##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Scriptel Pen
# FILE:		gazelle.gp
#
# AUTHOR:	Dave, 6/92
#
#
# Parameters file for: gazelle.geo
#
#	$Id: gazelle.gp,v 1.1 97/04/18 11:48:06 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	gazelle.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
driver serial
#
# Desktop-related things
#
longname 	"Gazelle Pen Digitizer"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
