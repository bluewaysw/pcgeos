##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# FILE:		htmem.gp
#
# AUTHOR:	Mingzhe Zhu, Jan 15, 1997
#
#
# 
#
#	$Id: htmem.gp,v 1.7.5.4 97/10/06 12:49:05 kkee Exp $
#
##############################################################################
#
name htmem.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW htmem Library"
tokenchars	"HTMM"
tokenid		0

#
# Specify geode type: is a library. 
#
type	library, single, c-api

#
# Libraries: list which libraries are used by the application.
#
library	geos
library ansic

#
# Entry point to the Library. 
#
entry HTMEMLIBRARYENTRY

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
#resource HTMEM_G		fixed read-only code shared
#I assume this refers to the main code segment
resource HTMEMCODE		fixed read-only code shared

#
# Export routines
#	These are the routines exported by the library
#

export ECCHECKHTMEMHANDLE
export HTMEMALLOC
export HTMEMALLOCWID
export HTMEMREALLOC
export HTMEMREALLOCWID
export HTMEMFREE
export HTMEMFREEALLWID
export HTMEMLOCK
export HTMEMUNLOCK
export HTMEMDEREF
export HTMEMALLOCANDLOCK
export HTMEMALLOCANDLOCKWID
export HTMEMUNLOCKANDFREE
export HTMEMORYLIMIT
export HTMEMORYALLOCATED
export HTMEMUSEDSPACEWID

export HTBUCKETALLOC
export HTBUCKETFREE
export HTBUCKETPUTBLOCK
export HTBUCKETFLUSH
export HTBUCKETGETBYTE
export HTBUCKETGETCHUNK



