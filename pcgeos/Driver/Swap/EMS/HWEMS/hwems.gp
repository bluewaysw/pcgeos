##############################################################################
#
#	Copyright (c) GeoWorks 1995 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Drivers -- EMS swap driver
# FILE:		hwspec.gp
#
# AUTHOR:	Andrew Wilson, May  3, 1995
#
#
# Parameters file for: hwspec.gp
#
#	$Id: hwems.gp,v 1.1 97/04/18 11:58:02 newdeal Exp $
#
##############################################################################
#
# Specify name of geode
#
      name hwems.drvr
#
# Specify type of geode (driver that may only be launched once)
#
type driver, single, system
#
# Import kernel routine definitions
#
library geos
library swap
#
# Desktop-related things
#

      longname	"HW-specific EMS Swap Driver"

tokenchars	"MEMD"
tokenid		0

resource Init preload, shared, code, read-only, swap-only


