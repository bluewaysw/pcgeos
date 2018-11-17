COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splinePtr.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

DESCRIPTION:
	Routines to deal with MSG_META_PTR

	$Id: splinePtr.asm,v 1.1 97/04/07 11:09:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplinePtrCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplinePtr

DESCRIPTION:	When a mouse-movement event comes in, see what mode
		we're in, and do something about it.

PASS:		*ds:si - VisSpline object
		ds:bx  -  "" ""
		ds:di  - VisSPline instance data
		cx - mouse x position
		dx - mouse y position
		bp - mouse flags

RETURN:		ax - MRF_PROCESSED

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplinePtr	method	dynamic VisSplineClass, MSG_META_PTR
	uses	cx, dx, bp
	.enter
	mov	ax, bp			; mouse flags
	call	SplineCreateGState
	call	SplineMouseMethodCommon
	call	SplineDeltaMousePosition
	CallTable bx, SplinePtrCalls, SplineMode
	call	SplineEndmCommon
	call	SplineDestroyGState
	mov	ax, mask MRF_PROCESSED
	.leave
	ret
SplinePtr	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplinePtrCreateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see what sort of MOVE op is currently
		happening. 

CALLED BY:

PASS:		es:bp - VisSplineInstance data 

RETURN:		

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 7/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePtrCreateCommon	proc near
	class	VisSplineClass 
	.enter
	GetActionType	bl
	cmp	bl, AT_MOVE_CONTROL
	jne	noMove
	call	SplineMakeTempCopyOfVisBounds
	call	SplineMoveControl
	jmp	done
noMove:
	cmp	bl, AT_CREATE_MODE_MOUSE_UP
	jne	done
	call	SplinePtrMouseUp
done:
	.leave
	ret
SplinePtrCreateCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplinePtrBeginnerSplineCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a pointer event in beginner create mode

CALLED BY:	SplinePtr

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	
	Update the controls of the PREVIOUS anchor

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePtrBeginnerSplineCreate	proc near
	class	VisSplineClass
	.enter

	;
	; If we're following the mouse around, then update the
	; previous anchor's controls
	;
	GetActionType al
	cmp	al, AT_CREATE_MODE_MOUSE_UP
	jne	done

	;
	; Go to the last anchor, unless there is none.
	;
	call	SplineGotoLastAnchor
	jc	done

	call	SplineSetInvertMode

	; Erase the old curves

	movHL	bx, <mask SDF_IM_CURVE>, <SOT_ERASE>
	mov	dx, mask SWPF_PREV_ANCHOR
	call	SplineOperateOnCurrentPointFar

	SplineDerefScratchChunk di
	movP	cxdx, ds:[di].SD_lastMouse
	call	SplineDrawFromLastAnchor

	;
	; Update the controls
	;

	movP	cxdx, ds:[di].SD_mouse
	call	SplineUpdateAutoSmoothControlsCXDX

	; Redraw the curves

	call	SplineDrawFromLastAnchor

	movHL	bx, <mask SDF_IM_CURVE>, <SOT_DRAW>
	mov	dx, mask SWPF_PREV_ANCHOR
	call	SplineOperateOnCurrentPointFar

done:
	.leave
	ret
SplinePtrBeginnerSplineCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplinePtrMouseUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with pointer events when the mouse is up. 
		Erase the spline curve from the last anchor to
		the previous mouse position and draw one to the
		 new position

CALLED BY:	

PASS:		es:bp - VisSplineInstance data 

RETURN:		

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 4/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePtrMouseUp	proc near	uses cx,dx,di
	class	VisSplineClass 
	.enter
	call	SplineSetInvertMode
	 
	SplineDerefScratchChunk	di
	movP	cxdx, ds:[di].SD_lastMouse
	call	SplineDrawFromLastAnchor

	movP	cxdx, ds:[di].SD_mouse
	call	SplineDrawFromLastAnchor
	.leave
	ret
SplinePtrMouseUp	endp

 



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineDeltaMousePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See how much the mouse has changed since the last
		store.  Update the mouse position and "deltas" fields
		in the scratch chunk.

CALLED BY:	SplinePtr, SplineSetVisBounds

PASS:		cx, dx, - mouse
		es:bp - VisSplineInstance data

RETURN:		cx, dx, -  deltax, deltay.  Everything relevant is
		stored in the scratch chunk

DESTROYED:	nothing

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDeltaMousePosition	proc	near	uses ax, si
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	>

	SplineDerefScratchChunk si

; Get the stored mouse, store it in "last mouse", and update the new
; mouse posn and deltas

	mov	ax, ds:[si].SD_mouse.P_x
	mov	ds:[si].SD_lastMouse.P_x, ax
	mov	ds:[si].SD_mouse.P_x, cx
	sub	cx, ax
	mov	ds:[si].SD_deltas.P_x, cx

	mov	ax, ds:[si].SD_mouse.P_y
	mov	ds:[si].SD_lastMouse.P_y, ax
	mov	ds:[si].SD_mouse.P_y, dx
	sub	dx, ax
	mov	ds:[si].SD_deltas.P_y, dx

	.leave
	ret
SplineDeltaMousePosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMoveCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try and perform a move based on the current action
		type.  If action type is irrelevant, do nothing.

CALLED BY:

PASS:		es:bp - VisSplineInstance data 
		cx, dx - mouse deltas
		ax - mouse flags (used by SplinePtrMoveRectangle)

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 4/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMoveCommon	proc near
	class	VisSplineClass 
	.enter
	GetActionType	bx
	sub	bl, AT_MOVE_ANCHOR
 	js	done		; Do nothing on AT_NONE!

	; copy the vis bounds to the scratch chunk to see if the move affects
	; them. 
	call	SplineMakeTempCopyOfVisBounds
	call	SplineSetInvertMode 
	CallTable	bx, SplineMoveCalls
done:
	.leave
	ret
SplineMoveCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMoveAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the current selected points, move them, see if
		change affected Vis bounds, then redraw.

CALLED BY:	SplineMoveCommon

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		cx, dx - deltas

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMoveAnchor	proc near


	class	VisSplineClass
	.enter

	;
	; Erase curves and control lines (there are no control lines
	; in beginner mode, but who cares?)
	;

	movHL	ax, <mask SDF_IM_CURVE or mask SDF_CONTROL_LINES>, \
			<SOT_ERASE>

	mov	bx, SWP_ANCHOR_CONTROLS_AND_CURVES
	call	SplineOperateOnSelectedPoints


	push	cx			; delta X
	mov	cl, SOT_ERASE
	call	checkBeginnerMode
	pop	cx

	;
	; Add deltas to the anchor (controls are changed based on anchor's
	; smoothness)
	;

	mov	al, SOT_ADD_DELTAS
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPoints

	;
	; Update controls now that all the anchors have been moved:
	;

	mov	al, SOT_UPDATE_CONTROLS_FROM_ANCHOR
	call	setUpdateControlFlags
	call	SplineOperateOnSelectedPoints

	mov	ax, SOT_ADD_TO_BOUNDING_BOX	; clear AH
	call	setBoundingBoxFlags
	mov	cl, es:[bp].VSI_handleSize.BBF_int
	clr	ch
	call	SplineOperateOnSelectedPoints

	;
	; Check to change the spline's size
	;

	call	SplineDetermineIfTempVisBoundsChanged

	;
	; Redraw IM curves.  
	;

	movHL	ax, <mask SDF_IM_CURVE>, <SOT_DRAW>

	mov	bx, SWP_ANCHOR_CONTROLS_AND_CURVES
	call	SplineOperateOnSelectedPoints

	;
	; Redraw outer curves in beginner mode
	;

	mov	cl, SOT_DRAW
	call	checkBeginnerMode

	;
	; redraw control lines (in advanced modes)
	;

	GetMode	al
	cmp	al, SM_ADVANCED_CREATE
	je	drawControl
	cmp	al, SM_ADVANCED_EDIT
	jne	done

drawControl:

	movHL	ax, <mask SDF_CONTROL_LINES>, <SOT_DRAW> 
	mov	bx, mask SWPF_NEXT_CONTROL or \
			mask SWPF_PREV_CONTROL
	call	SplineOperateOnSelectedPoints
done:
	.leave
	ret

setUpdateControlFlags:
	mov	di, offset updateControlTable
setFlagsCommon:
	GetEtypeFromRecord	bx, SS_MODE, es:[bp].VSI_state
	shl	bx
	mov	bx, cs:[bx][di]
	retn

setBoundingBoxFlags:
	mov	di, offset boundingBoxTable
	jmp	setFlagsCommon



checkBeginnerMode:
	GetEtypeFromRecord	al, SS_MODE, es:[bp].VSI_state
	cmp	al, SM_BEGINNER_EDIT
	jne	endCheck

	;
	; See if we should erase the OUTER curves as well (involves
	; more complicated case-checking)
	;

	mov	al, SOT_CHECK_BEGINNER_ANCHOR_MOVE
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPoints
endCheck:
	retn

SplineMoveAnchor	endp


updateControlTable	SplineWhichPointFlags	\
	-1,				; SM_BEGINNER_POLYLINE_CREATE
	-1,				; SM_BEGINNER_SPLINE_CREATE
	-1,				; SM_ADVANCED_CREATE
	mask SWPF_PREV_ANCHOR or \
		mask SWPF_ANCHOR_POINT or \
		mask SWPF_NEXT_ANCHOR,	; SM_BEGINNER_EDIT
	mask SWPF_ANCHOR_POINT,		; SM_ADVANCED_EDIT
	0

boundingBoxTable	SplineWhichPointFlags	\
	-1,		 		; SM_BEGINNER_POLYLINE_CREATE
	-1,		 		; SM_BEGINNER_SPLINE_CREATE
	-1,				  ; SM_ADVANCED_CREATE
	SWP_ANCHOR_ALL_CONTROLS_BEGINNER, ; SM_BEGINNER_EDIT
	SWP_ANCHOR_AND_CONTROLS,	  ; SM_ADVANCED_EDIT
	0




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMoveSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move a spline segment during advanced edit mode

CALLED BY:	SplinePtr

PASS:		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	
	Segments are moved by adjusting control points by the amount
	of mouse movement.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMoveSegment	proc near 	uses	ax,bx
	class	VisSplineClass 
	.enter

	; Erase
	movHL	ax, <mask SDF_IM_CURVE or mask SDF_CONTROL_LINES>,\
			<SOT_ERASE>
	mov	bx, SWP_SEGMENT
	call	SplineOperateOnSelectedPoints

	; Update
	mov	al, SOT_ADD_DELTAS
	mov	bx, mask SWPF_NEXT_CONTROL or mask SWPF_NEXT_FAR_CONTROL
	call	SplineOperateOnSelectedPoints

	mov	ax, SOT_ADD_TO_BOUNDING_BOX	; clear AH
	mov	cl, es:[bp].VSI_handleSize.BBF_int
	clr	ch
	call	SplineOperateOnSelectedPoints

	call	SplineDetermineIfTempVisBoundsChanged

	; Redraw
	movHL	ax, <mask SDF_IM_CURVE or mask SDF_CONTROL_LINES>,\
			<SOT_DRAW>
	mov	bx, SWP_SEGMENT
	call	SplineOperateOnSelectedPoints

	.leave
	ret
SplineMoveSegment	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMoveControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move control points during advanced create/advanced edit

CALLED BY:	SplinePtr, SplineMoveCommon

PASS:		es:bp - VisSplineInstance data
		(cx,dx) - mouse deltas

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMoveControl	proc near 	uses	ax,bx
	class	VisSplineClass 
	.enter

	mov	ax, es:[bp].VSI_actionPoint 
EC <	call	ECSplineControlPoint		>

	push	dx				; save mouse position
	push	cx

	; erase
	movHL	bx, <SDT_MOVE_CONTROL>, <SOT_ERASE> 
	call	SplineSetFlagsForControlMove
	call	SplineOperateOnCurrentPoint

	; update
	pop	cx				; restore deltas and
	XchgTopStack	dx			; save SplineWhichPointFlags
	
	call	SplineUserChangeControlPoint	; set the control
	call	SplineChangeOtherControlPoint	; set the other ctrl point

	mov	bx, SOT_ADD_TO_BOUNDING_BOX	; clear BH
	mov	dx, mask SWPF_NEXT_CONTROL or \
			mask SWPF_PREV_CONTROL
	mov	cl, es:[bp].VSI_handleSize.BBF_int
	clr	ch
	call	SplineOperateOnCurrentPoint

	call	SplineDetermineIfTempVisBoundsChanged

	; redraw
	movHL	bx, <SDT_MOVE_CONTROL>, <SOT_DRAW> 
	pop	dx
	call	SplineOperateOnCurrentPoint
	.leave
	ret
SplineMoveControl endp


SplinePtrCode	ends
