COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	DataStore	
MODULE:		Manager
FILE:		managerAccess.asm

AUTHOR:		Mybrid Spalding, Oct 11, 1995

ROUTINES:
	Name			Description
	----			-----------
EXT	DMIsDataStoreBuffered	Determines if a datastore has any
				records currently buffered.
EXT	MAIsDataStoreBufferedCallback
				ChunkArrayEnum Callback.

EXT	DMGetSessionBufferHandle
				Returns the buffer handle for a given
				datastore. See DMLockDataStore for 
				getting the buffer handle with
				synchronization.

EXT	MAGetSessionEntryByFileTokenCallback
				Returns pointer to DSSession entry
				given a DSElement token.
EXT	MAGetSessionEntryByDataStoreTokenCallback
				Returns pointer to DSSession entry
				given a datastore token.

EXT	DMGetSessionDataStoreName	
				Given a datastore token, returns the 
				file/datastore name.

EXT	DMGetSessionRecordID	Given a datastore token, returns the
				record id in from the session table.

EXT	DMGetRecordDataStoreToken
EXT	MAGetRecordDataStoreTokenCallback
				Returns the datastore token for 
				a record.


EXT	MAGetDSElementTokenCallback
				Returns the datastore file token.
EXT	MAGetDSElementFlags
				Returns the datastore flags. 


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/11/95   	Initial revision


DESCRIPTION:
	The DataStore Manager common routines which access the DataStore
structures in the Manager memory block--except those routines used for
synchnronization and those routines are in managerSynch.asm.

	$Id: managerAccess.asm,v 1.1 97/04/04 17:53:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ManagerMainCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMIsDataStoreBuffered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Predicate that returns true if there are any records
		in the session table in a record buffer for the passed
		datastore file handle.

CALLED BY:	(EXTERNAL) Global
PASS:		bx - datastore file handle
		
RETURN:		if carry set, true - there are buffered records for
		the file.

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	10) Lock the Manager block.
	15) Get the datastore token for the datastore file handle
	20) call DMIsDataStoreBufferedCallback to enum through
            the whole table.
	30) Unlock the Manager block.
	40) Return the results from the call back.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMIsDataStoreBuffered	proc	far
	uses	ax,cx,bx,si,di,ds
	.enter

EC<	call	ECCheckFileHandle					>

	call	MSLockMngrBlockP
	mov	si, ds:[MLBH_dsElementArray]
	mov	cx, bx			;cx - datastore file handle
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetDSElementTokenCallback
	call	ChunkArrayEnum		
EC<	ERROR_NC BAD_DATASTORE_FILE_HANDLE				>
	
	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>
	mov	bx, SEGMENT_CS
	mov	di, offset MAIsDataStoreBufferedCallback
	call	ChunkArrayEnum		

	call	MSUnlockMngrBlockV	;flags preserved
	.leave
	ret
DMIsDataStoreBuffered	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAIsDataStoreBufferedCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Predicate which returns true (halting the enum) if 
		the record buffer is not empty and the datastore token
		matches the passed token.

CALLED BY:	DMIsDataStoreBufferedCallback
PASS:		ax - datastore file token to match
		*ds:si	- session array
		ds:di	- session element

RETURN:		carry set if datastore file token matched and buffer 
		not empty.

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	10) compare tokens and exit false if unequal
	20) test for EMPTY_BUFFER_ID and return false if found
	30) exit true	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAIsDataStoreBufferedCallback	proc	far
	.enter

	cmp	ax, ds:[di].DSSE_dsToken
	clc				;return false
	je	tokenMatch

exit:
	.leave
	ret

tokenMatch:
	cmpdw	ds:[di].DSSE_recordID, EMPTY_BUFFER_ID
	clc				;return false
	je	exit
	stc				;return true, stop enum
	jmp	exit

MAIsDataStoreBufferedCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGetSessionEntryByFileTokenCallback	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if this client already has a session for this
		DataStore by using the Geode thread number and
		DSElement datastore file token.	
		
		!!WARNING!! This callback makes the assumption that
		only ONE session can exist per Geode per datastore
		file. If every multiple sessions can exist for the
		same Geode for the same file, this code won't work.
		Use MAGetSessionEntryByDataStoreTokenCallback instead. 
	

CALLED BY:	MDDataStoreOpenWithFileHandle (via ChunkArrayEnum)
PASS:		*ds:si - Session array
		ds:di - session element
		^hcx - client geode
		ax - DSElement datastore file token
RETURN:		carry set if match found,
		ds:dx - matching element
		ax - matching element token

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	10.) Check and make sure the Geode calling owns the session
	     entry.
	20.) Check the datastore file tokens, if equal return
	     the element.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/24/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAGetSessionEntryByFileTokenCallback		proc	far
		.enter

		cmp	cx, ds:[di].DSSE_client
		jne	continue
		cmp	ax, ds:[di].DSSE_dsToken
		je	found
continue:
		clc
exit:
		.leave
		ret
found:
		stc
		mov	dx, di			; return element in ds:dx
		jmp	exit
MAGetSessionEntryByFileTokenCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGetSessionEntryByDataStoreTokenCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the session element using the datastore token.

CALLED BY:	MDDataStoreOpenWithFileHandle (via ChunkArrayEnum)
PASS:		*ds:si - Session array
		ds:di - session element
		ax - datastore session token
RETURN:		carry set if match found,
		ds:dx - matching element
		ax - matching element number

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	10.) Compare the session entry datastore token with the passed
	     token, if they are the same return the element pointer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/24/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAGetSessionEntryByDataStoreTokenCallback	proc	far
		.enter

		cmp	ax, ds:[di].DSSE_session
		je	found
		clc
exit:
		.leave
		ret
found:
		mov	dx, di			; return element in  ds:dx
		stc
		jmp	exit

MAGetSessionEntryByDataStoreTokenCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMGetSessionDataStoreName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a session datastore token fills a given buffer
		with the datastore name. Assumes the passed buffer is at
		least of size (FILE_LONGNAME_LENGTH + 1).

CALLED BY:	(EXTERNAL) Global
PASS:		ax - datastore session token
		es:di - pointer to buffer for name

RETURN:		if session token found carry set
			es:di - session datastore name.

DESTROYED:	nothing provable
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	10) Lock the Manager block
	20) Use callback to get the session entry for the datastore
	    token, exit if bad token.
	30) Using the ChunkArrayElementToPtr for the DSElement number 
	    in the session entry, copy the name into es:di.
	40) Unlock the Manager block


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMGetSessionDataStoreName	proc	far
	uses	ax,bx,cx,dx,si,di,ds
	.enter

	call	MSLockMngrBlockP
	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>

	;Get the session entry from the table

	push	di
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetSessionEntryByDataStoreTokenCallback
	call	ChunkArrayEnum		;ds:dx - session element
	mov	si, dx			;ds:si - session element
	pop	dx
	cmc
	jc	exit			;return error

	;Get the datastore element from the table
	
	mov	ax, ds:[si].DSSE_dsToken
	mov	si, ds:[MLBH_dsElementArray]
EC<	call	ECCheckChunkArray					>
	call	ChunkArrayElementToPtr	;ds:di = element, cx = size
EC<	ERROR_C BAD_CHUNK_ARRAY_ELEMENT_NUMBER				>

	;Copy the name, null terminate it and then boogie
	
	mov	si, di			;ds:si datastore element
	mov	di, dx			;es:di buffer for name
	Assert	buffer esdi, FILE_LONGNAME_LENGTH+1
	add	si, offset DSE_name	;ds:si pointer to name
	sub	cx, offset DSE_name	;cx = size of name, w/o null

	rep	movsb
	mov	ax, 0
	LocalPutChar esdi, ax
	clc

exit:
	call	MSUnlockMngrBlockV	
	.leave
	ret
DMGetSessionDataStoreName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMGetSessionRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the record id of the current record 
		of the given session. 

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		if carry set, bad token
		else dxax - record id

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		10.) Lock the Manager block
		15.) Get the session entry for the datastore token
		20.) Find the session for the token
		30.) return the record id

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMGetSessionRecordID	proc	far
	uses	bx,cx,si,ds,di
	.enter

	call	MSLockMngrBlockP
	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>

	;Get the session entry from the table
	
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetSessionEntryByDataStoreTokenCallback
	call	ChunkArrayEnum		;ds:dx - session element
	cmc
	jc	exit			;return error

	mov	si, dx			;ds:si - session element
	movdw	dxax, ds:[si].DSSE_recordID

exit:
	call	MSUnlockMngrBlockV
	.leave
	ret
DMGetSessionRecordID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMGetRecordDataStoreToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a datastore file handle and record id returns
		the datastore token for the session with the record
		in the buffer. Assumes that a record can be in at
		most one session buffer at a time.

CALLED BY:	(EXTERNAL) Global
PASS:		^hbx - datastore file handle
		dxcx - record id
	
RETURN:		carry set if record found 
			ax - datastore token
		else carry clear,
			ax - preserved
					
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	10) Lock the Manager Block.
	20) Get the datstore file token for the file handle.
	30) Use MAGetSessionDataStoreTokenByRecordIdCallback to
	    retrieve the datastore token.
	40) Unlock the Manager block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMGetRecordDataStoreToken	proc	far
	uses	bx,cx,si,di,ds
	.enter

EC<	call	ECCheckFileHandle					>
	call	MSLockMngrBlockP
	mov	si, ds:[MLBH_dsElementArray]
EC<	call	ECCheckChunkArray					>

	;Get the DSElement token for the datastore file handle since
	;the session entry stores the file token and not the file handle.

	push	ax, cx
	mov	cx, bx			;^hcx - datastore file handle
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetDSElementTokenCallback
	call	ChunkArrayEnum
EC<	ERROR_NC BAD_DATASTORE_FILE_HANDLE				>

	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>
	mov	bx, SEGMENT_CS
	pop	cx
	mov	di, offset MRFindRecordInBufferCallback
	call	ChunkArrayEnum
	mov	di, ax
	pop	ax			;ax - original
	jnc	exit			;found match return token in ax

	mov	ax, ds:[di].DSSE_session

exit:	
	call	MSUnlockMngrBlockV	;flags preserved

	.leave
	ret
DMGetRecordDataStoreToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGetDSElementTokenCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a file handle returns the datastore file token.

CALLED BY:	DMIsDataStoreBufferedCallback
PASS:		cx - datastore file handle
		*ds:si - DSElement array
		ds:di - datastore file element

RETURN: 	if carry set, file handle match found
			ax - datastore DSElement token
		else
			no match found

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	10) If file handles equal, put token in ax and exit set carry
	20) exit clear carry 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAGetDSElementTokenCallback	proc	far
	.enter
	
	cmp	cx, ds:[di].DSE_data.DSED_fileHandle
	clc
	jne	exit
	call	ChunkArrayPtrToElement	;ax - token
	stc
exit:	
	.leave
	ret
MAGetDSElementTokenCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGetDSElementFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the DSElementFlags from the DSElement structure.

CALLED BY:	(INTERNAL) MMLockDataStoreCommon
PASS:		ds:di - session entry element
		

RETURN:		ch - lock count
		cl - lock bits
		ds:di - datastore file element

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	10.) Get the datastore file token for the session entry.
	20.) Get the pointer to the DSElement. 
	30.) mask the lock bits and lock count into the appropriate
	     place.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAGetDSElementFlags	proc	far
	uses	ax,si
	.enter
	;Get the flags from the DSElement array

	mov	ax, ds:[di].DSSE_dsToken
	mov	si, ds:[MLBH_dsElementArray]
EC<	call	ECCheckChunkArray					>
	call	ChunkArrayElementToPtr	;ds:di element
EC<	ERROR_C BAD_CHUNK_ARRAY_ELEMENT_NUMBER				>
	mov	cl, ds:[di].DSE_data.DSED_flags
	and	cl, ((mask DSEF_READ_LOCK) or (mask DSEF_WRITE_LOCK))
	mov	ch, ds:[di].DSE_data.DSED_flags 
	and	ch, mask DSEF_lockCount	;ch - DSED_lockCount

	.leave
	ret
MAGetDSElementFlags	endp

ManagerMainCode ends







