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
#	$Id: htmem.gp,v 1.1 97/04/07 11:49:44 newdeal Exp $
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

#
# Export routines
#	These are the routines exported by the library
#

export ECCHECKHTMEMHANDLE
export HTMEMALLOC
export HTMEMREALLOC
export HTMEMFREE
export HTMEMLOCK
export HTMEMUNLOCK
export HTMEMALLOCANDLOCK
export HTMEMUNLOCKANDFREE
export HTMEMORYLIMIT


