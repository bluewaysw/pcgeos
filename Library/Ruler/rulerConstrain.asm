COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Ruler Library
FILE:		rulerConstrain.asm

AUTHOR:		Jon Witort, 14 October 1991

ROUTINES:
	Name				Description
	----				-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	14 Oct 1991	Initial revision

DESCRIPTION:
	Constrain-related methods for VisRuler class.

	$Id: rulerConstrain.asm,v 1.1 97/04/07 10:42:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerGridGuideConstrainCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerSetConstrainTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SET_CONSTRAIN_TRANSFORM

  MSG_VIS_RULER_SET_CONSTRAIN_TRANSFORM is sent to the ruler so that it can
  properly constrain mouse events when the events are taken as happening
  within some transformed coordinate system (eg. a rotated/skewed GrObj)

Called by:	MSG_VIS_RULER_SET_CONSTRAIN_TRANSFORM

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

		ss:[bp] - TMatrix

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  5, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetConstrainTransform	method dynamic	VisRulerClass,
				MSG_VIS_RULER_SET_CONSTRAIN_TRANSFORM
	.enter

	;
	;	Allocate a gstate to hold the transform if none exists
	;
	mov	si, di					;ds:si <- instance
	mov	di, ds:[di].VRI_transformGState
	tst	di
	jnz	haveGState

	call	GrCreateState

	mov	ds:[si].VRI_transformGState, di		;store the new gstate

	;
	;	Copy the passed transform into our transform gstate
	;
haveGState:
	segmov	ds,ss
	mov	si, bp
	call	GrSetTransform

	.leave
	ret
VisRulerSetConstrainTransform	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerClearConstrainTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_CLEAR_CONSTRAIN_TRANSFORM

  MSG_VIS_RULER_CLEAR_CONSTRAIN_TRANSFORM is sent to the ruler so that it can
  properly constrain mouse events when the events are taken as happening
  within some untransformed coordinate system.

Called by:	MSG_VIS_RULER_CLEAR_CONSTRAIN_TRANSFORM

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  5, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerClearConstrainTransform	method dynamic	VisRulerClass,
				MSG_VIS_RULER_CLEAR_CONSTRAIN_TRANSFORM
	.enter

	;
	;	Destory our gstate, if any
	;
	mov	di, ds:[di].VRI_transformGState
	tst	di
	jz	done

	call	GrDestroyState

done:
	.leave
	ret
VisRulerClearConstrainTransform	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSetVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SET_VECTOR

Context:	

Source:		

Destination:	

Pass:		ss:bp = PointDWFixed. The passed point and the reference
				point define the vector.

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 29, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetVector	method	dynamic	VisRulerClass, MSG_VIS_RULER_SET_VECTOR
	uses	cx, dx
	.enter
	;
	;	This method will barf if the passed point is more
	;	than 2^16 points away from the reference.
	;
	mov	cx, ss:[bp].PDF_y.DWF_frac
	sub	cx, ds:[di].VRI_reference.PDF_y.DWF_frac
	mov	dx, ss:[bp].PDF_y.DWF_int.low
	sbb	dx, ds:[di].VRI_reference.PDF_y.DWF_int.low
	
	mov	ax, ss:[bp].PDF_x.DWF_frac
	sub	ax, ds:[di].VRI_reference.PDF_x.DWF_frac
	mov	bx, ss:[bp].PDF_x.DWF_int.low
	sbb	bx, ds:[di].VRI_reference.PDF_x.DWF_int.low

	call	GrSDivWWFixed
	jc	straightUpAndDown

gotSlope:
	mov	ds:[di].VRI_vectorSlope.WWF_int, dx
	mov	ds:[di].VRI_vectorSlope.WWF_frac, cx
	.leave
	ret

straightUpAndDown:

	;
	;  We want to set the slope to a huge value, leaving room
	;  enough for the graphics system to not blow up. For example,
	;  I initially had set dx = 0x7fff, but as soon as it did any
	;  math with that, it puked. I'm gonna try 0x3fff for now... -jon
	;

	mov	dx, 0x3fff
	jmp	gotSlope
VisRulerSetVector	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerRuleLargePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_RULE_LARGE_PTR

Pass:		*ds:si = ds:di = VisRuler instance
		ss:bp - PointDWFixed

		cx - VisRulerConstrainStrategy

Return:		ss:bp - ruled PointDWFixed

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerRuleLargePtr	method	dynamic	VisRulerClass,
			MSG_VIS_RULER_RULE_LARGE_PTR

	uses	cx

	.enter

CheckHack <(mask VRCS_OVERRIDE) eq 0x8000>
	tst	cx
	js	processStrategy

	mov	cx, ds:[di].VRI_constrainStrategy

processStrategy:
	call	ProcessConstrainStrategy

	test	cx, VRCS_SNAP_FLAGS
	jz	checkConstrain

	test	cx, mask VRCS_SNAP_TO_GUIDES_X
	jz	checkGridX

	mov	ax, MSG_VIS_RULER_SNAP_TO_GUIDES_X
	call	ObjCallInstanceNoLock
	jc	checkGuidesY

checkGridX:
	test	cx, mask VRCS_SNAP_TO_GRID_X_ABSOLUTE
	jz	checkRelativeX

	mov	ax, MSG_VIS_RULER_SNAP_TO_GRID_X
	call	ObjCallInstanceNoLock
	jmp	checkGuidesY

checkRelativeX:
	test	cx, mask VRCS_SNAP_TO_GRID_X_RELATIVE
	jz	checkGuidesY

	mov	ax, MSG_VIS_RULER_SNAP_RELATIVE_TO_REFERENCE_X
	call	ObjCallInstanceNoLock

checkGuidesY:
	test	cx, mask VRCS_SNAP_TO_GUIDES_Y
	jz	checkGridY

	mov	ax, MSG_VIS_RULER_SNAP_TO_GUIDES_Y
	call	ObjCallInstanceNoLock
	jc	checkConstrain

checkGridY:
	test	cx, mask VRCS_SNAP_TO_GRID_Y_ABSOLUTE
	jz	checkRelativeY

	mov	ax, MSG_VIS_RULER_SNAP_TO_GRID_Y
	call	ObjCallInstanceNoLock
	jmp	checkConstrain

checkRelativeY:
	test	cx, mask VRCS_SNAP_TO_GRID_Y_RELATIVE
	jz	checkConstrain

	mov	ax, MSG_VIS_RULER_SNAP_RELATIVE_TO_REFERENCE_Y
	call	ObjCallInstanceNoLock

checkConstrain:
	test	cx, VRCS_CONSTRAIN_FLAGS
	jz	checkShowMouse

	call	VisRulerCheckAxialConstraint
	jc	checkShowMouse

	call	VisRulerCheckDiagonalConstraint
	jc	checkShowMouse
				   
	call	VisRulerCheckVectorConstraint

checkShowMouse:

	mov	ax, MSG_VIS_RULER_DRAW_MOUSE_TICK
	call	ObjCallInstanceNoLock

	test	cx, mask VRCS_SET_REFERENCE
	jz	done

	mov	ax, MSG_VIS_RULER_SET_REFERENCE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
VisRulerRuleLargePtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ProcessConstrainStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisRuler
		ss:[bp] - PointDWFixed
		cx = VisRulerConstrainStrategy

Return:		"orthogonal" VisRulerConstrainStrategy

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessConstrainStrategy	proc	near
	.enter

	;
	;	See if the constrain strategy has the vector constrain
	;	bit set
	;
	test	cx, VRCS_VECTOR_CONSTRAIN
	jz	checkAxes

	;
	;	See if we want the X or Y component of the passed point
	;	when constraining to the vector.
	;
	call	XorYVector
	jnc	vectorX				;carry set if x in use

	;
	;	Since the X component will be set by constraining, we want
	;	to disable grids/guides on the X component.
	;
	andnf	cx, not (mask VRCS_INTERNAL or \
			mask VRCS_SNAP_TO_GRID_X_ABSOLUTE or \
			mask VRCS_SNAP_TO_GRID_X_RELATIVE or \
			mask VRCS_SNAP_TO_GUIDES_X or \
			VRCS_CONSTRAIN_TO_HV_AXES or \
			VRCS_CONSTRAIN_TO_DIAGONALS)

	jmp	checkActualOrReflection
	

vectorX:
	ornf	cx, mask VRCS_INTERNAL

	;
	;	Since the Y component will be set by constraining, we want
	;	to disable grids/guides on the Y component.
	;
	andnf	cx, not (mask VRCS_SNAP_TO_GRID_Y_ABSOLUTE or \
			mask VRCS_SNAP_TO_GRID_Y_RELATIVE or \
			mask VRCS_SNAP_TO_GUIDES_Y or \
			VRCS_CONSTRAIN_TO_HV_AXES or \
			VRCS_CONSTRAIN_TO_DIAGONALS)

checkActualOrReflection:
	;
	;	See if we want the actual vector or the reflected vector
	;
	test	cl, VRCS_CONSTRAIN_FLAGS
	jpo	done				;if only one set, no problem

	call	ActualOrReflectedVector
	jc	reflected

	andnf	cx, not mask VRCS_CONSTRAIN_TO_VECTOR_REFLECTION
	jmp	done

reflected:
	andnf	cx, not mask VRCS_CONSTRAIN_TO_VECTOR

done:
	.leave
	ret

checkAxes:
	test	cx, VRCS_CONSTRAIN_TO_HV_AXES or VRCS_CONSTRAIN_TO_DIAGONALS
	jz	done

	mov	dx, 0xffff
	test	cx, mask VRCS_CONSTRAIN_TO_HORIZONTAL_AXIS
	jz	checkVertDistance

	call	RulerGetApproximateDistanceToHorizontalAxis
	mov_tr	dx, ax

checkVertDistance:
	test	cx, mask VRCS_CONSTRAIN_TO_VERTICAL_AXIS
	jz	checkUnityDistance

	andnf	cx, not mask VRCS_CONSTRAIN_TO_VERTICAL_AXIS

	call	RulerGetApproximateDistanceToVerticalAxis
	cmp	ax, dx
	jae	checkUnityDistance

	andnf	cx, not mask VRCS_CONSTRAIN_TO_HORIZONTAL_AXIS
	ornf	cx, mask VRCS_CONSTRAIN_TO_VERTICAL_AXIS

	mov_tr	dx, ax

checkUnityDistance:
	test	cx, mask VRCS_CONSTRAIN_TO_UNITY_SLOPE_AXIS
	jz	checkNegativeUnityDistance

	andnf	cx, not mask VRCS_CONSTRAIN_TO_UNITY_SLOPE_AXIS

	call	RulerGetApproximateDistanceToUnityAxis
	cmp	ax, dx
	jae	checkNegativeUnityDistance

	andnf	cx, not (mask VRCS_CONSTRAIN_TO_HORIZONTAL_AXIS or \
			mask VRCS_CONSTRAIN_TO_VERTICAL_AXIS)
	ornf	cx, mask VRCS_CONSTRAIN_TO_UNITY_SLOPE_AXIS

	mov_tr	dx, ax

checkNegativeUnityDistance:
	test	cx, mask VRCS_CONSTRAIN_TO_NEGATIVE_UNITY_SLOPE_AXIS
	jz	setInternal

	andnf	cx, not mask VRCS_CONSTRAIN_TO_NEGATIVE_UNITY_SLOPE_AXIS

	call	RulerGetApproximateDistanceToNegativeUnityAxis
	cmp	ax, dx
	jae	setInternal

	andnf	cx, not (mask VRCS_CONSTRAIN_TO_HORIZONTAL_AXIS or \
			mask VRCS_CONSTRAIN_TO_VERTICAL_AXIS or \
			mask VRCS_CONSTRAIN_TO_UNITY_SLOPE_AXIS)
	ornf	cx, mask VRCS_CONSTRAIN_TO_NEGATIVE_UNITY_SLOPE_AXIS

	mov_tr	dx, ax

setInternal:
	;
	;	At this point, 1 (and only 1) of the 4 constrain bits
	;	should be set. We'll figure out if the x or y coordinate
	;	is relevant, and disable grids on the other one, since
	;	it will be constrained anyway.
	;

	test	cx, mask VRCS_CONSTRAIN_TO_HORIZONTAL_AXIS
	jz	checkVert

	;
	;	We're constraining horizontally, so disable y grids
	;
	andnf	cx, not (mask VRCS_SNAP_TO_GRID_Y_ABSOLUTE or \
			mask VRCS_SNAP_TO_GRID_Y_RELATIVE or \
			mask VRCS_SNAP_TO_GUIDES_Y)
	jmp	done

checkVert:
	test	cx, mask VRCS_CONSTRAIN_TO_VERTICAL_AXIS
	jz	checkDiags

	;
	;	We're constraining vertically, so disable x grids
	;
	andnf	cx, not (mask VRCS_SNAP_TO_GRID_X_ABSOLUTE or \
			mask VRCS_SNAP_TO_GRID_X_RELATIVE or \
			mask VRCS_SNAP_TO_GUIDES_X)
	jmp	done

checkDiags:
	;
	;	O.K., we're constraining to one of the slope = 1,-1 axes,
	;	so we want to figure out whether we'll be using the x
	;	or y coord.
	;
	call	XorYDiags
	jc	yDiags

	BitSet	cx, VRCS_INTERNAL
	andnf	cx, not (mask VRCS_SNAP_TO_GRID_Y_ABSOLUTE or \
			mask VRCS_SNAP_TO_GRID_Y_RELATIVE or \
			mask VRCS_SNAP_TO_GUIDES_Y)
	jmp	done

yDiags:
	BitClr	cx, VRCS_INTERNAL
	andnf	cx, not (mask VRCS_SNAP_TO_GRID_X_ABSOLUTE or \
			mask VRCS_SNAP_TO_GRID_X_RELATIVE or \
			mask VRCS_SNAP_TO_GUIDES_X)
	jmp	done

ProcessConstrainStrategy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerGetApproximateDistanceToHorizontalAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns an integer approximation of the horizontal distance
		between the passed point and the VisRuler's reference point.

Pass:		ds:[di] - VisRuler instance
		ss:[bp] - PointDWFixed

Return:		ax - distance

Destroyed:	nothing

Comments:	Won't work for distances > 32767

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerGetApproximateDistanceToHorizontalAxis	proc	near
	uses	bx
	class	VisRulerClass
	.enter

	mov	bx, ds:[di].VRI_reference.PDF_y.DWF_frac
	sub	bx, ss:[bp].PDF_y.DWF_frac

	mov	ax, ds:[di].VRI_reference.PDF_y.DWF_int.low
	sbb	ax, ss:[bp].PDF_y.DWF_int.low

	tst	bx
	jns	checkIntSign
	inc	ax

checkIntSign:
	tst	ax
	jns	done

	neg	ax
done:
	.leave
	ret
RulerGetApproximateDistanceToHorizontalAxis	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerGetApproximateDistanceToVerticalAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns an integer approximation of the vertical distance
		between the passed point and the VisRuler's reference point.

Pass:		ds:[di] - VisRuler instance
		ss:[bp] - PointDWFixed

Return:		ax - distance

Destroyed:	nothing

Comments:	Won't work for distances > 32767

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerGetApproximateDistanceToVerticalAxis	proc	near
	uses	bx
	class	VisRulerClass
	.enter

	mov	bx, ds:[di].VRI_reference.PDF_x.DWF_frac
	sub	bx, ss:[bp].PDF_x.DWF_frac

	mov	ax, ds:[di].VRI_reference.PDF_x.DWF_int.low
	sbb	ax, ss:[bp].PDF_x.DWF_int.low

	tst	bx
	jns	checkIntSign
	inc	ax

checkIntSign:
	tst	ax
	jns	done

	neg	ax
done:
	.leave
	ret
RulerGetApproximateDistanceToVerticalAxis	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerGetApproximateDistanceToUnityAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns an integer approximation of the distance
		between the passed point and the line with slope = 1 passing
		through the VisRuler's reference point.

Pass:		ds:[di] - VisRuler instance
		ss:[bp] - PointDWFixed

Return:		ax - distance

Destroyed:	nothing

Comments:	Won't work for distances > 32767

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerGetApproximateDistanceToUnityAxis	proc	near
	uses	bx, cx, dx
	class	VisRulerClass
	.enter

	mov	bx, ds:[di].VRI_reference.PDF_x.DWF_frac
	sub	bx, ss:[bp].PDF_x.DWF_frac

	mov	ax, ds:[di].VRI_reference.PDF_x.DWF_int.low
	sbb	ax, ss:[bp].PDF_x.DWF_int.low

	mov	cx, ds:[di].VRI_reference.PDF_y.DWF_frac
	sub	cx, ss:[bp].PDF_y.DWF_frac

	mov	dx, ds:[di].VRI_reference.PDF_y.DWF_int.low
	sbb	dx, ss:[bp].PDF_y.DWF_int.low

	sub	bx, cx
	sbb	ax, dx

	tst	bx
	jns	checkIntSign
	inc	ax

checkIntSign:
	tst	ax
	jns	scaleByHalfRoot2

	neg	ax
scaleByHalfRoot2:

	clr	dx
	mov	cx, HALF_ROOT_2
	mul	cx
	mov_tr	ax, dx
	.leave
	ret
RulerGetApproximateDistanceToUnityAxis	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerGetApproximateDistanceToNegativeUnityAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns an integer approximation of the distance
		between the passed point and the line with slope = -1 passing
		through the VisRuler's reference point.

Pass:		ds:[di] - VisRuler instance
		ss:[bp] - PointDWFixed

Return:		ax - distance

Destroyed:	nothing

Comments:	Won't work for distances > 32767

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerGetApproximateDistanceToNegativeUnityAxis	proc	near
	uses	bx, cx, dx
	class	VisRulerClass
	.enter

	mov	bx, ds:[di].VRI_reference.PDF_x.DWF_frac
	sub	bx, ss:[bp].PDF_x.DWF_frac

	mov	ax, ds:[di].VRI_reference.PDF_x.DWF_int.low
	sbb	ax, ss:[bp].PDF_x.DWF_int.low

	mov	cx, ds:[di].VRI_reference.PDF_y.DWF_frac
	sub	cx, ss:[bp].PDF_y.DWF_frac

	mov	dx, ds:[di].VRI_reference.PDF_y.DWF_int.low
	sbb	dx, ss:[bp].PDF_y.DWF_int.low

	add	bx, cx
	adc	ax, dx

	tst	bx
	jns	checkIntSign
	inc	ax

checkIntSign:
	tst	ax
	jns	scaleByHalfRoot2

	neg	ax
scaleByHalfRoot2:

	clr	dx
	mov	cx, HALF_ROOT_2
	mul	cx
	mov_tr	ax, dx
	.leave
	ret
RulerGetApproximateDistanceToNegativeUnityAxis	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			XorYDiags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns carry set if passed point is further vertically
		than horizontally from the VisRuler's reference point

Pass:		ds:[di] - VisRuler instance
		ss:[bp] - PointDWFixed

Return:		carry set if horizontal distance < vertical distance

Destroyed:	nothing

Comments:	Won't work for distances > 32767	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XorYDiags	proc	near
	class	VisRulerClass
	uses	ax, bx, cx, dx
	.enter

	;
	;	bxax <- abs(horizontal distance)
	;
	mov	ax, ds:[di].VRI_reference.PDF_x.DWF_frac
	sub	ax, ss:[bp].PDF_x.DWF_frac

	mov	bx, ds:[di].VRI_reference.PDF_x.DWF_int.low
	sbb	bx, ss:[bp].PDF_x.DWF_int.low
	jns	getY

	negwwf	bxax

getY:
	;
	;	dxcx <- abs(vertical distance)
	;
	mov	cx, ds:[di].VRI_reference.PDF_y.DWF_frac
	sub	cx, ss:[bp].PDF_y.DWF_frac

	mov	dx, ds:[di].VRI_reference.PDF_y.DWF_int.low
	sbb	dx, ss:[bp].PDF_y.DWF_int.low
	jns	compare

	negwwf	dxcx

compare:
	cmp	bx, dx			;carry set if bx<dx, clear if bx>dx
	jne	done
	cmp	ax, cx			;carry set if ax<cx, clear if ax>=cx
done:
	.leave
	ret
XorYDiags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			XorYVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns carry set if passed point is further vertically
		than horizontally from the VisRuler's reference point

Pass:		*ds:si - VisRuler object
		ds:[di] - VisRuler instance
		ss:[bp] - PointDWFixed

Return:		carry set if horizontal distance < vertical distance

Destroyed:	nothing

Comments:	Won't work for distances > 32767	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XorYVector	proc	near
	class	VisRulerClass
	uses	ax, bx, cx, dx
	.enter

	;
	;  Untransform the points and the vector. If there's an overflow
	;  in the vector calculation, then we're BASICALLY_VERTICAL
	;

	call	VisRulerUntransformPointsAndVector
	jc	retransform

	;
	;	If the slope is too flat or too vertical, we want to
	;	return a value that will keep use from blowing up
	;

	movwwf	dxcx, ds:[di].VRI_vectorSlope

	tst	dx
	jns	haveSlope
	negwwf	dxcx

haveSlope:
	tst	dx
	jnz	checkVertical

	cmp	cx, BASICALLY_FLAT
	ja	nonTrivial

	;
	;	The slope is really flat, so clear the carry to indicate
	;	that the ruler should map the vertical portion of the passed
	;	point.
	;

	clc
	jmp	retransform

checkVertical:

	cmp	dx, BASICALLY_VERTICAL
	jb	nonTrivial

	;
	;	The slope is really steep, so set the carry to indicate
	;	that the ruler should map the horizontal portion of the passed
	;	point.
	;

	stc
	jmp	retransform

nonTrivial:

	;
	;	dxcx <- abs(horizontal distance * slope)
	; 
	mov	ax, ds:[di].VRI_reference.PDF_x.DWF_frac
	sub	ax, ss:[bp].PDF_x.DWF_frac

	mov	bx, ds:[di].VRI_reference.PDF_x.DWF_int.low
	sbb	bx, ss:[bp].PDF_x.DWF_int.low

	call	GrMulWWFixed

	tst	dx
	jns	getY
	negwwf	dxcx

getY:
	;
	;	bxax <- abs(vertical distance)
	;
	mov	ax, ds:[di].VRI_reference.PDF_y.DWF_frac
	sub	ax, ss:[bp].PDF_y.DWF_frac

	mov	bx, ds:[di].VRI_reference.PDF_y.DWF_int.low
	sbb	bx, ss:[bp].PDF_y.DWF_int.low
	jns	compare

	negwwf	bxax

compare:

	cmp	dx, bx			;carry set if dx<bx, clear if dx>bx
	jne	retransform
	cmp	cx, ax			;carry set if cx<ax, clear if cx>=ax
retransform:
	pushf				;save result
	call	VisRulerTransformPointsAndVector
	popf				;carry <- result

	.leave
	ret
XorYVector	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerUntransformPointsAndVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Untransforms the passed point, the VisRuler's reference
		point, and the VisRuler's vectorSlope through the ruler's
		transform gstate, if any

Pass:		*ds:si - VisRuler object
		ss:[bp] - PointDWFixed

Return:		carry set if overflow during vector calculation

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  5, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerUntransformPointsAndVector	proc	near
	class	VisRulerClass
	uses	si, di, es, dx, bx, ax, cx
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset
	mov	di, ds:[si].VRI_transformGState
	tst	di
	jz	done

	;
	;	Untransform the passed point
	;
	segmov	es, ss
	mov	dx, bp
	call	GrUntransformDWFixed

	;
	;	Untransform the reference point
	;
	segmov	es, ds
	lea	dx, ds:[si].VRI_reference
	call	GrUntransformDWFixed

	;
	;	Untransform the vector
	;
	movwwf	bxax, ds:[si].VRI_vectorSlope
	mov	dx, 1
	clr	cx
	call	GrUntransformWWFixed
	jc	done

	xchg	dx, bx
	xchg	cx, ax

	call	GrSDivWWFixed
	jc	done

	movwwf	ds:[si].VRI_vectorSlope, dxcx
	clc

done:
	.leave
	ret
VisRulerUntransformPointsAndVector	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerTransformPointsAndVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Transforms the passed point, the VisRuler's reference
		point, and the VisRuler's vectorSlope through the ruler's
		transform gstate, if any

Pass:		*ds:si - VisRuler object
		ss:[bp] - PointDWFixed

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  5, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerTransformPointsAndVector	proc	near
	class	VisRulerClass
	uses	si, di, es, dx, bx, ax, cx
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset
	mov	di, ds:[si].VRI_transformGState
	tst	di
	jz	done

	;
	;	Transform the passed point
	;
	segmov	es, ss
	mov	dx, bp
	call	GrTransformDWFixed

	;
	;	Transform the reference point
	;
	segmov	es, ds
	lea	dx, ds:[si].VRI_reference
	call	GrTransformDWFixed

	;
	;	Transform the vector
	;
	movwwf	bxax, ds:[si].VRI_vectorSlope
	mov	dx, 1
	clr	cx
	call	GrTransformWWFixed

	xchg	dx, bx
	xchg	cx, ax

	call	GrSDivWWFixed
	movwwf	ds:[si].VRI_vectorSlope, dxcx

done:
	.leave
	ret
VisRulerTransformPointsAndVector	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ActualOrReflectedVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns carry set if passed point is further vertically
		than horizontally from the VisRuler's reference point

Pass:		*ds:si - VisRuler object
		ds:[di] - VisRuler instance
		ss:[bp] - PointDWFixed

Return:		carry set if reflected

Destroyed:	nothing

Comments:	Won't work for distances > 32767	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ActualOrReflectedVector	proc	near
	class	VisRulerClass
	uses	ax, bx, cx, dx
	.enter

	call	VisRulerUntransformPointsAndVector

	;
	;	bxax <- horizontal distance
	;
	mov	ax, ss:[bp].PDF_x.DWF_frac
	sub	ax, ds:[di].VRI_reference.PDF_x.DWF_frac

	mov	bx, ss:[bp].PDF_x.DWF_int.low
	sbb	bx, ds:[di].VRI_reference.PDF_x.DWF_int.low

	;
	;	dxcx <- vertical distance
	;
	mov	cx, ss:[bp].PDF_y.DWF_frac
	sub	cx, ds:[di].VRI_reference.PDF_y.DWF_frac

	mov	dx, ss:[bp].PDF_y.DWF_int.low
	sbb	dx, ds:[di].VRI_reference.PDF_y.DWF_int.low

	;
	;	Check for opposite signs
	;
	xor	dx, bx
	xor	dx, ds:[di].VRI_vectorSlope.WWF_int
	jns	retransform			;if actual, carry already clr

	;
	;	reflected
	;
	stc

retransform:
	pushf					;save result
	call	VisRulerTransformPointsAndVector
	popf					;carry <- result
	
	.leave
	ret
ActualOrReflectedVector	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerConstrainToAxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_CONSTRAIN_TO_DIAGONALS

Called by:	

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance
		ss:[bp] = PointDWFixed to constrain
		dx = size PointDWFixed

Return:		ss:[bp] = Diagonally constrained PointDWFixed

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerConstrainToAxes	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_TO_AXES
	uses	cx
	.enter
	mov	cx, VRCS_CONSTRAIN_TO_HV_AXES
	call	ProcessConstrainStrategy
	call	VisRulerCheckAxialConstraint
	.leave
	ret
VisRulerConstrainToAxes	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerCheckAxialConstraint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si = VisRuler object
		cx = VisRulerConstrainStrategy
		ss:bp = PointDWFixed

Return:		carry set if constrained

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerCheckAxialConstraint	proc	near
	class	VisRulerClass
	uses	ax
	.enter
	mov	ax, MSG_VIS_RULER_CONSTRAIN_TO_HORIZONTAL_AXIS
	test	cx, mask VRCS_CONSTRAIN_TO_HORIZONTAL_AXIS
	jnz	constrain
	test	cx, mask VRCS_CONSTRAIN_TO_VERTICAL_AXIS
	jz	done
	mov	ax, MSG_VIS_RULER_CONSTRAIN_TO_VERTICAL_AXIS
constrain:
	call	ObjCallInstanceNoLock
	stc
done:
	.leave
	ret
VisRulerCheckAxialConstraint	endp

VisRulerConstrainToHorizontalAxis	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_TO_HORIZONTAL_AXIS
	.enter

	movdwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_y, ax

	.leave
	ret
VisRulerConstrainToHorizontalAxis	endm

VisRulerConstrainToVerticalAxis	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_TO_VERTICAL_AXIS
	.enter

	movdwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_x, ax

	.leave
	ret
VisRulerConstrainToVerticalAxis		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerConstrainToDiagonals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_CONSTRAIN_TO_DIAGONALS

Called by:	

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance
		ss:[bp] = PointDWFixed to constrain
		dx = size PointDWFixed

Return:		ss:[bp] = Diagonally constrained PointDWFixed

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerConstrainToDiagonals	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_TO_DIAGONALS
	uses	cx
	.enter
	mov	cx, VRCS_CONSTRAIN_TO_DIAGONALS
	call	ProcessConstrainStrategy
	call	VisRulerCheckDiagonalConstraint
	.leave
	ret
VisRulerConstrainToDiagonals	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerCheckDiagonalConstraint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si = VisRuler object
		cx = VisRulerConstrainStrategy
		ss:bp = PointDWFixed

Return:		carry set if constrained

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerCheckDiagonalConstraint	proc	near
	class	VisRulerClass
	uses	ax

	.enter

	test	cx, mask VRCS_CONSTRAIN_TO_UNITY_SLOPE_AXIS
	jz	checkNegativeUnityConstrain

	mov	ax, MSG_VIS_RULER_CONSTRAIN_X_TO_UNITY_SLOPE_AXIS
	test	cx, mask VRCS_INTERNAL
	jz	doUnity
	mov	ax, MSG_VIS_RULER_CONSTRAIN_Y_TO_UNITY_SLOPE_AXIS
doUnity:
	call	ObjCallInstanceNoLock
	jmp	stcDone

checkNegativeUnityConstrain:
	test	cx, mask VRCS_CONSTRAIN_TO_NEGATIVE_UNITY_SLOPE_AXIS
	jz	done					;carry clear from test

	mov	ax, MSG_VIS_RULER_CONSTRAIN_X_TO_NEGATIVE_UNITY_SLOPE_AXIS
	test	cx, mask VRCS_INTERNAL
	jz	doNegativeUnity
	mov	ax, MSG_VIS_RULER_CONSTRAIN_Y_TO_NEGATIVE_UNITY_SLOPE_AXIS
doNegativeUnity:
	call	ObjCallInstanceNoLock
stcDone:
	stc
done:
	.leave
	ret
VisRulerCheckDiagonalConstraint	endp

VisRulerConstrainXToUnitySlopeAxis	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_X_TO_UNITY_SLOPE_AXIS
	.enter

	movdwf	ss:[bp].PDF_x, ss:[bp].PDF_y, ax
	subdwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_y, ax
	adddwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_x, ax

	.leave
	ret
VisRulerConstrainXToUnitySlopeAxis	endm

VisRulerConstrainYToUnitySlopeAxis	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_Y_TO_UNITY_SLOPE_AXIS
	.enter

	movdwf	ss:[bp].PDF_y, ss:[bp].PDF_x, ax
	subdwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_x, ax
	adddwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_y, ax

	.leave
	ret
VisRulerConstrainYToUnitySlopeAxis	endm

VisRulerConstrainXToNegativeUnitySlopeAxis	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_X_TO_NEGATIVE_UNITY_SLOPE_AXIS
	.enter

	movdwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_x, ax
	subdwf	ss:[bp].PDF_x, ss:[bp].PDF_y, ax
	adddwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_y, ax

	.leave
	ret
VisRulerConstrainXToNegativeUnitySlopeAxis	endm

VisRulerConstrainYToNegativeUnitySlopeAxis	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_Y_TO_NEGATIVE_UNITY_SLOPE_AXIS
	.enter

	movdwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_y, ax
	subdwf	ss:[bp].PDF_y, ss:[bp].PDF_x, ax
	adddwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_x, ax

	.leave
	ret
VisRulerConstrainYToNegativeUnitySlopeAxis	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerConstrainToVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_CONSTRAIN_TO_VECTOR

Pass:		*ds:[si] = VisRuler object
		ds:[di] = VisRuler instance
		ss:[bp] = PointDWFixed

Return:		ss:[bp] is constrained to vector

Destroyed:	ax, bx, cx, dx, di, si

Comments:	no comment

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 29, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerConstrainToVector	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_TO_VECTOR
	uses	cx
	.enter
	mov	cx, VRCS_VECTOR_CONSTRAIN
	call	ProcessConstrainStrategy
	call	VisRulerCheckVectorConstraint
	.leave
	ret
VisRulerConstrainToVector	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerCheckVectorConstraint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si = VisRuler object
		cx = VisRulerConstrainStrategy
		ss:bp = PointDWFixed

Return:		carry set if constrained

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerCheckVectorConstraint	proc	near
	class	VisRulerClass
	uses	ax
	.enter

	test	cx, mask VRCS_CONSTRAIN_TO_VECTOR
	jz	checkVectorReflection

	mov	ax, MSG_VIS_RULER_CONSTRAIN_X_TO_VECTOR
	test	cx, mask VRCS_INTERNAL
	jz	doVector
	mov	ax, MSG_VIS_RULER_CONSTRAIN_Y_TO_VECTOR
doVector:
	call	ObjCallInstanceNoLock
	jmp	stcDone

checkVectorReflection:
	test	cx, mask VRCS_CONSTRAIN_TO_VECTOR_REFLECTION
	jz	done					;carry clear from test

	mov	ax, MSG_VIS_RULER_CONSTRAIN_X_TO_VECTOR_REFLECTION
	test	cx, mask VRCS_INTERNAL
	jz	doVectorReflection
	mov	ax, MSG_VIS_RULER_CONSTRAIN_Y_TO_VECTOR_REFLECTION
doVectorReflection:
	call	ObjCallInstanceNoLock

stcDone:
	stc
done:
	.leave
	ret
VisRulerCheckVectorConstraint	endp

VisRulerConstrainXToVector	method	VisRulerClass,
				MSG_VIS_RULER_CONSTRAIN_X_TO_VECTOR
	uses	ax, bx
	.enter

	call	VisRulerUntransformPointsAndVector
	movwwf	axbx, ds:[di].VRI_vectorSlope
	call	VisRulerConstrainXToVectorCommon
	call	VisRulerTransformPointsAndVector

	.leave
	ret
VisRulerConstrainXToVector	endm

VisRulerConstrainXToVectorReflection	method	VisRulerClass,
				MSG_VIS_RULER_CONSTRAIN_X_TO_VECTOR_REFLECTION
	uses	ax, bx
	.enter

	call	VisRulerUntransformPointsAndVector
	movwwf	axbx, ds:[di].VRI_vectorSlope
	negwwf	axbx
	call	VisRulerConstrainXToVectorCommon
	call	VisRulerTransformPointsAndVector

	.leave
	ret
VisRulerConstrainXToVectorReflection	endm

VisRulerConstrainXToVectorCommon	proc	near
	class	VisRulerClass
	uses	ax, cx, dx, di, si
	.enter
	;
	;	map point to vector by fixing the y offset and
	;	changing the x offset.
	;
	movdwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_x, dx

	;
	;	Get slope reciprocal into dx:cx
	;
	tst	ax
	jnz	doIt
	tst	bx
	jz	done

doIt:
	cwd
	push	dx					;save high int
	xchg	ax, bx					;ax <- frac, bx <- int
	clr	cx
	mov	dx, 1
	call	GrSDivWWFixed

	;
	;	si:bx:ax <- y offset
	;
	movdwf	sibxax, ss:[bp].PDF_y
	subdwf	sibxax, ds:[di].VRI_reference.PDF_y

	pop	di					;di <- high int

 	;
	;	Multiply slope reciprocal by y offset
	;
	call	GrMulDWFixed
	
	;
	;	add the result to x
	;

	adddwf	ss:[bp].PDF_x, dxcxbx

done:
	.leave
	ret
VisRulerConstrainXToVectorCommon	endp

VisRulerConstrainYToVector	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_Y_TO_VECTOR
	uses	ax, cx
	.enter

	call	VisRulerUntransformPointsAndVector
	movwwf	axcx, ds:[di].VRI_vectorSlope
	call	VisRulerConstrainYToVectorCommon
	call	VisRulerTransformPointsAndVector

	.leave
	ret
VisRulerConstrainYToVector	endm

VisRulerConstrainYToVectorReflection	method	VisRulerClass, MSG_VIS_RULER_CONSTRAIN_Y_TO_VECTOR_REFLECTION
	uses	ax, cx
	.enter

	call	VisRulerUntransformPointsAndVector
	movwwf	axcx, ds:[di].VRI_vectorSlope
	negwwf	axcx
	call	VisRulerConstrainYToVectorCommon
	call	VisRulerTransformPointsAndVector

	.leave
	ret
VisRulerConstrainYToVectorReflection	endm

VisRulerConstrainYToVectorCommon	proc	near
	class	VisRulerClass
	uses	ax, cx, dx, di, si
	.enter
	;
	;	map point to vector by fixing the x offset and
	;	changing the y offset.
	;
	movdwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_y, dx

	;
	;	Get slope into dx:cx
	;
	cwd
	push	dx					;save sign extension
	mov_tr	dx, ax					;dx <- int.low

	;
	;	si:bx:ax <- x offset
	;
	movdwf	sibxax, ss:[bp].PDF_x
	subdwf	sibxax, ds:[di].VRI_reference.PDF_x

	pop	di					;di <- sign ext.

 	;
	;	Multiply slope by x offset
	;
	call	GrMulDWFixed
	
	;
	;	add the result to y
	;

	adddwf	ss:[bp].PDF_y, dxcxbx

	.leave
	ret
VisRulerConstrainYToVectorCommon	endp

RulerGridGuideConstrainCode	ends
