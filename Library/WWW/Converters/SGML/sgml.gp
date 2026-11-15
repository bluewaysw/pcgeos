##############################################################################
#
#	Copyright (c) Geoworks 1996.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Geos WWW Library
# FILE:		sgml.gp
#
# AUTHOR:	Kok Kin Kee, Sep 25, 1996
#
#
# DESCRIPTION:
#	geode paramters file for the SGML parser class.
#
#	$Id: sgml.gp,v 1.1 97/04/07 11:51:14 newdeal Exp $
#
##############################################################################
#
name sgml.lib


#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW SGML Library"
tokenchars	"SGML"
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

#
# Export classes
#
export SGMLClass



