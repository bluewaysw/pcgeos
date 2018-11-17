COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trSmallInfo.asm

AUTHOR:		John Wedgwood, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	Misc information about regions in small objects.

	$Id: trSmallInfo.asm,v 1.1 97/04/07 11:21:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionLinesInClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range of lines in a region that fall inside a 
		given rectangle.

CALLED BY:	TR_LinesInClipRect via CallRegionHandlers
PASS:		*ds:si	= Instance
		cx	= Region number
		ss:bp	= TextRegionEnumParameters
		ss:bx	= VisTextRange to fill in
RETURN:		VisTextRange holds the range of lines
		carry set if no lines appear in the region
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionLinesInClipRect	proc	near	uses	ax, dx
	class	VisTextClass
	.enter
EC <	call	ECSmallCheckRegionNumber			>

	call	TextRegion_DerefVis_DI		; ds:di <- instance ptr

	;
	; Since the RectDWord is relative to the current object, this means
	; that the bounds of our object are really:
	;	top	= 0
	;	bottom	= Height
	;	left	= 0
	;	right	= Width
	;

	;
	; Compute object.right (width)
	;
	mov	ax, ds:[di].VI_bounds.R_right	; ax <- width w/ margins
	sub	ax, ds:[di].VI_bounds.R_left

	clr	dx				; dx <- margins
	mov	dl, ds:[di].VTI_lrMargin
	shl	dx
	
	sub	ax, dx				; ax <- width w/o margins
	push	ax

	;
	; Compute object.bottom (height)
	;
	mov	dx, ds:[di].VI_bounds.R_bottom	; dx <- height w/ margins
	sub	dx, ds:[di].VI_bounds.R_top

	clr	ax				; ax <- margins
	mov	al, ds:[di].VTI_tbMargin
	shl	ax
	
	sub	dx, ax				; bx <- height w/o margins
	pop	ax				; ax = width

	call	LinesInClipCommon

	.leave
	ret

SmallRegionLinesInClipRect	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LinesInClipCommon

DESCRIPTION:	Common code to determine which lines are in the given
		region.  This is only called if the object actually
		intersects the rectangle.

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ax - region width
	dx - region height
	cx - region number
	ss:bp - TextRegionEnumParameters
	ss:bx - VisTextRange to fill in

RETURN:
	VisTextRange holds the range of lines
	carry set if no lines in clip region

DESTROYED:
	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/19/92		Initial version

------------------------------------------------------------------------------@
LinesInClipCommon	proc	near
	clr	di				; di <- high word for compares

	;
	; Check for right edge of region < left edge of clip rectangle
	;
	jledw	diax, ss:[bp].TREP_clipRect.RD_left, noLines

	;
	; Check for bottom edge of region < top edge of clip rectangle
	;
	jledw	didx, ss:[bp].TREP_clipRect.RD_top, noLines

	;
	; Figure the line at the top of the range, accounting for a possible
	; break-character.
	;
	movdw	diax, ss:[bp].TREP_clipRect.RD_top
	call	ConvertToWordValue		; ax <- Y position
	
	call	GetLineFromYPos			; dx.ax <- starting line
	movdw	ss:[bx].VTR_start, dxax		; Save starting line
	
	;
	; Figure the line at the bottom of the range, accounting for a possible
	; break-character.
	;
	movdw	diax, ss:[bp].TREP_clipRect.RD_bottom
	call	ConvertToWordValue		; ax <- Y position

	call	GetLineFromYPos			; dx.ax <- ending line
	movdw	ss:[bx].VTR_end, dxax		; Save ending line

	clc					; Signal: has lines
	ret

noLines:
	stc					; Signal: no lines
	ret

LinesInClipCommon	endp

;
; Convert di.ax to some reasonable value in ax
;
ConvertToWordValue	proc	near
	tst	di				; Check for word-value
	jz	gotValue
	
	mov	ax, -1				; Assume negative
	js	gotValue
	
	mov	ax, 0x7fff			; Must be large positive
gotValue:
	ret
ConvertToWordValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLineFromYPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the line that intersects a given position.

CALLED BY:	SmallRegionLinesInClipRect
PASS:		ax	= Y position
		cx	= region
		*ds:si	= Instance ptr
RETURN:		dx.ax	= Line at that position
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLineFromYPos	proc	near	uses	bx, cx
	.enter
	;
	; For small objects the X position doesn't matter.
	;
	mov	dx, ax				; dx <- Y position
	clr	ax				; ax <- X position
	call	TL_LineFromPosition		; bx.di <- ending line
	movdw	dxax, bxdi			; dx.ax <- ending line

	.leave
	ret

GetLineFromYPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionNextSegmentTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next segment of a region.

CALLED BY:	TR_NextSegmentTop via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region number
		dx	= Y position within that region
RETURN:		dx	= Y position of the top of the next segment
			= Region bottom if there are no more segments
		carry set if there are no more segments
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionNextSegmentTop	proc	near	uses ax
	class	VisTextClass
	.enter
EC <	call	ECSmallCheckRegionNumber			>
	
	;
	; There are never any more segments in a small object we always
	; return the bottom of the region.
	;
	call	TextRegion_DerefVis_DI		; ds:di <- Instance ptr
	mov	dx, ds:[di].VI_bounds.R_bottom	; dx <- height
	sub	dx, ds:[di].VI_bounds.R_top

	clr	ah				; ax <- 2 * margins
	mov	al, ds:[di].VTI_tbMargin
	shl	ax, 1
	
	sub	dx, ax				; dx <- height w/o margins

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Added  3/29/93 -jw
; If the object is smaller than the text, we really want to blt all the text
; so that appropriate redrawing of lines that become visible will occur.
;
; Really it's not a problem to return something that is too large as the only
; calls that will land here are when the calculation code is attempting to
; either move text around (call from BltStuff) or when it is attempting to figure
; out what lines to redraw (call from ForceRedrawOfLinesInRegion).
;
; The only other call is from the calculation code (CheckRecalcFromNextSegment).
; In that case, the value returned is ignored, and only the fact that another
; segment does/does-not exist is checked.
;
; Since this is a small object, VTI_height is always valid.
;
	ceilwbf	ds:[di].VTI_height, ax		; ax <- text height

	cmp	dx, ax				; Check for text height larger
	jae	gotHeight			; Branch if not
	mov	dx, ax				; Else use text height
gotHeight:
	;
	; dx holds the larger of the object height and the text height.
	;
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	stc					; Signal: no more segments
	.leave
	ret
SmallRegionNextSegmentTop	endp

TextRegion	ends

TextFixed	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionGetRegionTopLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top/left edge of a region.

CALLED BY:	TR_GetRegionTopLeft via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region number
		ss:bp	= PointDWord to fill in
RETURN:		PointDWord contains the top-left corner of the region
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionGetRegionTopLeft	proc	far
	class	VisTextClass
	uses	ax, dx
	.enter
EC <	call	ECSmallCheckRegionNumber			>
	
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	clr	dx				; dx.ax <- left
	clr	ah
	mov	al, ds:[di].VTI_lrMargin
	add	ax, ds:[di].VI_bounds.R_left
	movdw	ss:[bp].PD_x, dxax

	clr	ah				; dx.ax <- top
	mov	al, ds:[di].VTI_tbMargin
	add	ax, ds:[di].VI_bounds.R_top
	movdw	ss:[bp].PD_y, dxax
	.leave
	ret
SmallRegionGetRegionTopLeft	endp

TextFixed	ends

TextRegion	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionGetLineCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of lines in a region.

CALLED BY:	TR_RegionGetLineCount via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		cx	= Number of lines
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionGetLineCount	proc	near
	uses	ax, dx
	.enter
EC <	call	ECSmallCheckRegionNumber			>

	call	TL_LineGetCount			; dx.ax <- count
	
	mov_tr	cx, ax				; cx <- count
	.leave
	ret
SmallRegionGetLineCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionGetCharCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of characters in a region.

CALLED BY:	TR_RegionGetCharCount via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		dx.ax	= Number of characters
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionGetCharCount	proc	near
	.enter
EC <	call	ECSmallCheckRegionNumber			>

	call	TS_GetTextSize			; dx.ax <- size
	.leave
	ret
SmallRegionGetCharCount	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionLeftRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the bounds of the region at a given y position.

CALLED BY:	TR_RegionLeftRight via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region number
		dx	= Y position within that region
		bx	= Integer height of the line at that position
RETURN:		ax	= Left edge of the region at that point.
		bx	= Right edge of the region at that point.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionLeftRight	proc	near
	class	VisTextClass
	.enter
EC <	call	ECSmallCheckRegionNumber			>

	call	TextRegion_DerefVis_DI		; ds:di <- instance ptr
	mov	bx, ds:[di].VI_bounds.R_right	; bx <- width of object
	sub	bx, ds:[di].VI_bounds.R_left
	tst	bx
	jz	done				; don't both with margin
	
	clr	ax				; ax <- 2 * margin
	mov	al, ds:[di].VTI_lrMargin
	shl	ax
	
	sub	bx, ax				; bx <- region width
done:
	clr	ax				; Left is always zero
	.leave
	ret
SmallRegionLeftRight	endp

SmallRegionLeftRightFar proc	far
	call	SmallRegionLeftRight
	ret
SmallRegionLeftRightFar endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionFromOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the region associated with a given offset.

CALLED BY:	TR_RegionFromOffset via CallRegionHandler
PASS:		*ds:si	= Instance
		dx.ax	= Offset
RETURN:		cx	= Region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionFromOffset	proc	near
	clr	cx				; Always zero
	ret
SmallRegionFromOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionFromOffsetGetStartLineAndOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about a region associated with a given offset.

CALLED BY:	TR_RegionFromOffsetGetStartLineAndOffset via CallRegionHandler
PASS:		*ds:si	= Instance
		dx.ax	= Offset
RETURN:		dx.ax	= Region start offset
		bx.di	= Region start line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionFromOffsetGetStartLineAndOffset	proc	near
	clrdw	dxax
	clrdw	bxdi
	ret
SmallRegionFromOffsetGetStartLineAndOffset	endp

TextRegion	ends

TextFixed	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionFromLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the region associated with a given line.

CALLED BY:	TR_RegionFromOffset via CallRegionHandler
PASS:		*ds:si	= Instance
		bx.di	= Line
RETURN:		cx	= Region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionFromLine	proc	near
	clr	cx				; Always zero
	ret
SmallRegionFromLine	endp

TextFixed	ends

TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionFromPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the region associated with a given point.

CALLED BY:	TR_RegionFromOffset via CallRegionHandler
PASS:		*ds:si	= Instance
		ss:bp	= PointDWFixed
RETURN:		cx	= Region
		ax	= Relative X position
		dx	= Relative Y position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionFromPoint	proc	near	uses	bx, di, bp
	class	VisTextClass
	.enter
	mov	bx, bp				; ss:bx <- passed PointDWFixed
	sub	sp, size PointDWord		; Allocate stack frame
	mov	bp, sp				; ss:bp <- PointDWord

	;
	; Get region top-left
	;
	clr	cx				; Always zero (unless out of
						; bounds)
	call	SmallRegionGetRegionTopLeft	; Fill in regTopLeft

	;
	; Compute relative X position
	;
	movdw	dxax, ss:[bx].PDF_x.DWF_int
	subdw	dxax, ss:[bp].PD_x
	tst	dx
	jns	10$
	mov	cx, CA_NULL_ELEMENT
10$:
	
	push	ax				; Save relative X pos

	;
	; Compute relative Y position
	;
	movdw	dxax, ss:[bx].PDF_y.DWF_int
	subdw	dxax, ss:[bp].PD_y
	tst	dx
	jns	20$
	mov	cx, CA_NULL_ELEMENT
20$:

	mov_tr	dx, ax				; dx <- relative Y pos
	pop	ax				; ax <- relative X pos

	call	TextRegion_DerefVis_DI
	mov	bx, ds:[di].VI_bounds.R_right
	sub	bx, ds:[di].VI_bounds.R_left	; bx = width
	cmp	ax, bx
	jbe	30$
	mov	cx, CA_NULL_ELEMENT
30$:
	mov	bx, ds:[di].VI_bounds.R_bottom
	sub	bx, ds:[di].VI_bounds.R_top	; bx = height
	cmp	dx, bx
	jbe	40$
	mov	cx, CA_NULL_ELEMENT
40$:

	;
	; Restore stack
	;
	add	sp, size PointDWord
	.leave
	ret
SmallRegionFromPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionGetTrueWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of the rectangle bounding a region.

CALLED BY:	TR_RegionGetTrueWidth
PASS:		*ds:si	= Instance ptr
		cx	= Region number
RETURN:		dx.al	= Width of bounding rectangle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionGetTrueWidth	proc	near
	uses	bx
	.enter
	call	SmallRegionLeftRight	; ax <- 0, bx <- width
	mov	dx, bx			; dx.al <- width
	.leave
	ret
SmallRegionGetTrueWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionGetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of region.

CALLED BY:	TR_RegionGetHeight
PASS:		*ds:si	= Instance ptr
		cx	= Region number
RETURN:		dx.al	= Height of region.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionGetHeight	proc	near
	class	VisTextClass
	uses	di
	.enter
EC <	call	ECSmallCheckRegionNumber			>

	call	TextRegion_DerefVis_DI		; ds:di <- instance ptr
	movwbf	dxal, ds:[di].VTI_height
	.leave
	ret
SmallRegionGetHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionGetTrueHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of the rectangle bounding a region.

CALLED BY:	TR_RegionGetTrueHeight
PASS:		*ds:si	= Instance ptr
		cx	= Region number
RETURN:		dx.al	= Height of bounding rectangle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	For a small object we never want to ripple. This means that the
	height of the area bounding the object is infinite.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionGetTrueHeight	proc	near
EC <	call	ECSmallCheckRegionNumber			>

	mov	dx, 0x7fff	; Largest positive integer
	clr	al
	ret
SmallRegionGetTrueHeight	endp

TextRegion	ends
