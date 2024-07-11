COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c)  Geoworks 1995 -- All Rights Reserved

PROJECT:	GadgetDB
MODULE:		
FILE:		gdgdb.asm

AUTHOR:		David Loftesness, Nov 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	11/27/95   	Initial revision


DESCRIPTION:
		

	$Id: gdgdb.asm,v 1.1 98/03/11 04:31:18 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
UseLib  datastor.def

idata	segment

GadgetDBClass

idata	ends
	

GadgetDBCode segment resource


;;
;; Create property table
;;
makePropEntry database, databaseName, LT_TYPE_STRING,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_GET_NAME>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_SET_NAME>, \

makePropEntry database, numRecords, LT_TYPE_INTEGER,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_GET_NUM_RECORDS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_SET_NUM_RECORDS>, \

makePropEntry database, record, LT_TYPE_INTEGER,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_GET_RECORD>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_SET_RECORD>, \

makePropEntry database, recordID, LT_TYPE_LONG,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_GET_RECORD_ID>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_SET_RECORD_ID>, \

makePropEntry database, nextRecordID, LT_TYPE_LONG,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_GET_NEXT_RECORD_ID>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_SET_NEXT_RECORD_ID>, \

makePropEntry database, numFields, LT_TYPE_INTEGER,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_GET_NUM_FIELDS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DB_SET_NUM_FIELDS>, \

makeUndefinedPropEntry database, enabled
makeUndefinedPropEntry database, visible

compMkPropTable	GadgetDBProperty, database, databaseName, numRecords, \
	record, recordID, nextRecordID, numFields, enabled, visible

;;
;; Create action table
;;
makeActionEntry database, CreateDatabase \
	MSG_GADGET_DB_ACTION_CREATE, LT_TYPE_INTEGER, 7

makeActionEntry database, DeleteDatabase \
	MSG_GADGET_DB_ACTION_DELETE, LT_TYPE_INTEGER, 1

makeActionEntry database, OpenDatabase \
	MSG_GADGET_DB_ACTION_OPEN, LT_TYPE_INTEGER, 2

makeActionEntry database, CloseDatabase \
	MSG_GADGET_DB_ACTION_CLOSE, LT_TYPE_INTEGER, 0

makeActionEntry database, RenameDatabase \
	MSG_GADGET_DB_ACTION_RENAME, LT_TYPE_INTEGER, 1

makeActionEntry database, GetRecord \
	MSG_GADGET_DB_ACTION_GET_RECORD, LT_TYPE_INTEGER, 2

makeActionEntry database, PutRecord \
	MSG_GADGET_DB_ACTION_PUT_RECORD, LT_TYPE_INTEGER, 0

makeActionEntry database, PutRecordNoUpdate \
	MSG_GADGET_DB_ACTION_PUT_RECORD_NO_UPDATE, LT_TYPE_INTEGER, 0

makeActionEntry database, NewRecord \
	MSG_GADGET_DB_ACTION_NEW_RECORD, LT_TYPE_INTEGER, 0

makeActionEntry database, DeleteRecord \
	MSG_GADGET_DB_ACTION_DELETE_RECORD, LT_TYPE_INTEGER, 0

makeActionEntry database, GetField \
	MSG_GADGET_DB_ACTION_GET_FIELD, LT_TYPE_UNKNOWN, 1

makeActionEntry database, PutField \
	MSG_GADGET_DB_ACTION_PUT_FIELD, LT_TYPE_INTEGER, 2

makeActionEntry database, AddField \
	MSG_GADGET_DB_ACTION_ADD_FIELD, LT_TYPE_INTEGER, 3

makeActionEntry database, DeleteField \
	MSG_GADGET_DB_ACTION_DELETE_FIELD, LT_TYPE_INTEGER, 1

makeActionEntry database, RenameField \
	MSG_GADGET_DB_ACTION_RENAME_FIELD, LT_TYPE_INTEGER, 2

makeActionEntry database, SearchString \
	MSG_GADGET_DB_ACTION_SEARCH_STRING, LT_TYPE_INTEGER, 4

makeActionEntry database, SearchNumber \
	MSG_GADGET_DB_ACTION_SEARCH_NUMBER, LT_TYPE_INTEGER, 4

; array properties masquerading as actions
;
makeActionEntry database, GetfieldNames \
	MSG_GADGET_DB_ACTION_GET_FIELD_NAME, LT_TYPE_STRING, VAR_NUM_PARAMS

makeActionEntry database, GetfieldCategories \
	MSG_GADGET_DB_ACTION_GET_FIELD_CATEGORY, LT_TYPE_INTEGER, VAR_NUM_PARAMS

makeActionEntry database, GetfieldTypes \
	MSG_GADGET_DB_ACTION_GET_FIELD_TYPE, LT_TYPE_STRING, VAR_NUM_PARAMS

databaseActionTable	label	nptr.ActionEntryStruct
	word	offset databaseCreateDatabaseAction
	word	offset databaseDeleteDatabaseAction
	word	offset databaseOpenDatabaseAction
	word	offset databaseCloseDatabaseAction
	word	offset databaseRenameDatabaseAction
	word	offset databaseGetRecordAction
	word	offset databasePutRecordAction
	word	offset databasePutRecordNoUpdateAction
	word	offset databaseNewRecordAction
	word	offset databaseDeleteRecordAction
	word	offset databaseGetFieldAction
	word	offset databasePutFieldAction
	word	offset databaseAddFieldAction
	word	offset databaseDeleteFieldAction
	word	offset databaseRenameFieldAction
	word	offset databaseSearchStringAction
	word	offset databaseSearchNumberAction
	word	offset databaseGetfieldNamesAction
	word	offset databaseGetfieldCategoriesAction
	word	offset databaseGetfieldTypesAction
	word	ENT_ACTION_TABLE_TERMINATOR

if 0

macros can only take so many arguments, apparently.

compMkActTable database,  CreateDatabase, DeleteDatabase, OpenDatabase, \
			  CloseDatabase, RenameDatabase, GetRecord, \
			  PutRecord, PutRecordNoUpdate, NewRecord, \
			  DeleteRecord, GetField, \
			  PutField, AddField, DeleteField, RenameField, \
			  SearchString, SearchNumber, \
			  GetfieldNames, GetfieldCategory, GetfieldTypes
endif

MakeActionRoutines DB, database
MakePropRoutines DB, database

method GadgetUtilReturnReadOnlyError, GadgetDBClass, MSG_GADGET_DB_SET_RECORD
method GadgetUtilReturnReadOnlyError, GadgetDBClass,
	MSG_GADGET_DB_SET_RECORD_ID

Assert_ValidTableInstanceData macro
		if 0
		Assert	srange ds:[di].GT_numRows, 1, GADGET_TABLE_MAX_ROWS 
		Assert	srange ds:[di].GT_numCols, 1, GADGET_TABLE_MAX_COLS 
		
		Assert	ne 0, ds:[di].GT_rowHeights
		Assert	ne 0, ds:[di].GT_columnWidths
		Assert	chunk ds:[di].GT_rowHeights, ds
		Assert	chunk ds:[di].GT_columnWidths, ds

		Assert	srange ds:[di].GT_defaultRowHeight, 0, 1000
		endif
		
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/29/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBMetaResolveVariantSuperclass		method dynamic GadgetDBClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		mov	cx, segment ML2Class
		mov	dx, offset ML2Class
		ret
GadgetDBMetaResolveVariantSuperclass		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetDBClass object
		ds:di	= GadgetDBClass instance data
		ds:bx	= GadgetDBClass object (same as *ds:si)
		es 	= segment of GadgetDBClass
		ax	= message 
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBEntInitialize	method dynamic GadgetDBClass, 
					MSG_ENT_INITIALIZE
		.enter

		mov	di, offset GadgetDBClass
		call	ObjCallSuperNoLock
		
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset

		clr	ds:[di].GDBI_flags
		mov	ds:[di].GDBI_name, 0
		mov	ds:[di].GDBI_token, -1
		movdw	ds:[di].GDBI_recordNum, \
			GDB_RECORDNUM_FOR_NO_RECORD
		movdw	ds:[di].GDBI_recordID, \
			GDB_RECORDID_FOR_NO_RECORD
		
		.leave
		ret
GadgetDBEntInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetDBClass object
		ds:di	= GadgetDBClass instance data
		ds:bx	= GadgetDBClass object (same as *ds:si)
		es 	= segment of GadgetDBClass
		ax	= message 
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBMetaInitialize	method dynamic GadgetDBClass, 
					MSG_META_INITIALIZE
		.enter

		mov	di, offset GadgetDBClass
		call	ObjCallSuperNoLock
		
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		BitClr	ds:[di].EI_state, ES_IS_GEN
		BitClr	ds:[di].EI_state, ES_IS_VIS
		.leave
		ret
GadgetDBMetaInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close any open datastores before destroying

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= GadgetDBClass object
		ds:di	= GadgetDBClass instance data
		ds:bx	= GadgetDBClass object (same as *ds:si)
		es 	= segment of GadgetDBClass
		ax	= message 
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBEntDestroy	method dynamic GadgetDBClass, 
			MSG_ENT_DESTROY, MSG_META_DETACH
		uses	ax
		.enter

		mov	ax, ds:[di].GDBI_token
		mov	cx, ax
		call	DiscardRecordCommon
		jc	done

		tst	ds:[di].GDBI_flags
		jz	done
		mov_tr	ax, cx
		call	DataStoreClose
		clr	ds:[di].GDBI_flags
done:		
		.leave

		mov	di, offset GadgetDBClass
		call	ObjCallSuperNoLock
		
		ret
GadgetDBEntDestroy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCEntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/29/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBEntGetClass		method dynamic GadgetDBClass, MSG_ENT_GET_CLASS
		mov	cx, segment GadgetDBString
		mov	dx, offset GadgetDBString
		ret
GadgetDBEntGetClass		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDBGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the database name

CALLED BY:	MSG_GADGET_DB_GET_NAME
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:[bp] - GetPropertyArgs
RETURN:		database name string token
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBGetName	method dynamic GadgetDBClass,
						MSG_GADGET_DB_GET_NAME

		clr	ax			; assume no db open
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		jz	stuffReturnValue

		mov	ax, ds
		mov	di, ds:[di].GDBI_name
		mov	di, ds:[di]		; ax:di <- database name

		call	CopyStringToRunHeap	; ax <- token
	;
	; Return its token.
	;
stuffReturnValue:
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax
		ret
GadgetDBGetName		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDBGetNumRecords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the number of records

CALLED BY:	MSG_GADGET_DB_GET_NUM_RECORDS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:[bp] - GetPropertyArgs
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBGetNumRecords	method dynamic GadgetDBClass,
						MSG_GADGET_DB_GET_NUM_RECORDS
		.enter
	;
	; Raise a RTE if there is no database open.
	;
		call	DBCheckForNoOpenDatabaseOnPropertyAccess
		jc	done		

		
		mov	ax, ds:[di].GDBI_token
		call	DataStoreGetRecordCount
		jc	error

		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
done:
		.leave
		ret
error:
		les	di, ss:[bp].GPA_compDataPtr
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		call	PropError
		jmp	done
GadgetDBGetNumRecords		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDBGetNextRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the next record ID

CALLED BY:	MSG_GADGET_DB_GET_NEXT_RECORD_ID
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:[bp] - GetPropertyArgs
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBGetNextRecordID	method dynamic GadgetDBClass,
			MSG_GADGET_DB_GET_NEXT_RECORD_ID
		.enter
		
		call	DBCheckForNoOpenDatabaseOnPropertyAccess
		jc	done

		test	ds:[di].GDBI_flags, mask GDBF_RECORD_ID
		jz	noDBOpenOrNoID
		
		mov	ax, ds:[di].GDBI_token
		call	DataStoreGetNextRecordID
		jc	error

stuffReturnValue:
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_LONG
		movdw	es:[di].CD_data.LD_long, dxax
done:
		.leave
		ret
error:
		les	di, ss:[bp].GPA_compDataPtr
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		call	PropError
		jmp	done

noDBOpenOrNoID:
		mov	ax, GDB_RECORDID_FOR_NO_RECORD
		cwd
		jmp	stuffReturnValue
GadgetDBGetNextRecordID		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDBGetNumFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the number of fields

CALLED BY:	MSG_GADGET_DB_GET_NUM_FIELDS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:[bp] - GetPropertyArgs
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBGetNumFields	method dynamic GadgetDBClass,
			MSG_GADGET_DB_GET_NUM_FIELDS
		.enter

		call	DBCheckForNoOpenDatabaseOnPropertyAccess
		jc	done
	;
	;  The RecordID field isn't a "real" field, but in Legos it is,
	;  so if this database has a RecordID, then we need to account for
	;  it.
	
		mov	ax, ds:[di].GDBI_token
		push	ds,si
		call	DataStoreGetFieldCount
		pop	ds,si
		jc	error

		test	ds:[di].GDBI_flags, mask GDBF_RECORD_ID
		jz	setNum

		inc	ax					;account for
								;RecordID 
setNum:
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
done:
		.leave
		ret
error:
		les	di, ss:[bp].GPA_compDataPtr
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		call	PropError
		jmp	done
GadgetDBGetNumFields		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDBGetRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current record's number, 0 if it is a new record.

CALLED BY:	MSG_GADGET_DB_GET_RECORD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:[bp] - GetPropertyArgs
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		DataStore maintains a dword record number, but the
		DB component externally uses a word record number.
		If record number is FFFFFFFF, there's no problem
		returning the low word FFFF.  If the record number is
		greater than unsigned 7FFF (32767 dec), then we'll
		return garbage.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/30/95	Initial version
	jmagasin 8/20/96	Return LT_TYPE_INTEGER as DB spec says.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBGetRecord		method dynamic GadgetDBClass,
				MSG_GADGET_DB_GET_RECORD
		.enter
	;
	; Raise a RTE if there is no database open.
	;
		call	DBCheckForNoOpenDatabaseOnPropertyAccess
		jc	done

		
		test	ds:[di].GDBI_flags, mask GDBF_HAVE_NEW_RECORD
		jnz	haveNewRecord
		movdw	dxax, ds:[di].GDBI_recordNum
stuffRecordNum:
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
done:
		.leave
		ret
haveNewRecord:
		mov	ax, GDB_RECORDNUM_FOR_NEW_RECORD
		cwd
		jmp	stuffRecordNum
GadgetDBGetRecord		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDBGetRecordID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current record's id, -1 if none.

CALLED BY:	MSG_GADGET_DB_GET_RECORD_ID
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:[bp] - GetPropertyArgs
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBGetRecordID		method dynamic GadgetDBClass,
						MSG_GADGET_DB_GET_RECORD_ID
		.enter
	;
	; Raise a RTE if there is no database open.
	;
		call	DBCheckForNoOpenDatabaseOnPropertyAccess
		jc	exit
	;
	; If we don't have a record, or there's no RecordID field,
	; then return -1.
	;
		test	ds:[di].GDBI_flags, mask GDBF_HAVE_RECORD
		jz	noRecordOrNoID
		test	ds:[di].GDBI_flags, mask GDBF_RECORD_ID
		jz	noRecordOrNoID
		
		movdw	dxax, ds:[di].GDBI_recordID
stuffValue:
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_LONG
		movdw	es:[di].CD_data.LD_long, dxax

exit:
		.leave
		ret
noRecordOrNoID:
		mov	ax, GDB_RECORDID_FOR_NO_RECORD
		cwd
		jmp	stuffValue
GadgetDBGetRecordID		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionGetFieldInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets field name or type

CALLED BY:	MSG_GADGET_DB_ACTION_GET_FIELD_NAME,
		MSG_GADGET_DB_ACTION_GET_FIELD_TYPE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
		arg[0] = index of field

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Our buffers will be big enough for the biggest possible field name.
; Note that we word-align for swat.
if DBCS_PCGEOS
FIELD_NAME_BUFFER_SIZE equ (MAX_FIELD_NAME_LENGTH + 1) * (size TCHAR)
else
FIELD_NAME_BUFFER_SIZE equ (MAX_FIELD_NAME_LENGTH + 2) * (size TCHAR)
endif
CheckHack < MAX_FIELD_NAME_LENGTH eq 40 >	; As of 9/9/96, DataStore
						; specifies a max field name
						; length of 40.  Try to ensure
						; that we don't redefine this
						; constant to ensure word-
						; alignment.


GadgetDBActionGetFieldInfo	method dynamic GadgetDBClass,
				MSG_GADGET_DB_ACTION_GET_FIELD_NAME,
				MSG_GADGET_DB_ACTION_GET_FIELD_CATEGORY,
				MSG_GADGET_DB_ACTION_GET_FIELD_TYPE

		mov	cx, CPE_SPECIFIC_PROPERTY_ERROR
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
	LONG	jz	error


		mov	bx, di
	;
	;  Make sure we got the index arg
	;

		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
		mov	cx, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
	LONG	jne	error

	;
	; Get field info
	;
		mov	dx, es:[di].CD_data.LD_integer	;dl <- fieldID
	; a little passed value checking
		tst	dh
	LONG	jnz	error

		sub	sp, size FieldDescriptor + FIELD_NAME_BUFFER_SIZE +1
		mov	di, sp

		push	ax			; save message number

	;
	; We have to account for RecordID here. If the database has a
	; RecordID, then it's field 0, and everything else gets pushed back
	; by one.
	;
		test	ds:[bx].GDBI_flags, mask GDBF_RECORD_ID
		jz	checkTimestamp

	;
	; The database contains a RecordID, so if we've been asked for
	; field 0, that's what we give 'em. Otherwise, we just decrement
	; the number and pass it on.
	;
		dec	dx
		jns	checkTimestamp

	;
	; Lo and behold, it's the RecordID field. If we're looking for
	; the category, I guess we return 0. We return "RecordID" for
	; the name & "ID" for the type.
	;
		pop	ax				;ax <- msg #
		cmp	ax, MSG_GADGET_DB_ACTION_GET_FIELD_CATEGORY
		mov	cx, FC_NONE
		LONG	je	setCategory

		mov	di, offset IDTypeString
		cmp	ax, MSG_GADGET_DB_ACTION_GET_FIELD_TYPE
		je	setSpecialString
		mov	di, offset RecordIDFieldString

setSpecialString:
		mov	bx, handle Strings
		call	MemLock
		mov	es, ax
		mov	di, es:[di]			; ax:di <- field name
		call	CopyStringToRunHeap		; ax <- run heap
							; token
		call	MemUnlock
		jmp	okay

checkTimestamp:
		tst	dx
		jnz	notTimestamp

		test	ds:[bx].GDBI_flags, mask GDBF_TIMESTAMP
		jz	notTimestamp

	;
	; Lo and behold, it's the Timetamp field. If we're looking for
	; the category, I guess we return 0. We return "Timestamp" for
	; the name & "TIMESTAMP" for the type.
	;
		pop	ax				;ax <- msg #
		cmp	ax, MSG_GADGET_DB_ACTION_GET_FIELD_CATEGORY
		mov	cx, FC_NONE
		je	setCategory

		mov	di, offset TimestampTypeString
		cmp	ax, MSG_GADGET_DB_ACTION_GET_FIELD_TYPE
		je	setSpecialString
		mov	di, offset TimestampFieldString

		jmp	setSpecialString

notTimestamp:
		segmov	es, ss, cx
		mov	es:[di].FD_name.high, cx
		mov	cx, di
		add	cx, size FieldDescriptor
		mov	es:[di].FD_name.low, cx
		
		mov	ax, ds:[bx].GDBI_token
		call	MapIndexToFieldID
		mov	cx, FIELD_NAME_BUFFER_SIZE
		call	DataStoreGetFieldInfo
		pop	ax			; retrieve message number
		mov	cx, CPE_SPECIFIC_PROPERTY_ERROR
		jc	fieldError
		
		cmp	ax, MSG_GADGET_DB_ACTION_GET_FIELD_CATEGORY
		je	getCategory

		cmp	ax, MSG_GADGET_DB_ACTION_GET_FIELD_NAME
		jne	getType
	;
	; Copy the string to the run heap. 
	;
		movdw	axdi, es:[di].FD_name	; ax:di <- name
		call	CopyStringToRunHeap	; ax <- RunHeap token
okay:
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax
clearStack:
		add	sp, size FieldDescriptor + FIELD_NAME_BUFFER_SIZE +1
done:
		ret

getType:
		mov	al, es:[di].FD_data.FD_type
		call	MapFieldTypeToName		; ax <- field name str
		jmp	okay

getCategory:
		mov	cl, es:[di].FD_data.FD_category
		clr	ch

setCategory:
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		jmp	clearStack
		
fieldError:
		add	sp, size FieldDescriptor + FIELD_NAME_BUFFER_SIZE +1
error:
		les	di, ss:[bp].EDAA_retval
		mov	ax, cx
		call	PropError
		jmp	done
GadgetDBActionGetFieldInfo		endm

;
;IN:	dl = index
;	ax = datastore token
;OUT:	dl = FieldID
;
MapIndexToFieldID	proc	near
	uses	ax, cx, di, si, ds, es, bx
	.enter

	push	ax
	call	DataStoreGetFieldCount
	mov	cx, ax
	pop	ax		
	jc	error

EC<	tst	ch			>
EC<	ERROR_NZ -1			>
	cmp	dl, cl
	jae	error

	sub	sp, size FieldDescriptor +1
	mov	di, sp
	segmov	es, ss

	mov	cl, dl

	clr	dl
checkNext:
	push	ax
	mov_tr	bx, cx
	clr	cx				; don't get field name
	movdw	es:[di].FD_name, cxcx		; (Just to be tidy.)
	call	DataStoreGetFieldInfo
	mov_tr	cx, bx
	pop	ax
	jc	noDice

	jcxz	doneRestoreSP
	dec	cx

noDice:
	inc	dl
	cmp	dl, NULL_FIELD
	jne	checkNext

doneRestoreSP:
	add	sp, size FieldDescriptor +1
done:
	.leave
	ret
error:
	mov	dl, NULL_FIELD
	jmp	done
			
MapIndexToFieldID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a datastore

CALLED BY:	MSG_GADGET_DB_ACTION_CREATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionCreate		method dynamic GadgetDBClass,
				MSG_GADGET_DB_ACTION_CREATE
	;
	; Can't create a database until this one is closed
	;
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	cx, DSE_DATASTORE_ALREADY_OPEN
		LONG	jnz	dbError
	;
	;  Make sure we got the 2 args, name and "shared" flag
	;
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
	;
	; Check for valid parameters
	;

		push	ds
		call	CheckCreateParams
		pop	ds
		LONG	jnz	error
		LONG	jc	dbError
	;
	; Save object lptr on stack, and create params buffer on stack
	;
		push	si
		sub	sp, size DataStoreCreateParams + 1
		mov	si, sp			; ss:si <- create params

		mov	ax, es:[di][size ComponentData].CD_data.LD_integer
		call	SetCreateFlags
		LONG	jnz	fixStackAndFlagError
	;
	; Get # key fields and lock the datstore name string into es:di
	;
		mov	cx, es:[di][size ComponentData*2].CD_data.LD_integer
		mov	ss:[si].DSCP_keyCount, cx
EC <		cmp	cx, 1			; only 1 key supported  >
EC <		ERROR_A -1			; in first release	>
		
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapLock_asm		; es:di <- datastore name
		Assert	fptr esdi
		movdw	ss:[si].DSCP_name, esdi

		mov	ss:[si].DSCP_keyCount, cx	; save actual keyCount
		jcxz	noKeys
	;
	; Allocate stack space to hold as many FieldDescriptors as there are
	; elements in the passed arrays (and all arrays should be of the same
	; length). (each FieldDescriptor is 7 bytes)
	;
		mov	ax, size FieldDescriptor
		clr	dx
		mul	cx
EC <		tst	dx						>
EC <		ERROR_NZ -1						>
		sub	sp, ax
		mov	bx, sp
		movdw	ss:[si].DSCP_keyList, ssbx
		les	di, ss:[bp].EDAA_argv
		add	di, size ComponentData*3 	; array of field names
		call	BuildFieldDescriptorArray
		jc	afterCreate			; error occurred
noKeys:
	;
	; Create the datastore - it returns error or token in ax
	;
		push	ds
		segmov	ds, ss, ax
		clrdw	ds:[si].DSCP_notifObject, 0
		call	DataStoreCreate		; carry set if error
		pop	ds

	;
	; Clear the array of FieldDescriptors and the create params from
	; the stack
	;
afterCreate:
		mov	bx, ax			; save token in bx
		lahf
		add	sp, size DataStoreCreateParams + 1

		push	ax			; save flags
		clr	dx
		les	di, ss:[bp].EDAA_argv
		mov	cx, es:[di][size ComponentData*2].CD_data.LD_integer
		mov	ax, size FieldDescriptor
		mul	cx
		mov	cx, ax
		pop	ax			; restore flags
		add	sp, cx
		sahf
	;
	; Unlock everything we had locked above
	;
		call	UnlockCreateStuff
	;
	; If no error, initialize the thing's instance data.
	; Pass the flags parameter in cx, after setting the R/W flag.
	; Note: CDF_READ_WRITE is no longer used in database creation,
	;       but it's useful to InitForDataStoreOpened, which uses
	;	it to determine how to open the database.  See DBAction
	;	Rename, which uses CDF_READ_WRITE of reopen the db the
	;	same way it was previously open.
	;
		pop	si
		mov	cx, bx			; put possible error into cx
		jc	clearAndError
		mov	cx, es:[di][size ComponentData].CD_data.LD_integer
		or	cx, mask CDF_READ_WRITE
		call	InitForDataStoreOpened
		mov	cx, DSE_CREATE_ERROR
		jc	dbError

	;
	;  Success!
	;
		call	GadgetDBSuccessCommon

done:
		ret

fixStackAndFlagError:
		add	sp, (size DataStoreCreateParams + 1) + (size word)
		mov	cx, DSE_INVALID_FLAGS
		jmp	dbError

clearAndError:
		mov	si, ds:[si]
		add	si, ds:[si].GadgetDB_offset
		mov	ds:[si].GDBI_token, -1
		mov	ds:[si].GDBI_flags, 0
dbError:
		call	GadgetDBErrorCommon
		jmp	done
		
error:
		call	GadgetDBActionRTECommon

		jmp	done
GadgetDBActionCreate		endm

GadgetDBSuccessCommon	proc	near
	uses	di
	.enter
	les	di, ss:[bp].EDAA_retval
	mov	es:[di].CD_type, LT_TYPE_INTEGER
	mov	es:[di].CD_data.LD_integer, DSE_NO_ERROR
	.leave
	ret
GadgetDBSuccessCommon	endp

;
; Common code to return a DB error.
;	pass: cx    = db error returned to Legos code
;		      (same as DataStoreError)
;	      ss:bp = EntDoActionArgs
;
GadgetDBErrorCommon	proc	near
	uses	di
	.enter
	les	di, ss:[bp].EDAA_retval
	mov	es:[di].CD_type, LT_TYPE_INTEGER
	mov	es:[di].CD_data.LD_integer, cx
	.leave
	ret
GadgetDBErrorCommon	endp

;
; Common code for raising a RTE for an action.
;	pass: cx    = error
;	      ss:bp = EntDoActionArgs
;
GadgetDBActionRTECommon	proc	near
	.enter
	les	di, ss:[bp].EDAA_retval
	mov	es:[di].CD_type, LT_TYPE_ERROR
	mov	es:[di].CD_data.LD_error, cx
	.leave
	ret
GadgetDBActionRTECommon	endp



;
; The mapping from DataStore errors to Legos DB errors is as follows
; (taken from ~matta/Text/database.errors):
;
;   DataStoreError		- 1 to 1 mapping
;   DataStoreStructureError	- add 94, unless DSSE is common to
;				  DSE
;   DataStoreDataError		- add 187, unless DSDE is common to
;				  DSE or DSSE (then, add 94)
;
; This mapping depends on the DataStoreError, DataStoreStructureError
; and DataStoreDataError enumerations in datastor.def.


DSSE_TO_LEGOS_DB_ERROR	equ	94
DSDE_TO_LEGOS_DB_ERROR	equ	187

;
; Map a DataStoreStructureError in cx to an error code for
; the Legos db component.
;
MapDataStoreStructureErrorToLegosDBError	proc	near
		.enter
		pushf
		cmp	cx, DSSE_MEMORY_FULL
		jle	done
		add	cx, DSSE_TO_LEGOS_DB_ERROR
done:		
		popf
		.leave
		ret
MapDataStoreStructureErrorToLegosDBError	endp


;
; Map a DataStoreDataError in cx to an error code for
; the Legos db component.
;
MapDataStoreDataErrorToLegosDBError	proc	near
		.enter
		pushf
		cmp	cx, DSDE_MEMORY_FULL
		jle	done
		
		cmp	cx, DSDE_INVALID_RECORD_ID
		je	done
		
		cmp	cx, DSDE_INVALID_FIELD_ID
		jl	mapWithAddition
		cmp	cx, DSDE_RECORD_BUFFER_NOT_EMPTY
		jg	mapWithAddition
		call	MapDataStoreStructureErrorToLegosDBError
		jmp	done
		
mapWithAddition:
		add	cx, DSDE_TO_LEGOS_DB_ERROR
done:		
		popf
		.leave
		ret
MapDataStoreDataErrorToLegosDBError	endp

		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCreateParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	DBCActionCreate
PASS:		es:di - args passed to DBCActionCreate
		at ss:sp - EntObjBlock sptr

RETURN:		zero flag clear if runtime error
			cx = runtime error
		carry set if error that has an error code and
		zero flag is set.
			cx = database error code (if cf=zf=1)
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/21/95	Initial version
	jmagasin 8/13/96	Use CF and cx to differentiate btwn
				RTE and error manageable via error code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckCreateParams		proc	near	entObjBlockSPtr:sptr
		uses	ax, bx, dx, di, ds
		.enter
		
	; database name
		mov	cx, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_STRING	
		jne	error
	; flags
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_INTEGER
		jne	error

	; number of key fields
		cmp	es:[di][size ComponentData*2].CD_type, LT_TYPE_INTEGER
		jne	error
		mov	cx, es:[di][size ComponentData*2].CD_data.LD_integer
if 1
	;
	; Only 0 or 1 key fields supported in first release
	;
		jcxz	noKeyFields
		cmp	cx, 1
		je	getKeyFieldNames
		sub	cl, cl			; set zf
		stc
		mov	cx, GDBEC_INVALID_KEY_FIELD_COUNT
		jmp	error

	; array of key field names
getKeyFieldNames:
endif		
		add	di, size ComponentData * 3
		mov	dx, LT_TYPE_STRING
		call	checkArray
		jnz	error
		jc	error
		
	; array of key field types

		; check the size and types

		add	di, size ComponentData 
		mov	dx, LT_TYPE_STRING
		call	checkArray
		jnz	error
		jc	error


		; Check that each key field type is one of:
		; string, integer, long, float.

		push	ss:[entObjBlockSPtr]
		call	CheckKeyFieldTypesLegal
		pop	ss:[entObjBlockSPtr]
		jc	error


	; array of key field sort order
		add	di, size ComponentData 
		mov	dx, LT_TYPE_INTEGER
		call	checkArray
		jnz	error
		jc	error
if 0
;;; NOT SUPPORTED IN FIRST RELEASE
		
	; array of key field category
		add	di, size ComponentData 
		mov	dx, LT_TYPE_INTEGER
		call	checkArray
		; Jump to error, or move noKeyFields.
endif

noKeyFields:
		clc				; zf=1 from jcxz noKeyabove

error:		
		.leave
		ret

checkArray:
	;
	; Pass: es:di	- ComponentData
	;	cx	- number of elements,
	;       dx	- element type
	; Retn: zf	- set if es:di is array, clear if not
	;		  cx	- CAE_WRONG_TYPE if zf is clear
	;	cf	- set if some other error occurred for which
	;		  there is a database error code.
	;		  *NOTE* -- caller should check zf first.
	;		            cf is meaningless if zf is clear
	;		  cx	- database error code if cf is set and
	;			  zf is set
	;
		cmp	es:[di].CD_type, LT_TYPE_ARRAY
		jne	typeError
		
		mov	bx, es:[di].CD_data.LD_array
		call	MemLock
		mov	ds, ax
		cmp	ds:[AH_type], dx
		jne	typeError2
		
		cmp	cx, ds:[AH_maxElt]
		jne	countError
		
doneUnlock:		
		call	MemUnlock
done:		
		retn

typeError:
		mov	cx, CAE_WRONG_TYPE
		jmp	done
typeError2:
		mov	cx, CAE_WRONG_TYPE
		jmp	doneUnlock
countError:
		sub	cl, cl				; set zf
		mov	cx, DSE_INVALID_KEY_LIST
		stc
		jmp	doneUnlock
		
CheckCreateParams		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckKeyFieldTypesLegal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	CheckCreateParams

PASS:		es:di - keyFieldTypes array arg passed to DBCActionCreate
		at ss:sp - EntObjBlock sptr

RETURN:		carry flag clear
			- fields types are okay
			- cx preserved
		carry flag set
			- string is illegal type for key field
			- zero flag is set 
			- cx has error code

		Note both the carry and zero flags are set because
		CheckCreateParams needs to return with both set.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

register_return
CheckKeyFieldTypesLegal(register_args, sptr entObjBlockSPtr)
{

	#define kftArray	(es:di).CD_data.LD_array
	#define compBlock	ds

	word arrayHeaderHPtr = kftArray;
	word arrayHeaderSeg = MemLock(kftArray);

	if (arrayHeaderSeg->AH_maxElt == 0) {
		ClearCarryFlag();
		MemUnlock(arrayHeaderHPtr);
	} else {
		stringsSegSeg = MemLock(handle(Strings));
		TCHAR *fieldTypeString
			= RunHeapLock(compBlock, arrayHeaderSeg[0]);
	
		word oldCX = GetCX();

		int i;
		i = SPECIAL_STRINGS_COUNT - 1;
		while (i >= 0) {

			if (LocalCmpStrings(fieldTypeString,
			     *(stringsSegSeg + specialStringOffsets[i]),
			     0)
					== 0) {

				RunHeapUnlock(compBlock, arrayHeaderSeg[0]);

				SetCX(oldCX);
				ClearCarryFlag();

				goto done;
			}

			i--;
		}
				
		RunHeapUnlock(compBlock, arrayHeaderSeg[0]);

		SetZeroFlag();
		SetCarryFlag();
		SetCX(DSSE_INVALID_FIELD_TYPE
		      + DSSE_TO_LEGOS_DB_ERROR);
done:
		MemUnlock(handle(Strings));
	}

	MemUnlock(arrayHeaderHPtr);
}



KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	bkurtin	9/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

specialStringsOffsets		nptr \
	offset StringTypeString, \
	offset IntegerTypeString, \
	offset LongTypeString, \
	offset FloatTypeString

SPECIAL_STRINGS_COUNT	equ	4

CheckKeyFieldTypesLegal	proc	near	entObjBlockSPtr:sptr

		uses	ax, bx, ds, es, di, si
arrayHeaderSeg		local		word
arrayHeaderHPtr		local		hptr
stringsSegSeg		local		word
oldCX			local		word
		.enter


		mov	bx, es:[di].CD_data.LD_array
		mov	ss:[arrayHeaderHPtr], bx

		call	MemLock
		mov	ss:[arrayHeaderSeg], ax

		; es <- array header segment

		mov	es, ax

		; bx <- number of strings in the array

		mov	bx, es:[AH_maxElt]
		cmp	bx, 0
		ja	else_1

		clc
		jmp	end_if_1

else_1:
		mov	bx, handle Strings
		call	MemLock
		mov	ss:[stringsSegSeg], ax

		; es:di <- addr of field type string

		mov	es, ss:[arrayHeaderSeg]
		mov	ax, es:[size ArrayHeader]
		mov	ds, ss:[entObjBlockSPtr]
		call	RunHeapLock_asm

		mov	ss:[oldCX], cx

		; bx <- index of last string in specialStringsOffsets table

		mov	bx, (SPECIAL_STRINGS_COUNT - 1) * 2


		; Pull stuff for LocalCmpStrings out of the loop.
		
		mov	cx, 0
		mov	ds, ss:[stringsSegSeg]

while_1:
		cmp	bx, 0
		jl	end_while_1

		; ds:si <- addr of current special string

		mov	si, cs:[specialStringsOffsets][bx]
		mov	si, ds:[si]

		call	LocalCmpStrings

		jz	end_if_2

		add	bx, -2
		
		jmp	while_1
		
end_while_1:
		mov	ds, ss:[entObjBlockSPtr]
		call	RunHeapUnlock_asm

		; zero flag <- 0
		xor	cx, cx

		stc
		mov	cx, DSSE_INVALID_FIELD_TYPE + DSSE_TO_LEGOS_DB_ERROR

done:
		; Flags are preserved across MemUnlock as needed for return.

		mov	bx, handle Strings
		call	MemUnlock

end_if_1:
		mov	bx, ss:[arrayHeaderHPtr]
		call	MemUnlock

		.leave
		ret

end_if_2:
		mov	ds, ss:[entObjBlockSPtr]
		call	RunHeapUnlock_asm

		mov	cx, ss:[oldCX]
		clc

		jmp	done

CheckKeyFieldTypesLegal	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCreateFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets flags in DataStoreCreateParams

CALLED BY:	DBCActionCreate
PASS:		ss:si - DataStoreCreateParams
		ax - flags passed to CreateDatabase
RETURN:		ZF	- clear if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/21/95	Initial version
	jmagasin 7/19/96	Return ZF clear if try create shared DB.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCreateFlags		proc	near
		uses	bx
		.enter
	;
	; First make sure that only legal bits are set.
	; Note that CDF_READ_WRITE is no longer supported.
	;
		test	ax, not (mask CDF_SHARED or \
				 mask CDF_RECORD_ID or \
				 mask CDF_TIMESTAMP)
		jnz	exit
	;
	; Assume it will be opened exclusive.
	;
		mov	ss:[si].DSCP_flags, 0
		mov	ss:[si].DSCP_openFlags, mask DSOF_EXCLUSIVE
	;
	; If it is to be open shared, clear the exclusive flag, and make
	; sure that the ID flag has been set (shared DB's must have ID field)
	;
		test	ax, mask CDF_SHARED
		;jz	notShared
		jnz	exit				; error for Liberty1.0
		mov	ss:[si].DSCP_openFlags, 0	; 
EC <		test	ax, mask CDF_RECORD_ID				>
EC <		ERROR_Z -1						>
;notShared:
	;
	; Set the timestamp DataStoreCreateFlag, if timestamping is desired.
	;
		test	ax, mask CDF_TIMESTAMP
		jz	noTimestamp
		BitSet	ss:[si].DSCP_flags, DSF_TIMESTAMP
noTimestamp:
	;
	; Set the ID flag, if there is to be an ID field.
	;
		test	ax, mask CDF_RECORD_ID
		jz	noID
		BitSet	ss:[si].DSCP_flags, DSF_RECORD_ID
noID:
		sub	bl, bl				; no error, set ZF
exit:
		.leave
		ret
SetCreateFlags		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockCreateStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock any strings which were locked down when creating
		the datastore.

CALLED BY:	INTERNAL
PASS:		es:di - create args
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 8/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockCreateStuff		proc	near
		uses	ax, bx, cx, di, es
		.enter
		pushf
	;
	; Unlock datastore name
	;
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapUnlock_asm
		add	di, size ComponentData	; es:di <- flags
		add	di, size ComponentData	; es:di <- numKeyFields
	;
	; Get # fields in array
	;
		mov	cx, es:[di].CD_data.LD_integer
		jcxz	done
		add	di, size ComponentData	; es:di <- keyFieldNames array
	;
	; Lock the field name array and loop through it
	;
		mov	bx, es:[di].CD_data.LD_array
		call	MemLock
		mov	es, ax
		mov	di, size ArrayHeader
unlockLoop:
		mov	ax, es:[di]
		call	RunHeapUnlock_asm
		add	di, size word
		loop	unlockLoop

		call	MemUnlock		; unlock keyFieldNames array
done:
		popf
		.leave
		ret
UnlockCreateStuff		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildFieldDescriptorArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build array of FieldDescriptors

CALLED BY:	INTERNAL
PASS:		ss:si - DataStoreCreateParams
		ss:bx - array of FieldDescriptors
		es:di - array of args:
			array of field names (string)
			array of field types (string)
			array of field sort order (int)
			array of field categories (int)
		cx - number of array elements
RETURN:		ss:si.DSCP_keyCount = number of keys
		carry	- set if error encountered
				ax - "invalid field name" error code
				     "invalid field type" error code
			  clear otherwise
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine assumes that if the ID or TIMESTAMP field is one
	of the keys, the ID and timestamp flags are being passed to
	CreateDatabase, and therefore these fields don't have to be part
	of the keyList passed to DataStoreCreate.

	This routine is very dependent upon GadgetDBActionCreate's
	structure.  For example, UnlockCreateStuff should still be
	called even if this routine detects a reserved field name.
						-jmagasin 8/13/96

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 8/95	Initial version
	jmagasin 8/13/96	Don't allow reserved field names such
				as RecordID or Timestamp.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildFieldDescriptorArray	proc	near
		uses	bp
		.enter

		mov	bp, bx
		clr	dx			; initialize array index
		mov	ss:[si].DSCP_keyCount, dx

fdLoop:
	;
	; Lock the field name onto the run heap. 
	; All field names will be locked, to make unlocking easier.
	;
		mov	ax, es:[di].CD_data.LD_array
		call	GetWordFromArray	; ax <- string token
		pushdw	esdi
		call	RunHeapLock_asm
		Assert	fptr esdi
		movdw	ss:[bp].FD_name, esdi
		call	GadgetDBCheckForReservedFieldName
		popdw	esdi
		jz	errorReservedFieldName
	;
	; Get the field type. Type ID and type TIMESTAMP fields are
	; treated specially.
	;
		mov	ax, es:[di][ComponentData].CD_data.LD_array
		call	GetWordFromArray	; ax <- field type string token
		call	MapFieldTypeString		; carry set if ID type
		jc	noDice

EC <		cmp	al, DSFT_TIMESTAMP				>
EC <		jne	$10						>
EC <		test	ss:[si].DSCP_flags, mask DSF_TIMESTAMP		>
EC <		ERROR_Z -1						>
EC < $10:								>
		cmp	al, DSFT_TIMESTAMP
		je	noDice
		mov	ss:[bp].FD_type, al
	;
	; Get the sort order
	;
if 0
;; NOT SUPPORTED IN FIRST RELEASE
		mov	ax, es:[di][ComponendData*2].CD_data.LD_array
		call	GetWordFromArray
		call	MapSortOrder
		mov	ss:[bp].FD_flags, al
else
		clr	ss:[bp].FD_flags
endif
		
	;
	; Get the field category
	;
		mov	ax, es:[di][ComponentData*3].CD_data.LD_array
		clr	dx
		call	GetWordFromArray
;;;???		call	MapCategory
		mov	ss:[bp].FD_category, al
		inc	ss:[si].DSCP_keyCount		; one more key...
		add	bp, size FieldDescriptor	; pt to next FieldDesc.
noDice:
	;
	; If the field is of type ID or TIMESTAMP, it is not added to the
	; array of FieldDescriptors, so don't increment keyCount or update
	; the FieldDescriptor pointer, just update the array index and loop.
	;
		inc	dx				; inc the array index
		loop	fdLoop
		clc

done:
		.leave
		ret

errorReservedFieldName:
		inc	ss:[si].DSCP_keyCount		; Need to unlock
							; the resrvd key.
		mov	ax, DSSE_INVALID_FIELD_NAME + DSSE_TO_LEGOS_DB_ERROR
		stc
		jmp	done
BuildFieldDescriptorArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapFieldTypeToName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps from field type to field name, copying name to run heap

CALLED BY:	INTERNAL
PASS:		al - FieldType
		ds - segment of GadgetDB object
RETURN:		ax - RunHeap token 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/27/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapFieldTypeToName		proc	near
		uses	bx, cx, di, es
		.enter

EC <		cmp	al, DataStoreFieldType				>
EC <		ERROR_AE -1						>
		clr	ah
		shl	ax
		mov_tr	di, ax
		mov	di, cs:[typeTable][di]
		
		mov	bx, handle Strings
		call	MemLock
		mov	es, ax
		mov	di, es:[di]			; ax:di <- field name
		call	CopyStringToRunHeap		; ax <- run heap token

		mov	bx, handle Strings
		call	MemUnlock
		.leave
		ret

MapFieldTypeToName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapFieldTypeString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps from field type string to FieldType constant

CALLED BY:	BuildFieldDescriptorArray
PASS:		ax - RunHeap token for field type string
RETURN:		carry set if string == "ID", else
		al - FieldType
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/27/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapFieldTypeString		proc	near
		uses	bx, cx, si, di, es
		.enter

		push	ax, ds
		call	RunHeapLock_asm		; es:di <- field type string

		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
	;
	; special check for ID field first
	;
		mov	si, offset IDTypeString
		call	compareStrings
		stc
		jz	done
	;
	; Look for a matching field type string in our table
	;
		mov	cx, length typeTable
		mov	bx, offset typeTable - size lptr
tableLoop:
		add	bx, size lptr
		mov	si, cs:[bx]
		call	compareStrings
		je	found
		loop	tableLoop

	; default to binary if no other type matches
		mov	cl, DSFT_BINARY
		jmp	haveType
		
CheckHack< DSFT_INK eq (DataStoreFieldType - 1)>

found:				
		sub	cx, DSFT_INK
		neg	cx

haveType:		
		clc
done:
		pop	ax, ds
		pushf
		call	RunHeapUnlock_asm
		mov	bx, handle Strings
		call	MemUnlock
		popf
		mov	al, cl
		.leave
		ret

compareStrings:
		push	cx
		mov	si, ds:[si]			; ds:si <- string to match
		clr	cx
		call	LocalCmpStrings
		pop	cx
		retn
MapFieldTypeString		endp

typeTable	lptr	offset FloatTypeString,
			offset IntegerTypeString,
			offset LongTypeString,
			offset TimestampTypeString,
			offset DateTypeString,
			offset TimeTypeString,
			offset StringTypeString,
			offset BinaryTypeString,
			offset GraphicTypeString


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapFieldNameStringToType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps from field name string to DataStoreFieldType constant

		This is a total hack added in the final hour before LL4.
		Basically, before this time, the RecordID & Timestamp
		fields each had the same string for their field name and
		their field type. This is not how things are spec'd, so
		I've pulled the functionality of MapFieldTypeString out
		into this routine to simply return carry set of the passed
		string matches RecordIDFieldString, and al = DSFT_TIMESTAMP
		is it matches TimestampFieldString.


CALLED BY:	GetField, PutField

PASS:		ax - RunHeap token for field type string
RETURN:		carry set if string == RecordIDFieldString
		carry clear otherwise, with
			al = DSFT_TIMESTAMP iff string == TimestampFieldString,
			al = -1 otherwise (why not?)
DESTROYED:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	31 may 96	sweatin' it for LL4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapFieldNameStringToType		proc	near
		uses	bx, cx, si, di, es
		.enter

		push	ax, ds
		call	RunHeapLock_asm		; es:di <- field type string

		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
	;
	; special check for RecordID field first
	;
		mov	si, offset RecordIDFieldString
		call	compareStrings
		stc
		jz	done

	;
	; special check for Timestamp field 
	;
		mov	si, offset TimestampFieldString
		call	compareStrings
		clc
		mov	cl, DSFT_TIMESTAMP
		jz	done

		mov	cl, -1

done:
		pop	ax, ds
		pushf
		call	RunHeapUnlock_asm
		mov	bx, handle Strings
		call	MemUnlock
		popf
		mov	al, cl
		.leave
		ret

compareStrings:
		push	cx
		mov	si, ds:[si]			; ds:si <- string to match
		clr	cx
		call	LocalCmpStrings
		pop	cx
		retn
MapFieldNameStringToType		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWordFromArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read a word from an array

CALLED BY:	INTERNAL
PASS:		ax - array block
		dx - array index
RETURN:		ax - word
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 8/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetWordFromArray		proc	near
		uses	bx,si,ds
		.enter

		mov	bx, ax
		call	MemLock
		mov	ds, ax
		mov	si, size ArrayHeader
		add	si, dx				; si = AH + index
		add	si, dx				; si = AH + index*2
		mov	ax, ds:[si]
		call	MemUnlock

		.leave
		ret
GetWordFromArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a datastore

CALLED BY:	MSG_GADGET_DB_ACTION_OPEN
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/95	Initial version
	jmagasin 7/19/96	RTE if try open a shared DB since Legos and
				Liberty 1.0 don't support this.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionOpen		method dynamic GadgetDBClass,
						MSG_GADGET_DB_ACTION_OPEN
	;
	; Can't open a database until this one is closed
	;
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	cx, DSE_DATASTORE_ALREADY_OPEN
		LONG	jnz	dbError
	;
	;  Make sure we got the 2 args, name and flags
	;
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
	
		mov	cx, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	error
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_INTEGER
		jne	error
	;
	; Liberty 1.0 doesn't support shared db's, so the only legal flag
	; that Open will take is read/write.  (We really should have
	; separate OpenFlags now that CreateDatabase doesn't support
	; creating a read-only database.)
	;
		mov	cx, es:[di][size ComponentData].CD_data.LD_integer
		test	cx, not (mask CDF_READ_WRITE)
		jnz	flagError
	;
	; Lock the datstore name string into es:di
	;
		mov	ax, es:[di].CD_data.LD_string
		push	ax
		call	RunHeapLock_asm		; es:di <- datastore name
		Assert	fptr esdi

		mov	ax, 0			
		test	cx, mask CDF_SHARED	; is it shared?
		jnz	openShared	
		mov	ax, mask DSOF_EXCLUSIVE	; no, exclusive

openShared:
	;
	; Open the datastore - it returns error or token in ax
	;
		clrdw	cxdx			; no notifications, for now
		call	DataStoreOpen		; if carry, ax = DataStoreError
						;   else ax = datastore token
		mov	bx, ax			; bx <- token
		pop	ax
		pushf
		call	RunHeapUnlock_asm
		popf
	;
	; If no error, set fields in instance data.
	;
		mov	cx, bx			; indicate file doesn't exist
		jc	dbError
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
		mov	cx, es:[di][size ComponentData].CD_data.LD_integer
		call	InitForDataStoreOpened	; carry set if error
		mov	cx, DSE_OPEN_ERROR
		jc	dbError
	;
	;  Success!
	;
		call	GadgetDBSuccessCommon
done:		
		ret
		
error:
		call	GadgetDBActionRTECommon
		jmp	done

flagError:
		mov	cx, DSE_INVALID_FLAGS
dbError:
		call	GadgetDBErrorCommon
		jmp	done
GadgetDBActionOpen		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitForDataStoreOpened
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update instance data for datastore just opened.

CALLED BY:	INTERNAL
PASS:		*ds:si - GadgetDB object
		bx - datastore token
		cx - CreateDatabaseFlags
		es:di - ComponentData holding database name 
RETURN:		carry set if error,
		     datastore closed and inst data cleared
DESTROYED:	bx, cx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 8/95	Initial version
	jmagasin 8/21/96	Clear inst data on error

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitForDataStoreOpened		proc	near
		class GadgetDBClass
		uses	ax, si, bp
		.enter

		mov	bp, di			; es:bp <- args
	;
	; Save the datastore token.
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetDB_offset
		mov	ds:[di].GDBI_token, bx
	;
	; Set recordID and timestamp flags appropriately
	;
		mov	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	ax, bx
		push	cx
		call	DataStoreGetFlags
		pop	cx
		test	ax, mask DSF_RECORD_ID
		jz	noID
		BitSet	ds:[di].GDBI_flags, GDBF_RECORD_ID
noID:
		test	ax, mask DSF_TIMESTAMP
		jz	noTimestamp
		BitSet	ds:[di].GDBI_flags, GDBF_TIMESTAMP
noTimestamp:
	
		BitSet	ds:[di].GDBI_flags, GDBF_OPEN_EXCLUSIVE	
		test	cx, mask CDF_SHARED
		jz	notShared
		BitClr	ds:[di].GDBI_flags, GDBF_OPEN_EXCLUSIVE	;it is shared,
		test	ds:[di].GDBI_flags, mask GDBF_RECORD_ID	;must have ID
		jz	errorClose				
notShared:
		test	cx, mask CDF_READ_WRITE		; check if opened R/W
		jz	notReadWrite			; no, only readable
		BitSet	ds:[di].GDBI_flags, GDBF_OPEN_READ_WRITE
notReadWrite:		
	;
	; Copy the datastore name to a new chunk.
	;

	;
	; Tack on a "(complex)" at the end here so's we can use it
	; to access the associated VM file, if any. We'll keep the
	; null after the proper filename in place, and change it to
	; a space as needed.
	;
		mov	ax, es:[bp].CD_data.LD_string
		call	String2DBName

		mov	si, ds:[si]
		add	si, ds:[si].GadgetDB_offset
		mov	bx, ax			;bx <- new name chunk
		xchg	ds:[si].GDBI_name, ax	;ax <- old name chunk
		tst_clc	ax
		jz	done

	;
	; This thing had an old name, so presumably, we're in the middle
	; of a rename action, as oppposed to a create or an open. We need
	; to rename the associated VM file here so that we don't lose
	; track of it, then free the old name.
	;
		call	RenameAssociatedVMFile
		call	LMemFree			
		clc
done:
		.leave
		ret

errorClose:
		CheckHack <GDB_RECORDNUM_FOR_NO_RECORD eq -1>
		CheckHack <GDB_RECORDNUM_FOR_NO_RECORD eq \
			   GDB_RECORDID_FOR_NO_RECORD>
		mov	ax, GDB_RECORDNUM_FOR_NO_RECORD
		movdw	ds:[di].GDBI_recordNum, axax
		movdw	ds:[di].GDBI_recordID, axax
		clr	ds:[di].GDBI_flags
		xchg	ax, ds:[di].GDBI_token
		call	DataStoreClose
		stc
		jmp	done
		
InitForDataStoreOpened		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a datastore

CALLED BY:	MSG_GADGET_DB_ACTION_DELETE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionDelete		method dynamic GadgetDBClass,
						MSG_GADGET_DB_ACTION_DELETE
	;
	;  Make sure we got the name arg
	;
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
	
		mov	cx, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	error
	;
	; Lock the datstore name string into es:di
	;
		mov	ax, es:[di].CD_data.LD_string
		push	ax
		call	RunHeapLock_asm		; es:di <- datastore name
		Assert	fptr esdi

		push	ds
		segmov	ds, es, dx
		mov	dx, di			; ds:dx <- datastore name
		call	DataStoreDelete	 	; CF if error, ax =
						; DataStoreError
		pop	ds
		
		mov	cx, ax			; cx <- DataStoreError
		pop	ax
		pushf
		call	RunHeapUnlock_asm
		popf
		jc	dbError
	;
	;  Success!
	;
		call	String2DBName
		call	DeleteAssociatedVMFile

		call	GadgetDBSuccessCommon

done:		
		ret

dbError:
		call	GadgetDBErrorCommon
		jmp	done

error:
		call	GadgetDBActionRTECommon
		jmp	done
GadgetDBActionDelete		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Renames a datastore

CALLED BY:	MSG_GADGET_DB_ACTION_RENAME
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine neglects to free up the chunk that holds the
	name of the DB in all error cases.  However there are more
	pressing/probable bugs to work on right now.  Also, the
	chunk should get freed up on subsequent calls to InitForData
	StoreOpened anyway, so I don't think there's a leak here.

	If an error occurs in DataStoreRename, we should try and
	reopen the DB.  To do so, we'd like to use the code following
	DataStoreRename to open the DB under its original name and
	flags.  But this requires some special code:
		1.  to handle errors properly
		2.  to trick InitForDataStoreOpened into not
		    calling RenameAssociatedVMFile
	The errorRenaming, errorRenaming2, errorAtReopening, and
	errorAfterInit sections take care of this.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/95	Initial version
	jmagasin 8/19/96	Added locals.  Changed to reopen db
				if rename fails.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionRename		method dynamic GadgetDBClass,
						MSG_GADGET_DB_ACTION_RENAME
		mov	bx, bp
actionArgs	local	word		push	bx
renameError	local	word
nameChunk	local	word		
		.enter

		call	GadgetDBCheckRenamable
		LONG	jz	dbError

		mov	bx, di			;ds:bx <- instance data
		mov	di, ds:[di].GDBI_name	
		mov	dx, ds:[di]		;ds:dx <- current name
	;
	; Init some locals now.  (Do here for clarity.)
	;
		mov	cx, ds:[bx].GDBI_flags
		clr	ss:[renameError]
		clr	ss:[nameChunk]
	;
	;  Make sure we got the new name arg
	;
		mov	di, ss:[actionArgs]
		les	di, ss:[di].EDAA_argv
		Assert	fptr	esdi
	
		mov	ax, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_STRING
		LONG	jne	error
	;
	; Close the currently open datastore before renaming it.
	;
		call	DiscardRecordCommon
		mov	ax, ds:[bx].GDBI_token
		call	DataStoreClose
		jc	dbErrorInAX
		clr	ds:[bx].GDBI_flags
	;
	; Lock the new datstore name string into es:di
	; Pass old name in ds:dx
	;
		mov	ax, es:[di].CD_data.LD_string
		push	ax
		call	RunHeapLock_asm		; es:di <- datastore name
		Assert	fptr esdi
		LocalIsNull	es:[di]
		mov	ax, DSE_INVALID_NAME
		jz	errorRenaming

		call	DataStoreRename		; carry set if error
		jc	errorRenaming
	;
	; Try to reopen the datastore under the (possibly) new
	; name, in es:di.
	;
tryReopen:
		mov	ax, mask DSOF_EXCLUSIVE	; assume exclusive
		test	cx, mask GDBF_OPEN_EXCLUSIVE
		jnz	openExcl
		clr	ax			; no flags
openExcl:
		push	cx			; save GadgetDBFlags
		clrdw	cxdx
		call	DataStoreOpen
		mov	bx, ax			; bx <- datastore token
		pop	cx			; cx <- GadgetDBFlags
	;
	; Unlock the new name, saving carry flag in case of error
	;
		pop	ax			; ax <- string token
		pushf
		call	RunHeapUnlock_asm
		popf
		mov	ax, bx
		jc	errorAtReopening
	;
	; Save the new token, and reset the GadgetDBFlags correctly
	;
		mov	ax, cx
		clr	cx			; assume exclusive
		test	ax, mask GDBF_OPEN_EXCLUSIVE
		jnz	notShared
		mov	cx, mask CDF_SHARED	; no, it's shared
notShared:		
		test	ax, mask GDBF_OPEN_READ_WRITE
		jz	gotFlags
		or	cx, mask CDF_READ_WRITE
gotFlags:
		mov	di, ss:[actionArgs]
		les	di, ss:[di].EDAA_argv
		call	InitForDataStoreOpened
		mov	ax, DSE_WRITE_ERROR
		jc	errorAtReinit
	;
	; Success!  (Unless DataStoreRename failed.)
	;
		mov	cx, ss:[renameError]
		tst	cx
		jnz	errorRenaming2
		push	bp
		mov	bp, ss:[actionArgs]
		call	GadgetDBSuccessCommon
		pop	bp

done:
		.leave
		ret
dbErrorInAX:
		mov_tr	cx, ax
dbError:
		push	bp
		mov	bp, ss:[actionArgs]
		call	GadgetDBErrorCommon
		pop	bp
		jmp	done

error:
		mov_tr	cx, ax
		push	bp
		mov	bp, ss:[actionArgs]
		call	GadgetDBActionRTECommon
		pop	bp
		jmp	done

	;
	; Couldn't rename file.  Save error and current db name for
	; later.  Then jump back into main body of routine to unlock
	; string and try to reopen the DB under the original name.
	;
	; ds:dx	= original name
	; ax = DataStoreError
	;
errorRenaming:
		movdw	esdi, dsdx		; Open old db on error.
		mov	ss:[renameError], ax
		Assert	ne ax, 0
EC <		call	ECCheckObjectAtDSBX				>
		clr	ax
		xchg	ds:[bx].GDBI_name, ax	; Skip RenameAssoc.VMFile
		Assert	ne ax, 0		; in InitForD..S..Opened.
		mov	ss:[nameChunk], ax	; (see errorRenaming2)
		jmp	tryReopen

	;
	; InitForDataStoreOpened has alloc'd a new chunk for our
	; name.  Since the rename failed, delete the new chunk and
	; stuff our old one back in.
	;
errorRenaming2:
		mov	ax, ss:[nameChunk]
		mov	si, ds:[si]
		add	si, ds:[si].GadgetDB_offset
		xchg	ax, ds:[si].GDBI_name
		Assert	ne ax, 0
		tst	ax
		jz	dbError
		call	LMemFree
		jmp	dbError
	;
	; Error occurred reopening db.  If we're saving the nameChunk
	; (true iff error occurred when renaming), then free it now.
	; (We could just stick it back in the object and have InitFor
	; DataStoreOpened take care of it later.)
	;
errorAtReopening:
		mov_tr	cx, ax				; cx <- error
		mov	ax, ss:[nameChunk]
		tst	ax
		jz	dbError				; no rename error
		call	LMemFree
		mov	cx, ss:[renameError]
		jmp	dbError
	;
	; InitForDataStoreOpened failed.  Handle cleanup specially if
	; we already encountered an error when renaming.  Just free
	; nameChunk since we know there's no open DB if InitFDSO failed.
	;
errorAtReinit:
		mov_tr	cx, ax				; cx <- error
		mov	ax, ss:[nameChunk]
		tst	ax
		jz	dbError
		call	LMemFree
		mov	cx, ss:[renameError]
		jmp	dbError
GadgetDBActionRename		endm


if ERROR_CHECK
ECCheckObjectAtDSBX	proc	near
		.enter
		push	si
		mov	si, ds:[si]
		add	si, ds:[si].GadgetDB_offset
		Assert	e bx, si
		pop	si
		.leave
		ret
ECCheckObjectAtDSBX	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDBCheckRenamable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the current open db is shared or read-only,
		in which case it cannot be renamed (db-wise or field-
		wise).

CALLED BY:	GadgetDBActionRename, GadgetDBActionRenameField
PASS:		ds:di	- instance data of db component
RETURN:		zf	- set if error occurred
			  cx = db error code
			- clear if no error (and cx is trashed)
DESTROYED:	cx if no error occurred
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 7/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBCheckRenamable	proc	near
.warn -private
		.enter

	;
	; If the db is shared or read-only, then return an error.
	;
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	cx, GDBEC_DATABASE_NOT_OPEN
		jz	exit
		
		test	ds:[di].GDBI_flags, mask GDBF_OPEN_EXCLUSIVE
		mov	cx, DSE_ACCESS_DENIED
		jz	exit

		test	ds:[di].GDBI_flags, mask GDBF_OPEN_READ_WRITE
exit:
		.leave
		ret
.warn @private
GadgetDBCheckRenamable	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the datastore

CALLED BY:	MSG_GADGET_DB_ACTION_CLOSE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler),
		ax, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionClose		method dynamic GadgetDBClass,
						MSG_GADGET_DB_ACTION_CLOSE

		call	DiscardRecordCommon
		mov_tr	cx, ax
		jc	dbError
		
		mov	si, ds:[si]
		add	si, ds:[si].GadgetDB_offset
		mov	ax, ds:[di].GDBI_token
		call	DataStoreClose		; carry set if error, ax = DataStoreError
		mov	cx, ax
		jc	dbError
		clr	ds:[di].GDBI_flags

		clr	ax
		xchg	ax, ds:[di].GDBI_name
		call	LMemFree
		
	;
	;  Success!
	;
		call	GadgetDBSuccessCommon

done:		
		ret

dbError:
		call	GadgetDBErrorCommon
		jmp	done
GadgetDBActionClose		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionGetRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a record, make it the current record

CALLED BY:	MSG_GADGET_DB_ACTION_GET_RECORD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version
	jmagasin 7/26/96	Return Legos DB errors instead of RTE;
				don't touch instance data until sure success.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionGetRecord	method dynamic GadgetDBClass,
						MSG_GADGET_DB_ACTION_GET_RECORD

	;
	;  Make sure we got the record number arg and isID flag
	;
		les	bx, ss:[bp].EDAA_argv
		Assert	fptr	esbx
	
		mov	cx, CAE_WRONG_TYPE
		cmp	es:[bx][size ComponentData].CD_type, LT_TYPE_INTEGER
		jne	error

		cmp	es:[bx].CD_type, LT_TYPE_LONG
		je	isLong

		cmp	es:[bx].CD_type, LT_TYPE_INTEGER
		jne	error
		mov	ax, es:[bx].CD_data.LD_integer
		cwd
		mov_tr	cx, ax
		pushdw	dxcx

	;
	; Discard any current record, then load the desired record.
	;
discard:
	; dxcx pushed onto stack at this point
		call	DiscardRecordCommon		; ax <- error code
		jc	dbError

		mov	ax, ds:[di].GDBI_token
		cmp	es:[bx][size ComponentData].CD_data.LD_integer, 0
		jnz	isID

		call	DataStoreLoadRecordNum
		jc	dsdeDbError
		movdw	ds:[di].GDBI_recordID, dxcx
		popdw	dxcx
		movdw	ds:[di].GDBI_recordNum, dxcx
		jmp	noError
isID:		
		call	DataStoreLoadRecord
		jc	dsdeDbError
		movdw	ds:[di].GDBI_recordNum, dxcx
		popdw	dxcx
		movdw	ds:[di].GDBI_recordID, dxcx

noError:
		BitSet	ds:[di].GDBI_flags, GDBF_HAVE_RECORD
		BitClr	ds:[di].GDBI_flags, GDBF_HAVE_NEW_RECORD

		call	GadgetDBSuccessCommon

done:		
		ret
isLong:
		movdw	dxcx, es:[bx].CD_data.LD_long
		pushdw	dxcx
		jmp	discard

	;
	; DataStoreLoadRecord{Num} aren't supposed to return DSDE,
	; but they do.
	;
dsdeDbError:
		mov_tr	cx, ax
		call	MapDataStoreDataErrorToLegosDBError
		mov_tr	ax, cx
dbError:
		add	sp, size dword			; "pop" dxcx
		mov_tr	cx, ax
		call	GadgetDBErrorCommon
		jmp	done
error:
		call	GadgetDBActionRTECommon
		jmp	done
GadgetDBActionGetRecord		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionPutRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the current record to file.

CALLED BY:	MSG_GADGET_DB_ACTION_PUT_RECORD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionPutRecord	method dynamic GadgetDBClass,
			MSG_GADGET_DB_ACTION_PUT_RECORD, 
			MSG_GADGET_DB_ACTION_PUT_RECORD_NO_UPDATE

		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	cx, GDBEC_DATABASE_NOT_OPEN
		jz	dbError
		test	ds:[di].GDBI_flags, mask GDBF_OPEN_READ_WRITE
		mov	cx, DSE_ACCESS_DENIED
		jz	dbError
		test	ds:[di].GDBI_flags, mask GDBF_HAVE_RECORD
		mov	cx, GDBEC_NO_CURRENT_RECORD
		jz	dbError
	;
	; Save the record.
	;
		clr	cx, dx
		cmp	ax, MSG_GADGET_DB_ACTION_PUT_RECORD_NO_UPDATE
		mov	ax, ds:[di].GDBI_token
		je	noUpdate
		call	DataStoreSaveRecord
afterCall:
		mov	cx, DSE_UPDATE_ERROR
		jc	dbError
	;
	;  Success! Reset instance data to show there is no record
	;
		and	ds:[di].GDBI_flags, \
			not (mask GDBF_HAVE_RECORD or \
			     mask GDBF_HAVE_NEW_RECORD or \
			     mask GDBF_RECORD_MODIFIED)
		movdw	ds:[di].GDBI_recordNum, GDB_RECORDNUM_FOR_NO_RECORD
		movdw	ds:[di].GDBI_recordID, GDB_RECORDID_FOR_NO_RECORD
		
		call	GadgetDBSuccessCommon

done:		
		ret

dbError:
		call	GadgetDBErrorCommon
		jmp	done
noUpdate:
		call	DataStoreSaveRecordNoUpdate
		jmp	afterCall
GadgetDBActionPutRecord		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionNewRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discards the current record, and creates a new record.

CALLED BY:	MSG_GADGET_DB_ACTION_NEW_RECORD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionNewRecord	method dynamic GadgetDBClass,
						MSG_GADGET_DB_ACTION_NEW_RECORD

	;
	; Discard any existing record.
	;
		call	DiscardRecordCommon
		mov_tr	cx, ax
		jc	dbError
		test	ds:[di].GDBI_flags, mask GDBF_OPEN_READ_WRITE
		mov	cx, DSE_ACCESS_DENIED
		jz	dbError
	;
	; Create a new record, and set the RECORD flag.
	;
		mov	ax, ds:[di].GDBI_token
		call	DataStoreNewRecord
		jc	mapDSDEInAX
		or	ds:[di].GDBI_flags, \
			mask GDBF_HAVE_RECORD or mask GDBF_HAVE_NEW_RECORD
		
		call	GadgetDBSuccessCommon

done:		
		ret

mapDSDEInAX:
		mov_tr	cx, ax
		call	MapDataStoreDataErrorToLegosDBError		
dbError:
		call	GadgetDBErrorCommon
		jmp	done
GadgetDBActionNewRecord		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionDeleteRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the current record

CALLED BY:	MSG_GADGET_DB_ACTION_DELETE_RECORD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionDeleteRecord	method dynamic GadgetDBClass,
					MSG_GADGET_DB_ACTION_DELETE_RECORD

	;
	; Save the recordID and flags, then discard this record.
	;
		mov	cx, ds:[di].GDBI_flags
		movdw	dxbx, ds:[di].GDBI_recordID
		call	DiscardRecordCommon
		xchg	ax, cx				; cx <- error (if any)
							; ax <- old flags
		jc	dbError
	;
	; Need an open, writable DB to delete a record.  Note that
	; the flags we check aren't changed by DiscardRecordCommon.
	;
		test	ax, mask GDBF_DATASTORE_OPEN
		mov	cx, GDBEC_DATABASE_NOT_OPEN
		jz	dbError
		test	ax, mask GDBF_OPEN_READ_WRITE
		mov	cx, DSE_ACCESS_DENIED
		jz	dbError
	;
	; If we didn't have a record, speak up now.
	;
		test	ax, mask GDBF_HAVE_RECORD
		jnz	doDeletion
		mov	cx, GDBEC_NO_CURRENT_RECORD
		jmp	dbError
	;
	; Delete the current record and reset instance data
	;
doDeletion:
		mov_tr	cx, bx				; dxcx = recordID
		mov	ax, ds:[di].GDBI_token
		call	DataStoreDeleteRecord
		jnc	success
		
		mov_tr	cx, ax
		call	MapDataStoreDataErrorToLegosDBError
		jc	dbError

success:
		call	GadgetDBSuccessCommon

done:		
		ret

dbError:
		call	GadgetDBErrorCommon
		jmp	done
GadgetDBActionDeleteRecord		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionAddField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a field

CALLED BY:	MSG_GADGET_DB_ACTION_ADD_FIELD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionAddField	method dynamic GadgetDBClass,
						MSG_GADGET_DB_ACTION_ADD_FIELD

	;
	; Discard changes regardless of whether AddField succeeds.
	;
		call	DiscardRecordCommon
		jnc	checkOpenWritableDB
		mov_tr	cx, ax
		jmp	dbError
	;
	; Need an open, writable DB to delete a record.
	;
checkOpenWritableDB:
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	cx, GDBEC_DATABASE_NOT_OPEN
		LONG	jz	dbError
		test	ds:[di].GDBI_flags, mask GDBF_OPEN_READ_WRITE
		mov	cx, DSE_ACCESS_DENIED
		LONG	jz	dbError
	;
	;  Make sure we got the 3 args: name, type, and category
	;
		mov	bx, di			; ds:bx <- instance data
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
	
		cmp	es:[di].CD_type, LT_TYPE_STRING
		LONG	jne	error
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_STRING
		LONG	jne	error
		cmp	es:[di][2 * (size ComponentData)].CD_type, LT_TYPE_INTEGER
		LONG	jne	error
	;
	; Get the field category
	;
		mov	cx, es:[di][2 * (size ComponentData)].CD_data.LD_integer
		cmp	cx, FieldCategory
		jb	getFieldType
		mov	cx, DSSE_INVALID_FIELD_CATEGORY
		call	MapDataStoreStructureErrorToLegosDBError
		jmp	dbError

	;
	; Get the field type
	;
getFieldType:
		mov	ax, es:[di][size ComponentData].CD_data.LD_string
		call	MapFieldTypeString
		jc	fieldTypeError
		cmp	al, DSFT_TIMESTAMP
		je	fieldTypeError
		mov	ch, al
		jmp	getFieldName
fieldTypeError:
		mov	cx, DSSE_INVALID_FIELD_TYPE + DSSE_TO_LEGOS_DB_ERROR
		jmp	dbError
		
	;
	; Lock the field name string and make sure it's legal.
	;
getFieldName:
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapLock_asm		; es:di <- field name
		Assert	fptr esdi
		LocalIsNull	es:[di]
		jz	invalidFieldName
		call	GadgetDBCheckForReservedFieldName
		jnz	fillFieldDescriptor
invalidFieldName:
		call	RunHeapUnlock_asm
		mov	cx, DSSE_INVALID_FIELD_NAME + DSSE_TO_LEGOS_DB_ERROR
		jmp	dbError
	;
	; Fill in the FieldDescriptor and add the field
	;
fillFieldDescriptor:
		mov	ax, ds:[bx].GDBI_token
		sub	sp, size FieldDescriptor + 1
		mov	bx, sp
		movdw	ss:[bx].FD_name, esdi
		mov	ss:[bx].FD_data.FD_type, ch
		mov	ss:[bx].FD_data.FD_category, cl
		clr	ss:[bx].FD_data.FD_flags

		movdw	esdi, ssbx		; es:di <- FieldDescriptor
		call	DataStoreAddField	; carry set if error
		jnc	fixStack
		mov_tr	cx, ax
		call	MapDataStoreStructureErrorToLegosDBError

fixStack:
		lahf
		add	sp, size FieldDescriptor + 1
		sahf

		pushf
		les	di, ss:[bp].EDAA_argv
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapUnlock_asm
		popf
		jc	dbError					

		call	GadgetDBSuccessCommon
done:		
		ret

error:
		mov	cx, CAE_WRONG_TYPE
		call	GadgetDBActionRTECommon
		jmp	done

dbError:
		call	GadgetDBErrorCommon
		jmp	done
GadgetDBActionAddField		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDBCheckForReservedFieldName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the reserved field names "RecordID" and
		"Timestamp"

CALLED BY:	GadgetDBActionAddField
PASS:		es:di	- name of field to check
RETURN:		ZF	- set if field name is reserved
			  carry - set if RecordID
				  clear if Timestamp
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	MapFieldNameStringToType could accomplish the same thing,
	but string is already locked so might as well be be efficient.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBCheckForReservedFieldName	proc	near
		uses	ax, si, bx, ds, cx
		.enter

		mov	bx, handle Strings
		call	MemLock
		Assert	carryClear
		mov	ds, ax

		clr	cx
		mov	si, offset TimestampFieldString
		mov	si, ds:[si]
		call	LocalCmpStrings
		jz	isTimestamp
		
		mov	si, offset RecordIDFieldString
		mov	si, ds:[si]
		call	LocalCmpStrings
		jnz	doUnlock
		stc
doUnlock:
		call	MemUnlock
 		
		.leave
		ret

isTimestamp:
		clc
		jmp	doUnlock
GadgetDBCheckForReservedFieldName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionDeleteField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a field

CALLED BY:	MSG_GADGET_DB_ACTION_DELETE_FIELD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionDeleteField	method dynamic GadgetDBClass,
					MSG_GADGET_DB_ACTION_DELETE_FIELD
	;
	; Discard changes regardless of whether DeleteField succeeds.
	;
		call	DiscardRecordCommon
		jnc	checkOpenWritableDB
		mov_tr	cx, ax
		jmp	dbError
	;
	; Make sure we've got an open, writable database.
	;
checkOpenWritableDB:
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	cx, GDBEC_DATABASE_NOT_OPEN
		jz	dbError
		test	ds:[di].GDBI_flags, mask GDBF_OPEN_READ_WRITE
		mov	cx, DSE_ACCESS_DENIED
		jz	dbError
	;
	;  Make sure we got the arg, the field name 
	;
		mov	bx, di			; ds:bx <- instance data
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
	
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	error
	;
	; Lock the field name string into es:di
	;
		mov	ax, es:[di].CD_data.LD_string
		push	ax
		call	RunHeapLock_asm		; es:di <- field name
		Assert	fptr esdi

		push	si
		call	GadgetDBCheckForReservedFieldName
		jz	reservedField
		mov	cx, es
		mov	si, di			; cx:si <- field name
		mov	ax, ds:[bx].GDBI_token
		call	DataStoreDeleteField
		cmp	ax, DSSE_NO_ERROR
		clc
		je	afterMappingError
		mov_tr	cx, ax
		call	MapDataStoreStructureErrorToLegosDBError
		stc
afterMappingError:
		pop	si
		
		pop	ax
		pushf
		call	RunHeapUnlock_asm
		popf
		jc	dbError

		call	GadgetDBSuccessCommon
done:		
		ret

error:
		mov	cx, CAE_WRONG_TYPE
		call	GadgetDBActionRTECommon
		jmp	done

dbError:
		call	GadgetDBErrorCommon
		jmp	done

reservedField:
		mov	cx, GDBEC_PROTECTED_FIELD
		stc
		jmp	afterMappingError
GadgetDBActionDeleteField		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionRenameField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Renames a field

CALLED BY:	MSG_GADGET_DB_ACTION_RENAME_FIELD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionRenameField	method dynamic GadgetDBClass,
					MSG_GADGET_DB_ACTION_RENAME_FIELD
		.enter

		call	DiscardRecordCommon
		mov_tr	cx, ax
		jc	dbError

		call	GadgetDBCheckRenamable
		jz	dbError

		mov	bx, di			; ds:bx <- instance data
	;
	;  Make sure we got the 2 args, old name and new name
	;
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
	
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	error
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_STRING
		jne	error

	;
	; Check both names to make sure they are not protected fields
	; or null.  Check current name, then new name.
	;
		stc
		pushf				; plant an error
		mov	cx, DSSE_INVALID_FIELD_NAME + DSSE_TO_LEGOS_DB_ERROR
		mov	ax, es:[di].CD_data.LD_string
		mov	dx, es:[di][size ComponentData].CD_data.LD_string
		call	LockAndCheckName
		jz	unlockCurrentName
		mov_tr	ax, dx			; token of new name
		mov	dx, ds:[bx].GDBI_token
		movdw	bxsi, esdi		; bx:si <- current name

		call	LockAndCheckName	; es:di <- new name
		jz	unlockNewName
		add	sp, size word		; remove planted error
		
	;
	; Try to rename the field.
	;
		mov_tr	ax, dx			; ax <- session token
		call	DataStoreRenameField	; carry set if error
		mov_tr	cx, ax
		call	MapDataStoreStructureErrorToLegosDBError
		
		pushf
unlockNewName:
		les	di, ss:[bp].EDAA_argv
		mov	ax, es:[di][size ComponentData].CD_data.LD_string
		call	RunHeapUnlock_asm
		mov	ax, es:[di].CD_data.LD_string
unlockCurrentName:
		call	RunHeapUnlock_asm
		popf
		jc	dbError

		call	GadgetDBSuccessCommon
done:
		.leave
		ret

dbError:
		call	GadgetDBErrorCommon
		jmp	done
error:
		mov	cx, CAE_WRONG_TYPE
		call	GadgetDBActionRTECommon
		jmp	done
GadgetDBActionRenameField		endm


; Helper routine to lock a string and see if it's reserved or null.
;	Pass:	ax	- run heap token
;	Retn:	zf	- set if string (now locked) is null or reserved
;		es:di	- string
;
LockAndCheckName	proc	near
		.enter
		
		call	RunHeapLock_asm
		Assert	fptr esdi
		LocalIsNull	es:[di]
		jz	done
		call	GadgetDBCheckForReservedFieldName
done:
		.leave
		ret
LockAndCheckName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionGetField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets field data from current record

CALLED BY:	MSG_GADGET_DB_ACTION_GET_FIELD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDBActionGetField	method dynamic GadgetDBClass,
			MSG_GADGET_DB_ACTION_GET_FIELD
	;
	; If no current record, return error.
	;
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	cx, GDBEC_DATABASE_NOT_OPEN
		LONG	jz	dbError
		test	ds:[di].GDBI_flags, mask GDBF_HAVE_RECORD
		mov	cx, GDBEC_NO_CURRENT_RECORD
		LONG	jz	dbError
	;
	;  Make sure we got the field name arg
	;
		mov	bx, di			; ds:bx <- GadgetDB instance
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
	
		cmp	es:[di].CD_type, LT_TYPE_STRING
		LONG	jne	badArgs

		mov	ax, es:[di].CD_data.LD_string

	;
	; XXX - Check for Record ID field. And Timestamp?
	;
		call	MapFieldNameStringToType
		jnc	notRecordID

	;
	;  We want to return the RecordID value, so use
	;  the special DataStore API to do so.
	;
		movdw	dxax, ds:[bx].GDBI_recordID
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_LONG
		movdw	es:[di].CD_data.LD_long, dxax
		jmp	done

notRecordID:
		cmp	al, DSFT_TIMESTAMP
		jne	notTimestamp

	;
	;  Make sure we have a timestamp here
	;
		test	ds:[bx].GDBI_flags, mask GDBF_TIMESTAMP
		mov	cx, DSDE_FIELD_DOES_NOT_EXIST + DSDE_TO_LEGOS_DB_ERROR
		LONG	jz	dbError

		clr	dl			; dl <- FieldID
		jmp	haveID		

notTimestamp:
		mov	ax, es:[di].CD_data.LD_string
		push	ax
		call	RunHeapLock_asm		; es:di <- field name
		Assert	fptr esdi

		mov	ax, ds:[bx].GDBI_token
		call	DataStoreFieldNameToID
		mov	dx, ax			; dl <- field ID (or error)
		pop	ax
		pushf
		call	RunHeapUnlock_asm	; unlock field name
		popf
		mov	cx, dx			; (dl still holds field ID)
		call	MapDataStoreStructureErrorToLegosDBError
		jc	dbError

haveID:
		mov	ax, ds:[bx].GDBI_token
		push	ax, si, ds
		call	DataStoreLockRecord	; ds:si <- RecordHeader
		mov	bx, ds
		mov	di, si
		mov_tr	cx, ax			; save error, if any
		pop	ax, si, ds
		call	MapDataStoreDataErrorToLegosDBError
		jc	dbError
		
		push	si, ds
		push	ax
		mov	ds, bx
		mov	si, di
		call	DataStoreGetFieldPtr	; ds:di <- field data
						; dh = field type
						; cx = field size
		pop	bx
		jc	errorGettingFieldPtr
validField:
		mov	ax, ds			; ax:di <- field data
		pop	si, ds
		jmp	gotFieldData

	;
	; If the error is DSDE_FIELD_DOES_NOT_EXIST, then the field
	; is valid but has never been set; so return some null
	; value -- see below.  (We would have caught the
	; DSSE_INVALID_FIELD_NAME at DataStoreFieldNameToID.)
	;
errorGettingFieldPtr:
		cmp	ax, DSDE_FIELD_DOES_NOT_EXIST
		stc
		je	validField
		
		add	sp, 2 * (size word)	; fix stack
		mov_tr	cx, ax			; put error code into cx
		call	MapDataStoreDataErrorToLegosDBError
		mov_tr	ax, bx
		call	DataStoreUnlockRecord
		jmp	dbError
gotFieldData:
	;
	; ax:di - field data, 
	; cx - field size, dh - field type
	;
		push	bx			; save datastore token
	;
	; If DataStoreGetFieldPtr returned carry set, then presumably
	; the field doesn't exist, and we need to return some null
	; value of the proper type. Each of the copyDataJumpTable routines
	; will need to check the carry for this condition
	;
	;
		pushf				; save DataStoreGetFieldPtr f's
EC <		cmp	dh, DataStoreFieldType				>
EC <		ERROR_AE -1						>
		mov	bl, dh
		clr	bh
		shl	bx
		popf				;carry set if field not found
		call	cs:copyDataJumpTable[bx]

		pop	ax
		call	DataStoreUnlockRecord
done:		
		ret

badArgs:
		mov	cx, CAE_WRONG_TYPE
		call	GadgetDBActionRTECommon
		jmp	done

dbError:
		; GetField can't return error codes yet, so raise
		; a RTE instead.  See bug 59421.
		; call	GadgetDBErrorCommon
		mov	cx, CPE_SPECIFIC_PROPERTY_ERROR
		call	GadgetDBActionRTECommon
		jmp	done

GadgetDBActionGetField	endm


copyDataJumpTable	nptr	copyFloat,		; DSFT_FLOAT
				copyShort,		; DSFT_SHORT
				copyLong,		; DSFT_LONG
				copyTimestamp,		; DSFT_TIMESTAMP
				copyDate,		; DSFT_DATE
				copyTime,		; DSFT_TIME
				copyString,		; DSFT_STRING
				copyBinary,		; DSFT_BINARY
				copyBinary,		; DSFT_GRAPHIC
				copyBinary		; DSFT_INK

copyFloat:
		mov	es, ax			; es:di <- field data
		mov	ax, 0
		cwd
		jc	setFloat
		call	GadgetFloatGeos80ToIEEE32
setFloat:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_FLOAT
		movdw	es:[di].CD_data.LD_float, dxax
		retn

copyShort:
		mov	es, ax			; es:di <- field data
		mov	ax, 0
		jc	setShort
		mov	ax, es:[di]
setShort:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
		retn

copyTimestamp:
		mov	es, ax			; es:di <- field data
		mov	ax, 0
		cwd
		jc	setLong
	;
	; The datastore library stores the date as the low word, the
	; time as the high word. We wanna switch that so that straight
	; compares will work the way they're suppose to. We also want to
	; flip the sign bit so that signed comparisons work.
	;
		movdw	axdx, es:[di]
		xor	dx, 0x8000
		jmp	setLong

copyLong:
		mov	es, ax			; es:di <- field data
		mov	ax, 0
		cwd
		jc	setLong
		movdw	dxax, es:[di]
setLong:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_LONG
		movdw	es:[di].CD_data.LD_long, dxax
		retn

copyString:
	; Pass: cx - string size, including room for NULL.
	; We will add the NULL after copying the string data.
	;
		jc	nullString

		call	CopyNonNullTerminatedStringToRunHeap

		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax
		retn

nullString:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_STRING
		clr	es:[di].CD_data.LD_string
		retn
copyDate:
	;
	; Convert the DataStoreDate into a FileDate
	;
		mov	es, ax				;es:di <- data
		mov	ax, es:[di].DSD_year

		mov	cl, width FD_MONTH		; make room for month
		shl	ax, cl
		or	al, es:[di].DSD_month

		mov	cl, width FD_DAY
		shl	ax, cl
		or	al, es:[di].DSD_day

		jmp	setShort

copyTime:
	;
	; Convert the DataStoreTime into a FileTime
	;
		mov	es, ax				;es:di <- data
		mov	al, es:[di].DST_hour

		mov	cl, width FT_MIN	; make room for minutes
		shl	ax, cl
		or	al, es:[di].DST_minute

	;
	; We can only afford to store by the 2 seconds, so we need to
	; take the DST_second and half that.
	;
		mov	cl, width FT_2SEC
		shl	ax, cl
		mov	cl, es:[di].DST_second
		shr	cl		
		or	al, cl

		jmp	setShort

ifdef STRUCTS_ARE_GROOVY
copyTimestamp:
		pushf
		mov	es, ax				;es:di <- data
		mov	ax, es:[di]			;cx <- FileDate
		mov	dx, es:[di][size FileDate]	;dx <- FileTime

		les	di, ss:[bp].EDAA_runHeapInfoPtr
		mov	cx, 6
		call	DBAllocIntStruct
		popf
		jc	retStruct

		push	cx

		mov	bx, ax				;bx <- FileDate
		and	ax, mask FD_YEAR
		mov	cl, offset FD_YEAR
		shr	ax, cl
		mov	es:[di][0].LSF_value.low, ax

		mov	ax, cx
		and	ax, mask FD_MONTH
		mov	cl, offset FD_MONTH
		shr	ax, cl
		mov	es:[di][5].LSF_value.low, ax

		mov	ax, cx
		and	ax, mask FD_DAY
		mov	cl, offset FD_DAY
		shr	ax, cl
		mov	es:[di][10].LSF_value.low, ax

		mov	ax, dx
		and	ax, mask FT_HOUR
		mov	cl, offset FT_HOUR
		shr	ax, cl
		mov	es:[di][15].LSF_value.low, ax

		mov	ax, dx
		and	ax, mask FT_MIN
		mov	cl, offset FT_MIN
		shr	ax, cl
		mov	es:[di][20].LSF_value.low, ax

		mov	ax, dx
		and	ax, mask FT_2SEC
		mov	cl, offset FT_2SEC
		shr	ax, cl
		mov	es:[di][25].LSF_value.low, ax

		pop	cx				;cx <- struct token

unlockCommon:
		mov	ax, cx		
		call	RunHeapUnlock_asm

retStruct:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_STRUCT
		mov	es:[di].CD_data.LD_struct, cx
		retn

copyDate:
		pushf
		mov	es, ax				;es:di <- data

		mov	ax, es:[di].DSD_year
		mov	bh, es:[di].DSD_month
		mov	bl, es:[di].DSD_day

		les	di, ss:[bp].EDAA_runHeapInfoPtr
		mov	cx, 3
		call	DBAllocIntStruct
		popf
		jc	retStruct

		mov	es:[di][0].LSF_value.low, ax

		clr	ah
		mov	al, bh
		mov	es:[di][5].LSF_value.low, ax

		mov	al, bl
		mov	es:[di][10].LSF_value.low, ax
		jmp	unlockCommon

copyTime:
		pushf
		mov	es, ax				;es:di <- data

		mov	al, es:[di].DST_hour
		mov	bh, es:[di].DST_minute
		mov	bl, es:[di].DST_second

		les	di, ss:[bp].EDAA_runHeapInfoPtr
		mov	cx, 3
		call	DBAllocIntStruct
		popf
		jc	retStruct

		clr	ah
		mov	es:[di][0].LSF_value.low, ax

		mov	al, bh
		mov	es:[di][5].LSF_value.low, ax

		mov	al, bl
		mov	es:[di][10].LSF_value.low, ax
		jmp	unlockCommon
endif

copyBinary:
		jc	nullComplex

	;
	; The way things are being made to work today, a DSFT_BINARY will
	; only contain a LegosComplex structure, with the LC_vmfh field
	; "blanked" out (with LC_SIGNATURE in place of an actual VM
	; file handle), and with an LC_chain field that corresponds to
	; some VM file which is accessed by the the name of the database
	; with " (complex)" stuck on. Eg. "mydb (complex)"
	;

	;
	; check for sig.
	;
		mov	es, ax
		cmp	es:[di].LC_vmfh, LC_SIGNATURE
		jne	nullComplex

		call	ClipboardGetClipboardFile
		mov	dx, bx				; dx <- clipboard file

		mov	ah, VMO_OPEN
		call	OpenAssociatedVMFile		;bx <- vm file
		jc	nullComplex

		push	bp
		movdw	axbp, es:[di].LC_chain		;bx:ax:bp <- source
		call	VMCopyVMChain			;dx:ax:bp <- new

		push	ax
		mov	al, FILE_NO_ERRORS
		call	VMClose
		pop	ax

	;
	; We can't shove the new values into the LC at es:di, 'cause
	; they'll end up in the database (?!) that way.
	;
		movdw	bxcx, es:[di].LC_format		;bx:ax:bp <- source

		sub	sp, size LegosComplex
		mov	di, sp

		mov	ss:[di].LC_vmfh, dx
		movdw	ss:[di].LC_chain, axbp
		movdw	ss:[di].LC_format, bxcx
		
		mov	ax, ss				;ax:di <- new LC
		mov	bx, RHT_COMPLEX
		mov	dl, 1			;FIXME: initial ref count...?
		mov	cx, size LegosComplex
		call	RunHeapAlloc_asm
		add	sp, size LegosComplex
		pop	bp

setComplex:

		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_COMPLEX
		mov	es:[di].CD_data.LD_complex, ax
		retn
nullComplex:
		clr	ax
		jmp	setComplex
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenAssociatedVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the VM file handle for the file associated
		with the database going by the name of *ds:si.GDBI_name

PASS:		*ds:si - instance data
		ah - mode to pass to VMOpen, one of:
		    VMO_CREATE -  Set to create a new file if none exists, else
		    	the existing file is opened.
		    VMO_OPEN - Open existing VM file.

		VMO_CREATE will likely be passed in the "PutField" case, and
		VMO_OPEN will likely be passed in the "GetField" case.

RETURN:		carry set or error, else
		carry clear and bx = vm file handle. you should call
		VMClose(bx) when you're done with the thing.

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 july 96	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenAssociatedVMFile	proc	near
	uses	es, di, ax, cx, dx
	class	GadgetDBClass
	.enter

	;
	; Get the name of the file, presuming the extension for the
	; VM file follows the trailing null,
	; eg. "filename\000(complex)\000".
	;
		push	ax				;save VMOpen mode

		call	FilePushDir
		mov	ax, SP_DOCUMENT		
		call	FileSetStandardPath

		mov	di, ds:[si]
		add	di, ds:[di].GadgetDB_offset
		mov	di, ds:[di].GDBI_name
		tst	di
		jz	error
		mov	dx, ds:[di]
		call	DBName2VMName

	;
	; Go ahead 'n try to open the thing.
	;
		pop	ax				;ah <- VMOpen mode
		clr	al				;default access
		clr	cx

		call	VMOpen
		mov	{TCHAR}ds:[di], C_NULL

		pushf					;save error from VM
		call	FilePopDir
		popf

done:
	.leave
	ret

error:
		pop	ax
		stc
		jmp	done
OpenAssociatedVMFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBName2VMName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a string that looks like "string1\000string2"
		into "string1_string2", for use in accessing the VM
		file associated with a database.

PASS:		ds:dx = "string1\000string2"

RETURN:		ds:dx = "string1_string2"
		ds:di = pointing at the underscore so you can fix it up

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 july 96	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBName2VMName	proc	near
	uses	es, ax, cx
	.enter

	;
	; Locate the null and replace it with an underscore
	;
	segmov	es, ds
	mov	di, dx				;es:di <- name
	clr	ax, cx
	dec	cx
SBCS<	repne scasb			>
DBCS<	repne scasw			>
	dec	di
DBCS<	dec	di			>
	mov	{TCHAR}es:[di], C_UNDERSCORE

	.leave
	ret
DBName2VMName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		String2DBName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the passed string that looks like "string1\000string2"
		into "string1_string2", for use in accessing the VM
		file associated with a database.

PASS:		ax - run heap token of string1
		ds = object block

RETURN:		ax = block in object block containing the new string + ext.

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 july 96	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
String2DBName	proc	near
	uses	bx, cx, dx, di, si, es
	.enter

		push	ax

		mov	bx, handle Strings
		call	MemLock
		mov	es, ax
		mov	di, offset VMString
		mov	di, es:[di]
		call	LocalStringSize

		inc	cx			; add the NULL
DBCS <		inc	cx						>

		pop	ax
		push	ax			; save our new token
		pushdw	esdi			; save VMString ptr
		call	RunHeapLock_asm		; es:di <- datastore name
		Assert	fptr esdi
	
		mov	dx, cx			; dx <- size "(complex)"
		call	LocalStringSize
		inc	cx			; add the NULL
DBCS <		inc	cx						>
		add	cx, dx
		clr	al
		call	LMemAlloc
		sub	cx, dx

		segxchg	ds, es, si
		mov	si, di			; ds:si <- database name
		mov	di, ax
		mov	di, es:[di]		; es:di <- destination
		rep	movsb

	;
	; Tack on a "(complex)" at the end here so's we can use it
	; to access the associated VM file, if any. We'll keep the
	; null after the proper filename in place, and change it to
	; a space as needed.
	;
		popdw	dssi			; ds:si <- VMString
		mov	cx, dx			; cx <- # bytes in "(complex)"
		rep movsb

		call	MemUnlock

		segmov	ds, es
		mov_tr	bx, ax			; bx <- new chunk
		pop	ax
		call	RunHeapUnlock_asm

		mov_tr	ax, bx			; ax <- new chunk
	.leave
	ret
String2DBName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteAssociatedVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the VM file handle for the file associated
		with the database going by the name of *ds:si.GDBI_name

PASS:		*ds:ax - filename

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 july 96	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteAssociatedVMFile	proc	near
	uses	es, di, ax, cx, dx
	.enter

	;
	; Get the name of the file, presuming the extension for the
	; VM file follows the trailing null,
	; eg. "filename\000(complex)\000".
	;
		tst	ax
		jz	done
		mov_tr	di, ax		

		call	FilePushDir
		mov	ax, SP_DOCUMENT		
		call	FileSetStandardPath

		mov	dx, ds:[di]			;ds:dx <- name
		call	DBName2VMName

	;
	; Go ahead 'n try to delete the thing.
	;
		call	FileDelete
		mov	{TCHAR}ds:[di], C_NULL

		call	FilePopDir

done:
	.leave
	ret
DeleteAssociatedVMFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RenameAssociatedVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Renames the VM file handle for the file associated
		with the database.

PASS:		*ds:ax - old name
 	 	*ds:bx - new name

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 july 96	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RenameAssociatedVMFile	proc	near
	uses	es, di, ax, cx, dx
	.enter

	tst	ax
	jz	done	

	;
	; Get the name of the file, presuming the extension for the
	; VM file follows the trailing null,
	; eg. "filename\000(complex)\000".
	;
		
		mov_tr	di, ax				;di <- old name

		call	FilePushDir
		mov	ax, SP_DOCUMENT		
		call	FileSetStandardPath

		mov	dx, ds:[bx]
		mov_tr	ax, di				;ax <- old name
		call	DBName2VMName			;ds:dx <- new name
		push	di				;save for restore

		mov_tr	di, ax
		mov_tr	ax, dx				;ds:ax <- new name
		mov	dx, ds:[di]
		call	DBName2VMName			;ds:dx <- old name

		segmov	es, ds
		mov_tr	di, ax				;es:di <- new name
		call	FileRename

		pop	di
		mov	{TCHAR}ds:[di], C_NULL

		call	FilePopDir

done:
	.leave
	ret
RenameAssociatedVMFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionPutField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets field data in current record

CALLED BY:	MSG_GADGET_DB_ACTION_PUT_FIELD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		EDAA_retval filled in
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/3/95		Initial version
	jmagasin 8/21/96	Handle nulling out of a field.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComplexBinaryHeader	struct
	CBH_signature	word
	CBH_isDB	word
	CBH_format	ClipboardItemFormatID
ComplexBinaryHeader	ends

LC_SIGNATURE	equ	0xbeef

GadgetDBActionPutField	method dynamic GadgetDBClass,
			MSG_GADGET_DB_ACTION_PUT_FIELD
	.enter
	
	;
	; If no db open, or db is read-only, or no current record,
	; return error.
	;
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	cx, GDBEC_DATABASE_NOT_OPEN
		jz	dbError
		test	ds:[di].GDBI_flags, mask GDBF_OPEN_READ_WRITE
		mov	cx, DSE_ACCESS_DENIED
		jz	dbError
		test	ds:[di].GDBI_flags, mask GDBF_HAVE_RECORD
		mov	cx, GDBEC_NO_CURRENT_RECORD
		jz	dbError
	;
	;  Make sure we got the field name arg
	;
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
	
		cmp	es:[di].CD_type, LT_TYPE_STRING
		je	continue
		mov	cx, CAE_WRONG_TYPE
error:
		call	GadgetDBActionRTECommon
done:
		.leave
		ret

dbError:
		call	GadgetDBErrorCommon
		jmp	done
propError:
		mov	cx, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	error
		
continue:
		mov	bx, ds:[si]
		add	bx, ds:[bx].GadgetDB_offset
		mov	dx, ds:[bx].GDBI_token

	;
	; Set ourselves modified.  No harm abort if before actual setField.
	;
		BitSet	ds:[bx].GDBI_flags, GDBF_RECORD_MODIFIED
		
	;
	; XXX - check for RecordID field
	;
		mov	ax, es:[di].CD_data.LD_string
		call	MapFieldNameStringToType
ifdef CAN_PUT_A_RECORDID
		jc	isRecordID
else
		mov	cx, GDBEC_PROTECTED_FIELD
		jc	dbError
endif
	;
	; FIXME: need to differentiate between any old DSFT_TIMESTAMP field
	; and *the* DSFT_TIMESTAMP field
	;
		cmp	al, DSFT_TIMESTAMP
		jne	notSpecial
		
ifdef CAN_PUT_TIMESTAMP
	;
	; We're setting the timestamp.
	;

		test	ds:[bx].GDBI_flags, mask GDBF_TIMESTAMP
		mov	cx, GDBEC_PROTECTED_FIELD
		jz	dbError

		mov_tr	ax, dx				;ax <- token
		
	;
	; The datastore library stores the date as the low word, the
	; time as the high word. We wanna switch that so that straight
	; compares will work the way they're suppose to. We also need to
	; flip the very highest bit for the same reason.
	;
		
		mov	dx, es:[di][size ComponentData].CD_data.LD_long.high
		xor	dx, 0x8000
		mov	bx, es:[di][size ComponentData].CD_data.LD_long.low

		sub	sp, size FileDateAndTime
		mov	di, sp

		mov	es:[di].FDAT_date, dx
		mov	es:[di].FDAT_time, bx
		
		clr	bx				;use field id
		clr	dl				;timestamp is first
		mov	cx, size FileDateAndTime
		call	DataStoreSetField
		mov_tr	cx, ax
		call	MapDataStoreDataErrorToLegosDBError

		lahf
		add	sp, size FileDateAndTime
		sahf
	;
	; Switch 'em back for safety's sake.
	;
		jmp	checkErrorNoPop
else	; if can put TIMESTAMP
		mov	cx, GDBEC_PROTECTED_FIELD
		jmp	dbError
endif		
		
ifdef CAN_PUT_A_RECORDID
isRecordID:
		mov	cx, dx				;cx <- token
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_LONG
		jne	checkInt
		mov	dx, es:[di][size ComponentData].CD_data.LD_long.high
		mov	ax, es:[di][size ComponentData].CD_data.LD_long.low
		jmp	haveRecordID

checkInt:
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_INTEGER
		jne	propError
		mov	ax, es:[di][size ComponentData].CD_data.LD_integer
		cwd

haveRecordID:
		xchg	ax, cx				;ax <- token,
							;cx <- low word
		call	DataStoreSetRecordID
		mov_tr	cx, ax
		call	MapDataStoreDataErrorToLegosDBError
		CheckHack <DSE_NO_ERROR eq 0>
		cmp	cx, DSE_NO_ERROR+1
		cmc
		jmp	checkErrorNoPop
endif

notSpecial:
	;
	;  Let's get the type of the field, just in case we need to
	;  know about it for the purposes of locking the data.
	;
		pushdw	esdi
		push	dx			;save token
		mov	ax, es:[di].CD_data.LD_string
		push	ax			;save name for unlock
		call	RunHeapLock_asm		; es:di <- field name
		Assert	fptr esdi

		mov	ax, dx			; ax <- token
		call	DataStoreFieldNameToID	; al <- FieldID
		jc	fieldErrorInNotSpecial

		sub	sp, size FieldDescriptor +1
		mov	di, sp
		xchg	ax, dx			;ax <- token,
						;dl <- field id
		segmov	es, ss
		clr	cx			; don't get field name
		movdw	es:[di].FD_name, cxcx	; (Just to be tidy.)
		call	DataStoreGetFieldInfo
		jnc	gotFieldInfo

		add	sp, size FieldDescriptor +1
fieldErrorInNotSpecial:
		mov_tr	cx, ax
		call	MapDataStoreStructureErrorToLegosDBError
		pop	ax
		call	RunHeapUnlock_asm
		add	sp, 3 * (size word)	; fix stack
		jmp	dbError

gotFieldInfo:
		mov	cl, es:[di].FD_data.FD_type ;cl <- DataStoreFieldType
		add	sp, size FieldDescriptor +1
		pop	ax
		call	RunHeapUnlock_asm
		mov_tr	ax, si			;ax <- obj chunk (for complex)
		pop	si			;si <- datastore token
		popdw	esdi

		mov	bx, es:[di][size ComponentData].CD_type
		cmp	bx, LT_TYPE_COMPLEX
		je	lockComplex

	;
	; They say structs should *never* make it into a database.
	; - jon 28 may 96
	;
		cmp	bx, LT_TYPE_STRUCT
		LONG	je	propError

		cmp	bx, LT_TYPE_COMPONENT
		LONG	jae	propError

		shl	bx

		jmp	cs:lockDataJumpTable[bx]

clearField:
	;
	; We'll get here if asked to set a field to 0 or null.  Note
	; that a null complex is handled specially in lockComplex,
	; which will jump to setField.  Note that we ignore "field
	; does not exist" error because we'll get that if we null
	; out a field that has never been set.  We'll get "invalid
	; field name" if there is no such field defined for the DB.
	; Pass: dl	- FieldID
	;	si	- DataStore token
	;
		mov_tr	ax, si
		clr	cx			; use FieldID
		call	DataStoreRemoveFieldFromRecord
		mov_tr	cx, ax
		cmp	cx, DSDE_FIELD_DOES_NOT_EXIST
		jne	haveClearFieldError
		CheckHack <DSE_NO_ERROR eq 0>
		clr	cx
haveClearFieldError:
		call	MapDataStoreDataErrorToLegosDBError
		CheckHack <DSE_NO_ERROR eq 0>
		cmp	cx, DSE_NO_ERROR+1
		cmc
		jmp	checkErrorNoPop		; (nothing to unlock)

setField:
	;
	; Set the current record's field to nonzero/nonnull.
	; Pass: es:di	- data
	;	cx	- size of data
	;	dl	- FieldID
	;	si	- DataStore token
	;
		push	bx			; save bx just in case it's
						; the block we allocated
						; to copy the complex to

		mov_tr	ax, si
		clr	bx			; use FieldID
		call	DataStoreSetField
		pop	bx			;bx <- new block (if complex)

		mov_tr	cx, ax
		call	MapDataStoreDataErrorToLegosDBError
		CheckHack <DSE_NO_ERROR eq 0>
		cmp	cx, DSE_NO_ERROR+1
		cmc

	;
	; Unlock field name
	;
		push	cx			; save error code
		pushf				; cf=1 if error
		les	di, ss:[bp].EDAA_argv
		mov	cx, es:[di][size ComponentData].CD_type
		cmp	cx, LT_TYPE_COMPLEX
		LONG	je	unlockComplex
		cmp	cx, LT_TYPE_STRING
		LONG	je	unlockString
ifdef STRUCTS_ARE_GROOVY
		cmp	cx, LT_TYPE_STRUCT
		LONG	je	unlockStruct
endif
		cmp	cx, LT_TYPE_FLOAT
		LONG	je	unlockFloat
		cmp	cx, LT_TYPE_INTEGER
		LONG	je	unlockInteger

checkError:
		popf
		pop	cx
checkErrorNoPop:
		LONG	jc	dbError

		call	GadgetDBSuccessCommon
		LONG	jmp	done

ifdef STRUCTS_ARE_GROOVY
lockStruct:
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_STRUCT
		jne	propError
		mov	ax, es:[di][size ComponentData].CD_data.LD_struct
		cmp	cl, DSFT_DATE
		je	lockDate

	;
	; Must be a time
	;
		call	RunHeapLock_asm
		mov	bx, di

		sub	sp, size DataStoreDate		;we'll use the
							;larger of DSD and
							;DST so that we can
							;just pop a DSD after
		mov	di, sp
		mov	cx, es:[bx][0].LSF_value.low	; ax <- hours
		mov	ss:[di].DST_hour, cl
		mov	cx, es:[bx][5].LSF_value.low	; ax <- minutes
		mov	ss:[di].DST_minute, cl
		mov	cx, es:[bx][10].LSF_value.low	; ax <- seconds
		mov	ss:[di].DST_second, cl

		call	RunHeapUnlock_asm
		segmov	es, ss
		mov	cx, size DataStoreTime
		jmp	setField

lockDate:
		call	RunHeapLock_asm
		mov	bx, di

		sub	sp, size DataStoreDate
		mov	di, sp
		mov	cx, es:[bx][0].LSF_value.low	; ax <- year
		mov	ss:[di].DSD_year, cx
		mov	cx, es:[bx][5].LSF_value.low	; ax <- month
		mov	ss:[di].DSD_month, cl
		mov	cx, es:[bx][10].LSF_value.low	; ax <- day
		mov	ss:[di].DSD_day, cl

		call	RunHeapUnlock_asm
		segmov	es, ss
		mov	cx, size DataStoreDate
		jmp	setField
endif

lockComplex:
		push	si
		mov_tr	si, ax
		mov	ah, VMO_CREATE
		call	OpenAssociatedVMFile
		pop	si
		mov	cx, GDBEC_PUT_ERROR
		LONG	jc	dbError

		push	dx				;save field id.
		push	bp				;save locals
	;
	; If there's already a complex sitting in there, we need to
	; clear it out now.
	;
	; ACTUALLY, there's a problem with doing this: if this record
	; is never saved, then this chain would need to be retrieved,
	; since the original record would still be pointing at it.
	; I'm not in the mood for some complicated fix, so I'm if'ing
	; this code out to preserve the chain. This will cause db's
	; to become quite large as chains are overwritten by chains.
	; Oh well.
	;		- jon 14 aug 96
	;
if 0
		push	ds, si, di
		mov	ax, si
		push	ax
		call	DataStoreLockRecord
		jnc	lockSucceeded
		add	sp, size word			; undo push ax
		jmp	afterRecordUnlock
lockSucceeded:
		call	DataStoreGetFieldPtr
		jc	unlockRecord

EC<		pushf					>
EC<		cmp	cx, size LegosComplex		>
EC<		ERROR_NE -1				>
EC<		cmp	dh, DSFT_BINARY			>
EC<		ERROR_B -1				>
EC <		cmp	dh, DSFT_INK					>
EC <		ERROR_A -1						>
EC <		popf							>


		movdw	axbp, ds:[di].LC_chain

		call	VMFreeVMChain

unlockRecord:
		pop	ax
		call	DataStoreUnlockRecord
afterRecordUnlock:
		pop	ds, si, di

endif

		mov	ax, es:[di][size ComponentData].CD_data.LD_complex
		tst	ax
		jnz	copyComplex
	;
	; We're storing a null complex. For now, we'll just store a
	; LegosComplex worth of zero's, so that when GetField comes along
	; and doesn't see an LC_SIGNATURE there, it'll just return null
	;
		mov	cx, size LegosComplex
		sub	sp, cx
		mov	di, sp				;ss:di <- new LC
		segmov	es, ss				;es:di <- new LC
		clr	al
		rep stosb
		mov	di, sp				;ss:di <- new LC
		jmp	afterCopyComplex

copyComplex:

		push	ax
		call	RunHeapLock_asm
		mov	dx, bx				;dx <- database VM file
		mov	bx, es:[di].LC_vmfh
		movdw	axbp, es:[di].LC_chain

		call	VMCopyVMChain			;dx:ax:bp <- new stuff

		pop	cx				;cx <- run heap token
		sub	sp, size LegosComplex
		mov	bx, di				;es:bx <- old LC
		mov	di, sp				;ss:di <- new LC

		mov	ss:[di].LC_vmfh, LC_SIGNATURE
		movdw	ss:[di].LC_chain, axbp
		movdw	axbp, es:[bx].LC_format
		movdw	ss:[di].LC_format, axbp

		mov_tr	ax, cx				;ax <- run heap token
		call	 RunHeapUnlock_asm

		mov	bx, dx
afterCopyComplex:
		mov	al, FILE_NO_ERRORS
		call	VMClose

		mov	cx, size LegosComplex
		segmov	es, ss				;es:di <- new LC

	;
	; This is kind of gross, but I need to pop dx and bp from
	; before altering the stack pointer, and there's no damn
	; free registers....
	;
		mov	bp, sp
		mov	dx, ss:[bp][size LegosComplex + 2]
		mov	bp, ss:[bp][size LegosComplex]
		jmp	setField

unlockComplex:
		pop	ax				;ax <- flags
		add	sp, size LegosComplex + 4
		push	ax
		jmp	checkError
unlockString:
		mov	ax, es:[di][size ComponentData].CD_data.LD_string
		call	RunHeapUnlock_asm
		jmp	checkError
ifdef STRUCTS_ARE_GROOVY
unlockStruct:
		pop	ax				;ax <- flags
		add	sp, size DataStoreDate
		push	ax
		jmp	checkError
endif
unlockInteger:
		pop	ax				;ax <- flags
		add	sp, size DataStoreDate
		push	ax
		jmp	checkError
unlockFloat:
		pop	ax				;ax <- flags
		add	sp, size FloatNum
		push	ax
		jmp	checkError
		

lockDataJumpTable	nptr	lockError,		; LT_TYPE_UNKNOWN
				lockFloat,		; LT_TYPE_FLOAT
				lockInteger,		; LT_TYPE_INTEGER
				lockLong,		; LT_TYPE_LONG
				lockString		; LT_TYPE_STRING

lockError:
		ERROR -1					

lockFloat:
		mov	bl, dl				; bl <- FieldID

		mov	dx, es:[di][size ComponentData].CD_data.LD_float.high
		mov	ax, es:[di][size ComponentData].CD_data.LD_float.low

		tstdw	dxax
		jnz	haveNonZeroFloat
		mov	dl, bl				;dl <- FieldID
		jmp	clearField

haveNonZeroFloat:
		sub	sp, size FloatNum
		mov	di, sp
		segmov	es, ss

		call	GadgetFloatIEEE32ToGeos80

		mov	dl, bl				;dl <- FieldID
		mov	cx, size FloatNum
		jmp	setField
	
lockLong:
		lea	di, es:[di][size ComponentData].CD_data.LD_long

		tstdw	es:[di]
		LONG	jz	clearField
		
		mov	cx, size dword
		jmp	setField

lockInteger:
	;
	; If DataStoreFieldType is either DSFT_DATE or DSFT_TIME, we need to
	; do the convertion from LT_INTEGER (FileDate or FileTime) to
	; DataStoreDate or DataStoreTime. To make things simpler when it
	; comes time to free the structure from the stack once we're done
	; with it, I'm going to carve a DataStoreDate off the stack for
	; *any integer*.
	;

		mov	ax, es:[di][size ComponentData].CD_data.LD_integer
		tst	ax
		LONG	jz	clearField
		
		sub	sp, size DataStoreDate

		cmp	cl, DSFT_DATE
		je	lockDate
		cmp	cl, DSFT_TIME
		je	lockTime
		lea	di, es:[di][size ComponentData].CD_data.LD_integer
		mov	cx, size word
		jmp	setField

lockDate:
		; ax already has integer
		mov	di, sp
		
		push	ax
		andnf	ax, mask FD_YEAR
		mov	cl, offset FD_YEAR
		shr	ax, cl
		mov	ss:[di].DSD_year, ax
		pop	ax

		push	ax
		andnf	ax, mask FD_MONTH
		mov	cl, offset FD_MONTH
		shr	ax, cl
		mov	ss:[di].DSD_month, al
		pop	ax

		andnf	ax, mask FD_DAY
		mov	ss:[di].DSD_day, al

		segmov	es, ss
		mov	cx, size DataStoreDate
		jmp	setField

lockTime:
		; ax already has integer
		mov	di, sp
		
		push	ax
		andnf	ax, mask FT_HOUR
		mov	cl, offset FT_HOUR
		shr	ax, cl
		mov	ss:[di].DST_hour, al
		pop	ax

		push	ax
		andnf	ax, mask FT_MIN
		mov	cl, offset FT_MIN
		shr	ax, cl
		mov	ss:[di].DST_minute, al
		pop	ax

		andnf	ax, mask FT_2SEC
		shl	al
		mov	ss:[di].DST_second, al

		segmov	es, ss
		mov	cx, size DataStoreTime
		jmp	setField

lockString:
		mov	ax, es:[di][size ComponentData].CD_data.LD_string
		tst	ax
		LONG	jz	clearField
		call	RunHeapLock_asm
		call	LocalStringSize
		jcxz	unlockNullString
		jmp	setField
unlockNullString:
		call	RunHeapUnlock_asm
		jmp	clearField

GadgetDBActionPutField		endm




ifdef STRUCTS_ARE_GROOVY
; PASS:		ax - struct token
;		cx - nonzero to get date
;		dx - nonzero to get time
;		
; RETURN:	cx - date
;		dx - time
GetDateAndTimeFromStruct	proc	near
		uses	ax, bx, di
		.enter

		push	ax
		call	RunHeapLock_asm

		clr	bx
		jcxz	setTime

	;
	; Set ch:dl:dh assuming es:di is a struct DateTime
	;

		mov	ax, es:[di][0].LSF_value.low	; ax <- year
		mov	cl, width FD_MONTH		; make room for month
		shl	ax, cl

		or	ax, es:[di][5].LSF_value.low	; OR in the month
		mov	cl, width FD_DAY
		shl	ax, cl

		or	ax, es:[di][10].LSF_value.low	; OR in the day

		tst	dx
		jz	done

		mov	bx, 15

setTime:
	;
	; Now we do the time
	;		
		mov	dx, es:[di][bx].LSF_value.low	; dx <- hour
		mov	cl, width FT_MIN		; make room for min
		shl	dx, cl

		add	bx, 5
		or	dx, es:[di][bx].LSF_value.low	; OR in the month
		mov	cl, width FT_2SEC
		shl	dx, cl

		add	bx, 5
		or	dx, es:[di][bx].LSF_value.low	; OR in the secs

done:
		mov_tr	cx, ax

		pop	ax
		call	RunHeapUnlock_asm

		.leave
		ret
GetDateAndTimeFromStruct	endp
endif


;
; This code has been copied from the math library so that we don't
; have to deal with initiailizing an fp stack, etc.
;
; PASS: es:di = FloatNum
; RETURN: dxax = IEEE32 number
;
GadgetFloatGeos80ToIEEE32	proc	far
	uses	bx, cx
	.enter

	mov	ax, es:[di].F_exponent
	mov	dx, ax
	and	dx, 0x8000
	and	ax, 0x7fff
	tst	ax
	jz	doZero

	or	ax, dx
	sub	ax, 0x3fff
	add	ax, 0x7f
	and	ax, 0xff

	mov	cl, 7
	shl	ax, cl
	or	ax, dx
	push	ax		; save exponent
	mov	ax, es:[di].F_mantissa_wd3
	mov	dx, ax			; save for later
	mov	cl, 8
	shr	ax, cl
	and	ax, 0xff7f		; turn off implicit one
	pop	bx
	or	ax, bx
	push	ax			; save high word
	and	dx, 0x00ff	
	shl	dx, cl
	mov	ax, es:[di].F_mantissa_wd2

	and	ax, 0xff00
	shr	ax, cl
	or	ax, dx
	pop	dx			; dx:ax = real
	jmp	done
doZero:
	clr	ax, dx
done:
	.leave
	ret
GadgetFloatGeos80ToIEEE32	endp

GadgetFloatIEEE32ToGeos80	proc	far
	uses	bx, cx
	.enter
	mov_tr	bx, ax
	mov	ax, dx
	or	dx, bx
	jz	pushZero
	push	ax			; original dx (half with exponent)
	push	bx			; original ax 
	mov	cl, 8
	shl	ax, cl
	or	ax, 0x8000		; turn on implicit 1
	shr	bx, cl
	or	ax, bx
	mov	es:[di].F_mantissa_wd3, ax
	pop	dx			; original ax
	shl	dx, cl
	mov	es:[di].F_mantissa_wd2, dx
	mov	es:[di].F_mantissa_wd1, 0
	mov	es:[di].F_mantissa_wd0, 0
	
	pop	cx			; original dx
	mov	ax, cx
	mov	dx, cx
	and	dx, 0x8000			; get sign bit
	and	ax, 0x7f80
	mov	cl, 7
	shr	ax, cl
	tst	ax
	jz	doZero
	sub	ax, 0x7f
	add	ax, 0x3fff
	or	ax, dx
	jmp	cont
doZero:
	clr	ax
cont:
	mov	es:[di].F_exponent, ax
done:
	.leave
	ret
pushZero:
	push	di
	clr	ax
	mov	cx, size FloatNum / size word
	rep stosw
	pop	di
	jmp	done
GadgetFloatIEEE32ToGeos80	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCActionSearchString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a string

CALLED BY:	MSG_GADGET_DB_ACTION_SEARCH_STRING
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 1/96		Initial version
	jmagasin 8/30/96	Broke out subroutines, added handling
				for error codes.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SearchStringStatus	etype byte
	SSS_NONE	enum	SearchStringStatus
	SSS_ABORTED	enum	SearchStringStatus
	SSS_FOUND	enum	SearchStringStatus

SearchStringSearchRoutine	etype	byte, 0, 1
	SSSR_WILD_WILD	enum	SearchStringSearchRoutine
		; TextSearchInString for string of form "*ABC*"
	SSSR_END_WILD	enum	SearchStringSearchRoutine
		; Find string of form "ABC*"
	SSSR_START_WILD	enum	SearchStringSearchRoutine
		; Find string of form "*ABC"
	SSSR_EXACT	enum	SearchStringSearchRoutine
		; Find exact match for "ABC"

SearchStringParams	struct
	SSP_token		word
	SSP_status		SearchStringStatus
	SSP_origSearchFlags	word
	SSP_searchRoutine	SearchStringSearchRoutine
	SSP_searchParams	SearchParams
	align word
SearchStringParams	ends

GadgetDBActionSearchString		method dynamic GadgetDBClass,
					MSG_GADGET_DB_ACTION_SEARCH_STRING
		uses	cx, dx, bp
		.enter

		movdw	dxcx, ds:[di].GDBI_recordNum

	;
	; If no open datastore, return error
	;
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	ax, GDBEC_DATABASE_NOT_OPEN
		LONG	jz	recordError

	;
	;  Make sure we got all the args
	;
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
		call	CheckSearchStringArgs
		jz	everythingChecks

		mov	cx, CAE_WRONG_TYPE
		call	GadgetDBActionRTECommon
		jmp	done

everythingChecks:
		clr	al
		cmpdw	dxcx, GDB_RECORDNUM_FOR_NO_RECORD
		jne	haveStart

	;
	;  Since there's no current record, we need to start at the end.
	;
		mov	al, mask SF_START_AT_END
haveStart:
		sub	sp, size SearchStringParams
		mov	bx, sp				; ss:bx <- params
	;
	; Set the start record and max records. If max records = 0,
	; start at end.
	;
		movdw	ss:[bx].SSP_searchParams.SP_startRecord, dxcx
		mov	dl, al				; dl <- flags
		call	ValidateMaxRecords		; ax <- maxRecords
		tst	ax
		jnz	haveMax
		dec	ax
haveMax:
		push	dx
		cwd
		movdw	ss:[bx].SSP_searchParams.SP_maxRecords, dxax
		pop	dx

	;
	; Get SearchFlags and field name.
	;
		call	GetSearchStringFlags		; dl <- flags
		mov	cx, DSE_INVALID_FLAGS
		LONG	jc	dbErrorNukeSearchParams
		mov	ss:[bx].SSP_searchParams.SP_flags, dl
		call	GetSearchStringFieldName	; cx <- token or error
		LONG	jc	dbErrorNukeSearchParams

	;
	; Copy match string to global heap, then unlock the passed
	; string on the run heap.  The "mov dx" is needed only if
	; DoSearchString is used; DataStoreStringSearch doesn't need it.
	;
		mov	dx, es:[di][size ComponentData*2].CD_data.LD_integer
		mov	ss:[bx].SSP_origSearchFlags, dx
		call	CopySearchString
		jc	dbErrorNukeSearchParams
		movdw	ss:[bx].SSP_searchParams.SP_searchString, esdi

	;
	; Do the search.
	;
		mov	ax, cx				; ax <- token
		segmov	es, ss, di
		mov	di, bx
		call	DoSearchString			; ax <- error
		pushf
		jnc	doneSearch

	;
	; Something went wrong.  See if we should continue.
	;
		call	HandleFirstSearchFailed		; dxax <- rec count
		jc	popfRecordError
		jz	doneSearch

	;
	; Figure out how many records we'll search in our second search.
	;
		call	FigureOutNumRecordsForSecondSearch
		jc	popfRecordError

	;
	; Do the second search.
	;
		BitSet	es:[di].SSP_searchParams.SP_flags, SF_START_AT_END
		movdw	es:[di].SSP_searchParams.SP_maxRecords, dxax
		mov_tr	ax, cx
		add	sp, size word		; forget old results (pushf'd)
		call	DoSearchString
		pushf
		jc	secondSearchFailed
doneSearch:
		popf
	;
	; Clear the stack and free the block containing match string
	;
		mov	cx, ax			; dx.cx <- matching record
		lahf
		call	FreeSearchString
		add	sp, size SearchStringParams
		sahf
		mov	ax, cx
		jc	recordError

	;
	; Success! Make this (dx.cx) the current record.
	;
		call	DiscardRecordCommon
		jc	recordError
		mov	di, ds:[si]
		add	di, ds:[di].GadgetDB_offset
		movdw	ds:[di].GDBI_recordNum, dxcx
		mov	ax, ds:[di].GDBI_token
		call	DataStoreLoadRecordNum
		jc	recordError
		movdw	ds:[di].GDBI_recordID, dxcx
		BitSet	ds:[di].GDBI_flags, GDBF_HAVE_RECORD

		call	GadgetDBSuccessCommon

done:
		.leave
		ret

dbErrorNukeSearchParams:
	;
	; Drop SearchParams and handle error.
	;
		add	sp, size SearchStringParams
		mov_tr	ax, cx
		jmp	recordError

secondSearchFailed:
		call	HandleSecondSearchFailed

	;
	; DataStoreError passed to popfRecordError in ax,
	;
popfRecordError:
		call	FreeSearchString
		add	sp, size SearchStringParams + (size word)
		call	FindCurrentRecordNumberAfterSearchString
		mov_tr	cx, ax
		jmp	recordError2
		
recordError:
		mov_tr	cx, ax
		call	DiscardChangesToCurrentRecord
recordError2:
		call	SwitchNoRecordFoundErrorsHack
		call	GadgetDBErrorCommon
		jmp	done
GadgetDBActionSearchString		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSearchStringArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure SearchString args are okay.  Routine
		provided just for clarity since GadgetDBAction
		SearchString is too long.

CALLED BY:	GadgetDBActionSearchString
actionPASS:		es:di	- arguments to SearchString
RETURN:		zf	- set if args are legal
			  clear if RTE should be raised
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckSearchStringArgs	proc	near
		.enter

		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	done
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_STRING
		jne	done
		cmp	es:[di][size ComponentData*2].CD_type, LT_TYPE_INTEGER
		jne	done
		cmp	es:[di][size ComponentData*3].CD_type, LT_TYPE_INTEGER
done:
		.leave
		ret
CheckSearchStringArgs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSearchStringFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the passed SearchString flags and convert them
		into DataStore SearchFlags.  This helper routine is
		provided for clarity since GadgetDBActionSearchString
		is too long.

CALLED BY:	GadgetDBActionSearchString
PASS:		es:di	- SearchString arguments
		dl	- SearchFlags so far (preset by caller)
RETURN:		cf	- set if flags are illegal
			  clear otherwise
			     dl	- SearchFlags including flags passed
				  to SearchString from Legos code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSearchStringFlags	proc	near
		uses	ax
		.enter
	;
	; First make sure we've been given legal flags: no unused bits
	; should be set.
	;
		mov	ax, es:[di][size ComponentData*2].CD_data.LD_integer
		test	ax, not (mask SSF_BACKWARDS or \
				 mask SSF_CASE_SENSITIVE or \
				 mask SSF_PARTIAL_START or \
				 mask SSF_PARTIAL_END)
		stc
		jnz	done				; error

		
		mov	ax, es:[di][size ComponentData*2].CD_data.LD_integer
		test	ax, mask SSF_BACKWARDS
		jz	$10
		or	dl, mask SF_BACKWARDS

$10:		
		test	ax, mask SSF_CASE_SENSITIVE
		jnz	$20
		or	dl, mask SF_IGNORE_CASE
$20:
	;
	; The sense of SSF_PARTIAL_START/END are reversed ==> 0 means
	; * at start/end. So only if both are set is there no wildcard.
	;
		and	ax, mask SSF_PARTIAL_START or mask SSF_PARTIAL_END
		jz	done
		cmp	ax, (mask SSF_PARTIAL_START or mask SSF_PARTIAL_END)
		jne	done
		or	dl, mask SF_NO_WILDCARDS

		clc					; no error
done:
		.leave
		ret
GetSearchStringFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSearchStringFieldName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of the field to be searched.  This helper
		routine is provided for clarity, as GadgetDBActionSearch
		String is getting too long.

CALLED BY:	GadgetDBActionSearchString
PASS:		*ds:si	-	db component
		es:di	-	SearchString arguments
		ss:bx	-	SearchStringParams
RETURN:		carry	-	set if error occurred
					cx = error code (no mapping reqrd)
				clear if no error
					cx = DataStore session token
					SP_searchType set
					SP_startField set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSearchStringFieldName	proc	near
.warn -private
	uses	ax, es, di
		.enter
	;
	; Get the name of the field to search in. If name is NULL,
	; search in all string fields.
	;
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapLock_asm
		Assert	fptr, esdi

		push	di
		mov	di, ds:[si]
		add	di, ds:[di].GadgetDB_offset
		mov	ax, ds:[di].GDBI_token
		pop	di
		push	ax				; preserve token
		mov	ss:[bx].SSP_searchParams.SP_searchType, ST_ALL
		call	LocalStringLength
		jcxz	searchCommon			; search all (field 0)

	; Don't allow a string search in Timestamp or RecordID.
		call	GadgetDBCheckForReservedFieldName
		jz	nonStringField

		mov	ss:[bx].SSP_searchParams.SP_searchType, ST_FIELD
		call	DataStoreFieldNameToID
		mov	cx, ax				; save error, if any
searchCommon:
		mov	ss:[bx].SSP_searchParams.SP_startField, cl
unlockName:
		pushf
		les	di, ss:[bp].EDAA_argv
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapUnlock_asm
		popf
		jc	returnLegosDBError
		pop	cx				; return token

done:
		.leave
		ret

returnLegosDBError:
		add	sp, size word			; pop token
		cmp	cx, DSE_BAD_SEARCH_PARAMS
		je	haveError
		call	MapDataStoreStructureErrorToLegosDBError
haveError:
		stc
		jmp	done

nonStringField:
		mov	cx, DSE_BAD_SEARCH_PARAMS
		stc
		jmp	unlockName
.warn @private
GetSearchStringFieldName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleFirstSearchFailed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The first search in GadgetDBActionSearchString failed.
		Figure out what to do next.  This routine provided for
		clarity since GadgetDBActionSearchString is too long.

CALLED BY:	GadgetDBActionSearchString
PASS:		ax	- error returned by DataStoreStringSearch
		cx	- DataStore session token
		es:di	- SearchStringParams
RETURN:		carry	- set if error occurred and search should
			  not continue
		zero	- if carry is clear....
				set if search should not continue
				because there's nothing left to
				search
				dxax = record count if we should
				continue the search
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleFirstSearchFailed	proc	near
	uses	cx
		.enter

	;
	; If problem is *not* that we ran out of records (searching
	; either direction), then bail.
		cmp	ax, DSE_NO_MORE_RECORDS
		jne	error

	; We ran out of records.

	;
	; If we started at the 0th record and ran out searching forwards,
	; then there's nothing left to search.  If we started at record
	; 0 but searched backwards, then there's probably more to search.
	;
		tstdw	es:[di].SSP_searchParams.SP_startRecord
		jnz	checkIfStartedAtLastRecord
		test	es:[di].SSP_searchParams.SP_flags, mask SF_BACKWARDS
		jz	dontContinueSearch	; fwd search

	;
	; Similarly if we started at the last record and ran out
	; searching backwards, then there's nothing left to check.
	; But if we ran out searching forwards, there are more records.
	;
checkIfStartedAtLastRecord:
		xchg	ax, cx			; ax <- token
						; cx <- error
		push	cx
		call	DataStoreGetRecordCount
		mov_tr	cx, ax			; dxcx <- count
		pop	ax			; ax <- orig. error
		jc	error
		decdw	dxcx
		cmpdw	es:[di].SSP_searchParams.SP_startRecord, dxcx
		jnz	checkIfStartedAtEnd
		test	es:[di].SSP_searchParams.SP_flags, mask SF_BACKWARDS
		jnz	dontContinueSearch	; nothing left
		
	;
	; If we started our search from either end and ran out of
	; records, then there's nothing left to search.
	;
checkIfStartedAtEnd:
		test	es:[di].SSP_searchParams.SP_flags, mask SF_START_AT_END
		jnz	dontContinueSearch

	;
	; Yup, we will do a second search.
	;
		xchg	ax, cx
		incdw	dxax			; dxax <- record count
		test	cx, 0xffff		; cf<-0, zf<-0
		
exit:
		.leave
		ret

dontContinueSearch:
		test	al, 0			; zf <- 1, cf <- 0
		jmp	exit

error:
		stc
		jmp	exit
HandleFirstSearchFailed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureOutNumRecordsForSecondSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Our first search wrapped.  Figure out how many
		more records need to be checked.  This routine
		is provided for clarity since GadgetDBActionSearch
		String is too long.

CALLED BY:	GadgetDBActionSearchString
PASS:		es:di	- SearchStringParams
		dxax	- number or records in database
RETURN:		carry	- set if error
				ax = error code
			  clear if no error
				dxax = number recs to search in
				       second search
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureOutNumRecordsForSecondSearch	proc	near
		.enter

		test	es:[di].SSP_searchParams.SP_flags, mask SF_BACKWARDS
		jnz	backwards

	;
	; The search has wrapped back to the beginning. If we're searching
	; all the records, then we'll just put the original start number
	; into maxCount; otherwise, we'll compute the number of records
	; we've already scanned, and subtract that from maxRecords.
	;
		cmpdw	es:[di].SSP_searchParams.SP_maxRecords, -1
							; UNSIGNED comparison
		jz	forwardWrapMax

		subdw	dxax, es:[di].SSP_searchParams.SP_startRecord
							; dxax <- records
							; already searched
		jmp	checkNumLeft

forwardWrapMax:
		movdw	dxax, es:[di].SSP_searchParams.SP_startRecord
		Assert	carryClear
		jmp	exit

backwards:
	;
	; The search has wrapped to the end from the beginning. If we're
	; searching all the records, then we'll just put (total records -
	; the original start number -1) into maxCount; otherwise, we'll
	; compute the number of records we've already scanned, and subtract
	; that from maxRecords. 
	;
		cmpdw	es:[di].SSP_searchParams.SP_maxRecords, -1	; UNSIGNED comparison
		jz	backwardWrapMax

		movdw	dxax, es:[di].SSP_searchParams.SP_startRecord
		incdw	dxax				; dxax <- recs alrdy
							;         searched

checkNumLeft:
		subdw	dxax, es:[di].SSP_searchParams.SP_maxRecords
		negdw	dxax				; dxax <- num left
		
		test	dh, 0x80			; test sign bit
		jnz	returnNoMatch
		tstdw	dxax
		jz	returnNoMatch

	;
	; We've got more to search.
	;
		clc
exit:
		.leave
		ret
		
returnNoMatch:
		mov	ax, DSE_NO_MATCH_FOUND
		stc
		jmp	exit

backwardWrapMax:
		subdw	dxax, es:[di].SSP_searchParams.SP_startRecord
		decdw	dxax
		clc
		jmp	exit
FigureOutNumRecordsForSecondSearch	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleSecondSearchFailed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If a search wrapped and required a second search, and
		the second search failed, then handle it.

		(This routine provided for clarity only, as the search
		handlers are getting tooooooo long.)

CALLED BY:	GadgetDBActionSearchString
PASS:		ss:bp	- arguments to SearchString
		ax	- error code returned by DataStoreStringSearch
RETURN:		ax	- the *right* error code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Our search was done in two parts.  The second part searched
	for either the remaining fraction of maxRecords that we didn't
	search in the first part.  Or the second search completed the
	search of *all* records.  If the latter, then we need to
	replace the DSE_NO_MATCH_FOUND returned by DataStore with
	DSE_NO_MORE_RECORDS (as if DataStore had done one search
	including the wrap).


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleSecondSearchFailed	proc	near
	uses	di
		.enter

		CheckHack <DSE_NO_MATCH_FOUND eq DSE_NO_MORE_RECORDS - 1>
EC <		push	ax,bx						>
EC <		mov	ax, ss						>
EC <		mov	bx, es						>
EC <		Assert	e ax, bx					>
EC <		pop	ax,bx						>
		mov	di, ss:[bp].EDAA_argv.low
		Assert	fptr	esdi
		cmp	{word}es:[di][size ComponentData*3].CD_data, 0
		jnz	done			; maxRecords was not 0

		cmp	ax, DSE_NO_MATCH_FOUND
		jne	done
		inc	ax			; ax <- "No more records"
done:
		.leave
		ret
HandleSecondSearchFailed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwitchNoRecordFoundErrorsHack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to correct the reversal of meanings for error
		codes 24 and 25 between Legos and DataStore.

		Legos:
		   24 - No match found	  *all* records searched w/o
		   			  finding a match
		   25 - No more records	  N recs searched w/o match

		DataStore:
		   24 - No match found	  N recs searched w/o a match
		   25 - No more records	  *all* records searched w/o
					  finding a match

CALLED BY:	GadgetDBActionSearchString
PASS:		cx	- DataStoreError
RETURN:		cx	- converted DataStoreError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwitchNoRecordFoundErrorsHack	proc	near
		.enter

		CheckHack <DSE_NO_MATCH_FOUND eq DSE_NO_MORE_RECORDS - 1>
		cmp	cx, DSE_NO_MATCH_FOUND
		jne	checkNoMoreRecords
		inc	cx

done:
		.leave
		ret

checkNoMoreRecords:
		cmp	cx, DSE_NO_MORE_RECORDS
		jne	done
		dec	cx
		jmp	done
SwitchNoRecordFoundErrorsHack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValidateMaxRecords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're passed maxRecords >= number recs in DB, return
		0 for maxRecords.

CALLED BY:	GadgetDBActionSearchString/Number
PASS:		es:di	- args to SearchString
		*ds:si	- db component
RETURN:		ax	- legitimate maxRecords value
			   If passed maxRecords >= numRecords
				return 0
			   Negative maxRecords argument will be treated
			   as unsigned and converted to 0.
			   NOTE!  maxRecords argument updated, too.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	SearchString will interpret maxRecords=0 to mean "search
	everything."  If we don't do this conversion and the search
	fails, we'll get "No more records" instead of the desired
	"No match found."
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValidateMaxRecords	proc	near
.warn -private
	uses	cx, dx, bx
		.enter

		mov	cx, es:[di][size ComponentData*3].CD_data.LD_integer
		push	di
		
		mov	di, ds:[si]
		add	di, ds:[di].GadgetDB_offset
		mov	ax, ds:[di].GDBI_token
		call	DataStoreGetRecordCount
		jc	error
		xchg	cx, ax
		xchg	bx, dx			; bxcx <- num recs
		cwd				; dxax <- passed maxRecords
		cmpdw	dxax, bxcx
		jb	done
		clr	ax
done:
		pop	di
		mov	es:[di][size ComponentData*3].CD_data.LD_integer, ax
		
		.leave
		ret
error:
		mov_tr	ax, cx
		jmp	done
.warn @private
ValidateMaxRecords	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopySearchString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies search string to a block on global heap,
		prepending & appending with '*' as dictated by
		partial start/end flags.

CALLED BY:	GadgetDBCActionSearchString
PASS:		es:di - args
RETURN:		carry	- clear if no error
				es:di - match string.
				es:0 - block handle
			  set if error (i.e., "" match string)
				cx - error (no mapping required)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 1/96	Initial version
	jmagasin 10/16/96	return error if null match string passed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopySearchString		proc	near
		uses	ax, bx, si
		.enter
	;
	; Copy the search string to global heap
	; after getting flags and reversing
	; sense of partial start/end flags.
	;
		push	cx				; don't put in "uses"
		
		mov	dx, es:[di][size ComponentData*2].CD_data.LD_integer
		and	dx, (mask SSF_PARTIAL_START or mask SSF_PARTIAL_END)
		xor	dx, (mask SSF_PARTIAL_START or mask SSF_PARTIAL_END)
		mov	ax, es:[di][size ComponentData].CD_data.LD_string
		call	RunHeapLock_asm
		Assert	fptr, esdi

		push	ax, ds				;save for unlocking

	;
	; Calculate size needed, including wildcard '*'
	;
		call	LocalStringSize
		jcxz	nullMatchString
		inc	cx
DBCS<		inc	cx				>
		test	dx, mask SSF_PARTIAL_START
		jz	$10
		add	cx, size TCHAR			; preceding '*'
$10:				
		test	dx, mask SSF_PARTIAL_END
		jz	$20
		add	cx, size TCHAR			; following '*'
$20:
		segmov	ds, es, si
		mov	si, di				; ds:si <- source

		push	cx				; size of string
		mov	ax, cx
		add	ax, size word
		mov	cx, HAF_STANDARD_NO_ERR
		call	MemAlloc
		call	MemLock
		mov	es, ax
		mov	es:[0], bx
		mov	di, size word			; es:di <- dest
		pop	cx
	;
	; Now copy the string, any leading or trailing '*', and NULL
	; to the destination block
	;
		test	dx, mask SSF_PARTIAL_END
		jz	noPE
		sub	cx, size TCHAR
noPE:		
		mov	ax, WC_MATCH_MULTIPLE_CHARS	; '*'
		test	dx, mask SSF_PARTIAL_START
		jz	copyStringNow
		sub	cx, size TCHAR
		LocalPutChar	esdi, ax		; put '*'
copyStringNow:		
		rep	movsb				; copies NULL

		test	dx, mask SSF_PARTIAL_END
		jz	done
		sub	di, size TCHAR
		LocalPutChar	esdi, ax		; put '*'
		clr	ax
		LocalPutChar	esdi, ax		; put NULL
done:
		pop	ax, ds
		call	RunHeapUnlock_asm

		mov	di, size word			; es:di <- match string

		pop	cx				; from very beginning
		clc					; no error
exit:
		.leave
		ret

nullMatchString:
		pop	ax, ds
		call	RunHeapUnlock_asm
		pop	cx				; clear stack
		mov	cx, GDBEC_INVALID_MATCH_STRING
		stc					; error
		jmp	exit
CopySearchString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeSearchString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the search string allocated by CopySearchString.

CALLED BY:	DBCActionSearchString
PASS:		es:di	- SearchStringParams
RETURN:		nothing
DESTROYED:	es, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/23/96	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeSearchString		proc	near
		.enter

		mov	es, es:[di].SSP_searchParams.SP_searchString.high
		mov	bx, es:[0]
		call	MemFree
		
		.leave
		ret
FreeSearchString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCurrentRecordNumberAfterSearchString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Calculate the index of the current record after a
		failed SearchString.  Discards the current record
		(and any changes to it) and loads the new current
		record.

CALLED BY:      GadgetDBActionSearchString
PASS:           ss:bp	- EntDoActionArgs
		*ds:si = instance data                          
RETURN:         carry set if error (caller doesn't care which error)
		carry clear
			Record where search stopped is loaded
DESTROYED:      es, cx, di, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCurrentRecordNumberAfterSearchString	proc	near
		.enter

	;
	; Pass maxRecords and "backwards" flags to common code.
	;
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
		mov	cx, es:[di].[(size ComponentData)*3].CD_data.LD_integer
		mov	bx, es:[di][size ComponentData*2].CD_data.LD_integer
		and	bx, mask SSF_BACKWARDS
		call	FindCurrentRecordNumberCommon
		
		.leave
		ret
FindCurrentRecordNumberAfterSearchString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCurrentRecordNumberAfterSearchNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Calculate the index of the current record after a
		failed SearchString.  Discards the current record
		(and any changes to it) and loads the new current
		record.

CALLED BY:      GadgetDBActionSearchString
PASS:           ss:bp	- EntDoActionArgs
		*ds:si = instance data                          
RETURN:         carry set if error (caller doesn't care which error)
		carry clear
			Record where search stopped is loaded
DESTROYED:      nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCurrentRecordNumberAfterSearchNumber	proc	near
	uses	di, cx, bx
		.enter

	;
	; Pass maxRecords and "backwards" flags to common code.
	;
EC <		push	ax,bx						>
EC <		mov	ax, ss						>
EC <		mov	bx, es						>
EC <		Assert	e ax, bx					>
EC <		pop	ax,bx						>
		mov	di, ss:[bp].EDAA_argv.low
		Assert	fptr	esdi
		mov	cx, es:[di].[(size ComponentData)*3].CD_data.LD_integer
		mov	bx, es:[di][size ComponentData*2].CD_data.LD_integer
		and	bx, mask NSF_BACKWARDS
		call	FindCurrentRecordNumberCommon

		.leave
		ret
FindCurrentRecordNumberAfterSearchNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DoSearchString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a string in the datastore

CALLED BY:
PASS:		ax - datastore session token
		es:di - SearchStringParams
			Actually, params must be on stack, so esdi=ssdi.
			But I want to keep the API close to DataStore
			StringSearch.
RETURN:		carry clear if match found
			dx.ax - index of matching record	
		carry set if error
			ax - DSE_NO_MATCH_FOUND
			   - DSE_NO_MORE_RECORDS 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The API for this routine is very similar to
	DataStoreStringSearch.  Only differences are
		1. Takes SearchStringParams
		2. No field id returned in bl.

	Note for the curious:  Why don't we just use DataStore
	StringSearch?
	   DataStoreStringSearch uses TextSearchInString to
	   find the target string in the fields checked.  But
	   TextSearchInString treats any nonalphanumeric char
	   in a string as a string delimiter.  This is *not*
	   what we want.  According to the DB spec, fields
	   are indivisible strings.  Hence we've replaced
	   DataStoreStringSearch with a customized search.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/12/96	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoSearchString		proc	near
		uses	cx, si, bx, bp
		.enter
	;
	; Figure out what kind of comparison we'll need when
	; we compare a field with the target string. (see
	; strategy).
	;
		call	FigureOutSearchStringComparison

	;
	; Convert the SearchParams into params for our callback
	; and enumerate the records.
	;
		push	di
		mov	es:[di].SSP_status, SSS_NONE

		CheckHack <offset SF_BACKWARDS +8 eq offset DSREF_BACKWARDS>
		CheckHack <offset SF_START_AT_END +8 eq offset DSREF_START_AT_END>
		CheckHack <offset SF_BACKWARDS eq 7>
		clr	cl
		mov	ch, es:[di].SSP_searchParams.SP_flags
		mov	si, cx

		movdw	dxcx, es:[di].SSP_searchParams.SP_startRecord
		mov	es:[di].SSP_token, ax

		mov	bp, di				; callback data
		mov	bx, SEGMENT_CS
		mov	di, offset DoSearchStringCallback

		call	DataStoreRecordEnum
		pop	di
		jc	exit

	;
	; Figure out what happened.
	;
		mov	ax, cx				; dxax = rec # ??
		cmp	es:[di].SSP_status, SSS_FOUND
		je	exit

		mov	ax, DSE_NO_MORE_RECORDS
		cmp	es:[di].SSP_status, SSS_NONE	; ran off the end
		stc					; of record list
		je	exit

		mov	ax, DSE_NO_MATCH_FOUND		; no match in N recs

exit:
		.leave
		ret
DoSearchString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureOutSearchStringComparison
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the appropriate comparsion routine to
		use when looking for the target string within an
		individual field.  This routine provided because
		TextSearchInString treats fields with non-alpha-
		numeric chars as multistringed, a bad thing(tm).

CALLED BY:	
PASS:		ax - datastore session token
		es:di - SearchStringParams
			Actually, params must be on stack, so esdi=ssdi.
			But I want to keep the API close to DataStore
			StringSearch.
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if target string of form "*ABC*" {
		   let TextSearchInString do the search
		} else if target is of form "ABC*" {
		   search routine will try to match ABC at field's start
		   nuke the wildcard
		} else if target is of form "*ABC" {
		   search routine will try to match ABC at field's end
		   nuke the wildcard
		} else if target has no wildcard chars {
		   search routine must match target & field identically
		}
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/13/96    	Initial version (Friday the 13th!  This
				code might be jinxed:)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureOutSearchStringComparison	proc	near
	uses	ds, si, dx
		.enter

	;
	; If target string of form "*ABC*", use TextSearchInString.
	; The wildcard will be only at the start/end of the target.
	;
		mov	dx, es:[di].SSP_origSearchFlags
		test	dx, mask SSF_PARTIAL_START	; 0 means "*ABC??"
		jnz	checkEndWild
		test	dx, mask SSF_PARTIAL_END	; 0 means "*ABC*"
		jnz	checkEndWild
		
		mov	es:[di].SSP_searchRoutine, SSSR_WILD_WILD
		jmp	done

	;
	; Is our target of the form "ABC*"? 
	;
checkEndWild:
		test	dx, mask SSF_PARTIAL_END
		jnz	checkStartWild
		mov	es:[di].SSP_searchRoutine, SSSR_END_WILD
		jmp	done

	;
	; Is our target of the form "*ABC"?
	;
checkStartWild:
		test	dx, mask SSF_PARTIAL_START
		jnz	exactMatch
		mov	es:[di].SSP_searchRoutine, SSSR_START_WILD
		jmp	done

	;
	; Watson, we've narrowed it down:)
	;
exactMatch:
		mov	es:[di].SSP_searchRoutine, SSSR_EXACT

done:
		.leave
		ret
FigureOutSearchStringComparison	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSearchStringCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a string in a record

CALLED BY:	DoSearchString (via DataStoreRecordEnum)
PASS:		ds:di - ptr to RecordHeader in datastore
		ss:bp - SearchParams (that DataStoreStringSearch takes)
RETURN:		carry set if match found or should stop for some
		other reason
DESTROYED:	can destroy ax, bx, cx, dx, di, bp (see DFRecordArrayEnum)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/12/96	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoSearchStringCallback		proc	far
		uses	si
		.enter


	;
	; Should we even look at this record, or has our count expired?
	;
		movdw	dxcx, ss:[bp].SSP_searchParams.SP_maxRecords
		cmpdw	dxcx, -1
		je	setupForComparison		; searching all

		cmpdw	dxcx, 0
		ja	updateMaxRecords
		mov	ss:[bp].SSP_status, SSS_ABORTED	; out of records
		stc
		jmp	exit

updateMaxRecords:
		decdw	dxcx				; Num left to search
							; after this search.
		movdw	ss:[bp].SSP_searchParams.SP_maxRecords, dxcx


	;
	; Set up some common params (regardless of one/all field search).
	;
setupForComparison:
		mov	ax, ss:[bp].SSP_token
		mov	si, di
		
	;
	; If this is a single field search, get a ptr to the desired
	; field and do the comparison now.
	;
		cmp	ss:[bp].SSP_searchParams.SP_searchType, ST_FIELD
		jne	searchAllFields

		mov	dl, ss:[bp].SSP_searchParams.SP_startField
		call	DataStoreGetFieldPtr
		cmc					; keep looking on error
		jnc	exit
		mov_tr	al, dh
		call	DoSearchStringComparison

exit:
		.leave
		ret

searchAllFields:
		mov	bx, SEGMENT_CS
		mov	di, offset DoSearchStringComparison
		call	DataStoreFieldEnum
		CheckHack <SSS_FOUND eq (SearchStringStatus - 1)>
		cmp	ss:[bp].SSP_status, SSS_FOUND
		cmc					; cf=1 if match/abort
		jmp	exit
DoSearchStringCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSearchStringComparison
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the target string with the passed field.

CALLED BY:	
PASS:		ds:di	- ptr to field content
		cx	- size of field content
		al	- field type
		ss:bp	- SearchStringParams
RETURN:		carry	- set to stop enumeration
			     SSP_status = SSS_FOUND
			  clear to continue enumeration
		SearchStringParams updated
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This routine only knows how to compare a string field to the
	target string.  For regulating how many search attempts are
	made, see DoSearchStringCallback (which know how to abort a
	search).
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoSearchStringComparison	proc	far
		uses    bx, cx, dx, si, di, es
		.enter
	;
	; Make sure it's a string field.
	;
		cmp	al, DSFT_STRING
		clc
		jne	exit

	;
	; Do the comparison.
	;
		mov	bl, ss:[bp].SSP_searchRoutine
		clr	bh
		shl	bx

		mov_tr	si, di				; ds:si = field
		mov_tr	dx, cx				; dx = field length
DBCS <		shr	dx, 1				;      ...really!>
		les	di, ss:[bp].SSP_searchParams.SP_searchString
		call	LocalStringLength		; cx = target length
		
		call	cs:compareTargetToFieldJumpTable[bx]
		jnc	exit

		mov	ss:[bp].SSP_status, SSS_FOUND	; Match found!

exit:
		.leave
		ret
DoSearchStringComparison	endp


compareTargetToFieldJumpTable	nptr	doWildWildSearch,
					doWildEndSearch,
					doWildStartSearch,
					doExactSearch

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	The do???Search routines work as follows:

	Pass:	ds:si	- field string in which to look for target
		es:di	- target string
		ss:bp	- SearchStringParams
		dx	- length of field (number of TCHARs) w/o NULL
		cx	- length of target (number of TCHARs) w/o NULL
	Return: carry	- set if string found, clear if not
	Destr:	bx, cx, dx, si, di, es

	For doExactSearch, doWildStartSearch, and doWildEndSearch,
	we already upcased

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

doExactSearch		proc	near
		.enter
	;
	; Try to match "ABC".  There are no wildcards in our target.
	;
		cmp	dx, cx			; Same length?
		clc
		jne	done
		call	doLocalCmpStrings
done:
		.leave
		ret
doExactSearch		endp


doWildStartSearch	proc	near
		.enter
	;
	; Trying to find "*ABC".
	;
		dec	cx			; Don't cmp the *.
		stc
		jz	done			; But that's all there was!
		LocalNextChar	esdi

		sub	dx, cx
		cmc
		jnc	done			; field too short
DBCS <		shl	dx, 1						>
		add	si, dx			; ds:si = where to search
		call	doLocalCmpStrings
done:
		.leave
		ret
doWildStartSearch	endp


doWildEndSearch	proc	near
		.enter
	;
	; Trying to find "ABC*".
	;
		dec	cx			; Don't cmp the *.
		stc
		jz	done			; But that's all there was!
		cmp	dx, cx
		cmc
		jnc	done			; field too short
		call	doLocalCmpStrings
done:
		.leave
		ret
doWildEndSearch	endp


;
; Do either a LocalCmpStrings or a LocalCmpStringsNoCase
; depending on SSP_origSearchFlags.
;	Pass: ds:si - string 1
;	      es:di - string 2
;	      ss:bp - SearchStringParams
;	      cx    - number of characters to compare
;	Retn: carry - set if match found, clear if not
;
doLocalCmpStrings	proc	near
		.enter

		test	ss:[bp].SSP_origSearchFlags, \
			mask SSF_CASE_SENSITIVE
		jnz	caseSensitive
		call	LocalCmpStringsNoCase
		jz	haveMatch
		clc
		.leave
		ret

caseSensitive:
		call	LocalCmpStrings
		jz	haveMatch
		clc
		.leave
		ret

haveMatch:
		stc
		.leave
		ret
doLocalCmpStrings	endp


doWildWildSearch	proc	near
		uses	bp, ax, ds
		.enter
	;
	; Get SearchOptions.  We know the target is of the "*ABC*"
	; variety.  All we need to check is case-sensitivity.
	;
		clr	al			; assume no flags
		test	ss:[bp].SSP_origSearchFlags, \
			mask SSF_CASE_SENSITIVE	; 0 means insensitive
		jnz	setupPointers
		or	al, mask SO_IGNORE_CASE
		
	;
	; Set up pointers for TextSearchInString.
	;
setupPointers:
		xchg	si, di
		segxchg	es, ds, cx
		mov	bp, di			; search all of field string
		mov	bx, di
		mov	cx, dx
DBCS <		shl	dx, 1						>
		dec	dx
DBCS <		dec	dx						>
		add	bx, dx			; es:bx pts to end of field
		mov_tr	dx, cx			; length of field
		clr	cx			; target is null-terminated
		call	TextSearchInString
		cmc
		
		.leave
		ret
doWildWildSearch	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCurrentRecordNumberCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Calculate the index of the current record after a
		failed search.  Discards the current record (and any
		changes to it) and loads the new current record.

		Note that the new current record is not the last record
		searched.  Rather, it is the record that should be
		searched first if the user continues searching.

CALLED BY:      FindCurrentRecordNumberAfterSearchNumber,
		FindCurrentRecordNumberAfterSearchString
PASS:           *ds:si = instance data
		cx	- maxRecords argument
		bx	- 0 if forwards search,
			  nonzero if backwards search
RETURN:         carry set if error (caller doesn't care which error)
		carry clear
			Record where search stopped is loaded
DESTROYED:      di, cx, bx
SIDE EFFECTS:   

PSEUDO CODE/STRATEGY:
		- If it is a forward search
		   . record index = record index + maxRecords
		   . If record index >= numRecords then
			 record index = record index - numRecords
		- If it is a backward search
		   . record index = record index - maxRecords
		   . If record index < 0 then
		         record index = record index + numRecords
REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	ATRAN   7/29/96         Initial version
	jmagasin 8/23/96	Combined common code, added error handling,
				load record if success.
	jmagasin 9/3/96		Pass in maxRecords and "backwards" flag.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCurrentRecordNumberCommon proc    near
.warn -private
	uses	ax,dx
		.enter
	;
	; If we searched all records (maxRecords=0), then our
	; record property is correct as is.
	;
		jcxz	discardAndDone
	;
	; Set up some common stuff regardless of search direction.
	; cx <- maxRecords
	; di <- obj offset
	; ss:[sp] and ax <- num recs
	; dxbx <- current record (where search began)
	;
		mov     di, ds:[si]
		add     di, ds:[di].GadgetDB_offset
		mov	ax, ds:[di].GDBI_token
		call	DataStoreGetRecordCount	; dxax <- num records
		jc	discardAndDone

		tst	bx			; zf <- 0 if bkwds search
		push	dx
		movdw   dxbx, ds:[di].GDBI_recordNum

		pushf				; save test from bkwds test
		cmpdw	dxbx, -1		; if current record...
		jne	haveRecordNum
		clrdw	dxbx			; ...then we started at 0.
haveRecordNum:
		popf
		
		jnz     backwardSearch

	; Forward search
		add     bx, cx
		adc	dx, 0			; dxbx = rec index + maxRec
		pop	cx			; cxax = num records

		cmpdw	dxbx, cxax
		jb	gotCurrentRecordIndex	; (unsigned comparison)
		subdw	dxbx, cxax              ; forward wrap
		jmp	gotCurrentRecordIndex

	; Backward Search
backwardSearch:
		sub	bx, cx
		sbb	dx, 0			; dxbx = rec index - maxRec
		pop	cx			; cxax = num records
		
		test	dh, 0x80		; check sign bit
		jz	gotCurrentRecordIndex
		adddw	dxbx, cxax		; backward wrap

	;
	; Discard the current record, get the new record.
	;
gotCurrentRecordIndex:
		call	DiscardRecordCommon
		jc	done
		mov	ax, ds:[di].GDBI_token
		mov_tr	cx, bx
		pushdw	dxcx			; save new current rec index
		call	DataStoreLoadRecordNum	; dxcx <- rec id
		jnc	loadedNewCurRec		; jump if no error
		add	sp, size dword
		stc
		jmp	done
loadedNewCurRec:
		popdw	ds:[di].GDBI_recordNum
		movdw	ds:[di].GDBI_recordID, dxcx
		BitSet	ds:[di].GDBI_flags, GDBF_HAVE_RECORD
		clc
		jmp	done

discardAndDone:
		pushf					; save cf (error)
		call	DiscardChangesToCurrentRecord	; cf <- 0 or 1
		lahf
		pop	cx
		or	ah, cl				; or old/new CF's
		sahf
done:
		.leave
		Destroy	di, cx, bx
		ret
.warn @private
FindCurrentRecordNumberCommon endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDBActionSearchNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a number

CALLED BY:	MSG_GADGET_DB_ACTION_SEARCH_NUMBER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GadgetDBClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 1/96		Initial version
	jmagasin 9/4/96		Broke out subroutines.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComparisonType		etype byte
	ST_LT			enum ComparisonType
	ST_LTE			enum ComparisonType
	ST_EQ			enum ComparisonType
	ST_GTE			enum ComparisonType
	ST_GT			enum ComparisonType

AllKindsOfNumbers	union
	AKON_integer	word
	AKON_long	dword
	AKON_float	dword
AllKindsOfNumbers	end

SearchNumStatus	etype byte
	SNS_NONE	enum	SearchNumStatus
	SNS_ABORTED	enum	SearchNumStatus
	SNS_FOUND	enum	SearchNumStatus


SEARCH_FOR_RECORDID	= 0xFF				; Callback handles
							; this specially.

SearchNumCallbackParams	struct
	SNCP_token		word
	SNCP_startRecord	dword
	SNCP_flags		DataStoreRecordEnumFlags
	SNCP_startField		FieldID
	SNCP_comparison		ComparisonType
	SNCP_numberSize		word			;byte size of #
	SNCP_number		AllKindsOfNumbers
	SNCP_maxRecords		word			;abort search when
							;this thing reaches 0
	SNCP_status		SearchNumStatus			; did we abort
	align word
SearchNumCallbackParams ends

GadgetDBActionSearchNumber	method dynamic GadgetDBClass,
				MSG_GADGET_DB_ACTION_SEARCH_NUMBER
		uses	cx, dx, bp
		.enter

		movdw	dxcx, ds:[di].GDBI_recordNum

	;
	; If no open datastore, return error
	;
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	ax, GDBEC_DATABASE_NOT_OPEN
		LONG	jz	recordError

	;
	;  Make sure we got all the args
	;
		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
		call	CheckSearchNumberArgs
		jz	everythingChecks
		
		mov	cx, CAE_WRONG_TYPE
		call	GadgetDBActionRTECommon
		jmp	done

everythingChecks:

		clr	ax
		cmpdw	dxcx, GDB_RECORDNUM_FOR_NO_RECORD
		jne	haveStart

	;
	; Since there's no current record, we need to start at the end.
	;
		mov	ax, mask DSREF_START_AT_END
haveStart:
		sub	sp, size SearchNumCallbackParams
		mov	bx, sp				; ss:bx <- params
	;
	; Set the start record and max records. If maxRecords = 0,
	; start at end.
	;
		movdw	ss:[bx].SNCP_startRecord, dxcx
		mov	dx, ax				; dx <- flags
		call	ValidateMaxRecords		; ax <- maxRecords
		tst	ax
		jnz	haveMax
		dec	ax
haveMax:
		mov	ss:[bx].SNCP_maxRecords, ax
	;
	; Get search flags, field name and number to match.
	;
		call	GetSearchNumberFlags		; dx <- flags
		mov	ax, DSE_INVALID_FLAGS
		jc	dbErrorNukeSearchParams
		mov	ss:[bx].SNCP_flags, dx
		call	GetSearchNumberFieldName	; ax <- error, if any
		jc	dbErrorNukeSearchParams
		call	GetSearchNumberNumber
		
	;
	; Do the search and evaluate its results.
	;
		call	DoSearchNumber			; dxcx <- last rec
		call	EvalFirstSearchNumberResults
		jz	success
		jc	fixupSPRecordError

		call	FigureOutNumRecordsForSecondSearchNumber
		jc	fixupSPRecordError

	;
	; Continue a search that wrapped.  Note that DoSearchNumber
	; will specify a start record, but DSREF_START_AT_END will
	; override that.
	;
		BitSet	ss:[bx].SNCP_flags, DSREF_START_AT_END
		call	DoSearchNumber			; dxcx <- last rec

	;
	; Evaluate search results for second search (which handled
	; the wrapping).
	;
		call	EvalSecondSearchNumberResults
		jc	fixupSPRecordError

	;
	; Success! Make this (dx.cx) the current record.
	;
success:
		add	sp, size SearchNumCallbackParams
		call	DiscardRecordCommon
		jc	recordError

		mov	di, ds:[si]
		add	di, ds:[di].GadgetDB_offset
		movdw	ds:[di].GDBI_recordNum, dxcx
		mov	ax, ds:[di].GDBI_token
		call	DataStoreLoadRecordNum
		jc	recordError
		movdw	ds:[di].GDBI_recordID, dxcx
		BitSet	ds:[di].GDBI_flags, GDBF_HAVE_RECORD

		call	GadgetDBSuccessCommon

done:
		.leave
		ret

fixupSPRecordError:
		call	FindCurrentRecordNumberAfterSearchNumber
		add	sp, size SearchNumCallbackParams
		mov_tr	cx, ax
		jmp	recordError2

dbErrorNukeSearchParams:
		add	sp, size SearchNumCallbackParams

recordError:
		mov_tr	cx, ax		
		call	DiscardChangesToCurrentRecord
recordError2:
		call	SwitchNoRecordFoundErrorsHack
		call	GadgetDBErrorCommon
		jmp	done
GadgetDBActionSearchNumber		endm

;
;PASS:	ds:di - record header
;	ss:bp - SearchNumCallbackParams
;
;RETURN: carry set to stop enum
;
SearchNumCallback	proc	far
	uses	ax, bx, cx, dx, di, si
	.enter

	;
	;  Lock down the field in question so we can do the enum
	;
	mov	ax, ss:[bp].SNCP_token
	mov	dl, ss:[bp].SNCP_startField
	cmp	dl, SEARCH_FOR_RECORDID
	je	checkRecordID
	mov	si, di
	call	DataStoreGetFieldPtr
	jnc	gotField

	;
	; If we couldn't get the field because it "doesn't exist", then
	; we've found a field with value 0.
	;
	cmp	ax, DSDE_FIELD_DOES_NOT_EXIST
	jne	next				; Something else went wrong.

	cmp	ss:[bp].SNCP_numberSize, size AKON_integer
	jne	checkIfLongZero
	tst	ss:[bp].SNCP_number.AKON_integer
	jmp	evalZeroTest

checkIfLongZero:
	tstdw	ss:[bp].SNCP_number.AKON_long

evalZeroTest:
	stc
	jz	found
	jmp	next

	;
	; The field exists in this record -- grab it.
	;
gotField:
	cmp	cx, ss:[bp].SNCP_numberSize
	jne	next

	cmp	cx, size word
	jne	notInt

	mov	ax, ds:[di]
	cmp	ss:[bp].SNCP_number.AKON_integer, ax

getTableIndex:
	lahf
	mov	bl, ss:[bp].SNCP_comparison
	clr	bh
	shl	bx
	sahf

	call	cs:compareNumsJumpTable[bx]
	jc	found

	;
	; Didn't find anything in this record, so decrement
	; the count and continue.
	;
next:
	cmp	ss:[bp].SNCP_maxRecords, 0xffff
	clc
	je	done
	dec	ss:[bp].SNCP_maxRecords
	jz	abort

done:
	.leave
	ret

found:
	mov	ss:[bp].SNCP_status, SNS_FOUND
	jmp	done				; don't bother updating
						; maxRecords
notInt:
	mov	ax, ds:[di]
	mov	dx, ds:[di][size word]
	cmpdw	ss:[bp].SNCP_number.AKON_long, dxax
	jmp	getTableIndex

abort:
	; set up the status so we know we aborted because
	; we examined maxRecords without a match
	mov	ss:[bp].SNCP_status, SNS_ABORTED
	stc
	jmp	done

checkRecordID:
	; RecordID searches are handled specially.
	CheckHack <size RecordID eq size dword>
	cmpdw	ds:[di].RH_id, ss:[bp].SNCP_number.AKON_long, bx
	jmp	getTableIndex
SearchNumCallback	endp

;
; only works with integerss right now
;
compareNumsJumpTable	nptr	compareLT,
				compareLTE,
				compareEQ,
				compareGTE,
				compareGT

compareFinished:
	retn

compareLT:
	stc
	jl	compareFinished
	clc
	retn

compareLTE:
	stc
	jle	compareFinished
	clc
	retn
	
compareEQ:
	stc
	je	compareFinished
	clc
	retn

compareGTE:
	stc
	jge	compareFinished
	clc
	retn
	
compareGT:
	stc
	jg	compareFinished
	clc
	retn



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSearchNumberArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure SearchNumber args are okay.  Routine
		provided just for clarity since GadgetDBAction
		SearchNumber is too long.

CALLED BY:	GadgetDBActionSearchNumber
PASS:		es:di	- arguments to SearchNumber
RETURN:		zf	- set if args are legal
			  clear if RTE should be raised
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckSearchNumberArgs	proc	near
		.enter
		
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	done
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_INTEGER
		je	numOK
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_LONG
		je	numOK
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_FLOAT
		jne	done
numOK:
		cmp	es:[di][size ComponentData*2].CD_type, LT_TYPE_INTEGER
		jne	done
		cmp	es:[di][size ComponentData*3].CD_type, LT_TYPE_INTEGER

done:
		.leave
		ret
CheckSearchNumberArgs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSearchNumberFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the flags for our number search.  This routine
		provided for clarity because GadgetDBActionSearch
		Number is getting too big.

CALLED BY:	GadgetDBActionSearchNumber
PASS:		es:di	- SearchNumber arguments
		dx	- flags so far
RETURN:		cf	- set if illegal flags
			  clear otherwise
			     dx	- flags updated
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSearchNumberFlags	proc	near
		uses	ax
		.enter

		mov	ax, es:[di][size ComponentData*2].CD_data.LD_integer
		test	ax, not mask NSF_BACKWARDS
		stc
		jnz	done				; illegal flags

		test	ax, mask NSF_BACKWARDS
		jz	done
		or	dx, mask DSREF_BACKWARDS
		; Both test and or clear the carry flag.
done:
		.leave
		ret
GetSearchNumberFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSearchNumberFieldName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of the field to be searched.  This helper
		routine is provided for clarity, as GadgetDBActionSearch
		Number is getting too long.

CALLED BY:	GadgetDBActionSearchNumber
PASS:		*ds:si	-	db component
		es:di	-	SearchNumber arguments
		ss:bx	-	SearchNumberCallbackParams
RETURN:		carry	-	set if error occurred
					ax = error code (no mapping reqrd)
				clear if no error
					SNCP_token set
					SNCP_startField set
DESTROYED:	ax (unless carry set)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSearchNumberFieldName	proc	near
.warn -private
	uses	cx, es, di, si
		.enter
	;
	; Get the name of the field to search in.
	;
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapLock_asm
		Assert	fptr, esdi

	;
	; Can't search all fields in first release...
	;
		call	LocalStringLength
		jcxz	errorNullFieldName

	;
	; Stuff our session token into callback parameters.
	;
		mov	si, ds:[si]
		add	si, ds:[si].GadgetDB_offset
		mov	ax, ds:[si].GDBI_token
		mov	ss:[bx].SNCP_token, ax
	;
	; Check for RecordID and Timestamp fields.  Spec says we
	; may not search for these, although the code will work.
	;
		call	GadgetDBCheckForReservedFieldName
		jnz	getFieldID

		mov	cx, DSE_BAD_SEARCH_PARAMS
		stc
		jmp	unlockName


if 0	; This commented-out code allows us to search for RecordId/Timestamp.
		jnz	getFieldID

		jc	wantRecordID
	; want Timestamp
		clr	al				; Timestamp FieldID
		test	ds:[si].GDBI_flags, mask GDBF_TIMESTAMP
		jnz	haveFieldID
		jmp	dontHaveSpecialField
		
wantRecordID:
		mov	al, SEARCH_FOR_RECORDID		; see callback
		test	ds:[si].GDBI_flags, mask GDBF_RECORD_ID		
		jnz	haveFieldID

dontHaveSpecialField:
		mov	cx, DSSE_INVALID_FIELD_NAME + DSSE_TO_LEGOS_DB_ERROR
		stc
		jmp	unlockName
endif

	;
	; Get ID of field to search.
	;
getFieldID:
		call	DataStoreFieldNameToID
		mov	cx, ax				; save error, if any
		jc	haveFieldID			; (need to map error)
		call	EnsureFieldIsNumeric
		jc	unlockName			; (don't map error)
haveFieldID:
		call	MapDataStoreStructureErrorToLegosDBError
		mov	ss:[bx].SNCP_startField, al
unlockName:
		pushf
		les	di, ss:[bp].EDAA_argv
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapUnlock_asm
		mov_tr	ax, cx				; ax <- error, if any
		popf

done:
		.leave
		ret

errorNullFieldName:
		mov	ax, DSSE_INVALID_FIELD_NAME + DSSE_TO_LEGOS_DB_ERROR
		stc
		jmp	done
.warn @private
GetSearchNumberFieldName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureFieldIsNumeric
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SearchNumber can only search numeric fields.

CALLED BY:	GetSearchNumberFieldName only
PASS:		al	- FieldID
		ss:bx	- SearchNumberCallbackParams (for SNCP_token)
RETURN:		carry	- set if field is not numeric or if some error
			  occurred
				cx - error code (only if carry set)
DESTROYED:	nothing
SIDE EFFECTS:
		On any error, will return "Bad search params".  Though
		DataStoreGetFieldInfo should not error if DataStore
		FieldNameToID did not error.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureFieldIsNumeric	proc	near
		uses	es, di, dx
fieldData	local	FieldDescriptor
		.enter
	;
	; Get a description of the field.
	;
		mov_tr	dx, ax
		segmov	es, ss, ax
		lea	di, ss:[fieldData]
		mov	ax, ss:[bx].SNCP_token
		push	cx
		clr	cx				; Don't want FD_name.
		movdw	es:[di].FD_name, cxcx		; (Just to be tidy.)
		call	DataStoreGetFieldInfo
		pop	cx
		mov_tr	ax, dx
		jc	error
	;
	; Make sure it is a number
	;
		CheckHack <DSFT_FLOAT eq 0>
		CheckHack <DSFT_SHORT eq 1>
		CheckHack <DSFT_LONG  eq 2>
		cmp	es:[di].FD_data.FD_type, DSFT_LONG + 1
		cmc
		jc	error

done:
		.leave
		ret

error:
		mov	cx, DSE_BAD_SEARCH_PARAMS
		jmp	done
EnsureFieldIsNumeric	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSearchNumberNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number we want to match.

CALLED BY:	GadgetDBActionSearchNumber
PASS:		es:di	- SearchNumber arguments
		ss:bx	- SearchNumberCallbackParams
RETURN:		SearchNumberCallbackParams filled in
			SNCP_numberSize
			SNCP_number.AKON_integer/long
			SNCP_comparison
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSearchNumberNumber	proc	near
	uses	ax, dx
		.enter

	;
	; If the number is a long, handle it.
	;
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_INTEGER
		jne	getLong

	;
	; If the number is a RecordID, force it to a long.
	;
		cmp	ss:[bx].SNCP_startField, SEARCH_FOR_RECORDID
		je	wantRecordID

	;
	; The number is just an integer.
	;
		mov	ax, es:[di][size ComponentData].CD_data.LD_integer
		mov	ss:[bx].SNCP_numberSize, size word
		mov	ss:[bx].SNCP_number.AKON_integer, ax
		jmp	haveNum

getLong:
		mov	dx, es:[di][size ComponentData].CD_data.LD_long.high
		mov	ax, es:[di][size ComponentData].CD_data.LD_long.low
stuffLong:
		mov	ss:[bx].SNCP_numberSize, size dword
		movdw	ss:[bx].SNCP_number.AKON_long, dxax

haveNum:
		mov	ss:[bx].SNCP_comparison, ST_EQ
		
		.leave
		ret

wantRecordID:
	; coerce to long
		mov	ax, es:[di][size ComponentData].CD_data.LD_integer
		cwd
		jmp	stuffLong
GetSearchNumberNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSearchNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the SearchNumber via DataStoreRecordEnum.

CALLED BY:	GadgetDBActionSearchNumber
PASS:		ss:bx	- SearchNumberCallbackParams
RETURN:		carry	- set if error
				ax - DataStoreError (so no mapping reqrd)
			  else
				dx.cx - index of last record
				   examined +/-1, depending on direction
				if reached last record,
					ax - DSE_NO_MORE_RECORDS
				else
					ax - DSE_NO_ERROR
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoSearchNumber	proc	near
	uses	bp, si, bx, di
		.enter

		movdw	dxcx, ss:[bx].SNCP_startRecord
		mov	ss:[bx].SNCP_status, SNS_NONE
		mov	si, ss:[bx].SNCP_flags
		mov	ax, ss:[bx].SNCP_token
		mov	di, offset SearchNumCallback
		mov	bp, bx
		mov	bx, SEGMENT_CS
		call	DataStoreRecordEnum
		
		.leave
		ret
DoSearchNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalFirstSearchNumberResults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out what to do after the first number search.

CALLED BY:	GadgetDBActionSearchNumber
PASS:		carry	- set or clear according to DoSearchNumber
		ax	- error code from DoSearchNumber
		ss:bx	- SearchNumCallbackParams
RETURN:		zf	- set if we found a match
			    ax - DSE_NO_ERROR
			  clear if no match was found
			    carry - set if search is over due to error
					ax - error code
					     (no mapping required)
				    clear if search should coninue
					     (it wrapped)

DESTROYED:	ax (if zf=0 and cf=0)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalFirstSearchNumberResults	proc	near
		.enter

		jc	notFoundStopSearch	; DataStoreRecordEnum
						; choked on something.
		
		cmp	ss:[bx].SNCP_status, SNS_ABORTED
		je	abort			; Callback aborted.

		cmp	ss:[bx].SNCP_status, SNS_FOUND
		jz	exit			; Callback found match.
						; zf=1 and ax="no error"

		test	ss:[bx].SNCP_flags, mask DSREF_START_AT_END
		jnz	notFoundStopSearch	; Nothing left to check.
						; ax = DSE_NO_MORE_RECORDS
						; zf = 0

		or	al, 1			; wrap the search, zf=cf=0
		jmp	exit

abort:
		mov	ax, DSE_NO_MATCH_FOUND
		test	al, 0xff		; zf <- 0
notFoundStopSearch:
		stc

exit:
		.leave
		ret
EvalFirstSearchNumberResults	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalSecondSearchNumberResults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate the results of our second search.

CALLED BY:	GadgetDBActionSearchNumber
PASS:		ss:bx	- SearchNumberCallbackParams
		ss:bp	- arguments to SearchNumber
		carry	- set if DoSearchNumber returned an error
		ax	- error code from DoSearchNumber
RETURN:		carry	- set if search failed
				ax - error code (no mapping required)
			  clear if search succeeded
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalSecondSearchNumberResults	proc	near
		.enter

		jc	done				; DataStoreRecordEnum
							; returned an error

		cmp	ss:[bx].SNCP_status, SNS_FOUND	; Callback aborted.
		je	done				; ax = DSE_NO_ERROR
							; zf=1, cf=0
	;
	; We didn't find a match within the specified
	; number of records (with wrapping).  This must be the
	; case since second searches are only for a fixed number
	; of records, those records not seen in the first search.
	;
EC <		cmp	ss:[bx].SNCP_status, SNS_ABORTED		>
EC <		ERROR_NE	-1					>
		pushdw	esdi
		les	di, ss:[bp].EDAA_argv
		cmp	es:[di].[(size ComponentData)*3].CD_data.LD_integer, 0
		popdw	esdi
		stc
		mov	ax, DSE_NO_MORE_RECORDS		; all recs searched
		jz	done
		mov	ax, DSE_NO_MATCH_FOUND		; <all recs searched

done:
		.leave
		ret
EvalSecondSearchNumberResults	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureOutNumRecordsForSecondSearchNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out how many records we'll need to search on
		our second pass.

CALLED BY:	GadgetDBActionSearchNumber
PASS:		ss:bx	- SearchNumberCallbackParams
RETURN:		carry	- set if error
				ax = error code (no mapping reqrd)
			  clear if no error
DESTROYED:	ax (if no error)
SIDE EFFECTS:
	The database component only allows db's of up to 32767
	records, so a word can hold the number of records to
	search after we wrap.

	If the db component ever allows more records, then SNCP_
	maxRecords will need to become a dword.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureOutNumRecordsForSecondSearchNumber	proc	near
	uses	dx
		.enter

	;
	; If we're *not* searching everything, then SNCP_maxRecords
	; will already be correct due to SearchNumCallback.
	;
		cmp	ss:[bx].SNCP_maxRecords, 0xffff
		clc
		jne	exit

	;
	; Since we are searching everything, we must set
	; SNCP_maxRecords according to search direction.
	;
		test	ss:[bx].SNCP_flags, mask DSREF_BACKWARDS
		jnz	backwards
		
	;
	; The search has wrapped back to the begninning.
	; We'll set SNCP_maxRecords to the start record of our first
	; search.  (startRecord = sizeof{0..startRecord-1}
	;
		movdw	dxax, ss:[bx].SNCP_startRecord
		Assert	e dx, 0
		jmp	knowMaxRecords

backwards:
	;
	; The search has wrapped to the end from the beginning.
	; We'll just put (total records - (the original start number + 1))
	; into maxRecords.
	;
		mov	ax, ss:[bx].SNCP_token
		call	DataStoreGetRecordCount		; dxax <- num recs
		jc	exit

		subdw	dxax, ss:[bx].SNCP_startRecord
		Assert	e dx, 0
		Assert	ne ax, 0
		dec	ax

	;
	; Stuff SNCP_maxRecords, and make sure it's not 0.
	;
knowMaxRecords:
		mov	ss:[bx].SNCP_maxRecords, ax
		tst	ax
		mov	ax, DSE_NO_MORE_RECORDS
		stc
		jz	exit
		clc
exit:
		.leave
		ret
FigureOutNumRecordsForSecondSearchNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscardRecordCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discards the current record, if any.

CALLED BY:	INTERNAL
PASS:		*ds:si - GadgetDB
RETURN:		carry set if error
		ax	= DataStoreError, or *some* error meaningful
			  to an event handler
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Set record and recordID instance data to -1.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/95	Initial version
	jmagasin 7/22/96	Return DataStoreError in ax

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscardRecordCommon		proc	near
		uses	si, cx, dx
		class	GadgetDBClass
		.enter
	;
	; Do we have a current record? If not, we can skip the discard.
	;
		mov	si, ds:[si]
		add	si, ds:[si].GadgetDB_offset
		test	ds:[si].GDBI_flags, mask GDBF_DATASTORE_OPEN
		mov	ax, GDBEC_DATABASE_NOT_OPEN
		stc
		jz	done
		test	ds:[si].GDBI_flags, mask GDBF_HAVE_RECORD
		mov	ax, DSE_NO_ERROR
		clc
		jz	done
	;
	; Discard the record. DataStore manager better not tell us
	; there is nothing in the buffer...
	;
		mov	ax, ds:[si].GDBI_token
		call	DataStoreDiscardRecord
EC <		cmp	ax, DSDE_RECORD_BUFFER_EMPTY			>
EC <		ERROR_E	-1						>
		CheckHack <DSDE_NO_ERROR eq DSE_NO_ERROR>
		cmp	ax, DSDE_NO_ERROR
		je	okay
		mov_tr	cx, ax
		call	MapDataStoreDataErrorToLegosDBError
		mov_tr	ax, cx
		stc
		jmp	done
		
okay:
	;
	; Clear the "have record" flag, and initialize record number & ID 
	;
		and	ds:[si].GDBI_flags, \
			not (mask GDBF_HAVE_RECORD or \
			     mask GDBF_HAVE_NEW_RECORD or \
			     mask GDBF_RECORD_MODIFIED)
		movdw	ds:[si].GDBI_recordNum, GDB_RECORDNUM_FOR_NO_RECORD
		movdw	ds:[si].GDBI_recordID, GDB_RECORDID_FOR_NO_RECORD
		clc
		mov	ax, DSE_NO_ERROR
done:
EC <		pushf							>
EC <		cmpdw	ds:[si].GDBI_recordNum, GDB_RECORDNUM_FOR_NO_RECORD >
EC <		ERROR_NE -1						>
EC <		cmpdw	ds:[si].GDBI_recordID, GDB_RECORDID_FOR_NO_RECORD >
EC <		ERROR_NE -1						>
EC <		popf							>

		.leave
		ret
DiscardRecordCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscardChangesToCurrentRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discard changes to the current record, but keep it
		as the current record.

CALLED BY:	
PASS:		*ds:si	- GadgetDB
RETURN:		carry set if error
		ax	= DataStore error, or *some* error meaningful
			  to an event handler (see DiscardRecordCommon)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 8/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscardChangesToCurrentRecord	proc	near
.warn -private
		uses	di, cx
recordID	local	dword
		.enter
	;
	; If we have a modified record, discard any changes.
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetDB_offset
		test	ds:[di].GDBI_flags, mask GDBF_HAVE_RECORD ; cf<-0
		jz	done
		test	ds:[di].GDBI_flags, mask GDBF_RECORD_MODIFIED
		jz	done

		movdw	ss:[recordID], ds:[di].GDBI_recordID, cx
		call	DiscardRecordCommon
		jc	done
	;
	; Now reload the record.
	;
		push	dx
		push	ax
		mov	ax, ds:[di].GDBI_token
		movdw	dxcx, ss:[recordID]
		call	DataStoreLoadRecord		; dxcx <- rec#
		Assert	carryClear			; Don't expect rec
							; to disappear!
		jc	failOnRecordReload
		pop	ax
		movdw	ds:[di].GDBI_recordNum, dxcx
		movdw	ds:[di].GDBI_recordID, ss:[recordID], cx
		BitSet	ds:[di].GDBI_flags, GDBF_HAVE_RECORD
finishPopping:
		pop	dx

done:
		.leave
		ret

failOnRecordReload:
		add	sp, (size word)			; fix stack
		; ax has DataStoreError from DataStoreLoadRecord
		stc
		jmp	finishPopping
.warn @private
DiscardChangesToCurrentRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNonNullTerminatedStringToRunHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy a non-null-terminated string to the run heap, and
		tack a null onto the end of it

CALLED BY:	INTERNAL
PASS:		ax:di - string
		ds - segment of GadgetDB object
		cx - length of string, not including the null
RETURN:		ax - string token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	20 jun 1996	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNonNullTerminatedStringToRunHeap		proc	near
		uses	di, es
		.enter

	;
	; Add in space for the null
	;
		inc	cx
DBCS <		inc	cx					>

	;
	; Slap the thing in there.
	;
		call	CopyDataToRunHeap

	;
	; Lock it down and stuff the trailing null in there.
	;
		call	RunHeapLock_asm
		Assert	fptr esdi
		dec	cx
DBCS <		dec	cx					>
		add	di, cx
SBCS <		mov	{byte}es:[di], 0			>
DBCS <		mov	{word}es:[di], 0			>
		call	RunHeapUnlock_asm

		.leave
		ret
CopyNonNullTerminatedStringToRunHeap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyStringToRunHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy a string to the run heap

CALLED BY:	INTERNAL
PASS:		ax:di - string
		ds - segment of GadgetDB object
RETURN:		ax - string token
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/27/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyStringToRunHeap		proc	near
		uses	di, es
		.enter

		mov	es, ax				; es:di <- string
		call	LocalStringSize
		inc	cx				; add NULL
DBCS <		inc	cx						>
		
		call	CopyDataToRunHeap		; ax = token
		.leave
		ret
CopyStringToRunHeap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDataToRunHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy bytes to the run heap

CALLED BY:	INTERNAL
PASS:		ax:di - data
		ds - object block
		cx - number of bytes
RETURN:		ax - run heap token
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/27/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDataToRunHeap		proc	near
		uses	bx, cx, dx, si, di, es
		.enter

		mov	si, di				; ax:si = data
		push	ax
		mov	bx, RHT_STRING
		mov	dl, 1
		call	RunHeapAlloc_asm		; ax = token

		call	RunHeapLock_asm
		Assert	fptr esdi
		pop	bx

		push	ds
		mov	ds, bx				; ds:si <- data
		rep	movsb
		pop	ds
		call	RunHeapUnlock_asm
		.leave
		ret
CopyDataToRunHeap		endp

ifdef STRUCTS_ARE_GROOVY
;
; PASS:	cx = # of ints to alloc in struct
;
; RETURN: cx = struct token
;
DBAllocIntStruct	proc	far
	uses	ax, bx, dx, bp
	.enter

		push	cx
		mov	ax, size LegosStructField
		mul	cl
		mov_tr	cx, ax

		mov	bx, RHT_STRUCT
		mov	dl, 1
		clr	ax, di
		call	RunHeapAlloc_asm		; ax = token
		call	RunHeapLock_asm			; es:di <- new data

	; Initialize type bytes.  es:di is an array of 3 LegosStructFields
	;
		pop	cx				;cx <- count
		clr	bp
setLoop:
		mov	es:[di][bp].LSF_type, LT_TYPE_INTEGER
		mov	es:[di][bp].LSF_value.low, 0
		add	bp, size LegosStructField
		loop	setLoop

		mov_tr	cx, ax				;cx <- token
	.leave
	ret
DBAllocIntStruct	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCheckForNoOpenDatabaseOnPropertyAccess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quick check to see if there is no open database
		when accessing a property.  Called at the *beginning*
		of a routine, when ds:di = the db's instance data.

CALLED BY:	utility
PASS:		*ds:si	- database component
		ds:di	- instance data of database component
		ss:bp	- GetPropertyArgs
RETURN:		carry	- set if error
				GetPropertyArgs hold error
			  clear if no error
DESTROYED:	if errory, ax, es, di destroyed.  Else nothing destroyed.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 10/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBCheckForNoOpenDatabaseOnPropertyAccess	proc	near
.warn -private
		.enter
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		jz	error
		Assert	carryClear
done:
		.leave
		ret
error:
		les	di, ss:[bp].GPA_compDataPtr
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		call	PropError
		stc
		jmp	done
.warn @private
DBCheckForNoOpenDatabaseOnPropertyAccess	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PropError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set error code for return.

CALLED BY:	INTERNAL
PASS:		es:di - ComponentData
		ax - error
		*ds:si - GadgetDB
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/31/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PropError		proc	near
		class	GadgetDBClass
		.enter
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
if 0
	;
	; Because BasTest halts execution of basic program whenever
	; error is returned, the datastore never gets closed. Also,
	; MSG_ENT_DESTROY doesn't seem to arrive at the GadgetDB object
	; when BasTest is closed. DataStore will fatal error if it
	; exits with open files, so whenever error is returned, this
	; routine will close the open datastore.
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetDB_offset
		test	ds:[di].GDBI_flags, mask GDBF_DATASTORE_OPEN
		jz	done
		call	DiscardRecordCommon
		mov	ax, ds:[di].GDBI_token
		call	DataStoreClose
		jc	done
		mov	ds:[di].GDBI_flags, 0
done:		
endif		
		.leave
		ret
PropError		endp

GadgetDBCode ends


Strings		segment lmem LMEM_TYPE_GENERAL

RecordIDFieldString	chunk.TCHAR	"RecordID", 0
localize	"Name of the RecordID field.";

IDTypeString	chunk.TCHAR	"ID", 0
localize	"Name of the record ID field type.";

FloatTypeString	chunk.TCHAR	"float", 0
localize	"Name of the float field type.";

IntegerTypeString	chunk.TCHAR	"integer", 0
localize	"Name of the integer field type.";

LongTypeString	chunk.TCHAR	"long", 0
localize	"Name of the long field type.";

TimestampFieldString	chunk.TCHAR	"Timestamp", 0
localize	"Name of the Timestamp field.";

TimestampTypeString	chunk.TCHAR	"TIMESTAMP", 0
localize	"Name of the timestamp field type.";

DateTypeString	chunk.TCHAR	"date", 0
localize	"Name of the date field type.";

TimeTypeString	chunk.TCHAR	"time", 0
localize	"Name of the time field type.";

StringTypeString	chunk.TCHAR	"string", 0
localize	"Name of the string field type.";

BinaryTypeString	chunk.TCHAR	"binary", 0
localize	"Name of the binary field type.";

GraphicTypeString	chunk.TCHAR	"graphic", 0
localize	"Name of the graphic field type.";

VMString	chunk.TCHAR	"VM", 0
localize	"String appended to the name of a database in order to derive the name of the associated file which contains any complex data.";

Strings		ends

