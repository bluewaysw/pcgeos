#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
source_file="$root/Appl/Breadbox/BbxBrow/urlfetch/URLFETCH.goc"

require_present()
{
    if ! grep -F "$1" "$source_file" >/dev/null; then
        echo "missing shutdown cleanup: $1" >&2
        exit 1
    fi
}

require_absent()
{
    if grep -F "$1" "$source_file" >/dev/null; then
        echo "unexpected feature dependency: $1" >&2
        exit 1
    fi
}

require_present 'ThreadFreeSem(p_child->sem);'
require_present 'ThreadFreeSem(G_fetchProgressSem[i]);'
require_present 'HugeArrayDestroy(G_fetchProgressVMFile[i],'
require_present 'ThreadFreeSem(G_fetchSemaphore);'
require_present 'MemFree(G_allocBlock);'
require_present 'GeodeFreeLibrary(lastURLDriver);'
require_absent 'LoadGraphicStreamsFree'
require_absent 'LPD_imageProbe'

echo "URL fetch shutdown cleanup checks passed"
