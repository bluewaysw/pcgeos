COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskmaxManager.asm

AUTHOR:		Adam de Boor, Sep 19, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/19/91		Initial revision


DESCRIPTION:
	da file what gets compiled.
		

	$Id: taskmaxManager.asm,v 1.1 97/04/18 11:58:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TASKMAX		equ TRUE

include	taskGeode.def

include	taskmaxConstant.def
include taskmaxVariable.def

include taskmax.rdef

include taskStrings.asm		; switcher-independent strings
include taskmaxStrings.asm	; switcher-dependent strings

include taskInit.asm		; switcher-independent initialization
include taskmaxInitExit.asm

include	taskSwitch.asm		; switcher-independent system suspend/resume
				;  code

include	taskApplication.asm	; switcher-independent GenApp subclass
include	taskmaxApplication.asm	; switcher-dependent methods for same

include taskDriver.asm		; switcher-independent device driver interface
include taskmaxDriver.asm	; switcher-dependent implementation of some
				;  driver functions

include taskTrigger.asm		; switcher-independent express menu control's
				;	dos-task list entry
include	taskItem.asm		; switcher-independent dos-task list entry
include	taskmaxItem.asm		; switcher-dependent methods for same

include taskUtils.asm		; general utility routines
include taskmaxUtils.asm

include	taskmaxMain.asm		; switcher-dependent implementation of
				;  TaskDriverClass methods

include	taskmaxSummons.asm	; special control box support specific to this
				;  switcher.

include taskClipboard.asm
include taskmaxClipboard.asm
