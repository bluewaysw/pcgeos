name sitelist.lib
longname "Breadbox Site List Database"
type    library, single, c-api
tokenchars "None"
tokenid 16431
library geos
library ansic
library ui
platform geos201

# ---------------------------------------------------- PROTOTYPE 1.0 -----
export SiteListOpen
export SiteListClose
export SiteListGetCount
export SiteListFindNth
export SiteEntryCreate
export SiteEntryDestroy
export SiteEntryLock
export SiteEntryUnlock
export SiteFieldGet
export SiteFieldSet

export SiteSelectionClass

# ---------------------------------------------------- PROTOTYPE 1.1 -----
# incminor

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

