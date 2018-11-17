##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Any PS/2 System w/auxilary port
# FILE:		ps2.gp
#
# AUTHOR:	Adam, 11/89
#
#
# Parameters file for: ps2.geo
#
#	$Id: ps2.gp,v 1.1 97/04/18 11:47:57 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	ps2.drvr
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
longname 	"IBM PS/2 Mouse"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
