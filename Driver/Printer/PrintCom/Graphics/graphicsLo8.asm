
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MX 9-pin print drivers
FILE:		graphicsLo8.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:

	$Id: graphicsLo8.asm,v 1.1 97/04/18 11:51:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintLowBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prints a Low resolution band.
	loads a 8 bit high band Low res, rotates it,
	sends each color.
	It uses the normal 8 bit rotate routine
example in epson mode:
	Loads a 8 bit high buffer of the desired width from the input
	bitmap data.  The data is rotated properly for the 1 pass routine
	giving a resolution of 60 x 72 dpi on Epson 9-pin FX type
	printers.  It is assumed that the graphic print routine is
	using a 8-pin mode. 

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

PrPrintLowBand	proc	near
	uses	ax,bx,cx,dx,di
curBand	local	BandVariables
        .enter
        mov     ax,es:[PS_newScanNumber] ;set the band start for this band.
	mov	curBand.BV_bandStart,ax
entry:
        call    PrLoadBandBuffer        ;fill the bandBuffer
        call    PrScanBandBuffer        ;determine live print width.
        mov     cx,dx                   ;cl = lo byte count value.
        jcxz    colors                  ;if no data, just exit.
        mov     si,offset pr_codes_SetLoGraphics
        call    PrSendGraphicControlCode ;send the graphics code for this band
        jc      exit                    ;propogate errors out.
        call    PrRotate8Lines          ;send this band.
        jc      exit                    ;propogate errors out.
colors:
        call    SetNextCMYK
        mov     cx,es:[PS_curColorNumber]       ;see if the color is the first.
	jcxz    exit
        mov     ax,curBand.BV_bandStart
        mov     es:[PS_newScanNumber],ax ;set back to start of band
        jmp     entry                   ;do the next color.
exit:
	.leave
	ret
PrPrintLowBand	endp
