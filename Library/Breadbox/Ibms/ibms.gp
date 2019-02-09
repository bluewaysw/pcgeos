name ibms.lib
longname "Breadbox Index Based Mem Lib"
type    library, single, c-api
tokenchars "None"
tokenid 16431
library geos
library ansic

# ---------------------------------------------------- PROTOTYPE 1.0 -----
# Index Based Memory System routines:
export IBMSCreate
export IBMSOpen
export IBMSClose
export IBMSSave
export IBMSDestroy
export IBMSAlloc
export IBMSFree
export IBMSLock
export IBMSUnlock
export IBMSDirty
export IBMSGetMap
export IBMSSetMap
export IBMSResize

# Index Based Double Linked List routines:
export IBDLLCreate
export IBDLLDestroy
export IBDLLInsert
export IBDLLItemDelete
export IBDLLGetItem
export IBDLLGetCount
export IBDLLItemGetData
export IBDLLItemSetData
export IBDLLItemGetFlags
export IBDLLItemSetFlags
export IBDLLGetHeaderData
export IBDLLSetHeaderData
export IBDLLItemGetPrevious
export IBDLLItemGetNext

# Index Based Tree routines:
export IBTreeFolderCreate
export IBTreeFolderDestroy
export IBTreeFolderInsertData
export IBTreeFolderInsertFolder
export IBTreeEntryDelete
export IBTreeFolderGetEntry
export IBTreeFolderGetCount
export IBTreeFolderGetParent
export IBTreeEntryGetData
export IBTreeEntrySetData
export IBTreeEntryGetFlags
export IBTreeEntrySetFlags
export IBTreeEntryGetPrevious
export IBTreeEntryGetNext
export IBTreeEntryGetFolder
export IBTreeEntryMoveTo

# ---------------------------------------------------- PROTOTYPE 1.1 -----
# incminor

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

