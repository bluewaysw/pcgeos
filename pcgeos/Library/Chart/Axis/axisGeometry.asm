COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisGeometry.asm

AUTHOR:		John Wedgwood, Oct 18, 1991

ROUTINES:
	Name			Description
	----			-----------
	AxisGeometryPart2	Perform "part 2" of the geometry

	AxisGetOutsideTop	Get the amount of an axis that is above the
				plottable area.

	AxisGetOutsideBottom	Get the amount of an axis that is below the
				plottable area.

	AxisGetOutsideLeft	Get the amount of an axis that is left of
				the plottable area.

	AxisGetOutsideRight	Get the amount of an axis that is right of
				the plottable area.

	AxisSetRelatedAndOther	Set the related and other fields of an
				axis.

	AxisGetPlottableHeight	Get the height of the plottable area.

	AxisGetPlottableWidth	Get the width of the plottable area.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/18/91	Initial revision

DESCRIPTION:
	Geometry methods for the axis class.

	$Id: axisGeometry.asm,v 1.1 97/04/04 17:45:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGeometryPart2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Perform "part 2" of the geometry

PASS:		*ds:si	= CategoryAxisClass object
		ds:di	= CategoryAxisClass instance data
		es	= Segment of CategoryAxisClass.
		
RETURN:		cx, dx	= axis size

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	for VERTICAL:
		determine vertical plot bounds from related axis
		set top/bottom/left/right plot bounds
		adjust axis size, if necessary

	for HORIZONTAL:
		determine horizontal plot bounds from related
		set above/below distances		
		adjust axis size, if necessary

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisGeometryPart2	method	dynamic	AxisClass, 
					MSG_AXIS_GEOMETRY_PART_2
	uses	ax,bp
	.enter

	; Make sure bounds, etc. are valid

EC <	call	ECCheckAxisDSSI				>


	test	ds:[di].AI_attr, mask AA_VERTICAL
	jnz	vertical

	; HORIZONTAL

	; Get the position of the intersect relative to the axis' plot
	; bounds. 

	call	AxisGetIntersectionRelPosition	 
	mov	bx, ax			; intersect posn

	; Determine the amount that the related axis falls outside to
	; the left.  Subtract off the intersection RelPosition.
	; If result is less than current left edge of plot bounds, do
	; nothing.  Otherwise, adjust the plot bounds inward by the
	; new amount.

	mov	ax, MSG_AXIS_GET_OUTSIDE_LEFT
	call	callRelatedAxis

	sub	ax, bx
	cmp	ax, ds:[di].AI_plotBounds.R_left
	jle	afterLeft

	; If left bound changes, check right bound, and update
	; intersect position

	mov	ds:[di].AI_plotBounds.R_left, ax
	call	AxisGetIntersectionRelPosition	 
	mov	bx, ax			; intersect posn

afterLeft:

	; Get outside right for related.  If related doesn't extend
	; beyond this axis, then everything's OK, otherwise, subtract
	; off the difference

	mov	ax, MSG_AXIS_GET_OUTSIDE_RIGHT
	call	callRelatedAxis

	add	ax, bx
	sub	ax, ds:[di].AI_plotBounds.R_right
	js	gotRight
	sub	ds:[di].AI_plotBounds.R_right, ax

gotRight:

	mov	ax, ds:[di].AI_plotBounds.R_left
	sub	ax, ds:[di].AI_plotBounds.R_right
	jl	done
	add	ax, AXIS_MIN_PLOT_DISTANCE
	add	ds:[di].COI_size.P_x, ax
	add	ds:[di].AI_plotBounds.R_right, ax
	jmp	done

	;---------------------------------------------------
	; VERTICAL AXIS
	;

vertical:

	; Get top/bottom positions from related

	call	AxisGetIntersectionRelPosition
	mov	bx, ax			; intersect RelPosition
	mov	cx, ax			; make 2 copies

	;
	; Get other axis' outside top.  Add to intersect RelPosition, 
	; and then subtract plot distance.  If result is negative,
	; then top is OK, otherwise adjust top
	; If positive, result is OK, otherwise adjust top plot bounds.

	mov	ax, MSG_AXIS_GET_OUTSIDE_TOP
	call	callRelatedAxis

	add	bx, ax
	call	AxisGetPlotDistance
	sub	bx, ax
	js	gotTop	
	add	ds:[di].AI_plotBounds.R_top, bx

	; recalc intersection position

	call	AxisGetIntersectionRelPosition	 
	mov	cx, ax			; intersect RelPosition

	; Make sure this axis' outside bottom is greater than
	; (OtherAxis.outsideBottom - intersect RelPosition)
gotTop:
	mov	ax, MSG_AXIS_GET_OUTSIDE_BOTTOM
	call	callRelatedAxis
	sub	ax, cx			; other outside - relPos

	mov	bx, ds:[di].COI_size.P_y
	sub	bx, ds:[di].AI_plotBounds.R_bottom	

	sub	ax, bx
	js	gotBottom
	sub	ds:[di].AI_plotBounds.R_bottom, ax


gotBottom:
	mov	ax, ds:[di].AI_plotBounds.R_top
	sub	ax, ds:[di].AI_plotBounds.R_bottom
	jl	done
	add	ax, AXIS_MIN_PLOT_DISTANCE
	add	ds:[di].COI_size.P_y, ax
	add	ds:[di].AI_plotBounds.R_bottom, ax

done:	

EC <	call	ECCheckAxisDSSI			>

	mov	ax, MSG_TITLE_NOTIFY_AXIS_SIZE
	call	AxisCallTitle

	.leave
	ret

callRelatedAxis:
	push	si
	mov	si, ds:[di].AI_related
	call	ObjCallInstanceNoLock
	pop	si
	retn

AxisGeometryPart2	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSetRelatedAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the related and other fields of an axis.

CALLED BY:	via MSG_AXIS_SET_RELATED_AND_OTHER
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= Related axis
		dx	= Other axis
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisSetRelatedAxis	method dynamic	AxisClass,
			MSG_AXIS_SET_RELATED_AXIS
	mov	ds:[di].AI_related, cx
	ret
AxisSetRelatedAxis	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetOutsideTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of an axis that is above the plottable area.

CALLED BY:	via MSG_AXIS_GET_OUTSIDE_TOP
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Amount of space that is outside on top
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Assumes that the geometry is valid.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetOutsideTop	method dynamic	AxisClass,
			MSG_AXIS_GET_OUTSIDE_TOP
	mov	ax, ds:[di].AI_plotBounds.R_top
	ret
AxisGetOutsideTop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetOutsideBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of an axis that is below the plottable area.

CALLED BY:	via MSG_AXIS_GET_OUTSIDE_BOTTOM
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Amount of space that is outside on the bottom

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Assumes that the geometry is valid.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisGetOutsideBottom	method dynamic	AxisClass,
			MSG_AXIS_GET_OUTSIDE_BOTTOM
	.enter
	mov	ax, ds:[di].COI_size.P_y
	sub	ax, ds:[di].AI_plotBounds.R_bottom
	.leave
	ret
AxisGetOutsideBottom	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetOutsideLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of an axis that is left of the plottable area.

CALLED BY:	via MSG_AXIS_GET_OUTSIDE_LEFT
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Amount of space that is outside on the left
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes that the geometry is valid.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetOutsideLeft	method dynamic	AxisClass,
			MSG_AXIS_GET_OUTSIDE_LEFT
	mov	ax, ds:[di].AI_plotBounds.R_left
	ret
AxisGetOutsideLeft	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetOutsideRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of an axis that is right of the plottable area.

CALLED BY:	via MSG_AXIS_GET_OUTSIDE_RIGHT
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		cx	= Amount of space that is outside on the right
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes that the geometry is valid.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetOutsideRight	method dynamic	AxisClass,
			MSG_AXIS_GET_OUTSIDE_RIGHT
	.enter
	mov	ax, ds:[di].COI_size.P_x
	sub	ax, ds:[di].AI_plotBounds.R_right
	.leave
	ret
AxisGetOutsideRight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetPlottableHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of the plottable area.

CALLED BY:	via MSG_AXIS_GET_PLOTTABLE_HEIGHT
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Height of plottable area
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetPlottableHeight	method dynamic	AxisClass,
			MSG_AXIS_GET_PLOTTABLE_HEIGHT
	.enter
	mov	ax, ds:[di].AI_plotBounds.R_bottom
	sub	ax, ds:[di].AI_plotBounds.R_top
	.leave
	ret
AxisGetPlottableHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetPlottableWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of the plottable area.

CALLED BY:	via MSG_AXIS_GET_PLOTTABLE_WIDTH
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Width of plottable area
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetPlottableWidth	method dynamic	AxisClass,
			MSG_AXIS_GET_PLOTTABLE_WIDTH
	mov	ax, ds:[di].AI_plotBounds.R_right
	sub	ax, ds:[di].AI_plotBounds.R_left
	ret
AxisGetPlottableWidth	endm


AxisCode	ends
