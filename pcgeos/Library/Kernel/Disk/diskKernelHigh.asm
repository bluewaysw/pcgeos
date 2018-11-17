COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Disk Tracking -- Kernel-level Interface
FILE:		diskKernelHigh.asm

AUTHOR:		Adam de Boor, Feb 18, 1990

ROUTINES:
	Name			Description
	----			-----------
    EXT DiskLockFar		Make sure the desired disk is in the drive.

    EXT DiskLock		Make sure the desired disk is in the drive.

    INT DiskLockExcl		Similar to DiskLock, but provides exclusive
				access to the drive.

    INT DiskLockExclFar		Similar to DiskLock, but provides exclusive
				access to the drive.

    INT DiskLockCommon		Common code to validate a disk in a drive
				after the drive has been locked either
				shared (for the disk) or exclusive

    EXT DiskCheckWritable	See if a volume is writable.

    EXT DiskUnlockFar		Unlock the drive associated with the passed
				file or disk handle. The drive must have
				been locked by a call to DiskLock.

    EXT DiskUnlock		Unlock the drive associated with the passed
				file or disk handle. The drive must have
				been locked by a call to DiskLock.

    INT DiskUnlockExcl		Release exclusive access to a disk and its
				drive.

    INT DiskUnlockExclFar	Release exclusive access to a disk and its
				drive.

    INT DiskUnlockCommon	Common code required before both shared &
				exclusive disk unlock operatiions.

    EXT DiskCallFSD		Call the FSD associated with the passed
				disk handle.

    INT DiskCallFSDNoLock	Call the FSD for a disk when the FSIR is
				already locked shared.

    EXT DiskLockCallFSD		Call the FSD associated with the passed
				disk handle after ensuring the disk is in
				the drive.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/18/90		Initial revision


DESCRIPTION:
	Functions exported by the Disk module to the rest of the kernel.
		

	$Id: diskKernelHigh.asm,v 1.1 97/04/05 01:11:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskLock

DESCRIPTION:	Make sure the desired disk is in the drive.

CALLED BY:	EXTERNAL

PASS:		es:si - DiskDesc (es = FSInfoResource locked shared)
		al	= FILE_NO_ERRORS bit set if disk lock may not be aborted
			  by the user.

RETURN:		es:bp	= FSDriver to call for the disk

		carry clear if successful
		the drive containing the disk is locked shared for the
			passed disk.
		the shared lock is released by calling DiskUnlock

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@

DiskLockFar	proc	far
	call	DiskLock
	ret
DiskLockFar	endp
	public	DiskLockFar

DiskLock	proc	near
		uses	ax, bx, di
		.enter
	;
	; Make sure the disk hasn't been marked stale, aborting if it has.
	; 
		test	es:[si].DD_flags, mask DF_STALE
		jnz	failDiskNotLocked
	;
	; First lock the drive shared.
	; 
		mov	bp, es:[si].DD_drive
		call	DriveLockShared
		jc	done
	;
	; Now fight for the right to lock our disk handle into the drive.
	; 
		LockModule	si, es, [bp].DSE_diskLock, TRASH_AX_BX
	
		call	DiskLockCommon
		jc	fail
done:
		.leave
		ret
fail:
		call	DiskUnlock
failDiskNotLocked:
		stc
		jmp	done
DiskLock	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskLockCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to validate a disk in a drive after the drive
		has been locked either shared (for the disk) or exclusive

CALLED BY:	DiskLock, DiskLockExcl
PASS:		es:si	= DiskDesc
		es:bp	= DriveStatusEntry
		al	= FILE_NO_ERRORS set if lock may not be aborted.
		es	= FSInfoResource locked shared
RETURN:		carry set if couldn't lock the disk in the drive (drive
		    remains locked, according to the caller's wisdom)
		es:bp	= FSDriver to call
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
	12/27/00 ayuen: This routine used to grab/release DSE_lockSem around
	calls to DR_FS_DISK_LOCK.  However, this could cause deadlock with
	some DOS IFS drivers between DSE_lockSem and DDPD_aliasLock on a
	one-floppy-drive machine in the following scenario:
	- Thread 1 locks a disk in a floppy drive on a one-drive machine.  It
	  grabs DSE_lockSem, calls DR_FS_DISK_LOCK which grabs DDPD_aliasLock,
	  then releases DSE_lockSem.
	- Thread 2 tries to lock the same disk.  It grabs DSE_lockSem, calls
	  DR_FS_DISK_LOCK which tries to grab DDPD_aliasLock, and blocks.
	- Thread 1 tries to lock the same disk a second time.  It tries to
	  grab DSE_lockSem, and blocks.
	- Deadlock.

	Usually a thread doesn't lock the disk twice, but some VMem code
	bypasses the file system and does this for optimization purpose.  (See
	VMAddExtraDiskLock / VMReleaseExtraDiskLock.)

	To solve this problem, this routine is changed such that it no longer
	grabs/releases DSE_lockSem, and multiple threads can be calling
	DR_FS_DISK_LOCK at the same time.  It is then up to the IFS driver to
	decide whether or not, or when, to enforce mutual-exclusion within its
	routine, optionally using DSE_lockSem.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskLockCommon proc	far
		.enter
	;
	; Set up registers more to our liking...
	; 
		mov	di, bp
		mov	bp, es:[bp].DSE_fsd
	;
	; If the disk is always valid, don't call the FSD.
	; 
		test	es:[si].DD_flags, mask DF_ALWAYS_VALID
		jnz	setDisk		; (carry cleared by test)
	;
	; Call the FSD to lock the disk into the drive.
	;
		mov	di, DR_FS_DISK_LOCK
		push	bp			; preserve FSDriver
		call	es:[bp].FSD_strategy
		pop	bp			; es:bp - FSDriver
		mov	di, es:[si].DD_drive
		jc	exit
	;
	; Record the disk just locked as the last disk known to be in the
	; drive, storing the low word of the system counter as the last-access
	; time. This will also be set when the drive is unlocked, but doing
	; so allows another thread that was blocked on the DSE_lockSem (if
	; the IFS driver enforces mutual-exclusion) to continue quickly
	; without also checking the disk...
	;
setDisk:
		mov	es:[di].DSE_lastDisk, si
		
		call	TimerGetCount
		mov	es:[di].DSE_lastAccess, ax
		
	;
	; Save off the time of the lock so that anyone interested can
	; find when the last lock happened.  Very handy when
	; determining whether or not to suspend a battery-powered
	; machine.
	;
		push	ds
		LoadVarSeg ds
		movdw	ds:[diskLastAccess], bxax
		pop	ds

		clc
exit:

		.leave
		ret
DiskLockCommon endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskCheckWritable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a volume is writable.

CALLED BY:	EXTERNAL
PASS:		bx	= disk handle to check
RETURN:		carry set if disk is writable
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskCheckWritable proc	near
		uses	es
		.enter
		call	FileLockInfoSharedToES
EC <		call	AssertDiskHandle				>

   		test	es:[bx].DD_flags, mask DF_WRITABLE
		jz	done
		stc
done:
		call	FSDUnlockInfoShared
		.leave
		ret
DiskCheckWritable endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the drive associated with the passed file or disk
		handle. The drive must have been locked by a call
		to DiskLock.

CALLED BY:	EXTERNAL
PASS:		es:si	= DiskDesc
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskUnlockFar	proc	far			; for KLib
		call	DiskUnlock
		ret
DiskUnlockFar	endp

DiskUnlock	proc	near
		uses	ax, bx
		.enter
		pushf
		call	DiskUnlockCommon
	;
	; Release the disk exclusive for this drive.
	; 
		UnlockModule	si, es, [bx].DSE_diskLock
	;
	; Release the shared access to the drive itself.
	; 
		call	DriveUnlockShared
	;
	; All done.
	; 
		popf
		.leave
		ret
DiskUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskUnlockCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code required before both shared & exclusive disk
		unlock operatiions.

CALLED BY:	DiskUnlock, DiskUnlockExcl
PASS:		es:si	= DiskDesc
RETURN:		es:bx	= DriveStatusEntry for associated drive
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskUnlockCommon proc	far
		uses	di, bp
		.enter
	;
	; Tell the FSD the disk is being unlocked, but only if we told it we
	; were locking it before.
	;
		test	es:[si].DD_flags, mask DF_ALWAYS_VALID
		jnz	setCount

		mov	bx, es:[si].DD_drive
		mov	bx, es:[bx].DSE_fsd
		mov	di, DR_FS_DISK_UNLOCK
		call	es:[bx].FSD_strategy
setCount:
	;
	; Record the time of this unlock. The disk handle was already stored
	; when the disk was validated.
	; 
		call	TimerGetCount
		mov	bx, es:[si].DD_drive
		mov	es:[bx].DSE_lastAccess, ax
		.leave
		ret
DiskUnlockCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskCallFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the FSD associated with the passed disk handle.

CALLED BY:	EXTERNAL
PASS:		si	= disk handle
		di	= FSFunction
RETURN:		whatever FSD returns
DESTROYED:	bp, si, di (at least)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskCallFSD	proc	far
		uses	es
		.enter
		call	FileLockInfoSharedToES
		call	DiskCallFSDNoLock
		call	FSDUnlockInfoShared
		.leave
		ret
DiskCallFSD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskCallFSDNoLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the FSD for a disk when the FSIR is already locked
		shared.

CALLED BY:	DiskCallFSD, FileHandleOp
PASS:		es	= FSIR locked shared
		si	= disk handle
		di	= function in FSD to call
RETURN:		?
DESTROYED:	bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskCallFSDNoLock proc	near
		.enter
EC <		call	AssertESIsSharedFSIR				>
	;XXX: lock the drive here?
		tst	si		; no disk handle?
		jz	usePrimary	; => device, so use primary FSD

EC <		call	AssertDiskHandleSI				>

		mov	bp, es:[si].DD_drive
		mov	bp, es:[bp].DSE_fsd
callFSD:
		call	es:[bp].FSD_strategy
		.leave
		ret
		
usePrimary:
		mov	bp, es:[FIH_primaryFSD]
		jmp	callFSD
DiskCallFSDNoLock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskLockCallFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the FSD associated with the passed disk handle after
		ensuring the disk is in the drive.

CALLED BY:	EXTERNAL
PASS:		si	= disk handle
		di	= FSFunction
		es	= locked FSInfoResource
		al	= FILE_NO_ERRORS bit set if disk lock may not be
			  aborted.
RETURN:		carry set if lock aborted,
			ax	= ERROR_DISK_UNAVAILABLE
		else whatever the FSD returns.
DESTROYED:	bp, si, di (at least)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskLockCallFSD proc	far
		.enter
		push	si		; save disk handle for drive unlock

		tst	si		; 0 disk handle => no lock, just
		jz	usePrimary	;  call primary FSD

EC <		call	AssertDiskHandleSI				>

		call	DiskLock
		jc	bailOut

	;
	; Special case for FilePos, clear FILE_NO_ERRORS now
	;
		cmp	di, DR_FS_HANDLE_OP
		jnz	notPos
		cmp	ah, FSHOF_POSITION
		jnz	notPos
		and	al, not FILE_NO_ERRORS
notPos:
	;
	; Now call the intended function.
	; 
		call	es:[bp].FSD_strategy

	;
	; Unlock the disk.
	; 
		pop	si
		call	DiskUnlock
		
done:
		.leave
		ret

bailOut:
	;
	; (The silly) User aborted the lock, so return an error
	; to our caller. Carry is already set.
	; 
		pop	si
		mov	ax, ERROR_DISK_UNAVAILABLE
		jmp	done

usePrimary:
		mov	bp, es:[FIH_primaryFSD]
		call	es:[bp].FSD_strategy
		pop	si
		jmp	done
DiskLockCallFSD endp

Filemisc segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskLockExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Similar to DiskLock, but provides exclusive access
		to the drive.

CALLED BY:	FSDCheckDestWritable
PASS:		es:si	= DiskDesc to validate
		al	= FILE_NO_ERRORS bit set if disk lock may not be
			  aborted by the user.
RETURN:		carry set if couldn't do it (drive not locked in this case)
		es:bp	= FSDriver to call for the disk
		
		drive locked for exclusive access. it can be unlocked by
			calling DiskUnlockExcl
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskLockExcl proc	far
		uses	ax, bx, di
		.enter
		test	es:[si].DD_flags, mask DF_STALE
		jnz	failDiskNotLocked
	;
	; Lock the drive exclusive.
	; 
		mov	bp, es:[si].DD_drive		; bp <- DSE
		xchg	si, bp			; si <- DSE, bp <- DD
		call	DriveLockExclFar
		xchg	si, bp			; si <- DD, bp <- DSE
	;
	; Make sure the disk is in the drive.
	; 
		call	DiskLockCommon
		jc	fail
done:
		.leave
		ret
fail:
	;
	; User aborted disk lock, so need only unlock the drive, not the disk...
	; 
		push	si
		mov	si, es:[si].DD_drive
		call	DriveUnlockExclFar
		pop	si
failDiskNotLocked:
		stc
		jmp	done
DiskLockExcl endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskUnlockExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive access to a disk and its drive.

CALLED BY:	FSDCheckDestWritable
PASS:		es:si	= DiskDesc locked with DiskLockExcl
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskUnlockExcl	proc	far
		uses	ax, bx, si
		.enter
		pushf
		call	DiskUnlockCommon	; es:bx <- DSE
	;
	; Release the exclusive lock on the drive.
	; 
		mov	si, bx			; es:si <- DSE
		call	DriveUnlockExclFar
		popf
		.leave
		ret
DiskUnlockExcl	endp

Filemisc ends
