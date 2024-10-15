COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb Frame buffer devices	
FILE:		dumbcomGenChar.asm

AUTHOR:		Jim DeFrisco, Jun  7, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/ 7/92		Initial revision


DESCRIPTION:
	These routines used to reside in vidcomChars.asm, but the amount
	of conditional code became excessive after the creation of color
	vidmem.  Hence the creation of this file.
		

	$Id: clr24GenChar.asm,v 1.1 97/04/18 11:43:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @----------------------------------------------------------------------

FUNCTION:	CharCommon

DESCRIPTION:	Pseudo-function for SWAT since these routines mess with
		the stack alot

------------------------------------------------------------------------------@
CharCommon	proc	near
		ForceRef CharCommon


COMMENT @----------------------------------------------------------------------

FUNCTION:	CharLowFast

DESCRIPTION:	Draw a character.  Character is not clipped on the top or
		bottom, W_clipRect.R_left & W_clipRect.R_right valid, GR_COPY
		drawing mode, no pointer collision, mask WGF_CLIP_SIMPLE set.
		textMode 0.

CALLED BY:	INTERNAL
		VidPutChar

PASS:
	ax - x position for character
	bx - y position for character
	dl - character to draw
	dh - previous character
	ds - font structure
	ditherMatrix - set for current color

RETURN:
	Pointer possibly hidden
	ax - next x position

DESTROYED:
	bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Depending on the clipping state, jump to either FastCharCommon or
	CharLowCheck.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	Gene	5/89		added checks for unbuilt characters

------------------------------------------------------------------------------@

;------------------------------
; special case: character is missing:
;		(0) doesn't exist	--> use default
;		(2) not built		--> call the font driver
CLF_charMissing:
	tst	si			;assumes (CHAR_NOT_EXIST == 0)
	je	CLF_useDefault		;branch if character doesn't exist
EC <	cmp		si, CHAR_NOT_BUILT	>
EC <	ERROR_NE	FONT_BAD_CHAR_FLAG	>;shouldn't ever happen
	call	VidBuildChar
	mov	ds, cs:[PSL_saveFont]	;ds <- seg addr of font
	jmp	short CLF_afterBuild

;------------------------------
; special case: use CharLowCheck

CLF_check:
	jmp	CharLowCheck		;

if DBCS_PCGEOS
;------------------------------
; special case: character is in different character set
CLF_beforeFirst:
	add	dx, ds:FB_firstChar
CLF_afterLast:
	call	CallLockCharSetDS
	jnc	CLF_afterDefault		;branch if character exists
endif
;------------------------------
; special case: use default character
;		the current character is beyond the set of characters defined
;		in this font.
CLF_useDefault:
SBCS <	mov	dl, ds:[FB_defaultChar]					>
DBCS <	mov	dx, ds:[FB_defaultChar]					>
	jmp	short CLF_afterDefault

;-----------------------------
; special case: kerning info to use

CLF_DoKern:
	segmov	es, ds				;es <- seg addr of font
	call	KernChar			;kern me jesus
	jmp	CLF_afterKern

;------------------------------
; special case: character clipped

CLF_noDrawDX:
	mov	ax,dx
	jmp	PSL_afterDraw

;------------------------------
; special case: complex clip
; -- see after FastCharCommon

;------------------------------
CharLowFastCh	label near
	mov	es,cs:[PSL_saveWindow]
	mov	di, es:W_clipRect.R_left    ;di <- left of clip region
CLFC_minLSB	equ  (this word) + 2
	sub	di, 1234h		    ;MODIFIED: minimum LSB for font
	cmp	ax, di			    ;see if left edge clipped
	jl	CLF_check		    ;special case: left edge clipped.
	mov	cs:[PSL_saveRoutine],CHAR_LOW_FAST

CharLowFast	label near
	;
	; check for undefined character, in which case use the default
	;
if DBCS_PCGEOS

CLF_afterDefault:
CLF_lastChar = (this word) + 2
	cmp	dx, 0x1234		    ;MODIFIED
	ja	CLF_afterLast
CLF_firstChar = (this word) + 2
	sub	dx, 0x1234		    ;MODIFIED
	jb	CLF_beforeFirst

else

CLF_lastChar	equ  (this byte) + 2
	cmp	dl,12h			    ; check against last character in
	ja	CLF_useDefault		    ; font, use default if beyond.
CLF_afterDefault:
CLF_firstChar	equ  (this byte) + 2
	sub	dl,12h			    ; Subtract from first to get offset
					    ; into the font for this character.
	jb	CLF_useDefault		    ; If char is below the first char

endif
					    ; defined for the font then use
					    ; the default character (the
					    ; useDefault code branches right
					    ; back here, but with a valid char
					    ; in dl).
CLF_afterBuild:
	; compute data pointer
SBCS <	clr	dh			    ; dx <- offset into font data. >
	mov	di,dx			    ; di <- offset * 8
	FDIndexCharTable di, si
	mov	si,ds:FB_charTable[di].CTE_dataOffset ;es:si <- data pointer
	cmp	si, CHAR_MISSING	    ;Check for missing character.
	jbe	CLF_charMissing		    ;Use default if missing.
	;
	; ds:di = index to CharTableEntry for character
	; compute next character x position
	;
CLF_kernOp equ (this byte) + 0
	jmp	CLF_DoKern		    ;MODIFIED (JMP or MOV DH,xxx)
CLF_afterKern:

					    ;ASSUMES CTE_width.WBF_int.high==0
	mov	dx, ax			    ;dx <- x position
	cmp	cs:fracPosition, 0x80
	jb	CLF_noRound
	inc	ax
CLF_noRound:
	mov	cl, ds:[di].FB_charTable.CTE_width.WBF_frac
	add	cs:fracPosition, cl	    ;keep frac position up to date.
	adc	dx, ds:[di].FB_charTable.CTE_width.WBF_int
	;
	; We also need to round the y position to an integer
	;
	cmp	cs:fracYPosition, 0x80
	jb	CLF_noRoundY
	inc	bx
CLF_noRoundY:
	;
	; add in left side bearing (may be negative)
	;
	mov	cx, ax				;cx <- x position
	mov	al, ds:[si].CD_xoff
	cbw					;ax <- x offset (signed)
	add	ax, cx				;ax <- new x position
	;
	; compute right side and do clipping check
	;
	mov	cl,ds:[si].CD_pictureWidth  ;cx <- character width.
	clr	ch			    ;
	jcxz	CLF_noDrawDX		    ;Don't draw if no char width.

					    ;   (jump is cx == 0).
	add	cx,ax			    ;add x position to width.
	dec	cx			    ;cx = right edge of character.
	;
	; compute top and bottom -- check for clipping
	;
	push	dx
	mov	dx, ax				;save x position
	mov	al, ds:[si].CD_yoff
	cbw					;ax <- y offset (signed)
	add	bx, ax				;bx <- real top
	mov	ax, dx
	mov	dl, ds:[si].CD_numRows
	clr	dh			   	;dx <- # of rows
	;
	; this one region covers all of the character -- test for inside
	; right bound
	;
CLF_saveLastON	equ  (this word) + 2
	cmp	cx,1234h		    ; check for right edge clipped.
	jg	CLF_complex		    ; Complex clip if it is.
					    ;
	REAL_FALL_THRU	FastCharCommon, no  ; YAY. Character is completely
					    ; unclipped, fall through to draw
					    ; it in the fastest way possible.


COMMENT @----------------------------------------------------------------------

FUNCTION:	FastCharCommon

DESCRIPTION:	Draw a character that is entirely visible, plain text in
		GR_COPY mode
		WARNING: This "routine" is not callable it is only jmp'able.

CALLED BY:	INTERNAL
		CharLowFast, CharLowCheck

PASS:
	ax - x position
	bx - top line to draw
	cx - right edge of character to draw
	dx - bottom line to draw
	ds:si = character data
	on stack - new x position

RETURN:
	ax - new x position popped from stack

DESTROYED:
	bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@


FastCharCommon	label  near
	mov	bp,ax			;save left
	;
	; set up segment registers
	;
	SetBuffer	es,di		;es = screen
	;
	; cx = right byte offset, pretend we're 8 pixels/byte for now
	;
	sar	cx,1			;(byte offset == pixel offset / 8)
	sar	cx,1
	sar	cx,1
	;
	; set up shift count and number of lines (in ax)
	;
	and	al,7			;al = shift count (left edge % 7).
	mov	ah,dl			;ah = lines to draw
	;
	; set up screen offset
	;
	mov	di,bx			;di - first line to draw at.
	mov	dx,bp
	add	bp,dx
	add	bp,dx
	CalcScanLine	di,bp,es	; set up segment,
	and	bx,7			;bx = pattern index
	;
	; calculate number of bytes to draw to
	;
	mov	cx, ax			; cl = shift count, ch = lines to draw
	lodsb				; al = picture width (bits)
	add	si, CD_data-1		; ds:si -> character picture  data
	cmp	al, 32			
	ja	FCC_tooBig

	; OK, it's small enough to draw with our fastest routines.  Go for it.

	clr	ah			; only interested in how many to load
	mov	bp, ax
	dec	bp			; one less (so 8 pixels -> one byte)
	shr	bp			; word table, divide by 4
	shr	bp			; word table, divide by 4
	and	bp, 0xfffe		; clear low bit
	jmp	cs:[bp][FCC_table]	; Call the routine to do the draw.

;------------------------------
; special case: complex clip for CharLowFastCheck
; NOTE: This stub is here so the branch above is in range.
; It really belongs above CharLowFastCheck, but there the
; branch is out of range.

CLF_complex:
	dec	dx			    ;dx <- num rows in char.
	add	dx,bx			    ;dx = bottom (y pos + num rows).
	mov	di,ds
	mov	es,di				;es = font
	push	dx
	call	SetComplex
	pop	dx
	mov	ds,cs:[PSL_saveWindow]		;ds = window
	jmp	CharLowComplex		;

;------------------------------
; special case -- Character too big

FCC_tooBig:
	jmp	CharLarge


COMMENT @----------------------------------------------------------------------

FUNCTION:	CharLowCheck

DESCRIPTION:	Draw a character
		WARNING: This "routine" is not callable it is only jmp'able.

CALLED BY:	INTERNAL
		VidPutChar, CharLowFast

PASS:
	ax - x position for character
	bx - y position for character
	dl - character to draw
	dh - previous character
	ds - font structure
	textMode - set
	ditherMatrix - set for current color

RETURN:
	Pointer possibly hidden
	ax - next x position

DESTROYED:
	bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	Gene	5/89		added checks for unbuilt character

------------------------------------------------------------------------------@

;------------------------------
; special case: character is missing:
;		(0) doesn't exist	--> use default
;		(2) not built		--> call the font driver
CLC_charMissing:
	tst	si			;assumes (CHAR_NOT_EXIST == 0)
	je	CLC_useDefault		;branch if character doesn't exist
EC <	cmp		si, CHAR_NOT_BUILT	>
EC <	ERROR_NE	FONT_BAD_CHAR_FLAG	>;shouldn't ever happen
	call	VidBuildChar
	mov	es, cs:[PSL_saveFont]	;es <- seg addr of font
	jmp	short CLC_afterBuild

;------------------------------
; special case: we have kerning info to use

CLC_DoKern:
	call	KernChar			;kern me jesus
	jmp	CLC_afterKern

if DBCS_PCGEOS
CLC_beforeFirst:
	add	dx, es:[FB_firstChar]
CLC_afterLast:
	call	CallLockCharSetES
	jnc	CLC_afterDefault
endif
;------------------------------
; special case: use default character
;		Use the default character if the character to draw is either
;		beyond the last character defined in the character set or
;		before the first character defined, or if the character
;		is 'missing' from the character set.
;
CLC_useDefault:
SBCS <	mov	dl, es:[FB_defaultChar]					>
DBCS <	mov	dx, es:[FB_defaultChar]					>
	jmp	short CLC_afterDefault

;------------------------------

CharLowCheck	label  near
	mov	di,ds
	mov	es,di				;es = font
	mov	ds,cs:[PSL_saveWindow]		;ds = window
	;
	; check for undefined character, in which case use the default
	; (Check for beyond last character in the char set).
	;
if DBCS_PCGEOS
CLC_afterDefault:
	cmp	dx, es:[FB_lastChar]
	ja	CLC_afterLast
	sub	dx, es:[FB_firstChar]
	jb	CLC_beforeFirst
else

	cmp	dl,es:[FB_lastChar]		;
	ja	CLC_useDefault			;
CLC_afterDefault:
	sub	dl,es:[FB_firstChar]		; check for before the first
	jb	CLC_useDefault			; character (another default).
endif

CLC_afterBuild:
	;
	; compute data pointer
	;
SBCS <	clr	dh				; dx <- char offset into font.>
	mov	di,dx
	FDIndexCharTable di, si
	mov	si, es:FB_charTable[di].CTE_dataOffset ;es:si <- data pointer
	cmp	si, CHAR_MISSING		;check for missing
	jbe	CLC_charMissing			;branch if char is missing

CLC_kernOp equ (this byte) + 0
	jmp	CLC_DoKern			;MODIFIED (JMP or MOV DH,xxx)
CLC_afterKern:
	;
	; es:si = index to CharTableEntry for character
	; compute next character x position - first check fractional width flag
	;
	mov	dx, ax				;dx <- left edge.
	cmp	cs:[fracPosition], 128		;
	jb	CLC_noRound			;
	inc	ax				;round to nearest pixel.
CLC_noRound:					;
	mov	cl, es:[di].FB_charTable.CTE_width.WBF_frac
	add	cs:[fracPosition], cl		;add in the fractional pos.
	adc	dx, es:[di].FB_charTable.CTE_width.WBF_int
	;
	; We also need to round the y position to an integer
	;
	cmp	cs:fracYPosition, 0x80
	jb	CLC_noRoundY
	inc	bx
CLC_noRoundY:
	;
	; add left side bearing (may be negative)
	;
	mov	cx, ax				;cx <- x position
	mov	al, es:[si].CD_xoff
	cbw					;ax <- x offset (signed)
	add	ax, cx				;ax <- new x position

	;
	; compute real width of character
	;
	mov	cl,es:[si].CD_pictureWidth	;cx <- char width
	clr	ch				;
	jcxz	CLCh_noDrawDX
	add	cx,ax				;add position to width.
	dec	cx				;cx <- right side
	;
	; compute right side and do clipping check
	;
	cmp	cx,ds:[W_maskRect.R_left]	;check for clipped on left.
	jge	CLCh_noClipRight		;
CLCh_noDrawDX:
	mov	ax,dx
	jmp	PSL_afterDraw

CLCh_noClipRight:
	;
	; test for mask region null or entirely clipped left
	;
	cmp	ax,ds:[W_maskRect.R_right]	; check for beyond right
	jg	CLCh_noDrawDX			;
	;
	; compute top and bottom -- check for clipping
	;
	mov	bp, ax				;save x position
	mov	al,es:[si].CD_yoff
	cbw					;ax <- y offset (signed)
	add	bx, ax				;bx <- real top
	mov	ax, bp

	cmp	bx,ds:[W_maskRect.R_bottom]	;check for below bottom
	jg	CLCh_noDrawDX			;if so, don't draw
						;
	push	dx				;save x new position
	mov	dl,es:[si].CD_numRows		;
	clr	dh				;dx <- height
	dec	dx				;
	add	dx,bx				;dx <- bottom
	cmp	dx,ds:[W_maskRect.R_top]	;check for above top
	jl	CLCh_noDrawPop			;if so, don't draw
	;
	; make sure that clip info is correct
	;
	mov	bp,ds:[W_clipRect.R_bottom]			;
	cmp	bx,bp				; check for clipped top.
	jg	CLCh_setClip			;
	cmp	bx,ds:[W_clipRect.R_top]	; check for clipped bottom. 
	jl	CLCh_setClip			;
CLCh_afterClip:
	;
	; see if all of character is visible
	;
	test	ds:[W_grFlags],mask WGF_CLIP_SIMPLE ; is entire scan visible.
	jz	CLCh_complex			;
	cmp	dx,bp				; does clipReg span all lines ?
	jge	CLCh_complex			;
	;
	; this one region covers all of the character -- test for inside left
	; and right bounds
	;
	test	ds:[W_grFlags],mask WGF_CLIP_NULL	; is clip region empty.
	jnz	CLCh_noDrawPop			; don't draw if totally clipped
						;
	mov	bp,ds:[W_clipRect.R_left]	; left edge
	mov	di,ds:[W_clipRect.R_right]	; right edge
	cmp	ax,di				; entirely clipped ?
	jg	CLCh_noDrawPop			; if so then exit
	cmp	cx,bp				;
	jl	CLCh_noDrawPop			; if so then exit
	;
	; not entirely outside firstON, lastON -- check for straddling one
	; of these two -- if so then complex clip
	;
	cmp	ax,bp				;
	jl	CLCh_CharClip			;
	cmp	cx,di				;
	jg	CLCh_CharClip			;
	;
	; check for collision with pointer
	;
BeforeFastCommon:
NMEM <	call	CheckCollisionsDS					>
NMEM <	jc	CLCh_realSlow			;if collision, use slow case >
	test	cs:[stateFlags], mask AO_MASK_1
	jz	CLCh_realSlow			;
	mov	di, es				;
	mov	ds, di				; ds <- font ptr.
	sub	dx, bx				;dx <- number of lines to draw.
	inc	dx				; -1
	jmp	FastCharCommon			;use code in CharLowFast

;------------------------------
; special case: need complex test

CLCh_complex:
	jmp	CharLowComplex

;------------------------------
; special case: character clipped (not visible)

CLCh_noDrawPop:
	pop	ax
	jmp	PSL_afterDraw

;------------------------------
; special case: must recalculate clip region

CLCh_setClip:
	push	ax
	push	si
	call	WinValClipLine
	pop	si
	pop	ax
	mov	bp,ds:[W_clipRect.R_bottom]
	jmp	short CLCh_afterClip

;------------------------------
; special case: character partially visible

CLCh_CharClip:
	jmp	CharClip

;------------------------------

CLCh_realSlow:
	jmp	CharGeneralRealSlow


COMMENT @----------------------------------------------------------------------

FUNCTION:	CharLowComplex

DESCRIPTION:	Do an exhaustive region check to see determine how to
		draw the character
		WARNING: This "routine" is not callable it is only jmp'able.

CALLED BY:	INTERNAL
		CharLowFast, CharLowCheck

PASS:
	ax - x position
	bx - top line to draw
	cx - right edge of character to draw
	dx - bottom line to draw
	ds - Window structure
	es:si = character data
	ditherMatrix - set
	on stack - new x position

RETURN:
	ax - new x position popped from stack

DESTROYED:
	bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:
	ax - point from region
	si - region ptr
	di - left

PSEUDO CODE/STRATEGY:
	Determine which of these routines to use:
		CharFastCommon -- Fits CharLowFast criteria
		CharClip -- Character is only partially visible

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@

CharLowComplex	label near
	mov	di,ax
	push	si			;save si
	mov	si, ds:W_maskReg	;
	mov	si, ds:[si]		;
	add	si,ds:[W_clipPtr]	;point at mask region
	stc
	call	GrTestRectInReg
	pop	si
	cmp	al,TRRT_OUT
	jz	CLC_done
	cmp	al,TRRT_PARTIAL
	jz	CLC_CharClip

	mov	ax,di			;recover left
	jmp	BeforeFastCommon

CLC_CharClip:
	mov	ax,di			;recover left
	jmp	CharClip		;

CLC_done:
	pop	ax
	jmp	PSL_afterDraw


COMMENT @----------------------------------------------------------------------

FUNCTION:	CharClip

DESCRIPTION:	Draw a character that is partially clipped.

CALLED BY:	INTERNAL
		CharLowCheck

PASS:
	ax - x position
	bx - top line to draw
	cx - right edge of character to draw
	dx - bottom line to draw
	ds - Window structure
	es:si = character data
	ditherMatrix - set
	on stack - new x position

RETURN:
	ax - new x position popped from stack

DESTROYED:
	bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:
	Check for mouse collision
	Calculate variables
	while (linesToDraw--) {
		Set clipping vars and line mask for line
		for (i = 0; i < bytesToDraw; i++) {

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@

CharClip	label  near
	jmp	CharGeneralSlow


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharGeneralSlow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character that is possibly clipped

CALLED BY:	INTERNAL
		CharGeneral
PASS:		ax - x position
		bx - top line to draw
		cx - right edge of character to draw
		dx - bottom line to draw
		ds - Window structure
		es:si = character data
		ditherMatrix - set
		on stack - new x position
RETURN:		ax - new x position popped from stack
DESTROYED:	bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

	REGISTER/STACK USAGE:
		ds:si - character data
		es:di - screen position

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial mono version
	Jim	10/92		Re-written for 8-bit devices

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CharGeneralSlow	label near
		test	cs:[stateFlags], mask AO_MASK_1
		jnz	continue
		jmp	CharGeneralRealSlow
continue:
		mov	cs:[currentWin], ds	; save window.
		mov	cs:[currentLine], bx	; save current scan line
		call	CalcCharVars		; calculate drawing variables

		; loop for each line of the character data

lineLoop:
		call	SlowReadLine		; read data into lineDataBuffer
		push	si			; save ptr to character data.
		push	ds			; save segment of window.

		; Check for clipping which requires special setup

		mov	bx, cs:[currentLine]	; bx <- current character line.
		inc	cs:[currentLine]	; advance to next one.
		tst	bx			; check for off screen.
		js	nextLine		; skip to next one if it is.
		push	di			; save scan start
		call	SlowGenClip		; gen correct clip info
		jc	nextScan		;

		; Init for line

		mov	cx, cs			; ds <- driver segment.
		mov	ds, cx			;
		assume	ds:@CurSeg
		mov	si, offset lineDataBuffer ; si <- offset to char line
		mov	bx, ds:[charByteOffset]	; bx <- scan line offset
		mov	ch, ds:[bytesToDraw]	; ch <- #bytes of char data.
		mov	cl, ds:[shiftCount]	; shift count 
		clr	dl			; dl holds char data overflow

		; Loop for each byte -- load byte
byteLoop:
		clr	ah
		lodsb				; al = char data
		ror	ax, cl			; align with big mask buffer
		or	al, dl			; combine previous bits
		mov	dl, ah			; save new overflow

		; Clip byte

		tst	bx 			; test for byte not on screen
		js	skipByte		; skip to next byte if it is.
MEM <		cmp	bx, cs:[bm_bpMask]	; check for off-screen right >
NMEM <		cmp	bx, SCREEN_BYTE_WIDTH	; check for off-screen right >
		jge	nextScan		; jump if we're there

		; write out character data byte, applying appropriate dither
ifndef	IS_MEM
		and	ax, {word} cs:[lineMaskBuffer][bx]
else
		; for vidmem, the lineMaskBuffer stored as part of bitmap...

		push	bx, ds			; save some regs
		mov	ds, cs:[bm_segment]	; get window segment
		add	bx, size EditableBitmap ;
		and	ax, ds:[bx]  		; mask with region.
		pop	bx, ds			; save some regs
endif
		jz	nextByte		; if masking everything
MEM <		cmp	bx, cs:[bm_bpMaskRndDwn] ; check for last byte	>
MEM <		jge	lastByte		 ; jump if so		>
		call	DrawCharByte		; write byte of char data
		sub	di, 24			; so we don't add twice

		; Skip to next byte.
nextByte:
		add	di, 24			; onto next byte
skipByte:
		inc	bx			; onto next byte
		dec	ch			; do all bytes
		jnz	byteLoop		;
nextScan:
		pop	di			; restore scan line start
		NextScan di			; bump to next scan line
nextLine:
		pop	ds			;
		assume	ds:dgroup
		pop	si			;
MEM <		tst	cs:[bm_scansNext]	; if negative, bogus	>
MEM <		js	CGS_done					>
		dec	cs:[linesToDraw]	; one less line to draw.
		LONG jnz lineLoop		; loop to do the next one.
MEM <CGS_done:								>
		pop	ax
		jmp	PSL_afterDraw

		; We're working on the last "byte" of pixels, which can
		; correspond between 0 and 8 pixels that are left to
		; be written. Just write any pixels that remain.
lastByte:
		mov	cx, cs:[bm_nonIntegralPixels]
		call	DrawCharPartialByte	; handles 0-8 pixels
		jmp	nextScan


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharGeneralRealSlow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character that is possibly clipped and is in a
		pattern.
CALLED BY:	INTERNAL
		CharGeneral
PASS:		ax - x position
		bx - top line to draw
		cx - right edge of character to draw
		dx - bottom line to draw
		ds - Window structure
		es:si = character data
		ditherMatrix - set
		on stack - new x position
RETURN:		ax - new x position popped from stack
DESTROYED:	bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	jim	10/22/92	Rewritten for 8-bit color

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CharGeneralRealSlow	label  near

		; copy the draw mask over

		mov	cs:[currentWin], ds	; save window segment
		mov	cs:[currentLine], bx	;save current line of character.
		push	ax
		mov	ds, cs:[PSL_saveGState]	;
		mov	ax, {word} ds:[GS_textAttr.CA_mask]
		mov	{word} cs:[drawMask], ax
		mov	ax, {word} ds:[GS_textAttr.CA_mask+2]
		mov	{word} cs:[drawMask+2], ax
		mov	ax, {word} ds:[GS_textAttr.CA_mask+4]
		mov	{word} cs:[drawMask+4], ax
		mov	ax, {word} ds:[GS_textAttr.CA_mask+6]
		mov	{word} cs:[drawMask+6], ax
		pop	ax
		mov	ds, cs:[currentWin]	; restore ds
		call	CalcCharVars		; calculate drawing variables
RSlineLoop:					;
		call	SlowReadLine		; read data into lineDataBuffer
		push	si, ds			; save ptr to character data.

		; Check for clipping which requires special setup

		mov	bx, cs:[currentLine]	; bx <- current character line.
		inc	cs:[currentLine]	; advance to next one.
		tst	bx			; check for off screen.
		js	RSnextLine		 ; skip to next one if it is.
		push	di
		mov	cx, bx			; save it
		and	bx, 7
		mov	bl, cs:[bx][drawMask]
		mov	cs:[drawMaskByte], bl	; save it for later
		mov	bx, cx			; restore it
		call	SlowGenClip		; ensure clip info is correct
		jc	RSnextScan		;

		; Init for line

		segmov	ds, cs, cx		; ds <- driver segment.
		assume	ds:@CurSeg
		mov	si, offset lineDataBuffer ; si <- offset to char line
		mov	bx, ds:[charByteOffset]	; bx <- scan line offset
		mov	ch, ds:[bytesToDraw]	; ch <- #bytes of char data.
		mov	cl, ds:[shiftCount]	; shift count 
		clr	dl			; dl holds char data overflow

		; Loop for each byte -- load byte
writeLoop:
		clr	ah
		lodsb				; al = mask
		ror	ax,cl			; al = char data aligned
		or	al, dl			; combine previous bits
		mov	dl, ah			; save new overflow

		; Clip byte

		tst	bx			; test for byte not on screen
		js	RSskipByte		; skip to next byte if it is.
MEM <		cmp	bx, cs:[bm_bpMask]	; check for off-screen right >
NMEM <		cmp	bx, SCREEN_BYTE_WIDTH	; check for off-screen right >
		jge	RSnextScan		; jump if we're there

		; write out character data byte, applying appropriate dither
 		; screen <- screen & !(data & mask) | (data & pattern & mask)
ifndef	IS_MEM
		and	ax, {word} cs:[lineMaskBuffer][bx]
else
		; for vidmem, the lineMaskBuffer is stored in the bitmap

		push	bx,ds			; save some regs
		mov	ds, cs:[bm_segment]	; get window segment
		add	bx, size EditableBitmap ;
		and	ax, ds:[bx]  		; mask with region.
		pop	bx,ds			; save some regs
endif
drawMaskByte	equ (this byte) + 1
		and	al, 12h			; apply draw mask
MEM <		cmp	bx, cs:[bm_bpMaskRndDwn] ; check for last byte	>
MEM <		jge	RSlastByte		 ; jump if so		>
		call	DrawCharByte		; write one char byte
		sub	di, 24			; so we don't add twice

		; done with this byte.  Onto the next
RSnextByte::
		add	di, 24			; onto next byte
RSskipByte:
		inc	bx
		dec	ch			; do all bytes
		jnz	writeLoop		;
RSnextScan:
		pop	di
		NextScan di
RSnextLine:
		pop	si, ds			; restore ptr to char data
		assume	ds:dgroup
MEM <		tst	cs:[bm_scansNext]	; if negative, bogus	>
MEM <		js	CGRS_done					>
		dec	cs:[linesToDraw]	;one less line to draw.
		LONG jnz RSlineLoop		;else loop to do the next 
MEM <CGRS_done:								>
		pop	ax
		jmp	PSL_afterDraw

		; We're working on the last "byte" of pixels, which can
		; correspond between 0 and 8 pixels that are left to
		; be written. Just write any pixels that remain.
RSlastByte:
		mov	cx, cs:[bm_nonIntegralPixels]
		call	DrawCharPartialByte	; handles 0-8 pixels
		jmp	RSnextScan


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharGeneralFast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character that is not clipped and is not in outline

CALLED BY:	INTERNAL
		CharGeneral
PASS:		ax - x position
		bx - top line to draw
		ds - Window structure
		es:si = character data
		ditherMatrix - set
		on stack - new x position
RETURN:		ax - new x position popped from stack
DESTROYED:	bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	jim	10/22/92	Re-written for 8-bit color

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CharGeneralFast	label  near
		ForceRef	CharGeneralFast
		.warn	-unreach
		call	CalcCharVars		; calculate drawing variables
		.warn	@unreach

		; Init for each line.
GFlineLoop:
		push	di	
		mov	cl, cs:[shiftCount]	; cl <- alignment shift
		mov	ch, cs:[bytesToDraw]	; ch <- bytes on each line.
		mov	bl, cs:[linesToDraw]	; bl <- #scan lines to draw

		; Loop for each byte -- load byte
GFbyteLoop:
		clr	ah
		lodsb				; al = char data

		; write out character data byte, applying appropriate dither
		; screen <- (screen & !mask) | (data & mask & pattern)

		call	DrawCharByte
		dec	ch			; one less byte to do.
		jnz	GFbyteLoop
		pop	di
		NextScan di

		; bump dither indices

MEM <		tst	cs:[bm_scansNext]	; if negative, bogus	>
MEM <		js	GF_done						>
		dec	bl			;one less line to do.
		jnz	GFlineLoop		;else loop to do the next one.
MEM <GF_done:								>
		pop	ax
		jmp	PSL_afterDraw


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharLarge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level routine to draw a character when the source is
		X bytes wide and the destination is Y bytes wide, the drawing
		mode in GR_COPY and the character is entirely visible.

CALLED BY:	INTERNAL
		CharLowFast
PASS:		al - (bytes to load - 1) * 8
		ah - (bytes to draw - 1) * 2
		ds:si - character data
		es:di - screen position
		bx - pattern index
		cl - shift count
		ch - number of lines to draw
		bp - x position
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	jim	10/22/92	Rewritten for 8-bit color

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CharLarge 	label near

		; calculate the number of data bytes we're gonna load

		add	al, 7			; round up
		shr	al
		shr	al
		shr	al
		mov	cs:[bytesToDraw], al	; save for later
						;
CLlineLoop:
		push	di
		mov	bl, cs:[bytesToDraw]	; init byte count

CLbyteLoop:
		clr	ah
		lodsb				; al = char data

		; write out character data byte, applying appropriate dither
		; screen <- (screen & !mask) | (data & mask & pattern)

		call	DrawCharByte		; draw a byte of data
		dec	bl			; one less byte to do.
		jnz	CLbyteLoop		; loop to do next byte.
		pop	di
		NextScan di

		; One less line to do.

MEM <		tst	cs:[bm_scansNext]	; if negative, bogus	>
MEM <		js	CC_done						>
		dec	ch
		jnz	CLlineLoop		; loop to do next line.
MEM <CC_done:								>
		pop	ax
		jmp	PSL_afterDraw

CharCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCharVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate lots of information about the character that is
		about to be drawn.
CALLED BY:	INTERNAL
		CharGeneral
PASS:		ax - x position
		bx - top line to draw
		cx - right edge of character to draw
		dx - bottom line to draw
		ds - Window structure
		es:si = character data
		ditherMatrix - set
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	jim	10/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcCharVars	proc	near

		; save byte offset in mask data

		mov	bp, ax				; save x position
		sar	ax, 1				; (arithmetic shift)
		sar	ax, 1			
		sar	ax, 1			
		mov	cs:[charByteOffset], ax		; save offset for line.

		; cx = right byte offset

		sar	cx, 1			
		sar	cx, 1			
		sar	cx, 1			
		sub	cx, ax				; cx = #bytes - 1
	
		; set up shift count and #lines
	
		mov	ax, bp
		and	bp, 0xfff8			; writes are aligned!
		tst	bp				; if neg, don't add
		jns	offsetOK
		clr	bp				; just wait for it
offsetOK:		   
		and	al, 7
		mov	cs:[shiftCount], al		
		sub	dx, bx			
		inc	dx			
		mov	cs:[linesToDraw], dl	
	
		; set up screen offset
	
		mov	di, bx				; di - first line
		tst	di				; on screen ?
		jns	firstScanOK
		clr	di			
	
		; set up segment registers
firstScanOK:	
		segmov	ds, es, ax			; ds -> font
		SetBuffer es, ax			; es -> screen
		mov	ax, bp
		add	bp, ax
		add	bp, ax
		CalcScanLine	di, bp, es

		; For bitmaps, set offset into the pattern.
	
		and	bx, 7
	
		; calculate number of bytes to draw to
	
		inc	cx			; cx = # of bytes to draw
		mov	cs:[bytesToDraw], cl
		mov	ah, cl			; ah = bytes to draw
		lodsb				; al = picture width (bits)
		add	al, 7			; round up to full byte
		shr	al			;
		shr	al			;
		shr	al			;
		sub	ah, al			; ah = extra bytes
		mov	cs:[extraBytesToDraw], ah
		add	si, CD_data-1		; ds:si = data
		ret
CalcCharVars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCharByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a byte of character data, draw it.

CALLED BY:	INTERNAL
		various char drawing routines
PASS:		al	- char data to draw, already masked
		es:di	- frame buffer pointer
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCharByte	proc	near
		uses	bx
		.enter

EC <		push	ax						>
EC <		mov	ax, es						>
EC <		cmp	ax, cs:[bm_lastSeg]				>
EC <		ERROR_NE VIDMEM_HUGE_ARRAY_PROBLEM			>
EC <		mov	ax, cs:[bm_ec_lastOffset]			>
EC <		cmp	di, ax						>
EC <		ERROR_B  VIDMEM_HUGE_ARRAY_PROBLEM			>
EC <		add	ax, cs:[bm_ec_lastSliceSize]			>
EC <		sub	ax, 8						>
EC <		cmp	di, ax						>
EC <		ERROR_AE VIDMEM_HUGE_ARRAY_PROBLEM			>
EC <		pop	ax						>

		mov	bh, al
		mov	ax, {word}cs:[currentColor].RGB_red
		mov	bl, {byte}cs:[currentColor].RGB_blue

		shl	bh, 1
		jnc	pix2			
		mov	{word}es:[di].RGB_red, ax
		mov	{byte}es:[di].RGB_blue, bl
pix2:
		shl	bh, 1
		jnc	pix3			
		mov	{word}es:[di+3].RGB_red, ax
		mov	{byte}es:[di+3].RGB_blue, bl
pix3:
		shl	bh, 1
		jnc	pix4			
		mov	{word}es:[di+6].RGB_red, ax
		mov	{byte}es:[di+6].RGB_blue, bl
pix4:
		shl	bh, 1
		jnc	pix5			
		mov	{word}es:[di+9].RGB_red, ax
		mov	{byte}es:[di+9].RGB_blue, bl
pix5:
		shl	bh, 1
		jnc	pix6			
		mov	{word}es:[di+12].RGB_red, ax
		mov	{byte}es:[di+12].RGB_blue, bl
pix6:
		shl	bh, 1
		jnc	pix7			
		mov	{word}es:[di+15].RGB_red, ax
		mov	{byte}es:[di+15].RGB_blue, bl
pix7:
		shl	bh, 1
		jnc	pix8			
		mov	{word}es:[di+18].RGB_red, ax
		mov	{byte}es:[di+18].RGB_blue, bl
pix8:
		shl	bh, 1
		jnc	done
		mov	{word}es:[di+21].RGB_red, ax
		mov	{byte}es:[di+21].RGB_blue, bl
done:
		add	di, 24

		.leave
		ret
DrawCharByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCharPartialByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a byte of character data, draw it.

CALLED BY:	INTERNAL
		various char drawing routines
PASS:		al	- char data to draw, already masked
		cx	- # of pixels to draw (0 - 8)
		es:di	- frame buffer pointer
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		Optimized for space over speed, as this should not
		be called frequently.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/22/92	Initial version
	Don	10/28/00	Broke out separate routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCharPartialByte	proc	near
		uses	bx
		.enter

EC <		cmp	cx, 8			; expect 0 to 8		>
EC <		ERROR_A	VIDMEM_INTERNAL_ERROR				>
		jcxz	done
		mov	bh, al
		mov	ax, {word}cs:[currentColor].RGB_red
		mov	bl, {byte}cs:[currentColor].RGB_blue
	;
	; Loop through the pixels
	;
pixelLoop:
		shl	bh, 1
		jnc	nextPixel
		mov	{word}es:[di].RGB_red, ax
		mov	{byte}es:[di].RGB_blue, bl
nextPixel:
		add	di, 3
		loop	pixelLoop
done:
		.leave
		ret
DrawCharPartialByte	endp
