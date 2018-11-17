COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Drive
FILE:		driveHigh.asm

AUTHOR:		Cheng, 11/89

ROUTINES:
	Name			Description
	----			-----------
    GLB DriveGetStatusFar	Returns info on the disk drive specified.

    GLB DriveGetStatus		Returns info on the disk drive specified.

    GLB DriveGetExtStatus	Return the status word for the disk drive
				specified

    GLB DriveGetDefaultMedia	Returns the PC/GEOS media descriptor of the
				highest density format for the given drive.

    GLB DriveTestMediaSupport	For the specified drive, test to see if it
				supports the given media.

   RGLB DriveLockExclFar	Lock a drive for exclusive access by the
				current thread.

   RGLB DriveLockExcl		Lock a drive for exclusive access by the
				current thread.

    INT DriveUnlockExclFar	Release a drive for others to use.

    INT DriveUnlockExcl		Release a drive for others to use.

    GLB DriveGetName		Fetch the name of a drive, given its
				number.

    EXT DriveLocateByNumberFar	Locate a drive given its number.

    EXT DriveLocateByNumber	Locate a drive given its number.

    EXT DriveLocateByNameFar	Locate a drive given its name in a file
				path.

    EXT DriveLocateByName	Locate a drive given its name in a file
				path.

    INT DriveExtractDriveEntryByte Fetch a single byte from a
				DriveStatusEntry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial revision

DESCRIPTION:
	Global routines that allow callers to query the kernel about
	the drive configuration.
		
	$Id: driveHigh.asm,v 1.1 97/04/05 01:11:29 newdeal Exp $

-------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;
;		      GENERALLY GLOBAL ROUTINES
;
;------------------------------------------------------------------------------


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DriveGetStatus

DESCRIPTION:	Returns info on the disk drive specified.

CALLED BY:	GLOBAL

PASS:		al - based drive number

RETURN:		ah - drive status, see DriveStatus in drive.def
		carry flag set if drive not present

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version
	ardeb	7/24/91		Converted to 2.0

-------------------------------------------------------------------------------@

DriveGetStatusFar	proc	far
			call	DriveGetStatus
			ret
DriveGetStatusFar	endp
		public	DriveGetStatusFar

DriveGetStatus	proc	near
		uses	bx
		.enter
		mov	bx, offset DSE_status
		call	DriveExtractDriveEntryByte
		.leave
		ret
DriveGetStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveGetExtStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the status word for the disk drive specified

CALLED BY:	GLOBAL
PASS:		al	= drive number
RETURN:		carry set if drive doesn't exist.
		carry clear if drive found:
			ax	= DriveExtendedStatus
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveGetExtStatus proc	far
		uses	es, si
		.enter
		call	FileLockInfoSharedToES
		call	DriveLocateByNumber
		jc	done
		mov	ax, es:[si].DSE_status
done:
		call	FSDUnlockInfoShared
		.leave
		ret
DriveGetExtStatus endp

Filemisc	segment	resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DriveGetDefaultMedia

DESCRIPTION:	Returns the PC/GEOS media descriptor of the highest density
		format for the given drive.

CALLED BY:	GLOBAL

PASS:		al - based drive number

RETURN:		carry set if drive doesn't exist.
		carry clear if it does:
			ah - PC/GEOS media descriptor

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

DriveGetDefaultMedia	proc	far
		uses	bx
		.enter
		mov	bx, offset DSE_defaultMedia
		call	DriveExtractDriveEntryByte
		.leave
		ret
DriveGetDefaultMedia	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DriveTestMediaSupport

DESCRIPTION:	For the specified drive, test to see if it supports
		the given media.

CALLED BY:	GLOBAL

PASS:		al - drive number
		ah - PC/GEOS media descriptor

RETURN:		carry clear if drive supports media
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

DriveTestMediaSupport	proc	far
	uses ax, di, es, cx
	.enter
	;
	; Find the search start in the MediaSupportTable by locating the
	; highest-density media supported by the drive in that table.
	; Once we've got the starting point, we can then look through the
	; table until we either find the passed media type or a 0.
	;
	push	ax
	call	DriveGetDefaultMedia		;ah <- max density media

	segmov	es, cs
	mov	di, offset MediaSupportTable
	mov	cx, length MediaSupportTable
	mov	al, ah
	
	repne	scasb
	xchg	si, di				; preserve si w/o push
						; si <- search point
	jne	notFound

	dec	si				; point back at match for
						;  default
	pop	ax
	
searchLoop:
	lodsb	es:				; Fetch next possible media type
	tst	al				; End of table?
	jz	notFound			; Yes -- passed media not good
	cmp	al, ah				; Match?
	jne	searchLoop			; No -- keep looking
	; carry cleared by == comparison
done:
	mov	si, di				; restore si..
	.leave
	ret
notFound:
	stc					; Signal bad media
	jmp	done
DriveTestMediaSupport	endp


; The table is ordered by density, With the assumption that any drive that
; supports a given density can support any of the lower densities for the
; given disk size. See above.
	CheckHack <MEDIA_NONEXISTENT eq 0>
if PZ_PCGEOS
MediaSupportTable	MediaType	\
	MEDIA_1M2,		; 5.25" 1.2Mb (high-density)
	MEDIA_360K,		; 5.25" 360Kb (double-sided)
	MEDIA_320K,		; 5.25" 320Kb (double-sided)
	MEDIA_180K,		; 5.25" 180K (single-sided)
	MEDIA_160K,		; 5.25" 160K (single-sided)
	MEDIA_NONEXISTENT,		

	MEDIA_2M88,		; 3.5" 2.88 Mb (/s:36 /t:80)
	MEDIA_1M44,		; 3.5" 1.44 Mb
	MEDIA_720K,		; 3.5" 720Kb
	MEDIA_NONEXISTENT,	; Break in table

;PIZZA specific
	MEDIA_1M232,		; 3.5" 1.232 Mb
	MEDIA_640K,		; 3.5" 640Kb
	MEDIA_NONEXISTENT,	; Break in table

	MEDIA_FIXED_DISK,	; No options for fixed disk
	MEDIA_NONEXISTENT,

	MEDIA_SRAM,
	MEDIA_NONEXISTENT,

	MEDIA_FLASH,
	MEDIA_NONEXISTENT,

	MEDIA_ATA,
	MEDIA_NONEXISTENT,
	
	MEDIA_CUSTOM,		; Unknown
	MEDIA_NONEXISTENT
else
MediaSupportTable	MediaType	\
	MEDIA_1M2,		; 5.25" 1.2Mb (high-density)
	MEDIA_360K,		; 5.25" 360Kb (double-sided)
	MEDIA_320K,		; 5.25" 320Kb (double-sided)
	MEDIA_180K,		; 5.25" 180K (single-sided)
	MEDIA_160K,		; 5.25" 160K (single-sided)
	MEDIA_NONEXISTENT,		

	MEDIA_2M88,		; 3.5" 2.88 Mb (/s:36 /t:80)
	MEDIA_1M44,		; 3.5" 1.44 Mb
	MEDIA_720K,		; 3.5" 720Kb
	MEDIA_NONEXISTENT,	; Break in table

	MEDIA_FIXED_DISK,	; No options for fixed disk
	MEDIA_NONEXISTENT,

	MEDIA_SRAM,
	MEDIA_NONEXISTENT,

	MEDIA_FLASH,
	MEDIA_NONEXISTENT,

	MEDIA_ATA,
	MEDIA_NONEXISTENT,
	
	MEDIA_CUSTOM,		; Unknown
	MEDIA_NONEXISTENT
endif


Filemisc	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLockExclGlobal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a drive for exclusive access by the current thread.

CALLED BY:	RESTRICTED GLOBAL
PASS:		al	= number of drive to lock
RETURN:		carry set if drive doesn't exist
DESTROYED:	flags, si (returned as offset of DriveStatusEntry of drive
		for those In The Know)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriveLockExclGlobal	proc	far
		uses	es
		.enter
	; XXX: this used to deal with being called on the kernel thread by
	; not locking the drive (to avoid deadlock during a dirty shutdown)

		call	FileLockInfoSharedToES
		call	DriveLocateByNumber
		jc	fail
		stc				; mark busy
		call	DriveLockExclCommon
		clc
done:
		.leave
		ret
fail:
		call	FSDUnlockInfoShared
		jmp	done
DriveLockExclGlobal	endp
		public	DriveLockExclGlobal	; exported as alias




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLockExclCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to lock a drive for exclusive access.

CALLED BY:	DriveLockExclGlobal, DriveLockExcl
PASS:		es:si	= DriveStatusEntry
		es	= locked for shared access
		carry set if should mark drive busy
RETURN:		drive is marked DES_BUSY if carry set on entry
		shared lock on the FSIR released
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveLockExclCommon proc near
		uses	di, bp
		.enter
	;
	; If DSE_exclusive is grabbed while we've got the FSIR locked for
	; exclusive access, it means the drive is in-use by DiskFormat,
	; DiskCopy, or something external to the kernel, so we fail the
	; lock request. This decision is based on the requirement that
	; the FSIR be locked shared the whole time a drive is locked
	; shared, so the only way DSE_exclusive can be taken while we've
	; got the FSIR locked exclusive is if the drive has been locked
	; exclusive and the FSIR released, as happens with DiskFormat et al.
	;
	; 5/20/92: REVISIT THIS, AS WE NO LONGER HAVE THE FSIR EXCL HERE
	; 	-- ardeb
	;
	; 6/15/92: since we only come here with shared access on the FSIR,
	; the above concerns are moot. The thread doing the format will
	; always be able to lock the FSIR to unlock the drive, so no
	; deadlock should result...in theory -- ardeb
	; 
		mov	di, mask DES_BUSY
		jc	grabExcl
		clr	di
grabExcl:
		PSem	es, [si].DSE_exclusive
		ornf	es:[si].DSE_status, di
	;
	; Notify the IFS driver that the disk is now locked.
	; 
		mov	bp, es:[si].DSE_fsd
		mov	di, DR_FS_DRIVE_LOCK
		call	es:[bp].FSD_strategy

	;
	; Release exclusive access to the FSIR
	; 
		call	FSDUnlockInfoShared
		.leave
		ret
DriveLockExclCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLockExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kernel-internal form of locking a drive for exclusive access.

CALLED BY:	EXTERNAL
PASS:		si	= offset of DriveStatusEntry to lock
RETURN:		DES_BUSY set for the drive as well
		ds, es	= fixed up if pointing to FSIR on entry and
			  FSIR moved while waiting for exclusive access
		es	= destroyed if not pointing to FSIR on entry
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		As detailed in the README, we gain exclusive access to the
		FSIR before locking the drive itself for exclusive access
		to deal with the long-term busy tendency of things that
		call us.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveLockExclFar proc far
		call	DriveLockExcl
		ret
DriveLockExclFar endp
		public	DriveLockExclFar	; exported as FSDLockDriveExcl

DriveLockExcl	proc	near
		.enter
		call	FileLockInfoSharedToES
		stc
		call	DriveLockExclCommon
		.leave
		ret
DriveLockExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLockExclNoBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a drive for exclusive access without marking it busy

CALLED BY:	EXTERNAL (DiskRegisterSetup)
PASS:		es	= FSIR locked shared
		si	= offset of DriveStatusEntry to lock
RETURN:		es	= fixed up if FSIR moved while waiting for exclusive
			  access
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveLockExclNoBusy proc far
		.enter
		call	FileLockInfoSharedToES
		clc
		call	DriveLockExclCommon
		.leave
		ret
DriveLockExclNoBusy endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveUnlockExclGlobal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a drive for others to use.

CALLED BY:	RESTRICTED GLOBAL
PASS:		al	= drive number
RETURN:		nothing (fatal error if drive doesn't exist)
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 5/90		Initial version
	ardeb	7/24/91		converted to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriveUnlockExclGlobal	proc	far
		uses	es, si, bx
		.enter
	; XXX: this used to have companion code to that in DriveLockExcl
	; that dealt with being called from the kernel thread.
		pushf
		call	FileLockInfoSharedToES
		call	DriveLocateByNumber
EC <		ERROR_C	BAD_DRIVE_SPECIFIED				>
   		mov	bx, si
		call	DriveUnlockExcl
		call	FSDUnlockInfoShared
		popf
		.leave
		ret
DriveUnlockExclGlobal	endp
		public	DriveUnlockExclGlobal	; exported as alias


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveUnlockExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kernel-internal form of releasing exclusive access to a drive

CALLED BY:	EXTERNAL
PASS:		es:si	= DriveStatusEntry to release
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveUnlockExclFar proc far
		call	DriveUnlockExcl
		ret
DriveUnlockExclFar endp
		public	DriveUnlockExclFar	; exported as FSDUnlockDriveExcl

DriveUnlockExcl proc	near
		uses	bp, di, si
		.enter
		pushf
EC <		tst	es:[si].DSE_shareCount				>
EC <		ERROR_NZ	DRIVE_NOT_LOCKED_EXCLUSIVE		>
	;
	; Let the IFS driver know we're unlocking the drive.
	; 
		mov	bp, es:[si].DSE_fsd
		mov	di, DR_FS_DRIVE_UNLOCK
		call	es:[bp].FSD_strategy
	;
	; And perform the unlock
	; 
		andnf	es:[si].DSE_status, not mask DES_BUSY
		VSem	es, [si].DSE_exclusive
		popf
		.leave
		ret
DriveUnlockExcl	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLockShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the passed drive for shared access

CALLED BY:	EXTERNAL
       		DiskLock
PASS:		es:bp	= DriveStatusEntry to lock shared.
		al	= FILE_NO_ERRORS bit set if lock may not be
			  aborted.
RETURN:		carry set if drive is busy and FILE_NO_ERRORS wasn't
			passed
		carry clear if drive is locked shared.
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveLockShared	proc	near
		uses	ax
		.enter
	;
	; If the lock may be aborted, see if the drive is marked busy and
	; return carry set if it is. One might be concerned that after
	; the test, another thread could come in and make the drive busy,
	; and that much is true, but there's really not a whole lot we
	; can do about it...
	; 
		test	al, FILE_NO_ERRORS
		jnz	lockIt
		
		test	es:[bp].DSE_status, mask DES_BUSY
		stc
		jnz	done

lockIt:
	;
	; Gain exclusive access to DSE_shareCount.
	; 
		PSem	es, [bp].DSE_shareSem, TRASH_AX_BX
		mov	ax, es:[bp].DSE_shareCount
		tst	ax
		jnz	sharedLockSnagged
	;
	; First sharer to come this way, so grab the exclusive for the
	; drive as well, thereby blocking anyone who wants the exclusive.
	; 
		PSem	es, [bp].DSE_exclusive
sharedLockSnagged:
	;
	; Up the number of sharers so we know when to release the exclusive.
	; 
		inc	ax
		mov	es:[bp].DSE_shareCount, ax
		VSem	es, [bp].DSE_shareSem, TRASH_AX_BX
	;
	; Signal success.
	; 
		clc
done:
		.leave
		ret
DriveLockShared	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveUnlockShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release shared access to a disk drive

CALLED BY:	EXTERNAL
       		DiskUnlock
PASS:		es:bx	= DriveStatusEntry to release
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveUnlockShared proc	near
		.enter
	;
	; Gain exclusive access to the DSE_shareCount variable.
	; 
		PSem	es, [bx].DSE_shareSem, TRASH_AX
	;
	; One fewer shared lock on the thing. If DSE_shareCount now zero,
	; release the drive exclusive, too.
	; 
		dec	es:[bx].DSE_shareCount
		jnz	sharedLockReleased

		VSem	es, [bx].DSE_exclusive
sharedLockReleased:
		VSem	es, [bx].DSE_shareSem, TRASH_AX_BX
		.leave
		ret
DriveUnlockShared endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLocateByNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate a drive given its number.

CALLED BY:	EXTERNAL/INTERNAL
PASS:		es	= FSInfoResource locked shared or exclusive
		al	= drive number to find
RETURN:		carry set if drive doesn't exist.
		carry clear if it does:
			es:si	= DriveStatusEntry for it.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveLocateByNumber	proc	far
		.enter
		mov	si, offset FIH_driveList - offset DSE_next
searchLoop:
		mov	si, es:[si].DSE_next
		tst	si
		jz	done
		cmp	es:[si].DSE_number, al
		jne	searchLoop
		stc			; so carry returned clear...
done:
		cmc			; flip the carry so we return carry
					;  set on failure. We do it this way
					;  to save bytes and to avoid wasting
					;  2 cycles each time through the loop
		.leave
		ret
DriveLocateByNumber	endp

;-----------------------------------------------------------

FileCommon segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the name of a drive, given its number.

CALLED BY:	GLOBAL
		FileConstructFullPath
PASS:		al	= drive number
		es:di	= buffer in which to place the result
		cx	= number of bytes in the buffer
RETURN:		carry clear if drive exists & buffer large enough:
			cx	= # bytes remaining in the buffer,
				  including null-terminator
			es:di	= null-terminator
		carry set if drive doesn't exist or buffer too small
			cx	= 0 if drive doesn't exist
				= # bytes needed if buffer too small (includes
				  room for null-terminator)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveGetName	proc	far
		uses	ds, si, ax
		.enter
EC <		push	ax						>
EC <		pushf							>
EC <		pop	ax						>
EC <		test	ax, mask CPU_DIRECTION				>
EC <		ERROR_NZ DIRECTION_FLAG_SET				>
EC <		pop	ax						>

if	FULL_EXECUTE_IN_PLACE
EC <	jcxz	noCheck							>
EC<	push	bx, si							>
EC<	movdw	bxsi, esdi						>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx, si							>
EC <noCheck:								>
endif
	;
	; Locate the DriveStatusEntry for the beast.
	; 
		push	es
		call	FileLockInfoSharedToES
		call	DriveLocateByNumber
		jc	driveExistethNot
	;
	; Copy the null-terminated name into the buffer.
	; 
		segmov	ds, es
		pop	es
		push	bx
DBCS <		shr	cx, 1						>
		mov	bx, cx		; record passed buffer size in case it's
					;  too small
		add	si, offset DSE_name
		jcxz	notEnoughRoom
copyLoop:
		LocalGetChar ax, dssi
		LocalPutChar esdi, ax
		LocalIsNull ax		; null-terminator?
		loopne	copyLoop	; loop if not & still room
		jne	notEnoughRoom	; => stopped w/o hitting null

		LocalPrevChar esdi	; back up to null-terminator
		inc	cx		;  and account for it
		pop	bx
done:
	;
	; Release the FSInfoResource
	; 
		call	FSDUnlockInfoShared
DBCS <		shl	cx, 1						>
		.leave
		ret

driveExistethNot:
	;
	; Drive number passed is invalid -- return carry set and cx = 0
	; 
		mov	cx, 0
		pop	es
		jmp	done

notEnoughRoom:
	;
	; Not enough room in the destination buffer -- figure how many bytes
	; would actually be required.
	; 
		LocalGetChar ax, dssi
		LocalIsNull ax
		loopne	notEnoughRoom

		sub	cx, bx
		neg	cx
		pop	bx		; recover passed bx
		stc			; and set carry to indicate error
		jmp	done
DriveGetName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveLocateByName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate a drive given its name in a file path.

CALLED BY:	EXTERNAL
PASS:		es	= FSInfoResource, locked shared or exclusive
		ds:dx	= file path with possible drive name
RETURN:		carry set if no drive of specified name
			ds:dx	= file path w/o drive specifier
			si	= 0
		carry clear if either no drive in path, or drive found:
			si	= offset of DriveStatusEntry if drive given
				  and found, or 0 if no drive given
			ds:dx	= file path w/o drive specifier
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP		segment	resource
DriveLocateByName		proc	far
	mov	ss:[TPD_dataBX], handle DriveLocateByNameReal
	mov	ss:[TPD_dataAX], offset DriveLocateByNameReal
	GOTO	SysCallMovableXIPWithDSDX
DriveLocateByName		endp
CopyStackCodeXIP		ends

else

DriveLocateByName		proc	far
	FALL_THRU	DriveLocateByNameReal
DriveLocateByName		endp

endif

DriveLocateByNameReal	 proc	far
		uses	ax, di, cx
		.enter
	;
	; See if path has a drive specifier on it.
	; 
		mov	si, dx
findSpecLoop:
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		jz	noDriveSpecifier
		LocalCmpChar	ax, '\\'		; hit a directory?
		je	noDriveSpecifier	; ja -- give up now
		LocalCmpChar	ax, ':'
		jne	findSpecLoop		; not the end yet...
	;
	; Well, the path's got a drive specifier; figure its length and
	; go looking for a drive of the same name.
	; 
SBCS < 		lea	cx, [si-1]		; don't include ':'...	>
DBCS < 		lea	cx, [si-2]		; don't include ':'...	>
		sub	cx, dx			; cx <- size of specifier
DBCS <		shr	cx, 1			; cx <- length of specifier >

		mov	di, offset FIH_driveList - offset DSE_next
		clr	ax			; clear al now so we can easily
						;  check for null terminator
findDriveLoop:
	    ;
	    ; Advance to the next drive. If there is no next drive, we try
	    ; the whole thing again ignoring case in our comparisons.
	    ; 
		mov	di, es:[di].DSE_next
		tst	di
		jz	tryIgnoreCase
	    ;
	    ; Compare the drive specifier to the drive name, using the length
	    ; up to, but not including, the colon (as that should mismatch with
	    ; the null-terminator if this is the right drive).
	    ; XXX: what about case-sensitivity?
	    ; 
		push	cx, di
		add	di, offset DSE_name
		mov	si, dx
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		jne	10$		; if something didn't match, don't check
					;  for null terminator
SBCS <		scasb			; else make sure current drive-name cha>
DBCS <		scasw			; else make sure current drive-name cha>
					;  is its null terminator
10$:
		pop	cx, di
		jne	findDriveLoop	; mismatch either in the body or at the
					;  end -- continue our quest.
foundDrive:
	;
	; Found the drive. Set up return values and boogie. Carry already
	; cleared by == comparison, in theory.
	; 
SBCS <		lea	dx, ds:[si+1]	; dx <- first char after the drive >
DBCS <		lea	dx, ds:[si+2]	; dx <- first char after the drive >
					;  separator (at which si currently
					;  points)
		mov	si, di		; es:si <- DriveStatusEntry
done:
		.leave
		ret

	;--------------------
noDriveSpecifier:
	;
	; Path has no drive specifier, so just clear si, which clears the
	; carry, and get out.
	; 
		clr	si
		jmp	done

	;--------------------
tryIgnoreCase:
	;
	; To deal with DOS user's propensity for using lower case where
	; DOS uses upper case, we go through the list again performing case-
	; insensitive string comparisons on the drive names, since our
	; literal comparisons failed to find a match.
	; 
		mov	di, offset FIH_driveList - offset DSE_next
findDriveNoCaseLoop:
	    ;
	    ; Advance to the next drive. If there is no next drive, we bitch.
	    ; 
		mov	di, es:[di].DSE_next
		tst	di
		jz	driveNotFound
	    ;
	    ; Compare the drive specifier to the drive name, using the length
	    ; up to, but not including, the colon (as that should mismatch with
	    ; the null-terminator if this is the right drive).
	    ; XXX: what about case-sensitivity?
	    ; 
		push	di
		add	di, offset DSE_name
		mov	si, dx
		call	LocalCmpStringsNoCase
		jne	20$		; if something didn't match, don't check
					;  for null terminator
		add	di, cx
DBCS <		add	di, cx						>
SBCS <		scasb			; else make sure current drive-name cha>
DBCS <		scasw			; else make sure current drive-name cha>
					;  is its null terminator
20$:
		pop	di
		jne	findDriveNoCaseLoop	; mismatch either in the body or
						;  at the end -- continue our
						;  quest.
		add	si, cx
DBCS <		add	si, cx						>
		jmp	foundDrive

driveNotFound:
	;
	; Couldn't find the drive in the file path (different from path having
	; no drive) -- return carry set to signal our displeasure.
	; 
		add	dx, cx		; point past drive specifier anyway
		LocalNextChar dsdx
		clr	si		; signal no drive
		stc
		jmp	done
DriveLocateByNameReal endp

FileCommon	ends

;-----------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveExtractDriveEntryByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a single byte from a DriveStatusEntry

CALLED BY:	DriveGetStatus, DriveGetDefaultMedia
PASS:		al	= drive number
		bx	= offset within DriveStatusEntry from which to
			  fetch the byte.
RETURN:		carry set if drive doesn't exist.
		carry clear if it does:
			ah	= drive fetched.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveExtractDriveEntryByte proc	far
		uses	es, si
		.enter
		call	FileLockInfoSharedToES
		call	DriveLocateByNumber
		jc	done
		mov	ah, es:[si+bx]
done:
		call	FSDUnlockInfoShared
		.leave
		ret
DriveExtractDriveEntryByte endp
