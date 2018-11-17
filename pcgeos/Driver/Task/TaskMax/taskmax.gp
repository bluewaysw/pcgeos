##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		taskmax.gp
#
# AUTHOR:	Adam de Boor, Sep 19, 1991
#
#
# 
#
#	$Id: taskmax.gp,v 1.1 97/04/18 11:58:06 newdeal Exp $
#
##############################################################################
#
name taskmax.drvr

type driver, process, single, system

appobj TaskApp
class TaskMaxClass
#
# Desktop stuff
#
longname "TaskMax Task Driver"
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
resource ControlBox object
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
