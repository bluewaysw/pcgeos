COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		VM store
FILE:		vmstoreCode.asm

AUTHOR:		Adam de Boor, Apr 14, 1994

ROUTINES:
	Name			Description
	----			-----------
	VMSStringLengthWithNull
	VMSLock
*	MailboxGetVMFile
	VMSGetVMFileCallback
	VMSCreateNewFile
	VMSCreateFilename
*	MailboxGetVMFileName
	VMSFindFileCallback
*	MailboxDoneWithVMFile
*	MailboxOpenVMFile
	

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/94		Initial revision


DESCRIPTION:
	
		

	$Id: vmstoreCode.asm,v 1.1 97/04/05 01:20:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VMStore	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the VMStore map in the admin file

CALLED BY:	(INTERNAL) MailboxGetVMFile, MailboxGetVMFileName,
		MailboxDoneWithVMFile

PASS:		nothing
RETURN:		*ds:si	= vm store name array
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSLock		proc	near
		uses	bx, bp, ax
		.enter
		call	AdminGetVMStore
EC <		call	ECVMCheckVMFile					>
EC <		push	cx, ax						>
EC <		call	VMInfo						>
EC <		ERROR_C	VM_STORE_HANDLE_INVALID				>
EC <		cmp	di, MBVMID_VM_STORE				>
EC <		ERROR_NE VM_STORE_HANDLE_INVALID			>
EC <		pop	cx, ax						>

   		call	VMLock
		mov	ds, ax
EC <		mov	bx, bp						>
EC <		call	ECCheckLMemHandle				>
EC <		call	ECLMemValidateHeap				>

		mov	si, ds:[LMBH_offset]
EC <		call	ECLMemValidateHandle				>
		.leave
		ret
VMSLock		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the handle of a VM file to use for storing message data

CALLED BY:	(GLOBAL)
PASS:		bx	= expected number of VM blocks to be added to the file
RETURN:		carry set on error:
			ax	= VMStatus
			bx	= destroyed
		carry clear if ok:
			bx	= VMFileHandle
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetVMFile proc	far
		uses	ds, cx, dx, si, di
		.enter
		tst	bx
		jnz	haveNumBlocks
		mov	bx, VMS_DEFAULT_NUM_BLOCKS
haveNumBlocks:
	;
	; Look for a file with the requisite number of block handles
	; available.
	; 
		call	VMSLock		; *ds:si <- name array
		mov	cx, bx
		mov	bx, cs
		mov	di, offset VMSGetVMFileCallback
		call	ChunkArrayEnum	; ax <- file handle, if found
		mov_tr	bx, ax
		cmc
		jnc	done
	;
	; Not one available, so create a new one.
	; 
		call	VMSCreateNewFile
done:
		pushf
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		call	UtilUpdateAdminFile
		popf
		.leave
		ret
MailboxGetVMFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSGetVMFileCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate a VM file suitable for use

CALLED BY:	(INTERNAL) MailboxGetVMFile via ChunkArrayEnum
PASS:		ds:di	= VMStoreEntry
		cx	= number of blocks expected to be used
RETURN:		carry set if this element is suitable:
			ax	= file handle
			VMSE_refCount incremented
		carry clear if this element is not suitable
			ax	= destroyed
DESTROYED:	bx, si, di allowed
		dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSGetVMFileCallback proc	far
		uses	cx
		.enter
		cmp	ds:[di].VMSE_meta.NAE_meta.REH_refCount.WAAH_high,
				EA_FREE_ELEMENT
		je	done		; keep looking (carry clear)
	;
	; Element is in-use, so figure the number of used handles in the file.
	; If the file is open, we prefer to get the info from the horse's
	; mouth (this still won't take care of all potential overcommit
	; problems, but does mean we don't have to keep the array up-to-date).
	; 
		mov	bx, ds:[di].VMSE_handle
		tst	bx
		jz	useStoredValues

		push	cx
		call	VMGetHeaderInfo	; ax <- # used blocks
		pop	cx
		jmp	checkHandles

useStoredValues:
		mov	ax, ds:[di].VMSE_usedBlocks

checkHandles:
	;
	; Add the number of blocks we anticipate being used for this
	; message to the number of handles already used in the file. If
	; that pushes the header over the limit, keep looking.
	; 
		add	ax, cx
		cmc
		jnc	done		; => more than 64K handles, so
					;  keep looking (might have passed
					;  0xffff to insist on getting its
					;  own file)
		cmp	ax, VMS_MAX_HANDLES
		ja	done		; if would put it over the top,
					;  keep looking (carry clear)

	;
	; Add another reference to the file entry. If the file is already
	; open, we're done.
	; 
		inc	ds:[di].VMSE_refCount
		mov	ax, ds:[di].VMSE_handle
		tst	ax
		stc			; assume already open
		jnz	done
	;
	; Not open yet, so go to the mailbox directory and attempt to
	; open the file.
	; 
		call	MailboxPushToMailboxDir
		lea	dx, ds:[di].VMSE_name
		mov	ax, (VMO_OPEN shl 8) or \
				mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
				mask VMAF_ALLOW_SHARED_MEMORY or \
				mask VMAF_FORCE_DENY_WRITE
		call	VMOpen
		jc	openFailed
openOK:
		call	FilePopDir
	;
	; Open succeeded: store the handle away and return it in AX.
	; 
		mov	ds:[di].VMSE_handle, bx
		mov	ds:[di].VMSE_vmStatus, ax
		mov_tr	ax, bx
		stc
done:
		.leave
		ret
openFailed:
	;
	; Couldn't open the file, so we have to decrement the ref count before
	; continuing our search.
	; 
		WARNING	UNABLE_TO_OPEN_EXISTING_VMSTORE_FILE
		cmp	ax, VM_OPEN_INVALID_VM_FILE
		jne	ignoreEntry
	;
	; If file is invalid, delete it and create it anew.
	;
		call	FileDelete
		mov	ax, (VMO_CREATE shl 8) or \
				mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
				mask VMAF_ALLOW_SHARED_MEMORY or \
				mask VMAF_FORCE_DENY_WRITE
		call	VMOpen
		jnc	openOK

ignoreEntry:
		call	FilePopDir
		dec	ds:[di].VMSE_refCount
		clc
		jmp	done
VMSGetVMFileCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSCreateNewFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new data file for storing message bodies and record
		it in the vm store map

CALLED BY:	(INTERNAL) MailboxGetVMFile
PASS:		*ds:si	= vm store map
RETURN:		carry set on failure:
			ax	= VMStatus
			bx	= destroyed
		carry clear if ok:
			bx	= file handle
			ds	= fixed up
			ax	= destroyed
DESTROYED:	cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSCreateNewFile proc	near
slack		local	UHTA_NO_NULL_TERM_BUFFER_SIZE dup(char)
filename	local	FileLongName
newElement	local	VMStoreEntry

ForceRef filename
ForceRef slack
		uses	si, bp, es
		.enter
		call	VMSCreateFilename
		call	MailboxPushToMailboxDir
		push	ds
		segmov	ds, ss
		lea	dx, ss:[filename]
retry:
		mov	ax, (VMO_CREATE_TRUNCATE shl 8) or \
				mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
				mask VMAF_ALLOW_SHARED_MEMORY or \
				mask VMAF_FORCE_DENY_WRITE
		clr	cx
		call	VMOpen
		jc	openFailed
		pop	ds
 	;
 	; Make the file owned by mailbox library
 	;
		push	ax
 		mov	ax, handle 0
 		call	HandleModifyOwner
		pop	ax			;preserve VMStatus

	;
	; Initialize the data to store along with the name.
	; 
		mov	ss:[newElement].VMSE_handle, bx
		mov	ss:[newElement].VMSE_vmStatus, ax
		clr	ax
		mov	ss:[newElement].VMSE_usedBlocks, ax
		mov	ss:[newElement].VMSE_freeBlocks, ax
		movdw	ss:[newElement].VMSE_fileSize, axax
		inc	ax		; ref count of one, please
		mov	ss:[newElement].VMSE_refCount, ax
		mov	dx, ss
		mov	es, dx		; es, dx <- ss
		lea	di, ss:[filename]	; es:di <- name
			CheckHack <offset VMSE_handle eq size NameArrayElement>
		lea	ax, ss:[newElement].VMSE_handle	; dx:ax <- data, minus
							;  RefElementHeader
		mov	bx, mask NAAF_SET_DATA_ON_REPLACE
	;
	; Store the element in the array.
	; 
		call	LocalStringLength
		inc	cx		; include null
		call	NameArrayAdd
	;
	; Return the file handle w/carry clear, please.
	; 
		mov	bx, ss:[newElement].VMSE_handle
		clc
done:
		call	FilePopDir
		.leave
		ret

openFailed:
	;
	; Couldn't create the file, for some reason. The only one about which
	; we can do anything is when the thing already exists and is an invalid
	; VM file (I'm assuming the FILE_FORMAT_MISMATCH can't happen...)
	; 
		cmp	ax, VM_OPEN_INVALID_VM_FILE
		je	deleteAndRetry
		WARNING	UNABLE_TO_CREATE_VMSTORE_FILE
error:
		pop	ds
		stc
		jmp	done

deleteAndRetry:
	;
	; Some lingering thing from an earlier session. Nuke the file and
	; retry the open (if the nuking succeeds, that is).
	; 
		push	ax
		call	FileDelete
		WARNING_C UNABLE_TO_DELETE_EXISTING_BAD_VMSTORE_FILE
		pop	ax
		jnc	retry
		jmp	error
VMSCreateNewFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSCreateFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a filename for the new file.

CALLED BY:	(INTERNAL) VMSCreateNewFile
PASS:		*ds:si	= vm store map
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSCreateFilename proc	near
		uses	ds, si
		.enter	inherit	VMSCreateNewFile
	;
	; Figure the number that will be assigned to the new element, when we
	; add it, so we can generate an appropriate name. If there are any
	; free elements in the array, the first one will be used. If there
	; are none, one will be appended.
	; 
		mov	di, ds:[si]
		mov	dx, ds:[di].EAH_freePtr		; assume something free
		cmp	dx, EA_FREE_LIST_TERMINATOR
		jne	haveElementNum
		mov	dx, ds:[di].CAH_count		; none free, so count
							;  is the index of the
							;  elt that will be
							;  appended
haveElementNum:
	; dx = number of new element
		mov	bx, handle uiMessagesNameTemplate
		call	MemLock
		mov	ds, ax
		assume	ds:segment uiMessagesNameTemplate
		mov	si, ds:[uiMessagesNameTemplate]
		segmov	es, ss
		lea	di, ss:[filename]
		ChunkSizePtr	ds, si, cx
EC <		cmp	cx, size filename				>
EC <		ERROR_A	MESSAGE_BODY_FILENAME_CHUNK_TOO_LARGE		>
DBCS <		shr	cx			; cx = # chars w/ null	>

copyLoop:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, '\1'
		jne	storeChar
	;
	; Convert the token number to decimal at this point in the name.
	; 
EC <		cmp	dx, EA_FREE_LIST_TERMINATOR			>
EC <		ERROR_E	MESSAGE_BODY_FILENAME_CHUNK_HAS_DUPLICATE_PLACEHOLDER>

		mov_tr	ax, dx			; ax < 8000h
		cwd				; dxax <- number to convert
		push	cx
		clr	cx			; don't null-t, don't add
						;  leading zeroes
		call	UtilHex32ToAscii	; cx = # chars added
DBCS <		shl	cx			; cx = # bytes added	>
		add	di, cx			; es:di <- past result
		pop	cx			; cx <- chars left in template
EC <		mov	dx, EA_FREE_LIST_TERMINATOR; note \1 seen	>
EC <		ornf	ax, 1			; force non-z in case \1>
EC <						;  is last char		>
		jmp	nextChar
storeChar:
		LocalPutChar	esdi, ax
nextChar:
		loop	copyLoop

	; EC: sanity-check the template chunk
EC <		LocalIsNull	ax					>
EC <		ERROR_NZ MESSAGE_BODY_FILENAME_CHUNK_NOT_NULL_TERMINATED>
EC <		cmp	dx, EA_FREE_LIST_TERMINATOR			>
EC <		ERROR_NE MESSAGE_BODY_FILENAME_CHUNK_DOESNT_CONTAIN_NUMBER_PLACEHOLDER>
EC <		lea	ax, ss:[filename]				>
EC <		sub 	ax, di						>
EC <		neg	ax			; ax = size incl. null	>
EC <		cmp	ax, (FILE_LONGNAME_LENGTH + 1) * size TCHAR	>
EC <		ERROR_A MESSAGE_FILENAME_TOO_LONG			>
		call	MemUnlock
		.leave
		ret
VMSCreateFilename endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetVMFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the name of a file gotten with MailboxGetVMFile

CALLED BY:	(GLOBAL)
PASS:		cx:dx	= buffer in which to place the file's longname
		bx	= file handle whose name is required
RETURN:		buffer filled with null-terminated filename
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetVMFileName proc	far
		uses	bx, di, bp, ds, si
		.enter
		Assert 	vmFileHandle, bx
		Assert	fptr, cxdx

		call	VMSLock
		mov	bp, bx
		mov	bx, cs
		mov	di, offset VMSFindFileCallback
		call	ChunkArrayEnum
EC <		ERROR_NC ASKED_FOR_NAME_OF_VM_FILE_NOT_OPENED_BY_US	>
   		call	UtilVMUnlockDS
		.leave
		ret
MailboxGetVMFileName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSFindFileCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to find an entry in the name array that
		has the indicated file handle and copy the file's name out.

CALLED BY:	(INTERNAL) MailboxGetVMFileName via ChunkArrayEnum
			   MailboxDoneWithVMFile via ChunkArrayEnum
PASS:		ds:di	= VMStoreEntry
		cx:dx	= buffer for filename (cx = 0 means don't copy
		bp	= file handle being sought
RETURN:		carry set to stop enumerating (found element)
		if cx passed non-zero
			buffer filled
		else
			cx	= offset of VMStoreEntry found
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	buffer will be overwritten if element found

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSFindFileCallback proc	far
		.enter
		cmp	ds:[di].VMSE_meta.NAE_meta.REH_refCount.WAAH_high,
				EA_FREE_ELEMENT
		je	done		; (carry clear)
		cmp	ds:[di].VMSE_handle, bp
		clc
		jne	done
		jcxz	returnElement

		push	es
		lea	si, ds:[di].VMSE_name
		movdw	esdi, cxdx

		LocalCopyString
		pop	es
found:
		stc
done:
		.leave
		ret
returnElement:
		call	ChunkArrayPtrToElement
		mov	cx, di
		jmp	found
VMSFindFileCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxDoneWithVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the library know caller is done using the given VM file.

CALLED BY:	(GLOBAL)
PASS:		bx	= VM file handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	file may be closed
     		file & array entry may be deleted (if only one used block
			left [i.e. the header is all that's used])

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxDoneWithVMFile proc	far
		uses	ax,bx,cx,dx,ds,si,di,bp
		.enter
		Assert	vmFileHandle, bx
	;
	; Lock down the map.
	; 
		call	VMSLock		; *ds:si <- name array
	;
	; Locate the element with the file.
	; 
		clr	cx		; cx <- return elt #, please
		mov	bp, bx		; bp <- file being sought
		mov	bx, cs
		mov	di, offset VMSFindFileCallback
		call	ChunkArrayEnum	; ax <- elt #, ds:cx <- element
EC <		ERROR_NC DONE_WITH_VM_FILE_NOT_OPENED_BY_US		>
	;
	; Reduce the reference count by one. If still referenced, leave open.
	; 
		mov	di, cx
		dec	ds:[di].VMSE_refCount
		jnz	done
		call	VMSClose
	;
	; If the file is down to just the header block, then delete it and the
	; name array element.
	; 
		cmp	ds:[di].VMSE_usedBlocks, 1
		jne	done
		
		call	MailboxPushToMailboxDir
		push	ax		; save element # (again)
		lea	dx, ds:[di].VMSE_name
		call	FileDelete
		WARNING_C	UNABLE_TO_DELETE_EMPTY_VMSTORE_FILE

		pop	ax		; ax <- element #
		call	ElementArrayDelete
done:
	;
	; Something got changed, so dirty the block before unlocking it.
	; 
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		call	UtilUpdateAdminFile
		.leave
		ret
MailboxDoneWithVMFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down a file we've opened, gathering usage info before
		doing it.

CALLED BY:	(INTERNAL) MailboxDoneWithVMFile, VMSExitCallback
PASS:		ds:di	= VMStoreElement whose file is to be closed
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	ds:[di].VMSE_handle = 0, VMSE_usedBlocks, VMSE_freeBlocks,
		and VMSE_fileSize all updated
		Admin file is updated on disk (via VMUpdate).

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSClose	proc	near
		uses	ax, dx
		.enter
	;
	; Want to close the thing. Fetch the resource usage of the file before
	; doing so.
	; 
		mov	bx, ds:[di].VMSE_handle
		call	VMGetHeaderInfo
		mov	ds:[di].VMSE_usedBlocks, ax
		mov	ds:[di].VMSE_freeBlocks, dx
		call	VMUpdate
		call	FileSize
		movdw	ds:[di].VMSE_fileSize, dxax
	;
	; Now close the file down, please, and clear the VMSE_handle to prevent
	; erroneous finding of entry later.
	; 
		mov	al, FILE_NO_ERRORS	; force file out
		call	VMClose
		mov	ds:[di].VMSE_handle, 0
		call	UtilVMDirtyDS
		call	UtilUpdateAdminFile
		.leave
		ret
VMSClose	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxOpenVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reopen a VM file that was previously returned by
		MailboxGetVMFile, and whose name was gotten through
		MailboxGetVMFileName.
		The call must be matched by a call to MailboxDoneWithVMFile.

CALLED BY:	(GLOBAL) VM Tree Data Driver

PASS:		cx:dx   = name of the file to open
RETURN: 	carry set on error:
                       ax      = VMStatus
                       bx      = destroyed
               carry clear if ok
                       ax      = VMStatus 
                       bx      = file handle

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxOpenVMFile	proc	far
		uses	cx,dx,si,di,ds,es
		.enter
	;
	; Lock down the map.
	;
		call	VMSLock		;*ds:si = name array
	;
	; Locate the filename's VMStoreEntry
	;
		movdw	esdi, cxdx	;es:di = name to find
		call	LocalStringLength
		inc	cx		;include null-termination.
		clr	dx		;do not return data
		call	NameArrayFind	;ax = element number
		jc	haveEntry

EC <		WARNING	OPEN_VM_FILE_NOT_OPENED_BY_US		>
		mov	ax, VM_FILE_NOT_FOUND
		stc
		jmp	done
haveEntry:		
		call	ChunkArrayElementToPtr	;ds:di = VMStoreEntry
EC <		ERROR_C VM_STORE_ELEMENT_INVALID		>
	;
	; If the file is already open, inc the ref-count and return
	; the handle.  Otherwise, open the file.
	;
		tst	ds:[di].VMSE_refCount
		jz	openFile
		inc	ds:[di].VMSE_refCount
		mov	bx, ds:[di].VMSE_handle
		mov	ax, ds:[di].VMSE_vmStatus
		clc		
		jmp	exit
		
openFile:
		call	MailboxPushToMailboxDir
		lea	dx, ds:[di].VMSE_name
		mov	ax, (VMO_OPEN shl 8) or \
				mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
				mask VMAF_ALLOW_SHARED_MEMORY or \
				mask VMAF_FORCE_DENY_WRITE
		call	VMOpen
		call	FilePopDir
		jc	done				;open failed
		mov	ds:[di].VMSE_handle, bx
		mov	ds:[di].VMSE_vmStatus, ax
		mov	ds:[di].VMSE_refCount, 1
exit:
		call	UtilVMDirtyDS			;flags preserved
done:
		call	UtilVMUnlockDS			;flags preserved
		.leave
		ret
MailboxOpenVMFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMStoreExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that all the open VMStore files are closed

CALLED BY:	(EXTERNAL) AdminExit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	all open VM files are closed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMStoreExit	proc	far
		uses	ds, si, bx, di
		.enter
		call	VMSLock
		mov	bx, cs
		mov	di, offset VMSExitCallback
		call	ChunkArrayEnum
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		.leave
		ret
VMStoreExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSExitCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to close down any errantly-still-open
		files from the VMStore

CALLED BY:	(INTERNAL) VMStoreExit via ChunkArrayEnum
PASS:		ds:di	= VMStoreElement to check
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx
SIDE EFFECTS:	refCount set to 0, but block not dirtied

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSExitCallback	proc	far
		.enter
		cmp	ds:[di].VMSE_meta.NAE_meta.REH_refCount.WAAH_high,
			EA_FREE_ELEMENT
		je	done

		tst	ds:[di].VMSE_refCount
		jz	done
		WARNING	MISSING_CALL_TO_MailboxDoneWithVMFile
		mov	ds:[di].VMSE_refCount, 0
		call	VMSClose
done:
		clc
		.leave
		ret
VMSExitCallback	endp

VMStore		ends

