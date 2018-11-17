##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Poqet Pen
# FILE:		pqpen.gp
#
# AUTHOR:	Tony, 2/92
#
#
# Parameters file for: pqpen.geo
#
#	$Id: pqpen.gp,v 1.1 97/04/18 11:48:05 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	pqpen.drvr
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
longname 	"Poqet Pen Digitizer"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
