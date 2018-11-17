

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		common routines for the print driver
FILE:		rotate2pass24.asm

AUTHOR:		Dave Durran 

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/28/92		Initial revision


DESCRIPTION:
        Group of routines to support the 2 pass 24 bit high for
        printers that can not print horizontally adjacent dots on
        the same pass.

	Bit 7s at the top end of each byte.

APPLICATION:
	Epson 24 pin printers 2 pass hi res mode 360 x 180 dpi
		epson24.geo
	Epson late model 24 pin printers 4 pass hi res mode 360dpi sq.
		epshi24.geo
		nec24.geo

	$Id: rotate2pass24.asm,v 1.1 97/04/18 11:51:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSend24HiresLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Scans to find the live print width of this group of scanlines, and
	sends them out, using the even/odd column hi res method for the
	Epson LQ type 24 pin printers.

CALLED BY:
	Driver Hi res graphics routine.

PASS:
	es	=	segment of PState

RETURN:
        newScanNumber adjusted to (interleaveFactor) past the end of buffer.


DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSend24HiresLines	proc	near

	uses	cx
curBand       local   BandVariables
        .enter	inherit
entry:
        call    PrLoadBandBuffer        ;fill the bandBuffer
	call	PrScanBandBuffer	;determine live print width.
	mov	cx,dx			;
	jcxz	colors			;if no data, just exit.
	mov	si,offset pr_codes_SetHiGraphics
	call	PrSendGraphicControlCode ;send the graphics code for this band
	jc	exit
        call    PrRotate24LinesEvenColumns       ;send an interleave
	jc	exit
	mov	si,offset pr_codes_SetHiGraphics
		;cx must live from ScanBuffer to here for this to work.
	call	PrSendGraphicControlCode ;send the graphics code for this band
	jc	exit
        call    PrRotate24LinesOddColumns
	jc	exit
colors:
        call    SetNextCMYK
        mov     cx,es:[PS_curColorNumber]       ;see if the color is the first.
	jcxz    exit
        mov     ax,curBand.BV_bandStart
        mov     es:[PS_newScanNumber],ax ;set back to start of band
        jmp     entry                   ;do the next color.
exit:
	.leave
	ret

PrSend24HiresLines	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrRotate24LinesEvenColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a high density row
		only the even columns.... the odd ones are untouched .
		MED_RES_BUFF_HEIGHT must be the height of the printhead
		or less.
                If MED_RES_BUFF_HEIGHT is less than 24, the routine will
                rotate into the top MED_RES_BUFF_HEIGHT lines of a 24 pin
                printhead configuration. MED_RES_BUFF_HEIGHT must be at least
                17 for this to work right.

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

PrRotate24LinesEvenColumns	proc	near
	uses	ax, bx, cx, dx, ds, di, si, bp
	.enter
		
	mov	bp,es:[PS_bandBWidth]	;width of bitmap
	mov	si,offset GPB_bandBuffer ;source of data.
	mov	ds,es:[PS_bufSeg]	;get segment of output buffer.
					;get the scanned byte width to
        mov     di, offset GPB_outputBuffer ;output buffer
	call	PrClearOutputBuffer	;clean out any bytes that are in the 
					;desired zero column positions.
groupLoop:
	push	si			;save the start point
	mov	ah, MED_RES_BUFF_HEIGHT
if	MED_RES_BUFF_HEIGHT ne 24
	clr	cx			;init the destination bytes.
	mov	dx,cx
endif
byteLoop:
		; disperse the pixels from this scanline to the eight
		; successive groups on which we're currently working
	mov	al,ds:[si]		;  byte so we can get pixels
	shr	al
	shr	al
	rcl	dh
	shr	al
	shr	al
	rcl	dl
	shr	al
	shr	al
	rcl	ch
	shr	al
	shr	al
	rcl	cl
		; advance to the next scanline. If we've completed another eight
		; of these loops, the bytes are ready to be stored. since
		; slCount (ah) starts at 24, if the low 3 bits are 0 after the
		; decrement, we've done another 8
	add	si, bp		; point si at next sl
	dec	ah
	test	ah, 0x7
	jnz	byteLoop
		; fetch start of the byte group from dest and store all the
		; bytes we've worked up, leaving  zeros in between these
		; columns...
	mov	ds:[di], cl
	mov	ds:[di+6], ch
	mov	ds:[di+12], dl
	mov	ds:[di+18], dh	
	inc	di

					;  counter.
	tst	ah			; at end of the group?
	jnz	byteLoop		; no! keep going...
		; advance the destination to the start of the next group (21
		; bytes away since it was incremented 3 times during the loop).
	add	di, 21
        cmp     di,PRINT_OUTPUT_BUFFER_SIZE
        jb      bufferNotFull
        call    PrSendOutputBuffer
	jc	exitPop
bufferNotFull:

		; advance the scanline start position one byte to get to next
		; set of 8 pixels in the buffer

	pop	si			;get old start point
	inc	si
		
	dec	bx			; any more bytes in the row?
	jnz	groupLoop
        or      di,di                   ;any bytes remaining in outputBuffer?
        jz      exit                    ;if not, just exit.
        call    PrSendOutputBuffer      ;flush out the partial buffer.
exit:
	.leave
	ret

exitPop:
	pop	si			;clean up stack...
	jmp	exit			;and exit....
PrRotate24LinesEvenColumns	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrRotate24LinesOddColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a high density row
		only the odd columns.... the even ones are untouched .
                MED_RES_BUFF_HEIGHT must be the height of the printhead
                or less.
                If MED_RES_BUFF_HEIGHT is less than 24, the routine will
                rotate into the top MED_RES_BUFF_HEIGHT lines of a 24 pin
                printhead configuration. MED_RES_BUFF_HEIGHT must be at least
                17 for this to work right.

CALLED BY:	INTERNAL

PASS:
	bx	=	width of live print area
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

PrRotate24LinesOddColumns	proc	near
	uses	ax, bx, cx, dx, ds, di, si, bp
	.enter
		
	mov	bp,es:[PS_bandBWidth]	;width of bitmap
	mov	si,offset GPB_bandBuffer ;source of data.
	mov	ds,es:[PS_bufSeg]	;get segment of output buffer.

        mov     di, offset GPB_outputBuffer ;output buffer
	call	PrClearOutputBuffer	;clean out any bytes that are in the 
					;desired zero column positions.
groupLoop:
	push	si			;save the start point
        mov     ah, MED_RES_BUFF_HEIGHT
if      MED_RES_BUFF_HEIGHT ne 24
        clr     cx                      ;init the destination bytes.
        mov     dx,cx
endif
byteLoop:
		; disperse the pixels from this scanline to the eight
		; successive groups on which we're currently working
	mov	al,ds:[si]		;  byte so we can get pixels
	shr	al
	rcl	dh
	shr	al
	shr	al
	rcl	dl
	shr	al
	shr	al
	rcl	ch
	shr	al
	shr	al
	rcl	cl
		; advance to the next scanline. If we've completed another eight
		; of these loops, the bytes are ready to be stored. since
		; slCount (ah) starts at 24, if the low 3 bits are 0 after the
		; decrement, we've done another 8
	add	si, bp		; point si at next sl
	dec	ah
	test	ah, 0x7
	jnz	byteLoop
		; fetch start of the byte group from dest and store all the
		; bytes we've worked up, leaving  zeros in between these
		; columns...
	mov	ds:[di+3], cl
	mov	ds:[di+9], ch
	mov	ds:[di+15], dl
	mov	ds:[di+21], dh	
	inc	di

					;  counter.
	tst	ah			; at end of the group?
	jnz	byteLoop		; no! keep going...
		; advance the destination to the start of the next group (21
		; bytes away since it was incremented 3 times during the loop).
	add	di, 21
        cmp     di,PRINT_OUTPUT_BUFFER_SIZE
        jb      bufferNotFull
        call    PrSendOutputBuffer
	jc	exitPop
bufferNotFull:

		; advance the scanline start position one byte to get to next
		; set of 8 pixels in the buffer

	pop	si			;get back start point.
	inc	si
		
	dec	bx			;done with this line?
	jnz	groupLoop
        or      di,di                   ;any bytes remaining in output buff?
        jz      exit                    ;if not, just exit.
        call    PrSendOutputBuffer      ;flush out the partial buffer.
exit:
	.leave
	ret

exitPop:
	pop	si			;clean up stack...
	jmp	exit			;and exit....
PrRotate24LinesOddColumns	endp
