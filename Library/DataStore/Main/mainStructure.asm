COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	DataStore
MODULE:		Main
FILE:		mainStructure.asm

AUTHOR:		Wenyong Yang, Oct 12, 1995

ROUTINES:
	Name			Description
	----			-----------
GLB	DataStoreAddField	Adds a field to the datastore schema
GLB	DataStoreRenameField	Renames a field
GLB	DataStoreDeleteField	Deletes a field and field data from
				each record.
GLB	DataStoreFieldEnum	Enumerates all fields of a locked
				record with given ds token.
GLB	DataStoreBuildIndex	Builds an index for the datastore in
				a passed block. Index is not used by
				the datastore library, only a ref. for apps.

INT	DeleteFieldCB		Deletes a field's data from a locked
				record.

EXT	DSFieldEnumCommon	Enumerates all fields of a locked 
				record with given file handle.
EXT	DSIsFieldTypeValid	Checks for valid field type
EXT	DSIsFieldCategoryValid	Checks for valid field category
EXT	DSIsFieldFlagValid	Checks for valid field flags
EXT	DSIsAddFieldFlagValid	Checks for valid field flags
				record
EXT	DSValidateDataStoreIndexParams
				Validates the parameters passed
				into DataStoreBuildIndex.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/12/95   	Initial revision


DESCRIPTION:
	This file contains high level routines for manipulating
	datastore structure.
	
	Note that the low level routines are defined in File module.
		

	$Id: mainStructure.asm,v 1.1 97/04/04 17:53:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MainStructureCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreAddField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a field to the datastore schema.  No duplicate
		field name is allowed.

CALLED BY:	GLOBAL
PASS:		ax - datastore token
		es:di - ptr to a field descriptor
RETURN:		if carry set,
			ax - DataStoreStructureError
		else
			al - FieldID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	4) check for valid field type
	6) check for time stamp field
	8) check for valid field category
	10) check flag
	11) check field name's length
	18) call internal DSAddField to add a field
	20) return field id 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreAddField	proc	far
	uses	bx,cx
	.enter

	mov	bx, ax		; bx - datastore token
	;
	; check not to add a timestamp field
	;
	cmp	es:[di].FD_type, DSFT_TIMESTAMP
	mov	ax, DSSE_TIME_STAMP_CANNOT_BE_ADDED
	stc
	je	exit
	clc
	;
	; check type
	;
	mov	al, es:[di].FD_type
	call	DSIsFieldTypeValid
	mov	ax, DSSE_INVALID_FIELD_TYPE
	jc	exit
	;
	; check category
	;
	mov	al, es:[di].FD_category
	call	DSIsFieldCategoryValid
	mov	ax, DSSE_INVALID_FIELD_CATEGORY
	jc	exit
	;
	; Only valid flag is FF_DESCENDING
	;
	mov	al, es:[di].FD_flags
	call	DSIsAddFieldFlagValid				
	mov	ax, DSSE_INVALID_FIELD_FLAGS
	jc	exit
	;
	; check field name's length
	;
	push	es, di
	les	di, es:[di].FD_name
	call	LocalStringLength
	pop	es, di
	cmp	cx, MAX_FIELD_NAME_LENGTH + 1
	mov	ax, DSSE_FIELD_NAME_TOO_LONG
	cmc				; if cx > MAX_FIELD_NAME_LENGTH
					; carry is set, else carry is clear
	jc	exit
	;
	; get file handle
	;
	mov	ax, bx			;ax - datastore token
	mov	bl, mask DSEF_WRITE_LOCK
	call	DMLockDataStore		; pass: ax - datastore token
					;	bl - lock flags
					; return: if carry set, 
					;	bx - error
					; 	  else bx - file handle
					;	       cx - buffer handle
	xchg	ax, bx
	jc	exit
	xchg	ax, bx			;bx - file handle
	mov	cx, ax			;cx - datastore token

	;
	; add the field, will check for duplicate field names
	;
	call	DFAddField		; bx - file handle
					; return: if carry set
					;  	ax - error
					;	else al - field id
	xchg	ax, cx			;ax - datastore token
	call	DMUnlockDataStore	;flags preserved
	xchg	ax, cx			;ax - return value, cx - token
	jc	exit

	xchg	ax, cx			; cl - field id
	mov	bx, DSCT_FIELD_ADDED
	call	DFSendDataStoreNotification 
	mov	ax, cx
	clc	
exit:
	.leave
	ret
DataStoreAddField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreRenameField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes the name of a field of the given data store.
		No duplicate field name is allowed.

CALLED BY:	GLOBAL
PASS:		ax - DataStore token
		es:di - new field name, null terminated string
		bx:si - old field name, null terminated string
			pass bx=0 to only use field id.
		dl - FieldID, field id is ignored if bx is non-zero.
RETURN:		ax - DataStoreStructureError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	wy	10/23/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreRenameField		proc	far
		uses	ds, bx, cx, dx, bp
		.enter
	
	mov	bp, bx
	mov	bl, mask DSEF_WRITE_LOCK
	call	DMLockDataStore			; if carry set, bx -
						; error else 
						; bx - file handle
						; cx - buffer handle

	mov	cx, ax				; cx - dstoken
	mov	ax, bx
	jc	done


	push	cx
	;
	; check if new field name is valid
	;
	call	LocalStringLength
	cmp	cx, MAX_FIELD_NAME_LENGTH
	pop	cx
	mov	ax, DSSE_FIELD_NAME_TOO_LONG
	stc
	jg	exit

	call	DFMapNameToToken
	mov	ax, DSSE_FIELD_NAME_EXISTS
	cmc
	jc	exit

	tst	bp
	jz	useID

	mov	ds, bp			; ds:si - old field name
	;
	; use the old field name
	;
	push	es, di
	segmov	es, ds, ax
	mov	di, si
	call	DFMapNameToToken	; al - field id
	pop	es, di
	mov	dl, al
	mov	ax, DSSE_INVALID_FIELD_NAME
	jc	exit

useID:
	mov	al, dl
	call	DFRenameField		; pass: al - fieldID
					;	bx - ^h file
					;	esdi - new name
					; return: carry set if
					; invalid fieldID

	mov	ax, DSSE_INVALID_FIELD_ID

exit:	
	xchg	ax, cx			; ax - datastore token
	call	DMUnlockDataStore
	xchg	ax, cx			; ax - error code
	jc	done

	mov	ax, cx
	mov	bx, DSCT_FIELD_RENAMED
	call	DFSendDataStoreNotification 
	mov	ax, DSSE_NO_ERROR
	clc	
done:
	.leave
	ret
DataStoreRenameField		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreDeleteField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a field from the DataStore schema and from 
		every record in the DataStore which has the field

CALLED BY:	GLOBAL
PASS:		ax - DataStore token
		cx:si - field name, null-terminated string
			pass cx=0 to only use field id.
		dl - FieldID, field id is ignored if cx is non-zero.
RETURN:		ax - DataStoreStructureError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		10) check if the dsToken is valid and get file handle
    		and  get exclusive access to the file
		15) check if there is a current record in buffer if so, exit
		18) check if some app. has a current record out of the
		datastore, if so, return error 
		20) check if the given field is valid, and 
    		if it is not a key field or time stamp field
		40) recursively delete the field data from each 
    		record of the file
		46) delete the field from the datastore schema
		50) release the exclusive
		58) send notification
		60) return


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreDeleteField	proc	far
	dsToken		local	word	push	ax
	; local variables used in DFDeleteFieldCB
	fid		local 	byte
	fHandle		local 	word
	recIndex	local	dword
	uses	bx,cx,dx,si,di
	.enter

	;
	; check if the dsToken is valid and get file handle, buffer handle
	;
	mov	bl, mask DSEF_WRITE_LOCK
	call	LockDataStoreAndGetFieldID
	mov	ax, bx
	LONG	jc	done
	;
	; check if there is a current record in buffer if so, exit
	;
	mov	ax, DSSE_RECORD_BUFFER_NOT_EMPTY
	tst	cx
	LONG	jnz	errorUnlock

	mov	fHandle, bx
	mov	fid, dl
	;
	; check if some app. has a current record out of the
	; datastore, if so, return error 
	;
	call	DMIsDataStoreBuffered		; bx - file handle
						; return: carry set,if true
	mov	ax, DSSE_ACCESS_DENIED
	jc	errorUnlock
	;
	; check for primary key or timestamp field
	;
	call	DSGetFieldInfoByID
	jc	errorUnlock
	test	ch, mask FF_PRIMARY_KEY or mask FF_TIMESTAMP
	LONG	jnz	deleteError
	;
	; Delete the field data from each record in the file
	;
	call	DFGetRecordCount		; pass: ^hbx - file handle
						; return: dxax - count
	decdw	dxax						 
	movdw	recIndex, dxax

	push	bx				; file handle
	pushdw	dxax				; record to start at
	mov	ax, -1			
	pushdw	axax				; process all records
	mov	ax, vseg DeleteFieldCB
	push	ax
	mov	ax, offset DeleteFieldCB
	push	ax				; callback
	push	bp				; callback data
	;
	; callback modifies records, and because of that, we
	; have to enumerate them backwards
	;
	mov	ax, mask DSREF_BACKWARDS or DSREF_MODIFY_RECORDS
	call	DFRecordArrayEnum
EC <	ERROR_C	-1						>
	;
	; delete the field from the datastore schema
	;
	mov	al, fid
	mov	bx, fHandle
	call	DFRemoveField
EC <	ERROR_C	INVALID_FIELD_ID				>

	mov	ax, dsToken
	call	DMUnlockDataStore		; preserves flags

	mov	cl, fid
	mov	bx, DSCT_FIELD_DELETED
	call	DFSendDataStoreNotification 	; preserves flags
	mov	ax, DSSE_NO_ERROR

done:
	.leave
	ret

errorUnlock:
	push	ax
	mov	ax, dsToken
	call	DMUnlockDataStore
	pop	ax
	jmp	done

deleteError:
	;
	; check for time-stamp field
	;
	mov	ax, DSSE_DELETE_PRIMARY_KEY
	test	ch, mask FF_PRIMARY_KEY	; ch - field flags
	jnz	errorUnlock
EC <	test	ch, mask FF_TIMESTAMP					>
EC <	ERROR_Z -1							>
	mov	ax, DSSE_TIME_STAMP_CANNOT_BE_DELETED
	jmp	errorUnlock		
DataStoreDeleteField	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteFieldCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine used to delete field.

CALLED BY:	DataStoreDeleteField
PASS:		ds:di - ptr to record

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		10) check if the field is present
		20) remove the field
		30) resize the record and mark it dirty

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteFieldCB	proc	far
	uses	ax,bx,cx,dx,si,es
	.enter	inherit DataStoreDeleteField

	;
	; check if the field is present
	;
	mov	si, di
	mov	dl, fid
	mov	bx, fHandle
	call	DSIsFieldInRecord		; dssi - ptr to field header
						; al - 0, for variable 
						; 	size field
						; cx - field size

	jc	exit				; error, abort the
						; enum.
	jcxz	nextRecord			; field is not present
	;
	; remove the field
	;

	push	di

	mov	ax, ds:[di].RH_size
	mov	bx, ax				; bx - old record size

	sub	ax, cx				; ax - new record size 

	;
	; update the record size and field count
	;
	mov	ds:[di].RH_size, ax
	dec	ds:[di].RH_fieldCount

	add	di, bx			; dsdi - end of record	
	add	si, cx				; dssi - ptr to next field
	cmp	di, si
	je	truncateRecord
EC <	ERROR_C	INVALID_RECORD_SIZE		> ; carry set, if di < si

	sub	di, si			; di - # of bytes to copy
	mov_tr 	bx, di

	mov	di, si
	sub	di, cx				
	segmov	es, ds, cx			; dssi - source
						; esdi - destination
	mov_tr 	cx, bx
	rep	movsb

truncateRecord:
	mov	bx, fHandle
	mov	cx, ax
	movdw	dxax, recIndex
	call	DFTruncateRecord		; pass: ^hbx - file handle
						;	dxax - element number
						;	cx - new size
						; return: nothing
	pop	di
EC <	mov	si, di					>
EC <	call	ECCheckRecordPtr			>

nextRecord:
	pushf
	decdw	recIndex
	popf
exit:	
	.leave
	ret
DeleteFieldCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreFieldEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerates and calls the callback routine for each
		field of the given record
	
CALLED BY:	GLB
PASS:		ax - datastore token
		ds:si - ptr to RecordHeader
		bx:di - vfptr to callback routine

		Callback routine:
			Pass:
				ds:di - ptr to field content
				cx - field content size
				al - field type
				ah - field category
				dl - field id
				dh - field flags
				bp - callback data
			Return:
				carry set to stop enum
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreFieldEnum	proc	far
	uses	ax,bx, cx
	.enter

EC <	tst	bx				>
EC <	ERROR_Z	-1				>
	push	ax
	push	bx
	mov	bl, mask DSEF_READ_LOCK
	call	DMLockDataStore			; ^hbx - file handle 
	pop	ax				; ax - segment of callback
	jc	error

EC <	call	ECCheckRecordPtr				>
	xchg	ax, bx
	call	DSFieldEnumCommon

	pop	ax
	call	DMUnlockDataStore

exit:		
	.leave
	ret
error:
	pop	ax
	jmp	exit

DataStoreFieldEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSFieldEnumCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerates fields of the given record with file
		handle known.

CALLED BY:	EXTERNAL
PASS:		^h ax - file handle
		ds:si - ptr to RecordHeader
		bx:di - vfptr to callback routine
		Callback routine:
			Pass:
				ds:di - ptr to field content
				cx - field content size
				al - field type
				ah - field category
				dl - field id
				dh - field flags
				bp - callback data
			Return:
				carry set to stop enum
			Destroy: 
				nothing
RETURN:		carry - if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSFieldEnumCommon	proc	far
	callbackBP	local	word	push	bp
	callback	local	vfptr	push	bx, di		
	fHandle		local	word	push	ax
	numFields	local	word

	uses	ax, bx, cx, dx, di, si 
	.enter

	clr	ch
	clr	ah
	mov	al, ds:[si].RH_fieldCount
	mov	numFields, ax
	tst_clc	ax
	jz	exit
	add	si, offset RH_fieldData

nextField:
EC <	Assert	fptr, dssi						>
	;
	; parse the field
	;
	mov	bx, fHandle
	call	DSParseField			; pass: dssi-fieldheader
						;	^hbx- file handle
						; return: carry set if error
						;else 	cx - field content size
						;    	al - field type
						;	ah - field category
						;	dl - field id
						;	dh - field flags
						;	dsdi - field content
EC <	ERROR_C	INVALID_FIELD_ID			>
	;	
	;	Call the callback routine
	;
	mov	ss:[TPD_dataAX], ax
	movdw	bxax, callback
	push	cx, bp, ds, di
	mov	bp, callbackBP
	call	ProcCallFixedOrMovable
	mov_tr	ax, bp
	pop	cx, bp, ds, di
	mov	callbackBP, ax
	jc	exit

	add	di, cx
	mov	si, di				; dssi - header for
						; next field
	dec	numFields
	jnz	nextField
	clc
exit:
	.leave
	ret
DSFieldEnumCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIsFieldTypeValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a field type is defined

CALLED BY:	DataStoreAddField
PASS:		al - field type to check
RETURN:		carry set if invalid
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSIsFieldTypeValid	proc	far
	.enter
	cmp	al, DataStoreFieldType	; FieldType = DSFT_BINARY + 1, where the
				; DSFT_BINARY is the last field type defined

	cmc			; if al is within defined field types,
				; clear the carry flag, else set carry

	.leave
	ret
DSIsFieldTypeValid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIsFieldCategoryValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a field category is defined

CALLED BY:	DataStoreAddField
PASS:		al - field category to check
RETURN:		carry set if invalid
DESTROYED:	al
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSIsFieldCategoryValid	proc	far
	.enter
	cmp	al, FieldCategory
	cmc			; if al is within defined field categories,
				; clear the carry flag, else set carry

	.leave
	ret
DSIsFieldCategoryValid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIsAddFieldFlagValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the field flags are valid for a field
		the user wishes to add - only FF_DESCENDING is valid

CALLED BY:	DataStoreAddField
PASS:		al - field flags
RETURN:		carry set if invalid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSIsAddFieldFlagValid	proc	far
	.enter

	test	al, not mask FF_DESCENDING
	jz	done			;valid flag
	stc				;invalid flag, set carry
done:
	.leave
	ret
DSIsAddFieldFlagValid	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSValidateIndexParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the parameters passed to DataStoreBuildIndex.

CALLED BY:	(internal) DataStoreBuildIndex
PASS:		bx - data store file handle
		ds:si - array id DataStoreIndexCallbackParams
	
RETURN:		if carry set
			ax - DataStoreStructureError
		else
			ax - trashed		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JPD	3/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSValidateIndexParams	proc	near

EC<	call 	ECCheckFileHandle				>

	mov	al, ds:[si].DSICP_indexField
	call	DFCheckValidFieldID
	jc	fieldIdError

	mov	al, ds:[si].DSICP_sortOrder
	cmp	al, SO_DESCENDING
	ja	sortError

exit:
	ret

fieldIdError:
	mov	ax, DSSE_INVALID_FIELD_ID
	jmp	exit
	
sortError:
	mov	ax, DSSE_INVALID_SORT_ORDER
	stc
	jmp	exit

DSValidateIndexParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIndexAllocMemBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates and intializes the structure of an
		index head Mem block to the structure values passed in
		a DataStoreIndexParams structure. The space needed 
		for the array of record number is allocated and
		initialized with record numbers.
		
CALLED BY:	(INTERNAL) DataStoreBuildIndex
PASS:		es:di - DataStoreIndexCallbackParams
		ax    - record count
		dx    - The size of the index block header.
		
RETURN:		if carry set
			ax - DSSE_MEMORY_FULL
			ds, bx trashed
		else 
			ds - segment of new index Mem block
			bx - locked handle of new index Mem block
		     	     

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	10.) Allocate the index Mem block.
	20.) Lock the block and initialize the Header block.
	30.) Initialize index array with
	     record numbers from 0 to recordsCount-1.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JPD	3/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSIndexAllocMemBlock	proc	near
recCt    	local	word	push	ax
	uses	cx,dx,si,di,bp,es
	.enter 

	; Allocate the index Mem block
	mov	ax, size IndexArrayBlockHeader
	cmp 	ax, dx
	jge	sizeHeader
	mov	ax, dx

sizeHeader: 
  	push	ax
	mov	cx, recCt	; recCount*2 == size of actual index array
	shl	cx, 1
	add	ax, cx		; total size to allocate.
	mov  	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		; bx <- handle, ax <- segment
	jc	memError
	mov	ds, ax			; ds - segment of index block
				
	mov	cl, es:[di].DSICP_sortOrder
	mov	ch, es:[di].DSICP_indexField
	mov	ds:[IABH_sortOrder], cl
	mov	ds:[IABH_indexField], ch
	mov	cx, recCt
	mov	ds:[IABH_recCount], cx

	pop	si			; index offset
	mov	ds:[IABH_array], si	; store array offset

	clr	ax			; ax = 0 , first element of array
	mov	cx, recCt		; number of times to loop
initLoop:
	mov	ds:[si], ax
	add	si, size word		; one word for one record #
	inc	ax
	loop 	initLoop
					; now array contains all the
					; record numbers

	clc				; return no error
exit:   
	.leave
	ret

memError:
	pop	ax			; reset stack
	mov 	ax, DSSE_MEMORY_FULL	; carry is already set
	jmp 	exit

DSIndexAllocMemBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreBuildIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An index built using this routine is external to the 
		DataStore library manager. The only index the
		DataStore library maintains internally is the primary 
		key index specified when the datastore is created.

		This routine builds an index as an array 
		of record numbers for the datastore and then returns a 
		memory block containing the array of these 
		record numbers (low word only!). 

		There is no mechanism to have the DataStore library
		automatically update an index built by this routine.
		Instead, an application must call this routine to
		rebuild the index. An application can know when to 
		rebuild the index by receiving change notifications
		for this DataStore, and looking for those which.
		might effect the index.

CALLED BY:	GLOBAL
PASS: 		ax - datastore token
		ds:si - array of DataStoreIndexCallbackParams
		dx - size of IndexArray header,
			0 to use default size (IndexArrayBlockHeader)
		bp - callback data (on stack)
		cx:di - callback routine to do comparison
		    Callback is passed:
			ax - datastore token
			ds:si - fptr to DataStoreIndexCallbackParams
			bp - callback data
		    Return:
			ax = -1,  if record 1 comes before record 2 
			ax =  1,  if record 1 comes after record 2
RETURN:	if carry set:
		    ax - DataStoreStructureError
		else
		        ^hbx - IndexArray block

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JPD	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreBuildIndex	proc	far
	callbackData	local	word	push	bp
	params		local	fptr	push	ds, si
	callback	local	fptr	push	cx, di
	headerSize	local	word	push	dx
	dsToken		local	word	push	ax
	indexMh		local	word	
	dsHandle	local	word
	recCount	local	word
	fieldNum	local	byte
	sortOrder	local	byte
	indexOffset	local	word
	pivotPtr	local	fptr
	lMovePtr	local	word
	rMovePtr	local	word
	pivotSize	local	word
	ForceRef	callbackData
	ForceRef	callback
	ForceRef	params
	ForceRef	pivotPtr
	ForceRef	lMovePtr
	ForceRef	rMovePtr
	ForceRef	pivotSize
	ForceRef	indexOffset
	uses	cx,dx,ds,di,bp,es
	.enter
		
		
	mov	bl, mask DSEF_WRITE_LOCK
	call	DMLockDataStore		; 
	mov	ax, bx			; ax - DataStoreError or filehandle
	LONG jc	exit			; ax - error, bad token or no lock 
	mov	dsHandle, bx		

	call 	DSValidateIndexParams	; check passed params

	mov	ax, dsToken
	call	DMIndexLockDataStore	; grab exclusive index lock
	LONG jc	indexLockExit		; failed 
	
	call	DFGetRecordCount	; 
	LONG jz	recError		; no records, return error
	tst	dx			; any records in the datastore?
	LONG ja tooManyError
	mov	recCount, ax
		
	movdw	esdi, params
	mov	al, es:[di].DSICP_indexField
	mov	fieldNum, al        
	mov	al, es:[di].DSICP_sortOrder
	mov	sortOrder, al

	mov	dx, headerSize
	mov	cx, callbackData
	mov	ax, recCount
	call 	DSIndexAllocMemBlock	; bx - index block handle
					; ds -index block segment
					; Block is initilized to 
					; contain all the record # in
					; the single block. All the
					; index building is to be done
					; within the block. The block
					; is locked. 

	LONG jc	lockExit		; error allocating block
	mov	indexMh, bx
	mov	ax, ds:[IABH_array]
	mov	indexOffset, ax		; preserve it for other routines
 	call 	DSIndexBuild		; do the dirty deed
					; ax - error or trash
lockExit:
	pushf
	xchg	ax, dsToken
	call	DMIndexUnlockDataStore  ; flags preserved
	call	DMUnlockDataStore	; flags preserved
	xchg	ax, dsToken
	clc
	call  	MemUnlock
exit:	.leave
	ret

indexLockExit:
	mov	ax, DSSE_DATASTORE_LOCKED
	xchg	ax, dsToken
	call	DMUnlockDataStore	; flags preserved
	xchg	ax, dsToken
	jmp	exit
					
		
recError:
	mov	ax, DSSE_NO_RECORDS_IN_DATASTORE
	stc				;return error
	jmp	exit

tooManyError:
	mov	ax, DSSE_INDEX_RECORD_NUMBER_LIMIT_EXCEEDED
	stc
	jmp	exit

DataStoreBuildIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIndexBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Code to actually build an index. Broken out
		to keep DataStoreBuildIndex from getting excessively
		long. 

CALLED BY:	(INTERAL) DataStoreBuildIndex
PASSED:		
		ds - segment of locked locked index head block.
		inherit DataStoreBuildIndex 
RETURN:		if carry set
			ax - DataStoreStructureError
		else
			ax - trashed

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		The Index Array has been initialized by record
		numbers. Now sort through the array to rearrange
		the array according to the passed parameters.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JPD	3/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSIndexBuild	proc	near
	uses	bx,cx,dx,si,di,ds,bp,ds,es
	.enter inherit DataStoreBuildIndex

	clr	dx
	mov	si, indexOffset		;  - chunk handle of indexArray.

	mov	di, si			
	mov	cx, recCount		;  - the number of records
	dec	cx
	shl	cx, 1
	add	di, cx			; ds:di	-> ptr to the end of
					; index array
	mov	bx, dsHandle
	call	DSQuickSort		; sort through the record
					; numbers according to the
					; passed parameters

	.leave
	ret
DSIndexBuild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSQuickSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A quick sort routine, which sort through the record
		numbers in the index array, based on the passed 
		parameters, such as field number and field flags.
		It will check if user supplied callback execists,
		uses DSCompareElements if not.	

CALLED BY:	DSIndexBuild
PASS:		ds:si - fptr to index array 
		ds:di - fptr to the end of index array.
		        (where the unsorted recordNums are stored).
		bx    - dsHandle (dataStore handle).
	        inerit local variables from DataStoreBuildIndex
			
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	The index array is sorted.

PSEUDO CODE/STRATEGY:
		QuickSort (Robert Sedgewick) is used.
	
	void quicksort(itemType a[], int l, int r)
	  {
		int i, j; intemType v;
		if (r>l)
		  { 
			v = a[r]; i = l - 1; j = r;
			for (;;)
			 { 
			  while (a[++i] < v);
			  while (a[--i] > v);
			   if (i >= j) break;
			  swap(a, i, j)
			 }
		     swap(a, i, r)
		     quicksort(a, l, i-1)
		     quicksort(a, i+1, r)
		}
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JPD	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSQuickSort	proc	near
	uses 	cx, dx, si, di, bp
	.enter inherit DataStoreBuildIndex

	cmp	di, si		; see if ptr crossed
	jle	done		; ptr already crossed, stop.
	mov	lMovePtr, si
	mov	rMovePtr, di
	
	mov	dx, ds:[di]	; dx - pivot recordNum, Pivot(rMovePtr)
	
outerLoop:
	mov	di, rMovePtr	; restore the right side moving ptr
	mov	si, lMovePtr
	sub	si, size word	; moving the ptr to the right by one step

loop1:	
	cmp	si, rMovePtr	; see if ptr exceeds right side limit
	jge	loop2	
	add	si, size word		; leftPtr moves to next recordNum
	mov	ax, ds:[si]
	tst	callback.high
	jz      noUCB1		; no user callback defined.

	call 	UserCallback
	jmp     UCB1
noUCB1:
	call	DSCompareElements
UCB1:
	cmp	ax, -1
	jne	loop1		; the record is not greater than
				; pivot, loop again.

	; ds:si now pointing to the first element greater than pivot

loop2:
	sub	di, size word		; rightPtr moves to next recordNum
	cmp	si, di
	jg	leftHalf	; two ptrs crossed. 
				; No "out-of-position" record left
				; relative to current pivot.
				; Now it is time for "Divide-and-Conquer". 
	mov	ax, ds:[di]
	tst	callback.high
	jz      noUCB2
	call	UserCallback
	jmp	UCB2
noUCB2:
	call	DSCompareElements
UCB2:
	cmp	ax, 1
	jne	loop2		; not less than pivot, loop again.

	; ds:di now pointing to the first element less than pivot. 
	; ds:si now pointing to the first element greater than pivot.
	; Swap them!
	; Then loop to find next "out-of-position" pair to swap again.

	call 	DSSwapElements
	jmp	outerLoop	; loop to see any "out-of-position"
				; record numbers left.
	; all the swaps have been done with old pivot. Now divide
	; the set in left and right sub-sets recursively and choose
	; a pivot for each subset. Then do sorting on each subset.

	; now do the recursion call for the left subset

leftHalf:
	cmp	di, rMovePtr	
				
	jge	rightHalf	
	mov	di, rMovePtr
	call	DSSwapElements	; swap the pivot to its final position
				; before dividing the set

	mov	cx, si		
	mov	dx, rMovePtr	; define the right ptr for the subset
	mov	di, si
	sub	di, size word
	
	mov	si, lMovePtr	; define the left ptr for the subset
	mov	ax, ds:[di]	

	call	DSQuickSort

rightHalf:
	; now do the recursion call for the right subset
	mov	di, dx			; the right ptr
	mov	ax, ds:[di]
	mov	si, cx
	add	si, size word		; the left ptr
	cmp 	si, di
	ja	done			;ptrs crossed.
	call	DSQuickSort	
	
done:	
	.leave
	ret

DSQuickSort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks down the records and calls the routine which calls
		the user callback
CALLED BY:	DSQuickSort
PASS:		ax - low word of non-pivot record RecordNum
		dx - low word of pivot record RecordNum
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JPD	5/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserCallback	proc	near
	uses	 cx, dx, ds, di, si
	.enter

	; lock these two record and launch user callback
	
	push	ax
	mov	ax, dx
	clr	dx
	call	DFLockRecordNum		; lock down the pivot record 
					; ds:si <- RecordHeader
	movdw    cxdi, dssi
	pop     ax
	clr     dx
        call	DFLockRecordNum		; lock down the pivot record 
					; ds:si <- RecordHeader
	call	DSUserIndexCallbackLaunch

	push    ds
	mov     ds, cx
	call    DFUnlockRecordNum	; unlock the pivot record
	pop     ds
	call    DFUnlockRecordNum	; unlock the non-pivot record
	
	.leave
	ret
UserCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSUserIndexCallbackLaunch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch user supplied callback to do comparison
		of rec1 and rec2	

CALLED BY:	UserCallback
PASS:		cx:di - fptr to pivot record's RecordHeader
		ds:si - fptr to the RecordHeader of record to compare with.
		inherit local vars from DataStoreBuildIndex
RETURN:		ax   1; rec1 > rec2
		    -1; rec1 < rec2
		     0; rec1 = rec2
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JPD	3/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSUserIndexCallbackLaunch	proc	near
	uses	bx,cx,dx,ds,es,si,di,bp
	.enter inherit DataStoreBuildIndex

        mov     dx, di       
	les	di, params
	movdw	es:[di].DSICP_rec1, cxdx	;pivot record
	movdw	es:[di].DSICP_rec2, dssi	;the one to compare

	mov	ax, dsToken
	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], 0
	movdw   bxax, callback
	push  	bp
	mov     bp, callbackData	
	call	ProcCallFixedOrMovable	; ax return comparison result
	pop 	bp

	.leave
	ret
DSUserIndexCallbackLaunch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSSwapElements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap the given two record numbers in the index array.

CALLED BY:	DSBuildIndex		
PASS:		ds:si    - the ptr to the first record number
		ds:di    - the ptr to the second record number.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JPD	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSSwapElements	proc	near
	uses	cx,dx
	.enter
	mov	cx, ds:[si]
	mov	dx, ds:[di]
	mov	ds:[di], cx
	mov	ds:[si], dx
	.leave
	ret
DSSwapElements	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSCompareElements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the the two record number passed according to
	        the parameter passed. 

CALLED BY:	DSQuickSort
PASSED:		dx - pivot record number
		ax - recordNum to compare with pivot
		bx - dsHandle (datastore handle)
		fieldNum - field number to comare
RETURN:		ax = -1, if record < pivot	
	             +1, if record > pivot
		      0, if field in the record does not exist
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JPD	3/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSCompareElements	proc	near
	uses	bx,cx,dx,ds,si,es,di,bp
	.enter inherit DataStoreBuildIndex

	
	push	ax
	mov	ax, dx
	clr	dx
	call	DFLockRecordNum		; lock down the pivot record 
				; return ds:si -> fptr to record head
	mov	dl, fieldNum
	call	DSGetFieldPtrCommon	; ds:di -> fptr to the field content
	movdw	pivotPtr, dsdi	; preseve pivot record
	mov	pivotSize, cx	

	pop	ax
	clr 	dx
	call	DFLockRecordNum
	mov	dl, fieldNum
	call	DSGetFieldPtrCommon

	push	ds		; ptr to second field
	pop	es
	mov	al, dh			; ah - field type
	movdw	dssi, pivotPtr		; restore pivotPtr
	mov	dx, cx			; dx - size of field data
	mov	cx, pivotSize		; cx - size of pivot field

	; DFCompareFields doesn't use SortOrder, it uses FieldFlags
	; for the primary key sort order. Map SortOrder to those
	; field flags, Yahoo!
	
	clr	ah			; Only pass the sort flag
	cmp	sortOrder, SO_ASCENDING
	jne	descendOrder
	jmp	continue		; ah - clear = ascending

descendOrder:
	or	ah, mask FF_DESCENDING	; 
continue:
	call	DFCompareFields		; ax - compare result

	call    DFUnlockRecordNum	; unlock the pivot record
	mov	dx, es
	mov	ds, dx
	call    DFUnlockRecordNum	; unlock the non-pivot record

	.leave
	ret

DSCompareElements	endp

MainStructureCode  ends












