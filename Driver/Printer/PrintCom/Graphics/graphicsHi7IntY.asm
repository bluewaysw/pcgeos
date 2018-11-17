
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Oki 9-pin print drivers
FILE:		graphicsHi7IntY.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:

	$Id: graphicsHi7IntY.asm,v 1.1 97/04/18 11:51:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintHighBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Used for Oki 9-pin driver 
	CAUTION: the control code sequence is way different for this routine.
	Prints a hi resolution band.
	loads a 7 bit high band interleaved for high res, rotates it,
	sends each color, so on for each interleave.

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
	uses	ax,bx,cx,dx,di,bp
curBand	local	BandVariables
        .enter
        mov     ax,es:[PS_newScanNumber] ;set the band start for this band.
        mov     curBand.BV_bandStart,ax
	mov	cl,HI_RES_INTERLEAVE_FACTOR	;do HI_RES_INTERLEAVE_FACTOR
	mov	curBand.BV_interleave,cl			;interleaves.
entry:
        call    PrLoadBandBuffer        ;fill the bandBuffer
        call    PrScanBandBuffer        ;determine live print width.
        mov     cx,dx                   ;cl = lo byte count value.
        jcxz    colors                  ;if no data, just exit.
        mov     si,offset pr_codes_EnterGraphics
        call    SendCodeOut		;send the graphics code for this band
        jc      exit                    ;propogate errors out.
        call    PrRotate7Lines          ;send this band.
        jc      exit                    ;propogate errors out.
        mov     si,offset pr_codes_ExitGraphics
        call    SendCodeOut		;send the graphics code for this band
        jc      exit                    ;propogate errors out.
colors:
        call    SetNextCMYK
        mov     cx,es:[PS_curColorNumber]       ;see if the color is the first.
	jcxz    afterPass
        mov     ax,curBand.BV_bandStart
        mov     es:[PS_newScanNumber],ax ;set back to start of band
        jmp     entry                   ;do the next color.
afterPass:
        mov     ax,curBand.BV_bandStart        ;point at next band interleave.
        inc     ax
        mov     curBand.BV_bandStart,ax
        mov     es:[PS_newScanNumber],ax
        call    Pr1ScanlineFeed         ;chunk down 1 scanline
        jc      exit
	dec	curBand.BV_interleave
	jnz	entry
        add     es:[PS_newScanNumber],(HI_RES_BAND_HEIGHT - HI_RES_INTERLEAVE_FACTOR)				        ;adjust to point after these
                                        ;interleaves.
exit:
	.leave
	ret
PrPrintHighBand	endp
