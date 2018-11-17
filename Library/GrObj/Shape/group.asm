COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		group.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
GroupSetNewChildCenter
GroupSendToChildren
GroupProcessAllChildrenInDrawOrderCommon
GroupProcessAllChildrenSendCallBackMessageCB
GroupCalcBoundsOfChildren
GroupCalcBoundsOfChildrenCB
GroupReCenterGroup
GroupMoveGroupNowhere
GroupMoveGroupNowhereCB
GroupCalcCenterShift
GroupEvaluateParentPointCB
GroupTransformChildren
GroupGetNumChildren
GroupSendClassedEvent
GroupSendClassedEventToChildren
GroupSendClassedEventToChildrenCB
	
METHOD HANDLERS
	Name		
	----		
GroupMetaIntialize
GroupInitialize
GroupInstantiateGrObj
GroupExpand
GroupUnGroupable?
GroupAddGrObj
GroupRemoveGrObj
GroupClear
GroupDraw
GroupInvertGrObjSprite
GroupInvertGrObjNormalSprite
GroupProcessAllChildrenSendCallBackMessage
GroupCreateGState
GroupEvaluateParentPoint
GroupPassMessageOntoChildren
GroupHandleMessageAndPassToChildren
GroupConvertScaleToData

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
	This file contains routines to implement the GraphicGroup Class
		

	$Id: group.asm,v 1.1 97/04/04 18:08:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

GroupClass		;Define the class record

GrObjClassStructures	ends



GrObjGroupCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Group does a multiplicative resize

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

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
	srs	7/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupMetaInitialize	method dynamic GroupClass, 
						MSG_META_INITIALIZE
	.enter

	mov	di, offset GroupClass
	call	ObjCallSuperNoLock

	GrObjDeref	di,ds,si
	BitSet	ds:[di].GOI_attrFlags, GOAF_MULTIPLICATIVE_RESIZE
	ornf	ds:[di].GOI_msgOptFlags, \
		mask GOMOF_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT \
		or mask GOMOF_INVALIDATE

	.leave
	ret
GroupMetaInitialize		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we have no children then don't invalidate. This prevents
		the group from invalidating after an ungroup which is
		the nice thing.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

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
	srs	12/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupInvalidate	method dynamic GroupClass, 
						MSG_GO_INVALIDATE
	.enter

	tst	ds:[di].GI_drawHead.CP_firstChild.handle
	jz	done

	mov	di,offset GroupClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret
GroupInvalidate		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the ObjectTransform of a group for expansion
		The group is initialized with no width and height because these
		will be calculated later based on the objects added
		to it. The group's center is initialized a 0,0 
		because this makes each object's center relative to
		the group's center without doing any math. When
		the group's size is expanded to encompass the objects
		the group's center will be position correctly in the
		middle of all the objects.

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
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupInitialize	method dynamic GroupClass, MSG_GROUP_INITIALIZE
	uses	ax,cx,dx
	.enter

	push	si					;group chunk

	call	GrObjCreateNormalTransform

	segmov	es,ds,di
	AccessNormalTransformChunk	di,ds,si
	mov	dx,di

	add	di, offset OT_center
	clr	ax
	StoreConstantNumBytes < size PointDWFixed >, cx

	mov	di,dx
	add	di,offset OT_width
	StoreConstantNumBytes < size WWFixed >, cx

	mov	di,dx
	add	di,offset OT_height
	StoreConstantNumBytes < size WWFixed >, cx

	mov	si,dx
	add	si,offset OT_transform
	call	GrObjGlobalInitGrObjTransMatrix

	pop	si					;group chukn

	mov	ax,MSG_GO_GET_GROBJ_ATTR_FLAGS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	
	;    Reset all but the no default bits and don't set any of
	;    the no default bits
	;

	mov	dx,not NO_DEFAULT_GROBJ_ATTR_FLAGS
	andnf	cx,dx		
	mov	ax,MSG_GO_SET_GROBJ_ATTR_FLAGS
	call	ObjCallInstanceNoLock

	.leave
	ret
GroupInitialize		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupInstantiateGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Instantiate a grobject of the passed class in a block managed
	by the body that the group is associated with. This message
	is functionally equivalent to MSG_GB_INSTANTIATE_GROBJ, it merely
	simplies the creation of groups.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		cx:dx - class

RETURN:		
		cx:dx - OD of new object
	
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
	srs	4/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupInstantiateGrObj	method dynamic GroupClass, 
						MSG_GROUP_INSTANTIATE_GROBJ
	.enter

	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	.leave
	ret
GroupInstantiateGrObj		endm








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupUnGroupable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object consists of collection of objects in a
		group that can be broken up into the indivdual objects


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		stc - ungroupable

		
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
GroupUnGroupable method dynamic GroupClass, MSG_GO_UNGROUPABLE
	
	test	ds:[di].GOI_locks,mask GOL_UNGROUP
	jnz	done

	stc
done:
	ret
GroupUnGroupable		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupAddGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Add the passed object as child of group


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		cx:dx - optr of child to add
		bp - GroupAddGrObjFlags

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
GroupAddGrObj	method dynamic GroupClass, MSG_GROUP_ADD_GROBJ
	uses	ax,dx,bp
	.enter

	;    All children of the group must have a suspend count
	;    that matches that of the group. Make it so.
	;

	mov	ax,MSG_META_SUSPEND
	call	GroupMatchSuspend

	call	GroupGenerateUndoAddGrObjChain

	;    Add child to group
	;

	push	bp				;GroupAddGrObjFlags
	ornf	bp, mask CCF_MARK_DIRTY
	mov	ax, offset GOI_drawLink		;link field
	mov	di, offset GI_drawHead		;head of links
	mov	bx, offset GrObj_offset		;grobj is master
	call	ObjCompAddChild
	pop	ax				;GroupAddGrObjFlags

	;    Build out AfterAddedToGroupData and send to child
	;

	sub	sp, size AfterAddedToGroupData
	mov	bp,sp
	mov	bx,ds:[LMBH_handle]
	mov	ss:[bp].AATGD_group.handle,bx
	mov	ss:[bp].AATGD_group.chunk,si
	call	GroupSetNewChildCenter

	mov	bx,cx				;child handle
	mov	si,dx				;child chunk
	mov	dx,size AfterAddedToGroupData
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_AFTER_ADDED_TO_GROUP
	call	ObjMessage
	mov	di,ss:[bp].AATGD_group.chunk
	add	sp, size AfterAddedToGroupData

	;    If the group has already been added to the body
	;    then notify child of this.
	;

	GrObjDeref	di,ds,di			;group chunk
	mov	dl,ds:[di].GOI_tempState
	test	ds:[di].GOI_optFlags, mask GOOF_ADDED_TO_BODY
	jz	checkSelect
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_AFTER_ADDED_TO_BODY
	call	ObjMessage

checkSelect:
	;    If the group has already been selected
	;    then notify child of this.
	;

	test	dl, mask GOTM_SELECTED			;group's GOI_tempState
	jz	done
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_GROUP_GAINED_SELECTION_LIST
	call	ObjMessage

done:

	.leave
	ret
GroupAddGrObj		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupMatchSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the passed suspend/unsuspend message to the 
		object the number of times the group is suspended

CALLED BY:	INTERNAL
		GroupAddGrObj
		GroupRemoveGrObj

PASS:		*ds:si - group
		^lcx:dx - od of child
		ax - MSG_META_SUSPEND or MSG_META_UNSUSPEND

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
	srs	3/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupMatchSuspend		proc	near
	class	GroupClass
	uses	si,bx,cx,dx,bp,di
	.enter

EC <	call	ECGroupCheckLMemObject		

	GrObjDeref	di,ds,si
	movdw	bxsi,cxdx				;child od
	mov	cx,ds:[di].GI_suspendCount
	jcxz	done

loopSend:
	push	ax,cx					;message, count
	mov	di,mask MF_FIXUP_DS			;MessageFlags
	call	ObjMessage
	pop	ax,cx					;message, count
	loop	loopSend

done:
	.leave
	ret

GroupMatchSuspend		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupGenerateUndoAddGrObjChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for adding object to group

CALLED BY:	INTERNAL
		GroupAddGrObj

PASS:		*ds:si - group
		cx:dx - od of child

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
GroupGenerateUndoAddGrObjChain		proc	near
	uses	ax,bx
	.enter

EC <	call	ECGrObjCheckLMemObject				>
	
	call	GrObjGlobalStartUndoChainNoText
	jc	endChain

	;    Make that undo chain
	;

	mov	ax,MSG_GROUP_REMOVE_GROBJ		;undo message
	clr	bx					;AddUndoActionFlags
	call	GrObjGlobalAddFlagsUndoAction

endChain:
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GroupGenerateUndoAddGrObjChain		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupRemoveGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Remove the passed object as child of group


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass
		cx:dx - optr of child to remove

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
GroupRemoveGrObj	method dynamic GroupClass, 
						MSG_GROUP_REMOVE_GROBJ
transform	local	TransMatrix

	uses	cx,dx
	.enter

	;    Do this before the transform so that when the object
	;    is added back to the group during an undo, the objects
	;    transform will be relative to the groups center
	;

	call	GroupGenerateUndoRemoveGrObjChain

	push	si					;group chunk

	;    Copy groups transform to upper 2x2 of TransMatrix on stack
	;

	segmov	es,ss
	AccessNormalTransformChunk	si,ds,si
	add	si,offset OT_transform
	lea	di,transform
	MoveConstantNumBytes	<size GrObjTransMatrix >,ax

	;    Copy center to translation of TransMatrix
	;
	
	sub	si,( offset OT_transform + size GrObjTransMatrix -\
		    offset OT_center )			;

	MoveConstantNumBytes <size PointDWFixed >, ax

	;    After the child has been removed from the group, but
	;    before it has been transformed it is basically dorked,
	;    so mark it invalid. In particular this prevents it
	;    from invalidating incorrectly as part of the transform.
	;

	movdw	bxsi,cxdx			;child od
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_NOTIFY_GROBJ_INVALID
	call	ObjMessage

	;    If the group has already been selected then notify
	;    child of the loss of selection
	;

	pop	di					;group chunk
	push	di					;group chunk
	GrObjDeref	di,ds,di			;group chunk
	mov	dl,ds:[di].GOI_optFlags
	test	ds:[di].GOI_tempState, mask GOTM_SELECTED
	jz	checkBody
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_GROUP_LOST_SELECTION_LIST
	call	ObjMessage

checkBody:
	;    If the group has already been added to the body
	;    then notify child that it is being removed from the body
	;

	test	dl, mask GOOF_ADDED_TO_BODY		;group's optFlags
	jz	removeFromGroup
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_BEFORE_REMOVED_FROM_BODY
	call	ObjMessage

removeFromGroup:
	;    Notify child that it is being removed from group
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_BEFORE_REMOVED_FROM_GROUP
	call	ObjMessage
	movdw	cxdx,bxsi			;child od


	;    Remove child from group
	;

	pop	si				;group chunk
	push	bp				;stack frame
	mov	bp, mask CCF_MARK_DIRTY
	mov	ax, offset GOI_drawLink		;link field
	mov	di, offset GI_drawHead		;head of links
	mov	bx, offset GrObj_offset		;grobj is master
	call	ObjCompRemoveChild
	pop	bp				;stack frame

	;    Balance suspends that were received while a child of the
	;    group
	;

	mov	ax,MSG_META_UNSUSPEND
	call	GroupMatchSuspend

	;    Apply the groups transform to the child. This must
	;    be done after the child has been removed from the group
	;    so that the child can calculate its PARENT dimension
	;    correctly
	;

	push	bp				;stack frame
	lea	bp,transform
	movdw	bxsi,cxdx			;child od
	mov	di,mask MF_STACK or mask MF_FIXUP_DS
	mov	ax,MSG_GO_TRANSFORM
	call	ObjMessage
	pop	bp				;stack frame

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	call	ObjMessage


	.leave
	ret
GroupRemoveGrObj		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupGenerateUndoRemoveGrObjChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for removing object from group

CALLED BY:	INTERNAL
		GroupRemoveGrObj

PASS:		*ds:si - group
		cx:dx - od of child

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
GroupGenerateUndoRemoveGrObjChain		proc	near
	uses	ax,bx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>
	
	call	GrObjGlobalStartUndoChainNoText
	jc	endChain

	;    Add each child as first since the undo will be adding
	;    them in reverse order. Also, this undo chain should
	;    be generated before the groups transform is applied
	;    to the objects so that if the action is undone the
	;    object's ObjectTransform will be made relative to the
	;    groups center before the object is added back to the group.
	;

	mov	bp,GAGOF_FIRST or mask GAGOF_RELATIVE
	mov	ax,MSG_GROUP_ADD_GROBJ		;undo message
	clr	bx				;AddUndoActionFlags
	call	GrObjGlobalAddFlagsUndoAction

endChain:
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GroupGenerateUndoRemoveGrObjChain		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupSetNewChildCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the center adjust for the child in the passed stack
		frame

CALLED BY:	INTERNAL
		GroupAddGrObj

PASS:		
		*ds:si - group
		ss:bp - AfterAddedToGroupData
		cx:dx - child
		ax - GroupAddGrObjFlags
			only GAGOF_RELATIVE matters

RETURN:		
		ss:bp ATGD_newCenter

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
GroupSetNewChildCenter		proc	near
	class	GroupClass
	uses	ax,cx,di,si,es
	.enter

EC <	call	ECGroupCheckLMemObject				>

	mov	cx,size PointDWFixed/2		;num words to store/copy
	segmov	es,ss				;dest for store/copy
	lea	di,ss:[bp + offset AATGD_centerAdjust];dest offset

	test	ax, mask GAGOF_RELATIVE
	jnz	initToZero

	;    The center of the child is an absolute position, so set
	;    the centerAdjust to the negative of the center of the
	;    group
	;

	AccessNormalTransformChunk	si,ds,si
	add	si, offset OT_center		;source offset	
	rep	movsw
	sub	di,size PointDWFixed
	NegDWFixedPtr 	es:[di].PDF_x
	NegDWFixedPtr	es:[di].PDF_y

done:
	.leave
	ret

initToZero:
	;    The position in the child is already relative to the center
	;    of the group so just pass zero as the center adjust
	;
	clr	ax
	rep	stosw
	jmp	done

GroupSetNewChildCenter		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupInvertGrObjNormalSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass
		
		dx - gstate or 0

RETURN:		

	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupInvertGrObjNormalSprite	method dynamic GroupClass,
					MSG_GO_INVERT_GROBJ_NORMAL_SPRITE
	uses	ax
	.enter

	mov	di,dx
	call	GrObjGetParentGStateStart
	call	GrObjApplyNormalTransform

	call	GroupSendToNormalChildren

	call	GrObjGetGStateEnd

	.leave
	ret
GroupInvertGrObjNormalSprite		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupProcessAllChildrenSendCallBackMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For each child in group send call back message to 
		call back object with child's and groups OD 
		in stack frame

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		ss:bp - stack frame that starts with a 
		 	CallBackMessageData structure
			CBMD_callBackOD
			CBMD_callBackMessage
			CBMD_extraData1
			CBMD_extraData2
		dx - size of structure on stack


RETURN:		
		clc - all children processed
			ax,cx,dx,bp - same as passed
		stc - not all children processed
			ax,cx,dx,bp - returned from call back object		
	

CALL BACK MESSAGE:

	PASS:
		ss:bp - stack frame that starts with a 
		 	CallBackMessageData structure
			CBMD_callBackOD
			CBMD_callBackMessage
			CBMD_groupOD
			CBMD_childOD
			CBMD_extraData1
			CBMD_extraData2
		dx - size of structure on stack

	RETURNS:
		clc - keep processing children
			registers and stack frame unchanged
		stc - stop processing children
			ax,cx,dx,bp - set by call back object
			Call back object may not return data in
			the stack frame
			
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupProcessAllChildrenSendCallBackMessage	method dynamic GroupClass, \
			MSG_GROUP_PROCESS_ALL_GROBJS_SEND_CALL_BACK_MESSAGE
	.enter

EC <	push	bx,si						>
EC <	mov	bx,ss:[bp].CBMD_callBackOD.handle		>
EC <	mov	si,ss:[bp].CBMD_callBackOD.chunk		>
EC <	call	ECCheckLMemOD					>
EC <	pop	bx,si						>
EC <	cmp	dx, size CallBackMessageData			>
EC <	ERROR_B STACK_FRAME_NOT_BIG_ENOUGH_TO_BE_CALL_BACK_MESSAGE_DATA >

	mov	bx, SEGMENT_CS
	mov	di, offset GroupProcessAllChildrenSendCallBackMessageCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	.leave
	ret
GroupProcessAllChildrenSendCallBackMessage		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupProcessAllChildrenSendCallBackMessageCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the call back message to the call back object with
		the OD of the child and the group in stack frame  
		Stop processing children if call back object returns carry set.

CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		
		*ds:si - child
		*es:di - group
		ss:bp - stack frame that starts with a 
		 	CallBackMessageData structure
			CBMD_callBackOD
			CBMD_callBackMessage
			CBMD_extraData1
			CBMD_extraData2
		dx - size of structure on stack

RETURN:		
		clc - to keep processing children
			ax,cx,dx,bp - same as passed
		stc - to stop processing children
			ax,cx,dx,bp - from call back object message handler

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupProcessAllChildrenSendCallBackMessageCB		proc	far
	uses	bx,si,di
	.enter

	;    Protect registers from message
	;

	push	ax,cx,dx,bp

	;    Set child and group od's in stack frame
	;

	mov	ax,ds:[LMBH_handle]
	mov	ss:[bp].CBMD_childOD.handle,ax
	mov	ss:[bp].CBMD_childOD.chunk,si
	mov	ax,es:[LMBH_handle]
	mov	ss:[bp].CBMD_groupOD.handle,ax
	mov	ss:[bp].CBMD_groupOD.chunk,di
	
	;    Send call back message to call back object
	;

	mov	bx,ss:[bp].CBMD_callBackOD.handle
	mov	si,ss:[bp].CBMD_callBackOD.chunk
	mov	ax,ss:[bp].CBMD_callBackMessage
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	;    Jump if call back object wants to stop processing children
	;    otherwise recover protected registers
	;

	jc	stop
	pop	ax,cx,dx,bp			

done:
	.leave
	ret

stop:
	;    Leave ax,cx,dx,bp as returned from call back object
	;

	add	sp,8
	jmp	done

GroupProcessAllChildrenSendCallBackMessageCB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupPassMessageOntoNormalChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Catch all message handler to pass messages onto children

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		Depends on message being handled

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
	srs	12/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupPassMessageOntoNormalChildren	method dynamic GroupClass, 
						MSG_GO_SET_AREA_ATTR,
						MSG_GO_SET_LINE_ATTR,
				MSG_META_STYLED_OBJECT_SAVE_STYLE,
				MSG_META_STYLED_OBJECT_APPLY_STYLE,
				MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE
	.enter


	call	GroupSendToNormalChildren

	.leave
	ret
GroupPassMessageOntoNormalChildren		endm

;---

GroupPassMessageOntoNormalChildrenBorrowStack	method dynamic GroupClass, 
						MSG_GO_SET_AREA_COLOR,
						MSG_GO_SET_AREA_MASK,
						MSG_GO_SET_AREA_DRAW_MODE,
						MSG_GO_SET_TRANSPARENCY,
						MSG_GO_SET_LINE_COLOR,
						MSG_GO_SET_LINE_MASK,
						MSG_GO_SET_LINE_END,
						MSG_GO_SET_LINE_JOIN,
						MSG_GO_SET_LINE_STYLE,
						MSG_GO_SET_LINE_WIDTH,
						MSG_GO_SET_LINE_MITER_LIMIT,
						MSG_GO_SET_AREA_PATTERN,
						MSG_GO_SET_BG_COLOR,
					MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE,
					MSG_GO_SET_LINE_ATTR_ELEMENT_TYPE,
					MSG_GO_SET_STARTING_GRADIENT_COLOR,
					MSG_GO_SET_ENDING_GRADIENT_COLOR,
					MSG_GO_SET_NUMBER_OF_GRADIENT_INTERVALS,
					MSG_GO_SET_GRADIENT_TYPE,
			MSG_GO_COMBINE_AREA_NOTIFICATION_DATA,
			MSG_GO_COMBINE_GRADIENT_NOTIFICATION_DATA,
			MSG_GO_COMBINE_LINE_NOTIFICATION_DATA,
			MSG_GO_COMBINE_STYLE_NOTIFICATION_DATA,
			MSG_GO_COMBINE_STYLE_SHEET_NOTIFICATION_DATA,
					MSG_GO_GROUP_GAINED_SELECTION_LIST,
					MSG_GO_GROUP_LOST_SELECTION_LIST
	.enter

	mov	di, 800
	call	ThreadBorrowStackSpace

	call	GroupSendToNormalChildren

	call	ThreadReturnStackSpace

	.leave
	ret
GroupPassMessageOntoNormalChildrenBorrowStack		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupHandleMessageAndPassToChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle message here and pass onto all children
	
		Messages handled this way cannot have return values.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		Depends on message being handled

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
GroupHandleMessageAndPassToChildren	method dynamic GroupClass, 
					MSG_GO_AFTER_ADDED_TO_BODY, 
					MSG_GO_NUDGE_INSIDE,
					MSG_GO_MOVE_INSIDE

	.enter					

	mov	di, 700
	call	ThreadBorrowStackSpace
	push	di

	push	ax
	mov	di, offset GroupClass
	call	ObjCallSuperNoLock
	pop	ax

	clr	bx
	mov	di,OCCT_SAVE_PARAMS_DONT_TEST_ABORT	
	call	GroupProcessAllChildrenInDrawOrderCommon

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
GroupHandleMessageAndPassToChildren		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupPassToChildrenThenHandleMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass message to children then handle it for the gropu.
		
		MSG_GO_CHANGE_LOCKS is handled by children first
		so that group can provide return values.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		Depends on message being handled

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
GroupPassToChildrenThenHandleMessage	method dynamic GroupClass, 
					MSG_GO_BEFORE_REMOVED_FROM_BODY,
					MSG_GO_NUKE_DATA_IN_OTHER_BLOCKS,
					MSG_GO_CLEAR_SANS_UNDO,
					MSG_GO_CHANGE_LOCKS

	.enter					

	mov	di, 700
	call	ThreadBorrowStackSpace
	push	di

	push	ax
	clr	bx
	mov	di,OCCT_SAVE_PARAMS_DONT_TEST_ABORT	
	call	GroupProcessAllChildrenInDrawOrderCommon
	pop	ax

	mov	di, offset GroupClass
	call	ObjCallSuperNoLock


	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
GroupPassToChildrenThenHandleMessage		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to make one big undo chain for deleting the group
		and all its children. Also need to remove the group
		from its parent before nuking the children (see comment
		in code), but we can't complete the deletion of the
		group until after all the children are dead (they
		would try to send messages to the dead group)


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass


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
GroupClear	method dynamic GroupClass, MSG_GO_CLEAR
	uses	bp

	.enter					

	call	GrObjCanClear?
	jnc	done

	;    Merge undo chains of the children and group
	;    into a meta undo chain
	;

	mov	cx,handle deleteString
	mov	dx,offset deleteString
	call	GrObjGlobalStartUndoChain

	;    We must remove the group from it's parent before
	;    clearing the children so that if the delete is undone
	;    the children will have been added back to the group
	;    before the group is added back to it's parent. The
	;    group redraws when it is added back to the parent,
	;    and it won't redraw much without any children.
	;

	push	ax					;message	
	mov	ax,MSG_GO_REMOVE_FROM_GROUP
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GO_REMOVE_FROM_BODY
	call	ObjCallInstanceNoLock
	pop	ax					;message

	;    Send the MSG_GO_CLEAR to all the children
	;

	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di
	clr	bx
	mov	di,OCCT_SAVE_PARAMS_DONT_TEST_ABORT	
	call	GroupProcessAllChildrenInDrawOrderCommon
	pop	di
	call	ThreadReturnStackSpace

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

GroupClear		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupHandleMessageAndPassOntoNormalChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle message here and pass onto children without
		the paste inside bit set

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		Depends on message being handled

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
GroupHandleMessageAndPassOntoNormalChildren	method dynamic GroupClass, 
					MSG_GO_MAKE_INSTRUCTION,
					MSG_GO_MAKE_NOT_INSTRUCTION,
					MSG_GO_SET_INSERT_DELETE_MOVE_ALLOWED,
					MSG_GO_SET_INSERT_DELETE_RESIZE_ALLOWED,
					MSG_GO_SET_INSERT_DELETE_DELETE_ALLOWED,
					MSG_GO_SET_WRAP_TEXT_TYPE

	.enter					

	mov	di, 700
	call	ThreadBorrowStackSpace
	push	di

	push	ax
	mov	di, offset GroupClass
	call	ObjCallSuperNoLock
	pop	ax

	call	GroupSendToNormalChildren

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
GroupHandleMessageAndPassOntoNormalChildren		endm











COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupExpand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand and position group to contain all its children.
		Setting both the OBJECT dimensions and the PARENT
		dimensions.

		The children's positions must be relative to the
		center of the group for this routine to work.

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
		nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupExpand	method dynamic GroupClass, MSG_GROUP_EXPAND
	uses	dx
	.enter
	;    If we don't have any children then bail
	;    

	tst	ds:[di].GI_drawHead.CP_firstChild.handle
	jz	done

	tst	ds:[di].GI_suspendCount
	jnz	suspended

	clr	dx
	mov	ax,MSG_GO_UNDRAW_HANDLES
	call	ObjCallInstanceNoLock

	call	GroupReCalcOBJECTDimensionsAndCenter

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	clr	dx
	mov	ax,MSG_GO_DRAW_HANDLES
	call	ObjCallInstanceNoLock
 
done:
	.leave
	ret

suspended:
	BitSet	ds:[di].GI_unsuspendOps,GUO_EXPAND
	call	ObjMarkDirty
	jmp	done

GroupExpand		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupReCalcOBJECTDimensionsAndCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the OBJECT dimensions of the group,
		adjust the group's center to be in the middle of
		all the children and compensate the children's
		centers so that nothing actually moves

CALLED BY:	INTERNAL
		GroupExpand

PASS:		
		*ds:si - group

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
	srs	11/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupReCalcOBJECTDimensionsAndCenter		proc	near
	uses	ax,bx,di
	.enter

	;    To calculate the OBJECT bounds of the group we need 
	;    the group's children to calculate their bounds in
	;    the group's PARENT coordinate system as if the
	;    group had no transformation in it.
	;

	sub	sp,size BoundingRectData
	mov	bp,sp

	mov	di,PARENT_GSTATE
	call	GrObjCreateGStateForBoundsCalc
	mov	ss:[bp].BRD_parentGState,di

	mov	di,PARENT_GSTATE
	call	GrObjCreateGStateForBoundsCalc
	mov	ss:[bp].BRD_destGState,di

	;    Mark the BRD_rect as not initalized so the first child of
	;    the group will copy its bounds into BRD_rect instead of
	;    merging.
	;

	clr	ax
	mov	ss:[bp].BRD_initialized,ax
	call	GroupCalcBoundsOfChildren

	;    Adjust the center of the group and move the children
	;    accordingly.
	;

	call	GroupReCenterGroup

	;    Set the OBJECT dimensions
	;

	CallMod GrObjGlobalGetWWFixedDimensionsFromRectDWFixed
EC <	ERROR_NC	BUG_IN_DIMENSIONS_CALC			>
	call	GrObjSetNormalOBJECTDimensions

	;    Destroy temporary gstates
	;

	mov	di,ss:[bp].BRD_parentGState
	call	GrDestroyState
	mov	di,ss:[bp].BRD_destGState
	call	GrDestroyState

	add	sp, size BoundingRectData

	.leave
	ret
GroupReCalcOBJECTDimensionsAndCenter		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupGetBoundingRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the RectDWFixed that bounds all the objects in
		the group in the dest gstate coordinate system

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RectClass

		ss:bp - BoundingRectData
			destGState
			parentGState

RETURN:		
		ss:bp - BoundingRectData
			rect

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupGetBoundingRectDWFixed	method dynamic GroupClass, \
						MSG_GO_GET_BOUNDING_RECTDWFIXED
	.enter

	;    If we don't have any children then jump to call our superclass
	;    

	tst	ds:[di].GI_drawHead.CP_firstChild.handle
	jz	callSuper

	mov	di,ss:[bp].BRD_parentGState
	call	GrSaveTransform
	call	GrObjApplyNormalTransform
	call	GroupCalcBoundsOfChildren
	call	GrRestoreTransform

done:
	.leave
	ret

callSuper:
	;    Superclass will just use object dimensions
	;

	mov	di, offset GroupClass
	call	ObjCallSuperNoLock
	jmp	done

GroupGetBoundingRectDWFixed		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCalcPARENTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the document dimensions and store then in the
		instance data


PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		nothing


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCalcPARENTDimensions method dynamic GroupClass, 
					MSG_GO_CALC_PARENT_DIMENSIONS
	uses	ax,cx,dx,bp
	.enter


	;    If we don't have any children then jump to call our superclass
	;    

	tst	ds:[di].GI_drawHead.CP_firstChild.handle
	jz	callSuper

	sub	sp,size BoundingRectData
	mov	bp,sp

	;    We want objects to produce coordinates in the group's parent's
	;    OBJECT coordinate system
	;

	mov	di,OBJECT_GSTATE
	CallMod	GrObjCreateGStateForBoundsCalc
	mov	ss:[bp].BRD_parentGState,di

	mov	di,PARENT_GSTATE
	CallMod	GrObjCreateGStateForBoundsCalc
	mov	ss:[bp].BRD_destGState,di

	;    Mark the BRD_rect as not initalized so the first child of
	;    the group will copy its bounds into BRD_rect instead of
	;    merging.
	;

	clr	ax
	mov	ss:[bp].BRD_initialized,ax

	;    Calculate the bounds of the children of the group
	;    in the group's PARENT coordinate system.
	;

	call	GroupCalcBoundsOfChildren
	call	GrObjCheckForUnbalancedPARENTDimensions
	CallMod GrObjGlobalGetWWFixedDimensionsFromRectDWFixed
EC <	ERROR_NC	BUG_IN_DIMENSIONS_CALC			>
	call	GrObjSetNormalPARENTDimensions

	;    Destroy temporary gstates
	;

	mov	di,ss:[bp].BRD_parentGState
	call	GrDestroyState
	mov	di,ss:[bp].BRD_destGState
	call	GrDestroyState

	add	sp, size BoundingRectData

done:
	.leave
	ret

callSuper:
	;    Superclass will just use object dimensions
	;

	mov	di, offset GroupClass
	call	ObjCallSuperNoLock
	jmp	done

GroupCalcPARENTDimensions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCalcBoundsOfChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in passed RectDWFixed with bounds of children
		in the destGState coordinate system
		

CALLED BY:	INTERNAL

PASS:		
		*ds:si - group
		ss:bp  -   BoundingRectData
			parentGState
			destGState

RETURN:		
		ss:bp - BoundingRectData
			rect

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCalcBoundsOfChildren		proc	near
	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	call	ECGroupCheckLMemObject			>

	movdw	cxbx, ssbp				;main BRD

	; we must borrow stack space to handle recursion

	mov	dx, sp					;dx is old SP
	mov	di, 800
	call	ThreadBorrowStackSpace
	tst	di
	jz	noNewStack

	; we have a new stack -- point cx:bx at relocated stack

	xchg	bx, di
	call	MemLock
	xchg	bx, di
	mov_tr	cx, ax
	sub	bx, dx
	mov	bp, sp
	add	bx, ss:[bp].SL_savedStackPointer
noNewStack:
	push	di

	;    Create stack frame that will be passed to each child
	;    and then combined with the main BoundingRectData that
	;    was passed to this routine.
	;

	sub	sp,size BoundingRectData
	mov	bp,sp
	push	es
	mov	es, cx
	mov	ax,es:[bx].BRD_parentGState
	mov	ss:[bp].BRD_parentGState,ax
	mov	ax,es:[bx].BRD_destGState
	mov	ss:[bp].BRD_destGState,ax
	clr	ss:[bp].BRD_initialized
	pop	es
	mov	dx,bx					;main BRD offset

	mov	bx, SEGMENT_CS
	mov	di, offset GroupCalcBoundsOfChildrenCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	add	sp, size BoundingRectData

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
GroupCalcBoundsOfChildren		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCalcBoundsOfChildrenCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand the passed RectDWF by the bounds of the child

CALLED BY:	ObjCompProcessChildren

PASS:		
		*ds:si - child
		*es:di - group
		ss:bp - BoundingRectData to be passed to child
		cx:dx - BoundingRectData to be expanded with
			BoundingRectData returned from child

RETURN:		
		clc - to keep going

DESTROYED:	
		bx,si,di,es - ok because call back

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCalcBoundsOfChildrenCB		proc	far
	class	GroupClass
	uses	ax
	.enter

	;    Don't calc bounds of paste inside children
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags,mask GOAF_PASTE_INSIDE
	jnz	done

	;    Get bounds of child in destGState coords
	;

	mov	ax,MSG_GO_GET_BOUNDING_RECTDWFIXED
	call	ObjCallInstanceNoLockES

	;
	; If we get all zeroes back, this is because GrGetPathBoundsDWord
	; drew an ellipse that was very small, and apparently trivially 
	; rejected.   We'll account for this and not add this child's
	; bounds into the bounds of the object.  4/19/94 cbh
	; (Trashes: ax, di, sets es <- ss)
	;
	push	cx
	mov	cx, size RectDWFixed
	segmov	es, ss, ax
	clr	ax
	lea	di, ss:[bp].BRD_rect
	repz	scasb
	pop	cx
	jz	done				;all zeroes, exit

	;    If the main BRD_rect is uninitialized then copy
	;    the childs bounds into it. Otherwise combine the
	;    the childs rect with the main rect.
	;

	mov	ds,cx				;main BRD segment
	mov	si,dx				;main BRD offset

; No longer needed 4/19/94 cbh
;	segmov	es,ss,ax			;childs BRD segment

	mov	di,bp				;childs BRD offset
	tst	ds:[si].BRD_initialized
	jz	copyRect

	call	GrObjGlobalCombineRectDWFixeds

done:
	clc					;keep processing children

	.leave
	ret

copyRect:
	mov	ds:[si].BRD_initialized,1
	call	GrObjGlobalCopyRectDWFixed
	jmp	done

GroupCalcBoundsOfChildrenCB		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupReCenterGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reposition the center of the group and all of the objects
		so that center is actually in the center of the bounds
		of the objects.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - group
		ss:bp - BoundingRectData - 
			BRD_rect bounds of children in group's OBJECT
			coordinate system
			
RETURN:		
		group and all children may have moved

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
POSITIVE_MIN_SHIFT_INT_HIGH = 	0
POSITIVE_MIN_SHIFT_INT_LOW =  	0
POSITIVE_MIN_SHIFT_FRAC = 	0008h
NEGATIVE_MAX_SHIFT_INT_HIGH =	0ffffh
NEGATIVE_MAX_SHIFT_INT_LOW =	0ffffh
NEGATIVE_MAX_SHIFT_FRAC =	0fff8h

GroupReCenterGroup		proc	near
	uses	bx
	.enter

	sub	sp,size PointDWFixed
	mov	bx,sp
	call	GroupCalcCenterShift
	xchg	bx,bp				;bp <- PointDWFixed frame
						;bx <- BRD frame

	;   Eliminate tiny moves that are caused by rounding errors
	;

	jgDWF	ss:[bp].PDF_x.DWF_int.high,\
		ss:[bp].PDF_x.DWF_int.low,\
		ss:[bp].PDF_x.DWF_frac,\
		POSITIVE_MIN_SHIFT_INT_HIGH,\
		POSITIVE_MIN_SHIFT_INT_LOW,\
		POSITIVE_MIN_SHIFT_FRAC,\
		doMove

	jlDWF	ss:[bp].PDF_x.DWF_int.high,\
		ss:[bp].PDF_x.DWF_int.low,\
		ss:[bp].PDF_x.DWF_frac,\
		NEGATIVE_MAX_SHIFT_INT_HIGH,\
		NEGATIVE_MAX_SHIFT_INT_LOW,\
		NEGATIVE_MAX_SHIFT_FRAC,\
		doMove

	jgDWF	ss:[bp].PDF_y.DWF_int.high,\
		ss:[bp].PDF_y.DWF_int.low,\
		ss:[bp].PDF_y.DWF_frac,\
		POSITIVE_MIN_SHIFT_INT_HIGH,\
		POSITIVE_MIN_SHIFT_INT_LOW,\
		POSITIVE_MIN_SHIFT_FRAC,\
		doMove

	jgDWF	ss:[bp].PDF_y.DWF_int.high,\
		ss:[bp].PDF_y.DWF_int.low,\
		ss:[bp].PDF_y.DWF_frac,\
		NEGATIVE_MAX_SHIFT_INT_HIGH,\
		NEGATIVE_MAX_SHIFT_INT_LOW,\
		NEGATIVE_MAX_SHIFT_FRAC,\
		afterMove
doMove:
	call	GroupMoveGroupNowhere

afterMove:
	xchg	bx,bp				;bx <- PointDWFixed frame
						;bp <- BRD frame
	add	sp, size PointDWFixed

	.leave
	ret
GroupReCenterGroup		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupMoveGroupNowhere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the children the negative of the passed deltas
		(so that once the center of the group has been
		moved they will stay in the same place in DOCUMENT
		coordinates), then convert the deltas to
		the group's PARENT coordinates and move the
		group.


CALLED BY:	INTERNAL

PASS:		
		*ds:si - group
		ss:bp - PointDWFixed - deltas to move center of
		group in group's OBJECT coordinate system

RETURN:		
		nothing

DESTROYED:	
		ss:bp - PointDWFixed - destroyed

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupMoveGroupNowhere		proc	near
	class	GroupClass
	uses	bx,dx,di,es
	.enter

EC <	call	ECGroupCheckLMemObject			>

	;    Move  the children
	;

	negdwf	ss:[bp].PDF_x
	negdwf	ss:[bp].PDF_y
	mov	bx, SEGMENT_CS
	mov	di, offset GroupMoveGroupNowhereCB
	call	GroupProcessAllChildrenInDrawOrderCommon
	negdwf	ss:[bp].PDF_x
	negdwf	ss:[bp].PDF_y

	;    Convert the deltas into deltas in the group's 
	;    PARENT coordinate system
	;

	segmov	es,ss,dx
	mov	dx,bp
	clr	di
	call	GrCreateState
	call	GrObjApplyNormalTransformSansCenterTranslation
	call	GrTransformDWFixed
	call	GrDestroyState

	;    Move center of group
	;

	call	GrObjMoveNormalRelative

	.leave
	ret
GroupMoveGroupNowhere		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupMoveGroupNowhereCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move each child

CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		
		*ds:si - child
		*es:di - group
		ss:bp - PointDWFixed - deltas to move child

RETURN:		
		clc - to keep going

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupMoveGroupNowhereCB		proc	far
	.enter

	call	GrObjMoveNormalRelative

	clc

	.leave
	ret
GroupMoveGroupNowhereCB		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCalcCenterShift
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate how far the current center of the group is
		from the actual center of the bounds of the objects
		within the group.

		Since the passed bounds are in OBJECT coordinates and
		the center of the group is 0,0 in object coordinates
		we are just calculating the center of the rectangle.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - group
		ss:bp - BoundingRectData
			BRD_rect bounds of children in group's OBJECT
			coordinate system
		ss:bx - PointDWFixed - empty


RETURN:		
		ss:bx - PointDWFixed amount to move center of group

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCalcCenterShift		proc	near
	class	GroupClass
	uses	ax,cx,dx,di,si
	.enter

EC <	call	ECGroupCheckLMemObject			>

	;    Calc x of center of rect
	;    (right - left)/2 + left
	;

	push	bx				;point frame
	MovDWF	dx,cx,ax, ss:[bp].BRD_rect.RDWF_right
	MovDWF	di,si,bx, ss:[bp].BRD_rect.RDWF_left
	SubDWF	dx,cx,ax, di,si,bx
	ShrDWF	dx,cx,ax
	AddDWF	dx,cx,ax, di,si,bx
	pop	bx				;point frame
	MovDWF	ss:[bx].PDF_x, dx,cx,ax

	;    Calc y of center of rect
	;    (bottom - top)/2 + top
	;

	push	bx				;point frame
	MovDWF	dx,cx,ax, ss:[bp].BRD_rect.RDWF_bottom
	MovDWF	di,si,bx, ss:[bp].BRD_rect.RDWF_top
	SubDWF	dx,cx,ax, di,si,bx
	ShrDWF	dx,cx,ax
	AddDWF	dx,cx,ax, di,si,bx
	pop	bx				;point frame
	MovDWF	ss:[bx].PDF_y, dx,cx,ax

	.leave
	ret

GroupCalcCenterShift		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Have a gstate created with the transformations of all groups
	above it, plus its own

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

RETURN:		
		bp - gstate
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCreateGState	method dynamic GroupClass, MSG_GROUP_CREATE_GSTATE
	.enter

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	mov	di, OBJECT_GSTATE
	call	GrObjCreateGState
	mov	bp,di					;gstate

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
GroupCreateGState		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCreateGStateForBoundsCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Create a gstate with no window and no body translation, but
	includes the transformations of this group and all the
	groups above it.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

RETURN:		
		bp - gstate
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCreateGStateForBoundsCalc	method dynamic GroupClass, 
			MSG_GROUP_CREATE_GSTATE_FOR_BOUNDS_CALC
	.enter

	mov	di, OBJECT_GSTATE
	call	GrObjCreateGStateForBoundsCalc

	mov	bp,di					;gstate

	.leave
	ret
GroupCreateGStateForBoundsCalc		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCombineSelectionStateNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Group method for
		MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		^hcx = GrObjNotifySelectionStateChange struct

Return:		carry set if relevant diff bit(s) are all set

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCombineSelectionStateNotificationData	method dynamic	GroupClass,
			 MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

	.enter

	mov	di, offset GroupClass
	call	ObjCallSuperNoLock

	;
	;  Indicate that a group is selected
	;
	mov	bx, cx
	call	MemLock
	jc	done
	mov	es, ax

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_UNGROUP
	jnz	unlockBlock
	BitSet	es:[GONSSC_selectionState].GSS_flags, GSSF_UNGROUPABLE
unlockBlock:
	call	MemUnlock

	;
	;  Now send the block to our children
	;

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	clr	bx
	mov	di,OCCT_SAVE_PARAMS_TEST_ABORT
	mov	ax, MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA
	call	GroupProcessAllChildrenInDrawOrderCommon
	
	pop	di
	call	ThreadReturnStackSpace

done:
	.leave
	ret
GroupCombineSelectionStateNotificationData	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupVisTextGenerateNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_VIS_TEXT_GENERATE_NOTIFY to all our children
		who are text objects and MSG_GROUP_VIS_TEXT_GENERATE_NOTIFY
		to all our children groups

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		same as MSG_VIS_TEXT_GENERATE_NOTIFY

RETURN:		
		same as MSG_VIS_TEXT_GENERATE_NOTIFY
	
DESTROYED:	
		same as MSG_VIS_TEXT_GENERATE_NOTIFY

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupVisTextGenerateNotify	method dynamic GroupClass, 
					MSG_GROUP_VIS_TEXT_GENERATE_NOTIFY
	.enter

	mov	bx, SEGMENT_CS
	mov	di, offset GroupVisTextGenerateNotifyCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	.leave
	ret
GroupVisTextGenerateNotify		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupVisTextGenerateNotifyCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_VIS_TEXT_GENERATE_NOTIFY to this child if it
		is a text objects and MSG_GROUP_VIS_TEXT_GENERATE_NOTIFY
		to it if it is a group

CALLED BY:	ObjCompProcessChildren

PASS:		*ds:si - child optr
		*es:di - group optr
		ss:bp - VisTextGenerateNotifyParams
		dx - size VisTextGenerateNotifyParams
		cx = ss

RETURN:		
		clc - to keep processing

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
	srs	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupVisTextGenerateNotifyCB		proc	far
	class	GroupClass
	uses	cx,dx,bp
	.enter
	;    Only deal with normal children
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags,mask GOAF_PASTE_INSIDE
	jnz	done

	push	cx, dx, bp				;message params
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	pop	cx, dx, bp				;message params
	jnc	checkGroup

	;
	;  We're a text guardian, so send the message to the ward
	;
	mov	ax,MSG_VIS_TEXT_GENERATE_NOTIFY
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard

done:
	clc				;keep processing
	.leave
	ret


checkGroup:
	push	cx, dx, bp				;message params
	mov	cx, segment GroupClass
	mov	dx, offset GroupClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	pop	cx, dx, bp				;message params
	jnc	done

	; Protect from stack overflow.
	; The data on the stack for this call is a VisTextGenerateNotifyParams
	; structure.
	mov	di, size VisTextGenerateNotifyParams
	push	di					;popped by routine
	mov	di, 800
	call	GrObjBorrowStackSpaceWithData
	push	di					;save token for
							;ReturnStack
	
	; Be sure that cx=ss (for C version).. it is in the documentation
	; for MSG_VIS_TEXT_GENERATE_NOTIFY.
	mov	cx, ss
	
	mov	ax,MSG_GROUP_VIS_TEXT_GENERATE_NOTIFY
	call	ObjCallInstanceNoLockES
	
	pop	di
	call	GrObjReturnStackSpaceWithData
	
	mov	cx, ss
	
	jmp	done

GroupVisTextGenerateNotifyCB		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCheckForGrObjTexts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if there are any text objects in the group.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass


RETURN:		
		clc - no
		stc - yes
	
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
	srs	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCheckForGrObjTexts	method dynamic GroupClass, 
					MSG_GROUP_CHECK_FOR_GROBJ_TEXTS
	.enter

	mov	bx, SEGMENT_CS
	mov	di, offset GroupCheckForGrObjTextsCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	.leave
	ret
GroupCheckForGrObjTexts		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCheckForGrObjTextsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for child being a text object or a group with
		a text object in it.
		
		

CALLED BY:	ObjCompProcessChildren

PASS:		*ds:si - child optr
		*es:di - group optr

RETURN:		
		clc - no text
		stc - at least one text object

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
	srs	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCheckForGrObjTextsCB		proc	far
	class	GroupClass
	uses	cx,dx,bp
	.enter
	;    Only deal with normal children
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags,mask GOAF_PASTE_INSIDE
	jnz	done

	push	cx, dx, bp				;message params
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	pop	cx, dx, bp				;message params
	jnc	checkGroup

done:
	.leave
	ret


checkGroup:
	push	cx, dx, bp				;message params
	mov	cx, segment GroupClass
	mov	dx, offset GroupClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	pop	cx, dx, bp				;message params
	jnc	done

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di
	
	mov	ax,MSG_GROUP_CHECK_FOR_GROBJ_TEXTS
	call	ObjCallInstanceNoLockES
	
	pop	di
	call	ThreadReturnStackSpace

	jmp	done
	
GroupCheckForGrObjTextsCB		endp

; BEGIN UNUSED CODE --------------------------------------------------
if	0		; Not used by anybody in GrObj..


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GroupGetNumChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns the number of GrObjs in the group

Pass:		*ds:si = Group

Return:		cx = # children

Destroyed:	nothing
	
Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 19, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupGetNumChildren	proc	far
	uses	bx, di
	.enter

	clr	cx					;zero counter
	mov	bx, SEGMENT_CS
	mov	di, offset GroupGetNumChildrenCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	.leave
	ret
GroupGetNumChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GroupGetNumChildrenCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 19, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupGetNumChildrenCB	proc	far

	.enter

	inc	cx	

	.leave
	ret
GroupGetNumChildrenCB	endp

endif  ;0
; END UNUSED CODE ----------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GroupRecallStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sends the recall style message to its selected grobjies,
		then dec's the ref count so that the block can be freed

Pass:		*ds:si - Group object
		ds:di - Group instance

		ax - MSG_META_STYLED_OBJECT_RECALL_STYLE

		ss:[bp] - SSCRecallStyleParams

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupRecallStyle	method	GroupClass, 
			MSG_META_STYLED_OBJECT_RECALL_STYLE
	.enter

	;
	;	Forward the message to any selected grobjs
	;
	call	GroupSendToNormalChildren

	;
	;	Decrement the ref count (presumably to free the block)
	;
	mov	bx, ss:[bp].SSCRSP_blockHandle
	call	MemDecRefCount

	.leave
	ret
GroupRecallStyle	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the group can't handle the message then send it
		to the children

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx - handle of ClassedEvent
		dx - TravelOptions
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
	srs	6/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupSendClassedEvent	method dynamic GroupClass, 
						MSG_META_SEND_CLASSED_EVENT
eventHandle	local	hptr 	push	cx
travelOption	local	word 	push	dx
	.enter

	cmp	dx,TO_TARGET
	je	target

callSuper:
	mov	cx,eventHandle
	mov	dx,travelOption
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	push	bp					;stack frame
	mov	di, offset GroupClass
	CallSuper	MSG_META_SEND_CLASSED_EVENT
	pop	bp					;stack frame

done:
	.leave

	Destroy	ax,cx,dx,bp

	ret

target:
	;    Get the class of the encapsulated message
	;

	mov	bx,cx					;event handle
	mov	dx,si					;guardian chunk
	call	ObjGetMessageInfo
	xchg	dx,si					;event class offset,
							;guard chunk

	jcxz	noClass

	;    If the group can handle the message, then send it
	;    to the group. Otherwise send to children.
	;

	push	bp					;save locals
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLock
	pop	bp					;restore locals
	jc	callSuper

toChildren:
	;    Send message to the group's children.
	;

	mov	cx, ss:[eventHandle]
	mov	dx, ss:[travelOption]
	call	GroupSendClassedEventToChildren
	jmp	done

noClass:
	;    If the message has no class then it is intended for the leaf,
	;    but most of these classless message can't be handled 
	;    intelligently by multiple objects (eg MSG_META_COPY), except
	;    for MetaTextMessages. So if the message is classless
	;    send it to the group unless it is a MetaTextMessage.
	;
	
	call	GrObjGlobalCheckForMetaTextMessages
	jnc	callSuper
	jmp	toChildren


GroupSendClassedEvent		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupSendClassedEventToChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate and send the classed event to each child

CALLED BY:	INTERNAL
		GroupSendClassedEvent

PASS:		
		*ds:si - group
		cx - event handle
		dx - TravelOption

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
	srs	6/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupSendClassedEventToChildren		proc	near
	.enter

	mov	bx, SEGMENT_CS
	mov	di, offset GroupSendClassedEventToChildrenCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	mov	bx,cx					;event handle
	call	ObjFreeMessage

	.leave
	ret
GroupSendClassedEventToChildren		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupSendClassedEventToChildrenCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate the message and send it to the child

CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		*ds:si - child
		*es:di - group
		cx - event handle
		dx - TravelOption

RETURN:		
		nothing

DESTROYED:	
		bx - ok because it is a call back routine

PSEUDO CODE/STRATEGY:
		Must be a FAR routine because it is used as a call back

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupSendClassedEventToChildrenCB		proc	far
	class	GroupClass
	uses	ax,cx,dx,bp
	.enter

	;    Don't process children with paste inside bit set
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags,mask GOAF_PASTE_INSIDE
	jnz	done

	mov	bx,cx					;event handle
	call	ObjDuplicateMessage
	mov	cx,ax					;new event handle	
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	call	ObjCallInstanceNoLockES

done:
	clc
	.leave
	ret
GroupSendClassedEventToChildrenCB		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupMetaSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment our suspend count and send message onto our
		children.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

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
	srs	11/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupMetaSuspend	method dynamic GroupClass, MSG_META_SUSPEND
	.enter

	call	ObjMarkDirty
	inc	ds:[di].GI_suspendCount

	mov	di, 500
	call	ThreadBorrowStackSpace

	push	di					;stack token
	clr	bx
	mov	di,OCCT_SAVE_PARAMS_DONT_TEST_ABORT	
	call	GroupProcessAllChildrenInDrawOrderCommon
	pop	di					;stack token

	call	ThreadReturnStackSpace

	.leave
	ret
GroupMetaSuspend		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupMetaUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message onto our normal children and decrement our
		suspend count. If the suspend count goes to
		zero then perform GroupUnsuspendOps

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

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
	srs	11/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupMetaUnsuspend	method dynamic GroupClass, MSG_META_UNSUSPEND
	.enter


EC <	tst	ds:[di].GI_suspendCount
EC <	ERROR_Z	GROBJ_UNSUSPENDED_WHEN_NOT_ALREADY_SUSPENDED

	;   Must send to children before processing ourselves so
	;   that ops suspend in children will bubble up to us.
	;

	mov	di, 500
	call	ThreadBorrowStackSpace

	push	di					;stack token
	clr	bx
	mov	di,OCCT_SAVE_PARAMS_DONT_TEST_ABORT	
	call	GroupProcessAllChildrenInDrawOrderCommon
	pop	di					;stack token

	call	ThreadReturnStackSpace

	;   Decrement our suspend count
	;

	call	ObjMarkDirty
	GrObjDeref	di,ds,si
	dec	cx
	mov	ds:[di].GI_suspendCount,cx
	jz	unsuspended

done:
	.leave
	ret

unsuspended:
	test	ds:[di].GI_unsuspendOps,mask GUO_EXPAND
	jz	done

	BitClr	ds:[di].GI_unsuspendOps, GUO_EXPAND

	mov	ax,MSG_GROUP_EXPAND
	call	ObjCallInstanceNoLock
	jmp	done

GroupMetaUnsuspend		endm





GrObjGroupCode	ends


GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupProcessAllChildrenInDrawOrderCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to all children of group in order of the
		draw list

CALLED BY:	INTERNAL
		GroupSendToChildren

PASS:		
		*ds:si - instance data of group
	
		bx:di - call back routine
			(must be vfptr if XIP'ed)
			ax,cx,dx,bp - parameters to call back
		OR
		bx = 0 ,di - ObjCompCallType
			ax - message to send to children
			cx,dx,bp - parameters to message

RETURN:		
		ax,cx,dx,bp - may be returned depending on message,
		call back or ObjCompCallType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: call back routine must be in the same segment
		as this routine or must have been locked explicitly

		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupProcessAllChildrenInDrawOrderCommon		proc	far
	class	GroupClass
	uses	bx,di,es
	.enter

EC <	call	ECGroupCheckLMemObject			>

	mov	es,bx			;segment of call back or zero
	clr	bx			;initial child (first
	push	bx			;child of
	push	bx			;composite)
	mov	bx, offset GOI_drawLink	;pass offset to LinkPart on stack
	push	bx
	push	es			;pass call-back routine
	push	di			;call back offset or ObjCompCallType

	mov	bx, offset GrObj_offset	;grobj is master

	mov	di,offset GI_drawHead

	call	ObjCompProcessChildren	; must use a call (no GOTO) since
					; parameters are passed on the stack

	.leave
	ret
GroupProcessAllChildrenInDrawOrderCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupProcessAllPasteInsideChildrenCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to all children with GOAF_PASTE_INSIDE bit set

CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		*ds:si - child
		*es:di - group
		ax - message
		cx,dx,bp - message data

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Must be a FAR routine because it is used as a call back

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupProcessAllPasteInsideChildrenCB		proc	far
	class	GroupClass
	uses	ax,cx,dx,bp,di
	.enter

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags,mask GOAF_PASTE_INSIDE
	jz	done

	call	ObjCallInstanceNoLockES

done:
	clc
	.leave
	ret
GroupProcessAllPasteInsideChildrenCB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupProcessAllNormalChildrenCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to all children without GOAF_PASTE_INSIDE bit set

CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		*ds:si - child
		*es:di - group
		ax - message
		cx,dx,bp - message data

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Must be a FAR routine because it is used as a call back

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupProcessAllNormalChildrenCB		proc	far
	class	GroupClass
	uses	ax,cx,dx,bp,di
	.enter

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags,mask GOAF_PASTE_INSIDE
	jnz	done

	call	ObjCallInstanceNoLockES

done:
	clc
	.leave
	ret
GroupProcessAllNormalChildrenCB		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw children of group

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		bp - gstate
		cl - DrawFlags
		dx - GrObjDrawFlags

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
GroupDraw	method dynamic GroupClass, MSG_GO_DRAW
	.enter

	call	GrObjCanDraw?
	jnc	done

	;    Call the super class on these modes will result in
	;    MSG_GO_DRAW_QUICK_VIEW, MSG_GO_DRAW_PARENT_RECT or
	;    MSG_GO_DRAW_CLIP_AREA. All of which can be 
	;    handled by the group. (Most other MSG_GO_DRAW_*
	;    messages may not be sent to the group).
	;

	test	dx,mask GODF_DRAW_QUICK_VIEW or \
		mask GODF_DRAW_WRAP_TEXT_INSIDE_ONLY or \
		mask GODF_DRAW_WRAP_TEXT_AROUND_ONLY
	jnz	callSuper

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	mov	di,bp				;gstate
	call	GrSaveTransform
	call	GrObjApplyNormalTransform
	call	GroupSendToNormalChildren
		
	;    Only the normal children define the clip area, so don't
	;    do paste inside. Especially since it causes death by
	;    trying to begin a path in the middle of an existing one.
	;

	test	dx,mask GODF_DRAW_CLIP_ONLY
	jnz	restore

	GrObjDeref	bx,ds,si

	test	ds:[bx].GOI_attrFlags, mask GOAF_HAS_PASTE_INSIDE_CHILDREN
	jz	restore
	call	GroupDoPasteInside
restore:
	call	GrRestoreTransform

	pop	di
	call	ThreadReturnStackSpace

done:
	.leave
	ret


callSuper:
	mov	di,offset GroupClass
	call	ObjCallSuperNoLock
	jmp	done

GroupDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupDoPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a clipping path from the normal children
		and draw the paste inside children through that
		path.

CALLED BY:	GroupDraw

PASS:		
		*ds:si - group
		di - gstate with groups normal transform applied
		cl - DrawFlags
		dx - GrObjDrawFlags

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
	srs	9/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupDoPasteInside		proc	near
	uses	ax,dx,bp
	.enter

	call	GrSaveState

	;    Create clipping path from normal children
	;

	push	cx					;DrawFlags
	mov	cx,PCT_REPLACE
	call	GrBeginPath
	pop	cx					;DrawFlags

	push	dx,cx					;GrObj/DrawFlags
	mov	bp,di					;gstate
	BitSet	dx,GODF_DRAW_CLIP_ONLY
	mov	ax,MSG_GO_DRAW
	call	GroupSendToNormalChildren

	call	GrEndPath

	mov	dl,RFR_WINDING
	mov	cx,PCT_INTERSECTION
	call	GrSetWinClipPath
	pop	dx,cx					;GrObj/DrawFlags

	;    Draw paste inside children through clip path
	;

	call	GroupSendToPasteInsideChildren

	call	GrRestoreState

	.leave
	ret
GroupDoPasteInside		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupDrawClipArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the clipping area which is formed from only
		the normal children of the group

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		cl - DrawFlags
		bp - GrObjDrawFlags
		dx - gstate

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
	srs	11/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupDrawClipArea	method dynamic GroupClass, MSG_GO_DRAW_CLIP_AREA,
						MSG_GO_DRAW_CLIP_AREA_HI_RES
	.enter

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	mov	bx, SEGMENT_CS
	mov	di, offset GroupDrawClipAreaCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
GroupDrawClipArea		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupDrawClipAreaCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to normal children and preserve the
		transform in the gstate

CALLED BY:	INTERNAL
		GroupDrawClipArea as a callback

PASS:		*ds:si - child
		*es:di - group
		ax - message
		
		cl - DrawFlags
		bp - GrObjDrawFlags
		dx - gstate

RETURN:		
		clc - to keep processing

DESTROYED:	
		di - ok because its a call back routine

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupDrawClipAreaCB		proc	far
	class	GroupClass
	uses	ax
	.enter

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags,mask GOAF_PASTE_INSIDE
	jnz	done
	
	mov	di,dx					;gstate
	call	GrSaveTransform
	call	GrObjApplyNormalTransform
	call	ObjCallInstanceNoLockES
	call	GrRestoreTransform

done:
	clc
	.leave
	ret
GroupDrawClipAreaCB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupSetHasPasteInsideChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set whether group has paste inside children

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

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
	srs	9/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupSetHasPasteInsideChildren	method dynamic GroupClass, 
					MSG_GROUP_SET_HAS_PASTE_INSIDE_CHILDREN
	.enter

	call	ObjMarkDirty

	BitClr	ds:[di].GOI_attrFlags, GOAF_HAS_PASTE_INSIDE_CHILDREN
	cmp	cl, FALSE	;geez, I really hate this TRUE/FALSE crap
	je	done
	BitSet	ds:[di].GOI_attrFlags, GOAF_HAS_PASTE_INSIDE_CHILDREN

done:
	.leave
	ret
GroupSetHasPasteInsideChildren		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupSendToNormalChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all children of body in order of
		the draw list that don't have the GOAF_PASTE_INSIDE bit set.

CALLED BY:	INTERNAL
		

PASS:		
		*ds:si - instance data of graphic body
		ax - message to send to children
		cx,dx,bp - parameters to message

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
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupSendToNormalChildren		proc	far
	uses	bx,di
	.enter

EC <	call	ECGroupCheckLMemObject			>

	mov	bx, SEGMENT_CS					;
	mov	di, offset GroupProcessAllNormalChildrenCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	.leave
	ret
GroupSendToNormalChildren		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupSendToPasteInsideChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all children of body in order of
		the draw list that have the GOAF_PASTE_INSIDE bit set.

CALLED BY:	INTERNAL
		

PASS:		
		*ds:si - instance data of graphic body
		ax - message to send to children
		cx,dx,bp - parameters to message

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
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupSendToPasteInsideChildren		proc	far
	uses	bx,di
	.enter

EC <	call	ECGroupCheckLMemObject			>

	mov	bx, SEGMENT_CS					;
	mov	di, offset GroupProcessAllPasteInsideChildrenCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	.leave
	ret
GroupSendToPasteInsideChildren		endp

GrObjDrawCode	ends


GrObjRequiredInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupEvaluatePARENTPointForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Group evaluates point to determine if group
		should be selected by it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		ss:bp - PointDWFixed in PARENT coords

RETURN:		

		al - EvaluatePositionRating
		dx - EvaluatePositionNotes
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupEvaluatePositionData	struct
	GEPD_pointGroupWWF	PointWWFixed
	GEPD_pointGroupDWF	PointDWFixed
	GEPD_maxPriority	EvaluatePositionRating
	GEPD_notes		EvaluatePositionNotes
	GEPD_childBounds	RectWWFixed
GroupEvaluatePositionData	end

GroupEvaluatePARENTPointForSelection	method dynamic GroupClass, 
			MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION

positionData	local	GroupEvaluatePositionData

	;    Use superclass to check for point within bounds of
	;    group
	;

	mov	di,offset GroupClass
	call	ObjCallSuperNoLock
	cmp	al,EVALUATE_NONE
	je	exit
	
	; Protect from stack overflow.
	; Will save the passed in point.  This is done before the locals are
	; allocated.
	
	mov	di, size PointDWFixed
	push	di				;popped by routine
	mov	di, 800				;number of bytes required
	call	GrObjBorrowStackSpaceWithData
	push	di				;save token for ReturnStack

	.enter

	mov	bx,ss:[bp]				;orig bp,PARENT pt frame

	;    Convert point to OBJECT and store in stack frame.
	;    If OBJECT coord won't fit in WWF then bail
	;

	push	bp					;local frame
	lea	bp, ss:[positionData.GEPD_pointGroupWWF]
	call	GrObjConvertNormalPARENTToWWFOBJECT
	pop	bp					;local frame
	jnc	fail

	;    Also store OBJECT version of point as PointDWFixed so
	;    that it can be passed to the children with a
	;    MSG_GO_EVALUATE_PARENT_POINT
	;

	mov	ax,positionData.GEPD_pointGroupWWF.PF_x.WWF_frac
	mov	positionData.GEPD_pointGroupDWF.PDF_x.DWF_frac,ax
	mov	ax,positionData.GEPD_pointGroupWWF.PF_x.WWF_int
	cwd
	mov	positionData.GEPD_pointGroupDWF.PDF_x.DWF_int.low,ax
	mov	positionData.GEPD_pointGroupDWF.PDF_x.DWF_int.high,dx

	mov	ax,positionData.GEPD_pointGroupWWF.PF_y.WWF_frac
	mov	positionData.GEPD_pointGroupDWF.PDF_y.DWF_frac,ax
	mov	ax,positionData.GEPD_pointGroupWWF.PF_y.WWF_int
	cwd
	mov	positionData.GEPD_pointGroupDWF.PDF_y.DWF_int.low,ax
	mov	positionData.GEPD_pointGroupDWF.PDF_y.DWF_int.high,dx
	
	mov	positionData.GEPD_maxPriority,EVALUATE_NONE
	mov	positionData.GEPD_notes,0

	mov	bx, SEGMENT_CS
	mov	di, offset GroupEvaluatePARENTPointForSelectionCB
	call	GroupProcessAllChildrenInDrawOrderCommon

	mov	al,positionData.GEPD_maxPriority
	mov	dx,positionData.GEPD_notes

checkSelectionLock:
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_SELECT
	jnz	selectionLock

done:
	.leave
	
	pop	di
	call	GrObjReturnStackSpaceWithData
	
exit:
	ret

selectionLock:
	BitSet	dx, EPN_SELECTION_LOCK_SET
	jmp	done

fail:
	mov	al,EVALUATE_NONE			
	clr	dx					;Notes
	jmp	checkSelectionLock

GroupEvaluatePARENTPointForSelection		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupEvaluatePARENTPointForSelectionCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have child evaluate position
		
CALLED BY:	ObjCompProcessChildren

PASS:		
		*ds:si - child
		*es:di - group
		ss:bp - inherited stack frame
			GEPD_groupPointWWF
			GEPD_groupPointDWF

RETURN:		
		GEPD_maxPriority
		GEPD_notes
		stc - stop processing
		clc - continue processing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The groups evaluation of a position is the highest
		evaluation of the point by one of its children.

		We could stop our search when a child returned the
		highest possible priority, but we need to know
		if the overall evaluation should proceed below
		the group. So the evaluation by the groups children
		doesn't stop until a child returns the maximum
		priority AND the "I block out objects underneath me"
		flag.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupEvaluatePARENTPointForSelectionCB		proc	far

positionData	local		GroupEvaluatePositionData

	class	GrObjClass
	uses	ax,cx
	.enter	inherit
	
	;    Don't hit detect paste inside children
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags,mask GOAF_PASTE_INSIDE
	jnz	continue

	;    Get bounds of child in groups coordinate system
	;

	push	bp					;stack frame
	lea	bp,ss:[positionData.GEPD_childBounds]
	CallMod	GrObjGetWWFPARENTBounds
	pop	bp					;stack frame

	;    Expand bounds to allow some near miss selects
	;    even though group scale factor fucks it up some.
	;    Then see if point is within bounds of object
	;

	push	ds,si					;object ptr
	mov	ax,ss
	mov	es,ax					;point segment
	mov	ds,ax					;rect segment
	lea	si,ss:[positionData.GEPD_childBounds]
	lea	di,ss:[positionData.GEPD_pointGroupWWF]
	mov	dx,MINIMUM_SELECT_DELTA
	clr	cx
	CallMod	GrObjGlobalExpandRectWWFixedByWWFixed
	CallMod	GrObjGlobalIsPointWWFixedInsideRectWWFixed?
	pop	ds,si					;object ptr
	jnc	done
	
	;    Send evaluate message to object
	;

	push	bp					;local frame
	lea	bp,ss:[positionData.GEPD_pointGroupDWF]
	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
	call	ObjCallInstanceNoLockES
	pop	bp					;local frame

	;    Store new priority if new priority
	;    is greater than or equal to current. If object also returns
	;    EPN_BLOCKS_LOWER_OBJECTS then stop processing. 
	;    See PSEUDO CODE/STRATEGY for more info
	;

	cmp	positionData.GEPD_maxPriority,al
	jae	done					;implied clc
	mov	positionData.GEPD_maxPriority,al
	mov	positionData.GEPD_notes, dx

	;    If object of highest priority blocks lower objects then 
	;    return carry to stop search
	;

	test	dx, mask EPN_BLOCKS_LOWER_OBJECTS		;implied clc
	jz	done
	stc

done:
	.leave
	ret

continue:
	clc
	jmp	done

GroupEvaluatePARENTPointForSelectionCB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupGetDWFSelectionHandleBoundsForTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	It is not trivial to calculate the selection handle
		bounds for groups

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		ss:bp - RectDWFixed
RETURN:		
		ss:bp - RectDWFixed filled to the limits of graphics system
		
	
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
	srs	11/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupGetDWFSelectionHandleBoundsForTrivialReject method dynamic GroupClass, 
		MSG_GO_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	.enter

	call	GrObjReturnLargeRectDWFixed

	.leave
	ret
GroupGetDWFSelectionHandleBoundsForTrivialReject		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupGainedSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify our children that the group has become selected

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

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
	srs	3/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupGainedSelectionList	method dynamic GroupClass, 
						MSG_GO_GAINED_SELECTION_LIST
	.enter

	mov	di,offset GroupClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_GO_GROUP_GAINED_SELECTION_LIST
	call	ObjCallInstanceNoLock

	.leave
	ret
GroupGainedSelectionList		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupLostSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify our children that the group is no longer selected

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

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
	srs	3/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupLostSelectionList	method dynamic GroupClass, 
						MSG_GO_LOST_SELECTION_LIST
	.enter

	mov	di,offset GroupClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_GO_GROUP_LOST_SELECTION_LIST
	call	ObjCallInstanceNoLock

	.leave
	ret
GroupLostSelectionList		endm





GrObjRequiredInteractiveCode	ends






if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGroupCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an GroupClass or one
		of its subclasses
		
CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - object chunk to check
RETURN:		
		none
DESTROYED:	
		nothing - not even flags

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECGroupCheckLMemObject		proc	far
	uses	es,di
	.enter
	pushf	
	mov	di,segment GroupClass
	mov	es,di
	mov	di,offset GroupClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_A_GROUP_OBJECT	
	popf
	.leave
	ret
ECGroupCheckLMemObject		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGroupCheckLMemOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *bx:si* is a handle,lmem to an object stored
		in an object block and that it is an GroupClass or one
		of its subclasses
		
CALLED BY:	INTERNAL

PASS:		
		bx:si - OD of object chunk to check
RETURN:		
		none
DESTROYED:	
		nothing - not even flags

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECGroupCheckLMemOD		proc	far
	uses	ax,cx,dx,bp,di
	.enter
	pushf	
	mov	cx,segment GroupClass
	mov	dx,offset GroupClass
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	ERROR_NC OBJECT_NOT_A_GROUP_OBJECT	
	popf
	.leave
	ret
ECGroupCheckLMemOD		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupYouCantSendMeThisMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

RETURN:		

	
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
	srs	11/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupYouCantSendMeThisMessage	method dynamic GroupClass, 
					MSG_GO_DRAW_FG_AREA,
					MSG_GO_DRAW_FG_AREA_HI_RES,
					MSG_GO_DRAW_FG_LINE,
					MSG_GO_DRAW_FG_LINE_HI_RES,
					MSG_GO_DRAW_BG_AREA,
					MSG_GO_DRAW_BG_AREA_HI_RES,
					MSG_GO_DRAW_FG_GRADIENT_AREA,
					MSG_GO_DRAW_FG_GRADIENT_AREA_HI_RES
				

	ERROR	GROBJ_GROUP_CANT_HANDLE_THIS_MESSAGE

GroupYouCantSendMeThisMessage		endm


GrObjErrorCode	ends


endif


if	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupInvertGrObjSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have all the children draw their normal sprite

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass
		
		dx - gstate or 0

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
	srs	11/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupInvertGrObjSprite	method dynamic GroupClass, MSG_GO_INVERT_GROBJ_SPRITE
	uses	ax
	.enter

	mov	di,dx
	call	GrObjGetParentGStateStart
	call	GrObjApplySpriteTransform

	mov	ax,MSG_GO_INVERT_GROBJ_NORMAL_SPRITE
	call	GroupSendToNormalChildren

	call	GrObjGetGStateEnd

	.leave
	ret
GroupInvertGrObjSprite		endm

endif
