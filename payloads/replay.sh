#!/bin/bash
# Crash replay: XSLT recursive template → stack overflow in wkhtmltopdf 0.12.6
# Usage: ./replay.sh          → raw crash
#        ./replay.sh --gdb    → interactive gdb session

BIN=/lab/bin/wkhtmltopdf
XSL=/lab/payloads/crash.xsl
HTML=/lab/payloads/trigger.html
OUT=/lab/output/out.pdf

mkdir -p /lab/output

if [ "$1" = "--gdb" ]; then
    echo "[*] Launching under gdb"
    echo "[*] Commands: run → bt full → frame N → info locals"
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
    echo "[*] Expected: 137 (SIGKILL/OOM) or 139 (SIGSEGV)"
fi
