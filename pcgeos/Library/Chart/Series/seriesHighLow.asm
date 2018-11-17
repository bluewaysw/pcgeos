COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesHighLow.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/15/92   	Initial version.

DESCRIPTION:
	

	$Id: seriesHighLow.asm,v 1.1 97/04/04 17:47:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighLowRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= HighLowClass object
		ds:di	= HighLowClass instance data
		es	= segment of HihLowClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HighLowRealize	method	dynamic	HighLowClass, 
					MSG_CHART_OBJECT_REALIZE
	uses	ax,cx,dx

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	call	SeriesCreateGString
	mov	di, locals.SDLV_gstate

	; Draw line from series 0 to series 1

	mov	dx, locals.SDLV_categoryNum
	clr	cl			; series 0
	call	SeriesGetDataPointPosition	; ax, bx
	jc	abort
	push	ax, bx
	inc	cl
	call	SeriesGetDataPointPosition
	pop	cx, dx
	jc	abort

	call	GrDrawLine

	; For series 2, draw a tick off to the left

	cmp	locals.SDLV_seriesCount, 2
	jle	setIt

	mov	cl, 2
	mov	dx, locals.SDLV_categoryNum
	call	SeriesGetDataPointPosition
	jc	setIt
	mov	cx, ax
	mov	dx, bx
	sub	ax, MARKER_STD_SIZE/2
	call	GrDrawLine

	; for series 3, draw a tick off to the right

	cmp	locals.SDLV_seriesCount, 3
	jle	setIt	
	mov	cl, 3

	mov	dx, locals.SDLV_categoryNum
	call	SeriesGetDataPointPosition
	jc	setIt
	mov	cx, ax
	mov	dx, bx
	add	ax, MARKER_STD_SIZE/2
	call	GrDrawLine
setIt:

	mov	cx, CODT_PICTURE
	call	ChartObjectDualGetGrObj

	call	SeriesSetGrObjGString

	mov	cx, CODT_PICTURE
	call	ChartObjectDualSetGrObj

done:
	inc	locals.SDLV_categoryNum
	.leave
	mov	di, offset HighLowClass
	GOTO	ObjCallSuperNoLock

abort:
	push	si
	clr	di				;di <- no GState
	mov	si, locals.SDLV_gstate
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString
	pop	si

	mov	cx, CODT_PICTURE
	call	ChartObjectDualClearGrObj

	jmp	done

HighLowRealize	endm

