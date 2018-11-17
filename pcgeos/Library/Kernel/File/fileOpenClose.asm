COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/File -- Open/Close functions for files
FILE:		fileOpenClose.asm

AUTHOR:		Adam de Boor, Apr  8, 1990

ROUTINES:
	Name			Description
	----			-----------
    GLB	FileOpen		Open an existing file.

    INT	FileAllocOpOnPath	Call FileAllocOp and traverse path if
				needed

    INT	FileAllocOpInt		Call DR_FS_ALLOC_OP in the current FS
				driver to open/create a file.

    GLB	FileCreateTempFile	Create a temporary file with a unique name

    INT	FileCreateVerifyFileFormat The file being "created" already exists,
				so we must make sure that in its current
				form it is compatible with the caller's
				wishes as expressed in the FCF_NATIVE flag

    GLB	FileCreate		Create a new file or (optionally) truncate
				an existing file

    INT	FileCreateCommon	Common code to actually create a file (as
				opposed to opening an existing one, as is
				done first in FileCreate)

    GLB	FileDuplicateHandle	Return a new handle that refers to the same
				file as the given handle.

  ALIAS	FileCloseFar		Close an open file.

    GLB	FileClose		Close an open file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 8/90		Initial revision


DESCRIPTION:
	Functions for the opening and closing of files and their handles
		

	$Id: fileOpenClose.asm,v 1.1 97/04/05 01:11:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCommon	segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileOpen

DESCRIPTION:	Open an existing file.

CALLED BY:	GLOBAL

PASS:
	al - open mode (FileAccessFlags)
	ds:dx - file name

RETURN:
	IF file opened successfully:
		carry clear
		ax - PC/GEOS file handle

		The HF_otherInfo field of the returned handle contains
		the youngest handle open to the same file, or 0 if it
		is the only handle

	ELSE
		carry set
		ax - error code (FileError)
			ERROR_FILE_NOT_FOUND
			ERROR_PATH_NOT_FOUND
			ERROR_TOO_MANY_OPEN_FILES
			ERROR_SHARING_VIOLATION
			ERROR_WRITE_PROTECTED
			ERROR_INVALID_DRIVE

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added support for PC/GEOS file handles
	Cheng	9/89		Code to handle swapping of floppy disks
	ardeb	4/90		FS Driver support
	Todd	4/94		XIP'ed
-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileOpen		proc	far
	mov	ss:[TPD_dataBX], handle FileOpenReal
	mov	ss:[TPD_dataAX], offset FileOpenReal
	GOTO	SysCallMovableXIPWithDSDX
FileOpen		endp
CopyStackCodeXIP		ends

else

FileOpen		proc	far
	FALL_THRU	FileOpenReal
FileOpen		endp
endif

FileOpenReal	proc	far	uses cx, si, di, bp, dx, ds
	.enter
EC<	call	CheckAccessFlags					>

	mov	di, 500
	call	ThreadBorrowStackDSDX

	mov	ah,FSAOF_OPEN
	call	FileAllocOpOnPath

	call	ThreadReturnStackSpace

	.leave
	ret

FileOpenReal	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FileAllocOpOnPath

DESCRIPTION:	Call FileAllocOp and traverse path if needed

CALLED BY:	FileOpen, FileCreateTempFile, FileCreate

PASS:
	parameters for FileAllocOp (except di which can't be used)

RETURN:
	carry - set if error

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

FileAllocOpOnPath	proc	near
	push	si
	mov	si, offset FileAllocOpInt
	call	FileOpOnPath
	pop	si
	ret
FileAllocOpOnPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAllocOpInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call DR_FS_ALLOC_OP in the current FS driver to open/create
		a file. 

CALLED BY:	FileAllocOpOnPath
PASS:		di.high	= FSAllocOpFunction to invoke
		di.low	= access flags for new file
		es:si	= DiskDesc on which the file will be found
		ds:dx	= path on which to perform the operation
		other registers as appropriate to the call
RETURN:		carry clear if operation successful:
			ax	= new file handle
		carry set if operation failed:
			ax	= error code
DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAllocOpInt	proc	near
		.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, dsdx					>
EC<	call	ECAssertValidFarPointerXIP			>
EC<	pop	bx, si						>
endif
		mov	ax, di
		cmp	ah, FSAOF_OPEN
		je	callFSD	; if OPEN, FSD will check writability for us,
				;  as we must know if the file exists before
				;  we check for writability
		push	bx
		mov	bx, si
		call	FSDCheckDestWritable
		pop	bx
		jc	done
callFSD:
		push	di
		mov	di, DR_FS_ALLOC_OP
	; XXX: IF OPENING THE FILE WITH FFAF_RAW, DISK LOCK WILL NOT BE
	; ABORTABLE, BUT THAT FLAG'S FOR INTERNAL USE ONLY, SO...
		call	DiskLockCallFSD
		pop	di
		jc	done

		; al = SFN, ah = non-zero if device, di.low = access flags
		; di.high = FSAllocOpFunction
		; es:si = DiskDesc, dx = private data for FSD
		call	AllocateFileHandle
done:
		.leave
		ret
FileAllocOpInt	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCreateVerifyFileFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The file being "created" already exists, so we must make
		sure that in its current form it is compatible with the
		caller's wishes as expressed in the FCF_NATIVE flag

CALLED BY:	FileCreate
PASS:		ax	= handle created
		bh	= FileCreateFlags
		bl	= FileAccessFlags
RETURN:		carry set on error:
			bx	= ERROR_FILE_FORMAT_MISMATCH
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCreateVerifyFileFormat proc	near
		uses	cx
		.enter
		mov	cx, bx		; ch <- FileCreateFlags
		mov_tr	bx, ax		; bx <- file handle
		mov	ah, FSHOF_CHECK_NATIVE
		call	FileHandleOpFar
		mov_tr	ax, bx		; ax <- file handle, again
		mov	bx, cx		; bh <- FileCreateFlags (assume happy)
		cmc
		jnc	done
		mov	bx, ERROR_FILE_FORMAT_MISMATCH
done:
		.leave
		ret
FileCreateVerifyFileFormat endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileCreate

DESCRIPTION:	Create a new file or (optionally) truncate an existing file

CALLED BY:	GLOBAL

PASS:
	ah - FileCreateFlags
		FCF_NATIVE	set to force the format of the file to be
				the one native to the filesystem on which
				it's created, meaning primarily that DOS
				applications will be able to manipulate the
				file without doing anything special. There
				is no real reason for doing this for a file
				that will only be manipulated by PC/GEOS
				applications
				
				If FCF_MODE isn't FILE_CREATE_ONLY and the
				file already exists, but in a different
				state than that implied by this bit, then
				ERROR_FILE_FORMAT_MISMATCH will be returned
				and the file will be neither opened nor
				truncated.
				
		FCF_MODE 	one of three things:
			FILE_CREATE_TRUNCATE to truncate any existing file,
				creating the file if it doesn't exist.
	     		FILE_CREATE_NO_TRUNCATE to not truncate an existing 
				file, but create it if it doesn't exist
	     		FILE_CREATE_ONLY to fail if file of same name exists,
	     			but create it if it doesn't exist
	al - modes (FileAccessFlags). Must at least request write access
	     (FileAccessFlags <FE_NONE,FA_WRITE_ONLY>) if not read/write
	     access.
	cx - file attribute (FileAttrs) for file if it must be created.
	ds:dx - file name

RETURN:
	carry set if error:
		ax	= error code
	carry clear if success:
		ax 	= file handle

DESTROYED:
	ch

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added support for PC/GEOS file handles
	Cheng	9/89		Code to handle swapping of floppy disks
	Todd	4/94		XIP'ed
-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileCreate		proc	far
	mov	ss:[TPD_dataBX], handle FileCreateReal
	mov	ss:[TPD_dataAX], offset FileCreateReal
	GOTO	SysCallMovableXIPWithDSDX
FileCreate		endp
CopyStackCodeXIP		ends

else

FileCreate		proc	far
	FALL_THRU	FileCreateReal
FileCreate		endp
endif

FileCreateReal	proc	far
	uses bx, di, dx, bp, si
	.enter
EC <	test	ah, not mask FileCreateFlags				>
EC <	ERROR_NZ	CREATE_BAD_FLAGS				>
EC < CheckHack <FileCreateMode eq 3>					>
EC <	test	ah, mask FCF_MODE					>
EC <	jz	FCF_ok							>
EC <	ERROR_PE	CREATE_BAD_FLAGS ; => mode is 3, which is bad	>
EC <FCF_ok:								>

EC <	call	CheckAccessFlags					>
EC <	push	ax							>
EC <	andnf	al, mask FAF_MODE					>
EC <	cmp	al, FA_READ_ONLY					>
EC <	pop	ax							>
EC <	ERROR_E	CREATE_BAD_FLAGS					>

	mov	di, 500
	mov	bx, cx			; preserve FileAttrs
	call	ThreadBorrowStackDSDX
	mov	cx, bx
	push	di

	; Don't bother opening if this is a CREATE_ONLY.
	;
	mov	bx, ax				; bx <- flags and access
	andnf	bh, mask FCF_MODE		; bh <- mode
	cmp	bh, FILE_CREATE_ONLY		
	mov	bx, ERROR_FILE_NOT_FOUND	
	xchg	bx, ax			; bx <- flags, ax <- False error
	je	tryCreate
	xchg	bx, ax			; put them back...	
		
	push	ax			;save flags and access bits
	clr	ah			;mask out flag
	call	FileOpen
	pop	bx			; recover flags and access bits
	jc	tryCreate
	
	call	FileCreateVerifyFileFormat
	jc	closeOnError

		CheckHack <FILE_CREATE_ONLY gt FILE_CREATE_NO_TRUNCATE and \
			   FILE_CREATE_TRUNCATE lt FILE_CREATE_NO_TRUNCATE>

	andnf	bh, mask FCF_MODE	; FCF_NATIVE doesn't matter any more,
					;  as the files nativity is based
					;  on its current condition...
	cmp	bh, FILE_CREATE_NO_TRUNCATE
	je	done

	mov	bx, ERROR_FILE_EXISTS	; Assume FILE_CREATE_ONLY passed
	ja	closeOnError		; yup -- close file and return error

	;
	; FILE_CREATE_TRUNCATE passed and file exists. Truncate the thing
	; to 0.
	;
	xchg	bx, ax			; Need file handle in bx for truncate

	push	cx, dx
	clr	cx
	mov	dx, cx
	clr	al			; return errors, please
	call	FileTruncate
	pop	cx, dx

	xchg	ax, bx			; Return file handle in AX (possible
					;  error code moves to BX)
	jnc	done
	;
	; Error during truncation -- close the file down and return whatever
	; error we were given.
	;
closeOnError:
	xchg	ax, bx			; ax <- error code, bx <- file handle
	push	ax			; Save error code
	clr	al			; Give me errors, but I'll ignore them
	call	FileCloseFar
	pop	ax
error:
	stc
done:
	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

tryCreate:
	cmp	ax, ERROR_FILE_NOT_FOUND; Something other than missing file?
	jne	error			; Yes -- just return error
	
	;
	; File didn't exist, so try and create the thing.
	;
	mov	ah, FSAOF_CREATE
	mov	ch, bh			; ch <- FileCreateFlags
	mov	al, bl			; al <- access flags
	call	FileCreateCommon
	jmp	done
FileCreateReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCreateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to actually create a file (as opposed to opening
		an existing one, as is done first in FileCreate)

CALLED BY:	FileCreate, FileCreateTempFile
PASS:		ah	= FSAllocOpFunction
		al	= access flags (FileAccessFlags)
		cl	= attributes for new file (FileAttrs)
		ch	= FileCreateModes
		ds:dx	= path
RETURN:		ax	= file handle, if carry clear
			= error code, if carry set
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version
	Todd	4/94		XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileCreateCommon		proc	far
	mov	ss:[TPD_dataBX], handle FileCreateCommonReal
	mov	ss:[TPD_dataAX], offset FileCreateCommonReal
	GOTO	SysCallMovableXIPWithDSDX
FileCreateCommon		endp
CopyStackCodeXIP		ends

else

FileCreateCommon		proc	far
	FALL_THRU	FileCreateCommonReal
FileCreateCommon		endp
endif

FileCreateCommonReal	 proc	far
		.enter
EC <		test	cl, not (mask FA_RDONLY or mask FA_HIDDEN or \
   				mask FA_SYSTEM or mask FA_ARCHIVE) \
						; mask of illegal bits	>
EC <		ERROR_NZ	INVALID_ATTRIBUTES	; if any, error	>
EC <		call	CheckAccessFlags				>
EC <		push	ax						>
EC <		andnf	al, mask FAF_MODE				>
EC <		cmp	al, FA_READ_ONLY				>
EC <		pop	ax						>
EC <		ERROR_E	CREATE_BAD_FLAGS				>
	;
	; If creating something in a standard path, make sure all local
	; dirs up to and including the path exist.
	; 
		push	ax
		call	FileEnsureLocalPath
		jc	fail
		pop	ax
	;
	; Perform the operation.
	; 
		call	FileAllocOpOnPath
done:
		.leave
		ret
fail:
		inc	sp		; discard saved AX
		inc	sp
		jmp	done		; and boogie
FileCreateCommonReal endp

FileCommon ends

;------------------------------------

Filemisc segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileCreateTempFile

DESCRIPTION:	Create a temporary file with a unique name

CALLED BY:	GLOBAL

PASS:
	ah	= FileCreateFlags. only FCF_NATIVE has meaning.
	al	= FileAccessFlags
	cx 	= FileAttrs
	ds:dx 	= null-terminated directory in which to create file (with 14
		  extra bytes at the end in which the name of the file will be
		  placed, the result being the complete path for the file)
	      

RETURN:
	carry set if error
		ax	= error code
	carry clear if successful:
		ax	= PC/GEOS file handle
		ds:dx	= path to file actually created.

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added support for PC/GEOS file handles
	Cheng	9/89		Code to handle swapping of floppy disks
	Gene	2/00		Rewrote to use system timer for name generation
-------------------------------------------------------------------------------@

LocalDefNLString fctfTemplateTail <".TMP",0>

FileCreateTempFile	proc	far
		uses	es, di, si, bx
curCount	local	dword
		.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, dsdx					>
EC<	call	ECAssertValidFarPointerXIP			>
EC<	pop	bx, si						>
endif
	;
	; Set up args for FileCreateCommon and save for the loop...
	; 
		mov	ch, ah		; ch <- FileCreateFlags
		mov	ah, FSAOF_CREATE
		push	ax, cx
	;
	; Establish the template from the hex form of the current thread handle
	; followed by four 0's that will increment up to 9999. The suffix
	; is .TMP
	; 
		segmov	es, ds
		mov	di, dx
		LocalClrChar	ax
		mov	cx, -1
		LocalFindChar
		LocalPrevChar	esdi
		cmp	dx, di
		je	makeName	; => current dir, so no path sep
SBCS <		mov	al, C_BACKSLASH					>
DBCS <		LocalLoadChar	ax, C_BACKSLASH				>
		LocalPrevChar	esdi	; point to last char before null
SBCS <		scasb			; path sep already?		>
DBCS <		scasw			; path sep already?		>
		je	makeName	; yes -- don't add another
		LocalPutChar	esdi, ax
makeName:		
	    ;
	    ; Put in the timer count XOR'd with the process handle
	    ; for a nice random value
	    ; 
		mov	bx, di		; ds:bx <- start of part that changes
					;  with each iteration.
		call	TimerGetCount
		xor	bx, ss:TPD_processHandle
		movdw	ss:curCount, bxax
		call	putHexDWord
	    ;
	    ; add the file extension .TMP
	    ;
		mov	si, offset fctfTemplateTail
		CheckHack <not (length fctfTemplateTail and 1)>
if DBCS_PCGEOS
	rept (length fctfTemplateTail)
		movsw	cs:
	endm
else
	rept (length fctfTemplateTail)/2
		movsw	cs:
	endm
endif
	    ;
	    ; Null-terminate.
	    ; 
		LocalClrChar	ax
		LocalPutChar	esdi, ax
	;
	; Now loop through the 10,000 possible names trying to create each one
	; in turn.
	; 
		pop	cx
createLoop:
		pop	ax
		push	ax
		call	FileCreateCommon
		jnc	done
	;
	; Creation failed. Keep going so long as it's because a file of the
	; same name already exists.
	; 
		cmp	ax, ERROR_FILE_EXISTS
		stc
		jne	done
	;
	; Try the next number. We don't bother checking for an end condition,
	; because in order to fail it would require 2^32 *.TMP files in
	; the same directory. Created at one per second, it would take
	; over 136 years...
	;
		incdw	ss:curCount
		mov	di, bx				;es:di <- buf
		call	putHexDWord
		jmp	createLoop
	
done:
		inc	sp		; clear saved AX off the stack w/o
		inc	sp		;  biffing the carry

		.leave
		ret

if DBCS_PCGEOS
fctfHex8ToAscii	label	near
		push	bx
		push	ax
		mov	bx, offset fctfNibbles
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		clr	ah
		stosw
		pop	ax
		and	al, 0fh
		xlatb	cs:
		clr	ah
		stosw
		pop	bx
		retn
endif

putHexDWord:
		push	ax
		mov	ax, ss:curCount.high
		call	putHexWord
		mov	ax, ss:curCount.low
		call	putHexWord
		pop	ax
		retn

putHexWord:
		push	ax
		mov	al, ah				;al <- high byte
SBCS <		call	InitFileHex8ToAscii				>
DBCS <		call	fctfHex8ToAscii					>
		pop	ax
SBCS <		call	InitFileHex8ToAscii				>
DBCS <		call	fctfHex8ToAscii					>
		retn

FileCreateTempFile	endp

DBCS <fctfNibbles		db	"0123456789ABCDEF"		>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FILEENABLEOPENCLOSENOTIFICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the sending of FCNT_OPEN/FCNT_CLOSE notifications.

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FILEENABLEOPENCLOSENOTIFICATION proc	far
		uses	ds, ax
		.enter
		LoadVarSeg	ds, ax
		inc	ds:[openCloseNotificationCount]
		.leave
		ret
FILEENABLEOPENCLOSENOTIFICATION endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FILEDISABLEOPENCLOSENOTIFICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable the sending of FCNT_OPEN/FCNT_CLOSE notifications.

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FILEDISABLEOPENCLOSENOTIFICATION proc	far
		uses	ds, ax
		.enter
		LoadVarSeg	ds, ax
		dec	ds:[openCloseNotificationCount]
		.leave
		ret
FILEDISABLEOPENCLOSENOTIFICATION endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileDuplicateHandle

DESCRIPTION:	Return a new handle that refers to the same file as the given
		handle.

CALLED BY:	GLOBAL

PASS:
	bx - file handle to duplicate

RETURN:
	carry - set if error
	ax - new file handle (if no error)
	     error code (if an error)
		ERROR_TOO_MANY_OPEN_FILES

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	GetFileHandle calls FileCheckAccess which is unnecessary when we
	duplicate handles.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added code for PC/GEOS file handles
-------------------------------------------------------------------------------@

FileDuplicateHandle	proc	far
	uses bx, ds, cx, si, di
	.enter
	call	ECCheckFileHandle

	;
	; First tell the FSD about the new reference to the thing.
	; 
	mov	ah, FSHOF_ADD_REFERENCE
	call	FileHandleOpFar
	jc	done
	
	;
	; Make an exact copy of the thing. We can't use AllocateFileHandle for
	; all this, as it could well look at the copy and the original and
	; declare their access modes to conflict.
	; 
	LoadVarSeg	ds, si
	mov	si, bx
	call	MemIntAllocHandle ; allocate new handle owned by whomever, as
				;  it'll be overwritten in a moment (XXX: what
				;  if AllocateHandle changes to check that the
				;  owner is a geode? DupHandle will break too :)

	push	es
	segmov	es, ds
	mov	di, bx
	mov	cx, size HandleFile
	mov	ax, si		; preserve original for possible HF_otherInfo
				;  adjustment
	rep	movsb
	pop	es
	
	; change ownership of the duplicate to be the current process, not the
	; owner of the handle being duplicated.

	mov	si, ss:[TPD_processHandle]
	mov	ds:[bx].HF_owner, si
	
	call	PFileListFar
	;
	; If original handle had no HF_otherInfo set, point duplicate's
	; HF_otherInfo to the original, for consistency's sake.
	; 
	tst	ds:[bx].HF_otherInfo
	jnz	linkIt
	mov	ds:[bx].HF_otherInfo, ax
linkIt:
	;
	; Now place the new handle at the front of the file list.
	; 
	mov	ax, bx
	xchg	ax, ds:[fileList]
	mov	ds:[bx].HF_next, ax
	call	VFileListFar

	mov_trash	ax, bx	; return new handle in AX
done:
	.leave
	ret
FileDuplicateHandle	endp

Filemisc	ends

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileClose

DESCRIPTION:	Close an open file.

CALLED BY:	GLOBAL

PASS:
	al - flags:
		bit 7 - set if caller can't handle errors (FILE_NO_ERRORS)
		bits 6-0 - RESERVED (must be 0)
	bx - PC/GEOS file handle

RETURN:		carry - set if error
		ax - error code

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added support for PC/GEOS file handles
	Cheng	9/89		Code to handle swapping of floppy disks
-------------------------------------------------------------------------------@
FileCloseFar	proc	far
		call	FileClose
		ret
FileCloseFar	endp

FileClose	proc	near
		.enter
EC <		push	ds, bx						>
EC <		LoadVarSeg	ds					>
EC <		mov	bx, ds:[bx].HF_otherInfo			>
EC <		tst	bx						>
EC <		jz	handleOK					>
EC <		tst	ds:[currentThread]	; shutting down?	>
EC <		jz	handleOK		; yes -- don't hassle me>
EC <		cmp	ds:[bx].HG_type, SIG_VM				>
EC <		ERROR_E	VM_FILE_MUST_BE_CLOSED_WITH_VM_CLOSE		>
EC <handleOK:								>
EC <		pop	ds, bx						>
		
		call	FileErrorCatchStart
	;
	; See if we need to lock the disk down. If the file's not dirty, we
	; don't lock the disk down, allowing the user to close a clean document
	; without having to have the disk around.
	; 
		push	ax
		mov	ah, FSHOF_CHECK_DIRTY
		call	FileHandleOp
		tst	ax
		pop	ax

	;
	; Call the appropriate utility routine to actually close the
	; thing down.
	; 
		mov	ah, FSHOF_CLOSE
		jnz	lockHandleOp
		
		call	FileHandleOp
		jmp	closeCommon
lockHandleOp:
		call	FileLockHandleOp
closeCommon:
	;
	; Deal with errors and our caller's inability to deal with them...
	; 
		call	FileErrorCatchEnd
		.inst	byte	KS_FILE_CLOSE

		jc	done
	;
	; File closed successfully, so unlink & free the file handle.
	; 
		call	FreeFileHandle
done:
		.leave
		ret
FileClose	endp
