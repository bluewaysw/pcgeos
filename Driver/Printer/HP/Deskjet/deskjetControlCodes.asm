
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Deskjet Print Driver
FILE:		deskjetControlCodes.asm

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
		
	$Id: deskjetControlCodes.asm,v 1.1 97/04/18 11:51:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE DESKJET PCL PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

pr_codes_ResetPrinter	label	byte
	byte	2,C_ESC,"E"
pr_codes_CursorPosition	label	byte
	byte	3,C_ESC,"*p"
pr_codes_TransferNoGraphics	label	byte
	byte	8,C_ESC,"*b0m1W",0
pr_codes_EndGraphics	label	byte
	byte	4,C_ESC,"*rB"
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
	byte	13
	byte	C_ESC,"&l0o"		;Force set Portrait orientation.
	byte	"0L"			;defeat perf skip feature.
	byte	C_ESC,"*c0F"		;nuke all downloaded fonts (free up
					;memory)
	byte	C_SI			;set to primary font.

                ;custom init codes for various devices.
pr_codes_PJLEntryAndResetNoNeg       label   byte
        byte    41                      ;count
        byte    C_ESC,"%-12345X"        ;UEL Code.
        byte    "@PJL ENTER LANGUAGE=PCL",C_CR,C_LF
        byte    C_ESC,"E"               ;reset printer.
        byte    C_ESC,"&a1N"            ;set no negative motion.
pr_codes_PJLExit        label   byte
        byte    15                      ;count
        byte    C_ESC,"%-12345X@PJL",C_CR,C_LF  ;UEL Code.

pr_codes_SetBold	label	byte
	byte	5,C_ESC,"(s3B"
pr_codes_SetItalic	label	byte
	byte	5,C_ESC,"(s1S"
pr_codes_SetUnderline   label   byte
        byte    5,C_ESC,"&d3D"
pr_codes_ResetBold	label	byte
	byte	5,C_ESC,"(s0B"
pr_codes_ResetItalic	label	byte
	byte	5,C_ESC,"(s0S"
pr_codes_ResetUnderline label   byte
        byte    4,C_ESC,"&d@"

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
        byte    C_ESC,"*b2m#W",0
pr_codes_TransferGraphics       label   byte
        byte    C_ESC,"*b0m#W",0
;
; font/character controls:
;
;
; font/text attribute commands:
pr_codes_SetResidentFixed       label   byte
        byte    C_ESC,"(s0p#h",0        ;first few bytes in font selection.
pr_codes_SetResidentProportional        label   byte
        byte    C_ESC,"(s#p",0          ;first few bytes in font selection.
;(these 4 use the SendCodeOut routine)
pr_codes_SetResidentUpright     label   byte
        byte    2,"0s"
pr_codes_SetResidentItalic      label   byte
        byte    2,"1s"
pr_codes_SetResidentMedium      label   byte
        byte    2,"0b"
pr_codes_SetResidentBold        label   byte
        byte    2,"3b"


;paper control stuff.

pr_codes_DuplexMode     label   byte    ;set the duplex mode in the printer.
        byte    C_ESC,"&l#S",0

pr_codes_SetInputPath	label	byte	;set the input path for the paper.
	byte	C_ESC,"&l#H",0
