##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Drivers -- Extended Memory driver
# FILE:		extmem.gp
#
# AUTHOR:	Adam de Boor, Nov  5, 1989
#
#
# Parameters for extended memory driver
#
#	$Id: extmem.gp,v 1.1 97/04/18 11:58:03 newdeal Exp $
#
##############################################################################
#
# Specify name of geode
#
name extMem.drvr
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
longname	"Extended-Memory Driver"
tokenchars	"MEMD"
tokenid		0
#
# Override default resource flags
#
resource Init		preload, swap-only, shared, read-only, code
