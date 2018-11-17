#
# FILE:  PalmView.GP
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

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource STRINGRESOURCE lmem read-only swapable shared ui-object

export PalmViewPrimaryClass
export PalmViewProcessClass
export PalmViewVLTContentClass
export PalmViewVLTextClass

platform geos201

usernotes "Copyright 1994-2009  Breadbox Computer Company LLC  All Rights Reserved"

#
# END OF FILE:  FFIND.GP
#
