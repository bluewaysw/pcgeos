COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textScrollOneLine.asm

AUTHOR:		John Wedgwood, Feb 26, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/26/92	Initial revision

DESCRIPTION:
	One-line scrolling related code.

	$Id: textScrollOneLine.asm,v 1.1 97/04/07 11:18:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextInstance	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextScrollOneLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scroll a one line edit object so that a position falls into
		the visible area.

CALLED BY:	VisTextNotifyGeometryValid
PASS:		*ds:si	= Instance ptr
		cx	= Position to make visible
		     This position is kind of screwed up. It is the offset
		     into the text, plus the offset to the left edge of the
		     object, plus the lrMargin.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The position passed to us is:
		offset into text + VI_left + lrMargin
	In order to find out if this range falls into the visible boundaries
	we need to adjust based on the leftOffset value (which determines how
	much is off the left edge of the object).
		VI_bounds.R_left		      VI_bounds.R_right
		| lrMargin			      |
		v v				      v
		   +-------------------------------+
	  The text string looks like this here, sort of.
		   +-------------------------------+
	  ^-----^
	    |
	    +-- leftOffset.

	winPos = position + leftOffset.

USAGE:	ax = VI_bounds.R_left  + lrMargin.
	bx = VI_bounds.R_right - lrMargin.
	cx = position.
	dx = visWidth.
	bp = winPos. (= position + leftOffset).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextScrollOneLine	method	VisTextClass, MSG_VIS_TEXT_SCROLL_ONE_LINE
	call	TextCheckCanCalcNoRange		; Quit if we can't calculate.
	LONG jc quit

	push	di
	mov	di, 700
	call	ThreadBorrowStackSpace
	push	di

	call	TextGStateCreate
	;
	; Find the left and right edges of the line of text.
	;
	push	cx				; Save passed offset
	
	;
	; Transform the gstate to be appropriate for a small object
	;
	clr	cx
	clr	dl				; DrawFlags
	call	TR_RegionTransformGState

	;
	; Compute the width of the text.
	;
	call	TS_GetTextSize			; dx.ax <- size
	clrdw	bxdi				; line #0
	mov	bp, 0x7fff			; Compute to the end
	call	TL_LineTextPosition		; bx <- end of text
	mov	cx, bx				; cx <- real width of text

	;
	; Figure the left, right, and width of the area in which text is
	; displayed.
	;
	call	TextInstance_DerefVis_DI	; ds:di <- instance ptr
	mov	ax, ds:[di].VI_bounds.R_left	; ax <- object left
	mov	bx, ds:[di].VI_bounds.R_right	; bx <- object right
	
	;
	; Remove the margins in order to get a "real" idea of the area that
	; is filled with text.
	;
	add	al, ds:[di].VTI_lrMargin	; ax <- visLeft
	adc	ah,0
	sub	bl, ds:[di].VTI_lrMargin	; bx <- visRight
	sbb	bh,0

	mov	dx, bx
	sub	dx, ax				; dx <- visWidth

	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; ax	= Left edge of display area
	; bx	= Right edge of display area
	; dx	= Width of display area
	; cx	= Width of the text
	; On Stack:
	;	Pixel offset from left edge of text which we want to display
	;
	; Get the justification and figure the adjustment for same
	;
	push	ax, bx, cx			; Save l/r, textWidth
	sub	sp, size VisTextMaxParaAttr	; Allocate a stack frame
	mov	bp, sp				; ss:bp <- frame ptr
	
	push	dx, di				; Save display-width, instance
	clrdw	dxax				; Get attrs for offset 0
	clr	cx				; cx <- region
	clr	bx				; bx <- Y position in region
	clr	di				; dx <- line height in region
	call	TA_GetParaAttrForPosition	; Fill attribute structure
	pop	dx, di				; Rstr display-width, instance

	;
	; We need to adjust the line position by some amount depending on
	; whether or not it is left/right/center justified. We use a constant
	; to define the width of a one line object which is very convenient
	; because it means we can use this value rather than computing
	; something.
	;
	ExtractField word, ss:[bp].VTPA_attributes, VTPAA_JUSTIFICATION, ax, cx

	;
	; For left or full justification we use a zero adjustment since we
	; want the text to align itself with the left edge of the text-area.
	;
	clr	cx

	cmp	ax, J_LEFT
	je	gotAdjustment
	cmp	ax, J_FULL
	je	gotAdjustment

	;
	; For right justification we use the difference between the 
	; text-width and the width of the display area.
	;
	mov	cx, VIS_TEXT_ONE_LINE_RIGHT_MARGIN
	sub	cx, dx				; cx <- maxW - displayW

	cmp	ax, J_RIGHT
	je	gotAdjustment
	
	;
	; For center justification we use 1/2 the adjustment we would apply
	; to right justification.
	;
	shr	cx,1				; cx <- (maxW-displayW)/2

gotAdjustment:
	add	sp, size VisTextMaxParaAttr	; Restore stack
	mov	bp, cx				; bp = adjustment
	pop	ax, bx, cx			; Restore l/r, textWidth

	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	;
	; ax	= Left edge of display area
	; bx	= Right edge of display area
	; dx	= Width of the display area
	;
	; cx	= Offset from left edge to display
	; bp	= Adjustment to apply to the line
	;
	; On Stack:
	;	Pixel offset from left edge of text which we want to display
	;
	; If a left offset has never been set before then act like the text
	; all fits and set a left offset based on the justification
	;
	cmp	ds:[di].VTI_leftOffset,INITIAL_LEFT_OFFSET
	jz	textAllFits

	;
	; Check for the text fitting in the display area.
	;
	cmp	cx, dx				; Compare textW, displayW
	jge	textWiderThanDisplay		; Branch if text is wider

textAllFits:
	;
	; The text is narrower than display, calculate left offset based on
	; justification. Since the text all fits there is no work needed
	; to display the passed offset. As a result we can discard this value
	; from the stack.
	;
	pop	ax				; Remove offset from stack
	
	mov	cx, bp				; Set offset to -adjustment
	neg	cx
	jmp	setOffset

textWiderThanDisplay:
	;
	; The text is wider than the display area.
	; We need to do different things depending on the justification:
	;	LEFT:	Check for white space at the right edge of the line
	;		and try to remove it.
	;	RIGHT:	Check for white space at the left edge of the line
	;		and try to remove it.
	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; cx	= Width of the text
	; dx	= Width of the area to display in
	; bp	= Adjustment (based on the display width and max width)
	; On Stack:
	;	Pixel offset from left edge of text which we want to display
	;
	push	cx				; Save text width
	add	cx, ds:[di].VTI_leftOffset	; cx <- current end width
	add	cx, bp				; Add new adjustment

	;
	; dx	= Width of area to display in
	; cx	= Amount of text after the start of the display area after
	;	  we make this change.
	; Compare these two widths to see if there is a gap between the
	; end of the text and the end of the display area.
	;
	cmp	dx, cx				; Compare displayW, visibleText
	pop	cx				; Restore text width
	jle	noEndSpace			; Branch if no end space is left

	;
	; There is space between the end of the text and the right edge of the
	; display area. Shift everything over to eliminate white space at 
	; the right edge.
	;	new offset = dispWidth - textWidth
	; It may seem like magic, but by moving the text over so that there 
	; isn't a gap on the right will always result in the offset passed
	; in getting display correctly. This relies on the knowledge that the
	; offset passed in is the cursor position to display.
	;
	; The upshot of this is that we don't need the offset that we have been
	; carefully storing on the stack.
	;
	pop	bp				; Remove stuff from stack
	
	sub	cx, dx				; cx <- textW - displayW
	neg	cx				; cx <- displayW - textW
	jmp	setOffset

noEndSpace:
	;
	; There isn't any extra space at the end of the object. We must make
	; sure that the passed offset falls in the visible area.
	;
	pop	cx				; Restore passed offset

	;
	; Compare the passed position with the left and right edges of the
	; visual area to see if it's already on screen.
	;
	cmp	cx, ax				; Compare pos, displayLeft
	jge	notOffLeft			; Branch if it's not to the left

	;
	; The position is off left edge.
	; newLeftOffset = oldLeftOffset + (obj.left - position)
	;
	sub	cx, ax				; cx <- (position-objLeft)
	neg	cx
	add	cx, ds:[di].VTI_leftOffset
	jmp	setOffset			; Set new offset

notOffLeft:
	;
	; The position isn't off the left edge. Check to see if it's off the
	; right edge.
	;
	cmp	cx, bx				; Compare pos, displayRight
	jle	isVisible			; Branch if not to the right

	;
	; The position is off right side.
	; newLeftOffset = oldLeftOffset - (passedPosition - displayRight)
	; newLeftOffset = oldLeftOffset - passedPosition + displayRight
	; newLeftOffset =  -passedPosition + oldLeftOffset + displayRight
	;
	neg	cx
	add	cx, bx
	add	cx, ds:[di].VTI_leftOffset

setOffset:
	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; ax	= Left edge of the display
	; bx	= Right edge of the display
	; dx	= Width of the display
	; cx	= New offset of text from left edge of display area.
	;
	call	VisTextSetNewOffset

isVisible:
	;
	; The position is now visible. We can nuke the gstate and get out of
	; here.
	;
	call	TextGStateDestroy

	pop	di
	call	ThreadReturnStackSpace
	pop	di

quit:
	ret
VisTextScrollOneLine	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetNewOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new VTI_leftOffset field in the instance data.
		BitBlt's the object left/right in order to compensate for
		the new position.

CALLED BY:	VisTextScrollOneLine
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		ax	= Left edge of the display area
		bx	= Right edge of the display area
		dx	= Width of the display area
		cx	= New left offset
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetNewOffset	proc	near	uses si
	class	VisTextClass
	.enter
	;
	; If this is the first time a left offset has been set
	; (leftOffset = INITIAL_LEFT_OFFSET) that is an indication that this
	; object hasn't come on screen yet. This means that a bit-blt can't
	; do anything (in fact w/o a window it will likely die). In this case
	; just store the new offset and quit.
	;
	cmp	ds:[di].VTI_leftOffset,INITIAL_LEFT_OFFSET
	jnz	notFirstTime			; Branch if not first setting
	
	;
	; It's the first time...
	;
	mov	ds:[di].VTI_leftOffset, cx	; Set the new offset
	jmp	quit				; Quit without doing anything

notFirstTime:
	;
	; It's not the first time, we may need to move the bits around.
	; Do the quick check for no change in the offset in which case we 
	; can skip all the hard work.
	;
	cmp	cx, ds:[di].VTI_leftOffset	; Check for no change
	je	quit				; Quit if no change

	;
	; Make sure we can draw. If we can't we can quit while we're ahead.
	;
	call	TextCheckCanDraw
	jc	quit				; Quit if we can't draw

	;
	; We do need to move stuff around.
	; Need:
	; ax	= Left edge of source for move		0
	; bx	= Top edge of source for move		0
	;
	; cx	= Left edge of destination for move	(Computed)
	; dx	= Top edge of destination for move	0
	;
	; si	= Width of area to move			width
	;
	; di	= Handle for gstate
	;
	; On stack:
	;	Height of area to move			(VI_bottom - VI_top)
	;	Move flags (BLTM_MOVE)
	;
	
	;
	; Turn off the selection if it's a cursor.
	;
	call	TSL_SelectIsCursor		; Check for a selection.
	jnc	10$				; Skip if no cursor.
	call	EditUnHilite			; Turn off cursor.
10$:

	;
	; Save the new leftOffset and compute the destination X position.
	;
	; The destination position for the left edge of the object is the
	; difference between the old and new leftOffset.
	;
	xchg	cx, ds:[di].VTI_leftOffset	; Save new left offset
						; cx <- old left offset
	sub	cx, ds:[di].VTI_leftOffset	; cx <- difference in offsets
	neg	cx
	
	;
	; Compute the area height, accounting for margins.
	;
	mov	bp, ds:[di].VI_bounds.R_bottom	; bp <- height of area
	sub	bp, ds:[di].VI_bounds.R_top

	clr	ax
	mov	dl, ds:[di].VTI_tbMargin
	sub	bp, ax
	sub	bp, ax

	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	;
	; cx	= Dest left
	; bp	= Height of area to move
	; 
	push	di, si				; Save instance ptr/chunk

	;
	; Compute the width of the area to move, accounting for margins.
	;
	mov	si, ds:[di].VI_bounds.R_right	; si <- width of area to move
	sub	si, ds:[di].VI_bounds.R_left

	clr	ax
	mov	al, ds:[di].VTI_lrMargin
	sub	si, ax				; Adjust for margins
	sub	si, ax

	;
	; The source top/left are 0,0 since they are relative to a transformed
	; gstate.
	;
	clr	ax				; ax <- left edge of source
	clr	bx				; bx <- top edge of source
	clr	dx				; dx <- dest top position

	;
	; Bit-blt requires that the width and height to be one-based,
	; not zero based.
	;
;;;	inc	si				; Make width one-based
;;;	inc	bp				; Make height one-based

	mov	di, ds:[di].VTI_gstate		; di <- gstate

	;
	; Push the height and flags and move the bits.
	;
	push	bp				; Push height for call
	mov	bp, BLTM_MOVE
	push	bp				; Push flags
	call	GrBitBlt			; Removes 2 words from stack

	;
	; All done... On the stack is our instance chunk pointer and chunk.
	;
	pop	di, si				; Restore instance ptr/chunk

	;
	; If the selection is a cursor we need to turn the cursor back on.
	;
	call	TSL_SelectIsCursor		; Check for a selection
	jnc	20$
	call	EditHilite			; Turn on cursor
20$:

quit:
	.leave
	ret
VisTextSetNewOffset	endp


TextInstance	ends
