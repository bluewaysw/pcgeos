COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS	
MODULE:		Chart Library
FILE:		axisSpider.asm

AUTHOR:		Vijay Menon, Aug  9, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/ 9/93   	Initial revision


DESCRIPTION:
	
		

	$Id: axisSpider.asm,v 1.1 97/04/04 17:45:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpiderAxisGeometryPart2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	No additional geometry for Spider axis.

CALLED BY:	MSG_AXIS_GEOMETRY_PART_2
PASS:		*ds:si	= SpiderAxisClass object
		ds:di	= SpiderAxisClass instance data
		ds:bx	= SpiderAxisClass object (same as *ds:si)
		es 	= segment of SpiderAxisClass
		ax	= message #
RETURN:		Nothing 
DESTROYED:	Nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpiderAxisGeometryPart2	method dynamic SpiderAxisClass, 
					MSG_AXIS_GEOMETRY_PART_2
	.enter
	call	ValueAxisComputeTickUnits
	.leave
	ret
SpiderAxisGeometryPart2	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpiderAxisGetValuePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get position of data

CALLED BY:	MSG_AXIS_GET_VALUE_POSITION
PASS:		*ds:si	= SpiderAxisClass object
		ds:di	= SpiderAxisClass instance data
		ds:bx	= SpiderAxisClass object (same as *ds:si)
		es 	= segment of SpiderAxisClass
		ax	= message #
		cx	= series #
		dx	= category #

RETURN:		if value exists:
			ax 	= position Y of number
			cx	= position X
			carry clear
		else
			carry set -- that position is EMPTY
		
DESTROYED:	Nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpiderAxisGetValuePosition	method dynamic SpiderAxisClass, 
					MSG_AXIS_GET_VALUE_POSITION
	uses	dx, bp
	.enter
	; Get the y-position (Position if category is 0).
	push	di
	mov	di, offset SpiderAxisClass
	call	ObjCallSuperNoLock
	pop	di

	jc 	done					; No value found.

	; Adjust the position for non-zero categories.

	mov	cx, ax
	call	AxisPositionToSpider
	mov	ax, dx	
	clc
done:
	.leave
	ret
SpiderAxisGetValuePosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisPositionToSpider
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a y-position in chart coordinates to
		an x and y position 

CALLED BY:	SpiderAxisGetValuePosition, etc.
PASS:		cx = y-position
		dx = category

RETURN:		cx = x-position
		dx = y-position
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisPositionToSpider	proc	near
	uses	ax,bx,si
	class	AxisClass
	.enter
	; Optimization for zero-category: Point does not need to be
	; rotated.  Move y-coord to dx, and set cx to the center
	; x-coord.

	tst 	dx					; Rotate if category
	jnz	convert					; is not 0.
	
	mov	dx, cx
	clr	cx
	jmp	shiftX

convert:
	; Get y-coord in terms of the axis (distance from the center).
	neg	cx
	add	cx, ds:[di].AI_plotBounds.R_bottom
	add	cx, ds:[di].COI_position.P_y
	
	call	AxisSpiderToXY

	; Convert back to chart coordinates.
	neg	dx
	add	dx, ds:[di].AI_plotBounds.R_bottom
	add	dx, ds:[di].COI_position.P_y
shiftX:
	add	cx, ds:[di].AI_plotBounds.R_left
	add	cx, ds:[di].COI_position.P_x 

	.leave
	ret
AxisPositionToSpider	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSpiderToXY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute a position given a radius and category.

CALLED BY:	AxisPositionToSpider
PASS:		cx 	= radius
		dx 	= current category
RETURN:		cx 	= (radius) * sin (360*category/total)
		dx	= (radius) * cos (360*category/total)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/25/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisSpiderToXY	proc	near
	.enter
	push	cx				; push Radius

	push	si
	mov	si, offset TemplateChartGroup
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	ObjCallInstanceNoLock
	pop	si

	; Get angle of category axis.
	mov	bx, cx				; bx = total categories
	clr	cx				; dx.cx = current category
	clr	ax				; bx.ax = total categories
	call	GrUDivWWFixed			
	mov	bx, 360
	call	GrMulWWFixed			; dx.cx = angle in deg
	mov	ax, cx				; dx.ax = angle in deg

	; Compute radius * sin (angle) (X-coord.)
	pop	bx				; bx = radius
	push	dx, ax				; push	angle	
	call	GrQuickSine			; dx.ax = sine
	mov	cx, ax				; dx.cx = sine
	clr	ax				; bx.ax = radius
	call	GrMulWWFixed			; dx.cx = X-coord
	mov	cx, dx				; cx = X-coord
	pop	dx, ax				; dx.ax = angle
	push	cx				; push	X-coord

	; Compute radius * cos (angle) (Y-coord.)
	call	GrQuickCosine			; dx.ax = cosine
	mov	cx, ax				; dx.cx = cosine
	clr	ax				; bx.ax = radius
	call	GrMulWWFixed			; dx.cx = Y-coord
	pop	cx
	.leave
	ret
AxisSpiderToXY	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpiderAxisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Geometry calculations.

CALLED BY:	MSG_CHART_OBJECT_RECALC_SIZE
PASS:		*ds:si	= SpiderAxisClass object
		ds:di	= SpiderAxisClass instance data
		ds:bx	= SpiderAxisClass object (same as *ds:si)
		es 	= segment of SpiderAxisClass
		ax	= message #
		cx, dx  = suggested size

RETURN:		cx, dx  = Axis size

DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpiderAxisRecalcSize	method dynamic SpiderAxisClass, 
					MSG_CHART_OBJECT_RECALC_SIZE
	uses	ax
	.enter
	push	cx, dx
	call	ValueAxisComputeMaxLabelSize
	
	
	mov	ax, ds:[di].AI_maxLabelSize.P_y
	add	ax, AXIS_MIN_PLOT_DISTANCE
	Max	dx, ax

	mov	ax, ds:[di].AI_maxLabelSize.P_x
	add	ax, AXIS_MIN_PLOT_DISTANCE
	Max	cx, ax

	shr 	cx
	shr	dx

; Adjusts size if category titles are present.
; Spider axis leaves room on the left and right for the longest piece
; of text.  Also leaves room at the top and bottom for the max text height.
	push	cx, dx, si, bp
	clr	cx, dx, bp
	mov	si, offset TemplatePlotArea
	mov 	ax, MSG_CHART_OBJECT_GET_MAX_TEXT_SIZE
	call	ObjCallInstanceNoLock
	movP	axbx, cxdx
	pop	cx, dx, si, bp

	tst	bx
	jz	noText
	add	ax, 5					;Offset from end
	add	bx, 5					;of axis.
	sub	cx, ax					;Subtract text width
	sub	dx, bx					;Subtract text height

noText:
	; Radius is the minimum of the space available both
	; horizontally and vertically.
	Min	dx, cx					;dx = Radius

	cmp	dx, 0					;If radius < 1
	jg	positive				; set radius = 1
	mov	dx, 1

positive:
	; plotBounds.R_left = plotBounds.R_right = center (cx/2)
	; plotBounds.R_bottom = center (dx/2)
	; plotBounds.R_top = Max(center - radius,maxLabelHeight/2)

	mov	bx, dx
	mov	ax, ds:[di].AI_maxLabelSize.P_y
	shr	ax, 1
	pop	cx, dx
	push	cx, dx
	shr	cx, 1
	mov	ds:[di].AI_plotBounds.R_left, cx
	mov	ds:[di].AI_plotBounds.R_right, cx
	shr	dx, 1
	mov	cx, dx
	sub	cx, bx
	Max	cx, ax
	mov	ax, cx
	inc	ax
	Max	dx, ax
	mov	ds:[di].AI_plotBounds.R_top, cx
	mov	ds:[di].AI_plotBounds.R_bottom, dx

	pop	cx, dx
	
	.leave
	mov	di, offset ValueAxisClass
	GOTO	ObjCallSuperNoLock
SpiderAxisRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisDrawSpiderLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an axis line for each category

CALLED BY:	AxisDrawLine
PASS:		ax	= left
		cx	= right
		bx 	= top 
		dx 	= bottom
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisDrawSpiderLines	proc	near
	uses	ax, bx, cx, dx
	.enter
	push	si, cx
	mov	si, offset TemplateChartGroup
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	ObjCallInstanceNoLock
	pop	si, ax
	xchg	bx, dx
	
	dec	cx
	jcxz	done

	; Loop from (category count - 1) to 1.  For each category
	; draw a line from the center point to the end of each axis.
	; Note that the zero category line is drawn and labeled separately.
axesLoop:
	; cx 		= current category
	; dx 		= radius (length of each axis line)
	; (ax, bx)	= center point

	push	cx, dx, di
	xchg	cx, dx
	call	AxisPositionToSpider
	mov	di, bp
	call	GrDrawLine
	
	pop	cx, dx, di
	loop	axesLoop
done:
	.leave
	ret
AxisDrawSpiderLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpiderTicksCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to draw ticks for spider charts

CALLED BY:	AxisDrawTicks via TickEnum
PASS:		ss:bp	= TickEnumVars
		ax	= Position of current tick.
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/25/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSpiderTicksCB	proc	near
	uses	ax,bx,cx,dx,di
locals	local	TickEnumVars
	class	SpiderAxisClass
	.enter	inherit

	push	si, ax
	mov	si, offset TemplateChartGroup
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	ObjCallInstanceNoLock
	pop	si, ax

	mov	dx, ax
	dec	cx

	; Loop from (category count - 1) to zero.  Draw a tick on each
	; axis.
	
axesLoop:
	; cx 	= current category
	; dx 	= distance from tick to center.

	push	cx, dx, di
	xchg	cx, dx
	push	dx

	; Rotate to corresponding axis to get center point of the tick.
	call	AxisPositionToSpider

	; Get the bounds for this tick.
	mov	ax, cx
	mov	bx, dx
	pop	dx
	mov	cx, AXIS_STANDARD_AXIS_WIDTH
	call	AxisGetSpiderTickBounds
	
	; Draw the tick.
	mov	di, locals.TEV_gstate
	call	GrDrawLine
	pop	cx, dx, di

	dec	cx
	jns	axesLoop
	
	.leave
	ret
DrawSpiderTicksCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetSpiderTickBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the endpoints of a tick

CALLED BY:	DrawSpiderTicksCB
PASS:		(ax,bx)	= Midpoint of tick
		cx 	= Length of tick
		dx	= Category
RETURN:		(ax,bx)	= Endpoint1
		(cx,dx)	= Endpoint2
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/25/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetSpiderTickBounds	proc	near
	class	SpiderAxisClass
	.enter

	; Is the category zero?
	tst	dx				
	jnz	nonZero

	; If the category is zero, each endpoint is directly to the
	; left or the right.  Add and subtract half the length to the
	; center point to get the endpoints.

	mov	dx, cx
	shr	cx, 1
	add	ax, cx
	mov	cx, ax
	sub	cx, dx
	mov	dx, bx
	jmp	done

nonZero:
	push	ax, bx
	shr	cx, 1

	; Tick should be perpendicular to axis.
	; ax' = ax + cx * cos theta
	; bx' = bx + cx * sin theta
	; cx' = ax - cx * cos theta
	; dx' = bx - cx * sin theta
	
	call	AxisSpiderToXY
	xchg	cx, dx
	; cx 	= x-offset
	; dx 	= y-offset

	; Compute endpoint1
	pop	ax, bx
	add	ax, cx
	add	bx, dx
	push	ax, bx

	; Compute endpoint2
	xchg	ax, cx
	xchg	bx, dx
	shl	ax, 1
	shl	bx, 1
	sub	cx, ax
	sub	dx, bx
	pop	ax, bx	

done:
	.leave
	ret
AxisGetSpiderTickBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpiderAxisDrawGridLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw weblike grid lines

CALLED BY:	MSG_AXIS_DRAW_GRID_LINES
PASS:		*ds:si	= SpiderAxisClass object
		ds:di	= SpiderAxisClass instance data
		ds:bx	= SpiderAxisClass object (same as *ds:si)
		es 	= segment of SpiderAxisClass
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHack <offset GF_MINOR_Y eq offset TEF_MINOR>
CheckHack <offset GF_MAJOR_Y eq offset TEF_MAJOR>


SpiderAxisDrawGridLines	method dynamic SpiderAxisClass, 
					MSG_AXIS_DRAW_GRID_LINES
	;uses	ax, cx, dx, bp
	mov	bx, bp
locals	local 	TickEnumVars
	.enter
	;
	; Should be a vertical axis - don't bother shifting flags.
	;

	mov	locals.TEV_flags, cl
	mov	locals.TEV_gstate, bx
	mov	locals.TEV_callback, offset DrawSpiderLines

	call	TickEnum

	.leave
	ret
SpiderAxisDrawGridLines	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpiderLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to draw a web line around the center.

CALLED BY:	SpiderAxisDrawGridLines via TickEnum
PASS:		ds:di - axis object
		cl - Grid Flags
		ax - position along axis at which to draw
		ss:bp - TickEnumVars

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/17/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSpiderLines	proc	near
	class	SpiderAxisClass
	uses	ax,bx,cx,dx,di
locals	local	TickEnumVars
	.enter	inherit

	push	ax, si, di
	mov	si, offset TemplateChartGroup
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	ObjCallInstanceNoLock
	pop	bx, si, di

	; Move current point to the beginning of the web line on the main
	; (vertical) axis.  
	push	di
	mov 	ax, ds:[di].AI_plotBounds.R_left
	add	ax, ds:[di].COI_position.P_x
	mov	di, locals.TEV_gstate
	call 	GrMoveTo
	pop	di

	mov	dx, cx
	mov	cx, bx
	dec	dx

	; Loop through each category, computing the corresponding the
	; point for the category, and drawing a line to that point.
	; Loop from (category count - 1) to zero, returning to the
	; beginning.

axesLoop:
	; cx 	= Distance of webline from center.
	; dx 	= Current category.

	push	cx, dx, di
	call	AxisPositionToSpider
	mov	di, locals.TEV_gstate
	call	GrDrawLineTo
	pop	cx, dx, di
	dec	dx
	jns	axesLoop

	.leave
	ret
DrawSpiderLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpiderCategoryTitles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the category title for the appropriate axis.

CALLED BY:	AxisRealize
PASS:		nothing 
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/19/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSpiderCategoryTitles	proc	near
	uses	ax,bx,cx,dx
	class	SpiderAxisClass
	.enter
	
	; Check to see if category titles should be drawn.  If not
	; just return.

	call	UtilGetChartAttributes
	test	dx, mask CF_CATEGORY_TITLES
	jz	done

	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	UtilCallChartGroup
 
	push	cx
	dec	cx
	mov	dx, cx

	; Loop from (category count - 1) to zero.  Draw the
	; corresponding title for each category.

categoryLoop:
	; cx 	= Current category
	; dx	= # total categories - 1

	push	dx
	push	cx

	; Get a GrObj to place title in.
	sub	dx, cx
	mov	cx, SAT_TITLES
	call	ChartObjectMultipleGetGrObj
	pop	cx
	push	dx

	; Compute position of the title and draw it.
	call	ComputeSpiderTextPosition
	call	DrawSpiderTitle

	; Set the GrObj
	pop	dx
	push	cx
	mov	cx, SAT_TITLES
	call	ChartObjectMultipleSetGrObj

	pop	cx
	pop	dx
	dec	cx
	jns	categoryLoop

	; Remove Extra GrObjes from the array.
	pop	dx
	mov	cx, SAT_TITLES
	call	 ChartObjectRemoveExtraGrObjs	
done:
	.leave
	ret
DrawSpiderCategoryTitles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeSpiderTextPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the text position

CALLED BY:	DrawSpiderCategoryTitles
PASS:		cx	= Category Number
RETURN:		ax, bx  = position
		dl	= TextAnchorType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/19/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeSpiderTextPosition	proc	near
	uses	cx
	class	SpiderAxisClass
	.enter
	mov	dx, cx
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	UtilCallChartGroup

	; Compute angle from main vertical axis in degrees.
	mov	bx, cx
	clr	ax, cx
	call	GrSDivWWFixed
	mov	bx, 360
	call	GrMulWWFixed

	; Convert to polar angle with respect to the center.
	sub	dx, 90
	neg 	dx
	jns	normalized
	add	dx, 360

normalized:
	;
	; dx = angle
	;

	; Compute approximate location of text in the chart to
	; determine its orientation.

	mov	cl, TAT_LEFT			; Approximately 0 degrees
	cmp	dx, 23
	jb	gotAnchor
	mov	cl, TAT_BOTTOM_LEFT		; Approximately 45 degrees
	cmp	dx, 68
	jb	gotAnchor
	mov	cl, TAT_BOTTOM			; Approximately 90 degrees
	cmp	dx, 113
	jb	gotAnchor
	mov	cl, TAT_BOTTOM_RIGHT		; Approximately 135 degrees
	cmp	dx, 158
	jb	gotAnchor
	mov	cl, TAT_RIGHT			; Approximately 180 degrees
	cmp	dx, 203
	jb	gotAnchor
	mov	cl, TAT_TOP_RIGHT		; Approximately 225 degrees
	cmp	dx, 248
	jb	gotAnchor
	mov	cl, TAT_TOP			; Approximately 270 degrees
	cmp	dx, 293
	jb	gotAnchor
	mov	cl, TAT_TOP_LEFT		; Approximately 315 degrees
	cmp	dx, 338
	jb	gotAnchor
	mov	cl, TAT_LEFT			; Approximately 0 degrees

gotAnchor:
	push	cx

	mov	bx, ds:[di].AI_plotBounds.R_bottom
	sub	bx, ds:[di].AI_plotBounds.R_top
	add	bx, 5				; Offset from end of axis.
	clr	ax, cx
	call	GrPolarToCartesian		; dx, bx - coordinates
	
	pop	cx				; cl - TextAnchorType
	mov	ax, dx				; ax, bx - coords

	; Convert point to chart coordinates
	addP	axbx, ds:[di].COI_position
	add	ax, ds:[di].AI_plotBounds.R_right
	add	bx, ds:[di].AI_plotBounds.R_bottom
	mov	dx, cx
	.leave
	ret
ComputeSpiderTextPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpiderTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a title for a particular spider axis

CALLED BY:	
PASS:		ax, bx 	= position to anchor text.
		cx	= Category Number
		dl	= TextAnchorType
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/19/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSpiderTitle	proc	near
	uses	cx,bp
	.enter

	; Allocate a buffer to temporarily hold the text.
	sub	sp, CHART_TEXT_BUFFER_SIZE
	mov	bp, sp

	push	ax, dx
	mov	dx, ss
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_TITLE
	call	UtilCallChartGroup
	pop	ax, cx
	
	; Draw the text.
	call	AxisCreateOrUpdateText

	add	sp, CHART_TEXT_BUFFER_SIZE
	.leave
	ret
DrawSpiderTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisCreateOrUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create or update a grobj text object.	

CALLED BY:	DrawSpiderTitle
PASS:		*ds:si	= Axis object
		ss:bp	= Text buffer
		ax, bx	= Anchor position
		cl	= TextAnchorType
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisCreateOrUpdateText	proc	near
	uses	es, di
	.enter

	sub	sp, size CreateTextParams
	mov	di, sp

	push	di, bp
	mov	bp, di
	call	AxisSetGroupInfo
	pop	di, bp
	
	movP	ss:[di].CGOP_position, axbx
	mov	ss:[di].CGOP_size.P_x, 20
	mov	ss:[di].CGOP_size.P_y, 20

	mov	ss:[di].CGOP_flags, mask CGOF_CUSTOM_BOUNDS
	mov	ss:[di].CTP_anchor, cl
	mov	ss:[di].CGOP_locks, STANDARD_CHART_GROBJ_LOCKS

	mov	ss:[di].CTP_text.segment, ss
	mov	ss:[di].CTP_text.offset, bp

	mov	ss:[di].CTP_flags, mask CTF_CENTERED or \
					mask CTF_MAX_HEIGHT
	
	xchg	bp, di
	call	ChartObjectCreateOrUpdateText

	add	sp, size CreateTextParams
	.leave
	ret
AxisCreateOrUpdateText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpiderAxisRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reloc handler SpiderAxisClass.

CALLED BY:	
PASS:		*ds:si	= ChartObjectMultipleClass object
		ds:di	= ChartObjectMultipleClass instance data
		es	= Segment of ChartObjectMultipleClass.

		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE

		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper
		
RETURN:		CF 	= 0
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpiderAxisRelocate	method dynamic SpiderAxisClass, reloc 
	mov	cx, SAT_ARRAY
	call	ChartObjectRelocOrUnRelocArray

	mov	di, offset SpiderAxisClass
	call	ObjRelocOrUnRelocSuper
	ret
SpiderAxisRelocate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpiderAxisClearAllGrObjes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke all grobjes for this object.

CALLED BY:	MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
PASS:		*ds:si	= SpiderAxisClass object
		ds:di	= SpiderAxisClass instance data
		ds:bx	= SpiderAxisClass object (same as *ds:si)
		es 	= segment of SpiderAxisClass
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpiderAxisClearAllGrObjes	method dynamic SpiderAxisClass, 
					MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
	uses	ax,cx
	.enter

	mov	cx, SAT_ARRAY
	call	ChartObjectFreeGrObjArray

	.leave
	mov	di, offset SpiderAxisClass
	GOTO	ObjCallSuperNoLock
SpiderAxisClearAllGrObjes	endm

AxisCode	ends







