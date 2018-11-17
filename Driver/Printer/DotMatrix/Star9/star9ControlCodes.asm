
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Star 9-pin Print Driver
FILE:		star9ControlCodes.asm

AUTHOR:		Dave Durran, 1 April 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/1/90		Initial revision
	Dave	5/92		Initial 2.0 version


DC_ESCRIPTION:
	This file contains all the Printer Control Codes for the Star 9-pin
	driver.
		
	$Id: star9ControlCodes.asm,v 1.1 97/04/18 11:53:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE Star 9-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
	byte	2,C_ESC,"@"
pr_codes_InitPrinter	label	byte
	byte	5
	byte	C_ESC,"O"	;disable perf skip.
	byte	C_ESC,"U",1	;unidirectional print.
pr_codes_InitTextMode   label   byte
        byte    3               ;count
        byte    C_ESC,"U",0     ;set bi-directional
pr_codes_DefeatPaperOut label   byte
        byte    2,C_ESC,"8"
pr_codes_SetCountry   label   byte
        byte    2               ;count
        byte    C_ESC,"7"       ;

;__________ASF Control______________________________________
pr_codes_InitPaperLength        label   byte
        byte    4,C_ESC,"C",0,22 ;set page length to max (22")
pr_codes_FormFeed       label   byte
        byte    5
        byte    C_ESC,"3",2     ;set 2/144" line spacing.
        byte    C_ESC,"C"       ;set the page length.
pr_codes_ASFControl     label   byte
pr_codes_EnableASF      label   byte
pr_codes_DisableASF     label   byte
	byte	C_NULL

;__________Cursor Control______________________________________
pr_codes_SetTab label   byte
        byte    2,C_ESC,"D"
pr_codes_DoTab  label   byte
        byte    3,0,C_SPACE,C_HT
pr_codes_DoLineFeed     label   byte
        byte    2,C_ESC,"J"
pr_codes_DoMaxLineFeed  label   byte
        byte    3,C_ESC,"J",PR_MAX_LINE_FEED
pr_codes_Do1ScanlineFeed        label   byte
        byte    3,C_ESC,"J",1

;__________Graphics Control______________________________________
pr_codes_SetLoGraphics	label	byte
	byte	3,C_CR,C_ESC,"K"
pr_codes_SetMedGraphics	label	byte
	byte	3,C_CR,C_ESC,"L"
pr_codes_SetHiGraphics	label	byte
	byte	3,C_CR,C_ESC,"z"

;__________Pitch Control______________________________________
pr_codes_Set10Pitch	label	byte
	byte	6,C_ESC,"p",0,C_ESC,"B",1
pr_codes_Set12Pitch	label	byte
	byte	6,C_ESC,"p",0,C_ESC,"B",2
pr_codes_Set17Pitch	label	byte
	byte	6,C_ESC,"p",0,C_ESC,"B",3
pr_codes_SetProportional	label	byte
	byte	3,C_ESC,"p",1
;__________Style Control______________________________________
pr_codes_SetSubscript	label	byte
	byte	3,C_ESC,"S",1
pr_codes_SetSuperscript	label	byte
	byte	3,C_ESC,"S",0
pr_codes_SetNLQ	label	byte
	byte	3,C_ESC,"B",4
pr_codes_SetBold	label	byte
	byte	4,C_ESC,"E",C_ESC,"G"
pr_codes_SetItalic	label	byte
	byte	2,C_ESC,"4"
pr_codes_SetUnderline	label	byte
	byte	3,C_ESC,"-",1
pr_codes_SetDblWidth	label	byte
	byte	3,C_ESC,"W",1

pr_codes_ResetScript	label	byte
	byte	2,C_ESC,"T"
pr_codes_ResetNLQ	label	byte
	byte	3,C_ESC,"B",5
pr_codes_ResetBold	label	byte
	byte	4,C_ESC,"F",C_ESC,"H"
pr_codes_ResetItalic	label	byte
	byte	2,C_ESC,"5"
pr_codes_ResetUnderline	label	byte
	byte	3,C_ESC,"-",0
pr_codes_ResetDblWidth	label	byte
	byte	3,C_ESC,"W",0
pr_codes_SetCondensed	label	byte
pr_codes_ResetCondensed	label	byte
pr_codes_SetDblHeight	label	byte
pr_codes_ResetDblHeight	label	byte
	byte	C_NULL
