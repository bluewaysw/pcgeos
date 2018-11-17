##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Comm (Communication driver)
# FILE:		Comm.gp
#
# AUTHOR:	Insik, 7/92
#
#
# Parameters file for: Comm.geo
#
#	$Id: comm.gp,v 1.1 97/04/18 11:48:46 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	Comm.drv
#
# Specify geode type
#
type	driver, single 
#
# Import kernel routine definitions
#
library	geos 
library net
#
# Desktop-related things
#
longname	"Comm Driver"
tokenchars	"COMD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident		fixed code read-only shared
#
# Exported classes/routines
#



#
# XIP-enabled
#
