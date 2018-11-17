COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesPie.asm

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
	

	$Id: seriesPie.asm,v 1.1 97/04/04 17:47:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PieRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	draw a wedge

PASS:		*ds:si	= PieClass object
		ds:di	= PieClass instance data
		es	= Segment of PieClass.

RETURN:		

DESTROYED:	ax,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PieRealize	method	dynamic	PieClass, 
					MSG_CHART_OBJECT_REALIZE
locals	local	SeriesDrawLocalVars


	uses	ax

	.enter	inherit 

	mov	di, offset PieClass
	call	ObjCallSuperNoLock

	;
	; Push the series Max value on the FP stack
	;

	push	ds, si
	segmov	ds, ss
	lea	si, locals.SDLV_typeSpecific.TSV_pie.PV_max
	call	FloatPushNumber		; FP: max
	pop	ds, si

	; Get current value

	mov	cl, locals.SDLV_seriesNum
	mov	dx, locals.SDLV_categoryNum
	push	dx

	;
	; Unfortunately, if the current value is an error value,
	; we need to search back for the most recent non-error
	; value and use that (this way, the current value will
	; be considered to be 0).
	;

getCurVal:
	mov	ax, MSG_CHART_GROUP_GET_VALUE
	call	UtilCallChartGroup	; FP: max cur
	jnc	floatOK
	dec	dx
	js	pushVal0
	jmp	getCurVal
pushVal0:
	call	Float0			; FP: max cur=0
floatOK:
	pop	dx			; current category number
	mov	bx, 2
	call	FloatPick
	call	FloatDivide		; FP: max cur/max

	; If category is zero, then previous value is zero, otherwise
	; previous value is value of category-1

startPrev:
	dec	dx
	js	pushZero

	mov	ax, MSG_CHART_GROUP_GET_VALUE
	call	UtilCallChartGroup
	jc	startPrev
	jmp	gotPrev

pushZero:
	call	Float0		; FP: max cur/max prev=0

gotPrev:
		
	call	FloatRot	; FP: cur/max prev max
	call	FloatDivide	; FP: cur/max prev/max

	;
	; Ignoring the slice when the current & previous values are
	; the same doesn't handle the case where the current slice
	; value has changed since the last chart draw.  In this case,
	; we need to redraw the slice (0) at the same angle as the
	; previous slice.
	;

if 0
	;
	; If the current value is the same as the previous value, then
	; just bail, 'cause the wedge won't be very interesting
	; anyway... 
	;
		
	call	FloatComp
	jne	notEqual
	call	FloatDrop
	jmp	floatDropExit
endif

notEqual:
	;
	; Take the average
	;

	call	FloatDup	; FP: cur/max prev/max prev/max
	mov	bx, 3
	call	FloatPick	; FP: c/m p/m p/m c/m
	call	FloatAdd
	call	FloatDivide2	; FP: c/m p/m avg
	mov	bx, 3
	call	FloatRollDown	; FP: avg c/m p/m

	call	getAngle
	mov	bx, ax			; prev angle

	call	getAngle		; ax - current angle

	sub	sp, size CreateArcParams
	mov	di, sp
	call	SeriesSetCreateGrObjParams

	mov	ss:[di].CAP_startAngle.WWF_int, ax
	clr	ss:[di].CAP_startAngle.WWF_frac
	mov	ss:[di].CAP_endAngle.WWF_int, bx
	clr	ss:[di].CAP_endAngle.WWF_frac

	call	getAngle		; ax - midpoint angle
	mov	PieLocals.PV_midAngle, ax

	;
	; calculate bounding box 
	;

	mov	ax, PieLocals.PV_radius
	movP	cxdx, PieLocals.PV_center
	sub	cx, ax
	sub	dx, ax
	movP	ss:[di].CGOP_position, cxdx
	shl	ax
	movP	ss:[di].CGOP_size, axax
	mov	PieLocals.PV_arcParams.AP_bottom, dx

	;
	; Check for exploded, etc
	;

	call	PieCheckExploded

	;
	; create the arc object
	;

	call	SeriesGetAreaAttributes
	
	mov	ss:[di].CGOP_areaColor, al
	mov	ss:[di].CGOP_areaMask, ah
	mov	ss:[di].CGOP_flags, mask CGOF_AREA_MASK or \
					mask CGOF_AREA_COLOR

	;
	; Set move/resize locks
	;

	mov	ss:[di].CGOP_locks, STANDARD_CHART_GROBJ_LOCKS

	mov	cx, CODT_PICTURE
	call	ChartObjectDualGetGrObj
	push	bp
	mov	bp, di
	call	ChartObjectCreateOrUpdateArc
	pop	bp
	call	ChartObjectDualSetGrObj

	add	sp, size CreateArcParams

	
	; See if want to draw values

	call	PieCheckToDrawValue

	; See if want to draw a label

	call	PieCheckToDrawLabel

done:

	inc	locals.SDLV_categoryNum

	.leave
	ret

if 0	; No longer used since we want to handle #error# values correctly
floatDropExit:
	call	FloatDrop
	jmp	done
endif

getAngle:
	;
	; Take the top number on the FP stack, multiply by 360, and
	; convert it to an angle in our proper coordinate system
	;

	push	ds, si
	segmov	ds, cs
	mov	si, offset float360
FXIP<	push	cx							>
FXIP<	mov	cx, size FloatNum		; cx = size of data	>
FXIP<	call	SysCopyToStackDSSI		; ds:si = floatNum on stack >
	call	FloatPushNumber
FXIP<	call	SysRemoveFromStack		; release stack space	>
FXIP<	pop	cx				; restore cx		>
	pop	ds, si

	call	FloatMultiply
	call	FloatFloatToDword
	call	ConvertAngle
	retn

PieRealize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PieCheckToDrawLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a label needs to be drawn for this series, and
		if so, draw it.

CALLED BY:

PASS:		ss:bp - SeriesDrawLocalVars 
		*ds:si - Pie object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	
	
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PieCheckToDrawLabel	proc near	
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	test	locals.SDLV_flags, mask CF_CATEGORY_TITLES
	jz	done

	call	ComputeTextPosition
	call	DualDrawSeriesOrCategoryTitle
done:
	.leave
	ret
PieCheckToDrawLabel	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeTextPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	figure out where to put the text

CALLED BY:	PieCheckToDrawLabel, PieCheckToDrawValue

PASS:		nothing 

RETURN:		ax, bx - position
		cl - TextAnchorType

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FUDGE_FACTOR = 1		; factor in some fudge...

ComputeTextPosition	proc near

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	mov	dx, PieLocals.PV_midAngle
	call	NormalizeAngle

	;
	; From the midpoint angle, determine the best anchor position
	;

	mov	cl, TAT_LEFT
	cmp	dx, 23
	jb	gotAnchor
	mov	cl, TAT_BOTTOM_LEFT
	cmp	dx, 68
	jb	gotAnchor
	mov	cl, TAT_BOTTOM
	cmp	dx, 113
	jb	gotAnchor
	mov	cl, TAT_BOTTOM_RIGHT
	cmp	dx, 158
	jb	gotAnchor
	mov	cl, TAT_RIGHT
	cmp	dx, 203
	jb	gotAnchor
	mov	cl, TAT_TOP_RIGHT
	cmp	dx, 248
	jb	gotAnchor
	mov	cl, TAT_TOP
	cmp	dx, 293
	jb	gotAnchor
	mov	cl, TAT_TOP_LEFT
	cmp	dx, 338
	jb	gotAnchor
	mov	cl, TAT_LEFT
gotAnchor:
	push	cx

	mov	bx, PieLocals.PV_radius
	add	bx, FUDGE_FACTOR
	clr	ax, cx
	call	GrPolarToCartesian		; dx, bx - coordinates
	
	pop	cx				; cl - TextAnchorType
	mov	ax, dx				; ax, bx - coords
	addP	axbx, PieLocals.PV_center

	.leave
	ret
ComputeTextPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NormalizeAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take an arbitrary signed angle, and turn it into one
		between 0 & 359 degrees

CALLED BY:	CalcEllipsePointWithAng

PASS:		dx	= Angle

RETURN:		dx	= Angle (normalized)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/10/91	Initial version
		chrisb	1/93		Copied here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NormalizeAngle	proc	near
		uses	di
		.enter
	
		; Ensure we are between 0 & 360. If not, get it there
		;
		mov	di, 360
		sub	dx, di
makeLarger:
		add	dx, di
		tst	dx
		jl	makeLarger
		add	dx, di
makeSmaller:
		sub	dx, di
		cmp	dx, di
		jge	makeSmaller

		.leave
		ret
NormalizeAngle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PieCheckToDrawValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if values want to be drawn on the pie chart

CALLED BY:	PieRealize

PASS:		ss:bp - SeriesDrawLocalVars 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PieCheckToDrawValue	proc near	

locals	local	SeriesDrawLocalVars
	.enter	inherit 

	test	locals.SDLV_flags, mask CF_VALUES
	jz	done

	call	ComputeTextPosition
	call	SeriesGetValueText

	push	ax, bx, cx
	mov	cx, CODT_TEXT
	call	ChartObjectDualGetGrObj
	pop	ax, bx, cx

	call	SeriesCreateOrUpdateText

	mov	cx, CODT_TEXT
	call	ChartObjectDualSetGrObj
done:
	.leave
	ret
PieCheckToDrawValue	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PieCheckExploded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the pie chart is exploded, and if so,
		if the current wedge should be moved out.

CALLED BY:	PieRealize

PASS:		ss:bp - SeriesDrawLocalVars 
		ss:di - CreateArcParams

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	if current wedge is to be exploded
		theta = angle at center of wedge
		r = constant (or percentage of rectangle size?
		translate bounding rectangle by (r,theta)


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PieCheckExploded	proc near	
	uses	ax,bx,cx,dx
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	; Check if current wedge is exploded.  If so, move the
	; bounding box according to the central angle of this wedge.

	mov	al, locals.SDLV_variation
	cmp	al, CPV_ALL_EXPLODED
	je	explodeThisWedge
	cmp	al, CPV_ONE_EXPLODED
	jne	done
	tst	locals.SDLV_categoryNum
	jnz	done

explodeThisWedge:
	mov	bx, PieLocals.PV_explode
	mov	dx, PieLocals.PV_midAngle
	clr	ax, cx
	call	GrPolarToCartesian
	
	addP	ss:[di].CGOP_position, dxbx
done:
	.leave
	ret
PieCheckExploded	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an angle from a Y-axis=0, clockwise system to
		an X-axis=0, counterclockwise

CALLED BY:	PieRealize

PASS:		ax - angle 

RETURN:		ax - converted angle

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	newAngle = 90 - oldAngle

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/23/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertAngle	proc near	
	.enter
	sub	ax, 90
	neg	ax

	.leave
	ret
ConvertAngle	endp

float360	FloatNum	<0,0,0,0xB400,<0,0x4007>>




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PieGetMaxTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Determine the largest bounds of the text objects for
		the pie chart

PASS:		*ds:si	- PieClass object
		ds:di	- PieClass instance data
		es	- segment of PieClass
		cx, dx 	- current max
		bp - 	series #

RETURN:		cx, dx, bp updated

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CALC_TEXT_BOUNDS_FUDGE_FACTOR equ 4

PieGetMaxTextBounds	method	dynamic	PieClass, 
					MSG_CHART_OBJECT_GET_MAX_TEXT_SIZE

categoryNum	local	word	push	bp
currentMax	local	Point	push	dx, cx

	.enter

	sub	sp, CHART_TEXT_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss

	call	UtilGetChartAttributes
	test	dx, mask CF_CATEGORY_TITLES
	jz	notCategoryTitles

	mov	cx, ss:[categoryNum]
	push	bp
	mov	dx, ss
	mov	bp, di
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_TITLE
	call	UtilCallChartGroup
	pop	bp
	jmp	calc


notCategoryTitles:
	test	dx, mask CF_VALUES
	jz	nothing

	push	bp			; stack frame
	mov	cx, dx			; flags
	mov	dx, ss:[categoryNum]
	mov	bp, cx			; flags
	clr	cl
	call	SeriesGetValueTextCommon
	pop	bp

calc:

	;
	; If there's really no text there, then just return zero (XXX:
	; Maybe UtilGetTextSize should do this).
	;

	cmp	{byte} es:[di], 0
	je	nothing

	call	UtilGetTextSize		; cx, dx - width, height
	add	cx, CALC_TEXT_BOUNDS_FUDGE_FACTOR
	add	dx, CALC_TEXT_BOUNDS_FUDGE_FACTOR
	Max	cx, ss:[currentMax].P_x
	Max	dx, ss:[currentMax].P_y
done:

	add	sp, CHART_TEXT_BUFFER_SIZE
	.leave

	inc	bp
	ret


nothing:
	clr	cx, dx
	jmp	done

PieGetMaxTextBounds	endm


