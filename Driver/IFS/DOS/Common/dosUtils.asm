COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driUtils.asm

AUTHOR:		Adam de Boor, Oct 31, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/31/91	Initial revision


DESCRIPTION:
	Random utility things, of course.
		

	$Id: dosUtils.asm,v 1.1 97/04/10 11:55:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSReadSectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a sector(s) from a drive.

CALLED BY:	INTERNAL
PASS:		bx:dx	= starting sector number
		cx	= number of sectors to read
		ds:di	= buffer to which to read them

		es:si	= DriveStatusEntry
			- or -

		si.high	= 0xff
		si.low  = drive number
		BIOS semaphore grabbed (or equivalent)

RETURN:		carry set on error:
			ax	= FileError for the problem
		carry clear on success:
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSReadSectors proc	far
		uses	bx, cx, dx, si, di, bp, es, ds
		.enter
	;
	; Gain exclusive access to DOS/BIOS.
	; 
		call	SysLockBIOS

	;
	;  See if someone is using a fake-DriveStatusEntry.  If they
	;	are, just call DOS, if not, continue
	;
		xchg	ax, si

		cmp	ax, 0ff00h
		jae	notHuge

		xchg	ax, si

	;
	; If sector(s) is(are) on the first track of a removable disk, use the
	; BIOS to read the thing so we don't involve the disk cache. This allows
	; for more reliable identification of floppy disks.
	;
		test	es:[si].DSE_status, mask DS_MEDIA_REMOVABLE
		jz	useDOS

	;
	; Standard BIOS supports only 2 floppies, and other BIOSes vault
	; off the deep end if you ask them to do something to a floppy
	; that doesn't exist. We also don't generate the right drive
	; number for BIOSes that do support more than two floppies anyway,
	; as the number spaces for floppies and fixed disks are disjoint.
	; For all these reasons, if the removable drive is not A or B, just
	; use DOS to read it.
	;
	  	cmp	es:[si].DSE_number, 2
	  	jae	useDOS

		tst	bx
		jnz	useDOS
		cmp	dx, MAX_NON_CACHE
		jae	useDOS		; start beyond the pale, so use DOS
		mov	ax, dx
		add	ax, cx		; ax <- last sector+1
		cmp	ax, MAX_NON_CACHE
		jbe	useBIOS		; on first track, so use BIOS
useDOS:
	;
	; Figure what interface to use to call DOS. If the drive is marked
	; as needing the 32-bit sector interface, use that.
	; 
		mov	al, es:[si].DSE_number	; al <- drive number

		push	es:[si].DSE_private
		mov	si, es:[si].DSE_fsd
		cmp	es:[si].FSD_handle, handle 0
		pop	si
		jne	notHuge
		tst	si				;if no private data
		jz	notHuge				;then assume not huge
		test	es:[si].DDPD_flags, mask DDPDF_HUGE
		jnz	readFromHuge

notHuge:
EC <		tst	bx						>
EC <		ERROR_NZ	SECTOR_OUT_OF_RANGE			>
		mov	bx, di		; ds:bx <- buffer
		push	ds, di, cx, bx, dx, ax
		int	25h
		inc	sp
		inc	sp
		pop	ds, di, cx, bx, dx, si
		jnc	doneUnlock
	;
	; Cope with attempting 16-bit read on 32-bit device when drive
	; managed by some driver other than us. We should get back
	; ERROR_UNKNOWN_MEDIA, suitably massaged, according to Drew @
	; Datalight, in which case we'll try a 32-bit read.
	; 
		cmp	al, ERROR_UNKNOWN_MEDIA - ERROR_WRITE_PROTECTED
		jne	doneUnlock
		stc
		mov_tr	ax, si
		jmp	readFromHuge
doneUnlock:

		call	SysUnlockBIOS
		jnc	ok
		
		clr	ah		; Convert error code to FileError
		add	al, ERROR_WRITE_PROTECTED
		stc
ok:
		.leave
		ret

readFromHuge:
	;
	; Set up parameter block for 32-bit read.
	;
		push	ds		; address of read buffer
		push	di
		push	cx		; # sectors to read
		push	bx		; starting sector
		push	dx
		segmov	ds, ss		; ds:bx = parameter block
		mov	bx, sp
		mov	cx, -1		; Indicate read on huge
		int	25h
		mov	bx, sp
		lea	sp, [bx+12]	; 10 for the parameters, 2 for
					;  the flags that DOS insists on
					;  leaving on the stack. Must use LEA
					;  to avoid nuking the carry.
		jmp	doneUnlock

useBIOS:
		mov	ah, B13F_READ_SECTOR
		call	DOSCallBIOS
		jnc	doneUnlock
	;
	; Deal with things that claim to be removable but aren't hooked into
	; BIOS, like LapLink disks...
	;
		clr	bx		; zero high sector word
		cmp	ah, B13E_INVALID_PARAMETER
		je	useDOS
		call	DOSMapBIOSError
		jmp	doneUnlock
DOSReadSectors endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCallBIOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a BIOS read/write access

CALLED BY:	DOSReadSectors, DOSWriteSectors
PASS:		ah	= bios operation to perform
		dx	= starting sector (high byte 0)
		cx	= # sectors to transfer (high byte 0)
		ds:di	= transfer address
		es:si	= DriveStatusEntry
		bios locked
RETURN:		carry set on error (AH = error number)
DESTROYED:	bx, bp, al if successful

PSEUDO CODE/STRATEGY:
		deal with BE_DMA_CROSSES_64K 
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCallBIOS	proc	near	uses dx, cx, es
		.enter
		mov	bp, B13F_MAX_RETRIES
		mov	al, cl		; al <- # sectors to read
		mov	cl, dl		; cl <- starting sector (ch [track #]
					;  already clear)
		mov	dl, es:[si].DSE_number	; dl <- drive # (dh
					;  [head number] already clear)
	;
	; If the drive is an alias, use the lower number, between it and its
	; alias, to talk to BIOS, on the assumption the lower number is the
	; physical drive.
	; 
		mov	bx, es:[si].DSE_fsd
		cmp	es:[bx].FSD_handle, handle 0
		jne	doIt

		mov	bx, es:[si].DSE_private
		tst	bx			;if no private data then assume
		jz	doIt			;no alias
		test	es:[bx].DDPD_flags, mask DDPDF_ALIAS
		jz	doIt
		cmp	dl, es:[bx].DDPD_alias
		jb	doIt
		mov	dl, es:[bx].DDPD_alias
doIt:
		inc	cx		; sector is 1-based. Everything else
					;  is 0-based...
		segmov	es, ds		; es:bx <- transfer address
		mov	bx, di

callBios:
		push	ax		; save function #
		int	13h

	;
	; Turn on interrupts to get around a bug in Datalite DOS 6.0
	; This should not hurt anything else
	;
		INT_ON

		jnc	done
		dec	bp
		jz	fail
if 0	; this was added to reduce the lag time in formatting a never-formatted
	; disk, but may cause problems unless wait/post is turned on. Since
	; we've other ways in 2.0 to reduce the lag time, don't do this.
	;  	-- ardeb 11/18/91
	;
	; Only retry if drive not ready or disk has changed.
	; XXX: can BIOS return other errors if motor not spun up but valid
	; disk is in the drive?
	;
		cmp	ah, B13E_DRIVE_NOT_READY
		je	retry
		cmp	ah, B13E_DISK_CHANGED
		jne	fail
	;
	; Retries not used up yet. Reset the disk system before retrying.
	;
retry:
endif
		mov	ah, B13F_RESET_DISK_SYSTEM
		int	13h
		pop	ax		; restore function # and retry
		jmp	callBios
done:
		pop	ax
exit:
		.leave
		ret
fail:
		inc	sp		; discard function #
		inc	sp
		stc
		jmp	exit
DOSCallBIOS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSWriteSectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a sector(s) to a drive.

CALLED BY:	INTERNAL
PASS:		bx:dx	= starting sector number
		cx	= number of sectors to write
		ds:di	= buffer from which to write them
		es:si	= DriveStatusEntry

		- or -

		si.high	= 0xff
		si.low	= drive number

RETURN:		carry set on error:
			ax	= FileError for the problem
		carry clear on success:
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSWriteSectors proc	far
		uses	bx, cx, dx, si, di, bp, es, ds
		.enter
	;
	;
	; Gain exclusive access to DOS/BIOS.
	; 
		call	SysLockBIOS

ifdef	HACK_FOR_LEXMARK_PROTOTYPE
PrintMessage <WARNING: Lexmark hack compiled in>
	;
	; The screwy Lexmark prototype does not deal correctly with the
	; FlashRam card.  It cannot write to it, but it does not return any
	; error.
	;
		cmp	es:[si].DSE_number, 1
		stc
		jz	doneUnlock
endif

	;
	; See if we are passed in a fake DSE.  If so, just call DOS
	; with the propper drive number, if not, continue
	;
		xchg	ax, si

		cmp	ax, 0ff00h
		jae	notHuge

		xchg	ax, si

	;
	; If sector(s) is(are) on the first track of a removable disk, use the
	; BIOS to write the thing so we don't involve the disk cache. This
	; allows for more reliable identification of floppy disks.
	;
		test	es:[si].DSE_status, mask DS_MEDIA_REMOVABLE
		jz	useDOS
	;
	; Standard BIOS supports only 2 floppies, and other BIOSes vault
	; off the deep end if you ask them to do something to a floppy
	; that doesn't exist. We also don't generate the right drive
	; number for BIOSes that do support more than two floppies anyway,
	; as the number spaces for floppies and fixed disks are disjoint.
	; For all these reasons, if the removable drive is not A or B, just
	; use DOS to read it.
	;
	  	cmp	es:[si].DSE_number, 2
	  	jae	useDOS

		tst	bx
		jnz	useDOS
		cmp	dx, MAX_NON_CACHE
		jae	useDOS		; start beyond the pale, so use DOS
		mov	ax, dx
		add	ax, cx		; ax <- last sector+1
		cmp	ax, MAX_NON_CACHE
		jbe	useBIOS		; on first track, so use BIOS
useDOS:
	;
	; Figure what interface to use to call DOS. If the drive is marked
	; as needing the 32-bit sector interface, use that.
	; 
		mov	al, es:[si].DSE_number	; al <- drive number

		push	es:[si].DSE_private
		mov	si, es:[si].DSE_fsd
		cmp	es:[si].FSD_handle, handle 0
		pop	si
		jne	notHuge
		tst	si				;if no private data
		jz	notHuge				;then assume not huge

		test	es:[si].DDPD_flags, mask DDPDF_HUGE
		jnz	writeToHuge
notHuge:
EC <		tst	bx						>
EC <		ERROR_NZ	SECTOR_OUT_OF_RANGE			>
		mov	bx, di		; ds:bx <- buffer
		push	ds, di, cx, bx, dx, ax
		int	26h
		inc	sp
		inc	sp

		pop	ds, di, cx, bx, dx, si
		jnc	doneUnlock
	;
	; Cope with attempting 16-bit write on 32-bit device when drive
	; managed by some driver other than us. We should get back
	; ERROR_UNKNOWN_MEDIA, suitably massaged, according to Drew @
	; Datalight, in which case we'll try a 32-bit read.
	; 
		cmp	al, ERROR_UNKNOWN_MEDIA - ERROR_WRITE_PROTECTED
		stc
		jne	doneUnlock
		mov_tr	ax, si
		jmp	writeToHuge

doneUnlock:
		call	SysUnlockBIOS
		jnc	ok
		clr	ah		; Convert error code to FileError
		add	al, ERROR_WRITE_PROTECTED
		stc
ok:
		.leave
		ret

writeToHuge:
	;
	; Set up parameter block for 32-bit write.
	;
		push	ds		; address of write buffer
		push	di
		push	cx		; # sectors to write
		push	bx		; starting sector
		push	dx
		segmov	ds, ss		; ds:bx = parameter block
		mov	bx, sp
		mov	cx, -1		; Indicate write on huge
		int	26h
		mov	bx, sp
		lea	sp, [bx+12]	; 10 for the parameters, 2 for
					;  the flags that DOS insists on
					;  leaving on the stack. Must use LEA
					;  to avoid nuking the carry.
		jmp	doneUnlock

useBIOS:
		mov	ah, B13F_WRITE_SECTOR
		call	DOSCallBIOS
		jnc	doneUnlock
	;
	; Deal with things that claim to be removable but aren't hooked into
	; BIOS, like LapLink disks...
	;
		clr	bx		; zero high sector word
		cmp	ah, B13E_INVALID_PARAMETER
		je	useDOS
		call	DOSMapBIOSError
		jmp	doneUnlock
DOSWriteSectors endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSMapBIOSError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a BIOS error code to a FileError

CALLED BY:	(INTERNAL) DOSWriteSectors, DOSReadSectors
PASS:		ah	= BiosInt13Error
RETURN:		carry set
		ax	= FileError - ERROR_WRITE_PROTECTED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSMapBIOSError	proc	near
		.enter
		CheckHack <FileError lt 256>	; fits in a byte

		mov	al, ERROR_SECTOR_NOT_FOUND
		cmp	ah, B13E_ADDRESS_MARK_NOT_FOUND
		je	done

		mov	al, ERROR_WRITE_PROTECTED
		cmp	ah, B13E_WRITE_PROTECTED
		je	done

		mov	al, ERROR_DISK_UNAVAILABLE
		cmp	ah, B13E_DISK_CHANGED
		je	done

		mov	al, ERROR_UNKNOWN_MEDIA
		cmp	ah, B13E_BAD_MEDIA_TYPE
		je	done

		mov	al, ERROR_CRC_ERROR
		cmp	ah, B13E_CRC_ERROR
		je	done
		
		mov	al, ERROR_SEEK_ERROR
		cmp	ah, B13E_SEEK_FAILED
		je	done
		
		mov	al, ERROR_DRIVE_NOT_READY
		cmp	ah, B13E_DRIVE_NOT_READY
		je	done
	;
	; anything else we declare general-failure. Of the known errors, this
	; covers: B13E_DMA_OVERRUN, B13E_DMA_CROSSES_64K, and
	; B13E_CONTROLLER_FAILURE
	;
		mov	al, ERROR_GENERAL_FAILURE
done:		
		clr	ah
		sub	ax, ERROR_WRITE_PROTECTED	; cope with addition
							; read/write routines
							; will perform...
		stc
		.leave
		ret
DOSMapBIOSError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLogWithDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Log a message to the system log giving the name of the
		drive affected.

CALLED BY:	DOSReadBootSector
PASS:		bx	= chunk of SBCS string in Strings segment
		es:si	= DriveStatusEntry of affected drive.
RETURN:		ds	= Strings segment
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLogWithDrive proc	near
		uses	si, ax, di, cx, es, bp
		.enter
	;
	; Figure how long the drive name is.
	; 
		lea	di, es:[si].DSE_name
if DBCS_PCGEOS
		call	LocalStringSize		;cx <- size w/o NULL
		LocalNextChar escx		;cx <- size w/NULL
else
		mov	cx, -1
		clr	al
		repne	scasb
		not	cx		; cx <- length + null
endif
	;
	; Figure how long the message chunk is and sum them to figure the
	; length of the overall message.
	; 
		segmov	ds, Strings, ax
		mov	bx, ds:[bx]
		ChunkSizePtr	ds, bx, ax	; includes null, too
		add	cx, ax			;  so adding it in
		andnf	cx, not 1		;  and doing this rounds up to
						;  a word boundary :)
	;
	; Make room for the combination on the stack.
	; 
		mov	bp, sp
		sub	sp, cx
		mov	di, sp
		push	es
		segmov	es, ss
	;
	; Copy the first part onto the stack.
	; 
		xchg	si, bx
copyMsgLoop:
		lodsb
		stosb
		tst	al
		loopne	copyMsgLoop
		inc	cx
		dec	di
	;
	; Point ds:si to the drive name and copy it in immediately after the
	; initial part of the message.
	; 
		pop	ds
		mov	si, bx
		add	si, offset DSE_name
if DBCS_PCGEOS
		shr	cx, 1			;cx <- # of chars
nameLoop:
		LocalGetChar ax, dssi		;ax <- character of string
		stosb				;store SBCS string
		loop	nameLoop
else
		rep movsb
endif
	;
	; Write the combination out.
	; 
		segmov	ds, ss
		mov	si, sp
		call	LogWriteEntry	
	;
	; Clear the stack and reload DS with the Strings segment, since we
	; promised we would.
	; 
		mov	sp, bp
		segmov	ds, Strings, ax
		.leave
		ret
DOSLogWithDrive endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadVarSegDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load dgroup into DS

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ds	= dgroup
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dgroupSeg	sptr	dgroup
if FULL_EXECUTE_IN_PLACE
LoadVarSegDSFar	proc	far
	call	LoadVarSegDS
	ret
LoadVarSegDSFar	endp
endif
LoadVarSegDS	proc	near
		.enter
		mov	ds, cs:[dgroupSeg]
		.leave
		ret
LoadVarSegDS	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllocDosHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a slot in the JFT for the caller and return 
		a handle suitable for passing to DOS

CALLED BY:	INTERNAL
PASS:		bl	= SFN
RETURN:		bx	= DOS handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSAllocDosHandleFar proc far
		call	DOSAllocDosHandle
		ret
DOSAllocDosHandleFar endp

DOSAllocDosHandle proc	near
		uses	ds, ax, cx, di, es
		.enter
		call	LoadVarSegDS
		call	SysLockBIOS	; gain exclusive access to the JFT,
					;  locking out other threads AND
					;  DOS...
	;
	; Block until an entry becomes available.
	;
		PSem	ds, jftEntries
	;
	; Now find the available entry. Since we've already got the BIOS
	; lock, we have exclusive access to the table.
	;
		les	di, ds:[jftAddr]
		mov	al, 0xff		; 0xff => free slot
MS <		mov	cx, ds:[jftSize]				>
OS2 <		mov	cx, ds:[jftSize]				>
DRI <		mov	cx, ds:[realJFTSize]				>
		repne	scasb
EC <		ERROR_NE	COULD_NOT_FIND_FREE_JFT_SLOT		>

   		dec	di			; back up to free slot
		mov	es:[di], bl		; store passed SFN to claim slot
	;
	; Convert the found slot to a DOS handle.
	;
		sub	di, ds:[jftAddr].offset
		mov	bx, di			; return in BX
		call	SysUnlockBIOS
		.leave
		ret
DOSAllocDosHandle endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFreeDosHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a handle allocated by DOSAllocDosHandle

CALLED BY:	INTERNAL
PASS:		bx	= handle to free (NIL if just releasing slot)
RETURN:		bl	= SFN of freed DOS handle
DESTROYED:	bh (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFreeDosHandleFar proc far
		call	DOSFreeDosHandle
		ret
DOSFreeDosHandleFar endp
DOSFreeDosHandle proc	near
		uses	ds, es, ax
		.enter
		pushf
		call	LoadVarSegDS
		call	SysLockBIOS
	;
	; Release the handle by storing 0xff in the proper place in the JFT.
	; No need to get BIOS b/c the operations are atomic.
	;
		cmp	bx, NIL
		je	slotFreed
		mov	es, ds:[jftAddr].segment
		add	bx, ds:[jftAddr].offset
		mov	al, NIL
		xchg	{byte}es:[bx], al
		mov_tr	bx, ax
slotFreed:
	;
	; Signal another free JFT slot...
	;
		VSem	ds, jftEntries
		call	SysUnlockBIOS
		popf
		.leave
		ret
DOSFreeDosHandle endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilFileSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use DOS to find the size of an open file.

CALLED BY:	DOSHandleOp, DOSVirtGetExtAttrsLow
PASS:		bx	= DOS handle to use
		bp	= private data offset for the open file
RETURN:		dx:ax	= file size
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSUtilFileSize	proc	far
		uses	cx, ds
		.enter
	;
	; Figure and save current file position
	;
		clr	cx
		mov	dx, cx
		mov	ax, FILE_POS_RELATIVE or (MSDOS_POS_FILE shl 8)
		call	FileInt21
		push	dx, ax
	;
	; Seek to the end, getting us the file size.
	;
		clr	cx
		mov	dx, cx
		mov	ax, FILE_POS_END or (MSDOS_POS_FILE shl 8)
		call	FileInt21
	;
	; Recover original position (cx:di, since we've got stuff in dx) and
	; save the file size.
	;
		pop	cx, di
		push	dx, ax
	;
	; Restore the original position.
	;
		mov	dx, di
		mov	ax, FILE_POS_START or (MSDOS_POS_FILE shl 8)
		call	FileInt21
	;
	; Recover file size, account for file header and return.
	;
		pop	dx, ax
		call	LoadVarSegDS
		test	ds:[bp].DFE_flags, mask DFF_GEOS
		jz	done
		sub	ax, size GeosFileHeader
		sbb	dx, 0
done:
		.leave
		ret
DOSUtilFileSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilFileForEach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal version of FileForEach that uses the dosFileTable
		to find files open to a particular disk. This is needed to
		avoid grabbing the fileListSem while holding a drive lock,
		which prevents app-level callbacks from doing anything
		meaningful with the handles they obtain.

CALLED BY:	(EXTERNAL)
PASS:		si	= handle of disk on which interesting files
			  must be located
		bx:di	= callback routine:
			  (may be vfptr if XIP'ed)
				Pass:	ds:bx	= DOSFileEntry
					cl	= SFN
					si	= disk handle
				Return:	carry set to stop enumerating
				Destroy:	di
RETURN:		carry set if callback returned carry set
		ax, dx as returned by callback
DESTROYED:	bx, di + whatever callback destroys.
SIDE EFFECTS:	none here.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSUtilFileForEach proc	far
callback	local	fptr.far	push	bx, di
		uses	ds, cx
		.enter

		mov	bx, offset dosFileTable
		call	LoadVarSegDS
		clr	cx
entryLoop:
		cmp	ds:[bx].DFE_disk, si
		jne	nextEntry
		
NOFXIP<		call	ss:[callback]					>
FXIP<		mov	ss:[TPD_dataAX], ax				>
FXIP<		mov	ss:[TPD_dataBX], bx				>
FXIP<		movdw	bxax, ss:[callback]				>
FXIP<		call	ProcCallFixedOrMovable				>
		jc	done
nextEntry:
		inc	cx
		add	bx, size DOSFileEntry
		cmp	bx, offset dosFileTable + size dosFileTable
		jb	entryLoop
		; (carry clear if jb, aka jc, not taken)
done:
		.leave
		ret
DOSUtilFileForEach endp




PathOps		segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathOps_LoadVarSegDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load dgroup into DS

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ds	= dgroup
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
pathOps_dgroupSeg	sptr	dgroup
PathOps_LoadVarSegDS	proc	near
		.enter
		mov	ds, cs:[pathOps_dgroupSeg]
		.leave
		ret
PathOps_LoadVarSegDS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLockCWD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain exclusive rights to mess with the DOS cwd.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLockCWDFar	proc	far
		call	DOSLockCWD
		ret
DOSLockCWDFar	endp

DOSLockCWD 	proc	near
		uses	ds
		.enter
		mov	ds, cs:[pathOps_dgroupSeg]
		PSem	ds, cwdSem
		.leave
		ret
DOSLockCWD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUnlockCWD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive rights to mess with the DOS cwd.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		?
DESTROYED:	nothing (carry preserved; other flags biffed)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSUnlockCWD 	proc	far
		uses	ds
		.enter
		mov	ds, cs:[pathOps_dgroupSeg]

if ERROR_CHECK
	;
	; Store some bogus values in some of the protected dgroup
	; variables, so we don't try to access them again
	;
		mov	ds:[dosFinalComponent].offset, -1
		mov	ds:[dosPathBuffer][0], 0

endif
		VSem	ds, cwdSem
		.leave
		ret
DOSUnlockCWD	endp

PathOps		ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCheckDiskIsOurs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make certain the disk in question is actually ours

CALLED BY:	INTERNAL
PASS:		es:di	= DiskDesc to check
RETURN:		carry set if it's ours
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCheckDiskIsOurs proc far
		uses	di
		.enter
		mov	di, es:[di].DD_drive
		mov	di, es:[di].DSE_fsd
		cmp	es:[di].FSD_strategy.segment, segment DOSStrategy
		je	done
		stc
done:
		cmc
		.leave
		ret
DOSCheckDiskIsOurs endp
		



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSGetTimeStamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the current date and time into two 16-bit records
		(FileDate and FileTime)

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		dx	= FileDate
		cx	= FileTime
DESTROYED:	bx (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSGetTimeStamp	proc	far
		uses	ax
		.enter
		pushf
		call	TimerGetDateAndTime
	;
	; Create the FileDate record first, as we need to use CL to the end...
	; 
		sub	ax, 1980	; convert to fit in FD_YEAR
			CheckHack <offset FD_YEAR eq 9>
		mov	ah, al
		shl	ah		; shift year into FD_YEAR
		mov	al, bh		; install FD_DAY in low 5 bits
		
		mov	cl, offset FD_MONTH
		clr	bh
		shl	bx, cl		; shift month into place
		or	ax, bx		; and merge it into the record
		xchg	dx, ax		; dx <- FileDate, al <- minutes,
					;  ah <- seconds
		xchg	al, ah
	;
	; Now for FileTime. Need seconds/2 and both AH and AL contain important
	; stuff, so we can't just sacrifice one. The seconds live in b<0:5> of
	; AL (minutes are in b<0:5> of AH), so left-justify them in AL and
	; shift the whole thing enough to put the MSB of FT_2SEC in the right
	; place, which will divide the seconds by 2 at the same time.
	; 
		shl	al
		shl	al		; seconds now left justified
		mov	cl, (8 - width FT_2SEC)
		shr	ax, cl		; slam them into place, putting 0 bits
					;  in the high part
	;
	; Similar situation for FT_HOUR as we need to left-justify the thing
	; in CH, so just shift it up and merge the whole thing.
	; 
		CheckHack <(8 - width FT_2SEC) eq (8 - width FT_HOUR)>
		shl	ch, cl
		or	ah, ch
		mov_tr	cx, ax		; smaller to do this than clr cl and
					;  or ax into cx...

		popf
		.leave
		ret
DOSGetTimeStamp	endp
PathOps	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSInternalSetDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change DOS's idea of the current directory for the current
		drive, noting that no thread currently has its current dir
		in DOS for sure.

CALLED BY:	INTERNAL
PASS:		ds:dx	= new directory
RETURN:		carry set on error:
			ax	= error code
		carry clear if ok
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSInternalSetDir proc	far
		.enter
if ERROR_CHECK
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
	;
	; Invalidate curPath.
	; 
		push	ds
		call	PathOps_LoadVarSegDS
		mov	ds:[curPath], 0
		pop	ds
	;
	; And perform the change.
	; 
if _MSLF
		mov	ax, MSDOS7F_SET_CURRENT_DIR
else
		mov	ah, MSDOS_SET_CURRENT_DIR
endif
		call	FileInt21
		.leave
		ret
DOSInternalSetDir endp

PathOps		ends

ExtAttrs	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtAttrs_LoadVarSegDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load dgroup into DS

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ds	= dgroup
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
extAttrs_dgroupSeg	sptr	dgroup
ExtAttrs_LoadVarSegDS	proc	near
		.enter
		mov	ds, cs:[extAttrs_dgroupSeg]
		.leave
		ret
ExtAttrs_LoadVarSegDS	endp

ExtAttrs	ends

PathOpsRare	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathOpsRare_LoadVarSegDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load dgroup into DS

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ds	= dgroup
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
pathOpsRare_dgroupSeg	sptr	dgroup
PathOpsRare_LoadVarSegDS	proc	near
		.enter
		mov	ds, cs:[pathOpsRare_dgroupSeg]
		.leave
		ret
PathOpsRare_LoadVarSegDS	endp

PathOpsRare	ends

if not DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilByteToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the passed byte to hex ascii

CALLED BY:	DOSReadBootSector, DOSVirtMapDosToGeosName
PASS:		al	= byte to convert
		es:di	= place in which to store characters
RETURN:		es:di	= after last char
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nibbles		char	"0123456789ABCDEF"

DOSUtilByteToAscii proc	far
		uses	bx
		.enter
		mov	bx, offset nibbles
		mov	ah, al
		andnf	ax, 0x0ff0
		shr	al
		shr	al
		shr	al
		shr	al
		cs:xlatb		; al <- nibble char
		stosb
		mov	al, ah
		cs:xlatb
		stosb
		.leave
		ret
DOSUtilByteToAscii endp
endif

if FULL_EXECUTE_IN_PLACE
ResidentXIP	segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPassOnInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass on an interrupt we've decided not to handle

CALLED BY:	DOSWaitPostHandler, DOSCriticalHandler
PASS:		ds:bx	= place where old handler is stored
		on stack (pushed in this order): bx, ax, ds
RETURN:		never
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DPOIStack       struct
    DPOIS_bp            word
    DPOIS_ax            word
    DPOIS_bx            word
    DPOIS_retAddr       fptr.far
    DPOIS_flags         word
DPOIStack       ends

DOSPassOnInterrupt proc	far jmp
                on_stack        ds ax bx retf
        ;
        ; Fetch the old vector into ax and bx
        ;
        	mov     ax, ds:[bx].offset
        	mov     bx, ds:[bx].segment
        	pop     ds

                on_stack        ax bx retf
        ;
        ; Now replace the saved ax and bx with the old vector, so we can
        ; just perform a far return to get to the old handler.
        ;
        	push    bp
                on_stack        bp ax bx retf
        	mov     bp, sp
        	xchg    ax, ss:[bp].DPOIS_ax
        	xchg    bx, ss:[bp].DPOIS_bx
        	pop     bp
                on_stack        retf
        	ret
DOSPassOnInterrupt endp

if FULL_EXECUTE_IN_PLACE
ResidentXIP	ends
endif

;DOSUtilOpen moved into resident resource 4/21/93 EDS because is used when
;re-opening the megafile.
;Resident	ends
;PathOps		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a file for internal use, dealing with running out of
		SFT space, etc.

CALLED BY:	EXTERNAL
PASS:		ds:dx	= file to open
		JFT slot allocated
		al	= FileAccess to use
RETURN:		carry set if couldn't open the file:
			ax	= error code
		carry clear if file open:
			ax	= DOS handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We first try and open the file in FE_COMPAT mode, so we are
		the final arbiters of what we can and cannot open.
		
		To deal with files opened before we were loaded, where share
		deny modes would have been passed, we try a second time in
		FE_NONE mode if the first try failed with ERROR_ACCESS_DENIED.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOSUtilOpenFar	proc	far
		call	DOSUtilOpen
		ret
DOSUtilOpenFar	endp

DOSUtilOpen	proc	near
		uses	bx
		.enter
		mov	ah, MSDOS_OPEN_FILE
			CheckHack <FileAccessFlags <FE_COMPAT, 0> eq 0>
MS <redo:								>
		push	ax
		call	DOSUtilInt21
		pop	bx
		jnc	done
MS <		cmp	ax, ERROR_TOO_MANY_OPEN_FILES			>
MS <		jne	tryDenyNone					>
MS <		call	MSExtendSFT					>
MS <		jc	done						>
MS <		mov_tr	ax, bx						>
MS <		jmp	redo						>
MS <tryDenyNone:							>
		cmp	ax, ERROR_SHARING_VIOLATION
		stc
		jne	done

		mov_tr	ax, bx		; ax <- open file & access mode
		or	al, FileAccessFlags <FE_NONE,0>

MS <redoDenyNone:							>
MS <		push	ax						>
		call	DOSUtilInt21
MS <		pop	bx						>
MS <		jnc	done						>
MS <		cmp	ax, ERROR_TOO_MANY_OPEN_FILES			>
MS <		stc							>
MS <		jne	done						>
MS <		call	MSExtendSFT					>
MS <		jc	done						>
MS <		mov_tr	ax, bx						>
MS <		jmp	redoDenyNone					>
done:
		.leave
		ret
DOSUtilOpen	endp

;PathOps		ends
;Resident	segment	resource

if not DBCS_PCGEOS

if _MSLF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilGeosToDosCharNoUpcase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a single character from the PC/GEOS character set
		to the DOS character set, NOT upcasing it as we go.

CALLED BY:	EXTERNAL
PASS:		al	= character to map
RETURN:		carry set if character cannot be mapped:
			al	= '_'
		carry clear if character mapped correctly:
			al	= new character
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	1/07/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSUtilGeosToDosCharNoUpcase	proc	far

	cmp	al, 'z'
	ja	passOn
	cmp	al, 'a'
	jb	passOn			; jump iff CF set
	; CF is clear here

	ret				; returns CF clear

passOn:
	FALL_THRU	DOSUtilGeosToDosChar

DOSUtilGeosToDosCharNoUpcase	endp

endif	; _MSLF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilGeosToDosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a single character from the PC/GEOS character set
		to the DOS character set, upcasing it as we go.

CALLED BY:	EXTERNAL
PASS:		al	= character to map
RETURN:		carry set if character cannot be mapped:
			al	= '_'
		carry clear if character mapped correctly:
			al	= new character
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSUtilGeosToDosChar proc far
		uses 	ds, bx
		.enter
		cmp	al, 0x80	; high ascii?
		jae	useCodePage	; yes => must use code page table
		
		cmp	al, 'a'		; below lower-case ascii?
		jb	mappedOK	; yes -- it's ok
		cmp	al, 'z'		; above upper-case ascii?
		ja	mappedOK	; yes -- it's ok
		sub	al, 'a' - 'A'	; convert from lower to upper
mappedOK:
		clc
done:
		.leave
		ret
useCodePage:
		call	LoadVarSegDS
		mov	bx, offset dosCodePage	; ds:bx <- code page table
	CheckHack <offset LCP_to eq 0x80>
		xlatb
		tst	al		; unmappable?
		jnz	mappedOK	; no -- it's ok
		mov	al, '_'		; replace with default char
		stc			; and signal our displeasure
		jmp	done
DOSUtilGeosToDosChar endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilDosToGeosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a DOS character to its corresponding PC/GEOS character,
		if possible.

CALLED BY:	EXTERNAL
PASS:		al	= character to map
RETURN:		carry set if character is unmappable:
			al	= untouched
		carry clear if character mapped:
			al	= mapped character
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSUtilDosToGeosChar proc far
		uses	ds, bx
		.enter
		cmp	al, 0x80
		jae	useCodePage
mappedOK:
		clc
done:
		.leave
		ret

useCodePage:
		call	LoadVarSegDS
			CheckHack <offset LCP_from eq 0>
		mov	bx, offset dosCodePage - 0x80
		mov	ah, al
		xlatb
		tst	al
		jnz	mappedOK
		mov	al, ah
		stc
		jmp	done
DOSUtilDosToGeosChar endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilDosToGeos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a null-terminated string from the DOS character set
		to the PC/GEOS character set. Any unmappable characters
		are replaced with question marks.

CALLED BY:	EXTERNAL
PASS:		ds:si	= null-terminated string to map
		cx	= max # chars to map
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSUtilDosToGeos proc	far
		uses	es, si, di
		.enter
		mov	di, si
		segmov	es, ds
convertLoop:
		lodsb
		tst	al
		jz	done
		call	DOSUtilDosToGeosChar
		jnc	storeNew
		mov	al, '?'
storeNew:
		stosb
		loop	convertLoop
done:
		.leave
		ret
DOSUtilDosToGeos endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilInt21
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call FileInt21, checking for errors and fetching the
		extended error code, if the DOS version supports it.

CALLED BY:	EXTERNAL
PASS:		ah	= DOS function
RETURN:		carry set:
			ax	= extended error code
		carry clear:
			whatever
DESTROYED:	?
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DEBUG_BOOT_SECTOR_CALLS

DOSUtilInt21	proc	far
	cmp	ah, MSDOS_READ_FILE
	je	noDebug
	cmp	ah, MSDOS_WRITE_FILE
	je	noDebug
	cmp	ah, MSDOS_POS_FILE
	je	noDebug
	GOTO	DOSUtilInt21Debug
noDebug:
	GOTO	DOSUtilInt21NoDebug
DOSUtilInt21	endp

endif


if DEBUG_BOOT_SECTOR_CALLS
DOSUtilInt21NoDebug	proc	far
else
DOSUtilInt21	proc	far
endif
		.enter
		call	SysLockBIOS		; ensure extended error code
						;  comes from this call, if
						;  we need it...
	;
	; Special-case someone else looking for the extended error code so
	; we get the dosLastCritical untouched (we assume the caller had the
	; BIOS lock so dosLastCritical is from the previous call)
	; 
		cmp	ah, MSDOS_GET_EXT_ERROR_INFO
		je	getErrorCode

		push	ds
		call	LoadVarSegDS
		mov	ds:[dosLastCritical], 0
		pop	ds

	;
	; See if the call returns the carry flag + error
	; 
		cmp	ah, MSDOS_FREE_SPACE
		je	callNoCheck
		cmp	ah, MSDOS_FIRST_FCB_CALL
		jb	callCheck
		cmp	ah, MSDOS_LAST_FCB_CALL
		jbe	callNoCheck

callCheck:
	;
	; It does. Make the call, then go get the extended error code if there
	; was an error.
	; 
		call	FileInt21
		jc	getErrorCode
done:
		call	SysUnlockBIOS
		.leave
		ret

callNoCheck:
	;
	; Some call that doesn't return an error code + carry flag, so just
	; issue the call and boogie.
	; 
		call	FileInt21
		jmp	done
		
getErrorCode:
		push	bx, cx, dx, si, di, bp, ds, es
		call	LoadVarSegDS
		mov	ax, ds:[dosLastCritical]
		tst	ax
		jnz	haveErrorCode

		mov	ah, MSDOS_GET_EXT_ERROR_INFO
		call	FileInt21
	;
	; 1/7/93: Hack for NetWare Lite, which returns ax=53h (fail on
	; critical error) in the face of a sharing violation. It also
	; returns ch=1 (error locus unknown), which we expect won't come
	; back for most other things. So we map such a thing to
	; ERROR_SHARING_VIOLATION so our virtual-name mapping stuff knows
	; to retry with DENY_NONE, instead of COMPAT. -- ardeb
	;
		cmp	ax, 53h
		jne	haveErrorCode
		cmp	ch, 1
		jne	haveErrorCode
		mov	ax, ERROR_SHARING_VIOLATION
haveErrorCode:
		pop	bx, cx, dx, si, di, bp, ds, es
EC <		cmp	ax, 6		; illegal handle?		>
EC <		ERROR_E	ILLEGAL_DOS_HANDLE				>
		stc
		jmp	done

if DEBUG_BOOT_SECTOR_CALLS
DOSUtilInt21NoDebug	endp
else
DOSUtilInt21	endp
endif




if DEBUG_BOOT_SECTOR_CALLS

DOSUtilInt21Debug	proc	far
		.enter
		call	SysLockBIOS		; ensure extended error code
						;  comes from this call, if
						;  we need it...
	;
	; Special-case someone else looking for the extended error code so
	; we get the dosLastCritical untouched (we assume the caller had the
	; BIOS lock so dosLastCritical is from the previous call)
	; 
		cmp	ah, MSDOS_GET_EXT_ERROR_INFO
		je	getErrorCode

		push	ds
		call	LoadVarSegDS
		mov	ds:[dosLastCritical], 0
		pop	ds

		call	FileInt21
		jc	getErrorCode
done:
		call	SysUnlockBIOS
		.leave
		ret
getErrorCode:
		push	bx, cx, dx, si, di, bp, ds, es
		call	LoadVarSegDS
		mov	ax, ds:[dosLastCritical]
		tst	ax
		jnz	haveErrorCode

		mov	ah, MSDOS_GET_EXT_ERROR_INFO
		call	FileInt21
	;
	; 1/7/93: Hack for NetWare Lite, which returns ax=53h (fail on
	; critical error) in the face of a sharing violation. It also
	; returns ch=1 (error locus unknown), which we expect won't come
	; back for most other things. So we map such a thing to
	; ERROR_SHARING_VIOLATION so our virtual-name mapping stuff knows
	; to retry with DENY_NONE, instead of COMPAT. -- ardeb
	;
		cmp	ax, 53h
		jne	haveErrorCode
		cmp	ch, 1
		jne	haveErrorCode
		mov	ax, ERROR_SHARING_VIOLATION
haveErrorCode:
		pop	bx, cx, dx, si, di, bp, ds, es
EC <		cmp	ax, 6		; illegal handle?		>
EC <		ERROR_E	ILLEGAL_DOS_HANDLE				>
		stc
		jmp	done
DOSUtilInt21Debug	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSClearJFTEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  everytime gsdos does a search, it writes a value in the JFT, and
	   stores the same value as the first byte in the DTA. However if the
           DTA block is moved before the next search, they have no way of
           identifying this entry and clearing the JFT, which slowly starts
           filling up. So we have to clean up after them. -mjoy 1/29/97
CALLED BY: DOSFileEnum,
	   DOSPathOpDeleteDir,
	   DOSVirtMapCheckDosName,
	   DOSVirtMapCheckGeosName
PASS:		al - first byte of data in the DTA
RETURN:		nothing
DESTROYED:	nothing(flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	mjoy    	2/ 4/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if GSDOS

DOSClearJFTEntry	proc	far
	uses	bx, cx, di, ds, es
		.enter
		pushf
		cmp	al, NIL
		je	noJFTEntry
		call	LoadVarSegDS
	;
	; gain exclusive access to JFT
	;
		call	SysLockBIOS
		les	di, ds:[jftAddr]
		mov	cx, ds:[jftSize]
	;
	; search for matching entry in JFT
	;
		repne	scasb
		jne	unlockBIOS
	;
	; convert address to handle to pass to DOS
	;
		dec	di
		sub	di, ds:[jftAddr].offset
		mov	bx, di
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
unlockBIOS:
		call	SysUnlockBIOS
noJFTEntry:
		popf
	.leave
	ret
DOSClearJFTEntry	endp

endif		;GSDOS


Resident	ends

if _MSLF

PathOps		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilCopyFilenameFFDToFindData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the DOS short filename in dosNativeFFD.FFD_name to
		dos7FindData.W32FD_fileName.

CALLED BY:	EXTERNAL
PASS:		filename in dosNativeFFD.FFD_name
RETURN:		filename copied to dos7FindData.W32FD_fileName
		dos7FindData.W32FD_alternateFileName[0] set to 0
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	1/13/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSUtilCopyFilenameFFDToFindData	proc	far
	uses	cx, si, di, ds, es
	.enter

	call	PathOps_LoadVarSegDS
	segmov	es, ds
	mov	si, offset dosNativeFFD.FFD_name
	mov	di, offset dos7FindData.W32FD_fileName
	mov	cx, DOS_DOT_FILE_NAME_LENGTH_ZT
	rep	movsb

	mov	ds:[dos7FindData].W32FD_alternateFileName[0], 0

	.leave
	ret
DOSUtilCopyFilenameFFDToFindData	endp

PathOps		ends

endif	; _MSLF
