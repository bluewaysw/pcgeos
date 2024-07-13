COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	DataStore	
MODULE:		Manager
FILE:		managerRecord.asm

AUTHOR:		Mybrid Spalding, Oct 11, 1995

ROUTINES:
	Name			Description
	----			-----------
EXT	DataStoreLoadRecord	API routine stub which calls MMLoadRecordCommon
EXT	DataStoreLoadRecordNum	API routine stub which calls MMLoadRecordCommon
EXT	DMSetNewRecord		Puts a new record in a session.
INT	MRLoadRecordCommon	Loads a record for the API routines
				using a record id or record number.
EXT	MRFindRecordInBufferCallback
				Checks to see of a datastore record is
				already being used in another session's
				record buffer.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/11/95   	Initial revision


DESCRIPTION:
	DataStore API and Manager routines for the DataStoreManager
that deal with accessing datastore records.

	$Id: managerRecord.asm,v 1.1 97/04/04 17:53:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ManagerMainCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreLoadRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the passed record id into the session's record
		buffer and makes it the current record via
		MRLoadRecordCommon.  
		
CALLED BY:	(EXTERNAL) GLOBAL
PASS:		ax - datastore session token
		dx.cx - record id 

RETURN:		ax - DataStoreError
		carry set if error,
			dx.cx - preserved
		carry clear if no error, 
			dx.cx - record number
			ax - DSDE_NO_ERROR

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

	See MRLoadRecordCommmon for complete details.

	!!WARNING!! The local variables are inherited by MRLoadRecordCommon.
	DataStoreLoadRecordNum also calls out to MRLoadRecordCommon
	and thus local variables for these two routines need to be
	IDENTICAL in order for MRLoadRecordCommon to inherit local 
	variables correctly.
		
	10) Lock the Manager block.
	15) Grab the DataStore lock for read only, exit on failure.
	20) Call MSLockDataStoreCommon.
	30) Call MRLoadRecordCommon which release the DataStore lock
	    and unlocks the Manager block.
	40) Unlock the Manager block if a lock error occurred.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreLoadRecord	proc	far
	loadDSToken	local	word	push	ax
	loadRecordNum	local	dword	
	loadRecordID	local	dword	
	loadFlag	local	word
	ForceRef	loadDSToken
	ForceRef	loadRecordNum
	uses	bx,si,di,ds
	.enter

	movdw	loadRecordID, dxcx
	call	MSLockMngrBlockP	;ds - Manager Block segment
	mov	si, dx			;sicx - record id
	mov	di, ax			;di - datastore token
	mov	bl, mask DSEF_READ_LOCK	
	call	MSLockDataStoreCommon
	LONG jc	lockError		;ax - DataStoreError ...or...
					;bx - file handle
					;ds:dx - session element
	mov	ax, di			;ax - datastore token
	mov	di, dx			;ds:di - session element
	mov	loadFlag, LOAD_RECORD_WITH_ID
	call	MRLoadRecordCommon	;does most of the work.
					;Unlocks Manager Block
	movdw	dxcx, loadRecordID
	jc	exit
	movdw	dxcx, loadRecordNum
exit:
	.leave
	ret

lockError:
	call	MSUnlockMngrBlockV	
	jmp	exit

DataStoreLoadRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreLoadRecordNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the passed record number into the session's record
		buffer and makes it the current record. Returns the
		record number's record id.
		

CALLED BY:	(EXTERNAL) GLOBAL
PASS:		ax - datastore session token
		dx.cx - record num

RETURN:	        ax - DataStoreError
		if carry clear:
		   dx.cx - record id
		   ax - DSDE_NO_ERROR

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

	See MRLoadRecordCommon for complete details.

	!!WARNING!! The local variables are inherited by MRLoadRecordCommon.
	DataStoreLoadRecord also calls out to MRLoadRecordCommon
	and thus local variables for these two routines need to be
	IDENTICAL in order for MRLoadRecordCommon to inherit local 
	variables correctly.

	10) Lock the Manager block.
	10) Grab the datastore lock for read only, return error if
	    unable to (non-blocking).
	15) Call DFRecordNumToID to get the record id for the passed
	    record num.
	17) Exit and return any error from DFRecordNumToID
	20) Call MSLockDataStoreCommon for read only.
	30) Call MRLoadRecordCommon
	40) Unlock the Manager block if a lock error occurred.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreLoadRecordNum	proc	far
	loadDSToken	local	word	push	ax
	loadRecordNum	local	dword	push 	dx, cx
	loadRecordID	local	dword
	loadFlag	local	word	
	ForceRef	loadDSToken
	uses	bx,si,di,ds
	.enter

	call	MSLockMngrBlockP	;ds - Manager Block segment
	mov	bl, mask DSEF_READ_LOCK
	call	MSLockDataStoreCommon
	jc	error			;ax - DataStoreError ...or...
					;bx - file handle
					;ds:dx - session element

	call	MSUnlockMngrBlockV

	;Convert the record number to a record id
	mov	ax, loadDSToken
	movdw	dxcx, loadRecordNum
	call	DFRecordNumToID		;dxcx - record id
	mov	ax, DSDE_INVALID_RECORD_NUMBER
	jc	errorLock
	movdw	loadRecordID, dxcx	


	call	MSLockMngrBlockP	;ds - Manager Block segment
	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>

	;Get the session entry from the table
	
	push 	bx
	mov	ax, loadDSToken
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetSessionEntryByDataStoreTokenCallback
	call	ChunkArrayEnum		;ds:dx - session element
	cmc
	pop 	bx
EC<	ERROR_C	BAD_DATASTORE_TOKEN					>

	mov	di, dx			; ds:di - session element
	mov	loadFlag, LOAD_RECORD_WITH_NUM
	call	MRLoadRecordCommon	;does most of the work.
					;Unlocks Manager Block and DataStore

	;if no error was returned, return dx.cx as the record id
	;otherwise restore dx.cx to record number,

	movdw	dxcx, loadRecordID	
	jnc	exit
recordNum:
	movdw	dxcx, loadRecordNum
exit:
	.leave
	ret

errorLock:
	xchg	ax, loadDSToken
	call	DMUnlockDataStore
	xchg	ax, loadDSToken		; ax - datastore error
	jmp	recordNum

error:
	call	MSUnlockMngrBlockV
	jmp	recordNum

DataStoreLoadRecordNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRLoadRecordCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the passed record id record data from the
		datastore file into the session's record buffer and 
		makes it the current record. 

CALLED BY:	(EXTERNAL) GLOBAL
PASS:		loadDSToken	- datastore token
		loadRecordNum	- record number
		loadRecordID	- record id
		loadFlag	- LOAD_WITH_RECORD_ID or LOAD_WITH_RECORD_NUM
		bx - datastore file handle
		ds:di - session element for datastore token in ax
		manager LMem block locked

RETURN:		carry set if error
			ax - DataStoreError
		else
			ax - DSDE_NO_ERROR

DESTROYED:	bx, dx, di,ds
SIDE EFFECTS:	
		Unnlocks the Manager block 
		Releases the datastore read only lock.

PSEUDO CODE/STRATEGY:
	20) Check if the session entry has a record in its buffer
	    If so, unlock manager block and return an error.
	30) Check if the record is curently in use by another
	    datastore. If so, unlock manager block and return an error.
	33) Unlock the Manager block.
	40) Call DFReadRecord or DFReadRecordNum depending on the
	    loadFlag to read the record data into a new buffer that
	    gets created by DFReadRecord/DFReadRecordNum. 
	50) Call DMUnlockDataStore to release the datastore file lock.
	60) Return any error that occured in DFReadRecordID.
	65) Lock the Manager Block.
	66) Call DMSetNewRecord to make the new buffer handle returned
	    by DFReadRecord/DFRecordRecordNum the new record for the
	    session.
	90) If returning an error before a call to
	    DFReadRecord/DFReadRecordNum unlock the Manager block and
	    release the DataStore file lock.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRLoadRecordCommon	proc	near
	uses	cx,si
	.enter	inherit DataStoreLoadRecord

EC <	call	ECCheckFileHandle					>

	; See is this session already has a record in its buffer.
	; If so, it may not load another.
		
	mov	ax, DSDE_RECORD_BUFFER_NOT_EMPTY
	cmpdw	ds:[di].DSSE_recordID, EMPTY_BUFFER_ID
EC<	WARNING_NE DATASTORE_LOAD_OR_CLOSE_CALLED_WITHOUT_EMPTY_BUFFER	>
	stc
	LONG_EC	jne bufError
		
	; See if the desired record has already been loaded by someone else
	
	push	bx, di
	mov	ax, ds:[di].DSSE_dsToken
	movdw	dxcx, loadRecordID
	mov	bx, SEGMENT_CS
	mov	di, offset MRFindRecordInBufferCallback
	mov	si, ds:[MLBH_sessionArray]
	call	ChunkArrayEnum		;carry set, if found
	pop	bx, si			;ds:si - session entry for ax

	;The following line reserves the record id in case of 
	;a context switch before the record id is set in
	;DMSetNewRecord and thus is needed for synchronization.

	movdw	ds:[si].DSSE_recordID, dxcx
	mov	ax, DSDE_RECORD_IN_USE
	call	MSUnlockMngrBlockV	;flags preserved
	jc	recError	

	;If the load is being done using the record number it is a
	;direct lookup in the datastore file. The load using a record
	;id has to look through the entire datastore file. Therefore
	;call the appropriate DFRead routine depending on the passed type.

	mov	di, loadFlag
	cmp	di, LOAD_RECORD_WITH_ID
	je	readID
EC<	cmp	di, LOAD_RECORD_WITH_NUM				>
EC<	ERROR_NE -1							>
	movdw	dxax, loadRecordNum
	call	DFReadRecord
	jmp	continue
readID:
	movdw	dxax, loadRecordID
	call	DFReadRecordFromID	;^hax - new buffer block
	movdw	loadRecordNum, dxcx	; save record number
continue:
	jc	recError		; return error from reading	
	mov	bx, ax			;^hbx - buffer handle
	mov	ax, loadDSToken
	movdw	dxcx, loadRecordID
	call	DMSetNewRecord
EC<	ERROR_C CORRUPTED_DATASTORE_TOKEN_IN_DATASTORELOADRECORD 	>
	mov	ax, DSDE_NO_ERROR	;return no error, carry is clear
exit:
	xchg	ax, loadDSToken		
	call	DMUnlockDataStore	;flags preserved
	xchg	ax, loadDSToken		

	.leave
	ret

bufError:
	call	MSUnlockMngrBlockV	;flags preserved
	jmp	exit

	; At this point the record id has been reserved in the session
	; entry but an error occured before the record could be read into
	; the session's record buffer. Therefore, the session's record
	; buffer record id needs to be reset to an EMPTY_BUFFER_ID. 
	; The Manager block has been unlocked so use DMSetNewRecord.

recError:
	xchg	ax, loadDSToken		; loadDSToken - error code
	mov	bx, 0			; buffer handle to null
	movdw	dxcx, EMPTY_BUFFER_ID	; reset record id to empty.
	call	DMSetNewRecord		; reset buffer to empty record
EC<	ERROR_C CORRUPTED_DATASTORE_TOKEN_IN_DATASTORELOADRECORD 	>
	xchg	ax, loadDSToken		; ax - error code
	stc				; return error code in ax
	jmp	exit

MRLoadRecordCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRFindRecordInBufferCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks whether this session has the passed record from
		the passed datastore in its buffer.

CALLED BY:	(INTERNAL) DataStoreLoadRecord
PASS:		*ds:si - Session array
		ds:di - session element
		ax - DSElement token 
		dx.cx - record id to check

RETURN:		carry clear, 
		   no match, ax preserved
		else
		   ds:ax - session element ptr

DESTROYED:  nada

PSEUDO CODE/STRATEGY:
	05) if this session has no record in the record buffer, continue
	10) compare the passed dsToken with this session's dsToken
	12) if not equal, continue enumeration
	14) compare the passed recordID with this session's recordID
	16) if not equal, continue enumeration
	20) if dsTokens and RecordIDs are equal, stop enumeration
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	A record may be loaded by only one session at a time, so it
	should never be in two session elements at a time, and we
	can stop enumerating after we find the first match.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/24/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRFindRecordInBufferCallback		proc	far
	uses	bx
	.enter

	cmpdw	ds:[di].DSSE_recordID, EMPTY_BUFFER_ID
	je	notFound
	cmp	ax, ds:[di].DSSE_dsToken
	jne	notFound
	cmpdw	dxcx, ds:[di].DSSE_recordID
	jne	notFound
	;
	; We have to check for false positives here - if the buffer
	; contains a new record, the recordID is not yet valid.
	; Lock the record block and get the flags.
	;
	mov	bx, ds:[di].DSSE_buffer
	call	DSGetBufferRecordFlags
	test	al, mask BF_NEW_RECORD
	jnz	notFound
		
	mov	ax, di			;ds:ax - session element
	stc				;match found
	jmp	exit
	
notFound:
	clc				;keep searching
exit:
	.leave
	ret
MRFindRecordInBufferCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMSetNewRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the session entry to a new current record. 
		If the existing buffer handle is empty, set the new handle 
		and the	new record id. Otherwise free the previous block buffer
		LMem block, and then set the new handle and new record id. 

		!!WARNING!! 
		This routine assumes that the current record is NOT 
		locked and NOT modified. This is the responsiblity of 
		the caller.
	
CALLED BY:	Global
		ax - session token
		bx - buffer handle
		dx.cx - record id of record in buffer handle

RETURN:		carry set, if bad datastore session token
		else nada

DESTROYED:	nada

SIDE EFFECTS:	Frees the LMem block of the previous
		record buffer.

PSEUDO CODE/STRATEGY:
	10.) Lock the Manager block.
	20.) Find the session for the token.
	30.) If the existing buffer handle is not null, EC Verify that
	     the previous buffer record id is the same as that in the 
	     session array. 		
	40.) If the existing buffer handle is not null, free the Mem
	     block.
	50.) Set the session entry record id to the new record id.
	60.) Set the session entry buffer to the new buffer.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMSetNewRecord	proc	far
	uses	ax,bx,cx,dx,si,bp,di,ds
	.enter

EC <	tst	bx							>
EC <	jz	continue						>
EC <	call	ECCheckMemHandle					>
EC < continue:								>

	call	MSLockMngrBlockP	;ds - Manager segment
	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>

	push	dx			;save new record id
	mov	bp, bx			;^hbp - new buffer handle
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetSessionEntryByDataStoreTokenCallback
	call	ChunkArrayEnum		;ds:dx - session element
	mov	di, dx			;ds:di - session element
	pop	dx			;dx.cx - new record id
	cmc
	jc	exit			;return error

	;If the session buffer is not empty, free the old buffer.

	tst	ds:[di].DSSE_buffer	;Emtpy buffer handle?		>
	jz	emptyBuffer

	mov	bx, ds:[di].DSSE_buffer ;bx - old buffer handle
EC <	call	DSGetBufferRecordFlags					>
EC <	test	al, mask BF_MODIFIED_IN_BUFFER or mask BF_LOCKED	>
EC <	ERROR_NZ ERROR_CORRUPTED_RECORD_BUFFER				>
		
	call	MemFree	

emptyBuffer:

	mov	ds:[di].DSSE_buffer, bp
 	movdw	ds:[di].DSSE_recordID, dxcx
EC<	mov	bx, bp			;bp - buffer handle		>
EC<	tst_clc	bx							>
EC<	jz	exit							>
EC<	call	DSGetBufferRecordID 					>
EC<	cmpdw	dxcx, ds:[di].DSSE_recordID				>
EC<	ERROR_NE ERROR_CORRUPTED_RECORD_BUFFER				>
	clc				;return no error

exit:
	call 	MSUnlockMngrBlockV
	.leave
	ret
DMSetNewRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreDiscardRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discards the current record from the session's record
		buffer. It is an error to discard a locked record.

CALLED BY:	(EXTERNAL) GLOBAL
PASS:		ax - datastore token
RETURN:		ax - DataStoreDataError
		if carry set - error occured

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	10) Lock the Manager block
	20) Get the session entry for the token and return any error.
	30) If null handle return and error.
	40) Get the session buffer record's flags.
	50) If the record is locked, return an error.
	60) Free the buffer memhandle, which discards the record.
	70) Set the session buffer handle to null.
	    Note that the record id still reflects the old record
	    value. Therefore, ALWAYS check the record buffer
	    being null to make sure the current buffer is not empty.
	80) Unlock the Manager block, clear carry and exit with no error.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreDiscardRecord	proc	far
	uses	bx,cx,dx,si,di,bp,ds
	.enter

	call	MSLockMngrBlockP
	mov	si, ds:[MLBH_sessionArray] ;*ds:si - session array
	mov	bx, SEGMENT_CS		
	mov	di, offset MAGetSessionEntryByDataStoreTokenCallback
	call	ChunkArrayEnum		;ds:dx - session element
	mov	di, dx			;ds:di - session element
	mov	ax, DSDE_INVALID_TOKEN
	jnc	error			;return error

	;If no record in buffer than return an error. 

	cmpdw	ds:[di].DSSE_recordID, EMPTY_BUFFER_ID
	mov	ax, DSDE_RECORD_BUFFER_EMPTY
	je	error

	;Get the current record's flags and check if it is locked.
	;If it is, return and error.

	mov	bx, ds:[di].DSSE_buffer	;^hbx - datastore file
EC<	call	ECCheckMemHandle					>
	call 	DSGetBufferRecordFlags	;ax - BufferFlags
	and	ax, mask BF_LOCKED
	tst	ax
	mov	ax, DSDE_RECORD_LOCKED
	jnz	error

	;Free the buffer without saving to disk. This discards the
	;record. 

	call	MemFree			;discard the record
	mov	ds:[di].DSSE_buffer, 0	;set buffer pointer to NULL
	movdw	ds:[di].DSSE_recordID, EMPTY_BUFFER_ID
	mov	ax, DSDE_NO_ERROR
	call	MSUnlockMngrBlockV
	clc				;return no error
		
exit:
	.leave
	ret

error:
	call	MSUnlockMngrBlockV	;flags preserved
	stc
	jmp	exit

DataStoreDiscardRecord	endp


ManagerMainCode ends














