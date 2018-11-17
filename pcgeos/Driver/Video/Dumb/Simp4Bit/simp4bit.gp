##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Simp4Bit video driver
# FILE:		simp4bit.gp
#
# AUTHOR:	Adam, 10/89
#
#
# Parameters file for: simp4bit.geo
#
#	$Id: simp4bit.gp,v 1.1 97/04/18 11:43:47 newdeal Exp $
#
##############################################################################
#
#
# Specify permanent name first
#
name	simp4bit.drvr
#
# Specify geode type
#
type	driver, single, system
#
# Import kernel routine definitions
#
library	geos
#
# Desktop-related things
#
longname	"Simple 16-Color Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices	lmem, shared, read-only, conforming
resource VideoBitmap 	read-only, code, fixed
