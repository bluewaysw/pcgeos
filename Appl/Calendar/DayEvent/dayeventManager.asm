COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/DayEvent
FILE:		dayeventManager.asm

AUTHOR:		Don Reeves, September 1, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/1/89		Initial revision

DESCRIPTION:
	Manager file for DayEvent module
		
	$Id: dayeventManager.asm,v 1.1 97/04/04 14:47:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_DayEvent	= 1				; module being defined

; Included definitions
;

include		calendarGeode.def		; geode declarations
include		calendarConstant.def		; structure definitions
include		calendarGlobal.def		; global definitions
include		calendarMacro.def		; macro definitions
include		input.def


UseLib		dbase.def

; Class definitions & misc info
;
idata		segment
	DayEventClass
	PrintEventClass
	MyTextClass
idata		ends

DayEventCode	segment resource

SBCS <blankByte	byte	0			; useful for NULL strings >
DBCS <blankByte	wchar	0			; useful for NULL strings >

DayEventCode	ends


;Included source files
;
include		dayeventAlarm.asm
include		dayeventDraw.asm
include		dayeventMain.asm
include		dayeventMisc.asm
include		dayeventSentToList.asm

end






