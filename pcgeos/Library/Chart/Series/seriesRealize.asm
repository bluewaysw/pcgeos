COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesRealize.asm

AUTHOR:		John Wedgwood, Oct 21, 1991

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/21/91	Initial revision

DESCRIPTION:
	Realizing code for series.

	$Id: seriesRealize.asm,v 1.1 97/04/04 17:47:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGetDataPointPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the X/Y position for a series for a line or area chart.

CALLED BY:

PASS:		cl - series #
		dx - category #
		ss:bp - SeriesDrawLocalVars 

RETURN:		IF VALUE AVAILABLE:
			carry clear
			ax, bx - position
		ELSE:
			carry set

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/10/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGetDataPointPosition	proc near	
	uses	si
locals	local	SeriesDrawLocalVars
	.enter	inherit 
	call	SeriesGetValuePosition
	jc	done
	
	mov	bx, ax

ifdef	SPIDER_CHART
	; Spider Chart have no category axis.  The spider (value) axis
	; returns both the x and y coordinates.

	cmp	locals.SDLV_type, CT_SPIDER
	jnz	category
	mov	ax, cx
	clc
	jmp	done

category:
endif	; SPIDER_CHART

	call	SeriesGetCategoryPosition
	clc
done:
	.leave
	ret
SeriesGetDataPointPosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGetCategoryPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the position of the current category from the
		category axis

CALLED BY:

PASS:		dx - category #
		ss:bp - SeriesDrawLocalVars 

RETURN:		ax - position 	CARRY CLEAR ALWAYS

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGetCategoryPosition	proc near	
		uses	si, dx
		
locals	local	SeriesDrawLocalVars
		.enter	inherit 
		mov	si, locals.SDLV_categoryAxis
		mov	ax, MSG_CATEGORY_AXIS_GET_CATEGORY_POSITION
		call	ObjCallInstanceNoLock
		call	FloatFloatToDword	 ; destroys DX
		clc
		.leave
		ret
SeriesGetCategoryPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGetValuePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get value and category positions, widths for this
		series/category

CALLED BY:

PASS:		cl - series number, or -1 for bottom
		dx - category number
		ss:bp - SeriesDrawLocalVars

RETURN:		IF VALUE AVAILABLE:
			CARRY CLEAR
			ax - value position
		ELSE	
			CARRY SET		

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	if series# = -1
		return intersect position
	else
		call axis and get value position

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/10/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGetValuePosition	proc near	
	uses	si
locals	local	SeriesDrawLocalVars
	.enter	inherit

	tst	cl
	js	intersect

	mov	ax, MSG_AXIS_GET_VALUE_POSITION
	mov	si, locals.SDLV_valueAxis
	call	ObjCallInstanceNoLock	; ax <- value position
done:
	.leave
	ret

intersect:
	mov	ax, locals.SDLV_intersect
	clc
	jmp	done

SeriesGetValuePosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesDrawEachCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate callback routine for each
		category. Only call if there's a value for this category


CALLED BY:	

PASS:		ss:bp   = SeriesDrawLocalVars
		ds - data segment of chart objects
		cl - series number

RETURN:		nothing 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Callback should be defined as:
		PASS:	cl	= series number
			dx	= Category number
			ss:bp 	= SeriesDrawLocalVars struct

		RETURN:	nothing 

		CAN DESTROY: ax,bx,cx,dx,di,es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/4/91		Initial Revision 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesDrawEachCategory	proc	near
	uses	dx
locals	local	SeriesDrawLocalVars
	.enter inherit

	clr	dx		; category number
	mov	locals.SDLV_categoryIncrement, 1
	call	CategoryEnumCommon
	.leave
	ret
SeriesDrawEachCategory	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesDrawEachCategoryRV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw each category, starting at the last and counting
		down to the first

CALLED BY:	SeriesDrawArea

PASS:		ss:bp - SeriesDrawLocalVars 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Callback should be defined as:
		PASS:	cl	= series number
			dx	= Category number
			ss:bp 	= SeriesDrawLocalVars struct

		RETURN:	nothing 

		CAN DESTROY: ax,bx,cx,dx,di,si,es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/11/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesDrawEachCategoryRV	proc near
	uses	dx
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	dx, locals.SDLV_categoryCount
	dec	dx
	mov	locals.SDLV_categoryIncrement, -1
	call	CategoryEnumCommon

	.leave
	ret
SeriesDrawEachCategoryRV	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CategoryEnumCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to enum categories, either forward or
		backward. 

CALLED BY:

PASS:		ss:bp - local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CategoryEnumCommon	proc near
	uses	ax,bx,cx,dx,di,si,es

locals	local	SeriesDrawLocalVars
	.enter	inherit 

startLoop:
	mov	locals.SDLV_categoryNum, dx
	push	cx
	call	locals.SDLV_callback
	pop	cx
	mov	dx, locals.SDLV_categoryNum

	add	dx, locals.SDLV_categoryIncrement
	js	done			; gone negative
	cmp	dx, locals.SDLV_categoryCount
	jl	startLoop
	
done:
	.leave
	ret
CategoryEnumCommon	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGetZeroPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the "zero" position for a bar or column chart

CALLED BY:	ColumnRealizeCB, BarRealizeCB

PASS:		ss:bp - SeriesDrawLocalVars 
		cl - series #
		dx - category #

RETURN:		ax - zero position CARRY CLEAR ALWAYS 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	If chart is stacked, then zero position is position of
	previous series.  Otherwise, it's the intersect position

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/27/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGetZeroPosition	proc near	
	uses	cx,si

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	; Assume single series flag not set

EC <	test	locals.SDLV_flags, mask CF_SINGLE_SERIES	>
EC <	ERROR_NZ ILLEGAL_FLAGS					>

	; If not stacked, then just use the intersect posn, else use
	; the position of the previous series.

	test	locals.SDLV_flags, mask CF_STACKED
	jz	intersect

startLoop:
	dec	cl
	js	intersect
	mov	ax, MSG_AXIS_GET_VALUE_POSITION
	mov	si, locals.SDLV_valueAxis
	call	ObjCallInstanceNoLock
	jc	startLoop
done:
	clc
	.leave
	ret

intersect:
	mov	ax, locals.SDLV_intersect
	jmp	done
SeriesGetZeroPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGetPrevValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the previous value

CALLED BY:	SeriesGetValueTextCommon

PASS:		cl - series #
		dx - category number
		bp - ChartFlags

RETURN:		previous value on FP stack

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGetPrevValue	proc near	

	uses	ax,cx,dx,si

	.enter


	; Keep decrementing either the series or category number
	; until:
	;	- we run into a negative, in which case, return
	;	zero.
	;
	; 	- we hit a value.

decrementLoop:
	test	bp, mask CF_SINGLE_SERIES
	jnz	decrementCategory
	dec	cl
	jmp	gotPrev

decrementCategory:
	dec	dx
gotPrev:

	; If either the category or series has gone negative on us,
	; then return the intersect value

	js	zero
	mov	ax, MSG_CHART_GROUP_GET_VALUE
	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock
	jc	decrementLoop
	jmp	done			; found a number!


zero:
	call	Float0
done:
	clc
	.leave
	ret
SeriesGetPrevValue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DualDrawSeriesOrCategoryTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a series or category title for one of the "dual"
		objects. 

CALLED BY:

PASS:		*ds:si - dual object
		ss:bp - local vars
		ax, bx - position at which to "anchor" the text
		cl - TextAnchorType

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DualDrawSeriesOrCategoryTitle	proc near
	uses	cx
	.enter

	; Move the "grobj" into the proper field

	push	cx
	mov	cx, CODT_TEXT
	call	ChartObjectDualGetGrObj
	pop	cx

	call	DrawSeriesOrCategoryTitle

	mov	cx, CODT_TEXT
	call	ChartObjectDualSetGrObj

	.leave
	ret
DualDrawSeriesOrCategoryTitle	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSeriesOrCategoryTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a series title.  if CF_SINGLE_SERIES, then
		draw a category title instead.

CALLED BY:	DualDrawSeriesOrCategoryTitle, LegendItemDrawText

PASS:		ax,bx - position at which to anchor text
		cl - TextAnchorType

		*ds:si - series object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSeriesOrCategoryTitle	proc near	
	uses	ax,bx,cx,dx

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	push	ax,cx		; coordinates

	test	locals.SDLV_flags, mask CF_SINGLE_SERIES
	jnz	categoryTitle
 
	mov	cl, locals.SDLV_seriesNum
	mov	ax, MSG_CHART_GROUP_GET_SERIES_TITLE
	jmp	callIt

categoryTitle:
	mov	cx, locals.SDLV_categoryNum
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_TITLE

callIt:
	push	bp, si
	mov	dx, ss
	lea	bp, locals.SDLV_text
	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock
	pop	bp, si

	pop	ax,cx		; coordinates

	call	SeriesCreateOrUpdateText

	.leave
	ret
DrawSeriesOrCategoryTitle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGetValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text for the current value into the text buffer.

CALLED BY:

PASS:		*ds:si - series object
		ss:[bp] - local vars


RETURN:		locals.SDLV_text filled in

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGetValueText	proc near
	uses	ax,bx,cx,dx,si

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	mov	cl, locals.SDLV_seriesNum
	mov	dx, locals.SDLV_categoryNum
	lea	di, locals.SDLV_text
	segmov	es, ss
	push	bp
	mov	bp, locals.SDLV_flags
	call	SeriesGetValueTextCommon
	pop	bp

EC <	ERROR_C ILLEGAL_VALUE	>

	.leave
	ret
SeriesGetValueText	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGetValueTextCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to get the value text w/o using the
		local vars structure

CALLED BY:	SeriesGetValueText, PieGetMaxTextBounds

PASS:		cl - series #
		dx - category #
		ss:di - text buffer
		bp - flags

RETURN:		carry SET if not available 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGetValueTextCommon	proc near
	uses	ax,bp
	.enter

	mov	ax, MSG_CHART_GROUP_GET_VALUE
	call	UtilCallChartGroup
	jc	done

	;
	; subtract previous value if stacked
	;

	test	bp, mask CF_STACKED
	jz	gotValue
	call	SeriesGetPrevValue	; always returns something
	call	FloatSub

gotValue:
	;
	; convert to text
	;

	mov	bp, di
	call	UtilFloatToAscii
	clc
done:
	.leave
	ret
SeriesGetValueTextCommon	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesCreateOrUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create or update  a grobj text object

CALLED BY:	any series object

PASS:		*ds:si - series object
		ss:bp - SeriesDrawLocalVars
		ax, bx - anchor position
		cl - TextAnchorType

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesCreateOrUpdateText	proc near
	uses	es, di

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	sub	sp, size CreateTextParams
	mov	di, sp

	call	SeriesSetCreateGrObjParams

	movP	ss:[di].CGOP_position, axbx
	mov	ss:[di].CGOP_size.P_x, 20	; bogus values
	mov	ss:[di].CGOP_size.P_y, 20


	ornf	ss:[di].CGOP_flags, mask CGOF_CUSTOM_BOUNDS
	mov	ss:[di].CTP_anchor, cl

	;
	; Set standard locks.  Also set the edit lock, since if the
	; user tries to edit the text, (s)he will lose changes once
	; the chart is recalculated.
	;

	mov	ss:[di].CGOP_locks, STANDARD_CHART_GROBJ_LOCKS or \
			mask GOL_EDIT 
	
	;
	; set pointer to text.  Set the MAX HEIGHT so that it's not
	; allowed to wrap.
	;

	mov	ss:[di].CTP_text.segment, ss
	lea	ax, locals.SDLV_text
	mov	ss:[di].CTP_text.offset, ax
	mov	ss:[di].CTP_flags, mask CTF_CENTERED or \
						mask CTF_MAX_HEIGHT


	;
	; Make the text last in the draw order, so it shows up on top.
	; Since other objects will be relying on the value stored in
	; locals.SDLV_drawOrder, however, we need to update that as well.
	;
	mov	ss:[di].CGOP_drawOrder, GOBAGOR_LAST or \
			mask GOBAGOF_DRAW_LIST_POSITION 

	inc	locals.SDLV_drawOrder
		
	xchg	di, bp
	call	ChartObjectCreateOrUpdateText
	xchg	di, bp

	add	sp, size CreateTextParams

	.leave
	ret
SeriesCreateOrUpdateText	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGetAreaAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the area attributes for this series object

CALLED BY:

PASS:		ss:bp - SeriesDrawLocalVars 

RETURN:		al - Color
		ah - SystemDrawMask

DESTROYED:	nothing 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGetAreaAttributes	proc	near
	uses	bx,cx,dx,di,si

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	mov	cl, locals.SDLV_seriesNum
	test	locals.SDLV_flags, mask CF_SINGLE_SERIES
	jz	afterSingleSeries
	mov	cx, locals.SDLV_categoryNum

afterSingleSeries:
	test	locals.SDLV_flags, mask CF_SINGLE_COLOR
	jz	gotSeriesNumber
	clr	cl

gotSeriesNumber:

	mov	al, cl
	clr	ah
if NO_COLOR_DOCUMENTS
	mov	bl, length seriesDrawMaskTable
else
	mov	bl, length seriesAreaColorTable
endif
	div	bl

	; Use the REMAINDER (ah) for the color, the 
	; QUOTIENT (al) for the mask, except in no-color systems, where the
	; remainder is the mask, and the color is always black.
	
	mov	bl, ah
	clr	bh
	push	ax		; quotient (al)

if NO_COLOR_DOCUMENTS
EC <	cmp	bx, size seriesDrawMaskTable		>
EC <	ERROR_AE	ILLEGAL_VALUE			>
	mov	ah, cs:[bx].seriesDrawMaskTable		; get current color

else
EC <	cmp	bx, size seriesAreaColorTable		>
EC <	ERROR_AE	ILLEGAL_VALUE			>
	mov	al, cs:[bx].seriesAreaColorTable	; get current color
endif

	pop	bx
	clr	bh

if NO_COLOR_DOCUMENTS
	mov	al, C_BLACK
else
EC <	cmp	bx, size seriesDrawMaskTable		>
EC <	ERROR_AE	ILLEGAL_VALUE			>
	mov	ah, cs:[bx].seriesDrawMaskTable
endif
	.leave
	ret
SeriesGetAreaAttributes	endp


if NO_COLOR_DOCUMENTS

seriesDrawMaskTable SystemDrawMask \
        SDM_50,
        SDM_DIAG_NE,
        SDM_100,
        SDM_DIAG_NW,
        SDM_SHADED_BAR,
        SDM_HORIZONTAL,
        SDM_VERTICAL,
        SDM_GRID,
        SDM_BRICK,
        SDM_SLANT_BRICK
else
seriesAreaColorTable	byte \
	C_LIGHT_GREEN,
	C_LIGHT_RED, 
	C_LIGHT_CYAN, 
	C_YELLOW, 
	C_LIGHT_BLUE, 
	C_GREEN,
	C_RED,
	C_CYAN,
	C_VIOLET,
	C_BLUE,
	C_BROWN,
	C_LIGHT_GRAY,
	C_BLACK

seriesDrawMaskTable SystemDrawMask \
	SDM_100,
	SDM_DIAG_NE,
	SDM_DIAG_NW,
	SDM_SHADED_BAR,
	SDM_HORIZONTAL,
	SDM_VERTICAL,
	SDM_GRID,
	SDM_BRICK,
	SDM_SLANT_BRICK
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesCreateGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstring, storing the gstate and vm handle
		in the local variable structure

CALLED BY:	series realize handlers

PASS:		ss:bp - SeriesDrawLocalVars 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesCreateGString	proc near
	uses	ax,bx
locals	local	SeriesDrawLocalVars
	.enter	inherit 
	mov	bx, bp
	call	ChartObjectCreateGString
	xchg	bx, bp
	mov	locals.SDLV_gstate, bx
	mov	locals.SDLV_gstringBlock, ax
	.leave
	ret
SeriesCreateGString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPointInDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current point in the data block

CALLED BY:	Line/Area realize handlers

PASS:		ss:[bp] - local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPointInDataBlock	proc near
	uses	ax,bx
	.enter
	call	SeriesGetDataPointPosition
	jc	done
	call	SetPointCommon
done:
	.leave
	ret
SetPointInDataBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPointCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to set the next point in the data block.

CALLED BY:	ScatterRealize, SetPointInDataBlock, AreaSetPrevPoint

PASS:		ax, bx - point to set
		ss:[bp] - local vars

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPointCommon	proc near
ifdef 	SPIDER_CHART
	uses	cx,dx, di,si,es
else
	uses	cx, dx
endif	; SPIDER_CHART

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	cx, bx
	mov	bx, locals.SDLV_points
	call	MemDerefES

	mov	di, locals.SDLV_pointer
	stosw
	mov	ax, cx
	stosw
	mov	locals.SDLV_pointer, di
	inc	locals.SDLV_numPoints
	.leave
	ret
SetPointCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesCreateOrUpdatePolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the polyline points for this series object

CALLED BY:	Line/Area/Scatter realize handlers

PASS:		ss:bp - SeriesDrawLocalVars
		ss:di - CreatePolylineParams
				
			CPP_flags,
			CGOP_flags, and
			CGOP_lineMask must be already filled in.

		*ds:si - series object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	This routine fills in the area color.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	It's up to the CALLER to get/set the current grobj.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesCreateOrUpdatePolyline	proc near
	uses	ax,bx,cx,dx,bp
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	call	SeriesGetAreaAttributes		; al - color,
						; ah -area mask

	mov	ss:[di].CGOP_areaColor, al
	mov	ss:[di].CGOP_areaMask, ah
	ornf	ss:[di].CGOP_flags, mask CGOF_AREA_COLOR or \
				mask CGOF_AREA_MASK

	mov	ss:[di].CGOP_locks, STANDARD_CHART_GROBJ_LOCKS or \
					mask GOL_EDIT

	; Set points and # points

	push	bx
	mov	bx, locals.SDLV_points
	mov	ax, MGIT_ADDRESS
	call	MemGetInfo
	pop	bx
	mov	ss:[di].CPP_points.segment, ax
	clr	ss:[di].CPP_points.offset

	mov	ax, locals.SDLV_numPoints
	mov	ss:[di].CPP_numPoints, ax

	clr	ss:[di].CGOP_position.P_x
	clr	ss:[di].CGOP_position.P_y

	; Make size same as chart group (for now)
	
	mov	ax, MSG_CHART_OBJECT_GET_SIZE
	call	UtilCallChartGroup

	mov	ss:[di].CGOP_size.P_x, cx
	mov	ss:[di].CGOP_size.P_y, dx

	xchg	di, bp
	call	ChartObjectCreateOrUpdatePolyline
	xchg	di, bp

	.leave
	ret
SeriesCreateOrUpdatePolyline	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMarkerShape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the marker shape for the current series

CALLED BY:	LineOrScatterCreateOrUpdatePolyline

PASS:		ss:bp - local vars

RETURN:		al - marker shape

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMarkerShape	proc near

locals	local	SeriesDrawLocalVars

		.enter	inherit 

		mov	al, MS_NONE
		test	locals.SDLV_flags, mask CF_MARKERS
		jz	done

		mov	al, MS_SQUARE

done:
		.leave
		ret

GetMarkerShape	endp




if ERROR_CHECK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSeriesCheckSeriesNumCL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure CL hasn't been biffed

CALLED BY:

PASS:		ss:bp - local frame (SeriesDrawLocalVars)
		cl - series number

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSeriesCheckSeriesNumCL	proc near
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	pushf
	cmp	cl, locals.SDLV_seriesCount
	ERROR_AE	ILLEGAL_SERIES_NUMBER
	popf

	.leave
	ret
ECSeriesCheckSeriesNumCL	endp




ForceRef	ECSeriesCheckSeriesNumCL
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesSetCreateGrObjParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to set up the CreateGrObjParams

CALLED BY:	All SERIES routines that setup a CreateGrObjParams
		structure on the stack

PASS:		ss:di - CreateGrObjParams
		ss:bp (local) SeriesDrawLocalVars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	THIS ROUTINE MUST BE THE FIRST THING CALLED AFTER CREATING THE
	PARAMS STRUCTURE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesSetCreateGrObjParams	proc near
	uses	ax
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	ss:[di].CGOP_flags, mask CGOF_DRAW_ORDER
	mov	ax, locals.SDLV_drawOrder
	mov	ss:[di].CGOP_drawOrder, ax

	.leave
	ret
SeriesSetCreateGrObjParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesSetGrObjGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the gstring of the grobj for this series object to
		the string in the current gstate.

CALLED BY:	DrawHiLowDropLine, PieRealize

PASS:		ss:bp - SeriesDrawLocalVars 
		*ds:si - series object

RETURN:		nothing 

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesSetGrObjGString	proc near
	uses	cx,di

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	sub	sp, size CreateGStringParams
	mov	di, sp

	call	SeriesSetCreateGrObjParams

	ornf	ss:[di].CGOP_flags, mask CGOF_AREA_COLOR or \
					mask CGOF_AREA_MASK 

	call	SeriesGetAreaAttributes
	mov	ss:[di].CGOP_areaColor, al
	mov	ss:[di].CGOP_areaMask, ah

	mov	ax, locals.SDLV_gstate
	mov	ss:[di].CGSP_gstring, ax

	mov	ax, locals.SDLV_gstringBlock
	mov	ss:[di].CGSP_vmBlock, ax

	xchg	di, bp
	call	ChartObjectCreateOrUpdateGStringGrObj
	xchg	di, bp

	add	sp, size CreateGStringParams

	.leave
	ret
SeriesSetGrObjGString	endp



