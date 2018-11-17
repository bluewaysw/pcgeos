COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		groupTransfer.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	19 may 1992	initial version


DESCRIPTION:
	This file contains methods for GroupTransferClass
	related to cut/copy/paste

	$Id: groupTransfer.asm,v 1.1 97/04/04 18:08:19 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjTransferCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GroupCreateTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Group method for MSG_GO_CREATE_TRANSFER

Called by:	

Pass:		*ds:si = Group object
		ds:di = Group instance

		ss:bp - GrObjTransferParams

Return:		ss:[bp].GTP_curSlot - updated to the next slot in the header

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupCreateTransfer	method dynamic	GroupClass, MSG_GO_CREATE_TRANSFER
	uses	cx, bp
	.enter

	;
	;  Allocate a VMBlock item big enough for our Group
	;
	call	GroupGetNumCopyableGrObjs		;cx <- # children
	tst	cx
	LONG jz	done
	shl	cx
	shl	cx				;cx <- # children * size dword
	add	cx, size VMChainTree + size GrObjEntryPointRelocation
	mov	ss:[bp].GTP_curSize, cx
	mov	bx, ss:[bp].GTP_vmFile
	clr	ax				;user ID
	call	VMAlloc				;ax <- block handle
	clr	di

	movdw	ss:[bp].GTP_id, axdi

	mov_tr	cx, ax				;cx <- group tree block handle

	;
	;  Indicate that we're going to write the tree stuff and the class
	;
	mov	ss:[bp].GTP_curPos, size VMChainTree + size GrObjEntryPointRelocation

	;
	;  Write the rest of our instance data out
	;	
	mov	ax, MSG_GO_WRITE_INSTANCE_TO_TRANSFER
	call	ObjCallInstanceNoLock

	;
	;  The objects in the group should be written out with the
	;  group's center, instead of the passed center
	;
	mov	bx, bp				;ss:bx <- GTP
	sub	sp, size PointDWFixed
	mov	bp, sp
	mov	ax, MSG_GO_GET_CENTER
	call	ObjCallInstanceNoLock
	xchg	bx, bp				;ss:bp <- GTP
						;ss:bx <- group center

	subdwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_x, ss:[bx].PDF_x, ax
	subdwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_y, ss:[bx].PDF_y, ax

	push	bx				;save group center

	;
	;	Write children
	;
	mov_tr	ax, cx				;ax <- group tree block handle
	push	ss:[bp].GTP_textSSP.VTSSSP_treeBlock		;save passed tree block
	mov	ss:[bp].GTP_textSSP.VTSSSP_treeBlock, ax	;our kids want our tree block

	push	ss:[bp].GTP_curSlot		;save passed slot
	mov	ax, ss:[bp].GTP_curPos		;point after our instance data
	mov	ss:[bp].GTP_curSlot, ax

	push	ax				;save current position so
						;we can figure out how many
						;children we have
	;
	;	Store children's data here
	;
	
	; Protect from stack overflow.
	mov	di, size GrObjTransferParams
	push	di				;popped by routine
	mov	di, 800				;number of bytes required
	call	GrObjBorrowStackSpaceWithData
	push	di				;save token for ReturnStack
	
	mov	ax, MSG_GO_CREATE_TRANSFER
	clr	bx					;no call back segment
	mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GroupProcessAllChildrenInDrawOrderCommon
	
	pop	di
	call	GrObjReturnStackSpaceWithData

	;
	;  Setup our VMChainTree
	;
	mov	di, ss:[bp].GTP_curSlot
	pop	cx				;cx <- ptr to after group data
	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_textSSP.VTSSSP_treeBlock
	push	bp
	call	VMLock				;*es:di <- item
	call	VMDirty
	mov	es, ax
	mov	es:[VMCT_meta].VMCL_next, VM_CHAIN_TREE
	mov	es:[VMCT_offset], cx

	;
	;  Calc # children = (new slot - old slot) / size fptr
	;
	sub	di, cx
	shr	di
	shr	di
	mov	es:[VMCT_count], di

	mov	di, size VMChainTree
	mov	ax, MSG_META_GET_CLASS
	call	ObjCallInstanceNoLock
	mov	di, size VMChainTree
	mov	ax, MSG_GO_GET_GROBJ_CLASS
	call	GrObjWriteEntryPointRelocation

	call	VMUnlock
	pop	bp

	;
	;  Store our identifier in the header
	;
	pop	di				;di <- passed slot
	pop	ax				;ax <- passed tree block
	mov	cx, ss:[bp].GTP_textSSP.VTSSSP_treeBlock	;cx <- group block
	mov	ss:[bp].GTP_textSSP.VTSSSP_treeBlock, ax

	push	bp
	call	VMLock
	mov	es, ax
	mov	es:[di].high, cx
	clr	es:[di].low
	call	VMDirty
	call	VMUnlock
	pop	bp

	add	di, size dword				;point to the next slot
	mov	ss:[bp].GTP_curSlot, di

	;
	;  Restore the original center
	;
	pop	bx				;ss:bx <- group center
	adddwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_x, ss:[bx].PDF_x, ax
	adddwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_y, ss:[bx].PDF_y, ax
	add	sp, size PointDWFixed

done:
	.leave
	ret
GroupCreateTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupGetNumCopyableGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns the number of copyable grobjs in the selection list

Pass:		*ds:si - Group

Return:		cx - number of copyable grobjs in the selection list

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 30, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupGetNumCopyableGrObjs	proc	near
	uses	ax, bx, di
	.enter

	mov	ax, MSG_GO_INC_CX_IF_COPYABLE
	clr	bx, cx
	mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GroupProcessAllChildrenInDrawOrderCommon
	
	.leave
	ret
GroupGetNumCopyableGrObjs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GroupReplaceWithTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Group method for MSG_GO_REPLACE_WITH_TRANSFER

Called by:	

Pass:		*ds:si = Group object
		ds:di = Group instance

		ss:[bp] - GrObjTransferParams

Return:		ss:[bp].GTP_curPos - updated to after read data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupReplaceWithTransfer	method dynamic	GroupClass,
				MSG_GO_REPLACE_WITH_TRANSFER
	uses	cx,dx
	.enter

	;
	;  call superclass, updating ss:[bp].GTP_curPos
	;
	mov	di, offset GroupClass
	call	ObjCallSuperNoLock

	;
	;  Translate to the group's center
	;
	mov	bx, bp				;ss:bx <- GTP
	sub	sp, size PointDWFixed
	mov	bp, sp
	mov	ax, MSG_GO_GET_CENTER
	call	ObjCallInstanceNoLock
	xchg	bx, bp				;ss:bp <- GTP
						;ss:bx <- group center

	subdwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_x, ss:[bx].PDF_x, ax
	subdwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_y, ss:[bx].PDF_y, ax

	push	bx				;save group center

	;
	;  Read our children out of the tree
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_id.high
	mov	di, bp				;ss:[di] <- GTP
	call	VMLock
	push	bp				;save handle for unlocking
	mov	bp, di				;ss:[bp] <- GTP
	mov	es, ax

	mov	cx, es:[GOTBH_meta].VMCT_count
	mov	bx, es:[GOTBH_meta].VMCT_offset

	;
	;  save passed tree block
	;
	push	ss:[bp].GTP_textSSP.VTSSSP_treeBlock

objLoop:
	movdw	ss:[bp].GTP_id, es:[bx], ax
	mov	ax, MSG_GROUP_INSTANTIATE_GROBJ
	jcxz	afterLoop
	push	cx					;save # children
	call	GrObjParseOneGrObj

	;
	;  Add the new child to the group	
	;
	push	bp
	mov     bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax, MSG_GROUP_ADD_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	add	bx, size dword
	pop	cx					;cx <- # children
	loop	objLoop

afterLoop:
	
	;
	;  restore group GTP stuff
	;
	pop	ss:[bp].GTP_textSSP.VTSSSP_treeBlock

	mov_tr	ax, bp				;save GTP ptr
	pop	bp				;bp <- mem handle
	call	VMUnlock
	mov_tr	bp, ax				;ss:[bp] <- GTP

	;
	;  Restore the original center
	;
	pop	bx				;ss:bx <- passed center frame
	adddwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_x, ss:[bx].PDF_x, ax
	adddwf	ss:[bp].GTP_selectionCenterDOCUMENT.PDF_y, ss:[bx].PDF_y, ax
	add	sp, size PointDWFixed

	.leave
	ret
GroupReplaceWithTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupIncCxIfCopyable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Group method for MSG_GO_INC_CX_IF_COPYABLE

Called by:	MSG_GO_INC_CX_IF_COPYABLE

Pass:		*ds:si = Group object
		ds:di = Group instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 30, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupIncCXIfCopyable	method dynamic	GroupClass, MSG_GO_INC_CX_IF_COPYABLE
	.enter

	mov_tr	ax, cx					;ax <- # copyable

	test	ds:[di].GOI_locks,mask GOL_COPY
	jnz	dontInc

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di
	
	call	GroupGetNumCopyableGrObjs
	jcxz	dontInc
	
	pop	di
	call	ThreadReturnStackSpace

	inc	ax

dontInc:

	mov_tr	cx, ax

	.leave
	ret
GroupIncCXIfCopyable	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupDeselectIfCopyLockSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deselect the object if its copy lock is set.

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
			copy lock not set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupDeselectIfCopyLockSet	method dynamic GroupClass, 
				MSG_GO_DESELECT_IF_COPY_LOCK_SET
	uses	cx
	.enter

	test	ds:[di].GOI_locks,mask GOL_COPY
	jnz	deselect

	call	GroupGetNumCopyableGrObjs
	jcxz	deselect

done:
	.leave
	ret

deselect:
	mov	ax,MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock
	jmp	done
GroupDeselectIfCopyLockSet		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GroupPasteCallBackForPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add child to group as a paste inside child

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GroupClass

		^lcx:dx - newly pasted grobject

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
	srs	11/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupPasteCallBackForPasteInside	method dynamic GroupClass, 
				MSG_GROUP_PASTE_CALL_BACK_FOR_PASTE_INSIDE
	uses	cx,dx,bp
	.enter

	;    If the child has the group lock set just destroy it
	;    because it shouldn't be pasted inside.
	;

	push	si					;group chunk
	movdw	bxsi,cxdx
	clrdw	cxdx					;no actual lock change
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GO_CHANGE_LOCKS
	call	ObjMessage
	test	cx,mask GOL_GROUP			;child's locks
	jnz	killIt
	movdw	cxdx,bxsi				;child`s od
	pop	si					;group chunk

	;    Add in child with absolute position
	;

	mov	bp,GAGOF_LAST 
	mov	ax,MSG_GROUP_ADD_GROBJ
	call	ObjCallInstanceNoLock

	mov	bx,cx					;child handle
	mov	cl,TRUE
	mov	ax,MSG_GROUP_SET_HAS_PASTE_INSIDE_CHILDREN
	call	ObjCallInstanceNoLock

	mov	si,dx					;child chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_SET_PASTE_INSIDE
	call	ObjMessage

done:
	.leave
	ret

killIt:
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_CLEAR_SANS_UNDO
	call	ObjMessage
	pop	si					;group chunk
	jmp	done

GroupPasteCallBackForPasteInside		endm






GrObjTransferCode	ends

