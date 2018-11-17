COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Lizzy
MODULE:		Calendar/Week
FILE:		weekManager.asm

AUTHOR:		Andrew Wu, Jan 23, 1997

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	awu	1/23/97   	Initial revision


DESCRIPTION:
		
	Manager for Week object module

	$Id: weekManager.asm,v 1.1 97/04/04 14:49:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; Included definitions
;
include		calendarGeode.def		; geode declarations
include		calendarConstant.def		; structure definitions
include		calendarGlobal.def		; global definitions
include		calendarMacro.def		; macro definitions
include		input.def
include		timedate.def			; to get time & data
include		Objects/inputC.def

; Idata and other common information
;


; Include source files
;
include		weekViewInteractionClass.asm
include		weekDateTextContent.asm
include		weekScheduleContentClass.asm
include		weekEventTextContentClass.asm
end
