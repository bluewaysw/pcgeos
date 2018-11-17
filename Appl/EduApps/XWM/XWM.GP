name xwm.app
#
longname "Crossword Maker"
#
type   appl, process, single
class   XWMProcessClass
appobj  XWMApp
#
tokenchars "XWMa"
tokenid 16431

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource STRINGS data object
resource XWMAPPMONIKERRESOURCE data
resource XWMDOCMONIKERRESOURCE data
resource LOGORESOURCE data object

# platform
platform geos201

library geos
library ui
library ansic
library spool
library compress
#library text
exempt compress

export XWMDocumentControlClass

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC  All Rights Reserved"

