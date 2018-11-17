
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		9-pin print drivers
FILE:		graphicsPrintSwath48.asm

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

	$Id: graphicsPrintSwath48.asm,v 1.1 97/04/18 11:51:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a swath passed from spooler, figure the number
		of bands, and feed the correct amount to get to the top of
		the next band.
		Specialized routine for the Toshiba 24 pin dogs.
		This routine assumes that there is 1 vertical resolution: 48dpi.

		There is an approximation made to get the 180dpi printhead
		height close to a 1/48" boundary, without using so few pins
		as to render it useless.
		The approximation is: 19 pins = 5.06666 1/48" units.

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
	mov	dx,5			;
	call	PrLineFeed		;do the line feed in 1/48.
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
	clr	ax			;zero the 1/180 fraction
	mov	bx,ax			;div by 3.75 to get 1/48s in dx.
	mov	cx,17476		
	call	GrMulWWFixed
		;error on the short side, so toss fraction.
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
