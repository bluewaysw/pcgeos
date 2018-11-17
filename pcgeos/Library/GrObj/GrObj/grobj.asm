COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		object.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

Routines:
	Name			Description
	----			-----------
GrObjUnDrawHandlesLow		
DrawHandlesForce		
GrObjConvertFPDWFToRectDWF	
GrObjConvertCoordDWFixed	
GrObjCalcNormalDWFixedMappedCorners	
GrObjOTCalcDWFixedMappedCorners	
GrObjGenerateNormalFourPointDWFixeds 
GrObjOTGenerateFourPointDWFixeds 
GrObjAdjustDimensionsByLineWidth
GrObjGetWWFixedDimensionsFromRectDWF
GrObjConvertDocumentToDocumentOffsetRelative
GrObjSetNormalPARENTDimensions
GrObjGetNormalPARENTDimensions

GrObjCreateNormalTransform	
GrObjDestroyNormalTransform	
GrObjSendActionNotification

GrObjGetDWFPARENTBoundsUpperLeft
GrObjGenerateUndoRemoveFromBodyChain
GrObjGenerateUndoRemoveFromGroupChain
GrObjGenerateUndoAddToBodyChain
GrObjGenerateUndoChangeLocksChain



Method Handlers:
	Name			Description
	----			-----------
GrObjInitialize
GrObjKbdChar
GrObjCalcPARENTDimensions	
GrObjInitBasicData		
GrObjUnDrawSpriteNoDirty  	
GrObjDrawSpriteRaw		
GrObjDrawHandles		
GrObjUnDrawHandles		
GrObjInvertHandles		
GrObjInvalidate
GrObjDrawHandlesForce		
GrObjUnDrawHandlesNoDirty	
GrObjDrawHandlesOpposite	
GrObjDrawHandlesMatch		
GrObjGetDWPARENTBounds		
GrObjGetDWFPARENTBounds	
GrObjGetWWFPARENTBounds	
GrObjGetWWFOBJECTBounds	
GrObjClear			
GrObjClearSansUndo		
GrObjFinalObjFree		
GrObjBecomeEditable
GrObjBecomeUneditable
GrObjGainedTargetExcl
GrObjLostTargetExcl
GrObjDuplicateFloater
GrObjDrawEditIndicator
GrObjUnDrawEditInidicator
GrObjDrawEditIndicatorRaw
GrObjInvertEditIndicator
GrObjNotifyAction
GrObjAlterFTVMCExcl		
GrObjRemoveFromBody
GrObjRemoveFromBodySansUndo
GrObjRemoveFromGroup
GrObjRemoveFromGroupSansUndo
GrObjAddToBody

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
		

	$Id: grobj.asm,v 1.1 97/04/04 18:07:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjAlmostRequiredCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		MSG_META_INITIALIZE - GrObjClass

SYNOPSIS:	Initializes the GrObjInstance data portion

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMetaInitialize method dynamic GrObjClass, MSG_META_INITIALIZE
	.enter

	mov	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	mov	ds:[di].GOI_areaAttrToken,CA_NULL_ELEMENT
	mov	ds:[di].GOI_lineAttrToken,CA_NULL_ELEMENT
	
	.leave
	ret
GrObjMetaInitialize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Initialize the position and size of the object. Additionally,
		initialize to default attriubtes, and 
		any other initialization that needs to be done so that
		the object can be added to the body and drawn.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClas


		ss:bp - GrObjInitializeData
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
	srs	4/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitialize	method dynamic GrObjClass, MSG_GO_INITIALIZE
	uses	cx,dx,bp
	.enter

	;    Set basic instance data of new object
	;    Width, Height = as passed
	;    Center = Position + width/2 height/2
	;    Transform = Identity Matrix
	;

	mov	di,bp					;passed stack frame
	sub	sp,size BasicInit
	mov	bp,sp
	movdwf	ss:[bp].BI_center.PDF_x,ss:[di].GOID_position.PDF_x,ax
	movdwf	ss:[bp].BI_center.PDF_y,ss:[di].GOID_position.PDF_y,ax
	push	ds,si
	segmov	ds,ss,si
	mov	si,bp
	add	si,offset BI_transform
	call	GrObjGlobalInitGrObjTransMatrix
	pop	ds,si
	movwwf	axcx,ss:[di].GOID_width
	movwwf	ss:[bp].BI_width,axcx
	sarwwf	axcx					;half width
	cwd
	adddwf	ss:[bp].BI_center.PDF_x,dxaxcx		;center = left + width/2
	movwwf	axcx,ss:[di].GOID_height
	movwwf	ss:[bp].BI_height,axcx
	sarwwf	axcx					;half height
	cwd
	adddwf	ss:[bp].BI_center.PDF_y,dxaxcx		;center = top + height/2
	mov	ax,MSG_GO_INIT_BASIC_DATA
	call	ObjCallInstanceNoLock
	add	sp,size BasicInit

	mov	ax,MSG_GO_INIT_TO_DEFAULT_ATTRS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjInitialize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitBasicData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have object fill out its basic instance data from the
		passed structure and calculate the remaining data
		from it.

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		ss:bp - BasicInit
RETURN:		
		normalTransform
			OT_center
			OT_width
			OT_weight
			OT_transform
		
DESTROYED:	
		WARNING: May cause block to move and/or chunk to move
		within block

PSEUDO CODE/STRATEGY:
		nothing
			
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitBasicData  method dynamic GrObjClass, MSG_GO_INIT_BASIC_DATA,
					MSG_GO_REPLACE_GEOMETRY_INSTANCE_DATA
	uses	ax,cx,dx
	.enter

	call	GrObjCreateNormalTransform

	push	si				;object chunk
	AccessNormalTransformChunk		di,ds,si
	segmov	es,ds				;dest segment
	segmov	ds,ss				;source segment
	mov	si,bp				;source offset
	mov	dx,di				;dest offset
	addnf	si, <offset BI_center>
	addnf	di, <offset OT_center>
	MoveConstantNumBytes <size PointDWFixed> ,cx

	mov	si,bp				;orig source offset
	mov	di,dx				;orig dest offset
	addnf	si, <offset BI_width>
	addnf	di, <offset OT_width>
	MoveConstantNumBytes <size WWFixed> ,cx

	mov	si,bp				;orig source offset
	mov	di,dx				;orig dest offset
	addnf	si, <offset BI_height>
	addnf	di, <offset OT_height>
	MoveConstantNumBytes <size WWFixed> ,cx

	mov	si,bp				;orig source offset
	mov	di,dx				;orig dest offset
	addnf	si, <offset BI_transform>
	addnf	di, <offset OT_transform>
	MoveConstantNumBytes <size GrObjTransMatrix> ,cx

	pop	si				;object chunk
	segmov	ds,es				;object segment


	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock	

	.leave
	ret
GrObjInitBasicData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCreateNormalTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create or realloc the normal transform chunk

CALLED BY:	INTERNAL
		GrObjInitBasicData

PASS:		
		*ds:si - instance data

RETURN:		
		*ds:[si].GOI_normalTransform set
		ds - updated if block moved

DESTROYED:	
		WARNING - may cause block to move

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateNormalTransform		proc	far
	class	GrObjClass
	uses	ax,cx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si
	mov	di,ds:[di].GOI_normalTransform
	tst	di
	jz	allocChunk

done:
	.leave
	ret

allocChunk:
	mov	cx,size ObjectTransform
	mov	al,mask OCF_DIRTY				;ObjChunkFlags
	call	LMemAlloc
	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_normalTransform,ax
	jmp	done


GrObjCreateNormalTransform		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjNotifyGrObjValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the object that it has a valid normalTransform,
		attributes and such. Clear the invalid bit.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		none
	
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
	srs	2/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNotifyGrObjValid	method dynamic GrObjClass, MSG_GO_NOTIFY_GROBJ_VALID
	.enter

	call	ObjMarkDirty

	BitClr	ds:[di].GOI_optFlags, GOOF_GROBJ_INVALID

	.leave
	ret
GrObjNotifyGrObjValid		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjNotifyGrObjInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the object that it's no longer valid
			

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		none
	
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
	srs	9/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNotifyGrObjInvalid	method dynamic GrObjClass, MSG_GO_NOTIFY_GROBJ_INVALID
	.enter

	call	ObjMarkDirty

	BitSet	ds:[di].GOI_optFlags, GOOF_GROBJ_INVALID

	.leave
	ret
GrObjNotifyGrObjInvalid		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAddPotentialSizeToBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Increments the potential size of this grobj's object block
		by the amount of size the grobj	could potentially expand to.

PASS:		
		*(ds:si) - instance data of object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	17 jul 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAddPotentialSizeToBlock	method dynamic GrObjClass,
				MSG_GO_ADD_POTENTIAL_SIZE_TO_BLOCK
	uses	cx, dx
	.enter

	;
	;  If this object is the floater, it's not in the document, and
	;  thus shouldn't affect the block size
	;
	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jnz	done

	mov	ax,MSG_GO_GET_POTENTIAL_GROBJECT_SIZE
	call	ObjCallInstanceNoLock

	mov	dx, ds:[LMBH_handle]
	mov	ax, MSG_GB_INCREASE_POTENTIAL_EXPANSION
	clr	di
	call	GrObjMessageToBody

done:
	.leave
	ret
GrObjAddPotentialSizeToBlock	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetPotentialGrObjectSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		cx - size in bytes
	
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
	srs	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetPotentialGrObjectSize	method dynamic GrObjClass, 
					MSG_GO_GET_POTENTIAL_GROBJECT_SIZE
	.enter

	mov	di,ds:[si]
	les	di,ds:[di].MB_class
	mov	cx,es:[di].Class_instanceSize
	add	cx,POTENTIAL_BASE_GROBJ_SIZE

	.leave
	ret
GrObjGetPotentialGrObjectSize		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjChangeLocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the GrObjLocks for the object.
		The bits in dx will be cleared before 
		the bits in cx are set.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx - GrObjLocks - bits to set
		dx - GrObjLocks - bits to clear

RETURN:		
		cx - GrObjLocks before change
		dx - GrObjLocks after change

	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjChangeLocks	method dynamic GrObjClass, MSG_GO_CHANGE_LOCKS
	uses	bp
	.enter

	;    If locks lock not set then ok to change locks
	;

	test	ds:[di].GOI_locks, mask GOL_LOCK
	jz	ok

	;    If locks lock going to be cleared then ok to change locks
	;

	test	dx,mask GOL_LOCK
	jz	lockedOut

ok:
	call	GrObjGenerateUndoChangeLocksChain

	test	cx, mask GOL_SELECT
	jnz	unselect

checkEdit:
	test	cx, mask GOL_EDIT
	jnz	unedit

changeLocks:
	;
	;  If we're going to change either the GOL_DELETE or the
	;  GOL_COPY lock, we'll need to update the edit controller
	;

	mov	bp, cx
	or	bp, dx

	GrObjDeref	di,ds,si
	mov	ax,ds:[di].GOI_locks
	push	ax					;original
	not	dx
	andnf	ax, dx
	ornf	ax, cx
	mov	ds:[di].GOI_locks,ax
	mov	dx,ax					;new

	call	ObjMarkDirty

	mov	cx, mask GOUINT_GROBJ_SELECT
	test	bp, mask GOL_DELETE or mask GOL_COPY
	jz	sendNotif
	mov	cx, mask GOUINT_GROBJ_SELECT or mask GOUINT_SELECT
sendNotif:
	call	GrObjOptSendUINotification

	pop	cx					;original

	;    If the draw lock changed states we need to invalidate.
	;

	GrObjDeref	di,ds,si
	mov	ax,ds:[di].GOI_locks
	xor	ax,cx					;cur, orig
	test	ax, mask GOL_DRAW
	jnz	invalidate

done:
	.leave
	ret

unselect:
	mov	ax,MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock
	jmp	checkEdit

unedit:
	push	cx					;locks to set
	mov	cl,DONT_SELECT_AFTER_EDIT
	mov	ax,MSG_GO_BECOME_UNEDITABLE
	call	ObjCallInstanceNoLock
	pop	cx					;locks to set
	jmp	changeLocks


lockedOut:
	;    We can't change the locks, return before and after
	;    as current.
	;

	mov	cx,ds:[di].GOI_locks
	mov	dx,cx
	jmp	done

invalidate:
	mov	ax,MSG_GO_INVALIDATE
	call	ObjCallInstanceNoLock
	jmp	done


GrObjChangeLocks		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoChangeLocksChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for changing locks

CALLED BY:	INTERNAL
		GrObjChangeLocks

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
GrObjGenerateUndoChangeLocksChain		proc	near
	class	GrObjClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>
	
	mov	cx,handle lockString
	mov	dx,offset lockString
	call	GrObjGlobalStartUndoChain
	jc	endChain

	GrObjDeref	di,ds,si
	mov	dx,mask GrObjLocks			;reset them all
	mov	cx,ds:[di].GOI_locks			;set them to current
	mov	ax,MSG_GO_CHANGE_LOCKS			;undo message
	clr	bx					;AddUndoActionFlags
	call	GrObjGlobalAddFlagsUndoAction

endChain:
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjGenerateUndoChangeLocksChain		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetLocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the GrObjLocks for the object.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		ax - GrObjLocks
	
DESTROYED:	
		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5 jul 1992	initial perversion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetLocks	method dynamic GrObjClass, MSG_GO_GET_LOCKS
	.enter

	mov	ax,ds:[di].GOI_locks

	.leave
	ret
GrObjGetLocks		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCombineLocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method or's the grobj's locks into the passed locks;
		this is generally used in combination with other grobjs
		(eg., all the selected grobjs) to find out what is
		allowable and what is not for a set of grobjs
		
PASS:		cx - locks set so far
		dx - locks clear so far

RETURN:		cx, dx - locks updated
	
DESTROYED:	
		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5 jul 1992	initial perversion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCombineLocks	method dynamic GrObjClass, MSG_GO_COMBINE_LOCKS
	.enter

	or	cx, ds:[di].GOI_locks		;cx <- cx OR locks
	not	dx
	and	dx, ds:[di].GOI_locks
	not	dx				;dx <- dx OR (not locks)

	.leave
	ret
GrObjCombineLocks		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetTempStateAndOptFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the GrObjTempState for the object.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		al - GrObjTempState
		ah - GrObjOptimizationFlags	

DESTROYED:	
		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5 jul 1992	initial perversion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetTempStateAndOptFlags	method dynamic GrObjClass, 
					MSG_GO_GET_TEMP_STATE_AND_OPT_FLAGS
	.enter

	mov	al,ds:[di].GOI_tempState
	mov	ah,ds:[di].GOI_optFlags

	.leave
	ret
GrObjGetTempStateAndOptFlags		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate visual bounds of object

PASS:		
		*(ds:si) - instance data

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This method is not dynamic, so the passed 
		parameters are more limited and you must be careful
		what you destroy.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInvalidate method GrObjClass, MSG_GO_INVALIDATE,
				MSG_GO_INVALIDATE_AREA,
				MSG_GO_INVALIDATE_LINE

	uses	di,bp,si,ds,bx
	.enter

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_ADDED_TO_BODY
	jz	done

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done

	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP
	jnz	inGroup


	mov	di, PARENT_GSTATE
	call	GrObjCreateGState

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjGetDWPARENTBounds

	;   Avoid some greebles by expanding rect.
	;

	mov	ax,1
	clr	bx
	adddw	ss:[bp].RD_right,bxax
	adddw	ss:[bp].RD_bottom,bxax
	subdw	ss:[bp].RD_left,bxax
	subdw	ss:[bp].RD_top,bxax
	segmov	ds,ss					;seg RectDWord
	mov	si,bp					;offset RectDWord
	call	GrInvalRectDWord
	add	sp, size RectDWord	

	call	GrDestroyState

done:
	.leave
	ret

inGroup:
	;    To prevent a bunch of little invalidates, all objects
	;    inside groups cause just the group to invalidate.
	;

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di
	
	mov	di,mask MF_FIXUP_DS				;MessageFlags
	mov	ax,MSG_GO_INVALIDATE
	call	GrObjMessageToGroup

	pop	di
	call	ThreadReturnStackSpace

	jmp	done

GrObjInvalidate		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInvalidateWithUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler

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
	srs	3/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInvalidateWithUndo	method dynamic GrObjClass, 
						MSG_GO_INVALIDATE_WITH_UNDO
	.enter

	mov	ax,MSG_GO_INVALIDATE
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_INVALIDATE_WITH_UNDO
	clr	bx
	call	GrObjGlobalAddFlagsUndoAction

	.leave
	ret
GrObjInvalidateWithUndo		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOptInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the object taking into account the
		GrObjMessageOptimizationFlags

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - grobject

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			opt bit not set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOptInvalidate		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_msgOptFlags, mask GOMOF_INVALIDATE
	jnz	send

	call	GrObjInvalidate

done:
	.leave
	ret

send:
	push	ax
	mov	ax,MSG_GO_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	ax
	jmp	done

GrObjOptInvalidate		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBecomeEditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell object to grab edit grab and otherwise become editable.
		The edit grab is also the target exclusive

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		stc - become editable
		clc - didn't become editable, most likely due to edit lock

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBecomeEditable method dynamic GrObjClass, MSG_GO_BECOME_EDITABLE
	.enter

	call	GrObjCanEdit?
	jnc	done

	;   Don't waste time if we are already being edit
	;

	test 	ds:[di].GOI_tempState, mask GOTM_EDITED
	jnz	done

	call	MetaGrabTargetExclLow
	call	MetaGrabFocusExclLow

	stc
done:
	.leave
	ret
GrObjBecomeEditable endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBecomeUneditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell object to release edit grab and otherwise clean up
		from being edit.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cl - AfterEditAction

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBecomeUneditable method dynamic GrObjClass, MSG_GO_BECOME_UNEDITABLE
	uses	ax,dx
	.enter

EC <	cmp	cl,AfterEditAction				>
EC <	ERROR_AE	BAD_AFTER_EDIT_ACTIONS			>

	mov	dl,ds:[di].GOI_tempState

	call	MetaReleaseTargetExclLow
	call	MetaReleaseFocusExclLow

	;   If we weren't actually the edit then don't
	;   do select after edit stuff
	;

	test	dl,mask GOTM_EDITED
	jz	done

	;    If caller requested select after edit then
	;    have it become selected
	;

	cmp	cl, SELECT_AFTER_EDIT
	jne	done

	mov	dl, HUM_NOW
	mov	ax,MSG_GO_BECOME_SELECTED
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GrObjBecomeUneditable endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAlterFTVMCExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab focus and/or target excls from the body.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		cx:dx - optr to grab/release exclusive for
		bp - MetaAlterFTVMCExclFlags

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAlterFTVMCExcl	method dynamic GrObjClass, 
						MSG_META_MUP_ALTER_FTVMC_EXCL
	.enter

	BitClr	bp, MAEF_NOT_HERE
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody

	.leave

	Destroy	ax,cx,dx,bp

	ret

GrObjAlterFTVMCExcl		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notfiy object that is has gained the targetExcl, which
		means it can be edited.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGainedTargetExcl	method dynamic GrObjClass,  MSG_META_GAINED_TARGET_EXCL
	.enter


	;    Since the body passes MSG_META_SUSPEND and MSG_META_UNSUSPEND
	;    onto the objects with the target
	;    if an object gains the target while the body
	;    is already suspended then the object must match the 
	;    body's suspend count. Otherwise the object could
	;    receive unbalanced unsuspends from the body.
	;

	mov	ax,MSG_META_SUSPEND
	call	GrObjMatchSuspend

	;    Clear any extraneous flags
	;

	andnf	ds:[di].GOI_actionModes, not (	mask GOAM_MOVE or \
						mask GOAM_RESIZE or \
						mask GOAM_ROTATE or \
						mask GOAM_ACTION_PENDING or \
						mask GOAM_ACTION_HAPPENING or \
						mask GOAM_ACTION_ACTIVATED )

	;    Search/Replace and Spell can give the target
	;    to grobjects without my control. If we didn't empty the
	;    selection list here, other objects would remain selected
	;    while a text object was being edited.
	;

	call	GrObjRemoveGrObjsFromSelectionList

	mov	cl, mask GOTM_EDITED
	clr	ch
	call	GrObjChangeTempStateBits

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;gstate
	mov	ax,MSG_GO_DRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock
	call	GrDestroyState

	mov	cx, mask GrObjUINotificationTypes
	call	GrObjOptSendUINotification

	Destroy 	ax,cx,dx,bp

	.leave
	ret
GrObjGainedTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify object that is has lost the target.
		The object can no longer be edited.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLostTargetExcl		method dynamic GrObjClass, 
						MSG_META_LOST_TARGET_EXCL
	.enter

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;gstate
	mov	ax,MSG_GO_UNDRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock
	mov	di,dx					;gstate
	call	GrDestroyState

	;    Need to send ui update before clearing the edit bit
	;    so that when a text object loses the target it will
	;    notify the body so that the body can tell the
	;    attribute manager to show the default attrs.
	;

	mov	cx,mask GrObjUINotificationTypes
	call	GrObjOptSendUINotification

	clr	cl
	mov	ch,  mask GOTM_EDITED
	call	GrObjChangeTempStateBits

	;    Since the body passes MSG_META_SUSPEND and MSG_META_UNSUSPEND
	;    onto the objects with the target
	;    if an object gains the target while the body
	;    is already suspended then the object must match the 
	;    body's suspend count. Otherwise the object would
	;    be left suspended permanently.
	;

	mov	ax,MSG_META_UNSUSPEND
	call	GrObjMatchSuspend

	.leave

	Destroy 	ax,cx,dx,bp

	ret
GrObjLostTargetExcl		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjLostFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are in create mode when we lose the focus, then
		terminate that create.
	
		Bad things happen if vis objects get discarded while
		they have the focus, so we inced the interactible
		count in gained focus.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLostFocusExcl	method dynamic GrObjClass, 
						MSG_META_LOST_FOCUS_EXCL
	.enter

	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jnz	done

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jz	done

	;    Send via queue to avoid a message circle if END_CREATE
	;    caused the focus to be released.
	;

	mov	bx,ds:[LMBH_handle]
	mov	di,mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	clr	cx				;EndCreatePassFlags
	mov	ax,MSG_GO_END_CREATE
	call	ObjMessage

done:
	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjLostFocusExcl		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGainedSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set bit in object so that we know we know that the
		body is the system target and draw handles and edit
		indicator as necessary

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGainedSysTargetExcl	method dynamic GrObjClass, 
					MSG_META_GAINED_SYS_TARGET_EXCL

	.enter

	mov	cl,TRUE
	mov	ax,MSG_GO_SET_SYS_TARGET
	call	ObjCallInstanceNoLock

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjGainedSysTargetExcl		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjLostSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear bit in object so that we know we know that the
		body is the system target

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLostSysTargetExcl	method dynamic GrObjClass, 
						MSG_META_LOST_SYS_TARGET_EXCL
	.enter

	mov	cl,FALSE
	mov	ax,MSG_GO_SET_SYS_TARGET
	call	ObjCallInstanceNoLock

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjLostSysTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetSysTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update object with status of system target
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cl - TRUE/FALSE

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
	srs	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetSysTarget	method dynamic GrObjClass, 
					MSG_GO_SET_SYS_TARGET
	uses	cx,dx
	.enter

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di				;gstate

	cmp	cl,FALSE
	je	clearSysTarget

	mov	cl,mask GOTM_SYS_TARGET
	clr	ch
	call	GrObjChangeTempStateBits

	mov	ax,MSG_GO_DRAW_HANDLES
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GO_DRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

destroyGState:
	mov	di,dx
	call	GrDestroyState

	.leave

	Destroy	ax,cx,dx,bp

	ret

clearSysTarget:
	clr	cl
	mov	ch,mask GOTM_SYS_TARGET
	call	GrObjChangeTempStateBits

	mov	ax,MSG_GO_UNDRAW_HANDLES
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GO_UNDRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

	jmp	destroyGState

GrObjSetSysTarget		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawEditIndicator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws edit indicator to indicate object is selected. 
 
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		dx - BODY_GSTATE gstate

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		if not edited don't draw
		if edit indicator are already drawn don't draw

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		This method should be optimized for SMALL SIZE over SPEED.

		Common cases:
			The object will have GOTM_EDITED set


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawEditIndicator method dynamic GrObjClass, MSG_GO_DRAW_EDIT_INDICATOR
	uses	ax,cx
	.enter

	test	ds:[di].GOI_tempState, mask GOTM_EDITED
	jz	done
	test	ds:[di].GOI_tempState, mask GOTM_SYS_TARGET
	jz	done

	;   if the object edit indicator is already drawn
	;   then don't draw edit indicator
	;


	test	ds:[di].GOI_tempState, mask GOTM_EDIT_INDICATOR_DRAWN
	jnz	done

	;    Mark edit indicator as being draw
	;

	mov	cl, mask GOTM_EDIT_INDICATOR_DRAWN
	clr	ch
	call	GrObjChangeTempStateBits

	;    Draw those edit indicator
	;

	mov	ax,MSG_GO_INVERT_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

GrObjDrawEditIndicator endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUnDrawEditIndicator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the edit indicator if it is drawn

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		dx - gstate

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED.

		Common cases:
			The object will have GOTM_EDIT_INDICATOR_DRAWN set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUnDrawEditIndicator method dynamic GrObjClass, 
						MSG_GO_UNDRAW_EDIT_INDICATOR
	uses	ax,cx
	.enter

	;    If the edit indicator are not drawn then don't erase them
	;

	test	ds:[di].GOI_tempState, mask GOTM_EDIT_INDICATOR_DRAWN
	jz	done

	;    Mark edit indicator as not drawn
	;

	clr	cl
	mov	ch,  mask GOTM_EDIT_INDICATOR_DRAWN
	call	GrObjChangeTempStateBits
	
	;    Erase those edit indicator
	;

	mov	ax,MSG_GO_INVERT_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GrObjUnDrawEditIndicator endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawEditIndicatorRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to update the edit indicator during an expose event. 
		Draws the edit indicator if the edit indicatorDraw flag is set,
		otherwise does nothing

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		dx - gstate of expose

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	If the edit indicator is drawn, then
		draw them again because they may have been crunged.

	If the edit indicator isn't drawn, then
		do nothing, you'll only make it worse.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED.

		Common cases:
			The object will have GOTM_EDIT_INDICATOR_DRAWN set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawEditIndicatorRaw method dynamic GrObjClass, 
						MSG_GO_DRAW_EDIT_INDICATOR_RAW
	uses	ax
	.enter

	test	ds:[di].GOI_tempState, mask GOTM_EDIT_INDICATOR_DRAWN
	jz	done					

	mov	ax,MSG_GO_INVERT_EDIT_INDICATOR
	call	ObjCallInstanceNoLock
done:
	.leave

	ret	
GrObjDrawEditIndicatorRaw endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInvertEditIndicator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inverts edit indicator of selected object.
		This default handler draws the object's sprite
		as the edit indicator

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		dx - gstate

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED.

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInvertEditIndicator	method dynamic GrObjClass, 
						MSG_GO_INVERT_EDIT_INDICATOR
	uses	cx,dx,bp
	.enter

	mov	di,dx					;gstate	
EC <	call	ECCheckGStateHandle			>

	call	GrSaveTransform
	call	GrObjApplyNormalTransform

	;    Set attributes for drawing sprite
	;
		
	GrObjApplySpriteAttrs

	;   Calc rect -w/2-1,-h/2-1,w/2+1,h/2+1, that encompasses object
	;   without overlapping any of the data
	;

	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetNormalOBJECTDimensions
	
	sub	sp,size PointDWFixed
	mov	bp,sp
	mov	ss:[bp].PDF_x.DWF_int.high,0
	mov	ss:[bp].PDF_y.DWF_int.high,0
	mov	ss:[bp].PDF_x.DWF_int.low,2
	mov	ss:[bp].PDF_y.DWF_int.low,2
	mov	ss:[bp].PDF_x.DWF_frac,0
	mov	ss:[bp].PDF_y.DWF_frac,0
	push	si
	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTConvertVectorPARENTToOBJECT
	pop	si

	push	bx,ax					;height adjust
	mov	bx,ss:[bp].PDF_x.DWF_int.low
	mov	ax,ss:[bp].PDF_x.DWF_frac
	tst	bx
	jns	10$
	negwwf	bxax
10$:
	addwwf	dxcx,bxax				;adjust width
	pop	bx,ax					;height adjust
	push	dx,cx					;width
	mov	dx,ss:[bp].PDF_x.DWF_int.low
	mov	cx,ss:[bp].PDF_x.DWF_frac
	tst	dx
	jns	20$
	negwwf	dxcx
20$:
	addwwf	bxax,dxcx				;adjust height
	pop	dx,cx
	add	sp,size PointDWFixed
	
	call	GrObjCalcIncreasedResolutionCorners

	;    Draw that sucker
	;

	call	GrDrawRect

	call	GrRestoreTransform

	.leave
	ret
	
GrObjInvertEditIndicator endm



GrObjAlmostRequiredCode	ends


GrObjRequiredInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we get a keyboard char bounce it back up to the
		body.

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
	srs	5/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjKbdChar	method dynamic GrObjClass, MSG_META_KBD_CHAR
	.enter

	mov	ax,MSG_META_FUP_KBD_CHAR
	clr	di
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	.leave
	ret
GrObjKbdChar		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GrObj won't be receiving any more messages, so
		vaporize any remaining chunks, data.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjFinalObjFree	method dynamic GrObjClass, MSG_META_FINAL_OBJ_FREE
	.enter

	mov	ax, MSG_GO_SUBTRACT_POTENTIAL_SIZE_FROM_BLOCK
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_NUKE_DATA_IN_OTHER_BLOCKS
	call	ObjCallInstanceNoLock

	;    Nuke normal and sprite transforms
	;

	clr	ax
	GrObjDeref	di,ds,si
	xchg	ax,ds:[di].GOI_normalTransform
	tst	ax
	jz	checkSprite
	call	LMemFree

checkSprite:
	clr	ax
	GrObjDeref	di,ds,si
	xchg	ax,ds:[di].GOI_spriteTransform
	tst	ax
	jz	callSuper
	call	LMemFree

callSuper:
	mov	ax,MSG_META_FINAL_OBJ_FREE
	mov	di,offset GrObjClass
	call	ObjCallSuperNoLock

	.leave

	Destroy 	ax,cx,dx,bp

	ret
GrObjFinalObjFree		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a grobject *now*

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
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjObjFree	method dynamic GrObjClass, MSG_GO_OBJ_FREE, 
				MSG_GO_OBJ_FREE_GUARANTEED_NO_QUEUED_MESSAGES
	uses	cx,dx,bp
	.enter

	call	ObjIncInUseCount
	mov	ax, MSG_META_FINAL_OBJ_FREE
	call	ObjCallInstanceNoLock
	
	.leave
	ret

GrObjObjFree		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjQuickTotalBodyClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler for MSG_GO_QUICK_TOTAL_BODY_CLEAR

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
	srs	3/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjQuickTotalBodyClear	method dynamic GrObjClass, 
						MSG_GO_QUICK_TOTAL_BODY_CLEAR
	.enter

	mov	ax,MSG_GO_NUKE_DATA_IN_OTHER_BLOCKS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjQuickTotalBodyClear		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjNukeDataInOtherBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for MSG_GO_NUKE_DATA_IN_OTHER_BLOCKS

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
	srs	9/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNukeDataInOtherBlocks	method dynamic GrObjClass, 
						MSG_GO_NUKE_DATA_IN_OTHER_BLOCKS
	uses	cx
	.enter

	;    Clear all temp state bits. Must do this so we don't
	;    leave the in use count hosed.
	;

	clr	cl
	mov	ch,mask GrObjTempModes	
	call	GrObjChangeTempStateBits

	movnf	cx,CA_NULL_ELEMENT
	GrObjDeref	di,ds,si
	xchg	cx,ds:[di].GOI_areaAttrToken
	call	GrObjDerefGrObjAreaToken

	movnf	cx,CA_NULL_ELEMENT
	GrObjDeref	di,ds,si
	xchg	cx,ds:[di].GOI_lineAttrToken
	call	GrObjDerefGrObjLineToken

	.leave
	ret
GrObjNukeDataInOtherBlocks		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjClearSansUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell object to kill itself without undo.
		Note: This routine ignores the delete lock.

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
			object is the floater

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjClearSansUndo	method dynamic GrObjClass, 
						MSG_GO_CLEAR_SANS_UNDO
	uses	cx,dx,bp
	.enter

	call	GrObjGlobalUndoIgnoreActions

	;    Send out our query delete notification
	;

	mov	bp, GOANT_QUERY_DELETE
	call	GrObjOptNotifyAction

	;    Objects in groups are always deleteable no matter
	;    what the action notification returns.
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP
	jnz	checkFloater

	;    Bail if the object we notified doesn't want the object
	;    to be deleted
	;

	tst	bp				
	jz	done

checkFloater:
	;    The floater was never added to the body, but it may still
	;    have the mouse grab, so make sure to release it. Normally
	;    the mouse is release by MSG_GO_REMOVE_FROM_BODY.
	;

	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jz	remove

	mov	ax,MSG_GO_RELEASE_MOUSE
	call	ObjCallInstanceNoLock

accept:
	call	GrObjGlobalUndoAcceptActions

	mov	bp, GOANT_DELETED
	call	GrObjOptNotifyAction

	;    Always use queue flushing. This solves bug when destroying
	;    an object that was so small it was thrown away.
	;

	mov	ax,MSG_META_OBJ_FREE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

remove:
	;    Save some branching code and just call both remove messages.
	;    The handlers are smart enough to do nothing if need be.
	;

	mov	ax,MSG_GO_REMOVE_FROM_GROUP
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GO_REMOVE_FROM_BODY
	call	ObjCallInstanceNoLock
	jmp	accept

GrObjClearSansUndo		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjClearIfNotWithinBodyBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell object to kill itself if it's not within the body's bounds

PASS:		
		nothing

RETURN:		
		carry set if object nuked itself
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			object is the floater

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjClearIfNotWithinBodyBounds	method dynamic GrObjClass, 
				MSG_GO_CLEAR_IF_NOT_WITHIN_BODY_BOUNDS
	.enter

	;
	;  Get object's bounds
	;
	sub	sp, size RectDWord
	mov	bp, sp
	mov	di, bp
	mov	ax, MSG_GO_GET_DW_PARENT_BOUNDS
	call	ObjCallInstanceNoLock

	;
	;  Get body bounds
	;

	sub	sp, size RectDWord
	mov	bp, sp
	mov	ax, MSG_GB_GET_BOUNDS
	push	di
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToBody
	pop	di

	xchg	si, bp
	mov	ax, ss
	push	ds
	mov	ds, ax					;ss:di <- body bounds
	mov	es, ax					;ss:di <- grobj bounds

	call	GrObjIsRectDWordOverlappingRectDWord?
	pop	ds
	cmc						;switch context
	jnc	done					;branch if in bounds

	mov	si, bp
	mov	ax, MSG_GO_CLEAR_SANS_UNDO
	call	ObjCallInstanceNoLock

	stc						;indicate death

done:

	lahf
	add	sp, 2 * size RectDWord
	sahf

	.leave
	ret
GrObjClearIfNotWithinBodyBounds		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjRemoveFromBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the object from the body
		and generate an undo chain to undo this.
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
	srs	8/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRemoveFromBody	method dynamic GrObjClass, 
						MSG_GO_REMOVE_FROM_BODY
	uses	cx,dx
	.enter

	;    Objects in groups will still have their ADDED_TO_BODY
	;    flag set if the group has been added to the body, so we
	;    must check both bits.
	;

	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP
	jnz	done
	test	ds:[di].GOI_optFlags, mask GOOF_ADDED_TO_BODY
	jz	done

	mov	ax,MSG_GO_RELEASE_EXCLS
	call	ObjCallInstanceNoLock

	;   Must invalidate so that when undoing an add with this
	;   message the area the object just vacated will redraw
	;

	call	GrObjOptInvalidate

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GB_REMOVE_GROBJ
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

done:
	.leave
	ret

GrObjRemoveFromBody		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUnGroupable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object consists of collection of objects in a
		group that can be broken up into the indivdual objects


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		clc - not ungroupable

		
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUnGroupable method dynamic GrObjClass, MSG_GO_UNGROUPABLE
	clc
	ret
GrObjUnGroupable		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAnotherToolActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Sent to the object with the selection when another tool is activated.
	Receiving object decides whether to drop selection based on tool
	activating

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx:dx - od of caller
		bp - AnotherToolActivatedFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAnotherToolActivated	method GrObjClass, 
					MSG_GO_ANOTHER_TOOL_ACTIVATED
	uses	ax,cx
	.enter

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jnz	endCreate

checkEdit:
	mov	cl,SELECT_AFTER_EDIT
	test	bp, mask ATAF_STANDARD_POINTER
	jnz	unedit
	mov	cl,DONT_SELECT_AFTER_EDIT
unedit:
	mov	ax,MSG_GO_BECOME_UNEDITABLE
	call	ObjCallInstanceNoLock

	;    Both standard pointers and shapes can manipulate
	;    our handles so remain on the selection list
	;    if already selected. This also helps out quick move/copy
	;    so that newly created shape can stay selected.
	;

	test	bp, mask ATAF_STANDARD_POINTER or mask ATAF_SHAPE
	jnz	done

	mov	ax,MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock
done:
	.leave
	ret

endCreate:
	clr	cx				;EndCreatePassFlags
	mov	ax,MSG_GO_END_CREATE
	call	ObjCallInstanceNoLock
	jmp	checkEdit

GrObjAnotherToolActivated		endp




GrObjRequiredInteractiveCode	ends






GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjRelocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with relocation and unrelocation of objects

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper
RETURN:		carry - set if error
		bp - unchanged

DESTROYED:	
		ax,cx,dx

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRelocation	method dynamic GrObjClass, reloc
	.enter

	;    If the object is being relocated after being read from the
	;    file then it can't be realized
	;

	cmp	dx,VMRT_RELOCATE_AFTER_READ
	jne	done


	;    Clear any suspension. Otherwise if we crashed and it 
	;    was set it would never get cleared again.
	;

	mov	ax,ATTR_GO_ACTION_NOTIFICATION
	call	ObjVarFindData
	jnc	clearStuff
	clr	ds:[bx].GOANS_suspendCount

clearStuff:
	GrObjDeref	di,ds,si

	;    Auto save should be disabled during create,
	;    resize/move/rotate etc
	;

EC <	test	ds:[di].GOI_actionModes,mask GOAM_CREATE		>
EC <	ERROR_NZ GROBJ_GROBJECT_BEING_CREATED_SAVED_TO_FILE	>
EC <	tst	ds:[di].GOI_actionModes				>
EC <	ERROR_NZ GROBJ_GROBJECT_BEING_MODIFIED_SAVED_TO_FILE	>

	;    Since the object is just being read in, it can't be
	;    selected, have handles drawn, etc. So, nothing in
	;    tempState can be set.  
	;

	clr	ds:[di].GOI_tempState

done:
	.leave
	mov	di, offset GrObjClass
	call	ObjRelocOrUnRelocSuper
	ret

GrObjRelocation	endm

GrObjDrawCode	ends

GrObjRequiredCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOptNotifyAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out action notifications taking into account the
		GrObjMessageOptimizationFlags

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object
		bp - GrObjActionNotificationType

RETURN:		
		bp - based on GrObjActionNotificationType
		     GOANT_PRE_DELETE - zero to abort the deletion

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
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOptNotifyAction		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_msgOptFlags, mask GOMOF_NOTIFY_ACTION
	jnz	send
	call	GrObjNotifyAction
done:
	.leave
	ret

send:
	mov	ax,MSG_GO_NOTIFY_ACTION
	call	ObjCallInstanceNoLock
	jmp	done
	

GrObjOptNotifyAction		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjNotifyAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out action notification if it has been defined.
		Have grobject send out notification that an action has
		been performed on it. The notification OD and message
		is stored in var data at ATTR_GO_ACTION_NOTIFICATION.
		If the grobject has no such var data it must check
		the body for notification info, ATTR_GB_ACTION_NOTIFICATION


PASS:		
		*(ds:si) - instance data of object

		bp - GrObjActionNotificationType

RETURN:
		bp - based on GrObjActionNotificationType
		     GOANT_QUERY_DELETE - zero to abort the deletion
	
DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE
		because it is called from many places.

		Common cases:
			unknown

		WARNING: This method is not dynamic, so the passed 
		parameters are more limited and you must be careful
		what you destroy.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNotifyAction	method GrObjClass, MSG_GO_NOTIFY_ACTION
	uses	ax,bx,cx,dx,di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjCanSendActionNotification?
	jnc	done

	call	GrObjActionNotificationSuspendedInBody?
	jc	done

	call	GrObjSendWrapChangeNotification

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_HAS_ACTION_NOTIFICATION
	jnz	attemptSend
	
	call	GrObjSendActionNotificationViaBody

done:
	.leave
	ret

attemptSend:
	mov	ax,ATTR_GO_ACTION_NOTIFICATION
	call	ObjVarFindData

	;    If suspendCount is non-zero don't send any action notification
	;

	tst	ds:[bx].GOANS_suspendCount
	jnz	done

	;    Send action notification through od in var data
	;

	mov	cx,ds:[LMBH_handle]			;objects handle
	mov	dx,si					;objects chunk
	mov	ax,MSG_GROBJ_ACTION_NOTIFICATION
	mov	si,ds:[bx].GOANS_optr.chunk
	mov	bx,ds:[bx].GOANS_optr.handle
	mov	di,mask MF_FIXUP_DS or mask MF_CALL	;so we can get BP
	call	ObjMessage
	jmp	done

GrObjNotifyAction		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSendWrapChangeNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the object has a GrObjWrapTextType other than
		none and it has moved, resized or otherwise
		changed it's geometry then send out a
		GOANT_WRAP_CHANGED or GOANT_PRE_WRAP_CHANGE
		notification also		

CALLED BY:	INTERNAL
		GrObjNotifyAction

PASS:		
		*ds:si - grobject
		bp - GrObjActionNotificationType

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
	srs	9/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSendWrapChangeNotification		proc	near
	class	GrObjClass 
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject		>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags, mask GOAF_WRAP
	jnz	wrapObject

done:
	.leave
	ret

wrapObject:
	push	es,ax,cx,bp			;don't destroy
	segmov	es,cs
	mov	ax,bp
	mov	di,offset PreActionTable
	mov	cx,length PreActionTable
	repne	scasw
	jz	sendPreWrap
	mov	di,offset ActionTable
	mov	cx,length ActionTable
	repne	scasw
	jnz	doneWrap

	mov	bp,GOANT_WRAP_CHANGED
	call	GrObjOptNotifyAction
	jmp	doneWrap

sendPreWrap:
	mov	bp,GOANT_PRE_WRAP_CHANGE
	call	GrObjOptNotifyAction

doneWrap:
	pop	es,ax,cx,bp			;don't destroy
	jmp	done

GrObjSendWrapChangeNotification		endp

PreActionTable	word	\
	GOANT_PRE_MOVE,
	GOANT_PRE_RESIZE,
	GOANT_PRE_ROTATE,
	GOANT_PRE_SKEW,
	GOANT_PRE_TRANSFORM,
	GOANT_PRE_SPEC_MODIFY,
	GOANT_QUERY_DELETE

ActionTable	word	\
	GOANT_MOVED,
	GOANT_RESIZED,
	GOANT_ROTATED,
	GOANT_SKEWED,
	GOANT_TRANSFORMED,
	GOANT_SPEC_MODIFIED,
	GOANT_PASTED,
	GOANT_UNDO_GEOMETRY,
	GOANT_CREATED



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanSendActionNotification?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object is allowed to send action notification

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can send action notification

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanSendActionNotification?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done

	stc

done:
	.leave
	ret

GrObjCanSendActionNotification?		endp

GrObjRequiredCode	ends


GrObjExtInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDuplicateFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Copy object to different block. Copies instance data 
		and normalTransform chunk if it exists. spriteTransform
		chunk, object links and other uncopyable data is
		zeroed out.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx:dx - od of body

RETURN:		
		cx:dx - OD of new object

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		WARNING: May cause block to move and/or chunk to move
		within block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDuplicateFloater	method dynamic GrObjClass, MSG_GO_DUPLICATE_FLOATER
	uses	ax,bp
	.enter

EC <	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER 		>
EC <	ERROR_Z OBJECT_BEING_DUPLICATED_IS_NOT_THE_FLOATER	>

	;    Get block from body and lock it
	;

	push	si				;object chunk
	mov	bx,cx				;body handle
	mov	si,dx				;body chunk
	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	bx,cx				;dest block
	call	ObjLockObjBlock
	mov	es,ax				;dest segment
	pop	si				;object chunk

	;    Copy object instance data
	;

	mov	ax,si				;source chunk
	call	GrObjCopyChunk

	;    Copy normalTransform and store new chunk handle in
	;    dest object
	;
	
	push	ax				;new chunk
	GrObjDeref	di,ds,si
	mov	ax,ds:[di].GOI_normalTransform	;source chunk
	call	GrObjCopyChunk
	pop	si				;new chunk
	GrObjDeref	di,es,si
	mov	es:[di].GOI_normalTransform,ax

	;    Zero out uncopyable data in new block
	;

	clr	ax
	mov	es:[di].GOI_spriteTransform,ax
	mov	es:[di].GOI_drawLink.handle,ax
	mov	es:[di].GOI_drawLink.chunk,ax
	mov	es:[di].GOI_reverseLink.handle,ax
	mov	es:[di].GOI_reverseLink.chunk,ax
	andnf	es:[di].GOI_optFlags, not (mask GOOF_ADDED_TO_BODY or \
					mask GOOF_IN_GROUP or \
					mask GOOF_FLOATER) 
	mov	es:[di].GOI_actionModes,al
	mov	es:[di].GOI_tempState,al

	;    Until otherwise notified, this object is invalid
	;    since the floater didn't have attributes
	;

	ornf	es:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID

	;
	;	Tell the new grobj to add its potential size to the block
	;
	segmov	ds, es
	mov	ax, MSG_GO_ADD_POTENTIAL_SIZE_TO_BLOCK
	call	ObjCallInstanceNoLock

	;    Don't drag any var data in from the floater
	;

	mov	cx,0
	mov	dx,0xffff
	clr	bp					;delete it all
	call	ObjVarDeleteDataRange

	;    Unlock dest block

	call	MemUnlock

	;    Return newly created object
	;

	mov		cx,bx			;new object handle
	mov		dx,si			;new object chunk

	.leave
	ret
GrObjDuplicateFloater		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInvertGrObjSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert rectangular sprite of object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		dx - gstate 

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInvertGrObjSprite	method dynamic GrObjClass,
					MSG_GO_INVERT_GROBJ_SPRITE
	uses	cx,dx
	class	GrObjClass
	.enter

	mov	di,dx					;gstate
	call	GrObjGetParentGStateStart
	mov	dx, di
EC <	call	ECCheckGStateHandle			>
	CallMod	GrObjApplySpriteTransform	
	jnc	applySpriteAttrs

	GrObjApplySimpleSpriteAttrs

drawSprite:
	mov	ax,MSG_GO_DRAW_SPRITE_LINE_HI_RES
	GrObjDeref	bx,ds,si
	test	ds:[bx].GOI_tempState,mask GOTM_SPRITE_DRAWN_HI_RES
	jnz	send
	mov	ax,MSG_GO_DRAW_SPRITE_LINE

send:
	call	ObjCallInstanceNoLock
	call	GrObjGetGStateEnd

	.leave
	ret

applySpriteAttrs:

	GrObjApplySpriteAttrs
	jmp	drawSprite

GrObjInvertGrObjSprite endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawSpriteLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide rectangular outline as default handler so
		that sprites will work.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		dx - gstate to draw through

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawSpriteLine	method dynamic GrObjClass,
						MSG_GO_DRAW_SPRITE_LINE
	class	GrObjClass
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetSpriteOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawRect

	.leave
	ret
GrObjDrawSpriteLine		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawSpriteLineHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide rectangular outline as default handler so
		that sprites will work.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		dx - gstate to draw through

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawSpriteLineHiRes	method dynamic GrObjClass,
						MSG_GO_DRAW_SPRITE_LINE_HI_RES
	class	GrObjClass
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	call	GrSaveTransform
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetSpriteOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	GrDrawRect
	call	GrRestoreTransform

	.leave
	ret
GrObjDrawSpriteLineHiRes		endp









COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDestroyNormalTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the normal data chunk

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data

RETURN:		
		GOI_normalTransform = 0

DESTROYED:	
		nothing
	
PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDestroyNormalTransform		proc	far
	uses	ax,di
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si	
	clr	ax
	xchg	ax,ds:[di].GOI_normalTransform
EC <	tst	ax						>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST			>

	call	LMemFree

	.leave
	ret
GrObjDestroyNormalTransform		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawSpriteRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to update sprite image during an expose event. Draws
		the appropriate sprite if the spriteDrawn flag is set, 
		otherwise does nothing.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
		dx - gstate


RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	If the sprite is drawn, draw them again because they may have been
		damaged.
	If the sprite isn't drawn, do nothing, you'll only make it worse.
		
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawSpriteRaw method dynamic GrObjClass, MSG_GO_DRAW_SPRITE_RAW
	uses	ax
	.enter

EC <	xchg	di,dx						>
EC <	call	ECCheckGStateHandle				>
EC <	xchg	di,dx

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	floater

normal:
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	done

	test	ds:[di].GOI_tempState, mask GOTM_SPRITE_DRAWN
	jz	done
	
	mov	ax,MSG_GO_INVERT_GROBJ_SPRITE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret	


floater:
	;    We are the floater see if we are moving/resizing/etc someone
	;    who needs to draw its sprite
	;

	test	ds:[di].GOI_actionModes, 	mask GOAM_RESIZE or \
					mask GOAM_MOVE or \
					mask GOAM_ROTATE
	jz	normal

	call	PointerSendToActionGrObj
	jc	done

	clr	di
	call	GrObjSendToSelectedGrObjs
	jmp	done

GrObjDrawSpriteRaw endm




GrObjExtInteractiveCode ends



GrObjExtNonInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSubtractPotentialSizeFromBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrements the potential size of this grobj's object block
		by the amount of size the grobj	could potentially expand to.

PASS:		
		*(ds:si) - instance data of object

RETURN:		
		nothing

DESTROYED:	
		ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	17 jul 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSubtractPotentialSizeFromBlock	method dynamic GrObjClass,
				MSG_GO_SUBTRACT_POTENTIAL_SIZE_FROM_BLOCK
	.enter

	;    Floater is not in the document
	;

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	done

	mov	ax,MSG_GO_GET_POTENTIAL_GROBJECT_SIZE
	call	ObjCallInstanceNoLock

	mov	dx, ds:[LMBH_handle]
	mov	ax, MSG_GB_DECREASE_POTENTIAL_EXPANSION
	clr	di
	call	GrObjMessageToBody

done:

	.leave
	ret
GrObjSubtractPotentialSizeFromBlock	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanClear?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can be deleted. Must send out
		GOANT_QUERY_DELETE action notification as
		part of this.
		
		NOTE: Object's in groups must always be deletable. The
		code in the group depends on this.


CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - Object

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			can clear the object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanClear?		proc	far
	class	GrObjClass
	uses	di
	.enter
EC <	call	ECGrObjCheckLMemObject			>

	;    Objects in groups can always be deleted regardless
	;    of their lock setting.
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP
	jnz	sendAction
	test	ds:[di].GOI_locks,mask GOL_DELETE
	jnz	fail

sendAction:
	mov	bp, GOANT_QUERY_DELETE
	call	GrObjOptNotifyAction
	
	;    We must always send out the action notifiction
	;    but since objects in groups must always be deletable
	;    we may need to ignore the return value from the action
	;    notification.
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP
	jnz	success

	;    Bail if the object we notified doesn't want the object
	;    to be deleted
	;

	tst	bp				
	jz	fail

success:
	stc

done:
	.leave
	ret

fail:
	clc
	jmp	done

GrObjCanClear?		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell object to kill itself in an undoable fashion

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
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjClear method dynamic GrObjClass, MSG_GO_CLEAR

	uses	bp

	.enter

EC <	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER		>
EC <	ERROR_NZ	GROBJ_CANT_CLEAR_FLOATER_WITH_UNDO		>

	call	GrObjCanClear?
	jnc	done

	;    Merge undo chains associated with clearing an object
	;    into a meta undo chain
	;

	mov	cx,handle deleteString
	mov	dx,offset deleteString
	call	GrObjGlobalStartUndoChain

	;    Save some branching code and just call both remove messages.
	;    The handlers are smart enough to do nothing if need be.
	;

	mov	ax,MSG_GO_REMOVE_FROM_GROUP
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GO_REMOVE_FROM_BODY
	call	ObjCallInstanceNoLock

	; Notify any interested parties that we're going away
	;
	mov	bp, GOANT_DELETED
	call	GrObjOptNotifyAction

	;    If ignoring undo actions is on we must destroy the 
	;    object ourselves because there will be no undo action to 
	;    do it for us. In destroying the object ourselves we must
	;    make sure that there are no undo actions which will send
	;    us messages if freed or undone.
	;

	call	GenProcessUndoCheckIfIgnoring
	tst	ax
	jnz	ignoring

	;
	; Generate the undo chain. If undo has been aborted, then this
	; object will get deleted immediately, so no code after this
	; call should count on the object existing.
	;
	
	mov	ax,MSG_GO_GENERATE_UNDO_CLEAR_CHAIN
	call	ObjCallInstanceNoLock

endUndoChain:
	call	GrObjGlobalEndUndoChain

done:
	.leave
	ret

ignoring:
	call	GrObjFreeObjectAppropriately
	jmp	endUndoChain


GrObjClear endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjReleaseExcls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release any excls, mouse grab, become unselected, unedited
		etc

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
	srs	8/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjReleaseExcls	method dynamic GrObjClass, 
						MSG_GO_RELEASE_EXCLS
	uses	cx
	.enter

	mov	ax,MSG_GO_RELEASE_MOUSE
	call	ObjCallInstanceNoLock

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jnz	done

	mov	cl, DONT_SELECT_AFTER_EDIT
	mov	ax,MSG_GO_BECOME_UNEDITABLE
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GrObjReleaseExcls		endm

GrObjExtNonInteractiveCode	ends


GrObjGroupCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDeselectIfGroupLockSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deselect the object if its group lock is set.

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
			group lock not set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDeselectIfGroupLockSet	method dynamic GrObjClass, 
					MSG_GO_DESELECT_IF_GROUP_LOCK_SET
	.enter

	test	ds:[di].GOI_locks,mask GOL_GROUP
	jnz	deselect
done:
	.leave
	ret

deselect:
	mov	ax,MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock
	jmp	done

GrObjDeselectIfGroupLockSet		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAfterAddedToGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to object after it has been added to a group

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - AfterAddedToGroupData

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAfterAddedToGroup	method dynamic GrObjClass, MSG_GO_AFTER_ADDED_TO_GROUP
	uses	ax,bp
	.enter

	;    Store OD of group in reverse link field
	;    and set IN_GROUP attribute
	;	

	mov	bx,ss:[bp].AATGD_group.handle
	mov	ds:[di].GOI_reverseLink.LP_next.handle,bx
	mov	bx,ss:[bp].AATGD_group.chunk
	mov	ds:[di].GOI_reverseLink.LP_next.chunk,bx
	ornf	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP

	;    Subtract center adjust from center of child
	;

	add	bp,offset AATGD_centerAdjust
	CallMod	GrObjMoveNormalRelative

	call	ObjMarkDirty

	.leave
	ret

GrObjAfterAddedToGroup		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBeforeRemovedFromGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to object after it has been removed from group.


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

RETURN:		
		nothing

	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBeforeRemovedFromGroup	method dynamic GrObjClass, 
					MSG_GO_BEFORE_REMOVED_FROM_GROUP
	uses	ax
	.enter

	call	ObjMarkDirty

	;    Clear in group bit and od of group in 
	;    reverse link
	;

	BitClr	ds:[di].GOI_optFlags,GOOF_IN_GROUP
	clr	ax
	mov	ds:[di].GOI_reverseLink.LP_next.handle,ax
	mov	ds:[di].GOI_reverseLink.LP_next.chunk,ax

	.leave
	ret

GrObjBeforeRemovedFromGroup		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjRemoveFromGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the object from the group
		and generate an undo chain to undo this.

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
	srs	8/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRemoveFromGroup	method dynamic GrObjClass, 
						MSG_GO_REMOVE_FROM_GROUP
	uses	cx,dx,bp
	.enter

	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP
	jz	done

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GROUP_REMOVE_GROBJ
	mov	bp,mask GAGOF_RELATIVE
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToGroup

done:
	.leave
	ret
GrObjRemoveFromGroup		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInvertGrObjNormalSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert sprite of object using normal transform data.
		Used by objects in group when group is being 
		interactively resized, rotated,etc

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		dx - gstate or 0

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInvertGrObjNormalSprite	method dynamic GrObjClass,
					MSG_GO_INVERT_GROBJ_NORMAL_SPRITE
	uses	cx,dx
	class	GrObjClass
	.enter

	mov	di,dx					;gstate
	call	GrObjGetParentGStateStart
	mov	dx, di
EC <	call	ECCheckGStateHandle			>
	GrObjApplySpriteAttrs
	CallMod	GrObjApplyNormalTransform	

	mov	ax,MSG_GO_DRAW_NORMAL_SPRITE_LINE
	call	ObjCallInstanceNoLock

	call	GrObjGetGStateEnd

	.leave
	ret

	
GrObjInvertGrObjNormalSprite endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawNormalSpriteLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide rectangular outline as default handler so
		that sprites of objects in groups will work.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		dx - gstate to draw through

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawNormalSpriteLine	method dynamic GrObjClass,
						MSG_GO_DRAW_NORMAL_SPRITE_LINE
	class	GrObjClass
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawRect

	.leave
	ret
GrObjDrawNormalSpriteLine		endp

GrObjGroupCode	ends





GrObjTransferCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAfterQuickPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler

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
	srs	3/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAfterQuickPaste	method dynamic GrObjClass, 
						MSG_GO_AFTER_QUICK_PASTE
	.enter

	mov	dl, HUM_NOW
	mov	ax,MSG_GO_BECOME_SELECTED
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjAfterQuickPaste		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGrObjClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_GET_GROBJ_CLASS

Called by:	MSG_GO_GET_GROBJ_CLASS

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

Return:		cx:dx - pointer to GrObjClass

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetGrObjClass	method dynamic	GrObjClass, MSG_GO_GET_GROBJ_CLASS
	.enter

	mov	cx, segment GrObjClass
	mov	dx, offset GrObjClass

	.leave
	ret
GrObjGetGrObjClass	endm

GrObjTransferCode	ends
