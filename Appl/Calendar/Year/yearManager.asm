COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Year
FILE:		yearManager.asm

AUTHOR:		Don Reeves, 3-03-91

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/03/91		Initial revsion

DESCRIPTION:
	Manager for the Year object module
		
	$Id: yearManager.asm,v 1.1 97/04/04 14:49:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Year	= 1					; module being defined

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
idata		segment
	MonthClass
	YearClass
idata		ends


udata   segment
udata   ends


; Include source files
;
include		yearMonth.asm
include		yearYearMain.asm
include		yearYearMouse.asm
include		yearYearPrint.asm
end
