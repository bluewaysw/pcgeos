

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		common routines for the print driver
FILE:		rotate24Into4.asm

AUTHOR:		Dave Durran 

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/28/92		Initial revision


DESCRIPTION:

	$Id: rotate24Into4.asm,v 1.1 97/04/18 11:51:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrRotate24Lines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a medium density row
                If HI_RES_BUFF_HEIGHT is less than 24, the routine will
                rotate into the bottom HI_RES_BUFF_HEIGHT lines of a 24 pin
                printhead configuration. HI_RES_BUFF_HEIGHT must be at least
                19 for this to work right.
		This file services the Toshiba method of 4 byte (6bit)
		per column rotate.

CALLED BY:	INTERNAL

PASS:
	bx	=	byte width of live print area
        es      =       segment address of PState

RETURN:		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrRotate24Lines	proc	near
	uses	ax, bx, cx, dx, ds, di, si
inputBWidth	local	word			; byte width of input bitmap
bWidthRemaining	local	word			; byte width of live print
scanlineStart	local	word			; First byte in scanline group
destination	local	word			; Offset to first byte in
						;  result group
	.enter
		
	mov	bWidthRemaining,bx	; initialize main counter
	mov	ax,es:[PS_bandBWidth] ;save width of bitmap.
	dec	ax			;only need 1 less than width.
	mov	inputBWidth,ax 	
	mov	ds,es:[PS_bufSeg]	;get segment of output buffer.
					;get the scanned byte width to
	mov	scanlineStart, offset GPB_bandBuffer ;input band buffer
	mov	destination, offset GPB_outputBuffer ;output buffer
groupLoop:
	mov	si, scanlineStart
        mov     di, HI_RES_BUFF_HEIGHT
        clr     ax                      ;initialize the destination bytes.
        mov     bx,ax
        mov     cx,ax
        mov     dx,ax
byteLoop:
		; disperse the pixels from this scanline to the eight
		; successive groups on which we're currently working
	xchg	ax, di			; preserve ax while getting
	mov	ah, al			;  scanline counter into high
	lodsb				;  byte so we can get pixels
	xchg	ax, di			;  into low and have count
	shr	di			;  shift its way back down
	rcl	dh			;  over the course of these
	shr	di			;  operations whereby the
	rcl	dl			;  individual pixels are
	shr	di			;  dispersed to the proper
	rcl	ch			;  bytes of the current
	shr	di			;  8-vertical-line group
	rcl	cl
	shr	di
	rcl	bh
	shr	di
	rcl	bl
	shr	di
	rcl	ah
	shr	di
	rcl	al
		; advance to the next scanline. If we've completed another eight
		; of these loops, the bytes are ready to be stored. since
		; slCount starts at 24, if the low 3 bits are 0 after the
		; decrement, we've done another 8
	add	si, inputBWidth		; point si at next sl
	dec	di
	cmp	di, 18
	je	storeTheBytes
	cmp	di, 12
	je	storeTheBytes
	cmp	di, 6
	je	storeTheBytes
	tst	di
	jnz	byteLoop

storeTheBytes:
		; fetch start of the byte group from dest and store all the
		; bytes we've worked up, using stosb at the end to automatically
		; increment di so we get to the next subgroup in the 32-byte
		; group.
	xchg	di, destination		; (preserve counter in "dest")

	mov	ds:[di+28], dh		;  if they were done in the
	mov	ds:[di+24], dl		;  loop.
	mov	ds:[di+20], ch
	mov	ds:[di+16], cl
	mov	ds:[di+12], bh
	mov	ds:[di+8], bl
	mov	ds:[di+4], ah
	mov	ds:[di], al
	inc	di

	xchg	destination, di		; save new dest and recover
					;  counter.
	tst	di			; at end of the group?
	jnz	byteLoop		; no! keep going...
		; advance the destination to the start of the next group (28
		; bytes away since it was incremented 4 times during the loop).
	add	destination, 28
        cmp     destination,PRINT_OUTPUT_BUFFER_SIZE
        jb      bufferNotFull
	xchg	destination, di		; save new dest and recover
        call    PrSendOutputBuffer
	jc	exit
	xchg	destination, di		; save new dest and recover
bufferNotFull:

		; advance the scanline start position one byte to get to next
		; set of 8 pixels in the buffer

	inc	scanlineStart
		
	dec	bWidthRemaining		; any more bytes in the row?
	jnz	groupLoop
	mov	di,destination		;get bac the output buffer index
	or	di,di			;any bytes remaining?
	jz	exit			;if not, just exit.
	call	PrSendOutputBuffer	;flush out the partial buffer.
exit:
	.leave
	ret
PrRotate24Lines	endp
