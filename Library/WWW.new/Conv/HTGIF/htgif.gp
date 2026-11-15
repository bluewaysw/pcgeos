##############################################################################
#
#	Copyright (c) Geoworks 1996.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Geos WWW Library
# FILE:		htgif.gp
#
# AUTHOR:	Kok Kin Kee, Nov 26, 1996
#
#
# HTGIF glue parameters
#
#	$Id: htgif.gp,v 1.3.11.2 97/09/25 18:35:52 kkee Exp $
#
##############################################################################
#
name htgif.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW HTGIF Library"
tokenchars	"HTGF"
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
library html
library htconv

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#

#
# Export classes
#
export HTGIFClass



