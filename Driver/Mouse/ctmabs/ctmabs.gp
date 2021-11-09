##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Absolute CuteMouse Wheel Mouse (uses INT 51 interface)
# FILE:		ctmabs.gp
#
# AUTHOR:	Adam, 11/89, MeyerK 09/2021
#
#
# Parameters file for: ctmabs.geo
#
#
##############################################################################
#
# Specify permanent name first
#
name	ctmabs.drvr
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
longname 	"Abs. coord. Wheel Mouse"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Init preload shared code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
