COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	Pen library
MODULE:		Ink
FILE:		inkClassEdit.asm

AUTHOR:		Andrew Wilson, Oct 10, 1994

ROUTINES:
	Name			Description
	----			-----------
	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of inkClass.asm

DESCRIPTION:
	Method handlers for ink class.	

	$Id: inkClassEdit.asm,v 1.1 97/04/05 01:27:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkEdit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if undo is active.

CALLED BY:	GLOBAL
PASS:		*ds:si - Ink object
RETURN:	        zero flag zet if no undo (jz noUndo)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForUndo	proc	near	uses	si
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	test	ds:[si].II_flags, mask IF_HAS_UNDO
	.leave
	ret
CheckForUndo	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectionStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the start of the selection

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		ax, bx - start of selection
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectionStart	proc	near
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ax, ds:[di].II_selectBounds.R_left
	mov	bx, ds:[di].II_selectBounds.R_top
	.leave
	ret
GetSelectionStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectionBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the bounds of the selection.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		ax, bx, cx, dx - bounds of selection
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectionBounds	proc	near
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ax, ds:[di].II_selectBounds.R_left
	mov	bx, ds:[di].II_selectBounds.R_top
	mov	cx, ds:[di].II_selectBounds.R_right
	mov	dx, ds:[di].II_selectBounds.R_bottom
	.leave
	ret
GetSelectionBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNumPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine holds the # points in the array

CALLED BY:	GLOBAL
PASS:		*ds:si - ptr to Ink object's instance data
RETURN:		ax - # points in array
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNumPoints	proc	far	uses	si, cx
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>
	clr	ax			;If no segment array, exit	
	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	mov	si, ds:[si].II_segments
	tst	si
	jz	exit
	call	ChunkArrayGetCount	;Else, get the # elements in it,
	mov_tr	ax, cx			; and return it in AX
exit:
	.leave
	ret
GetNumPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkInkDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks the object as dirty, if necessary. If it wasn't dirty
		before, sends out the dirty notification.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkInkDirty	proc	near	uses	di
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	test	ds:[di].II_flags, mask IF_DIRTY
	jnz	exit
	ornf	ds:[di].II_flags, mask IF_DIRTY
	push	ax, bx, si
	mov	ax, ds:[di].II_dirtyMsg
	movdw	bxsi, ds:[di].II_dirtyOutput
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, bx, si
exit:
	.leave
	ret
MarkInkDirty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCollinearTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if points A and C are both
		above/to the left/to the right/below point B

CALLED BY:	GLOBAL
PASS:		bx - x coord of point c
		dx - y coord of point c
		ds:di - ptr to end of Point array (point B)
RETURN:		carry set if not collinear
DESTROYED:	ax, cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoCollinearTrivialReject	proc	near
	mov	ax, ds:[di][-(size Point)].P_x
	mov	cx, bx
	sub	cx, ax				;CX <- delta X of line seg CB
	sub	ax, ds:[di][-(size Point * 2)].P_x ;AX <- delta X of line seg BA
	xor	ax, cx
	js	notCollinear
	jz	checkY

	cmp	ax, cx			;AX == CX if pre-xor AX was == 0.
	jz	notCollinear
	jcxz	notCollinear

checkY:
	mov	ax, ds:[di][-(size Point)].P_y
	mov	cx, dx
	sub	cx, ax				;CX <- delta Y of line seg CB
	sub	ax, ds:[di][-(size Point * 2)].P_y ;AX <- delta Y of line seg BA

	xor	ax, cx			;Clears the carry
	js	notCollinear
	jz	exit

	jcxz	notCollinear
	cmp	ax, cx			;AX == CX if pre-xor AX was == 0.
	clc
	jnz	exit

notCollinear:
	stc
exit:
	ret

DoCollinearTrivialReject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfCollinear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed point is collinear with the
		previous 2...

CALLED BY:	GLOBAL
PASS:		ds:bx - ptr to ChunkArrayHeader of line segment
		ds:di - ptr past last point
		cx,dx - point to check
RETURN:		carry set if collinear (ds:di - ptr to previous point)
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:
	First, make sure current line segment has *at least* 2 points 
	(not counting one we want to add).

	If so, we have 3 points A,B,C (C is the current one). 

	Then, make sure pts A and C are not on the same side of pt B
	(trivial reject).

	Compute slopes from A to B and B to C. If they are equal, then
	points are collinear

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfCollinear	proc	near	uses	bx, cx, dx
	slope	local	WWFixed
	.enter
	mov	bx, ds:[bx].CAH_count
	xchg	bx, cx			;CX <- # items in array
					;BX <- x coord of point
	jcxz	notCollinear		;If no items in array, branch

;	Calculate the slope from this point and the previous point, and
;	the previous point and the point before that. If equal, all three
;	points are collinear.

	mov_tr	ax, cx
	dec	ax
	jz	notCollinear		;If only one element, exit
	test	ds:[di][-(size Point)].P_x, 0x8000
	jnz	notCollinear		;Exit if line segment has < 1 point
	test	ds:[di][-(size Point * 2)].P_x, 0x8000
	jnz	notCollinear		;Exit if line segment has < 2 points

;	Do trivial reject (make sure point B is between points A and C)

	call	DoCollinearTrivialReject
	jc	notCollinear

	clr	ax
	clr	cx
	sub	bx, ds:[di][-(size Point)].P_x	 ;BX:AX <- deltaX for this obj
	tst	bx				;Avoid divide by zero
	jz	checkForDeltaXZero
	sub	dx, ds:[di][-(size Point)].P_y	;DX:CX <- deltaY for this obj

;	Calcluate the slope between current point and previous

	call	GrSDivWWFixed		;DX:CX <- slope
	movdw	slope, dxcx
	mov	bx, ds:[di][-(size Point)].P_x
	sub	bx, ds:[di][-(size Point * 2)].P_x
	jz	notCollinear
	mov	dx, ds:[di][-(size Point)].P_y
	sub	dx, ds:[di][-(size Point * 2)].P_y
	clr	cx

;	Calculate the slope between the previous 2 points

	call	GrSDivWWFixed		;
	cmpdw	dxcx, slope
	stc
	jz	exit
notCollinear:
	clc
exit:
	.leave
	ret
checkForDeltaXZero:
	mov	bx, ds:[di][-(size Point)].P_x
	sub	bx, ds:[di][-(size Point * 2)].P_x
	jnz	notCollinear
	stc
	jmp	exit
CheckIfCollinear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a coordinate to the list

CALLED BY:	GLOBAL
PASS:		cx, dx - X, Y coordinates to add
		bx - chunk handle of line segment
		ds:di - ptr to next data to store
RETURN:
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddCoord	proc	near	uses	bx, ax
	.enter

	call	CheckIfCollinear
	jc	storePoint		;If this is collinear, just overwrite
					; previous point.

;	Append a new point to the end

	add	di, size Point
	inc	ds:[bx].CAH_count

storePoint:

;	Coordinates cannot exceed 15 bits, as we use the high bit to
;	designate that the coordinate ends the current line segment.
EC <	tst	cx							>
EC <	ERROR_S	INK_COORD_EXCEEDED_15_BITS				>
EC <	tst	dx							>
EC <	ERROR_S	INK_COORD_EXCEEDED_15_BITS				>

	mov	ds:[di][-(size Point)].P_x, cx
	mov	ds:[di][-(size Point)].P_y, dx
	.leave
	ret
AddCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if point and subsequent point are on same side
		of erase region.

CALLED BY:	GLOBAL
PASS:		ss:[bp] - ptr to EraseCallbackFrame
		cx, dx - coord of point #1
		ax, bx - coord of point #2
RETURN:		carry set if no trivial reject
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoTrivialReject	proc	near
;	If both end points are to left of erase rectangle, then trivial
;	reject

	cmp	cx, ss:[bp].R_left
	jnb	checkToRight
	cmp	ax, ss:[bp].R_left
	jb	trivialReject
checkToRight:
;	If both end points are to right of erase rectangle, then trivial
;	reject

	cmp	cx, ss:[bp].R_right
	jna	checkToTop
	cmp	ax, ss:[bp].R_right
	ja	trivialReject

checkToTop:
;	If both end points are above erase rectangle, then trivial
;	reject

	cmp	dx, ss:[bp].R_top
	jnb	checkToBottom
	cmp	bx, ss:[bp].R_top
	jb	trivialReject
checkToBottom:
;	If both end points are below erase rectangle, then trivial
;	reject

	cmp	dx, ss:[bp].R_bottom
	jna	noTrivialReject
	cmp	bx, ss:[bp].R_bottom
	jna	noTrivialReject

trivialReject:
	clc
	ret
noTrivialReject:
	stc
	ret
DoTrivialReject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfPointInBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the point is in the erase rectangle.

CALLED BY:	GLOBAL
PASS:		ss:bp - ptr to rectangle
		cx, dx - ptr to point to check
RETURN:		carry set if in erase rectangle
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfPointInBounds	proc	near
EC <	tst	cx							>
EC <	ERROR_S	CLIP_ERROR						>
	cmp	cx, ss:[bp].ECF_bounds.R_left
	jb	outExit
	cmp	cx, ss:[bp].ECF_bounds.R_right
	ja	outExit
	cmp	dx, ss:[bp].ECF_bounds.R_top
	jb	outExit
	cmp	dx, ss:[bp].ECF_bounds.R_bottom
	ja	outExit
	stc
	ret
outExit:
	clc
	ret
CheckIfPointInBounds	endp

if	ERROR_CHECK
ECCheckBoundsESDI	proc	near	uses	ds, si
	.enter
	segmov	ds, es
	mov	si, di
	call	ECCheckBounds
	.leave
	ret
ECCheckBoundsESDI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckClipping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the lines are clipped correctly

CALLED BY:	GLOBAL
PASS:		ss:bp - EraseCallbackFrame
		*ds:si - chunk array
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckClipping	proc	near
	uses	ax, cx, dx, bp, es, bx, di
	.enter		
	tst	si
	jz	exit
	mov	bx, cs
	mov	di, offset CheckIfPointInBoundsCallback
	call	ChunkArrayEnum
exit:
	.leave
	ret
ECCheckClipping	endp
CheckIfPointInBoundsCallback	proc	far
	mov	cx, ds:[di].P_x
	mov	dx, ds:[di].P_y
	tst	dx
	ERROR_S	CLIP_ERROR
	andnf	cx, 0x7fff
	call	CheckIfPointInBounds
	ERROR_C	CLIP_ERROR


	ret
CheckIfPointInBoundsCallback	endp
endif	;ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipPointsToClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clips points in source array to passed bounds, and saves them
		in the destination array (throws out points/segments outside
		of the passed bounds).

CALLED BY:	GLOBAL
PASS:		ds:si - source array
		es:di - dest array in PointBlockHeader
		cx - # points
		ss:bp - Rectangle to clip to
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipPointsToClipRect	proc	far	uses	bx
	.enter

	mov	es:[PBH_numPoints], cx
top:
;
;	If the point is in bounds, add it to the dest array
;

	mov	cx, ds:[si].P_x
	mov	dx, ds:[si].P_y
	andnf	cx, 0x7fff
	call	CheckIfPointInBounds
	mov	cx, ds:[si].P_x
	jnc	outOfBounds

	call	appendPoint

gotoNext:
	add	si, size Point
	dec	es:[PBH_numPoints]
	jnz	top


done:

;	Calc the # points added to dest array
;	numPoints = (offset of next entry in array) / size Point

	sub	di, size PointBlockHeader
.assert size Point eq 4
	shr	di, 1
	shr	di, 1
	mov	es:[PBH_numPoints], di
	.leave
	ret

outOfBounds:
;
;	Else, the point is out of bounds:
;
;		If the last point in the dest array was not an end segment:
;			Clip the line segment from the previous point and
;			this point to the bounds rectangle.
;
;		If the next point in the source array is in bounds:
;			Clip the line segment from this point to the next
;			point to the bounds rectangle.
;	
;
	cmp	di, size PointBlockHeader
	jz	wasEndSegment
	cmp	es:[di-size Point].P_x, 0
	js	wasEndSegment


;	Find the point of intersection of the line segment and the
;	clip rectangle.

	andnf	cx, 0x7fff			
	mov	ax, es:[di - size Point].P_x
	mov	bx, es:[di - size Point].P_y
	add	ax, ss:[bp].R_left	;Convert the prev point from the coord
	add	bx, ss:[bp].R_top	; system of the clip rect to that of
					; the obj.
	xchgdw	axbx, cxdx		;AX,BX <- point outside rect
					;CX,DX <- point inside rect
	call	FindInnerIntersection
EC <	ERROR_NC	-1						>


;	If the point of intersection is the *start* of the line segment,
;	do not add a new point, but just make the start of the line segment
;	be the end also (it is illegal to have two points at the same
;	coordinate).


	sub	ax, ss:[bp].R_left
	sub	bx, ss:[bp].R_top
	cmp	ax, es:[di - size Point].P_x
	jne	setDest
	cmp	bx, es:[di - size Point].P_y
	je	afterPointAppend
setDest:
EC <	call	ECCheckBoundsESDI					>
EC <	tst	ax							>
EC <	ERROR_S	-1							>
EC <	tst	bx							>
EC <	ERROR_S	NEGATIVE_Y_COORDINATE					>

	mov	es:[di].P_x, ax
	mov	es:[di].P_y, bx
	add	di, size Point

afterPointAppend:
	ornf	es:[di - size Point].P_x, 0x8000
	mov	cx, ds:[si].P_x
	mov	dx, ds:[si].P_y
wasEndSegment:


;	Now we have a point out of the bounds of the clip rectangle. We want
;	to skip points until:
;
;	1) We hit the end of a line segment
;	2) We hit the end of the source array
;	3) We encounter a point that is within the bounds
;	4) The line segment crosses through the clip region, but neither end
;	   point is in the region.
;	

	tst	cx				;If this was an end segment,
	LONG js	gotoNext			; goto the next point.

;	We are out of bounds, and in the middle of a line. We know that
;	we aren't at the end of the array yet, as the last point in the
;	array is always a end point.
;
	mov	ax, ds:[si][size Point].P_x	;AX,BX <- next point in line
	andnf	ax, 0x7fff
	mov	bx, ds:[si][size Point].P_y
	call	DoTrivialReject
	jc	checkForIntersection
noIntersection:

	add	si, size Point
	mov	cx, ds:[si].P_x
	mov	dx, ds:[si].P_y
	dec	es:[PBH_numPoints]
	jnz	wasEndSegment
	jmp	done
checkForIntersection:

;	Add a point on the clip boundary between this point and the next
;	point.

	xchgdw	cxdx, axbx		;AX,BX <- point outside region
					;CX,DX <- next point
	call	FindInnerIntersection
	jnc	noIntersection
	movdw	cxdx, axbx
	call	appendPoint
	jmp	gotoNext

appendPoint:

;	Copy the points from source to dest, after transforming them to be
;	offset from the upper left corner of the bounds

	tst	cx
	pushf			;Save End-of-line-segment marker
	andnf	cx, 0x7fff
	sub	cx, ss:[bp].R_left
EC <	ERROR_S	-1							>
	sub	dx, ss:[bp].R_top
EC <	ERROR_S	NEGATIVE_Y_COORDINATE					>
	popf
	jns	10$		;Restore End-of-line-segment marker	
	ornf	cx, 0x8000
10$:
EC <	call	ECCheckBoundsESDI					>
	mov	es:[di].P_x, cx
	mov	es:[di].P_y, dx
	add	di, size Point
	retn
	
ClipPointsToClipRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindOuterIntersection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes the intersection between the erase rectangle and
		the passed line segment. It returns the intersection point
		outside the erase rect

CALLED BY:	GLOBAL
PASS:		(ax, bx) to (cx, dx) - line segment to check
			(ax,bx) *must* be outside of erase region
			X0,Y0 = ax, bx
			X1,Y1 = cx, dx
		ss:bp - ptr to rectangle
		
RETURN:		carry set if intersection
			ax, bx - first point of intersection
				(outside of erase rect)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindOuterIntersection	proc	near	uses	cx, dx
	.enter

	call	FindIntersection
	.leave
	ret
FindOuterIntersection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindInnerIntersection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes the intersection between the erase rectangle and
		the passed line segment. It returns the intersection point
		outside the erase rect

CALLED BY:	GLOBAL
PASS:		(ax, bx) to (cx, dx) - line segment to check
			(ax,bx) *must* be outside of erase region
			X0,Y0 = ax, bx
			X1,Y1 = cx, dx
		ss:bp - ptr to rectangle
		
RETURN:		carry set if intersection
			ax, bx - first point of intersection
				(outside of erase rect)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindInnerIntersection	proc	near	uses	cx, dx
	.enter
	call	FindIntersection
	movdw	axbx, cxdx
	.leave
	ret
FindInnerIntersection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindIntersection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes the intersection between the erase rectangle and
		the passed line segment

CALLED BY:	GLOBAL
PASS:		(ax, bx) to (cx, dx) - line segment to check
			(ax,bx) *must* be outside of erase region
			X0,Y0 = ax, bx
			X1,Y1 = cx, dx
		ss:bp - ptr to rectangle
		
RETURN:		carry set if intersection
			ax, bx - first point of intersection
				(outside of erase rect)
			cx, dx - first point of intersection (inside erase rect)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

	Wow, this may change, but here goes:

	Find parametric equations for the line segment of the form:
		X = X0 + T*A
		Y = Y0 + T*B

	pseudo code (x0,y0 *must* be outside of erase region)

		oldPoint.P_x = x0
		oldPoint.P_y = y0
		if (x1-x0 > y1-y0)
		{
			max = abs(x1-x0);
			deltaY = (y1-y0)/max
			deltaX = (x1-x0)/max; (+ or - 1)
		} else {
			max = abs(y1-y0);
			deltaX = (x1-x0)/max;
			deltaY = (y1-y0)/max; (+ or - 1)
		}
				newX = oldPoint.P_x;
				newY = oldPoint.P_y;
			for (t=0;t<=max;t++) {
				newX += deltaX;
				newY += deltaY;	
				if (InEraseRegion(newX, newY))
					return(TRUE, oldPoint.P_x, oldPoint.P_y);
				oldPoint.P_x = newX;
				oldPoint.P_y = newY;	
			}				
			return (FALSE, oldPoint.P_x, oldPoint.P_y);
		}
			


		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindIntersection	proc	near	uses	di
EC <	origPoint1	local	Point					>
EC <	origPoint2	local	Point					>
	deltaX	local	WWFixed
	deltaY	local	WWFixed
	oldPointX	local	WWFixed
	oldPointY	local	WWFixed
	finalXCoord	local	word
	finalYCoord	local	word

EC <	xchg	ax, cx							>
EC <	xchg	bx, dx							>
EC <	call	CheckIfPointInBounds					>
EC <	ERROR_C FIND_INTERSECTION_PASSED_STARTING_POINT_IN_ERASE_RECT	>
EC <	xchg	ax, cx							>
EC <	xchg	bx, dx							>
	push	si
	mov	si, bp
	.enter
EC <	mov	origPoint1.P_x, ax					>
EC <	mov	origPoint1.P_y, bx					>
EC <	mov	origPoint2.P_x, cx					>
EC <	mov	origPoint2.P_y, dx					>

	mov	finalXCoord, cx
	mov	finalYCoord, dx
	mov	oldPointX.WWF_int, ax
	mov	oldPointY.WWF_int, bx
	clr	di
	mov	deltaX.WWF_frac, di
	mov	deltaY.WWF_frac, di
	mov	oldPointX.WWF_frac, di
	mov	oldPointY.WWF_frac, di

;
;	Load deltaX/deltaY, and load DI with the loop variable
;	DI = Max(y1-y0, x1-x0)
;

	sub	dx, bx			;DX <- y1-y0
	sub	cx, ax			;CX <- x1-x0

;	DI <- Max(|(X1-X0)|, |(Y1-Y0)|)

	clr	ax
	push	cx, dx
	mov	deltaX.WWF_int, 1
	tst	cx			;CX <- |CX|
	jns	10$
	mov	deltaX.WWF_int, -1
	neg	cx
10$:
	mov	deltaY.WWF_int, 1
	tst	dx			;DX <- |DX|
	jns	15$
	mov	deltaY.WWF_int, -1
	neg	dx
15$:
	mov	di, cx			;DI <- |X1-X0|
	cmp	cx, dx
	ja	20$
	mov	di, dx 			;DI <- |Y1-Y0|
20$:
	pop	cx, dx
	mov	bx, di			;BX:AX <- max(abs(x1-x0, y1-y0))
	ja	x1x0gty1y0		;Branch if |X1-X0| > |Y1-Y0|
	mov	dx, cx			;DX:CX <- X1-X0
       	clr	cx
	call	GrSDivWWFixed		;DX:CX <- (X1-X0)/(Y1-Y0)
	movdw	deltaX,dxcx
	jmp	doLoop
x1x0gty1y0:
	clr	cx			;DX:CX <- Y1-Y0
	call	GrSDivWWFixed
	movdw	deltaY, dxcx
doLoop:
;	CX:AX <- newX
;	DX:BX <- newY

	movdw	cxax, oldPointX
	movdw	dxbx, oldPointY
loopTop:
	adddw	cxax, deltaX		;newX += deltaX
	adddw	dxbx, deltaY		;newY += deltaY
	xchg	si, bp
	call	CheckIfPointInBounds	;If (InEraseRegion (newX, newY))
	xchg	si, bp
	jc	foundIntersection	;   return(TRUE)	
	movdw	oldPointX, cxax		;oldPoint.P_x = newX
	movdw	oldPointY, dxbx		;oldPoint.P_y = newY
	dec	di			;
	jnz	loopTop			;Branch back up or exit with carry
					; clear
					;Do final check - test last point in
					; line, as we might not be there yet
					; due to round-off error...
	mov	ax, cx
	mov	bx, dx
	mov	cx, finalXCoord		;
	mov	dx, finalYCoord
	xchg	si, bp
	call	CheckIfPointInBounds	;Sets carry if this last point
					; *was* in the region.
	xchg	si, bp
exit:
EC <	jnc	noInt							>
EC <	xchg	si, bp							>
EC <	call	CheckIfPointInBounds					>
EC <	xchg	si, bp							>
EC <	ERROR_NC	CLIP_ERROR					>
EC <	xchgdw	axbx, cxdx						>
EC <	xchg	si, bp							>
EC <	call	CheckIfPointInBounds					>
EC <	xchg	si, bp							>
EC <	ERROR_C	CLIP_ERROR						>
EC <	xchgdw	axbx, cxdx						>
EC <	stc								>
EC <noInt:								>
	.leave
	pop	si
	ret
foundIntersection:
	mov	ax, oldPointX.WWF_int
	mov	bx, oldPointY.WWF_int
	jmp	exit			;Exit with carry set
	
FindIntersection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TerminateLineSegmentAtClipBoundary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminates the current line segment at the passed point,
		adding a new point if necessary.

CALLED BY:	GLOBAL
PASS:		ds:di - Point structure for start of line segment
		ax, bx - X,Y vals to terminate line structure at
		ss:bp - rectangle we are clipping to (for EC code)
RETURN:		ds:di - ptr to end of current line segment
			(may be newly created point)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TerminateLineSegmentAtClipBoundary	proc	near	

;	If current point at clip boundary, don't add new point.

	cmp	ds:[di].P_x, ax
	jne	doAdd
	cmp	ds:[di].P_y, bx
	je	noAdd
doAdd:
	add	di, size Point			;Add new point after current
	call	ChunkArrayInsertAt		; one.
EC <	xchgdw	axbx, cxdx						>
EC <	call	CheckIfPointInBounds					>
EC <	ERROR_C	CLIP_ERROR						>
EC <	xchgdw	axbx, cxdx						>
	mov	ds:[di].P_x, ax
	mov	ds:[di].P_y, bx
noAdd:
	ornf	ds:[di].P_x, 0x8000
	ret
TerminateLineSegmentAtClipBoundary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clips the current line segment.

CALLED BY:	GLOBAL
PASS:		ss:bp - EraseCallbackFrame
		ds:di - ptr to point.
		*ds:si - chunk array 
RETURN:		carry set if we deleted the current point
DESTROYED:	ax, bx, cx, dx, di
 
PSEUDO CODE/STRATEGY:
	There are several cases:

	1) Both points are outside clip area, and line segment does not
	   intersect it.
		Action: Do nothing

	2) Both points are outside clip area, but line segment crosses
	   clip area.
		Action: Add two points at edge of clip region, one as a
			endpoint to current segment, and one as a start
			point to next segment.

	3) This point is outside, but next point is inside.
		Action: Add new point at clip boundary - if point is already
			on clip boundary, then use it.
			Make point an endpoint.

	4) This point is inside, but next point is outside
		Action: Move point to clip boundary

	5) This point is inside, and next point is inside.
		Action: Delete point


	6) This point is outside and is an endpoint.
	Action: Do nothing

	7) This point is inside and is an endpoint.
		Action: Delete point

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseCallbackFrame	struct
	ECF_bounds	Rectangle
	;	Bounds of area to clear (inclusive - boundaries are cleared
	;	too).

EraseCallbackFrame	ends
EraseCallback	proc	near
EC <	mov	cx, ss:[bp].ECF_bounds.R_left				>
EC <	or	cx, ss:[bp].ECF_bounds.R_top				>
EC <	or	cx, ss:[bp].ECF_bounds.R_bottom				>
EC <	or	cx, ss:[bp].ECF_bounds.R_right				>
EC <	tst	cx							>
EC <	ERROR_S	BAD_ERASE_BOUNDS					>

	mov	cx, ds:[di].P_x
	mov	dx, ds:[di].P_y
	mov	ax, ds:[di][size Point].P_x	;AX:BX <- next point
	andnf	ax, 0x7fff
	mov	bx, ds:[di][size Point].P_y

	tst	cx
	js	doEndPointCheck		;
	call	DoTrivialReject		;Check if we are trivial rejecting
					; (Both points are above/to left/to
					;  right/below erase rectangle)
	jc	notTrivialReject

;	CASE 1 - just exit

exit:
	ret
doEndPointCheck:

;		CASES 6 & 7

	andnf	cx, 0x7fff
	call	CheckIfPointInBounds
	jnc	exit			;If endpoint is outside the erase reg,
					; exit. Else, delete the point.

;		CASE 7 - delete point (endpoint in erase region)

deletePoint:
	call	ChunkArrayDelete
	stc	
	jmp	exit

notTrivialReject:
	call	CheckIfPointInBounds	;
	xchg	cx, ax
	xchg	dx, bx
	jc	firstPointInBounds

	call	CheckIfPointInBounds
	jnc	checkForIntersection

;	CASE 3 - Current point is outside, next is inside.
;		 Check if current point (AX,BX) is on clip boundary. If not,
;		 add new point. Make point be endpoint.


	call	FindOuterIntersection
EC <	ERROR_NC INTERSECTION_NOT_FOUND					>

	call	TerminateLineSegmentAtClipBoundary
	clc
	jmp	exit

checkForIntersection:
;	CASES 1,2
	call	FindOuterIntersection
	jnc	exit			;If no intersection, then trivial
					; reject

;	CASE 2 - Add new points to line segment if current points are not
;		 already on clip boundary. Make first point added an
;		 endpoint.

	call	TerminateLineSegmentAtClipBoundary

;
;	Now, find point where line segment *exits* clip region, and add
;	new point there if necessary.
;
	xchg	ax, cx			;Swap order of points to get
	xchg	bx, dx			; next intersection point.
	call	FindOuterIntersection
;EC <	ERROR_NC INTERSECTION_NOT_FOUND					>
	jnc	exit			;If no intersection, branch

;	If we already have a point at the intersection, then just exit.
;	Else, add a new point there.

	add	di, size Point
	cmp	ax, ds:[di].P_x
	jne	addAndExit
	cmp	bx, ds:[di].P_y	;Clears carry if equal
	je	exit
addAndExit:
	call	ChunkArrayInsertAt
EC <	xchgdw	axbx, cxdx						>
EC <	call	CheckIfPointInBounds					>
EC <	ERROR_C	CLIP_ERROR						>
EC <	xchgdw	axbx, cxdx						>
	mov	ds:[di].P_x, ax
	mov	ds:[di].P_y, bx
	clc
	jmp	exit

firstPointInBounds:

;	CASES 4,5 - first point is in erase region

	call	CheckIfPointInBounds	;
	jc	deletePoint		;CASE 5 - both points in erase reg

;
;	Else, do CASE 4 - First point is inside, and second point is outside
;			  Move point to clip boundary.
;

	xchg	ax, cx			;AX:BX <- point outside boundary
	xchg	bx, dx
	call	FindOuterIntersection
EC <	ERROR_NC INTERSECTION_NOT_FOUND					>
EC <	xchgdw	axbx, cxdx						>
EC <	call	CheckIfPointInBounds					>
EC <	ERROR_C	CLIP_ERROR						>
EC <	xchgdw	axbx, cxdx						>
	mov	ds:[di].P_x, ax
	mov	ds:[di].P_y, bx
	clc	
	jmp	exit	
EraseCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Breaks off all lines that go through the passed rectangle
		+ ERASE_HEIGHT/WIDTH

CALLED BY:	GLOBAL
PASS:		*ds:si - ptr to Ink object
		ax, bx, cx, dx - erase rectangle
		es - ink block
RETURN:		ds:di - ptr to Ink instance data
DESTROYED:	ax, bx, cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseRect	proc	near	
	class	InkClass
	.enter	inherit DoInkErase
EC <	call	ECCheckIfInkObject					>
	cmp	ptCount, 0
	LONG jle	exit
	call	MarkInkDirty
	add	cx, es:IH_reserved.low		;Add width/height of the
	add	dx, es:IH_reserved.high		; erase rectangle
	dec	cx
	dec	dx

	sub	ax, realPixelSize		; bump out coords by two
	sub	ax, realPixelSize
	sub	bx, realPixelSize
	sub	bx, realPixelSize


	; limit the erasing to the rect that we did our trivial reject for

	cmp	ax, currEraseRect.R_right
	jg	exit
	cmp	ax, currEraseRect.R_left
	jg	checkTop
	mov	ax, currEraseRect.R_left
checkTop:
	cmp	bx, currEraseRect.R_bottom
	jg	exit
	cmp	bx, currEraseRect.R_top
	jg	checkRight
	mov	bx, currEraseRect.R_top
checkRight:
	cmp	cx, currEraseRect.R_left
	jl	exit
	cmp	cx, currEraseRect.R_right
	jl	checkBottom
	mov	cx, currEraseRect.R_right
checkBottom:
	cmp	dx, currEraseRect.R_top
	jl	exit
	cmp	dx, currEraseRect.R_bottom
	jl	noNegativeCoords
	mov	dx, currEraseRect.R_bottom
noNegativeCoords:

	tst	ax
	jns	10$
	clr	ax
10$:
	tst	bx
	jns	20$
	clr	bx
20$:
	tst	cx
	js	exit
	tst	dx
	js	exit

	mov	eraseCB.ECF_bounds.R_left, ax
	mov	eraseCB.ECF_bounds.R_top, bx
	mov	eraseCB.ECF_bounds.R_right, cx
	mov	eraseCB.ECF_bounds.R_bottom, dx

	call	GetInkPointCount
	push	cx
	mov	cx, ptCount			; limit search
	mov	ax, ptFirst
	push	bp
	lea	bp, eraseCB

;	Clip all the lines to the bounds

	;
	;	clr	cx				; test without opts
	;
	call	ClipLinesToRectangle
	pop	bp
	call	GetInkPointCount
	pop	ax
	sub	cx, ax
	add	ptCount, cx
exit:
	.leave
	ret

EraseRect	endp

;
;	cx = point count
GetInkPointCount	proc	near
	class	InkClass
	uses	si
	.enter
	clr	cx				; assume nothing
	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	mov	si, ds:[si].II_segments
	tst	si				;If we have a line segment 
	jz	exit
	mov	si, ds:[si]			; ds:di -> point ChunkArray
	mov	cx, ds:[si].CAH_count		;
exit:
	.leave
	ret
GetInkPointCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipLinesToRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clips all lines in the passed object to the passed rectangle
		(deletes line segments inside the rectangle)

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
		ss:bp - EraseCallbackFrame

		cx	- number of points to check, or zero to check all pts
		if cx!=0 then
			ax - which point to start on (offset from start)
RETURN:		nada
DESTROYED:	ax, bx, cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipLinesToRectangle	proc	near	uses	si
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	si, ds:[di].II_segments
	tst	si				;If we have a line segment 
	jnz	processPoints			; array
exit:
EC <	call	ECCheckClipping						>
	.leave
	ret

processPoints:
	mov	di, ds:[si]			; ds:di -> point ChunkArray
	mov	bx, ds:[di].CAH_count		;
	add	di, ds:[di].CAH_offset		;DS:DI <- ptr to first point
	jcxz	doAllPoints
	add	di, ax				; ds:di -> custom first point
	mov	bx, cx				; load up custom count
doAllPoints:
	shl	bx, 1
	shl	bx, 1
	add	bx, di
	sub	bx, size Point			; ds:bx -> last point to check

CheckHack	<size Point eq 4>
;
;	In an attempt to increase speed, we take advantage of the coherency
;	of the ink points - if one point is to one side of the erase rectangle,
;	subsequent points are extremely likely to be there too.
;

loopTop:
	cmp	di, bx
	ja	exit	

	mov	cx, ds:[di].P_x
	mov	dx, ds:[di].P_y
	tst	cx
	js	endPoint
	cmp	cx, ss:[bp].ECF_bounds.R_left
	jb	isToLeft
	cmp	cx, ss:[bp].ECF_bounds.R_right
	ja	isToRight
	cmp	dx, ss:[bp].ECF_bounds.R_top
	jb	isAbove
	cmp	dx, ss:[bp].ECF_bounds.R_bottom
	jna	callCallback
;isBelow:
	mov	ax, ss:[bp].ECF_bounds.R_bottom
checkBelow:	
	mov	cx, ds:[di][size Point].P_y
	cmp	cx, ax
	jna	callCallback
	add	di, size Point
	cmp	di, bx
	jb	checkBelow
	jmp	loopTop

isToLeft:
	mov	ax, ss:[bp].ECF_bounds.R_left
checkLeft:
	mov	cx, ds:[di][size Point].P_x
	andnf	cx, 0x7fff
	cmp	cx, ax
	jnb	callCallback
	add	di, size Point
	cmp	di, bx
	jb	checkLeft
	jmp	loopTop

isToRight:
	mov	ax, ss:[bp].ECF_bounds.R_right
checkRight:	
	mov	cx, ds:[di][size Point].P_x
	andnf	cx, 0x7fff
	cmp	cx, ax
	jna	callCallback
	add	di, size Point
	cmp	di, bx
	jb	checkRight
	jmp	loopTop

isAbove:
	mov	ax, ss:[bp].ECF_bounds.R_top
checkAbove:
	mov	cx, ds:[di][size Point].P_y
	cmp	cx, ax
	jnb	callCallback
	add	di, size Point
	cmp	di, bx
	jb	checkAbove
	jmp	loopTop

endPoint:
	andnf	cx, 0x7fff
	call	CheckIfPointInBounds		;If this end point is not
	jc	callCallback			; in the erase rect, just
						; loop up to goto next.
	add	di, size Point
	jmp	loopTop
callCallback:
	mov	bx, di
	sub	bx, ds:[si] 
	push	bx
	call	EraseCallback
	pop	di
	jc	deletedPoint		;If we deleted a point, we don't need
					; to go to the next point.
	add	di, size Point		;Goto next point
deletedPoint:
	add	di, ds:[si]		;DS:DI <- ptr to point
	mov	bx, ds:[si]
	mov	ax, ds:[bx].CAH_count
	shl	ax, 1
	shl	ax, 1
	add	ax, ds:[bx].CAH_offset
	add	bx, ax			;DS:BX <- ptr to last point in 
	sub	bx, size Point		; array
	jmp	loopTop
ClipLinesToRectangle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes out all the data in the ink object.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkDelete	method	dynamic InkClass, MSG_META_DELETE

	test	ds:[di].II_flags, mask IF_SELECTING
	jnz	exit
	
	mov	bp, offset DeleteUndoString	;BP <- undo title
	call	StartUndoChain

	call	GetSelectionBounds
	call	GenerateAllUndoAction

	call	EndUndoChain

	sub	sp, size EraseCallbackFrame
	mov	bp, sp
	mov	ss:[bp].ECF_bounds.R_left, ax
	mov	ss:[bp].ECF_bounds.R_top, bx
	mov	ss:[bp].ECF_bounds.R_right, cx
	mov	ss:[bp].ECF_bounds.R_bottom, dx
	clr	cx				; check all the points
	call	ClipLinesToRectangle
	add	sp, size EraseCallbackFrame

	call	MarkInkDirty

;	Invalidate the bounds

	call	GetSelectionBounds
	call	ForceInval
exit:
	ret
InkDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method requests ink unless the current tool is the
		eraser.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - InkReturnValue
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkQueryIfPressIsInk	method dynamic InkClass, MSG_META_QUERY_IF_PRESS_IS_INK
	.enter
	mov	ax, IRV_NO_INK
	cmp	ds:[di].II_tool, IT_SELECTOR
	je	exit

;	Create a GState for the IM code to draw through

	call	GetGState
EC <	tst	di							>
EC <	ERROR_Z	CREATE_GSTATE_QUERY_NOT_ANSWERED			>
	call	SetClipRectToVisBounds

;	Set color/width&height of ink
; 	We hack the eraser by drawing fat ink in "white"

	call	GetStrokeWidthAndHeight

.assert CF_INDEX eq 0

	mov	bp, ds:[si]
	add	bp, ds:[bp].Ink_offset
	clr	ch
	mov	cl, ds:[bp].II_penColor
	cmp	ds:[bp].II_tool, IT_ERASER
	jne	10$
	mov	ax, ERASER_WIDTH_AND_HEIGHT

;	Set the draw color to be the color of the background window

	push	si, ax
	mov	si, WIT_COLOR
	call	WinGetInfo
	mov	cl, al
	pop	si, ax
10$:
	xchg	ax, cx
	call	GrSetLineColor
	mov_tr	ax, cx			;AX <- Ink width/height

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, di			;Save GState
	clrdw	bxdi			;no gesture callback
	call	UserCreateInkDestinationInfo
	mov	ax, IRV_NO_INK
	tst	bp
	jz	exit
	mov	ax, IRV_DESIRES_INK
exit:
	.leave
	ret
InkQueryIfPressIsInk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformInkBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine transforms the passed ink block to the
		coordinate system of the ink object.

CALLED BY:	GLOBAL
PASS:		es - locked ink block
		ds:di,*ds:si - Ink object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransformInkBlock	proc	near	uses	bx, si, di
	class	VisClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, ds:[di].VI_bounds.R_left	;BP,DX <- bounds of object
	mov	dx, ds:[di].VI_bounds.R_top

;	Get window this object lies in

	call	VisQueryWindow

;	Transform the bounds (in case we have to invalidate them after an
;	 erase)

	mov	ax, es:[IH_bounds].R_left
	mov	bx, es:[IH_bounds].R_top
	call	WinUntransform
	sub	ax, bp			;Convert bounds to obj coord system
	mov	es:[IH_bounds].R_left, ax
	sub	bx, dx
	mov	es:[IH_bounds].R_top, bx
	
	mov	ax, es:[IH_bounds].R_right
	mov	bx, es:[IH_bounds].R_bottom
	call	WinUntransform
	sub	ax, bp
	mov	es:[IH_bounds].R_right, ax
	sub	bx, dx			;Convert bounds to obj coord system
	mov	es:[IH_bounds].R_bottom, bx

;	Transform the width/height of the erase rectangle


	mov	ax, ERASE_WIDTH
	mov	bx, ERASE_HEIGHT
	call	WinUntransform
	mov	es:[IH_reserved].low, ax
	mov	es:[IH_reserved].high, bx

	clr	ax
	clr	bx
	call	WinUntransform
	sub	es:[IH_reserved].low, ax
	sub	es:[IH_reserved].high, bx

	mov	cx, es:[IH_count]
	mov	si, offset IH_data

loopTop:
;	DI <- window our object lives in
;	CX <- # points left to transform
;	ES:SI <- ptr to point to transform
;	BP - left vis bound of object
;	DX - top vis bound of object

	mov	ax, es:[si].P_x
	mov	bx, es:[si].P_y

;	AX <-   ink  X coordinate:
;		High bit - set if this is the end of an ink stroke
;		low 15 bits - signed x coordinate
;
;	Convert the 15-bit signed X coordinate value to an 8-bit signed value
;	so it can be transformed to window coords

	shl	ax			;High Bit -> carry
	pushf	
	sar	ax			;Sign extend the 15-bit value in AX

	call	WinUntransform		;Transform the coordinate to our window
	sub	ax, bp			; coords, and then into our personal
	sub	bx, dx			; object vis coords

;	Transform the X coordinate into a 15-bit signed value, and set the high
;	bit to be 1 if it was the end of the line segment

EC <	test	ah, 0xc0						>
EC <	ERROR_PO COORDINATE_OVERFLOW					>
	andnf	ax, 0x7fff		;Clear the high bit (it is a seven-bit
					; signed number)
	popf				;Restore the "end of stroke" flag
	jnc	10$			;
	ornf	ax, 0x8000		;
10$:
	mov	es:[si].P_x, ax
	mov	es:[si].P_y, bx
	add	si, size Point
	loop	loopTop
	.leave
	ret
TransformInkBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine does a Bresenham's algorithm along the X axis

CALLED BY:	GLOBAL
PASS:		bx - deltaY
		ax - deltaX
		es - ink block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseX	proc	near
	.enter	inherit	DoInkErase

	sal	bx, 1		;incr1 = 2dy
	mov	incr1, bx
	sub	bx, ax		;D = 2dy - dx
	mov	dx, bx
	sub	bx, ax
	mov	incr2, bx	;incr2 = 2 (dy - dx)
	mov	ax, line2.P_x
	cmp    	line1.P_x, ax
	jg	swap
afterSwap:	
	mov	endCoord, ax
	mov	ax, ss:pixelSize		;Assume y2 > y1
	mov	bx, line2.P_y
	cmp	bx, line1.P_y
	jg	yOK
	neg	ax
yOK:
	mov	bump, ax
	mov	ax, line1.P_x		;start erase at first endpoint
loopTop:
	cmp	dx, 0
	jg	doErase
	add	dx, incr1
	add	ax, pixelSize
	jmp	doCheck
doErase:
	push	dx			; save decision var
	mov	cx, ax
	add	ax, pixelSize
	xchg	ax, line1.P_x
	mov	bx, line1.P_y		;BX <- top coord of rect to erase
	mov	dx, bx			;
	call	EraseRect
	pop	dx
	mov	ax, bump
	add	line1.P_y, ax
	add	dx, incr2
	mov	ax, line1.P_x
doCheck:
	cmp	ax, endCoord
	jl	loopTop
	mov	ax, endCoord

	mov_tr	cx, ax
	mov	bx, line1.P_y
	mov	ax, line1.P_x
	mov	dx, bx
	call	EraseRect
	.leave
	ret
swap:
	xchg	ax, line1.P_x
	mov	bx, line2.P_y
	xchg	bx, line1.P_y
	mov	line2.P_y, bx
	jmp	afterSwap
EraseX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine does a Bresenham's algorithm along the X axis

+CALLED BY:	GLOBAL
PASS:		bx - deltaY
		ax - deltaX
		es - ink block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseY	proc	near
	.enter	inherit	DoInkErase
	sal	ax, 1		;incr1 = 2dx
	mov	incr1, ax
	sub	ax, bx		;D = 2dx - dy
	mov	dx, ax
	sub	ax, bx
	mov	incr2, ax	;incr2 = 2 (dx - dy)
	mov	ax, line2.P_y
	cmp    	line1.P_y, ax
	jg	swap
afterSwap:	
	mov	endCoord, ax
	mov	ax, ss:pixelSize	;Assume y2 > y1
	mov	bx, line1.P_x
	cmp	bx, line2.P_x
	jl	xOK
	neg	ax
xOK:
	mov	bump, ax
	mov	ax, line1.P_y		;start erase at first endpoint
loopTop:
	cmp	dx, 0
	jg	doErase
	add	dx, incr1
	add	ax, pixelSize
	jmp	doCheck
doErase:
	push	dx
	mov	bx, line1.P_y
	mov	dx, ax
	add	ax, pixelSize
	mov	line1.P_y, ax
	mov	ax, line1.P_x
	mov	cx, ax
	call	EraseRect
	pop	dx
	mov	ax, bump
	add	line1.P_x, ax
	add	dx, incr2
	mov	ax, line1.P_y
doCheck:
	cmp	ax, endCoord
	jl	loopTop
	mov	ax, endCoord

	mov	bx, line1.P_y
	mov	dx, ax
	mov	ax, line1.P_x
	mov	cx, ax
	call	EraseRect
	.leave
	ret
swap:
	xchg	ax, line1.P_y
	mov	bx, line2.P_x
	xchg	bx, line1.P_x
	mov	line2.P_x, bx
	jmp	afterSwap
EraseY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseLineSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the passed line segment 

CALLED BY:	GLOBAL
PASS:		ax, bx - one coord
		cx, dx - other coord
		es - Ink block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseLineSegment	proc	near	uses	di, cx, dx
	.enter	inherit	DoInkErase
	shl	cx, 1
	sar	cx, 1		;Convert 7-bit signed x values to 8 bit
	shl	ax, 1
	sar	ax, 1
	mov	line1.P_x, ax
	mov	line1.P_y, bx
	mov	line2.P_x, cx
	mov	line2.P_y, dx
	mov	di, cx
	sub	di, ax
	jns	10$
	neg	di
10$:
	mov	deltaX, di

	mov	di, dx
	sub	di, bx
	jns    	20$
	neg	di
20$:
	mov	deltaY, di

	mov	ax, deltaX

	; divide by the scale factor, so we don't have to do so many

	clr	dx
	mov	bx, ss:pixelSize
	div	bx
	mov	cx, ax
	mov	ax, di		; ax = deltaY
	clr	dx
	mov	bx, ss:pixelSize
	div	bx
	mov	bx, ax		; bx = scaled back deltaY
	mov	ax, cx		; ax = scaled back deltaX

	cmp	ax, bx		;If deltaX > deltaY, draw along x axis
	jge	doEraseX
	call	EraseY
exit:
	.leave
	ret
doEraseX:
	call	EraseX
	jmp	exit
EraseLineSegment	endp

SendToApp	proc	near	uses	bx, si, di
	.enter
	clr	bx
	call	GeodeGetAppObject
	tst	bx
	jz	exit	
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	.leave
	ret
SendToApp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoInkErase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Treat the incoming ink points as ink erase points.

CALLED BY:	GLOBAL
PASS:		*ds:si - InkObject
		es - Ink block
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoInkErase	proc	near
	loopCount	local	word
	ptFirst	local	word
	ptCount	local	word
	origPtFirst local word
	whichOpt local	word

;	These are *inherited*. Don't delete them

.warn -unref_local

	currEraseRect local Rectangle
	line1	local	Point
	line2	local	Point
	deltaX	local	word
	deltaY	local	word
	incr1	local	word
	incr2	local	word
	endCoord local	word
	bump	local	word
	pixelSize local	word			; essentially the scale factor
						; (rounded up to 1 if 0)
	realPixelSize local	word		; The *actual* size of each
						; pixel
	eraseCB	local	EraseCallbackFrame
						;  erased points
.warn @unref_local
	class	InkClass

	.enter
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	SendToApp

	; calculate the scale factor so we don't have to waste so much time
	; going down diagonal lines.

	mov	ax, es:[IH_reserved].low ; get document size of erase 
	clr	dx
	mov	bx, ERASE_WIDTH		; divide to get scale factor
	div	bx			; ax = scale factor
;
; The problem here is that the document could actually be scaled out. If so,
; then treat it as if it is unscaled.
;
	mov	realPixelSize, ax
	tst	ax
	jnz	setPixelSize
	mov	ax, 1
setPixelSize:
	mov	pixelSize, ax		; save it for later
	mov	cx, es:[IH_count]
	jcxz	exit
	mov	loopCount, cx

	clr	origPtFirst
	call	LimitPointSearch
	clr	whichOpt		; set to Normal optimization (not line)
	mov	cx, ptFirst
	mov	origPtFirst, cx
	tst	ptCount
	jz	exit

	mov	di, offset IH_data	;ES:DI <- points to add
newLineSeg:
	mov	ax, es:[di].P_x		;
	mov	bx, es:[di].P_y
loopTop:
	mov	cx, es:[di].P_x
	mov	dx, es:[di].P_y

	; the points we get back from the digitizer frequently have multiple
	; horizontal/vertical line segments in a row.  If we find a horiz or
	; vertical segment, accumulate them an then call EraseRect instead
	; of EraseLineSegment.

	cmp	bx, dx			; is it horizontal ?
	LONG je	horizAccum		;  yes, accumulate all horiz lines.
	cmp	ax, cx			; is it vertical ?
	LONG je	vertAccum		;  yes, accumulate all vertical lines.

	cmp	whichOpt, 1		; if we have another line bounds, 
	je	calcNewBounds		;  don't user it again, elseif overall.
	cmp	ptCount, 32		; if only a few points, don`t waste 
	jb	eraseLine		;  time making it smaller	
calcNewBounds:
	call	CalcNewLineBounds
	mov	whichOpt, 1
	tst	ptCount			; if none to do, skip call
	jz	lineErased
eraseLine:
	call	EraseLineSegment
lineErased:
	movdw	axbx, cxdx

nextPoint:
	add	di, size Point
	dec	loopCount
	jz	exit
	tst	cx
	jns	loopTop
	jmp	newLineSeg

exit:
	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	SendToApp

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	test	ds:[di].II_flags, mask IF_INVALIDATE_ERASURES
	jz	done

;	Invalidate the bounds of the ink

	call	GetGState
	tst	di
	jz	done

	mov	ax, es:[IH_bounds].R_left
	mov	bx, es:[IH_bounds].R_top
	mov	cx, es:[IH_bounds].R_right
	mov	dx, es:[IH_bounds].R_bottom
	sub	ax, pixelSize
	sub	ax, pixelSize
	sub	bx, pixelSize
	sub	bx, pixelSize
	add	cx, es:[IH_reserved].low
	add	cx, pixelSize
	add	dx, es:[IH_reserved].high
	add	dx, pixelSize
	call	GrInvalRect
	call	GrDestroyState
done:
	.leave
	ret

	; accumulate horizontal lines.  
horizAccum:
	shl	cx, 1
	sar	cx, 1			; Convert 15-bit signed x values 
	shl	ax, 1			;  to 16 bit
	sar	ax, 1
	cmp	ax, cx			; sort 'em
	jle	xSorted
	xchg	ax, cx
xSorted:
	mov	bx, dx			; may have been messed up by code below
	cmp	es:[di+(size Point)].P_y, bx ; any more to accumulate ?
	jne	haveEraseRect

	; more horizontal points to consider.

	tst	loopCount		; don't go ahead if no more points
	jz	haveEraseRect
	test	es:[di].P_x.high, 0x80	; if current point is an endpoint, 
	jnz	haveEraseRect		;  then don't continue
	add	di, size Point		; onto next point
	mov	bx, es:[di].P_x
	shl	bx, 1			; take care of 15->16-bit convert
	sar	bx, 1
	dec	loopCount
	cmp	ax, bx			; check for new minimum
	je	xSorted			; if same, continue
	jl	checkRight		; if more, check for new right side
	mov	ax, bx			; have new left side
	jmp	xSorted			;  continue
checkRight:
	cmp	cx, bx
	jge	xSorted			; nothing new
	mov	cx, bx			; new right side
	jmp	xSorted	
	
haveEraseRect:
	push	di
	tst	whichOpt		; figure which is in effect
	jz	eraseIt
	call	LimitPointSearch	; else re-calc it.
	clr	whichOpt
eraseIt:
	call	EraseRect		; do this rectangle
	pop	di
	movdw	bxax, es:[di]		; get point in case wasn't sorted.
	mov	cx, ax			; need a copy here too
	tst	loopCount
	LONG jz	exit
	jmp	nextPoint

	; accumulate vertical lines.
vertAccum:
	shl	ax, 1			;  to 16 bit
	sar	ax, 1
	mov	cx, ax			; copy up
	cmp	bx, dx			; sort 'em
	jle	ySorted
	xchg	bx, dx
ySorted:
	mov	ax, es:[di+(size Point)].P_x ; check next point
	shl	ax, 1
	sar	ax, 1
	cmp	cx, ax 			; any more to accumulate ?
	mov	ax, cx			; may have been messed up below
	jne	haveEraseRect

	; more vertical points to consider.

	tst	loopCount
	jz	haveEraseRect
	test	es:[di].P_x.high, 0x80	; if current point is an endpoint, 
	jnz	haveEraseRect		;  then don't continue
	add	di, size Point		; onto next point
	dec	loopCount
	mov	ax, es:[di].P_y		; so we don't have to check me 4 times
	cmp	bx, ax			; check for new minimum
	je	ySorted			; if same, continue
	jl	checkBottom		; if more, check for new bottom 
	mov	bx, ax			; have new top
	jmp	ySorted			;  continue
checkBottom:
	cmp	dx, ax
	jge	ySorted			; nothing new
	mov	dx, ax			; new bottom
	jmp	ySorted	
	
DoInkErase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNewLineBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset ptCount and ptFirst to narrow search for one line

CALLED BY:	INTERNAL
		DoInkErase
PASS:		es	- InkHeader block
		*ds:si	- InkObject
		DoInkErase frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcNewLineBounds	proc	near
		uses	ax,bx,cx,dx		; save endpoints
		.enter	inherit DoInkErase

		; save old InkBounds
	
		push	es:[IH_bounds].R_left
		push	es:[IH_bounds].R_right
		push	es:[IH_bounds].R_top
		push	es:[IH_bounds].R_bottom

		shl	cx, 1			; Convert 7-bit signed x 
		sar	cx, 1			;  values to 8 bit
		shl	ax, 1
		sar	ax, 1

		cmp	ax, cx			; sort bounds
		jle	xOK
		xchg	ax, cx
xOK:
		cmp	bx, dx			; sort bounds
		jle	yOK
		xchg	bx, dx
yOK:
		mov	es:[IH_bounds].R_left, ax
		mov	es:[IH_bounds].R_top, bx
		mov	es:[IH_bounds].R_right, cx
		mov	es:[IH_bounds].R_bottom, dx
		call	LimitPointSearch
		pop	es:[IH_bounds].R_bottom
		pop	es:[IH_bounds].R_top
		pop	es:[IH_bounds].R_right
		pop	es:[IH_bounds].R_left

		.leave
		ret
CalcNewLineBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LimitPointSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Limit the point search in the ink object coord list

CALLED BY:	DoInkErase
PASS:		DoInkErase stack frame
		*ds:si	- InkObject
		es	- ink block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Tromp through the ink data structure points, and figure out
		the first and last points that overlap the bounding box of
		the erase points.  This gets passed to EraseRect eventually
	  	to limit the search there.

		As a first pass, we just use the criteria: both points (in
		x or y) must be on the same side of the bounding rect of the
		ink.

		This can be called more than once to further narrow the
		search.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LimitPointSearch	proc	near
		class	InkClass
		uses	si, di, cx, ax, bx, dx
		.enter	inherit	DoInkErase

		; get a pointer to the first point, and initialize the
		; limiting variables.

		mov	di, ds:[si]
		add	di, ds:[di].Ink_offset
		mov	si, ds:[di].II_segments
		tst	si			;If we have a line segment 
		jnz	processPoints		; array
noPoints:
		clr	ptCount			; in case there are none.
		clr	ptFirst	
exit:
		.leave
		ret

		; start looking.  But first, calculate the bounds of the 
		; search
processPoints:
		mov	cx, pixelSize
		shl	cx, 1			; pixelSize * 2
		mov	ax, es:[IH_bounds].R_left
		sub	ax, cx
		mov	currEraseRect.R_left, ax
		mov	ax, es:[IH_bounds].R_top
		sub	ax, cx
		mov	currEraseRect.R_top, ax
		mov	ax, es:[IH_bounds].R_right
		add	ax, es:[IH_reserved].low
		mov	currEraseRect.R_right, ax
		mov	ax, es:[IH_bounds].R_bottom
		add	ax, es:[IH_reserved].high
		mov	currEraseRect.R_bottom, ax

		mov	si, ds:[si]		; ds:si -> point ChunkArray
		mov	cx, ds:[si].CAH_count	; cx = point count
		jcxz	noPoints
		add	si, ds:[si].CAH_offset	; ds:si -> first point
		mov	di, si			; keep di pting at ChunkArray
		add	si, origPtFirst		; don't check before this
		mov	ax, si
		sub	ax, di
		shr	ax, 1			; divide by size of Point
		shr	ax, 1
		sub	cx, ax			; that fewer points to check
		mov	ptCount, cx		; but assume we do the rest

		; our first task is to find the first line segment inside
		; the clip rect. There is more space vertically than 
		; horizontally (in the notepad, at least), so start off by 
		; assuming we'll be successful in our search vertically first.

		call	SearchWhileOut		; cx = #pts after first found

		mov	ptCount, cx		; record new max number to chk
		mov	ax, si			; record new offset too
		sub	ax, di			; ax = offset into point list
		mov	ptFirst, ax		; save offset.
		jcxz	exit			; if none left, none left.

		; no we have the lower end limit to the search.  We can do 
		; better by defining an upper end as well.  We do this
		; by finding the last segment that is possibly inside the
		; bounding box, then changing ptCount appropriately.

findLastLoop:
		mov	dx, cx			; make sure we're in...
		call	SearchWhileIn		; cx = #points left
		cmp	dx, cx			; if same, none in...
		je	findOuts		;   so don't update things

		mov	di, ptCount
		sub	di, cx
		inc	di
findOuts:
		jcxz	foundLast		; if remainder in, OK...
		call	SearchWhileOut
		tst	cx
		jnz	findLastLoop
foundLast:
		mov	ptCount, di
		jmp	exit

LimitPointSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchWhileOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search through points until we hit one that is inside the
		bounding box of the erase ink.

CALLED BY:	INTERNAL
		LimitPointSearch
PASS:		ds:si	- pointer to list of Points
		cx	- maximum number to search
		es	- InkHeader block
RETURN:		cx	- number left after first one hit
		ds:si	- pointer to first one inside bounding box
DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchWhileOut	proc	near
		uses	dx
		.enter	inherit DoInkErase

		sub	si, size Point
nextPair:
		add	si, size Point
		call	ArePointsToOneSide
		jnc	exit
		loop	nextPair
exit:
		.leave
		ret

SearchWhileOut	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchWhileIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search through points until we hit one that is outside the
		bounding box of the erase ink.

CALLED BY:	INTERNAL
		LimitPointSearch
PASS:		ds:si	- pointer to list of Points
		cx	- maximum number to search
		es	- InkHeader block
RETURN:		cx	- number left after first one hit
		ds:si	- pointer to first one inside bounding box
DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchWhileIn	proc	near
		uses	dx
		.enter	inherit DoInkErase

		sub	si, size Point
nextPair:
		add	si, size Point
		call	ArePointsToOneSide
		jc	exit
		loop	nextPair
exit:
		.leave
		ret
SearchWhileIn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArePointsToOneSide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if both points are to one side of the rectangle

CALLED BY:	INTERNAL
PASS:		es:	- InkHeader
		ds:si	- pointer to two Points
RETURN:		carry	- set if both to one side
DESTROYED:	ax,bx,dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArePointsToOneSide		proc	far
		uses	cx
		.enter	inherit DoInkErase

		mov	ax, currEraseRect.R_top	; check top
		mov	bx, ds:[si].P_y
		mov	dx, ds:[si+(size Point)].P_y

		cmp	bx, ax			; see if first one is
		jge	checkBottom
		cmp	dx, ax			; check 2nd
		jge	checkBottom
toOneSide:
		stc
exit:
		.leave
		ret

		; not above, check below.
checkBottom:
		mov	ax, currEraseRect.R_bottom
		cmp	bx, ax				; check first
		jle	checkLeft
		cmp	dx, ax
		jg	toOneSide
checkLeft:
		mov	ax, currEraseRect.R_left
		mov	bx, ds:[si].P_x
		mov	dx, ds:[si+(size Point)].P_x
		shl	bx, 1			; make endpoints work
		sar	bx, 1
		shl	dx, 1
		sar	dx, 1

		cmp	bx, ax			; see if first one is
		jge	checkRight
		cmp	dx, ax			; check 2nd
		jl	toOneSide

checkRight:
		mov	ax, currEraseRect.R_right
		cmp	bx, ax
		jle	notToOneSide
		cmp	dx, ax
		jg	toOneSide
notToOneSide:
		clc
		jmp	exit
ArePointsToOneSide		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipLineSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clips the line segment to the screen

CALLED BY:	GLOBAL
PASS:		ax, bx - point on screen
		cx, dx - point off screen
RETURN:		cx, dx - clipped point (on screen)
DESTROYED:	ax, bx
 
PSEUDO CODE/STRATEGY:

	The slope of the line is DELTAX / DELTAY.

	The equation for the clipped line is:

	X = AX - BX * SLOPE = AX - BX * DELTAX / DELTAY

	Y = BX - AX/SLOPE = BX - AX / (DELTAX / DELTAY)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipLineSegment	proc	near
	slope	local	WWFixed
	onScreenPt	local	Point
	offScreenPt	local	Point
	.enter
EC <	tst	bx							>
EC <	ERROR_S	BAD_POINT_PASSED_TO_CLIP_LINE_SEGMENT			>
EC <	tst	ax							>
EC <	ERROR_S	BAD_POINT_PASSED_TO_CLIP_LINE_SEGMENT			>
EC <	tst	dx							>
EC <	js	10$							>
EC <	tst	cx							>
EC <	ERROR_NS BAD_POINT_PASSED_TO_CLIP_LINE_SEGMENT			>
EC <10$:								>
	mov	onScreenPt.P_x,  ax
	mov	onScreenPt.P_y,  bx
	mov	offScreenPt.P_x, cx 
	mov	offScreenPt.P_y, dx

	sub	ax, cx			;AX <- delta X
	sub	bx, dx			;BX <- delta Y
	tst	bx			;If slope is 0 or infinite, handle
	LONG jz	noDeltaY		; those cases specially...
	tst	ax	
	jz	noDeltaX
	mov_tr	dx, ax
	clr	ax			;BX.AX <- delta Y
	mov	cx, ax			;DX.CX <- delta X
	call	GrSDivWWFixed
	movdw	slope, dxcx

	tst	offScreenPt.P_x
	jns	clipDX

	movdw	bxax, dxcx		;BX.AX <- slope
	mov	dx, onScreenPt.P_x	;DX.CX <- onScreenPt.X
	call	GrSDivWWFixed

	mov	bx, onScreenPt.P_y	;BX.AX = onScreenPt.Y	
	clr	ax
	subwwf	bxax, dxcx		;New y = onScrnPt.Y - onScrnPt.X/slope
	rndwwf	bxax			;BX <- new Y
	clr	offScreenPt.P_x
	mov	offScreenPt.P_y, bx
	movdw	dxcx, slope
clipDX:
	tst	offScreenPt.P_y
	jns	noClipDX

	mov	bx, onScreenPt.P_y
	clr	ax
	call	GrMulWWFixed
	mov	bx, onScreenPt.P_x
	clr	ax
	subwwf	bxax, dxcx
	rndwwf	bxax

	clr	offScreenPt.P_y
	mov	offScreenPt.P_x, bx
noClipDX:
	mov	cx, offScreenPt.P_x
	mov	dx, offScreenPt.P_y
exit:
	.leave
	ret
noDeltaX:
	mov	cx, onScreenPt.P_x
	clr	dx
	jmp	exit
noDeltaY:
	clr	cx
	mov	dx, onScreenPt.P_y
	jmp	exit
ClipLineSegment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipPointToScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine adds points to clip the line segments going
		through the current point to the screen.

CALLED BY:	GLOBAL
PASS:		cx, dx - point to add
			(CX is 7-bit signed value, with high bit set indicating
			 that the point is the end of a line segment).
		ds:di - place to store next point
		ds:bx - ptr to ChunkArrayHeader of line segment
		es:bp - ptr to next point
RETURN:		nada
DESTROYED:	cx, dx
 
PSEUDO CODE/STRATEGY:

 	This point is outside the bounds of the object.

	If the last point added was an end segment {
		If next point is off screen or this is an end segment
			GotoNextPoint;
		Else
			clip the current point to the screen
			add the current point, and GotoNextPoint;

	} Else (last point was not an end segment) {
		Clip the current point to the screen using prev point
		add the current point and end segment
		GOTO "doClip"
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipPointToScreen	proc	near	uses	ax
	.enter
EC <	tst	dx							>
EC <	js	negCoord						>
EC <	test	ch, 0x40						>
EC <	ERROR_Z	COORD_ON_SCREEN_SHOULD_NOT_BE_CLIPPED			>
EC <negCoord:								>

	tst	ds:[bx].CAH_count
	jz	lastPtWasEndSegment
	cmp	ds:[di-(size Point)].P_x.high, 0
	js	lastPtWasEndSegment

;	The last point was not an end segment.

	push	cx, dx
	push	bx
	shl	cx, 1			;Convert 7-bit signed value
	sar	cx, 1
	mov	ax, ds:[di - (size Point)].P_x
	mov	bx, ds:[di - (size Point)].P_y
	call	ClipLineSegment		;Returns CX,DX <- last pt on line
					; segment within object bounds.
	pop	bx
	call	AddCoord
	ornf	ds:[di - (size Point)].P_x, 0x8000
	pop	cx, dx	
lastPtWasEndSegment:
	tst	cx			
	js	exit
	shl	cx, 1			;Convert 7-bit signed value to 8 bit
	sar	cx, 1
	mov	ax, es:[bp].P_x
	shl	ax, 1			;Convert 7-bit signed value to 8 bit
	sar	ax, 1
	tst	ax
	js	exit
	tst	es:[bp].P_y
	js	exit
	push	bx
	mov	bx, es:[bp].P_y
	call	ClipLineSegment
	pop	bx
	call	AddCoord
exit:
	.leave
	ret
ClipPointToScreen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler accepts ink and adds it to the ink 
		object.

CALLED BY:	GLOBAL
PASS:		cx, dx, bp - MSG_META_NOTIFY_WITH_DATA_BLOCK args
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkInk	method	dynamic InkClass, MSG_META_NOTIFY_WITH_DATA_BLOCK
	cmp	dx, GWNT_INK
	jne	callSuper
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	je	doInk
callSuper:
	mov	di, offset InkClass
	GOTO	ObjCallSuperNoLock


doInk:
	call	GrabTarget

;	Erase the selection (if one exists)

	call	NukeSelection

	push	cx, dx, bp, es
	mov	bx, bp
	call	MemLock
	push	bx
	mov	es, ax			;

;	Transform the ink points in screen coordinates to our document
;	coordinates

	call	TransformInkBlock

	mov	cx, ds:[LMBH_handle]
	cmpdw	cxsi, es:[IH_destination]
	jne	isPencil
	cmp	ds:[di].II_tool, IT_ERASER
	jne	isPencil

;	Generate an undo action

	mov	bp, offset EraseUndoString
	call	StartUndoChain

	mov	ax, es:[IH_bounds].R_left
	mov	bx, es:[IH_bounds].R_top
	mov	cx, es:[IH_bounds].R_right
	add	cx, es:[IH_reserved].low
	mov	dx, es:[IH_bounds].R_bottom
	add	dx, es:[IH_reserved].high
	call	GenerateAllUndoAction

	call	EndUndoChain

;	Do the erase (modify the internal data - it's already been done on
;	the screen).

	call	DoInkErase
	jmp	unlockExit

;	Interpret this ink data as "pen" input (not as erasure)

isPencil:
	
	call	GetNumPoints
	mov	cx, es:[IH_count]
	add	cx, ax
	call	GetMaxNumPoints
	cmp	cx, dx
	jae	tooManyPoints


;	Generate an undo action for this ink addition.

	mov	bp, offset InkUndoString
	call	StartUndoChain

	mov_tr	di, ax				;BP <- current # points
	mov	ax, es:[IH_bounds].R_left
	mov	bx, es:[IH_bounds].R_top
	mov	cx, es:[IH_bounds].R_right
	mov	dx, es:[IH_bounds].R_bottom
	call	GenerateInkUndoAction

	call	EndUndoChain

;	Add the ink to this object

	mov	cx, es:[IH_count]	;We actually create space for 
	shl	cx, 1			; 1.5 * count, as when we clip the
	add	cx, es:[IH_count]	; lines to the screen boundary, we
	shr	cx, 1			; may need to create more points.
	push	cx
	call	CreateRoomForSegments
	pop	ax

	call	MarkInkDirty

	mov	bx, ds:[si]			;CreateRoomForSegments adds the
	add	bx, ds:[bx].Ink_offset		; points added into CAH_count
	mov	bx, ds:[bx].II_segments		; which we don't want
	mov	bx, ds:[bx]
	sub	ds:[bx].CAH_count, ax

	push	cx			;Push current # line segments in array

	mov	ax, es:[IH_count]
	mov	bp, offset IH_data	;ES:BP <- ptr to point
loopTop:
	dec	ax
	js	loopExit

	mov	cx, es:[bp].P_x		;
	mov	dx, es:[bp].P_y		;
	add	bp, size Point

	push	cx			;

;	Add point to object

	shl	cx, 1			;Convert 7-bit signed coord to 8-bit
	sar	cx, 1
	tst	cx
	js	doClip
	tst	dx
	js	doClip
	call	AddCoord

	pop	cx
	tst	cx			;Test to see if we are at the end
	jns	loopTop			; of this segment. Branch if not.
	ornf	ds:[di - (size Point)].P_x, 0x8000
	jmp	loopTop

doClip:
	pop	cx
	call	ClipPointToScreen
	jmp	loopTop


tooManyPoints:
	push	ax				;Save # items in array
	mov	cx, offset BadInk
	call	PutupErrorDialog

	mov	ax, MSG_VIS_INVALIDATE		;Redraw the ink
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

loopExit:

;	Re-alloc segment array to be the correct size

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ax, ds:[di].II_segments
	tst	ax
	jz	noSegments
	mov	di, ax			;AX <- chunk handle of array
	mov	di, ds:[di]
	mov	cx, ds:[di].CAH_count	;CX <- # items in array
	shl	cx, 1
	shl	cx, 1			;  CX*4 = size of data
	add	cx, ds:[di].CAH_offset	;CX += size of header
	call	LMemReAlloc
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
noSegments:
	pop	ax				;AX <- first element # we
						; added
unlockExit:
	pop	bx
	movdw	cxdx, es:[IH_destination]
	call	MemUnlock

;	If we were the destination for the ink (meaning that the screen is
;	already updated for us), skip the redraw. Else, we may have to
;	redraw

	cmp	dx, si
	jne	doDraw
	cmp	cx, ds:[LMBH_handle]
	je	noDraw

doDraw:

;	Draw all the line segments that we have added

	tst	ds:[di].II_segments
	jz	noDraw

	call	RedrawInk

noDraw:
	call	UpdateEditControlStatus
	pop	cx, dx, bp, es
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	jmp	callSuper
InkInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutupErrorDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up an error dialog box.

CALLED BY:	GLOBAL
PASS:		cx - chunk handle of error message
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutupErrorDialog	proc	far	uses	ax, bx, cx, dx, bp, di,si, es
	.enter
	mov	dx, GenAppDoDialogParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, CDT_ERROR shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE
	mov	bx, handle BadPaste
	call	MemLock
	mov	es, ax
	mov	di, cx
	mov	di, es:[di]
	movdw	ss:[bp].GADDP_dialog.SDP_customString, esdi
	clrdw	ss:[bp].GADDP_finishOD
	clr	ss:[bp].GADDP_message
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment

	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	clr	bx
	call	GeodeGetAppObject
	tst	bx
	jz	exit
	mov	di, mask MF_STACK or mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
exit:
	add	sp, size GenAppDoDialogParams
	mov	bx, handle BadPaste
	call	MemUnlock
	.leave
	ret
PutupErrorDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendDataFromTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends data from the transfer format.

CALLED BY:	GLOBAL
PASS:		ax.bp - transfer format VM chain
		*ds:si - Ink object
RETURN:		carry set if error (too many points)
		di - # points in data before paste
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendDataFromTransferFormat	proc	near
	vmChain		local	dword			\
			push	bp, ax
	vmFile		local	hptr
			push	bx	

	numPoints	local	word
	.enter

;	Generate a paste undo action

	call	GetNumPoints
	mov_tr	cx, ax			;CX <- # points in object

	call	GetMaxNumPoints		;Returns DX = max # points
	mov	numPoints, cx
	mov	bx, vmFile
	movdw	diax, vmChain
	call	DBLock
	mov	di, es:[di]
	add	cx, es:[di][size XYSize]	;CX <- # points *after* paste
	cmp	cx, dx
	mov	cx, es:[di].XYS_width		;CX,DX - width/height of
	mov	dx, es:[di].XYS_height		; data
	call	DBUnlock
	jae	tooManyPoints

	push	bp
	mov	bp, offset PasteUndoString
	call	StartUndoChain		;Start the undo chain
	pop	bp

	call	GetSelectionStart	;Get upper left corner of selection

	add	cx, ax			;AX,BX,CX,DX <- bounds of paste
	add	dx, bx
	mov	di, numPoints
	call	GenerateInkUndoAction	;
	call	EndUndoChain

	mov_tr	cx, ax			;CX,DX <- x/y offset to do paste
	mov	dx, bx
	movdw	diax, vmChain
	mov	bx, vmFile

;	Paste the data in

	push	bp
	mov	bp, size XYSize		;BP <- size of extra data to skip 
	call	AppendDataFromFile
	call	MarkInkDirty
	pop	bp

	clc
done:
	mov	di, numPoints
	.leave
	ret
tooManyPoints:
	mov	cx, offset BadPaste
	call	PutupErrorDialog
	stc
	jmp	done

AppendDataFromTransferFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedrawInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraws the ink starting at the passed offset.

CALLED BY:	GLOBAL
PASS:		ax - index of first point of ink to draw
		*ds:si - Ink object
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, es, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RedrawInk	proc	near
	class	InkClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	exit

	call	GetGState
	tst	di
	jz	exit
	call	SetClipRectToVisBounds

	mov	bp, di

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	tst	ds:[di].II_segments
	jz	popSIdestroyState
	mov	si, ds:[di].II_segments
	call	ChunkArrayElementToPtr
	call	ChunkArrayGetCount
	sub	cx, ax			;CX <- # items to draw
	pop	si
	jcxz	destroyState

	segmov	es, ds			;ES:DI <- pointer to points to draw
					;BP  <- gstate to draw through
	clr	dx			;DX <- clear "print" flag
	call	DrawMultipleLineSegments
destroyState:
	mov	di, bp
	call	GrDestroyState
exit:
	.leave
	ret

popSIdestroyState:
	pop	si
	jmp	destroyState

RedrawInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Paste the selected area to the clipboard
CALLED BY:	
PASS:		*ds:si	= InkClass object
		ds:di	= InkClass instance data
		ds:bx	= InkClass object (same as *ds:si)
		es 	= segment of InkClass
		ax	= message #
RETURN:		carry set if the copy was unsuccessful for any reason
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkPaste	method dynamic InkClass, MSG_META_CLIPBOARD_PASTE
	.enter

	test	ds:[di].II_flags, mask IF_SELECTING	;No paste allowed while
	LONG jnz exit					; selecting.

	clr	di				;Erase selection (if any)
	call	RedrawSelection				; 	

;	ClipboardQueryItem:
;	PASS:
;	bp - ClipboardItemFlags (for quick/normal)
;	RETURN:
;	bp - number of formats available (0 if no transfer item)
;	cx:dx - owner of transfer item
;	bx:ax - (VM file handle):(VM block handle) to transfer item header
;			(pass to ClipboardRequestItemFormat)

	clr	bp
	call	ClipboardQueryItem
	push	ax,bx
	tst	bp
	LONG jz	done

;	ClipboardRequestItemFormat:
;	PASS:
;	cx:dx - format manufacturer:format type
;	bx:ax = transfer item header (returned by ClipboardQueryItem)
;	RETURN:
;	bx - file handle of transfer item
;	ax:bp - VM chain (0 if none)
;	cx - extra data word 1
;	dx - extra data word 2

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_INK
	call	ClipboardRequestItemFormat
	tstdw	axbp			;Exit if no ink data
	jz	done


	call	AppendDataFromTransferFormat
	jc	done

;	Draw the appended data

	mov_tr	ax, di			;AX <- offset to first point of pasted
					; data
	call	RedrawInk

done:
	pop	ax,bx
	call	ClipboardDoneWithItem
	clr	di			;Redraw the selection (if any)
	call	RedrawSelection
exit:
	.leave
	ret
InkPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Cut the selected area to the clipboard
CALLED BY:	GLOBAL
PASS:		*ds:si	= InkClass object
		ds:di	= InkClass instance data
		ds:bx	= InkClass object (same as *ds:si)
		es 	= segment of InkClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkCut	method dynamic InkClass, MSG_META_CLIPBOARD_CUT
	uses	ax, cx, dx, bp
	.enter

	test	ds:[di].II_flags, mask IF_SELECTING
	jnz	exit

	mov	ax, MSG_META_CLIPBOARD_COPY
	call	ObjCallInstanceNoLock	

	mov	bp, offset CutUndoString
	call	StartUndoChain

	mov	ax, MSG_META_DELETE
	call	ObjCallInstanceNoLock

	call	EndUndoChain
exit:
	.leave
	ret
InkCut	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoAllData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undoes an "IUT_ALL_DATA"-type undo action.

CALLED BY:	GLOBAL
PASS:		ss:bp - UndoActionStruct
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx,bp,di,es 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UndoAllData	proc	near
	.enter
EC <	cmp	ss:[bp].UAS_dataType, UADT_VM_CHAIN			>
EC <	ERROR_NZ	BAD_UNDO_ACTION_DATA_TYPE			>

;	Generate a "redo" action

	mov	bx, ss:[bp].UAS_data.UADU_vmChain.UADVMC_file
	movdw	axdi, ss:[bp].UAS_data.UADU_vmChain.UADVMC_vmChain
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di].R_left
	mov	bx, es:[di].R_top
	mov	cx, es:[di].R_right
	mov	dx, es:[di].R_bottom
	call	DBUnlock
	call	GenerateAllUndoAction

;	Load the data from the file

	call	FreeInkData

	push	ax
	push	bx, cx, dx
	mov	bx, ss:[bp].UAS_data.UADU_vmChain.UADVMC_file
	movdw	axdi, ss:[bp].UAS_data.UADU_vmChain.UADVMC_vmChain
	clr	cx
	clr	dx
	mov	bp, size Rectangle
	call	AppendDataFromFile
	call	MarkInkDirty
	pop	bx, cx, dx
	call	GetStrokeWidthAndHeight
	add	cl, al
	adc	ch, 0
	add	dl, ah
	adc	dh, 0
	pop	ax

;	Redraw the area that changed

	call	ForceInval
	.leave
	ret
UndoAllData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNumStrokes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applies an undo action with the old # strokes.

CALLED BY:	GLOBAL
PASS:		ss:bp - UndoActionStruct
		*ds:si - ink object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx,bp,di,es 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UndoNumStrokes	proc	near
	class	InkClass
	.enter

;
;	The data passed to us is a pointer to an UndoNumStrokesStruct.
;

EC <	cmp	ss:[bp].UAS_dataType, UADT_OPTR				>
EC <	ERROR_NZ	BAD_UNDO_ACTION_DATA_TYPE			>

	movdw	bxdi, ss:[bp].UAS_data.UADU_optr.UADO_optr

	call	MemDerefES
	mov	di, es:[di]

;	Generate a "redo" item.

	mov	ax, es:[di].UNSS_bounds.R_left
	mov	bx, es:[di].UNSS_bounds.R_top
	mov	cx, es:[di].UNSS_bounds.R_right
	mov	dx, es:[di].UNSS_bounds.R_bottom
	mov	bp, es:[di].UNSS_oldNumPoints
	call	GenerateNumStrokesAction

;	Delete the ink the user added.

	push	ax, bx, cx, dx, si		;Save object/bounds
	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	mov	si, ds:[si].II_segments
EC <	tst	si							>
EC <	ERROR_Z	-1							>

	mov_tr	ax, bp				;AX <- new # strokes to have
						; in array.
	mov	cx, -1				;Nuke the rest of the strokes
	call	ChunkArrayDeleteRange
	pop	ax, bx, cx, dx, si		;Restore object/bounds
	call	MarkInkDirty

;	Redraw the bounds of these strokes.

	push	ax
	call	GetStrokeWidthAndHeight
	add	cl, al
	adc	ch, 0
	add	dl, ah
	adc	dh, 0
	pop	ax
	call	ForceInval
	.leave
	ret
UndoNumStrokes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddSegmentsToObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the passed segments to the object

CALLED BY:	GLOBAL
PASS:		es:di - ptr to array of Points
		cx - # points to add
		*ds:si - Ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddSegmentsToObject	proc	near	uses	si
	.enter
	push	di
	push	cx				;Save # points to add
	call	CreateRoomForSegments
	pop	cx

;	Copy the ink segments into the segment block

	pop	si
	segxchg	es, ds				;ES:DI <- ptr to dest for
						; segments
						;DS:SI <- ptr to source for
						; segments	
	shl	cx, 1				;CX <- # words to copy
	rep	movsw
	segxchg	es, ds
	.leave
	ret
AddSegmentsToObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoStrokeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applies an undo action with the old # strokes.

CALLED BY:	GLOBAL
PASS:		ss:bp - UndoActionStruct
		*ds:si - ink object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx,bp,di,es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UndoStrokeData	proc	near	uses	si
	class	InkClass
	.enter	

;
;	The data passed to us is a pointer to an UndoStrokeDataStruct.
;

EC <	cmp	ss:[bp].UAS_dataType, UADT_VM_CHAIN			>
EC <	ERROR_NZ	BAD_UNDO_ACTION_DATA_TYPE			>

	mov	bx, ss:[bp].UAS_data.UADU_vmChain.UADVMC_file
	mov	ax, ss:[bp].UAS_data.UADU_vmChain.UADVMC_vmChain.high
	call	VMLock
	mov	es, ax
	push	bp

;	Generate a "redo" item.

	call	GetNumPoints		;AX <- # items
	push	ax
	mov_tr	di, ax
	mov	ax, es:USDS_bounds.R_left
	mov	bx, es:USDS_bounds.R_top
	mov	cx, es:USDS_bounds.R_right
	mov	dx, es:USDS_bounds.R_bottom
	call	GenerateInkUndoAction

;	Add the ink strokes back into the object

	mov	cx, es:USDS_numPoints		;CX <- # points to add
	mov	di, offset USDS_data

EC <	ERROR_C	-1							>
	call	AddSegmentsToObject
	call	MarkInkDirty

;	Draw the ink we just re-added.

	pop	ax				;

	call	RedrawInk

	pop	bp
	call	VMUnlock
	.leave
	ret
UndoStrokeData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceInval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invals the passed bounds.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		(ax, bx) (cx,dx) bounds to redraw (in object coords)
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceInval	proc	near
	class	VisClass
	.enter
EC <	call	ECCheckIfInkObject					>
	sub	sp, size VisAddRectParams
	mov	bp, sp
	clr	ss:[bp].VARP_flags

;	Adjust the bounds in object coordinates (relative to the origin of
;	the object) to be bounds relative to the origin of the window
;
;	Also, clip the boundary region to our bounds, so we don't invalidate
;	outside our bounds.
;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	ax, ds:[di].VI_bounds.R_left
	cmp	ax, ds:[di].VI_bounds.R_right
	jbe	10$
	mov	ax, ds:[di].VI_bounds.R_right
10$:
	mov	ss:[bp].VARP_bounds.R_left, ax
	add	cx, ds:[di].VI_bounds.R_left
	cmp	cx, ds:[di].VI_bounds.R_right
	jbe	20$
	mov	cx, ds:[di].VI_bounds.R_right
20$:
	mov	ss:[bp].VARP_bounds.R_right, cx
	add	bx, ds:[di].VI_bounds.R_top
	cmp	bx, ds:[di].VI_bounds.R_bottom
	jbe	30$
	mov	bx, ds:[di].VI_bounds.R_bottom
30$:
	mov	ss:[bp].VARP_bounds.R_top, bx
	add	dx, ds:[di].VI_bounds.R_top
	cmp	dx, ds:[di].VI_bounds.R_bottom
	jbe	40$
	mov	dx, ds:[di].VI_bounds.R_bottom
40$:
	mov	ss:[bp].VARP_bounds.R_bottom, dx

	mov	dx, size VisAddRectParams
	mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	call	ObjCallInstanceNoLock
	add	sp, size VisAddRectParams
	.leave
	ret
ForceInval	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message handler undoes the data.

CALLED BY:	GLOBAL
PASS:		ss:bp - ptr to UndoActionStruct
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkUndo	method	InkClass, MSG_META_UNDO
	.enter
	call	NukeSelection

	mov	di, ss:[bp].UAS_appType.low
EC <	cmp	di, InkUndoType						>
EC <	ERROR_AE	BAD_UNDO_TYPE					>

	call	cs:[inkUndoHandlers][di]	;Returns ax, bx, cx, dx - 
						; bounds of undo
	.leave
	ret
InkUndo	endp

inkUndoHandlers	nptr	UndoAllData
		nptr	UndoNumStrokes
		nptr	UndoStrokeData

				   


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToProcessStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the process.

CALLED BY:	GLOBAL
PASS:		ax, cx, dx, bp - data for message
RETURN:		ds,es - lmem blocks
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToProcessStack	proc	near	uses	bx, di
	.enter
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	.leave
	ret
SendToProcessStack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a new undo chain, if undo is enabled.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
		bp - chunk handle of undo chain title
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartUndoChain	proc	near	uses	ax, dx, bp
	.enter
	call	CheckForUndo
	jz	exit
	mov_tr	ax, bp				;AX <- chunk handle of title
	mov	dx, size StartUndoChainStruct
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].SUCS_title.chunk, ax
	mov	ss:[bp].SUCS_title.handle, handle ControlStrings
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].SUCS_owner.handle, ax
	mov	ss:[bp].SUCS_owner.chunk, si
	mov	ax, MSG_GEN_PROCESS_UNDO_START_CHAIN
	call	SendToProcessStack
	add	sp, dx
exit:
	.leave
	ret
StartUndoChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ends a new undo chain, if undo is enabled.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
		bp - chunk handle of undo chain title
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndUndoChain	proc	near	uses	ax, bx, cx, di
	call	CheckForUndo
	jz	exit
	.enter
	mov	ax, MSG_GEN_PROCESS_UNDO_END_CHAIN
	call	GeodeGetProcessHandle
	mov	cx, -1			;Don't allow empty chains
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
exit:
	ret
EndUndoChain	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipBoundsToObjectBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clips the bounds to the object bounds

CALLED BY:	GLOBAL
PASS:		ax, bx, cx, dx - signed coords
		*ds:si - object
RETURN:		ax, bx, cx, dx - clipped to obj coords
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipBoundsToObjectBounds	proc	near	uses	di
	class	VisClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ax, ds:[di].VI_bounds.R_left
	jge	10$
	mov	ax, ds:[di].VI_bounds.R_left
10$:
	cmp	bx, ds:[di].VI_bounds.R_top
	jge	20$
	mov	bx, ds:[di].VI_bounds.R_top
20$:

	cmp	cx, ds:[di].VI_bounds.R_right
	jle	30$
	mov	cx, ds:[di].VI_bounds.R_right
30$:
	cmp	cx, ds:[di].VI_bounds.R_left
	jge	35$
	mov	cx, ds:[di].VI_bounds.R_left
35$:
	cmp	dx, ds:[di].VI_bounds.R_bottom
	jle	40$
	mov	dx, ds:[di].VI_bounds.R_bottom
40$:
	cmp	dx, ds:[di].VI_bounds.R_top
	jge	exit
	mov	dx, ds:[di].VI_bounds.R_top
exit:
	.leave
	ret
ClipBoundsToObjectBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAllUndoVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates an undo VM Chain

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		ax, bx, cx, dx - bounds of undo area
RETURN:		ax:di - vm chain
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAllUndoVMChain	proc	near	uses	bx, cx, dx, es, bp
	call	CheckForUndo
	jz	exit
	.enter
	call	ClipBoundsToObjectBounds

	push	ax, bx, cx, dx

;	Create a VMChain holding all of the data for the object.

	sub	sp, size InkDBFrame
	mov	bp, sp
	clrdw	ss:[bp].IDBF_DBGroupAndItem
	mov	ss:[bp].IDBF_DBExtra, size Rectangle
	mov	ss:[bp].IDBF_bounds.R_left, 0
	mov	ss:[bp].IDBF_bounds.R_top, 0
	mov	ss:[bp].IDBF_bounds.R_right, -1
	mov	ss:[bp].IDBF_bounds.R_bottom, -1

;	Get the file to create the vm chain in

	call	GenProcessUndoGetFile
	mov	ss:[bp].IDBF_VMFile, ax
	push	ax
	call	SaveInk
	pop	bx				;BX <- vm file handle
	add	sp, size InkDBFrame

	mov	di, bp

	call	DBLock
	call	DBDirty
	mov	di, es:[di]
	pop	es:[di].R_left, es:[di].R_top, es:[di].R_right, es:[di].R_bottom
	call	DBUnlock
	mov	di, bp

	.leave
exit:
	ret
CreateAllUndoVMChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateAllUndoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates an undo action that contains all the data for the
		passed object.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
		ax, bx, cx, dx - bounds of change
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateAllUndoAction	proc	near	uses	ax, bx, cx, dx, di, bp, es
	call	CheckForUndo
	jz	exit
	.enter

	call	CreateAllUndoVMChain		;Returns AX.DI as the 
						; vmChain

	mov	dx, size AddUndoActionStruct
	sub	sp, dx
	mov	bp, sp

	clr	ss:[bp].AUAS_flags
	mov	ss:[bp].AUAS_data.UAS_dataType, UADT_VM_CHAIN
	mov	ss:[bp].AUAS_data.UAS_appType.low, IUT_ALL_DATA
	movdw	ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain, axdi
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].AUAS_output.handle, ax
	mov	ss:[bp].AUAS_output.chunk, si

	mov	ax, MSG_GEN_PROCESS_UNDO_ADD_ACTION
	call	SendToProcessStack
	add	sp, dx
	.leave
exit:
	ret
GenerateAllUndoAction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateInkUndoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates an undo action that just contains the number of
		strokes that are currently in the object

CALLED BY:	GLOBAL
PASS:		ax, bx, cx, dx - bounds
		di - # strokes in object
		*ds:si - ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateInkUndoAction	proc	near	uses	ax, bx, cx, dx, bp, di
	call	CheckForUndo
	jz	exit
	.enter
	call	ClipBoundsToObjectBounds
	sub	sp, size UndoNumStrokesStruct + size AddUndoActionStruct
	mov	bp, sp
	mov	ss:[bp].UNSS_oldNumPoints, di
	mov	ss:[bp].UNSS_bounds.R_left,ax
	mov	ss:[bp].UNSS_bounds.R_top,bx
	mov	ss:[bp].UNSS_bounds.R_right,cx
	mov	ss:[bp].UNSS_bounds.R_bottom,dx
	add	bp, size UndoNumStrokesStruct
	mov	dx, size AddUndoActionStruct
	clr	ss:[bp].AUAS_flags
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].AUAS_output.handle, ax
	mov	ss:[bp].AUAS_output.chunk, si

	mov	ss:[bp].AUAS_data.UAS_dataType, UADT_PTR
	mov	ss:[bp].AUAS_data.UAS_appType.low, IUT_NUM_STROKES
	movdw	ss:[bp].AUAS_data.UAS_data.UADU_ptr.UADP_ptr, sssp
	mov	ss:[bp].AUAS_data.UAS_data.UADU_ptr.UADP_size, size UndoNumStrokesStruct
	mov	ax, MSG_GEN_PROCESS_UNDO_ADD_ACTION
	call	SendToProcessStack
	add	sp, size UndoNumStrokesStruct + size AddUndoActionStruct
	.leave
exit:	
	ret
GenerateInkUndoAction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNumStrokesUndoVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a VM Chain containing a bunch of strokes for redoing
		ink/pastes.

CALLED BY:	GenerateNumStrokesAction
PASS:		ax, bx, cx, dx - bounds
		bp - index of first stroke to save
RETURN:		ax.di - vm chain
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNumStrokesUndoVMChain	proc	near	uses	bx, cx, dx, bp, si, es
	class	InkClass
	.enter
	call	ClipBoundsToObjectBounds
	push	bp			;Save index of first point to save
	push	ax, bx, cx, dx		;Save bounds

;	Get the file handle to allocate the data in

	push	bp
	mov	ax, MSG_GEN_PROCESS_UNDO_GET_FILE
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	mov_tr	bx, ax			;BX <- VM File

;	Allocate space in the file for the stroke data

	call	GetNumPoints
	sub	ax, bp			;AX <- # points to add
	push	ax			;Save # points
.assert size Point eq 4
	shl	ax
	shl	ax			;AX <- size of points
	add	ax, UndoStrokeDataStruct
	mov_tr	cx, ax			;CX <- size to allocate	
	call	VMAlloc
	mov	dx, ax			;DX <- VM block handle

;	Copy the bounds/# points information

	pop	cx			;CX <- # points added
	call	VMLock
	call	VMDirty
	mov	es, ax
	clr	es:[USDS_meta].VMCL_next
	mov	es:[USDS_numPoints], cx
	pop	es:[USDS_bounds].R_left, es:[USDS_bounds].R_top, \
		es:[USDS_bounds].R_right, es:[USDS_bounds].R_bottom

;	Copy the stroke data over

	pop	ax			;Restore index of first stroke	
	jcxz	done			;If no strokes to copy, branch
	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	mov	si, ds:[si].II_segments
	call	ChunkArrayElementToPtr
	mov	si, di			;DS:SI <- source for data
	mov	di, offset USDS_data	;ES:DI <- dest for data
	shl	cx
	rep	movsw
done:
	call	VMUnlock
	mov_tr	ax, dx			;AX.DI <- VM Chain
	clr	di
	.leave
	ret
CreateNumStrokesUndoVMChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateNumStrokesAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates an undo action that contains the strokes that
		have been deleted.

CALLED BY:	GLOBAL
PASS:		ax, bx, cx, dx - bounds
		bp - # strokes that should be in the object 
			(we add all the strokes after these)
		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateNumStrokesAction	proc	near	uses	ax, bx, cx, dx, bp, si, di, es
	.enter

	call	CreateNumStrokesUndoVMChain

	mov	dx, size AddUndoActionStruct
	sub	sp, dx
	mov	bp, sp

	clr	ss:[bp].AUAS_flags
	mov	ss:[bp].AUAS_data.UAS_dataType, UADT_VM_CHAIN
	mov	ss:[bp].AUAS_data.UAS_appType.low, IUT_STROKE_DATA
	movdw	ss:[bp].AUAS_data.UAS_data.UADU_vmChain.UADVMC_vmChain, axdi
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].AUAS_output.handle, ax
	mov	ss:[bp].AUAS_output.chunk, si

	mov	ax, MSG_GEN_PROCESS_UNDO_ADD_ACTION
	call	SendToProcessStack
	add	sp, dx
	.leave
	ret
GenerateNumStrokesAction	endp

InkEdit	ends
