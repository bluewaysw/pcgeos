##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Video Driver
# FILE:		svga.gp
#
# AUTHOR:	Jim, 9/90
#
# Parameters file for: svga.geo
#
#	$Id: svga.gp,v 1.1 97/04/18 11:42:23 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	svga.drvr
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
longname	"Super VGA 800x600 16-clr"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices   lmem, shared, read-only, conforming

