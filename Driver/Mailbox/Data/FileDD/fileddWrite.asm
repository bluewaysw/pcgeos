COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		File Data Driver
FILE:		fileddWrite.asm

AUTHOR:		Chung Liu, Oct 11, 1994

ROUTINES:
	Name			Description
	----			-----------
	FileDDWriteInitialize  
	FDDAllocWriteStateLocked
	FDDCreateFileAndUpdateWriteState
	FDDCheckIfNative
	FDDWriteFileData
	FileDDWriteNextBlock    
	FileDDWriteComplete     
	FileDDWriteCancel

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/11/94   	Initial revision


DESCRIPTION:
	The IRS.
		

	$Id: fileddWrite.asm,v 1.1 97/04/18 11:41:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDWriteInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the first call issued by the transport driver before
		receiving a message. It effectively passes to the receiving
		data driver the values that were returned from the sending
		data driver's DR_MBDD_READ_INITIALIZE function. As for
		reading, the driver is expected to allocate some state
		information to track the transaction.

		The driver returns a suitable 16-bit token for the transport
		driver to identify the message body more efficiently on
		subsequent calls.

CALLED BY:	DR_MBDD_WRITE_INITIALIZE
PASS:		bx	= number of blocks in the message
		cxdx	= number of bytes in the message body
RETURN:		carry set if body could not be accessed:
			ax	= MailboxError
			si	= destroyed
		carry clear if ok:
			si	= token to pass to subsequent calls
			ax	= destroyed

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Allocate a write state block, and go on ahead, because we can't
	open the file until we receive the extended attributes block.
		
	XXX: It would be a good idea to check if there's that much room
	to write the file...  Add later.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDWriteInitialize	proc	far
	uses	bx,cx,di
	.enter
	clr	cx			 	;don't have a filename yet.
	call	FDDAllocWriteStateLocked 	;ds:si = FileDDWriteState
					 	; di = state token
	clr	ds:[si].FWS_fileHandle
	clr	ds:[si].FWS_extAttrs
	mov	si, di

	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared
	.leave
	ret
FileDDWriteInitialize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDAllocWriteStateLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a FileDDWriteState chunk in the readWriteStateBlock
		segment.  Returns with the segment of the chunk locked.
		Caller must MemUnlockShared the segment when done 
		accessing the chunk.

CALLED BY:	FileDDWriteInitialize
PASS:		cx	= filename length
RETURN:		ds	= segment address
		di	= chunk handle for FileDDWriteState
		ds:si 	= FileDDWriteState
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDAllocWriteStateLocked	proc	near
		uses	ax,bx,cx
		.enter
	mov	bx, handle FileDDState
	;
	; Use exclusive access so that threads don't hose each other
	; by causing the state block to move.
	;
	call	MemLockExcl
	mov	ds, ax
	add	cx, size FileDDWriteState
	call	LMemAlloc
	mov	di, ax			;di = handle of chunk
	mov	si, ds:[di]

	call	MemDowngradeExclLock
	.leave
	ret
FDDAllocWriteStateLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDWriteNextBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the next block of data to the message body. The
		driver may either consume the data block, taking responsibility
		for it and its handle, or it may allow the caller to free the
		block on return.
CALLED BY:	
PASS:		si	= token returned by DR_MBDD_WRITE_INITIALIZE
		dx	= extra word returned by DR_MBDD_READ_NEXT_BLOCK on
			  sending machine
		cx	= number of bytes in the block
		bx	= handle of data block
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			ax	= 0 if data block has been consumed. non-zero
				  if block should be freed by caller.


DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDWriteNextBlock	proc	far
	uses	bx,ds,di
	.enter
	;
	; Check if we have a file handle yet.  This will indicate if
	; the file has been opened.
	;
	call	FDDStateLock			;ds:di = *ds:si = write state.
	tst 	ds:[di].FWS_fileHandle
	jnz	writeFileData

	call	FDDCreateFileAndUpdateWriteState	;ds may have moved
	jmp	unlockAndExit

writeFileData:
	
	call	FDDWriteFileData

unlockAndExit:
	;
	; Unlock the state block.
	;
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared		;flags preserved.
		
	.leave
	ret
FileDDWriteNextBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDCreateFileAndUpdateWriteState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a file with the correct attributes.

CALLED BY:	FileDDWriteNextBlock
PASS:		ds:di 	= FileDDWriteState
		si	= chunk handle of write state
		^hbx	= array of FileExtAttrDesc
		cx	= size of data
		dx	= number of entries in array
RETURN:		carry clear if okay:
			ax	= 0 if data block has been consumed. non-zero
				  if block should be freed by caller.
			ds 	= may have moved.
		carry set if error:
			ax	= MailboxError
				 ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDCreateFileAndUpdateWriteState	proc	near
writeState	local	dword			push ds, si
attrsBlock	local	hptr			push bx
numAttrs	local	word			push dx
newFile		local	PathName
fileHandle	local	hptr
diskHandle	local	word
	uses	bx,cx,dx,si,es,di
	.enter
	;
	; Create a file, perhaps in native mode, depending on the
	; attributes we received.
	;
	clr	ax
	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_WRITE_ONLY>
	mov	cx, FILE_ATTR_NORMAL 
	call	FDDCheckIfNative		;carry set if native dos file
	jnc	create
	mov	ah, mask FCF_NATIVE

create:
	segmov	ds, ss
	lea	dx, newFile			;ds:dx = filename buffer
	call	FDDCreateInMailboxDir		;ds:dx filled in
						;  ax = file handle,
						;  bx = disk handle
	LONG jc	fileOpenError
	mov	fileHandle, ax
	mov	diskHandle, bx

	;
	; Resize the state block to hold the filename we just got.
	;
	movdw	esdi, dsdx
	push	es, di			;save ptr for copying later.
	call	LocalStringSize		;cx = size w/o null
	inc	cx			;include null
DBCS <	inc	cx					>

	add	cx, size FileDDWriteState
	movdw	dsax, writeState	;*ds:ax = write state 
	call	LMemReAlloc		;ds may have moved, ax resized.
EC <	ERROR_C	-1					>

	;
	; Fill in the state info we have acquired.
	;
	segmov	es, ds
	mov	di, ax
	mov	di, es:[di]			;es:di = write state
	mov	ax, fileHandle
	mov	es:[di].FWS_fileHandle, ax
	mov	ax, diskHandle
	mov	es:[di].FWS_diskHandle, ax
	mov	ax, attrsBlock
	mov	es:[di].FWS_extAttrs, ax
	mov	ax, numAttrs
	mov	es:[di].FWS_extAttrsCount, ax
	clr	es:[di].FWS_error
	sub	cx, size FileDDWriteState
	mov	es:[di].FWS_filenameLen, cx
		
	;now copy the filename
	add	di, offset FWS_filename		;es:di = dest.
	pop	ds, si				;ds:si = newFile
	LocalCopyString

	; return new state segment (moved)
	segmov	ds, es	
	
	; block was consumed -- data driver will free it later.
	mov	ax, 0
	clc	
exit:
	.leave
	ret

fileOpenError:
	mov	ax, ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY	
	jmp	exit
FDDCreateFileAndUpdateWriteState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDCheckIfNative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if extended attributes array specifies native mode.

CALLED BY:	FDDCreateFileAndUpdateWriteState
PASS:		^hbx	= array of FileExtAttrDesc
		dx	= number of attributes
RETURN:		carry set if an attribute specifies native mode.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDCheckIfNative	proc	near
	uses	ds,si,es,di,ax,cx
	.enter
	call	MemLock
	mov	ds, ax
	clr	si
	mov	cx, dx
attrLoop:
	cmp	ds:[si].FEAD_attr, FEA_FILE_TYPE
	je	checkType
	add	si, size FileExtAttrDesc
	loop	attrLoop

	; native DOS files may not come with a FEA_FILE_TYPE attribute.
	stc
exit:
	call	MemUnlock		;flags preserved.
	.leave
	ret

checkType:
	;
	; ds:si = FileExtAttrDesc of FEA_FILE_TYPE
	;
	mov	di, ds:[si].FEAD_value.offset
	mov	ax, ds:[di]
	cmp	ax, GFT_NOT_GEOS_FILE
	je	dosFile
	;
	; We have in our hands a GEOS file, after all.
	;
	clc
	jmp	exit

dosFile:
	stc
	jmp	exit
FDDCheckIfNative	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDWriteFileData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write data to the file.

CALLED BY:	FileDDWriteNextBlock
PASS:		^hbx	= data
		cx	= size
		ds:di	= FileDDWriteState
RETURN:		carry clear if okay:
			ax	= 0 if data block has been consumed. non-zero
				  if block should be freed by caller.
		carry set if error:
			ax	= MailboxError
				ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDWriteFileData	proc	near
	uses	es,ds,bx,cx,dx
	.enter
	;
	; If we have already encountered an error, don't proceed.
	;
	segmov	es, ds				;es:di = write state
	tst	es:[di].FWS_error
	jnz	errorAlready
	;
	; Lock down the block of data.
	;
	push	bx				;save to unlock
	call	MemLock
	mov	ds, ax
	clr	dx				;ds:dx = buffer to write
	;
	; Write the block data to the file.
	;
	mov	bx, es:[di].FWS_fileHandle	;bx = file handle
	clr	ax				;errors okay

	;cx = number of bytes to write.
	call	FileWrite
	jc	fileWriteError
	
	mov	ax, 1				;we didn't consume the block.
		
unlockAndExit:
	; unlock the data block
	pop	bx
	call	MemUnlock			;flags preserved

exit:
	.leave
	ret

fileWriteError:
	;
	; es:di = write state
	; ax = FileError
	;
	mov	es:[di].FWS_error, ax
	mov	ax, ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
	jmp	unlockAndExit

errorAlready:
	mov	ax, ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
	stc
	jmp	exit
	
FDDWriteFileData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDWriteComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signals to the data driver that the reception of the
		message body is complete. The driver may free the state
		information it allocated in DR_MBDD_WRITE_INITIALIZE.

CALLED BY:	DR_MBDD_WRITE_COMPLETE
PASS:		si	= token returned by DR_MBDD_WRITE_INITIALIZE
		cx:dx	= pointer to buffer for app-ref of body (size 
			  determined by MBDDI_appRefSize).
RETURN:		carry set if message body couldn't be commited to
		disk:
			ax	= MailboxError
				ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
		carry clear if message body successfully committed.
			cx:dx	= filled with app-ref to the data.
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDWriteComplete	proc	far
stateChunk	local	word			push si
	uses	bx,cx,dx,ds,si,es,di
	.enter
	call	FDDStateLock			
	mov	si, di				;ds:si = FDDWriteState
	movdw	esdi, cxdx			;es:di = appRef.
	;
	; place disk handle in the app-ref.
	;
	mov	bx, ds:[si].FWS_diskHandle
	mov	es:[di].FAR_diskHandle, bx

	mov	bx, ds:[si].FWS_fileHandle
	clr	ax				;errors okay
	call	FileClose
	jc	closeError
	;
	; Check if an error happend during write-next.
	;
	tst	ds:[si].FWS_error
	jnz	writeNextError	
	;
	; Set the attributes of the file, then get rid of the ext. attrs
	; block.
	;
	mov	ax, ds:[si].FWS_diskHandle	
	mov	bx, ds:[si].FWS_extAttrs	;^hbx = ext. attrs.
	mov	cx, ds:[si].FWS_extAttrsCount
	mov	dx, si
	add	dx, offset FWS_filename		;ds:dx = filename

	call	FDDFileSetExtAttributes
	jc	setExtAttrsError		

	;
	; Free the extended attributes block.
	;
	call	MemFree	
	;
	; copy the filename to the app-ref
	;
	add	si, offset FWS_filename	;ds:si = source filename
	add	di, offset FAR_filename	;es:di = dest. filename
	LocalCopyString
	clc		
		
exit:
	;
	; Free the state segment.  Save flags, and ax, which could be
	; a MailboxError.
	; 	
	pushf
	push	ax
	mov	ax, stateChunk		;free the write state
	call	LMemFree
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared
	pop	ax
	popf
	.leave
	ret

writeNextError:
closeError:
setExtAttrsError:
	;
	; ds:si = write state.  
	; An error happened during DR_MBDD_WRITE_NEXT, or FileClose, or when
	; we tried to set the file's extended attributes.  We need to delete 
	; the file and return error.  Oh, don't forget to free the extended
	; attributes block.
	;
	mov	bx, ds:[si].FWS_extAttrs
	call	MemFree

	mov	bx, ds:[si].FWS_diskHandle
	add	si, offset FWS_filename		;ds:si = filename
	call	FDDFileDelete
	stc
	;
	; ds = state segment
	;
	mov	ax, ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
	jmp	exit
		
FileDDWriteComplete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDWriteCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel the write process, clean up, free up, delete.

CALLED BY:	DR_MBDD_WRITE_CANCEL
PASS:		si	= token returned from DR_MBDD_WRITE_INITIALIZE
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Delete the file
	Free the state chunk
	Free the extended attributes block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDWriteCancel	proc	far
	uses	ax,bx,ds,si,di
	.enter
	push	si				;save the state chunk
	call	FDDStateLock			;ds:di = state
	mov	si, di				;ds:si = state
	;
	; If we have an extended attributes block, then free it.
	;
	mov	bx, ds:[si].FWS_extAttrs
	tst	bx
	jz	deleteFile
	call	MemFree

deleteFile:
	;
	; Delete the temp file that was created to hold the data.
	;
	mov	bx, ds:[si].FWS_diskHandle
	add	si, offset FWS_filename		;ds:si = filename
	call	FDDFileDelete
	;
	; Return the state chunk to the great pool
	;
	pop	ax				;ax = state chunk
	call	LMemFree
	mov	bx, ds:[LMBH_handle]		;bx = state block
	call	MemUnlockShared

	.leave
	ret
FileDDWriteCancel	endp

Movable		ends	





