COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlBorder.asm

AUTHOR:		John Wedgwood, Feb 26, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/26/92	Initial revision

DESCRIPTION:
	Misc border related stuff.

	$Id: tlBorder.asm,v 1.1 97/04/07 11:21:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextDrawCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextClearBehindLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear behind an entire line as a prelude to drawing. Also,
		draw any border that the line has

CALLED BY:	CheckPBStatusChange, TextDraw(2), TextLineHeightChange,
		TextScreenUpdate(2)

PASS:		*ds:si	= Instance ptr
		al	= TextClearBehindFlags
		bx.di	= Line to clear behind
			= -1 to draw area below the text on the screen
		ss:bp	= LICL_vars structure with these set:
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
				LICL_paraAttrStart = -1 if paraAttr invalid

			   Also:
				LICL_region
				LICL_lineBottom
				LICL_lineHeight
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/26/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions
	jcw	12/26/91	Changed for new line module

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextClearBehindLine	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx
	.enter
	;
	; Clear the area. This will also set the paragraph attributes.
	;
	call	TL_LineClearBehind		; Clear the area behind the line

	;
	; Draw tab-lines and borders
	;
	clr	bx				; Draw tab lines after this
	call	DrawTabLinesAfterPos		;   position.

	clr	cx				; draw all sides
	call	DrawBorderIfAny

	.leave
	ret
TextClearBehindLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBorderIfAny
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the border (if any exists).

CALLED BY:	TextClearAfterField, TextClearBehindLine
PASS:		ss:bp	= LICL_vars structure on stack.
		*ds:si	= Instance
		cx - border sides to ignore
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawBorderIfAny	proc	near
	class	VisTextClass

	test	LICL_paraAttr.VTPA_borderFlags, mask VTPBF_LEFT or \
						mask VTPBF_TOP or \
						mask VTPBF_RIGHT or \
						mask VTPBF_BOTTOM
	jz	noBorder

	;
	; Draw me a border
	;
	call	TextDrawBorder

noBorder:
	ret
DrawBorderIfAny	endp

TextDrawCode ends

TextBorder	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextDrawBorder

DESCRIPTION:	Draw any border that a line has.  Called

CALLED BY:	INTERNAL

PASS:	*ds:si - text object
	ss:bp - LICL_frame
		LICL_rect - bounds of line, including border *except* on the
			    left side and the right side
		LICL_lineFlags - set
		LICL_lastLineBorder - set
		LICL_nextLineBorder - set
	cx - border sides to ignore

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
TextDrawBorder	proc	far	uses	ax, bx, cx, dx, si, di
	class	VisTextClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_gstate		; di <- gstate

	call	SetBorderColorAndAttributes
	pushf					;value to pass at end

	push	ss:[bp].LICL_theRect.R_left

	call	CalcRealBorder			;returns dx = border flags
	not	cx
	and	dx, cx

	; push left and right by shadow size

	push	si
	mov	cx, mask VTPBF_LEFT
	push	dx
	call	GetBorderInfo			;returns ax = total
	sub	ss:[bp].LICL_theRect.R_left, ax
	pop	dx

	mov	cx, mask VTPBF_RIGHT
	push	dx
	call	GetBorderInfo			;returns ax = total
	pop	bx				;bx = border flags
	pop	si

	; left border ?

	push	bx
	mov	LICL_borderStart, offset LICL_theRect.R_top
	mov	LICL_borderSide, offset LICL_theRect.R_left
	mov	LICL_borderEnd, offset LICL_theRect.R_bottom
	mov	LICL_borderOpposite, offset LICL_theRect.R_right
	mov	cx, mask VTPBF_LEFT
	clr	dx
	call	DrawBorderSide
	pop	bx

	; right border ?

	push	bx
	mov	LICL_borderSide, offset LICL_theRect.R_right
	mov	LICL_borderOpposite, offset LICL_theRect.R_left
	mov	cx, mask VTPBF_RIGHT
	mov	dl,mask DBF_NEGATIVE
	call	DrawBorderSide
	pop	bx

	; top border ?

	push	bx
	mov	LICL_borderStart, offset LICL_theRect.R_left
	mov	LICL_borderSide, offset LICL_theRect.R_top
	mov	LICL_borderEnd, offset LICL_theRect.R_right
	mov	LICL_borderOpposite, offset LICL_theRect.R_bottom
	mov	cx, mask VTPBF_TOP
	clr	dx
	call	DrawBorderSide
	pop	bx

	; bottom border ?

	mov	LICL_borderSide, offset LICL_theRect.R_bottom
	mov	LICL_borderOpposite, offset LICL_theRect.R_top
	mov	cx, mask VTPBF_BOTTOM
	mov	dl,mask DBF_NEGATIVE
	call	DrawBorderSide

	pop	ss:[bp].LICL_theRect.R_left

	popf
	jz	30$
	clr	ax
	call	GrSetAreaPattern
30$:

	.leave
	ret

TextDrawBorder	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawBorderSide

DESCRIPTION:	Draw a border side

CALLED BY:	INTERNAL

PASS:
	bx - VisTextParaBorderFlags
	cx - bit mask for side to draw
	dl - DBF_NEGATIVE set
	di - gstate
	ss:bp - LICL_frame
		LICL_rect - bounds of line, including border
		LICL_lineFlags - set
		LICL_mapRect - set

RETURN:

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	widSH = width + shadow (if shadowed)
	adjust = (if side is shadowed) -> border width
				else -> shadow width

		Left		Top		Right		Bottom
		----		---		-----		------
LEFT SIDE:
		SIDE		START		OPPOSITE	END
Top left T,B:	left		top		left+widSH-1	bottom-adjust
Top left T:	left		top		left+widSH-1	bottom
Top left B:	left		top		left+widSH-1	bottom-adjust
Top left:	left		top		left+widSH-1	bottom
Top right T,B:	left		top+adjust	left+widSH-1	bottom
Top right T:	left		top+adjust	left+widSH-1	bottom
Top right B:	left		top		left+widSH-1	bottom
Top right:	left		top		left+widSH-1	bottom
Bot left T,B:	left		top+adjust	left+widSH-1	bottom
Bot left T:	left		top+adjust	left+widSH-1	bottom
Bot left B:	left		top		left+widSH-1	bottom
Bot left:	left		top		left+widSH-1	bottom
Bot right T,B:	left		top		left+widSH-1	bottom-adjust
Bot right T:	left		top		left+widSH-1	bottom
Bot right B:	left		top		left+widSH-1	bottom-adjust
Bot right:	left		top		left+widSH-1	bottom

TOP SIDE:
		START		SIDE		END		OPPOSITE
Top left:	left		top		right-adjust	top+widSH-1
Top right:	left+adjust	top		right		top+widSH-1
Bot left:	left+adjust	top		right		top+widSH-1
Bot right:	left		top		right-adjust	top+widSH-1

RIGHT SIDE:
		OPPOSITE	START		SIDE		END
Top left:	right-widSH+1	top+adjust	right		bottom
Top right:	right-widSH+1	top		right		bottom-adjust
Bot left:	right-widSH+1	top		right		bottom-adjust
Bot right:	right-widSH+1	top+adjust	right		bottom

BOTTOM SIDE
		START		OPPOSITE	END		SIDE
Top left:	left+adjust	bottom-widSH+1	right		bottom
Top right:	left		bottom-widSH+1	right-adjust	bottom
Bot left:	left		bottom-widSH+1	right-adjust	bottom
Bot right:	left+adjust	bottom-widSH+1	right		bottom


GENERIC:
	SIDE = SIDE
	OPPOSITE = OPPOSITE + (negative * (width+shadow-1))
	START = START + (shadowFlag * adjust)
	END = END - (!shadowFlag * adjust)

						Adjust		Adjust
	Negative	shadowFlag		Requires top	Requires bot
	--------	----------		------------	------------
Left	0		top right, bot left	top r, bot l	top l, bot r
Top	0		top right, bot left	0		0
Right	1		top left, bot right	top l, bot r	top r, bot l
Bottom	1		top left, bot right	0		0

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@


DrawBorderSide	proc	near

	;
	; If no border on this side then exit
	;
	test	bx,cx
	jnz	10$
	ret
10$:

;------------------------------------------------------------
	;
	; Get border variables for this side
	;
	push	dx
	mov	dx,bx
	push	si
	call	GetBorderInfo
	pop	si
	pop	ax
	or	dl,al				;dl = DrawBorderFlags

	;
	; Save rectangle (we mangle it below)
	;
	push	LICL_rect.R_left
	push	LICL_rect.R_top
	push	LICL_rect.R_right
	push	LICL_rect.R_bottom
	
	;
	; Here's the situation...
	;
	; We are drawing a rectangle that corresponds to one side of the
	; border. Assume for a moment that we're talking about the
	; top edge of the border. The rectangle would be defined as:
	;	LICL_borderStart	= LICL_left
	;	LICL_borderEnd		= LICL_right
	;	LICL_borderSide		= LICL_top
	;	LICL_borderOpposite	= LICL_bottom
	;
	; What this means is that the start/end correspond to the 'long'
	; edge of the border while the side/opposite correspond to the 'width'
	; edge of the border.
	;
	; There are two tasks here. The first is to set up the start/end
	; so that they correctly measure out the long edge of the border side.
	; The second is to set the side/opposite so that it corresponds to
	; the width of the border.
	;
	; If the border edge is the bottom or right edge, we get this flag
	; passed to us: DBF_NEGATIVE
	;
	; This flag indicates that the adjustment we need to make on the
	; opposite edge of the border should be negative
	;
	; This means that if DBF_NEGATIVE is passed for the right border side,
	; (and it always is) we want to adjust the left edge in of the rectangle
	; needs to be adjusted *backwards* to yield the correct rectangle.
	;

	;
	; We attack the case of setting up the start/end to correspond to the
	; correct area for the border. If we are dealing with a shadowed edge,
	; one end of this shadowed edge must be adjusted inwards so that
	; it falls one shadow-width inside the boundary of the area.
	;
	; For example, with the shadow from the top-left, the bottom and right
	; edges get adjusted by this amount (shadow-width):
	;		***********   <- 'shadow width' space here
	;		*	  **
	;		*	  **
	;		*	  **
	;		************
	;		 ***********
	;		^
	;		'shadow width' space here
	;
	; In both cases we are adjusting the 'start' of the shadowed edge.
	; Note that for the left and top edges, we are adjusting the 'end'
	; of the edge by the same amount.
	;
	; If the shadow comes from the other direction, the amount of the
	; adjustment is still the same, but we are adjusting the 'end' of
	; the edge:
	;		**********    <- 'shadow width' space here
	;		***********
	;		**	  *
	;		**	  *
	;		**	  *
	;		 **********
	;		^
	;		'shadow width' space here
	;
	; The rule of thumb is this for shadowed edges is:
	;	if (negative edge) then
	;	    start    += shadowAmount
	;	    opposite -= shadowAmount + borderWidth
	;	else
	;	    end      -= shadowAmount
	;	    opposite += shadowAmount + borderWidth
	;	endif
	;
	; For non-shadowed edges, the rules are similar:
	;	if (negative edge) then
	;	    start    += shadowAmount
	;	    opposite -= borderWidth
	;	else
	;	    end      -= shadowAmount
	;	    opposite += borderWidth
	;	endif
	;
	; At this point, we have the following values set:
	;	LICL_borderStart/End/Side/Opposite are all set
	;	dl = DrawBorderFlags indicating:
	;		DBF_NEGATIVE	- negative adjustment needed
	;		DBF_SHADOW_FLAG - which edge to adjust (start/end)
	;		DBF_NO_SHADOW	- this side is not shadowed
	;		DBF_SIDE_SHADOWED - the paragraph has this
	;				    side shadowed w/ respect to the 
	;				    anchor
	;		DBF_DOUBLE	- this is a double border
	;		DBF_DONT_ADJUST_START - double-border w/ sides selected
	;		DBF_DONT_ADJUST_END   - such that we don't adjust parts
	;	ax = passed DBF_NEGATIVE
	;	bx = inset for wash color
	;	cx = shadow width or border width
	;
	
	;
	; So first we attack the problem of the width of the border.
	;
	push	bx
	test	dl,mask DBF_NEGATIVE
	jz	20$
	neg	bx
20$:
	;
	; bx	= Amount to adjust 'opposite' side by
	;
	mov	si,LICL_borderSide		; ss:bp.si <- ptr to side
	mov	ax,{word} ss:[bp][si]		; ax <- side value
	add	ax,bx				; ax <- value for opposite
	mov	si,LICL_borderOpposite		; ss:bp.si <- ptr to opposite
	mov	{word} ss:[bp][si],ax		; Save value for opposite
	pop	bx

	;
	; That was easy... now we set the start/end of the border side.
	;

	;
	; Check for no shadow on this side, or a double-border. In either
	; case, we're basically done with this side.
	;
	test	dl,mask DBF_NO_SHADOW or mask DBF_DOUBLE
	jnz	common
	
	; For shadowed sides (DBF_SIDE_SHADOWED set) we want to adjust
	; the start or end by the border width.
	;
	; For non-shadowed sides, we want to do the same adjustment, but
	; by the shadow width.
	;
	; cx	= shadow width
	; bx	= shadow width + border width
	;
	push	cx
						; Assume non-shadowed
	test	dl, mask DBF_SIDE_SHADOWED
	jz	gotAdjustAmount
	
	;
	; The side is a shadowed side. We want to draw the small-line part
	; of the border, but only if the border-width is larger than 1.
	;
	call	DrawSmallBorderThingy

gotAdjustAmount::
	;
	; cx	= border width (if shadowed side)
	;	= shadow width (if not shadowed side)
	;
	
	;
	; We want to make sure we adjust the correct edge. The DBF_SHADOW_FLAG
	; is set if we want to adjust the start of the border edge.
	;
	mov	si, LICL_borderStart		; Assume start edge
	test	dl,mask DBF_SHADOW_FLAG
	jnz	gotEdge
	mov	si, LICL_borderEnd
	neg	cx

gotEdge:
	add	{word} ss:[bp][si], cx
	pop	cx

common:
	;
	; Draw the border...
	;
	call	FillLICLRect

;-----------------------------------------------------------------------------
	; if double border then do inside

	test	dl, mask DBF_DOUBLE
	jz	noDouble
	test	dl, mask DBF_DONT_ADJUST_START
	jnz	40$
	mov	si, LICL_borderStart		;start inset
	add	{word} ss:[bp][si],cx
40$:
	test	dl, mask DBF_DONT_ADJUST_END
	jnz	50$
	mov	si, LICL_borderEnd		;end inset
	sub	{word} ss:[bp][si],cx
50$:
	test	dl,mask DBF_NEGATIVE
	jz	80$
	neg	cx
80$:
	mov	si, LICL_borderSide		;move line
	add	{word} ss:[bp][si],cx
	mov	si, LICL_borderOpposite		;move line
	add	{word} ss:[bp][si],cx
	call	FillLICLRect
noDouble:

	pop	LICL_rect.R_bottom
	pop	LICL_rect.R_right
	pop	LICL_rect.R_top
	pop	LICL_rect.R_left
	ret

DrawBorderSide	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSmallBorderThingy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine draws the thin-line part of a shadowed side.

CALLED BY:	DrawBorderSide
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars...
		cx	= Shadow width
		bx	= Shadow width + Border width
		dl	= DrawBorderFlags
		di	= GState handle to draw with
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Look at the following diagram:
		+---------------+
		|		|
		|		|
		|		|***
		|		|***
		|		|***
		|		|***
		+---------------+***
		   *****************
		   *****************
		   *****************
	Notice that the right and bottom edges are made up of two
	distinct line segments. The code in DrawBorderSide will draw
	the thick part. Our mission is to draw the thin part.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/23/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSmallBorderThingy	proc	near
	uses	ax, bx, cx, si
	.enter
	push	LICL_rect.R_top
	push	LICL_rect.R_left
	push	LICL_rect.R_bottom
	push	LICL_rect.R_right
	
	sub	bx, cx				; bx <- border width

	;
	; Setting the position for the border is easy...
	;	if DBF_NEGATIVE then
	;	    borderSide = borderOpposite + borderWidth
	;	else
	;	    borderSide = borderOpposite - borderWidth
	;	endif
	;
	test	dl, mask DBF_NEGATIVE
	jnz	gotBorderWidth
	neg	bx

gotBorderWidth:
	mov	si, LICL_borderOpposite		; si <- offset to save to
	mov	ax, {word} ss:[bp][si]		; ax <- value to start with
	add	ax, bx				; ax <- value to save
	mov	si, LICL_borderSide		; si <- offset to get from
	mov	{word} ss:[bp][si], ax		; Save new value
	
	;
	; Now we set the border-start or the border-end depending on what needs
	; adjusting. Here's the rule:
	;	if DBF_SHADOW_FLAG then
	;	    borderEnd = borderStart + shadowWidth
	;	else
	;	    borderStart = borderEnd - shadowWidth
	;
	push	di				; Save gstate handle
	mov	si, LICL_borderStart
	mov	di, LICL_borderEnd

	test	dl, mask DBF_SHADOW_FLAG
	jnz	gotStartEnd
	
	xchg	di, si				; di <- start
						; si <- end
	neg	cx

gotStartEnd:
	mov	ax, {word} ss:[bp][si]		; ax <- anchor value
	add	ax, cx				; ax <- new value
	mov	{word} ss:[bp][di], ax		; Save new value
	pop	di				; Restore gstate handle
	
	call	FillLICLRect			; Draw the part

	pop	LICL_rect.R_right
	pop	LICL_rect.R_bottom
	pop	LICL_rect.R_left
	pop	LICL_rect.R_top
	.leave
	ret
DrawSmallBorderThingy	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FillLICLRect

DESCRIPTION:	Fill the LICL_rect

CALLED BY:	INTERNAL

PASS:
	di - gstate
	ss:bp - LICL_vars

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

FillLICLRect	proc	near		uses ax, bx, cx, dx
	.enter

	mov	ax,LICL_rect.R_left
	mov	bx,LICL_rect.R_top
	mov	cx,LICL_rect.R_right
	mov	dx,LICL_rect.R_bottom
	call	GrFillRect

	.leave
	ret

FillLICLRect	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetBorderColorAndAttributes

DESCRIPTION:	Set the border color and attributes

CALLED BY:	INTERNAL

PASS:
	ss:bp - LICL vars

RETURN:
	Z flag - Set if no pattern

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/10/92		Initial version

------------------------------------------------------------------------------@
SetBorderColorAndAttributes	proc	near	uses ax, bx
	.enter

	mov	ax, LICL_paraAttr.VTPA_borderColor.low
	mov	bx, LICL_paraAttr.VTPA_borderColor.high
	call	GrSetAreaColor
	mov	al, LICL_paraAttr.VTPA_borderGrayScreen
	call	GrSetAreaMask

	mov	ax, {word} LICL_paraAttr.VTPA_borderPattern
	tst	ax
	pushf
	jz	10$
	call	GrSetAreaPattern
10$:
	popf

	.leave
	ret

SetBorderColorAndAttributes	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetPrevNextBorder

DESCRIPTION:	Get border flags for the previous and next lines

CALLED BY:	GetBorderAndFlags

PASS:	*ds:si	- Instance ptr
	bx.di	- Current line
	ss:bp	- LICL_vars structure:
			LICL_paraAttr set for this line
			LICL_lineBottom = top of this line
			LICL_lineHeight	= height of this line

RETURN:	LICL_prevLineB* - set
	LICL_nextLineB* - set
	LICL_paraAttr still set for this line

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
GetPrevNextBorder	proc	far
	class	VisTextClass
	uses	ax, bx, dx, di
	.enter
	call	GetPrevBorder

	;
	; Get paraAttr for next line
	;
	call	TL_LineNext			; bx.di <- next line
	jnc	hasNextLine

	;
	; No next line... Fake it :-)
	;
	clr	ax
	jmp	saveBorderFlags
hasNextLine:
	call	TL_LineToOffsetStart		; dx.ax <- start of line
	call	T_GetBorderInfo			; ax <- border flags
saveBorderFlags:
	mov	LICL_nextLineBorder, ax
	.leave
	ret
GetPrevNextBorder	endp

;---

GetPrevBorder	proc	near
	class	VisTextClass
	uses	ax, bx, dx, di
	.enter

	;
	; Get paraAttr for previous line
	;
	tstdw	bxdi
	jnz	notFirstLine

	;
	; No previous line... Fake it :-)
	;
	clr	ax
	jmp	saveBorderFlags

notFirstLine:
	;
	; There may not be a previous line, we may not have calculated the
	; line structures yet. This call might have been inspired by a call
	; from VisTextCalcHeight(). If there are no line structures then we
	; want to grab the previous lines start from the stack frame.
	;
	movdw	dxax, ss:[bp].LICL_prevLineStart

	push	di
	call	TextBorder_DerefVis_DI
	test	ds:[di].VTI_intFlags, mask VTIF_HAS_LINES
	pop	di
	jz	afterGotStart

	call	TL_LinePrevious			; bx.di <- previous line
	call	TL_LineToOffsetStart		; dx.ax <- start of line

afterGotStart:
	call	T_GetBorderInfo			; ax <- border flags
saveBorderFlags:
	mov	LICL_prevLineBorder, ax

	.leave
	ret

GetPrevBorder	endp

;----

TextBorder_DerefVis_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
TextBorder_DerefVis_DI	endp

TextBorder	ends
