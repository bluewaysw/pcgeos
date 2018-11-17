COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Chart Library
FILE:		seriesSpider.asm

AUTHOR:		Vijay Menon, Aug  5, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/ 5/93   	Initial revision


DESCRIPTION:
	SpiderClass
		

	$Id: seriesSpider.asm,v 1.1 97/04/04 17:47:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpiderRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Realize a series of data

CALLED BY:	MSG_CHART_OBJECT_REALIZE
PASS:		*ds:si	= SpiderClass object
		ds:di	= SpiderClass instance data
		ds:bx	= SpiderClass object (same as *ds:si)
		es 	= segment of SpiderClass
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/ 5/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpiderRealize	method	dynamic	SpiderClass, 
					MSG_CHART_OBJECT_REALIZE
	uses	ax,cx,dx

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	cl, locals.SDLV_seriesNum

	mov	ax, offset SetPointInDataBlock
	mov	locals.SDLV_callback, ax

	clr	locals.SDLV_pointer
	clr	locals.SDLV_numPoints

	; Compute the point for each category.
	call	SeriesDrawEachCategory
	
	; Add the first point again on the end, so a line is drawn
	; from the last point to the first point.
	push	si
	mov	cl, locals.SDLV_seriesNum
	clr	ch
	clr	dx
	mov	si, locals.SDLV_valueAxis
	mov	ax, MSG_AXIS_GET_VALUE_POSITION
	call	ObjCallInstanceNoLock
	pop	si

	mov	bx, ax
	mov	ax, cx
	call	SetPointCommon

	call	LineOrScatterCreateOrUpdatePolyline

	inc	locals.SDLV_seriesNum

	.leave
	mov	di, offset SpiderClass
	GOTO	ObjCallSuperNoLock
SpiderRealize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpiderGetMaxTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the largest bounds of the text objects for
		the Spider chart

CALLED BY:	MSG_CHART_OBJECT_GET_MAX_TEXT_SIZE
PASS:		*ds:si	= SpiderClass object
		ds:di	= SpiderClass instance data
		ds:bx	= SpiderClass object (same as *ds:si)
		es 	= segment of SpiderClass
		ax	= message #
		cx, dx  = current max
		bp	= series #

RETURN:		cx, dx, bp updated
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	8/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CALC_TEXT_BOUNDS_FUDGE_FACTOR equ 4

SpiderGetMaxTextBounds	method	dynamic	SpiderClass, 
					MSG_CHART_OBJECT_GET_MAX_TEXT_SIZE

currentMax	local	Point	push	dx, cx

	.enter

	sub	sp, CHART_TEXT_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss

	call	UtilGetChartAttributes
	test	dx, mask CF_CATEGORY_TITLES
	jz	nothing

	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	UtilCallChartGroup
	dec	cx
	
	; Loop through each category to find the maximum height and
	; width of any text.
categoryLoop:
	push	cx
	push	bp
	mov	dx, ss
	mov	bp, di
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_TITLE
	call	UtilCallChartGroup
	pop	bp

	;
	; If there's really no text there, then just return zero (XXX:
	; Maybe UtilGetTextSize should do this).
	;

	cmp	{char} es:[di], 0
	je	continue

	call	UtilGetTextSize		; cx, dx - width, height
	add	cx, CALC_TEXT_BOUNDS_FUDGE_FACTOR
	add	dx, CALC_TEXT_BOUNDS_FUDGE_FACTOR
	Max	ss:[currentMax].P_x, cx
	Max	ss:[currentMax].P_y, dx

continue:
	pop	cx
	dec	cx
	jns	categoryLoop

	mov	cx, ss:[currentMax].P_x
	mov	dx, ss:[currentMax].P_y
	
done:

	add	sp, CHART_TEXT_BUFFER_SIZE
	.leave

	ret


nothing:
	clr	cx, dx
	jmp	done

SpiderGetMaxTextBounds	endm
