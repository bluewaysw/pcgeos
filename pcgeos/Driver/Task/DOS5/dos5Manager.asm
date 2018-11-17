COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Task-switch drivers -- MS DOS 5 DOSSHELL
FILE:		dos5Manager.asm

AUTHOR:		Adam de Boor, May  30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 5/92		Initial revision


DESCRIPTION:
	The file what gets compiled.
		

	$Id: dos5Manager.asm,v 1.1 97/04/18 11:58:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Common include files
;
include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include lmem.def
include system.def
include drive.def
include disk.def
include driver.def
include timedate.def
include localize.def
include initfile.def
include char.def
include input.def

UseDriver	Internal/kbdDr.def

DefDriver	Internal/taskDr.def

include Internal/fileInt.def
include Internal/dos.def
include Internal/fsd.def
include Internal/semInt.def

DOS5	equ	TRUE


include nontsConstant.def
include dos5Constant.def
include taskConstant.def

include nontsVariable.def
include dos5Variable.def
include taskVariable.def

include dos5.rdef

include dos5Entry.asm

; Stuff for shutting down and running DOS programs
include nontsExec.asm
include nontsShutdown.asm
include nontsStart.asm

include taskInit.asm		; switcher-independent initialization
include dos5InitExit.asm	; support for same.

include taskSwitch.asm		; switcher-independent suspend/resume
include dos5Switch.asm		; support routines

include taskApplication.asm	; switcher-independent GenApp subclass
include	dos5Application.asm	; support routines

include taskStrings.asm
include dos5Strings.asm

