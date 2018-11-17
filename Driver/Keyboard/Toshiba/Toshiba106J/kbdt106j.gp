##############################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS/J
# MODULE:	Kernel
# FILE:		kbdt106j.gp
#
# AUTHOR:	Tera
#
# Parameters file for: kbdt106j.geo
#
#	$Id: kbdt106j.gp,v 1.1 97/04/18 11:47:48 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kbdt106j.drvr
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
longname	"Toshiba 106J"
tokenchars	"KBDD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource Movable preload code read-only
