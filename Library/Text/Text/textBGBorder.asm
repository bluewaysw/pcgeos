COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User interface.
FILE:		textBGBorder.asm

AUTHOR:		Tony

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	5/22/89		Initial revision

DESCRIPTION:
	Low level utility routines for implementing the methods defined on
	VisTextClass.

	$Id: textBGBorder.asm,v 1.1 97/04/07 11:18:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		T_EnsureCorrectParaAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that the paragraph attributes in an LICL_vars
		structure are up to date.

CALLED BY:	
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars including:
				LICL_paraAttrStart/End
				LICL_region		(region for ruler)
				LICL_lineBottom		(y pos for ruler)
				LICL_lineHeight		(line height for ruler)
		dx.ax	= Offset to make attributes valid for
RETURN:		LICL_vars up to date
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	LICL_lineBottom and LICL_lineHeight are poorly named for the
	function of this routine. The calculation code uses LICL_lineBottom
	as the bottom of the previous line, therefore it can be considered
	as the top of the current line.
	
	The calculation code uses LICL_lineHeight as the height of the current
	line, so you can see that the combination of LICL_lineBottom and
	LICL_lineHeight gives the range of vertical area within LICL_region
	that is covered by this line.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
T_EnsureCorrectParaAttr	proc	far
	cmpdw	dxax, LICL_paraAttrStart
	jb	getParaAttr
	cmpdw	dxax, LICL_paraAttrEnd
	jae	getParaAttr

	; if the region is non-rectangular then always get new attributes
	; because the right margin can change for each line

	push	cx
	mov	cx, ss:[bp].LICL_region
	call	TR_RegionIsComplex
	pop	cx
	jnc	paraAttrOK

getParaAttr:
	call	T_GetNewParaAttr
paraAttrOK:
	ret
T_EnsureCorrectParaAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		T_GetNewParaAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get new paragraph attributes

CALLED BY:	T_EnsureCorrectParaAttr, CalculateHeightCallback
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		dx.ax	= Offset to get attributes for
RETURN:		Paragraph attributes reset
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
T_GetNewParaAttr	proc	far
	uses	ax, bx, cx, dx
	.enter
	push	bp, di
	;
	; Grab parameters for TA_GetParaAttrForPosition
	;
	mov	cx, ss:[bp].LICL_region
	ceilwbf	ss:[bp].LICL_lineBottom, bx	;this is really the line top
	ceilwbf	ss:[bp].LICL_lineHeight, di

	lea	bp, ss:[bp].LICL_theParaAttr	; ss:bp <- ptr to the paraAttr

	;
	; Load up the parameters for getting the ruler.
	;
	call	TA_GetParaAttrForPosition	; dx.ax <- start of range
						; cx.bx <- end of range
						; attributes buffer filled
	pop	bp, di

	movdw	LICL_paraAttrStart,dxax
	movdw	LICL_paraAttrEnd,cxbx

	mov	ax, LICL_paraAttr.VTPA_rightMargin
	mov	LICL_realRightMargin, ax
	tst	LICL_paraAttr.VTPA_borderFlags
	jz	noBorder

	;
	; Adjust right margin.
	;
	push	si, di

	;
	; search for a tab at the right margin
	;
	push	bp
	clr	cx
	clr	di				;assume no tab found
	mov	cl, LICL_paraAttr.VTPA_numberOfTabs
	jcxz	afterTabSearch
	lea	bp, LICL_paraAttr.VTPA_tabList
tabLoop:
	cmp	ax, ss:[bp].T_position
	jz	foundTabAtRightMargin
	add	bp, size Tab
	loop	tabLoop
	jmp	afterTabSearch

foundTabAtRightMargin:
	mov	di, bp

afterTabSearch:
	pop	bp

	mov	cx, mask VTPBF_RIGHT
	mov	dx, LICL_paraAttr.VTPA_borderFlags
	call	GetBorderInfo			;ax = ammount to inset
	sub	LICL_realRightMargin, ax

	;
	; if tab at right margin then inset it
	;
	tst	di
	jz	noTabInset
	sub	ss:[di].T_position, ax
noTabInset:

	;
	; We adjust the smaller of the left/para margin in by the border
	; amount. If the other margin then becomes smaller, then we set the
	; two of them to be the same value.
	;
	mov	cx, mask VTPBF_LEFT
	mov	dx, LICL_paraAttr.VTPA_borderFlags
	call	GetBorderInfo			;ax = ammount to inset

	mov	cx, LICL_paraAttr.VTPA_leftMargin
	cmp	cx, LICL_paraAttr.VTPA_paraMargin
	jbe	adjustLeft
	;
	; Adjust the paragraph margin
	;
	add	LICL_paraAttr.VTPA_paraMargin, ax
	cmp	cx, LICL_paraAttr.VTPA_paraMargin
	jae	afterMarginAdjust
	
	;
	; The paragraph margin is now larger than the left margin. Force them
	; to be equal.
	;
	mov	ax, LICL_paraAttr.VTPA_paraMargin
	mov	LICL_paraAttr.VTPA_leftMargin, ax
	jmp	afterMarginAdjust

adjustLeft:
	;
	; Adjust the left margin
	;
	add	LICL_paraAttr.VTPA_leftMargin, ax
	
	mov	cx, LICL_paraAttr.VTPA_paraMargin
	cmp	cx, LICL_paraAttr.VTPA_leftMargin
	jae	afterMarginAdjust
	
	;
	; The left margin is now larger than the paragraph margin. Force them
	; to be equal.
	;
	mov	ax, LICL_paraAttr.VTPA_leftMargin
	mov	LICL_paraAttr.VTPA_paraMargin, ax

afterMarginAdjust:
	pop	si, di

noBorder:
	.leave
	ret
T_GetNewParaAttr	endp


TextFixed	ends

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

TextBorder	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		T_GetParaAttrAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the VTPA_attributes field of the VisTextParaAttr for
		a given offset.

CALLED BY:	HandleKeepWithNext
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		dx.ax	= Offset into the text
RETURN:		ax	= VTPA_attributes field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
T_GetParaAttrAttributes	proc	far
	uses	bx, cx, bp, di
	.enter
	;
	; Assume paragraph attributes we have are valid.
	;
	mov	cx, LICL_paraAttr.VTPA_attributes

	cmpdw	dxax, LICL_paraAttrStart
	jb	getParaAttr
	cmpdw	dxax, LICL_paraAttrEnd
	jb	quit

getParaAttr:
	;
	; We need to get the attributes ourselves.
	;
	sub	sp, size VisTextMaxParaAttr	; Allocate space for the info
	mov	bp, sp				; ss:bp <- new buffer
	
	clr	cx				; cx <- region
	clr	bx				; bx <- Y position
	clr	di				; di <- height of line at <bx>
	call	TA_GetParaAttrForPosition	; Fill in attr structure
	
	mov	cx, ss:[bp].VTPA_attributes	; cx <- attributes from ruler
	
	add	sp, size VisTextMaxParaAttr	; Restore stack

quit:
	mov	ax, cx				; ax <- attributes to return
	.leave
	ret
T_GetParaAttrAttributes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		T_GetBorderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about a border.

CALLED BY:	GetPrevBorder, GetPrevNextBorder
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		dx.ax	= Offset to get information for
RETURN:		ax	= Border flags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
T_GetBorderInfo	proc	far	uses	cx, bp, di
	.enter
	
	cmpdw	dxax, LICL_paraAttrStart
	jb	getParaAttr
	cmpdw	dxax, LICL_paraAttrEnd
	jb	useParaAttrInLICL

getParaAttr:
	;
	; We need to get the attributes ourselves.
	;
	mov	cx, ss:[bp].LICL_region		; cx <- region
	ceilwbf	ss:[bp].LICL_lineBottom, bx	; bx <- Y position

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	clr	di				; di <- height of line at <bx>

	sub	sp, size VisTextMaxParaAttr	; Allocate space for the info
	mov	bp, sp				; ss:bp <- new buffer
	call	TA_GetParaAttrForPosition	; Fill in attr structure
	mov	ax, ss:[bp].VTPA_borderFlags
	add	sp, size VisTextMaxParaAttr	; Restore stack

	pop	di
	call	ThreadReturnStackSpace

quit:
	.leave
	ret

useParaAttrInLICL:
	;
	; Use the values already in the stack frame.
	;
	mov	ax, LICL_paraAttr.VTPA_borderFlags
	jmp	quit
	
T_GetBorderInfo	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CalcRealBorder

DESCRIPTION:	Calculate the real border flags

CALLED BY:	INTERNAL

PASS:	ss:bp - LICL_frame
		LICL_rect - bounds of line, including border
		LICL_lineFlags - set
		LICL_nextLineB* - set
		LICL_prevLineB* - set

RETURN:	dx - VisTextParaBorderFlags

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

CalcRealBorder	proc	far
	uses	cx
	.enter
	mov	dx, LICL_paraAttr.VTPA_borderFlags	;flags to pass

	;
	; if the "draw inner lines" flag is set then definitely draw the
	; top line
	;
	test	dx, mask VTPBF_DRAW_INNER_LINES
	jnz	10$

	;
	; otherwise only draw the border if the line above differs in one
	; of these border flags:
	;	left, top, right, bottom
	;	double, draw inner
	;
	mov	ax, LICL_prevLineBorder
	xor	ax, dx					;ax = bits that changed
	test	ax, mask VTPBF_LEFT or mask VTPBF_TOP or mask VTPBF_RIGHT or \
		    mask VTPBF_BOTTOM or mask VTPBF_DOUBLE or \
		    mask VTPBF_DRAW_INNER_LINES
	jnz	10$
	and	dx, not mask VTPBF_TOP
10$:
	;
	; If there is no top border and the draw inner lines bit is set
	; then we want to draw the bottom border.
	;
	test	dx, mask VTPBF_TOP
	jnz	15$
	test	dx, mask VTPBF_DRAW_INNER_LINES
	jnz	20$
15$:
	;
	; otherwise only draw the border if the line above differs in one
	; of these border flags:
	;	left, top, right, bottom
	;	double, draw inner
	;
	mov	ax, LICL_nextLineBorder
	xor	ax, LICL_paraAttr.VTPA_borderFlags	;ax = bits that changed
	test	ax, mask VTPBF_LEFT or mask VTPBF_TOP or mask VTPBF_RIGHT or \
		    mask VTPBF_BOTTOM or mask VTPBF_DOUBLE or \
		    mask VTPBF_DRAW_INNER_LINES
	jnz	20$
	and	dx, not mask VTPBF_BOTTOM
20$:

	mov	ax, ss:[bp].LICL_lineFlags
	test	ax, mask LF_STARTS_PARAGRAPH
	jnz	30$
	and	dx, not mask VTPBF_TOP
30$:
	test	ax, mask LF_ENDS_PARAGRAPH
	jnz	40$
	and	dx, not mask VTPBF_BOTTOM
40$:
	.leave
	ret

CalcRealBorder	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CalcBorderSpacing

DESCRIPTION:	Inset the rectangle for the BG color for the border

CALLED BY:	INTERNAL

PASS:
	cx - VTPBF_{LEFT,TOP,RIGHT,BOTTOM} for correct side
	ss:bp - LICL_vars:
		LICL_paraAttr - set
		LICL_rect - bg color rect

RETURN:
	ax - border spacing

DESTROYED:
	bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

CalcBorderSpacing	proc	far	uses si
	.enter

	call	CalcRealBorder			;returns dx = border flags
	call	GetBorderInfo			;returns ax = total

	.leave
	ret

CalcBorderSpacing	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetBorderInfo

DESCRIPTION:	Return border information

CALLED BY:	INTERNAL

PASS:
	cx - side to calculate for (mask VTPBF_{LEFT,TOP,RIGHT,BOTTOM} )
	dx - VisTextParaBorderFlags
	LICL_paraAttr.VTPA_borderWidth
	LICL_paraAttr.VTPA_borderSpacing
	LICL_paraAttr.VTPA_borderShadow

RETURN:

	if doubled border:
		ax = 2*width + shadow + spacing (ammount to add for border)
		bx = border width
		cx = border width + shadow width
		si = 2*width + shadow (ammount to add for bg color area)

	if single border:
		ax = width + shadow + spacing (ammount to add for border)
		bx = width + shadow
		cx = shadow width
		si = width + shadow (ammount to add for bg color area)

	dl = DrawBorderFlags, w/ DBF_SHADOW_FLAG set correctly.
		This flag is non-zero if the edge in question should
		have its start adjusted and clear if the end should
		be adjusted.
		
		The best way to think of this is by looking at examples
		of shadowed borders with the values in question.
			   0		           1            
			********	         ********        
			*      **	        **      *
		      0 *  tl  ** 1	      1 **  tr  * 0
			*      **	        **      *
			*********	        *********       
			 ********	        ********       
			   1		           0

			   0		           1            
			********	         ********
			*********	        *********
			**      *	        *      **
		      0 **  br  * 1	      1 *  bl  ** 0
			**      *	        *      **
			 ********	        ********
			   1		           0

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

GetBorderInfo	proc	far
	test	cx,dx
	jnz	1$
	clr	ax
	clr	bx
	clr	cx
	clr	dx
	clr	si
	ret
1$:

	; get border width

	mov	ax, cx
	mov	bx, dx

	mov_tr	dx, ax					;dx saves ax
	mov	al, LICL_paraAttr.VTPA_borderWidth
	call	convertWidth
	xchg	ax, dx					;dx = width

	test	bx, mask VTPBF_DOUBLE
	jz	single

;--------

	; double border -> handle specially

	; if drawing left or right
	;	if no top then don't adjust START
	;	if no bottom then don't adjust END

	mov	al, mask DBF_DOUBLE		;flags to return
	test	ah, (mask VTPBF_LEFT or mask VTPBF_RIGHT) shr 8
	jz	4$
	test	bx, mask VTPBF_TOP
	jnz	3$
	or	al, mask DBF_DONT_ADJUST_START
3$:
	test	bx, mask VTPBF_BOTTOM
	jnz	4$
	or	al, mask DBF_DONT_ADJUST_END
4$:
	push	ax

	mov_tr	si, ax					;si saves ax
	mov	al, LICL_paraAttr.VTPA_borderShadow
	call	convertWidth
	xchg	ax, si					;si = width

	mov_tr	bx, ax					;bx saves ax
	mov	al, LICL_paraAttr.VTPA_borderSpacing
	call	convertWidth
	xchg	ax, bx					;bx = spacing

	; bx = spacing, dx = width, si = shadow

	xchg	bx, dx			;bx = width, dx = spacing
	mov	cx, bx			;cx = width
	add	cx, si			;cx = width + shadow
	mov	ax, cx			;ax = width + shadow
	add	ax, bx			;ax = 2*width + shadow
	mov	si, ax			;si = 2*width + shadow
	add	ax, dx			;ax = 2*width + shadow + spacing

	pop	dx			;recover flags
	ret

;--------

single:
	; test for shadow on this side

	clr	al
	mov	si,bx
	and	si,mask VTPBF_ANCHOR

	; if there is no shadow, we can skip all of this
	test	bx, mask VTPBF_SHADOW
	jz	skipShadowStuff

	;;;mov	cl, offset VTPBF_ANCHOR	;BIT 0
	;;;shr	si,cl

	; set flags

	test	ah, cs:[borderShadowFlagTable][si]
	jz	10$
	or	al, mask DBF_SHADOW_FLAG
10$:
	test	ah, cs:[borderShadowTable][si]
	jz	20$
	or	al, mask DBF_SIDE_SHADOWED
20$:
	test	ah, cs:[borderRequiresTop][si]
	jz	30$
	test	bx, mask VTPBF_TOP
	jnz	30$
	or	al, mask DBF_NO_SHADOW
30$:
	test	ah, cs:[borderRequiresBottom][si]
	jz	40$
	test	bx, mask VTPBF_BOTTOM
	jnz	40$
	or	al, mask DBF_NO_SHADOW
40$:

skipShadowStuff:

	; add in shadow

	clr	si				;assume no shadow
	test	bx, mask VTPBF_SHADOW
	jz	noShadowThisSide		;branch if none

	mov_tr	si, ax
	mov	al, LICL_paraAttr.VTPA_borderSpacing
	call	convertWidth
	xchg	ax, si					;si = shadow
	tst	si
	jnz	nonZeroShadow
	or	al,mask DBF_NO_SHADOW
nonZeroShadow:

	;
	; We always want to return the shadow width in cx (which gets it from
	; the value in si, calculated here).
	;
	mov_tr	si, ax			;si <- flags
	mov	al, LICL_paraAttr.VTPA_borderShadow
	call	convertWidth		;ax <- shadow width
	xchg	ax, si			;si <- shadow width
					;ax <- flags (again)
	;
	; We adjust the width+shadow value only if this side is shadowed.
	;
	test	al, mask DBF_SIDE_SHADOWED ;if no shadow this side then zero
	jz	noShadowThisSide
	
	add	dx,si			;dx <- width + shadow
					;si <- shadow width
noShadowThisSide:

	; add in spacing

	mov_tr	bx, ax					;bx saves ax
	mov	al, LICL_paraAttr.VTPA_borderSpacing
	call	convertWidth
	xchg	ax, bx					;bx = spacing

	; al= flags, bx = spacing, dx = (width + shadow), si = shadow

	mov	cx, si			;cx = shadow
	mov	si, dx			;si = width + shadow
	xchg	ax, dx			;ax = width + shadow, dl = flags
	xchg	bx, ax			;bx = width + shadow, ax = spacing
	add	ax, bx			;ax = width + shadow + spacing

	ret

convertWidth:
	clr	ah
	add	ax, 4
	shr	ax
	shr	ax
	shr	ax
	retn

borderShadowTable	label	byte
	byte	(mask VTPBF_RIGHT or mask VTPBF_BOTTOM) shr 8	;SA_TOP_LEFT
	byte	(mask VTPBF_LEFT or mask VTPBF_BOTTOM) shr 8	;SA_TOP_RIGHT
	byte	(mask VTPBF_RIGHT or mask VTPBF_TOP) shr 8	;SA_BOTTOM_LEFT
	byte	(mask VTPBF_LEFT or mask VTPBF_TOP) shr 8	;SA_BOTTOM_RIGHT

	;
	; This list maps an anchor point and an edge and tells whether or not
	; that edge should have its start or end adjusted, if it has a shadow.
	;
borderShadowFlagTable	label	byte
	byte	(mask VTPBF_RIGHT or mask VTPBF_BOTTOM) shr 8	;SA_TOP_LEFT
	byte	(mask VTPBF_LEFT or mask VTPBF_TOP) shr 8	;SA_TOP_RIGHT
	byte	(mask VTPBF_LEFT or mask VTPBF_TOP) shr 8	;SA_BOTTOM_LEFT
	byte	(mask VTPBF_RIGHT or mask VTPBF_BOTTOM) shr 8	;SA_BOTTOM_RIGHT

borderRequiresTop	label	byte
	byte	(mask VTPBF_RIGHT) shr 8			;SA_TOP_LEFT
	byte	(mask VTPBF_LEFT) shr 8				;SA_TOP_RIGHT
	byte	(mask VTPBF_LEFT) shr 8				;SA_BOTTOM_LEFT
	byte	(mask VTPBF_RIGHT) shr 8			;SA_BOTTOM_RIGHT

borderRequiresBottom	label	byte
	byte	(mask VTPBF_LEFT) shr 8				;SA_TOP_LEFT
	byte	(mask VTPBF_RIGHT) shr 8			;SA_TOP_RIGHT
	byte	(mask VTPBF_RIGHT) shr 8			;SA_BOTTOM_LEFT
	byte	(mask VTPBF_LEFT) shr 8				;SA_BOTTOM_RIGHT

GetBorderInfo	endp

TextBorder	ends
