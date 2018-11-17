COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesLine.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

DESCRIPTION:
	

	$Id: seriesLine.asm,v 1.1 97/04/04 17:47:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineSeriesRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:		

PASS:		*ds:si	= LineSeriesClass object
		ds:di	= LineSeriesClass instance data
		es	= Segment of LineSeriesClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LineSeriesRealize	method	dynamic	LineSeriesClass, 
					MSG_CHART_OBJECT_REALIZE
	uses	ax,cx,dx

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	cl, locals.SDLV_seriesNum

	mov	ax, offset SetPointInDataBlock
	mov	locals.SDLV_callback, ax

	clr	locals.SDLV_pointer
	clr	locals.SDLV_numPoints
	call	SeriesDrawEachCategory
	
	call	LineOrScatterCreateOrUpdatePolyline

	inc	locals.SDLV_seriesNum

	.leave
	mov	di, offset LineSeriesClass
	GOTO	ObjCallSuperNoLock

LineSeriesRealize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineOrScatterCreateOrUpdatePolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create or update a polyline for line or scatter series.

CALLED BY:	LineSeriesRealize, ScatterRealize

PASS:		ss:[bp] - local vars
		

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineOrScatterCreateOrUpdatePolyline	proc near
	uses	di,si,bp
locals	local	SeriesDrawLocalVars
	.enter	inherit 


	sub	sp, size CreatePolylineParams
	mov	di, sp
	call	SeriesSetCreateGrObjParams

	ornf	ss:[di].CGOP_flags, mask CGOF_LINE_MASK or \
				mask CGOF_LINE_COLOR or \
				mask CGOF_LINE_STYLE

	call	LineOrScatterGetLineAttributes
	mov	ss:[di].CGOP_lineColor, al
	mov	ss:[di].CGOP_lineStyle, ah
			
	clr	ss:[di].CPP_flags	; CreatePolylineFlags

	call	GetMarkerShape
	mov	ss:[di].CPP_markerShape, al

	
	test	locals.SDLV_flags, mask CF_LINES
	jz	noLineMask
	mov	ss:[di].CGOP_lineMask, SDM_100
	jmp	gotLineMask

noLineMask:
	mov	ss:[di].CGOP_lineMask, SDM_0
gotLineMask:

	mov	cx, CODT_PICTURE
	call	ChartObjectDualGetGrObj

	call	SeriesCreateOrUpdatePolyline

	mov	cx, CODT_PICTURE
	call	ChartObjectDualSetGrObj


	add	sp, size CreatePolylineParams


	.leave
	ret
LineOrScatterCreateOrUpdatePolyline	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineOrScatterGetLineAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get line attributes for this line (scatter) object

CALLED BY:	LineOrScatterCreateOrUpdatePolyline

PASS:		ss:bp - SeriesDrawLocalVars 

RETURN:		al - line color
		ah - line style 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineOrScatterGetLineAttributes	proc near	
	uses	bx,cx,dx
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	cl, locals.SDLV_seriesNum

	; For SCATTER charts, decrement the series number

	cmp	locals.SDLV_type, CT_SCATTER
	jne	gotSeriesNum
	dec	cl
	jns	gotSeriesNum
	clr	cl
gotSeriesNum:

	; if MARKERS, then use "normal" line attributes (series 0)

	test	locals.SDLV_flags, mask CF_MARKERS
	jz	pickLineAttributes
	clr	cl

pickLineAttributes:
	mov	al, cl
	clr	ah
	mov	bl, length SeriesLineStyleTable
	div	bl

	; quotient in AL, remainder in AH
	; quotient is used for color
	; remainder is used for style
	
	push	ax				; remainder (ah)
	mov	bl, al
	clr	bh

	
EC <	cmp	bx, size SeriesLineColorTable		>
EC <	ERROR_AE	ILLEGAL_VALUE			>


	mov	al, cs:[bx].SeriesLineColorTable	; get current color

	pop	bx				; remainder (bh)
	mov	bl, bh
	clr	bh
	
EC <	cmp	bx, size SeriesLineStyleTable		>
EC <	ERROR_AE	ILLEGAL_VALUE			>

	mov	ah, cs:[bx].SeriesLineStyleTable
	.leave
	ret
LineOrScatterGetLineAttributes	endp



SeriesLineColorTable	byte \
	C_BLACK,
	C_BLUE,
	C_GREEN,
	C_CYAN,
	C_RED,
	C_VIOLET,
	C_BROWN,
	C_LIGHT_GRAY,
	C_DARK_GRAY,
	C_LIGHT_BLUE,
	C_LIGHT_GREEN,
	C_LIGHT_CYAN,
	C_LIGHT_RED

SeriesLineStyleTable LineStyle \
	LS_SOLID,
	LS_DASHED,
	LS_DOTTED,
	LS_DASHDOT,
	LS_DASHDDOT




