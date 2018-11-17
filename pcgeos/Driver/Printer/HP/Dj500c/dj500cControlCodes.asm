
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Deskjet CMY Print Driver
FILE:		dj500cControlCodes.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserplsControlCodes.asm
	Dave	6/92		Initial 2.0 revision 


DC_ESCRIPTION:
	This file contains all the Printer Control Codes for the Deskjet 
	driver.
		
	$Id: dj500cControlCodes.asm,v 1.1 97/04/18 11:52:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE COLOR DESKJET PCL PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

pr_codes_ResetPrinter	label	byte
	byte	2,C_ESC,"E"
pr_codes_CursorPosition	label	byte
	byte	3,C_ESC,"*p"
pr_codes_TransferNoGraphics	label	byte
	byte	7,C_ESC,"*b0m0V"
pr_codes_Do1ScanlineFeed	label	byte
	byte	7,C_ESC,"*b0m0W"
pr_codes_EndGraphics	label	byte
	byte	5,C_ESC,"*rbC"
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
	byte	18
	byte	C_ESC,"&l0o"		;Force set Portrait orientation.
	byte	"0L"			;defeat perf skip feature.
	byte	C_ESC,"*r-3U"		;use 3 plane CMY pallette.
        byte    C_ESC,"*p2N"            ;set unidirectional printing.

                ;custom init codes for various devices.
pr_codes_PJLEntryAndResetNoNeg       label   byte
        byte    41                      ;count
        byte    C_ESC,"%-12345X"        ;UEL Code.
        byte    "@PJL ENTER LANGUAGE=PCL",C_CR,C_LF
	byte	C_ESC,"E"		;reset printer.
	byte	C_ESC,"&a1N"		;set no negative motion.
pr_codes_PJLExit        label   byte
        byte    15                      ;count
        byte    C_ESC,"%-12345X@PJL",C_CR,C_LF  ;UEL Code.

pr_codes_SetASCII7      label   byte
        byte    4
        byte    C_ESC,"(0U"
pr_codes_SetIBM437      label   byte
        byte    5
        byte    C_ESC,"(10U"
pr_codes_SetIBM850      label   byte
        byte    5
        byte    C_ESC,"(12U"
pr_codes_SetRoman8      label   byte
        byte    4
        byte    C_ESC,"(8U"
pr_codes_SetLatin1      label   byte
        byte    4
        byte    C_ESC,"(0N"

pr_graphic_Res_Values	label	word
	word	75
	word	150
	word	300

;----------------------------------------------------------------------
;the following control codes use the WriteNumCommand routine.
;----------------------------------------------------------------------
;
; graphic controlcodes
;
pr_codes_SetGraphicRes	label	byte
	byte	C_ESC,"*t#R",C_ESC,"*r1A",0	;# = resolution in dpi.
pr_codes_TIFFTransferGraphics       label   byte
        byte    C_ESC,"*b2m#V",0
pr_codes_TransferGraphics       label   byte
        byte    C_ESC,"*b0m#V",0


;paper control stuff.

pr_codes_DuplexMode     label   byte    ;set the duplex mode in the printer.
        byte    C_ESC,"&l#S",0

pr_codes_SetInputPath	label	byte	;set the input path for the paper.
	byte	C_ESC,"&l#H",0
