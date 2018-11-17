
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript print driver
FILE:		psbTables.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/11/91		Initial revision


DESCRIPTION:
	This file contains any printer specific tables
		
	$Id: psbTables.asm,v 1.1 97/04/18 11:52:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------------------------------------------
;	Routines found in other modules
;--------------------------------------------------------------------------

modHanJumpTable label	word
		hptr	handle CommonCode	; DR_PRINT_START_JOB
		hptr	handle CommonCode	; DR_PRINT_END_JOB

		hptr	handle CommonCode	; DR_PRINT_SWATH

		hptr	handle CommonCode	; DR_PRINT_SET_FONT
		hptr	handle CommonCode	; DR_PRINT_SET_COLOR
		hptr	handle CommonCode	; DR_PRINT_TEXT
		hptr	handle CommonCode	; DR_PRINT_SET_STYLES
		hptr	handle CommonCode	; DR_PRINT_TEST_STYLES
		hptr	handle CommonCode	; DR_PRINT_RAW
		hptr	handle CommonCode	; DR_PRINT_SET_CURSOR
		hptr	handle CommonCode	; DR_PRINT_START_PAGE
		hptr	handle CommonCode	; DR_PRINT_END_PAGE
		hptr	handle CommonCode	; DR_PRINT_SET_LINE_SPACING

modOffJumpTable label	word
		word	offset CommonCode:PrintStartJob
		word	offset CommonCode:PrintEndJob

		word	offset CommonCode:PrintSwath

		word	offset CommonCode:PrintSetFont
		word	offset CommonCode:PrintSetColor
		word	offset CommonCode:PrintText
		word	offset CommonCode:PrintSetStyles
		word	offset CommonCode:PrintTestStyles
		word	offset CommonCode:PrintRaw
		word	offset CommonCode:PrintSetCursor
		word	offset CommonCode:PrintStartPage
		word	offset CommonCode:PrintEndPage
		word	offset CommonCode:PrintSetLineSpacing


;--------------------------------------------------------------------------
;	Escape codes supported and routine table
;--------------------------------------------------------------------------

escCodes	label	word			; escape codes supported

NUM_ESC_ENTRIES	equ	($ - escCodes)/2


escHanJumpTable label	word

escOffJumpTable label	word

