##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse Drivers -- Casio Zoomer pen mouse driver
# FILE:		casiopen.gp
#
# AUTHOR:	Don, 11/92
#
#
# Parameters file for: casiopen.geo
#
#	$Id: casiopen.gp,v 1.1 97/04/18 11:48:07 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	casiopen.drvr
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
longname 	"Z Pen Driver"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident 		shared code read-only fixed
resource Init 			shared code read-only swap-only preload
resource MouseExtendedInfoSeg	lmem, read-only, shared, conforming
