##############################################################################
#
#	Copyright (c) Geoworks 1996.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Geos WWW Library
# FILE:		htfile.gp
#
# AUTHOR:	Kok Kin Kee, Sep 19, 1996
#
#
# DESCRIPTION:
#       geode paramters file for the HTFile protocol class
#
#	$Id: htfile.gp,v 1.2.10.1 97/09/05 10:50:54 jeremyb Exp $
#
##############################################################################
#
name htfile.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW HTFile Protocol Library"
tokenchars	"HTFL"
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
library htmem
library htcore

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#


#
# Export classes
#
export HTFileClass



