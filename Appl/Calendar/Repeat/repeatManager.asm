COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Repeat
FILE:		repeatManager.asm

AUTHOR:		Don Reeves, October 25, 1989

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/25/89	Initial revision
	Don	11/20/89	Made into a manager file

DESCRIPTION:
	Implements the creation (in the dialog boxes), storage,  and
	generation of repeating events.
		
	$Id: repeatManager.asm,v 1.1 97/04/04 14:48:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Repeat		= 1				; module being defined

; Included definitions
;
include		calendarGeode.def		; geode info
include		calendarConstant.def		; constants, structures
include		calendarGlobal.def		; globals
include		calendarMacro.def		; macros
include		timedate.def			; time kernel call

UseLib		dbase.def

; A few constants
;
NUM_REPEAT_TABLES	= 5			; number of tables

udata	segment

startRepeatTable	label	word
	repeatTableHeader	RepeatTableHeader<>
	repeatTableStructs	RepeatTableStruct NUM_REPEAT_TABLES dup (<>)
endRepeatTable		label	word

udata	ends

TOTAL_REPEAT_TABLE_SIZE	= endRepeatTable - startRepeatTable


udata	segment
	GenDayArray	byte	7 dup (?)	; seven bytes of fun
	weeklyYear	word	(?)		; temp storage used by GenWeek
	repeatMapGroup	word	(?)		; group # for RepeatMap
	repeatMapItem	word	(?)		; item # for RepeatMap
	tableHandle	hptr			; current RepeatTable handle
	tableChunk	nptr			; current RepeatTable chunk
	repeatLoadID	word	(?)		; used to load single Events
	repeatGenProc	word	(?)		; AddNewEvent or DeleteEvent
	newYear		byte	(?)		; TRUE if a new year
ifndef	GCM
	repeatBlockHan	word	(?)		; the RepeatBlock handle
endif
udata	ends


; Now include the actual repeat code
;
include		repeatCreate.asm		; creates a new repeat event
include		repeatDatabase.asm		; store/retrieve repeat events
include		repeatDynamic.asm		; the dynamic list utilities
include		repeatGenerate.asm		; generates the repeat events
include		repeatTable.asm			; repeat table routines
include		repeatUtils.asm			; repeat utilities

end
