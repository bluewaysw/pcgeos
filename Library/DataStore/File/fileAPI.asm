COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	DataStore
MODULE:		File
FILE:		fileOpen.asm

AUTHOR:		Cassie Hartzog, Oct 4, 1995

ROUTINES:
	Name				Description
	----				-----------
GLB	DataStoreDelete			Delete a datastore file
GLB	DataStoreRename			Rename a datastore file
GLB	DataStoreGetRecordCount		Get the number of records in datastore
GLB	DataStoreGetFlags		Get DataStoreFlags for datastore
GLB	DataStoreGetOwner		Get GeodeToken of datastore owner
GLB	DataStoreGetVersion		Get datastore ProtocolNumber
GLB	DataStoreSetVersion		Set datastore ProtocolNumber
GLB	DataStoreGetExtraData		Get datastore extra user data
GLB	DataStoreSetExtraData		Set datastore extra user data
GLB	DataStoreSaveRecord		Save a record to file
GLB	DataStoreMapRecordNumToID	Gets RecordID from record numberb
GLB	DataStoreRecordEnum		Enumerates all records in a file
GLB	DataStoreStringSearch		Searches for a string in the datastore
GLB	DataStoreGetNextRecordID 	Gets the RecordID that will be
					assigned to the next new record 
GLB	DataStoreSetNextRecordID 	Sets the RecordID that will be
					assigned to the next new record 

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95	Initial revision

DESCRIPTION:
	Contains code to create, open, close a datastore file

	$Id: fileAPI.asm,v 1.1 97/04/04 17:53:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


FileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a datastore.

CALLED BY:	GLOBAL
PASS:		ds:dx - datastore name
RETURN:		ax - DataStoreError
		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreDelete		proc	far
		uses	bx
		.enter

		mov	bx, vseg FileDelete
		mov	ax, offset FileDelete
		call	DFFileOperation
		jc	done

		mov	bx, DSCT_DATASTORE_CHANGED
		call	DFSendDataStoreNotificationWithName
done:		
		.leave
		ret
DataStoreDelete		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename a datastore.

CALLED BY:	GLOBAL
PASS:		ds:dx - old name
		es:di - new name
RETURN:		ax - DataStoreError
		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreRename		proc	far
		uses	bx
		.enter

		mov	bx, vseg FileRename
		mov	ax, offset FileRename
		call	DFFileOperation
		jc	done
		
		mov	bx, DSCT_NAME_CHANGED
		call	DFSendDataStoreNotificationWithName
done:		
		.leave
		ret
DataStoreRename		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetRecordCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of records in the datastore

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		carry set if error,
			ax - DataStoreError
		else
			dx.ax - number of records 
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetRecordCount		proc	far
		uses	bx, cx
		.enter

		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		jc	exit			; bx <- DataStoreError 

		push	ax
		call	DFGetRecordCount
		mov	bx, ax
		pop	ax
		clc

		call	DMUnlockDataStore	
exit:
		mov	ax, bx
		.leave
		ret
DataStoreGetRecordCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of records in the datastore

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		carry set if error,
			ax - DataStoreError
		else
			ax - DataStoreFlags
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetFlags		proc	far
		uses	bx, cx
		.enter

		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		jc	exit			; bx <- DataStoreError 

		push	ax
		call	DFGetFlags
		mov	bx, ax			; bx <- DataStoreFlags
		pop	ax
		clc				; no error

		call	DMUnlockDataStore
exit:		
		mov	ax, bx			;ax <- DataStoreError or flags
		.leave
		ret
DataStoreGetFlags		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetOwner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of records in the datastore

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		carry set if error,
			ax - DataStoreError
		else
			dx.ax - TokenChars
			cx - ManufacturerID
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetOwner		proc	far
		uses	bx
		.enter

		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		jc	exit			; bx <- DataStoreError 

		push	ax
		call	DFGetOwner		;dx.ax - TokenChars; cx - MID
		mov	bx, ax
		pop	ax
		
		call	DMUnlockDataStore
		clc
exit:
		mov	ax, bx
		.leave
		ret
DataStoreGetOwner		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetVersion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the version number as set by creator.

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		carry set if error,
			ax - DataStoreError
		else
			dx.ax - ProtocolNumber
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetVersion		proc	far
		uses	bx
		.enter

		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		jc	exit			; bx <- DataStoreError 

		push	ax
		mov	ax, offset DSM_version
		call	ReadDWordFromMapBlock
		mov	bx, ax
		pop	ax

		call	DMUnlockDataStore
		clc
exit:		
		mov	ax, bx			; ax <- DataStoreError
		.leave
		ret
DataStoreGetVersion		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreSetVersion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the version number. 

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		dx.cx - ProtocolNumber
RETURN:		carry set if error,
			ax - DataStoreError
		else
			dx.ax - ProtocolNumber
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreSetVersion		proc	far
		uses	bx, cx, es, bp
		.enter

		mov	bl, mask DSEF_WRITE_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		jc	exit			; bx <- DataStoreError 

		push	ax
		mov	ax, cx			;dx.ax - ProtocolNumber
		call	LockDataStoreMap
		movdw	es:[DSM_version], dxax
		call	VMDirty
		call	VMUnlock
		pop	ax

		call	DMUnlockDataStore
		clc
exit:		
		mov	ax, bx			; ax <- DataStoreError
		.leave
		ret
DataStoreSetVersion		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreSetExtraData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the version number. 

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		cx - number of bytes of extra data
		ds:dx - data
RETURN:		carry set if error
		ax - DataStoreError
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreSetExtraData		proc	far
		uses	bx
		.enter

		push	cx
		mov	bl, mask DSEF_WRITE_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		pop	cx
		jc	exit			; bx <- DataStoreError 

		push	ax
		call	DFSetExtraData
		pop	ax

		call	DMUnlockDataStore
		mov	bx, DSE_NO_ERROR
		clc
exit:		
		mov	ax, bx			; ax <- DataStoreError
		.leave
		ret
DataStoreSetExtraData		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetExtraData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the version number. 

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		cx - size of buffer
		es:di - data buffer
RETURN:		ax - DataStoreError
		carry set if error,
		else cx - number of bytes copied to buffer, 0 if none
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetExtraData		proc	far
		uses	bx
		.enter

		push	cx
		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		pop	cx
		jc	exit			; bx <- DataStoreError 

		push	ax
		call	DFGetExtraData
		pop	ax

		call	DMUnlockDataStore

		mov	bx, DSE_NO_ERROR
		clc
exit:		
		mov	ax, bx			; ax <- DataStoreError
		.leave
		ret
DataStoreGetExtraData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetTimeStamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the datastore timestamp

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		carry set if error,
			ax - DataStoreError
		else
			dx.ax - FileDateAndTime
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetTimeStamp		proc	far
;uses	bx
uses	bx, cx
		.enter

		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		jc	exit			; bx <- DataStoreError 

		push	ax
		mov	ax, offset DSM_timestamp
		call	ReadDWordFromMapBlock		; dx.ax <- timestamp
		mov	bx, ax
		pop	ax
		clc

		call	DMUnlockDataStore
exit:		
		mov	ax, bx			; ax <- DataStoreError
		.leave
		ret
DataStoreGetTimeStamp		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreSetTimeStamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the timestamp

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		dx.cx - FileDateAndTime
RETURN:		carry set if error,
			ax - DataStoreError
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreSetTimeStamp		proc	far
		uses	bx, cx, bp, es
		.enter

		push	cx
		mov	bl, mask DSEF_WRITE_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		pop	cx
		jc	exit			; bx <- DataStoreError 

		push	ax
		mov	ax, cx			;dx.ax - FileDateAndTime
		
		call	LockDataStoreMap
		movdw	es:[DSM_timestamp], dxax
		call	VMDirty
		call	VMUnlock
		pop	ax
		clc

		call	DMUnlockDataStore
exit:		
		mov	ax, bx			; ax <- DataStoreError
		.leave
		ret
DataStoreSetTimeStamp		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetNextRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the RecordID that will be assigned to the next
		new record. Note, for a shared datastore

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		carry set if error, ax - DataStoreError
		else dx.ax - RecordID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetNextRecordID	proc	far
		uses	bx,cx
		.enter
		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		jc	exit			; bx <- DataStoreError 

		push	ax
		call	DFGetNextRecordID		; dx.ax <-
							; next record id

	; the recordid should be from first record id to NO_MORE_RECORD_ID
EC <		cmpdw	dxax, FIRST_RECORD_ID				>
EC <		jge	ok						>
EC <		cmpdw	dxax, LAST_RECORD_ID				>
EC <		jle	ok						>
EC <		ERROR	INVALID_RECORD_ID				> 
EC < ok:								>
		mov	bx, ax
		pop	ax

		call	DMUnlockDataStore
exit:		
		mov	ax, bx			; ax <- DataStoreError

		.leave
		ret
DataStoreGetNextRecordID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreSetNextRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the RecordID that will be assigned to the next
		new record for a datastore which is opened with 
		exclusive access.  

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		dx.cx - next RecordID
RETURN:		ax - DataStoreError
DESTROYED:	nothing
SIDE EFFECTS:	
	currently, LAST_RECORD_ID is smaller than FIRST_RECORD,
  	so if record id exceeds ffffhffffh, the error checking will 
	fail.   12/17/95

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreSetNextRecordID	proc	far
		uses	bx, bp
		.enter

	;
	; check if the new id is valid
	;
		cmpdw	dxcx, FIRST_RECORD_ID
		mov	bx, DSE_INVALID_RECORD_ID
		jge	10$

		cmpdw	dxcx, LAST_RECORD_ID
		jg	exit
		clc
10$:
	;
	; check if the file is opened with exclusive 
	;
		call	DMCheckExclusive	; pass: ax - dstoken
						; carry set if no
						; exclusive access
		mov	bx, DSE_ACCESS_DENIED
		jc	exit

		push	cx
		mov	bl, mask DSEF_WRITE_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
EC <		ERROR_C	-1					>
		pop	cx

		push	ax, bx
		push	dx
		call	DFGetNextRecordID		; dx.ax <- current
							; nextRecord's value

		pop	bx				; bx:cx <- new
							; nextRecord id
	;
	; check that the new value is larger than the current one
	;
		cmpdw	bxcx, dxax, bp
		pop	ax, bp				; ax - dstoken
							; ^hbp - file
		je	unlockStore
		mov_tr	dx, bx				; dx.cx <- new id
		mov	bx, DSE_CANNOT_SET_NEXT_RECORD_ID_SMALLER
		jl	unlockStore			; carry is set
							; if less than

		mov_tr bx, bp
		call	DFSetNextRecordID

		mov	bx, DSCT_NEXT_RECORD_ID_CHANGED
		call	DFSendDataStoreNotification
		clc
		mov	bx, DSE_NO_ERROR
unlockStore:
		call	DMUnlockDataStore
exit:		
		mov	ax, bx			; ax <- may be DataStoreError

		.leave
		ret
DataStoreSetNextRecordID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFSendDataStoreNotificationWithName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and send a datastore file change notification

CALLED BY:	INTERNAL
PASS:		ds:dx - datastore name
		bx - DataStoreChangeType
RETURN:		^hbx - notification block
DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/27/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFSendDataStoreNotificationWithName		proc	far
		uses	ax, bx, cx, si, di, es
		.enter
		pushf

		push	bx
		mov	ax, size DataStoreChangeNotification
		mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE \
				or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	ax, 1
		call	MemInitRefCount

		call	MemLock
		mov	es, ax
		pop	es:[DSCN_action]

		mov	di, offset DSCN_name
		mov	si, dx
		.assert (size DSCN_name gt FILE_LONGNAME_LENGTH+1)
		mov	cx, FILE_LONGNAME_LENGTH+1
		rep	movsb
		call	MemUnlock

		call	SendNotification

		popf
		.leave
		ret
DFSendDataStoreNotificationWithName		endp

FileCode	ends


FileCommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreSaveRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the current record to file

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		cx.dx - callback to do sort comparisons
		bp - extra data passed to callback

RETURN:		carry set if error
			ax - DataStoreDataError
		else
			dx.ax - record index after it is saved
			bx.cx - record ID after it is saved
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/19/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreSaveRecord	proc far
	.enter
	mov	bx, 1
	call DataStoreSaveRecordCommon
	.leave
	ret
DataStoreSaveRecord	endp
	
DataStoreSaveRecordNoUpdate	proc far
	.enter
	clr	bx
	call DataStoreSaveRecordCommon
	.leave
	ret
DataStoreSaveRecordNoUpdate	endp
	
DataStoreSaveRecordCommon	proc	near
		update	local	word		push	bx
		cbData	local	word		push	bp
		dsToken local	word		push	ax
		index	local	RecordID
		timeStamp local FileDateAndTime
		uses	di, si, es
		.enter	

		push	cx
		mov	bl, mask DSEF_WRITE_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		mov	di, cx			;^hdi <- record handle
		jcxz	noRecord
		pop	cx
		jc	exit			; ax <- DataStoreError 
	;
	; Time stamp the record if it needs it.
	;
		clr	si			;use current time
		tst	ss:[update]
		jz	continue
		push	di, cx
		mov	cx, di			;^hcx <- record handle 
		segmov	es, ss
		lea	di, ss:[timeStamp]	;es:di <- time stamp buffer
		call	SetRecordTimeStamp	;es:di <- previous time stamp
		pop	di, cx
		jnc	continue
		mov	si, 1			;si == 0, timestamp not changed
continue:
		push	ax
		push	bp
		mov	bp, cbData
		call	DFSaveRecord		; if carry set, ax = error
						; else dx.ax=index, cx.bx=ID
		pop	bp
		movdw	index, dxax
		pop	ax
		jc	saveError
	;
	; Flush the record from the buffer
	;
		push	bx, cx
		clr	bx			; empty buffer
		movdw	dxcx, EMPTY_BUFFER_ID
		call	DMSetNewRecord
		pop	bx, cx
		
doneUnlock:
		call	DMUnlockDataStore
		movdw	dxax, index
exit:
		.leave
		ret

saveError:
		tst	si
		stc
		jz	doneUnlock		;record was not time stamped
	;
	; Reset the time stamp to the original value since the save failed.
	;
		mov	ax, dsToken		;ax - datastore token
		lea	di, ss:[timeStamp]	;es:di - previous time stamp
		call	SetRecordTimeStamp	
EC<		ERROR_NC -1						>
		jmp	doneUnlock

noRecord:
		pop	cx
		mov	index.low, DSDE_RECORD_BUFFER_EMPTY
		stc
		jmp	doneUnlock
DataStoreSaveRecordCommon		endp

FileCommonCode	ends


FileMiscCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreMapRecordNumToID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the RecordID for the nth record, where n is passed in

CALLED BY:	GLOBAL
PASS:		ax - datastore session token
		dx.cx - record number
RETURN:		carry set if error,
			ax - DataStoreDataError
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
DataStoreMapRecordNumToID		proc	far
		.enter

		push	cx
		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		pop	cx
		jc	exit			; ax <- DataStoreError 

		call	DFRecordNumToID		; dx.cx <- RecordID
		mov	bx, DSDE_NO_ERROR
		jnc	done
		mov	bx, DSDE_RECORD_NOT_FOUND
done:
		call	DMUnlockDataStore
		mov	ax, bx			; ax <- DataStoreDataError
exit:		
		.leave
		ret
DataStoreMapRecordNumToID		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreRecordEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all records in a file.

CALLED BY:	GLOBAL
PASS:		ax - datastore session token
		si - DataStoreRecordEnumFlags
		dx.cx - record number to start at
		bx.di - vfptr of callback routine
		bp - callback data (stack frame)
RETURN:		carry set if error,
		    ax - DataStoreError
		else
		    dx.cx - index of last record examined, +/- 1,
			depending on direction 
		    if reached last record, 
			ax - DSE_NO_MORE_RECORDS
		    else 
			ax - DSE_DSE_NO_ERROR
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 2/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreRecordEnum		proc	far
		uses	bx, bp
		cbData		local	word	push	bp
		callback	local	fptr	push	bx, di
		.enter

		push	cx
		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		pop	cx
		jc	error			; bx <- DataStoreError 

		push	ax
	;
	; Set up the params for DFRecordArrayEnum 
	;
		push	bx			; file handle
		pushdw	dxcx			; start record
		movdw	dxax, -1			; process all records
		pushdw	dxax			; number records to process
		pushdw	callback		; callback
		push	cbData			; callback data
		
		mov	ax, si			; enum flags
		call	DFRecordArrayEnum	; carry set if callback aborted
						;  & dx.cx <- record num
		pop	ax
		call	DMUnlockDataStore	; flags preserved

		mov	ax, DSE_NO_MORE_RECORDS	; assume enumeration is done
		jnc	done
		mov	ax, DSE_NO_ERROR	; no, callback aborted
		clc				; signal no error
done:
		.leave
		ret
error:
		mov	ax, bx			;ax <- DataStoreError
		jmp	done
DataStoreRecordEnum		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreStringSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a string in the datastore

CALLED BY:	GLOBAL
PASS:		ax - datastore session token
		es:di - SearchParams
RETURN:		carry clear if match found
			dx.ax - index of matching record	
			bl - FieldID of field containing the match
		carry set if error
			ax - DSE_NO_MATCH_FOUND
			   - DSE_NO_MORE_RECORDS 
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/14/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreStringSearch		proc	far
		params		local	dword	push	es, di
		dsHandle	local	word
		field		local	byte
		ForceRef	params
		uses	cx, si, di, es
		.enter
		
		push	cx
		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
		mov	dsHandle, bx
		pop	cx
		LONG	jc	lockError		; bx <- DataStoreError 
	;
	; Before going any further, if this is a single-field search,
	; make sure the field is valid and is of type DSFT_STRING
	;
		cmp	es:[di].SP_searchType, ST_FIELD
		jne	continue

		push	ax
		mov	dl, es:[di].SP_startField
		call	DSGetFieldInfoByID
		pop	ax
		jc	exit
		cmp	dl, DSFT_STRING
		jne	badParams

continue:
		push	ax
		clr	cx
		test	es:[di].SP_flags, mask SF_BACKWARDS
		jz	$10
		mov	cx, mask DSREF_BACKWARDS
$10:
		test	es:[di].SP_flags, mask SF_START_AT_END
		jz	$20
		or	cx, mask DSREF_START_AT_END
$20:
	;
	; Set up the params for DFRecordArrayEnum 
	;
		push	bx			; file handle
		pushdw	es:[di].SP_startRecord
		pushdw	es:[di].SP_maxRecords

		mov	ax, SEGMENT_CS
		push	ax
		mov	ax, offset DFSearchCallback
		push	ax			; callback

		clr	ax
		push	bp			; callback data
		
		mov	ax, cx			; flags
		call	DFRecordArrayEnum	; if carry set, dx.cx = 
						;    matching record num
		mov	di, ax			; else 
						;    ax = DSE_NO_ERROR or
						;    DSE_NO_MORE_RECORDS
		pop	ax
		call	DMUnlockDataStore	; flags preserved

		cmc
		mov	ax, cx			; dx.ax <- record num
		mov	bl, field
		jnc	exit

		mov	ax, DSE_NO_MATCH_FOUND
		cmp	di, DSE_NO_ERROR
		stc
		je	exit
EC <		cmp	di, DSE_NO_MORE_RECORDS				>
EC <		ERROR_NE -1						>
EC <		stc							>
		mov	ax, di
				
exit:
		.leave
		ret

lockError:
		mov	ax, bx
		jmp	exit
badParams:
		mov	ax, DSE_BAD_SEARCH_PARAMS
		stc
		jmp	exit
DataStoreStringSearch		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFSearchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a string in a record

CALLED BY:	DataStoreStringSearch (via DFRecordArrayEnum)
PASS:		ds:di - ptr to RecordHeader in datastore
		al - SearchFlags
		bp - stack frame inherited from DataStoreStringSearch
RETURN:		carry set if match found
		ss:record updated with ID of this record
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/14/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFSearchCallback		proc	far
		uses	ds, bp
		.enter inherit DataStoreStringSearch

		mov	si, di
		les	di, ss:params
		mov	dl, es:[di].SP_startField
		mov	ss:field, dl		
	;
	; If this is a single field search, get a ptr to the desired
	; field and do the comparison now.
	;
		cmp	es:[di].SP_searchType, ST_FIELD
		jne	notFieldSearch

		mov	bx, ss:dsHandle
		call	DSGetFieldPtrCommon	; ds:di <- field data,
						;    cx <- field size,
						;    dh <- DataStoreFieldType
		jc	noField
	;
	; Pass: ds:di - string, cx - length, al - DataStoreFieldType, dl - FieldID
	;
		mov	al, dh
		call	MatchFieldCallback
		
done:
		.leave
		ret

notFieldSearch:
	;
	; We either want to search all fields, or fields of a particular
	; category. Enumerate the fields, checking each one in turn.
	;
		mov	ax, dsHandle		; ^hax - datastore file
		mov	bx, SEGMENT_CS
		mov	di, offset MatchFieldCallback
		call	DSFieldEnumCommon	
		jmp	done

noField:
EC <		cmp	ax, DSDE_FIELD_DOES_NOT_EXIST			>
		clc
EC <		ERROR_NE INVALID_FIELD_ID				>
		jmp	done
		
DFSearchCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatchFieldCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Examine a field for a matching string

CALLED BY:	DFSearchCallback
PASS:		ds:di - string
		cx - string length
		al - field type
		ah - field category	(if not ST_FIELD search)
		dl - FieldID
		bp - stack frame inherited from DFSearchCallback
RETURN:		carry set if match found,
			ss:field contains matching field
		carry clear if not found
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/16/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MatchFieldCallback		proc	far
		.enter inherit DFSearchCallback

		mov	ss:field, dl		; update the current field
	;
	; We only search in string fields...
	;
		cmp	al, DSFT_STRING
		jne	continue
	;
	; If this is a search of type ST_CATEGORY, see if this
	; category matches		
	;
		les	bx, ss:params
		cmp	es:[bx].SP_searchType, ST_CATEGORY
		jne	notCat
		cmp	ah, es:[bx].SP_category
		jne	continue

notCat:
	;
	; If this is a search every field search, make sure this field
	; comes after the start field
	;
		cmp	es:[bx].SP_searchType, ST_ALL
		jne	notAll
		cmp	dl, es:[bx].SP_startField
		jb	continue

notAll:
		push	bp, dx
		mov	ah, es:[bx].SP_flags
		push	ax

		mov	ax, ds
		lds	si, es:[bx].SP_searchString	; ds:si <- match string

		mov	es, ax			; es:di <- string to search in
		mov	bp, di			; es:bp <- 1st char in string
		mov	bx, di			; es:di <- 1st char in string
		mov	dx, cx			; dx <- length of string
DBCS<		shr	dx			>
		dec	cx
DBCS<		dec	cx			>
		add	bx, cx			; es:bx <- last char to search
		clr	cx			; string to match is null-term

		pop	ax
		clr	al			; assume no flags
		test	ah, mask SF_IGNORE_CASE
		jz	$10
		or	al, mask SO_IGNORE_CASE
$10:
		test	ah, mask SF_NO_WILDCARDS
		jz	$20
		or	al, mask SO_NO_WILDCARDS
$20:		
		test	ah, mask SF_PARTIAL_WORD
		jz	$30
		or	al, mask SO_PARTIAL_WORD
$30:
		call	TextSearchInString	; carry set if not found
		pop	bp, dx
		cmc
done:
		.leave
		ret

continue:
		clc
		jmp	done
MatchFieldCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetCurrentTransactionNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the current transaction number

CALLED BY:	EXTERNAL
PASS:		ax = DataStore Token
RETURN:		carry set if error
			ax = DataStoreDataError	
		else carry clear
			dx.cx = transaction number
			ax = DataStore Token
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	2/21/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetCurrentTransactionNumber	proc	far
	uses	bx
	.enter
	
	mov	bl, mask DSEF_READ_LOCK
	call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
	xchg	ax, bx
	jc	exit			; bx <- DataStoreError 

	xchg	ax, bx
	push	di, si
	call	FetchCurrentTransactionNumber
	movdw	dxcx, disi
	pop	di, si
	call	DMUnlockDataStore 

exit:
	.leave
	ret
DataStoreGetCurrentTransactionNumber	endp

FileMiscCode	ends









