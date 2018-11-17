COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		VGALike video drivers
FILE:		vgacomOutput.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
    INT OptRectOneWord		Draw a rectangle that fits in a word and is
				unclipped, in DM_COPY draw mode
    INT DrawOptRect		Draw a rectangle with draw mode GR_COPY and
				all bits in the draw mask set
    INT BlastDitheredRect	Draw a dithered rectangle
    INT BlastDitheredScan	Draw one scan line of a dithered shape
    INT BlastOptRect		Draw an unclipped rectangle in the GR_COPY
				draw mode
    INT SpecialRectOneWord	Draw a rectangle that can fit in a byte
				horizontally, and uses the mask buffer.
    INT DrawSpecialRect		Draw a rectangle with draw mode GR_COPY and
				all bits in the draw mask set
    INT BlastSpecialRect	Draw an unclipped rectangle in the GR_COPY
				draw mode
    INT DrawSpecialRectDithered Draw a rectangle that is more than one byte
				wide, and is dithered in color
    INT MaskDitheredScan	Draw one scan line of a dithered shape

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	11/88	initial vga version
	Jim	12/91	added dithering support

DESCRIPTION:
	This is the source for the VGALike video driver output routines.  
		
	$Id: vgacomOutput.asm,v 1.1 97/04/18 11:42:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OptRectOneWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle that fits in a word and is unclipped, in
		DM_COPY draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:		es:di   - screen address for upper left corner of rectangle
		ds	- window segment
		bp	- number of scan lines to draw
		al	- left side mask
		ah	- right side mask
		cx	- scan line to start on

RETURN:		nothing	
DESTROYED:	just about everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/88		Initial vga version
	jim	12/16/91	Initial dithered version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OptRectOneWord	proc	near
		and	ah, al				; ah = mask
		mov	al, BITMASK			; set bitmask reg
		mov	dx, GR_CONTROL
		out	dx, ax				; set update mask
		test	cs:driverState, mask VS_DITHER	; need to dither ?
		jnz	ditherIt
		mov	cx, bp				; get loop count in cx
		
		; loop once for each scan line we have to do
writeLoop:
		or	es:[di], al			; read/write latches
		NextScan di				; to next scan line
		loop	writeLoop
		ret

		; special dithering version.  
		; basically, we do the whole thing 3 times, using the 
		; computed dither matrix and enabling one bit plane at a time
ditherIt:
		mov	si, cx				; get scan line in si
		StartVGADither 				; do some common setup
		mov	dx, GR_SEQUENCER		; setup right reg

		; plane zero is enabled, so whack out the blue plane 

		mov	cx, bp				; load loop count
ditherLoop:
		and	si, 3				; only need low 2 bits
		mov	ah, es:[di]			; load latches
		mov	ax, MAP_MASK_0			; enable blue plane
		out	dx, ax
		mov	al, cs:[ditherMatrix][si]	; get blue plane 
		mov	es:[di], al			; write data
		mov	ax, MAP_MASK_1			; enable green plane
		out	dx, ax
		mov	al, cs:[ditherMatrix+4][si]	; get green plane 
		mov	es:[di], al			; write data
		mov	ax, MAP_MASK_2			; enable red plane
		out	dx, ax
		mov	al, cs:[ditherMatrix+8][si]	; get red plane 
		mov	es:[di], al			; write data
		mov	ax, MAP_MASK_3			; enable hilite plane
		out	dx, ax
		mov	al, cs:[ditherMatrix+12][si]	; get plane data
		mov	es:[di], al			; write data
		inc	si				; onto next dither byte
		NextScan di
		loop	ditherLoop

		FinishVGADither				; cleanup
		ret
OptRectOneWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOptRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		dx - number of bytes covered by rectangle + 1
		zero flag - set if rect is one byte wide
		cx - pattern index
		es:di - buffer address for first left:top of rectangle
		ds - Window structure
		bp - number of lines to draw
		al - left mask
		ah - right mask
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawOptRect	proc	near
	jz	OptRectOneWord
	mov	bx, ax				; pass masks

	; check the dither flag and do the right thing

	test	cs:[driverState], mask VS_DITHER
	jnz	BlastDitheredRect

	; calculate # of bytes in the middle of the line, offset to next line

	dec	dx				;number of middle bytes
	mov	cs:[BOR_middleCount],dx		;pass number of middle bytes

	neg	dx
	add	dx, BWID_SCR-1
	mov	cs:[BOR_nextScanOffset], dx

	mov	dx, GR_CONTROL			; set up control reg for ega
	mov	al, BITMASK

	GOTO	BlastOptRect

DrawOptRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastDitheredRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a dithered rectangle

CALLED BY:	DrawOptRect
PASS:		see above
RETURN:		nothing
DESTROYED:	most everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlastDitheredRect	proc	near

		; do a little bit of setup first

		mov	si, cx				; get scan line in si
		mov	cx, bp				; load loop count
		mov	cs:[BDS_left], al		; store masks
		mov	cs:[BDS_right], ah
		dec	dx				; calc
		mov	bp, dx				;   #middle bytes

		; basically, we do the whole thing 3 times, using the 
		; computed dither matrix and enabling one bit plane at a time

		StartVGADither 				; do some common setup

		; plane zero is enabled, so whack out the blue plane 

scanLoop:
		push	cx				; save loop count
		and	si, 3				; only need low 2 bits
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_0			; enable blue plane
		out	dx, ax
		mov	cl, cs:[ditherMatrix][si]
		call	BlastDitheredScan		; write plane zero
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_1			; enable green plane
		out	dx, ax
		mov	cl, cs:[ditherMatrix+4][si]	; get green plane 
		call	BlastDitheredScan		; write plane 
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_2			; enable red plane
		out	dx, ax
		mov	cl, cs:[ditherMatrix+8][si]	; get red plane 
		call	BlastDitheredScan
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_3			; enable hilite plane
		out	dx, ax
		mov	cl, cs:[ditherMatrix+12][si]	; get hilite plane 
		call	BlastDitheredScan
		inc	si				; onto next dither byte

		; bump pointer to next scan line

		NextScan di
		pop	cx				; restore loop count
		loop	scanLoop

		FinishVGADither				; cleanup
		ret
BlastDitheredRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastDitheredScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one scan line of a dithered shape

CALLED BY:	various drawing routines (BlastDitheredRect)
PASS:		cl	- dither data to repeat on line
		bp	- #middle bytes to do
		es:di	- points to starting byte in scan line to fill
		si	- scan line number, (at least low two bits)
		self mod values setup in this routine
		SetVGADither already invoked

RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlastDitheredScan	proc	near
		mov	bx, di				; save address pointer
		mov	dx, GR_CONTROL
		mov	al, BITMASK			; setup register offset
BDS_left	equ	(this byte) + 1
		mov	ah, 12h				; setup left mask
		out	dx, ax
		mov	ch, es:[di]			; load latches
		mov	es:[di], cl			; update left side
		inc	di
		mov	ah, 0xff
		out	dx, ax
		mov	ax, cx				; get byte to write
		mov	cx, bp				; load #bytes to write
		rep	stosb				; blast them
		mov	cx, ax				; still need the byte
		mov	al, BITMASK
BDS_right	equ	(this byte) + 1		
		mov	ah, 12h
		out	dx, ax
		mov	ch, es:[di]			; load latches
		mov	es:[di], cl			; update right byte
		mov	di, bx				; restore pointer
		ret
BlastDitheredScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastOptRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	
PASS:		es:di - buffer address for first left:top of rectangle
		ds - Window structure
		bp - number of lines to draw
		BOR_middleCount - number of middle words
		dx - GR_CONTROL
		bl - left mask
		bh - right mask
		BOR_nextScanOffset - offset to next scan line
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	REGISTER/STACK USAGE:
		ax = pattern word, word to store
		bx = pattern index
		cx = for left and right: (screen AND bits to save), 
		     for middle: counter
		si = temp for left (pattern word)
		dx = offset to next scan line
		es:di = screen buffer address
		bp = counter

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/88		Initial version
	jim	12/91		rewrote as part of dither additions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BlastOptRect	proc	near

	; handle left byte specially
scanLoop:
	mov	ah, bl
	out	dx, ax
	or	es:[di], al		; modify word
	inc	di

	; draw middle bytes

	mov	ah, 0ffh		; setup solid mask
	out	dx, ax			; write all bits
BOR_middleCount	= (this word) + 1
	mov	cx, 1234h		; MODIFIED
	rep	stosb			; store bytes

	; handle right word specially

	mov	ah, bh
	out	dx, ax
	or	es:[di], al		; modify word

BOR_nextScanOffset = (this word) + 2
	add	di, 1234h		; MODIFIED
	dec	bp
	jnz	scanLoop
	ret

BlastOptRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpecialRectOneWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle that can fit in a byte horizontally, and
		uses the mask buffer. 

CALLED BY:	higher level rectangle routines
		DrawSimpleRect

PASS:		cx	- scan line (to use for pattern index)
		es:di	- points into frame buffer to top byte in rectangle
		ds - Window structure
		bp - number of lines to draw
		al - left mask
		ah - right mask

RETURN:		nothing
DESTROYED:	most everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version (hercules)
	jim	11/88		vga version
	jim	12/17/91	rewrote, added dithered version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpecialRectOneWord	proc	near
		mov	bx, cx			; use bx as pattern index
		clr	bh
		and	ah, al
		mov	cs:[SROW_mask], ah	; setup mask
		jmp	$+2			; XXX: clear prefetch queue
						; so we don't get greebles
						; on a 486. this could
						; probably be done a little
						; better, like inverting the
						; jnz below -- ardeb
		mov	al, BITMASK		; set bitmask reg
		mov	dx, GR_CONTROL
		mov	cx, bp			; setup loop count
		
		; need a different version if we're dithering colors

		test	cs:[driverState], mask VS_DITHER 
		jnz	ditherIt

		; loop for each scan line
SROW_loop:
		and	bx, 7
		mov	ah, {byte} cs:[bx][maskBuffer]	; get pattern byte
SROW_mask equ (this byte) + 2
		and	ah, 12h			; and in mask
		out	dx, ax			; set update mask
		or	es:[di], al
		inc	bx		
		NextScan di
		loop	SROW_loop
		ret

		; version to do dithering
ditherIt:
		mov	cs:[SRD_mask], ah
		mov	si, bx				; get scan line in si
		StartVGADither 				; do some common setup

		; loop for each scan line, enabling one plane at a time

		mov	cx, bp				; load loop count
ditherLoop:
		and	si, 3				; only need low 2 bits
		and	bx, 7				; only need low 3 bits
		mov	ah, es:[di]			; load the latches
		mov	ah, {byte} cs:[maskBuffer][bx]	; get mask byte
SRD_mask	equ	(this byte) + 2
		and	ah, 12h
		mov	dx, GR_CONTROL
		mov	al, BITMASK
		out	dx, ax
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_0			; enable blue plane
		out	dx, ax
		mov	al, cs:[ditherMatrix][si]	; get blue plane 
		mov	es:[di], al			; write data
		mov	ax, MAP_MASK_1			; enable green plane
		out	dx, ax
		mov	al, cs:[ditherMatrix+4][si]	; get green plane 
		mov	es:[di], al			; write data
		mov	ax, MAP_MASK_2			; enable red plane
		out	dx, ax
		mov	al, cs:[ditherMatrix+8][si]	; get red plane 
		mov	es:[di], al			; write data
		mov	ax, MAP_MASK_3			; enable hilite plane
		out	dx, ax
		mov	al, cs:[ditherMatrix+12][si]	; get hilite plane 
		mov	es:[di], al			; write data
		inc	si				; onto next dither byte
		inc	bx
		NextScan di
		loop	ditherLoop

		FinishVGADither 				; cleanup
		ret
SpecialRectOneWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpecialRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set
CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		dx - number of bytes covered by rectangle + 1
		zero flag - set if rect is one byte wide
		cx - pattern index
		es:di - buffer address for first left:top of rectangle
		ds - Window structure
		bp - number of lines to draw
		al - left mask
		ah - right mask
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawSpecialRect	proc	near
	LONG jz	SpecialRectOneWord
	mov	word ptr cs:[d_LRmasks], ax	; store masks

	; check the dither flag and do the right thing

	test	cs:[driverState], mask VS_DITHER
	jnz	DrawSpecialRectDithered

	; calculate # of bytes in the middle of the line, offset to next line

	dec	dx				;number of middle bytes
	mov	si,dx				;pass number of middle bytes

	neg	dx
	add	dx, BWID_SCR-2
	mov	cs:[BSR_nextScanOffset], dx

	mov	dx, GR_CONTROL			; set up control reg for ega
	mov	al, BITMASK
	mov	bx, cx				; bx = pattern index

	GOTO	BlastSpecialRect

DrawSpecialRect	endp
	public	DrawSpecialRect

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastSpecialRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		bx - index into pattern buffer (0-7)
		es:di - buffer address for first left:top of rectangle
		ds - Window structure
		bp - number of lines to draw
		si - number of middle words
		dx - GR_CONTROL
		BSR_nextScanOffset - offset to next scan line
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	REGISTER/STACK USAGE:
		ax = pattern word, word to store
		bx = pattern index
		cx = for left and right: (screen AND bits to save), 
		     for middle: counter
		dx = offset to next scan line
		es:di = screen buffer address
		bp = counter
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSR_loop:

	; update pattern pointer

	inc	bx
	and	bx, 7

	; move to next scan line

BSR_1	label	word
BSR_nextScanOffset	=	BSR_1 + 2
	add	di, 1234h		;MODIFIED

BlastSpecialRect	proc	near

	; handle left byte specially
	mov	ah, cs:[d_leftMask]
	and	ah, {byte} cs:[maskBuffer][bx]	; and in pattern byte
	out	dx, ax
	or	es:[di], al		;modify word
	inc	di

	; draw middle bytes

	mov	cx,si

	jcxz	BSR_noMiddle
	mov	ah, {byte} cs:[maskBuffer][bx]	; and in pattern byte
	out	dx, ax
BSR_inner:
	or	es:[di], al
	inc	di
	loop	BSR_inner
BSR_noMiddle:

	; handle right word specially
	mov	ah, cs:[d_rightMask]
	and	ah, {byte} cs:[maskBuffer][bx]	; and in pattern byte
	out	dx, ax
	or	es:[di], al		;modify word
	inc	di

	dec	bp			;loop to do all lines
	jnz	BSR_loop

	ret

BlastSpecialRect	endp
	public	BlastSpecialRect

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpecialRectDithered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle that is more than one byte wide, and is
		dithered in color

CALLED BY:	DrawSpecialRect

PASS:		al, ah		- left/right masks for the line
		cx		- scan line (top)
		bp		- #lines to draw
		es:di		- points to upper left part of rect in frame
				  buffer
		ds		- window segment
RETURN:		nothing
DESTROYED:	most everyting

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSpecialRectDithered	proc	near

		; do a little bit of setup first

		mov	si, cx				; get scan line in si
		mov	bx, cx
		clr	bh
		mov	cx, bp				; load loop count
		mov	cs:[MDS_left], al		; store masks
		mov	cs:[MDS_right], ah
		dec	dx				; calc
		mov	bp, dx				;   #middle bytes

		; basically, we do the whole thing 3 times, using the 
		; computed dither matrix and enabling one bit plane at a time

		StartVGADither 				; do some common setup

		; plane zero is enabled, so whack out the blue plane 

scanLoop:
		push	cx, bx				; save loop count
		and	bx, 7
		mov	ch, {byte} cs:[maskBuffer][bx]	; mask for scan line
		and	si, 3				; only need low 2 bits
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_0			; enable blue plane
		out	dx, ax
		mov	cl, cs:[ditherMatrix][si]
		call	MaskDitheredScan		; write plane zero
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_1			; enable green plane
		out	dx, ax
		mov	cl, cs:[ditherMatrix+4][si]	; get green plane 
		call	MaskDitheredScan		; write plane 
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_2			; enable green plane
		out	dx, ax
		mov	cl, cs:[ditherMatrix+8][si]	; get red plane 
		call	MaskDitheredScan
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_3			; enable hilite plane
		out	dx, ax
		mov	cl, cs:[ditherMatrix+12][si]	; get hilite plane 
		call	MaskDitheredScan
		inc	si				; onto next dither byte

		; bump pointer to next scan line

		NextScan di
		pop	cx, bx				; restore loop count
		inc	bx
		loop	scanLoop

		FinishVGADither 			; cleanup
		ret
DrawSpecialRectDithered	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaskDitheredScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one scan line of a dithered shape

CALLED BY:	various drawing routines (BlastDitheredRect)
PASS:		cl	- dither data to repeat on line
		ch	- mask for scan line
		bp	- #middle bytes to do
		es:di	- points to starting byte in scan line to fill
		si	- scan line number, (at least low two bits)
		self mod values setup in this routine
		SetVGADither already invoked

RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MaskDitheredScan	proc	near
		mov	bx, di				; save address pointer
		mov	dx, GR_CONTROL
		mov	al, BITMASK			; setup register offset
MDS_left	equ	(this byte) + 1
		mov	ah, 12h				; setup left mask
		and	ah, ch				; combine a mask byte
		out	dx, ax
		mov	ah, es:[di]			; load latches
		mov	es:[di], cl			; update left side
		inc	di
		mov	ah, ch				; combine a mask byte
		out	dx, ax
		mov	ax, cx				; get byte to write

		; do the middle bytes

		mov	cx, bp				; load #bytes to write
		jcxz	middleDone			; skip if none to do
middleBytes:
		mov	dh, es:[di]			; load latches
		mov	es:[di], al			; blast them
		inc	di
		loop	middleBytes

		; do the right byte
middleDone:
		mov	cx, ax				; still need the byte
		mov	dx, GR_CONTROL
		mov	al, BITMASK
MDS_right	equ	(this byte) + 2		
		and	ah, 12h
		out	dx, ax
		mov	al, es:[di]			; load latches
		mov	es:[di], cl			; update right byte
		mov	di, bx				; restore pointer
		ret
MaskDitheredScan	endp


