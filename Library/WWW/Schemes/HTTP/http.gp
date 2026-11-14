##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	Geos WWW Library.
# FILE:		http.gp
#
# AUTHOR:	Kok Kin Kee, May 23, 1996
#
#
# DESCRIPTION:
#	geode parameters file for the HTTP protocol class.
#
#	$Id: http.gp,v 1.4.10.1 97/09/05 10:51:12 jeremyb Exp $
#
##############################################################################
#
name http.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW HTTP Protocol Library"
tokenchars	"HTTP"
tokenid		0

#
# Specify geode type: is a library
#
type	library, single

#
# Libraries: list which libraries are used by the application.
#
library	geos
library ansic
library htcore
library htmem
library htcache

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#

#
# Export classes. For all protocol classes, the first thing to export *MUST*
# be the protocol classname.
#
export HTTPClass
export HTTPGenClass
export HTTPReqClass



