##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		kbdn_it.gp
#
# AUTHOR:	Gene
#
# Parameters file for: kbdn_it.geo
#
#	$Id: kbdn_it.gp,v 1.1 97/04/18 11:47:18 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kbdn_it.drvr
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
longname	"Italian Keyboard Driver"
tokenchars	"KBDD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource Movable preload code read-only
