COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driDisk.asm

AUTHOR:		Adam de Boor, Oct 31, 1991

ROUTINES:
	Name			Description
	----			-----------
    INT DOSDiskSaveEndangeredFiles Utility routine to preserve the
				directory index and dirty state for all
				files open to the disk that was last
				accessed in the passed drive.

    INT DSEF_callback		Callback function for
				DOSDiskSaveEndangeredFiles to preserve the
				directory index and dirty state for all
				files open to the passed disk.

    INT DOSDiskReadBootSector	Read the boot sector of the given drive
				into our buffer, determine if the thing is
				valid and see if the sector already has a
				32-bit volume ID, returning it if so.

    INT DOSDiskFormID		Generate a 32-bit disk ID from the current
				date & time, storing it in the passed boot
				sector buffer.

    INT DOSDiskReleaseBootSector Release the boot sector buffer so other
				threads may use it.

    INT DOSDiskGenerateWPID	Generate a 32-bit ID for a write-protected
				disk, using information that should be
				unique amongst disks, we hope.

    INT DOSDiskID		Return the 32-bit ID for the disk currently
				in the passed drive.

    INT DOSDiskCopyVolumeNameToDiskDesc Copy the name of a disk out of an
				FCB (in DOS character set) into a DiskDesc
				structure, converting from the DOS to the
				GEOS character set.

    INT DOSDiskLocateVolume	Common function used for initializing a
				disk handle and renaming a disk.

    INT DOSDiskInit		Initialize a new disk handle with the
				remaining pertinent information. The
				FSInfoResource is locked for exclusive
				access and its segment is passed in ES for
				use by the driver.

    INT DOSDiskGrabAlias	If the drive in which the passed disk
				resides is one of a pair of aliases for the
				same physical drive, gain exclusive access
				to the physical drive.

    INT DOSDiskReleaseAlias	If the drive is an alias, release exclusive
				access to the physical drive.

    INT DOSDiskLock		Make sure the passed disk is in the drive.

    INT DOSDiskUnlock		Deal with drive aliases, releasing the
				physical drive semaphore if this is the
				last shared lock on the drive. This will
				also need to commit any dirty files if the
				disk is floppy.

    INT DDU_callback		Callback function to commit any dirty file
				open to the given disk.

    INT DOSDiskFindFree		Find the free space available on the given
				disk.

    INT DOSDiskInfo		Fetch detailed info about a disk in one
				swell foop.

    INT DOSDiskRename		Change the volume name of the passed disk.
				The disk has been locked into its drive for
				exclusive access, and the FSIR is also
				locked for exclusive access. FSD is
				expected to perform whatever mapping is
				necessary for its filesystem and copy the
				result into the DiskDesc if the rename is
				successful.

    INT DOSDiskCopyAndMapVolumeName Copy volume name from the source to
				someplace in an FCB (usually), upcasing and
				space-padding the thing as we go to both
				satisfy DOS and our own needs.

    INT DOSDiskSave		Append whatever private data the driver
				will require to restore the passed disk
				descriptor. The system portion
				(FSSavedDisk) will already have been filled
				in, with FSSD_private set to the offset at
				which the driver should store its
				information.

    INT DOSDiskRestore		Perform whatever actions are needed before
				the kernel attempts to restore a disk
				handle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/31/91	Initial revision


DESCRIPTION:
	implementation of all DR_FS_DISK calls except format and copy.
		
NOTES:
	DR DOS has a bit of protection built in to its file management
	system. It maintains a "login sequence" number for each drive, which
	is basically a checksum of various important pieces of the disk. If
	a file is open to the drive when that sequence number changes, all
	further modification of that file is disallowed. The file is marked
	not dirty, its write-access bit is cleared, and its directory index
	is set to -1. This prevents any inadvertent damage to the new disk
	now in the drive.
	
	We, however, know when the disk for the file in question has been
	stuck back in, as we ask the user for it and keep asking until we
	get it.
	
	To deal with this, before reading the boot sector, we call the
	routine DOSDiskSaveEndangeredFiles, which takes the current directory
	index and dirty state for each file on the disk and saves it in
	the private area of the file handle.
	
	Before opening a file or performing I/O on an open file, we make
	sure those values are stored back in the DR DOS FileHandle/FileDesc
	structures.


	$Id: dosDisk.asm,v 1.1 97/04/10 11:55:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


if _DRI

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskSaveEndangeredFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to preserve the directory index and
		dirty state for all files open to the disk that was
		last accessed in the passed drive.

CALLED BY:	DOSDiskReadBootSector
PASS:		es:si	= DriveStatusEntry the files on whose last disk needs
			  to be saved from danger.
		bootSem grabbed by this thread.

			- or -
		si.high	= 0xff
		si.low	= drive number
		bootSem grabbed by this thread.

RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskSaveEndangeredFiles proc	near
		uses	di, si, bx, cx
		.enter
	;
	;  See if we have a real, or fake DSE.
	;  Assumption: If fake, it's because there is no DSE for the
	;  	drive.  As such, there is no point checking for one...
	;	
		cmp	si, 0ff00h
		jae	done

		mov	si, es:[si].DSE_lastDisk	; si <- DiskDesc
		tst	si
		jz	done		; => no disk in drive before, so
					;  nothing to save

		mov	bx, SEGMENT_CS
		mov	di, offset DSEF_callback
		call	DOSUtilFileForEach
done:
		.leave
		ret
DOSDiskSaveEndangeredFiles endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSEF_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for DOSDiskSaveEndangeredFiles to preserve
		the directory index and dirty state for all files open to
		the passed disk.

CALLED BY:	DOSDiskSaveEndangeredFiles via DOSUtilFileForEach

PASS:		ds:bx	= DOSFileEntry to examine (on this disk)
		si	= DiskDesc of disk last seen in the drive

RETURN:		carry set to stop enumerating

DESTROYED:	di, ax (if I want to)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSEF_callback	proc	far
		uses	cx, es
		.enter
	;
	; Ja. Locate the file's FileDesc, from which we can obtain the current
	; directory index and dirty state for the file.
	; 
		les	di, ds:[handleTable]
		shl	cx				; index table of nptrs
		add	di, cx
		mov	di, es:[di]			; es:di <- FileHandle
		mov	di, es:[di].FH_desc		; es:di <- FileDesc
		mov	ax, es:[di].FD_dirIndex

		cmp	ax, -1			; hath it been biffed?
EC <		je	usePreviousIndex ; yes -- make sure got it already>
NEC <		je	done		 ; yes -- hope we got it already>
    		mov	ds:[bx].DFE_index, ax

	;
	; Check dirty state and set DFF_DIRTY appropriately.
	; 
		andnf	ds:[bx].DFE_flags, not mask DFF_DIRTY
		test	es:[di].FD_flags, mask FDS_DIRTY
		jz	done
		ornf	ds:[bx].DFE_flags, mask DFF_DIRTY
done:
		clc
		.leave
		ret

EC <usePreviousIndex:							>
EC <	;								>
EC <	; File hasn't had I/O performed on it since we changed disks	>
EC <	; from under it, so use whatever index and dirty state we had	>
EC <	; stored for the beast before.					>
EC <	; 								>
EC <		cmp	ds:[bx].DFE_index, -1				>
EC <	;	ERROR_E MISSED_GETTING_INDEX_FOR_FILE			>
EC <		jmp	done						>
DSEF_callback	endp

endif	; DRI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskReadBootSector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the boot sector of the given drive into our buffer,
		determine if the thing is valid and see if the sector already
		has a 32-bit volume ID, returning it if so.

CALLED BY:	DOSDiskID, DOSDiskLock

PASS:		es:si	= DriveStatusEntry for the drive.
			- or -
		si.high	= 0xff
		si.low	= drive number

RETURN:		carry set if boot sector invalid
		carry clear if boot sector valid:
			boot sector semaphore grabbed
			ds	= boot sector
			ZF clear (jnz will take) if no volume ID in the sector.
			ZF set if volume ID present:
				cx:dx	= 32-bit ID

DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskReadBootSectorFar proc far
		call	DOSDiskReadBootSector
		ret
DOSDiskReadBootSectorFar endp

DOSDiskReadBootSector proc	near
		uses	si, ax, bx
		.enter
	;
	; Snag the buffer for the boot sector.
	; 
		call	DOSDiskGrabBootSector	; ds <- sector buffer

	;
	; Read the sector into the boot buffer.
	;
		clr	bx
		mov	dx, bx
		mov	cx, 1
		clr	di
		call	DOSReadSectors
		jc	logNoRead

	;
	; Check the jump instruction at the start of the sector. It must
	; contain one of four things:
	;	- a near jump (three bytes) [XXX: check target of jump?]
	;	- a short jump (two bytes) followed by a NOP
	;	- all zeroes
	;	- a CLI followed by a short jump (from Packard Bell hard
	;	  disk [IBM 3.3 is in the oemNameAndVersion field, though
	;	  the DOS on the machine is MS-DOS 4.01...])
	;
		mov	ax, {word}ds:[BS_jumpInstr]
		cmp	al, JMP_INTRA_SEG
		je	checkForID
		mov	bl, 90h			; check for NOP as third...
		cmp	al, JMP_SHORT
		je	checkThirdByte
		cmp	ax, (JMP_SHORT shl 8) or 0xfa	; 0xfa == CLI
		je	checkForID		; third byte can be anything..
		clr	bl			; third byte must be zero
		tst	ax			; first two be zero?
		jnz	logInvalidFirstByte	; no => it be an error
checkThirdByte:
		cmp	ds:[BS_jumpInstr][2], bl
		jne	logInvalidThirdByte

checkForID:
		mov	cx, ds:[BS_volumeID].high
		mov	dx, ds:[BS_volumeID].low
		cmp	ds:[BS_extendedBootSig], EXTENDED_BOOT_SIGNATURE
		je	done
		
		.warn	-field		; I know. I know...
		mov	cx, ds:[BS_oemNameAndVersion].DIS_id.high
		mov	dx, ds:[BS_oemNameAndVersion].DIS_id.low
		cmp	ds:[BS_oemNameAndVersion].DIS_present,
			DISK_ID_PRESENT
		.warn	@field
		clc
done:
		.leave
		ret
	;
	; Complex handling of error conditions to allow us to figure, in the
	; future, just why we're rejecting a perfectly good disk.
	; 
logNoRead:
	;
	;  No logging errors with a Fake DSE
	;
		cmp	si, 0ff00h
		jae	error

	; es:si = DriveStatusEntry
	; ax = FileError
		push	es
		mov	bx, offset CouldNotReadBootSector
		call	DOSLogWithDrive
		
		sub	sp, 4		; room for error code in hex, plus 1
					;  to keep the stack aligned
		segmov	es, ss
		mov	di, sp
		call	storeByte
		mov	{char}es:[di-1], 0
		mov	si, sp
		segmov	ds, ss
		call	LogWriteEntry
		add	sp, 4
		pop	es
		jmp	error

logInvalidFirstByte:
		mov	bx, offset InvalidFirstByteMsg
		jmp	logInvalidSector
logInvalidThirdByte:
		mov	bx, offset InvalidThirdByteMsg
logInvalidSector:
	;
	;  No logging errors with a Fake DSE
	;
		cmp	si, 0ff00h
		jae	error

	; es:si = DriveStatusEntry
	; bx = string saying which byte was bad
		call	SysGetConfig		; biffs DX
		test	al, mask SCF_LOGGING
		jz	error
	;
	; If logging is enabled, let the user (and our CS rep) know exactly
	; why we're upset with the contents of the sector, spewing the
	; drive, which byte is wrong, and the first three bytes of the sector.
	; 
		push	es
		push	ds
		push	bx
		mov	bx, offset InvalidSectorMsg
		call	DOSLogWithDrive	; ds <- Strings, too
		pop	bx
		mov	si, ds:[bx]
		call	LogWriteEntry
		pop	ds
		sub	sp, 10		; room for 3 bytes in hex, plus 1 to
					;  keep the stack aligned
		segmov	es, ss
		mov	di, sp
		mov	al, ds:[BS_jumpInstr][0]
		call	storeByte
		mov	al, ds:[BS_jumpInstr][1]
		call	storeByte
		mov	al, ds:[BS_jumpInstr][2]
		call	storeByte
		mov	{char}es:[di-1], 0
		mov	si, sp
		segmov	ds, ss
		call	LogWriteEntry
		add	sp, 10
		pop	es
error:
	;
	; Release the boot sector, set the carry, and bail.
	; 
		call	DOSDiskReleaseBootSector
		stc
		jmp	done

storeByte:
	; Pass:		es:di = buffer
	; 		al = byte to store
	; Return:	es:di = after space
	; Destroy:	ax
	; 
		call	DOSUtilByteToAscii
		mov	al, ' '
		stosb
		retn
DOSDiskReadBootSector endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskFormID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a 32-bit disk ID from the current date & time,
		storing it in the passed boot sector buffer.

CALLED BY:	DOSDiskID
PASS:		ds	= boot sector into which to store the new ID.
RETURN:		cx:dx	= 32-bit ID
DESTROYED:	bx (flags preserved)

PSEUDO CODE/STRATEGY:
		We form the 32-bit ID from the current date and time, placing
		the FileTime record in CX, and the FileDate record in DX

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskFormID	proc	near
		.enter
		clr	cx, dx
		call	DOSDiskCheckNotStacker
		jnc	done
	;
	; Use the current date and time as the disk ID
	; 
		call	DOSGetTimeStamp
	;
	; Now store the ID in the boot sector. We know it's not an extended
	; boot sector or we wouldn't have been called, so store the thing in
	; the oemNameAndVersion field.
	; 
		.warn	-field	; so tell me something I don't know.
		mov	ds:[BS_oemNameAndVersion].DIS_id.high, cx
		mov	ds:[BS_oemNameAndVersion].DIS_id.low, dx
		mov	ds:[BS_oemNameAndVersion].DIS_present, DISK_ID_PRESENT
		.warn	@field
done:
		.leave
		ret
DOSDiskFormID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskReleaseBootSector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the boot sector buffer so other threads may use it.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ds, all flags but Carry

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskReleaseBootSector proc far
		uses	ax, bx
		.enter
		segmov	ds, dgroup, bx
		VSem	ds, bootSem, TRASH_AX_BX
		.leave
		ret
DOSDiskReleaseBootSector endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskGrabBootSector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the boot sector buffer in preparation for reading
		the boot sector, or whatever.

CALLED BY:	INTERNAL
       		DOSDiskReadBootSector, DOSDriveCheckChange
PASS:		es:si	= DriveStatusEntry of drive on whose behalf the
			  boot sector buffer is being grabbed
			- or -
		si.high = 0xff
		si.low  = drive number

RETURN:		ds	= segment of boot sector buffer

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskGrabBootSector proc	near
		.enter
		segmov	ds, dgroup, bx

		PSem	ds, bootSem, TRASH_AX_BX
	;
	; Preserve directory indices for all the files open to this drive,
	; now we've got the boot semaphore.
	; 
DRI <		call	DOSDiskSaveEndangeredFiles			>

    		mov	ds, ds:[bootSector]
		.leave
		ret
DOSDiskGrabBootSector		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskPLockSectorBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain exclusive access to the sector buffer.

CALLED BY:	DR_DPFS_P_LOCK_SECTOR_BUFFER
PASS:		nothing
RETURN:		ax	= segment of buffer
DESTROYED:	bp, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Under DR DOS, this is a near-duplicate of DOSDiskGrabBootSector
		to avoid the DOSDiskSaveEndangeredFiles call

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 1/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskPLockSectorBuffer proc	far
		uses	bx, ds
		.enter
if _DRI
		segmov	ds, dgroup, bx
		PSem	ds, bootSem, TRASH_AX_BX
    		mov	ax, ds:[bootSector]
else
		call	DOSDiskGrabBootSector
		mov	ax, ds		
endif
		.leave
		ret
DOSDiskPLockSectorBuffer endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskUnlockVSectorBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the sector buffer

CALLED BY:	DR_DPFS_UNLOCK_V_SECTOR_BUFFER
PASS:		nothing
RETURN:		nothing
DESTROYED:	flags
SIDE EFFECTS:	none, really

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 1/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskUnlockVSectorBuffer proc	far
		uses	ds
		.enter
		call	DOSDiskReleaseBootSector
		.leave
		ret
DOSDiskUnlockVSectorBuffer endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskGenerateWPID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a 32-bit ID for a write-protected disk, using
		information that should be unique amongst disks, we hope.

CALLED BY:	DOSDiskID
PASS:		es:si	= DriveStatusEntry for the drive
		boot sector semaphore grabbed
		ds	= segment of sector buffer we can use; contains
			  valid boot sector with disk geometry to begin with.
RETURN:		carry set if couldn't generate ID (unable to read sectors)
			ax	= error code
		carry clear if ID generated:
			cx:dx	= 32-bit ID
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Following is from Cheng's original code; all the same reasoning
	applies:

	Desirable checksum characteristics:
		* Easy to get to

		* Reproducible. There is no area on disk that can be used
		where this is guaranteed. Moreover, the disk may be
		write-protected, invalidating the possibility that we
		stick a unique identifier into, say, the boot sector
		(which we already do as the main strategy). Given the
		possibility of change then, we try to select a strategy
		that minimizes the likelihood that the checksum that we
		derive would change.

		* Uniqueness. Once again, this cannot be guaranteed.

	The FAT seems the most likely candidate. The other possibilties
	and why they were eliminated are listed below:

		There is nothing unique like a time stamp in the Boot Sector.

		The Root Directory would be a good candidate except for
		the fact that the math required to get the physical disk
		coordinates of the root dir sectors. (Conversion from a
		logical sector would be required).

		The same reasoning applies to the Files Area.

		The FAT is easy to get to and we only employ this strategy
		of computing the checksum when we are dealing with write-
		protected disks (ie when the strategy of writing out a
		unique disk identifier is impossible). If these conditions
		did not hold, especially the fact that we use it only
		when dealing with write-protected disks, use of an entry
		in the Root Directory would be a better choice because the
		possibility of the contents changing might be less.

	Current checksum computation strategy:
		get FAT sector
		add dwords in sector

		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskGenerateWPID	proc	near
		uses	si, bx, di
		.enter
	;
	; Read the first sector of the FAT into the buffer.
	;
		clr	bx
		mov	dx, ds:[BS_bpbNumReserved]	; bx:dx <- first FAT
							;  sector
		push	ds:[BS_bpbSectorSize]	; save sector size
		mov	cx, 1			; 1 sector only
		clr	di			; read to ds:0
		call	DOSReadSectors
		pop	cx			; recover sector size
		jc	done

	;
	; Compute checksum by summing the dwords in the sector
	; 
		shr	cx		; need # of dwords, so divide by 4
		shr	cx
		clr	dx
		clr	di
		mov	si, di
genLoop:
		lodsw
		add	dx, ax
		lodsw
		adc	di, ax
		loop	genLoop

		mov	cx, di		; cx:dx <- checksum
		clc
done:
		.leave
		ret
DOSDiskGenerateWPID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCheckNotStacker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed boot sector doesn't come from a stacked
		volume.

CALLED BY:	(INTERNAL) DOSDiskHackForStacker, DOSDiskFormID
PASS:		ds	= boot sector to check
RETURN:		carry set if not a stacked disk
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCheckNotStacker proc	near
		.enter
		cmp	{word}ds:[BS_oemNameAndVersion][0], 'S' or ('T' shl 8)
		jne	yes
		cmp	{word}ds:[BS_oemNameAndVersion][2], 'A' or ('C' shl 8)
		jne	yes
		cmp	{word}ds:[BS_oemNameAndVersion][4], 'K' or ('E' shl 8)
		jne	yes
		cmp	{word}ds:[BS_oemNameAndVersion][6], 'R' or (' ' shl 8)
		je	done		; (carry clear)
yes:
		stc
done:
		.leave
		ret
DOSDiskCheckNotStacker		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskHackForStacker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the oemNameAndVersion field is STACKER, meaning the
		thing is actually a stacked volume located on a hard
		disk, not a floppy (if it were a floppy, we would have read
		the true boot sector through BIOS). If such is the case, we
		won't actually be able to write the boot sector, though
		Stacker won't tell us so, and we'll end up horribly
		confused.
		
		In any case, such a volume isn't actually removable, despite
		what Stacker told us originally, so mark the disk as
		always valid.

CALLED BY:	(INTERNAL) DOSDiskID
PASS:		cxdx	= disk ID
		al	= DiskFlags we're going to use
		ds	= bootSector buffer
		es:si	= DriveStatusEntry
RETURN:		carry clear if sector from stacker
			cxdx	= disk ID to use
			al	= DiskFlags to use
			ah	= MediaType to use
		carry set if not stacker volume
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskHackForStacker proc	near
		.enter
		call	DOSDiskCheckNotStacker
		jc	done
		ornf	al, mask DF_ALWAYS_VALID
		mov	ah, MEDIA_CUSTOM
done:
		.leave
		ret
DOSDiskHackForStacker endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the 32-bit ID for the disk currently in the passed
		drive.

CALLED BY:	DR_FS_DISK_ID
PASS:		es:si	= DriveStatusEntry for the drive
		  	- or -
		si.high = 0xff
		si.low  = drive number
			- or -
		si.high	= 0xfe		
		si.low  = drive number 	
			
RETURN:		carry set if ID couldn't be determined
		carry clear if it could:
			cx:dx	= 32-bit ID
			al	= DiskFlags for the disk
			ah	= MediaType for the disk
			- or -
		if si.high = 0xfe on entry the write protect flags 
			     will not be determined if there already 
			     is an ID.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Look for non-DriveStatusEntry.
		If not non-standard, do regular song and dance.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskID	proc	far
doWPCheck	local	byte
		uses	ds, bx
		.enter
		mov	ss:[doWPCheck], TRUE
		mov	ax, si
		cmp	ah, 0feh	
		jb	haveDSE		; drive letter or DSE ?
		ja	readSector	; do WP check
		add	si, 0x100	; indicate drive letter
		clr	ss:[doWPCheck]
		jmp	readSector
haveDSE:
		test	es:[si].DSE_status, mask DS_MEDIA_REMOVABLE
		jnz	isRemovable
	;
	; We don't even bother with the boot sector for fixed drives, just
	; return an ID of zero and standard DiskFlags. Why do we punt? For
	; a number of reasons:
	; 	1) the disk never changes, so we don't need a real ID anyway
	; 	2) if we were to attempt to write the boot sector, to
	;	   determine if the disk is actually writable, some
	;	   anti-virus TSRs would have a fit.
	;	3) if we store a 32-bit ID in the oemNameAndVersion field of
	;	   a hard disk on a PC-DOS system, it will refuse to boot.
	;
		clr	cx
		mov	dx, cx
		mov	al, mask DF_WRITABLE or mask DF_ALWAYS_VALID
		mov	ah, MEDIA_FIXED_DISK
done:
		.leave
		ret

isRemovable:
	;
	; MS-DOS: keep DOS apprised of disk changes by checking with the
	; driver to see if the disk has changed *before* we read the boot
	; sector (at which time the change line for the drive would be
	; de-asserted and DOS would get confused).
	; 
	; 12/15/00 ayuen: Skip reading the boot sector if the disk hasn't
	; changed.  This makes opening Floppy Disk folder three times as
	; fast.
	;
MS <		mov	bx, si		; pass es:bx = DSE		>
MS <		call	DOSDriveCheckChange	;ax = error flag	>
MS <		jc	maybeChanged					>
MS <		mov	bx, es:[bx].DSE_lastDisk    ; es:bx = DiskDesc	>
MS <		tst_clc	bx						>
MS <		jz	readSector	; => ID not generated yet	>
MS <		movdw	cxdx, es:[bx].DD_id				>
MS <			CheckHack <DD_flags + 1 eq DD_media>		>
MS <		mov	ax, {word} es:[bx].DD_flags			>
MS <					; al = DiskFlags, ah = MediaType>
MS <		jmp	done		; return CF clear		>
MS <maybeChanged:							>
MS <		tst	ax						>
MS <		stc							>
MS <		jnz	done						>

readSector:
	;
	; More fun. Need to do our magic with the boot sector.
	; 
		call	DOSDiskReadBootSector
		jc	done		; => bad disk, so fail the whole thing
		jz	haveID
		call	DOSDiskFormID
haveID:

		lahf
		mov	al, mask DF_WRITABLE
		call	DOSDiskHackForStacker
		jnc	releaseBoot
	;
	; Check to see if the disk is write protected by calling the
	; secondary files system driver.  If the secondary file system
	; driver does not know, then we try writing to the disk.
	;
		sahf	
		jnz	writeBootSector
		mov	bx, si
		tst	ss:[doWPCheck]	; caller doesn't care about WP flag
		jz	dontCheckWriteProtect

		call	DOSCheckWritable
		jnc	writeBootSector

dontCheckWriteProtect:
		jmp	bootSectorWriteAvoided

writeBootSector:		
		push	ax, cx, dx	;save ID and flags (both of them :)

		clr	bx
		mov	dx, bx		; sector 0
		mov	cx, 1		; 1 sector
		mov	di, bx		; ds:di <- buffer
		call	DOSWriteSectors
		pop	ax, cx, dx

		jnc	figureMedia
	;
	; Disk isn't actually writable. We don't much care about the error.
	; 
		clr	al		; assume ID was in the boot sector
					;  already and return with DF_WRITABLE
					;  clear (it so happens we've nothing
					;  else we need set, either)
bootSectorWriteAvoided:
		sahf
		jz	figureMedia	; if ID was in the boot sector already,
					;  we don't need to generate a sum from
					;  the FAT as the ID we found is good
					;  enough for us.
		mov	bh, al
		call	DOSDiskGenerateWPID
		jc	figureMedia
		mov_tr	al, bh		;  restore AL after it was biffed
					;  by DOSDiskGenerateWPID
figureMedia:
		mov	bl, ds:[BS_bpbMediaDescriptor]
		mov	di, ds:[BS_bpbSectorsPerTrack]
	;
	; Convert the DOS media descriptor and disk geometry into a PC/GEOS
	; MediaType enum.
	; 
		pushf			; save error/no error flag
		clr	bh		; must pass BH 0
		xchg	cx, di		; cx <- s.p.t., save high word of ID
		call	DOSDiskMapDosMediaToGEOSMedia
		mov	cx, di		; cx <- high word of ID again
		popf
releaseBoot:
		call	DOSDiskReleaseBootSector
		jmp	done
DOSDiskID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCheckWritable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the secondary driver to find out if the disk is
		writable. 

CALLED BY:	DOSDiskID
PASS:		es:si	= DriveStatusEntry
		  	- or -
		si.high = 0xff
		si.low  = drive number


RETURN:		carry set if we know whether or not it is writable.
		al 	= DF_WRITABLE bit set accordingly
		or
		carry clear if do not know whether or not it is writable
		al 	= unchanged
		
DESTROYED:	di, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	2/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCheckWritable	proc	near
	uses	ds, es, cx, dx
	.enter
		push	si
		call	getDSE
		jc	dontKnow
	
	;
	; es:si = DriverStatusEntry
	;
		mov	di, DR_DSFS_GET_WRITABLE
		call	DOSCallSecondary
		pushf
		cmp	bx, TRUE
		je	popExit
		popf	
dontKnow:
		clc
		jmp	exit
popExit:
		popf
exit:
		pop	si
		call	unlockFSInfo
	.leave
	ret

getDSE:
		push	ax
		cmp	si, 0xfe00
		jae	haveDriveNumber
		clc	
		jmp	haveDSE

haveDriveNumber:
		;
		; get the DriverStatusEntry if all we have is the
		; drive number
		;
		call	FSDLockInfoShared	
		mov	es, ax
		mov	ax, si
		call	DriveLocateByNumber
haveDSE:
		pop	ax
		ret

unlockFSInfo:
		pushf	
		cmp	si, 0xfe00
		jb	dontUnlock
		call	FSDUnlockInfoShared
dontUnlock:
		popf
		ret

DOSCheckWritable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCallSecondary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		es	= FSInfoResource	
		bx	= DriverStatusEntry
		di	= DOSSecondaryFSFunction

RETURN:		bx	= FALSE if the call could not be made because
			  we are the primary, or because the protocols
			  are mismatched.
		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCallSecondary	proc	far
	uses	ds
	.enter
		push	di

		mov	di, es:[bx].DSE_fsd
		cmp	es:[di].FSD_strategy.segment, segment DOSStrategy
		je	dontCall
		
		mov	bx, es:[di].FSD_handle
		push	si
		call	GeodeInfoDriver	
		mov	bx, si		; ds:bx <- DriverInfoStruct
		pop	si	
	;	
	; Make sure the secondary's protocol number isn't out of line.
	; 
		cmp	ds:[bx].FSDIS_altProto.PN_major,
			DOS_SECONDARY_FS_PROTO_MAJOR
		jne	dontCall
		cmp	ds:[bx].FSDIS_altProto.PN_minor,
			DOS_SECONDARY_FS_PROTO_MINOR
		jb	dontCall
	;
	; es:si <- DriveStatusEntry
	; All systems are go -- call the secondary.
	; 
		pop	di
		call	ds:[bx].FSDIS_altStrat
		mov	bx, TRUE	
exit:
	.leave
	ret

dontCall:
		pop	di
		mov	bx, 	FALSE
		jmp	exit
DOSCallSecondary	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSDiskMapDosMediaToGEOSMedia

DESCRIPTION:	Returns the GEOS media descriptor that corresponds to
		the given DOS media descriptor.

CALLED BY:	INTERNAL
       		DOSDiskID, DRIFetchDeviceParams, DRICheckDCB

PASS:		cx - sectors per track
		bl - DOS media descriptor (bh zero)

RETURN:		ah - GEOS media descriptor

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

DOSDiskMapDosMediaToGEOSMedia	proc	far
		uses	bx
		.enter
if PZ_PCGEOS
	;
	; for Pizza, we'll support 1.232M 3.5" instead of 160K 5.25"
	;	(can't use sectors-per-tracks as both are 8)
	;	(MEDIA_1M232 = MEDIA_160K)
	;
		mov	ah, MEDIA_1M232
		cmp	bl, DOS_MEDIA_1M232
		je	done
endif
	;
	; Handle exception to near-consecutiveness
	; 
		cmp	bl, DOS_MEDIA_1M44
		jne	notF0

	;
	; 3.5" 1.44Mb or 2.88Mb
	; 
		mov	ah, MEDIA_2M88
		cmp	cx, 36		; 2.88Mb uses 36 s.p.t.
		je	done

		mov	ah, MEDIA_1M44
		jmp	done

notF0:
		and	bl, 07h

	;
	; Valid values in bl are now 0 (fixed), 1 (720K/1.2M), 4 (180K),
	; 5 (360K), 6 (160K) and 7 (320K)

		mov	ah, cs:[bx][dosMediaConvTable]

		cmp	ah, MEDIA_1M2	;handle non-unique exception
		jne	done

	;
	; DOS media byte 0f9h is shared by the 5.25" 1.2Mb media and
	; the 3.5" 720Kb. We use the number of sectors per track in
	; the BPB to distinguish between the two.
	;
		cmp	cx, 15		; 1.2 Mb format?
		je	done
		mov	ah, MEDIA_720K
done:
		.leave
		ret
DOSDiskMapDosMediaToGEOSMedia	endp

dosMediaConvTable MediaType \
		MEDIA_FIXED_DISK,
		MEDIA_1M2,	;this offset is also valid for 720Kb
		MEDIA_720K,	; XXX: 2.11 on the Toshiba 1000SE uses a
				;  descriptor byte of 0xfa to describe a
				;  720K 3.5" drive...
		0,
		MEDIA_180K,
		MEDIA_360K,
		MEDIA_160K,
		MEDIA_320K


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyVolumeNameToDiskDesc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the name of a disk out of an FCB (in DOS character
		set) into a DiskDesc structure, converting from the DOS
		to the GEOS character set.

CALLED BY:	DOSDiskInit, DOSDiskRename
PASS:		ds:dx	= place from which to copy (VOLUME_NAME_LENGTH
			  space-padded bytes)
		es:si	= DiskDesc to which to copy it.
RETURN:		nothing
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyVolumeNameToDiskDesc proc	far
SBCS <		uses	si, ds						>
DBCS <		uses	si, ds, bp, dx					>
		.enter
	;
	; First copy the name into the DiskDesc. Have to go to null-termination
	; to cope with dumb-ass CD-ROMs and bugs in the new DR DOS.
	; 
		lea	di, es:[si].DD_volumeLabel
		mov	si, dx
			CheckHack <size FCB_name ge length DD_volumeLabel>
		mov	cx, length DD_volumeLabel
DBCS <		mov	dx, cx						>

if DBCS_PCGEOS
		call	DCSFindCurCodePage
copyLoop:
	;
	; Get and map the character
	;
		call	DCSDosToGeosCharString
EC <		ERROR_C	DOS_CHAR_COULD_NOT_BE_MAPPED			>
	;
	; We want to space pad from the NULL onward.
	;
		tst	ax			;NULL?
		jz	endString
	;
	; Loop for more characters
	;
		dec	dx			;dx <- one less char
		loop	copyLoop
	;
	; Pad end of string with NULLs.  We track the # of characters
	; separately in dx because cx is the # of bytes, but that
	; number of bytes in DOS may not generate the same number of
	; characters in GEOS.
	;
endString:
		mov	cx, dx			;cx <- # of chars left
		mov	ax, ' '			;ax <- pad with spaces
		rep	stosw
else

copyLoop:
		lodsb
		tst	al
		jnz	storeIt
		dec	si
		mov	al, ' '
storeIt:
		stosb
		loop	copyLoop
	;
	; Now convert the whole thing to the GEOS character set.
	; 
		lea	si, es:[di-size DD_volumeLabel]
		segmov	ds, es		; ds:si <- string to convert
		mov	cx, size DD_volumeLabel
		call	DOSUtilDosToGeos
endif
		.leave
		ret
DOSDiskCopyVolumeNameToDiskDesc		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskLocateVolumeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine, shared by formatting and disk code, to
		locate a volume label, given a drive number and the
		address of two buffers.

CALLED BY:	DOSDiskLocateVolume, DOSFormatSetName
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
DOSDiskLocateVolumeLow proc	far
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
		call	DOSUtilInt21
	;
	; Now ask DOS to find the durn thing.
	; 
		pop	dx
		mov	ah,MSDOS_FCB_SEARCH_FOR_FIRST
		call	DOSUtilInt21
		call	SysUnlockBIOS
		.leave
		ret
DOSDiskLocateVolumeLow endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskLocateVolume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common function used for initializing a disk handle and
		renaming a disk.

CALLED BY:	INTERNAL
       		DOSDiskInit, DOSDiskRename
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
DESTROYED:	cx, dx, di, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskLocateVolume proc near
		.enter	inherit	DOSDiskInit
		mov	di, es:[si].DD_drive
		mov	dl, es:[di].DSE_number
		lea	di, ss:[volFCB]
		lea	bx, ss:[dta]
		call	DOSDiskLocateVolumeLow
		.leave
		ret
DOSDiskLocateVolume endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskInit
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
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskInit	proc	far
volFCB		local	FCB		; FCB we need to use to locate the
					;  volume label (DOS 2.X has bugs with
					;  4eh(cx=FA_VOLUME))
dta		local	FCB		; DTA for DOS to use during volume
					;  location (needs an unopened
					;  extended FCB).
	ForceRef volFCB	; in DOSDiskLocateVolume
		uses	ax, cx, dx, si, di, ds
		.enter
	;
	; See if the disk actually has a volume label.
	; 
		push	ax	; save FSDNamelessAction
		call	DOSDiskLocateVolume
		tst	al
		pop	ax		; ah <- FSDNamelessAction
		jnz	nameless
		tst	ss:[dta].FCB_name[0]	; cope with CD-ROMs that have
		jz	nameless		;  no real label. They come back
						;  with a null byte at the start
						;  of the name in the DTA.
						;  -- ardeb 11/23/92
	;
	; Copy the volume label into the disk descriptor from the DTA.
	; 
		lea	dx, ss:[dta].FCB_name
		call	DOSDiskCopyVolumeNameToDiskDesc
		clc			; signal happiness
done:
		.leave
		ret

nameless:
	;
	; Disk has no volume label, so make one up.
	; 
		call	FSDGenNameless
		jmp	done
DOSDiskInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskGrabAlias
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the drive in which the passed disk resides is one of
		a pair of aliases for the same physical drive, gain exclusive
		access to the physical drive.

CALLED BY:	DOSDiskLock
PASS:		es:si	= DiskDesc for the disk being locked in.
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskGrabAlias proc	near
		uses	si
		.enter
		mov	si, es:[si].DD_drive
		call	DOSDriveLock
		.leave
		ret
DOSDiskGrabAlias endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskReleaseAlias
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the drive is an alias, release exclusive access to the
		physical drive.

CALLED BY:	DOSDiskUnlock
PASS:		es:si	= DiskDesc being unlocked
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskReleaseAlias proc near
		uses	si
		.enter
		mov	si, es:[si].DD_drive
		call	DOSDriveUnlock
		.leave
		ret
DOSDiskReleaseAlias endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed disk is in the drive.

CALLED BY:	DR_FS_DISK_LOCK
PASS:		es:si	= DiskDesc for the disk to be locked in
		al	= FILE_NO_ERRORS bit set if disk lock may not
			  be aborted by the user.
RETURN:		carry set if disk could not be locked
			- even on carry set, DOSDiskUnlock must eventually
			  be called to release the alias lock for the drive
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskLock	proc	far
		uses	bx, cx, dx, di, ds
		.enter
	;
	; If the drive is an alias, make sure this drive is the current one.
	; 
		call	DOSDiskGrabAlias
	;
	; 12/27/00 ayuen: To avoid deadlock between DSE_lockSem and
	; DDPD_aliasLock, the kernel is now changed to not grab/release
	; DSE_lockSem around calls to DR_FS_DISK_LOCK, such that we can grab
	; the semaphore ourselves after we have already grabbed the alias
	; lock.  This way deadlock is avoided.  (See DiskLockCommon.)
	;
		mov	bx, es:[si].DD_drive
		PSem	es, [bx].DSE_lockSem
	;
	; If the hardware says the disk has changed, fetch the ID for the
	; disk.
	; 
		push	ax			; save FILE_NO_ERRORS flag
		call	DOSDriveCheckChange
		pop	ax			; recover FILE_NO_ERRORS flag
						; (ignore error code)
		jc	getID
	;
	; Hardware says the disk hasn't changed, but that doesn't help us if
	; the disk we're going for isn't the one that was last in the drive...
	; 
		cmp	si, es:[bx].DSE_lastDisk
		je	doneOK
getID:
	;
	; Read the boot sector of the disk currently in the drive, extracting
	; its 32-bit ID, if any.
	; 
		push	ax		; save FILE_NO_ERRORS flag
		xchg	bx, si		; es:si <- DSE, es:bx <- DD
		call	DOSDiskReadBootSector
		xchg	bx, si
		jc	promptForDisk	; => no or bad disk, so can't be what
					;  we want
		jz	checkID		; => have ID to check
	;
	; If boot sector is valid, but doesn't contain an ID, see if the
	; beast is writable. If so, then we should have put an ID in the disk
	; before, so it can't be what we want.
	;
	; If not, we need to regenerate the checksum ID from the FAT and see
	; if that matches.
	; 
		test	es:[si].DD_flags, mask DF_WRITABLE
		jnz	promptForDisk
		
		xchg	bx, si		; es:si <- DSE, es:bx <- DD
		call	DOSDiskGenerateWPID
		xchg	bx, si
		jc	promptForDisk	; => can't generate, so can't be what
					;  we want
checkID:
	;
	; Have ID, so compare it against the one for the disk itself.
	; 
		cmp	cx, es:[si].DD_id.high
		jne	differentDisk
		cmp	dx, es:[si].DD_id.low
		jne	differentDisk	; (carry clear on == comparison)

	;
	; MS: if disk just located in the drive is the same as was last in
	; the drive, then clear the DCB_mediaChanged flag for the DCB,
	; as the disk hasn't actually changed...
	; 
	; On second thought, perhaps we shouldn't clear this bit, lest DOS
	; return the wrong results the next time we do a FileEnum.  This seems
	; to happen for 3.5 format disks if you remove the disk, delete a file
	; on another machine, and re-insert the disk.  dl 6/19/93
	;
if 0
MS <		cmp	si, es:[bx].DSE_lastDisk			>
MS <		jne	releaseBoot					>
MS <		mov	bx, es:[bx].DSE_private				>
MS <		tst	bx						>
MS <		jz	releaseBoot					>
MS <		push	es						>
MS <		les	bx, es:[bx].DDPD_dcb				>
MS <		mov	es:[bx].DCB_mediaChanged, FALSE			>
MS <		pop	es						>
MS <releaseBoot:							>
endif
	;
	; Found the disk, so we're done.
	; 
		call	DOSDiskReleaseBootSector
		pop	ax		; recover FILE_NO_ERRORS flag
doneOK:
		clc
done:
	;
	; Release DSE_lockSem that we grabbed at the beginning.
	;
		VSem	es, [bx].DSE_lockSem, TRASH_AX_BX	; CF preserved
		.leave
		ret
differentDisk:
if FLOPPY_BASED_DOCUMENTS
		push	bx, di, si
		mov	si, es:[bx].DSE_lastDisk
		cmpdw	cxdx, es:[si].DD_id
		jne	afterFlush
	; 
	; Before prompting for the new disk, flush any unsaved buffers
	; from the previous disk, since we didn't do so when we last
	; unlocked this disk
	;

		mov	bx, cs
		mov	di, offset DDU_callback
		call	DOSUtilFileForEach
afterFlush:
		pop	bx, di, si
endif
		
promptForDisk:
	;
	; Ask the user to insert the disk after releasing the boot sector
	; and recovering the flag that says whether the user may abort
	; the lock.
	; 
		call	DOSDiskReleaseBootSector
		pop	ax		; al <- FILE_NO_ERRORS flag
		call	FSDAskForDisk
		jc	done		; => user canceled, so we're done

	;
	; Call DOSDriveCheckChange again, as it will make sure that
	; DOS and BIOS are both in agreement about whether a new disk
	; was inserted.   Prevents critical errors, etc.
	;
		
		push	ax			; save FILE_NO_ERRORS flag
		call	DOSDriveCheckChange
		pop	ax			; recover FILE_NO_ERRORS flag
						; (ignore error code)
		jmp	getID		; else make sure the user put the
					;  right disk in...
DOSDiskLock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with drive aliases, releasing the physical drive
		semaphore if this is the last shared lock on the drive.
		This will also need to commit any dirty files if the disk
		is floppy.

CALLED BY:	DR_FS_DISK_UNLOCK
PASS:		es:si	= DiskDesc to unlock
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskUnlock	proc	far
		uses	bx, si, cx, di, dx
		.enter

if not FLOPPY_BASED_DOCUMENTS
	;
	; (In Redwood, we'll skip the update.   The theory is a) the user
	;  always is the one that decides to save, and b) documents are
	;  never written to disk piecemeal.   Hopefully not committing will
	;  be a dramatic time savings.)
	;

	;
	; See if the disk is removable...
	; 
		mov	bx, es:[si].DD_drive
		test	es:[bx].DSE_status, mask DS_MEDIA_REMOVABLE
		jz	releaseAlias
	;
	; If the disk is removable, and this is the last unlock of the beast,
	; find all files open to the disk that are dirty and commit them.
	; 
		cmp	es:[bx].DSE_shareCount, 1
		ja	releaseAlias	; others still sharing, so do nothing
	;
	; If shareCount is 1 or 0, this is the last shared unlock, or an
	; exclusive unlock, so check for dirty files and commit them.
	; 
		mov	bx, SEGMENT_CS
		mov	di, offset DDU_callback
		call	DOSUtilFileForEach
releaseAlias:
endif

	;
	; Now release the alias lock, if there is one for this drive.
	; 
		call	DOSDiskReleaseAlias
done::
		.leave
		ret
DOSDiskUnlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DDU_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to commit any dirty file open to the
		given disk.

CALLED BY:	DOSDiskUnlock via DOSUtilFileForEach
PASS:		ds:bx	= DOSFileEntry to examine (on this disk)
		es:si	= DiskDesc of disk being unlocked
		cl	= SFN
RETURN:		carry set to stop enumerating
DESTROYED:	di, is allowed

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DDU_callback	proc	far
		.enter
	;
	; Ja. Locate the file's FileDesc, from which we can obtain the current
	; dirty state for the file.
	; 
		test	ds:[bx].DFE_flags, mask DFF_DIRTY
		jz	done
	;
	; File is dirty, so call DOS to commit the thing.
	; 
if not _MS2
		andnf	ds:[bx].DFE_flags, not mask DFF_DIRTY

		push	ax
		xchg	bx, cx			;bx <- SFN, save old bx
		call	DOSAllocDosHandle
		mov	ah, MSDOS_COMMIT
		call	DOSUtilInt21
		call	DOSFreeDosHandle
		xchg	bx, cx			;ds:bx <- DFE, cx <- SFN
		pop	ax
else
		.err <This needs reworking for MS2>
endif

done:
		clc
		.leave
		ret
DDU_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskFindFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the free space available on the given disk.

CALLED BY:	DR_FS_DISK_FIND_FREE
PASS:		es:si	= DiskDesc of disk whose free space is desired (disk
			  is locked into drive)
RETURN:		carry clear if successful:
			dx:ax	= # bytes free on the disk.
		carry set if error:
			ax	= error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskFindFree proc	far
		uses	si, bx, cx
		.enter
		mov	si, es:[si].DD_drive
		mov	dl, es:[si].DSE_number
		inc	dx		; (1-byte inst)
		mov	ah, MSDOS_FREE_SPACE
		call	DOSUtilInt21
		cmp	ax, 0xffff
		je	fail
		
		mul	cx			; dx:ax = bytes/cluster
						;  (if > 64K, we're in trouble)
EC <		ERROR_C	BYTES_PER_CLUSTER_OVER_64K			>
		mul	bx			; dx:ax = bytes free
		clc
done:
		.leave
		ret
fail:
		mov	ax, ERROR_INVALID_DRIVE
		stc
		jmp	done
DOSDiskFindFree endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch detailed info about a disk in one swell foop.

CALLED BY:	DR_FS_DISK_INFO
PASS:		bx:cx	= fptr.DiskInfoStruct
		es:si	= DiskDesc of disk whose info is desired (disk is
			  locked shared in the drive)
RETURN:		carry set on error
			ax	= error code
		carry clear if successful
			buffer filled in.
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskInfo	proc	far
		uses	bx, cx, dx, si, di, ds, es
		.enter
	;
	; Save address of structure we're to fill in once we've got the info.
	; 
		push	bx, cx
	;
	; Fetch the drive number from the DriveStatusEntry and ask DOS about
	; the disk.
	; 
		mov	bx, es:[si].DD_drive
		mov	dl, es:[bx].DSE_number
		inc	dx
		mov	ah, MSDOS_FREE_SPACE
		call	DOSUtilInt21	; ax <- sectors/cluster
					; bx <- free clusters
					; cx <- bytes/sector
					; dx <- total clusters
		cmp	ax, 0xffff
		je	fail
	;
	; Now fill in the structure.
	; 
		pop	ds, di		; ds:di <- structurre to fill in

		push	dx		; save total clusters
		mul	cx		; ax <- bytes/cluster
		mov	ds:[di].DIS_blockSize, ax

		mul	bx		; dx:ax <- bytes free
		mov	ds:[di].DIS_freeSpace.low, ax
		mov	ds:[di].DIS_freeSpace.high, dx

		pop	ax		; ax <- total cluster
		mul	ds:[di].DIS_blockSize	; dx:ax <- bytes total
		mov	ds:[di].DIS_totalSpace.low, ax
		mov	ds:[di].DIS_totalSpace.high, dx
		
		segxchg	ds, es
		add	si, offset DD_volumeLabel	; ds:si <- source
		add	di, offset DIS_name		; es:di <- dest
		CheckHack <size DD_volumeLabel le size DIS_name>
		mov	cx, size DD_volumeLabel
		rep	movsb
		clc
done:
		.leave
		ret
fail:
		pop	bx, cx		; clear the stack
		stc
		mov	ax, ERROR_INVALID_DRIVE
		jmp	done
DOSDiskInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the volume name of the passed disk. The disk has been
		locked into its drive for exclusive access, and the FSIR is
		also locked for exclusive access. FSD is expected to perform
		whatever mapping is necessary for its filesystem and copy the
		result into the DiskDesc if the rename is successful.

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
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskRename	proc	far
volFCB		local	FCB		; FCB we need to use to locate the
					;  volume label (DOS 2.X has bugs with
					;  4eh(cx=FA_VOLUME))
dta		local	RenameFCB	; DTA for DOS to use during volume
					;  location (needs an unopened
					;  extended FCB).
		uses	bx, cx, dx, ds, si, di
		.enter
	;
	; Look for an existing volume label to rename
	; 
		push	ds, dx		; save new name
		call	DOSDiskLocateVolume
		pop	ds, dx
		push	es, si
		mov	si, dx		; ds:si <- new name
		segmov	es, ss

		tst	al
		jnz	createNewLabel

	;
	; Use the FCB stored in the DTA to rename the existing volume.
	; We set RFCB_attributes to FA_VOLUME to make sure nothing weird
	; like FA_ARCHIVE being set (as just happened to me) causes
	; any problems.
	;
		lea	di, ss:[dta].RFCB_newName
		call	DOSDiskCopyAndMapVolumeName

		lea	dx, ss:[dta]
		mov	ss:[dta].RFCB_attributes, mask FA_VOLUME
		segmov	ds, ss
		mov	ah, MSDOS_FCB_RENAME
		call	DOSUtilInt21

		add	dx, offset RFCB_newName
		tst	al
		jz	setNewName

renameFailed:
		pop	es, si			; recover disk descriptor
		mov	ax, ERROR_ACCESS_DENIED
		stc
		jmp	done

createNewLabel:
	;
	; ds:si	= new name
	; es	= ss
	; 
	; Copy the new volume name into the volFCB (dta may not be properly
	; initialized since nothing was found).
	; 
		lea	di, ss:[volFCB].FCB_name
		call	DOSDiskCopyAndMapVolumeName

	;
	; Use the now-filled extended FCB to create a new volume label for
	; the sucker.
	; 
		lea	dx, ss:[volFCB]		;ds:dx = unopened FCB
		segmov	ds, ss
		mov	ah, MSDOS_FCB_CREATE
		call	DOSUtilInt21

		tst	al
		jnz	renameFailed
		add	dx, offset FCB_name

setNewName:
	;
	; Copy the new name into the disk descriptor from ds:dx. Our internal
	; routine DOSDiskCopyVolumeNameToDiskDesc has properly upcased and
	; space-padded the beast, so all is groovy.
	; 
		pop	es, si

		call	DOSDiskCopyVolumeNameToDiskDesc
		andnf	es:[si].DD_flags, not mask DF_NAMELESS
done:
		.leave
		ret
DOSDiskRename	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyAndMapVolumeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy volume name from the source to someplace in an FCB
		(usually), upcasing and space-padding the thing as we go
		to both satisfy DOS and our own needs.

CALLED BY:	INTERNAL
       		DOSDiskRename, DOSFormatWriteBootAndReserved
PASS:		ds:si	= null-terminated GEOS volume name
		es:di	= place to which to copy (size FCB_name)
RETURN:		nothing
DESTROYED:	ax, bx, cx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyAndMapVolumeName proc	far
DBCS <		uses	bp, dx						>
		.enter
		mov	cx, size FCB_name
if DBCS_PCGEOS
		call	DCSFindCurCodePage
copyLoop:
	;
	; Get and map the character
	;
		mov	dx, di			;es:dx <- ptr to dest
		call	DCSGeosToDosCharFileString
		tst	ax			;reached NULL?
		jz	endString
	;
	; Loop for more characters
	;
		loop	copyLoop
		jmp	done

	;
	; We want to space pad from the NULL onward.
	;
endString:
		mov	di, dx			;es:di <- ptr to end of string
		mov	al, ' '			;ax <- pad with spaces
		rep	stosb
done:
else

copyLoop:
		lodsb
		tst	al
		jnz	upcaseAndConvert
		mov	al, ' '
		dec	si		; keep hitting the null...
		jmp	store
upcaseAndConvert:
		call	DOSUtilGeosToDosChar
store:
		stosb
		loop	copyLoop
endif

		.leave
		ret
DOSDiskCopyAndMapVolumeName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskSave
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
	We have no additional information we need to save, since we can do
	nothing to help restore the thing anyway.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskSave	proc	far
		.enter
		clr	cx
		.leave
		ret
DOSDiskSave	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskRestore
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
		carry clear if disk should be ok to restore:
			bx	= DriveStatusEntry where the disk should be.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		We can do nothing to help the kernel here, so just return
		with carry clear and everything else untouched.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskRestore	proc	far
		.enter
		clc
		.leave
		ret
DOSDiskRestore	endp


Resident	ends
