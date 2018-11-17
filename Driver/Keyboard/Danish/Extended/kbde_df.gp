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
# Parameters file for: kbde_df.geo
#
#	$Id: kbde_df.gp,v 1.1 97/04/18 11:46:53 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kbde_df.drvr
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
longname	"Danish Extended Keyboard"
tokenchars	"KBDD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource Movable preload code read-only
