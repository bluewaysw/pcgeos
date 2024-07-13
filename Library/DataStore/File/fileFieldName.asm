COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	DataStore
MODULE:		File
FILE:		fileFieldName.asm

AUTHOR:		Cassie Hartzog, Oct 9, 1995

ROUTINES:
	Name				   Description
	----				   -----------
INT	FieldNameElementArrayCreate	   Creates a new FieldNameElement array
EXT	DFMapNameToToken		   Gets FieldID from field name
EXT	DFMapTokenToName		   Gets field name from FieldID
EXT	DFMapTokenToData		   Gets FieldData from FieldID
EXT	DFMapTokenToDescriptor		   Gets FieldDescriptor from FieldID
EXT	DFAddField			   Adds a field 
EXT	DFRemoveField			   Removes a field
EXT	DFRenameField			   Renames a field
EXT	DFGetFieldCount			   Gets total number of fields
EXT	DFCheckValidFieldID		   Checks if a FieldID is valid
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/09/95	Initial revision

DESCRIPTION:
	This provides code to access the FieldNameElementArray.

	Note that VMLock provides thread-exclusive access to the
	FieldNameElementArray block -- no other threads can lock the
	block while we have it locked. Only when deleting a field is it
	necessary to grab the file exclusive, since all records are
	potentially affected.

	$Id: fileFieldName.asm,v 1.1 97/04/04 17:53:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;--------------------------------------------------------------------------
;		External API
;--------------------------------------------------------------------------

FileCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetFieldCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the number of fields defined in this datastore.

CALLED BY:	GLOBAL
PASS:		ax - session token
RETURN:		carry set if error
			ax - DataStoreStructureError
		else
			ax - field count
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/26/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetFieldCount		proc	far
		uses	bx, cx
		.enter
		
		mov	bl, mask DSEF_READ_LOCK 
		call	DMLockDataStore		;^hbx - datastore file
		jc	exit			;didn't get a lock

		mov 	cx, ax			;cx - session token
		call	DFGetFieldCount		;ax - field count
		mov	bx, ax			;bx - field count
		mov	ax, cx			;ax - session token
		call	DMUnlockDataStore     	;preserves flags
		mov	ax, bx			;ax - field count
		clc				;return no error

exit:		
		.leave
		ret

DataStoreGetFieldCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreGetFieldInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the FieldData and name for a field, given its FieldID

CALLED BY:	GLOBAL
PASS:		ax - session token
		dl - FieldID
		es:di - FieldDescriptor
		cx - size of buffer (in bytes) pointed to by FD_name.
		     If 0, then field name will not be copied.
RETURN:		ax - DataStoreStructureError
		carry set if error, ax = 
				DSSE_INVALID_TOKEN
				DSSE_INVALID_FILED_ID
				DSSE_DATASTORE_LOCKED
		carry clear if no error, ax = 
				DSSE_NO_ERROR
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/26/95	Initial version
	jmagasin 9/17/96	Added cx parameter, size of field->FD_name.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreGetFieldInfo		proc	far
		uses	bx
		.enter

		push	cx			;save buffer size
		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx - datastore file
		pop	cx
		jc	errorInBX

		push	ax			;save session token
		mov	al, dl
		call	DFMapTokenToDescriptor
		pop	ax
		call	DMUnlockDataStore	;flags preserved
		jc	error
		mov	ax, DSSE_NO_ERROR

exit:		
		.leave
		ret

errorInBX:
		mov_tr	ax, bx
		jmp	exit
error:
		mov	ax, DSSE_INVALID_FIELD_ID
		jmp	exit
DataStoreGetFieldInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreFieldIDToName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the name for the field with the passed ID

CALLED BY:	GLOBAL
PASS:		ax - DataStore session token
		dl - FieldID	
		cx - size of name buffer
		es:di - name buffer 
RETURN:		if carry set:
			ax - DataStoreStructureError
				DSSE_INVALID_TOKEN
				DSSE_DATASTORE_LOCKED
				DSSE_INVALID_FIELD_ID
		else:	
			ax - DSSE_NO_ERROR
			cx - # of bytes copied, including NULL
			(es:di - field name)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/26/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreFieldIDToName		proc	far
		uses	bx, dx, bp
		.enter

		push 	cx			;preserve
		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx - datastore file
		pop	cx			;restore
		jc	exit

		mov	bp, ax			;bp - session token
		mov	al, dl
		call	DFMapTokenToName	;cx - # of bytes
		jc	error
		mov	ax, bp			;ax - session token
		call	DMUnlockDataStore	;flags preserved
		mov	ax, DSSE_NO_ERROR
exit:		
		.leave
		ret

error:
		mov	ax, DSSE_INVALID_FIELD_ID
		jmp	exit		
DataStoreFieldIDToName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreFieldNameToID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a field name to FieldID

CALLED BY:	GLOBAL
PADD:		ax - DataStore session token
		es:di - field name
RETURN:		if carry set 
			ax - DataStoreStructureError
				DSSE_INVALID_TOKEN
				DSSE_INVALID_FIELD_NAME
				DSE_DATASTORE_LOCKED
		else
			al - FieldID
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/26/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreFieldNameToID		proc	far
		uses	bx, cx
		.enter

		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		;^hbx - datastore file
		jc	exit			;didn't get the lock

		mov	cx, ax			;cx - session token
		call	DFMapNameToToken	;al - FieldId
		jnc	unlock
		mov	ax, DSSE_INVALID_FIELD_NAME
unlock:
		mov	bx, ax			;bx - return value
		mov	ax, cx			;ax - session token
		call 	DMUnlockDataStore	;flags preserved
		mov	ax, bx			;ax - return value

exit:
		.leave
		ret
DataStoreFieldNameToID		endp


FileCommonCode	ends


;--------------------------------------------------------------------------
;		Internal API
;--------------------------------------------------------------------------


FileCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFMapNameToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a field name, returns the FieldID associated
		with it.

CALLED BY:	EXTERNAL
PASS:		es:di - name to look for
		^hbx - datastore file
RETURN:		carry clear if field name existed in the database
			ax = FieldID
		else carry set
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFMapNameToToken	proc	far	uses	cx, dx, si, ds
		.enter
		call	LockFieldNameElementArray
		clr	cx, dx			;null-term. string; no data
		call	NameArrayFind
		cmc
		call	VMUnlockDS		;preserves flags
		.leave
		ret
DFMapNameToToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFMapTokenToName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the name associated with a field.

CALLED BY:	External
PASS:		^bx - datastore file
		al - FieldID
		cx - max # bytes to copy
		es:di - addr of buffer to hold data
RETURN:		carry set if invalid token
		cx - number of bytes actually copied
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFMapTokenToName	proc	far	
		uses	si, ds
		.enter

		clr	ah			; convert to name token
		call	LockElementAndGetName	
		call	VMUnlockDS

		.leave
		ret
DFMapTokenToName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFMapTokenToData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a FieldID token, get the FieldData

CALLED BY:	EXTERNAL
PASS:		bx - datastore VM handle
		al - FieldID
		es:di - FieldData struct
RETURN:		carry set if no such field
DESTROYED:	nada

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 9/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFMapTokenToData		proc	far
		uses	cx, si, ds
		.enter
	;
	; Lock the element & make sure it is not a free element
	;
		clr	ah				; convert to name token
		push	di
		call	LockFieldNameElementArray	; *ds:si <- array
		call	ChunkArrayElementToPtr		; ds:di <- FieldData
		mov	si, di
		pop	di
		jc	exit
		cmp	ds:[si].WAAH_high, EA_FREE_ELEMENT
		stc
		je	exit
	;
	; copy the FieldData
	;
		add	si, offset FNE_data
		mov	cx, size FieldData
		rep	movsb
		clc
exit:		
		call	VMUnlockDS
		.leave
		ret
DFMapTokenToData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFMapTokenToDescriptor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a FieldID token, get the FieldDescriptor

CALLED BY:	EXTERNAL
PASS:		bx - datastore VM handle
		al - FieldID
		es:di - FieldDescriptor struct
		cx - size of buffer (in bytes) pointed to by FD_name.
		     If 0, then field name will not be copied.
RETURN:		carry set if no such field
DESTROYED:	nada

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 9/95	Initial version
	jmagasin 9/17/96	Added cx parameter, size of field->FD_name.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFMapTokenToDescriptor		proc	far
		uses	cx, si, di, ds
		.enter
	;
	; Lock the element and copy the name to the buffer
	;
		clr	ah			; convert to name token
		push	es, di
		les	di, es:[di].FD_name
		call	LockElementAndGetName	; ds:si <- FieldNameElement
		pop	es, di
		jc	exit
	;
	; copy the rest of the data
	;
		add	si, offset FNE_data
		mov	cx, size FieldData
		rep	movsb
		clc
exit:		
		call	VMUnlockDS
		.leave
		ret
DFMapTokenToDescriptor		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFAddField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a field to FieldNameElement array

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
		es:di - FieldDescriptor
RETURN:		carry set if error,
			ax = DataStoreStructureError
				DSSE_FIELD_NAME_IN_USE
			 	DSSE_TOO_MANY_FIELDS
		carry clear if no error,
			al - FieldID
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFAddField		proc	far
		uses	bx, cx, dx, si, di, ds, es
		.enter

		call	LockFieldNameElementArray ; *ds:si <- NameArray
	;
	; Check for token > 255 ==> we only store one byte in FieldID,
	; so can only define 256 names.
	;
		push	bx
		clr	bx			 ;no callback
		call	ElementArrayGetUsedCount ;ax - # used elements
		pop	bx

		tst	ah
		stc
		mov	ax, DSSE_TOO_MANY_FIELDS
		jnz	unlock
	;
	; Add the field now, but return error if it already exists
	;
		movdw	dxax, esdi
		les	di, es:[di].FD_name				
EC <		Assert	nullTerminatedAscii, esdi			>

		push	bx
		clr	cx, bx			;null-term name; don't
						;  replace existing data
		call	NameArrayAdd		;carry set if name added

		pop	bx
		mov_tr	dx, ax
		mov	ax, DSSE_FIELD_NAME_EXISTS
		cmc		
		jc	unlock

	;
	; Write the changes to file now.
	;
		call	DFUpdateDataStore	;carry; ax = DataStoreError
		jc	unlock
		
		mov	ax, dx			;al <- FieldID
unlock:		
		call	VMUnlockDS		;preserves flags
		
		.leave
		ret
DFAddField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFRemoveField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a field from FieldNameElement array

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
		al - FieldID
RETURN:		carry set if invalid FieldID
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFRemoveField		proc	far
		uses	cx, si, ds
		.enter

		call	LockFieldNameElementArray
		clr	ah			;ax <- name token
		call	CheckValidFieldElement
		jc	exit
		call	ElementArrayDelete
		call	VMDirtyDS
		call	DFUpdateDataStore	;carry; ax = DataStoreError
exit:		
		call	VMUnlockDS		;preserves flags
		.leave
		ret
DFRemoveField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFRenameField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename a field

CALLED BY:	EXTERNAL
PASS:		al - FieldID
		es:di - new name
		^hbx - datastore file
RETURN:		carry set if invalid FieldID
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFRenameField		proc	far
		uses	cx, si, ds
		.enter

EC <		Assert	nullTerminatedAscii, esdi			>

		call	LockFieldNameElementArray
		clr	ah			;ax <- name token
		call	CheckValidFieldElement
		jc	exit

		clr	cx			; name is null-terminated
		call	NameArrayChangeName
		call	VMDirtyDS
		clc
exit:
		call	VMUnlockDS
		.leave
		ret
DFRenameField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFGetFieldCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of defined fields

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
RETURN:		ax - number of fields
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFGetFieldCount		proc	far
		uses	si, ds
		.enter

		call	LockFieldNameElementArray
		clr	bx
		call	ElementArrayGetUsedCount
		call	VMUnlockDS
		
		.leave
		ret
DFGetFieldCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFCheckValidFieldID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed FieldID is valid

CALLED BY:	EXTERNAL
PASS:		^hbx - datastore file
		al - FieldID
RETURN:		carry set if FieldID is invalid
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFCheckValidFieldID		proc	far
		uses	si, ds
		.enter
		
		call	LockFieldNameElementArray ;*ds:si <- array
		clr	ah			;ax <- name token
		call	CheckValidFieldElement	;sets carry flag
		call	VMUnlockDS		;preserves flags
		
		.leave
		ret
DFCheckValidFieldID		endp


;------------------------------------------------------------------------
;		Internal sub-routines
;------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckValidFieldElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed field element number refers to
		a valid field.

CALLED BY:	INTERNAL
PASS:		*ds:si - FieldNameElement array
		ax - field element number
RETURN:		carry set if no such field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckValidFieldElement		proc	far
		uses	cx, di
		.enter
	;
	; If the element is free, return error
	;
		call	ChunkArrayElementToPtr
		jc	exit
		
		cmp	ds:[di].WAAH_high, EA_FREE_ELEMENT
		stc
		je	exit
		clc
exit:
		.leave
		ret
CheckValidFieldElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockElementAndGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down a FieldNameElement and copy its name to a buffer.

CALLED BY:	INTERNAL - DFMapTokenToName, DFMapTokenToData
PASS:		bx - datastore VM handle
		ax - field name token
		cx - max # bytes to copy (0 to not copy any data)
		es:di - addr of buffer to hold name
RETURN:		carry set if invalid token was passed
		carry clear if field was found,
			ds:si - FieldNameElement
			cx - string name length, if cx was not passed as 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockElementAndGetName		proc	near
		namePtr		local	fptr
		uses	ax, di
		.enter

;push	es, di
movdw	namePtr, esdi
		call	LockFieldNameElementArray ; *ds:si <- array

		call	CheckValidFieldElement
		jc	exit			; not valid, exit
	;
	; Get a pointer to the appropriate element
	;
		push	cx
		call	ChunkArrayElementToPtr	; cx <- size of element
		pop	ax			; ax <- # bytes to copy
EC <		ERROR_C -1						>
;NEC <		jc	justExit					>
NEC <		jc	exit					>

	;
	; If 0 was passed in cx, don't copy name to buffer
	;
		tst	ax 			; holds passed cx
		mov	si, di			; return ptr to element
		jz	noCopy
DBCS <		and	al, 0xfe		; wchar align >
		
		lea	si, ds:[di].FNE_name	; ds:si <- name w/o NULL
	;
	; Get the # bytes to copy
	;
		sub	cx, size FieldNameElement ;cx <- length of name
		add	cx, size TCHAR		;add NULL to name length
		cmp	cx, ax			;name length < buffer size?
		jbe	10$			;yes, copy the whole thing
		mov	cx, ax			;else copy part of name
10$:
		sub	cx, size TCHAR		;NULL can't be copied, because
						; is not in name array
	;
	; Copy the name to the buffer at es:di
	;
		mov	ax, di			;save di in ax
;pop	es, di
movdw	esdi, namePtr
		push	cx			;save string length
		jcxz	done
		rep	movsb
done:
		mov	si, ax			;ds:si <- element
		pop	cx
		add	cx, size TCHAR		;include NULL
		clr	ax
		LocalPutChar	esdi, ax	;stuff the NULL
noCopy:
		clc
exit:
		.leave
		ret
;NEC < justExit:								>
;NEC <		pop	es, di						>

if 0
unlock:
		call	VMUnlockDS		;preserves flags
		jmp	exit
endif
LockElementAndGetName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockFieldNameElementArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks down the element array that contains the field names.

CALLED BY:	GLOBAL
PASS:		bx - DataStore handle
RETURN:		*DS:SI - locked field name element array
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockFieldNameElementArray	proc	far	uses	ax, bp
	.enter

EC <	Assert	vmFileHandle, bx					>

;	Get the element array from the map block

	call	VMGetMapBlock
	call	VMLock
	mov	ds, ax
	mov	ax, ds:[DSM_fieldArray]
	call	VMUnlock

;	Lock down the element array

	call	VMLock
	mov	ds, ax
	mov	si, ds:[FALMBH_array]

EC <	Assert	ChunkArray, dssi					>
	.leave
	ret
LockFieldNameElementArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMUnlockDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks the VM block whose segment lies in DS 

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada - flags preserved
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMUnlockDS	proc	far	
		push	bp
		mov	bp, ds:[LMBH_handle]
EC <		pushf
EC <		Assert	vmMemHandle, bp					>
EC <		popf
		call	VMUnlock
		pop	bp
		ret		
VMUnlockDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMDirtyDS, VMDirtyES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dirties the VM block whose segment lies in DS or ES

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada - flags preserved
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMDirtyDS	proc	near	
		push	bp
		mov	bp, ds:[LMBH_handle]
EC <		pushf
EC <		Assert	vmMemHandle, bp					>
EC <		popf
		call	VMDirty
		pop	bp
		ret		
VMDirtyDS	endp
		
FileCommonCode	ends


FileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FieldNameElementArrayCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates an empty element array in a VM block

CALLED BY:	GLOBAL
PASS:		bx - handle of datastore file
RETURN:		carry set if error
			ax - DataStoreError
		else
			ax - VM block
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FieldNameElementArrayCreate	proc	near	uses	cx, si, ds
	.enter

	push	bx		;Save the handle of the file 

;	Allocate an LMem heap to hold our element array

	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, FieldArrayLMemBlockHeader
	call	MemAllocLMem		; no error
	call	MemLock
	mov	ds, ax			;DS <- heap in which to allocate array

;	Create an empty element array with variable sized elements

	mov	bx, size FieldData	;Variable sized elements
	clr	cx			;No extra data in element array header
	clr	si			;Allocate a new chunk
	mov	al, mask LMF_RETURN_ERRORS
	call	NameArrayCreate		;SI <- handle of name array
	jc	error
	mov	ds:[FALMBH_array], si
	
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

;	Attach this block to the VM file

	mov	cx, bx	  		;CX <- memory handle
	clr	ax			;allocate new VM block
	pop	bx			;BX <- handle of file
	call	VMAttach		;AX <- VMBlock handle

exit:
	.leave
	ret

error:
	pop	bx
	jmp	exit		
FieldNameElementArrayCreate	endp

FileCode	ends
