COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	DataStore
MODULE:	        File
FILE:		fileMisc.asm

AUTHOR:		Cassie Hartzog, Oct  5, 1995

ROUTINES:
	Name			Description
	----			-----------
EXT	DFGetRecordCount	Gets number of records in datastore
EXT	DFSetRecordCount	Sets number of records in datastore
EXT	DFGetOwner		Gets GeodeToken of datastore owner
EXT	DFGetVersion		Gets ProtocolNumber of datastore
EXT	DFSetVersion		Sets ProtocolNumber for datastore
EXT	DFGetFlags		Gets DataStoreFlags for datastore
EXT	DFGetExtraData		Gets datastore's user data
EXT	DFSetExtraData		Sets datastore's user data
EXT	DFGetTimeStamp		Gets datastore's timestamp
EXT	DFSetTimeStamp		Sets datastore's timestamp

EXT	DFGetNextRecordID	Gets datastore's id assigned to next
				new record
EXT	DFSetNextRecordID	Sets datastore's id assigned to next
				new record

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	10/ 5/95	Initial revision


DESCRIPTION:
	Miscellaneous routines 

	$Id: fileMisc.asm,v 1.1 97/04/04 17:53:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFGetRecordCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns total number of records in datastore.

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
RETURN:		dx.ax - record count
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFGetRecordCount		proc	far
		.enter
		mov	ax, offset DSM_recordCount
		call	ReadDWordFromMapBlock
		.leave
		ret
DFGetRecordCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFGetOwner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the GeodeToken of the datastore's owner

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
RETURN:		dx.ax - TokenChars
		cx - ManufacturerID
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFGetOwner		proc	far
		uses	es, bp
		.enter
		call	LockDataStoreMap
		movdw	dxax, es:[DSM_owner].GT_chars
		mov	cx, es:[DSM_owner].GT_manufID
		call	VMUnlock
		.leave
		ret
DFGetOwner		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFSetExtraData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets user data in datastore file

CALLED BY:	EXTERNAL - DataStoreSetExtraData
PASS:		^hbx - datastore file
		cx - # bytes of data, 0 to delete old data
		ds:dx - data
RETURN:		nothing		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/13/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFSetExtraData		proc	far
		uses	ax, bp, si, di, es
		.enter

		clr	ax			; assume no data
		jcxz	noData
		
		call	VMAlloc			; ax <- VM block handle

		push	ax			; save VM block handle
		call	VMLock
		mov	es, ax
		clr	di

		push	cx			; save data size
		mov	si, dx
		rep	movsb
		call	VMDirty
		call	VMUnlock
		pop	cx
		pop	ax

noData:		
		call	LockDataStoreMap
		mov	es:[DSM_extraDataSize], cx
		xchg	ax, es:[DSM_extraData]
		call	VMDirty
		call	VMUnlock

		tst	ax
		jz	noFree
		call	VMFree			; free the old block, if exists
noFree:
		call	DFUpdateDataStore
		
		.leave
		ret
DFSetExtraData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFGetExtraData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets user data in datastore file

CALLED BY:	EXTERNAL - DataStoreSetExtraData
PASS:		^hbx - datastore file
		cx - size of buffer
		es:di - buffer to hold data
RETURN:		cx - # bytes copied to buffer
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/13/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFGetExtraData		proc	far
		uses	ax, bx, si, di, ds, bp
		.enter

		push	di
		mov	di, offset DSM_extraData
		call	ReadWordFromMapBlock
		mov	ax, di

		mov	di, offset DSM_extraDataSize
		call	ReadWordFromMapBlock
		mov	si, di
		pop	di

		tst	si
		jz	noData
	;
	; Copy smaller of buffer size, # bytes of extra data
	;
		cmp	cx, si
		jbe	okay
		mov	cx, si
		
okay:
		call	VMLock
		mov	ds, ax
		clr	si

		push	cx
		rep	movsb
		call	VMUnlock
		pop	cx
done:		
		.leave
		ret
noData:
		clr	cx
		jmp	done
DFGetExtraData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFGetNextRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets next record id. (assume there is already a lock
		on the given datastore.)

CALLED BY:	EXTERNAL
PASS:		^hbx - file
RETURN:		dxax - next record id
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFGetNextRecordID	proc	far
	.enter
	mov	ax, offset DSM_recordID
	call	ReadDWordFromMapBlock

	.leave
	ret
DFGetNextRecordID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFSetNextRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets next record id.

CALLED BY:	EXTERNAL
PASS:		^hbx - file 
		dxcx - new next record id
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFSetNextRecordID	proc	far
	uses	es, bp
	.enter

EC <	cmpdw	dxcx, FIRST_RECORD_ID		 	>
EC <	jge	ok					>
EC <	cmpdw	dxcx, LAST_RECORD_ID			>
EC <	ERROR_A INVALID_RECORD_ID			>

EC < ok:						>
	call	LockDataStoreMap
	movdw	es:[DSM_recordID], dxcx
	call	VMDirty
	call	VMUnlock
	clc

	.leave
	ret
DFSetNextRecordID	endp

FileCode	ends


FileCommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFSetRecordCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds 1 or -1 to record count

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
		ax - 1 or -1
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 7/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFSetRecordCount		proc	near
		uses	dx, es, bp
		.enter
EC <		cmp	ax, 1						>
EC <		je	okay						>
EC <		cmp	ax, -1						>
EC <		ERROR_NE -1						>
EC < okay:	 							>
		
		call	LockDataStoreMap
		cwd				
		adddw	es:[DSM_recordCount], dxax
		call	VMDirty
		call	VMUnlock
		.leave
		ret
DFSetRecordCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the DataStoreFlags for the datastore

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
RETURN:		ax - DataStoreFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFGetFlags	proc	far
		uses di
		.enter
		mov	di, offset DSM_flags
		call	ReadWordFromMapBlock
		mov	ax, di
		.leave
		ret
DFGetFlags	endp

;--------------------------------------------------------------------------
;		Internal Routines
;--------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockDataStoreMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks the DataStoreMap

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
RETURN:		es:0 - DataStoreMap
		^hbp - map block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockDataStoreMap		proc	far
		uses	ax
		.enter
		call	VMGetMapBlock
		call	VMLock
		mov	es, ax
		.leave
		ret
LockDataStoreMap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadWordFromMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a word from the DataStoreMap

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
		di - offset from which to read
RETURN:		di - word
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadWordFromMapBlock		proc	far
		uses	es, bp
		.enter
		call	LockDataStoreMap
		mov	di, es:[di]
		call	VMUnlock
		.leave
		ret
ReadWordFromMapBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadDWordFromMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a word from the DataStoreMap

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
		ax - offset from which to read
RETURN:		dx.ax - dword read
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadDWordFromMapBlock		proc	far
		uses	di, es, bp
		.enter
		call	LockDataStoreMap
		mov	di, ax
		movdw	dxax, es:[di]
		call	VMUnlock
		.leave
		ret
ReadDWordFromMapBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRecordTimeStamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the TIME_STAMP field in the record buffer if one
		exists. Can be used to set the record time stamp to the
		current time or to a time passed in.
	
CALLED BY:	(INTERNAL) DataStoreSaveRecord
PASS:		ax - datastore token
		^hbx - handle to datastore file
		^hcx - handle to record buffer mem block
		es:di - FileDateAndTime buffer
			si == 0, set to current time
			si == 1, set to passed time (restore)
				if es:di == 0, delete the timestamp
		
RETURN:		if record exists in buffer its timestamp has been updated
			carry set
			if si == 0, 
				es:di - old time stamp of record in buffer
				(for restore)
			else
				es:di - unchanged
		else
			carry clear
		
DESTROYED:	nada
SIDE EFFECTS:	
		Changes record in record buffer.

PSEUDO CODE/STRATEGY:
	20) Use DFGetFlags to check if the datastore is time stamped, 
	    exit if it isn't.
	30) If the user has set the timestamp, exit.
	40) If current time is requested use TimerGetFileDataAndTime
	    to fill es:di with current time.
	50) Call DataStoreGetField to get current record timestamp 
	55) If record doesn't have a timestamp field (it is a new record),
	    will return 0 as old timestamp
	60) If timestamp == 0, delete the timestamp field, else set it
	    by calling DataStoreSetField 
	70) Return the saved old timestamp field, if si == 0
	

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	MS		11/14/95    	Initial version
	tgautier	 2/19/97	Add modification tracking

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRecordTimeStamp	proc	near
	timePtr		local	fptr	push	es, di
	dsHandle	local	word	push	bx
	bufHandle	local	word	push	cx		
	fdat		local	FileDateAndTime
EC <	fieldData	local	FieldData				>
	uses	ax,bx,cx,dx,es,di
	.enter

	;This procedure assumes the caller has already EC checked 
   	;parameters.

	;Is the datastore time stamped or using mod tracking? Exit if not.
	
	call	DFGetFlags	
	mov	dx, ax
	test	dx, mask DSF_TIMESTAMP or mask DSF_TRACK_MODS
	clc				;return not time stamped
	jnz	continue		;jump - datastore timestamped

exit:
	.leave
	ret

continue:
	; if DSF_TRACK_MODS is turned on, skip the user-override
	; feature of the timestamping -- mod tracking will occur no
	; matter what and override whatever the user thinks they are
	; doing (hey we're smarter than the user, aren't we?!?)
	;
	mov	bx, bufHandle		;^hbx - datastore file handle	
	test	dx, mask DSF_TRACK_MODS
	jnz	testHaveTimeStamp

	;If the user has modified the timestamp, we don't want
	;to overwrite it, so exit.
	;		
EC <	call 	ECCheckMemHandle					>
	call	DSGetBufferRecordFlags	;al - buffer flags		
	test	al, mask BF_TIMESTAMP_MODIFIED
	clc				
	jnz	exit		

testHaveTimeStamp:
	;Use the passed time if (si != 0).

	tst	si			;use passed time?
	jnz	haveTimestamp

	; if DSF_TRACK_MODS is turned on, get the next transaction
	; number, otherwise get the current time and date for
	; timestamping
	test	dx, mask DSF_TRACK_MODS
	jz	setCurrentDateAndTime

	push	bx, di, si
	mov	bx, dsHandle
	call	FetchNextTransactionNumber
	mov	dx, di
	mov	ax, si
	pop	bx, di, si
	jmp 	setTimeStampField

setCurrentDateAndTime:
	;
	; Get the current time to set in the record. 
	;
	call	TimerGetFileDateTime	;ax - FileDate,	dx - FileTime

setTimeStampField:
	mov	es:[di].FDAT_date, ax
	mov	es:[di].FDAT_time, dx

	;Make sure we are actually getting the time stamp field. The
	;API calls for a hard coded arrangement where the time stamp 
	;field is always field id == 0. This is asserted here.

	segmov	es, ss, ax

EC<	mov	al, TIME_STAMP_FIELD_ID					>
EC<	lea	di, ss:[fieldData]					>
EC<	mov	bx, dsHandle						>
EC<	call	DFMapTokenToData					>
EC<	ERROR_C -1							>
EC<	mov	al, ss:[fieldData].FD_type				>
EC<	cmp	al, DSFT_TIMESTAMP					>
EC<	ERROR_NE -1							>

	;Get the previous time stamp so we can return it.

	lea	di, fdat		;es:di - buffer for old time stamp
	mov	bx, ss:[dsHandle]
	mov	ax, ss:[bufHandle]
	mov	cx, size FileDateAndTime
	mov	dl, TIME_STAMP_FIELD_ID
	call	DSGetFieldCommon
EC <	ERROR_C ERROR_GETTING_TIME_STAMP_FIELD				>
	cmp	cx, size FileDateAndTime
	je	haveTimestamp
EC <	tst	cx							>
EC <	ERROR_NZ ERROR_GETTING_TIME_STAMP_FIELD				>

	;The field is not present in this record. Could it be new?
	;Set time to 0. If this is called to restore the time after
	;save fails, we should check for 0 and delete the timestamp field.
		
	mov	es:[di].FDAT_date, 0
	mov	es:[di].FDAT_time, 0
		
haveTimestamp:

	;Set the timestamp to that in the buffer.
	;Delete timestamp if passed timestamp == 0.

	les	di, timePtr		;es:di - new time time stamp
					;fdat - old time stamp
	cmpdw	es:[di], 0
	jz	deleteIt
	mov	cx, size FileDateAndTime
	mov	dl, TIME_STAMP_FIELD_ID
	mov	ax, ss:[bufHandle]
	mov	bx, ss:[dsHandle]
	call	DSSetFieldCommon
EC<	cmp	bx, DSDE_NO_ERROR					>
EC<	ERROR_NE ERROR_GETTING_TIME_STAMP_FIELD				>
EC<	cmp	cx, size FileDateAndTime				>
EC<	ERROR_NE ERROR_GETTING_TIME_STAMP_FIELD				>

	;If si == 1, we are restoring timestamp, not setting it.
		
	tst	si
	jnz	done
		
	;Return the old time stamp.

	mov	ax, fdat.FDAT_date
	mov	es:[di].FileDate, ax
	mov	ax, fdat.FDAT_time
	mov	es:[di].FileTime, ax
done:
	stc		
	LONG jmp exit

deleteIt:
	mov	cx, bufHandle
	mov	bx, dsHandle
	mov	dl, TIME_STAMP_FIELD_ID
	call	DSRemoveFieldFromRecordCommon
	jmp	done
SetRecordTimeStamp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFSendDataStoreNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize notification block

CALLED BY:	INTERNAL
PASS:		ax - datastore token
		bx - DataStoreChangeType
		dx.cx - recordID, if applicapble
		cl - fieldID, if applicable
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/27/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFSendDataStoreNotification		proc	far
		uses	ax, bx, cx, dx, di, es
		.enter
		pushf
		
		push	ax, bx, cx
		mov	ax, size DataStoreChangeNotification
		mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE \
				or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	ax, 1
		call	MemInitRefCount

		call	MemLock
		mov	es, ax
		mov	es:[DSCN_record].high, dx
		pop	ax, es:[DSCN_action], cx

		mov	es:[DSCN_record].low, cx
		mov	es:[DSCN_field], cl

		mov	di, offset DSCN_name
		call	DMGetSessionDataStoreName
EC <		ERROR_C -1						>

		call	MemUnlock

		call	SendNotification

		popf
		.leave
		ret
DFSendDataStoreNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a DataStoreChange notification

CALLED BY:	INTERNAL
PASS:		^hbx - DataStoreChangeNotification
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/27/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendNotification		proc	far
		uses	ax, cx, dx, si, di, bp
		.enter

		call	MemIncRefCount
		
		push	bx
		mov	bp, bx				; bp <- data block
		clrdw	bxsi
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_DATASTORE_CHANGE
		mov	di, mask MF_RECORD
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		call	ObjMessage			; di <- event handle

		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GAGCNLT_NOTIFY_DATASTORE_CHANGE
		mov	cx, di				; event handle
		mov	dx, bp				; dx <- data block
		clr	bp				; no flags
		call	GCNListSend
		pop	bx

		call	MemDecRefCount
		
		.leave
		ret
SendNotification		endp

FileCommonCode	ends


