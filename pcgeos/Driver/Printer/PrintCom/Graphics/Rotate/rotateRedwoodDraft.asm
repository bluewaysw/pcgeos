

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		common routines for the print driver
FILE:		rotateRedwoodDraft.asm

AUTHOR:		Dave Durran 

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/93		Initial revision


DESCRIPTION:

	$Id: rotateRedwoodDraft.asm,v 1.1 97/04/18 11:51:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrRotate64LinesMulX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a low density row

CALLED BY:	INTERNAL

PASS:
	bx	=	byte width of live print area
        es      =       segment address of PState

RETURN:		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Do the regular rotate for 64 pins high, but copy all the data
		multiple times in the X direction, to produce a draft quality
		buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE: This routine assumes that you have a whole swath sized
		Output Buffer available, so it doesnt test for the end of the 
		output buffer in the grouploop.
		This output buffer is fixed at location:
			PR_OUTPUT_BUFFER_START_SEG
		The intermediate memory bitmap buffer is still pointed at
		by the PState location: PS_bufSeg

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrRotate64LinesMulX	proc	near
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
	mov	di, PRINTHEAD_HEIGHT
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
		; slCount starts at 8, if the low 3 bits are 0 after the
		; decrement, we've done another 8
	add	si, inputBWidth		; point si at next sl
	dec	di
	test	di, 0x7
	jnz	byteLoop
		; fetch start of the byte group from dest and store all the
		; bytes we've worked up, using stosb at the end to automatically
		; increment di so we get to the next subgroup in the 64-byte
		; group.
	xchg	di, destination		; (preserve counter in "dest")
	mov	ds,es:[PS_redwoodSpecific].RS_outputBuffer
					;point at the destination DMA buffer.
	mov	ds:[di+224], dh		;  if they were done in the
	mov	ds:[di+224+8], dh		
	mov	ds:[di+224+16], dh	
	mov	ds:[di+224+24], dh
	mov	ds:[di+192], dl		;  loop.
	mov	ds:[di+192+8], dl		
	mov	ds:[di+192+16], dl	
	mov	ds:[di+192+24], dl
	mov	ds:[di+160], ch
	mov	ds:[di+160+8], ch
	mov	ds:[di+160+16], ch
	mov	ds:[di+160+24], ch
	mov	ds:[di+128], cl
	mov	ds:[di+128+8], cl
	mov	ds:[di+128+16], cl
	mov	ds:[di+128+24], cl
	mov	ds:[di+96], bh
	mov	ds:[di+96+8], bh
	mov	ds:[di+96+16], bh
	mov	ds:[di+96+24], bh
	mov	ds:[di+64], bl
	mov	ds:[di+64+8], bl
	mov	ds:[di+64+16], bl
	mov	ds:[di+64+24], bl
	mov	ds:[di+32], ah
	mov	ds:[di+32+8], ah
	mov	ds:[di+32+16], ah
	mov	ds:[di+32+24], ah
	mov	ds:[di], al
	mov	ds:[di+8], al
	mov	ds:[di+16], al
	mov	ds:[di+24], al

        mov     ds,es:[PS_bufSeg]       ;get segment of driver bitmap buffer.
	inc	di

	xchg	destination, di		; save new dest and recover
					;  counter.
	tst	di			; at end of the group?
	jnz	byteLoop		; no! keep going...
		; advance the destination to the start of the next group (56
		; bytes away since it was incremented 8 times during the loop).
		;add the multiple copy space....
	add	destination, 224+24

		; advance the scanline start position one byte to get to next
		; set of 8 pixels in the buffer

	inc	scanlineStart
		
	dec	bWidthRemaining		; any more bytes in the row?
	jnz	groupLoop
	mov	di,destination		;get back the index in output buffer.
	or	di,di			;any bytes remaining?
	jz	exit			;if not, just exit.

	call	PrSendOutputBuffer	;Send the finished DMA Output buffer.

		;Now we set the reverse direction from the last pass in the
		;PState and in the printer.
	mov	si,offset pr_codes_SetForward	;assume forward direction.
	xor	es:[PS_redwoodSpecific].RS_direction,PRINT_DIRECTION_REVERSE
					;next pass
	jz	setNewDirection
        mov     si,offset pr_codes_SetBackward	;set the reverse direction.

setNewDirection:
	call	SendCodeOut

exit:
	.leave
	ret

PrRotate64LinesMulX	endp
