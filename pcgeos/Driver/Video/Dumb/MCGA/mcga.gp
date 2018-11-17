##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Video Drivers -- MCGA
# FILE:		mcga.gp
#
# AUTHOR:	Adam, 11/89
#
# Parameters file for: mcga.geo
#
#	$Id: mcga.gp,v 1.1 97/04/18 11:42:32 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	mcga.drvr
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
longname	"MCGA Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices   lmem, shared, read-only, conforming
