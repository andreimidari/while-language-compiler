#!/usr/bin/env bash
# Usage: ./run_lexer_tests.sh [io.o]   (after `make`)
#
# Generates lexer edge cases: CRLF endings, comments at EOF without a
# trailing newline, tab indentation, valid time literals, and invalid
# time literals that must be rejected with a lexical error.
cd "$(dirname "$0")"
pass=0; fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ -n "${1:-}" ] && [ -f "$1" ]; then
    cp "$1" "$tmp/io.o"
else
    gcc -m32 -c io.c -o "$tmp/io.o" || exit 1
fi

accept()
{
    name=$1
    if ./while "$tmp/$name" > "$tmp/$name.asm" 2> "$tmp/$name.err" \
       && nasm -felf "$tmp/$name.asm" -o "$tmp/$name.o" 2> "$tmp/$name.err" \
       && gcc -m32 -no-pie -Wl,-z,noexecstack "$tmp/io.o" "$tmp/$name.o" \
              -o "$tmp/$name.bin" 2> "$tmp/$name.err" \
       && timeout 5 "$tmp/$name.bin" > /dev/null 2> "$tmp/$name.err"; then
        pass=$((pass+1))
    else
        fail=$((fail+1)); echo "FAIL (should be accepted): $name"; head -n2 "$tmp/$name.err"
    fi
}

reject_lexical()
{
    name=$1
    if ./while "$tmp/$name" > /dev/null 2> "$tmp/$name.err"; then
        fail=$((fail+1)); echo "FAIL (should be rejected): $name"
    elif ! grep -q "Lexical error." "$tmp/$name.err"; then
        fail=$((fail+1)); echo "FAIL (not a lexical error): $name"; head -n2 "$tmp/$name.err"
    else
        pass=$((pass+1))
    fi
}

# CRLF line endings and a CRLF comment at EOF.
printf 'program crlf\r\nbegin\r\n    skip;\r\nend\r\n# trailing comment\r\n' > "$tmp/crlf.while"
# Comment at EOF without a trailing newline.
printf 'program comment_at_eof\nbegin\n    skip;\nend\n# no newline' > "$tmp/comment-eof.while"
# Inline comment at EOF without a trailing newline.
printf 'program inline_comment_at_eof\nbegin\n    skip;\nend # no newline' > "$tmp/inline-comment-eof.while"
# Tab-indented program.
printf 'program tabs\nbegin\n\tskip;\nend\n' > "$tmp/tabs.while"
# Valid time literals at both boundaries.
printf 'program valid_times\n  time t;\nbegin\n  t := 00:00;\n  write(hour(t));\n  t := 23:59;\n  write(minute(t));\nend\n' > "$tmp/valid-times.while"
# Identifiers with underscores and digits.
printf 'program identifiers\n  integer a_1;\nbegin\n  a_1 := 1;\n  write(a_1);\nend\n' > "$tmp/identifiers.while"
# Invalid time literals: hour and minute out of range.
printf 'program bad_time\n  time t;\nbegin\n  t := 24:00;\nend\n' > "$tmp/invalid-hour.while"
printf 'program bad_time\n  time t;\nbegin\n  t := 12:60;\nend\n' > "$tmp/invalid-minute.while"
# Unknown character.
printf 'program bad_char\nbegin\n  @\nend\n' > "$tmp/invalid-char.while"

accept crlf.while
accept comment-eof.while
accept inline-comment-eof.while
accept tabs.while
accept valid-times.while
accept identifiers.while
reject_lexical invalid-hour.while
reject_lexical invalid-minute.while
reject_lexical invalid-char.while

echo "lexer: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
