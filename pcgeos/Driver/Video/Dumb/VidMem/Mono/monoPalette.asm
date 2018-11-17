COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver	
FILE:		monoPalette.asm

AUTHOR:		Jim DeFrisco, Mar 11, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/11/92		Initial revision


DESCRIPTION:

	Basic palette info.	
		

	$Id: monoPalette.asm,v 1.1 97/04/18 11:42:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NUM_PAL_ENTRIES	equ	2		; number of entries in palette

;	this table contains the RGB values corresponding to the indices
;	stored in the above vidPalette table.

palDefRGBValues	byte	0ffh, 0ffh, 0ffh	; entry 0 -- white
		byte	000h, 000h, 000h	; entry 1 -- black
		
palCurRGBValues	byte	0ffh, 0ffh, 0ffh	; entry 0 -- white
		byte	000h, 000h, 000h	; entry 1 -- black
		


