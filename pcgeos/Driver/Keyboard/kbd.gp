##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		keyboard.gp
#
# AUTHOR:	Tony, 11/89
#
#
# Parameters file for: kbd.geo
#
#	$Id: kbd.gp,v 1.1 97/04/18 11:47:00 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kbd.drvr
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
longname	"US Keyboard Driver"
tokenchars	"KBDD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Movable preload shared code read-only discard-only
resource KbdExtendedInfoSeg lmem, read-only, shared, conforming
#
# XIP-enabled
#


