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

resource AppResource ui-object
resource Interface ui-object
resource Strings lmem read-only shared
resource XWMAPPMONIKERRESOURCE lmem read-only shared
resource XWMDOCMONIKERRESOURCE lmem read-only shared

# platform
#platform geos201

library geos
library ui
library ansic
library spool
library compress
#library text
#exempt compress

export XWMDocumentControlClass

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC  All Rights Reserved"
