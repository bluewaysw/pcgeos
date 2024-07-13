COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Hilton
MODULE:		Pipeport
FILE:		pipeportBehaviors.asm

AUTHOR:		Robert Greenwalt, Nov 26, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/26/96   	Initial revision


DESCRIPTION:
		
	

	$Id: pipeportBehaviors.asm,v 1.1 97/04/04 17:54:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; A datastore pipe element may only access one db.  You pass the db
; name in at startup.  All startup infoWords MUST have a db in their buffer.
;
; DXIW_INITIALIZE
;	miscInfo - nothing
;	dataBuffer - null terminated database name
;


;
; DXIW_EXPORT
;
;   Keeps state.  When we first get this, we start exporting records
;   on a first-found first-sent basis.  The next contiguous EXPORT
;   sends the next.  If we get any other infoWord, we reset the state,
;   and a return to EXPORT starts the export over.
;
;


PipePort	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStorePipePortInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starting up a DS pipe port.  Try to lock datastore and
		open the db.

CALLED BY:	DXMain
PASS:		DataXBehaviorArguments on stack
		ds	= dgroup

		ds:[0]	- PipeElementHeader
		cx	- hptr of our data block
		es:[di]	- DataXInfo
RETURN:		ax 	= DXErrorType
DESTROYED:	everything except bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Load the DB - don't fail if it's already loaded exclusive

;	Aquire an Int Lock on the DB.  
		If another Int Lock exists
			fail - store null for the DB token
		else
			wait until all ext Locks are clear (denying
			new ones

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	12/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStorePipePortInitialize	proc	far args:DataXBehaviorArguments

	.enter
		les	di, args.DXBA_dataXInfo
	;
	; Error if the buffer is not null-terminated
	;
		mov	cx, es:[di].DXI_dataSize
		mov	es, es:[di].DXI_dataSegment
		clr	di, ax

DBCS<		shr	cx					>
DBCS<		repnz	scasw					>
SBCS<		repnz	scasb					>
		jnz	notNullTerminated

		clr	di, cx, dx, ax
		call	DataStoreOpen		; es:di = name
						; cx:dx = change
						;         notification
						;         optr
						; al  	= open flags
		jnc	noError
	;
	; Store the offending error into the miscinfo
	;
		les	di, args.DXBA_dataXInfo
		mov	es:[di].DXI_miscInfo.low, ax
	;
	; setup to store invalid token into the DSPPD_dsToken in our
	; custom data 
	;
		mov	ax, -1
noError:
		lds	si, args.DXBA_customData
		mov     ({DSPipePortData} ds:[si]).DSPPD_dsToken, ax

	;
	; *MUST* return either DXET_NOT_REENTRANT or DXET_REENTRANT
	; after initialize.
	;
		mov	ax, DXET_NOT_REENTRANT
done:
	.leave
	ret

notNullTerminated:
		mov	ax, DXET_FATAL_ERROR
		jmp	done

DataStorePipePortInitialize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStorePipePortCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform common startup checking for pipeport behaviors

CALLED BY:	DataStorePipePortExport, DataStorePipePortImport
PASS:		inherits DataXBehaviorArguments
		ds		= dgroup

RETURN:		carry set on error
		ax 		= error generated, or DataStore Token
			          if not 
		dx[CPU_ZERO]	= not set if 1st segment
		ds:[si] 	= CustomData
		es:[di]		= DataXInfo

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The first 

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	1/24/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStorePipePortCommon	proc	near
	uses	bx
	.enter inherit DataStorePipePortImport
	;
	; setup es:di and ds:si
	;
		lds	si, args.DXBA_customData
		les	di, args.DXBA_dataXInfo
	;
	; Check for a ds token
	;
		mov	ax, ds:[si].DSPPD_dsToken
		cmp	ax, -1
		jne	haveToken
		stc
		mov	es:[di].DXI_miscInfo.high, DSDE_INVALID_TOKEN
		mov	ax, DXET_DATABASE_ERROR
		jmp	done
haveToken:	
	; if there is a word in the common info about our last
	; operation, verify that they match
		mov	bx, ds:[si].DSPPD_lastAction
		cmp	bx, es:[di].DXI_infoWord
		pushf					; load flags
		pop	dx				; to dx
		je	dontDiscard			; they match
	;
	; nope, they don't match so lose the DataStore buffer (there
	; may not be one but who cares) -- save the token
	;
		mov	bx, ax
		call 	DataStoreDiscardRecord
		mov	ax, bx
dontDiscard:
	;
	; store current info word, or reset if last segment
	;
		mov	bx, DXIW_NULL
		test	es:[di].DXI_flags, mask DXF_FINAL
		jnz	storeInfoWord

		mov	bx, es:[di].DXI_infoWord
storeInfoWord:
		mov	ds:[si].DSPPD_lastAction, bx
		clc
done:
	.leave
	ret
DataStorePipePortCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStorePipePortShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shutting down..

CALLED BY:	DXMain
PASS:		DataXBehaviorArguments on stack
		ds	= dgroup
 
		ds:[0]	- PipeElementHeader
		cx	- hptr of PEH block
		es:[di]	- DataXInfo
RETURN:		ax	- DXErrorType (DXET_USE_INHERITED_BEHAVIOR to
				       complete the shutdown)
DESTROYED:	everything except bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	12/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStorePipePortShutdown	proc	far args:DataXBehaviorArguments
	.enter
ForceRef args
	;
	; Close any DS sesssion
	;
		call 	DataStorePipePortCommon
		jc	done
		call	DataStoreClose
done:
		mov	ax, DXET_USE_INHERITED_BEHAVIOR
	.leave
	ret
DataStorePipePortShutdown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStorePipePortDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to handle the default case of getting an
		unknown word

CALLED BY:	DXMAIN
PASS:		DataXBehaviorArgs on stack
		ds = dgroup
RETURN:		ax = DXErrorType
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	2/10/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStorePipePortDefault	proc	far args:DataXBehaviorArguments
	.enter
ForceRef args
		call 	DataStorePipePortCommon
		jc	done
		mov	ax, DXET_NO_ERROR
done:	
	.leave
	ret
DataStorePipePortDefault	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStorePipePortDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current transaction for the database upon
		receiving a singlular done message.

CALLED BY:	DXMAIN
PASS:		DataXBehaviorArgs on stack
		ds = dgroup
RETURN:		ax = DXErrorType
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	2/21/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStorePipePortDone	proc	far args:DataXBehaviorArguments
	.enter
ForceRef args
		call 	DataStorePipePortCommon
		jc	error
		call 	DataStoreGetCurrentTransactionNumber
		jc	error
	
		movdw	es:[di].DXI_miscInfo, dxcx		
		mov	ax, DXET_NO_ERROR
done:

	.leave
	ret
error:
		mov	es:[di].DXI_miscInfo.high, ax
		mov	ax, DXET_DATABASE_ERROR
		jmp	done
DataStorePipePortDone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStorePipePortSingleRecordExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a single record export

CALLED BY:	DXMAIN
PASS:		DataXBehaviorArgs on stack
		ds 	= dgroup
RETURN:		ax 	= DXErrorType
DESTROYED:	everything, except bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Get the ID
	Check to see if it contains DATA_EXCHANGE_NEW_RECORD (FFFF) 
	Send the database description if it does
	Else get the record, send it.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	2/24/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStorePipePortSingleRecordExport	proc	far \
					args:DataXBehaviorArguments
		dsToken	local	word
	uses	bp
	.enter
ForceRef args
	;
	; First, get the record id into dx.cx
	;	
		call	DataStorePipePortCommon
		jc	done

		mov	dsToken, ax			; save dsToken
		segmov	ds, es:[di].DXI_dataSegment, bx
		movdw	dxcx, ds:[RH_id]

		cmpdw	dxcx, DATA_EXCHANGE_NEW_RECORD
		jne	haveID
	;
	; The ID is DATA_EXCHANGE_NEW_RECORD, so send our database
	; definition
	;	
		call	SendDBDefinition
		jmp	done

haveID:
		call	DataStoreLoadRecord
		jc	databaseError
	
		mov	ax, dsToken			; restore dsToken
		mov	bl, mask DSEF_READ_LOCK		
		call	DMLockDataStore			; ^hcx <- record 
							;	  buffer
		jc	lockError
	;
	; ^hcx = handle to the record buffer.  
	; Copy it to the DataX buffer.
	; First, setup ds:si -> source
	;
		mov	bx, cx
		call 	MemLock
		mov	ds, ax
		mov	si, ds:[RLMBH_record]
		mov	si, ds:[si]
		mov	cx, ds:[si].RH_size
	;
	; Set the datax buffer size to the record size
	;
		pushdw	esdi
		push	cx
		call	DXSetDXIDataBufferSize
		jc	memError

	; 
	; ds:si already points to source, point es:di to destination.
	;
		mov	es, ax
		clr	di
	;
	; copy
	;
		shr	cx
		jnc	evenByteCount
		movsb
evenByteCount:
		rep movsw

	;
	; restore si, unlock the record block, and indicate no error
	; in cx
	;		
		call 	MemUnlock
		mov	cx, DXET_NO_ERROR

unlockAndDiscard:
	; cx = DXET_xxx 
	;
		mov	ax, dsToken			; restore dsToken
		call	DMUnlockDataStore
discard:
	; cx = DXET_xxx
		mov	ax, dsToken			; restore dsToken
		call	DataStoreDiscardRecord
		jnc	done		
	;
	; if there was an original error, and this erred out, don't
	; overshadow the original error, otherwise note this error
		cmp	cx, DXET_NO_ERROR
		je	databaseError
done:
	;
	; cx = DXET_xxx
	;
	mov	ax, cx

	.leave
	ret

memError:
	; A mem alloc error occured.
	;
		mov	cx, DXET_MEM_ALLOC_ERROR
		jmp	unlockAndDiscard

lockError:
	; An error occured from DMLockDataStore
	; bx = error
	;
		mov	es:[di].DXI_miscInfo.high, bx
		mov	cx, DXET_DATABASE_ERROR		
		jmp	discard
	

databaseError:
	; A database error occured.  
	; ax = error
	;
		mov	es:[di].DXI_miscInfo.high, ax
		mov	cx, DXET_DATABASE_ERROR
		jmp	done

DataStorePipePortSingleRecordExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDBDefinition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The Field Names are in an ElementArray.  DataStore API
		access functions try to lock down each one, which will
		be slow.  So we need to lock the ElementArray, try every 
		entry and add the name to the field data each time.

CALLED BY:	DataStorePipePortSingleRecordExport
PASS:		ax 		= dsToken
		es:[di]		= DataXInfo
		inherit from DataStorePipePort
RETURN:		cx = DXET error code
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	2/25/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendDBDefinition	proc	near
	uses	bx
	.enter inherit DataStorePipePortSingleRecordExport
	;
	;  point es to the data buffer	
	;
		segmov	es, es:[di].DXI_dataSegment

	;
	; lock down the database to get the file handle	
	;
		mov	bl, mask DSEF_READ_LOCK
		call	DMLockDataStore		; ^hbx <- file handle
		jc	lockError	

		call	LockFieldNameElementArray
		
	;
	; Initialize our search (ax) to 0, initialize the buffer size
	; (dx) to 0
	;
		clr	ax, dx
loopTop:
		call	CheckValidFieldElement
		jc 	invalidFieldElement

		call	ChunkArrayElementToPtr	; cx <- size of element
						; ds:di <- element
		push	si
		lea	si, ds:[di].FNE_name	; ds:si <- name w/o NULL
	;
	; Get the # bytes to copy
	;
		sub	cx, size FieldNameElement ;cx <- length of name

		les	di, args.DXBA_dataXInfo
		push	dx			; store end of buffer
		push	ax			; save fieldID counter
		add	dx, cx
		add	dx, size FieldHeader
		pushdw	esdi
		push	dx
		call	DXSetDXIDataBufferSize
		jc	memError

		mov	es, ax
		pop	ax
		pop	di			; es:di <- buffer ptr

		mov	es:[di].FH_id, al
		mov	es:[di].FH_size, cx
		add	di, size FieldHeader	; es:di <- string ptr

		shr	cx
		jnc	evenByteCount
		movsb
evenByteCount:
		rep	movsw
	
		pop	si
invalidFieldElement:
		inc	ax
		cmp	ax, 0x0100
		jb	loopTop

unlockDataBase:
	;
	; unlock the database
	;
		call	VMUnlockDS

		mov	ax, dsToken
		call 	DMUnlockDataStore

		mov	cx, DXET_NO_ERROR				

done:
	.leave
	ret

memError:
	;
	; a memory error occured
	;
		pop	si
		pop	di
		pop	ax
		mov	cx, DXET_MEM_ALLOC_ERROR
		jmp	unlockDataBase

lockError:
	; An error occured from DMLockDataStore
	; bx = error
	;
		mov	es:[di].DXI_miscInfo.high, bx
		mov	cx, DXET_DATABASE_ERROR		
		jmp	done

SendDBDefinition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportSendFirstCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shorthand function to send the first _ALL or _PARTIAL 
		DXIW
CALLED BY:	DataStorePipePortExport
PASS:		es:di	= DataXInfo
		si	= InfoWord to pass
		bp	= offset to arguments
RETURN:		on error:
			carry set
			ax = DXET Value
		not error:
			carry clear
			ax unchanged

DESTROYED:	si
		ax on error
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	2/18/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportSendFirstCommand	proc	near
	.enter
		mov	es:[di].DXI_infoWord, si
		mov	si, 0
		push	ax
		pushdw	esdi
		push	si
		call	DXSetDXIDataBufferSize
		pop	ax
	;	jc	memError			; I'm going to
							; omit this
							; since I KNOW
							; I'm setting
							; the size to
							; 0, and that
							; had better
							; NOT fail!
		pushdw	ssbp
		call	DXManualPipeCycle
	;
	; We have just received data back from the pipe.  Check to
	; make sure the protocol has been followed.  If we get an
	; export, continue the export, otherwise check for a DONE.  If
	; it's a DONE, stop the export and return immediately.
	; Otherwise setup as though we err'ed out in the callback routine.
	;
		cmp	es:[di].DXI_infoWord, DXIW_EXPORT
		je	done

		cmp	es:[di].DXI_infoWord, DXIW_DONE
		jne	invalidDXIW
		mov	ax, DXET_NO_ERROR
		jmp	setError		
invalidDXIW:
		mov	ax, DXET_INVALID_DXIW
setError:
		stc	
done:
	.leave
	ret
ExportSendFirstCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStorePipePortExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performing an export

CALLED BY:	DXMain
PASS:		inherits DataXBehaviorArguments
		ds	= dgroup
RETURN:		ax 	= DXErrorType
DESTROYED:	everything, except bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Verify that we can do an export (have ds token)
	
	Check the expr date (see if we have to do all)

	Start enum with callback - it'll take care of running the pipe
		until we are done.
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg		12/ 5/96    	Initial version
	tgautier	1/30/97		Segmented Export, Shutdown correctly

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStorePipePortExport	proc	far args:DataXBehaviorArguments
	uses	bp
	.enter
	;
	; call common code
	;
		call	DataStorePipePortCommon
		jc	done
	
		add	bp, offset args			; ss:[bp] = args
	;
	; Check the transaction # to see if we should do a full or
	; partial export, but first store the original transaction #.
	;
		movdw	dxcx, es:[di].DXI_miscInfo
		movdw	ds:[si].DSPPD_transaction, dxcx
		push	si
		tstdw	dxcx
		jz	sendAll				; Send All
							; Records if
							; they asked
							; since
							; transaction 0
		call	DLFindDeletedSince		; can't send
							; changes if
							; carry set
		
		jc	sendAll
	;
	; Send Changes 
	; Send the DXIW_PARTIAL_RECORDS response
	;
		add	sp, 2				; lose the push si
		push	si
		mov	si, DXIW_PARTIAL_RECORDS
		call	ExportSendFirstCommand
		pop	si
		jc	incompleteExportStoreError
				
loopTop:
		tstdw 	bxsi
		jz	startEnum
	;
	; Set the buffer size (must do this each time because they
	; will be sending an export message which can (usually or
	; does) have a data buffer size of 0)
	;
		push	ax, cx
		mov	cx, size RecordHeader
		pushdw	esdi
		push	cx
		call	DXSetDXIDataBufferSize
		mov	ds, ax
		pop	ax, cx
		jc	memError

	;
	; Fill in RecordHeader fields		
	;
		movdw	ds:[0].RH_id, bxsi
		mov	ds:[0].RH_size, size RecordHeader
		mov	ds:[0].RH_fieldCount, 0
	;
	; Send the data
	; 
		pushdw	ssbp
		call	DXManualPipeCycle
		cmp	es:[di].DXI_infoWord, DXIW_EXPORT
		jne	partialExportNotExportDXIW
	;	
	; We got back an EXPORT, so keep going
	;
		call	DLFindDeletedSince
		tstdw	bxsi
		jmp	loopTop	

partialExportNotExportDXIW:
	;
	; The pipe protocol was violated in the middle of exporting
	; deletions.  Check it and do the appropriate thing.
	;
		cmp	es:[di].DXI_infoWord, DXIW_DONE
		jne	partialExportInvalidDXIW
		mov	ax, DXET_NO_ERROR
		jmp	incompleteExportStoreError

partialExportInvalidDXIW:	
		mov	ax, DXET_INVALID_DXIW
		jmp	incompleteExportStoreError

sendAll:
	;
	; We send all records from here.  First, put a 0 into the
	; transaction (indicating export all) for our export enum function.  
	;
		pop	si
		movdw	ds:[si].DSPPD_transaction, 0
	;
	; Send off the DXIW_ALL_RECORDS message
	;
		mov	si, DXIW_ALL_RECORDS
		call	ExportSendFirstCommand
		jc	incompleteExportStoreError
	;
	; Get Ready to export all records
	;		
startEnum:
		push	di				; save DataXInfo offset
		mov	bx, vseg ExportSendRecords
		mov	di, offset ExportSendRecords
		clr	dx, cx				; start from
							; earliest record
		mov	si, mask DSREF_START_AT_END
		call	DataStoreRecordEnum
		pop	di
		jc	dataStoreError			; check for
							; DataStore error
	;
	; Check for full export
	;
		cmp	ax, DSE_NO_MORE_RECORDS
		jne	incompleteExport
		mov	es:[di].DXI_infoWord, DXIW_DONE
		jmp	callBehavior

incompleteExportStoreError:
		mov	es:[di].DXI_miscInfo.low, ax
incompleteExport:
	;
	; the export call back quits with the error type in the
	; low word of miscInfo.  Make sure the infoWord wasn't a 
	; shutdown, because otherwise we need to process it.
	;
		cmp	es:[di].DXI_infoWord, DXIW_CLEAN_SHUTDOWN
		je	callBehavior
		cmp	es:[di].DXI_infoWord, DXIW_DONE
		je	callBehavior
		mov	ax, es:[di].DXI_miscInfo.low
		jmp	done
callBehavior:
		pushdw	ssbp
		call 	DXManualBehaviorCall
		jmp	done

memError:		
		mov	ax, DXET_MEM_ALLOC_ERROR
		jmp	done

dataStoreError:
		mov	es:[di].DXI_miscInfo.high, ax
		mov	ax, DXET_DATABASE_ERROR

done:
	.leave
	ret
DataStorePipePortExport	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStorePipePortImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performing an import.

CALLED BY:	DXMain
PASS:		inherits DataXBehaviorArguments
		ds	= dgroup
RETURN:		ax 	= DXErrorType

DESTROYED:	everything except bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Importing a single record - may be unfriendly		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	12/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStorePipePortImport	proc	far args:DataXBehaviorArguments
	uses	bp		; everything else can be destroyed

	.enter
	;
	; Call our common code
	;
		call	DataStorePipePortCommon		; carry set on error 
							; ax = error
							; carry clear no error
							; ax = dsToken
							; es:[di] = DataXInfo
							; ds:[si] = CustomData
							; dx.0	  = not set if 
							;           first seg

		jc	done

	;
	; mov es:di to ds:si
	;
		mov	si, di
		segmov	ds, es, di
	;
	; Setup es to point to beginning of data buffer
	;
		mov	bx, ds:[si].DXI_dataSegment
		mov	es, bx
	;
	; save dsToken
	;
		mov	di, ax
	;
	; Check the import type - friend or foe?
	;
	; <not implemented>

	;
	; Check if this is the first segment.
	;
		push	dx
		popf
		jnz	firstSegment
	;
	; Setup bx for fieldLoop and start iterating fields
	;
		mov	bx, 0	
		jmp	startLoop

firstSegment:
	;
	; Check if this is a new record or not
	;
		cmp	{word}es:[RH_id], DATA_EXCHANGE_NEW_RECORD
		jne	haveID
		cmp	{word}es:[RH_id].2, DATA_EXCHANGE_NEW_RECORD
		je	newRecord

haveID:
	;
	; Load dxcx with the record id
	;
		movdw	dxcx, es:[RH_id]
	;
	; Check if this record should be deleted -- there will be no
	; fields specified in the record header
	;
		tst	es:[RH_fieldCount]
		jnz	loadRecord
	;	
	; there are no fields, delete the record
	;
		call 	DataStoreDeleteRecord
		cmp	ax, DSDE_NO_ERROR
		je	dataStoreNoError
		jmp	dataStoreError

	;
	; ok, load record because everything checks out and we're not 
	; deleting it
	;
loadRecord:
		call	DataStoreLoadRecord
		jc	dataStoreError
		jmp	fieldLoop

newRecord:
		call	DataStoreNewRecord
		jc	dataStoreError

	;
	; Now, loop through all the fields we're given and make the changes
	;
fieldLoop:
		mov	bx, offset RH_fieldData

startLoop:
	;
	; bx  	= offset of field data
	; di	= dsToken
	; es	= data segment
	;
		push 	ds
		push	bp, si
		mov	bp, ds:[si].DXI_dataSize
		mov	ds, di			; put dsToken into ds
						; bp = size of buffer
		mov	si, bx			; es:si = first field
		clr	bx			; set bx to 0 for 
						; DataStoreSetField
loopTop:
		cmp	si, bp
		jnc	loopEnd
		mov	dl, es:[si].FH_id
		call	ImportFieldPrep		; es:[di] = field data
						; es:[si] = next field
						; cx = field size
		mov	ax, ds			; Reset ax to dsToken
		call	DataStoreSetField
		cmp	ax, DSDE_NO_ERROR
		je	loopTop
		pop	bp, si
		jmp	dataStoreErrorDiscard

loopEnd:
		pop	bp, si
		pop	ds
		clr	cx			; no callback
	;
	; Check if it's the final segment.
	;
		mov	dx, ds:[si].DXI_flags
		test	dx, mask DXF_FINAL
		jz	notFinalSegmentDontSave
		
		call	DataStoreSaveRecord
		jc	dataStoreErrorDiscard

notFinalSegmentDontSave:
		pushdw	dssi
		mov	ax, size RecordHeader
		push	ax
		call	DXSetDXIDataBufferSize
		jc	memError
		movdw	ds:[si].DXI_miscInfo, bxcx	; return the ID
		jmp	dataStoreNoError

dataStoreErrorDiscard:
	;
	; We had a problem and have a record in the buffer - remove it
	;
		push	ax			; save the first error
		mov	ax, ds			; reload dsToken
		call	DataStoreDiscardRecord
		cmp	ax, DSDE_NO_ERROR	; paranoid mode :)
		jne	dataStoreErrorDiscardFailed
		pop	ax
		pop	ds
		jmp	dataStoreError

dataStoreErrorDiscardFailed:
		pop	ds			; toss first error
		pop	ds
		
		
dataStoreError:
	;
	; There has been a DataStore error.  Put the offending error
	; into the miscinfo, put DXET_DATABASE_ERROR into ax, and
	; return
	;
		mov	ds:[si].DXI_miscInfo.high, ax
		mov	ax, DXET_DATABASE_ERROR
		les	di, args.DXBA_customData
		mov	ds:[si].DSPPD_lastAction, DXIW_NULL
		jmp 	done

memError:
		mov	ax, DXET_MEM_ALLOC_ERROR
		jmp	done

dataStoreNoError:
	;
	; No error generated
	;
		mov	ax, DXET_NO_ERROR
done:
	.leave
	ret
DataStorePipePortImport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportFieldPrep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some messy stuff in prep for field import

CALLED BY:	DataStorePipePortImport
PASS:		ax	= DS Token
		dl	= field ID
		es:[si]	= FieldHeader or FieldHeaderFixed
RETURN:		carry set on error
			es:[si] = after current Field (next
					FieldHeader if not the last,
					else garbage)
			es:[di] = current field data
			cx	= field size (if variable)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	12/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportFieldPrep	proc	near
	uses	ax,bx,dx
	.enter
		mov	bl, mask DSEF_WRITE_LOCK
		push	ax
		call	DMLockDataStore		; bx = file handle
						; cx = buffer handle
		jc	done

		call	DSGetFieldInfoByID	; ax = field size, 0
						; 	if variable
						; cl = header size
						; ch = field flags
						; dl = field type
						; dh = field category
		mov	di, ax
		pop	ax
		call	DMUnlockDataStore	; preserves flags
		pushf
		tst	di
		jz	variableField
	;
	; Fixed field length - size in di
	;
		add	si, offset FHF_data
		add	di, si
		xchg	di, si		; si = next record, di =
					; current data
		jmp	almostDone
variableField:
		mov	di, si
		add	di, offset FH_data
		mov	cx, es:[si].FH_size
		add	si, cx
		sub	cx, size FieldHeader
almostDone:
		popf
done:
	.leave
	ret
ImportFieldPrep	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportSendRecords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enum function called to export records

CALLED BY:	DataStoreRecordEnum
PASS:		bp 	- stack ptr to DataXBehaviorArguments args
		ds:di	- RecordHeader
RETURN:		carry set to stop the enum
DESTROYED:	nothing!
SIDE EFFECTS:	sends stuff down the pipe
		if we run across a non _EXPORT infoWord we will stop
		if we have an error, we will store the error info and stop

PSEUDO CODE/STRATEGY:
		Copy a record
		V the sem
		P the sem
		check for continuation - if not, bail
		return carry clear to get the next record

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	12/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportSendRecords	proc	far
	uses	ax, bx, cx, dx, es, di, ds, si
	.enter
	;
	; move source pointer to ds:si
	; load dx with total record size
	;
		mov	si, di			; ds:si = source
		mov	dx, ds:[si].RH_size

	;
	; Check the transaction #
 	
	 	les	di, ss:[bp].DXBA_customData
		movdw	bxcx, es:[di].DSPPD_transaction
		tstdw	bxcx
		jz	enumRecord
	;
	; loadup the number of the record.  Continue if it is greater
	; than (or equal?) to the bxcx

		cmp	bx, {word}ds:[si].FHF_data.(size RecordHeader + 2)
		jb	enumRecord
		cmp	cx, {word}ds:[si].FHF_data.(size RecordHeader)
		jb	enumRecord
		clc
		jmp 	done

enumRecord:
	;
	; load up es:di -> DataXInfo
	;
		les	di, ss:[bp].DXBA_dataXInfo	
	;
	; Let's put the whole size of the record into miscInfo for the
	; hell of it
		mov	es:[di].DXI_miscInfo.high, dx

loopTop:
	; ds:si   = source 
	; es:[di] = DataXInfo
	;
		cmp	dx, MAX_EXPORT_SIZE
		jbe	lastSegment	
	;
	; Yep, we're segmented
	;
		mov	es:[di].DXI_flags, 0
		mov	cx, MAX_EXPORT_SIZE
		jmp	copyBuffer
		
lastSegment:
	;
	; last (or only) segment in buffer
	;
		mov	es:[di].DXI_flags, mask DXF_FINAL
		mov	cx, dx
		
copyBuffer:
	; Copy the buffer, may be only a piece
	; es:di = DataXInfo  (copy goes to es:di->DXI_dataSegment
	; ds:si = source
	; cx = size to copy
	; dx = total size to copy
	;
		xchg	si, di	
		pushdw	essi	
		push	cx
		call 	DXSetDXIDataBufferSize		
		jc	memError
		xchg	si, di
	;
	; point es:[di] to the destination
	;
		mov	bx, es:[di].DXI_dataSegment
		mov	es, bx
		mov	di, 0

		sub	dx, cx
		shr	cx
		jnc	evenByteCount
		movsb
evenByteCount:
		rep movsw
	;
	; Now send it
	;
		pushdw	ssbp
		call	DXManualPipeCycle
	;
	; Check for continuation
	;
		les	di, ss:[bp].DXBA_dataXInfo
		cmp	es:[di].DXI_infoWord, DXIW_EXPORT
		jne	mismatchedInfoWord
	;
	; are continuing, have we done the whole buffer?
	;
		tst	dx
		jnz	loopTop
		clc
		jmp 	done

mismatchedInfoWord:
	;	
	; signal the error in the InfoWord, no error if DXIW_DONE
	;
		cmp	es:[di].DXI_infoWord, DXIW_DONE
		je	noError
		mov	es:[di].DXI_miscInfo.low, DXET_INVALID_DXIW
		jmp	notContinuing

noError:
		mov	es:[di].DXI_miscInfo.low, DXET_NO_ERROR
		jmp 	notContinuing
	
memError:
	;
	; signal the error in high word of miscInfo
	;
		mov	es:[si].DXI_miscInfo.low, DXET_MEM_ALLOC_ERROR

notContinuing:
		stc

done:
	.leave
	ret
ExportSendRecords	endp

PipePort	ends
