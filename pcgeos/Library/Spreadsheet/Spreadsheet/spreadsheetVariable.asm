COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetVariable.def

AUTHOR:		Gene Anderson, Feb 27, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/27/91		Initial revision


DESCRIPTION:
	Global varibles for the spreadsheet object.
		
	$Id: spreadsheetVariable.asm,v 1.1 97/04/07 11:13:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

;
; Never ever add anything here that isn't read-only.
;
; Having buffers that you can write to in a library isn't cool unless you
; have a semaphore to control access to them.
;

;
; Table of function tokens.
;
; Make sure the order of this table matches that of funcNameTable.
;
funcIDTable	word	FUNCTION_ID_SPREADSHEET_CELL	; @CELL function

;
; One entry for each function. Contains the flags to or in with the
; PP_flags when the function is parsed.
;
funcFlagsTable	word	mask PF_CONTAINS_DISPLAY_FUNC


;
; A list of offsets into dgroup where the names of the functions are
;
; Make sure the order of this table matches that of funcIDTable.
;
funcNameTable	word	offset dgroup:cellName

;
; Table of function names.
;	First byte	= Length of the name
;	Next bytes	= Text of the name
;
cellName	byte	4, "CELL"

;
; formatCount:
;	variable that is incremented so that it can be used in the
;	NotifyFloatFormatChange structure to force a notification to be sent.
;
formatCount	word	0


;
; The variable is used to tell whether we should center the selected cell.
; if it is 0, that means we don't have to center it. If it is non-zero, then
; we need to center the selected cell.
;
centerFlag	byte	0

idata	ends
