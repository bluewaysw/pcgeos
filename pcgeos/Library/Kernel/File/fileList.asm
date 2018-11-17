COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/File -- File list manipulation
FILE:		fileList.asm

AUTHOR:		Adam de Boor, Apr  6, 1990

ROUTINES:
	Name			Description
	----			-----------
    INT	AllocateFileHandle	Convert a DOS handle to a GEOS handle
    INT FreeFileHandle		Free up a GEOS file handle
    EXT ExitFile		Close all remaining open files
    EXT FileFindDuplicate	Find another handle referring to the same file
    EXT FileForEach		Process the file list file by file.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 6/90		Initial revision


DESCRIPTION:
	Functions for manipulating/searching the file list
		

	$Id: fileList.asm,v 1.1 97/04/05 01:11:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

FUNCTION:	FreeFileHandle

DESCRIPTION:	Free a GEOS file handle

CALLED BY:	INTERNAL (FileClose)

PASS:		bx - GEOS file handle

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version
------------------------------------------------------------------------------@

FreeFileHandle	proc	near	uses ax, ds, si
	.enter
	call	FSLoadVarSegDS
EC<	call	ECCheckFileHandle					>
	call	PFileList
	mov	ax, offset fileList - HF_next
scanLoop:
	mov	si, ax
	mov	ax, ds:[si].HF_next
EC <	tst	ax							>
EC <	ERROR_Z	FILE_LIST_CORRUPT					>
	cmp	ax, bx
	jne	scanLoop

	mov	ax, ds:[bx].HF_next	; link around handle being freed
	mov	ds:[si].HF_next, ax
	call	VFileList

	call	FarFreeHandle
	.leave
	ret
FreeFileHandle	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ExitFile

DESCRIPTION:	End file interactions with DOS

CALLED BY:	INTERNAL (EndGeos)

PASS:		ds - idata

RETURN:		nothing

DESTROYED:	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Cheng	4/89		Initial version

------------------------------------------------------------------------------@
ExitFile	proc	far
EF_loop:
	;
	; Continue closing the head of the fileList (which should remove it
	; from the list) until the list is empty.
	;
	mov	bx, ds:fileList
	tst	bx
	jz	done
EC <	mov	ds:[bx].HF_otherInfo, 0		; avoid EC death if VM	>
	clr	al
	call	FileClose
	call	ResetWatchdog
	jmp	EF_loop
done:
EC <		mov	ds:[fileExited], TRUE				>
	ret
ExitFile	endp

;-----------------------------------------------------------------

FileCommon segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	AllocateFileHandle

DESCRIPTION:	Allocate a GEOS file handle for a newly-open file. Performs
		required access-control checks.

CALLED BY:	RESTRICTED GLOBAL (FileAllocOpInt,
		FileDuplicateHandle, RFSAllocOp)

PASS:		al	= SFN
		ah	= non-zero if open to device
		dx	= private data word for FSD
		di.low	= FileFullAccessFlags
		di.high	= FSAllocOpFunction that caused this to be created.
			  If FSAOF_OPEN, write access requested, and disk
			  non-writable, file will be closed and 
			  ERROR_WRITE_PROTECTED returned.
		es:si	= DiskDesc of disk on which file was opened
		es	= FSIR locked shared

RETURN:		if no error:
			carry clear
			ax 	= new handle
		else
			carry set
			ax	= error code
			es	= new segment of FSIR, in case it moved while
				  the file was being closed

DESTROYED:	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version
	ardeb	9/91		Convert to Ideal FS
------------------------------------------------------------------------------@

AllocateFileHandle	proc	far
 	uses 	cx, dx, ds, si, di, bp
	.enter
	LoadVarSeg	ds, bx
	mov	bx, ss:[TPD_processHandle]	; bx <- file owner
	call	MemIntAllocHandle		; this zeroes everything...

	;
	; Initialize the various fields to zero or their proper value,
	; if we've got it around.
	; 
	
	mov	ds:[bx].HF_sfn, al		; store SFN from FSD
	tst	ah				; open to device?
	jnz	10$				; yes -- leave HF_disk 0
	mov	ds:[bx].HF_disk, si		; no -- store offset to disk
						;  descriptor
10$:
	mov	ds:[bx].HF_handleSig, SIG_FILE	; mark as file handle
	mov_trash	ax, di			; al <- access flags
						; ah <- FSAllocOpFunction
	mov	ds:[bx].HF_accessFlags, al
	mov	ds:[bx].HF_semaphore, 1		; File handle not grabbed
	mov	ds:[bx].HF_private, dx

	;
	; If file opened by FSAOF_OPEN and write access requested, make sure
	; the destination disk is writable.
	; 
	cmp	ah, FSAOF_OPEN			; opened by open?
	jne	checkAccess

	inc	al				; convert 0-2 -> 1-3, thereby
	test	al, 2				;  setting b1 if writing
	jz	checkAccess			;  requested
	xchg	bx, si				; bx <- disk, si <- file
	call	FSDCheckDestWritable		; returns ax = proper error
						;  code if write-protected
	xchg	bx, si
	jc	closeOnError

checkAccess:
	;
	; Now loop through all open files looking for any that are open
	; to the same file and making sure the access/deny modes for the
	; new file are compatible with what's already out there.
	; 
	
	call	PFileListFar
	
	; determine the FSD to call right at the start, since it will
	; remain constant throughout the loop.

	mov	bp, es:[FIH_primaryFSD]		; assume open to device and
						;  set bp to primary FSD
	tst	ds:[bx].HF_disk
	jz	haveFSD				; => correct
	mov	bp, es:[si].DD_drive		; nope. actually on a disk, so
	mov	bp, es:[bp].DSE_fsd		;  perform the usual indirec-
						;  tions to get to the FSD
haveFSD:
	clr	si
scanLoop:
	call	FileFindDuplicateInt
	jnc	openOK
	
	;
	; Set the file's otherInfo field to this handle that refers to the
	; same file (since files are added to the head, this means HF_otherInfo
	; will always be the oldest open handle referring to the file).
	; 
	mov	ds:[bx].HF_otherInfo, si

	;
	; Fetch the access flags for the two handles and make sure they're
	; compatible.
	; 
	mov	al, ds:[bx].HF_accessFlags
	mov	ah, ds:[si].HF_accessFlags
	call	IsAccessCompatible
	jnc	scanLoop

	;
	; Ick. Close the thing down after releasing the file list.
	; 
	call	VFileListFar
	mov	ax, ERROR_SHARING_VIOLATION

closeOnError:
	push	ax				; save error code
	mov	ax, (FSHOF_CLOSE shl 8) 	; al <- 0 => errors ok
						; ah <- operation to perform
	call	FileLockHandleOpFar
	call	FarFreeHandle			; free the handle we can no
						;  longer use.
	pop	ax
	stc
	jmp	done

openOK:
	mov	ax, ds:[fileList]
	mov	ds:[bx].HF_next, ax
	mov	ds:[fileList], bx
	call	VFileListFar
	
	mov_tr	ax, bx
	clc
done:
	.leave
	ret
AllocateFileHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileFindDuplicateInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal routine to do all the actual work of locating
		a file that's open to the same file as the passed one.

CALLED BY:	FileFindDuplicate, AllocateFileHandle
PASS:		ds	= dgroup
		bx	= handle against which to compare
		si	= handle after which to start (0 => start at the
			  beginning)
		es:bp	= FSDriver through which to call (es == FSIR locked
			  shared)
		fileListSem grabbed
RETURN:		carry set if found a duplicate:
			si	= handle of same
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileFindDuplicateInt	proc	far
		uses	dx
		.enter
		tst	si
		jnz	searchLoop
		mov	si, offset fileList - offset HF_next
searchLoop:
	;
	; Advance to the next file in the list. If no next file, no duplicate
	; for that passed, so return carry clear.
	; 
		mov	si, ds:[si].HF_next
		tst	si		; (clears carry)
		je	done
	;
	; If handles are the same, keep looking, as we're not interested in
	; truisms...
	; 
		cmp	bx, si
		je	searchLoop
	;
	; Make sure the two handles are open to the same disk. The obviously
	; cannot be open to the same file if they aren't open to the same disk.
	; 
		mov	ax, ds:[si].HF_disk
		cmp	ds:[bx].HF_disk, ax
		jne	searchLoop
	;
	; Ask the FSD if they're open to the same file.
	; 
		push	bx, bp
		mov	al, ds:[bx].HF_sfn
		mov	bx, ds:[bx].HF_private
		mov	cl, ds:[si].HF_sfn
		mov	dx, ds:[si].HF_private
		mov	di, DR_FS_COMPARE_FILES
		call	es:[bp].FSD_strategy
		pop	bx, bp
		sahf				; fetch result...
		jne	searchLoop
	;
	; Flag duplicate found.
	; 
		stc
done:
		.leave
		ret
FileFindDuplicateInt	endp

FileCommon ends

;-----------------------------------------------------------------


Filemisc	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	IsAccessCompatible

DESCRIPTION:	Checks to see if the file sharing and access modes of the
		two handles are compatible.

CALLED BY:	INTERNAL (AllocateFileHandle)

PASS:		al	= access flags for first handle
		ah	= access flags for second handle

RETURN:		carry - set if error

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Call IACCheck to see if al is compatible with ah, then switch al and
	ah call IACCheck again, thereby seeing if the original ah is compatible
	with the original al...

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/89		Initial version
------------------------------------------------------------------------------@

IsAccessCompatible	proc	far
	call	IACCheck
	jc	done
	xchg	ah, al
	call	IACCheck
done:
	ret
IsAccessCompatible	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare a set of denial bits and a set access-request
		bits to see if they are compatible.

CALLED BY:	IsAccessCompatible?
PASS:		ah	= access-request bits
		al	= denial bits
RETURN:		carry set if access denied
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The denial modes are numbered:
			1	exclude all
			2	exclude writes
			3	exclude reads
			4	exclude none
		The access-request codes are
			0	read only
			1	write only
			2	read/write
		Thus, if we increment the access-request code, we get bit 0
		indicating read access required, and bit 1 indicating write
		access required. Further if we decrement and invert the
		denial modes, we get (at least for bits 0 and 1):
			3	exclude all
			2	exclude writes
			1	exclude reads
			0	exclude none
		Note that if we mask the incremented access-request code with
		the altered denial mode value, a non-zero value indicates that
		the access is denied...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACCheck	proc	near	uses cx
		.enter
		push	ax
		and	ah, mask FFAF_MODE
EC <		cmp	ah, FileAccess					>
EC <		ERROR_AE	BAD_ACCESS_MODE				>
		and	al, mask FFAF_EXCLUDE
EC <		cmp	al, FileExclude shl offset FFAF_EXCLUDE	>
EC <		ERROR_AE	BAD_SHARING_MODE			>
EC <		tst	al						>
EC <		ERROR_Z		BAD_SHARING_MODE			>
		inc	ah
		mov	cl, offset FFAF_EXCLUDE
		shr	al, cl
		dec	ax		; (1-byte inst and won't affect ah)
		not	al
		and	al, ah		; (clears carry)
		xchg	ax, cx		; save result
		pop	ax		; and get original values
		jz	ok		; Z => no conflicts
	;
	; Deal with FFAF_EXCLUSIVE and FFAF_OVERRIDE. If the only conflict
	; between the files is for reading, we say the accesses are compatible
	; if the one requesting read access has the FFAF_OVERRIDE bit set and
	; the one denying reading *doesn't* have the FFAF_EXCLUSIVE bit set.
	;
		test	cl, 2		; Writing conflict?
		jnz	bad
		test	al, mask FFAF_EXCLUSIVE; File *really* exclusive?
		jnz	bad
		test	ah, mask FFAF_OVERRIDE; Opener overriding reading
					      ;  conflict?
		jnz	ok
bad:
		stc
ok:
		.leave
		ret
IACCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileFindDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find any other file handle that refers to the same file.

CALLED BY:	EXTERNAL (VMFindOtherOpen)
PASS:		bx	= file handle any duplicate of which is sought.
		ds	= idata
		si	= handle after which to start searching or 0 to
			  search entire list
RETURN:		si	= duplicate handle
		carry set if successful
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileFindDuplicate proc far
EC <		call	AssertDSKdata					>
		ENTER_FILE
		push	ax, cx		; save additional registers we need
					;  to trash but dare not.

		call	PFileListFar	; gain exclusive access to the list
	;
	; Figure the FSD we'll be calling to perform the comparison.
	; 
		mov	bp, es:[FIH_primaryFSD]
		tst	ds:[bx].HF_disk
		jz	haveFSD
		mov	bp, ds:[bx].HF_disk
		mov	bp, es:[bp].DD_drive
		mov	bp, es:[bp].DSE_fsd
haveFSD:
	;
	; Do the traversal using common code.
	; 
		call	FileFindDuplicateInt
	;
	; Recover appropriate registers, set the return register into the
	; frame from whence it will be popped.
	; 
		pop	ax, cx
		mov	bp, sp
		mov	ss:[bp].EFF_si, si
	;
	; Release the file list, now we've got what we wanted.
	; 
		call	VFileListFar

		EXIT_FILE
		ret
FileFindDuplicate endp

Filemisc ends

;---------------------------------------------------------------

;;; I'm moving FileForEach into kcode for Wizard -jon 27 apr 1993
;;; This is done for Wizard's "fast login", where a machine's
;;; NetWare connection is abruptly severed while GEOS is running, and
;;; FileForEach is one of the routines needed to patch things up.
;;;
;;; Wizard isn't an XIP system, so don't do this on full-XIP systems
;;;
FXIP <FileSemiCommon segment resource					>
NOFXIP <FSResident segment resource					>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileForEach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the file list with a supplied callback function

CALLED BY:	GLOBAL
PASS:		ax, cx, dx, bp = initial data to pass to callback
		bx	= file from which to start processing. 0 to process
			  entire list.
		di:si	= far ptr to callback routine
			(or virtual far pointer on XIP systems)	
RETURN:		ax, cx, dx, bp = as returned from last call
		carry - set if callback forced early termination of processing.
		bx	= last file processed if carry set, else 0
DESTROYED:	di, si

PSEUDO CODE/STRATEGY:
		CALLBACK ROUTINE:
			Pass:	bx	= handle of file to process
				ds	= idata
				ax, cx, dx, bp = data as passed to FileProcess
					  or returned from previous callback
			Return:	carry - set to end processing
				ax, cx, dx, bp = data to send on or return
			Can Destroy: di, si, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileForEach	proc	far	uses ds, es
callback	local	fptr.far	\
		push	di, si 		; set it
	ForceRef callback
		.enter
if	FULL_EXECUTE_IN_PLACE
EC <	xchg	bx, di							>
EC <	call	ECAssertValidFarPointerXIP				>
EC <	xchg	bx, di							>
endif
	;
	; Snag the list semaphore for the whole thing.
	;
FXIP <		call	PFileListFar					>
NOFXIP <	call	PFileList					>
	;
	; Point DS at idata for the duration.
	;
		LoadVarSeg	ds
		
		tst	bx
		jnz	processLoop
		mov	bx, ds:[fileList]
processLoop:
		tst	bx		; hit end of list?
		jz	done
		call	SysCallCallbackBPFar
		mov	bx, ds:[bx].HF_next
		jnc	processLoop
done:
	;
	; Release list semaphore now processing is complete. Note: VFileList
	; doesn't touch the carry flag or any other register.
	; 
FXIP <		call	VFileListFar					>
NOFXIP <	call	VFileList					>
		.leave
		ret
FileForEach	endp

FXIP <FileSemiCommon	ends						>
NOFXIP <FSResident	ends						>
