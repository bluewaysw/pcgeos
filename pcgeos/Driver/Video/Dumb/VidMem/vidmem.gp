##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Video Drivers
# FILE:		vidmem.gp
#
# AUTHOR:	Jim, 10/89, from vga.gp
#
# Parameters file for: vidmem.geo
#
#	$Id: vidmem.gp,v 1.1 97/04/18 11:42:57 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	vidmem.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
#
# Desktop-related things (token is MVID, not VIDD, to avoid picking this
# up in setup/preferences as a viable video driver)
#
longname	"Memory Video Driver"
tokenchars	"MVID"
tokenid		0
#
# Make this module fixed so we can put the strategy routine there
#
resource Main fixed code read-only shared
resource monogroup code discardable swapable shared
resource clr4group code discardable swapable shared
resource clr8group code discardable swapable shared
resource clr24group code discardable swapable shared
resource cmykgroup code discardable swapable shared
