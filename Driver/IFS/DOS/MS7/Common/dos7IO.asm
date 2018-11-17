COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driIO.asm

AUTHOR:		Adam de Boor, Oct 31, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/31/91	Initial revision


DESCRIPTION:
	Stuff dealing with open files.
		

	$Id: dos7IO.asm,v 1.1 97/04/10 11:55:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSHandleOpPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the read/write pointer for the file, dealing with
		hiding the header for the file.

CALLED BY:	DOSHandleOp
PASS:		bx	= DOS handle
		bp	= offset to private data for the file (0 if not ours)
		cx:dx	= new position
		al	= positioning method
RETURN:		carry set on error:
			ax	= error code
		carry clear on success:
			dx:ax	= new position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSHandleOpPosition proc near
		uses	ds, cx
		.enter
	;
	; If file not marked as geos, perform normal position call.
	; 
		call	LoadVarSegDS
		test	ds:[bp].DFE_flags, mask DFF_GEOS
		jz	doNormalPosition
		
CheckHack <FILE_POS_START lt FILE_POS_RELATIVE and \
	   FILE_POS_END gt FILE_POS_RELATIVE>

		cmp	al, FILE_POS_RELATIVE
		jb	posStart
	;
	; Relative or end position: if the position goes into the header, reset
	; it to the end of the header. Since the offset for end can be
	; negative, it is possible to get back into the header, and the
	; adjustment of the resulting position is the same in both cases...
	; 
		mov	ah, MSDOS_POS_FILE
		call	DOSUtilInt21
		jc	done
	    ;
	    ; Adjust resulting position to not include the header. If that
	    ; takes it below 0, we've got ourselves a problem...
	    ; 
		sub	ax, size GeosFileHeader
		sbb	dx, 0
		jnc	done
	    ;
	    ; Pretend it's a request for an absolute 0 position and fall
	    ; through to the absolute code...
	    ; 
		clr	cx
		mov	dx, cx
		mov	al, FILE_POS_START
posStart:
	;
	; Absolute position: just add the size of the header to the requested
	; size.
	; 
		add	dx, size GeosFileHeader
		adc	cx, 0
		mov	ah, MSDOS_POS_FILE
		call	DOSUtilInt21
		jc	done
		
		sub	ax, size GeosFileHeader
		sbb	dx, 0		; will *not* generate a borrow
done:
		.leave
		ret

doNormalPosition:
		mov	ah, MSDOS_POS_FILE
		call	DOSUtilInt21
		jmp	done
DOSHandleOpPosition endp

PathOpsRare	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSHandleOpSetFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the name for a file opened before we were loaded

CALLED BY:	(INTERNAL) DOSHandleOp
PASS:		es:si	= disk on which file resids
		bx	= geos file handle
		bp	= offset of DOSFileEntry
		ds:dx	= name for the file
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSHandleOpSetFileName proc	far
		uses	ds, dx, cx
		.enter
	;
	; Gain the right to map the name...
	; 
		call	DOSEstablishCWD
		jc	done
	;
	; Now map it, insisting on it being a file.
	; 
		call	DOSVirtMapFilePath
		jc	done
	;
	; Compute the 32-bit ID for the file.
	; 
		call	PathOpsRare_LoadVarSegDS
if _MS7
		push	si
		mov	si, offset dos7FindData
		clr	dx
		call	DOS7GetIDFromFD
		pop	si
else
		GetIDFromDTA	ds:[dosNativeFFD], cx, dx
endif
		movdw	ds:[bp].DFE_id, cxdx
	;
	; What the heck: transfer the FileAttrs too.
	; 
if _MS7
		mov	al, ds:[dos7FindData].W32FD_fileAttrs.low.low
else
		mov	al, ds:[dosNativeFFD].FFD_attributes
endif
		mov	ds:[bp].DFE_attrs, al
done:
		call	DOSUnlockCWD
		.leave
		ret
DOSHandleOpSetFileName endp
PathOpsRare	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSHandleOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an operation on a file handle. If appropriate, the
		disk on which the file is located will have been locked.

CALLED BY:	DR_FS_HANDLE_OP
PASS:		ah	= FSHandleOpFunction to perform
		bx	= handle of open file
		es:si	= DiskDesc (FSInfoResource and affected drive locked
			  shared)
		other parameters as appropriate.
RETURN:		carry set on error:
			ax	= error code
		carry clear if successful:
			return values depend on subfunction
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	*** MORE INFO HERE ***

    FSHOF_READ		enum	FSHandleOpFunction
    ;	Pass:	ds:dx	= buffer to which to read
    ;		cx	= # bytes to read
    ;	Return:	carry clear if successful:
    ;			ax	= # bytes read
    Pass directly to DOS

    FSHOF_WRITE		enum	FSHandleOpFunction
    ;	Pass:	ds:dx	= buffer from which to write
    ;		cx	= # bytes to write
    ;	Return:	carry clear if successful:
    ;			ax	= # bytes written
    Pass directly to DOS

    FSHOF_POSITION	enum	FSHandleOpFunction
    ;	Pass:	al	= FileSeekModes
    ;		cx:dx	= offset to use
    ;	Return:	carry clear if successful:
    ;			dx:ax	= new absolute file position
    Pass directly to DOS

    FSHOF_TRUNCATE	enum	FSHandleOpFunction
    ;	Pass:	cx:dx	= size to which to truncate the file
    ;	Return:	nothing (besides carry & error code)
    ;
    Seek to position and write 0 bytes

    FSHOF_COMMIT	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing (besides carry & error code)
    If COMMIT call supported, use it, else duplicate & close

    FSHOF_LOCK		enum	FSHandleOpFunction
    ;	Pass:	cx	= top of inherited stack frame, set up as:
    ;			regionStart	local	dword
    ;			regionLength	local	dword
    ;					.enter
    ;	Return:	nothing (besides carry & error code)
    ;
    Pass directly to DOS

    FSHOF_UNLOCK	enum	FSHandleOpFunction
    ;	Pass:	cx	= top of inherited stack frame, set up as:
    ;			regionStart	local	dword
    ;			regionLength	local	dword
    ;					.enter
    ;	Return:	nothing (besides carry & error code)
    ;
    Pass directly to DOS

    FSHOF_GET_DATE_TIME	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	cx	= last modification time (FileTime record)
    ;		dx	= last modification date (FileDate record)
    ;
    Pass directly to DOS

    FSHOF_SET_DATE_TIME	enum	FSHandleOpFunction
    ;	Pass:	cx	= new modification time (FileTime record)
    ;		dx	= new modification date (FileDate record)
    ;	Return:	nothing (besides carry & error code)
    ;
    Pass directly to DOS

    FSHOF_FILE_SIZE	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	dx:ax	= size of the file
    ;
    Play games with SEEK

    FSHOF_ADD_REFERENCE	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing extra
    ;
    Pass directly to DOS

    FSHOF_CHECK_DIRTY	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	ax	= non-zero if file is dirty.
    ;
    ;	Notes:	This is used by the FileClose code in the kernel to determine
    ;		if it needs to lock the file's disk. IF THE FSD SAYS THE
    ;		FILE IS NOT DIRTY, THE DISK WILL NOT BE LOCKED AND NO I/O FOR
    ;		THE FILE MAY TAKE PLACE.
    ;
    Use GET_DEV_INFO ioctl to determine this.

    FSHOF_CLOSE		enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing extra
    ;
    ;	Notes:	As noted for FSHOF_CHECK_DIRTY, the disk will not be locked
    ;		unless the previous call to FSHOF_CHECK_DIRTY returned that
    ;		the file was dirty. If the disk is not locked, no I/O may
    ;		take place on behalf of the file, not even to update its
    ;		directory entry.
    ;
    Pass directly to DOS
		
    FSHOF_GET_FILE_ID	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	cx:dx	= file ID
    ;
    Return FILE_NO_DIR_ID

    FSHOF_GET_DIR_ID	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	cx:dx	= ID for containing directory
    ;
    Return FILE_NO_DIR_ID

    FSHOF_CHECK_NATIVE	enum	FSHandleOpFunction
    ;	Pass:	ch	= FileCreateFlags
    ;	Return:	carry set if file is in format implied by FCF_NATIVE
    ;
    ...

    FSHOF_GET_EXT_ATTRIBUTES enum FSHandleOpFunction
    ;	Pass:	ss:dx	= FSHandleExtAttrData
    ;		cx	= size of FHEAD_buffer, or # entries in same if
    ;			  FHEAD_attr is FEA_MULTIPLE
    ;	Return:	nothing extra
    
    FSHOF_SET_EXT_ATTRIBUTES enum FSHandleOpFunction
    ;	Pass:	ss:dx	= FSHandleExtAttrData
    ;		cx	= size of FHEAD_buffer, or # entries in same if
    ;			  FHEAD_attr is FEA_MULTIPLE
    ;	Return:	nothing extra
    
    FSHOF_GET_ALL_EXT_ATTRIBUTES enum FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	ax	= handle of locked block with array of FileExtAttrDesc
    ;			  structures for all attributes possessed by the file,
    ;			  except those that can never be set.
    ;		cx	= number of entries in that array.
    ;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSHandleOp	proc	far
		uses	bx, bp
		.enter
EC <		cmp	ah, FSHandleOpFunction				>
EC <		ERROR_AE	INVALID_HANDLE_OP			>
	;
	; Convert geos file handle to DOS handle, taking care of restoring
	; the directory index et al for files that might have had them biffed
	; by a disk change.
	; 
		push	ds
		mov	ds, es:[FIH_dgroup]
	    ;
	    ; By definition, if we're being called, the private data is ours.
	    ; If a secondary wants to have private data of its own, it must
	    ; be sure the HF_private field holds what we returned for the
	    ; file before calling us.
	    ; 
		mov	bp, ds:[bx].HF_private
	;
	; Vector to correct internal support code to load the remaining
	; registers as appropriate and clean up after the internal
	; front-line code actually performs the operation.
	; 
		xchg	ah, al
		mov	di, ax
		xchg	al, ah
		andnf	di, 0xff
		shl	di
		call	LoadVarSegDS
		test	ds:[bp].DFE_flags, mask DFF_OURS or mask DFF_SFT_VALID
		pop	ds
		jz	notOurs
		jmp	cs:[handleOpJmpTable][di]

notOurs:
		jmp	cs:[notOursHandleOpJmpTable][di]

notOursHandleOpJmpTable	nptr.near allocHandle,	; FSHOF_READ
		 		allocHandle,	; FSHOF_WRITE
				allocHandle,	; FSHOF_POSITION
				allocHandle,	; FSHOF_TRUNCATE
				allocHandle,	; FSHOF_COMMIT
				allocHandle,	; FSHOF_LOCK
				allocHandle,	; FSHOF_UNLOCK
				allocHandle,	; FSHOF_GET_DATE_TIME
				allocHandle,	; FSHOF_SET_DATE_TIME
				noDoFileSize,	; FSHOF_FILE_SIZE
				noDoAddReference,; FSHOF_ADD_REFERENCE
				noDoCheckDirty,	; FSHOF_CHECK_DIRTY
				doClose,	; FSHOF_CLOSE
				doGetFileID,	; FSHOF_GET_FILE_ID
				checkNative,	; FSHOF_CHECK_NATIVE
				allocHandle,	; FSHOF_GET_EXT_ATTRIBUTES
				allocHandle,	; FSHOF_SET_EXT_ATTRIBUTES
				allocHandle,	; FSHOF_GET_ALL_EXT_ATTRIBUTES
				doForget,	; FSHOF_FORGET
				doSetFileName	; FSHOF_SET_FILE_NAME

CheckHack	<length notOursHandleOpJmpTable eq FSHandleOpFunction>

handleOpJmpTable nptr.near	allocHandle,	; FSHOF_READ
		 		wrtAllocHandle,	; FSHOF_WRITE
				allocHandle,	; FSHOF_POSITION
				wrtAllocHandle,	; FSHOF_TRUNCATE
				wrtAllocHandle,	; FSHOF_COMMIT
				allocHandle,	; FSHOF_LOCK
				allocHandle,	; FSHOF_UNLOCK
				allocHandle,	; FSHOF_GET_DATE_TIME
				allocHandle,	; FSHOF_SET_DATE_TIME
				findSFTEntry,	; FSHOF_FILE_SIZE
				findSFTEntry,	; FSHOF_ADD_REFERENCE
				findSFTEntry,	; FSHOF_CHECK_DIRTY
				doClose,	; FSHOF_CLOSE
				doGetFileID,	; FSHOF_GET_FILE_ID
				checkNative,	; FSHOF_CHECK_NATIVE
				allocHandle,	; FSHOF_GET_EXT_ATTRIBUTES
				wrtAllocHandle,	; FSHOF_SET_EXT_ATTRIBUTES
				allocHandle,	; FSHOF_GET_ALL_EXT_ATTRIBUTES
				doForget,	; FSHOF_FORGET
				doSetFileName	; FSHOF_SET_FILE_NAME

CheckHack	<length handleOpJmpTable eq FSHandleOpFunction>

wrtAllocHandle:
if _DRI
	;
	; Special stuff to detect ACCESS_DENIED returned due to disk changes
	; and correct the problem.
	; 
	; First issue the call normally.
	;
		push	bx, cx
		call	doAllocHandle
		jnc	clearStack
	;
	; Error in operation. See if the error was ACCESS_DENIED, which could
	; mean the open file was marked read-only (i.e. handle not open
	; for writing) due to a disk change.
	; 
		cmp	ax, ERROR_ACCESS_DENIED
		stc
		jne	clearStack
	;
	; It was ACCESS_DENIED. Recover registers that are trashed by
	; some operations so we can retry the thing.
	; 
		pop	bx, cx
	;
	; Fix up the DR DOS data structures to make the file writable again.
	; 
		push	ds, di
		mov	ds, es:[FIH_dgroup]
		call	DRIFixFileData
		pop	ds, di
	;
	; Repeat the operation one more time.
	; 
		call	doAllocHandle
		jmp	done
clearStack:
	;
	; Discard the saved bx & cx and finish stuff off.
	; 
		inc	sp
		inc	sp
		inc	sp
		inc	sp
		jmp	done
else
	; for non-DRI cases, just fall through to standard allocHandle case
endif
allocHandle:
		call	doAllocHandle
		jmp	done

doAllocHandle:
	;
	; Support-code for things that actually talk to DOS with a DOS
	; file handle. Allocates the DOS handle, calls the front-line routine,
	; then frees the handle.
	;
		push	ds
		mov	ds, es:[FIH_dgroup]
		mov	bl, ds:[bx].HF_sfn
		pop	ds
		call	DOSAllocDosHandle
		call	cs:[withHandleOpJmpTable][di]
		call	DOSFreeDosHandle
		retn

findSFTEntry:
	;
	; Support-code for things that deal directly with the SFT. Load
	; ds:bx from the SFN, then call the appropriate routine.
	; 
		push	ds
		mov	ds, es:[FIH_dgroup]
		mov	bl, ds:[bx].HF_sfn
		clr	bh
		call	LoadVarSegDS
if _DRI
		shl	bx
		add	bx, ds:[handleTable].offset
		mov	ds, ds:[handleTable].segment
		mov	bx, ds:[bx]		; ds:bx <- FileHandle
else
		push	es, di
		xchg	ax, bx
		call	DOSPointToSFTEntry
		xchg	ax, bx
		segmov	ds, es
		mov	bx, di
		pop	es, di
endif
		call	cs:[withHandleOpJmpTable][di]
		pop	ds
done:
		.leave
		ret

withHandleOpJmpTable nptr.near	doRead,		; FSHOF_READ
		 		doWrite,	; FSHOF_WRITE
				doPosition,	; FSHOF_POSITION
				doTruncate,	; FSHOF_TRUNCATE
				doCommit,	; FSHOF_COMMIT
				doLockUnlock,	; FSHOF_LOCK
				doLockUnlock,	; FSHOF_UNLOCK
				doGetSetDateTime,; FSHOF_GET_DATE_TIME
				doGetSetDateTime,; FSHOF_SET_DATE_TIME
				doFileSize,	; FSHOF_FILE_SIZE
				doAddRef,	; FSHOF_ADD_REFERENCE
				doCheckDirty,	; FSHOF_CHECK_DIRTY
				doClose,	; FSHOF_CLOSE
				doGetFileID,	; FSHOF_GET_FILE_ID
				0,		; FSHOF_CHECK_NATIVE (n.u.)
				doGetExtAttrs,	; FSHOF_GET_EXT_ATTRIBUTES
				doSetExtAttrs,	; FSHOF_SET_EXT_ATTRIBUTES
				doGetAllExtAttrs, ; FSHOF_GET_ALL_EXT_ATTRIBUTES
				doForget,	; FSHOF_FORGET
				0		; FSHOF_SET_FILE_NAME (n.u.)

CheckHack	<length withHandleOpJmpTable eq FSHandleOpFunction>

	;------------------------------------------------------------
	; INTERNAL FRONT-LINE ROUTINES
	;------------------------------------------------------------
doRead:
	; bx = DOS file handle
		mov	ah, MSDOS_READ_FILE
		jmp	passToDOS
	;--------------------
doWrite:
	; bx = DOS file handle
		call	markDirty
		mov	ah, MSDOS_WRITE_FILE
passToDOS:
		call	DOSUtilInt21
		retn
	;--------------------
markDirty:
		push	ds
		call	LoadVarSegDS
		ornf	ds:[bp].DFE_flags, mask DFF_DIRTY
		pop	ds
		retn
	;--------------------

doPosition:
	; bx = DOS file handle
		call	DOSHandleOpPosition
		retn

	;--------------------
doClose:
	; bx = geos file handle
	; bp = private data
	; Do file-change notification first.

		call	notifyContentChange
doForget:
		call	DOSReleaseAllLocks

		push	cx, dx, si, ds

		mov	si, -1		; => don't notify

		push	bx		; save geos handle
		call	noAllocHandle
		call	SysLockBIOS
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
if _REDMS4
		jnc	noError
		cmp	ax, 13h		; avoid this bogus error from datalight
					;   on a correctly-fixed write-protected
					;   disk problem.
		jne	closeError
noError:
else
		LONG	jc	closeError
endif
		pop	bx
	    ;
	    ; Make sure DFE_flags for the entry is set to 0 so if the SFN
	    ; is re-used by another FSD that calls us, we don't get
	    ; confused. Also make sure HF_sfn for the file is NIL, so if
	    ; the thing is on a floppy, the flushing of files on the same
	    ; disk in DOSDiskUnlock knows to skip this now-closed file.
	    ; Set DFE_disk to 0
	    ; 
	CheckHack <offset DFF_REF_COUNT + width DFF_REF_COUNT eq 8>

		call	LoadVarSegDS
		sub	ds:[bp].DFE_flags, 1 shl offset DFF_REF_COUNT
		jnc	closeFreeJFT		; => still references, so
						;  leave the DFE alone

		call	FSDCheckOpenCloseNotifyEnabled
		jnc	clearPrivateData

	;
	; See if any other handle is open to this file. If there is one, don't
	; send out notification.
	; 
		push	bx, ax
		movdw	dxax, ds:[bp].DFE_id
		clr	si
		xchg	si, ds:[bp].DFE_disk	; fetch & set disk to 0, so we
						;  don't think this entry is
						;  still a reference to the
						;  file
		mov	bx, offset dosFileTable
		mov	cx, length dosFileTable
checkOtherOpenLoop:
		cmp	ds:[bx].DFE_disk, si
		jne	nextEntry
		cmpdw	ds:[bx].DFE_id, dxax
nextEntry:
		lea	bx, [bx+size DOSFileEntry]
		loopne	checkOtherOpenLoop
	;
	; Either ran out of entries or found one that refers to the same file.
	; 
		mov	cx, dx		; cxdx <- ID in case must notify
		mov_tr	dx, ax		; si = disk
		jne	popClearPrivateData	; => no other open, so notify
						;  of close

		mov	si, -1		; si <- -1 => no notify
popClearPrivateData:
		pop	bx, ax
		
clearPrivateData:
		mov	ds:[bp].DFE_disk, 0
		mov	ds:[bp].DFE_flags, 0
		clc

		
closeFreeJFT:
	;
	; Must unload the cached path here before the geos handle is freed.
	;
if _SFN_CACHE
		
		push	ds
		mov	ds, es:[FIH_dgroup]
		mov	bl, ds:[bx].HF_sfn
		clr	bh
		pop	ds
		call	DOS7ClearCacheForSFN
endif
		
		mov	bx, NIL		; just V the semaphore; DOS has already
					;  freed the slot
closeDone:
	;
	; Release the JFT slot
	; 
		call	DOSFreeDosHandle
		call	SysUnlockBIOS
	;
	; Now the BIOS lock is released, we can send out notification of the
	; close.
	; 
		jc	notifyDone	; => error, so no notify
		cmp	si, -1		; check disk handle for -1
		je	notifyDone	; => still open, somewhere
		mov	ax, FCNT_CLOSE
		call	FSDGenerateNotify
		clc			; no error
notifyDone:
		pop	cx, dx, si, ds
		jmp	done
closeError:
		inc	sp		; discard saved geos file handle
		inc	sp		;  as the file isn't closed
		jmp	closeDone
	;--------------------
doTruncate:
	; bx = DOS file handle
		call	markDirty
		push	cx, dx
	;
	; Seek to the truncation point.
	; 
		mov	al, FILE_POS_START
		call	DOSHandleOpPosition
		jc	truncateDone
	;
	; And write zero bytes there. This truncates under DOS...
	; 
		clr	cx
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
truncateDone:
		pop	cx, dx
		retn
		
	;--------------------
doCommit:
	; bx = DOS file handle
		call	notifyContentChange

		push	ds
		call	LoadVarSegDS
		andnf	ds:[bp].DFE_flags, not mask DFF_DIRTY
		pop	ds
if not _MS2
		mov	ah, MSDOS_COMMIT
		call	DOSUtilInt21

	; DOS 6 -- set SFTFF_WRITTEN (saying that the file is clean) since
	;	   DOS is too stupid to do this itsself

MS <		jc	commitDone					>

MS <		push	ax, bx, ds					>
MS <		call	LoadVarSegDS					>
MS <		cmp	ds:[dosVersionMajor], 6				>
MS <		jnz	10$						>

MS <		test	ds:[bp].DFE_flags, mask DFF_OURS or mask DFF_SFT_VALID>
MS <		jz	10$						>

MS <		add	bx, ds:[jftAddr].offset				>
MS <		mov	ds, ds:[jftAddr].segment			>
MS <		mov	al, ds:[bx]					>

MS <		push	es, di						>
MS <		call	DOSPointToSFTEntry		;es:di = entry	>
MS <		or	es:[di].SFTE_flags, mask SFTFF_WRITTEN		>
MS <		pop	es, di						>
MS <10$:								>
MS <		clc							>
MS <		pop	ax, bx, ds					>
MS <commitDone:								>
		retn
else
	;
	; MSDOS_COMMIT function not supported in MS DOS 2, so instead
	; we must duplicate the handle and close the duplicate.
	; 
		push	bx
		mov	bx, NIL
		call	DOSAllocDosHandle	; allocate JFT slot for dup.
		pop	bx

		mov	ah, MSDOS_DUPLICATE_HANDLE
		call	DOSUtilInt21		; ax <- new handle

		push	bx
		mov_tr	bx, ax
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21		; close the new handle

		mov	bx, NIL
		call	DOSFreeDosHandle	; and release its slot
		pop	bx
		retn
endif

	;--------------------
doLockUnlock:
	; bx = DOS file handle
	; XXX: need geos handle so we know owner of locks
		push	bp, si, di, dx
		mov	si, bp				;si = private data
		mov	bp, cx
		shr	di
		sub	di, FSHOF_LOCK
		mov_trash	ax, di	; al <- 0 for lock, 1 for unlock
			CheckHack <FSHOF_UNLOCK eq FSHOF_LOCK+1>

		push	ds
		call	LoadVarSegDS
		test	ds:[si].DFE_flags, mask DFF_GEOS
		pop	ds
		mov	si, ss:[bp].FSHLUF_regionLength.high	; si:di <- len
		mov	di, ss:[bp].FSHLUF_regionLength.low
		mov	cx, ss:[bp].FSHLUF_regionStart.high	; cx:dx <- start
		mov	dx, ss:[bp].FSHLUF_regionStart.low
		jz	afterGeosAdjust
		adddw	cxdx, <size GeosFileHeader>
afterGeosAdjust:

		call	DOSLockUnlockRecord
		jc	lockUnlockDone		; if failed our own tests,
						;  don't bother with DOS
		mov	ah, MSDOS_LOCK_RECORD
		call	DOSUtilInt21
		jnc	lockUnlockDone
	;
	; If function not supported by DOS, it's not an error...
	; 
		cmp	ax, ERROR_UNSUPPORTED_FUNCTION
		je	lockUnlockDone		; (carry cleared by eq)
		stc
lockUnlockDone:
		pop	bp, si, di, dx
		retn

	;--------------------
doGetSetDateTime:
	; bx = DOS file handle
		mov_trash	ax, di
		shr	ax
		sub	ax, FSHOF_GET_DATE_TIME	; al <- 0 for get date/time,
						; al <- 1 for set date/time
		jz	noDirty
		call	markDirty
noDirty:
			CheckHack <FSHOF_SET_DATE_TIME eq FSHOF_GET_DATE_TIME+1>
		mov	ah, MSDOS_GET_SET_DATE
		call	DOSUtilInt21
		retn

	;--------------------
doFileSize:
	; ds:bx	= FileHandle
	; bp = private data
DRI <		mov	bx, ds:[bx].FH_desc				>
DRI <		mov	dx, ds:[bx].FD_size.high			>
DRI <		mov	ax, ds:[bx].FD_size.low				>

MS <		mov	dx, ds:[bx].SFTE_size.high			>
MS <		mov	ax, ds:[bx].SFTE_size.low			>
	;
	; If file is geos file, reduce file size by size of geos file header
	; 
		call	LoadVarSegDS
		test	ds:[bp].DFE_flags, mask DFF_GEOS
		jz	doFSDone
		sub	ax, size GeosFileHeader
		sbb	dx, 0
doFSDone:
		retn

	;--------------------
doAddRef:
	; ds:bx = FileHandle
	; bp = DOSFileEntry offset
	;
	; There's no way to do this w/o knowing stuff about DOS structures,
	; as we can't leave a handle lying in the JFT...
	; 
DRI <		inc	ds:[bx].FH_refCount				>
MS <		inc	ds:[bx].SFTE_refCount				>
addRefCommon:
		push	ds
		call	LoadVarSegDS
		add	ds:[bp].DFE_flags, 1 shl offset DFF_REF_COUNT
	CheckHack <offset DFF_REF_COUNT + width DFF_REF_COUNT eq 8>
EC <		ERROR_C	TOO_MANY_REFERENCES				>
		pop	ds
		retn

	;--------------------
doCheckDirty:
	; ds:bx = FileHandle/SFTEntry
	;
	; Check the FileDesc to see if the file is dirty. It doesn't matter
	; if this handle made it dirty; when the file gets closed, the data will
	; get flushed no matter who changed it.
	;
	; DRI: regardless of whether the file is dirty, DR DOS (6.0) will
	; do a MEDIA_CHECK of the drive, even though it has nothing to
	; write to the disk, and then a BUILD_BPB if that thinks the media
	; have changed. This means we must always report the file as dirty
	; so we can be sure the right f***ing disk is in the drive
	; 	-- ardeb 3/12/92
	; MS: it's even worse for MS 3-5, as that beast not only checks the
	; media change, but also writes the first cluster of the file *and*
	; its directory entry, even if the file is clean. What a lame-ass
	; system
	; 	-- ardeb 3/26/92
	; 
	; MS 6.x: it seems like they finally got it right in DOS 6.  The
	; SFTFF_WRITTEN flag is 1 if the file is clean, and if so there is
	; no access done to the drive.
	;	-- tony 3/7/95

DRI <		mov	ax, TRUE					>

MS <		push	ds						>
MS <		call	LoadVarSegDS					>
MS <		cmp	ds:[dosVersionMajor], 6				>
MS <		pop	ds						>
MS <		mov	ax, TRUE					>
MS <		jnz	gotResult					>
MS <		mov	ax, ds:[bx].SFTE_flags				>
MS <		and	ax, mask SFTFF_WRITTEN				>
MS <		xor	ax, mask SFTFF_WRITTEN				>
MS <gotResult:								>
		retn

	;--------------------
doGetFileID:
	; ds:bx = FileHandle
	; bp = private data
	;
	; Return the directory index for the beast.
	; 
		call	LoadVarSegDS
		movdw	cxdx, ds:[bp].DFE_id
		retn

	;--------------------
checkNative:
	; bx = HandleFile
	; ch = FileCreateFlags
	; 
	;
	; See if a newly-created file is open in a mode appropriate to
	; what the caller asked for.
	;
	; NOTE: this code is jumped to, not called (as all the other things
	; are...)
	; 
		push	ds, cx
		andnf	cx, (mask FCF_NATIVE shl 8)	; ch <- native wanted
							; cl <- is native
							;  (assume geos)
		call	LoadVarSegDS
		test	ds:[bp].DFE_flags, mask DFF_GEOS
		jnz	compareTheoryAndReality
		ornf	cl, mask FCF_NATIVE
compareTheoryAndReality:
		xor	ch, cl		; (clears carry)
		pop	ds, cx
		js	cNDone		; => theory didn't match reality,
					;  so leave carry clear
		stc			; indicate match
cNDone:
		jmp	done
	;--------------------
doGetExtAttrs:
		push	es, dx
		segmov	es, dgroup, di
		mov	si, es:[bp].DFE_disk
		; XXX: this assumes dosFileTable isn't 0
		xchg	bp, dx		; dx <- priv data, bp <- passed
					;  data
		mov	ax, ss:[bp].FHEAD_attr	; ax <-attr desired
		les	di, ss:[bp].FHEAD_buffer; es:di <- buffer
		call	DOSVirtGetExtAttrs
popAndReturn:
		pop	es, dx
		retn
	;--------------------
doSetExtAttrs:
		push	es, dx
		segmov	es, dgroup, di
		mov	si, es:[bp].DFE_disk
		xchg	bp, dx
		mov	ax, ss:[bp].FHEAD_attr	; ax <-attr desired
		les	di, ss:[bp].FHEAD_buffer; es:di <- buffer
		call	DOSVirtSetExtAttrs
		jmp	popAndReturn
	;--------------------
doGetAllExtAttrs:
		call	DOSVirtGetAllExtAttrs
		retn
	;--------------------
noDone:
		clc
		jmp	done
	;--------------------
noDoCheckDirty:	; default behaviour: assume dirty
		mov	ax, TRUE
		jmp	noDone
	;--------------------
noDoAddReference:
		call	noAllocHandle	; convert geos to DOS handle
		push	bx
		mov	bx, NIL
		call	DOSAllocDosHandle	; allocate another JFT slot
						;  for the duplicate we're about
						;  to make
		pop	bx

		mov	ah, MSDOS_DUPLICATE_HANDLE
		call	DOSUtilInt21

		call	DOSFreeDosHandle	; free the slot for the original
		mov_tr	bx, ax
		call	DOSFreeDosHandle	; free the slot for the dup
	;
	; set up return address for addRefCommon to return to.
		push	cs:[doneOffset]
		jmp	addRefCommon
doneOffset	word	offset done
	;--------------------
noDoFileSize:
		call	noAllocHandle
		call	DOSUtilFileSize		; copes with header
		call	DOSFreeDosHandle
		jmp	done

	;--------------------
doSetFileName:
		call	DOSHandleOpSetFileName
		jmp	done

	;------------------------------------------------------------
	;
	; 		UTILITY ROUTINES
	;
noAllocHandle:
	; Pass:	es	= FSIR
	; 	bx	= geos file handle
	; Ret:	bx	= DOS handle
	; 
		push	ds
		mov	ds, es:[FIH_dgroup]
		mov	bl, ds:[bx].HF_sfn
		call	DOSAllocDosHandle
		pop	ds
		retn

	;--------------------
	; If file marked dirty, let the world know it's changed
notifyContentChange:
		tst	bp
		jz	notifyContentChangeDone
		push	ds
		call	LoadVarSegDS
		test	ds:[bp].DFE_flags, mask DFF_DIRTY
		jz	popDSNotifyContentChangeDone
		mov	ax, FCNT_CONTENTS
		call	notifyHandleChange
popDSNotifyContentChangeDone:
		pop	ds
notifyContentChangeDone:
		retn

	;--------------------
	; Send out indicated notification.
	; ax = FileChangeNotificationType
	; bp = offset of DOSFileEntry, 0 if none
notifyHandleChange:
		tst	bp			; any private data?
		jz	notifyHandleChangeDone

		push	cx, dx, bx, ds		; don't trash anything
		call	LoadVarSegDS
		movdw	cxdx, ds:[bp].DFE_id	; cxdx <- ID
		call	FSDGenerateNotify
		pop	cx, dx, bx, ds
notifyHandleChangeDone:
		retn
DOSHandleOp	endp


if _MS7


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCompareFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare two open files (given their SFNs) to see if they
		refer to the same disk file. Note: one or both SFN may actually
		be invalid, owing to the lack of synchronization during
		the closing of a file. The driver must check for this and
		return that the two are unequal.


		This version compensates for the fact that some DOS7s don't
		keep the SFT updated.  The LFN API for Win95 provides
		a GetFileInfoByHandle function which returns, among other
		things, a unique id for the file.  These are used instead
		of the SFT.

CALLED BY:	DR_FS_COMPARE_FILES
PASS:		al	= SFN of first file
		cl	= SFN of second file
RETURN:		ah	= flags byte (for sahf) that will allow je if the
			  two files refer to the same disk file (carry will be
			  clear after sahf).
DESTROYED:	al, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	2/13/97		Initial version for MS7

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCompareFiles proc	far
handleInfo	local	ByHandleFileInfo
		uses	bx, cx, dx, ds, si
		.enter
	;
 	; Get the index and volume of the first SFN. 
	;
		mov	bl, al
		call	DOSAllocDosHandleFar	;bx <- DOS handle

		segmov	ds, ss
		lea	dx, ss:[handleInfo]
		mov	ax, MSDOS7F_GET_FILE_INFO_BY_HANDLE
		stc					; must set carry
		call	DOSUtilInt21
		jc	bogusSFN
	;
	; Store the relevent info away.  Free the JFT slot.
	;
		mov	al, cl				; al <- next SFN
		mov	cx, ss:[handleInfo].BHFI_volume.low
		mov	di, ss:[handleInfo].BHFI_indexHigh.low
		mov	si, ss:[handleInfo].BHFI_indexLow.low
		call	DOSFreeDosHandleFar

	;
	; Get the index and volume for the second SFN.
	;
		mov	bl, al
		call	DOSAllocDosHandleFar
		mov	ax, MSDOS7F_GET_FILE_INFO_BY_HANDLE
		stc
		call	DOSUtilInt21
		jc	bogusSFN
		
		call	DOSFreeDosHandleFar
	;
	; And do the comparisons.
	;
		cmp	cx, ss:[handleInfo].BHFI_volume.low
		jne	done

		cmp	di, ss:[handleInfo].BHFI_indexHigh.low
		jne	done

		cmp	si, ss:[handleInfo].BHFI_indexLow.low
		clc
done:
		lahf
			.leave
			ret
bogusSFN:
	;
	; One of the SFNs was bogus, so be sure to return not-equal with carry
	; clear (OR clears the carry for us)
	; 
		or	ax, 1
		jmp	done
DOSCompareFiles endp

else

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCompareFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare two open files (given their SFNs) to see if they
		refer to the same disk file. Note: one or both SFN may actually
		be invalid, owing to the lack of synchronization during
		the closing of a file. The driver must check for this and
		return that the two are unequal.

CALLED BY:	DR_FS_COMPARE_FILES
PASS:		al	= SFN of first file
		cl	= SFN of second file
RETURN:		ah	= flags byte (for sahf) that will allow je if the
			  two files refer to the same disk file (carry will be
			  clear after sahf).
DESTROYED:	al, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCompareFiles proc	far
		uses	ds, si, es
		.enter
	;
	; Get pointers to the two SFT entries. If either one doesn't actually
	; exist, then the files aren't equal.
	; 
		call	DOSPointToSFTEntry
		jc	bogusSFN
		segmov	ds, es
		mov	si, di
		xchg	ax, cx
		call	DOSPointToSFTEntry
		xchg	ax, cx
		jc	bogusSFN
		
		call	DOSCompareSFTEntries
		clc		; must return flags word with carry clear
done:
		lahf
		.leave
		ret
bogusSFN:
	;
	; One of the SFNs was bogus, so be sure to return not-equal with carry
	; clear (OR clears the carry for us)
	; 
		or	ax, 1
		jmp	done
DOSCompareFiles endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLockUnlockRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock or unlock a range of a file.

CALLED BY:	DOSHandleOp
PASS:		bx	= DOS handle
		al	= 1 to unlock, 0 to lock
		cx:dx	= start of affected range
		si:di	= length of affected range
RETURN:		carry set if region already claimed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLockUnlockRecord proc far
		.enter
		clc		; do nothing for now
		.leave
		ret
DOSLockUnlockRecord endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSReleaseAllLocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A file is about to be closed, so release any and all locks
		there may be on the physical file attached to this handle.

CALLED BY:	DOSHandleOp
PASS:		bx	= DOS handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSReleaseAllLocks proc far
		.enter
		.leave
		ret
DOSReleaseAllLocks endp



Resident	ends
