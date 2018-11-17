COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon BJC Print Driver
FILE:		canonBJCControlCodes.asm

AUTHOR:		Joon Song, 9 Jan 1999

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/99		Initial version from canon48ControlCodes.asm


DESCRIPTION:
	This file contains all the control codes for the Canon BJC driver.
		
	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
; CONTROL CODES FOR THE CANON BUBBLEJET PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

;__________Job Control______________________________________
pr_codes_ResetPrinter		label	byte
	byte	7		;byte count
	byte	C_ESC,"[K",2,0	;command = RESET, byte count
	byte	0, 15		;init = 0, id = 15

pr_codes_InitPrinter		label	byte
	byte	14		;byte count
	byte	C_ESC,"(b",1,0	;command = COMPRESSION MODE, byte count
	byte	1		;compression = PackBits
	byte	C_ESC,"(t",3,0	;command = SET IMAGE FORMAT, byte count
	byte	1,0,0		;bitdepth = 1, format = CMYK, ink = regular

pr_codes_SetPrintResolution	label	byte
	byte	5
	byte	C_ESC,"(d",4,0	;command = SET IMAGE RESOLUTION, byte count
				;4 bytes = vert.hi, vert.lo, horiz.hi, horiz.lo

pr_codes_SetPrintingMethod	label	byte
	byte	6
	byte	C_ESC,"(c",2,0	;command = SET PRINT METHOD, byte count
	byte	0x10		;color print
				;extra byte to follow containing Media&Quality

pr_codes_ReturnToEmulationMode	label	byte
	byte	2		; byte count
	byte	C_ESC,"@"

;__________Cursor Control______________________________________
pr_codes_DoLineFeed		label	byte
	byte	5		;byte count
	byte	C_ESC,"(e",2,0	;command = RASTER SKIP, byte count

;__________Graphics Control____________________________________
pr_codes_SetGraphics		label	byte
	byte	3		;byte count
	byte	C_ESC,"(A"	;command = SET COLOR COMPONENT

;__________Color Control_______________________________________
canonBJColorTable		label	byte
	byte	"YCMK"
