COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cdromDisk.asm

AUTHOR:		Adam de Boor, Mar 29, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/29/92		Initial revision


DESCRIPTION:
	Disk-related functions for NetWare.
		

	$Id: cdromDisk.asm,v 1.1 97/04/10 11:55:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMDiskGenerateID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an ID from the VTOC for the current disk.

CALLED BY:	(INTERNAL)
PASS:		es:si	= DriveStatusEntry
RETURN:		carry set if ID couldn't be determined
		carry clear if ID figured:
			cxdx	= 32-bit ID
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMDiskGenerateID proc	near
	volFCB		local	FCB
	dta		local	FCB
		uses	ds, bx, si, es, di, bp
		.enter
	;
	; Read the volume label.  This seems to have magical effects -- without
	; this call, the succeeding call to retrieve the VTOC makes DOS forever
	; unable to refresh its buffers, providing us with a permanent image of
	; the previous disk.  I guess the rule is that you must talk to DOS
	; before talking to MSCDEX after a disk change has occurred.  How you're
	; supposed to know that a disk change has occurred without talking to
	; MSCDEX is beyond me... dl 7/16/93
	;
		mov	dl, es:[si].DSE_number
		lea	di, ss:[volFCB]
		lea	bx, ss:[dta]
		call	CDROMDiskLocateVolumeLow
	; edigeron 1/11/01 - Testing for the carry flag isn't the right
	; thing to do here. That doesn't work. Normally the error gets
	; caught in the following code, but not if using DR-DOS and NWCDEX.
	; And this error handler is wrong too, as we didn't allocate memory
	; yet...
	;		jc	error
		tst	al
		jnz	errorNoFree

	;
	; Allocate a buffer for reading the first sector of the VTOC.
	; 
		mov	ax, CDROM_SECTOR_SIZE
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		jc	done
	;
	; Now read it in.
	; 
		push	bx, bp
		mov	cl, es:[si].DSE_number	; cx <- drive #
		clr	ch
		mov	es, ax
		mov	ds, ax
		clr	bx, dx			; es:bx <- buffer
						; dx <- sector # (0)
		mov	ax, CDROM_READ_VTOC
		call	CDROMUtilSetFailOnError	; grabs BIOS
		int	2fh
		call	CDROMUtilClearFailOnError
		jc	error

	;
	; Compute a 32-bit checksum for the thing, using our favorite algorithm.
	; 
		clr	si		; point to start of buffer
		mov	dx, 0x31fe	; magic number
		mov	cl, 5		; handy shift count for *33
		clr	ah
calculateLoop:
		lodsb
	;
	; Multiply existing value by 33
	; 
		movdw	dibp, bxdx	; save current value for add
		rol	dx, cl		; *32, saving high 5 bits in low ones
		shl	bx, cl		; *32, making room for high 5 bits of
					;  dx
		mov	ch, dl
		andnf	ch, 0x1f	; ch <- high 5 bits of dx
		andnf	dl, not 0x1f	; nuke saved high 5 bits
		or	bl, ch		; shift high 5 bits into bx
		adddw	bxdx, dibp	; *32+1 = *33
	;
	; Add current byte into the value.
	; 
		add	dx, ax
		adc	bx, 0
		cmp	si, CDROM_SECTOR_SIZE	; end of the buffer?
		jb	calculateLoop		; no

		mov	cx, bx		; cxdx <- ID

		pop	bx, bp
		call	MemFree
		clc
done:		
		.leave
		ret
error:

		pop	bx, bp
		call	MemFree
errorNoFree:
		stc
		jmp	done
CDROMDiskGenerateID endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMDiskID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the ID number for the disk in a drive we manage.

CALLED BY:	DR_FS_DISK_ID
PASS:		es:si	= DriveStatusEntry for the drive
RETURN:		carry set if ID couldn't be determined
		carry clear if it could:
			cx:dx	= 32-bit ID
			al	= DiskFlags for the disk
			ah	= MediaType for the disk
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMDiskID	proc	far
		.enter

		call	CDROMDiskGenerateID	; cxdx <- ID
		jc	done
doneEarly:
		clr	al		; disk flags
		mov	ah, MEDIA_CUSTOM; ah <- MediaType

done:
		.leave
		ret

if 0
lameness:
		clr	cx
		mov	dx, cx
		mov	al, mask DF_WRITABLE or mask DF_ALWAYS_VALID
		mov	ah, MEDIA_FIXED_DISK
		jmp	doneEarly
endif

CDROMDiskID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMDiskRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to rename a disk. CDROMs don't allow this, so
		we always return ERROR_ACCESS_DENIED

CALLED BY:	DR_FS_DISK_RENAME
PASS:		es:si	= DiskDesc of disk to be renamed (locked for exclusive
			  access...)
		ds:dx	= new name for disk
RETURN:		carry set on error:
			ax	= error code
		carry clear if successful
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMDiskRename	proc	far
		.enter
		mov	ax, ERROR_ACCESS_DENIED
		stc
		.leave
		ret
CDROMDiskRename	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMDiskSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append whatever private data the driver will require to
		restore the passed disk descriptor. The system portion
		(FSSavedDisk) will already have been filled in, with
		FSSD_private set to the offset at which the driver should
		store its information.

		NOTE: The registers passed to this function are non-standard
		(the FSIR is in DS, not ES).

CALLED BY:	DR_FS_DISK_SAVE
PASS:		ds:bx	= DiskDesc being saved (not locked; FSIR locked shared)
		es:dx	= place to store FSD's private data
		cx	= # bytes FSD may use
RETURN:		carry clear if disk saved:
			cx	= # bytes actually taken by FSD-private data
		carry set if disk not saved:
			cx	= # bytes needed by FSD-private data (0 =>
				  other error)
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Nothing to do here.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMDiskSave	proc	far
		.enter
		clr	cx
		.leave
		ret
CDROMDiskSave	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMDiskRestore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform whatever actions are needed before the kernel attempts
		to restore a disk handle.

		The main purpose of this function is for network FSDs that
		should ensure the drive about to be used is actually mapped
		to the same remote path it was mapped to when the disk was
		saved, or to mount the appropriate path if the kernel doesn't
		actually know what drive it will use.

CALLED BY:	DR_FS_DISK_RESTORE
PASS:		es	= FSIR locked exclusive
		ds:si	= FSSavedDisk structure.
		bx	= DriveStatusEntry for drive in which disk will be
			  sought; 0 if drive unknown
RETURN:		carry set if disk couldn't be restored:
			ax	= DiskRestoreError
			bx	= destroyed
		carry clear if disk should be ok to restore:
			bx	= DriveStatusEntry where the disk should be.
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Make sure the DriveStatusEntry is for a CD-ROM drive. If not,
		change it to the first CD-ROM drive we know of.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMDiskRestore proc	far
		.enter
	;
	; If drive is a CD-ROM, we're happy
	; 
		tst	bx
		jz	findDrive

		mov	ax, es:[bx].DSE_status
		andnf	ax, mask DS_TYPE
		cmp	ax, DRIVE_CD_ROM shl offset DS_TYPE
		je	done

findDrive:
	;
	; Look for first CD-ROM drive of which we know and use that.
	; 
		segmov	ds, dgroup, bx
		mov	al, ds:[cdromDrives][0].CDRD_number
		mov	bx, offset FIH_driveList - offset DSE_next
findDriveLoop:
		mov	bx, es:[bx].DSE_next
		tst	bx
		jz	driveNoLongerExists
		cmp	es:[bx].DSE_number, al
		jne	findDriveLoop
done:
		.leave
		ret

driveNoLongerExists:
		mov	ax, DRE_DRIVE_NO_LONGER_EXISTS
		stc
		jmp	done
CDROMDiskRestore endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMDiskLocateVolumeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine, shared by formatting and disk code, to
		locate a volume label, given a drive number and the
		address of two buffers.

CALLED BY:	CDROMDiskLocateVolume, CDROMDiskGenerateID
PASS:		dl	= drive number (0-origin)
		ss:di	= FCB to use for the search
		ss:bx	= DTA to use for the search (RenameFCB)
RETURN:		al	= 0 if found label
		ds	= ss
DESTROYED:	dx, cx, di, ah
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMDiskLocateVolumeLow proc	far
		uses	es
		.enter
		inc	dx		; make it 1-origin

	;
	; Initialize the FCB: all 0 except:
	; 	FCB_type	0xff to indicate extended FCB
	; 	FCB_attributes	indicates volume label wanted
	; 	FCB_volume	holds drive number
	;	FCB_name	set to all '?' to match any characters

		segmov	es,ss
		push	di
		mov	cx, size FCB
		clr	al
		rep	stosb
		pop	di

		mov	ss:[di].FCB_type, 0xff	; Mark as extended
		mov	ss:[di].FCB_attributes, mask FA_VOLUME; Want volume
		mov	ss:[di].FCB_volume, dl		;set drive

		push	di
		add	di, offset FCB_name
		mov	cx, size FCB_name
		mov	al,'?'
		rep 	stosb

		call	SysLockBIOS
	;
	; Set the DTA to our temporary one on the stack, here, to give DOS
	; enough work room.
	;
		segmov	ds, ss
		mov	dx, bx				; Point DOS at DTA
		mov	ah, MSDOS_SET_DTA
		call	FileInt21
	;
	; Now ask DOS to find the durn thing.
	; 
		pop	dx
		mov	ah,MSDOS_FCB_SEARCH_FOR_FIRST
		call	FileInt21
		call	SysUnlockBIOS
		.leave
		ret
CDROMDiskLocateVolumeLow endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMDiskLocateVolume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common function used for initializing a disk handle and
		renaming a disk.

CALLED BY:	INTERNAL
       		CDROMDiskInit, CDROMDiskRename
PASS:		es:si	= DiskDesc for the disk being initialized or
			  renamed.
		ss:bp	= inherited frame with
				volFCB	local	FCB
				dta	local	FCB
RETURN:		al	= 0 if volume found:
			dta filled with unopened extended FCB containing
			the volume name, suitable for copying or deleting
			= ffh if volume not found
		ds	= ss
DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMDiskLocateVolume proc near
		.enter	inherit	CDROMDiskLock
		mov	di, es:[si].DD_drive
		mov	dl, es:[di].DSE_number
		lea	di, ss:[volFCB]
		lea	bx, ss:[dta]
		call	CDROMDiskLocateVolumeLow
		.leave
		ret
CDROMDiskLocateVolume endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMDiskLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the given disc is in the drive.

CALLED BY:	DR_FS_DISK_LOCK
PASS:		es:si	= DiskDesc for the disk to be locked in
		al	= FILE_NO_ERRORS bit set if disk lock may not
			  be aborted by the user.
RETURN:		carry set if disk could not be locked
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	12/27/00 ayuen: To avoid some deadlock problem in some DOS IFS drivers,
	the kernel is now changed to not grab/release DSE_lockSem around calls
	to DR_FS_DISK_LOCK, such that the IFS driver can decide whether or not
	to enforce mutual-exclusion.  For CDROM driver we need to grab/release
	the semaphore ourselves.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMDiskLock	proc	far
volFCB		local	FCB		; FCB we need to use to locate the
					;  volume label (DOS 2.X has bugs with
					;  4eh(cx=FA_VOLUME))
dta		local	FCB		; DTA for DOS to use during volume
					;  location (needs an unopened
					;  extended FCB).
		uses	bx, cx, dx, ds
		.enter
		mov	bx, es:[si].DD_drive
		push	bx		; save DriveStatusEntry nptr
		PSem	es, [bx].DSE_lockSem, TRASH_BX
getID:
	;
	; Fetch the volume ID for the disk, which the MSCDEX docs claim is a
	; fairly lightweight operation...
	; 
		push	ax
		call	CDROMUtilSetFailOnError
		call	CDROMDiskLocateVolume
		call	CDROMUtilClearFailOnError
		tst	al
		pop	ax
		jnz	checkUnnamed		; al <> 0 means no
						; label found

		tst	ss:[dta].FCB_name[0]	; duplicate check done in
		jz	checkUnnamed		;  DR_FS_DISK_INIT in primary
	;
	; Map the name in-place
	; 
		push	ds, ax
		push	es, si
		segmov	es, ss, ax
		mov	ds, ax
		lea	si, ss:[dta].FCB_name
		mov	dx, si
		mov	di, DR_DPFS_MAP_VOLUME_NAME
		push	bp
		call	CDROMCallPrimary
		pop	bp
		pop	es, di
		push	di
		add	di, offset DD_volumeLabel
		mov	cx, size DD_volumeLabel
		repe	cmpsb
		pop	si
		pop	ds, ax
		jne	promptForDisk
done:
		pop	bx		; es:bx = DriveStatusEntry
		VSem	es, [bx].DSE_lockSem, TRASH_AX_BX
		.leave
		ret
checkUnnamed:
	;
	; If disk has no volume label, but the one we're looking for did,
	; ask for the disk.
	; 
		test	es:[si].DD_flags, mask DF_NAMELESS
		jz	promptForDisk
	;
	; Else use the ID generated from the VTOC instead.
	; 
		push	ax, si
		mov	si, es:[si].DD_drive
		call	CDROMDiskGenerateID
		pop	ax, si
		cmp	cx, es:[si].DD_id.high
		jne	promptForDisk
		cmp	dx, es:[si].DD_id.low
		je	done

promptForDisk:
	;
	; Ask the user to insert the disk after releasing the boot sector
	; and recovering the flag that says whether the user may abort
	; the lock.
	; 
		call	FSDAskForDisk
		jc	done		; => user canceled, so we're done
		jmp	getID		; else make sure the user put the
					;  right disk in...
CDROMDiskLock	endp

Resident	ends
