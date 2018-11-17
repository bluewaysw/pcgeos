COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		VidMem/Clr2
FILE:		clr2Palette.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	This file contains the default palette used by the 2-bit color driver.

	$Id: clr2Palette.asm,v 1.1 97/04/18 11:43:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;***************************************************************************
;	DEFAULT PALETTE 
;***************************************************************************

NUM_PAL_ENTRIES	equ	4		; number of entries in palette

;	this table contains the RGB values corresponding to the indices
;	stored in the above vidPalette table.

currentPalette	label	RGBValue
		byte	00h, 00h, 00h	; entry 0 -- black
		byte	55h, 55h, 55h	; entry 1 -- dk grey
		byte	0aah, 0aah,0aah	; entry 2 -- lt grey
		byte	0ffh, 0ffh,0ffh	; entry 3 -- white

		; default mapping is one-to-one
defBitmapPalette byte	0,1,1,1,1,1,1,2,1,2,2,2,2,2,2,3
