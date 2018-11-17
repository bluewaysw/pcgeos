
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LBP Print Driver
FILE:		lbpControlCodes.asm

AUTHOR:		Dave Durran, 1 April 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/1/90		Initial revision
	Dave	6/22/92		Initial 2.0 revision


DC_ESCRIPTION:
	This file contains all the Printer Control Codes for the LBP
	driver.
		
	$Id: lbpControlCodes.asm,v 1.1 97/04/18 11:51:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE Canon LBP PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

pr_codes_CSIcode	label	byte
	byte	2,C_ESC,"["

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
	byte	4
	byte	C_ESC,";"	;enter ISO Mode.
	byte	C_ESC,"<"	;Soft Reset.

pr_codes_InitPaperLetter	label	byte
	byte	6
	byte	C_ESC,"[30;;"	;portrait letter paper size

pr_codes_InitPaperLegal	label	byte
	byte	6
	byte	C_ESC,"[32;;"	;portrait legal paper size

pr_codes_InitPaperA4	label	byte
	byte	6
	byte	C_ESC,"[14;;"	;portrait A4 paper size

pr_codes_InitPaperB5	label	byte
	byte	6
	byte	C_ESC,"[26;;"	;portrait B5 paper size

pr_codes_InitPaperCustom	label	byte
	byte	5
	byte	C_ESC,"[80;"	;custom paper size

pr_codes_InitPrinter	label	byte
	byte	48
	byte	"p"		;FINISH SETTING paper size, and format
	byte	C_ESC,"[3&z"	;enter extended full paint mode.
	byte	C_ESC,"[?2h"	;disable auto FF
	byte	C_ESC,"[?1l"	;disable auto NL
	byte	C_ESC,"[7 I"	;Set size unit to 1/300".
	byte	C_ESC,"[11h"	;set positional units to SIZE.
	byte	C_ESC,"[0;0f"	;set CAP to 0,0
	byte	C_ESC,"(",027h,024h,032h ;set primary graphic char set to IBML.
	byte	C_ESC,")",027h,020h,031h ;set secondary graphic char set IBMR1.
	byte	C_ESC,"[?32h"	;enable scalable font selection.


;__________Graphics Control______________________________________
pr_codes_SetGraphics	label	byte
	byte	5
	byte	";75.r",0,0	;Set Graphics resolution to Low Res.
	byte	6
	byte	";150.r",0	;Set Graphics resolution to Med Res.
	byte	6
	byte	";300.r",0	;Set Graphics resolution to Hi Res.

;__________Style Run Control______________________________________
pr_codes_SetDutch	label	byte
	byte	6
	byte	C_ESC,"[5;5y"
pr_codes_SetSwiss	label	byte
	byte	6
	byte	C_ESC,"[4;4y"
pr_codes_SetCourier	label	byte
	byte	6
	byte	C_ESC,"[3;3y"
pr_codes_SetPitchStart	label	byte
	byte	3
	byte	C_ESC,"[?"
pr_codes_SetPitchEnd	label	byte
	byte	3
	byte	"0 K"
pr_codes_SetSizeStart	label	byte
	byte	2
	byte	C_ESC,"["
pr_codes_SetSizeEnd	label	byte
	byte	2
	byte	" C"

;__________Pitch Control______________________________________
pr_codes_Set10Pitch	label	byte
	byte	5
	byte	C_ESC,"[0 K"
pr_codes_Set12Pitch	label	byte
	byte	5
	byte	C_ESC,"[1 K"
pr_codes_Set15Pitch	label	byte
	byte	5
	byte	C_ESC,"[2 K"
pr_codes_SetProportional	label	byte
	byte	6
	byte	C_ESC,"[?0 K"

;__________Style Control______________________________________
pr_codes_SetBold	label	byte
	byte	4
	byte	C_ESC,"[1m"
pr_codes_SetItalic	label	byte
	byte	4
	byte	C_ESC,"[3m"
pr_codes_SetUnderline	label	byte
	byte	4
	byte	C_ESC,"[4m"
pr_codes_SetShadow	label	byte
	byte	5
	byte	C_ESC,"[?6m"
pr_codes_SetOutline	label	byte
	byte	5
	byte	C_ESC,"[?7m"
pr_codes_SetReverse	label	byte
	byte	4
	byte	C_ESC,"[7m"
pr_codes_SetDblWidth	label	byte
	byte	11
	byte	C_ESC,"[100;200 B"

pr_codes_ResetBold	label	byte
	byte	5
	byte	C_ESC,"[22m"
pr_codes_ResetItalic	label	byte
	byte	5
	byte	C_ESC,"[23m"
pr_codes_ResetUnderline	label	byte
	byte	5
	byte	C_ESC,"[24m"
pr_codes_ResetShadow	label	byte
	byte	6
	byte	C_ESC,"[?26m"
pr_codes_ResetOutline	label	byte
	byte	6
	byte	C_ESC,"[?27m"
pr_codes_ResetReverse	label	byte
	byte	5
	byte	C_ESC,"[27m"
pr_codes_ResetDblWidth	label	byte
	byte	11
	byte	C_ESC,"[100;100 B"
