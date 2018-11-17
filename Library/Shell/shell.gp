##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# FILE:		shell.gp
#
# AUTHOR:	Martin Turon, Oct  2, 1992
#
#	$Id: shell.gp,v 1.1 97/04/07 10:45:14 newdeal Exp $
#
##############################################################################
#
name shell.lib

#
# Desktop-related things
#
longname 	"Shell Library"
tokenchars	"SHLL"

#
# Specify geode type
#
type	library, single

#
# Imported libraries
#
library	geos
library ui

#########################################################################
# 	Define resources other than standard discardable code		#
#########################################################################
nosort
resource Icon			read-only code shared
resource File			read-only code shared
resource ShellErrorDialog	read-only code shared
resource DirInfo		read-only code shared
resource FQT			read-only code shared
resource IconGadgets		read-only code shared
resource Init			read-only code shared
resource Util			read-only code shared
resource ShellFileBuffer	read-only code shared
resource ShellFileErrorStrings	lmem
#########################################################################
# 			Exported Routines				#
#########################################################################

# File Module Routines
export	ShellSetObjectType
export	ShellGetObjectType
export	ShellSetToken
export	ShellGetToken
export  ShellAllocPathBuffer
export  ShellAlloc2PathBuffers
export	ShellFreePathBuffer
export  ShellSetFileHeaderFlags
export	ShellPushToRoot

# Util Module Routines
export	ShellBuildFullFilename
export	ShellCombineFileAndPath
export	FileComparePathsEvalLinks

# Icon Module Routines
export	ShellLoadMoniker
export	ShellDefineTokens

# DirInfo Module Routines
export	ShellCreateDirInfo
export	ShellOpenDirInfo
export	ShellCloseDirInfo
export	ShellSearchDirInfo
export	ShellSetPosition
export	ShellGetPosition
export	ECCheckDirInfo
export	ShellOpenDirInfoRW

# Dialog Module Routines
export	ShellReportFileError
export	ShellReportError

# FQT (FileQuickTransfer) Module Routines
export	ShellGetTrueDiskHandleFromFQT
export	ShellGetRemoteFlagFromFQT

#########################################################################
# 			Exported Classes				#
#########################################################################

export	IconListClass
export	IconDisplayClass


###########  If you add new routines, put them here   #############
###########  (and don't forget to up minor protocol)  #############

export	ShellGetFileHeaderFlags
export	ShellDropFinalComponent
#
# XIP-enabled
#

# Buffer Module Routines
export	ShellBufferOpen
export	ShellBufferClose
export	ShellBufferReadLine
export	ShellBufferReadNLines
export	ShellBufferLock
export	ShellBufferUnlock

export  SHELLREPORTFILEERROR
