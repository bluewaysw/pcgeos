##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Video Driver
# FILE:		vga8.gp
#
# AUTHOR:	Jim, 10/92
#
# Parameters file for: vga8.geo
#
#	$Id: vga8.gp,v 1.1 97/04/18 11:42:06 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	vga8.drvr
#
# Specify geode type
#
type	driver, single, system
#
# Import kernel routine definitions
#
library	geos
#
# Desktop-related things
#
longname	"VESA 256-color SVGA Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices   lmem, shared, read-only, conforming
