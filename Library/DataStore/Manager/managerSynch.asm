COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	DataStore	
MODULE:		Manager
FILE:		managerMain.asm

AUTHOR:		Mybrid Spalding, Oct 11, 1995

ROUTINES:
	Name			Description
	----			-----------
EXT	DMLockDataStore		Locks datastore and returns file
				handle/buffer handle via MSLockDataStoreCommon
EXT	MSLockDataStoreCommon 	Common routine for DMLockDataStore
				MRLoadRecordCommon which does not call
				DMLockDataStore but calls this routine.
EXT	DMUnlockDataStore	Unlocks a datastore
EXT	DMIndexLockDataStore	Grabs the exclusive index lock for a Datastore.
EXT	DMIndexUnlockDataStore  Releases the index lock for a DataStore.
EXT	MSLockMngrBlockP	Semaphore lock on the manager memory block
EXTT	MSUnlockMngrBlockV	Semaphore unlock on the manager memory block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/11/95   	Initial revision


DESCRIPTION:
	DataStore Manager routines which encapsulate synchronization
for the DataStore Library.

	$Id: managerSynch.asm,v 1.1 97/04/04 17:53:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ManagerMainCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMLockDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Synchronization routine for locking a datastore. 
		Read and write locks can be requested.   
		Given a lock request, attempts to grab the requested
		lock. This is a non-blocking grab and fails if unsuccessful.
		EC fail if no lock is requested. Write locks are exclusive.
		A read lock granted increments a read lock count for
		multiple reader access. Multiple lock requests for
		of the same type are allowed by a thread but they must
		be nested. This means exactly one unlock for each lock. In
		other words, 5 consecutive requests for locks must be 
		followed by 5 consecutive unlocks in order to release
		the lock.It is a fatal error to request both a read
		and a write lock for a datastore. If the lock is
		successfully granted than the buffer handle and file
		handle for the datastore are returned.
	
CALLED BY:	(EXTERNAL) Global
PASS:		ax - datastore session token
		bl - DSElementFlags - lock flags only
	
RETURN:		if carry set
			bx - DataStoreError
		else
			bx - file handle
			cx - buffer handle
		
DESTROYED:	nada
SIDE EFFECTS:	
		Locks the DataStore

PSEUDO CODE/STRATEGY:
	05) Lock the Manager Memory Block
	10) call MSLockDataStoreCommon 
	20) return any error return by MSLockDataStoreCommon
	30) Put the buffer handle from the returned session pointer in cx
	40) Unlock the Manager Memory Block before exiting

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMLockDataStore	proc	far
	uses	ax,dx,di,ds,bp
	.enter

	call	MSLockMngrBlockP
	call	MSLockDataStoreCommon
	jc	error			;if carry, ax - DataStoreError, else
					;bx - file handle
					;ds:dx - session element
	mov	di, dx			;ds:di - session element
	mov	cx, ds:[di].DSSE_buffer ;return the buffer handle

exit:
	call	MSUnlockMngrBlockV	
	.leave
	ret

error:
	mov	bx, ax			;bx - DataStoreError
	jmp	exit

DMLockDataStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLockDataStoreCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	From DMLockDataStore:
		Read and write locks can be requested.   
		Given a lock request, attempts to grab the requested
		lock. This is a non-blocking grab and fails if unsuccessful.
		EC fail if no lock is requested. Write locks are exclusive.
		A read lock granted increments a read lock count for
		multiple reader access. Multiple lock requests for
		of the same type are allowed by a thread but they must
		be nested. This means exactly one unlock for each lock. In
		other words, 5 consecutive requests for locks must be 
		followed by 5 consecutive unlocks in order to release
		the lock. It is a fatal error to request a read
		and then write lock for a datastore, although the
	        reverse is okay. If the lock is	successfully granted
		than the buffer handle and file	handle for the
		datastore are returned.

CALLED BY:	(INTERNAL) DMLockDataStore
		(INTERNAL) MRLoadRecordCommon

PASS:		ax - datastore session token
		bl - DSElemenetFlags - lock flags only
		ds - locked Manager LMem segment.
	
RETURN:		if carry set
			ax - DataStoreError
			dx, bx - trashed
		else
			ds:dx - session element 
			bx - file handle for ds:dx			

DESTROYED:	
SIDE EFFECTS:	
		Locks the DataStore. 

PSEUDO CODE/STRATEGY:
	10) call MAGetSessionEntryByDataStoreTokenCallback to 
	    get the session entry
	20) if no entry found for the datastore token then set carry  & exit.
	30) EC Verify that one and only one lock flag is requested.
	40) Check if this is a first time lock request or a multiple
	    request.
	50) For multiple locks, if the holding a read lock and
	    requesting a write lock, EC fail. 
	60) For first time lock requests, get the DSElement lock
	    flags, and set the lock bit. 
	70) For fist time lock requests check if the number of read
	    locks is over the maximum. increment the read lock count, 
	    and set the lock count.
	62) For first time lock requests set the lock bit in the
	    session entry dsFlags.
	64) For all lock requests granted, increment the session lock
	    count in the session entry.
	90) Return the file handle and session pointer. 
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLockDataStoreCommon	proc	far
	uses	cx,si,di,bp,ds
	.enter

	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>

	;Get the session entry for the datastore token and for the
        ;matching record id from the session table
		
	push 	bx
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetSessionEntryByDataStoreTokenCallback
	call	ChunkArrayEnum		;ds:dx - session element
	pop	bx
	LONG jnc badToken
	mov	di, dx			;ds:di - session element

	; Test for valid lock flags
	; Make sure one and only one lock was requested.

	cmp	bl, mask DSEF_READ_LOCK					
	je	readLock
	cmp	bl, mask DSEF_WRITE_LOCK
	je	writeLock
EC<	ERROR	BAD_LOCK_FLAGS						>
NEC<	jmp	lockFailed						>

readLock:

	; Does the requester already own the lock? 
	; If so it's okay if we have a write lock and a read is requested.
	; We just treat this as a write lock request and exit normally.

	mov	bl, ds:[di].DSSE_dsFlags				
	mov	bh, bl
	and	bl, ((mask DSEF_READ_LOCK) or (mask DSEF_WRITE_LOCK))
	tst	bl
	jnz	multiLockExit
	
;;;firstReadLock:

	call	MAGetDSElementFlags	;ch - lockCount, cl - lock bits
					;ds:di - element
	and	cl, mask DSEF_WRITE_LOCK ;fail if file is write locked
	tst 	cl
	LONG jnz lockFailed
	cmp	ch,  DSEF_MAXIMUM_READ_LOCKS
					;fail if all the read locks in use
	LONG je	lockFailed
	inc	ch 
	or 	ch, (mask DSEF_READ_LOCK)
	jmp	firstLockExit
	
writeLock:

	; Does the requester already own the lock? 
	
	mov	bl, ds:[di].DSSE_dsFlags				
	mov	bh, bl
	and	bl, ((mask DSEF_READ_LOCK) or (mask DSEF_WRITE_LOCK))
	tst	bl
	jz	firstWriteLock

	; Make sure that we don't hold a read lock and are requesting a
	; write lock, this is dangerous programming and EC fail.

	and	bl, (mask DSEF_READ_LOCK)				
	tst	bl							
EC<	WARNING_NZ WRITE_LOCK_REQUESTED_WHEN_HOLDING_READ_LOCK		>
	LONG jnz lockFailed
	jmp 	multiLockExit

firstWriteLock:

	call	MAGetDSElementFlags	;ch - lockCount, cl - lock bits
					;ds:di - element
	tst 	cl			;fail if any lock is held for this file
	jnz	lockFailed
EC<	tst	ch							>
EC<	ERROR_NZ BAD_LOCK_COUNT						>
	mov	ch, mask DSEF_WRITE_LOCK ;Set the DSElement lock bit

firstLockExit:

	or	ds:[di].DSE_data.DSED_flags, ch	;set DSElement lock
	mov	bx, ds:[di].DSE_data.DSED_fileHandle
EC<	call	ECCheckFileHandle					>
	and	ch, not (mask DSEF_lockCount)
	inc	ch			;add the first lock count to session
	mov	di, dx			;ds:di - session element
	mov	ds:[di].DSSE_dsFlags, ch ;set DSSessionArray lock
	clc				;return no error
	jmp	exit

multiLockExit:

	; Okay, we are requesting another lock.
	; ECVerify the lock count for the session is not greater than
	; the maximum allowed or is zero.

EC<	and	bh, (mask DSEF_lockCount)				>
EC<	cmp	bh, DSEF_MAXIMUM_SESSION_LOCKS				>
EC<	ERROR_E REQUESTED_MORE_THAN_MAXIMUM_SESSION_LOCKS		>
EC<	tst	bh							>
EC<	ERROR_Z BAD_SESSION_ENTRY_LOCK_COUNT				>

	; Increment the lock count and return the goodies.

	inc	ds:[di].DSSE_dsFlags	;lockCount are lowest bits
	mov	ax, ds:[di].DSSE_dsToken
	mov	si, ds:[MLBH_dsElementArray]
EC<	call	ECCheckChunkArray					>
	call	ChunkArrayElementToPtr	;ds:di element
	mov	bx, ds:[di].DSE_data.DSED_fileHandle
					;^hbx - datstore file handle
EC<	call	ECCheckFileHandle					>
	clc

exit:
	.leave
	ret

lockFailed:
	mov	ax, DSE_DATASTORE_LOCKED
	stc				;return error
	jmp	exit

badToken:
	mov	ax, DSE_INVALID_TOKEN	
	stc				;return an error
	jmp	exit

MSLockDataStoreCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMUnlockDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks a DataStore file by clearing the lock bits
		in the DataStore and Session arrays. If the lock was a read
		lock it only clears the DataStore lock if the read lock
		count goes to zero, otherwise, only the read lock count is
		decremented. LockDataStore guarantees that the Session has 
		at most one lock, so the lock type doesn't need to be 
		specified. 

CALLED BY:	(EXTERNAL) Global
PASS:		ax - datastore token
	
RETURN:		nada, flags preserved

DESTROYED:	nothing
SIDE EFFECTS:	

		Core dumps if ax is a bad token. Why? Because if a bad
		datastore token is passed there is almost a 100% chance
		an unrecoverable error has happened.

		1.) DMLockDataStore was already called with a good token
		and a bad token passed at the API level should have 
		already been caught. Therefore, a bad token passed
		to DMUnlockDataStore is not an API error, but an
		internal Library bug.

		2.) Whatever DataStore was trying to be unlocked is
		still locked. Presumabley this is not good because
		DataStores should not be locked across API calls, only
		internally. 
	
		
PSEUDO CODE/STRATEGY:
	05) Lock the Manager Block. 
	10) call MAGetSessionEntryByDataStoreTokenCallback to 
	    get the session entry
	20) if no entry found for the datastore token then set carry  & exit.
	30) if the lockCount for the session's DSSE_dsFlags is greater
	    than zero, decrement the count.
	40) if the lockCount is not zero, exit.
	35) Get the Session element's DataStore element dsToken.
	37) Get the DataStore element.
	40) Get the lock bits and read lock count from the DataStore elmennt.
	50) Verify the lock bits set are the same in the Session array and
            the DataStore array.
	60) For read locks, decrement the read lock count, check if the
	    count is 0 and clear the DataStore read lock bit if so.
	70) For read locks, clear the Session element read lock bit.
	80) For write locks, clear both the Session and DataStore element
	    lock bits.
	90) Unlock the Manage block and exit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMUnlockDataStore	proc	far
	uses	ax,bx,cx,dx,si,di,ds,bp
	.enter

	pushf
	call	MSLockMngrBlockP
	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>

	;Get the session entry from the table
	
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetSessionEntryByDataStoreTokenCallback
	call	ChunkArrayEnum		;ds:dx - session element
	ERROR_NC UNLOCKDATASTORE_PASSED_BAD_SESSION_TOKEN

	;EC verify the lock count is greater than zero. One lock count
	;should exist for every lock acquire.

	mov	di, dx			;ds:di - session element
	mov	cl, ds:[di].DSSE_dsFlags
	and	cl, (mask DSEF_lockCount)
EC<	tst	cl							>
EC<	ERROR_Z BAD_LOCK_COUNT						>

	;Only release the lock if this is the topmost call of nested
	;lock calls, which happens when the lock count is one.

	dec	cl
	dec	ds:[di].DSSE_dsFlags
	tst	cl
	LONG jnz exit			;need to call unlock again

	;Get the DataStore Element and flags

	mov	ax, ds:[di].DSSE_dsToken
	mov	si, ds:[MLBH_dsElementArray]
EC<	call	ECCheckChunkArray					>
	call	ChunkArrayElementToPtr	;ds:di DataStore element
EC<	ERROR_C BAD_CHUNK_ARRAY_ELEMENT_NUMBER				>
	mov	cl, ds:[di].DSE_data.DSED_flags
	and	cl, ((mask DSEF_READ_LOCK) or (mask DSEF_WRITE_LOCK))

	;Verify that only one bit is set in the session table.

	mov	bp, di			;ds:bp - datastore element
	mov	di, dx			;ds:di - session element
	cmp	ds:[di].DSSE_dsFlags, mask DSEF_READ_LOCK
	je	readLocked
	cmp	ds:[di].DSSE_dsFlags, mask DSEF_WRITE_LOCK
	je	writeLocked

	;If no flags, okay just means we have not lock, just cause
	;an EC warning and exit.

EC<	tst	ds:[di].DSSE_dsFlags					>
EC<	ERROR_NZ BAD_LOCK_FLAGS						>
EC<	WARNING  UNLOCKDATATSTORE_CALLED_WITH_NO_LOCK			>
	jmp	exit			;no lock held, exit
 
readLocked:

	;Make sure the DataStore lock type is the same

	cmp	cl, mask DSEF_READ_LOCK
EC<	ERROR_NE BAD_LOCK_FLAGS						>
				
	;Decrement the read lock count and check if it went to 0

	mov	di, bp			;ds:di - datastore element
	mov	ch, ds:[di].DSE_data.DSED_flags
	and	ch, mask DSEF_lockCount ;lowest bits, no need to shift
EC<	tst	ch							>
EC<	ERROR_Z BAD_LOCK_COUNT					>
	dec	ch			;ch - number of read locks
	dec	ds:[di].DSE_data.DSED_flags
	tst	ch			;number of read locks == 0?
	jnz	resetSessionFlags

	;No read locks left, clear the read lock bit

	and	ds:[di].DSE_data.DSED_flags, (not (mask DSEF_READ_LOCK))
	jmp	resetSessionFlags

writeLocked:

	mov	di, bp			;ds:di - datastore element
	cmp	cl, mask DSEF_WRITE_LOCK
EC<	ERROR_NE BAD_LOCK_FLAGS						>

	;Clear the write lock bit in the DataStore element

	and	ds:[di].DSE_data.DSED_flags, (not (mask DSEF_WRITE_LOCK))

resetSessionFlags:

	mov	di, dx			;ds:di - session element
	clr 	ds:[di].DSSE_dsFlags

exit:
	popf				;restore flags
	call	MSUnlockMngrBlockV
	.leave
	ret

DMUnlockDataStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMIndexLockDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a non-blocking grab of the exclusive index
		lock for a datastore. This lock was implemented
		because the DataStore index building routines access
		two HugeArray pointers at a time. If more than one
		thread has two HugeArray blocks locked down than
		deadlock occurs. We don't want to grab a write lock
		because this is overkill for this purpose.
	
	
CALLED BY:	EXTERNAL
PASS:		ax - datstore session token
RETURN:		carry clear if successful

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	10.) Lock the ManagerBlock.
	20.) Get the DSElement index.
	30.) Get the DSElement flags.
	40.) Check if lock is arleady grabbed, if so
             set carry and exit.
	50.) Set the index lock bit, clear carry, and exit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMIndexLockDataStore	proc	far
	uses	ax,bx,cx,si,di,ds
	.enter

	call	MSLockMngrBlockP
	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>

	;Get the session entry from the table
	
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetSessionEntryByDataStoreTokenCallback
	call	ChunkArrayEnum		; ds:dx - session element
EC<	ERROR_NC BAD_SESSION_TOKEN					>

	;Get the DataStore Element and flags

	mov	di, dx			; ds:di -session element
	mov	ax, ds:[di].DSSE_dsToken
	mov	si, ds:[MLBH_dsElementArray]
EC<	call	ECCheckChunkArray					>
	call	ChunkArrayElementToPtr	; ds:di DataStore element
EC<	ERROR_C BAD_CHUNK_ARRAY_ELEMENT_NUMBER				>
	mov	cl, ds:[di].DSE_data.DSED_flags
	and	cl, mask DSEF_INDEX_LOCK
	tst	cl			; lock already in use?
	stc				; failed to get the lock
	jnz 	exit
	or	ds:[di].DSE_data.DSED_flags, mask DSEF_INDEX_LOCK	
	clc

exit:
	call	MSUnlockMngrBlockV
	.leave
	ret

DMIndexLockDataStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMIndexUnlockDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Releases the exclusive index lock for a datastore.

CALLED BY:	EXTERNAL
PASS:		ax - datastore token
RETURN:		nada
DESTROYED:	nothing - flags preserved
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMIndexUnlockDataStore	proc	far
	uses	ax,bx,dx,cx,si,di,ds
	.enter

	pushf
	call	MSLockMngrBlockP
	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>

	;Get the session entry from the table
	
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetSessionEntryByDataStoreTokenCallback
	call	ChunkArrayEnum		; ds:dx - session element
EC<	ERROR_NC BAD_SESSION_TOKEN					>

	;Get the DataStore Element and flags

	mov	di, dx			; ds:di -session element
	mov	ax, ds:[di].DSSE_dsToken
	mov	si, ds:[MLBH_dsElementArray]
EC<	call	ECCheckChunkArray					>
	call	ChunkArrayElementToPtr	; ds:di DataStore element
EC<	ERROR_C BAD_CHUNK_ARRAY_ELEMENT_NUMBER				>
	mov	cl, ds:[di].DSE_data.DSED_flags
EC<	and	cl, mask DSEF_INDEX_LOCK				>
EC<	tst	cl			; lock already in use?		>
EC<	ERROR_Z	-1			; lock bit is not set?      	>
	and	ds:[di].DSE_data.DSED_flags, not (mask DSEF_INDEX_LOCK)

	call	MSUnlockMngrBlockV	
	popf
		
	.leave
	ret
DMIndexUnlockDataStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLockMngrBlockP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Locks the Manager LMem block with HandleP and puts the
		segment in ds.

CALLED BY:	(INTERNAL) Global
PASS:		nothing

RETURN:		ds - segment of LMem block.
		carry clear

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLockMngrBlockP	proc	far
	uses	ax, bx
	.enter

	LoadDGroup ds, bx
	mov	bx, ds:[dsMLBHandle]
EC<	call	ECCheckLMemHandle					>
	call	HandleP
	call	MemLock
EC<	ERROR_C BAD_MANAGER_LMEM_BLOCK					>
 	mov	ds, ax		      	;ds - segment Manager LMem block

	.leave
	ret
MSLockMngrBlockP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSUnLockMngrBlockV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks the global Manager memory block with HandleV.

CALLED BY:	(INTERNAL) Global
PASS:		nothing
RETURN:		nothing - flags preserved

DESTROYED:	ds

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSUnlockMngrBlockV	proc	far
	uses	bx
	.enter
	pushf
	LoadDGroup ds, bx
	mov	bx, ds:[LMBH_handle]
EC<	call	ECCheckLMemHandle					>
	call	HandleV
	call	MemUnlock   	      	;flags preseved
	popf

	.leave
	ret
MSUnlockMngrBlockV	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMCheckExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a file is opened with exclusive eccess,
		if not, set carry

CALLED BY:	EXTERNAL	
PASS:		ax - dstoken
RETURN:		carry set if no exclusive access
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMCheckExclusive	proc	far
	uses	cx,si,di, ds
	.enter
	call	MSLockMngrBlockP	; ds - segment of manager
					; block
	mov	si, ds:[MLBH_dsElementArray]
EC <	call	ECCheckChunkArray				>
	call	ChunkArrayElementToPtr	; ds:di element
	test	ds:[di].DSE_data.DSED_flags, mask DSEF_OPENED_EXCLUSIVE
	jnz	done
	stc				; has no exclusive
done:
	call	MSUnlockMngrBlockV
	.leave
	ret
DMCheckExclusive	endp

ManagerMainCode ends












