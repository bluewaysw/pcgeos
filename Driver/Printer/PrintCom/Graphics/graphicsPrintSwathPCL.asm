
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		HP PCL type print drivers
FILE:		graphicsPrintSwathPCL.asm

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

	$Id: graphicsPrintSwathPCL.asm,v 1.1 97/04/18 11:51:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a swath passed from spooler, all in one variable sized
		band, since the min band height is 1 scanline.
		

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
;	dec	cx			; see if only one band to do
	clc
	jcxz	destroyBuffer
		;set the graphics mode in the printer.
	clr	bh
	mov	bl,es:PS_mode
	mov	ax,cs:[bx].pr_graphic_Res_Values
	mov	di,offset pr_codes_SetGraphicRes
	call	WriteNumCommand
	jc	destroyBuffer

scanlineLoop:
	call	DerefAScanline
	call	PrSendScanline		;print a line from this swath.
	jc	destroyBuffer
	inc	es:[PS_newScanNumber]	;point at next line down.
	loop	scanlineLoop

	mov	si,offset pr_codes_EndGraphics
	call	SendCodeOut

		; all done, kill the buffer and leave
destroyBuffer:
	pushf
	call	PrDestroyPrintBuffers	;get rid of print buffer space.
	popf				; no errors
	.leave
	ret

PrintSwath	endp
