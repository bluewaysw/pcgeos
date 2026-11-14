##############################################################################
#
#	Copyright (c) Geoworks 1996.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Geos WWW Library
# FILE:		htmlp.gp
#
# AUTHOR:	Kok Kin Kee, Oct 21, 1996
#
#
# HTML Parser glue paramaters
#
#	$Id: htmlp.gp,v 1.1 97/04/07 11:51:08 newdeal Exp $
#
##############################################################################
#
name htmlp.lib


#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW HTML Library"
tokenchars	"HTMP"
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

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource HTMLFILTERRESOURCE	read-only lmem discardable
resource HTMLDTDRESOURCE	read-only lmem discardable


#
# Export classes
#
export HTMLPClass
