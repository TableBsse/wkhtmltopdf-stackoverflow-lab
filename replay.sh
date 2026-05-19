#!/bin/bash
# Usage: ./replay.sh          → crash test
#        ./replay.sh --gdb    → interactive gdb

LAB=$(cd "$(dirname "$0")" && pwd)
BIN=$LAB/bin/wkhtmltopdf
XSL=$LAB/payloads/crash.xsl
HTML=$LAB/payloads/trigger.html
OUT=$LAB/output/out.pdf

export LD_LIBRARY_PATH=$LAB/libs:$LD_LIBRARY_PATH
mkdir -p "$LAB/output"

if [ "$1" = "--gdb" ]; then
    echo "[*] Launching gdb — type 'run' then 'bt full' after crash"
    gdb -q \
        -ex "set args $HTML toc --xsl-style-sheet $XSL $OUT" \
        -ex "catch signal SIGSEGV" \
        -ex "catch signal SIGABRT" \
        "$BIN"
else
    echo "[*] Running crash test..."
    ulimit -s unlimited
    "$BIN" "$HTML" toc --xsl-style-sheet "$XSL" "$OUT" 2>&1
    echo "[*] Exit code: $?"
    echo "[*] Expected: 137 (SIGKILL) or 139 (SIGSEGV)"
fi
