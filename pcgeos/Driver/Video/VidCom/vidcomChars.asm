COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Common video driver
FILE:		vidcomChars.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB VidPutString		Draw a string of characters. Draws until
				the maximum number of characters requested
				is drawn, or until a NULL byte is reached
				in the string.
    INT PutStringLow		PutString, the second half. At this point a
				lot of preprocessing has been done.
				Checking against clip regions, mapping of
				colors to patterns, etc. The routine to do
				the drawing has been determined (and is in
				di). This routine loops printing characters
				in the given font/style/pattern/color until
				it reaches a NULL byte or prints the
				desired number of characters. In addition
				PutString() has modified several pieces of
				the code in this routine in order to
				maximize the speed of drawing.
    INT SetComplex		Set up variables for the complex character
				drawing routine
    INT CharCommon		Pseudo-function for SWAT since these
				routines mess with the stack alot
    INT KernChar		Kern a pair of characters by adjusting the
				position at which the second character
				should be drawn.
    INT SlowReadLine		Read a line of character data into
				lineDataBuffer
    INT CalcCharVars		Calculate lots of information about the
				character that is about to be drawn.
    INT SetupRegion		Make self-modifications for region
				characters.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	jeremy	5/91		Added support for mono EGA

DESCRIPTION:
	This file contains character output routines common to all video
drivers.
	
	$Id: vidcomChars.asm,v 1.1 97/04/18 11:41:53 newdeal Exp $

------------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

FUNCTION:	VidPutString

DESCRIPTION:	Draw a string of characters. Draws until the maximum number
		of characters requested is drawn, or until a NULL byte is
		reached in the string.

CALLED BY:	GLOBAL

PASS:
	ax.dl - x position (WBFixed, device coords)
	bx.dh - y position (WBFixed, device coords)
	cx - seg addr of font
	ss:bp - ptr to VPS_params structure on stack
	  VPS_numChars - max # of characters to draw
	  VPS_stringSeg - segment of string to draw
	si - offset of string to draw
	es - seg addr of window (Window)
	ds - graphics state structure (GState)
	  GS_textAttr.CA_colorIndex (byte) - color in index form.
	  GS_textAttr.CA_colorRGB (3 bytes) - color in R, G, B form.
	  GS_textAttr.CA_mapMode (byte) - color mapping mode.

RETURN:
	ax.dl - x position for next char
	bx.dh - y position for next char
	si - pointing after last character drawn
	bp - seg addr of font (may have moved)
	es - seg addr of Window (may have moved)

DESTROYED:
	cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	Jim	4/6/88		Don't look at me, I just added the ShiftPattern
				stuff.
	Gene	5/89		Added checks for unbuilt characters.
	Gene	6/89		Added checks for complex tranforms.
	John	16-Nov-89	Added support for optional hyphens.
	Gene	1/90		Removed styles, updated optimizations

------------------------------------------------------------------------------@

VidPutString	proc	near

	; Save registers needed later.  These variables are all in self
	; modified code in PutStringLow

	mov	cs:[PSL_saveYPos],bx
	mov	cs:[PSL_saveGState],ds
	mov	cs:[fracPosition], dl
	mov	cs:[fracYPosition], dh
	mov	cs:[PSL_saveFont], cx		;save font seg
	mov	cs:[PSL_saveWindow], es		;save window seg
	mov	dx, ss:[bp].VPS_stringSeg
	mov	cs:[PSL_saveStringSeg], dx	;save string seg

SBCS <	mov	cx, ss:[bp].VPS_numChars	;cx <- # chars to draw	>

	;
	; Setup the ditherMatrix, if need be.  And the EGA hardware.

	CheckSetDither	cs, GS_textAttr

ifdef IS_MONO
ifdef IS_MEM
	;
	;  If the mix mode doesn't depend on the source, then we don't
	;  want to dither
	;

	cmp	ds:[GS_mixMode], MM_COPY
	jne	checkFunkyMixMode

afterDither:
endif
endif
	; Self modify PutStringLow for various cases
	; self modifications for first and last character in font
	;
if DBCS_PCGEOS
	push	ds
	mov	ds, cx				;ds <- seg addr of font
	mov	dx, ds:FB_firstChar
	mov	di, es				;di <-  window (interleaved)
	mov	cs:CLF_firstChar, dx
	mov	dx, ds:FB_lastChar
	mov	cs:CLF_lastChar, dx
	pop	ds
	mov	cx, ss:[bp].VPS_numChars	;cx <- # chars to draw
else
	mov	dx, {word}ds:GS_fontFirstChar	;dl <- firstChar
						;dh <- lastChar
	mov	cs:CLF_firstChar, dl
	mov	di, es				;di <-  window (interleaved)
	mov	cs:CLF_lastChar, dh
endif

	;
	; minimum left side bearing for fast vs. almost fast check.
	; minimum top side bound for fast vs. slow check.
	;
	mov	dx, ds:GS_minLSB
	mov	cs:VPS_minLSB, dx

	;
	; self modification for drawing control-characters
	;
	mov	dl, ds:GS_drawCtrlOpcode
	mov	cs:PSL_checkMapCtrlOp, dl
	mov	cs:PSL_checkCtrlAdjustOpcode, dl

	;
	; self modification for textDrawOffset.
	;
	mov	dl, ds:GS_drawOffsetOpcode
	mov	cs:PSL_drawOffsetOp, dl
	
	mov	dx, ds:GS_textDrawOffset
	mov	cs:CLE_drawOffset, dx

	;
	; self modification for soft-hyphens
	;
	mov	dl, ds:GS_hyphenOpcode		;dl <- hyphen opcode
	mov	cs:PSL_hyphenOp, dl

	;
	; self modification for space padding (full justified only)
	;
	mov	dl, ds:GS_optSpacePad		;dl <- space opcode
	mov	cs:PSL_spaceOpcode, dl		;save opcode
	cmp	dl, GO_SPECIAL_CASE
	jne	VPS_afterPad			;additional work if padding
if CHAR_JUSTIFICATION
	mov	dl, ds:GS_optFullJust		;dl <- full justification opcode
	mov	cs:PSL_fullJustOpcode, dl	;save opcode
endif
	mov	dl, ds:GS_textSpacePad.WBF_frac	;dl <- fractional padding
	mov	cs:PSL_spacePadFrac, dl
	mov	dx, ds:GS_textSpacePad.WBF_int	;dx <- integer padding
	mov	cs:PSL_spacePad, dx
VPS_afterPad:
	test	ds:GS_fontFlags, mask FBF_IS_REGION
	jz	VPS_afterRegion
	jmp	SetupRegion

ifdef	IS_MEM
ifdef	IS_MONO
checkFunkyMixMode:

	mov	dl, ds:[GS_mixMode]

	;
	;  If the MixMode is either MM_SET, MM_CLEAR, or MM_INVERT,
	;  then we want SDM_100
	;
	cmp	dl, MM_SET
	je	nukeDither

	cmp	dl, MM_CLEAR
	je	nukeDither

	cmp	dl, MM_INVERT
	jnz	afterDither

nukeDither:

	mov	dx, 0xffff
	mov	{word} cs:[ditherMatrix]+0, dx
	mov	{word} cs:[ditherMatrix]+2, dx
	mov	{word} cs:[ditherMatrix]+4, dx
	mov	{word} cs:[ditherMatrix]+6, dx
	jmp	afterDither
endif
endif

VPS_afterRegion:

	;
	; Do not move either the complex or kerning self-modification
	; checks. Either may go vaulting off to do the complex case,
	; so any other self-modifications should be done before this
	; point.
	;
	; self modifications for complex vs. simple transforms
	; self-modifications for kerning/no kerning
	;
	mov	dx, {word}ds:GS_complexOpcode	;dl <- complex opcode
						;dh <- kerning opcode
	mov	cs:PSL_complexOp1, dl
	mov	cs:PSL_complexOp2, dl
	mov	cs:CLF_kernOp, dh
	mov	cs:CLC_kernOp, dh
	cmp	dh, GO_SPECIAL_CASE
	jne	VPS_afterKern			;additional work if kerning
	push	ax
	mov	cs:lastChar,0			;no kerning char
	mov	cs:lastFlags,0			;no kerning flags
	mov	al, ds:GS_complexOpcode		;al <- complex opcode
	mov	cs:kernComplexOp1, al
	mov	cs:kernComplexOp2, al		;store opcode in kern code
	mov	ax, {word}ds:GS_trackKernValue	;ax <- track kern (BBFixed)
	mov	cs:trackKernFrac, al		;store fraction
	mov	al, ah				;al <- integer
	cbw					;sign extend into ax
	mov	cs:trackKernInt, ax		;store track kerning
	tst	ah				;test sign
	pop	ax
	js	VPS_useComplex			;have go slow with negatives
VPS_afterKern:
	cmp	dl, GO_SPECIAL_CASE		;see if jump stuffed in
	je	VPS_useComplex

	;
	; check for special mask -- need complex
	;
	cmp	ds:[GS_optDrawMask],0
	jnz	VPS_useComplex

	;
	; compute bottom line that character spans
	;
	mov	dx, bx			    	;dx <- starting y coord
	add	dx, ds:GS_pixelHeightM1	    	;add height of font
	mov	bp, ds:GS_minTSB	    	;bp <- minimum coord on top
	neg	bp

	mov	ds,di
	;
	; test for entirely inside mask region (top)
	;
	add	bp, bx			    	;bp <- y coord - min TSB
	cmp	bp,ds:[W_maskRect.R_top]	;if y position < mask top then
	jl	VPS_useComplex			;    not entirely in region.

	;
	; test for entirely inside mask region (bottom)
	;

	cmp	dx,ds:[W_maskRect.R_bottom]	; if bottom > mask bottom then
	jg	VPS_useComplex			;    not completely in region

	;
	; Make sure that clip info is correct. ie: Check to see if the values
	; that were calculated for the previous scan line are not valid for
	; the current one. If the on/off points have changed then we need to
	; call the window code to get the new on/off set.
	;
	mov	di,ds:[W_clipRect.R_bottom]	;
	cmp	bx,di				; if current line is not
	jg	VPS_setClip			; between the top/bottom
	cmp	bx,ds:[W_clipRect.R_top]	; areas in which the on/off
	jge	VPS_afterClip			; points are valid then we
						; must recalculate
						; (VPS_setClip).
	;
	; HandleMem special case -- set clipping variables. The values for the
	;  variables for the current scan line are not the same as they were
	;  for the previous scan line, so we need to re-evaluate them.
	;
VPS_setClip:
	push	ax
	push	si
	call	WinValClipLine
	pop	si
	pop	ax
	mov	di,ds:[W_clipRect.R_bottom]
VPS_afterClip:
	;
	; See if all of character is visible.
	;
	test	ds:[W_grFlags],mask WGF_CLIP_SIMPLE
	jz	VPS_useComplex			; complex if clipped partially.
	cmp	dx,di				; complex if top is in region
	jge	VPS_useComplex			; but bottom (dx) is not.
	;
	; Check for collision with pointer. The driver is responsible for
	; turning off the pointer if it drawing to an area occupied by the
	; pointer. We check against the bounding box of the pointer.
	;

	mov	di,ds:[W_clipRect.R_right]	;self modify one only use of
	mov	cs:[CLF_saveLastON],di		;the GState in CharLowFast

ifdef	IS_MEM
	jmp	VPS_useFast		; no cursor collisions for mem
else

cursorRegRight	=	(this word) + 1
	cmp	ax, 1234h
	jg	VPS_useFast			;drawing to right -> branch
cursorRegBottom	=	(this word) + 2
	cmp	bx, 1234h
	jg	VPS_useFast			;drawing below -> branch
cursorRegTop	=	(this word) + 2
	cmp	dx, 1234h
	jl	VPS_useFast			;drawing above -> branch
cursorRegLeft	=	(this word) + 2
	cmp	di, 1234h
	jl	VPS_useFast			;drawing to left -> branch

endif

VPS_useComplex:
	call	SetComplex
	jmp	VPS_drawIt		;Go do the drawing.

VPS_useAlmostFast:
	mov	dx, cs:VPS_minLSB
	mov	cs:CLFC_minLSB, dx	    	;modify left edge check
	call	SetComplex
	mov	cs:[PSL_saveRoutine],CHAR_LOW_FAST_CH
	jmp	VPS_drawIt		;Go do the drawing.

VPS_useFast:

NMEM <	xchg	cx,di				;save cx in di, cx = lastON >
NMEM <	call	CheckCollisionsDS					>
NMEM < 	mov	cx,di							>
NMEM <	jc	VPS_useComplex			;if collision, use slow case >

	;
	; Test for character past left edge of clipping boundary.
	; Need to check against maximum negative left-side bearing.
	; (ie. some characters go to the *left* of the start position)
	; CharLowFastCh() will also check this value to determine
	; when it can begin using the fast case safely.
	;
VPS_minLSB equ (this word) + 1
	mov	dx, 1234h			;MODIFIED
	add	dx, ax
	cmp	dx, ds:W_clipRect.R_left
	jl	VPS_useAlmostFast		;if before left then branch
	mov	cs:[PSL_saveRoutine],CHAR_LOW_FAST

VPS_drawIt:

	REAL_FALL_THRU	PutStringLow

VidPutString	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	PutStringLow

DESCRIPTION:	PutString, the second half. At this point a lot of
		preprocessing has been done. Checking against clip regions,
		mapping of colors to patterns, etc. The routine to do the
		drawing has been determined (and is in di). This routine
		loops printing characters in the given font/style/pattern/color
		until it reaches a NULL byte or prints the desired number of
		characters. In addition PutString() has modified several
		pieces of the code in this routine in order to maximize
		the speed of drawing.

CALLED BY:	INTERNAL
		VidPutString

PASS:
	ax.fracPosition - x position
	bx.fracYPosition - y position
	cx - maximum number of characters to draw
	si - string offset
	GS_textAttr.CA_colorIndex (byte) - color in index form
	GS_textAttr.CA_colorRGB (3 bytes) - color in R, G, B form
	GS_textAttr.CA_mapMode (byte) - color mapping mode
	PSL_saveYPos - y position to print at
	PSL_saveRoutine - routine to call
	PSL_saveStringSeg - segment of string passed
	PSL_saveFont - segment of font to use
	PSL_saveWindow - window to pass

RETURN:
	ax.dl - x position for next char
	bx.dh - y position for next char
	ds - same
	dx:si - pointing after last character drawn
	bp - seg addr of font (may have moved)

DESTROYED:
	cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@


PutStringLow	proc	near

	;
	; If we are not drawing characters (due to a non-zero char offset)
	; then we want to do some patching here...
	;
PSL_drawOffsetOp	equ (this byte)
	jmp	short goto_PSL_checkDrawOffset
PSL_afterDrawOffset:

PSL_loop:

PSL_saveStringSeg equ  (this word) + 1
	mov	bp,1234h		;MODIFIED
	mov	ds,bp			; ds <- segment of the string.
					;
	LocalGetChar dx, dssi, NO_ADVANCE ;dl <- character to draw
	LocalIsNull dx			; check for NULL byte.
	jz	PSL_done		; quit if null.

	;
	; Check for a soft hyphen
	; (if we are doing soft hyphens)
	;
PSL_hyphenOp	equ (this byte)
	jmp	short PSL_startHyphen	;MODIFIED (JMP or MOV DH,xxx)
PSL_afterHyphen:
SBCS <	cmp	dl, C_OPTHYPHEN		;Can't draw soft hyphens.	>
DBCS <	cmp	dx, C_SOFT_HYPHEN	;Can't draw soft hyphens.	>
	je	PSL_skipChar		;

PSL_complexOp1	equ (this byte)
	jmp	short PSL_startComplex	;MODIFIED (JMP or MOV DH,xxx)
PSL_afterStart:
	
	;
	; Need to do a mapping if we are drawing ctrl characters
	;
PSL_checkMapCtrlOp	equ (this byte)
	jmp	short PSL_checkMapForCtrl ;MODIFIED (JMP or MOV DH,xxx)
PSL_afterCheckMapCtrlOp:

	push	cx
PSL_saveFont	equ (this word) + 1
	mov	di,1234h		;MODIFIED (segment of font)
	push	si			;interleaved
	mov	ds,di			;ds <- segment address of font data.

PSL_saveRoutineLabel	label	word
PSL_saveRoutine	equ (this word) + 1
	jmp	near ptr CharLowFast	;call character drawing routine.

PSL_afterDraw	label	near
MEM <	jmp	relLastBlock		; release last huge block	>
MEM <blockReleased:							>
	pop	si			;si <- index into string
	pop	cx			;cx <- # of chars left to draw

	;
	; Check for a space character
	; (if there is any space padding)
	;
PSL_spaceOpcode	equ (this byte)
	jmp	short PSL_checkSpace	;MODIFIED (JMP or MOV DH,xxx)
PSL_afterSpace:

	;
	; Need to do an adjustment if we are drawing ctrl characters
	;
PSL_checkCtrlAdjustOpcode	equ (this byte)
ifdef	IS_CASIO
	jmp	short goto_PSL_checkAdjustForCtrl ;MODIFIED (JMP or MOV DH,xxx)
else
DBCS <	jmp	short goto_PSL_checkAdjustForCtrl ;MODIFIED (JMP or MOV DH,xxx)>
SBCS <	jmp	short PSL_checkAdjustForCtrl ;MODIFIED (JMP or MOV DH,xxx)>
endif
PSL_afterCheckCtrlCharAdjustment:

PSL_saveYPos	equ  (this word) + 1
	mov	bx,1234h		;bx <- y position to draw at.

PSL_complexOp2	equ (this byte)
	jmp	short PSL_isComplex	;MODIFIED (JMP or MOV DH,xxx)
PSL_afterComplex label	near

PSL_skipChar:
	LocalNextChar dssi		;si <- offset to next character to draw
	loop	PSL_loop		;decrement cx and loop while not zero.

PSL_done:
;CASIO < jmp	cancelAutoTrans						>
;CASIO <autoTransCancelled:						>
PSL_saveWindow	equ  (this word) + 1
	mov	bp,1234h		;MODIFIED
	mov	es,bp			;es <- segment address of the window.

PSL_saveGState	equ  (this word) + 1
	mov	bp,1234h		;MODIFIED
	mov	ds,bp			;ds <- segment address of the GState.

	mov	dx,cs:[PSL_saveStringSeg]
NMEM < 	cmp	cs:[xorHiddenFlag],0	;check for ptr hidden.		>
NMEM < 	LONG jnz PSL_redrawXOR		;go and redraw it if it was hidden.>
NMEM <afterXORRedraw:							>
NMEM < 	cmp	cs:[hiddenFlag],0	;check for ptr hidden.		>
NMEM < 	jnz	PSL_redraw		;go and redraw it if it was hidden.>

NMEM <PutStringExit	label	near					>
	mov	bp, cs:PSL_saveFont	;bp <- seg addr of font
	mov	dl, cs:fracPosition
	mov	dh, cs:fracYPosition
NullRoutine label near
	ForceRef	NullRoutine
	ret

;----------------------------------

goto_PSL_checkDrawOffset:
	jmp	short PSL_checkDrawOffset

ifdef	IS_CASIO
goto_PSL_checkAdjustForCtrl:
	jmp	short PSL_checkAdjustForCtrl
endif
DBCS <goto_PSL_checkAdjustForCtrl:					>
DBCS <	jmp	short PSL_checkAdjustForCtrl				>
;----------------------------------
; special case for optional hyphen.
PSL_startHyphen:
SBCS <	cmp	dl, C_OPTHYPHEN		; Check for optional hyphen.	>
DBCS <	cmp	dx, C_SOFT_HYPHEN	; Check for optional hyphen.	>
	jne	PSL_afterHyphen		; Skip if not an optional hyphen.
	cmp	cx, 1			; cx <- # of chars left to process
					;   (including this one).
					; We are checking for the last char on
	je	PSL_needHyphen		;   the line.
SBCS <	cmp	{byte} ds:[si][1], 0	; Check for next char is NULL.	>
DBCS <	cmp	{wchar} ds:[si][2], 0	; Check for next char is NULL.	>
	jne	PSL_afterHyphen		;
PSL_needHyphen:				;
	;
	; Well, we are handling soft hyphens, and this is the last character
	; on the line, replace it with a hard hyphen, and return to handle it
	; as normal.
	;
SBCS <	mov	dl, C_HYPHEN		;				>
DBCS <	mov	dx, C_HYPHEN_MINUS	;				>
	jmp	PSL_afterHyphen		;

;----------------------------------
; special cases for complex transform

PSL_startComplex:
	push	ax
SBCS <	mov	dh, cs:fracPosition	;save x position (int:frac)	>
SBCS <	push	dx							>
DBCS <	push	{word}cs:fracPosition-1	;save x position (int:frac)	>
					;want fracPosition byte as high byte
					;	of word being push
	jmp	short PSL_afterStart

PSL_isComplex:
	call	DoComplexMove		;advance to next character
	add	sp, size WWFixed	;clear old position
	jmp	PSL_afterComplex

;----------------------------------
; special case for doing control characters
;
; I could have a table lookup here, but I felt that wouldn't be as fast as
; we would want.
;
PSL_checkMapForCtrl:
DBCS <	cmp	{wchar} ds:[si], C_IDEOGRAPHIC_SPACE			>
DBCS <	LONG je	PSL_doCtrlCharMap					>
SBCS <	cmp	{byte} ds:[si], C_SPACE	;Control char is <= C_SPACE	>
DBCS <	cmp	{wchar} ds:[si], C_SPACE ;Control char is <= C_SPACE	>

ifndef	IS_CASIO
	ja	PSL_afterCheckMapCtrlOp
	jmp	PSL_doCtrlCharMap
else
	jbe	PSL_doCtrlCharMap
	jmp	PSL_afterCheckMapCtrlOp
endif

;----------------------------------
; special case for padding spaces.
PSL_checkSpace:
	mov	ds, cs:PSL_saveStringSeg
SBCS <	cmp	{byte} ds:[si], C_SPACE					>
DBCS <	cmp	{wchar} ds:[si], C_SPACE				>
if CHAR_JUSTIFICATION
PSL_fullJustOpcode equ (this byte)
endif
	jne	PSL_afterSpace		;done if not a space
	;
	; add in the spacing.
	;
PSL_spacePadFrac equ (this byte) + 5	;MODIFIED
	add	cs:fracPosition, 0x12	;add in fractional padding
PSL_spacePad equ (this word) + 1	;MODIFIED
	adc	ax, 0x1234		;add in integer padding
	jmp	PSL_afterSpace

PSL_checkAdjustForCtrl:
	mov	ds, cs:PSL_saveStringSeg
DBCS <	cmp	{wchar} ds:[si], C_IDEOGRAPHIC_SPACE			>
DBCS <	LONG je	PSL_doCtrlCharAdjustment				>
SBCS <	cmp	{byte} ds:[si], C_SPACE	;Control char is <= C_SPACE	>
DBCS <	cmp	{wchar} ds:[si], C_SPACE ;Control char is <= C_SPACE	>
	LONG jbe PSL_doCtrlCharAdjustment
	jmp	PSL_afterCheckCtrlCharAdjustment

	; changed 4/7/93 to make AutoTransfer the default state
if (0)
CASIO <cancelAutoTrans:							>
CASIO <	CasioAutoXferOff						>
CASIO <	jmp	autoTransCancelled					>
endif
MEM <relLastBlock:							>
MEM <	ReleaseHugeArray		; release block			 >
MEM <	jmp	blockReleased						>
;----------------------------------
; special case for redrawing pointer
;
NMEM <PSL_redraw:							>
NMEM < 	push	ax, bx, dx, si						>
NMEM < 	call	CondShowPtr		;redraw ptr, mark it as not hidden. >
NMEM < 	pop	ax, bx, dx, si						>
NMEM < 	jmp	PutStringExit						>

NMEM <PSL_redrawXOR:							>
NMEM <	call	ShowXOR							>
NMEM <	jmp	afterXORRedraw						>

;
; OK... What we do here is to save the character routine that we would
; normally be calling and install our own routine.
; The new routine will update the current position, compare the current
; character against the drawOffset. If the character is at the end of the
; string, then we re-install the previous character routine and jump to it
; in order to start getting the text drawn.
;
PSL_checkDrawOffset:
	mov	dx, CHAR_LOW_EMPTY
	xchg	dx, cs:PSL_saveRoutine	; save our new routine
					; dx <- old routine
	mov	cs:PSL_oldRoutine, dx	; save old routine.
	

if DBCS_PCGEOS
	mov	ds, cs:PSL_saveFont	;ds <- seg addr of font
	mov	dx, ds:FB_firstChar
	mov	cs:CLE_firstChar, dx
	mov	dx, ds:FB_lastChar
	mov	cs:CLE_lastChar, dx
	mov	ds, cs:PSL_saveGState	; load ds with the gstate segment.
else
	mov	ds, cs:PSL_saveGState	; load ds with the gstate segment.
	mov	dx, {word}ds:GS_fontFirstChar
	mov	cs:CLE_firstChar, dl
	mov	cs:CLE_lastChar, dh
endif
	
	mov	dx, {word}ds:GS_complexOpcode
	mov	cs:CLE_kernOp, dh
	jmp	PSL_afterDrawOffset	; that's it...

;----------------------------------------
; The real code for mapping control characters
;
PSL_doCtrlCharMap:
DBCS <	push	ax							>
SBCS <	mov	dh, C_CNTR_DOT						>
if DBCS_PCGEOS
NPZ <	mov	ax, C_MIDDLE_DOT					>
PZ <	mov	ax, C_HALFWIDTH_KATAKANA_MIDDLE_DOT			>
endif
	
SBCS <	cmp	dl, C_SPACE		; Map C_SPACE -> C_CNTR_DOT	>
DBCS <	cmp	dx, C_SPACE		; Map C_SPACE -> C_CNTR_DOT	>
	je	gotChar1
	
SBCS <	cmp	dl, C_NONBRKSPACE	; Map C_NONBRKSPACE -> C_CNTR_DOT >
DBCS <	cmp	dx, C_NON_BREAKING_SPACE ; Map C_NONBRKSPACE -> C_CNTR_DOT >
	je	gotChar1

DBCS <	cmp	dx, C_IDEOGRAPHIC_SPACE	; Map C_IDEOGRAPHIC_SPACE -> C_CNTR_DOT >
DBCS <	je	gotChar1						>
	
SBCS <	mov	dh, C_PARAGRAPH						>
DBCS <	mov	ax, C_PARAGRAPH_SIGN					>
SBCS <	cmp	dl, C_CR		; Map C_CR -> C_PARAGRAPH	>
DBCS <	cmp	dx, C_CR		; Map C_CR -> C_PARAGRAPH	>
	je	gotChar1
	
SBCS <	mov	dh, C_LOGICAL_NOT					>
if DBCS_PCGEOS
NPZ <	mov	ax, C_NOT_SIGN						>
PZ <	mov	ax, C_RIGHT_ARROW					>
endif
SBCS <	cmp	dl, C_TAB		; Map C_TAB -> C_LOGICAL_NOT	>
DBCS <	cmp	dx, C_TAB		; Map C_TAB -> C_LOGICAL_NOT	>
	je	gotChar1
	
SBCS <	mov	dh, C_DBLDAGGER						>
DBCS <	mov	ax, C_DOUBLE_DAGGER					>
SBCS <	cmp	dl, C_COLUMN_BREAK	; Map C_COLUMN_BREAK -> C_DBLDAGGER >
DBCS <	cmp	dx, C_COLUMN_BREAK	; Map C_COLUMN_BREAK -> C_DBLDAGGER >
	je	gotChar1
	
SBCS <	mov	dh, C_SECTION						>
DBCS <	mov	ax, C_SECTION_SIGN					>
	cmp	dl, C_SECTION_BREAK	; Map C_SECTION_BREAK -> C_SECTION
	je	gotChar1
	
SBCS <	mov	dh, dl							>
DBCS <	mov	ax, dx							>
	
gotChar1:
SBCS <	mov	dl, dh			; dl <- character to draw	>
DBCS <	mov	dx, ax			; dx <- character to draw	>
DBCS <	pop	ax							>
	jmp	PSL_afterCheckMapCtrlOp

;-------------------------------

PSL_doCtrlCharAdjustment:
	mov	ds, cs:PSL_saveStringSeg

SBCS <	mov	dl, {byte} ds:[si]	; dl <- character from the stream>
DBCS <	mov	dx, {wchar} ds:[si]	; dx <- character from the stream>
SBCS <	mov	dh, C_CNTR_DOT						>
if DBCS_PCGEOS
NPZ <	mov	bx, C_MIDDLE_DOT					>
PZ <	mov	bx, C_HALFWIDTH_KATAKANA_MIDDLE_DOT			>
endif
	
SBCS <	cmp	dl, C_SPACE		; Map C_SPACE -> C_CNTR_DOT	>
DBCS <	cmp	dx, C_SPACE		; Map C_SPACE -> C_CNTR_DOT	>
	je	gotChar
	
SBCS <	cmp	dl, C_NONBRKSPACE	; Map C_NONBRKSPACE -> C_CNTR_DOT >
DBCS <	cmp	dx, C_NON_BREAKING_SPACE ; Map C_NONBRKSPACE -> C_CNTR_DOT >
	je	gotChar

DBCS <	cmp	dx, C_IDEOGRAPHIC_SPACE	; Map C_IDEOGRAPHIC_SPACE -> C_CNTR_DOT >
DBCS <	je	gotChar							>
	
SBCS <	mov	dh, C_PARAGRAPH						>
DBCS <	mov	bx, C_PARAGRAPH_SIGN					>
SBCS <	cmp	dl, C_CR		; Map C_CR -> C_PARAGRAPH	>
DBCS <	cmp	dx, C_CR		; Map C_CR -> C_PARAGRAPH	>
	je	gotChar
	
SBCS <	mov	dh, C_DBLDAGGER						>
DBCS <	mov	bx, C_DOUBLE_DAGGER					>
SBCS <	cmp	dl, C_COLUMN_BREAK	; Map C_COLUMN_BREAK -> C_DBLDAGGER >
DBCS <	cmp	dx, C_COLUMN_BREAK	; Map C_COLUMN_BREAK -> C_DBLDAGGER >
	je	gotChar
	
SBCS <	mov	dh, C_SECTION						>
DBCS <	mov	bx, C_SECTION_SIGN					>
SBCS <	cmp	dl, C_SECTION_BREAK	; Map C_SECTION_BREAK -> C_SECTION >
DBCS <	cmp	dx, C_SECTION_BREAK	; Map C_SECTION_BREAK -> C_SECTION >
	je	gotChar
	
SBCS <	mov	dh, C_LOGICAL_NOT					>
if DBCS_PCGEOS
NPZ <	mov	bx, C_NOT_SIGN						>
PZ <	mov	bx, C_RIGHT_ARROW					>
endif
SBCS <	cmp	dl, C_TAB		; Map C_TAB -> C_LOGICAL_NOT	>
DBCS <	cmp	dx, C_TAB		; Map C_TAB -> C_LOGICAL_NOT	>
	jne	dccmQuit		; Branch if no mapping
	
gotChar:
	;
	; We adjust the current X position by the difference  between the
	; width of the original character and the mapped character.
	;
SBCS <	; dl	= Character we would have drawn				>
SBCS <	; dh	= Character we did draw					>
DBCS <	; dx	= Character we would have drawn				>
DBCS <	; bx	= Character we did draw					>
	;
	; ax.fracPosition = current X position
	;
	push	es, cx, di		; Save nuked registers
DBCS <	push	bx			; save char actually drawn	>
	segmov	es, cs:PSL_saveFont, bx	; es <- font segment

	call	dccm_GetCharWidth	; bx.cl <- old character width
	add	cs:fracPosition, cl	; Update fractional position
	adc	ax, bx			; ax <- new position to draw at

SBCS <	mov	dl, dh			; dl <- character actually drawn>
DBCS <	pop	dx			; dx <- character actually drawn>
	call	dccm_GetCharWidth	; bx.cl <- new character width
	sub	cs:fracPosition, cl	; Update fractional position
	sbb	ax, bx			; ax <- new position to draw at
	pop	es, cx, di		; Save nuked registers

dccmQuit:
	jmp	PSL_afterCheckCtrlCharAdjustment


;
; Gets the width of a character.
;	PASS:	dx	= Character
;		es	= Segment address of the font
;	RETURN:	bx.cl	= Width of the character (from the font data)
;	DESTROYED:	di
;
dccm_GetCharWidth	label	near
if DBCS_PCGEOS
dccmGCW_afterDefault:
	cmp	dx, es:FB_lastChar
	ja	dccmGCW_afterLast
	sub	dx, es:FB_firstChar	; dx <- entry in list
	jb	dccmGCW_beforeFirst
	mov	di, dx			; di <- character
else
	cmp	dl,byte ptr es:FB_lastChar
	ja	dccmGCW_useDefault
	sub	dl, es:FB_firstChar	; dl <- entry in list
	jb	dccmGCW_useDefault
dccmGCW_gotChar:
	clr	bx			; di <- character
	mov	bl, dl
	mov	di, bx
endif
	
	FDIndexCharTable di, bx		; di <- offset into char data

	mov	cl, es:FB_charTable[di].CTE_width.WBF_frac
	mov	bx, es:FB_charTable[di].CTE_width.WBF_int
	retn

if DBCS_PCGEOS
dccmGCW_beforeFirst:
	add	dx, es:FB_firstChar
dccmGCW_afterLast:
	call	CallLockCharSetES
	jnc	dccmGCW_afterDefault		;branch if char exists
dccmGCW_useDefault:
	mov	dx, es:FB_defaultChar
	jmp	dccmGCW_afterDefault
else
dccmGCW_useDefault:
	mov	dl,byte ptr es:[FB_defaultChar]
	jmp	short dccmGCW_gotChar
endif

PutStringLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetComplex

DESCRIPTION:	Set up variables for the complex character drawing routine

CALLED BY:	INTERNAL
		VidPutString, CharLowFast

PASS:

RETURN:

DESTROYED:
	dx, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

SetComplex	proc	near
	mov	ds,cs:[PSL_saveGState]		;save GState segment.
	mov	dl, ds:[GS_textAttr].CA_flags	;save flags.
	mov	cs:[stateFlags], dl		;
	mov	cs:[PSL_saveRoutine],CHAR_LOW_CHECK
	ret

SetComplex	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	KernChar

DESCRIPTION:	Kern a pair of characters by adjusting the position at which
		the second character should be drawn.

CALLED BY:	INTERNAL
		DoAlloc, MemInfoHeap

PASS:
	dx - current character index (NOT value)
	cs:lastChar - previous character drawn, if any
	cs:lastFlags - CharTableFlags for previous character
	ax.cs:fracPosition - x position
	bx.cs:fracYPosition - y position
	es - seg addr of font
	es:di - ptr to CharTableEntry for current character

RETURN:
	ax:fracPosition - updated x
	bx:fracYPosition - updated y
	cs:lastChar - updated
	cs:lastFlags - updated

DESTROYED:
	dx

PSEUDO CODE/STRATEGY:
	if (complex)
		save start position;
	if (kerning pair)
		adjustment += pair kern value;
	if (track kerning)
		adjustment += track kern value;
	if (adjustment > width)
		adjustment = -width;
	position += adjustment;
	if (complex)
		transform new position;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

------------------------------------------------------------------------------@

StartComplexKern	label	near
	push	ax
SBCS <	mov	dh, cs:fracPosition	;save x position (int:frac)	>
SBCS <	push	dx							>
DBCS <	push	{word}cs:fracPosition-1	;save x position (int:frac)	>
					;want fracPosition byte as high byte
					;	of word being push
	jmp	afterStartKern

KernChar	proc	near
kernComplexOp1	equ (this byte)
	jmp	short StartComplexKern	;MODIFIED (JMP or MOV DH, xxx)
afterStartKern	label	near
	push	bx, cx, ds
	clr	cx
	clr	bh			;cx.bh <- width
	segmov	ds, es			;ds <- seg addr of font
	push	ax
if DBCS_PCGEOS
PrintMessage <fix StartComplexKern>
else
	mov	al, dl			;al <- character index
	add	al, ds:FB_firstChar	;al <- character value
	mov	ah, al			;both ah and al are char being drawn
	xchg	ah, cs:[lastChar]	;ah = previous, al = current
endif

	test	ds:FB_charTable[di].CTE_flags, mask CTF_IS_SECOND_KERN
	jz	notKernable		;branch if not kernable
	test	cs:lastFlags, mask CTF_IS_FIRST_KERN
	jz	notKernable		;branch if not after kernable

	push	di
	tst	ah			;test for left edge (ie. no previous)
	jz	noPairKern		;branch if no previous
	push	cx
	mov	cx,ds:[FB_kernCount]	;cx <- number of kerning pairs
	mov	di,ds:[FB_kernPairPtr]	;es:di = kerning table
	repne	scasw			;scan table
	pop	cx
	jnz	noPairKern		;quit if not found
	sub	di,ds:[FB_kernPairPtr]	;di = offset to char (+1)
	add	di,ds:[FB_kernValuePtr]	;di = offset to value (+1)
	mov	ax, ds:[di-2]		;ax <-  pair kern value (BBFixed)
	add	bh, al
	mov	al, ah
	cbw				;sign extend
	adc	cx, ax			;cx.bh += pair kern value
noPairKern:
	pop	di
notKernable:
	pop	ax

trackKernFrac	equ	(this byte) + 2	;MODIFIED
	add	bh, 0x12 		;add fractional track kerning
trackKernInt equ	(this word) + 2	;MODIFIED
	adc	cx, 0x1234		;add integer track kerning

	mov	bl, ds:FB_charTable[di].CTE_flags
	mov	cs:lastFlags, bl	;update kerning flags
	mov	bl, ds:FB_charTable[di].CTE_width.WBF_frac
	mov	dx, ds:FB_charTable[di].CTE_width.WBF_int

	add	bl, bh
	adc	dx, cx			;dx.bl <- width + kern
	jns	isForwardsMove		;branch if forwards / positive

	mov	bh, ds:FB_charTable[di].CTE_width.WBF_frac
	mov	cx, ds:FB_charTable[di].CTE_width.WBF_int
	neg	bh
	not	cx
	cmc
	adc	cx, 0			;cx.bh <-  -(width)

isForwardsMove:
	add	cs:fracPosition, bh	;add fractional kerning
	adc	ax, cx			;add integer kerning

	pop	bx, cx, ds

kernComplexOp2	equ (this byte)
	jmp	short DoComplexKern	;MODIFIED (JMP or MOV DH, xxx)
afterDoKern:
	ret

DoComplexKern:
	call	DoComplexMove		;transform the difference
	add	sp, size WWFixed	;clear old position
	push	bp
	mov	bp, sp
	mov	dh, cs:fracPosition
	mov	ss:[bp].CKF_oldX.WWF_frac.high, dh
	mov	ss:[bp].CKF_oldX.WWF_int, ax
	pop	bp
	jmp	afterDoKern

;
; This structure defines what is on the stack at the point
; DoComplexKern is called. This is used to update the old x
; position, which the next complex move is done relative to.
;
ComplexKernFrame	struct
    CKF_savedBP		word		;saved value of bp
    CKF_returnAddr	nptr		;near return address
    CKF_stringIndex	word		;index into string
    CKF_numChars	word		;# of chars left to draw
    CKF_oldX		WWFixed		;old x position
ComplexKernFrame	ends

KernChar	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SlowReadLine

DESCRIPTION:	Read a line of character data into lineDataBuffer

CALLED BY:	INTERNAL
		CharGeneralSlow

PASS:
	ds:si - data pointer
	bytesToDraw-extraBytesToDraw - number of bytes to load
RETURN:
	ds:si - data pointer for next row.
	lineDataBuffer - holds the data read in.
DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@

SlowReadLine	proc	near
	push	es, di	
	mov	di, cs	
	mov	es, di		
	mov	di, offset lineDataBuffer	
	mov	cl,cs:[bytesToDraw]	;
	sub	cl,cs:[extraBytesToDraw]
	clr	ch			;
	clr	bl			;extra bits (onlu used in bold)
	rep	movsb			;copy all bytes
	mov	al,bl			;
	stosb				;store last bits
	clr	ax			;pad with 0
	stosb				;
	pop	es, di			;
	ret				;

SlowReadLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharLowRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character. Character is large, so it is stored
		as a region. The text mode, clipping, et al do not matter.
CALLED BY:	JMP'd to by PutStringLow

PASS:		ds - seg addr of font
		ax - x position for character
		bx - y position for character
		dl - character to draw
RETURN:		ax - next x position
		
DESTROYED:	bx, cx, dx, si, di, ds, es, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	LOGGING

RegFlags	record
    RF_TRIVIAL_REJECT_FROM_RECT_SETUP:1
    RF_CALLED_DRAW_COMPLEX_RECT:1
    RF_CALLED_DRAW_LRCLIPPED_RECT:1
    RF_CALLED_DRAW_SIMPLE_RECT:1
    RF_CALLED_DRAW_OPT_RECT:1
RegFlags	end

curRegFlags	RegFlags

CHAR_LOG_SIZE	equ	1500

CharInfo	record
    :4
    CI_CLIP_MISMATCH_PREVIOUS:1		;current clip rect doesn't match last
    CI_TEXT_NOT_SOLID_BLACK:1		;text color != 100% C_BLACK
    CI_CHAR_REGION_MISMATCH_LEFT:1	;region mismatch on left bound
    CI_CHAR_REGION_MISMATCH_TOP:1	; " top bound
    CI_CHAR_REGION_MISMATCH_RIGHT:1	; " right bound
    CI_CHAR_REGION_MISMATCH_BOTTOM:1	; " bottom
    CI_SUBSTITUTED_DEFAULT:1		;Substituted default character
    CI_BUILD_CHAR:1
    CI_MASK_SIMPLE:1
    CI_BUFFER_CHANGED:1
    CI_PATTERN_ALL_ZEROS:1
    CI_PATTERN_ALL_ONES:1
CharInfo	end

CharClipInfo	record
    CCI_REJECTED_CHAR_LEFT_OF_WINDOW:1
    CCI_REJECTED_CHAR_RIGHT_OF_WINDOW:1
    CCI_REJECTED_CHAR_ABOVE_WINDOW:1
    CCI_REJECTED_CHAR_BELOW_WINDOW:1
    CCI_PART_CLIPPED_CHAR_LEFT_OF_WINDOW:1
    CCI_PART_CLIPPED_CHAR_RIGHT_OF_WINDOW:1
    CCI_PART_CLIPPED_CHAR_ABOVE_WINDOW:1
    CCI_PART_CLIPPED_CHAR_BELOW_WINDOW:1
CharClipInfo	end

CharLogEntry	struct
    CLE_char		Chars
    CLE_pos		Point
    CLE_info		CharInfo
    CLE_clipInfo	CharClipInfo
    CLE_regFlags	RegFlags
    CLE_clipBefore	Rectangle
    CLE_clipAfter	Rectangle
CharLogEntry	ends

CharLog		CharLogEntry	CHAR_LOG_SIZE dup (<>)

logPtr		nptr	offset CharLog

numCharsLogged	sdword	0

bufferSum	word	-1

endif

;------------------------------------------------------------------------------
; special case: character is missing:
;	(0) doesn't exist	--> use default
;	(2) not built		--> call the font driver
CLR_charMissing:
	tst	si			;assumes (CHAR_NOT_EXIST == 0)
	je	CLR_useDefault		;branch if character doesn't exist
EC <	cmp		si, CHAR_NOT_BUILT	>
EC <	ERROR_NE	FONT_BAD_CHAR_FLAG	>;shouldn't ever happen

ifdef	LOGGING
	xchg	di, cs:[logPtr]
	ornf	cs:[di].CLE_info, mask CI_BUILD_CHAR
	xchg	di, cs:[logPtr]
endif

	call	VidBuildChar
	mov	es, cs:PSL_saveFont	;es <- seg addr of font
	jmp	CLR_afterBuild

if DBCS_PCGEOS
;------------------------------
; special case: character is in different character set
CLR_beforeFirst:
	add	dx, es:FB_firstChar
CLR_afterLast:
	call	CallLockCharSetES
	;
	; Update our self-modifications
	;
	mov	di, es:FB_firstChar
	mov	cs:[CLR_firstChar], di
	mov	di, es:FB_lastChar
	mov	cs:[CLR_lastChar], di
	jnc	CLR_afterDefault		;branch if character exists
endif
;------------------------------------------------------------------------------
; special case: use default character
CLR_useDefault:

ifdef	LOGGING
	xchg	di, cs:[logPtr]
	ornf	cs:[di].CLE_info, mask CI_SUBSTITUTED_DEFAULT
	xchg	di, cs:[logPtr]
endif

DBCS <	mov	dx, es:FB_defaultChar					>
SBCS <	mov	dl, ds:FB_defaultChar					>
	jmp	CLR_afterDefault

;------------------------------------------------------------------------------
; special case: kerning info to use
CLR_DoKern:
	call	KernChar			;kern me jesus
	jmp	CLR_afterKern

;------------------------------------------------------------------------------
CharLowRegion	label	near
	segmov	es, ds, cx

ifdef	LOGGING
	inc	cs:[numCharsLogged].low
	jnz	CLR_noInc
	inc	cs:[numCharsLogged].high
CLR_noInc:
	xchg	di, cs:[logPtr]
	mov	cs:[di].CLE_char, dl
	mov	cs:[di].CLE_info, 0
	xchg	di, cs:[logPtr]
endif

	;
	; Check for undefined character, in which case use the default
	;
if DBCS_PCGEOS

CLR_afterDefault:
CLR_lastChar = (this word) + 2			;MODIFIED
	cmp	dx, 0x1234
	ja	CLR_afterLast
CLR_firstChar = (this word) + 2			;MODIFIED
	sub	dx, 0x1234			;convert to index, check before
	jb	CLR_beforeFirst			;branch if before first

else

CLR_lastChar = (this byte) + 2			;MODIFIED
	cmp	dl, 0x12			;check for after last
	ja	CLR_useDefault			;branch if after
CLR_afterDefault:
CLR_firstChar = (this byte) + 2			;MODIFIED
	sub	dl, 0x12			;convert to index, check before
	jb	CLR_useDefault			;branch if before first

endif

CLR_afterBuild:
SBCS <	clr	dh				;dx <- char offset into font.>
	mov	di,dx				;
	FDIndexCharTable di, si			;di <- offset * 8 (or *6)
	mov	si, es:FB_charTable[di].CTE_dataOffset ;es:si <- data pointer
	cmp	si, CHAR_MISSING		;check for missing
	jbe	CLR_charMissing			;branch if char is missing

CLR_kernOp equ (this byte) + 0
	jmp	CLR_DoKern			;MODIFIED (JMP or MOV DH,xxx)
CLR_afterKern:

	mov	dx, es:FB_heapCount
	inc	dx					;increment usage count
	mov	es:FB_heapCount, dx
DBCS <	mov	es:[si].RCD_usage, dx			;update char usage >
SBCS <	mov	es:FB_charTable[di].CTE_usage, dx	;update char usage >

	mov	dx, ax			    	;dx <- x position
	cmp	cs:fracPosition, 0x80
	jb	CLR_noRound
	inc	ax
CLR_noRound:
	;
	; We also need to round the y position to an integer
	;
	cmp	cs:fracYPosition, 0x80
	jb	CLR_noRoundY
	inc	bx
CLR_noRoundY:
	mov	cl, es:[di].FB_charTable.CTE_width.WBF_frac
	add	cs:fracPosition, cl	    	;update fractional position
	adc	dx, es:[di].FB_charTable.CTE_width.WBF_int

	push	dx				;save next char x position

	add	ax, es:[si].RCD_xoff		;add in left side bearing
	add	bx, es:[si].RCD_yoff		;add in top side bearing
	mov	dx, es
	mov	cx, si
	cmp	es:[si].RCD_bounds.R_left, EOREGREC
	je	nullRegion
	add	cx, offset RCD_bounds		;dx:cx <- ptr to region
	mov	si, offset GS_textAttr		;si <- offset of attributes
	mov	es, cs:PSL_saveWindow		;es <- seg addr of Window
	mov	ds, cs:PSL_saveGState		;ds <- seg addr of GState

ifdef	LOGGING
	call	LogBeforeCall
endif

	call	VidDrawRegion
nullRegion:

ifdef	LOGGING
	call	LogAfterCall
endif

	pop	ax				;ax <- x position of next char
	jmp	PSL_afterDraw

;-----------------------------------------------------------------------

ifdef	LOGGING

LogBeforeCall	proc	near	uses	ax, bx, cx, dx, si, bp, ds, es
	.enter

	push	ds, si
	xchg	di, cs:[logPtr]
	mov	cs:[di].CLE_pos.P_x, ax
	mov	cs:[di].CLE_pos.P_y, bx

	;
	; Compare the current clipRect with the original maskRect
	; and save the clipRect for later comparison...
	;
	push	ax
	mov	ax, es:W_clipRect.R_left
	mov	cs:[di].CLE_clipBefore.R_left, ax

	mov	ax, es:W_clipRect.R_top
	mov	cs:[di].CLE_clipBefore.R_top, ax

	mov	ax, es:W_clipRect.R_right
	mov	cs:[di].CLE_clipBefore.R_right, ax

	mov	ax, es:W_clipRect.R_bottom
	mov	cs:[di].CLE_clipBefore.R_bottom, ax
	pop	ax

	test	es:[W_grFlags], mask WGF_MASK_SIMPLE
	jz	notSimple
	ornf	cs:[di].CLE_info, mask CI_MASK_SIMPLE
notSimple:
	mov	ds, dx
	mov	bp, cx			;ds:bp = region

	push	ax
	add	ax, ds:[bp].R_left	;ax = real left
	cmp	ax, es:[W_maskRect].R_right
	jle	noClipLeft1
	ornf	cs:[di].CLE_clipInfo, mask CCI_REJECTED_CHAR_RIGHT_OF_WINDOW
	jmp	noClipLeft2
noClipLeft1:
	cmp	ax, es:[W_maskRect].R_left
	jge	noClipLeft2
	ornf	cs:[di].CLE_clipInfo, mask CCI_PART_CLIPPED_CHAR_LEFT_OF_WINDOW
noClipLeft2:
	pop	ax

	push	ax
	add	ax, ds:[bp].R_right	;ax = real right
	cmp	ax, es:[W_maskRect].R_left
	jge	noClipRight1
	ornf	cs:[di].CLE_clipInfo, mask CCI_REJECTED_CHAR_LEFT_OF_WINDOW
	jmp	noClipRight2
noClipRight1:
	cmp	ax, es:[W_maskRect].R_right
	jle	noClipRight2
	ornf	cs:[di].CLE_clipInfo, mask CCI_PART_CLIPPED_CHAR_RIGHT_OF_WINDOW
noClipRight2:
	pop	ax

	push	bx
	add	bx, ds:[bp].R_top	;ax = real top
	cmp	bx, es:[W_maskRect].R_bottom
	jle	noClipTop1
	ornf	cs:[di].CLE_clipInfo, mask CCI_REJECTED_CHAR_BELOW_WINDOW
	jmp	noClipTop2
noClipTop1:
	cmp	bx, es:[W_maskRect].R_top
	jge	noClipTop2
	ornf	cs:[di].CLE_clipInfo, mask CCI_PART_CLIPPED_CHAR_ABOVE_WINDOW
noClipTop2:
	pop	bx

	push	bx
	add	bx, ds:[bp].R_bottom	;ax = real bottom
	cmp	bx, es:[W_maskRect].R_top
	jge	noClipBottom1
	ornf	cs:[di].CLE_clipInfo, mask CCI_REJECTED_CHAR_ABOVE_WINDOW
	jmp	noClipBottom2
noClipBottom1:
	cmp	bx, es:[W_maskRect].R_bottom
	jle	noClipBottom2
	ornf	cs:[di].CLE_clipInfo, mask CCI_PART_CLIPPED_CHAR_BELOW_WINDOW
noClipBottom2:
	pop	bx
	;
	; Check the actual bounds of the region vs. what
	; we expect them to be...
	;
	mov	si, bp
	add	si, offset RCD_data - offset RCD_bounds
	call	GrGetPtrRegBounds		;get actual bounds or region
	mov	si, bp
	cmp	ds:[si].R_left, ax
	je	noRegionLeft
	ornf	cs:[di].CLE_info, mask CI_CHAR_REGION_MISMATCH_LEFT
noRegionLeft:
	cmp	ds:[si].R_top, bx
	je	noRegionTop
	ornf	cs:[di].CLE_info, mask CI_CHAR_REGION_MISMATCH_TOP
noRegionTop:
	cmp	ds:[si].R_right, cx
	je	noRegionRight
	ornf	cs:[di].CLE_info, mask CI_CHAR_REGION_MISMATCH_RIGHT
noRegionRight:
	add	dx, 10				;special case for bottom
	cmp	ds:[si].R_bottom, dx
	jle	noRegionBottom
	ornf	cs:[di].CLE_info, mask CI_CHAR_REGION_MISMATCH_BOTTOM
noRegionBottom:
	;
	; Make sure we're drawing in black
	;
	pop	ds, si
	cmp	ds:GS_textAttr.CA_colorIndex, C_BLACK
	jne	notBlackText
	cmp	ds:GS_textAttr.CA_maskType, SDM_100
	je	isBlackText
notBlackText:
	ornf	cs:[di].CLE_info, mask CI_TEXT_NOT_SOLID_BLACK
isBlackText:
	xchg	di, cs:[logPtr]

	.leave
	ret

LogBeforeCall	endp

;----------------------------------------

LogAfterCall	proc	near	uses	ax, bx, cx, dx, si, bp, ds, es
	.enter

	xchg	di, cs:[logPtr]

	;
	; see if the clip rect has changed
	;
	mov	ax, es:W_clipRect.R_left
	mov	bx, es:W_clipRect.R_top
	mov	cx, es:W_clipRect.R_right
	mov	dx, es:W_clipRect.R_bottom

	mov	cs:[di].CLE_clipAfter.R_left, ax
	mov	cs:[di].CLE_clipAfter.R_top, bx
	mov	cs:[di].CLE_clipAfter.R_right, cx
	mov	cs:[di].CLE_clipAfter.R_bottom, dx

	cmp	cs:[di].CLE_clipBefore.R_left, ax
	jne	clipChanged
	cmp	cs:[di].CLE_clipBefore.R_top, bx
	jne	clipChanged
	cmp	cs:[di].CLE_clipBefore.R_right, cx
	jne	clipChanged
	cmp	cs:[di].CLE_clipBefore.R_bottom, dx
	je	clipUnchanged
clipChanged:
	ornf	cs:[di].CLE_info, mask CI_CLIP_MISMATCH_PREVIOUS
clipUnchanged:

	;
	; Save the region drawing flags to show which
	; region routines were called.
	;
	mov	al, cs:[curRegFlags]
	mov	cs:[di].CLE_regFlags, al

	; check buffer for changes

	SetBuffer	ds, ax			;ds = buffer
	mov	ax, cs:[bm_bpScan]		;scan line width
	mul	ds:[B_height]			;ax = size
	mov	cx, ax
	shr	cx				;convert to words
	clr	bx				;bx is running sum
	mov	si, ds:[CB_data]
sumLoop:
	lodsw
	add	bx, ax
	loop	sumLoop

	cmp	bx, cs:[bufferSum]
	jz	sumUnchanged
	ornf	cs:[di].CLE_info, mask CI_BUFFER_CHANGED
sumUnchanged:
	mov	cs:[bufferSum], bx

	; check for pattern buffer all 0's

ifndef IS_CLR24
	push	ax
	mov	ax, {word} cs:[ditherMatrix]+0
	or	ax, {word} cs:[ditherMatrix]+2
	or	ax, {word} cs:[ditherMatrix]+4
	or	ax, {word} cs:[ditherMatrix]+6
	jnz	notAllZeros
	ornf	cs:[di].CLE_info, mask CI_PATTERN_ALL_ZEROS
notAllZeros:

	mov	ax, {word} cs:[ditherMatrix]+0
	and	ax, {word} cs:[ditherMatrix]+2
	and	ax, {word} cs:[ditherMatrix]+4
	and	ax, {word} cs:[ditherMatrix]+6
	cmp	ax, 0xff
	jnz	notAllOnes
	ornf	cs:[di].CLE_info, mask CI_PATTERN_ALL_ONES
notAllOnes:
	pop	ax
endif
	;
	; Advance the pointer into the log buffer
	;
	add	di, size CharLogEntry
	cmp	di, offset CharLog + (size CharLog)
	jnz	noWrap
	mov	di, offset CharLog
noWrap:

	xchg	di, cs:[logPtr]
	.leave
	ret

LogAfterCall	endp

LogStringInit	proc	near
	uses	ds
	.enter

	mov	ds, di				;ds <- seg addr of Window

	.leave
	ret
LogStringInit	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make self-modifications for region characters.
CALLED BY:	VidPutString

PASS:		ds - seg addr of GState
		di - seg addr of Window
RETURN:		none - jumps to PutStringLow
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupRegion	proc	near
ifdef LOGGING
	call	LogStringInit
endif
if DBCS_PCGEOS
	push	ds
	mov	ds, cs:PSL_saveFont		;ds <- seg addr of font
	mov	dx, ds:FB_firstChar
	mov	cs:CLR_firstChar, dx
	mov	dx, ds:FB_lastChar
	mov	cs:CLR_lastChar, dx		;save mods for first, last
	pop	ds
else
	mov	dx, {word}ds:GS_fontFirstChar	;dl <- first, dh <- last
	mov	cs:CLR_firstChar, dl
	mov	cs:CLR_lastChar, dh		;save mods for first, last
endif
	mov	cs:PSL_saveRoutine, CHAR_LOW_REGION 	;set routine

	mov	dx, {word}ds:GS_complexOpcode	;dl <- complex opcode
						;dh <- kerning opcode
	mov	cs:PSL_complexOp1, dl
	mov	cs:PSL_complexOp2, dl
	mov	cs:CLR_kernOp, dh
	cmp	dh, GO_SPECIAL_CASE		;see if kerning
	jne	afterKern			;additional work if kerning

	push	ax
	mov	cs:lastChar,0			;no kerning char
	mov	al, ds:GS_complexOpcode		;al <- complex opcode
	mov	cs:kernComplexOp1, al
	mov	cs:kernComplexOp2, al		;store opcode in kern code
	mov	ax, {word}ds:GS_trackKernValue	;ax <- track kern (BBFixed)
	mov	cs:trackKernFrac, al		;store fraction
	mov	al, ah				;al <- integer
	cbw					;sign extend into ax
	mov	cs:trackKernInt, ax		;store track kerning
	pop	ax
afterKern:
	jmp	PutStringLow
SetupRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharLowEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		ds	= segment address of font.
		ax	= x position.
		bx	= y position (unused).
		dl	= character to draw.
		cx	= # of characters left to draw.
RETURN:		ax	= next x position.
DESTROYED:	bx, cx, dx, si, di, ds, es, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 9/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharLowEmpty	label	near
CLE_drawOffset	equ	(this word) + 2
	cmp	cx, 1234h		; Check for done last character.
	ja	CLE_skipDraw
	;
	; Uh oh... We need to draw the character. Restore the routine
	; in PutStringLow() and jump to it.
	;
PSL_oldRoutine	equ	(this word) + 5
	mov	cs:PSL_saveRoutine, 1234h	; MODIFIED

	mov	di, cs:PSL_saveRoutine
	add	di, offset PSL_saveRoutineLabel + 3
	jmp	di				; go to the routine...

CLE_skipDraw:
	;
	; check for undefined character, in which case use the default
	;
if DBCS_PCGEOS

CLE_afterDefault:
CLE_lastChar	equ  (this word) + 2
	cmp	dx, 0x1234			;MODIFIED
	ja	CLE_afterLast
CLE_firstChar	equ  (this word) + 2
	sub	dx, 0x1234			;MODIFIED
	jb	CLE_beforeFirst

else

CLE_lastChar	equ  (this byte) + 2
	cmp	dl,12h			    ; check against last character in
	ja	CLE_useDefault		    ; font, use default if beyond.
CLE_afterDefault:
CLE_firstChar	equ  (this byte) + 2
	sub	dl,12h			    ; Subtract from first to get offset
					    ; into the font for this character.
	jb	CLE_useDefault		    ; If char is below the first char
					    ; defined for the font then use
					    ; the default character (the
					    ; useDefault code branches right
					    ; back here, but with a valid char
					    ; in dl).
endif
	; compute data pointer
SBCS <	clr	dh			    ; dx <- offset into font data.>
	mov	di,dx			    ;
	FDIndexCharTable di, cx		    ; di <- offset * 8 (or *6)
	;
	; Check for a missing character (CTE_dataOffset == 0)
	;
	cmp	ds:FB_charTable[di].CTE_dataOffset, 0
	je	CLE_useDefault		    ; Use the default if char missing.
	;
	; ds:di = index to CharTableEntry for character
	; compute next character x position
	;
CLE_kernOp equ (this byte) + 0
	jmp	CLE_DoKern			;MODIFIED (JMP or MOV DH,xxx)
CLE_afterKern:
	mov	cl, ds:[di].FB_charTable.CTE_width.WBF_frac
	add	cs:fracPosition, cl	    ;keep frac position up to date.

	adc	ax, ds:[di].FB_charTable.CTE_width.WBF_int

	jmp	PSL_afterDraw		; Do next character.

if DBCS_PCGEOS
;------------------------------
; special case: character is in different character set

CLE_beforeFirst:
	add	dx, ds:FB_firstChar
CLE_afterLast:
	call	CallLockCharSetDS
	push	ax
	mov	ax, ds:FB_firstChar
	mov	cs:CLE_firstChar, ax
	mov	ax, ds:FB_lastChar
	mov	cs:CLE_lastChar, ax
	pop	ax
	jnc	CLE_afterDefault		;branch if char exists
endif
;------------------------------
; special case: use default character
;		the current character is beyond the set of characters defined
;		in this font.
CLE_useDefault:
DBCS <	mov	dx,ds:[FB_defaultChar]					>
SBCS <	mov	dl,byte ptr ds:[FB_defaultChar]				>
	jmp	short CLE_afterDefault

;-----------------------------
; special case: kerning info to use

CLE_DoKern:
	segmov	es, ds				;es <- seg addr of font
	call	KernChar			;kern me jesus
	jmp	CLE_afterKern

;
;	Constants for self-modifying mode
;

CHAR_LOW_FAST	=	offset CharLowFast - offset PSL_saveRoutineLabel - 3
CHAR_LOW_FAST_CH =	offset CharLowFastCh - offset PSL_saveRoutineLabel - 3
CHAR_LOW_CHECK	=	offset CharLowCheck - offset PSL_saveRoutineLabel - 3
CHAR_LOW_REGION =	offset CharLowRegion - offset PSL_saveRoutineLabel - 3
CHAR_LOW_EMPTY	=	offset CharLowEmpty - offset PSL_saveRoutineLabel - 3


if DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallLockCharSetDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to call FontDrLockCharSet()

CALLED BY:	CharLowFast(), CharLowEmpty()
PASS:		dx - character to lock font for
RETURN:		ds - new seg addr of font
		carry - set if character does not exist
		modifications updated:
			PSL_saveFont
			CLF_firstChar
			CLF_lastChar
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallLockCharSetDS	proc	near
	uses	ax
	.enter
	;
	; Lock the new font
	;
	push	bx, cx, dx, si, di
	mov	si, offset PutStringState 	;cs:si <- ptr to table
	call	SaveVidState			;save self-modifcations
	mov	ds, cs:PSL_saveGState		;ds <- seg addr of GState
	VSem	cs, videoSem, TRASH_BX		;release the driver sem
	call	FontDrLockCharSet
	PSem	cs, videoSem, TRASH_BX		;get the driver sem
	mov	ds, ax				;ds <- new font seg addr
	lahf					;ah <- flags
	mov	si, offset PutStringState	;cs:si <- ptr to table
	call	RestoreVidState			;restore self-modifications
	sahf					;restore results
	pop	bx, cx, dx, si, di
	mov	ax, ds				;ax <- new font seg
	;
	; update various self-modifications
	;
	mov	cs:[PSL_saveFont], ax		;<- new font seg
	mov	ax, ds:FB_firstChar
	mov	cs:[CLF_firstChar], ax		;<- new first char
	mov	ax, ds:FB_lastChar
	mov	cs:[CLF_lastChar], ax		;<- new last char

	.leave
	ret
CallLockCharSetDS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallLockCharSetES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to call FontDrLockCharSet()

CALLED BY:	CharLowRegion(), CharLowCheck(), PutStringLow()
PASS:		dx - character to lock font for
RETURN:		es - new seg addr of font
		carry - set if character does not exist
		modifications updated:
			PSL_saveFont
			CLF_firstChar
			CLF_lastChar
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallLockCharSetES	proc	near
	uses	ds
	.enter

	call	CallLockCharSetDS
	segmov	es, ds

	.leave
	ret
CallLockCharSetES		endp

endif
