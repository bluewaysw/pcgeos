

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferScanBandNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	12/94	initial version

DESCRIPTION:

	$Id: bufferScanBandNike.asm,v 1.1 97/04/18 11:50:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrScanBandBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the screen (band Buffer) to find out how wide to print.
		Scan for the leading and trailing zero bytes

CALLED BY:	
	PrPrintABand

PASS:	
		es	=	PSTATE segment

RETURN:	
		ax	=	starting column number
		cx	=	ending column number
		dx	=	number of columns that we are going to print.
		bx	=	number of bytes wide to print.

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrScanBandBuffer	proc	near
	uses	es,di,si
blankLeft	local	word
liveWidth	local	word
	.enter
	;GENERAL INIT
	;some registers mean certain things all the way through the scan
	;process. They are:
	;ax - 0 for scan compare
	;bx - byte width of input buffer
	;si - index to start the next scan from

	mov	cx,es:PS_buffHeight	;number of scanlines to check
        mov     bx,es:PS_bandBWidth ;get the width of the screen input buffer.
	mov	blankLeft,bx		;init the blank byte counts
        mov     es,es:[PS_bufSeg]	;buffer segment for scan string
        clr     dx              ;start with zero width.
	mov	liveWidth,dx
	mov	si, (offset GPB_bandBuffer)-1 ;si is the index to pass di 


scanNextLine:
	;FRONT HALF INIT
	clr	ax
	inc	si			;add to get to even scanline start
	cld				;direction = forward
	push	cx			;save the scanline number
	mov	cx,bx			;cx now used for byte limit count
	;FRONT HALF SCAN
	mov	di,si
	repe	scasb		;see if this byte is blank (nothing to print).

	jz	forLastByteOK	;if last byte was blank, skip.
	inc	cx

forLastByteOK:
	;FRONT HALF BYTE CALCULATION
	mov	ax,cx			;make cx be the number of zero bytes
	mov	cx,bx
	sub	cx,ax			;by subtracting the count left from
					;the byte width
	cmp	cx,blankLeft		;see if the number of 0s went down
	jnc	blankLineTest		;if not, skip...
	mov	blankLeft,cx

blankLineTest:
	;TEST FOR A WHOLE SCANLINE OF ZERO BYTES: if there is nothing here,
	;do not test for the right half, just go to the next scanline.
	cmp	cx,bx			;bx is PS_bandBWidth
	pop	cx			;recover the scanline number
	jc	livePrintInit		;C flag intact from above cmp.
                ;get the start of buffer.
                ;adjust to point at end of "previous line".
		;just like the routine below would
        add     si,bx
	dec	si 
	jmp	doneWithScanline	;C flag intact from above cmp.

livePrintInit:
	;LIVE PRINT AREA INIT
	clr	ax
                ;get the start of buffer.
                ;adjust to point at end of "previous line".
        add     si,bx
	dec	si 
	cmp	bx,liveWidth	;are the live width and byte width = ?
	je	doneWithScanline ;if so, then the right half does not need to
				; be checked

	std                     ;set the direction flag to decrement..

	push	cx			;save the scanline number
	mov	cx,bx		;get the width of the screen input buffer.
	mov	di,si		;load index

	;LIVE PRINT AREA SCAN
	repe	scasb		;see if this byte is blank (nothing to print).

	jz	widthLastByteOK	;if last byte was blank, skip.
	inc	cx
widthLastByteOK:

	cmp	liveWidth,cx	;see if cx is less than liveWidth
	jnc	afterWidthStore	;if so, skip.
	mov	liveWidth,cx	;load dx with new width.
afterWidthStore:
	pop	cx		;get back the loop counter.

doneWithScanline:

	loop	scanNextLine
	
	;CALCULATE EXIT PARAMETERS
	;pass out:
	;	ax	=	starting column number
	;	cx	=	ending column number
	;	dx	=	number of columns that we are going to print.
	;	bx	=	number of bytes wide to print.

	mov	bx,liveWidth	;
	tst	bx		;see if there is anything to print
	jnz	setParameters
	mov	ax,bx
	mov	dx,bx
	mov	cx,bx
	jmp	exit

setParameters:
	mov	ax,blankLeft
	sub	bx,ax		;bx now bytes wide to print
	mov	dx,bx
	mov	cx,3		;shift everything by 3 (multiply x 8)
	shl	dx,cl		;dx is now the columns wide
	shl	ax,cl 		;ax is now the starting column
	mov	cx,liveWidth
	shl	cx,1
	shl	cx,1
	shl	cx,1
	dec	cx		;cx is now the ending column number
	mov	es:GPB_bytesWide,bx	;save the number of byte wide.
	mov	es:GPB_columnsWide,dx	;save the number of columns.
	mov	es:GPB_startColumn,ax	;save the start column number.
	mov	es:GPB_endColumn,cx	;pass out the end column number.

exit:
	clc
	cld
	.leave
	ret



if 0
----------------------------------------------------------------------------
	mov	cx,es:[PS_buffHeight] ;height of the band buffer.
	mov	bx,es:PS_bandBWidth ;get the width of the screen input buffer.
	mov	es,es:[PS_bufSeg]
	std			;set the direction flag to decrement..
	clr	al		;clear al (check for zero bytes).
	clr	dx		;start with zero width.

		;get the start of buffer.
		;adjust to point at end of "previous line".
	mov	si, (offset GPB_bandBuffer)-1

		;loop once/scanline.

DoScanLine:
	push	cx		;save cx loop counter
	mov	di,si		;save index, because scas screws it up.
	mov	cx,bx		;get the width of the screen input buffer.
	add	di,cx		;add to the reference start of line.

	;check a byte.
	repe	scasb		;see if this byte is blank (nothing to print).

	jz	LastByteOK	;if last byte was blank, skip.
	inc	cx
LastByteOK:
	cmp	dx,cx		;see if cx is less than dx
	jnc	NewWidth	;if so, skip.
	mov	dx,cx		;load dx with new width.
NewWidth:
	pop	cx		;get back the loop counter.
	cmp	dx,bx		;see if the width is the max already.
	je	FinalWidth	;if so, no need to check any more.
	add	si,bx		;add the byte band width for next time.
	loop	DoScanLine	;do for all lines.

	mov	bx,dx		;pass the number of bytes wide also.
FinalWidth:
	cld			;clear the direction flag.
	or	dx,dx		; see if clear (no width)
	jz	exit
;This half does the leading zero byte check.
	;bx is the byte width from above.
	dec	dx
	mov	es:GPB_endColumn,dx	;save for later.
	mov	cx,NIKE_BUFF_HEIGHT
	clr	al
	clr	dx		;set up for new width
	mov	si,offset GPB_bandBuffer ;new index to start of buffer.
doFrontScanline:
	push	cx		;save cx loop counter
	mov	di,si		;save index, because scas screws it up.
	mov	cx,bx		;new byte width.
	
	;check a byte.
	repe	scasb		;see if the byte is zero.

	jz	lastFrontByteOK	;if last byte was blank, skip.
	inc	cx

lastFrontByteOK:
	cmp	dx,cx		;see if the new width is more than old.
	jnc	newFrontWidth
	mov	dx,cx

newFrontWidth:
	pop	cx		;recover the width count.
	cmp	dx,bx		;see if we are maxed out.
	je	finalTotalWidth
	add	si,bx		;add the byte width from above to get to the
				;next scanline
	loop	doFrontScanline

finalTotalWidth:
	mov	ax,bx		;save the previous width.
	mov	bx,dx		;save the current width.
	sub	ax,bx		;difference is clear bytes in front.
	mov	cl,3
	sal	ax,cl		;x 8 = columns
;loaded already for exit in ax	mov	bufferStartColumn,ax

converToColumns:
	mov	cl,3		;multiply number of bytes by 8
	sal	dx,cl		; to get number of columns.
	
	mov	es:GPB_bytesWide,bx	;save the number of byte wide.
	mov	es:GPB_columnsWide,dx	;save the number of columns.
	mov	es:GPB_startColumn,ax	;save the start column number.
	mov	cx,es:GPB_endColumn	;pass out the end column number.

exit:
	.leave
	ret
endif
PrScanBandBuffer	endp
