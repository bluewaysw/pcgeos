COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fsdDrive.asm

AUTHOR:		Adam de Boor, Jul 24, 1991

ROUTINES:
	Name			Description
	----			-----------
   RGLB	FSDInitDrive		Allocate a drive descriptor for the given
				drive. Will re-use an existing one, if
				such exists.
   RGLB	FSDDeleteDrive		Delete a drive descriptor, so long as it's
				not currently in use.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/24/91		Initial revision


DESCRIPTION:
	FSD helper routines that manipulate DriveStatusEntry structures.
		

	$Id: fsdDrive.asm,v 1.1 97/04/05 01:17:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


; GRRR: These things must reside in Filemisc so FSDDeleteDrive can call
; DiskCheckInUse while holding exclusive access to the FSIR -- ardeb 10/5/93
; 
Filemisc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDInitDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize a descriptor for a drive.

CALLED BY:	RESTRICTED GLOBAL
PASS:		al	= drive number (-1 if should be assigned based on
			  the drive name).
		ah	= MediaType for default (highest-density) media
		bx	= offset of private data chunk for the drive
			  (0 if no private data needed for the drive)
		cx	= DriveExtendedStatus
		dx	= FSDriver offset
		ds:si	= asciiz drive name
		
		FSInfoResource MUST NOT BE LOCKED
RETURN:		dx	= offset of DriveStatusEntry
DESTROYED:	ax, cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FSDInitDrive		proc	far
	mov	ss:[TPD_dataBX], handle FSDInitDriveReal
	mov	ss:[TPD_dataAX], offset FSDInitDriveReal
	GOTO	SysCallMovableXIPWithDSSI
FSDInitDrive		endp
CopyStackCodeXIP		ends

else

FSDInitDrive		proc	far
	FALL_THRU	FSDInitDriveReal
FSDInitDrive		endp

endif
FSDInitDriveReal	proc	far
		uses	es, di
		.enter
	;
	; Gain exclusive access to the block. This synchronizes the creation/
	; deletion of drives, as well as allowing the block to move.
	; 
		call	FSDLockInfoExclToES
		assume	es:FSInfoResource, ds:nothing

		cmp	al, -1		; are we to make up a number?
		jne	findExisting	; no -- go look for an existing drive
					;  of the same number.
	;
	; Don't have a number yet. Look through the list of drives for one
	; of the same name, while at the same time finding the lowest number
	; above the base 26 used for single-character drive names.
	; 
		push	cx
		mov	di, offset FIH_driveList - offset DSE_next
findByName:
	    ;
	    ; Advance to the next drive in the list.
	    ; 
		mov	di, es:[di].DSE_next
		tst	di
		jz	useLowestNumber
	    ;
	    ; Fetch this drive's number so we can properly maintain our
	    ; lowest-existing-drive-outside-single-letter-range counter in
	    ; AL
	    ; 
		mov	cl, es:[di].DSE_number
		cmp	cl, 'Z' - 'A'	; in single-letter range?
		jbe	compareName	; yes -- just compare the name
		cmp	cl, al		; below our current favorite?
		jae	compareName	; yes -- just compare the name
		mov	al, cl		; no -- use this as benchmark instead
compareName:
	    ;
	    ; Figure the length of the name in the drive from the size of
	    ; the chunk holding the entry, after subtracting out the size
	    ; of the fixed portion and the size word itself, of course.
	    ; 
		mov	cx, es:[di].LMC_size
		sub	cx, size DriveStatusEntry + size word
DBCS <		shr	cx, 1						>
	    ;
	    ; Compare the two names, including the null-terminators at the end
	    ; of each. If they match, we got ourselves a winna
	    ; 
		push	si, di
		add	di, offset DSE_name
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		pop	si, di
		jne	findByName
		
		mov	al, es:[di].DSE_number
		jmp	haveDriveNumber
useLowestNumber:
	;
	; Use the number below the lowest one found so long as the name isn't
	; a single-lettered thing.
	; 
		dec	ax		; al is lowest used, so reduce by one
					;  to get first free. Can't wrap, since
					;  must be >= 26
EC <		cmp	al, 26						>
EC <		ERROR_B	ALL_DRIVE_NUMBERS_IN_USE			>

if DBCS_PCGEOS
		mov	cx, ds:[si]	; cx <- first char of name
		cmp	cx, 'z'
		ja	haveDriveNumber	; branch if not alpha
		tst	{word}ds:[si][2]
		jnz	haveDriveNumber	; branch if > 1 char in name
		cmp	cx, 'a'
		jae	computeNumber	; => lower-case alpha
		cmp	cx, 'Z'
		ja	haveDriveNumber	; => not alpha, use lowest
		cmp	cx, 'A'
		jb	haveDriveNumber	; => not alpha, use lowest
else
		mov	cx, ds:[si]	; cx <- first two bytes of name
		cmp	cx, 'z'
		ja	haveDriveNumber	; > 1 char in the name, or not alpha
		cmp	cl, 'a'
		jae	computeNumber	; => lower-case alpha
		cmp	cl, 'Z'
		ja	haveDriveNumber	; => not alpha, use lowest
		cmp	cl, 'A'
		jb	haveDriveNumber	; => not alpha, use lowest
endif
computeNumber:
	;
	; Drive name is single-character alphabetic, so compute the drive number
	; from it (0 = A, 1 = B, ...)
	; 
		mov	al, cl
		sub	al, 'a'		; assume lower-case
		jae	haveDriveNumber	; yup -- al now drive number
		add	al, 'a' - 'A'	; nope. adjust back up (requires 8
					;  cycles in this more-common case, not
					;  the 16 of the jae...)
haveDriveNumber:
		pop	cx
	;
	; Fall into the code used for pre-specified number, even if we know
	; the drive doesn't exist, because it's smaller, though wasteful.
	; We don't get executed much anyway...
	; 
findExisting:
	;
	; Look for an existing drive with the same number so we can biff it.
	; We do the lookup and deletion ourselves so we can transfer over the
	; last disk and access times to the new descriptor. This is needed
	; by some primary FSDs.
	; 
		push	ds, ax, bx
		clr	bx
		mov	es:[fsdTemplateDrive].DSE_lastDisk, bx
		mov	es:[fsdTemplateDrive].DSE_lastAccess, bx
		call	FSDFindDriveAndPrev
		jc	createNew
		
		mov	ax, ds:[di].DSE_lastDisk
		mov	ds:[fsdTemplateDrive].DSE_lastDisk, ax
		mov	ax, ds:[di].DSE_lastAccess
		mov	ds:[fsdTemplateDrive].DSE_lastAccess, ax
		call	FSDNukeTheDriveDamnIt
createNew:
		pop	ds, ax, bx
		push	di		; save old offset for revectoring
					;  of disk descriptors
	;
	; al is now the drive number, passed-in or assigned. Set the proper
	; fields within the template drive descriptor so we can just copy
	; the monster into the chunk we're about to create.
	; 
		segxchg	ds, es
		assume	ds:FSInfoResource, es:nothing
		mov	ds:[fsdTemplateDrive].DSE_number, al
		mov	ds:[fsdTemplateDrive].DSE_defaultMedia, ah
		mov	ds:[fsdTemplateDrive].DSE_status, cx
		mov	ds:[fsdTemplateDrive].DSE_fsd, dx
		mov	ds:[fsdTemplateDrive].DSE_private, bx
		
	;
	; Find the length of the drive name we'll be copying in.
	; (includes the NULL).
	; 
		mov	di, si
		LocalStrLength includeNull
	;
	; Add to that the size of a drive descriptor and allocate a chunk
	; that big.
	; 
DBCS <		push	cx						>
DBCS <		shl	cx, 1						>
		add	cx, size DriveStatusEntry
		call	LMemAlloc
DBCS <		pop	cx						>

		mov_trash	di, ax
		push	di
		push	es, si, cx		; preserve addr & size of
						;  drive name
	;
	; Copy in the template we filled in above.
	; 
		assume	es:FSInfoResource
		segmov	es, ds			; es <- FSIR
		mov	si, offset fsdTemplateDrive
		mov	cx, size DriveStatusEntry/2
		rep	movsw
if (size DriveStatusEntry) AND 1
   		movsb
endif
	;
	; Recover the drive name and its length and move it into place. DI
	; points to the DSE_name field by virtue of it being a label at the
	; end of the structure...
	; 
		CheckHack <offset DSE_name eq size DriveStatusEntry>

		pop	ds, si, cx
SBCS <		sub	cx, size DriveStatusEntry			>
		LocalCopyNString		;rep movsb/movsw
	;
	; Link the newly-initialized drive at the head of the drive list.
	; 
		pop	di	
		mov	ax, di
		xchg	ax, es:[FIH_driveList]
		mov	es:[di].DSE_next, ax
	;
	; Point any disk descriptors that were pointing to the old drive
	; descriptor to the new one.
	; 
		pop	ax
		tst	ax
		jz	done		; => no previous, so no revectoring
					;  needed.
		mov	si, offset FIH_diskList - offset DD_next
revectorLoop:
		mov	si, es:[si].DD_next
		tst	si
		jz	done
		cmp	es:[si].DD_drive, ax
		jne	revectorLoop
		mov	es:[si].DD_drive, di
	    ;
	    ; Re-initialize the ID etc. for the disk now, we assume, the proper
	    ; FSD is managing the drive on which it's located. XXX: pay
	    ; attention to the error, if any.
	    ;
		call	FSDReInitDisk
		jnc	revectorLoop

		mov	es:[si].DD_drive, 0
		jmp	revectorLoop

done:
	;
	; if DX isn't offset fileSkeletonDriver, send notification out of
	; drive's creation.
	;
		call	FSDDowngradeExclInfoLock
		cmp	dx, offset fileSkeletonDriver
		je	returnNewOffset

		call	FSDNotifyDriveCreated
returnNewOffset:
		mov	dx, di
		call	FSDUnlockInfoShared
		.leave
		ret
		assume	ds:dgroup, es:dgroup
FSDInitDriveReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDReInitDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-initialize a disk that has switched from one drive
		descriptor to another.

CALLED BY:	FSDInitDrive
PASS:		es:si	= DiskDesc that changed
		es:di	= new DriveStatusEntry
RETURN:		carry set if couldn't re-initialize
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDReInitDisk	proc	near
		call	PushAllFar
		segmov	ds, es
		test	ds:[si].DD_flags, mask DF_ALWAYS_VALID
		jz	markStale
	;
	; Change the private data for the disk to be appropriate to the driver
	; now managing the disk.
	; 
		mov	bx, ds:[di].DSE_fsd
		mov	cx, ds:[bx].FSD_diskPrivSize
		mov	ax, ds:[si].DD_private
		jcxz	ensureNoPrivateData
		tst	ax
		jz	allocNewPrivateData
		call	LMemReAlloc

storePrivateDataOffset:
		mov	ds:[si].DD_private, ax
	;
	; Now re-register the thing to get the new driver's idea of the ID
	; and volume name.
	; 
		mov	bx, si
		call	DiskReRegisterInt
done:
		call	PopAllFar
		ret

ensureNoPrivateData:
		tst	ax
		jz	storePrivateDataOffset
		call	LMemFree
		clr	ax
		jmp	storePrivateDataOffset

allocNewPrivateData:
		call	LMemAlloc
		jmp	storePrivateDataOffset

markStale:
	;
	; If disk isn't always valid, we have no means of ensuring it's in
	; the drive now, so we simply mark the disk stale and return carry
	; set to indicate we couldn't re-initialize the handle.
	; 
		ornf	ds:[si].DD_flags, mask DF_STALE
		stc
		jmp	done
FSDReInitDisk	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDNotifyDriveCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the world this drive has been created.

CALLED BY:	FSDInitDrive
PASS:		es:di	= new DriveStatusEntry
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDNotifyDriveCreated proc	near
		uses	cx
		.enter
		mov	cx, GCNDCNT_CREATED
		mov	al, es:[di].DSE_number
		call	FSDNotifyDriveCommon
		.leave
		ret
FSDNotifyDriveCreated endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDNotifyDriveDestroyed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the world this drive is gone

CALLED BY:	FSDDeleteDrive
PASS:		al	= DriveStatusEntry just biffed
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDNotifyDriveDestroyed proc near
		uses	cx
		.enter
		mov	cx, GCNDCNT_DESTROYED
		call	FSDNotifyDriveCommon
		.leave
		ret
FSDNotifyDriveDestroyed endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDNotifyDriveCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the world about a status-change in one of the drives.

CALLED BY:	INTERNAL
       		FSDNotifyDriveDestroyed, FSDNotifyDriveCreated
PASS:		cx	= GCNDriveChangeNotificationType
		al	= drive number being affected
RETURN:		nothing
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDNotifyDriveCommon proc	near
		call	PushAllFar
	;
	; If system not done initializing, there's no one to notify...
	; 
		LoadVarSeg	ds, dx
		tst	ds:[initFlag]
		jnz	done
	;
	; Broadcast the change to everyone on the list.
	; 
		mov_tr	dx, ax
		clr	dh
		mov	ax, MSG_NOTIFY_DRIVE_CHANGE
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	si, GCNSLT_FILE_SYSTEM
		mov	di, mask GCNLSF_FORCE_QUEUE
		call	GCNListRecordAndSend
done:
		call	PopAllFar
		ret
FSDNotifyDriveCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDFindDriveAndPrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a drive descriptor and the pointer to it, given the
		drive number

CALLED BY:	FSDDeleteDriveInternal, FSDDeleteDrive, FSDInitDrive
PASS:		al	= drive number
		es	= FSInfoResource
RETURN:		carry set if drive not found:
			di	= 0
			bx	= nuked
		carry clear if drive found:
			di	= DriveStatusEntry
			bx	= entry that points to same
		ds	= FSInfoResource
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDFindDriveAndPrev proc near
		.enter
		segmov	ds, es
	;
	; Locate the drive in the list first. ds:di is the current drive,
	; while ds:bx is where the pointer to the current drive is located,
	; so we can unlink the drive from the chain easily.
	; 
		mov	di, offset FIH_driveList - offset DSE_next
findByNumLoop:
		mov	bx, di
		mov	di, ds:[bx].DSE_next
		tst	di
		jz	notFound
		cmp	ds:[di].DSE_number, al
		jne	findByNumLoop
done:
		.leave
		ret
notFound:
	;
	; Signal the drive wasn't here by returning carry set.
	; 
		stc
		jmp	done
FSDFindDriveAndPrev endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDNukeTheDriveDamnIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlink and free the drive descriptor passed.

CALLED BY:	FSDDeleteDriveInternal, FSDDeleteDrive
PASS:		ds = es	= FSInfoResource locked exclusive
		ds:di	= DriveStatusEntry to free
		ds:bx	= DriveStatusEntry pointing to same
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDNukeTheDriveDamnIt proc near
		.enter
	;
	; Found it. Unlink the drive from the list.
	; 
		mov	ax, ds:[di].DSE_next
		mov	ds:[bx].DSE_next, ax
	;
	; Free the fsd-private data, if it exists.
	; 
		mov	ax, ds:[di].DSE_private
		tst	ax
		jz	freeOld
		call	LMemFree
freeOld:
	;
	; Now free the DriveStatusEntry itself.
	; 
		mov	ax, di
		call	LMemFree
		.leave
		ret
FSDNukeTheDriveDamnIt	endp

	assume	es:nothing, ds:dgroup

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDDeleteDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the descriptor for the passed drive.

CALLED BY:	RESTRICTED GLOBAL
PASS:		al	= drive number
RETURN:		carry set if drive actively in use (a thread has a working
			directory on the drive, or there's a file open
			to the drive). The drive is not deleted in this case.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDDeleteDrive	proc	far
		uses	es, bx, di, ds, ax
		.enter
		call	FSDLockInfoExclToES
		assume	es:FSInfoResource
		
	;
	; Locate the drive descriptor.
	; 
		call	FSDFindDriveAndPrev	; ds <- FSIR
		jc	doneUnlockExcl
	;
	; If drive marked busy, don't biff it.
	; 
		test	ds:[di].DSE_status, mask DES_BUSY
		stc
		jnz	doneUnlockExcl
	;
	; See if any of the disk handles registered on the drive are actively
	; in-use.
	; 
		push	bx
		mov	bx, offset FIH_diskList - offset DD_next
scanLoop:
		mov	bx, ds:[bx].DD_next
		tst	bx
		jz	scanComplete
		cmp	ds:[bx].DD_drive, di	; disk on this drive?
		jne	scanLoop		; no -- keep looking
		call	DiskCheckInUse		; is it in use?
		jnc	scanLoop		; no -- we're ok
	;
	; At least one disk registered in the drive is still in-use, so
	; return carry set to indicate our inability to biff the thing.
	; 
		pop	bx
doneUnlockExcl:
		call	FSDUnlockInfoExcl
done:		
		.leave
		ret

scanComplete:
	;
	; Go through and mark all disks that were registered in this drive
	; as stale, so no one can use them again.
	; 
		mov	bx, offset FIH_diskList - offset DD_next
invalidateLoop:
		mov	bx, ds:[bx].DD_next
		tst	bx
		jz	freeItMan
		cmp	ds:[bx].DD_drive, di	; on this drive?
		jne	invalidateLoop		; no -- keep going

		ornf	ds:[bx].DD_flags, mask DF_STALE
		clr	ax
		mov	ds:[bx].DD_drive, ax	; so we won't find it again...
		
	    ;
	    ; If the disk has private data, free it.
	    ; 
		xchg	ax, ds:[bx].DD_private
		tst	ax
		jz	invalidateLoop
		call	LMemFree
		jmp	invalidateLoop

freeItMan:
		pop	bx
		mov	al, ds:[di].DSE_number
		push	ax
		call	FSDNukeTheDriveDamnIt
	;
	; Now let the world know the drive is gone, after downgrading our lock
	; to *shared* to allow any other resources needed for the notification
	; to be brought into memory.
	; 
		pop	ax
		call	FSDDowngradeExclInfoLock
		call	FSDNotifyDriveDestroyed
		call	FSDUnlockInfoShared
		clc
		jmp	done
FSDDeleteDrive	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDDriveGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of drives known to the system.

CALLED BY:	EXTERNAL
		SGI_NumberOfVolumes (SysGetInfo)
PASS:		ds	= dgroup
RETURN:		ax	= number of registered drives
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDDriveGetCount proc	far
		uses	es, bx
		.enter
		call	FileLockInfoSharedToES
		mov	ax, -1
		mov	bx, offset FIH_driveList - offset DSE_next
countLoop:
		mov	bx, es:[bx].DSE_next
		inc	ax
		tst	bx
		jnz	countLoop
		
		call	FSDUnlockInfoShared
		.leave
		ret
FSDDriveGetCount endp

Filemisc	ends
