COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		msnetDisk.asm

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
		

	$Id: msnetDisk.asm,v 1.1 97/04/10 11:55:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetDiskID
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
MSNetDiskID	proc	far
		.enter
		clr	cx		; (clears carry)
		mov	dx, cx		; ID is always 0...
		mov	al, mask DF_WRITABLE or mask DF_ALWAYS_VALID
		mov	ah, MEDIA_FIXED_DISK
		.leave
		ret
MSNetDiskID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetDiskRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to rename a disk. Lantastic doesn't allow this, so
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
MSNetDiskRename	proc	far
		.enter
		mov	ax, ERROR_ACCESS_DENIED
		stc
		.leave
		ret
MSNetDiskRename	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetDiskSave
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
	locate the redirection list entry for the drive
		- if none, return carry set and cx == 0
	figure the length of the target path
	if there's enough room, copy it in,
	else return carry set
	cx <- length of the target path
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSNetDiskSave	proc	far
spaceAvail	local	word		push	cx
privData	local	fptr		push	es, dx
devName		local	MSNetDeviceName
targPath	local	MSNetPath
driveLetter	local	char
		uses	ds, si, bx, dx, ax, es
		.enter
	;
	; Fetch the drive letter from the name, so we don't need the DSE
	; again.
	; 
		mov	si, ds:[bx].DD_drive
		mov	al, ds:[si].DSE_name[0]
		mov	ss:[driveLetter], al
	;
	; Set up for the loop:
	; 	ds:si	<- buffer for device name
	; 	es:di	<- buffer for target path
	; 	bx	<- list entry # (0 for first)
	; 	
		clr	bx
		segmov	ds, ss, ax
		mov	es, ax
		lea	si, ss:[devName]
		lea	di, ss:[targPath]
findDriveLoop:
	;
	; Fetch the next entry from the redirection list.
	; 
		push	bx, bp
		mov	ax, MSDOS_GET_REDIRECTED_DEVICE
		call	FileInt21
		mov	cx, bx
		pop	bx, bp
		jc	cantSave		; => device not redirected

		cmp	cx, MSNDT_DISK
		jne	nextEntry
	;
	; Entry is for a disk. See if it's for our disk.
	; 
		lodsb
		cmp	al, ss:[driveLetter]
		je	foundIt
		dec	si		; nope -- back up ds:si to start
					;  of the buffer
nextEntry:
		inc	bx
		jmp	findDriveLoop

foundIt:
	;
	; Found the entry. See how long the target path is.
	; 
		mov	si, di		; ds:si <- path buffer, for copy
		clr	al
		mov	cx, -1
		repne	scasb
		not	cx		; cx <- chars needed, including null
		cmp	ss:[spaceAvail], cx
		jb	done		; not enough room,
	;
	; Copy the entire target path in, including null.
	; 
		les	di, ss:[privData]
		push	cx		; save # bytes used
		rep	movsb
		pop	cx
		; (carry already clear from compare with spaceAvail)
done:
		.leave
		ret
cantSave:
		mov	cx, 0		; no amount would help, as drive isn't
					;  redirected
		jmp	done		; (carry still set)
MSNetDiskSave	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetDiskRestore
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
		Saved data is just the target path. Run through the list
		of redirected devices looking for one redirected to that
		path.
		
		If none found, find a free drive and redirect it to the
		stored path.
		
		If found, locate the DSE for the device and return it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSNetDiskRestore	proc	far
savedData	local	fptr.FSSavedDisk push ds, si
fsir		local	sptr		push es
dse		local	word		push bx	; existing DSE for the saved
						;  disk, if any
devName		local	MSNetDeviceName
targPath	local	MSNetPath
		uses	cx, dx, si, di, ds, es
		.enter
		segmov	ds, ss, ax
	;
	; Look for a drive redirected to the same place as the saved disk was
	; using our by-now-standard loop to examine all redirected devices.
	; 
		mov	es, ax
		lea	si, ss:[devName]
		lea	di, ss:[targPath] 
		mov	bx, -1
findDriveLoop:
		inc	bx
		push	bp, bx
		mov	ax, MSDOS_GET_REDIRECTED_DEVICE
		call	FileInt21
		mov	cx, bx
		pop	bp, bx
		jc	notMapped
		cmp	cx, MSNDT_DISK
		jne	findDriveLoop
	;
	; Found a redirected disk. See if it's going to the same place.
	; 
		push	ds, si, di
		lds	si, ss:[savedData]
		add	si, ds:[si].FSSD_private	; ds:si <- our private
							;  data
compareLoop:
		lodsb
		scasb
		jne	endCompare
		tst	al
		jnz	compareLoop
endCompare:
		pop	ds, si, di
		jne	findDriveLoop
	;
	; Found a drive mapped there. Find its DSE and return it.
	; 
		mov	es, ss:[fsir]
		mov	dx, si
		call	DriveLocateByName
EC <		ERROR_C	MAPPED_DRIVE_UNKNOWN_TO_KERNEL			>
EC <		tst	si						>
EC <		ERROR_Z	MAPPED_DRIVE_UNKNOWN_TO_KERNEL			>
		mov	bx, si		; return DSE offset in bx
done:
		.leave
		ret

notMapped:
	;
	; Well, the thing isn't currently mapped. If the drive the thing was
	; mapped to when it was saved is unclaimed, try and map the target
	; path there.
	; 
		tst	ss:[dse]
		jnz	findAvailDrive
		
		lds	si, ss:[savedData]
		add	si, FSSD_driveName	; ds:si <- drive name (followed
						;  by colon)
		call	tryMapDrive
		jnc	done

findAvailDrive:
	;
	; Couldn't map to drive it was on before, for one reason or another, so
	; find an open drive to which we can map the thing.
	; 
		segmov	ds, ss
		lea	si, ss:[devName]
		mov	{word}ds:[si+1], ':'	; all names are single-letter,
						;  so set up trailing colon and
						;  null-term at start
		clr	al			; start with drive A
findAvailDriveLoop:
		call	DriveGetStatus
		jnc	nextDrive

	;
	; Drive doesn't exist. Convert number to letter and try to map
	; the target path there.
	; 
		add	al, 'A'
		mov	ds:[si], al
		call	tryMapDrive
		jnc	done
		sub	al, 'A'			; convert back to number
						;  (DO NOT PUSH AX AROUND
						;  THE CALL TO tryMapDrive)
nextDrive:
		inc	ax
		cmp	al, 'Z' - 'A'		; out of single-letter drives?
		jbe	findAvailDriveLoop	; no
		mov	ax, DRE_ALL_DRIVES_USED
		clr	bx
		stc
		jmp	done

	;--------------------
	;Pass:		ds:si	= MSNetDeviceName to try and map
	;Return:	carry set on error
	;		carry clear if ok:
	;			bx	= DSE offset
	;			si, es, di = destroyed
	;Destroyed:	cx, dx
	;Notes:		if mapping fails owing to access problems or not
	;		being connected, this routine will not return. It
	;		will vault to done all by itself, so don't leave
	;		anything on the stack before calling it.
tryMapDrive:
		push	ax
		mov	ax, MSDOS_REDIRECT_DEVICE
		mov	bl, MSNDT_DISK
		clr	cx			; lantastic wants 0, so we'll
						;  accommodate it
		les	di, ss:[savedData]	; es:di <- target path
		add	di, es:[di].FSSD_private
		call	FileInt21
		jnc	mapSuccessful
	;
	; Failed. If access was denied, don't try futher, but return an
	; appropriate error message.
	; 
		cmp	ax, ERROR_ACCESS_DENIED
		je	accessDenied
		cmp	ax, ERROR_NETWORK_NOT_LOGGED_IN
		je	notConnected
		cmp	ax, ERROR_FILE_NOT_FOUND
		je	noLongerExists
		stc		; some other error, keep trying
mapDone:
		pop	ax
		retn		

accessDenied:
		mov	ax, DRE_PERMISSION_DENIED
mapError:
		add	sp, 4		; discard saved AX and return
					;  address
		clr	bx		; drive doesn't exist
		stc
		jmp	done
notConnected:
		mov	ax, DRE_NOT_ATTACHED_TO_SERVER
		jmp	mapError

noLongerExists:
		mov	ax, DRE_DRIVE_NO_LONGER_EXISTS
		jmp	mapError

mapSuccessful:
	;
	; Map succeeded, so create an entry for it.
	; 
		mov     cx, DriveExtendedStatus <
				0,              ; drive may be available over
						;  net
				0,              ; drive not read-only
				0,              ; drive cannot be formatted
				0,              ; drive not an alias
				0,              ; drive not busy
				<
				    1,          ; drive is present
				    0,          ; assume not removable
				    1,          ; assume is network
				    DRIVE_FIXED ; assume fixed
				>
			>
	    ;
	    ; Copy the device name someplace where we can trim the trailing
	    ; colon. Also gives us a way to get the drive number conveniently.
	    ; 
		mov	al, ds:[si]
		clr	ah
		mov	{word}ss:[devName], ax

		call	LoadVarSegDS
		mov	dx, ds:[fsdOffset]

		segmov	ds, ss
		lea	si, ss:[devName]	; ds:si <- drive name
		sub	al, 'A'			; al <- drive #
		mov	ah, MEDIA_FIXED_DISK	; ah <- default media
		clr	bx			; no private data needed
		call	FSDInitDrive
		mov	bx, dx			; bx <- DSE
	;
	; Fixup saved segment address of FSIR for return.
	; 
		call	FSDDerefInfo
		mov	ss:[fsir], ax
		clc
		jmp	mapDone
MSNetDiskRestore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetCheckNetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to create a disk handle here, possibly, and map the
		path to an appropriate drive...

CALLED BY:	DR_FS_CHECK_NET_PATH
PASS:		ds:dx	= path to check
		es	= FSInfoResource locked shared.
RETURN:		carry set if path belongs to this net but cannot be reached
			(e.g. not logged into the server)
		carry clear if call ok:
			bx	= disk handle to use, 0 if path not ours
			ds:dx	= file path to actually use (may be different,
				  but doesn't have to be)
			es	= new location of FSIR if disk handle had
				  to be allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSNetCheckNetPath proc	far
		.enter
		clr	bx		; not ours, for now
		.leave
		ret
MSNetCheckNetPath endp


Resident	ends
