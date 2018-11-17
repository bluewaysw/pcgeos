COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel VM Manager -- High-level interface routines
FILE:		vmemHigh.asm

AUTHOR:		Cheng, 1989

ROUTINES:
	Name			Description
	----			-----------
    GLB	VMOpen			Open a VM file
    GLB	VMAlloc			Allocate a new VM block
    GLB	VMFind			Find an existing block by uid
    GLB	VMLock			Lock down a VM block
    GLB	VMUnlock		Unlock a VM block
    GLB	VMDirty			Mark a block as dirty and in need of write-out
    GLB	VMFree			Free a VM block
    GLB VMModifyUserID		Change the ID bound to a VM block
    GLB	VMUpdate		Write all dirty blocks to the file
    GLB	VMClose			Update and close a VM file
    GLB	VMSetMapBlock		Record a VM block as the map block for the
			file.
    GLB	VMGetMapBlock		Retrieve the map block for the file
    GLB VMGetAttributes		Get VM attributes
    GLB VMSetAttributes		Set VM attributes
    GLB	VMGrabExclusive		Obtain exclusive access to a VM file
    GLB	VMReleaseExclusive	Allow others to access a VM file
    GLB	VMInfo			Retrieve info about a VM block
    GLB	VMSetReloc		Set the relocation/unrelocation routine for
			the file.
    GLB	VMAttach		Attach a block of memory to a VM block
    GLB VMDetach		Remove a block of memory from a VM block
    GLB VMGetHeader		Read the GeosFileHeader for a VM file
    GLB VMSetHeader		Write the GeosFileHeader for a VM file

    GLB VMDiscardDirtyBlocks	Discards all dirty blocks in a file.
	
    GLB VMTestDirtySizeForModeChange	Modify Dirty Size of VMFile and check 
					if this exceeds limit
    GLB VMSetDirtyLimit		Sets the dirty limit for a file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/89		Initial revision
	Adam	11/89		Added exclusive/info routines

DESCRIPTION:
	This file contains the high-level interface routines for the VMem
	code.
		
Intended calling sequence:
	VM file handle <- VMOpen
	...
	VM block handle <- VMAlloc(VM file handle)
	...
	data address, VM mem handle <- VMLock(VM block handle)
	...
	[ optional: VMDirty(VM mem handle)]
	VMUnlock(VM mem handle)
	...
	VMClose(VM file handle)

Register usage:
	when possible:
	bx - VM file handle
	si - VM handle / VM mem handle
	bp - VM header handle
	di - VM block handle
	ds - idata
	es - VM header

	when relevant:
	ax - number of bytes
	cx - high word of file position
	dx - low word of file position

Semaphore hierachy:
	vmFile sem - located in VM handle
	header grab - located in header block's handle
	block grab - located in VM mem handle
	heap sem
	DOS sem

	$Id: vmemHigh.asm,v 1.1 97/04/05 01:16:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment resource


COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMLock

		The assembly version of VMLock returns a MemHandle in
		bp, but since we can't do that in C, a pointer (*mh)
		must be passed in which to place the returned
		MemHandle.

C DECLARATION:	extern void * _pascal VMLock(VMFileHandle file,
					     VMBlockHandle block,
					     MemHandle *mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
VMLOCK	proc	far	file:word, block:word, mh:fptr
					uses bp, ds
	.enter

	mov	bx, file
	mov	ax, block
	lds	cx, mh
	call	VMLock
	mov	bx, cx			; ds:bx = mh
	mov	ds:[bx], bp

	mov_tr	dx, ax
	clr	ax

	.leave
	ret

VMLOCK	endp
	SetDefaultConvention

kcode	ends

VMOpenCode		segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMOpenGetFileAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the requisite attributes from the file so we know
		how to open the file.

CALLED BY:	(INTERNAL) VMOpen
PASS:		ah	= VMOpenType
		ds:dx	= file name
		ss:bp	= inherited stack frame
RETURN:		carry set on error:
			ax	= VMStatus
		carry clear if ok
			ax	= destroyed
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMOpenGetFileAttrs proc	near
	.enter	inherit VMOpenReal
	;
	; if we're opening the file CREATE_ONLY or CREATE_TRUNCATE, then
	; there is no point in getting the file flags since we will biff
	; them anyway
	;
	mov	fileFlags, 0			;assume no flags
	mov	fileAttributes, 0		;and no attrs
	mov	driveStatus, 0			; and no known drive status
	mov	internalFlags, 0

	test	ah, VMO_NATIVE_WITH_EXT_ATTRS
	jz	notAProblem
	andnf	ah, not VMO_NATIVE_WITH_EXT_ATTRS
notAProblem:
	cmp	ah, VMO_CREATE_TRUNCATE
	je	done
	cmp	ah, VMO_CREATE_ONLY
	je	done
	cmp	ah, VMO_TEMP_FILE
	je	done


	; fetch both the GeosFileHeaderFlags and the FileAttrs for the file
	; in question.

	push	es, di, cx
	mov	ss:[getAttrsDescs][0*FileExtAttrDesc].FEAD_attr, FEA_FLAGS
	mov	ss:[getAttrsDescs][0*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[fileFlags]
	mov	ss:[getAttrsDescs][0*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[getAttrsDescs][0*FileExtAttrDesc].FEAD_size, 
			size fileFlags
	
	mov	ss:[getAttrsDescs][1*FileExtAttrDesc].FEAD_attr, FEA_FILE_ATTR
	mov	ss:[getAttrsDescs][1*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[fileAttributes]
	mov	ss:[getAttrsDescs][1*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[getAttrsDescs][1*FileExtAttrDesc].FEAD_size,
			size fileAttributes

	mov	ss:[getAttrsDescs][2*FileExtAttrDesc].FEAD_attr,
			FEA_DRIVE_STATUS
	mov	ss:[getAttrsDescs][2*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[driveStatus]
	mov	ss:[getAttrsDescs][2*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[getAttrsDescs][2*FileExtAttrDesc].FEAD_size,
			size driveStatus

	mov	ax, FEA_MULTIPLE
	mov	cx, length getAttrsDescs
	lea	di, ss:[getAttrsDescs]
	segmov	es, ss
	call	FileGetPathExtAttributes
	pop	es, di, cx
	jnc	setInternalFlags

	cmp	ax, ERROR_FILE_NOT_FOUND
	je	checkCreate

	; if the error is ERROR_ATTR_NOT_FOUND, then the thing isn't a VM
	; file. Otherwise, we return whatever error we were given.

	cmp	ax, ERROR_ATTR_NOT_FOUND
	stc
	jne	done
	mov	ax, VM_OPEN_INVALID_VM_FILE

done:
	.leave
	ret

checkCreate:
	;
	; If VMO_CREATE, ERROR_FILE_NOT_FOUND is fine
	; 
	;;; Changed,  4/26/93 -jw to support new "passedFlag"
	;;;     VMO_NATIVE_WITH_EXT_ATTRS
	cmp	ss:[passedFlags].high, VMO_CREATE
	je	setInternalFlags
		
	cmp	ss:[passedFlags].high, VMO_CREATE or \
				       VMO_NATIVE_WITH_EXT_ATTRS
	stc
	jne	done

setInternalFlags:
	test	driveStatus, mask DES_LOCAL_ONLY
	jz	done
	mov	internalFlags, mask IVMF_FILE_LOCAL
	jmp	done
VMOpenGetFileAttrs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMOpenDoOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try and open the requested file.

CALLED BY:	(INTERNAL) VMOpen
PASS:		ds:dx	= name of file to open/create
		al	= FileAccessFlags
		di	= VMStatus to return on successful open
		ss:bp	= inherited stack frame
RETURN:		carry set on error:
			ax	= FileError/VMStatus
		carry clear on successs:
			ax	= VMStatus
			bx	= file handle
			si	= handle of other handle open to same file,
				  or 0 if none
DESTROYED:	cx
SIDE EFFECTS:	a file handle is created, and an existing file might be
     			truncated.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMOpenDoOpen	proc	near
		.enter	inherit VMOpenReal

		clr	si		; assume no sharing

	;
	; Differentiate between the three major categories:
	;	- open existing (ah == 0, aka VMO_OPEN)
	;	- create temp file (ah == 1, aka VMO_TEMP_FILE)
	;	- create w/o truncate, create w/truncate, create only
	;
			CheckHack <VMO_TEMP_FILE eq 1 and VMO_OPEN eq 0>

		mov	ah, ss:[passedFlags].high
;;; Added,  4/26/93 -jw
;;; To make sure that we don't mess up and try to compare against a value
;;; that might include the VMO_NATIVE_WITH_EXT_ATTRS bit...
;;;
EC <		cmp	ah, VMO_OPEN or VMO_NATIVE_WITH_EXT_ATTRS	>
EC <		ERROR_Z	VMO_OPEN_AND_VMO_NATIVE_WITH_EXT_ATTRS_NOT_ALLOWED >
EC <		cmp	ah, VMO_TEMP_FILE or VMO_NATIVE_WITH_EXT_ATTRS	>
EC <		ERROR_Z	VMO_TEMP_FILE_AND_VMO_NATIVE_WITH_EXT_ATTRS_NOT_ALLOWED>
		
		and	ah, not VMO_NATIVE_WITH_EXT_ATTRS

		cmp	ah, VMO_TEMP_FILE
		je	isTempFile
		jb	useFileOpen
	;
	; See if the access is read-only (public file)
	;
			CheckHack <FA_READ_ONLY eq 0>
		test	al, mask FAF_MODE
		jz	readOnly
	;
	; Wants to create the file. Set CH appropriately for FileCreate.
	; 
			CheckHack <VMO_CREATE lt VMO_CREATE_ONLY and \
				   VMO_CREATE_TRUNCATE gt VMO_CREATE_ONLY>
		cmp	ah, VMO_CREATE_ONLY
		mov	ah, FILE_CREATE_NO_TRUNCATE
		jb	doCreate
		mov	ah, FILE_CREATE_ONLY
		je	doCreate
		mov	ah, FILE_CREATE_TRUNCATE
doCreate:
		mov	cx, FILE_ATTR_NORMAL

;;; Added,  4/26/93 -jw
;;; To support VM files being created with "native" names
;;;
		test	ss:[passedFlags].high, VMO_NATIVE_WITH_EXT_ATTRS
		jz	reallyCreateIt
		or	ah, mask FCF_NATIVE_WITH_EXT_ATTRS
reallyCreateIt:
		call	FileCreate
		jc	done
	;
	; Got a handle back -- see whether we created the file or if it was
	; already there (if file size is 0, we created it).
	; 
		mov_tr	bx, ax		; bx <- file handle
		call	FileSize
		or	dx, ax
		jnz	checkOtherOpen	; => created w/o truncation, so we need
					;  to perform normal FileOpen-style
					;  post-processing.
createOK:
		mov	ax, VM_CREATE_OK
done:
		.leave
		ret

isTempFile:
	;
	; Create a temporary VM file.
	; 
		mov	cx, FILE_ATTR_NORMAL
		call	FileCreateTempFile
		jc	done
		mov_tr	bx, ax
		jmp	createOK
	;
	; Access is read-only (file is likely a public file)
	;
readOnly:
		cmp	ah, VMO_CREATE
		jz	useFileOpen
		mov	ax, VM_SHARING_DENIED
		stc
		jmp	done

useFileOpen:
	;
	; Open an existing VM file.
	; 
		call	FileOpen
		jc	done
		
		mov_tr	bx, ax

checkOtherOpen:
		call	VMFindOtherOpen
		mov	ax, di		; ax <- status for successful open
		cmc
		jnc	done		; si = handle of other thing open to
					;  same file
		clr	si		; signal nobody else has it open (clears
					;  carry, too)
		jmp	done
VMOpenDoOpen	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMOpen

SYNOPSIS:	Open a VM file in one of several different ways depending on
		the flags passed.

CALLED BY:	GLOBAL

PASS:		ah - mode:
		    VMO_TEMP_FILE - Set to create a temporary file to store
			data. ds:dx is the directory in which to create the
			file, FOLLOWED BY 13 NULL BYTES (in addition to the
			terminating null byte). The name of the created file
			is appended to the directory.
		    VMO_CREATE_ONLY -  Set to create a new file. File may not
		    	already exist.
		    VMO_CREATE -  Set to create a new file if none exists, else
		    	the existing file is opened.
		    VMO_CREATE_TRUNCATE - Set to create a new file if none
			exists, else truncate any existing file.
		    VMO_OPEN - Open existing VM file.
		    
		    In addition to the above flags you can also or in the
		    modifier:
			    VMO_NATIVE_WITH_EXT_ATTRS
		    which allows the creation of VM files which have filenames
		    that are compatible with the host filesystem.

		al - mode (VMAccessFlags)
		cx - user specified compression threshold (may be 0, in which
		     case the system default applies)
		ds:dx - file name to open (directory in which to create temp
		     file, if VMO_TEMP_FILE)

RETURN:		carry set on error
			
		ax - VMStatus
		     VM_FILE_EXISTS	- VMO_CREATE_ONLY option - file already
					  exists.
		     VM_FILE_NOT_FOUND	- VMO_OPEN option - cannot find file
		     VM_SHARING_DENIED	- file already open and access denied
		     VM_CREATE_OK	- new file has been created
		     VM_OPEN_OK_READ_ONLY - file opened read only
		     VM_OPEN_OK_TEMPLATE - template file opened (read-only)
		     VM_OPEN_OK_READ_WRITE_NOT_SHARED
		     VM_OPEN_OK_READ_WRITE_SINGLE
		     VM_OPEN_OK_READ_WRITE_MULTIPLE
		     VM_OPEN_OK_BLOCK_LEVEL
		     VM_OPEN_INVALID_VM_FILE - file not a valid VM file
		     other FileError error
		bx - VM file handle.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
    if VMO_CREATE_TEMP then
	FileCreateTempFile
	init VM handle
	return (VM_CREATE_OK)
    else
	open (name)
	if ok then
	    if sharing then
		up ref count
		return (VM_SHARING_OK)
	    else
		init VM handle
		read file header into VM handle
		return (VM_OPEN_OK)
	    endif
	else if access denied then
	    return (VM_SHARING_DENIED)
	else
	    create (name)
	    if ok then
		init VM handle
		return (VM_CREATE_OK)
	    else
		return (error)
	    endif
	endif
    endif

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
VMOpen	proc	far
	mov	ss:[TPD_dataBX], handle VMOpenReal
	mov	ss:[TPD_dataAX], offset VMOpenReal
	GOTO	SysCallMovableXIPWithDSDX
VMOpen	endp
CopyStackCodeXIP	ends
else

VMOpen	proc	far
	FALL_THRU	VMOpenReal
VMOpen	endp

endif

VMOpenReal	proc	far 	uses cx, dx, si, di, bp, ds, es
passedFlags	local	word	\
		push	ax
compaction	local	word	\
		push	cx
fileFlags	local	GeosFileHeaderFlags
fileAttributes	local	FileAttrs
returnValue	local	VMStatus
internalFlags	local	InternalVMFlags
driveStatus	local	DriveExtendedStatus

getAttrsDescs	local	3 dup(FileExtAttrDesc)	; for flags & attributes &
						;  drive status...
	ForceRef	passedFlags		; these are used in various
	ForceRef	fileFlags		;  subrs
	ForceRef	fileAttributes
	ForceRef	driveStatus
	ForceRef	getAttrsDescs
	.enter
EC <	call	FarAssertInterruptsEnabled				>

	;error-check command code

if	ERROR_CHECK
	push	ax
	and	ah, not VMO_NATIVE_WITH_EXT_ATTRS
	cmp	ah, VMOpenType
	ERROR_AE	OPEN_BAD_FLAGS
	pop	ax
	push	ax

	test	al, not mask VMAccessFlags
	ERROR_NZ	OPEN_BAD_FLAGS

	mov	ah, al
	and	ah, mask VMAF_FORCE_READ_ONLY or mask VMAF_FORCE_READ_WRITE
	cmp	ah, mask VMAF_FORCE_READ_ONLY or mask VMAF_FORCE_READ_WRITE
	ERROR_Z	OPEN_BAD_FLAGS

	pop	ax
endif

	LoadVarSeg	es
	;
	; Gain exclusive access to the VM system so we can properly determine
	; if anyone else has the thing open.
	;
	call	PvmSemFar			;lock vmSem

	;
	; Fetch the necessary attributes from any existing file.
	; 
	call	VMOpenGetFileAttrs
	jc	toDone

	;
	; Use those and the VMAccessFlags we were given to compute a set of
	; FileAccessFlags and other things to use in the actual open call.
	; 
	call	VMMapModeToFlags	;al <- access flags
	jc	toDone

	;
	; Now open or create the file, as appropriate.
	; 
	call	VMOpenDoOpen		; bx <- file handle, ax <- VMStatus
	jc	toDone
	
	mov	ss:[returnValue], ax	; record in case it gets biffed...

	cmp	ax, VM_CREATE_OK
	je	fileCreated

	;----------------------------------------------------------------------
	; existing file successfully opened
	;
	; If we are opened in a mode than allows shared memory then check for
	; the file already being open

	test	internalFlags, mask IVMF_BLOCK_LEVEL_SYNC
	jz	errorCheckFile		; => ignore other open

	tst	si
	jnz	sharing

errorCheckFile:
	;
	; Existing file opened and not sharing
	; 

	call	CreateVMHandle
	;
	; Retrieve file header and error-check it. This gives us back the
	; header size and position, but we don't care.
	;

	; XXX: We really should grab the exclusive here, but this causes
	;      death if the file is corrupt (since we are trying to get
	;      exclusive access to the file in order to do the corruption
	;      test).

;;;	call	VMStartExclusiveInternalNoTimeout
	call	VMReadFileHeader
;;;	call	VMReleaseExclusive

	jnc	doneOK

	; this used to check to make sure the file contained at least a
	; VMFileHeader and a VMHeader, but I think VMReadFileHeader performs
	; enough consistency checks to take care of it...

	;---------------------
	; File be hosed -- close the handle before returning an error

	push	bx, ds
	LoadVarSeg	ds
	mov	bx, ds:[bx].HF_otherInfo
	call	FarFreeHandle
	pop	bx, ds
	mov	ax, VM_OPEN_INVALID_VM_FILE

closeReturnError:
	push	ax			; save error code
	clr	al			; allow errors during close (we ignore
					;  them)
	call	FileCloseFar
	pop	ax
	stc
toDone:
	jmp	done

	;--------------------
fileCreated:
	;
	; File was created, so now create the actual VM handle and so forth.
	;
	;ax - status code
	;bx - file handle

	call	VMCreateFileHeader
	jc	closeReturnError

	call	CreateVMHandle

	mov	cx, compaction
	call	VMCreateHeader		;destroys ax, cx, di
	jmp	doneOK

	;--------------------
sharingError:
	mov	ax, VM_SHARING_DENIED
	jmp	closeReturnError

sharing:
	;
	; File opened and sharing resources with another open.
	; 

EC<	call	AssertESKdata						>
	;
	; Point the new handle at the existing file-table entry, as there's
	; no point in having two entries open to the same file, given that
	; only one thing can be writing to it at once, so only one file offset
	; is needed...
	; bx = file handle just opened
	; si = other handle open (VM-wise) to the same file
	;
	; Make sure that our VM flags are compatible with the other open
	;
	mov	si, es:[si].HF_otherInfo	;si <- existing HandleVM
	test	es:[si].HVM_flags, mask IVMF_BLOCK_LEVEL_SYNC
	jz	sharingError

	clr	al		; no errors on close
	call	FileCloseFar
	mov	bx, es:[si].HVM_fileHandle
	call	FileDuplicateHandle
	mov_tr	bx, ax	; bx <- new handle

	mov	es:[bx].HF_otherInfo, si	;point new handle at VM handle
	inc	es:[si].HVM_refCount		;flag another reference to the
						; file.

	push	bp
	mov	bp, si				;bp <- existing HandleVM	
EC<	call	VMCheckVMHandle						>
	call	VMCheckDirtyOnOpen
	pop	bp

doneOK:
	clc					;clear error flag
	mov	ax, returnValue

done:
	;
	; ax = VMStatus
	; carry set if error
	; carry clear if ok:
	; 	bx	= file handle
	; 
	call	VvmSemFar		;release vmSem
	jc	mapFileErrorToVMStatus

	; deal with read-only shared-single open *after* releasing vmSem so
	; we don't end up with mixed semaphores if someone tries to open
	; a VM file while holding the exclusive on another one.

	push	ax, bp
	call	VMStartExclusiveInternalNoTimeout
	call	EnterVMFileFar			;FaultIn expects the VM file
						;to be entered
	call	VMFaultInBlocksIfNeeded
	;
	; now, set the dirty limit in the header and set the dirty
	; size in the VM Handle to -1.
	;
	mov	ds:[VMH_blockTable].VMBH_uid, VM_DIRTY_LIMIT_NOT_SET
	;
	; now, set the new dirty size to -1 (since we start out async by
	; default..), but first, check if a reloc Routine exists, if it
	; does, we do nothing..
	;
	INT_OFF
	tst	es:[bp].HVM_relocRoutine.segment
	jnz	relocPresent
	;
	; very quickly, set the offset negative to signify that the
	; dirty limit is neither accurate nor desired
	;
	mov	{byte}es:[bp].HVM_relocRoutine.offset.high, -1
relocPresent:
	INT_ON
	andnf	es:[si].HM_flags, not mask HF_DISCARDABLE ; header's dirty!

	call	ExitVMFileFar
	call	VMReleaseExclusive
	pop	ax, bp

	; make sure that any db stuff is also sane...

	call	DBCheckDBFile
	jnc	exit
	mov	al, FILE_NO_ERRORS
	call	VMClose
	mov	ax, VM_OPEN_INVALID_VM_FILE
error:
	stc
exit:

	.leave
	ret
mapFileErrorToVMStatus:
	;
	; Map a FileError code to an appropriate VMStatus return code.
	; 
	cmp	ax, first VMStatus
	jae	error			; => already mapped

	mov_tr	dx, ax
	mov	ax, VM_SHARING_DENIED
	cmp	dx, ERROR_ACCESS_DENIED
	je	error
	cmp	dx, ERROR_SHARING_VIOLATION
	je	error
	
	mov	ax, VM_WRITE_PROTECTED
	cmp	dx, ERROR_WRITE_PROTECTED
	je	error
	
	mov	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
	cmp	dx, ERROR_SHORT_READ_WRITE
	je	error
	
	mov	ax, VM_FILE_FORMAT_MISMATCH
	cmp	dx, ERROR_FILE_FORMAT_MISMATCH
	je	error

	mov	ax, VM_FILE_NOT_FOUND
	cmp	dx, ERROR_FILE_NOT_FOUND
	je	error

	mov	ax, VM_FILE_EXISTS
	cmp	dx, ERROR_FILE_EXISTS
	je	error

	mov	ax, VM_CANNOT_CREATE	; assume something reasonable.
	jmp	error
VMOpenReal	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMMapModeToFlags

DESCRIPTION:	Given VMAccessFlags, return FileAccessFlags and set up
		the internal flags

CALLED BY:	VMOpen

PASS:
	ss:bp - inherited variables

RETURN:
	carry - set if error (file incompatible with passed flags)
		ax - error code
	carry clear if ok:
		al - FileAccessFlags
		di - VMStatus to return on successful open
		internalFlags - set

DESTROYED:
	bx, cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/31/91		Initial version

------------------------------------------------------------------------------@
VMMapModeToFlags	proc	near
	.enter inherit VMOpenReal

	; set defaults

	clr	al
	mov	cl, internalFlags	;cl = InternalVMFlags
	mov	ch, passedFlags.low	;ch = VMAccessFlags
	mov	bx, fileFlags		;bx = GeosFileHeaderFlags

	; the final InternalVMFlags and FileAccessFlags are a function of
	; InternalVMFlags: IVMF_FILE_LOCAL
	; passedFlags: VMAF_FORCE_READ_ONLY, VMAF_FORCE_READ_WRITE,
	;	       VMAF_FORCE_DENY_WRITE, VMAF_DISALLOW_SHARED_MULTIPLE,
	;	       VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION
	; GeosFileHeaderFlags: GFHF_SHARED_SINGLE, GFHF_SHARED_MULTIPLE

	; If we can open it, assume it is valid.  If it is truely invalid
	; we'll have problems when we attempt to open it.

	and	cl, not mask IVMF_INVALID_FILE

	; if USE_BLOCK_LEVEL_SYNCRONIZATION

	test	ch, mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION
	jz	notBlockLevel
	mov	di, VM_OPEN_OK_BLOCK_LEVEL
	or	cl, mask IVMF_BLOCK_LEVEL_SYNC or mask IVMF_DEMAND_PAGING
	dec	al			;default read-write
	clc				;deny write based on flag
	call	VMComputeFileAccess
	jmp	doneGood

	; not USE_BLOCK_LEVEL_SYNCRONIZATION

notBlockLevel:
	test	cl, mask IVMF_FILE_LOCAL
	jnz	noFileLock
	or	cl, mask IVMF_NEED_FILE_LOCK
noFileLock:
	test	bx, mask GFHF_TEMPLATE
	jnz	template

	test	bx, mask GFHF_SHARED_MULTIPLE
	jnz	sharedMultiple

	test	ch, mask VMAF_FORCE_SHARED_MULTIPLE
	jnz	sharedMultiple

	test	bx, mask GFHF_SHARED_SINGLE
	jnz	sharedSingle

	; file not shared

notShared:
	mov	di, VM_OPEN_OK_READ_WRITE_NOT_SHARED
	dec	al			;default read-write
	stc				;force deny write if read/write
	call	VMComputeFileAccess
demandPagingIfReadWrite:
	cmp	di, VM_OPEN_OK_READ_ONLY
	jz	doneGood
	or	cl, mask IVMF_DEMAND_PAGING
	jmp	doneGood

	; file is a template -- treat templates with "force read-write" as
	; if they are not templates

template:
	test	ch, mask VMAF_FORCE_READ_WRITE
	jnz	notShared
	mov	di, VM_OPEN_OK_TEMPLATE
	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	jmp	demandPaging

	; file is "shared single"

sharedSingle:
;;;	or	cl, mask IVMF_DEMAND_PAGING	;NOT NOW...
	mov	di, VM_OPEN_OK_READ_WRITE_SINGLE
					;default read-only
	stc				;force deny write if read/write
	call	VMComputeFileAccess
	jmp	demandPagingIfReadWrite

	; file is "shared multiple"

sharedMultiple:
	test	ch, mask VMAF_DISALLOW_SHARED_MULTIPLE
	jnz	error
	mov	di, VM_OPEN_OK_READ_WRITE_MULTIPLE
	dec	al			;default read-write
	clc				;deny write based on flag
	call	VMComputeFileAccess
	jmp	demandPagingIfReadWrite

doneGood:

if FLOPPY_BASED_DOCUMENTS

demandPaging:
	;
	; Unless a certain flag is passed to force demand paging, we won't
	; have it, due to the slowness of accessing floppies.  However,
	; if the VMAF_NO_DEMAND_PAGING flag is set, we will DEFINITELY
	; not have demand paging, as it's probably set to avoid memory 
	; problems.   6/6/94 cbh
	;
	or	cl, mask IVMF_DEMAND_PAGING
	test	ch, mask VMAF_NO_DEMAND_PAGING
	jz	afterDemandPaging
	and	cl, not mask IVMF_DEMAND_PAGING	;Let's not have demand paging
						;  for floppy-based files, it's
						;  muy painful.  -cbh 1/ 7/94
afterDemandPaging:

else

	; if file is read-only then allow demand paging
	; if "deny write" then allow demand paging
	; if file is on write protected media then allow demand paging
	; LATER: check destination disk handle, perhaps, as this just shows
	; if the drive itself is read-only, not if the disk is.

	test	ch, mask VMAF_FORCE_DENY_WRITE
	jnz	demandPaging
	test	driveStatus, mask DES_READ_ONLY
	jnz	demandPaging
	test	fileAttributes, mask FA_RDONLY
	jz	afterReadOnly
demandPaging:
	or	cl, mask IVMF_DEMAND_PAGING
afterReadOnly:

endif

	mov	internalFlags, cl

	clc				;no error
exit:
	.leave
	ret

error:
	mov	ax, VM_CANNOT_OPEN_SHARED_MULTIPLE
	stc
	jmp	exit

VMMapModeToFlags	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMComputeFileAccess

DESCRIPTION:	Compute the FileAccessFlags based on a jumbled mass of bits
		passed

CALLED BY:	(INTERNAL) VMMapModeToFlags

PASS:
	al - non-zero if default is read/write
	     zero if default is read-only
	carry - set to force deny write if access is read-write
		clear if is deny write is based on VMAF_FORCE_DENY_WRITE
	ch - VMAccessFlags
	di - return value if file not opened read only

RETURN:
	al - FileAccessFlags
	di - return value

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 1/91		Initial version

------------------------------------------------------------------------------@
VMComputeFileAccess	proc	near
	pushf				;save deny flag

	tst	al
	mov	al, FileAccessFlags <0, FA_READ_WRITE>
	jz	defaultReadOnly

	; default is read-write

	test	ch, mask VMAF_FORCE_READ_ONLY
	jnz	readOnly
readWrite:
	popf
	jnc	common
denyWrite:
	or	al, FE_DENY_WRITE shl offset FAF_EXCLUDE
	ret

	; default is read-only

defaultReadOnly:
	test	ch, mask VMAF_FORCE_READ_WRITE
	jnz	readWrite
readOnly:
	mov	di, VM_OPEN_OK_READ_ONLY ;di = return value
	mov	al, FileAccessFlags <0, FA_READ_ONLY>
	popf				;discard deny flag

common:
	test	ch, mask VMAF_FORCE_DENY_WRITE
	jnz	denyWrite
	or	al, FE_NONE shl offset FAF_EXCLUDE
	ret

VMComputeFileAccess	endp

VMOpenCode	ends

VMHigh		segment	resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMAlloc

DESCRIPTION:	Allocate a VM block handle.

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		ax - user specified id.
		cx - number of bytes (may be 0, in which case no associated
		     memory is allocated; memory must be allocated separately
		     and given to the block with VMAttach)

RETURN:		ax - VM block handle, marked dirty if memory actually allocated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	detach an unassigned block
	mark block used
	allocate handle and bytes
	store handle in memHandle field of block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	once an id is used, all subsequent calls to VMAlloc by the same thread
	should specify a unique id, or calls to VMFind will return inconsistent
	results

	Dirties header via VMGetUnassignedBlk

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMAlloc		proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

	push	si

	call	VMGetUnassignedBlk		;detach an unassigned block
	call	VMMarkBlkUsed
	mov	ds:[di].VMBH_uid, ax		;store user id

	; if 0 passed then allocate no memory handle

	clr	si				;assume no bytes
	jcxz	20$

	xchg	ax, cx				;num bytes in ax (1-byte inst)
	mov	cx, mask HAF_ZERO_INIT shl 8	;zero-initialize the memory
						; and mark it dirty (by
						; virtue of not passing
						; HF_DISCARDABLE)
	call	VMGetMemSpaceAndSetOtherInfo	;si <- func(ax, bx, ds)

	inc	ds:[VMH_numResident]

20$:
	; deal with dirty notification
	call	NotifyDirtyFar

	mov	ds:[di].VMBH_memHandle, si	;store it

	mov	ax, di				;return VM block handle in ax
	pop	si

	call	VMMaintainExtraBlkHansFar

	;
	; Make sure we do not have too many resident handles
	;
	call	VMEnforceHandleLimit

	jmp	VMPop_ExitVMFileFar

VMAlloc		endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMFind

DESCRIPTION:	Given the VM block user id, locate and return the first
		VM block handle whose id field matches the argument.

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		ax - user id
		cx - 0 to find first block with the given ID, or a vm block
		     handle to find the next block with the given ID

RETURN:		carry - clear if found, set otherwise
		ax - VM block handle if found, else ax = 0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMFind	proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

	mov	di, VMH_blockTable	; Start search after header (if
	jcxz	10$			; 0 was passed)
	mov	di, cx			; else start at cx
10$:
	call	VMGetNextUsedBlk
	jc	none

	cmp	ds:[di].VMBH_uid, ax
	jne	10$

	;found
	mov	ax, di
EC<	call	VMCheckStrucs						>
EC<	clc								>
	jmp	short 90$
none:
	;not found
	clr	ax
	stc
90$:
	jmp	VMPop_ExitVMFileFar

VMFind	endp

VMHigh	ends



kcode	segment
COMMENT @----------------------------------------------------------------------

FUNCTION:	VMLock

SYNOPSIS:	Lock the given VM handle.  Load in the data if necessary.
		Give the caller's thread exclusive access to the block.

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		ax - VM block handle

RETURN:		ax - segment of locked VM block
		bp - memory handle of locked VM block (needed for MemReAlloc)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@
VMLock	proc	far
EC <		call	ECCheckStack					>
EC <	call	VMCheckFileHandle					>
EC <	call	FarAssertInterruptsEnabled				>
	;
	; OPTIMIZATION -- this thing is currently really, really slow. To
	; speed it up in the common case (single-thread using the file, block
	; already in memory), we do a bit of extra work to see if we can safely
	; just snag the block handle from the header and run with it. We
	; can't be quick if:
	;	1) the VM header isn't in memory (HVM_headerHandle is 0)
	;	2) the VM header is in memory but it's being moved (the
	;	   HM_addr field of the header handle is 0)
	;	3) the VM header is grabbed by someone else
	;	4) the passed block isn't in memory.
	; All these cases are tested for in the code below.
	;
	push	ds, bx, di
	LoadVarSeg	ds, di		; we want speed, dammit..
	INT_OFF				; ensure consistency.

	; We don't need to check for the VM semaphore, we'll check the owner
	; of the header later

	; Case (1)
	mov	di, ds:[bx].HF_otherInfo
	mov	di, ds:[di].HVM_headerHandle
	tst	di			; header around?
	jz	slow			; no => do it the slow way
	
	; Case (2) and (3)
	cmp	ds:[di].HM_lockCount, 0
	jne	headerGrabbed

continueOptimization:
	mov	di, ds:[di].HM_addr
	tst	di			; header in transit?
	jz	slow			; yes => do it the slow way
	
	; Case (4)
	mov	ds, di
	mov_tr	di, ax			; di <- VM block
EC <	call	VMCheckUsedBlkHandle					>

	mov	bx, ds:[di].VMBH_memHandle
	tst	bx			; block resident?
	jz	slowRestoreBlk		; no => do it the slow way

	; If this file is only accessed by one thread then lock lock it

	test	ds:[VMH_attributes], mask VMA_SINGLE_THREAD_ACCESS
	jz	multiThread

	LoadVarSeg	ds, ax
	FastLock1	ds, bx, ax, VML_1, VML_2

optExit:
	mov	bp, bx			; return handle in BP
	pop	ds, bx, di
	ret

multiThread:
	; Grab the sucker. We've still got interrupts off at this point,
	; so we're ok.
	call	MemThreadGrab
	jc	slowRestoreBlk		; block discarded => do it the slow way
	jmp	optExit

	;
	; The header is grabbed.  It is grabbed by us then we can still
	; optimize
	;
headerGrabbed:
	mov	bx, ds:[bx].HM_usageValue
	cmp	bx, ds:[currentThread]
	jz	continueOptimization
	jmp	slow

	; FastLock2	ds, bx, ax, VML_1, VML_2

???_VML_2:
	INT_ON
	call	FullLockNoReload
	jnc	???_VML_1

slowRestoreBlk:
	xchg	ax, di			; ax <= VM block handle again	
slow:
	;
	; Unoptimized case. Go through the full histrionics to enter the
	; VM file, etc. etc. etc.
	; 
	pop	ds, bx, di
	INT_ON
	call	VMPush_EnterVMFile

	mov	di, ax			;pass VM block handle in di
EC <	call	VMCheckUsedBlkHandle					>

	;get block data (init ax, cx, dx, si)
	mov	si, ds:[di].VMBH_memHandle
	tst	si
	jz	notResident

	; check for block discarded (VMBF_PRESERVE_HANDLE can do this). We can
	; safely check this as VMBlockBiffable won't allow the block to go away
	; while we've got the header grabbed.
	test	es:[si].HM_flags, mask HF_DISCARDED
	jz	resident
notResident:

	; We check to see if we need to biff any blocks to stay below the 
	; handle limit here, while the header is still grabbed, and before
	; we read in the block we are trying to lock (otherwise, we might
	; kick out the block we just read).

	call	VMEnforceHandleLimit
	;
	; Make sure we've got enough unassigned handles around.
	; This can also biff the block we just read, so do it before VMReadBlk.
	; Assign two extra handles, to account for the resident block we're about
	; to make.  (EC code dies if we muck with VMH_numResident.)
	; mevissen, 5/99
	;
	add	ds:[VMH_numExtraUnassigned], 2
	call	VMMaintainExtraBlkHans
	sub	ds:[VMH_numExtraUnassigned], 2

	mov	ax, ds:[di].VMBH_fileSize
	mov	cx, ds:[di].VMBH_filePos.high
	mov	dx, ds:[di].VMBH_filePos.low

	call	VMReadBlk		;destroys ax, cx, dx; stores handle
					; and increases VMH_numResident
EC<	call	VMCheckMemHandle	;check si			>

resident:
EC<	call	VMCheckStrucs						>

	;
	; Release the header and file before trying to grab the block. This
	; allows other people to lock blocks if we need to wait. In a normal
	; synchronization hierarchy, this wouldn't be necessary, but this isn't
	; normal as a caller could have a block grabbed and try to grab another
	; one. If we're not careful here, we deadlock, so...
	;
	;es - idata seg
	;bx - VM file handle
	;bp - VM mem handle
	;

EC<	call	AssertESKdata						>
EC<	call	VMCheckFileHandle					>

	;
	; There used to be a window of vulnerability in here when we would
	; release the header and then the HandleVM. If we context switched
	; between the header release and the VvmFileNoSwitch, VMBlockBiffableLow
	; would think any block, including the one we just read in, was fair
	; game for nuking. In fact, we actually had a case where the block
	; got biffed, and therefore freed. To get around this, without blocking
	; with the interruptCount non-zero (which would be very deadly), we
	; split SysExitCritical into two parts:
	;
	;    There is another important case that must be avoided: we must
	;    not call MemThreadGrabNB with interruptCount non-zero, since
	;    we may have to block in order to swap the block in.
	;
	;    We decrement interruptCount and call MemThreadGrabNB with
	;    interrupts off.
	;
	;    If we cannot immediately get the block (someone else has it), it
	;    is safe to just perform a regular blocking thread-grab on the
	;    block.  The act of blocking trying to grab the block will have
	;    the same effect as the second half of SysExitCritical.
	;    Since we're hanging out on the block, it should not get unlocked
	;    by the MemThreadRelease, so the block will not get freed from
	;    under us. 
	;
	;    If we were able to grab the block initially, we have only to
	;    check if a wakeup was aborted by our having called
	;    SysEnterCritical and perform a WakeUpRunQueue, to ensure the
	;    highest-priority thread is actually running, before continuing
	;    with our life.  Also, in this case MemThreadGrabCommon will not
	;    turn interrupts on until after we safely have the HF_otherInfo
	;    field of the block set to 0, which will prevent VMBlockBiffableLow
	;    from trying to biff it.
	;
	;    -- ardeb 8/6/90, tony 10/17/90
	;
	; This used to clear ECF_SEGMENT before calling ExitVMFile to avoid
	; grabbing the heap sem when nulling out segment registers. However,
	; MemThreadRelease has long since been changed to specially check
	; the segments against the block being released and decide based on
	; that whether to set them to NULL_SEGMENT, so nothing in ExitVMFile
	; should cause the heap semaphore to be grabbed. -- ardeb 10/24/95
	;

	call	SysEnterCritical
	push	si
	call	ExitVMFile
	;
	; Now grab the block in question
	;
	pop	bx				;bx = mem handle
	INT_OFF
	dec	es:[interruptCount]
	;
	; *** Special case: if single threaded then lock it
	;
	; To get around EC code that does not allow locking blocks owned by
	; a VM file, change the owner temporarily
	;
	cmp	es:[bx].HM_otherInfo, -1
	jnz	multiThread2
EC <	push	es:[bx].HM_owner					>
EC <	mov	ax, ss:[TPD_processHandle]				>
EC <	mov	es:[bx].HM_owner, ax					>
	FastLock1	es, bx, ax, VML3, VML4
EC <	pop	es:[bx].HM_owner					>
	jmp	checkWakeup

multiThread2:
	call	MemThreadGrabCommon
	jnc	checkWakeup
	call	MemThreadGrab
haveBlock:
	INT_ON

	;
	; Return the memory handle in bp, but have to modify stored frame
	; to do so.
	;
	mov	bp, sp
	mov	ss:[bp].VMPOES_bp, bx

	jmp	VMPop_NoExitVMFile

checkWakeup:
	;
	; Gross second part of "in-line" SysExitCritical.
	;
	inc	es:[interruptCount]
if TRACK_INTERRUPT_COUNT and ERROR_CHECK
	cmp	es:[interruptCount], 1
	jnz	notZeroToOne
	movdw	es:[intCountStack], sssp
	mov	es:[intCountType], INT_COUNT_VM_LOCK
	mov	es:[intCountData], bx
notZeroToOne:
endif
	call	SysExitCritical
	jmp	haveBlock

	FastLock2	es, bx, ax, VML3, VML4

VMLock	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMUnlock

C DECLARATION:	extern void
			_pascal VMUnlock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
VMUNLOCK	proc	far
	on_stack	retf
	mov	dx, offset VMUnlock
dirtyUnlockCommon label far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	xchg	ax, bp
	push	cs
	call	dx
	xchg	ax, bp
	ret

VMUNLOCK	endp
	SetDefaultConvention

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMUnlock

DESCRIPTION:	Unlock a VM block

CALLED BY:	GLOBAL

PASS: 		bp - Memory handle of locked VM block (NOT the VM
	 	     block handle)
RETURN:		nothing

DESTROYED:	
	Non-EC: Nothing (flags preserved)

	EC:	Nothing (flags preserved), except, possibly for DS and ES:

		If segment error-checking is on, and either DS or ES
		is pointing to a block that has become unlocked,
		then that register will be set to NULL_SEGMENT upon
		return from this procedure. 


PSEUDO CODE/STRATEGY:
	If VM file is only usable by a single thread, then
		just unlock the block
	otherwise, 
		call	MemThreadRelease

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version
	ardeb	4/17/94		Changed VMEM_DISCARD code to make sure the
				block is still a VM block, and then to call
				VMBlockBiffable first

-------------------------------------------------------------------------------@

VMUnlock	proc	far

EC <	call	FarAssertInterruptsEnabled				>

	pushf
	push	ax
	push	ds
	LoadVarSeg	ds, ax

	; check for a VM file accessed by a single thread

	cmp	ds:[bp].HM_otherInfo, -1
	jnz	multiThread

	FastUnLock	ds, bp, ax, NO_NULL_SEG

	pop	ds
popDone:
	; Make sure that NullSegmentRegisters gets called from both
	; flows of execution

EC <	call	NullSegmentRegisters					>

if	ERROR_CHECK
	push	ax, bx, dx, bp, ds
	mov	bx, bp
	call	LoadVarSegDS
	test	ds:[sysECLevel], mask ECF_VMEM_DISCARD
	jz	noDiscard
	call	PHeap

	; Make sure the block is still a VM block (i.e. it wasn't biffed after
	; the unlock happened)
	; It's possible that the block could be freed and the handle reused for
	; another VM file, but if the block is unlocked, nuking it shouldn't
	; cause any problems, I hope... -- ardeb 4/17/94
	
	mov	bp, ds:[bx].HM_owner		;bp = VM handle
	tst	bp
	jz	afterBiff			; => block free
	cmp	ds:[bp].HG_type, SIG_VM
	jne	afterBiff			; => block freed, then allocated
						;  for something else

	test	ds:[bx].HM_flags, mask HF_DISCARDABLE
	jz	afterBiff

	; First call VMBlockBiffable on the thing, so we're sure the header
	; block is in memory before we zero the HM_addr and call
	; VMUpdateAndRidBlk. Failure to do this will cause a CORRUPTED_HEAP
	; death should VMUpdateAndRidBlk be the one required to bring the
	; header back into memory from the swap device -- ardeb 4/17/94

	call	VMBlockBiffable
	jc	afterBiff

	clr	dx
	xchg	dx, ds:[bx].HM_addr		;dx = addr

	tst	ds:[bx].HM_lockCount
	jnz	restoreSegment
	
	call	VMUpdateAndRidBlk		;nuke it
	jnc	afterBiff

restoreSegment:
	mov	ds:[bx].HM_addr, dx

afterBiff:
	call	VHeap

noDiscard:
	pop	ax, bx, dx, bp, ds
endif

	pop	ax
	popf
	ret

multiThread:
	pop	ds			; do now so that
					; MemThreadRelease will actually
					; NullSeg at the correct time
					; (before any waiting threads
					; can lock and foul up the NullSeg)
	xchg	bx, bp
	call	MemThreadRelease
	xchg	bx, bp
	jmp	popDone

VMUnlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMDiscardDirtyBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discards all dirty blocks in a VM file

CALLED BY:	GLOBAL

PASS:		bx - VM file handle

RETURN:		carry clear if successful,
			ax = 0 or VM_UPDATE_NOTHING_DIRTY 
		carry set if error, 
			ax = VMStatus
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMDiscardDirtyBlocks		proc	far

EC <	call	FarAssertInterruptsEnabled				>

	mov	ax, VMO_INTERNAL
	call	VMStartExclusiveNoTimeout
	call	VMPush_EnterVMFileFar		

	LoadVarSeg	es, ax
	;
	; optimization:
	; if the file is not modified then there is nothing to discard
	;
	push	bx
	mov	bx, es:[bx].HF_otherInfo	;bx = VM handle
	test	es:[bx].HVM_flags, mask IVMF_FILE_MODIFIED
	pop	bx
	jnz	noOpt
	mov	ax, VM_UPDATE_NOTHING_DIRTY
	clc
	jmp	noReadHeader
done:
	;
	; If the file is not in backup mode, we need to re-read the
	; header, so that any blocks which have been freed will be
	; restored.  For files which have VMA_BACKUP set, this is taken
	; care of by creating zombie blocks in VMFree for blocks which
	; don't already have a backup block.
	;
	test	ds:VMH_attributes, mask VMA_BACKUP
	jnz	noReadHeader
	;
	; Free the VMHeader, which is locked. Must change the owner
	; so EC code won't barf.
	;
	mov	bp, es:[bx].HF_otherInfo	;bp = HandleVM
	clr	bx
	xchg	bx, es:[bp].HVM_headerHandle
EC <	mov	ax, ss:[TPD_processHandle]				>
EC <	mov	es:[bx].HM_owner, ax					>
	call	MemFree
	;
	; Read the old VMHeader from file. Because we are passing si = 0,
	; a new block will be allocated and the data will be read from file.
	;
	segmov	ds, es, ax			; ds = idata
	clr	si				; no VMHeader handle
	mov	bx, es:[bp].HVM_fileHandle	; bx = file handle
	call	VMLoadHeaderBlk			; ^hsi <- header block
	;
	; Must lock the header again to match the number of unlocks
	; which will happen when we release the exclusive and exit
	; the file.
	;
	segmov	ds, es, ax			; ds = idata
	call	VMLockHeaderBlk			; ds <- VM header
	clc					; return no error
		
noReadHeader:		
EC <	call	VMCheckStrucs						>
	call	VMReleaseExclusive
	jmp	VMPop_ExitVMFileFar


noOpt:
	mov	di, offset VMH_blockTable
freeLoop:
	call	VMGetNextInUseBlk
	cmc
	jnc	done

	cmp	ds:[di].VMBH_sig, VMBT_ZOMBIE	; revert it to a DUP block 
	je	restoreZombie
	cmp	ds:[di].VMBH_sig, VMBT_BACKUP
	je	checkForBackupZombie
	;
	; Block is a DUP block or a USED block.
	; If the block is not in memory, it is not dirty, so skip it.
	;
	mov	bp, ds:[di].VMBH_memHandle
	tst	bp		
	jz	freeLoop
	;
	; If the block is discardable, it is not dirty, so skip it.
	;
;;
;; WRONG! For a file which is does not have VMA_BACKUP set, we will 
;; re-read the header after discarding all blocks. If this is a new
;; block which is not referenced in the old header, it will be "lost"
;; once this new header is gone. Just discard all blocks.
;;
;;	test	es:[bp].HM_flags, mask HF_DISCARDABLE
;;	jnz	freeLoop

	call	DiscardDirtyBlock
	jnc	freeLoop			; no error, continue
	jmp	noReadHeader			; we're hosed....

restoreZombie:
	tst	ds:[di].VMBH_fileSize		; special ZOMBIE blocks have
	jz	freeLoop			;   non-zero filesize.
	mov	ds:[di].VMBH_sig, VMBT_DUP
	inc	ds:[VMH_numUsed]		; ZOMBIE blocks don't count 
						;  as used, DUP blocks do
	jmp	freeLoop

checkForBackupZombie:
	;
	; A USED block with a backup that has been freed since the last
	; update will be turned into a zombie, and all of its filespace
	; is given to the backup block.  If this block is backing up 
	; a zombie block, restore the zombie to used and turn this
	; block into a zombie, giving its filespace back to the used block.
	;
	push	si
	mov	si, ds:[di].VMBH_uid
	cmp	ds:[si].VMBH_sig, VMBT_ZOMBIE
	jne	continue
EC <	test	ds:[si].VMBH_flags, mask VMBF_HAS_BACKUP	>
EC <	ERROR_Z VM_DISCARD_DIRTY_BLOCKS_LOGIC_ERROR		>
	;
	; Promote the ZOMBIE block to be a real USED block again
	;
	mov	ds:[si].VMBH_sig, VMBT_USED
	andnf	ds:[si].VMBH_flags, not mask VMBF_HAS_BACKUP
	inc	ds:[VMH_numUsed]		; inc the # of used blocks
	;
 	; Transfer file space to the USED block.
	;		
	mov	ax, ds:[di].VMBH_fileSize
EC <	tst	ax						>
EC <	ERROR_Z VM_DISCARD_DIRTY_BLOCKS_LOGIC_ERROR		>
	mov	ds:[si].VMBH_fileSize, ax
	movdw	dxax, ds:[di].VMBH_filePos
	movdw	ds:[si].VMBH_filePos, dxax
	;
	; Free the old backup block and its memory.  
	;
	tst	ds:[di].VMBH_memHandle
	jz	noGrab
	mov	bp, ds:[di].VMBH_memHandle
	call	GrabBlock
noGrab:		
	call	VMDiscardMemBlk				; free the mem block
	call	VMFreeBlkHandle				; free the vm block
continue:
	pop	si
	jmp	freeLoop
		
VMDiscardDirtyBlocks		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscardDirtyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discard a dirty block.

CALLED BY:	VMDiscardDirtyBlocks
PASS:		ds - VMHeader
		ds:di - VMBlockHandle (di = VMBlock handle)
		bp - VM block MemHandle
		bx - VM file handle
		es - idata seg
RETURN:		error if carry set,
			ax = VMStatus
		else
			ax = 0
DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscardDirtyBlock		proc	near
	uses	bx, ds, es
	.enter

EC<	test	ds:[di].VMBH_sig, VM_IN_USE_BIT				>
EC<	ERROR_Z	VM_DISCARDING_NON_USED_BLOCK				>
EC<	cmp	ds:[di].VMBH_sig, VMBT_DUP				>
EC<	ERROR_B VM_DISCARDING_NON_USED_BLOCK				>

	call	GrabBlock
	;
	; If the block has no file space, discard the mem block
	; and free the vm handle. We can't call VMFree to do this,
	; as it might zombify a new DUP block which would want freed.
	;
	cmp	ds:[di].VMBH_fileSize, 0
	jne	haveFileSpace
	call	VMDiscardMemBlk
	call	VMFreeBlkHandle		
	jmp	short blockDone

haveFileSpace:
	;
	; We're removing one block from the heap, so make note of that.
	;
	dec	ds:VMH_numResident
	;
	; Grab the heap semaphore and discard the block's memory.
	;
	segxchg	ds, es				; ds <- idata
	mov	bx, bp				; bx <- block handle
	mov	dx, ds:[bx].HM_addr		; dx <- block address
	call	FarPHeap
	call	DoDiscard
	;
	; If the preserve handle bit is not set, free the handle and
	; clear the handle for the VMBlockHandle
	;
	test	es:[di].VMBH_flags, mask VMBF_PRESERVE_HANDLE
	jnz	releaseHeap
	mov	es:[di].VMBH_memHandle, 0	; Note no handle for block
	call	FreeHandle

releaseHeap:
	call	FarVHeap

EC <	call	ECMemVerifyHeapLow					>
EC <	call	AssertDSKdata						>
blockDone:
	clr	ax				; return no error
	clc

exit::
	.leave

EC <	pushf								>
EC <	call	VMCheckDSHeader						>
EC <	popf								>

	ret

if 0
;; GrabLock now FatalErrors if it cannot lock the block, so this is 
;; unnecessary.
;;
cantLock:
	mov	ax, VM_DISCARD_CANNOT_DISCARD_BLOCK
	stc
	jmp	exit
endif
		
DiscardDirtyBlock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab exclusive access to a block

CALLED BY:	DiscardDirtyBlock, 
PASS:		ds - VMHeader
		bp - block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabBlock		proc	near
	uses	ax, bx
	.enter
	;
	; Check if this thread has exclusive access to the file.
	;
	test	ds:[VMH_attributes], mask VMA_SINGLE_THREAD_ACCESS
	jnz	exit
	;
	; If not, check whether another thread has already locked the
	; block.  If so, we can't very well biff it.
	;
	mov	bx, bp
	call	MemThreadGrabNB			; carry set if error
	ERROR_C	VM_CANT_GRAB_BLOCK_SO_DISCARD_FAILED	
	tst	ax				; is it already discarded?
	jz	exit

	call	MemThreadRelease		; preserves flags

exit:
	.leave
	ret
GrabBlock		endp

kcode	ends


VMOpenCode	segment	resource
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetDirtyState

DESCRIPTION:	Find out whether a VM file has been modified since the last
		save.

CALLED BY:	GLOBAL

PASS:		bx - VM file handle

RETURN:		al - non-zero if DIRTY since last save
		ah - non-zero if DIRTY since last auto-save

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Note that al (dirty since last save) is only valid if the file
	has the notify dirty bit set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMGetDirtyState		proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

	; if IVMF_NOTIFY_OWNER_ON_DIRTY is CLEAR then the file has been changed
	; since the last save

	; if IVMF_FILE_LOCAL is SET then the file has been changed since the
	; last auto-save

	mov	al, es:[bp].HVM_flags		;non-zero if clean
	mov	ah, al
	and	ax, mask IVMF_NOTIFY_OWNER_ON_DIRTY or \
			(mask IVMF_FILE_MODIFIED shl 8)
	xor	al, mask IVMF_NOTIFY_OWNER_ON_DIRTY

	jmp	VMPop_ExitVMFileFar

VMGetDirtyState		endp
VMOpenCode	ends



kcode		segment	resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMDirty

C DECLARATION:	extern void
			_far _pascal VMDirty(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
VMDIRTY	proc	far
	mov	dx, offset VMDirty
	jmp	dirtyUnlockCommon
VMDIRTY	endp
	SetDefaultConvention

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMDirty

DESCRIPTION:	Mark a VM block as dirty (altered). This must be done to
		a locked VM block before it is unlocked.

CALLED BY:	GLOBAL

PASS: 		bp - grabbed VM mem handle (NOT a VM block)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	clear discardable bit in mem handle

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMDirty		proc	far	uses es
	.enter
EC <	call	FarAssertInterruptsEnabled				>

	;
	; Error-checking code ensures the block is locked. This must be true
	; or there is a window of vulnerability between when the thing was
	; unlocked and now during which the block might be discarded.
	; 
EC <	push	bx							>
EC <	mov	bx, bp							>
EC <	call	CheckHandleLegal					>
EC <	call	CheckToUnlockNS						>
EC <	pop	bx							>
	LoadVarSeg es

	test	es:[bp].HM_flags, mask HF_DISCARDABLE
	jz	alreadyDirty

	andnf	es:[bp].HM_flags, not mask HF_DISCARDABLE

	;
	; need to do dirty size tracking
	;
	push	cx, si
	mov	cx, es:[bp].HM_size
	mov	si, es:[bp].HM_owner
	call	VMTestDirtySizeForModeChange
	pop	cx, si

	xchg	bx, bp

	call	NotifyDirty		; only do this the first time
					; - see VMA_NOTIFY_DIRTY comment
	xchg	bx, bp

alreadyDirty:
	.leave
	ret
VMDirty		endp
kcode	ends


VMHigh	segment	resource
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMFree

DESCRIPTION:	Free a VM block handle

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		ax - VM block handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header via VMFreeBlkHandle or VMBackupBlockIfNeeded

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMFree	proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

; don't let caller free header...
EC<	cmp	ax, offset VMH_blockTable				>
EC<	ERROR_BE	VM_BAD_BLK_HAN					>

	mov	di, ax
EC<	call	VMCheckUsedBlkHandle					>
	call	VMDiscardMemBlk
	test	ds:VMH_attributes, mask VMA_BACKUP
	jnz	zombify

freeIt:
	call	VMFreeBlkHandle
	call	VMCheckCompression	; Compress the file if free space
					;  now too high a percentage...
	jmp	VMPop_ExitVMFileFar

zombify:
	;
	; If the block has a backup copy or is VMBT_USED without a backup, we
	; can't free the handle until a VMSave is performed, so convert the
	; thing into a zombie block with a backup block holding the old file
	; space.
	;
    	test	ds:[di].VMBH_flags, mask VMBF_HAS_BACKUP
	jz  	createBackup

endZombify:
	dec	ds:[VMH_numUsed]	; Zombie blocks don't count as used
	mov	ds:[di].VMBH_sig, VMBT_ZOMBIE
	jmp	VMPop_ExitVMFileFar

createBackup:
	;
	; DUP w/o backup copies that *do* have file space cannot just
	; be freed, because then VMDiscardDirtyBlocks won't work properly.
	; We have to zombify such blocks, but can free DUPs w/o backup
	; copies that have no file space, as they were created since the
	; last save and have not been auto-saved.  -- cassie, 6/8/95
	;
	cmp	ds:[di].VMBH_sig, VMBT_DUP		; not DUP?
	jne	createIt				;  create Zombie
	tst	ds:[di].VMBH_fileSize			; no file space?
	jz	freeIt					;  just free it
	mov	ds:[di].VMBH_sig, VMBT_ZOMBIE	
	jmp	endZombify

createIt:
	push	si
	call	VMBackupBlockIfNeededFar;di = new block (copy of di [now in si])
	mov	di, si			;di <- block being freed (file space
					; taken away by VMBBIN)
	pop	si

	jmp	endZombify

VMFree	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMModifyUserID

DESCRIPTION:	Modify the user ID for a VM block handle

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		ax - VM block handle
		cx - new user ID

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMModifyUserID	proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

EC<	tst	ax							>
EC<	ERROR_Z	VM_BAD_BLK_HAN						>

	mov	di, ax
EC<	call	VMCheckUsedBlkHandle					>
	mov	ds:[di].VMBH_uid,cx

	call	VMMarkHeaderDirty
	call	NotifyDirtyFar
	jmp	VMPop_ExitVMFileFar

VMModifyUserID	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMUpdate

DESCRIPTION:	Flushes all dirty VM blocks onto disk.

CALLED BY:	GLOBAL

PASS:		bx - VM file handle

RETURN:		carry clear if successful, set otherwise
		ax - error code
		     0 or VM_UPDATE_NOTHING_DIRTY if successful, or
		     VM_UPDATE_INSUFFICIENT_DISK_SPACE if all blocks couldn't
		     	be written b/c the disk is full, or
		     VM_UPDATE_BLOCK_WAS_LOCKED if a block couldn't be written
		      	because it was grabbed by some other thread, or
		     some member of the FileError enum.
		     

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMUpdate	proc	far

EC <	call	FarAssertInterruptsEnabled				>
EC <	call	VMCheckFileHandle					>
	; optimization:
	; if the file is not modified then there is no need to update
	;
	; Note: this must be done before VMPush_EnterVMFile as that
	; function likes to force the header in and mark it dirty, causing
	; something to always be written...

	push	bx, ds
	LoadVarSeg	ds
	mov	bx, ds:[bx].HF_otherInfo	;bx = VM handle
	test	ds:[bx].HVM_flags, mask IVMF_FILE_MODIFIED
	pop	bx, ds
	jnz	noOpt
	mov	ax, VM_UPDATE_NOTHING_DIRTY
	ret

noOpt:
	mov	ax, VMO_UPDATE
	call	VMStartExclusiveNoTimeout
	call	VMAddExtraDiskLock
	call	VMPush_EnterVMFileFar

	; 10/6/95: clear VMH_noCompress if not in backup mode, to allow
	; sync-update files to be compressed during this call. -- ardeb
	push	{word}ds:[VMH_compressFlags]
	test	ds:[VMH_attributes], mask VMA_BACKUP
	jnz	doUpdate
	BitClr	ds:[VMH_compressFlags], VMCF_NO_COMPRESS
doUpdate:
	call	VMUpdateLowRealAttrs
	pop	{word}ds:[VMH_compressFlags]

	call	VMReleaseExclusive
	jmp	VMPop_ExitVMFileFar_ReleaseExtraDiskLock

VMUpdate	endp

VMHigh	ends

VMOpenCode	segment	resource
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMClose

DESCRIPTION:	Close the VM file.

CALLED BY:	GLOBAL

PASS:		al - FILE_NO_ERRORS to 0
		bx - VM file handle

RETURN:		carry - set if error
		ax - VMStatus

DESTROYED:	bx (if file was actually closed)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	update file
	free VM blocks in memory
	close file

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	NOTE: Doesn't do a VMSave in backup mode to allow an application to
	shut down to run a DOS application and come back in the same state.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version

-------------------------------------------------------------------------------@

VMClose	proc	far	uses	cx, dx, si, di, bp, es, ds
	.enter

EC <	tst	al							>
EC <	jz	10$							>
EC <	cmp	al, FILE_NO_ERRORS					>
EC <	ERROR_NZ VM_CLOSE_BAD_PARAMETER_IN_AL				>
EC <10$:								>

EC <	call	FarAssertInterruptsEnabled				>

EC<	call	VMCheckFileHandle					>

	;
	; If this is a read-only file then bail
	;
	LoadVarSeg	ds, cx
	mov	cl, ds:[bx].HF_accessFlags
	and	cl, mask FFAF_MODE
				CheckHack <FA_READ_ONLY eq 0>
	jz	noError

	;
	; Synchronize the on-disk version first
	;
	mov_tr	dx, ax				;dl = no error flag
	call	VMUpdate
	jnc	noError
	tst	dl				;if not FILE_NO_ERRORS then
	stc					;return the error
	jz	done
noError:

EC<	call	VMCheckFileHandle					>

	;
	; Perform normal locking of the file, with the additional precaution of
	; obtaining the VM semaphore, before closing the thing down.
	; 
	call	PvmSemFar		;get exclusive access to open/close
					; file semaphore
if	IDLE_UPDATE_ASYNC_VM
	call	HeapVMFileClosed
endif	; IDLE_UPDATE_ASYNC_VM

	call	EnterVMFileFar
EC<	call	VMCheckStrucs						>

	mov	bp, es:[bx][HF_otherInfo]	; Fetch VM handle
	test	es:[bp].HVM_flags, mask IVMF_BLOCK_LEVEL_SYNC
	jz	notInUse
	dec	es:[bp].HVM_refCount
	jne	inUse
notInUse:
	;
	; No other references to VM handle exist -- release mem blocks, header
	; handle & block, VM handle containing semaphore released so no
	; ExitVMFile required.
	;
	; We used to do another update here in case the file was compressed,
	; but this is no longer needed since VMUpdateLow does this.
	;
	push	bx
	call	VMFreeAllBlks		;func(bx), carry set if error
	pop	bx
	xchg	bx, bp			;free up the VM handle itself
	segmov	ds, es			;wants ds=idata...
	call	FarFreeHandle
	xchg	bx, bp
	jmp	closeFile		; go close the file
inUse:
	;
	; Other references to VM handle exist. Make sure the VM handle doesn't
	; have this file as its HVM_fileHandle (would cause errors for later
	; accesses).
	; 
	call	VMOpenCode_SwapESDS	; need ds=idata
	cmp	ds:[bp].HVM_fileHandle, bx
	jne	finishAccess		; Go close this file handle -- no
					;  further references to it.
	push	si
	clr	si			; Search entire list, please
	call	VMFindOtherOpen		; Locate another handle we can use to
					;  access the file.
EC < 	ERROR_NC VM_REFERENCE_COUNT_BOGUS				>
	mov	ds:[bp].HVM_fileHandle, si
	pop	si

finishAccess:
	call	VMOpenCode_SwapESDS	; need ds=header again
	call	ExitVMFileFar
closeFile:
	;
	; Finish off the file handle.
	;
EC <	LoadVarSeg	ds, ax						>
EC <	mov	ds:[bx].HF_otherInfo, 0	; avoid EC death in FileClose	>
	mov	al, FILE_NO_ERRORS
	call	FileCloseFar		;func(al, bx)

	;
	; Allow pending opens/closes to happen now the world is once again
	; self-consistent.
	; 
	call	VvmSemFar		;release vmSem
	clc				; no error
done:
	.leave
	ret

VMClose	endp

VMOpenCode_SwapESDS proc near
	segxchg	ds, es
	ret
VMOpenCode_SwapESDS endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTruncateAndClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke all VM blocks for the passed file and close it. This
		is to be used only in extreme cases where the file isn't
		absolutely essential, e.g. when a state file can't be
		written.

CALLED BY:	(EXTERNAL)
PASS:		bx	= file handle
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTruncateAndClose proc	far
		uses	ds, cx, dx, si, di, bp, es
		.enter
		call	PvmSemFar
		call	EnterVMFileFar

EC <		cmp	es:[bp].HVM_refCount, 1				>
EC <		ERROR_NE	CANNOT_TRUNCATE_MULTI_REFERENCED_VM_FILE>
	;
	; Free all the memory associated with the file, ignoring the existence
	; of any dirty blocks (they'll get freed, too).
	; 
		call	VMFreeAllBlks		
	;
	; Free the HandleVM
	; 
		xchg	bx, bp
		segmov	ds, es
		call	FarFreeHandle
		mov	bx, bp
	;
	; Truncate the file to zero length.
	; 
		clr	cx, dx
		call	FileTruncate
	;
	; Close the file (must succeed, else file couldn't have been created)
	; 
		mov	al, FILE_NO_ERRORS
		call	FileCloseFar
		call	VvmSemFar
		.leave
		ret
VMTruncateAndClose endp

VMOpenCode	ends


VMHigh	segment	resource
COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMSetExecThread

DESCRIPTION:	Set the executing thread for a VM file containing objects

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		ax - Thread handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@
VMSetExecThread	proc	far	uses bx, ds
	.enter

EC <	call	ECVMCheckVMFile						>
EC <	xchg	ax, bx							>
EC <	call	ECCheckThreadHandleFar					>
EC <	xchg	ax, bx							>

	LoadVarSeg	ds
	mov	bx, ds:[bx].HF_otherInfo	;bx = HandleVM
	mov	ds:[bx].HVM_execThread, ax

	.leave
	ret

VMSetExecThread	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMSetMapBlock

DESCRIPTION:	Set the "map block" for the VM file.

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		ax - VM block handle of map block

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Don't check validity of the block, as doing so forbids the caller
	from storing an arbitrary map word, which is unhappy.

	Dirties header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMSetMapBlock	proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

	mov	ds:[VMH_mapBlock], ax
	call	VMMarkHeaderDirty
	call	NotifyDirtyFar

	jmp	VMPop_ExitVMFileFar

VMSetMapBlock	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMSetDBMap

DESCRIPTION:	Set the "map block" for the VM file.

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		ax - VM block handle of map block

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Don't check validity of the block, as doing so forbids the caller
	from storing an arbitrary map word, which is unhappy.

	Dirties header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMSetDBMap	proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

	mov	ds:[VMH_dbMapBlock], ax
	call	VMMarkHeaderDirty
	call	NotifyDirtyFar

	jmp	VMPop_ExitVMFileFar

VMSetDBMap	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMPreserveBlocksHandle

DESCRIPTION:	Cause the memory handle for a block to be preserved
		whenever the file is opened, until the file is closed.
		This routine should be called for any VM blocks that
		contain objects.

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		ax - VM block handle to preserve handle for

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMPreserveBlocksHandle	proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

	mov	si, ax
	ornf	ds:[si].VMBH_flags, mask VMBF_PRESERVE_HANDLE
	call	VMMarkHeaderDirty
	call	NotifyDirtyFar

	jmp	VMPop_ExitVMFileFar

VMPreserveBlocksHandle	endp

VMHigh	ends


kcode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetMapBlock

DESCRIPTION:	Return the VM handle of the VM block set as the map block (set
		with VMSetMapBlock).  An application might use this block to
		store "road map" type information about the file.

CALLED BY:	GLOBAL

PASS:		bx - VM file handle

RETURN:		ax - VM block handle of map block (or 0 if none)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMGetMapBlock	proc	far
	call	VMPush_EnterVMFile

EC <	call	FarAssertInterruptsEnabled				>

	mov	ax, ds:[VMH_mapBlock]

	jmp	VMPop_ExitVMFile

VMGetMapBlock	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetDBMap

DESCRIPTION:	Return the DB map block

CALLED BY:	INTERNAL

PASS:		bx - VM file handle

RETURN:		ax - VM block handle of map block (or 0 if none)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

VMGetDBMap	proc	far
	call	VMPush_EnterVMFile

EC <	call	FarAssertInterruptsEnabled				>

	mov	ax, ds:[VMH_dbMapBlock]

	jmp	VMPop_ExitVMFile

VMGetDBMap	endp

kcode	ends

VMOpenCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMGetAttributes

DESCRIPTION:	Return the VMAttributes for the given file

CALLED BY:	GLOBAL

PASS:		bx - VM file handle

RETURN:		al - VMAttributes

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@

VMGetAttributes	proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

	mov	al, ds:[VMH_attributes]

	jmp	VMPop_ExitVMFileFar

VMGetAttributes	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VMSetAttributes

DESCRIPTION:	Set the VMAttributes for the given file

CALLED BY:	GLOBAL

PASS:		bx - VM file handle
		al - bits to set
		ah - bits to reset

RETURN:		al - new VMAttributes

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Dirties header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version
	Robertg 11/94		pre-tests added

-------------------------------------------------------------------------------@

VMSetAttributes	proc	far
	push	dx
	mov	dx, 1
	call	SetAttrLow
	pop	dx
	ret

VMSetAttributes	endp

	; dx = non-zero to dirty

SetAttrLow	proc	far
	call	VMPush_EnterVMFileFar

EC <	call	FarAssertInterruptsEnabled				>

	mov	cl, ds:[VMH_attributes]

	test	al, mask VMA_NOTIFY_DIRTY
	jnz	settingNotifyDirty
continuePreTests:
	mov	ch, mask VMA_SYNC_UPDATE
	test	al, ch
	jnz	settingSyncUpdate

	test	ah, ch
	jnz	clearingSyncUpdate


	; handle bits to reset
nothingSpecial:
	mov	ch, ah
	not	ch
	and	cl, ch
	or	al, cl
	mov	ds:[VMH_attributes], al
postTests:
	;
	; Shut off compression for this file if in backup mode, as VMDoCompress
	; would wreak havoc with our carefully laid plans of mice and men...
	; VMSaveRevertCommon will compress the thing eventually.
	;
	; 10/6/95: also turn off compression for sync-update. It will get
	; turned back on again in VMUpdate if VMA_BACKUP is clear. We
	; essentially don't want to perform intermediate compressions when
	; in sync-update mode, as that causes writing to the file at undefined
	; times, which is exactly what sync-update is supposed to prevent
	; 					-- ardeb
	;
	test	al, mask VMA_BACKUP or mask VMA_SYNC_UPDATE
	jz	10$
	BitSet	ds:[VMH_compressFlags], VMCF_NO_COMPRESS
10$:
	;
	; If VMA_NOTIFY_DIRTY is turned off then clear the flag in the HandleVM
	;
	test	al, mask VMA_NOTIFY_DIRTY
	jnz	20$
	andnf	es:[bp].HVM_flags, not mask IVMF_NOTIFY_OWNER_ON_DIRTY
20$:

	call	VMMarkHeaderDirty
	tst	dx
	jz	30$
	call	NotifyDirtyFar
30$:
	jmp	VMPop_ExitVMFileFar

settingNotifyDirty:
	; if notify dirty wasn't set before then we need to set the
	; dirty limit and reset things
	;
	; if dirty limit has a value, we don't need to do anything..
	;
	cmp	ds:[VMH_blockTable].VMBH_uid, VM_DIRTY_LIMIT_NOT_SET
	jne	continuePreTests

	push	bx
	mov	bx, MSG_META_VM_FILE_SET_INITIAL_DIRTY_LIMIT

	and	es:[si][HM_flags], not mask HF_DISCARDABLE
	jmp	doBitWorkAndObjMessage

notYetTempAsyncable:
	;
	; well, are we setting it to be TempAsyncable?
	;
	test	al, mask VMA_NOTIFY_DIRTY
	jz	nothingSpecial
	jmp	goingTempAsyncable

settingSyncUpdate:
	; needed to catch any transition to sync mode so that we can
	; recalibrate the dirty size if needed.
	;
	; require the temp async bit be cleared..  if they require the
	; sync set, they imply this too, yet old code may not know
	; this..  so we do it for them.
	;
	or	ah, mask VMA_TEMP_ASYNC
	;
	; is the file tempasync-able?
	;
	test	cl, mask VMA_NOTIFY_DIRTY
	jz	notYetTempAsyncable
goingTempAsyncable:
	;
	; is this file tracking its dirty size?  (meaning is the dirty
	; limit set positive - check the sign bit)
	;
	test	ds:[VMH_blockTable].VMBH_uid.high, 0x80
	jnz	nothingSpecial
	;
	; is the current dirty size accurate?  If it is positive, we
	; say it is (either it is, or a relocRoutine is in use..  in
	; either case we don't want to mess with it!)
	;
	test	es:[bp].HVM_relocRoutine.offset.high, 0x80
	jz	nothingSpecial	
	;			
	; ok, so we need to get an accurate dirty size.. some trickery
	; here: we need do any other bitwork they wanted done, but set
	; the VMA_TEMP_ASYNC, clear the VMA_SYNC_UPDATE and trigger an update.
	; The update will reset the bits to the correct pattern.
	;
	push	bx
	mov	bx, bp				; get HandleVM
	call	NotifyDirtyFar			; force the file dirty
	clr	dx				; only do it once!
	mov	bx, MSG_META_VM_FILE_AUTO_SAVE
	and	ax, (not (mask VMA_SYNC_UPDATE or \
		    (mask VMA_TEMP_ASYNC shl 8)))
	or	ax, mask VMA_TEMP_ASYNC or (mask VMA_SYNC_UPDATE shl 8)
	jmp	doBitWorkAndObjMessage

clearingSyncUpdate:
	;
	; needed to catch sync-async transitions..  dirtysize needs to
	; be set to -1
	;
	; are we going to TempAsync or Async?  if the VMA_TEMP_ASYNC
	; bit isn't being set then we need to zap our dirty size (go
	; full-time Async)
	;
	test	al, mask VMA_TEMP_ASYNC
	jnz	nothingSpecial
	;
	; must be going Full-time async..  so set the dirty size to -1
	; (don't track anymore)
	;

	INT_OFF
	tst	es:[bp].HVM_relocRoutine.segment
	jnz	relocRoutinePresent
	mov	{word}es:[bp].HVM_relocRoutine.offset, -1
relocRoutinePresent:
	INT_ON
	jmp	nothingSpecial

doBitWorkAndObjMessage:

	mov	ch, ah
	not	ch
	and	cl, ch
	or	al, cl
	mov	ds:[VMH_attributes], al
	;
	; now get file owner and send Message
	;
	mov	ax, bx			; set message
	mov	bx, es:[bp].HVM_fileHandle
	mov	cx, es:[bx].HF_owner
	xchg	bx, cx
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage

	pop	bx
	jmp	postTests



	
SetAttrLow	endp

VMOpenCode	ends


VMHigh	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VMFilePos

DESCRIPTION:	Call FilePos

CALLED BY:	INTERNAL

PASS:
	bx - file
	dx - position

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 1/91		Initial version

------------------------------------------------------------------------------@
if not FLOPPY_BASED_DOCUMENTS
VMFilePos	proc	far	uses	ax, cx
	.enter
	mov	al, FILE_POS_START
	clr	cx
	call	FilePosFar
	.leave
	ret
VMFilePos	endp
endif
COMMENT @----------------------------------------------------------------------

FUNCTION:	VMFileReadWord

DESCRIPTION:	Read a word from a file

CALLED BY:	INTERNAL

PASS:
	bx - file handle
	ax - offset to read word from

RETURN:
	carry - set if error
	ax - word read

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 1/91		Initial version

------------------------------------------------------------------------------@
if not FLOPPY_BASED_DOCUMENTS
VMFileReadWord	proc	far	uses cx, dx, ds
	.enter

	mov_trash	dx, ax
	call	VMFilePos

	push	ax			;allocate word on stack
	mov	dx, sp
	segmov	ds, ss			;ds:dx = buffer
	clr	ax			;allow errors
	mov	cx, size word
	call	FileReadFar
	pop	ax			;get word read

	.leave
	ret

VMFileReadWord	endp
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMFileWriteWord

DESCRIPTION:	Write a word to a file

CALLED BY:	INTERNAL

PASS:
	bx - file handle
	ax - word to write
	dx - offset to write to

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 1/91		Initial version

------------------------------------------------------------------------------@
if not FLOPPY_BASED_DOCUMENTS
VMFileWriteWord	proc	near	uses cx, dx, ds
	.enter

	call	VMFilePos

	push	ax			;allocate word on stack and set it
	mov	dx, sp
	segmov	ds, ss			;ds:dx = buffer
	clr	ax			;allow errors
	mov	cx, size word
	call	FileWriteFar
	pop	ax			;get word written

	.leave
	ret

VMFileWriteWord	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMGrabExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide current thread with exclusive access to the VM file

CALLED BY:	GLOBAL
PASS:		bx = VM file handle, unless override present
		ax = VMOperation enum for operation to be performed
					(currently unused)
		cx = timeout value in 1/10th of a second
					(0 for no timeout (wait forever))
RETURN:		ax = VMStartExclusiveReturnValue
		cx = existing VMOperation (if timeout)
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Enter the VM file, grabbing exclusive access to the header.
		This will prevent anyone from doing anything to the file,
		though they can (unfortunately) continue to modify any block
		they already have locked.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMStartExclusiveInternalNoTimeout	proc	far	uses ax
	.enter
	mov	ax, VMO_READ
	call	VMStartExclusiveNoTimeout
	.leave
	ret
VMStartExclusiveInternalNoTimeout	endp

;---

VMStartExclusiveNoTimeout	proc	far	uses cx
	.enter
	clr	cx
	call	VMGrabExclusive
	.leave
	ret
VMStartExclusiveNoTimeout	endp

;---

VMGrabExclusive proc	far	uses bx, dx, si, di, bp, ds, es
	.enter

EC <	call	FarAssertInterruptsEnabled				>

	stc					;flag for lock
	call	VMFileLockUnlockCommon
if not FLOPPY_BASED_DOCUMENTS
	jc	timeout
endif

	call	EnterVMFileFar		;ds = VM header, es = idata
					;bp = VM handle, si = header handle
					;bx = file handle

if FLOPPY_BASED_DOCUMENTS
	mov	ax, VMSERV_NO_CHANGES
else

	test	es:[bp].HVM_flags, mask IVMF_BLOCK_LEVEL_SYNC
	jnz	exitNoChanges

	cmp	ax, VMO_READ
	jz	noWriteUpdateType	; might be opened read-only, you know
	cmp	ax, VMO_SAVE_AS
	jz	noWriteUpdateType	; don't write anything if we're doing
					; a save-as

	mov	dx, offset VMFH_updateType
	call	VMFileWriteWord
noWriteUpdateType:

	mov	ax, offset VMFH_updateCounter
	call	VMFileReadWord		;ax = counter
EC <	ERROR_C VM_READ_FILE_WORD_ERROR				>
	cmp	ax, es:[bp].HVM_refCount
	mov	es:[bp].HVM_refCount, ax	;save counter
	mov	ax, VMSERV_NO_CHANGES
	jz	exit

	; the file has changed

	call	VMPurgeBlocks
	call	VMFaultInBlocksIfNeeded
	mov	ax, VMSERV_CHANGES
exit:
endif
	.leave
	ret

;---

if not FLOPPY_BASED_DOCUMENTS

exitNoChanges:
	mov	ax, VMSERV_NO_CHANGES
	jmp	exit

;---

timeout:
	mov	ax, offset VMFH_updateType
	call	VMFileReadWord			;ax = operation
EC <	ERROR_C VM_READ_FILE_WORD_ERROR				>
	mov_trash	cx, ax			;cx = operation
	mov	ax, VMSERV_TIMEOUT
	jmp	exit

endif

VMGrabExclusive endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMCheckForModifications

DESCRIPTION:	See if a VM file has been modified

CALLED BY:	GLOBAL

PASS:
	bx - vm file handle

RETURN:
	carry - set if file modified

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 1/91		Initial version

------------------------------------------------------------------------------@
VMCheckForModifications	proc	far	uses ax, bx, ds
	.enter

if FLOPPY_BASED_DOCUMENTS
	clc
else

EC <	call	FarAssertInterruptsEnabled				>

	LoadVarSeg	ds
	mov	ax, offset VMFH_updateCounter
	call	VMFileReadWord		;ax = counter
EC <	ERROR_C VM_READ_FILE_WORD_ERROR				>
	mov	bx, ds:[bx].HF_otherInfo
	cmp	ax, ds:[bx].HVM_refCount
	clc
	jz	done
	stc
done:
endif
	.leave
	ret

VMCheckForModifications	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMFileLockUnlockCommon

DESCRIPTION:	Lock or unlock the byte in the VM file that provides
		exclusive access across the network

CALLED BY:	VMGrabExclusive, VMReleaseExclusive

PASS:
	carry - set to lock, clear to unlock
	cx - timeout (in 10ths of a second) (if lock) (0 to wait forever)
	bx - file handle

RETURN:
	carry - set if timeout

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 1/91		Initial version

------------------------------------------------------------------------------@
VMFileLockUnlockCommon	proc	near	uses ax, bx, cx, dx, si, di, bp, ds
	.enter

	mov	bp, cx				;bp = timeout

	pushf
	LoadVarSeg	ds

	mov	si, ds:[bx].HF_otherInfo	;si = HandleVM
	test	ds:[si].HVM_flags, mask IVMF_NEED_FILE_LOCK
	jz	abort
	test	ds:[si].HVM_flags, mask IVMF_BLOCK_LEVEL_SYNC
	jnz	abort

	movdw	cxdx, VM_BYTE_LOCK_POSITION	;cx.dx = position
	movdw	sidi, 1				;si.di = length
	popf
	jc	lockit
	call	FileUnlockRecord
	jmp	done

lockit:
	call	FileLockRecord
	jnc	done
	tst	bp
	jz	sleep
	dec	bp
	stc
	jz	done
sleep:
	mov	ax, 60/10			;wait 1/10 second
	call	TimerSleep
	jmp	lockit

done:
	.leave
	ret

abort:
	popf
	clc
	jmp	done

VMFileLockUnlockCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMReleaseExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relinquish exclusive access to a VM file

CALLED BY:	GLOBAL
PASS:		bx	= VM file handle unless override present
RETURN:		Nothing
DESTROYED:	Nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		EnterVMFile, to get registers set up properly, then
		call VMReleaseHeader to account for unmatched VMLockHeaderBlk
		from EnterVMFile in VMGrabExclusive. Then call ExitVMFile

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		VMHeader block can move (even if locked)!

		DS will be updated if it is passed to this routine pointing
		to the VMHeader block of the passed VM file. ES does not
		undergo similar updating.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/30/89	Initial version
	don	 7/14/93	Fixed problem where DS is passed as the
				VMHeader, and DS moves!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMReleaseExclusive	proc	far
	uses	ax, bx, cx, dx, di, si, bp, es
	.enter

EC <	call	FarAssertInterruptsEnabled				>

	pushf
	push	ds
	mov	ax, ds			;store incoming segment

	call	EnterVMFileFar		;ds = VM header, es = idata
					;bp = VM handle, si = header handle
					;bx = file handle
	mov	cx, ds
	cmp	ax, cx			;see if DS was pointing at the VMHeader
	pushf				;save comparison results

	mov	al, es:[bp].HVM_flags
	test	al, mask IVMF_BLOCK_LEVEL_SYNC
	jnz	exit

if not FLOPPY_BASED_DOCUMENTS

		CheckHack <FA_READ_ONLY eq 0>
	test	es:[bx].HF_accessFlags, mask FFAF_MODE
	jz	noModifications

	test	al, mask IVMF_FILE_MODIFIED
	jz	noModifications
	call	VMUpdateLowRealAttrs
noModifications:
endif

	clc				;flag for unlock
	call	VMFileLockUnlockCommon
exit:
	call	ExitVMFileFar
	call	ExitVMFileFar

	popf				;restore DS=VMHeader comparison
	pop	ax			;restore original DS
	je	exit2			;if same, we have correct DS (=VMHeader)
	mov	ds, ax			;else restore passed value
exit2:
	popf

	.leave
	ret
VMReleaseExclusive	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMPurgeBlocks

DESCRIPTION:	Purge all blocks from memory for a given VM file

CALLED BY:	VMGrabExclusive

PASS:
	VM handle grabbed/released
	ds - header block
	bp - HandleVM
	es - kdata
	bx - vm file handle

RETURN:
	none

DESTROYED:
	ax, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 1/91		Initial version

------------------------------------------------------------------------------@
if not FLOPPY_BASED_DOCUMENTS
VMPurgeBlocks	proc	near
	.enter

	call	FarPHeap
	mov	di, VMH_blockTable		;Start search after header
blockLoop:
	call	VMGetNextUsedBlk		;di = block
	jc	loopDone

	; get block

	call	VMDiscardMemBlk
	jmp	blockLoop

loopDone:

	; last we must purge the header and reread it

	push	bx
	push	es:[bp].HVM_headerHandle
	call	ExitVMFileFar
	pop	bx
EC <	mov	es:[bx].HM_owner, handle 0	; change ownership to kernel>
						; to avoid bogus EC death in
						; MemFree
	call	MemFree
	mov	es:[bp].HVM_headerHandle, 0
	call	FarVHeap
	pop	bx
	call	EnterVMFileFar

	.leave
	ret

VMPurgeBlocks	endp
endif
COMMENT @----------------------------------------------------------------------

FUNCTION:	VMFaultInBlocksIfNeeded

DESCRIPTION:	Read in all blocks from a VM file if needed

CALLED BY:	VMOpen, VMGrabExclusive

PASS:
	VM handle grabbed/released
	bx - vm file handle (grabbed exclusively)
	es - idata seg
	bp - VM handle (not needed for exit)
	si - VM header handle
	ds - VM header

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 1/91		Initial version

------------------------------------------------------------------------------@
VMFaultInBlocksIfNeeded	proc	far	uses ax, bx, di
	.enter

	test	es:[bp].HVM_flags, mask IVMF_DEMAND_PAGING
	jnz	done

	; bp = HandleVM, si = header handle, ds = VM header, es = idata

EC <	WARNING	FAULTING_IN_VM_BLOCKS				>	
	mov	di, VMH_blockTable		;Start search after header
blockLoop:
	call	VMGetNextUsedBlk		;di = block
	jc	done
	mov	ax, di
	push	bp				; preserve HandleVM for header
	call	VMLock				;  deref
	call	VMUnlock
	pop	bp

	; make the block look old

	INT_OFF
	push	bx
        mov     bx, es:[bp].HVM_headerHandle    ; header may have moved during
        mov     ds, es:[bx].HM_addr             ; VMLock, so dereference it

	mov	bx, ds:[di].VMBH_memHandle
	tst	bx
	jz	noAgeChange
	tst	es:[bx].HM_addr
	jz	noAgeChange
	mov	ax, es:[systemCounter].low
	sub	ax, 60*60*5			;make block 5 miunute old
	mov	es:[bx].HM_usageValue, ax
noAgeChange:
	pop	bx
	INT_ON
	jmp	blockLoop

done:
	.leave
	ret

VMFaultInBlocksIfNeeded	endp


VMHigh	ends

kcode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch info about a VM block

CALLED BY:	GLOBAL
PASS:		bx	= VM file handle (unless override present)
		ax	= VM block handle
RETURN:		carry clear if block handle is ok:
		    cx	= size of block. Note: the function doesn't
			  guarantee the block will remain this size after
			  the function returns. It must be locked with VMLock
			  to ensure this.
		    ax	= associated memory handle, if any (0 if none)
		    di	= user ID of the block.
		carry set if block handle is free or out of range or
		    otherwise illegal. No other registers are altered.
		    This is intended to allow the integrity of a VM
		    file to be checked in a way not possible by the
		    VM code (i.e. where the internal structure, known only
		    to the application, is being checked to be sure the file
		    got written to disk correctly)
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Gain access to the VM file by calling EnterVMFile.
		Load ax with the associated memory handle
		If has memory, set cx from the HM_size field of the memory
			handle.
		Else set cx from the VMBH_size field of the VM block handle

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMInfo		proc	far

EC <	call	FarAssertInterruptsEnabled				>

	; OPTIMIZATION -- This is currently rather slow

	push	ds, bx
	LoadVarSeg	ds, di		; we want speed, dammit..
	INT_OFF				; ensure consistency.

	; We don't need to check for the VM semaphore, we'll check the owner
	; of the header later

	; Case (1)
	mov	di, ds:[bx].HF_otherInfo
	mov	di, ds:[di].HVM_headerHandle
	tst	di			; header around?
	jz	slow			; no => do it the slow way
	
	; Case (2) and (3)
	cmp	ds:[di].HM_lockCount, 0
	jne	headerGrabbed

continueOptimization:
	mov	di, ds:[di].HM_addr
	tst	di			; header in transit?
	jz	slow			; yes => do it the slow way

	push	es
	mov	ds, di
	mov_tr	di, ax
	LoadVarSeg	es, ax
	call	infoCommon
	INT_ON
	pop	es
	pop	ds, bx
	ret

	;
	; The header is grabbed.  If it is grabbed by us then we can still
	; optimize
	;
headerGrabbed:
	mov	bx, ds:[bx].HM_usageValue
	cmp	bx, ds:[currentThread]
	jz	continueOptimization

slow:
		pop	ds, bx
		call	VMPush_EnterVMFileFar
		mov_tr	di, ax
		call	infoCommon
	;
	; Return values by storing them in the frame to be popped
	;
		mov	bp, sp
		mov	ss:[bp].VMPOES_cx, cx
		mov	ss:[bp].VMPOES_di, di

		jmp	VMPop_ExitVMFileFar

;----

infoCommon:
	;
	; See if the passed VM block handle is legal:
	;	- it's within range of the block table
	;	- it refers to a VMBT_DUP or VMBT_USED block
	;
	; This will not check for a completely bogus handle ID, as it is
	; intended only for checking the integrity of a file, not for catching
	; stupidity on the part of the programmer...
	; 
		cmp	di, offset VMH_blockTable
		jb	bad
		cmp	di, ds:[VMH_lastHandle]
		jae	bad
		test	ds:[di].VMBH_sig, VM_IN_USE_BIT
		jz	bad
		cmp	ds:[di].VMBH_sig, VMBT_DUP
		jb	bad
EC <		call	VMCheckBlkHanOffset				>

	;
	; Fetch memory handle and file size (in case no memory)
	;
		mov	ax, ds:[di].VMBH_memHandle
		mov	cx, ds:[di].VMBH_fileSize
		tst	ax		; Memory with it?
		jz	noMem		; Nope
	;
	; Fetch the size from the memory handle
	; XXX: Should it be locked? I don't think so. The block can't lose its
	; memory handle, since we've got the file grabbed, nor will its size
	; change should the block be swapped out or discarded...
	;
		push	bx		; save file handle
		xchg	ax, bx		; bx <- memory handle
		mov	ax, es:[bx].HM_size
		mov	cl, 4
		shl	ax, cl
		xchg	cx, ax		; cx <- block size
		xchg	ax, bx		; ax <- memory handle
		pop	bx		; recover file handle for ExitVMFile
noMem:
	;
	; Fetch the UID bound to the block
	;
		mov	di, ds:[di].VMBH_uid
		clc				; signal happiness
		retn
bad:
		stc				; signal unhappiness
		retn


VMInfo		endp
kcode	ends


VMOpenCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSetReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the (fixed-memory) relocation routine to be called
		whenever a block is brought into memory from or written
		from memory to the VM file.

CALLED BY:	GLOBAL
PASS:		bx	= VM file handle
		cx:dx	= address of routine to call. Routine is called:
			PASS:
				ax = memory handle
				bx = VM file handle
				di = block handle of loaded block
				dx = segment address of block
				cx = VMRelocType
					VMRT_UNRELOCATE_BEFORE_WRITE
					VMRT_RELOCATE_AFTER_READ
					VMRT_RELOCATE_AFTER_WRITE
				bp = User ID for the block
			RETURN:
				block relocated/unrelocated
			DETROY:
				ax, bx, cx, dx, si, di, bp ,ds, es
			NOTES:
				The routine may not allocate or free memory --
				it may only manipulate the data in the block.
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSetReloc	proc	far
EC <	call	FarAssertInterruptsEnabled				>

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx, si						>
EC <		movdw	bxsi, cxdx					>
EC < 		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx, si						>
endif
		call	VMPush_EnterVMFileFar
;
; note: must set the segment before setting the offset to avoid
; synchronization problems with VMem dirty size tracking!
;
		mov	es:[bp].HVM_relocRoutine.segment, cx
		mov	es:[bp].HVM_relocRoutine.offset, dx
		jmp	VMPop_ExitVMFileFar

VMSetReloc	endp
VMOpenCode	ends


VMHigh	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check usage of memory handles by VM blocks in VM file.

CALLED BY:	GLOBAL
PASS:		bx	= VM file handle
		cx	= low water mark
		dx	= high water mark
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/28/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMEnforceHandleLimits	proc	far

	call	VMPush_EnterVMFileFar

	call	VMEnforceHandleLimitLow

	jmp	VMPop_ExitVMFileFar

VMEnforceHandleLimits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach a block of memory to a VM block, nuking whatever
		was there before.

CALLED BY:	GLOBAL
PASS:		bx	= VM file handle
		ax	= VM block handle -- or 0 to allocate new VM block
		cx	= memory handle to attach to the block handle
RETURN:		ax	= VM block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Dirties header if new block allocated (VMGetUnassignedBlk)
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMAttach	proc	far

EC <	call	FarAssertInterruptsEnabled				>

EC <	push	ax, ds							>
EC <	LoadVarSeg	ds						>
EC <	xchg	bx, cx							>
EC <	call	ECCheckMemHandleFar					>
EC <	test	ds:[bx].HM_flags, mask HF_SWAPABLE			>
EC <	ERROR_Z	VM_ATTACH_BLOCK_MUST_BE_SWAPABLE			>
EC <	test	ds:[bx].HM_flags, mask HF_DISCARDABLE			>
EC <	ERROR_NZ VM_ATTACH_BLOCK_CANNOT_BE_DISCARDABLE			>
EC <	test	ds:[bx].HM_flags, mask HF_LMEM				>
EC <	jz	1$							>
EC <	call	ObjLockObjBlock						>
EC <	mov	ds, ax							>
EC <	test	ds:[LMBH_flags], mask LMF_DETACHABLE			>
EC <	ERROR_NZ	VM_ATTACH_BLOCK_CANNOT_BE_DETACHABLE		>
EC <	call	MemUnlock						>
EC <1$:									>
EC <	xchg	bx, cx							>
EC <	pop	ax, ds							>

	FALL_THRU	VMAttachNoEC

VMAttach	endp

;---

VMAttachNoEC	proc	far

	call	VMPush_EnterVMFileFar

	; test for no block passed

	tst	ax
	jnz	10$
	call	VMGetUnassignedBlk
	call	VMMarkBlkUsed
	jmp	setHandle
10$:
	xchg	ax, di			; pass VM block handle in di

EC <	call	VMCheckUsedBlkHandle				>

	; nuke any existing memory block for the thing

	call	VMDiscardMemBlk

setHandle:
	; install the handle as the handle for this block
	call	SetHandleLow

	; make sure we've enough extra block handles to deal with it
	call	VMMaintainExtraBlkHansFar
	
	; make sure we don't have too many handles associated with this file
	call	VMEnforceHandleLimit

	jmp	VMPop_ExitVMFileFar

VMAttachNoEC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the memory block from a VM block handle without
		destroying anything about the file. NOTE: This may not return
		the same memory handle as VMVMBlockToMemBlock.

CALLED BY:	GLOBAL
PASS:		bx	= VM file handle
		ax	= VM block handle
		cx	= owner for memory handle (0 => current thread's
			  geode)
RETURN:		di	= memory handle. The block is marked as non-discardable.
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMDetach	proc	far
		uses	bp, si, ds, es
		.enter

EC <		call	FarAssertInterruptsEnabled			>
	;
	; First gain exclusive access to the block in question.
	;
		mov	di, ax				; save this
		call	VMLock
		LoadVarSeg	es, si
		test	es:[bp].HM_flags, mask HF_DISCARDABLE
		jnz	stealIt
	;
	; Since it's dirty, we must duplicate it, as this operation is supposed
	; to be non-destructive.
	;
dupIt:
		mov	ds, ax
		call	VMDuplicateBlockForDetach
		call	VMUnlock
		jmp	changeOwner
someOneBlocked:
		mov	bx, ax
		call	ExitVMFileFar
		jmp	dupIt
stealIt:
	;
	; To make this thing more efficient, we take a clean memory handle away
	; from the block (XXX: this assumes no one else is blocked trying
	; to lock the block...)  *** see next comment!
	; 
		mov	ax, bp			; preserve the block handle
		call	EnterVMFileFar
	;
	; No longer assume no one is blocked trying to lock the block!
	;
	; Ok, now if somebody wants to lock it right now, they can't
	; because we've Entered the File and they need to.  so if
	; we check to see if someone is blocked trying to lock and
	; react to this (by going back and acutally duplicating it),
	; we'll be safe
	;
		xchg	ax, bx
		cmp	es:[bx].HM_otherInfo, 0
		jg	someOneBlocked
		FastUnLock	es, bx, si, NO_NULL_SEG
		mov	bx, ax

EC <		call	VMCheckUsedBlkHandle				>
		clr	ax			; zero memHandle
		xchg	ds:[di].VMBH_memHandle, ax
		dec	ds:[VMH_numResident]	; one fewer resident block
		call	ExitVMFileFar
		mov_tr	si, ax

changeOwner:
	;
	; Change the block to be owned as passed in.
	; 
		jcxz	useCurrentGeode
reallyChangeOwnerAndExit:
		andnf	es:[si].HM_flags, not mask HF_DISCARDABLE
		mov	es:[si].HM_owner, cx

	;
	; Clear the LMF_IS_VM bit from the lmem header if the detached block
	; is LMem
	;
		test	es:[si].HM_flags, mask HF_LMEM
		jz	returnHandle

		xchg	si, bx
		call	MemLockSkipObjCheck
		mov	ds, ax
		andnf	ds:[LMBH_flags], not mask LMF_IS_VM
		call	MemUnlock
		xchg	si, bx

returnHandle:
		;
		; Return the memory handle in di, but have to modify stored
		; frame to do so.
		;
		mov	di, si
		.leave
		ret

useCurrentGeode:
		mov	cx, ss:[TPD_processHandle]
		jmp	reallyChangeOwnerAndExit
VMDetach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMDuplicateBlockForDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a copy of the given block of memory.

CALLED BY:	(INTERNAL) VMDetach
PASS:		bp	= handle of block to duplicate
		ds	= segment of same
		es	= kdata
RETURN:		si	= new handle
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMDuplicateBlockForDetach proc	near
		uses	ax, ds, di, es, cx, bx
		.enter
	;
	; Figure the size of the block.
	; 
		mov	ax, MGIT_SIZE
		mov	bx, bp
		call	MemGetInfo
		push	ax		; save for copy
	;
	; Allocate another the same size, locked. (XXX: pass NO_ERR flag.
	; Ought to be able to handle an error more gracefully, but I have
	; no time to code it -- ardeb 11/23/92)
	; 
		mov	cl, es:[bx].HM_flags
		mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
		call	MemAllocFar
		mov	es, ax
	;
	; Copy the contents from the old to the new.
	; 
		clr	si, di
		pop	cx
		shr	cx
		rep	movsw
	;
	; Unlock the new & return it in SI.
	; 
		call	MemUnlock
		mov	si, bx
		.leave
		ret
VMDuplicateBlockForDetach endp

kcode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTestDirtySizeForModeChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests if the newly dirtied block pushes the dirty size
	of a VMFile over the files dirty limit.  If so, it sets the
	block TempAsync.

CALLED BY:	Global - notably VMDirty, VMMarkHeaderDirty, and MemReAlloc
PASS:		si	- VM Handle
		cx	- size of newly dirtyed block (in paras)
		es	- kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		turns off ints for just a bit..
		may change the docs dirty size
		may queue up an autosave
PSEUDO CODE/STRATEGY:
	check if a relocRoutine exists..  if so, quit
		check if the dirty size is already negative (threshold
		crossed earlier)..  if so, quit
			Subtract the new size
			check if went negative..  if not, quit
				call VMGoAsync

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTestDirtySizeForModeChange	proc	far
	.enter
EC<	xchg	bp,si					>
EC<	call	VMCheckVMHandle				>
EC<	xchg	bp,si					>
EC<	call	AssertESKdata				>
EC<	call	FarAssertInterruptsEnabled		>
	;
	; look to see if a relocRoutine is in use.. not likely
	;
	INT_OFF
	tst	es:[si].HVM_relocRoutine.segment
	jnz	turnIntBackOnAndQuit
	;
	; quickly check if we've already crossed the limit by checking
	; the sign bit
	;
	test	{byte}es:[si].HVM_relocRoutine.offset.high, 0x80
	jnz	turnIntBackOnAndQuit
	;
	; subtract and see if this crossed the limit
	;
	sub	es:[si].HVM_relocRoutine.offset, cx
	INT_ON
	jns	justQuit
	;
	; ok, go asynch
	;
	push	ax, bx, cx, di, ds, bp, si

; ok, going to inline SetAttrLow..  so that this routine can go into
; kcode (or some other fixed resource) without all SAL's baggage..

	mov	bx, es:[si].HVM_fileHandle
	call	EnterVMFile

	mov	al, ds:[VMH_attributes]
	and	al, not (mask VMA_SYNC_UPDATE)
	or	al, mask VMA_TEMP_ASYNC
	mov	ds:[VMH_attributes], al
	
	and	{byte}es:[si].HM_flags, not (mask HF_DISCARDABLE)
	call	ExitVMFile

	test	al, mask VMA_NOTIFY_DIRTY
	jz	mayHaveNoProcess

	call	NotifyDirtyFar

	mov	cx, bx
	mov	bx, es:[bx].HF_owner	; ok, now get the owner in
					; queue prep..

	mov	ax, MSG_META_VM_FILE_AUTO_SAVE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

mayHaveNoProcess:
	pop	ax, bx, cx, di, ds, bp, si

turnIntBackOnAndQuit:
	INT_ON
justQuit:
	.leave
	ret

VMTestDirtySizeForModeChange	endp
kcode ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSetDirtyLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the dirty limit for a VMFile and adjusts the
		dirty size.

CALLED BY:	Anybody
PASS:		bx - VM file handle
		cx - new dirty limit, 0 for system default
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	may cause file to go asynchronous

PSEUDO CODE/STRATEGY:
	if no value passed in
		get system default
	Enter File
	Swap in the new limit
	Exit File
	INT_OFF
		Check if was temp async before - if so, there is no
			accurate record of the dirty size, so we'll
			just leave it async and wait for the update.
		modify dirty size by difference in limits
			size(new)=size(old)-limit(old)+limit(new)
		goasync if appropriate
	INT_ON

	Everything between the Interrupt toggles is done in
	VMTestDirtySizeForModeChange already.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
vMDirtyLimitKey		char	"vmdirtylimit",0
vMDirtyLimitCat		char	"system",0

VMSetDirtyLimit	proc	far
	uses	si, ds, ax, bx, cx, dx, es, bp
	.enter

	tst	cx
	jnz	haveRealValue

	mov	si, offset vMDirtyLimitCat
	mov	cx, cs
	mov	dx, offset vMDirtyLimitKey
	mov	ds, cx

	mov	ax, VM_DIRTY_LIMIT_DISABLED	; sets the default dirty size
						; (-1 disables Temp-Async)

	call	InitFileReadInteger
	mov	cx, ax

haveRealValue:
	cmp	cx, VM_DIRTY_LIMIT_NOT_SET	; not allowed to set
						; this! see long note below
	je	convertToDisabled
haveOkValue:
	;
	; we have to enter the file so that we can mess with the
	; VMHeader
	;
	call	EnterVMFileFar	; es <- kdata
				; bp <- VM Handle
				; si <- VM Header Handle
				; ds <- VM Header

	call	VMMarkHeaderDirty

	test	ds:[VMH_attributes], mask VMA_NOTIFY_DIRTY
	jz	hathNoProcess

	mov	dx, cx
	xchg	cx, ds:[VMH_blockTable].VMBH_uid

	call	ExitVMFileFar	; bx -> VM file handle
				; ds -> VM Header
				; es -> idata
				; si ><

	;
	; Note - 0x8000 (VM_DIRTY_LIMIT_NOT_SET) is the initial dirty
	; limit set in VMOpenReal.  This value tells things
	; (SetAttrLow, mostly) that the dirty limit has not been set.
	; This value will not occur naturally and we prevent it if the
	; user tries to VMSetDirtyLimit it or uses it in the .INI
	; file.  Any other negative value will disable the mechanism
	; (the constant VM_DIRTY_LIMIT_DISABLED uses 0xFFFF).
	; If you did use an INI value of 0x8000 this is what would
	; happen: 
	;	File opened - value set to 0x8000
	;	File set VMA_NOTIFY_DIRTY - calls SetAttrLow
	;	SetAttrLow notices 0x8000 and the file is now eligable
	;		for TempAsync behavior (owned by a process)
	;		and so tries to set the initial dirty limit by
	;		MSGing the owning process with
	;		MSG_META_VM_FILE_SET_INITIAL_DIRTY_LIMIT 
	;	VMSetDirtyLimit looks up .INI setting, and noticing
	;		the dirty size is negative (and therefore not
	;		accurate) sends a MSG_META_VM_FILE_AUTO_SAVE
	;		to resynch things.
	;	Update toggles VMA_NOTIFY_DIRTY - go to step 2 above..
	;
	; So we don't allow the user to set this value.
	;
	or	cx, cx
	js	justSet

	sub	cx, dx		; cx = limit(old) - limit(new)
	mov	si, bp		; si = VM Handle

	call	VMTestDirtySizeForModeChange
done:
	.leave
	ret

convertToDisabled:
	mov	cx, VM_DIRTY_LIMIT_DISABLED
	jmp	haveOkValue

hathNoProcess:
	mov	ds:[VMH_blockTable].VMBH_uid, cx
	call	ExitVMFileFar
	jmp	done


justSet:
	;
	; enable the mechanism - the new limit is in place, so just
	; queue up an autosave to reset the dirty size.  Can't go
	; through VMTestDirtySizeForModeChange because it assumes that,
	; with a neg dirty size, an autosave has already been queued.
	;
	call	NotifyDirtyFar

	mov	cx, bx		; store away the file handle for the message
	mov	bx, es:[bx].HF_owner
	
	mov	ax, MSG_META_VM_FILE_AUTO_SAVE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	jmp	done

VMSetDirtyLimit	endp

VMHigh	ends


kcode	segment	resource
COMMENT @----------------------------------------------------------------------

FUNCTION:	VMMemBlockToVMBlock

DESCRIPTION:	Given a VM memory handle, find the VM block and file

CALLED BY:	GLOBAL

PASS:
	bx - VM memory handle

RETURN:
	ax - VM block
	bx - VM file

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
VMMemBlockToVMBlock	proc	far	uses ds, bp, si, di, es
	.enter

EC <	call	FarAssertInterruptsEnabled				>

	LoadVarSeg	ds
	mov	ax, bx				;ax = mem handle
	mov	bx, ds:[bx].HM_owner			;bx = VM handle
	mov	bx, ds:[bx].HVM_fileHandle

	call	EnterVMFile

	call	VMGetBlkHandle			;di = VM block handle

	mov	ax, di

	call	ExitVMFile
	.leave
	ret
VMMemBlockToVMBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMVMBlockToMemBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a VM block, return a memory handle.

CALLED BY:	External.
PASS:		bx - VM file handle (will use override if one is defined).
		ax - VM block.
RETURN:		ax - Memory handle.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMVMBlockToMemBlock	proc	far

EC <	call	FarAssertInterruptsEnabled				>

	call	VMPush_EnterVMFile
EC <	xchg	ax, di						>
EC <	call	VMCheckUsedBlkHandle				>
NEC <	xchg	ax, di				;(1-byte inst)	>

	mov	ax, ds:[di].VMBH_memHandle
	tst	ax
	jnz	done

	; allocate a discarded memory handle for the sucker

	push	si
	mov	ax, ds:[di].VMBH_fileSize		;size to allocate
	mov	cx, mask HF_DISCARDED or mask HF_DISCARDABLE
	call	VMGetMemSpaceAndSetOtherInfo
	xchg	ax, si				;(1-byte inst)
	pop	si

	mov	ds:[di].VMBH_memHandle, ax
done:
	jmp	VMPop_ExitVMFile
VMVMBlockToMemBlock	endp
kcode	ends

VMSaveRevertCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the backup versions of all blocks in the file

CALLED BY:	GLOBAL
PASS:		bx	= VM file handle
RETURN:		carry	= set on error
		ax	= error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSave		proc	far	uses cx
		.enter

EC <	call	FarAssertInterruptsEnabled				>

	; Ensure that we can access the source disk, so that if we cannot
	; the user gets an opportunity to abort

		push	bx, si, bp, es
		call	FileGetDiskHandle	;bx = disk handle
		mov	si, bx			;si = disk handle
		call	FileLockInfoSharedToES	;es = FSInfoResource
		clr	ax			;abortable
		call	DiskLockFar		;returns carry
		jc	10$
		call	DiskUnlockFar
10$:
		call	FSDUnlockInfoShared
		pop	bx, si, bp, es
		mov	ax, ERROR_DISK_UNAVAILABLE
		jc	done

		mov	ax, VMO_SAVE
		mov	cx, 1
		call	VMSaveRevertCommon
done:
		.leave
		ret
VMSave		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMRevert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the file from its backup copy

CALLED BY:	GLOBAL
PASS:		bx	= VM file handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMRevert	proc	far	uses ax, cx
		.enter

EC <	call	FarAssertInterruptsEnabled				>

		mov	ax, VMO_REVERT
		clr	cx
		call	VMSaveRevertCommon
		.leave
		ret
VMRevert	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSaveAs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the current copy of a file and copy it to a new location,
		then revert the file to its backup copy. The current file is
		closed and a handle for the new file is returned.

CALLED BY:	GLOBAL
PASS:		ah	= open mode for new file (VMOpenType)
		al	= mode for new file (VMAccessFlags)
		bx	= VM file handle
		cx	= compression threshold for new file (may be 0,
			  in which case the system default applies)
		ds:dx	= name for new file
RETURN:		bx	= handle for new file
		carry set on error
		ax	= status (see VMOpen)
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
	open new file (exit on failure)
	enter both files
	
	foreach block in old file:
	    if VMBT_USED:
		alloc same handle in new file
		if n/r:
		    read in, mark dirty, attach to new file, write
			and discard
		else
		    attach to new file and mark dirty
	    else if VMBT_BACKUP:
		alloc dup handle in new file
		if dup n/r:
		    read in, mark dirty, attach to new file, write
			and discard
		else
		    attach dup to new file and mark dirty
		exchange file pos & size with dup, setting dup to USED
		free the backup handle
	    else if VMBT_DUP & block has no backup:
		alloc same handle in new file
		if n/r: 
		    read in, mark dirty, attach to new file, write and
			discard
		else
		    attach to new file and mark dirty
		free handle in old file

	set attributes of new to match attributes of old
    	update old with VMA_BACKUP off
	release and close old file
    	copy header except for longname
    	update new file with VMA_BACKUP off
	release new file and exit, returning its handle in bx

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Ideally, this would be implemented in two passes, where the 
	destination is set up first and written out, ensuring happiness
	there, then the source is reverted and written out. This way, if
	we run out of room on the destination disk, the save-as can be
	backed out and the original file left untouched.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSaveAs	proc	far	uses ds, bp, si, es, di
destName	local	fptr.char	; Name of destination, in case of error\
		push	ds	\
		push	dx
openMode	local	byte		; Mode for opening file, so we know if
					;  need to delete longname or regular
sourceFile	local	hptr
destFile	local	hptr
sourceVM	local	hptr
destVM		local	hptr
destHeader	local	sptr.VMHeader
headerCopy	local	VMSaveAsHeader	; Buffer for copying relevant pieces of
					;  the header when done.
headerAttrs	local	VMSAH_NUM_ATTRS dup(FileExtAttrDesc)

	ForceRef headerCopy	; VMSaveAsTransferHeader
	ForceRef headerAttrs	; VMSaveAsTransferHeader
		.enter

EC <	call	FarAssertInterruptsEnabled				>

		mov	ss:[openMode], ah
	;======================================================================
	;		OPEN/ENTER BOTH FILES
	;======================================================================
	;
	; First, attempt to open the new file.
	; XXX: SHOULD COPY COMPRESSION THRESHOLD FROM THE ONE TO THE OTHER
	;
    	    	push	bx  		; Save old file
    	    	call	VMOpen
		jnc 	openOk
		pop	bx
		jmp	done
openOk:
	;
	; Save the handle of the destination, then grab the source file
	;
		mov	ss:[destFile], bx
		pop	bx
		push	bp
		call	EnterVMFileFar
		xchg	ax, bp			; (1-byte inst)
		pop	bp
		mov	ss:[sourceVM], ax
		mov	ss:[sourceFile], bx

	;======================================================================
	;		Ensure that we can access the source disk
	;======================================================================

		mov	si, es:[bx].HF_disk
		push	es, bp
		call	FileLockInfoSharedToES
		clr	ax			;abortable
		call	DiskLockFar		;returns carry
		jc	10$
		call	DiskUnlockFar
10$:
		call	FSDUnlockInfoShared
		pop	es, bp
		jnc	canAccessSource
		mov	ax, ERROR_DISK_UNAVAILABLE
earlyError:
		pushf
		push	ax
		jmp	undoDone
canAccessSource:

	;
	; Now grab the destination file, keeping track of the source's header,
	; since that's the one we'll be traversing.
	;
		mov	bx, ss:[destFile]
		push	ds, bp
		call	EnterVMFileFar
		xchg	ax, bp			; ax <- dest VM handle (1-b i)
		mov	ds:[VMH_attributes], mask VMA_SYNC_UPDATE; flag as
						; synchronous update so we can
						; extend the header if we need
						; more unassigned blocks during
						; VMTransfer
		pop	ds, bp
		mov	ss:[destVM], ax

	;======================================================================
	;	    TRANSFER FILE HEADER
	;
	;	Do this now because the source disk is already in the drive,
	;	so this is the perfect time to access it.
	;======================================================================

		call	VMSaveAsTransferHeader
		jc	earlyError

	;======================================================================
	;	    TRANSFER BLOCKS & INFO TO DESTINATION
	;======================================================================
	;
	; Traverse all the blocks in the source file.
	;
		mov	di, ds:[VMH_lastHandle]
		mov	si, ss:[sourceVM]	; Load bx & si for any 
		mov	bx, ss:[destVM]		;  VMTransfer calls we make

scanLoop:
		sub	di, size VMBlockHandle
		cmp	di, offset VMH_blockTable
		jbe	scanComplete
		;
		; If block not in-use, ignore it.
		;
		mov	ax, {word}ds:[di].VMBH_sig
		test	ax, 1
		jz	scanLoop

		cmp	al, VMBT_DUP		; DUP or USED?
		jb	scanLoop		; No -- ignore it

		call	VMTransfer		; Else transfer to dest
		jnc	scanLoop
		jmp	undoAndNuke		; => block was non-resident
						;  and couldn't be read or
						;  written, so abort.

scanComplete:

	;
	; Copy any relocation routine to the dest.
	; bx = destVM, si = sourceVM
	;
	; note: test for a relocRoutine is to just test the segment..
	;	and must set the segment before the offset to avoid
	;	synch problems with the vmem dirty size tracking!
	;
		mov	ax, es:[si].HVM_relocRoutine.segment
		tst	ax
		jz	relocCopied
		mov	es:[bx].HVM_relocRoutine.segment, ax
		mov	ax, es:[si].HVM_relocRoutine.offset
		mov	es:[bx].HVM_relocRoutine.offset, ax

relocCopied:
	;======================================================================
	;	    FLUSH SOURCE AND DEST TO DISK
	;======================================================================
	;
	; Update the destination file and change its attributes to match
	; those of the source. Note: can't just save segment of dest
	; header at the start as it's likely to move as blocks get allocated
	; in it...
	;
		mov	si, bx			; si <- destVM for later (avoid
						;  memory reference, you know?)
		mov	bx, ss:[destFile]
		mov	al, ds:[VMH_attributes]
		clr	dx
		call	SetAttrLow		; set attributes now so
						;  any relocation routine gets
						;  called.
		mov	ax, ds:[VMH_mapBlock]
		mov	cx, ds:[VMH_dbMapBlock]
		mov	dx, ds:[VMH_compactionThreshold]

		push	ds
		mov	di, es:[si].HVM_headerHandle
		mov	ds, es:[di].HM_addr
		xchg	si, di			;si = DEST header handle
						;di = DEST HandleVM

		mov	ds:[VMH_mapBlock], ax
		mov	ds:[VMH_dbMapBlock], cx
		mov	ds:[VMH_compactionThreshold], dx

	; mark the destination file as dirty (since none of the blocks are
	; as yet written)

		test	ds:[VMH_attributes], mask VMA_NOTIFY_DIRTY
		jz	noNotifyDirty
		or	es:[di].HVM_flags, mask IVMF_NOTIFY_OWNER_ON_DIRTY
noNotifyDirty:

		or	es:[di].HVM_flags, mask IVMF_FILE_MODIFIED
		call	VMUpdateNoBackup
		mov	ss:[destHeader], ds		; save for exit
		pop	ds
		jc	undoAndNuke

		pushf
		push	ax

if FLOPPY_BASED_DOCUMENTS
	;
	; In Redwood, document files generally have demand paging turned
	; off.   Since we probably won't care about the source file after
	; we revert it, we'll turn demand paging on so we won't run out
	; of memory when SaveAsRevertCommon faults all the source document
	; blocks in again.   cbh 3/13/94
	;
		mov	si, ss:[sourceVM]
		or	es:[si].HVM_flags, mask IVMF_DEMAND_PAGING

endif

	;
	; Revert the source file now the destination is safely written.
	;
		mov	bx, ss:[sourceFile]	; bx <- file handle
		call	ExitVMFileFar		; exit the file before calling
						; the common routine since
						; it is expected to be
						; "un-entered" there
		clr	cx			; revert

		mov	ax, VMO_SAVE_AS
		call	VMSaveRevertCommon

	;======================================================================
	;		CLOSE/EXIT BOTH FILES
	;======================================================================
	;
	; Close down the source file.
	;
		call	closeIt
	;
	; Set up for exit, replacing file override with new file, if override
	; was set on entrance.
	;
		mov	bx, ss:[destFile]
		mov	ds, ss:[destHeader]
		mov	si, ds:[VMH_blockTable].VMBH_memHandle ;What is this?

	; 
	; Now we have transferred all the blocks to the destination file,
	; and updated them on disk, so make sure the dest file is within the
	; handle limit.
	;
		call	VMEnforceHandleLimit

		call	ExitVMFileFar
	;
	; Restore error code and carry from update of destination.
	;
finish:
		pop	ax
		popf
done:
		.leave		
		ret

	;======================================================================
	;		   UNDO AFTER ERROR
	;======================================================================
	;----------------------------------------------------------------------
	; Unable to write the destination for one reason or another. So we have
	; to recover the memory we gave to the destination, close and delete the
	; dest and return whatever error we got.
	; es = idata still
	;
undoAndNuke:
		pushf			; push error flag
	;
	; Replace ERROR_SHORT_READ_WRITE with VM_UPDATE_INSUFFICIENT_DISK_SPACE
	;
		cmp	ax, ERROR_SHORT_READ_WRITE
		jnz	notShortReadWrite
		mov	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
notShortReadWrite:
		push	ax		;  and error code for "finish"
	;
	; Work down the destination header looking for USED blocks that have
	; memory handles associated with them. There can be no other type of
	; block in the destination, as nothing can be using it yet.
	; 
		mov	si, ss:[destVM]
		mov	si, es:[si].HVM_headerHandle
		mov	ds, es:[si].HM_addr
		mov	di, ds:[VMH_lastHandle]
undoLoop:
		sub	di, size VMBlockHandle
		cmp	di, offset VMH_blockTable
		jbe	undoDone
		
		test	ds:[di].VMBH_sig, VM_IN_USE_BIT
		jz	undoLoop
		
	;
	; Block is in-use. Fetch the memory handle from the thing and clear
	; anything that's there, as it's going back to the source handle.
	;
		clr	bx
		xchg	bx, ds:[di].VMBH_memHandle
		tst	bx
		jz	undoLoop
		
		test	es:[bx].HM_flags, mask HF_DISCARDED
		jnz	giveToSource
		dec	ds:[VMH_numResident]	; One fewer resident block
						;  for the destination
		clr	ax			; Set ZF again (DEC cleared it)
giveToSource:
	;
	; Now give the handle to the source file again. No need to
	; allocate anything or do anything to the VM block handle in the
	; source's header, as we didn't touch it during the transfer loop.
	; 
		push	ds
		mov	si, ss:[sourceVM]
		mov	es:[bx].HM_owner, si	; Transfer ownership to source
		mov	si, es:[si].HVM_headerHandle
		mov	ds, es:[si].HM_addr
		mov	ds:[di].VMBH_memHandle, bx
	;
	; If handle not discarded, adjust the resident count for the source
	; (it was reduced by VMTransfer) file and mark the block as dirty.
	; 
		jnz	blockIsBack		; (ZF still here from previous
						;  test for HF_DISCARDED)
		inc	ds:[VMH_numResident]
		andnf	es:[bx].HM_flags, not mask HF_DISCARDABLE
blockIsBack:
		pop	ds
		jmp	undoLoop
		
undoDone:
	;
	; All memory now belongs to the source file again, as it was. Sadly,
	; all transferred blocks are marked dirty, but c'est la vie. Now
	; close down the destination and delete it once that's done.
	; 
		mov	bx, ss:[destFile]
		call	closeIt
		
		lds	dx, ss:[destName]
		call	FileDelete

	;
	; Exit the source file.
	;
		mov	si, ss:[sourceVM]
		mov	bx, ss:[sourceFile]
		mov	si, es:[si].HVM_headerHandle

	; It is possible that we marked a bunch of blocks dirty as part of
	; this (made them resident) so nuke some if necessary and possible
	
		call	VMEnforceHandleLimit

		mov	ds, es:[si].HM_addr
		call	ExitVMFileFar
		jmp	finish
		
closeIt:
		mov	al, FILE_NO_ERRORS
		call	VMClose
		retn

VMSaveAs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSaveAsTransferHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer the salient portions of the header from the original
		to the new file.

CALLED BY:	VMSaveAs
PASS:		ss:bp	= inherited frame
RETURN:		carry set on error
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSaveAsTransferHeader proc	near
		uses	es, di
		.enter	inherit VMSaveAs
	;
	; Copy the important pieces of the header from the source to the dest.
	;
		mov	ss:[headerAttrs][0*FileExtAttrDesc].FEAD_attr, FEA_FLAGS
		mov	ss:[headerAttrs][0*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_flags
		mov	ss:[headerAttrs][0*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][0*FileExtAttrDesc].FEAD_size,
				size VMSAH_flags

		mov	ss:[headerAttrs][1*FileExtAttrDesc].FEAD_attr, 
				FEA_RELEASE
		mov	ss:[headerAttrs][1*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_release
		mov	ss:[headerAttrs][1*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][1*FileExtAttrDesc].FEAD_size,
				size VMSAH_release

		mov	ss:[headerAttrs][2*FileExtAttrDesc].FEAD_attr, 
				FEA_PROTOCOL
		mov	ss:[headerAttrs][2*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_protocol
		mov	ss:[headerAttrs][2*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][2*FileExtAttrDesc].FEAD_size,
				size VMSAH_protocol

		mov	ss:[headerAttrs][3*FileExtAttrDesc].FEAD_attr,
				FEA_TOKEN
		mov	ss:[headerAttrs][3*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_token
		mov	ss:[headerAttrs][3*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][3*FileExtAttrDesc].FEAD_size,
				size VMSAH_token

		mov	ss:[headerAttrs][4*FileExtAttrDesc].FEAD_attr, 
				FEA_CREATOR
		mov	ss:[headerAttrs][4*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_creator
		mov	ss:[headerAttrs][4*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][4*FileExtAttrDesc].FEAD_size,
				size VMSAH_creator

		mov	ss:[headerAttrs][5*FileExtAttrDesc].FEAD_attr,
				FEA_USER_NOTES
		mov	ss:[headerAttrs][5*FileExtAttrDesc].FEAD_value.segment,
				ss
		lea	ax, ss:[headerCopy].VMSAH_notes
		mov	ss:[headerAttrs][5*FileExtAttrDesc].FEAD_value.offset,
				ax
		mov	ss:[headerAttrs][5*FileExtAttrDesc].FEAD_size,
				size VMSAH_notes
	

		segmov	es, ss
		lea	di, ss:[headerAttrs]
		mov	cx, length headerAttrs
		

		mov	bx, ss:[sourceFile]
		mov	ax, FEA_MULTIPLE
		call	FileGetHandleExtAttributes
		jc	headerTransferred

		andnf	ss:[headerCopy].VMSAH_flags,
				not (mask GFHF_TEMPLATE or \
				     mask GFHF_SHARED_MULTIPLE or \
				     mask GFHF_SHARED_SINGLE)

		mov	bx, ss:[destFile]
		mov	ax, FEA_MULTIPLE
		call	FileSetHandleExtAttributes

headerTransferred:
		.leave
		ret
VMSaveAsTransferHeader endp

VMSaveRevertCode	ends

