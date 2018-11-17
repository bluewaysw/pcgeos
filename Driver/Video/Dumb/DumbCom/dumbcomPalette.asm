COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video drivers
FILE:		dumbcomPalette.asm

AUTHOR:		Jim DeFrisco, Mar 11, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/11/92		Initial revision


DESCRIPTION:
	color palette info	
		

	$Id: dumbcomPalette.asm,v 1.1 97/04/18 11:42:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NUM_PAL_ENTRIES	equ	2		; number of entries in palette


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDevicePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the actual device palette

CALLED BY:	INTERNAL
		VidSetPalette
PASS:		palCurRGBValues buffer up to date
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDevicePalette	proc	near
		.enter
		.leave
		ret
SetDevicePalette	endp
ForceRef	SetDevicePalette

;	this table contains the RGB values corresponding to the indices
;	stored in the above vidPalette table.

currentPalette	label	RGBValue
		byte	0ffh, 0ffh, 0ffh	; entry 0 -- white
		byte	000h, 000h, 000h	; entry 1 -- black
		

defBitmapPalette byte	0x00,0xff

