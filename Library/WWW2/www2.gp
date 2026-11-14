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
resource ww2mem_TEXT	fixed read-only code shared
resource sgml_TEXT	fixed read-only code shared
resource sched_TEXT	fixed read-only code shared
resource req_TEXT	fixed read-only code shared


#
# Export routines
#	These are the routines exported by the library
#

#
# String routines
#
export TSTRLEN
export TSTRCPY
export Tstrncpy
export TSTRRCHR
export WWSTRINGECCHECK
# export JstrncpyToTCHAR
export TSTRCAT
export JSTRCPY
export JSTRNCPY
export WWSTRCASECMP
export WWSTRCASECMPWWMEM
export WWSTRNCASECMP
export WWSTRNCASECMPWWMEM
export WWSTRCASESTR
export WWSTRTOLOWER
export WWSTRTOUPPER
export STRALLOCCOPY
export STRNALLOCCOPY
export STRNALLOCCOPYTCHAR
export STRNCPYTCHAR
export STRNCPYTOTCHAR
export WWSTRLENWWMEM
export WWSTRINGLEN
export WWSTRCPYWWMEM
export WWSTRCATWWMEM
export WWSTRALLOCCOPY
export WWSTRNALLOCCOPYTCHAR
export WWSTRNALLOCCOPY
export WWSTRALLOCCAT
export WWSTRNALLOCCATTCHAR
export STRNALLOCCATTCHAR
export WWSTRALLOCCOPYWWMEM

#
# Suffix routine
#
export SUFFIXMIMETYPE
export URLMIMETYPE
export URLMIMETYPETCHAR
export MIMETYPETOSUFFIX


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
export ECCHECKWWMEMHANDLE
export WWMEMALLOC
export WWMEMREALLOC
export WWMEMFREE
export WWMEMLOCK
export WWMEMUNLOCK
export WWMEMDEREF
export WWMEMALLOCANDLOCK
export WWMEMUNLOCKANDFREE



export WWStreamClass
export WWListElementClass
export WWListClass
export WWStatusClass
export SgmlClass
export CommandSchedulerClass
export HTMLViewerClass
export WWFileClass



