
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon Laser Beam print drivers
FILE:		graphicsPrintSwath300.asm

AUTHOR:		Dave Durran 

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/92		Initial revision


DESCRIPTION:

	$Id: graphicsPrintSwath300.asm,v 1.1 97/04/18 11:51:24 newdeal Exp $

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
        call    SetFirstCMYK            ;set the ribbon up.
;	dec	cx			; see if only one band to do
	jcxz	printLastBand
bandLoop:
	call	PrPrintABand		;print a band from this swath.
	jc	destroyBuffer
	add	es:[PS_cursorPos].P_y,HI_RES_BAND_HEIGHT
	call	PrMoveCursor		;send control code for hi res.
	jc	destroyBuffer
	loop	bandLoop

		; if any remainder, then we need to send it, plus a shorter
		; line feed
printLastBand:
	tst	dx			; any remainder ?
	jz	destroyBuffer
	call	PrPrintABand		; print last band
	jc	destroyBuffer
	mov	ax,dx			;get in ax for resolution adjustment
	call	PrAdjustForResolution
	mov	dx,ax
	add	es:[PS_cursorPos].P_y,dx
	call	PrMoveCursor	; 

		; all done, kill the buffer and leave
destroyBuffer:
	pushf
	call	PrDestroyPrintBuffers	;get rid of print buffer space.
	popf				; pass errors
	.leave
	ret

		; some transmission error.  cleanup and exit.
PrintSwath	endp
