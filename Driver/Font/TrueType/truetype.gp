##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	TrueType Font Driver
# FILE:		truetype.gp
#
# AUTHOR:	Gene, 11/89
#
#
# Parameters file for: truetype.geo
#
#	$Id: truetype.gp,v 1.1 97/04/18 11:45:31 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	truetype.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
#library ansic
#
# Desktop-related things
#
longname	"TrueType Font Driver"
tokenchars	"FNTD"
tokenid		0
usernotes	"#FreeGEOS font driver to render TrueType fonts."
#
# Define resources other than standard discardable code
#
resource Resident 	fixed code read-only shared
resource Resident2 	fixed code read-only shared
resource ttcmap_TEXT 	fixed code read-only shared
resource ttmemory_TEXT 	fixed code read-only shared
resource ttcalc_TEXT 	fixed code read-only shared
resource InitMod	code read-only shared discard-only


#
# XIP-enabled
#
