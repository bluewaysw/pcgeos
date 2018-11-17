
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Okidata Print Driver
FILE:		oki9ControlCodes.asm

AUTHOR:		Dave Durran, 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision
	Dave	5/92		Initial 2.0 version


DC_ESCRIPTION:
	This file contains all the style setting routines for the oki9 
	driver.
		
	$Id: oki9ControlCodes.asm,v 1.1 97/04/18 11:53:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE OKI 9-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
	byte	1
	byte	C_DC1		;enable printing.
pr_codes_InitPrinter    label   byte
	byte	15		;byte count
	byte	C_ESC,"%C001"	;set margin all the way to left.
	byte	01eh		;set 10-pitch
	byte	C_ESC,04bh	;reset superscript
	byte	C_ESC,04dh	;reset subscript
	byte	C_ESC,"I"	;reset bold
	byte	C_ESC,"D"	;reset underline
pr_codes_InitTextMode   label   byte
        byte    C_NULL               ;count

;__________Cursor Control______________________________________
pr_codes_InitPaperLength        label   byte
        byte    8
	byte	C_ESC,"%9",PR_MAX_LINE_FEED	;set line spacing to max 
	byte	C_ESC,"F99"			;set the form length to 99 line
pr_codes_FormFeed       label   byte
        byte    6
        byte    C_ESC,"%9",2     ;set 2/144" line spacing.
        byte    C_ESC,"F"       ;set the page length.
pr_codes_SetTab	label	byte
	byte	2,C_ESC,C_HT
pr_codes_DoTab	label	byte
	byte	2,C_CR,C_HT
pr_codes_SetLineFeed    label   byte
	byte	3,C_ESC,"%","9"
pr_codes_SetMaxLineFeed label   byte
	byte	4,C_ESC,"%","9",PR_MAX_LINE_FEED
pr_codes_Do1ScanlineFeed       label   byte
	byte	5,C_ESC,"%","9",1,C_LF



;__________Graphics Control______________________________________
pr_codes_EnterGraphics	label	byte
	byte	3,C_CR,1ch,03h
pr_codes_ExitGraphics	label	byte
	byte	2, 03h, 02h

;__________Pitch Control______________________________________
pr_codes_Set5Pitch	label	byte
	byte	2, 01eh, 01fh
pr_codes_Set6Pitch	label	byte
	byte	2, 01ch, 01fh
pr_codes_Set10Pitch	label	byte
	byte	1, 01eh
pr_codes_Set12Pitch	label	byte
	byte	1, 01ch
pr_codes_Set17Pitch	label	byte
	byte	1, 01dh
pr_codes_SetProportional	label	byte
	byte    C_NULL	;no proport. code, but code has to be present.

;__________Style Control______________________________________
pr_codes_SetSubscript	label	byte
	byte	2,C_ESC,"L"
pr_codes_SetSuperscript	label	byte
	byte	2,C_ESC,"J"
pr_codes_SetNLQ	label	byte
	byte	2,C_ESC,"1"
pr_codes_SetBold	label	byte			
	byte	2,C_ESC,"H"
pr_codes_SetItalic	label	byte
	byte	2,C_ESC,"T"
pr_codes_SetUnderline	label	byte
	byte	2,C_ESC,"C"

pr_codes_ResetSuperscript	label	byte
	byte	2,C_ESC,04bh
pr_codes_ResetSubscript	label	byte
	byte	2,C_ESC,04dh
pr_codes_ResetNLQ	label	byte
	byte	2,C_ESC,"0"
pr_codes_ResetBold	label	byte
	byte	2,C_ESC,"I"
pr_codes_ResetItalic	label	byte
	byte	2,C_ESC,"I"
pr_codes_ResetUnderline	label	byte
	byte	2,C_ESC,"D"

