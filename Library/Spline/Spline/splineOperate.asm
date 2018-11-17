COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VisSpline object
FILE:		splineOperate.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

ROUTINES:
	SplineAddDeltas
	SplineAddToNew
	SplineModifyInfoFlags
	SplineOperateOnAllPoints
	SplineOperateOnAllPointsCB
	SplineOperateOnCurrentPoint
	SplineOperateOnNewPoints
	SplineOperateOnPointCommon
	SplineOperateOnSelectedOrNew
	SplineOperateOnSelectedPoints
	SplineOperateOnSelectedPointsCB
	SplineOperateOnWhichPoints
	SplineSelectCodeOperations
	SplineTransformPoint

DESCRIPTION:
	These procedures perform various "operations" on the spline's
	points.  The operation to be performed is specified by 
	a SplineOperateType enum, and a call table.

	$Id: splineOperate.asm,v 1.1 97/04/07 11:09:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplinePtrCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnSelectedPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform operations on selected points based on the
		flag passed

CALLED BY:	everywhere (internal)

PASS:		es:bp - VisSplineInstance data

		al - SplineOperateType
		ah - SplineDrawFlags (for SOT_DRAW and SOT_ERASE)
		bx - SplineWhichPointFlags

		cx, dx - parameters to pass to lower-level routines

RETURN:		if SOT_CHECK_MOUSE_HIT or SOT_CHECK_MOUSE_HIT_SEGMENT
		 was passed:
			CARRY SET iff mouse hit detected,
		else:
			nothing		
	
DESTROYED:	nothing

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnSelectedPoints	proc	near
	uses	di
	class	VisSplineClass
	.enter
	mov	di, offset VSI_selectedPoints
	call	SplineOperateOnSelectedOrNew
	.leave
	ret
SplineOperateOnSelectedPoints	endp

SplineOperateOnSelectedPointsFar	proc far
	call	SplineOperateOnSelectedPoints
	ret
SplineOperateOnSelectedPointsFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnNewPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform operations on selected points based on the
		flag passed

CALLED BY:	everywhere (internal)

PASS:		es:bp - VisSplineInstance data

		al - SplineOperateType
		bx - SplineWhichPointFlags

		cx, dx - parameters to pass to lower-level routines

RETURN:		if SOT_CHECK_MOUSE_HIT or SOT_CHECK_MOUSE_HIT_SEGMENT
		 was passed:
			CARRY SET iff mouse hit detected,
		else:
			nothing		
	
DESTROYED:	nothing

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnNewPoints	proc	far
	uses	di
	class	VisSplineClass
	.enter
	mov	di, offset VSI_newPoints 
	call	SplineOperateOnSelectedOrNew
	.leave
	ret
SplineOperateOnNewPoints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnSelectedOrNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform operations on selected (new) points based on the
		flag passed

CALLED BY:	SplineOperateOnSelectedPoints, SplineOperateOnNewPoints

PASS:		es:bp - VisSplineInstance data
		di - offset from start of instance data to chunk
		handle of array to traverse

		al - SplineOperateType
		ah - SplineDrawFlags (if al=SOT_ERASE or SOT_DRAW)
		bx - SplineWhichPointFlags

		cx, dx - parameters to pass to lower-level routines

RETURN:		if SOT_CHECK_MOUSE_HIT or SOT_CHECK_MOUSE_HIT_SEGMENT
		 was passed:
			CARRY SET iff mouse hit detected,
		else:
			nothing		
	
DESTROYED:	di (saved by calling routine)

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnSelectedOrNew	proc	near
	uses	ax,bx,cx,dx,si
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndLMemBlock>


	; get array chunk handle, freeing up di
		
	mov	si, es:[bp][di]
	tst	si
	jz	done

	;
	; Call the setup routine.  We also want to move the
	; SplineWhichPointFlags into DX, but can't do so until after
	; the setup routine is called, as we might be passing
	; parameters in via (cx, dx).
	;

	push	bx			; SplineWhichPointFlags
	mov	bx, ax
	call	SplineOperateSetup
	pop	dx			; SplineWhichPointFlags
	jc	done

	mov_tr	cx, ax			; SplineOperateType, SplineDrawFlags

	; store a "high" point number before starting
	mov	ax, SPLINE_MAX_POINT+1
	call	SplineSaveAnchorSD

	mov	bx, cs
	mov	di, offset SplineOperateOnSelectedPointsCB
	call	ChunkArrayEnum
done:
	.leave
	ret

SplineOperateOnSelectedOrNew	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineOperateSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform whatever gets done before traversal.  In some
		cases, this means check to see if the traversal should
		be performed...

CALLED BY:

PASS:		es:bp - VisSplineInstance data 
		bl - SplineOperateType
		cx,dx - data (in some cases)

RETURN:		carry set to abort operation, clear otherwise

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateSetup	proc near
	class	VisSplineClass 

	SplineDerefScratchChunk di
	BitClr	ds:[di].SD_flags, SDF_STOP_ENUMERATION
	clr	bh
EC <	cmp	bx, SplineOperateType		>
EC <	ERROR_G	ILLEGAL_CALL_TABLE_VALUE	>
	GOTO	cs:[bx].SplineOperateSetupCalls

SplineOperateSetup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCheckCanDrawAndSaveCXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the spline is drawable, and if so, save CX
		and DX in the scratch chunk.

CALLED BY:	SplineOperateSetup

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 
		cx, dx, - values to place in the scratch chunk

RETURN:		carry set if unable to draw.

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 1/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCheckCanDrawAndSaveCXDX	proc near
	.enter
	call	SplineCheckCanDraw
	jc	done
	call	SplineSaveCXDXToSD
done:
	.leave
	ret
SplineCheckCanDrawAndSaveCXDX	endp



		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnSelectedPointsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	CALLBACK routine to operate on selected points

CALLED BY:	ChunkArrayEnum	(SplineOperateOnSelectedPoints)

PASS:		cl - SplineOperateType
		ch - SplineDrawFlags 
		dx - SplineWhichPointFlags 
		ds:[di]- current anchor point number
		es:bp - VisSplineInstance data 

RETURN:		carry (set or clear) for certain operations

DESTROYED:	ax,si

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnSelectedPointsCB	proc	far
	uses	dx

	class	VisSplineClass

	.enter


 	mov	ax, ds:[di].SLE_pointNum 	; get element number

	mov	si, es:[bp].VSI_points		; get points array
						; chunk handle

EC <	call	ECSplineInstanceAndLMemBlock	> 

	call	SplineOperateOnWhichPoints
	.leave
	ret
SplineOperateOnSelectedPointsCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnAllPoints		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform some sort of operation on ALL the points of the
		spline.

CALLED BY:	internal


PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		al - SplineOperateType
		ah - SplineDrawFlags
		bx - SplineWhichPointFlags

		cx, dx - values to pass to lower-level routines

RETURN:		if SOT_CHECK_MOUSE_HIT or SOT_CHECK_MOUSE_HIT_SEGMENT
		 was passed:
			CARRY SET iff mouse hit detected
		else:
			nothing 

DESTROYED:	nothing
		(preserves AX which is munged by callback routine)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnAllPoints	proc	far
	uses		di
	.enter

	mov	di, offset SplineOperateOnAllPointsCB
	call	OperateOnAllOrRange
	.leave
	ret
SplineOperateOnAllPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OperateOnAllOrRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call ChunkArrayEnum for either all points, or a range
		of points.

CALLED BY:	SplineOperateOnAllPoints, SplineOperateOnRange

PASS:		es:bp - vis spline instance
		*ds:si - points
		di - offset of callback routine
		al - SplineOperateType
		ah - SplineDrawFlags
		bx - SplineWhichPointFlags

RETURN:		nothing 

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OperateOnAllOrRange	proc near
	uses	ax,bx,cx,dx
	.enter

EC <	call	ECSplineInstanceAndPoints	>

	push	bx, di	 	; SplineWhichPointFlags, callback
	mov	bx, ax
	call	SplineOperateSetup
	pop	dx, di		; SplineWhichPointFlags, callback
	jc	done

	mov_tr	cx, ax			; SplineOperateType, SplineDrawFlags
	mov	bx, cs
	call	ChunkArrayEnum
done:
	.leave
	ret
OperateOnAllOrRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnAllPointsCB		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Operate on each point in the points array

CALLED BY:	ChunkArrayEnum (SplineOperateOnAllPoints)

PASS:		ds:di - current point
		*ds:si - points array
		cl - SplineOperateType
		ch - SplineDrawFlags 
		dx - SplineWhichPointFlags
		es:bp - VisSplineInstance data 

RETURN:		carry

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnAllPointsCB	proc	far
	.enter
	test	ds:[di].SPS_info, mask PIF_CONTROL	; control pt?
	jnz	done					; skip.
	call	ChunkArrayPtrToElement		; get ax=point number
	call	SplineOperateOnWhichPoints
done:
	.leave
	ret
SplineOperateOnAllPointsCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineOperateOnRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Operate on a range of points.  

CALLED BY:

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		al - SplineOperateType
		ah - SplineDrawFlags
		bx - SplineWhichPointFlags

		scratch chunk contains 
			SD_firstPoint and
			SD_lastPoint 
			properly initialized
			

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnRange	proc far
	uses	di
	class	VisSplineClass

	.enter

	mov	di, offset SplineOperateOnRangeCB
	call	OperateOnAllOrRange

	.leave
	ret
SplineOperateOnRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineOperateOnRangeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine in the "operate on a range of points"
		procedure. 

CALLED BY:	ChunkArrayEnum via SplineOperateOnRange

PASS:		ds:di - point data
		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/31/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnRangeCB	proc far
	uses	di
	class	VisSplineClass 
	.enter

	; Skip if control point (carry is clear)
	test	ds:[di].SPS_info, mask PIF_CONTROL	
	jnz	done				

	call	ChunkArrayPtrToElement		; get ax=point number

	SplineDerefScratchChunk di
	cmp	ax, ds:[di].SD_firstPoint
	jl	nextPoint
	cmp	ax, ds:[di].SD_lastPoint
	jg	endEnum

	call	SplineOperateOnWhichPoints
done:
	.leave
	ret
endEnum:
	stc
	jmp	done
nextPoint:
	clc
	jmp	done
	
SplineOperateOnRangeCB	endp




	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineOperateOnCurrentPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an operation on only one point (or one
	point and its neighbors).

CALLED BY:	INTERNAL
  
PASS:		ax - point number
		bl - SplineOperateType
		bh - SplineDrawFlags

		cx - parameter to pass to lower level
		dx - SplineWhichPointFlags

		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	
	Not quite analogous to OperateOnSelectedPoints... as only CX
can contain data to pass to low-level routines.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 6/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnCurrentPoint	proc	near
	uses	 ax, bx, cx, di
	.enter
EC <	call	ECSplineInstanceAndPoints	>
EC <	call	ECSplinePoint			>

	push	bx
	call	SplineOperateSetup
	pop	bx
	jc	done

	mov	cx, bx			; SplineOperateType,
					; SplineDrawFlags. 

	call	SplineGotoAnchor
	call	SplineOperateOnWhichPoints
done:
	.leave
	ret
SplineOperateOnCurrentPoint	endp

SplineOperateOnCurrentPointFar	proc far
	call	SplineOperateOnCurrentPoint
	ret
SplineOperateOnCurrentPointFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnWhichPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Operate on certain points based on the  "which points"
		flags.

CALLED BY:	SplineOperateOnSelectedPointsCB, 
		SplineOperateOnAllPointsCB,
		SplineOperateOnCurrentPoint

PASS:		ax - anchor point number
		*ds:si - points array
		es:bp - VisSplineInstance data 
		cl - SplineOperateType
		ch - SplineDrawFlags 
		dx - SplineWhichPointFlags

RETURN:		nothing

DESTROYED:	ax, di, bx

PSEUDO CODE/STRATEGY:	
	The procedure starts with a conception of a "CURRENT ANCHOR"
point (stored in the scratch chunk).  With the SplineWhichPointFlags,
we can access any of that point's neighborsThis procedure checks each
flag to see if it is set.  If so, that point is accessed, and the
SplineOperateOnPointCommon procedure is called.

Checks for hit detection are done after the NEXT_FAR_CONTROL,
NEXT_CONTROL, ANCHOR, PREV_CONTROL, and PREV_FAR_CONTROL only.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This procedure is long and ugly.  At least it's commented.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CB	5/91		Initial version
	CB	3/92		Changed to access points in array order

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnWhichPoints	proc	near
	uses	dx

	.enter

EC <	test	dx, not SplineWhichPointFlags		>
EC <	ERROR_NZ ILLEGAL_FLAGS				>

EC <	call	ECSplineAnchorPoint	  		>
EC <	call	ECSplineInstanceAndPoints		> 


	;
	; store the anchor number in the scratch data
	;

	call	SplineSaveAnchorSD

	;
	; Look at each flag in the SplineWhichPointFlags.  If it's
	; set, then call the appropriate procedure, and operate on the
	; resulting point
	;

	clr	bx		; pointer to current proc to call
startLoop:

	;
	; Shift the SplineWhichPointFlags.  If carry is set, then that
	; flag was set, so move to that point.  If
	; SplineOperateOnPointCommon returns carry set, then stop the
	; enumeration. 
	;

	shr	dx
	jnc	next
	call	cs:[operateMoveTable][bx]
	jc	next
	call	SplineOperateOnPointCommon
	jc	done

	;
	; Move on to the next point. If there are none left, then bail.
	;

next:
	tst	dx
	jz	done
	add	bx, size nptr
	call	SplineGetAnchorSD
	jmp	startLoop
done:
	.leave
	ret

SplineOperateOnWhichPoints	endp


; This table is based on the SplineWhichPointFlags
operateMoveTable	label	word
	NearProc ErrorStubSPC
	NearProc SplineGotoPrevAnchor
	NearProc SplineGotoPrevFarControl
	NearProc SplineGotoPrevControl
	NearProc StubCLC			; anchor
	NearProc SplineGotoNextControl
	NearProc SplineGotoNextFarControl
	NearProc SplineGotoNextAnchor
	NearProc ErrorStubSPC
	NearProc ErrorStubSPC
	NearProc SplineGoto2ndPrevAnchor
	NearProc SplineGoto2ndPrevFarControl
	NearProc SplineGoto2ndPrevControl
	NearProc SplineGoto2ndNextControl
	NearProc SplineGoto2ndNextFarControl
	NearProc SplineGoto2ndNextAnchor




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnPointCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the specified operation routine on the current point.

CALLED BY:	SplineOperateOnWhichPoints

PASS:		ax - point number

		*ds:si - points chunk array
		cl - SplineOperateType
		ch - SplineDrawFlags 
		es:bp - VisSplineInstance data

RETURN:		if cl = SOT_CHECK_MOUSE_HIT and paramCX, paramDX

DESTROYED:	di

REGISTER/STACK USAGE:	
	Called routines are allowed to destroy ax,bx,cx,dx,di
	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnPointCommon	proc	near
	uses	bx,cx,dx
	class	VisSplineClass 
	.enter
EC <	call	ECSplineInstanceAndPoints		>
EC <	call	ECSplinePoint				>

	; Pass SplineDrawFlags in BL to lower routines

	mov	bl, ch				; SplineDrawFlags
	clr	ch
	push	cx				; SplineOperateType

	SplineDerefScratchChunk di
	mov	cx, ds:[di].SD_paramCX
	mov	dx, ds:[di].SD_paramDX

	; If the SplineOperateType is one of the SelectCodeOperateTypes, then
	; make the call in the SplineSelectCode segment.

	pop	di			; SplineOperateType 
	cmp	di, SOT_OPERATE_CODE_TYPES
	jae	farCall
	call	cs:[di].SplineOperateCalls

	; deref the scratch data again to see if should stop enum.  

afterCall:
	SplineDerefScratchChunk di
	test	ds:[di].SD_flags, mask SDF_STOP_ENUMERATION
	jnz	stopEnum		; assume that carry is clear!
done:
	.leave
	ret

	; RARER (slower) CASES:
stopEnum:
	stc
	jmp	done

farCall:
	call	SplineOperateInOtherSegment
	jmp	afterCall


SplineOperateOnPointCommon	endp



 COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAddDeltas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the values in CX, DX to the current point


CALLED BY:	SplineOperateOnPointCommon 

PASS:		(cx, dx) - mouse deltas
		*ds:si - points array
		ax - point number

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	This routine is different than most
	of the other Operate routines in that it is an error to
	call it with anything other than an anchor point.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/31/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddDeltas	proc near uses	di
	.enter
EC <	call	ECSplinePoint	>
	call	ChunkArrayElementToPtr
	add	ds:[di].SPS_point.PWBF_x.WBF_int, cx
	add	ds:[di].SPS_point.PWBF_y.WBF_int, dx
	.leave
	ret
SplineAddDeltas	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEraseBeginnerAnchorMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether to erase this anchor's curve

CALLED BY:	SplineOperateOnPointCommon via
			SOT_ERASE_BEGINNER_ANCHOR_MOVE

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - anchor #
		cl - SplineOperateType (SOT_DRAW or SOT_ERASE)

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di 

PSEUDO CODE/STRATEGY:

	check to erase:
		the 2ND PREV anchor (if the prev anchor has a prev
		control) 	
		the NEXT anchor (if it has a NEXT control)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCheckBeginnerAnchorMove	proc near
	.enter

	push	ax			; original anchor
	call	SplineGotoPrevAnchor
	jc	checkNext
	push	ax
	call	SplineGotoPrevControl
	pop	ax
	jc	checkNext
	call	SplineGotoPrevAnchor
	call	doIt

checkNext:
	pop	ax			; original anchor
	call	SplineGotoNextAnchor
	jc	done
	push	ax
	call	SplineGotoNextControl
	pop	ax
	jc	done

	mov	dx,offset done		; cheesy!
	push	dx

doIt:
	mov	bl, mask SDF_IM_CURVE
	clr	dx
	cmp	cl, SOT_DRAW
	je	draw

	call	SplineErasePointCommon
	jmp	done
draw:
	call	SplineDrawPointCommon
	retn
done:	

	.leave
	ret
SplineCheckBeginnerAnchorMove	endp


SplinePtrCode	ends


SplineOperateCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineOperateInOtherSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure is used by SplineOperateOnPointCommon
	to make jumps out of a jump table into procedures in the
	SplineOperateCode segment.

CALLED BY:	SplineOperateOnPointCommon

PASS:		es:bp - VisSplineInstance data
		ax - current point
		cx - param passed to SplineOperate...
		dx - param
		*ds:si - points array
		di - SplineOperateType

RETURN:		depends on SplineOperateType

DESTROYED:	di

PSEUDO CODE/STRATEGY:	
	Called routines are allowed to destroy ax,bx,cx,dx,di

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/17/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateInOtherSegment	proc far
	.enter

EC <	cmp	di, SplineOperateType		>
EC <	ERROR_G	ILLEGAL_CALL_TABLE_VALUE	>
	sub	di, SOT_OPERATE_CODE_TYPES
	call	cs:[di].SplineOperateCodeCalls

	.leave
	ret
SplineOperateInOtherSegment	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineModifyInfoFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify (set and/or reset) info flags for the current
		point
		

CALLED BY:	SplineOperateOnPointCommon

PASS:		*ds:si - points 
		ax - point number
		ch - info flags to SET
		cl - info flags to RESET

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	
	The RESET is done first, before the SET.  This fact is taken
advantage of the SplineSetSmoothness method, which is setting the
SMOOTHNESS etype in the anchor point's record.  (In order to set the
etype, the bits must first be zeroed out).

KNOWN BUGS/SIDE EFFECTS/IDEAS:	
	It is illegal to:
		Set/Reset PIF_CONTROL
	since this is done only once, when a point is created.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/31/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineModifyInfoFlags	proc near uses	di, cx
	.enter

EC <	call	ECSplinePoint			>

	call	ChunkArrayElementToPtr

EC <	ERROR_C	ILLEGAL_SPLINE_POINT_NUMBER	>

EC <	test	cx, ((mask PIF_CONTROL) shl 8) or mask PIF_CONTROL >
EC <	ERROR_NZ ILLEGAL_MODIFY_FLAGS	>

	not	cl
	andnf	ds:[di].SPS_info, cl
	ornf	ds:[di].SPS_info, ch

EC <	call	ECSplinePoint			>

	.leave
	ret
SplineModifyInfoFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineTransformPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the current point by the gstate's
		transformation matrix.

CALLED BY:	SplineSelectCodeOperations

PASS:		cx - gstate handle
		ax - current point
		*ds:si - points array 
		es:bp - VisSplineInstance data 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/26/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineTransformPoint	proc	near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	mov	bp, cx			; gstate handle
	; set DS:DI to the point's data
	call	ChunkArrayElementToPtr

	; load the point into registers, converting to WWFixed
	LoadPointWWFixed

	xchg	di, bp
	call	GrTransformWWFixed
	xchg	di, bp


	StorePointWWFixed	

	.leave
	ret
SplineTransformPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineAddToNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a point number to the NEW POINTS list

CALLED BY:	

PASS:		es:bp - VisSplineInstance data
		ax - current point number

RETURN:		nothing
	
DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	new points array is in INCREASING order

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddToNew	proc	near
	uses	si
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	>

	mov	si, es:[bp].VSI_newPoints
	call	SplineInsertInList
	.leave
	ret
SplineAddToNew	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineSelectPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the point number (ax) in the selected list, 
		Set the "selected" bit in the point's info record.

CALLED BY:	SplineModifySelection

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array
		ax - point number

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectPoint	proc	near

	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints	>
EC <	call	ECSplineAnchorPoint		>

	; set the selected bit
	call	ChunkArrayElementToPtr
	ornf	ds:[di].SPS_info, mask APIF_SELECTED

	push	si
	mov	si, es:[bp].VSI_selectedPoints
	call	ChunkArrayGetCount		; cx - old # selections
	call	SplineInsertInList
	pop	si

	ornf	es:[bp].VSI_editState, mask SES_SELECT_STATE_CHANGED
	.leave
	ret
SplineSelectPoint	endp

SplineSelectPointFar	proc	far
	call	SplineSelectPoint
	ret
SplineSelectPointFar	endp
 



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineStoreLengthOfCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the length of the current curve at the BEGINNING
		of the passed chunk array.

CALLED BY:	SplineOperateOnPointCommon

PASS:		ax - current anchor point
		*ds:si - points array 
		^lcx:dx - chunk array in which to store length

RETURN:		nothing 

DESTROYED:	ax,bx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineStoreLengthOfCurve	proc	near
	uses	si
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	> 

	mov	bx, ax				; anchor #
	call	SplineGetLengthOfCurrentCurve
	tst	ax
	jz	done

	push	ds:[LMBH_handle]	; points block handle
	push	ax			; length
	push	bx			; point number

	mov	bx, cx
	call	MemDerefDS
	mov	si, dx
	clr	ax
	call	ChunkArrayElementToPtr
	call	ChunkArrayInsertAt
	pop	ds:[di].LS_pointNum
	pop	ds:[di].LS_length
	pop	bx
	call	MemDerefDS		; restore points block

done:
EC <	call	ECSplineInstanceAndLMemBlock	> 
	.leave
	ret

SplineStoreLengthOfCurve	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCheckHitSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the mouse hit a segment, and, if so, store the
		point number and set the carry

CALLED BY:

PASS:		

RETURN:		

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCheckHitSegment	proc near
	call	SplinePointOnSegment?
	GOTO	SplineCheckHitCommon
SplineCheckHitSegment	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCheckHitPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the mouse hits a point

CALLED BY:	SplineOperateOnPointCommon

PASS:		
		es:bp - Spline's instance data
		ds:di - fptr to point
		*ds:si - points array
RETURN:		
		ds:[di].SD_flags, SDF_STOP_ENUMERATION if hit

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCheckHitPoint	proc near
	call	SplinePointAtCXDX?
	GOTO	SplineCheckHitCommon
SplineCheckHitPoint	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCheckHitCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the requisite data in the scratchData chunk so
		that higher up routines know what the deal is.

CALLED BY:	SplineCheckHitPoint, SplineCheckHitSegment

PASS:		ax - point number
		es:bp - VisSplineInstance data 
		*ds:si - points array 
		carry set iff point was hit

RETURN:		nothing 

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/21/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCheckHitCommon	proc near
	class	VisSplineClass 
	.enter
	jnc	done
	SplineDerefScratchChunk di
	mov	ds:[di].SD_pointNum, ax
	BitSet	ds:[di].SD_flags, SDF_STOP_ENUMERATION
done:		
	.leave
	ret
SplineCheckHitCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRemoveExtraControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the current control point if it's too close to
		its anchor

CALLED BY:	SplineOperateOnPointCommon

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array 
		ax - current control point
		cx    - tolerance value

RETURN:		nothing 

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 6/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRemoveExtraControls	proc	near
	uses	ax,bx,cx,dx
	.enter
EC <	call	ECSplineControlPoint		>

	call	ChunkArrayElementToPtr

	; control point's coords in cx, dx
	push	ax, cx
	LoadPointAsInt	cx, dx, ds:[di].SPS_point
	call	SplineGotoAnchor

	; anchor point into ax,   bx
	LoadPointAsInt 	ax, bx, ds:[di].SPS_point

	; calc absolute value of x- and y- deltas.
	sub	ax, cx			
	jns	posX
	neg	ax
posX:
	sub	bx, dx
	jns	posY
	neg	bx
posY:

	; compare sum of deltas to tolerance value.

	add	bx, ax
	pop	ax, cx
	cmp	bx, cx
	jge	done
	call	SplineDeletePoint
done:
	.leave
	ret
SplineRemoveExtraControls	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInsertInArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	insert the passed point into the array

CALLED BY:

PASS:		ax - point #
		*ds:si - points array 
		cx - array to insert in
		dx - point number to insert before

RETURN:		nothing 

DESTROYED:	ax,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInsertInArray	proc near
	uses	cx,dx,es,si
	.enter
EC <	call	ECSplineInstanceAndPoints		> 

	xchg	ax, dx			; ax<- dest, dx<- source
	xchg	cx, si			; cx<- source array, si<- dest

	call	ChunkArrayElementToPtr
	jc	append
	call	ChunkArrayInsertAt
	jmp	gotDest
append:
	call	ChunkArrayAppend

gotDest:
	; Now, ds:di is the destination address 
	call	ChunkArrayPtrToElement  ; ax<- new dest

	push	di			; ds:di - dest

	xchg	ax, dx			; ax<- source, dx<-dest
	xchg	cx, si			; cx<- dest array, si<- source
	call	ChunkArrayElementToPtr
	mov	si, di
	pop	di			
	segmov	es, ds			; es:di - dest
	mov	cx, size SplinePointStruct
	rep	movsb
	.leave
	ret
SplineInsertInArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineToggleInfoFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle the info flags of the current point

CALLED BY:	SplineOperateOnPointCommon

PASS:		ax 	- point number
		*ds:si 	- points
		es:bp 	- vis Spline

RETURN:		nothing 

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineToggleInfoFlags	proc near
	call	ChunkArrayElementToPtr
	xornf	ds:[di].SPS_info, cl
	ret
SplineToggleInfoFlags	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetSmoothness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the smoothness for this point

CALLED BY:

PASS:		*ds:si - points
		es:[bp] - VisSpline instance

		SD_paramDX - if zero, then this is the first point
			looked at
		SD_paramCX - smoothness of points already examined, if
			any. 

RETURN:		SD_paramCX, SD_paramDX updated.  If a discrepancy
		occurs, then enumeration is stopped

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetSmoothness	proc near
	class	VisSplineClass
	.enter
	call	ChunkArrayElementToPtr
	mov	al, ds:[di].SPS_info
	andnf	al, mask APIF_SMOOTHNESS
	cbw					; clr ah

	SplineDerefScratchChunk di
	tst	dx
	jz	firstOne

	cmp	ax, cx
	je	done
	mov	ds:[di].SD_paramCX, -1
	mov	ds:[di].SD_flags, mask SDF_STOP_ENUMERATION
done:
	.leave
	ret

firstOne:
	mov	ds:[di].SD_paramCX, ax
	mov	ds:[di].SD_paramDX, TRUE
	jmp	done
SplineGetSmoothness	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetNumControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Combine the current anchor's # controls with those of
		his friends.

CALLED BY:	SplineOperateOnPointCommon

PASS:		ax - anchor #
		es:[bp] - vis Spline
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetNumControls	proc near

	class	VisSplineClass

	.enter

	clr	bl				; # controls
	push	ax
	call	SplineGotoPrevControlFar
	jc	afterPrev
	inc	bl
afterPrev:
	pop	ax

	call	SplineGotoNextControlFar
	jc	afterNext
	inc	bl
afterNext:
	mov_tr	al, bl
	cbw				; ax <- num points

	SplineDerefScratchChunk di
	tst	dx
	jz	firstOne

	cmp	ax, cx
	je	done
	mov	ds:[di].SD_paramCX, -1
	mov	ds:[di].SD_flags, mask SDF_STOP_ENUMERATION
done:
	.leave
	ret

firstOne:
	mov	ds:[di].SD_paramCX, ax
	mov	ds:[di].SD_paramDX, TRUE
	jmp	done

SplineGetNumControls	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAddControlsConform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add control points, minimizing disruption of shape

CALLED BY:	SplineOperateOnPointCommon

PASS:		es:bp - Vis Spline
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx 

PSEUDO CODE/STRATEGY:
	Add prev control at 1/4 distance from anchor to prev anchor
	add next control at 1/4 distance from anchor to next anchor

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	If there is either no next anchor or no prev anchor, then
	the respective control will be placed on top of the anchor.
	Sorry. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddControlsConform	proc near

	mov	bx, bp

anchorNum	local	word	push	ax
curAnchor	local	Point
prevAnchor	local	Point
nextAnchor	local	Point
prevControl	local	Point
nextControl	local	Point

	.enter

	call	ChunkArrayElementToPtr

	LoadPointAsInt	cx, dx, ds:[di].SPS_point
	movdw	curAnchor	cxdx

	xchg	bx, bp
	call	SplineGotoPrevAnchorFar
	xchg	bx, bp
	jc	storePrev
	LoadPointAsInt	cx, dx, ds:[di].SPS_point
storePrev:
	movdw	prevAnchor,	cxdx

	mov	ax, anchorNum
	xchg	bx, bp
	call	SplineGotoNextAnchorFar
	xchg	bx, bp
	jc	storeNext
	LoadPointAsInt	cx, dx, ds:[di].SPS_point

storeNext:
	movdw	nextAnchor, cxdx

	; Calculate where next, prev controls should go -- each one
	; goes 1/4 distance from current anchor to next/prev

	movdw	cxdx, curAnchor
	shl	cx
	shl	dx
	adddw	cxdx, curAnchor		; 3 * curAnchor
	push	cx, dx

	adddw	cxdx, nextAnchor
	shr	cx
	shr	cx
	shr	dx
	shr	dx

	movdw	nextControl, cxdx

	pop	cx, dx			; 3 * curAnchor
	adddw	cxdx, prevAnchor
	shr	cx
	shr	cx
	shr	dx
	shr	dx

	movdw	prevControl, cxdx

	;
	; Insert the PREV control point
	;

	mov	ax, anchorNum

	xchg	bx, bp
	call	SplineAddPrevControl
	xchg	bx, bp
	mov	ss:[anchorNum], ax

	;
	; If the procedure didn't return SRT_OK, then either the point
	; already existed, or there are too many points.  In either
	; case, don't modify the new point's coordinates
	;

	cmp	cl, SRT_OK
	jne	addNext

	xchg	bx, bp
	call	SplineGotoPrevControlFar
	xchg	bx, bp

	movdw	cxdx, prevControl
	StorePointAsInt	ds:[di].SPS_point, cx, dx

addNext:

	;
	; Now, add the NEXT control
	;
	mov	ax, anchorNum

	xchg	bx, bp
	call	SplineAddNextControl
	xchg	bx, bp

	cmp	cl, SRT_OK
	jne	done

	xchg	bx, bp
	call	SplineGotoNextControlFar
	xchg	bx, bp

	movdw	cxdx, nextControl
	StorePointAsInt	ds:[di].SPS_point, cx, dx

done:

	.leave
	ret
SplineAddControlsConform	endp





SplineOperateCode	ends

