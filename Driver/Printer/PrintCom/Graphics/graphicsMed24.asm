
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 24-pin print drivers
FILE:		graphicsMed24.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:

	$Id: graphicsMed24.asm,v 1.1 97/04/18 11:51:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintMediumBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Used to print a 24 pin medium resolution band. (non-interleaved)
	Usually used to print a 180dpi resolution band.
	Loads a MED_RES_BUFF_HEIGHT buffer of the desired width from the input
	bitmap data.  
	Bit 7 is the top bit of the rotated data.

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
	Dave	03/01/90	Initial version
	Dave	03/20/90	combined some routines.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrPrintMediumBand	proc	near
	uses	ax,bx,cx,dx,di
curBand	local	BandVariables
	.enter
	mov	ax,es:[PS_newScanNumber] ;set the band start for this band.
	mov	curBand.BV_bandStart,ax
entry:
	call	PrLoadBandBuffer	;fill the bandBuffer
	call	PrScanBandBuffer	;determine live print width.
	mov	cx,dx			;cl = lo byte count value.
	jcxz	colors			;if no data, just exit.
	mov	si,offset pr_codes_SetMedGraphics
	call	PrSendGraphicControlCode ;send the graphics code for this band
	jc	exit			;propogate errors out.
	call	PrRotate24Lines		;send this band.
	jc	exit			;propogate errors out.
colors:
	call	SetNextCMYK
	mov	cx,es:[PS_curColorNumber]	;see if the color is the first.
	jcxz	exit
	mov	ax,curBand.BV_bandStart
	mov	es:[PS_newScanNumber],ax ;set back to start of band
	jmp	entry			;do the next color.
exit:
	.leave
	ret
PrPrintMediumBand	endp
