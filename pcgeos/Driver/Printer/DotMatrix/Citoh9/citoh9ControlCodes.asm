
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		citoh 9-pin Print Driver
FILE:		citoh9ControlCodes.asm

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
	This file contains all the Printer Control Codes for the citoh 9-pin
	driver.
		
	$Id: citoh9ControlCodes.asm,v 1.1 97/04/18 11:53:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE CITOH 9-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
	byte	2,C_ESC,"c"
pr_codes_InitPrinter	label	byte		;general init codes.
	byte	2,C_ESC,">"	;unidirectional print.
pr_codes_InitTextMode   label   byte
        byte    2               ;count
        byte    C_ESC,"<"       ;set bi-directional

;__________Cursor Control______________________________________
pr_codes_AbsPos	label	byte
	byte	3,C_CR,C_ESC,"F"
pr_codes_SetLineFeed	label	byte
	byte	2,C_ESC,"T"
pr_codes_SetMaxLineFeed	label	byte
	byte	4,C_ESC,"T99"
pr_codes_Do1ScanlineFeed       label   byte
        byte    5,C_ESC,"T01",C_LF

;__________ASF Control______________________________________
pr_codes_InitPaperLength        label   byte
pr_codes_ASFControl     label   byte
pr_codes_EnableASF      label   byte
pr_codes_DisableASF     label   byte
pr_codes_DefeatPaperOut label   byte
        byte    C_NULL

;__________Graphics Control______________________________________
pr_codes_SetLoGraphics	label	byte
	byte	5,C_CR,C_ESC,"N",C_ESC,"S"
pr_codes_SetHiGraphics	label	byte
	byte	5,C_CR,C_ESC,"P",C_ESC,"S"

;__________Pitch Control______________________________________
pr_codes_Set10Pitch	label	byte
	byte	2,C_ESC,"N"
pr_codes_Set12Pitch	label	byte
	byte	2,C_ESC,"E"
pr_codes_SetProportional	label	byte
	byte	2,C_ESC,"P"
pr_codes_Set17Pitch	label	byte
	byte	2,C_ESC,"Q"

;__________Style Control______________________________________
pr_codes_SetCondensed	label	byte
	byte	C_NULL
pr_codes_SetSubscript	label	byte
	byte	3,C_ESC,"s2"
pr_codes_SetSuperscript	label	byte
	byte	3,C_ESC,"s1"
pr_codes_SetNLQ	label	byte
pr_codes_SetBold	label	byte
	byte	2,C_ESC,"!"
pr_codes_SetItalic	label	byte
	byte	3,C_ESC,"i1"
pr_codes_SetUnderline	label	byte
	byte	2,C_ESC,"X"
pr_codes_SetDblWidth    label   byte
	byte	1,C_SO
pr_codes_ResetCondensed	label	byte
	byte	C_NULL
pr_codes_ResetScript	label	byte
	byte	3,C_ESC,"s0"
pr_codes_ResetNLQ	label	byte
pr_codes_ResetBold	label	byte
	byte	2,C_ESC,"\""
pr_codes_ResetItalic	label	byte
	byte	3,C_ESC,"i0"
pr_codes_ResetUnderline	label	byte
	byte	2,C_ESC,"Y"
pr_codes_ResetDblWidth  label   byte
	byte	1,C_SI
pr_codes_SetStrikeThru	label	byte
pr_codes_SetDblHeight   label   byte
pr_codes_ResetStrikeThru	label	byte
pr_codes_ResetDblHeight label   byte
	byte	C_NULL

;__________Color Control______________________________________
pr_codes_SetColor       label   byte
	byte	2
	byte	C_ESC,"K"
pr_codes_SetYellow      label   byte
	byte	3
	byte	C_ESC,"K1"
pr_codes_SetCyan        label   byte
	byte	3
	byte	C_ESC,"K3"
pr_codes_SetMagenta     label   byte
	byte	3
	byte	C_ESC,"K2"
pr_codes_SetBlack       label   byte
	byte	3
	byte	C_ESC,"K0"
