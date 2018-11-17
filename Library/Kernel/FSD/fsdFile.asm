COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fsdFile.asm

AUTHOR:		Adam de Boor, Oct 16, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/16/91	Initial revision


DESCRIPTION:
	File-module related FSD support routines.
		

	$Id: fsdFile.asm,v 1.1 97/04/05 01:17:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kinit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register another FS driver in the system.

CALLED BY:	RESTRICTED GLOBAL
PASS:		cx:dx	= strategy routine
		ax	= FSDFlags
		bx	= handle of driver
		di	= number of bytes of private data required for each
			  DiskDesc
RETURN:		dx	= FSDriver offset (for use in calling FSDInitDrive)
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDRegister	proc	far
		uses	ds
		.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si							>
EC<	movdw	bxsi, cxdx						>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx, si							>
endif
	;
	; Save input parameters from destruction and lock the FSIR for
	; our exclusive use, placing the result in DS so we can allocate
	; things (rather than the more-normal ES)
	; 
		push	ax, bx, cx
		call	FSDLockInfoExcl
		mov	ds, ax
		assume	ds:FSInfoResource
	;
	; Now allocate a record for the new driver and pop the various things
	; we saved into it.
	; 
		mov	cx, size FSDriver
		call	LMemAlloc
		mov	bx, ax
		pop	ds:[bx].FSD_flags, \
			ds:[bx].FSD_handle, \
			ds:[bx].FSD_strategy.segment
		mov	ds:[bx].FSD_strategy.offset, dx
		mov	ds:[bx].FSD_diskPrivSize, di
	;
	; Link the new record at the head of the list.
	; 
		xchg	ds:[FIH_fsdList], ax
		mov	ds:[bx].FSD_next, ax
		mov	dx, bx
	;
	; If the driver is marked as a primary FSD, set it as THE primary
	; FSD.
	; 
		test	ds:[bx].FSD_flags, mask FSDF_PRIMARY
		jz	fetchPermanentName
EC <		push	bx						>
EC <		mov	bx, ds:[FIH_primaryFSD]				>
EC <		test	ds:[bx].FSD_flags, mask FSDF_SKELETON		>
EC <		ERROR_Z	TOO_MANY_PRIMARY_FSDs				>
EC <		pop	bx						>
		mov	ds:[FIH_primaryFSD], bx

fetchPermanentName:
	;
	; Fetch the driver's permanent name from its core block so we can find
	; the thing in DiskRestore without having to grab the geodeSem.
	; 
		push	di, es
		lea	di, ds:[bx].FSD_name
		segmov	es, ds
		mov	bx, ds:[bx].FSD_handle
		mov	ax, GGIT_PERM_NAME_ONLY
		call	GeodeGetInfo
		pop	di, es

	;
	; Make sure the skeleton disk's private data chunk is big enough to
	; accomodate that much private data.
	; 
		mov	cx, di
		jcxz	done			; no private data needed by
						; this driver, so need to
						; do nothing

		mov	di, ds:[fsdTemplateDisk].DD_private
		tst	di
		jz	allocNewPrivChunk

		ChunkSizePtr	ds, di, ax
		cmp	ax, cx		; current size big enough?
		jae	done		; yes

		xchg	ax, di		; ax <- chunk
		call	LMemReAlloc
storePrivChunkAddr:
		mov	ds:[fsdTemplateDisk].DD_private, ax
							; store new address
							;  of the beast
done:
	;
	; Done playing with ourselves...
	; 
		call	FSDUnlockInfoExcl
		.leave
		ret

allocNewPrivChunk:
	; cx = size required
		call	LMemAlloc
		jmp	storePrivChunkAddr

		assume	ds:dgroup
FSDRegister	endp

kinit		ends

FSResident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a filesystem driver from the system. An FSD may not
		be removed unless all the drives that refer to it have
		been removed.

CALLED BY:	(GLOBAL)
PASS:		dx	= offset of FSDriver to remove
RETURN:		carry set if driver may not be removed, as there's a
			driver still defined that refers to it
		carry clear if driver removed
DESTROYED:	ax, dx
SIDE EFFECTS:	various

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDUnregister	proc	far
		uses	ds, bx, si
		.enter
		call	FSDLockInfoExcl
		mov	ds, ax
		assume	ds:FSInfoResource
EC <		mov	ax, offset FIH_fsdList - offset FSD_next 	>
EC <ensureIsFSDLoop:							>
EC <		mov_tr	bx, ax						>
EC <		mov	ax, ds:[bx].FSD_next				>
EC <		cmp	dx, ax						>
EC <		je	isFSD						>
EC <		tst	ax						>
EC <		jnz	ensureIsFSDLoop					>
EC <		ERROR	INVALID_FSDRIVER_OFFSET				>
EC <isFSD:								>
	;
	; Make sure there are no drives referencing the FSD.
	; 
		mov	si, offset FIH_driveList - offset DSE_next
driveCheckLoop:
		mov	bx, si
		mov	si, ds:[bx].DSE_next
		tst	si
		jz	allDrivesGone
		cmp	ds:[si].DSE_fsd, dx
		jne	driveCheckLoop
		stc
		jmp	done

allDrivesGone:
	;
	; Now locate the thing that points to the driver being removed
	; 
		mov	si, offset FIH_fsdList - offset FSD_next
findPrevFSDLoop:
		mov	bx, si
		mov	si, ds:[bx].FSD_next
		cmp	si, dx
		jne	findPrevFSDLoop
	;
	; Unlink the driver from the chain.
	; 
		mov	si, ds:[si].FSD_next
		mov	ds:[bx].FSD_next, si
	;
	; If the driver was the primary, clear out references to it.
	; 
		cmp	ds:[FIH_primaryFSD], dx
		jne	nukeIt
		push	es
		LoadVarSeg es, ax
		assume	es:dgroup
		mov	es:[defaultDrivers].DDT_fileSystem, 0
		mov	ds:[FIH_primaryFSD], 0
		pop	es
		assume	es:nothing
nukeIt:
	;
	; Finally, biff the chunk.
	; 
		mov_tr	ax, dx
		call	LMemFree
		clc
done:
		call	FSDUnlockInfoExcl
		assume	ds:dgroup
		.leave
		ret
FSDUnregister	endp

FSResident	ends

;--------------------------------------------------------------

FileCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDInformOldFSDOfPathNukage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the FSD on which the passed path block was located
		that the thing is about to be freed.

CALLED BY:	FileDeletePath, SetCurPathUsingStdPath, GLOBAL
PASS:		bx	= FilePath block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDInformOldFSDOfPathNukage	proc	far
		uses	bp, si, di, ds
		.enter
		LoadVarSeg	ds

		mov	si, ds:[bx].HM_otherInfo
		test	si, DISK_IS_STD_PATH_MASK	; StandardPath?
		jnz	done			; yes
		
		mov	di, DR_FS_CUR_PATH_DELETE
		call	DiskCallFSD
done:
		.leave
		ret
FSDInformOldFSDOfPathNukage endp

FileCommon	ends

;----------------------------------------------

FSResident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDInt21
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call to DOS after grabbing the DOS/BIOS lock

CALLED BY:	?
PASS:		registers set up for DOS call
RETURN:		?
DESTROYED:	nothing by us...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDInt21	proc	near
		.enter
;disallow calling function 0 this way (really old-fashioned exit), as it
; sends the machine off the deep end, making it hard to debug
EC <		cmp	ah, 0						>
EC <		ERROR_E	GASP_CHOKE_WHEEZE				>
	;
	; Gain exclusive access to DOS/BIOS
	;
		call	SysLockBIOSFar
	;
	; Copy dosAddr into callVector.segment and callTemporary. We use this,
	; instead of callVector itself, because callVector.offset is already
	; set up by ProcCallModuleRoutine when it attempts to lock a non-
	; resident resource. As such, the offset portion is unbiffable. The
	; segment portion, however, cannot possibly have been set up yet, and
	; callTemporary is never used anywhere, so...
	; 
		push	ds
		push	ax
		LoadVarSeg	ds, ax
		mov	ax, ds:dosAddr.segment
		mov	ss:TPD_callTemporary, ax
		mov	ax, ds:dosAddr.offset
		mov	ss:TPD_callVector.segment, ax
		pop	ax
		pop	ds
	;
	; Emulate interrupt
	;

	; Turn off the trap flag first, as otherwise we'll turn trapping
	; back on when we return from the interrupt

SSP <		call	SaveAndDisableSingleStepping			>
		pushf
		INT_OFF
if		TEST_RECORD_INT21
		call	FSDRecordInt21Call		; destroys flags
endif
		call	{dword}ss:TPD_callVector.segment
SSP <		call	RestoreSingleStepping				>
	;
	; Handle critical errors in the gross way necessitated by some versions
	; of DOS.
	; 
		pushf
		cmp	ss:TPD_callTemporary, 1		; Error detected?
		ja	noCritical			; Nope (DOS must have
							;  been in a segment >
							;  1)
		pop	ax				; Set carry in saved
		or	ax, ss:TPD_callTemporary	; flags if appropriate
		push	ax
		mov	ax, ss:TPD_callVector.segment	; ax <- error code
noCritical:
if		TEST_RECORD_INT21
		call	FSDEndInt21Call			; destroys flags
endif
		popf
	;
	; Release DOS/BIOS lock
	;
		call	SysUnlockBIOSFar
done::
		.leave
		ret
FSDInt21	endp

if		TEST_RECORD_INT21

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDRecordInt21Call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Records calls made to DOS with Int21

CALLED BY:	FSDInt21
PASS:		AH	= Int21Call enumerated type (function)
			  Interrupts are OFF

RETURN:		Nothing
DESTROYED:	flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDRecordInt21Call	proc	near
		uses	ax, bx, ds
		.enter
	
		; Record the current time
		;
		push	ax
		LoadVarSeg	ds, ax
		call	TimerStartCount		; record starting count
		mov	ds:[recInt21Start].TR_ticks, bx
		mov	ds:[recInt21Start].TR_units, ax
		pop	ax

		; Increment the usage count
		;
		mov	al, ah
		clr	ah
		shl	ax, 1
		mov	bx, ax
		shl	ax, 1
		add	bx, ax			; offset into recInt21Table=> BX
		add	bx, offset recInt21Table
		inc	ds:[bx].IRE_count
		mov	ds:[recInt21Func], bx

		; Now track any amount we are reading or writing
		;
		clr	bx			; use as a high word later
		cmp	ax, MSDOS_READ_FILE * 4
		je	readFile
		cmp	ax, MSDOS_WRITE_FILE * 4
		je	writeFile
done:
		.leave
		ret

		; Record information for file reads or writes
readFile:
		adddw	ds:[recFileReads], bxcx
		jmp	done
writeFile:
		adddw	ds:[recFileWrites], bxcx
		jmp	done
FSDRecordInt21Call	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDEndInt21Call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the time spent in an Int21 call

CALLED BY:	FSDInt21
PASS:		Inerrupts ON

RETURN:		Nothing
DESTROYED:	flags

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDEndInt21Call		proc	near
		uses	ax, bx, si, ds
		.enter

		; Now record the end of the call
		;
		LoadVarSeg	ds, ax
		mov	bx, ds:[recInt21Start].TR_ticks
		mov	ax, ds:[recInt21Start].TR_units
		mov	si, ds:[recInt21Func]	 ; elapsed time buffer => DS:SI
		call	TimerEndCount		 ; update elapsed time

		.leave
		ret
FSDEndInt21Call		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDRecordError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record a critical error for the current thread.

CALLED BY:	FS driver
PASS:		ax	= error code to return
		bx	= 0 if should not set carry on return
			= 1 if should set carry on return
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		store the error code in TPD_callVector.segment and the
		carry/error flag in TPD_callTemporary. Since DOS must be in
		a segment other than 0 or 1, we can safely use callTemporary
		being below 1 as a signal that an error occurred.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDRecordError	proc	far
		.enter
		mov	ss:[TPD_callTemporary], bx
		mov	ss:[TPD_callVector.segment], ax
		.leave
		ret
FSDRecordError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDGetThreadPathDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the disk handle from the current thread's current
		path.

CALLED BY:	FSDs
PASS:		nothing
RETURN:		bx	= disk handle for thread's current path. This may
			  be a member of the StandardPath enum. If
			  BX & DISK_IS_STD_PATH_MASK
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDGetThreadPathDiskHandle proc	far
		uses	ds
		.enter
		LoadVarSeg	ds, bx
		mov	bx, ss:[TPD_curPath]
		tst	bx
		jz	done		; XXX: necessary?
		mov	bx, ds:[bx].HM_otherInfo
done:
		.leave
		ret
FSDGetThreadPathDiskHandle endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDCheckOpenCloseNotifyEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if FCNT_OPEN/FCNT_CLOSE notification is enabled

CALLED BY:	(RESTRICTED GLOBAL)
PASS:		nothing
RETURN:		carry set if notification is enabled
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDCheckOpenCloseNotifyEnabled proc	far
		uses	ds
		.enter
		LoadVarSeg	ds
		tst	ds:[openCloseNotificationCount]
		jz	done
		stc
done:
		.leave
		ret
FSDCheckOpenCloseNotifyEnabled endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDGenerateNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate file-change notification from the passed
		parameters.

CALLED BY:	(RESTRICTED GLOBAL)
PASS:		ax	= FileChangeNotificationType
		if ax != FCNT_BATCH
		    si		= disk handle
		    cxdx	= ID to pass (either of affected file or
				  containing directory)
		    ds:bx	= file name, if needed
		else
		    bx		= handle of FileChangeBatchNotificationData
		
RETURN:		carry set if notification discarded due to lack of memory
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDGenerateNotify proc far
		uses	es, si, di, bp
		.enter
		
		tst	ss:[TPD_fsNotifyBatch]
		jz	straightNotify
		
		call	FSDAddNotifyToBatch
		jmp	done

straightNotify:
		cmp	ax, FCNT_BATCH
		jne	notBatch
		mov_tr	dx, ax
		jmp	sendNotify
notBatch:
	;
	; Allocate a data block to convey our meaning.
	; 
		push	ax, bx, cx
		mov	ax, size FileChangeNotificationData
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		call	MemAllocFar
		jc	memErr
	;
	; Store the constant parts of the data (disk handle, and ID for
	; something).
	; 
		mov	es, ax
		mov	es:[FCND_disk], si
		mov	es:[FCND_id].low, dx
		pop	es:[FCND_id].high
	;
	; See if we need to copy a filename in.
	; 
		pop	si		; ds:si <- filename
		pop	dx		; dx <- FCNT
	CheckHack <FCNT_CREATE eq 0 and FCNT_RENAME eq 1>
		cmp	dx, FCNT_RENAME	; only rename and create take a
					;  file name.
		ja	unlockBlock	; => no name required

	;
	; Copy the filename from ds:di to es:FCND_name
	; 
		mov	di, offset FCND_name
		LocalCopyString		;copy NULL-terminated string
unlockBlock:
		call	MemUnlock
sendNotify:
	;
	; Initialize the reference count for the data block to 1, to
	; account for what GCNListSend does.
	; 
		mov	ax, 1
		call	MemInitRefCount

		mov	bp, bx		; bp <- data block
	;
	; Record the MSG_NOTIFY_FILE_CHANGE going to no class in particular.
	; 
		mov	ax, MSG_NOTIFY_FILE_CHANGE
		clr	bx, si
		mov	di, mask MF_RECORD
		call	ObjMessage
	;
	; Call GCNListSend
	; 
		mov	cx, di			; cx <- event handle
		mov	bx, MANUFACTURER_ID_GEOWORKS	; bxax <- list ID
		mov	ax, GCNSLT_FILE_SYSTEM
		mov	dx, bp			; dx <- data block
		mov	bp, mask GCNLSF_FORCE_QUEUE	; now would be a bad
							;  time to field this
							;  message on this
							;  thread...
		call	GCNListSend
		clc					; GCNListSend may
							; modify flags...
done:
		.leave
		ret

memErr:
		pop	ax, bx, cx
		jmp	done
FSDGenerateNotify endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDAddNotifyToBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the passed notification to the batch we're building
		for this thread.

CALLED BY:	(INTERNAL) FSDGenerateNotify
PASS:		ax	= FileChangeNotificationType
		si	= disk handle
		cxdx	= ID to pass (either of affected file or containing
			  directory)
		ds:bx	= file name, if needed
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es, si, di, bp
SIDE EFFECTS:	a new block for ss:[TPD_fsNotifyBatch] may be allocated

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDAddNotifyToBatch proc	near
		.enter
		mov	di, bx		; save file name
		mov	bx, ss:[TPD_fsNotifyBatch]
		push	ax		; save notification type
lockIt:
		call	MemLock
		mov	es, ax
		cmp	es:[FCBND_end], FSD_MAX_BATCH_SIZE
		jbe	addToThisOne
	;
	; Not enough room here. Allocate a new block and link it to the existing
	; one through the HM_otherInfo.
	; 
		call	MemUnlock
		push	bx
		call	FSDAllocNewBatchBlock
		pop	ax
		jc	memErr

		call	MemModifyOtherInfo
		mov	ss:[TPD_fsNotifyBatch], bx
		jmp	lockIt

addToThisOne:
	;
	; Enlarge the block enough to hold the data for the notification,
	; coping with some things having a name (FCNT_CREATE, FCNT_RENAME)
	; and others not.
	; 
		pop	ax
		push	ax
		cmp	ax, FCNT_RENAME
		mov	ax, size FileChangeBatchNotificationItem
		ja	haveSize
		mov	ax, size FileChangeBatchNotificationItem + \
				size FileLongName
haveSize:
		push	cx
		add	ax, es:[FCBND_end]
		mov	bp, ax
		add	ax, FSD_ALLOC_GRANULARITY-1 ; round up
		andnf	ax, not (FSD_ALLOC_GRANULARITY-1)

	    ;
	    ; Now see if we actually need to call MemReAlloc (faster to perform
	    ; this check ourselves than having to get the heap semaphore and
	    ; all that other stuff just to realize there's no change in size)
	    ; 
		LoadVarSeg	es, cx
		mov	cx, es:[bx].HM_size
		shl	cx
		shl	cx
		shl	cx
		shl	cx
		cmp	cx, ax
		jb	enlargeIt

		mov	es, es:[bx].HM_addr	; reload ES, since we're not
						;  changing it (block is locked)
	;
	; Fetch where we're to put this notification and adjust the pointer for
	; the next time.
	; 
storeNotification:
		mov	bx, es:[FCBND_end]
FSDANTB_haveOffset label near	
	ForceRef FSDANTB_haveOffset	; for showcalls -F

		mov	es:[FCBND_end], bp
	;
	; Record all the fixed information.
	; 
		pop	es:[bx].FCBNI_id.high
		mov	es:[bx].FCBNI_id.low, dx
		mov	es:[bx].FCBNI_disk, si
		pop	ax
		mov	es:[bx].FCBNI_type, ax
	;
	; Copy the name in, if appropriate.
	; 
		cmp	ax, FCNT_RENAME
		ja	notificationComplete
		mov	si, di			; ds:si <- file name
		lea	di, es:[bx].FCBNI_name	; es:di <- dest
		mov	cx, length FileLongName
		LocalCopyNString		;rep movsb/movsw

notificationComplete:
	;
	; Unlock the batch block and return.
	; 
		mov	bx, ss:[TPD_fsNotifyBatch]
		call	MemUnlock
		clc
done:
		.leave
		ret
enlargeErr:
		pop	cx
memErr:
		pop	ax
		jmp	done

enlargeIt:
		mov	cx, (mask HAF_ZERO_INIT) shl 8
		call	MemReAlloc
		jc	enlargeErr
		mov	es, ax
		jmp	storeNotification
FSDAddNotifyToBatch endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDAllocNewBatchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block to batch up file-system change notifications

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		bx	= handle of block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDAllocNewBatchBlock proc	near
		uses	ax, ds, cx
		.enter
		mov	ax, FSD_ALLOC_GRANULARITY
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		call	MemAllocFar
		jc	done
		mov	ds, ax
		mov	ds:[FCBND_end], offset FCBND_items
		clr	ax			; null-terminate
		call	MemModifyOtherInfo	;  in case only item in list
		call	MemUnlock
done:
		.leave
		ret
FSDAllocNewBatchBlock endp


FSResident	ends
