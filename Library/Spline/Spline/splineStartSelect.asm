COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineStartSelect.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

DESCRIPTION:
	code to handle MSG_META_START_SELECT

	$Id: splineStartSelect.asm,v 1.1 97/04/07 11:09:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineSelectCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineStartSelect

DESCRIPTION:	Based on the mode we're in, figure out what to do when a
		button press comes in.  Create a gstate, and then process
		the input.
		
PASS:		*ds:si - VisSpline object
		ds:bx -  VisSpline object
		ds:di -  VisSpline_offset
		cx - x position
		dx - y position
		bp - mouse flags
 
RETURN:		ax - MRF_PROCESSED

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineStartSelect	method dynamic VisSplineClass, MSG_META_START_SELECT
	uses	cx, dx, bp
	.enter

	mov	ax, bp			; mouse flags

	call	MetaGrabTargetExclLow	; gives us a GSTATE
	call	MetaGrabFocusExclLow
	call	VisGrabMouse

	call	SplineCalcHandleDimensions

	call	SplineMouseMethodCommon		

	;
	; store the mouse position and flags in the scratch chunk.
	;

	SplineDerefScratchChunk di
	movP	ds:[di].SD_mouse, cxdx
	mov	ds:[di].SD_mouseFlags, ax
	
	; use the jump table to figure out what to do.

	CallTable bx, SplineStartSelectCalls, SplineMode

	call	SplineEndmCommon
	mov	ax, mask MRF_PROCESSED
	.leave
	ret
SplineStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineSSCreateModeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common start-select code for all create modes.
		Erase invert-mode curve curve from last anchor, if any.
		See if mouse click is over first or last anchor, and
		if so, end create mode.
		Otherwise, create a new anchor point

CALLED BY:	SplineStartSelect

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		cx, dx - mouse position
		ax - mouse flags

RETURN:		carry clear if new point created
		carry set otherwise.  If carry is set, we've left
		create mode

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSSCreateModeCommon	proc	near
	uses	ax, bx, di
	class	VisSplineClass 
	.enter

	;
	; Erase the curve from the last anchor to the mouse, and set
	; the action type to AT_NONE, so that other procedures will
	; know the sprite isn't on-screen.
	;
	GetActionType	al
	cmp	al, AT_CREATE_MODE_MOUSE_UP
	jne	afterMouse		
	call	SplineDrawFromLastAnchorToMouse
	SetActionType	AT_NONE
afterMouse:

	;
	; Check for mouse on first anchor. If no first anchor then
	; there are no points, so just add an anchor.
	;

	call	SplineGotoFirstAnchor
	jc	addAnchor			;jmp if no first anchor
	call	SplinePointAtCXDXFar
	jc	terminateAndClose

	;
	; Check for mouse on last anchor.
	;

	call	SplineGotoLastAnchor
	jc	addAnchor			;jmp if no last anchor
	call	SplinePointAtCXDXFar
	jc	terminate

addAnchor:
	; 
	; Spline not ended so add a new anchor point at the mouse click.
	; If no more anchors can be added then leave create mode.
	;

	call	SplineAddAnchor
	jc	terminate			;jmp if achieved max anchors

	;
	; We want hollow handles drawn on the first anchor point
	; and on the most recently added anchor point so that
	; the user know where to click to end the spline.
	;

	;
	; Select this point.  
	;
	
	call	SplineSelectPointFar
	call	SplineDrawSelectedPoints
	
	;
	; If no previous anchor then we just created first and we
	; don't have to do anything else
	;

	call	SplineGotoPrevAnchorFar
	jc	afterUnselect

	;
	; Unselect the previous point.
	;

	call	SplineUnselectPoint

afterUnselect:

	mov	ax, UT_ADD_POINT
	call	SplineInitUndo

	SetActionType	AT_SELECT_ANCHOR
	clc				; signify we created a new
					; anchor. 

done:
EC <	call	ECSplineInstanceAndPoints		>  
	.leave
	ret

;------------------------------
terminateAndClose:
	;
	; Since we are going to close the curve, let's just erase all the
	; line segments (we are still in invert mode).  This fixes the
	; problems where parts of the curve are temporarily outside of the
	; bounding box, including the case where the there are only two
	; distinct anchor points (the last and first overlap).
	;
	movHL	ax, <mask SDF_CURVE>, <SOT_DRAW>
	mov	bx, mask SWPF_PREV_ANCHOR
	call	SplineOperateOnAllPoints

	mov	ax, MSG_SPLINE_CLOSE_CURVE
	call	SplineSendMyselfAMessage

terminate:
	;
	; Unselect the last anchor
	;
	call	SplineGotoLastAnchor
	jc	afterUnselect2
	call	SplineUnselectPoint
afterUnselect2:

	mov	ax,MSG_SPLINE_NOTIFY_CREATE_MODE_DONE
	call	SplineSendMyselfAMessage


	;
	; Nuke the undo stuff, as this prevents a crash if the grobj
	; decides this spline needs to be deleted, and anyway the Undo type
	; isn't really relevant at this point.
	;

	call	GeodeGetProcessHandle
	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage

	stc
	jmp	done

SplineSSCreateModeCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSSBeginnerCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start select in beginner create mode.  draw the
		anchor, because the user can't change the shape until
		after the next END SELECT


CALLED BY:	SplineStartSelect

PASS:		es:bp - vis spline
		*ds:si - points

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSSBeginnerCreate	proc near
	class	VisSplineClass
	.enter

	; If the action point has been deleted, then don't complete
	; anchor placement.  This is for the case where the user
	; double-clicks on the first point in Polyline Create mode.

	call	SplineSSCreateModeCommon
	jc	done

	call	SplineCompleteAnchorPlacement
done:	
	.leave
	ret
SplineSSBeginnerCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSSBeginnerSplineCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle START_SELECT in beginner spline create -- add
		controls to last anchor.

CALLED BY:	SplineStartSelect

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSSBeginnerSplineCreate	proc near
	class	VisSplineClass 
	.enter


	;
	; What the hell -- put a NOP in here.  It can't cause any
	; problems
	; I wonder if:
	;	- anyone will notice
	; 	- it'll ship with our product
	;	- this source code will one day be released
	;

	nop


	;
	; Call the common routine -- this will add an anchor, unless
	; it tells us it didn't.
	;
		
	call	SplineSSCreateModeCommon
	jc	done

	;
	; Add auto-smooth controls to the last anchor.  We know there
	; is such a thing, because the called routine just created it.
	;

	call	SplineGotoLastAnchor
EC <	ERROR_C ILLEGAL_SPLINE_POINT_NUMBER	>
	call	SplineAddNextControlFar
	call	SplineAddPrevControlFar


	call	SplineCompleteAnchorPlacementBeginnerSplineCreate


done:	

	.leave
	ret
SplineSSBeginnerSplineCreate	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSSEditMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In edit modes, see if the mouse is over a point, and
		if so, select that point.

CALLED BY:	SplineStartSelect

PASS:		(cx,dx) - mouse point
		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ax - mouse flags

RETURN:		cx - point number
		dl - SplineSelectType

DESTROYED:	ax,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/22/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSSEditMode	proc	near
	uses	bx,cx,dx
	class	VisSplineClass 
	.enter

	test	ax, mask BI_DOUBLE_PRESS
	jnz	doublePress

	call	SplineHitDetectLow
	xchg	ax, cx			; ax <- point #
					; cx <- mouse flags
	mov	bl, dl
	clr	bh
	CallTable	bx, SplineSelectInternalCalls, SplineSelectType
done:
	.leave
	ret

doublePress:

	GetActionType al
	cmp	al, AT_SELECT_ANCHOR
	je	gotPoint
	cmp	al, AT_SELECT_CONTROL
	jne	done

gotPoint:

	;
	; Get to an anchor point
	;

	mov	ax, es:[bp].VSI_actionPoint
	call	SplineGotoAnchor

	;
	; Make this anchor the only selected point
	;

	call	SplineUnselectAll
	call	SplineSelectPointFar
	call	SplineDrawSelectedPoints

	;
	; If this point has no controls, then add 2. Otherwise, delete
	; any controls.
	;

	call	SplineGotoPrevControlFar
	jc	noPrev

deleteControls:
	mov	ax, MSG_SPLINE_DELETE_CONTROLS
	call	SplineSendMyselfAMessage
	jmp	done



noPrev:
	call	SplineGotoNextControlFar
	jnc	deleteControls

	;
	; There are no controls, so add them
	;
	mov	ax, MSG_SPLINE_INSERT_CONTROLS
	call	SplineSendMyselfAMessage
	jmp	done

SplineSSEditMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectNothingInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the mouse doesn't hit anything, prepare for
		creating a drag rectangle.

CALLED BY:	SplineSSEditMode (SplineSelectInternalCalls)

PASS:		es:bp - vis spline
		ds - spline's data block
		cl - ButtonInfo
		ch - UIFunctionsActive

RETURN:		nothing 

DESTROYED:	ax,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectNothingInternal	proc	near

	class	VisSplineClass 

	.enter

	SetActionType	AT_SELECT_NOTHING

	;
	; If UIFA_EXTEND, then just leave the start of the mouse where
	; it is. 
	;

	test	ch, mask UIFA_EXTEND
	jnz	afterSetStartRect

	SplineDerefScratchChunk	di
	MovPoint	ds:[di].SD_startRect, ds:[di].SD_mouse, ax

afterSetStartRect:

	;
	; If neither the EXTEND nor the ADJUST flags are set, then
	; unselect all points
	;

	test	ch, mask UIFA_EXTEND or mask UIFA_ADJUST
	jnz	done

	call	SplineUnselectAll

done:
	.leave
	ret
SplineSelectNothingInternal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectAnchorInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select an anchor point and make it the action point.
		Use mouse flags to unselect others, etc, as appropriate.

CALLED BY:	SplineSSEditMode

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ax - anchor point number 

RETURN:		nothing 

DESTROYED:	bl

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectAnchorInternal	proc near
	mov	bl, AT_SELECT_ANCHOR
	GOTO	SplineSelectAnchorOrControlInternal
SplineSelectAnchorInternal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectControlInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the control point, make it the action point,
		and select its anchor owner (depending on mouse flags)

CALLED BY:	SplineSSEditMode

PASS:		*ds:si - points array 
		es:bp - VisSplineInstance data 
		ax - current point

RETURN:		

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectControlInternal	proc near
	mov	bl, AT_SELECT_CONTROL
	FALL_THRU	SplineSelectAnchorOrControlInternal
SplineSelectControlInternal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectAnchorOrControlInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're currently in SELECT_SEGMENT mode, then
		unselect everything before selecting current point

CALLED BY:	SplineSelectAnchorInternal, 
		SplineSelectControlInternal

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ax - current point
		bl - ActionType

RETURN:		nothing 

DESTROYED:	bx, di, ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/25/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectAnchorOrControlInternal	proc near
	class	VisSplineClass 
	.enter

	GetActionType	bh
	cmp	bh, AT_SELECT_SEGMENT
	jne	afterUnselect
	call	SplineUnselectAll

afterUnselect:
	call	SplineMakeActionPoint
	call	SplineGotoAnchor
	call	SplineModifySelection
	.leave
	ret
SplineSelectAnchorOrControlInternal	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectSegmentInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a segment of the spline

CALLED BY:	SplineSSEditMode

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/23/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectSegmentInternal	proc	near
	uses	bx
	class	VisSplineClass 
	.enter
	GetMode	bx
	CallTable	bx, SplineSelectSegmentCalls, SplineMode
	.leave
	ret
SplineSelectSegmentInternal	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineHitDetectLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the mouse came across anything
		interesting.

CALLED BY:

PASS:		(cx, dx) - mouse (in VisSpline coordinates)
		es:bp - VisSpline
		*ds:si - points

RETURN:		cx - point number of selected/hit point (if any)
		dl - SplineSelectType
		
DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineHitDetectLow	proc	near
	uses	ax,bx
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints	>

	;
	;  Make sure the handle dimensions are OK
	;

if 0
	push	ds, si
	SplineDerefScratchChunk si
	mov	si, ds:[si].SD_splineChunkHandle
	segmov	ds, es
	call	SplineCalcHandleDimensions	
	pop	ds, si
endif

	mov	al, SOT_CHECK_MOUSE_HIT

	; If in BEGINNER EDIT mode, skip control-point test:
	GetMode	ah 
	cmp	ah, SM_BEGINNER_EDIT
	je	anchors

	mov	bx, SWP_ALL_CONTROLS
	call	SplineOperateOnSelectedPointsFar
	mov	bl, SST_CONTROL_POINT
	LONG jc	found

	; If no CONTROL points were found, then look for ANCHOR points.

anchors:
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnAllPoints
	mov	bl, SST_ANCHOR_POINT
	LONG jc	found

	mov	al, SOT_CHECK_MOUSE_HIT_SEGMENT
	mov	bx, mask SWPF_ANCHOR_POINT 
	call	SplineOperateOnAllPoints
	mov	bl, SST_SEGMENT
	jc	found

	mov	ax, cx
	mov	bx, dx

	; AX, BX - mouse point

	test	es:[bp].VSI_state, mask SS_FILLED 
	jz	afterPath

	; Draw the spline to a path, so we can see if point is inside it

	call	SplineDrawToPathFar

	mov	cl, RFR_ODD_EVEN
	call	GrTestPointInPath

	jnc	afterPath
	mov	dl, SST_INSIDE_CLOSED_CURVE
	mov	cx, -1			; no point
	jmp	done

afterPath:

EC <	call	ECSplineInstanceAndPoints		> 

	; Final check -- see if inside vis bounds.  Since the point
	; has already been translated to the spline's internal
	; coordinate system, check if ax, bx are positive and less
	; than the spline's width, height

	tst	ax
	js	notFound
	tst	bx
	js	notFound

	push	ax
	mov	ax, MSG_VIS_GET_SIZE
	call	SplineSendMyselfAMessage	; cx, dx - size
	pop	ax

	cmp	ax, cx
	jg	notFound
	cmp	bx, dx
	jg	notFound
	mov	dl, SST_INSIDE_VIS_BOUNDS
	mov	cx, -1			; no point
	jmp	done

notFound:
	mov	dl, SST_NONE
done:

EC <	call	ECSplineInstanceAndPoints	>

	.leave
	ret

	; A point was found!  Get its number (stored in scratch chunk), and
	; move the SplineSelectType into dl
found:
	SplineDerefScratchChunk di
	mov	cx, ds:[di].SD_pointNum
	mov	dl, bl
	jmp	done

SplineHitDetectLow	endp



	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineHitDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	See if the mouse "hits" a point (external)

PASS:		*DS:SI	= VisSplineClass object
		DS:DI	= VisSplineClass instance data
		ES	= Segment of VisSplineClass.
		AX	= Method.
		cx, dx	= mouse position

RETURN:		cx - point number of selected point, if a point was
		selected, -1 otherwise

		dl - SplineSelectType

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 8/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineHitDetect	method	dynamic	VisSplineClass, MSG_SPLINE_HIT_DETECT
	uses	bp

	.enter

	call	SplineCreateGState		; for the path test
	call	SplineCalcHandleDimensions
	call	SplineMouseMethodCommonReadOnly
	call	SplineHitDetectLow
	call	SplineDestroyGState
	call	SplineEndmCommon

 	.leave
	ret

SplineHitDetect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCalcHandleDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the VisSpline's handle size to yield a constant
		pixel (ie., device coordinate) size.

CALLED BY:	SplineHitDetect

PASS:		*ds:si = VisSplineClass object

RETURN:		nothing

DESTROYED:	nothing

	Name	Date		Description
	----	----		-----------
	jon	21 dec 1992	Initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCalcHandleDimensions	proc	near
	class	VisSplineClass
	uses	ax, bx, cx, dx, di, si, es

untransformedOrigin	local	PointWWFixed

	.enter

	call	SplineCreateGState		; for the path test

	mov	si, ds:[si]
	add	si, ds:[si].VisSpline_offset
	mov	di, ds:[si].VSI_gstate

	;
	;  Untransform 0,0
	;
	clr	ax, bx, cx, dx
	call	GrUntransformWWFixed

	movwwf	ss:[untransformedOrigin].PF_x, dxcx
	movwwf	ss:[untransformedOrigin].PF_y, bxax

	;
	;  Untransform SPLINE_POINT_MOUSE_TOLERANCE, 0
	;
	clr	ax, bx, cx
	mov	dx, INIT_HANDLE_SIZE shr 8
	call	UntransformAndCalcDistance
	mov	{word} ds:[si].VSI_handleSize, ax
	;
	;  Untransform 0, SPLINE_POINT_MOUSE_TOLERANCE
	;
	clr	ax, cx, dx
	mov	bx, INIT_HANDLE_SIZE shr 8
	call	UntransformAndCalcDistance
	mov	{word} ds:[si].VSI_handleHeight, ax

	push	bp
	mov	bp, si
	segmov	es, ds
	call	SplineDestroyGState
	pop	bp

 	.leave
	ret
SplineCalcHandleDimensions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UntransformAndCalcDistance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		dx:cx, bx:ax - point
		di - gstate
		untransformedOrigin inherited from SplineCalcHandleDimensions

Return:		ax - BBFixed distance between untransformed point and
		     untransformedOrigin

Destroyed:	bx, cx, dx

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UntransformAndCalcDistance	proc	near
	.enter inherit SplineCalcHandleDimensions

	;
	;  Untransform the point
	;

	call	GrUntransformWWFixed

	;
	;  Calculate the distance between the trwo untransformed points
	;

	subwwf	dxcx, ss:[untransformedOrigin].PF_x
	call	GrSqrWWFixed

	subwwf	bxax, ss:[untransformedOrigin].PF_y
	xchg	dx, bx
	xchg	cx, ax

	call	GrSqrWWFixed

	addwwf	dxcx, bxax
	call	GrSqrRootWWFixed

	;
	;  Convert the WWFixed to a BBFixed, and save it
	;

	mov	ah, dl
	mov	al, ch

	.leave
	ret
UntransformAndCalcDistance	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Select the passed point 

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		ax	= Method.
		cx - point number
		dl - SplineSelectType

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSelect	method	dynamic	VisSplineClass, MSG_SPLINE_SELECT
	uses	bp

	.enter

	call	SplineCreateGState
	call	SplineMethodCommon 
	call	SplineSelectLow
	mov	cx, UPDATE_ALL
	call	SplineUpdateUI
	call	SplineDestroyGState
	call	SplineEndmCommon 

	.leave
	ret
SplineSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectAtCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Select whatever happens to be at the passed coordinates.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		ax	= Method.
		(cx,dx) = coordinates.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/22/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSelectAtCoords	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SELECT_AT_COORDS
	uses	ax,cx,dx,bp
	.enter
	call	SplineCreateGState
	call	SplineCalcHandleDimensions
	call	SplineMethodCommon 
	call	SplineHitDetectLow
	call	SplineSelectLow
	call	SplineEndmCommon 
	call	SplineDestroyGState

	.leave
	ret
SplineSelectAtCoords	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInactiveToEditMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go from "inactive" mode to edit mode

CALLED BY:	SplineSelect

PASS:		es:bp - VisSpline object
		ds - data segment of spline's lmem block 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInactiveToEditMode	proc	near
	uses	ax, cx
	.enter
	mov	cl, SM_ADVANCED_EDIT
	mov	ax, MSG_SPLINE_SET_MODE
	call	SplineSendMyselfAMessage	
	.leave
	ret
SplineInactiveToEditMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a point

CALLED BY:	SplineStartSelect, SplineSelect

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		cx - point number
		dl - SplineSelectType

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectLow	proc	near
	uses	ax,bx
	class	VisSplineClass 
	.enter
	GetEtypeFromRecord	bx, SS_MODE, es:[bp].VSI_state 
	cmp	bx, SM_INACTIVE
	jne	afterInactive
	call	SplineInactiveToEditMode

afterInactive:
	mov	ax, cx
	mov	bl, dl
	clr	bh
	CallTable	bx, SplineSelectCalls, SplineSelectType
	ECCheckEtype	bl, ActionType
	SetActionType	bl		; returned from called procs.
	call	SplineDrawSelectedPoints

	.leave
	ret
SplineSelectLow	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the current control point the action point, and
		make its anchor the selected point

CALLED BY:	SplineSelectLow

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ax - point number		

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectControl	proc	near
	uses	ax,di
	class	VisSplineClass 
	.enter
	mov	es:[bp].VSI_actionPoint, ax
	call	SplineGotoAnchor
	call	SplineSelectPointFar
	mov	bl, AT_SELECT_CONTROL
	.leave
	ret
SplineSelectControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	select an anchor point

CALLED BY:	EXTERNAL selection routine

PASS:		es:[bp] - spline

RETURN:		

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/22/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectAnchor	proc near
	.enter
	call	SplineSelectPointFar
	mov	bl, AT_SELECT_ANCHOR
	.leave
	ret
SplineSelectAnchor	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a spline segment

CALLED BY: 	SplineSelectCalls

PASS:		es:bp - spline

RETURN:		ActionType (bl)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/22/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectSegment	proc near
	.enter
	call	SplineSelectPointFar
	mov	bl, AT_SELECT_SEGMENT
	.leave
	ret
SplineSelectSegment	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:

PASS:		nothing 

RETURN:		bl - ActionType

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectNothing	proc near
	.enter
	mov	bl, AT_SELECT_NOTHING
	.leave
	ret
SplineSelectNothing	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectSegmentAdvancedEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a segment.  Will draw "marching ants" when
		supported. 

CALLED BY:	SplineSelectLow

PASS:		es:bp - VisSplineInstance data
		ax - anchor point number
		*ds:si - points

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 5/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectSegmentAdvancedEdit	proc near 	uses	bx, di
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints		>

	; See if we were already in "select-segment" mode.  If not, then
	; unselect all existing points

	GetActionType	bl
	cmp	bl, AT_SELECT_SEGMENT
	
	je	afterUnselect			; YES:  do nothing
	call	SplineUnselectAll		; NO: unselect all current

afterUnselect:
	; Set the action type BEFORE calling ModifySelection so that when
	; ModifySelection calls DrawSelectedPoints, it draws in "segment"
	; mode. 
	mov	bl, AT_SELECT_SEGMENT
	call	SplineMakeActionPoint		; make it the action point
	call	SplineModifySelection		; Now, add (?) seg to sel list

	.leave
	ret
SplineSelectSegmentAdvancedEdit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectSegmentBeginnerEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subdivide the current curve, select the new point, and
		make it the action point

CALLED BY:

PASS:		ax - anchor point
		*ds:si - points array 
		es:bp - VisSplineInstance data 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectSegmentBeginnerEdit	proc	near
		uses	ax,di
		.enter

		call	SplineClosestPointOnCurve

	;
	; If the subdivision parameter is very close to zero or one,
	; then just select the anchor or the next anchor.
	;
		jcxz	selectAnchor
		cmp	cx, 0xffa0
		ja	selectNextAnchor
		
		call	SplineSubdivideOnParam

		call	SplineGotoNextAnchorFar
		mov	bl, AT_SELECT_ANCHOR
		call	SplineMakeActionPoint

done:
		.leave
		ret

selectAnchor:
		call	SplineSelectAnchorInternal
		jmp	done

selectNextAnchor:
		call	SplineGotoNextAnchorFar
		call	SplineSelectAnchorInternal
		jmp	done
SplineSelectSegmentBeginnerEdit	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineMakeActionPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make (ax) the action point

CALLED BY:	internal

PASS:		es:bp - VisSplineInstance data
		ax - point number
		bl - action type

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
SplineMakeActionPoint	proc	far
	uses	di
	class	VisSplineClass
	.enter
	
	ECCheckEtype	bl, ActionType

	SetEtypeInRecord bl, SES_ACTION, es:[bp].VSI_editState

	mov	es:[bp].VSI_actionPoint, ax
	.leave
	ret
SplineMakeActionPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineModifySelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify the selection of the current point based on the
		mouse flags.  Also, check to see if switching from
		AT_SELECT_ANCHOR (or AT_SELECT_CONTROL) to
		AT_SELECT_SEGMENT or vice versa.

CALLED BY:	internal

PASS:		ax - current anchor point #
		*ds:si - ChunkArray of points
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Assume the SD_mouseFlags contains valid data

	if UIFA_EXTEND is set, add point to sel. list
	if UIFA_ADJUST is set, toggle selection of point
	OTHERWISE:  make point the EXCLUSIVE selected point

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineModifySelection	proc	near
	uses	ax, bx
	class	VisSplineClass
	.enter
EC <	call	ECSplineAnchorPoint		> 
EC <	call	ECSplineInstanceAndPoints	>

	; get the mouse flag information
	
	SplineDerefScratchChunk	di
	mov	bx, ds:[di].SD_mouseFlags	

	; point ds:di to the point's data
	call	ChunkArrayElementToPtr

	; if UIFA_ADJUST, then toggle selection of current point
	test	bh, mask UIFA_ADJUST 	
	jz	afterToggle

	; If point is selected, un-select it.  Otherwise, add it to selection list.
	test	ds:[di].SPS_info, mask APIF_SELECTED
	jz	addSelect
	call	SplineUnselectPoint
	jmp	drawSelected

afterToggle:
	; if UIFA_EXTEND, then add to selection list
	test	bh, mask UIFA_EXTEND		; Add to selection?
	jnz	addSelect			; YES: add

	; if none of the above, then:  
	;  if point is already selected, do nothing
	;  else, make it the exclusive selected point.
	test	ds:[di].SPS_info, mask APIF_SELECTED
	jnz	done

	call	SplineUnselectAll		; NO: make exclusive

addSelect:
	call	SplineSelectPointFar

drawSelected:	
	call	SplineDrawSelectedPoints
done:
	.leave
	ret
SplineModifySelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUnselectPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go thru the selected list until the point (ax) is found,
		and delete it from the list.  Reset the SELECTED bit
		in the point's info record.

CALLED BY:	SplineModifySelection

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		ax - point number

RETURN:		nil, nada, zip

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		It is an error to call this routine with a point
		that's not selected.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUnselectPoint	proc near 	uses	ax,bx,cx,dx,di,si
	class	VisSplineClass
	.enter

EC <	call	ECSplineInstanceAndPoints	>
EC <	call	ECSplineAnchorPoint		> 

	; reset the selected bit
	call	ChunkArrayElementToPtr

	BitClr	ds:[di].SPS_info, APIF_SELECTED

	call	SplineSetInvertModeFar

	GetMode	bl
	cmp	bl, SM_ADVANCED_CREATE
	jbe	createModes

	; erase the point's filled handle (and neighboring controls)

	movHL	bx, <mask SDF_FILLED_HANDLES or mask SDF_CONTROL_LINES>,\
			<SOT_ERASE>
	mov	dx, SWP_ALL
	call	SplineOperateOnCurrentPointFar 
	
	; Draw hollow anchor handle for this point

	movHL	bx, <mask SDF_HOLLOW_HANDLES>, <SOT_DRAW> 
drawAnchor:
	mov	dx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnCurrentPointFar 

afterDraw:
	; Now, delete the point from the selected list

	mov	si, es:[bp].VSI_selectedPoints
	mov_tr	bx, ax				; bx = anchor #
	clr	ax				; ax = sel. list elt #
startLoop:
	call	ChunkArrayElementToPtr
	; If this dies here, it probably means that the point wasn't
	; selected to begin with.

EC <	ERROR_C CORRUPT_SELECTED_POINTS_LIST		>

	inc	ax				; point to next elt before cmp
	cmp	ds:[di].SLE_pointNum, bx
EC <	ERROR_L	CORRUPT_SELECTED_POINTS_LIST		>
	jg	startLoop

	; The point was found, so delete it
	call	ChunkArrayDelete
	.leave
	ret

	; When unselecting a point in create mode, erase its hollow
	; handle, unless it's the first point, which always keeps its
	; handle drawn.
createModes:
	mov_tr	bx, ax			; current point
	call	SplineGotoFirstAnchor
	xchg	ax, bx
	cmp	ax, bx
	je	afterDraw

	movHL	bx, <mask SDF_HOLLOW_HANDLES>, <SOT_ERASE>
	jmp	drawAnchor

SplineUnselectPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInsertInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the passed point number in the list, keeping
		list in HIGH-LOW order

CALLED BY:	SplineSelectPoint, SplineAddToNew

PASS:		ax - point number
		*ds:si - list (chunk array), either selected list or
		new points list

RETURN:		nothing (point is in list)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInsertInList	proc	far
	uses	ax,bx,di
	.enter

	mov	bx, ax			; point to insert is in bx
	clr	ax
startLoop:
	call	ChunkArrayElementToPtr	; get next element
	jc	appendIt		; not found? add to end of list
	cmp	ds:[di].SLE_pointNum, bx ; compare element with bx
	je	done			; already in list. do nothing
	jl	insertIt		; element is less than bx
	inc	ax			; go to next element
	jmp	startLoop		; repeat

appendIt:
	call	ChunkArrayAppend	; add to end
	jmp	storeIt
insertIt:	
	call	ChunkArrayInsertAt	; insert at current
storeIt:
	mov	ds:[di].SLE_pointNum, bx
done:
	.leave
	ret
SplineInsertInList	endp


	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineUnselectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unselect any selected anchor points -- erase 
		control point lines, then zero the array, reset the
		HAS_ACTION_POINT bit in spline Mode

CALLED BY:	SplineMakeSelectedExcl, etc

PASS:		es:bp - VisSplineInstance data

		*ds:si - points chunk array

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUnselectAll	proc	far
	uses	ax, bx, cx, si

	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints	>

	; Erase all control lines & filled handles

	call	SplineEraseSelectedPoints

	;
	; Draw hollow anchor handles around previously selected anchors
	;

	movHL	ax, <mask SDF_HOLLOW_HANDLES>, <SOT_DRAW> 
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	;
	; Clear the "selected" flags for each point
	;

	mov	al, SOT_MODIFY_INFO_FLAGS
	mov	cx, mask APIF_SELECTED
	call	SplineOperateOnSelectedPointsFar

	;
	; Now, zero out the selected array
	;

	mov	si, es:[bp].VSI_selectedPoints
	call	ChunkArrayZero	

	;	
	; Notify UI, etc.
	;

	ornf	es:[bp].VSI_editState, mask SES_SELECT_STATE_CHANGED

	.leave
	ret	
SplineUnselectAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineStartMoveCopy, MSG_META_START_MOVE_COPY
		End the current CREATE mode, go into EDIT mode.  If
		the mouse happens to be over the FIRST anchor point,
		then make the curve a CLOSED curve.

DESCRIPTION:	Handle the right-mouse button press

PASS:		*ds:si - VisSpline object
		ds:bx  -  "" ""
		ds:di  - VisSPline instance data
		cx - mouse x position
		dx - mouse y position
		bp - mouse flags

RETURN:		ax - MRF_PROCESSED

DESTROYED:	nothing

REGISTER/STACK USAGE:	al = SplineMode

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineStartMoveCopy	method 	dynamic VisSplineClass, 
						MSG_META_START_MOVE_COPY
	uses	cx, dx, bp
	.enter

	;
	; Only do something in create modes
	;

	call	SplineAreWeInCreateMode?
	jnc	done

	; Exit create mode.
	; If mouse is over first anchor, then close the curve.

	call	SplineCreateGState
	call	SplineMouseMethodCommon
	push	cx
	mov	cl, SM_INACTIVE
	mov	ax, MSG_SPLINE_SET_MODE
	call	SplineSendMyselfAMessage
	pop	cx

	call	SplineGotoFirstAnchor
	jc	afterClose

	call	SplinePointAtCXDXFar
	jnc	afterClose
	mov	ax, MSG_SPLINE_CLOSE_CURVE
	call	SplineSendMyselfAMessage
afterClose:
	call	SplineDestroyGState
	call	SplineEndmCommon
done:
	mov	ax, mask MRF_PROCESSED
	.leave
	ret
SplineStartMoveCopy	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBogusMouseMethod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set AX to MRF_PROCESSED to keep the system from crashing.

PASS:		*DS:SI	= VisSplineClass instance data.
		DS:DI	= *DS:SI.
		ES	= Segment of VisSplineClass.
		AX	= Method.

RETURN:		AX - mask MRF_PROCESSED

DESTROYED:	Nada.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/29/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineBogusMouseMethod	method	dynamic	VisSplineClass, MSG_META_END_MOVE_COPY
	mov	ax, mask MRF_PROCESSED
	ret
SplineBogusMouseMethod	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAreWeInCreateMode?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether we're in one of the create modes

CALLED BY:	SplineStartMoveCopy

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
SplineAreWeInCreateMode?	proc near
	uses	ax
	class	VisSplineClass
	.enter
	GetEtypeFromRecord	al, SS_MODE, es:[bp].VSI_state 
	cmp	al, SM_BEGINNER_POLYLINE_CREATE
	je	yes
	cmp	al, SM_BEGINNER_SPLINE_CREATE
	je	yes
	cmp	al, SM_ADVANCED_CREATE
	clc
	jne	done
yes:
	stc
done:
	.leave
	ret
SplineAreWeInCreateMode?	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	select all spline points	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSelectAll	method	dynamic	VisSplineClass, 
					MSG_META_SELECT_ALL
	.enter
	call	SplineMethodCommon

	call	SplineUnselectAll

	movL	ax, <SOT_SELECT_POINT>
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnAllPoints

	call	SplineDrawSelectedPoints

	call	SplineEndmCommon 
	.leave
	ret
SplineSelectAll	endm


SplineSelectCode	ends
