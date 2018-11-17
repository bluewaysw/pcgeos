##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		kps1_fr.gp
#
# AUTHOR:	Gene
#
# Parameters file for: kps1_fr.geo
#
#	$Id: kps1_fr.gp,v 1.1 97/04/18 11:47:13 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kps1_fr.drvr
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
longname	"French PS/1 Keyboard Driver"
tokenchars	"KBDD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource Movable preload shared code read-only discard-only
