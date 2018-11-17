##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- MSBus
# FILE:		msbus.gp
#
# AUTHOR:	Adam, 11/89
#
#
# Parameters file for: msbus.geo
#
#	$Id: msbus.gp,v 1.1 97/04/18 11:48:02 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	msBus.drvr
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
longname 	"Microsoft Bus Mouse"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Init preload shared code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
