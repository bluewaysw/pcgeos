
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		graphicsHi8IntXY.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision
	Dave	3/92		moved from epson9


DESCRIPTION:

	$Id: graphicsHi8IntXY.asm,v 1.1 97/04/18 11:51:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintHighBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prints a hi resolution band. (interleaved)
        loads a 8 bit high band interleaved for high res, rotates it,
        sends each color, so on for each interleave.
        It uses the even/odd 8 bit rotate routine, so modes requiring adjacent
        dots to be printed on a second pass can use it.
example in epson mode:
	Loads a 24 bit high buffer of the desired width from the input
	bitmap data.  The data is rotated properly for the 3 pass routine
	giving a resolution of 240 x 216 dpi on Epson 9-pin FX type
	printers.  It is assumed that the graphic print routine is
	using a 8-pin mode (ESC * 3 for 240 dpi horiz.).

CALLED BY:
	PrPrintABand

PASS:
	PS_newScanNumber = top line of this band
	es	=	segment of PState

RETURN:
	PS_newScanNumber = top line of next band

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/01/90	Initial version
	Dave	03/20/90	combined some routines.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrPrintHighBand	proc	near
	uses	ax,bx,cx,dx,di
curBand	local	BandVariables
	.enter
        mov     ax,es:[PS_newScanNumber] ;set the band start for this band.
        mov     curBand.BV_bandStart,ax
        mov     cl,HI_RES_INTERLEAVE_FACTOR     ;do HI_RES_INTERLEAVE_FACTOR
        mov     curBand.BV_interleave,cl                   ;interleaves.
entry:
	call	PrSend8HiresLines
	jc	exit
	mov	ax,curBand.BV_bandStart		;point at next band interleave.
	inc	ax
	mov	curBand.BV_bandStart,ax
	mov	es:[PS_newScanNumber],ax
	call	Pr1ScanlineFeed		;chunk down 1/216"
	jc	exit
        dec     curBand.BV_interleave
        jnz     entry
        add     es:[PS_newScanNumber],(HI_RES_BAND_HEIGHT - \
		HI_RES_INTERLEAVE_FACTOR) ;adjust to point after these
                                        ;interleaves.
exit:
	.leave
	ret
PrPrintHighBand	endp
