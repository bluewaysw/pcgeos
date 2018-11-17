##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Video Drivers -- Null
# FILE:		null.gp
#
# AUTHOR:	Adam, 11/89
#
# Parameters file for: null.geo
#
#	$Id: null.gp,v 1.1 97/04/18 11:43:45 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	null.drvr
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
longname	"Null Video Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices   lmem, shared, read-only, conforming
