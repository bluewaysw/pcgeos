##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Geos WWW Library
# FILE:		htgnf.gp
#
# AUTHOR:	Kok Kin Kee, Feb 14, 1997
#
#
# HTGNF glue parameters
#
#	$Id: htgnf.gp,v 1.1.11.1 97/09/05 10:56:12 jeremyb Exp $
#
##############################################################################
#
name htgnf.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW HTGNF Library"
tokenchars	"HTGN"
tokenid		0

#
# Specify geode type: is a library
#
type	library, single

#
# Libraries: list which libraries are used by the application.
#
library	geos
library ui
library ansic
library netutils noload
library htcore
library uigenera
library htconv

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#

#
# Export classes, the first class must be the converter class.
#
export HTGNFClass

