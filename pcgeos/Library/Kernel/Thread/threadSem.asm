COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Thread
FILE:		threadSem.asm

ROUTINES:
	Name				Description
	----				-----------
   GLB	ThreadBlockOnQueue		Block on a queue (application entry
					point)
   GLB	ThreadWakeUpQueue		Wake up a queue (application entry
					point)

   EXT	BlockOnLongQueue		Block on a queue (general routine)
   EXT	WakeUpLongQueue			Wake up a queue (general routine)
   EXT	WakeUpRunQueue			Wake up the run queue
   EXT	WakeUpSI			Wake up thread SI

   INT	WakeUpRunQueue			Wake up the run queue

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

DESCRIPTION:
	This file implements the semaphore handling routines.

	$Id: threadSem.asm,v 1.1 97/04/05 01:15:22 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadAllocThreadLock

DESCRIPTION:	Allocate a semaphore

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	bx - handle of semaphore

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ThreadAllocThreadLock	proc	far

	mov	bx, 1

	FALL_THRU	ThreadAllocSem

ThreadAllocThreadLock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadAllocSem

DESCRIPTION:	Allocate a semaphore

CALLED BY:	GLOBAL

PASS:
	bx - value for semaphore

RETURN:
	bx - handle of semaphore

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ThreadAllocSem	proc	far	uses ds
	.enter

	push	bx
	LoadVarSeg	ds
	mov	bx, ss:[TPD_processHandle]	;owner
	call	AllocateHandle			;all fields set to zero
	mov	ds:[bx].HS_type, SIG_SEMAPHORE
	mov	ds:[bx].HS_moduleLock.TL_owner, -1
	pop	ds:[bx].HS_moduleLock.TL_sem.Sem_value

	.leave
	ret

ThreadAllocSem	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadFreeSem

DESCRIPTION:	Allocate a semaphore

CALLED BY:	GLOBAL

PASS:
	bx - handle of semaphore

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ThreadFreeSem	proc	far	uses ds
	.enter
EC <	call	CheckLegalSemaphoreHandle				>
	LoadVarSeg	ds
	call	FreeHandle

	.leave
	ret

ThreadFreeSem	endp
if ERROR_CHECK
CheckLegalSemaphoreHandle	proc	near
	pushf					; flags presevered, remember?
	push	ds				;	-- todd 08/15/94
	LoadVarSeg	ds
	call	CheckHandleLegal					
	cmp	ds:[bx].HS_type, SIG_SEMAPHORE				
	ERROR_NZ	NON_SEMAPHORE_PASSED_TO_SEM_ROUTINE
	pop	ds
	call	SafePopf			; can be called with INTs off.
	ret					;	-- todd 08/15/94
CheckLegalSemaphoreHandle	endp
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadPSem

C DECLARATION:	extern SemaphoreError
			_far _pascal ThreadPSem(SemaphoreHandle sem);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
THREADPSEM	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	FALL_THRU	ThreadPSem

THREADPSEM	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadPSem

DESCRIPTION:	P a semaphore

CALLED BY:	GLOBAL

PASS:
	bx - handle of semaphore

RETURN:
	ax - SemaphoreError

DESTROYED:
	none (carry flag preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ThreadPSem	proc	far
	call	_dopsem
	clr	ax
	ret

ThreadPSem	endp

_dopsem		proc	near

	push	bx
EC <	call	CheckLegalSemaphoreHandle				>
	lea	bx, ds:[bx].HS_moduleLock.TL_sem	;preserve flags
	jmp	SysPSemCommon
_dopsem		endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadVSem

C DECLARATION:	extern SemaphoreError
C DECLARATION:	extern Boolean
			_far _pascal ThreadVSem(SemaphoreHandle sem);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
THREADVSEM	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	FALL_THRU	ThreadVSem

THREADVSEM	endp
	SetDefaultConvention


COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadVSem

DESCRIPTION:	V a semaphore

CALLED BY:	GLOBAL

PASS:
	bx - handle of semaphore

RETURN:
	ax - SemaphoreError

DESTROYED:
	none (flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ThreadVSem	proc	far
	call	_dovsem
	mov	ax, 0					;preserve flags
	ret

ThreadVSem	endp

_dovsem		proc	near
EC <	call	CheckLegalSemaphoreHandle				>

	push	bx
	lea	bx, ds:[bx].HS_moduleLock.TL_sem	;preserve flags
	jmp	SysVSemCommon
_dovsem		endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadPTimedSem

C DECLARATION:	extern SemaphoreError
			_far _pascal ThreadPTimedSem(SemaphoreHandle sem,
						     word timeout);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
THREADPTIMEDSEM	proc	far	; mh:hptr
	C_GetTwoWordArgs	bx, cx,   ax,dx	;bx = handle, cx = timeout

	FALL_THRU	ThreadPTimedSem

THREADPTIMEDSEM	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadPTimedSem

DESCRIPTION:	P a semaphore with a timeout value

CALLED BY:	GLOBAL

PASS:
	bx - handle of semaphore
	cx - timeout value

RETURN:
	ax - SemaphoreError (SE_TIMEOUT if timeout)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ThreadPTimedSem	proc	far	uses ds
	.enter

	clr	ax
	LoadVarSeg	ds
EC <	call	CheckLegalSemaphoreHandle				>
	PTimedSem	ds, [bx].HS_moduleLock.TL_sem, cx
	jnc	done
	mov	ax, SE_TIMEOUT
done:

	.leave
	ret

ThreadPTimedSem	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadGrabThreadLock

C DECLARATION:	extern void
			_far _pascal ThreadGrabThreadLock(
						ThreadLockHandle sem);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
THREADGRABTHREADLOCK	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	FALL_THRU	ThreadGrabThreadLock

THREADGRABTHREADLOCK	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadGrabThreadLock

DESCRIPTION:	Grab a thread lock

CALLED BY:	GLOBAL

PASS:
	bx - handle of semaphore

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ThreadGrabThreadLock	proc	far
	call	_dolock
	ret

ThreadGrabThreadLock	endp

_dolock		proc	near
	push	bx
EC <	call	CheckHandleLegal					>
	add	bx, offset HS_moduleLock
	jmp	SysLockCommon
_dolock		endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadReleaseThreadLock

C DECLARATION:	extern void
			_far _pascal ThreadReleaseThreadLock(
						ThreadLockHandle sem);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
THREADRELEASETHREADLOCK	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	FALL_THRU	ThreadReleaseThreadLock

THREADRELEASETHREADLOCK	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadReleaseThreadLock

DESCRIPTION:	Release a thread lock

CALLED BY:	GLOBAL

PASS:
	bx - handle of semaphore

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ThreadReleaseThreadLock	proc	far
	call	_dounlock
	ret

ThreadReleaseThreadLock	endp

_dounlock	proc	near
	push	bx
EC <	call	CheckHandleLegal					>
	add	bx, offset HS_moduleLock
	jmp	SysUnlockCommon
_dounlock	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ThreadBlockOnQueue

DESCRIPTION:	Block on a queue (application entry point)

CALLED BY:	GLOBAL

PASS:
	ax - segment of queue
	bx - offset of queue

RETURN:
	ax, bx - destroyed

DESTROYED:
	none (flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

ThreadBlockOnQueue	proc	far
	call	BlockOnLongQueue	;call real routine
	ret

ThreadBlockOnQueue	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ThreadWakeUpQueue

DESCRIPTION:	Wake up a queue (application entry point)

CALLED BY:	GLOBAL

PASS:
	ax - segment of queue
	bx - offset of queue

RETURN:
	ax, bx - destroyed

DESTROYED:
	none (carry flag preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

ThreadWakeUpQueue	proc	far
	call	WakeUpLongQueue		;call real routine
	ret

ThreadWakeUpQueue	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	WakeUpSI

DESCRIPTION:	Wake up thread SI if it is higher priority than current
		thread.  Otherwise, put SI on the run queue.

CALLED BY:	EXTERNAL
		ThreadCreate

PASS:
	si - handle of thread

RETURN:
	si - same

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/88		Initial version
-------------------------------------------------------------------------------@

FarWakeUpSI	proc	far
	call	WakeUpSI
	ret
FarWakeUpSI	endp

WakeUpSI	proc	near
if	SUPPORT_32BIT_DATA_REGS
	push	ds
	push	esi
	push	edi
	push	ecx
	pushf
	push	edx
	mov	ecx, eax		; ecx.high = eax.high
	rol	ebx, 16			; bx = orig ebx.high
	mov	cx, bx			; cx = orig ebx.high
	ror	ebx, 16			; restore ebx
	push	ecx			; push eax.high, ebx.high
	push	es
	push	fs
	push	gs
else
	push	ds
	push	si
	push	di
	push	cx
	pushf
	push	dx
	push	es
endif	; SUPPORT_32BIT_DATA_REGS
	LoadVarSeg	ds
	INT_OFF
	jmp	WakeUpCommon

WakeUpSI	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	WakeUpRunQueue

DESCRIPTION:	Wake up any higher-priority thread that is runnable.

CALLED BY:	EXTERNAL
		TimerInterrupt, ThreadModify, SysExitInterrupt

PASS:
	ds	= idata

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
	ardeb	5/90		Changed to check for empty run queue and save bx
				(2 of the 3 places that called this
				saved bx around it; 2 of 3 places had to check
				for a non-zero run queue)
-------------------------------------------------------------------------------@

WakeUpRunQueue	proc	near
	push	bx
	mov	bx,offset runQueue
	tst	{word}ds:[bx]
	jz	noOneElse
	mov	ax,ds
	call	WakeUpLongQueue
noOneElse:
	pop	bx
	ret
WakeUpRunQueue	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	WakeUpLongQueue

DESCRIPTION:	Wake up a queue (kernel entry point)

CALLED BY:	EXTERNAL
		WakeUpCSQueue, ThreadWakeUpQueue

PASS:
	ax - segment of queue
	bx - offset of queue

RETURN:
	ax, bx - destroyed
	carry flag - SAME

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Take first thread off of queue and put it on run queue.  If new
	thread is higher priority than current thread, then block the current
	thread and run the new thread.

	If in interrupt code or in in the kernel's thread then do not context
	switch.

	Since the PSem and VSem macros do not turn off interrupts, a little
	bit of special syncronization code is required in BlockOnLongQueue
	and in WakeUpLongQueue:

		BlockOnLongQueue:
			INT_OFF
			test	queue,15
			jz	BOLQ_block
			dec	queue
			ret
		BOLQ_block:
			** Block on the queue

		WakeUpLongQueue:
			INT_OFF
			test	queue,15
			jbe	WULQ_wakeUp
			inc	queue
			ret
		WULQ_wakeUp:
			** Wake up the queue

	The problem is that PSem might decrement the semaphore from 0 to -1
	but before the thread can block, a context switch causes another
	thread to do a VSem and increment from -1 to 0.  This causes
	WakeUpLongQueue to be called which normally expects to wake up a
	thread.  This is impossible since the first thread has not yet blocked.
	In this case WakeUpLongQueue will set the queue to 1 which signals
	BlockOnLongQueue to not actually block.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

WakeUpLongQueue	proc	near
if	SUPPORT_32BIT_DATA_REGS
	push	ds
	push	esi
	push	edi
	push	ecx
	pushf
	push	edx
	mov	ecx, eax
	rol	ebx, 16			; ecx.high = eax.high
	mov	cx, bx			; cx = orig ebx.high
	ror	ebx, 16			; restore ebx
	push	ecx			; push eax.high, ebx.high
	push	es
	push	fs
	push	gs
else
	push	ds
	push	si
	push	di
	push	cx
	pushf
	push	dx
	push	es
endif	; SUPPORT_32BIT_DATA_REGS

	LoadVarSeg	ds
	INT_OFF

	mov	es,ax

	; test for nothing to wake up

	cmp	word ptr es:[bx],16
	jae	10$
	inc	word ptr es:[bx]
	jmp	RecoverFromPartialBlock
10$:

	call	RemoveFromQueue		;get highest priority thread from queue

	;compare priorities

WakeUpCommon	label near
	cmp	si,KERNEL_INIT_BLOCK	;is kernel blocked in init code ?
	jz	kernelInit

	cmp	ds:[interruptCount],0	;are we running interrupt code ?
	jnz	intNoWakeUp		;if so then do not context switch

	mov	bx,ds:[currentThread]
	tst	bx				;test for kernel mode
	jz	noWakeUp
	mov	al,ds:[bx][HT_curPriority]	;load priority of current
	cmp	al,ds:[si][HT_curPriority]	;compare to newly runnable
	jae	BlockAndDispatchSI		;if current process is lower or
						;equal then branch to block it

	; else put new thread on run queue and exit

noWakeUp:
	mov	ax,ds:[runQueue]
	mov	ds:[si][HT_nextQThread],ax
	mov	ds:[runQueue],si
	jmp	RecoverFromPartialBlock

	; waking up kernel thread

kernelInit:
	inc	ds:[initWaitFlag]
	jmp	RecoverFromPartialBlock

	; not waking up because running interrupt code

intNoWakeUp:
	mov	ds:[intWakeUpAborted],TRUE
	jmp	noWakeUp

WakeUpLongQueue	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	BlockAndDispatchSI

DESCRIPTION:	Block on the run queue and run the given thread

CALLED BY:	EXTERNAL
		WakeUpCommon

PASS:
	interrupts off
	si - handle of thread to run
	ds - kernel variable segment
	stack - registers pushed in this order:
		ds, si, di, cx, flags, dx, es

RETURN:
	ax, bx - destroyed

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/88		Initial version

-------------------------------------------------------------------------------@

BlockAndDispatchSI	proc	near jmp
if	SUPPORT_32BIT_DATA_REGS
	push	ebp			;push the rest of the registerse
else
	push	bp			;push the rest of the registers
endif	; SUPPORT_32BIT_DATA_REGS

if UTILITY_MAPPING_WINDOW
	;
	; save current utility mapping windows
	;
	call	UtilWindowSaveMapping
endif

if	TRACK_INTER_RESOURCE_CALLS
FXIP <	push	ds:[curXIPResourceHandle] ;Save the current XIP		>
					  ;resource handle
endif
FXIP <	push	ds:[curXIPPage]		;Save the current XIP page	>

EC <	mov	dx,ss							>
EC <	cmp	dx, seg dgroup						>
EC <	ERROR_Z	BLOCK_IN_KERNEL						>

	mov	bx,ds:[currentThread]	;insert proc in queue
	mov	ax,ds:[runQueue]	;get old start of queue
	mov	ds:[bx][HT_nextQThread],ax
	mov	ds:[runQueue],bx

	mov	ds:[bx][HT_saveSS],ss
	mov	ds:[bx][HT_saveSP],sp

	;switch to kernel context

	call	SwitchToKernel			;ds <- idata

	jmp	DispatchSI

BlockAndDispatchSI	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	BlockOnLongQueue

DESCRIPTION:	Block on a queue (kernel entry point)

CALLED BY:	EXTERNAL
		ThreadBlockOnQueue, various and sundry

PASS:
	interrupts off
	ax - segment of queue
	bx - offset of queue

RETURN:
	ax, bx - destroyed
	flags - same

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Special code is needed since PSem and VSem do not turn off interrupts.
	This is detailed in WakeUpLongQueue.

		BlockOnLongQueue:
			INT_OFF
			test	queue,15
			jz	BOLQ_block
			dec	queue
			ret
		BOLQ_block:
			** Block on the queue

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

BlockOnLongQueue	proc	near
if	SUPPORT_32BIT_DATA_REGS
	push	ds
	push	esi
	push	edi
	push	ecx
	pushf
	push	edx
	mov	ecx, eax		; ecx.high = eax.high
	rol	ebx, 16			; bx = orig ebx.high
	mov	cx, bx			; cx = orig ebx.high
	ror	ebx, 16			; restore ebx
	push	ecx			; push eax.high, ebx.high

	push	es
	push	fs
	push	gs
	push	ebp
else
	push	ds		;save registers, both to save state and to
	push	si		;give us some working space
	push	di
	push	cx
	pushf
	push	dx

	push	es
	push	bp
endif	; SUPPORT_32BIT_DATA_REGS

	LoadVarSeg	ds		;ds = idata
	mov	es,ax			;es = queue

	; If blocked in kernel then assume init code and don't reset stack
	; this allows blocking in init code

	INT_OFF
	; Test for WakeUp already happened

	mov	ax,es:[bx]		;get old start of queue
	test	ax,15
	jz	10$
	dec	word ptr es:[bx]	;wake up already happened, continue
	jmp	RecoverFromFullBlock
10$:
	tst	ds:[interruptCount]
	jnz	blockInInterrupt

	mov	si,ds:[currentThread]	;insert proc in queue
	tst	si
	jz	kernel

	mov	es:[bx],si
	mov	ds:[si][HT_nextQThread],ax

if UTILITY_MAPPING_WINDOW
	;
	; save current utility mapping windows
	;
	call	UtilWindowSaveMapping
endif

if	TRACK_INTER_RESOURCE_CALLS
FXIP <	push	ds:[curXIPResourceHandle] ;Save the current XIP		>
					  ;resource handle
endif
FXIP <	push	ds:[curXIPPage]						>

	mov	ds:[si][HT_saveSS],ss
	mov	ds:[si][HT_saveSP],sp
	jmp	Dispatch		;context is switched to kernel in
					;this routine. Returning from BOLQ
					;is also handled by Dispatch
					;when this thread is woken up.

	; Blocking in kernel thread or during an interrupt -- use special wait
	; loop

kernel:
; EC CODE REMOVED 1/7/93: this can happen if wait/post is enabled and the
; machine is acting as a server for a peer-to-peer network. In this case,
; the int 28h issued by the primary IFS driver will be echoed as an
; int 2ah::84h which can cause disk access and lead to a wait/post
; invocation. The primary IFS driver doesn't do a SysEnterCritical, as it
; has no need to, other than this EC code... -- ardeb
EC <	cmp	ds:[initFlag],0						>
EC <	ERROR_Z	BLOCK_IN_KERNEL						>

blockInInterrupt:
	mov	ax, sp
	mov	si, ss
	xchg	ds:[initStack].offset, ax
	xchg	ds:[initStack].segment, si
	push	ax
	push	si
	push	{word}es:[bx]		;allow other threads to be blocked on
					; the same queue
	mov	word ptr es:[bx],KERNEL_INIT_BLOCK	;mark as special block

	clr	ax
	mov	ds:[initWaitFlag],al
	INT_ON
BOLQ_loop:
	call	Idle
	xchg	al,ds:[initWaitFlag]
	tst	al
	jz	BOLQ_loop

	pop	{word}es:[bx]		; recover previously queued threads
	pop	ds:[initStack].segment	;  and previous initStack in case
	pop	ds:[initStack].offset	;  we're nesting these things...
	jmp	RecoverFromFullBlock

BlockOnLongQueue	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	RemoveFromQueue

DESCRIPTION:	Remove the highest priority thread from the given queue

CALLED BY:	INTERNAL
		WakeUpLongQueue, Dispatch

PASS:
	interupts off
	es:bx - queue
	ds - kernel variable segment

RETURN:
	si - handle of highest priority thread (0 if none in queue)

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:
	cl - highest priority so far
	si - handle of highest priority thread

PSEUDO CODE/STRATEGY:
	Move through queue keeping to find highest priority thread

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/88		Initial version

-------------------------------------------------------------------------------@

RemoveFromQueue	proc	near
	; es:bx = queue

	mov	si,es:[bx]		;get first proc on queue

	; test for waking up thread blocked in init code

	cmp	si,KERNEL_INIT_BLOCK
	jz	kernelInit

EC <	call	CheckThreadSI						>

	cmp	ds:[si][HT_nextQThread],0	;test for only one thread
	jnz	moreThanOne

	; only one thread

	mov	word ptr es:[bx],0	;zero queue
	ret				;return thread in si

kernelInit:
	mov	word ptr es:[bx],0
	ret

moreThanOne:
	mov	dx,bx
	mov	cl,ds:[si][HT_curPriority]
	mov	bx,si
	clr	si

	; bx = current thread
	; si = handle BEFORE highest priority thread so far
	; cl = priority of highest priority thread so far

threadLoop:
	mov	di,ds:[bx][HT_nextQThread]	;di = next thread
	or	di,di				;(thread to test)
	jz	atEnd				;if at end then branch
EC <	call	CheckThreadDI						>
	cmp	cl,ds:[di][HT_curPriority]	;compare priority of current
	jb	noNewWinner			;winner to priority of thread
						;on queue.  If current is higher
						;then branch

	mov	si,bx
	mov	cl,ds:[di][HT_curPriority]

noNewWinner:
	mov	bx,di
	jmp	threadLoop

atEnd:
	or	si,si				;test for removing first thread
	jz	removeFirst

	mov	bx,si
	mov	si,ds:[si][HT_nextQThread]	;si = thread to return
	clr	di				;make si's not point to anything
	xchg	di,ds:[si][HT_nextQThread]
	mov	ds:[bx][HT_nextQThread],di
EC <	call	CheckThreadSI						>
	ret

removeFirst:
	mov	bx,dx
	mov	si,es:[bx]
	clr	di
	xchg	di,ds:[si][HT_nextQThread]
	mov	es:[bx],di
EC <	call	CheckThreadSI						>
	ret

RemoveFromQueue	endp
