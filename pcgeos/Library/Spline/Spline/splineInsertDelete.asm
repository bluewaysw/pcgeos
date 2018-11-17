COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineInsertDelete.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/31/92   	Initial version.

DESCRIPTION:
	

	$Id: splineInsertDelete.asm,v 1.1 97/04/07 11:09:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineUtilCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMetaDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Delete selected points

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineMetaDelete	method	dynamic	VisSplineClass, 
					MSG_META_DELETE
	mov	ax, MSG_SPLINE_DELETE_ANCHORS
	GOTO	ObjCallInstanceNoLock
SplineMetaDelete	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDeleteRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Delete a range of points

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		cx 	- first anchor to delete
		dx 	- last anchor to delete

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/31/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineDeleteRange	method	dynamic	VisSplineClass, 
					MSG_SPLINE_DELETE_RANGE
	uses	ax,cx,dx,bp

	.enter

	call	SplineMethodCommon 
	SplineDerefScratchChunk	di
	mov	ds:[di].SD_firstPoint, cx
	mov	ds:[di].SD_lastPoint, dx

	; Delete controls first

	mov	al, SOT_DELETE
	mov	bx, SWP_CONTROLS
	call	SplineOperateOnRange

	; Delete anchors

	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnRange

	;
	; Recalc size (if not suspended)
	;
	mov	ax, MSG_VIS_RECALC_SIZE
	call	SplineSendMyselfAMessage

	call	UpdateUIForInsertOrDelete

	call	SplineEndmCommon 
	.leave
	ret
SplineDeleteRange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateUIForInsertOrDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI if we're inserting/deleting points,
		unless the object is inactive

CALLED BY:	SplineDeleteRange, SplineInsertAnchors,
		SplineInsertControls, SplineDeleteAnchors, 
		SplineDeleteControls

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateUIForInsertOrDelete	proc	near

	class	VisSplineClass
	;
	; Don't bother if we're in inactive mode.  
	;

	GetEtypeFromRecord	cl, SS_MODE, es:[bp].VSI_state
	cmp	cl, SM_INACTIVE
	je	done

	mov	cx, mask SGNF_SPLINE_POINT or mask SGNF_POLYLINE or \
			mask SGNF_SMOOTHNESS or mask SGNF_EDIT
	call	SplineUpdateUI
done:
	ret
UpdateUIForInsertOrDelete	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineInsertAnchors

DESCRIPTION:	Insert anchor points in the middles of all
			of the selected SEGMENTS

PASS:		*ds:si - VisSpline object
		ds:bx - " "" 
		ds:di - VisSpline instance data

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInsertAnchors	method dynamic VisSplineClass, \
						MSG_SPLINE_INSERT_ANCHORS
	uses	ax, cx, dx, bp
	.enter

	; create gstate, lock block, create scratch chunk

	call	SplineCreateGState
	call	SplineMethodCommon

	; prepare undo data structures

	mov	ax, UT_INSERT_ANCHORS
	call	SplineInitUndo

	; Erase currently selected points.

	call	SplineEraseSelectedPoints

	;
	; copy the NEXT and NEXT_FAR control of every selected anchor
	; to the UNDO array, as we'll want to restore their positions
	; if the user UNDOES
	;

	mov	al, SOT_COPY_TO_UNDO
	mov	bx, mask SWPF_NEXT_CONTROL or mask SWPF_NEXT_FAR_CONTROL
	call	SplineOperateOnSelectedPointsFar

	; do a midpoint subdivision

	SplineDerefScratchChunk di
	mov	ds:[di].SD_subdivideParam, 8000h
	mov	al, SOT_SUBDIVIDE_CURVE
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	; Put every selected point's NEXT anchor in the NEW list

	mov	al, SOT_ADD_TO_NEW
	mov	bx, mask SWPF_NEXT_ANCHOR
	call	SplineOperateOnSelectedPointsFar

	; Unselect everything

	call	SplineUnselectAll	

	; change action type to AT_SELECT_ANCHOR

	SetEtypeInRecord AT_SELECT_ANCHOR, SES_ACTION, es:[bp].VSI_editState

	; Make the NEW POINTS  selected 

	mov	al, SOT_SELECT_POINT
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnNewPoints


	; draw selected stuff

	call	SplineDrawSelectedPoints

	call	UpdateUIForInsertOrDelete

	call	SplineDestroyGState
	call	SplineEndmCommon 
	.leave
	ret
SplineInsertAnchors	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineDeleteAnchors, MSG_SPLINE_DELETE_ANCHORS

DESCRIPTION:	delete all the selected anchors

PASS:		*ds:si - VisSpline object
		ds:bx  -  "" ""
		ds:di  - VisSPline instance data

RETURN:		nothing

DESTROYED:	cx

PSEUDO CODE/STRATEGY:	
	UNDOABLE operation
	Copies each anchor and control to the UNDO list
	Copies the PREVIOUS anchor of each selected anchor to the NEW
	list 

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDeleteAnchors method	dynamic	VisSplineClass, 
						MSG_SPLINE_DELETE_ANCHORS
	uses	ax
	.enter
	call	SplineCreateGState
	call	SplineMethodCommon

	call	SplineEraseSelectedPoints

	;
	; When deleting in create mode, erase the mouse thingy
	;

	call	SplineDrawFromLastAnchorToMouse

	mov	ax, UT_DELETE_ANCHORS
	call	SplineInitUndo


	;
	; Copy each selected anchor to the UNDO list.  Controls will
	; be copied by DeleteControlsLow
	;

	mov	ax, SOT_COPY_TO_UNDO
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	;
	; Copy the PREV anchor of every selected anchor to the NEW list.  This
	; list will be used to inval the proper areas after the delete, and
	; also in the case of an UNDO event.
	;

	mov	al, SOT_ADD_TO_NEW
	mov	bx, mask SWPF_PREV_ANCHOR
	call	SplineOperateOnSelectedPointsFar

	; Delete controls

	call	DeleteControlsLow

	; Now, delete anchors

	mov	al, SOT_DELETE
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	; Now, copy the NEW list to the SELECTED list.  No need to UNSELECT
	; first, since all selected points have just been deleted (and removed
	; themselves from the selected list, if they're being good!)

	mov	al, SOT_SELECT_POINT
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnNewPoints

	;
	; Invalidate the selected points.
	;
	
	movL	ax, SOT_INVALIDATE
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	; Now, draw filled handles, etc for selected points

	call	SplineDrawSelectedPoints

	call	SplineDrawFromLastAnchorToMouse

	call	SplineRecalcVisBounds
	call	UpdateUIForInsertOrDelete
	call	SplineEndmCommon 
	.leave
	ret

SplineDeleteAnchors	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineDeleteControls, MSG_SPLINE_DELETE_CONTROLS

DESCRIPTION:	Delete all control points from all of the selected
		anchor points

PASS:		*ds:si - VisSpline object
		ds:bx  -  "" ""
		ds:di  - VisSPline instance data

RETURN:		nothing

DESTROYED:	nothing 

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDeleteControls  method dynamic VisSplineClass, 
					MSG_SPLINE_DELETE_CONTROLS
	uses	ax,cx,dx,bp
	.enter

	call	SplineCreateGState
	call	SplineMethodCommon

	mov	ax, UT_DELETE_CONTROLS
	call	SplineInitUndo

	call	DeleteControlsLow

	call	SplineRecalcVisBounds
	call	UpdateUIForInsertOrDelete
	call	SplineEndmCommon 
	.leave
	ret
SplineDeleteControls	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteControlsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to delete control points from
		selected anchors.

CALLED BY:

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteControlsLow	proc near
	.enter

	; Invalidate selected points

	movL	ax, SOT_INVALIDATE
	mov	bx, SWP_BOTH_CURVES
	call	SplineOperateOnSelectedPointsFar

	; Copy points to UNDO before deleting

	mov	al, SOT_COPY_TO_UNDO
	mov	bx, SWP_CONTROLS
	call	SplineOperateOnSelectedPointsFar

	mov	al, SOT_DELETE
	mov	bx, SWP_CONTROLS
	call	SplineOperateOnSelectedPointsFar

	.leave
	ret
DeleteControlsLow	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInsertControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Add control points to all of the selected anchor points.

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.

RETURN:		nothing

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

	CDB	6/19/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineInsertControls	method	dynamic	VisSplineClass, 
					MSG_SPLINE_INSERT_CONTROLS
	uses	ax,cx,dx,bp
	.enter

	; Create gstate, etc.

	call	SplineCreateGState
	call	SplineMethodCommon

	;
	; Invalidate both curves around the selected point(s)
	;

	movL	ax, SOT_INVALIDATE
	mov	bx, SWP_BOTH_CURVES
	call	SplineOperateOnSelectedPointsFar

	;
	; Add controls
	;

	mov	al, SOT_ADD_CONTROLS_CONFORM
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	;
	; Place the controls in a manner pleasing to the eye
	;

	mov	al, SOT_UPDATE_AUTO_SMOOTH_CONTROLS
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	;
	; Intialize the UNDO array
	;
	mov	ax, UT_INSERT_CONTROLS
	call	SplineInitUndo

	;
	; Copy the selected points array to the NEW POINTS array
	;

	call	SplineCopySelectedToNew

	;
	; Do another INVAL, since the new curves may fall outside the bounding
	; rectangles of the old curves.
	;

	movL	ax, SOT_INVALIDATE
	mov	bx, SWP_BOTH_CURVES
	call	SplineOperateOnSelectedPointsFar

	;
	; Redraw selections to account for new control points, etc.
	;

	call	SplineDrawSelectedPoints

	call	SplineRecalcVisBounds

	;
	; clean-up and exit.
	;

	call	UpdateUIForInsertOrDelete
	call	SplineDestroyGState
	call	SplineEndmCommon
	.leave
	ret
SplineInsertControls	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInsertAllControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Insert controls along EVERY spline point -- don't
		position them anywhere

PASS:		*DS:SI	= VisSplineClass object
		DS:DI	= VisSplineClass instance data
		ES	= Segment of VisSplineClass.
		AX	= message

RETURN:		

DESTROYED:	Nada.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineInsertAllControls	method	dynamic	VisSplineClass, 
					MSG_SPLINE_INSERT_ALL_CONTROLS
	uses	ax,bp

	.enter
	call	SplineMethodCommon
	mov	al, SOT_ADD_PREV_CONTROL
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnAllPoints

	mov	al, SOT_ADD_NEXT_CONTROL
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnAllPoints

	call	SplineEndmCommon
	.leave
	ret
SplineInsertAllControls	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRemoveExtraControlPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Remove any control points that are close enough to
		their anchors to be considered "redundant"

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		cx 	= tolerance value

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineRemoveExtraControlPoints	method	dynamic	VisSplineClass, 
				MSG_SPLINE_REMOVE_EXTRA_CONTROL_POINTS
	uses	ax,cx,dx,bp
	.enter
	call	SplineMethodCommon 
	call	SplineInvalidate
	mov	al, SOT_REMOVE_EXTRA_CONTROLS
	mov	bx, mask SWPF_PREV_CONTROL or \
			mask SWPF_NEXT_CONTROL
	call	SplineOperateOnAllPoints
	call	SplineEndmCommon 

	.leave
	ret
SplineRemoveExtraControlPoints	endm

SplineUtilCode	ends


SplineOperateCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInsertPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a spline point into the array -- also update the 
		selected list, action point, and SD_anchor.

CALLED BY:	internal

PASS:		ax - current point number.  If ax is beyond end of list,
			then add a new point.
		bl - SPS_info data (PointInfoFlags)
		cx - x-position
		dx - y-position
		*ds:si - chunk array of points
		es:bp - VisSplineInstance data

RETURN:		carry clear if point inserted,
			ds:di - point address
		carry set otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Only sets integer coordinates.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInsertPoint	proc	near
	uses	cx

	class	VisSplineClass

	.enter

 EC <	call	ECSplineInstanceAndPoints	>

	push	cx
	mov	cx, 1
	call	SplineCheckToAddPoints
	pop	cx
	jc	done

	call	ChunkArrayElementToPtr
	jc	append
	call	ChunkArrayInsertAt

loadData:
	StorePointAsInt	ds:[di].SPS_point, cx, dx
	mov	ds:[di].SPS_info, bl
	;
	; Now, fixup all the lists with the new point
	;
	push	dx
	mov	dx, 1
	call	SplineFixupReferences
	pop	dx
	clc
done:
	.leave
	ret

append:	
	call	ChunkArrayAppend	; NO, add to end of list
	jmp	loadData

SplineInsertPoint	endp

SplineInsertPointFar	proc far
	call	SplineInsertPoint
	ret
SplineInsertPointFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAddPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a point to the end of the points array

CALLED BY:	internal

PASS:		cx = x coordinate
		dx = y
		bl = PointInfoFlags
		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		If point added:
			carry clear,
			ax = point #
			ds:di - point address
		ELSE
			carry set,
			ax unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddPoint	proc	near
	uses	cx
	.enter
EC < 	call	ECSplineInstanceAndPoints	>

	push	cx
	mov	cx, 1
	call	SplineCheckToAddPoints
	pop	cx
	jc	done

	call	ChunkArrayAppend
	StorePointAsInt	ds:[di].SPS_point, cx, dx
	mov	ds:[di].SPS_info, bl
	call	ChunkArrayPtrToElement
	clc
done:
	.leave
	ret
SplineAddPoint	endp


SplineAddPointFar	proc	far
	call	SplineAddPoint
	ret
SplineAddPointFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAddAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Unselect the currently selected points,
		Add an anchor point to the end of the array, and make it
		the selected and action point.
		Also check to see if new point is outside vis bounds,
		and if so, send an update-vis-bounds message


CALLED BY:	SplineSSCreateModeCommon

PASS:		*ds:si - points Chunk array
		es:bp - VisSplineInstance data

		cx - x -coordinate
		dx - y -coordinate

RETURN:		If point added:
			carry clear
			ax = point #
		else:
			carry set
			ax = unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddAnchor	proc	far
	uses	bx, dx
	class	VisSplineClass 
	.enter
EC <	call	ECSplineInstanceAndPoints		>

	call	SplineMakeTempCopyOfVisBounds

	;
	; In Beginner Spline create mode, set smoothness to AUTO
	; smooth. 
	;

	GetEtypeFromRecord	al, SS_MODE, es:[bp].VSI_state
	cmp	al, SM_BEGINNER_SPLINE_CREATE
	mov	bx, ST_AUTO_SMOOTH
	je	gotSmoothness
	mov	bx, ST_VERY_SMOOTH
gotSmoothness:
	call	SplineAddPoint		; returns point # in ax
	jc	done

	mov	bl, AT_SELECT_ANCHOR
	call	SplineMakeActionPoint

	mov	bx, SOT_ADD_TO_BOUNDING_BOX	; clear BH
	mov	dx, mask SWPF_ANCHOR_POINT
	mov	cl, es:[bp].VSI_handleSize.BBF_int
	clr	ch

	call	SplineOperateOnCurrentPointFar

	call	SplineDetermineIfTempVisBoundsChanged
	clc
done:
	.leave
	ret
SplineAddAnchor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineDeletePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the current point.  Also fixup the selection
		list, action point, and SD_anchor

CALLED BY:	SplineCheckToDeleteControlPoints, 
		SplineDeleteSelectedControlsCB

PASS:		*ds:si - points list
		es:bp - VisSplineInstance data		
		ax - point number

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDeletePoint	proc	near
	uses	dx, di
	.enter
EC <	call	ECSplineInstanceAndPoints		>
	call	ChunkArrayElementToPtr	; deref element
	call	ChunkArrayDelete	; delete it
	mov	dx, -1			; decrement count
	call	SplineFixupReferences
	.leave
	ret
SplineDeletePoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineFixupReferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup all references to point numbers

CALLED BY:	UTILITY

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array
		dx = amount to change point numbers by
		(+1 or -1, most likely)

		ax - point to compare points against

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Fixup - lists
		action point
		anchor point in Scratch Data
		firstPoint (SD)
		lastPoint (SD)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	*** THIS PROCEDURE MUST NOT INSERT OR DELETE ANY MEMORY IN THE
	POINTS BLOCK ***

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/31/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineFixupReferences	proc near
	uses	ax,bx,cx,dx,di,si
	class	VisSplineClass 
	.enter

EC <	call	ECSplineInstanceAndLMemBlock	> 

	; Fixup  selected list
	
	mov	si, es:[bp].VSI_selectedPoints
	mov	bx, cs
	mov	di, offset SplineFixupListCB
	call	ChunkArrayEnum

	; fixup new points list

	mov	si, es:[bp].VSI_newPoints
	tst	si
	jz	afterNew
	mov	di, offset	SplineFixupListCB
	mov	bx, cs
	call	ChunkArrayEnum

afterNew:

	segxchg	ds, es
	lea	di, ds:[bp].VSI_actionPoint
	call	FixupPointCheckDelete
	segxchg	ds, es

	SplineDerefScratchChunk si
	lea	di, ds:[si].SD_anchor
	call	FixupPointCheckDelete

	lea	di, ds:[si].SD_firstPoint
	call	FixupPoint
	lea	di, ds:[si].SD_lastPoint
	call	FixupPoint

	.leave
	ret
SplineFixupReferences	endp

		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineFixupListCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current list is either:
		- selected points or new points

		In any case, assume the word at ds:di is a point
		number.

		If pointNum >= AX, and DX > 0
			Add DX to pointNum

		If pointNum = AX and DX < 0
			Delete the current list entry

		If pointNum < AX
			do nothing, end enumeration

CALLED BY:	internal

PASS:		ax - point number to compare against
		dx - value to add (+1 or -1)
		*ds:si - list
		ds:di - current entry of list

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:
	Since both lists are decreasing, stop when pointNum < AX

KNOWN BUGS/SIDE EFFECTS/IDEAS: 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineFixupListCB	proc	far
	.enter
	
	cmp	ds:[di].SLE_pointNum, ax	; compare point # with AX
	jl	done				; LESS, end (carry
						; flag set)
	jg	addIt
	tst	dx
	js	deleteCurrent
addIt:
	add	ds:[di].SLE_pointNum, dx	; GREATER, fixup element number
	clc					; clear carry set by 
						; negative adds! 
done:
	.leave
	ret

deleteCurrent:
	call	ChunkArrayDelete
	stc				; end enumeration
	jmp	done

SplineFixupListCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup a point number at ds:di

CALLED BY:

PASS:		ds:di - address of point to fix up
		ax - point to compare against
		dx - amount to add/subtract

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	If the point # at ds:di is less or equal to AX, then leave it
	the same.  This operation should NOT be performed on values
	that have to reference a REAL point number (such as the action
	point, etc) -- it's used for updating the FIRST/LAST point
	numbers. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/31/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixupPoint	proc near
	.enter

	cmp	ds:[di], ax		; is new point > action point #
	jle	done
	add	ds:[di], dx
done:
	.leave
	ret

FixupPoint	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupPointCheckDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup the point number.  If a deletion occurred, then
		move an illegal point number into the location

CALLED BY:

PASS:		ds:di - address of point to fix up
		ax - point to compare against
		dx - amount to add/subtract

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixupPointCheckDelete	proc near

	.enter

	cmp	ds:[di], ax		; is new point > action point #
	jl	done
	je	checkDelete
addIt:
	add	ds:[di], dx
done:
	.leave
	ret

checkDelete:

	; If DX is positive, then increment current point.  If DX is
	; negative, then the current point was probably deleted, so
	; stick a goofy value in ds:di

	tst	dx
	jns	addIt
	mov	{word} ds:[di], SPLINE_MAX_POINT+1
	jmp	done

FixupPointCheckDelete	endp


SplineOperateCode	ends



