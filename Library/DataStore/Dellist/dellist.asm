COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		dellist.asm

AUTHOR:		Robert Greenwalt, Feb 13, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg 	2/13/97   	Initial revision


DESCRIPTION:
		
	Routines that use the deadlist

	$Id: dellist.asm,v 1.1 97/04/16 16:31:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DeletionListCode	segment	resource

Comment @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DLCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates an empty block for the dellist

CALLED BY:	InitializeDataStore
PASS:		bx - handle of datastore file
RETURN:		carry set if error
			ax - DataStoreError
		else
			ax - vm block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg 	2/13/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DLCreate	proc	far
	uses	cx,ds
	.enter
		push	bx

		mov	ax, size DelList + (size DelListEntry * \
				DS_DEL_LIST_LENGTH)
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jc	memError
		mov	ds, ax
	;
	; Setup some intial values
	;
		mov	{word}ds:[DL_latest], (offset DL_listTop)
		mov	{word}ds:[DL_cachedTransaction].low, -1
		mov	{word}ds:[DL_cachedTransaction].high, -1
		call	MemUnlock
	;
	; Now attach it to the file
	;
		mov	cx, bx
		clr	ax
		pop	bx
		call	VMAttach	; bx = vm file handle
					; ax = vm block handle or 0 to alloc
					; cx = block to attach
					; ax < vm block
		clc
done:
	.leave
	ret
memError:
		pop	bx
		mov	ax, DSE_MEMORY_FULL
		jmp	done
DLCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DLAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new entry to the list

CALLED BY:	DeleteRecordCommonAndTrack
PASS:		bx - file
		dxcx = record id
		disi = transaction number of the deletion
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	may overwrite the oldest entry in the list

PSEUDO CODE/STRATEGY:
		If the file doesn't have a dellist, don't do anything

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg 	2/14/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DLAdd	proc	far
	uses	ax,bp,es,bx
	.enter
	;
	; Find our DelList
	;
		call	VMGetMapBlock
		call	VMLock
		mov	es, ax
		mov	ax, es:[DSM_delList]
		call	VMUnlock
	;
	; Verify it exists
	;
		tst	ax
		jnz	haveList
done:
	.leave
	ret
haveList:
		call	VMLock
		mov	es, ax
		mov	bx, es:[DL_latest]
	;
	; calc the offset of the next slot
	;
		add	bx, size DelListEntry
		cmp	bx, ((DS_DEL_LIST_LENGTH-1) * size DelListEntry) \
				+ offset DL_listTop
		jbe	haveAddress
		mov	bx, offset DL_listTop
haveAddress:
	;
	; Store it
	;
		mov	es:[DL_latest], bx
		movdw	es:[bx].DLE_transactionNumber, disi
		movdw	es:[bx].DLE_recordID, dxcx
		call	VMDirty
		call	VMUnlock
		jmp	done
DLAdd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DLFindDeletedSince
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first entry since a transaction number

CALLED BY:	Internal
PASS:		ax = datastore token
		dxcx = transaction number to find since
RETURN:		carry set if not tracking or don't remember back that
			far
		dxcx = transaction # of next deletion since passed
			transaction #
		bxsi = record ID of next deletion since passed
			transaction #
DESTROYED:	nothing
SIDE EFFECTS:	adjusts the dellist search cache

PSEUDO CODE/STRATEGY:
		if the request number = the cache number
			and the cached number = the list[cache-offset] number
				then the cached number equals the
				list[++cache-offset] number, return
				the cached number
		else
			do a linear search - replace the cache if get
			a hit


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg 	2/14/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DLFindDeletedSince	proc	far
	uses	bp, es, ds, ax
	.enter
	;
	; Find our dellist
	;
		mov	bl, mask DSEF_WRITE_LOCK
		mov	si, cx			; dxsi = trans #
		call	DMLockDataStore
;
; Unlock DataStore(ds token = ax)
;
		push	ax
		call	VMGetMapBlock		; bx = VM file
						; ax <= vm block
		call	VMLock			; lock the mapblock
		mov	es, ax
		mov	ax, es:[DSM_delList]
		call	VMUnlock
	;
	; verify it exists
	;
		tst	ax
		stc
		jz	noDelList
		call	VMLock			; lock the dellist
;
; Unlock DataStore (dstoken = stack)
; Unlock DelList (vmhandle = bp)
;
		mov	ds, ax
	;
	; Check for a cache hit
	;
		cmpdw	dxsi, ds:[DL_cachedTransaction]
		jne	notCached
	;
	; Check the validity of cache
	;
		mov	bx, ds:[DL_cachedOffset]
		cmpdw	dxsi, ds:[bx].DLE_transactionNumber
		jne	notCached
	;
	; Cache hit - we know the offset of the next guy
	;
		incdw	dxsi		; findsince++
		jmp	loopTop
haveAddress:
	;
	; Update the cache
	;
		mov	ds:[DL_cachedOffset], bx
		movdw	dxcx, ds:[bx].DLE_transactionNumber
		movdw	ds:[DL_cachedTransaction], dxcx
		mov	si, ds:[bx].DLE_recordID.low
		mov	bx, ds:[bx].DLE_recordID.high
		clc
unlockList:
		pushf
		call	VMDirty
		popf
		call	VMUnlock
noDelList:
		pop	ax
		call	DMUnlockDataStore
	.leave
	ret
backToTop:
		mov	bx, offset DL_listTop
		jmp	checkEntry
notCached:
	;
	; We've got to do a search - setup
	;
		mov	bx, ds:[DL_latest]
		add	bx, size DelListEntry		; bx = earliest
		incdw	dxsi				; findsince++
		cmp	bx, ((DS_DEL_LIST_LENGTH-1) * size DelListEntry) \
				+offset DL_listTop
		jbe	haveEarliest
		mov	bx, offset DL_listTop
haveEarliest:
	;
	; Is it early enough: (earliest <= findsince+1)
	;
		cmpdw	dxsi, ds:[bx].DLE_transactionNumber
		jae	checkEntry
		call	VMUnlock
		stc				;else fail - we don't
						;hold all since
		jmp	noDelList

loopTop:
	;
	; Now, we've got findsince+1 in dxsi
	;
		add	bx, size DelListEntry
		cmp	bx, ((DS_DEL_LIST_LENGTH-1) * size DelListEntry) \
				+ offset DL_listTop
		ja	backToTop
checkEntry:
		cmpdw	dxsi, ds:[bx].DLE_transactionNumber
		jbe	haveAddress	; hit if findsince+1 <= this
	;
	; Check for wrap
	;
		cmp	bx, ds:[DL_latest]
		jne	loopTop
		clc
		clr	dx, cx, si, bx
		jmp	unlockList

DLFindDeletedSince	endp

DeletionListCode	ends
