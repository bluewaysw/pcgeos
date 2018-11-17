COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/DayPlan
FILE:		dayplanManager.asm

AUTHOR:		Don Reeves, March 2, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/2/91		Initial revision

DESCRIPTION:
	Manager file for DayPlan module
		
	$Id: dayplanManager.asm,v 1.1 97/04/04 14:47:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_DayPlan	= 1				; module being defined

; Included definitions
;
include		calendarGeode.def		; geode declarations
include		calendarConstant.def		; structure definitions
include		calendarGlobal.def		; global definitions
include		calendarMacro.def		; macro definitions
include		vm.def
include		initfile.def			; initfile definitions

UseLib		dbase.def

if HANDLE_MAILBOX_MSG
include		Mailbox/appt.def
endif

;Common variables & constants
;
LARGE_BLOCK_SIZE 	= 0xA000		; 40K
OFF_SCREEN_TOP		= -1			; inital values for EventTable
OFF_SCREEN_BOTTOM	= 0

idata	segment
	DayPlanClass
	timeOffset	word EVENT_TIME_OFFSET	; offset to the time field
idata	ends

udata	segment
	SizeTextObject		nptr (?)	; handle to the text object
	oneLineTextHeight	word (?)	; height of one line of text
	timeWidth		word (?)	; width of the time field
	yIconOffset		word (?)	; vertical offset at which
						; ...to draw event icon
udata	ends


;Included source files
;
include		dayplanInit.asm			; the init & detach code
include		dayplanBuffer.asm		; the buffer code
include		dayplanMain.asm			; the main bulk of the code
include		dayplanRange.asm		; the range set-up code
include		dayplanPrint.asm		; the printing code
include		dayplanPreference.asm		; the preference setting code
include		dayplanMailbox.asm		; the mailbox event code
include		dayplanApi.asm			; Calendar API code
include		dayplanUtils.asm		; shared utility code

end
