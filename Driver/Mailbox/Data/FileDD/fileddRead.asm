COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		File Data Driver
FILE:		fileddRead.asm

AUTHOR:		Chung Liu, Oct 11, 1994

ROUTINES:
	Name			Description
	----			-----------
	FileDDReadInitialize   
	FDDAllocReadStateLocked
	FileDDReadNextBlock 
	FDDReadExtendedAttributes
	FDDReadFileData  
	FileDDReadComplete     

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/11/94   	Initial revision


DESCRIPTION:
	Embodiement of the Freedom of Information Act.

	The first call to FileDDReadNextBlock returns the extended 
	attributes block for the file, with the extra word being the 
	count of attributes in the attributes block.  
	Likewise, the first call to FileDDWriteNextBlock after FileDD
	WriteInit expects the extended attributes block and size.
			

	$Id: fileddRead.asm,v 1.1 97/04/18 11:41:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDReadInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate message body and prepare to fetch blocks of 
		data from the message body.

CALLED BY:	DR_MBDD_READ_INITIALIZE
PASS:		cx:dx	= pointer to mboxRef for the message body
RETURN:		carry set if body could not be accessed:
			ax	= MailboxError
		carry clear if ok:
			si	= token to pass to subsequent calls
			bx	= number of blocks in the message
			cxdx	= number of bytes in the message body
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDReadInitialize	proc	far
numBlocks	local	word
	uses	di,ds,es
	.enter
	; get the disk data and the filename so we can open the file.
	mov 	es, cx
	mov	di, dx
	add	di, es:[di].FMR_diskDataOffset	;es:di = disk data

	mov	ds, cx
	add	dx, FMR_filenameAndDiskData	;ds:dx = filename

	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	call	FDDFileOpenWithDiskData		;ax = file handle
	jc	fileOpenError

	mov	bx, ax				;bx = GEOS file handle
	call	FileSize			;dx:ax = size of file.
		
	;dx:ax = file size; file handle.
	push	dx, ax, bx			;save to return

	;determine number of blocks
	mov	cx, FILE_DATA_DRIVER_BLOCK_SIZE
	div	cx				;ax = quotient, dx = remainder
	tst	dx
	jz	noRemainder
	inc	ax

noRemainder:
	inc	ax				;add the ext. attributes block
	mov	numBlocks, ax

	pop	cx, dx, bx			;cx:dx = number of bytes
						;  bx = file handle
	call	FDDAllocReadStateLocked		;*ds:di = FileDDReadState
	mov	si, di				;si = read token to return
	mov	di, ds:[di]
	mov	ds:[di].FRS_fileHandle, bx
	clr	ds:[di].FRS_sentExtAttrs
	mov	bx, ds:[LMBH_handle]	
	call	MemUnlockShared
	
	; return bx = number of blocks
	mov	bx, numBlocks
	clc	
exit:
	.leave
	ret

fileOpenError:
	mov	ax, ME_DATA_DRIVER_CANNOT_ACCESS_MESSAGE_BODY
	jmp	exit
FileDDReadInitialize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDAllocReadStateLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a FileDDReadState chunk in readWriteStateBlock

CALLED BY:	FileDDReadInitialize
PASS:		nothing
RETURN:		*ds:di	= FileDDReadState.  di is the state token.
		ds:si	= FileDDReadState.  Caller must MemUnlockShared
			  ds:[LMBH_handle] when done accessing. 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDAllocReadStateLocked	proc	near
	uses	ax,bx,cx
	.enter
	mov	bx, handle FileDDState
	;
	; Use exclusive access so that threads don't hose each other
	; by causing the state block to move.
	;
	call	MemLockExcl
	mov	ds, ax
	mov	cx, size FileDDReadState
	call	LMemAlloc
	mov	di, ax			;di = handle of chunk
	mov	si, ds:[di]
	call	MemDowngradeExclLock
	.leave
	ret
FDDAllocReadStateLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDReadNextBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the next block of data from the message body.
		The returned block must be freed by the caller.

CALLED BY:	DR_MBDD_READ_NEXT_BLOCK
PASS:		si	= token returned by FileDDReadInitialize
RETURN:		carry set on error:
			ax	= MailboxError
			bx, cx, dx destroyed
		carry clear if ok:
			dx	= extra word to pass to data driver on
				  receiving machine
			cx	= number of bytes in the block
			bx	= handle of block holding the data (0 if
				  no more data in the body)

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If FRS_sendExtAttrs is zero, then send the extended attributes for
	the file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDReadNextBlock	proc	far
		uses	ds,si,di
		.enter
	;
	; Check if extended attributes have been sent already.
	;
		call	FDDStateLock		;ds:di = FileDDReadState
		mov	si, ds:[di].FRS_fileHandle ;si = file handle
		tst	ds:[di].FRS_sentExtAttrs
	;
	; Cleanup before deciding
	;
		pushf
		mov	ds:[di].FRS_sentExtAttrs, -1
		mov	bx, ds:[LMBH_handle]
		call	MemUnlockShared
		popf
	;
	; if FRS_sentExtAttrs = 0, send extended attributes.
	;
		jnz 	sendFileData
		call	FDDReadExtendedAttributes
		jmp	exit

sendFileData:
		call	FDDReadFileData	
		clr	dx

exit:
		.leave
		ret
FileDDReadNextBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDReadExtendedAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the file's extended attributes.

CALLED BY:	FileDDReadNextBlock
PASS:		si	= file handle
RETURN:		carry clear if okay:
			^hbx	= block containing array of all the file's 
				  extended attributes
			cx	= size of array
			dx	= number of elements in array
			ax destroyed
		carry set if error:
			ax	= MailboxError
				ME_DATA_DRIVER_CANNOT_ACCESS_MESSAGE_BODY
			bx, cx, dx destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDReadExtendedAttributes	proc	near
	.enter
	mov	bx, si	
	call	FileGetHandleAllExtAttributes	;^hax = ext. attrs.
						;  cx = number of entries
	jc	error
	mov	bx, ax				;^hbx = ext. attributes
	mov	dx, cx				;dx = number of entries
	mov	ax, MGIT_SIZE
	call	MemGetInfo			;ax = block size in bytes
	mov	cx, ax				;cx = block size
	call	MemUnlock	
	clc
exit:
	.leave
	ret
error:
	mov	ax, ME_DATA_DRIVER_CANNOT_ACCESS_MESSAGE_BODY
	jmp	exit
FDDReadExtendedAttributes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDReadFileData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a block of data from the file.

CALLED BY:	FileDDReadNextBlock
PASS:		si	= file handle
RETURN:		carry clear if okay:
			^hbx	= data
			cx	= size of data
			ax destroyed
		carry set if error:
			ax	= MailboxError
				ME_DATA_DRIVER_CANNOT_ACCESS_MESSAGE_BODY
				ME_NOT_ENOUGH_MEMORY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDReadFileData	proc	near
	uses	dx,ds,si,di
	.enter
	;
	; Alloc a block to store the data we'll return.
	;
	mov	ax, FILE_DATA_DRIVER_BLOCK_SIZE
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc	;bx = handle, ax = address
	jc	memAllocError
	mov	di, bx		;save the block handle in di

	mov	ds, ax
	clr	dx		;ds:dx = buffer into which to read.
	clr	al		;errors okay
	mov	bx, si		;bx = file handle
	mov	cx, FILE_DATA_DRIVER_BLOCK_SIZE
	call	FileRead	;cx = number of bytes read in.
	jnc	returnValues
	;
	; If FileRead returned ax = ERROR_SHORT_READ_WRITE and cx = 0,
	; then free the block, and return bx = 0.
	;
	cmp	ax, ERROR_SHORT_READ_WRITE
	jne	fileReadError
	tst	cx
	jnz	returnValues

	mov	bx, di
	call	MemFree
	clr	bx
	clc
	jmp	exit

returnValues:
	mov	bx, di		;^hbx = data
	call	MemUnlock
	clc
exit:
	.leave
	ret

memAllocError:
	mov	ax, ME_NOT_ENOUGH_MEMORY
	jmp 	exit

fileReadError:
	mov	bx, di
	call	MemFree
	mov	ax, ME_DATA_DRIVER_CANNOT_ACCESS_MESSAGE_BODY
	stc
	jmp	exit
FDDReadFileData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDReadComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free state information allocated in FileDDReadInitialize.

CALLED BY:	DR_MBDD_READ_COMPLETE
PASS:		si	= token returned by FileDDReadInitialize
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDReadComplete	proc	far
		uses	ax,bx
		.enter
	;
	; Grab the file handle and close the file.
	;
		call	FDDStateLock		;ds:di = FileDDReadState
		clr	al
		mov	bx, ds:[di].FRS_fileHandle
		call	FileClose
	;
	; Free the chunk and unlock the segment of the read state.
	;
		mov	ax, si			;ax = state chunk
		call 	LMemFree
		mov	bx, ds:[LMBH_handle]
		call	MemUnlockShared
		.leave
		ret
FileDDReadComplete	endp


Movable		ends


