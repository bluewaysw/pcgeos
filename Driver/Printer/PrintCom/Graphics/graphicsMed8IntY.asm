
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Star 9-pin print drivers
FILE:		graphicsMed8IntY.asm

AUTHOR:		Dave Durran 

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/4/93		Initial revision


DESCRIPTION:

	$Id: graphicsMed8IntY.asm,v 1.1 97/04/18 11:51:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintMediumBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prints a Medium resolution band.
	loads a 8 bit Medium band interleaved for Medium res, rotates it,
	sends each color, so on for each interleave.
	It uses the normal 8 bit rotate routine, so modes requiring adjacent
	dots to be printed on the next pass need to use the graphicsHi8IntXY
	module to send alternating even/odd columns.
example in star mode:
	Loads a 16 bit high buffer of the desired width from the input
	bitmap data.  The data is rotated properly for the 2 pass routine
	giving a resolution of 120 x 144 dpi on Star 9-pin Gemini type
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
	Dave	03/04/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrPrintMediumBand	proc	near
	uses	ax,bx,cx,dx,di,bp
curBand       local   BandVariables
        .enter
        mov     ax,es:[PS_newScanNumber] ;set the band start for this band.
        mov     curBand.BV_bandStart,ax
	mov	cl,MED_RES_INTERLEAVE_FACTOR	;do MED_RES_INTERLEAVE_FACTOR
	mov	curBand.BV_interleave,cl			;interleaves.
entry:
        call    PrLoadBandBuffer        ;fill the bandBuffer
        call    PrScanBandBuffer        ;determine live print width.
        mov     cx,dx                   ;cl = lo byte count value.
        jcxz    colors                  ;if no data, just exit.
        mov     si,offset pr_codes_SetMedGraphics
        call    PrSendGraphicControlCode ;send the graphics code for this band
        jc      exit                    ;propogate errors out.
        call    PrRotate8Lines          ;send this band.
        jc      exit                    ;propogate errors out.
colors:
        call    SetNextCMYK
        mov     cx,es:[PS_curColorNumber]       ;see if the color is the first.
	jcxz    afterPass
        mov     ax,curBand.BV_bandStart
        mov     es:[PS_newScanNumber],ax ;set back to start of band
        jmp     entry                   ;do the next color.
afterPass:
        mov     ax,curBand.BV_bandStart    ;point at next band interleave.
        inc     ax
        mov     curBand.BV_bandStart,ax
        mov     es:[PS_newScanNumber],ax
        call    Pr1ScanlineFeed         ;chunk down 1 scanline
        jc      exit
	dec	curBand.BV_interleave
	jnz	entry
        add     es:[PS_newScanNumber],(MED_RES_BAND_HEIGHT - MED_RES_INTERLEAVE_FACTOR)				        ;adjust to point after these
                                        ;interleaves.
exit:
	.leave
	ret
PrPrintMediumBand	endp
