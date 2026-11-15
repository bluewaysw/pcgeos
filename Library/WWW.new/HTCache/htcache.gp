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
#	$Id: htcache.gp,v 1.7.3.2 97/11/18 22:41:30 kkee Exp $
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

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#

export HTCACHEENABLE
export HTCACHEDISABLE
export HTCACHEISENABLED
export HTCACHEGETREFERENCE
export HTCACHESETLIMIT
export HTCACHECLEAR
export HTCACHEWRITERCREATE

