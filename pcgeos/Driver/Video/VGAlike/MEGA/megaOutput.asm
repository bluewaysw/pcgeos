COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		MEGA video driver
FILE:		megaOutput.asm

AUTHOR:		Jim DeFrisco, Jeremy Dashe

ROUTINES:
	Name		Description
	----		-----------
    GBL	VidDrawRect	draw a filled rectangle
	
REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	4/88	initial version
	Tony	11/88	converted from Bitmap
	jeremy	4/91	monochrome support


DESCRIPTION:
	This is the source for the MEGA screen driver output routines.  
	This file is included in the file Kernel/Screen/mega.asm
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/usr/pcgeos/Spec/video.doc).  

	$Id: megaOutput.asm,v 1.1 97/04/18 11:42:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

COMMENT @-----------------------------------------------------------------------

FUNCTION:	OptRectOneWord

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	al - left mask
	ah - right mask

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	dx = EGA output register
	al = EGA bitmask register index
	ah = pattern byte, byte to store
	bx = pattern index
	cx = mask for bits to save
	dx = mask for new bits
	si = temp (screen AND bits to save)
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

OptRectOneWord	proc	near
	xchg	bx, cx			; bx <- index to pattern
	mov	cx, ax			; save masks
	and	ch, cl			; ch = mask of rectangle
	mov	dx, GR_CONTROL

	jmp	short OROW_loopEntry

OROW_loop:
	add	di, BWID_SCR
	inc	bx			; bx <- new pattern index
	and	bx, 7

OROW_loopEntry:
	SetMEGAColor

	mov	ah, cs:[bx][ditherMatrix]
	and	ah, ch			; ah <- white's pattern mask
	mov	al, BITMASK		; set bitmask reg
	out	dx, ax
	or	es:[di], al		; paint the white pixels

	ClearMEGAColor

	mov	ah, cs:[bx][ditherMatrix]
	not	ah
	and	ah, ch			; ah <- black's pattern mask
	mov	al, BITMASK		; set bitmask reg
	out	dx, ax
	or	es:[di], al		; paint the black pixels

	dec	bp				;loop to do all lines
	jnz	OROW_loop

	ret

OptRectOneWord	endp
	public	OptRectOneWord

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DrawOptRect

DESCRIPTION:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	dx - number of bytes covered by rectangle + 1
	zero flag - set if rect is one byte wide
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	al - left mask
	ah - right mask

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

DrawOptRect	proc	near
	jz	OptRectOneWord
	mov	bx, ax				; pass masks

	; calculate # of bytes in the middle of the line, offset to next line

	dec	dx				;number of middle bytes
	mov	cs:[BOR_middleCount],dx		;pass number of middle bytes

	neg	dx
	add	dx, BWID_SCR-1
	mov	cs:[BOR_nextScanOffset], dx

	mov	dx, GR_CONTROL			; set up control reg for ega
	mov	al, BITMASK

	mov	si, cx
	GOTO	BlastOptRect

DrawOptRect	endp
	public	DrawOptRect

COMMENT @-----------------------------------------------------------------------

FUNCTION:	BlastOptRect

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	BOR_middleCount - number of middle words
	dx - GR_CONTROL
	bl - left mask
	bh - right mask
	BOR_nextScanOffset - offset to next scan line

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
	bx = pattern index
	cx = for left and right: (screen AND bits to save), for middle: counter
	si = temp for left (pattern word)
	dx = offset to next scan line
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

BOR_loop:

	; move to next scan line

BOR_1	label	word
BOR_nextScanOffset	=	BOR_1 + 2
	add	di, 1234h		;MODIFIED
	inc	si

BlastOptRect	proc	near
	; figure out index to pattern mask for this scan line
	and	si, 7			;

	; Set draw color:
	SetMEGAColor

	; handle left byte specially

	mov	ah, bl
	and	ah, cs:[si][ditherMatrix]	;
	mov	al, BITMASK
	out	dx, ax
	or	es:[di], al		;modify word

	; Reset draw color:
	ClearMEGAColor

	mov	ah, cs:[si][ditherMatrix]
	not	ah
	and	ah, bl 
	mov	al, BITMASK
	out	dx, ax
	or	es:[di], al		;modify word
	
	inc	di

	; draw middle bytes

BOR_2	label	word
BOR_middleCount	=	BOR_2 + 1
	mov	cx,1234h		;MODIFIED
	tst	cx
	jz	handleRightByte

	mov	al, BITMASK		; 
	mov	ah, cs:[si][ditherMatrix]
	tst	ah			; are we drawing just black?
	jz	doBlackWrite		; jump if so
	cmp	ah, 0xff		; are we drawing just white?
	je	doWhiteWrite		; jump if so

	; Mixed pattern: we need to read/write twice.
	out	dx, ax			;

	SetMEGAColor

	push	ds, si
	push	cx, di
	push	si
	segmov	ds, es, ax		;
	mov	si, di			; 
	rep	movsb			; blast out white pixels

	ClearMEGAColor

	pop	si
	mov	ah, cs:[si][ditherMatrix]
	not	ah			;
	mov	al, BITMASK		;
	out	dx, ax			;

	pop	cx, di			; blast out black pixels
	mov	si, di			; 
	rep	movsb			; blammo.
	pop	ds, si			;
	jmp	short handleRightByte	;

doBlackWrite:
	; The middle bytes are all the reset color.  Blast 'em.
	not	ah			;
	out	dx, ax			;

	ClearMEGAColor
	rep	stosb			;
	jmp	short handleRightByte	;

doWhiteWrite:
	; The middle bytes are all white.  Blast 'em.
	out	dx, ax			;
		
	SetMEGAColor
	rep	stosb			;
	; FALL THROUGH TO handleRightByte
	
handleRightByte:
; handle right byte specially
	; Set draw color:
	SetMEGAColor

	mov	ah, bh			; ah <- right word mask
	and	ah, cs:[si][ditherMatrix]
	mov	al, BITMASK
	out	dx, ax
	or	es:[di], al		;modify word

	; Reset draw color:
	ClearMEGAColor

	mov	ah, cs:[si][ditherMatrix]
	not	ah			;
	and	ah, bh			;
 	mov	al, BITMASK
	out	dx, ax
	or	es:[di], al		;modify word

	dec	bp			;loop to do all lines
	LONG jnz	BOR_loop

	ret

BlastOptRect	endp
	public	BlastOptRect

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpecialRectOneWord

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	al - left mask
	ah - right mask

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	dx = EGA output register
	al = EGA bitmask register index
	ah = pattern byte, byte to store
	bx = pattern index
	cx = mask for bits to save
	dx = mask for new bits
	si = temp (screen AND bits to save)
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

SpecialRectOneWord	proc	near
	mov	bx, cx				; use bx as pattern index
	and	al, ah
	mov	cl, al				; cl = mask
	; We have to figure out if the bits in the maskBuffer should be
	; drawn in black or white.
	mov	ah, 0xff			; assume white on black
	clr	al

	; If the mode is INVERT, the set color is "white," or set bits.
	cmp	cs:currentDrawMode, MM_INVERT
	je	setMaskColors

	; If the mode is XOR, the set color is "white," or set bits.
	cmp	cs:currentDrawMode, MM_XOR
	je	setMaskColors

	; If the mode is SET, the set color is "white," or set bits.
	cmp	cs:currentDrawMode, MM_SET
	je	setMaskColors

	; For other modes, set the draw color to the reverse
	; of the ditherMatrix.
	tst	cs:[ditherMatrix]		; draw in black?
	jnz	setMaskColors			; jump if not.
	not	ax				; else, yep, draw in black.

setMaskColors:	
	mov	cs:maskSetColor, ah
	mov	cs:maskResetColor, al
	mov	dx, GR_CONTROL
	jmp	short SROW_loopEntry

SROW_loop:
	inc	bl
	and	bl, 7
	add	di, BWID_SCR

SROW_loopEntry:
	clr	al				;
	mov	ah, cs:maskSetColor		; draw white pixels first
	out	dx, ax				;

	mov	al, BITMASK			; set bitmask reg
	mov	ah, {byte} cs:[bx][maskBuffer]	; get pattern byte
	and	ah,cl				; and in mask
	out	dx, ax				; set update mask
	or	es:[di], al

	dec	bp				;loop to do all lines
	jnz	SROW_loop

	ret

SpecialRectOneWord	endp
	public	SpecialRectOneWord

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DrawSpecialRect

DESCRIPTION:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	dx - number of bytes covered by rectangle + 1
	zero flag - set if rect is one byte wide
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	al - left mask
	ah - right mask

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

DrawSpecialRect	proc	near
	jz	SpecialRectOneWord
	mov	word ptr cs:[d_LRmasks], ax	; store masks

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

COMMENT @-----------------------------------------------------------------------

FUNCTION:	BlastSpecialRect

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	bx - index into pattern buffer (0-7)
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - number of middle words
	dx - GR_CONTROL
	BSR_nextScanOffset - offset to next scan line

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
	bx = pattern index
	cx = for left and right: (screen AND bits to save), for middle: counter
	dx = offset to next scan line
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@


BlastSpecialRect	proc	near
	; We have to figure out if the bits in the maskBuffer should be
	; drawn in black or white.
	mov	ah, 0xff			; assume white on black
	clr	al

	; If the mode is INVERT, the set color is "white," or set bits.
	cmp	cs:currentDrawMode, MM_INVERT
	je	setMaskColors

	; If the mode is XOR, the set color is "white," or set bits.
	cmp	cs:currentDrawMode, MM_XOR
	je	setMaskColors

	; If the mode is SET, the set color is "white," or set bits.
	cmp	cs:currentDrawMode, MM_SET
	je	setMaskColors

	; For other modes, set the draw color to the reverse
	; of the ditherMatrix.
	tst	cs:[ditherMatrix]		; draw in black?
	jnz	setMaskColors			; jump if not.
	not	ax				; else, yep, draw in black.

setMaskColors:	
	mov	cs:maskSetColor, ah
	mov	cs:maskResetColor, al
	jmp	short BlastSpecialRectEntry

BSR_loop:

	; update pattern pointer

	inc	bl
	and	bl, 7

	; move to next scan line

BSR_1	label	word
BSR_nextScanOffset	=	BSR_1 + 2
	add	di, 1234h		;MODIFIED

BlastSpecialRectEntry:
	; handle left byte specially
	clr	al
	mov	ah, cs:maskSetColor
	out	dx, ax

	mov	al, BITMASK
	mov	ah, {byte} cs:[bx][maskBuffer]	; use pattern byte
	and	ah, cs:[d_leftMask]
	out	dx, ax
	or	es:[di], al		;modify word

	inc	di

	; draw middle bytes

	mov	cx,si

	jcxz	BSR_noMiddle

BSR_inner:
	clr	al
	mov	ah, cs:maskSetColor
	out	dx, ax

	mov	al, BITMASK
	mov	ah, {byte} cs:[bx][maskBuffer]	 ; use pattern byte
	out	dx, ax
	or	es:[di], al

	inc	di
	loop	BSR_inner
BSR_noMiddle:

	; handle right word specially
	clr	al
	mov	ah, cs:maskSetColor
	out	dx, ax

	mov	al, BITMASK
	mov	ah, {byte} cs:[bx][maskBuffer]	; use pattern byte
	and	ah, cs:[d_rightMask]
	out	dx, ax
	or	es:[di], al		;modify word

	inc	di

	dec	bp			;loop to do all lines
	jnz	BSR_loop

	ret

BlastSpecialRect	endp
	public	BlastSpecialRect
