COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Database manager.
FILE:		Utils.asm

AUTHOR:		John Wedgwood, July 19, 1989

ROUTINES:
	Name			Description
	----			-----------
	DBItemBlockFind		Find an item block in a group that is large
				enough to satisfy a given request. (Allocating
				a new one if none are available).
	DBItemBlockAlloc	Allocate a new item block for a group.
	DBItemBlockFree		Free up an item block for a group.
	DBItemBlockLock		Lock an item block.
	DBItemBlockUnlock	Unlock an item block.
	DBItemBlockDirty	Dirty an item block.
	DBItemBlockAddRef	Add a reference to an item block.
	DBItemBlockDelRef	Delete a reference to an item block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	19-Jul-89	Initial revision

DESCRIPTION:
	This file contains routines which handle item-blocks. An item-block
	is a vmem-block which is used as a local-memory heap. Items are
	contained in the block and are represented as chunks on the heap.

	An item-block can contain items from only one group. A single group
	can have more than one item-block.

	Information for an item block is stored in the heap of structures
	in the group-block.

	When all references to an item-block go away, then the item block
	is removed and the structure associated with it is returned to the
	groups structure heap free-list.

USAGE:	Where possible, the following registers are used:
	bx = Database file handle.
	ds = Segment address of the group-block.
	es = Segment address of the item-block.
	si = Offset into group-block of DBItemBlockInfo structure for the
	     item-block.

	$Id: dbaseItemBlock.asm,v 1.1 97/04/05 01:17:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBaseCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemBlockFind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an item block in a given group that is large enough to
		satisfy a given request. (Allocates a new item block if no
		available item block is large enough).

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of the group block.
		cx = size of the request.
RETURN:		si = item-block that is large enough to satisfy the request.
		     (Offset to DBItemBlockInfo structure for the item block).
		ds = segment of same group block (may have moved).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach item-block in the groups list do
	    If the item-block has enough space for the request
	        break.
	End
	If no large enough item-block was found
	    Create a new item-block.
	Endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemBlockFind	proc	near 	uses ax, cx, dx, di
	.enter
	mov	si, ds:DBGH_itemBlocks		; ds:di <- ptr to block list.
	mov	dx, cx				; Place amount needed in dx
						;  to avoid thrashing by
						;  VMInfo
searchLoop:
	tst	si				; End of list?
	jz	alloc
	mov	ax, ds:[si].DBIBI_block		; Fetch item-block to check
	;
	; Fetch the size of the block
	;
	call	VMInfo				; ax,cx,di = func(bx,ax)
	;
	; Check to see if cx+dx < MAX_SIZE.
	; Make sure that cx+dx is not > 64K.
	;
	add	cx, dx				; cx <- new total size.
	jc	tryNext				; skip if size > 64K.
	cmp	cx, DB_ITEM_BLOCK_DESIRED_SIZE	; check against max-size.
	jb	endLoop				; quit if in range.
tryNext:					;
	mov	si, ds:[si].DBIBI_next		; si <- next item-block.
	jmp	searchLoop			; loop to check next one.
endLoop:					;
done:
	.leave
	ret
alloc:
	call	DBItemBlockAlloc		; Need to another block.
	jmp	done
DBItemBlockFind	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemBlockAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a new item block for a given group.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of the group block.
RETURN:		si = offset to DBItemBlockInfo structure of new item-block.
		ds = segment address of group block (may have moved).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Allocate a new vmem block.
	Lock it.
	Initialize it to be an lmem heap.
	Mark it as dirty.
	Allocate a structure for it.
	Save the vmem handle of the new item-block.
	Set the reference count of the item-block to zero.
	Return the offset to the allocated structure.

NOTES:	It is assumed that this routine will be immediately followed by
	some sort of allocation in the item-block. If this does not occur, then
	the item block will have a reference count of zero, but will still
	exist in the group block. This will cause a fatal-error when the error
	checking code is executed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemBlockAlloc	proc	near	uses ax, cx, dx, bp, di
	.enter
	call	DBBlockAlloc			; di <- available structure.
	mov	ax, ds:DBGH_itemBlocks		;
	mov	ds:[di].DBIBI_next, ax		; link into the list.
	mov	ds:DBGH_itemBlocks, di		;
	mov	ax, DB_ITEM_BLOCK_ID		; ax <- id number.
	mov	cx, DB_ITEM_BLOCK_INIT_SIZE	; cx <- initial size of block.
	call	VMAlloc				; Allocate a new vm-block.
	mov	ds:[di].DBIBI_block, ax		; save the vm-handle.
	mov	ds:[di].DBIBI_refCount, 0	; no references.
	;
	; Lock the block and initialize it as an lmem heap.
	;
	push	ds				; Save group segment.
	push	ax				; save the vm-handle.
	call	VMLock				; Lock the item-block.
	mov	ds, ax				; ds <- seg addr of block.
	;;; Set up parameters.
	push	bx				;
	mov	bx, bp				; bx <- memory handle.
	mov	ax, LMEM_TYPE_GENERAL		; ax <- type of block.
	mov	dx, size DBItemBlockHeader	; offset to handle table.
	mov	cx, 32				; # of handles to allocate.
	push	si, di
	mov	si, 256				; initial heap space.
	clr	di
	call	LMemInitHeap			;
	ornf	ds:[LMBH_flags], mask LMF_IS_VM
	pop	si, di
	;;; Initialize the block header.
	pop	bx				; Restore database file handle.
	pop	ax				; ax <- vm-handle.
	mov	ds:DBIBH_vmHandle, ax		; Save the vm-handle.
	mov	ds:DBIBH_infoStruct, di		; Save the offset to the info.
	pop	ds				; Restore group segment.
						;
	call	VMDirty				; Dirty the item-block.
	call	VMUnlock			; Unlock the item-block.
	mov	si, di				; Return offset to struct in si.
	.leave					;
	ret					;
DBItemBlockAlloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemBlockFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up an item block for a group.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of a locked group block.
		si = offset to the DBItemBlockInfo structure for the item-block
		     to free.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Free the entire item-block.
	Free the associated data structure.

NOTES:	It is assumed that no items are in the block. (All items should be
	free'd before this routine is called). If this is not the case then
	the error checking code will die.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemBlockFree	proc	near 	uses ax, di
	.enter				;
	;
	; Need to unlink this item block from the list of allocated item blocks
	;
	push	bx			;Save file handle	
	mov	di, ds:DBGH_itemBlocks	;
	cmp	di, si			; Check for first item block in list.
	je	DBIBF_firstInList	;
	;
	; Not first item in list, need to find it.
	;
DBIBF_loop:				;
	mov	bx, di			; bx <- previous.
	mov	di, ds:[di].DBIBI_next	; Check next structure.
	cmp	di, si			; Check for found it.
	jne	DBIBF_loop		; Loop it not.
	;
	; Found the structure, bx points to the previous one.
	;
	mov	ax, ds:[di].DBIBI_next	;
	mov	ds:[bx].DBIBI_next, ax	; Link it out...
	jmp	short DBIBF_done	; Quit
DBIBF_firstInList:			;
	;
	; Was first item block in list, just reset field in header.
	;
	mov	ax, ds:[di].DBIBI_next	;
	mov	ds:DBGH_itemBlocks, ax	;
DBIBF_done:				;
	pop	bx			;Restore file handle
	mov	ax, ds:[si].DBIBI_block	; ax <- vm-block handle.
	call	VMFree			; Free the vm-block.
	mov	di, si			; di <- offset to structure.
	call	DBBlockFree		; Free the structure.
	.leave				;
	ret				;
DBItemBlockFree	endp

DBaseCode	ends

kcode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemBlockLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a database item block.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of locked group block.
		si = offset into group block of the DBItemBlockInfo structure
		     for this item-block.
RETURN:		es = segment address of the item-block.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Look up the vm-block to lock.
	Lock it.
	Initialize the LMem stuff.
	Return segment address in es.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemBlockLock	proc	far	uses ax, bp, dx
	.enter
	mov	ax, ds:[si].DBIBI_block		; ax <- block
	call	VMLock				; ax <- seg, bp <- handle.
	mov	es, ax				;
						;
	mov	es:LMBH_handle, bp		; save the memory handle.
						;
EC <	call	DBValidateItemBlock		; 	>
EC <	call	DBCheckIBRefCount		;	>
	.leave
	ret					;
DBItemBlockLock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a previously locked database item.

CALLED BY:	External.

PASS:		es = Segment address of lmem-heap containing item.

RETURN:		nothing.

DESTROYED:	
	Non-EC: Nothing (flags preserved)

	EC:	Nothing (flags preserved), except, possibly for DS and ES:

		If segment error-checking is on, and either DS or ES
		is pointing to a block that has become unlocked,
		then that register will be set to NULL_SEGMENT upon
		return from this procedure. 


PSEUDO CODE/STRATEGY:
	Unlock the item-block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/21/89		Initial version
	AY	7/15/94		Moved from dbaseCode.asm and used FALL_THRU

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBUnlock	proc	far
	FALL_THRU	DBItemBlockUnlock	; Unlock item block.
DBUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemBlockUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a database item-block.

CALLED BY:	Internal.
PASS:		es = segment address of locked item block.
RETURN:		nothing
DESTROYED:	nothing (flags returned intact)

PSEUDO CODE/STRATEGY:
	Look up the associated vm-handle.
	Unlock the vm-block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemBlockUnlock	proc	far
	push	bp
	mov	bp, es:LMBH_handle	; bp <- memory handle.
	call	VMUnlock
	pop	bp
	ret
DBItemBlockUnlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemBlockDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark an item-block as dirty.

CALLED BY:	Internal.
PASS:		es = segment address of locked item block.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemBlockDirty	proc	far
	push	bp
	mov	bp, es:LMBH_handle	; bp <- memory handle.
	call	VMDirty
	pop	bp
	ret
DBItemBlockDirty	endp

kcode	ends

DBaseCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemBlockAddRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a reference to an item block.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of locked group block.
		es = segment address of locked item-info block.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemBlockAddRef	proc	near	uses si
	.enter
EC <	call	DBValidateItemBlock	;	>
EC <	call	DBValidateGroup		;	>
					;
	mov	si, es:DBIBH_infoStruct	;
	inc	ds:[si].DBIBI_refCount	;
	call	DBGroupDirty		; This is a change to the group block.
	call	DBItemBlockDirty	; We assume that adding a reference
EC <	call	DBCheckIBRefCount	;	>
	.leave				;  implies a change to the item block.
	ret				;
DBItemBlockAddRef	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemBlockDelRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a reference to an item block.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of locked group block.
		es = segment address of locked item-info block.
		si = offset to DBItemBlockInfo in group block.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemBlockDelRef	proc	near	uses	si, bp
	.enter
EC <	call	DBValidateItemBlock	;	>
EC <	call	DBValidateGroup		;	>
					;
	mov	si, es:[DBIBH_infoStruct]
	dec	ds:[si].DBIBI_refCount	; one fewer reference.
EC <	ERROR_S	BAD_ITEM_BLOCK_REFERENCE_COUNT			>
EC <	call	DBCheckIBRefCount	; doesn't dick with flags	>

	jne	DBIBDR_blockNotFreed	;
	;
	; This block is no longer used, free it up.
	;
	call	DBGroupDirty		; This is a change to the group block.
	mov	bp, es:[LMBH_handle]	; Unlock the thing first...
	call	VMUnlock
	call	DBItemBlockFree		; Bye bye.
	stc				; Signal: Block free'd
	jmp	done

DBIBDR_blockNotFreed:			;
	call	DBItemBlockDirty	; We assume that deleting a reference
					;  implies a change to the item block.
	clc				; Signal: Block not free'd
done:
	.leave
	ret				;
DBItemBlockDelRef	endp

DBaseCode	ends
