COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineGoto.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 6/92   	Initial version.

DESCRIPTION:
	

	$Id: splineGoto.asm,v 1.1 97/04/07 11:09:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplinePtrCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGotoPointCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goto the point specified by ax, bx, cx, and dx

CALLED BY:	internal

PASS:		ax - current point number
		bh - mask of desired point's info record
		bl - bits to test of the info record
		cx - maximum allowable distance from current pt. to
		     desired point
		dx - direction to move (+1 or -1)
		*ds:si = points array

RETURN:		point found: 
			carry clear and ax = point #
			ds:[di] = new point
		point not found:
			carry set, ax = original point #
			di - destroyed

DESTROYED:	bx, cx

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	Use the BH and BL registers as MASK and COMPARES
	against the current point's info record.  Continue looping 
	(CX = COUNT) until the right point is found.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoPointCommon	proc	near
	push	ax			; original. point #
start:
	add	ax, dx			; increment (or decrement) pt #
	js	notFound		; we've gone negative
	call	ChunkArrayElementToPtr	; get the point in di
	jc	notFound

	;
	; There is a point, so see if it's the right one.  BH contains
	; a mask of the interesting bits, and BL contains the bits
	; that SHOULD be set.  If the right bits are set, then we've
	; found the point, otherwise keep looking.  
	;

	push	bx			; save bx
	andnf	bh, ds:[di].SPS_info	; zero out uninteresting bits
	cmp	bh, bl			; see if this is the point we want
	pop	bx			; restore bx
	je	found			; YES, we've found the point 
	loop	start			; NO, keep looking

notFound:
	stc				; if at end of loop, set carry
	pop	ax			; point not found, restore old one
	jmp	done

found:
	;
	; We've found the point.  (carry is clear here).  remove the
	; old point number from the stack, and exit
	;

	inc	sp
	inc	sp
done:
	ret
SplineGotoPointCommon	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGotoAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the anchor that "owns" the current control point
		OR, if the current point is an anchor point, then do nothing.

CALLED BY:	internal

PASS:		*ds:si - chunk array
		ax - current control point (or anchor point number)

RETURN:		ax - anchor point number
		ds:di - anchor point

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This procedure can NEVER return with the carry set, since, by
definition, every control point has an anchor point.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoAnchor	proc 	far
	uses	bx, cx, dx

	.enter

EC <	call	ECSplinePoint			>

	call	ChunkArrayElementToPtr
	mov	bl, ds:[di].SPS_info
	test	bl, mask PIF_CONTROL
	jz	done

	mov	cx, 1				; move 1 point at most
	test	bl, mask CPIF_PREV		; see if we're at a PREV ctrl
	mov	bx, FIND_ANCHOR			; move FIND info into bx
	mov	dx, MOVE_BACK			; NO: move back
	jnz	forward				; YES (previous): move forward
	jmp	doIt
forward:
	mov	dx, MOVE_FORWARD
doIt:
	call	SplineGotoPointCommon
done:
EC <	call	ECSplineAnchorPoint		>
	.leave
	ret
SplineGotoAnchor 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGotoOtherControlPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	based on the info record in the CURRENT control point,
		go to the OTHER one

CALLED BY:	internal

PASS:		*ds:si - points chunk
		ax - current point number

RETURN:		same as SplineGotoPointCommon

DESTROYED:	nothing

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoOtherControlPoint	proc	far
	uses	bx
	.enter
EC <	call	ECSplineControlPoint	>
	call	ChunkArrayElementToPtr
	mov	bl, ds:[di].SPS_info
	call	SplineGotoAnchor	; go to the anchor point
	TOGGLE	bl, CPIF_PREV
	call	SplineGotoNextOrPrev	; now go to the OTHER control point
	.leave
	ret
SplineGotoOtherControlPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGotoPrevAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move backwards in the chunk array until the previous
		anchor point is found.  Assumes that ax is currently
		an anchor point.

CALLED BY:	internal

PASS:		*ds:si - array
		es:bp - VisSplineInstance data
		ax - current anchor point number

RETURN:		same values as SplineGotoPointCommon

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoPrevAnchorFar	proc	far
	call	SplineGotoPrevAnchor
	ret
SplineGotoPrevAnchorFar	endp

SplineGotoPrevAnchor	proc	near
	uses	bx, cx, dx
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints	>
EC <	call	ECSplineAnchorPoint >	
	mov	cx, 3		; move 3 points at most
	mov	dx, MOVE_BACK	; backwards
	mov	bx, FIND_ANCHOR	; until an anchor is found
	call	SplineGotoPointCommon	
	jnc	done

	call	SplineCheckIfOpenCurve
	jc	done
	
	; It's a closed curve, so go to the last anchor.
	call	SplineGotoLastAnchor
done:
	.leave
	ret
SplineGotoPrevAnchor	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCheckIfOpenCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the curve is Open or Closed. Set the CARRY if
		the curve is OPEN

CALLED BY:	SplineGotoPrevAnchor, SplineGotoNextAnchor

PASS:		*es:bp - spline
		*ds:si - points

RETURN:		carry flag - set if curve is OPEN

DESTROYED:	di

PSEUDO CODE/STRATEGY:	
	The curve is always open during CREATE modes. It is also open
if the SS_CLOSED bit is not set.
	
	I can rely on the TEST instruction clearing the carry...

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCheckIfOpenCurve	proc	near
	uses	ax
	class	VisSplineClass
	.enter

	;
	; In CREATE modes, curve is always open:
	;

	GetMode	al
	cmp	al, SM_BEGINNER_POLYLINE_CREATE
	je	open
	cmp	al, SM_BEGINNER_SPLINE_CREATE
	je	open
	cmp	al, SM_ADVANCED_CREATE
	je	open

	;
	; If closed bit set, then clear carry (done by TEST
	; instruction), and exit
	;

	test	es:[bp].VSI_state, mask SS_CLOSED
	jnz	done

open:
	stc
done:
	.leave
	ret
SplineCheckIfOpenCurve	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGotoNextAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go from the current anchor point to the next one

CALLED BY:	internal

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		ax - current point number

RETURN:		same as SplineGotoPointCommon

DESTROYED:	nothing

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoNextAnchorFar	proc	far
	call	SplineGotoNextAnchor
	ret
SplineGotoNextAnchorFar	endp

SplineGotoNextAnchor	proc	near
	uses	bx, cx, dx
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints		>
EC <	call	ECSplineAnchorPoint			>

	mov	cx, 3
	mov	dx, MOVE_FORWARD
	mov	bx, FIND_ANCHOR	
	call	SplineGotoPointCommon
	jnc	done

	call	SplineCheckIfOpenCurve
	jc	done

	; It's a "Closed" curve, so the NEXT anchor is actually the FIRST
	; anchor.
	call	SplineGotoFirstAnchor
done:
	.leave
	ret
SplineGotoNextAnchor	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGotoFirstAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the first anchor point

CALLED BY:	throughout library

PASS:		*ds:si - points array 
		es:bp - VisSplineInstance data 

RETURN:		CARRY set if no points in array
		OTHERWISE:
			ax - anchor point number 
			di - anchor point data

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/25/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoFirstAnchor	proc	far
	uses	cx
	.enter
EC <	call	ECSplineInstanceAndPoints		>  

	call	ChunkArrayGetCount
	jcxz	noPoints
	clr	ax
	call	SplineGotoAnchor
done:
	.leave
	ret

noPoints:
	stc
	jmp	done
SplineGotoFirstAnchor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGotoLastAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the last anchor point

CALLED BY:	global

PASS:		*ds:si - points array

RETURN:		ax - point number of last point
		ds:di - point data

		OR - carry set if no points

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/18/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoLastAnchor	proc	far
	uses	cx
	.enter
	call	ChunkArrayGetCount
	jcxz	notFound
	mov	ax, cx
	dec	ax
	call	SplineGotoAnchor
	jmp	done
notFound:
	stc
done:
	.leave
	ret
SplineGotoLastAnchor	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGotoNextFarControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	SplineGotoNextFarControl: 
		Go to the PREV control of the NEXT anchor point


CALLED BY:	SplineOperateOnSelectedPointsCB

PASS:		ax - current point
		*ds:si - spline points chunk array		
RETURN:		same as SplineGotoPointCommon

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoNextFarControl	proc	near
	mov	di, offset SplineGotoPrevControl
	GOTO	SplineGotoFromNextAnchor
SplineGotoNextFarControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGotoPrevFarControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the NEXT control of the PREV anchor point

CALLED BY:

PASS:		ax - current point
		*ds:si - spline points chunk array		
RETURN:		same as SplineGotoPointCommon

DESTROYED:	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoPrevFarControl	proc near
	mov	di, offset SplineGotoNextControl
	GOTO	SplineGotoFromPrevAnchor
SplineGotoPrevFarControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGotoFromPrevAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	goto a point related to the Prev anchor of this point

CALLED BY:	INTERNAL

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - anchor #
		di - procedure to call if there's a prev anchor 

RETURN:		same values as SplineGotoPointCommon

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoFromPrevAnchor	proc near
	push	ax
	push	di
	call	SplineGotoPrevAnchor
	pop	di
	jc	notFound
	inc	sp
	inc	sp
	call	di
done:
	ret
notFound:
	pop	ax
	jmp	done
SplineGotoFromPrevAnchor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGotoFromNextAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	goto a point related to the Next anchor of this point

CALLED BY:	INTERNAL

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - anchor #
		di - procedure to call if there's a next anchor 

RETURN:		same values as SplineGotoPointCommon

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoFromNextAnchor	proc near
	push	ax
	push	di
	call	SplineGotoNextAnchor
	pop	di
	jc	notFound
	inc	sp
	inc	sp
	call	di
done:
	ret
notFound:
	pop	ax
	jmp	done
SplineGotoFromNextAnchor	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGotoNextOrPrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the "Next" or "Previous" control point
		owned by the current anchor point.

CALLED BY:	internal

PASS:		ax - current anchor point #
		*ds:si - chunk array
		bl = SPT_NEXT_CONTROL or SPT_PREV_CONTROL

RETURN:		see SplineGotoPointCommon

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGotoNextOrPrev	proc	far
EC <	call	ECSplineAnchorPoint	>	; make sure at anchor pt

	test	bl, mask CPIF_PREV
	jnz	prev
	call	SplineGotoNextControl
	jmp	done
prev:
	call 	SplineGotoPrevControl
done:
	.leave
	ret
SplineGotoNextOrPrev	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGotoNextControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move to this point's NEXT control point.  Assume at
		anchor point

CALLED BY:	internal

PASS:		*ds:si - points list
		ax - anchor point #

RETURN:		same as SplineGotoPointCommon

DESTROYED:	nothing

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoNextControlFar	proc	far
	call	SplineGotoNextControl
	ret
SplineGotoNextControlFar	endp

SplineGotoNextControl	proc	near
	uses	bx, cx, dx
	.enter
EC <	call	ECSplineAnchorPoint	>	; make sure at anchor pt
	mov	bx, FIND_NEXT_CONTROL
	mov	cx, 1
	mov	dx, MOVE_FORWARD
	call	SplineGotoPointCommon	
	.leave
	ret
SplineGotoNextControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGotoPrevControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go from the current anchor point to the previous
		control point

CALLED BY:	internal

PASS:		ax - anchor point number
		*ds:si points array

RETURN:		same as SplineGotoPointCommon

DESTROYED:	nothing

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGotoPrevControlFar	proc	far
	call	SplineGotoPrevControl
	ret
SplineGotoPrevControlFar	endp

SplineGotoPrevControl	proc	near
	uses	bx, cx, dx
	.enter
EC <	call	ECSplineAnchorPoint			>
	mov	bx, FIND_PREV_CONTROL
	mov	cx, 1
	mov	dx, MOVE_BACK
	call	SplineGotoPointCommon
	.leave
	ret
SplineGotoPrevControl	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGoto2ndNextAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go to the anchor 2 ahead of this one

CALLED BY:	INTERNAL

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - anchor #

RETURN:		return/destroyed same as SplineGotoPointCommon

DESTROYED:	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGoto2ndNextAnchor	proc near
	mov	di, offset SplineGotoNextAnchor
	GOTO	SplineGotoFromNextAnchor
SplineGoto2ndNextAnchor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGoto2ndPrevAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go to the anchor 2 back from here

CALLED BY:	INTERNAL

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - anchor #

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGoto2ndPrevAnchor	proc near
	mov	di, offset SplineGotoPrevAnchor
	GOTO	SplineGotoFromPrevAnchor
SplineGoto2ndPrevAnchor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGoto2ndPrevFarControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the PrevFar control of the previous anchor

CALLED BY:	INTERNAL

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - anchor #

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGoto2ndPrevFarControl	proc near
	mov	di, offset SplineGotoPrevFarControl
	GOTO	SplineGotoFromPrevAnchor
SplineGoto2ndPrevFarControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGoto2ndPrevControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the Prev control of the previous anchor

CALLED BY:	INTERNAL

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - anchor #


RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGoto2ndPrevControl	proc near
	mov	di, offset SplineGotoPrevControl
	GOTO	SplineGotoFromPrevAnchor
SplineGoto2ndPrevControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGoto2ndNextControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the Next control of the next anchor

CALLED BY:	INTERNAL

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - anchor #

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGoto2ndNextControl	proc near
	mov	di, offset SplineGotoNextControl
	GOTO	SplineGotoFromNextAnchor
SplineGoto2ndNextControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGoto2ndNextFarControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the NextFar control of the Next anchor

CALLED BY:	INTERNAL

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - anchor #

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGoto2ndNextFarControl	proc near
	mov	di, offset SplineGotoNextFarControl
	GOTO	SplineGotoFromNextAnchor
SplineGoto2ndNextFarControl	endp



SplinePtrCode	ends
