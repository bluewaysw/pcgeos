
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Star Gemini 9-pin Print Driver
FILE:		gemini9ControlCodes.asm

AUTHOR:		Dave Durran, 1 April 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/1/90		Initial revision


DC_ESCRIPTION:
	This file contains all the Printer Control Codes for the gemini 9-pin
	driver.
		
	$Id: gemini9ControlCodes.asm,v 1.1 97/04/18 11:54:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE Star Gemini 9-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter   label   byte
        byte    NULL ;2,C_ESC,"@"
pr_codes_InitPrinter    label   byte
        byte    6,0             ;send a null to wait till after any reset garb
        byte    C_ESC,"O"       ;cancel any perforation skipping.
        byte    C_ESC,"U",1     ;set uni-directional
pr_codes_InitTextMode   label   byte
        byte    3               ;count
        byte    C_ESC,"U",0     ;set bi-directional
pr_codes_DefeatPaperOut label   byte
        byte    2,C_ESC,"8"

;__________ASF Control______________________________________
pr_codes_InitPaperLength        label   byte
        byte    4,C_ESC,"C",0,22 ;set page length to max (22")
pr_codes_FormFeed       label   byte
        byte    5
        byte    C_ESC,"3",2     ;set 2/144" line spacing.
        byte    C_ESC,"C"       ;set the page length.



;__________Cursor Control______________________________________
pr_codes_SetTab label   byte
        byte    2
        byte    C_ESC,"D"                       ;set the tab...
pr_codes_DoTab  label   byte
        byte    2,0,C_HT
pr_codes_DoLineFeed     label   byte
        byte    2,C_ESC,"J"
pr_codes_DoMaxLineFeed  label   byte
        byte    3,C_ESC,"J",PR_MAX_LINE_FEED
pr_codes_Do1ScanlineFeed        label   byte
        byte    3,C_ESC,"J",1

;__________Graphics Control______________________________________
pr_codes_SetLoGraphics  label   byte
        byte    3,C_CR,C_ESC,"K"
pr_codes_SetMedGraphics label   byte
pr_codes_SetHiGraphics  label   byte    ;used for hi also....
        byte    3,C_CR,C_ESC,"L"

;__________Pitch Control______________________________________
pr_codes_Set10PitchRoman        label   byte
        byte    3,C_ESC,"B",1
pr_codes_Set12PitchRoman        label   byte
        byte    3,C_ESC,"B",2
pr_codes_Set17PitchRoman        label   byte
        byte    3,C_ESC,"B",3
pr_codes_SetProportionalRoman   label   byte
        byte    3,C_ESC,"Z",1


pr_codes_SetCondensed	label	byte
	byte	1,C_SI
pr_codes_SetSubscript	label	byte
	byte	3,C_ESC,"S",1
pr_codes_SetSuperscript	label	byte
	byte	3,C_ESC,"S",0
pr_codes_SetNLQ	label	byte
pr_codes_SetBold	label	byte
	byte	4,C_ESC,"E",C_ESC,"G"
pr_codes_SetItalic	label	byte
	byte	2,C_ESC,"4"
pr_codes_SetDblWidth	label	byte
	byte	3,C_ESC,"W",1
pr_codes_SetUnderline	label	byte
pr_codes_SetDblHeight	label	byte
	byte	1,C_NULL
pr_codes_ResetCondensed	label	byte
	byte	1,C_DC2
pr_codes_ResetScript	label	byte
	byte	2,C_ESC,"T"
pr_codes_ResetNLQ	label	byte
pr_codes_ResetBold	label	byte
	byte	4,C_ESC,"F",C_ESC,"H"
pr_codes_ResetItalic	label	byte
	byte	2,C_ESC,"5"
pr_codes_ResetDblWidth	label	byte
	byte	3,C_ESC,"W",0
pr_codes_ResetUnderline	label	byte
pr_codes_ResetDblHeight	label	byte
	byte	1,C_NULL

