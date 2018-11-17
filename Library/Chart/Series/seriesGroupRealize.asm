COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		sgroupRealize.asm

AUTHOR:		John Wedgwood, Oct 21, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/21/91	Initial revision

DESCRIPTION:
	Realizing code for Series Group

	$Id: seriesGroupRealize.asm,v 1.1 97/04/04 17:47:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Realize the series group

PASS:		*ds:si	= SeriesGroupClass object
		ds:di	= SeriesGroupClass instance data
		es	= Segment of SeriesGroupClass.
		cl	= ChartType
		ch 	= ChartVariation
		dx	= ChartFlags

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesGroupRealize	proc far

	uses	ax,cx,dx
locals	local	SeriesDrawLocalVars

	class	SeriesGroupClass

	.enter

ForceRef locals		; used by called procedures.

	;
	; Draw (or erase) the grid lines, if need be.
	;

	call	DrawGridLines

	call	SetupSeriesDrawLocalVars

	; call super - calls children


	mov	di, offset SeriesGroupClass
	call	ObjCallSuperNoLock

	call	DrawDropLines

	call	FinishRealizeSeries

	.leave
	ret
SeriesGroupRealize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawGridLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GridFlags from ChartGroup, and call the axes
		to do the drawing

CALLED BY:

PASS:		*ds:si - SeriesGroup

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawGridLines	proc near	
	uses	ax,cx,dx,di,bp
	class	SeriesGroupClass 
	.enter

	mov	ax, MSG_CHART_GROUP_GET_GRID_FLAGS
	call	UtilCallChartGroup

	tst	cl
	jz	noGridLines

	call	ChartObjectCreateGString
	push	ax				; gstring vm block
	
	mov	ax, MSG_AXIS_DRAW_GRID_LINES
	call	UtilCallAxes

	mov	di, bp		; gstate handle

	mov	cx, CODT_GRID_LINES
	call	ChartObjectDualGetGrObj

	; Find the first series object, so we can put the grid lines
	; before it in draw order

	push	si
	clr	cx
	mov	ax, MSG_SERIES_GROUP_FIND_SERIES_BY_NUMBER
	call	ObjCallInstanceNoLock		; *ds:ax - series

	mov_tr	si, ax
	mov	ax, MSG_CHART_OBJECT_FIND_GROBJ
	call	ObjCallInstanceNoLock		; ^lcx:dx - grobj for series
	mov	ax, GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	jcxz	gotPosition

	mov	ax, MSG_GB_FIND_GROBJ
	call	UtilCallChartBody		; cx - draw order
	mov	ax, cx
	ornf	ax, mask GOBAGOF_DRAW_LIST_POSITION

gotPosition:
	pop	si

	pop	cx				; gstring vm block

	sub	sp, size CreateGStringParams
	mov	bp, sp
	
	mov	ss:[bp].CGOP_flags, mask CGOF_DRAW_ORDER
	mov	ss:[bp].CGOP_drawOrder, ax
	mov	ss:[bp].CGSP_gstring, di
	mov	ss:[bp].CGSP_vmBlock, cx

	call	ChartObjectCreateOrUpdateGStringGrObj

	add	sp, size CreateGStringParams

	mov	cx, CODT_GRID_LINES
	call	ChartObjectDualSetGrObj

done:
	.leave
	ret

noGridLines:
	
	; If a grobj exists for this, then nuke it.

	mov	cx, CODT_GRID_LINES
	call	ChartObjectDualClearGrObj
	jmp	done

DrawGridLines	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDropLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw drop lines for the series group

CALLED BY:

PASS:		*ds:si - series group
		ss:bp - local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDropLines	proc near

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	clr	dx
	test	locals.SDLV_flags, mask CF_DROP_LINES
	jz	removeExtras

	clr	GroupLocals.GV_curElement

	mov	ax, offset DrawDropLinesCB
	mov	locals.SDLV_callback, ax
	call	SeriesDrawEachCategory
	mov	dx, GroupLocals.GV_curElement

removeExtras:
	mov	cx, COMT_DROP_LINES
	call	ChartObjectRemoveExtraGrObjs

	.leave
	ret
DrawDropLines	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDropLinesCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to draw a drop line for each category

CALLED BY:

PASS:		ss:bp - local vars
		*ds:si - SeriesGroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDropLinesCB	proc near
	uses	si,bp

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	cmp	locals.SDLV_type, CT_AREA
	je	area

	; Otherwise, type is CT_LINE

EC <	cmp	locals.SDLV_type, CT_LINE	>
EC <	ERROR_NE ILLEGAL_CHART_TYPE		>

	call	LineGetDropLinePosition
	jmp	gotPosition
area:

	; Skip categories 0 and (n-1)

	tst	dx
	jz	done

	push	dx
	inc	dx
	cmp	dx, locals.SDLV_categoryCount
	pop	dx
	je	done

	call	AreaGetDropLinePosition
gotPosition: 

	push	cx, dx
	mov	cx, COMT_DROP_LINES
	mov	dx, GroupLocals.GV_curElement
	call	ChartObjectMultipleGetGrObj
	pop	cx, dx

	; passes params in ax, bx
	call	ChartObjectCreateOrUpdateStandardLine

	mov	cx, COMT_DROP_LINES
	mov	dx, GroupLocals.GV_curElement
	call	ChartObjectMultipleSetGrObj

	inc	GroupLocals.GV_curElement

done:

	.leave
	ret
DrawDropLinesCB	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AreaGetDropLinePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out where to draw a drop line for an area chart

CALLED BY:	SeriesDrawEachCategory (AreaRealize)

PASS:		ss:bp - SeriesDrawLocalVars 
		dx - category count

RETURN:		ax,bx,cx,dx - position

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AreaGetDropLinePosition	proc near	

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	clr	cl
	call	SeriesGetZeroPosition		
	push	ax				; bottom

	; Top is the position of (seriesCount-1)

	mov	cl, locals.SDLV_seriesCount
	dec	cl

	call	SeriesGetDataPointPosition	; ax -left, bx -top
	mov	cx, ax				; right
	pop	dx				; bottom

	.leave
	ret
AreaGetDropLinePosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineGetDropLinePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out where to draw a drop line
		
CALLED BY:	DrawDropLines

PASS:		ss:bp - SeriesDrawLocalVars 
		dx - category #

RETURN:		IF CATEGORY NOT EMPTY:
			carry clear
			ax,bx,cx,dx - coordinates 
		ELSE
			carry set

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineGetDropLinePosition	proc near	
	uses	si,di
locals	local	SeriesDrawLocalVars
	.enter	inherit

	; get MAX and MIN for all series for the current category

	push	bp
	mov	cx, (MAX_SERIES_COUNT shl 8)
	mov	bp, dx
	mov	ax, MSG_CHART_GROUP_GET_RANGE_MAX_MIN
	call	UtilCallChartGroup
	pop	bp
	jc	done

	mov	ax, MSG_AXIS_VALUE_TO_POSITION
	mov	si, locals.SDLV_valueAxis
	call	ObjCallInstanceNoLock
	mov	bx, ax				; bottom

	mov	ax, MSG_AXIS_VALUE_TO_POSITION
	call	ObjCallInstanceNoLock		
	push	ax				; top

	call	SeriesGetCategoryPosition
	mov	cx, ax				; left, right
	pop	dx				; top
	clc
done:
	.leave
	ret
LineGetDropLinePosition	endp










COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSeriesDrawLocalVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the local variables for drawing each series

CALLED BY:

PASS:		*ds:si - SeriesGroup
		cl - ChartType
		ch - ChartVariation
		dl - ChartFlags

		ss:bp - SeriesDrawLocalVars 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 9/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSeriesDrawLocalVars	proc far
	uses	ax,bx,cx,dx,di,si

	class	PlotAreaClass 		; So I can get axis chunk
					; handles 

locals	local	SeriesDrawLocalVars

	.enter	inherit

	clr	locals.SDLV_seriesNum
	clr	locals.SDLV_categoryNum
	clr	locals.SDLV_intersect	; for pie charts.
	mov	locals.SDLV_type, cl
	mov	locals.SDLV_variation, ch
	mov	locals.SDLV_flags, dx
	mov	locals.SDLV_drawFlags, mask SDF_CENTER_TEXT

	;
	; Get number of series & number of categories
	;

	mov	si, offset TemplateChartGroup
	mov	ax, MSG_CHART_GROUP_GET_SERIES_COUNT
	call	ObjCallInstanceNoLock
	mov	locals.SDLV_seriesCount, cl

	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	ObjCallInstanceNoLock
	mov	locals.SDLV_categoryCount, cx

	;
	; If pie chart, don't do any Axis stuff
	;

	ECCheckEtype locals.SDLV_type, ChartType
	cmp	locals.SDLV_type, CT_PIE
	je	noAxes

	;
	; ASSUME X-AXIS IS ALWAYS DRAWN BEFORE Y-AXIS -- Place each
	; series object in draw order BEFORE the x-axis.  Use reverse
	; draw order, as this value won't change throughout series
	; realize.
	;

	assume	ds:ChartUI
	mov	di, ds:[TemplatePlotArea]
	assume	ds:dgroup

ifdef	SPIDER_CHART
	; If it is a spider chart, we want the data drawn AFTER the axis.
	cmp	locals.SDLV_type, CT_SPIDER
	jz	noAxisGrObj
endif

	mov	si, ds:[di].PAI_xAxis
	mov	ax, MSG_CHART_OBJECT_FIND_GROBJ
	call	ObjCallInstanceNoLock		; ^lcx:dx - grobj
	jcxz	noAxisGrObj

	;
	; Now ask the grobj body what the grobj's draw order position
	; is 	
	;

	mov	ax, MSG_GB_FIND_GROBJ
	call	UtilCallChartBody
EC <	ERROR_NC	OBJECT_NOT_FOUND			>
	inc	dx
	mov	locals.SDLV_drawOrder, dx	; save reverse order.
	jmp	gotOrder

noAxisGrObj:	
	mov	locals.SDLV_drawOrder, 	GOBAGOR_LAST or\
				 mask GOBAGOF_DRAW_LIST_POSITION

gotOrder:

	;
	; Get the value and category axes.
	; If bar chart, x-axis is value axis, otherwise, vice versa
	;

	assume	ds:ChartUI
	mov	di, ds:[TemplatePlotArea]
	assume	ds:dgroup

	mov	ax,  ds:[di].PAI_xAxis
	mov	bx,  ds:[di].PAI_yAxis

	cmp	locals.SDLV_type, CT_BAR
	jne	gotAxes
	xchg	ax, bx

gotAxes:
	mov	locals.SDLV_categoryAxis, ax
	mov	locals.SDLV_valueAxis, bx
	mov	si, bx			; value axis

ifdef	SPIDER_CHART
	tst	ax
	jz	afterAxes	; No category axis, so no intersection.
endif	

	;
	; Now, value axis is in SI.
	; Find out where the category axis intercepts the value axis
	;

	mov	ax, MSG_AXIS_GET_INTERSECTION_POSITION
	call	ObjCallInstanceNoLock
	mov	locals.SDLV_intersect, ax	
	jmp	afterAxes

noAxes:
	mov	locals.SDLV_drawOrder, 	GOBAGOR_LAST or\
				 mask GOBAGOF_DRAW_LIST_POSITION

afterAxes:

	;
	; Initialize type-specific variables
	;

	mov	bl, locals.SDLV_type
	clr	bh
	call	cs:SetupLocalVarsTable[bx]

	.leave
	ret
SetupSeriesDrawLocalVars	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishRealizeSeries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free any blocks allocated by the SeriesDraw routine

CALLED BY:

PASS:		*ds:si - SeriesGroup object 
		ss:bp - SeriesDrawLocalVars 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FinishRealizeSeries	proc far
	uses	bx
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	; clean up afterwards

	mov	bl, locals.SDLV_type
	clr	bh
	call	cs:FinishRealizeTable[bx]
	clc
	.leave
	ret
FinishRealizeSeries	endp

Stub	proc	near
	ret
Stub	endp

ifdef	SPIDER_CHART
SetupLocalVarsTable	word \
	offset	SetupLocalVarsColumnOrBar,
	offset	SetupLocalVarsColumnOrBar,
	offset	SetupLocalVarsLineOrScatter,
	offset	SetupLocalVarsArea,
	offset	SetupLocalVarsLineOrScatter,
	offset	SetupLocalVarsPie,
	offset	Stub,
	offset	SetupLocalVarsSpider
else	; SPIDER_CHART
SetupLocalVarsTable	word \
	offset	SetupLocalVarsColumnOrBar,
	offset	SetupLocalVarsColumnOrBar,
	offset	SetupLocalVarsLineOrScatter,
	offset	SetupLocalVarsArea,
	offset	SetupLocalVarsLineOrScatter,
	offset	SetupLocalVarsPie,
	offset	Stub
endif	; SPIDER_CHART

.assert (size SetupLocalVarsTable eq ChartType)

ifdef	SPIDER_CHART
FinishRealizeTable	word	\
	offset	Stub,
	offset	Stub,
	offset	FreePointsBlock,
	offset	FreePointsBlock,
	offset	FreePointsBlock,
	offset	Stub,
	offset	Stub,
	offset	FreePointsBlock
else	; SPIDER_CHART
FinishRealizeTable	word	\
	offset	Stub,
	offset	Stub,
	offset	FreePointsBlock,
	offset	FreePointsBlock,
	offset	FreePointsBlock,
	offset	Stub,
	offset	Stub
endif	; SPIDER_CHART

.assert (size FinishRealizeTable eq ChartType)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupLocalVarsColumnOrBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the local variables for column and bar graphs

CALLED BY:	SetupSeriesDrawLocalVars

PASS:		ss:bp - SeriesDrawLocalVars 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	HACK: assume ColumnVars and BarVars are identical

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupLocalVarsColumnOrBar	proc near	
	uses	ds,es,si,di,ax
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	;
	; Get category width
	;

	mov	ax, MSG_CATEGORY_AXIS_GET_CATEGORY_WIDTH
	mov	si, locals.SDLV_categoryAxis
	call	ObjCallInstanceNoLock

	call	FloatDup
	segmov	es, ss
	lea	di, ColumnLocals.CV_width
	call	FloatPopNumber

	test	locals.SDLV_flags, mask CF_STACKED
	jnz	gotSeriesWidth

	;
	; divide by the number of series to get series width
	;

	mov	al, locals.SDLV_seriesCount
	cbw
	call	FloatWordToFloat
	call	FloatDivide

gotSeriesWidth:

	call	FloatDup			; keep series width on stack.
	segmov	es, ss
	lea	di, ColumnLocals.CV_seriesWidth
	call	FloatPopNumber

	;
	; compute the overlap amount.  The overlap is expressed as a
	; percentage, so we take this amount, and multiply it by the
	; series width to produce an amount (in points) that will be
	; added/subtracted to the position of each column rectangle.
	;

	clr	al
	cmp	locals.SDLV_variation, CCV_OVERLAPPED
	jne	gotOverlap
	mov	al, DEFAULT_COLUMN_OVERLAP
gotOverlap:
	call	FloatPushPercent
	call	FloatMultiply
	lea	di, ColumnLocals.CV_overlap
	call	FloatPopNumber

	;
	; If the columns overlap, then make each series a bit wider.
	; The amount to add depends on the number of series:
	;
	; Extra width = (overlap*(#series-1))/#series
	;
	cmp	locals.SDLV_variation, CCV_OVERLAPPED
	jne	done

	cmp	locals.SDLV_seriesCount, 1
	jle	done

	segmov	ds, ss
	lea	si, ColumnLocals.CV_overlap
	call	FloatPushNumber			; FP: overlap

	mov	al, locals.SDLV_seriesCount
	dec	al
	cbw
	call	FloatWordToFloat		; FP: overlap #series-1
	call	FloatMultiply			; 

	mov	al, locals.SDLV_seriesCount
	cbw
	call	FloatWordToFloat
	call	FloatDivide

	;
	; Add this amount to the series width
	;

	lea	si, ColumnLocals.CV_seriesWidth
	call	FloatPushNumber
	call	FloatAdd
	lea	di, ColumnLocals.CV_seriesWidth
	call	FloatPopNumber

done:
	.leave
	ret
SetupLocalVarsColumnOrBar	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupLocalVarsLineOrScatter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	setup local vars for the line & scatter charts.

CALLED BY:	

PASS:		ss:bp - local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupLocalVarsLineOrScatter	proc near
	uses	ax
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	ax, locals.SDLV_categoryCount
	call	AllocPointsBlock

	.leave
	ret
SetupLocalVarsLineOrScatter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupLocalVarsArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block to hold the polygons created during
		area chart drawing

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupLocalVarsArea	proc near	
	uses	ax,cx
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	; allocate a memory block to draw the series data
	; we need space for 2 * category count

	mov	ax, locals.SDLV_categoryCount
	shl	ax
	call	AllocPointsBlock
	.leave
	ret
SetupLocalVarsArea	endp

ifdef	SPIDER_CHART

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupLocalVarsSpider
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block for points of a spider chart.

CALLED BY:	
PASS:		ss:bp 	= Local vars
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupLocalVarsSpider	proc	near
	uses	ax
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	ax, locals.SDLV_categoryCount
	inc	ax
	call	AllocPointsBlock
	.leave
	ret
SetupLocalVarsSpider	endp

endif	; SPIDER_CHART


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocPointsBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a points block to hold points created for
		line/area/scatter charts.

CALLED BY:
	SetupLocalVarsLineOrScatter / SetupLocalVarsArea

PASS:		ss:[bp] - local vars	
		ax - # of points that the block will need to hold

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocPointsBlock	proc near
	uses	ax,bx,cx,dx
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	; Multiply # points by size of each point

	mov	cx, size Point
	mul	cx			; ax - size of polygon
	ECMakeSureZero	dx

	mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_NO_ERR shl 8)
	call	MemAlloc

	mov	locals.SDLV_points, bx
	.leave
	ret
AllocPointsBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupLocalVarsPie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup local vars for pie charts

CALLED BY:

PASS:		ss:bp - local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MIN_PIE_DIAMETER = 10

SetupLocalVarsPie	proc near	
	uses	ax,bx,cx,dx,di,si

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	;
	; Get max value for the first series (since there's only one)
	;

	mov	ax, MSG_CHART_GROUP_GET_SERIES_MAX_MIN
	clr	cx			; series numbers (min, max)
	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock
LONG	jc	error


	call	FloatDrop		; FP: max

	push	es, di
	segmov	es, ss
	lea	di, PieLocals.PV_max
	call	FloatPopNumber
	pop	es, di

	;
	; get center -- center = PlotArea position + 1/2 PlotArea size
	;

	mov	si, offset TemplatePlotArea
	mov	ax, MSG_CHART_OBJECT_GET_SIZE
	call	ObjCallInstanceNoLock

	push	cx, dx			; size

	shr	cx, 1
	shr	dx, 1
	push	cx, dx			; size/2
	mov	ax, MSG_CHART_OBJECT_GET_POSITION
	call	ObjCallInstanceNoLock
	pop	ax, bx			; size/2
	addP	cxdx, axbx
	movP	PieLocals.PV_center, cxdx


	; If there are category titles or value labels, then we must
	; reduce the width by the width of the titles.  We assume the
	; worst case which is that there is a title on both the left
	; and right sides of the pie, and each one is the maximum
	; title width.  
	;
	; Subtract height by max height
	; Subtract width by max width * 2
	;

	push	bp
	clr	cx, dx, bp
	mov	ax, MSG_CHART_OBJECT_GET_MAX_TEXT_SIZE
	mov	si, offset TemplateSeriesGroup
	call	ObjCallInstanceNoLock	; cx - width, dx - height
	pop	bp

	movP	axbx, cxdx
	pop	cx, dx			; size

	sub	dx, bx
	shl	ax, 1
	sub	cx, ax

	;
	; get diameter (minimum of width & height)
	;

	Min	dx, cx
	push	dx

	;
	; Reduce the diameter by some amount based on the chart
	; variation. 
	;

	mov	bl, locals.SDLV_variation
	clr	bh
	mov	ax, cs:AdjustPieDiameterTable[bx]
	clr	bx, cx		; DX.CX - diameter
				; BX.AX - percentage to adjust it by
	call	GrMulWWFixed

	;
	; DX - amount to reduce based on variation
	;

	pop	ax		; original diameter
	sub	ax, dx		; adjusted amount
	Max	ax, MIN_PIE_DIAMETER

	shr	ax, 1
	mov	PieLocals.PV_radius, ax

	;
	; Now, set explode amount
	;

	mov_tr	dx, ax		; radius
	clr	cx
	mov	bl, locals.SDLV_variation
	clr	bh
	mov	ax, cs:ExplodePieTable[bx]
	clr	bx, cx
	call	GrMulWWFixed
	mov	PieLocals.PV_explode, dx


	; Set the CloseType in the ArcParams structure
	mov  	PieLocals.PV_arcParams.AP_close, ACT_PIE
	clc
done:
	.leave
	ret

error:

	;
	; There's no numeric data in this series.  Just store 1 as the
	; series max (unless you have a better idea!)
	;
	call	Float1
	push	es, di
	segmov	es, ss
	lea	di, PieLocals.PV_max
	call	FloatPopNumber
	pop	es, di
	jmp	done

SetupLocalVarsPie	endp



AdjustPieDiameterTable	word	\
	PIE_DEFAULT_MARGIN,			; bullshit value
	PIE_DEFAULT_MARGIN,
	PIE_DEFAULT_MARGIN,
	PIE_ONE_EXPLODED_REDUCE_RADIUS,
	PIE_ALL_EXPLODED_REDUCE_RADIUS,
	PIE_DEFAULT_MARGIN

ExplodePieTable	word	\
	0,
	0,
	0,
	PIE_ONE_EXPLODED_MOVE_WEDGE,
	PIE_ALL_EXPLODED_MOVE_WEDGE,
	0




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreePointsBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the block created in SetupLocalVars

CALLED BY:	FinishRealizeSeries

PASS:		ss:bp - SeriesDrawLocalVars 

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreePointsBlock	proc near	

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	bx, locals.SDLV_points
	call	MemFree

	.leave
	ret
FreePointsBlock	endp

