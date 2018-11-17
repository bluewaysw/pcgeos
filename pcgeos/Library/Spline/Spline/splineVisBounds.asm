COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VisSpline object	
FILE:		splineVisBounds.asm

AUTHOR:		Chris Boyke

ROUTINES:
	SplineCheckPointAgainstVisBounds	
	SplineCompareVisBoundsWithTemp
	SplineDetermineIfTempVisBoundsChanged
	SplineMakeTempCopyOfVisBounds
	SplineRequestVisBoundsChangeToTemp
	SplineTranslateCoordinatesByVisBounds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/26/91		Initial version.

DESCRIPTION:
	Routines to deal with those pesky vis bounds.
	

	$Id: splineVisBounds.asm,v 1.1 97/04/07 11:08:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineUtilCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Recalculate the size of the spline object, sending
		myself a resize message, if necessary

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		ax	= Method.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	If we're in suspended animation, then just set a bit, and do
	it later.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineRecalcSize	method	dynamic	VisSplineClass, MSG_VIS_RECALC_SIZE
	.enter
	mov	di, offset VisSplineClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisSpline_offset

	tst	ds:[di].VSI_suspendCount
	jnz	suspended

	call	SplineMethodCommon
	call	SplineRecalcVisBounds
	call	SplineEndmCommon
done:
	.leave
	ret

suspended:
	ornf	ds:[di].VSI_unSuspendFlags, mask SUSF_GEOMETRY
	jmp	done

SplineRecalcSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawVisBoundaryLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the visual boundary of the VisSpline object in
		invert-mode using dotted lines.

CALLED BY:	SplineDrawEverythingElse,
		SplineSetVisBoundaryDrawn,
		SplineEraseVisBoundary

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	
	Only draw if the VIS_BOUNDARY_DRAWN bit is set in the
	VSI_state field.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawVisBoundaryLow	proc	far
	uses	ax,bx,cx,dx,ds,di,si
	class	VisSplineClass
	.enter

	test	es:[bp].VSI_state, mask SS_VIS_BOUNDARY_DRAWN
	jz	done
	mov	di, es:[bp].VSI_gstate
	
	push	dx
	clr	ax, dx
	call	GrSetLineWidth
	pop	dx

	mov	al, MM_INVERT
	call	GrSetMixMode

	mov	al, LS_DOTTED
	clr	bl
	call	GrSetLineStyle

	; returns size in CX, DX
	SplineDerefScratchChunk si
	mov	si, ds:[si].SD_splineChunkHandle
	segmov	ds, es
	call	VisGetSize
	clr	ax
	clr	bx
	call	GrDrawRect
done:

	.leave
	ret
SplineDrawVisBoundaryLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Resize the VisSpline object, adjusting the coordinates
		of the points so that their screen  coordinates remain
		unchanged. 

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.

		ss:bp - Rectangle structure of new vis bounds.

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/24/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetVisBounds	method	dynamic	VisSplineClass, 
			 			MSG_SPLINE_SET_VIS_BOUNDS
	uses	ax,cx,dx,bp
	.enter

	; Erase the old visual bounds rectangle (if drawn)
	call	SplineDrawVisBoundary

	; Store the right and bottom corners of the new vis bounds
	; BX will point to the VIS-level instance data

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	MemMov	ds:[bx].VI_bounds.R_right, ss:[bp].R_right, ax
	MemMov	ds:[bx].VI_bounds.R_bottom, ss:[bp].R_bottom, ax

	; Store the top and left coordinates and also determine the
	; amount of change in each direction.
	mov	ax, ss:[bp].R_left		; new left
	mov	cx, ax			
	xchg	cx, ds:[bx].VI_bounds.R_left	; store new, get old
	sub	cx, ax				; sub (old-new)

	mov	ax, ss:[bp].R_top		; get new top
	mov	dx, ax
	xchg	dx, ds:[bx].VI_bounds.R_top	; store new, get old top
	sub	dx, ax				; sub (old-new)

	; If there was any change to the top or right bounds, then
	; re-translate the gstate, and add this change to every point (to keep
	; points fixed on the screen).

	mov	bx, cx
	or	bx, dx
	jz	redrawVisBoundary


	tst	ds:[di].VSI_gstateRefCount
	jz	redrawVisBoundary

	push	cx, dx, di
	mov	bx, dx			; get y-translation (bx.ax)
	neg	bx
	clr	ax

	mov	dx, cx			; x-translation (dx.cx)
	neg	dx
	clr	cx

	mov	di, ds:[di].VSI_gstate
	call	GrApplyTranslation
	pop	cx, dx, di		; restore x, y

redrawVisBoundary:
	call	SplineDrawVisBoundary
	mov	bx, cx
	or	bx, dx
	jz	done

	; lock points block, etc.
	call	SplineMethodCommon

	; Add amounts in cx, dx to the mouse.  Also, store cx, dx to "deltas"
	SplineDerefScratchChunk	bx
	addP	ds:[bx].SD_mouse, cxdx
	movP	ds:[bx].SD_deltas, cxdx

	;Now, all points have to be adjusted by the amounts in CX, DX.
	mov	al, SOT_ADD_DELTAS
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnAllPoints

	mov	al, SOUT_ADD_DELTAS
	call	SplineOperateOnUndoPoints
	call	SplineEndmCommon 

done:
	
	.leave
	ret
SplineSetVisBounds	endm


	;******************************************************************************
	;	Vis boundary methods
	;******************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineSetVisBoundaryDrawn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw (in invert mode) the visual boundary of the
		VisSpline object.

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDO CODE/STRATEGY:	none

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/24/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetVisBoundaryDrawn	method	dynamic	VisSplineClass, 
					MSG_SPLINE_DRAW_VIS_BOUNDARY
	uses	ax,cx,dx,bp
	.enter
	test	ds:[di].VSI_state, mask SS_VIS_BOUNDARY_DRAWN
	jnz	done
	ornf	ds:[di].VSI_state, mask SS_VIS_BOUNDARY_DRAWN
	call	SplineDrawVisBoundary
done:
	.leave
	ret
SplineSetVisBoundaryDrawn	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEraseVisBoundary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Erase the visual boundary of the spline object

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/24/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineEraseVisBoundary	method	dynamic	VisSplineClass, 
					MSG_SPLINE_ERASE_VIS_BOUNDARY
	uses	bp
	.enter
	test	ds:[di].VSI_state, mask SS_VIS_BOUNDARY_DRAWN
	jz	done

	; Reset the bit after calling the routine, because the routine checks the bit!

	call	SplineDrawVisBoundary
	mov	di,ds:[si]
	add	di,ds:[di].VisSpline_offset
	BitClr 	ds:[di].VSI_state, SS_VIS_BOUNDARY_DRAWN
done:
	.leave
	ret
SplineEraseVisBoundary	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawVisBoundary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create the gstate and draw the vis boundary

CALLED BY:	SplineSetVisBoundaryDrawn, 
		SplineEraseVisBoundary

PASS:		*ds:si - VisSpline object
		ds:di - VisSpline instance data
		es - segment of VisSpline class record

RETURN:		nothing 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	
	Doesn't need to be fast, so I made it small

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Registers used are those changed by SplineMethodCommon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawVisBoundary	proc near	
	uses		ds, es, si, di, bp, bx
	.enter
	call	SplineCreateGState
	call	SplineMethodCommon
	call	SplineDrawVisBoundaryLow
	call	SplineEndmCommon
	call	SplineDestroyGState
	.leave
	ret
SplineDrawVisBoundary	endp

SplineUtilCode	ends

SplineOperateCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRecalcVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go through every point of the spline object,
		determining the MINIMAL bounding rectangle.
		Send a message to myself if bounds should change.

CALLED BY:	SplineEndSelect, SplineDeletePoints, etc, etc.

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array
		

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/26/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRecalcVisBounds	proc	far

	uses	ax,bx,si

	class	VisSplineClass

	.enter

EC <	call	ECSplineInstanceAndPoints	> 

	call	ChunkArrayGetCount		; # of points
	jcxz	noPoints

	call	SplineGetBoundingBoxIncrement	; cx <- increment

	SplineDerefScratchChunk di
	andnf	ds:[di].SD_flags, not mask SDF_BOUNDING_BOX_INITIALIZED

	mov	ax, SOT_ADD_TO_BOUNDING_BOX	; clear AH
	mov	bx, mask SWPF_PREV_CONTROL or \
			mask SWPF_ANCHOR_POINT or \
			mask SWPF_NEXT_CONTROL

	call	SplineOperateOnAllPoints

compare:
	call	SplineCompareVisBoundsWithTemp
	je	done
	call	SplineRequestVisBoundsChangeToTemp
done:
	.leave
	ret			; < - EXIT POINT


noPoints:
	clr	ax

	SplineDerefScratchChunk di
	mov	ds:[di].SD_boundingBox.R_left, ax
	mov	ds:[di].SD_boundingBox.R_right, ax
	mov	ds:[di].SD_boundingBox.R_top, ax
	mov	ds:[di].SD_boundingBox.R_bottom, ax
	jmp	compare

SplineRecalcVisBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetBoundingBoxIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the increment needed to add to a curve's bounding
		box to include:
			- the handles 
			- line width
			- marker size
		whichever is greater.

CALLED BY:	

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 

RETURN:		cx - amount to add

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 1/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetBoundingBoxIncrement	proc	near
	uses	ax, dx
	class	VisSplineClass 
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	> 

	mov	ax, MSG_SPLINE_GET_LINE_WIDTH
	call	SplineSendMyselfAMessage
	mov	cx, dx			; keep int, discard frac.
	shr	cx, 1			; divide by 2

	mov	al, es:[bp].VSI_handleSize.BBF_int
	cbw
	max	cx, ax

	mov	al, es:[bp].VSI_markerShape
	cmp	al, MS_NONE
	je	done

	max	cx, MARKER_STD_SIZE

done:
	.leave
	ret
SplineGetBoundingBoxIncrement	endp

SplineGetBoundingBoxIncrementFar	proc	far
	call	SplineGetBoundingBoxIncrement
	ret
SplineGetBoundingBoxIncrementFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCompareVisBoundsWithTemp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the spline's REAL Vis bounds with those in the
	SD_boundingBox,  translated appropriately.

CALLED BY:	SplineRecalcVisBounds

PASS:		es:bp - VisSplineInstance data 
		ds:di - scratch chunk 

RETURN:		ZERO flag set if equal

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCompareVisBoundsWithTemp	proc near 	uses	si,cx,dx
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndScratch	> 

	; If either the left or top are nonzero, then things have changed.

	tst	ds:[di].SD_boundingBox.R_left
	jnz	done
	tst	ds:[di].SD_boundingBox.R_top
	jnz	done

	; otherwise, compare right and bottom with the object's size

	mov	si, ds:[di].SD_splineChunkHandle
	segxchg	es, ds
	call	VisGetSize
	segxchg	es, ds


	cmp	ds:[di].SD_boundingBox.R_right, cx
	jne	done
	cmp	ds:[di].SD_boundingBox.R_bottom, dx
done:
	.leave
	ret
SplineCompareVisBoundsWithTemp	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRequestVisBoundsChangeToTemp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a request (to myself) to change the Vis Bounds.

CALLED BY:	SplineRecalcVisBounds,
		SplineDetermineIfTempVisBoundsChanged

PASS:		es:bp - VisSplineInstance data 
		ds:di - POINTER to scratch chunk
		
RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	
	Translate the boundingBox by the REAL vis bounds before
	sending message.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/26/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineRequestVisBoundsChangeToTemp	proc	far
	uses	ax,bx,cx,dx,si
	.enter
EC <	call	ECSplineInstanceAndScratch	> 

	; At the end of all this, we want the proper rectangle struct to be on
	; the stack (This, of course, is a serious hack!)

	CheckHack <offset R_bottom eq 6>
	CheckHack <offset R_right  eq 4>
	CheckHack <offset R_top    eq 2>
	CheckHack <offset R_left   eq 0>

	mov	si, ds:[di].SD_splineChunkHandle
	segxchg	ds, es
	call	VisGetBounds
	segxchg	ds, es
	mov_tr	cx, ax		; (CX, BX) -- position

	mov	ax, ds:[di].SD_boundingBox.R_bottom
	add	ax, bx
	push	ax

	mov	ax, ds:[di].SD_boundingBox.R_right
	add	ax, cx
	push	ax

	mov	ax, ds:[di].SD_boundingBox.R_top
	add	ax, bx
	push	ax

	mov	ax, ds:[di].SD_boundingBox.R_left
	add	ax, cx
	push	ax

	mov	bx, sp
	mov	dx, size Rectangle
 	mov	ax, MSG_SPLINE_NOTIFY_CHANGE_BOUNDS
	call	SplineSendMyselfAMessage

	; restore stack pointer
	add	sp, size Rectangle
	.leave
	ret
SplineRequestVisBoundsChangeToTemp	endp

SplineOperateCode	ends


SplinePtrCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMakeTempCopyOfVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a temporary copy of the Visual Bounds in the
		scratch chunk. 

CALLED BY:	SplineMoveCommon

PASS:		es:bp - VisSplineInstance data

RETURN:		nothing 

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	
	Actually, not really a COPY, but a TRANSLATION into the
	spline's internal coordinate system.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMakeTempCopyOfVisBounds	proc far
 	uses	ax,cx,dx,si,di

	class	VisSplineClass

	.enter

	SplineDerefScratchChunk	di
	mov	si, ds:[di].SD_splineChunkHandle

	segxchg	ds, es
	call	VisGetSize		; returns size in cx, dx
	segxchg	ds, es

	BitClr	ds:[di].SD_flags, SDF_BOUNDING_BOX_CHANGED
	ornf	ds:[di].SD_flags, mask SDF_BOUNDING_BOX_INITIALIZED
	clr	ax
	mov	ds:[di].SD_boundingBox.R_left, ax
	mov	ds:[di].SD_boundingBox.R_top, ax
	mov	ds:[di].SD_boundingBox.R_right, cx
	mov	ds:[di].SD_boundingBox.R_bottom, dx

	.leave
	ret
SplineMakeTempCopyOfVisBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAddPointToBoundingBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current point is outside the current Vis
		Bounds of the spline object

CALLED BY:	SplineOperateOnPointCommon

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data
		ax - current point number
		bl - SplineDrawFlags (SDF_USE_UNDO_INSTEAD_OF_TEMP)
		cx - amount to add, subtract to current point's
		position to allow for handle size, & line width

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di	

PSEUDO CODE/STRATEGY:	
	This procedure will only make the rectangle BIGGER, not
	smaller!  That's why SplineRecalcVisBounds has to
	first load the boundingBox with valid data.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	;; To save  my fingers somme typing:

LEFT	equ <ds:[di].SD_boundingBox.R_left>
RIGHT 	equ <ds:[di].SD_boundingBox.R_right>
TOP	equ <ds:[di].SD_boundingBox.R_top>
BOTTOM 	equ <ds:[di].SD_boundingBox.R_bottom>

SplineAddPointToBoundingBox	proc near 	

	class	VisSplineClass
	.enter

EC <	test	bl, not mask SDF_USE_UNDO_INSTEAD_OF_TEMP >
EC <	ERROR_NZ	ILLEGAL_FLAGS			  >

	;
	; Get the coordinates for this point, getting the UNDO data,
	; if requested.  Note:  The UNDO data for this point may not
	; exist, so just exit if not found.
	;

	push	cx
	mov	cl, bl
	call	SplineGetPointData
	pop	ax		; amount to add for line-width, etc.
	jc	done

	LoadPointAsInt	cx, dx, ds:[di].SPS_point

	SplineDerefScratchChunk	di

	test	ds:[di].SD_flags, mask SDF_BOUNDING_BOX_INITIALIZED
	jz	initialize
	
	mov	bx, cx		; temp storage for X-coord

	; What we do is compare the points (CX, DX) with the TOP,
	; BOTTOM, LEFT, and RIGHT coordinates of the rectangle,
	; updating the rectangle if necessary.

	sub	cx, ax		; subtract handle size
	cmp	cx, LEFT	; check with left bdy
	je	checkYCoord	; equal, DONE with x-coord
	jg	checkRight	; greater? check with right bdy
	mov	LEFT, cx	; update!
	BitSet	ds:[di].SD_flags, SDF_BOUNDING_BOX_CHANGED
	jmp	checkYCoord

checkRight:
	mov	cx, bx		; old x-coord
	add	cx, ax		; handle size
	cmp	cx, RIGHT
	jle	checkYCoord
	mov	RIGHT, cx
	BitSet	ds:[di].SD_flags, SDF_BOUNDING_BOX_CHANGED

checkYCoord:
	mov	bx, dx		; save y-coord
	sub	dx, ax		; subtract handle size
	cmp	dx, TOP
	je	done
	jg	checkBottom
	mov	TOP, dx	
	BitSet	ds:[di].SD_flags, SDF_BOUNDING_BOX_CHANGED
	jmp	done

checkBottom:
	mov	dx, bx		; restore y-coord
	add	dx, ax		; add handle size
	cmp	dx, BOTTOM
	jle	done
	mov	BOTTOM, dx
	BitSet	ds:[di].SD_flags, SDF_BOUNDING_BOX_CHANGED
done:		
	.leave
	ret

initialize:
	push	cx, dx
	sub	cx, ax
	sub	dx, ax
	mov	LEFT, cx
	mov	TOP, dx
	pop	cx, dx
	add	cx, ax
	add	dx, ax
	mov	RIGHT, cx
	mov	BOTTOM, dx
	ornf	ds:[di].SD_flags, mask SDF_BOUNDING_BOX_INITIALIZED
	jmp	done
	
SplineAddPointToBoundingBox	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDetermineIfTempVisBoundsChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the VisBounds have changed.  If so, send a
		MSG_SPLINE_RESIZE to myself

CALLED BY:	SplineMoveAnchor, 
		SplineMoveSegment,
		SplineMoveControl, 
		SplineAddAnchor

PASS:		es:bp - VisSplineInstance data
		ds - data segment of VisSpline's data block

RETURN:		es, di, bp, ds fixed up (if necessary)

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	
	The boundingBox rectangle is in VisSpline coordinates.
These must be translated to document coordinates before
sending the message.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDetermineIfTempVisBoundsChanged	proc far uses	si
	class	VisSplineClass
	.enter

EC <	call	ECSplineInstanceAndLMemBlock	> 
	 
	SplineDerefScratchChunk di
	test	ds:[di].SD_flags, mask SDF_BOUNDING_BOX_CHANGED
	jz	done
	call	SplineRequestVisBoundsChangeToTemp
	call	SplineSetInvertMode
done:
	.leave
	ret
SplineDetermineIfTempVisBoundsChanged	endp




SplinePtrCode	ends

SplineObjectCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetMinimalVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetMinimalVisBounds	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_MINIMAL_VIS_BOUNDS
	uses	ax,cx,dx,bp
	.enter
	
	push	di				;instance data offset
	clr	di
	call	GrCreateState
	mov	bp,di
	pop	di				;instance data offset
	call	SplineSetupPassedGState

	call	SplineSetNormalAttributes

	call	SplineDrawToPathFar

	mov	di, es:[bp].VSI_gstate
	mov	ax, GPT_CURRENT			; want current path
	call	GrGetPathBounds
	pushf
	call	SplineRestorePassedGState	
	call	GrDestroyState 
	popf
	jc	noPath

	;
	; Deal with bugs in the graphics code
	;

IRP reg, <ax, bx, cx, dx>
	cmp	&reg, MAX_COORD
	jg	error
	cmp	&reg, MIN_COORD
	jl	error
endm

storeIt:
	;
	; Add in our (spline) vis bounds upper-left hand corner
	;
	add	ax, es:[bp].VI_bounds.R_left
	add	cx, es:[bp].VI_bounds.R_left
	add	bx, es:[bp].VI_bounds.R_top
	add	dx, es:[bp].VI_bounds.R_top


		CheckHack <size Rectangle eq 8>
		CheckHack <offset R_bottom eq 6>
		CheckHack <offset R_right eq 4>
		CheckHack <offset R_top eq 2>
		CheckHack <offset R_left eq 0>

	push	dx, cx, bx, ax
	mov	bx, sp
	mov	ax, MSG_SPLINE_NOTIFY_CHANGE_BOUNDS
	mov	dx, size Rectangle
	call	SplineSendMyselfAMessage

	add	sp, size Rectangle

noPath:
	call	SplineEndmCommon


	.leave
	ret
error:
	clr	ax, bx, cx, dx
	jmp	storeIt

SplineSetMinimalVisBounds	endm


SplineObjectCode	ends
