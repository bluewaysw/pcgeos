COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pareaGeometry.asm

AUTHOR:		John Wedgwood, Oct  9, 1991

ROUTINES:
	Name			Description
	----			-----------
	PlotAreaRecalcSize	Recompute the size of the plot area.

	PlotAreaRecalcAxisSizes Recalculate the sizes of the (passed) axes

	Stub			Do nothing

				Do nothing

	CallXAxisFirst		send a message to the X axis, then to the Y
				axis

	CallYAxisFirst		send a message to the X axis, then to the Y
				axis

	CallYOnly		send a message only to the Y axis

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 9/91	Initial revision

DESCRIPTION:
	Geometry code for the plot area.

	$Id: pareaGeometry.asm,v 1.1 97/04/04 17:46:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlotAreaRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recompute the size of the plot area.

CALLED BY:	via MSG_CHART_OBJECT_RECALC_SIZE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= suggested width
		dx	= suggested height

RETURN:		cx	= Desired width 
		dx	= Desired height

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Calculate axis sizes, 
	set series area size.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlotAreaRecalcSize	method dynamic	PlotAreaClass,
			MSG_CHART_OBJECT_RECALC_SIZE
	.enter

	push	si			; plot area

	; calculate margin

	call	PlotAreaCalcMargin

	;
	; Call superclass -- have kids recalc sizes. XXX: This causes
	; the SeriesGroup (and its children) to get a RECALC_SIZE
	; message, even though its too early at this point for that
	; object to get the message.  The result is that it's sent
	; reduntantly, but it really doesn't take that long...
	;


	mov	di, offset PlotAreaClass
	call	ObjCallSuperNoLock		; cx, dx - child sizes 

	;
	; See if there're any axes.  If not, just send size to series
	; group. 
	;

	DerefChartObject ds, si, di
	tst	ds:[di].PAI_yAxis
	jz	setSeriesGroup

	;
	; Otherwise, do "PASS 2" of the axis geometry calculations
	;
	call	UtilGetChartAttributes
	mov	bl, cl
	clr	bh

	push	bx
	mov	ax, MSG_AXIS_GEOMETRY_PART_2
	call	cs:RecalcAxesTable[bx]
	pop	bx

	;
	; Update the plot area's size to the max width/height of the axes
	;

	call	PlotAreaUpdateSize


setSeriesGroup:
	; If there are axes, then use the PlotBounds of the axes to
	; set the series area.  Otherwise, series area is the same as
	; the PlotArea bounds.

	DerefChartObject	ds, si, di	
	mov	si, ds:[di].PAI_xAxis
	tst	si

ifdef	SPIDER_CHART
	; Since spider charts have no x-axis we have to check the y-axis.
	jz	checkY				;No x - Is it a pie or
						;spider chart?
else
	jz	noAxes				;A pie chart
endif	; SPIDER_CHART

	mov	ax, MSG_AXIS_GET_PLOTTABLE_WIDTH
	call	ObjCallInstanceNoLock
	mov_tr	cx, ax

ifdef	SPIDER_CHART
	jmp 	getY

checkY:
	movP	cxdx, ds:[di].COI_size
	mov	si, ds:[di].PAI_yAxis
	tst 	si
	jz	callSeriesGroup			;No x or y axis - Pie
						;chart

getY:
endif	; SPIDER_CHART

	mov	si, ds:[di].PAI_yAxis
	mov	ax, MSG_AXIS_GET_PLOTTABLE_HEIGHT
	call	ObjCallInstanceNoLock
	mov_tr	dx, ax

ifndef	SPIDER_CHART
	jmp	callSeriesGroup
	
noAxes:
	movP	cxdx, ds:[di].COI_size
endif	; SPIDER_CHART
		
callSeriesGroup:
	mov	ax, MSG_CHART_OBJECT_RECALC_SIZE
	mov	si, offset TemplateSeriesGroup
	call	ObjCallInstanceNoLock

	; Return size to caller

	pop	si
	DerefChartObject ds, si, di
	movP	cxdx, ds:[di].COI_size

	.leave
	ret
PlotAreaRecalcSize	endm

ifdef 	SPIDER_CHART
RecalcAxesTable	word 	\
	offset	CallXAxisFirst,
	offset	CallYAxisFirst,
	offset	CallXAxisFirst,
	offset	CallXAxisFirst,
	offset	CallYAxisFirst,
	offset	Stub,
	offset	CallXAxisFirst,
	offset 	CallYOnly
else	; SPIDER_CHART
RecalcAxesTable	word 	\
	offset	CallXAxisFirst,
	offset	CallYAxisFirst,
	offset	CallXAxisFirst,
	offset	CallXAxisFirst,
	offset	CallYAxisFirst,
	offset	Stub,
	offset	CallXAxisFirst
endif	; SPIDER_CHART


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlotAreaUpdateSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the plot area's size in the event that the axes
		became larger in "step 2" calculations

CALLED BY:	PlotAreaRecalcSize

PASS:		cx, dx - original plot area size
		*ds:si - plot area

RETURN:		cx, dx - new, larger bounds

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/20/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlotAreaUpdateSize	proc near

	class	PlotAreaClass

bounds	local	Point

	uses	ax, di, si

	.enter

	clr	bounds.P_x
	clr	bounds.P_y

	push	si
	DerefChartObject ds, si, di
	mov	ax, MSG_CHART_OBJECT_GET_SIZE
	mov	si, ds:[di].PAI_xAxis
	tst	si
	jz	getY
	call	ObjCallInstanceNoLock
	Max	bounds.P_x, cx
	Max	bounds.P_y, dx

getY:
	mov	si, ds:[di].PAI_yAxis
	call	ObjCallInstanceNoLock
	Max	cx, bounds.P_x
	Max	dx, bounds.P_y
	pop	si

	add	cx, ds:[di].CCI_margin.R_left
	add	cx, ds:[di].CCI_margin.R_right
	add	dx, ds:[di].CCI_margin.R_top
	add	dx, ds:[di].CCI_margin.R_bottom
	mov	ax, MSG_CHART_OBJECT_SET_SIZE
	call	ObjCallInstanceNoLock

	.leave
	ret
PlotAreaUpdateSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Stub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing

CALLED BY:

PASS:		nothing

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Stub	proc near
	ret
Stub	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CallXAxisFirst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a message to the X axis, then to the Y axis

CALLED BY:

PASS:		ds:di - PlotArea

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallXAxisFirst	proc	near
	uses	si
	class	PlotAreaClass 
	.enter

	push	ds:[di].PAI_yAxis, ax
	mov	si, ds:[di].PAI_xAxis
	call	ObjCallInstanceNoLock

	pop	si, ax
	call	ObjCallInstanceNoLock

	.leave
	ret
CallXAxisFirst	endp 


CallYAxisFirst	proc	near
	uses	si
	class	PlotAreaClass 
	.enter

	push	ds:[di].PAI_xAxis, ax
	mov	si, ds:[di].PAI_yAxis
	call	ObjCallInstanceNoLock

	pop	si, ax
	call	ObjCallInstanceNoLock
	.leave
	ret
CallYAxisFirst	endp

ifdef	SPIDER_CHART
CallYOnly	proc	near
	uses	si
	class	PlotAreaClass 
	.enter
	mov	si, ds:[di].PAI_yAxis
	call	ObjCallInstanceNoLock
	.leave
	ret
CallYOnly	endp
endif	; SPIDER_CHART





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlotAreaCalcMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the extra space surrounding the axes

CALLED BY:	PlotAreaRecalcSize

PASS:		ds:di - plot area
		cx, dx - suggested size for plot area

RETURN:		cx, dx - suggested size for axes
		CCI_margin filled in.

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlotAreaCalcMargin	proc near
	class	PlotAreaClass
	uses	ax, cx, dx
	.enter

	clr	ax
	mov	ds:[di].CCI_margin.R_top, ax
	mov	ds:[di].CCI_margin.R_bottom, ax
	mov	ds:[di].CCI_margin.R_left, ax
	mov	ds:[di].CCI_margin.R_right, ax

	call	UtilGetChartAttributes

	;
	; For COLUMN and BAR charts, add space for value labels, if any
	;
	test	dx, mask CF_VALUES
	jz	done

	cmp	cl, CT_COLUMN
	je	column
	cmp	cl, CT_BAR
	jne	done


	;
	; XXX: FIX THIS:  Should really send
	; MSG_CHART_OBJECT_GET_MAX_TEXT_SIZE to the series
	; group to find out the max x/y bounds of all the series objects!
	;


	; BAR CHART
	; put extra space on the sides

	add	ds:[di].CCI_margin.R_left, DEFAULT_VALUE_LABEL_WIDTH
	add	ds:[di].CCI_margin.R_right, DEFAULT_VALUE_LABEL_WIDTH
	jmp	done

column:
	add	ds:[di].CCI_margin.R_top, DEFAULT_VALUE_LABEL_HEIGHT
	add	ds:[di].CCI_margin.R_bottom, DEFAULT_VALUE_LABEL_HEIGHT

done:
	.leave
	ret
PlotAreaCalcMargin	endp

