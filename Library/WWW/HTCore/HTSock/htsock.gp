##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	Geos WWW Library
# FILE:		htsocket.gp
#
# AUTHOR:	Kok Kin Kee, Jun 15, 1996
#
#
# DESCRIPTION:
#	geode parameters file for the HTSocket stream class.
#
#	$Id: htsock.gp,v 1.1 97/04/07 11:48:04 newdeal Exp $
#
##############################################################################
#
name htsock.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW Socket Library"
tokenchars	"HTSC"
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
library socket

#
# Entry point to the Library.
#

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
# resource HTFIXEDCODERESOURCE    fixed read-only code shared

#
# Export classes
#
export HTStreamClass
export HTSocketClass



