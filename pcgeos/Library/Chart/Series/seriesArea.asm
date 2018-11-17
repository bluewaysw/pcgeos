COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesArea.asm

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
	

	$Id: seriesArea.asm,v 1.1 97/04/04 17:47:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AreaRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= AreaClass object
		ds:di	= AreaClass instance data
		es	= Segment of AreaClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AreaRealize	method	dynamic	AreaClass, 
					MSG_CHART_OBJECT_REALIZE
locals	local	SeriesDrawLocalVars
	uses	ax,cx,dx
	.enter	inherit 

	; Set the pointer to the beginning of the block

	clr	locals.SDLV_pointer
	clr	locals.SDLV_numPoints
	
	; calculate the points for the current series

	mov	cl, locals.SDLV_seriesNum
	mov	locals.SDLV_callback, offset AreaSetPoint
	call	SeriesDrawEachCategory

	; Now, get data for prev series -- going in reverse.

	mov	locals.SDLV_callback, offset AreaSetPrevPoint
	call	SeriesDrawEachCategoryRV

	; Draw and fill the polygon

	mov	bx, locals.SDLV_points
	mov	ax, MGIT_ADDRESS
	call	MemGetInfo
	mov_tr	cx, ax
	clr	dx			; cx:dx - points

	mov	bx, locals.SDLV_categoryCount
	shl	bx
	call	AreaCreateOrUpdatePolyline

	test	locals.SDLV_flags, mask CF_SERIES_TITLES
	jz	removeTitle
	call	AreaDrawTitle
	jmp	done
removeTitle:
	mov	cx, CODT_TEXT
	call	ChartObjectDualClearGrObj
done:



	inc	locals.SDLV_seriesNum
	.leave
	mov	di, offset AreaClass
	GOTO	ObjCallSuperNoLock

AreaRealize	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AreaDrawTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw  the series title in the center of the polygon

CALLED BY:	AreaRealize

PASS:		*ds:si - area object
		ss:bp  - local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	left = GetCategoryPosition(0)
	right = GetCategoryPosition(categoryCount-1)
	top = GetValuePosition(seriesNum, (categoryCount-1)/2)
	bottom = GetValuePosition(seriesNum-1, (categoryCount-1)/2)


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AreaDrawTitle	proc near	
	uses	ax,bx,cx,dx,di,si,bp
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	;
	; calculate y-position
	;

	mov	cl, locals.SDLV_seriesNum
	mov	dx, locals.SDLV_categoryCount
	shr	dx, 1
	call	SeriesGetValuePosition
	mov_tr	bx, ax

	dec	cl
	call	SeriesGetValuePosition
	add	bx, ax
	shr	bx, 1				; vertical position

	clr	dx
	call	SeriesGetCategoryPosition	; left
	push	ax
	mov	dx, locals.SDLV_categoryCount
	dec	dx
	call	SeriesGetCategoryPosition	; right
	mov	cx, ax				; right
	pop	ax				; left
	add	ax, cx
	shr	ax
	mov	cl, TAT_CENTER
	call	DualDrawSeriesOrCategoryTitle
	.leave
	ret
AreaDrawTitle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AreaCreateOrUpdatePolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create or update the polyline grobj for this area object

CALLED BY:	AreaRealize

PASS:		*ds:si - area object
		ss:bp - local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AreaCreateOrUpdatePolyline	proc near
	uses	cx,ax

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	sub	sp, size CreatePolylineParams
	mov	di, sp
	call	SeriesSetCreateGrObjParams

	mov	ss:[di].CPP_flags, mask CPF_CLOSED
	mov	ss:[di].CPP_markerShape, MS_NONE

	mov	cx, CODT_PICTURE
	call	ChartObjectDualGetGrObj
	call	SeriesCreateOrUpdatePolyline

	call	ChartObjectDualSetGrObj

	add	sp, size CreatePolylineParams

	.leave
	ret
AreaCreateOrUpdatePolyline	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AreaSetPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current point in the data block.  If the
		current point doesn't exist, set the previous point.

CALLED BY:	AreaRealize via SeriesDrawEachCategory

PASS:		ss:bp - local vars
		cl - series #
		dx - category #

RETURN:		nothing 

DESTROYED:	ax,bx,cx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AreaSetPoint	proc near
	inc	cl
	GOTO	AreaSetPrevPoint
AreaSetPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AreaSetPrevPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the Previous point in the data block

CALLED BY:	AreaRealize via SeriesDrawEachCategoryRV

PASS:		ss:bp - local vars
		cl - series #
		dx - category #

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AreaSetPrevPoint	proc near
	.enter

	call	SeriesGetZeroPosition	; ax <- prev value position

	mov_tr	bx, ax
	call	SeriesGetCategoryPosition
	call	SetPointCommon

	.leave
	ret
AreaSetPrevPoint	endp




