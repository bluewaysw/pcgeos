

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 48-jet Print Driver
FILE:		epson48ControlCodes.asm

AUTHOR:		Dave Durran, 

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	9/22/92		Initial revision


DC_ESCRIPTION:
	This file contains all the Control Codes for the Epson 48-jet
	driver.
		
	$Id: epson48ControlCodes.asm,v 1.1 97/04/18 11:54:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;*****************************************************************************
;
;CONTROL CODES FOR THE EPSON 24-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
	byte	2,C_ESC,"@"
pr_codes_InitPrinter	label	byte
	byte	13
	byte	C_ESC,"O"	;defeat the bottom margin
	byte	C_ESC,"6"	;print in 80h to 9fh range.
	byte	C_ESC,"t",1	;set 8 bit character table.
        byte    C_ESC,"U",1     ;set uni-directional
	byte	C_ESC,"r",0	;set color to black.
pr_codes_InitTextMode   label   byte
        byte    3               ;count
        byte    C_ESC,"U",0     ;set bi-directional
pr_codes_DefeatPaperOut label   byte
        byte    2,C_ESC,"8"
pr_codes_SetCountry   label   byte
        byte    2               ;count
        byte    C_ESC,"R"       ;

;__________ASF Control______________________________________
pr_codes_InitPaperLength	label	byte
	byte	4,C_ESC,"C",0,22 ;set page length to max (22")
pr_codes_FormFeed	label	byte
	byte	5
	byte	C_ESC,"3",3	;set 3/180" line spacing.
	byte	C_ESC,"C"	;set form length.
pr_codes_ASFControl	label	byte
	byte	2,C_ESC,C_EM	;argument is function of ASF
pr_codes_EnableASF	label	byte
	byte	3,C_ESC,C_EM,4	;Enable the ASF
pr_codes_DisableASF	label	byte
	byte	3,C_ESC,C_EM,0	;Disable the ASF

;__________Cursor Control______________________________________
pr_codes_AbsPos	label	byte
	byte	2,C_ESC,"$"
pr_codes_SetLineFeed	label	byte
	byte	2,C_ESC,"+"
pr_codes_SetMaxLineFeed	label	byte
	byte	3,C_ESC,"+",PR_MAX_LINE_FEED
pr_codes_DoSingleLineFeed	label	byte
	byte	4,C_ESC,"+",1,C_LF

;__________Graphics Control______________________________________
pr_codes_SetLoGraphics	label	byte
	byte	4,C_CR,C_ESC,"*",0
pr_codes_SetMedGraphics	label	byte
	byte	4,C_CR,C_ESC,"*",39
pr_codes_SetHiGraphics	label	byte
	byte	4,C_CR,C_ESC,"*",73

;__________Pitch Control______________________________________
pr_codes_Set10PitchRoman	label	byte
	byte	8,C_ESC,"k",0,C_ESC,"p",0,C_ESC,"P"
pr_codes_Set12PitchRoman	label	byte
	byte	8,C_ESC,"k",0,C_ESC,"p",0,C_ESC,"M"
pr_codes_Set15PitchRoman	label	byte
	byte	8,C_ESC,"k",0,C_ESC,"p",0,C_ESC,"g"
pr_codes_SetProportionalRoman	label	byte
	byte	6,C_ESC,"k",0,C_ESC,"p",1
pr_codes_Set10PitchSans	label	byte
	byte	8,C_ESC,"k",1,C_ESC,"p",0,C_ESC,"P"
pr_codes_Set12PitchSans	label	byte
	byte	8,C_ESC,"k",1,C_ESC,"p",0,C_ESC,"M"
pr_codes_Set15PitchSans	label	byte
	byte	8,C_ESC,"k",1,C_ESC,"p",0,C_ESC,"g"
pr_codes_SetProportionalSans	label	byte
	byte	6,C_ESC,"k",1,C_ESC,"p",1

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

;__________Color Control______________________________________
pr_codes_SetColor	label	byte
	byte	2,C_ESC,"r"
pr_codes_SetYellow      label   byte
        byte    3,C_ESC,"r",4
pr_codes_SetCyan        label   byte
        byte    3,C_ESC,"r",2
pr_codes_SetMagenta     label   byte
        byte    3,C_ESC,"r",1
pr_codes_SetBlack       label   byte
        byte    3,C_ESC,"r",0
