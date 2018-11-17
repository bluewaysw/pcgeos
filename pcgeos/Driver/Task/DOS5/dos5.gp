##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		dos5.gp
#
# AUTHOR:	Adam de Boor, Sep 19, 1991
#
#
# 
#
#	$Id: dos5.gp,v 1.1 97/04/18 11:58:20 newdeal Exp $
#
##############################################################################
#
name dos5.drvr

type driver, process, single, system

appobj TaskApp
class DOS5Class
#
# Desktop stuff
#
longname "MS-DOS 5.0 Task Driver"
tokenchars "TSKD"
tokenid 0

library ui
library geos
library text

#
# We use text objects, so we need the room.
#
stack	3000

resource Interface object
resource Resident shared code read-only fixed
resource TaskStrings shared lmem read-only
#
# used only by other people, and that seldom; no point in swapping it, and it
# never changes
#
resource TaskDriverExtInfo shared lmem read-only discard-only
#
# Export needed classes for object relocations
#
export	TaskApplicationClass
export	TaskItemClass
export	TaskTriggerClass
export	TaskMaxSummonsClass
