COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/File -- General Utility Routines
FILE:		fileUtils.asm

AUTHOR:		Adam de Boor, Apr  6, 1990

ROUTINES:
	Name			Description
	----			-----------
    INT EnterFile		Initial setup for File, Disk and Drive
				routines

    INT FarEnterFile		Similar to EnterFile, but intended to be
				called by any sort of routine (near or far)
				outside of kcode. Must be matched by a call
				to FarExitFile at the end of the routine.
				Registers and stack are left exactly as for
				EnterFile.

    INT FarExitFile		Other half of EnterFile for routines not in
				kcode.

    EXT FileLockInfoSharedToES	Lock the FSInfoResource for reading,
				returning it in ES

    INT FileGetDestinationDisk	Fetch the disk handle of the destination of
				a file operation

    INT FSDCheckDestWritable	See if the destination of some file
				operation is writable. This determines only
				if the disk in question is write-protected
				(or unusable), not if the file/directory in
				question is marked read-only. Presumably
				DOS is competent enough to figure that out
				itself. We're just trying to avoid critical
				errors...

    EXT FileWPathOpOnPath	Perform an operation on a path after
				ensuring the destination disk is writable.
				Note that a path op is different from an
				alloc op in that path ops never allocate a
				file handle.

    INT FileOpOnPath		Front-end function to do something to a
				file, dealing with logical paths.

    INT FileWPathOpInt		Perform an operation on a path after
				ensuring the destination disk is writable.
				This does not deal with the current path or
				the path in question being within a
				logical/standard directory. The thread's
				current path is assumed to be a physical
				one.

    GLB FileInt21		External interface to FSDInt21 function

    INT FileErrorCatchStart	Begin error filter for file functions

    INT FileErrorCatchEnd	Prevent any errors from being returned to
				callers that can't handle them. Called at
				the end of a function that called
				FileErrorCatchStart. If an error was
				detected for a function where the caller
				requested that no errors be returned,
				SysNotify will be called to inform the user
				that an unrecoverable error has occurred
				and would he like to exit or reboot?

    INT FHOpGetDiskHandle	Extract the disk handle for an open file
				into SI, where the Disk routines expect it.

    INT FileLockHandleOpFar	Perform a handle operation after locking
				the disk on which the referenced file is
				located.  The file handle is also checked
				for validity in both EC and non-EC, so the
				caller need not do so.

    INT FileLockHandleOp	Perform a handle operation after locking
				the disk on which the referenced file is
				located.  The file handle is also checked
				for validity in both EC and non-EC, so the
				caller need not do so.

    INT FileHandleOpFar		Perform some operation on a file handle via
				its FS driver.  The file handle is checked
				for validity, so the caller need not do so.

    INT FileHandleOp		Perform some operation on a file handle via
				its FS driver.  The file handle is checked
				for validity, so the caller need not do so.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 6/90		Initial revision


DESCRIPTION:
	Utility routines for the File module.
		

	$Id: fileUtils.asm,v 1.1 97/04/05 01:11:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


FSLoadVarSegDS	proc	near
	mov	ds, cs:[fsDgroupSeg]
	ret
fsDgroupSeg	word	dgroup
FSLoadVarSegDS	endp

;------------------------------------------------------------------------------
;
;		ENTER/EXIT PROCESSING FOR FILE MODULE
;
; These routines are responsible for saving/restoring common registers,
; locking/unlocking various things, etc. They should *not* be called directly.
; Instead, the ENTER_FILE and EXIT_FILE macros should be used at the beginning
; and end of the appropriate routine.
;
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initial setup for File, Disk and Drive routines

CALLED BY:	INTERNAL
       		(File, Disk and Drive routines)
PASS:		nothing
RETURN:		es	= FSInfoResource locked for shared access
		si, di, bp, dx saved on the stack
DESTROYED:	bp

PSEUDO CODE/STRATEGY:
		This is a co-routine. You (a near routine) call it, it
		saves some registers, locks the FSInfoResource and "returns"
		to you by calling you back at its return address. When
		you finally return, it pops the registers it saved,
		unlocks the FSInfoResource and returns to your caller.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnterFile	proc	near call
	;
	; Save the registers what need saving.
	; 
		push	es, di, si, bp, dx

EC <		call	ECCheckStack					>

	;
	; Lock the FSInfoResource to ES for shared access.
	; 
		call	FileLockInfoSharedToES
	;
	; Call our caller back.
	; 
		mov	bp, sp
		call	ss:[bp-2].EFF_retnCaller; call the caller back, taking
						;  into account the fact that
						;  the return address to us
						;  isn't actually on the stack
						;  yet, though EFFrame
						;  incorporates it.
	;
	; Release the FSInfoResource.
	; 
		call	FSDUnlockInfoShared
	;
	; Pop the registers we saved, and boogie
	; 
		pop	es, di, si, bp, dx

		inc	sp	; discard EFF_retnCaller w/o
		inc	sp	;  biffing the carry
		ret		; return to our caller's caller
EnterFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FarEnterFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Similar to EnterFile, but intended to be called by any
		sort of routine (near or far) outside of kcode. Must be
		matched by a call to FarExitFile at the end of the routine.
		Registers and stack are left exactly as for EnterFile.

CALLED BY:	INTERNAL
       		(routines outside kcode)
PASS:		nothing
RETURN:		es	= FSInfoResource locked for shared access
		si, di, bp, dx saved on the stack
DESTROYED:	bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FarEnterFile	proc	far	call
	;
	; Save the registers what need saving.
	;
		push	es, di, si, bp, dx
	;
	; Lock the FSInfoResource to ES for shared access.
	;
		call	FileLockInfoSharedToES
	;
	; Copy return address down after making room for fake EFF_retnInt
	; field
	; 
		dec	sp
		dec	sp
		mov	bp, sp
		push	({fptr}ss:[bp].EFF_retnCaller).segment
		push	({fptr}ss:[bp].EFF_retnCaller).offset
		ret
FarEnterFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FarExitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Other half of EnterFile for routines not in kcode.

CALLED BY:	INTERNAL
       		(routines not in kcode)
PASS:		es	= FSIR locked shared
		EFFrame on stack
RETURN:		si, di, bp, dx as passed to FarEnterFile
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FarExitFile	proc	far call
	;
	; Place our return address where FarEnterFile's is now.
	; 
		mov	bp, sp
		pop	({fptr}ss:[bp+4].EFF_retnCaller).offset
		pop	({fptr}ss:[bp+4].EFF_retnCaller).segment
	;
	; Point ss:sp to the first saved register, discarding the garbage
	; EFF_retnInt.
	; 
		lea	sp, ss:[bp+4].EFF_dx
	;
	; Release the FSIR.
	; 
		call	FSDUnlockInfoShared
	;
	; Pop all the saved registers in the proper order.
	; 
		pop	es, di, si, bp, dx

		ret
FarExitFile	endp

;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLockInfoSharedToES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the FSInfoResource for reading, returning it in ES

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		es	= FSInfoResource
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLockInfoSharedToES	proc	far
		uses	ax
		.enter
		call	FSDLockInfoShared
		mov	es, ax
		.leave
		ret
FileLockInfoSharedToES	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileInt21
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	External interface to FSDInt21 function

CALLED BY:	GLOBAL
PASS:		registers for DOS call
RETURN:		values from DOS call
DESTROYED:	depends on function called

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileInt21	proc	far
		.enter
		call	FSDInt21
		.leave
		ret
FileInt21	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileErrorCatchStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin error filter for file functions

CALLED BY:	FileClose, FileRead, FileWrite
PASS:		al	= FILE_NO_ERRORS if caller of caller cannot handle
			  getting an error and no error, barring hardware
			  failure, is expected. If an error does occur, it
			  is acceptable to biff the system. Be careful out
			  there.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileErrorCatchStart proc near
		.enter
		xchg	ax, bx		; bl <- error flag, ax <- passed bx
		XchgTopStack	bx	; bx <- ret addr, push error flag
		push	bx		; put ret addr back on stack
		mov	bx, sp
		mov	bx, ss:[bx+2]	; bl <- error flag
		xchg	ax, bx		; al <- error flag, bx <- passed bx
		.leave
		ret
FileErrorCatchStart endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileErrorCatchEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent any errors from being returned to callers that
		can't handle them. Called at the end of a function that
		called FileErrorCatchStart. If an error was detected for
		a function where the caller requested that no errors be
		returned, SysNotify will be called to inform the user that
		an unrecoverable error has occurred and would he like to
		exit or reboot?

CALLED BY:	FileClose, FileRead, FileWrite, FileCommit, FileTruncate
PASS:		return address pointing to KernelStrings byte giving name
		of calling function.

		a word is also left on the stack by FileErrorCatchStart, so
		the stack should be in the same condition (except for the
		string address pushed) as it was when FileErrorCatchStart
		was called.
RETURN:		only if no error was detected or errors are permitted.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileErrorCatchEnd proc	near	errFlag:word
		.enter
		jnc	noError
		test	errFlag, FILE_NO_ERRORS
		jz	error
	;
	; Now tell the user we can't go on. If user chooses exit, rather than
	; reboot, SysShutdown will be called by SysNotify, but we need to
	; field events for the thread until it is sent an EXIT message...
	;
		call	FSLoadVarSegDS

		push	ax, bx		; save for debugging purposes!

ifdef	GPC
		mov	al, KS_TE_SYSTEM_ERROR
		call	AddStringAtMessageBufferFar
		mov	al, KS_FILE_ERROR
		call	AddStringAtESDIFar
else
		mov	al, KS_UNRECOVERABLE_ERROR_IN
		call	AddStringAtMessageBufferFar
endif	; GPC
		mov	bx, ss:[bp+2]	; point to data byte following call
		mov	al, cs:[bx]
		call	AddStringAtESDIFar

ifdef	GPC
		clr	di		; no second string
else
		LocalNextChar	esdi	; skip over null
		push	di		; save start
		mov	al, KS_UNRECOVERABLE_ERROR_PART_TWO
		call	AddStringAtESDIFar
		pop	di				; ds:di <- 2nd string
endif
		mov	si, offset messageBuffer	; ds:si <- first string

ifdef	GPC
		mov	ax, mask SNF_EXIT	; unrecoverable - exit
else
		mov	ax, mask SNF_EXIT or mask SNF_REBOOT
endif
		call	SysNotify
		clr	bx		; Attach to current queue
		call	ThreadAttachToQueue
		.UNREACHED
error:
	;
	; Error, but it's acceptable -- just return carry set.
	;
		stc
noError:
	;
	; Point past the FECData structure that follows the call without
	; destroying anything...
	; 
		inc	{word}ss:[bp+2]
		.leave
		ret	@ArgSize
FileErrorCatchEnd endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FHOpGetDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the disk handle for an open file into SI, where
		the Disk routines expect it.

CALLED BY:	FileLockHandleOp, FileHandleOp
PASS:		bx	= file handle (checked for validity by
			  FileGetDiskHandle)
RETURN:		si	= disk handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FHOpGetDiskHandle proc	near
		uses	bx
		.enter
		call	FileGetDiskHandle
		mov	si, bx
		.leave
		ret
FHOpGetDiskHandle endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLockHandleOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a handle operation after locking the disk on which
		the referenced file is located.
		
		The file handle is also checked for validity in both EC and
		non-EC, so the caller need not do so.

CALLED BY:	Things in fileIO.asm
PASS:		bx	= file handle
		ah	= FSHandleOpFunction to perform
		al	= has FILE_NO_ERRORS bit set if disk lock may
			  not be aborted.
RETURN:		di, bx, es unaltered
DESTROYED:	depends on function called

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLockHandleOpFar	proc	far
		call	FileLockHandleOp
		ret
FileLockHandleOpFar	endp

FileLockHandleOp	proc	near
	;
	; Lock things what need locking, saving registers what need saving.
	;
		ENTER_FILE
	;
	; Extract the disk handle from the file handle so we can validate
	; it and find the FSD to call.
	;
		call	FHOpGetDiskHandle
	;
	; Contact the FSD to Do The Right Thing.
	;
		mov	di, DR_FS_HANDLE_OP
		push	ax
		call	DiskLockCallFSD
		pop	di
	;
	; If the function returns something in DX, we have to play games to
	; get it there when we return.
	; 
		pushf
		xchg	ax, di
		cmp	ah, FSHOF_POSITION
		je	returnDX
		cmp	ah, FSHOF_GET_DATE_TIME
		je	returnDX
		cmp	ah, FSHOF_FILE_SIZE
		je	returnDX
done:
		xchg	ax, di
		popf
		EXIT_FILE
		ret
returnDX:
	;
	; Operation expects return value in DX, so store it into the frame
	; for EnterFile to pop, accounting for the flags word we pushed.
	; 
		mov	bp, sp
		mov	ss:[bp+2].EFF_dx, dx
		jmp	done
FileLockHandleOp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileHandleOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform some operation on a file handle via its
		FS driver.
		
		The file handle is checked for validity, so the caller
		need not do so.

CALLED BY:	INTERNAL
PASS:		bx	= file handle
		ah	= FSHandleOpFunction to perform
		the rest is subject to change without notice
		parameters may not be passed in es or di
RETURN:		di, bx, es unaltered
DESTROYED:	depends on function called

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileHandleOpFar	proc	far
		call	FileHandleOp
		ret
FileHandleOpFar	endp

FileHandleOp	proc	near
		ENTER_FILE
		call	FHOpGetDiskHandle
		mov	di, DR_FS_HANDLE_OP
		call	DiskCallFSDNoLock
		EXIT_FILE
		ret
FileHandleOp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FILEBATCHCHANGENOTIFICATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Merge all file-change notifications into batches, to reduce
		the number of handles, etc., required during large-scale
		filesystem operations.

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FILEBATCHCHANGENOTIFICATIONS proc	far
		uses	bx
		.enter
		tst	ss:[TPD_fsNotifyBatch]
		jnz	done
		call	FSDAllocNewBatchBlock
		jc	done
		mov	ss:[TPD_fsNotifyBatch], bx
done:
		.leave
		ret
FILEBATCHCHANGENOTIFICATIONS endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FILEFLUSHCHANGENOTIFICATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush pending file-change notifications.

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FILEFLUSHCHANGENOTIFICATIONS	proc	far
		uses	ax, bx, cx, dx, ds
		.enter
		pushf
	;
	; We'd like to process the notifications in the order in which they
	; occurred, but they're in blocks in a linked list from newest to
	; oldest, so push the blocks onto the stack, preceded by a 0 word
	; so we know when we reach the end.
	; 
		LoadVarSeg	ds, ax
		clr	bx
		push	bx		; sentinel
		xchg	ss:[TPD_fsNotifyBatch], bx	; bx <- head, turn off
							;  batching
pushLoop:
		tst	bx
		jz	processBlocks
		push	bx
		mov	bx, ds:[bx].HM_otherInfo
		jmp	pushLoop

processBlocks:
		pop	bx		; bx <- next block
		tst	bx
		jz	done
		mov	ax, FCNT_BATCH
		call	FSDGenerateNotify	; destroys ax, bx, cx, dx
		jmp	processBlocks
done:
		popf
		.leave
		ret
FILEFLUSHCHANGENOTIFICATIONS		endp

;----------------------------------------------------------------

FileCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetDestinationDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the disk handle of the destination of a file operation

CALLED BY:	FSDCheckDestWritable, FS drivers.
PASS:		ds:dx	= path to file
		bx	= 0 if should see if path is a subdirectory of
			  a standard path. non-0 if shouldn't check.
		FSInfoResource not locked
RETURN:		carry clear if could get disk handle:
			bx	= disk handle or StandardPath, if path is
				  under standard path
			ds:dx	= path to file w/o drive specifier, and w/o
				  leading components if path was actually
				  under a standard directory. NOTE: This
				  will be absolute if any part of the passed
				  path was consumed to obtain the standard
				  path returned in BX. InitForPathEnum will
				  strip off the leading backslash for you, but
				  beware, if you don't call InitForPathEnum.
			ax	= destroyed
		else carry is set and
			ax	= ERROR_DRIVE_NOT_READY
				  ERROR_INVALID_DRIVE
				  ERROR_PATH_NOT_FOUND
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We keep the FSIR locked only for as long as we need it. A
		deadlock arises if one attempts to register a disk with 
		the FSIR locked (someone else can have diskRegisterSem down
		and attempt to lock the FSIR excl, while we would then be
		blocked on diskRegisterSem holding the FSIR shared...)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	On a system where std paths aren't enabled, this procedure
	will return the DISK HANDLE of the disk on which the geoworks
	tree resides.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetDestinationDisk	proc	far
		uses 	ds, si, di, es
		.enter
EC <		tst	{word}ss:[TPD_exclFSIRLocks]		>
EC <		ERROR_NZ	FSIR_MAY_NOT_BE_LOCKED		>
	;
	; See if the path is a network path. If so, we need to find an FSD
	; that'll accept it.
	; 
		mov	si, dx
if DBCS_PCGEOS
		cmp	{wchar}ds:[si], '\\'
		jne	notNetwork
		cmp	{wchar}ds:[si][2], '\\'
		LONG je	isNetwork
notNetwork:
else
		cmp	{word}ds:[si], '\\' or ('\\' shl 8)
		LONG je	isNetwork
endif
		
	;
	; See if a drive was specified.
	; 
		mov	di, dx			; record start of path in case
						;  we need to parse it into a
						;  std path.
		call	FileLockInfoSharedToES
		call	DriveLocateByName
		jc	invalidDrive
		
		tst	si
		jnz	driveSpecified		; => ds:dx points beyond drive
						;  specifier.
		call	FSDUnlockInfoShared
	;
	; No drive specified, so use disk handle from current path after
	; checking for standard path.
	; 
		push	ds
		LoadVarSeg	ds
		tst	ds:[loaderVars].KLV_stdDirPaths
		jz	checkPathBlockForStdPath

fetchCurPathDiskHandle:
		tst	bx		; check for std path?
		mov	bx, ss:[TPD_curPath]
		mov	bx, ds:[bx].HM_otherInfo
		pop	ds
		jnz	done		; no -- skip check
	;
	; See if the current disk handle, when combined with the specified
	; path, form a standard path.
	; 
		test	bx, DISK_IS_STD_PATH_MASK
		jnz	curPathIsStdPath

parseStdPath:
		call	checkStdPath
done:
		.leave
		ret

invalidDrive:
		call	FSDUnlockInfoShared
		mov	ax, ERROR_INVALID_DRIVE
		jmp	done

checkPathBlockForStdPath:
	;
	; Std paths aren't enabled, but we must convert the destination from
	; absolute to relative if the current path is actually within a
	; std directory.
	; 
	; Only do this if caller asked us to check for a std path.
	; XXX: IS THIS RIGHT?
	;
		tst	bx
		jnz	fetchCurPathDiskHandle
		
		call	lockCurPathToES		; saves bx, es, biffs ax
		tst	es:[FP_stdPath]
		call	unlockCurPath
		jz	fetchCurPathDiskHandle
		
		mov	ax, ds
		pop	ds
		push	ds
		mov	si, dx
		LocalCmpChar ds:[si], '\\'	; destination absolute?
		mov	ds, ax			; ds <- dgroup again
		jne	fetchCurPathDiskHandle	; no
		inc	dx			; yes -- make it relative
DBCS <		inc	dx						>
						; instead
		jmp	fetchCurPathDiskHandle

curPathIsStdPath:
	;
	; Current path is a standard path. Need to check the tail in the
	; path block to see if it's an actual standard path, or just something
	; under one. In the former case, we still need to call
	; FileParseStandardPath as the leading components of the destination
	; could put us in a different standard path.
	; 
		call	lockCurPathToES		; saves bx, es, biffs ax
		mov	di, es:[FP_path]
		tst	{char}es:[di]	; (clears carry)
		call	unlockCurPath
		jnz	done		; in dir below std path, so leading
					;  components of ds:dx can have no
					;  bearing
		mov	di, dx		; ds:di <- path to parse
		jmp	parseStdPath	; go for it...

	;----------------------------------------
	;
	;		DRIVE SPECIFIER
driveSpecified:
	;
	; First see if the path is under a standard directory, if the caller
	; has asked us to check.
	; 
		mov	al, es:[si].DSE_number	; fetch drive number
		call	FSDUnlockInfoShared

		tst	bx		; should we check for standard path?
		jnz	notStandardPath	; no -- skip this
		
		call	checkStdPath
		jnz	done		; => is std path.

notStandardPath:

		call	DiskRegisterDisk
		jnc	done			; bx is disk handle, ds:dx
						;  point beyond drive spec.
	;
	; Couldn't register the disk, so return carry (already) set and the
	; appropriate error code.
	; 
		mov	ax, ERROR_DRIVE_NOT_READY
		jmp	done

	;----------------------------------------
	;
	;		NETWORK PATH
isNetwork:
	;
	; Run through the list of FSD's contacting each one that's marked
	; as a network FSD until one returns a non-zero disk handle, or
	; carry set (indicating the path would be for it, but the path can't
	; actually be accessed).
	; 
		call	FileLockInfoSharedToES
		mov	si, offset FIH_fsdList - offset FSD_next
networkLoop:
		mov	si, es:[si].FSD_next	; advance to next
		tst	si			; out of FSDs?
		jz	networkPathNotFound	; yes => path invalid

		test	es:[si].FSD_flags, mask FSDF_NETWORK
		jz	networkLoop		; => not network FSD, so
						;  don't bother it.
	    ;
	    ; Ask the FSD if it claims ownership of the path.
	    ; 
		mov	di, DR_FS_CHECK_NET_PATH
		push	bp
		call	es:[si].FSD_strategy
		pop	bp
		jc	networkPathNotFound	; => path is the FSD's, but
						;  is invalid

	    ;
	    ; If non-zero disk handle is returned, we're happy
	    ; 
		tst	bx
		jz	networkLoop
		jmp	networkDone

networkPathNotFound:
		mov	ax, ERROR_PATH_NOT_FOUND
		stc
networkDone:
		call	FSDUnlockInfoShared
		jmp	done

	;--------------------
	; Pass:		nothing
	; Return:	bx, es saved on stack
	; 		es = locked FilePath block
	; 		bx = current path block
	; Destroyed:	ax
lockCurPathToES:
		pop	ax
		push	bx, es
		push	ax
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	es, ax
		retn
	;--------------------
	; Pass:		bx	= current path block
	; Return:	bx, es	= as saved by lockCurPathToES
	; Destroyed:	ax, flags preserved
unlockCurPath:
		call	MemUnlock
		pop	ax
		pop	bx, es
		jmp	ax

	;--------------------
	; Pass:		ds:di	= path to parse
	; 		ds:dx	= same
	; 		bx	= starting point (or 0 if none)
	; Return:	if "jne" branches:
	;		   bx	= StandardPath
	;		   ds:dx= tail (absolute if anything removed from
	;			  passed path to get to std path)
	;		if "je" branches:
	;		   ds:dx= untouched
	;		carry always clear
	; Destroyed:	nothing
	; 
checkStdPath:
		push	ax
		push	es
		segmov	es, ds		; es:di <- path to check
		call	FileParseStandardPathIfPathsEnabled
		pop	es		

		tst	ax		; is path a standard?
		jz	cspDone		; no
		mov_tr	bx, ax		; bx <- S.P.

	;
	; If we actually ate some of the path to get the standard path, we need
	; to make the tail absolute so InitForPathEnum doesn't hose itself.
	; Of course, this might hose other things...
	; 
		cmp	di, dx		; did we eat anything? (compare
					;  in this order so carry clear
					;  no matter what [di >= dx always])
		je	cspIsStdPath	; no -- dx set properly
SBCS <		lea	dx, ds:[di-1]	; ds:dx <- backslash at start of tail >
DBCS <		lea	dx, ds:[di-2]	; ds:dx <- backslash at start of tail >
cspIsStdPath:
		or	al, 1		; force JNE
cspDone:
		pop	ax
		retn
		
FileGetDestinationDisk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDCheckDestWritable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the destination of some file operation is writable.
		This determines only if the disk in question is write-protected
		(or unusable), not if the file/directory in question is
		marked read-only. Presumably DOS is competent enough to
		figure that out itself. We're just trying to avoid
		critical errors...

CALLED BY:	FileCreateDir, FileDeleteDir, FileCreate, FileDelete,
       		FileRename, FileSetAttributes, DiskFormat
PASS:		es:bx	= destination disk handle, as gotten from
			  FileGetDestinationDisk
		FSIR locked shared
RETURN:		carry set (ax = ERROR_WRITE_PROTECTED) if destination
			disk is write-protected
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDCheckDestWritable	proc	far
		.enter
if	FULL_EXECUTE_IN_PLACE
EC <		call	AssertDiskHandle				>
EC <		push	bx, si						>
EC <		movdw	bxsi, esbx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx, si						>
endif


		test	es:[bx].DD_flags, mask DF_WRITABLE
		jnz	done

assumeNotWritable::
	;
	; See if the drive is read-only, so there's no chance the user could
	; have made the disk writable.
	; 
		push	si
		mov	si, es:[bx].DD_drive
		test	es:[si].DSE_status, mask DES_READ_ONLY
		jnz	writeProtected
	;
	; If user wants to write the sucker, see if maybe s/he has un-
	; protected it.
	; 
		call	DiskReRegister
		test	es:[bx].DD_flags, mask DF_WRITABLE
		jnz	donePop
	;
	; Nope -- complain about write-protection.
	; 
writeProtected:
		; (carry cleared by test, and by DiskCheckWritable...)
		mov	ax, ERROR_WRITE_PROTECTED
		stc
donePop:
		pop	si
done:
		.leave
		ret
FSDCheckDestWritable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWPathOpOnPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an operation on a path after ensuring the destination
		disk is writable. Note that a path op is different from an
		alloc op in that path ops never allocate a file handle.

CALLED BY:	EXTERNAL
PASS:		ds:dx	= path on which the operation is to be performed
		ah	= FSPathOpFunction
		al	= ignored
RETURN:		carry set on error:
			ax	= error code
		carry clear on success
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileWPathOpOnPath	proc	far
		push	si
		mov	si, offset FileWPathOpInt
		call	FileOpOnPath
		pop	si
		ret
FileWPathOpOnPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRPathOpOnPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a read-only operation on a path.  Note that a
		path op is different from an alloc op in that path ops
		never allocate a file handle.

CALLED BY:	EXTERNAL

PASS:		ds:dx	= path on which the operation is to be performed
		ah	= FSPathOpFunction
		al	= ignored
RETURN:		carry set on error:
			ax	= error code
		carry clear on success
DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileRPathOpOnPath	proc far
		push	si
		mov	si, offset FileRPathOpInt
		call	FileOpOnPath
		pop	si
		ret
FileRPathOpOnPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWPathOpInt, FileRPathOpInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an operation on a path after ensuring the destination
		disk is writable (WPath). This does not deal with the
		current path or the path in question being within a
		logical/standard directory. The thread's current path
		is assumed to be a physical one.

CALLED BY:	FileWPathOpOnPath, FileRPathOpOnPath

PASS:		ds:dx	= path on which the operation is to be performed
		es	= FSIR locked shared
		si	= disk handle for disk on which that path resides
		di.high	= FSPathOpFunction
		di.low	= ignored
RETURN:		carry set on error:
			ax	= error code
		carry clear on success:
			registers as appropriate to function called
DESTROYED:	ax, bp, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileWPathOpInt	proc	near
		.enter

		push	bx
		mov	bx, si
		call	FSDCheckDestWritable
		pop	bx
		jc	done
		
FileRPathOpInt	label	near

		mov	ax, di		; ah <- FSPathOpFunction

		push	di
		mov	di, DR_FS_PATH_OP
		clr	al		; allow disk lock to be aborted
		call	DiskLockCallFSD
		pop	di
done:
		.leave
		ret
FileWPathOpInt	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpOnPathFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Far version of FileOpOnPath

CALLED BY:	(INTERNAL) FileResolveStandardPath, FileGetCurrentPathIDs
PASS:		ds:dx	= path on which to operate
		si:di	= virtual callback function
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FOOPF_frame	struct
    FOOPFF_passedBX	word
    FOOPFF_callback	fptr.far
FOOPF_frame	ends

FileOpOnPathFar	proc	far
		.enter
	;
	; Setup frame for our callCallback routine to use.
	; 
		push	si, di, bx
EC <		mov	bx, si						>
EC <		xchg	si, di						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		xchg	si, di						>
		mov	bx, sp
	;
	; Do it, babe.
	; 
		mov	si, offset callCallback
		call	FileOpOnPath
	;
	; Recover passed registers and boogie.
	; 
		pop	si, di, bx
		.leave
		ret

callCallback:
	;
	; DI we can trash anyway, and BX is saved by FileOpOnPathLow, so we're
	; golden.
	; 
		mov	di, bx
		mov	bx, ss:[di].FOOPFF_passedBX

FXIP<		mov	ss:[TPD_dataBX], bx				>
FXIP<		mov	ss:[TPD_dataAX], ax				>
FXIP<		movdw	bxax, ss:[di].FOOPFF_callback			>
FXIP<		call	ProcCallFixedOrMovable				>

NOFXIP<		call	ss:[di].FOOPFF_callback				>


		retn
FileOpOnPathFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpOnPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end function to do something to a file, dealing with
		logical paths.

CALLED BY:	FileWPathOpOnPath, FileRPathOpOnPath, FileAllocOpOnPath
PASS:		ds:dx	= path on which to operate
		si	= function in Filemisc to call for each physical
			  directory along the logical path to which ds:dx
			  refers. If this returns carry set, ax is expected
			  to be a FileError code.
		bx	= value to pass to si in bx

RETURN:		whatever si returned

DESTROYED:	depends on function called (nothing destroyed by this
		function itself)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpOnPath	proc	near
		push	es, di, si, bp, dx

		mov	di, ax		; save for callback routine

		push	bp
		inc	ss:[TPD_stackBot]
		mov	bp, ss:[TPD_stackBot]
		mov	{byte} ss:[bp].CP_linkCount, 0
		pop	bp
		
		call	FileOpOnPathLow

		dec	ss:[TPD_stackBot]
		
		pop	es, di, si, bp, dx
		ret

FileOpOnPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpOnPathLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine that can be called recursively to deal with
		links. 

CALLED BY:	FileOpOnPath

PASS:		ds:dx	= path on which to operate
		es	= FSIR locked, shared
		si	= function in Filemisc to call for each physical
			  directory along the logical path to which ds:dx
			  refers. If this returns carry set, ax is expected
			  to be a FileError code.

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/13/92   	pulled out from FileOpOnPath

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpOnPathLow	proc near

		push	bx

		clr	bx		; check for standard path, please
		call	FileGetDestinationDisk
		jc	done
		
		test	bx, DISK_IS_STD_PATH_MASK	; standard path?
		jnz	onPath
		
		call	callCallback
		jmp	afterCallback
onPath:
		push	cx
		mov	cx, TRUE
		call	InitForPathEnum
		pop	cx
		jc	done			;no paths at all (means no
						; finish required)
pathLoop:
	;
	; Advance to the next physical directory on the path.
	; 
		call	SetDirOnPath
		mov	ax, ERROR_FILE_NOT_FOUND
		jc	pathDone		;no more paths
	;
	; Try and perform the operation here.
	; 
		push	dx			; dx shouldn't change in FGDD
						;  (any drive would have been
						;  caught up above), but we're
						;  naturally cautious.
		mov	bx, 1			; don't check for std path
		call	FileGetDestinationDisk
		pop	dx
		call	callCallback
		jnc	pathDone
	;
	; Any error but these indicates the file exists but cannot be
	; operated on, so bail now.
	; 
		cmp	ax, ERROR_FILE_NOT_FOUND
		je	pathLoop
		cmp	ax, ERROR_PATH_NOT_FOUND
		je	pathLoop
		stc
pathDone:
		call	FinishWithPathEnum
afterCallback:
		jnc	done
		cmp	ax, ERROR_LINK_ENCOUNTERED
		je	followLink
		stc

done:
		pop	bx
		ret

callCallback:
		call	FileLockInfoSharedToES
		mov_tr	ax, si			; ax <- routine to call
		mov	si, bx			; si <- disk for path
		mov	bx, sp
		mov	bx, ss:[bx+2]		; bx <- as originally passed
		push	ax, dx
		call	ax
		pop	si, dx
		call	FSDUnlockInfoShared
		retn

followLink:
	;
	; A link was encountered, so follow it, and try again.
	;
		push	ds, dx, bx		; mem handle of link data
		call	FileGetLinkData
		jc	afterFollowLink

	; bx - disk handle of target,
	; ds:dx - path to target.

		push	cx
		mov	cx, bx
		call	PushToRoot
		pop	cx
		jc	afterFollowLink

	;
	; Increment the link count and bail if we seem to be in an
	; infinite loop.
	;

		push	bp
		mov	bp, ss:[TPD_stackBot]
		inc	{word} ss:[bp].CP_linkCount
		cmp	{word} ss:[bp].CP_linkCount, MAX_LINK_COUNT
		pop	bp
		jne	linkCountOK

		mov	ax, ERROR_TOO_MANY_LINKS
		stc
		jmp	afterFollowLink

linkCountOK:
		
	;
	; Now, try again with the new path.  Restore the path when done.
	;

		mov	bx, sp
		mov	bx, ss:[bx+6]		; bx <- as originally passed
		call	FileOpOnPathLow

		call	FilePopDir

afterFollowLink:

		pop	ds, dx, bx
		pushf
		call	MemFree
		popf

		jmp	done


FileOpOnPathLow	endp


FileCommon ends

;--------------------------------------------------------------------

FileSemiCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetLinkDataCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to deref the block of link data and
		restore the disk, if any

CALLED BY:	FileGetLinkData, FileReadLink

PASS:		^hbx - FSPathLinkData

RETURN:		bx - disk handle, or zero if none
		ds:dx - target path returned from DOS driver

DESTROYED:	ax,cx,si,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetLinkDataCommon	proc far
		.enter
	;
	; Dereference the block of link data (since the FSD was
	; supposed to leave it locked), and fetch the pathname
	;

		call	MemDerefDS
		lds	dx, ds:[FPLD_targetPath]

	;
	; If there's a saved disk, then restore it
	;
		clr	bx
		tst	ds:[FPLD_targetSavedDiskSize]
		jz	done
	;
	; Restore the saved disk handle
	;
		mov	si, offset FPLD_targetSavedDisk
		clr	cx
		call	DiskRestore
		mov_tr	bx, ax
		jc	mapError

done:
		.leave
		ret

mapError:
	;
	; Map the DiskRestoreError into a FileError
	; 
		mov	ax, ERROR_NETWORK_NOT_LOGGED_IN
		cmp	bx, DRE_NOT_ATTACHED_TO_SERVER
		je	haveCode
		mov	ax, ERROR_ACCESS_DENIED
		cmp	bx, DRE_PERMISSION_DENIED
		je	haveCode
		mov	ax, ERROR_DISK_UNAVAILABLE
haveCode:
		stc
		jmp	done


FileGetLinkDataCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetLinkData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the link data as returned by the FSD 

CALLED BY:	FileOpOnPathLow, SetCurPath

PASS:		bx - handle of (locked) FSPathLinkData block

RETURN:		if error
			ax - FileError
			bx - destroyed
		else
			ds:dx - path of link's target
			bx    - disk handle of target

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	The CALLER must free the memory block in BX after the data at
	ds:dx is no longer needed.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetLinkData	proc far
		uses	si, cx

		.enter

	;
	; Deref the block, and restore the disk, if any
	;

		call	FileGetLinkDataCommon
		jc	done
		tst	bx
		jnz	done

	;
	; There was no saved disk, so use  FileGetDestinationDisk
	; to get a disk handle from the path
	;

		call	FileGetDestinationDisk

done:
		.leave
		ret

FileGetLinkData	endp

FileSemiCommon	ends
