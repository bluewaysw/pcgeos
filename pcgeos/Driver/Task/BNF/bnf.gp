##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		bnf.gp
#
# AUTHOR:	Adam de Boor, Sep 19, 1991
#
#
# 
#
#	$Id: bnf.gp,v 1.1 97/04/18 11:58:09 newdeal Exp $
#
##############################################################################
#
name bnf.drvr

type driver, process, single, system

appobj TaskApp
class BNFClass
#
# Desktop stuff
#
longname "Back & Forth Task Driver"
tokenchars "TSKD"
tokenid 0

library ui
library geos
library text

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
export 	BNFSummonsClass
