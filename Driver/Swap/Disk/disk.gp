##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Drivers -- Disk Swap driver
# FILE:		disk.gp
#
# AUTHOR:	Adam de Boor, June  12, 1990
#
#
#	$Id: disk.gp,v 1.1 97/04/18 11:58:04 newdeal Exp $
#
##############################################################################
#
# Specify name of geode
#
name disk.drvr
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
longname	"Disk Swap Driver"
tokenchars	"MEMD"
tokenid		0
#
# Override default resource flags
#
resource Init		preload, shared, read-only, code, swap-only
resource Resident	shared, read-only, code, fixed

#
# XIP-enabled
#
