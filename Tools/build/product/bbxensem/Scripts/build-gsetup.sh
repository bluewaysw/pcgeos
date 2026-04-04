#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASM_FILE="$SCRIPT_DIR/gsetup.asm"
OBJ_FILE="$SCRIPT_DIR/gsetup.obj"
COM_FILE="$SCRIPT_DIR/gsetup.com"

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

WASM_EXE="$(find_tool wasm || true)"
WLINK_EXE="$(find_tool wlink || true)"

if [ -z "$WASM_EXE" ] || [ -z "$WLINK_EXE" ]; then
    echo "ERROR: Could not find OpenWatcom wasm/wlink." >&2
    echo "ERROR: Put tools in PATH or set WATCOM." >&2
    exit 1
fi

"$WASM_EXE" -zq -fo="$OBJ_FILE" "$ASM_FILE"
"$WLINK_EXE" option quiet format dos com option nodefault option start=_start \
    file "$OBJ_FILE" name "$COM_FILE"
rm -f "$OBJ_FILE"

echo "Built $COM_FILE"
