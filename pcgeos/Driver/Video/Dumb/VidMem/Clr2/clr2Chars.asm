COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		VidMem/Clr2
FILE:		clr2Chars.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	Low-level character drawing routines for 2-bit/pixel vidmem	

	$Id: clr2Chars.asm,v 1.1 97/04/18 11:43:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharXIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level routine to draw a character when the source is
		X bytes wide, the drawing mode in GR_COPY and the character 
		is entirely visible.

CALLED BY:	INTERNAL
		FastCharCommon
PASS:		ds:si - character data
		es:di - screen position
		bx - pattern index
		cl - shift count
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

char1Loop:
	add	bx, 2			;increment pattern pointer
	and	bl, 6
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; off end of bitmap ?		>
MEM <	js	C1_done							>

Char1In		proc		near
	push	di			; save offset into frame buffer
	clr	ah
	lodsb				; al = character data
	ror	ax, cl			; al = data shifted correctly, carry=of
	mov	dl, ah			; save overflow, if any
	mov	bp, {word} cs:[bx][ditherMatrix] ; ax = color dither
	call	DrawCharByte		; lay down a single byte

	; see if the high byte has anything in it.  We know it can only be
	; a single bit, since we only shifted by 1 (if any).

	tst	dl
	jnz	doExtraBit
end1Loop:
	pop	di
	dec	ch
	jnz	char1Loop
MEM <C1_done label	near						>
	pop	ax
	jmp	PSL_afterDraw


	; we shifted some out of the first byte, color an additional bit
doExtraBit:
	mov	al, dl				; grab overflow bits
	call	DrawCharByte			; draw them too
	jmp	end1Loop
Char1In	endp

	; utility routine used by character drawing code
	; bp = dither word
	; al = byte to draw
	; es:di -> screen location to start drawing
DrawCharByte	proc	near
INV_CLR2 <not bp						>
	push	dx
	call	BuildDataByte		; build out 2-byte buffer
	mov	ax, bp			; save for next word
	mov	dx, {word}cs:[dataBuff2]
	and	ax, dx			; ax = char data in color
	not	dx			; dx = NOT char data
	and	dx, es:[di]		; dx = screen and NOT char data
	or	ax, dx			; ax = data to store
	stosw
	pop	dx
INV_CLR2 <not bp						>
	ret
DrawCharByte	endp

;-------------------------------

char2Loop:
	add	bx, 2			;increment pattern pointer
	and	bl, 6
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; off end of bitmap ?		>
MEM <	js	C2_done							>

Char2In	proc		near
	push	di			; save scan line offset
	clr	ah
	lodsb				; ax = char data
	ror	ax, cl
	mov	dl, ah			; save overflow
	mov	bp, {word} cs:[bx][ditherMatrix] ; ax = color dither
	call	DrawCharByte
	clr	ah
	lodsb				; get second byte
	ror	ax, cl			; shift in next bits
	or	al, dl
	mov	dl, ah
	call	DrawCharByte

	; finally, check final overflow bits from rotate. 

	tst	dl			; restore overflow bit
	jnz	setExtraBit
end2Loop:
	pop	di
	dec	ch
	jnz	char2Loop
MEM <C2_done	label 	near						>
	pop	ax
	jmp	PSL_afterDraw


	; we have one more pixel to set.
setExtraBit:
	mov	al, dl				; grab overflow bits
	call	DrawCharByte			; draw them too
	jmp	end2Loop
Char2In	endp

;----------------------------------------

char3Loop:
	add	bx, 2			;increment pattern pointer
	and	bl, 6
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; off end of bitmap ?		>
MEM <	js	C3_done							>

Char3In	proc		near
	push	di			; save scan line offset
	clr	ah
	lodsb				; ax = char data
	ror	ax, cl
	mov	dl, ah			; save overflow
	mov	bp, {word} cs:[bx][ditherMatrix] ; ax = color dither
	call	DrawCharByte
	clr	ah
	lodsb				; get second byte
	ror	ax, cl			; rotate into position
	or	al, dl			; combine prev overflow
	mov	dl, ah			; save current overflow
	call	DrawCharByte
	clr	ah
	lodsb				; one more time
	ror	ax, cl
	or	al, dl
	mov	dl, ah
	call	DrawCharByte

	; check any final overflow

	tst	dl			; restore final overflow
	jnz	setExtraBit
end3Loop:
	pop	di
	dec	ch
	jnz	char3Loop
MEM <C3_done	label	near						>
	pop	ax
	jmp	PSL_afterDraw


	; we have one more pixel to set.
setExtraBit:
	mov	al, dl				; grab overflow bits
	call	DrawCharByte			; draw them too
	jmp	end3Loop
Char3In	endp

;-------------------------------

char4Loop:
	add	bx, 2			;increment pattern pointer
	and	bl, 6
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; off end of bitmap ?		>
MEM <	js	C4_done							>

Char4In	proc		near
	push	di			; save scan line offset
	clr	ah			; init overflow
	lodsb				; ax = char data
	ror	ax, cl
	mov	dl, ah			; save overflow bits
	mov	bp, {word} cs:[bx][ditherMatrix] ; ax = color dither
	call	DrawCharByte
	clr	ah
	lodsb				; do second byte
	ror	ax, cl
	or	al, dl			; combine prev overflow
	mov	dl, ah			; save new overflow
	call	DrawCharByte
	clr	ah			; do third byte
	lodsb
	ror	ax, cl
	or	al, dl
	mov	dl, ah
	call	DrawCharByte
	clr	ah			; finally, fourth
	lodsb
	ror	ax, cl
	or	al, dl
	mov	dl, ah
	call	DrawCharByte

	; check final shift out bits

	tst	dl			; restore final overflow
	jnz	setExtraBit
end4Loop:
	pop	di
	dec	ch
	jnz	char4Loop
MEM <C4_done	label	near						>
	pop	ax
	jmp	PSL_afterDraw


	; we have one more pixel to set.
setExtraBit:
	mov	al, dl				; grab overflow bits
	call	DrawCharByte			; draw them too
	jmp	end4Loop
Char4In	endp
