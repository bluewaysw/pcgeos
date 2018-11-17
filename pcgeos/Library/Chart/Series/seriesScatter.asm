COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesScatter.asm

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
	

	$Id: seriesScatter.asm,v 1.1 97/04/04 17:47:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScatterRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ScatterClass object
		ds:di	= ScatterClass instance data
		es	= Segment of ScatterClass.

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

ScatterRealize	method	dynamic	ScatterClass, 
					MSG_CHART_OBJECT_REALIZE

locals	local	SeriesDrawLocalVars

	uses	ax,cx,dx

	.enter	inherit

	clr	locals.SDLV_numPoints
	clr	locals.SDLV_pointer 

	tst	locals.SDLV_seriesNum
	jnz	gotSeriesNum
	inc	locals.SDLV_seriesNum
gotSeriesNum:
	mov	cl, locals.SDLV_seriesNum
	
	mov	locals.SDLV_callback, offset ScatterSetPointCB
	call	SeriesDrawEachCategory

	call	LineOrScatterCreateOrUpdatePolyline

	inc	locals.SDLV_seriesNum
	.leave

	mov	di, offset ScatterClass
	GOTO	ObjCallSuperNoLock

ScatterRealize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScatterGetPointPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an x,y position for a point on a scatter chart

CALLED BY:

PASS:		ss:bp - SeriesDrawLocalVars
		cl - series #
		dx - category # 


RETURN:		IF NUMBERS AVAILABLE:
			carry clear
			ax, bx point (x,y)
		ELSE
			CARRY SET

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScatterGetPointPosition	proc near	
	uses	cx,si
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	call	SeriesGetValuePosition
	jc	done

	mov	bx, ax			; y-value

	mov	si, locals.SDLV_categoryAxis
	clr	cl			; get value for series 0
	mov	ax, MSG_AXIS_GET_VALUE_POSITION
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
ScatterGetPointPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScatterSetPointCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line to the current scatter point

CALLED BY:	SeriesDrawEachCategory

PASS:		ss:bp - SeriesDrawLocalVars
		cl - series #
		dx - category # 

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScatterSetPointCB	proc near	
	.enter
	call	ScatterGetPointPosition
	jc	done
	call	SetPointCommon
done:
	.leave
	ret
ScatterSetPointCB	endp

