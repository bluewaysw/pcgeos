COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineSplitJoin.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/30/92   	Initial version.

DESCRIPTION:
	

	$Id: splineSplitJoin.asm,v 1.1 97/04/07 11:09:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineUtilCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSplit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Split this spline

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

		^hcx  	= block in which to place new spline
		^hdx 	= block in which to place spline points

		
RETURN:		dx - chunk handle of new spline
		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSplit	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SPLIT
	uses	ax,bp
	.enter

	test	ds:[di].VSI_state, mask SS_CLOSED
	jnz	openCurve	

	call	SplineCreateGState
	call	SplineMethodCommon

	call	SplineGetFirstSelectedPoint
	jc	noneSelected		; no points selected!

	mov	bx, ax			; first selected point

	call	SplineUnselectAll	; make nothing selected

	mov	ax, MSG_SPLINE_COPY
	call	SplineSendMyselfAMessage
	push	cx, dx			; OD of new spline

	mov	ax, MSG_SPLINE_DELETE_RANGE
	mov	cx, -1			; start before ALL points
	mov	dx, bx
	dec	dx
	call	SplineSendMyselfAMessage

	mov	cx, bx			; first selected point
	inc	cx
	pop	bx, si			; OD of new spline
	mov	dx, SPLINE_MAX_POINT+1
	mov	ax, MSG_SPLINE_DELETE_RANGE
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage
	mov	cx, bx
	mov	dx, si			; return new OD to caller

endMethod:
	call	SplineDestroyGState
	call	SplineEndmCommon
done:
	.leave
	ret

noneSelected:
	clr	cx, dx
	jmp	endMethod

openCurve:
	mov	ax, MSG_SPLINE_OPEN_CURVE
	call	ObjCallInstanceNoLock 
	clr	cx, dx			; no new object created
	jmp	done

SplineSplit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetFirstSelectedPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the point number of the first selected point

CALLED BY:

PASS:		CARRY set if error (no points selected)

RETURN:		ax - first selected point (if no carry, otherwise ax -
		unchanged) 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/31/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetFirstSelectedPoint	proc near
	uses	si,cx
	.enter
	class	VisSplineClass 

EC <	call	ECSplineInstanceAndLMemBlock	> 

	; Get the LAST element in the selected array (=the FIRST
	; selected point)

	mov	si, es:[bp].VSI_selectedPoints
	call	ChunkArrayGetCount
	jcxz	noneSelected
	dec	cx
	call	ChunkArrayElementToPtr 
	mov	ax, ds:[di]
	clc
done:
	.leave
	ret

noneSelected:
	stc
	jmp	done

SplineGetFirstSelectedPoint	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCloseCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Close the spline curve

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.

RETURN:		nothing

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	Set the "CLOSED" and "FILLED" bits in the
			instance data.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/18/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineCloseCurve	method	dynamic	VisSplineClass, 
						MSG_SPLINE_CLOSE_CURVE
	uses	ax,cx,dx,bp
	.enter

	; set bits in instance data

	ornf	ds:[di].VSI_state, mask SS_CLOSED or mask SS_FILLED

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	;    We may only need to update the open close ui but I'm
	;    not really sure so I am doing everything. steve 11/11/92
	;

	mov	cx,UPDATE_ALL
	mov	ax, MSG_SPLINE_BEGIN_UPDATE_UI
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisSpline_offset
	call	SplineMethodCommon

	mov	ax, UT_CLOSE_CURVE
	call	SplineInitUndo

	;
	; If the first anchor is AUTO-SMOOTH, then update the controls
	; accordingly. 
	;
	call	SplineGotoFirstAnchor	; ds:di - first anchor
	jc	afterUpdate

	mov	bl, ds:[di].SPS_info
	andnf	bl, mask APIF_SMOOTHNESS
	cmp	bl, ST_AUTO_SMOOTH
	jne	doLast
	call	SplineUpdateAutoSmoothControlsFar

	;
	; Do the same for the last anchor
	;

doLast:
	call	SplineGotoLastAnchor	; ds:di - first anchor
	mov	bl, ds:[di].SPS_info
	andnf	bl, mask APIF_SMOOTHNESS
	cmp	bl, ST_AUTO_SMOOTH
	jne	afterUpdate
	call	SplineUpdateAutoSmoothControlsFar

	;
	; Since control points may have been moved, we should
	; recalculate our size.
	;

	mov	ax, MSG_VIS_RECALC_SIZE
	call	SplineSendMyselfAMessage

	;
	; And, since we've recalc'ed our size, we need to invalidate
	; again. 
	;
	mov	ax, MSG_VIS_INVALIDATE
	call	SplineSendMyselfAMessage


afterUpdate:

	call	SplineEndmCommon 
	
	.leave
	ret
SplineCloseCurve	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetClosedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return whether spline is closed

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of VisSplineClass

RETURN:		
		cl - TRUE/FALSE
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetClosedState	method dynamic VisSplineClass, 
						MSG_SPLINE_GET_CLOSED_STATE
	.enter

	mov	cl,ds:[di].VSI_state
	andnf	cl,mask SS_CLOSED

	.leave
	ret
SplineGetClosedState		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineOpenCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Open the curve.  If it's filled, make it unfilled.

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/18/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineOpenCurve	method	dynamic	VisSplineClass, MSG_SPLINE_OPEN_CURVE
	uses	ax,cx,dx,bp
	.enter

	test	ds:[di].VSI_state, mask SS_CLOSED
	jz	done			; who you trying to fool?

	; reset the closed and filled bits in the instance data
	andnf	ds:[di].VSI_state, not (mask SS_CLOSED or mask SS_FILLED)

	call	SplineMethodCommon 

	mov	ax, UT_OPEN_CURVE
	call	SplineInitUndo

	; Invalidate the spline

	call	SplineInvalidate

	; Move the first selected point to the front of the list

	call	SplineGetFirstSelectedPoint
	jc	afterFirstSelected

	; re-set SI, 'cause we'll have a new chunk array after this
	; call. 

	mov_tr	cx, ax
	mov	ax, MSG_SPLINE_SET_FIRST_POINT
	call	SplineSendMyselfAMessage
	mov	si, es:[bp].VSI_points

afterFirstSelected:

if 0
	; This duplication is confusing -- removed 10/12/92

	; duplicate the first anchor and its prev control at the end
	; of the array

	call	SplineGotoFirstAnchor

	SplineDerefScratchChunk di
	mov	ds:[di].SD_firstPoint, ax
	mov	ds:[di].SD_lastPoint, ax

	mov	cx, si
	mov	dx, SPLINE_MAX_POINT+1
	mov	al, SOT_INSERT_IN_ARRAY
	mov	bx, mask SWPF_ANCHOR_POINT or mask SWPF_PREV_CONTROL
	call	SplineOperateOnRange
endif

	;    We may only need to update the open close ui but I'm
	;    not really sure so I am doing everything. steve 11/11/92
	;

	mov	cx,UPDATE_ALL
	call	SplineUpdateUI

	call	SplineEndmCommon 
done:
	.leave
	ret
SplineOpenCurve	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetFirstPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Make the passed point the first point in the array

PASS:		*ds:si	= SplineSetFirstPointClass object
		ds:di	= SplineSetFirstPointClass instance data
		es	= Segment of SplineSetFirstPointClass.
		cx	= point number to make FIRST

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetFirstPoint	method	dynamic	VisSplineClass,
					MSG_SPLINE_SET_FIRST_POINT

	.enter

	call	SplineCreateGState
	call	SplineMethodCommon

	call	SplineUnselectAll	; make nothing selected

	push	cx			; save this point
	SplineDerefScratchChunk di
	mov	ds:[di].SD_firstPoint, cx
	mov	ds:[di].SD_lastPoint, SPLINE_MAX_POINT+1

	; create a new array

	push	si
	mov	bx, size SplinePointStruct
	clr	cx, si
	clr	al
	call	ChunkArrayCreate
	mov	cx, si			; chunk handle of new array
	mov	dx, SPLINE_MAX_POINT+1	; add points to end of array
	pop	si

	; copy points from current point to end into array

	mov	al, SOT_INSERT_IN_ARRAY
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnRange

	; copy all points from 0 to the passed point-1

	pop	ax			; original point
	dec	ax
	SplineDerefScratchChunk di
	mov	ds:[di].SD_firstPoint, 0
	mov	ds:[di].SD_lastPoint, ax
	mov	al, SOT_INSERT_IN_ARRAY
	call	SplineOperateOnRange

	; nuke the old points array, and store the new one.

	mov	ax, si
	call	LMemFree
	
	mov	es:[bp].VSI_points, cx

	call	SplineDestroyGState
	call	SplineEndmCommon 

	.leave
	ret
SplineSetFirstPoint	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineReversePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineReversePoints	method	dynamic	VisSplineClass, 
					MSG_SPLINE_REVERSE_POINTS
	uses	ax,cx,dx,bp
	.enter

	call	SplineCreateGState
	call	SplineMethodCommon

	call	SplineUnselectAll	; make nothing selected

	; create a new array

	push	si
	mov	bx, size SplinePointStruct
	clr	cx, si
	clr	al
	call	ChunkArrayCreate
	mov	cx, si			; chunk handle of new array
	clr	dx			; add points to beginning of array
	pop	si

	; copy all points

	mov	al, SOT_INSERT_IN_ARRAY
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnAllPoints

	; nuke the old points array, and store the new one.

	mov	ax, si
	call	LMemFree
	
	mov	es:[bp].VSI_points, cx

	mov	ax, SOT_TOGGLE_INFO_FLAGS
	mov	bx, mask SWPF_PREV_CONTROL or mask SWPF_NEXT_CONTROL
	mov	cl, mask CPIF_PREV
	call	SplineOperateOnAllPoints

	call	SplineDestroyGState
	call	SplineEndmCommon 

	.leave
	ret
SplineReversePoints	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineJoin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Join this spline to another

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

		ss:bp 	= SplineJoinParams

RETURN:		SplineErrorType

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

	Join will not take effect if combined number of points is
	beyond maximum

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineJoin	method	dynamic	VisSplineClass, 
					MSG_SPLINE_JOIN
	uses	cx,dx,bp
	.enter
	mov	bx, bp		; SplineJoinParams

	call	SplineCreateGState
	call	SplineMethodCommon
	call	SplineUnselectAll

;	mov	ax, UT_JOIN
;	call	SplineInitUndo

	mov	ax, MSG_SPLINE_GET_NUMBER_OF_POINTS
	call	JoinCallOtherSpline
	call	SplineCheckToAddPoints
	jc	error

	mov	ax, MSG_SPLINE_GET_POINTS
	call	JoinCallOtherSpline	; cx:dx - other spline's points

	push	es:[bp].VSI_points	; save my current points

	; Allocate a new points chunk in DS, and copy the passed
	; points into it.

	push	cx
	clr	al
	clr	cx
	call	LMemAlloc
	pop	cx

	mov	si, ax
	mov	es:[bp].VSI_points, ax		; new chunk
	mov	ax, MSG_SPLINE_REPLACE_POINTS
	call	SplineSendMyselfAMessage

	; Add the deltas

	mov	cx, ss:[bx].SJP_deltaX
	mov	dx, ss:[bx].SJP_deltaY
	push	bx				; stack frame

	mov	al, SOT_ADD_DELTAS
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnAllPoints

	; Append the points to the end of the original array

	pop	cx				; original array
	mov	dx, SPLINE_MAX_POINT+1
	mov	al, SOT_INSERT_IN_ARRAY
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnAllPoints

	; Free the source array

	mov_tr	ax, si
	call	LMemFree

	; set the new array in the instance data

	mov	es:[bp].VSI_points, cx

	; Nuke the other spline

	mov	ax, MSG_VIS_DESTROY
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	JoinCallOtherSpline

	; recalc size, etc.

	mov	ax, MSG_VIS_RECALC_SIZE
	call	SplineSendMyselfAMessage
	mov	al, SRT_OK
done:
	call	SplineDestroyGState
	call	SplineEndmCommon
	.leave
	ret
error:
	mov	al, SRT_TOO_MANY_POINTS
	jmp	done

SplineJoin	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JoinCallOtherSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call the "other" spline referred to in the
		SplineJoinParams. 

CALLED BY:	SplineJoin

PASS:		ss:bx - SplineJoinParams

RETURN:		ax,cx,dx,bp - returned from method called

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JoinCallOtherSpline	proc near
	uses	bx,si,di
	.enter
	mov	si, ss:[bx].SJP_otherSpline.chunk
	mov	bx, ss:[bx].SJP_otherSpline.handle
	mov	di, mask MF_CALL or mask MF_FIXUP_ES or mask MF_FIXUP_DS 
	call	ObjMessage
	.leave
	ret
JoinCallOtherSpline	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	return the OD of the spline's points

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		^lcx:dx - Chunk array of SplinePointStruct structures

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
	Optimized for SIZE over SPEED

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetPoints	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_POINTS
	.enter
	mov	cx, ds:[di].VSI_lmemBlock
	mov	dx, ds:[di].VSI_points
	.leave
	ret
SplineGetPoints	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineReplacePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Replace the spline's points with the passed set of points

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		^lcx:dx	- chunk array of SplinePointStruct structures
			  block MUST be in same VM file as spline

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineReplacePoints	method	dynamic	VisSplineClass, 
					MSG_SPLINE_REPLACE_POINTS
	uses	ax,cx,dx,bp
	.enter

	call	SplineMethodCommon
	push	es, bp			; spline instance

	;
	; Lock the passed points block, and get the size of the points
	; chunk. 
	;

	mov	bx, cx
	call	ObjLockObjBlock	
	
	mov	es, ax
	mov	di, dx
	mov	di, es:[di]
	ChunkSizePtr	es, di, cx
	
	;
	; Reallocate our existing points chunk so it's big enough.
	;

	mov	ax, si			; spline's points array
	call	LMemReAlloc
	mov	si, ds:[si]

	;
	; Copy the points in.
	;

	segxchg	ds, es
	xchg	di, si
	shr	cx, 1
	rep	movsw
	jnc	done
	movsb	
done:	
	segxchg	ds, es			; ds - spline's points block

	;
	; Unlock the source block. SplineEndmCommon will unlock the
	; destination block.
	;

	call	MemUnlock		; unlock block BP
	pop	es, bp			; restore spline instance

	call	SplineEndmCommon

	.leave
	ret
SplineReplacePoints	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCheckToAddPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the spline can deal with adding the passed
		number of points

CALLED BY:

PASS:		es:bp - VisSpline object
		cx - number of points to add

RETURN:		carry clear if OK, carry set otherwise.

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCheckToAddPoints	proc far
	class	VisSplineClass
	uses	ax,cx,si
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	> 

	mov	ax, cx
	mov	si, es:[bp].VSI_points
	call	ChunkArrayGetCount
	add	cx, ax
	cmp	cx, SPLINE_MAX_POINT
	jg	tooMany
	clc
done:
	.leave
	ret

tooMany:
	stc
	jmp	done

SplineCheckToAddPoints	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetNumberOfPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetNumberOfPoints	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_NUMBER_OF_POINTS
	uses	ax,dx,bp
	.enter
	call	SplineMethodCommon
	call	ChunkArrayGetCount
	call	SplineEndmCommon
	.leave
	ret
SplineGetNumberOfPoints	endm


SplineUtilCode	ends
