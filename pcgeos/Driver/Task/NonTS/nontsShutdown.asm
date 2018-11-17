COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nontsShutdown.asm

AUTHOR:		Adam de Boor, May 11, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/11/92		Initial revision


DESCRIPTION:
	Code to handle the two shutdown calls.
		

	$Id: nontsShutdown.asm,v 1.1 97/04/18 11:58:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NTSMovableCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSShutdownAborted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a shutdown having been aborted.

CALLED BY:	NTSStart, NTSShutdownComplete
PASS:		cx	= 0 if called from outside the driver
			= non-zero if called from NTSStart
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Resize NTSExecCode to its resource size, so it can be
		    read in from the file safely.
		Call MemDiscard on the beast to throw its memory away.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTSShutdownAborted proc	far
		uses	ds
		.enter
	;
	; Make sure we actually started a task. Unless we were called from
	; NTSStart, in which case EF_RUN_DOS won't have been set, but we still
	; need to clean up.
	; 
		segmov	ds, dgroup, ax
		PSem	ds, ntsStartSem, TRASH_AX_BX
		tst	cx
		jnz	cleanUp

		clr	bx		; set/clear nothing
		call	SysSetExitFlags
		test	bl, mask EF_RUN_DOS
		jz	done
cleanUp:
	;
	; Shrink the block to its original size. If we don't do this, then the
	; kernel will get royally warped when trying to read the thing back
	; from our executable file.
	; 
		mov	ax, size NTSExecCode
		mov	bx, handle NTSExecCode
		clr	cx
		call	MemReAlloc
	;
	; Now throw the thing away.
	; 
		call	MemDiscard

	; Free the fixed block we allocated. Dunno if we're guarenteed to
	; have allocated a block when we reach this, so put in a check.
		mov	bx, ds:[ntsExecCodeHandle]
		tst	bx
		jz	noBlockAllocated
		call	MemFree
		clr	ds:[ntsExecCodeHandle]
noBlockAllocated:

	;
	; Clear the EF_RUN_DOS flag, since we won't be doing so...
	; 
		mov	bx, mask EF_RUN_DOS shl 8
		call	SysSetExitFlags
done:
		VSem	ds, ntsStartSem, TRASH_AX_BX
		.leave
		ret
NTSShutdownAborted endp

NTSMovableCode	ends

idata	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSAppsShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that all applications are now gone and the
		shutdown of devices is about to take place.

CALLED BY:	DR_TASK_APPS_SHUTDOWN
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We've got a few things to do here:
		    lock down this code resource an extra time, so the
			DR_TASK_SHUTDOWN_COMPLETE code is accessible. Set
			up ntsShutdownCompleteVector with this segment
		    lock down the NTSExecCode block, forcing it in from
		    	swap, if that's where it ended up in all the shutdown
			frenzy
		    lock the disk for the working directory
		    lock the disk for the program

NOTES:
		Changed to use segment returned by MemLock for 
		ntsShutdownCompleteVector so that the segment value
		will still be valid if the code resource gets mapped 
		out.  -- 4/18/94
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/92		Initial version
	jwu	4/18/94		Changed to make XIP-enabled

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTSAppsShutdown	proc	far
		uses	ds, bx, ax, si, bp, es, cx, di
		.enter

	; edigeron 12/15/00 - Moving this function and the next into fixed
	; code. This is needed when EMS is enabled, or else this resource
	; will most likely get loaded into the EMS page frame. This is very
	; bad, as shortly after this function exits, GEOS will unload the EMS
	; driver. Part of its shutdown process is to set the page frame to
	; point back to the last thing it pointed at before GEOS started,
	; which isn't going to be our code. So if we put this in fixed code,
	; we're guarenteed to be near the bottom of the heap, instead of in
	; the page frame.
		
		segmov	ds, dgroup, ax
if 0
	;
	; Give our block an extra lock so it stays around.
	; 
		mov	bx, handle NTSShutdownComplete
		call	MemLock				
	
	CheckHack <segment NTSShutdownComplete eq @CurSeg>

		mov	ds:[ntsShutdownCompleteVector].segment, ax
else
		mov	ds:[ntsShutdownCompleteVector].segment, cs
endif
		mov	ds:[ntsShutdownCompleteVector].offset,
				offset NTSShutdownComplete
	; edigeron 12/15/00 -
	; Due to the EMS page frame stuff, we gotta allocate a fixed block,
	; and then copy the code into it. Not pretty, but gets the job done.
	; Don't wanna know what complications HAF_CODE will or won't cause,
	; so simply not worrying about it. We don't care about errors, as
	; there is no way in hell we're going to not have enough memory free
	; here. This hack is needed because we have *too much* free memory
	; at the time this code gets called.

	;
	; Lock down the NTSExecCode block.
	; 
		push	ds
		mov	bx, handle NTSExecCode
		call	MemLock
		mov	ds, ax
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		push	ax
		mov	cx, mask HF_FIXED or (mask HAF_NO_ERR shl 8)
		call	MemAlloc
		push	bx
		mov	es, ax
		clr	di, si
		pop	cx
		shr	cx
		rep	movsw	; Memory blocks are multiples of 16, right?
		mov	bx, handle NTSExecCode
		call	MemUnlock
		pop	bx
		pop	ds
		
		mov	ds:[ntsExecCodeVector].segment, es
		mov	ds:[ntsExecCodeVector].offset, offset NTSExecRunIt
		mov	ds:[ntsExecCodeHandle], bx

	;
	; Now lock the two disks involved in this operation.
	; 
		mov	ds, ax		; segment still in ax
		call	FSDLockInfoShared
		mov	es, ax			; es:si <- cwd disk
		mov	si, ds:[ntsExecFrame].NTSEF_args.DEA_cwd.DEDAP_disk
		mov	al, FILE_NO_ERRORS	; aborting this lock is not
						;  allowed
		call	DiskLock
		
		mov	si, ds:[ntsExecFrame].NTSEF_args.DEA_prog.DEDAP_disk
		mov	al, FILE_NO_ERRORS
		call	DiskLock
		call	FSDUnlockInfoShared
		.leave
		ret
NTSAppsShutdown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSShutdownComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shutdown is now complete or has been aborted. Finish
		preparations for running the program, or clean up, whichever
		is appropriate.

CALLED BY:	DR_TASK_SHUTDOWN_COMPLETE
PASS:		cx	= non-zero if switch has been confirmed. zero if
			  something as refused permission to switch, and the
			  switch has therefore been aborted. (WILL ALWAYS BE
			  NON-ZERO: NTSShutdownCompleteStub checks and calls
			  NTSShutdownAborted if cx is 0 on entry)
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Change to program's working directory
		if kdata == PSP+16:
		    copy NTSExecCode to kdata & shrink PSP block to fit
		else
		    copy stub code/data to PSP+16 & free kdata

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTSShutdownComplete proc far

;	We assume that ss is passed in a kdata - check that assumption

EC <		mov	bx, ss:[TPD_blockHandle]			>
EC <		mov	ax, ss						>
EC <		cmp	ax, ss:[bx].HM_addr				>
EC <		ERROR_NZ	SHUTDOWN_NOT_CALLED_FROM_KERNEL_THREAD	>

;	If we are running on an XIP system, kcode will have been copied
; 	to RAM, so we cannot do a direct call to routines in kcode, because
;	it will not be at the location it was at when the calls were
;	relocated.

		mov	bx, handle SysGetConfig
		mov	ax, ss:[bx].HM_addr
		mov	ss:[TPD_callVector].segment, ax

		segmov	ds, dgroup, ax
		mov	ds, ds:[ntsExecCodeVector].segment
	;
	; Add a /r to the PSP_cmdTail so SCF_RESTARTED gets set on restart.
	;

	;	call	SysGetConfig

		mov	ss:[TPD_callVector].offset, offset SysGetConfig
		call	ss:[TPD_callVector]	; ax <- SysConfigFlags
						; dx <- processor & mach type
		test	al, mask SCF_RESTARTED
		jnz	restartFlagSet		; => /r already in command tail,
						;  so don't mess with it.
		
		push	ds
		mov	ax, ds:[ntsExecFrame].NTSEF_args.DEA_psp
		mov	ds, ax
		mov	es, ax
		mov	al, ds:[PSP_cmdTail][0]	; al <- tail length
		clr	ah
	    ;
	    ; Move the command tail bytes up 2 to make room for /r
	    ; (must be at the front b/c first non-/ arg indicates geodes to
	    ; load...)
	    ; 
		mov	si, ax
		mov_tr	cx, ax
		add	si, offset PSP_cmdTail+1; si <- c.r. after tail
		lea	di, ds:[si+2]		; di <- move up by 2
		std				; move from the end, please
		inc	cx			; move the \r too
		rep	movsb
		cld
		mov	{word}ds:[PSP_cmdTail][1], '/' or ('r' shl 8)
		add	ds:[PSP_cmdTail][0], 2
		pop	ds

restartFlagSet:
	;
	; Switch to the cwd.
	; 
		mov	dl, ds:[ntsExecFrame].NTSEF_args.DEA_cwd.DEDAP_path[0]
		sub	dl, 'A'		; dl <- drive number
		mov	ah, MSDOS_SET_DEFAULT_DRIVE
		int	21h
		lea	dx, ds:[ntsExecFrame].NTSEF_args.DEA_cwd.DEDAP_path[2]
		mov	ah, MSDOS_SET_CURRENT_DIR
		int	21h
	;
	; Figure where we should copy the thing.
	; 
		mov	ax, ds:[ntsExecFrame].NTSEF_args.DEA_heapStart
		mov	bx, ds:[ntsExecFrame].NTSEF_args.DEA_psp
		mov	dx, bx		; dx <- segment affected by DOS op --
					;  assume it'll be the PSP
		add	bx, size ProgramSegmentPrefix shr 4
		mov	ch, MSDOS_RESIZE_MEM_BLK
		cmp	ax, bx
		je	copyToAX
		xchg	ax, bx		; copy above PSP
		mov	dx, bx		; dx <- segment affected by DOS op
		mov	ch, MSDOS_FREE_MEM_BLK
copyToAX:
	; ax	= segment to which to copy the NTSExecCode
	; ch	= DOS op to perform
	; dx	= segment to which apply that op
		mov	ds:[ntsExecFrame].NTSEF_execBlock.DEA_cmdTail.segment,
				ax
		mov	ds:[ntsExecFrame].NTSEF_execBlock.DEA_cmdTail.offset,
				offset ntsExecFrame.NTSEF_args.DEA_argLen
		mov	ds:[ntsExecFrame].NTSEF_execBlock.DEA_fcb1.segment, ax
		mov	ds:[ntsExecFrame].NTSEF_execBlock.DEA_fcb1.offset, 
				offset ntsExecFrame.NTSEF_fcb1
		mov	ds:[ntsExecFrame].NTSEF_execBlock.DEA_fcb2.segment, ax
		mov	ds:[ntsExecFrame].NTSEF_execBlock.DEA_fcb2.offset, 
				offset ntsExecFrame.NTSEF_fcb2
	;
	; Set the segment of the environment the child should receive. Either
	; 0 (our own) if not interactive, or the mangled one with our adorable
	; message in it, if it is interactive.
	; 
		clr	bx
		test	ds:[ntsExecFrame].NTSEF_args.DEA_flags, 
				mask DEF_INTERACTIVE
		jz	setEnvBlock
		mov	bx, offset ntsEnvKindaStart+15
		shr	bx
		shr	bx
		shr	bx
		shr	bx
		add	bx, ax
setEnvBlock:
		mov	ds:[ntsExecFrame].NTSEF_execBlock.DEA_envBlk, bx
	;
	; Move the NTSExecFrame down to its proper location (ax)
	; 
		mov	es, ax
		clr	si
		mov	di, si
		mov	bx, handle NTSExecCode


		mov	ax, MGIT_SIZE
		mov	ss:[TPD_callVector].offset, offset MemGetInfo
		call	ss:[TPD_callVector]
;		call	MemGetInfo
		

		push	cx		; save DOS operation
		mov_tr	cx, ax
		shr	cx		; convert to words (always even b/c
					;  heap allocates in paragraphs)
		rep	movsw
		pop	ax		; ah <- operation to perform
	;
	; Switch to the stack in the NTSExecFrame
	; 
		segmov	ss, es
		mov	sp, offset ntsExecFrame.NTSEF_stack + size NTSEF_stack
	;
	; Set up stack frame for DOS to return to NTSExecRunIt in its
	; new location.
	; 
		pushf
		push	es
		mov	bx, offset NTSExecRunIt
		push	bx

		mov	es, dx		; es <- affected operation
	;
	; Calculate the number of paragraphs in the NTSExecCode block, plus the
	; PSP itself, in case we're shrinking it.
	; 
		mov	bx, di
		add	bx, 15+size ProgramSegmentPrefix
		shr	bx
		shr	bx
		shr	bx
		shr	bx
	;
	; Jump to the DOS handler.
	; 
		segmov	ds, 0, dx
		jmp	{fptr.far}ds:[21h*fptr]
NTSShutdownComplete endp

idata	ends
