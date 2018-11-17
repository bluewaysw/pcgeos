
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb ASCII (Unformatted) Print Driver
FILE:		dumbControlCodes.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        Dave    8/30/93         Initial Revision


DC_ESCRIPTION:
	This file contains all the style setting routines for the Dumb
	driver.
		
	$Id: dumbControlCodes.asm,v 1.1 97/04/18 11:56:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE DUMB ASCII PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter	label	byte
pr_codes_InitPrinter	label	byte	;general initialize conditions.
pr_codes_InitTextMode   label   byte

;__________ASF Control______________________________________
pr_codes_InitPaperLength        label   byte
pr_codes_ASFControl     label   byte
pr_codes_EnableASF      label   byte
pr_codes_DisableASF     label   byte
pr_codes_DefeatPaperOut	label	byte

;_________Pitch Control_____________________________________
pr_codes_Set10PitchRoman	label	byte
        byte    C_NULL

