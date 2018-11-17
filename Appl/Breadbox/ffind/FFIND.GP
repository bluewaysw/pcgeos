#
# FILE:  FFIND.GP
#
name ffind.app
longname "File Finder"
type    appl, process, single
class   FileFindProcessClass
appobj  FileFindApp

tokenchars "FFNR"
tokenid 0   #16431

library geos
library ui
library ansic
library text

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource CONSTANTDATA object, data, swapable
resource OPENAPPLICATION object, code, swapable
resource CODERESOURCE object, code, swapable
resource RECURSIVERESOURCE object, code, swapable
resource GOTFILESRESOURCE object, code, swapable
resource STRINGSRESOURCE lmem read-only swapable shared ui-object

export FileFindPrimaryClass
export FileFindProcessClass
export FileFindVLTContentClass
export FileFindVLTextClass

platform geos201

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

#
# END OF FILE:  FFIND.GP
#
