
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon Redwood Bubble-Jet 64-jet Print Driver
FILE:		red64ControlCodes.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/10/92	Initial revision


DESCRIPTION:
	This file contains all the control codes for the Canon 64-jet
	driver.
		
	$Id: red64ControlCodes.asm,v 1.1 97/04/18 11:55:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE CANON BUBBLEJET 64-JET PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Print Engine Control_____________________________
pr_codes_ResetPrinter	label	byte
	byte	2			;byte count for code.
	byte	01,10h			;initialize the printer mechanism.
pr_codes_InitSpeed	label	byte
	byte	3			;byte count for code.
	byte	02,01h,0		;set fine mode 80CPS
pr_codes_InitDraftSpeed	label	byte
	byte	3			;byte count for code.
	byte	02,01h,5		;set draft mode 160CPS
pr_codes_SetForward	label	byte
	byte	3			;byte count for code.
	byte	02,02h,00
pr_codes_SetBackward	label	byte
	byte	3			;byte count for code.
	byte	02,02h,01
pr_codes_CleanHead	label	byte
	byte	2			;byte count for code.
	byte	1,11h			;clean the head 3 time purge.
pr_codes_CapHead	label	byte
        byte    2                       ;byte count for code.
	byte	1,13h			;cap the head immediately.
pr_codes_SetTOD		label	byte
	byte	2			;byte count......
	byte	7,08h			;Set time and date (6 bytes follow)
pr_codes_ParkHead	label	byte	;stick the head out of harms way.
	byte	3			;byte count
	byte	02,30h,00

;__________ASF Control______________________________________
pr_codes_SetManualFeed        label   byte
	byte	3			;byte count for code.
        byte    02,05h,04		;set the manual feed option.
pr_codes_SetASF         label   byte
	byte	3			;byte count for code.
        byte    02,05h,05		;set the Auto Sheet feed option.
pr_codes_FormFeed       label   byte
	byte	2			;byte count for code.
        byte    01,06h			;eject a page from the printer.

;__________Cursor Control______________________________________
pr_codes_AbsPos	label	byte
	byte	2			;byte count for code.
	byte	3,12h			;word argument follows...
pr_codes_DoLineFeed	label	byte
	byte	3			;byte count for code.
	byte	4,7h,0			;word argument follows...
pr_codes_DoReverseFeed	label	byte
	byte	3			;byte count for code.
	byte	4,7h,1			;word argument follows...
pr_codes_ASFQuery	label	byte	
	byte	3
	byte	2,20h,4			;get options installed.

;__________Graphics Control______________________________________
pr_codes_SetHiGraphics		label	byte	;dummy offset.
pr_codes_SetGraphicsWidth	label	byte
	byte	2
	byte	5,3h		;left (word) and right (word) positions follow
pr_codes_StartPrinting		label	byte
	byte	4
	byte	3,4h,0,0		;assume the paper is positioned before

pr_codes_GetPaperErrors	label	byte		;return the status of paper.
	byte	3
	byte	2,20h,1

pr_codes_enableEEPROM		label byte
	byte	9				;set EEPROM password
	byte	40h
	byte	"SysErom$"

pr_codes_ReadLoc00 		label	byte	
	byte	4				;read EEPROM user location 0
	byte	41h,1,0,0

pr_codes_disableEEPROM		label	byte
	byte	4				;disable EEPROM commands
	byte	41h, 0, 0, 0
	
pr_codes_GetPaperPosition	label	byte	;return the paper vertical
	byte	2 				;position in 1/360"
	byte	1,26h
pr_codes_GetPrinterCondition	label	byte	;return the status of mechanism.
	byte	3
	byte	2,20h,0
pr_codes_GetPaperRemaining	label	byte	;return the amount of paper left
	byte	2
	byte	1,21h
