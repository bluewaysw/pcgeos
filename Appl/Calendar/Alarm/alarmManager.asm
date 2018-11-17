COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Alarm
FILE:		alarmManager.asm

AUTHOR:		Don Reeves, September 1, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/1/89		Initial revision

DESCRIPTION:
	Manager file for Alarm module
		
	$Id: alarmManager.asm,v 1.1 97/04/04 14:47:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Alarm	= 1					; module being defined

; Included definitions
;
include		calendarGeode.def		; geode declarations
include		calendarConstant.def		; structure definitions
include		calendarGlobal.def		; global definitions
include		calendarMacro.def		; macro definitions
include		timedate.def			; timer definitions
include		vm.def				; definitions for kernel VM
include		sound.def			; sound definitions

UseLib		dbase.def			; definitions for database
						;  library
UseLib		rtcm.def			; definitions for
						; RealTimeClock library


;Included source files
;
include		alarmAlarm.asm			; active alarm checking
include		alarmReminder.asm		; on screen reminders
