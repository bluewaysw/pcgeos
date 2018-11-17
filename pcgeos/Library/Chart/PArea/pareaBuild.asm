COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pareaBuild.asm

AUTHOR:		John Wedgwood, Oct  9, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 9/91	Initial revision

DESCRIPTION:
	Method handlers for rebuilding a chart.

	$Id: pareaBuild.asm,v 1.1 97/04/04 17:46:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlotAreaBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the plot area.

CALLED BY:	via MSG_CHART_OBJECT_BUILD
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cl	= ChartType
		ch	= ChartVariation
		dx	= ChartFlags
		bp	= BuildChangeFlags

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	The PlotArea is a parent of the axes and the series area.
	The pointers to the axes are stored in the PlotArea's instance
	data, while the SeriesGroup's OD is hard-wired into the block
	structure. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlotAreaBuild	method dynamic	PlotAreaClass,
		MSG_CHART_OBJECT_BUILD

	uses	ax, cx, dx,bp
	.enter

	ECCheckChartType	cl
	ECCheckFlags bp, BuildChangeFlags
	
	; Move chart type into BX

	clr	bh
	mov	bl, cl			

	; See if we should nuke the current axes

if PZ_PCGEOS
	;
	; This is a HACK to get rid of the label-drawing problem
	; which occurs in Pizza when changing to a chart type which
	; rotates the axis.  Nuke the axis on AXIS_ROTATE.
	;
	test	bp, mask BCF_AXIS_REMOVE or mask BCF_AXIS_ROTATE
else
	test	bp, mask BCF_AXIS_REMOVE
endif
	jz	afterNukeAxes

	DerefChartObject ds, si, di
	add	di, offset PAI_xAxis
	call	UtilDetachAndKill


	DerefChartObject ds, si, di 
	add	di, offset PAI_yAxis
	call	UtilDetachAndKill
	
	
afterNukeAxes:
	DerefChartObject ds, si, di
	tst	ds:[di].PAI_yAxis
	jnz	gotAxes
	
	ECCheckChartType bx
	call	cs:[bx].CreateAxisTable
	jmp	initialize


gotAxes:
ifdef	SPIDER_CHART
	ECCheckChartType cl
	cmp	cl, CT_SPIDER
	jnz	notSpider
	
	test	dx, mask CF_CATEGORY_TITLES
	jz	initialize

	push	cx
	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	mov	cx, mask COS_IMAGE_INVALID or mask COS_GEOMETRY_INVALID
	call	UtilCallAxes
	pop	cx

notSpider:
endif	;SPIDER_CHART

if not PZ_PCGEOS

	test	bp, mask BCF_AXIS_ROTATE
	jz	initialize
	
	;
	; Switch the axes.  Mark their geometry invalid
	;
	push	cx
	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	mov	cx, mask COS_IMAGE_INVALID or mask COS_GEOMETRY_INVALID
	call	UtilCallAxes
	pop	cx

	DerefChartObject ds, si, di 
	mov	ax, ds:[di].PAI_xAxis
	xchg	ax, ds:[di].PAI_yAxis
	mov	ds:[di].PAI_xAxis, ax

endif

initialize:
	call	InitializeAxes

	; Now, call superclass

	.leave
	mov	di, offset PlotAreaClass
	GOTO	ObjCallSuperNoLock

PlotAreaBuild	endm

ifdef	SPIDER_CHART
CreateAxisTable	word	\
	offset CreateNormalAxes,		; column
	offset CreateBar,		; Bar
	offset CreateNormalAxes,		; Line
	offset CreateNormalAxes,		; Area
	offset CreateScatter,
	offset CreatePie,
	offset CreateNormalAxes,
	offset CreateSpider
else	; SPIDER_CHART
CreateAxisTable	word	\
	offset CreateNormalAxes,		; column
	offset CreateBar,		; Bar
	offset CreateNormalAxes,		; Line
	offset CreateNormalAxes,		; Area
	offset CreateScatter,
	offset CreatePie,
	offset CreateNormalAxes
endif	; SPIDER_CHART



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeAxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set some bits, values, pointers, etc, in the axes

CALLED BY:	PlotAreaBuild

PASS:		bx - chart type
		*ds:si - PlotArea

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeAxes	proc near

	.enter
	cmp	bx, CT_PIE
	je	done

	DerefChartObject ds, si, di 

ifdef	SPIDER_CHART
	cmp	bx, CT_SPIDER
	jne 	notSpider
	call 	InitializeSpider
	jmp	done

notSpider:
endif	;SPIDER_CHART
 
	ECCheckChartType bx	
	call	cs:PlotAreaInitializeTable[bx]
	call	SetHorizontalAndVertical
	call	PlotAreaSetRelatedAndOther
done:
	.leave
	ret
InitializeAxes	endp




PlotAreaInitializeTable	word	\
	offset	InitializeNormalAxes,
	offset	InitializeBar,
	offset	InitializeNormalAxes,
	offset	InitializeNormalAxes,
	offset	InitializeScatter,
	offset	ErrorStub,
	offset	InitializeNormalAxes

ErrorStub	proc	near
EC <	ERROR	ILLEGAL_CHART_TYPE	>
NEC <	ret				>
ErrorStub	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHorizontalAndVertical
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the "horizontal" and "vertical" attributes in the
		axes. 

CALLED BY:	InitializeAxes

PASS:		*ds:si - PlotArea

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHorizontalAndVertical	proc near
	uses	ax,cx,si
	class	PlotAreaClass 
	.enter

	DerefChartObject ds, si, di
	push	ds:[di].PAI_xAxis
	mov	si, ds:[di].PAI_yAxis

	mov	cx, mask AA_VERTICAL		; (cl = AA_VERTICAL, ch = 0)
	mov	ax, MSG_AXIS_SET_ATTRIBUTES
	call	ObjCallInstanceNoLock

	; Clear the VERTICAL bit for the x-axis

	pop	si				; x axis
	mov	cx, mask AA_VERTICAL shl 8
	mov	ax, MSG_AXIS_SET_ATTRIBUTES
	call	ObjCallInstanceNoLock

	.leave
	ret
SetHorizontalAndVertical	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeNormalAxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the axes in a column/line/area chart

CALLED BY:	InitializeAxes

PASS:		ds:di - PlotArea

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeNormalAxes	proc near
	uses	ax,cx,si
	class	PlotAreaClass 
	.enter

	; Set the min/max series for the value (Y) axis

	mov	si, ds:[di].PAI_yAxis
	mov	cx, MAX_SERIES_COUNT shl 8
	mov	ax, MSG_VALUE_AXIS_SET_SERIES
	call	ObjCallInstanceNoLock

	.leave
	ret
InitializeNormalAxes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the axes for a bar chart

CALLED BY:	InitializeAxes

PASS:		ds:di - plot area

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeBar	proc near
	uses	ax,cx,si
	class	PlotAreaClass 
	.enter

	; Set the min/max series for the value (X) axis

	mov	si, ds:[di].PAI_xAxis
	mov	cx, MAX_SERIES_COUNT shl 8
	mov	ax, MSG_VALUE_AXIS_SET_SERIES
	call	ObjCallInstanceNoLock

	.leave
	ret
InitializeBar	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeScatter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init axes for a scatter chart

CALLED BY:	InitializeAxes

PASS:		ds:di - plot area

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeScatter	proc near
	uses	ax,cx,si
	class	PlotAreaClass 
	.enter

	; Set the min/max series for the (X) axis

	mov	si, ds:[di].PAI_xAxis
	clr	cx			; first/last are both 0
	mov	ax, MSG_VALUE_AXIS_SET_SERIES
	call	ObjCallInstanceNoLock

	; Set y-axis series to (1..MAX)

	mov	si, ds:[di].PAI_yAxis
	mov	cx, (MAX_SERIES_COUNT shl 8) or 1
	mov	ax, MSG_VALUE_AXIS_SET_SERIES
	call	ObjCallInstanceNoLock 

	.leave
	ret
InitializeScatter	endp

ifdef	SPIDER_CHART

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeSpider
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize only one axis for Spider chart

CALLED BY:	InitializeAxes
PASS:		ds:di	- plot area
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeSpider	proc	near
	uses	ax,cx,si
	class	PlotAreaClass

	.enter
	call	InitializeNormalAxes

	mov	cx, mask AA_VERTICAL		; (cl = AA_VERTICAL, ch = 0)
	mov	si, ds:[di].PAI_yAxis
	mov	ax, MSG_AXIS_SET_ATTRIBUTES
	call	ObjCallInstanceNoLock

	.leave
	ret
InitializeSpider	endp

endif	;SPIDER_CHART


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNormalAxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a horizontal category axis and a vertical value
		axis. 

CALLED BY:	PlotAreaBuild

PASS:		*ds:si	= PlotArea object
		ds:di	= PlotArea Instance data
		ch	= ChartVariation
		dx 	= ChartFlags

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNormalAxes	proc	near
	class	PlotAreaClass
	uses	ax
	.enter

	; Create a category axis for horizontal, and a value axis for
	; vertical. 

	mov	ax, offset PAI_xAxis
	call	CreateCategoryAxis

	mov	ax, offset PAI_yAxis
	call	CreateValueAxis

	.leave
	ret
CreateNormalAxes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build axes and series for a bar chart

CALLED BY:	

PASS:		*ds:si - PlotArea object
		dx - ChartFlags		

RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateBar	proc	near
	class	PlotAreaClass 
	uses	ax, cx, dx
	.enter
	; vertical category axis

	mov	ax, offset PAI_yAxis
	call	CreateCategoryAxis

	; horizontal value axis

	mov	ax, offset PAI_xAxis
	call	CreateValueAxis

	.leave
	ret
CreateBar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateScatter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build 2 value axes:  the x-axis covers only the first
		series, the y-axis covers the rest.

CALLED BY:	PlotAreaBuild

PASS:		*ds:si - PlotArea object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial Revision 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateScatter	proc	near
	uses	ax
	class	PlotAreaClass
	.enter

	; x-axis

	mov	ax, offset PAI_xAxis
	call	CreateValueAxis

	; y-axis

	mov	ax, offset PAI_yAxis
	call	CreateValueAxis

	.leave
	ret
	
CreateScatter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreatePie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing.  No axes are needed for pie, so forget it.

CALLED BY:	PlotAreaBuild

PASS:		ds:di - PlotArea object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreatePie	proc	near
	ret
CreatePie	endp

ifdef	SPIDER_CHART

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSpider
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create one vertical value axis.

CALLED BY:	PlotAreaBuild
PASS:		ds:di - PlotArea object
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateSpider	proc	near
	uses	ax
	class	PlotAreaClass
	.enter

	; y-axis

	mov	ax, offset PAI_yAxis
	segmov	es, <segment SpiderAxisClass>, di
	mov	di, offset SpiderAxisClass
	call	CreateAxisCommon
	.leave
	ret
CreateSpider	endp

endif	; SPIDER_CHART


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateCategoryAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a category axis

CALLED BY:	CreateScatter

PASS:		*ds:si - PlotArea object
		ax - offset in PlotArea instance to location to store
		axis chunk handle
		cl - AxisAttributes to set

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateCategoryAxis	proc near	
	uses	es,di
	.enter
	segmov	es, <segment CategoryAxisClass>, di
	mov	di, offset CategoryAxisClass
	call	CreateAxisCommon
	.leave
	ret
CreateCategoryAxis	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateValueAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a value axis and set the firstSeries and
		lastSeries fields

CALLED BY:

PASS:		*ds:si - PlotArea object
		ax - offset in PlotArea instance to location to store
			axis chunk handle


RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateValueAxis	proc near	
	uses	cx,es,di
	.enter
	segmov	es, <segment ValueAxisClass>, di
	mov	di, offset ValueAxisClass
	call	CreateAxisCommon
	.leave
	ret
CreateValueAxis	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAxisCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		
		*ds:si - PlotArea object

		ax = offset in instance data to place to store axis
		chunk handle

RETURN:		nothing 

DESTROYED:	bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAxisCommon	proc near	
	uses	ax,bx,di,si
	.enter
	push	ax, si			; PlotArea chunk handle,
					; offset to storage
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate

	; store chunk handle of new object

	pop	ax, bx
	mov	di, ds:[bx]
	add	di, ax
	mov	ds:[di], si

	mov	dx, si			; axis chunk handle
	mov	si, bx			; PlotArea chunk handle
	mov	bp, CCO_LAST shl offset CCF_REFERENCE
	call	ChartCompAddChild

	.leave
	ret
CreateAxisCommon	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlotAreaSetRelatedAndOther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the relations between all the axes

CALLED BY:

PASS:		*ds:si - PlotArea object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 9/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlotAreaSetRelatedAndOther	proc near	
	uses	ax,cx,dx,si
	class	PlotAreaClass 
	.enter

	DerefChartObject ds, si, di
	mov	si, ds:[di].PAI_xAxis
	mov	cx, ds:[di].PAI_yAxis
	mov	ax, MSG_AXIS_SET_RELATED_AXIS
	call	ObjCallInstanceNoLock

	xchg	si, cx
	call	ObjCallInstanceNoLock
	.leave
	ret
PlotAreaSetRelatedAndOther	endp
