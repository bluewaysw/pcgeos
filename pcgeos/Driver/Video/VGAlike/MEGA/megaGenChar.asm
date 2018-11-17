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
		

	$Id: megaGenChar.asm,v 1.1 97/04/18 11:42:19 newdeal Exp $

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

;------------------------------
; special case: use default character
;		the current character is beyond the set of characters defined
;		in this font.
CLF_useDefault:
	mov	dl,byte ptr ds:[FB_defaultChar]
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
CLF_lastChar	equ  (this byte) + 2
	cmp	dl,12h			    ; check against last character in
	ja	CLF_useDefault		    ; font, use default if beyond.
CLF_afterDefault:
CLF_firstChar	equ  (this byte) + 2
	sub	dl,12h			    ; Subtract from first to get offset
					    ; into the font for this character.
	jb	CLF_useDefault		    ; If char is below the first char
					    ; defined for the font then use
					    ; the default character (the
					    ; useDefault code branches right
					    ; back here, but with a valid char
					    ; in dl).
CLF_afterBuild:
	; compute data pointer
	clr	dh			    ; dx <- offset into font data.
	mov	di,dx			    ; di <- offset * 8
	shl	di,1			    ;
	shl	di,1			    ;
	shl	di,1			    ;
	mov	si,ds:FB_charTable[di].CTE_dataOffset ;es:si <- data pointer
	cmp	si, CHAR_MISSING	    ;Check for missing character.
	jbe	CLF_charMissing		    ;Use default if missing.
	;
	; ds:di = index to CharTableEntry for character
	; compute next character x position
	;
CLF_kernOp equ (this byte) + 0
	jmp	CLF_DoKern			;MODIFIED (JMP or MOV DH,xxx)
CLF_afterKern:

		    			    ;ASSUMES CTE_width.WBF_int.high == 0
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
ifndef	IS_CLR24
MEM  <	call	CalcDitherIndices	; for strange ditherMatrices	>
endif
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
	ditherMatrix - set
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
	; cx = right byte offset
	;
ifndef  MEM_CLR4
	shr	cx,1			;cx = right, calculate byte offset
	shr	cx,1			;
endif
	shr	cx,1			;(byte offset == pixel offset / 8)
	;
	; set up shift count and number of lines (in ax)
	;
	and	al,7			;al = shift count (left edge % 7).
ifdef IS_MEM
C4 <	and	al, 1			; 2 pixels/byte		>
endif
	mov	ah,dl			;ah = lines to draw
	;
	; set up screen offset
	;
	mov	di,bx			;di - first line to draw at.
ifndef  MEM_CLR4
	shr	bp,1			;bp = byte offset (left / 8).
	shr	bp,1			;
endif
	shr	bp,1			;
	sub	cx,bp			;cx = number of bytes to draw - 1
NMEM <	CalcScanLine	di,bp		;di = screen offset with bp added in >
MEM  <	CalcScanLine	di,bp,es	; set up segment, 		>
BIT <	and	bx,7			;bx = pattern index		>
	;
	; calculate number of bytes to draw to
	;
	xchg	ax,cx			;cl = shift count, ch = lines to draw
	shl	ax,1			;al = (# of bytes to draw - 1) * 2
					;
	mov	ah,al			;
	lodsb				;al = picture width (bits)
	dec	ax			;NOTE: This is meant to decrement
					;      the byte but the word operation
					;      is faster and will work since
					;      al is always non zero
	and	al,11111000b		;al = (bytes to load - 1) * 8
	add	si,CD_data-1		;ds:si = data
	;
	; al = (bytes to load - 1) * 8, ah = (bytes to draw - 1) * 2
	;
MEGA <	mov	bh,bl			; bh = pattern index		>
EGA <	mov	bl,BITMASK						>
EGA <	mov	dx,GR_CONTROL						>

	test	ax,0f8e0h		; check for: al >= 32 or ah >= 8
	jnz	FCC_tooBig
ifdef   MEM_CLR4
	clr	ah			; only interested in how many to load
	shr	ax, 1			; word table, divide by 4
	shr	ax, 1			; word table, divide by 4
endif
	add	al,ah			; Wow. The thing is small enough to
	clr	ah			; draw quickly.
	mov	bp,ax			; 
					;
ifdef	IS_MEM
C4   <	shl	bx, 1			; word-wide dither matrix	>
C4   <	and 	bx, 6			; 4-words/matrix		>
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	doDispersed						>
MONO <	jmp	ClusterCharMux						>
CMYK <	jmp	ClusterCharMux						>
MONO <doDispersed:							>
endif

ifndef	IS_CMYK
	jmp	cs:[bp][FCC_table]	; Call the routine to do the draw.
endif
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

;------------------------------
; special case: use default character
;		Use the default character if the character to draw is either
;		beyond the last character defined in the character set or
;		before the first character defined, or if the character
;		is 'missing' from the character set.
;
CLC_useDefault:
	mov	dl,byte ptr es:[FB_defaultChar]
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
	cmp	dl,byte ptr es:[FB_lastChar]	;
	ja	CLC_useDefault			;
CLC_afterDefault:
	sub	dl,byte ptr es:[FB_firstChar]	; check for before the first
	jb	CLC_useDefault			; character (another default).
CLC_afterBuild:
	;
	; compute data pointer
	;
	clr	dh				; dx <- char offset into font.
	mov	di,dx				; di <- offset * 8
	shl	di,1				;
	shl	di,1				;
	shl	di,1				;
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
ifndef IS_CLR24
MEM <	call	CalcDitherIndices			>
endif

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
	test	ds:[W_grFlags],mask WGF_CLIP_SIMPLE	; is entire scan line visible.
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
NMEM <	call	CheckCollisionsDS					>
	jmp	CharGeneralSlow


COMMENT @----------------------------------------------------------------------

FUNCTION:	CharGeneralSlow

DESCRIPTION:	Draw a character that is possibly clipped and possibly in
		outline

CALLED BY:	INTERNAL
		CharGeneral

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
	bytesToDraw - number of bytes to draw
	extraBytesToDraw - number of bytes to draw - number of bytes to load
	shiftCount - number of times to shift right
	linesToDraw - number of lines to draw
	currentWin - segment of window
	currentLine - first line to draw
	charByteOffset - first line to draw
	bp - BITMAP - pattern index
	     EGA - GR_CONTROL
	cx - number to use with NextScanReg to move to next line
	ds:si - character data
	es:di - screen position

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@


;----------------------------------------------------
; special case: line entirely clipped
;		skips 'bytesToDraw' bytes in the character definition to get
;		to the next char line to draw.

CGS_lineClipped:
	mov	ch,cs:[bytesToDraw]		;load and fall thru
	;;; FALL THRU to skipEOLN
;----------------------------------------------------
; special case: rest of line clipped
;		skips the remainder of the line.

CGS_skipEOLN:
	mov	cl,ch
	clr	ch
	add	di,cx
	jmp	CGS_afterWrite

;----------------------------------------------------

CGS_realSlow:
	jmp	CharGeneralRealSlow

CharGeneralSlow	label near
	test	cs:[stateFlags], mask AO_MASK_1
	jz	CGS_realSlow
	mov	cs:[currentWin],ds	;save segment of window.
	mov	cs:[currentLine],bx	;save current line of character.
					;
	call	CalcCharVars		;calculate drawing variables
	;
	; bx == pattern index for bitmap drivers.  Save it for
	;       mono EGA as well.
	;
MEGA <	mov	bp, bx							>
NMEM <	StoreNextScanMod	<cs:[CGS_nextScanOffset]>,cx		>

	; for vidmem, we probably need to do some extra work for clustered
	; dithers
ifndef	IS_CLR24
ifdef	IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CGS_skipClustered					>
ifndef  MEM_CLR4
	InitDitherIndex bp
	mov	cs:[CGS_ditherBase], bp		
	mov	bp, bx				; keep ditherIndex in bp
endif
MONO <CGS_skipClustered:						>
endif
endif

CGS_lineLoop:
	call	SlowReadLine		; read data into lineDataBuffer
					;
	push	si			; save ptr to character data.
	push	ds			; save segment of window.
	;
	; Check for clipping which requires special setup
	;
	mov	bx,cs:[currentLine]	; bx <- current character line.
	inc	cs:[currentLine]	; advance to next one.
	tst	bx			; check for scan line off screen.
	LONG js	CGS_afterLine		; skip to next one if it is.
					;
MEM  <	push	di			; save scan start		>
	call	SlowGenClip		; make sure clip info is correct
	LONG jc	CGS_lineClipped		;
	;
	; Init for line
	;
	mov	cx,cs			; ds <- driver segment.
	mov	ds,cx			;
	assume	ds:@CurSeg
	mov	si, offset lineDataBuffer ; si <- offset to char line
					;       data.
	mov	bx,ds:[charByteOffset]	; bx <- offset to char data.
	mov	cl,ds:[shiftCount]	; cl <- amount to shift data.
	mov	ch,ds:[bytesToDraw]	; ch <- number of bytes of char data.
	clr	dl			;no bits from last byte
	;
	; Loop for each byte -- load byte
	;
CGS_writeLoop:
	lodsb				;al = mask, ah = extra data
	clr	ah			;
	ror	ax,cl			;ax = mask shifted correctly
					;
	or	al,dl			;ax = mask with all bits correct
EGA <	mov	dl,ah			;;dl = extra bits		>
	;
	; Clip byte
	;
	tst	bx			;test for byte not on screen
	LONG js	CGS_skipWrite		;skip to next byte if it is.
NMEM <	cmp	bx,SCREEN_BYTE_WIDTH	;check for off screen left.	>
ifdef IS_CMYK
	cmp	bx, cs:[bm_bpPlane]	; check fro off screen left
else
MEM  <	cmp	bx,cs:[bm_bpScan]	;check for off screen left.	>
endif
	LONG jge CGS_skipEOLN		;skip to next line if it is.

	; for the memory video driver, the lineMaskBuffer is stored as part
	; of the bitmap...

MEM  <	push	bx,ds			; save some regs		>
MEM  <	mov	ds, cs:[bm_segment]	; get window segment		>
MEM  <	add	bx, size EditableBitmap ;				>
MEM  <	and	al, ds:[bx]  		; mask with region.		>
MEM  <	pop	bx,ds			; save some regs		>

	; ...whereas it is in a fixed location for other drivers

NMEM <	and	al,ds:[bx][lineMaskBuffer]  ; mask with region.		>

	; Bitmap drivers (CGA, HGC, etc).
	; screen <- (screen & !mask) | (data & mask & pattern)
	; For vidmem, things are a little more interesting.  Most of the 
	; vidmem modules use a clustered dither pattern, requiring some
	; register gymnastics.  Mono mode also does this, but allows normal
	; (dispersed) dithering as well.	

ifndef IS_MEGA
BIT <	mov	dh,al			; save mask			>
ifndef IS_CLR24
ifdef IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CGS_normalDither					>
	push	si
CGS_ditherBase equ (this word) + 1				
	mov	si, 1234h						
CMYK <	push	bx							>
	NextDitherByte si, bp
	BumpDitherIndex bp						
CMYK <	pop	bx							>
	pop	si							
MONO <monoCont:								>
else
BIT <	mov	al, {byte} cs:[bp][ditherMatrix] ;al = pattern 		>
endif
endif
BIT <	and	al, dh			; al = mask AND pattern		>
BIT <	not	dh			;;dh = NOT mask			>
BIT <	mov	dl,es:[di]		;;dl = screen			>
BIT <	and	dl,dh			;;dl = NOT mask AND screen	>
BIT <	or	al,dl			;;al = data to store		>
BIT <	mov	es:[di], al						>

		; for CMYK, we have three more planes to do
ifdef	IS_CMYK
	push	bx
	not	dh
	mov	al, {byte} cs:[cyanWord]	; cyan is next	(setup by
	and	al, dh				;  NextDitherByte)
	not	dh
	mov	bx, cs:[bm_bpPlane]		; index to cyan plane
	mov	dl, es:[bx][di]
	and	dl, dh
	not	dh
	or	al, dl
	mov	es:[bx][di], al			; store cyan
	shl	bx, 1				; on to magenta
	mov	al, {byte} cs:[magentaWord]
	and	al, dh
	not	dh
	mov	dl, es:[bx][di]
	and	dl, dh
	not	dh
	or	al, dl
	mov	es:[bx][di], al			; store magenta
	add	bx, cs:[bm_bpPlane]		; on to black
	mov	al, {byte} cs:[blackWord]
	and	al, dh
	not	dh
	mov	dl, es:[bx][di]
	and	dl, dh
	or	al, dh
	mov	es:[bx][di], al			; store black
	pop	bx
endif

endif
	;
	; Color EGA type drivers.
	; Write byte and mask all at once to the EGA card.
	;
CEGA <	mov	ah,al							>
CEGA <	mov	al,BITMASK						>
CEGA <	xchg	dx,bp							>
CEGA <	out	dx,ax							>
CEGA <	xchg	dx,bp							>
CEGA <	or	es:[di],al						>
	;
	; Monochrome EGA type drivers.
	; Blast out the white pixels first, then reverse the mask
	; and blast out the black pixels.  This works correctly
	; in inverse mode as well.
	;
MEGA <	push	ax, cx, dx						>
MEGA <	xchg	cx, ax							>
MEGA <	mov	dx, GR_CONTROL						>
MEGA <	clr	al			; set fill color to white	>
MEGA <	mov	ah, 0xff						>
MEGA <	out	dx, ax							>
MEGA <	mov	ah, {byte} cs:[bp][ditherMatrix]			>
MEGA <	and	ah, cl							>
MEGA <	mov	al,BITMASK						>
MEGA <	out	dx,ax							>
MEGA <	or	es:[di],al						>
MEGA <	clr	ax			; set fill color to black	>
MEGA <	out	dx, ax							>
MEGA <	mov	ah, {byte} cs:[bp][ditherMatrix]			>
MEGA <	not	ah							>
MEGA <	and	ah, cl							>
MEGA <	mov	al,BITMASK						>
MEGA <	out	dx,ax							>
MEGA <	or	es:[di],al						>
MEGA <	pop	ax, cx, dx						>

CGS_skipWrite:
	;
	; Skip to next byte.
	; For bitmap drivers (HGC, CGA) add in bits from previous byte.
	;
BIT <	mov	dl,ah			;;dl = extra bits		>
	inc	di			; move to next byte.
	inc	bx			;increment byte offset for clipping
	dec	ch			;do all bytes
	LONG jnz CGS_writeLoop		;
CGS_afterWrite:
NMEM <	NextScanMod	di, CGS_nextScanOffset				>
MEM  <	pop	di			; restore scan line start	>
MEM  <	NextScan di			; bump to next scan line	>

	; for vidmem, we need to bump the pointers for the clustered dither
ifndef IS_CLR24
ifdef IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CGS_monoSkipClus					>
	mov	si, cs:[CGS_ditherBase]	
	xchg	bp, bx
	NextDitherScan 	
	xchg	bp, bx	
	mov	cs:[CGS_ditherBase], si	
MONO <CGS_monoDoneClus:							>
endif
endif
CGS_afterLine:
	pop	ds			;
	assume	ds:dgroup
	pop	si			;
	;
	; on bitmap driver we need to advance to the next pattern byte.
	;
ifndef IS_MEM
BIT <	inc	bp			;;increment pattern pointer	>
BIT <	and	bp,7							>
endif

	dec	cs:[linesToDraw]	;one less line to draw.
	jz	CGS_end			;quit if none left.
	jmp	CGS_lineLoop		;else loop to do the next one.
CGS_end:				;
	pop	ax
	jmp	PSL_afterDraw

ifndef IS_CLR24
ifdef	IS_MEM
MONO <CGS_normalDither:							>
MONO <	mov	al, {byte} cs:[bp][ditherMatrix] ;al = pattern 		>
MONO <	jmp	monoCont						>
MONO <CGS_monoSkipClus:							>
MONO <	inc	bp							>
MONO <	and	bp, 7							>
MONO <	jmp	CGS_monoDoneClus					>
endif
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	CharGeneralRealSlow

DESCRIPTION:	Draw a character that is possibly clipped and is in a
		pattern.

CALLED BY:	INTERNAL
		CharGeneral

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
	bytesToDraw - number of bytes to draw
	extraBytesToDraw - number of bytes to draw - number of bytes to load
	shiftCount - number of times to shift right
	linesToDraw - number of lines to draw
	currentWin - segment of window
	currentLine - first line to draw
	charByteOffset - first line to draw
	bp - BITMAP - pattern index
	     EGA - GR_CONTROL
	cx - number to use with NextScanReg to move to next line
	ds:si - character data
	es:di - screen position

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@

CGRS_getDrawMask:
	;
	; Get the draw-mask.
	;
	push	ds			;
	push	ax			;
	mov	ds,cs:[PSL_saveGState]	;
	mov	ax, {word} ds:[GS_textAttr.CA_mask]
	mov	{word} cs:[drawMask], ax
	mov	ax, {word} ds:[GS_textAttr.CA_mask+2]
	mov	{word} cs:[drawMask+2], ax
	mov	ax, {word} ds:[GS_textAttr.CA_mask+4]
	mov	{word} cs:[drawMask+4], ax
	mov	ax, {word} ds:[GS_textAttr.CA_mask+6]
	mov	{word} cs:[drawMask+6], ax
	pop	ax			;
	pop	ds			;
	jmp	short CGRS_afterMask	;

;----------------------------------------------------
; special case: line entirely clipped
;		skips 'bytesToDraw' bytes in the character definition to get
;		to the next char line to draw.
CGRS_lineClipped:
;	mov	ch,cs:[bytesToDraw]		;load and fall thru
;	mov	cl,ch

	mov	cl,cs:[bytesToDraw]		;load and fall thru
	clr	ch
	add	di,cx
	jmp	CGRS_afterWrite

;----------------------------------------------------
CharGeneralRealSlow	label  near
	mov	cs:[currentWin],ds	;save segment of window.
	mov	cs:[currentLine],bx	;save current line of character.
	jmp	short CGRS_getDrawMask	;
CGRS_afterMask:
	call	CalcCharVars		;calculate drawing variables
	mov	bp, bx			;
	and	bp, 7			;bp <- index into drawMask.
NMEM <	StoreNextScanMod	<cs:[CGRS_nextScanOffset]>,cx		>

	; for vidmem, we probably need to do some extra work for clustered
	; dithers
ifndef	IS_CLR24
ifdef	IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CGRS_skipClustered					>
	InitDitherIndex bp
	mov	cs:[CGRS_ditherBase], bp		
	mov	bp, bx				
MONO <CGRS_skipClustered:						>
endif
endif

CGRS_lineLoop:				;
	call	SlowReadLine		; read data into lineDataBuffer
	push	si			; save ptr to character data.
	push	ds			; save segment of window.
	;
	; Check for clipping which requires special setup
	;
	mov	bx,cs:[currentLine]	; bx <- current character line.
	inc	cs:[currentLine]	; advance to next one.
	tst	bx			; check for scan line off screen.
EGA <	LONG js	CGRS_afterLine		; skip to next one if it is.	>
BIT <	LONG js	CGRS_afterLine		; skip to next one if it is.	>
MEM <	push	di							>
ifndef IS_CLR24
ifdef   IS_MEM
	mov	cx, bx			; save it
	and	bx, 7
	mov	bl, cs:[bx][drawMask]
	mov	cs:[CGRS_mask], bl
	mov	bx, cx			; restore it
endif
endif
	call	SlowGenClip		; make sure clip info is correct
	LONG jc	CGRS_lineClipped	;
	;
	; Init for line
	;
	mov	cx,cs			; ds <- driver segment.
	mov	ds,cx			;
	assume	ds:@CurSeg
	mov	si, offset lineDataBuffer ; si <- offset to char line
					;       data.
	mov	bx,ds:[charByteOffset]	; bx <- offset to char data.
	mov	cl,ds:[shiftCount]	; cl <- amount to shift data.
	mov	ch,ds:[bytesToDraw]	; ch <- number of bytes of char data.
	clr	dl			;no bits from last byte
	;
	; Loop for each byte -- load byte
	;
CGRS_writeLoop:
	lodsb				;al = mask, ah = extra data
	clr	ah			;
	ror	ax,cl			;ax = mask shifted correctly
					;
	or	al,dl			;ax = mask with all bits correct
EGA <	mov	dl,ah			;;dl = extra bits		>
	;
	; Clip byte
	;
	tst	bx			;test for byte not on screen
	LONG js	CGRS_skipWrite		;skip to next byte if it is.
NMEM <	cmp	bx,SCREEN_BYTE_WIDTH	;check for off screen left.	>
MEM  <	cmp	bx,cs:[bm_bpScan]	;check for off screen left.	>
	jl	CGRS_notEOLN		;skip to next line if it is.
	mov	cl,ch			;
	clr	ch			;
	add	di,cx			;
	jmp	CGRS_afterWrite		;
CGRS_notEOLN:				;

	; for the memory video driver, the lineMaskBuffer is stored as part
	; of the bitmap...

MEM  <	push	bx,ds			; save some regs		>
MEM  <	mov	ds, cs:[bm_segment]	; get window segment		>
MEM  <	add	bx, size EditableBitmap ;				>
MEM  <	and	al, ds:[bx]  		; mask with region.		>
MEM  <	pop	bx,ds			; save some regs		>

	; ...whereas it is in a fixed location for other drivers

NMEM <	and	al,ds:[bx][lineMaskBuffer]  ; mask with region.		>

	; Bitmap drivers (CGA, HGC, etc, but NOT MEGA).
	; screen <- ! ((!screen & !mask) | (data & !pattern & mask))
	; screen <- screen & !(data & mask) | (data & pattern & mask)
	;
ifndef IS_MEGA
ifndef IS_CLR24
ifdef IS_MEM
CGRS_mask equ (this byte) + 1
	and	al, 12h
else
BIT <	and	al, {byte} cs:[bp][drawMask]		;		>
endif
BIT <	mov	dl, al			; 				>
BIT <	not	dl			;				>
BIT <	and	es:[di],dl		; 				>
CMYK <	mov	bp, cs:[bm_bpPlane]					>
CMYK <	and	es:[bp][di], dl		; cyan plane			>
CMYK <	shl	bp, 1			; magenta plane			>
CMYK <	and	es:[bp][di], dl						>
CMYK <	add	bp, cs:[bm_bpPlane]
CMYK <	and	es:[bp][di], dl						>
ifdef	IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CGRS_normalDither					>
	push	si
CGRS_ditherBase equ (this word) + 1				
	mov	si, 1234h						
CMYK <	push	bx							>
	mov	dl, al
	NextDitherByte   , bp
	and	al, dl
	BumpDitherIndex bp						
CMYK <	pop	bx							>
	pop	si							
MONO <CGRS_monoDitherContinue:						>
else
BIT <	and	al, {byte} cs:[bp][ditherMatrix]	 ;		>
endif
BIT <	or	es:[di], al		;				>
ifdef IS_CMYK
	mov	bp, cs:[bm_bpPlane]		; do other planes 	>
	mov	al, {byte} cs:[cyanWord]
	and	al, dl
	or	es:[bp][di], al			; update cyan
	mov	al, {byte} cs:[magentaWord]
	and	al, dl
	shl	bp, 1
	or	es:[bp][di], al			; update magenta
	add	bp, cs:[bm_bpPlane]
	mov	al, {byte} cs:[blackWord]
	and	al, dl
	or	es:[bp][di], al			; update black
endif
endif
endif
	;
	; Color EGA type drivers.
	; Write byte and mask all at once to the EGA card.
	;
CEGA <	mov	ah,al							>
CEGA <	and	ah,{byte}ds:[bp][drawMask]				>
CEGA <	mov	al,BITMASK						>
CEGA <	push	dx							>
CEGA <	mov	dx,GR_CONTROL						>
CEGA <	out	dx,ax							>
CEGA <	pop	dx							>
CEGA <	or	es:[di],al						>
	;
	; Monochrome EGA type drivers.
	; Blast out the white pixels first, then reverse the mask
	; and blast out the black pixels.  This works correctly
	; in inverse mode as well.
	;
MEGA <	push	ax, cx, dx						>
MEGA <	xchg	cx, ax							>
MEGA <	mov	dx, GR_CONTROL						>
MEGA <	clr	al							>
MEGA <	mov	ah, 0xff						>
MEGA <	out	dx, ax							>
MEGA <	mov	ah, {byte} cs:[bp][ditherMatrix]			>
MEGA <	and	ah,{byte}ds:[bp][drawMask]				>
MEGA <	and	ah, cl							>
MEGA <	mov	al,BITMASK						>
MEGA <	out	dx,ax							>
MEGA <	or	es:[di],al						>
MEGA <	clr	ax							>
MEGA <	out	dx, ax							>
MEGA <	mov	ah, {byte} cs:[bp][ditherMatrix]			>
MEGA <	not	ah							>
MEGA <	and	ah,{byte}ds:[bp][drawMask]				>
MEGA <	and	ah, cl							>
MEGA <	mov	al,BITMASK						>
MEGA <	out	dx,ax							>
MEGA <	or	es:[di],al						>
MEGA <	pop	ax, cx, dx						>

CGRS_skipWrite:
	;
	; Skip to next byte.
	; For bitmap drivers (HGC, CGA) add in bits from previous byte.
	;
BIT <	mov	dl,ah			;;dl = extra bits		>
	inc	di			; move to next byte.
					;
	inc	bx			;increment byte offset for clipping
	dec	ch			;do all bytes
	LONG jnz CGRS_writeLoop		;
CGRS_afterWrite:
NMEM <	NextScanMod	di, CGRS_nextScanOffset				>
MEM  <	pop	di							>
MEM  <	NextScan	di						>

	; for vidmem, we need to bump the pointers for the clustered dither
ifndef	IS_CLR24
ifdef IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CGRS_monoSkipClus					>
	mov	si, cs:[CGRS_ditherBase]	
	xchg	bp, bx
	NextDitherScan 	
	xchg	bp, bx	
	mov	cs:[CGRS_ditherBase], si	
MONO <CGRS_monoDoneClus:						>
endif
endif
CGRS_afterLine:
	pop	ds			;
	assume	ds:dgroup
	pop	si			;
	;
	; advance to the next pattern byte.
	;
NMEM <	inc	bp			;increment pattern pointer	>
NMEM <	and	bp,7							>

	dec	cs:[linesToDraw]	;one less line to draw.
	jz	CGRS_end		;quit if none left.
	jmp	CGRS_lineLoop		;else loop to do the next one.
CGRS_end:				;
	pop	ax
	jmp	PSL_afterDraw
ifndef IS_CLR24
ifdef IS_MEM
MONO <CGRS_normalDither:						>
MONO <	and	al, {byte} cs:[bp][ditherMatrix] ;al = pattern 		>
MONO <	jmp	CGRS_monoDitherContinue					>
MONO <CGRS_monoSkipClus:						>
MONO <	inc	bp							>
MONO <	and	bp, 7							>
MONO <	jmp	CGRS_monoDoneClus					>
endif
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	CharGeneralFast

DESCRIPTION:	Draw a character that is not clipped and is not in outline

CALLED BY:	INTERNAL
		CharGeneral

PASS:
	ax - x position
	bx - top line to draw
	ds - Window structure
	es:si = character data
	ditherMatrix - set
	on stack - new x position

RETURN:
	ax - new x position popped from stack

DESTROYED:
	bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:
	bytesToDraw - number of bytes to draw
	extraBytesToDraw - number of bytes to draw - number of bytes to load
	shiftCount - number of times to shift right
	linesToDraw - number of lines to draw
	bp - BITMAP - pattern index
	     EGA - GR_CONTROL
	cx - number to use with NextScanReg to move to next line
	ds:si - character data
	es:di - screen position

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@

CharGeneralFast	label  near
	ForceRef	CharGeneralFast
	.warn	-unreach
	call	CalcCharVars		;calculate drawing variables
	.warn	@unreach
NMEM <	StoreNextScanMod	<cs:[CGF_nextScanOffset]>,cx		>

	; for vidmem, we probably need to do some extra work for clustered
	; dithers
ifndef IS_CLR24
ifdef	IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CGF_skipClustered					>
	InitDitherIndex bp
	mov	cs:[CGF_ditherBase], bp		
	mov	bp, bx				
MONO <CGF_skipClustered:						>
endif
endif
	mov	bl,cs:[linesToDraw]	;bl <- number of char lines to draw.

CGF_lineLoop:
	;
	; Init for each line.
	;
MEM <	push	di							>
	mov	cl,cs:[shiftCount]	;cl <- amount to shift italic.
	mov	ch,cs:[bytesToDraw]	;ch <- bytes on each line.
	clr	dl			;no bits from last byte
	;
	; Loop for each byte -- load byte
	;
CGF_writeLoop:
	clr	al			;
	cmp	ch,cs:[extraBytesToDraw]
	jbe	CGF_extra		;
	lodsb				;al = mask, ah = extra data
CGF_extra:
	clr	ah			;clear extra rotated bits
	ror	ax,cl			;ax = mask shifted correctly
	or	al,dl			;ax = mask with all bits correct
	;
	; For bitmap drivers (CGA, HGC).
	; screen <- (screen & !mask) | (data & mask)
	;
ifndef IS_MEGA

BIT <	mov	dh,al							>
ifndef IS_CLR24
ifdef IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CGF_normalDither					>
	push	si
CGF_ditherBase equ (this word) + 1				
	mov	si, 1234h						
CMYK <	push	bx							>
	NextDitherByte si, bp
	and	al, dh
	BumpDitherIndex bp						
CMYK <	pop	bx							>
	pop	si							
MONO <CGF_monoDitherContinue:						>
else
BIT <	and	al, {byte} cs:[bp][ditherMatrix] ;al = pattern 		>
endif
endif
BIT <	not	dh			;;dh = NOT mask			>
BIT <	mov	dl,es:[di]		;;dl = screen			>
BIT <	and	dl,dh			;;dl = NOT mask AND screen	>
BIT <	or	al,dl			;;al = data to store		>
BIT <	stosb								>
ifdef IS_CMYK
	not	dh
	dec	di
	mov	bp, cs:[bm_bpPlane]	; onto cyan
	mov	al, {byte} cs:[cyanWord]
	and	al, dh
	not	dh
	mov	dl, es:[bp][di]		; get cyan byte
	and	dl, dh
	not	dh
	or	al, dl
	mov	es:[bp][di], al
	shl	bp, 1			; on to magenta
	mov	al, {byte} cs:[magentaWord]
	and	al, dh
	not	dh
	mov	dl, es:[bp][di]
	and	dl, dh
	not	dh
	or	al, dl
	mov	es:[bp][di], al
	add	bp, cs:[bm_bpPlane]	; onto black
	mov	al, {byte} cs:[blackWord]
	and	al, dh
	not	dh
	mov	dl, es:[bp][di]
	and	dl, dh
	not	dh
	or	al, dl
	mov	es:[bp][di], al
	inc	di
endif
BIT <	mov	dl,ah			;;dl = extra bits		>

endif
	;
	; For EGA type drivers.
	; Set mask and value to store and write it out all at once.
	;
CEGA <	mov	dl,ah			;;dl = extra bits		>
CEGA <	mov	ah,al							>
CEGA <	mov	al,BITMASK						>
CEGA <	xchg	dx,bp							>
CEGA <	out	dx,ax							>
CEGA <	xchg	dx,bp							>
CEGA <	or	es:[di],al						>
CEGA <	inc	di							>
	
MEGA <	push	ax, cx, dx						>
MEGA <	xchg	cx, ax							>
MEGA <	mov	dx, GR_CONTROL						>

MEGA <	clr	al							>
MEGA <	mov	ah, 0xff						>
MEGA <	out	dx, ax							>

MEGA <	mov	ah, {byte} cs:[bp][ditherMatrix]			>
MEGA <	and	ah, cl							>
MEGA <	mov	al,BITMASK						>
MEGA <	out	dx,ax							>
MEGA <	or	es:[di],al						>

MEGA <	clr	ax							>
MEGA <	out	dx, ax							>

MEGA <	mov	ah, {byte} cs:[bp][ditherMatrix]			>
MEGA <	not	ah							>
MEGA <	and	ah, cl							>
MEGA <	mov	al,BITMASK						>
MEGA <	out	dx,ax							>
MEGA <	or	es:[di],al						>

MEGA <	clr	al							>
MEGA <	mov	ah, 0xff						>
MEGA <	out	dx, ax							>

MEGA <	pop	ax, cx, dx						>
MEGA <	mov	dl,ah			;;dl = extra bits		>
MEGA <	inc	di							>

	dec	ch			;one less byte to do.
	LONG jnz CGF_writeLoop		;loop to write out the next one.

NMEM <	NextScanMod	di, CGF_nextScanOffset				>
MEM  <	pop	di							>
MEM  <	NextScan	di						>

	; for vidmem, we need to bump the pointers for the clustered dither
ifndef IS_CLR24
ifdef IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CGF_monoSkipClus					>
	mov	si, cs:[CGF_ditherBase]	
	xchg	bp, bx
	NextDitherScan 	
	xchg	bp, bx	
	mov	cs:[CGF_ditherBase], si	
MONO <CGF_monoDoneClus:							>
endif
endif
	;
	; For bitmap drivers.
	; Advance to the next pattern byte.
	;
ifndef	IS_MEM
BIT <	inc	bp			;;increment pattern pointer	>
BIT <	and	bp,7							>
endif
	
	dec	bl			;one less line to do.
	jz	CGF_done		;quit if no more.
	jmp	CGF_lineLoop		;else loop to do the next one.
CGF_done:
	pop	ax
	jmp	PSL_afterDraw

ifndef IS_CLR24
ifdef IS_MEM
MONO <CGF_normalDither:							>
MONO <	and	al, {byte} cs:[bp][ditherMatrix] ;al = pattern 		>
MONO <	jmp	CGF_monoDitherContinue					>
MONO <CGF_monoSkipClus:							>
MONO <	inc	bp							>
MONO <	and	bp, 7							>
MONO <	jmp	CGF_monoDoneClus					>
endif
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	CharLarge

DESCRIPTION:	Low level routine to draw a character when the source is
		X bytes wide and the destination is Y bytes wide, the drawing
		mode in GR_COPY and the character is entirely visible.

CALLED BY:	INTERNAL
		CharLowFast

PASS:
	al - (bytes to load - 1) * 8
	ah - (bytes to draw - 1) * 2
	ds:si - character data
	es:di - screen position
	bx - pattern index
	cl - shift count
	ch - number of lines to draw
	on stack - ax

RETURN:
	ax - popped off stack

DESTROYED:
	ch, dx, bp, si, di

REGISTER/STACK USAGE:
	al - mask
	ah - NOT mask
	dl - temporary

PSEUDO CODE/STRATEGY:
	dest = (mask AND pattern) or (NOT mask AND screen)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@

CharLarge label near
	shr	al,1			;
	shr	al,1			;
	shr	al,1			;
	inc	al			;al = bytes to load
					;
	shr	ah,1			;
	inc	ah			;ah = bytes to draw
	mov	cs:[bytesToDraw],ah	;save.
	sub	ah,al			;
	mov	cs:[extraBytesToDraw],ah
					;
	mov	al,cs:[bytesToDraw]	;bytes to draw
	clr	ah			;
	neg	ax			;
NMEM <	StoreNextScanMod	<cs:[CL_nextScanOffset]>,ax		>

	; for vidmem, we probably need to do some extra work for clustered
	; dithers
ifndef IS_CLR24
ifdef	IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CL_skipClustered					>
	InitDitherIndex bp
	mov	cs:[CL_ditherBase], bp		
	mov	bp, bx				
MONO <CL_skipClustered:							>
else
	;
	; For bitmap drivers : set ptr to pattern and count of number of
	;	lines to do.
	;
MEGA <	push	bx			; save pattern counter		>
BIT <	mov	bp,bx			;;bp = pattern pointer		>
endif
endif


BIT <	mov	dl,ch			;line count			>
	;
	; For EGA drivers : bp = number of lines to do.
	;
EGA <	mov	al,ch			;;bp = line count		>
EGA <	clr	ah							>
EGA <	mov	bp,ax							>

CL_lineLoop:
		; for vidmem, we need to always start at the beginning of the
		; scan line.
MEM <	push	di							>
	mov	bx,word ptr cs:[bytesToDraw] ;bl = bytes to draw, bh = extra
	clr	ch			;clear extra bits
CL_loop:
	clr	al			;assume this is an exra byte
	cmp	bl,bh			;
	jbe	CL_extra		;
	lodsb				;al = mask, ah = extra data
CL_extra:
	clr	ah			;
	ror	ax,cl			;ax = mask shifted correctly
	or	al,ch			;;ax = mask with all bits correct
	;
	; For bitmap drivers :
	;	screen <- (screen & !mask) | (data & mask)
	;
ifndef IS_MEGA

BIT <	mov	dh,al							>
ifndef IS_CLR24
ifdef IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CL_normalDither					>
	push	si
CL_ditherBase equ (this word) + 1				
	mov	si, 1234h						
CMYK <	push	bx							>
	NextDitherByte  , bp
	and	al, dh
	BumpDitherIndex bp						
CMYK <	pop	bx							>
	pop	si							
MONO <CL_monoDitherContinue:						>
else
BIT <	and	al, {byte} cs:[bp][ditherMatrix] ;al = pattern 		>
endif
endif
BIT <	not	dh			;;dh = NOT mask			>
BIT <	mov	ch,es:[di]		;;dl = screen			>
BIT <	and	ch,dh			;;dl = NOT mask AND screen	>
BIT <	or	al,ch			;;al = data to store		>
BIT <	stosb								>
ifdef IS_CMYK
	not	dh
	dec	di
	mov	bp, cs:[bm_bpPlane]	; onto cyan
	mov	al, {byte} cs:[cyanWord]
	and	al, dh
	not	dh
	mov	ch, es:[bp][di]		; get cyan byte
	and	ch, dh
	not	dh
	or	al, ch
	mov	es:[bp][di], al
	shl	bp, 1			; on to magenta
	mov	al, {byte} cs:[magentaWord]
	and	al, dh
	not	dh
	mov	ch, es:[bp][di]
	and	ch, dh
	not	dh
	or	al, ch
	mov	es:[bp][di], al
	add	bp, cs:[bm_bpPlane]	; onto black
	mov	al, {byte} cs:[blackWord]
	and	al, dh
	not	dh
	mov	ch, es:[bp][di]
	and	ch, dh
	not	dh
	or	al, ch
	mov	es:[bp][di], al
	inc	di
endif
BIT <	mov	ch,ah			;;ch = extra bits		>

endif
	;
	; For ega drivers :
	;	Set data and mask. Write them out together.
	;
CEGA <	mov	ch,ah			;;ch = extra bits		>
CEGA <	mov	ah,al							>
CEGA <	mov	al,BITMASK						>
CEGA <	out	dx,ax							>
CEGA <	or	es:[di],al						>
CEGA <	inc	di							>

MEGA <	pop	dx		; recover pattern counter		>
MEGA <	push	si		; save lodsb offset			>
MEGA <	push	ax, cx							>
MEGA <	xchg	cx, ax							>

MEGA <	mov	si, dx							>
MEGA <	and	si, 7							>
MEGA <	mov	dx, GR_CONTROL						>

MEGA <	clr	al							>
MEGA <	mov	ah, 0xff						>
MEGA <	out	dx, ax							>

MEGA <	mov	ah, {byte} cs:[si][ditherMatrix]			>
MEGA <	and	ah, cl							>
MEGA <	mov	al,BITMASK						>
MEGA <	out	dx,ax							>
MEGA <	or	es:[di],al						>

MEGA <	clr	ax							>
MEGA <	out	dx, ax							>

MEGA <	mov	ah, {byte} cs:[si][ditherMatrix]			>
MEGA <	not	ah							>
MEGA <	and	ah, cl							>
MEGA <	mov	al,BITMASK						>
MEGA <	out	dx,ax							>
MEGA <	or	es:[di],al						>

MEGA <	pop	ax, cx							>

MEGA <	mov	dx, si							>
MEGA <	pop	si		; recover lodsb offset			>
MEGA <	push	dx		; save pattern index			>

MEGA <	mov	ch,ah		;;ch = extra bits			>
MEGA <	inc	di							>

	dec	bl		;one less byte to do.
	LONG jnz CL_loop		;loop to do next byte.
	;
	; For bitmap drivers :
	;	Must advance ptr into the patter.
	;	Force index to be 0...7 since patterns are all 8 bytes.
	;
MEGA <	pop	dx		;recover pattern index			> 
MEGA <	inc	dx							>
MEGA <	push	dx							>

ifndef IS_MEGA
ifndef IS_MEM
BIT <	inc	bp			;;increment pattern pointer	>
BIT <	and	bp,7							>
endif
endif

NMEM <	NextScanMod	di, CL_nextScanOffset				>
MEM  <	pop	di							>
MEM  <	NextScan	di						>

	; for vidmem, we need to bump the pointers for the clustered dither
ifndef IS_CLR24
ifdef IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER			>
MONO <	jz	CL_monoSkipClus					>
	push	si
	mov	si, cs:[CL_ditherBase]	
	xchg	bp, bx
	NextDitherScan 	
	xchg	bp, bx	
	mov	cs:[CL_ditherBase], si	
	pop	si
MONO <CL_monoDoneClus:							>
endif
endif

	;
	; One less line to do.
	;
ifndef IS_MEGA
BIT <	dec	dl							>
endif

EGA <	dec	bp							>
	LONG jnz CL_lineLoop		;loop to do next line.
					;
MEGA <	pop	dx			; get rid of pattern index	>
	pop	ax
	jmp	PSL_afterDraw

ifndef IS_CLR24
ifdef IS_MEM
MONO <CL_normalDither:							>
MONO <	and	al, {byte} cs:[bp][ditherMatrix] ;al = pattern 		>
MONO <	jmp	CL_monoDitherContinue					>
MONO <CL_monoSkipClus:							>
MONO <	inc	bp							>
MONO <	and	bp, 7							>
MONO <	jmp	CL_monoDoneClus					>
endif
endif
CharCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CalcCharVars

DESCRIPTION:	Calculate lots of information about the character that is
		about to be drawn.

CALLED BY:	INTERNAL
		CharGeneral

PASS:
	ax - x position
	bx - top line to draw
	cx - right edge of character to draw
	dx - bottom line to draw
	ds - Window structure
	es:si = character data
	ditherMatrix - set

RETURN:
	bytesToDraw - number of bytes to draw
	extraBytesToDraw - number of bytes to draw - number of bytes to load
	shiftCount - number of times to shift right
	linesToDraw - number of lines to draw
	currentWin - segment of window
	currentLine - first line to draw
	charByteOffset - byte offset into scan line
	bp - BITMAP - pattern index
	     EGA - GR_CONTROL
	cx - number to use with NextScanReg to move to next line
	ds:si - character data
	es:di - screen position

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@

CalcCharVars	proc	near
	mov	bp,ax				; save x position
ifndef	MEM_CLR4
	sar	ax,1				;calculate left byte index
	sar	ax,1				;shift in from high bit
endif
	sar	ax,1				;(arithmetic shift)
	mov	cs:[charByteOffset],ax		;save offset for line.
	;
	; cx = right byte offset
	;
ifndef	MEM_CLR4
	shr	cx, 1				;cx = right, calc byte offset
	shr	cx, 1				;
endif
	shr	cx, 1				;
	sub	cx, ax				;cx = #bytes to draw - 1
	;
	; set up shift count and #lines
	;
	xchg	ax, bp				; ax = xpos, bp = byte pos
ifdef	MEM_CLR4
	and	al, 1
else
	and	al, 7				;al = shift count for one byte.
endif
	mov	cs:[shiftCount],al		;
	sub	dx,bx				;
	inc	dx				;
	mov	cs:[linesToDraw],dl		;
	;
	; set up screen offset
	;
	mov	di,bx				;di - first line to draw
	tst	di				;make sure that it is on-screen
	jns	CCV_notAboveScreen		;
	clr	di				;
CCV_notAboveScreen:
NMEM <	CalcScanLine	di,bp		;di = screen offset with bp added in >
	;
	; set up segment registers
	;
	segmov	ds,es,ax			;ds -> font
	SetBuffer es,ax				;es -> screen
MEM  <  CalcScanLine	di,bp,es					>
	;
	; For bitmaps, set offset into the pattern.
	;
ifdef	MEM_CLR4
	and	bx, 6
else
BIT <	and	bx,7			;;bx = pattern index		>
endif
BIT <	mov	bp,bx			;;bp = pattern index		>
	;
	; For EGA, set to a constant used to control the EGA.
	;
EGA <	mov	bp,GR_CONTROL						>
	;
	; calculate number of bytes to draw to
	;
	inc	cx			;cx = # of bytes to draw
	mov	cs:[bytesToDraw],cl	;
	mov	ah,cl			;ah = bytes to draw
	neg	cx			;cx = offset on next scan line
					;
	lodsb				;al = picture width (bits)
	add	al,7			;
	shr	al,1			;
	shr	al,1			;
	shr	al,1			;
	sub	ah,al			;ah = extra bytes
	mov	cs:[extraBytesToDraw],ah
					;
	add	si,CD_data-1		;ds:si = data
					;
	ret				;

CalcCharVars	endp
