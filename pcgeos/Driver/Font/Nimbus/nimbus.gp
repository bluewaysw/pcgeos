##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Nimbus Font Driver
# FILE:		nimbus.gp
#
# AUTHOR:	Gene, 11/89
#
#
# Parameters file for: nimbus.geo
#
#	$Id: nimbus.gp,v 1.1 97/04/18 11:45:31 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	nimbus.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
#
# Desktop-related things
#
longname	"Nimbus-Q Font Driver"
tokenchars	"FNTD"
tokenid		0
usernotes	"Contains Nimbus Q from Digital Typeface Corp. \
and typefaces from URW"
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only shared
resource InitMod	code read-only shared discard-only


#
# XIP-enabled
#
