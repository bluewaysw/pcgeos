##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- GRiDPAD pen mouse driver
# FILE:		gridpen.gp
#
# AUTHOR:	Gene, 7/90
#
#
# Parameters file for: gridpen.geo
#
#	$Id: gridpen.gp,v 1.1 97/04/18 11:48:02 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	gridpen.drvr
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
longname 	"GRiDPAD Pen Driver"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Init preload shared code read-only swap-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
