
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Graphics Printer 9-pin Print Driver
FILE:		grpr9ControlCodes.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/93		Initial 2.0 version


DC_ESCRIPTION:
	This file contains all the Printer Control Codes for the Grpr 9-pin
	driver.
		
	$Id: grpr9ControlCodes.asm,v 1.1 97/04/18 11:55:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE IBM 9-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
	byte	1,C_NULL
pr_codes_InitPrinter	label	byte
	byte	10,0		;send a null to wait till after any reset garb
	byte	C_ESC,"O"	;cancel any perforation skipping.
	byte	C_ESC,"P",0,C_DC2 ;non proportional, 10 pitch
        byte    C_ESC,"U",1     ;set uni-directional
pr_codes_InitTextMode   label   byte
        byte    3               ;count
        byte    C_ESC,"U",0     ;set bi-directional

;__________ASF Control______________________________________
pr_codes_InitPaperLength        label   byte
        byte    4,C_ESC,"C",0,22 ;set page length to max (22")
pr_codes_FormFeed       label   byte
        byte    5
        byte    C_ESC,"3",3     ;set 3/216" line spacing.
        byte    C_ESC,"C"       ;set the page length.

;__________Cursor Control______________________________________
pr_codes_SetTab	label	byte
	byte	4,C_CR,C_SPACE,C_ESC,"D"
pr_codes_DoTab	label	byte
	byte	3,0,C_HT,C_SPACE	;space is for the column # starting
					;at column 1.
pr_codes_DoLineFeed     label   byte
        byte    2,C_ESC,"J"
pr_codes_DoMaxLineFeed      label   byte
        byte    3,C_ESC,"J",PR_MAX_LINE_FEED
pr_codes_Do1ScanlineFeed        label   byte
        byte    3,C_ESC,"J",1

;__________Graphics Control______________________________________
pr_codes_SetLoGraphics  label   byte
        byte    3,C_CR,C_ESC,"K"
pr_codes_SetMedGraphics label   byte
        byte    3,C_CR,C_ESC,"L"
pr_codes_SetHiGraphics  label   byte
        byte    3,C_CR,C_ESC,"Z"

;__________Pitch Control______________________________________
pr_codes_Set10Pitch		label	byte
	byte	4,C_ESC,"P",0,C_DC2
pr_codes_Set12Pitch		label	byte
	byte	5,C_ESC,"P",0,C_ESC,":"
pr_codes_SetProportional	label	byte
	byte	3,C_ESC,"P",1

;__________Style Control______________________________________
pr_codes_SetCondensed	label	byte
	byte	1,C_SI
pr_codes_SetSubscript	label	byte
	byte	3,C_ESC,"S",1
pr_codes_SetSuperscript	label	byte
	byte	3,C_ESC,"S",0
pr_codes_SetNLQ	label	byte
	byte	3,C_ESC,"I",2
pr_codes_SetBold	label	byte
	byte	4,C_ESC,"E",C_ESC,"G"
pr_codes_SetUnderline	label	byte
	byte	3,C_ESC,"-",1
pr_codes_SetOverline	label	byte
	byte	3,C_ESC,"_",1
pr_codes_SetDblWidth	label	byte
	byte	3,C_ESC,"W",1

pr_codes_ResetCondensed	label	byte
	byte	1,C_DC2
pr_codes_ResetScript	label	byte
	byte	2,C_ESC,"T"
pr_codes_ResetNLQ	label	byte
	byte	3,C_ESC,"I",0
pr_codes_ResetBold	label	byte
	byte	4,C_ESC,"F",C_ESC,"H"
pr_codes_ResetUnderline	label	byte
	byte	3,C_ESC,"-",0
pr_codes_ResetOverline	label	byte
	byte	3,C_ESC,"_",0
pr_codes_ResetDblWidth	label	byte
	byte	3,C_ESC,"W",0


;__________Color Control______________________________________
pr_codes_SetColor       label   byte
        byte    2,C_ESC,"r"
pr_codes_SetYellow      label   byte
        byte    3,C_ESC,"r",4
pr_codes_SetCyan        label   byte
        byte    3,C_ESC,"r",2
pr_codes_SetMagenta     label   byte
        byte    3,C_ESC,"r",1
pr_codes_SetBlack       label   byte
        byte    3,C_ESC,"r",0
