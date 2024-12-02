COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:		vgaPalette.asm

AUTHOR:		Jim DeFrisco, Oct 15, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/15/92		Initial revision


DESCRIPTION:
	Palette stuff
		

	$Id: vgaPalette.asm,v 1.1 97/04/18 11:41:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDevicePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the hardware palette

CALLED BY:	VidSetPalette
PASS:		currentPalette setup
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
	uses ax, bx, cx, dx, ds
		.enter
		.leave
		ret
SetDevicePalette	endp


if (0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixColorRGB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a 24-bit RGB value to a valid 6-bit VGA palette
		entry

CALLED BY:	INTERNAL

PASS:		al	- red component
		bl	- green component
		bh	- blue component

RETURN:		al	- fixed red component
		bl	- fixed green component
		bh	- fixed blue component

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		map the full range of 0-ff into 3f values evenly distributed
		between 0 and ff.
		new component=(old AND 0xfc) OR (old >> 6)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	07/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixColorRGB	proc	near
		uses	cx
		.enter

		; fix red component

		mov	cl, al			; save red component
		clr	ch
		shl	cx, 1			; get two high bits into ch
		shl	cx, 1
		and	al, 0xfc		; clear out low two bits
		or	al, ch			; set two bits as approp.

		; fix green component

		mov	cl, bl			; do green component
		clr	ch
		shl	cx, 1			; get two high bits into ch
		shl	cx, 1
		and	bl, 0xfc		; clear out low two bits
		or	bl, ch			; set two bits as approp.

		; fix blue component

		mov	cl, bh			; do green component
		clr	ch
		shl	cx, 1			; get two high bits into ch
		shl	cx, 1
		and	bh, 0xfc		; clear out low two bits
		or	bh, ch			; set two bits as approp.

		.leave
		ret
FixColorRGB	endp
endif