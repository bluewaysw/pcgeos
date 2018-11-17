

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		commom print driver routines
FILE:		rotate2pass8.asm

AUTHOR:		Dave Durran 28 Feb 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/28/92		Initial revision


DESCRIPTION:
	Group of routines to support the 2 pass 8 bit high for 
	printers that need to not print horizontally adjacent dots on
	the same pass.
	Bit 7 is the top bit.

APPLICATIONS:
	Epson 9-pin printers 6 pass hi res mode
		epson9.geo
		eprx9.geo


	$Id: rotate2pass8.asm,v 1.1 97/04/18 11:51:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSend8HiresLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Scans to find the live print width of this group of scanlines, and
	sends them out, using the even/odd column hi res method for the
	Epson 9-pin FX type printers.

CALLED BY:
	Driver Hi res graphics routine.

PASS:
	es	=	segment of PState

RETURN:
	newScanNumber adjusted to 3 past the end of buffer.

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

PrSend8HiresLines	proc	near
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
        call    PrRotate8LinesEvenColumns       ;send an interleave
	jc	exit
	mov	si,offset pr_codes_SetHiGraphics
		;cx must live from ScanBuffer to here for this to work.
	call	PrSendGraphicControlCode ;send the graphics code for this band
	jc	exit
        call    PrRotate8LinesOddColumns
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

PrSend8HiresLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrRotate8LinesEvenColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	Internal

PASS:
	bx	=	byte width of the live print area
	es	=	segment address of PState

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrRotate8LinesEvenColumns	proc	near
	uses	ax,bx,cx,dx,ds,di,si,es,bp
	.enter
	mov	bp,es:[PS_bandBWidth]	;width of bitmap
	mov	si,offset GPB_bandBuffer ;source of data.
	segmov	ds,es,ax	;save the PState segment in ds.
        mov     es,es:[PS_bufSeg]       ;get segment of output buffer.
        mov     di, offset GPB_outputBuffer ;output buffer

groupLoop:
	push	si		;save the scan line start position
	mov	ah,8		;do 8 bits in one byte.
byteloop:
	mov	al,es:[si]	;get the byte for this shift
	shr	al		;shift out the even columns....
	shr	al		;4 bits into target registers.....
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
	add	si,bp		;add for the next byte down vertically.
	dec	ah		;adjust the loop counter.
	jnz	byteloop

	;clr	ah		;ah should be cleared from above....
	mov	al,cl		;store the target regs into the output buff.
	stosw			;di should be correct, and is adjusted here.
	mov	al,ch
	stosw
	mov	al,dl
	stosw
	mov	al,dh
	stosw

	cmp	di,PRINT_OUTPUT_BUFFER_SIZE
        jb      bufferNotFull

	mov	ax,ds		;swap PState, and output buffer segs.
	mov	dx,es
	mov	ds,dx
	mov	es,ax
        call    PrSendOutputBuffer
        jc      exitPop
	mov	ax,ds		;swap PState, and output buffer segs back.
	mov	dx,es
	mov	ds,dx
	mov	es,ax
bufferNotFull:

                ; advance the scanline start position one byte to get to next
                ; set of 8 pixels in the buffer

	pop	si			;get back, and adjust scan line start
        inc     si

        dec     bx  		       ; any more bytes in the row?
        jnz     groupLoop
	or	di,di			;see if there is any spare data left in
	jz	exit			;if not, just exit.
	mov	ax,ds		;swap PState, and output buffer segs.
	mov	dx,es
	mov	ds,dx
	mov	es,ax
	call	PrSendOutputBuffer	;flush out the partial buffer.
exit:
	.leave
	ret

exitPop:
	pop	si		;dummy pop from inside grouploop
	jmp	exit

PrRotate8LinesEvenColumns	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrRotate8LinesOddColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	Internal

PASS:
	bx	=	byte width of live print area
	es	=	segment address of PState

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrRotate8LinesOddColumns	proc	near
	uses	ax,bx,cx,dx,ds,di,si,es,bp
	.enter
	mov	bp,es:[PS_bandBWidth]	;width of bitmap
	mov	si,offset GPB_bandBuffer ;source of data.
	segmov	ds,es,ax	;save the PState segment in ds.
        mov     es,es:[PS_bufSeg]       ;get segment of output buffer.
        mov     di, offset GPB_outputBuffer ;output buffer

groupLoop:
	push	si		;save the scan line start position
	mov	ah,8		;do 8 bits in one byte.
byteloop:
	mov	al,es:[si]	;get the byte for this shift
	shr	al		;store the bits into 4 target regs.
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
	add	si,bp		;add for the next byte down vertically.
	dec	ah		;adjust the loop counter.
	jnz	byteloop

	clr	al		;store the target regs into the outputBuffer
	mov	ah,cl
	stosw			;di should be correct, and is adjusted here.
	mov	ah,ch
	stosw
	mov	ah,dl
	stosw
	mov	ah,dh
	stosw

	cmp	di,PRINT_OUTPUT_BUFFER_SIZE
        jb      bufferNotFull

	mov	ax,ds		;swap PState, and output buffer segs.
	mov	dx,es
	mov	ds,dx
	mov	es,ax
        call    PrSendOutputBuffer
        jc      exitPop
	mov	ax,ds		;swap PState, and output buffer segs back.
	mov	dx,es
	mov	ds,dx
	mov	es,ax
bufferNotFull:

                ; advance the scanline start position one byte to get to next
                ; set of 8 pixels in the buffer

	pop	si			;get back, and adjust scan line start
        inc     si

        dec     bx  		       ; any more bytes in the row?
        jnz     groupLoop
	or	di,di			;see if there is any spare data left in
	jz	exit			;if not, just exit.
	mov	ax,ds		;swap PState, and output buffer segs.
	mov	dx,es
	mov	ds,dx
	mov	es,ax
	call	PrSendOutputBuffer	;flush out the partial buffer.
exit:
	.leave
	ret

exitPop:
	pop	si		;dummy pop from inside grouploop
	jmp	exit
PrRotate8LinesOddColumns	endp
