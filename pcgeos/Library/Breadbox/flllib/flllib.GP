##############################################################################
#
# PROJECT:      File List Library
# FILE:         FLLLIB.gp
#
# AUTHOR:       Lysle Shields
#
##############################################################################

name flllib.app
longname "Breadbox File List Library"
type    library, single, c-api
tokenchars "None"
tokenid 16431
library geos
library ui
library ansic

#platform geos201

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

# ---------------------------------------------------- PROTOTYPE 1.0 -----
export GenFileListClass
export DirPathCreate 
export DirPathDestroy
export DirPathGetVolume
export DirPathSetVolume
export DirPathGetFilter
export DirPathSetFilter
export DirPathGetFlags
export DirPathSetFlags
export DirPathGetNthFolder
export DirPathGetNumFolders
export DirPathAppendFolder
export DirPathDeleteFolder
export DirPathAllocSubString
export DirPathAllocSubStringOptr
export DirPathReset
export DirPathRemoveLastFolder
export DirPathDuplicate
export DirPathApplyPath
export DirPathStandardParse
export DirPathCompareFolder
export DirPathStandardCondense
export DirPathMakeRoot
export DirPathConstructString

# ---------------------------------------------------- PROTOTYPE 1.1 -----
# incminor

#internal
export FileListTableClass
export GenLocalFileListClass
resource FLLUI ui-object
