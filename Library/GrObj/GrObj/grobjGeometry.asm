COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GrObj
MODULE:		GrObj
FILE:		grobjGeometry.asm

AUTHOR:		Steve Scholl, Mar 3, 1992

Routines:
	Name			Description
	----			-----------
GrObjBeginGeometryCommon
GrObjEndGeometryCommon
GrObjInitializeInsertDeleteWorkingData
GrObjCalcInsertDeleteWorkingData
GrObjAxisInsert
GrObjAxisDelete
GrObjConsiderParamsAndPermissions
GrObjConsiderAxisParamsAndPermissions
GrObjDoInsertDeleteGeometry
GrObjCalcInsertDeleteAxisMove
GrObjCalcInsertDeleteAxisScale
GrObjGenerateUndoRotateChain
GrObjGenerateUndoMoveChain
GrObjGenerateUndoScaleChain
GrObjGenerateUndoSkewChain
GrObjGenerateUndoTransformChain

Method Handlers:
	Name			Description
	----			-----------
GrObjMove	
GrObjRotate
GrObjSkew
GrObjNudge
GrObjAlign
GrObjSetSize
GrObjGetSize
GrObjSetPosition
GrObjGetPosition
GrObjScale
GrObjTransform
GrObjInsertOrDeleteSpace

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
		

	$Id: grobjGeometry.asm,v 1.2 98/01/26 20:43:49 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjExtNonInteractiveCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBeginGeometryCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform some common functionality for the methods
		the do geometry manipulations on a grobject

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBeginGeometryCommon		proc	far
	uses	ax,di,dx
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	;    Get gstate to pass with handle drawing messages
	;

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;gstate

	;    Erase handle of object in case it is selected
	;

	mov	ax,MSG_GO_UNDRAW_HANDLES
	call	ObjCallInstanceNoLock

	;    Invalidate original bounds of object
	;

	call	GrObjOptInvalidate

	mov	di,dx
	call	GrDestroyState

	.leave
	ret
GrObjBeginGeometryCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEndGeometryCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform some common functionality for the methods
		the do geometry manipulations on a grobject

CALLED BY:	INTERNAL
		GrObjMove
		GrObjRotate

PASS:		
		*ds:si - GrObject

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEndGeometryCommon		proc	far
	uses	ax,di,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	;    Get gstate to pass with handle drawing messages
	;

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;gstate

	;    Invalidate object at new position
	;

	call	GrObjOptInvalidate
	
	;    Redraw handles of object if it is selected
	;

	mov	ax,MSG_GO_DRAW_HANDLES
	call	ObjCallInstanceNoLock

	mov	di,dx					;handles gstate
	call	GrDestroyState

	.leave
	ret
GrObjEndGeometryCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move object relative to its current position

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - PointDWFixed - amount to move in DOCUMENT coords

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			GrObject will be selected, so create one gstate for
			UNDRAW_HANDLES and DRAW_HANDLES

			Move amount will not be zero

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMove method dynamic GrObjClass, MSG_GO_MOVE
	uses	ax, dx
	.enter

	call	GrObjCanMove?
	jnc	done

	;    See if the passed amount to move is nonzero
	;    Check low int's first, since they're most likely to
	;    be non-zero
	;    

	mov	ax, ss:[bp].PDF_x.DWF_int.low
	or	ax, ss:[bp].PDF_y.DWF_int.low
	jz	checkOther

doMove:
	push	bp					;stack frame
	mov	bp,GOANT_PRE_MOVE
	call	GrObjOptNotifyAction
	pop	bp					;stack frame

	call	GrObjGenerateUndoMoveChain
	call	GrObjBeginGeometryCommon
	call	GrObjMoveNormalRelative

	mov	bp,GOANT_MOVED
	mov	ax,MSG_GO_COMPLETE_TRANSLATE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

checkOther:
	or	ax, ss:[bp].PDF_x.DWF_frac
	or	ax, ss:[bp].PDF_y.DWF_frac
	or	ax, ss:[bp].PDF_x.DWF_int.high
	or	ax, ss:[bp].PDF_y.DWF_int.high
	jnz	doMove
	jmp	done
	

GrObjMove		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoMoveChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for a move action

CALLED BY:	INTERNAL
		GrObjEndMove
		GrObjMove

PASS:		*ds:si - object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoMoveChain		proc	far
	uses	ax,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	cx,handle moveString
	mov	dx,offset moveString
	mov	ax,MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjGenerateUndoMoveChain		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMoveCenterAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move object's center to the passed point

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - PointDWFixed

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		This method should be optimized for SMALL SIZE over SPEED

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMoveCenterAbs method dynamic GrObjClass, MSG_GO_MOVE_CENTER_ABS
	uses	ax, dx
	.enter

	call	GrObjCanMove?
	jnc	done

	push	bp					;stack frame
	mov	bp,GOANT_PRE_MOVE
	call	GrObjOptNotifyAction
	pop	bp					;stack frame

	call	GrObjGenerateUndoMoveChain
	call	GrObjBeginGeometryCommon
	call	GrObjMoveNormalAbsolute

	mov	bp,GOANT_MOVED
	mov	ax,MSG_GO_COMPLETE_TRANSLATE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GrObjMoveCenterAbs		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate a grobject

PASS:		
		*(ds:si) - instance data
		cx:dx - WWFixed degrees of counter clockwise rotation
		bp low - GrObjHandleSpecification to rotate about

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			GrObject will be selected, so create one gstate for
			UNDRAW_HANDLES and DRAW_HANDLES

			Rotation will not be zero

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRotate method dynamic GrObjClass, MSG_GO_ROTATE
	uses	ax,cx,dx,bp
	.enter

	call	GrObjCanRotate?
	jnc	done
	
	;    See if passed rotation is non-zero
	;   

	jcxz	checkFrac
	
doRotate:
	push	bp					;stack frame
	mov	bp,GOANT_PRE_ROTATE
	call	GrObjOptNotifyAction
	pop	bp					;stack frame

	call	GrObjGenerateUndoRotateChain

	call	GrObjBeginGeometryCommon

	;    Create stack frame for rotate data
	;    and rotate the baby.
	;

	mov	ax,bp					;GrObjHandleSpec
	sub	sp,size WWFixed
	mov	bp,sp
	mov	ss:[bp].WWF_int,cx
	mov	ss:[bp].WWF_frac,dx
	mov	cl,al					;GrObjHandleSpec
	call	GrObjRotateNormalRelative
	add	sp, size WWFixed

	mov	bp,GOANT_ROTATED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock

done:
	.leave
	ret


checkFrac:
	tst	dx
	jnz	doRotate
	jmp	done

GrObjRotate		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUntransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Untransform a grobject

PASS:		
		*(ds:si) - instance data
		cx:dx - WWFixed degrees of counter clockwise rotation
		bp low - GrObjHandleSpecification to untransform about

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			GrObject will be selected, so create one gstate for
			UNDRAW_HANDLES and DRAW_HANDLES

			Rotation will not be zero

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUntransform method dynamic GrObjClass, MSG_GO_UNTRANSFORM
	uses	bp
	.enter

	call	GrObjCanTransform?
	jnc	done
	
	push	bp					;GOHS
	mov	bp,GOANT_PRE_TRANSFORM
	call	GrObjOptNotifyAction
	pop	bp					;GOHS

	call	GrObjGenerateUndoTransformChain

	call	GrObjBeginGeometryCommon

	;    Create stack frame for untransform data
	;    and untransform the baby.
	;

	AccessNormalTransformChunk	di, ds, si

	;
	;  Set the transform = I
	;
	clr	ax
	clrwwf	ds:[di].OT_transform.GTM_e12, ax
	clrwwf	ds:[di].OT_transform.GTM_e21, ax

	mov	ds:[di].OT_transform.GTM_e11.WWF_frac, ax
	mov	ds:[di].OT_transform.GTM_e22.WWF_frac, ax
	inc	ax
	mov	ds:[di].OT_transform.GTM_e11.WWF_int, ax
	mov	ds:[di].OT_transform.GTM_e22.WWF_int, ax

	mov	bp,GOANT_TRANSFORMED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GrObjUntransform		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoRotateChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for a rotate action

CALLED BY:	INTERNAL
		GrObjEndRotate
		GrObjRotate

PASS:		*ds:si - object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoRotateChain		proc	far
	uses	ax,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	cx,handle rotateString
	mov	dx,offset rotateString
	mov	ax,MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjGenerateUndoRotateChain		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a grobject. [current matrix][scale]
		
    		If called by MSG_GO_FLIP, the undo string is flipString
		instead of scaleString.

CALLED BY:	MSG_GO_SCALE
		MSG_GO_FLIP
		
PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjScaleData
			GOSD_scale - scale factors

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			GrObject will be selected

			scale will not be 1x1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/90		Initial version
	JimG	7/27/94		Made this the handler for MSG_GO_FLIP

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScale method dynamic GrObjClass, MSG_GO_SCALE,
				      MSG_GO_FLIP
	uses	ax,cx,dx,bp
	.enter

	call	GrObjCanResize?
	jnc	done
	
	;    See if passed scale is 1x1
	;   

	cmp	ss:[bp].GOASD_scale.GOSD_xScale.WWF_int,1
	je	checkOthers

	
doScale:
	push	bp					;stack frame
	mov	bp,GOANT_PRE_RESIZE
	call	GrObjOptNotifyAction
	pop	bp					;stack frame

	cmp	ax, MSG_GO_FLIP
	je	generateFlipUndo
	
	call	GrObjGenerateUndoScaleChain

beginGeometryCommon:
	call	GrObjBeginGeometryCommon

	call	GrObjScaleNormalRelative

	mov	bp,GOANT_RESIZED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock

done:
	.leave
	ret


checkOthers:
	tst	ss:[bp].GOASD_scale.GOSD_xScale.WWF_frac
	jnz	doScale
	cmp	ss:[bp].GOASD_scale.GOSD_yScale.WWF_int,1
	jne	doScale
	tst	ss:[bp].GOASD_scale.GOSD_yScale.WWF_frac
	jnz	doScale
	jmp	done
	
    	;
	; Same as GrObjGenerateUndoScaleChain EXCEPT that it uses flipString
	; instead of scaleString.
	;
	; Destroys ax, cx, dx
	;
generateFlipUndo:
	mov	cx, handle flipString
	mov	dx, offset flipString
	mov	ax, MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	call	ObjCallInstanceNoLock
	jmp	beginGeometryCommon
	

GrObjScale		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjScaleObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a grobject in its own coordinates.
		[current matrix][scale]

PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjScaleData
			GOSD_scale - scale factors

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			GrObject will be selected

			scale will not be 1x1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleObject method dynamic GrObjClass, MSG_GO_SCALE_OBJECT
	uses	ax,cx,dx,bp
	.enter

	call	GrObjCanResize?
	jnc	done
	
	;    See if passed scale is 1x1
	;   

	cmp	ss:[bp].GOASD_scale.GOSD_xScale.WWF_int,1
	je	checkOthers

	
doScale:
	call	GrObjGenerateUndoScaleChain
	call	GrObjBeginGeometryCommon

	mov	cl, HANDLE_CENTER
	call	GrObjScaleNormalRelativeOBJECT

	mov	bp,GOANT_RESIZED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock

done:
	.leave
	ret


checkOthers:
	tst	ss:[bp].GOASD_scale.GOSD_xScale.WWF_frac
	jnz	doScale
	cmp	ss:[bp].GOASD_scale.GOSD_yScale.WWF_int,1
	jne	doScale
	tst	ss:[bp].GOASD_scale.GOSD_yScale.WWF_frac
	jnz	doScale
	jmp	done

GrObjScaleObject		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoScaleChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for a scale action

CALLED BY:	INTERNAL
		GrObjScale

PASS:		*ds:si - object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoScaleChain		proc	far
	uses	ax,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	cx,handle scaleString
	mov	dx,offset scaleString
	mov	ax,MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjGenerateUndoScaleChain		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSkew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skew a grobject

PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjSkewData
			GOSD_xDegrees - x skew degrees
			GOSD_yDegrees - y skew degrees

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			GrObject will be selected

			skew will not be zero

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSkew method dynamic GrObjClass, MSG_GO_SKEW
	uses	ax,cx,dx,bp
	.enter

	call	GrObjCanSkew?
	jnc	done
	
	;    See if passed skew is non-zero
	;   

	tst	ss:[bp].GOSD_xDegrees.WWF_int
	jz	checkOthers

	
doSkew:
	push	bp					;stack frame
	mov	bp,GOANT_PRE_SKEW
	call	GrObjOptNotifyAction
	pop	bp					;stack frame

	call	GrObjGenerateUndoSkewChain
	call	GrObjBeginGeometryCommon

	call	GrObjSkewNormalRelative

	mov	bp,GOANT_SKEWED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock

done:
	.leave
	ret


checkOthers:
	tst	ss:[bp].GOSD_xDegrees.WWF_frac
	jnz	doSkew
	tst	ss:[bp].GOSD_yDegrees.WWF_int
	jnz	doSkew
	tst	ss:[bp].GOSD_yDegrees.WWF_frac
	jnz	doSkew
	jmp	done

GrObjSkew		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoSkewChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for a skew action

CALLED BY:	INTERNAL
		GrObjSkew

PASS:		*ds:si - object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoSkewChain		proc	far
	uses	ax,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	cx,handle skewString
	mov	dx,offset skewString
	mov	ax,MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjGenerateUndoSkewChain		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjNudge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nudge a grobj in screen units.  
		Particularly useful for moving one pixel on the
		screen regardless of the scale view

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx - number of x units to move
		dx - number of y units to move

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Does boundary check to be sure that the object is not nudged
		outside of the body's bounds.  This routine will either to the
		nudge as requested, or none at all; i.e., if a diagonal
		nudge is requested and that nudge will move the object out of
		the document bounds only in one direction, the nudge will
		be aborted rather than only nudging in the in-bounds direction.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/21/92		Initial version
	JimG	7/12/94		Added boundary check to prevent nudging out
				of body bounds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNudge	method dynamic GrObjClass, MSG_GO_NUDGE
	uses	ax,cx,dx
	
	; Check to see if object can move at all before pushing registers or
	; allocating stack space.
	call	GrObjCanMove?
	jnc	exit

originalXDelta	local		word			push cx
originalYDelta	local		word			push dx
deltaPoint	local		PointDWFixed
centerPoint	local		PointDWFixed	
boundaryRect	local		RectDWord
visibleParams	local		MakeRectVisibleParams
	
; Inherited locals
ForceRef	originalXDelta
ForceRef	originalYDelta
ForceRef	centerPoint
ForceRef	boundaryRect
ForceRef	visibleParams
	.enter

	; If both cx and dx are 0, then just get outta' here.. no sense in
	; messing around.
	mov	ax, cx
	or	ax, dx
	jz	done
	
	call	GrObjGetCurrentNudgeUnits

	push	dx,bx					;y num units, unit
	mov	dx,cx					;x num units int
	clr	bx, cx					;clr x num units frac
	xchg	bl, ah					;bl <- x unit int, ah 0
	xchg	ah, al					;ah <- x unit f, al 0
	call	GrMulWWFixed
	mov_tr	ax, dx
	cwd
	mov	ss:[deltaPoint].PDF_x.DWF_int.high, dx
	mov	ss:[deltaPoint].PDF_x.DWF_int.low, ax
	mov	ss:[deltaPoint].PDF_x.DWF_frac,cx

	pop	dx,ax					;y num units, unit
	clr	bx, cx					;clr y num units frac
	xchg	bl, ah					;bl <- y unit int, ah 0
	xchg	ah, al					;ah <- y unit f, al 0
	call	GrMulWWFixed
	mov_tr	ax, dx
	cwd
	mov	ss:[deltaPoint].PDF_y.DWF_int.high, dx
	mov	ss:[deltaPoint].PDF_y.DWF_int.low, ax
	mov	ss:[deltaPoint].PDF_y.DWF_frac,cx
	
if KEEP_NUDGE_ON_DOC
	; If this is a paste inside object, don't do any boundary testing.
	test	ds:[di].GOI_attrFlags, mask GOAF_PASTE_INSIDE
	jnz	doMove
	
	call	GrObjCheckIfNudgeIsInsideBounds
	jc	done					;invalid nudge, bail
	
doMove:
endif
	; Do the move
	push	bp
	lea	bp, ss:[deltaPoint]
	mov	ax,MSG_GO_MOVE
	call	ObjCallInstanceNoLock
	pop	bp
	
if RECENTER_ON_NUDGE
	;
	; 1/24/98: See grobjConstant.def re: ND-000081 -- eca
	;

	; If the object is not a paste inside, please ensure that it is
	; still visible to the user.
	mov	di, ds:[si]
	add	di, ds:[di].GrObj_offset
	test	ds:[di].GOI_attrFlags, mask GOAF_PASTE_INSIDE
	jnz	done
	
	call	GrObjEnsureObjectIsOnScreen
endif

done:
	.leave
	
exit:
	ret
GrObjNudge		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCheckIfNudgeIsInsideBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by GrObjNudge.  Checks if the nudge
		will result in the object's center remaining within the
		body's boundaries.

CALLED BY:	GrObjNudge	INTERNAL
PASS:		*ds:si	- instance data of GrObj object
		ss:bp	- inherited locals from GrObjNudge
		
RETURN:		carry:	set if move is invalid
			clear if move is okay
		ss:[centerPoint]: if the move is valid, this is updated to
			reflect	the new center point
			
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Does boundary check to be sure that the object is not nudged
		outside of the body's bounds.  This routine will either to the
		nudge as requested, or none at all; i.e., if a diagonal
		nudge is requested and that nudge will move the object out of
		the document bounds only in one direction, the nudge will
		be aborted rather than only nudging in the in-bounds direction.
		
		NOTE: could by off by [0,1) (in document space) because we
		round the value of the center of the object since the body
		bounds come back to us as integers.  But this is not really
		a problem, just FYI.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if KEEP_NUDGE_ON_DOC
	;
	; 1/26/98: See grobjConstant.def re: ND-000xxx -- eca
	;
GrObjCheckIfNudgeIsInsideBounds	proc	near
	.enter	inherit GrObjNudge
	
	; Get the boundary of the body and get the old center of the object.
	; Calculate the new center of the object and determine if the new
	; center is going to be out-of-bounds.  If this is the case, then do
	; not permit the move.  This is to prevent the user from "nudging"
	; an object irretrievably out of the document.
	
	; Get boundary of the body.
	mov	bx, bp					;save local ptr
	mov	ax, MSG_GB_GET_BOUNDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	lea	bp, ss:[boundaryRect]
	call	GrObjMessageToBody
	
	; Get the center of the object
	mov	bp, bx					;get local ptr
	mov	ax, MSG_GO_GET_CENTER
	lea	bp, ss:[centerPoint]
	call	ObjCallInstanceNoLock
	mov	bp, bx					;restore local ptr
	
	mov	di, ss:[originalXDelta]
	mov	dx, ss:[originalYDelta]
	
	; If y delta == 0, then we can skip testing the Y edge and we also
	; know that the x delta != 0 because if they were both zero, we
	; would not be here.  So, jump into the "test x" code AFTER testing
	; for zero.
	tst	dx
	jz	testXEdgeNotZero
	
	; Calculate the new y center of the object (rounded to DWord)
	movdwf	cxbxax, ss:[centerPoint].PDF_y
	adddwf	cxbxax, ss:[deltaPoint].PDF_y
	movdwf	ss:[centerPoint].PDF_y, cxbxax
	rnddwf	cxbxax
	
	; Decide whether to check the top or the bottom
	tst	dx
	js	isTopEdge
	
	; if the center is past the bottom, do NOT move
	jgdw	cxbx, ss:[boundaryRect].RD_bottom, moveIsInvalid
	jmp	testXEdge

isTopEdge:
	; if the center is past the top, do NOT move
	jldw	cxbx, ss:[boundaryRect].RD_top, moveIsInvalid
	
testXEdge:
	tst	di					;original x delta
	jz	moveIsOkay	
	
testXEdgeNotZero:
	; Calculate the new x center of the object (rounded to DWord)
	movdwf	cxbxax, ss:[centerPoint].PDF_x
	adddwf	cxbxax, ss:[deltaPoint].PDF_x
	movdwf	ss:[centerPoint].PDF_x, cxbxax
	rnddwf	cxbxax
	
	; Decide whether to check the left or the right
	tst	di
	js	isLeftEdge
	
	; if the center is past the right edge, do NOT move
	jgdw	cxbx, ss:[boundaryRect].RD_right, moveIsInvalid
	jmp	moveIsOkay

isLeftEdge:
	; if the center is past the left edge, do NOT move
	jldw	cxbx, ss:[boundaryRect].RD_left, moveIsInvalid
	
moveIsOkay:
	clc
	
done:
	.leave
	ret

moveIsInvalid:
	stc
	jmp	short done

GrObjCheckIfNudgeIsInsideBounds	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEnsureObjectIsOnScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures that a GrObj object is being displayed.  Essentially
		sends the view a message to do this.

CALLED BY:	GrObjNudge	INTERNAL

PASS:		*ds:si	- instance data of GrObj object
		ss:bp	- inherited locals from GrObjNudge
		
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RECENTER_ON_NUDGE
	;
	; 1/24/98: See grobjConstant.def re: ND-000081 -- eca
	;
GrObjEnsureObjectIsOnScreen	proc	near
	uses	si
	.enter	inherit	GrObjNudge
	
	; Calculate the rectangle to make always visible.  This rectangle is
	; a 3-unit square around the center point.
	movdw	axbx, ss:[centerPoint].PDF_x.DWF_int
	decdw	axbx
	movdw	ss:[visibleParams].MRVP_bounds.RD_left, axbx
	add	bx, 2
	adc	ax, 0
	movdw	ss:[visibleParams].MRVP_bounds.RD_right, axbx
	
	movdw	axbx, ss:[centerPoint].PDF_y.DWF_int
	decdw	axbx
	movdw	ss:[visibleParams].MRVP_bounds.RD_top, axbx
	add	bx, 2
	adc	ax, 0
	movdw	ss:[visibleParams].MRVP_bounds.RD_bottom, axbx
	
	; Set up the remaining parts of the MakeRectVisibleParams
	mov	ss:[visibleParams].MRVP_xMargin, MRVM_50_PERCENT
	clr	ss:[visibleParams].MRVP_xFlags
	mov	ss:[visibleParams].MRVP_yMargin, MRVM_50_PERCENT
	clr	ss:[visibleParams].MRVP_yFlags
	
	push	bp
	; Package up message to send to the view
	lea	bp, ss:[visibleParams]
	mov	dx, size MakeRectVisibleParams
	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage				;^hdi = ClassedEvent
	
	; Send message to the body to pass the classed event up to the view.
	mov	cx, di
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS
	call	GrObjMessageToBody
	pop	bp
	
	.leave
	ret
GrObjEnsureObjectIsOnScreen	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjNudgeInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nudge paste inside children

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx - number of x units to move
		dx - number of y units to move


RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNudgeInside	method dynamic GrObjClass, 
						MSG_GO_NUDGE_INSIDE
	.enter

	test	ds:[di].GOI_attrFlags, mask GOAF_PASTE_INSIDE
	jz	done

	mov	ax,MSG_GO_NUDGE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GrObjNudgeInside		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMoveInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move paste inside children

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - PointDWFixed

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMoveInside	method dynamic GrObjClass, MSG_GO_MOVE_INSIDE
	.enter

	test	ds:[di].GOI_attrFlags, mask GOAF_PASTE_INSIDE
	jz	done

	mov	ax,MSG_GO_MOVE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GrObjMoveInside		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the width and height of the object. 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - PointWWFixed
			PF_x - desired width in points
			PF_y - desired height in points

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		nothing


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetSize	method dynamic GrObjClass, MSG_GO_SET_SIZE
	uses	cx,dx,bp

anchorHandle	local	word 
anchorPoints	local	SrcDestPointDWFixeds

	.enter

	call	GrObjCanResize?
	jnc	done

	push	bp					;stack frame
	mov	bp,GOANT_PRE_RESIZE
	call	GrObjOptNotifyAction
	pop	bp					;stack frame

	mov	di,ss:[bp]				;orig stack frame
	mov	anchorHandle, HANDLE_LEFT_TOP

	call	GrObjBeginGeometryCommon

	;    Calculate the initial position of the anchor point
	;

	push	bp				;stack frame
	mov	cx,anchorHandle			;cl gets GHS of anchor handle
	lea	bp,[anchorPoints.SDPDWF_source]
	call	GrObjGetNormalPARENTHandleCoords
	pop	bp				;stack frame

	;    Set the new size
	;

	movwwf	dxcx,ss:[di].PF_x
	movwwf	bxax,ss:[di].PF_y
	call	GrObjSetNormalOBJECTDimensions

	;    Calc the final position of the anchored point
	;

	push	bp				;stack frame
	mov	cx,anchorHandle			;ch gets GHS of anchor handle
	lea	bp,[anchorPoints.SDPDWF_dest]
	call	GrObjGetNormalPARENTHandleCoords
	pop	bp				;stack frame

	;    Move the object so that the anchored point
	;    stays in the same place
	;

	push	bp
	lea	bp,ss:[anchorPoints]
	call	GrObjMoveNormalBackToAnchor

	mov	bp,GOANT_RESIZED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock
	pop	bp

done:
	.leave
	ret
GrObjSetSize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width and height of the object in points.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		dx:cx - WWFixed width in points
		bp:ax - WWFixed height in points
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetSize	method dynamic GrObjClass, MSG_GO_GET_SIZE
	.enter

	call	GrObjCanGeometry?
	jnc	done

	call	GrObjGetAbsNormalOBJECTDimensions
	mov	bp, bx

done:
	.leave
	ret
GrObjGetSize		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the position of the upper left of a grobj.
		The position passed must be in PARENT coords

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - PointDWFixed

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetPosition	method dynamic GrObjClass, MSG_GO_SET_POSITION
	uses	bp
	.enter

	call	GrObjCanMove?
	jnc	done

	mov	bx,bp					;desired position

	;    Get current position
	;

	sub	sp,size PointDWFixed
	mov	bp,sp
	mov	ax,MSG_GO_GET_POSITION
	call	ObjCallInstanceNoLock

	;    Get desired position - current position in stack frame
	;

	subdwf	ss:[bp].PDF_x,ss:[bx].PDF_x,ax
	negdwf	ss:[bp].PDF_x
	subdwf	ss:[bp].PDF_y,ss:[bx].PDF_y,ax
	negdwf	ss:[bp].PDF_y

	;    Move object to desired position

	mov	ax,MSG_GO_MOVE
	call	ObjCallInstanceNoLock
	add	sp,size PointDWFixed

done:
	.leave
	ret
GrObjSetPosition		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Get the position of the upper left of a grobject. The position 
	is in DOCUMENT coords unless the grobject is in a group. Then the
	position is relative to the upper left of a group. If the grobject
	has been rotated/skewed/tranformed this gets the location of the
	selection handle that was initially at the upper left of the grobject.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - PointDWFixed - empty

RETURN:		
		ss:bp - PointDWFixed - filled
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetPosition	method dynamic GrObjClass, MSG_GO_GET_POSITION
	uses	cx,dx
	.enter

	call	GrObjCanGeometry?
	jnc	done

	;    Get OBJECT coords of upper left
	;

	call	GrObjGetNormalOBJECTDimensions
	sarwwf	dxcx,1
	sarwwf	bxax,1
	negwwf	dxcx
	negwwf	bxax
	mov	ss:[bp].PDF_x.DWF_int.low,dx
	mov	ss:[bp].PDF_x.DWF_frac,cx
	mov	ss:[bp].PDF_y.DWF_int.low,bx
	mov	ss:[bp].PDF_y.DWF_frac,ax
	mov	ax,dx
	cwd
	mov	ss:[bp].PDF_x.DWF_int.high,dx
	mov	ax,bx
	cwd
	mov	ss:[bp].PDF_y.DWF_int.high,dx

	;    Convert OBJECT coordinate into DOCUMENT coords
	;

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;dest gstate
	mov	di,OBJECT_GSTATE
	call	GrObjCreateGState
	mov	si,dx					;dest gstate
	segmov	es,ss					;frame segment
	mov	dx,bp					;frame offset
	call	GrObjConvertCoordDWFixed
	call	GrDestroyState
	mov	di,si
	call	GrDestroyState

done:
	.leave
	ret
GrObjGetPosition		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjFlipHoriz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flips the object horizontally (eg. about the vertical axis)

PASS:		
		*(ds:si) - instance data

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2 jul 92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjFlipHoriz	 method dynamic GrObjClass, MSG_GO_FLIP_HORIZ
	.enter

	sub	sp, size GrObjAnchoredScaleData
	mov	bp,sp
	clr	ax
	mov	ss:[bp].GOASD_scaleAnchor, al
	mov	ss:[bp].GOASD_scale.GOSD_xScale.WWF_frac, ax
	mov	ss:[bp].GOASD_scale.GOSD_xScale.WWF_int, -1
	mov	ss:[bp].GOASD_scale.GOSD_yScale.WWF_frac, ax
	mov	ss:[bp].GOASD_scale.GOSD_yScale.WWF_int, 1
	mov	ax, MSG_GO_FLIP
	call	ObjCallInstanceNoLock
	add	sp, size GrObjAnchoredScaleData

	.leave
	ret
GrObjFlipHoriz	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjFlipVert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flips the object vertically (eg. about the horizontal axis)

PASS:		
		*(ds:si) - instance data

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2 jul 92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjFlipVert	 method dynamic GrObjClass, MSG_GO_FLIP_VERT
	.enter

	sub	sp, size GrObjAnchoredScaleData
	mov	bp,sp
	clr	ax
	mov	ss:[bp].GOASD_scaleAnchor, al
	mov	ss:[bp].GOASD_scale.GOSD_xScale.WWF_frac, ax
	mov	ss:[bp].GOASD_scale.GOSD_xScale.WWF_int, 1
	mov	ss:[bp].GOASD_scale.GOSD_yScale.WWF_frac, ax
	mov	ss:[bp].GOASD_scale.GOSD_yScale.WWF_int, -1
	mov	ax, MSG_GO_FLIP
	call	ObjCallInstanceNoLock
	add	sp, size GrObjAnchoredScaleData

	.leave
	ret
GrObjFlipVert	endm







GrObjExtNonInteractiveCode 	ends

GrObjGroupCode	segment resource

if	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertScaleToData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the scale from the transformation matrix and
		modify the width and height by the removed scale 
		factor

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertScaleToData	method dynamic GrObjClass, 
						MSG_GO_CONVERT_SCALE_TO_DATA
matrix		local	GrObjTransMatrix
scaleX		local	WWFixed
scaleY		local	WWFixed
skewXY		local	WWFixed

	uses	cx,dx
	.enter
	
	call	GrObjDecomposeTransform
	jnc	continue
	jmp	done


continue:
	call	GrObjGenerateUndoTransformChain

	;    The final GrObjTransMatrix we want is [skewXY][matrix].
	;    	|1 	0||a	b|	|a	b |
	;	|s	1||c	d| =	|as+c bx+d|
	;

	movwwf	dxcx,matrix.GTM_e11
	movwwf	bxax,skewXY
	call	GrMulWWFixed
	addwwf	matrix.GTM_e21,dxcx
	movwwf	dxcx,matrix.GTM_e12
	call	GrMulWWFixed
	addwwf	matrix.GTM_e22,dxcx

	;    Copy matrix into normalTransform
	;

	push	ds,si				;object 
	AccessNormalTransformChunk		di,ds,si
	add	di,offset OT_transform
	segmov	es,ds
	segmov	ds,ss
	lea	si,matrix
	MoveConstantNumBytes	<size GrObjTransMatrix>, cx
	pop	ds,si				;object

	;    Multiply width and height by scale factors
	;

	AccessNormalTransformChunk		di,ds,si
	movwwf	dxcx,ds:[di].OT_width	
	movwwf	bxax,scaleX
	call	GrMulWWFixed
	movwwf	ds:[di].OT_width,dxcx
	movwwf	dxcx,ds:[di].OT_height
	movwwf	bxax,scaleY
	call	GrMulWWFixed
	movwwf	ds:[di].OT_height,dxcx

	call	ObjMarkDirty

done:
	.leave
	ret
GrObjConvertScaleToData		endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDecomposeTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decompose transform in a rotation matrix, a skew and an
		x and y scale
		
PASS:		
		*(ds:si) - instance data of object

RETURN:		
		clc - successful decomposition
		stc - hosed
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDecomposeTransform		proc	far
	class	GrObjClass
matrix		local	GrObjTransMatrix
scaleX		local	WWFixed
scaleY		local	WWFixed
skewXY		local	WWFixed

	uses	ax,bx,cx,dx,di,es
	.enter	inherit

	;    Copy GrObjTransMatrix to stack frame
	;

	push	si					;object chunk
	AccessNormalTransformChunk	si,ds,si
	add	si,offset OT_transform
	lea	di,matrix
	segmov	es,ss,ax
	MoveConstantNumBytes	<size GrObjTransMatrix>,cx	
	pop	si					;object chunk
	
	;    Check determinate here
	;

	;    Calc magnitude of first row
	;

	lea	di,matrix
	addnf	di,<offset GTM_e11>
	call	GrObjCalcVectorMagnitudeAndNormalize
	jc	done
	movwwf	scaleX,dxcx

	;    Calc dot product of rows 1 and 2 
	;    (initial skewXY value)
	;
	
	movwwf	dxcx,matrix.GTM_e11
	movwwf	bxax,matrix.GTM_e21
	call	GrMulWWFixed
	pushwwf	dxcx
	movwwf	dxcx,matrix.GTM_e12
	movwwf	bxax,matrix.GTM_e22
	call	GrMulWWFixed
	popwwf	bxax
	addwwf	bxax,dxcx				;initial skewXY

	;    Orthogonalize row 2
	;    M21 = M21 - (skewXY*M11)
	;    M22 = M22 - (skewXY*M12)

	movwwf	dxcx,matrix.GTM_e11
	call	GrMulWWFixed
	subwwf	matrix.GTM_e21,dxcx
	movwwf	dxcx,matrix.GTM_e12
	call	GrMulWWFixed
	subwwf	matrix.GTM_e22,dxcx

	;    Calc magnitude of second row and normalize
	;

	lea	di,matrix
	addnf	di,<offset GTM_e21>
	call	GrObjCalcVectorMagnitudeAndNormalize
	jc	done
	movwwf	scaleY,dxcx

	;    Calc final value of skewXY
	;

	xchgwwf	dxcx,bxax				;skewXY, scaleY
	call	GrSDivWWFixed
	jc	done
	movwwf	skewXY,dxcx

done:
	.leave
	ret
GrObjDecomposeTransform		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrobjCalcVectorMagnitudeAndNormalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the magnitude of the vector comprised of a
		pair of WWFixed values

CALLED BY:	INTERNAL
		GrObjDecomposeTransform

PASS:		
		es:di - fptr to two WWFixeds
RETURN:		
		clc - magnitude successfully calculated
			dx:cx - Magnitude
		stc - choke
			dx,cx - Destroyed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcVectorMagnitudeAndNormalize		proc	near
	uses	ax,bx,bp,si
	.enter

	;    Square first element of vector
	;

	push	di					;vector offset
	movwwf	axcx,es:[di]
	cwd						;sign extend to DWF
	mov	di,dx					;high int
	mov	dx,ax					;low int
	movdwf	sibxax,didxcx
	call	GrMulDWFixed
	pop	di					;vector offset
	jc	done
	push	dx					;high int
	push	cx					;low int
	push	bx					;frac

	;    Square second element of vector

	push	di					;vector offset
	movwwf	axcx,<es:[di][size WWFixed]>
	cwd
	mov	di,dx
	mov	dx,ax
	movdwf	sibxax,didxcx
	call	GrMulDWFixed
	pop	di					;vector offset
	jc	pop3

	;    Sum of squares
	;

	pop	ax
	add	bx,ax
	pop	ax
	adc	cx,ax
	pop	ax
	adc	dx,ax

	mov	bp,bx
	call	GrObjCalcSquareRoot
	jc	done

	;    Normalize vector
	;

	movwwf	bxax,dxcx				;magnitude
	movwwf	dxcx,es:[di]				;first vector element
	call	GrSDivWWFixed
	jc	done
	movwwf	es:[di],dxcx

	movwwf	dxcx,<es:[di][size WWFixed]>
	call	GrSDivWWFixed
	jc	done
	movwwf	<es:[di][size WWFixed]>,dxcx
	movwwf	dxcx,bxax				;magnitude

done:
	.leave
	ret
pop3:
	add	sp,6
	stc
	jmp	done

GrObjCalcVectorMagnitudeAndNormalize		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform a grobject. The transform is applied to the
		center of the object and is pre applied to
		the transform in the object. It is used for applying
		a groups transform to all its children.

PASS:		
		*(ds:si) - instance data
		ss:bp - TransMatrix

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			GrObject will be selected

			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTransform method dynamic GrObjClass, MSG_GO_TRANSFORM
	uses	cx,dx,bp
	.enter

	call	GrObjCanTransform?
	jnc	done
	
	push	bp					;stack frame
	mov	bp,GOANT_PRE_TRANSFORM
	call	GrObjOptNotifyAction
	pop	bp					;stack frame

	call	GrObjGenerateUndoTransformChain
	call	GrObjBeginGeometryCommon

	call	GrObjTransformNormalRelative

	mov	bp,GOANT_TRANSFORMED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

GrObjTransform		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoTransformChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for a transform action

CALLED BY:	INTERNAL
		GrObjTransform

PASS:		*ds:si - object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoTransformChain		proc	far
	uses	ax,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	cx,handle transformString
	mov	dx,offset transformString
	mov	ax,MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjGenerateUndoTransformChain		endp

GrObjGroupCode	ends

GrObjObscureExtNonInteractiveCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjScaleAboutPARENTLeftTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Scales object [current matrix] [scale]. 
 	Obscure message which applies the scale along the PARENT axes
	and keeps the left top of the PARENT bounds in the same place.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		ss:bp - GrObjScaleData
RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleAboutPARENTLeftTop	method dynamic GrObjClass, 
				MSG_GO_SCALE_ABOUT_PARENT_LEFT_TOP
	.enter

	call	GrObjCanResize?
	jnc	done

	;    See if passed scale is 1x1
	;   

	cmp	ss:[bp].GOSD_xScale.WWF_int,1
	je	checkOthers

doScale:
	push	bp					;stack frame
	mov	bp,GOANT_PRE_RESIZE
	call	GrObjOptNotifyAction
	pop	bp					;stack frame

	call	GrObjBeginGeometryCommon
	mov	bx,bp					;GrObjScaleData
	sub	sp,size SrcDestPointDWFixeds
	mov	bp,sp
	add	bp,offset SDPDWF_source
	call	GrObjGetDWFPARENTBoundsUpperLeft
	sub	bp,offset SDPDWF_source

	xchg	bp,bx				;GrObjScaleData,SrcDestPDWF
	call	GrObjScaleNormalRelative
	xchg	bx,bp				;GrObjScaleData,SrcDestPDWF

	;    We must calc the parent dimensions here because 
	;    GrObjGetDWFPARENTBoundsUpperLeft depends on them 
	;    being set correctly.
	;

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	add	bp,offset SDPDWF_dest
	call	GrObjGetDWFPARENTBoundsUpperLeft
	sub	bp,offset SDPDWF_dest

	call	GrObjMoveNormalBackToAnchor
	add	sp,size SrcDestPointDWFixeds

	mov	bp,GOANT_RESIZED
	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	call	ObjCallInstanceNoLock

	mov	bp,bx					;GrObjScaleData

done:
	.leave
	ret

checkOthers:
	tst	ss:[bp].GOSD_xScale.WWF_frac
	jnz	doScale
	cmp	ss:[bp].GOSD_yScale.WWF_int,1
	jne	doScale
	tst	ss:[bp].GOSD_yScale.WWF_frac
	jnz	doScale
	jmp	done

GrObjScaleAboutPARENTLeftTop		endm





InsertDeleteAxisFlags	record
	IDAF_MOVE_INTERSECTING:1	;TRUE if moveIntersecting field
					;has useful data in it.
	IDAF_SCALE:1			;TRUE if scale field
					;has useful data in it.
	IDAF_DELETE:1			;TRUE if applying scale field
					;results in object with zero as 
					;a dimension
	IDAF_MOVE_BELOW_RIGHT:1		;TRUE if moveBelowRight field
					;has useful data in it.
InsertDeleteAxisFlags	end

InsertDeleteAxis struct
	IDA_objEdgeStart	DWFixed		;Left or top of object in 
						;DOCUMENT coordinates

	IDA_objEdgeEnd		DWFixed		;Right or bottom of object in 
						;DOCUMENT coordinates

	IDA_objDimension 	WWFixed		;Width or height of object
						;in DOCUMENT coordinates

	IDA_spaceStart 		DWFixed		;x or y of insert/delete point
						;in DOCUMENT coordinates

	IDA_space		DWFixed		;Amount of space in x or y
						;to insert

	IDA_spaceEnd		DWFixed		;x or y of insert/delete point
						;plus insert/delete space

	IDA_moveIntersecting	DWFixed		;Amount to move object 
						;in x or y in DOCUMENT coords.
						;Move caused by object 
						;intersecting the insert/delete
						;space

	IDA_scale		WWFixed		;Scale factor to apply to
						;x or y dimension

	IDA_moveBelowRight	DWFixed		;Amount to move object 
						;in x or y in DOCUMENT coords.
						;Move caused by object being
						;right or below the 
						;insert/delete space
	IDA_flags		InsertDeleteAxisFlags
	IDA_passedType		InsertDeleteSpaceTypes
InsertDeleteAxis	ends


InsertDeleteWorkingData	struct
	IDWD_horiz	InsertDeleteAxis	;
	IDWD_vert	InsertDeleteAxis	;
InsertDeleteWorkingData	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInsertOrDeleteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserting or deleting space may cause object to
		move, resize or even be deleted.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - InsertDeleteSpaceParams

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInsertOrDeleteSpace	method dynamic GrObjClass, 
						MSG_GO_INSERT_OR_DELETE_SPACE

workingData	local	InsertDeleteWorkingData
ForceRef	workingData
	mov	bx,bp				;InsertDeleteSpaceParams
	.enter

	call	GrObjCanGeometryAndValid?
	jnc	done

	call	GrObjInitializeInsertDeleteWorkingData
	call	GrObjCalcInsertDeleteWorkingData
	call	GrObjConsiderParamsAndPermissions
	call	GrObjDoInsertDeleteGeometry

done:
	.leave
	ret


GrObjInsertOrDeleteSpace		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitializeInsertDeleteWorkingData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize InsertDeleteWorkingData 

CALLED BY:	INTERNAL
		GrObjInsertOrDeleteSpace

PASS:		
		*ds:si - Object
		ss:bp - inherited InsertDeleteWorkingData
		ss:bx - InsertDeleteSpaceParams

RETURN:		
		InsertDeleteWorkingData initialized

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

		Pieces of this routine are duplicates of each other. It
		could be broken into a common subroutine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitializeInsertDeleteWorkingData		proc	near

workingData	local	InsertDeleteWorkingData
	uses	ax,bx,cx,dx,di,si,es,ds
	.enter	inherit

EC <	call	ECGrObjCheckLMemObject				>

	push	ds,si					;object

	segmov	ds,ss,ax
	mov	es,ax

	mov	ax, ss:[bx].IDSP_type
	mov	ss:[workingData.IDWD_horiz.IDA_passedType], ax
	mov	ss:[workingData.IDWD_vert.IDA_passedType], ax

	;   Init spaceStart to the insert/delete point
	;   and spaceEnd to spaceStart + abs(space to insert/delete)
	;

	mov	si,bx
	add	si,offset IDSP_position.PDF_x
	lea	di,ss:[workingData.IDWD_horiz.IDA_spaceStart]
	MoveConstantNumBytes <size DWFixed>,cx

	mov	si,bx
	add	si,offset IDSP_position.PDF_x
	lea	di,ss:[workingData.IDWD_horiz.IDA_spaceEnd]
	MoveConstantNumBytes <size DWFixed>,cx

	movdwf	dxcxax,ss:[bx].IDSP_space.PDF_x
	movdwf	workingData.IDWD_horiz.IDA_space,dxcxax
	tst	dx
	jns	10$
	negdwf	dxcxax
10$:
	adddwf	workingData.IDWD_horiz.IDA_spaceEnd,dxcxax


	mov	si,bx
	add	si,offset IDSP_position.PDF_y
	lea	di,ss:[workingData.IDWD_vert.IDA_spaceStart]
	MoveConstantNumBytes <size DWFixed>,cx

	mov	si,bx
	add	si,offset IDSP_position.PDF_y
	lea	di,ss:[workingData.IDWD_vert.IDA_spaceEnd]
	MoveConstantNumBytes <size DWFixed>,cx

	movdwf	dxcxax,ss:[bx].IDSP_space.PDF_y
	movdwf	ss:[workingData.IDWD_vert.IDA_space],dxcxax
	tst	dx
	jns	20$
	negdwf	dxcxax
20$:
	adddwf	ss:[workingData.IDWD_vert.IDA_spaceEnd],dxcxax

	clr	al
	mov	ss:[workingData.IDWD_horiz.IDA_flags],al
	mov	ss:[workingData.IDWD_vert.IDA_flags],al

	;    Set EdgeStart, EdgeEnd and Dimension fields from 
	;    PARENT bounds of object
	;

	pop	ds,si					;object
	mov	bx,bp					;inherited frame
	sub	sp, size RectDWFixed
	mov	bp,sp
	mov	ax,MSG_GO_GET_DWF_PARENT_BOUNDS
	call	ObjCallInstanceNoLock
	xchg	bp,bx					;inherited, RectDWFixed

	movdwf	ss:[workingData.IDWD_horiz.IDA_objEdgeStart],\
		ss:[bx].RDWF_left,ax
	movdwf	dxcxax,ss:[bx].RDWF_right
	movdwf	ss:[workingData.IDWD_horiz.IDA_objEdgeEnd],dxcxax
	subdwf	dxcxax,ss:[bx].RDWF_left
	movwwf	ss:[workingData.IDWD_horiz.IDA_objDimension],cxax

	movdwf	ss:[workingData.IDWD_vert.IDA_objEdgeStart],\
		ss:[bx].RDWF_top,ax
	movdwf	dxcxax,ss:[bx].RDWF_bottom
	movdwf	ss:[workingData.IDWD_vert.IDA_objEdgeEnd],dxcxax
	subdwf	dxcxax,ss:[bx].RDWF_top
	movwwf	ss:[workingData.IDWD_vert.IDA_objDimension],cxax
	add	sp,size RectDWFixed

	.leave
	ret
GrObjInitializeInsertDeleteWorkingData		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcInsertDeleteWorkingData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill out the InsertDeleteWorkingData struct

CALLED BY:	INTERNAL
		GrObjInsertOrDeleteSpace

PASS:		
		ss:bp - inherited InsertDeleteWorkingData

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcInsertDeleteWorkingData	proc near

workingData	local	InsertDeleteWorkingData

	.enter	inherit

	push	bp				;local frame
	lea	bp,ss:[workingData.IDWD_horiz]
	tst	ss:[bp].IDA_space.DWF_int.high
	js	doHorizDelete

	call	GrObjAxisInsert

doVert:
	pop	bp				;local frame
	push	bp				;local frame
	lea	bp,ss:[workingData.IDWD_vert]
	tst	ss:[bp].IDA_space.DWF_int.high
	js	doVertDelete

	call	GrObjAxisInsert

done:
	pop	bp

	.leave
	ret

doHorizDelete:
	call	GrObjAxisDelete
	jmp	doVert
		
doVertDelete:
	call	GrObjAxisDelete
	jmp	done
		

GrObjCalcInsertDeleteWorkingData		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAxisInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill out the 
		IDA_moveIntersecting, IDA_scale, and IDA_moveBelowRight
		fields in the InsertDeleteAxis structure

CALLED BY:	INTERNAL
		GrObjInsertOfDeleteSpace

PASS:		
		ss:bp - InsertDeleteAxis
RETURN:		
		ss:bp - InsertDeleteAxis

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		if objEdgeStart >= spaceStart then 
			moveBelowRight = space
			exit
		else if objEdgeStart < spaceStart < objectEdgeEnd then
			scale = (objDimension + space)/objDimension
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			a move is more likely than a resize

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAxisInsert		proc	near
	uses	ax,bx,cx,dx
	.enter

	jldwf	ss:[bp].IDA_objEdgeStart,ss:[bp].IDA_spaceStart,tryResize,ax
	movdwf	ss:[bp].IDA_moveBelowRight,ss:[bp].IDA_space,ax
	BitSet	ss:[bp].IDA_flags, IDAF_MOVE_BELOW_RIGHT

done:
	.leave
	ret

tryResize:
	jledwf	ss:[bp].IDA_objEdgeEnd,ss:[bp].IDA_spaceStart,done,ax
	push	bp					;passed frame
	movwwf	axcx,ss:[bp].IDA_objDimension
	cwd
	xchg	ax,cx				;frac,int
	adddwf	dxcxax,ss:[bp].IDA_space
	mov	bx,ss:[bp].IDA_objDimension.WWF_int
	mov	bp,ss:[bp].IDA_objDimension.WWF_frac
	xchg	ax,bp				;divisor frac, dividend frac
	call	GrSDivDWFbyWWF
	mov	ax,bp
	pop	bp					;passed frame

	;    If the high word of the scale is not zero then something
	;    horribly bad has happened, so ignore the calced scale
	;

	tst	dx
	jnz	done
	movwwf	ss:[bp].IDA_scale,cxax
	BitSet	ss:[bp].IDA_flags, IDAF_SCALE
	jmp	done

GrObjAxisInsert		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAxisDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill out the 
		IDA_moveIntersecting, IDA_scale, and IDA_moveBelowRight
		fields in the InsertDeleteAxis structure

CALLED BY:	INTERNAL
		GrObjInsertOfDeleteSpace

PASS:		
		ss:bp - InsertDeleteAxis
RETURN:		
		ss:bp - InsertDeleteAxis

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		if spaceEnd <= objEdgeStart then
			moveBelowRight = space
		else if spaceStart <= objEdgeStart then
			moveIntersecting = spaceStart-objEdgeStart
		endif

		if spaceEnd > objEdgeStart and spaceStart < objEdgeEnd then
			tempDeltaEnd = Min(objEdgeEnd,spaceEnd)
			tempDeltaStart = Max (objEdgeStart,spaceStart)
			scale = objDimension - (tempDeltaEnd-tempDeltaStart)
				-------------------------------------------
					objDimension
		endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			a move is more likely than a resize

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAxisDelete		proc	near
	uses	ax,bx,cx,dx
	.enter

	jgdwf	ss:[bp].IDA_spaceEnd,ss:[bp].IDA_objEdgeStart,tryMoveInt,ax
moveIt:
	movdwf	ss:[bp].IDA_moveBelowRight,ss:[bp].IDA_space,ax
	BitSet	ss:[bp].IDA_flags, IDAF_MOVE_BELOW_RIGHT

done:
	.leave
	ret

tryMoveInt:
	jgdwf	ss:[bp].IDA_spaceStart,ss:[bp].IDA_objEdgeStart, tryResize,ax
	test	ss:[bp].IDA_passedType, \
		mask IDST_MOVE_OBJECTS_INSIDE_DELETED_SPACE_BY_AMOUNT_DELETED
	jnz	moveIt
	movdwf	ss:[bp].IDA_moveIntersecting,ss:[bp].IDA_spaceStart,ax
	subdwf	ss:[bp].IDA_moveIntersecting,ss:[bp].IDA_objEdgeStart,ax
	BitSet	ss:[bp].IDA_flags, IDAF_MOVE_INTERSECTING
	
tryResize:
	;    From compare for moveBelowRight we know that
	;    spaceEnd > objEdgeStart
	;

	jgdwf	ss:[bp].IDA_spaceStart,ss:[bp].IDA_objEdgeEnd, done,ax
	movwwf	axcx,ss:[bp].IDA_objDimension
	cwd
	jldwf	ss:[bp].IDA_objEdgeEnd,ss:[bp].IDA_spaceEnd,subEdgeEnd,bx
	subdwf	dxaxcx,ss:[bp].IDA_spaceEnd

max:
	jgdwf	ss:[bp].IDA_objEdgeStart,ss:[bp].IDA_spaceStart,addEdgeStart,bx
	adddwf	dxaxcx,ss:[bp].IDA_spaceStart

calcScale:
	push	bp					;passed frame
	mov	bx,ss:[bp].IDA_objDimension.WWF_int
	mov	bp,ss:[bp].IDA_objDimension.WWF_frac
	xchg	ax,cx				;dividend frac, dividend int
	xchg	ax,bp				;divisor frac, dividend frac
	call	GrSDivDWFbyWWF
	mov	ax,bp
	pop	bp					;passed frame

	;    If the high word of the scale is not zero then something
	;    horribly bad has happened, so ignore the calced scale
	;

	tst	dx
	jnz	jmpDone

	;    If both the low int and the frac are zero then we must
	;    mark it as delete too
	;

	tst	cx
	jnz	storeScale
	tst	ax
	jnz	storeScale
	BitSet	ss:[bp].IDA_flags, IDAF_DELETE

storeScale:
	movwwf	ss:[bp].IDA_scale,cxax
	BitSet	ss:[bp].IDA_flags, IDAF_SCALE
jmpDone:
	jmp	done

subEdgeEnd:
	subdwf	dxaxcx,ss:[bp].IDA_objEdgeEnd
	jmp	max
	
addEdgeStart:
	adddwf	dxaxcx,ss:[bp].IDA_objEdgeStart
	jmp	calcScale

GrObjAxisDelete		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConsiderParamsAndPermissions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify IDA_flags based on the passed parameters
		and the objects permissions

CALLED BY:	INTERNAL
		GrObjInsertOrDeleteSpace

PASS:		
		*ds:si - object
		ss:bp - inherited InsertDeleteWorkingData
		ss:bx - InsertDeleteSpaceParams

RETURN:		
		ss:bp - inherited InsertDeleteWorkingData
			both IDA_flags may have changed
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConsiderParamsAndPermissions		proc	near
workingData	local	InsertDeleteWorkingData
	.enter inherit

EC <	call	ECGrObjCheckLMemObject				>

	push	bp
	lea	bp,ss:[workingData.IDWD_horiz]
	call	GrObjConsiderAxisParamsAndPermissions
	pop	bp
	
	push	bp
	lea	bp,ss:[workingData.IDWD_vert]
	call	GrObjConsiderAxisParamsAndPermissions
	pop	bp

	.leave
	ret
GrObjConsiderParamsAndPermissions		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConsiderAxisParamsAndPermissions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify IDA_flags based on the passed parameters
		and the objects permissions

CALLED BY:	INTERNAL
		GrObjConsiderParamsAndPermissions

PASS:		
		*ds:si - object
		ss:bp - InsertDeleteAxis
		ss:bx - InsertDeleteSpaceParams

RETURN:		
		ss:bp - IDA_flags may have changed
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConsiderAxisParamsAndPermissions		proc	near
	class	GrObjClass
	uses	ax,di
	.enter inherit

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si

	mov	al,ss:[bp].IDA_flags

	test	ss:[bx].IDSP_type, \
			mask IDST_MOVE_OBJECTS_INTERSECTING_DELETED_SPACE
	jz	nukeMoveIntersecting
	test	ds:[di].GOI_attrFlags,mask GOAF_INSERT_DELETE_MOVE_ALLOWED
	jnz	checkResize

nukeMoveIntersecting:
	BitClr	al, IDAF_MOVE_INTERSECTING

checkResize:
	test	ss:[bx].IDSP_type, \
				mask IDST_RESIZE_OBJECTS_INTERSECTING_SPACE
	jz	nukeScale
	test	ds:[di].GOI_attrFlags,mask GOAF_INSERT_DELETE_RESIZE_ALLOWED
	jnz	checkDelete

nukeScale:
	BitClr	al, IDAF_SCALE

checkDelete:
	test	ss:[bx].IDSP_type, \
				mask IDST_DELETE_OBJECTS_SHRUNK_TO_ZERO_SIZE
	jz	nukeDelete
	test	ds:[di].GOI_attrFlags,mask GOAF_INSERT_DELETE_DELETE_ALLOWED
	jnz	checkMoveBelowRight

nukeDelete:
	BitClr	al, IDAF_DELETE

checkMoveBelowRight:
	test	ss:[bx].IDSP_type, mask \
	IDST_MOVE_OBJECTS_BELOW_AND_RIGHT_OF_INSERT_POINT_OR_DELETED_SPACE
	jz	nukeMoveBelowRight
	test	ds:[di].GOI_attrFlags,mask GOAF_INSERT_DELETE_MOVE_ALLOWED
	jnz	done

nukeMoveBelowRight:
	BitClr	al, IDAF_MOVE_BELOW_RIGHT

done:
	mov	ss:[bp].IDA_flags,al

	.leave
	ret
GrObjConsiderAxisParamsAndPermissions		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDoInsertDeleteGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually move/resize/delete object based on
		InsertDeleteWorkingData

CALLED BY:	INTERNAL
		GrObjInsertOrDeleteSpace

PASS:		*ds:si - object
		ss:bp - inherited InsertDeleteWorkingData

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDoInsertDeleteGeometry		proc	near
workingData	local	InsertDeleteWorkingData
	uses	ax,bx,cx
	.enter inherit

EC <	call	ECGrObjCheckLMemObject				>
	
	;    Do move
	;

	sub	sp,size PointDWFixed
	mov	bx,sp
	push	bp
	lea	bp,ss:[workingData.IDWD_horiz]
	call	GrObjCalcInsertDeleteAxisMove
	pop	bp
	push	bp
	add	bx,offset PDF_y
	lea	bp,ss:[workingData.IDWD_vert]
	call	GrObjCalcInsertDeleteAxisMove
	sub	bx,offset PDF_y
	pop	bp
	xchg	bp,bx				;PointDWFixed, workingData
	mov	ax,MSG_GO_MOVE
	call	ObjCallInstanceNoLock
	xchg	bx,bp				;PointDWFixed, workingData
	add	sp,size PointDWFixed

	;    Do scale
	;

	sub	sp,size GrObjScaleData
	mov	bx,sp
	push	bp
	add	bx,offset GOSD_xScale
	lea	bp,ss:[workingData.IDWD_horiz]
	call	GrObjCalcInsertDeleteAxisScale
	sub	bx,offset GOSD_xScale
	pop	bp
	push	bp
	add	bx,offset GOSD_yScale
	lea	bp,ss:[workingData.IDWD_vert]
	call	GrObjCalcInsertDeleteAxisScale
	sub	bx,offset GOSD_yScale
	pop	bp
	xchg	bp,bx				;GrObjScaleData, workingData
	mov	ax,MSG_GO_SCALE_ABOUT_PARENT_LEFT_TOP
	call	ObjCallInstanceNoLock
	xchg	bx,bp				;GrObjScaleData, workingData
	add	sp,size GrObjScaleData

	;    Do delete
	;

	test	ss:[workingData.IDWD_horiz.IDA_flags], mask IDAF_DELETE
	jnz	delete
	test	ss:[workingData.IDWD_vert.IDA_flags], mask IDAF_DELETE
	jnz	delete

done:
	.leave
	ret

delete:
	mov	ax,MSG_GO_CLEAR
	call	ObjCallInstanceNoLock
	jmp	done

GrObjDoInsertDeleteGeometry		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcInsertDeleteAxisMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the total amount the object needs to be moved

CALLED BY:	INTERNAL
		GrObjDoInsertDeleteGeometry

PASS:		
		ss:bp - InsertDeleteAxis
		ss:bx - DWFixed - empty

RETURN:		
		ss:bx - amount to move in axis

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcInsertDeleteAxisMove		proc	near
	uses	ax,di,es
	.enter

	;   Init move to zero
	;

	segmov	es,ss,ax
	mov	di,bx
	clr	ax
	StoreConstantNumBytes <size DWFixed >,cx

	;   Add in intersecting and below right moves
	;

	test	ss:[bp].IDA_flags, mask IDAF_MOVE_INTERSECTING
	jz	10$
	adddwf	ss:[bx], ss:[bp].IDA_moveIntersecting,ax
10$:
	test	ss:[bp].IDA_flags, mask IDAF_MOVE_BELOW_RIGHT
	jz	20$
	adddwf	ss:[bx], ss:[bp].IDA_moveBelowRight,ax
20$:

	.leave
	ret
GrObjCalcInsertDeleteAxisMove		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcInsertDeleteAxisScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the scale factor for one axis

CALLED BY:	INTERNAL
		GrObjDoInsertDeleteGeometry

PASS:		
		ss:bp - InsertDeleteAxis
		ss:bx - WWFixed - empty

RETURN:		
		ss:bx - WWFixed - scale factor

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcInsertDeleteAxisScale		proc	near
	uses	ax
	.enter

	;   Init scale to 1.0
	;

	mov	ss:[bx].WWF_int,1
	clr	ss:[bx].WWF_frac

	test	ss:[bp].IDA_flags, mask IDAF_SCALE
	jz	done
	movwwf	ss:[bx], ss:[bp].IDA_scale,ax
done:
	.leave
	ret

GrObjCalcInsertDeleteAxisScale		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjAlign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_ALIGN

Pass:		*ds:si = ds:di = GrObj
		ss:bp = AlignParams
		dx = size AlignParams

Return:		nothing

Destroyed:	ax, bx, cx, di, es

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov  6, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAlign	method	dynamic	GrObjClass, MSG_GO_ALIGN

center		local	PointDWFixed
boundsDWF	local	RectDWFixed
localPoint	local	PointDWFixed

	mov	bx, bp					;ss:bx <- AlignParams

	.enter

	call	GrObjCanMove?
	jnc	done

	mov	dl, ss:[bx].AP_type
	test	dl, mask AT_ALIGN_X or mask AT_DISTRIBUTE_X or \
			mask AT_ALIGN_Y or mask AT_DISTRIBUTE_Y
	jnz	continue

done:
	.leave
	ret

continue:
	;
	;	Save the original passed point
	;
	push	ds, si
	mov	ax, ss
	mov	ds, ax
	mov	es, ax
	mov	si, bx
	lea	di, ss:localPoint
	mov	cx, size PointDWFixed / 2
	rep	movsw
	pop	ds, si

	;
	;	Get the object's center
	;
	push	bp
	lea	bp, ss:[center]
	mov	ax, MSG_GO_GET_CENTER
	call	ObjCallInstanceNoLock

	pop	bp
	push	bp
	;
	;	Get the object's bounds
	;
	lea	bp, ss:[boundsDWF]
	mov	ax, MSG_GO_GET_DWF_PARENT_BOUNDS
	call	ObjCallInstanceNoLock
	pop	bp

	;
	;	check whatkind of horizontal alignment we want
	;
	test	dl, mask AT_ALIGN_X or mask AT_DISTRIBUTE_X
	jnz	calcXOffset

	clr	ax
	clrdwf	localPoint.PDF_x, ax
	jmp	calcYOffset

calcXOffset:
	mov	al, dl
	and	al, mask AT_CLRW
	jz	centerX

	cmp	al, CLRW_RIGHT shl offset AT_CLRW
	je	rightX

	;
	;	either align left or width
	;
	subdwf	localPoint.PDF_x, boundsDWF.RDWF_left, ax
	jmp	checkAlignY

centerX:
	subdwf	localPoint.PDF_x, center.PDF_x, ax
	jmp	checkAlignY

rightX:
	subdwf	localPoint.PDF_x, boundsDWF.RDWF_right, ax

checkAlignY:
	test	dl, mask AT_ALIGN_Y or mask AT_DISTRIBUTE_Y
	jnz	calcYOffset

	clr	ax
	clrdwf	localPoint.PDF_y, ax
	jmp	doAlign

calcYOffset:
	mov	al, dl
	and	al, mask AT_CTBH
	jz	centerY

	cmp	al, CTBH_BOTTOM shl offset AT_CTBH
	je	bottomY

	;
	;	align either top or height
	;
	subdwf	localPoint.PDF_y, boundsDWF.RDWF_top, ax
	jmp	doAlign

centerY:
	subdwf	localPoint.PDF_y, center.PDF_y, ax
	jmp	doAlign

bottomY:
	subdwf	localPoint.PDF_y, boundsDWF.RDWF_bottom, ax

doAlign:
	push	bp
	lea	bp, ss:localPoint
	;
	;    Move the object
	;
	mov	ax, MSG_GO_MOVE
	call	ObjCallInstanceNoLock
	pop	bp

	test	dl, mask AT_ALIGN_X or mask AT_DISTRIBUTE_X
	jz	checkCTBH

	mov	al, dl
	andnf	al, mask AT_CLRW
	cmp	al, mask AT_CLRW
	jne	checkHeight

	;
	;	We're aligning by width, so add in this object's width for
	;	the next object...

	push	dx

	movdwf	dxcxax, boundsDWF.RDWF_right
	subdwf	dxcxax, boundsDWF.RDWF_left
	adddwf	ss:[bx].AP_x, dxcxax

	pop	dx

checkHeight:
	test	dl, mask AT_ALIGN_Y or mask AT_DISTRIBUTE_Y
	jz	addDistribute

checkCTBH:
	mov	al, dl
	andnf	al, mask AT_CTBH
	cmp	al, mask AT_CTBH
	jne	addDistribute

	;
	;	We're aligning by height, so add in this object's width for
	;	the next object...

	push	dx
	movdwf	dxcxax, boundsDWF.RDWF_bottom
	subdwf	dxcxax, boundsDWF.RDWF_top
	adddwf	ss:[bx].AP_y, dxcxax
	pop	dx

addDistribute:
	test	dl, mask AT_DISTRIBUTE_X
	jz	checkAddDistributeY

	xchg	bp, bx					;bx <- local ptr
							;bp <- frame ptr

	AddDWF	ss:[bp].AP_x, ss:[bp].AP_spacingX, ax
	xchg	bp, bx					;bp <- local ptr
							;bx <- frame ptr

checkAddDistributeY:
	test	dl, mask AT_DISTRIBUTE_Y
	LONG jz	done

	xchg	bp, bx					;bx <- local ptr
							;bp <- frame ptr

	AddDWF	ss:[bp].AP_y, ss:[bp].AP_spacingY, ax
	mov	bp, bx					;bp <- local ptr
	jmp	done
GrObjAlign	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjAlignToGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_ALIGN_TO_GRID

Pass:		*ds:si = ds:di = GrObj
		cl = AlignType

Return:		nothing

Destroyed:	ax, dx

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	26 mar 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; This rectangular region of the object is expanded by this amount (low word)
; to allow for two things: (1) the fact that the previous code used by GenValue
; to convert ASCII to FixedPoint was inaccurate and thus the user may hit
; align to grid and have it not move (because it is very close, but not
; exact), and (2) if the object is exactly aligned top or left and the user
; requrests an align to grid top or left, it will not move because of the
; ruler's rounding rules.  This will cause a click on the align to always
; move the object.	--JimG 6/20/94
;
ALIGN_FUDGE_EPSILON_LOW = 0100h		; About 0.00390625 points

GrObjAlignToGrid	method	dynamic	GrObjClass, MSG_GO_ALIGN_TO_GRID

boundsDWF	local	RectDWFixed
centerDWF	local	PointDWFixed
localPoint	local	PointDWFixed
halfGridSpacing	local	PointDWFixed

	.enter

	call	GrObjCanMove?
	jc	doMove

done:
	.leave
	ret

doMove:

	test	cl, mask ATGT_H_CENTER or mask ATGT_V_CENTER
	jz	afterCenter

	;
	;	Get the object's center
	;
	push	bp
	lea	bp, ss:[centerDWF]
	mov	ax, MSG_GO_GET_CENTER
	call	ObjCallInstanceNoLock
	pop	bp

afterCenter:
	test	cl, mask ATGT_LEFT or mask ATGT_RIGHT or \
			mask ATGT_TOP or mask ATGT_BOTTOM
	jz	afterBounds

	;
	;	Get the object's bounds
	;
	push	bp
	lea	bp, ss:[boundsDWF]
	mov	ax, MSG_GO_GET_DWF_PARENT_BOUNDS
	call	ObjCallInstanceNoLock
	pop	bp

	;
	;	Subtract off 1/2 of the line width so that the object
	;	aligns to the grid as if it were drawn with the snap to grid
	;	enabled.  --JimG 6/20/94
	;
	push	cx			;save AlignToGridType
	push	ds, si			;save object pointer
	push	bp			;save stack frame
	
	call	GrObjGetLineWidth	;di:bp = WWFixed line width
	
	shrdw	dibp			;get 1/2 width
	
	; negate line width.  faster to use negdw with zero register and then
	; set di to FFFF than to use negdwf (we know highest word will
	; always be FFFF).
	
	mov	cx, bp
	mov	dx, di
	clr	di
	negdw	dxcx, di		;and set di to FFFF than to use negdwf.
	dec	di			;di:dx:cx = DWFixed -1/2 * line width
	
	pop	bp			;restore stack frame
	segmov	ds, ss, si
	lea	si, ss:[boundsDWF]	;ds:si = RectDWFixed
	call	GrObjGlobalExpandRectDWFixedByDWFixed
	pop	ds, si			;restore object pointer
	
	;
	;	Get 1/2 the spacing of the grid so we can
	;	"round" to the correct grid line
	;
	push	bp			;save local ptr
	mov	ax, MSG_VIS_RULER_GET_GRID_SPACING
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToRuler

	;
	;	take half of the grid spacing... well, actually, just *a hair*
	;	less than half,	otherwise repeated alignments will move the
	;	damn things left/up every time...
	;
;	dec	dx			;take off 1/2 point for now...
;	dec	bp

	shrdw	dxcx
	shrdw	bpax

	mov	di, bp			;di <- y int
	pop	bp			;bp <- local ptr
	mov	ss:halfGridSpacing.PDF_x.DWF_int.low, dx
	mov	ss:halfGridSpacing.PDF_x.DWF_frac, cx
	mov	ss:halfGridSpacing.PDF_y.DWF_int.low, di
	mov	ss:halfGridSpacing.PDF_y.DWF_frac, ax
	clr	cx
	mov	ss:halfGridSpacing.PDF_x.DWF_int.high, cx
	mov	ss:halfGridSpacing.PDF_y.DWF_int.high, cx
	pop	cx			;cx <- AlignToGridType

afterBounds:

	push	si			;save chunk handle

	;
	;	check what kind of horizontal alignment we want
	;
	movnf	di, <offset PDF_x>
	test	cl, mask ATGT_LEFT
	jz	checkRight

	negdwf	ss:[halfGridSpacing].PDF_x

	;
	;	We want to align the left edge of the object to the grid.
	;
	movnf	si, <offset RDWF_left>
	call	CalcLocalPoint
	jmp	checkVertical

checkRight:
	test	cl, mask ATGT_RIGHT
	jz	checkHCenter

	;
	;	We want to align the right edge of the object to the grid.
	;
	movnf	si, <offset RDWF_right>
	call	CalcLocalPoint
	jmp	checkVertical

checkHCenter:
	test	cl, mask ATGT_H_CENTER
	jz	noHAlign
	movdwf	ss:[localPoint].PDF_x, ss:[centerDWF].PDF_x, ax
	jmp	checkVertical

noHAlign:
	clr	ax
	clrdwf	ss:[localPoint].PDF_x, ax

checkVertical:	
	;
	;	check what kind of vertical alignment we want
	;
	movnf	di, <offset PDF_y>
	test	cl, mask ATGT_TOP
	jz	checkBottom

	;
	;	We want to align the top edge of the object to the grid.
	;

	negdwf	ss:[halfGridSpacing].PDF_y
	movnf	si, <offset RDWF_top>
	call	CalcLocalPoint
	jmp	callRuler

checkBottom:
	test	cl, mask ATGT_BOTTOM
	jz	checkVCenter

	;
	;	We want to align the bottom edge of the object to the grid.
	;
	movnf	si, <offset RDWF_bottom>
	call	CalcLocalPoint
	jmp	callRuler

checkVCenter:
	test	cl, mask ATGT_V_CENTER
	jz	noVAlign
	movdwf	ss:[localPoint].PDF_y, ss:[centerDWF].PDF_y, ax
	jmp	callRuler

noVAlign:
	clr	ax
	clrdwf	ss:[localPoint].PDF_y, ax
callRuler:

	pop	si					;*ds:si <- GrObj

	;
	;	Use centerDWF to store the unruled localPoint
	;
	movdwf	ss:[centerDWF].PDF_x, ss:[localPoint].PDF_x, ax
	movdwf	ss:[centerDWF].PDF_y, ss:[localPoint].PDF_y, ax

	; 
	; Fudge the point passed to the ruler by a small amount.  See comment
	; at beginning of this routine.
	;
	test	cl, mask ATGT_LEFT or mask ATGT_RIGHT
	jz	topBottomFudge
	mov	dx, ALIGN_FUDGE_EPSILON_LOW
	test	cl, mask ATGT_RIGHT
	jnz	doLeftRight
	neg	dx
doLeftRight:
	movnf	di, <offset PDF_x>
	call	FudgeLocalPointByFraction

topBottomFudge:
	test	cl, mask ATGT_TOP or mask ATGT_BOTTOM
	jz	doneWithFudging
	mov	dx, ALIGN_FUDGE_EPSILON_LOW
	test	cl, mask ATGT_BOTTOM
	jnz	doTopBottom
	neg	dx

doTopBottom:
	movnf	di, <offset PDF_y>
	call	FudgeLocalPointByFraction
	
doneWithFudging:

	;
	;	OK, we've got our localPoint ready to go. Let the
	;	ruler do its thing
	;
	push	bp, cx
	lea	bp, ss:[localPoint]
	mov	cx, mask VRCS_OVERRIDE or VRCS_SNAP_TO_GRID_ABSOLUTE \
					or VRCS_SNAP_TO_GUIDES
	mov	ax, MSG_VIS_RULER_RULE_LARGE_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToRuler
	pop	bp, cx

	;
	;	Calc distance moved
	;
	subdwf	ss:[localPoint].PDF_x, ss:[centerDWF].PDF_x, ax
	subdwf	ss:[localPoint].PDF_y, ss:[centerDWF].PDF_y, ax

	;
	;	Factor in the ruler shift if necessary
	;
	test	cl, mask ATGT_LEFT or mask ATGT_RIGHT
	jz	checkVAdjust

	adddwf	ss:[localPoint].PDF_x, ss:[halfGridSpacing].PDF_x, ax

checkVAdjust:
	test	cl, mask ATGT_TOP or mask ATGT_BOTTOM
	jz	move

	adddwf	ss:[localPoint].PDF_y, ss:[halfGridSpacing].PDF_y, ax
	
move:
	;
	;    Move the object
	;
	push	bp
	lea	bp, ss:[localPoint]
	mov	ax, MSG_GO_MOVE
	call	ObjCallInstanceNoLock
	pop	bp

	jmp	done
GrObjAlignToGrid	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CalcLocalPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Common routine to calculate a DWF value for GrObjAlignToGrid

Pass:		di - offset PDF_*
		si - offset RDWF_*

Return:		localPoint[di] = boundsDWF[si] + halfGridSpacing[di]

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcLocalPoint	proc	near

	.enter	inherit GrObjAlignToGrid


	mov	ax, ss:[boundsDWF][si].DWF_frac
	add	ax, ss:[halfGridSpacing][di].DWF_frac
	mov	ss:[localPoint][di].DWF_frac, ax

	mov	ax, ss:[boundsDWF][si].DWF_int.low
	adc	ax, ss:[halfGridSpacing][di].DWF_int.low
	mov	ss:[localPoint][di].DWF_int.low, ax

	mov	ax, ss:[boundsDWF][si].DWF_int.high
	adc	ax, ss:[halfGridSpacing][di].DWF_int.high
	mov	ss:[localPoint][di].DWF_int.high, ax
	
	.leave
	ret
CalcLocalPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FudgeLocalPointByFraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a fractional amount to localPoint.

CALLED BY:	ONLY BY GrObjAlignToGrid
PASS:		ss:bp	= correct local variables
		dx	= fractional amount to fudge by
		di	= Offset to localPoint
		
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	6/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FudgeLocalPointByFraction	proc	near
	.enter	inherit GrObjAlignToGrid
	
	tst	dx
	jz	done
	
	clr	ax
	tst	dx
	jns	addIt
	dec	ax

addIt:
	add	ss:[localPoint][di].DWF_frac, dx
	adc	ss:[localPoint][di].DWF_int.low, ax
	adc	ss:[localPoint][di].DWF_int.high, ax
	
done:
	.leave
	ret
FudgeLocalPointByFraction	endp

GrObjObscureExtNonInteractiveCode	ends
