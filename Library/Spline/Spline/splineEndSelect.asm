COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineEndSelect.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

DESCRIPTION:
	Routines for dealing with MSG_META_END_SELECT

	$Id: splineEndSelect.asm,v 1.1 97/04/07 11:09:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineSelectCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineEndSelect, MSG_META_END_SELECT

DESCRIPTION:	

PASS:		*ds:si - VisSpline object
		ds:bx  -  "" ""
		ds:di  - VisSPline instance data
		cx - mouse x position
		dx - mouse y position
		bp - mouse flags

RETURN:		ax = MRF_PROCESSED

DESTROYED:	nothing

REGISTER/STACK USAGE:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndSelect	method	dynamic VisSplineClass, MSG_META_END_SELECT
	uses	cx, dx, bp
	.enter

	call	SplineMouseMethodCommon
	CallTable bx, SplineEndSelectCalls, SplineMode

	call	SplineRecalcVisBounds

	call	CheckChangeInSelectionState

	call	SplineEndmCommon 
	mov	ax, mask MRF_PROCESSED
	.leave
	ret
SplineEndSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckChangeInSelectionState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the "select state changed" bit is set, and if
		send out notifications for the UI

CALLED BY:	SplineEndSelect

PASS:		es:bp - vis spline
		ds - data block segment

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckChangeInSelectionState	proc near

	uses	si

	class	VisSplineClass

	.enter
EC <	call	ECSplineInstanceAndLMemBlock	>

	test	es:[bp].VSI_editState, mask SES_SELECT_STATE_CHANGED
	jz	done

	andnf	es:[bp].VSI_editState, not mask SES_SELECT_STATE_CHANGED

	mov	cx, UPDATE_ALL
	call	SplineUpdateUI

done:
	.leave
	ret
CheckChangeInSelectionState	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineESEditModes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle END SELECT in edit modes

CALLED BY:	SplineEndSelect

PASS:		es:bp - VisSpline
		*ds:si -points

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineESEditModes	proc near
	class	VisSplineClass
	uses	di, si
	.enter
	call	SplineEndMoveCommon

	SplineDerefScratchChunk	di
	mov	si, ds:[di].SD_splineChunkHandle
	push	ds:[LMBH_handle]
	segxchg	ds, es
	call	VisReleaseMouse
	segmov	es, ds
	call	MemDerefStackDS
	
	.leave
	ret
SplineESEditModes	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineESAdvancedCreateMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process END-SELECT in the create modes

CALLED BY:	SplineEndSelect

PASS:		es:bp - VisSplineInstance data 
		cx, dx - mouse position

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 7/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineESAdvancedCreateMode	proc near
	class	VisSplineClass 
	.enter

	;
	; If we're in AT_CREATE_MODE_MOUSE_UP, then this is a spurious
	; end-select, so ignore it. 
	;

	GetActionType	al
	cmp	al, AT_CREATE_MODE_MOUSE_UP
	je	done

	;
	; store mouse position 
	;

	SplineDerefScratchChunk di
	movP	ds:[di].SD_mouse, cxdx

	;
	; if move-control, then erase control lines, reset temp flags, etc.
	;

	cmp	al, AT_MOVE_CONTROL
	jne	afterCall
	call	SplineESAdvancedCreateMoveControls

afterCall:

	call	SplineCompleteAnchorPlacement
done:
	.leave
	ret
SplineESAdvancedCreateMode	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCompleteAnchorPlacement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish visual update after anchor placement.  For
		SPLINE CREATE mode, this occurs on END SELECT.  For
		POLYLINE MODE, this occurs on START SELECT.

CALLED BY:	SplineESAdvancedCreateMode, 
		SplineSSPolylineCreateMode

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCompleteAnchorPlacement	proc near
	class	VisSplineClass
	.enter

	mov	ax, es:[bp].VSI_actionPoint


	;
	; Draw "normal mode" curve for the previous anchor
	;
	call	SplineSetNormalAttributes 

	movHL	bx, <mask SDF_CURVE>, <SOT_DRAW> 
	mov	dx, SWP_BOTH_CURVES
	call	SplineOperateOnCurrentPointFar 

	call	SplineCompleteAnchorPlacementCommon

	.leave
	ret
SplineCompleteAnchorPlacement	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCompleteAnchorPlacementCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine for completing anchor placement

CALLED BY:	SplineCompleteAnchorPlacement, 
		SplineCompleteAnchorPlacementBeginnerSplineEdit

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCompleteAnchorPlacementCommon	proc near
	class	VisSplineClass 
	.enter

	; draw mouse-up sprite if we're still in create mode (we might
	; have gone into inactive mode)

	call	SplineAreWeInCreateMode?
	jnc	done

	SetActionType AT_CREATE_MODE_MOUSE_UP	
	call	SplineDrawFromLastAnchorToMouse

done:
	.leave
	ret
SplineCompleteAnchorPlacementCommon	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCompleteAnchorPlacementBeginnerSplineCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish anchor placement visual display in
		SM_BEGINNER_SPLINE_CREATE mode

CALLED BY:	SplineSSBeginnerSplineEdit

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - action point

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

	In this procedure, we've just placed an anchor point, so erase
	the IM_CURVE for the 2nd prev anchor, and draw the
	IM_CURVE for the previous anchor

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCompleteAnchorPlacementBeginnerSplineCreate	proc near
	class	VisSplineClass 
	.enter

	call	SplineSetInvertModeFar

	;
	; Erase IM curve for 2nd prev anchor
	;

	movHL	bx, <mask SDF_IM_CURVE>, <SOT_ERASE>
	mov	dx, mask SWPF_2ND_PREV_ANCHOR
	call	SplineOperateOnCurrentPointFar

	;
	; Draw IM curve for prev anchor
	;

	movHL	bx, <mask SDF_IM_CURVE>, <SOT_DRAW>
	mov	dx, mask SWPF_PREV_ANCHOR
	call	SplineOperateOnCurrentPointFar

	;
	; Draw 2nd PREV curve.
	;

	call	SplineSetNormalAttributes 

	mov	dx, mask SWPF_2ND_PREV_ANCHOR
	movHL	bx, <mask SDF_CURVE>, <SOT_DRAW> 
	call	SplineOperateOnCurrentPointFar 

	call	SplineCompleteAnchorPlacementCommon

	.leave
	ret
SplineCompleteAnchorPlacementBeginnerSplineCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineESAdvancedCreateMoveControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a "MOVE-CONTROLS" operation during advanced
		create mode.

CALLED BY:	SplineESAdvancedCreateMode

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
SplineESAdvancedCreateMoveControls	proc	near
	uses	cx, dx
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints		>  


	;
	; The action point is currently a control point -- move the
	; action point to this control's ANCHOR instead.
	;

	mov	ax, es:[bp].VSI_actionPoint
	call	SplineGotoAnchor
	mov	es:[bp].VSI_actionPoint, ax

	;
	; Erase IM curves:
	;

	movHL	bx, <mask SDF_IM_CURVE>, <SOT_ERASE> 
	mov	dx, SWP_BOTH_CURVES
	call	SplineOperateOnCurrentPointFar 

	;
	; Erase control lines
	;

	mov	bh, mask SDF_CONTROL_LINES
	mov	dx, SWP_ALL_CONTROLS
	call	SplineOperateOnCurrentPointFar 


	; See if control points are close enough to their anchor to be deleted.

	mov	bl, SOT_REMOVE_EXTRA_CONTROLS
	mov	dx, mask SWPF_NEXT_CONTROL or \
			mask SWPF_PREV_CONTROL
	mov	cx, SPLINE_POINT_MOUSE_TOLERANCE
	call	SplineOperateOnCurrentPointFar

	.leave
	ret
SplineESAdvancedCreateMoveControls	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndMoveCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a move operation. Set the Action Type to a
		"Select" back from a "move"

CALLED BY:	SplineESEditModes

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 7/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndMoveCommon	proc near
	class	VisSplineClass 

	uses	ax

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


SYNOPSIS:	Handle end move anchor in edit modes.

CALLED BY:	SplineEndMoveAnchor

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndMoveAnchor	proc near
	class	VisSplineClass 

	mov	bx, SWP_ANCHOR_ALL_CONTROLS_AND_CURVES or \
			mask SWPF_NEXT_ANCHOR

	GetEtypeFromRecord	al, SS_MODE, es:[bp].VSI_state 
	cmp	al, SM_BEGINNER_EDIT
	jne	gotFlags
	ornf	bx, mask SWPF_2ND_PREV_ANCHOR OR \
			mask SWPF_2ND_PREV_FAR_CONTROL or \
			mask SWPF_2ND_PREV_CONTROL or \
			mask SWPF_2ND_NEXT_ANCHOR or \
			mask SWPF_2ND_NEXT_CONTROL or \
			mask SWPF_2ND_NEXT_FAR_CONTROL
gotFlags:
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

	push	bx			; SplineWhichPointFlags
	SplineDerefScratchChunk di
	mov	ax, ds:[di].SD_boundingBox.R_left
	mov	bx, ds:[di].SD_boundingBox.R_top
	mov	cx, ds:[di].SD_boundingBox.R_right
	mov	dx, ds:[di].SD_boundingBox.R_bottom
	mov	di, es:[bp].VSI_gstate
	call	GrInvalRect
	pop	bx			; SplineWhichPointFlags

	; Reset TEMP flags for all points involved.  Do this AFTER we
	; got the bounding box, as the temp flags were used to
	; determine which UNDO points to use.

	mov	al, SOT_MODIFY_INFO_FLAGS
	movL	cx, <mask PIF_TEMP>
	call	SplineOperateOnSelectedPointsFar

	
	; Reset IM_CURVE flags for anchors

	mov	cl, mask APIF_IM_CURVE
	call	SplineOperateOnSelectedPointsFar


	;
	; Draw selected points -- this won't do much because the area
	; just got invalidated, but it will draw next time we get a
	; redraw event
	;

	call	SplineDrawSelectedPoints

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

	GetEtypeFromRecord	bx, SS_MODE, es:[bp].VSI_state 
	CallTable	bx, SplineEndMoveControlTable

	.leave
	ret
SplineEndMoveControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndMoveControlCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end-move control in (advanced) create mode

CALLED BY:	SplineEndMoveControl

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndMoveControlCreate	proc near
	class	VisSplineClass 
	.enter

	mov	ax, es:[bp].VSI_actionPoint

	; See if control points are close enough to their anchor to be deleted.

	mov	bl, SOT_REMOVE_EXTRA_CONTROLS
	mov	dx, mask SWPF_NEXT_CONTROL or \
			mask SWPF_PREV_CONTROL
	mov	cx, SPLINE_POINT_MOUSE_TOLERANCE
	call	SplineOperateOnCurrentPointFar

	.leave
	ret
SplineEndMoveControlCreate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndMoveControlEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an end-move control in advanced edit mode.
		This requires invalidation

CALLED BY:	SplineEndMoveControl

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - current anchor point

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndMoveControlEdit	proc near
	class	VisSplineClass 
	.enter

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
	mov	cx, SPLINE_POINT_MOUSE_TOLERANCE
	call	SplineOperateOnCurrentPointFar
	.leave
	ret
SplineEndMoveControlEdit	endp




SplineSelectCode	ends
