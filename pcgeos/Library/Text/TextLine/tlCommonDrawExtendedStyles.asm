COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonDrawExtendedStyles.asm

AUTHOR:		John Wedgwood, Jul 10, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 7/10/92	Initial revision

DESCRIPTION:
	Handle drawing of extended styles.

	$Id: tlCommonDrawExtendedStyles.asm,v 1.1 97/04/07 11:21:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextBorder	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawAllExtendedStyles

DESCRIPTION:	Draw all extended styles

CALLED BY:	INTERNAL

PASS:
	*ds:si	= Instance
	ss:bp	= LICL_vars with these set:
			LICL_line
			LICL_lineStart
			LICL_theParaAttr
			LICL_paraAttrStart
			LICL_paraAttrEnd

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
	Tony	9/ 2/92		Initial version

------------------------------------------------------------------------------@
DrawAllExtendedStyles	proc	far	uses ax, dx
	.enter
	call	DrawTextBackgroundColor
	call	DrawBoxedText
	call	DrawButtonText

	.leave
	ret

DrawAllExtendedStyles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTextBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the background color behind the text on a line.

CALLED BY:	CommonLineClearArea
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars with these set:
				LICL_line
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
	Use a nice enumerating routine in the style code (as yet unwritten)
	to callback for each style run that I'm interested in.
	
	The callback will draw the background color for each text-run.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTextBackgroundColor	proc	near
	.enter
	mov	ax, mask VTES_BACKGROUND_COLOR
	mov	dx, offset DrawTextBackgroundColorCallback
	call	CallExtendedStyleEnum
	.leave
	ret
DrawTextBackgroundColor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallExtendedStyleEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up for a call to ExtendedStyleEnum

CALLED BY:	DrawTextBackgroundColor, DrawBoxedText,
		DrawButtonText
PASS:		*ds:si	= Instance
		ax	= VisTextExtendedStyle bit
		dx	= Callback routine
		ss:bp	= LICL_vars with these set:
				LICL_line
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallExtendedStyleEnum	proc	near	uses bx, di
	.enter

	push	ax				; Pass style bit
	push	dx				; Pass callback

	;
	; Figure the range we're interested in
	;
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line
	call	TL_LineGetCharCount		; dx.ax <- number of chars
	movdw	bxdi, ss:[bp].LICL_lineStart
	adddw	dxax, bxdi			; dxax = range end
	pushdw	dxax				; Pass the range end
	pushdw	bxdi
	
	call	TA_ExtendedStyleEnum		; Enumerate the entries
						; Fixes up the stack
	.leave
	ret
CallExtendedStyleEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBoxedText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the boxes around text on a line.

CALLED BY:	CommonLineClearArea
PASS:		*ds:si	= Instance
		ss:bx	= Pointer to a VisTextRange containing the
				range to place the box around.
		ss:bp	= LICL_vars with these set:
				LICL_line
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Use a nice enumerating routine in the style code (as yet unwritten)
	to callback for each style run that I'm interested in.
	
	The callback will draw the boxes for each text-run.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawBoxedText	proc	near
	.enter
	mov	ax, mask VTES_BOXED
	mov	dx, offset DrawBoxedTextCallback
	call	CallExtendedStyleEnum
	.leave
	ret
DrawBoxedText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawButtonText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the buttons around text on a line.

CALLED BY:	CommonLineClearArea
PASS:		*ds:si	= Instance
		ss:bx	= Pointer to a VisTextRange containing the
				range to place the button around.
		ss:bp	= LICL_vars with these set:
				LICL_line
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
	Use a nice enumerating routine in the style code (as yet unwritten)
	to callback for each style run that I'm interested in.
	
	The callback will draw the buttons for each text-run.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawButtonText	proc	near
	.enter
	mov	ax, mask VTES_BUTTON
	mov	dx, offset DrawButtonTextCallback
	call	CallExtendedStyleEnum
	.leave
	ret
DrawButtonText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTextBackgroundColorCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the background color for a hunk of text.

CALLED BY:	ExtendedStyleEnum
PASS:		*ds:si	= Instance
		ss:bx	= Pointer to a VisTextRange
		ss:cx	= VisTextChrAttr
		di	= gstate
		ss:bp	= LICL_vars w/ these set:
				LICL_line
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
	Find left/right edge of range to color
	Set color
	Draw rectangle

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTextBackgroundColorCallback	proc	near
	class	VisTextClass
	.enter

	;
	; Area mask (gray-screen)
	;
	push	bx
	mov	bx, cx
	mov	al, ss:[bx].VTCA_bgGrayScreen	; al <- SystemDrawMask
	call	GrSetAreaMask			; Set the gray-screen

	;
	; Pattern
	;
	mov	al, ss:[bx].VTCA_bgPattern.GP_type ; al <- PatternType
	mov	ah, ss:[bx].VTCA_bgPattern.GP_data ; ah <- Data
	call	GrSetAreaPattern		; Set the pattern

	;
	; Area color
	;
	mov	ax, {word} ss:[bx].VTCA_bgPattern
	call	GrSetAreaPattern
						; al...bh <- color + flags
	mov	ax, {word} ss:[bx].VTCA_bgColor.CQ_redOrIndex
	mov	bx, {word} ss:[bx].VTCA_bgColor.CQ_green
	call	GrSetAreaColor			; Set the color
	pop	bx				; Restore frame ptr

	;
	; Now get the coordinates and draw the background.
	;
	call	GetRangeCoordinates		; ax...dx <- coords of range
	cmp	ax, cx
	jz	afterDraw
	call	GrFillRect			; Fill the background
afterDraw:

	clr	ax
	call	GrSetAreaPattern

	.leave
	ret
DrawTextBackgroundColorCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRangeCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the coordinates of a range of text on a line.

CALLED BY:	DrawTextBackgroundColorCallback, DrawBoxedTextCallback,
		DrawButtonTextCallback
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		ss:bx	= VisTextRange
RETURN:		ax...dx	= Coordinates of the rectangle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRangeCoordinates	proc	near
	uses	di
	.enter
	;
	; Compute the left edge of the range to color
	;
	push	bx, bp				; Save frame ptrs
	movdw	dxax, ss:[bx].VTR_start		; dx.ax <- start position
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line
	mov	bp, 0x7fff			; Return position
	call	TL_LineTextPosition		; bx <- pixel position
						; Nukes ax, dx
	mov	ax, bx				; ax <- pixel position
	pop	bx, bp				; Restore frame ptrs
	
	;
	; Compute the right edge of the range to color
	;
	push	ax, bx, bp			; Save left, frame ptrs
	movdw	dxax, ss:[bx].VTR_end		; dx.ax <- end position
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line
	mov	bp, 0x7fff			; Return position
	call	TL_LineTextPosition		; bx <- pixel position
						; Nukes ax, dx
	mov	cx, bx				; ax <- pixel position
	pop	ax, bx, bp			; Restore left,  frame ptrs
	
	;
	; *ds:si= Instance ptr
	; ax	= Left edge
	; cx	= Right edge
	; ss:bp	= LICL_vars
	; ss:bx	= VisTextRange
	; On stack:
	;	GState to use	<<-- Top of stack
	;
	; Figure the left edge of the line so we can adjust the left/right
	;
	push	ax, bx				; Save left, frame ptr
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line
	call	TL_LineGetLeftEdge		; ax <- offset to left edge
	mov	di, ax				; di <- offset to left edge
	pop	ax, bx				; Restore left, frame ptr
	
	;
	; Adjust the left and right edges.
	;
	add	ax, di
	add	cx, di

	;
	; Figure the top/bottom of the line
	;
	push	ax, cx				; Save left, right
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line
	call	TL_LineGetTop			; dx.bl <- top of line
	ceilwbf	dxbl, ax			; ax <- top of line
	push	ax				; Save top of line
	movwbf	cxal, dxbl

	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line
	call	TL_LineGetHeight		; dx.bl <- height of line
	addwbf	dxbl, cxal			; dx.bl <- next line
	ceilwbf	dxbl, dx			; dx <- bottom
	;
	; *ds:si= Instance ptr
	; cx	= Right edge
	; ss:bp	= LICL_vars
	; dx	= Line height
	; On stack:
	;	Top edge	<<-- Top of stack
	;	Right edge
	;	Left edge
	;	GState to use
	;
	pop	bx				; bx <- top of line
	pop	ax, cx				; cx <- right edge
						; ax <- left edge of line

	;
	; Finally, limit the right edge to the bounds of the ruler, so that
	; we don't color beyond the right margin.
	;
	cmp	cx, LICL_realRightMargin
	jbe	gotRight
	mov	cx, LICL_realRightMargin
gotRight:
	.leave
	ret
GetRangeCoordinates	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBoxedTextCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a box around some text.

CALLED BY:	ExtendedStyleEnum
PASS:		*ds:si	= Instance
		ss:bx	= Pointer to a VisTextRange indicating the range of
				text to box.
		ss:cx	= VisTextChrAttr
		di	= gstate		
		ss:bp	= LICL_vars w/ these set:
				LICL_line
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawBoxedTextCallback	proc	near
	clr	dx				;not button
	GOTO	DrawBoxCommon
DrawBoxedTextCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawButtonTextCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a button around some text.

CALLED BY:	ExtendedStyleEnum
PASS:		*ds:si	= Instance
		ss:bx	= Pointer to a VisTextRange indicating the range of
				text to button.
		ss:cx	= VisTextChrAttr
		di	= gstate		
		ss:bp	= LICL_vars w/ these set:
				LICL_line
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawButtonTextCallback	proc	near
	mov	dx, 1				; button
	FALL_THRU	DrawBoxCommon
DrawButtonTextCallback	endp

;---

DrawBoxCommon	proc	near

	call	SetBorderColorAndAttributes
	pushf
	
	; Now get the coordinates and draw the frame.

	push	dx
	call	GetRangeCoordinates		; ax...dx <- coords of range
	pop	si				; si = button flag
	cmp	ax, cx
	jz	afterDraw

	; if we are drawing a button then bring the right and bottom in one

	tst	si
	jz	notButton1
	dec	cx
	dec	dx
notButton1:

	; draw left

	push	cx
	mov	cx, ax
	inc	cx
	call	GrFillRect
	pop	cx

	; draw top

	push	dx
	mov	dx, bx
	inc	dx
	call	GrFillRect
	pop	dx

	; draw right

	push	ax
	mov	ax, cx
	dec	ax
	call	GrFillRect
	pop	ax

	; draw bottom

	push	bx
	mov	bx, dx
	dec	bx
	call	GrFillRect
	pop	bx

	; if drawing a button then draw the shaded part

	tst	si
	jz	notButton2

	; draw shadow right

	push	ax, bx, cx
	mov	ax, cx
	inc	cx
	inc	bx
	call	GrFillRect
	pop	ax, bx, cx

	; draw shadow bottom

	mov	bx, dx
	inc	dx
	inc	ax
	call	GrFillRect

notButton2:

afterDraw:

	popf
	jz	30$
	clr	ax
	call	GrSetAreaPattern
30$:
	ret

DrawBoxCommon	endp

TextBorder	ends
