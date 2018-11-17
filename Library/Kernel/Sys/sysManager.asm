COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel -- General System Things
FILE:		sysManager.asm


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/89		Initial version

DESCRIPTION:
	This file assembles the Sys code.


	$Id: sysManager.asm,v 1.1 97/04/05 01:15:02 newdeal Exp $

------------------------------------------------------------------------------@

ifndef HARDWARE_TYPE
HARDWARE_TYPE	equ	<PC>		; Choices include:
						;	PC
						;	ZOOMER (XIP only)
						;	BULLET (XIP only)

endif

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------
include assert.def
include sem.def
include object.def
include graphics.def
include win.def
include input.def
include Objects/metaC.def
include Objects/winC.def
include Objects/inputC.def
include gcnlist.def

include Internal/im.def
UseDriver Internal/powerDr.def
UseDriver Internal/videoDr.def
UseDriver Internal/kbdDr.def
if	USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
UseDriver Internal/mouseDr.def
endif
UseDriver Internal/taskDr.def
include Internal/fileInt.def
include Internal/interrup.def
include Internal/dos.def

include	profile.def

;--------------------------------------

include sysConstant.def		;SYS constants

;-------------------------------------

include sysVariable.def		;sets up its own segments

;-------------------------------------

kcode	segment
include sysStats.asm
include sysError.asm
include sysMisc.asm
include sysInterrupt.asm
include sysProfile.asm

kcode	ends

include sysScreen.asm
include sysNotification.asm
include sysC.asm
include sysErrorNotKCode.asm	; code too big to fit in kcode
include sysUtilWindow.asm

;-------------------------------------

kinit	segment
include sysInit.asm
kinit	ends


end
