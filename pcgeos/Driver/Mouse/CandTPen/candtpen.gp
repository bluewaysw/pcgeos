##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Gazelle Pen
# FILE:		candtpen.gp
#
# AUTHOR:	Dave, 1/93
#
#
# Parameters file for: candtpen.geo
#
#	$Id: candtpen.gp,v 1.1 97/04/18 11:48:06 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	candtpen.drvr
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
