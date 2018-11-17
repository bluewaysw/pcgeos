##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Video Drivers -- CGA
# FILE:		cga.gp
#
# AUTHOR:	Adam, 11/89
#
# Parameters file for: cga.geo
#
#	$Id: cga.gp,v 1.1 97/04/18 11:42:32 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	cga.drvr
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
longname	"CGA Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices	lmem, shared, read-only, conforming
