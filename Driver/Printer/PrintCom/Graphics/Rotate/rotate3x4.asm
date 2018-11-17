

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		commom print driver routines
FILE:		rotate3x4.asm

AUTHOR:		Dave Durran 28 Feb 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/28/92		Initial revision


DESCRIPTION:
	Group of rotate routines to do the 12 bit high 120 x 108 dpi mode
	(3-pass) for Epson 9-pin printers.

Application:
	call	PrRotate4LinesZeroBottom	;send top interleave
	call	PrRotate4LinesZeroTop	;send bottom interleave
	call	PrRotate4LinesZeroBottom	;send middle interleave


	$Id: rotate3x4.asm,v 1.1 97/04/18 11:51:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrRotate4LinesZeroTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	used for pass 2

CALLED BY:
	Internal

PASS:
	bx	=	byte width of live print area
	es	=	segment address of PState

RETURN:

DESTROYED:
	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrRotate4LinesZeroTop	proc	near
	uses	bx,cx,dx,ds,di,si
bWidthRemaining	local	word
scanlineStart	local	word
nextdown	local	word
count		local	byte
	.enter
	mov	bWidthRemaining,bx ;init the main counter.
	mov	ax,es:[PS_bandBWidth] ;width used for byte count, and next line
					;offset.
	mov	nextdown,ax	;save the offset for the next byte below.
        mov     ds,es:[PS_bufSeg]       ;get segment of output buffer.
        mov     scanlineStart, offset GPB_bandBuffer ;input band buffer
        mov     di, offset GPB_outputBuffer ;output buffer

groupLoop:
	push	es		;save the PState seg.
	segmov	es,ds,ax	;point at the beginning of the GBP struc.

	mov	si,scanlineStart
	mov	count,4		;do 4 x 2 shifts bits in one byte.
byteloop:
	push	si		;save scanline position
	mov	si,[si]		;get the byte for this shift
				;use the regs to shift into, they will be
				;stored later.
	clc			;set zero to shift in.
	rcl	dh,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	dh,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	dl,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	dl,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	ch,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	ch,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	cl,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	cl,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	bh,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	bh,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	bl,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	bl,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	ah,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	ah,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	al,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	al,1		;shift in to a dest. byte.

	pop	si		;recover scanline position
	add	si,nextdown	;add for the next byte down vertically.
	dec	count		;adjust the loop counter.
	jnz	byteloop

	stosw			;di should be correct, and is adjusted here.
	mov	ax,bx
	stosw
	mov	ax,cx
	stosw
	mov	ax,dx
	stosw

	pop	es		;get back PState seg.

	cmp	di,PRINT_OUTPUT_BUFFER_SIZE
        jb      bufferNotFull
        call    PrSendOutputBuffer
        jc      exit
bufferNotFull:

                ; advance the scanline start position one byte to get to next
                ; set of 8 pixels in the buffer

        inc     scanlineStart

        dec     bWidthRemaining         ; any more bytes in the row?
        jnz     groupLoop
	or	di,di			;see if there is any spare data left in
	jz	exit			;if not, just exit.
	call	PrSendOutputBuffer	;flush out the partial buffer.
exit:
	.leave
	ret
PrRotate4LinesZeroTop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrRotate4LinesZeroBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	used for pass 1, and 3

CALLED BY:
	Internal

PASS:
        bx      =       live print width in bytes.
	es	=	segment address of PState
	si	=	start address for bitmap in bandBuffer.
	bp	=	offset for next byte below to load.

RETURN:

DESTROYED:
	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrRotate4LinesZeroBottom	proc	near
	uses	bx,cx,dx,ds,di,si
bWidthRemaining	local	word
scanlineStart	local	word
nextdown	local	word
count		local	byte
	.enter
	mov	bWidthRemaining,bx ;init the main counter.
	mov	ax,es:[PS_bandBWidth]
	mov	nextdown,ax	;save the offset for the next byte below.
        mov     ds,es:[PS_bufSeg]       ;get segment of output buffer.
        mov     scanlineStart, offset GPB_bandBuffer ;input band buffer
        mov     di, offset GPB_outputBuffer ;output buffer

groupLoop:
	push	es
	segmov	es,ds,ax	;point at the beginning of the GBP struc.

	mov	si,scanlineStart
	mov	count,4		;do 4 x 2 shifts bits in one byte.
byteloop:
	push	si		;save the scanline position.
	mov	si,[si]		;get the byte for this shift
				;use the regs to shift into, they will be
				;stored later.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	dh,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	dh,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	dl,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	dl,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	ch,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	ch,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	cl,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	cl,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	bh,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	bh,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	bl,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	bl,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	ah,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	ah,1		;shift zero bit in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcl	al,1		;shift in to a dest. byte.
	clc			;set zero to shift in.
	rcl	al,1		;shift zero bit in to a dest. byte.

	pop	si		;recover the scanline position.
	add	si,nextdown	;add for the next byte down vertically.
	dec	count		;adjust the loop counter.
	jnz	byteloop

	stosw			;di should be correct, and is adjusted here.
	mov	ax,bx
	stosw
	mov	ax,cx
	stosw
	mov	ax,dx
	stosw

	pop	es

	cmp	di,PRINT_OUTPUT_BUFFER_SIZE
        jb      bufferNotFull
        call    PrSendOutputBuffer
        jc      exit
bufferNotFull:

                ; advance the scanline start position one byte to get to next
                ; set of 8 pixels in the buffer

        inc     scanlineStart

        dec     bWidthRemaining         ; any more bytes in the row?
        jnz     groupLoop
	or	di,di			;see if there is any spare data left in
	jz	exit			;if not, just exit.
	call	PrSendOutputBuffer	;flush out the partial buffer.
exit:
	.leave
	ret
PrRotate4LinesZeroBottom	endp
