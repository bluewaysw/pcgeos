##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	VideoDriver
# FILE:		vga.gp
#
# AUTHOR:	Jim, 10/91
#
# Parameters file for: vga.geo
#
#	$Id: vga.gp,v 1.1 97/04/18 11:41:59 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	vga.drvr
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
longname	"Standard VGA Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices   lmem, shared, read-only, conforming

#
# XIP-enabled
#
