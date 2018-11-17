COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pareaPosition.asm

AUTHOR:		John Wedgwood, Oct 21, 1991

ROUTINES:
	Name			Description
	----			-----------
	PlotAreaSetPosition	Position the axes and the series area.

	PositionAxes		Position an axis pair

	PositionSeriesGroup	Set the position of the Series Area

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/21/91	Initial revision

DESCRIPTION:
	Positioning code.

	$Id: pareaPosition.asm,v 1.1 97/04/04 17:46:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlotAreaSetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the axes and the series area.

CALLED BY:	via MSG_CHART_OBJECT_BOUNDS_SET
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		ax	= Method
		es	= Class segment
		cx, dx	= position

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlotAreaSetPosition	method dynamic	PlotAreaClass,
			MSG_CHART_OBJECT_SET_POSITION

	uses	ax,cx,dx,bp
	.enter

	; HACK! Don't call ChartCompClass -- call its superclass
	; instead!  The reason is that ChartComp will position both
	; children in the upper left-hand corner of the plot area.
	; This isn't bad, it's just unnecessary, as PlotArea
	; determines position itself.


	mov	di, offset ChartCompClass
	call	ObjCallSuperNoLock

	DerefChartObject ds, si, di
	
	tst	ds:[di].PAI_xAxis
	jnz	positionAxes
	tst	ds:[di].PAI_yAxis
	jz	done

ifdef	SPIDER_CHART
	call	PositionYAxis
	jmp	done
endif

positionAxes:
	;
	; Position the axes
	;
	call	PositionAxes		; Position the axis

done:
	call	PositionSeriesGroup
	.leave
	ret
PlotAreaSetPosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionAxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position an axis pair

CALLED BY:	PlotAreaSetPosition

PASS:		ds:di - PlotArea object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	X-axis position =
			LEFT: margin.R_left
			TOP:  margin.R_top + y-axis plotBounds top +
					y-axis intersectionRelPos

	Y-axis position:
			LEFT: margin.R_left + x-axis plotBounds.R_left +
					x-axis intersectionRelPos
			TOP:  margin.R_top

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 9/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionAxes	proc near	
	uses	ax,cx,dx,si

xAxisIntersect	local	word
xAxisPBLeft	local	word
xAxisPBTop	local	word

yAxisIntersect	local	word
yAxisPBLeft	local	word
yAxisPBBottom	local	word

	class	PlotAreaClass 
	.enter

	; Get intersection positions

	mov	si, ds:[di].PAI_xAxis
	mov	ax, MSG_AXIS_GET_INTERSECTION_REL_POSITION
	call	ObjCallInstanceNoLock
	mov	xAxisIntersect, ax

	push	bp
	mov	ax, MSG_AXIS_GET_PLOT_BOUNDS_INTERNAL
	call	ObjCallInstanceNoLock
	mov	bx, bp
	pop	bp
	mov	xAxisPBTop, bx
	mov	xAxisPBLeft, ax

	; For y-axis, get intersection and outsideLeft

	mov	si, ds:[di].PAI_yAxis
	mov	ax, MSG_AXIS_GET_INTERSECTION_REL_POSITION
	call	ObjCallInstanceNoLock
	mov	yAxisIntersect, ax

	push	bp
	mov	ax, MSG_AXIS_GET_PLOT_BOUNDS_INTERNAL
	call	ObjCallInstanceNoLock
	mov	bx, bp
	pop	bp
	mov	yAxisPBLeft, ax
	mov	yAxisPBBottom, dx

	; position y-axis
	;	LEFT: 	POS.P_x + 
	;		margin.R_left + 
	;		x-axis plotBounds.R_left +
	;		x-axis intersectionRelPos -
	;		y-axis PB.R_left
	;
	;	TOP:  POS.P_y + margin.R_top

	mov	cx, ds:[di].COI_position.P_x
	add	cx, ds:[di].CCI_margin.R_left
	add	cx, xAxisPBLeft
	add	cx, xAxisIntersect
	sub	cx, yAxisPBLeft

	mov	dx, ds:[di].COI_position.P_y
	add	dx, ds:[di].CCI_margin.R_top
	mov	ax, MSG_CHART_OBJECT_SET_POSITION
	call	ObjCallInstanceNoLock

	; X-axis position =
	;	LEFT: POS.P_x + margin.R_left
	;	TOP:  	POS.P_y +
	;		margin.R_top +
	;		y-axis plotBounds bottom -
	;		y-axis intersectionRelPos -
	;		x-axis plotBounds.R_top


	mov	dx, ds:[di].COI_position.P_y
	add	dx, ds:[di].CCI_margin.R_top
	add	dx, yAxisPBBottom
	sub	dx, yAxisIntersect
	sub	dx, xAxisPBTop

	mov	cx, ds:[di].COI_position.P_x
	add	cx, ds:[di].CCI_margin.R_left

	mov	si, ds:[di].PAI_xAxis
	mov	ax, MSG_CHART_OBJECT_SET_POSITION
	call	ObjCallInstanceNoLock
	.leave
	ret
PositionAxes	endp

ifdef	SPIDER_CHART

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionYAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the Y Axis

CALLED BY:	PlotAreaSetPositon
PASS:		ds:di	= PlotArea Object
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionYAxis	proc	near
	uses	ax,cx,dx,bp, si

	class 	PlotAreaClass
	.enter
	; For y-axis, get intersection and outsideLeft

	mov	si, ds:[di].PAI_yAxis

	mov	ax, MSG_AXIS_GET_PLOT_BOUNDS_INTERNAL
	call	ObjCallInstanceNoLock


	; position y-axis
	;	LEFT: 	POS.P_x + 
	;		margin.R_left + 
	;		x-axis plotBounds.R_left +
	;		x-axis intersectionRelPos -
	;		y-axis PB.R_left
	;
	;	TOP:  POS.P_y + margin.R_top
	
	mov	cx, ds:[di].COI_position.P_x
	add	cx, ds:[di].CCI_margin.R_left

	mov	dx, ds:[di].COI_position.P_y
	add	dx, ds:[di].CCI_margin.R_top
	mov	ax, MSG_CHART_OBJECT_SET_POSITION
	call	ObjCallInstanceNoLock


	.leave
	ret
PositionYAxis	endp

endif	; SPIDER_CHART


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionSeriesGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the position of the Series Area 

CALLED BY:	PlotAreaSetPosition

PASS:		*ds:si - PlotArea

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionSeriesGroup	proc near
	uses	ax,bx,cx,dx,di,si,bp
	class	PlotAreaClass 
	.enter

	; If there are no axes, make series area same position as plot
	; area

	movP	cxdx, ds:[di].COI_position

	mov	si, ds:[di].PAI_yAxis
	tst	si

ifdef	SPIDER_CHART
	jz	sendIt

	push	cx
	mov	si, ds:[di].PAI_xAxis
	tst	si
	jz	getY
	pop	cx
else
	jz	noAxes
endif	; SPIDER_CHART

	mov	ax, MSG_AXIS_GET_PLOT_BOUNDS
	call	ObjCallInstanceNoLock

	push	ax		; save x-position

ifdef	SPIDER_CHART
getY:
endif
	mov	si, ds:[di].PAI_yAxis
	mov	ax, MSG_AXIS_GET_PLOT_BOUNDS
	call	ObjCallInstanceNoLock

	mov	dx, bp		; y-position
	pop	cx		; x-position

ifndef	SPIDER_CHART
	jmp	sendIt
noAxes:	
	movP	cxdx, ds:[di].COI_position
endif	; SPIDER_CHART

sendIt:
	mov	ax, MSG_CHART_OBJECT_SET_POSITION
	mov	si, offset TemplateSeriesGroup
	call	ObjCallInstanceNoLock
	.leave
	ret
PositionSeriesGroup	endp




ChartCompCode	ends
