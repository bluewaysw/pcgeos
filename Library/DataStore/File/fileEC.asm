COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	DataStore Library
MODULE:	        File
FILE:		fileEC.asm

AUTHOR:		Cassie Hartzog, Oct 20, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	10/20/95	Initial revision


DESCRIPTION:
	Error checking routines.

	$Id: fileEC.asm,v 1.1 97/04/04 17:53:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK

FileECCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCompareKeyFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that modified record and in-file copy of that record
		have the same key value, i.e. that the modified record
		doesn't need to move within the record array.

CALLED BY:	DFSaveRecord
PASS:		es:si - modified record
		dx.ax - record index
		^vbx:di - record array
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 9/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCompareKeyFields		proc	far
		uses	ax, bx, dx, bp, si, di, ds, es
		.enter

		push	si
		call	HugeArrayLock		; ds:si <- record in  file
						; dx is trashed
		tst	ax
		ERROR_Z INVALID_INDEX_VALUE
		pop	di			; es:di <- modified record

		push	ds
		call	DFSortCallback
		tst	bx
		ERROR_NZ KEY_FIELD_MODIFIED_WITHOUT_SETTING_BUFFER_FLAG
		pop	ds
		
		call	HugeArrayUnlock
		
		.leave
		ret
ECCompareKeyFields		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validates the entire database

CALLED BY:	EXTERNAL
PASS:		bx - handle of DB
RETURN:		nada
DESTROYED:	nada (flags preserved)
 
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateDataStore	proc	far	
		uses	 di
		.enter
		pushf
	;
	; Do this extra EC only if ECF_VMEM EC is on
	;
		push	ax, bx
		call	SysGetECLevel
		test	ax, mask ECF_VMEM
		pop	ax, bx
		jz	exit
	;
	; Check the datastore
	;
		call	CheckFieldArray
		call	CheckRecordArray
exit:
		popf
		.leave
		ret
ECValidateDataStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFieldArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the field name array

CALLED BY:	ECValidateDataStore
PASS:		^hbx - datastore file
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/18/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFieldArray		proc	near
		uses	ax, bx, cx, si, di, ds
		dsHandle	local	hptr	push bx
		keysDone	local	word
		ForceRef	dsHandle
		.enter

		call	LockFieldNameElementArrayFar	; *ds:si <- array
		call	ECCheckChunkArray

		call	DFGetFieldCount			; ax <- # fields

		push	ax
		clr	cx
		mov	keysDone, cx
		mov	bx, SEGMENT_CS
		mov	di, offset CheckFieldNameElement
		call	ChunkArrayEnum			; cx <- # elements
		pop	ax
		
		cmp	ax, cx
		ERROR_NE 	INVALID_FIELD_COUNT

		call	VMUnlockDSFar	
		.leave
		ret
CheckFieldArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFieldNameElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a valid FieldNameElement

CALLED BY:	CheckFieldArray (via ChunkArrayEnum)
PASS:		*ds:si - FieldNameArray
		ds:di - FieldNameElement
		cx - count of elements in use
		bp - inherited stack frame

RETURN:		carry clear
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	cassie		10/18/95	Initial version
	tgautier 	 2/19/97	Add modification tracking

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFieldNameElement		proc	far
		.enter inherit CheckFieldArray

		jcxz	firstField
		
		cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
		jz	firstField			; set keysDone flag
		clr	ax
	; resume: ax = 0 if this was not a firstField
	; if it was a first field, don't set keysDone here since
	; it was set in the firstField code
resume:
		push	ax
		mov	al, ds:[di].FNE_data.FD_flags
		call	DSIsFieldFlagValid
		ERROR_C INVALID_FIELD_FLAGS
		test	al, mask FF_PRIMARY_KEY
		pop	ax
		jnz	primaryField
		tst	ax
		jnz	checkType
		mov	keysDone, 1			; set keysDone flag
checkType:
		mov	al, ds:[di].FNE_data.FD_type
		call	DSIsFieldTypeValid
		ERROR_C INVALID_FIELD_TYPE

		mov	al, ds:[di].FNE_data.FD_category
		call	DSIsFieldCategoryValid
		ERROR_C INVALID_FIELD_CATEGORY

		inc	cx
continue:
		clc
		.leave
		ret

firstField:
	;
	; If first field element has been deleted, there better not
	; be any keys following it, because key fields and timestamps
	; cannot be deleted.
	;
		mov	keysDone, 1
		cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
		jz	continue
		mov	keysDone, 0		; reset the keysDone flag
	;
	; If the first field is a timestamp field, make sure the
	; DSF_TIMESTAMP or the DSF_TRACK_MODS flag is set in the map block.
	;
		cmp	ds:[di].FNE_data.FD_type, DSFT_TIMESTAMP
		mov	ax, 1
		jne	resume

		mov	bx, dsHandle
		call	DFGetFlags
		test	ax, mask DSF_TIMESTAMP or mask DSF_TRACK_MODS
		ERROR_Z -1
		mov	ax, 1
		jmp	resume

primaryField:
	;
	; This field is marked as a primary key field. These fields
	; are added when the datastore is created, and because they
	; cannot be deleted, they should be contiguous and not intermixed
	; with free elements or non-key elements.
	;
		tst	keysDone
		ERROR_NZ KEY_FIELDS_OUT_OF_ORDER
		jmp	checkType
		
CheckFieldNameElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckRecordArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the records in the record array

CALLED BY:	INTERNAL
PASS:		^hbx - datastore file
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckRecordArray	proc	near	
		uses	ax, bx, cx, dx, si, di
		.enter

		call	GrabFileExclusive
	;
	; Check that record count matches number of elements in array
	;
		mov	ax, offset DSM_recordCount
		call	ReadDWordFromMapBlock		; dx.ax - record count

		push	dx, ax
		mov	di, offset DSM_recordArray
		call	ReadWordFromMapBlock		; di - handle of array

		call	ECCheckHugeArray	
		call	HugeArrayGetCount		; dx.ax - array count
		pop	cx, si

		cmp	cx, dx
		ERROR_NE INVALID_RECORD_COUNT
		cmp	si, ax
		ERROR_NE INVALID_RECORD_COUNT
		push	dx
		mov	dx, bx
	;
	; Now check each record in the array
	;
		push	bx
		push	di
		mov	ax, SEGMENT_CS
		push	ax
		mov	ax, offset CheckRecord
		push	ax
		clr	ax
		push	ax, ax		;Start at first record
		mov	ax, 0xffff
		push	ax, ax		;Check them all
		call	HugeArrayEnum
		call	VMReleaseExclusive
		pop   	dx
		.leave
		ret
CheckRecordArray	endp

CheckRecord	proc	far

	uses    dx
	.enter
	mov	bx, dx
	mov	si, di
	mov	dx, ax		
	call	ECCheckRecordElement
	clc
	.leave
	ret	
CheckRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECDuplicateRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a record to a block	

CALLED BY:	INTERNAL
PASS:		ds:di - RecordHeader
RETURN:		^hbx - block containing copy of record
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECDuplicateRecord		proc	far
		uses	ax, cx, si, di, es
		.enter

		mov	si, di
		mov	ax, ds:[si].RH_size
		push	ax
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc		; bx <- handle, ax <- segment
		pop	cx

		mov	es, ax
		clr	di
		rep	movsb
		call	MemUnlock
		
		.leave
		ret
ECDuplicateRecord		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if record has changed since duplicate was made

CALLED BY:	INTERNAL
PASS:		^hbx - handle of record block duplicate
		ds:di - Record
RETURN:		nothing - block at bx is freed
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckDuplicate		proc	far
		uses	ax, cx, si, di, es
		.enter

		tst	bx
		jz	done
		
		mov	si, di

		call	MemLock
		mov	es, ax
		clr	di
		mov	cx, es:[di].RH_size
		cmp	cx, ds:[si].RH_size
		ERROR_NE RECORD_MODIFIED_IN_FILE

		repe	cmpsb
		ERROR_NZ RECORD_MODIFIED_IN_FILE
		
		call	MemFree
done:
		.leave
		ret
ECCheckDuplicate		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabFileExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get exclusive access to the file, so no other thread can
		get in while we are in there.
CALLED BY:	INTERNAL
PASS:		bx - file handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabFileExclusive	proc	near	uses	ax, cx
	.enter
	mov	ax, VMO_WRITE		
	clr	cx			;No timeout - block
	call	VMGrabExclusive
	.leave
	ret
GrabFileExclusive	endp

FileECCode	ends

FileCommonCode	segment resource

LockFieldNameElementArrayFar	proc	far
		call	LockFieldNameElementArray
		ret
LockFieldNameElementArrayFar	endp

VMUnlockDSFar	proc	far
		call	VMUnlockDS
		ret
VMUnlockDSFar	endp
		
FileCommonCode	ends

endif


