COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Interface Gadgets
MODULE:		Gadgets
FILE:		uiManager.asm

AUTHOR:		Skarpi Hedinsson, Jun 24, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/24/94   	Initial revision


DESCRIPTION:
	
		

	$Id: uiManager.asm,v 1.1 97/04/04 17:59:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include gadgetsGeode.def
include gadgetsVisMonikerUtil.def

;UseLib	Internal/Jedi/jlib.def

;
; Time/date format category & keys
;
TIMEDATE_CATEGORY_STRING	equ	<"system", C_NULL>
TIMEDATE_TIME_FMT_STRING	equ	<"timeFormat", C_NULL>

;---------------------------------------------
; Date/Time definitions
;

; The type in .INI under the key TIMEDATE_TIME_FMT_STRING
TimeFormatIdentifier		etype	word, 0, (size word)
TFI_AMPM			enum TimeFormatIdentifier
TFI_24HR			enum TimeFormatIdentifier

KeyAction		struct
	KA_char		word
	KA_handler	nptr.near	NULL
	KA_msg		word
KeyAction		ends

TS_NONE		equ	0
SS_NONE		equ	0
SS_ANYSHIFT	equ	(mask SS_LSHIFT or mask SS_RSHIFT)
SS_ANYCTRL	equ	(mask SS_LCTRL or mask SS_RCTRL)


;---

DefLib Objects/gadgets.def

;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

DateInputTextClass	class	GenTextClass
DateInputTextClass	endc

TimeInputTextClass	class	GenTextClass

MSG_TIME_INPUT_TEXT_SET_TIME_TYPE		message
;
; Sets the TITI_timeType value.
;
; PASS:		cx	= TimeInputType
; RETURN:	nothing
; DESTROYED:	nothing
;

MSG_TIME_INPUT_TEXT_DISPLAY_STRING_WHEN_EMPTY	message
;
; Name sez it all.
;
; PASS:		^ldx:bp	= string to display
; RETURN:	nothing
; DESTROYED:	ax, cx, dx, bp
;

MSG_TIME_INPUT_TEXT_SET_AMPM_MODE		message
;
; Turn AM/PM mode on or off.
;
; PASS:		cl	= BooleanByte (BB_FALSE = 24hr mode)
; RETURN:	nothing
; DESTROYED:	nothing
;

;-----------------------------------------------------------------------------
;		Instance Data
;-----------------------------------------------------------------------------

	TITI_timeType		TimeInputType		TIT_TIME_OF_DAY
		; What type of input gadget is this.  The default is
		; TIT_timeOfDay which allows AM/PM.

	TITI_drawNoneIfEmpty		BooleanByte	BB_FALSE
		; Should we display "NONE" when empty?

	TITI_notEmpty			BooleanWord	BW_TRUE
		; Is the text object currently empty?

	TITI_emptyString		optr.char	NULL
		; String to display when empty, if TITI_drawNoneIfEmpty
		; is not false.

	TITI_tempString			lptr.char	NULL
		; Storage space utilized by the parser.

	TITI_ampmMode			BooleanByte	BW_FALSE
		; Only affects us in TIT_TIME_OF_DAY_MODE: are
		; we in AM/PM mode?  Changes parsing strategy.

TimeInputTextClass	endc

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
GadgetsClassStructures	segment resource

	DateInputTextClass	; declare the custom date text class record
	TimeInputTextClass	; declare the custom time text class record

GadgetsClassStructures	ends

include uiManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include uiCommon.asm
include uiRepeatTrigger.asm
include uiDateSelector.asm
include uiDateInput.asm
include uiTimeInputParse.asm
include	uiTimeInputText.asm
include uiTimeInput.asm
include uiStopwatch.asm
include uiTimer.asm
include uiBatteryIndicator.asm

