
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		toshiba 24-pin Print Driver
FILE:		toshiba24Styles.asm

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
	This file contains all the style setting routines for the toshiba 24-pin
	driver.
		
	$Id: toshiba24ControlCodes.asm,v 1.1 97/04/18 11:53:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE TOSHIBA 24-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
	byte	3,C_ESC,C_CTRL_Z,"I"
pr_codes_InitPrinter	label	byte	;general initialize conditions.
	byte	6			;byte count
	byte	C_ESC,"Z"		;no auto CR-LF
	byte	C_ESC,"."		;no auto LF
	byte	C_ESC,">"		;unidirectional
pr_codes_InitTextMode   label   byte
        byte    2               ;count
        byte    C_ESC,"<"       ;set bi-directional
pr_codes_DefeatPaperOut label   byte
        byte    C_NULL

;__________ASF Control______________________________________
pr_codes_InitPaperLength        label   byte
pr_codes_ASFControl     label   byte
pr_codes_EnableASF      label   byte
pr_codes_DisableASF     label   byte
        byte    C_NULL

;__________Cursor Control______________________________________
pr_codes_AbsTab	label	byte
	byte	2,C_ESC,C_HT
;pr_codes_VerPos	label	byte
	byte	2,C_ESC,"V"
pr_codes_SetMaxLineFeed	label	byte
	byte	4,C_ESC,"L99"
pr_codes_SetLineFeed	label	byte
	byte	2,C_ESC,"L"
pr_codes_GraphFeed	label	byte
	byte	5,C_ESC,"L07",C_LF

;__________Graphics Control______________________________________
pr_codes_SetMedGraphics	label	byte
	byte	3,C_CR,C_ESC,";"
pr_codes_SetHiGraphics	label	byte
	byte	3,C_CR,C_ESC,01dh

;__________Pitch Control______________________________________
pr_codes_Set10PitchDraft	label	byte
	byte	6
	byte	C_ESC,"*0"
	byte	C_ESC,01fh,C_CR
pr_codes_Set12PitchDraft	label	byte
	byte	6
	byte	C_ESC,"*0"
	byte	C_ESC,01fh,C_VT
pr_codes_Set15PitchDraft	label	byte
	byte	6
	byte	C_ESC,"*0"
	byte	C_ESC,01fh,C_HT
pr_codes_Set10PitchRoman	label	byte
	byte	6
	byte	C_ESC,"*2"
	byte	C_ESC,01fh,C_CR
pr_codes_Set12PitchRoman	label	byte
	byte	6
	byte	C_ESC,"*2"
	byte	C_ESC,01fh,C_VT
pr_codes_Set15PitchRoman	label	byte
	byte	6
	byte	C_ESC,"*2"
	byte	C_ESC,01fh,C_HT
pr_codes_Set17PitchRoman	label	byte
	byte	6
	byte	C_ESC,"*2"
	byte	C_ESC,01fh,C_BS
pr_codes_SetProportionalRoman	label	byte
	byte	3
	byte	C_ESC,"*3"

;__________Style Control______________________________________
pr_codes_SetCondensed	label	byte
	byte	2,C_ESC,"["
pr_codes_SetNLQ	label	byte
	byte	3,C_ESC,"*2"
pr_codes_SetBold	label	byte
	byte	3,C_ESC,"K3"
pr_codes_SetItalic	label	byte
	byte	2,C_ESC,C_DC2
pr_codes_SetUnderline	label	byte
	byte	2,C_ESC,"I"
pr_codes_SetDblWidth	label	byte
	byte	2,C_ESC,"!"
pr_codes_SetShadow	label	byte
	byte	2,C_ESC,"Q"
pr_codes_ResetCondensed	label	byte
	byte	2,C_ESC,"]"
pr_codes_ResetNLQ	label	byte
	byte	C_NULL
pr_codes_ResetBold	label	byte
	byte	2,C_ESC,"M"
pr_codes_ResetItalic	label	byte
	byte	2,C_ESC,C_DC4
pr_codes_ResetUnderline	label	byte
	byte	2,C_ESC,"J"
pr_codes_ResetDblWidth	label	byte
	byte	2,C_ESC,"\""
pr_codes_ResetShadow	label	byte
	byte	2,C_ESC,"R"

