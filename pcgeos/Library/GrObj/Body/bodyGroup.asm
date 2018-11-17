COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hierarchy
FILE:		graphicBodyGroup.asm

AUTHOR:		Steve Scholl, Nov 15, 1991

ROUTINES:
	Name			Description
	----			-----------
GrObjBodyUnGroupAGroup
GrObjBodyUnGroupSelectedGroupsCB
GrObjBodyAddSelectedGrObjsToGroupCB
GrObjBodyAddSelectedGrObjsToGroup

MSG_HANDLERS
	Name			Description
	----			-----------
GrObjBodyTransferGrObjFromGroup
GrObjBodyGroupSelectedGrObjs
GrObjBodyUnGroupSelectedGroups
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/91	Initial revision


DESCRIPTION:
		

	$Id: bodyGroup.asm,v 1.1 97/04/04 18:08:03 newdeal Exp $
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjGroupCode	segment resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUnGroupAGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ungroup the group. Adding the groups children to the body


CALLED BY:	INTERNAL

PASS:		
		*ds:si - body
		cx:dx - group

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
	srs	11/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUnGroupAGroup		proc	far
	class	GrObjBodyClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject				>
EC <	push	bx,si							>
EC <	mov	bx,cx							>
EC <	mov	si,dx							>
EC <	call	ECGroupCheckLMemOD					>
EC <	pop	bx,si							>

	;    Fill CallBackMessageData structure and have group send
	;    transfer message back to body for each child
	;

	sub	sp, size CallBackMessageData
	mov	bp,sp
	mov	ax,ds:[LMBH_handle]			;body handle
	mov	ss:[bp].CBMD_callBackOD.handle,ax	;body is call back 
	mov	ss:[bp].CBMD_callBackOD.chunk,si
	mov	ss:[bp].CBMD_callBackMessage, \
					MSG_GB_TRANSFER_GROBJ_FROM_GROUP
	push	dx					;group chunk
	mov	bx,cx					;group handle
	mov	ax,MSG_GB_FIND_GROBJ
	call	ObjCallInstanceNoLock
	ornf	cx,mask GOBAGOF_DRAW_LIST_POSITION
	mov	ss:[bp].CBMD_extraData1,cx		;draw position
	pop	si					;group handle
	mov	ax,MSG_GROUP_PROCESS_ALL_GROBJS_SEND_CALL_BACK_MESSAGE
	mov	di,mask MF_FIXUP_DS
	mov	dx,size CallBackMessageData
	call	ObjMessage
	mov	di,ss:[bp].CBMD_callBackOD.chunk	;body chunk
	add	sp, size CallBackMessageData

	;    Destroy that group
	;

	mov	ax,MSG_GO_CLEAR
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjBodyUnGroupAGroup		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTransferGrObjFromGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the child from the group and add it to the graphic
		body.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - CallBackMessageData
			CBMD_groupOD
			CBMD_childOD
			CBMD_extraData1 - position of group in reverse
					order list

RETURN:		
		clc - to keep processing children
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTransferGrObjFromGroup	method dynamic GrObjBodyClass, \
					MSG_GB_TRANSFER_GROBJ_FROM_GROUP
	uses ax,cx,dx
	.enter

	;    Remove child from group. Have group convert object
	;    back into its PARENT coordinate system
	;
	
	push	bp,si				;stack frame, body chunk
	mov	bx,ss:[bp].CBMD_groupOD.handle
	mov	si,ss:[bp].CBMD_groupOD.chunk
	mov	cx,ss:[bp].CBMD_childOD.handle
	mov	dx,ss:[bp].CBMD_childOD.chunk
	clr	bp				;GroupAddGrObjFlags
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GROUP_REMOVE_GROBJ
	call	ObjMessage

	;    Get the childs attr flags so that we can know if it
	;    was a paste inside child. More info further along
	;    in routine.
	;

	;    If the child was a paste inside child then we
	;    need to clear the paste inside bit and invalidate the
	;    child because parts of the child were probably
	;    clipped while it was in the group.
	;

	push	cx					;child handle
	movdw	bxsi,cxdx				;child od
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GO_GET_GROBJ_ATTR_FLAGS
	call	ObjMessage
	mov	di,cx					;child`s attr flags
	pop	cx

	;    Add child to body at the position of the group in
	;    in draw list, so that it ends up in the selection
	;    list before the group. The prevents the child from
	;    being processed by this enum and getting ungrouped too.
	;
	
	pop	bp,si				;frame, body chunk
	push	bp				;stack frame
	mov	bp,ss:[bp].CBMD_extraData1	;group draw order position
	mov	ax,MSG_GB_ADD_GROBJ
	call	ObjCallInstanceNoLock

	;    If the child was a paste inside child, we need to clear
	;    that paste inside bit and invalidate. We need to invalidate
	;    it because parts of the paste inside child may be have been
	;    clipped out and we want them to draw now.
	;

	movdw	bxsi,cxdx			;child od
	test	di,mask GOAF_PASTE_INSIDE	;attr flags
	jz	selectChild

	clr	cl					;false
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_SET_PASTE_INSIDE
	call	ObjMessage

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INVALIDATE
	call	ObjMessage


selectChild:
	;    Tell child to become selected, but not to 
	;    draw its handles so that it looks like the whole
	;    ungroup happens at once.
	;

	mov	dx, HUM_MANUAL
	mov	ax,MSG_GO_BECOME_SELECTED
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp				;stack frame

	;    Because we added a child before it the position
	;    of the group has moved up one. If we didn't do 
	;    this the children would get ungrouped in
	;    the reverse order
	;

	inc	ss:[bp].CBMD_extraData1

	clc					;keep processing children

	.leave
	ret
GrObjBodyTransferGrObjFromGroup		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GBMarkBusyNoSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the process that owns the block the body is in as
		busy, but don't suspend it.

CALLED BY:	
		INTERNAL
PASS:		
		*(ds:si) - graphic body
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
	srs	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GBMarkBusyNoSuspend		proc	near
	uses	ax,cx,dx,bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject				>

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication

	.leave
	ret
GBMarkBusyNoSuspend		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GBMarkNotBusyNoUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the process that owns the block the body is in as
		not busy, but don't unsuspend it.

CALLED BY:	
		INTERNAL
PASS:		
		*(ds:si) - graphic body
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
	srs	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GBMarkNotBusyNoUnsuspend		proc	near
	uses	ax,cx,dx,bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject				>

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication

	.leave
	ret
GBMarkNotBusyNoUnsuspend		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Paste the objects in the clipboard inside the selected
		objects. This is done by making each selected object
		a group and then adding each object in the clipboard
		as a paste inside child of each of the newly formed groups.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

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
GrObjBodyPasteInside	method dynamic GrObjBodyClass, 
						MSG_GB_PASTE_INSIDE
	uses	cx,dx,bp
	.enter

	;    In addition to preventing groups from being created with
	;    group lock objects in them it also resolves nasty
	;    problems if every grobj selected has its group lock set.
	;

	mov	ax,MSG_GO_DESELECT_IF_GROUP_LOCK_SET
	call	GrObjBodySendToSelectedGrObjs

	;    If no selected children then bail
	;

	call	GrObjBodyGetNumSelectedGrObjs	
	tst	bp
	jz	done

	;    Check for overlap of objects in clipboard
	;    and selected objects.
	;

	call	GrObjBodyCheckForPasteInsideOverlapError
	jc	overlapError
	
	call	GBMarkBusyNoSuspend

	;    Start a chain for the entire grouping process
	;

	mov	cx,handle pasteInsideString
	mov	dx,offset pasteInsideString
	call	GrObjGlobalStartUndoChain

	;    Suspend the body so we don't get too many updates
	;

	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock

	;    Make the selected objects into groups so that
	;    we can add the paste inside children to them.
	;

	call	GrObjBodyGroupSelectedObjectsWithThemselves

	;    Paste inside each of the selected groups
	;
	
	call	GrObjBodyPasteInsideSelectedGroups

	;    We need to unsuspend before the invalidate so that
	;    the new groups will expand to their proper size in
	;    time for the invalidation
	;    

	mov	ax, MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	;    Invalidate the groups so that the stuff just
	;    pasted inside can draw. When groups are formed
	;    normally nothing redraws. Need WITH_UNDO so
	;    that undoing a paste inside is guaranteed to redraw.
	;

	mov	ax,MSG_GO_INVALIDATE_WITH_UNDO
	call	GrObjBodySendToSelectedGrObjs

	;    Draw the handles of all the selected groups now.
	;    The handles weren't drawn when the groups were
	;    initially selected so that they wouldn't get
	;    drawn over by objects being pasted in causing
	;    screen glitches next time the handles invert.
	;

	mov	ax,MSG_GO_DRAW_HANDLES
	call	GrObjBodySendToSelectedGrObjs

	call	GrObjGlobalEndUndoChain

	call	GBMarkNotBusyNoUnsuspend

done:

	.leave
	ret

overlapError:
	mov	bx, handle pasteInsideOverlapErrorString
	mov	ax, offset pasteInsideOverlapErrorString
	call	GrObjBodyStandardError

	jmp	done

GrObjBodyPasteInside		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGroupSelectedObjectsWithThemselves
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace each selected child with a group containing
		the child. This is done as part of paste inside.

CALLED BY:	INTERNAL
		GrObjBodyPasteInside

PASS:		*ds:si - GrObjBody

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
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGroupSelectedObjectsWithThemselves		proc	near
	uses	bx,di
	.enter

	mov	bx,SEGMENT_CS
	mov	di,offset GrObjBodyGroupObjectWithItselfCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodyGroupSelectedObjectsWithThemselves		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGroupObjectWithItselfCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the child with a group containing the child.
		This is intended for use on selected objects as
		part of doing paste inside.

CALLED BY:	INTERNAL
		ObjArrayProcessChildren

PASS:		*ds:si - child optr
		*es:di - body optr

RETURN:		
		clc - to keep processing

DESTROYED:	
		bx,si,di,ds,es - ok because call back

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGroupObjectWithItselfCB		proc	far
	uses	ax,cx,dx,bp
	.enter

	;    Get position of selected child so that we can add
	;    group at the same position
	;

	segxchg	ds,es
	xchg	di,si
	mov	cx,es:[LMBH_handle]			;child handle
	mov	dx,di					;child chunk
	mov	ax,MSG_GB_FIND_GROBJ
	call	ObjCallInstanceNoLockES
	
	;    Create and initialize group
	;

	push	di,si					;child,body chunks
	push	cx					;child position
	mov	cx,segment GroupClass
	mov	dx,offset GroupClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLockES

	mov	bx,cx					;group handle
	mov	si,dx					;group chunk
	mov	ax,MSG_GROUP_INITIALIZE
	mov	di,mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage
	pop	bp					;child  position
	pop	di,si					;child,body chunks

	;    Add group to body BEFORE child and select it
	;    now so that is ends up in the selection array
	;    before the child. If the group was to end up
	;    after the child in the selection array or
	;    if the child was removed from the selection array
	;    before the group was added then the selection array
	;    enum code would dutifully process the group and
	;    we would put our new group in another group and
	;    so on and so on. We must mark the group as grobj
	;    valid or it won't get added to the selection list.
	;

	ornf	bp,mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ
	call	ObjCallInstanceNoLockES			;es is child segment

	push	si,di,dx				;body,child,group chunks
	movdw	bxsi,cxdx				;group od

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage

	mov	dx,HUM_MANUAL
	mov	ax,MSG_GO_BECOME_SELECTED
	mov	di,mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage
	pop	si,di,dx				;body,child,group chunks

	;    Remove child from body and selection list, then
	;    add it to group.
	;

	segxchg	es,ds					;body seg,child seg
	xchg	di,si					;body ,child chunk
	call	GrObjBodyAddSelectedGrObjsToGroupCB

	;    Expand group to contain its child.
	;

	movwwf	bxsi,cxdx				;group od
	mov	ax,MSG_GROUP_EXPAND
	mov	di,mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage


	.leave
	ret
GrObjBodyGroupObjectWithItselfCB		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPasteInsideSelectedGroups
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate a paste with each group as the paste call
		back object. On the call back the pasted object will
		be added to the group as a paste inside child.

CALLED BY:	INTERNAL
		GrObjBodyPasteInside

PASS:		*ds:si - GrObjBody

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
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPasteInsideSelectedGroups		proc	near
	uses	bx,di
	.enter

	mov	bx,SEGMENT_CS
	mov	di,offset GrObjBodyPasteInsideSelectedGroupCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodyPasteInsideSelectedGroups		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPasteInsideSelectedGroupCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate a paste with this selected group as the 
		paste call back object

CALLED BY:	INTERNAL
		ObjArrayProcessChildren
		GrobjBodyPasteInsideSelectedGroups

PASS:		*ds:si - selected group
		*es:di - GrObjBody

RETURN:		
		clc - to keep processing

DESTROYED:	
		es,ds,di,si,bx - ok because call back

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		Must be far, this is a call back routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPasteInsideSelectedGroupCB		proc	far
	uses	ax,cx,dx,bp
	.enter

	;    There shouldn't be any non groups in the selection list
	;    unless a selected object had the group lock set.
	;    Just bail if object is not a group
	;

	push	es,di					;body
	mov	di,segment GroupClass
	mov	es,di
	mov	di,offset GroupClass
	call	ObjIsObjectInClass
	pop	es,di					;body
	jnc	done

	;    Set up paste call back to be the group so that
	;    it can add each pasted object as a paste inside
	;    child.
	;

	segxchg	es,ds					;group,body segs
	xchg	di,si					;group,body chunks
	mov	cx,es:[LMBH_handle]			;group handle
	mov	dx,di					;group chunk
	mov	ax,MSG_GROUP_PASTE_CALL_BACK_FOR_PASTE_INSIDE
	call	GrObjBodySetPasteCallBack

	;    Do the paste 
	;

	mov	ax,MSG_GB_PASTE
	call	ObjCallInstanceNoLock

done:
	clc

	.leave
	ret
GrObjBodyPasteInsideSelectedGroupCB		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGroupSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a group object object and add all the selected
		children to it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

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
	srs	11/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGroupSelectedGrObjs	method dynamic GrObjBodyClass, 
					MSG_GB_GROUP_SELECTED_GROBJS
	uses	cx,dx,bp
	.enter

	;    In addition to preventing groups from being created with
	;    group lock objects in them it also resolves nasty
	;    problems if every grobj selected has its group lock set.
	;

	mov	ax,MSG_GO_DESELECT_IF_GROUP_LOCK_SET
	call	GrObjBodySendToSelectedGrObjs

	;    If no selected children then bail
	;

	call	GrObjBodyGetNumSelectedGrObjs	
	tst	bp
	jnz	checkDims

done:
	.leave
	ret

error:	; ERROR NOT REPORTED
	jmp	done

checkDims:
	;    Max sure all selected children will fit in
	;    a group
	;

	mov	dx,MAX_OBJECT_DIMENSION
	call	GrObjBodyCheckBoundsOfSelectedGrObjs
	jnc	error

	call	GBMarkBusy

	;    Start a chain for the entire grouping process
	;

	mov	cx,handle groupString
	mov	dx,offset groupString
	call	GrObjGlobalStartUndoChain
	
	;    Suspend the body so we don't get too many updates
	;

	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock

	call	GrObjBodyGroupSelectedGrObjsLow

	;    Make the group valid and select it
	;

	push	si					;body chunk
	movwwf	bxsi,cxdx				;group od
	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	dx,HUM_NOW
	mov	ax,MSG_GO_BECOME_SELECTED
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	pop 	si					;body chunk
	mov	ax, MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	call	GrObjGlobalEndUndoChain

	call	GBMarkNotBusy

	jmp	done
GrObjBodyGroupSelectedGrObjs		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGroupSelectedGrObjsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a group object object and add all the selected
		children to it

PASS:		
		*(ds:si) - instance data body

RETURN:		
		cx:dx - od of group
	
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
GrObjBodyGroupSelectedGrObjsLow	proc far
					
	uses	ax,bx,bp,si,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Instantiate group object
	;
	push	si					;body chunk

	mov	cx,segment GroupClass
	mov	dx,offset GroupClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	;    Initialize group object
	;

	mov	bx,cx					;group handle
	mov	si,dx					;group chunk
	mov	ax,MSG_GROUP_INITIALIZE
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add group to body at position of highest selected child
	;

	pop 	si					;body chunk
	push	cx,dx					;group od
	call	GrObjBodyGetHighestSelectedChildPosition
	mov	bp,cx					;position in draw list
	ornf	bp, mask GOBAGOF_DRAW_LIST_POSITION
	pop	cx,dx					;group od
	mov	ax,MSG_GB_ADD_GROBJ
	call	ObjCallInstanceNoLock

	;    Add selected children to the group
	;
	
	call	GrObjBodyAddSelectedGrObjsToGroup

	;    Expand group to contain its children
	;

	movwwf	bxsi,cxdx				;group od
	mov	ax,MSG_GROUP_EXPAND
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

GrObjBodyGroupSelectedGrObjsLow		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCheckBoundsOfSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check bounds of selected children against passed limit

CALLED BY:	INTERNAL
		GrObjBodyGroupSelectedGrObjs

PASS:		
		dx - max allowed bounds dimensions

RETURN:		
		stc - within in limit
		clc - hosed

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
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCheckBoundsOfSelectedGrObjs		proc	far
	uses	ax,bp,cx
	.enter

	sub	sp,size RectDWFixed
	mov	bp,sp
	call	GrObjBodyGetDWFBoundsOfSelectedGrObjs
	clr	cx					;frac of limit
	call	GrObjGlobalCheckWWFixedDimensionsOfRectDWFixed
	lahf
	add	sp, size RectDWFixed
	sahf

	.leave
	ret
GrObjBodyCheckBoundsOfSelectedGrObjs		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAddSelectedGrObjsToGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the selected children to a group. The children must
		be processed in draw order and removed from the selection
		list and from the body before being added to the group
		

CALLED BY:	INTERNAL
		GrObjBodyGroupSelectedGrObjs

PASS:		
		*ds:si - instance data of graphic body
		cx:dx - od of group

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
GrObjBodyAddSelectedGrObjsToGroup		proc	far
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,SEGMENT_CS				; bx <- vseg if XIP'ed
	mov	di,offset GrObjBodyAddSelectedGrObjsToGroupCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodyAddSelectedGrObjsToGroup		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAddSelectedGrObjsToGroupCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add any selected child to a group. The child must
		removed from the selection
		list and from the body before being added to the group

CALLED BY:	ObjArrayProcessChildren
		GrObjBodyAddSelectedGrObjsToGroup
		GrobjBodyGroupObjectWithItselfCB

PASS:		*ds:si -- child handle
		*es:di -- composite handle
		cx:dx - od of group

RETURN:		
		clc - to keep search going

DESTROYED:	
		di,bx,si - ok because call back

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAddSelectedGrObjsToGroupCB		proc	far
	class	GrObjClass
	uses	ax,cx,dx,bp
	.enter

	push	di					;body chunk
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_GROUP
	pop	di					;body chunk
	jnz	done

	;    Remove child from selection list and from
	;    body. Don't use MSG_GO_REMOVE_FROM_BODY because
	;    we don't want the object to invalidate
	;

	mov	ax,MSG_GO_RELEASE_EXCLS
	call	ObjCallInstanceNoLockES

	push	cx,dx					;group od
	mov	cx,ds:[LMBH_handle]			;child handle
	mov	dx,si					;child chunk
	segmov	ds,es					;body seg
	mov	si,di					;body chunk
	mov	ax,MSG_GB_REMOVE_GROBJ
	call	ObjCallInstanceNoLockES
	pop	bx,si					;group od


	;    Add child to group treating child's center as an
	;    relative position, since the group was initalized
	;    to have its center at 0,0
	;

	mov	ax,MSG_GROUP_ADD_GROBJ
	mov	bp,GAGOF_LAST or mask GAGOF_RELATIVE
	mov	di,mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage

done:
	clc					;keep going

	.leave
	ret
GrObjBodyAddSelectedGrObjsToGroupCB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUnGroupSelectedGroups
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ungroup each selected child that is a group

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

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
	srs	11/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUnGroupSelectedGroups	method dynamic GrObjBodyClass, 
					MSG_GB_UNGROUP_SELECTED_GROUPS 
	uses	cx,dx
	.enter

	call	GBMarkBusy

	;    Start a chain for the entire ungrouping process
	;

	mov	cx,handle ungroupString
	mov	dx,offset ungroupString
	call	GrObjGlobalStartUndoChain

	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock

	;    Ungroup all the selected groups
	;

	mov	bx, SEGMENT_CS
	mov	di, offset GrObjBodyUnGroupSelectedGroupsCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	;    Draw handles of all the children that just joined the
	;    selection list
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	dx,ds:[di].GBI_graphicsState
	mov	ax,MSG_GO_DRAW_HANDLES
	call	GrObjBodySendToSelectedGrObjs

	mov	ax, MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	call	GrObjGlobalEndUndoChain

	call	GBMarkNotBusy

	.leave
	ret
GrObjBodyUnGroupSelectedGroups		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUnGroupSelectedGroupsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If child can be ungrouped then ungroup it.

CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		
		*ds:si - child
		*es:di - group
		
RETURN:		
		clc - to keep processing

DESTROYED:	
		ds,si,di - ok because call back

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUnGroupSelectedGroupsCB		proc	far
	uses	ax,cx,dx
	.enter

	mov	ax,MSG_GO_UNGROUPABLE
	call	ObjCallInstanceNoLockES
	jnc	done

	mov	cx,ds:[LMBH_handle]		;group handle	
	segmov	ds,es				;body segment
	mov	dx,si				;group chunk
	mov	si,di				;body chunk
	call	GrObjBodyUnGroupAGroup
done:
	.leave
	ret
GrObjBodyUnGroupSelectedGroupsCB		endp


GrObjGroupCode	ends


GrObjTransferCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCheckForPasteInsideOverlapError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the bounds of the selected objects will
		overlap the bounds of the pasted objects. If not
		then flag an error

CALLED BY:	INTERNAL
		GrObjBodyPasteInside

PASS:		*ds:si - GrObjBody

RETURN:		
		stc - error
		clc - no error

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
	srs	11/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCheckForPasteInsideOverlapError		proc	far
	uses	bp,di,dx
	.enter

	clr	bp					;normal transfer
	call	ClipboardQueryItem
	tst	bp
	jz	error

	mov	di,offset BigFourTransferItemFormatTable
	mov	dx,offset PasteInsideOverlapErrorTransferItemFormatRoutineTable
	call	GrObjBodyCallTransferItemFormatRoutine
	jc	doneWithItem			;jmp if format not found

	tst	bp
	jnz	error

	clc

doneWithItem:
	pushf	
	call	ClipboardDoneWithItem
	popf

	.leave
	ret
error:
	stc
	jmp	doneWithItem


GrObjBodyCheckForPasteInsideOverlapError		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCallTransferItemFormatRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call routine for transfer item format.

CALLED BY:	INTERNAL
		GrObjBodyCheckForPasteInsideOverlapError

PASS:		
		*ds:si - GrObjBody
		bx:ax - vm file handle:vm block handle to transfer item header
		di - offset of table of formats
			first word of table is number of formats
			followed by word pairs manufacturer, format
		dx - offset of table of routine offset
		bp - data for routine

		tables and routines must be in this segment

		routines will be called with
			*ds:si - GrObjBody
			bx - file handle of transfer item
			ax - VM block handle of vm chain
			cx - extra data word 1
			dx - extra data word 2
			bp - passed bp
			
				header
RETURN:		
		stc - no format match
			bp,di - destroyed

		clc - format routine called
			bp,di - from routine called

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
	srs	11/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCallTransferItemFormatRoutine		proc	near
	uses	ax,bx,cx,dx,es
	.enter

	segmov	es,cs				;segment of tables
	mov	cx,es:[di]			;number of formats
	add	di,2				;first format pair offset
	push	bp				;data for routine

nextFormat:
	push	dx				;routine offset
	push	cx				;number of formats
	push	ax				;vm block handle
	push	di				;format offset
	mov	cx,es:[di]			;manufacturer
	mov	dx,es:[di+2]			;format
	call	ClipboardRequestItemFormat
	tst	ax				;vm block handle of header
	jnz	foundFormat
	pop	di				;table offset
	pop	ax				;vm block handle
	pop	cx				;number of formats 
	pop	dx				;routine offset
	add	di,4				;next format offset
	add	dx,2				;next routine offset
	loop	nextFormat
	pop	bp				;unused data for routine

	stc					;no match

done:
	.leave
	ret

foundFormat:
	add	sp,6				;vm block handle, format offset,
						;number of formats
	pop	di				;routine offset
	pop	bp				;data for routine
	call	word ptr cs:[di]		;near call (OK for XIP)
	clc					;format found and called
	jmp	done

GrObjBodyCallTransferItemFormatRoutine		endp


BigFourTransferItemFormatTable word \
	4,
	MANUFACTURER_ID_GEOWORKS, CIF_GROBJ,
	MANUFACTURER_ID_GEOWORKS, CIF_BITMAP,
	MANUFACTURER_ID_GEOWORKS, CIF_TEXT,
	MANUFACTURER_ID_GEOWORKS, CIF_GRAPHICS_STRING

PasteInsideOverlapErrorTransferItemFormatRoutineTable word \
	offset GrObjBodyCheckForSelectionAndGrObjPasteBoundsOverlap,
	offset GrObjBodyCheckForSelectionAndBitmapPasteBoundsOverlap,
	offset GrObjBodyCheckForSelectionAndTextPasteBoundsOverlap,
	offset GrObjBodyCheckForSelectionAndGStringPasteBoundsOverlap



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCheckForSelectionAndGrObjPasteBoundsOverlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for bounds of objects to be pasted to see
		if it overlaps the bounds of the selected objects.

CALLED BY:	INTERNAL
		GrObjBodyCallTransferItemFormatRoutine

PASS:		
		*ds:si - GrObjBody
		bx - file handle of transfer item
		ax - vm block handle of GrObjTransferBlockHeader
		cx - extra data word 1
		dx - extra data word 2
		

RETURN:		
		bp - zero if overlap
		bp - non zero if no overlap

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
	srs	11/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCheckForSelectionAndGrObjPasteBoundsOverlap		proc	near
	uses	ax,bx,cx,dx,ds,es,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjBodyGetRectDWordBoundsOfGrObjPaste
	mov	bx,bp					;paste bounds frame

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjBodyGetBoundsOfSelectedGrObjs

	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	mov	di,bx					;paste bounds offset
	mov	si,bp					;selected bounds offset
	call	GrObjIsRectDWordOverlappingRectDWord?
	jnc	fail

	clr	bp					;success

clearStack:
	add	sp,(size RectDWord)*2
	.leave
	ret

fail:
	mov	bp,1
	jmp	clearStack

GrObjBodyCheckForSelectionAndGrObjPasteBoundsOverlap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCheckForSelectionAndGStringPasteBoundsOverlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for bounds of gstring to be pasted to see
		if it overlaps the bounds of the selected objects.

CALLED BY:	INTERNAL
		GrObjBodyCallTransferItemFormatRoutine

PASS:		
		*ds:si - GrObjBody
		bx - file handle of transfer item
		ax - vm block handle of VMChain
		cx - extra data word 1
		dx - extra data word 2
		

RETURN:		
		bp - zero if overlap
		bp - non zero if no overlap

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
	srs	11/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCheckForSelectionAndGStringPasteBoundsOverlap		proc	near
	uses	ax,bx,cx,dx,ds,es,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjBodyGetRectDWordBoundsOfGStringPaste
	mov	bx,bp					;paste bounds frame

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjBodyGetBoundsOfSelectedGrObjs

	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	mov	di,bx					;paste bounds offset
	mov	si,bp					;selected bounds offset
	call	GrObjIsRectDWordOverlappingRectDWord?
	jnc	fail

	clr	bp					;success

clearStack:
	add	sp,(size RectDWord)*2
	.leave
	ret

fail:
	mov	bp,1
	jmp	clearStack

GrObjBodyCheckForSelectionAndGStringPasteBoundsOverlap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCheckForSelectionAndBitmapPasteBoundsOverlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for bounds of bitmap to be pasted to see
		if it overlaps the bounds of the selected objects.

CALLED BY:	INTERNAL
		GrObjBodyCallTransferItemFormatRoutine

PASS:		
		*ds:si - GrObjBody
		bx - file handle of transfer item
		ax - vm block handle of VMChain
		cx - extra data word 1
		dx - extra data word 2
		

RETURN:		
		bp - zero if overlap
		bp - non zero if no overlap

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
	srs	11/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCheckForSelectionAndBitmapPasteBoundsOverlap		proc	near
	uses	ax,bx,cx,dx,ds,es,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjBodyGetRectDWordBoundsOfBitmapPaste
	mov	bx,bp					;paste bounds frame

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjBodyGetBoundsOfSelectedGrObjs

	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	mov	di,bx					;paste bounds offset
	mov	si,bp					;selected bounds offset
	call	GrObjIsRectDWordOverlappingRectDWord?
	jnc	fail

	clr	bp					;success

clearStack:
	add	sp,(size RectDWord)*2
	.leave
	ret

fail:
	mov	bp,1
	jmp	clearStack

GrObjBodyCheckForSelectionAndBitmapPasteBoundsOverlap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCheckForSelectionAndTextPasteBoundsOverlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for bounds of text to be pasted to see
		if it overlaps the bounds of the selected objects.

CALLED BY:	INTERNAL
		GrObjBodyCallTransferItemFormatRoutine

PASS:		
		*ds:si - GrObjBody
		bx - file handle of transfer item
		ax - vm block handle of VMChain
		cx - extra data word 1
		dx - extra data word 2
		

RETURN:		
		bp - zero if overlap
		bp - non zero if no overlap

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
	srs	11/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCheckForSelectionAndTextPasteBoundsOverlap		proc	near
	uses	ax,bx,cx,dx,ds,es,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	;    The extra data is supposed to be the width and height.
	;    If either clearly isn't a width or height then return
	;    no error because there is nothing we can do.
	;

	clr	bp					;no error
	jcxz	done
	tst	dx
	jz	done

	;    Convert width and height into bounding rect centered
	;    on zero.
	;

	sub	sp,size RectDWord
	mov	bp,sp
	mov	ax,dx					;height
	cwd						;height
	sardw	dxax
	movdw	ss:[bp].RD_right,dxax
	negdw	dxax
	movdw	ss:[bp].RD_left,dxax
	mov	ax,cx					;width
	cwd						;width
	sardw	dxax
	movdw	ss:[bp].RD_bottom,dxax
	negdw	dxax
	movdw	ss:[bp].RD_top,dxax

	call	GrObjBodyAddPastePointToRectDWord
	mov	bx,bp					;text bounds frame

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjBodyGetBoundsOfSelectedGrObjs

	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	mov	di,bx					;paste bounds offset
	mov	si,bp					;selected bounds offset
	call	GrObjIsRectDWordOverlappingRectDWord?
	jnc	fail

	clr	bp					;success

clearStack:
	add	sp,(size RectDWord)*2
done:
	.leave
	ret

fail:
	mov	bp,1
	jmp	clearStack

GrObjBodyCheckForSelectionAndTextPasteBoundsOverlap		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetRectDWordBoundsOfGrObjPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return RectDWord formed from dimensions of paste and
		the paste point. Paste point is middle of paste.
		Must be a CIF_GROBJ paste format

CALLED BY:	INTERNAL
		GrObjBodyCheckForSelectionAndGrObjPasteBoundsOverlap

PASS:		*ds:si - GrObjBody
		bx - vm file handle of transfer item
		ax - vm block handle of GrObjTransferBlockHeader
		ss:bp - RectDWord - empty
RETURN:		
		ss:bp - RectDWord - bounds of paste

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
	srs	11/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetRectDWordBoundsOfGrObjPaste		proc	near
	uses	ax,cx,dx,bp,es
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	mov	cx,bp					;stack frame
	call	VMLock
	mov	es,ax					;segment header block
	push	bp					;mem handle for unlock	
	mov	bp,cx					;stack frame

	;    Init RectDWord to dimensions of paste with 0,0 as middle
	;

	movdw	dxcx,es:[GOTBH_size.PD_x]
	sardw	dxcx
	movdw	ss:[bp].RD_right,dxcx
	negdw	dxcx
	movdw	ss:[bp].RD_left,dxcx
	movdw	dxcx,es:[GOTBH_size.PD_y]
	sardw	dxcx
	movdw	ss:[bp].RD_bottom,dxcx
	negdw	dxcx
	movdw	ss:[bp].RD_top,dxcx

	;    Add in paste point
	;

	call	GrObjBodyAddPastePointToRectDWord

	pop	bp					;mem handle of vm block
	call	VMUnlock

	.leave
	ret
GrObjBodyGetRectDWordBoundsOfGrObjPaste		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetRectDWordBoundsOfGStringPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return RectDWord formed from dimensions of paste and
		the paste point. Paste point is middle of paste.
		Must be a CIF_GRAPHICS_STRING paste format

CALLED BY:	INTERNAL
		GrObjBodyCheckForSelectionAndGStringPasteBoundsOverlap

PASS:		*ds:si - GrObjBody
		bx - vm file handle of transfer item
		ax - vm block handle of VMChain
		ss:bp - RectDWord - empty
RETURN:		
		ss:bp - RectDWord - bounds of paste

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
	srs	11/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetRectDWordBoundsOfGStringPaste		proc	near
	uses	ax,bx,cx,dx
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	push	ds,si					;body
	mov	cl,GST_VMEM
	mov	si,ax					;vm block handle
	call	GrLoadGString

	;    Get bounds of GString and then center those bounds
	;    on 0,0 so that we can position the bounds around
	;    or paste point
	;

	segmov	ds,ss,ax				;RectDWord segment
	mov	bx,bp					;RectDWord offset
	clr	di					;no gstate
	clr	dx					;no control flags
	call	GrGetGStringBoundsDWord

	movdw	dxcx,ss:[bp].RD_right
	adddw	dxcx,ss:[bp].RD_left
	sardw	dxcx
	subdw	ss:[bp].RD_right,dxcx
	subdw	ss:[bp].RD_left,dxcx

	movdw	dxcx,ss:[bp].RD_bottom
	adddw	dxcx,ss:[bp].RD_top
	sardw	dxcx
	subdw	ss:[bp].RD_bottom,dxcx
	subdw	ss:[bp].RD_top,dxcx

	mov	dl,GSKT_LEAVE_DATA
	call	GrDestroyGString

	pop	ds,si					;body

	call	GrObjBodyAddPastePointToRectDWord

	.leave
	ret
GrObjBodyGetRectDWordBoundsOfGStringPaste		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetRectDWordBoundsOfBitmapPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return RectDWord formed from dimensions of paste and
		the paste point. Paste point is middle of paste.
		Must be a CIF_BITMAP paste format

CALLED BY:	INTERNAL
		GrObjBodyCheckForSelectionAndBitmapPasteBoundsOverlap

PASS:		*ds:si - GrObjBody
		bx - vm file handle of transfer item
		ax - vm block handle of VMChain
		ss:bp - RectDWord - empty
RETURN:		
		ss:bp - RectDWord - bounds of paste

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
	srs	11/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetRectDWordBoundsOfBitmapPaste		proc	near
	uses	ax,bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>


	mov	di,ax					;vm block handle
	call	GrGetHugeBitmapSize

	;    Get bounds of Bitmap and then center those bounds
	;    on 0,0 so that we can position the bounds around
	;    or paste point
	;

	sar	ax,1
	mov	ss:[bp].RD_right.low,ax
	neg	ax
	mov	ss:[bp].RD_left.low,ax
	sar	bx,1
	mov	ss:[bp].RD_bottom.low,bx
	neg	bx
	mov	ss:[bp].RD_top.low,bx
	clr	ax
	mov	ss:[bp].RD_right.high,ax
	mov	ss:[bp].RD_bottom.high,ax
	dec	ax					;ffffh
	mov	ss:[bp].RD_left.high,ax
	mov	ss:[bp].RD_top.high,ax

	call	GrObjBodyAddPastePointToRectDWord

	.leave
	ret
GrObjBodyGetRectDWordBoundsOfBitmapPaste		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAddPastePointToRectDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the paste point to both points of a RectDWord

CALLED BY:	INTERNAL
		GrObjBodyGetRectDWordBoundsOfGStringPaste
		GrObjBodyGetRectDWordBoundsOfGrObjPaste
		GrObjBodyGetRectDWordBoundsOfTextPaste

PASS:		
		*ds:si - body
		ss:bp - RectDWord - initialized

RETURN:		
		ss:bp - RectDWord

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
	srs	11/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAddPastePointToRectDWord		proc	near
	uses	bx,bp,dx,cx
	.enter

	mov	bx,bp					;RectDWord offset
	sub	sp,size PointDWFixed
	mov	bp,sp
	call	GrObjBodyGetPastePoint
	mov	dx,ss:[bp].PDF_x.DWF_int.high
	mov	cx,ss:[bp].PDF_x.DWF_int.low
	adddw	ss:[bx].RD_left,dxcx
	adddw	ss:[bx].RD_right,dxcx
	mov	dx,ss:[bp].PDF_y.DWF_int.high
	mov	cx,ss:[bp].PDF_y.DWF_int.low
	adddw	ss:[bx].RD_top,dxcx
	adddw	ss:[bx].RD_bottom,dxcx
	add	sp,size PointDWFixed

	.leave
	ret
GrObjBodyAddPastePointToRectDWord		endp


GrObjTransferCode	ends
