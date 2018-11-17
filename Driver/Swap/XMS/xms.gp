##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Drivers -- XMS Swap driver
# FILE:		xms.gp
#
# AUTHOR:	Adam de Boor, June  13, 1990
#
#
#	$Id: xms.gp,v 1.1 97/04/18 11:58:04 newdeal Exp $
#
##############################################################################
#
# Specify name of geode
#
name xms.drvr
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
longname	"XMS Swap Driver"
tokenchars	"MEMD"
tokenid		0
#
# Override default resource flags
#
resource Init		preload, shared, read-only, code, swap-only
