
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS - Spline edit object
MODULE:		VisSpline edit object
FILE:		splineUndo.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version


METHODS:
	SplineUndo, 

GLOBAL ROUTINES:

	SplineAddToNewPointsList
	SplineGetPointData

INTERNAL
ROUTINES:

DESCRIPTION:	Handle the "undo" stuff for the VisSplineObject

	$Id: splineUndo.asm,v 1.1 97/04/07 11:08:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplinePtrCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineGetPointData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set ds:[di] pointing to a point's data.  If the passed
flags so indicate, have ds:[di] point to the "undo" version of the
point rather than the actual point.

CALLED BY:	

PASS:		*ds:si - points chunk array
		es:bp - VisSplineInstance data
		ax - point number
		cl - SplineDrawFlags

RETURN:	CARRY set iff point not found, otherwise:

	di - based on the flags passed:
	if SDF_USE_UNDO_INSTEAD_OF_TEMP is set:
		if point is TEMP:
			return UNDO point (error if undo not found)
		ELSE
			return the point
	OTHERWISE:
		return the point		


DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetPointData	proc	near
	uses	si
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints	>
	call	ChunkArrayElementToPtr		; get point data
	jc	done				; no point? return carry set
	test	ds:[di].SPS_info, mask PIF_TEMP ; is temp bit set?
	jz	done				; NO: done
	test	cl, mask SDF_USE_UNDO_INSTEAD_OF_TEMP
						; use UNDO instead?
	jz	done				; no? DONE

	;
	; There might be no undo points
	;

	mov	si, es:[bp].VSI_undoPoints
	tst	si
	jz	done

	call	SplineLookupUndoPoint	; get UNDO point
	jc	done			; carry = no point available
	add	di, offset UAE_data	; set pointer to actual point
					; data (ADD clears carry)
done:
	.leave
	ret
SplineGetPointData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineLookupUndoPoint	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lookup the point (ax) in the undo array

CALLED BY:	SplineGetPointData

PASS:		*ds:si - undo array
		ax - point number to search for

RETURN:		If found:  
			carry clear, 
			ds:di is the UNDO point
		ELSE:  
			di undefined
			carry set

DESTROYED:	nothing

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:	
	** OPTIMIZE ** 
	We could use a BINARY search here since the array is in
	increasing order.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineLookupUndoPoint	proc	near
	uses	cx, ax
	.enter
	mov	cx, ax			; save point number
	clr	ax			; start at beginning of array
startLoop:
	call	ChunkArrayElementToPtr	; get next element in array
	jc	notFound		; not found!
	cmp	ds:[di].UAE_pointNum, cx ; is it the point? 
	je	done			; YES: found (carry is clear)
	jg	notFound		; GREATER: not found
	inc	ax			; go to next point
	jmp	startLoop
notFound:
	stc
done:
	.leave
	ret

SplineLookupUndoPoint	endp


SplinePtrCode	ends


SplineOperateCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineCopyPointToUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the selected point to the "undo" list.  Clear the
		DRAWN flags in the UNDO version.

CALLED BY:	SplineOperateOnPointCommon

PASS:		*ds:si - points chunk array
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
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineCopyPointToUndo	proc	near
	uses	ax,bx,cx,dx,si,di,es
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndPoints	>
EC <	call	ECSplinePoint			>



	mov	bx, si				; store points ch.
						; handle
	mov	cx, ax				; store point number

	mov	si, es:[bp].VSI_undoPoints

	; REGISTERS:
	;	cx - point number
	;	*ds:bx - points array
	;	*ds:si - Undo chunk array
	;
	; Now, insert point in INCREASING order into the chunk array.
	; If it's already there, then don't sweat, just exit.  This
	; can happen, for example, if 2 adjacent anchors are selected,
	; and they both try to add their neighboring controls to the
	; undo list, for a MOVE operation
	;

	clr	ax				; start at beginning of array
startLoop:
	call	ChunkArrayElementToPtr
	jc	addAfter			; end of array
	cmp	ds:[di].UAE_pointNum, cx
	je	done
	jg	insertAt			; insert it here
	inc	ax
	jmp	startLoop

insertAt:
	call	ChunkArrayInsertAt
	jmp	storeIt
addAfter:
	call	ChunkArrayAppend
storeIt:
	mov	dx, di			; destination (in Undo Array)
	; ds:dx is the destination.
	mov	si, bx			; points array
	mov	ax, cx			; source point number
	call	ChunkArrayElementToPtr
	mov	si, di			; ds:si - source point
	mov	di, dx			; ds:di - dest point

	segmov	es, ds, cx
	
	CheckHack <offset UAE_data eq size word>

	stosw				; store point number 

	mov	cx, size SplinePointStruct
	cld
	rep	movsb
done:
	.leave
	ret
SplineCopyPointToUndo	endp




SplineOperateCode	ends

SplineObjectCode	segment

UndoError	proc	near
	ERROR 	ILLEGAL_UNDO			
UndoError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineUndo

DESCRIPTION:	Undo the most recent action 

PASS:		*ds:si - VisSpline object
		ds:di  - VisSPline instance data
		es - segment of VisSplineClass record
		ss:bp - UndoActionStruct

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndo	method dynamic VisSplineClass, MSG_META_UNDO
	.enter	

	mov	ax, ss:[bp].UAS_data.UADU_flags.UADF_flags.low
	mov	bx, ss:[bp].UAS_data.UADU_flags.UADF_flags.high

	call	SplineCreateGState
	call	SplineMethodCommon

	; Unselect all selected points (either the UNDO or NEW list will be
	; made the selected list)

	call	SplineUnselectAll

	push	bx, di, si, bp
EC <	cmp	bx, UndoType			>
EC <	ERROR_A	ILLEGAL_CALL_TABLE_VALUE	>

	call	cs:[SplineUndoCalls][bx]
	pop	bx, di, si, bp

	;
	; Draw selected points
	;

	call	SplineDrawSelectedPoints


	; Set the UNDO type for a possible REDO.  If UndoType is zero,
	; then the undo chain has already been dealt with.

	mov	ax, cs:[bx].SplineRedoValues
	tst	ax
	jz	afterInitUndo
	call	SplineInitUndo
afterInitUndo:

	; Determine if Vis bounds should change

	call	SplineRecalcVisBounds
	
	; Free scratch chunk, unlock mem block

	call	SplineDestroyGState
	call	SplineEndmCommon 
	.leave
	ret
SplineUndo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoFreeingAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Free the data associated with the undo action being freed

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
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineUndoFreeingAction	method	dynamic	VisSplineClass, 
					MSG_META_UNDO_FREEING_ACTION
		.enter
		mov	ax, ss:[bp].UAS_data.UADU_flags.UADF_flags.low
		mov	bx, ss:[bp].UAS_data.UADU_flags.UADF_flags.high

		call	SplineMethodCommon

EC < 		cmp	bx, UT_LINE_ATTR				>
EC <		je	ok						>
EC <		cmp	bx, UT_AREA_ATTR				>
EC <		ERROR_NE ILLEGAL_UNDO					>
EC < ok:								>
		call	LMemFree
		call	SplineEndmCommon 
		.leave
		ret
SplineUndoFreeingAction	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoInsertAnchors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo an "Insert anchors" or a SUBDIVIDE operation
		- delete anchors and controls of the NEW list
		- copy UNDO controls to POINTS

CALLED BY:	SplineUndo

PASS:		es:bp 	- VisSplineInstance data
		*ds:si 	- points array
		ax	- subdivision parameter

RETURN:		cx 	- subdivision parameter

DESTROYED:	ax, bx, dx, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoInsertAnchors	proc near
		.enter
		push	ax		; subdivision param

	; Add the PREV of every NEW point to the SELECTED list

		mov	al, SOT_SELECT_POINT
		mov	bx, mask SWPF_PREV_ANCHOR
		call	SplineOperateOnNewPoints

	; Delete all anchors/controls in the "NEW" list

		mov	al, SOT_DELETE
		mov	bx, SWP_CONTROLS
		call	SplineOperateOnNewPoints

		mov	bx, mask SWPF_ANCHOR_POINT
		call	SplineOperateOnNewPoints

	; copy control points to their old positions

		mov	al, SOUT_COPY_TO_POINTS
		call	SplineOperateOnUndoPoints

	; Copy selected list to NEW (in case of REDO)

		call	SplineCopySelectedToNew
	
		call	SplineInvalidate

		pop	cx		; subdivision param
		.leave
		ret
SplineUndoInsertAnchors	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRedoInsertAnchors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redo an insert-anchors that's just been undone

CALLED BY:	SplineUndo 

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRedoInsertAnchors	proc near
	mov	ax, MSG_SPLINE_INSERT_ANCHORS
	GOTO	SplineRedoCommon
SplineRedoInsertAnchors	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRedoSubdivide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redo a beginner-edit style subdivision.

CALLED BY:	SplineUndo

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ax - subdivide param

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRedoSubdivide	proc near
	class	VisSplineClass

	push	ax			; subdivide param 

	; get point number of NEW point
	push	si			; points array
	mov	si, es:[bp].VSI_newPoints
	clr	ax
	call	ChunkArrayElementToPtr
	mov	ax, ds:[di]		; point number
	pop	si

	; now perform the subdivision

	pop	cx
	call	SplineSubdivideOnParam

	ret
SplineRedoSubdivide	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoDeleteAnchors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo a "delete anchors"

CALLED BY:	SplineUndo 

PASS:		es:bp - VisSplineInstance data 

RETURN:		

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoDeleteAnchors	proc near
	.enter

	; Draw (erase) the mouse sprite.

	call	SplineDrawFromLastAnchorToMouse

	;
	; Invalidate the points listed in the NEW array
	;

	mov	ax, SOT_INVALIDATE
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnNewPoints

	;
	; Insert the UNDO points into the points array
	;

	mov	al, SOUT_INSERT_IN_POINTS
	call	SplineOperateOnUndoPoints

	;
	; Make them selected
	;

	mov	al, SOUT_MAKE_SELECTED
	call	SplineOperateOnUndoPoints

	movL	ax, SOT_INVALIDATE
	mov	bx, SWP_BOTH_CURVES
	call	SplineOperateOnSelectedPointsFar

	;
	; redraw the mouse sprite
	;

	call	SplineDrawFromLastAnchorToMouse

	call	SplineCopySelectedToNew
	.leave
	ret
SplineUndoDeleteAnchors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRedoDeleteAnchors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redo a "delete anchors" op that was previously undone

CALLED BY:	SplineUndo 

PASS:		es:bp - VisSplineInstance data 

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRedoDeleteAnchors	proc near
	mov	ax, MSG_SPLINE_DELETE_ANCHORS
	GOTO	SplineRedoCommon
SplineRedoDeleteAnchors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoInsertControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo an "insert controls" operation

CALLED BY:	SplineUndo

PASS:		es:bp - VisSplineInstance data
		*ds:si - Points array

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoInsertControls	proc near
	mov	ax, MSG_SPLINE_DELETE_CONTROLS
	GOTO	SplineRedoCommon
SplineUndoInsertControls	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoDeleteControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo a "delete controls" by inserting the UNDO points
		back into the POINTS array

CALLED BY:	SplineUndo 

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 
RETURN:		nothing

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoDeleteControls	proc near	


	; Insert the UNDO points into the points array

        mov	al, SOUT_INSERT_IN_POINTS
	call	SplineOperateOnUndoPoints

	mov	al, SOUT_MAKE_SELECTED
	call	SplineOperateOnUndoPoints

	movL	ax, SOT_INVALIDATE
	mov	bx, SWP_BOTH_CURVES
	call	SplineOperateOnSelectedPointsFar


	;
	; Copy the SELECTED array to the NEW array, since a REDO
	; operation will use this array to select the points
	;
	
	call	SplineCopySelectedToNew
	ret	
SplineUndoDeleteControls	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRedoDeleteControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redo a "delete controls"

CALLED BY: 	SplineUndo 

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 
RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRedoDeleteControls	proc near
	mov	ax, MSG_SPLINE_DELETE_CONTROLS
	GOTO	SplineRedoCommon
SplineRedoDeleteControls	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRedoCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform one of the various REDO operations by copying
		the NEW list to SELECTED, and sending a message to
		myself to operate on the SELECTED list.

CALLED BY:	Various SplineUndo... procedures

PASS:		ax - message to send to myself
		es:bp - VisSplineInstance data 	
		ds - data segment of spline's lmem block 

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRedoCommon	proc near
	push	ax
	mov	al, SOT_SELECT_POINT
	mov	bx,  mask SWPF_ANCHOR_POINT
	call	SplineOperateOnNewPoints
	pop	ax
	call	SplineSendMyselfAMessage
	ret
SplineRedoCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnUndoPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the given operation on the UNDO list

CALLED BY:	SplineUndo

PASS:		es:bp - VisSplineInstance data
		al - SplineOperateOnUndoType

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
SplineOperateOnUndoPoints	proc far	 
	class	VisSplineClass

	uses	di,bp,si,bx

	.enter

EC <	call	ECSplineInstanceAndLMemBlock	>

	mov	si, es:[bp].VSI_undoPoints
	tst	si
	jz	done

	mov	dx, es:[bp].VSI_points			; get points addr
	mov	cl, al
	mov	bx, cs
	mov	di, offset SplineOperateOnUndoPointsCB
	call	ChunkArrayEnum

done:
	.leave
	ret
SplineOperateOnUndoPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineOperateOnUndoPointsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to operate on UNDO points

CALLED BY:	ChunkArrayEnum (SplineOperateOnUndoCommon )

PASS:		*ds:dx - points array chunk handle
		ds:[di] - current UNDO point
		cl - SplineOperateOnUndoType

		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	bx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineOperateOnUndoPointsCB	proc	far
	uses	ax
	.enter

	mov	ax, ds:[di].UAE_pointNum	; get point number
	mov	si, dx				; get points chunk array

	mov	bl, cl				; undo type
	clr	bh

	; Allow routines to destroy whatever the hell they want!

	push	ax, bx, cx, dx, si, di, es
	CallTable 	bx, SplineOperateOnUndoCalls, SplineOperateOnUndoType
	pop	ax, bx, cx, dx, si, di, es

	clc
	.leave
	ret
SplineOperateOnUndoPointsCB	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSelectUndoPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cause the point whose point number is the same as that
		UNDO point to become selected.  If a control point is
		given, selects its owner (anchor).

CALLED BY:	SplineOperateOnUndoPointsCB

PASS:		ds:di - address of current undo point
		es:bp - VisSplineInstance data
		*ds:si - points array

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	
	Only select ANCHOR points.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSelectUndoPoint	proc near
	.enter
	mov	ax, ds:[di].UAE_pointNum
	call	SplineGotoAnchor
	call	SplineSelectPointFar
	.leave
	ret
SplineSelectUndoPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCopyUndoToPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the current UNDO point over its "real" counterpart.

CALLED BY:	SplineOperateOnUndoPointsCB

PASS:		ds:di - address of UNDO point
		ax - point number
		*ds:si - points array

RETURN:		nothing

DESTROYED:	cx, di, es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCopyUndoToPoint	proc near uses	si
	.enter
	push	di				; save address of UNDO point
	call	ChunkArrayElementToPtr		; get point data
EC <	ERROR_C ILLEGAL_SPLINE_POINT_NUMBER >
	segmov	es, ds,si			; prepare for copy
	cld
	pop	si				; restore addr of UNDO
						; point
	add	si, offset UAE_data		; skip past point #
	mov	cx, size SplinePointStruct
	rep	movsb
	.leave
	ret
SplineCopyUndoToPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineExchangeUndoWithPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exchange the data of the current
		UNDO point and its "real" counterpart.

CALLED BY:	SplineUndo

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ds:di - current UNDO point
		ax - current undo point number
		

RETURN:		Nothing 

DESTROYED:	ax,cx,di,si,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineExchangeUndoWithPoint	proc near
	.enter
EC <	call	ECSplineInstanceAndPoints		> 

	lea	bx, ds:[di].UAE_data		; get address of undo point.

	call	ChunkArrayElementToPtr		; get addr of REAL point
EC <	ERROR_C	ILLEGAL_SPLINE_POINT_NUMBER >
	mov	si, bx
	cld
	mov	cx, size SplinePointStruct
	segmov	es, ds

startLoop:			
	mov	al, es:[di]
	xchg	al, ds:[si]
	stosb
	inc	si
	loop	startLoop
	.leave
	ret
SplineExchangeUndoWithPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInsertUndoInPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the current UNDO point into the regular points array.

CALLED BY:	SplineOperateOnUndoPointsCB

PASS:		ax - point number
		es:bp - spline instance
		*ds:si - points array
		ds:di - pointer to UNDO point

RETURN:		nothing

DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:	
	Have to copy the point to the stack, since the block might move

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInsertUndoInPoints	proc near

	uses	es, si

passedBP	local	word	push	bp
tempPoint	local	SplinePointStruct
	.enter

	
	;
	; Copy the undo point onto the stack
	;

	push	es, si
	lea	si, ds:[di].UAE_data
	segmov	es, ss
	lea	di, ss:[tempPoint]
	mov	cx, size SplinePointStruct
	rep	movsb
	pop	es, si

	;
	; Insert the point in the array
	;

	push	bp
	mov	bp, ss:[passedBP]
	call	SplineInsertPointFar	; ds:di - point (DS may have
					; moved)
	pop	bp

	;
	; Now, copy the point off the stack into the points array
	;

	segmov	es, ds, si
	segmov	ds, ss, si
	lea	si, ss:[tempPoint]
	mov	cx, size SplinePointStruct
	rep	movsb

	segmov	ds, es		; return fixed-up DS

	.leave
	ret
SplineInsertUndoInPoints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAddDeltasToUndoPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add deltas (in the Scratch Chunk) to the UNDO point

CALLED BY:	SplineOperateOnUndoPoints

PASS:		es:bp - VisSplineInstance data 
		ds:di - current undo point

RETURN:		nothing

DESTROYED:	ax, si, di

PSEUDO CODE/STRATEGY:	
	Deltas are stored in the Scratch Chunk.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddDeltasToUndoPoint	proc near
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndLMemBlock		>

	SplineDerefScratchChunk si

	mov	ax, ds:[si].SD_deltas.P_x
	add	ds:[di].UAE_data.SPS_point.PWBF_x.WBF_int, ax
	mov	ax, ds:[si].SD_deltas.P_y
	add	ds:[di].UAE_data.SPS_point.PWBF_y.WBF_int, ax

	.leave
	ret
SplineAddDeltasToUndoPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineAddUndoToNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the current UNDO point to the NEW list

CALLED BY:	SplineOperateOnUndoPointsCB

PASS:		ds:di - current UNDO point
		es:bp - VisSplineInstance data 

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/25/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAddUndoToNew	proc near
	class	VisSplineClass 
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	> 
	mov	ax, ds:[di].UAE_pointNum
	
	mov	si, es:[bp].VSI_newPoints
	call	SplineInsertInList
	.leave
	ret
SplineAddUndoToNew	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineInitUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Since most spline actions are atomic, this routine is
		used to begin, add data, and end an undo.

CALLED BY:	UTILITY

PASS:		es:bp - VisSplineInstance data
		ds 	- data segment of spline's lmem block 
		ax	- UndoType
		cx 	- other info (depends on UndoType)

RETURN:		nothing

DESTROYED:	undo data

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitUndo	proc	far

	.enter

EC <	call	ECSplineInstanceAndLMemBlock	> 

	call	SplineUndoStartChain
	call	SplineUndoAddAction
	call	SplineUndoEndChain

	.leave
	ret
SplineInitUndo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoAddAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an action to an existing undo chain

CALLED BY:	SplineInitUndo

PASS:		ax - UndoType
		cx - undo data (depends on undo type)
		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoAddAction	proc near
	uses	ax,bx,cx,dx,di,bp
	class	VisSplineClass 
	.enter

EC <	call	ECSplineInstanceAndLMemBlock	>


	;
	; Set up any data that needs to be set up.  Do this whether or
	; not we're ignoring UNDO
	;

	mov_tr	bx, ax			; UndoType

	; Callback routine (SplineInitUndoCalls)
	; PASS:
	;	cx - undo data (depends on undo type)
	; RETURN:
	;  	 ax - value to store in UAS_data.UADU_flags.UADF_flags.low
	;  	 cx - AddUndoActionFlags
	;
	push	bx
	call	cs:[SplineInitUndoCalls][bx]
	pop	bx

	call	CheckIfIgnoring
	jc	done


	sub	sp,size AddUndoActionStruct
	mov	di, sp

	mov	ss:[di].AUAS_data.UAS_dataType, UADT_FLAGS
	mov	ss:[di].AUAS_data.UAS_data.UADU_flags.UADF_flags.low, ax
	mov	ss:[di].AUAS_data.UAS_data.UADU_flags.UADF_flags.high, bx
	mov	ss:[di].AUAS_flags, cx

	mov	ax, es:[LMBH_handle]
	mov	ss:[di].AUAS_output.handle, ax
	SplineDerefScratchChunk bx
	mov	ax, ds:[bx].SD_splineChunkHandle
	mov	ss:[di].AUAS_output.chunk,ax

	mov	bp, di
	mov	dx, size AddUndoActionStruct
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_FIXUP_ES
	call	GeodeGetProcessHandle
	mov	ax, MSG_GEN_PROCESS_UNDO_ADD_ACTION
	call	ObjMessage

	add	sp, size AddUndoActionStruct	; carry is clear
	
done:
	.leave
	ret
SplineUndoAddAction	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfIgnoring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the process is ignoring UNDO

CALLED BY:	SplineUndoStartChain, SplineUndoAddAction,
		SplineUndoEndChain

PASS:		nothing 

RETURN:		carry SET if ignoring

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfIgnoring	proc near
	uses	ax
	.enter

	call	GenProcessUndoCheckIfIgnoring
	tst	ax
	jz	done
	stc
done:
	.leave
	ret
CheckIfIgnoring	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoStartChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin an undo chain

CALLED BY:	UTILITY

PASS:		ax - UndoType
		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoStartChain	proc near
	uses	ax,bx,cx,di
	class	VisSplineClass 
	.enter

	call	CheckIfIgnoring
	jc	done

	sub	sp,size StartUndoChainStruct
	mov	di, sp

	mov_tr	bx, ax		; UndoType
	shl	bx
	movdw	ss:[di].SUCS_title, cs:[undoStrings][bx], ax

	mov	ax, es:[LMBH_handle]
	mov	ss:[di].SUCS_owner.handle, ax

	SplineDerefScratchChunk bx
	mov	ax, ds:[bx].SD_splineChunkHandle
	mov	ss:[di].SUCS_owner.chunk, ax

	push	bp
	mov	bp, di
	call	GeodeGetProcessHandle
	mov	dx, size StartUndoChainStruct
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES or mask MF_STACK
	mov	ax, MSG_GEN_PROCESS_UNDO_START_CHAIN
	call	ObjMessage
	pop	bp
	add	sp, size StartUndoChainStruct	; carry is clear

done:
	.leave
	ret
SplineUndoStartChain	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoEndChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	finish sending undo data to the process

CALLED BY:	UTILITY

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoEndChain	proc near
	uses	ax,bx,cx,di
	.enter

	call	CheckIfIgnoring
	jc	done

	mov	cx, sp					;non zero
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	mov	ax, MSG_GEN_PROCESS_UNDO_END_CHAIN
	call	ObjMessage
	clc
done:
	.leave
	ret
SplineUndoEndChain	endp



undoStrings	optr	\
	0,		; 	UT_NONE	
	lineAttrStr,	; 	UT_LINE_ATTR
	areaAttrStr,	; 	UT_AREA_ATTR
	moveStr,	; 	UT_MOVE	
	0,		; 	UT_UNDO_MOVE
	insertStr,	; 	UT_SUBDIVIDE 
	0,		; 	UT_UNDO_SUBDIVIDE 
	insertStr,	; 	UT_INSERT_ANCHORS 
	0,		; 	UT_UNDO_INSERT_ANCHORS
	deleteStr,	; 	UT_DELETE_ANCHORS
	0,		; 	UT_UNDO_DELETE_ANCHORS
	curvyStr,	; 	UT_INSERT_CONTROLS
	straightStr,	; 	UT_DELETE_CONTROLS
	0,		; 	UT_UNDO_DELETE_CONTROLS
	addStr,		; 	UT_ADD_POINT
	openStr,	; 	UT_OPEN_CURVE
	closeStr	; 	UT_CLOSE_CURVE

.assert (size undoStrings eq UndoType*2)




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitUndoSubdivide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize undo data for a SUBDIVIDE operation

CALLED BY:	SplineInitUndo

PASS:		es:bp - VisSplineInstance
		cx - subdivide param

RETURN:		ax - subdivide param

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
		Preserve CX around array-initialization

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/19/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitUndoSubdivide	proc near
		push	cx			; subdivide param
		call	SplineInitUndoAndNew
		pop	ax			; return in AX
		ret
SplineInitUndoSubdivide	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitRedoSubdivide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the subdivide param in AX

CALLED BY:	SplineInitUndo

PASS:		cx - subdivide param

RETURN:		ax - subdivide param

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/19/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitRedoSubdivide	proc near
		mov_tr	ax, cx
		clr	cx
		ret
SplineInitRedoSubdivide	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitUndoLineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the Line Attributes chunk of the UNDO data.
		Copy the spline's current LineAttributes stuff to the
		Undo chunk
		

CALLED BY:	SplineInitUndo

PASS:		es:bp - VisSplineInstance data

RETURN:		cx - AUAF_NOTIFY_BEFORE_FREEING

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/13/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitUndoLineAttr	proc near 	uses	dx
	class	VisSplineClass
	.enter
	mov	dx, offset VSI_lineAttr
	call	SplineInitUndoAttrsCommon
	.leave
	ret
SplineInitUndoLineAttr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitUndoAreaAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the UNDO area attributes 

CALLED BY:	SplineInitUndo

PASS:		es:bp - VisSplineInstance data

RETURN:		cx - AUAF_NOTIFY_BEFORE_FREEING

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/13/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitUndoAreaAttr	proc near 	uses	cx,dx
	class	VisSplineClass
	.enter
	mov	dx, offset VSI_areaAttr
	call	SplineInitUndoAttrsCommon
	.leave
	ret
SplineInitUndoAreaAttr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitUndoAttrsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the UNDO data structures for either of
		the line/area  attribute change operations

CALLED BY:	SplineInitUndoLineAttrs, SplineInitUndoAreaAttrs

PASS:		es:bp - VisSplineInstance data
		dx - offset from start of VSI data where source data resides

RETURN:		ax - word of data to store in the undo action
		cx - AUAF_NOTIFY_BEFORE_FREEING

DESTROYED:	bx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/13/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitUndoAttrsCommon	proc near 	

	class	VisSplineClass 
	.enter

	mov	di, dx
	mov	si, es:[bp][di]		; get chunk handle of source

	;
	; Allocate a new chunk 
	;

	ChunkSizeHandle	ds, si, cx

	clr	al
	call	LMemAlloc

	mov	di, ax			; new chunk handle
	call	SplineCopyChunk

	mov_tr	ax, di			; return new chunk handle
	mov	cx, mask AUAF_NOTIFY_BEFORE_FREEING

	.leave
	ret
SplineInitUndoAttrsCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitUndoArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the undo points array, and set the
		UI_POINTS_VALID chunk

CALLED BY:	SplineInitUndo

PASS:		es:bp - VisSplineInstance data

RETURN:		cx - 0

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/13/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitUndoArray	proc near 	
	uses	bx,di
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	> 

	mov	bx, size UndoArrayElement
	lea	di, es:[bp].VSI_undoPoints
	call	SplineInitUndoArrayCommon
	.leave
	ret
SplineInitUndoArray	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitUndoAndNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize both the UNDO array and the NEW POINTS array

CALLED BY:	

PASS:		es:bp - VisSplineInstance data 

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitUndoAndNew	proc near
	call	SplineInitUndoArray
	FALL_THRU	SplineInitializeNewArray
SplineInitUndoAndNew	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitializeNewArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the NEW POINTS array

CALLED BY:

PASS:		es:bp - VisSplineInstance data 

RETURN:		cx - 0

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitializeNewArray	proc	near

	class	VisSplineClass 

	.enter

	mov	bx, size SelectedListEntry
	lea	di, es:[bp].VSI_newPoints
	call	SplineInitUndoArrayCommon
	.leave
	ret
SplineInitializeNewArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInitUndoArrayCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize either the UNDO or NEW POINTS array

CALLED BY:	SplineInitUndoArray, SplineInitializeNewArray

PASS:		bx - size of array element
		ds - segment of lmem block in which to place array
		es:di - place where chunk handle resides

RETURN:		cx - 0

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	If the array already exists, then zero it	
	We don't want to be notified when the undo action is freed,
	because we keep the undo information around regardless, as
	it's used for drawing, etc.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInitUndoArrayCommon	proc	near
	uses	ax,si

	.enter

	;
	; If the existing array hasn't been freed, then exit.
	;

	mov	si, es:[di]
	tst	si
	jnz	zeroIt

	;
	; create new chunk array
	;

	mov	ax, si		; clr	ax, cx
	mov	cx, si
	call	ChunkArrayCreate
	mov	es:[di], si
done:
	clr	cx		; no AddUndoActionFlags
	.leave
	ret
zeroIt:
	call	ChunkArrayZero
	jmp	done

SplineInitUndoArrayCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCopyChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a chunk from one place to the next

CALLED BY:	SplineInitUndoAttrsCommon

PASS:		*ds:si - source
		*ds:di - target
		
RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:		Assume chunks don't overlap

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/13/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCopyChunk	proc 	near 	
	uses	cx,di,si,es
	.enter
	segmov	es, ds
	cld
	mov	si, ds:[si]
	mov	di, ds:[di]
	ChunkSizePtr	ds, si, cx
	rep	movsb
	.leave
	ret
SplineCopyChunk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoLineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exchange the UNDO line attributes and the VSI line
		attributes. Inval the whole mess.
	
CALLED BY:	SplineUndo

PASS:		es:bp - VisSplineInstance data


RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoLineAttr	proc near
	class	VisSplineClass
	.enter

	;
	; Copy the old line attrs struct in
	;


	call	SplineInvalidate
	.leave
	ret
SplineUndoLineAttr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoAreaAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exchange the UNDO area attributes and the VSI area
		attributes.  Inval the entire object

CALLED BY:	SplineUndo

PASS:		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoAreaAttr	proc near
	class	VisSplineClass
	.enter


	;
	; Copy the old area attrs struct in
	;

	call	SplineInvalidate
	.leave
	ret
SplineUndoAreaAttr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo a MOVE operation.
		Select all the UNDO points, do an INVAL on selected,
		and then exchange UNDO and normal point positions.

CALLED BY:	SplineUndo

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 

RETURN:		nothing

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoMove	proc near 
	.enter
EC <	call	ECSplineInstanceAndPoints		> 

	; Select UNDO points

	mov	al, SOUT_MAKE_SELECTED
	call	SplineOperateOnUndoPoints

	; INVAL selected

	movL	ax, SOT_INVALIDATE
	mov	bx, SWP_BOTH_CURVES
	call	SplineOperateOnSelectedPointsFar

	; exchange new and old

	mov	al, SOUT_EXCHANGE_WITH_POINTS
	call	SplineOperateOnUndoPoints	

	; INVAL selected

	movL	ax, SOT_INVALIDATE
	mov	bx, SWP_BOTH_CURVES
	call	SplineOperateOnSelectedPointsFar

	.leave
	ret
SplineUndoMove	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCopySelectedToNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the "selected points" list to the NEW points array

CALLED BY:	InsertControls

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/24/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCopySelectedToNew	proc	far
	uses	ax,cx,di,si
 	class	VisSplineClass 
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	> 

	; Get handle and size of selected list
	 
	mov	si, es:[bp].VSI_selectedPoints
	ChunkSizeHandle	ds, si, cx

	mov	ax, es:[bp].VSI_newPoints
	tst	ax
	jnz	reAlloc
	call	LMemAlloc
	mov	es:[bp].VSI_newPoints, ax
	jmp	copy

reAlloc:
	call	LMemReAlloc
copy:
	mov	di, ax
	call	SplineCopyChunk	

	.leave
	ret
SplineCopySelectedToNew	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoAddPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo the adding of a point in create mode

CALLED BY:	SplineUndo

PASS:		es:bp - spline
		*ds:si - points

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoAddPoint	proc near
		.enter

	;
	; Select the last point, which, for some reason, gets
	; unselected by SplineUndo.
	;
		call	SplineGotoLastAnchor
		jc	done

		call	SplineSelectPointFar

		mov	ax, MSG_SPLINE_DELETE_ANCHORS
		call	SplineSendMyselfAMessage

done:
		.leave
		ret
SplineUndoAddPoint	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoCloseCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo a CLOSE CURVE by opening the curve

CALLED BY:

PASS:		es:bp - VisSplineInstance
		ds - segment of spline's lmem block

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoCloseCurve	proc near
	mov	ax, MSG_SPLINE_OPEN_CURVE
	call	SplineSendMyselfAMessage
	ret
SplineUndoCloseCurve	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUndoOpenCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the curve

CALLED BY:

PASS:		es:bp - VisSplineInstance
		ds - segment of spline's lmem block

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUndoOpenCurve	proc near
	mov	ax, MSG_SPLINE_CLOSE_CURVE
	call	SplineSendMyselfAMessage
	ret
SplineUndoOpenCurve	endp



SplineObjectCode	ends

