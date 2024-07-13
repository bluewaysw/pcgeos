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
EXT	DFFileCreate			Create a datastore file
EXT	DFFileOpen			Open a datastore file
EXT	DFFileClose			Close a datastore file
EXT	DFFileDelete			Delete a datastore file
EXT	DFFileRename			Rename a datastore file
EXT	DFUpdateDataStore		VMUpdate datastore file
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95	Initial revision

DESCRIPTION:
	Contains code to create, open, close a datastore file

	$Id: fileOpen.asm,v 1.1 97/04/04 17:53:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFFileCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens a database file, or creates one if it doesn't exist.

CALLED BY:	EXTERNAL
PASS:		ds:si - DataStoreCreateParams

RETURN:		carry set if error (ax = error code)
		else bx = file handle
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFFileCreate	proc	far	uses	es, cx, dx, di, bp
		.enter

EC <		push	ds						>
EC <		lds	dx, ds:[si].DSCP_name.offset			>
EC <		Assert	nullTerminatedAscii, dsdx			>
EC <		pop	ds						>
	;
	; Create the file in the Document directory
	;
		call	PushToDocumentDir
		push	ds
		lds	dx, ds:[si].DSCP_name
	;
	; Create the file, in synchronous update mode
	;
		mov	ax, (VMO_CREATE_ONLY shl 8) or \
			(mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_READ_WRITE or \
			mask VMAF_FORCE_DENY_WRITE)
		clr	cx
		call	VMOpen
		pop	ds
		jc	openError		;Exit if error opening file
	;
	; Make this library own the file, so it won't get closed 
	; automatically if the client exits.
	;
		push	ax
		mov	ax, handle 0
		call	HandleModifyOwner
		pop	ax
	;
	; Set the protocol and creator token appropriately
	;
		call	SetCreatorAndProtocol
	;
	; Make file sync-update, so we don't have to worry about the data
	; possibly being in an inconsistant state...
	;
		mov	ax, mask VMA_SYNC_UPDATE
		call	VMSetAttributes
	;
	; Initialize the file (create a map block with worthwhile data)
	;
		call	InitializeDataStore
		jc	initError

		call	AddKeyFields		; add all the key fields
;;;		jc	exit
		jc	initError

EC <		call	ECValidateDataStore				>

exit:
		call	FilePopDir
		.leave
		ret

openError:
		mov	bx, ax
		mov	ax, DSE_DATASTORE_EXISTS
		cmp	bx, VM_FILE_EXISTS
		je	error
		mov	ax, DSE_CREATE_ERROR
error:		
		stc
		jmp	exit

initError:
		push	ax, ds
		lds	dx, ds:[si].DSCP_name
		call	FileDelete
		pop	ax, dx
		jmp	error
		
DFFileCreate		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFFileOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a datastore file

CALLED BY:	EXTERNAL
PASS:		es:di - name
			
RETURN:		carry set if error, ax = DataStoreError
		bx = file handle
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFFileOpen		proc	far	uses	dx, cx, ds, es, di, si
		.enter

EC <		Assert	nullTerminatedAscii, esdi			>

		call	PushToDocumentDir

		movdw	dsdx, esdi
		call	CheckValidDataStoreFile	;ax <- DataStoreError
		jc	exit
		
		mov	ax, (VMO_OPEN shl 8) or \
			(mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			 mask VMAF_FORCE_READ_WRITE or \
			 mask VMAF_FORCE_DENY_WRITE)
		clr	cx
		call	VMOpen
		call	FilePopDir
		jc	openError		;Exit if error opening file
	;
	; Make this library own the file, so it won't get closed automatically
	; if the client exits.
	;
		mov	ax, handle 0
		call	HandleModifyOwner

	;
	; Check if this is a private datastore which cannot be
	; opened by anyone but the creator.
	;
		call	CheckIfPrivate		; ax <- DataStoreError
		jc	closeExit
		
EC <		call	ECValidateDataStore				>
exit:		
		.leave
		ret
openError:
		mov	bx, ax
		mov	ax, DSE_DATASTORE_NOT_FOUND
		cmp	bx, VM_FILE_NOT_FOUND
;;		cmp	bx, VM_OPEN_INVALID_VM_FILE	; handle this?
		mov	ax, DSE_ACCESS_DENIED
		cmp	bx, VM_SHARING_DENIED				
EC <		ERROR_Z ATTEMPTED_TO_OPEN_FILE_WHICH_IS_ALREADY_OPEN	>
NEC <		je	error						>
		mov	ax, DSE_OPEN_ERROR
		
error::
		stc
		jmp	exit

closeExit:
		clr	al
		call	VMClose
		mov	ax, DSE_PRIVATE_DATASTORE
		jmp	error
		
DFFileOpen		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFFileClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the passed datastore

CALLED BY:	GLOBAL
PASS:		bx - handle of datastore
RETURN:		carry set if error
		ax - DataStoreError
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFFileClose	proc	far
		.enter

		call	DFUpdateDataStore
		clr	al
		call	VMClose
		mov	bx, DSE_NO_ERROR
		jnc	exit
		mov	bx, DSE_WRITE_ERROR
		cmp	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
		je	error
		mov	bx, DSE_CLOSE_ERROR
error:
		stc
exit:
		mov	ax, bx
		.leave
		ret
DFFileClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFFileOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes or renames a datastore file.
		The file cannot be in use.

CALLED BY:	INTERNAL - DataStoreRename, DataStoreDelete
PASS:		ds:dx - datastore name
		es:di - new name (for rename)
		bx:ax - vfptr of File routine to call
RETURN:		ax - DataStoreError
		carry set if error
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 9/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFFileOperation		proc	near
		uses	bx, cx, bp
routine local	vfptr	push	bx, ax
		.enter

		call	PushToDocumentDir

		call	CheckValidDataStoreFile	;ax <- DataStoreError
		jc	exit
	;
	; Make sure that no one has this datastore open.
	;
;;		call	DMIsDataStoreOpen
		mov	ax, DSE_ACCESS_DENIED
		jc	exit
	;
	; Open the file so that we can check if it is private.
	;
		push	cx
		mov	ax, (VMO_OPEN shl 8) or \
			(mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			 mask VMAF_FORCE_READ_WRITE or \
			 mask VMAF_FORCE_DENY_WRITE)
		clr	cx
		call	VMOpen
		pop	cx
		jc	openError		;Exit if error opening file
	;
	; Check if this is a private datastore which cannot be
	; opened by anyone but the creator.
	;
		call	CheckIfPrivate		; carry set if private
		pushf
		clr	al
		call	VMClose
		popf
		jc	exit
	;
	; If the file is private, it is owned by this geode, so
	; go ahead and do the operation
	;
		movdw	bxax, ss:routine
		call	ProcCallFixedOrMovable
		jc	fileError
		mov	ax, DSE_NO_ERROR
exit:		
		call	FilePopDir
		.leave
		ret

openError:		
		mov	bx, ax
		mov	ax, DSE_DATASTORE_NOT_FOUND
		cmp	bx, VM_FILE_NOT_FOUND
		je	error
		mov	ax, DSE_ACCESS_DENIED
		jmp	error
fileError:
		mov	bx, ax
		mov	ax, DSE_INVALID_NAME
		cmp	bx, ERROR_INVALID_NAME
		je	error
		mov	ax, DSE_DATASTORE_EXISTS
		cmp	bx, ERROR_FILE_EXISTS
		je	error
		mov	ax, DSE_ACCESS_DENIED
EC <		cmp	bx, ERROR_FILE_IN_USE				>
EC <		je	error						>
EC <		cmp	bx, ERROR_ACCESS_DENIED				>
EC <		ERROR_NE UNKNOWN_FILE_ERROR				>
error:
		stc
		jmp	exit
		
DFFileOperation		endp

FileCode	ends


FileCommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFUpdateDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the database is written to disk.

CALLED BY:	GLOBAL
PASS:		bx - file handle
RETURN:		carry set if error
			ax = DSE_WRITE_ERROR
		carry clear if no error
			ax = DSE_NO_ERROR

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFUpdateDataStore	proc	far	
		.enter

EC <	call	ECValidateDataStore					>
		
tryAgain:
	call	VMUpdate

;	Crash if we couldn't update the file on disk, unless it was because
;	a dirty block was locked by another thread. If a dirty block is locked
;	by another thread, the file on disk is probably in an inconsistent
;	state, so we need to sit in a loop and keep trying to write out
;	the file.

	jnc	okay
	cmp	ax, VM_UPDATE_BLOCK_WAS_LOCKED				
;;EC <	ERROR_NZ ERROR_RETURNED_FROM_VM_UPDATE				>
EC <	jnz 	error							>
NEC <	jnz	error							>
EC <	WARNING	VM_UPDATE_FAILED_DUE_TO_LOCKED_BLOCK			>
	mov	ax, 60/8	;Wait for 1/8 second
	call	TimerSleep
	jmp	tryAgain

okay:
EC <	call	ECValidateDataStore					>
	clc
	mov	ax, DSE_NO_ERROR
exit:
	.leave
	ret

EC < error:								>
EC <		call	VMDiscardDirtyBlocks				>
EC <		ERROR_C -1						>
EC <		mov	ax, DSE_WRITE_ERROR				>
EC <		stc							>
EC <		jmp	exit						>
		
NEC < error:								>
NEC <	mov	ax, DSE_WRITE_ERROR					>
NEC <	stc								>
NEC <	jmp	exit							>
DFUpdateDataStore	endp

FileCommonCode	ends

;--------------------------------------------------------------------------
;		Internal Routines
;--------------------------------------------------------------------------

FileCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a new datastore file

CALLED BY:	INTERNAL - DFFileCreate
PASS:		^hbx - datastore file
		ds:si - DataStoreCreateParams
RETURN:		carry set if error,
			ax - DataStoreError
				DSE_INSUFFICIENT_MEMORY
			 	DSE_UPDATE_ERROR
		carry clear if no error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	cassie		10/4/95		Initial version
	robertg 	 2/19/97	Add modification tracking
	tgautier	 2/20/97	Fix munged parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeDataStore		proc	near
		uses	cx, dx, bp, es, di
		.enter

		mov	cx, size DataStoreMap
		clr	ax
		call	VMAlloc			; no error
		call	VMSetMapBlock		; no error
	;
	; Initialize the map block
	;
		call	VMLock			; no error
		mov	es, ax
		call	VMDirty			; no error
	;
	; Initialize some fields and test DSCP_flags
	; When DSF_NO_PRIMARY_KEY is set DSCP_keyCount should be zero,
	; and when it is not set, DSCP_keyCount is greater than one.
	; Other wise a error message will be sent and carry flag is set.
	;

		tst	ds:[si].DSCP_keyCount
		jnz	primaryKey
		or	ds:[si].DSCP_flags, mask DSF_NO_PRIMARY_KEY	

primaryKey:
		mov	ax, ds:[si].DSCP_flags
EC <		test	ax, mask  DSF_NO_PRIMARY_KEY		>
EC <		jnz	noKeyField				>
EC <		tst	ds:[si].DSCP_keyCount			>
EC <		ERROR_Z	DSF_FLAG_NOT_CONSISTANT_WITH_KEY_COUNT  >
EC <		jmp	continue				>
EC < noKeyField:						>
EC <		tst	ds:[si].DSCP_keyCount			>
EC <		ERROR_NZ DSF_FLAG_NOT_CONSISTANT_WITH_KEY_COUNT >
EC < continue:							>

		mov	es:[DSM_flags], ax
		call	TimerGetFileDateTime
		movdw	es:[DSM_timestamp], dxax
		mov	es:[DSM_language], SL_ENGLISH

		clr	ax, dx
		movdw	es:[DSM_recordCount], dxax
		mov	es:[DSM_extraData], ax
		movdw	es:[DSM_version], dxax
	;
	; Check for modification tracking
	;
		test	es:[DSM_flags], mask DSF_TRACK_MODS
		jz	notTrackingMods
	;
	; Reset the transaction number
	;
		movdw	es:[DSM_transactionNumber], dxax
	;
	; Ok, build a deadlist
	;
		call	DLCreate
		jc	memoryError
		mov	es:[DSM_delList], ax

notTrackingMods:
	;
	; Start at a record ID that has both the high and low words non-zero,
	; to make sure that everyone is correctly preserving valid record IDs.
	;
		movdw	es:[DSM_recordID], FIRST_RECORD_ID
	;
	; Get the GeodeToken of the current process
	;
		push	bx
		call	GeodeGetProcessHandle
		mov	di, offset DSM_owner
		clr	cx			
		mov	ax, GGIT_TOKEN_ID
		call	GeodeGetInfo		; no error
		pop	bx
	;	
	; Create an empty element array to hold the field names
	;
		call	FieldNameElementArrayCreate
		jc	memoryError
		mov	es:[DSM_fieldArray], ax
	;
	; Create a huge array with variable sized elements to hold record data
	;
		clr	di
		clr	cx
		call	HugeArrayCreate
		mov	es:[DSM_recordArray], di

		call	VMUnlock
		call	DFUpdateDataStore
exit:
		.leave
		ret

memoryError:
		call	VMUnlock
		stc
		mov	ax, DSE_MEMORY_FULL
		jmp	exit
InitializeDataStore		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushToDocumentDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push the current dir and change to Document dir

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 9/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PushToDocumentDir		proc	near
		.enter
		call	FilePushDir
		mov	ax, SP_DOCUMENT
		call	FileSetStandardPath
		.leave
		ret
PushToDocumentDir		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckValidDataStoreFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a file in the current paths is a valid
		datastore file

CALLED BY:	INTERNAL
PASS:		ds:dx - filename

RETURN:		carry set if not valid datastore file
			ax - DataStoreError

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/20/95	Initial version
	jmagasin 8/22/96	Check for null filename.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckValidDataStoreFile		proc	near
		proto	local	ProtocolNumber	
		creator	local	GeodeToken
		uses	cx, bp, di, es
		.enter

	;
	; Check for null datastore name.
	;
		mov	di, dx
		LocalIsNull	ds:[di]
		mov	ax, DSE_INVALID_NAME
		jz	error


		sub	sp, size FileExtAttrDesc * 3
		mov	di, sp				
		mov	ss:[di].FEAD_attr, FEA_CREATOR
		lea	ax, creator
		movdw	ss:[di].FEAD_value, ssax
		mov	ss:[di].FEAD_size, size creator
		add	di, size FileExtAttrDesc
		mov	ss:[di].FEAD_attr, FEA_PROTOCOL
		lea	ax, proto
		movdw	ss:[di].FEAD_value, ssax
		mov	ss:[di].FEAD_size, size proto
		add	di, size FileExtAttrDesc
		mov	ss:[di].FEAD_attr, FEA_END_OF_LIST

		segmov	es, ss, ax
		mov	di, sp			; es:di <- buffer
		mov	ax, FEA_MULTIPLE
		mov	cx, 2			; 2 entries
		call	FileGetPathExtAttributes
		mov	cx, ax			; cx <- FileError
		lahf
		add	sp, size FileExtAttrDesc * 3
		sahf
		jc	openError

		mov	ax, DSE_INVALID_DATASTORE_FILE
		cmp	creator.GT_manufID, MANUFACTURER_ID_GEOWORKS
		jne	error
		cmp	{word}creator.GT_chars, DS_TOKEN_1_2
		jne	error
		cmp	{word}creator.GT_chars+2, DS_TOKEN_3_4
		jne	error

		mov	ax, DSE_PROTOCOL_ERROR
		cmp	proto.PN_major, DS_PROTO_MAJOR
		jne	error
		cmp	proto.PN_minor, DS_PROTO_MINOR
		jne	error

		clc
exit:
		.leave
		ret

openError:
		mov	ax, DSE_DATASTORE_NOT_FOUND
		cmp	cx, ERROR_FILE_NOT_FOUND
		je	error		
		mov	ax, DSE_INVALID_DATASTORE_FILE
error:
		stc
		jmp	exit
CheckValidDataStoreFile		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfPrivate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if current datastore is private, and if so,
		wether this geode is it's creator.

CALLED BY:	DFFileOpen
PASS:		^hbx - datastore file
RETURN:		carry set if private and this geode is not owner
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfPrivate		proc	near
		token	local	GeodeToken	
		uses	cx, dx, bp, di, es
		.enter

		call	DFGetFlags
		test	ax, mask DSF_PRIVATE
		jz	noError
		
		push	bx
		call	GeodeGetProcessHandle	;^hbx - process
		segmov	es, ss, ax
		lea	di, ss:token
		clr	cx			
		mov	ax, GGIT_TOKEN_ID
		call	GeodeGetInfo		; no error
		pop	bx
		
		call	DFGetOwner
		cmp	cx, token.GT_manufID
		jne	error
		cmpdw	dxax, token.GT_chars
		jne	error
noError:
		clc
exit:
		.leave
		ret
error:
		stc
		jmp	exit
CheckIfPrivate		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCreatorAndProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the creator token and ProtocolNumber for a 
		datastore file

CALLED BY:	INTERNAL
PASS:		^hbx - file handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/20/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCreatorAndProtocol		proc	near
		proto	local	ProtocolNumber	
		creator	local	GeodeToken
		uses	ax, cx, bp, di, es
		.enter

		mov	creator.GT_manufID, MANUFACTURER_ID_GEOWORKS
		mov	{word}creator.GT_chars, DS_TOKEN_1_2
		mov	{word}creator.GT_chars+2, DS_TOKEN_3_4
		mov	proto.PN_major, DS_PROTO_MAJOR
		mov	proto.PN_minor, DS_PROTO_MINOR

		sub	sp, size FileExtAttrDesc * 3
		mov	di, sp
		
		mov	ss:[di].FEAD_attr, FEA_CREATOR
		lea	ax, creator
		movdw	ss:[di].FEAD_value, ssax
		mov	ss:[di].FEAD_size, size creator
		add	di, size FileExtAttrDesc
		mov	ss:[di].FEAD_attr, FEA_PROTOCOL
		lea	ax, proto
		movdw	ss:[di].FEAD_value, ssax
		mov	ss:[di].FEAD_size, size proto
		add	di, size FileExtAttrDesc
		mov	ss:[di].FEAD_attr, FEA_END_OF_LIST

		segmov	es, ss, ax
		mov	di, sp			; es:di <- buffer
		mov	ax, FEA_MULTIPLE
		mov	cx, 2			; 2 entries
		call	FileSetHandleExtAttributes
		ERROR_C	-1						
		add	sp, size FileExtAttrDesc * 3

		.leave
		ret
SetCreatorAndProtocol		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddKeyFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A DataStore file is being created. Add the key fields.

CALLED BY:	DFFileCreate
PASS:		^hbx - datastore file
		ds:si - DataStoreCreateParams		
RETURN:		carry set if error
			ax - DataStoreError
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	cassie		10/23/95	Initial version
	tgautier	 2/19/97	Add modification tracking 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddKeyFields		proc	near
		uses	cx, di, es
		.enter
	;
	; Check whether we need to add a timestamp field or not.  
	; The timestamp field is always first, and can't be deleted.
	; Also add the timestamp field if modification tracking is turned on.
	;
		call	DFGetFlags
		test	ax, mask DSF_TIMESTAMP or mask DSF_TRACK_MODS
		jz	noTimestamp
	;
	; Set up a FieldDescriptor for the timestamp field.
	; The field name is in a localizable resource, which
	; must be locked first.
	;
		sub	sp, size FieldDescriptor + 1
		mov	di, sp
		segmov	es, ss, ax
		mov	es:[di].FD_type, DSFT_TIMESTAMP
		mov	es:[di].FD_category, FC_NONE
		mov	es:[di].FD_flags, mask FF_TIMESTAMP

		push	bx, ds
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax		
		mov	bx, offset TimestampFieldName
		mov	bx, ds:[bx]			; ds:bx <- field name
		movdw	es:[di].FD_name, dsbx
		pop	bx, ds
		call	DFAddField
EC <		ERROR_C -1						>
	;
	; Unlock the Strings resource now that the name has been added
	;
		push	bx
		mov	bx, handle Strings
		call	MemUnlock
		pop	bx
		add	sp, size FieldDescriptor + 1
		
noTimestamp:
		mov	cx, ds:[si].DSCP_keyCount
		jcxz	noKeys
		les	di, ds:[si].DSCP_keyList
keyLoop:
		andnf	es:[di].FD_flags, mask FF_DESCENDING
		ornf	es:[di].FD_flags, mask FF_PRIMARY_KEY
		call	DFAddField
		jc	exit
		add	di, size FieldDescriptor
		loop	keyLoop
exit:		
		.leave
		ret
noKeys:
		clc
		jmp	exit
AddKeyFields		endp

FileCode	ends


Strings		segment lmem LMEM_TYPE_GENERAL

TimestampFieldName	chunk.char	"__TIMESTAMP", 0
localize	"Name of the timestamp field.";

Strings		ends


