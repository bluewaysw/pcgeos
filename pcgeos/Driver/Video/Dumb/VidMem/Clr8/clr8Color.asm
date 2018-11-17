COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		clr8Color.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
    GBL	VidSetPalEntry	Set a new palette entry
	
REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/91	initial version


DESCRIPTION:

	$Id: clr8Color.asm,v 1.1 97/04/18 11:42:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetPalEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a single palette entry

CALLED BY:	GLOBAL, INTERNAL

PASS:		ah	- index to set
		al	- red component
		bl	- green component
		bh	- blue component

RETURN:		ah	- index just set
		al	- red component		(value actually set by device)
		bl	- green component	(value actually set by device)
		bh	- blue component	(value actually set by device)

DESTROYED:	dx, di

PSEUDO CODE/STRATEGY:
		set the new entry;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	07/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSetPalEntry	proc	near
		uses	cx
		.enter

		; now have valid RGB color, store to shadowed palette

		mov	dl, ah				; get index into word
		clr	dh				;  
		mov	di, dx				;
		shl	dx, 1				; mul by three
		add	di, dx
		mov	ss:palCurRGBValues[di].RGB_red, al	; 
		mov	ss:palCurRGBValues[di].RGB_green, bl	
		mov	ss:palCurRGBValues[di].RGB_blue, bh

		.leave
		ret
VidSetPalEntry	endp

