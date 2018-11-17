COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spline edit object
FILE:		splineMath.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

ROUTINES:
	BinarySearchWWFixed
	CalcPolynomial
	MulDWFByWordFrac
	MulDWordByWord
	MulDWords
	NewtonianIteration
	SplineArcTan
	SplineCalcCoefficients
	SplineCalcDistFormulaCoeffs
	SplineCalcDistance
	SplineCalcSquareRoot
	SplineCheckMinimalDimensions
	SplineClosestPointOnCurve
	SplineConvertPointsFromWBFixed
	SplineConvertPointsToWBFixed
	SplineGetBezierPoints
	SplineGetBoundingRectangle
	SplineNormalizeAngle
	SplinePointAtCXDX?
	SplinePointInCurrentBoundingRectangle
	SplinePointInRectangleLow?
	SplinePointInWBFRect?
	SplinePointOnSegment?
	SplinePolarToCartesian
	SplineSubdivideAndCheckPoint
	SplineSubdivideCurveHigh
	SplineSubdivideCurveLow
	SplineSubdivideMidpointLow
	TakeDerivative

DESCRIPTION:
	math routines for implementing the Spline object

	$Id: splineMath.asm,v 1.1 97/04/07 11:09:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplinePtrCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGetBezierPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	In the VisSpline object, points are stored in such a way as to
minimize space.  For example, a straight line segment may be specified
only by its endpoints (anchor points), and not by any control points.
A Bezier curve is always specified by 4 points, so the purpose of this
routine is to provide those 4 points even in cases where the actual
number of points is less.  A nonexistent control point is always given
as a copy (duplicate) of is "owner" anchor point.


CALLED BY:	internal

PASS:
	ax - element number of first anchor point
	cl - SplineDrawFlags (only SDF_USE_UNDO_INSTEAD_OF_TEMP is
		looked at)

	*ds:si - Chunk Array of points
	es:bp - VisSplineInstance data

RETURN:
	carry set if there's not a curve available to draw.
	ds:di - SD_bezierPoints

DESTROYED:	

PSEUDO CODE/STRATEGY:
	A Cubic Bezier Curve is always defined by 4 points, so this
	routine must "fill out" those 4 points by determining what
	sort of control points we have.  Basically, the array at this
	point can contain the following points:

	1) A N P A  (anchor, next, previous, anchor)
	2) A N A
	3) A P A
	4) A A

	And we want to convert it to:

	A N P A

	This means that "missing" points must be filled in.   To do this,
	I first extract P0, then P1 is either the Next control point, or
	P0 (if there is no NEXT).  Then, we get P3, and fill in P2 as
	either P3's PREV or P3, if P3 has no PREV.

	This routine uses	the "SplineGetPointData" along with
	SplineDrawFlags (in CX) to determine whether to use the normal
	point data or the "undo" point data.

	*** ADDED 7/2 ***
	If there is no NEXT anchor, then return something reasonable,
	but be sure and set the carry as well.  "Something reasonable"
	will be a copy of point P0 in points P2 and P3 (this is for
	Invalidation on the LAST point of an open curve).



REGISTER USAGE:
	ax is the point number
	ds:bx - base of CurveStruct
	cl - number of SOURCE points that went into the final
	curve structure. (if cl=2, calling routine may be able to be
	"smarter" about what it's doing...)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetBezierPoints	proc	far
	uses	ax, bx, dx
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints	>

	SplineDerefScratchChunk bx
	add	bx, offset SD_bezierPoints	; ds:bx - destination 
						; CurveStruct 

	mov	dl, 4			; assume all 4 source points available

	; get point P0

	CheckHack	<offset CS_P0 eq 0>
	call	SplineGetPointCoords
	jc	done				; No more points, return
						; with carry set.

	push	ax			;  anchor number

	;Now, get P1:

	call	SplineGotoNextControl
	jc	noNext

	push	bx
	add	bx, offset CS_P1
	call	SplineGetPointCoords
	pop	bx
	jmp	getP3
noNext:
	; If no next, then copy P0 to P1

	dec	dl
	MovPoint	ds:[bx].CS_P1, ds:[bx].CS_P0

getP3:
	; Now, skip to next anchor, and fill in P3

	pop	ax			; original anchor
	call	SplineGotoNextAnchor
	jc	noP3

	push	bx
	add	bx, offset CS_P3
	call	SplineGetPointCoords
	pop	bx

	;now, getP2:

	call	SplineGotoPrevControl
	jc	noPrev
	push	bx
	add	bx, offset CS_P2
	call	SplineGetPointCoords
	pop	bx
	jmp	done

noPrev:
	; If no prev, then copy P3 to P2, and decrement count

	dec 	dl
	MovPoint	ds:[bx].CS_P2, ds:[bx].CS_P3, ax
	clc
done:
	mov	cl, dl			; number of source points
	mov	di, bx			; set DS:DI pointing to curveStruct
	.leave
	ret

	; Special case:  If no next anchor point, at least return something
	; that the GetBoundingRectangle code can use (but don't change the
	; carry flag!)
noP3:
irp xy, <P_x, P_y>
	mov	ax, ds:[bx].CS_P0.xy
	mov	ds:[bx].CS_P2.xy, ax
	mov	ds:[bx].CS_P3.xy, ax
endm
	jmp	done

SplineGetBezierPoints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetPointCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the coordinates of the given point

CALLED BY:	

PASS:		ax - point #
		cl - SplineDrawFlags (determines whether to use UNDO)
		ds:bx - address to store x, y coords to
		es:bp - spline
		*ds:si - points array

RETURN:		carry set if error

DESTROYED:	
		cx, di

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetPointCoords		proc	near
	uses	cx, dx
	.enter
	; Get either the normal or UNDO data
	call	SplineGetPointData
	jc	done
	LoadPointAsInt	cx, dx, ds:[di].SPS_point
	mov	ds:[bx].P_x, cx
	mov	ds:[bx].P_y, dx
	clc
done:
	.leave
	ret
SplineGetPointCoords		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplinePolarToCartesian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a polar coordinate to its corresponding
		cartesian coordinate

CALLED BY:	SplineUpdateAutoSmoothControls

PASS:		dx.cx - angle (theta)
		bx.ax - distance (r)

RETURN:		cx - x coordinate
		dx - y cordinate

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	X = R * cos(theta), Y=-R * sin(theta)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Converts from a bottom-centered coordinate system to a top-centered
	one.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 3/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePolarToCartesian	proc near 	uses	ax,bx
	angle	 local WWFixed
	distance local WWFixed
	.enter
	mov	distance.WWF_int, bx
	mov	distance.WWF_frac, ax
	mov	angle.WWF_int, dx
	mov	angle.WWF_frac, cx
	mov	ax, cx
	call	GrQuickCosine		; cos(theta) in dx.ax
	mov	cx, ax
	mov	bx, distance.WWF_int
	mov	ax, distance.WWF_frac
	call	GrMulWWFixed
	push	dx			; x-coordinate
	mov	dx, angle.WWF_int
	mov	ax, angle.WWF_frac
	call	GrQuickSine
	mov	cx, ax
	mov	bx, distance.WWF_int
	mov	ax, distance.WWF_frac
	call	GrMulWWFixed		; result in dx.cx (y-coordinate)
	neg	dx			; change sign of y-coordinate
	pop	cx			; restore x-coordinate
	.leave
	ret
SplinePolarToCartesian	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineNormalizeAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Normalize an angle by making it between 0 and 360 degrees

CALLED BY:

PASS:		dx - angle (integer)

RETURN:		dx - angle between 0 and 360

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/10/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineNormalizeAngle	proc near
	.enter

	; First, add 360 if angle less than zero
	cmp	dx, 0
	jge	positive
negative:
	add	dx, 360
	jl	negative

	; Now, subtract 360 if angle > 360
positive:
	cmp	dx, 360
	jl	done
	sub	dx, 360
	jmp	positive
done:
	.leave
	ret
SplineNormalizeAngle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCalcSquareRoot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the square root of a 32 bit number

CALLED BY:	INTERNAL
		CalcDistance

PASS:
		dx:ax - high word, low word - ALL INTEGER, NO FRAC
RETURN:
		ax.bx - square root (16 int, 16 frac )

DESTROYED:
		cx,dx,di,si

PSEUDO CODE/STRATEGY:
	A = (N/A +A)/2


	The following produces a reasonable good fraction with little effort.
	In almost all cases repeatedly using this formula returns the
	floor of the square root. So i know that
	(A+x)(A+x) = N = A^2 + R
	x^2 + 2Ax + A^2 = A^2 + R
	X^2 + 2Ax = R
	since x < 1 , throw out X^2
	2Ax = R
	x = R/2A
	In a very few cases (actually I've only found one) the formula
	returns the ceiling. If this happens, I reduce my approximation
	by 1 and and calc x again

	The max value for passed dx is calced by 8192*65535, so that
	the calculation of the initial approx does not puke.

	ffffffh is chosen as the split point for calcing the
	initial approximation because 300 * 65535 > ffffffh and it
	is easy to check for ffffffh just be checking for dh = 0

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCalcSquareRoot		proc	near
	.enter

EC <	cmp	dx,1fffh					>
EC <	ERROR_AE	BAD_SQUARE_ROOT_ARG			>

	;; The initial approximation is chosen in a very arbitary fashion
	;;(N/300)+2 if N < ffffffh
	;;(N/8192)+2 if N >= ffffffh
	;; It is important that the above division returns a number
	;; less than 65536 to prevent a divide by 0 error
	;; a much better algorithm is used in GrSqrRootWWFixed but I am
	;; under a tight deadline so I am using this for now

	mov	di,dx				;save value
	mov	si,ax
	mov	bx,300
	tst	dh
	jz	10$				;jmp if N > ffffffh
	mov	bx,8192
10$:
	div	bx				;calc initial approx
	add	ax,2				;initial approx

nextApprox:
	mov	bx,ax				;save current approx
	mov	ax,si				;value
	mov	dx,di
	div	bx				;value/approx
	add	ax,bx				;add approx
	shr	ax,1				;take average
	cmp	ax,bx				;cmp new to old
	je	gotInteger			;jmp if last 2 approxs same
	sub	bx,ax				;sub new from old
	cmp	bx,1
	je	gotInteger			;jmp if only 1 dif from last
	cmp	bx,-1
	jne	nextApprox			;fall if only 1 dif from last
gotInteger:

	clr	dx				;A high
	mov	bx,ax				;A
	mul	bx				;A^2
	sub	ax,si
	sbb	dx,di				;A^2 - N = -R
	jg	aWeirdCase
	neg	ax				;+R
	mov	dx,ax				;R
	clr	cx				;R frac
	push	bx				;A
	shl	bx,1				;2 * A
	clr	ax				;2*A frac
	call	GrUDivWWFixed
	mov	bx,cx				;frac of quotient
	pop	ax

	.leave
	ret

aWeirdCase:
	mov	ax,bx				;A
	dec	ax				;better A
	jmp	short gotInteger

SplineCalcSquareRoot		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCalcDistance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calcs distance between two points

CALLED BY:	INTERNAL

PASS:
		cx - delta x
		dx - delta y

RETURN:
		dx.cx - distance (16 int, 16 frac)
DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		Ask Pythagoras

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 9/90		Initial version
	cdb	4/91		changed registers around to make it
				incomatible with anything Steve was using
				it for.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCalcDistance		proc far  uses	ax, bx, si, di
	.enter

	; 
	tst	cx
	jns	nonNegX
	neg	cx
nonNegX:
	tst	dx
	jns	nonNegY
	neg	dx
nonNegY:
	jz	horizontal	; if dx is zero

	; jcxz MUST come after DX has been fixed up!

	jcxz	vertical	; if cx is zero

	; neither one is zero, take the square root.

	mov	ax,dx				;sqr abs delta y
	mul	dx
	mov	bx,dx				;high of square
	mov	dx,cx				;abs delta x
	mov	cx,ax				;low of delta y square
	mov	ax,dx				;abs delta x
	mul	dx				;sqr abs delta x
	add	ax,cx				;add low words
	adc	dx,bx				;add high words
	call	SplineCalcSquareRoot
	mov	dx, ax				; store result in dx.cx
	mov	cx, bx
done:
	.leave
	ret

horizontal:
	mov_trash dx, cx			; x-delta is the distance
	clr	cx
	jmp	short done

vertical:					; y-delta is the distance
	clr	cx
	jmp	short done
SplineCalcDistance		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplinePointInRectangleLow?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if point is in rectangle

CALLED BY:	SplinePointInCurrentBoundingRectangle
		...

PASS:		(si, di) - point
		ax, bx, cx, dx - rectangle

RETURN:		CARRY - set (inside) or CLEAR (outside)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePointInRectangleLow?	proc far
	.enter
	cmp	si, ax			; compare it with (left)
	jl	no			; less? NO
	cmp	si, cx			; cmp it with right
	jg	no			; greater? NO
	cmp	di, bx			; cmp with top
	jl	no			; less? NO
	cmp	di, dx			; cmp with bottom
	jg	no			; greater? NO

	stc
	jmp	done
no:
	clc
done:
	.leave
	ret
SplinePointInRectangleLow?	endp


SplinePtrCode	ends

SplineOperateCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplinePointInCurrentBoundingRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the point (cx,dx) is inside the bounding rectangle
		formed by the current curve

CALLED BY:	SplinePointOnSegment?

PASS:		*ds:si - chunk array of points
		es:bp - VisSplineInstance data
		ax - current anchor point number
		cx, dx, - mouse (or other) point

RETURN:		carry set iff point inside rectangle

DESTROYED:	nothing

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePointInCurrentBoundingRectangle 	proc far

		uses	ax, bx, cx, dx, si, di

		.enter
		
EC <		call	ECSplineInstanceAndPoints 	>

		push	cx, dx			; save point (cx, dx)
		clr	cx			; no flags
		call	SplineGetBoundingRectangle
		pop	si, di			; restore point
		call	SplinePointInRectangleLow?

		.leave
		ret
SplinePointInCurrentBoundingRectangle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplinePointOnSegment?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the point (cx, dx) lies close enough
		to the current spline segment

CALLED BY:	SplineMouseCheckSegment

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		ax - point number
		cx, dx - mouse pointer

RETURN:		CARRY SET if close enough

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	If the point doesn't lie within the bounding rectangle, then
quick reject. If it does, then convert points to WBFixed, and perform
recursive subdivision until yes/no answer can be made.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePointOnSegment?	proc	near
		uses	ax, bx, cx, di, si
		class	VisSplineClass

		.enter

EC <		call	ECSplineInstanceAndPoints		>

		push	ax			; anchor # of current segment
		call 	SplineGotoNextAnchorFar	; see if there's a NEXT anchor
		pop	ax
		jc	no		; NO?  then there's no segment to check

		call	SplinePointInCurrentBoundingRectangle
		jnc	done
	;
	; It's inside the bounding rectangle, so convert Bezier points to
	; WBFixed, and do the subdivision thang
	;
	
		SplineDerefScratchChunk di

		add	di, offset SD_bezierPoints

		push	cx
		mov	cx, 4
		call	SplineConvertPointsToWBFixed

		call	SplineGetBoundingBoxIncrement
		mov	bx, cx
		pop	cx

		call	SplineSubdivideAndCheckPoint
done:
		.leave
		ret

no:
		clc
		jmp	done

SplinePointOnSegment?	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSubdivideAndCheckPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	repeatedly subdivide the current curve
		and see if the point lies inside either half

CALLED BY:	SplinePointOnSegment?

PASS:		ds:di - address of PointWBFixeds to subdivide
		bx - additional distance to add to rectangle size
		cx, dx - mouse pointer

RETURN:		carry set (inside), clear (outside)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	If either dimension of the rectangle formed by the current set
	of points is smaller than the tolerance, then set carry and
	return.

	Otherwise, subdivide the curve.
	If point is in first half:
		repeat
	If point in 2nd half:
		move 2nd half to beginning
		repeat
	Otherwise:
		return (clear carry).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSubdivideAndCheckPoint	proc	near
	uses	si,es
	.enter
	segmov	es, ds		; make ES and DS the same
startLoop:
	call	SplineCheckMinimalDimensions
	jc	done

	; subdivide it.  If its in the first half, then repeat with 1st half
	call	SplineSubdivideMidpointLow
	call	SplinePointInWBFRect?
	jc	startLoop

	; Not in first half, see if in 2nd half
	mov	si, di
	add	di, (size WBCurveStruct - size PointWBFixed)
	call	SplinePointInWBFRect?
	jnc	outside

	; It IS in the second half, so move the 2nd half up and repeat
	xchg	si, di
	push	cx, di
	cld
	mov	cx, size WBCurveStruct/2
	rep	movsw
	pop	cx, di
	jmp	startLoop

outside:
	clc
done:
	.leave
	ret
SplineSubdivideAndCheckPoint	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCheckMinimalDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if either the X or Y dimension of the
		rectangle formed by the 4 points at the current
		WBCurveStruct is small enough to fall within the
		"tolerance" value

CALLED BY:	SplineSubdivideAndCheckPoint

PASS:		ds:di - address of rectangle

RETURN:		carry if either dimension  is very small

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCheckMinimalDimensions	proc	near
	uses	ax,cx,dx
	.enter
	; CX is min, DX is MAX

irp XY, <PWBF_x, PWBF_y>
	mov	cx, ds:[di].WBCS_P0.XY.WBF_int
	mov	dx, cx

	mov	ax, ds:[di].WBCS_P1.XY.WBF_int
	FixRange ax, cx, dx

	mov	ax, ds:[di].WBCS_P2.XY.WBF_int
	FixRange ax, cx, dx

	mov	ax, ds:[di].WBCS_P3.XY.WBF_int
	FixRange ax, cx, dx

	sub	dx, cx
	cmp	dx, SPLINE_POINT_MOUSE_TOLERANCE
	jle	minimal
endm
	clc
	jmp	done
minimal:
	stc
done:
	.leave
	ret
SplineCheckMinimalDimensions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplinePointInWBFRect?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the spline point is inside the rectangle formed
	by the set of WBFixed points in the current WBCurveStruct.
	The rectangle is expanded to include the passed tolerance value.

CALLED BY:	SplineSubdivideAndCheckPoint

PASS:		ds:di - WBCurveStruct
		bx - tolerance value
		cx, dx - point value

RETURN:		carry set (yes), or clear (no)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePointInWBFRect?	proc	near
	uses	ax,bx,cx,dx,di,si,bp
	.enter
	push	bx, cx, dx	; tolerance, mouse point

	; Rectangle is stored in AX, BX, DX, BP (for now)  (LTRB)

	mov	ax, ds:[di].PWBF_x.WBF_int
	mov	dx, ax
	mov	bx, ds:[di].PWBF_y.WBF_int
	mov	bp, bx

	; flesh out the rectangle
	mov	cx, 3
loopStart:
	add	di, size PointWBFixed
	mov	si, ds:[di].PWBF_x.WBF_int
	FixRange	si, ax, dx
	mov	si, ds:[di].PWBF_y.WBF_int
	FixRange	si, bx, bp
	loop	loopStart

	; store rectangle in AX, BX, CX, DX
	mov	cx, dx
	mov	dx, bp

	pop	bp, si, di

	sub	ax, bp
	sub	bx, bp
	add	cx, bp
	add	dx, bp
	call	SplinePointInRectangleLow?
	.leave
	ret
SplinePointInWBFRect?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGetBoundingRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the bounding rectangle of the current curve

CALLED BY:	SplineInvalCurve, SplinePointOnSegment?

PASS:		*ds:si - points array
		ax - current anchor point number
		bl - SplineDrawFlags
		es:bp - VisSplineInstance data

RETURN:		ax, bx, cx, dx - bounding rectangle of current curve

DESTROYED:	nothing

REGISTER/STACK USAGE:
	Push a rectangle structure on the stack, and access it thru
	bx.
	ax - is the point number (but also used as a memory-access
	register)
	cx - stores SplineDrawFlags
	dx - temp storage of point number
	*ds:si - points array
	ds:di - current point


PSEUDO CODE/STRATEGY:	A BEZIER curve always lies within the "Convex Hull" of
	its 4 defining points (the 2 anchors and 2 controls).  I'm using
	the bounding rectangle, which is bigger than the convex hull, 
	but easier to use.


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetBoundingRectangle	proc	far
	uses	si, di
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints 	>
EC <	call	ECSplineAnchorPoint		>  ;make sure at anchor


	push	bp				; pointer to instance
						; data 

	mov	cl, bl				; SplineDrawFlags
	call	SplineGetBezierPoints

	; The rectangle will be computed in (DI,BX,BP,DX)
	;				   (Left, Top, Right, Bottom)

	mov	si, di		; point si to start of curve struct

	; Initially, the rectangle consists of only the first point.

	lodsw			; load first x-coordinate
	mov	di, ax		; store in left & right
	mov	bp, ax
	lodsw			; load first y-coordinate
	mov	bx, ax		; store in top & bottom
	mov	dx, ax

	; Now go thru the other 3 points and see if they make the rectangle
	; any bigger:

	mov	cx, 3
startLoop:
	lodsw			; get next x-coordinate

	FixRange	ax, di, bp
	lodsw			; get next y-coordinate
	FixRange	ax, bx, dx
	loop	startLoop

	; Put the rectangle in AX, BX, CX, DX
	mov	ax, di
	mov	cx, bp

	; expand the rectangle to include handle sizes & line width

	pop	bp
	push	cx
	call	SplineGetBoundingBoxIncrement
	mov	di, cx
	pop	cx

	sub	ax, di
	sub	bx, di
	add	cx, di
	add	dx, di

EC <	call	ECSplineInstanceAndLMemBlock	> 
	.leave
	ret
SplineGetBoundingRectangle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplinePointAtCXDX?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current spline point (ax) is near enough to
		coordinates (CX, DX)

CALLED BY:	internal

PASS:		ax - point number
		*ds:si 	- ChunkArray of Points
		cx, dx - coordinates to compare point against.
		es:bp - Spline's instance data

RETURN:		Carry set if points are close enough

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	Find the x-, and y- differences, add them together,
			subtract a "tolerance" value.
			(carry flag being set correctly)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePointAtCXDX?	proc	near uses	cx, dx, di
	class	VisSplineClass
	.enter

EC <	call	ECSplineInstanceAndPoints	> 

	call	ChunkArrayElementToPtr

	Diff	cx, ds:[di].SPS_point.PWBF_x.WBF_int
	tst	ch
	jnz	notIn
	cmp	cl, es:[bp].VSI_handleSize.BBF_int
	ja	notIn

	Diff	dx, ds:[di].SPS_point.PWBF_y.WBF_int
	tst	dh
	jnz	notIn
	cmp	dl, es:[bp].VSI_handleHeight.BBF_int
	ja	notIn

	;
	;  In!
	;

	stc
	jmp	done

notIn:
	clc
done:
	.leave			; Carry flag should be set appropriately
	ret
SplinePointAtCXDX?	endp

SplinePointAtCXDXFar	proc	far
	call	SplinePointAtCXDX?
	ret
SplinePointAtCXDXFar	endp
 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSubdivideOnParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subdivide the current curve based on the given parameter.

CALLED BY:	SplineSubdivideCurveAtMousePosition,
		SplineRedoInsertAnchors 

PASS:		ax - current anchor point
		cx - parameter on which to subdivide
		es:bp - VisSplineInstance data 

RETURN:		ax

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSubdivideOnParam	proc	far
	uses	bx,dx
	class	VisSplineClass 
	.enter

	push	cx
	mov	cx, 3
	call	SplineCheckToAddPoints
	pop	cx
	jc	done

	; Tell UNDO what's up:

	push	ax
	mov	ax, UT_SUBDIVIDE
	call	SplineInitUndo
	pop	ax

	; Store param in scratch chunk
	SplineDerefScratchChunk di
	mov	ds:[di].SD_subdivideParam, cx

	call	SplineUnselectAll

	mov	bl, SOT_COPY_TO_UNDO
	mov	dx, mask SWPF_NEXT_CONTROL or mask SWPF_NEXT_FAR_CONTROL
	call	SplineOperateOnCurrentPointFar 

	call	SplineSubdivideCurveHigh
	call	SplineGotoNextAnchorFar

	; Set the point to "auto-smooth"
	mov	bl, ST_AUTO_SMOOTH
	SetEtypeInRecord bl, APIF_SMOOTHNESS, ds:[di].SPS_info

	; Select the new point:
	call	SplineUnselectAll
	call	SplineSelectPoint
	call	SplineDrawSelectedPoints

	; Copy the SELECTED list to the NEW POINTS list
	call	SplineCopySelectedToNew
done:
	.leave
	ret
SplineSubdivideOnParam	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSubdivideCurveHigh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subdivide the current curve and get high

	Using the subdivision parameter, set everything up to perform a
	subdivision of the current Bezier curve.  The
	parameter is a value between zero and one which specifies
	where along the curve it is to be subdivided.

CALLED BY:	SplineSelectCodeOperations,
		SplineSelectSegmentBeginnerEdit

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array
		ax - current anchor point

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	1)  Store the number of points to be added in the UNDO
	information.

	2)  perform the subdivision

	3)  insert the new points.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 5/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSubdivideCurveHigh	proc	near
	uses	ax,bx,cx,dx,di
	class	VisSplineClass
	.enter
EC <	call	ECSplineAnchorPoint		> 
EC <	call	ECSplineInstanceAndLMemBlock			>
EC <	call	ECSplineInstanceAndPoints		>

	; Is there a NEXT anchor point?  If not, no way to subdivide the curve!
	
	push	ax
	call	SplineGotoNextAnchorFar
	pop	ax
	LONG jc	done

	; Find the 4 points that make up this Bezier curve:

	mov	di, es:[bp].VSI_scratch
	push	di				; save chunk handle
						; for later.
	mov	di, ds:[di]
	mov	bx, ds:[di].SD_subdivideParam

	clr	cl		; No SplineDrawFlags
	call	SplineGetBezierPoints
	cmp	cl, 2
	je	lineSegment

	; Perform the subdivision
	mov	cx, 4				; number of points
	call	SplineConvertPointsToWBFixed	; convert to WBFixed
	cmp	bx, 8000h
	je	midPoint
	call	SplineSubdivideCurveLow		; divide the curve
	jmp	afterSubdivide
midPoint:
	call	SplineSubdivideMidpointLow
afterSubdivide:
	mov	cx, 7				; curve divided to 7 points
	call	SplineConvertPointsFromWBFixed


	; First add "next control"

	pop	di				; scratch chunk handle
	mov	bx, offset SD_bezierPoints.BP_curveStruct.CS_P1
						; offset to next ctrl
	mov	cl, SPT_NEXT_CONTROL
	call	SplineAddControlSpecial

	; Insert next point AFTER "next control" (will work even if next
	; control doesn't exist).
	push	di
	call	SplineGotoNextControlFar	
	pop	di
	inc	ax

	; Add next anchor
	push	di
	mov	di, ds:[di]
	movP	cxdx, ds:[di].SD_bezierPoints.BP_curveStruct.CS_P3
	mov	bx, SPT_ANCHOR_POINT
	call	SplineInsertPoint
	pop	di

	; Add next anchor's PREV control
	mov	bx, offset SD_bezierPoints.BP_curveStruct.CS_P2
	mov	cl, SPT_PREV_CONTROL
	call	SplineAddControlSpecial

	; Add next anchor's NEXT control 
	mov	bx, offset SD_bezierPoints.BP_curveStruct.CS_P4
	mov	cl, SPT_NEXT_CONTROL
	call	SplineAddControlSpecial

	; Add LAST anchor's prev control:

	push	di
	call	SplineGotoNextAnchorFar
	pop	di
	mov	bx, offset SD_bezierPoints.BP_curveStruct.CS_P5
	mov	cl, SPT_PREV_CONTROL
	call	SplineAddControlSpecial
done:
	clc			; for ChunkArrayEnum's benefit.
	.leave
	ret


lineSegment:
	call	SplineSubdivideLineSegment
	pop	di			; scratch data chunk handle
	jmp	done


SplineSubdivideCurveHigh	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSubdivideLineSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given that the current spline curve is a line segment,
		subdivide it into 2 of the same by adding a single anchor.

CALLED BY:	SplineSubdivideCurveHigh

PASS:		ax - current anchor #
		bx - subdivide param
		ds:di - SD_bezierPoints
		es:bp - VisSplineInstance data 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	ds:[di].CS_P0 and CS_P3 are the points in
		question. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	new point P = P0 + param * (P1 - P0)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSubdivideLineSegment	proc	near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	push	ax		; anchor number
	clr	ax		
	xchg	ax, bx		; put param in AX, clear BX

	mov	dx, ds:[di].CS_P3.P_x
	sub	dx, ds:[di].CS_P0.P_x
	mov	cx, bx
	call	GrMulWWFixed
	add	dx, ds:[di].CS_P0.P_x
	push	dx			; save x-coordinate

	mov	dx, ds:[di].CS_P3.P_y
	sub	dx, ds:[di].CS_P0.P_y
	mov	cx, bx
	call	GrMulWWFixed
	add	dx, ds:[di].CS_P0.P_y
	pop	cx			; restore x-coord

	pop	ax			; restore anchor number
	inc	ax
	mov	bx, SPT_ANCHOR_POINT
	call	SplineInsertPoint

	.leave
	ret
SplineSubdivideLineSegment	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAddControlSpecial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: The real name of this procedure is:

	SplineAddControlOrUpdateIfAlreadyThereUnlessSameAsAnchor

	Basically:  if anchor has a control, just change its
	coordinates, otherwise add the new control.

	If coordinates are IDENTICAL to anchor's, then don't add
	(don't delete, either!)

CALLED BY:	SplineSubdivideCurveHigh

PASS:	*ds:di - scratch chunk
	bx - offset from start of scratch chunk to point's new
		coordinates
	ax - current anchor point
	es:bp - VisSplineInstance data 
	*ds:si - points array 
	cl - SplinePointType: SPT_NEXT_CONTROL or SPT_PREV_CONTROL


RETURN:		AX - new anchor point number (if changed)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Name says it all

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddControlSpecial	proc	near
	uses	bx,cx,dx,di
	.enter

EC <	call	ECSplineAnchorPoint		>

	; Rearrange things: Deref scratch data, get point's data into
	; (BL, CX, DX)

	mov	di, ds:[di]
	add	di, bx
	mov	bl, cl			; point type
	movP	cxdx, ds:[di]

	; See if control exists:
	call	SplineGotoNextOrPrev
	jnc	hasPoint

	; Doesn't currently have this point -- add if different
	call	ChunkArrayElementToPtr
	cmp	cx, ds:[di].SPS_point.PWBF_x.WBF_int
	jne	newPoint
	cmp	dx, ds:[di].SPS_point.PWBF_y.WBF_int
	je	done			; don't add, it's same as anchor

newPoint:
	cmp	bl, SPT_PREV_CONTROL
	je	insertIt
	inc	ax
insertIt:
	clr	bh			; no fractional data
	call	SplineInsertPoint
gotoAnchor:
	call	SplineGotoAnchor	; return AX as anchor #
done:
	.leave
	ret

hasPoint:
	; This point already exists -- change its coordinates
	StorePointAsInt	ds:[di], cx, dx
	jmp	gotoAnchor

SplineAddControlSpecial	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineSubdivideCurveLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a curve of 4 spline points, return a set of 7 points
		which make up 2 bezier curves of the same shape as the
		original curve

CALLED BY:	SplineSubdivideCurveHigh

PASS:		ds:di- address of points to subdivide (in WWCurveStruct)
		bx - parameter (t) at which to subdivide

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	This procedure probably uses	more macros than it should.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSubdivideCurveLow	proc	far
	uses	ax, bx, cx, dx, di
	.enter

	; First, copy the points from their positions in the WBCurveStruct to
	; their positions in the SubdivideStruct

	MovPointWBFixed	ds:[di].SS_V1, ds:[di].WBCS_P1, ax
	MovPointWBFixed	ds:[di].SS_V3, ds:[di].WBCS_P3, ax
	MovPointWBFixed	ds:[di].SS_V2, ds:[di].WBCS_P2, ax


	; First level of subdivisions (look at the accompanying document or this
	; will look greek to you).

	mov	ax, bx			; the "param" is in AX

	DivideWBLine	SS_V0, SS_V1, SS_V01
	DivideWBLine	SS_V1, SS_V2, SS_V11
	DivideWBLine	SS_V2, SS_V3, SS_V21

	; 2nd level of subdivision

	DivideWBLine	SS_V01, SS_V11, SS_V02
	DivideWBLine	SS_V11, SS_V21, SS_V12

	; 3rd level:

	DivideWBLine	SS_V02, SS_V12, SS_V03

	.leave
	ret
SplineSubdivideCurveLow		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSubdivideMidpointLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subdivide the curve at its midpoint

CALLED BY:	SplineSubdivideMidpoint

PASS:		ds:di - pointer to a MidpointSubdivideStruct
				(also, ptr to a WBCurveStruct)
RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	See "Splines for Computer Graphics and Geometric Modeling",
	page 221.  Note that I am doing things in a slightly different
	order so that I can use the same memory to store both the
	"before" and "after" curves.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSubdivideMidpointLow	proc near uses	ax,bx,cx,dx

t	local	PointWBFixed
	.enter

	; Move P3 to T3
	MovPointWBFixed	ds:[di].MSS_T3, ds:[di].WBCS_P3, ax

	; calculate "t"
	MidPointWBFixed	t, ds:[di].WBCS_P1, ds:[di].WBCS_P2

	; P1 is no longer needed, so we can calculate S1 and overwrite it
	MidPointWBFixed	ds:[di].MSS_S1, ds:[di].WBCS_P0, ds:[di].WBCS_P1

	; calc T2 from P2 and P3
	MidPointWBFixed	ds:[di].MSS_T2, ds:[di].WBCS_P2, ds:[di].WBCS_P3

	; calc T1 from t and T2
	MidPointWBFixed	ds:[di].MSS_T1, t, ds:[di].MSS_T2

	; calc S2 from S1 and t (overwriting P2)
	MidPointWBFixed	ds:[di].MSS_S2, ds:[di].MSS_S1, t

	; calc S3 from S2 and T1, overwriting P3
	MidPointWBFixed	ds:[di].MSS_S3, ds:[di].MSS_S2, ds:[di].MSS_T1

	.leave
	ret
SplineSubdivideMidpointLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineConvertPointsToWBFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a set of integer points to WBFixed format

CALLED BY:	internal

PASS:		ds:di - address of points
		cx - number of points to convert

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:	Since we want to overwrite source points,
	move in reverse


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineConvertPointsToWBFixed	proc	far
	uses	si, di, cx, ax, es
	.enter
	.assert	WBF_frac eq 0
	.assert WBF_int eq 1
	segmov	es, ds

	mov	si, di
	add	si, offset CS_P3.P_y		; move si to last word
	add	di, offset WBCS_P3.PWBF_y.WBF_int ; move di to last word
	std					; decrement indices
	shl	cx, 1		; number of words is 2 * number of points
start:
	lodsw			; get source point value
	stosw			; store integer part (di will be
				; decremented by 2).
	inc	di		; point DI to fractional part
	clr	al
	stosb			; store fractional part (zero)
	dec	di		; point DI to beginning of next int.
	loop	start
	cld			; clear direction flag
	.leave
	ret
SplineConvertPointsToWBFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineConvertPointsFromWBFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert points from WBFixed to integer

CALLED BY:	internal

PASS:		ds:di - address of points
		cx - number of points to convert

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:	Overwrites existing points

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineConvertPointsFromWBFixed	proc	far
	uses	ax, cx, di, si, es
	.enter
	.assert	WBF_frac eq 0
	.assert WBF_int eq 1

	segmov	es, ds, ax

	mov	si, di
	cld
	shl	cx, 1		; # words is 2 * # points
start:
	lodsb			; load fractional part
	mov	bl, al
	lodsw			; load int part
	RoundAXBL		; round it, returning AX
	stosw			; store integer portion
	loop	start
	.leave
	ret
SplineConvertPointsFromWBFixed	endp


SplineOperateCode	ends


SplineMathCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineCalcCoefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the coefficients needed to evaluate the
	Bezier polynomials using Horner's rule.  Store these
	coefficients in DPoint structures (dword integer)

CALLED BY:

PASS:		ds:di - scratch chunk

RETURN:		a = (-P0 + 3P1 - 3P2 + P3)
		b = (3P0 - 6P1 + 3P2)
		c = (-3P0 + 3P1)
		d = P0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	use IRP -- makes the procedure very long, but
	also, very short!

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCalcCoefficients	proc	far
	uses	ax,bx,cx,dx,di,si
	class	VisSplineClass 
	.enter

	lea	si, ds:[di].SD_bezierPoints
	add	di, offset SD_coeffs

irp field, <P_x, P_y>

	mov	ax, ds:[si].CS_P0.&field
	mov	bx, ds:[si].CS_P1.&field
	mov	cx, ds:[si].CS_P2.&field
	mov	dx, ds:[si].CS_P3.&field
	call	CalcCoeffsLow
	add	di, size DWordCoeffs
endm
	.leave
	ret
SplineCalcCoefficients	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCoeffsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate coefficients

CALLED BY:	SplineCalcCoefficients

PASS:		ax, bx, cx, dx (P0, P1, P2, P3)

RETURN:		nothing (ds:di contains coefficients)

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcCoeffsLow	proc near
	P0	local	word
	P1	local	word
	P2	local	word
	P3	local	word
	P0_times3	local	sdword
	P1_times3	local	sdword
	P1_times6	local	sdword
	P2_times3	local	sdword
	.enter
	mov	P0, ax
	mov	P1, bx
	mov	P2, cx
	mov	P3, dx


	; First, perform multiplications
	; These multiplies by 3 could be optimized with a shift and an add...

	; 3 * P0:

	mov	cx, 3
	imul	cx
	movdw	P0_times3, dxax

	; 3 * P1
	mov	ax, P1
	imul	cx
	movdw	P1_times3	dxax

	; 6 * P1
	shldw	dxax
	movdw	P1_times6, dxax

	; 3 * P2
	mov	ax, P2
	imul	cx
	movdw	P2_times3, dxax

	; now, do the adds
	; A = (-P0 + 3P1 - 3P2 + P3)

	mov	ax, P0
	neg	ax
	cwd

	adddw	dxax, P1_times3
	subdw	dxax, P2_times3	
	
	add	ax, P3
	adc	dx, 0
	movdw		ds:[di].DWC_A, dxax

	; B =  (3*P0 - 6*P1 + 3*P2)

	movdw	bxax, P0_times3
	subdw	bxax, P1_times6
	adddw	bxax, P2_times3
	movdw	ds:[di].DWC_B, bxax

	; C =  (-3*P0 + 3*P1)

	movdw	bxax, P0_times3
	negdw	bxax

	adddw	bxax, P1_times3
	movdw	ds:[di].DWC_C, bxax

	; D = P0
	mov	ax, P0
	cwd
	movdw	ds:[di].DWC_D, dxax

	.leave
	ret
CalcCoeffsLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineClosestPointOnCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the closest point on a Bezier curve to the
	given (mouse) point -- store the parameter in the scratch chunk.

CALLED BY:	SplineSelectSegmentBeginnerEdit

PASS:		ax - current anchor point
		*ds:si - points array
		es:bp - VisSplineInstance data

		mouse point is stored in scratch chunk

RETURN:		cx - "t" parameter of closest point on curve

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/29/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineClosestPointOnCurve	proc	far
	uses	ax,bx,dx,di,si
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints		>

	clr	cl		; no DrawFlags
	call	SplineGetBezierPoints

	; If only 2 source points, then do (faster) line segment check.
	cmp	cl, 2
	jg	curve
	call	SplineClosestPointOnLineSegment
	jmp	found

curve:
	SplineDerefScratchChunk di
	call	SplineCalcCoefficients	; calculate coefficients
					; needed for Bezier polynomials

	call	SplineCalcDistFormulaCoeffs
	call	TakeDerivative

	; Now, ready to find the value of "t" that gives the minimum distance.
	; Since Newtonian iteration is only good at finding local minima, we
	; do a binary search on initial values, checking each result to see if
	; it actually works.
	mov	cx, length InitValueList
	mov	bx, offset InitValueList
startLoop:
	push	cx
	mov	ax, cs:[bx]
	call	NewtonianIteration
	push	bx
	clr	bx
	call	ProducePointFromTValue
	pop	bx
	call	CheckMouseAtCXDX
	pop	cx
	jc	found
	add	bx, size word
	loop	startLoop
	clr	ax			; nothing works! return zero
found:
	mov	cx, ax
	.leave
	ret
SplineClosestPointOnCurve	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineClosestPointOnLineSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the parametric value of the point on a line
		segment which is closest to the (mouse) point.
		

CALLED BY:	SplineClosestPointOnCurve

PASS:		es:bp - VisSplineInstance data 

RETURN:		ax - parametric value

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Divide (dist: P0-mouse)
		--------------
		dist: P0-P3

	(P0 and P3 are the anchor point values in the bezier points struct.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
P0 equ <ds:[di].SD_bezierPoints.BP_curveStruct.CS_P0>
P3 equ <ds:[di].SD_bezierPoints.BP_curveStruct.CS_P3>

SplineClosestPointOnLineSegment	proc	near
	uses	bx,cx,dx
	class	VisSplineClass 
	.enter

EC <	call	ECSplineInstanceAndLMemBlock	> 

	; First, calc distance: (P0x, P0y) - (mouseX, mouseY)

	SplineDerefScratchChunk di

	movP	cxdx, ds:[di].SD_mouse
	subP	cxdx, ds:[di].SD_bezierPoints.BP_curveStruct.CS_P0
	call	SplineCalcDistance
	push	cx, dx

	; Now, calc distance (P0x, P0y) - (P3x, P3y)


	movP	cxdx, ds:[di].SD_bezierPoints.BP_curveStruct.CS_P0
	subP	cxdx, ds:[di].SD_bezierPoints.BP_curveStruct.CS_P3
	call	SplineCalcDistance
	mov	ax, cx
	mov	bx, dx
	pop	cx, dx

	; Divide. If result > 1, then fudge it!

	call	GrSDivWWFixed
	mov	ax, cx
	tst	dx
	jz	done
	mov	ax, 0ffffh
done:
	.leave
	ret
SplineClosestPointOnLineSegment	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProducePointFromTValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a value of "t" for the current curve, produce
		the x,y point.

CALLED BY:	SplineClosestPointOnCurve

PASS:		bx.ax - t value
		ds:di - scratch data (contains coefficients)
		es:bp - VisSplineInstance data 

RETURN:		cx, dx - (x,y) value of point
		carry set iff BX.AX out of range

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProducePointFromTValue	proc	near
	uses	bx,si
	.enter

EC < 	call	ECSplineInstanceAndScratch		> 

	cmp	bx, 1
	ja	outOfRange
	je	tEqualsOne

	; BX is zero.  If AX is zero, then use P0 as the point!
	tst	ax
	jz	tEqualsZero

	; Otherwise, use polynomial coefficients to calculate point
	; First, get X value
	lea	si, ds:[di].SD_coeffs
	mov	cx, 3
	clr	bx
	call	CalcPolynomial
	push	cx			; throw out high word

	; Now get Y value
	add	si, size DWordCoeffs
	mov	cx, 3
	call	CalcPolynomial
	mov	dx, cx			; 
	pop	cx			; restore CX=X
OK:
	clc
done:
	.leave
	ret

	; BX is 1, If A is nonzero, return error, else return P3
tEqualsOne:
	tst	ax
	jnz	outOfRange
	movP	cxdx, ds:[di].SD_bezierPoints.BP_curveStruct.CS_P3
	jmp	OK

tEqualsZero:
	movP	cxdx, ds:[di].SD_bezierPoints.BP_curveStruct.CS_P0
	jmp	OK

outOfRange:
	stc
	jmp	done

ProducePointFromTValue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMouseAtCXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the mouse is at (CX, DX)

CALLED BY:	SplineClosestPointOnCurve

PASS:		ds:di - scratch data
		(CX, DX) - x-y coordinate pair

RETURN:		carry set iff close enough

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckMouseAtCXDX	proc	near
	uses	ax,bx
	.enter
	mov	ax, ds:[di].SD_mouse.P_x
	mov	bx, ds:[di].SD_mouse.P_y
	Diff	ax, cx			; find the Difference betw. the points
	Diff	bx, dx			;
	add	ax, bx			; add the differences
	sub	ax, SPLINE_POINT_MOUSE_TOLERANCE*3
	.leave
	ret
CheckMouseAtCXDX	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCalcDistFormulaCoeffs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calculate the coefficients used in the formula for
	minimizing the distance between a Bezier curve point and a
	point in space.

CALLED BY:

PASS:		es:bp - VisSplineInstance data 
		ds:di - scratch chunk

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

	Let X0, Y0 be the point.
	Distance formula (squared) is:
		d^^2 = (Cx(t)-X0)^^2 + (Cy(t) - Y0)^^2

	Taking the derivative:

	f' = 	2(Cx(t)-X0)(Cx'(t) + 2(Cy(t)-Y0)Cy'(t)

	Set this to zero, and solve for the variable t:

	(Cx(t)-X0)Cx'(t) + (Cy(t)-Y0)Cy'(t) = 0

	Where:

		C(t) = a*t^3 + b*t^2 + c*t + d

	Anyway, skipping over all the intermediate steps (left as an
	exercise to the reader), we get the final polynomial:

	t^5 [ 3(a_x^2 + a_y^2)]		(a_x is a-sub-x)

	+ t^4 [ 5(a_x * b_x  + a_y * b_y)]

	+ t^3 [ 4(a_x * c_x + a_y * c_y) + 2 (b_x^2 + b_y^2)]

	+ t^2 [ 3(a_x * d_x + a_y * d_y + b_x * c_x + b_y * c_y - a_x*X0 - a_y * Y0)]

	+ t   [ c_x^2 + c_y^2 + 2(b_x * d_x + b_y * d_y - b_x*X0 -b_y*Y0)]

	+ c_x * d_x + c_y * d_y - c_x * X0 - c_y * Y0

	The coefficients will be called A, B, C, D, E, and F

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/29/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	; string equates:

a_x	equ	<ds:[di].SD_coeffs.CS_X.DWC_A>
b_x	equ	<ds:[di].SD_coeffs.CS_X.DWC_B>
c_x	equ	<ds:[di].SD_coeffs.CS_X.DWC_C>
d_x	equ	<ds:[di].SD_coeffs.CS_X.DWC_D>
a_y	equ	<ds:[di].SD_coeffs.CS_Y.DWC_A>
b_y	equ	<ds:[di].SD_coeffs.CS_Y.DWC_B>
c_y	equ	<ds:[di].SD_coeffs.CS_Y.DWC_C>
d_y	equ	<ds:[di].SD_coeffs.CS_Y.DWC_D>

A	equ	<ds:[di].SD_distCoeffs.distCoeffA>
B	equ	<ds:[di].SD_distCoeffs.distCoeffB>
C	equ	<ds:[di].SD_distCoeffs.distCoeffC>
D	equ	<ds:[di].SD_distCoeffs.distCoeffD>
E	equ	<ds:[di].SD_distCoeffs.distCoeffE>
F	equ	<ds:[di].SD_distCoeffs.distCoeffF>

X0	equ	<ds:[di].SD_mouse.P_x>
Y0	equ	<ds:[di].SD_mouse.P_y>

SplineCalcDistFormulaCoeffs	proc near
	uses	ax,bx,cx,dx,di,si

	.enter
EC < 	call	ECSplineInstanceAndScratch		>

	
	; First, calc "A" = 3(a_x^2 + a_y ^2)

	movdw	dxcx, a_x
	movdw	bxax, dxcx
	call	MulDWords
	pushdw	dxcx

	movdw	dxcx, a_y
	movdw	bxax, dxcx
	call	MulDWords
	popdw	bxax

	adddw	dxcx, bxax
	mov	bx, 3
	call	MulDWordByWord

	movdw	A, dxcx

	; B = 5(a_x b_x + a_y b_y)

	MulAndPush	a_x, b_x

	Mul32		a_y, b_y

	PopAndAdd32

	mov	bx, 5
	call	MulDWordByWord

	movdw	B, dxcx

	; C = 4(a_x c_x + a_y c_y) + 2(b_x^2 + b_y ^2)

	MulAndPush	a_x, c_x

	Mul32	a_y, c_y

	PopAndAdd32

	mov	bx, 4
	call	MulDWordByWord
	pushdw	dxcx

	movdw	dxcx, b_x
	movdw	bxax, dxcx
	call	MulDWords
	pushdw	dxcx

	movdw	dxcx, b_y
	movdw	bxax, dxcx
	call	MulDWords

	PopAndAdd32

	mov	bx, 2
	call	MulDWordByWord
	PopAndAdd32

	movdw	C, dxcx

	; D = 3(a_x d_x + a_y d_y + b_x c_x + b_y c_y - a_x X0 - a_y Y0)

	MulAndPush	a_x, d_x

	MulAndPush	a_y, d_y

	MulAndPush	b_x, c_x

	MulAndPush	b_y, c_y

	movdw	dxcx, a_x
	negdw	dxcx
	mov	bx, X0
	call	MulDWordByWord
	pushdw	dxcx

	movdw	dxcx, a_y
	negdw	dxcx
	mov	bx, Y0
	call	MulDWordByWord

	PopAndAdd32
	PopAndAdd32
	PopAndAdd32
	PopAndAdd32
	PopAndAdd32

	mov	bx, 3
	call	MulDWordByWord

	movdw	D, dxcx


	; E = c_x^2 + c_y^2 + 2(b_x * d_x + b_y * d_y - b_x*X0 -b_y*Y0)

	movdw	dxcx, c_x
	movdw	bxax, dxcx
	call	MulDWords
	pushdw	dxcx

	movdw	dxcx, c_y
	movdw	bxax, dxcx
	call	MulDWords
	pushdw	dxcx

	MulAndPush	b_x, d_x

	MulAndPush	b_y, d_y

	movdw	dxcx, b_x
	negdw	dxcx
	mov	bx, X0
	call	MulDWordByWord
	pushdw	dxcx

	movdw	dxcx, b_y
	negdw	dxcx
	mov	bx, Y0
	call	MulDWordByWord

	PopAndAdd32
	PopAndAdd32
	PopAndAdd32

	; multiply by 2
	shl	cx, 1
	rcl	dx, 1

	PopAndAdd32
	PopAndAdd32

	movdw	E, dxcx

	; F = 	c_x * d_x + c_y * d_y - c_x * X0 - c_y * Y0

	MulAndPush	c_x, d_x

	MulAndPush	c_y, d_y

	movdw	dxcx, c_x
	mov	bx, X0
	call	MulDWordByWord
	negdw	dxcx
	pushdw	dxcx

	movdw	dxcx, c_y
	mov	bx, Y0
	call	MulDWordByWord
	negdw	dxcx

	PopAndAdd32
	PopAndAdd32
	PopAndAdd32

	movdw	F, dxcx

	.leave
	ret
SplineCalcDistFormulaCoeffs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TakeDerivative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Using the "power rule", take the derivative of a
	polynomial. (coefficients are assumed to be dword integers)

CALLED BY:

PASS:		es:bp - VisSplineInstance data 
		ds:di - scratch chunk

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Made the loop counter a constant, since only used by dist
formula stuff.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TakeDerivative	proc	near
	uses	bx,cx,dx,di,si
	.enter
EC < 	call	ECSplineInstanceAndScratch		> 

	lea	si, ds:[di].SD_distCoeffs
	add	di, offset SD_derivDistCoeffs
	mov	bx, 5			; highest degree
startLoop:
	movdw	dxcx, ds:[si]
	call	MulDWordByWord

	movdw	ds:[di], dxcx
	add	si, (size dword)
	add	di, (size dword)
	dec	bx
	jnz	startLoop
	.leave
	ret
TakeDerivative	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NewtonianIteration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Solve a polynomial by using Newtonian iteration.  The
	basic formula is:

	t1 = initial estimate
	REPEAT:
		t2 = t1 - f(t)/f'(t).
		t1 = t2
	UNTIL: f(t) or f'(t) is zero

CALLED BY:

PASS:		ax - initial value of "t"
		es:bp - VisSplineInstance data 
		ds:di - scratch chunk

RETURN:		ax - value of "t" for which f(t) is approx. 0

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewtonianIteration	proc	near
	uses	bx,cx,dx,di,si
	degree	local	word

	; Put this EC call before the .enter, 'cause it checks "bp"
EC < 	call	ECSplineInstanceAndScratch		> 
	.enter
	mov	degree, 5		; 5th degree equation

	clr	bx			; int starts out as zero
	mov	cx, 6			; Number of times (max) to loop
loopStart:

	push	cx			; loop count
	; calculate f(t)

	pushdw	bxax			; "t" value
	mov	cx, degree
	lea	si, ds:[di].SD_distCoeffs
	call	CalcPolynomial 		; (returns result DX:CX)
	tst	dx
	jnz	fNonZero
	jcxz	fZero
fNonZero:
	pushdw	dxcx			; F(t)

	; calculate f'(t)
	mov	cx, degree
	dec	cx

	lea	si, ds:[di].SD_derivDistCoeffs
	call	CalcPolynomial
	tst	dx
	jnz	fPrimeNonZero
	jcxz	fPrimeZero

fPrimeNonZero:
	movdw	bxax, dxcx
	
	popdw	dxcx			; F(t)
	
	call GrSDivWWFixed		; result is in DX.CX

	popdw	bxax			; restore "t" value
	subdw	bxax, dxcx		; calc new "t"

	pop	cx
	loop	loopStart
done:
	.leave
	ret

	; Fix up the stack before returning
fPrimeZero:
	add	sp, 2 * size word	; pop "f" value off stack
fZero:
	pop	ax		; pop low word of param
	add	sp, 4		; pop high word, loop count
	jmp	done

NewtonianIteration	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcPolynomial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a polynomial using Horner's rule.  Assume
	the variable is a WWFixed (BX.AX), and the coefficients are dword
	integers.  The result is a DWFixed number.

CALLED BY:

PASS:		bx.ax - variable
		cx - highest power of variable
		ds:si - coefficients (dword integers)

RETURN:		DX:CX - result (dword integer)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Horner's rule:

	Ax^5 + Bx^4 + Cx^3 ... =

	... (((A * x + B) * x + C) *x + D) * x ...

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcPolynomial	proc	near
	uses	ax, si, di
	.enter

	movdw	didx, ds:[si]		; DI:DX.CX - first operand


startLoop:
	push	bx, cx			; save variable and power
	push	si			; address of coefficients
	clr	cx
	mov	si, cx

	; Multiply di:dx.cx by si:bx.ax

	call	GrMulDWFixed		; result: DX:CX.BX
	mov	di, dx
	mov	dx, cx

	pop	si
	add	si, size dword

	add	dx, ds:[si].low		; add next coeff.
	adc	di, ds:[si].high

	pop	bx, cx			; restore variable, count
	loop	startLoop

	mov	cx, dx
	mov	dx, di
	.leave
	ret
CalcPolynomial	endp


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulDWFByWordFrac
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply a signed DWF by an unsigned 16-bit fraction

CALLED BY:	CalcPolynomial

PASS:		DX:CX.BX - DWFixed
		AX - 16-bit fraction

RETURN:		DX:CX.BX - result, AX unchanged

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
				 |intHigh|intLow |frac1
				 |	 |       |frac2
				-|-------|-------|-----
				 |	 | F1F2H |F1F2L
				 | ILF2H | ILF2L
			   IHF2H | IHF2L

	Result:  IHF2H:(ILF2H+IHF2L).(F1F2H+ILF2L)


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/19/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MulDWFByWordFrac	proc	near
	uses	ax

	; sources
	intHigh	local	word
	intLow	local	word
	frac2	local	word

	; partial results
	F1F2H	local	word
	ILF2	local	dword
	IHF2	local	dword
	.enter
	tst	dh
	pushf				;	save sign
	jns	dwFixedPos
	NegDWFixed	dx, cx, bx

dwFixedPos:		
	mov	intHigh, dx
	mov	intLow, cx
	mov	frac2, ax

	; Multiply F1 * F2

	mul	bx			; result DX:AX only keep high w.
	mov	F1F2H, dx
	
	; Multiply IL * F2
	mov	ax, frac2
	mul	cx
	Store32	ILF2, ax, dx

	; Multiply IH * F2
	mov	ax, frac2
	mul	intHigh
	Store32	IHF2, ax, dx

	; Add all the partial results, being careful to propagate carries.

	clr	cx
	clr	dx
	mov	bx, F1F2H
	add	bx, ILF2.low
	adc	cx, IHF2.low
	adc	dx, 0
	add	cx, ILF2.high
	adc	dx, IHF2.high

	; Restore sign

	popf
	jns	done
	NegDWFixed	dx, cx, bx
done:
	.leave
	ret
MulDWFByWordFrac	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulDWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply 2 dword integers together

CALLED BY:

PASS:		DX:CX - first integer
		BX:AX - 2nd integer

RETURN:		DX:CX - result
		(carry represents overflow)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Stolen from GrMulWWFixed, which does (almost) exactly what I want.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MulDWords	proc	near
	uses	ax,bx,si

	firstArg	local dword
	secondArg	local dword
	lowTimesLow	local dword
	lowTimesHigh	local word
	highTimesLow	local word

	.enter

	; SI is used as the sign flag
	mov	si, 1

	; test sign of both arguments, and determine if result is < 0

	tst	dh			; test first arg
	jns	firstArgPos
	negdw	dxcx
	neg	si

firstArgPos:
	tst	bh
	jns	secondArgPos
	negdw	bxax
	neg	si

secondArgPos:

	; store arguments for later use:
	movdw	firstArg, dxcx
	movdw	secondArg, bxax

	; done fixing arguments, start multiply
	; low * low

	mul	cx
	movdw	lowTimesLow, dxax

	; high * low

	mov	ax, secondArg.low
	mul	firstArg.high
	tst	dx
	jnz	overflow
	mov	highTimesLow, ax

	; low * high

	mov	ax, secondArg.high
	mul	firstArg.low
	tst	dx
	jnz	overflow
	mov	lowTimesHigh, ax

	; high * high (if both arguments are nonzero, then it's an automatic
	; error!)
	tst	secondArg.high
	jz	addEmUp
	tst	firstArg.high
	jnz	overflow

addEmUp:
	; Add the low*low result with the low words of low*high and high*low
	; jump on overflow

	movdw	dxcx, lowTimesLow

	add	dx, lowTimesHigh
	jo	overflow

	add	dx, highTimesLow
	jo	overflow

	tst	si
	jns	done
	negdw	dxcx
	clc
done:
	.leave
	ret

overflow:
	stc
	jmp	done

MulDWords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulDWordByWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply a dword integer by a word integer (both
		arguments are signed)

CALLED BY:

PASS:		DX:CX - first integer
		BX - 2nd integer

RETURN:		DX:CX - result
		(carry represents overflow)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/3/91

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MulDWordByWord	proc	near
	uses	ax,bx,si

	firstArg	local dword
	lowTimesLow	local dword
	highTimesLow	local word

	.enter

	; SI is used as the sign flag
	mov	si, 1

	; test sign of both arguments, and determine if result is < 0

	tst	dh			; test first arg
	jns	firstArgPos
	negdw	dxcx
	neg	si

firstArgPos:
	tst	bx
	jns	secondArgPos
	neg	bx
	neg	si

secondArgPos:

	; store arguments for later use:
	movdw	firstArg, dxcx
	push	bx			; second Arg

	; start multiply low * low

	mov	ax, bx
	mul	cx
	movdw	lowTimesLow, dxax

	; high * low

	pop	ax			; second argument
	mul	firstArg.high
	tst	dx
	jnz	overflow
	mov	highTimesLow, ax

	; Add the low*low result with the low word of high*low
	; jump on overflow

	movdw	dxcx, lowTimesLow

	add	dx, highTimesLow
	jo	overflow

	tst	si			; sign bit
	jns	done
	negdw	dxcx
	clc
done:
	.leave
	ret

overflow:
	stc
	jmp	done

MulDWordByWord	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineArcTan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given y and x, calculate arctan(y/x)

CALLED BY:
PASS:		cx = x
		dx = -y	(sign changed to produce more human-visible form)

RETURN:
		dx.cx - angle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Do a binary search on the tangent table.
	DX is -y instead of y in order to make the result more in line
	with the visual representation (a bottom-centered coordinate system).


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine currently performs largest integer angle with a tangent
	less than the passed value. Linear Interpolation could be done
	but it wasn't necessary for my purposes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/89		Initial version
	cdb	6/91		Changed for ArcTan

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineArcTan	proc	far
	uses	ax, bx, di, bp, ds
	.enter
	neg	dx		; change coordinate system to bottom-origin
	push	cx,dx		;save passed x, y
	tst	cx
	jz	zeroX		; see if x zero
	jg	posX
	neg	cx
posX:
	; Now, cx is > 0

	tst	dx
	jz	zeroY
	jg	posY
	neg	dx
posY:
	; Now, dx > 0.  Divide dx/cx
	Divide	dx, cx		; Divide dx by cx (result DX.AX is WWFixed)

	clr	bx		;lower search position
	mov	cx,90 * size WWFixed 	;upper table search position
	segmov	ds, cs
	mov	di, offset 	SplineTangentTable
	call	BinarySearchWWFixed

	mov	dx, bx
	shr	dx, 1		; divide table offset by 4
	shr	dx, 1
	clr	cx		; Now DX.CX is angle (cx is 0 but so what?)

	;ADJUST ANGLE FOR QUADRANT
adjustForQuadrant:
	pop	ax		; passed y int
	pop	bx		; passed x int
	tst	ax
	js	quad3or4	;jmp if passed y is negative
	tst	bx
	jns	done		;passed x pos, so stay in quad 1 (done)
	;quad2:
	mov	bx,180		;otherwise correct angle is 180-angle,quad 2
	jmp	subtract	;jmp to do subtraction

quad3or4:			;passed y was neg so in quad 3 or 4
	tst	bx
	jns	quad4		;jmp if passed x pos
	;quad3:
	add	dx,180		;otherwise must be in quad 3,so add 180
	jmp	done
quad4:				;in quad 4 do 360 - angle
	mov	bx,360
subtract:			;subtract angle from value in bx
	sub	bx,dx
	mov	dx,bx
done:
	.leave
	ret

zeroX:	mov	dx, 90		; if x is zero, angle is 90 degrees
	clr	cx		; (before adjust)
	jmp	adjustForQuadrant

zeroY:
	clr	dx		; if y zero, angle is 0 degrees (before adj.)
	clr	cx
	jmp	adjustForQuadrant

SplineArcTan	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BinarySearchWWfixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a binary search on a table of WWFixed

CALLED BY:
PASS:		ds:di	- segment and offset to table
		bx	- lowest table position to search
		cx	- highest table OFFSET to search
		dx.ax	- value to find (WWFixed)
RETURN:
		bx - table offset

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/89		Initial version
	cdb	4/91		Modified for WWFixed numbers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BinarySearchWWFixed		proc	near
	uses	ax

	lower	local	word
	searchVal local WWFixed
	.enter
	mov	searchVal.WWF_int, dx
	mov	searchVal.WWF_frac, ax
	mov	lower, bx		; save lower bound

startLoop:
	add	bx, cx			;bx = lower + upper
	shr	bx, 1			; bx = (lower + upper) / 2
	andnf	bx, not (size WWFixed-1) ; round bx to the nearest location
	cmp	cx, lower
	jb	done			;stop, upper < lower

	cmpdw	ds:[di][bx], searchVal, ax
	jb	truncateLowerHalf	;jmp if table < hunted
	je	done			;BINGO

	; Value in table > hunted value, so truncate upper half
	sub	bx, size WWFixed
	mov	cx, bx
	mov	bx, lower
	jmp	startLoop

truncateLowerHalf:
	add	bx, size WWFixed
	mov	lower, bx
	jmp	startLoop
done:
	.leave
	ret
BinarySearchWWFixed	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetLengthOfCurrentCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the length of the current curve.

CALLED BY:

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ax - current anchor point

RETURN:		AX - length

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Use BX.AX as a WWFixed representation for better accuracy
	Break the spline into 16 line segments (for now)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetLengthOfCurrentCurve	proc	far
	uses	bx,cx,dx,di,si,bp
	class	VisSplineClass 
	.enter

	clr	cl		; draw flags
	call	SplineGetBezierPoints
	jc	zeroLength

	SplineDerefScratchChunk di

	cmp	cl, 2	
	movP	cxdx, ds:[di].SD_bezierPoints.BP_curveStruct.CS_P0
	je	lineSegment

	; It's not a line segment, so go thru the iterations.  SD_mouse is
	; used as temp storage for the point.  I hope this doesn't cause any
	; problems!

	clrdw	ds:[di].SD_distance
	movP	ds:[di].SD_mouse, cxdx

	call	SplineCalcCoefficients
	clrdw	bxax

	; (CX, DX) is the current point
startLoop:
	add	ax, 4096		; = 1/16 of 65536
	adc	bx, 0
	call	ProducePointFromTValue
	jc	endLoop
	push	ax, bx

	mov	ax, cx
	mov	bx, dx
	xchg	cx, ds:[di].SD_mouse.P_x
	xchg	dx, ds:[di].SD_mouse.P_y
	sub	cx, ax
	sub	dx, bx

	call	SplineCalcDistance
	adddw	ds:[di].SD_distance, dxcx
	pop	ax, bx
	jmp	startLoop
endLoop:
	mov	ax, ds:[di].SD_distance.WWF_int

done:
	.leave
	ret

lineSegment:
	sub	cx, ds:[di].SD_bezierPoints.BP_curveStruct.CS_P3.P_x
	sub	dx, ds:[di].SD_bezierPoints.BP_curveStruct.CS_P3.P_y
	call	SplineCalcDistance
	mov	ax, dx
	jmp	done

zeroLength:
	clr	ax
	jmp	done

SplineGetLengthOfCurrentCurve	endp




SplineMathCode ends



