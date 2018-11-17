COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Thread
FILE:		threadC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: threadC.asm,v 1.1 97/04/05 01:15:20 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadAllocSem

C DECLARATION:	extern SemaphoreHandle
			_far _pascal ThreadAllocSem(word value);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADALLOCSEM	proc	far
	C_GetOneWordArg	bx,   cx,dx	;bx = value
	call	ThreadAllocSem
	mov_trash	ax, bx
	ret

THREADALLOCSEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadAllocThreadLock

C DECLARATION:	extern SemaphoreHandle
			_far _pascal ThreadAllocThreadLock();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADALLOCTHREADLOCK	proc	far
	call	ThreadAllocThreadLock
	mov_trash	ax, bx
	ret

THREADALLOCTHREADLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadFreeSem

C DECLARATION:	extern void
			_far _pascal ThreadFreeSem(SemaphoreHandle sem);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADFREESEM	proc	far
	C_GetOneWordArg	bx,   cx,dx	;bx = han
	GOTO	ThreadFreeSem

THREADFREESEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadGetInfo

C DECLARATION:	extern word
			_far _pascal ThreadGetInfo(ThreadHandle th,
						ThreadGetInfoType info);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADGETINFO	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = info

	GOTO	ThreadGetInfo

THREADGETINFO	endp

C_Common	ends

;---

kcode	segment	resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadDestroy

C DECLARATION:	extern void
			ThreadDestroy(word errorCode,
				optr ackODHan,
				word ackData);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADDESTROY	proc	far

	; nuke return address (we will not need it)

	pop	ax
	pop	cx

if	ERROR_CHECK
	;
	; Warn if we are called from movable resource.
	;
	call	SegmentToHandle		;cx = hptr
	mov	bx, cx
	LoadVarSeg	ds
	test	ds:[bx].HM_flags, mask HF_FIXED
	jnz	ok
	cmp	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	WARNING_NE THREAD_DESTROY_CALLED_FROM_MOVABLE_RESOURCE
ok:
endif	; ERROR_CHECK

	pop	si			;ackData

	pop	bp			;ackOD.chunk
	pop	dx			;ackOD.handle

	pop	cx			;exit code
	jmp	ThreadDestroy

THREADDESTROY	endp

kcode	ends

C_System	segment	resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadCreate

C DECLARATION:	extern ThreadHandle
		    _far _pascal ThreadCreate(word priority, word valueToPass,
					void _far (*startRoutine)(),
					word stackSize, GeodeHandle owner);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	We do something rather gross here, in order to call the start routine
	with the standard C calling convention (passing valueToPass as the
	first and only argument to the routine):
		* call ThreadCreate passing our own callback routine. This
		  creates a Semaphore with both words of zero just below
		  TPD_stackBot for the new thread.
		* we then block on the first of the two words (treating it as
		  a thread queue..).
		* our callback wakes us up and blocks on the other word.
		* we change the registers of the new thread to be the
		  appropriate arguments we've got (dx:bp = real start; it
		  already receives valueToPass in cx)
		* we wake up the other thread
		* the callback frees the two words at TPD_stackBot and
		  calls the startRoutine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADCREATE_OLD	proc	far
	; Original version destroyed SI
	REAL_FALL_THRU THREADCREATE
THREADCREATE_OLD	endp

THREADCREATE	proc	far	priority:word, valueToPass:word,
				startRoutine:fptr.far, stackSize:word,
				owner:hptr
					uses di, bp, ds, es, si
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, startRoutine				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	ax, priority
	mov	bx, valueToPass
	
	mov	cx, segment _THREADCREATE_callback
	mov	dx, offset _THREADCREATE_callback
	mov	di, stackSize
	push	bp
	mov	bp, owner
	call	ThreadCreate
	pop	bp
	jc	error

	;
	; Now wait for the new thread to get to the appropriate point in
	; our callback routine.
	;
	push	bx
	LoadVarSeg	ds, ax
	call	ThreadFindStack		; use ThreadFindStack to deal with the
					;  thread possibly being in DOS while
					;  it's notifying its various libraries
					;  of its creation.
	mov	es, ax			; ax:bx <- queue on which to wait
	mov	bx, size ThreadPrivateData 
	call	ThreadBlockOnQueue
	;
	; Change its registers to contain the values from our stack frame.
	;
	pop	bx
	push	bx
	mov	bx, ds:[bx].HT_saveSP
	mov	ax, ss:[startRoutine].segment
	mov	es:[bx].TBS_dx, ax
	mov	ax, ss:[startRoutine].offset
	mov	es:[bx].TBS_bp, ax
	;
	; Now wake it up again so it can continue on its merry way.
	; 
	mov	ax, es
	mov	bx, (size ThreadPrivateData) + 2
	call	ThreadWakeUpQueue
	;
	; Return the handle of the new thread in AX
	; 
	pop	ax
	mov	ss:[TPD_error], 0
done:
	.leave
	ret
error:
	mov	ss:[TPD_error], ERROR_INSUFFICIENT_MEMORY
	clr	ax
	jmp	done
THREADCREATE	endp

kcode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_THREADCREATE_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for THREADCREATE

CALLED BY:	THREADCREATE via ThreadCreate
PASS:		ds = es = thread's dgroup
		cx	= valueToPass
RETURN:		never
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_THREADCREATE_callback proc	far
	;
	; Wake up the calling thread so it can tell us what routine to call.
	; 
		mov	ax, ss
		mov	bx, size ThreadPrivateData
		call	ThreadWakeUpQueue
	;
	; Now wait for it to tell us; ThreadWakeUpQueue biffs ax & bx, so we
	; must reload them...
	; 
		mov	ax, ss
		mov	bx, (size ThreadPrivateData) + 2
		call	ThreadBlockOnQueue
	;
	; Clear "semaphore" (i.e. the two thread queues) off the base of the
	; stack -- necessary synchronization is now complete.
	; 
	; This can't be done, really, since the stackBot might have changed
	; (e.g. ProcCallFixedOrMovable_cdecl stores its return address in a
	; FOMFrame structure at the bottom of the stack).  The two thread
	; queues will have to remain.
	; j- 11/8/95
	;
;;		sub	ss:[TPD_stackBot], 4
	;
	; cx = valueToPass
	; dx:bp = routine to call.
	; 
		push	cx
		mov	bx, dx
		mov	ax, bp
		call	ProcCallFixedOrMovable
	;
	; If that returned, we need to exit the thread. Do so.
	; 
		clr	dx, bp, si
		mov_tr	cx, ax			; cx <- return value
		jmp	ThreadDestroy
_THREADCREATE_callback endp

kcode	ends

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadModify

C DECLARATION:	extern void
			_far _pascal ThreadModify(ThreadHandle th,
					word newBasePriority, word flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADMODIFY	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = han, ax = prio, cx = fl

	mov	ah, cl				;ah = flags
	GOTO	ThreadModify

THREADMODIFY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadPrivAlloc

C DECLARATION:	extern word
			_far  _pascal ThreadPrivAlloc(word wordsRequested,
							GeodeHandle owner);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADPRIVALLOC	proc	far
	C_GetTwoWordArgs	cx, bx,   ax,dx	;cx = count, bx = owner

	call	ThreadPrivAlloc
	mov_trash	ax, bx
	jnc	noError
	clr	ax
noError:
	ret

THREADPRIVALLOC	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadPrivFree

C DECLARATION:	extern void
			_far _pascal ThreadPrivFree(word range,
							word wordsRequested);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADPRIVFREE	proc	far
	C_GetTwoWordArgs	bx, cx,   ax,dx	;bx = range, cx = count

	call	ThreadPrivFree
	ret

THREADPRIVFREE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThreadHandleException

C DECLARATION:	extern void
		    _far _pascal ThreadHandleException(ThreadHandle th,
					ThreadException exception,
					void _far (*handler)());

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
THREADHANDLEEXCEPTION	proc	far	th:hptr, exception:ThreadException,
					handler:fptr.far
	.enter

	mov	ax, exception
	mov	bx, th
	mov	cx, handler.segment
	mov	dx, handler.offset
	call	ThreadHandleException

	.leave
	ret

THREADHANDLEEXCEPTION	endp

C_System	ends

	SetDefaultConvention
