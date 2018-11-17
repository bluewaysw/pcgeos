##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		kbdn_fr.gp
#
# AUTHOR:	Gene
#
# Parameters file for: kbdn_fr.geo
#
#	$Id: kbdn_fr.gp,v 1.1 97/04/18 11:47:10 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kbdn_fr.drvr
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
longname	"French Keyboard Driver"
tokenchars	"KBDD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource Movable preload code read-only
