##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	Geos WWW2 Library.
# FILE:		www2.gp
#
# AUTHOR:	
#
#
# The WWW2 Library core parameter file.
#
#	$Id: www2.gp,v 1.2 98/09/03 04:05:17 allen Exp $
#
##############################################################################
#
name www2.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW2 Core Library"
tokenchars	"WWW2"
tokenid		0

#
# Specify geode type: is a library. 
#
type	library, single, c-api

#
# Libraries: list which libraries are used by the application.
#
library	geos
library ui
library ansic
library socket
library math

#
# Entry point to the Library. 
#
# entry HTCORELIBRARYENTRY
entry HTMEMLIBRARYENTRY

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource WW2MEM_G	fixed read-only code shared
resource SGML_E		fixed read-only code shared
resource SCHED_E	fixed read-only code shared
resource REQ_E		fixed read-only code shared


#
# Export routines
#	These are the routines exported by the library
#

#
# String routines
#
export Tstrlen
export Tstrcpy
export Tstrncpy
export Tstrrchr
export WWStringECCheck
# export JstrncpyToTCHAR
export Tstrcat
export Jstrcpy
export Jstrncpy
export WWStrCaseCmp
export WWStrCaseCmpWWMem
export WWStrNCaseCmp
export WWStrNCaseCmpWWMem
export WWStrCaseStr
export WWStrToLower
export WWStrToUpper
export stralloccopy
export strnalloccopy
export strnalloccopyTCHAR
export strncpyTCHAR
export strncpyToTCHAR
export WWStrLenWWMem
export WWStringLen
export WWStrCpyWWMem
export WWStrCatWWMem
export WWStrAllocCopy
export WWStrNAllocCopyTCHAR
export WWStrNAllocCopy
export WWStrAllocCat
export WWStrNAllocCatTCHAR
export strnalloccatTCHAR
export WWStrAllocCopyWWMem

#
# Suffix routine
#
export SuffixMimeType
export UrlMimeType
export UrlMimeTypeTCHAR
export MimeTypeToSuffix


#
# Uri routines
#
export WWParseURIStr
export WWParseURIHandle
export WWParseURIStrAll
export WWParseURIHandleAll
export WWFileURIOpen

#
# Mem routines
#
export ECCheckWWMemHandle
export WWMemAlloc
export WWMemRealloc
export WWMemFree
export WWMemLock
export WWMemUnlock
export WWMemDeref
export WWMemAllocAndLock
export WWMemUnlockAndFree



export WWStreamClass
export WWListElementClass
export WWListClass
export WWStatusClass
export SgmlClass
export CommandSchedulerClass
export HTMLViewerClass
export WWFileClass



