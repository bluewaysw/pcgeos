
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson late model 24-pin print drivers
FILE:		graphicsHi24IntXY.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:

	$Id: graphicsHi24IntXY.asm,v 1.1 97/04/18 11:51:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintHighBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prints a High resolution band. (interleaved)
        loads a 24 bit high band interleaved for high res, rotates it,
        sends each color, so on for each interleave.
example in epson mode:
	Loads a 24 bit high buffer of the desired width from the input
	bitmap data.  The data is rotated properly for the lq type 24
	pin printers.  It is assumed that the graphic print routine is
	using a 24-pin mode (ESC * 40 for 360 x 180dpi ).
	4-pass 360 dpi square mode.

CALLED BY:
	PrPrintABand

PASS:
	ds:si	=	pointer into bitmap data
			(has to be locked huge array block)
	es	=	segment of PState

RETURN:
	ds:si	=	Adjusted to point at the next scan line data in
			Huge Array.

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrPrintHighBand	proc	near
	uses	ax,bx,cx,dx,di
curBand	local	BandVariables
	.enter
        mov     ax,es:[PS_newScanNumber]        ;init the bandStart.
        mov     curBand.BV_bandStart,ax
        mov     cl,HI_RES_INTERLEAVE_FACTOR     ;do HI_RES_INTERLEAVE_FACTOR
        mov     curBand.BV_interleave,cl                   ;interleaves.
entry:
	call	PrSend24HiresLines	;send the even/odd swaths out.
	jc	exit			;pass out any errors.
	mov	si,offset pr_codes_DoSingleLineFeed ;feed 1/130"
	call	SendCodeOut
	jc	exit			;pass errors out.
	inc	es:[PS_cursorPos].P_y	;update the cursor position in PState.
	mov	ax,curBand.BV_bandStart		;inc the scanline number.
	inc	ax
	mov	curBand.BV_bandStart,ax
	mov	es:[PS_newScanNumber],ax

        dec     curBand.BV_interleave
        jnz     entry
        add     es:[PS_newScanNumber],(HI_RES_BAND_HEIGHT - \
		HI_RES_INTERLEAVE_FACTOR)  ;adjust to point after these
                                        ;interleaves.
exit:
	.leave
	ret
PrPrintHighBand	endp
