#
# FILE:  palmview.gp
#
name palmview.app
longname "Palm Viewer"
type    appl, process, single
class   PalmViewProcessClass
appobj  PalmViewApp

tokenchars "PMVW"
tokenid 16431

library geos
library ui
library ansic
library text

resource AppResource ui-object
resource Interface ui-object
resource StringResource lmem read-only swapable shared ui-object

export PalmViewPrimaryClass
export PalmViewProcessClass
export PalmViewVLTContentClass
export PalmViewVLTextClass

platform geos201

usernotes "Copyright 1994-2009  Breadbox Computer Company LLC  All Rights Reserved"

#
# END OF FILE:  FFIND.GP
#
