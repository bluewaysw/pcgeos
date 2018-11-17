COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonInvert.asm

AUTHOR:		John Wedgwood, Jan  3, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 3/92	Initial revision

DESCRIPTION:
	Code for inverting ranges on lines.

	$Id: tlCommonInvert.asm,v 1.1 97/04/07 11:21:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineInvertRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert a range on a line.

CALLED BY:	SmallLineInvertRange, LargeLineInvertRange
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Size of the line/field data
		ss:bp	= LICL_vars with:
			    LICL_range holds the range to invert
			    VTR_start = 0 for line start
			    VTR_end   = TEXT_ADDRESS_PAST_END for line end
			    LICL_region set
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineInvertRange	proc	near
	uses	ax, bx, dx
	.enter
	;
	; Check for a hidden line (height of zero)
	;
	tstwbf	es:[di].LI_hgt
	jz	quit

	;
	; We'll be setting bx up to hold:
	;	bit 0: 0 always
	;	bit 1:		0: Invert from some position
	;			1: Invert from start
	;	bit 2:		0: Invert to some position
	;			1: Invert to end
	;
	clr	bx				; Assume pos->pos

	movdw	dxax, ss:[bp].LICL_lineStart	; dx.ax <- start of line
	cmpdw	dxax, ss:[bp].LICL_range.VTR_start
	jae	invertFromStart

	tstdw	ss:[bp].LICL_range.VTR_start
	jnz	gotStart

invertFromStart:
	or	bx, 2				; start->???

gotStart:

	CommonLineAddCharCount			; dx.ax <- end of line
	cmpdw	dxax, ss:[bp].LICL_range.VTR_end
	jbe	invertToEnd

	cmpdw	ss:[bp].LICL_range.VTR_end, TEXT_ADDRESS_PAST_END
	jne	gotEnd

invertToEnd:
	or	bx, 4				; ???->end

gotEnd:

	;
	; bx	= Index into table of near routines
	; es:di	= Line
	; ss:bp	= LICL_vars set
	;
	call	cs:invertRangeHandlers[bx]		; Call the handler

quit:
	.leave
	ret
CommonLineInvertRange	endp

invertRangeHandlers	label	word
	word	offset cs:InvertPosToPos
	word	offset cs:InvertStartToPos
	word	offset cs:InvertPosToEnd
	word	offset cs:InvertStartToEnd


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertPosToPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert from one position on a line to another.

CALLED BY:	CommonLineInvertRange via invertRangeHandlers
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Size of the line/field data
		ss:bp	= LICL_vars filled in
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertPosToPos	proc	near
	uses	ax, bx, dx
	.enter
	
	push	ss:[bp].LICL_region	; Save the region we're inverting in

	;
	; Compute the position for the start of the invert.
	;
	pushdw	ss:[bp].LICL_range.VTR_start
	movdw	dxax, ss:[bp].LICL_lineStart
	mov	bx, 0x7fff		; Compute until dx.ax is reached
	call	CommonLineTextPosition	; bx <- pixel offset from line-left
					; Nukes dx.ax
	CommonLineGetAdjustment		; ax <- adjustment
	add	bx, ax			; bx <- final position
	
	push	bx			; Save left edge for LineInvertArea()

	;
	; Compute the position for the end of the range.
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; ss:bp	= LICL_vars
	; On stack:
	;	Left edge of area to invert
	;
	pushdw	ss:[bp].LICL_range.VTR_end
	movdw	dxax, ss:[bp].LICL_lineStart
	mov	bx, 0x7fff		; Compute until dx.ax is reached
	call	CommonLineTextPosition	; bx <- pixel offset from line-left
					; Nukes dx.ax
	CommonLineGetAdjustment		; ax <- adjustment
	add	bx, ax			; bx <- final position

	push	bx			; Save right edge for LineInvertArea()

	pushdw	ss:[bp].LICL_line	; Save the line we're inverting on

	clr	bx			; No possibility of page break

	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; bx	= Height of page-break if any
	; On stack:
	;   (1)	Line we're inverting on
	;   (2)	Right edge of area to invert
	;   (3)	Left edge of area to invert
	;
	; Check for line ends in page break. If it does, want to invert
	; the page break.
	;
	call	LineInvertArea		; Invert the area
	.leave
	ret
InvertPosToPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertStartToPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert from the start of a line to a given position.

CALLED BY:	CommonLineInvertRange via invertRangeHandlers
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Size of the line/field data
		ss:bp	= LICL_vars filled in
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertStartToPos	proc	near
	uses	bx
	.enter
	
	push	ss:[bp].LICL_region	; Save the region we're inverting in

	call	LineComputeLineStartPos	; bx <- left edge for LineInvertArea
	push	bx			; Save left edge for LineInvertArea

	call	LineComputeEndPos	; bx <- right edge for LineInvertArea
	push	bx			; Save right edge for LineInvertArea

	pushdw	ss:[bp].LICL_line	; Save the line we're inverting on
	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; On stack:
	;   (1)	Line we're inverting on
	;   (2)	Right edge of area to invert
	;   (3)	Left edge of area to invert
	;
	clr	bx			; No possibility of page break
	call	LineInvertArea		; Invert the area
	.leave
	ret
InvertStartToPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertPosToEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert from a position on a line to the end.

CALLED BY:	CommonLineInvertRange via invertRangeHandlers
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Size of the line/field data
		ss:bp	= LICL_vars filled in
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertPosToEnd	proc	near
	uses	bx
	.enter
	
	push	ss:[bp].LICL_region	; Save the region we're inverting in

	;
	; Compute the position for the start of the range.
	;
	call	LineComputeStartPos	; bx <- left for LineInvertRange
	push	bx			; Save left for LineInvertRange

	call	LineComputeLineEndPos	; bx <- end of line
	push	bx			; Save right for LineInvertRange

	pushdw	ss:[bp].LICL_line	; Save the line we're inverting on

	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; bx	= Height of page-break if any
	; On stack:
	;   (1)	Line we're inverting on
	;   (2)	Right edge of area to invert
	;   (3)	Left edge of area to invert
	;
	; Check for line ends in page break. If it does, want to invert
	; the page break.
	;
	call	LineInvertArea		; Invert the area
	.leave
	ret
InvertPosToEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertStartToEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert an entire line

CALLED BY:	CommonLineInvertRange via invertRangeHandlers
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Size of the line/field data
		ss:bp	= LICL_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertStartToEnd	proc	near
	uses	ax, bx, dx
	.enter
	
	push	ss:[bp].LICL_region	; Save the region we're inverting in

	call	LineComputeLineStartPos	; bx <- left edge for LineInvertArea
	push	bx
	call	LineComputeLineEndPos	; bx <- right edge for LineInvertArea
	push	bx

	pushdw	ss:[bp].LICL_line	; Save the line we're inverting on

	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; On stack:
	;   (1)	Line we're inverting on
	;   (2)	Right edge of area to invert
	;   (3)	Left edge of area to invert
	;
	; Check for line ends in page break. If it does, want to invert
	; the page break.
	;
	call	LineInvertArea		; Invert area
	.leave
	ret
InvertStartToEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineComputeLineStartPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the position of the start of the line.

CALLED BY:	InvertStartToPos, InvertStartToEnd
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		ss:bp	= LICL_vars
RETURN:		bx	= Start of line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineComputeLineStartPos	proc	near
	uses	ax
	.enter
	CommonLineGetAdjustment		; ax <- adjustment
	mov	bx, ax			; bx <- left edge to invert
	.leave
	ret
LineComputeLineStartPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineComputeLineEndPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the end position on a line.

CALLED BY:	InvertPosToEnd, InvertStartToEnd
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		ss:bp	= LICL_vars
RETURN:		bx	= End of line
			= -1, if we want to invert to right edge of the region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineComputeLineEndPos	proc	near
	uses	ax
	.enter
	call	CommonLineGetFlags	; ax <- LineFlags

	;
	; Removed 8/26/99 by Tony.  This causes incorrect inversion in the
	; browser when selecting across several regions.  I can't figure
	; out what -1 is supposed to do
	;
;;;	mov	bx, -1			; Assume has a break
;;;
;;;	test	ax, mask LF_ENDS_IN_COLUMN_BREAK or \
;;;		    mask LF_ENDS_IN_SECTION_BREAK
;;;	jnz	quit

	;
	; Compute the right edge of the line.
	;
	call	LineGetLastFieldEnd	; bx <- end of last field on line
	CommonLineGetAdjustment		; ax <- adjustment
	add	bx, ax			; bx <- end position

;;;quit:
	.leave
	ret
LineComputeLineEndPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineComputeStartPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the position of the starting offset.

CALLED BY:	InvertPosToPos, InvertPosToEnd
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line/field data
		ss:bp	= LICL_vars
RETURN:		bx	= Pixel offset of offset from left edge of line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineComputeStartPos	proc	near
	uses	ax, dx
	.enter
	pushdw	ss:[bp].LICL_range.VTR_start
	movdw	dxax, ss:[bp].LICL_lineStart
	mov	bx, 0x7fff		; Calculate until offset (dx.ax)
	call	CommonLineTextPosition	; Nukes dx.ax

	CommonLineGetAdjustment		; ax <- adjustment
	add	bx, ax			; bx <- final position
	.leave
	ret
LineComputeStartPos	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineComputeEndPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the position of the ending offset.

CALLED BY:	InvertPosToPos, InvertStartToPos
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line/field data
		ss:bp	= LICL_vars
RETURN:		bx	= Pixel offset of offset from left edge of line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineComputeEndPos	proc	near
	uses	ax, dx
	.enter
	pushdw	ss:[bp].LICL_range.VTR_end
	movdw	dxax, ss:[bp].LICL_lineStart
	mov	bx, 0x7fff		; Calculate until offset (dx.ax)
	call	CommonLineTextPosition	; Nukes dx.ax

	CommonLineGetAdjustment		; ax <- adjustment
	add	bx, ax			; bx <- final position
	.leave
	ret
LineComputeEndPos	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineInvertArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert an area on a line.

CALLED BY:	InvertPosToPos, InvertStartToPos, InvertPosToEnd, 
		InvertStartToEnd
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Size of line/field data
		On stack:
			(Pushed 1st) Region we're inverting in
			(Pushed 2nd) Left edge of area to invert
			(Pushed 3rd) Right edge of area to invert
			(Pushed 4th) The line we're inverting on

			If the right edge is -1 then the right edge is
			computed by getting the right edge of the region.

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


LineInvertArea	proc	near	\
				lineRef:dword,
				rightEdge:word,
				leftEdge:word,
				region:word
	class	VisTextClass
	uses	ax, bx, cx, dx, di, bp
topEdge		local	WBFixed
bottomEdge	local	WBFixed
if SIMPLE_RTL_SUPPORT
flip		local	word
endif
	.enter
	;
	; Get the top and bottom of the line.
	;
	push	bx, di				; Save parameters
	movdw	bxdi, lineRef			; bx.di <- current line
	call	TL_LineGetTop			; dx.bl <- line top

	movwbf	topEdge, dxbl			; topEdge <- line top
	movwbf	bottomEdge, dxbl		; bottomEdge <- line top
	pop	bx, di				; Restore parameters

	push	bx				; Save break height
	CommonLineGetHeight			; dx.bl <- line height
	addwbf	bottomEdge, dxbl		; bottomEdge <- line height

;;;
;;; Changed, 12/14/92 -jw
;;;
;;; Now it always computes the regions right edge and, if it is less than the
;;; right edge supplied, the regions right edge is used.
;;;
;;;	;
;;;	; Check for needing to compute the right edge.
;;;	;
;;;	cmp	rightEdge, -1
;;;	jne	gotRight
	
	;
	; Load up stuff...
	;
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	mov	ax, ds:[di].VTI_leftOffset	; ax <- left-offset
	add	leftEdge, ax			; Update the left/right edges
	add	rightEdge, ax

	;
	; We need to compute the right edge of the area to invert.
	;
	ceilwbf	topEdge, dx			; dx <- Y position
	ceilwbf	bottomEdge, bx			; bx <- height
	sub	bx, dx
	mov	cx, region			; cx <- region
	call	TR_RegionLeftRight		; ax <- left
						; bx <- right
if SIMPLE_RTL_SUPPORT
	; Compute the flip value (which is right + left position)
	mov	flip, ax
	add	flip, bx
endif

	cmp	bx, rightEdge			; Check for region-right less
	jge	gotRight			; Branch if right is OK
	mov	rightEdge, bx			; Save new right edge

gotRight::
	
	mov	di, ds:[di].VTI_gstate		; di <- gstate to use

	mov	ax, MM_INVERT			; Set gstate to invert
	call	GrSetMixMode

	mov	ax, leftEdge			; ax...dx <- coordinates
	mov	cx, rightEdge
if SIMPLE_RTL_SUPPORT
	push	di
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	test	ds:[di].VTI_features, mask VTF_RIGHT_TO_LEFT
	pop	di
	je	notRTL
	neg	ax
	add	ax, flip
	neg	cx
	add	cx, flip
	xchg	ax, cx
notRTL:
endif
	ceilwbf	topEdge, bx
	ceilwbf	bottomEdge, dx
	
	;
	; Check to see if we're not inverting anything and branch to check
	; for a break of some sort.
	;
	cmp	ax, cx				; Compare edges
	jge	quit				; Branch if nothing to invert

	;
	; Convert the coordinates to document coordinates from object coords.
	;
	call	GrFillRect			; Invert the rectangle


quit:
	mov	ax, MM_COPY			; Restore to normal mode
	call	GrSetMixMode
	.leave
	ret	@ArgSize
LineInvertArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineGetLastFieldEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the end of the last field on the line.

CALLED BY:	LineComputeLineEndPos
PASS:		es:di	= Line
		cx	= Size of line/field data
RETURN:		bx	= End of last field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	offset = cx - sizeof(FieldInfo)
	fptr   = offset + di
	pos    = fptr.FI_position + fptr.FI_width
	
	return(pos)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineGetLastFieldEnd	proc	near
	uses	cx, di
	.enter
	;
	; Get the offset of the last field.
	; cx = Offset past last field.
	;
	sub	cx, size FieldInfo	; cx <- offset to last field.
	add	di, cx			; es:di <- ptr to last field
	
	mov	bx, es:[di].FI_position	; bx <- end of last field
	add	bx, es:[di].FI_width
	.leave
	ret
LineGetLastFieldEnd	endp

TextFixed	ends
