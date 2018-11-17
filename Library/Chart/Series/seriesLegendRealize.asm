COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesLegend.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	LegendRealize		Realize the legend

	LegendDrawItem		Draw the legend item for the current
				series/category

	LegendItemDrawRect		Draw a rectangle with the current line/area
				attributes.

	LegendItemDrawMarker	Draw a marker for the current legend item

	LegendItemDrawText		Create the text for this legend item

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/28/92   	Initial version.

DESCRIPTION:
	

	$Id: seriesLegendRealize.asm,v 1.1 97/04/04 17:47:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Realize the legend

PASS:		*ds:si	= LegendClass object
		ds:di	= LegendClass instance data
		es	= Segment of LegendClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	The legend is realized as a set of GrObj pictures and text
	objects.  The pictures are either rectangles or line-chart
	markers.  Code from the Series stuff is borrowed heavily.

	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendRealize	proc	far

	uses	ax,cx,dx
locals	local	SeriesDrawLocalVars
	.enter

		call	SetupSeriesDrawLocalVars

		clr	ColumnLocals.CV_curElement
		clr	locals.SDLV_categoryNum	
		clr	locals.SDLV_seriesNum

	;
	; For XY charts, only do legend for series 1-n
	;
		
		call	UtilGetChartAttributes
		cmp	cl, CT_SCATTER
		jne	afterInc
		inc	locals.SDLV_seriesNum
afterInc:
		

	;
	; Call superclass (sends message to kids)
	;

		mov	ax, MSG_CHART_OBJECT_REALIZE
		mov	di, offset LegendClass
		call	ObjCallSuperNoLock


	;
	; Now, clean up
	;

		call	FinishRealizeSeries

	.leave
	ret
LegendRealize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendItemRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	METHOD for LegendItemClass, MSG_CHART_OBJECT_REALIZE

PASS:		*ds:si	- LegendItemClass object
		ds:di	- LegendItemClass instance data
		es	- segment of LegendItemClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendItemRealize	proc	far

	class	LegendItemClass


locals	local	SeriesDrawLocalVars


	uses	ax,cx,dx,es

	.enter	inherit

EC <	ECCheckEtype	ds:[di].LII_type, LegendItemType	>

	cmp	ds:[di].LII_type, LIT_TEXT
	je	drawText

	;
	; Draw the rectangle or marker
	;

	mov	bl, locals.SDLV_type
	clr	bh
	ECCheckChartType	bx
	call	cs:LegendDrawTable[bx]
	inc	ColumnLocals.CV_curElement
	jmp	done

drawText:
	call	LegendItemDrawText
done:

	.leave
	mov	di, offset LegendItemClass
	GOTO	ObjCallSuperNoLock
LegendItemRealize	endm

ifdef	SPIDER_CHART
LegendDrawTable	word	\
	offset	LegendItemDrawRect,
	offset	LegendItemDrawRect,
	offset	LegendItemDrawMarker,
	offset	LegendItemDrawRect,
	offset	LegendItemDrawMarker,
	offset	LegendItemDrawRect,
	offset	ErrorStub,
	offset 	LegendItemDrawMarker
else	; SPIDER_CHART
LegendDrawTable	word	\
	offset	LegendItemDrawRect,
	offset	LegendItemDrawRect,
	offset	LegendItemDrawMarker,
	offset	LegendItemDrawRect,
	offset	LegendItemDrawMarker,
	offset	LegendItemDrawRect,
	offset	ErrorStub
endif	; SPIDER_CHART

.assert (size LegendDrawTable eq ChartType)


ErrorStub	proc	near
EC <	ERROR	ILLEGAL_CHART_TYPE	>
NEC <	ret				>
ErrorStub	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendItemDrawRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with the current line/area
		attributes. 

CALLED BY:

PASS:		ss:bp - SeriesDrawLocalVars 
		*ds:si - Legend object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendItemDrawRect	proc near	
	uses	di

	class	LegendClass

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	sub	sp, size CreateRectParams
	mov	di, sp

	push	si
	call	DrawRectOrMarkerCommon
	pop	si

	xchg	di, bp
	call	ChartObjectCreateOrUpdateRectangle
	xchg	di, bp

	add	sp, size CreateRectParams

	.leave
	ret
LegendItemDrawRect	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendItemDrawMarker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a marker for the current legend item

CALLED BY:	LegendRealize

PASS:		*ds:si - legend object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendItemDrawMarker	proc near	

	class	LegendClass

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	sub	sp, size CreatePolylineParams
	mov	di, sp

	push	si				; legend
	call	DrawRectOrMarkerCommon		; ^lbx:si - series grobj

	push	di
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	bxsi, cxdx
	

	mov	ax, MSG_SPLINE_GET_MARKER_SHAPE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS 
	call	ObjMessage
	pop	di
	ornf	ss:[di].CPP_flags, mask CPF_LEGEND
	mov	ss:[di].CPP_markerShape, al
	pop	si				; legend

	; store the coordinates for the points by hand.

	sub	sp, 3 * size Point
	mov	bx, sp

	clr	cx, dx				; position of points
	mov	ax, ss:[di].CGOP_size.P_y
	shr	ax
	add	dx, ax
	movP	ss:[bx], cxdx
	add	bx, size Point
	mov	ax, ss:[di].CGOP_size.P_x
	shr	ax
	add	cx, ax
	movP	ss:[bx], cxdx
	add	bx, size Point
	add	cx, ax
	movP	ss:[bx], cxdx
	mov	ss:[di].CPP_points.segment, ss
	mov	ss:[di].CPP_points.offset, sp
	mov	ss:[di].CPP_numPoints, 3

	xchg	di, bp
	call	ChartObjectCreateOrUpdatePolyline
	xchg	di, bp

	add	sp, size CreatePolylineParams + 3 * size Point

	.leave
	ret
LegendItemDrawMarker	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRectOrMarkerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the attribute tokens for the current legend item,
		and return the OD of the series grobject

CALLED BY:	LegendItemDrawRect, LegendItemDrawMarker

PASS:		ss:bp - SeriesDrawLocalVars
		*ds:si - LegendItem object
		ss:di - CreatePolylineParams

RETURN:		^lbx:si - OD of grobj

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawRectOrMarkerCommon	proc near
	uses	ax,cx

	class	LegendItemClass

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	DerefChartObject ds, si, bx
	movP	cxdx, ds:[bx].COI_position
	movP	ss:[di].CGOP_position, cxdx
	movP	cxdx, ds:[bx].COI_size
	movP	ss:[di].CGOP_size, cxdx

	mov	ss:[di].CGOP_flags, mask CGOF_USE_TOKENS
	mov	ss:[di].CGOP_locks, STANDARD_CHART_GROBJ_LOCKS

	mov	cx, ColumnLocals.CV_curElement
	mov	ax, MSG_SERIES_GROUP_FIND_SERIES_GROBJ
	call	UtilCallSeriesGroup
	movOD	bxsi, cxdx

	push	di
	mov	ax, MSG_GO_GET_GROBJ_LINE_TOKEN
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	mov	ss:[di].CGOP_lineToken, cx

	push	di
	mov	ax, MSG_GO_GET_GROBJ_AREA_TOKEN
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	mov	ss:[di].CGOP_areaToken, cx

	.leave
	ret
DrawRectOrMarkerCommon	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendItemDrawText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the text for this legend item

CALLED BY:	LegendItemRealize

PASS:		ss:bp - SeriesDrawLocalVars
		*ds:si - Legend object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendItemDrawText	proc near
		uses	di,si

		class	LegendClass

locals	local	SeriesDrawLocalVars
		.enter	inherit 


		mov	ax, ds:[di].COI_size.P_x
		shr	ax
		add	ax, ds:[di].COI_position.P_x
		mov	bx, ds:[di].COI_position.P_y
			
		mov	cl, TAT_TOP
		call	DrawSeriesOrCategoryTitle

		test	locals.SDLV_flags, mask CF_SINGLE_SERIES
		jnz	incCategory
		inc	locals.SDLV_seriesNum
		jmp	done
incCategory:
		inc	locals.SDLV_categoryNum
done:
		.leave
		ret
LegendItemDrawText	endp



SeriesCode	ends
