
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		lbp print driver
FILE:		graphicsCapslCommon.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/22/92		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the lbp
	print driver graphics mode support

	$Id: graphicsCapslCommon.asm,v 1.1 97/04/18 11:51:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintABand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap

CALLED BY:	GLOBAL

PASS:		es	- PState segment
		PS_newScanNumber = top line of this band

RETURN:		carry	-set if some communications error
		PS_newScanNumber = top line of next band

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrPrintABand	proc	near
	uses	ax,bx,cx,dx,di,es
	.enter

        call    PrLoadBandBuffer        ;fill the bandBuffer
	push	ds,si
	mov	ds,es:[PS_bufSeg]		;source segment for band
	mov	si,offset GPB_bandBuffer	;set source to be the band
					;buffer.

		;Scan the left to see where we can start sending stuff.
		;We want to find the number of leading zero bytes. we find
		;the number of full bytes to the right, and subtract from
		;the byte width to get the offset to move in.
	clr	dx			;init the live print width to zero.
	mov	cx,es:PS_bandHeight	;use height as counter.
	push 	si

forwardScanLoop:
	push	cx,es
	mov	cx,es:PS_bandBWidth	;width of input bitmap (swath)
	segmov	es,ds,di		;es --> bitmap segment for scas.
					;direction is assumed to be forward.
	mov	di,si			;load index for compare.
	clr	al			;compare inverted zero.
	repe	scasb			;test the byte for "zero"
	jz	aroundInc1
	inc	cx			;cx has # of non-zero bytes.

aroundInc1:
	cmp	dx,cx			;see if less than previous line.
	jnc	leadingZerosOK
	mov	dx,cx			;if not, load dx (new width)

leadingZerosOK:
	pop	cx,es
	add	si,es:PS_bandBWidth	;add for the start of the next line.
	loop	forwardScanLoop		;do # lines times.
	pop	si

		;dx now = # bytes to right of leading blank bytes.
	test	dx,dx			;see if zero.
	jz	exit			;done if no data.
	mov	ax,es:PS_bandBWidth	;width of input bitmap (swath)
	mov	es:PS_intWidth,dx	;save width of data.
	sub	ax,dx			;get width of leading blank bytes.
	mov	cl,3			;x8 for bit width.
	sal	ax,cl

		;Set the CAP to the correct place in X to start picture.
		;ax is now the bit distance in from the left margin to start
		;printing stuff.
	call	PrAdjustForResolution
	push	si
	mov	si,offset pr_codes_CSIcode
	call	SendCodeOut
	pop	si
	jc	carryStage			;pass error out.
		;send the width (bits) out.
	call	HexToAsciiStreamWrite
	jc	carryStage			;pass error out.
	mov	cl,"`"
	call	PrintStreamWriteByte

carryStage:
	jc	carryStage2			;pass error out.

		;Scan the right to see where we can stop sending stuff.
		;We dont want to send trailing zeros, so check how wide we need
		;to send.
	push	si
	clr	dx			;initialize the width to zero.
	mov	cx,es:PS_bandHeight	;use height as counter.
	add	si,es:PS_bandBWidth	;width of input bitmap (swath)
	dec	si			;start from right side.
	std				;go backwards.

backwardScanLoop:
	push	cx,es
	mov	cx,es:PS_intWidth	;width of live data 
	segmov	es,ds,di		;es --> bitmap segment for scas.
					;direction is assumed to be forward.
	mov	di,si			;load index for compare.
	clr	al			;compare inverted zero.
	repe	scasb			;test the byte for "zero"
	inc	cx			;cx has # of non-zero bytes.
					;there has to be at least 1.
	cmp	dx,cx			;see if less than previous line.
	jnc	trailingZerosOK
	mov	dx,cx			;if not, load dx (new width)

trailingZerosOK:
	pop	cx,es
	add	si,es:PS_bandBWidth	;add for the start of the next line.
	loop	backwardScanLoop		;do # lines times.
	cld
	pop	si

		;dx now = # bytes of live print area.
	mov	bx,es:PS_bandBWidth
	sub	bx,es:PS_intWidth	;bx now = # of leading blank bytes.
	mov	es:PS_intWidth,dx	;intWidth now = live print width.

		;send control code to send graphics.
		;dx	- number of bytes wide to send.
		;bx	- number of leading zero bytes.
	mov	cx,dx			;calculate the total byte count.
	clr	dx
	mov	ax,es:[PS_bandHeight]
	mul	cx
	push	bx,si
	mov	si,offset pr_codes_CSIcode
	call	SendCodeOut	
	jc	controlcodesent
	call	HexToAsciiStreamWrite	;send total bytes amount.
	jc	controlcodesent
	mov	cl,";"			;demarkation character in control code.
	call	PrintStreamWriteByte	;send it.
	jc	controlcodesent
	mov	ax,es:[PS_intWidth]	;byte width in dx for hex to ascii out.
	call	HexToAsciiStreamWrite	;send byte width.
	jc	controlcodesent
	clr	ah
	mov	al,es:[PS_mode]		;get the resolution mode.
	sal	ax,1			;x8 for index.
	sal	ax,1
	mov	si,ax
	add	si,offset cs:pr_codes_SetGraphics
	call	SendCodeOut

controlcodesent:
	pop	bx,si

carryStage2:
	jc	exit

		;send the bitmap out
		;ds:si	- input bitmap data source (beginning of print area)
	add	si,bx		;get start of bitmap to start of live area.
	mov	cx,es:PS_bandHeight ;number of lines to send.
sendOuterLoop:
	push	cx,si
	mov	cx,es:PS_intWidth ;get live print width.
	call	PrintStreamWrite	;send them out.
	pop	cx,si
	jc	exit
	add	si,es:PS_bandBWidth ;get to next line beginning of data.
	loop	sendOuterLoop

		; some transmission error. cleanup and exit
exit:
	pop	ds,si
	.leave
	ret

PrPrintABand	endp
