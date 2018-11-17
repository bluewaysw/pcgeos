
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson late model 24-pin print drivers
FILE:		graphicsPrintSwath360.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:

	$Id: graphicsPrintSwath360.asm,v 1.1 97/04/18 11:51:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap

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
	call	SetFirstCMYK		;set the ribbon up.
	jc	exitErr
;	dec	cx			; see if only one band to do
	jcxz	printLastBand
bandLoop:
	call	PrPrintABand		;print a band from this swath.
	jc	exitErr
	push	dx			; save band count
	mov	dx,HI_RES_BAND_HEIGHT
if HI_RES_INTERLEAVE_FACTOR ne 1                ;only for interleaved passes
	cmp     es:[PS_mode], PM_GRAPHICS_HI_RES
	jne	lineFeedHere
	sub	dx,HI_RES_INTERLEAVE_FACTOR	;make up for extra 1/360 between
					;hi resolution passes.
lineFeedHere:
endif
	call	PrLineFeed		;send control code for hi res.
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
	cmp	es:[PS_mode], PM_GRAPHICS_LOW_RES
	jne	checkMedRes
	mov	cx, dx			; amount to line feed (in hires)
	shl	cx, 1			; need it *3 for 60 to 180dpi
	add	dx, cx
checkMedRes:
	cmp	es:[PS_mode], PM_GRAPHICS_HI_RES
	je	send360LineFeed
	shl	dx,1			;x2 for 180 to 360 dpi
	jmp	sendLastLineFeed
send360LineFeed:
if HI_RES_INTERLEAVE_FACTOR ne 1                ;only for interleaved passes
	sub	dx,HI_RES_INTERLEAVE_FACTOR	;make up for extra 1/360 between
					;hi resolution passes.
	js	destroyBuffer		;just leave, if negative result.
endif
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
