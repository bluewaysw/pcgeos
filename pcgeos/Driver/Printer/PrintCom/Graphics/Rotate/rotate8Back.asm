

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		commom print driver routines
FILE:		rotate8Back.asm

AUTHOR:		Dave Durran 28 Feb 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/28/92		Initial revision


DESCRIPTION:

	$Id: rotate8Back.asm,v 1.1 97/04/18 11:51:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrRotate8Lines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	Internal

PASS:
	bx	=	byte width of live print area
	es	=	segment address of PState
	si	=	offset in buffer to get scanlines from.

RETURN:

DESTROYED:
	ax

PSEUDO CODE/STRATEGY:
	differs from the normal rotate8lines routine in that the top bit
	is the LSB.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrRotate8Lines	proc	near
	uses	bx,cx,dx,ds,di,si
bWidthRemaining	local	word
scanlineStart	local	word
nextdown	local	word
count		local	byte
	.enter
        mov     bWidthRemaining,bx	;init the main counter.
	mov	ax,offset GPB_bandBuffer
        mov     scanlineStart, ax	;input band buffer
	mov	ax,es:[PS_bandBWidth]	;offset to next scanline.
        mov     nextdown,ax		;save offset for the next byte below.
        mov     ds,es:[PS_bufSeg]       ;get segment of output buffer.
        mov     di, offset GPB_outputBuffer ;output buffer

groupLoop:
        push    es              ;save the PState seg.
        segmov  es,ds,ax        ;point at the beginning of the GBP struc.

	mov	si,scanlineStart
	mov	count,8		;do 8 bits in one byte.
byteloop:
	push	si

	mov	si,[si]		;get the byte for this shift
				;use the regs to shift into, they will be
				;stored later.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcr	dh,1		;shift in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcr	dl,1		;shift in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcr	ch,1		;shift in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcr	cl,1		;shift in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcr	bh,1		;shift in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcr	bl,1		;shift in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcr	ah,1		;shift in to a dest. byte.
	shr	si,1		;shift a bit from the source byte (low byte).
	rcr	al,1		;shift in to a dest. byte.

	pop	si		;get back the index for this source byte.
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
PrRotate8Lines	endp
