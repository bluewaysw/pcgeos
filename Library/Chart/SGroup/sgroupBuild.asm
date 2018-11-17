COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		sgroupBuild.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	SeriesGroupBuild		Build the series area

	CreateSeries		Create one series object for each series,
				make them children of the series area

	CreateSeriesCB		
				SeriesGroup's list of children.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/25/92   	Initial version.

DESCRIPTION:
	

	$Id: sgroupBuild.asm,v 1.1 97/04/04 17:46:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupObjClearAllGrObjes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke all the grobjes for this series object

PASS:		*ds:si	= SeriesGroupClass object
		ds:di	= SeriesGroupClass instance data
		es	= Segment of SeriesGroupClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesGroupObjClearAllGrObjes	method	dynamic	SeriesGroupClass, 
					MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
	uses	ax,cx
	.enter
	mov	cx, COMT_DROP_LINES
	call	ChartObjectFreeGrObjArray

	mov	cx, CODT_GRID_LINES
	call	ChartObjectDualClearGrObj

	.leave
	mov	di, offset SeriesGroupClass
	GOTO	ObjCallSuperNoLock
SeriesGroupObjClearAllGrObjes	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupSendToGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- SeriesGroupClass object
		ds:di	- SeriesGroupClass instance data
		es	- segment of SeriesGroupClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesGroupSendToGrObj	method	dynamic	SeriesGroupClass, 
					MSG_CHART_OBJECT_SEND_TO_GROBJ
	uses	ax,cx,dx,bp
	.enter
	mov_tr	ax, cx
	mov	cx, COMT_DROP_LINES
NOFXIP<	mov	bx, cs							>
	mov	di, offset SeriesGroupSendToGrObjCB
	call	ChartObjectArrayEnum

	DerefChartObject ds, si, di
	push	si
	movOD	bxsi, ds:[di].SGI_gridLines
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	.leave
	mov	di, offset SeriesGroupClass
	GOTO	ObjCallSuperNoLock
SeriesGroupSendToGrObj	endm





if FULL_EXECUTE_IN_PLACE
ChartObjectCode segment	resource
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupSendToGrObjCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to this grobj

CALLED BY:	SeriesGroupSendToGrObj via ChunkArrayEnum

PASS:		ax - message to send

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGroupSendToGrObjCB	proc far

	mov	bx, ds:[di].handle
	mov	si, ds:[di].offset
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	clc
	ret
SeriesGroupSendToGrObjCB	endp

if FULL_EXECUTE_IN_PLACE
ChartObjectCode	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Build the series group

PASS:		*ds:si	= SeriesGroupClass object
		ds:di	= SeriesGroupClass instance data
		es	= Segment of SeriesGroupClass.
		cl	= ChartType
		ch	= ChartVariation
		dx	= ChartFlags
		bp	= BuildChangeFlags

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

SeriesGroupBuild	method	dynamic	SeriesGroupClass, 
					MSG_CHART_OBJECT_BUILD
	uses	ax,cx,dx,bp
	.enter

	ECCheckChartType	cl
	ECCheckChartVariation	ch
	ECCheckFlags		dx, ChartFlags
	ECCheckFlags		bp, BuildChangeFlags

	test	bp, mask BCF_CHART_TYPE or \
			mask BCF_CHART_VARIATION or \
			mask BCF_DATA or \
			mask BCF_SERIES_COUNT or \
			mask BCF_CATEGORY_COUNT
	jz	done

	;
	; If chart type changed, then nuke all the series data.  Also
	; nuke them if the series or category count has changed. 
	;

	test	bp, mask BCF_CHART_TYPE  or \
			mask BCF_SERIES_COUNT or \
			mask BCF_CATEGORY_COUNT or \
			mask BCF_CHART_VARIATION_ATTR
	jnz	nukeSeries

	;
	; None of the major stuff has changed, but some numbers might
	; have, so force the series objects to redraw themselves.
	;

	mov	cl, mask COS_IMAGE_INVALID
	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	call	ObjCallInstanceNoLock

	mov	ax, MSG_CHART_OBJECT_MARK_TREE_INVALID
	call	ObjCallInstanceNoLock

	jmp	done
	

nukeSeries:
	mov	ax, MSG_META_OBJ_FREE
	call	ChartCompCallChildren

	mov	di, ds:[si]		; deref again.

	clr	ds:[di].CCI_comp.CP_firstChild.handle
	clr	ds:[di].CCI_comp.CP_firstChild.chunk

	; create a series object for each series

	ECCheckChartType	cl
	call	CreateSeries
done:
	.leave
	mov	di, offset SeriesGroupClass
	GOTO	ObjCallSuperNoLock
SeriesGroupBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSeries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create one series object for each series, make them
		children of the series area

CALLED BY:	SeriesGroupBuild

PASS:		*ds:si - SeriesGroup object
		cl - ChartType
		ch - ChartVariation
		dx - ChartFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	if SINGLE_SERIES flag is set
		build one object for each category

	if chart type is SCATTER
		number of objects is #series-1

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 9/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateSeries	proc near	
	class	SeriesGroupClass
	uses	ax,cx,si

locals	local	SeriesBuildVars

	.enter

	mov	locals.SBV_type, cl
	mov	locals.SBV_variation, ch
	mov	locals.SBV_flags, dx

	; Get series and category count
	call	UtilGetSeriesAndCategoryCount
	mov	locals.SBV_seriesCount, cl
	mov	locals.SBV_categoryCount, dx

	; Normally, one series object is created for each series.  In
	; pie charts and high-low charts, however, create one for each 
	; CATEGORY instead.

	test	locals.SBV_flags, mask CF_ONE_SERIES_OBJECT_PER_CATEGORY
	jnz	useCategoryCount

	clr	ch		; cx <- num objects to create

	cmp	locals.SBV_type, CT_SCATTER
	jne	insertLoop
	dec	cx
	jmp	insertLoop

useCategoryCount:
	mov	cx, dx		; cx <- num objects to create

insertLoop:
	;
	; Insert another series...
	; cx	= Current series number
	; *ds:si= Instance ptr
	;
	jcxz	quit				; Branch if no more series
	dec	cx	
	
	call	CreateSeriesCB			; ax <- series chunk
	
	jmp	insertLoop
quit:
	.leave
	ret
CreateSeries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSeriesCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to instantiate a series object

CALLED BY:	CreateSeries

PASS:		*ds:si 	= SeriesGroup object
		es	= Class segment
		cx	= Series number
		ss:bp	= SeriesBuildVars

RETURN:		nothing 

DESTROYED:	ax,bx,dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateSeriesCB	proc	near
	class	SeriesGroupClass
	uses	cx,di,si,bp
locals	local	SeriesBuildVars
	.enter	inherit

	; Create a new object.

	push	si
	mov	bl, locals.SBV_type
	clr	bh
	mov	di, cs:BuildSeriesTable[bx]	; get class to build
	mov	bx, ds:LMBH_handle		; bx <- block handle
	call	ObjInstantiate			; si <- object

	; Add child last in link

	mov	dx, si			; new child object
	pop	si			; SeriesGroup object
	mov	bp, CCO_LAST
	call	ChartCompAddChild

	.leave
	ret
CreateSeriesCB	endp

ifdef	SPIDER_CHART
BuildSeriesTable	word	\
	offset	ColumnClass,
	offset	BarClass,
	offset	LineSeriesClass,
	offset	AreaClass,
	offset	ScatterClass,
	offset	PieClass,
	offset	HighLowClass,
	offset 	SpiderClass
else	; SPIDER_CHART
BuildSeriesTable	word	\
	offset	ColumnClass,
	offset	BarClass,
	offset	LineSeriesClass,
	offset	AreaClass,
	offset	ScatterClass,
	offset	PieClass,
	offset	HighLowClass
endif	; SPIDER_CHART

.assert (size BuildSeriesTable eq ChartType)
