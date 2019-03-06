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
#	$Id: vga8.gp,v 1.2 96/08/05 03:51:56 canavese Exp $
#
##############################################################################
#
# Specify permanent name first
#
name    vga15.drvr
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
longname        "VESA 32K-color SVGA Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices   lmem, shared, read-only, conforming

usernotes "Copyright 1996-97 Breadbox Computer Company"
