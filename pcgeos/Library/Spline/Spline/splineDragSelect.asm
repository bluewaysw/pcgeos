COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		spline
FILE:		splineDragSelect.asm

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
	

	$Id: splineDragSelect.asm,v 1.1 97/04/07 11:09:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSelectCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineDragSelect, MSG_META_DRAG_SELECT

DESCRIPTION:	If in "Create" mode, then create control points and set
		them at mouse (cx, dx), then get ready for a MOVE operation 

		If EDIT mode, prepare for a MOVE operation, if there's
		a point that's selected, or otherwise, begin the "drag box".

PASS:		*ds:si - VisSpline object
		ds:bx  -  "" ""
		ds:di  - VisSPline instance data
		cx - mouse x position
		dx - mouse y position
		bp - mouse flags

RETURN:		ax = MRF_PROCESSED

DESTROYED:	nothing

REGISTER/STACK USAGE:	al - Spline Mode

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDragSelect	method	dynamic VisSplineClass, MSG_META_DRAG_SELECT
	uses	cx, dx, bp
	.enter

	mov	ax, bp			; mouse flags
 	call	SplineMouseMethodCommon

	CallTable bx, SplineDragSelectCalls, SplineMode

	call	SplineEndmCommon
	mov	ax,mask MRF_PROCESSED
	.leave
	ret
SplineDragSelect	endm	




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineDSAdvancedCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare for a control-move
			
CALLED BY:	call table (SplineDragSelect)

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	ax, bx,cx,dx,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineDSAdvancedCreate	proc	near
	class	VisSplineClass

	mov	ax, es:[bp].VSI_actionPoint
	call	SplineAddVerySmoothControlPoints ; add control points around ax
	cmp	cl, SRT_TOO_MANY_POINTS
	je	done

	inc	ax			; move to NEXT control point
	mov	bl, AT_MOVE_CONTROL
	call	SplineMakeActionPoint	; make it the action point

done:	
	ret
SplineDSAdvancedCreate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDSEditModes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a "select" action to a "move" action

CALLED BY:	SplineDragSelect

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		ax - mouse flags

RETURN:		nothing

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/25/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDSEditModes	proc near 
	class	VisSplineClass
	.enter

	call	SplineSetInvertModeFar

	; Get action type into BX (assume bh is zero) 
	GetActionType	bx	
	ECMakeSureZero	bh
				
	cmp	bl, AT_NONE
	je	done

EC <	cmp	bl, AT_SELECT_NOTHING		>
EC <	ERROR_G ILLEGAL_ACTION_TYPE		>

	;
	; Tell UNDO about pending move
	;

	push	ax			; mouse flags
	mov	ax, UT_MOVE
	call	SplineInitUndo
	pop	ax			; mouse flags

	;
	; Convert the SELECT action to a MOVE action of the same form
	;

	push	bx
EC <	cmp	bl, AT_SELECT_ANCHOR	>
EC <	ERROR_S ILLEGAL_ACTION_TYPE	>
	sub	bl, AT_SELECT_ANCHOR
	CallTable	bx, SplineBeginMoveCalls
	pop	bx

	add	bl, (AT_MOVE_ANCHOR - AT_SELECT_ANCHOR)
	SetActionType	bl
done:
	.leave
	ret
SplineDSEditModes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBeginMoveSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin a segment-move operation

CALLED BY:	SplineDSEditModes

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


	.leave
	ret
SplineBeginMoveSegment	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBeginMoveAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin a MOVE_ANCHOR operation

CALLED BY:	SplineDSEditModes

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
	class	VisSplineClass 
	.enter

	; copy anchor and controls to UNDO

	mov	al, SOT_COPY_TO_UNDO
	call	setCopyToUndoFlags
	call	SplineOperateOnSelectedPointsFar

	; erase filled handles
	
	movHL	ax, <mask SDF_FILLED_HANDLES>, <SOT_ERASE>
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnSelectedPointsFar

	; Set TEMP flags

	mov	al, SOT_MODIFY_INFO_FLAGS 
	movH	cx, <mask PIF_TEMP>
	call	setTempFlags
	call	SplineOperateOnSelectedPointsFar


	.leave
	ret

setCopyToUndoFlags:
	mov	di, offset copyToUndoTable
setFlagsCommon:
	GetEtypeFromRecord	bx, SS_MODE, es:[bp].VSI_state 
	shl	bx, 1
	mov	bx, cs:[di][bx]
	retn

setTempFlags:
	mov	di, offset tempFlagsTable
	jmp	setFlagsCommon

SplineBeginMoveAnchor	endp

copyToUndoTable	SplineWhichPointFlags	\
	mask SWPF_ANCHOR_POINT,			; SM_BEGINNER_POLYLINE_CREATE
	SWP_ANCHOR_ALL_CONTROLS_BEGINNER,	; SM_BEGINNER_SPLINE_CREATE
	mask SWPF_ANCHOR_POINT,			; SM_ADVANCED_CREATE
	SWP_ANCHOR_ALL_CONTROLS_BEGINNER,	; SM_BEGINNER_EDIT
	SWP_ANCHOR_AND_CONTROLS,		; SM_ADVANCED_EDIT
	0

.assert (length copyToUndoTable eq SplineMode)

tempFlagsTable	SplineWhichPointFlags	\
	mask SWPF_ANCHOR_POINT, 		; SM_BEGINNER_POLYLINE_CREATE
	SWP_ANCHOR_ALL_CONTROLS_BEGINNER,	; SM_BEGINNER_SPLINE_CREATE
	mask SWPF_ANCHOR_POINT,			; SM_ADVANCED_CREATE
	SWP_ANCHOR_ALL_CONTROLS_BEGINNER,	; SM_BEGINNER_EDIT
	SWP_ANCHOR_AND_CONTROLS,		; SM_ADVANCED_EDIT
	0

.assert (length tempFlagsTable eq SplineMode)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBeginMoveControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin a MOVE-CONTROLS operation

CALLED BY:	SplineDSEditModes

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
	pop	ax				; control point number

	; Erase filled handles

	movHL	bx, <mask SDF_FILLED_HANDLES>, <SOT_ERASE>
	call	SplineSetFlagsForControlMove	; sets dx (SWPF)
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
		its anchor point in the "scratch" block.  Increment
		the ref count of the scratch chunk so that it will
		persist until the end of the move

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
	;

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



SplineSelectCode	ends
