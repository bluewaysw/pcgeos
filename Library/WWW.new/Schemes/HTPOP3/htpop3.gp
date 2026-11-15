##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Geos WWW Library
# FILE:		htpop3.gp
#
# AUTHOR:	Kok Kin Kee, Jun 11, 1997
#
#
# POP3 glue parameters
#
#	$Id: htpop3.gp,v 1.1.5.1 97/09/05 10:52:47 jeremyb Exp $
#
##############################################################################
#
name  htpop3.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW POP3 Protocol Library"
tokenchars	"HTP3"
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
export HTPOP3Class

