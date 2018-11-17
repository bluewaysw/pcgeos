##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- MicroSoft Serial
# FILE:		msser.gp
#
# AUTHOR:	Adam, 11/89
#
#
# Parameters file for: msser.geo
#
#	$Id: msser.gp,v 1.1 97/04/18 11:48:01 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	msSer.drvr
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
longname 	"Microsoft Serial Mouse"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource Init preload code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
