##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Geos WWW Library
# FILE:		htimap.gp
#
# AUTHOR:	Kok Kin Kee, May 19, 1997
#
#
# IMAP4 glue parameters.
#
#	$Id: htimap.gp,v 1.1.6.1 97/09/05 10:52:09 jeremyb Exp $
#
##############################################################################
#
name  htimap.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW IMAP4 Protocol Library"
tokenchars	"HTI4"
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

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#

#
# Export classes. For all protocol classes, the first thing to export *MUST*
# be the protocol classname.
#
export HTIMAPClass






