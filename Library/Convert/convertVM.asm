COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	File Manager Tools -- 1.X Document Conversion
MODULE:		Low-level VM File Conversion
FILE:		convertVM.asm

AUTHOR:		Adam de Boor, Aug 26, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	8/26/92		Initial revision


DESCRIPTION:
	Functions to convert the low-level system VM structures for a file
	from 1.x to 2.0.
		

	$Id: convertVM.asm,v 1.1 97/04/04 17:52:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VMCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVMCloseFilesOnError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down the files when an error is encountered.

CALLED BY:	(INTERNAL) ConvertVMCopyFileHeader,
			   ConvertVMCopyVMHeader
PASS:		ss:bp	= inherited stack frame
RETURN:		nothing
DESTROYED:	ax, bx, dx, ds
SIDE EFFECTS:	ss:[sourceFile], ss:[destFile] both closed, destination file
		is deleted, ss:[destName] is freed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVMCloseFilesOnError proc	near
		.enter	inherit ConvertVMFile
	;
	; Close destination file....
	; 
		mov	bx, ss:[destFile]
		clr	al
		call	FileClose
	;
	; ...and delete it...
	; 
		mov	bx, ss:[destName]
		call	MemDerefDS
		clr	dx
		call	FileDelete
	;
	; ...and free the block that held its name.
	; 
		call	MemFree
	;
	; Close down the source file.
	; 
		mov	bx, ss:[sourceFile]
		clr	al
		call	FileClose
		.leave
		ret
ConvertVMCloseFilesOnError endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVMCreateDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the destination temporary file for the conversion.

CALLED BY:	(INTERNAL) ConvertVMFile
PASS:		ss:bp	= inherited stack frame
		ds:dx	= source file name
RETURN:		carry set on error:
			ax	= FileError
			source file closed
		carry clear on success:
			ax	= destination file handle
DESTROYED:	bx, ds, es, dx, si, di, cx
SIDE EFFECTS:	ss:[finalComp], ss:[destName] both set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVMCreateDest proc	near
		.enter	inherit ConvertVMFile
	;
	; Locate the boundary between the source name's leading path components
	; and its final filename component.
	; 
		mov	si, dx
findFinalComponentLoop:
		lodsb
		tst	al			; end of name?
		jz	figureBufferSize	; yes -- ds:dx is char after
						;  final leading path comp
		cmp	al, '\\'		; separator?
		jne	findFinalComponentLoop	; no -- keep looking
		lea	dx, [si-1]		; yes -- record its position
		jmp	findFinalComponentLoop

figureBufferSize:
	;
	; ds:dx = place to null-terminate source name to get directory for
	; temp file.
	; 
		mov	ss:[finalComp], dx		; save for rename
		mov	ax, dx
		sub	ax, ss:[fileName].offset	; ax <- # bytes w/o 0
		push	ax
		jnz	allocDestName
		inc	ax			; we'll need to put '.' in...
allocDestName:
	;
	; Now allocate a block to hold the destination directory and the stuff
	; the kernel will be tacking onto the end.
	; 
		add	ax, 14+1	; 14 required by FileCreateTempFile,
					; 1 required by null terminator
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		pop	cx
		jc	memErrorDestNotOpen
	;
	; Copy the leading components into the buffer. If there were no
	; leading components, store "." there instead.
	; 
		mov	es, ax
		mov	ss:[destName], bx
		clr	di
		jcxz	storeDot

		mov	si, ss:[fileName].offset
		rep	movsb
		jmp	nullTermDest
storeDot:
		mov	al, '.'
		stosb
nullTermDest:
		clr	al
		stosb
		segmov	ds, es
		clr	dx
	;
	; Create normal PC/GEOS file for reading and writing and exclusive
	; access.
	; 
		mov	cx, FILE_ATTR_NORMAL
		mov	ax, FileAccessFlags <FE_EXCLUSIVE, FA_READ_WRITE>
		call	FileCreateTempFile
		jc	createError
done:
		.leave
		ret

memErrorDestNotOpen:
	;
	; Couldn't allocate the buffer for the name, so just close the source
	; file and return an error.
	; 
		mov	bx, ss:[sourceFile]
		clr	al
		call	FileClose
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		stc
		jmp	done

createError:
	;
	; Close the source file and free the buffer holding the destination's
	; name.
	; 
		push	ax
		mov	bx, ss:[sourceFile]
		clr	al
		call	FileClose
		mov	bx, ss:[destName]
		call	MemFree
		pop	ax
		stc
		jmp	done
ConvertVMCreateDest endp


;
; List of attributes to set on destination, using stuff read in from the
; source file.
; 
attrList	FileExtAttrDesc \
	<FEA_FILE_TYPE, 	GFHO_type, 	size GFHO_type>,
	<FEA_FLAGS, 		GFHO_flags, 	size GFHO_flags>,
	<FEA_RELEASE, 		GFHO_release, 	size GFHO_release>,
	<FEA_PROTOCOL, 		GFHO_protocol, 	size GFHO_protocol>,
	<FEA_TOKEN, 		GFHO_token, 	size GFHO_token>,
	<FEA_CREATOR, 		GFHO_creator, 	size GFHO_creator>,
	<FEA_USER_NOTES,	GFHO_userNotes,	size GFHO_userNotes>
CVMF_NUM_ATTRS	equ	length attrList

CVMFHeaderBuf	struct
    CVMFHB_header	VMFileHeaderOld
    CVMFHB_attrs	FileExtAttrDesc CVMF_NUM_ATTRS dup (<>)
CVMFHeaderBuf	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVMCopyFileHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy and convert the file header of the source file.

CALLED BY:	(INTERNAL) ConvertVMFile
PASS:		ss:bp	= inherited stack
RETURN:		carry set on error:
			ax	= FileError
			dest file closed and deleted
			dest name freed
			source file closed
		carry clear on success:
			ax	= destroyed
DESTROYED:	bx, cx, dx, si, di, ds, es
SIDE EFFECTS:	ss:[headerPos], ss:[headerSize] set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVMCopyFileHeader proc near
		.enter	inherit ConvertVMFile
	;
	; Allocate a buffer for the VMFileHeaderOld.
	; 
		mov	ax, size CVMFHeaderBuf
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc	; ^hbx, ax <- buffer
		LONG jc	couldntAllocateFileHeaderSoCloseAndNukeDestFreeDestNameAndCloseSource
	;
	; Read in the VMFileHeaderOld
	; 
		push	bx		; save handle for free
		mov	ds, ax
		mov	es, ax		; for setting attributes...
		clr	dx
		mov	bx, ss:[sourceFile]
		clr	dx
		mov	cx, size VMFileHeaderOld
		clr	al
		call	FileRead
		LONG jc	couldntReadHeaderSoFreeHeaderBufCloseAndNukeDestFreeDestNameAndCloseSource
	;
	; Protect against files with the same longname, which can easily occur
	; when people copy in an old file with 1.2 that they already converted.
	; The filesystem (alas) doesn't screen these duplicates out, so we have
	; to be careful.
	; 
		mov	ax, ERROR_FILE_FORMAT_MISMATCH
		cmp	{word}ds:[CVMFHB_header].VMFHO_gfh.GFHO_signature[0],
				GFHO_SIG_1_2
		jne	couldntReadHeaderSoFreeHeaderBufCloseAndNukeDestFreeDestNameAndCloseSource
		cmp	{word}ds:[CVMFHB_header].VMFHO_gfh.GFHO_signature[2],
				GFHO_SIG_3_4
		jne	couldntReadHeaderSoFreeHeaderBufCloseAndNukeDestFreeDestNameAndCloseSource
		cmp	ds:[CVMFHB_header].VMFHO_gfh.GFHO_type, GFTO_VM
		jne	couldntReadHeaderSoFreeHeaderBufCloseAndNukeDestFreeDestNameAndCloseSource		
	;
	; Set the various extended attributes for the dest from the values
	; stored in the VMFileHeaderOld, after fixing up the file type (which
	; increased by 1 from 1.x to 2.0, but we know this thing's a VM file,
	; so just set it directly)
	; 
		mov	ds:[CVMFHB_header].VMFHO_gfh.GFHO_type, GFT_VM
	    ;
	    ; Copy in the array of attribute descriptors.
	    ; 
		mov	di, offset CVMFHB_attrs
		mov	si, offset attrList
		segmov	ds, cs
		mov	cx, size attrList
		rep	movsb
	    ;
	    ; Set their FEAD_value.segment pointers.
	    ; 
		mov	cx, CVMF_NUM_ATTRS
		mov	di, offset CVMFHB_attrs
setSegmentLoop:
		mov	es:[di].FEAD_value.segment, es
		add	di, size FileExtAttrDesc
		loop	setSegmentLoop
	    ;
	    ; Now tell the kernel to set the attributes for the dest.
	    ; 
		mov	di, offset CVMFHB_attrs	; es:di <- FEAD array
		mov	ax, FEA_MULTIPLE	; ax <- attr to set (many)
		mov	cx, CVMF_NUM_ATTRS	; cx <- # attrs to set
		mov	bx, ss:[destFile]	; bx <- file handle
		call	FileSetHandleExtAttributes
	;
	; Now set up and write out the 2.0 VMFileHeader. First zero out the
	; VMFileHeader.
	; 
		CheckHack <size VMFileHeader lt VMFHO_signature>
		segmov	ds, es
		clr	di
		mov	cx, size VMFileHeader
		clr	al
		rep	stosb
	    ;
	    ; Set the signature properly.
	    ; 
		mov	ds:[VMFH_signature], VM_FILE_SIG
	    ;
	    ; Transfer the size in, and save it in our local variable. It
	    ; doesn't change...
	    ; 
		mov	ax, ds:[CVMFHB_header].VMFHO_headerSize
		mov	ds:[VMFH_headerSize], ax
		mov	ss:[headerSize], ax
	    ;
	    ; Transfer the position into the header, adjusting for the loss
	    ; of the GeosFileHeaderOld and the expansion of the VM-specific
	    ; portion. We store the unadulterated position in our local
	    ; variable, however, so we know how much data we need to transfer
	    ; before we get to the header.
	    ; 
		mov	ax, ds:[CVMFHB_header].VMFHO_headerPos.low
		mov	ss:[headerPos].low, ax
		sub	ax, CVM_POS_ADJUST
		mov	ds:[VMFH_headerPos].low, ax
		mov	ax, ds:[CVMFHB_header].VMFHO_headerPos.high
		mov	ss:[headerPos].high, ax
		sbb	ax, 0
		mov	ds:[VMFH_headerPos].high, ax
	    ;
	    ; Write the VMFileHeader to the destination. We're still located
	    ; just after the hidden file header.
	    ; 
		clr	dx
		mov	cx, size VMFileHeader
		mov	bx, ss:[destFile]
		clr	al
		call	FileWrite
		jc	couldntWriteHeaderSoFreeHeaderBufCloseAndNukeDestFreeDestNameAndCloseSource
	;
	; Free that buffer.
	; 
		pop	bx
		call	MemFree
		clc
done:
		.leave
		ret

couldntAllocateFileHeaderSoCloseAndNukeDestFreeDestNameAndCloseSource:
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		push	ax

cleanUpAfterPushingErrorCodeAndFreeingBuffer:
		call	ConvertVMCloseFilesOnError
	;
	; Recover error code, set the carry, and return.
	; 
		pop	ax
		stc
		jmp	done

couldntWriteHeaderSoFreeHeaderBufCloseAndNukeDestFreeDestNameAndCloseSource:
couldntReadHeaderSoFreeHeaderBufCloseAndNukeDestFreeDestNameAndCloseSource:
		pop	bx
		push	ax
		call	MemFree
		jmp	cleanUpAfterPushingErrorCodeAndFreeingBuffer
ConvertVMCopyFileHeader endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVMBulkTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy large swathes of the file from source to dest without
		interpretation of any sort.

CALLED BY:	(INTERNAL) ConvertVMFile
PASS:		si	= source file
		di	= dest file
		cxdx	= number of bytes to copy.
RETURN:		carry set on error:
			ax	= FileError
			dest file closed and deleted
			dest name freed
			source file closed
		carry clear on success:
			ax	= destroyed
DESTROYED:	bx, cx, dx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVMBulkTransfer proc	near
passedBP	local	word	push bp
bytesLeft	local	dword	push cx, dx
copyBufSize	local	word
copyBufHandle	local	hptr
		.enter	
	;
	; First find how big a block exists in the system.
	; 
		mov	ax, SGIT_LARGEST_FREE_BLOCK
		call	SysGetInfo		; ax = size of largest block
						;	in paragraphs
	;
	; If it's too small to be useful, we'll just have to be pushy.
	; 
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1			; ax = size in bytes
		cmp	ax, CVM_FILE_BUF_SIZE	; smallest useful buffer
		ja	compareToTransferSize
		mov	ax, CVM_FILE_BUF_SIZE

compareToTransferSize:
	;
	; Use the smaller of the largest block size and the amount we're
	; transferring.
	; 
		tst	cx			; > 64K?
		jnz	setCopySize		; yes -- what we've got is what
						;  we'll get...
		cmp	ax, ss:[bytesLeft].low	; > buf size?
		jbe	setCopySize		; yes, use largest block avail
						; else, use file size
		mov	ax, ss:[bytesLeft].low

setCopySize:
		mov	ss:[copyBufSize], ax	; save buffer size

		tst	ax
		jz	done
	;
	; Allocate that many bytes.
	; 
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	couldntAllocCleanUpAsUsualOnError

		mov	ss:[copyBufHandle], bx	; save copy buffer handle

		mov	ds, ax			; ds:dx <- buffer addr for
		clr	dx			;  the duration.
copyLoop:
	;
	; Figure how many bytes to read: a whole buffer, or however many are
	; left, whichever is less.
	; 
		mov	cx, ss:[copyBufSize]	; Try for full buffer...
		tst	ss:[bytesLeft].high
		jnz	readBuffer
		cmp	cx, ss:[bytesLeft].low
		jbe	readBuffer
		mov	cx, ss:[bytesLeft].low
readBuffer:
		clr	al			; give me errors
		mov	bx, si			; bx <- source file
		call	FileRead
		jc	error
	;
	; Write out however many bytes we asked for.
	; 
		clr	al			; give me errors
		mov	bx, di			; bx <- dest file
		call	FileWrite
		jc	error
	;
	; Reduce the number of bytes to transfer by the number written and
	; loop if there's more to do.
	; 
		sub	ss:[bytesLeft].low, cx
		sbb	ss:[bytesLeft].high, 0

		tstdw	ss:[bytesLeft]
		jnz	copyLoop
	;
	; Free up the transfer buffer and return success.
	; 
		mov	bx, ss:[copyBufHandle]
		call	MemFree
		clc
done:
		.leave
		ret

couldntAllocCleanUpAsUsualOnError:
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		push	ax
cleanUpAsUsual:
		push	bp
		mov	bp, ss:[passedBP]	; ss:bp <- ConvertVMFile locals
		call	ConvertVMCloseFilesOnError
		pop	bp
		pop	ax
		stc
		jmp	done

error:
		push	ax
		mov	bx, ss:[copyBufHandle]
		call	MemFree
		jmp	cleanUpAsUsual
ConvertVMBulkTransfer endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVMCopyVMHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the VM header block to the destination, after suitable
		abuse.

CALLED BY:	(INTERNAL) ConvertVMFile
PASS:		ss:bp	= inherited stack
RETURN:		carry set on error:
			ax	= FileError
			dest file closed and deleted
			dest name freed
			source file closed
		carry clear on success:
			ax	= destroyed
DESTROYED:	bx, cx, dx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVMCopyVMHeader proc	near
		.enter	inherit ConvertVMFile
	;
	; Allocate a buffer for the header.
	; 
		mov	ax, ss:[headerSize]
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		LONG jc couldntAllocVMHeaderSoCloseAndNukeDestFreeDestNameAndCloseSource
	;
	; Read the header in.
	; 
		push	bx
		mov	ds, ax
		clr	dx
		mov	cx, ss:[headerSize]
		mov	bx, ss:[sourceFile]
		clr	al
		call	FileRead
		LONG jc	couldntReadVMHeaderSoFreeBufCloseAndNukeDestFreeDestNameAndCloseSource
	;
	; Loop over all the blocks, abusing them as necessary.
	; 
		mov	si, offset VMH_blockTable
blockLoop:
		test	ds:[si].VMBH_sig, VM_IN_USE_BIT
		jz	adjustFilePos
	;
	; Block is in-use. If the header has VMAO_PRESERVE_HANDLES set, we
	; want to set VMBF_PRESERVE_HANDLE for all in-use handles, as that's
	; what it meant, using 2.0 terminology.
	; 
		test	ds:[VMH_attributes], mask VMAO_PRESERVE_HANDLES
		jz	fiddleWithID
		ornf	ds:[si].VMBH_flags, mask VMBF_PRESERVE_HANDLE
fiddleWithID:
	;
	; Deal with DBase blocks, converting from the old ID to the new.
	; 
		mov	ax, ds:[si].VMBH_uid

		mov	cx, DB_ITEM_BLOCK_ID	; assume item block
		cmp	ax, DB_OLD_ITEM_BLOCK_ID
		je	setID

		mov	cx, DB_GROUP_ID		; assume group block
		cmp	ax, DB_OLD_GROUP_ID
		je	setID

		mov	cx, ax			; assume not dbase
		cmp	ax, DB_OLD_MAP_ID
		jne	setID
	    ;
	    ; DBase map block also needs to have its handle recorded in the
	    ; new VMH_dbMapBlock (formerly VMH_mapExtra) field of the header,
	    ; as well as having its ID upgraded.
	    ; 
		mov	ds:[VMH_dbMapBlock], si
		mov	cx, DB_MAP_ID
setID:
		mov	ds:[si].VMBH_uid, cx

adjustFilePos:
	;
	; If the block (free or allocated) has space in the file, adjust it
	; by the requisite amount. DO NOT test VMBH_fileSize, as that's the
	; high word of the size of a free block, and usually zero...
	; 
		mov	ax, ds:[si].VMBH_filePos.low
		or	ax, ds:[si].VMBH_filePos.high
		jz	nextBlock
		subdw	ds:[si].VMBH_filePos, CVM_POS_ADJUST
nextBlock:
	;
	; Advance to the next block in the header.
	; 
		add	si, size VMBlockHandle
		cmp	si, ds:[VMH_lastHandle]
		jne	blockLoop
	;
	; 1.X documents with objects in them were always accessed by a single
	; thread, so if the file indicates it holds objects in any of its
	; blocks, set the VMA_SINGLE_THREAD_ACCESS bit as well.
	; 
		test	ds:[VMH_attributes], mask VMA_OBJECT_RELOC
		jz	writeHeader
		ornf	ds:[VMH_attributes], mask VMA_SINGLE_THREAD_ACCESS
writeHeader:
	;
	; Clear out the no-longer-existent VMAO_PRESERVE_HANDLES bit, just
	; in case we want to reuse that bit for something else.
	;
	; Disable VMA_OBJECT_RELOC until the file has been converted, as
	; attempting to relocate the object blocks created by the old
	; application is doomed to failure.
	; 
		andnf	ds:[VMH_attributes], not (mask VMAO_PRESERVE_HANDLES or\
				mask VMA_OBJECT_RELOC)
	;
	; Write the whole monster out.
	; 
		mov	cx, ss:[headerSize]
		mov	bx, ss:[destFile]
		clr	al
		call	FileWrite
		jc	couldntWriteVMHeaderSoFreeBufCloseAndNukeDestFreeDestNameAndCloseSource
	;
	; Free the buffer holding the header.
	; 
		pop	bx
		call	MemFree
		clc
done:
		.leave
		ret

couldntAllocVMHeaderSoCloseAndNukeDestFreeDestNameAndCloseSource:
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		push	ax

cleanUpAfterPushingErrorCodeAndFreeingBuffer:
		call	ConvertVMCloseFilesOnError
	;
	; Recover error code, set the carry, and return.
	; 
		pop	ax
		stc
		jmp	done

couldntWriteVMHeaderSoFreeBufCloseAndNukeDestFreeDestNameAndCloseSource:
couldntReadVMHeaderSoFreeBufCloseAndNukeDestFreeDestNameAndCloseSource:
		pop	bx
		push	ax
		call	MemFree
		jmp	cleanUpAfterPushingErrorCodeAndFreeingBuffer
ConvertVMCopyVMHeader endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a single VM file from a 1.x to 2.0, in-place

CALLED BY:	GLOBAL
PASS:		ds:dx	= path to file to convert
		cx	= disk on which it sits (0 => current dir/disk)
RETURN:		carry set on error:
			ax	= FileError
DESTROYED:	ax, bx
SIDE EFFECTS:	if successful, old file is overwritten

PSEUDO CODE/STRATEGY:
		Open source file.
		FileCreateTempFile for dest.
		Read VMFileHeaderOld into allocated block.
		Set all extended attributes of dest from GeosFileHeaderOld.
		Write new VMFileHeader after adjusting position of header
		    for absence of GeosFileHeaderOld and increased VMFileHeader
		Transfer data from source to dest until VMHeader
		Read VMHeader.
		foreach block:
		    if allocated:
			set VMBF_PRESERVE_HANDLE if VMAO_PRESERVE_HANDLES
			adjust file position by 16-GeosFileHeaderOld
			if id is DB_OLD_MAP_ID, set VMH_dbMapBlock and
			  change to DB_MAP_ID	
			if id is DB_OLD_GROUP_ID, set to DB_GROUP_ID
			if id is DB_OLD_ITEM_BLOCK_ID, set to DB_ITEM_BLOCK_ID
		    else if free space:
		    	adjust file position by 16-GeosFileHeaderOld
		clear VMAO_PRESERVE_HANDLES
		if VMA_OBJECT_RELOC, set VMA_SINGLE_THREAD_ACCESS, then
			clear VMA_OBJECT_RELOC
		Write VMHeader
		Transfer rest of the file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/26/92		Initial version
	cassie  4/15/93		Change read-only files to read/write 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
rootPath	char	'\\', 0

ConvertVMFile 	proc	far
fileName	local	fptr	push ds, dx	; Name of file being converted
diskHandle	local	word	push cx		; Handle of disk on which it
						;  sits (0 => current dir)
sourceFile	local	hptr			; Handle of source file
destFile	local	hptr			; Handle of dest file
destName	local	hptr			; Handle of block holding
						;  temp file's name
headerSize	local	word			; Size of VMHeaderOld
headerPos	local	dword			; VMHeaderOld position (source
						;  file)
finalComp	local	word			; Offset of final component
						;  of fileName
		uses	cx, dx, ds, bp, es, si, di
		.enter
	;
	; If source file is on a different disk, push to its root
	; 
		jcxz	openSource
		call	FilePushDir
		push	ds, dx
		segmov	ds, cs
		mov	dx, offset rootPath
		mov	bx, cx
		call	FileSetCurrentPath
		pop	ds, dx
		jc	error
openSource:
		call	FileGetAttributes	; cx <- attributes
		jc	error
		test	cx, mask FA_RDONLY
		jz	notReadOnly
		andnf	cx, not (mask FA_RDONLY) ; clear the read only bit
		call	FileSetAttributes
		jc	error
notReadOnly:
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		call	FileOpen
		jnc	createDest
error:
		jmp	popDirIfNecessary
	;--------------------
createDest:
		mov	ss:[sourceFile], ax
		call	ConvertVMCreateDest

		jc	error
		mov	ss:[destFile], ax
		
		call	ConvertVMCopyFileHeader
		jc	popDirIfNecessary
	;
	; Transfer everything up to the VMHeaderOld.
	; 
		movdw	cxdx, ss:[headerPos]
		subdw	cxdx, <size VMFileHeaderOld>
		mov	si, ss:[sourceFile]
		mov	di, ss:[destFile]
		call	ConvertVMBulkTransfer
		jc	popDirIfNecessary
	;
	; Convert and write the header itself.
	; 
		call	ConvertVMCopyVMHeader
		jc	popDirIfNecessary
	;
	; Transfer the rest of the file.
	; 
		mov	bx, ss:[sourceFile]
		call	FileSize		; dxax <- size
		mov	cx, dx
		mov_tr	dx, ax			; cxdx <- file size
		subdw	cxdx, ss:[headerPos]	; reduce byte count by start of
						;  header...
		sub	dx, ss:[headerSize]	;  ...and its size
		sbb	cx, 0
		mov	si, ss:[sourceFile]
		mov	di, ss:[destFile]
		call	ConvertVMBulkTransfer
		jc	popDirIfNecessary
	;
	; Shut everything down.
	; 
		mov	bx, ss:[destFile]
		clr	al
		call	FileClose

		mov	bx, ss:[sourceFile]
		call	FileClose
	;
	; Nuke the source file.
	; 
		lds	dx, ss:[fileName]
		call	FileDelete
		jc	couldntDeleteSource
	;
	; Rename the dest to be the source.
	; 
		segmov	es, ds
		mov	di, ss:[finalComp]
		cmp	di, ss:[fileName].offset
		je	haveNewName
		inc	di		; skip over backslash
haveNewName:
		mov	bx, ss:[destName]
		call	MemDerefDS
		clr	dx
		call	FileRename
		
	;
	; Free buffer holding destination name.
	; 
		call	MemFree
	;
	; Pop dir, if necessary.
	; 
		clc
popDirIfNecessary:
		pushf
		tst	ss:[diskHandle]	; (clears carry)
		jz	dirPopped
		call	FilePopDir
dirPopped:
		popf
		.leave
		ret

couldntDeleteSource:
		push	ax
		mov	bx, ss:[destName]
		call	MemDerefDS
		clr	dx
		call	FileDelete
		call	MemFree
		pop	ax
		stc
		jmp	popDirIfNecessary
ConvertVMFile	endp

VMCode	ends
