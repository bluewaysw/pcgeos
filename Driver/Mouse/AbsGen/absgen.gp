##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Absolute Generic (uses INT 51 interface)
# FILE:		genmouse.gp
#
# AUTHOR:	Adam, 11/89
#
#
# Parameters file for: genmouse.geo
#
#	$Id: absgen.gp,v 1.1 97/04/18 11:47:59 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	absgen.drvr
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
longname 	"Absolute Generic Mouse"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Init preload shared code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
