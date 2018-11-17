COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		netwareDisk.asm

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
		

	$Id: netwareDisk.asm,v 1.1 97/04/10 11:55:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskID
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
NWDiskID	proc	far
		.enter
		clr	cx		; (clears carry)
		mov	dx, cx		; ID is always 0...
		mov	al, mask DF_WRITABLE or mask DF_ALWAYS_VALID
		mov	ah, MEDIA_FIXED_DISK
		.leave
		ret
NWDiskID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskGetRootPathForDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the root path for a drive, given its drive number.
		Static global buffers are used during the determination, 
		and the result is left in a static buffer, so appropriate
		synchronization should be used before calling this routine
		(grabbing the working directory at the minimum).

CALLED BY:	(INTERNAL) NWDiskGetRootPath, NWDiskRestore
PASS:		dx	= drive number (0-origin)
RETURN:		carry clear if root path gotten ok:
			ds:dx	= start of path
			ds:di	= null char at the end of the path
		carry set on error
DESTROYED:	ax, cx
SIDE EFFECTS:	nwDiskInitRequestBuffer and nwDiskInitReplyBuffer overwritten

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskGetRootPathForDrive proc	far
		uses	es, si, bx
		.enter
		mov	ax, NFC_GET_DIRECTORY_HANDLE
		call	FileInt21	; al <- dir handle
EC <		tst	al						>
EC <		ERROR_Z	DRIVE_NO_LONGER_VALID				>
	;
	; (2) map that to a path
	; 
		call	LoadVarSegDS
		mov	ds:[nwDiskInitRequestBuffer].NREQBUF_GDP_dirHandle, al
		mov	si, offset nwDiskInitRequestBuffer
		segmov	es, ds
		mov	di, offset nwDiskInitReplyBuffer
		mov	ax, NFC_GET_DIRECTORY_PATH
		call	FileInt21
		tst	al
		jnz	error
	;
	; (3) get the current directory for the drive. DX should still hold the
	; drive number...
	; 
		sub	sp, MSDOS_PATH_BUFFER_SIZE
		segmov	ds, ss
		mov	si, sp
		inc	dx		; 1-origin drive #
		mov	ah, MSDOS_GET_CURRENT_DIR
		call	FileInt21
	;
	; Count the number of characters in the returned path.
	; 
		clr	cx, ax
countCurDirLoop:
		lodsb
		tst	al
		loopne	countCurDirLoop
		segmov	ds, es
		add	sp, MSDOS_PATH_BUFFER_SIZE	; clear stack
		not	cx		; cx <- # bytes w/o null
	;
	; Now point DI to the end of the final component.
	; 
		mov	al, ds:[nwDiskInitReplyBuffer].NREPBUF_GDP_pathLength
		add	di, ax
		add	di, offset NREPBUF_GDP_path	; di <- end of the path
							;  returned by NW
		sub	di, cx		; reduce di by length of DOS string.
	;
	; ds:di points to the start of the first component not part of the
	; drive's root path. It will point beyond a forward slash or colon if
	; the current directory for the drive isn't the root, or if the current
	; dir *is* the root, but the root is a volume, not a directory on the
	; volume. It will point past a real character that's part of the path,
	; however, if the root of the drive is a directory on a volume. What
	; does this mean to you? It means if the char before ds:di is a
	; backslash or a colon, we want to biff it, else we want to leave di
	; right where it is.
	; 

		cmp	{char}ds:[di-1], '/'
		je	trimTrailer
		cmp	{char}ds:[di-1], ':'
		jne	done
trimTrailer:
		dec	di
done:
		mov	{char}ds:[di], 0	; null-terminate
		mov	dx, offset nwDiskInitReplyBuffer.NREPBUF_GDP_path
		clc
exit:
		.leave
		ret
error:
		stc
		jmp	exit
NWDiskGetRootPathForDrive endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskGetRootPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the root path for a drive. Static global buffers are
		used during the determination, and the result is left in
		a static buffer, so appropriate synchronization should be 
		used before calling this routine (grabbing the working
		directory at the minimum).

CALLED BY:	(INTERNAL) NWDiskInit, NWDiskSave
PASS:		es:si	= DiskDesc for the drive of which the root path is
			  desired
RETURN:		carry clear if root path gotten ok:
			ds:dx	= start of path
			ds:di	= null char at the end of the path
		carry set on error
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskGetRootPath proc	far
		.enter
	;
	; push and set preferred server connection to that for the drive
	; in question
	; 
		call	NWChangePreferredServer
		push	ax
	;
	; get the directory handle for the drive.
	; 
		mov	bx, es:[si].DD_drive
		clr	dx
		mov	dl, es:[bx].DSE_number
	;
	; Call common routine, now we have the drive number.
	; 
		call	NWDiskGetRootPathForDrive
	;
	; Restore preferred server from entry.
	; 
		call	NWRestorePreferredServer	; (clears stack)
		.leave
		ret
NWDiskGetRootPath endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWLockCWD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain exclusive access to DOS's working directory

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	flags, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWLockCWD	proc	far
		uses	bp
		.enter
		mov	di, DR_DPFS_LOCK_CWD
		call	NWCallPrimary
		.leave
		ret
NWLockCWD	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWUnlockCWD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive access to DOS's working directory

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	di (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWUnlockCWD	proc	far
		uses	bp
		.enter
		pushf
		mov	di, DR_DPFS_UNLOCK_CWD
		call	NWCallPrimary
		popf
		.leave
		ret
NWUnlockCWD	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a new disk handle with the remaining pertinent
		information. The FSInfoResource is locked for exclusive access
		and its segment is passed in ES for use by the driver.

CALLED BY:	DR_FS_DISK_INIT
PASS:		es:si	= DiskDesc for the disk, with all fields but
			  DD_volumeLabel filled in. DD_private is 0.
		ah	= FSDNamelessAction to be passed to FSDGenNameless if
			  the disk has no volume label.
RETURN:		carry set on failure
		carry clear on success
			es	= fixed up if a chunk was allocated by the FSD
			DD_volumeLabel filled in.
			DD_private holding the offset of a chunk of private
				data, if one was allocated.
DESTROY:	nothing

PSEUDO CODE/STRATEGY:
		This is kinda fun. Rather than just consulting DOS to get
		the volume name of the NW volume on which the thing is located,
		it seems more useful to use the final component of the path
		to which the root of the drive is mapped, making it much
		easier to differentiate among the various drives, if the sysop
		has set things up correctly.
		
		The way we find what the root directory is is somewhat
		complicated:
			1) get the directory handle for the drive in which
			   the disk is located
			2) map that to a path
			3) get the DOS working directory for the drive and
			   remove that from the end of the path obtained in (2)
			4) skip the final character (either a : or a /) and
			   search backward for the start of the last component
			   (a / or the start of the string) and use what we
			   get from that as the volume name.

		Since our caller has so kindly locked the FSIR for exclusive
		access, we needn't worry about the DOS working directory lock.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskInit	proc	far
		uses	bx, ax, dx, cx, es, ds, si
		.enter
	;
	; No longer protected by exclusive access to the FSIR, so grab the
	; CWD lock in the primary.
	; 
		call	NWLockCWD
		
		call	NWDiskGetRootPath
		jc	done
	;
	; Look for the start of the component. This is either the start of the
	; returned path, or the first forward-slash or colon before the end of
	; the component.
	; 
		push	si		; save DiskDesc offset
		lea	si, [di-1]	; point to last char of component

		std
findComponentStartLoop:
		cmp	si, dx
		je	foundStart
		lodsb
		cmp	al, '/'		; NW uses forward-slash as separator...
		je	foundSeparator
		cmp	al, ':'
		jne	findComponentStartLoop
foundSeparator:
		inc	si		; point SI back to the start of
		inc	si		;  the component.
foundStart:
		cld
	;
	; Now copy the component into the DD_volumeLabel field of the new
	; DiskDesc.
	; 
		mov	cx, di
		sub	cx, si		; cx <- # chars in component
		pop	di		; es:di <- DiskDesc
		add	di, offset DD_volumeLabel
	;
	; Figure by how much the final component will over- or under-flow
	; DD_volumeLabel, adjusting CX down if it will over-flow.
	; 
		mov	bx, size DD_volumeLabel
		sub	bx, cx
		jae	copyName
		mov	cx, size DD_volumeLabel

copyName:
if DBCS_PCGEOS
		push	bx, di
		mov	ah, FSCSF_CONVERT_TO_GEOS
		sub	sp, size FSConvertStringArgs
		mov	bx, sp
		movdw	ss:[bx].FSCSA_source, dssi
		movdw	ss:[bx].FSCSA_dest, esdi
		mov	ss:[bx].FSCSA_length, cx
		mov	di, DR_FS_CONVERT_STRING
		call	NWCallPrimary
		add	sp, size FSConvertStringArgs
		pop	bx, di
		sub	bx, cx		; num bytes to be filled with space
		shl	cx
		add	di, cx
		shr	bx		; num words to be filled with space

else	; SBCS
		rep	movsb
endif	;DBCS
	;
	; Now space-pad DD_volumeLabel the rest of the way, if any.
	; 
		tst	bx		; (clears carry)
		jle	done
		mov	cx, bx
		LocalLoadChar	ax, ' '
SBCS<		rep	stosb>
DBCS<		rep	stosw>
done:
		call	NWUnlockCWD
		.leave
		ret
NWDiskInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to rename a disk. NetWare doesn't allow this, so
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
NWDiskRename	proc	far
		.enter
		mov	ax, ERROR_ACCESS_DENIED
		stc
		.leave
		ret
NWDiskRename	endp
Resident	ends

Transient	segment	resource	; these should be ok to be movable,
					;  even the DISK_RESTORE thing, as
					;  having the FSIR locked exclusive
					;  should grant access to all drives
					;  we might need (only concern is for
					;  disk being formatted, but we won't
					;  be on such a disk [format would have
					;  been refused], so...)

transientDgroup	sptr	dgroup
Transient_LoadVarSegDS	proc	near
		mov	ds, cs:[transientDgroup]
		ret
Transient_LoadVarSegDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskSave
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
	check there's enough room and bail if not
	lock CWD
	change to disk's drive
	change to root
	get connection ID
	get server name & copy into data
	get drive dir handle
	save dir handle
	copy data into saved-disk data
	inval cur path in primary IFSD
	unlock CWD
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskSave	proc	far
spaceAvail	local	word		push	cx
rootPath	local	fptr.char
		uses	ds, si, bx, dx, ax
		.enter
	;
	; Lock CWD so we can play games.
	; 
		call	NWLockCWD
	;
	; Fetch the path of the root directory.
	; 
		push	es, dx
		segmov	es, ds
		mov	si, bx
		call	NWDiskGetRootPath
		movdw	ss:[rootPath], dsdx
	;
	; Get drive's connection.
	; 
		mov	si, es:[si].DD_drive
		clr	bx
		mov	bl, es:[si].DSE_number

		mov	ax, NFC_GET_DRIVE_CONNECTION_ID_TABLE
		call	FileInt21	; es:si <- connection ID table
		mov	bl, es:[si][bx]
EC <		tst	bl						>
EC <		ERROR_Z	DRIVE_NO_LONGER_VALID				>
	;
	; Locate the server name for that connection.
	; 
		mov	ax, NFC_GET_FILE_SERVER_NAME_TABLE
		call	FileInt21	; es:si <- server name table
		dec	bx		; make connection 0-origin
		CheckHack <size NetWareFileServerName eq 48>
		shl	bx
		shl	bx
		shl	bx
		shl	bx
		add	si, bx
		shl	bx
		add	si, bx

		segmov	ds, es
		pop	es, di
		mov	cx, ss:[spaceAvail]
	;
	; Copy server name into private data.
	; 
		call	copyNullTerm
	;
	; Copy root path into private data.
	; 
		lds	si, ss:[rootPath]
		call	copyNullTerm
	;
	; Figure number of bytes we used. CX continued to decrement even
	; after we used up all the space available, if such we did.
	; 
		mov_tr	ax, cx
		mov	cx, ss:[spaceAvail]
		sub	cx, ax

		tst	ax		; did it all fit?
		jge	done		; yes
		stc			; no -- return error
done:
	;
	; Release the working directory.
	; 
		call	NWUnlockCWD
		.leave
		ret

	;--------------------
	; Copy the null-terminated string at ds:si to es:di, being careful
	; not to overflow the space we were given, yet still keeping track of
	; how much we'd actually need.
	;
	; Pass:
	; 	ds:si	= null-terminated string
	; 	es:di	= place to which to copy it
	; 	cx	= bytes available
	; Return:
	; 	es:di	= advanced beyond copy (with null copied over) or to
	;		  end of available space, whichever comes first.
	; 	ds:si	= advanced beyond string
	; 	cx	= reduced by length of string, whether it was copied
	;		  or not.
	; Destroyed:
	; 	al
copyNullTerm:
		lodsb			; fetch next char
		tst	cx		; any room?
		jle	checkEnd	; no
		stosb			; yes -- store it
checkEnd:
		dec	cx		; another byte used
		tst	al		; end of the string?
		jnz	copyNullTerm	; no
		retn
NWDiskSave	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskRestore
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
			ax	= DiskRestoreErrors
			bx	= destroyed
		carry clear if disk should be ok to restore:
			bx	= DriveStatusEntry where the disk should be.
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Saved data are two null-terminated strings. The first is
		the name of the server on which the disk was located. The
		second is the path to the root of the drive, as returned by
		NWDiskGetRootPath.
		
		Eventually:
			locate the server whose name is in the saved data
			if couldn't find server, then error
			push and set the current preferred connection
			restore the directory handle
			get the path for the directory handle
			run through all existing drives looking for one whose
				path matches the one we've got.
			if found, return that DSE
			if none found, find an unused drive letter and map
				this handle to that drive letter, creating
				the DSE. The mapping should be temporary,
				I think.
			restore the preferred connection

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskRestore	proc	far
savedData	local	fptr.FSSavedDisk push ds, si
fsir		local	sptr		push es
dse		local	word		push bx	; existing DSE for the saved
						;  disk, if any
serverCon	local	byte			; connection ID of saved
						;  server
	ForceRef serverCon
dirPath		local	fptr.char
	ForceRef dirPath
		uses	cx, dx, si, di, ds
		.enter
		call	NWLockCWD
	;
	; Locate the server in the server name table.
	; 
		call	NWDiskRestoreLocateServer
		jc	done
		push	ax			; save old preferred connection
	;
	; Locate something mapped to the same place, if possible.
	; 
		call	NWDiskRestoreLocateExistingDrive
		jc	doneRestorePrefCon
		tst	bx
		jnz	doneRestorePrefCon

	;
	; No dice. See if the drive to which this thing was mapped has been
	; taken.
	; 
		call	Transient_LoadVarSegDS

		tst	ss:[dse]
		jnz	findAvailDrive		; => drive already taken
		
		les	si, ss:[savedData]
SBCS <		mov	bl, es:[si].FSSD_driveName[0]>
SBCS <		sub	bl, 'A'>
DBCS <		mov	bx, es:[si].FSSD_driveName[0]>
DBCS <		sub 	bx, 'A'>
		clr	bh
		call	mapDriveIfPossible
		jnc	doneRestorePrefCon

findAvailDrive:
	;
	; Couldn't map to drive it was on before for one reason or another, so
	; find an open drive to which we can map the thing.
	;
	; XXX: START WITH THE TEMP DRIVES AND CYCLE BACK TO PERMANENTS?
	; 
		clr	al
findAvailDriveLoop:
		call	DriveGetStatus
		jnc	nextDrive		; => drive exists
		mov	bl, al
		call	mapDriveIfPossible
		jnc	doneRestorePrefCon
nextDrive:
		inc	ax
		cmp	al, NW_MAX_NUM_DRIVES
		jne	findAvailDriveLoop

		clr	bx
doneRestorePrefCon:
		call	NWRestorePreferredServer
done:
	;
	; Reload ES with FSIR, in case we created a drive entry and caused the
	; thing to shift.
	; 
		mov	es, ss:[fsir]
		call	NWUnlockCWD
		.leave
		ret

	;--------------------
	; Try and map the path to the given drive
	;
	; Pass:
	; 	bl	= 0-based drive number
	; 	ds	= dgroup
	; Return:
	; 	carry set on failure
	; 		bx	= destroyed
	; 	carry clear on success:
	; 		bx	= offset of new DSE
	; Destroyed:
	; 	dx, cx, si
mapDriveIfPossible:
	;
	; Ask netware to map the thing as the root of the passed drive.
	; 
		push	ax

		inc	bx		; change to 1-origin
		mov	dx, offset nwDiskInitReplyBuffer.NREPBUF_GDP_path
		mov	ax, NFC_MAP_ROOT
		call	FileInt21
		jc	mapDriveDone
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
		mov	dx, ds:[fsdOffset]
		mov	si, offset nwNormalDriveName	; assume in lower 26
		dec	bx			; back to 0-origin
		mov	al, bl			; al <- drive #
		mov	ah, MEDIA_FIXED_DISK	; ah <- default media
		add	bl, 'A'			; convert to letter
		cmp	bl, 'Z'
		jbe	allocDrive

		sub	bl, 'Z'-'1'
		mov	si, offset nwSpecialDriveName
allocDrive:
SBCS <		mov	ds:[nwNormalDriveName], bl>
DBCS <		clr bh>
DBCS <		mov	ds:[nwNormalDriveName], bx>
		clr	bx			; no private data needed
		call	FSDInitDrive
		mov	bx, dx
	;
	; Fixup saved segment address of FSIR for return.
	; 
		call	FSDDerefInfo
		mov	ss:[fsir], ax
		clc
mapDriveDone:
		pop	ax
		retn
NWDiskRestore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskRestoreLocateServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the server for the saved disk and establish its
		connection as the preferred one.

CALLED BY:	(INTERNAL) NWDiskRestore
PASS:		ss:bp	= inherited frame
		ds:si	= FSSavedDisk
RETURN:		carry set on error:
			ax	= DiskRestoreError
		carry clear if ok:
			ax	= previous preferred connection ID
			ss:[serverCon] = set
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskRestoreLocateServer proc	near
		.enter	inherit	NWDiskRestore
	;
	; Locate the file server name table.
	; 
		push	si
		mov	ax, NFC_GET_FILE_SERVER_NAME_TABLE
		call	FileInt21		; es:si <- name table
		mov	di, si
		pop	si
	;
	; Point ds:si at the name of the server in the saved data.
	; 
		add	si, ds:[si].FSSD_private
		mov	cx, NW_MAX_SERVERS
findConnectionLoop:
	;
	; See if this entry in the table matches the saved server name.
	; Both are null-terminated, unless both are the maximum length.
	; 
		push	si, di, cx
		mov	cx, size NetWareFileServerName
compareLoop:
		lodsb
		tst	al		; end of saved name?
		jz	endOfSavedName	; yes -- confirm end of table name
		scasb
		loope	compareLoop
		jmp	nextServer
endOfSavedName:
		scasb			; confirm table entry at null too
nextServer:
		pop	si, di, cx
		je	haveServer
	;
	; Didn't match -- advance to the next entry in the name table.
	; 
		add	di, size NetWareFileServerName
		loop	findConnectionLoop

		clr	cx		; indicate server not in table
attach:
		call	NWDiskRestoreAttachAsGuest
		jnc	haveConnection
	;
	; Didn't find server in the table, so return appropriate error.
	; 
		mov	ax, DRE_NOT_ATTACHED_TO_SERVER
		stc
		jmp	done
haveServer:
	;
	; Have the server, so convert that to a connection ID.
	; 
		sub	cx, NW_MAX_SERVERS+1
		neg	cx		; cx <- connection # (1-origin)
	;
	; Make sure the connection is active. Is this necessary?
	; 
		push	bx, si
		mov	ax, NFC_GET_CONNECTION_ID_TABLE
		call	FileInt21
			CheckHack <size NetWareConnectionIDTableItem eq 32>
		mov	bx, cx
		shl	bx
		shl	bx
		shl	bx
		shl	bx
		shl	bx
		tst	es:[si][bx-NetWareConnectionIDTableItem].NCITI_slotInUse		
		pop	bx, si
		jz	attach
haveConnection:
	;
	; Switch to that connection as the preferred one, saving the old
	; value.
	; 
		mov	ax, NFC_GET_PREFERRED_CONNECTION_ID
		call	FileInt21
		push	ax
		mov	dl, cl
		mov	ss:[serverCon], cl
		mov	ax, NFC_SET_PREFERRED_CONNECTION_ID
		call	FileInt21
		pop	ax
		clc
done:
		.leave
		ret
NWDiskRestoreLocateServer endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskRestoreAttachAsGuest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach to the indicated server as a guest user.

CALLED BY:	(INTERNAL) NWDiskRestoreLocateServer
PASS:		ds:si	= server name
		cl	= connection number to use (0 if server not in table)
RETURN:		carry clear if successful:
			cl	= connection number
		carry set if error
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskRestoreAttachAsGuest	proc	near
serverName	local	fptr	push	ds, si
netAddr		local	NovellNodeSocketAddrStruct
serverNameLen	local	byte
emptySlot	local	byte
emptySlotOff	local	word
connIDTable	local	fptr
		uses	bx,dx,ds,si,es,di
		.enter

		tst	cl
		jz	addToTables

		;server in shell tables already
		mov	emptySlot, cl
		jmp 	doAttach

addToTables:
	;
	; Need to add the server to the shell's server table, using the
	; current preferred server to find the address of the server to
	; which we wish to attach.
	; 
	; First get the server name length
	;
		mov	cx, length NetWareFileServerName

countLoop:
		lodsb
		tst	al
		loopnz	countLoop
		mov	ax, 2			; assume name too long
		jnz	error
		
		sub	cx, length NetWareFileServerName
		not	cx			; don't include null

		mov	serverNameLen, cl
	;
	; Now get the net address of server
	; 
		lds	si, serverName
		lea	dx, ss:[netAddr]

		call 	NWDiskRestoreGetNetAddr

		tst 	al
		jnz	error

	;
	; Ok. Now we've got the server's address & name, we need to find a free
	; slot in the connection id table for this new connection.
	;
	; Called function sets ss:[emptySlotOff] && ss:[emptySlot] &&
	; ss:[connIDTable]
	; 
		call	NWDiskRestoreFindEmptyConnectionSlot
		jc	error
	;
	; Now figure, for some ungodly reason, the order number of the server
	; relative to the other elements in the table. 1 is the lowest address,
	; while 8 is the highest.
	; 
	; see NetWare doc. on how order numbers work.
	; this algorithm is copied from the ICLAS algorithm
	;
		call	NWDiskRestoreComputeOrderNumber	; dl <- order number
	;
	; Initialize the connection-table entry we found.
	; 
		mov	es, ss:[connIDTable].segment
		mov	di, ss:[emptySlotOff]	; es:di <- entry

		mov	es:[di].NCITI_slotInUse, 0xff
		mov	es:[di].NCITI_serverOrderNumber, dl
	    ;
	    ; Copy in the server's network address.
	    ; 
		add	di, NCITI_serverAddress
		segmov	ds, ss
		lea	si, ss:[netAddr]
		mov	cx, size NovellNodeSocketAddrStruct
		rep	movsb 
	;
	; Initialize the corresponding slot in the server name table.
	; 
		mov	ax, NFC_GET_FILE_SERVER_NAME_TABLE
		call	FileInt21

		;es:si = server name table
		;set es:di = offset into unused slot
		mov	al, ss:[emptySlot]	;numbering starts at 1
		dec	al			;decrement to calc. offset
		mov	ah, size NetWareFileServerName
		mul	ah
		mov	di, si
		add	di, ax

		lds	si, ss:[serverName]

		clr	cx
		mov	cl, serverNameLen
		rep	movsb 
		clr	al			; null-terminate...
		stosb

doAttach:	
	;
	; now call NetWare attach interrupt call.
	;
		mov	dl, ss:[emptySlot]
		mov	ax, NFC_ATTACH_TO_FILE_SERVER
		call	FileInt21
		clr	ah
		
		tst	al
		stc
		jnz	error
	;
	; Finally, attempt to log in as GUEST with no password.
	; 
		call	NWDiskRestoreLoginAsGuest
		jc	error

		clr 	cx
		mov	cl, ss:[emptySlot]
error:
		.leave
		ret
NWDiskRestoreAttachAsGuest endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskRestoreLoginAsGuest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to login to the server as GUEST

CALLED BY:	(INTERNAL) NWDiskRestoreAttachAsGuest
PASS:		ss:[emptySlot]	= connection ID of attached server
RETURN:		carry set on error
			server detached
		carry clear if ok:
			user logged in as guest
DESTROYED:	ax, bx, cx, dx, si, di, es, ds
SIDE EFFECTS:	user will (eventually) be notified of his/her attachment
     		as GUEST on the indicated server...

PSEUDO CODE/STRATEGY:
		set preferred server to newly-attached
		construct request buf

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		even
nwDiskLoginVars	label	byte
		word	nwDiskLoginEndReqBuf-nwDiskLoginVars-2
		byte	low NFC_LOGIN_TO_FILE_SERVER
		NetObjectType	NOT_USER
		byte	length nwDiskLoginGuestName
nwDiskLoginGuestName char	'GUEST'
		byte	0		; password length
nwDiskLoginEndReqBuf	label byte

nwDiskLoginReply word	0
		even
nwDiskEndLoginVars	label	byte

NWDiskRestoreLoginAsGuest proc	near
		.enter	inherit	NWDiskRestoreAttachAsGuest
	;
	; Establish the newly-attached server as the preferred one, saving
	; the current preferred connection ID.
	;
	; We've got the FSIR exclusive at this point, so this is safe.
	; 
		mov	ax, NFC_GET_PREFERRED_CONNECTION_ID
		call	FileInt21
		push	ax
		mov	dl, ss:[emptySlot]
		mov	ax, NFC_SET_PREFERRED_CONNECTION_ID
		call	FileInt21
	;
	; Copy the login variables onto the stack (they never change).
	; 
		mov	bx, sp		; save for easy restore
		mov	cx, nwDiskEndLoginVars - nwDiskLoginVars 
		sub	sp, cx
		segmov	es, ss
		mov	di, sp
		segmov	ds, cs
		mov	si, offset nwDiskLoginVars
		rep	movsb
	;
	; Set up ds:si && es:di for the call.
	; 
		segmov	ds, ss
		mov	si, sp

		lea	di, ds:[si+(nwDiskLoginReply-nwDiskLoginVars)]
		mov	ax, NFC_LOGIN_TO_FILE_SERVER
		call	FileInt21
	;
	; Clear the stack and restore the preferred server connection before
	; checking for error.
	; 
		mov	sp, bx
		call	NWRestorePreferredServer
		tst_clc	al
		jz	notifyUser
	;
	; Error, so detach from the server again (so we try again later, on
	; the off chance that GUEST suddenly has appeared on the server...or
	; something).
	; 
		mov	dl, ss:[emptySlot]
		mov	ax, NFC_DETACH_FROM_FILE_SERVER
		call	FileInt21
		stc
done:
		.leave
		ret

notifyUser:
	;
	; The strings have to be in the same segment for SysNotify to use
	; them. This means we need to allocate a block to hold both the
	; constant string and the server name. Happily, getting their sizes
	; is easy.
	; 
		mov	bx, handle attachedAsGuest
		call	MemLock
		mov	ds, ax
		assume	ds:segment attachedAsGuest
		ChunkSizeHandle ds, attachedAsGuest, ax
		push	ax		; save count for copy

		add	al, ss:[serverNameLen]
		adc	ah, 0
		inc	ax		; plus null char
		inc	ax		; plus offset needed to make sure
					;  SysNotify thinks we're passing
					;  a string...
					
	;
	; Now allocate the block to hold the strings.
	; 
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		pop	cx		; cx <- size of attachedAsGuest
		jc	notifyDone
	;
	; First copy in the fixed string.
	; 
		mov	es, ax
		mov	di, 1		; must start at 1, so SysNotify thinks
					;  it's getting a string

		mov	si, ds:[attachedAsGuest]
		rep	movsb
	;
	; Now copy in the server name.
	; 
		mov	ax, di		; save start of server name
		lds	si, ss:[serverName]
		mov	cl, serverNameLen; (ch is 0)
		inc	cx
		rep	movsb
	;
	; Call SysNotify
	; 
		segmov	ds, es
		mov	si, 1		; first string
		mov_tr	di, ax		; di <- second string
		mov	ax, mask SNF_CONTINUE
		call	SysNotify

		call	MemFree
notifyDone:
	;
	; Unlock the block holding the fixed string and get out of here.
	; 
		mov	bx, handle attachedAsGuest
		call	MemUnlock
		clc
		jmp	done

		assume	ds:dgroup

NWDiskRestoreLoginAsGuest endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskRestoreComputeOrderNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the order of the server we're about to add w.r.t. the
		other servers already in the table.

CALLED BY:	(INTERNAL) NWDiskRestoreAttachAsGuest
PASS:		ss:bp	= inherited frame
RETURN:		dl	= order number
DESTROYED:	ax, bx, cx, dh, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskRestoreComputeOrderNumber proc	near
		.enter	inherit	NWDiskRestoreAttachAsGuest
		mov 	dx, NW_MAX_SERVERS+1	;dl <- sentinel value for order
						; number
						;dh <- # used slots seen (0)

		lds	si, ss:[connIDTable]

		segmov	es, ss
		lea	di, ss:[netAddr]	;es:di <- addr for new entry

		mov	bx, NW_MAX_SERVERS	;repeat for the whole table

findOrder:
	;
	; Make sure the slot is in-use before using its address & order number
	; 
		tst	ds:[si].NCITI_slotInUse
		jz	contOrder

		inc	dh		; record another in-use slot
		

	;
	; Compare the table entry with the new address. Flags end up set as
	; if	cmp	new, existing	were done.
	; 
		push	di, si
		add	si, offset NCITI_serverAddress
		mov	cx, size NovellNodeSocketAddrStruct
		clr	ax
		jcxz	compareDone
		repe	cmpsb
		mov	al, es:[di-1]
		sub	al, ds:[si-1]
compareDone:
		pop	di, si
		jge	contOrder	; => new entry >= table entry, so
					; the table entry's order number is
					; unaffected by our addition.
	;
	; Table entry's address is > new entry. We always need to up the
	; table entry's order number, to account for the presence of the
	; new entry. In addition, if the existing entry's number is lower than
	; any we've seen previously, we want it...
	; 
		cmp	dl, ds:[si].NCITI_serverOrderNumber
		jl	upExistingOrderNum	; already have a lower # from
						;  another entry whose addr
						;  is > than ours...

		mov	dl, ds:[si].NCITI_serverOrderNumber

upExistingOrderNum:
		inc	ds:[si].NCITI_serverOrderNumber

contOrder:
		add	si, size NetWareConnectionIDTableItem
		dec	bx
		jnz	findOrder

		cmp 	dl, NW_MAX_SERVERS+1	; find anything > us?
		jnz	done			; yes
	;
	; If my order number is still beyond the pale, then my order
	; number will be the biggest (i.e. the number of used slots + 1).
	;
		mov	dl, dh
		inc	dl

done:
		.leave
		ret
NWDiskRestoreComputeOrderNumber endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskRestoreFindEmptyConnectionSlot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an unused slot in the shell's connection table

CALLED BY:	(INTERNAL) NWDiskRestoreAttachAsGuest
PASS:		ss:bp	= inherited frame
RETURN:		carry set if couldn't find a slot:
			al	= 1
		carry clear if found one:
			ss:[connIDTable]	= set to base of connection
						  table
			ss:[emptySlot]		= set to 1-origin connection
						  ID
			ss:[emptySlotOff]	= set to offset (coupled with
						  ss:[connIDTable].segment) of
						  the table entry
DESTROYED:	ax, cx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskRestoreFindEmptyConnectionSlot proc near
		.enter	inherit	NWDiskRestoreAttachAsGuest
		mov	ax, NFC_GET_CONNECTION_ID_TABLE
		call	FileInt21
		movdw	ss:[connIDTable], essi

		mov	cx, NW_MAX_SERVERS
findSlot:
		tst	es:[si].NCITI_slotInUse
		jz	foundSlot
		add	si, size NetWareConnectionIDTableItem
		loop	findSlot
		mov	ax, 1		;error, too many connections
		stc
		jmp	done

foundSlot:
		sub	cx, NW_MAX_SERVERS+1
		neg	cx		; cx <- connection # (1-origin)

		mov	ss:[emptySlotOff], si
		mov	ss:[emptySlot], cl
		clc
done:
		.leave
		ret
NWDiskRestoreFindEmptyConnectionSlot endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskRestoreGetNetAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the network address of a server.

CALLED BY:	(INTERNAL) NWDiskRestoreAttachAsGuest
PASS:		ds:si	= server name
		ss:dx	= pointer to NovellNodeSocketAddrStruct
		cx	= name length (w/o null)
RETURN:		al	= result code (0 => success)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
netAddrPropName	char	size netAddrPropName-1, NWBinderyObjPropName_NetAddress

NWDiskRestoreGetNetAddr	proc	near
serverName	local	fptr	push ds, si
netAddrPtr	local	fptr	push ss, dx
serverNameLen	local	word	push cx
bufferBlock	local	hptr		
reqBuf		local	fptr
repBuf		local	fptr					
	uses	bx, cx, dx, ds, es, di, si
	.enter
	
	mov	ax, size NReqBuf_ReadPropertyValue + \
			size NRepBuf_ReadPropertyValue
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jnc	haveBuffers
	mov	al, NRC_IO_FAILURE_LACK_OF_DYNAMIC_WORKSPACE
	jmp	done

haveBuffers:
	mov	ds, ax			; ds:si <- request
	clr	si
	mov	es, ax			; es:di <- reply
	mov	di, size NReqBuf_ReadPropertyValue

	mov	ss:[bufferBlock], bx
	mov	ss:[reqBuf].segment, ax
	mov	ss:[reqBuf].offset, 0
	mov	ss:[repBuf].segment, ax
	mov	ss:[repBuf].offset, di
	
	mov	ds:[di].NREPBUF_RPV_length, size NRepBuf_ReadPropertyValue - 2
	
	;
	; Initialize the request buffer. First the fixed parts.
	; 
	mov	ds:[si].NREQBUF_RPV_subFunc, low NFC_READ_PROPERTY_VALUE
	mov	ds:[si].NREQBUF_RPV_objectType, NOT_FILE_SERVER
	
	;
	; Copy in the name of the server & its length.
	; 
	mov	cx, serverNameLen		;cx = count
	mov	ds:[si].NREQBUF_RPV_objectNameLen, cl
	lea	di, ds:[si].NREQBUF_RPV_objectName
	lds	si, serverName			;ds:si = server name
	rep 	movsb
	
	;
	; Now the variable part: the segment number & the property name.
	; 
	mov	al, NW_BINARY_OBJECT_PROPERTY_INITIAL_SEGMENT
	stosb
	segmov	ds, cs
	mov	si, offset netAddrPropName	; ds:si <- name & length source
	mov	cx, size netAddrPropName
	rep	movsb
	
	;
	; calculate length of request buffer (which starts at 0)
	; 
	lea	ax, [di-size NREQBUF_RPV_length]
	mov	es:[NREQBUF_RPV_length], ax
	
	;
	; call NetWare
	;
	les	di, ss:[repBuf]		; es:di <- reply buf
	lds	si, ss:[reqBuf]		; ds:si <- request buf
	mov	ax, NFC_READ_PROPERTY_VALUE
	call	FileInt21

	clr	ah
	test	al, 0
	jnz	freeBuffer

	;copy property value to buffer
	lds	si, ss:[repBuf]
	add	si, offset NREPBUF_RPV_propertyValue
	les	di, ss:[netAddrPtr]
	mov	cx, (size NovellNodeSocketAddrStruct)
	rep	movsb

freeBuffer:
	mov	bx, ss:[bufferBlock]
	call	MemFree
done:
	.leave
	ret
NWDiskRestoreGetNetAddr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDiskRestoreLocateExistingDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for an existing drive whose root is the same as that
		of the saved drive.

CALLED BY:	(INTERNAL) NWDiskRestore
PASS:		ss:bp	= inherited stack frame
		ds, es	= dgroup
		nwRestoreDirReplyBuffer.NREPBUF_RD_dirHandle set
RETURN:		carry set on error
			ax	= DiskRestoreError
		carry clear if ok
			bx	= non-zero if have DSE for return
				= 0 if no drive already mapped to root:
				  nwDiskInitReplyBuffer.NREPBUF_GDP_path set to
				  path to which to map new drive
DESTROYED:	ds, es, si, di, ax, cx, dx
SIDE EFFECTS:	nwDiskInit{Reply,Request}Buffer overwritten

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDiskRestoreLocateExistingDrive proc	near
		.enter	inherit	NWDiskRestore
		lds	si, ss:[savedData]
		add	si, ds:[si].FSSD_private
skipServerNameLoop:
		lodsb
		tst	al
		jnz	skipServerNameLoop
		movdw	ss:[dirPath], dssi
	;
	; Now loop through all drives looking for those connected to the
	; same server. For each one, see if its root path matches the
	; one we've now got.
	; 
		mov	ax, NFC_GET_DRIVE_CONNECTION_ID_TABLE
		call	FileInt21		; es:si <- connection ID table
		mov	di, si
		mov	cx, NW_MAX_NUM_DRIVES
		mov	al, ss:[serverCon]
	;
	; Optimization: see if any existing drive of the same name is
	; mapped appropriately.
	; 
		tst	ss:[dse]		; drive itself exists?
		jz	driveLoop		; no -- go on a quest
		
		push	es
		mov	es, ss:[fsir]
		mov	bx, ss:[dse]
		mov	bl, es:[bx].DSE_number	; bx <- drive number
		clr	bh
		pop	es
		cmp	al, es:[si][bx]	; existing drive on same server?
		jne	driveLoop	; no
		
		call	checkDrive	; this drive mapped right?
		jne	driveLoop	; no -- start search
		jmp	done		; yes -- we're done

driveLoop:
		scasb			; same connection?
		loopne	driveLoop	; loop if not
		jne	notFound	; => ran out of drives before found

		mov	bx, NW_MAX_NUM_DRIVES-1
		sub	bx, cx		; bx <- drive #

		call	checkDrive
		jne	driveLoop
done:
	;
	; Clear the path off the stack
	; 
		.leave
		ret

notFound:
	;
	; Didn't find a drive mapped to the same place, so copy the path
	; back into the nwDiskInitReplyBuffer, putting a colon onto the end
	; if we stripped it before.
	; 
		segmov	es, dgroup, di
		lds	si, ss:[dirPath]
		mov	di, offset nwDiskInitReplyBuffer.NREPBUF_GDP_path
		mov	ah, ':'	; flag volume terminator needed
copyPathForMapLoop:
		lodsb
		tst	al
		jz	terminateMapPath
		stosb
		cmp	ah, al		; volume terminator?
		jne	copyPathForMapLoop
		clr	ah		; flag colon seen
		jmp	copyPathForMapLoop

terminateMapPath:
		xchg	al, ah		; al <- : if needed (0 if not), ah < - 0
		stosw
		clr	bx		; flag everything ok, but we didn't
					;  find diddly
		jmp	done

	;--------------------
	; See if the given drive is mapped to the same place as the restored
	; disk handle was.
	; Pass:
	; 	bx	= 0-based drive #
	; 	ss:bp	= inherited stack frame
	; Return:
	; 	flags set so je is taken if drive mapped to same place:
	; 		bx	= offset of DSE
	; Destroyed:
	; 	si, dx always
	; 	es, ax (if match found)
	; 
checkDrive:
		push	di, cx, es, ax

		mov	dx, bx		; dx <- drive #
		call	NWDiskGetRootPathForDrive
		les	di, ss:[dirPath]
		mov	si, dx		; ds:si <- root path of drive
comparePathLoop:
		lodsb
		scasb
		jne	endComparePathLoop
		tst	al
		jnz	comparePathLoop

endComparePathLoop:
		pop	di, cx, es, ax
		jne	checkDriveDone
	;
	; Found a drive mapped to the same place as the saved thing was. Use
	; it.
	; 
		mov	al, bl			; al <- drive number
		mov	es, ss:[fsir]
		call	DriveLocateByNumber
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
		mov	bx, si
		cmp	bx, si			; return with flags set for
						;  je
checkDriveDone:
		retn

NWDiskRestoreLocateExistingDrive endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWCheckNetPath
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
NWCheckNetPath	proc	far
		.enter
		clr	bx		; not ours, for now
		.leave
		ret
NWCheckNetPath	endp


Transient	ends
