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

resource APPRESOURCE ui-object
resource WSMMONIKERRESOURCE
resource INTERFACE ui-object
resource STRINGS data object
resource DOCGROUPRESOURCE object
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

