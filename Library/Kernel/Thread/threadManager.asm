COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Thread
FILE:		threadManager.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file assembles the thread code.

	See the spec for more information.

	$Id: threadManager.asm,v 1.1 97/04/05 01:15:14 newdeal Exp $

-------------------------------------------------------------------------------@
;----------------------------------------------------------------------------
;		Definitions
;----------------------------------------------------------------------------

_KernelThread	=	1	;Identify this module

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include Objects/processC.def
include sem.def
include object.def
include initfile.def

UseDriver Internal/powerDr.def
include Internal/interrup.def
include Internal/geodeStr.def		;includes: geode.def
include Internal/dos.def	;for ProgramSegmentPrefix (ThreadFindStack)
include Internal/debug.def
UseDriver Internal/taskDr.def
include	profile.def

if SINGLE_STEP_PROFILING
include Objects/inputC.def
endif

if SUPPORT_32BIT_DATA_REGS
.386				;enable 386 instructions
endif

;--------------------------------------

include threadMacro.def		;THREAD macros
include threadConstant.def	;THREAD constants

;-------------------------------------

include threadVariable.def

;-------------------------------------

kcode	segment
include threadErrorCheck.asm
include threadThread.asm
include threadSem.asm
include threadPrivate.asm
include threadException.asm
include threadProfile.asm
kcode	ends

include threadC.asm

;-------------------------------------

kinit	segment
include threadInit.asm
kinit	ends

end
