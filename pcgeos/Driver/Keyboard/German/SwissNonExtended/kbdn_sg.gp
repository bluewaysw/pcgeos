##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		kbdn_sg.gp
#
# AUTHOR:	Gene
#
# Parameters file for: kbdn_sg.geo
#
#	$Id: kbdn_sg.gp,v 1.1 97/04/18 11:47:17 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kbdn_sg.drvr
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
longname	"Swiss-German Keyboard Driver"
tokenchars	"KBDD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource Movable preload code read-only
