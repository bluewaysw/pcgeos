name wsm.app
#
longname "Word Search Maker"
#
type   appl, process, single
class   WSMProcessClass
appobj  WSMApp
#
tokenchars "BWSM"
tokenid 16431

resource AppResource ui-object
resource WSMMonikerResource
resource Interface ui-object
resource Strings data object
resource DocGroupResource object
resource LOGORESOURCE data object

# platform
platform geos201

library geos
library ui
library ansic
library spool
#library text

export WSMDocumentControlClass

usernotes "Copyright 1994-2001 Breadbox Computer Company LLC  All Rights Reserved"
