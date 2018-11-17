COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Heap -- Heap scrubbing
FILE:		heapScrub.asm

AUTHOR:		Adam de Boor, Jun 25, 1990

ROUTINES:
	Name			Description
	----			-----------
	VScrub			Let the scrub thread run
	HeapStartScrub		Create the scrub thread at boot time
	HeapScrubThread		Driving function for scrub thread
	HeapEnsureFreeSpace	Make sure there's room enough for the
				given # of paragraphs to come in.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/25/90		Initial revision


DESCRIPTION:
	Functions to implement the heap scrub thread -- a low-priority (hence
	idle-time) thread to clean out the heap when it is close to
	overcommitted.
	
	A primary tenet of this module is that the scrubbing must not interfere
	with regular system activity. Anything that suddenly needs a lot of
	memory will get it by going through the normal FindFree channels.
	It will be slower, but it will function (one hopes). The scrub thread
	is intended to act like "read-ahead" for a disk cache: clearing the
	way so the memory will be there when needed. If it falls behind,
	however, the system will continue, just as a sector will be read even
	if the read-ahead function made an incorrect prediction of what the
	system would need next.
	
	Because of this tenet, the thread releases and grabs the heap semaphore
	more than you would think is necessary.
		

	$Id: heapScrub.asm,v 1.1 97/04/05 01:14:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeapScrubThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Driving function for heap scrubbing.

CALLED BY:	ThreadCreate
PASS:		ds	= idata
		es	= idata
RETURN:		never
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
	Wait until woken up or scrub interval has passed.
	
	If used block above the boundary block is locked, nuke heapDesiredSize -
		heapFreeSize bytes
	Else, nuke heapDesiredSize - boundary.HM_size bytes
	When done, if couldn't free up enough and
	     	heapFreeSize < heapDesiredSize, broadcast
		MSG_PROCESS_MEM_FULL(HC_CONGESTED)
	Incrementally compact the heap until there's nothing more to compact.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeapScrubThread	proc	far
	;
	; Save the current hour in the high byte of a word on the stack for
	; our hack to deal with the double-rollover DOS clock bug.
	; 
		push	{word}ds:[hours-1]
scrubLoop:
	;
	; Deal with double-rollover DOS clock bug (if midnight passes twice
	; without DOS having to figure out what time it is, it will not
	; properly increment the day) by telling DOS what the new date and
	; time is when we pass midnight.
	; 
		pop	ax			; ah <- hour last time
		mov	al, ds:[hours]
		cmp	ah, al			; same hour?
		je	waitForSomething	; yes => do nothing
		tst	al			; hour past midnight?
		jnz	waitForSomething	; no => do nothing

		call	SysLockBIOS		; gain exclusive access to DOS
		call	RestoreMSDOSTime	; reset its date and time
		call	SysUnlockBIOS		; and release exclusive access
waitForSomething:
	;
	; Push current hour for next time through...
	; 
		mov	ah, al
		push	ax

		PTimedSem	ds, scrubSem, SCRUB_TIMEOUT, TRASH_AX_BX_CX
		jc	compactLoop	; Timeout => not in danger

if	IDLE_UPDATE_ASYNC_VM
		call	HeapIdleUpdateVM
endif	; IDLE_UPDATE_ASYNC_VM

	;
	; Throw out enough to bring the boundary block up to the desired
	; size if the heap were completely compact.
	;
		call	HeapLocateBoundary
		mov	di, ds:[bx].HM_next
		mov	ax, ds:[loaderVars].KLV_heapDesiredSize
		jnc	20$			;throw out maximum if no
						; boundary block
		tst	ds:[di].HM_lockCount
		jz	figureMegaTonnage
	;
	; Block beyond boundary block is locked, so there's no point in
	; basing our decisions on the amount we can throw out to make
	; the boundary block the right size. Instead, we decide based on
	; the amount of free space on the heap, in the hope that the block
	; will soon be unlocked and life will return to goodness and
	; compactitude.
	; 
		mov	si, ds:[loaderVars].KLV_heapFreeSize
		add	ax, HEAP_EXTRA_LOCKED_SIZE
figureMegaTonnage:		
		sub	ax, si
		jb	compactLoop		; boundary already big enough
20$:

if 0	; NO LONGER SEND LOW SEVERITY WARNINGS -- tony 4/18/92

	;
	; First notify everyone that the heap is getting full
	;
		push	ax
		mov	ax, MSG_PROCESS_MEM_FULL
		clr	cx		; Low severity
		call	DoBroadcast
		pop	ax
endif

	;
	; Now let ThrowOutBlocks work its magic. We don't grab the heap
	; semaphore before calling so TOB can give other threads a chance
	; at the heap. It attempts to be as unobtrusive as possible...
	; 
		mov	di, offset swapTable
		call	ThrowOutBlocks
		jnc	compactLoop

	;
	; Couldn't throw out enough to get to the desired level, so tell the
	; world to clean up its act if the total free space on the heap
	; is actually below the desired free-space threshold.
	; 
		mov	ax, ds:[loaderVars].KLV_heapFreeSize
		cmp	ax, ds:[loaderVars].KLV_heapDesiredSize
		jae	compactLoop

		mov	cx, HC_CONGESTED
		mov	ax, MSG_PROCESS_MEM_FULL
		call	DoBroadcast
compactLoop:
	;
	; Now gradually compact the heap. This always happens, even if we didn't
	; need throw anything away. Not particularly expensive since this
	; is idle-time.
	;
		call	PHeap
		clr	cl
		call	CompactHeap
		call	VHeap
		jnc	compactLoop
		jmp	scrubLoop
HeapScrubThread	endp

DoBroadcast	proc	near
	mov	di, mask MF_RECORD
	call	ObjMessage			;di = message
	mov	bx, di
	call	ObjProcBroadcastMessage
	ret
DoBroadcast	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeapIdleUpdateVM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update any VM files that need updating

CALLED BY:	(INTERNAL) HeapScrubThread
PASS:		ds	= kdata
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 7/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	IDLE_UPDATE_ASYNC_VM
HeapIdleUpdateVM proc	near
		.enter
fileLoop:
		mov	bx, ds:[heapAsyncVMQueue]
		tst	ds:[bx].HQ_semaphore.Sem_value
		jz	done
		
		call	PvmSemFar
	;
	; Remove a message from the queue and fetch the file to be updated
	; from it.
	;
		call	QueueGetMessage
		mov_tr	bx, ax
		mov	ax, ds:[bx].HE_method
	;
	; Nuke the message and update the file.
	;
		call	ObjFreeMessage
		mov_tr	bx, ax
		tst	bx
		jz	fileClosed
		call	VMUpdate
fileClosed:
		call	VvmSemFar
		jmp	fileLoop
done:
		.leave
		ret
HeapIdleUpdateVM endp
endif	; IDLE_UPDATE_ASYNC_VM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeapVMFileClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a VM file is about to be closed and remove it from
		the async-update queue, if it's present.

CALLED BY:	(EXTERNAL)
PASS:		ds	= kdata
		bx	= file being closed
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	queued messages have their HE_method set to 0 if they match
     		the file being closed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	IDLE_UPDATE_ASYNC_VM
HeapVMFileClosed proc	far
		uses	ax, bx, di
		.enter
		push	cs
		mov	ax, offset callback
		push	ax
		mov_tr	ax, bx
		mov	bx, ds:[heapAsyncVMQueue]
		mov	di, mask MF_CHECK_DUPLICATE or mask MF_CUSTOM or \
				mask MF_DISCARD_IF_NO_MATCH or \
				mask MF_FORCE_QUEUE
		call	ObjMessage
		.leave
		ret

callback:
		mov	di, PROC_SE_CONTINUE
		cmp	ax, ds:[bx].HE_method
		jne	callbackDone
		mov	ds:[bx].HE_method, 0
		mov	di, PROC_SE_EXIT
callbackDone:
		retf
HeapVMFileClosed endp
endif	; IDLE_UPDATE_ASYNC_VM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeapLocateBoundary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the boundary block between the fixed and movable heaps

CALLED BY:	HeapScrubThread, HeapEnsureFreeSpace
PASS:		ds	= idata
RETURN:		bx	= boundary block
		si	= size of boundary block (paras)
		carry set if actual boundary block located
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeapLocateBoundary proc	near
		.enter
		call	PHeap
		mov	bx, offset loaderVars.KLV_handleBottomBlock - \
								offset HM_next
findBoundary:
		mov	si, ds:[bx].HM_next
		tst	ds:[si].HM_owner
		jz	10$
		test	ds:[si].HM_flags, mask HF_FIXED
		jz	checkFree
10$:
		mov	bx, si
		jmp	findBoundary

checkFree:
		cmp	bx, offset loaderVars.KLV_handleBottomBlock - \
								offset HM_next
		je	done			; (carry already clear)
		tst	ds:[bx].HM_owner	; (clears carry)
		jnz	done
		stc				; indicate successful search
		mov	si, ds:[bx].HM_size	;  and return block size
done:
		call	VHeap
		.leave
		ret
HeapLocateBoundary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VScrub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the scrub thread go.

CALLED BY:	FindFree
PASS:		ds	= idata
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VScrub		proc	near

;	The actual count of the scrubSemaphore is irrelevant here - just
;	make sure it is non-zero, so the scrub thread will run.

		pushf
		push	ds
		LoadVarSeg	ds
		cmp	ds:[scrubSem].Sem_value, 0
		pop	ds
		jg	exit
		popf

		push	bx
		mov	bx, offset scrubSem
		jmp	SysVSemCommon
exit:
		popf
		ret
VScrub		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeapMarkForIdleUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the passed file for updating

CALLED BY:	(EXTERNAL)
PASS:		bx	= VM handle to update at idle time
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 8/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	IDLE_UPDATE_ASYNC_VM
HeapMarkForIdleUpdate proc	near
		uses	bx, ds, ax, di
		.enter
		pushf
		mov_tr	ax, bx
		LoadVarSeg	ds
		mov	bx, ds:[heapAsyncVMQueue]
		mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE
		call	ObjMessage
		call	VScrub
		popf
		.leave
		ret
HeapMarkForIdleUpdate endp
endif	; IDLE_UPDATE_ASYNC_VM


GLoad	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeapEnsureFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the heap has enough room for the indicated number
		of paragraphs to be loaded in.

CALLED BY:	LoadGeodeLow
PASS:		ax	= number of paragraphs to be free
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeapEnsureFreeSpace	proc	near	uses	ax, bx, cx, dx, si, di, bp
		.enter
		call	FarPHeap
EC <		call	AssertDSKdata					>
	;
	; Up the amount needed by the desired size of the boundary block.
	;
		add	ax, DANGER_LEVEL shr 4

	;
	; Max the amount out at twice the target level for the scrub thread.
	; This is an arbitrary number, of course...
	; 
		mov	bx, ds:[loaderVars].KLV_heapDesiredSize
		shl	bx
		cmp	ax, bx
		jb	checkEnoughAlready
		mov	ax, bx
checkEnoughAlready:
	;
	; If there's enough free space already, do nothing.
	;
		sub	ax, ds:[loaderVars].KLV_heapFreeSize
		jbe	done
		
	;
	; always throw out a fair amount (or else it is not worth our while)
	;
		cmp	ax, MIN_SPACE_TO_THROW_OUT
		jae	10$
		mov	ax, MIN_SPACE_TO_THROW_OUT
10$:
	;
	; Else throw out enough to bring heapFreeSize up to the desired size.
	;
		mov	di, offset swapTable
		call	ThrowOutBlocks
done:
		call	FarVHeap
		.leave
		ret
HeapEnsureFreeSpace	endp

GLoad	ends
