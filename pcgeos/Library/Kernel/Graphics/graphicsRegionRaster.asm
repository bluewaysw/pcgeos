COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		KLib/Graphics/RegionPath
FILE:		graphicsRegionRaster.asm

AUTHOR:		Gene Anderson, Apr  2, 1990

ROUTINES:
	Name			Description
	----			-----------
INT	RasterLine		Scan convert a line into the region.
INT	RasterBezier		Scan convert a Bezier curve into the region.
INT	SetPointInRegion	Set a single on/off point in the region.

INT	FindRegionLine		Find given line within region.
INT	FindSetRegionPoint	Find given point on line, set on/off.
INT	RegionAddSpace		Add space to region at given point.

EC	ECCheckOffset		Check that offset is within region.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/ 2/90		Initial revision

DESCRIPTION:
	Contains rasterization routines for regions/paths.

	$Id: graphicsRegionRaster.asm,v 1.1 97/04/05 01:12:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsRegionPaths	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RasterLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan convert a line into the region.
CALLED BY:	NimbusLine

PASS: 		(ax,bx) - endpoint 0 (Point)
		(cx,dx) - endpoint 1 (Point)
		es - seg addr of RegionPath
RETURN:		es - (new) seg addr of RegionPath
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
	Because of the way the region code works, the line is always
	traversed in the y direction. This means that horizontal
	lines can/must be ignored.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RasterLine	proc	near
	uses	di, si, bp, ds
	.enter

	; if the line can be trivially rejected, do it.  We can do this if
	; both are above, or both below the window.

	cmp	bx, es:[RP_y_min]		; if below, check both
	jl	checkdxbelow
	cmp	bx, es:[RP_y_max]		; if above, check other
	jle	getDirection

	; bx is above the window...
	
	cmp	dx, es:[RP_y_max]		; check this one too.
	jle	getDirection
	jmp	done
checkdxbelow:
	cmp	dx, es:[RP_y_min]
	jge	getDirection
	jmp	done
	;
	; First find the direction of the line, for winding rule
	;
getDirection:
	mov	di, RPD_DOWN			;assume line goes down
	cmp	bx, dx				;y0<y1?
	jl	flipDone			;yes, OK
	je	done				;ignore horizontals
	mov	di, RPD_UP			;it actually gos up
	xchg	ax, cx
	xchg	bx, dx				;swap ends
flipDone:
	;
	; Determine the horizontal difference for each pixel change in Y 
	;
	mov	si, dx				;si <- end y
	push	bx				;save y0
	push	ax				;save x0
	sub	ax, cx				;cx <- d(x)
	sub	bx, dx				;dx <- d(y)
	mov	dx, ax
	clr	ax				;bx.ax <- d(x)
	mov	cx, ax				;dx.cx <- d(y)
	tst	dx				;check divident for zero
	jz	postDivide
	call	GrSDivWWFixed			;dx.cx <- d(x)/d(y)
postDivide:
	mov	bp, dx
	mov	ax, cx				;bp.ax <- d(x)/d(y)
	pop	cx
	pop	dx				;dx <- start y
	segmov	ds, es
	;
	; Loop vertically until we're done with this line segment
	;
	mov	bx, di				;bx <- RegionPointDirection
	clr	di
	xchg	ax, di				;bp.di <- d(x)/d(y)
						;cx.ax <- x position
lineLoop:
	push	ax, bx, cx, dx
	rndwwf	cxax				;cx <- ROUND(cx.ax)
	call	SetPointInRegion		;set on/off point (cx,dx)
	pop	ax, bx, cx, dx
	addwwf	cxax, bpdi			;next x position
	inc	dx				;next y position
	cmp	dx, si				;end of the line?
	jl	lineLoop			;no, keep going
done:
	.leave
	ret
RasterLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RasterBezier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a bezier curve to a polyline.  Output that
		polyline to either a scan-conversion routine
		(RasterLine), or a polyline routine (CurveToPolylineCB)

CALLED BY:	CurveToPolyline,  GrRegionPathAddBezierAtCP

PASS:		ds:si - ptr to points p0-p3 (IntRegionBezier)
			and stack (grows downward to segment start)

		es - segment in which to store points. For region
			code, es:0 is a RegionPath structure.
		For curve code, es:0 is a CurvePolyline structure

		bp - offset to callback routine to call.  Routine must
			be in the same segment as RasterBezier

		CALLBACK ROUTINE:

			PASS: (ax,bx) , (cx, dx) - endpoints of one
			line segment in the curve

			RETURN: nothing

			CAN DESTROY:  ax, bx, cx, dx
		
RETURN:		es - (new) seg addr of RegionPath (or CurvePolyline)

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		This is the same algorithm the Nimbus stuff uses.
	It refers to SIGGRAPH 1986, Course Notes #4, pp 164-165.
		My addition is checking to see if the points
	are collinear and just drawing a line if they are. This
	is becomes effective as the curve flattens out, which
	happens more rapidly at larger pointsizes.

		See "An Introduction to Splines For Use In Computer
	Graphics & Geometric Modeling" (Bartels, Beatty, Barsky)
	for more about Bezier curves and about my optimization.
	(Jim has a copy)

	New End Condition (CB -- 3/16/92)

	Using ArcTangent (a single divide and a binary search on a
	90-item table), determine if (P0-P3) and (P0-P1) are in the
	same direction, opposite of (P3-P2).  If so, output P0-P3.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version
	CDB	2/4/92		changed to allow use by GrDrawSpline

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
diff	macro	dest, source
local	done
	sub	dest, source
	jge	done
	neg	dest
done:
endm


IRB_x0		equ <IRB_p0.IRP_x>
IRB_y0		equ <IRB_p0.IRP_y>
IRB_x1		equ <IRB_p1.IRP_x>
IRB_y1		equ <IRB_p1.IRP_y>
IRB_x2		equ <IRB_p2.IRP_x>
IRB_y2		equ <IRB_p2.IRP_y>
IRB_x3		equ <IRB_p3.IRP_x>
IRB_y3		equ <IRB_p3.IRP_y>

RBA_left	equ <ds:[si]>
RBA_right	equ <ds:[si][(size IntRegionBezier)]>
RBA_args	equ <ds:[di]>

RasterBezierFar	proc	far
	call	RasterBezier
	ret
RasterBezierFar	endp

RasterBezier	proc	near

	mov	di, si				;di <- ptr to passed args

	; check end conditions. 
	; If P1 is close to P0, or P2 is close to P3, then output this
	; line. 

	mov	ax, RBA_args.IRB_x1.WBF_int
	diff	ax, RBA_args.IRB_x0.WBF_int
	cmp	ax, BEZIER_POINT_TOLERANCE
	jg	notClose

	mov	ax, RBA_args.IRB_y1.WBF_int
	diff	ax, RBA_args.IRB_y0.WBF_int
	cmp	ax, BEZIER_POINT_TOLERANCE
	jg	notClose

	mov	ax, RBA_args.IRB_x3.WBF_int
	diff	ax, RBA_args.IRB_x2.WBF_int
	cmp	ax, BEZIER_POINT_TOLERANCE
	jg	notClose

	mov	ax, RBA_args.IRB_y3.WBF_int
	diff	ax, RBA_args.IRB_y2.WBF_int
	cmp	ax, BEZIER_POINT_TOLERANCE
	jle	drawSegment

notClose:

	; They're not close enough.
	; See if P1 and P2 both lie on the line segment (P0-P3).  

	push	si
	lea	si, RBA_args.IRB_p1
	call	PointOnLine?
	pop	si
	jnc	anotherLevel

	push	si
	lea	si, RBA_args.IRB_p2
	call	PointOnLine?
	pop	si
	jnc	anotherLevel

	;
	; Output P0-P3
	;
	; ds:di = ptr to IntRegionBezier.IRB_p0
	;

drawSegment:
	movwbf	axcl, RBA_args.IRB_x0
	rndwbf	axcl
	movwbf	bxcl, RBA_args.IRB_y0
	rndwbf	bxcl

	push	ax
	movwbf	cxal, RBA_args.IRB_x3
	rndwbf	cxal
	movwbf	dxal, RBA_args.IRB_y3
	rndwbf	dxal
	pop	ax

	call	bp
	mov	si, di			; nuke the scratch space
	
	ret

anotherLevel:

	mov	si, di			; nuke the scratch space
	;
	; We've got 4K or so of "stack" space.
	; Make sure we don't overflow it. 
	;
	cmp	si, (size IntRegionBezier)*2
	jb	drawSegment			;no, stop recursion
	;
	; Divide the curve at the midpoint and recurse.
	;
	sub	si, (size IntRegionBezier)*2	;allocate args for next calls
	push	si, di
	call	DivideCurve			;divide x points
	jc	checkValidity
	add	si, offset IRP_y
	add	di, offset IRP_y
	call	DivideCurve			;divide y points
checkValidity:
	pop	si, di
	jc	overflowCondition
	call	RasterBezier			;recurse to the left
	add	si, size IntRegionBezier
	call	RasterBezier			;recurse to the right
	add	si, size IntRegionBezier

	ret

	; oops.  overflowed out math.  Just draw the thing.
overflowCondition:
	add	si, (size IntRegionBezier)*2
	jmp	drawSegment
RasterBezier	endp


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next 2 pairs of coordinates from the
		IntRegionBezier structure.  Compare the pairs for
		equality

CALLED BY:

PASS:		ds:di - pointer to two PointWBFixed structs

RETURN:		ax, bx - first point
		cx, dx - second point

		ZERO flag set if pairs are equal
		ds:di - pointer to next PointWBFixed


DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextLine	proc near
	.enter

	movwbf	axcl, ds:[di].PWBF_x
	rndwbf	axcl
	movwbf	bxcl, ds:[di].PWBF_y
	rndwbf	bxcl

	add	di, size PointWBFixed

	push	ax
	movwbf	cxal, ds:[di].PWBF_x
	rndwbf	cxal
	movwbf	dxal, ds:[di].PWBF_y
	rndwbf	dxal
	pop	ax

	cmp	ax, cx
	jne	done
	cmp	bx, dx
done:
	.leave
	ret
GetNextLine	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DivideCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do parametric subdivision for x or y.
CALLED BY:	RasterBezier

PASS:		ds:di - ptr to args (IntRegionBezier) + offset for x or y
		ds:si - ptr to two sets of points (IntRegionBezier) + offset
RETURN:		carry	- set if error (coordinate calculation error)
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DivideCurve	proc	near
	uses	bp
	.enter
	mov	bl, RBA_args.IRB_x0.WBF_frac
	mov	ax, RBA_args.IRB_x0.WBF_int	;ax.bl <- x0
	mov	RBA_left.IRB_x0.WBF_frac, bl
	mov	RBA_left.IRB_x0.WBF_int, ax	;pass x0

	mov	dl, RBA_args.IRB_x1.WBF_frac
	mov	bp, RBA_args.IRB_x1.WBF_int	;bp.dl <- x1
	add	bl, dl
	adc	ax, bp				;ax.bl <- (x0+x1)
	jo	overflow
	Div2	ax, bl				;ax.bl <- sx1=(x0+x1)/2
	mov	RBA_left.IRB_x1.WBF_frac, bl
	mov	RBA_left.IRB_x1.WBF_int, ax	;pass sx1

	mov	bh, RBA_args.IRB_x2.WBF_frac
	mov	cx, RBA_args.IRB_x2.WBF_int	;cx.bh <- x2
	add	dl, bh
	adc	bp, cx				;bp.dl <- (x1+x2)
	jo	overflow
	Div2	bp, dl				;bp.dl <- t=(x1+x2)/2
	add	bl, dl
	adc	ax, bp				;ax.bl <- (sx1+t)
	jo	overflow
	Div2	ax, bl				;ax.bl <- sx2=(sx1+t)/2
	mov	RBA_left.IRB_x2.WBF_frac, bl
	mov	RBA_left.IRB_x2.WBF_int, ax	;pass sx2

	mov	bh, RBA_args.IRB_x3.WBF_frac
	mov	cx, RBA_args.IRB_x3.WBF_int	;cx.bh <- x3
	mov	RBA_right.IRB_x3.WBF_frac, bh
	mov	RBA_right.IRB_x3.WBF_int, cx	;pass x3

	add	bh, RBA_args.IRB_x2.WBF_frac
	adc	cx, RBA_args.IRB_x2.WBF_int	;cx.bh <- (x3+x2)
	jo	overflow
	Div2	cx, bh				;cx.bh <- tx2=(x2+x3)/2
	mov	RBA_right.IRB_x2.WBF_frac, bh
	mov	RBA_right.IRB_x2.WBF_int, cx	;pass tx2

	add	bh, dl
	adc	cx, bp				;cx.bh <- (t+tx2)
	jo	overflow
	Div2	cx, bh				;cx.bh <- tx1=(t+tx2)/2
	mov	RBA_right.IRB_x1.WBF_frac, bh
	mov	RBA_right.IRB_x1.WBF_int, cx	;pass tx1
	add	bl, bh
	adc	ax, cx				;ax.bl <- (sx2+tx1)
	jo	overflow
	Div2	ax, bl				;ax.bl <- sx3=(sx2+tx1)/2
	mov	RBA_left.IRB_x3.WBF_frac, bl
	mov	RBA_left.IRB_x3.WBF_int, ax	;pass sx3
	mov	RBA_right.IRB_x0.WBF_frac, bl
	mov	RBA_right.IRB_x0.WBF_int, ax	;pass sx3
	clc
done:
	.leave
	ret

overflow:
	stc
	jmp	done

DivideCurve	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPointInRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a single point in the region
CALLED BY:	LibRegionAddPoint, LibRegionAddLine

PASS:		(cx,dx) - (x,y) point
		bx - RegionPointDirection
		es - seg addr of region
RETURN:		es - (new) seg addr of region
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The RP_flags field in the RegionPath structure now contains
		a flag that indicates a lower level memory allocation failed.,
		Users of this routine should check that flag and take approp.
		action.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetPointInRegion	proc	near
	uses	si, di, bp, ds
	.enter

if (0)
	; if the point we're setting is the same as the last point we set,
	; then ignore it.  This fixes the case where connected line segments
	; are added as individual elements, so the last point of one line
	; is the same as the first point of the next line.  This yields bad
	; results if both are removed.

	cmp	cx, es:[RP_lastSet].P_x
	jne	tryToSetIt
	cmp	dx, es:[RP_lastSet].P_y
	je	done
tryToSetIt:
	mov	es:[RP_lastSet].P_x, cx
	mov	es:[RP_lastSet].P_y, dx
endif

	segmov	ds, es, ax
	;
	; Get the y coordinate of the passed point and
	; convert it into an offset into the region. Also
	; do checks to see if it changes the bounding box.
	;
	mov	ax, dx				;ax <- y point
	cmp	ax, ds:RP_y_min			;see if above top
	jl	done				;branch if clipped
	cmp	ax, ds:RP_y_max			;see if below bottom
	jge	done				;branch if clipped

	cmp	ax, ds:RP_bounds.R_top		;check against top edge
	jl	newTop
afterTop:
	cmp	ax, ds:RP_bounds.R_bottom	;check against bottom edge
	jge	newBottom
afterBottom:
	
	call	FindRegionLine			;find correct line in region
	;
	; Get the x coordinate of the passed point, and
	; convert it into an offset into the region. Also
	; do checks to see if it changes the bounding box.
	;
	mov	ax, cx				;ax <- x point
	cmp	ax, ds:RP_bounds.R_left		;check against left edge
	jl	newLeft
afterLeft:
	cmp	ax, ds:RP_bounds.R_right	;check against right edge
	jg	newRight
afterRight:
	call	FindSetRegionPoint		;find & set point on line
done:
	.leave
	ret
;
; These are done as stubs because the most common case for
; bounds checking is no or only one new bound. This way
; the more common case is a fall through at 4 cycles per, and
; the less common case is the slower branch at 12 cycles per.
;
newTop:
	mov	ds:RP_bounds.R_top, ax
	jmp	afterTop

	;
	; Must increment bottom because of imaging convention
	;
newBottom:
	mov	ds:RP_bounds.R_bottom, ax
	inc	ds:RP_bounds.R_bottom
	jmp	afterBottom

newLeft:
	mov	ds:RP_bounds.R_left, ax
	jmp	afterLeft

newRight:
	mov	ds:RP_bounds.R_right, ax
	jmp	afterRight
SetPointInRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindRegionLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find ptr to specified line in current region.
CALLED BY:	SetPointInRegion

PASS:		ds, es - seg addr of RegionPath
		ax - line # in region to find
RETURN:		es:di - ptr to start of line
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
	if (line < lastLineFound) {
		scan backwards;
	} else if (line > lastLineFound) {
		scan forwards;
	}
	return(line ptr);
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: line of the region exists
	ASSUMES: lines are MIN_REGION_LINE_SIZE bytes long.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindRegionLine	proc	near
	uses	cx
	.enter

	xchg	dx, ax				;dx <- line to find, trash AX
	mov	cx, -1				;check everything
	mov	ax, EOREGREC			;ax <- word to search for
	mov	di, ds:RP_curPtr		;di <- ptr to last known line
	cmp	dx, ds:RP_curLine		;see if after known line
	jl	backLineScan			;branch if before known line
	je	done				;branch if same
lineLoop:
EC <	cmp	es:[di], EOREGREC		;see if end of region	>
EC <	ERROR_E	GRAPHICS_REGION_LINE_NOT_FOUND	;we don't handle this	>
	cmp	ds:[di], dx			;see if correct line
	je	found
	add	di, MIN_REGION_LINE_SIZE - 2	;line at least this long
	repne	scasw				;find end of line
	jmp	lineLoop

firstLine:
	mov	di, size RegionPath		;di <- ptr to first line
foundBack:
	cld					;evil to leave this set...
found:
	mov	ds:RP_curLine, dx
	mov	ds:RP_curPtr, di		;update last line found
done:
	.leave
	ret

backLineScan:
	cmp	dx, ds:RP_y_min			;see if looking for first line
	je	firstLine			;branch if first line
	std					;scan backwards
backLineLoop:
EC <	cmp	di, size RegionPath		;have we gone too far?	>
EC <	ERROR_B	GRAPHICS_REGION_LINE_NOT_FOUND	;			>
	cmp	ds:[di], dx			;see if correct line
	je	foundBack
	sub	di, MIN_REGION_LINE_SIZE	;line at least this long
	repne	scasw				;find end of 2 lines back
	add	di, REGION_LINE_SIZE		;skip EOREGREC to line # 1 back
EC <	call	ECCheckOffset			;			>
	jmp	backLineLoop

FindRegionLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindSetRegionPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find and set the specified point on a line.
CALLED BY:	SetPointInRegion

PASS:		es:di - ptr to line in region
		ds, es - seg addr of region
		ax - x coordinate of point to find
		bx - up/down value		
RETURN:		carry	- set if couldn't allocate memory
			  else es - (new) seg addr of region
DESTROYED:	ax, bx, cx, dx, di, si, bp

PSEUDO CODE/STRATEGY:
	while (!found) {
	    if (unused space) {
		found = TRUE;
	    } else if (end of line) {
		AddSpace();			/* add space at end of line */
		found = TRUE;
	    } else if (value < passed coord) {
		AddSpace();			/* add space in middle */
		found = TRUE;
	    } else {
	        point++;			/* advance to next point */
	    }
	}
	SetPoint(point);
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/28/90		Initial version
	don	7/22/91		Added support for WINDING rule

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <RFR_ODD_EVEN eq 0>

FindSetRegionPoint	proc	near
	.enter

	; Some set-up work
	;
	xchg	bx, ax				;bx <- x coordinate to set
	xchg	bp, ax				;bp <- up/down value, trash AX
	mov	dx, 2				;bytes/point for ODD_EVEN rule
	tst	es:[RP_fillRule]		;ODD_EVEN or WINDING ??
	jz	pointLoop			;ODD_EVEN, so go for it
	mov	dx, 4				;bytes/point for WINDING rule
	sub	di, 2				;fudge factor to start properly

	; Loop thorugh the line to find where to insert point
	;
pointLoop:
	add	di, dx				;advance to next point
	mov	ax, ds:[di]			;ax <- x point
	cmp	ax, UNUSED_POINT		;see if vacant
	je	placeFound			;use the vacant spot
	cmp	ax, EOREGREC			;see if end of line
	je	addSpace			;end of line, bummer
	cmp	ax, bx				;check against coord
	jg	foundRect			;found the right area
	jne	pointLoop			;else go try again

	; The point on the line has been set already. We must unset it
	; or die for the ODD_EVEN rule, or maintain the up/down count
	; for the WINDING rule. We must also ensure that the on/off
	; points are contiguous, else the loop above will not work!
	; 
	tst	es:[RP_fillRule]		;ODD_EVEN or WINDING
	jnz	unsetWinding			;WINDING, so go to it
	mov	si, di				;destination => ES:DI
	add	si, 2				;source => DS:SI
movePoints:
	lodsw					;point or marker => AX
EC <	call	ECCheckOffset			;check within block>
	stosw					;store in previous position
	shr	ax, 1
	cmp	ax, (EOREGREC shr 1)		;EOREGREC or UNUSED_POINT ??
	jne	movePoints			;neither, so continue
	mov	es:[di][-2], UNUSED_POINT	;mark point as unused
	jmp	doneOK
unsetWinding:
	add	ds:[di+2], bp			;add in up/down value
	jmp	doneOK

	; Add space at the current location, so that we can insert
	; the point. We will need to move any data after this point down
	; by the number of bytes we insert
	;
addSpace:
	xchg	ax, dx				;ax <- # of bytes to add
	call	RegionAddSpace
	jc	done				; couldn't allocate.  bummer.
placeFound:
EC <	call	ECCheckOffset			;check within block>
	mov	ds:[di], bx			;set the on/off point
	tst	es:[RP_fillRule]		;ODD_EVEN or WINDING
	jz	doneOK				;ODD_EVEN, so we're done
	mov	ds:[di+2], bp			;store the up/down value
doneOK:
	clc
done:
	.leave
	ret

	; We've found the correct portion of the line. We need
	; to shift the rest of the line down to make space, or
	; if we can't do that, shift the whole region to make space.
	;
foundRect:
	mov	si, di				;si <- ptr to location
spaceLoop:
	add	si, dx				;skip one point
	mov	ax, ds:[si]
	cmp	ax, EOREGREC			;end of line?
	je	addSpace			;yes, we've to to resize
	cmp	ax, UNUSED_POINT		;vacant space?
	jne	spaceLoop			;no, try again

	; We've found a vacant spot on the line. We need to shift
	; everything after our insertion point up one word.
	;
	push	di
	mov	cx, si
	sub	cx, di				;cx <- # of bytes to move
	shr	cx, 1				;cx <- # of words to move
	add	si, dx
	sub	si, 2				;hack due to size differential
	mov	di, si				;es:di <- dest
EC <	call	ECCheckOffset			;check within block>
	sub	si, dx				;ds:si <- source
	std					;work backwards
	rep	movsw				;shift me jesus
	cld					;must reset direction flag
	pop	di
	jmp	placeFound
FindSetRegionPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegionAddSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add space to our region definition.
CALLED BY:	FindSetRegionPoint

PASS:		es:di - ptr to insertion point
		ds, es - seg addr of region
		ax - # of bytes to add
RETURN:		carry	- set if some problem allocating memory
			  else ds, es - (new) seg addr of region
DESTROYED:	ax, cx, si

PSEUDO CODE/STRATEGY:
	if (!space at end of block) {
		Realloc(block);
	}
	for (s =
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/28/90		Initial version
	don	4/16/91		Now works with additional bytes other than 2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RegionAddSpace	proc	near
	uses	bx, bp, di
	.enter

	; if we're already in trouble, don't add to it.

	test	ds:[RP_flags], mask RPF_CANT_ALLOC
	jnz	allocProblem

	; See if we need to re-allocate the block
	;
	mov	cx, ds:RP_endPtr		;cx <- amount we're using
	add	cx, ax				;cx <- new size
	xchg	bp, ax				;bp <- amount to add
	mov	ax, ds:RP_size			;ax <- current block size
	mov	bx, ds:RP_handle		;bx <- handle of block
	mov	ds:RP_endPtr, cx		;save new size
	cmp	cx, ax				;see if enough left over
	jbe	insertSpace			;branch if enough room

	; Re-allocate by a standard large amount, to avoid repeated calls
	;
	add	cx, REGION_BLOCK_REALLOC_INC_SIZE ;up size so we don't thrash
NEC <	jc	allocProblem					>
EC <	ERROR_C	GRAPHICS_REGION_TOO_BIG		;		>
	mov	ds:RP_size, cx			;save new size
	xchg	ax, cx				;ax <- size to realloc
	clr	ch				; want to handle errors
	call	MemReAlloc			;reallocate as necessary
	jc	allocProblem			; if can't allocate, bail
	mov	es, ax				;es <- seg addr of block
	mov	ds, ax

	; Copy things below allocated space (from bottom of memory towards top)
	; Assume: BP = # of bytes to insert
	;         DI = insertion point
	;
insertSpace:
	mov	cx, ds:RP_endPtr		;cx <- new size
	mov	si, cx
	sub	cx, di				;cx <- # of bytes to shift
	shr	cx, 1				;cx <- # of words to shift
EC <	ERROR_C	GRAPHICS_REGION_ODD_SIZE	;should always be even>
	dec	si
	dec	si				
	mov	di, si				;destination = newSize - 2
EC <	call	ECCheckOffset			;check within block	>
	sub	si, bp				;source = destination - inserted
EC <	xchg	di, si							>
EC <	call	ECCheckOffset			;check within block	>
EC <	xchg	di, si							>
	std
	rep	movsw				;shift me jesus
	cld
	clc					; signal no alloc problems
done:
	.leave
	ret

	; There is some problem allocating the necessary memory.  Instead of
	; dying, as we did before, let's set a flag to say that things are
	; hosed and back it all out.  At a point higher up we'll re-alloc
	; the block to be just a rectangle.
allocProblem:
	or	ds:RP_flags, mask RPF_CANT_ALLOC ; set the flag
	stc					; signal alloc problems
	jmp	done
RegionAddSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that an offset is within the region block.
CALLED BY:	INTERNAL

PASS:		di - offset to check
		es - segment address of RegionPath
RETURN:		none
DESTROYED:	none, not even flags

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK
ECCheckOffset	proc	near
	uses	ax, bx
	.enter
	pushf

	call	SysGetECLevel			;ax <- ErrorCheckingFlags
	test	ax, mask ECF_GRAPHICS		;checking regions?
	jz	skipCheck			;no, don't bother

	cmp	di, ds:RP_size			;see if bigger than we thought
	ERROR_AE GRAPHICS_REGION_OVERDOSE
	cmp	di, ds:RP_endPtr		;see if bigger than we though
	ERROR_AE GRAPHICS_REGION_OVERDOSE
	mov	bx, ds:RP_handle		;bx <- handle of region block
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	cmp	di, ax				;see if bigger than block
	ERROR_AE GRAPHICS_REGION_OVERDOSE

skipCheck:
	popf
	.leave
	ret
ECCheckOffset	endp
endif





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CurveToPolylineCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine in the "CurveToPolyline" process

CALLED BY:	RasterBezier via CurveToPolyline

PASS:		endpoints of next line segment: 
		ax,bx - P0
		cx,dx - P1
		es - segment of CurvePolylinePoints

RETURN:		es - new segment of CurvePolylinePoints

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Points will not be added to block if there's not enough
	memory.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CURVE_POLYLINE_BLOCK_MAX_SIZE	equ	40960
; This is a pretty huge value, but since we're allowing MemReAlloc to
; return errors, such a big block will only be created if the memory
; is available.


CurveToPolylineCB	proc near	
	uses	di
	.enter

	; Make sure there's enough room for at least 2 more points

	mov	di, es:[CP_curPtr]
	add	di, 2 * size Point
	cmp	di, es:[CP_size]
	jbe	afterAlloc

	;
	; reallocate by a large amount, unless the block is already
	; bigger than it should be.
	;

	push	ax, bx, cx
	mov	ax, es:[CP_size]
	cmp	ax, CURVE_POLYLINE_BLOCK_MAX_SIZE
	jae	errorPop

	add	ax, CURVE_POLYLINE_SIZE_INCREMENT

	mov	bx, es:[CP_handle]
	clr	cx
	call	MemReAlloc
	jc	errorPop

	;
	; Now that we've successfully reallocated, store the new size.
	;

	mov	es, ax
	add	es:[CP_size], CURVE_POLYLINE_SIZE_INCREMENT
	pop	ax, bx, cx

afterAlloc:

	; Get the pointer to the next set of points.  If no points
	; have been stored yet, then store the first point, otherwise,
	; only store the second point

	mov	di, es:[CP_curPtr]
	cmp	di, size CurvePolyline
	ja	afterFirst

	; store the first point (ax, bx)

	inc	es:[CP_numPoints]
	stosw
	mov_tr	ax, bx
	stosw

afterFirst:

	mov_tr	ax, cx
	stosw
	mov_tr	ax, dx
	stosw
	inc	es:[CP_numPoints]
	mov	es:[CP_curPtr], di
done:
	.leave
	ret


errorPop:
	;
	; We don't have the memory to add any more points to this
	; block.  What can we do??? Nothing -- the polyline just won't
	; get drawn correctly!
	;

	pop	ax, bx, cx
	jmp	done
CurveToPolylineCB	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointOnLine?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the point is on the line

CALLED BY:	RasterBezier

PASS:		ds:di - RasterBezierArgs
		ds:[si] - point T

RETURN:		carry SET if on line, clear otherwise

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	
	Ripped off from Graphics Gems, Fast 2D point-on-line test
	(p 49-50)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This procedure was written as an April Fool's joke.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PX = RBA_args.IRB_x0.WBF_int
QX = RBA_args.IRB_y0.WBF_int
PY = RBA_args.IRB_x3.WBF_int
QY = RBA_args.IRB_y3.WBF_int
TX = ds:[si].IRP_x.WBF_int
TY = ds:[si].IRP_x.WBF_int

max	macro	dest, source
local	done
	cmp	dest, source
	jge	done 
	mov	source, dest
done:
endm



PointOnLine?	proc near
	.enter
	mov	ax, QY
	sub	ax, PY
	mov	bx, TX
	sub	bx, PX
	imul	bx			; dx:ax - result

	pushdw	dxax

	mov	ax, TY
	sub	ax, PY
	mov	bx, QX
	sub	bx, PX
	imul	bx

	popdw	bxcx
	subdw	dxax, bxcx
	
	tst	dx
	jns	posDXAX
	negdw	dxax
posDXAX:

	mov	bx, QX
	diff	bx, PX

	mov	cx, QY
	diff	cx, PY

	max	bx, cx
	clr	cx

	jgdw	dxax, cxbx, notOnLine

;-----------------------------------------------------------------------------
;	RE-DEFINE the CONSTANTS		
;-----------------------------------------------------------------------------
 
	mov	ax, PX
	mov	bx, PY
	mov	cx, QX
	mov	dx, QY

PX = ax
PY = bx
QX = cx
QY = dx

	; If Qx < Px and Px < Tx, not on line

	cmp	QX, PX
	jge	test2

	cmp	PX, TX
	jl	notOnLine

test2:
	; If Qy < PY and PY < TY, not on line

	cmp 	QY, PY
	jge	test3

	cmp	PY, TY
	jl	notOnLine	

test3:
	; If TX < PX and PX < QX, not on line

	cmp	TX, PX
	jge	test4

	cmp	PX, QX
	jl	notOnLine

test4:
	; If TY < PY and PY < QY, not on line
	cmp	TY, PY
	jge	test5

	cmp	PY, QY
	jl	notOnLine

test5:
	; If PX < QX and QX < TX, not on line
	cmp	PX, QX
	jge	test6

	cmp	QX, TX
	jl	notOnLine

test6:
	; If PY < QY and QY < TY, not on line
	cmp	PY, QY
	jge	test7

	cmp	QY, TY
	jl	notOnLine

test7:
	; If TX < QX and QX < PX, not on line
	cmp	TX, QX
	jge	test8

	cmp	QX, PX
	jl	notOnLine

test8:
	; If TY < QY and QY < PY, not on line
	cmp	TY, QY
	jge	onLine

	cmp	QY, PY
	jge	onLine

notOnLine:
	clc
done:
	.leave
	ret

onLine:
	stc
	jmp	done

PointOnLine?	endp



GraphicsRegionPaths	ends
