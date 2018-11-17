COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel -- High-level disk module routines
FILE:		diskHigh.asm

AUTHOR:		Adam de Boor, Feb 14, 1990

ROUTINES:
	Name			Description
	----			-----------
    INT DiskMapStdPathFar	Map a StandardPath constant to a real disk
				handle so apps don't have to worry about
				passing a StandardPath constant to the Disk
				routines.

    INT DiskMapStdPath		Map a StandardPath constant to a real disk
				handle so apps don't have to worry about
				passing a StandardPath constant to the Disk
				routines.

    INT DiskRegisterSetup	Set up for a DiskRegisterDisk or
				DiskReRegister

    INT DiskRegisterTakeDown	Finish up after registering/re-registering
				a disk.

    INT DiskRegisterCommon	Common code for DiskRegisterDiskSilently,
				DiskRegisterDisk

    GLB DiskAllocAndInit	Allocate a new disk handle and initialize
				it.

    GLB DiskRegisterDiskSilently Registers a disk with the system but does
				not put up the association dialog box if a
				volume name is generated.

    GLB DiskRegisterDisk	Routine for registering a disk with the
				system.

    GLB DiskGetDrive		Given a disk handle, returns the drive in
				which the disk was registered.

    GLB DiskGetVolumeName	Given a disk handle, copies out the volume
				name.

    GLB DiskFind		Given a volume name, searches the list of
				registered disks to find one that has the
				name.

    INT CheckVolumeNameMatch	Utility routine used by DiskFind to compare
				the sought volume name against that for the
				handle, dealing with space-padding and so
				forth.

    INT DiskReRegister		Re-register a disk to see if its name or
				write-protect status has changed.

    INT DiskReRegisterInt	Internals of DiskReRegister after all
				synchronization points have been snagged.

    GLB DiskCheckWritableFar	See if a volume is writable

    GLB DiskCheckInUse		Determine if a disk handle is actively
				in-use, either by an open file or by a
				thread having a directory on the disk in
				its directory stack.

    INT DIU?_fileCallback	Callback routine to determine if a file is
				open to a disk.

    INT DIU?_pathCallback	Callback routine to determine if a path in
				a thread's directory stack is on a
				particular disk.

    GLB DiskCheckUnnamed	See if a disk handle refers to an unnamed
				disk (i.e. one that has no user-supplied
				volume name)

    GLB DiskForEach		Run through the list of registered disks,
				calling a callback routine for each one
				until it says stop, or we run out of disks.

    GLB DiskSave		Save information that will allow a disk
				handle to be restored when the caller is
				restoring itself from state after a
				shutdown.

    GLB DiskRestore		Restore a saved disk handle for the caller.

    INT DiskUnlockInfoAndCallFSD Utility routine employed by DiskFormat and
				DiskCopy to call the strategy routine of an
				FSD given the drive descriptor, but only
				after releasing a shared lock on the
				FSInfoResource

    GLB DiskFormat		Formats the disk in the specified drive.

    GLB DiskCopy		Copies the contents of the source disk to
				the destination disk, prompting for them as
				necessary.

    INT DiskVolumeOp		Utility routine for the various
				Disk*Volume* functions to call the FSD
				bound to a disk

    GLB DiskGetVolumeFreeSpace	return free space on volume

    GLB DiskGetVolumeInfo	Get information about a volume.

    GLB DiskSetVolumeName	Set the name of a volume

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/14/90		Initial revision


DESCRIPTION:
	More specific notes can be found in the routine headers.

		
	$Id: diskHigh.asm,v 1.1 97/04/05 01:11:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskMapStdPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a StandardPath constant to a real disk handle so
		apps don't have to worry about passing a StandardPath
		constant to the Disk routines.

CALLED BY:	INTERNAL
PASS:		bx	= disk handle/StandardPath to check
RETURN:		bx	= real disk handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskMapStdPath	proc	far
		uses	ds
		.enter
		test	bx, DISK_IS_STD_PATH_MASK
		jz	done
		LoadVarSeg	ds
		mov	bx, ds:[topLevelDiskHandle]
done:
		.leave
		ret
DiskMapStdPath	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskGetDrive

DESCRIPTION:	Given a disk handle, returns the drive in which the disk
		was registered.

CALLED BY:	GLOBAL (Desktop)

PASS:		bx - disk handle

RETURN:		al - 0 based drive number

DESTROYED:	ah

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	ardeb	7/16/91		Renamed & changed to use FSIR

-------------------------------------------------------------------------------@

DiskGetDrive	proc	far
		uses	es, bx
		.enter
		call	DiskMapStdPath
		call	FileLockInfoSharedToES
		mov	bx, es:[bx].DD_drive
		mov	al, es:[bx].DSE_number
		call	FSDUnlockInfoShared
		.leave
		ret
DiskGetDrive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskCheckWritableFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a volume is writable

CALLED BY:	GLOBAL
PASS:		bx	= disk handle to check
RETURN:		carry set if disk is writable
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskCheckWritableFar proc	far
		uses	bx
		.enter
		call	DiskMapStdPath
		call	DiskCheckWritable
		.leave
		ret
DiskCheckWritableFar endp
		public	DiskCheckWritableFar



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskCheckUnnamed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a disk handle refers to an unnamed disk (i.e. one
		that has no user-supplied volume name)

CALLED BY:	GLOBAL
PASS:		bx	= file or disk handle
RETURN:		carry set if disk is unnamed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskCheckUnnamed proc	far
		uses	es, bx
		.enter
		call	DiskMapStdPath
		call	FileLockInfoSharedToES
EC <		call	AssertDiskHandle				>
		test	es:[bx].DD_flags, mask DF_NAMELESS
		jz	done		; (carry cleared by test)
		stc
done:
		call	FSDUnlockInfoShared
		.leave
		ret
DiskCheckUnnamed endp

;-------------------------------------------------

FileCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskRegisterSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up for a DiskRegisterDisk or DiskReRegister

CALLED BY:	DiskRegisterCommon, DiskReRegister
PASS:		al	= 0-based drive number
RETURN:		carry set on error:
			drive doesn't exist
			drive is busy
		carry clear on success:
			ds:si	= DriveStatusEntry
			es	= FSInfoResource, too
DESTROYED:	bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The caller shouldn't have any locks on the FSIR before calling
this routine.  However, this cannot be asserted using EC code, because
when GEOS is booting, LoadFSDriver calls FSDSInit, which registers a
disk, and thus would crash on startup...
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskRegisterSetup proc	near
		uses	ax
		.enter

	;
	; Gain exclusive access to fsdTemplateDisk.
	; 
		LoadVarSeg	ds, si
		PSem	ds, diskRegisterSem
	;
	; Lock the FSIR for shared access
	; 
		push	ax
		call	FSDLockInfoShared
		mov	es, ax			; es <- FSIR for FSD consistency
		mov	ds, ax			; ds <- FSIR for efficiency
		pop	ax
	;
	; Find the drive descriptor, now we've got the FSIR.
	; 
		call	DriveLocateByNumber
		jc	done			; => drive doesn't exist
	;
	; Grab the drive exclusive and clear the BUSY flag, since we won't
	; be using the exclusive for long. This prevents other things from
	; returning ERROR_DISK_UNAVAILABLE just because we're registering
	; a disk in the drive. -- ardeb 9/2/93
	; 
		call	DriveLockExclNoBusy
		clc
done:

		.leave
		ret
DiskRegisterSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskRegisterCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for
		DiskRegisterDiskSilently, DiskRegisterDisk
CALLED BY:	See above
PASS:		al	= 0-based drive number
		ah	= FSDNamelessAction
RETURN:		bx	= disk handle if carry clear
			= 0 if carry set (disk couldn't be registered)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskRegisterCommon	proc near
		uses	es, si, bp, ax, ds, di, cx, dx
		.enter
		clr	bx		; in case setup fails...
		call	DiskRegisterSetup
		jc	unlockFSIR

	;
	; Contact the drive's FSD to fetch the ID for the disk currently
	; in the drive.
	; 
		push	ax		; save FSDNamelessAction
		mov	di, DR_FS_DISK_ID
		mov	bp, ds:[si].DSE_fsd
		push	bp		; save FSDriver
		call	ds:[bp].FSD_strategy
		pop	bp		
		mov	bx, 0			; assume failure
		jc	fail

		mov	bx, offset FIH_diskList - offset DD_next
diskLoop:
		mov	di, bx			;DI <- previous disk in chain
		mov	bx, ds:[bx].DD_next
		tst	bx
		jz	notFound
		
		cmp	ds:[bx].DD_id.low, dx	; low ID word matches?
		jne	diskLoop		; nope
		cmp	ds:[bx].DD_id.high, cx	; high ID word matches?
		jne	diskLoop		; nope
		cmp	ds:[bx].DD_drive, si	; same drive?
		je	found			; got it

;	0:0 is the general ID we use for unremovable media - don't
;	re-use that, ever.

		tstdw	cxdx
		jz	diskLoop
	;
	; If the DiskDesc is STALE then resurrect it (since the ID's match)
	;
		test	ds:[bx].DD_flags, mask DF_STALE
		jz	diskLoop
		tst	ds:[bx].DD_drive
		jnz	diskLoop
	;
	; We are resurrecting a pre-owned DiskDesc structure. We need to 
	; re-initilize it, because the volume name could have changed since
	; the last time the disk was in the drive.
	;

	; Unlink the DiskDesc from the chain (it'll be linked in again by
	; InitDiskDesc).
	;
	; DS:DI <- previous DiskDesc in chain
	; DS:BX <- DiskDesc to re-use

		push	ds:[bx].DD_next	;
		pop	ds:[di].DD_next	;

		mov	di, bx		;DS:DI <- ptr to DiskDesc to re-use
		pop	bx		;Remove the FSDNamelessAction
		mov	bh, FNA_IGNORE	;Don't generate a new name
		call	InitDiskDesc
		jmp	unlockFSIR
found:		
	;
	; Better re-initialize the flags value so that the read-only
	; status will be accurately recorded, as the disk's state may
	; have changed since it was last registered. -Don 12/27/93
	;
	; Grab new DF_WRITABLE flag only, preserve everything else
	; - brianc 4/1/94
	;
	; Added to 20X - brianc 4/19/94
	;
	;	al - new flags
	;
		andnf	ds:[bx].DD_flags, not mask DF_WRITABLE
		andnf	al, mask DF_WRITABLE
		ornf	ds:[bx].DD_flags, al
		clc
fail:
		pop	ax
	;
	; no longer need the drive locked exclusive.
	; 
		call	DriveUnlockExclFar
unlockFSIR:
		call	FSDUnlockInfoShared

		LoadVarSeg	ds, si
		VSem	ds, diskRegisterSem	; preserves carry
		.leave
		ret

notFound:
		pop	bx
		call	DiskAllocAndInit
		jmp	unlockFSIR
DiskRegisterCommon	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskRegisterDisk

DESCRIPTION:	Routine for registering a disk with the system.

CALLED BY:	GLOBAL ()

PASS:		al - drive number

RETURN:		carry clear if successful
			bx - disk handle
		carry set if error:
			bx = 0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

DiskRegisterDisk	proc	far
	uses	ax
	.enter
if DO_NOT_ANNOUNCE_UNNAMED_DISKS
	mov	ah, FNA_SILENT		; register but don't tell user name
else
	mov	ah, FNA_ANNOUNCE	; register & tell user if nameless
endif
	call	DiskRegisterCommon
	.leave
	ret
DiskRegisterDisk	endp
COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskRegisterDiskSilently

DESCRIPTION:	Registers a disk with the system but does not put up
		the association dialog box if a volume name is generated.

CALLED BY:	GLOBAL

PASS:		al - 0 based drive number

RETURN:		carry clear if successful
			bx - disk handle
		carry set if error:
			bx = 0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

DiskRegisterDiskSilently	proc	far
	uses	ax
	.enter
	mov	ah, FNA_SILENT		; register but don't tell user if
					;  nameless
	call	DiskRegisterCommon
	.leave
	ret
DiskRegisterDiskSilently	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskGetVolumeName

DESCRIPTION:	Given a disk handle, copies out the volume name.

CALLED BY:	GLOBAL (Desktop)

PASS:		bx - disk handle
		es:di - buffer

RETURN:		es:di - pointer to null terminated volume name without any
			trailing spaces (must have VOLUME_NAME_LENGTH+1
			chars)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	ardeb	7/16/91		Renamed & changed to use FSIR

-------------------------------------------------------------------------------@

DiskGetVolumeName	proc	far
		call	PushAllFar
;EC <		call	ECCheckDirectionFlag				>
		call	DiskMapStdPath
if	FULL_EXECUTE_IN_PLACE
EC<		push	bx, si						>
EC<		movdw	bxsi, esdi					>
EC<		call	ECAssertValidTrueFarPointerXIP			>
EC<		pop	bx, si						>
endif

	;
	; Lock down the FSIR shared so we can get to the disk descriptor.
	; 
		lea	si, [bx].DD_volumeLabel
		call	FSDLockInfoShared
		mov	ds, ax
	;
	; Copy all the characters in.
	; 
		mov	cx, VOLUME_NAME_LENGTH
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>
		
	;
	; null terminate, nuking any trailing padding spaces
	;
		mov	cx, MSDOS_VOLUME_LABEL_LENGTH
		std				; look backwards
		LocalPrevChar esdi		; ...went one beyond the end
		LocalLoadChar ax, ' '		; ...find first non-space >
SBCS <		repe	scasb						>
DBCS <		repe	scasw						>
SBCS <		mov	{byte}es:[di][2], 0	; di one less than first non->
DBCS <		mov	{wchar}es:[di][4], 0	; di one less than first non->
						;  space, so offset by 2 to biff
						;  the first space (or null-
						;  terminate the whole thing if
						;  exactly VOLUME_NAME_LENGTH
						;  bytes long)
		cld				; look forwards
	;
	; Release the FSIR again.
	; 
		call	FSDUnlockInfoShared

		call	PopAllFar
		ret
DiskGetVolumeName	endp

FileCommon ends

;--------------------------------------------------------------

FileSemiCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save information that will allow a disk handle to be
		restored when the caller is restoring itself from state
		after a shutdown.

CALLED BY:	GLOBAL
PASS:		bx	= disk handle to save
		es:di	= buffer for data (which is opaque to you) that
			  allows the handle to be restored.
		cx	= size of the buffer
RETURN:		carry clear if handle saved ok:
			cx	= actual number of bytes used in the passed
				  buffer
		carry set if handle couldn't be saved:
			cx	= number of bytes needed to save the disk.
				  This is 0 if the disk handle cannot be
				  saved for some reason (e.g. it refers to
				  a network drive that no longer exists)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Lock FSIR
		figure length of drive name, with null & colon
		if drive name + size FSSavedDisk <= CX:
		    copy in FSSD_name, FSSD_flags, FSSD_id
		    lock driver core block
		    copy in FSSD_ifsName
		    unlock driver core block
		    set FSSD_private to after drive name null
		    copy in drive name
		    append colon
		    reduce CX by FSSD_private and advance si by FSSD_private
		    call DR_FS_DISK_SAVE
		    add FSSD_private to cx, leaving carry untouched
		else
		    call DR_FS_DISK_SAVE(cx = 0)
		    add drive name + size FSSavedDisk to returned CX
		    set carry
		fi
		unlock FSIR
		    
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskSave	proc	far
		uses	ds, di, ax, si, bp, dx
		.enter
if	FULL_EXECUTE_IN_PLACE
EC<	jcxz	noSize						>
EC<	push	bx, si						>
EC<	movdw	bxsi, esdi					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
EC<noSize:
endif

	;
	; See if the passed disk handle is actually a StandardPath
	; 
		test	bx, DISK_IS_STD_PATH_MASK
		jz	isDiskHandle
	;
	; We need three bytes for a standard path:
	; 	- a 0 byte for the start of FSSD_name
	; 	- a word to hold the StandardPath
	; 
		cmp	cx, size FSSavedStdPath
		mov	cx, size FSSavedStdPath	; signal amount needed, in
						;  case not enough present...
		jb	exitJmp			; => not enough, so return w/
						;  carry set
		mov	es:[di].FSSSP_signature, 0
		mov	es:[di].FSSSP_stdPath, bx
exitJmp:
		jmp	exit

isDiskHandle:
	;
	; Lock the FSIR shared, as we won't be modifying it, but we do need
	; its information.
	; 
		call	FSDLockInfoShared
		mov	ds, ax
	;
	; Figure how long the drive name is, including its null terminator and
	; the colon we need to stick at its end.
	; 
		push	es, cx, di
		mov	es, ax
EC <		call	AssertDiskHandle				>

   		mov	di, ds:[bx].DD_drive
		mov	cx, -1
SBCS <		clr	al						>
DBCS <		clr	ax						>
		add	di, offset DSE_name
SBCS <		repne	scasb						>
DBCS <		repne	scasw						>
		neg	cx		; cx <- length (name) + null + colon
DBCS <		shl	cx, 1		; cx <- size (name) + null + colon >
	;
	; Add that length to the overall size of an FSSavedDisk structure
	; 
		add	cx, size FSSavedDisk
		mov_tr	ax, cx
		pop	es, cx, di
	;
	; Do we have enough room in the passed buffer to store our part of
	; the information?
	; 
		cmp	ax, cx
		LONG ja	noRoomNoRoom
	;
	; Yes. Point FSSD_private after all our stuff. This also lets us
	; keep the length of the drive name in a handy place...
	; 
		mov	es:[di].FSSD_private, ax
	;
	; Save the disk flags, so we know whether to check the ID of the disk
	; in the drive on restore.
	; 
		mov	al, ds:[bx].DD_flags
		mov	es:[di].FSSD_flags, al
		mov	al, ds:[bx].DD_media
		mov	es:[di].FSSD_media, al
	;
	; Save the 32-bit disk ID for similar reasons.
	; 
		mov	ax, ds:[bx].DD_id.low
		mov	es:[di].FSSD_id.low, ax
		mov	ax, ds:[bx].DD_id.high
		mov	es:[di].FSSD_id.high, ax
	;
	; Copy the volume label in, so we can prompt the user gracefully
	; on restart.
	; 
		push	cx, di
		lea	si, ds:[bx].DD_volumeLabel		
		add	di, offset FSSD_name
SBCS <		mov	cx, size FSSD_name-1	; includes room for null-term..>
DBCS <		mov	cx, length FSSD_name-1	; includes room for null-term..>
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>

SBCS <		clr	al		; null-terminate the beast	>
DBCS <		clr	ax		; null-terminate the beast	>
		LocalPutChar esdi, ax
	;
	; Now get the permanent name of the associated FSD, so if the drive
	; isn't defined when we restore this, we can at least figure who to
	; call to restore the thing.
	;
	; If the FSD is the primary, place a null byte at the start of the
	; name so we know to automatically use the primary on restore, rather
	; than looking for a particular driver. This allows disk handles to
	; be saved to the .ini file and the user to upgrade to a different DOS
	; without those disk handles suddenly becoming invalid.
	; 
		mov	di, ds:[bx].DD_drive
		mov	di, ds:[di].DSE_fsd
		mov	ax, ds:[di].FSD_handle
		cmp	di, ds:[FIH_primaryFSD]
		pop	di
		mov	es:[di].FSSD_ifsName[0], 0	; assume is primary
		je	copyDriveName

		push	bx, ds, di
		mov_tr	bx, ax
		call	MemLock
		mov	ds, ax
		mov	si, offset GH_geodeName
		mov	cx, size GH_geodeName
		add	di, offset FSSD_ifsName
		rep	movsb
		call	MemUnlock
		pop	bx, ds, di		
copyDriveName:
	;
	; Now copy the drive name in, appending a colon to it so
	; DriveLocateByName is happy, and we prompt the user with something
	; with which they're familiar upon restore.
	; 
		mov	si, ds:[bx].DD_drive
		add	si, offset DSE_name
		mov	cx, es:[di].FSSD_private
		push	di
		add	di, offset FSSD_driveName
SBCS <		sub	cx, size FSSavedDisk+2				>
DBCS <		sub	cx, size FSSavedDisk+2*(size wchar)		>
		rep	movsb
SBCS <		mov	ax, ':' or (0 shl 8)				>
DBCS <		mov	ax, ':'						>
		stosw
DBCS <		clr	ax						>
DBCS <		stosw							>
		pop	si
		pop	cx
	;
	; Point es:dx to the storage space for the FSD, and reduce CX by the
	; amount we've used.
	; 
		mov	dx, es:[si].FSSD_private
		sub	cx, dx
		add	dx, si
	;
	; Now call the FSD to have it store what it needs.
	; 
		mov	di, DR_FS_DISK_SAVE
		mov	bp, ds:[bx].DD_drive
		mov	bp, ds:[bp].DSE_fsd
		call	ds:[bp].FSD_strategy
	;
	; Preserve the carry while we add in the amount we need/used to the
	; amount returned by the FSD
	;
		mov	ax, es:[si].FSSD_private
		jc	error
		add	cx, ax			; (won't exceed 64K,
						;  so won't set carry)
done:		
		call	FSDUnlockInfoShared
exit:
		.leave
		ret

noRoomNoRoom:
	;
	; Not enough room for our own data, so call the FSD to find out how
	; much it would use, in a perfect world, without letting it store
	; anything.
	; 
		push	ax			; save our requirements
		clr	cx			; tell FSD it ain't got nothin
		mov	di, DR_FS_DISK_SAVE
		mov	bp, ds:[bx].DD_drive
		mov	bp, ds:[bp].DSE_fsd
		call	ds:[bp].FSD_strategy
		pop	ax			; recover our requirements
		jnc	addOurs			; => FSD happy (must have
						;  returned cx==0, since we
						;  gave it no room, but we
						;  don't want to do that...)

error:
	; ax = # bytes we require
	; cx = # bytes FSD require
		jcxz	done		; => can't be saved for some reason
					;  other than lack of buffer space,
					;  so return cx==0 ourselves

addOurs:
					; else add in the amount we used to
					; the amount the FSD needed and
					; return carry set
		add	cx, ax
		stc			; we are not amused.
		jmp	done
DiskSave	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskRestore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore a saved disk handle for the caller.

CALLED BY:	GLOBAL
PASS:		ds:si	= buffer to which the disk handle was saved with
			  DiskSave
		cx:dx	= vfptr to callback routine, if user must be prompted
			  for the disk. If cx is 0, no callback will be
			  attempted, and failure will be returned if the disk
			  was in drive that no longer exists, or contains
			  removable media but not the disk in question.
			  
RETURN:		carry set if disk could not be restored:
			ax	= DiskRestoreError indicating why.
		carry clear if disk properly restored:
			ax	= handle of disk for this invocation of PC/GEOS

DESTROYED:	

PSEUDO CODE/STRATEGY:
		The callback routine is called:
		Pass:
			ds:dx	= drive name (null-terminated, with
				  trailing ':')
			ds:di	= disk name (null-terminated)
			ds:si	= buffer to which the disk handle was saved
			ax	= DiskRestoreError that would be returned if
				  callback weren't being called.
			bx, bp	= as passed to DiskRestore
		Return:
			carry clear if disk should be in the drive;
				ds:si	= new position of buffer, if it moved
			carry set if user canceled the restore:
				ax	= error code to return (usually
					  DRE_USER_CANCELED_RESTORE)
		
		; first we need to find the driver itself, so we know who to
		; call to ID the disk currently in the drive.
		bx <- GeodeFind(FSSD_ifsName, GA_DRIVER)
		if driver not found:
		    return (DRE_DRIVE_NO_LONGER_EXISTS)
	        fi

		lock FSIR exclusive

		bp <- FSDriver for the driver

		; now locate the drive, using the name we saved away.
		bx <- DriveLocateByName
		if drive not found, or drive managed by driver other than bp:
		    ; assume nothing for the drive, as the disk can't be
		    ; there
		    bx <- 0
 		fi
			
		; give the FSD a chance to verify that this is indeed the
		; drive we're looking for.
		call DR_FS_DISK_RESTORE(ds:si, bx)
		if error or bx still 0:
		    return (DRE_DRIVE_NO_LONGER_EXISTS)
		fi
		
		see if any known disk for the drive matches the saved ID
		if so, return the one found

		; we know now we need to create a new disk handle, but we
		; need to ensure the disk is in the drive before we
		; initialize the new disk handle.
		if flags say disk not always valid:
		    ; find what's there currently
		    call DR_FS_DISK_ID

		    if ID doesn't match saved ID:
			; use callback to ask the user for the disk
			unlock FSIR, so callback can do as it likes
			call callback(DRE_REMOVABLE_DRIVE_DOESNT_HOLD_DISK)
			if error, return ax
		    go back to the beginning, as the FSIR could have changed
		        during the callback
		fi
		
		; we know the disk is in the drive, so create a new
		; DiskDesc and initialize it to match what's there now.
		create DiskDesc and store ID and drive and flags
		call DR_FS_DISK_INIT
		return new disk handle
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskRestore	proc	far
passedBP	local	word	\
		push	bp
callback	local	fptr	; routine to call back in case disk not found\
		push	cx, dx
passedBX	local	word	; save point for BX for callback \
		push	bx
		uses	bx, cx, dx, di, es
		.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	mov	bx, ds						>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	tst	cx						>
EC<	jz	xipSafe						>
EC<	movdw	bxsi, cxdx					>
EC<	call	ECAssertValidFarPointerXIP			>
EC<	xipSafe:						>
EC<	pop	bx, si						>
endif
	;
	; See if the saved "disk handle" was actually a StandardPath constant.
	; 
		tst	ds:[si].FSSSP_signature
		jnz	restoreLoop
	;
	; Yes. Just return that constant. (carry cleared by tst)
	; 
		mov	ax, ds:[si].FSSSP_stdPath
		jmp	exit
restoreLoop:
		call	FileLockInfoSharedToES
 	;
	; See if the IFS driver is loaded for the drive.
	; 
		cmp	ds:[si].FSSD_ifsName[0], 0
		je	usePrimaryDriver

		mov	di, offset FIH_fsdList - offset FSD_next

searchByNameLoop:
		mov	di, es:[di].FSD_next
		tst	di
		jz	searchByNameFailed
		push	di, si
		add	di, offset FSD_name
		add	si, offset FSSD_ifsName
		mov	cx, GEODE_NAME_SIZE
		repe	cmpsb
		pop	di, si
		jne	searchByNameLoop
		jmp	lookForDrive

searchByNameFailed:
	;
	; If we can't locate the IFS driver, there's nothing more we can do.
	; 
		call	FSDUnlockInfoShared
		mov	ax, DRE_DRIVE_NO_LONGER_EXISTS
		stc
		jmp	exit

usePrimaryDriver:
	;
	; Disk belonged to the primary FSD when it was saved, so the current
	; one has to be able to handle it -- just fetch the primary FSD's
	; handle from the FSIR.
	; 
		mov	di, es:[FIH_primaryFSD]

lookForDrive:
	;
	; Now see if we can find a drive by the name stored in the FSSavedDisk
	; structure (terminated by a colon, of course).
	; 
		push	si
		lea	dx, ds:[si].FSSD_driveName
		call	DriveLocateByName
		mov	bx, si
		pop	si
		jc	noDrive
		
EC <		tst	bx						>
EC <		ERROR_Z	SAVED_DISK_HAS_NO_DRIVE_SPECIFIER_FOR_DRIVE_NAME>

   		cmp	es:[bx].DSE_fsd, di
		je	haveDrive

noDrive:
	;
	; Either the drive doesn't exist, or it's being run by some FSD other
	; than the one that ran it when the disk was saved. In either case,
	; we've no real idea what drive to use, so set bx to 0.
	; 
		clr	bx

haveDrive:
	;
	; We've put it off as long as possible. Upgrade our lock on the
	; FSIR to be exclusive.
	; 
		call	FSDUpgradeSharedInfoLock	; fixes up ES...
	;
	; Give the FSD a chance to either verify the drive we've selected is
	; the right one, or to tell us what drive to use, if we haven't a clue.
	; 
		push	bp
		mov	bp, di
		mov	di, DR_FS_DISK_RESTORE
		call	es:[bp].FSD_strategy
		mov	di, bp
		pop	bp
		call	FSDDowngradeExclInfoLock
		jc	doneJmp		; => FSD bitched; ax already an error
					;  code, but we need to unlock the FSIR
		
	;
	; Make sure we know what drive to use. If the FSD didn't complain, but
	; was clueless nonetheless, we need to return an error telling the
	; caller the drive doesn't exist anymore.
	; 
		tst	bx
		jnz	checkExistingDisks
		mov	ax, DRE_DRIVE_NO_LONGER_EXISTS
		stc
doneJmp:
		jmp	done

checkExistingDisks:
	;
	; Now have the correct drive, so see if any known disk is for the
	; drive and has the right 32-bit ID.
	; 
		push	bp
		mov	bp, offset FIH_diskList - offset DD_next
checkExistingLoop:
		mov	bp, es:[bp].DD_next
		tst	bp			; end of the road?
		jz	noExisting		; yes
		
		cmp	es:[bp].DD_drive, bx	; right drive?
		jne	checkExistingLoop	; no

		mov	ax, es:[bp].DD_id.low
		cmp	ds:[si].FSSD_id.low, ax	; low word of ID matches?
		jne	checkExistingLoop	; no

		mov	ax, es:[bp].DD_id.high
		cmp	ds:[si].FSSD_id.high, ax; high word of ID matches?
		jne	checkExistingLoop	; no
	;
	; The current disk is from the right drive and has the right ID, so
	; we'll take it. Shift its offset into AX for return, clear the carry
	; and boogie...
	; 
		mov_tr	ax, bp
		pop	bp
		clc
		jmp	done

noExisting:
	;
	; No existing disk matches. If the disk was always valid before, we
	; can just create a new one from scratch.
	; 
		xchg	bx, si		; ds:bx <- FSSavedDisk
					; es:si <- DriveStatusEntry

		mov	al, ds:[bx].FSSD_flags
		test	al, mask DF_ALWAYS_VALID
		jnz	createNew
	;
	; Otherwise, we have to make sure the right disk is in the drive before
	; we do that.
	;
	; Get the 32-bit ID for the disk currently in the drive.
	; 
		call	DriveLockExclFar

		mov	di, DR_FS_DISK_ID
		mov	bp, es:[si].DSE_fsd
		call	es:[bp].FSD_strategy
		jc	promptForDisk	; => no disk in the drive, so must
					;  prompt
	;
	; See if that ID matches the stored ID.
	; 
		cmp	cx, ds:[bx].FSSD_id.high
		jne	promptForDisk
		cmp	dx, ds:[bx].FSSD_id.low
		je	createNew

promptForDisk:
	;
	; Must ask the user to insert the disk. Point the registers at the
	; appropriate places for the call and do it.
	;
	; NOTE: We must release our lock on the FSIR to allow the callback to
	; call pretty much anything. This has the side effect of forcing us
	; to go through the whole rigamarole again, as drives might have
	; vanished/been unmounted, the disk might have been registered, etc.,
	; while we weren't looking.
	; 
		call	DriveUnlockExclFar
		pop	bp
		lea	dx, ds:[bx].FSSD_driveName
		lea	di, ds:[bx].FSSD_name
		mov	cx, ss:[callback].offset
		mov	ss:[TPD_callVector].offset, cx
		mov	cx, ss:[callback].segment
		mov	ss:[TPD_callVector].segment, cx
		mov	si, bx			; ds:si <- FSSavedDisk, in case
						;  fixup needed
		mov	bx, ss:[passedBX]
FXIP<		mov	ss:[TPD_dataBX], bx				>
		call	FSDUnlockInfoShared
		stc
		mov	ax, DRE_REMOVABLE_DRIVE_DOESNT_HOLD_DISK
FXIP<		mov	ss:[TPD_dataAX], ax				>
		jcxz	exit			; => no callback, so can't
						;  do spit
		push	bp
		mov	bp, ss:[passedBP]
NOFXIP<		call	ss:[TPD_callVector]				>
FXIP<		movdw	bxax, ss:[TPD_callVector]			>
FXIP<		call	ProcCallFixedOrMovable				>
		pop	bp
		jc	exit

	;
	; User didn't cancel, so go through the whole process again.
	; 
		jmp	restoreLoop

createNew:
	;
	; Create a new disk handle for the beast, now we know it's in the
	; drive.
	; 
	; ds:bx = FSSavedDisk
	; es:si = DriveStatusEntry
	; al	= DiskFlags for new disk
	; bp saved on stack, so we can biff it.
	; 
		mov	cx, ds:[bx].FSSD_id.high; pass disk ID
		mov	dx, ds:[bx].FSSD_id.low
		mov	bp, es:[si].DSE_fsd	;  and FSD to call
		mov	ah, ds:[bx].FSSD_media	;  and type of disk
if DO_NOT_ANNOUNCE_UNNAMED_DISKS
		mov	bh, FNA_SILENT		; don't tell user if new disk
						;  is unnamed.
else
		mov	bh, FNA_ANNOUNCE	; tell user if new disk
						;  is unnamed....?
endif
		push	ds			; need to preserve this...
		segmov	ds, es			; ds <- FSIR
		call	DiskAllocAndInit	; unlocks drive
		pop	ds
	;
	; Recover frame pointer and load registers for return; whether we
	; succeeded in creating the new handle or not, we've reached the
	; end of our rope and must now hang in the wind...
	; 
		pop	bp
		mov_tr	ax, bx			; ax <- new disk handle
		jnc	done

		mov	ax, DRE_COULDNT_CREATE_NEW_DISK_HANDLE
		stc
done:
	;
	; Release shared access to the FSIR. Doesn't affect any registers
	; 
		call	FSDUnlockInfoShared
exit:
		.leave
		ret
DiskRestore	endp

FileSemiCommon ends

;--------------------------------------------------------------

Filemisc segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitDiskDesc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inits a disk handle, either by allocating a new one, or
		by reusing a passed one

CALLED BY:	DiskAllocAndInit, DiskRegisterCommon
PASS:		cx:dx	= 32-bit ID
		al	= DiskFlags
		ah	= MediaType for disk
		bh	= FSDNamelessAction
		ds, es	= FSIR locked shared
		di	= offset into FSIR of DiskDesc to reuse, or 0 to alloc
		si	= DriveStatusEntry offset of drive in which the disk
			  is located
		bp	= FSDriver to call
		
		** drive locked for exclusive access

RETURN:		carry clear if disk handle could be created:
			bx	= disk handle
		carry set if disk handle couldn't be created:
			bx	= 0
		ds	= fixed up if pointing to FSIR on entry, else destroyed
		** drive unlocked
DESTROYED:	ds, ax, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitDiskDesc	proc	far
		.enter
	;
	; Start by initializing the skeleton descriptor with the contents
	; of a passed in handle, if any - brianc 7/27/93
	;
		tst	di
		jz	afterMove


	;
	; Don't overwrite the skeleton's DD_private field, because it
	; points to a skeleton private chunk.
	;
		
		push	cx, si, di
		mov	si, di			; ds:si = passed in handle
		mov	di, offset fsdTemplateDisk	; es:di = template
		mov	cx, size DiskDesc - size DD_private
		.assert (offset DD_private + size DD_private eq size DiskDesc)
		
		rep movsb
		pop	cx, si, di
afterMove:
		
	;
	; Store the parameters we were given into the skeleton descriptor
	; we keep around for this purpose.
	; 
		push	bp, si, di
		mov	ds:[fsdTemplateDisk].DD_id.high, cx
		mov	ds:[fsdTemplateDisk].DD_id.low, dx
		mov	ds:[fsdTemplateDisk].DD_flags, al
		mov	ds:[fsdTemplateDisk].DD_media, ah
		mov	ds:[fsdTemplateDisk].DD_drive, si
	;
	; Now contact the FSD to have it initialize its part of the deal.
	; 
		mov	si, offset fsdTemplateDisk
		mov	ax, bx		; ah <- FSDNamelessAction
		mov	di, DR_FS_DISK_INIT
		call	ds:[bp].FSD_strategy
		pop	bp, si, di	; restore FSDriver, DiskDesc, and
					;  DriveStatusEntry
	;
	; Release exclusive access to the drive, always, as our caller expects
	; it.
	; 
		call	DriveUnlockExclFar
		mov	bx, 0
		jc	done
	;
	; Now upgrade the shared FSIR lock to an exclusive one so we can copy
	; the skeleton disk descriptor and put it in the chain.
	; 
		call	FSDUpgradeSharedInfoLock

	;
	; Allocate room for the DiskDesc itself and initialize it from what's
	; in fsdSkeletonDisk.
	;
		push	si, cx
		mov	cx, size DiskDesc
		mov	bx, di
		tst	di		;If re-using existing DiskDesc, 
		jnz	noAlloc		; branch.

		call	LMemAlloc
		mov_tr	bx, ax		; bx <- new descriptor offset
		mov	di, bx

noAlloc:
		mov	si, offset fsdTemplateDisk
		segmov	es, ds
		rep	movsb
	;
	; Allocate room for the private data the driver has said it needs.
	; 
		mov	si, ds:[fsdTemplateDisk].DD_private
		clr	ax			; assume none needed
		mov	cx, ds:[bp].FSD_diskPrivSize
		jcxz	privDataCopied

		call	LMemAlloc
		mov	di, ax
		rep	movsb
privDataCopied:
		mov	ds:[bx].DD_private, ax
	;
	; Now link the new DiskDesc at the head of the list of known disks.
	; 
		mov	ax, bx
		xchg	ds:[FIH_diskList], ax
		mov	ds:[bx].DD_next, ax
		pop	si, cx
	;
	; All done with our resource-moving code, so release the exclusive.
	; 
		call	FSDDowngradeExclInfoLock
	;
	; Record the new handle as the last disk known in the drive, along
	; with the current time.
	; 
		mov	ds:[si].DSE_lastDisk, bx
		push	bx
		call	TimerGetCount
		pop	bx
		mov	ds:[si].DSE_lastAccess, ax
		clc
done:
		.leave
		ret
InitDiskDesc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskAllocAndInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a new disk handle and initialize it.

CALLED BY:	RESTRICTED GLOBAL
PASS:		cx:dx	= 32-bit ID
		al	= DiskFlags
		ah	= MediaType for disk
		bh	= FSDNamelessAction
		ds	= FSIR locked shared
		si	= DriveStatusEntry offset of drive in which the disk
			  is located
		bp	= FSDriver to call
		
		** drive locked for exclusive access

RETURN:		carry clear if disk handle could be created:
			bx	= disk handle
		carry set if disk handle couldn't be created:
			bx	= 0
		ds	= fixed up if pointing to FSIR on entry, else destroyed
		** drive unlocked
DESTROYED:	ds, ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskAllocAndInit proc	far
		.enter
		clr	di
		call	InitDiskDesc
		.leave
		ret
DiskAllocAndInit endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskFind

DESCRIPTION:	Given a volume name, searches the list of registered disks
		to find one that has the name.

		An additional search for a match in the remaining disk
		descriptors is conducted to see if the match is unique.

CALLED BY:	GLOBAL (Desktop)

PASS:		ds:si - null terminated volume name

RETURN:		carry set if error
			ax - error code
				VN_MATCH_NOT_FOUND
			bx - 0
		carry clear if no error
			ax - status code
				VN_MATCH_NOT_UNIQUE
				VN_MATCH_UNIQUE
			bx - disk handle

DESTROYED:	

REGISTER/STACK USAGE:
	bp - idata segment

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	ardeb	7/16/91		Renamed & changed to use FSIR

-------------------------------------------------------------------------------@
DiskFind	proc	far
		uses	di, es, cx
		.enter
		call	FileLockInfoSharedToES
		
		mov	di, offset FIH_diskList - offset DD_next
		mov	ax, DFR_NOT_FOUND	; assume no match
		clr	bx
diskLoop:
		mov	di, es:[di].DD_next	; es:di <- next descriptor
		tst	di
		jz	done
		
		test	es:[di].DD_flags, mask DF_STALE
		jnz	diskLoop		; stale, so don't return it

		call	CheckVolumeNameMatch	; check match
		jc	diskLoop		; nope -- go to next disk
		
		cmp	ax, DFR_NOT_FOUND	; first one found?
		jne	foundDuplicate		; nope -- signal this
		
		mov	ax, DFR_UNIQUE		; assume unique
		mov	bx, di			; bx <- disk handle
		jmp	diskLoop		; go look for duplicate

foundDuplicate:
		mov	ax, DFR_NOT_UNIQUE	; not the only one with the
						;  name, so flag it and stop
						;  now (only need to know that
						;  more than one exists, not
						;  how many exist)
done:
		call	FSDUnlockInfoShared
			CheckHack <DFR_NOT_FOUND gt DFR_NOT_UNIQUE AND \
				   DFR_NOT_FOUND gt DFR_UNIQUE>
		cmp	ax, DFR_NOT_FOUND	; set the carry if the disk
						;  was found (both the possible
						;  return codes in the "found"
						;  case are below the code
						;  for "not found")
		cmc				; but we need carry set if we
						;  didn't find it...
		.leave
		ret
DiskFind	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckVolumeNameMatch

DESCRIPTION:	Utility routine used by DiskFind to compare the
		sought volume name against that for the handle, dealing with
		space-padding and so forth.

CALLED BY:	INTERNAL (DiskFind)

PASS:		es:[di].DD_volumeLabel = label against which to compare
		ds:si - null-terminated name being sought

RETURN:		carry clear if match
		set if not

DESTROYED:	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@


CheckVolumeNameMatch	proc	near
	uses	si, di
	.enter
	add	di, DD_volumeLabel	;es:di <- volume name for this disk

	mov	cx, MSDOS_VOLUME_LABEL_LENGTH
	repe	cmpsb 
	je	done			; yup -- matched the whole way through
					;  (carry cleared by = comparison)
	tst	{byte}ds:[si-1]		; make sure source mismatched due to
					;  null-terminator
	jz	confirm			; yes -- go make sure rest is padding
noMatch:
	stc
done:
	.leave
	ret
confirm:
	;
	; Make sure the rest of the chars in the disk handle's volumeLabel are
	; just padding spaces.
	;
	push	ax
	mov	al, ' '
	repe	scasb
	pop	ax

	je	done			; made it to the end, so yes...
	jmp	noMatch
CheckVolumeNameMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskReRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-register a disk to see if its name or write-protect
		status has changed.

CALLED BY:	FileCheckDiskWritable
PASS:		es:bx	= handle to re-initialize (FSIR locked shared)
RETURN:		carry set if disk is bad
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskReRegister	proc	far
		call	PushAllFar
	;
	; Make sure the disk is in the drive and lock the drive for exclusive
	; access.
	; 
		mov	si, bx
		call	DiskLockExcl
		jc	done
	;
	; Promote our shared lock on the FSIR to an exclusive one
	; 
		call	DiskReRegisterInt
	;
	; Release the exclusive on the drive
	; 
		call	DiskUnlockExcl
done:
		mov	bp, sp
		mov	ss:[bp].PAF_es, es	; in case FSIR moved...
		call	PopAllFar
		ret
DiskReRegister	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskReRegisterInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internals of DiskReRegister after all synchronization
		points have been snagged.

CALLED BY:	DiskReRegister, FSDReInitDisk
PASS:		es:bx	= DiskDesc to re-initialize
		FSIR locked shared
		drive locked exclusive
RETURN:		carry set on failure
DESTROYED:	ax, cx, dx, di, bp, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskReRegisterInt proc	far
		uses	si
		.enter
		segmov	ds, es 			; ds <- FSIR for efficiency
	;
	; Contact the drive's FSD to fetch the ID and flags of the disk
	; currently in the drive.
	; 
		mov	di, DR_FS_DISK_ID
		mov	si, ds:[bx].DD_drive
		mov	bp, ds:[si].DSE_fsd
		push	bp
		call	ds:[bp].FSD_strategy
		pop	bp
		jc	done
	;
	; Store the new ID and flags & media (for dealing with FSDReInitDisk).
	; 
		mov	ds:[bx].DD_id.low, dx
		mov	ds:[bx].DD_id.high, cx
		xchg	ds:[bx].DD_flags, al
		mov	ds:[bx].DD_media, ah
	;
	; Figure if the user should be notified should the disk now turn out
	; to be nameless. If the disk is currently unnamed, we won't notify
	; the user should the disk continue to be nameless.
	;
		mov	ah, FNA_ANNOUNCE	; assume named, so announce if
						;  disk now unnamed.
		test	al, mask DF_NAMELESS	; correct?
		jz	fetchName		; => correct.
		
		mov	ah, FNA_IGNORE		; currently unnamed, so do
						;  nothing if still unnamed
fetchName:
	;
	; Contact the drive's FSD to fetch the disk's volume name now.
	; 
		push	si
		mov	si, bx			; es:si <- DiskDesc
		mov	di, DR_FS_DISK_INIT
		push	bp
		call	ds:[bp].FSD_strategy
		pop	bp
		pop	si
done:
		.leave
		ret
DiskReRegisterInt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskCheckInUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if a disk handle is actively in-use, either by
		an open file or by a thread having a directory on the disk
		in its directory stack.

CALLED BY:	GLOBAL
PASS:		bx	= disk handle
RETURN:		carry set if the disk is in-use.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskCheckInUse	proc	far
		.enter
		call	PushAllFar
		call	DiskMapStdPath
		mov	cx, bx
		mov	di, SEGMENT_CS
		mov	si, offset DIU?_fileCallback
		clr	bx		; process whole list, please
		call	FileForEach
		jc	done
		
		mov	di, SEGMENT_CS
		mov	si, offset DIU?_pathCallback
		call	FileForEachPath
done:
		call	PopAllFar
		.leave
		ret
DiskCheckInUse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIU?_fileCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to determine if a file is open to a disk.

CALLED BY:	DiskCheckInUse via FileForEach
PASS:		bx	= file handle
		ds	= kdata
		cx	= disk handle being sought
RETURN:		carry set if file open on disk. This will stop traversal
		and cause a carry-set return from DiskCheckInUse
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIU?_fileCallback	proc far
		cmp	cx, ds:[bx].HF_disk
		je	DIU?_callbackCommon
		stc			; return carry clear to continue search
DIU?_callbackCommon label near
		cmc
		ret
DIU?_fileCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIU?_pathCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to determine if a path in a thread's
		directory stack is on a particular disk.

CALLED BY:	DiskCheckInUse via FileForEach
PASS:		bx	= path handle
		di	= disk handle for the path
		cx	= disk handle being sought
RETURN:		carry set if path is on the disk. This will stop traversal
		and cause a carry-set return from DiskCheckInUse
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIU?_pathCallback	proc far
		cmp	cx, di
		je	DIU?_callbackCommon
		clc
		ret
DIU?_pathCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskForEach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run through the list of registered disks, calling a callback
		routine for each one until it says stop, or we run out of
		disks.

CALLED BY:	GLOBAL
PASS:		ax, cx, dx, bp = initial data to pass to callback
		di:si	= far pointer to callback routine
			(XIP geodes can pass virtual far pointers)
RETURN:		ax, cx, dx, bp = as returned from last call
		carry	= set if callback forced early termination of processing
		bx	= last disk processed, if carry set, else 0
DESTROYED:	di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskForEach	proc	far
callback	local	fptr.far	; routine to call back \
		push	di		; set segment \
		push	si		;  and offset
		uses	es
		ForceRef callback
		.enter

if	FULL_EXECUTE_IN_PLACE
EC<		push	bx						>
EC<		mov	bx, di						>
EC<		call	ECAssertValidFarPointerXIP			>
EC<		pop	bx						>
endif

		call	FileLockInfoSharedToES
		mov	bx, offset FIH_diskList - offset DD_next
processLoop:
		mov	bx, es:[bx].DD_next
		tst	bx
		jz	done
		call	SysCallCallbackBPFar
		jnc	processLoop
done:
		call	FSDUnlockInfoShared
		.leave
		ret
DiskForEach	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskUnlockInfoAndCallFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine employed by DiskFormat and DiskCopy to
		call the strategy routine of an FSD given the drive
		descriptor, but only after releasing a shared lock on
		the FSInfoResource

CALLED BY:	DiskFormat, DiskCopy
PASS:		es:bx	= DriveStatusEntry
		di	= FSD function to call
		on stack:
			bx to pass to driver
RETURN:		whatever FSDriver returns
		bx-to-pass removed from stack
DESTROYED:	bx, ax, si (ax, si nuked before driver called)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskUnlockInfoAndCallFSD proc	near passBX:word
fsdStrategy	local	fptr.far
		.enter
	;
	; Copy the FSD's strategy routine to fsdStrategy
	; 
		push	ax
		mov	bx, es:[bx].DSE_fsd
		mov	ax, es:[bx].FSD_strategy.segment
		mov	ss:[fsdStrategy].segment, ax
		mov	ax, es:[bx].FSD_strategy.offset
		mov	ss:[fsdStrategy].offset, ax
		pop	ax
	;
	; Release shared access to the FSInfoResource
	; 
		call	FSDUnlockInfoShared
	;
	; Call the strategy routine passing it the BP we were passed.
	; 
		mov	bx, ss:[passBX]
		call	SysCallCallbackBPFar
		.leave
		ret	@ArgSize
DiskUnlockInfoAndCallFSD endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskFormat

DESCRIPTION:	Formats the disk in the specified drive.

CALLED BY:	GLOBAL

PASS:		al - drive number
		ah - PC/GEOS media descriptor
			MEDIA_160K, or
			MEDIA_180K, or
			MEDIA_320K, or
			MEDIA_360K, or
			MEDIA_720K, or
			MEDIA_1M2, or
			MEDIA_1M44, or
			MEDIA_2M88

		    not currently supported:
			MEDIA_FIXED_DISK for default max capacity
			MEDIA_DEFAULT_MAX for default max capacity
		bx - handle of disk to format, 0 if disk currently in drive
			is known to be unformated, -1 if state of drive not
			known

		bp - DiskFormatFlags
		cx:dx - vfptr to callback routine, initialized only if
			DFF_CALLBACK_PCT_DONE or DFF_CALLBACK_CYL_HEAD set
			in bp

		ds:si - ASCIIZ volume name

RETURN:		carry set on error
		error code in ax:
			FMT_DONE (= 0) if successful
			FMT_INVALID_DRIVE
			FMT_DRIVE_NOT_READY
			FMT_ERR_WRITING_BOOT
			FMT_ERR_WRITING_ROOT_DIR
			FMT_ERR_WRITING_FAT
			FMT_BAD_PARTITION_TABLE
			FMT_ERR_READING_PARTITION_TABLE
			FMT_ABORTED
			FMT_SET_VOLUME_NAME_ERR
			FMT_CANNOT_FORMAT_FIXED_DISKS_IN_CUR_RELEASE
			FMT_ERR_DISK_IS_IN_USE
			FMT_ERR_WRITE_PROTECTED
		if successful (else 0):
			si:di - bytes in good clusters
			dx:cx - bytes in bad clusters

DESTROYED:	ax,bx

	Callback:
	PASS:
		ax - percentage done
	RETURN:
		carry set to CANCEL
	DESTROYED:
		nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Formats for floppies are low-level, ie. all data will be lost.
	Formats for fixed disks proceed as track verifies. The FAT is rebuilt.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
DiskFormat		proc	far
EC<	test	bp, mask DFF_CALLBACK_PCT_DONE or mask DFF_CALLBACK_CYL_HEAD >
EC<	jz	xipSafe							>
EC<	push	bx, si							>
EC<	movdw	bxsi, cxdx						>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx, si							>
EC< xipSafe:								>
	mov	ss:[TPD_dataBX], handle DiskFormatReal
	mov	ss:[TPD_dataAX], offset DiskFormatReal
	GOTO	SysCallMovableXIPWithDSSI
DiskFormat		endp
CopyStackCodeXIP	ends

else

DiskFormat		proc	far
	FALL_THRU	DiskFormatReal
DiskFormat		endp

endif
DiskFormatReal	proc	far
		uses	es, ds
		.enter
	;
	; Make sure the drive can support the passed format.
	; 
		call	DriveTestMediaSupport
		LONG jc	badMediaSpec

	;
	; See if the disk handle has been passed or is known to not exist.
	; 
		inc	bx			; -1 => unknown?
		jz	registerCurrentDisk	; right -- try register
		dec	bx			; 0 => unformatted?
		jz	lockDriveExcl		; right -- skip check

	;
	; Disk handle was discovered before and passed in, so see if the thing
	; is currently in-use.
	; 
		call	DiskCheckInUse
		LONG jc	diskInUse
	;
	; Disk not currently in-use, but make sure the thing's in the drive.
	; 
		call	FileLockInfoSharedToES
EC <		call	AssertDiskHandle				>
		push	si, bp
		mov	si, bx		; es:si <- DiskDesc
		call	DiskLockFar
		LONG jc	formatAbortedDuringValidate

		call	DiskUnlockFar
		pop	si, bp
		jmp	verifyDiskWritable

notYetFormatted:
		clr	bx		; pass no disk handle
		jmp	lockDriveExcl

registerCurrentDisk:
	;
	; State of drive is unknown. Attempt to register the disk that may
	; be in there right now.
	; 
		call	DiskRegisterDiskSilently
		jc	notYetFormatted	; => unformatted, so can't be in-use
	;
	; There's a valid disk in there, so make sure it's not currently
	; in-use.
	; 
		call	DiskCheckInUse
		jc	diskInUse	; choke

		call	FileLockInfoSharedToES

verifyDiskWritable:
	;
	; Make sure the disk is writable before we attempt to format it.
	; 
		call	FSDCheckDestWritable
		call	FSDUnlockInfoShared
		jnc	lockDriveExcl
		mov	ax, FMT_ERR_WRITE_PROTECTED
		jmp	fail
lockDriveExcl:
	;
	; Make sure, after all that, that the drive actually supports
	; formatting.
	; 
		push	si
		call	FileLockInfoSharedToES
		call	DriveLocateByNumber
		jc	noSuchDrive
		test	es:[si].DSE_status, mask DES_FORMATTABLE
		jz	cannotFormat
	;
	; Gain exclusive access to the drive for the duration.
	; 
		call	DriveLockExclFar

	;
	; All systems are go. Mark the drive as busy for an extended period
	; and go call the FSD.
	; 
		ornf	es:[si].DSE_status, mask DES_BUSY

		pop	di		; di <- volume label
		push	si		; FSFA_dse
		push	bx		; FSFA_disk

		mov	bx, si		; es:bx <- DriveStatusEntry,
		push	bp		; FSFA_flags
		push	ds, di		; FSFA_volumeName
		push	ss:[TPD_dgroup]	; FSFA_ds
		push	cx, dx		; FSFA_callback
		push	ax		; FSFA_media, FSFA_drive
		mov	ax, sp		; ss:bx <- FSFormatArgs
		push	ax		;  when FSD is finally called

		mov	di, DR_FS_DISK_FORMAT	; di <- function to perform
		call	DiskUnlockInfoAndCallFSD
	;
	; Mark the drive as no longer busy and release its exclusive regardless
	; of the error code.
	; 
		mov	bx, sp		; clear stack of args w/o biffing carry
		CheckHack <offset FSFA_dse+size FSFA_dse eq size FSFormatArgs>
		lea	sp, ss:[bx].FSFA_dse
		pop	si		; si <- DSE offset

		pushf
		call	FileLockInfoSharedToES
		call	DriveUnlockExclFar	
		call	FSDUnlockInfoShared
		mov	si, ax		; return good-bytes-high in SI, not AX,
					;  but be sure to leave error code in
					;  AX, if such there be...
		popf
		jc	fail		; handle return values on error
done:
		.leave
		ret

formatAbortedDuringValidate:
		call	FSDUnlockInfoShared
		pop	si, bp
		mov	ax, FMT_ERR_DISK_UNAVAILABLE
		jmp	fail

badMediaSpec:
		mov	ax, FMT_ERR_DRIVE_CANNOT_SUPPORT_GIVEN_FORMAT
		jmp	fail

diskInUse:
		mov	ax, FMT_ERR_DISK_IS_IN_USE
		jmp	fail

noSuchDrive:
		pop	si		; recover volume label offset (use
					;  pop instead of two inc sp's to
					;  save space; this code ain't
					;  time-critical)
		mov	ax, FMT_ERR_INVALID_DRIVE_SPECIFIED
		jmp	fail

cannotFormat:
		pop	si		; recover volume label offset
		mov	ax, FMT_ERR_DRIVE_CANNOT_BE_FORMATTED
fail:
	;
	; Return 0 bytes good, 0 bytes bad and carry set.
	; 
		clr	si
		mov	di, si
		mov	cx, si
		mov	dx, si
		stc
		jmp	done
DiskFormatReal	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskCopy

DESCRIPTION:	Copies the contents of the source disk to the destination disk,
		prompting  for them as necessary.

CALLED BY:	GLOBAL

PASS:		dh - source drive number
		dl - destination drive number
		al - DiskCopyFlags
		cx:bp - callback routine (virtual pointer if XIP'ed geode)

RETURN:		ax - DiskCopyError/FormatError
			0 if successful

DESTROYED:	nothing

	Interface for callback function:

	DCC_GET_SOURCE_DISK
		passed:
			ax - DCC_GET_SOURCE_DISK
			dl - 0 based drive number
		callback routine to return:
			ax = 0 to continue, non-0 to abort


	DCC_REPORT_NUM_SWAPS
		passed:
			ax - DCC_REPORT_NUM_SWAPS
			dx - number of swaps required
		callback routine to return:
			ax = 0 to continue, non-0 to abort


	DCC_GET_DEST_DISK
		passed:
			ax - DCC_GET_DEST_DISK
			dl - 0 based drive number
		callback routine to return:
			ax = 0 to continue, non-0 to abort


	DCC_VERIFY_DEST_DESTRUCTION
		passed:
			ax - DCC_REPORT_NUM_SWAPS
			bx - disk handle of destination disk
			dl - 0 based drive number
		callback routine to return:
			ax = 0 to continue, non-0 to abort


	DCC_REPORT_FORMAT_PCT
		passed:
			ax - DCC_REPORT_FORMAT_PCT
			dx - percentage of destination disk formatted
		callback routine to return:
			ax = 0 to continue, non-0 to abort

	DCC_REPORT_READ_PCT
		passed:
			ax - DCC_REPORT_READ_PCT
			dx - percentage of source disk read
		callback routine to return:
			ax = 0 to continue, non-0 to abort

	DCC_REPORT_WRITE_PCT
		passed:
			ax - DCC_REPORT_WRITE_PCT
			dx - percentage of destination disk written
		callback routine to return:
			ax = 0 to continue, non-0 to abort

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if formats are compatible then
	    allocate buffer (some multiple of 1 sector)
	    for all blocks on disk
		read source (takes care of bringing disk in)
		write dest (takes care of bringing disk in)
	    end for
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version
	Todd	05/94		XIP'ed

-------------------------------------------------------------------------------@
DiskCopy	proc	far
args		local	FSCopyArgs
		uses	bx, cx, dx, si, di, es
		.enter
	;
	; Store passed args to give to the IFS driver.
	; 
		mov	ss:[args].FSCA_flags, al
		mov	ax, ss:[bp]		; ax <- passed BP
		movdw	ss:[args].FSCA_callback, cxax

	;
	; Verify callback is not XIP'ed
	;
if	FULL_EXECUTE_IN_PLACE
EC<		push	bx, si						>
EC<		movdw	bxsi, cxax					>
EC<		call	ECAssertValidFarPointerXIP			>
EC<		pop	bx, si						>
endif

		call	FileLockInfoSharedToES
	;
	; Check out the dest drive to make sure it exists and supports copying.
	; 
		mov	al, dl
		call	locateAndCheckDrive
		LONG jc	errorUnlockFSIR
		mov	di, si		; save dest in a convenient place
		mov	ss:[args].FSCA_dest, si
	;
	; Likewise for the source drive
	; 
		mov	al, dh
		call	locateAndCheckDrive
		dec	ax		; convert to source-drive error code
					;  in case of error
		jc	errorUnlockFSIR
		mov	ss:[args].FSCA_source, si
	;
	; Make sure both drives run by the same driver.
	; 
		mov	ax, es:[si].DSE_fsd
		cmp	ax, es:[di].DSE_fsd
		mov	ax, ERR_DRIVES_HOLD_DIFFERENT_FILESYSTEM_TYPES
		jne	errorUnlockFSIR
	;
	; Ask the callback to get the disk in
	; 
		mov	dl, es:[si].DSE_number
		call	FSDUnlockInfoShared
		push	dx

FXIP<		mov	ss:[TPD_dataAX], DCC_GET_SOURCE_DISK	>
FXIP<		mov	ss:[TPD_dataBX], bx			>
FXIP<		movdw	bxax, ss:[args].FSCA_callback		>
FXIP<		call	ProcCallFixedOrMovable			>

if 	DCC_GET_SOURCE_DISK eq 0
NOFXIP<		clr	ax		; faster & smaller	>
else
NOFXIP<		mov	ax, DCC_GET_SOURCE_DISK			>
endif
NOFXIP<		call	ss:[args].FSCA_callback			>
		pop	dx

		tst	ax
		mov	ax, ERR_OPERATION_CANCELLED
		jnz	error
	;
	; Try and register the disk in the drive.
	; 
		mov	al, dl
		call	DiskRegisterDisk
		mov	ax, ERR_SOURCE_DISK_NOT_FORMATTED
		jc	error
		mov	ss:[args].FSCA_disk, bx
	;
	; Now make sure the media of the disk are compatible with the dest
	; drive.
	; 
		call	FileLockInfoSharedToES
		mov	ah, es:[bx].DD_media
		mov	si, ss:[args].FSCA_dest
		mov	al, es:[si].DSE_number
		call	DriveTestMediaSupport
		mov	ax, ERR_SOURCE_DISK_INCOMPATIBLE_WITH_DEST_DRIVE
		jc	errorUnlockFSIR
	;
	; Call the FSIR to do the copy. We do *not* lock the two drives
	; for exclusive access as they might be aliases of each other and we'd
	; deadlock on ourselves.
	; 
		mov	bx, si
		lea	ax, ss:[args]
		push	bp
		push	ax
		mov	di, DR_FS_DISK_COPY
		call	DiskUnlockInfoAndCallFSD
		pop	bp
done:
		.leave
		ret

errorUnlockFSIR:
		call	FSDUnlockInfoShared
error:
		stc
		jmp	done
	;--------------------
	;Pass:		al = drive number
	;		es = FSIR
	;Return:	carry set on error:
	;		    ax	= ERR_INVALID_DEST_DRIVE
	;			= ERR_DEST_DRIVE_DOESNT_SUPPORT_DISK_COPY
	;		carry clear if happy:
	;		    es:si	= DriveStatusEntry
	;
locateAndCheckDrive:
		call	DriveLocateByNumber	; es:si <- dest drive
		mov	ax, ERR_INVALID_DEST_DRIVE
		jc	locateComplete
		
		test	es:[si].DSE_status, mask DES_FORMATTABLE
		jnz	locateComplete
		mov	ax, ERR_DEST_DRIVE_DOESNT_SUPPORT_DISK_COPY
		stc
locateComplete:
		retn


DiskCopy	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskVolumeOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for the various Disk*Volume* functions to
		call the FSD bound to a disk

CALLED BY:	DiskGetVolumeFreeSpace, DiskGetVolumeInfo
PASS:		si	= offset of DiskDesc
		di	= FSFunction to invoke
RETURN:		whatever, es & bp cannot hold return values
DESTROYED:	di, ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskVolumeOp	proc	far
		uses	es, bp
		.enter
		test	si, DISK_IS_STD_PATH_MASK
		jz	doIt
		LoadVarSeg	es, ax
		mov	si, es:[topLevelDiskHandle]
doIt:
		call	FSDLockInfoShared
		mov	es, ax
		clr	al				; lock may be aborted
		call	DiskLockCallFSD
		call	FSDUnlockInfoShared
		.leave
		ret
DiskVolumeOp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskGetVolumeFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return free space on volume

CALLED BY:	GLOBAL

PASS:		bx - disk handle of volume for which to get free space

RETURN:		carry clear if no error
			dx:ax - bytes free on that volume
		carry set if error
			ax - ERROR_INVALID_VOLUME

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskGetVolumeFreeSpace	proc	far
	uses	si, di
	.enter
	mov	si, bx
	mov	di, DR_FS_DISK_FIND_FREE
	call	DiskVolumeOp
	.leave
	ret
DiskGetVolumeFreeSpace	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskGetVolumeInfo

DESCRIPTION:	Get information about a volume.

CALLED BY:	GLOBAL

PASS:
	bx - disk handle of volume for which to get info
	es:di - DiskInfoStruct to fill in

RETURN:
	carry - set if error
		ax - error code (if an error)
			ERROR_INVALID_VOLUME
	carry clear if success
		structure at es:di filled in

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@
DiskGetVolumeInfo	proc	far
	uses	cx, bx, si, di
	.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si							>
EC<	movdw	bxsi, esdi						>
EC<	call	ECAssertValidTrueFarPointerXIP				>
EC<	pop	bx, si							>
endif
	mov	si, bx
	mov	bx, es
	mov	cx, di
	mov	di, DR_FS_DISK_INFO
	call	DiskVolumeOp
	.leave
	ret
DiskGetVolumeInfo	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskSetVolumeName

DESCRIPTION:	Set the name of a volume

CALLED BY:	GLOBAL

PASS:
	bx - disk handle of volume of which to set volume name
	ds:si - new name (null-terminated)

RETURN:
	carry - set if error
	ax - error code (if an error)
		ERROR_INVALID_VOLUME
		ERROR_ACCESS_DENIED

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	lock FSIR shared
	lock the drive for exclusive access
	upgrade FSIR shared lock to exclusive
	ask FSD to rename the disk (DR_FS_DISK_RENAME)
	if success, copy new name into DiskDesc
	downgrade FSIR exclusive to shared
	release exclusive access to drive
	release shared FSIR lock

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Todd	5/94		XIP'ed
-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
DiskSetVolumeName		proc	far
	mov	ss:[TPD_dataBX], handle DiskSetVolumeNameReal
	mov	ss:[TPD_dataAX], offset DiskSetVolumeNameReal
	GOTO	SysCallMovableXIPWithDSSI
DiskSetVolumeName		endp
CopyStackCodeXIP		ends

else

DiskSetVolumeName		proc	far
	FALL_THRU	DiskSetVolumeNameReal
DiskSetVolumeName		endp

endif

DiskSetVolumeNameReal	proc	far
	uses	es, di, dx, bp, cx, bx
	.enter
	call	DiskMapStdPath
	call	FileLockInfoSharedToES
	;
	; Make sure the disk is actually writable. bail if not.
	; 
	call	FSDCheckDestWritable
	jc	done

	;
	; Lock the disk for exclusive access, as we'll be modifying the DiskDesc
	; 
	xchg	si, bx			; es:si <- DiskDesc, ds:bx <- new name
	call	DiskLockExcl
	jc	done

	;
	; Upgrade our shared lock on the FSIR to an exclusive one and ask the
	; FSD to rename the disk. It'll take care of updating the DiskDesc.
	; 
	mov	dx, bx			; ds:dx <- new name
	mov	di, DR_FS_DISK_RENAME
	mov	bp, es:[si].DD_drive
	mov	bp, es:[bp].DSE_fsd
	call	es:[bp].FSD_strategy

	;
	; Release the disk, being careful not to muck with the result of the
	; rename.
	; 
	call	DiskUnlockExcl
done:
	;
	; Release our shared lock on the FSIR, now we're all done.
	; 
	call	FSDUnlockInfoShared
	.leave
	ret
DiskSetVolumeNameReal	endp

Filemisc	ends
