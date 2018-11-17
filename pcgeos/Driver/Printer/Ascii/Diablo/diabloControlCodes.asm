
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Diablo Daisy Wheel Print Driver
FILE:		diabloControlCodes.asm

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
	This file contains all the style setting routines for the Diablo
	driver.
		
	$Id: diabloControlCodes.asm,v 1.1 97/04/18 11:56:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE DIABLO DAISY WHEEL PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
	byte	3,C_ESC,C_CTRL_Z,"I"
pr_codes_InitPrinter	label	byte	;general initialize conditions.
	byte	2			;byte count
	byte	C_ESC,"/"		;bidirectional
pr_codes_InitTextMode   label   byte
        byte    2               ;count
        byte    C_ESC,"/"       ;set bi-directional
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
;pr_codes_GraphFeed	label	byte
	byte	5,C_ESC,01eh,"07",C_LF

;__________Pitch Control______________________________________
pr_codes_Set10PitchRoman	label	byte
	byte	6
	byte	C_ESC,"Q"
	byte	C_ESC,01fh,C_CR
pr_codes_Set12PitchRoman	label	byte
	byte	6
	byte	C_ESC,"Q"
	byte	C_ESC,01fh,C_VT
pr_codes_Set15PitchRoman	label	byte
	byte	6
	byte	C_ESC,"Q"
	byte	C_ESC,01fh,C_HT
pr_codes_Set17PitchRoman	label	byte
	byte	6
	byte	C_ESC,"Q"
	byte	C_ESC,01fh,C_BS
pr_codes_SetProportionalRoman	label	byte
	byte	3
	byte	C_ESC,"P"

;__________Style Control______________________________________
pr_codes_SetBold	label	byte
	byte	2,C_ESC,"O"
pr_codes_SetItalic	label	byte
	byte	2,C_ESC,"A"		;really set secondary color.
pr_codes_SetUnderline	label	byte
	byte	2,C_ESC,"E"
pr_codes_ResetBold	label	byte
	byte	2,C_ESC,"&"
pr_codes_ResetItalic	label	byte
	byte	2,C_ESC,"B"
pr_codes_ResetUnderline	label	byte
	byte	2,C_ESC,"R"

