##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Mouse Drivers -- KBMouse (keyboard driven mouse, for people
#				 only use computers on the floor of CES shows...
# FILE:		kbmouse.gp
#
# AUTHOR:	Eric, 12/91	(Adapted from GenMouse)
#
# Parameters file for: kbmouse.geo
#
#	$Id: kbmouse.gp,v 1.1 97/04/18 11:48:04 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kbmouse.drvr
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
longname 	"Keyboard-run Mouse Driver"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Init preload shared code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
