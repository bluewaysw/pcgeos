##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Mouse Systems
# FILE:		msys.gp
#
# AUTHOR:	Adam, 11/89
#
#
# Parameters file for: msys.geo
#
#	$Id: msys.gp,v 1.1 97/04/18 11:47:58 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	mSys.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
driver	serial
#
# Desktop-related things
#
longname 	"Mouse Systems Serial Mouse"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Init preload shared code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
