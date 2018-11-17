COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineMethods.asm

AUTHOR:		Chris Boyke

REVISION HSTORY:

	Name	Date		Description
	----	----		-----------
	CDB	6/13/91		Initial version.

METHODS:
	SplineAbortCurrentOperation
	SplineCloseCurve
	SplineCopy
	SplineDeleteAnchors
	SplineDeleteControls
	SplineDraw
	SplineEndSelectRectangle
	SplineGetAllLengths
	SplineGetAreaColor
	SplineGetAreaMask
	SplineGetHandleSize
	SplineGetLineColor
	SplineGetLineStyle
	SplineGetLineWidth
	SplineInitialize
	SplineInsertAllControls
	SplineInsertAnchors
	SplineInsertControls
	SplineObjFree
	SplineOpenCurve
	SplineSelectRectangle
	SplineSetAreaColor
	SplineSetAreaMask
	SplineSetHandleSize
	SplineSetLineColor
	SplineSetLineStyle
	SplineSetLineWidth
	SplineSetSmoothness
	SplineSubdivideCurve
	SplineTransformPoints
	SplineUnselectAllPoints

DESCRIPTION:	
	This file contains methods defined by the VisSpline
object. 
	

	$Id: splineMethods.asm,v 1.1 97/04/07 11:09:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineUtilCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		splineDraw, MSG_VIS_DRAW

DESCRIPTION:	Translate the given gstate by the vis bounds and draw 
		everything.

PASS:		*ds:si - spline object
		ds:bx  - spline object
		ds:di  - VisSpline instance data
		bp - gstate handle

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDraw	method	dynamic VisSplineClass, MSG_VIS_DRAW
	uses	ax
	.enter
	mov	ax, MSG_SPLINE_DRAW_BASE_OBJECT
	call	ObjCallInstanceNoLock
	mov	ax, MSG_SPLINE_DRAW_EVERYTHING_ELSE
	call	ObjCallInstanceNoLock
	.leave
	ret
SplineDraw	endm




;******************************************************************************
; Operations on the spline points
;******************************************************************************



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetSmoothness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the smoothness for the selected points

PASS:		*DS:SI	= VisSplineClass instance data.
		DS:DI	= *DS:SI.
		ES	= Segment of VisSplineClass.
		AX	= Method.
		CL 	= SmoothType etype

RETURN:		nothing

DESTROYED:	Nada

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/10/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetSmoothness	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_SMOOTHNESS
	uses	ax,cx,dx,bp
	.enter
	call	SplineMethodCommon
	mov	al, SOT_MODIFY_INFO_FLAGS
	mov	bx, mask SWPF_ANCHOR_POINT

; HACK!  The ModifyInfoFlags procedure will properly handle this
; setting of the ETYPE in the flags record (we hope!) by first
; clearing the bits, then setting them.

CheckHack <offset APIF_SMOOTHNESS eq 0>
	mov	ch, cl
	mov	cl, mask APIF_SMOOTHNESS
	call	SplineOperateOnSelectedPointsFar

	mov	cx, mask SGNF_SMOOTHNESS
	call	SplineUpdateUI

	call	SplineEndmCommon 
	.leave
	ret
SplineSetSmoothness	endm


SplineUtilCode	ends
	


SplineInitCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the VisSpline's instance data

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= VisSpline instance data
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		dx 	= size of stack frame (0 if none passed)
		ss:bp 	= stack frame of initialization parameters
				(SplineInitParams)

RETURN:		nothing

DESTROYED:	nothing 

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDO CODE/STRATEGY:
	Read values from the init block, using default values where
	none are passed.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This is NOT the method for MSG_META_INITIALIZE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/25/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineInitialize	method	dynamic	VisSplineClass, 
						MSG_SPLINE_INITIALIZE
	uses	ax,cx,dx,bp
	.enter

	call	ObjMarkDirty

	call	SplineGetVMFile		; bx - VM file handle

; If no PARAMS were passed, then create a params structure
	tst	dx
NEC <	jnz	hasParams

EC <	jz	createParams
EC <	test	ss:[bp].SIP_flags, mask SIF_INTERNAL
EC <	ERROR_NZ ILLEGAL_FLAGS
EC <	jmp	hasParams
EC <createParams:	

	sub	sp, size SplineInitParams
	mov	bp, sp
	clr	ss:[bp].SIP_lmemBlock
	mov	ss:[bp].SIP_flags,	INIT_FLAGS

hasParams:
; If RESET_LINKAGES flag is set, then clear out the link field.  NOTE:
; this means going in and messing with superclass instance data.

	test	ss:[bp].SIP_flags, mask SIF_RESET_LINKAGES
	jz	afterResetLink

	clrdw	ds:[di].VI_link.LP_next

afterResetLink:


	push	si			; spline's chunk handle
	segmov	es, ds

	; See if the points block exists

	mov	ax, ss:[bp].SIP_lmemBlock
	tst	ax
	jnz	afterCreateBlock

	; create a new one -- make a note of the fact.  Make it an
	; object block, so that we can muck with its interactibility
	; count, etc.

	ornf	es:[di].VSI_state, mask SS_CREATED_BLOCK
	push	bx			; VM file handle
	clr	bx
	call	UserAllocObjBlock
	call	ObjLockObjBlock
	mov	ds, ax			; ds - new object block
	mov	cx, bx			; mem handle
	clr	ax			; create a new VM block
	pop	bx			; VM file handle
	call	VMAttach
	call	VMPreserveBlocksHandle
	mov_tr	ax, cx

afterCreateBlock:
	mov	es:[di].VSI_lmemBlock, ax
	test	ss:[bp].SIP_flags, mask SIF_MANAGE_ATTRIBUTES
	jz	afterCreateAttrChunks

	;
	; Create the chunks to store line, area attributes
	;

	ornf	es:[di].VSI_state, mask SS_HAS_ATTR_CHUNKS
	clr	al				; No ObjectChunkFlags
	mov	cx, size LineAttr
	call	LMemAlloc			; allocate attributes chunk
	mov	es:[di].VSI_lineAttr, ax

	clr	al				; No ObjectChunkFlags
	mov	cx, size AreaAttr
	call	LMemAlloc			; allocate attributes chunk
	mov	es:[di].VSI_areaAttr, ax

afterCreateAttrChunks:

	; allocate selected points chunk array

	mov	bx, size SelectedListEntry
	clr	ax, cx, si
	call	ChunkArrayCreate		; allocate selected points 
	mov	es:[di].VSI_selectedPoints, si  

	; allocate points chunk array
	
	mov	bx, size SplinePointStruct	; Chunk array of spline points
	clr	ax, si				; cx is zero from above
	call	ChunkArrayCreate
	mov	es:[di].VSI_points, si		; store chunk handle of array

	; Unlock the mem block, after marking it dirty, of course

	mov	bx, ds:[LMBH_handle]
	push	bp
	mov	bp, bx
	call	VMDirty
	pop	bp
	call	MemUnlock

	; restore *ds:si as the spline

	segmov	ds, es
	pop	si

	; 
	; Set initial settings for the data
	;

	clr	ax
	mov	ds:[di].VSI_undoPoints, ax
	mov	ds:[di].VSI_newPoints, ax
	mov	ds:[di].VSI_scratch, ax
	mov	ds:[di].VSI_gstate, ax
	mov	ds:[di].VSI_gstateRefCount, al
	mov	ds:[di].VSI_editState, al
	mov	ds:[di].VSI_actionPoint, ax
	mov	{word} ds:[di].VSI_handleSize, INIT_HANDLE_SIZE
	SetEtypeInRecord  SM_INACTIVE, SS_MODE, ds:[di].VSI_state
	
	; Set the spline NOT drawable

	mov	ax, MSG_VIS_SET_ATTRS
	movH	cx, <mask VA_DRAWABLE>
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock

	; Initialize line/area attributes

	mov	ax, MSG_SPLINE_SET_DEFAULT_LINE_ATTRS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_SPLINE_SET_DEFAULT_AREA_ATTRS
	call	ObjCallInstanceNoLock

	; Initialize points, etc.

	call	SplineInitializePoints

	; If SIF_INTERNAL flag is set, then release stack data

	test	ss:[bp].SIP_flags, mask SIF_INTERNAL
	jz	done
	add	sp, size SplineInitParams
done:
	.leave
	ret
SplineInitialize	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitializePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the APIF_SELECTED bit for the anchor points, and
		reset all drawn bits for all points.

CALLED BY:	SplineInitialize

PASS:		*ds:si - VisSpline object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,ds

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/29/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitializePoints	proc	near
	uses	si,di,bp
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].VisSpline_offset

	call	SplineMethodCommon 
	mov	al, SOT_MODIFY_INFO_FLAGS
	mov	bx, mask SWPF_ANCHOR_POINT
	movL	cx, <mask APIF_SELECTED or \
			mask APIF_HOLLOW_HANDLE or \
			mask APIF_IM_CURVE or  \
			mask PIF_FILLED_HANDLE or \
			mask PIF_TEMP> 
	
	call	SplineOperateOnAllPoints

	mov	bx, mask SWPF_NEXT_CONTROL or mask SWPF_PREV_CONTROL
	movL	cx, <mask PIF_FILLED_HANDLE or \
			mask CPIF_CONTROL_LINE or\
			mask PIF_TEMP>

	call	SplineOperateOnAllPoints

	call	SplineEndmCommon
	.leave
	ret
SplineInitializePoints	endp




SplineInitCode	ends


SplineUtilCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAbortCurrentOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Release the mouse grab, end any kind of move
		operation, etc.

PASS:		*DS:SI	= VisSplineClass instance data.
		DS:DI	= *DS:SI.
		ES	= Segment of VisSplineClass.
		AX	= Method.

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDO CODE/STRATEGY:	
	If there's a DRAG_SELECT or MOVE_OPERATION, then send myself
	an END_SELECT.
	
	Release the mouse grab, destroy the GState and Scratch Chunk.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineAbortCurrentOperation	method	dynamic	VisSplineClass, 
				MSG_SPLINE_ABORT_CURRENT_OPERATION

	uses	ax,cx,dx,bp
	.enter
	call	VisReleaseMouse
	.leave
	ret
SplineAbortCurrentOperation	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineTransformPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Transform the spline's points based on the passed
		gstate transformation matrix.

PASS:		*DS:SI	= VisSplineClass object
		DS:DI	= VisSplineClass instance data
		ES	= Segment of VisSplineClass.
		AX	= Method.
		BP 	= GState handle
RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/26/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineTransformPoints	method	dynamic	VisSplineClass, 
						MSG_SPLINE_TRANSFORM_POINTS
	uses	ax,cx,dx,bp
	.enter

	push	di			; offset to instance data
	mov	di,bp			; gstate
	call	GrSaveState
	call	SplineTranslateGStateByVisBounds
	pop	di			; offset to instance data


	push	bp			; save gstate handle
; Invalidate myself first:
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

; Now, change coordinates
	call	SplineMethodCommon

	pop	cx			; restore gstate handle
	mov	ax, SOT_TRANSFORM_POINT
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnAllPoints

	mov	di, cx			; gstate handle

	; Convert BACK from DOCUMENT coordinates to SPLINE coordinates
	; Get vis bounds upper left-hand corner
	; subtract this amount from all points.

	mov	cx, es:[bp].VI_bounds.R_left
	mov	dx, es:[bp].VI_bounds.R_top
	neg	cx
	neg	dx

	; Now, all points have to be adjusted by the amounts in CX, DX.

	mov	al, SOT_ADD_DELTAS
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnAllPoints

	mov	al, SOUT_ADD_DELTAS
	call	SplineOperateOnUndoPoints

	call	GrRestoreState


; Fixup VisBounds
	mov	ax,MSG_SPLINE_SET_MINIMAL_VIS_BOUNDS
	call	SplineSendMyselfAMessage

; Invalidate again w/new vis bounds
	call	SplineInvalidate

; Unlock mem block, exit
	call	SplineEndmCommon 
	.leave
	ret
SplineTransformPoints	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetAllLengths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the length of every spline curve, storing result
		in the passed ChunkArray

PASS:		*DS:SI	= VisSplineClass object
		DS:DI	= VisSplineClass instance data
		ES	= Segment of VisSplineClass.
		AX	= Method.
		^lCX:DX	= Chunk Array (block must be locked)

RETURN:		nothing 

DESTROYED:	Nada.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	The chunk array must already be initialized (to zero
	elements).  Element size is irrelevant, but the FIRST WORD
	will contain the anchor point number, and the SECOND WORD will
	contain the length of the curve.
	
	The array is created so that it's in REVERSE order (high point
	numbers stored first), so that Mr. Blend can insert points
	more easily.

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetAllLengths	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_ALL_LENGTHS
	uses	ax,cx,dx,bp

	.enter
EC <	cmp	cx, ds:[LMBH_handle]		>
EC <	ERROR_E	OBJECT_BLOCK_AND_LENGTH_BLOCK_IDENTICAL >

	call	SplineMethodCommon
	mov	al, SOT_STORE_LENGTH_IN_ARRAY
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnAllPoints

; Now, go thru and fill in the PERCENT fields

	push	ds:[LMBH_handle]	; save current points block
					; handle 
	mov	bx, cx
	call	MemDerefDS
	mov	si, dx

	mov	bx, cs
	mov	di, offset SplineSumLengthCB
	clr	cx
	call	ChunkArrayEnum

	mov	dx, cx
	mov	di, offset SplineConvertToPercentCB
	call	ChunkArrayEnum

	pop	bx			; restore points block handle
	call	MemDerefDS
	call	SplineEndmCommon

	.leave
	ret
SplineGetAllLengths	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSumLengthCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the current length to the total

CALLED BY:

PASS:		

RETURN:		CX - total length up to current point

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSumLengthCB	proc far
	add	cx, ds:[di].LS_length
	clc
	ret
SplineSumLengthCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineConvertToPercentCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the LS_percent field of the current point

CALLED BY:

PASS:		ds:di - current length element
		cx - total length of spline
		dx - length of spline up to the NEXT point 

RETURN:		dx - length of spline up to the current point

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineConvertToPercentCB	proc far
	.enter
	sub	dx, ds:[di].LS_length	; subtract off THIS curve's
					; length.

	push	dx
	
	Divide	dx, cx		; Divide current length/ total length
				; result is DX.AX (wwfixed)

	mov	ds:[di].LS_percent, ax	; store percentage amount

	pop	dx
	clc
	.leave
	ret
SplineConvertToPercentCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSubdivideCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*DS:SI	= VisSplineClass object
		DS:DI	= VisSplineClass instance data
		ES	= Segment of VisSplineClass.
		AX	= Method.

RETURN:		ax 	= new anchor number

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

SplineSubdivideCurve	method	dynamic	VisSplineClass, 
				MSG_SPLINE_SUBDIVIDE_CURVE
	uses	cx,dx,bp
	.enter

	call	SplineMethodCommon
	mov	ax, cx
	mov	cx, dx
	call	SplineSubdivideOnParam
	call	SplineEndmCommon

	.leave
	ret
SplineSubdivideCurve	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Make a copy of myself

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		ax	= Method.

		cx 	= handle of object block in which to place the
			  copy 
		dx 	= handle of data block in which to place the 
			  points, etc.

RETURN:		cx 	- chunk handle of new spline

DESTROYED:	Nada.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/14/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineCopy	method	dynamic	VisSplineClass, MSG_SPLINE_COPY
	uses	ax,dx,bp

sourceChunk	local	word	push	si
destPointsBlock	local	word	push	dx
destSpline	local	optr
copyChunkParams	local	CopyChunkInFrame
lineAttrs	local	LineAttr
areaAttrs	local	AreaAttr
	
	.enter

	mov	ss:[destSpline].handle, cx

	; set up source for chunk copy

	mov	ax, ds:[LMBH_handle]
	mov	copyChunkParams.CCIF_source.handle, ax
	mov	copyChunkParams.CCIF_source.chunk, si
	mov	copyChunkParams.CCIF_copyFlags, CCM_OPTR shl offset CCF_MODE

	; copy spline object

	mov	bx, ss:[destSpline].handle
	mov	copyChunkParams.CCIF_destBlock, bx
	call	MemOwner		; bx <- owner
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_PROCESS_COPY_CHUNK_IN
	push	bp
	mov	dx, size CopyChunkInFrame
	lea	bp, ss:[copyChunkParams]
	call	ObjMessage
	pop	bp
	mov	ss:[destSpline].chunk, ax

	mov	si, sourceChunk
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	ax, destPointsBlock
	movdw	bxsi, ss:[destSpline]

	;
	; Set up stack frame for SPLINE_INITIALIZE
	; ds:di - current spline
	; ax - destination points block (mem handle)
	; ^lbx:si - destination spline

	push	bp			; local frame
	sub	sp, size SplineInitParams
	mov	bp, sp

	push	bx
	mov_tr	bx, ax
	call	VMMemBlockToVMBlock
	mov	ss:[bp].SIP_lmemBlock, ax
	pop	bx
;
; If the current spline has attr chunks, then we want the new spline
; to have them, too (and vice versa) Set SIF_MANAGE_ATTRIBUTES to the
; spline's SS_HAS_ATTR_CHUNKS flag.  As I've got things set up now,
; this SHIFT should assemble to nothing.
;
	mov	al, ds:[di].VSI_state
	and	al, mask SS_HAS_ATTR_CHUNKS
	SHIFT	al, <offset SIF_MANAGE_ATTRIBUTES - offset	\
			SS_HAS_ATTR_CHUNKS>
	or	al, SPLINE_COPY_FLAGS

	mov	ss:[bp].SIP_flags, al

	mov	ax, MSG_SPLINE_INITIALIZE
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	mov	dx, size SplineInitParams
	call	ObjMessage

	add	sp, size SplineInitParams
	pop	bp			; restore local vars

	;
	; Set the destination spline's points 
	;

	mov	di, ss:[sourceChunk]
	mov	di, ds:[di]
	add	di, ds:[di].VisSpline_offset
	mov	cx, ds:[di].VSI_lmemBlock
	mov	dx, ds:[di].VSI_points
	mov	ax, MSG_SPLINE_REPLACE_POINTS
	clr	di
	call	ObjMessage

	;
	; Copy the line attributes
	;
	mov	si, ss:[sourceChunk]
	mov	ax, MSG_SPLINE_GET_LINE_ATTRS
	mov	cx, ss
	lea	dx, ss:[lineAttrs]
	call	ObjCallInstanceNoLock

	mov	si, ss:[destSpline].chunk
	mov	ax, MSG_SPLINE_SET_LINE_ATTRS
	clr	di
	call	ObjMessage

	;
	; Copy the area attributes
	;

	mov	si, ss:[sourceChunk]
	mov	ax, MSG_SPLINE_GET_AREA_ATTRS
	mov	cx, ss
	lea	dx, ss:[areaAttrs]
	call	ObjCallInstanceNoLock

	mov	si, ss:[destSpline].chunk
	mov	ax, MSG_SPLINE_SET_AREA_ATTRS
	clr	di
	call	ObjMessage

	;
	; Return new spline's chunk handle to caller
	;

	mov	cx, ss:[destSpline].chunk

	.leave
	ret
SplineCopy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the visual representation of anchors based on
		the passed rectangle and flags.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		ss:bp   = SplineSelectRectangleParams

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/24/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSelectRectangle	method	dynamic	VisSplineClass,
					MSG_SPLINE_SELECT_RECTANGLE 
	uses	ax,cx,dx,bp
	.enter

CheckHack	<offset SSRP_rect eq 0>

	call	SplineCreateGState

	mov	cl, ss:[bp].SSRP_flags

	push	bp			; ss:bp = passed Rectangle
	call	SplineMethodCommon 
	SplineDerefScratchChunk	di
	add	di, offset SD_startRect
	pop	si			; ptr to Rectangle
	segmov	es, ds
	segmov	ds, ss
	
; Going to move the Rectangle structure into two "Point" structures in
; the scratch data that we hope are the right size and contiguous in
; memory!

	CheckHack <(size Rectangle) eq (2*size Point)>
	CheckHack <(offset SD_mouse) eq (offset SD_startRect)+size Point>

	MovBytes <size Rectangle>

	call	SplineSetInvertModeFar
	mov	al, SOT_DRAW_FOR_SELECTION_RECTANGLE
	mov	bx, mask SWPF_ANCHOR_POINT
	mov	ch, cl			; UIFunctionsActive
	mov	si, es:[bp].VSI_points
	call	SplineOperateOnAllPoints

	call	SplineEndmCommon 
	call	SplineDestroyGState 
	.leave
	ret
SplineSelectRectangle	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndSelectRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	End the selection-rectangle business by selecting
		filled anchors.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/25/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineEndSelectRectangle	method	dynamic	VisSplineClass, 
					MSG_SPLINE_END_SELECT_RECTANGLE
	uses	ax,cx,dx,bp
	.enter
	call	SplineCreateGState 
	call	SplineMethodCommon 
	call	SplineEndDragRectCommon
	call	SplineEndmCommon 
	call	SplineDestroyGState 
	.leave
	ret
SplineEndSelectRectangle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUnselectAllPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Unselect all points

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/25/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineUnselectAllPoints	method	dynamic	VisSplineClass, 
					MSG_SPLINE_UNSELECT_ALL_POINTS
	uses	bp
	.enter
	call	SplineCreateGState 
	call	SplineMethodCommon 
	call	SplineUnselectAll
	call	SplineEndmCommon 
	call	SplineDestroyGState 
	.leave
	ret
SplineUnselectAllPoints	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Free the spline's lmem block (if sole owner) before
		calling superclass.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineFinalObjFree	method	dynamic	VisSplineClass, MSG_META_FINAL_OBJ_FREE
	uses	ax,cx
	.enter

	test	ds:[di].VSI_state, mask SS_CREATED_BLOCK
	jz	callSuper

	;    Make sure not to put any messages on the queue
	;

	clr	cx
	xchg	cx, ds:[di].VSI_lmemBlock
	call	GeodeGetProcessHandle
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_PROCESS_FINAL_BLOCK_FREE
	call	ObjMessage

callSuper:
	mov	ax,MSG_META_FINAL_OBJ_FREE
	mov	di, offset VisSplineClass
	call	ObjCallSuperNoLock

	.leave
	ret
SplineFinalObjFree	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetHandleSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the handle size.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		cx 	= handle size (BBFixed)

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Store HALF the handle size, since it's always used internally
	that way.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 4/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetHandleSize	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_HANDLE_SIZE
	uses	bp
	.enter
	shr	cx, 1		;;    divide by 2 
	mov	{word} ds:[di].VSI_handleSize, cx
	call	SplineCreateGState 
	call	SplineMethodCommon 
	call	SplineDrawEverythingProtectHandles
	call	SplineEndmCommon 
	call	SplineDestroyGState 
	.leave
	ret
SplineSetHandleSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetHandleSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the handle size

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		cx 	= handle size (BBFixed)

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 4/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetHandleSize	method	dynamic	VisSplineClass, 
						MSG_SPLINE_GET_HANDLE_SIZE
	mov	cx, {word} ds:[di].VSI_handleSize
	shl	cx, 1
	ret
SplineGetHandleSize	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineNotifyGeometryValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Clear the geometry invalid bit

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
	CDB	3/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineNotifyGeometryValid	method	dynamic	VisSplineClass, 
					MSG_VIS_NOTIFY_GEOMETRY_VALID
	.enter

	; Reset the geometry invalid flag

	andnf	ds:[di].VI_optFlags, not mask VOF_GEOMETRY_INVALID

	.leave
	ret
SplineNotifyGeometryValid	endm






SplineUtilCode	ends

