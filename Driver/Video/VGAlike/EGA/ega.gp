##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Video Drivers
# FILE:		ega.gp
#
# AUTHOR:	Adam, 10/89
#
# Parameters file for: ega.geo
#
#	$Id: ega.gp,v 1.1 97/04/18 11:42:09 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	ega.drvr
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
longname	"EGA Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices	lmem, shared, read-only, conforming
