
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		QuietJet Print Driver
FILE:		quietjetControlCodes.asm

AUTHOR:		Dave Durran, 1 April 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/1/90		Initial revision


DC_ESCRIPTION:
	This file contains all the Printer Control Codes for the quietJet
	driver.
		
	$Id: quietjetControlCodes.asm,v 1.1 97/04/18 11:52:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE HP QUIETJET PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

pr_codes_PJLEntryAndResetNoNeg       label   byte
pr_codes_PJLExit        label   byte
pr_codes_ResetPrinter	label	byte
	byte	2,C_ESC,"E"
pr_codes_CursorPosition	label	byte
	byte	3,C_ESC,"*p"
pr_codes_Do1ScanlineFeed        label   byte
        byte    6,C_ESC,"*b1W",0
pr_codes_StartGraphicLine       label   byte
        byte    8,C_ESC,"*r1A",C_ESC,"*b"
pr_codes_EndGraphics    label   byte
        byte    4,C_ESC,"*rB"
pr_graphic_Res_Values   label   word
        word    96
        word    0
        word    192

pr_codes_SetASCII7      label   byte
        byte    4
        byte    C_ESC,"(0U"
pr_codes_SetIBM437      label   byte
        byte    5
        byte    C_ESC,"(10U"
pr_codes_SetRoman8      label   byte
        byte    4
        byte    C_ESC,"(8U"

					;paper length, and bottom margin set
					;in PrintStartJob here.
pr_codes_SetPageLength	label	byte
	byte	5
	byte	C_ESC,"&l8d"		;8lpi
pr_codes_MidPageLength	label	byte
	byte	3
	byte	"p2e"			;2 line top margin.
pr_codes_FinishPageLength	label	byte
	byte	6
	byte	"F",C_ESC,"&a0R"	;set to top margin.
pr_codes_InitPrinter	label	byte
	byte	5,C_ESC,"&l0L"

pr_codes_Set5PitchRoman       label   byte
        byte    7,C_ESC,"(s0p5H"
pr_codes_Set6PitchRoman       label   byte
        byte    7,C_ESC,"(s0p6H"
pr_codes_Set10PitchRoman       label   byte
        byte    8,C_ESC,"(s0p10H"
pr_codes_Set106PitchRoman       label   byte
        byte    10,C_ESC,"(s0p10.6H"
pr_codes_Set12PitchRoman       label   byte
        byte    8,C_ESC,"(s0p12H"
pr_codes_Set213PitchRoman       label   byte
        byte    10,C_ESC,"(s0p21.3H"
pr_codes_SetProportionalRoman	label	byte
	byte	5,C_ESC,"(s1P"

pr_codes_SetNLQ	label	byte
	byte	5,C_ESC,"(s1Q"
pr_codes_SetBold	label	byte
	byte	5,C_ESC,"(s1B"
pr_codes_SetUnderline	label	byte
	byte	4,C_ESC,"&dD"

pr_codes_ResetNLQ	label	byte
	byte	5,C_ESC,"(s0Q"
pr_codes_ResetBold	label	byte
	byte	5,C_ESC,"(s0B"
pr_codes_ResetUnderline	label	byte
	byte	4,C_ESC,"&d@"

;----------------------------------------------------------------------
;the following control codes use the WriteNumCommand routine.
;----------------------------------------------------------------------
;
; graphic controlcodes
;
pr_codes_SetGraphicRes  label   byte
        byte    C_ESC,"*t#R",C_ESC,"*r1A",0     ;# = resolution in dpi.
pr_codes_TransferGraphics       label   byte
        byte    C_ESC,"*b#W",0

;
; font/character controls:
;
pr_codes_SetPitch       label   byte
        byte    C_ESC,"(s0p#H",0             ;# = Font Pitch

;paper control stuff.

pr_codes_DuplexMode     label   byte    ;set the duplex mode in the printer.
        byte    C_ESC,"&l#S",0

pr_codes_SetInputPath   label   byte    ;set the input path for the paper.
        byte    C_ESC,"&l#H",0
