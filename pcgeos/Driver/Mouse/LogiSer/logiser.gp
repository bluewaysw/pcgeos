##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Logitech C7
# FILE:		logiser.gp
#
# AUTHOR:	Adam, 11/89
#
#
# Parameters file for: logiser.geo
#
#	$Id: logiser.gp,v 1.1 97/04/18 11:48:00 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	logiSer.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
driver 	serial
#
# Desktop-related things
#
longname 	"Logitech Serial Mouse"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Init preload shared code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming

