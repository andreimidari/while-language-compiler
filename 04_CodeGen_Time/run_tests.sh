#!/usr/bin/env bash
# Usage: ./run_tests.sh   (after `make`)
# *.ok            -> must compile, assemble (nasm) and link.
# *.*error        -> compiler must exit non-zero.
cd "$(dirname "$0")"
pass=0; fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
gcc -m32 -c io.c -o "$tmp/io.o" || exit 1

for f in general-tests/* custom-tests/*; do
    case "$f" in
        *.ok)
            if ./while "$f" > "$tmp/t.asm" 2> "$tmp/err" \
               && nasm -felf "$tmp/t.asm" -o "$tmp/t.o" \
               && gcc -m32 -no-pie -Wl,-z,noexecstack "$tmp/io.o" "$tmp/t.o" -o "$tmp/t"; then
                pass=$((pass+1))
            else
                fail=$((fail+1)); echo "FAIL (should compile): $f"; head -n2 "$tmp/err"
            fi ;;
        *error)
            if ./while "$f" > /dev/null 2>&1; then
                fail=$((fail+1)); echo "FAIL (should be rejected): $f"
            else
                pass=$((pass+1))
            fi ;;
    esac
done
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
