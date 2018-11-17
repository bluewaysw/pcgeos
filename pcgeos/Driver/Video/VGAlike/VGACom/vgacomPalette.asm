COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VGA Video Driver
FILE:		vgacomPalette.asm

AUTHOR:		Jim DeFrisco, Mar 11, 1992

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/11/92		Initial revision


DESCRIPTION:
	color tables	
		

	$Id: vgacomPalette.asm,v 1.1 97/04/18 11:42:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;***************************************************************************
;	DEFAULT PALETTE 
;***************************************************************************

NUM_PAL_ENTRIES	equ	16		; number of entries in palette

;	this table contains the RGB values corresponding to the indices
;	stored in the above vidPalette table.

currentPalette	byte	00h, 00h, 00h	; entry 0 -- black
		byte	00h, 00h, 0aah	; entry 1 -- dk blue
		byte	00h, 0aah, 00h	; entry 2 -- dk green
		byte	00h, 0aah, 0aah	; entry 3 -- dk cyan
		byte	0aah, 00h, 00h	; entry 4 -- dk red
		byte	0aah, 00h, 0aah	; entry 5 -- dk violet
		byte	0aah, 055h, 00h	; entry 6 -- brown
		byte	0aah, 0aah,0aah	; entry 7 -- dk grey
		byte	55h, 55h, 55h	; entry 8 -- lt grey
		byte	55h, 55h, 0ffh	; entry 9 -- lt blue
		byte	55h, 0ffh, 55h	; entry a -- lt green
		byte	55h, 0ffh, 0ffh	; entry b -- lt cyan
		byte	0ffh, 55h, 55h	; entry c -- lt red
		byte	0ffh, 55h, 0ffh	; entry d -- lt violet
		byte	0ffh, 0ffh, 55h	; entry e -- yellow
		byte	0ffh, 0ffh,0ffh	; entry f -- white
		
		; default mapping is one-to-one
defBitmapPalette byte	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15		
