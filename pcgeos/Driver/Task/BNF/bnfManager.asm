COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bnfManager.asm

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
		

	$Id: bnfManager.asm,v 1.1 97/04/18 11:58:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_Driver         = 1

BACK_AND_FORTH	= TRUE

include	taskGeode.def

include	bnfConstant.def
include bnfVariable.def

include bnf.rdef

include taskStrings.asm		; switcher-independent strings
include bnfStrings.asm		; switcher-dependent strings

include taskInit.asm		; switcher-independent initialization
include bnfInitExit.asm		; switcher-dependent initialization & exit

include	taskSwitch.asm		; switcher-independent system suspend/resume
				;  code

include	taskApplication.asm	; switcher-independent GenApp subclass
include	bnfApplication.asm	; switcher-dependent methods for same

include taskDriver.asm		; switcher-independent device driver interface
include bnfDriver.asm		; switcher-dependent implementation of some
				;  driver functions

include taskTrigger.asm		; switcher-independent express menu control's
				;	dos-task list entry
include	taskItem.asm		; switcher-independent dos-task list entry
include	bnfItem.asm		; switcher-dependent methods for same

include taskUtils.asm		; general utility routines
include bnfUtils.asm

include	bnfMain.asm		; switcher-dependent implementation of
				;  TaskDriverClass methods

include bnfSummons.asm		; special control box support specific to this
				;  switcher.

include taskClipboard.asm	; switcher-independent clipboard support
include bnfClipboard.asm	; switcher-dependent routines for same
