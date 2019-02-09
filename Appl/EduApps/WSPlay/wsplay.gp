# -----------------------------------------------------------------
#   converting the maker into a player
#
#   7/25/00	jfh
# -----------------------------------------------------------------

name wsplay.app
#
longname "Word Search Player"
#
type   appl, process, single
class   WSPProcessClass
appobj  WSPApp
#
tokenchars "WSPL"
tokenid 16431

resource AppResource ui-object
resource WSPMonikerResource
resource Interface ui-object
resource DocGroupResource object
resource StringsResource data object
resource LOGORESOURCE data object

# platform
platform geos201

library geos
library ui
library ansic
library spool

export WSPDocumentControlClass
export WSPGenViewClass

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC  All Rights Reserved"
