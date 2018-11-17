COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj/GrObj
FILE:		grobjTransfer.asm

AUTHOR:		jon

METHODS:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	may 1992	initial version

DESCRIPTION:
	Transfer item creation stuff

	$Id: grobjTransfer.asm,v 1.1 97/04/04 18:07:21 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTransferCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjCreateTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_CREATE_TRANSFER

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		ss:bp - GrObjTransferParams

Return:		ss:[bp].GTP_curSlot - updated to the next slot in the tree
					specified by ss:[bp].GTP_textSSP.VTSSSP_treeBlock

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateTransfer	method dynamic	GrObjClass, MSG_GO_CREATE_TRANSFER
	uses	cx, dx, bp
	.enter

	;
	;  Check the GOL_COPY lock
	;

	test	ds:[di].GOI_locks, mask GOL_COPY
	jnz	done

	;
	;  Allocate a DB item big enough for our grobj
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	cx, size GrObjEntryPointRelocation
	mov	ss:[bp].GTP_curSize, cx
	mov	ax, DB_UNGROUPED
	call	DBAlloc				;ax:di <- group:item

	movdw	ss:[bp].GTP_id, axdi

	;
	;  Store the unrelocated class
	;
	call	DBLock				;*es:di <- item
	mov	di, es:[di]			;es:di <- item

	;
	;  Unreloc class
	;
	mov	ax,MSG_META_GET_CLASS
	call	ObjCallInstanceNoLockES
	mov	ax, MSG_GO_GET_GROBJ_CLASS
	call	GrObjWriteEntryPointRelocation

	call	DBUnlock

	;
	;  Indicate that we wrote the classes already
	;
	mov	ss:[bp].GTP_curPos, size GrObjEntryPointRelocation

	;
	;  Write the rest of the data out
	;	
	mov	ax, MSG_GO_WRITE_INSTANCE_TO_TRANSFER
	call	ObjCallInstanceNoLock

	mov	ax, ss:[bp].GTP_textSSP.VTSSSP_treeBlock
	mov	di, ss:[bp].GTP_curSlot

	;
	;  Store our identifier in the header
	;
	movdw	cxdx, ss:[bp].GTP_id

	push	bp
	call	VMLock
	mov	es, ax
	movdw	es:[di], cxdx
	call	VMDirty
	call	VMUnlock
	pop	bp

	add	di, size dword				;point to the next slot
	mov	ss:[bp].GTP_curSlot, di

done:
	.leave
	ret
GrObjCreateTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjIncCxIfCopyable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_INC_CX_IF_COPYABLE

Called by:	MSG_GO_INC_CX_IF_COPYABLE

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 30, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjIncCXIfCopyable	method dynamic	GrObjClass, MSG_GO_INC_CX_IF_COPYABLE
	.enter

	test	ds:[di].GOI_locks, mask GOL_COPY
	jnz	done

	inc	cx
	
done:
	.leave
	ret
GrObjIncCXIfCopyable	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDeselectIfCopyLockSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deselect the object if its copy lock is set.

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
			copy lock not set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDeselectIfCopyLockSet	method dynamic GrObjClass, 
				MSG_GO_DESELECT_IF_COPY_LOCK_SET
	.enter

	test	ds:[di].GOI_locks,mask GOL_COPY
	jnz	deselect
done:
	.leave
	ret

deselect:
	mov	ax,MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock
	jmp	done
GrObjDeselectIfCopyLockSet		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjWriteEntryPointRelocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This routine write an EntryPointRelocation and the
		entry number of the "leaf" grobj class into the
		passed buffer.

Pass:		es:di - empty buffer to write GrObjEntryPointRelocation
		cx:dx - class ptr

		ax - message to send to cx:dx class that will return
			leaf grobj class
			(eg., MSG_GO_GET_GROBJ_CLASS or MSG_GV_GET_GROBJ_CLASS)

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjWriteEntryPointRelocation	proc	far
	uses	ax, bx, cx, dx, di, ds, es
	.enter

	;
	;  Push the buffer ptr and the passed class onto the stack
	;  so we can call ObjUnRelocateEntryPoint later
	;
	pushdw	esdi				;push buffer ptr
	pushdw	cxdx				;push class on stack

	;
	;  Nudge the buffer ptr down by a word so that the grobj entry number
	;  getw written immediately after the (eventual) location of the full
	;  relocation.
	;
	;  We need to make sure that EPR_entryNumber is the last field
	;  in EntryPointRelocation for this to work.
	;
CheckHack <((offset EPR_entryNumber) + (size word)) eq (size EntryPointRelocation)>
	inc	di
	inc	di
	pushdw	esdi				;push buffer ptr

	;
	;	Get the "leaf" grobj class of the passed class
	;
;	clr	bx				;get core block of current proc
;	call	GeodeAccessCoreBlock
	movdw	esdi, cxdx			;es:di <- class
	call	ObjCallClassNoLock

	;
	;  Unrelocate the leaf grobj class. The pointer is offset by
	;  a word so that the entry point is written into the bottom of
	;  the passed buffer.
	;
	pushdw	cxdx				;push class on stack
	call	ObjUnRelocateEntryPoint		;fill in EntryPointRelocation

	;
	;  Unrelocate the passed class into the beginning of the passed buffer
	;
	call	ObjUnRelocateEntryPoint		;fill in EntryPointRelocation

	.leave
	ret
GrObjWriteEntryPointRelocation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjWriteInstanceToTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_WRITE_INSTANCE_TO_TRANSFER

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		ss:[bp] - GrObjTransferParams

Return:		ss:[bp].GTP_curPos updated to point past data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjWriteInstanceToTransfer	method dynamic	GrObjClass,
				MSG_GO_WRITE_INSTANCE_TO_TRANSFER
	uses	cx,dx
	.enter

	;
	;  Allocate some space to create our GrObjTransferDataDirectory and
	;  our GrObjDefiningData
	;
	sub	sp, size GrObjTransferDataDirectory + size GrObjDefiningData
	mov	di, sp
	segmov	es, ss

	;
	;  Start writing...
	;
	push	si				;save GrObj object chunk
	GrObjDeref	si,ds,si		;ds:si <- instance
	push	ds:[si].GOI_normalTransform	;save normal transform chunk

	;
	;  Store tile flags
	;
	clr	ax		;no var data for now...
	stosw

	;
	;  Store the rest of the instance data
	;

	mov	ax, ds:[si].GOI_attrFlags
	mov	es:[di].GODD_attrFlags, ax

	test	ax, mask GOAF_DONT_COPY_LOCKS
	mov	ax, 0
	jnz	storeLocks

	mov	ax, ds:[si].GOI_locks

storeLocks:
	mov	es:[di].GODD_locks, ax

	;
	;  unreloc area token
	;
	push	di					;save ptr
	mov	bx, ds:[si].GOI_areaAttrToken
	cmp	bx, CA_NULL_ELEMENT
	je	gotAreaToken
	mov_tr	ax, bx
	clr	bx, cx					;point at area array,
							;from doc -> xfer
	mov	di, ss:[bp].GTP_optBlock
	mov	dx, CA_NULL_ELEMENT
	call	StyleSheetCopyElement
	mov	ss:[bp].GTP_optBlock, di

gotAreaToken:
	push	bx					;save unreloc'd token

	;
	;  unreloc line token
	;
	mov	bx, ds:[si].GOI_lineAttrToken
	cmp	bx, CA_NULL_ELEMENT
	je	gotLineToken
	mov_tr	ax, bx
	mov	bx, 1					;point at line array
	clr	cx
	mov	di, ss:[bp].GTP_optBlock
	mov	dx, CA_NULL_ELEMENT
	call	StyleSheetCopyElement
	mov	ss:[bp].GTP_optBlock, di
gotLineToken:
	pop	ax					;ax <- unreloc'd token
	pop	di					;di <- dest ptr

	mov	es:[di].GODD_lineToken, bx
	mov	es:[di].GODD_areaToken, ax

	;
	;  Store the normal transform
	;

CheckEvenSize	ObjectTransform

	mov	cx, size ObjectTransform / 2
	pop	si				;si <- normal transform chunk
	mov	si, ds:[si]
	add	di, offset GODD_normalTransform
	push	di				;save dest transform
	rep movsw
	pop	di				;es:di <- dest transform

	;
	;	Adjust the object so that the selection center is the
	;	origin for the transfer item
	;
	subdwf	es:[di].OT_center.PDF_x, ss:[bp].GTP_selectionCenterDOCUMENT.PDF_x, cx
	subdwf	es:[di].OT_center.PDF_y, ss:[bp].GTP_selectionCenterDOCUMENT.PDF_y, cx

	;
	;  Deal with ATTR_GO_PARENT_DIMENSIONS_OFFSET/
	;  GOOF_HAS_UNBALANCED_PARENT_DIMENSIONS
	;
	pop	si				;*ds:si = GrObj
	mov	ax, ATTR_GO_PARENT_DIMENSIONS_OFFSET
	call	ObjVarFindData
	jnc	noGoofingOff
	;
	; if we have an X offset, expand parent width by that offset on
	; *each* side of center to account for either a positive or negative
	; offset (we don't want to change the object center point)
	;
	movwwf	dxax, ds:[bx].PF_x
	tstwwf	dxax				;sets Z flag only
	jz	noGoofx
	tst	dx				;check S flag
	jns	goofXOkay
	negwwf	dxax				;get abs
goofXOkay:
	shlwwf	dxax				;expand on each side of center
	addwwf	es:[di].OT_parentWidth, dxax
noGoofx:
	;
	; if we have an Y offset, expand parent height by that offset on
	; *each* side of center to account for either a positive or negative
	; offset (we don't want to change the object center point)
	;
	movwwf	dxax, ds:[bx].PF_y
	tstwwf	dxax				;sets Z flag only
	jz	noGoofy
	tst	dx				;check S flag
	jns	goofYOkay
	negwwf	dxax				;get abs
goofYOkay:
	shlwwf	dxax				;expand on each side of center
	addwwf	es:[di].OT_parentHeight, dxax
noGoofy:
noGoofingOff:

	;
	;  Write the structure to the item
	;
	mov	di, sp				;point di back to the beginning
						;of the structure

	mov	cx, size GrObjTransferDataDirectory + size GrObjDefiningData
	call	GrObjWriteDataToTransfer

	add	sp, cx

	.leave
	ret
GrObjWriteInstanceToTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjWriteDataToTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Writes a block of data into the current transfer item

Pass:		ss:[bp] - GrObjTransferParams
		es:[di] - structure to write out
		cx - size of structure in es:[di]

Return:		nothing

Destroyed:	nothing

Comments:	ss:bp.GTP_curSize and ss:bp.GTP_curPos are updated
		accordingly

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjWriteDataToTransfer	proc	far

	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

	;
	;  Set ds:si -> structure to write
	;
	segmov	ds, es
	mov	si, di

	;
	;  Figure out whether GTP_id points to a VM block
	;  or a DB item
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_id.high
	add	ss:[bp].GTP_curSize, cx
	push	cx				;save size
	tst	ss:[bp].GTP_id.low
	jnz	grObjInDB

	;
	;  The object is in a vm block, so lock it down
	;
	mov	di, bp				;ss:[di] <- GTP
	call	VMLock
	call	VMDirty
	mov	bx, bp				;bx <- mem handle

	;
	;  Get more space for our structure
	;
	mov	bp, di				;ss:[bp] <- GTP
	mov	ax, ss:[bp].GTP_curSize
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc
	mov	es, ax

	clr	di
	jmp	startWriting

grObjInDB:
	;
	;  GTP_id points to a DB item, so do a realloc
	;
	mov	di, ss:[bp].GTP_id.low
	mov	cx, ss:[bp].GTP_curSize
	call	DBReAlloc			;get room for our tokens
	call	DBLock				;*es:di <- item
	call	DBDirty
	mov	di, es:[di]			;es:di <- item
	clr	bx				;no mem handle

startWriting:
	;
	;  Spew the passed structure into the item
	;
	add	di, ss:[bp].GTP_curPos
	pop	cx				;cx <- size
	add	ss:[bp].GTP_curPos, cx

	rep movsb	;spunk!

	;
	;  Unlock whatever we locked
	;
	tst	bx
	jnz	unlockVM
	call	DBUnlock

done:
	.leave
	ret

unlockVM:
	mov	bp, bx				;bp <- mem handle
	call	VMUnlock
	jmp	done
GrObjWriteDataToTransfer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjReadInstanceFromTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_READ_INSTANCE_DATA_FROM_TRANSFER

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		ss:[bp] - GrObjTransferParams

Return:		ss:[bp].GTP_curPos - updated to after read data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjReadInstanceFromTransfer	method dynamic	GrObjClass,
				MSG_GO_READ_INSTANCE_FROM_TRANSFER
	uses	cx, bp
	.enter

	; Protect from stack overflow.
	mov	di, size GrObjTransferParams
	push	di				;popped by routine
	mov	di, 800				;number of bytes required
	call	GrObjBorrowStackSpaceWithData
	push	di				;save token for ReturnStack

	;
	;  Allocate some space to create our GrObjTransferDataDirectory and
	;  our GrObjDefiningData
	;
	mov	cx, size GrObjTransferDataDirectory + size GrObjDefiningData
	sub	sp, cx
	mov	di, sp
	segmov	es, ss

	call	GrObjReadDataFromTransfer

	;
	;  Now es:di should be pointing to a GrObjTransferDataDirectory
	;
	add	di, size GrObjTransferDataDirectory

	;
	;  Set attr flags (should be a message)
	;
	;  Also clear out the wrap type 'cause it'll cause hell in GeoWrite
	;  if you paste a bunch of GrObjs and it recalcs the path for each
	;  one...
	;
	GrObjDeref	bx,ds,si
	mov	ax, es:[di].GODD_attrFlags
	andnf	ax, not mask GOAF_WRAP
	mov	ds:[bx].GOI_attrFlags, ax

	;
	;  Set locks
	;
	mov	ax, es:[di].GODD_locks
	mov	ds:[bx].GOI_locks, ax

	;
	;  reloc line token
	;
	push	di				;save GODD
	mov	ax, es:[di].GODD_areaToken
	push	ax				;save area token

	mov	ax, es:[di].GODD_lineToken
	cmp	ax, CA_NULL_ELEMENT
	jne	relocateLineToken

	GrObjDeref	bx,ds,si
	mov	ds:[bx].GOI_lineAttrToken, ax
	jmp	checkAreaAttrToken
	
relocateLineToken:
	mov	bx, 1				;point at line array
	mov	cx, bx				;from xfer -> doc
	mov	di, ss:[bp].GTP_optBlock
	mov	dx, CA_NULL_ELEMENT
	call	StyleSheetCopyElement
	mov	ss:[bp].GTP_optBlock, di

	mov	cx, bx					;cx <- token
	mov	ax, MSG_GO_SET_GROBJ_LINE_TOKEN
	call	ObjCallInstanceNoLock

checkAreaAttrToken:
	;
	;  reloc area token
	;
	pop	ax				;ax <- unreloc'd area token
	cmp	ax, CA_NULL_ELEMENT
	jne	relocateAreaToken

	GrObjDeref	bx,ds,si
	mov	ds:[bx].GOI_areaAttrToken, ax
	jmp	doneWithTokens
	
relocateAreaToken:
	clr	bx				;area array offset
	mov	cx, 1
	mov	di, ss:[bp].GTP_optBlock
	mov	dx, CA_NULL_ELEMENT
	call	StyleSheetCopyElement
	mov	ss:[bp].GTP_optBlock, di

	mov	cx, bx					;cx <- token
	mov	ax, MSG_GO_SET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock

doneWithTokens:
	pop	di				;di <- GODD

	;
	;  create a normal transform for ourselves and fill it in
	;
	call	GrObjCreateNormalTransform
	add	di, offset GODD_normalTransform

	;
	;  Point ds:si at dest normal transform
	;
	GrObjDeref	si,ds,si
	push	si					;save obj ptr
	mov	si, ds:[si].GOI_normalTransform
	mov	si, ds:[si]

CheckEvenSize	ObjectTransform
	mov	cx, size ObjectTransform/2
	xchg	di, si
	segxchg	ds, es

	push	di
	rep movsw
	pop	di

	;
	;	Adjust the object so that the passed center is the
	;	origin for the transfer item
	;
	adddwf	es:[di].OT_center.PDF_x, ss:[bp].GTP_selectionCenterDOCUMENT.PDF_x, cx
	adddwf	es:[di].OT_center.PDF_y, ss:[bp].GTP_selectionCenterDOCUMENT.PDF_y, cx

	mov	di, si
	segxchg	ds, es

	;
	;  Clear our invalid bit
	;
	pop	si					;ds:si <- obj
	BitClr	ds:[si].GOI_optFlags, GOOF_GROBJ_INVALID

	add	sp, size GrObjTransferDataDirectory + size GrObjDefiningData

	pop	di
	call	GrObjReturnStackSpaceWithData

	.leave
	ret
GrObjReadInstanceFromTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjReadDataFromTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Reads a block of data into the current transfer item

Pass:		ss:[bp] - GrObjTransferParams
		es:[di] - structure to fill in
		cx - size of structure in es:[di]

Return:		nothing

Destroyed:	nothing

Comments:	ss:bp.GTP_curSize and ss:bp.GTP_curPos are updated
		accordingly

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjReadDataFromTransfer	proc	far

	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

	;
	;  Set ds:si -> structure to fill
	;
	segmov	ds, es
	mov	si, di

	;
	;  Figure out whether GTP_id points to a VM block
	;  or a DB item
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_id.high
	tst	ss:[bp].GTP_id.low
	jnz	grObjInDB

	mov	di, bp					;di <- data ptr
	call	VMLock
	mov	bx, bp					;bx <- mem handle
	mov	bp, di					;ss:bp <- GTP
	mov	es, ax
	clr	di
	jmp	lockedBlock

grObjInDB:
	;
	;  The object is in a DB item
	;
	mov	di, ss:[bp].GTP_id.low
	call	DBLock
	mov	di, es:[di]
	clr	bx					;no mem handle

lockedBlock:
	add	di, ss:[bp].GTP_curPos

	;
	;  Switch ds:si and es:di so that ds:si = source, es:di = dest
	;

	segxchg	ds, es
	xchg	di, si

	add	ss:[bp].GTP_curPos, cx

	;
	;  Spew!
	;

	rep movsb

	;
	;  Unlock our block
	;
	tst	bx
	jnz	unlockVM

	segxchg	ds, es
	call	DBUnlock

done:
	.leave
	ret

unlockVM:
	mov	bp, bx
	call	VMUnlock
	jmp	done
GrObjReadDataFromTransfer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjReplaceWithTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_REPLACE_WITH_TRANSFER

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		VM override file set

		ss:[bp] - GrObjTransferParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjReplaceWithTransfer	method dynamic	GrObjClass,
				MSG_GO_REPLACE_WITH_TRANSFER
	uses	bp
	.enter

	mov	ax, MSG_GO_READ_INSTANCE_FROM_TRANSFER
	call	ObjCallInstanceNoLock

	mov	bp, GOANT_PASTED
	call	GrObjOptNotifyAction

	.leave
	ret
GrObjReplaceWithTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjQuickTransferTakeMouseGrabIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the default handler.  Doesn't do anything.
		Always returns carry clear.

CALLED BY:	MSG_GO_QUICK_TRANSFER_TAKE_MOUSE_GRAB_IF_POSSIBLE
PASS:		*ds:si	= GrObjClass object
		ds:di	= GrObjClass instance data
		ds:bx	= GrObjClass object (same as *ds:si)
		es 	= segment of GrObjClass
		ax	= message #
		ss:bp	= LargeMouseData
		^lcx:dx	= optr to the owner of the Quick Transfer Object

RETURN:		
	carry:	SET	- Object was eligible and mouse was grabbed.
		CLEAR	- Object was not eligible, mouse grab was not changed.

DESTROYED:	ax can be destroyed
SIDE EFFECTS:	
	NOT TO BE CALLED WITH MF_STACK.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjQuickTransferTakeMouseGrabIfPossible	method dynamic GrObjClass, 
			    MSG_GO_QUICK_TRANSFER_TAKE_MOUSE_GRAB_IF_POSSIBLE
	.enter
	
	clc
	
	.leave
	ret
GrObjQuickTransferTakeMouseGrabIfPossible	endm


GrObjTransferCode	ends
