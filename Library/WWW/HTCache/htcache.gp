##############################################################################
#
#	Copyright (c) Geoworks 1996.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Geos WWW Library
# FILE:		htcache.gp
#
# AUTHOR:	Kok Kin Kee, Nov  1, 1996
#
#
# geode parameters for the cache manager
#
#	$Id: htcache.gp,v 1.1 97/04/07 11:49:39 newdeal Exp $
#
##############################################################################
#
name htcache.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW Cache Library"
tokenchars	"HTCH"
tokenid		0

#
# Specify geode type: is a library
#
type	library, single, c-api

#
# Libraries: list which libraries are used by the application.
#
library	geos
library ansic
library htmem
library htcore

#
# Entry point to the Library
#
entry HTCACHELIBRARYENTRY

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource HTCacheData           shared lmem discardable

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#

#
# Export classes. 
#
export HTCacheWriterClass

export HTCACHEENABLE
export HTCACHEDISABLE
export HTCACHEISENABLED
export HTCACHEGETREFERENCE
export HTCACHESETLIMIT
export HTCACHEWRITERCREATE

