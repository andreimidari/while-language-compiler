#!/usr/bin/env bash
# Usage: ./run_runtime_tests.sh [io.o]   (after `make`)
#
# Each runtime-tests/*.while is compiled, assembled, linked against io.o,
# run, and compared with the matching .expected file. If a matching .in
# file exists it is fed to the program on stdin.
cd "$(dirname "$0")"
pass=0; fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ -n "${1:-}" ] && [ -f "$1" ]; then
    cp "$1" "$tmp/io.o"
else
    gcc -m32 -c io.c -o "$tmp/io.o" || exit 1
fi

for src in runtime-tests/*.while; do
    [ -e "$src" ] || continue
    name=$(basename "$src" .while)
    expected="runtime-tests/$name.expected"
    input=/dev/null
    [ -f "runtime-tests/$name.in" ] && input="runtime-tests/$name.in"

    if [ ! -f "$expected" ]; then
        fail=$((fail+1))
        echo "FAIL (missing expected output): $expected"
        continue
    fi

    if ! ./while "$src" > "$tmp/$name.asm" 2> "$tmp/$name.err"; then
        fail=$((fail+1)); echo "FAIL (compiler): $src"; head -n2 "$tmp/$name.err"
        continue
    fi
    if ! nasm -felf "$tmp/$name.asm" -o "$tmp/$name.o" 2> "$tmp/$name.err"; then
        fail=$((fail+1)); echo "FAIL (assembler): $src"; head -n2 "$tmp/$name.err"
        continue
    fi
    if ! gcc -m32 -no-pie -Wl,-z,noexecstack "$tmp/io.o" "$tmp/$name.o" \
            -o "$tmp/$name" 2> "$tmp/$name.err"; then
        fail=$((fail+1)); echo "FAIL (linker): $src"; head -n2 "$tmp/$name.err"
        continue
    fi
    if ! timeout 5 "$tmp/$name" < "$input" > "$tmp/$name.out" 2> "$tmp/$name.err"; then
        fail=$((fail+1)); echo "FAIL (runtime): $src"; head -n2 "$tmp/$name.err"
        continue
    fi
    if diff -u "$expected" "$tmp/$name.out" > "$tmp/$name.diff"; then
        pass=$((pass+1))
    else
        fail=$((fail+1)); echo "FAIL (output): $src"; cat "$tmp/$name.diff"
    fi
done

echo "runtime: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
