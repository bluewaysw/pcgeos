COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		VidMem/Clr2
FILE:		clr2Output.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	

	$Id: clr2Output.asm,v 1.1 97/04/18 11:43:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawOptRect

DESCRIPTION:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	dx - number of words covered by rectangle + 1
	zero flag - set if rect is one word wide
	cx - pattern index (scan line number AND 7)
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 8) * 2
	bx - (right x position MOD 8) * 2

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
------------------------------------------------------------------------------@

DrawOptRect	proc	near

	tst	dx
	jz	OptRectOneWord

	; calculate # of words in the middle of the line, offset to next line

	dec	dx				;number of middle words

	; compute left masks.  The table is much smaller, since we can only
	; fit 4 pixels in two words, than the table for mono mode.  Shave off
	; a few more bits

	mov	ax,cs:[si][leftMaskTable]	;get mask
	mov	cs:[BOR_leftNewMask],ax
	not	ax
	mov	cs:[BOR_leftOldMask],ax

	; compute right masks

	mov	ax,cs:[bx][rightMaskTable]	;get mask
	mov	cs:[BOR_rightNewMask],ax
	not	ax
	mov	cs:[BOR_rightOldMask],ax

	mov	bx,cx				;pass pattern index in bx
	shl	bx, 1				; 2-word/scan
	and	bx, 6				; 4-word table

	GOTO	BlastOptRect

DrawOptRect	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OptRectOneWord

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	cx - pattern index (scan line number AND 7)
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 8) * 2
	bx - (right x position MOD 8) * 2

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
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
------------------------------------------------------------------------------@

OptRectOneWord	proc		near
	mov	ax,cs:[si][leftMaskTable]	;get mask
	and	ax,cs:[bx][rightMaskTable]	;composite mask
	mov	dx,ax				;dx = mask for new bits
	not	ax
	mov	bx,cx				;bx = pattern index
	shl	bx, 1				; 2-words/scan
	and	bx, 6				; 4-word dither matrix
	mov	cx,ax				;cx = mask for bits to save
	jmp	short OROW_loopEntry

OROW_loop:
	add	bx, 2				;inc pattern ptr to next scan
	and	bl, 6
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap >
MEM <	js	done				;  then bail		>

OROW_loopEntry:
	mov	ax, {word} cs:[bx][ditherMatrix] ;get dithered word
INV_CLR2 <	not	ax						>
	and	ax,dx				;ax = new data bits
	mov	si,es:[di]
	and	si,cx				;si = bits to save
	or	ax,si				;or in data bits
	mov	es:[di], ax

	dec	bp				;loop to do all lines
	jnz	OROW_loop
done::
	ret

OptRectOneWord	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	BlastOptRect

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	bx - index into pattern buffer (0-7)
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	dx - number of middle words
	BOR_leftNewMask - mask for bits to set on left
	BOR_leftOldMask - mask for bits to preserve on left
	BOR_rightNewMask - mask for bits to set on right
	BOR_rightOldMask - mask for bits to preserve on right
	BOR_nextScanOffset - Stored with StoreNextScanMod with
				SCREEN_BYTE_WIDTH - ( (# middle words) + 2) * 2

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
------------------------------------------------------------------------------@

BOR_loop:
	add	bx, 2			;increment pattern pointer to next scan
	and	bl,6
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap >
MEM <	js	BOR_done			;  then bail		>

BlastOptRect	proc		near
	push	di					
	
	mov	ax, {word} cs:[bx][ditherMatrix] ;get dithered word
INV_CLR2 <	not ax							>
	; handle left word specially

	mov	si,ax			; save pattern for later
BOR_leftNewMask	equ	(this word) + 1	
	and	ax,1234h		;modified

	mov	cx,es:[di]		;get word
BOR_leftOldMask	equ	(this word) + 2
	and	cx,1234h		;modified
	or	ax,cx
	stosw
	mov	ax,si

	; draw middle words

	mov	cx,dx			;# of words to store
	rep stosw

	; handle right word specially

BOR_rightNewMask	equ (this word) + 1
	and	ax,1234h		;modified
	mov	cx,es:[di]		;get word
BOR_rightOldMask	equ	(this word) + 2
	and	cx,1234h		;modified
	or	ax,cx
	stosw

	pop	di			; restore start of scan
	dec	bp			;loop to do all lines
	jnz	BOR_loop
MEM <BOR_done label near						>
	ret

BlastOptRect	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawNOTRect

DESCRIPTION:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	dx - number of words covered by rectangle + 1
	zero flag - set if rect is one word wide
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 8) * 2
	bx - (right x position MOD 8) * 2

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
------------------------------------------------------------------------------@

DrawNOTRect	proc		near
	tst	dx
	jz	NOTRectOneWord

	; calculate # of words in the middle of the line, offset to next line

	dec	dx				;number of middle words

	; compute right masks

	mov	ax,cs:[bx][rightMaskTable]	;get mask
	not	ax
	mov	cs:[BNR_rightMask],ax

	; compute left masks

	mov	ax,cs:[si][leftMaskTable]	;get mask
	not	ax
	mov	bx,ax

	GOTO	 BlastNOTRect

DrawNOTRect	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NOTRectOneWord

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 8) * 2
	bx - (right x position MOD 8) * 2

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
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
------------------------------------------------------------------------------@

NOTRectOneWord	proc		near
	mov	ax,cs:[si][leftMaskTable]	;get mask
	and	ax,cs:[bx][rightMaskTable]	;compisite mask
	not	ax
	mov	dx,ax				;dx = mask for bits to preserve
	mov	cx,bp				; we can use cx for loop count
	jmp	short NROW_loopEntry

NROW_loop:
	NextScan	di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap >
MEM <	js	done				;  then bail		>

NROW_loopEntry:
	mov	ax,es:[di]
	not	ax
	xor	ax,dx
	mov	es:[di], ax

	loop	NROW_loop
done::
	ret

NOTRectOneWord	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	BlastNOTRect

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	dx - number of middle words
	bx - mask for bits to preserve on left
	BNR_rightMask - mask for bits to preserve on right
	BNR_nextScanOffset - Stored with StoreNextScanMod with
				SCREEN_BYTE_WIDTH - ( (# middle words) + 2) * 2

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
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
------------------------------------------------------------------------------@

BNR_loop:
	NextScan	di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap >
MEM <	js	BNR_done			;  then bail		>

BlastNOTRect	proc		near

	; handle left word specially

	push	di
	mov	ax,es:[di]		;get word
	not	ax
	xor	ax,bx
	stosw

	; draw middle words

	mov	cx,dx			;# of words to store
	jcxz	BNR_noMiddle
BNR_middle:
	mov	ax,es:[di]
	not	ax
	stosw
	loop	BNR_middle
BNR_noMiddle:

	; handle right word specially

	mov	ax,es:[di]		;get word
	not	ax
BNR_rightMask	equ	(this word) + 1
	xor	ax,1234h		;modified
	stosw

	pop	di
	dec	bp			;loop to do all lines
	jnz	BNR_loop
MEM <BNR_done label near						>
	ret

BlastNOTRect	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawSpecialRect

DESCRIPTION:	Draw a rectangle with a special draw mask or draw mode clipping
		left and right

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	dx - number of words covered by rectangle + 1
	zero flag - set if rect is one word wide
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 8) * 2
	bx - (right x position MOD 8) * 2

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	02/89		Modified to do map mode right
------------------------------------------------------------------------------@

DrawSpecialRect	proc		near
	tst	dx
	jz	SpecialOneWord

	; calculate # of words in the middle of the line, offset to next line

	dec	dx				;number of middle words
	mov	cs:[BSR_middleCount], dx	;save parameter

	; compute left masks

	mov	ax, cs:[si][leftMaskTable]	;get mask
	mov	cs:[BSR_leftNewMask], ax

	; compute right masks

	mov	ax, cs:[bx][rightMaskTable]	;get mask
	mov	cs:[BSR_rightNewMask], ax

	mov	bx, cx				;pass pattern index in bx
	shl	bx, 1				; 1-word scan lines
	and	bx, 6				; only 4 scans
	jmp	BlastSpecialRect

DrawSpecialRect	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecialOneWord

DESCRIPTION:	Draw an unclipped rectangle in the any draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 8) * 2
	bx - (right x position MOD 8) * 2
	maskBuffer - draw mask to use
	wDrawMode - drawing mode to use

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
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
	Jim	02/89		Modified to do map mode stuff right
------------------------------------------------------------------------------@

SpecialOneWord	proc		near
	mov	ax, cs:[si][leftMaskTable]	; get mask
	and	ax, cs:[bx][rightMaskTable]	; composite mask
	mov	cs:[SOW_newBits],ax
	mov	bx, cx				; bx = pattern index
	shl	bx, 1				; 1-word/scan
   	and	bx, 6				; 4 scans
	jmp	short SOW_loopEntry

SOW_loop:
	add	bx, 2				; increment pattern pointer
	and	bl, 6
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap >
MEM <	js	done				;  then bail		>

SOW_loopEntry:
	mov	ax, {word} cs:[bx][ditherMatrix]; get dithered word
	mov	dx, {word} cs:[bx][maskBuff2]	; get draw mask byte
	mov	si, ax				; si = pattern bits
SOW_newBits	equ	(this word) + 2
	and	dx, 1234h			; apply left/right masks
	mov	ax, es:[di]			; ax = screen
	call	cs:[modeRoutine]		; ax = word to write
	mov	es:[di], ax

	dec	bp				; loop to do all lines
	jnz	SOW_loop
done::
	ret
SpecialOneWord	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	BlastSpecialRect

DESCRIPTION:	Draw an unclipped rectangle in the any draw mode

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	bx - index into pattern buffer (0-7)
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	BSR_leftNewMask - mask for bits to set on left
	BSR_rightNewMask - mask for bits to set on right
	BSR_middleCount - number of full words in middle of rectangle
	BSR_nextScanOffset - Stored with StoreNextScanMod with
				SCREEN_BYTE_WIDTH - ( (# middle words) + 2) * 2

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
	Jim	02/89		Modified to do map mode right
------------------------------------------------------------------------------@

BSR_loop:
	add	bx, 2			;increment pattern pointer
	and	bl, 6
	NextScan	di
MEM <	tst	cs:[bm_scansNext]		; if off end of bitmap >
MEM <	LONG js	BSR_done			;  then bail		>

BlastSpecialRect	proc		near
	push	di
	mov	ax, {word} cs:[bx][ditherMatrix]; get dithered word
	mov	dx, {word} cs:[bx][maskBuff2]	; get draw mask byte
	mov	si, ax				; si = pattern bits

	; handle left word specially

BSR_leftNewMask	equ	(this word) + 2
	and	dx,1234h			; apply left-side mask
	mov	ax, es:[di]			; ax = screen
	call	cs:[modeRoutine]		; ax = word to write
	stosw

	; draw middle words

	push	bp
BSR_middleCount	equ	(this word) + 1
	mov	bp, 1234h			; # words to store -- modified
	tst	bp
	jz	BSR_noMiddle
BSR_midLoop:
	mov	ax, es:[di]			; ax = screen
	mov	dx, {word} cs:[bx][maskBuff2]
	call	cs:[modeRoutine]		; ax = word to write
	stosw
	dec	bp
	jnz	BSR_midLoop
BSR_noMiddle:
	pop	bp

	; handle right word specially

	mov	ax, es:[di]			; ax = screen
	mov	dx, {word} cs:[bx][maskBuff2]
BSR_rightNewMask	equ	(this word) + 2
	and	dx, 1234h			; apply right-side mask
	call	cs:[modeRoutine]		; ax = word to write
	stosw

	pop	di
	dec	bp			;loop to do all lines
	LONG jnz BSR_loop
MEM <BSR_done label near						>
	ret

BlastSpecialRect	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ModeCLEAR, ModeCOPY, ModeNOP, ModeAND, ModeINVERT, ModeXOR,
		ModeSET, ModeOR

DESCRIPTION:	Execute draw mode specific action

CALLED BY:	INTERNAL
		SpecialOneWord, BlastSpecialRect

PASS:
	si - pattern (data)
	ax - screen
	dx - new bits AND draw mask

	where:	new bits = bits to write out (as in bits from a
			   bitmap).  For objects like rectangles,
			   where newBits=all 1s, dx will hold the
			   mask only.  Also: this mask is a final
			   mask, including any user-specified draw
			   mask.

RETURN:
	ax - destination (word to write out)

DESTROYED:
	dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	02/89		Modified to do map mode right
------------------------------------------------------------------------------@

;	the comments below use the following conventions (remember 
;	boolean algebra?...)
;		AND	^
;		OR	v
;		NOT	~

ModeRoutines	proc		near
		ForceRef	ModeRoutines
ModeCLEAR	label	near				
	not	dx
INV_CLR2 <not	ax							>
	and	ax, dx
INV_CLR2 <not	ax							>
ModeNOP		label near
	ret

;-----------------

ModeCOPY	label  near	; (screen^~(data^mask))v(data^mask^pattern)
INV_CLR2 <not	ax							>
	not	dx
	and	ax, dx
	not	dx
	and	dx, si
	or	ax, dx
INV_CLR2 <not	ax							>
	ret

;-----------------

MA_orNotMask	word	

ModeAND		label  near	; (screen^((data^mask^pattern)v~(data^mask))
	not	dx
	mov	cs:[MA_orNotMask], dx
	not	dx
	and	dx, si
	or	dx, cs:[MA_orNotMask]
INV_CLR2 <not	ax							>
	and	ax, dx
INV_CLR2 <not	ax							>

	ret

;-----------------

;
; Since ~(~a XOR b) is the same as (a XOR b), we don't bother inverting
; AX in ModeINVERT & ModeXOR for inverse drivers.
;
ModeINVERT	label  near	; screenXOR(data^mask)
	xor	ax, dx
	ret

;-----------------

ModeXOR		label  near	; screenXOR(data^mask^pattern)

;	For the Responder (Simp4Bit) video driver, we need to mimic the
;	horrible, incorrect VGA behavior (black pixels are not affected by
;	XORing with gray), so we can do gray inversions in the help topics
;	screen without causing the text to be a weird color.

	and	dx, si


	xor	ax, dx
	ret


;-----------------

ModeSET		label  near			
				; (screen^~(data^mask))v(data^mask^setColor)
INV_CLR2 <not	ax							>
	or	ax, dx
INV_CLR2 <not	ax							>
	ret

;-----------------

ModeOR		label  near	; screen v (data^mask^pattern)
INV_CLR2 <not	ax							>
	and	dx, si
	or	ax, dx
INV_CLR2 <not	ax							>
	ret

ModeRoutines	endp
