COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		grobjVisGuardianTransfer.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	19 may 1992	initial version


DESCRIPTION:
	This file contains methods for GrObjVisGuardianClass
	related to cut/copy/paste

	$Id: grobjVisGuardianTransfer.asm,v 1.2 98/07/20 12:11:50 joon Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjTransferCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianAfterQuickPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Guardian objects want to be edited after a quick paste

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
GrObjVisGuardianAfterQuickPaste	method dynamic GrObjVisGuardianClass, 
						MSG_GO_AFTER_QUICK_PASTE
	.enter

	mov	ax,MSG_GO_BECOME_EDITABLE
	call	ObjCallInstanceNoLock

	;
	; ensure selected (in case not editable, above won't select)
	;
	mov	ax,MSG_GO_BECOME_SELECTED
	mov	dl, HUM_MANUAL
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjVisGuardianAfterQuickPaste		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjVisGuardianCreateTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjVisGuardian method for MSG_GO_CREATE_TRANSFER

Called by:	

Pass:		*ds:si = GrObjVisGuardian object
		ds:di = GrObjVisGuardian instance

		ss:bp - GrObjTransferParams

Return:		ss:[bp].GTP_curSlot - updated to the next slot in the header

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianCreateTransfer	method dynamic	GrObjVisGuardianClass,
				MSG_GO_CREATE_TRANSFER
	uses	cx, bp
	.enter

	;
	;  Allocate a VMBlock item big enough for our tree, class, and
	;  the ward's 32bit identifier
	;
	mov	cx, size VMChainTree + size GrObjEntryPointRelocation + size dword
	mov	ss:[bp].GTP_curSize, cx
	mov	bx, ss:[bp].GTP_vmFile
	clr	ax				;user ID
	call	VMAlloc				;ax <- block handle
	clr	di

	movdw	ss:[bp].GTP_id, axdi

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
	;	Do the ward thing
	;
	mov	ax, MSG_GOVG_GET_TRANSFER_BLOCK_FROM_VIS_WARD
	call	ObjCallInstanceNoLock

	pushdw	cxdx				;save 32 bit id of ward

	;
	;  Setup our VMChainTree
	;
	mov	di, ss:[bp].GTP_curPos
	mov	ax, ss:[bp].GTP_id.high		;ax <- group block
	push	bp				;save GTP
	call	VMLock				;*es:di <- item
	mov	es, ax
	mov	es:[VMCT_meta].VMCL_next, VM_CHAIN_TREE
	mov	es:[VMCT_offset], di
	mov	es:[VMCT_count], 1
	call	VMDirty

	;
	;  Write guardian class
	;
	mov	ax,MSG_META_GET_CLASS
	call	ObjCallInstanceNoLock
	mov	di, size VMChainTree
	mov	ax, MSG_GO_GET_GROBJ_CLASS
	call	GrObjWriteEntryPointRelocation

	pop	bx				;ss:bx <- GTP
	mov	di, ss:[bx].GTP_curPos
	popdw	es:[di]

	call	VMUnlock
	mov	bp, bx				;ss:bp <- GTP

	;
	;  Store our identifier in the header
	;
	mov	cx, ss:[bp].GTP_id.high		;cx <- guardian block handle
	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_textSSP.VTSSSP_treeBlock
	mov	di, ss:[bp].GTP_curSlot
	push	bp
	call	VMLock
	mov	es, ax
	mov	es:[di].high, cx
	clr	es:[di].low
	call	VMDirty				;mark dirty so changes don't
						;get discarded
	call	VMUnlock
	pop	bp

	add	di, size dword			;point to the next slot
	mov	ss:[bp].GTP_curSlot, di

	.leave
	ret
GrObjVisGuardianCreateTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjVisGuardianReplaceWithTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjVisGuardian method for MSG_GO_REPLACE_WITH_TRANSFER

Called by:	

Pass:		*ds:si = GrObjVisGuardian object
		ds:di = GrObjVisGuardian instance

		ss:[bp] - GrObjTransferParams

Return:		ss:[bp].GTP_curPos - updated to after read data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianReplaceWithTransfer	method dynamic	GrObjVisGuardianClass,
					MSG_GO_REPLACE_WITH_TRANSFER
	uses	cx,dx
	.enter

	;
	;  call superclass, updating ss:[bp].GTP_curPos
	;
	mov	di, offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	;
	;  reading in the transfer data above has the sad effect of
	;  stomping the INVALID bit.  We need the invalid bit so that
	;  we actually send a NOTIFY_GEOMETRY_VALID to the poor ward who
	;  needs it desparately.
	;
	GrObjDeref	di, ds, si
	ornf	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID

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

	mov	di, es:[GOTBH_meta].VMCT_offset

	;
	;  save passed tree block
	;
	movdw	cxdx, es:[di]

	mov	ax, MSG_GOVG_CREATE_WARD_WITH_TRANSFER
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GO_NOTIFY_GROBJ_VALID
	call	ObjCallInstanceNoLock


	mov_tr	ax, bp				;save GTP ptr
	pop	bp				;bp <- mem handle
	call	VMUnlock
	mov_tr	bp, ax				;ss:[bp] <- GTP

	.leave
	ret
GrObjVisGuardianReplaceWithTransfer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjVisGuardianWriteInstanceToTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjVisGuardian method for MSG_GO_WRITE_INSTANCE_TO_TRANSFER

		Unrelocate and write the class of our ward

Called by:	

Pass:		*ds:si = GrObjVisGuardian object
		ds:di = GrObjVisGuardian instance

		ss:[bp] - GrObjTransferParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 19, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianWriteInstanceToTransfer	method dynamic	GrObjVisGuardianClass,
					MSG_GO_WRITE_INSTANCE_TO_TRANSFER
	uses	cx,dx
	.enter

	;
	;  call superclass, updating ss:[bp].GTP_curPos
	;
	mov	di, offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	;
	;	Write our subclass specific data
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_id.high
	add	ss:[bp].GTP_curSize, size GrObjEntryPointRelocation	;space for ward's class

	;
	;  The object is in a vm block, so lock it down
	;
	mov	di, bp				;ss:[di] <- GTP
	call	VMLock
	call	VMDirty

	;
	;  Get more space for our ward's class
	;
	mov	bx, bp				;bx <- mem handle
	mov	bp, di				;ss:[bp] <- GTP
	mov	ax, ss:[bp].GTP_curSize
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc
	mov	es, ax

	GrObjDeref	di,ds,si
	movdw	cxdx, ds:[di].GOVGI_class
	mov	di, ss:[bp].GTP_curPos
	mov	ax, MSG_GV_GET_GROBJ_VIS_CLASS
	call	GrObjWriteEntryPointRelocation

	mov_tr	ax, bp				;save GTP ptr
	mov	bp, bx				;bp <- mem handle
	call	VMUnlock
	mov_tr	bp, ax				;ss:[bp] <- GTP

	;
	;  Indicate that we wrote the class
	;
	add	ss:[bp].GTP_curPos, size GrObjEntryPointRelocation

	.leave
	ret
GrObjVisGuardianWriteInstanceToTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjVisGuardianReadInstanceFromTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjVisGuardian method for MSG_GO_READ_INSTANCE_FROM_TRANSFER

		Read and relocate the class of our ward

Called by:	

Pass:		*ds:si = GrObjVisGuardian object
		ds:di = GrObjVisGuardian instance

		ss:[bp] - GrObjTransferParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianReadInstanceFromTransfer	method dynamic	GrObjVisGuardianClass,
					MSG_GO_READ_INSTANCE_FROM_TRANSFER
	uses	cx,dx
	.enter

	;
	;  call superclass, updating ss:[bp].GTP_curPos
	;
	mov	di, offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	;
	;  The object is in a vm block, so lock it down
	;
	mov	di, bp				;ss:[di] <- GTP
	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_id.high
	call	VMLock
	push	bp				;save handle for unlocking
	mov	bp, di				;ss:[bp] <- GTP
	mov	es, ax
	mov	di, ss:[bp].GTP_curPos

	;
	;  Read and relocate the ward class
	;
	call	GrObjReadEntryPointRelocation

	;
	;  Save the relocated class in our instance data
	;
	GrObjDeref	si,ds,si			;ds:si <- instance
	movdw	ds:[si].GOVGI_class, cxdx

	;
	;  Unlock the block
	;
	mov_tr	ax, bp				;save GTP ptr
	pop	bp				;bp <- mem handle
	call	VMUnlock
	mov_tr	bp, ax				;ss:[bp] <- GTP

	;
	;  Indicate that we read the class
	;
	add	ss:[bp].GTP_curPos, size GrObjEntryPointRelocation

	.leave
	ret

GrObjVisGuardianReadInstanceFromTransfer	endm

GrObjTransferCode	ends
