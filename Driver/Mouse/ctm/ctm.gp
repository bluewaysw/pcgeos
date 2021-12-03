##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Generic (uses MicroSoft INT 51 interface) with
# CuteMouse Wheel Api extensions
# FILE:		ctm.gp
#
# AUTHOR:	Adam, 11/89; MeyerK 09/2021
#
# Parameters file for: ctm.geo
#
#
##############################################################################
#
# Specify permanent name first
#
name	ctm.drvr
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
longname 	"CuteMouse-supported Wheel Mouse"
tokenchars 	"MOUS"
tokenid 	0
#
# Platform for product variant
#
ifdef PRODUCT_GEOS2X
platform geos20
endif
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Init preload shared code read-only
resource MouseExtendedInfoSeg lmem read-only shared conforming
