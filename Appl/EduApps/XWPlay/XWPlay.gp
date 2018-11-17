name xwplay.app
#
longname "Crossword Player"
#
type   appl, process, single
class   XWPProcessClass
appobj  XWPApp
#
tokenchars "XWPL"
tokenid 16431

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource STRINGS data object
#resource XWMAPPMONIKERRESOURCE data
#resource XWMDOCMONIKERRESOURCE data
#resource LOGORESOURCE data object

# platform
platform geos201

library geos
library ui
library ansic
library spool
#library text

export XWPDocumentControlClass
export XWPGenViewClass

usernotes "Copyright Breadbox Computer Company  All Rights Reserved"

