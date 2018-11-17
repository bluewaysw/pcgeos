

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson Escape P2 24-pin Print Driver
FILE:		escp2ControlCodes.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	7/31/91		Initial revision


DC_ESCRIPTION:
	This file contains all the Control Codes for the epshi 24-pin
	driver.
		
	$Id: escp2ControlCodes.asm,v 1.1 97/04/18 11:54:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;*****************************************************************************
;
;CONTROL CODES FOR THE EPSON ESC P2 24-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

pr_codes_ResetPrinter	label	byte
	byte	2,C_ESC,"@"
pr_codes_SetNoPerfSkip	label	byte
	byte	13,C_ESC,"O"
	byte	C_ESC,"t",1	;set 8 bit character table.
	byte	C_ESC,"6"	;set printing in 80h to 9fh range.
	byte	C_ESC,"(U",1,0,10	;ESC P2 set units to 1/360"
pr_codes_AbsPos	label	byte
	byte	2,C_ESC,"$"
pr_codes_SetTab	label	byte
	byte	2,C_ESC,"D"
pr_codes_DoTab	label	byte
	byte	2,0,C_HT
pr_codes_DoLineFeed	label	byte
	byte	2,C_ESC,"+"
pr_codes_DoMaxLineFeed	label	byte
	byte	3,C_ESC,"+",PR_MAX_LINE_FEED
pr_codes_SetLoGraphics	label	byte
	byte	3,C_ESC,"*",0
pr_codes_SetRasterGraphics	label	byte
	byte	9,C_ESC,"U",0		;set unidir printing for graphics
	byte	C_ESC,"(G",1,0,1	;ESC P2 set raster graphics mode cmd
pr_codes_SetMedGraphics	label	byte
	byte	6,C_ESC,".",0,20,20,24
pr_codes_SetHiGraphics	label	byte
	byte	6,C_ESC,".",0,10,10,24

pr_codes_Set10Pitch	label	byte
	byte	5,C_ESC,"p",0,C_ESC,"P"
pr_codes_Set12Pitch	label	byte
	byte	5,C_ESC,"p",0,C_ESC,"M"
pr_codes_Set15Pitch	label	byte
	byte	5,C_ESC,"p",0,C_ESC,"g"
pr_codes_SetProportional	label	byte
	byte	3,C_ESC,"p",1
pr_codes_SetCondensed	label	byte
	byte	1,C_SI
pr_codes_SetSubscript	label	byte
	byte	3,C_ESC,"S",1
pr_codes_SetSuperscript	label	byte
	byte	3,C_ESC,"S",0
pr_codes_SetNLQ	label	byte
	byte	3,C_ESC,"x",1
pr_codes_SetBold	label	byte
	byte	4,C_ESC,"E",C_ESC,"G"
pr_codes_SetItalic	label	byte
	byte	2,C_ESC,"4"
pr_codes_SetUnderline	label	byte
	byte	3,C_ESC,"-",1
pr_codes_SetDblWidth	label	byte
	byte	3,C_ESC,"W",1
pr_codes_SetDblHeight	label	byte
	byte	3,C_ESC,"w",1
pr_codes_ResetCondensed	label	byte
	byte	1,C_DC2
pr_codes_ResetScript	label	byte
	byte	2,C_ESC,"T"
pr_codes_ResetNLQ	label	byte
	byte	3,C_ESC,"x",0
pr_codes_ResetBold	label	byte
	byte	4,C_ESC,"F",C_ESC,"H"
pr_codes_ResetItalic	label	byte
	byte	2,C_ESC,"5"
pr_codes_ResetUnderline	label	byte
	byte	3,C_ESC,"-",0
pr_codes_ResetDblWidth	label	byte
	byte	3,C_ESC,"W",0
pr_codes_ResetDblHeight	label	byte
	byte	3,C_ESC,"w",0

