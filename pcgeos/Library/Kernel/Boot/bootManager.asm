cOMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Boot
FILE:		bootManager.asm

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
	Ted	2/89		Reads in an ASCII file to configure the system

DESCRIPTION:
	This file assembles the boot code.

	See the spec for more information.

	$Id: bootManager.asm,v 1.1 97/04/05 01:10:57 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include file.def
include graphics.def

include input.def
include lmem.def
include font.def
include initfile.def
include char.def
include localize.def
include win.def
include gcnlist.def
include product.def
	
include Internal/log.def
include Internal/geodeStr.def
include Internal/dos.def
include Internal/interrup.def
include Internal/debug.def
include Internal/fileInt.def

UseDriver Internal/fsDriver.def
UseDriver Internal/videoDr.def
UseDriver Internal/powerDr.def
UseDriver Internal/kbdDr.def
UseDriver Internal/swapDr.def
UseDriver Internal/fontDr.def
UseDriver Internal/taskDr.def

;--------------------------------------

include bootMacro.def		;BOOT macros
include bootConstant.def	;BOOT constants

;-------------------------------------

include bootVariable.def	;sets up its own segments
include bootInitfileVariable.def

;-------------------------------------

include bootStrings.asm

kcode	segment

include bootBoot.asm

kcode	ends
;-------------------------------------

kinit	segment

include bootInit.asm
include bootInitfile.asm
include bootLog.asm

kinit	ends


end	BootGeos
