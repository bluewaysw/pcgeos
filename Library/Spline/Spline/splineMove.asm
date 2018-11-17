COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		spline
FILE:		splineMove.asm

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
	CDB	10/ 8/91	Initial version.

DESCRIPTION:
	Handle external point-movement functions
	

	$Id: splineMove.asm,v 1.1 97/04/07 11:09:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSelectCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBeginMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Begin a MOVE of the currently selected point(s)

PASS:		*DS:SI	= VisSplineClass object
		DS:DI	= VisSplineClass instance data
		ES	= Segment of VisSplineClass.
		AX	= Method.

RETURN:		

DESTROYED:	Nada.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Draw various points in invert-mode depending on the ActionType

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 8/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineBeginMove	method	dynamic	VisSplineClass, MSG_SPLINE_BEGIN_MOVE
	uses	ax,cx,dx,bp
	.enter
	call	SplineCreateGState
	call	SplineMethodCommon

	; Make scratch chunk persist until SplineEndMove so that
	; control-anchor distance is kept constant throughout (for semi-smooth
	; control-move operations)

	SplineDerefScratchChunk	di
	inc	ds:[di].SD_refCount

	call	SplineBeginMoveCommon
	call	SplineEndmCommon
	call	SplineDestroyGState
	.leave
	ret
SplineBeginMove	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBeginMoveCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a "select" action to a "move" action

CALLED BY:	SplineDragSelect, SplineBeginMove

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/25/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineBeginMoveCommon	proc near 
	class	VisSplineClass
	.enter

	; Get action type into BX (assume bh is zero) 
	GetActionType	bx	
	ECMakeSureZero	bh
				
	cmp	bl, AT_NONE
	je	done

EC <	cmp	bl, AT_SELECT_NOTHING		>
EC <	ERROR_G ILLEGAL_ACTION_TYPE		>

	; Tell UNDO about pending move
	mov	ax, UT_MOVE
	call	SplineInitUndo

	push	bx
	sub	bl, AT_SELECT_ANCHOR
	CallTable	bx, SplineBeginMoveCalls
	pop	bx
	add	bl, (AT_MOVE_ANCHOR - AT_SELECT_ANCHOR)
	SetActionType	bl
done:
	.leave
	ret
SplineBeginMoveCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBeginMoveSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin a segment-move operation

CALLED BY:

PASS:		*ds:si - points array 
		es:bp - VisSplineInstance data 

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/20/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineBeginMoveSegment	proc	near
	uses	ax,bx
	.enter
	;
	; Add a next-control and a next-far control to the selected anchors

	mov	ax, SOT_ADD_NEXT_CONTROL		; 
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	mov	al, SOT_ADD_PREV_CONTROL
	mov	bx, mask SWPF_NEXT_ANCHOR
	call	SplineOperateOnSelectedPointsFar

	; copy controls to UNDO
	mov	al, SOT_COPY_TO_UNDO
	mov	bx, mask SWPF_NEXT_CONTROL or \
			mask SWPF_NEXT_FAR_CONTROL
	call	SplineOperateOnSelectedPointsFar

	; erase filled handles for controls

	call	SplineSetInvertModeFar
	movHL	ax, <mask SDF_FILLED_HANDLES>, <SOT_ERASE>
	call	SplineOperateOnSelectedPointsFar

	; Set the "TEMP" flags for controls

	mov	al, SOT_MODIFY_INFO_FLAGS 
	movH	cx, <mask PIF_TEMP>
	call	SplineOperateOnSelectedPointsFar

	; Change smoothness to NONE

	mov	al, SOT_MODIFY_INFO_FLAGS
	mov	bx, mask SWPF_ANCHOR_POINT or mask SWPF_NEXT_ANCHOR
	movHL	cx, <ST_NONE>, <mask APIF_SMOOTHNESS>
	call	SplineOperateOnSelectedPointsFar


	; draw invert-mode curves

	movHL	ax, <mask SDF_IM_CURVE>, <SOT_DRAW>
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	.leave
	ret
SplineBeginMoveSegment	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBeginMoveAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin a MOVE_ANCHOR operation

CALLED BY:	SplineDSAdvancedEdit

PASS:		*es:bp - VisSpline object
		*ds:si - points array

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineBeginMoveAnchor	proc near 	uses	ax,bx,cx
	.enter

	; copy anchor and controls to UNDO
	mov	al, SOT_COPY_TO_UNDO
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnSelectedPointsFar

	; draw curves in invert mode

	call	SplineSetInvertModeFar
	movHL	ax, <mask SDF_IM_CURVE>, <SOT_DRAW>
	mov	bx, SWP_BOTH_CURVES
	call	SplineOperateOnSelectedPointsFar

	; erase filled handles
	
	movHL	ax, <mask SDF_FILLED_HANDLES>, <SOT_ERASE>
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnSelectedPointsFar

	; Set TEMP flags

	mov	al, SOT_MODIFY_INFO_FLAGS 
	movH	cx, <mask PIF_TEMP>
	call	SplineOperateOnSelectedPointsFar


	.leave
	ret
SplineBeginMoveAnchor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBeginMoveControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin a MOVE-CONTROLS operation

CALLED BY:	SplineDSAdvancedEdit

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineBeginMoveControl	proc near 	uses	ax,bx,cx,di
	class	VisSplineClass 
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	> 

	; First: If the control points are involved in a SEMI_SMOOTH
	; relationship (yes, it sounds kinky), then store the distance
	; from the OTHER control to its anchor in the scratch chunk

	mov	ax, es:[bp].VSI_actionPoint
EC <	call	ECSplineControlPoint		> ; make sure action pt is
						; a control point

	; copy control points to UNDO

	mov	bl, SOT_COPY_TO_UNDO
	mov	dx, mask SWPF_NEXT_CONTROL or \
			mask SWPF_PREV_CONTROL
	call	SplineOperateOnCurrentPointFar 


	; If semi-smooth or auto-smooth, store the distance from the anchor to
	; the OTHER control point, as it must remain constant over all PTR
	; events.

	push	ax				; control point
	call	SplineDetermineSmoothness
	cmp	bl, ST_SEMI_SMOOTH
	je	storeDistance
	cmp	bl, ST_AUTO_SMOOTH
	jne	afterStoreDistance

storeDistance:
	call	SplineGotoOtherControlPoint
	jc	afterStoreDistance
	call	SplineStoreControlAnchorDistance

afterStoreDistance:
	; draw curves in invert mode.
	pop	ax				; control point number
	call	SplineSetInvertModeFar

	movHL	bx, <mask SDF_IM_CURVE>, <SOT_DRAW>
	call	SplineSetFlagsForControlMove	; sets dx (SWPF)
	call	SplineOperateOnCurrentPointFar 

	; Erase filled handles

	movHL	bx, <mask SDF_FILLED_HANDLES>, <SOT_ERASE>
	call	SplineOperateOnCurrentPointFar 

	; Set temp flags (for controls only)

	mov	bl, SOT_MODIFY_INFO_FLAGS 
	andnf	dx, not (mask SWPF_ANCHOR_POINT  or mask SWPF_PREV_ANCHOR)

	movH	cx, <mask PIF_TEMP>
	call	SplineOperateOnCurrentPointFar 

	.leave
	ret
SplineBeginMoveControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineStoreControlAnchorDistance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the distance from the current control point to
		its anchor point in the "scratch" block.  Assume
		the scratch block already exists.

CALLED BY:	SplineBeginMoveControl

PASS:		ax - control point number
		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	If scratch chunk not allocated, then allocate it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineStoreControlAnchorDistance	proc near uses	ax,cx,dx,di
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndLMemBlock		>

	;
	; Make sure we're at a control point and get its coordinates

EC <	call	ECSplineControlPoint	>	; make sure at ctrl point
	call	ChunkArrayElementToPtr	
	LoadPointAsInt	cx, dx, ds:[di].SPS_point
						; load control point's coords
						; into CX, DX
	call	SplineGotoAnchor		; go to anchor point
	push	ax, bx
	LoadPointAsInt	ax, bx, ds:[di].SPS_point 
	sub	cx, ax
	sub	dx, bx
	pop	ax, bx

	call	SplineCalcDistance		; calculate distance

	

	SplineDerefScratchChunk di

	mov	ds:[di].SD_distance.WWF_int, dx		; save distance
	mov	ds:[di].SD_distance.WWF_frac, cx 	; in scratch chunk
	.leave
	ret
SplineStoreControlAnchorDistance	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	End a move operation

PASS:		*DS:SI	= VisSplineClass object
		DS:DI	= VisSplineClass instance data
		ES	= Segment of VisSplineClass.
		AX	= Method.

RETURN:		nothing 

DESTROYED:	Nada.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 8/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineEndMove	method	dynamic	VisSplineClass, MSG_SPLINE_END_MOVE
	uses	ax,cx,dx,bp

	.enter
	call	SplineCreateGState 
	call	SplineMethodCommon 

	GetActionType al
	cmp	al, AT_MOVE_ANCHOR
	js	done

	; decrement the scratch chunk's ref count
	SplineDerefScratchChunk	di
	dec	ds:[di].SD_refCount

	call	SplineEndMoveCommon

done:
	call	SplineEndmCommon 
	call	SplineDestroyGState 

	.leave
	ret
SplineEndMove	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndMoveCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a move operation. Set the Action Type to a
		"Select" back from a "move"

CALLED BY:	SplineEndMove, SplineEndSelect

PASS:		es:bp - VisSplineInstance data 

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndMoveCommon	proc near
	class	VisSplineClass 
	.enter

	GetActionType bx
EC <	cmp	bl, AT_MOVE_RECTANGLE	>
EC <	ERROR_G	ILLEGAL_ACTION_TYPE	>

	push	bx
	sub	bl, AT_MOVE_ANCHOR
	js	popAndDone

	CallTable	bx, SplineEndMoveCalls
	pop	bx
	sub	bl,  (AT_MOVE_ANCHOR - AT_SELECT_ANCHOR)
	SetActionType	bl

	call	SplineRecalcVisBounds
done:
	.leave
	ret

popAndDone:
	pop	bx
	jmp	done


SplineEndMoveCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndMoveSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a "move-segment" operation. 

CALLED BY:	SplineEndMoveCommon

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	


KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndMoveSegment	proc near
	mov	bx, mask SWPF_ANCHOR_POINT or \
			mask SWPF_NEXT_CONTROL or \
			mask SWPF_NEXT_FAR_CONTROL or \
			mask SWPF_NEXT_ANCHOR
	GOTO	SplineEndMoveSegmentOrAnchor
SplineEndMoveSegment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndMoveAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a "MOVE ANCHOR" operation

CALLED BY:	SplineEndMoveCommon

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndMoveAnchor	proc near 

EC <	call	ECSplineInstanceAndPoints		>  
	mov	bx, MASK SWPF_ANCHOR_POINT or \
			SWP_ALL_CONTROLS or \
			mask SWPF_PREV_ANCHOR or \
			mask SWPF_NEXT_ANCHOR
	FALL_THRU	SplineEndMoveSegmentOrAnchor
SplineEndMoveAnchor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndMoveSegmentOrAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End the move of either segments or anchors

CALLED BY:	SplineEndMoveAnchor, SplineEndMoveSegment

PASS:		bl - SplineWhichPointFlags -- these are the points
		that need to be added to the region to be invalidated

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	
	Inval the undo and new curves, set drawn flags so MSG_VIS_DRAW
	will draw everything correctly.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndMoveSegmentOrAnchor	proc near

	class	VisSplineClass

	.enter

	; Get a bounding box that includes both the UNDO curves and
	; the NEW curves

	call	SplineGetBoundingBoxIncrementFar	; cx <- increment

	SplineDerefScratchChunk di
	andnf	ds:[di].SD_flags, not mask SDF_BOUNDING_BOX_INITIALIZED

	; Add the "UNDO" curves to bounding box

	movHL	ax, <mask SDF_USE_UNDO_INSTEAD_OF_TEMP>,	\
				<SOT_ADD_TO_BOUNDING_BOX>
	call	SplineOperateOnSelectedPointsFar

	; add the new curves to the bounding box

	clr	ah
	call	SplineOperateOnSelectedPointsFar

	; Inval the bounding box

	SplineDerefScratchChunk di
	mov	ax, ds:[di].SD_boundingBox.R_left
	mov	bx, ds:[di].SD_boundingBox.R_top
	mov	cx, ds:[di].SD_boundingBox.R_right
	mov	dx, ds:[di].SD_boundingBox.R_bottom
	mov	di, es:[bp].VSI_gstate
	call	GrInvalRect
	
	; Draw normal selected stuff
	call	SplineSetDrawnFlagsForSelectedPoints

	.leave

	ret
SplineEndMoveSegmentOrAnchor	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndMoveControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a "control move" operation

CALLED BY:	SplineEndSelect, SplineEndMove

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndMoveControl	proc near 
	class	VisSplineClass
	mov	ax, es:[bp].VSI_actionPoint

	; Inval the "undo" curves

	movHL	bx, <mask SDF_USE_UNDO_INSTEAD_OF_TEMP>, SOT_INVALIDATE
	mov	dx, SWP_BOTH_CURVES
	call	SplineOperateOnCurrentPointFar 

	; inval the new curves

	movL	bx, SOT_INVALIDATE
	mov	dx, SWP_BOTH_CURVES
	call	SplineOperateOnCurrentPointFar 

	; set filled handle flags, reset temp flags for anchor and controls, 

	mov	bl, SOT_MODIFY_INFO_FLAGS 
	mov	dx, SWP_ANCHOR_AND_CONTROLS
	movHL	cx, <mask PIF_FILLED_HANDLE>, <mask PIF_TEMP>
	call	SplineOperateOnCurrentPointFar 

	; Reset IM_CURVE flags for anchor and prev anchor

	movL	cx, <mask APIF_IM_CURVE>
	mov	dx, SWP_BOTH_CURVES
	call	SplineOperateOnCurrentPointFar 

	; See if control points are close enough to their anchor to be deleted.

	mov	bl, SOT_REMOVE_EXTRA_CONTROLS
	mov	dx, mask SWPF_NEXT_CONTROL or \
			mask SWPF_PREV_CONTROL
	mov	cx, SPLINE_POINT_TOLERANCE
	call	SplineOperateOnCurrentPointFar
	.leave
	ret
SplineEndMoveControl	endp


SplineSelectCode	ends
