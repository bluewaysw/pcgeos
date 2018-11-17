COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trSmallDraw.asm

AUTHOR:		John Wedgwood, Dec 23, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/23/92	Initial revision

DESCRIPTION:
	Code for helping draw.

	$Id: trSmallDraw.asm,v 1.1 97/04/07 11:21:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextDrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallEnumRegionsInClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the regions in a clip rectangle.

CALLED BY:	TR_RegionEnumRegionsInClipRect
PASS:		*ds:si	= Instance
		ds:di	= Instance
		ss:bp	= TextRegionEnumParameters w/ these set:
				TREP_flags
				TREP_callback
				TREP_region
				TREP_globalClipRect
				TREP_object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version
	mg	03/31/00	Added check for null masks

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallEnumRegionsInClipRect	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx
	.enter
	;
	; Get the clip-rectangle. This isn't as easy as it sounds. We have
	; a gstate already, and it is possible (and even likely) that the
	; gstate has been transformed in some way. We can't discard that
	; transformation. In order to get the clip-rectangle bounds as
	; relative to the object, we do the following:
	;     - Transform gstate for region 0 (only region) if it hasn't
	;	been done already
	;     - Get the clip-rectangle relative to the object
	;     - Adjust the clip-rectangle by adjusting it by the bounds
	;	of the object.
	;
	; This gets us a clip-rectangle which is relative to the origin
	; for this object, rather than the object itself.
	;
	
	;
	; Transform gstate
	;
		CheckHack	<mask DF_PRINT eq mask TCBF_PRINT>
	mov	dl, ss:[bp].TREP_flags		; dl <- flags for transform
	clr	cx
	call	TR_RegionTransformGState	; Set up for region 0 (only one)

	;
	; Get clip-rectangle
	;
	push	ds, si, di			; Save instance
	mov	di, ds:[di].VTI_gstate		; di <- gstate
	
	segmov	ds, ss, si			; ds:si <- ptr to rect
	lea	si, ss:[bp].TREP_globalClipRect
	call	GrGetMaskBoundsDWord		; Get the mask bounds

	pop	ds, si, di			; Restore instance
	
	jc	nullPath			; Null path: all regions fail
	
	;
	; Compute the top/left of the object.
	;
	clr	ah				; ax <- left margin
	mov	al, ds:[di].VTI_lrMargin
	add	ax, ds:[di].VI_bounds.R_left	; ax <- left edge of object

	clr	bh				; bx <- top margin
	mov	bl, ds:[di].VTI_tbMargin
	add	bx, ds:[di].VI_bounds.R_top	; bx <- top edge of object

	;
	; Adjust the clip-rectangle, left and right
	;
	add	ss:[bp].TREP_globalClipRect.RD_left.low, ax
	adc	ss:[bp].TREP_globalClipRect.RD_left.high, 0

	add	ss:[bp].TREP_globalClipRect.RD_right.low, ax
	adc	ss:[bp].TREP_globalClipRect.RD_right.high, 0

	;
	; Adjust the clip-rectangle, top and bottom
	;
	add	ss:[bp].TREP_globalClipRect.RD_top.low, bx
	adc	ss:[bp].TREP_globalClipRect.RD_top.high, 0

	add	ss:[bp].TREP_globalClipRect.RD_bottom.low, bx
	adc	ss:[bp].TREP_globalClipRect.RD_bottom.high, 0

	;
	; Set some values that don't exist for small objects...
	;
	mov	ss:[bp].TREP_displayMode, VLTDM_PAGE
	clr	ss:[bp].TREP_regionSpacing
	clrdw	ss:[bp].TREP_draftRegionSize.XYS_width
	clrdw	ss:[bp].TREP_draftRegionSize.XYS_height

	;
	; All lines and characters are contained in a single region.
	;
	clrdw	ss:[bp].TREP_regionFirstLine
	movdw	ss:[bp].TREP_regionLineCount, -1
	clrdw	ss:[bp].TREP_regionFirstChar
	movdw	ss:[bp].TREP_regionCharCount, -1

	;
	; Set the clipRect top/bottom to be relative to the object.
	;
	movdw	dxcx, ss:[bp].TREP_globalClipRect.RD_top
	sub	cx, bx
	sbb	dx, 0
	movdw	ss:[bp].TREP_clipRect.RD_top, dxcx

	movdw	dxcx, ss:[bp].TREP_globalClipRect.RD_bottom
	sub	cx, bx
	sbb	dx, 0
	movdw	ss:[bp].TREP_clipRect.RD_bottom, dxcx


	;
	; Set the clipRect left/right to be relative to the object.
	;
	movdw	dxcx, ss:[bp].TREP_globalClipRect.RD_left
	sub	cx, ax
	sbb	dx, 0
	movdw	ss:[bp].TREP_clipRect.RD_left, dxcx

	movdw	dxcx, ss:[bp].TREP_globalClipRect.RD_right
	sub	cx, ax
	sbb	dx, 0
	movdw	ss:[bp].TREP_clipRect.RD_right, dxcx


	;
	; Compute the width and height of a small region.
	;
	; ax	= Left edge of region
	; bx	= Top edge of region
	;
	neg	ax				; ax <- width of region
	add	ax, ds:[di].VI_bounds.R_right
	sub	al, ds:[di].VTI_lrMargin
	sbb	ah, 0

	neg	bx				; bx <- height of region
	add	bx, ds:[di].VI_bounds.R_bottom
	sub	bl, ds:[di].VTI_tbMargin
	sbb	bh, 0


	;
	; ax	= Width of region,  which is same as right edge
	; bx	= Height of region, which is same as bottom edge
	;
	call	CommonCheckRegionAndCallback
nullPath:
	.leave
	ret
SmallEnumRegionsInClipRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonCheckRegionAndCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a region falls in the clip-rect.

CALLED BY:	SmallEnumRegionsInClipRect, LargeEnumRegionsInClipRect
PASS:		ss:bp	= TextRegionEnumParameters w/ these set:
				TREP_flags
				TREP_callback
				TREP_region
				TREP_clipRect
				TREP_object
		ax	= Width of the region
		bx	= Height of the region
RETURN:		TREP_regionHeight/Width set to passed values
		carry set to abort
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonCheckRegionAndCallback	proc	near
	uses	ds, si
	.enter
	;
	; Save width and height
	;
	mov	ss:[bp].TREP_regionWidth, ax
	mov	ss:[bp].TREP_regionHeight, bx
	
	;
	; We need to allow for the region spacing so that if the bottom of
	; the region is obscured, but if the area between regions is displayed,
	; we make a callback for this region so that the gap can be drawn.
	;
	add	bx, ss:[bp].TREP_regionSpacing

	;
	; The clip-rectangle is *not* relative to the object. This means that 
	; if the right or bottom edges of the clip-rect are negative, the 
	; region can't fall in the clip-rect.
	;
	tst	ss:[bp].TREP_clipRect.RD_right.high
	js	quitContinue
	tst	ss:[bp].TREP_clipRect.RD_bottom.high
	js	quitContinue
	
	;
	; Check to see if the region falls in the bounds of the clip-rect
	;
	
	;
	; If right edge of region is less than left of clip-rect, we can quit
	;
	tst	ss:[bp].TREP_clipRect.RD_left.high
	js	checkBottom

	cmp	ax, ss:[bp].TREP_clipRect.RD_left.low
	jbe	quitContinue

checkBottom:
	;
	; If bottom edge of region is less than top of clip-rect, we can quit
	;
	tst	ss:[bp].TREP_clipRect.RD_top.high
	js	doCallback
	
	cmp	bx, ss:[bp].TREP_clipRect.RD_top.low
	jbe	quitContinue

doCallback:
	;
	; It appears that the region does overlap the clip-rect, call
	; the callback.
	;

;if ERROR_CHECK
	;
	;  If not vfptr check if the segment passed is same as current
	;  code segment.  Since it is allowed to pass a fptr to the 
	;  callback if you are calling from the same segment.
	;
;FXIP<	push	ax, bx							>
;FXIP<	mov	ax, ss:[bp].TREP_callback.segment			>
;FXIP<	cmp	ah, 0xf0						>
;FXIP<	jae	isVirtual						>
;FXIP<	mov	bx, cs							>
;FXIP<	cmp	ax, bx							>
;FXIP<	ERROR_NE  TEXT_FAR_POINTER_TO_MOVABLE_XIP_RESORCE		>
;FXIP<isVirtual:							>
;FXIP<	pop	ax, bx							>
;endif

	movdw	dssi, ss:[bp].TREP_object	; Reset instance ptr
	call	ss:[bp].TREP_callback		; Call the callback...
						; carry set if wants to abort

quit:
	;;; Carry set if callback wants to stop now
	.leave
	ret

quitContinue:
	clc					; Signal: continue
	jmp	quit
CommonCheckRegionAndCallback	endp

TextDrawCode	ends
