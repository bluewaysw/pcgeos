COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS - Spline edit object
MODULE:		
FILE:		splineControls.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

ROUTINES:
	SplineAddNextControl
	SplineAddNextFarControl
	SplineAddPrevControl
	SplineAddVerySmoothControlPoints
	SplineChangeOtherControlPoint
	SplineCheckToDeleteControlPoints
	SplineDetermineSmoothness
	SplineSetFlagsForControlMove
	SplineSetSmoothnessLow
	SplineUpdateAutoSmoothControls
	SplineUserChangeControlPoint

DESCRIPTION:
	Routines to handle control points.


	$Id: splineControls.asm,v 1.1 97/04/07 11:09:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineOperateCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineAddVerySmoothControlPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add 2 control points to the anchor point if they don't
		already exist.
		Set the anchor to VERY_SMOOTH

CALLED BY:	internal

PASS:		*ds:si - points list
		es:bp - VisSplineInstance data
		ax - anchor point number

RETURN:		ax - new anchor point number
		cl - SplineReturnType (SRT_TOO_MANY_POINTS, if that's
			the case)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddVerySmoothControlPoints	proc	far

	.enter

EC <	call	ECSplineInstanceAndPoints	>
EC <	call	ECSplineAnchorPoint >	; make sure at anchor point

	call	ChunkArrayElementToPtr
	ornf	ds:[di].SPS_info, ST_VERY_SMOOTH

	call	SplineAddPrevControl
	call	SplineAddNextControl	; add a "NEXT" control point

	.leave
	ret
SplineAddVerySmoothControlPoints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineAddNextControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a "next" control to this anchor point

CALLED BY:	internal to SPLINE

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		ax - point number

RETURN:		cl - SplineReturnType

DESTROYED:	nothing

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddNextControlFar	proc	far
	call	SplineAddNextControl
	ret
SplineAddNextControlFar	endp

SplineAddNextControl	proc	near
	uses	bx, di
	.enter

EC <	call	ECSplineInstanceAndPoints	>
EC <	call	ECSplineAnchorPoint		> ; make sure at anchor

	call	SplineGotoNextControlFar 	 ; see if next ctrl exists
	mov	bl, SPT_NEXT_CONTROL
	call	AddNextOrPrev

	.leave
	ret
SplineAddNextControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineAddPrevControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a "Previous" control point to the current anchor point

CALLED BY:	internal to SPLINE

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		ax - anchor point number

RETURN:		ax - new anchor point number
		cl - SplineReturnType

DESTROYED:	nothing

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddPrevControlFar	proc	far
	call	SplineAddPrevControl
	ret
SplineAddPrevControlFar	endp

SplineAddPrevControl	proc	near
	uses	bx,di
	.enter

EC <	call	ECSplineInstanceAndPoints	>
EC <	call	ECSplineAnchorPoint		>

	call	SplineGotoPrevControlFar	; go to the previous control
	mov	bl, SPT_PREV_CONTROL	
	call	AddNextOrPrev
	.leave
	ret

SplineAddPrevControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNextOrPrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a "next" or "prev" control point

CALLED BY:	SplineAddNextControl, SplineAddPrevControl

PASS:		bl - PointInfoFlags
		ax - anchor number
		*ds:si - points
		es:bp - VisSplineInstance
		CARRY FLAG - set if point should be added

RETURN:		ax - anchor number (if changed)
		cl - SplineReturnType

DESTROYED:	bx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddNextOrPrev	proc near

	uses	dx

	.enter
	
	;
	; Allocate a SPS_point structure on the stack without munging
	; the carry or nuking AX
	;
	mov	di, sp
	lea	sp, ss:[di-(size SPS_point)]

	jnc	nullOp				; already there? DONE

	call	ChunkArrayElementToPtr		; ds:di - point

	;
	; Copy the anchor's coordinates onto the stack
	;

	push	es, si
	mov	si, di
	mov	di, sp
	add	di, 4
	segmov	es, ss
	mov	cx, size SPS_point/2
	rep	movsw
	pop	es, si

	;
	; If we're adding a NEXT control, then increment point number before
	; doing insert.
	;

	cmp	bl, SPT_PREV_CONTROL
	je	gotNum
	inc	ax
gotNum:
	call	SplineInsertPoint	; ds:di - new point
	jc	tooMany

	;
	; Now, copy the point off the stack
	;
	
	push	ds, es, si
	mov	si, sp
	add	si, 6
	segmov	es, ds
	segmov	ds, ss
	mov	cx, size SPS_point/2
	rep	movsw
	pop	ds, es, si

	mov	cl, SRT_OK

gotoAnchor:
	call	SplineGotoAnchor

done:

	;
	; Make sure we're still pointing at the anchor point
	;

EC <	call	ECSplineAnchorPoint		>
	add	sp, size SPS_point
	.leave
	ret

nullOp:
	mov	cl, SRT_NULL_OPERATION
	jmp	gotoAnchor

tooMany:

	;
	; If we can't add this point, then set AX back to the be the
	; anchor number.  In the case of a PREV control, it's there
	; already.  In the case of a NEXT control, decrement AX
	;

	cmp	bl, SPT_NEXT_CONTROL
	jne	gotAnchor
	dec	ax			; go back to anchor
gotAnchor:
	mov	cl, SRT_TOO_MANY_POINTS
	jmp	done

AddNextOrPrev	endp



SplineOperateCode	ends

SplinePtrCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineUserChangeControlPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	change a control point 

CALLED BY:	internal

PASS:		*ds:si - Chunk Array
		ax - current control point
		cx - change in x
		dx - change in y

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUserChangeControlPoint	proc	near
	uses	di
	.enter
EC <	call	ECSplineControlPoint >		; make sure we're at a
						; valid control point
	call	ChunkArrayElementToPtr
	add	ds:[di].SPS_point.PWBF_x.WBF_int, cx	; add delta X
	add	ds:[di].SPS_point.PWBF_y.WBF_int, dx	; add delta Y
	.leave
	ret
SplineUserChangeControlPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineChangeOtherControlPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the OTHER control point of the current anchor point
		based on what THIS control point is up to

CALLED BY:	internal

PASS:		*ds:si - Chunk Array
		es:bp - VisSplineInstance data
		ax - control point number
		cx, dx - mouse deltas

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:  

  for SEMI-SMOOTH:


KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineChangeOtherControlPoint	proc	near uses	ax,bx,cx,di
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints >
EC <	call	ECSplineControlPoint	>	; make sure at control point

	; set ds:di to point to the OTHER control point
	push	ax
	call	SplineGotoOtherControlPoint
	pop	ax

	jc	done	; No control point to change!

	; See what type of smoothness we're dealing with here.

	call	SplineDetermineSmoothness
	cmp	bl, ST_NONE
	je	done
	cmp	bl, ST_VERY_SMOOTH
	je	verySmooth

	; the semi-smooth case is used for both semi-smooth and auto-smooth.
	call	SplineChangeSemiSmoothControlPoint
	jmp	done

verySmooth:
	call	SplineChangeVerySmoothControlPoint

done:
	.leave
	ret
SplineChangeOtherControlPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineChangeSemiSmoothControlPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the OTHER control point in "semi-smooth" fashion.

CALLED BY:	SplineChangeOtherControlPoint

PASS:		ax - THIS control point's point number
		ds:di - ptr to OTHER control point
		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

	P0 = 	X0, Y0 = THIS control point
	P1 = 	X1, Y1 = anchor point
	P2 =	X2, Y2 = OTHER control point

	THETA = ARCTAN((Y0-Y1)/(X0-X1))

	D = distance (P1 - P2)
	
	X2 = X1 - D * COS(THETA)
	Y2 = X1 - D * SIN(THETA)

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/20/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineChangeSemiSmoothControlPoint	proc far uses	ax,bx,cx,dx
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints	>
EC <	call	ECSplineControlPoint	>

	push	di				; push OTHER control
						; point's pointer.

	; Get THIS control point's coords and subtract from anchor.

	call	ChunkArrayElementToPtr
	LoadPointAsInt	cx, dx, ds:[di].SPS_point

	call	SplineGotoAnchor
	LoadPointAsInt	ax, bx, ds:[di].SPS_point
	push	ax, bx				; save anchor's coords

	sub	cx, ax			; subtract differences
	sub	dx, bx

	call	SplineArcTan		; arctan will be in DX.CX
	
	; get distance from anchor to OTHER control point (already stored in
	; scratch chunk)
	
	SplineDerefScratchChunk bx

	mov	ax, ds:[bx].SD_distance.WWF_frac
	mov	bx, ds:[bx].SD_distance.WWF_int

	call	SplinePolarToCartesian		; convert angle, distance
						; to x,y coords.

	; restore anchor point's coords, and subtract new offsets

	pop	ax, bx
	sub	ax, cx
	sub	bx, dx

	; Go to OTHER control point:

	pop	di

	; Store new control point values
	StorePointAsInt		ds:[di].SPS_point, ax, bx
	.leave
	ret
SplineChangeSemiSmoothControlPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineChangeVerySmoothControlPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the OTHER control point in such a way that it is
	equidistant from, and in the opposite direction of the
	anchor from THIS control point.

CALLED BY:	SplineChangeOtherControlPoint

PASS:		ds:di - address of OTHER control point
		ax - point number of THIS control
		*ds:si - points array

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	
	Let P0 = THIS control
		P1 = ANCHOR
		P2 = OTHER control

		P2 = P1 - (P0 - P1), which is 2*P1 - P0

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/20/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineChangeVerySmoothControlPoint	proc far

	uses	ax,bx,cx,dx

	.enter

	push	di

	; Get THIS control's coordinates

	call	ChunkArrayElementToPtr
	LoadPointAsInt	cx, dx, ds:[di].SPS_point

	call	SplineGotoAnchor
	LoadPointAsInt	ax, bx, ds:[di].SPS_point

	; P1 * 2
	shl	ax, 1
	shl	bx, 1

	; P1 * 2 - P0

	sub	ax, cx
	sub	bx, dx

	pop	di
	StorePointAsInt	ds:[di].SPS_point, ax, bx
	.leave
	ret
SplineChangeVerySmoothControlPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineUpdateAutoSmoothControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the control points for the current anchor points
		based on the anchor's position, and the angles between
		the anchor and its neighbors.

CALLED BY:	SplineBeginnerEditMoveAnchor

PASS:		*ds:si - points array
		es:bp - VisSpline instance data
		ax - anchor point number

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FUDGE_FACTOR = 10

SplineUpdateAutoSmoothControlsFar	proc	far
	call	SplineUpdateAutoSmoothControls
	ret
SplineUpdateAutoSmoothControlsFar	endp

SplineUpdateAutoSmoothControls	proc	near
	uses	ax, cx, dx
	.enter

	;
	; Get the coordinates for the NEXT anchor.  If there's no such
	; thing, then just use the coordinates of the current anchor. 
	;

	push	ax
	call	SplineGotoNextAnchor
	pop	ax
	jnc	getCXDX
	call	ChunkArrayElementToPtr

getCXDX:
	LoadPointAsInt	cx, dx, ds:[di].SPS_point
	call	SplineUpdateAutoSmoothControlsCXDX

	.leave
	ret
SplineUpdateAutoSmoothControls	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUpdateAutoSmoothControlsCXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update control points for the current anchor, based on
		the position of the previous anchor, and the position
		passed in (CX,DX)

CALLED BY:	SplineUpdateAutoSmoothControls, 

PASS:		es:bp - vis spline instance
		*ds:si - points
		cx, dx - position of "next" anchor
		ax - current anchor point

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

	Let P0 = Prev anchor
	    P1 = Prev control
	    P2 = Anchor
	    P3 = Next control
	    P4 = Next anchor

	vectorA = vector(P2,P0)
	vectorB = vector(P2,P4)
	vectorC = vector(P0,P4)

	angleA = arctan(vectorA)
	angleB = arctan(vectorB)
	angleC = arctan(vectorC)

	angleD = average(angleA,angleB)

	
	angleE = angleA - angleC

	neighborDistance = min(lengthVectorA, lengthVectorB)*3/4

	R = neighborDistance * sine(angleE) / 2

	Control points are at a distance from P2 (in polar coordinates),
		(R,angleF) and (R,angleG)
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUpdateAutoSmoothControlsCXDX	proc	near
	uses	ax,bx,cx,dx,di

	class	VisSplineClass

; The coordinates for the NEXT anchor come in from the caller -- push
; Y-coord first

P4		local	Point		push	dx, cx
anchorNum 	local	word		push	ax
P0		local	Point
P2		local	Point
angleA		local	sword
angleB		local	sword
angleD		local	sword
angleE		local	sword
lengthVectorA	local	WWFixed
lengthVectorB	local	WWFixed
neighborDistance local	WWFixed
minControlLength local	word

	.enter

EC <	call	ECSplineAnchorPoint	>

	; Store anchor position

	call	ChunkArrayElementToPtr
	LoadPointAsInt	cx, dx, ds:[di].SPS_point
	movP	P2, cxdx

	;
	; get the OLD bp (es:bp - VisSplineInstance data) to visit the
	; previous anchor
	;

	push	bp
	mov	bp, ss:[bp]
	call	SplineGotoPrevAnchor
	pop	bp

	;
	; If there's no previous anchor, then just use the current
	; anchor's coordinates as the previous anchor
	;

	jc	noPrev
	LoadPointAsInt	cx, dx, ds:[di].SPS_point
	movP	P0, cxdx
	jmp	afterPrev

noPrev:
	movP	P0, P2, ax

afterPrev:

	;
	; vectorA = vector( P2 -->P0 )
	;

	movP	cxdx, P0
	subP	cxdx, P2

	;
	; angleA = arctan(vectorA)
	;

	push	cx, dx		; save vector A
	call	SplineArcTan
	mov	angleA, dx		

	;
	; lengthVectorA = length(vectorA)
	;

	pop	cx, dx
	call	SplineCalcDistance
	movwwf	lengthVectorA, dxcx	; and store length of vector A


	;
	; vectorB = vector(P2 --> P4)
	;

	movP	cxdx, P4
	subP	cxdx, P2


	;
	; calc lengthVectorB
	;
	push	cx, dx			; vector B
	call	SplineCalcDistance
	movwwf	lengthVectorB, dxcx

	;
	; neighborDistance = min(lengthVectorA, lengthVectorA)*3/4
	; minControlLength = neighborDistance / 2
	;
	
	cmp	dx, lengthVectorA.WWF_int
	jl	storeNeighborDistance
	mov	dx, lengthVectorA.WWF_int

storeNeighborDistance:
	mov	cx, dx
	shr	cx
	shr	cx
	sub	dx, cx
	clr	cx
	movwwf	neighborDistance, dxcx

	shr	dx
	mov	minControlLength, dx

	;
	;angleB = arctan(vectorB)
	;

	pop	cx, dx			; vector B
	call	SplineArcTan
	mov	angleB, dx
	mov	bx, dx			; save angle b in bx

	;
	; angleD = averge of angleA, angleB
	; If angleA and angleB are more than 180 degrees apart, then 
	; 	angleD = angleD + 180.  This is done so that all three
	; angles lie in the same hemicircle, and thus produces a more
	; pleasing shape.

	add	dx, angleA
	shr	dx, 1
	
	Diff	bx, angleA
	cmp	bx, 180
	jle	storeAngleD

	add	dx, 180

storeAngleD:
	call	SplineNormalizeAngle
	mov	angleD, dx

	;
	; vectorC = vector(P0,P4)
	;

	movP	cxdx, P4
	subP	cxdx, P0

	;
	; angleC = arctan(vectorC)
	;

	call	SplineArcTan

	;
	; angleE = angleA - angleC
	;

	neg	dx
	add	dx, angleA
	add	dx, 180
	call	SplineNormalizeAngle
	mov	angleE, dx

	;
	; R = neighborDistance * sine(angleE)
	;

	clr	ax
	call	GrQuickSine	; (result will be in DX.AX)
	mov	cx, ax		; put result in DX.CX

 	movdw	bxax, neighborDistance

	call	GrMulWWFixed
	mov	bx, dx		; save result in BX.AX
	mov	ax, cx

	; Control point P1 = P2 + (polar) (R,angleD - 90)

	mov	dx, angleD
	sub	dx, 90
	clr	cx

	; Do some trickery on (R, theta) to make R positive
	tst	bx
	jns	posR
	neg	bx
	add	dx, 180
posR:
	; Divide R by 2

	sar	bx, 1
	rcr	ax, 1

	;
	; Make sure R falls between the bounds MIN and MAX
	;

	cmp	bx, MAX_AUTO_SMOOTH_CONTROL_DISTANCE
	jl	maxOK
	mov	bx, MAX_AUTO_SMOOTH_CONTROL_DISTANCE
maxOK:
	cmp	bx, minControlLength
	jg	minOK
	mov	bx, minControlLength
minOK:
	call	SplinePolarToCartesian
	push	cx, dx			; save x,y offsets 

	mov	ax, anchorNum
	call	SplineGotoPrevControl
	jc	storeNextControl
	addP	cxdx, P2
	StorePointAsInt	ds:[di].SPS_point, cx, dx

storeNextControl:
	pop	cx, dx
	mov	ax, anchorNum
	call	SplineGotoNextControl
	jc	done
	neg	cx
	neg	dx
	addP	cxdx, P2
	StorePointAsInt	ds:[di].SPS_point, cx, dx
done:
	.leave
	ret
SplineUpdateAutoSmoothControlsCXDX	endp	




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUpdateControlsFromAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the position of the control points for this
		anchor point -- either by adding the deltas passed in
		CX and DX, or updating them in "auto-smooth" fashion.

CALLED BY:	SplineOperateOnPointCommon

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		(CX DX) mouse deltas

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Determine smoothness of anchor, and act accordingly.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUpdateControlsFromAnchor	proc	near
	uses	ax,bx,cx,dx,di,si,bp
	.enter
EC <	call	ECSplineAnchorPoint	>

	; If auto-smooth, then call the Auto-smooth procedure

	call	SplineDetermineSmoothness
	cmp	bl, ST_AUTO_SMOOTH
	je	autoSmooth

	; otherwise, just add deltas.

	push	ax
	call	SplineGotoPrevControl
	jc	nextControl
	add	ds:[di].SPS_point.PWBF_x.WBF_int, cx
	add	ds:[di].SPS_point.PWBF_y.WBF_int, dx

nextControl:
	pop	ax
	call	SplineGotoNextControl
	jc	done
	add	ds:[di].SPS_point.PWBF_x.WBF_int, cx
	add	ds:[di].SPS_point.PWBF_y.WBF_int, dx
	jmp	done

autoSmooth:
	call	SplineUpdateAutoSmoothControls
done:
	.leave
	ret
SplineUpdateControlsFromAnchor	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineSetFlagsForControlMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Based on certain facts about the control point and its
	owner, we want to set certain flags for drawing the curve(s) 
	in "interactive" mode.  Basically, if the ANCHOR (owner) of the 
	control is SMOOTH, then we want to draw both curves of the anchor,
	otherwise only draw one or the other (based on whether CONTROL
	is a NEXT or PREV control).

CALLED BY:	SplineDSAdvancedEditControl, SplinePtrAdvancedEditControl

PASS:		ax - current (action) control point 
		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		dl - SplineWhichPointFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REGISTER/STACK USAGE:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSetFlagsForControlMove	proc	far
	uses	ax, di, bx
	.enter
EC <	call	ECSplineControlPoint >	; make sure Action pt. is a control
	mov	dx, mask SWPF_ANCHOR_POINT
	call	ChunkArrayElementToPtr
	mov	bh, ds:[di].SPS_info		; get control's info record

	call	SplineGotoAnchor
	mov	bl, ds:[di].SPS_info
	andnf	bl, mask APIF_SMOOTHNESS
	cmp	bl, ST_NONE
	jne	smooth

	; It's not smooth, so only draw one control or the other

	test	bh, mask CPIF_PREV		; is control a PREV?
	jz	nextOnly			; NO: then set NEXT only
	ornf	dx, mask SWPF_PREV_ANCHOR or \
			mask SWPF_PREV_CONTROL	; YES: set PREV only
	jmp	done
nextOnly:
	ornf	dx, mask SWPF_ANCHOR_POINT or \
			mask SWPF_NEXT_CONTROL
	jmp	done
smooth:
	ornf	dx, mask SWPF_PREV_ANCHOR or \
			mask SWPF_ANCHOR_POINT or \
			mask SWPF_PREV_CONTROL or \
			mask SWPF_NEXT_CONTROL
done:
	.leave
	ret
SplineSetFlagsForControlMove	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDetermineSmoothness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See what type of SMOOTHNESS is applicable for the
		current anchor point/control point(s)

CALLED BY:	SplineDSMoveControl

PASS:		ax - point number (either anchor or control)
		*ds:si - points array

RETURN:		bl - one of the SmoothTypes (etype)

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDetermineSmoothness	proc far	 uses	ax,di
	.enter
EC <	call	ECSplinePoint	>
	call	SplineGotoAnchor
	mov	bl, ds:[di].SPS_info
	andnf	bl, mask APIF_SMOOTHNESS
	.leave
	ret
SplineDetermineSmoothness	endp

SplinePtrCode	ends


