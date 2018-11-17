COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Timer
FILE:		timerManager.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name				Description
	----				-----------
   GLB	TimerStart			Start a timer
   GLB	TimerSleep			Sleep for a given ammount of time
   GLB	TimerBlockOnTimedQueue		Block on a semaphore with timeout
   GLB	TimerStop			Remove a timer
   GLB	TimerGetCount			Return system time counter
   GLB	TimerGetDateAndTime		Get system time and date
   GLB	TimerSetDateAndTime		Set system time and date
   GLB	SysInfo				Get general system information
   GLB	SysStatistics			Get system performance statistics

   EXT	InitTimer			Initialize the Timer module

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file assembles the Timer code.

	See the spec for more information.

	$Id: timerManager.asm,v 1.1 97/04/05 01:15:25 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include sem.def
include timer.def
include timedate.def
include object.def
include gcnlist.def

include Internal/geodeStr.def
include Internal/interrup.def
include Internal/dos.def
include Internal/timerInt.def	; For counting durations of operations
UseDriver Internal/powerDr.def

;--------------------------------------

include timerMacro.def		;TIMER macros
include timerConstant.def	;TIMER constants

;-------------------------------------

include timerVariable.def

;-------------------------------------

kcode	segment
include timerInt.asm
include timerList.asm
include timerMisc.asm
kcode	ends

include timerC.asm

;-------------------------------------

kinit	segment
include timerInit.asm
kinit	ends

end
