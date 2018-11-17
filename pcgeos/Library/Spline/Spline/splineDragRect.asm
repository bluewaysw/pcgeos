COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VisSpline edit object
FILE:		splineDragRect.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

DESCRIPTION:	This file implements drag-selection for the spline object

ROUTINES:
	SplineDeterminePointRectangleRelation
	SplineDragRectInside
	SplineDragRectInsideAdjust
	SplineDragRectOutside
	SplineDrawDragRect
	SplineDrawPointForDragRect
	SplinePointInDragRectangle?
	SplineRedrawDragRect
	SplineSelectAnchorIfHandleFilled
	

	$Id: splineDragRect.asm,v 1.1 97/04/07 11:09:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineSelectCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDSDragRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	 When dragging open a rectangle, if neither the UIFA_EXTEND nor
	 the UIFA_ADJUST flags are set, then unselect all the selected points.
	 Also draw the drag rectangle at it's beginning size.

CALLED BY:	SplineDSEditModes

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		al - ButtonInfo
		ah - UIFunctionsActive

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/25/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDSDragRectangle	proc near 	uses cx,dx,si
	class	VisSplineClass	
	.enter

	; If user was selecting segments, unselect them before starting
	; rectangle operation.

	GetActionType al
	cmp	al, AT_SELECT_SEGMENT
	jne	afterUnselect

	call	SplineUnselectAll

afterUnselect:

	;
	; Draw the first incarnation of the drag rectangle.
	;

	SplineDerefScratchChunk si
	movP	cxdx, ds:[si].SD_mouse
	call	SplineDrawDragRect
	.leave
	ret
SplineDSDragRectangle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineESDragRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the drag rectangle and draw selected points

CALLED BY:	SplineEndSelect

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineESDragRectangle	proc near 	uses ax,bx,si
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints		> 

; Erase the rectangle

	SplineDerefScratchChunk si
	movP	cxdx, ds:[si].SD_mouse
	call	SplineDrawDragRect

; Do other stuff (call to far proc, no GOTO)

	call	SplineEndDragRectCommon
	.leave
	ret
SplineESDragRectangle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndDragRectCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a drag-rectangle operation.  

CALLED BY:	SplineESDragRectangle, SplineEndSelectRectangle

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 

RETURN:		nothing 

DESTROYED:	ax,bx,si

PSEUDO CODE/STRATEGY:	
	Erase all control lines/handles of selected points
	Nuke the selected array
	Select points that have filled anchor handles
	draw selected points

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/25/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndDragRectCommon	proc far
	class	VisSplineClass 
	.enter

; Erase all control lines/handles of (previously) selected points
	call	SplineSetInvertModeFar
	movHL	ax, <mask SDF_CONTROL_LINES or \
			mask SDF_FILLED_HANDLES>, <SOT_ERASE>
	mov	bx, SWP_ALL_CONTROLS
	call	SplineOperateOnSelectedPointsFar

; Zero out the selected array
	mov	si, es:[bp].VSI_selectedPoints
	call	ChunkArrayZero

; Now, select only those points that have filled anchor handles

	mov	al, SOT_SELECT_ANCHORS_WITH_FILLED_HANDLES
	mov	bx, mask SWPF_ANCHOR_POINT
	mov	si, es:[bp].VSI_points
	call	SplineOperateOnAllPoints

; Draw the newly selected points

	call	SplineDrawSelectedPoints

	.leave
	ret
SplineEndDragRectCommon	endp


SplineSelectCode	ends

SplinePtrCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplinePtrMoveRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move the drag rectangle on a ptr event

CALLED BY:	SplinePtr

PASS:		es:bp - vis spline instance
		*ds:si - points
		ax - mouse flags
		cx, dx - mouse deltas
	
RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePtrMoveRectangle	proc near
	.enter

	; erase the old rectangle and draw the new one.  Recalculate 
	; which points are selected

	call	SplineRedrawDragRect

	mov_tr	cx, ax			; mouse flags

	mov	al, SOT_DRAW_FOR_SELECTION_RECTANGLE
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnAllPoints
	.leave
	ret
SplinePtrMoveRectangle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawPointForDragRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the current point based on whether or not
		it's in the drag-selection rectangle	

CALLED BY:	SplineOperateOnPointCommon

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array
		ax - current anchor point
		ch - UIFunctionsActive

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	
	Certain UI functions are tracked here:  UIFA_ADJUST
	(control-key) and UIFA_EXTEND (shift-key).  

	If the point is INSIDE the rectangle:

		If UIFA_ADJUST is set:

			Draw point the OPPOSITE of its selection bit

		if UIFA_EXTEND is set:
		
			draw point as SELECTED

		if neither flag is set:

			draw point as SELECTED

	If the point is OUTSIDE the rectangle:

		Draw point the way its selection bit is set 


KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawPointForDragRect	proc near

	class	VisSplineClass
	.enter

EC <	call	ECSplineAnchorPoint		> 

	call	SplinePointInDragRectangle?
	jc	inside

	;
	; It's outside: FILLED = SELECTED 
	;

	test	ds:[di].SPS_info, mask APIF_SELECTED
	jnz	filled

hollow:
	call	SplineDrawHollowHandle
	jmp	done

inside:

	;
	; If INSIDE and NOT ADJUST, then FILLED
	;

	test	ch, mask UIFA_ADJUST
	jz	filled

	;
	; Inside, adjust (toggle):  FILLED = OPPOSITE OF SELECTED
	;

	test	ds:[di].SPS_info, mask APIF_SELECTED
	jnz	hollow
filled:
	mov	bh, mask SDF_FILLED_HANDLES
	call	SplineDrawFilledHandle
done:
	.leave
	ret

SplineDrawPointForDragRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplinePointInDragRectangle?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current spline point is inside or outside
		the drag rectangle. 

CALLED BY:	

PASS:		es:bp - VisSplineInstance data 
		ax - current spline point
		*ds:si - spline points array

RETURN:		carry SET if inside
		ds:di - current point

DESTROYED:	ax, bx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplinePointInDragRectangle?	proc near

	uses	si, cx

	class	VisSplineClass
	.enter

	;
	; Use the lightning-quick element-to-ptr macro, 'cause we have
	; the need for speed in this routine. 
	;

	CAElementToPtr	ds, si, ax, bx, TRASH_AX_DX
	push	bx

	LoadPointAsInt	si, di, ds:[bx].SPS_point


	SplineDerefScratchChunk bx
	movP	cxdx, ds:[bx].SD_startRect

	mov	ax, ds:[bx].SD_mouse.P_x
	mov	bx, ds:[bx].SD_mouse.P_y
	
	; Make sure AX < CX and BX < DX

	SortRegs	ax, cx
	SortRegs	bx, dx

	call	SplinePointInRectangleLow?
	pop	di			; ds:di - point

	.leave
	ret
SplinePointInDragRectangle?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRedrawDragRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the old drag rectangle and draw the new one.

CALLED BY:	SplinePtrDragRect

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing

DESTROYED:	bx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/10/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRedrawDragRect	proc far

	uses	cx

	class	VisSplineClass

	.enter

EC <	call	ECSplineInstanceAndLMemBlock	>

	SplineDerefScratchChunk bx

; Erase old
	movP	cxdx, ds:[bx].SD_lastMouse
	call	SplineDrawDragRect
	
; Draw new
	movP	cxdx, ds:[bx].SD_mouse
	call	SplineDrawDragRect
	.leave
	ret
SplineRedrawDragRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawDragRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a "selection" rectangle based on data in 
		the ScratchData chunk.

CALLED BY:	SplineRedrawDragRect

PASS:		es:bp - VisSplineInstance data
		cx, dx - one corner of the rectangle (other corner
		is SD_startRect)

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawDragRect	proc far	

	uses ax,bx,si,di

	class	VisSplineClass
	.enter

EC <	call	ECSplineInstanceAndLMemBlock	> 

	mov	di, es:[bp].VSI_gstate

	push	dx
	clr	ax, dx			; zero line width
	call	GrSetLineWidth
	pop	dx

	mov	ax, MM_INVERT
	call	GrSetMixMode
	
	mov	al, LS_DOTTED
	clr	bl
	call	GrSetLineStyle

	
	SplineDerefScratchChunk si
	movP	axbx, ds:[si].SD_startRect

	call	GrDrawRect

	.leave
	ret
SplineDrawDragRect	endp

SplinePtrCode	ends


SplineOperateCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectAnchorIfHandleFilled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the current anchor point if it has its "filled
		handle" bit set.

CALLED BY:	SplineOperate...

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		ax - current anchor point

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

	This procedure doesn't make any DRAW calls

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectAnchorIfHandleFilled	proc near 

EC <	call	ECSplineAnchorPoint		>

	call	ChunkArrayElementToPtr
	test	ds:[di].SPS_info, mask PIF_FILLED_HANDLE
	jz	unSelect
	GOTO	SplineSelectPoint

unSelect:
	BitClr	ds:[di].SPS_info, APIF_SELECTED
	ret
SplineSelectAnchorIfHandleFilled	endp

SplineOperateCode	ends






