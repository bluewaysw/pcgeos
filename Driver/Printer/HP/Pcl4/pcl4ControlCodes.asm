
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet Print Driver
FILE:		pcl4ControlCodes.asm

AUTHOR:		Dave Durran, 1 April 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserplsControlCodes.asm


DC_ESCRIPTION:
	This file contains all the Printer Control Codes for the PCL 4
	driver.
		
	$Id: pcl4ControlCodes.asm,v 1.1 97/04/18 11:52:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE PCL LEVEL 4 PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

pr_codes_ResetPrinter	label	byte
	byte	2,C_ESC,"E"
pr_codes_CursorPosition	label	byte
	byte	3,C_ESC,"*p"
pr_codes_StartGraphics  label   byte
        byte    5,C_ESC,"*r1A"
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
pr_codes_SetLetterLength	label	byte
	byte	23			;count
	byte	C_ESC,"&l8d"		;8lpi
	byte	"88"			;88 lines
	byte	"p2e"			;2 line top margin.
	byte	"84"			;84 lines of actual text.
	byte	"F",C_ESC,"&a0R"	;set to top margin.
	byte	C_ESC,"&l6d"		;reset to 6lpi
pr_codes_InitPrinter	label	byte
	byte	8
	byte	C_ESC,"&l0o"		;Force set Portrait orientation.
	byte	"0L"			;defeat perf skip feature.
	byte	C_SI			;set to primary font.

		;custom init codes for various devices.
		;For IBM PPDS mode to PCL4 emmulation.
pr_codes_SICToPCL	label	byte
	byte	8			;count
	byte	C_ESC,"[K",3,0,5,031h,2
pr_codes_SICToPPDS	label	byte
	byte	8			;count
	byte	C_ESC,"[K",3,0,1,031h,1


;____________________HP PJL related control codes__________________________
pr_codes_PJLUEL         label   byte
        byte    9                       ;count
        byte    C_ESC,"%-12345X"        ;UEL Code.
pr_codes_PJLCRLF       label   byte
        byte    6                      ;count
        byte    "@PJL",C_CR,C_LF
pr_codes_PJLEnterPCL       label   byte
        byte    27                      ;count
        byte    "@PJL ENTER LANGUAGE = PCL",C_CR,C_LF
pr_codes_PJLEnterPCL5       label   byte
        byte    28                      ;count
        byte    "@PJL ENTER LANGUAGE = PCL5",C_CR,C_LF
pr_codes_PJLMsgPCL          label   byte
        byte    38                      ;count
        byte    "@PJL RDYMSG DISPLAY = \"GEOS PCL JOB\"",C_CR,C_LF
pr_codes_PJLMsgClear            label   byte
        byte    26                      ;count
        byte    "@PJL RDYMSG DISPLAY = \"\"",C_CR,C_LF



pr_codes_SetUnderline   label   byte
        byte    5,C_ESC,"&d3D"
pr_codes_ResetUnderline label   byte
        byte    4,C_ESC,"&d@"

pr_codes_SetASCII7	label	byte
	byte	4
	byte	C_ESC,"(0U"
pr_codes_SetIBM437	label	byte
	byte	5
	byte	C_ESC,"(10U"
pr_codes_SetIBM850	label	byte
	byte	5
	byte	C_ESC,"(12U"
pr_codes_SetRoman8	label	byte
	byte	4
	byte	C_ESC,"(8U"
pr_codes_SetWindows	label	byte
	byte	4
	byte	C_ESC,"(9U"
pr_codes_SetVentura	label	byte
	byte	5
	byte	C_ESC,"(13J"
pr_codes_SetLatin1	label	byte
	byte	4
	byte	C_ESC,"(0N"


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
	byte	C_ESC,"*t#R",0			;# = resolution in dpi.
pr_codes_TransferGraphics       label   byte
        byte    C_ESC,"*b#W",0
pr_codes_StartAndTransferGraphics       label   byte
	byte	C_ESC,"*r1A",C_ESC,"*b#W",0
;
;
; font/character controls:
;
pr_codes_SelectFont	label	byte
	byte	C_ESC,"(#X",0			;# = HPFontID
pr_codes_SelectChar	label	byte
	byte	C_ESC,"*c#E",0			;# = character
pr_codes_FontControl	label	byte
	byte	C_ESC,"*c#F",0			;# = HPFontControls

pr_codes_SetFontID	label	byte
	byte	C_ESC,"*c#D",0			;# = HPFontID

;
; Macro controls.
;
pr_codes_MacroControl	label	byte
	byte	C_ESC,"&f#X",0			;# = HPMacroControls

;
; font/text attribute commands:
pr_codes_SetResidentFixed	label	byte
	byte	C_ESC,"(s0p#h",0	;first few bytes in font selection.
pr_codes_SetResidentProportional	label	byte
	byte	C_ESC,"(s#p",0		;first few bytes in font selection.
;(these 4 use the SendCodeOut routine)
pr_codes_SetResidentUpright	label	byte
	byte	2,"0s"
pr_codes_SetResidentItalic	label	byte
	byte	2,"1s"
pr_codes_SetResidentMedium	label	byte
	byte	2,"0b"
pr_codes_SetResidentBold	label	byte
	byte	2,"3b"

;
; font/character download commands:
;
pr_codes_SendFont	label	byte
	byte	C_ESC,")s#W",0			;# = size HPFontHeader
pr_codes_SendChar	label	byte
	byte	C_ESC,"(s#W",0			;# = size char data
pr_codes_ContinueChar	label	byte
	byte	C_ESC,"(s#W",4,1,0		;# = size char data
						;continuation.
;movement code for space routine.

pr_codes_AdjustInX	label	byte
	byte    C_ESC,"*p#X",0		;# = dots to move from left margin.

pr_codes_AdjustInY	label	byte
	byte    C_ESC,"*p#Y",0		;# = dots to move from top margin.

pr_codes_RightRelMove	label	byte
	byte	C_ESC,"*p+#X",0		;# = dot width of space char.

;paper control stuff.

pr_codes_NumCopies	label	byte	;set the number of copies in printer.
	byte	C_ESC,"&l#X",0

pr_codes_DuplexMode	label	byte	;set the duplex mode in the printer.
	byte	C_ESC,"&l#S",0

pr_codes_SetInputPath	label	byte	;set the input path for the paper.
	byte	C_ESC,"&l#H",0
