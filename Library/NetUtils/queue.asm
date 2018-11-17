COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Serial/IR Communication Protocol
MODULE:		Utils
FILE:		queue.asm

AUTHOR:		Steve Jang, Mar 22, 1994

ROUTINES:
	Name			Description
	----			-----------
	QueueLMemCreate		createa a queue in LMem
	QueueLMemDestroy	destroys a queue in LMem

	QueueMarkAsDead		marks a queue as dead. after this operation,
				enqueueLock or dequeueLock will return
				QE_DEAD error.

	QueueEnqueueLock	returns a fptr to the memory portion to be
				enqueued in 'EnqueueUnlock' operation.
	QueueEnqueueUnlock	enqueues memory portion returned by

	QueueAbortEnqueue	Aborts enqueue operation when called after
				EnqueueLock and before EnqueueUnlock.

	QueueDequeueLock	returns a fptr to front entry of a queue.
	QueueDequeueUnlock	dequeues one element from queue.

	QueueAbortDequeue	Aborts dequeue operation when called after
				DequeueLock and before DequeuEnd.

	QueueEnum		Traverse the queue and do enum function

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/22/94   	Initial revision


DESCRIPTION:
	Queue mechanism to be used in NetLib and HDLC driver.
		
	$Id: queue.asm,v 1.1 97/04/05 01:25:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QueueCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueLMemCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a queue in LMem heap.

CALLED BY:	GLOBAL
PASS:		ax	= entry size
		bx	= LMem heap in which to create queue
		cl	= queue initial length
		dx	= queue max length
RETURN:		^lbx:cx	= queue( optr )
		carry set if allocation fails
DESTROYED:	ax
SIDE EFFECTS:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueLMemCreate	proc	far

		queueInitLength		local	word
		queueMaxLength		local	word
		queueEltSize		local	word
		
		uses	dx, ds, di
		.enter
		push	bx
EC <		call	ECCheckLMemHandle				>
EC <		call	ECValidateQueueCreateParams			>
		tst	cl
		jnz	cont
		mov	cl, 2
		add	dx, 2
cont:
		clr	ch
		mov	queueInitLength, cx
		mov	queueMaxLength, dx
		mov	queueEltSize, ax
	;
	; Compute memory amount required by the queue
	;
		mul	cl				; ax = entry size
							;      * queue len
		add	ax, size QueueStruct		; ignore last byte
		mov_tr	dx, ax				; store Q mem amount
	;
	; Allocate memory chunk for queue in LMem Heap
	; now, ax = amount of memory to allocate
	;      bx = LMem heap handle
	;
		call	MemLockExcl			;-> ax = seg addr
		mov	ds, ax				; ds = seg addr
		mov	cx, dx				; cx = Q mem amount
		call	LMemAlloc			;-> ax = chunk handle
		jc	error				;   ds = new seg addr
		mov	di, ax
		mov	di, ds:[di]			; ds:di = fptr to queue
	;
	; Initialize queue
	;
		mov	ds:[di].QS_totalSize, dx	; store total buff size
		segmov	ds:[di].QS_initLength, queueInitLength, dx
		segmov	ds:[di].QS_curLength, dx
		segmov	ds:[di].QS_maxLength, queueMaxLength, dx
		segmov	ds:[di].QS_eltSize, queueEltSize, dx
		mov	ds:[di].QS_front, offset QS_buffer
		mov	ds:[di].QS_end, offset QS_buffer
		mov	ds:[di].QS_state, CQS_ALIVE
		clr	ds:[di].QS_numEnqueued
	;
	; make ^lbx:cx = optr for new queue
	;
		mov_tr	cx, ax
	;
	; Allocate synchronization semaphore
	;
		mov	bx, 1				; semaphore value
		call	ThreadAllocSem			;-> bx = sem handle
		mov	ds:[di].QS_syncSem, bx
		mov	ax, handle 0
		call	HandleModifyOwner
	;
	; Allocate blocking semaphores
	;
		mov	bx, queueInitLength		; bx = queue length
		call	ThreadAllocSem			;-> bx = sem handle
		mov	ds:[di].QS_enqueueSem, bx
		mov	ax, handle 0
		call	HandleModifyOwner
		
		clr	bx				; queue is empty
		call	ThreadAllocSem			;-> bx = sem handle
		mov	ds:[di].QS_dequeueSem, bx
		mov	ax, handle 0
		call	HandleModifyOwner
error:
		pop	bx
		call	MemUnlockExcl		
		.leave
		ret
		
QueueLMemCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueLMemDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys a queue.  All the contents are also destoyed.

CALLED BY:	GLOBAL
PASS:		^lbx:cx	= optr to queue
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	1. Wait until queue is vacant( not being used )
	2. Set QS_state = CQS_SHUTTING_DOWN
	3. V all the threads waiting to enqueue or dequeue
	4. deallocate queue		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueLMemDestroy	proc	far
		uses	ax,ds,si
		.enter
	;
	; Lock the MemBlock and find out whether this is a HugeLMem queue or
	; LMem queue.
	;
		call	QueueDestroyQueueSemaphores	
		call	MemLockExcl		;-> ax = seg addr
		mov	ds, ax			; ds = segment address
		mov_tr	ax, cx			; ax = chunk handle
EC <		ECCheckLMemChunkDSAX					>
		call	LMemFree		;-> nothing changed
		call	MemUnlockExcl		;-> nothing changed
		.leave
		ret
QueueLMemDestroy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueDestroyQueueSemaphores
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deallocates enqueue/dequeue semaphores in a queue

CALLED BY:	Queue(Huge)LMemDestroy, QueueResize
PASS:		^lbx:cx	= queue
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueDestroyQueueSemaphores	proc	near
		uses	ax,bx,ds,si
		.enter
	;
	; Lock the queue
	;
		push	bx
		call	MemLockExcl
		mov	ds, ax
		mov	si, cx
		mov	si, ds:[si]
		mov	bx, ds:[si].QS_syncSem
		call	ThreadFreeSem
		mov	bx, ds:[si].QS_enqueueSem
		call	ThreadFreeSem
		mov	bx, ds:[si].QS_dequeueSem
		call	ThreadFreeSem
		pop	bx
		call	MemUnlockExcl
		
		.leave
		ret
QueueDestroyQueueSemaphores	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueMarkAsDead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wake up all the threads that are blocking for some reason
		concerning this queue.  Any thread that accesses this queue
		in the future will get QE_DEAD error.

CALLED BY:	QueueHugeLMemDestroy, QueueLMemDestroy
PASS:		^lbx:si	= queue to mark as dead
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	1. P queue's sync semaphore
	2. Set QS_state = CQS_DEAD
	3. V queue's sync semaphore
	4. V queue's enqueue/dequeue semaphore
	   ( this will cause chain reaction of V's, waking up all the threads
	     blocking on the semaphores )

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueMarkAsDead	proc	far
		uses	ax,bx,di,si,ds
		.enter
	;
	; Lock the queue
	;
		push	bx
		call	MemLockShared
		mov	ds, ax
		
EC <		call	ECValidateQueueDSSI				>
		mov	si, ds:[si]		; ds:si = queue

	;
	; Change queue state to shutting down: this causes chain reaction of
	; 			V syncSem, waking up everybody who's queued up
	;
		mov	bx, ds:[si].QS_syncSem
		call	ThreadPSem
		mov	di, ds:[si].QS_state		; record current state
		mov	ds:[si].QS_state, CQS_DEAD
		call	ThreadVSem
	;
	; Wake up all the threads that are blocked because the queue
	; was either full or empty
	;
		mov	bx, ds:[si].QS_enqueueSem
		call	ThreadVSem
		
		mov	bx, ds:[si].QS_dequeueSem
		call	ThreadVSem
	;
	; After this no thread will block on any of enqueue/dequeue semaphores
	;
		pop	bx
		call	MemUnlockShared
		
		.leave
		ret

QueueMarkAsDead	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueEnqueueLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a fptr to the portion of memory to be enqueued in
		EnqueueUnlock operation.  If queue is full, wait cx ticks for
		dequeue operation which will free up some space in the queue.

		(!) after copying information to be enqueued into this portion
		    of memory, one must call 'QueueEnqueueUnlock' in order to
		    actually enqueue that portion of memory into queue.

CALLED BY:	GLOBAL

PASS:		^lbx:si	= queue
		cx	= time out value range: 0x0010-0xfff0
			  [ 0x0000-0x000f, 0xfff1-0xffff reserved ]

			  NO_WAIT for no waiting
			  RESIZE_QUEUE for resizing if more space is needed.
			  But if the queue size becomes bigger than the max
			  size specified in QueueCreate, returns QE_TOO_BIG.
			  FOREVER_WAIT for waiting forever

RETURN:		ds:di	= new element to be enqueued
		cx	= size of entry
		if CF is set, cx = error message
			either QE_TIMEOUT or QE_SHUTTING_DOWN

DESTROYED:	ds
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	1. (QS_front = QS_end) and (QF_full = 1)[queue is full]?
		block until 'dequeue' operation or 'timeout'
	2. if no_error,
		di = QS_end

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueEnqueueLock		proc	far
		queueHandle	local	hptr
		uses	ax,bx,dx,si
		.enter
	;
	; Lock the queue
	;
		mov	queueHandle, bx
		call	MemLockShared
		mov	ds, ax
		
		mov	di, si				; *ds:di = queue
		mov	si, ds:[si]			; ds:si = queue(fptr)
	;
	; P enqueue semaphore to determine whether queue is full
	; : if enqueueSem.value = 0, block until timeout or dequeue operation
	;
waitForDequeue:
		mov	dx, ds:[si].QS_enqueueSem
		mov	bx, queueHandle
		call	MemUnlockShared
		
		mov_tr	bx, dx				;;;; block until
		call	ThreadPTimedSem			;;;; room is available
		mov_tr	dx, ax
		
		mov	bx, queueHandle
		call	MemLockShared			; re-dereference fptr
		mov	ds, ax				; to the queue
		mov	si, ds:[di]
		
		cmp	dx, SE_TIMEOUT
		je	timeOut				; timeout! = error
EC <		call	ECValidateQueueDSSIptr				>
	;
	; Queue is not full; get memory portion to be enqueued
	; P sync semaphore: critical section begins here
	;
		mov	bx, ds:[si].QS_syncSem		;
		call	ThreadPSem			;-> ax= semaphore error
		
		mov	di, ds:[si].QS_end		; di = offset within Q
		add	di, si				;    + offset within
							;      memory segment
		cmp	ds:[si].QS_state, CQS_DEAD
		je	deadError
		mov	cx, ds:[si].QS_eltSize
		clc
finish:
		jnc	done				; if no error leave the
		mov	bx, queueHandle			; queue locked
		call	MemUnlockShared
done:
	;
	; at this point:
	;	ds:di = fptr to new entry
	;	sync semaphore is P'ed
	;     OR
	; queue error
	;
		.leave
		ret
deadError:
	;
	; wake up the next person waiting
	;
		mov	bx, ds:[si].QS_syncSem
		call	ThreadVSem			; V syncSem
		mov	bx, ds:[si].QS_enqueueSem	; V enqueue sem( no one
		call	ThreadVSem			;   will ever block)
		mov	cx, QE_DEAD
		stc
		jmp	finish
timeOut:
	;
	; error means: queue is full
	;
		cmp	cx, FOREVER_WAIT		; forever wait?
		je	waitForDequeue			;
	;
	; check for resize
	;
		cmp	cx, RESIZE_QUEUE
		jne	conti
		call	MemUpgradeSharedLock
		call	QueueStretchQueue
		call	MemDowngradeExclLock
LONG		jnc	waitForDequeue
		mov	cx, QE_TOO_BIG
		jmp	finish
conti:
		mov	cx, QE_TIMEOUT
		stc
		jmp	finish
		
QueueEnqueueLock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueStretchQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stretch the buffer of a queue to double size
		(!) ds:si may have both changed on return

CALLED BY:	QueueEnqueueLock
PASS:		*ds:di = queue
		ds:si  = queue(fptr)
RETURN:		carry set if error
		ds:si  = adjusted for new resized queue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueStretchQueue	proc	near
		uses	ax, bx, cx, es, di
		.enter

EC <		WARNING	WARNING_STRETCHING_QUEUE			>
	;
	; P sync semaphore so that there can't be more than 1 thread executing
	; this routine.
	;
		mov	bx, ds:[si].QS_syncSem
		call	ThreadPSem
	;
	; Decide whether to resize the queue
	; Rules: 1) there should be no more room in circular buffer
	;	 2) current queue size * 2 < max queue size
	;
		mov	ax, ds:[si].QS_curLength
		cmp	ax, ds:[si].QS_numEnqueued
		ja	finish
		shl	ax, 1
		cmp	ds:[si].QS_maxLength, ax
		jb	finish				; carry set
	;
	; Resize the chunk
	;
		mov	cx, ds:[si].QS_totalSize	; cx = 2 * old size
		shl	cx, 1
		sub	cx, size QueueStruct
		mov	ax, di				; ax = chunk handle
		call	LMemReAlloc			; ds, es might have
		jc	finish				; changed
	;
	; Move enqueued Entries
	;
		mov	si, ds:[di]			; ds:si = stretched
							;         queue
		mov	cx, ds:[si].QS_front		;
		sub	cx, offset QS_buffer		; cx = bytes to move
		
		push	si				;
		segmov	es, ds, di			;
		mov	di, si				; es:di = beginning of
		add	di, ds:[si].QS_totalSize	;         added space
		add	si, offset QS_buffer		; ds:si = beginning of
		rep	movsb				;         circular buff
	;
	; adjust end pointer/ front pointer remains the same
	;
		pop	si				; ds:si = fptr queue
		sub	di, si				;
		mov	ds:[si].QS_end, di		; di = queue end
	;
	; adjust enqueue semaphore
	;
		mov	cx, ds:[si].QS_curLength	; queue = twice longer
		mov	bx, ds:[si].QS_enqueueSem	;
vEnqueueSem:
		call	ThreadVSem			; sem.value++
		loop	vEnqueueSem
	;
	; Adjust other queue variables
	;
		mov	ax, ds:[si].QS_curLength	;
		shl	ax, 1				;
		mov	ds:[si].QS_curLength, ax	; curLen = curLen * 2
		mov	ax, ds:[si].QS_totalSize	; cx = 2 * old size
		shl	ax, 1
		sub	ax, size QueueStruct
		mov	ds:[si].QS_totalSize, ax	; QS_totalSize = ax
finish:
		mov	bx, ds:[si].QS_syncSem
		call	ThreadVSem
		.leave
		ret
QueueStretchQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueEnqueueUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enqueues a new element to queue.  New element is the memory
		portion returned by QueueEnqueueLock.  If Queue is full at
		this time, return error.

CALLED BY:	GLOBAL
PASS:		*ds:si	= queue
RETURN:		nothing
DESTROYED:	nothing ( flags preserved )
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	1. QS_end = QS_end + QS_eltSize
	   if QS_end = QS_totalSize, then QS_end = offset QS_buffer
	2. There should be no error except when the user chooses to EnqueueUnlock
	   without EnqueueLock.  EC version catches that.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueEnqueueUnlock	proc	far
		uses	ax,bx,si
		.enter
EC <		call	ECValidateQueueDSSI				>
EC <		call	ECCheckLegalEndOperation			>
		pushf
		mov	si, ds:[si]			; ds:si = queue(fptr)
	;
	; Queue should never be full at this point; enqueue entry now
	;
		mov	ax, ds:[si].QS_end		;
		add	ax, ds:[si].QS_eltSize		; QS_end += QS_eltSize
		cmp	ax, ds:[si].QS_totalSize	; if end = totalSize
		jae	wrapAround			; then wrap around
continueEnqueue:
		mov	ds:[si].QS_end, ax
	;
	; Changes introduced by dynamic resizing queue
	;
		inc	ds:[si].QS_numEnqueued
	;
	; V dequeue/sync semaphores
	;
		mov	bx, ds:[si].QS_syncSem		; C.S. ends here
		call	ThreadVSem			;
		mov	bx, ds:[si].QS_dequeueSem	; one more entry for
		call	ThreadVSem			; dequeue operation
	;
	; Unlock the queue
	;
		mov	bx, ds:LMBH_handle
		call	MemUnlockShared
		popf
		.leave
		ret
wrapAround:
		mov	ax, offset QS_buffer
		jmp	continueEnqueue

QueueEnqueueUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueAbortEnqueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Aborts enqueue operation when called
		enqueueLock and before enqueueUnlock.
		Synchronization semaphore is released.
		EnqueueSemaphore is V'ed

CALLED BY:	GLOBAL

PASS:		^lbx:si	= queue

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Synchronization/enqueue semaphore is released.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueAbortEnqueue	proc	far
		uses	si,bx
		.enter
		push	bx
EC <		call	ECValidateQueueDSSI				>
EC <		call	ECCheckLegalEndOperation			>
		mov	si, ds:[si]			; get offset
	;
	; V QS_enqueueSem
	;
		mov	bx, ds:[si].QS_enqueueSem	; one more room for
		call	ThreadVSem			; enqueue
	;
	; V QS_syncSem
	;
		mov	bx, ds:[si].QS_syncSem		; release sync
		call	ThreadVSem			; semaphore
		
		pop	bx
		call	MemUnlockShared
		.leave
		ret
QueueAbortEnqueue	endp


FixedCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueDequeueLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the front entry of a queue. If queue is empty, wait cx
		clock ticks for 'enqueue' operation.  If 'enqueue' operation
		never occurs, return error.

CALLED BY:	GLOBAL
PASS:		^lbx:si	= queue
		cx	= time out value range: 0x0010-0xfff0
			  [ 0x0000-0x000f, 0xfff1-0xffff reserved ]

			  NO_WAIT for waiting 0 ticks.
			  FOREVER_WAIT for wait forever
			  RESIZE_QUEUE is not used in dequeue as it will
			  automatically resize itself as necessary.

RETURN:		ds:di	= front entry
		cx	= size of element
		CF set if error, cx = error message,
				 either QE_TIMEOUT or QE_SHUTTING_DOWN

DESTROYED:	ds

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	1. (QS_front = QS_end) and (QF_full = 0)[queue is empty]?
		block until 'enqueue' operation or 'timeout'
	2. if no error
		di = QS_start

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/25/94    	Initial version
	brianc	10/22/98	Moved into fixed code for resolver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueDequeueLock	proc	far
		queueHandle	local	hptr
		uses	ax,bx,si,dx
		.enter
	;
	; Lock the queue
	;
		mov	queueHandle, bx
		call	MemLockShared
		mov	ds, ax
		
EC <		call	ECValidateQueueDSSI				>

		mov	di, si				;*ds:di = queue
		mov	si, ds:[si]			; ds:si = queue(fptr)
	;
	; Check if we need to resize
	;
		mov	ax, ds:[si].QS_curLength
		shr	ax, 1
		shr	ax, 1
		cmp	ax, ds:[si].QS_numEnqueued
		jb	waitForEnqueue
		cmp	ax, ds:[si].QS_initLength	; don't go below init
		jb	waitForEnqueue			; length
	;
	; Shrink the queue to half of its size: doesn't affect seg addr.
	;
		call	QueueShrinkQueue
	;
	; P dequeue semaphore to determine whether queue is empty
	; : if empty, wait until timeout or enqueue operation
	;
waitForEnqueue:						
		mov	dx, ds:[si].QS_dequeueSem
		mov	bx, queueHandle
		call	MemUnlockShared
		
		mov_tr	bx, dx				;;;; block until there
		call	ThreadPTimedSem			;;;; is something in Q
		xchg	dx, ax
		
		mov	bx, queueHandle			;
		call	MemLockShared			; re-dereference 
		mov	ds, ax				; fptr to the queue
		mov	si, ds:[di]
		
		cmp	dx, SE_TIMEOUT			;
		je	timeOut				; timeout = error
	;
	; Queue is not empty; get front entry now
	; P sync semaphore: Critical section begins here
	;
		mov	bx, ds:[si].QS_syncSem		;
		call	ThreadPSem			;
		mov	di, ds:[si].QS_front		; di = front entry
		add	di, si				;      ( offset )

		cmp	ds:[si].QS_state, CQS_DEAD
		je	deadError		
		mov	cx, ds:[si].QS_eltSize
		clc
finish:
		jnc	done				; if no error, Queue remains
		mov	bx, queueHandle			; locked
		call	MemUnlockShared
	;
	; at this point:
	;	ds:di = fptr to dequeued entry
	;	sync semaphore is P'ed
	;    OR
	; queue error
	;
done:
		.leave
		ret
deadError:
	;
	; wake up the next person waiting
	;
		mov	bx, ds:[si].QS_syncSem
		call	ThreadVSem			; V syncSem
		mov	bx, ds:[si].QS_enqueueSem	; V dequeuSem( no one
		call	ThreadVSem			;   will ever block )
		mov	cx, QE_DEAD
		stc
		jmp	finish
timeOut:
	;
	; error means queue is empty
	;
		cmp	cx, FOREVER_WAIT		; forever wait?
		je	waitForEnqueue			;
		mov	cx, QE_TIMEOUT
		stc
		jmp	finish
		
QueueDequeueLock	endp

FixedCode ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueShrinkQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shrink the queue to 1/2  of its size.
		(!) ds may change.

CALLED BY:	QueueDequeueLock
PASS:		*ds:di		= queue
		ds:si		= queue fptr
RETURN:		ds:si		= new queue fptr
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	I chose NOT TO FLIP direction flag.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	6/ 8/94    	Initial version
	brianc	10/22/98	Made far for QueueDequeueLock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueShrinkQueue	proc	far
		uses	ax, bx, cx, es, di
		.enter
EC <		WARNING WARNING_SHRINKING_QUEUE				>
	;
	; Decide whether enqueued entries are devides in two, or exist in
	; one piece
	;
		mov	ax, ds:[si].QS_end
		cmp	ax, ds:[si].QS_front
		push	di, si
		jb	devided
	;
	; The enqueued entries are not devided by the end line of circular
	; buffer.  Move the entire chunk of enqueued entries to the beginning
	; of the circular buffer
	;
		segmov	es, ds, ax
		mov	cx, ds:[si].QS_end		;
		sub	cx, ds:[si].QS_front		; cx = # bytes to move
		mov	di, si				;
		add	di, offset QS_buffer		; es:di = beginning of
							;	  circ. buffer
		add	si, ds:[si].QS_front		; ds:si = beginning of
							;     enqueued entries
		rep	movsb
		mov_tr	ax, di
		pop	di, si
		sub	ax, si
		mov	ds:[si].QS_end, ax
		mov	ds:[si].QS_front, offset QS_buffer
		jmp	continue
devided:
	;
	; The enqueued entries are devided into two chunks by the end line of
	; circular buffer.  Move the front part of enqueued entry chunk forward
	; so that it is now devided at the half point of the buffer area.
	;
		segmov	es, ds, ax
		mov	cx, ds:[si].QS_totalSize	; cx = end of cir. buff
		sub	cx, ds:[si].QS_front		; cx = # bytes to move
		mov	di, ds:[si].QS_totalSize	;
		sub	di, size QueueStruct		;
		shr	di, 1				;
		add	di, size QueueStruct		; di = new circular buf
		sub	di, cx				;      boundary - # of
		mov	ax, di				;      bytes to move
		add	di, si				;
		add	si, ds:[si].QS_front		; ds:si = cur loc of
							;         front chunk
		rep	movsb
		pop	di, si
		mov	ds:[si].QS_front, ax		; new front
							; end not changed
continue:
	;
	; Now that enqueued entries are in place, adjust chunk size, and
	; adjust queue variables
	;
		mov	cx, ds:[si].QS_totalSize	;
		sub	cx, size QueueStruct		;
		shr	cx, 1				; totalSz = totalSz -
		add	cx, size QueueStruct		; ( circ. buff Sz / 2 )
		mov	ds:[si].QS_totalSize, cx	; ax = new size
		mov	ax, di				; cx = chunk handle
		call	LMemReAlloc
	;
	; Adjust enqueue semaphore
	;
		mov	si, ds:[di]
		mov	cx, ds:[si].QS_curLength	;
		shr	cx, 1				;
		mov	ds:[si].QS_curLength, cx	; curLen = curLen / 2
		mov	bx, ds:[si].QS_enqueueSem	;
pEnqueueSem:
		call	ThreadPSem			;
		loop	pEnqueueSem			; capacity of Queue / 2
		
		.leave
		ret
QueueShrinkQueue	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueDequeueUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dequeue an element from queue.		

CALLED BY:	GLOBAL
PASS:		*ds:si	= queue
RETURN:		nothing
DESTROYED:	nothing ( flags preserved )
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	1. QS_front = QS_front + QS_eltSize
	   if QS_front = QS_totalSize, then QS_front = offset QS_buffer
	2. There should be no error except when the user chooses to EnqueueUnlock
	   without EnqueueLock.  EC version catches that.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueDequeueUnlock		proc	far
		uses	ax,bx,si
		.enter
EC <		call	ECValidateQueueDSSI				>
EC <		call	ECCheckLegalEndOperation			>
		pushf
		mov	si, ds:[si]			; ds:si = queue(fptr)
	;
	; Queue should never be empty; dequeue entry now
	;
		mov	ax, ds:[si].QS_front		; 
		add	ax, ds:[si].QS_eltSize		; QS_front += QS_eltSz
		cmp	ax, ds:[si].QS_totalSize	; if front = totalSize
		jae	wrapAround			; then wrap around
continueDequeue:
		mov	ds:[si].QS_front, ax		; store new QS_front
	;
	; Changes introduced by dynamic queue resizing
	;
		dec	ds:[si].QS_numEnqueued
	;
	; V enqueue/sync semaphores( wake up enqueueing thread first )
	;
		mov	bx, ds:[si].QS_syncSem		; C.S. ends here
		call	ThreadVSem			;
		mov	bx, ds:[si].QS_enqueueSem	; one more room for
		call	ThreadVSem			; enqueue operation
	;
	; Unlock the block
	;
		mov	bx, ds:LMBH_handle
		call	MemUnlockShared
		popf
		.leave
		ret
wrapAround:
		mov	ax, offset QS_buffer
		jmp	continueDequeue

QueueDequeueUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueAbortDequeue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Aborts dequeue operation when called
		dequeueLock and before dequeueUnlock.
		Synchronization semaphore is released.
		DequeueSemaphore is V'ed

CALLED BY:	GLOBAL

PASS:		*ds:si	= queue

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Synchronization/dequeue semaphore is released.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueAbortDequeue	proc	far
		uses	ax,si,bx
		.enter
EC <		call	ECValidateQueueDSSI				>
EC <		call	ECCheckLegalEndOperation			>
		mov	si, ds:[si]			; get offset
	;
	; V QS_dequeueSem
	;
		mov	bx, ds:[si].QS_dequeueSem	; one more entry for
		call	ThreadVSem			; dequeue
	;
	; V QS_syncSem
	;
		mov	bx, ds:[si].QS_syncSem		; release sync sem
		call	ThreadVSem			;
		mov	bx, ds:LMBH_handle
		call	MemUnlockShared
		
		.leave
		ret
QueueAbortDequeue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueNumEnqueues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the current capacity of queue and the number of entries
		currently enqueued

CALLED BY:	GLOBAL
PASS:		^lbx:si	= queue
RETURN:		cx	= number of enqueued entries in the queue
		dx	= current capacity of the queue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueNumEnqueues	proc	far
		uses	ax,si
		.enter
		call	MemLockShared
		mov	ds, ax
		mov	si, ds:[si]
		mov	cx, ds:[si].QS_numEnqueued
		mov	dx, ds:[si].QS_curLength
		call	MemUnlockShared
		.leave
		ret
QueueNumEnqueues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs the procedure passed in on every element in the
		queue.

CALLED BY:	GLOBAL
PASS:		^lbx:si	= queue
		cx:dx = virtual fptr for enum routine
		bp    = data to pass in as parameter1
		ds    = data to pass in as parameter2
		di    = data to pass in as parameter3

	In callback routine:
	PASS:
		bp    = parameter1
		ds    = parameter2
		di    = parameter3
		es:si = current queue element
	RETURN:
		carry set to abort enum
		bp,ds,di = whatever you want to return and pass on to the
			   next callback routine(or you shouldn't trash these)
	MAY DESTROY:
		ax,bx,cx,dx,si,es
		must not cause queue chunk or block to move

RETURN:		carry set if enum was aborted
		bp,ds,di( whatever the callback routine returned last )
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueEnum	proc	far
		uses	ax,es,si
		.enter
		Assert	vfptr, cxdx
		call	MemLockShared
		mov	es, ax
		mov	si, es:[si]
		push	bx
		mov	bx, es:[si].QS_syncSem
		call	ThreadPSem
		push	bx
	;
	; Traverse the queue 
	;
		mov	bx, si
		mov	si, es:[bx].QS_curLength
		cmp	si, es:[bx].QS_numEnqueued
		mov	si, es:[bx].QS_front
		je	insideTraverse
	;
	; If circular buffer is full, QS_front and QS_end are the same.
	; Traverse the first element even if QS_front == QS_end
	;
traverseLoop:
		cmp	si, es:[bx].QS_end
		je	unlockExit
insideTraverse:
	;
	; es:bx = QueueStruct
	; si = offset to queue element
	; bp,ds,di = parameters
	;
		add	si, bx
		push	es,bx,si,cx,dx
		mov	ax, dx
		mov	bx, cx
		call	ProcCallFixedOrMovable
		pop	es,bx,si,cx,dx
		jc	unlockExit
	;
	; Get to the next element
	;
		sub	si, bx
		add	si, es:[bx].QS_eltSize
		cmp	si, es:[bx].QS_totalSize
		jne	traverseLoop
		mov	si, offset QS_buffer
		jmp	traverseLoop
unlockExit:
		pop	bx
		call	ThreadVSem
		pop	bx
		call	MemUnlockShared
		.leave
		ret
QueueEnum	endp

QueueCode	ends

