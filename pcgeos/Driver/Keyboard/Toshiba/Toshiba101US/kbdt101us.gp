##############################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS/J
# MODULE:	Kernel
# FILE:		kbdt101us.gp
#
# AUTHOR:	Tera
#
# Parameters file for: kbdt101us.geo
#
#	$Id: kbdt101us.gp,v 1.1 97/04/18 11:47:46 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	kbdt101us.drvr
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
longname	"Toshiba 101US"
tokenchars	"KBDD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only
resource Movable preload code read-only
