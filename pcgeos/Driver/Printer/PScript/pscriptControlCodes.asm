
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Printer Driver
FILE:		pscriptControlCodes.def

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dave	4/93		Initial revision


DESCRIPTION:
	This file contains Control Codes used by the
	PostScript printer driver

	$Id: pscriptControlCodes.asm,v 1.1 97/04/18 11:56:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;____________________HP PJL related control codes__________________________
pr_codes_PJLUEL         label   byte
        byte    9                       ;count
        byte    C_ESC,"%-12345X"        ;UEL Code.
pr_codes_PJLCRLF       label   byte
        byte    6                      ;count
        byte    "@PJL",C_CR,C_LF
pr_codes_PJLEnterPostScript       label   byte
        byte    34                      ;count
        byte    "@PJL ENTER LANGUAGE = POSTSCRIPT",C_CR,C_LF
pr_codes_PJLMsgPScript		label	byte
	byte	37			;count
	byte	"@PJL RDYMSG DISPLAY = \"GEOS PS JOB\"",C_CR,C_LF
pr_codes_PJLMsgClear		label	byte
	byte	26			;count
	byte	"@PJL RDYMSG DISPLAY = \"\"",C_CR,C_LF


;________________________IBM SIC related Control Codes___________________

pr_codes_IBMSelectTraySIC	label	byte	;Set Initial Conditions
	byte	11			;count
	byte	C_ESC,"[K",7,0,0,49,1,0,0,0	;tray argument must follow.
pr_codes_IBMEnterPostScriptSIC	label	byte	;Set Initial Conditions
	byte	8			;count
	byte	C_ESC,"[K",3,0,0,49,8	;retain everything except data stream
