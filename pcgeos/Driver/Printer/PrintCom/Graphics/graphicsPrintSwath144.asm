
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		9-pin print drivers
FILE:		graphicsPrintSwath144.asm

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

	$Id: graphicsPrintSwath144.asm,v 1.1 97/04/18 11:51:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a swath passed from spooler, figure the number
		of bands, and feed the correct amount to get to the top of
		the next band.
		This routine assumes that there are 2 print resolutions
		of vertical resolutions: 72dpi, 144dpi.

CALLED BY:	GLOBAL

PASS:		bp	- PState segment
		dx.cx	- VM file and block handle for Huge bitmap

RETURN:		carry	- set if some transmission error

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
	uses	ax,cx,ds,bx,dx,si,di,ds,es
	.enter
	mov	es, bp			; es -> PState

		; load the bitmap header into the PState
	call	LoadSwathHeader		; bitmap header into PS_swath

		; load up the band width and height
	call	PrLoadPstateVars	;set up the pstate band Vars.

		; size and allocate a graphics data buffer
	call	PrCreatePrintBuffers	;allocate the print buffer.

		; get pointer to data
	clr	ax
	mov	es:[PS_curColorNumber],ax ;init offset into scanline.
	call	DerefFirstScanline		; ds:si -> scan line zero
        call    SetFirstCMYK            ;set the ribbon up.
;	dec	cx			; see if only one band to do
	jcxz	printLastBand

bandLoop:
	call	PrPrintABand		;print a band from this swath.
	jc	exitErr
	push	dx			; save band count
	mov	dx,(HI_RES_BAND_HEIGHT - HI_RES_INTERLEAVE_FACTOR)
	cmp	es:[PS_mode],PM_GRAPHICS_LOW_RES
	jne	sendLineFeed
	add	dx,HI_RES_INTERLEAVE_FACTOR ;make up the extra lines sent in
						;hires.

sendLineFeed:
	call	PrLineFeed		;do the line feed in 1/144.
	pop	dx
	jc	exitErr
	loop	bandLoop

		; if any remainder, then we need to send it, plus a shorter
		; line feed
printLastBand:
	tst	dx			; any remainder ?
	jz	destroyBuffer
	call	PrPrintABand		; print last band
	jc	exitErr
	cmp	es:[PS_mode],PM_GRAPHICS_LOW_RES
	jne	correctForScanlineFeeds
	mov	cx, dx			; amount to line feed (in hires)
	shl	dx, 1			; need it *2 for 72dpi
	jmp	sendLastLineFeed

correctForScanlineFeeds:
	sub	dx,HI_RES_INTERLEAVE_FACTOR ;dont resend the 1Scanline feeds 
	js	destroyBuffer		;dont bother if remaining distance is
					;negative
	jz	destroyBuffer		;or zero.

sendLastLineFeed:
	call	PrLineFeed	; 
	jc	exitErr

		; all done, kill the buffer and leave
destroyBuffer:
	call	PrDestroyPrintBuffers	;get rid of print buffer space.
	clc				; no errors
exit:
	.leave
	ret

		; some transmission error.  cleanup and exit.
exitErr:
	call	PrDestroyPrintBuffers	;get rid of print buffer space.
	stc
	jmp	exit
PrintSwath	endp
