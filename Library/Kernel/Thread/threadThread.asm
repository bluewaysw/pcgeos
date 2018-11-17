COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Thread
FILE:		threadThread.asm

ROUTINES:
	Name				Description
	----				-----------
   GLB	ThreadCreate			Create a new thread
   GLB	ThreadDestroy			Kill a process or a thread
   GLB	ThreadCallModuleRoutine		Call a routine in a process' module
   GLB	ThreadGetInfo			Return information about a thread
   GLB	ThreadModify			Modify a thread's priority

   EXT	Dispatch			Dispatch a process from the run queue

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file contains the routines to do thread control.

	$Id: threadThread.asm,v 1.1 97/04/05 01:15:15 newdeal Exp $

------------------------------------------------------------------------------@

GLoad	segment


COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadCreate

DESCRIPTION:	Create a new thread for a process

CALLED BY:	GLOBAL

PASS:
	al - priority of new thread
	bx - value to pass to new thread in cx
	cx:dx - routine at which new thread should start. This routine
		is called:
			Pass:	ds = es = owning geode's dgroup
				cx	= value passed to ThreadCreate in BX
				ax, bx	= undefined
				dx, bp	= 0
				si	= owning geode handle
				di	= LCT_NEW_CLIENT_THREAD
				flags	= undefined
				For Kernel Use (apps can use ThreadCreateSync /
				    ThreadCreateRelease to take advantage of 
				    this):
					the four bytes below *ss:[TPD_stackBot]
					are a locked semaphore (i.e. both words
					are 0) for use in synchronizing startup.

			Return:	never (jump to ThreadDestroy instead)

	di - size to allocate for new stack
	bp - owner for thread

RETURN:
	carry - set if error
	bx - handle of new thread
	cx - 0

DESTROYED:
	ax, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Allocate a handle table entry for the thread
	Set thread variables as passed
	Add thread to runnable list

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

RANDOM NOTES INCLUDED TO HELP THE DOCUMENTATION EFFORT:

when the thread is started, it begins execution at the cx:dx passed in
to ThreadCreate. If you're going to be fielding events use
MSG_PROCESS_CREATE_EVENT_THREAD sent to your process instead.

1024 bytes is probably reasonable (512 if you're not doing any file-related
work on the thread). if the thread'll be running any text objects or objects
that can undergo keyboard navigation (like dialog boxes and triggers and so
forth), you'll probably want to make it 3K. The kernel already adds some extra
space for handling interrupts (100 bytes, or something), but...

you can call GeodeGetProcessHandle to get the right owner.

The error that can be returned is if the kernel is unable to allocate
fixed space for the new thread's stack (this is very rare these days;
it was more important before the advent of pseudo-fixed blocks).

Usually you specify the thread to run the object block when you
allocate it with UserAllocObjBlock or you duplicate it with 
ObjDuplicateResource.

-adam

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

------------------------------------------------------------------------------@

TBS_SIZE	=	size ThreadBlockState

ThreadCreate	proc	far
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si							>
EC<	movdw	bxsi, cxdx						>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx, si							>
endif

	push	ds
	push	ax

	; allocate stack -- add the size of ThreadPrivateData to
	; the size requested so that apps are immune to changes in this size

	push	bx, cx
	mov_tr	ax, di
	add	ax,(size ThreadPrivateData) + STACK_RESERVED_FOR_INTERRUPTS
	mov	cx,ALLOC_FIXED
	call	MemAllocFar
	jc	error

	;
	; Make the thread's stack owned by the thread's owner so it
	; doesn't get freed at an "inopportune" moment.
	;
	LoadVarSeg	ds
	mov	ds:[bx].HM_owner, bp

	;
	; Duplicate the entire ThreadPrivateData for the new thread from
	; the current one. This allows the thread to inherit all exception
	; handlers and any private data allocated for the current
	; thread by some other geode.
	;
	push	es
	clr	si
	mov	di, si
	mov	es, ax
	mov	cx, size ThreadPrivateData/2

	INT_OFF
	rep	movsw	ss:
	INT_ON

if UTILITY_MAPPING_WINDOW
	;
	; clear util window private data
	;
	call	UtilWindowThreadCreate	
endif
	
	cmp	ss:[TPD_threadHandle], 0
	je	dontDuplicateKTPD_heap

finishCreate:
	; increment the reference count of the ThreadExceptionHandlers block
	; since we have a new thread that refer to it.

	mov	es, ss:[TPD_exceptionHandlers]
	inc	es:[TEH_referenceCount]

	; compute stack pointer for the thread: it starts at the very end of
	; the stack block, regardless of the size passed in.

	mov	di, ds:[bx].HM_size
	mov	cl, 4
	shl	di, cl

	pop	es

	mov	ds, ax
	clr	ax
	mov	ds:[TPD_blockHandle], bx
	mov	ds:[TPD_fsNotifyBatch], ax	; don't share notification
						;  batching, thanks
	mov	{word}ds:[TPD_exclFSIRLocks],ax	; just in case...

if AUTOMATICALLY_FIXUP_PSELF
	mov	ds:[TPD_cmessageFrame], ax	; no cmessageFrame
	mov	ds:[TPD_stackBorrowCount], ax	; no stackBorrowCount
endif

	; NOTE: MSG_PROCESS_CREATE_EVENT_THREAD depends on this being "size
	; ThreadPrivateData". If you change it, change that likewise

	mov	ds:[TPD_stackBot], size ThreadPrivateData
	pop	bx, cx

	; ds:di = stack

	pop	ax
	call	CreateThreadCommon
	pop	ds
	clc
	ret

error:
	pop	bx, cx
	pop	ax
	pop	ds
	ret

dontDuplicateKTPD_heap:
	;
	; If spawning a kernel thread, don't duplicate the ThreadPrivateData
	; heap, as it's been corrupted to contain the geode handles of the
	; owners of the various slots.
	; 
	clr	ax
	mov	di, offset TPD_heap
	mov	cx, length TPD_heap
	rep	stosw
	mov	ax, es
	jmp	finishCreate
ThreadCreate	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateThreadCommon

DESCRIPTION:	Do the common part of creating a thread

CALLED BY:	INTERNAL
		ThreadCreate

PASS:
	al - priority of new thread
	bx - value to pass to new thread in cx
	cx - segment for new thread to start at
	dx - offset for new thread to start at
	bp - owner for new thread
	ds:di - stack

RETURN:
	bx - handle of new thread

DESTROYED:
	ax, cx, dx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Allocate a handle table entry for the thread
	Set thread variables as passed
	Add thread to runnable list

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

------------------------------------------------------------------------------@
CreateThreadCommon	proc	near	uses es
	.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si							>
EC<	movdw	bxsi, cxdx						>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx, si							>
endif
	push	ax				;save priority


	call	FarPThread
	;
	; Set up state block as if thread blocked normally. Only fun thing
	; is need a near return to a far return in order to get to the
	; starting point for the thread, since DispatchSI performs a near
	; return to get to whomever blocked the thread. We use ThreadCreate's
	; far return as the place to which DispatchSI returns. Refer
	; to ThreadBlockState in localcon.def for more info on the layout.
	;
	; 2/20/92: with the addition of LCT_NEW_CLIENT_THREAD to the
	; suite of calls a library's entry point can receive, we must now
	; be sure to call said entry points whenever a thread is created, so
	; we no longer return to ThreadCreate's far return, but instead
	; return to GeodeNotifyLibraries with di & si set up properly
	; to issue the calls to all the libraries of the thread's geode
	; and only then return to the starting point for the thread.
	;
	; 5/2/94: another change. to allow the initial routine to be in movable
	; memory, if the virtual fptr indicates the routine is movable, we
	; "push" the virtual far pointer onto the new stack, followed by the
	; address of StartThread for GeodeNotifyLibraries to use as its return
	; address. StartThread will call PROCCALLFIXEDORMOVABLE_PASCAL,
	; which will pluck the vfptr off the stack and call the thing. The
	; movable routine will have to return with registers set up for going
	; to ThreadDestroy (cx, dx, bp, and si) in order for the code block
	; to be unlocked -- ardeb

	; set up far return address

	sub	di, size StackFooter
	mov	ds:[di].SL_savedStackBlock, 0	; so Swat knows no further
						;  blocks

	cmp	ch, MAX_SEGMENT shr 8
	jb	isFixed
HMA <	cmp	cx, HMA_SEGMENT						>
HMA <	je	isFixed							>

	; routine is movable -- go to StartThread first and let it call the
	; movable routine, then go to ThreadDestroy

	sub	di, (size ThreadBlockState) + 8

	mov	ds:[di+TBS_SIZE+fptr].segment,cx	;initial CS
	mov	ds:[di+TBS_SIZE+fptr].offset,dx		;initial IP

	mov	ds:[di+TBS_SIZE].segment, segment StartThread
	mov	ds:[di+TBS_SIZE].offset,offset StartThread
	jmp	createSem

isFixed:
	; routine is fixed, so GeodeNotifyLibraries can just go straight there
	; on return.

	sub	di, (size ThreadBlockState) + 4
	
	mov	ds:[di+TBS_SIZE].segment, cx		;initial CS
	mov	ds:[di+TBS_SIZE].offset, dx		;initial IP

createSem:
	mov	ds:[di].TBS_ret, offset GeodeNotifyLibraries

	;
	; Establish a claimed semaphore at stackBot, as a number of the things
	; that call us require it (e.g. MSG_PROCESS_CREATE_EVENT_THREAD, and
	; DoGeodeProcess) and they can no longer use TPD_callVector the way they
	; had been, as it can get biffed while notifying all the libraries.
	; 
	mov	si, ds:[TPD_stackBot]
	mov	ds:[si].Sem_value, 0
	mov	ds:[si].Sem_queue, 0
	add	si, size Semaphore
	mov	ds:[TPD_stackBot], si	

	;
	; Up the reference count of the owning geode as the geode cannot
	; go away until this thread is gone as well. Fetch dgroup's segment
	; while we've got both the kernel and the geode segments around.
	; dgroup is always resource #1 (offset 2 in the resource handle table)
	;
	LoadVarSeg	es, ax

	;
	; Link the stack block into the list of known stacks, for
	; ThreadFindStack to use. Stack blocks are linked through their
	; HM_usageValue fields.
	; 
	mov	si, ds:[TPD_blockHandle]
	mov	ax, si
	INT_OFF
	xchg	ax, es:[threadStackPtr]
	mov	es:[si].HM_usageValue, ax
	INT_ON

	push	ds
	xchg	bx, bp
	call	MemLock
	mov	ds, ax				; ds = core block of owner
AXIP <	cmp	bx, handle 0			; check against core block >
AXIP <	je	afterIncRef			; ...and skip for XIP	   >
	inc	ds:[GH_geodeRefCount]		; another reference to the
AXIP <afterIncRef:				; ...owner		   >
	mov	si, ds:[GH_resHandleOff]	; point si to resource table
	mov	si, ds:[si][2]			; fetch handle of dgroup
	mov	cx, es:[si].HM_addr		; fetch segment into cx
	call	MemUnlock
	xchg	bx, bp
	pop	ds

	mov	ds:[TPD_processHandle],bp


	;
	; Point DS and ES at the geode's dgroup. Seems a useful place to have
	; them...
	;
if	SUPPORT_32BIT_DATA_REGS
        clr     ax
        mov     ds:[di].TBS_ebpHigh, ax
        mov     ds:[di].TBS_ebxHigh, ax
        mov     ds:[di].TBS_eaxHigh, ax
        mov     ds:[di].TBS_edxHigh, ax
        mov     ds:[di].TBS_ecxHigh, ax
        mov     ds:[di].TBS_ediHigh, ax
        mov     ds:[di].TBS_esiHigh, ax
        mov     ds:[di].TBS_fs, NULL_SEGMENT
        mov     ds:[di].TBS_gs, NULL_SEGMENT
endif
	mov	ds:[TPD_dgroup], cx
	mov	ds:[di].TBS_ds, cx
	mov	ds:[di].TBS_es, cx
	mov	ds:[di].TBS_cx, bx	; Initial value goes in CX
	pushf
	pop	ds:[di].TBS_flags	; use the same flags that we have
	mov	ds:[di].TBS_si, bp	; SI <- owning geode
	mov	ds:[di].TBS_di, LCT_NEW_CLIENT_THREAD	;  DI <- call type
							;   for geode's
							;   libraries
	clr	ax
	mov	ds:[di].TBS_dx, ax	;  DX, and
	mov	ds:[di].TBS_bp, ax	;  BP start out 0

if UTILITY_MAPPING_WINDOW
	;
	; init util window mapping
	;
	call	UtilWindowInitSavedMapping
endif

FXIP <	mov	ds:[di].TBS_xipPage, ax					>
if TRACK_INTER_RESOURCE_CALLS
FXIP <	mov	ds:[di].TBS_resourceHandle, ax				>
endif
	;
	; Inherit the current working directory from the creating thread
	;
	mov	bx, ss:[TPD_curPath]
	call	FileCopyPath
	mov	ds:[TPD_curPath], bx

	segmov	es, ds, si		; es <- stack (also gets it in si
					;  for later reload)

	LoadVarSeg	ds		; Load ds with idata for AllocateHandle
	call	MemIntAllocHandle

	mov	es:[TPD_threadHandle], bx

	pop	ax			;Recover thread prio

	mov	ds:[bx][HT_handleSig],SIG_THREAD


	; HT_basePriority and HT_cpuUsage are in the same word -- set them both
	; at once

	mov	ds:[bx][HT_curPriority],al
	;clr	ah	; cpuUsage zeroed by AllocateHandle
	mov	ds:[bx][HT_basePriority],al

	;clr	ax	; handle zeroed by AllocateHandle
	;mov	ds:[bx][HT_nextQThread],ax
	;mov	ds:[bx][HT_eventQueue],ax

	mov	ds:[bx][HT_owner],bp

	mov	ds:[bx][HT_saveSS],si	;save passed variables
	mov	ds:[bx][HT_saveSP],di

	;
	; Place new thread handle on global list of all threads
	;
	mov	si,ds:[threadListPtr]
	mov	ds:[bx][HT_next],si
	mov	ds:[threadListPtr],bx

	mov	al,DEBUG_CREATE_THREAD	;notify debugger of thread creation
	call	FarDebugProcess

	call	FarVThread

	; bx = handle to new thread

	mov	si,bx			;pass thread in si
	call	FarWakeUpSI		;wake up thread if higher priority
	mov	bx,si

	clr	cx
	.leave
	ret
CreateThreadCommon	endp

GLoad	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starting-point for threads. Returned to by GeodeNotifyLibraries
		with the vfptr of the start routine on the stack.

CALLED BY:	(INTERNAL)
PASS:		ds, es	= owner's dgroup
		cx	= value passed to ThreadCreate in BX
		si	= owning geode
		di	= LCT_NEW_CLIENT_THREAD
		dx, bp	= 0
RETURN:		never
DESTROYED:	everything
SIDE EFFECTS:	when returned to, jumps immediately to ThreadDestroy, so
     			cx, dx, bp and si should be set up appropriately

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartThread	proc	far jmp
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jmp	ThreadDestroy
StartThread	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	RemoveThread

DESCRIPTION:	Remove the given thread from the list of threads.

CALLED BY:	INTERNAL
		ThreadDestroy

PASS:
	exclusive access to thread list
	bx - handle of thread to remove
	ds - kernel variable segment
	si - stack block handle

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
	Tony	4/88		Initial version

------------------------------------------------------------------------------@
RemoveThread	proc	near
EC <	call	ECCheckThreadHandle					>

	;
	; First, remove the stack block from the list of all stacks.
	; 
	push	di, ax
	mov	ax, offset threadStackPtr - offset HM_usageValue
stackLoop:
	mov_tr	di, ax				; di <- possible predecessor
	mov	ax, ds:[di].HM_usageValue	; ax <- following block
EC <	tst	ax							>
EC <	ERROR_Z	THREAD_STACK_NOT_IN_LIST				>
	cmp	ax, si				; is stack being removed the
						;  "next" block in the list?
	jne	stackLoop			; no -- keep looking
	
	mov	ax, ds:[si].HM_usageValue	; ax <- new next
	mov	ds:[di].HM_usageValue, ax	; unhook stack from predecessor

	push	si
	mov	si,offset threadListPtr		;Thread **si = &threadListPtr

RT_loop:
	mov	di,ds:[si]			;di = *si
EC <	tst	di							>
EC <	ERROR_Z	ILLEGAL_THREAD						>
	cmp	bx,di				;if (bx == *si)
	jz	found
	lea	si,ds:[di].HT_next		;si = &(si->next)
	jmp	RT_loop

found:
	mov	di,ds:[di].HT_next
	mov	ds:[si],di

	pop	si
	pop	di, ax
	GOTO	FreeHandle			;free handle and exit
						;(turns on interrupts)

RemoveThread	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadDestroy

DESCRIPTION:	Exit the current process or thread

CALLED BY:	GLOBAL

PASS:
	cx 	- exit code
	dx:bp	- OD to send MSG_META_ACK to after thread is completely dead
	si 	- data to pass as BP portion of "DX:BP = source of ACK" in
		  MSG_META_ACK, as the source, this thread, requires only DX
		  to reference.

RETURN:
	never

DESTROYED:
	---

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Doug	6/92		Added ability to pass "si" on through

------------------------------------------------------------------------------@
ThreadDestroy	proc	far	jmp
	push	si, cx, dx, bp		;save parameters

	mov	dx,ax			;pass exit code in dx

	call	GeodeLockCoreBlock	;ds = core block (locked), bx = han
	test	ds:[GH_geodeAttr], mask GA_PROCESS
	segmov	es, ds			; es = core block
	LoadVarSeg	ds
	jz	notProcess

if	(0)	; not yet! -- Doug 4/20/93
	; Nuke reference to thread, if it exists, added by GeodeLoad
	; for threads that are involved in transparently detaching an app.
	;
	mov	cx, ds:[currentThread]
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_THREADS
	call	GCNListRemove
endif

	; exiting the first thread of a process ?

	mov	ax, ds:[currentThread]
	cmp	ax, ds:[bx].HM_otherInfo	;killing first thread?
	jnz	notFirstThread

	; killing the first thread -- find any object resources run by the
	; thread and change their otherInfo to -1

	push	ax, bx, ds
	segmov	ds, es				;need core block in ds
	mov	bx, -1
	call	SubstituteRunningThread		;Find any object resources run
						;by the process thread & replace
						;their HM_otherInfo field w/-1.
	pop	ax, bx, ds

	; If the UI is going away, validate any disk handles for running a
	; DOS application while we've still got a thread on which to do it.

	cmp	bx, ds:[uiHandle]
	jne	nukeProcess

	;We're nuking the UI thread, so zero out the handle here, to
	; minimize any weird timing windows, where code may try to
	; send messages to it while it is exiting. This fixes the 
	; problem on the Bullet where the power driver polls the battery
	; every 30 ticks (and never stops), by sending a message to the UI
	; thread - if the timer went off after the thread was destroyed,
	; but before uiHandle was zeroed out, the Bullet code would die.
	; The Bullet power code is still wrong, but at least it won't crash
	; anymore - 7/26/94 atw

	clr	ds:[uiHandle]
	call	InitFileCommit		;and flush the geos.ini file

	test	ds:[exitFlags], mask EF_RUN_DOS
	jz	nukeProcess

	mov	di, DR_TASK_APPS_SHUTDOWN
	call	ds:[taskDriverStrategy]

nukeProcess:
	call	KillProcess		;returns ax, bx, cx
	jmp	common

notFirstThread:

	; exiting the process's ui thread ?

	push	ds
	segmov	ds, es				;need core block in ds
	cmp	ax, ds:[PH_uiThread]		;killing UI thread?
	jnz	afterUIThread
	mov	ds:[PH_uiThread], 0		;zero-out reference in 
						;ProcessHeader, as it is waving
						;good-byte at this very moment.
	push	bx
	mov	bx, -2
	call	SubstituteRunningThread		;Find any object resources run
	pop	bx				;by the UI thread & replace
						;their HM_otherInfo field w/-2.
afterUIThread:
	pop	ds


	; not killing first thread -- send thread exit code to process

	mov	bx,ss:[TPD_processHandle]
	mov	cx,ds:[currentThread]
	mov	ax, MSG_PROCESS_NOTIFY_THREAD_EXIT
	jmp	common

notProcess:
	clr	bx				;don't send method

common:
	mov	si, es:[GH_geodeHandle]
	call	UnlockES
EC <	call	NullES							>


	; at this point (ax, bx, cx) hold notification message to send

	push	ax, bx, cx

	mov	bx,ds:[currentThread]
	push	bx				;save current thread

	clr	ax
	xchg	ax,ds:[bx].HT_eventQueue	;remove event queue
	tst	ax
	jz	noQueue
	xchg	ax, bx				;bx <- queue (1-byte inst)
	call	GeodeFreeQueue
noQueue:

	; notify all libraries of our geode of our demise. si is still
	; our owner's handle, and we are free to biff di now.
	
	mov	di, LCT_CLIENT_THREAD_EXIT
	call	GeodeNotifyLibraries


	call	PGeode			; Grab Geode lock and hold it until
					;  we're almost done. This avoids a
					;  nasty race condition when this is
					;  the last thread for a geode and some
					;  other thread is also removing a
					;  reference to the geode
					;  	-- ardeb 3/8/95

	mov	bx, si
	call	FreeGeodeLow		;free the geode associated with this
					;thread -- returns carry set if geode
					;removed
	pushf
	call	FileDeletePathStack	; remove thread's path stack
	call	PThread			;get needed semaphores while we're
	call	PHeap			; still allowed to block
	call	SysLockBIOS
	popf

	mov	si, ss:[TPD_blockHandle] ;si = stack handle
	pop	bx			;recover current thread

	pop	ax, di, es		;(ax, di, es) hold notification message
	pop	cx, dx, bp		;recover exit code, OD

	INT_OFF
	pop	ds:[TPD_dataAX]		;get "data to pass in BP" into a 
					;a safe harbor
	;
	; WARNING!  You are about to enter the twilight zone. Upon return from
	; "SwitchToKernel", you will be executing under an entirely different
	; thread & stack.  This bottleneck-from-hell restricts the data that
	; can be passed from one side to the other to registers only, as 
	; absolutely none of the stack is preserved.   -- Doug 6/9/92
	;
	call	SwitchToKernel		;ds <- idata
	push	ax, di, es		;save notification message
	push	ds:[TPD_dataAX]		;place "data to pass in BP" back on
					;stack
	INT_ON

	; Switch ownership of the heap lock to the kernel thread. Can't just
	; do PHeap on the kernel thread b/c we may not block there

	mov	ds:heapSem.TL_owner, 0
	mov	ds:geodeSem.TL_owner, 0	; ditto for geode lock
	mov	ds:biosLock.TL_owner, 0	; ditto for BIOS lock
	
	inc	ss:[TPD_sharedFSIRLocks]; flag our possession of the shared
					;  FSIR lock grabbed by PHeap

	segmov	es, ds			;make es legal

	pushf				;save carry
	xchg	cx, dx			;dx = exit code, cx = OD high
	mov	al,DEBUG_EXIT_THREAD
	call	FarDebugProcess		;notify debugger of ThreadDestroy
					; now that we're in the kernel thread
					;dx = exit code

					;bx = thread to remove
	call	RemoveThread

	; remove thread's reference to it's ThreadExceptionHandlers block

	mov	es, ds:[si].HM_addr	;es = old ss
	mov	es, es:[TPD_exceptionHandlers]	;es:0 = ThreadExceptionHandlers
	dec	es:[TEH_referenceCount]	;decrement reference count
	jnz	sharedTEH		;jmp if block is used by another thread

	push	bx			;we were the last thread to reference
	mov	bx, es:[TEH_handle]	; this ThreadExceptionHandlers block
	call	MemFree			; so free it
EC <	call	NullES							>
	pop	bx

sharedTEH:
	popf				;recover carry
	jc	removeStack		;if removing the geode then always
					;remove the stack block

	; If geode wasn't removed, see if the stack block is resource 1 for
	; the geode. If it is, we can't free it -- the block will be freed
	; when the geode goes away finally, since we won't be running with
	; ss pointing at it at that time.

	mov	es, ds:[si].HM_addr	;es = old ss
	push	bx
	mov	bx, es:[TPD_processHandle]
	call	NearLockES		; es = geode's core block
	pop	bx
	mov	di, es:[GH_resHandleOff];di = base of resource handle table
	cmp	si, es:[di][2]		;stack handle matches resource 1?
	call	UnlockES
EC <	call	NullES							>
	je	noRemove		;don't biff it then

removeStack:
	xchg	bx,si			;remove stack block,
					;si now = thread/proc that was removed

;	If the geode was an XIP geode, don't free the stack block, as we will
;	want to re-use it if/when the geode is reloaded. If the geode supports
;	discardable dgroups, then discard it.

EC <	call	ECCheckMemHandleFar					>

if	FULL_EXECUTE_IN_PLACE
	cmp	bx, LAST_XIP_RESOURCE_HANDLE				
	ja	freeStack						
	test	ds:[bx].HM_flags, mask HF_DISCARDABLE
	jz	noRemove

	push	dx, bp
	mov	dx, ds:[bx].HM_addr
	call	DoFullDiscard			;Discard the memory, and mark
	pop	dx, bp				; the block as not fixed/not
						; locked (in case it was 
						; allocated pseudo-fixed)
	andnf	ds:[bx].HM_flags, not mask HF_FIXED
	clr	ds:[bx].HM_lockCount
	jmp	noRemove
endif
	
freeStack::

	call	DoFree
noRemove:
	call	VGeode			; can finally, safely remove our lock
					;  on the geode lock

	; send MSG_META_ACK to OD passed
					; cx:bp = OD to send ACK to
					; dx = exit code
					; si = thread/proc removed

	; Shift registers around for MSG_META_ACK to be sent out
	mov	bx, cx
	mov	cx, dx
	mov	dx, si
	mov	si, bp
	pop	bp			; retrieve data to pass in BP
					; bx:si is OD to send ACK to
					; cx = exit code
					; dx = thread/proc removed
					; bp = "data to pas BP" passed in.
TD_swatlab label near		;Used by "showcalls -s"
	ForceRef	TD_swatlab
	mov	ax,MSG_META_ACK		;acknowledge destroy
	call	ObjMessageForceQueue

	mov	dx, cx			; move exit code to dx

	; send notification method (dx = exit code)
	; NOTE:  if this was a process and the parent process is no
	; more, bx is 0.

	pop	ax, bx, cx
					; ax = notification method
					; bx = process to notify (or 0)
					; cx = thread/process
					; dx = exit code
	; make sure the destination is still a process. We can get into
	; problems if all the threads for a process are exiting at
	; once and end up sending to something that no longer has a queue,
	; whereupon we nonchalantly start mucking with idata in random ways.
	; Since we're on the kernel's thread right now, we needn't worry
	; about context switches, so we can just test things...
	; 9/2/90: also have to deal with non-app thread being last one out.
	; In this case, the core block gets freed. In EC, 0xcccc has
	; GA_PROCESS bit set, so death results... -- ardeb

	tst	bx
	jz	notifyComplete
	cmp	bx, handle 0
	jz	notifyComplete

	cmp	bx, ds:[bx].HM_owner	; Still a geode?
	jne	notifyComplete		; Nope -- don't notify

	push	ax
	call	NearLockES
	test	es:[GH_geodeAttr], mask GA_PROCESS	; Still a process?
	call	UnlockES
EC <	call	NullES							>
	pop	ax

	jz	notifyComplete

	mov	di,mask MF_FORCE_QUEUE
	call	ObjMessageNear
notifyComplete:

	call	SysUnlockBIOS
	call	VHeap
	call	VThread

	; check for killing the UI process
	;	bp holds the handle of the thing we just destroyed
	;	either a process or a thread

	cmp	cx, ds:[uiHandleInternal]
	jnz	notUI
	clr	ds:[uiHandleInternal]
	mov	ax, SST_FINAL
	mov	si, -1				; No message, please
	call	SysShutdown			;and never return...
notUI:

if 0
	; if we've removed the last application then exit...

	cmp	ds:[exitFlag],0
	jz	noQuit

	jmp	EndGeos

noQuit:
endif

	jmp	Dispatch

ThreadDestroy	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadAttachToQueue

C DECLARATION:	extern void
			_far _pascal ThreadAttachToQueue(QueueHandle qh,
						ClassStruct _far *class);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADATTACHTOQUEUE	proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax	;bx = han, cx = seg, dx = off

	FALL_THRU	ThreadAttachToQueue

THREADATTACHTOQUEUE	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadAttachToQueue

DESCRIPTION:	Attach to an event queue (block on the queue, receive events
		from it)

CALLED BY:	GLOBAL

PASS:
	bx - handle of event queue to attach to. If 0, caller wants to
		"re-attach" to the thread's current queue. Used mostly
		when a function wants to never return, but needs to still
		field events so its application can detach properly.
	cx:dx - pointer to class to handle events (only used if bx is passed
		as 0)

RETURN:
	never

DESTROYED:
	-

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
ThreadAttachToQueue	proc	far
	tst	bx
	jnz	haveQ
	LoadVarSeg	ds
	mov	bx, ss:[TPD_threadHandle]
	mov	bx, ds:[bx].HT_eventQueue
	tst	bx
	jnz	TATQ_loop
	; If no queue for the thread, just make the thing exit.
	; XXX: this is something of a kludge...
	mov	cx, bx		; exit 
	inc	cx		;  non-zero
	mov	dx, bx		; no one to send ACK to
	mov	bp, bx
	jmp	ThreadDestroy

haveQ:
	mov	ss:[TPD_classPointer].segment,cx
	mov	ss:[TPD_classPointer].offset,dx

AttachToQueueLow label	near
	LoadVarSeg	ds
	mov	ax,ds:[currentThread]
	mov	ds:[bx].HQ_thread,ax		;store associated thread

	; store queue in thread handle

	xchg	ax,bx				;ax=queue, bx=thread
	mov	ds:[bx].HT_eventQueue,ax
	mov	bx,ax

	; bx = queue

TATQ_loop:
	push	bx
	call	QueueGetMessage
	mov	bx, ax
	mov	di, mask MF_CALL		; always perform direct call
	call	MessageDispatch
	pop	bx
	jmp	TATQ_loop

ThreadAttachToQueue	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	Dispatch, DispatchSI

DESCRIPTION:	Dispatch - Dispatch a runnable thread from the run queue
		DispatchSI - dispatch thread SI

CALLED BY:	INTERNAL
		Dispatch - BlockOnLongQueue, StartGEOS, RemoveThread
		DispatchSI - BlockAndRun

PASS (DispatchSI):
	ds - kernel variable segment

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

------------------------------------------------------------------------------@
Dispatch	proc	far
	INT_OFF
	call	SwitchToKernel			;ds <- idata
	INT_ON
	segmov	es, ds

;	Turn off trap flag here, so we don't profile idle loop. If we wake
;	up a thread, the trap flag will be turned back on there if appropriate

SSP <	TRAP_OFF							>

	; SetTimerInterrupt needs the offset of the loop to compute totalCount
	; accurately

DispatchLoop	label	near

	INT_OFF				;exclusive access to run queue
	tst	ds:runQueue		;wait for thread to be runable
	jnz	found
	mov	ds:[idleCalled], 1
	INT_ON

	; call the idle loop code -- this includes the power management driver
	; and anything else that has hooked the idle vector

	call	Idle

	jmp	DispatchLoop

	; runQueue is not empty - run one!

found:

	mov	bx, offset runQueue
	call	RemoveFromQueue

	REAL_FALL_THRU	DispatchSI

Dispatch	endp


DispatchSI	proc	far
EC <	push	ax, bx, es						>
EC <	test	si,15							>
EC <	jz	5$							>
EC <illegalThread:							>
EC <	ERROR	ILLEGAL_THREAD						>
EC <5$:									>
EC <	cmp	si,ds:[loaderVars].KLV_lastHandle			>
EC <	jae	illegalThread						>
EC <	cmp	si, ds:[loaderVars].KLV_handleTableStart		>
EC <	jb	illegalThread						>
EC <	cmp	ds:[si].HT_handleSig, SIG_THREAD			>
EC <	jnz	illegalThread						>
EC <	mov	ax,ds:[si].HT_saveSS		;test for trashed SS	>
EC <	idata segment | global	biosLock:ThreadLock | idata ends	>
EC <	cmp	si, ds:[biosLock].TL_owner	;in DOS?		>
EC <	je	10$				;yes -- don't check	>
EC <	cmp	ax, ds:[loaderVars].KLV_pspSegment ;in DOS or mouse driver?>
EC <	jb	10$							>
EC <	mov	es,ax							>
EC <	mov	bx,es:[TPD_blockHandle]					>
EC <	cmp	ax,ds:[bx].HM_addr					>
EC <	jne	10$				;some cache programs	>
EC <						; switch to their own	>
EC <						; stack spontaneously...>
;EC <	ERROR_NZ	ILLEGAL_THREAD					>
EC <	mov	ax,ds:[bx].HM_size					>
EC <	shl	ax,1							>
EC <	shl	ax,1							>
EC <	shl	ax,1							>
EC <	shl	ax,1							>
EC <	cmp	ax,ds:[si].HT_saveSP					>
EC <	jb	illegalThread						>
EC <	cmp	si, es:[TPD_threadHandle]				>
EC <	ERROR_NE	GASP_CHOKE_WHEEZE				>
EC <10$:								>
EC <	pop	ax, bx, es						>

	inc	ds:[curStats].SS_contextSwitches;update count of switches...

if PROFILE_LOG
	push	bx
	mov 	bx, 0xff			;want to add thread
						;switch entries for
						;all modes. bx <- all
						;ProfileModeFlags
	InsertGenericProfileEntry PET_THREAD_SWITCH, 1, bx, si
	pop	bx
endif
	mov	ds:[currentThread],si
	mov	ds:[threadTimer],TIME_SLICE	;give thread its time slice
	mov	ss,ds:[si][HT_saveSS]		;load stack pointer
	mov	sp,ds:[si][HT_saveSP]

if	FULL_EXECUTE_IN_PLACE

;	Pop the old XIP page off the stack, and map that page in.

	pop	dx
	MapXIPPageInline	dx, TRASH_AX_BX_DX
if	TRACK_INTER_RESOURCE_CALLS
	pop	ds:[curXIPResourceHandle]	; restore resource handle
endif
endif

if UTILITY_MAPPING_WINDOW
	;
	; restore utility mapping window for this thread
	;
	call	UtilWindowRestoreMapping
endif
	
DSI_awake	label	near

	ForceRef DSI_awake		;Swat uses this, prevent a warning

;**********************************************************************
;				WARNING
;
; The application debugger depends on the order in which these registers
; are pushed. DO NOT CHANGE THEM WITHOUT ALSO CHANGING THE DEBUGGER.
; All hell will likely break loose if you do.
;
;**********************************************************************

RecoverFromFullBlock	label	near
if	SUPPORT_32BIT_DATA_REGS
	pop	ebp			;BlockOnLongQueue
else
	pop	bp			;BlockOnLongQueue
endif	; SUPPORT_32BIT_DATA_REGS
RecoverFromPartialBlock label	near	; Jumped to by WakeUpLongQueue
if	SUPPORT_32BIT_DATA_REGS
	pop	gs
	pop	fs
	pop	es

	pop	ecx			;ecx = (orig eax.high).(orig ebx.high)
	ror	ebx, 16
	mov	bx, cx			;bx = orig ebx.high
	rol	ebx, 16			;ebx.high recovered
	ror	ecx, 16			;cx = orig eax.high
	ror	eax, 16
	mov_tr	ax, cx			;ax = orig eax.high
	rol	eax, 16			;eax.high recovered

	pop	edx
else
	pop	es			;recover registers pushed by
	pop	dx
endif	; SUPPORT_32BIT_DATA_REGS

if	SINGLE_STEP_PROFILING

;	Turn on or off the trap flag based on whether single-step profiling
;	is active or not.

	pop	cx			;Get the processor flags in CX
	andnf	cx, not mask CPU_TRAP	;Turn off the trap flag
	LoadVarSeg	ds
	tst	ds:[singleStepping]	;If single stepping is off, branch
	jz	continue		; to leave trap flag off
	ornf	cx, mask CPU_TRAP	;Else, turn on the trap flag
continue:
	push	cx
	tst	ds:[inSingleStep]
	ERROR_NZ	-1
endif
	call	SafePopf		;avoid popf bug in '286
if	SUPPORT_32BIT_DATA_REGS
	pop	ecx
	pop	edi
	pop	esi
	pop	ds
else
	pop	cx
	pop	di
	pop	si
	pop	ds
endif	; SUPPORT_32BIT_DATA_REGS
	retn				;keep running

DispatchSI	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	Idle

DESCRIPTION:	Call any idle loop handlers

CALLED BY:	INTERNAL

PASS:
	ds - kdata

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
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
Idle	proc	far
	uses ax, bx, cx, dx, di, si, bp
	.enter

	; The counter "SS_idleCount" is used to compute system idle time.

	incdw	ds:[curStats].SS_idleCount

	; Call any idle loop handlers set up

	mov	cx, MAX_IDLE_ROUTINES
	mov	di, offset idleRoutineTable

callIdleRoutine:
	tstdw	ds:[di]
	jz	next
	call	{fptr} ds:[di]
next:
	add	di, size fptr
	loop	callIdleRoutine

	; Call the idle loop of the power management driver (if any)

	tst	ds:defaultDrivers.DDT_power
	jz	noPowerDriver

	mov	di, DR_POWER_IDLE
	call	ds:powerStrategy

noPowerDriver:

	.leave
	ret
SwatLabel	Idle_end
Idle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadEnsureThreadHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure BX holds a thread handle, dealing with passing
		of 0 to indicate current thread.

CALLED BY:	INTERNAL (ThreadInfo, ThreadModify
PASS:		bx	= thread handle, or 0 to indicate current thread
RETURN:		bx	= error-checked thread handle
		ds	= idata
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadEnsureThreadHandle proc	near
		.enter
		LoadVarSeg	ds
		tst	bx				;check for current
		jnz	notCurrent
		mov	bx,ds:[currentThread]
	;
	; allow ThreadGetInfo to be called on the scheduler
	; thread, for things that might be called at interrupt
	; time and need to know what thread they're on -- ardeb 3/11/92
	; 
EC <		tst	bx						>
EC <		jz	done						>
notCurrent:
EC <		call	ECCheckThreadHandle				>
EC <done:								>
		.leave
		ret
ThreadEnsureThreadHandle endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadGetInfo

DESCRIPTION:	Return information about a block

CALLED BY:	GLOBAL

PASS:
	ax - ThreadGetInfoType
	bx - handle of thread to get info about or 0 for current thread

RETURN:
	ax - value dependent on ThreadGetInfoType passed
	if bx was passed as 0, bx = handle of current thread

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/91		Initial version

------------------------------------------------------------------------------@
ThreadGetInfo	proc	far	uses si, ds
	.enter
	LoadVarSeg	ds
	mov_trash	si, ax

	call	ThreadEnsureThreadHandle

EC <	cmp	si, size globalThreadGetInfoTable			>
EC <	ERROR_AE	THREAD_GET_INFO_BAD_PARAMETER			>
EC <	test	si, 1							>
EC <	ERROR_NZ	THREAD_GET_INFO_BAD_PARAMETER			>

	call	cs:[globalThreadGetInfoTable][si]

	.leave
	ret

ThreadGetInfo	endp

globalThreadGetInfoTable	nptr.near	\
	TGI_PriorityAndUsage,			;TGIT_PRIORITY_AND_USAGE
	TGI_ThreadHandle,			;TGIT_THREAD_HANDLE
	TGI_QueueHandle,			;TGIT_QUEUE_HANDLE
	TGI_StackSegment			;TGIT_STACK_SEGMENT

;---

TGI_PriorityAndUsage	proc	near
	mov	ax, {word} ds:[bx].HT_basePriority
	ret
TGI_PriorityAndUsage	endp

;---

TGI_ThreadHandle	proc	near
	mov	ax, bx	;Don't change this to a mov_trash, as ThreadGetInfo
	ret		; is defined as returning BX as the thread handle
TGI_ThreadHandle	endp

;---

TGI_QueueHandle		proc	near
	mov	ax, ds:[bx].HT_eventQueue
	ret
TGI_QueueHandle		endp

;---

TGI_StackSegment	proc	near
	call	ThreadFindStack
	ret
TGI_StackSegment	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadModify

DESCRIPTION:	Modify the priority of a thread

CALLED BY:	GLOBAL

PASS:
	bx - handle of thread to modify or 0 to modify current thread
	al - new base priority (if the bit is set to change it)
	ah - ThreadModifyFlags (flags for what to modify)
		TMF_BASE_PRIO - set to modify base priority
		TMF_ZERO_USAGE - set to zero recent CPU usage

RETURN:
	bx - handle of thread modified

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
------------------------------------------------------------------------------@
ThreadModify	proc	far	uses cx, ds
	.enter
	call	ThreadEnsureThreadHandle

	INT_OFF
	mov	cx,word ptr ds:[bx][HT_basePriority]	;load current values
		CheckHack <mask TMF_BASE_PRIO eq 0x80>
	shl	ah,1					;test for changing base
	jnc	noBaseChange
	mov	cl,al					;change base priority
noBaseChange:
		CheckHack <mask TMF_ZERO_USAGE eq 0x40>
	shl	ah,1					;test for zeroing cpu
	jnc	noUsageChange
	clr	ch					;clear recent usage

noUsageChange:
	mov	word ptr ds:[bx][HT_basePriority],cx	;save new values
	add	cl,ch					;compute new real prio
	jnc	storePrio				;check for overflow
	mov	cl, 255					;max out the prio if so

storePrio:
	mov	ds:[bx][HT_curPriority],cl		;and save it

	call	WakeUpRunQueue				;wake up a runable
							;thread if one exists
							;with a higher priority
	INT_ON
	.leave
	ret

ThreadModify	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadInfoQueue

DESCRIPTION:	Returns info about the current dispatch being executed by a
		thread.   If the thread is in the middle of processing a
		method, then the system time when it started doing so is 
		returned.  Used for performance measurement, auto-busy
		state in UI.

CALLED BY:	GLOBAL

PASS:
	ax - segment of stack for thread (Sorry, there is apparently no
	     way to get this from a thread handle)

RETURN:
	ax		- # of events in the queue
	bx		- thread's event queue
	<cx><dx>	- system counter at the time that the last event was
			  dispatched to the thread.
			  This is set to -1 when the thread returns from
			  processing each event, and stored with the system
			  timer after successfully P'ing of a new event from
			  the event queue, but before calling the handler for
			  that event.

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/90		Initial version
------------------------------------------------------------------------------@

if	0	;(AUTO_BUSY)
ThreadInfoQueue	proc	far
	push	ds
	mov	ds, ax
	INT_OFF
						; Fetch system time of last
						; dispatch
	mov	dx, ds:[TPD_dispatchTime].low
	mov	cx, ds:[TPD_dispatchTime].high

	mov	bx, ds:[TPD_threadHandle]	; get thread handle
	LoadVarSeg	ds
						; get queue handle
	mov	bx, ds:[bx].HT_eventQueue
						; & fetch # of events in queue
	mov	ax, ds:[bx].HQ_semaphore.Sem_value
	INT_ON
	pop	ds
	ret

ThreadInfoQueue	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Grab the thread list semaphore

CALLED BY:      INTERNAL
PASS:           nothing
RETURN:         nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        ardeb   5/23/90         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FarPThread        	proc    far
	call	PThread
	ret
FarPThread        	endp

PThread        	proc    near
                push    bx
                mov     bx, offset threadSem
                jmp     SysPSemCommon
PThread        	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                VThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Release the thread list semaphore

CALLED BY:      INTERNAL
PASS:           nothing
RETURN:         nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        ardeb   5/23/90         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FarVThread        	proc    far
	call	VThread
	ret
FarVThread        	endp

VThread        	proc    near
                push    bx
                mov     bx, offset threadSem
                jmp     SysVSemCommon
VThread        	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the thread list with a supplied callback function

CALLED BY:	EXTERNAL
PASS:		ax, cx, dx, bp = initial data to pass to callback
		di:si	= vfar ptr to callback routine
RETURN:		ax, cx, dx, bp = as returned from last call
		carry - set if callback forced early termination of processing.
		bx	= last thread processed if carry set, else 0
DESTROYED:	di, si

PSEUDO CODE/STRATEGY:
		CALLBACK ROUTINE:
			Pass:	bx	= handle of thread to process
				ds	= idata
				ax, cx, dx, bp = data as passed to ThreadProcess
					  or returned from previous callback
			Return:	carry - set to end processing
				ax, cx, dx, bp = data to send on or return
			Can Destroy: di, si, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadProcess	proc	far	uses ds, es
callback	local	fptr.far
		.enter
	;
	; Save the callback's address
	;
		mov	callback.segment, di
		mov	callback.offset, si
	;
	; Snag the thread semaphore for the whole thing.
	;
		call	PThread
	;
	; Point DS at idata for the duration.
	;
		LoadVarSeg	ds
		
		mov	bx, offset threadListPtr - offset HT_next
processLoop:
		mov	bx, ds:[bx].HT_next
		tst	bx		; hit end of list?
		jz	done
	;
	; Since we are in kcode (which is fixed), any passed in fptr
	; for the callback is valid.  Therefore we do not need to
	; call ECAssertValidFarPointerXIP before calling the callback.
	;			-- todd 03/15/94
		call	SysCallCallbackBP
		jnc	processLoop

done:
	;
	; Release thread semaphore now processing is complete. Note: VThread
	; doesn't touch the carry flag or any other register.
	; 
		call	VThread
		.leave
		ret
ThreadProcess	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysAddIdleIntercept

DESCRIPTION:	Add a routine to the list of routines to be called at idle
		time.  The  routine called gets passed nothing, returns
		nothing and should destroy nothing.


CALLED BY:	GLOBAL

PASS:
	dx:ax - routine to add. It will be called:
		PASS:	nothing
		RETURN:	nothing
		DESTROY:	ax, bx, dx, si, bp
		
		i.e. ds, es, cx, and di must be preserved

RETURN:
	carry - set if routine could not be added (table full)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/30/92		Initial version

------------------------------------------------------------------------------@

kinit	segment resource

SysAddIdleIntercept	proc	far	uses cx, si, ds
	.enter

	LoadVarSeg	ds
	mov	cx, MAX_IDLE_ROUTINES
	mov	si, offset idleRoutineTable
	call	SysEnterCritical
searchLoop:
	tstdw	ds:[si]
	jz	found
	add	si, size fptr
	loop	searchLoop

	stc
	jmp	done

found:
	movdw	ds:[si], dxax
	clc
done:
	call	SysExitCritical			;flags preserved
	.leave
	ret

SysAddIdleIntercept	endp

kinit ends


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysRemoveIdleIntercept

DESCRIPTION:	Remove a routine from the list of routines to be called
		at idle time

CALLED BY:	GLOBAL

PASS:
	dx:ax - routine to remove

RETURN:
	carry - set if routine could not be found

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/30/92		Initial version

------------------------------------------------------------------------------@
SysRemoveIdleIntercept	proc	far	uses cx, si, ds
	.enter

	LoadVarSeg	ds
	mov	cx, MAX_IDLE_ROUTINES
	mov	si, offset idleRoutineTable
	call	SysEnterCritical
searchLoop:
	cmpdw	dxax, ds:[si]
	jz	found
	add	si, size fptr
	loop	searchLoop

	stc
	jmp	done

found:
	clr	cx				;clears carry
	clrdw	ds:[si], cx
done:
	call	SysExitCritical			;flags preserved
	.leave
	ret

SysRemoveIdleIntercept	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ThreadBorrowStackSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if there is as much stack space left as is
		needed by the calling routine.  If there isn't, the current
		stack data is saved off into a movable, swappable block, in
		order that the entire stack space may be re-used for the
		upcoming operation.

		May NOT be used whereever data on the stack is needed for the
		upcoming code.


CALLED BY:	EXTERNAL
PASS:		di	- amount of stack space needed, or 0 to just go ahead
			  & do it (i.e. save off the current stack)
RETURN:		di	- "Token" to pass to 
		ss:sp	- if stack space borrowed, this will be changed to
			  point to the top of the stack, so that the entire
			  space may be re-used.  Caller must call
			  ThreadReturnStackSpace before returning or popping
			  anything previously placed on the stack.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	These are the places in the system software that use this mechanism
	As of 10/16/92

*** denotes additions for single threaded apps

KERNEL
------
ObjMetaDispatchEvent		(1000 before dispatching event)
FullLoadNoReload		(300 before calling MemSwapIn)
FullLoadReload			(300 before calling DoReAlloc)
FileSetCurrentPath		(650 before setting path)
PathBuildRegion			(400 before building region)
ObjSendToObjBlockOutput		(700 before sending output)
GCNListAddToList		(500 before sending status message)

UI
--
GenControlNotifyWithDataBlock	(800)
GenOutputAction			(1000 before outputing action)
VisUpdateGeometry		(800 before geometry recalc)
VisSpecBuildBranch		(600 before geometry recalc)
VisSpecBuildUnbranch		(600 before geometry recalc)
VisVupAlterFTVMCExcl		(600 before sending messages upward)
VisUpdateWindowsAndImage	(600 before doing work)
FlowMessageSendToGrab		(600 before sending message)
GenViewCallWithoutLinks		(600 before calling)
GenProcessUndoEndChain		(500)
UserDoDialog			(1000)
VisCompUpdateWinGroup		(800 before doing update)
VisCompRecalcSize		(600 before doing resize)
NotifyEnabledCommon		(700 before doing anything)
VisSpecGupQueryVisParent	(400 before calling parent)
VisCompPosition			(600 before doing work)
GenControlLoadOptions		(500)
GenToolGroupBuildBranch		(600)
VisOpen				(600 if sending visibility notification)
VisRedrawEntireObject		(500)
VisVisVupQuery			(500)
GenProcessUndoFlushActions	(500)

SPECIFIC UI
-----------
OLPaneKbdChar 			(1000 before FUP-ing a MSG_META_KBD_CHAR)
OLApplicationFupKbdChar		(1000 before searching for kbd accel)
ForwardMenuSepQueryToNextSiblingOrParent	(500 before recursion...)
OLCtrlRerecalcSize		(600 before doing work)
OLCtrlPositionBranch		(600 before doing work)
SendTrackScrollingMethod	(800 before sending track scrolling message)
OLFSRescanLow			(1000 before rescan)
OLPaneSendNotification		(600 before sending notification)
OLDisplayWinSendCompleteNotification	(500 before sending notification)
ValidateItem			(700 before sending message)
***SendCompleteUpdateToDC	(800 before sending)
OLMenuWinInteractionCommand	(500 before gup'ing INTERACTION_COMMAND)
OLCtrlBroadcastForDefaultFocus	(500 before recursing)
OLCtrlSendToGenChildren		(400)
CalcDesiredCtrlSize		(500)
OLDisplayWinSpecSetNotUsable	(600)

TEXT
----
TextRecalc			(1000 before calculating)
TextReplace			(1000 before calculating)
VisTextCalcHeight		(1000 before redrawing)
VisTextScreenUpdate		(1000 before redrawing)
TextDraw			(1000 before drawing)
InvertRange			(1000 before inverting)
VisLargeTextHeightNotify	(600 doing sending notification)
TA_SendNotification		(600 doing sending notification)
VisTextReplaceAllOccurrencesInRange	(1000 before doing replace)
VisTextSearch			(1000 before searching)
LargeRegionMakeNextRegion	(1000 before calling to make next region)
VisTextCopy			(1000)
VisTextPaste			(800)
EC: ECCheckRunsElementArray	(600 before doing error checking)

GROBJ
-----
GrObjBodyUpdateUIControllers	(600 before updating)
CONVERT
-------
ConvertOldTextObject		(1000)

GEOWRITE
--------
WriteDocumentWrapNotification	(1000 before dealing with notification)

NIMBUS
------
NimbusGenChar			(400)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/17/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadBorrowStackSpace	proc	far	call
	;
	; If we are using special debugging code, then we want to borrow
	; every single time this is called.
	;
EC <	push	ds						>
EC <	LoadVarSeg	ds					>
EC <	test	ds:[sysECLevel], mask ECF_APP			>
EC <	pop	ds						>
EC <	jz	skipBorrowAlways				>
EC <	clr	di						>
EC <skipBorrowAlways:						>

	tst	di		; just do it?
	jz	maybeBorrow	; yes

	;
	; See if the requested number of bytes are available.
	; 
	add	di, STACK_RESERVED_FOR_INTERRUPTS
	add	di, ss:[TPD_stackBot]
	cmp	sp, di
	jb	maybeBorrow

noBorrow:
	clr	di		; return "extra space not needed"
	ret

maybeBorrow:
	;
	; Don't borrow if running on the scheduler thread, as its stack doesn't
	; follow the rules (the handle table follows the stack, for example,
	; rather than the stack being the last thing in the block).
	; 
	cmp	ss:[TPD_blockHandle], handle dgroup
	jz	noBorrow

TBSS_borrow label near			; needed for "showcalls -S"
	ForceRef	TBSS_borrow

if AUTOMATICALLY_FIXUP_PSELF
	inc	ss:[TPD_stackBorrowCount]
endif

	push	si

	; Get offset to the data on stack we want to save
	;
	mov	si, sp		; get current stack ptr
	add	si, 2+4		; don't need to save return address from this
				; routine, nor si which we just pushed, in
				; the block

				; NOTE!  If you change the stack usage here,
				; you must update the code below which needs
				; to know the # of bytes on the stack at this
				; point in time.
	push	ax, bx, cx, ds, es

	; Get size of the stack block
	;
	LoadVarSeg	ds

EC <	inc	ds:[stackBorrowCount]					>

	mov	bx, ss:[TPD_blockHandle]
	mov	ax, ds:[bx].HM_size	; get size of stack block in paragraphs
	mov	cl, 4			; convert to bytes
	shl	ax, cl
	push	ax			; save size of stack block
EC <	cmp	ax, di							>
EC <	WARNING_B	TRIED_TO_BORROW_AMOUNT_GREATER_THAN_STACK_SIZE	>

	; Get # of bytes to save in ax
	;
	sub	ax, si
	mov	cx, ax			; save # of bytes to save

	; Figure place in block to which we'll start copying. We need it to be
	; the same offset within a paragraph so the StackFooter at the end of
	; the current stack gets copied as the last bytes of the block we're
	; about to allocate. In this calculation, we rely on the paragraph
	; alignment imposed by the heap (if the starting data are above
	; size SavedStackHeader within their paragraph, we don't need to adjust
	; the size in ax, as the heap will round up, leaving us ample room for
	; the SavedStackHeader; if they aren't, we need only add another
	; paragraph to the size. This wastes between 12 and 15 bytes, but I
	; think backtraces are worth it, don't you?)
	; 
	mov	bx, si
	andnf	bx, 0xf			; bx <- starting offset

	cmp	bx, size SavedStackHeader
	ja	allocBlock
	add	ax, 16
	add	bx, 16			; start in 2nd paragraph to avoid
					;  biffing header
allocBlock:
	;
	; Get block to save off stack in
	;
	push	bx			; save starting offset
	push	cx			; save # bytes to copy
	mov	cx, ((mask HAF_LOCK or mask HAF_NO_ERR) shl 8) or \
			mask HF_SWAPABLE
	call	MemAlloc
	mov	es, ax
	clr	di
	pop	cx		; get # of bytes to save
	mov	ax, cx		; store # of bytes we're saving
	stosw
	mov	ax, si		; & where they came from; ax <- sp for setting
				;  SL_savedStackPointer
	stosw

	pop	di		; di <- starting offset
	push	di		; save for storing in SL_savedStackPointer

	;
	; Save off stack data
	;
	segmov	ds, ss
	shr	cx, 1
	rep	movsw		; Save 'em out.
	jnc	noCopy
	movsb
noCopy:

	call	NearUnlock	; allow saved stack data block to move
				; around heap

	segmov	es, ss
	pop	ax		; ax <- starting offset of data in block
	pop	di		; get ptr past end of stack

	mov	si, sp		; get ptr to saved regs, return address
	mov	cx, 6*2+4	; # of bytes on stack at this point, through
				; the return address
	sub	di, cx
	sub	di, size StackFooter

	push	di		; save what will be new stack ptr
copyFrame::	
	;
	; One interesting thing... Since the stack frame we are copying falls
	; below the destination frame on the stack, it is possible for the
	; two of them to overlap (only in extreme cases, like with EC code).
	;
	; The result is total havoc. The best way to avoid this is to copy
	; the bytes in reverse order.
	;
	add	si, cx		; ds:si <- ptr past end of source
	dec	si

	add	di, cx		; es:di <- ptr past end of dest
	dec	di
	std			; Copy down

	;
	; es:di	= Pointer to place to start storing data
	; bx	= Block handle
	; ax	= Starting offset of data in the block
	;
	mov	{word} es:[di+1].SL_savedStackBlock, bx
				; store handle of data block holding 
				; continuation of stack (to allow Swat
				; to do backtraces)
	mov	{word} es:[di+1].SL_savedStackPointer, ax

	;
	; ds:si	= Pointer to end of source buffer
	; es:di = Pointer to end of dest buffer
	; cx	= Number of bytes to copy
	; direction flag set to copy backwards
	;
	rep	movsb		; copy to top of stack
	cld			; Copy forward now


	mov	di, bx		; return block handle in di
	pop	sp		; adjust stack ptr to top
;-----------------------------------------------------------------------------
initStackSpace::
	;
	; Initialize the space between the bottom of the stack and the
	; stack pointer so that we won't reuse data on our current stack
	; where the data is actually below the stack pointer.
	;
EC <	push	ds						>
EC <	LoadVarSeg	ds					>
EC <	test	ds:[sysECLevel], mask ECF_APP			>
EC <	pop	ds						>
EC <	jz	done						>

EC <	push	di				; Save return value	>

	;
	; Figure the start and end of the area to clear
	;
EC <	segmov	es, ss, ax			; es <- stack segment	>
EC <	mov	di, ss:[TPD_stackBot]		; es:di <- start of area>
EC <	mov	cx, sp				; cx <- end of area to clear>
	
	;
	; Initialize that hunk of space
	;
EC <	sub	cx, di				; cx <- # of bytes to clear>
EC <	clr	al				; al <- byte to store	>
EC <	rep	stosb				; Fill it in		>

EC <	pop	di				; Restore return value	>
done::
;-----------------------------------------------------------------------------

	pop	ax, bx, cx, ds, es

	pop	si
	ret
ThreadBorrowStackSpace	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ThreadBorrowStackDSDX

DESCRIPTION:	Borrow stack space and keep ds:dx pointing at the correct place

CALLED BY:	EXTERNAL

PASS:
	di - threshhold
	ds:dx - buffer

RETURN:
	ds, dx - possibly moved, but pointing to the same thing
	di - token

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/ 6/92	Initial version

------------------------------------------------------------------------------@
ThreadBorrowStackDSDX	proc	far


	; We need to ensure that we have enough stack space, but it is possible
	; that the passed path is on the stack.  To make things work we must
	; adjust ds:dx if the stack is moved

	call	ThreadBorrowStackSpace

	tst	di
	jz	noNewStack			;if no borrow then done

	push	ax, si, bx 			;preserve me, please. I hold
						;important information in
						;some contexts...

	mov	si, ds				;si <- passed DS, for comparison
						; (we're about to nuke it)

	; Lock down the copied data so we can get at our return address.

	mov	bx, di
	call	NearLockDS

	; ds:bx <- the stack data in the other block, after our return address

	mov	bx, sp
	mov	ax, ss:[bx+6].SL_savedStackPointer
	add	ax, 4

	mov	ss:[bx+6].SL_savedStackPointer, ax; discard our return
	add	ds:[SSH_sp], 4			  ;  address from the saved
						  ;  data
	sub	ds:[SSH_size], 4
	mov_tr	bx, ax				; ds:bx <- old data

	; see if the buffer was actually on the stack in the first place. if
	; the saved DS (in SI) matches the current SS, it was in the same
	; block.

	mov	ax, ss
	cmp	ax, si
	jne	restoreDS			;=> ds:dx not on stack, but
						; we still need our return
						; address

	; see if the buffer was below the old stack pointer (stored in
	; SSH_sp in the header at the start of the block)

	cmp	dx, ds:[SSH_sp]
	jb	restoreDS			;=> not actually in the data,
						; so we need to get the old
						; DS back again

	; the buffer was in the old data -- arrange for DS to point to the
	; old data on return (which we, yech, just leave locked; it will be
	; effectively unlocked when the old block is freed by
	; ThreadReturnStackSpace) and adjust DX to point to the data in the
	; block

	push	ds				;return this in DS
	sub	dx, ds:[SSH_sp]			;dx <- offset from old SP
	add	dx, bx				;dx <- offset within other block

	clc					;signal block is to remain
						; locked
recoverReturnAddress:

	; need to recover our return address from the borrowed block. Current
	; state:
	; 	CF	= set to unlock the other block
	; 	ds:bx	= start of old stack data, not including our return
	;		  address
	; 	ss:sp ->	DS to return
	; 			BX to return
	; 			SI to return
	;			AX to return

	mov	ax, ds:[bx-4].segment		;fetch the return address
	mov	si, ds:[bx-4].offset

	mov	bx, sp
	xchg	ax, ss:[bx+4].segment		;ax <- passed ax, store ret seg
	xchg	si, ss:[bx+4].offset		;si <- passed si, store ret off
	jnc	recoverBX			;=> leave locked

	mov	bx, di
	call	NearUnlock

recoverBX:
	pop	ds
	pop	bx

noNewStack:
	ret

restoreDS:
	; return DS to its former glory by pushing the value saved in SI to be
	; popped at recoverBX. 
	push	si
	stc					;signal to unlock the block
	jmp	recoverReturnAddress
ThreadBorrowStackDSDX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ThreadReturnStackSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restores stack to where it was before ThreadBorrowStackSpace
		was called.

CALLED BY:	EXTERNAL
PASS:		di	- "Token" returned from ThreadBorrowStackSpace
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/17/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadReturnStackSpace	proc	far	call
	pushf
	tst	di
	jnz	return
	popf
	ret

return:
	push	ax, bx, cx, si, ds, es
	mov	si, sp
	mov	cx, size word *7 + size fptr
				; # of bytes on stack at this point, through
				; return address

	mov	bx, di
	call	NearLockDS

	mov	di, ds:[SSH_sp]	; ss:di is where we'll put data back
	sub	di, cx		; back up to where we'll move ss:sp to 
	mov	sp, di		; set new SP before move of saved registers
				;  so incoming interrupts don't have a chance
				;  in hell of nuking the data.
	push	ax		; save segment of data block

	mov	ax, ss
	mov	ds, ax
	mov	es, ax
	rep	movsb		; move down stuff on stack & return address

	pop	ds		; get segment of data block back
				; get location to set sp back to after move

	;
	; Now copy the data from the saved block back onto the stack.
	; es:di is what sp was when ThreadBorrowStackSpace was called. ss:si
	; points just after our return address, which should be the StackFooter
	; we created in ThreadBorrowStackSpace, and from which we obtain the
	; start of the data to copy from the block.
	; 
EC <	cmp	bx, ss:[si].SL_savedStackBlock				>
EC <	ERROR_NE	SOMETHING_LEFT_ON_STACK_BEFORE_STACK_SPACE_RETURN>
	mov	si, ss:[si].SL_savedStackPointer
EC <	cmp	di, ds:[SSH_sp]						>
EC <	ERROR_NE	GASP_CHOKE_WHEEZE				>
	mov	cx, ds:[SSH_size]	; get # of bytes to restore
	rep	movsb

	call	NearFree		; Nuke the save block

if AUTOMATICALLY_FIXUP_PSELF
	dec	ss:[TPD_stackBorrowCount]
	call	ThreadFixupPSelf
endif

	pop	ax, bx, cx, si, ds, es
	popf
	ret

ThreadReturnStackSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadFixupPSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup pself

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The cmessageFrame is expected to be setup like this:

		masterOffset	<-> cmessageFrame
		pself		<-> cmessageFrame-4
		oself		<-> cmessageFrame-8

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if AUTOMATICALLY_FIXUP_PSELF

ThreadFixupPSelf	proc	near
	tst	ss:[TPD_cmessageFrame]		; do we have a cmessageFrame?
	jz	done				; exit if not

	tst	ss:[TPD_stackBorrowCount]	; have we borrowed stack space?
	jnz	done				; exit if so

	uses	bx, si, bp, ds
	.enter

	mov	bp, ss:[TPD_cmessageFrame]	; bp = cmessageFrame
	movdw	bxsi, ss:[bp-8]			; ^lbx:si = object
	call	MemDerefDS			; *ds:si = object instance data
EC <	call	ECCheckLMemObject		; ensure lmem object	>
	mov	si, ds:[si]			; ds:si = object instance data
	mov	bx, ss:[bp]			; bx = masterOffset
	tst	bx				; masterOffset ?= 0
	jz	update				; skip if no masterOffset
	add	si, ds:[si][bx]			; ds:si = masterClass instance
update:
	movdw	ss:[bp-4], dssi			; update pself

	.leave
done:
	ret
ThreadFixupPSelf	endp

endif
