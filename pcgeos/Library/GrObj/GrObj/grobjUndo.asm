COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		grobjUndo.asm

AUTHOR:		Steve Scholl, Jul 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	7/30/92		Initial revision


DESCRIPTION:
	
		

	$Id: grobjUndo.asm,v 1.1 97/04/04 18:07:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



GrObjRequiredCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform undo

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - UndoActionStruc
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
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUndo	method dynamic GrObjClass, MSG_META_UNDO
	.enter

	mov	ax,({GrObjUndoAppType}ss:[bp].UAS_appType).GOUAT_undoMessage

	;    All grobj undo messages take their parameters from the
	;    UndoActionDataUnion in the same order regardless of
	;    the UndoActionDataType.
	;

CheckHack <(offset UADF_flags.low) eq 0>
CheckHack <(offset UADF_flags.high) eq 2>
CheckHack <(offset UADF_extraFlags) eq 4>
CheckHack <(offset UADVMC_vmChain.low) eq 0>
CheckHack <(offset UADVMC_vmChain.high) eq 2>
CheckHack <(offset UADVMC_file) eq 4>

	mov	cx,{word}ss:[bp].UAS_data
	mov	dx,{word}ss:[bp].UAS_data+2
	mov	bp,{word}ss:[bp].UAS_data+4
	
	call	ObjCallInstanceNoLock

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjUndo		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUndoFreeingAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform undo freeing action

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - AddUndoActionStruc
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
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUndoFreeingAction	method dynamic GrObjClass, MSG_META_UNDO_FREEING_ACTION
	.enter

	mov	ax,({GrObjUndoAppType}ss:[bp].AUAS_data.\
					UAS_appType).GOUAT_freeMessage

	;    All grobj undo messages take their parameters from the
	;    UndoActionDataUnion in the same order regardless of
	;    the UndoActionDataType.
	;

CheckHack <(offset UADF_flags.low) eq 0>
CheckHack <(offset UADF_flags.high) eq 2>
CheckHack <(offset UADF_extraFlags) eq 4>
CheckHack <(offset UADVMC_vmChain.low) eq 0>
CheckHack <(offset UADVMC_vmChain.high) eq 2>
CheckHack <(offset UADVMC_file) eq 4>

	mov	cx,{word}ss:[bp].AUAS_data.UAS_data
	mov	dx,{word}ss:[bp].AUAS_data.UAS_data+2
	mov	bp,{word}ss:[bp].AUAS_data.UAS_data+4
	

	call	ObjCallInstanceNoLock

	.leave

	Destroy	ax,cx,dx,bp

	ret

GrObjUndoFreeingAction		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUndoReplaceGeometryInstanceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an undo action so that we can undo undo to the current
		state and the set our instance data from the passed
		undo info.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		dx - DB group
		cx - DB item
		bp - VM File handle

		The referenced DBitem must contain a BasicInit structure

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
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUndoReplaceGeometryInstanceData	method dynamic GrObjClass, 
				MSG_GO_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA
	uses	cx,bp
	.enter

	call	GrObjBeginGeometryCommon

	;    Make the undo, undoable
	;    Don't pass a string so that it will use the previous string
	;

	pushdw	cxdx
	clrdw	cxdx
	mov	ax,MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	call	ObjCallInstanceNoLock
	popdw	cxdx

	;    Lock the db item with instance data copy in it
	;

	mov	bx,bp					;VM file
	mov	ax,dx					;group
	mov	di,cx					;item
	call	DBLock
	mov	di,es:[di]				;deref db

	;    Copy BasicInit struc to stack frame
	;

	sub	sp,size BasicInit
	mov	bp,sp
	push	ds,si					;object 
	segmov	ds,es					;db item is source
	segmov	es,ss					;stack is dest
	mov	si,di					;source offset
	mov	di,bp					;dest offset
	MoveConstantNumBytes	<size BasicInit>,cx

	;    Unlock the db item
	;

	segmov	es,ds					;db block
	call	DBUnlock
	pop	ds,si					;object

	;    Set the object instance data from the undo info
	;    and clear stack frame
	;

	mov	ax,MSG_GO_REPLACE_GEOMETRY_INSTANCE_DATA
	call	ObjCallInstanceNoLock
	add	sp,size BasicInit

	call	GrObjEndGeometryCommon

	mov	bp,GOANT_UNDO_GEOMETRY
	call	GrObjOptNotifyAction

	.leave
	ret
GrObjUndoReplaceGeometryInstanceData		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoReplaceGeometryInstanceDataAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo action for the objects current geometry
		instance data

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
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoReplaceGeometryInstanceDataAction method dynamic GrObjClass,
		MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_ACTION
	uses	cx,dx,bp
	.enter

	;    Alloc db item for storing undo item in undo file
	;

	mov	cx,size	BasicInit
	call	GrObjGlobalAllocUndoDBItem

	;    Copy instance data to  to db item
	;

	push	ax,di,si			;group, item, object chunk
	call	DBLock
	mov	di,es:[di]			;deref db item
	AccessNormalTransformChunk	si,ds,si
	mov	dx,di				;db item offset
	mov	bp,si				;instance data offset

	addnf	di, <offset BI_center>
	addnf	si, <offset OT_center>
	MoveConstantNumBytes <size PointDWFixed> ,cx

	mov	si,bp				;instance data offset
	mov	di,dx				;db item offset
	addnf	di, <offset BI_width>
	addnf	si, <offset OT_width>
	MoveConstantNumBytes <size WWFixed> ,cx

	mov	si,bp				;instance data offset
	mov	di,dx				;db item offset
	addnf	di, <offset BI_height>
	addnf	si, <offset OT_height>
	MoveConstantNumBytes <size WWFixed> ,cx

	mov	si,bp				;instance data offset
	mov	di,dx				;db item offset
	addnf	di, <offset BI_transform>
	addnf	si, <offset OT_transform>
	MoveConstantNumBytes <size GrObjTransMatrix> ,cx

	pop	dx,cx,si			;group, item, object chunk
	call	DBUnlock

	mov	bp,bx				;vm file handle
	clr	bx				;AddUndoActionFlags
	mov	di,MSG_META_DUMMY
	mov	ax,MSG_GO_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA
	call	GrObjGlobalAddVMChainUndoAction

	.leave
	ret
GrObjGenerateUndoReplaceGeometryInstanceDataAction		endm









COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoReplaceGeometryInstanceDataChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for the objects current geometry
		instance data

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx:dx - od of undo text 

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
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoReplaceGeometryInstanceDataChain method dynamic GrObjClass,
		MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	.enter

	call	GrObjGlobalStartUndoChain
	jc	endChain

	mov	ax,MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_ACTION
	call	ObjCallInstanceNoLock

endChain:
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjGenerateUndoReplaceGeometryInstanceDataChain		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoClearChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain, that when processed will
		generate an undo chain that when processed will
		send us this message. There is a strange symbiotic
		relationship between clearing and undo a clear.
		After a clear, we need an undo action that if
		freed will complete the freeing of the object and if
		undone will create an undo action that if undone
		will create the original action. Think about it.

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
GrObjGenerateUndoClearChain	method dynamic GrObjClass, 
						MSG_GO_GENERATE_UNDO_CLEAR_CHAIN
	.enter

	call	GrObjGlobalStartUndoChainNoText
	jc	endChain

	mov	ax,\
	MSG_GO_GENERATE_UNDO_UNDO_CLEAR_CHAIN_WITH_ACTION_NOTIFICATION	
							;undo message
	mov	di,MSG_GO_OBJ_FREE_GUARANTEED_NO_QUEUED_MESSAGES
							;freeing undo message
	mov	bx,mask AUAF_NOTIFY_IF_FREED_WITHOUT_BEING_PLAYED_BACK
	call	GrObjGlobalAddFlagsUndoAction

endChain:
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjGenerateUndoClearChain		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoClearChainWithActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain, that when processed will
		generate an undo chain that when processed will
		send us this message. There is a strange symbiotic
		relationship between clearing and undo a clear.
		After a clear, we need an undo action that if
		freed will complete the freeing of the object and if
		undone will create an undo action that if undone
		will create the original action. Think about it.

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
GrObjGenerateUndoClearChainWithActionNotification method dynamic GrObjClass, 
		MSG_GO_GENERATE_UNDO_CLEAR_CHAIN_WITH_ACTION_NOTIFICATION
	uses	bp
	.enter

	mov	ax,MSG_GO_GENERATE_UNDO_CLEAR_CHAIN
	call	ObjCallInstanceNoLock

	mov	bp,GOANT_REDO_DELETE
	call	GrObjOptNotifyAction

	.leave
	ret
GrObjGenerateUndoClearChainWithActionNotification		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoUndoClearChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain, that when processed will
		generate an undo chain that when processed will
		send us this message. There is a strange symbiotic
		relationship between clearing and undo a clear.
		After a clear, we need an undo action that if
		freed will complete the freeing of the object and if
		undone will create an undo action that if undone
		will create the original action. Think about it.

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
GrObjGenerateUndoUndoClearChain	method dynamic GrObjClass, 
					MSG_GO_GENERATE_UNDO_UNDO_CLEAR_CHAIN
	.enter

	call	GrObjGlobalStartUndoChainNoText
	jc	endChain

	mov	ax,MSG_GO_GENERATE_UNDO_CLEAR_CHAIN_WITH_ACTION_NOTIFICATION
							;undo message
	clr	bx					;AddUndoActionStruct
	call	GrObjGlobalAddFlagsUndoAction

endChain:
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjGenerateUndoUndoClearChain		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoUndoClearChainWithoutActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs functionality of MSG_GO_GENERATE_UNDO_UNDO_CLEAR_CHAIN
		as well as sending out a GOANT_REDO_DELETE action
		notification.

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
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoUndoClearChainWithActionNotification	method dynamic \
GrObjClass, MSG_GO_GENERATE_UNDO_UNDO_CLEAR_CHAIN_WITH_ACTION_NOTIFICATION
	uses	bp
	.enter

	call	GenProcessUndoCheckIfIgnoring
	tst	ax
	jnz	done

	mov	ax,MSG_GO_GENERATE_UNDO_UNDO_CLEAR_CHAIN
	call	ObjCallInstanceNoLock

	mov	bp,GOANT_UNDO_DELETE
	call	GrObjOptNotifyAction

done:
	.leave
	ret
GrObjGenerateUndoUndoClearChainWithActionNotification		endm

GrObjRequiredCode	ends
