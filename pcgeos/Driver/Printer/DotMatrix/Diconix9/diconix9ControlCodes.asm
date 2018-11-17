
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Diconix9-jet Print Driver
FILE:		diconix9ControlCodes.asm

AUTHOR:		Dave Durran, 15 Nov 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/15/91	Initial revision
	Dave	5/92		Initial 2.0 version


DC_ESCRIPTION:
	This file contains all the Printer Control Codes for the diconix 9-pin
	driver.
		
	$Id: diconix9ControlCodes.asm,v 1.1 97/04/18 11:54:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE Diconix 9-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
	byte	2,C_ESC,"@"
pr_codes_InitPrinter	label	byte
	byte	8,0		;send a null to wait till after any reset garb
	byte	C_ESC,"O"	;cancel any perforation skipping.
        byte    C_ESC,"6"       ;print in 80h to 9fh range.
        byte    C_ESC,"U",1     ;set uni-directional
pr_codes_InitTextMode   label   byte
        byte    3               ;count
        byte    C_ESC,"U",0     ;set bi-directional
pr_codes_DefeatPaperOut	label	byte
	byte	2,C_ESC,"8"
pr_codes_SetCountry   label   byte
        byte    2               ;count
        byte    C_ESC,"R"       ;

;__________ASF Control______________________________________
pr_codes_InitPaperLength        label   byte
        byte    4,C_ESC,"C",0,22 ;set page length to max (22")
pr_codes_FormFeed       label   byte
        byte    5
        byte    C_ESC,"3",4     ;set 4/288" line spacing.
        byte    C_ESC,"C"       ;set the page length.
pr_codes_ASFControl     label   byte
        byte    2,C_ESC,C_EM    ;argument is function of ASF
pr_codes_EnableASF      label   byte
        byte    3,C_ESC,C_EM,4  ;Enable the ASF
pr_codes_DisableASF     label   byte
        byte    3,C_ESC,C_EM,0  ;Disable the ASF

;__________Cursor Control______________________________________
pr_codes_SetTab	label	byte
	byte	4,C_CR,C_SPACE,C_ESC,"D"
pr_codes_DoTab	label	byte
	byte	2,0,C_HT
pr_codes_DoLineFeed	label	byte
	byte	2,C_ESC,"J"
pr_codes_DoMaxLineFeed	label	byte
	byte	3,C_ESC,"J",PR_MAX_LINE_FEED
pr_codes_Do1ScanlineFeed	label	byte
	byte	3,C_ESC,"J",1

;__________Graphics Control______________________________________
pr_codes_SetLoGraphics	label	byte
	byte	3,C_CR,C_ESC,"K"
pr_codes_SetMedGraphics	label	byte	
pr_codes_SetHiGraphics	label	byte	;used for hi also....
	byte	3,C_CR,C_ESC,"L"

;__________Pitch Control______________________________________
pr_codes_Set10PitchRoman	label	byte
	byte	5,C_ESC,"p",0,C_ESC,"P"
pr_codes_Set12PitchRoman	label	byte
	byte	5,C_ESC,"p",0,C_ESC,"M"
pr_codes_SetProportionalRoman	label	byte
	byte	3,C_ESC,"p",1

;__________Style Control______________________________________
pr_codes_SetCondensed	label	byte
	byte	1,C_SI
pr_codes_SetSubscript	label	byte
	byte	3,C_ESC,"S",1
pr_codes_SetSuperscript	label	byte
	byte	3,C_ESC,"S",0
pr_codes_SetNLQ	label	byte
	byte	3,C_ESC,"x",1
pr_codes_SetBold	label	byte
	byte	4,C_ESC,"E",C_ESC,"G"
pr_codes_SetItalic	label	byte
	byte	2,C_ESC,"4"
pr_codes_SetUnderline	label	byte
	byte	3,C_ESC,"-",1
pr_codes_SetDblWidth	label	byte
	byte	3,C_ESC,"W",1
pr_codes_SetDblHeight	label	byte
	byte	3,C_ESC,"w",1
pr_codes_ResetCondensed	label	byte
	byte	1,C_DC2
pr_codes_ResetScript	label	byte
	byte	2,C_ESC,"T"
pr_codes_ResetNLQ	label	byte
	byte	3,C_ESC,"x",0
pr_codes_ResetBold	label	byte
	byte	4,C_ESC,"F",C_ESC,"H"
pr_codes_ResetItalic	label	byte
	byte	2,C_ESC,"5"
pr_codes_ResetUnderline	label	byte
	byte	3,C_ESC,"-",0
pr_codes_ResetDblWidth	label	byte
	byte	3,C_ESC,"W",0
pr_codes_ResetDblHeight	label	byte
	byte	3,C_ESC,"w",0

