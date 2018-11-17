COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		DBGroupAndItem Queue
FILE:		dbqCode.asm

AUTHOR:		Adam de Boor, Apr  7, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 7/94		Initial revision


DESCRIPTION:
	Implementation of the DBQ abstraction.
		

	$Id: dbqCode.asm,v 1.1 97/04/05 01:19:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBQ	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a queue to track DBGroupAndItems

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file in which to allocate the queue
		ax	= number of bytes in each item (for DBQAlloc)
		cx	= entry point number of routine to call to clean up
			  item (DBQ_NO_CLEANUP if none needed)
		dx	= entry point number of routine to call when item
			  added to the queue.
RETURN:		carry set if couldn't allocate:
			ax	= 0
		carry clear if queue allocated:
			ax	= queue handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQCreate	proc	far
		uses	di, cx, ds, bp
		.enter
EC <		call	ECVMCheckVMFile					>
EC <		cmp	cx, DBQ_NO_CLEANUP				>
EC <		je	callbackOK					>
EC <		push	bx, ax						>
EC <		mov	ax, cx						>
EC <		mov	bx, handle 0					>
EC <		call	ProcGetLibraryEntry	; let this EC the number>
EC <		pop	bx, ax						>
EC <callbackOK:								>
EC <		cmp	dx, DBQ_NO_ADD_ROUTINE				>
EC <		je	addRoutineOK					>
EC <		push	bx, ax						>
EC <		mov	ax, cx						>
EC <		mov	bx, handle 0					>
EC <		call	ProcGetLibraryEntry	; let this EC the number>
EC <		pop	bx, ax						>
EC <addRoutineOK:							>

		push	cx, ax
		mov	cx, size DBGroupAndItem
		mov	di, size DBQHeader
		call	HugeArrayCreate
	;
	; Now initialize our portion of the HugeArray header.
	; 
		mov	ax, di
		call	VMLock
		mov	ds, ax
		pop	ds:[DBQH_cleanup], ds:[DBQH_itemSize]
		mov	ds:[DBQH_addRoutine], dx
		mov	ds:[DBQH_magic], DBQ_MAGIC_NUMBER
		call	VMDirty
		call	VMUnlock
		mov_tr	ax, di
		clc
		.leave
		ret
DBQCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQAddRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark another reference to a DB item

CALLED BY:	(INTERNAL)
PASS:		bx	= VM file handle
		dxax	= affected item
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	The item's DBQD_refCount is incremented and the item marked 
		dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQAddRef	proc	far
		uses	ax, di, es
		.enter
		pushf
EC <		call	DBQCheckGroupAndItem				>
	;
	; Shift appropriate registers and lock down the item.
	; 
		mov_tr	di, ax		; di <- item
		mov	ax, dx		; ax <- group
		call	DBLock		; *es:di <- item data
	;
	; Deref the item and up the ref count.
	; 
		mov	di, es:[di]
		inc	es:[di].DBQD_refCount
EC <		ERROR_Z	DBQ_REF_COUNT_OVERFLOW				>
	;
	; That makes the item dirty, so do the deed before unlocking the block.
	; 
		call	DBDirty
		call	DBUnlock
		popf
		.leave
		ret
DBQAddRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQDelRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove another reference to a DB item

CALLED BY:	(INTERNAL)
PASS:		bx	= VM file handle
		dxax	= affected item
RETURN:		nothing
DESTROYED:	dx, ax (flags preserved)
SIDE EFFECTS:	item will be destroyed if the ref count goes to 0

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQDelRef	proc	far
		uses	cx, di, es
		.enter
		pushf
EC <		call	DBQCheckGroupAndItem				>
		pushdw	dxax		; for possible free...
	;
	; Shift appropriate registers and lock down the item.
	; 
		mov_tr	di, ax		; di <- item
		mov_tr	ax, dx		; ax <- group
		call	DBLock		; *es:di <- item data
	;
	; Deref the item and decrease the ref count.
	; 
		mov	di, es:[di]
EC <		tst	es:[di].DBQD_refCount				>
EC <		ERROR_Z	DBQ_REF_COUNT_UNDERFLOW				>
		dec	es:[di].DBQD_refCount
		jz	destroy		; => no more refs, so kill it
	;
	; Not ready for the scrap heap yet, but it is dirty, so mark it thus
	; before unlocking it.
	; 
		call	DBDirty
		call	DBUnlock
		add	sp, 4		; discard group & item (want ax & dx to
					;  actually be destroyed, for EC...)
done:
		popf
		.leave
		ret

destroy:
	;
	; The reference count has reached 0, so we want to first call the
	; queue-specific cleanup procedure to do its thing, then free the item.
	; 
		mov	cx, es:[di].DBQD_cleanup
	;
	; Release the item. no need to perform the DBDirty since we're about to
	; biff it. Don't need to worry about the thing getting discarded and
	; coming back in with a refcount of 1 since no one can have a reference
	; to it (that's why we're destroying it...)
	; 
		call	DBUnlock
		popdw	dxax
			CheckHack <DBQ_NO_CLEANUP eq -1>
		inc	cx
		jz	freeItem
		dec	cx
	;
	; Fetch the vfptr of the cleanup routine.
	; 
		push	bx		; save file handle
		mov	bx, handle 0
		xchg	ax, cx		; ax <- entry #, cx <- item
		call	ProcGetLibraryEntry
		mov	di, bx		; diax <- vfptr
		pop	bx
	;
	; Rearrange the registers appropriately and make the call.
	; 
		pushdw	diax
		mov_tr	ax, cx		; dxax <- group & item, again		
		call	PROCCALLFIXEDORMOVABLE_PASCAL
freeItem:
	;
	; Rearrange the registers for DBFree and (finally) free the item itself.
	; 
		mov_tr	di, ax
		mov_tr	ax, dx
		call	DBFree
		jmp	done
		
DBQDelRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append an entry to a DBQ

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file handle
		di	= queue handle
		dxax	= DBGroupAndItem to add
RETURN:		carry set if couldn't append item
		carry clear if item appended
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQAdd		proc	far
		uses	cx, bp, si, ds, bx
		.enter
EC <		call	DBQCheckQueue					>	
EC <		call	DBQCheckGroupAndItem				>
		call	DBQAddRef
	;
	; Lock down the queue header so adding to the queue and calling the
	; DBQH_addRoutine are an atomic operation.
	; 
		mov_tr	si, ax		; si <- item
		call	HugeArrayLockDir
		mov	ds, ax
		mov_tr	ax, si		; ax <- item, again

	;
	; Append the DBGroupAndItem as a new element in the array.
	; 
		push	ds:[DBQH_meta].HAD_header.LMBH_handle	; save mem
								;  handle for
								;  deref
		pushdw	dxax
		mov	cx, 1		; append 1 element, please
		mov	bp, ss		; bp:si <- data pointer
		mov	si, sp
		call	HugeArrayAppend
		popdw	dxax
		pop	bp		; bp <- header handle
	;
	; Point to the header again and see if there's an addRoutine we need
	; to call.
	; 
		xchg	bx, bp		; bp <- VM file, bx <- header handle
		call	MemDerefDS	; ds <- header, again

		mov_tr	si, ax		; save item
		mov	ax, ds:[DBQH_addRoutine]
	CheckHack <DBQ_NO_ADD_ROUTINE eq -1>
		inc	ax
		jz	done
		dec	ax
	;
	; There is. Fetch its address and call it, please.
	; 
		mov	bx, handle 0
		call	ProcGetLibraryEntry	; bx:ax <- routine to call
		pushdw	bxax
		mov	ax, si		; dxax <- group & item
		mov	bx, bp		; bx <- file handle
		call	PROCCALLFIXEDORMOVABLE_PASCAL
done:
		mov_tr	ax, si		; ax <- item, again
	;
	; Release the queue header.
	; 
		call	HugeArrayUnlockDir
		clc			; happiness
		.leave
		ret
DBQAdd		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQHugeArrayEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a HugeArrayEnum over a queue, calling a callback
		in this segment.

CALLED BY:	(INTERNAL) DBQRemove, DBQEnum, DBQMatch, DBQDestroy
PASS:		bx	= VM file handle
		di	= queue handle
		cs:ax	= callback routine
RETURN:		what HugeArrayEnum returns
DESTROYED:	whatever
SIDE EFFECTS:	ax is cleared before HugeArrayEnum is called (for DBQEnum)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQHugeArrayEnum proc	near
		.enter
		
		push	bx			; file handle
		push	di			; array handle
FXIP <		mov	di, SEGMENT_CS					>
FXIP <		push	di						>
FXIP <		mov	di, sp						>
FXIP <		mov	di, ss:[di + size sptr]	; di = array handle	>
NOFXIP <	push	cs						>
		push	ax			; callback
		clr	ax
		pushdw	axax			; starting elt # (0)
		dec	ax
		pushdw	axax			; # elts (all)
		inc	ax			; ax <- 0
		call	HugeArrayEnum
		.leave
		ret
DBQHugeArrayEnum endp
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find and remove an entry from a DBQ

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file handle
		di	= queue handle
		dxax	= DBGroupAndItem to remove
RETURN:		carry set if couldn't remove (item not in queue)
		carry clear if item removed
DESTROYED:	dx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQRemove	proc	far
eltNum		local	dword
		uses	cx
		.enter
EC <		call	DBQCheckQueue					>	
EC <		call	DBQCheckGroupAndItem				>
		push	ax
		mov_tr	cx, ax		; dxcx <- item for which we search
		clrdw	ss:[eltNum]
		mov	ax, offset DBQRemoveCallback
		call	DBQHugeArrayEnum	; CF set if found
		pop	ax		; dxax = DBGroupAndItem
		jnc	done

		; remove element from queue
		call	DBQDelRef
		mov	cx, 1		; delete one elt
		movdw	dxax, ss:[eltNum]
		call	HugeArrayDelete
		stc			; such that CF will be clear on return

done:
		cmc			; carry set if not found
		.leave
		ret
DBQRemove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQRemoveCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate and remove an item from a DBQ

CALLED BY:	(INTERNAL) DBQRemove via HugeArrayEnum
PASS:		ds:di	= DBGroupAndItem to check
		dxcx	= DBGroupAndItem being removed.
		ss:bp	= inherited stack frame from DBQRemove
RETURN:		carry set if found element (stop enumerating):
;;;			HugeArrayContract called to delete the element
;;;			ax, cx	= destroyed
		carry clear if didn't find element (keep looking)
DESTROYED:	nothing
SIDE EFFECTS:;;;	element is removed if found (this is ok, since enumeration
     			is also stopped when this happens)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQRemoveCallback proc	far
		.enter inherit DBQRemove

		Assert	stackFrame, bp
		cmpdw	dxcx, ds:[di]
		stc			; assume it matches
		je	done

		incdw	ss:[eltNum]	; next element num
		clc			; continue enumerating
done:
		.leave
		ret
DBQRemoveCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQGetItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Using an index, fetch the DBGroupAndItem of the indexth
		entry in the queue (0-origin). The item has an extra
		reference added to it that must be released by calling
		DBQDelRef

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file handle
		di	= queue handle
		cx	= index of entry to retrieve
RETURN:		carry set if index is invalid:
			dxax	= 0_0
		carry clear if entry gotten:
			dxax	= DBGroupAndItem
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQGetItem	proc	far
		.enter
		call	DBQGetItemNoRef
		jc	done
		call	DBQAddRef
		clc			; happy happy joy joy
done:
		.leave
		ret
DBQGetItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQGetItemNoRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Using an index, fetch the DBGroupAndItem of the indexth
		entry in the queue (0-origin), but don't add an extra
		reference to the item (the caller guarantees the item will
		remain in the queue so long as the caller is using the
		DBGroupAndItem thus obtained)

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file handle
		di	= queue handle
		cx	= index of entry to retrieve
RETURN:		carry set if index is invalid:
			dxax	= 0_0
		carry clear if entry gotten:
			dxax	= DBGroupAndItem
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQGetItemNoRef	proc	far
		uses	ds, si, cx
		.enter
EC <		call	DBQCheckQueue					>
		mov_tr	ax, cx
		clr	dx		; dx.ax = element number to get.
		call	HugeArrayLock
		tst	ax		; any elements found?
		cwd			; assume...
		stc			;  ...not (dxax <- 0_0)
		jz	done
		
		lodsw			; ax = DBGI_item	(1 byte inst)
		mov_tr	dx, ax		; dx = DBGI_item	(1 byte inst)
		lodsw			; axdx = DBGroupAndItem	(1 byte inst)
		xchg	dx, ax		; dxax = DBGroupAndItem	(1 byte inst)
		call	HugeArrayUnlock	; release the array entry
EC <		call	DBQCheckGroupAndItem				>
		clc			; happy happy joy joy
done:
		.leave
		ret
DBQGetItemNoRef	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate through the entries in a queue, calling a callback
		for each entry.

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file containing the queue
		di	= queue handle
		cx:dx	= callback routine:
			  Pass:	bx	= VM file containing the queue
				sidi	= DBGroupAndItem
				cx, dx, bp, es = as returned by previous call
					     (bp for first callback as passed 
					     to DBQEnum)
			  Return: carry set to stop enumerating:
			  		ax, cx, dx, bp, es = to return to 
							caller of DBQEnum
				  carry clear to keep enumerating:
					cx, dx, bp, es = to pass to next 
							 callback
					ax = destroyed
			  Destroyed:
				bx, si, di
RETURN:		carry set if callback stopped iteration
		carry clear if callback didn't stop iteration
		ax, cx, dx, bp, es = as returned by callback (ax, cx, dx, all 0
				 if the queue was empty)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQEnum		proc	far
cbBP		local	word	push bp
vmFile		local	word	push bx
callback	local	fptr	push cx, dx
	ForceRef	cbBP		; DBQEnumCallback
	ForceRef	vmFile		; DBQEnumCallback
	ForceRef	callback	; DBQEnumCallback
		.enter
EC <		call	DBQCheckQueue					>
		Assert	vfptr, cxdx		

		clr	cx, dx			; cx, dx <- 0 (in case no elts)
		mov	ax, offset DBQEnumCallback
		call	DBQHugeArrayEnum
		.leave
		ret
DBQEnum		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for DBQEnum to load up the registers and
		call the true callback routine.

CALLED BY:	(INTERNAL) DBQEnum via HugeArrayEnum
PASS:		ds:di	= current DBGroupAndItem
		cx, dx, es	= to pass to true callback
		bp	= frame pointer from DBQEnum
RETURN:		carry set to stop iterating:
			ax, cx, dx, bp, es = to return to caller of DBQEnum
		carry clear to keep going:
			cx, dx, bp, es = for next callback
			ax = destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQEnumCallback	proc	far
		uses	bx, si, di
		.enter	inherit	DBQEnum
	;
	; Load up the registers. Sadly, this leaves us with no register to
	; point to the callback routine address, so we have to push the callback
	; on the stack and use PROCCALLFIXEDORMOVABLE_PASCAL to get there.
	; This has the added benefit of allowing the callback to be movable,
	; of course...
	; 
		mov	bx, ss:[vmFile]
		mov	si, ds:[di].DBGI_group	; sidi <- DBGroupAndItem
		mov	di, ds:[di].DBGI_item
		push	bp

		pushdw	ss:[callback]		; callback itself...
		mov	bp, ss:[cbBP]		; bp <- caller's bp
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		mov	bx, bp
		pop	bp
		mov	ss:[cbBP], bx		
		.leave
		ret
DBQEnumCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Match bytes in each entry against the passed buffer and
		store the DBGroupAndItem for each match in the DBQ
		whose handle is returned.

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file containing the queue
		di	= queue handle
		dx:si	= buffer containing comparison bytes
		cx	= number of bytes to compare
		ax	= offset within each entry of data to compare
RETURN:		carry set on error:
			ax	= 0
		carry clear on success:
			ax	= handle of HugeArray containing the 
				  DBGroupAndItem refs of those elements
				  that matched.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQMatch	proc	far
compBuf		local	fptr	push dx, si
compSize	local	word	push cx
compOff		local	word	push ax
vmFile		local	word	push bx
resultArray	local	word
	ForceRef	compBuf		; DBQMatchCallback
	ForceRef	compSize	; DBQMatchCallback
	ForceRef	compOff		; DBQMatchCallback
	ForceRef	vmFile		; DBQMatchCallback
		uses	cx, dx
		.enter
EC <		call	DBQCheckQueue					>
		Assert	vfptr, dxsi
		
	;
	; Create a queue for the results.
	; 
		push	bp, ds
		mov	ax, di
		call	VMLock
		mov	ds, ax
		mov	ax, ds:[DBQH_itemSize]
		mov	cx, ds:[DBQH_cleanup]
		call	VMUnlock
		pop	bp, ds
		
		mov	dx, DBQ_NO_ADD_ROUTINE
		call	DBQCreate
		mov	ss:[resultArray], ax
	;
	; Set up the args for HugeArrayEnum
	; 
		mov	ax, offset DBQMatchCallback
		call	DBQHugeArrayEnum
		
		mov	ax, ss:[resultArray]
		.leave
		ret
DBQMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQMatchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to compare bytes in the current DBGroupAndItem
		against those provided by the caller of DBQMatch

CALLED BY:	(INTERNAL) DBQMatch via HugeArrayEnum
PASS:		ds:di	= DBGroupAndItem
		ss:bp	= inherited frame
RETURN:		carry set to stop enumerating
			ss:[resultArray] = 0 (array destroyed)
		carry clear to keep enumerating
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQMatchCallback proc	far
		uses	ds, si, es, di, cx, ax, bx, bp
		.enter	inherit	DBQMatch
	;
	; Fetch out the group & item.
	; 
		mov	bx, ss:[vmFile]
		mov	ax, ds:[di].DBGI_group
		mov	di, ds:[di].DBGI_item

		pushdw	axdi			; save for DBQAdd, in
						;  case the thing matches.
	;
	; Lock down the item so we can compare its bytes.
	; 
		call	DBLock			; *es:di <- item
		lds	si, ss:[compBuf]	; ds:si <- benchmark

		mov	di, es:[di]		; es:di <- item
	;
	; EC: Make sure the bytes against which we're comparing in the item
	; actually are *in* the item.
	; 
EC <		ChunkSizePtr	es, di, cx				>
EC <		mov	ax, ss:[compOff]				>
EC <		cmp	cx, ax		; item smaller than starting offset?>
EC <		ERROR_B	COMPARISON_OFFSET_BEYOND_BOUNDS_OF_ITEM		>
EC <		add	ax, ss:[compSize]				>
EC <		cmp	cx, ax		; item smaller than ending offset?>
EC <		ERROR_B	ITEM_TOO_SMALL_FOR_COMPLETE_COMPARISON		>

		add	di, ss:[compOff]	; es:di <- bytes to compare
		mov	cx, ss:[compSize]
		tst	cx			; set ZF in case CX == 0 =>
						;  we're basically duplicating
						;  the DBQ...
		repe	cmpsb
		popdw	dxax			; dxax <- item
		call	DBUnlock
		jne	done			; => no match
	;
	; Append the DBGroupAndItem to the result queue.
	; 
		mov	di, ss:[resultArray]
		call	DBQAdd
done:
	;
	; Continue iterating.
	; 
		clc
		.leave
		ret
DBQMatchCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy a queue. The items within the queue will be freed when
		their reference counts drop to 0.

		Note: it is the responsibility of the caller to make sure
		the queue is not used during or after the destruction.

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file containing the queue
		di	= queue handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQDestroy	proc	far
vmFile		local	word	push bx
	ForceRef	vmFile	; DBQDestroyCallback
		uses	ax
		.enter
EC <		call	DBQCheckQueue					>
	;
	; Remove our reference from each element.
	; 
		mov	ax, offset DBQDestroyCallback
		call	DBQHugeArrayEnum
	;
	; Now destroy the array, wholesale.
	; 
		call	HugeArrayDestroy

		.leave
		ret
DBQDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQDestroyCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove this queue's reference from a single item.

CALLED BY:	(INTERNAL) DBQDestroy via HugeArrayEnum
PASS:		ds:di	= current DBGroupAndItem
RETURN:		carry set to stop enumerating
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQDestroyCallback proc	far
		uses	bx, dx, ax, cx
		.enter	inherit	DBQDestroy
	;
	; Load up registers for callback.
	; 
		mov	bx, ss:[vmFile]
		mov	ax, ds:[di].DBGI_group
		mov	di, ds:[di].DBGI_item
		call	DBInfo
		jc	done		; => item not valid, so don't nuke
		MovMsg	dxax, axdi
		call	DBQDelRef
done:
		clc
		.leave
		ret
DBQDestroyCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate an item for the queue.

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file containing the queue
		di	= queue handle
RETURN:		carry set if couldn't allocate:
			dxax	= 0_0
		carry clear if item allocated:
			dxax	= DBGroupAndItem. item's DBQData is properly
				  initialized
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQAlloc	proc	far
		uses	bp, di, es, cx
		.enter
EC <		call	DBQCheckQueue					>
	;
	; Fetch the item size and cleanup routine from the queue header.
	; 
		mov	ax, di
		call	VMLock
		mov	es, ax
		mov	cx, es:[DBQH_itemSize]
		mov	dx, es:[DBQH_cleanup]
		call	VMUnlock
	;
	; Allocate an item of that size, ungrouped.
	; 
		mov	ax, DB_UNGROUPED
		call	DBAlloc

	;
	; Initialize the DBQData of the new item appropriately. We set the
	; reference count to 1, allowing DBQFree to simply call DBQDelRef
	; to have the thing be destroyed.
	; 
		pushdw	axdi		; save for return
		call	DBLock
		mov	di, es:[di]
		mov	es:[di].DBQD_refCount, 1
		mov	es:[di].DBQD_cleanup, dx
		call	DBDirty
		call	DBUnlock
	;
	; Return the new item in dxax
	; 
		popdw	dxax
		.leave
		ret
DBQAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free an allocated item. The item will not actually be freed
		until everyone that's using it is done using it.

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file containing the queue and item
		dxax	= DBGroupAndItem to free
RETURN:		nothing
DESTROYED:	dx, ax
SIDE EFFECTS:	queue cleanup routine may be called

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQFree		proc	far
		GOTO	DBQDelRef
DBQFree		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of entries in the queue.

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file handle
		di	= queue handle
RETURN:		dxax	= # entries
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		This routine exists only in the EC version, where it makes
		sure the thing's a queue, then goes directly to 
		HugeArrayGetCount. In the non-ec, things call HugeArrayGetCount
		directly, instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
DBQGetCount	proc	far
		call	DBQCheckQueue
		call	HugeArrayGetCount
		ret
DBQGetCount 	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQCheckMember
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed item is a member of the passed queue.

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file containing the item & queue
		di	= queue handle
		dxax	= DBGroupAndItem
RETURN:		carry set if the item is in the queue
		carry clear if it's not
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQCheckMember	proc	far
		uses	cx
		.enter
		call	DBQCheckGetIndexCommon
		.leave
		ret
DBQCheckMember	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQCheckGetIndexCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the queue looking for an item & its index

CALLED BY:	(INTERNAL) DBQCheckMember,
			   DBQGetIndex
PASS:		bx	= VM file containing the item & queue
		di	= queue handle
		dxax	= DBGroupAndItem
RETURN:		carry set if the item's in the queue:
			cx	= index of the item (from 0)
		carry clear if the item's not in the queue:
			cx	= # of items in the queue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/13/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQCheckGetIndexCommon proc	near
		uses	bp, ax
		.enter
EC <		call	DBQCheckQueue					>
EC <		call	DBQCheckGroupAndItem				>
		mov_tr	cx, ax			; dxcx <- item for which we
						;  search
		clr	bp			; bp <- index of 1st item
		mov	ax, offset DBQCheckGetIndexCommonCallback
		call	DBQHugeArrayEnum	; carry <- set if found
		mov_tr	cx, bp
		.leave
		ret
DBQCheckGetIndexCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQCheckGetIndexCommonCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate an item in a DBQ

CALLED BY:	(INTERNAL) DBQCheckGetIndexCommon via DBQHugeArrayEnum
PASS:		ds:di	= DBGroupAndItem
		dxcx	= DBGroupAndItem being sought
		bp	= index of this element
RETURN:		carry set if found element (stop enumerating):
			bp	= index of this element
		carry clear if not the element being sought
			bp	= index of the next element
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQCheckGetIndexCommonCallback proc	far
		.enter
		inc	bp			; assume not the one
		cmpdw	dxcx, ds:[di]
		clc
		jne	done
		dec	bp			; bp <- this element's index
		stc
done:
		.leave
		ret
DBQCheckGetIndexCommonCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQGetIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If an item is in a queue, return its index.

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM file containing the item & queue
		di	= queue handle
		dxax	= DBGroupAndItem
RETURN:		carry set if item not in the queue:
			cx	= destroyed
		carry clear if item is in the queue:
			cx	= its index
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/13/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQGetIndex	proc	far
		.enter
		call	DBQCheckGetIndexCommon
		cmc			; just need to invert the return flag
		.leave
		ret
DBQGetIndex	endp

DBQ	ends

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBQCheckIsDBQ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed thing is a DBQ. Used when opening
		the admin file after a crash, to get rid of unwanted references
		to messages from queues that are no longer in-use.

CALLED BY:	AdminInit
PASS:		^vbx:di	= potential DBQ
RETURN:		carry set if it is a DBQ
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBQCheckIsDBQ	proc	near
		uses	ds, ax, bp
		.enter
		mov	ax, di
		call	VMLock
		mov	ds, ax
		cmp	ds:[DBQH_magic], DBQ_MAGIC_NUMBER
		call	VMUnlock
		clc
		jne	done
		stc
done:
		.leave
		ret
DBQCheckIsDBQ	endp

Init	ends
