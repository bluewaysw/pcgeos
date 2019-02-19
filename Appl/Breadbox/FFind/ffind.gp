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

resource AppResource ui-object
resource Interface ui-object
#resource ConstantData object, data, swapable
resource OpenApplication object, code, swapable
resource CodeResource object, code, swapable
resource RecursiveResource object, code, swapable
resource GotFilesResource object, code, swapable
resource StringsResource lmem read-only swapable shared ui-object

export FileFindPrimaryClass
export FileFindProcessClass
export FileFindVLTContentClass
export FileFindVLTextClass

platform geos201

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

#
# END OF FILE:  FFIND.GP
#
