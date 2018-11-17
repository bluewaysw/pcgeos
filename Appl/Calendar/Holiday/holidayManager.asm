COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS J
MODULE:		JCalendar/Holiday
FILE:		holidayManager.asm

AUTHOR:		TORU TERAUCHI, JUL 28, 1993

ROUTINES:
	NAME			DESCRIPTION
	----			-----------

	
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	Tera	7/28/93   	INITIAL REVISION


DESCRIPTION:
	Set holidays.
		

	$Id: holidayManager.asm,v 1.1 97/04/04 14:49:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_Holiday	= 1				; module being defined

; Included definitions
;
include		calendarGeode.def		; geode info
include		calendarConstant.def		; constants, structures
include		calendarGlobal.def		; globals
include		calendarMacro.def		; macros

;------------------------------------------------------------------------------
;			Class
;------------------------------------------------------------------------------
idata	segment

if PZ_PCGEOS ; Pizza
	SetHolidayInteractionClass
endif

idata	ends

;------------------------------------------------------------------------------
;			Global Variables
;------------------------------------------------------------------------------

idata	segment

if PZ_PCGEOS ; Pizza

; Need for reading / writing holiday file
;
fileHandle	DW	0h			; PC/GEOS file handle
dummyData	DB	0h			; dummy buffer for data
charData	DB	20 dup (0h)		; buffer for char data
						; max word length = 20-1
charDataNum	DW	0h			; number of char data


; The holiday flag
;
HF_nation	DB	'NationalHoliday:'	; key code
HF_repeat	DB	'RepeatHoliday:'
HF_holiday	DB	'PersonalHoliday:'
HF_weekday	DB	'PersonalWeekday:'
HF_sunday	DB	'Sun'			; week
HF_monday	DB	'Mon'
HF_tuesday	DB	'Tue'
HF_wednesday	DB	'Wed'
HF_thursday	DB	'Thu'
HF_friday	DB	'Fri'
HF_saturday	DB	'Sat'
HF_january	DB	'Jan'			; month
HF_february	DB	'Feb'
HF_march	DB	'Mar'
HF_april	DB	'Apr'
HF_may		DB	'May'
HF_june		DB	'Jun'
HF_july		DB	'Jul'
HF_august	DB	'Aug'
HF_september	DB	'Sep'
HF_october	DB	'Oct'
HF_november	DB	'Nov'
HF_december	DB	'Dec'

endif

idata	ends

if PZ_PCGEOS ; Pizza
; Now include the actual holiday code
;
include		holidaySetting.asm		; setting of a new holiday
include		holidayFile.asm			; read / write holiday file
include		holidayData.asm			; set / get holiday data
include		holidayUtils.asm		; holiday utilities
endif

end

