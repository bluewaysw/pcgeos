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
GroupProcessAllGrObjsInDrawOrderCommon
GroupProcessAllGrObjsSendCallBackMessageCB
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
	Name			Description
	----			-----------
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
GroupProcessAllGrObjsSendCallBackMessage
GroupGetBoundingRectDWFixed
GroupCalcPARENTDimensions
GroupCreateGState
GroupEvaluateParentPoint
GroupPassMessageOntoChildren
GroupCompleteTransform

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
	This file contains routines to implement the GraphicGroup Class
		

	$Id: oldgroup.asm,v 1.1 97/04/04 18:08:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

GroupClass		;Define the class record

GrObjClassStructures	ends



GroupCode	segment resource





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
		GroupExpand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand and position group to contain all its children.
		The children's positions must be relative to the
		center of the group.
		Any transformation stored with the group will be used
		to calculate the size of the group and will be removed
		from the groups instance data.

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
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupExpand	method dynamic GroupClass, MSG_GROUP_EXPAND
	.enter

	;    Clear any transformation that will screw up the results
	;

	push	si
	AccessNormalTransformChunk	si,ds,si
	add	si,offset OT_transform
	call	GrObjGlobalInitGrObjTransMatrix
	pop	si

	;    If we don't have any children then bail
	;    

	tst	ds:[di].GI_drawHead.CP_firstChild.handle
	jz	done

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GroupExpand		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCompleteTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply transform in groups GOI_normalTransform to all
		its children. Expand the group to contain all its
		children and then call super class to complete
		transformation.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		bp - GrObjActionNotificationType

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
	srs	4/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCompleteTransform	method dynamic GroupClass, MSG_GO_COMPLETE_TRANSFORM
	.enter

	call	GroupTransformChildren

	mov	di,offset GroupClass
	call	ObjCallSuperNoLock

	.leave
	ret
GroupCompleteTransform		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupTransformChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply the transformation in the groups GOI_normalTransform
		to all the children

CALLED BY:	INTERNAL
		GroupCompleteTransform

PASS:		
		*ds:si - group

RETURN:		
		nothings

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
	srs	4/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupTransformChildren		proc	near
	class	GroupClass
	uses	ax,cx,bp,di,si,es
	.enter

EC <	call	ECGroupCheckLMemObject				>

	;    Copy groups transform to stack frame
	;

	segmov	es,ss,bp
	sub	sp,size GrObjTransMatrix
	mov	bp,sp
	push	si					;group chunk
	AccessNormalTransformChunk	si,ds,si
	push	si					;normalTransform offset
	add	si,offset OT_transform
	mov	di,bp
	MoveConstantNumBytes	<size GrObjTransMatrix >,cx

	;    Clear transformation from group. Must do this before
	;    transforming children so that it does not affect 
	;    their calculation of their parent bounds
	;

	pop	si					;normalTransform offset
	add	si,offset OT_transform
	call	GrObjGlobalInitGrObjTransMatrix

	;    Apply transform to all of groups children
	;

	pop	si					;group chunk
	mov	ax,MSG_GO_TRANSFORM
	call	GroupSendToChildren

	;    Clear transform stack frame	
	;

	add	sp, size GrObjTransMatrix


	.leave
	ret
GroupTransformChildren		endp




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
	stc
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
	test	ds:[di].GOI_optFlags, mask GOOF_ADDED_TO_BODY
	jz	done
	mov	ax,MSG_GO_AFTER_ADDED_TO_BODY
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
done:

	.leave
	ret
GroupAddGrObj		endm



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
	uses	ax,cx,dx,bp
	.enter

	;    If the group has not been removed from the body
	;    then notify child that it is being removed from body.
	;

	test	ds:[di].GOI_optFlags, mask GOOF_ADDED_TO_BODY
	jz	removeFromGroup
	push	si					;group chunk
	mov	bx,cx
	mov	si,dx
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_BEFORE_REMOVED_FROM_BODY
	call	ObjMessage
	pop	si					;group chunk

removeFromGroup:

	push	si				;group chunk

	;    Build out BeforeRemovedFromGroupData and send to child
	;

	sub	sp, size BeforeRemovedFromGroupData
	mov	bp,sp
	mov	bx,cx				;child handle

	;    Copy groups center into center adjust field
	;

	AccessNormalTransformChunk	si,ds,si	
	add	si,offset OT_center
	segmov	es,ss					;dest segment
	lea	di, ss:[bp + offset BRFGD_centerAdjust]
	MoveConstantNumBytes <size PointDWFixed >, cx

	;    Send remove message to child
	;

	mov	si,dx				;child chunk
	mov	dx,size BeforeRemovedFromGroupData
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_BEFORE_REMOVED_FROM_GROUP
	call	ObjMessage
	add	sp, size BeforeRemovedFromGroupData

	mov	cx,bx				;child handle
	mov	dx,si				;child chunk
	pop	si				;group chunk

	;    Remove child from group
	;

	mov	bp, mask CCF_MARK_DIRTY
	mov	ax, offset GOI_drawLink		;link field
	mov	di, offset GI_drawHead		;head of links
	mov	bx, offset GrObj_offset		;grobj is master
	call	ObjCompRemoveChild


	.leave
	ret
GroupRemoveGrObj		endm




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
			only OGOBAGOF_RELATIVE matters

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

	test	ax, mask OGOBAGOF_RELATIVE
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
		GroupClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify object that it is about to be nuked

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
	srs	11/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupClear	method dynamic GroupClass, MSG_GO_CLEAR
	.enter

	call	GroupSendToChildren

	mov	di,offset GroupClass
	call	ObjCallSuperNoLock

	.leave
	ret
GroupClear		endm





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
		cx - DrawFlags

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

	mov	di,bp
	call	GrSaveTransform
	call	GrObjApplyNormalTransform
	call	GroupSendToChildren
	call	GrRestoreTransform

	.leave
	ret
GroupDraw		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupInvertGrObjSprite
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
GroupInvertGrObjSprite	method dynamic GroupClass, MSG_GO_INVERT_GROBJ_SPRITE
	uses	ax
	.enter

	mov	di,dx
	call	GrObjGetParentGStateStart
	call	GrObjApplySpriteTransform

	mov	ax,MSG_GO_INVERT_GROBJ_NORMAL_SPRITE
	call	GroupSendToChildren

	call	GrObjGetGStateEnd

	.leave
	ret
GroupInvertGrObjSprite		endm



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
GroupInvertGrObjNormalSprite	method dynamic GroupClass, \
					MSG_GO_INVERT_GROBJ_NORMAL_SPRITE
	uses	ax
	.enter

	mov	di,dx
	call	GrObjGetParentGStateStart
	call	GrObjApplyNormalTransform

	call	GroupSendToChildren

	call	GrObjGetGStateEnd

	.leave
	ret
GroupInvertGrObjNormalSprite		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupProcessAllGrObjsSendCallBackMessage
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
GroupProcessAllGrObjsSendCallBackMessage	method dynamic GroupClass, \
			MSG_GROUP_PROCESS_ALL_GROBJS_SEND_CALL_BACK_MESSAGE
	.enter

EC <	push	bx,si						>
EC <	mov	bx,ss:[bp].CBMD_callBackOD.handle		>
EC <	mov	si,ss:[bp].CBMD_callBackOD.chunk		>
EC <	call	ECCheckLMemOD					>
EC <	pop	bx,si						>
EC <	cmp	dx, size CallBackMessageData			>
EC <	ERROR_B STACK_FRAME_NOT_BIG_ENOUGH_TO_BE_CALL_BACK_MESSAGE_DATA >

	mov	bx,cs
	mov	di,offset GroupProcessAllGrObjsSendCallBackMessageCB
	call	GroupProcessAllGrObjsInDrawOrderCommon

	.leave
	ret
GroupProcessAllGrObjsSendCallBackMessage		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupProcessAllGrObjsSendCallBackMessageCB
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
GroupProcessAllGrObjsSendCallBackMessageCB		proc	far
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

GroupProcessAllGrObjsSendCallBackMessageCB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupPassMessageOntoChildren
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
GroupPassMessageOntoChildren	method dynamic GroupClass, 
						MSG_GO_AFTER_ADDED_TO_BODY, 
						MSG_GO_BEFORE_REMOVED_FROM_BODY,
						MSG_GO_SET_AREA_ATTR,
						MSG_GO_SET_AREA_COLOR,
						MSG_GO_SET_AREA_MASK,
						MSG_GO_SET_AREA_DRAW_MODE,
						MSG_GO_SET_AREA_INFO,
						MSG_GO_SET_LINE_ATTR,
						MSG_GO_SET_LINE_COLOR,
						MSG_GO_SET_LINE_MASK,
						MSG_GO_SET_LINE_DRAW_MODE,
						MSG_GO_SET_LINE_END,
						MSG_GO_SET_LINE_JOIN,
						MSG_GO_SET_LINE_STYLE,
						MSG_GO_SET_LINE_WIDTH,
						MSG_GO_SET_LINE_MITER_LIMIT
	.enter

	push	ax
	mov	di, offset GroupClass
	call	ObjCallSuperNoLock
	pop	ax

	call	GroupSendToChildren

	.leave
	ret
GroupPassMessageOntoChildren		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupSendToChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all children of body in order of
		the draw list. The message will be sent to all
		children regardless of message return values

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
GroupSendToChildren		proc	far
	uses	bx,di
	.enter

EC <	call	ECGroupCheckLMemObject			>

	clr	bx					;no call back segment
	mov	di,OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GroupProcessAllGrObjsInDrawOrderCommon

	.leave
	ret
GroupSendToChildren		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupProcessAllGrObjsInDrawOrderCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to all children of group in order of the
		draw list

CALLED BY:	INTERNAL
		GroupSendToChildren

PASS:		
		*ds:si - instance data of group
	
		bx:di - call back routine
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
GroupProcessAllGrObjsInDrawOrderCommon		proc	far
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
GroupProcessAllGrObjsInDrawOrderCommon		endp




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
		put -width/2,-height/2,width/2,height/2 into FourPointDWFixed
		map these points through object transform into document coords
		order these points to form one bounding rect
		calc width and height from bounding rect
		store these as document dimensions		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		nothing


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCalcPARENTDimensions method dynamic GroupClass, \
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
	CallMod	GrObjCreateGState
	mov	ss:[bp].BRD_parentGState,di

	mov	di,PARENT_GSTATE
	CallMod	GrObjCreateGState
	mov	ss:[bp].BRD_destGState,di

	;    Mark the BRD_rect as not initalized so the first child of
	;    the group will copy its bounds into BRD_rect instead of
	;    merging.
	;

	clr	ax
	mov	ss:[bp].BRD_initialized,ax

	;    Calculate the bounds of the children of the group
	;    in the group's PARENT coordinate system. Reposition
	;    the group so that its center is at the middle of the
	;    bounds and adjust all the children to be relative to
	;    this new position. Then set both the OBJECT dimensions
	;    and the PARENT dimensions of the group to the
	;    bounds of the children
	;

	call	GroupCalcBoundsOfChildren
	call	GroupReCenterGroup
	CallMod GrObjGlobalGetWWFixedDimensionsFromRectDWFixed
EC <	ERROR_NC	BUG_IN_DIMENSIONS_CALC			>
	call	GrObjSetNormalOBJECTDimensions
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
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGroupCheckLMemObject			>

	mov	cx,ss					;main BRD segment
	mov	bx,bp					;main BRD offset

	;    Create stack frame that will be passed to each child
	;    and then combined with the main BoundingRectData that
	;    was passed to this routine.
	;

	sub	sp,size BoundingRectData
	mov	bp,sp
	mov	ax,ss:[bx].BRD_parentGState
	mov	ss:[bp].BRD_parentGState,ax
	mov	ax,ss:[bx].BRD_destGState
	mov	ss:[bp].BRD_destGState,ax
	clr	ss:[bp].BRD_initialized
	mov	dx,bx					;main BRD offset

	mov	bx,cs
	mov	di, offset GroupCalcBoundsOfChildrenCB
	call	GroupProcessAllGrObjsInDrawOrderCommon

	add	sp, size BoundingRectData

	mov	bp,dx					;main BRD offset

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
		bx,si,di - ok because call back

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
	uses	ax
	.enter

	;    Get bounds of child in destGState coords
	;

	mov	ax,MSG_GO_GET_BOUNDING_RECTDWFIXED
	call	ObjCallInstanceNoLockES

	;    If the main BRD_rect is uninitialized then copy
	;    the childs bounds into it. Otherwise combine the
	;    the childs rect with the main rect.
	;

	mov	ds,cx				;main BRD segment
	mov	si,dx				;main BRD offset
	segmov	es,ss,ax			;childs BRD segment
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
		ss:bp - BoundingRectData

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

SYNOPSIS:	Move the center of the group the passed deltas in
		the PARENT coordinate system. Then move the children
		the opposite deltas converted to the GROUP coordinate
		system.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - group
		ss:bp - PointDWFixed

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
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupMoveGroupNowhere		proc	near
	class	GroupClass
	uses	bx,cx,dx,bp,di,es
	.enter

EC <	call	ECGroupCheckLMemObject			>

	;    Save current center
	;

	sub	sp,size PointDWFixed
	mov	bx,sp
	push	si					;group chunk
	AccessNormalTransformChunk	si,ds,si
	add	si,offset OT_center			;source offset
	segmov	es,ss					;dest segment
	mov	di,bx					;dest offset
	mov	cx,size PointDWFixed/2
	rep	movsw
	pop	si					;group chunk

	;    Move center of group
	;

	call	GrObjMoveNormalRelative

	;    Converting the original group center to GROUP coordinates
	;    will give the deltas to move the objects
	;

	push	si					;group chunk
	mov	di, OBJECT_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;GROUP gstate

	mov	di, PARENT_GSTATE
	call	GrObjCreateGState
	mov	si,dx					;GROUP gstate

	mov	dx,bx					;orig center offset
	call	GrObjConvertCoordDWFixed
	mov	bp,dx					;object deltas offset

	call	GrDestroyState
	mov	di,si
	call	GrDestroyState

	pop	si					;group chunk
	mov	bx,cs
	mov	di,offset GroupMoveGroupNowhereCB
	call	GroupProcessAllGrObjsInDrawOrderCommon

	add	sp, size PointDWFixed

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
		within the group

CALLED BY:	INTERNAL

PASS:		
		*ds:si - group
		ss:bp - BoundingRectData
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
	uses	ax,cx,dx,di
	.enter

EC <	call	ECGroupCheckLMemObject			>

	;    Calc x of center of rect
	;    (right - left)/2 + left
	;

	push	si,bx				;object chunk, point frame

	MovDWF	dx,cx,ax, ss:[bp].BRD_rect.RDWF_right
	MovDWF	di,si,bx, ss:[bp].BRD_rect.RDWF_left
	SubDWF	dx,cx,ax, di,si,bx
	ShrDWF	dx,cx,ax
	AddDWF	dx,cx,ax, di,si,bx

	pop	si,bx				;object chunk, point frame

	;    Subtract current center x from actual center x
	;    and store in point stack frame

	AccessNormalTransformChunk	di,ds,si
	SubDWF	dx,cx,ax, ds:[di].OT_center.PDF_x
	MovDWF	ss:[bx].PDF_x, dx,cx,ax

	;    Calc y of center of rect
	;    (bottom - top)/2 + top
	;

	push	si,bx				;object chunk, point frame

	MovDWF	dx,cx,ax, ss:[bp].BRD_rect.RDWF_bottom
	MovDWF	di,si,bx, ss:[bp].BRD_rect.RDWF_top
	SubDWF	dx,cx,ax, di,si,bx
	ShrDWF	dx,cx,ax
	AddDWF	dx,cx,ax, di,si,bx

	pop	si,bx				;object chunk, point frame

	;    Subtract current center y from actual center y
	;    and store in point stack frame

	AccessNormalTransformChunk	di,ds,si
	SubDWF	dx,cx,ax, ds:[di].OT_center.PDF_y
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

	mov	di, OBJECT_GSTATE
	call	GrObjCreateGState
	mov	bp,di					;gstate

	.leave
	ret
GroupCreateGState		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupEvaluateParentPoint
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

GroupEvaluateParentPoint	method dynamic GroupClass, MSG_GO_EVALUATE_PARENT_POINT

positionData	local	GroupEvaluatePositionData

	;    Use superclass to check for point within bounds of
	;    group
	;

	mov	di,offset GroupClass
	call	ObjCallSuperNoLock
	cmp	al,EVALUATE_NONE
	je	done

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

	mov	bx,cs
	mov	di,offset GroupEvaluateParentPointCB
	call	GroupProcessAllGrObjsInDrawOrderCommon

	mov	al,positionData.GEPD_maxPriority
	mov	dx,positionData.GEPD_notes

done:
	.leave
	ret

fail:
	mov	al,EVALUATE_NONE			
	clr	dx					;Notes
	jmp	short	done

GroupEvaluateParentPoint		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupEvaluateParentPointCB
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
GroupEvaluateParentPointCB		proc	far

positionData	local		GroupEvaluatePositionData

	class	GrObjClass
	uses	ax,cx
	.enter	inherit

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
	mov	ax,MSG_GO_EVALUATE_PARENT_POINT
	call	ObjCallInstanceNoLockES
	pop	bp					;local frame

	;    Store new priority if new priority
	;    is greater than or equal to current. If object also returns
	;    EPN_BLOCKS_LOWER_OBJECTS then stop processing. 
	;    See PSEUDO CODE/STRATEGY for more info
	;

	cmp	positionData.GEPD_maxPriority,al
	jae	done
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
GroupEvaluateParentPointCB		endp



if	ERROR_CHECK
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
ECGroupCheckLMemObject		proc	near
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

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GroupAttributeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Common GroupClass method for attribute messages

Called by:	

Pass:		*ds:si = Group object
		ds:di = Group instance

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupAttributeCommon	method dynamic	GroupClass,
			MSG_GO_COMBINE_AREA_NOTIFICATION_DATA,
			MSG_GO_COMBINE_LINE_NOTIFICATION_DATA,
			MSG_GO_COMBINE_STYLE_NOTIFICATION_DATA,
			MSG_GO_COMBINE_STYLE_SHEET_NOTIFICATION_DATA

	.enter

	call	GroupSendToChildren

	.leave
	ret	
GroupAttributeCommon	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupCombineSelectionStateNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Group method for
		MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		^hcx = GrObjNotifySelectionStateChange struct

Return:		carry set if relevant diff bit(s) are all set

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCombineSelectionStateNotificationData	method dynamic	GroupClass,
			 MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

	uses	ax

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
	BitSet	es:[GONSSC_selectionState].GSS_flags, GSSF_UNGROUPABLE
	call	MemUnlock
done:
	.leave
	ret
GroupCombineSelectionStateNotificationData	endm


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
	mov	bx, cs
	mov	di, offset GroupGetNumChildrenCB
	call	GroupProcessAllGrObjsInDrawOrderCommon

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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GroupStyleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Forwards any MSG_META_STYLED_OBJECT_* messages to the
		appropriate object(s).

Pass:		*ds:si - GrObjBody object
		ds:di - GrObjBody instance

		ax - MSG_META_STYLED_OBJECT_* (except RECALL_STYLE)

		cx,dx,bp - data

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupStyleCommon	method	GroupClass, 
			MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER,
			MSG_META_STYLED_OBJECT_UPDATE_MODIFY_BOX,
			MSG_META_STYLED_OBJECT_MODIFY_STYLE,
			MSG_META_STYLED_OBJECT_DEFINE_STYLE,
			MSG_META_STYLED_OBJECT_REDEFINE_STYLE,
			MSG_META_STYLED_OBJECT_SAVE_STYLE,
			MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET,
			MSG_META_STYLED_OBJECT_DESCRIBE_STYLE,
			MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS,
			MSG_META_STYLED_OBJECT_APPLY_STYLE,
			MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE,
			MSG_META_STYLED_OBJECT_DELETE_STYLE

	.enter

	call	GroupSendToChildren

	.leave
	ret
GroupStyleCommon	endm


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
	call	GroupSendToChildren

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

	tst	cx
	jz	noClass

	;    If the group can handle the message, then send it
	;    to the group. Otherwise send to children.
	;

	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLock
	jc	callSuper

toChildren:
	;    Send message to the group's children.
	;

	mov	cx,eventHandle
	mov	dx,travelOption
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

	mov	bx,cs
	mov	di,offset GroupSendClassedEventToChildrenCB
	call	GroupProcessAllGrObjsInDrawOrderCommon

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
	uses	ax,cx,dx,bp
	.enter

	mov	bx,cx					;event handle
	call	ObjDuplicateMessage
	mov	cx,ax					;new event handle	
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	call	ObjCallInstanceNoLockES

	.leave
	ret
GroupSendClassedEventToChildrenCB		endp

GroupCode	ends
