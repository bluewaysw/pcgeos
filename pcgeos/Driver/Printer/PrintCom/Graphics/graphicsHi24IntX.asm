
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 24-pin print drivers
FILE:		graphicsHi24IntX.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:

	$Id: graphicsHi24IntX.asm,v 1.1 97/04/18 11:51:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintHighBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prints a High resolution band.
	doeas 2 passes for adjacent pixel printing.
	Loads a 17-24 bit high buffer of the desired width from the input
	bitmap data.  The data is rotated properly for the lq type 24
	pin printers.  It is assumed that the graphic print routine is
	using a 24-pin mode (ESC * 40 for 360 x 180dpi ).

CALLED BY:
	PrPrintABand

PASS:
	PS_newScanNumber = start line of band
	es	=	segment of PState

RETURN:
	PS_newScanNumber = start line of next band

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
	mov	ax,es:[PS_newScanNumber]	;init the bandStart.
	mov     curBand.BV_bandStart,ax
	call	PrSend24HiresLines	;send the even/odd swaths out.
	.leave
	ret
PrPrintHighBand	endp
