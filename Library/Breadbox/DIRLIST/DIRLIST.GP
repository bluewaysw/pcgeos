##############################################################################
#
# PROJECT:      indexarray / Directory List
# FILE:         dirlist.gp
#
# AUTHOR:       Rainer Bettsteller
#
##############################################################################

name            dirlist.lib
longname        "Dircetory List Support"
tokenchars      "DLst"
tokenid         739

usernotes "1st Bugfix. Some problems showing directories are fixed. (c) by RABE-Soft 06/2000"

type            library, single

platform        geos20

library         geos
library         ansic
library 	ui



resource BITMAPRESOURCE lmem, read-only, shared


export DClickGenDynamicListClass

# IndexArray - Routinen

export INDEXARRAYCREATEPATH
export INDEXARRAYCREATENEWPATH
export INDEXARRAYEXISTPATH
export INDEXARRAYFINDPARENTINDEX
export INDEXARRAYCREATEFILEENTRY
export INDEXARRAYAPPENDFILE
export INDEXARRAYAPPENDSUBDIR
export INDEXARRAYINCREMENTSIZE
export INDEXARRAYLOCKENTRY

# durchsuchen von Verzeichnissen

export DIRLISTENUMSUBDIR
export DIRLISTEXTENDEDENUMSUBDIR
export DIRLISTENUMDIRSANDFILES

# verwalten der Icon-Bildchen

export DIRLISTGETDOSICONTYPE
export DIRLISTGETICONTYPE
export DIRLISTGETICONOPTR
export DIRLISTWRITEICONIZEDSTRING
export DIRLISTGETCURRENTDIRNAME
export DIRLISTPARSENAMEFROMPATH

incminor

export BargrafClass
#export BargrafViewClass
#export BargrafContentClass

export DIRLISTSORTFILEENUMRESULT

incminor

export DIRLISTTOOLADJUSTLINKDIRS

incminor

export INDEXARRAYAPPENDFILEEX
export INDEXARRAYCREATEFILEENTRYEX

