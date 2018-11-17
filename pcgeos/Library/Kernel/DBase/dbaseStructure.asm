COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Database Library -- Basic Structure Manipulations
FILE:		dbStructure.asm

AUTHOR:		John Wedgwood, Jul 24, 1989

METHODS:
	Name			Description
	----			-----------
	DBItemAlloc		Allocate a new item structure.
	DBItemFree		Free a item structure.
	DBBlockAlloc		Allocate a new item-block structure.
	DBBlockFree		Free an item-block structure.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	7/24/89		Initial revision

DESCRIPTION:
	This file contains routines to allocate and free the structures that
	are used in group blocks to store information about items and
	item-blocks.

	$Id: dbaseStructure.asm,v 1.1 97/04/05 01:17:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DBaseCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a DBItemInfo structure.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of a locked group block.
RETURN:		ds = segment address of same block (may have moved).
		di = offset to allocated structure.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If the free-list is empty then
	    Add new structures to the free-list.
	Endif
	Remove the first item from the free-list.
	Dirty the group block.

	If this group block is the current ungrouped group then
	    If the block size of this group is beyond the threshold then
	        Create a new current "ungrouped" group.
	    Endif
	Endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemAlloc	proc	near
	cmp	ds:DBGH_itemFreeList, 0		; check for a free list.
	jne	DBIA_hasList			;
	;
	; Create more structures.
	; New size = (# of strucs)*(size of struct) + (size of header).
	;
	push	ax, bx, cx, dx, es		;
	mov	ax, ds:DBGH_blockSize		; ax <- old block size.
	push	ax				; save old size.
	add	ax, DB_ITEM_STRUC_INC * size DBFreeItemStruct
	mov	bx, ds:DBGH_handle		; bx <- handle of group block.
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc			; Make bigger.
	mov	ds, ax				;
	add	ds:DBGH_blockSize, DB_ITEM_STRUC_INC * size DBFreeItemStruct
	pop	bx				; bx <- old size of block.
	;
	; Need to link all the new structures into the list.
	; bx = old size of block, which is the same as the pointer to the first
	;      new structure.
	;
	mov	cx, DB_ITEM_STRUC_INC		; cx <- # of new structures.
	mov	di, bx				; di <- ptr to start.
	mov	dx, bx				; save ptr to start.
DBIA_addNewFree:				;
	mov	bx, di				; bx <- offset to current one.
	add	di, size DBFreeItemStruct	; di <- offset to next one.
	mov	ds:[bx].DBFIS_next, di		; link to next.
	loop	DBIA_addNewFree			;
						;
	mov	ds:[bx].DBFIS_next, 0		; no next one if on last.
	mov	ds:DBGH_itemFreeList, dx	; set start of list.
	pop	ax, bx, cx, dx, es		;
DBIA_hasList:					;
	mov	di, ds:DBGH_itemFreeList	; di <- 1st free list element.
						;
	push	ax				;
	mov	ax, ds:[di].DBFIS_next		; Link around the item.
	mov	ds:DBGH_itemFreeList, ax	;
	pop	ax				;
						;
	test	ds:[DBGH_flags], mask GF_NEW_UNGROUP
	jz	dirtyGroup			; => DBGH_numItems might not
						;  be there
	inc	ds:[DBGH_numItems]
dirtyGroup:
	call	DBGroupDirty

	;
	; Need to check for this being the current ungrouped group and handle
	; the case of the ungrouped group growing beyond the threshold.
	;
	cmp	ds:DBGH_blockSize, DB_GROUP_BLOCK_DESIRED_SIZE
	jb	DBIA_done			;
	;
	; Block is larger than the threshold, but it may not be the current
	; ungrouped group.
	;
	test	ds:DBGH_flags, mask GF_NEW_UNGROUP
	jz	DBIA_done
	
	;
	; Well, the block looks like it's too full, but in reality it
	; might not be. If there are items in the free-list, then we
	; can just reuse those items, and the block won't grow at
	; all. We check the free-list, and if it's not empty, we 
	; skip the remaining code because we *can* continue to use
	; this group block.
	;
	tst	ds:DBGH_itemFreeList
	jnz	DBIA_done

	;
	; Block is the ungroup, and is too large, so mark it as full and set
	; the file as no longer having an ungrouped group.
	;
	test	ds:[DBGH_flags], mask GF_UNGROUP_FULL
	jnz	DBIA_done			; we were blocked waiting for
						;  someone else to release the
						;  ungroup when they decided
						;  the ungroup was full, so
						;  they've already done this
						;  work...

	ornf	ds:[DBGH_flags], mask GF_UNGROUP_FULL
	push	ds
	call	DBLockDBMap
	mov	ds:[DBMB_newUngrouped], 0
	call	DBDirtyDBMap
	call	DBUnlockDBMap
	pop	ds
DBIA_done:					;
	ret					;
DBItemAlloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBItemFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a DBItemInfo structure.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of a locked group block.
		di = offset to structure to free.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Add the structure to the free list.
	Dirty the group block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBItemFree	proc	near
	push	ax				;
	mov	ax, ds:DBGH_itemFreeList	;
	mov	ds:[di].DBFIS_next, ax		; link in to free list.
	mov	ds:DBGH_itemFreeList, di	; set to start of list.
						;
	test	ds:[DBGH_flags], mask GF_NEW_UNGROUP
	jz	doDirty				; => DBGH_numItems might not
						;  be there, and don't need to
						;  do ungroup-full check
	dec	ds:[DBGH_numItems]

	;
	; If the block is a member of the ungrouped set and was full, see if
	; it's still full. We do all this here, rather than in DBItemFree,
	; to avoid deadlocking when we have to go back up and get the header
	; block to set the VMBF_UNGROUPED_AVAIL flag for the block. There's
	; still some potential for deadlock if this thread still has an
	; item block locked, of course, but I can't think of a way to cope
	; with that...
	; 
	test	ds:[DBGH_flags], mask GF_UNGROUP_FULL
	jz	doDirty
	cmp	ds:[DBGH_numItems], DB_UNGROUP_LOW_WATER_MARK
	ja	doDirty

	;
	; ungroup block now available for allocation again. Mark it as such
	; in the VMHeader
	;
	andnf	ds:[DBGH_flags], not mask GF_UNGROUP_FULL

	push	bx
	mov	ax, ds:[DBGH_vmemHandle]
	mov	bx, ds:[DBGH_handle]
	call	VMMarkUngroupAvail
	pop	bx

doDirty:
	call	DBGroupDirty

	;
	; This would be a good place to check to see if there are free
	; structures at the end of the group block. If there are some, then
	; we can remove them from the free list and resize the group block
	; smaller. This is the only chance we have to make the group block
	; smaller.
	;
	pop	ax				;
	ret				;
DBItemFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBBlockAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a DBItemBlockInfo structure.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of a locked group block.
RETURN:		ds = segment address of same block (may have moved).
		di = offset to allocated structure.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If the free-list is empty then
	    Add new structures to the free-list.
	Endif
	Remove the first item from the free-list.
	Dirty the group block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBBlockAlloc	proc	near
	cmp	ds:DBGH_blockFreeList, 0	; check for a free list.
	jne	DBBA_hasList			;
	;
	; Create more structures.
	;
	push	bx, cx, dx, es			;
	mov	ax, ds:DBGH_blockSize		; ax <- old block size.
	push	ax				; save old size.
	add	ax, DB_BLOCK_STRUC_INC * size DBFreeBlockStruct
	mov	bx, ds:DBGH_handle		; bx <- handle of group block.
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc			; Make bigger.
	mov	ds, ax				;
	add	ds:DBGH_blockSize, DB_BLOCK_STRUC_INC * size DBFreeBlockStruct
	pop	bx				; bx <- old size of block.
	;
	; Need to link all the new structures into the list.
	; bx = old size of block, which is the same as the pointer to the first
	;      new structure.
	;
	mov	cx, DB_BLOCK_STRUC_INC		; cx <- # of new structures.
	mov	di, bx				; di <- ptr to start.
	mov	dx, bx				; save ptr to start.
DBBA_addNewFree:				;
	mov	bx, di				; bx <- offset to current one.
	add	di, size DBFreeBlockStruct	; di <- offset to next one.
	mov	ds:[bx].DBFBS_next, di		; link to next.
	loop	DBBA_addNewFree			;
						;
	mov	ds:[bx].DBFBS_next, 0		; no next one if on last.
	mov	ds:DBGH_blockFreeList, dx	; set start of list.
	pop	bx, cx, dx, es			;
DBBA_hasList:					;
	mov	di, ds:DBGH_blockFreeList	; di <- 1st free list element.
						;
	push	ax				;
	mov	ax, ds:[di].DBFBS_next		; Link around the item.
	mov	ds:DBGH_blockFreeList, ax	;
	pop	ax				;
						;
	push	bp				;
	mov	bp, ds:DBGH_handle		; bp <- memory handle.
	call	VMDirty				; Mark the group as dirty.
	pop	bp				;
	ret					;
DBBlockAlloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBBlockFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a DBItemBlockInfo structure.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of a locked group block.
		di = offset to structure to free.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Add the structure to the free list.
	Dirty the group block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBBlockFree	proc	near
	uses	ax, bp				;
	.enter					;
	;
	; First we add the block to the free list.
	;
	mov	ax, ds:DBGH_blockFreeList	;
	mov	ds:[di].DBFBS_next, ax		; link in to free list.
	mov	ds:DBGH_blockFreeList, di	; set to start of list.
	;
	; Now mark the group as dirty, so it will be flushed to disk rather
	; than discarded.
	;
	mov	bp, ds:DBGH_handle		; bp <- memory handle.
	call	VMDirty				; Mark the group as dirty.
	;
	; This would be a good place to check to see if there are free
	; structures at the end of the group block. If there are some, then
	; we can remove them from the free list and resize the group block
	; smaller. This is the only chance we have to make the group block
	; smaller.
	;
	.leave					;
	ret					;
DBBlockFree	endp

DBaseCode	ends
