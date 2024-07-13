COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	DataStore	
MODULE:		Main
FILE:		mainData.asm

AUTHOR:		Wenyong Yang, Oct 13, 1995

ROUTINES:
	Name			Description
	----			-----------
GLB	DataStoreNewRecord	Creates a new, empty record in buffer.
GLB	DataStoreSetField	Sets a field data for the current record.
GLB	DataStoreGetField	Gets a field data from the current
				record and stores it in a block
GLB	DataStoreGetFieldChunk	Gets a field data from the current
				record and stores it in a chunk.
GLB	DataStoreGetFieldSize	Gets the size of a given field in the
				current record. 
GLB	DataStoreRemoveFieldFromRecord 
			Removes the given field from the buffer block.
GLB	DataStoreGetNumFields	Gets the number of fields in the
				current record.
GLB	DataStoreGetFieldPtr	Gets the pointer to a given field in a record.

GLB	DataStoreLockRecord	Locks the current record and returns a ptr.
GLB	DataStoreUnlockRecord	Unlocks the current record.

GLB	DataStoreDeleteRecord	Deletes a record with given record id.
GLB	DataStoreDeleteRecordNum Deletes a record with given record number.

GLB	DataStoreGetRecordID	Gets id of the current record.
GLB	DataStoreSetRecordID	Sets the id of the current record.

EXT	DSSetFieldCommon	Sets the field given file handle and field id
EXT	DSGetFieldCommon	Gets the field given file handle and field id
EXT	DSRemoveFieldFromRecordCommon	
				Removes a field from a record
EXT	DSGetFieldPtrCommon	Gets the pointer to a field in a
				record given file handle.
EXT	DSAllocSpecialBlock	Allocates a LMem block
EXT	DSGetFieldInfoByID	Gets field header size for a given field, 
			       	,its data size for fixed field, flags and type.
EXT	DSIsFieldInRecord	Scans a locked record to find a 
EXT	DSGetFieldSizeByType	Gets field size for fixed-length fields
EXT	DSGetFieldSize		Gets the size of a field including its
				header with the given field header
EXT	DSParseField		Parses a field
EXT	DSGetBufferRecordFlags	Gets the flags of the buffer.
INT	DSIsDataPrintable	Checks if the given data is printable.
EXT	DSIsDataValidForField	Checks if the given data is valid for
				the given field.

INT	ResizeWithFieldFound	Inserts or deletes space to a locked 
				current record.
INT	ResizeWithFieldNotFound	Inserts space to a locked current record

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/13/95   	Initial revision


DESCRIPTION:
	This file contains high level routines for manipulating 
	data.

		
	$Id: mainData.asm,v 1.1 97/04/04 17:53:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MainCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreNewRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there is no current record in the buffer, then
		creates a new, empty record in the buffer, sets the
		new record flag and makes this record 
		the current record. Only when this record is
		explicitly saved will it be written to the datastore.
		
		Returns error if there is already a current record in
		buffer when this routine is called.

CALLED BY:	GLOBAL

PASS:		ax - datastore token
RETURN:		ax - DataStoreDataError
		carry set if error

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		1) check for non-empty buffer
		2) get record id for the new record
		4) allocate a new block for the new record
		5) set record ID and buffer flags in the new block
		8) update buffer handle in session table.
		10) return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreNewRecord	proc	far
	dsToken		local	word	push	ax

	uses	bx,cx,dx,si,di,ds
	.enter

	; get file handle

	mov	bl, mask DSEF_WRITE_LOCK
	call	DMLockDataStore		; pass: ax - datastore token
					; 	bl - lock flags
					; return: if carry set
					; 	       bx - DSDE error
					; 	  else bx - file handle
					;	       cx - buffer handle
	xchg	ax, bx
	LONG 	jc	exit
	mov	bx, ax
	tst	cx			; is there a record in buffer already?
	LONG	jnz	errorUnlock	; yes, can't create a new one.

	mov	ax, dsToken
	call	DMUnlockDataStore	; flags preserved

	; allocate an LMEM heap to hold the new record

	mov	dx, size RecordLMemBlockHeader
	mov	cx, dx
	add	cx, size RecordHeader

	call	DSAllocSpecialBlock	; carry set if error
	mov	ds, ax			; else ax - segment of block

	mov	ax, DSDE_MEMORY_FULL
	jc	exit

	; create a record chunk containing only a record header

	mov	cx, size RecordHeader
	call	LMemAlloc		; ax <- record chunk	
	mov	ds:[RLMBH_flags], mask BF_NEW_RECORD
	mov	ds:[RLMBH_record], ax
	mov	si, ax						
	mov	si, ds:[si]					

	; initialize fields in the new record header

	movdw	ds:[si].RH_id, NEW_RECORD_ID
	mov	ds:[si].RH_size, size RecordHeader
	clr	ds:[si].RH_fieldCount

EC <	call	ECCheckRecordPtr				>

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	
	; update buffer handle

	movdw	dxcx, NEW_RECORD_ID, ax
	mov	ax, dsToken
	call	DMSetNewRecord		; pass: ax - datastore token
					; bx - buffer handle
					; dxcx - NEW_RECORD_ID
					; return: if carry set, bad token
	mov	ax, DSDE_INVALID_TOKEN
	jc	exit
	mov	ax, DSDE_NO_ERROR

exit:
	.leave
	ret

errorUnlock:
	mov	ax, dsToken
	call	DMUnlockDataStore
	mov	ax, DSDE_RECORD_BUFFER_NOT_EMPTY
	stc
	jmp	exit
	
DataStoreNewRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreSetField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the passed field of the current buffered record 
		with the given data.  The passed data size will be
		ignored for fixed-length fields. 
		Note* For variable-length fields, it is an error to 
		pass size equal to zero. 

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		bx:si - field name, pass bx = 0 to only use field id.
		dl - FieldID, field id is ignored if bx is non-zero.
		es:di - new field data
		cx - size of field data, size is ignored for
		     fixed-length fields.

RETURN:		ax - DataStoreDataError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	5) check if passed data is valid
	8) check if zero data size is passed for variable-length field
	12) lock the current record
	15) check if passed field exists in the record
	18) if the field is not in record, create and insert field header
	20) update field data, field info
	28) set buffer flag : _MODIFIED_IN_BUFFER
	30) Unlock the buffer block
	40) return		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreSetField	proc	far
	dsToken		local	word	push	ax
	dSize		local	word	push	cx
	uses	bx,cx,dx,ds,es,si,di
	.enter

	mov	cx, bx			; cx:si <- field name
	mov	bl, mask DSEF_WRITE_LOCK
	call	LockDataStoreAndGetFieldID
	LONG	jc	done

	;
	; If no current record, exit now
	;
	mov	ax, bx
	mov	bx, DSDE_RECORD_BUFFER_EMPTY
	stc
	LONG	jcxz	unlockStore

	mov	bx, ax
	mov	ax, cx			; ^hbx - file 
					; ^hax - record block
					; dl - field id
	mov	cx, ss:[dSize]

	call	DSSetFieldCommon


unlockStore:
	mov 	ax, ss:[dsToken]
	call	DMUnlockDataStore	;flags preserved

done:
	mov	ax, bx
	.leave
	ret
DataStoreSetField	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSSetFieldCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	EXTERNAL
PASS:		^hbx - file handle
		^hax - buffer handle
		dl - file id
		es:di - new field data
 		cx - size of data, size is ignored for fixed-size field
		
RETURN:		bx - DataStoreDataError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSSetFieldCommon	proc	far
	dOffset		local	word	push	di
	rHandle		local	word	push	ax
	fHandle		local	word	push	bx
	dSize		local	word	push	cx
	fieldFlags	local	byte	
	fieldID		local 	FieldID
	fType		local	byte
	fFlags		local	byte
	axSave		local	word
	cxSave		local	word

	uses	ax,cx,dx,si,di, es, ds
	.enter

	mov	ss:[fieldID], dl

	call	DSGetFieldInfoByID	; ax - field data size, 
					; 0 if variable size
					; cl - header size
					; ch - FieldFlags
					; dl - field type

	mov	ss:[axSave], ax		;save those registors for
	mov	ss:[cxSave], cx		;calling function.
	mov	ss:[fType], dl
	mov	ss:[fFlags], ch	
	LONG	jc	exit

	mov	ss:[fieldFlags], ch

	tst	ax
	jz	checkValidData		; variable size field, jump

	mov	ss:[dSize], ax		; ignore passed data size for
					; fix-size field
checkValidData:
	tst	dSize
	LONG 	jz	done1
	;
	; check for valid data
	;
	mov	cx, dSize
	call	DSIsDataValidForField 
	LONG	jc	done2

	;
	; locks down the current record
	;
	mov	bx, ss:[rHandle]
	call	MemLock
	mov	ds, ax
	LONG	jc	done3
	;
	; check if passed field exists in the record
	;
	mov	si, ds:[RLMBH_record]
	mov	si, ds:[si]		; dssi - ptr to record

	push	si			; offset of the record
	mov	bx, ss:[fHandle]
	
    	call	DSIsFieldInRecordForSetFieldCommon
					; cx - field size, 0 if
					; not present
					; al - field header type
					; si - offset of field
					; dh - field type

	pop	di			; di - offset of the record	

	jc	unlockBuf

	mov	bx, ds:[RLMBH_record]	; bx - ^h of the record chunk
	jcxz	notInRecord
	;
	; field is already in the current record
	;
	.assert	DS_NON_FIXED_FIELD eq 0
	mov	dx, cx
	mov	cx, size FieldHeader
	tst	al
	jz	20$
	mov	cx, size FieldHeaderFixed
20$:

	sub	dx, cx
	mov	cx, dSize
	call	ResizeWithFieldFound	; dssi- ptr to field content
					; data, 
					; dsdi - ptr to record
			
	jc	unlockBuf
	jmp	updateFieldData

notInRecord:
	mov	cx, dSize
	call	ResizeWithFieldNotFound	; ds:si- ptr to field content
					; data, 
					; dsdi - ptr to record
	jc	unlockBuf

updateFieldData:
	segxchg	es, ds, ax
	mov	di, si
	mov	si, ss:[dOffset]		;dssi-source, esdi-destination
	rep	movsb
	;
	; set buffer flag : _MODIFIED_IN_BUFFER
	;
	or	es:[RLMBH_flags], mask BF_MODIFIED_IN_BUFFER
	test 	ss:[fieldFlags], mask FF_PRIMARY_KEY
	jz	$10
	or	es:[RLMBH_flags], mask BF_PRIMARY_KEY_MODIFIED
$10:
	test 	ss:[fieldFlags], mask FF_TIMESTAMP
	jz	$20
	or	es:[RLMBH_flags], mask BF_TIMESTAMP_MODIFIED
$20:
EC <	mov	ax, es:[LMBH_handle]			>
EC <	mov	bx, ss:[fHandle]
EC <	call	ECCheckRecordBlock			>
	mov	ax, DSDE_NO_ERROR

unlockBuf:
	;
	; unlock the the datastore and the buffer block
	;
	mov	bx, es:[LMBH_handle]
	call	MemUnlock		;flags preserved

exit:	mov	bx, ax

	.leave
	ret
done3:
	mov	ax, DSDE_MEMORY_FULL
	jmp	exit
done2:
	mov	ax, DSDE_INVALID_FIELD_DATA
	jmp 	exit
done1:	
	mov	ax, DSDE_INVALID_DATA_SIZE
	jmp 	exit

DSSetFieldCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIsFieldInRecordForSetFieldCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a field with given id exists in the given 
		record. This routine is specially designed for
		SetFieldCommon to avoid calls to DSGetFieldInfoByID 

CALLED BY:	DSSetFieldCommon
PASS:		bx - file handle
		ds:si - ptr to record
		dl - field ID
RETURN:		if carry set, ax - error message
		*note: in this routine it is not an error if the field
			is not present.
		else
			cx - field size including header, 0 if not present
			si - offset of stop point
			al - field header type
			ah - field flags
			dh - field type
			dl - field id

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JD	2/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSIsFieldInRecordForSetFieldCommon	proc	near

	
	.enter	inherit DSSetFieldCommon


	
	clr	ch
	mov	cl, ds:[si].RH_fieldCount
	add	si, size RecordHeader
	jcxz	notFound

	; non-empty record
	mov	dl, fieldID
scanNextField:
	.assert	FH_id eq FHF_id
	cmp	dl, ds:[si].FH_id	; dl - field id
	je	found
	jl	notFound

	call	DSGetFieldSize	; ax - size including header
EC <	ERROR_C 	INVALID_FIELD_ID			>
	
	add	si, ax

	loop	scanNextField

notFound:
	mov	ax, ss:[axSave]
	clr	cx
	jmp	done

found:
	mov	ax, ss:[axSave]
	mov	cx, ss:[cxSave]
	clr	ch
	add	cx, ax
	tst	ax
	jnz	done
	mov	cx, ds:[si].FH_size
done:
	clc
	mov	dh, fType
	mov	dl, fieldID
	mov	ah, fFlags

	.leave
	ret
DSIsFieldInRecordForSetFieldCommon     endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGetFieldSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the size of a field (including its header) with 
		a given field header

CALLED BY:	INTERNAL
PASS:		ds:si - field header
		^hbx - datastore handle
RETURN:		if carry set, ax - error
		else ax - field size
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGetFieldSize	proc	near
	uses	cx, dx, di
	.enter
	.assert	offset FHF_id eq offset FH_id

	mov	al, ds:[si].FH_id	; Get field ID

	push	si, ds			
	clr	ah
	
	push	ax, bp			; preserve fieldID and bp
	call 	VMGetMapBlock		; get the element array		
	call	VMLock
	mov	ds, ax
	mov	ax, ds:[DSM_fieldArray] 
	call 	VMUnlock
	call 	VMLock			; lock the element array
	mov	ds, ax
	mov	si, ds:[FALMBH_array]
	pop	ax, bp

	call	ChunkArrayElementToPtr	;ds:si <-- FieldData
	mov	si, di

	jc	exit1

	add	si, offset FNE_data
	mov	al, ds:[si].FD_type    ; get the field type

exit1:	push	bp
	mov	bp, ds:[LMBH_handle]
	call	VMUnlock
	pop	bp
	pop	si, ds

	call	DSGetFieldSizeByType

	clr	ch
	add	cx, ax
	tst	ax
	mov	ax, cx
	jnz	done
	mov	ax, ds:[si].FH_size
done:
	.leave
	ret
DSGetFieldSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGetFieldSizeByType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets header size for a given file type, and gets field
		data size if the field is of fixed size

CALLED BY:	DSGetFieldInfoByID
PASS:		al - field type
RETURN:		if carry set, ax - error message,
		else
			cl - header size
			ax - data size, 0 if variable size
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGetFieldSizeByType	proc	near

	mov	dl, al
	;
	; check if field is valid
	;
	cmp	dl, DataStoreFieldType
	cmc
	jc	exit
	;
	; find sizes - optimize for string type
	;
	mov	cl, size FieldHeader
	clr	ax
	.assert	(DSFT_BINARY eq DSFT_STRING + 1)
	cmp	dl, DSFT_STRING
	jb	continue
	clc

done:	ret

exit:	mov	ax, DSDE_INVALID_FIELD_TYPE
	jmp	done
continue:
	.assert (size FileDateAndTime eq size dword)
	.assert (size DataStoreTime eq 3)
	.assert (size DataStoreDate eq size dword)
	mov	cl, size FieldHeaderFixed
	cmp	dl, DSFT_SHORT
	je	wordSize
	mov	ax, size byte
	cmp	dl, DSFT_TIME
	je	wordSize
	cmp	dl, DSFT_FLOAT
	mov	ax, size FloatNum
	je	done
	clr	ax
EC <	cmp	dl, DSFT_LONG					>
EC <	je	dwordSize					>
EC <	cmp	dl, DSFT_TIMESTAMP				>
EC <	je	dwordSize					>
EC <	cmp	dl, DSFT_DATE					>
EC <	ERROR_NE	INVALID_FIELD_TYPE			>

EC < dwordSize:							>
	add	ax, size word
wordSize:
	add	ax, size word
	jmp	done

DSGetFieldSizeByType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the data of the given field from the current 
		record. If passed size is larger than zero, then copy
		data to the destination pointed by passed pointer. 
		If the passed size is zero, then allocate a
		block for data and makes the passed pointer pointing
		to data in this block.
		Note: if a new block is allocated, it is the calling 
		routine's responsibility to deallocate the new block.

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		bx:si - field name, pass bx = 0 to only use field id.
		dl - FieldID, field id is ignored if bx is non-zero.
		es:di - dest. for field data
		cx - max # bytes to copy, 0 to allocate a new block
RETURN:		if carry set,
			ax - DataStoreDataError
		else
			bx - handle of block containing the field's
			     data, if cx was passed 0
			cx - # bytes of data copied, 0 if no data
			es:di - ptr to copied data
		Note* es, di change if a new block is allocated.

DESTROYED:	nothing
		Note: that bx will be trashed, if this routine
		terminates with errors other than DSDE_EXCEEDS_BUFFER_SIZE 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		2) check if there is a current record in buffer
		if so, lock it down

		4) check if passed field is valid

		15) check if passed field exists in the record

		20) copy the field if it is there 

		30) unlock the current record

		40) return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetField	proc	far
	uses	dx,bp, si
	.enter

	;
	;Get field id if a field name is passed.
	;
	mov	bp, cx			; bp - max # bytes to copy

	mov	cx, bx			; cx:si <- field name
	mov	bl, mask DSEF_READ_LOCK
	call	LockDataStoreAndGetFieldID; dl <- field id
	LONG	jc	exit
	;
	; If no current record, exit now
	;
	mov	si, bx			; si - file handle
	mov	bx, DSDE_RECORD_BUFFER_EMPTY
	stc
	jcxz	unlockStore

	push	ax
	mov	ax, cx		; ^hax - buffer handle
	mov	bx, si		; ^hbx - file handle
	mov	cx, bp		; cx - max # of bytes to copy
	call	DSGetFieldCommon
	pop	ax

unlockStore:
	call	DMUnlockDataStore

exit:	
	jnc	20$
	mov_tr	ax, bx
20$:
	.leave
	ret

DataStoreGetField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGetFieldCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a field from the current record. (Same as
		DataStoreGetField.)

CALLED BY:	EXTERNAL
PASS:		^hbx - file handle
		^hax - buffer handle
		dl - file id
		es:di - dest. for field data
 		cx - max # bytes to copy, 0 to allocate a new block
RETURN:		if carry set, 
			bx - DataStoreDataError
		else
			bx - handle of block containing the field's
			     data, if cx was passed 0
			cx - # bytes of data copied, 0 if no data
			es:di - ptr to copied data
		Note* es, di change if a new block is allocated.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGetFieldCommon	proc	far
	maxBytes	local	word	push	cx
	headerSize	local	word	
	blockHan	local	word
	uses	ax,dx,ds, si
	
	.enter
	clr	ss:[blockHan]
	;
	; lock the record buffer
	;
	push	bx
	mov	bx, ax
	call	MemLock
	mov	ds, ax
	pop	bx				; ^hbx - file handle
	mov	ax, DSDE_MEMORY_FULL
	jc	exit

	; check if passed field exists in the record

	mov	si, ds:[RLMBH_record]
	mov	si, ds:[si]
    	call	DSIsFieldInRecord	; pass: bx - file handle
					;	dssi - ptr to record
					;	dl - field ID
					; return: if carry set, ax -  error
					; else
					;  cx - field size including header
					;             0 if not present	
					;  al - field header type
					;  si - offset of field
					;  dh - field type

	jc	unlockBuf			; error!
	jcxz	unlockBuf	; field is not in record

	.assert	DS_NON_FIXED_FIELD eq 0
	mov	ss:[headerSize], size FieldHeader
	tst	al
	jz	$10
	mov	ss:[headerSize], size FieldHeaderFixed
$10:
	;
	; Field was found in the current record
	;
	sub	cx, ss:[headerSize];
	tst	ss:[maxBytes]		; was a buffer passed?
	jnz	okBuf
	;
	; no buffer passed, allocate a new block
	;
	mov	ss:[maxBytes], cx
	mov	ax, cx			; ax - size to allocate
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		; bx - handle, ax - segment
	mov	es, ax
	mov	di, 0			
	mov	ax, DSDE_MEMORY_FULL	
	jc	unlockBuf
	mov	cx, ss:[maxBytes]
	mov	ss:[blockHan], bx
	
okBuf:
	;
	; copy data over
	;
	cmp	ss:[maxBytes], cx
	jge	10$
	mov	cx, ss:[maxBytes]		; carry is set at this point
	mov	ax, DSDE_EXCEEDS_BUFFER_SIZE
10$:
	push	cx, di
	add	si, ss:[headerSize]		; dssi - field content
	rep	movsb
	pop	cx, di

unlockBuf:
	; Unlock the buffer block 
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

exit:
	mov	bx, ax
	jc	20$
	mov	bx, ss:[blockHan]	; ^hbx - new block handle, 
					; 	0 if no new block

20$:
	.leave
	ret
DSGetFieldCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetFieldChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the data of the field with given name or id from
		the current record and stores the field data in the 
		chunk passed.  
		If no chunk is passed, then allocate a new one. 
		If the field data is larger than the passed chunk, 
		the chunk is resized.
		The number of bytes copied to the chunk is returned.
		
CALLED BY:	GLOBAL
PASS:		ax - datastore token
		cx:si - field name, if cx = 0, then use field id 
			passed in dl
		dl - FieldID, ignored if bx is not 0
		bx - MemHandle of block to put data in
		di - ChunkHandle, or 0 to allocate a new one
RETURN:		if carry set,
			ax - DataStoreDataError, cx destroyed
		else
			ax - ChunkHandle of chunk containing the
			field's data
			cx - # bytes of data copied, 0 if field is 
			not present
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		10) lock the datastore and get the id for the field
		20) lock the current record
		30) get the ptr to the desired field in record
		40) copy data into passed chunk, allocate or resize
		the chunk if necesary.
		50) unlock the current record
		60) unlock the datastore 
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetFieldChunk	proc	far
	dsToken		local	word	push	ax
	destBlock	local	word	push	bx
	destChunk	local	word	push	di
	uses	bx,dx,ds,si,di
	.enter

	;
	;Get field id if a field name is passed.
	;
	mov	bl, mask DSEF_READ_LOCK
	call	LockDataStoreAndGetFieldID	; dl - field id
						; ^hbx - file
						; ^hcx - buffer
	xchg	ax, bx
	LONG	jc	exit
	xchg	ax, bx

	;
	; If no current record, exit now
	;
	mov	ax, DSDE_RECORD_BUFFER_EMPTY
	stc
	LONG	jcxz	unlockStore

	;
	; lock the record buffer
	;
	push	bx
	mov	bx, cx
	call	MemLock
	mov	ds, ax
	pop	bx
	mov	ax, DSDE_MEMORY_FULL
	jc	unlockStore

	;
	; get the ptr to the desired field in record
	;
	mov	si, ds:[RLMBH_record]
	mov	si, ds:[si]		; dssi - ptr to record

	call	DSGetFieldPtrCommon	; dsdi - ptr to field data
					; cx - field data size

	jnc	10$
	tst	cx			; check if field is not present
	jnz	unlockBuf
	clc
	jmp	unlockBuf

10$:
	mov	si, di			; dssi - ptr to field data (source)
	;
	; lock the destination block
	;
	mov	bx, destBlock
	call	MemLock
	mov	es, ax
	mov	ax, DSDE_INVALID_BLOCK_HANDLE
	jc	unlockBuf

	;
	; set up the destination
	;
	mov	di, destChunk
	tst	di
	jz	allocChunk

	;
	; check if the passed chunk needs to be resized
	;
EC <	push	ds, si						>
EC <	segmov	ds, es, ax					>
EC <	mov	si, ds:[di]					>
EC <	call	ECCheckLMemChunk				>
EC <	pop	ds, si						>
	ChunkSizeHandle	es, di, ax	; ax - old chunk size
	cmp	ax, cx
	jge	chunkReady		; chunk is big enough, jump
	push	ds
	segmov	ds, es, ax
	mov	ax, di
	call	LMemReAlloc
	mov	di, ax			; *es:di - destination chunk
	pop	ds
	mov	ax, DSDE_MEMORY_FULL
	jc	unlockPassedBlk

chunkReady:
	push	cx
	mov	ax, di			; ax - chunk handle
	mov	di, es:[di]		; es:di - destination
	rep	movsb
	pop	cx

unlockPassedBlk:
	call	MemUnlock

unlockBuf:
	; Unlock the datastore and buffer block 
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

unlockStore:
	xchg	ax, dsToken		; ax <- dsToken, save error
	call	DMUnlockDataStore
	mov	ax, dsToken		; ax <- error
exit:
	.leave
	ret

allocChunk:
	clr	ax
	call	LMemAlloc
	mov	di, ax			; di - chunk handle
	mov	ax, DSDE_MEMORY_FULL
	jc	unlockPassedBlk
	jmp	chunkReady
	
DataStoreGetFieldChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetFieldSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the number of bytes in the named field (or if
		field=NULL, the field with passed field id) of the
		current record.

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		bx:si - field name, if bx = 0, then use field id 
			passed in dl
		dl - FieldID, ignored if bx is not 0
RETURN:		if carry set,
			ax - DataStoreDataError
		else
			ax - # bytes of field data, 0 if field is 
			not present
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetFieldSize	proc	far
	uses	bx, cx, dx, si, di, ds, bp
	.enter

	mov	bp, ax				; bp - dstoken
	;
	;Get field id if a field name is passed.
	;
	mov	cx, bx				; cx:si - field name
	mov	bl, mask DSEF_READ_LOCK
	call	LockDataStoreAndGetFieldID	; dl - field id
						; ^hbx - file
						; ^hcx - buffer
	xchg	ax, bx
	LONG	jc	exit
	xchg	ax, bx

	;
	; If no current record, exit now
	;
	mov	ax, DSDE_RECORD_BUFFER_EMPTY
	stc
	LONG	jcxz	unlockStore

	;
	; lock the record buffer
	;
	push	bx
	mov	bx, cx
	call	MemLock
	mov	ds, ax
	pop	bx
	mov	ax, DSDE_MEMORY_FULL
	jc	unlockStore

	;
	; get the ptr to the desired field in record
	;
	mov	si, ds:[RLMBH_record]
	mov	si, ds:[si]		; dssi - ptr to record

	call	DSGetFieldPtrCommon	; dsdi - ptr to field data
					; cx - field data size

	jc	getPtrError
	mov	ax, cx			; ax - field data size

unlockBuf:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

unlockStore:
	xchg	ax, bp
	call	DMUnlockDataStore
	mov	ax, bp

exit:
	.leave
	ret

getPtrError:
	cmp	ax, DSDE_FIELD_DOES_NOT_EXIST
	jne	unlockBuf
	clr	ax
	clc
	jmp	unlockBuf

DataStoreGetFieldSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreRemoveFieldFromRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the given field from the current buffered
		record.  This change will affect datastore file only
		the current record is saved explicitly. 

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		cx:si - field name, pass cx = 0 to only use field id
		dl - field id, field id is ignored if cx is non-zero.
RETURN:		ax - DataStoreDataError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		1) check if the given token is valid

		2) check if there is a current record in buffer
		if so, lock it down

		20) remove the field, if it exists in the record
		decrement the record's field count, record size.

		30) Unlock the current record

		40) return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreRemoveFieldFromRecord	proc	far
	dsToken		local	word	push	ax
	uses	bx, cx
	.enter

	mov	bl, mask DSEF_WRITE_LOCK
	call	LockDataStoreAndGetFieldID
	mov	ax, bx			; bx = error if carry is set
	jc	exit

	;
	; If no current record, exit now
	;
	mov	ax, DSDE_RECORD_BUFFER_EMPTY
	stc
	jcxz	doneUnlock
		
	;
	; remove the field
	;
	call	DSRemoveFieldFromRecordCommon	; pass: ^hcx - record handle
						; 	^hbx - file handle
						;	dl - field id
EC <	pushf							>
EC <	push	ax				;save error code>
EC <	mov	ax, cx						>
EC <	call	ECCheckRecordBlock				>
EC <	pop	ax						>
EC <	popf							>
	jc	doneUnlock
	mov	ax, DSDE_NO_ERROR

doneUnlock:
	xchg	ax, dsToken
	call	DMUnlockDataStore
	mov	ax, dsToken
exit:
	.leave
	ret
DataStoreRemoveFieldFromRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSRemoveFieldFromRecordCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the given field from the locked record.
		Note* this routine only works for those Lmem blocks,
		which have the same layout as the buffer block.

CALLED BY:	EXTERNAL
PASS:		^hcx - record block
		^hbx - datastore file
		dl - field ID
RETURN:		carry set if error
			ax - DataStoreDataError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSRemoveFieldFromRecordCommon	proc	far
	uses	bx, cx, dx, si, di, ds
	.enter

	push	bx
	mov	bx, cx
	call	MemLock
EC <	ERROR_C -1						>
	pop	bx
	mov	ds, ax

	mov	si, ds:[RLMBH_record]
	push	si
	mov	si, ds:[si]		; ds:si <- RecordHeader
	mov	di, si			; save record offset
    	call	DSIsFieldInRecord	; pass: bx - file handle
					;	dssi - ptr to record
					;	dl - field ID
					; return: if carry set, ax -  error
					; else
					; 	cx - field size, 0 if
					; 		not present
					;	al - field header type
					;	ah - field flags
					;	si - offset of field
					;	dh - field type

	pop	dx			; dx - record chunk handle
	jc	exit			; ax - error
	jcxz	notFound

	;
	; We are going to remove the field, since it exists in the record.
	; Set the buffer flags appropriately.
	;
	or	ds:[RLMBH_flags], mask BF_MODIFIED_IN_BUFFER
	test	ah, mask FF_PRIMARY_KEY 
	jz	$10
	or	ds:[RLMBH_flags], mask BF_PRIMARY_KEY_MODIFIED
$10:
	;
	; Clear the timestamp modified flag, as we want to use the
	; system timestamp if the user deletes the timestamp field
	;
	test 	ah, mask FF_TIMESTAMP
	jz	$20
	andnf	ds:[RLMBH_flags], not mask BF_TIMESTAMP_MODIFIED
$20:

	mov	bx, si			; ds:bx <- field to delete
					; bx <- offset within record block
	sub	bx, di			;  	of field to delete
	.assert	DS_NON_FIXED_FIELD eq 0
	tst	al
	mov	ax, size FieldHeader
	jz	20$
	mov	ax, size FieldHeaderFixed
20$:
	mov	ax, dx
	call	LMemDeleteAt
	;
	; decrement the record's field count and record size
	;
	dec	ds:[di].RH_fieldCount
	sub	ds:[di].RH_size, cx		; clears carry
EC <	ERROR_C	INVALID_RECORD_SIZE		>
	
exit:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	.leave
	ret

notFound:
	mov	ax, DSDE_FIELD_DOES_NOT_EXIST
	stc
	jmp	exit
DSRemoveFieldFromRecordCommon	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreLockRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks the current record, returns a pointer to it.
		DSDE_RECORD_BUFFER_EMPTY is returned if there is
		no current record.  The caller must unlock the record
		by calling DataStoreUnlockRecord. 

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		if carry set
			ax - DataStoreDataError
		else
			ds:si - ptr to the current record (RecordHeader)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreLockRecord	proc	far
	uses	bx,cx,bp
	.enter

	mov	bp, ax
	mov	bl, mask DSEF_READ_LOCK
	call	DMLockDataStore		; ^hbx - file
					; ^hcx - buffer
	xchg	ax, bx
	jc	exit

	mov	bx, ax
	tst	cx
	stc
	mov	ax, DSDE_RECORD_BUFFER_EMPTY
	jz	unlockStore
	clc

	xchg	bx, cx			; ^hcx - file
	call	MemLock
	mov	ds, ax
	mov	ax, DSDE_MEMORY_FULL
	mov	bx, cx			; ^hbx - file
	jc	unlockStore

	mov	si, ds:[RLMBH_record]
	mov	si, ds:[si]		; ds:si - ptr to current record
EC <	call	ECCheckRecordPtr				>

	;
	; check if the record is already locked
	;
	test	ds:[RLMBH_flags], mask BF_LOCKED
	stc
	mov	ax, DSDE_RECORD_LOCKED
	jnz	unlockBuf

	;
	; set the lock 
	;
	or	ds:[RLMBH_flags], mask BF_LOCKED
	mov	ax, bp			; restore ax, when no error
	call	DMUnlockDataStore
exit:
	.leave
	ret
unlockBuf:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
unlockStore:
	xchg	ax, bp
	call	DMUnlockDataStore
	xchg	ax, bp
	jmp	exit

DataStoreLockRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreUnlockRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks the current record. Do nothing, if the current
		record was not locked.

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreUnlockRecord	proc	far
	uses	bx,cx,ds,bp
	.enter
	mov	bp, ax
	mov	bl, mask DSEF_READ_LOCK
	call	DMLockDataStore		; ^hbx - file
					; ^hcx - buffer
EC <	ERROR_C	BAD_SESSION_TOKEN				>
	xchg	bx, cx
	call	MemLock
EC <	ERROR_C	BAD_BUFFER_LMEM_BLOCK				>
	mov	ds, ax
	;
	; check if the record was locked
	;
	test	ds:[RLMBH_flags], mask BF_LOCKED
EC <	WARNING_Z UNLOCK_A_RECORD_THAT_WAS_NOT_LOCKED		>
	jz	wasNotLocked					

EC <	push	si						>	
EC <	mov	si, ds:[RLMBH_record]				>
EC <	mov	si, ds:[si]		; ds:si - ptr to current record  >
EC <	xchg	bx, cx			; ^hbx - file		>
EC <	call	ECCheckRecordPtr				>
EC <	pop	si						>
EC <	mov	bx, cx			; ^hbx - buffer 	>
	;
	; unlock the current record
	;
	BitClr	ds:[RLMBH_flags], BF_LOCKED
	call	MemUnlock

wasNotLocked:
	call	MemUnlock

	mov	ax, bp			; restore ax, when no error
	call 	DMUnlockDataStore

	.leave
	ret
DataStoreUnlockRecord	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreDeleteRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a record with the given ID from the datastore

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		dxcx - record ID
RETURN:		ax - DataStoreDataError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		10) check if the given record is in any application's
		buffer, return an error if so.

		20) remove the record from file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreDeleteRecord	proc	far
	dsToken	local	word	push	ax
	recID	local	dword	
	uses	bx,cx,dx, ds
	.enter

	movdw	recID, dxcx
	mov	bl, mask DSEF_WRITE_LOCK
	push	cx
	call	DMLockDataStore		;^hbx - datastore file
	xchg	ax, bx
	pop	cx
	jc	done

	xchg	ax, bx			; ax - dstoken 
					; ^hbx - file
	;
	; check if the record is a current record of some session
	;
	call	DMGetRecordDataStoreToken	; pass: ^hbx - file
						;	dxcx - record id
						; return: ax - dsToken

	jnc	deleteFromFile			; record is not buffered

	mov	ax, DSDE_RECORD_IN_USE
	jmp	exit			; the record is in buffer 

deleteFromFile:
	mov	ax, cx			; dx.ax <- recordID
	call	DFDeleteRecordFromID
	jc	exit

	mov	ax, dsToken
	mov	bx, DSCT_RECORD_DELETED
	call	DFSendDataStoreNotification
	mov	ax, DSDE_NO_ERROR
exit:
	xchg	ax, dsToken
	call	DMUnlockDataStore
	xchg	ax, dsToken
done:
	.leave
	ret

DataStoreDeleteRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreDeleteRecordNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Like DataStoreDeleteRecord, but takes a record number
		instead of a record id.

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		dx.cx - record number
RETURN:		ax - DataStoreDataError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		5) lock the datastore
		10) Get its record id from record number
		20) Check if this record is in buffer
		30) Remove it from file if it is not buffered
		35) unlock the datastore

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreDeleteRecordNum	proc	far
	dsToken	local	word	push	ax
	index	local	dword	
	rid	local	dword	
	uses	bx,cx,dx
	.enter

	movdw	ss:[index], dxcx, bx
	push	cx
	mov	bl, mask DSEF_WRITE_LOCK
	call	DMLockDataStore
	pop	cx
	xchg	ax, bx
	jc	done

	xchg	ax, bx				; ^hbx - file
	;
	; Get its record id from record number
	;
	call	DFRecordNumToID			; dxcx - record id
	movdw	ss:[rid], dxcx
	mov	ax, DSDE_INVALID_RECORD_NUMBER
	jc	unlock

	;
	; Check if this record is in buffer
	;
	call	DMGetRecordDataStoreToken
	jnc	deleteFromFile
	mov	ax, DSDE_RECORD_IN_USE
	jmp	unlock

deleteFromFile:
	movdw	dxax, ss:[index]
	call	DFDeleteRecord
EC <	ERROR_C	-1						>
	movdw	dxcx, ss:[rid], ax
	mov	ax, ss:[dsToken]
	mov	bx, DSCT_RECORD_DELETED
	call	DFSendDataStoreNotification
	mov	ax, DSDE_NO_ERROR

unlock:
	push	ax
	mov	ax, ss:[dsToken]
	call	DMUnlockDataStore
	pop	ax
done:

	.leave
	ret

DataStoreDeleteRecordNum	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the record id of the current record.

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		if carry set, ax - DataStoreDataError
		else dx.ax - RecordID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetRecordID	proc	far
	uses	bx,cx,ds,si
	.enter

	;
	;Get field id if a field name is passed.
	;
	mov	bl, mask DSEF_READ_LOCK
	call	DMLockDataStore		; ^hbx - file handle
					; ^hcx - buffer handle
	LONG	jc	exit
EC <	mov	si, bx			; ^hsi - file handle >
	mov	bx, DSDE_RECORD_BUFFER_EMPTY
	stc
	jcxz	unlockStore
	clc

	;
	;Lock the buffer block
	;
	push	ax
	mov	bx, cx
	call	MemLock
EC <	ERROR_C BAD_BUFFER_LMEM_BLOCK				>
	mov	ds, ax
	pop	ax

EC<	push	bx						>
EC <	mov	bx, si				; ^hbx - file	>
	mov	si, ds:[RLMBH_record]
	mov	si, ds:[si]			; ds:si - ptr to
						; record
EC <	call	ECCheckRecordPtr				>
EC <	pop	bx				; ^hbx - buffer >
	movdw	dxcx, ds:[si].RH_id
	call	MemUnlock
	mov	bx, cx				; dxbx - record id

unlockStore:
	call	DMUnlockDataStore

exit:
	mov	ax, bx

	.leave
	ret
DataStoreGetRecordID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreSetRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the new id is the same as the id stored in the
		datastore buffer, then do nothing.
		Otherwise, change the RecordID for the current record to the 
		value passed if the datastore is opened
		for exclusive access.  The record must be saved for
		the change to be permanent. If there already exists a 
		record with this RecordID, it will be overwritten.
		If the RecordID is greater than the next RecordID to
		be assigned to a new record, the next RecordID will be
		updated to the passed RecordID plus one.
		Record ID can be from the FIRST_RECORD_ID(inclusize)
		to LAST_RECORD_ID (exclusize).
	

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		dx.cx - RecordID
RETURN:		ax - DataStoreDataError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		10) check for exclusive access
		15) get record file handle and buffer handle
		20) change the record id for the current record 
		and mark it dirty
		30) update the nextRecordID if needed	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreSetRecordID	proc	far
	dsToken		local	word	push	ax
	bufHan		local	word
	fileHan		local	word
	uses	bx,cx,dx,si,di,ds
	.enter

	.assert	FIRST_RECORD_ID eq 0x00010001
	.assert NEW_RECORD_ID eq (FIRST_RECORD_ID - 1)
	.assert	LAST_RECORD_ID eq ( FIRST_RECORD_ID -2 )

	;
	; the id should be between FIRST_RECORD_ID and LAST_RECORD_ID
	; the following checking might need to change if the constants
	; are defined differently
	;
	;
	; can't set rid to be LAST_RECORD_ID
	; because we can not advance next record id any more
	;
	cmpdw	dxcx, LAST_RECORD_ID
	mov	bx, DSDE_INVALID_RECORD_ID
	LONG	je exit

;
; check if the new record id is different from the record id in
; the current record, if they are the same, then do nothing
;
	; get record file handle and buffer handle
	;
	mov	di, cx			; dxdi - new record id
	mov	bl, mask DSEF_WRITE_LOCK
	call	DMLockDataStore		;^hbx <- file, ^hcx <- buffer
EC <	ERROR_C	-1						>
	mov	ss:[bufHan], cx
	mov	ss:[fileHan], bx

	mov	bx, DSDE_RECORD_BUFFER_EMPTY
	LONG	jcxz	unlockStore

	mov	bx, cx
	call	MemLock
EC <	ERROR_C	BAD_BUFFER_LMEM_BLOCK				>
	mov	ds, ax
	;
	; one exception for new record where it can set its
	; id to be NEW_RECORD_ID
	;
	cmpdw	dxdi, NEW_RECORD_ID
	jne	okID
	test	ds:[RLMBH_flags], mask BF_NEW_RECORD
	mov	bx, DSDE_INVALID_RECORD_ID
	LONG	jz	unlockBuf

okID:
EC <	mov	bx, ss:[fileHan]	;^hbx - file		>
	mov	si, ds:[RLMBH_record]
	mov	si, ds:[si]
EC <	call	ECCheckRecordPtr				>
	
	cmpdw	ds:[si].RH_id, dxdi
	je	unlockBufNoError
	
	;
	; the new record id is different from the id in the current
	; record.  We need to have exclusive access in order to set it.
	;
	mov	ax, ss:[dsToken]
	call	DMCheckExclusive	
	mov	bx, DSDE_ACCESS_DENIED
	LONG	jc	unlockBuf

	; 
	;change the record id for the current record
	;
	movdw	ds:[si].RH_id, dxdi
	or	ds:[RLMBH_flags], mask BF_RECORDID_MODIFIED

unlockBufNoError:
	mov	bx, ss:[bufHan]
	call	MemUnlock	
	
	;
	; update the nextRecordID if needed
	;
	mov	bx, ss:[fileHan]
	mov	cx, dx
	call	DFGetNextRecordID	; dxax - next record id
	cmpdw	cxdi, dxax
	jl	done			; done if new id is smaller

	movdw	dxcx, cxdi
	incdw	dxcx
	call	DFSetNextRecordID

done:
	mov	ax, ss:[dsToken]
	mov	bx, DSDE_NO_ERROR

unlockStore:
	call	DMUnlockDataStore
exit:
	mov	ax, bx
	.leave
	ret
unlockBuf:
	push	bx
	mov	bx, ss:[bufHan]
	call	MemUnlock
	pop	bx
	jmp	exit
DataStoreSetRecordID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetFieldPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives a pointer to a field's content in a given locked
		record. Assumes the passed record is valid.

CALLED BY:	GLB
PASS:		ax - datastore token
		ds:si - Record header
		dl - field id
RETURN:		if carry set, ax - DSDE error
			cx is trashed
		else
		      	cx - field size
		      	dh - field type
			ds:di - ptr to field content
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetFieldPtr	proc	far
	uses	bx,si,bp
	.enter


	mov	bp, ax
	mov	bl, mask DSEF_READ_LOCK
	call	DMLockDataStore
	mov	ax, bx				; bx - error or file handle
	jc	done					
	
EC <	call	ECCheckRecordPtr		>

	call	DSGetFieldPtrCommon		; pass:	bx - ^h datastore
						; 	ds:si - record ptr
						;	dl - field id
						; return:carry set, ax - DSDE
						;  	else:
						;	cx - field size
						;	dh - field type
						;	ds:di - field ptr

	xchg	ax, bp				; save possible error in bp
	call	DMUnlockDataStore
	mov	ax, bp				; restore error to ax
done:
	.leave
	ret
DataStoreGetFieldPtr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetNumFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the number of fields in the current record

CALLED BY:	GLOBAL
PASS:		ax - datastore token
RETURN:		if carry set:
			ax - DataStoreDataError
		else
			ax - number of fields
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetNumFields	proc	far
	uses	bx,cx,si,bp, ds
	.enter

	mov	bp, ax				; bp - dstoken
	mov	bl, mask DSEF_READ_LOCK
	call	DMLockDataStore			; ^hbx - file
						; ^hcx - buffer
	mov	ax, bx			; bx = error if carry is set
	jc	exit

	;
	; If no current record, exit now
	;
	mov	ax, DSDE_RECORD_BUFFER_EMPTY
	stc
	jcxz	unlockStore
		
	;
	; lock the record 
	;
	push	bx
	mov	bx, cx
	call	MemLock
	pop	bx
	mov	ds, ax
	mov	ax, DSDE_MEMORY_FULL
	jc	unlockStore

	mov	si, ds:[RLMBH_record]
	mov	si, ds:[si]
EC <	call	ECCheckRecordPtr				>
	clr	ah
	mov	al, ds:[si].RH_fieldCount

	mov	bx, cx
	call	MemUnlock

unlockStore:
	xchg	bp, ax
	call	DMUnlockDataStore
	xchg 	bp, ax	

exit:
	.leave
	ret
DataStoreGetNumFields	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGetFieldPtrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a pointer to the given field's content in a given
		record of a datastore with the given file handle.
		Assume the datastore is already locked.
		
CALLED BY:	EXTERNAL
PASS:		^hbx - datastore
		ds:si - ptr to record header
		dl - field id
RETURN:		if carry set, ax - DSDE error
			cx = 0, if ax is DSDE_FIELD_DOES_NOT_EXIST
		else
			cx - field data size
			dh - field type
			ds:di - ptr to field content
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGetFieldPtrCommon	proc	far
	uses	bx,si,bp
	.enter

	mov	bp, ax
	call	DSIsFieldInRecord	
	jc	done
	jcxz	notPresent			; field is not present
	mov	di, si	

	.assert	DS_NON_FIXED_FIELD eq 0			
	tst	al				; al = 0 if variable-length
	mov	ax, size FieldHeader
	jz	10$
	mov	ax, size FieldHeaderFixed
10$:
	add	di, ax 				; dsdi - field content
	sub	cx, ax				; cx - field data size
						; dh - field type
EC <	mov	al, dh					>
EC <	call	DSIsFieldTypeValid			>
EC <	ERROR_C	INVALID_FIELD_TYPE			>

EC <	cmp	cx, MAX_FIELD_SIZE			>
EC <	ERROR_A	INVALID_FIELD_SIZE			>

EC <	push	dx, es					>
EC <	mov	dl, dh					>
EC <	segmov	es, ds, ax				>
EC <	call	DSIsDataValidForField			>
EC <	ERROR_C	INVALID_FIELD_DATA			>
EC < 	pop	dx, es					>

	mov	ax, bp				; preserve ax, when no error
	clc
done:
	.leave
	ret

notPresent:
	mov	ax, DSDE_FIELD_DOES_NOT_EXIST
	stc
	jmp	done
DSGetFieldPtrCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockDataStoreAndGetFieldID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks the datastore and maps the field name to its FieldID
		if a name is passed

CALLED BY:	INTERNAL
PASS:		ax - datastore session token
		bl - DataStoreElementFlags
		cx:si - field name

RETURN:		carry clear is no error, 
			^hbx - datastore file
			^hcx - record block, if there is a current record
			 dl - fieldID
		carry set if error,
			bx - DataStoreError
			datastore is unlocked
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockDataStoreAndGetFieldID		proc	far
	uses	ax, es, di
	.enter

	push	cx
	call	DMLockDataStore		; bx - file handle or error
	pop	di			; di:si - field name
	jc	done			; bx - DataStoreError

	; check if a field name is passed

	tst_clc	di
	jz	done

	; check if passed name is valid and corresponding field id

	push	ax
EC <	mov	ax, cx						>
EC <	call	ECCheckRecordBlock				>

	mov	es, di			; es:si - field name
	mov	di, si			; es:di - field name
	call	DFMapNameToToken
	mov	dl, al			; dl - field id
	pop	ax			; ax - datastore session token
	jnc	done

	call	DMUnlockDataStore
	mov	bx, DSDE_INVALID_FIELD_NAME
		
done:
	.leave
	ret
LockDataStoreAndGetFieldID		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSAllocSpecialBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates an lmem block

CALLED BY:	INTERNAL
PASS:		dx - block header size
		cx - size of block (including header)
RETURN:		carry set if error,
		else ax - segment of block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/13/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSAllocSpecialBlock		proc	far
		uses	bx, cx, si, di
		.enter

		mov	ax, cx
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; bx <- handle, ax <- segment
		jc	exit

		push	ds
		mov	ds, ax
		
		mov     ax, LMEM_TYPE_GENERAL
		mov	di, mask LMF_RETURN_ERRORS
		mov	cx, 1			;allocate 1 handle intially
		mov	si, size RecordHeader+3	;initial heap size - header
		and	si, 0xfffc		; size rounded up to dword size
		call	LMemInitHeap

		mov	ax, ds
		pop	ds
		clc
exit:
		.leave
		ret
DSAllocSpecialBlock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGetFieldInfoByID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Gets field header size for a given field, field	data
		size if the field is of fixed length, field flags and type.
		
CALLED BY:	DataStoreSetField
PASS:		bx - file handle
		dl - field ID
RETURN:		if carry set, ax - error
		else	ax - field data size,0 if variable-length field 
			0 if variable size
			cl - header size
			ch - field flags
			dl - field type
			dh - field category
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGetFieldInfoByID	proc	far
	fieldInfo	local	FieldData
	uses	di,es
	.enter
	;
	; check info for the given field
	;
	segmov	es, ss, ax
	lea	di, fieldInfo		; esdi - field data struct
	mov	al, dl
	call	DFMapTokenToData
	jc	exit

	mov	dl, fieldInfo.FD_type
EC <	mov	al, dl					>
EC <	call	DSIsFieldTypeValid			>
EC <	ERROR_C INVALID_FIELD_TYPE			>

	mov	dh, fieldInfo.FD_category
EC <	mov	al, dh					>
EC <	call	DSIsFieldCategoryValid			>
EC <	ERROR_C INVALID_FIELD_CATEGORY			>

	mov	ch, fieldInfo.FD_flags
EC <	mov	al, ch					>
EC <	call	DSIsFieldFlagValid			>
EC <	ERROR_C INVALID_FIELD_FLAGS			>

	mov	al, dl
	call	DSGetFieldSizeByType
					; pass: al - field type
					; return: if carry set, ax - error
					;    else ax - size, 0 if variable size
					;	  cl - header size
EC <	ERROR_C	INVALID_FIELD_TYPE				>

done:	.leave
	ret
exit:				;move this part here to avoid
				;unnessesary instruction when
				;valid, which is most likely true.
	mov	ax, DSDE_INVALID_FIELD_ID
	jmp	done
DSGetFieldInfoByID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIsFieldInRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a field with given id exists in the given 
		record. 

CALLED BY:	DataStoreSetField
PASS:		bx - file handle
		ds:si - ptr to record
		dl - field ID
RETURN:		if carry set, ax - error message
		*note: in this routine it is not an error if the field
			is not present.
		else
			cx - field size including header, 0 if not present
			si - offset of stop point
			al - field header type
			ah - field flags
			dh - field type
			dl - field id

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSIsFieldInRecord	proc	far
	fid		local	byte
	fFlags		local	byte
	uses	bx,di
	.enter
	mov	fid, dl

	call	DSGetFieldInfoByID	
	mov	dh, dl			; field type --> dh
	mov	fFlags, ch
	jc	exit

	clr	ch
	push	cx, ax		; cx - size of header, 
				; ax - size of data, 0 if variable
				; field size

	mov	cl, ds:[si].RH_fieldCount
	add	si, size RecordHeader
	jcxz	notFound

	; non-empty record
	mov 	dl, fid
scanNextField:
	.assert	FH_id eq FHF_id
	cmp	dl, ds:[si].FH_id	; dl - field id
	je	found
	jl	notFound

	call	DSGetFieldSize	; ax - size including header
EC <	ERROR_C 	INVALID_FIELD_ID			>
	
	add	si, ax

	loop	scanNextField

notFound:
	pop	cx, ax
	clr	cx
	jmp	done

found:
	pop	cx, ax
	add	cx, ax
	tst	ax
	jnz	done
	mov	cx, ds:[si].FH_size
done:
	clc
	mov	ah, fFlags

exit:
	.leave
	ret
DSIsFieldInRecord     endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSParseField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parses a field

CALLED BY:	EXTERNAL
PASS:		ds:si - field header
		^hbx - file handle
RETURN:		carry set if error
		else   	cx - field content size
		   	al - field type
			ah - field category
			dl - field id
			dh - field flags
			dsdi - field content
DESTROYED:	if carry set, then ax, cx, dx are trashed.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSParseField	proc	far
	uses	bx, es
	.enter

	.assert	offset FHF_id eq offset FH_id
	mov	dl, ds:[si].FH_id
	call	DSGetFieldInfoByID	; ax - 0, if variable-length field 
					; cl - header size
					; ch - field flags
					; dl - field type
					; dh - field category
EC <	ERROR_C	INVALID_FIELD_ID				>

	push	dx			; save type and category
	mov	dh, ch
	mov	dl, ds:[si].FH_id

	clr	ch			; cx - field header size

	mov	di, si
	add	di, cx			; ds:di <- field data
	tst	ax			; variable length field?
	jnz	$20

EC <	cmp	cx, size FieldHeader		>
EC <	ERROR_NE CORRUPT_FIELD_SIZES		>
	mov	ax, ds:[si].FH_size
	sub	ax, cx			; ax - field data size
EC <	ERROR_C	INVALID_FIELD_SIZE	; corrupt field size 	>

$20:
	mov	cx, ax			; cx - field data size
EC <	cmp	cx, MAX_FIELD_SIZE				>
EC <	ERROR_A	INVALID_FIELD_SIZE	; corrupt field size 	>

	segmov	es, ds, ax
	pop	ax			; get type and category
	xchg	ax, dx			; ax - id , flags & dx - type, cat
	call	DSIsDataValidForField
EC <	ERROR_C	INVALID_FIELD_DATA	; corrupt field size 	>
	xchg	ax, dx			; ax - type, cat & dx - id, flags
NEC <	jnc	exit						>
NEC <	mov	ax, DSDE_INVALID_FIELD_DATA   ; in case of error>

NEC < exit:							>
	.leave
	ret
DSParseField	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGetBufferRecordFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the flags of the buffer.

CALLED BY:	EXTERNAL
PASS:		^hbx - record buffer
RETURN:		al - buffer flags
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGetBufferRecordFlags	proc	far
	uses	ds
	.enter
EC <	call	ECCheckMemHandle				>
	call	MemLock
EC <	ERROR_C	BAD_BUFFER_LMEM_BLOCK				>
	mov	ds, ax
	mov	al, ds:[RLMBH_flags]
	call	MemUnlock
	.leave
	ret
DSGetBufferRecordFlags	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeWithFieldFound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resizes the record chunk when the field already exits 
		and set the field size if resize is successful.

CALLED BY:	DataStoreSetField
PASS:		dsdi - ptr to record
		dssi - ptr field
		al - field header type, 0, if FieldHeader
			else, FieldHeaderFixed
		dx - current field data size
		cx - new field data size
		bx - ^h of record
		
RETURN:		if carry set, ax - error (DataStoreDataError)
		 else	dssi- ptr to field content
		dsdi - ptr to record
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeWithFieldFound	proc	near
	uses	bx,cx,dx,bp
	.enter


CheckHack <	DS_NON_FIXED_FIELD eq 0		>
	tst	al			; 0 is variable length field
	mov	bp, size FieldHeader
	jz	10$
	mov	bp, size FieldHeaderFixed	; bp - field header size

10$:
	cmp	dx, cx
	je	done
	
	;
	; different size
	;
	mov	ax, bx		; ax - ^h chunk
	mov	bx, si
	sub	bx, di
	add	bx, bp		; bx - offset to delete or insert

	cmp	dx, cx
	jl	expand
	;
	; need to shrink the chunk
	;
	sub	dx, cx
	xchg	cx, dx		; cx - # bytes to delete, dx - new
				; field size
	call	LMemDeleteAt
	sub	ds:[di].RH_size, cx
	sub	ds:[si].FH_size, cx
	jmp	done

expand:
	push	bx
	mov	bx, cx
	sub	cx, dx		; cx - # bytes to insert
	add	dx, bx		; dx - new field size
	pop	bx
	call	LMemInsertAt

	mov	bx, ax
	mov	ax, DSDE_MEMORY_FULL
	jc	exit
	sub	si, di		; si - offset of the field from 
				; the begining of the record
	;
	; the block might have moved, re-derefrence the chunk handle
	;
	mov	di, bx
	mov	di, ds:[di]	; di - offset of the record
	add	ds:[di].RH_size, cx
	add	si, di		; si - offset of field header
	
			
	add	ds:[si].FH_size, cx

done:
	clc				; in case carry is trashed
	add	si, bp			; si - offset of field data
exit:
	.leave
	ret
ResizeWithFieldFound	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeWithFieldNotFound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resizes the record chunk when the field doesn't exit
		in the record, initializes header and increment field 
		count if resize is successful.

CALLED BY:	DataStoreSetField
PASS:		dsdi - ptr to record
		dssi - ptr to where to insert
		ax - field header type, 0, if FieldHeader
					   else FieldHeaderFixed
		dx - current field size
		cx - new field size
		bx - ^h of record chunk
RETURN:		if carry set, ax - errror message (DataStoreDataError)
		else, dssi - ptr to field content
		dsdi - ptr to record (ds may have been moved)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeWithFieldNotFound	proc	near
	uses	bx,cx,bp
	.enter

CheckHack <	DS_NON_FIXED_FIELD eq 0		>
	tst	al			; 0 is variable length field
	mov	bp, size FieldHeader
	jz	10$
	mov	bp, size FieldHeaderFixed	; bp - field header size

10$:
	; check field count
	mov	al, ds:[di].RH_fieldCount
	cmp	al, 0xff
	je	done1

	;
	; resize the buffer block make sure there is enough space
	;
	mov	ax, bx
	mov	bx, si
	sub	bx, di			; bx - offset to insert
	add	cx, bp			; cx - # bytes to insert
	call	LMemInsertAt
	jc	done2

	sub	si, di
	; the block might have moved, re-derefrence the chunk handle
	mov	di, ax
	mov	di, ds:[di]		; di - offset of the record
	add	si, di			; si - offset of field header

	; increment field count and record size
	add	ds:[di].RH_fieldCount, 1
	add	ds:[di].RH_size, cx

	;
	; initialize the field header
	;

	.assert	offset FHF_id eq offset FH_id
	mov	ds:[si].FH_id, dl

	cmp	bp, size FieldHeader
	jne	initFixedFH
	mov	ds:[si].FH_size, cx	; cx - field size

initFixedFH:
	clc				; in case carry is trashed
	add	si, bp

exit:
	.leave
	ret
done1:	mov	ax, DSDE_TOO_MANY_FIELDS
	stc
	jmp	exit
done2:	mov	ax, DSDE_MEMORY_FULL
	jmp	exit

ResizeWithFieldNotFound	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIsDataValidForField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a given field has valid data.

CALLED BY:	EXT
PASS:		^hbx - file handle
		es:di - field data
		dl - field type
		cx - data size
RETURN:		carry set if not valid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		10) no check if it is a fixed size field
		20) check printable for DSFT_STRING

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSIsDataValidForField	proc	far
		uses	ax, bx, cx, dx
		.enter

EC <		cmp	dl, DataStoreFieldType					>
EC <		ERROR_AE INVALID_FIELD_TYPE				>

		clc				; no error if field is empty
		jcxz	done			; no data - exit

		clr	dh
		mov	bx, dx
		shl	bx, 1
		call	cs:validateDataJumpTable[bx]
done:		
		.leave
		ret
DSIsDataValidForField	endp


validateDataJumpTable	nptr	ValidateFloat,		; DSFT_FLOAT
				ValidateShort,		; DSFT_SHORT
				ValidateLong,		; DSFT_LONG
				ValidateTimeStamp,	; DSFT_TIMESTAMP
				ValidateDate,		; DSFT_DATE
				ValidateTime,		; DSFT_TIME
				DSIsDataPrintable,	; DSFT_STRING
				ValidateOkay,		; DSFT_BINARY
				ValidateOkay,		; DSFT_GRAPHIC
				ValidateOkay		; DSFT_INK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Validate...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the passed data, which is of the passed type

CALLED BY:	DSIsDataValidForField
PASS:		dl - DataStoreFieldType
		cx - data size
		es:di - data
RETURN:		carry set if data is invalid
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/20/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValidateOkay		proc	near
		.enter
		clc
		.leave
		ret
ValidateOkay		endp


ValidateFloat		proc	near
		.enter
		cmp	cx, size FloatNum
		stc
		jne	done
		clc
done:
		.leave
		ret
ValidateFloat		endp


ValidateShort		proc	near
		.enter
		cmp	cx, size word
		stc
		jne	done
		clc
done:
		.leave
		ret
ValidateShort		endp


ValidateLong		proc	near
		.enter
		cmp	cx, size dword
		stc
		jne	done
		clc
done:
		.leave
		ret
ValidateLong		endp


ValidateDate		proc	near
		uses	ax, bx, cx
		.enter

		cmp	cx, size DataStoreDate
		jne	error
		mov	bl, es:[di].DSD_month
		cmp	bl, 12
		ja	error
		cmp	bl, 1
		jb	error

		mov	ax, es:[di].DSD_year
		call	LocalCalcDaysInMonth
		cmp	es:[di].DSD_day, ch
		ja	error
		cmp	es:[di].DSD_day, 1
		jb	error
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
ValidateDate		endp


ValidateTime		proc	near
		.enter

		cmp	cx, size DataStoreTime
		jne	error
		cmp	es:[di].DST_hour, 24
		ja	error
		cmp	es:[di].DST_minute, 60
		ja	error
		cmp	es:[di].DST_second, 60
		ja	error
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
ValidateTime		endp

ValidateTimeStamp	proc	near
		ret
ValidateTimeStamp	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIsDataPrintable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the given string is valid
		(contains only printable chars)

CALLED BY:	EXTERNAL
PASS:		es:di - data
		cx - # of bytes to check
RETURN:		carry set, if there is non-printable data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSIsDataPrintable	proc	near
	uses	ax, cx, si, ds
	.enter
	
	clc	
	jcxz	done
	segmov	ds, es, ax
	mov	si, di
SBCS <	clr	ah						>
DBCS <	shr	cx						>
DBCS <	ERROR_C -1						>
nextChar:
	LocalGetChar	ax, dssi
	call	LocalIsPrintable 
	jz	nonPrintable
	loop	nextChar

done:
	.leave
	ret
nonPrintable:
	stc
	jmp	done
DSIsDataPrintable	endp

MainCode ends

