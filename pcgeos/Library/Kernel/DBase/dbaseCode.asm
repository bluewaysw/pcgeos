COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Database manager.
FILE:		dbCode.asm

AUTHOR:		John Wedgwood, Jun 21, 1989

ROUTINES:
	Name			Description
	----			-----------
	VMOpen			Open or create a database file.
	VMUpdate		Update a database file.
	VMSave			Commit the current version of the file,
				deleting the backup copy
	DBRevert		Return a file to its backup state
	DBSaveAs		Save current version to a different file,
				returning the current to its backup state
	VMClose			Update and close a database file.
	DBLock			Lock a database item for exclusive access.
	DBUnlock		Unlock a locked database item.
	DBDirty			Mark an item as dirty (needing to be written).
    **	DBAlloc			Create a new database item.
    **	DBReAlloc		Resize an existing database item.
	DBFree			Remove an item from the database.
    **	DBInsertAt		Insert bytes in the middle of an item.
	DBDeleteAt		Delete bytes from the middle of an item.
	DBGroupAlloc		Create a new database group.
	DBGroupFree		Remove all items in a group.
	DBSetMap		Define an item as holding map information.
	DBGetMap		Get the database item that is the map.
	DBLockMap		Lock the map item.
	DBCopyDBItem		Copy a DB item
	DBInfo			Retrieve info about a DB item
(** see NOTES).

NOTES:
	Calls to the following routines deserve special attention:
		DBAlloc(), DBReAlloc(), DBInsertAt().
	If ds or es contains the segment address of an item-block when these
	routines are called, then they will be updated to refer to the same
	item block before the routines return.

	Because of this you should not push and pop es or ds around calls to
	these routines. (There is little point anyway, since they don't change
	ds or es if they do not point at an item-block).

	All DBase calls may be passed 0 for the VM file handle, if the
	VM override is set. Since the text library is the only beast
	that uses the override, this fact is *not* documented for each
	routine, to avoid ISV confusion.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	6/21/89		Initial revision
	Don	8/15/92		Removed the group & vm file override

DESCRIPTION:
	Database manager code.

	$Id: dbaseCode.asm,v 1.1 97/04/05 01:17:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VMOpenCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCheckData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that all blocks in the file with the passed ID
		actually have data associated with them.

CALLED BY:	VMOpen
PASS:		di	= VM uid of blocks to check
		bx	= file just opened
		bp	= minimum block size
RETURN:		carry set if one or more blocks are bad
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBCheckData	proc	near
		.enter

		clr	cx		; start at first block
findLoop:
		mov	ax, di
		call	VMFind
		cmc
		jnc	done
	;
	; Note that we do not push/pop di since VMInfo returns it as the
	; user ID for the block, which is what it already is
	;
		push	ax
		call	VMInfo
		cmp	cx, bp		; Block too small?
		pop	cx		; cx = vm block handle (so that we can
					; find the next one)
		jnc	findLoop

done:
		.leave
		ret
DBCheckData	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DBCheckDBFile

DESCRIPTION:	Ensure that DB data is sane

CALLED BY:	VMOpen

PASS:
	bx - file

RETURN:
	carry - set if not sane

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@


MAP_BLOCK_PARA_SIZE	equ	(((size DBMapBlock)+15)/16)

DBCheckDBFile	proc	near	uses ax, cx, di, bp, ds
	.enter

	;
	; Now make sure the file is reasonable. This means:
	;	- the map block actually has data associated with it
	;	- the DBMB_vmemHandle matches
	;	- all group blocks and item blocks have file-data associated
	;	  with them.
	;
	call	VMGetDBMap
	tst	ax
	jz	done
	push	ax
	call	VMInfo			; Fetch size of map block
	pop	ax
	jc	done
	cmp	cx, MAP_BLOCK_PARA_SIZE*16
	stc
	jne	done
	mov	di, ax		; preserve VM handle for comparison

	call	VMLock			; Lock down the map block
	mov	ds, ax			;  and make sure it's ok
	cmp	di, ds:[DBMB_vmemHandle]
	call	VMUnlock
	stc
	jne	done
	
	mov	di, DB_GROUP_ID		; Check all group blocks
	mov	bp, size DBGroupHeader
	call	DBCheckData
	jc	done
	
	mov	di, DB_ITEM_BLOCK_ID	; Check all item blocks
	mov	bp, size DBItemBlockHeader
	call	DBCheckData
done:
	.leave
	ret

DBCheckDBFile	endp

VMOpenCode ends

kcode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBLockMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the map-item for the database file.
		This is provided as a utility routine. It is slightly faster
		than calling DBGetMap() followed by a call to DBLock().
		(But not a lot).

CALLED BY:	External.
PASS:		bx = Database file handle.
RETURN:		es:*di = pointer to the map item.
		di = 0 if there is no map.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBLockMap	proc	far	uses	ax, ds
	.enter
EC <	call	ECVMCheckVMFile		; Check bx param.	>
					;
	call	DBLockDBMap		; ds <- byte map segment address.
	mov	ax, ds:DBMB_mapGroup	;
	mov	di, ds:DBMB_mapItem	;
	call	DBUnlockDBMap		; release the map block.
	;
	; bx = Database file handle.
	; ax = group, di = item.
	;
	tst	di			; quit if no map block.
	jz	DBLM_noMap		;
	call	DBLockGroupValid	;
DBLM_noMap:				;
	.leave
	ret				;
DBLockMap	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBLock

C DECLARATION:	extern void *
			_pascal DBLockUngrouped(DBFileHandle file,
						DBGroupAndItem id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBLOCKUNGROUPED	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = file, ax = grp, cx = it

	push	di, es
	mov	di, cx
	call	DBLock
	mov	dx, es
	mov	ax, es:[di]
	pop	di, es
	ret

DBLOCKUNGROUPED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBUnlock

C DECLARATION:	extern void
			_far _pascal DBUnlock(void _far *ptr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBUNLOCK	proc	far
	C_GetOneDWordArg	ax, bx,  cx,dx	;ax = seg, bx = off

EC <	mov	cx, es							>
EC <	cmp	ax, cx							>
EC <	jnz	different						>
EC <	call	DBUnlock						>
EC <	ret								>
EC <different:								>

	push	es
	mov	es, ax
	call	DBUnlock
	pop	es
	ret

DBUNLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBDirty

C DECLARATION:	extern void
			_far _pascal DBDirty(void _far *ptr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBDIRTY	proc	far
	C_GetOneDWordArg	ax, bx,  cx,dx	;ax = seg, bx = off

	push	es
	mov	es, ax
	call	DBDirty
	pop	es
	ret

DBDIRTY	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a database item for exclusive access.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group	(VM-handle to group block).
		di = item	(Offset to ItemInfo in group-block).
RETURN:		es:*di = pointer to database item.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Lock the group.
	Look up the item-block and chunk handle.
	Lock the item-block.
	Return the segment of the item-block and the chunk handle.
	Unlock the group.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBLock	proc	far
	push	ax				;
	call	DBLockGroupValid		; Do the lock...
	pop	ax				;
	ret					;
DBLock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBLockGroupValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a block, the group is valid and should not be nuked
		by the override.
CALLED BY:	

PASS:		same as DBLock.
RETURN:		same as DBLock.
DESTROYED:	nothing (I hope)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBLockGroupValid	proc	far
EC <	call	ECVMCheckVMFile			; check bx parameter.	>
EC <	call	DBCheckIsGroup			; check ax parameter.	>
EC <	call	DBCheckIsItem			; check di parameter.	>
						;
	push	ds, si				;
	call	DBGroupLock			; ds <- seg addr of group.
	mov	si, ds:[di].DBII_block		; si <- item-block reference.
	mov	di, ds:[di].DBII_chunk		; di <- chunk.
	push	ax, bp
	mov	ax, ds:[si].DBIBI_block
	call	DBGroupUnlock			; release the group before going
						;  for the item block, to lessen
						;  the chances of deadlock
	call	VMLock
	mov	es, ax
EC <	call	DBValidateItemBlock					>
   	pop	ax, bp
	pop	ds, si				;
						;
EC <	push	ds, si				;	>
EC <	segmov	ds, es				;	>
EC <	mov	si, di				;	>
EC <	call	ECLMemValidateHeapFar		;	>
EC <	call	ECLMemValidateHandle		;	>
EC <	pop	ds, si				;	>
	ret
DBLockGroupValid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark an item as needing to be written to disk.

CALLED BY:	External.
PASS:		es = segment address of the block containing the
		     dbase item.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Dirty the item-block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBDirty	proc	far
	call	DBItemBlockDirty	; Dirty the item-block.
	ret				;
DBDirty	endp

kcode	ends

DBaseCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a new database item in a given group.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group	(VM-handle to group block).
		     If ax == DB_UNGROUPED, then the item is allocated
		     "ungrouped". That is to say, a group is assigned to
		     the item. The assigned group is returned to the caller
		     and needs to be used in future references to the item.
		cx = size.
	Optional:
		ds = segment address of an item-block.
		es = segment address of an item-block.
RETURN:		di = item	(Offset to DBItemInfo in group block).
		ax = group 
	Optional:
		ds = segment address of same item-block that was passed in.
		es = segment address of same item-block that was passed in.
		     (unchanged if it was not pointing at an item block).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Lock the group block.
	Allocate a block/chunk pair in the group-block.
	Find an item-block that is large enough to hold the new item.
	Set the item-block in the block/chunk pair.
	Lock the item-block.
	Allocate the new item using LMemAlloc().
	Set the chunk in the block/chunk pair.
	Dirty the item-block.
	Return the offset to the ItemInfo structure in the group-block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBAlloc	proc	far
	push	cx, si			; Must push these three in this order.
EC <	call	DBEnsureNotExplicitUngrouped	; checks bx & ax, too	>
	cmp	ax, DB_UNGROUPED	; Check for ungrouped.
	jne	hasGroup		;
	call	DBGroupGetUngrouped	; ax <- ungrouped group to alloc in.
EC <	call	DBCheckIsGroup		; Check ax parameter.	>
hasGroup:				;
	push	ax			;
					;
	push	ds, es			; Save segment registers for fixup.
	call	DBGroupLock		; ds <- segment addr of group block.
	call	DBItemAlloc		; ds:di <- ptr to block/chunk pair.
	call	DBItemBlockFind		; si <- reference to item-block.
	mov	ds:[di].DBII_block, si	; save item-block reference.
	call	DBItemBlockLock		; es <- seg addr of item block.
	push	ds			; save seg addr of group block.
	segmov	ds, es			; ds <- seg of item-block.
	mov	si, ds			; save old seg addr of item-block.
	call	LMemAlloc		; ax <- chunk handle.
	segmov	es, ds			; segment may have moved.
	pop	ds			; restore seg addr of group block.
	mov	ds:[di].DBII_chunk, ax	; save the chunk handle.
	mov	ax, es			; save new seg addr of item-block.
	call	DBItemBlockAddRef	; mark item-block as dirty.
	call	DBItemBlockUnlock	; Unlock the item-block.

	call	DBGroupUnlock		; Unlock the group block.
	pop	ds, es			;
	;
	; ds, es = passed segments.
	; si     = old segment of changed item block.
	; ax	 = new segment of changed item block.
	;
	cmp	ax, si			; if no change then
	je	done			;
	mov	cx, ds			;
	cmp	cx, si			; if ds == old seg addr then
	jne	noDSFixup		;
	mov	ds, ax			;    fixup ds
noDSFixup:				;
	mov	cx, es			;
	cmp	cx, si			; if es == old seg addr then
	jne	noESFixup		;
	mov	es, ax			;    fixup es
noESFixup:				;
					;
done:					;
	pop	ax			; Must pop these three in this
	pop	cx, si			; order.
	ret				;
DBAlloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBReAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the size of an existing database item.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group	(VM-handle to group block).
		di = item	(Offset to DBItemInfo in group block).
		cx = new size.
	Optional:
		ds = segment address of an item-block.
		es = segment address of an item-block.
RETURN:	Optional:
		ds = segment address of same item-block that was passed in.
		es = segment address of same item-block that was passed in.
		     (unchanged if it was not pointing at an item block).
DESTROYED:	nothing.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBReAlloc	proc	far
	uses	ax, si			; Nukes ax, si
	.enter				;
	call	DBReAllocInternal	;
	;
	; Everything we wanted done is now done, except that ax and si
	; have been nuked...
	;
	.leave				; Restore ax, si
	ret				;
DBReAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBReAllocInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as DBReAlloc() but returns some information that
		might be useful to other DB routines.

CALLED BY:	DBInsertAt
PASS:		bx = Database file handle.
		ax = group	(VM-handle to group block).
		di = item	(Offset to DBItemInfo in group block).
		cx = new size.
	Optional:
		ds = segment address of an item-block.
		es = segment address of an item-block.

RETURN:		si = old segment address of changed item block.
		ax = new segment address of changed item block.
    Optional:
		ds = segment address of same item-block that was passed in.
		es = segment address of same item-block that was passed in.
		     (unchanged if it was not pointing at an item block).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBReAllocInternal	proc	near
	uses	bx, cx, dx, di, bp	; Returns ax, si
	.enter				; Save stuff.
EC <	call	ECVMCheckVMFile		; Check bx parameter.	>
EC <	call	DBCheckIsGroup		; Check ax parameter.	>
EC <	call	DBCheckIsItem		; Check di parameter.	>
					;
	push	ds, es			;
	call	DBGroupLock		; ds <- seg addr of group.
	mov	si, ds:[di].DBII_block	; si <- item-block.
	mov	ax, ds:[di].DBII_chunk	; ax <- chunk.
	call	DBItemBlockLock		; es <- seg addr of item-block.
	;
	; Check for case of item getting smaller. In this case, just re-alloc
	; in the same block.
	;
	xchg	bx, ax			;
	ChunkSizeHandle	es, bx, dx	; dx <- old size.
	xchg	bx, ax			;
	cmp	cx, dx			; check for smaller new size.
	jbe	DBRA_sameBlock		; alloc in same block if so.
	;
	; Check for the case where this is the only item in the block.
	; When this happens we just re-alloc it in the same block, there is
	; no need to move it.
	;
	cmp	ds:[si].DBIBI_refCount, 1
	je	DBRA_sameBlock		;
	;
	; The item is not the only one in the block. Check to see if the new
	; item size will keep the block under the threshold.
	;
	mov	bp, cx			;
	sub	bp, dx			; bp <- size difference.
	add	bp, es:LMBH_blockSize	; bp <- new total block size.
	cmp	bp, DB_ITEM_BLOCK_DESIRED_SIZE
	jbe	DBRA_sameBlock		; Alloc in same block if under max size

	call	DBItemBlockFind		; si <- reference to large enough block
	mov	ds:[di].DBII_block, si	; save new block.
					;
	;
	; The item must be re-alloc'd in a new block.
	; *es:ax = pointer to old data.
	; ds = segment address of group block.
	; ds:si = pointer to ItemBlockInfo for the new item-block.
	; ds:di = ponter to ItemInfo for the item.
	; cx    = new size for item.
	; dx    = old size for item.
	;
	; We need to allocate space for the item in the new item-block.
	; We need to copy the data.
	; We need to save the new chunk into the ItemInfo structure for the
	;   item.
	;
	push	es
	push	cx, ds, di		;
	push	es, ax			; Save old data item-block segment
					;   and chunk handle in old block.
	call	DBItemBlockLock		; es = seg addr of new block
	segmov	ds, es, di		; ds <- es.
					; di <- es. (save old seg addr).
	call	LMemAlloc		; ax <- new item chunk handle.
	pop	ds, si			; ds <- old data item-block segment.
					; si <- chunk handle of old item.
					;
	push	di, ax			; save old seg addr, new chunk handle.
	xchg	di, ax			; es:di <- ptr to destination. (1-b i)
	mov	di, es:[di]		;
	mov	ax, si			; *ds:ax <- reference to old data.
	mov	si, ds:[si]		; ds:si <- ptr to old data.
					;
	mov	cx, dx			; cx <- old size.
	rep	movsb			; move the data.
	call	LMemFree		; nuke old data (ax = chunk handle).
	pop	si, ax			; Restore seg addr & new chunk handle.
	pop	cx, ds, di		; Restore group segment and other things
	call	DBItemBlockAddRef	; Note another reference to the block
	call	DBItemBlockUnlock	; Unlock new item block (needs es).
					;
	mov	ds:[di].DBII_chunk, ax	; save new chunk handle.
	mov	ax, es			; save new seg address of item block.
	pop	es			; es <- segment of old item block
	call	DBItemBlockDelRef	; Delete reference to old block
	;
	; We don't care about the flag returned from DBItemBlockDelRef()
	; (carry set if item block is no longer used, and was deleted) because
	; the only way that we can get here is if the item is NOT the only one
	; in the block, so deleting the reference will never cause the item
	; block to be free'd..
	;
	;
	; Before quitting, must have:
	;	es = segment of item-block that still needs unlocking
	;	si = old segment address of item-block that changed.
	;	ax = new segment address of item-block that changed.
	;	ds = segment of group block
	;
	jmp	short DBRA_done		;
DBRA_sameBlock:				;
	;
	; Re-alloc the item in the block in which it currently resides.
	;
	mov	dx, ds			; save seg addr of group.
	mov	si, es			; save old seg addr of item-block.
	mov	ds, si			; *ds:ax <- ptr to data.
	call	LMemReAlloc		; Just re-allocate in same block.
	mov	ax, ds			; save new seg addr of item block.
	mov	ds, dx			; restore seg addr of group.
DBRA_done:				;
	;	es = segment of item-block that still needs unlocking
	call	DBItemBlockDirty	; Dirty the item-block.
	call	DBItemBlockUnlock	; Unlock item-block. (needs es).
	call	DBGroupUnlock		; Unlock group block. (needs ds).
	pop	ds, es			;
	;
	; ds, es = segments to fixup.
	; si	 = old segment address of changed item block.
	; ax	 = new segment address of changed item block.
	;
	cmp	ax, si			; if no change then
	je	DBRA_quit		;
	mov	dx, ds			;
	cmp	dx, si			; if ds == old seg addr then
	jne	DBRA_noDSFixup		;
	mov	ds, ax			;    fixup ds
DBRA_noDSFixup:				;
	mov	dx, es			;
	cmp	dx, si			; if es == old seg addr then
	jne	DBRA_noESFixup		;
	mov	es, ax			;    fixup es
DBRA_noESFixup:				;
					;
DBRA_quit:				;
	.leave				;
	ret				;
DBReAllocInternal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an item from the database.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group	(VM-handle to group block).
		di = item	(Offset to DBItemInfo in group block).
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Lock the group block.
	Lock the item-block.
	Free the item via a call to LMemFree().
	Unlock the item-block.

	Free the associated data-structure via a call to DBItemFree().
	Unlock the item-block.
	Remove a reference to the item-block via a call to DBItemBlockDelRef().
	Unlock the group block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBFree	proc	far 	uses ax, si, ds, es
	.enter
EC <	call	ECVMCheckVMFile			; Check bx parameter.	>
EC <	call	DBCheckIsGroup			; Check ax parameter.	>
EC <	call	DBCheckIsItem			; Check di parameter.	>
						;
	call	DBGroupLock			; ds <- seg addr of group block
	mov	si, ds:[di].DBII_block		;
	call	DBItemBlockLock			; es <- seg addr of item-block.
	mov	ax, ds:[di].DBII_chunk		; ax <- chunk.
	push	ds				;
	segmov	ds, es				; ds:*ax <- chunk
	call	LMemFree			; Free the item.
	segmov	es, ds				; segment may have changed.
	pop	ds				;
						;
	call	DBItemFree			; free structure at ds:di
	call	DBItemBlockDelRef		; One less thing in the block.
	;
	; Need to check the return value from DBItemBlockDelRef(). If the
	; carry is set, then the item block was deleted, so unlocking it is
	; going to cause an error.
	;
	jc	DBF_noMoreItemBlock		;
	call	DBItemBlockUnlock		; Unlock item-block.

DBF_noMoreItemBlock:				;
	call	DBGroupUnlock			; Unlock the group.
	.leave					;
	ret					;
DBFree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBInsertAt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert space in the middle of a database item.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group.	(VM block handle).
		di = item.	(Offset into group block).
		dx = offset to insert at.
		cx = # of bytes to insert.
	Optional:
		ds = segment address of an item-block.
		es = segment address of an item-block.
RETURN:	Optional:
		ds = segment address of same item-block that was passed in.
		es = segment address of same item-block that was passed in.
		     (unchanged if it was not pointing at an item block).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBInsertAt	proc	far	uses ax, bx, cx, dx, di, si, bp
oldSize	local	word
dbGroup	local	word
	.enter
	push	ds, es				; Save registers to fix up.
EC <	call	ECVMCheckVMFile			; check bx parameter.	>
EC <	call	DBCheckIsGroup			; check ax parameter.	>
EC <	call	DBCheckIsItem			; check di parameter.	>
						;
	push	cx				;
						;
	mov	dbGroup, ax			; Save the group.
						;
	push	ds, di, si			;
	call	DBGroupLock			; ds <- seg addr of group.
	mov	si, ds:[di].DBII_block		; si <- item block reference.
	mov	di, ds:[di].DBII_chunk		; di <- chunk handle.
	call	DBItemBlockLock			; es <- seg addr of item block.
	ChunkSizeHandle	es, di, ax		;
	mov	oldSize, ax			; Save the size.
						;
	mov	ax, dbGroup			; ax <- group (again).
	add	cx, oldSize			; cx <- new item size.
	call	DBItemBlockUnlock		; Unlock item-block  (es).
	call	DBGroupUnlock			; Unlock group-block (ds).
	pop	ds, di, si			;
	;
	; cx = new chunk size.
	; oldSize = old chunk size.
	;
	call	DBReAllocInternal		; Put me in a block.
	;
	; si = old segment address of changed item block.
	; ax = new segment address of changed item block.
	;
	pop	cx				; cx <- # of bytes to insert.
	push	si, ax				; Save old segment addr and
						;   new segment addr.
	mov	ax, dbGroup			; ax <- group again...
	;
	; Need:
	;	bx = db file handle.
	;	ax = group block (vm handle).
	;	di = item.
	;
	call	DBLockGroupValid		; es:*di <- ptr to item.
	;
	; bx = Database file handle.
	; es:*di = pointer to item to insert in.
	; dx = offset to insert at.
	; cx = # of bytes to insert.
	; oldSize = old size of chunk.
	;
	push	di				;
	segmov	ds, es				; ds, es = lmem heap segment.
	mov	di, ds:[di]			; ds:di (es:di) <- ptr to item.
						;
	push	cx, di				;
	add	di, oldSize			; di <- ptr to end of old data.
	add	di, cx				; di <- ptr to end of new data.
	dec	di				;
	mov	si, di				; si <- source
	sub	si, cx				;
	mov	cx, oldSize				;
	sub	cx, dx				; cx <- # of chars to shift.
	std					; move backward.
	rep	movsb				; Shift the data.
	cld					; reset flag.
	pop	cx, di				;
						;
	push	ax				;
	add	di, dx				; di <- position of insertion.
	clr	al				; al <- byte to clear data with
	rep	stosb				; zero out the inserted space.
	pop	ax				;
	pop	di				; di <- handle to chunk again.
						;
	call	DBUnlock			; Unlock the item. (es:*di).
	pop	si, ax				; Restore seg registers.
	pop	ds, es				; Restore seg registers.
	;
	; ds,es = segments to fixup.
	; si	= old address of re-alloc'd block.
	; ax	= new address of re-alloc'd block.
	; dx	= scratch.
	;
	cmp	ax, si				; if no change then
	je	quit				;    quit
	mov	dx, ds				;
	cmp	dx, si				; if ds == old seg addr then
	jne	noDSFixup			;
	mov	ds, ax				;    fixup ds
noDSFixup:					;
	mov	dx, es				;
	cmp	dx, si				; if es == old seg addr then
	jne	noESFixup			;
	mov	es, ax				;    fixup es
noESFixup:					;
						;
quit:						;
	.leave					;
	ret					;
DBInsertAt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBDeleteAt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete bytes from the middle of an item.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group.	(VM block handle).
		di = item.	(Offset into group block).
		dx = offset to delete at.
		cx = # of bytes to delete.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBDeleteAt	proc	far
	push	ax				;
EC <	call	ECVMCheckVMFile			; check bx parameter.	>
EC <	call	DBCheckIsGroup			; check ax parameter.	>
EC <	call	DBCheckIsItem			; check di parameter.	>
						;
	push	ds, si				;
	call	DBGroupLock			; ds <- seg addr of group.
	mov	si, ds:[di].DBII_block		; si <- item-block reference.
	mov	ax, ds:[di].DBII_chunk		; ax <- chunk.
	call	DBItemBlockLock			; es <- seg addr of item-block.
	call	DBItemBlockDirty		; Dirty the item-block.
	;
	; Have es:*ax = pointer to item.
	;
	push	ax, bx, ds			;
	segmov	ds, es				; ds:*ax <- item reference.
	mov	bx, dx				; bx <- offset to delete at.
						; cx already holds # to delete.
	call	LMemDeleteAt			; Nuke 'em.
	pop	ax, bx, ds			;
						;
	call	DBItemBlockUnlock		; Unlock the item block (es).
	call	DBGroupUnlock			; Unlock the group	(ds).
	pop	ds, si				;
	pop	ax				;
	ret					;
DBDeleteAt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new database group.

CALLED BY:	External.
PASS:		bx = Database file handle.
RETURN:		ax = group	(VM-handle of group block).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGroupAlloc	proc	far
EC <	call	ECVMCheckVMFile			; Check bx parameter.	>
						;
	push	cx, bp, ds			;
	mov	ax, DB_GROUP_ID			; ax <- id for block.
	mov	cx, size DBGroupHeader		; cx <- size.
	call	VMAlloc				; ax <- vm block handle
	push	ax				; save it for returning.
	call	VMLock				; ax <- segment, bp <- handle.
	;
	; Initialize the group block. (0-initialized by VMAlloc)
	;
	mov	ds, ax				;
	mov	ds:DBGH_handle, bp		; Save the memory handle.
	mov	ds:DBGH_blockSize, size DBGroupHeader
	pop	ax				; return in ax.
	mov	ds:DBGH_vmemHandle, ax		; save group handle.
						;
	call	VMDirty				; Mark group as dirty.
	call	VMUnlock			; Unlock group.
	pop	cx, bp, ds			;
	ret					;
DBGroupAlloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all items associated with a group.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group	(VM-handle of group block).
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/21/89		Initial version
	dlr	12/20/89	Free the group handle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGroupFree	proc	far 	uses ax, di, si, ds
	.enter
EC <	call	ECVMCheckVMFile			; Check bx param.	>
EC <	call	DBCheckIsGroup			; Check ax param.	>
						;
	;
	; If the group being freed is the current old or new ungroup, zero
	; out that field of the db map block.
	; 
	call	DBLockDBMap
	clr	di
	cmp	ds:[DBMB_newUngrouped], ax
	jne	checkOldUngroup
	mov	ds:[DBMB_newUngrouped], di
checkOldUngroup:
	cmp	ds:[DBMB_ungrouped], ax
	jne	ungroupHandled
	mov	ds:[DBMB_ungrouped], di
ungroupHandled:
	;
	; If the group contains the map item, zero that out, too.
	; 
	cmp	ds:[DBMB_mapGroup], ax
	jne	dirtyMap
	mov	ds:[DBMB_mapGroup], di
	mov	ds:[DBMB_mapItem], di
dirtyMap:
	call	DBDirtyDBMap
	call	DBUnlockDBMap


	push	ax				; save the group handle
	call	DBGroupLock			; ds <- seg addr of group.
	mov	di, ds:DBGH_itemBlocks		; ds:di <- ptr to first block.
DBGF_loop:					;
	tst	di				;
	jz	DBGF_endLoop			;
	push	ds:[di].DBIBI_next		; save link to next item.
	mov	ax, ds:[di].DBIBI_block		;
	call	VMFree				;
	pop	di				; di <- next item.
	jmp	DBGF_loop			; loop to do next one.
DBGF_endLoop:					;
	call	DBGroupUnlock			;
	pop	ax				; restore the group handle
	call	VMFree				; free the group
	.leave					;
	ret					;
DBGroupFree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBSetMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Define a database item as being the road-map to the data file.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group	(VM-handle of group block).
		di = item	(Offset to DBItemInfo in group block).
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Lock the datbase managers map block.
	Set the map block information in the header.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBSetMap	proc	far
	push	ax			;
EC <	call	ECVMCheckVMFile		; Check bx param.	>
EC <	call	DBCheckIsGroup		; Check ax param.	>
EC <	call	DBCheckIsItem		; Check di param.	>
					;
	push	ds			;
	call	DBLockDBMap		; ds <- segment address of map block.
	mov	ds:DBMB_mapGroup, ax	; save map group.
	mov	ds:DBMB_mapItem, di	; save map item.
	call	DBDirtyDBMap		; mark that we've changed it
	call	DBUnlockDBMap		;
	pop	ds			;
	pop	ax			;
	ret				;
DBSetMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGetMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the database item that is the map.

CALLED BY:	External.
PASS:		bx = Database file handle.
RETURN:		ax = group	(VM-handle to group block).
		di = item	(Offset to DBItemInfo in group block).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Lock the datbase managers map block.
	Get the map block information in the header.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGetMap	proc	far
EC <	call	ECVMCheckVMFile		; Check bx param.	>
					;
	push	ds			;
	call	DBLockDBMap		; ds <- segment address of map block.
	mov	ax, ds:DBMB_mapGroup	; get map group.
	mov	di, ds:DBMB_mapItem	; get map item.
	call	DBUnlockDBMap		;
	pop	ds			;
	ret				;
DBGetMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCopyDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy an existing DB item.

CALLED BY:	External.
PASS: 		bx = Source file handle.
		ax = group of source DB item
		di = source item	(Offset to DBItemInfo in group block).

		bp = dest file handle 
		cx = destination group

RETURN:		di - item created
		ax - group

DESTROYED:	nothing.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBCopyDBItem	proc	far	uses	bx, cx, dx, si, es, ds
	.enter

	call	DBLock			;Lock the source db item
	segmov	ds, es
	mov	si, di			;*DS:SI <- ptr to DB item
	mov	di, ds:[si]		;
	mov_tr	ax, cx			;AX <- group of destination	
	ChunkSizePtr ds, di, cx		;CX <- size of src DB item

;	ALLOC DB ITEM IN DESTINATION FILE

	mov	bx, bp
	call	DBAlloc
	push	di, ax			;Push item/group we created

;	Lock just-allocated block and copy data over to it

	call	DBLock
	call	DBDirty
	mov	si, ds:[si]		;DS:SI <- ptr to src chunk
	mov	di, es:[di]		;ES:DI <- ptr to dest chunk
	shr	cx, 1
	jnc	10$
	movsb
10$:	
	rep	movsw
	call	DBUnlock		;Unlock the dest DB item
	segmov	es, ds			;
	call	DBUnlock		;Unlock the source DB item
	pop	di, ax			;Restore DB item/group

	.leave
	ret
DBCopyDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch salient info about a DB item

CALLED BY:	(GLOBAL)
PASS:		bx	= VM file
		ax	= DB group
		di	= DB item
RETURN:		carry set if group or item is invalid
		carry clear if ok:
			cx	= size of the item
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBInfo		proc	far
		uses	ax, ds, si, bp, di
		.enter
EC <		call	ECVMCheckVMFile					>
	;
	; See if the group block is actually a group block.
	;
		push	di, ax
		call	VMInfo
		mov	si, di
		pop	di, ax
		jc	invalid			; => not a VM block
		cmp	si, DB_GROUP_ID		; is it a DB group?
		jne	invalid			; no -- invalid

		cmp	di, cx			; item info beyond bounds of the
						;  group block?
		jae	invalid			; yes -- invalid
	;
	; Lock down the group and fetch the item info.
	;
		call	DBGroupLock		; ds <- group
		
		mov	ax, ds:[di].DBII_block
		mov	si, ds:[di].DBII_chunk
	;
	; Make sure the item block info offset points to a valid, in-use item
	; block info record by looking down the group's item block info chain
	; for that offset.
	;
		mov	di, offset DBGH_itemBlocks - offset DBIBI_next
validateItemBlock:
		mov	di, ds:[di].DBIBI_next
		tst	di
		jz	validateItemBlockDone		; => hit end of list
		cmp	ax, di
		jne	validateItemBlock

validateItemBlockDone:
	;
	; Make sure the item block is a valid VM block
	;
		mov	ax, ds:[di].DBIBI_block
		call	DBGroupUnlock
		tst	di			; did we actually find it?
		jz	invalid			; => no

		push	ax
		call	VMInfo
		pop	ax
		jc	done
		cmp	di, DB_ITEM_BLOCK_ID
		jne	invalid			; => valid VM, but not an item
						;  block

		cmp	si, cx			; is chunk beyond the end of the
						;  block?
		jb	lockItemBlock		; no

unlockInvalid:
		mov	bp, ds:[LMBH_handle]
		call	VMUnlock
invalid:
		stc
		jmp	done

lockItemBlock:
	;
	; Release the group and lock the item block instead.
	;
		call	VMLock
		mov	ds, ax
	;
	; Make sure the chunk handle is a valid chunk.
	;
		cmp	si, ds:[LMBH_offset]
		jb	unlockInvalid		; => before handle table
		mov	cx, ds:[LMBH_nHandles]
		shl	cx
		add	cx, ds:[LMBH_offset]
		cmp	si, cx
		jae	unlockInvalid		; => after handle table
		tst	{word}ds:[si]
		jz	unlockInvalid		; => free handle
	;
	; Endlich, get the size of the chunk and release the block.
	;
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
		call	VMUnlock
		clc
done:
		.leave
		ret
DBInfo		endp

DBaseCode	ends
