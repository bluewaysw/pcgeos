##############################################################################
#
# PROJECT:      File Tool Library
# FILE:         rsftool.gp
#
# AUTHOR:       Rainer Bettsteller
#
##############################################################################

name            rsftool.lib
longname        "RabeSoft File Tool Library"
tokenchars      "FlTl"
tokenid         16480
usernotes	"Made by RABE-Soft 04/2020-07/2025\rEnglisch Version 1.8.4"

type            library, single

platform        geos20

library         geos
library         ansic
library 	ui



resource DialogBoxResource	ui-object read-only shared
resource InfoTextResource	lmem read-only shared
resource InfoText2Resource	lmem read-only shared

export SelectDirOrFileDialogClass

# ******************** exportierte Routinen ************************

# ---------- file delector support --------------------------

export	FILETOOLREQUESTCHANGEDIR
export  FILETOOLEXTENDEDREQUESTSELECTFILE
export	FILETOOLREQUESTDISK

export	FILETOOLPRINTDATEANDSIZE
export	FILETOOLGETFILESELECTORFULLPATH
export	FILETOOLGETFILESELECTORDIRECTORYPATH
export	FILETOOLSETCURRENTPATHFROMFILESELECTOR
export	FILETOOLGETTEXTOPTR

# ---------- Compare and Convert --------------------------

export	FILETOOLCOMPAREPROTOCOL
export	FILETOOLCOMPARERELEASE
export	FILETOOLCOMPAREFILEDATEANDTIME

export	FILETOOLFILEDATETOTIMEDATE

# ---------- Edit path strings ----------------------------

export	FILETOOLDROPBACKSLASH
export	FILETOOLMAKEPARENTPATH
export	FILETOOLADDPATHELEMENT
export	FILETOOLPARSENAMEFROMPATH_OLD

# ---------- Path and CurrentDir ------------------------

export	FILETOOLCREATESUBDIR
export	FILETOOLCREATEPATH
export  FILETOOLGETCURRENTDIRNAME

# ---------- Search for files and folders ------------------------

export	FILETOOLEXISTFILEGD

export	FILETOOLENUMSUBDIR
export	FILETOOLEXTENDEDENUMSUBDIR
export	FILETOOLENUMDIRSANDFILES
export	FILETOOLSORTFILEENUMRESULT
export	FILETOOLADJUSTLINKDIRS

# ---------- Read and write files ------------------------

export	FILETOOLINSERTBUFFER
export	FILETOOLDELETERANGE
export	FILETOOLREPLACEBUFFER

export	FILETOOLCOPYFILE_OLD
export	FILETOOLDELETEFILE_OLD
export	FILETOOLRENAMEFILE
export	FILETOOLMODIFYDOSNAME

export	FILETOOLSETEXTATTR
export	FILETOOLREADLINE
export	FILETOOLTRIMLINE

#------- Version 1.1 --------------
incminor

export	FILETOOLCOPYFILE_OLD2
export	FILETOOLMOVEFILE_OLD

#------- Version 1.2 --------------
incminor

export FTCREATEFILEBUFFER
export FTREADBUFFEREDFILE
export FTGETFILEPOSATBUFFEREDPOSITION
export FTBUFFEREDFILESKIP
export FTDESTROYFILEBUFFER

#------- Version 1.3 --------------
incminor

export FILETOOLEXTENUMSUBDIRWITHSKIP


#------- Version 1.4 --------------
incminor

export FILETOOLREQUESTINPUTFILENAME
export FILETOOLEXTENDEDREQUESTINPUTFILENAME
export FILETOOLFINDLASTDOTCHAR
export FILETOOLGETDOSEXTENSION

#------- Version 1.5 --------------
incminor

export FILETOOLREQUESTINPUTFOLDERNAME
export FILETOOLREQUESTINPUTCOMMONNAME

#------- Version 1.6 --------------
incminor

export	FILETOOLPARSENAMEFROMPATH

#------- Version 1.7 --------------
# supports "Yes, All" trigger when copying, moving, or deleting
incminor

export	FILETOOLDELETEFILE_OLD2
export	FILETOOLCOPYFILE
export	FILETOOLMOVEFILE

#------- Version 1.8 --------------
incminor

export	FILETOOLREADLINE2
export	FILETOOLDELETEFILE
export  FILETOOLDELETEFILEEASY
export  FILETOOLCOPYFILEEASY
export  FILETOOLMOVEFILEEASY
export	FILETOOLRENAMEFILENORETRY
export	FILETOOLMODIFYDOSNAMENORETRY


