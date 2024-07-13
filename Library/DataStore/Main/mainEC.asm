COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	DataStore Library
MODULE:		Main
FILE:		mainEC.asm

AUTHOR:		Cassie Hartzog, Nov  9, 1995

ROUTINES:
	Name			Description
	----			-----------
EXT	ECCheckRecordBlock	Checks the validity of record block
EXT	ECCheckRecordElement	Check whether a record in a HugeArray 
				element is valid
EXT	ECCheckRecordPtr	Checks the validity of the passed record

INT	CheckFieldCallback	Checks whether a field is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 9/95   	Initial revision


DESCRIPTION:
	
		

	$Id: mainEC.asm,v 1.1 97/04/04 17:53:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK

MainECCode		segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckRecordBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the validity of record block

CALLED BY:	EXTERNAL
PASS:		^hax - record Lmem block handle
		^hbx - datastore file
RETURN:		nada
DESTROYED:	nada (flags preserved)
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckRecordBlock	proc	far	uses	ax, bx, cx, ds, si, di
		.enter

		pushf

		tst	ax
		jz	okay
		
		push	bx
		mov	bx, ax
		call	MemLock
		mov	ds, ax
		mov	si, ds:[RLMBH_record]
		mov	si, ds:[si]
		ChunkSizePtr ds, si, ax		; ax - size of record chunk

		pop	bx

	;
	; Make sure that the size of the chunk matches the size of the record
	; data 
	;
	cmp	ax, ds:[si].RH_size
	ERROR_NE CORRUPT_FIELD_SIZES

		call	ECCheckRecordPtr

		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
okay:
		popf

		.leave
		ret
ECCheckRecordBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckRecordElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether a record in a HugeArray element is valid

CALLED BY:	EXTERNAL
PASS:		ds:si - record in HugeArray
		bx - datastore file handle
		dx - element size
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/19/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckRecordElement		proc	far
		.enter
		pushf
	;
	; Make sure stored size agrees with chunk size.
	;
		cmp	dx, ds:[si].RH_size
		ERROR_NE	INVALID_RECORD_SIZE

		call	ECCheckRecordPtr
		popf
		.leave
		ret
ECCheckRecordElement		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckRecordPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the validity of the passed record

CALLED BY:	INTERNAL
PASS:		ds:si - ptr to record header
		^hbx - datastore handle
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	wy	11/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckRecordPtr	proc	far	uses	ax, bx, cx, dx, si, di, bp
		
		dsHandle	local	hptr	push bx
		fieldData	local	FieldData
		fieldCount	local	word
		recordSize	local	word
		prevFid		local	byte
		validPrevFid	local	byte
		ForceRef	fieldData
		ForceRef	dsHandle
		ForceRef	prevFid
		.enter

		pushf
		mov	ax, bx			; ^hax - file
	;
	; Step through all the fields, to ensure that their sizes/data are
	; reasonable. Also count the number of fields in the record
	; to make sure it agrees with RH_fieldCount.
	;
		mov	ss:[fieldCount], 0	; fieldCount = 0
		mov	ss:[recordSize], size RecordHeader	
		mov	bx, SEGMENT_CS
		mov	di, offset CheckFieldCallback
		clr	validPrevFid			; invalid prevFid
		call	DSFieldEnumCommon
		ERROR_C	-1 				
		mov	ax, ss:[fieldCount]
		tst	ah
		ERROR_NZ	INVALID_FIELD_COUNT
		cmp	al, ds:[si].RH_fieldCount
		ERROR_NE	INVALID_FIELD_COUNT
	;
	; Make sure that the size of the block matches the size of the record
	; data, to within 16 bytes (the heap code rounds data sizes up to the
	; next 16-byte boundary).
	;
		mov	cx, ss:[recordSize]
		sub	cx, ds:[si].RH_size
		ERROR_C	CORRUPT_FIELD_SIZES
		cmp	cx, 16
		ERROR_AE CORRUPT_FIELD_SIZES

		popf
		.leave
		ret
ECCheckRecordPtr	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFieldCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks whether a field is valid

CALLED BY:	ECCheckRecordPtr (vie DataStoreFieldEnum)
PASS:		ds:di - ptr to field content
		cx - field content size
		al - field type
		ah - field category
		dl - field id
		dh - field flags
		bp - callback data
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFieldCallback	proc	far
	uses	es
	.enter	inherit ECCheckRecordPtr

	;
	; Fields are stored in order of their FieldID. Make sure
	; this field's ID comes after the previous field's.
	;
	tst	validPrevFid
	jz	invalidFid

	cmp	dl, prevFid
	ERROR_BE FIELDS_OUT_OF_ORDER
	jmp	continue

invalidFid:
	mov	validPrevFid, 1
	
continue:
	mov	prevFid, dl
		
	inc	ss:[fieldCount]		; increment field count

	mov	dl, al			; save field type 
	push	cx
	call	DSGetFieldSizeByTypeFar	; cl - header size
	ERROR_C	INVALID_FIELD_TYPE
	clr	ah
	mov	al, cl			; ax - header size
	pop	cx			; cx - content size

	add	ax, cx
	add	ss:[recordSize], ax

	mov	bx, dsHandle
	segmov	es, ds, ax		; es:di - field data
	call	DSIsDataValidForField
	ERROR_C	INVALID_FIELD_DATA
		
	.leave
	ret
CheckFieldCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSIsFieldFlagValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the field flags are valid 

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
DSIsFieldFlagValid	proc	far	
	.enter

	test	al, not FieldFlags
	jz	done			;valid flag
	stc				;invalid flag, set carry
done:
	.leave
	ret
DSIsFieldFlagValid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGetBufferRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the record id from a given record buffer block

CALLED BY:	EXTERNAL	
PASS:		^hbx - record buffer
RETURN:		dxcx - record id
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/16/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGetBufferRecordID		proc	far
		uses	ax, ds, si
		.enter

		call	MemLock
EC <		ERROR_C BAD_BUFFER_LMEM_BLOCK				>
		mov	ds, ax
		mov	si, ds:[RLMBH_record]
		mov	si, ds:[si]

		movdw	dxcx, ds:[si].RH_id
		
		.leave
		ret
DSGetBufferRecordID		endp

MainECCode	ends

MainCode		segment	resource

DSGetFieldSizeByTypeFar	proc	far
		call	DSGetFieldSizeByType
		ret
DSGetFieldSizeByTypeFar	endp

MainCode		ends
		
endif


