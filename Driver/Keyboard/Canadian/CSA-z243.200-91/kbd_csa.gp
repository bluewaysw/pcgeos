##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		keyboard.gp
#
# AUTHOR:	Gene
#
# Parameters file for: kbd_csa.geo
#
#	$Id: kbd_csa.gp,v 1.1 97/04/18 11:47:26 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kbd_csa.drvr
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
longname	"CAN/CSA-Z243.200-91 Keyboard"
tokenchars	"KBDD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource Movable preload shared code read-only discard-only
