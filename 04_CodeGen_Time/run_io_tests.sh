#!/usr/bin/env bash
# Usage: ./run_io_tests.sh   (after `make`)
#
# Builds io.c together with the unit test driver and runs it.
cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if ! gcc -std=c11 -O2 -Wall -Wextra -o "$tmp/io_tests" io.c io-tests/io_tests.c; then
    exit 1
fi

"$tmp/io_tests"
