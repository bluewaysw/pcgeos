#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_FILE="$SCRIPT_DIR/gsetup.c"
EXE_FILE="$SCRIPT_DIR/gsetup.exe"

find_tool() {
    local tool_name="$1"

    if command -v "$tool_name" >/dev/null 2>&1; then
        command -v "$tool_name"
        return 0
    fi

    if [ -n "${WATCOM:-}" ]; then
        for candidate in \
            "$WATCOM/binl64/$tool_name" \
            "$WATCOM/binl/$tool_name"
        do
            if [ -x "$candidate" ]; then
                echo "$candidate"
                return 0
            fi
        done
    fi

    return 1
}

WCL_EXE="$(find_tool wcl || true)"

if [ -z "$WCL_EXE" ]; then
    echo "ERROR: Could not find OpenWatcom wcl." >&2
    echo "ERROR: Put tools in PATH or set WATCOM." >&2
    exit 1
fi

if [ -n "${WATCOM:-}" ]; then
    WATCOM_ROOT="$WATCOM"
else
    WATCOM_ROOT="$(cd "$(dirname "$WCL_EXE")/.." && pwd)"
fi

WATCOM="$WATCOM_ROOT" "$WCL_EXE" -bt=dos -ms -zq -i="$WATCOM_ROOT/h" -fe="$EXE_FILE" "$SRC_FILE"

echo "Built $EXE_FILE"
