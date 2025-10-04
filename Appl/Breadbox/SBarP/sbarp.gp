name sbar.app
longname "Startbar"
type     appl, process, single
class    StartBarProcessClass
appobj   StartBarApp

tokenchars "SBar"
tokenid 16431

library geos
library ui
library ansic
library text
library sbarutil

resource APPRESOURCE ui-object
resource INTERFACE ui-object
#resource ABOUTRES ui-object
resource STARTBARMENURES ui-object
resource NDICORES lmem read-only shared
resource NDICORESBW lmem read-only shared
resource NDICORESCOL lmem read-only shared
resource TEXTRES lmem read-only shared

usernotes "Copyright 1994-97 Breadbox Computer Company."
export StartBarAppClass
export StartBarPrimaryClass
export StartBarInteractionClass
export StartBarIconInteractionClass
export StartBarRightInteractionClass
export StartBarSButtonTriggerClass
export StartBarSideTitleClass
export StartBarExpressMenuControlClass
stack 4000