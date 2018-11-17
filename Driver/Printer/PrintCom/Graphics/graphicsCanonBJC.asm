COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Canon BJC Printer Driver
FILE:		graphicsCanonBJC.asm

AUTHOR:		Joon Song, Jan 11, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/11/99   	Initial revision


DESCRIPTION:
		
	

	$Id$

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

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version
	joon	1/11/99    	CanonBJ version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintSwath	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	.enter

	mov	es, bp			; es -> PState

		; load the bitmap header into the PState
	call	LoadSwathHeader		; bitmap header into PS_swath

		; load up the band width and height
	call	PrLoadPstateVars	; set up the pstate band Vars.

		; size and allocate a graphics data buffer
	call	PrCreatePrintBuffers	; allocate the print buffer.

		; get pointer to data
	call	DerefFirstScanline	; ds:si -> scan line zero

	mov	cx, es:[PS_swath].B_height
	jcxz	destroyBuffer

	mov	dl, es:[PS_printerType]
	andnf	dl, mask PT_COLOR
	cmp	dl, BMF_MONO
	je	monoLoop		; only print black if BMF_MONO

cmykLoop:
	clr	es:[PS_curColorNumber]	; print "Y"
	call	DerefAScanline
	call	PrPrintAScan
	jc	destroyBuffer		; exit with carry set

	inc	es:[PS_curColorNumber]	; print "C"
	call	DerefAScanline
	call	PrPrintAScan
	jc	destroyBuffer		; exit with carry set

	inc	es:[PS_curColorNumber]	; print "M"
	call	DerefAScanline
	call	PrPrintAScan
	jc	destroyBuffer		; exit with carry set

	inc	es:[PS_curColorNumber]	; print "K"
	call	DerefAScanline
	call	PrPrintAScan
	jc	destroyBuffer		; exit with carry set

	mov	dx, 1
	call	PrLineFeed		; skip to next line
	jc	destroyBuffer		; exit with carry set

	inc	es:[PS_newScanNumber]
	loop	cmykLoop
	jmp	destroyBuffer

monoLoop:
	mov	es:[PS_curColorNumber], 0	; print "K"
	call	DerefAScanline
	mov	es:[PS_curColorNumber], 3	; print "K"
	call	PrPrintAScan
	jc	destroyBuffer		; exit with carry set

	mov	dx, 1
	call	PrLineFeed		; skip to next line
	jc	destroyBuffer		; exit with carry set

	inc	es:[PS_newScanNumber]
	loop	monoLoop

		; all done, kill the buffer and leave
destroyBuffer:
	pushf
	call	PrDestroyPrintBuffers	;get rid of print buffer space.
	popf

	.leave
	ret
PrintSwath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintAScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a color scanline

CALLED BY:	PrintSwath
PASS:		es	= PState segment
		ds:si	= pointer to a scan line of bitmap data
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon   	1/11/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrPrintAScan	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; compact scanline data using PackBits

EC <	push	ax							>
EC <	mov	ax, cx							>
EC <	shr	ax, 1			; worst case is 133% expansion	>
EC <	add	ax, cx			; ...we'll test for 150%	>
	call	PrCompactScanline	; cx = compacted data size
EC <	cmp	cx, ax							>
EC <	ERROR_A	CANON_BJC_BAD_DATA_COMPACTION				>
EC <	pop	ax							>
	jcxz	done

	; write out code for sending bitmap data to printer

	mov     si, offset pr_codes_SetGraphics
	call    SendCodeOut		; write out code = C_ESC,"(A"
	jc	done

	mov	di, cx
	inc	cx			; add 1 for color byte
	call	PrintStreamWriteByte	; write low byte of data size
	jc	done
	mov	cl, ch
	call	PrintStreamWriteByte	; write high byte of data size
	jc	done

	mov	bx, es:[PS_curColorNumber]
	mov	cl, cs:[canonBJColorTable][bx]
	call	PrintStreamWriteByte	; write color byte
	jc	done

	push	ds
	mov	ds, es:[PS_bufSeg]
	mov	si, offset GPB_bandBuffer
	mov	cx, di
	call	PrintStreamWrite
	pop	ds
	jc	done

	mov	cl, C_CR		; send a carriage return.
	call	PrintStreamWriteByte
done:
	.leave
	ret
PrPrintAScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrCompactScanline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compact scanline using PackBits

CALLED BY:	PrPrintAScan
PASS:		es	= PState segment
		ds:si	= pointer to a scan line of the bitmap
RETURN:		cx	= size of compacted data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/12/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrCompactScanline	proc	near
	uses	ax,bx,dx,si,di,bp,es
	.enter

	; first check to see if there is anything to print for this scanline

EC <	tst	cx							>
EC <	ERROR_Z	CANON_BJC_UNEXPECTED_NULL_DATA_SIZE			>
	push	es
	mov	cx, es:[PS_bandBWidth]	; cx = number of bytes to check
	segmov	es, ds
	mov	di, si
	clr	ax
	repe	scasb
	pop	es
	LONG jz	done			; return with cx = 0 if all zeros

	; calculate the width of the scanline

	push	es
	mov	cx, es:[PS_bandBWidth]	; cx = number of bytes to check
	segmov	es, ds
	mov	di, si
	add	di, cx
	dec	di
	clr	ax
	std
	repe	scasb
	inc	cx
	cld
	pop	es

	; now do PackBits

	mov	es, es:[PS_bufSeg]
	mov	di, offset GPB_bandBuffer	; es:di = buffer

initPrev:
	dec	cx
	js	calcSize
	lodsb					; al = data byte
	mov	ah, al				; ah = prev byte
gotPrev:
	mov	bl, 1				; bl = count = 1
	mov	bp, di				; es:bp = count pointer
	inc	di				; leave space for count
	dec	cx
	js	finishDiff
	lodsb					; al = data byte
	cmp	ah, al				; compare curr with prev
	jne	diffLoop
sameLoop:
	inc	bl				; increment count
	cmp	bl, 0x80			; end repeat if max reached
	je	endSame
	dec	cx
	js	finishSame
	lodsb					; al = data byte
	cmp	ah, al				; compare curr with prev
	je	sameLoop			; continue loop if still same

	dec	bl
	neg	bl				; repeat counts are negative
	mov	es:[bp], bl			; write count
	xchg	ah, al				; ah = new prev data
	stosb					; write old prev data 
	jmp	gotPrev
endSame:
	dec	bl
	neg	bl				; repeat counts are negative
	mov	es:[bp], bl			; write count
	mov	al, ah
	stosb					; write data
	jmp	initPrev
finishSame:
	dec	bl
	neg	bl				; repeat counts are negative
	mov	es:[bp], bl			; write count
	mov	al, ah
	stosb					; write data
	jmp	calcSize

diffLoop:
	xchg	ah, al				; ah = new prev data
	stosb					; write old prev data
	inc	bl				; increment count
	cmp	bl, 0x80			; end literal if max reached
	je	endDiff
	dec	cx
	js	finishDiff
	lodsb					; al = data byte
	cmp	ah, al				; compare curr with prev
	jne	diffLoop			; continue loop if still diff

	sub	bl, 2				; decrement to make 0 based
	mov	es:[bp], bl			; write count
	mov	bp, di				; es:bp = next count pointer
	inc	di				; leave space for count
	mov	bl, 1				; increment count
	jmp	sameLoop
endDiff:
	dec	bl
	mov	es:[bp], bl			; write count
	mov	al, ah				; al = last diff byte
	stosb					; write last diff byte
	jmp	initPrev
finishDiff:
	dec	bl
	mov	es:[bp], bl
	mov	al, ah
	stosb

calcSize:
	sub	di, offset GPB_bandBuffer	; di = compressed data size
	mov	cx, di	
done:
	.leave
	ret
PrCompactScanline	endp
