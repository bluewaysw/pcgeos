#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)

require_present()
{
    if ! grep -F "$1" "$root/$2" >/dev/null; then
        echo "missing Stop invariant: $1" >&2
        exit 1
    fi
}

require_absent()
{
    if grep -F "$1" "$root/$2" >/dev/null; then
        echo "unexpected Stop invariant: $1" >&2
        exit 1
    fi
}

require_present '@AbortOperation(FALSE, TRUE, 0)' \
  Appl/Breadbox/BbxBrow/htmlview/UIAction.goc
require_absent 'G_stopped = FALSE' \
  Appl/Breadbox/BbxBrow/urlframe/URLFRAME.goc
require_present 'UserAbortEnd();' \
  Appl/Breadbox/BbxBrow/urldoc/URLDOC.goc
require_present 'MSG_URL_TEXT_INTERNAL_CANCEL_LIKE_GRAPHICS' \
  Appl/Breadbox/BbxBrow/urltext/URLTEXT.goc
require_present 'if(G_stopped && ret != URL_RET_PROGRESS &&' \
  Appl/Breadbox/BbxBrow/urltext/URLTEXT.goc
require_present 'if(canceled && !iad.IAD_completeGraphic)' \
  Appl/Breadbox/BbxBrow/htmlview/ImportG.goc
require_present 'VMFreeVMChain(vmf, VMCHAIN_MAKE_FROM_VM_BLOCK(vmb));' \
  Appl/Breadbox/BbxBrow/htmlview/ImportG.goc

echo "Stop cancellation checks passed"
