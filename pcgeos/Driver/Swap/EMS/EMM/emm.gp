##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Drivers -- Expanded Memory driver
# FILE:		emm.gp
#
# AUTHOR:	Adam de Boor, June  19, 1990
#
#
# Parameters for emm memory driver
#
#	$Id: emm.gp,v 1.1 97/04/18 11:58:00 newdeal Exp $
#
##############################################################################
#
# Specify name of geode
#
name emm.drvr
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
longname	"Expanded Memory EMM Driver"
tokenchars	"MEMD"
tokenid		0

resource Init preload, shared, code, read-only, swap-only
