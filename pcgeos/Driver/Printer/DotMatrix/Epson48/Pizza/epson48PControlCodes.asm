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
	owa	5/94		DBCS version


DC_ESCAPERIPTION:
	This file contains all the Control Codes for the Epson 48-jet
	driver.
		
	$Id: epson48PControlCodes.asm,v 1.1 97/04/18 11:54:44 newdeal Exp $

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
	byte	2,C_ESCAPE,"@"
pr_codes_InitPrinter	label	byte
	byte	13
	byte	C_ESCAPE,"O"	;defeat the bottom margin
	byte	C_ESCAPE,"6"	;print in 80h to 9fh range.
	byte	C_ESCAPE,"t",3	;set kana character table.
        byte    C_ESCAPE,"U",1     ;set uni-directional
	byte	C_ESCAPE,"r",0	;set color to black.
pr_codes_InitTextMode   label   byte
        byte    3               ;count
        byte    C_ESCAPE,"U",0     ;set bi-directional
pr_codes_DefeatPaperOut label   byte
        byte    2,C_ESCAPE,"8"
pr_codes_SetCountry   label   byte
        byte    2               ;count
        byte    C_ESCAPE,"R"       ;

;__________ASF Control______________________________________
pr_codes_InitPaperLength	label	byte
	byte	4,C_ESCAPE,"C",0,22 ;set page length to max (22")
pr_codes_FormFeed	label	byte
	byte	5
	byte	C_ESCAPE,"3",3	;set 3/180" line spacing.
	byte	C_ESCAPE,"C"	;set form length.
pr_codes_ASFControl	label	byte
	byte	2,C_ESCAPE,C_END_OF_MEDIUM	;argument is function of ASF
pr_codes_EnableASF	label	byte
	byte	3,C_ESCAPE,C_END_OF_MEDIUM,4	;Enable the ASF
pr_codes_DisableASF	label	byte
	byte	3,C_ESCAPE,C_END_OF_MEDIUM,0	;Disable the ASF

;__________Cursor Control______________________________________
pr_codes_AbsPos	label	byte
	byte	2,C_ESCAPE,"$"
pr_codes_SetLineFeed	label	byte
	byte	2,C_ESCAPE,"+"
pr_codes_SetMaxLineFeed	label	byte
	byte	3,C_ESCAPE,"+",PR_MAX_LINE_FEED
pr_codes_DoSingleLineFeed	label	byte
	byte	4,C_ESCAPE,"+",1,C_LF

;__________Graphics Control______________________________________
pr_codes_SetLoGraphics	label	byte
	byte	4,C_CR,C_ESCAPE,"*",0
pr_codes_SetMedGraphics	label	byte
	byte	4,C_CR,C_ESCAPE,"*",39
pr_codes_SetHiGraphics	label	byte
	byte	4,C_CR,C_ESCAPE,"*",73

;__________Pitch Control______________________________________
pr_codes_Set10PitchRoman	label	byte
	byte	10,C_ESCAPE,"k",0,C_ESCAPE,"p",0,C_ESCAPE,"P",C_FIELD_SEP,C_DEVICE_CONTROL_TWO
pr_codes_Set12PitchRoman	label	byte
	byte	10,C_ESCAPE,"k",0,C_ESCAPE,"p",0,C_ESCAPE,"M",C_FIELD_SEP,C_DEVICE_CONTROL_TWO
pr_codes_Set15PitchRoman	label	byte
	byte	10,C_ESCAPE,"k",0,C_ESCAPE,"p",0,C_ESCAPE,"g",C_FIELD_SEP,C_SHIFT_IN
pr_codes_SetProportionalRoman	label	byte
	byte	6,C_ESCAPE,"k",0,C_ESCAPE,"p",1
pr_codes_Set10PitchSans	label	byte
	byte	10,C_ESCAPE,"k",1,C_ESCAPE,"p",0,C_ESCAPE,"P",C_FIELD_SEP,C_DEVICE_CONTROL_TWO
pr_codes_Set12PitchSans	label	byte
	byte	10,C_ESCAPE,"k",1,C_ESCAPE,"p",0,C_ESCAPE,"M",C_FIELD_SEP,C_DEVICE_CONTROL_TWO
pr_codes_Set15PitchSans	label	byte
	byte	10,C_ESCAPE,"k",1,C_ESCAPE,"p",0,C_ESCAPE,"g",C_FIELD_SEP,C_SHIFT_IN
pr_codes_SetProportionalSans	label	byte
	byte	6,C_ESCAPE,"k",1,C_ESCAPE,"p",1

;__________Style Control______________________________________
pr_codes_SetCondensed	label	byte
	byte	1,C_SHIFT_IN
pr_codes_SetSubscript	label	byte
	byte	6,C_ESCAPE,"S",1,C_FIELD_SEP,"r",1
pr_codes_SetSuperscript	label	byte
	byte	6,C_ESCAPE,"S",0,C_FIELD_SEP,"r",0
pr_codes_SetNLQ	label	byte
	byte	6,C_ESCAPE,"x",1,C_FIELD_SEP,"x",0
pr_codes_SetBold	label	byte
	byte	4,C_ESCAPE,"E",C_ESCAPE,"G"
pr_codes_SetItalic	label	byte
	byte	2,C_ESCAPE,"4"
pr_codes_SetUnderline	label	byte
	byte	6,C_ESCAPE,"-",1,C_FIELD_SEP,"-",1
pr_codes_SetDblWidth	label	byte
	byte	3,C_ESCAPE,"W",1
pr_codes_SetDblHeight	label	byte
	byte	3,C_ESCAPE,"w",1
pr_codes_ResetCondensed	label	byte
	byte	1,C_DEVICE_CONTROL_TWO
pr_codes_ResetScript	label	byte
	byte	4,C_ESCAPE,"T",C_FIELD_SEP,C_DEVICE_CONTROL_TWO
pr_codes_ResetNLQ	label	byte
	byte	6,C_ESCAPE,"x",0,C_FIELD_SEP,"x",1
pr_codes_ResetBold	label	byte
	byte	4,C_ESCAPE,"F",C_ESCAPE,"H"
pr_codes_ResetItalic	label	byte
	byte	2,C_ESCAPE,"5"
pr_codes_ResetUnderline	label	byte
	byte	6,C_ESCAPE,"-",0,C_FIELD_SEP,"-",0
pr_codes_ResetDblWidth	label	byte
	byte	3,C_ESCAPE,"W",0
pr_codes_ResetDblHeight	label	byte
	byte	3,C_ESCAPE,"w",0

;__________Color Control______________________________________
pr_codes_SetColor	label	byte
	byte	2,C_ESCAPE,"r"
pr_codes_SetYellow      label   byte
        byte    3,C_ESCAPE,"r",4
pr_codes_SetCyan        label   byte
        byte    3,C_ESCAPE,"r",2
pr_codes_SetMagenta     label   byte
        byte    3,C_ESCAPE,"r",1
pr_codes_SetBlack       label   byte
        byte    3,C_ESCAPE,"r",0

;__________Kanji In/Out_______________________________________
pr_codes_SetKanji       label   byte
	byte    3,C_FIELD_SEP,"&",0
pr_codes_ResetKanji     label   byte
	byte    3,C_FIELD_SEP,".",0

