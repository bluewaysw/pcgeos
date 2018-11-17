
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon Redwood
FILE:		graphicsPrintSwathRedwood.asm

AUTHOR:		Dave Durran 

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/14/92		Initial revision


DESCRIPTION:

	$Id: graphicsPrintSwathRedwood.asm,v 1.1 97/04/18 11:51:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap

CALLED BY:	GLOBAL

PASS:		bp	- PState segment
		dx.cx	- VM file and block handle for Huge bitmap

RETURN:		dx	- how much to move down for next bitmap		
		carry	- set if some transmission error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSwath	proc	far
	uses	ax,bx,cx,si,di,ds,es
	.enter

	mov	es, bp			; es -> PState

		; load the bitmap header into the PState
	call	LoadSwathHeader		; bitmap header into PS_swath

		;we dont load some PState variables anymore.
        	;     es:[PS_bandHeight]
        	;     es:[PS_buffHeight]
        	;     es:[PS_interleaveFactor]
		;none of these locations should be used by Redwood.

		; load up the band width and height
        mov     ax, es:[PS_swath].B_width
        add     ax, 7                   ; round up to next byte boundary
        and     al, 0xf8
        mov     es:[PS_bandWidth], ax   ; load the dot width.
        mov     cl, 3                   ; divide by 8....
        shr     ax, cl                  ; to obtain the byte width.
        mov     es:[PS_bandBWidth], ax

		;do the bands/swath calculation.
        mov     ax,es:[PS_swath].B_height ; get the height of bitmap.
        clr     dx                      ; dx:ax = divisor
	mov	cx,GRAPHICS_FEED_HEIGHT
        div     cx		        ;get number of bands in this
        mov     cx,ax                   ;swath for counter.
                                                ; dx has remainder of division
						; should be 2
                                                ; this is the #scans
	call	PrCreatePrintBuffers		;alloc our memory bitmap buffer

		; get pointer to data
	clr	ax
	mov	es:[PS_curColorNumber],ax ;init offset into scanline.
	call	DerefFirstScanline		; ds:si -> scan line zero
	call	SetFirstCMYK		;set the ribbon up.
	jc	exitErr
;	dec	cx			; see if only one band to do
	jcxz	printLastBand
bandLoop:
	push	dx			; save band count
	cmp	dx,BAND_OVERLAP_AMOUNT
	jle	addFeedHeight
	mov	dx,BAND_OVERLAP_AMOUNT	;init to LIVE_PRINT_HEIGHT

addFeedHeight:
	add	dx,GRAPHICS_FEED_HEIGHT	;normally this should wind up being
					;LIVE_PRINT_HEIGHT
	call	PrPrintHighBand		;print a band from this swath.
	pop	dx
	jc	exitErr

	mov	es:[PS_redwoodSpecific].RS_yOffset,GRAPHICS_FEED_HEIGHT
	loop	bandLoop

		; if any remainder, then we need to send it, plus a shorter
		; line feed
printLastBand:
	cmp	dx,BAND_OVERLAP_AMOUNT	;normally this should wind up being
	jle	noFeed			;some where like 0
	tst	dx			; any remainder ?
	jz	destroyBuffer
	call	PrPrintHighBand		; print last band
	jc	exitErr
					;hi resolution passes.
	sub	dx,BAND_OVERLAP_AMOUNT
	mov	es:[PS_redwoodSpecific].RS_yOffset,dx
	mov	dx,BAND_OVERLAP_AMOUNT

noFeed:
		; all done, kill the buffer and leave
destroyBuffer:
        call    PrDestroyPrintBuffers   ;get rid of print buffer space.
	clc				; no errors
exit:
	.leave
	ret

		; some transmission error.  cleanup and exit.
exitErr:
        call    PrDestroyPrintBuffers   ;get rid of print buffer space.
	stc
	jmp	exit
PrintSwath	endp




