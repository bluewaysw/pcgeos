COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994,1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	DataStore
MODULE:		File
FILE:		fileAccess.asm

AUTHOR:		Cassie Hartzog, Oct 10, 1995

ROUTINES:
	Name				Description
	----				-----------
EXT	DFLockRecordNum			Locks a huge array index number
			                and returns the pointer.
EXT	DFUnlockRecordNum		Unlocks a huge array record block.
EXT	DFReadRecord			Reads a record into a block
EXT	DFReadRecordFromID		Reads a record into a block
INT	DFGetNewRecordID		Gets RecordID for a new record
EXT	DFRecordNumToID			Gets RecordID from record number
EXT	DFSaveRecord			Saves the passed record to file
EXT	DFDeleteRecord			Deletes a record based on number
EXT	DFDeleteRecordFromID		Deletes a record based on RecordID
EXT	DFSortCallback			Standard callback for finding
					  record position w/in HugeArray
EXT	DFTruncateRecord		Truncates a record
EXT	DFRecordArrayEnum		Enumerates through th record array.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial revision

DESCRIPTION:
	Contains code to access records in a datastore

	$Id: fileAccess.asm,v 1.1 97/04/04 17:53:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFLockRecordNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a record number, which is an index into the
	        record Huge Array, locks the record and returns 
		the pointer.

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore
		dx.ax - index of record to lock

RETURN:		carry set if error
		else
			ds:si - record pointer
			dx - size of record huge array element

DESTROYED:	nothing
SIDE EFFECTS:	Locks a HugeArray block on the heap.
		Be very careful not to cause deadlock by calling this
		routine more than twice without unlocking a block,
		otherwise deadlock can happen.
	
	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFLockRecordNum	proc	far
	uses	ax,cx,di
	.enter
	
		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock	 ; di <- record array block
EC <		call	ECValidateDataStore				>
	;
	; Lock down the record data in the huge array
	;
		call	HugeArrayLock		; ds:si <- element,
						; dx <- size of element
		tst	ax			; If ax = 0, not found
		stc
		jz	exit

EC <		call	ECCheckRecordElement				>

	;
	; Should probably set up some error checking here to insure
	; that the record doesn't get modified.
	; 
	
exit:
		.leave
		ret

DFLockRecordNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFUnlockRecordNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the sptr to the element block returned by
	        DFLockRecordNum, unlocks the record block.

CALLED BY:	
PASS:		ds	- sptr to element block (returned by HugeArrayLock)
RETURN:		nada
DESTROYED:	nothing
SIDE EFFECTS:	Unknown.

		This strategy assumes that DFLockRecordNum and
		DFUnlockRecordNum can be nested like so:

		1sptr = DFLockRecodNum( 1 );
		...do some things with 1sptr...
		2sptr = DFLockRecordNum( 2 );
		...do some things with 1sptr & 2sptr...
		DFUnlockRecordNum( 1sptr );
		...do some things with 2stpr...
		DFUnlockRecordNum( 2sptr );
		
		Where records 1 & 2 are in the same or different 
		HugeArray blocks.

				
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFUnlockRecordNum	proc	far
	.enter

	;
	; Should probably do some error checking here to insure that 
	; that the record has not been modified.
	;
		call	HugeArrayUnlock

	.leave
	ret
DFUnlockRecordNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFReadRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the data for the record corresponding to this
		index from the database into a memory block.

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore
		dx.ax - index of item to get
RETURN:		carry set if error
			ax - DataStoreDataError
				DSDE_RECORD_NOT_FOUND
		else
			^hax - record block
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFReadRecord	proc	far	uses	di
		.enter
		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock	 ; di <- record array block
		call	GetRecordFromIndexCommon ; ax <- record handle
EC <		jc	exit						>
EC <		call	ECCheckRecordBlock				>
EC < exit:								>
		.leave
		ret
DFReadRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFReadRecordFromID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the data for the record corresponding to this
		RecordID from the database into a memory block.

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore
		dx.ax - RecordID

RETURN:		carry set if error
			ax - DataStoreDataError
				DSDE_RECORD_NOT_FOUND
			cx - destroyed
		else	^hax - record block
			dx.cx - record number

DESTROYED:	if error, cx is destroyed
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFReadRecordFromID	proc	far	uses	di
		.enter
		call	FindRecordInDB		;DX.AX <- record index
						;DI <- huge array handle
		jc	notFound
		mov	cx, ax			;return index in dx.cx
		call	GetRecordFromIndexCommon
EC <		jc	exit						>
EC <		call	ECCheckRecordBlock				>
exit:
		.leave
		ret
notFound:
		mov	ax, DSDE_RECORD_NOT_FOUND
		jmp	exit
DFReadRecordFromID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFGetNewRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a RecordID for a new record

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file 
RETURN:		dx.ax - new record ID
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFGetNewRecordID	proc	near	uses	bp, es
		.enter
		call	LockDataStoreMap
		movdw	dxax, es:[DSM_recordID]
		incdw	es:[DSM_recordID]
EC <		cmpdw	dxax, LAST_RECORD_ID 				>
EC <		ERROR_E RECORD_ID_OVERFLOW				>
		call	VMDirty
		call	VMUnlock
;; 		call	DFUpdateDataStore	; VMUpdate the file so that 
						;  the change is written out
		.leave
		ret
DFGetNewRecordID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFDeleteRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a record from the datastore

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
		dx.ax - record index
RETURN:		carry set if error
			ax - DataStoreDataError
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFDeleteRecord	proc	far	
		uses	di
		.enter
		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock	 ; di <- record array block
		call	DeleteRecordCommonAndTrack
		mov	ax, DSDE_RECORD_NOT_FOUND
		jc	notFound
		mov	ax, -1
		call	DFSetRecordCount
		call	DFUpdateDataStore	; carry; ax = DataStoreError

notFound:
		.leave
		ret
DFDeleteRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFDeleteRecordFromID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a record from the datastore based on RecordID

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
		dx.ax - RecordID
RETURN:		carry set if error
			ax = DataStoreDataError
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFDeleteRecordFromID	proc	far
		uses	di
		.enter
	;
	; First see if the RecordID is in use
	;
		call	FindRecordInDB		;DX.AX <- record # to delete
						;DI <- huge array handle
		jc	notFound
		call	DeleteRecordCommonAndTrack
						;carry set if not found
EC <		ERROR_C INVALID_INDEX_VALUE				>
		mov	ax, -1
		call	DFSetRecordCount
		call	DFUpdateDataStore	; carry; ax = DataStoreError
exit:
		.leave
		ret
notFound:
		mov	ax, DSDE_INVALID_RECORD_NUMBER
		jmp	exit
DFDeleteRecordFromID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFRecordNumToID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the RecordID for a given record number

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
		dx.cx - record index
RETURN:		carry set if record not found
		else
			dx.cx - RecordID
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 6/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFRecordNumToID		proc	far
		uses	ax, bx, si, di, ds
		.enter

		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock	 ; di <- record array block
EC <		call	ECValidateDataStore				>
	;
	; Lock down the record data in the huge array
	;
		mov	ax, cx
		call	HugeArrayLock		; ds:si <- element,
						; dx <- size of element
		tst	ax			; If ax = 0, not found
		stc
		jz	exit

EC <		call	ECCheckRecordElement				>
		movdw	dxcx, ds:[si].RH_id
		clc		
		call	HugeArrayUnlock
exit:
		.leave
		ret
DFRecordNumToID		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFSaveRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts the database record in the appropriate place in the
		database. 

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore
		ax - datastore token
		^hdi - record block
		cx:dx - callback to determine what record we should insert
			before, cx = 0 to use standard callback
		bp - data to pass to callback	

		Callback is passed:
			ax - datastore token
			bp - callback data
			es:di - record we are inserting (item 1)
			ds:si - record in database (item 2)
		Return:
			ax < 0 if item1 < item2
			else, ax > 0 (do not return AX = 0)

RETURN:		carry set if error
			ax - DataStoreDataError
		else
			dx.ax - record index 
			bx.cx - record ID

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFSaveRecord	proc	far	
		uses	bp, di, si, es, ds
		callbackData	local	word	push	bp
		dsToken		local	word	push	ax
		callback	local	vfptr	push	cx, dx
		recordPtr	local	fptr
		recordIndex	local	dword
		oldRid		local	dword
		notifType	local	DataStoreChangeType
		.enter

EC <		mov	ax, di						>
EC <		call	ECCheckRecordBlock				>
		mov	notifType, DSCT_RECORD_ADDED

		push	bx
		mov	bx, di
		call	MemLock
		pop	bx
		mov	es, ax
		mov	cl, es:[RLMBH_flags]

		mov	si, es:[RLMBH_record]
		mov	si, es:[si]		;es:si <- RecordHeader
		movdw	ss:[recordPtr], essi
	;
	; check if record id is changed
	;
		test	cl, mask BF_RECORDID_MODIFIED
		jz	ridUnchanged


	;
	; get the record id that is stored in the session table
	; which is DS_NEW_RECORD for new records or the record id
	; for the current record when it is loaded from file
	;
		mov	ax, ss:[dsToken]
		call	DMGetSessionRecordID	; dxax - record id in session
						; table
		movdw	ss:[oldRid], dxax
		cmpdw	dxax, es:[si].RH_id
		LONG	jne	ridChanged
	
ridUnchanged:
		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock	 ; di <- record array block

		test	cl, mask BF_NEW_RECORD
		jz	oldRecord	
		call	DFGetNewRecordID
		movdw	es:[si].RH_id, dxax
		jmp	insert
		
oldRecord:		
		mov	ss:[notifType], DSCT_RECORD_CHANGED

		movdw	dxax, es:[si].RH_id
		call	FindRecordInDB		;dx.ax <- index; di - array
EC <		ERROR_C INVALID_RECORD_ID				>
		movdw	ss:[recordIndex], dxax

	;
	; If none of the primary key fields were modified, we just
	; need to replace this record.
	;
		test	cl, mask BF_PRIMARY_KEY_MODIFIED
		LONG	jz	replace
	;
	; The key has changed, so this record will need to move in the
	; file. First, we delete the record which currently exists in
	; the file, then, we re-add the new record add at the correct
	; position, after we find where that is.
	;
		movdw	dxax, ss:[recordIndex]
		call	DeleteRecordCommon		; don't track 
							; a deletion
							; here!
EC <		ERROR_C INVALID_INDEX_VALUE				>
NEC <		jc	abort						>

		mov	ax, -1
		call	DFSetRecordCount

insert:
	;
	; Now, do a binary search to find out where in the record array
	; we should insert the element. The callback should never return
	; INSERT_EQUAL, so HugeArrayBinarySearch should never return carry set
	;
		movdw	essi, ss:[recordPtr]
		movdw	cxdx, ss:[callback]
		mov	ax, ss:[dsToken]
		push	bp
		mov	bp, ss:[callbackData]
		call	InsertRecordPtr		;dx.ax <- position for the
		pop	bp			; record to be inserted
		movdw	ss:[recordIndex], dxax

noInsert:
		push	bx
		movdw	dxcx, es:[si].RH_id
	;
	; clear BF_NEW_RECORD and modified flags, since the 
	; record is successfully saved
	;
		and	es:[RLMBH_flags], mask BF_LOCKED

		mov	bx, es:[LMBH_handle]
		call	MemUnlock
		pop	bx
		
		call	DFUpdateDataStore	; carry set if error
		jc	abort
	;
	; Send the change notification
	;
		mov	ax, ss:[dsToken]
		mov	bx, ss:[notifType]
		call	DFSendDataStoreNotification

		mov	bx, dx			; bx.cx <- record ID
		movdw	dxax, ss:[recordIndex]	; dx.ax <- record index
EC <		jmp	noValidate					>
		
abort:						
EC <		call	ECValidateDataStore				>
EC < noValidate:							>
		
		.leave
		ret

replace:
		call	ReplaceRecordPtrByIndex
		jmp	noInsert
ridChanged:
		call	SaveWithRidChanged
		jmp	noInsert
		
DFSaveRecord	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveWithRidChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save a record with its record id changed, i.e. the
		current record's id is not the same as the rid stored
		in the session table.

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
		es - segment of record buffer Lmem block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Remove the record in file with the new record id.
	It is ok if there is no record with the new id in file.

 	if the current record is a new record
 	    insert the record
	else  ;; not a new record
 		
 	    if primary key is modified
 		delete old record
 		insert the current record
 	    else 
 		overwrite the old record

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveWithRidChanged	proc	near
	uses	ax, bx, cx, dx, si, di
	.enter inherit DFSaveRecord

EC <	test es:[RLMBH_flags], mask BF_RECORDID_MODIFIED	>
EC <	ERROR_Z	-1						>
	;
	; find the new record id
	;	
	les	si, ss:[recordPtr]	; essi- ptr to record
	movdw	dxax, es:[si].RH_id	; dxax - new record id

EC <	cmpdw ss:[oldRid], dxax					>
EC <	ERROR_E	-1						>


	;
	; delete the record in file with the same id as the new record
	; id, it is possible that this id is not previously used .
	;
	call	DFDeleteRecordFromID
	clc				; continue if record is not found

	test 	es:[RLMBH_flags], mask BF_NEW_RECORD
	jnz	insert			; new record, just insert

	;
	; we are saving an existing record, then check if the 
	; primary key is changed, if this is the case delete
	; the record in file and insert the changed one.
	; 
	mov	ss:[notifType], DSCT_RECORD_CHANGED
	movdw	dxax, ss:[oldRid]
	call	FindRecordInDB		; dxax - index of the record
					; di - array handle
EC <	ERROR_C	INVALID_RECORD_ID			>
	test 	es:[RLMBH_flags], mask BF_PRIMARY_KEY_MODIFIED
	jz	replace
	call	DeleteRecordCommonAndTrack
EC <	ERROR_C	INVALID_RECORD_ID			>
	mov	ax, -1
	call	DFSetRecordCount

insert:
	mov	ax, ss:[dsToken]
	movdw	cxdx, ss:[callback] 
	push	bp
	mov	bp, ss:[callbackData]
	call	InsertRecordPtr		
	pop	bp
	movdw	ss:[recordIndex], dxax
done:
	.leave
	ret

replace:
	call	ReplaceRecordPtrByIndex	
	movdw	ss:[recordIndex], dxax
	jmp 	done

SaveWithRidChanged	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertRecordPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a record to a datastore file and increment 
		the count of records

CALLED BY:	INTERNAL
PASS:		pass: ax - ds token
		^hbx -file
		cxdx - callback
		essi - record ptr
		bp - callback data
RETURN:		dxax - record index
DESTROYED:	bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertRecordPtr	proc	near
	uses	cx,si,di
	.enter

	;
	; Now, do a binary search to find out where in the record array
	; we should insert the element. The callback should never return
	; INSERT_EQUAL, so HugeArrayBinarySearch should never return carry set
	;
		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock	; di- record array 

		call	HugeArrayBinarySearch	;dx.ax <- position for the

		push	ax
EC <		ERROR_NC	CALLBACK_RETURNED_0			>

	;
	; Add the record to the datafile
	;
		mov	cx, es:[si].RH_size
		mov	bp, es			;bp.si <- record to insert
		call	HugeArrayInsert
	;
	; increment the record count
	;
		mov	ax, 1
		call	DFSetRecordCount

		pop	ax
	.leave
	ret
InsertRecordPtr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceRecordPtrByIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a index to a record in a datastore file and 
		replace it with a a given record.
		Note that it is ok if two records have different
		id, this happens when we change a record's id with 
		out changing its primary key field.

CALLED BY:	INTERNAL
PASS:		essi - record ptr
		dxax - record index
		^hbx - file
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceRecordPtrByIndex	proc	near
	uses	cx, di, bp
	.enter


		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock	; di- record array 

EC <	; make sure that key fields have not been modified 		>
EC <		call	ECCompareKeyFields				>
		
		mov	bp, es			;bp.si <- record to insert
		mov	cx, es:[si].RH_size
		call	HugeArrayReplace

	.leave
	ret
ReplaceRecordPtrByIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFTruncateRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Truncates a record by removing the passed number of bytes
		from the end. This is called by the callback to
		DFRecordArrayEnum, when the HugeArray is locked and
		being enumerated, so we must be careful how we modify
		the records, or we will invalidate stored element pointers.

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore handle
		dx:ax - record number
		cx - new record size
RETURN:		
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 8/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFTruncateRecord		proc	far
		uses	cx, si, di, ds
		.enter

		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock	 ; di <- record array block
	;
	; Lock down the requested record. The #consecutive elements
	; before and including this one in this ChunkArray is returned
	; in cx, so this elements number is one less than that.
	;
EC <		pushdw	dxax						>
EC <		push	cx			; save new size		>
EC <		call	HugeArrayLock		; ds:si <- element; dx = size >
EC <		tst	ax			; ax = if not found	>
EC <		ERROR_Z	INVALID_INDEX_VALUE				>
EC <		pop	ax						>
	;
	; Compare new size to old size, to make sure new size is smaller
	;
EC <		cmp	ax, dx 						>
EC <		mov_tr	cx, ax 						>
EC <		ERROR_AE INVALID_TRUNCATE_SIZE				>
EC <		popdw	dxax						>
	;
	; Now truncate the element. Pointers to this element are
	; still valid after doing so.
	;
		call	HugeArrayResize
EC <		call	HugeArrayUnlock 				>
		
		.leave
		ret
DFTruncateRecord		endp


;-------------------------------------------------------------------------
;		Internal routines
;-------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFSortCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Standard primary key sort callback

CALLED BY:	GLOBAL (via HugeArrayBinarySearch), DFSaveRecord

PASS:		es:di -	rec1 (record to insert)
		ds:si - rec2 (record in datastore)
		^hbx - datastore file

RETURN:		ax - -1 if rec1 should come before rec2
		      1 if rec1 should come after rec2
		bx - same as ax, except that if their key fields
			match exactly, return bx = 0
DESTROYED:	bp, di, ds, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFSortCallback		proc	far

		rec1		local	fptr	push	es, di
		rec2		local	fptr	push	ds, si
		dsHandle	local	hptr	push	bx
		fieldData	local	FieldData
		ForceRef	rec1
		ForceRef	rec2
		ForceRef	dsHandle
		ForceRef	fieldData
		uses	cx, dx
		.enter

	;
	; Enumerate over the key fields, comparing the data for
	; those fields in the two records to find which comes first
	;
		call	LockFieldNameElementArray
		mov	bx, SEGMENT_CS
		mov	di, offset PrimaryKeyCallback
		call	ChunkArrayEnum
		call	VMUnlockDS
	;
	; PrimaryKeyCallback may return 0, if key fields are exactly equal.
	; In that case, we will return INSERT_BEFORE instead, to ensure that
	; HugeArrayBinarySearch is deterministic. The original value of
	; ax is returned in bx, so that this routine can be used by
	; ECCompareKeyFields.
	;
		mov	bx, ax
		tst	ax
		jnz	done
		mov	ax, INSERT_BEFORE
done:		
		.leave
		ret
DFSortCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrimaryKeyCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if field defined by this element is part of the
		primary key, and if so, compare the data in this field
		in the passed records.

CALLED BY:	DFSortCallback (via ChunkArrayEnum)
PASS:		ds:di - FieldNameElement
		bp - stack frame ptr 
		ax - element size
RETURN:		ax - same as in DFCompareFields
DESTROYED:	bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	Primary key fields are added when the datastore is created
	and cannot be deleted. Therefore, they will be contiguous
	elements in the name array, and the first free element or
	non-key element signifies that there are no more keys.

	There is one exception to this rule, however, and that is
	the timestamp field, which is automatically added when
	the datastore is created. It is the first field in the datastore,
	and cannot be deleted.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	cassie		10/17/95	Initial version
	tgautier	 2/19/97	Add modification tracking

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrimaryKeyCallback		proc	far
		uses	ds, es
		.enter inherit DFSortCallback
	;
	; If this is a free element, or is not a primary key field,
	; stop enumerating.
	;
		cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
		LONG_EC	jz	stop
	;
	; If this the first field, it might be a timestamp field, 
	; and key fields will follow, so continue enumerating.
	;
		call	ChunkArrayPtrToElement		; ax <- FieldID
EC <		tst	ah						>
EC <		ERROR_NZ INVALID_FIELD_ID				>
		mov	dl, al
		tst	dl
		jnz	notTimeStampField
	;
	; If the first field is a timestamp field, && the
	; (DSF_TIMESTAMP or DSF_TRACK_MODS) flag is set, this is the 
	; internal datastore's timestamp field, which is not part of the key.
	;
		cmp	ds:[di].FNE_data.FD_type, DSFT_TIMESTAMP
		jne	notTimeStampField

		mov	bx, ss:[dsHandle]		;^hbx <- datastore
		call	DFGetFlags			; ax <- DataStoreFlags
		test	ax, mask DSF_TIMESTAMP or mask DSF_TRACK_MODS
		jnz	continue

notTimeStampField:
		mov	al, ds:[di].FNE_data.FD_flags
		test	al, mask FF_PRIMARY_KEY
		jz	keysEqual
	;
	; Save the FieldData in our local structure
	;
		mov	ss:[fieldData].FD_flags, al
		mov	al, ds:[di].FNE_data.FD_type
		mov	ss:[fieldData].FD_type, al
	;
	; Get ptrs to field data for this field in each record
	;
		mov	bx, ss:[dsHandle]
		lds	si, ss:[rec2]		; ds:si <- RecordHeader
		call	DSGetFieldPtrCommon	; ds:di <- field data,
						;    cx <- field size,
						;    dh <- DataStoreFieldType
EC <		jnc	okay1						>
EC <		cmp	ax, DSDE_FIELD_DOES_NOT_EXIST			>
EC <		je	okay1						>
EC <		ERROR	INVALID_FIELD_ID				>

EC < okay1:								>
		mov	al, ss:[fieldData].FD_type
EC <		cmp	al, dh						>
EC <		ERROR_NE FIELD_TYPE_MISMATCH				>
		
		push	cx, ds, di
		mov	bx, ss:[dsHandle]
		lds	si, ss:[rec1]		; ds:si <- RecordHeader
		call	DSGetFieldPtrCommon	; ds:di <- field data,
						;    cx <- field size,
						;    dh <- DataStoreFieldType
EC <		jnc	okay2						>
EC <		cmp	ax, DSDE_FIELD_DOES_NOT_EXIST			>
EC <		je	okay2						>
EC <		ERROR	INVALID_FIELD_ID				>

EC < okay2:								>
		mov	al, ss:[fieldData].FD_type
EC <		cmp	al, dh						>
EC <		ERROR_NE FIELD_TYPE_MISMATCH				>

		mov	si, di			;ds:si <- record1
		pop	dx, es, di
	;
	; ds:si - field in record1, cx = size of data
	; es:di - field in record2, dx = size of data
	; al - DataStoreFieldType
	;
		mov	ah, ss:[fieldData].FD_flags
		call	DFCompareFields		; returns ax = 0,-1,1
		tst	ax			; If fields are not equal,
		jnz	stop			;   stop enumeration
continue:		
		clc				; else continue enumeration
done:		
		.leave
		ret

keysEqual:
		clr	ax			; not a key field, recs are =
stop:
		stc
		jmp	done
PrimaryKeyCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFCompareFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two (string) fields.

CALLED BY:	PrimaryKeyCallback
PASS:		ds:si - field data from record1 (record to insert)
		cx = size of data at ds:si (0 if no data)
		es:di - field data from record2 (in file)
		dx = size of data at es:di (0 if no data)
		al - DataStoreFieldType
		ah - FieldFlags 

RETURN:		ax - 0 if fields are equal
		    -1 if field1 comes before field2
		     1 if field1 comes after field2

DESTROYED:	cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
INSERT_EQUAL	equ	0
INSERT_AFTER	equ	1
INSERT_BEFORE	equ	-1

DFCompareFields		proc	far
		uses	bx
		.enter

	;
	; Do the trivial cases first - one or both fields is empty
	;
		push	cx
		or	cx, dx			; are both fields empty?
		pop	cx
		mov	bx, INSERT_EQUAL	; then fields are "equal"
		jz	emptyField
		mov	bx, INSERT_BEFORE	; record 1 comes first if
		jcxz	emptyField		;  its field is empty
		mov	bx, INSERT_AFTER	; record 1 comes after if
		tst	dx			;  record 2's field is empty
		jz	emptyField
	;				
	; Both fields contain data.
	; Call the correct compare routine for this field type
	;
		push	ax
		mov	bl, al
EC <		cmp	bl, DSFT_BINARY					>
EC <		ERROR_Z INVALID_FIELD_TYPE_FOR_PRIMARY_KEY		>
		mov	bh, 0
		shl	bx
		call 	cs:compareTable[bx]	; ax <- ordering
		pop	bx
		tst	ax
		jz	exit
done:		
	;
	; If the FF_DESCENDING flag is set for this field, reverse the
	; order of the keys by changing the value in ax
	;
		test	bh, mask FF_DESCENDING
		jz	exit
		mov	bx, INSERT_BEFORE
		cmp	ax, INSERT_AFTER
		je	swap
		mov	bx, INSERT_AFTER
swap:
		mov	ax, bx
exit:
		.leave
		ret

emptyField:
		xchg	ax, bx			; bh <- flags, ax - order
		tst	ax
		jz	exit
		jmp	done
		
DFCompareFields		endp

		.assert DSFT_FLOAT eq 0
		.assert DSFT_SHORT eq 1
		.assert DSFT_LONG eq 2
		.assert DSFT_TIMESTAMP eq 3
		.assert DSFT_DATE eq 4
		.assert DSFT_TIME eq 5
		.assert DSFT_STRING eq 6

compareTable	nptr	CompareFloat,		; DSFT_FLOAT
			CompareShort,		; DSFT_SHORT
			CompareLong,		; DSFT_LONG
			CompareTimestamp,	; DSFT_TIMESTAMP
			CompareDate,		; DSFT_DATE
			CompareTime,		; DSFT_TIME
			CompareString		; DSFT_STRING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two string fields

CALLED BY:	GLOBAL
PASS:		ds:si - string 1
		cx - length of string 1 (non-zero)
		es:di - string 2
		dx - length of string 2 (non-zero)
RETURN:		ax = INSERT_BEFORE if string 1 comes before string 2 
		ax = INSERT_AFTER if string 1 comes *after* string 2 
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareString	proc	near
		.enter
		clr	ax
		cmp	cx, dx
		jbe	okay
		xchg	cx, dx
		mov	ax, 1	; ax != 0, if length(str1) > length(str2)

okay:
		call	LocalCmpStrings
		pushf
		tst	ax
		jz	10$
		xchg	cx, dx

10$:
		popf
		jz	insertEqual
		jnc	insertAfter
insertBefore:
		mov	ax, INSERT_BEFORE
exit:
		.leave
		ret

insertAfter:
		mov	ax, INSERT_AFTER
		jmp	exit

insertEqual:
		cmp	cx, dx		
		mov	ax, INSERT_EQUAL
		jg	insertAfter
		jl	insertBefore
		jmp	exit
CompareString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareShort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two shorts (word)

CALLED BY:	DFCompareFields
PASS:		ds:si - buffer containing field 1 data
		es:di - buffer containing field 2 data

RETURN:		ax - 0 if field 1 equals field 2
		    -1 if field 1 comes before field 2
		     1 if field 1 comes after field 2
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareShort		proc	near
		.enter
		clr	ax			; assume they are equal
		mov	cx, ds:[si]
		cmp	cx, es:[di]
		je	done
		mov	ax, INSERT_BEFORE
		jl	done
		mov	ax, INSERT_AFTER
done:		
		.leave
		ret
CompareShort		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareLong
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two longs (dword)

CALLED BY:	DFCompareFields
PASS:		ds:si - buffer containing field 1 data
		es:di - buffer containing field 2 data

RETURN:		ax - 0 if field 1 equals field 2
		    -1 if field 1 comes before field 2
		     1 if field 1 comes after field 2
DESTROYED:	cx, dx, bx

PSEUDO CODE/STRATEGY:
		We can't use cmpdw since we need to do a signed
		comparison.  So we first compare the high words,
		and then, if necessary, the low words.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/95	Initial version
	jmagasin 9/12/96	Broke comparsion into hi/lo sections.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareLong		proc	near
		.enter

		mov	cx, ds:[si].high
		mov	dx, es:[di].high
		cmp	cx, dx			; Signed compare hi words.
		je	compareLowWord

evalFlags:
		mov	ax, 0
		jz	done
		mov	ax, INSERT_BEFORE
		jl	done
		mov	ax, INSERT_AFTER
done:
		.leave
		ret

	; Both numbers are either positive or negative.
	; Signed-compare the low words.
compareLowWord:
		mov	bx, es:[di].low		; dxbx = field 2
		mov	ax, ds:[si].low		; cxax = field 1
		sub	ax, bx			; cf=1  if field1 < field2
		jz	evalFlags		; (since cx=dx)

		pushf				; Don't touch non-S/O/Z flags.
		pop	ax
		jnc	f1_GT_f2		; field 1 > field 2

	; field 1 < field 2:  set up flags accordingly
		or	ax, mask CPU_SIGN
		and	ax, not mask CPU_OVERFLOW
		jmp	setUpFlags
f1_GT_f2:
		or	ax, mask CPU_SIGN or mask CPU_OVERFLOW
setUpFlags:
		and	ax, not mask CPU_ZERO	; Already had our chance!
		push	ax
		popf
		jmp	evalFlags
CompareLong		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareFloat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two floats (FloatNum)

CALLED BY:	DFCompareFields
PASS:		ds:si - buffer containing field 1 data
		es:di - buffer containing field 2 data

RETURN:		ax - 0 if field 1 equals field 2
		    -1 if field 1 comes before field 2
		     1 if field 1 comes after field 2
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareFloat		proc	near
		.enter
	;
	; flags set by what you may consider to be a 
	; "cmp es:di, ds:si" , note the order of two numbers is reversed.
	;
		call	FloatCompPtr	
		mov	ax, 0		; assume they are equal
		je	done
		mov	ax, INSERT_AFTER
		jl	done
		mov	ax, INSERT_BEFORE
done:
		.leave
		ret
CompareFloat		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two dates (DataStoreDate)

CALLED BY:	DFCompareFields
PASS:		ds:si - buffer containing field 1 data
		es:di - buffer containing field 2 data

RETURN:		ax - 0 if field 1 equals field 2
		    -1 if field 1 comes before field 2
		     1 if field 1 comes after field 2
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareDate		proc	near
		.enter
		mov	ax, ds:[si].DSD_year
		cmp	ax, es:[di].DSD_year
		jl	insertBefore
		ja	insertAfter
		mov	al, ds:[si].DSD_month
		cmp	al, es:[di].DSD_month
		jl	insertBefore
		ja	insertAfter
		mov	al, ds:[si].DSD_day
		cmp	al, es:[di].DSD_day
		jl	insertBefore
		ja	insertAfter

		mov	ax, INSERT_EQUAL
exit:		
		.leave
		ret
insertAfter:
		mov	ax, INSERT_AFTER
		jmp	exit

insertBefore:
		mov	ax, INSERT_BEFORE
		jmp	exit
CompareDate		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two times (DataStoreTime)

CALLED BY:	DFCompareFields
PASS:		ds:si - buffer containing field 1 data
		es:di - buffer containing field 2 data

RETURN:		ax - 0 if field 1 equals field 2
		    -1 if field 1 comes before field 2
		     1 if field 1 comes after field 2
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareTime		proc	near
		.enter
		mov	al, ds:[si].DST_hour
		cmp	al, es:[di].DST_hour
		jl	insertBefore
		ja	insertAfter
		mov	al, ds:[si].DST_minute
		cmp	al, es:[di].DST_minute
		jl	insertBefore
		ja	insertAfter
		mov	al, ds:[si].DST_second
		cmp	al, es:[di].DST_second
		jl	insertBefore
		ja	insertAfter

		mov	ax, INSERT_EQUAL
exit:		
		.leave
		ret
insertAfter:
		mov	ax, INSERT_AFTER
		jmp	exit

insertBefore:
		mov	ax, INSERT_BEFORE
		jmp	exit
CompareTime		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareTimestamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two times (DataStoreTime)

CALLED BY:	DFCompareFields
PASS:		ds:si - buffer containing field 1 data
		es:di - buffer containing field 2 data

RETURN:		ax - 0 if field 1 equals field 2
		    -1 if field 1 comes before field 2
		     1 if field 1 comes after field 2
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareTimestamp		proc	near
		.enter
		mov	ax, ds:[si].FDAT_date
		cmp	ax, es:[di].FDAT_date
		jl	insertBefore
		ja	insertAfter
		mov	ax, ds:[si].FDAT_time
		cmp	ax, es:[di].FDAT_time
		jl	insertBefore
		ja	insertAfter

		mov	ax, INSERT_EQUAL
exit:		
		.leave
		ret
insertAfter:
		mov	ax, INSERT_AFTER
		jmp	exit

insertBefore:
		mov	ax, INSERT_BEFORE
		jmp	exit
CompareTimestamp		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayBinarySearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs a binary search on the huge array, to find out 
		where to insert a record

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
		di - VM block handle of huge array
		es:si - ptr to record to insert
		cx:dx - vfptr to callback
		ax - datastore token
		bp - data to pass to callback (stack frame)

			Callback is passed:

			ds:si - fptr to record in datastore 	(item 1)
			es:di - fptr to record to insert 	(item 2)
			ax - datastore token
			bp - callback data

			Callback returns:
			
			AX - 0 if items match
			    -1 if item1 < item2
			     1 if item1 > item2 
		
RETURN:		dx.ax - index of item to insert before
		carry clear if callback returned 0, set otherwise
DESTROYED:	cx
 
PSEUDO CODE/STRATEGY:
       Taken from Knuth, vol. 3, page 407

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeArrayBinarySearch	proc	far
	uses	bp, di, si, ds

	callbackData	local	word	push	bp
	dataOffset	local	nptr	push	si
	callback	local	vfptr	push	cx, dx
	dsToken		local	word	push	ax

	lower		local	dword
	; The lowest element that could possibly match the passed record

	upper		local	dword	
	; The highest element that could possibly match the passed record
	
	current		local	dword
	; The current element

	.enter
		

;	Set up the initial bounds of the search

	call	DFGetFlags
	test	ax, mask DSF_NO_PRIMARY_KEY
	pushf
	clr	ax
	clrdw	lower, ax
	clrdw	current, ax
	call	HugeArrayGetCount
	popf

;	If no key field, we may want to append the record (if no callback)

	LONG	jnz	noKeyField

continue:
	decdw	dxax
	movdw	upper, dxax

searchLoop:
	jgdw	lower, upper, noMatch, ax
	
	movdw	dxax, upper
	adddw	dxax, lower
	shrdw	dxax
	movdw	current, dxax		;current = (upper + lower) / 2
					; (approximate median of upper & lower)

;	copy the record for this index to a block, lock it 
;	and call the comparison callback	

	call	HugeArrayLock		;ds:si <- RecordHeader
EC <	call	ECCheckRecordElement					>

	push	bx, di, bp, ds, es
	mov	ax, dsToken
	mov	di, dataOffset		; es:di <- record passed in
	tst	callback.high
	jnz	doProcCall
	call	DFSortCallback
afterCallback:
	pop	bx, di, bp, ds, es

	call	HugeArrayUnlock

	tst_clc	ax
	js	searchBelow
	jz	match			;Exit with carry clear

searchAbove::
	movdw	dxax, current
	incdw	dxax
	movdw	lower, dxax
	jmp	searchLoop

searchBelow:
	movdw	dxax, current
	decdw	dxax
	movdw	upper, dxax
	jmp	searchLoop

noMatch:
;	"lower" contains the index of where this item should be in the list,
;	so return it.

	stc
	movdw	dxax, lower		; return index
haveIndex:

	.leave
	ret

noKeyField:
; 	If no key field *and* no callback, just append the record.
;
	tst	callback.high
	jnz	continue		; callback exists; do binary search
	adddw	dxax, 2
	stc
	jmp	haveIndex

match:
	movdw	dxax, current
	jmp	haveIndex

doProcCall:
	mov	ss:[TPD_dataAX], ax
	movdw	bxax, callback
	mov	bp, callbackData
	call	ProcCallFixedOrMovable	; ax <- compare result
	jmp	afterCallback
		
HugeArrayBinarySearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRecordFromIndexCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an index into a huge array, copies the data into a
		record block. 

CALLED BY:	INTERNAL
PASS:		bx.di - VM file handle/hugearray handle
		dx.ax - index of item to lock
RETURN:		carry set if error
			ax - DataStoreDataError
		else
			^hax - record block

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRecordFromIndexCommon	proc	near
		uses	bx, cx, dx, si, di, es, ds, bp
		.enter

EC <		call	ECValidateDataStore				>
	;
	; Lock down the record data in the huge array
	;
		call	HugeArrayLock		; ds:si <- element,
						; dx <- size of element
EC <		call	ECCheckRecordElement				>

		mov	bx, DSDE_RECORD_NOT_FOUND	; assume error
		tst	ax			; If ax = 0, not found
		jz	exit
	;
	; Allocate a Record block
	;
		push	dx
		mov	cx, size RecordLMemBlockHeader
		xchg	cx, dx			; cx - record, dx - header size
		add	cx, dx			; cx <- total block size
		call	DSAllocSpecialBlock	; ax <- segment of block
		pop	cx			; dx <- record size
		mov	bx, DSDE_MEMORY_FULL
		jc	exit
	;
	; Allocate a chunk to hold the record data
	;
		push	ds
		mov	ds, ax			; ds <- block
		mov	es, ax			; need this below
		clr	al			; no flags
		call	LMemAlloc		; ax <- chunk handle
		pop	ds
		mov	bx, DSDE_MEMORY_FULL
		jc	chunkError

		mov	es:[RLMBH_flags], 0
		mov	es:[RLMBH_record], ax
	;
	; Copy the data from the datastore record into the memory block
	;
		mov	di, ax
		mov	di, es:[di]		; es:di <- record block
		rep	movsb

		mov	bx, es:[LMBH_handle]
		call	MemUnlock
		clc

exit:
		clr	ax
		call	HugeArrayUnlock
		mov	ax, bx			;ax <- error or handle
		
		.leave
		ret

chunkError:
		push	bx
		mov	bx, es:[LMBH_handle]
		call	MemFree
		pop	bx
		stc
		jmp	exit
GetRecordFromIndexCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteRecordCommonAndTrack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete Record and track changes if necessary

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
		di - record array VM block handle
		dx.ax - record index
RETURN:		carry set if item was not found in the database
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	2/21/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteRecordCommonAndTrack	proc	near
	uses	cx, si
	.enter
		movdw	sicx, dxax
	;
	; We get the record index in dxax.  We want to call
	; DFRecordNumToID with dxcx and preserve the original dxax.
	; So move dxax into sicx, but call the function with dxcx (so
	; the preserved value is in siax).
	;
		call	DFRecordNumToID			; dx.cx <= rec ID
	;
	; Put the index back into dxax *and* preserve dx by holding it
	; in si
	;
		xchg	si, dx				
		call 	DeleteRecordCommon
		mov	dx, si				; restore ID
		jc	done
	;
	; Check if we're tracking mods
	;
		push	di
		mov	di, offset DSM_flags
		call	ReadWordFromMapBlock
		and	di, mask DSF_TRACK_MODS
		jz	notTracking
							
		call	FetchNextTransactionNumber	; disi <= trans #
		call	DLAdd
notTracking:
		pop	di
		clc
done:
				
	.leave
	ret
DeleteRecordCommonAndTrack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteRecordCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a record from the database based on its index number

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
		di - record array VM block handle
		dx.ax - record index
RETURN:		carry set if item was not found in the database
DESTROYED:	dx, ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/11/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteRecordCommon		proc	near
		uses	cx, si, di
		.enter

EC <		call	ECCheckStack					>
EC <		call	ECValidateDataStore				>

		movdw	cxsi, dxax
		call	HugeArrayGetCount	;dx.ax <- count
		cmpdw	cxsi, dxax
		stc
		jae	notFound
		movdw	dxax, cxsi
	;
	; Borrow stack space, as it appears that HugeArrayDelete
	; needs a bunch of stack...
	;
EC <		call	ECCheckStack					>
		mov	si, di
		mov	di, 700
		call	ThreadBorrowStackSpace
		xchg	si, di			;SI <- stack token 
						;DI <- huge array handle
		mov	cx, 1			;Delete one item
		call	HugeArrayDelete
		mov	di, si			;DI <- stack token
		call	ThreadReturnStackSpace
		clc
notFound:
		.leave
		ret
DeleteRecordCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFRecordArrayEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate record array, forwards or backwards

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
		ax - DataStoreRecordEnumFlags
		on stack:
			File			(pushed first)
			Element to start at	(pushed second)
			Number to process	(pushed third)
			Callback routine(vfptr) (pushed fourth)
			Callback data(word) 	(pushed fifth)

	Callback should be defined as:
		Pass:	ds:di - ptr to RecordHeader
			bp - extra data
		Return: carry set to abort
		Destroyed: can destroy ax, bx, cx, dx, di, bp

RETURN:		carry set if callback aborted,
			dx.cx - index of last record examined
		else
			ax - DSE_NO_ERROR or
			ax - DSE_NO_MORE_RECORDS

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Will die if startRecord is > last record number.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/20/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFRecordArrayEnum	proc	far	cbData:word, callback:fptr,
					processNumber:dword, startRecord:dword,
					fileHandle:hptr
		flags		local	word	\
				push	ax
		count		local	dword
		recordNum	local	dword
		ForceRef	count
		ForceRef	cbData
		ForceRef	callback
		.enter

		mov	bx, fileHandle
		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock	 ; di <- record array block
	;
	; Get the number of records, store it in count. For forward searches,
	; count is not modified. For backward searches, it will be set
	; to MAX(processNumber, count) and then counted down in EnumBackwards.
	;
		call	DFGetRecordCount	 			
		movdw	count, dxax
EC <		call	HugeArrayGetCount	; dx.ax <- number of elements>
EC <		cmpdw	dxax, count		 			>
EC <		ERROR_NE INVALID_RECORD_COUNT				>
		tstdw	dxax
		LONG 	jz	lastRecord
	;
	; Get the proper record number to start at. Depends on
	; whether we are supposed to start at either first or last
	; record, and what the last record number is.
	;
		decdw	dxax			; dx.ax = number of last record

		test	flags, mask DSREF_BACKWARDS
		jnz	backwards

		test	flags, mask DSREF_START_AT_END
		jz	$10
		movdw	dxax, 0			; start at first record
		jmp	$20
$10:		
	;
	; If startRecord is > last record, don't enumerate.
	;
		cmpdw	dxax, startRecord
		LONG	jb	lastRecord
		movdw 	dxax, startRecord
$20:
		movdw	startRecord, dxax
		movdw	recordNum, dxax		; set initial recordNum
		
	;
	; Call HugeArrayEnum to call the callback for each record
	;
EC <		call	ECValidateDataStore				>

		push	bp
		push	bx, di		; ^vbx:di <- array
		mov	ax, SEGMENT_CS
		push	ax
		mov	ax, offset DFRecordArrayEnumCallback
		push	ax		; callback
		pushdw	startRecord
		clr	dx
		movdw	dxax, processNumber
		pushdw	dxax
		call	HugeArrayEnum	; carry set if callback aborted
		pop	bp
	;
	; If carry is set, recordNum contains record number where
	; match was found.
	;
		movdw	dxcx, recordNum	; dxcx - last record examined
		jc	done
	;
	; No match was found. If we examined the last record, return error.
	;
		cmpdw	dxcx, count
		je	lastRecord
noMoreRecords:
		mov	ax, DSE_NO_ERROR
		clc

done:
		.leave
		ret @ArgSize

backwards:
	;
	; dx.ax = number of the last record. We want to start at this
	; record if DSREF_START_AT_END is set. If startRecord > last
	; record, don't enum.
	;
		test	flags, mask DSREF_START_AT_END
		jnz	$50
		cmpdw	dxax, startRecord
		jb	lastRecord
		movdw	dxax, startRecord
$50:		
		movdw	startRecord, dxax
		movdw	recordNum, dxax

		call	EnumBackwards
		movdw	dxcx, recordNum
		jc	done
	;
	; See if we reached the last record, which is true if
	; recordNum == -1.
	;
		cmpdw	dxcx, -1
		jne	noMoreRecords
lastRecord:		
		mov	ax, DSE_NO_MORE_RECORDS
		clc
		jmp	done
DFRecordArrayEnum		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFRecordArrayEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make note of the record number and call the real callback

CALLED BY:	DFRecordArrayEnum (via HugeArrayEnum)
PASS:		ds:di - ptr to RecordHeader
		bp - inherited stack frame
RETURN:		carry set to stop enumeration
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/29/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFRecordArrayEnumCallback		proc	far
		.enter inherit DFRecordArrayEnum

		push	bp

	;
	; Don't create a duplicate record if we know this callback
	; is going to modify records (as when DataStoreDeleteField
	; is called.
	;
EC <		clr	bx						>
EC <		test	flags, DSREF_MODIFY_RECORDS			>
EC <		jnz	$10						>
EC <		call	ECDuplicateRecord				>
EC < $10:								>
EC <		push	bx, di, ds					>

		movdw	bxax, callback
		mov	bp, cbData
		call	ProcCallFixedOrMovable
	;
	; Make sure the callback did not modify the record in the file,
	; and that it did not destroy ds.
	;
EC <		pop	bx, di, ax					>
EC <		pushf							>
EC <		mov	cx, ds						>
EC <		cmp	ax, cx						>
EC <		ERROR_NE CALLBACK_TRASHED_PTR				>
EC <		call	ECCheckDuplicate				>
EC <		popf							>

		pop	bp
		jc	done

		mov	ax, -1
		test	flags, mask DSREF_BACKWARDS
		jnz	updateNum
		mov	ax, 1
updateNum:
		cwd
		adddw	recordNum, dxax
		clc		
done:		
		.leave
		ret
DFRecordArrayEnumCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumBackwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HugeArrayEnum only moves forward. Use HugeArrayPrev
		to step through the records backwards.

CALLED BY:	DFRecordArrayEnum
PASS:		^vbx:di - HugeArray
RETURN:		carry set by callback
DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 7/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumBackwards		proc	near
		uses	ds
		.enter	inherit	DFRecordArrayEnum
	;
	; Figure out the number to process, which is MIN(count, processNumber)
	;
		movdw	dxax, processNumber	; dx.ax <- # desired to process
		cmpdw	dxax, -1
		jne	$20			; dx.ax <- -1, process all
$20:
		cmpdw	count, dxax
		jbe	$10
		movdw	count, dxax
		
$10:		
		movdw	dxax, startRecord
		call	HugeArrayLock		; ds:si <- record
EC <		tst	ax			; ax = 0 if not found	>
EC <		ERROR_Z INVALID_INDEX_VALUE				>

callbackLoop:
	;
	; Call our routine which calls the callback 
	;
		push	si
		mov	di, si			; ds:di <- record
		call	DFRecordArrayEnumCallback
		pop	si
		jc	done			; CF set <- stop enumeration

		decdw	count
		tstdw	count
		clc
		jz	done

		call	HugeArrayPrev		; ds:si - element
		tst	ax			; ax = 0 if we're at first elt.
		jnz	callbackLoop
		clc

done:
		pushf
		call	HugeArrayUnlock
		popf

		.leave
		ret
EnumBackwards		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindRecordInDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks for the passed record in the datastore, returning
		its index number

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
		dx.ax - RecordID
RETURN:		dx.ax - array index of item
		di - array handle
		carry set if item not found
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindRecordInDB	proc	near	uses	cx
		recordID	local	dword	push	dx, ax
		ForceRef	recordID
		.enter
	;
	; Call MatchIDCallback for each record in the array.
	;
		clr	ax			; go forward
		push	bx			; file handle
		push	ax, ax			; start at first record
		mov	ax, -1
		push	ax, ax			; go to last record
		
		mov	ax, SEGMENT_CS
		mov	dx, offset MatchIDCallback
		push	ax, dx			; callback
		push	bp			; callback data
		
		clr	ax			; no flags
		call	DFRecordArrayEnum	; carry set if found
		cmc				;  & dx.cx = index
		jc	exit			;Exit if no match
		mov	ax, cx			
exit:
		.leave
		ret
FindRecordInDB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatchIDCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks for a record that matches the passed ID

CALLED BY:	INTERNAL
PASS:		ds:di - record data
		ss:bp - stack frame (inherited from FindRecordInDB)
RETURN:		if match, carry set
		curIndex updated
		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MatchIDCallback	proc	far
		.enter inherit FindRecordInDB

		movdw	dxax, ss:recordID
		cmpdw	dxax, ds:[di].RH_id
		stc
		jz	exit			;Branch w/carry set if match
		clc
exit:
		.leave
		ret
MatchIDCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchNextTransactionNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the next transaction number, and store it in
		the database.

CALLED BY:	Two places: DeleteRecordCommon and DFSaveRecord
PASS:		^hbx = datastore file
RETURN:		disi = your transaction number, sir..
DESTROYED:	nothing
SIDE EFFECTS:	incs the files transaction count

PSEUDO CODE/STRATEGY:
	the transactionNumber in the map block is the number of the
	last one - we need to inc it before we grab it (++x)

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg 	2/19/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FetchNextTransactionNumber	proc	near
	uses	es,bp
	.enter
		call	LockDataStoreMap
		incdw	es:[DSM_transactionNumber]
		movdw	disi, es:[DSM_transactionNumber]
		call	VMDirty
		call	VMUnlock
	.leave
	ret
FetchNextTransactionNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchCurrentTransactionNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current transaction number

CALLED BY:	INTERNAL
PASS:		^hbx = datastore file
RETURN:		disi = the transaction number
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	2/21/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FetchCurrentTransactionNumber	proc	far
	uses	es, bp
	.enter
		call	LockDataStoreMap
		movdw	disi, es:[DSM_transactionNumber]
		call 	VMUnlock
	.leave
	ret
FetchCurrentTransactionNumber	endp

FileCommonCode	ends

