COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		System Spooler
FILE:		processUtils.asm

AUTHOR:		Jim DeFrisco, 9 March 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/13/90		Initial revision


DESCRIPTION:
	This file contains the code to implement the printer job queues

	$Id: processUtils.asm,v 1.1 97/04/07 11:11:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


QueueManagement	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocPrintQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates and initializes print queue buffer

CALLED BY:	INTERNAL
		SpoolAddJob

PASS:		queueSemaphore down

RETURN:		ax	- segment of locked print queue block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		; alloc enough for minimum queue, round up to 16-byte bound
INITIAL_QUEUE_SIZE equ <(((size PrintQueue + size QueueInfo + size JobInfoStruct + size JobParameters + 8 + 15)/16)*16)>
QUEUE_HEAP_SIZE 	equ	<INITIAL_QUEUE_SIZE - size PrintQueue>

AllocPrintQueue	proc	near
		uses	cx, dx, ds
		.enter

		; alloc a buffer for the thing

		mov	ax, INITIAL_QUEUE_SIZE		; init size
		mov	bx, handle 0			; set owner to spool
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		call	MemAllocSetOwner
		call	HandleP				; Own block too
		mov	ds, ax				; ds -> block

		; it's an LMem managed block so do the init thing

		mov	dx, size PrintQueue		; offset to heap
		mov	ax, LMEM_TYPE_GENERAL		; just general type
		mov	cx, QUEUE_HEAP_SIZE		; initial heap size
		push	si, di, bp
		mov	si, 2				; alloc two handles
		clr	di
		clr	bp
		call	LMemInitHeap			; init the block
		pop	si, di, bp

		; initializing other things

		clr	ax
		mov	ds:[PQ_numQueues], ax		; no queues yet
		mov	ds:[PQ_numJobs], ax		; no jobs yet
		mov	ds:[PQ_firstQueue], ax		; no queues yet
		mov	ax, ds				; return segment in ax
		mov	cx, dgroup
		mov	ds, cx
		mov	ds:[queueHandle], bx		; save handle

		.leave
		ret
AllocPrintQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindRightQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the queue that's right for the job

CALLED BY:	INTERNAL
		SpoolAddJob

PASS:		ds	- segment address of locked/owned PrintQueue
		es:si	- pointer to PrintPortInfo for queue

RETURN:		bx	- handle to the right queue
			  or 0 if no queue allocated for this device

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Follow the queue chain, comparing device names.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindRightQueue	proc	near
		uses	di, si, es, cx
		.enter
		
		; if there aren't any queues yet, then bail

		clr	bx			; assume this is first one
		cmp	ds:[PQ_numQueues], 0	; any here ?
		jz	done			;  no, finished

		; start at the beginning.  Search, search, search...

		mov	bx, ds:[PQ_firstQueue]	; get chunk to first one
searchLoop:
		mov	di, ds:[bx]		; get pointer to next one
		mov	cx, ds:[di].QI_portInfo.PPI_type
		cmp	cx, es:[si].PPI_type	; same type? if not, bail
		jne	nextOne			;  else check port number 
		cmp	cx, PPT_CUSTOM
		je	checkCustom

		cmp	cx, PPT_PARALLEL	; parallel or serial ??
		ja	done			; if not, only one queue exists
		mov	cx, ds:[di].QI_portInfo.PPI_params.PP_serial.SPP_portNum
		cmp	cx, es:[si].PPI_params.PP_serial.SPP_portNum
		je	done			; if we found it, we're done
nextOne:
		mov	bx, ds:[di].QI_next	; get pointer to next one
		tst	bx			; at end of list ?
		jnz	searchLoop		;  else keep looking
done:						; handle (or zero) is is BX
		.leave
		ret

checkCustom:

		; Compare all the CPP_info bytes of the two to see if this is
		; the right queue to use.

		push	si, cx, di
		add	di, offset QI_portInfo.PPI_params.PP_custom.CPP_info
		add	si, offset PPI_params.PP_custom.CPP_info
		xchg	si, di
		mov	cx, size CPP_info/2
		repe	cmpsw

	if size CPP_info and 1
		jne	10$
		cmpsb
10$:
	endif
		pop	si, cx, di
		jne	nextOne
		jmp	done
FindRightQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertJobIntoQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter a filled out job structure into a print queue

CALLED BY:	INTERNAL
		CreateThreadStart

PASS:		ax	- chunk handle of job info
		bx	- chunk handle of queue to insert into
		ds	- segment of locked/owned PrintQueue

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InsertJobIntoQueue proc	near
		uses	ax, bx
		.enter
		
		; dereference the queue handle.  If there are no jobs yet,
		; just make this one the current job.  Else follow the chain
		; until we hit the end.

		mov	bx, ds:[bx]		; ds:bx -> queue info block
		cmp	ds:[bx].QI_curJob, 0	; any jobs in the queue ?
		jne	followChain		;  yes, follow the chain
		mov	ds:[bx].QI_curJob, ax	; store the job handle
		clr	ax
		mov	ds:[bx].QI_fileHan, ax	; clear out all the other info
		mov	{word} ds:[bx].QI_filePos, ax
		mov	{word} ds:[bx].QI_filePos+2, ax
		mov	ds:[bx].QI_curPage, ax

exit:
		.leave
		ret

		; at least one job is in the queue, follow the links
followChain:
		mov	si, ds:[bx].QI_curJob
linkLoop:
		mov	si, ds:[si]		; dereference next handle
		cmp	ds:[si].JIS_next, 0	; is this the end ?
		je	foundIt			;  yes, finish up
		mov	si, ds:[si].JIS_next	;  no, get next link
		jmp	linkLoop
foundIt:
		mov	ds:[si].JIS_next, ax	; save link
		jmp	exit			; all done
		
InsertJobIntoQueue endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapJobIDtoHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a job chunk handle given a jobID

CALLED BY:	INTERNAL
		SpoolDelJob...

PASS:		cx	- jobID
		ds	- locked/owned PrintQueue

RETURN:		bx	- job chunk handle
			- zero if no match found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		given a unique job id, map it to the chunk handle for the 
		desired job

		for each queue
		    for each job in the queue
			if (jobIDs match)
			    return current job handle
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MapJobIDtoHandle proc	near
		uses	si,di,ax
		.enter

		mov	bx, ds:[PQ_firstQueue]	; for each queue...
nextQueueInBlock:
		tst	bx			; if no queues, exit
		jz	exit
		mov	si, ds:[bx]		; ds:si -> queue
		mov	di, ds:[si].QI_curJob	; get current job pointer
nextJobInQueue:
		tst	di			; 
		jz	nextQueue
		mov	ax, di			; save job handle
		mov	di, ds:[di]		; ds:di -> job
		GetJobID	ds,di,bx
		cmp	cx,bx
		jne	nextJob
		mov	bx, ax			; return job handle
		jmp	exit
nextJob:
		mov	di, ds:[di].JIS_next	; get next job handle
		jmp	nextJobInQueue
nextQueue:
		mov	bx, ds:[si].QI_next	; on to next queue
		jmp	nextQueueInBlock	
exit:
		.leave
		ret
MapJobIDtoHandle endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendJobNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send method to process notifying it that a job
		has been added to or removed from a queue

CALLED BY:	SpoolAddJob(), SpoolDelJob()

PASS:		*DS:BX	- JobInfoStruct of job in queue
		AX	- Message to be sent to process

RETURN:		nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/18/90	Initial version
	don	 5/27/92	Combined removed & added routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendJobAddedNotification	proc	far
		mov	ax, MSG_SPOOL_JOB_ADDED
		GOTO	SendJobNotification
SendJobAddedNotification	endp

SendJobRemovedNotification	proc	far
		mov	ax, MSG_SPOOL_JOB_REMOVED
		FALL_THRU	SendJobNotification
SendJobRemovedNotification	endp

SendJobNotification		proc	far
		uses	bx, cx, dx, di, bp, si
		.enter

		mov	di, ds:[bx]
		GetJobID	ds, di, cx
		mov	di, ds:[di].JIS_queue
		mov	di, ds:[di]
		mov	dx, ds:[di].QI_portInfo.PPI_type
		mov	bp, ds:[di].QI_portInfo.PPI_params.PP_serial.SPP_portNum
		push	ax, di, bx
		mov     bx, handle 0            ; sending it to ourself
		mov     di, mask MF_FORCE_QUEUE
		call    ObjMessage
		pop	ax, di, bx
	;
	; Now cope with notifying the system GCN list, when the job is removed.
	; 
		cmp	ax, MSG_SPOOL_JOB_REMOVED
		jne	done

		mov	dx, cx			; dx <- job ID, always
		mov	al, ds:[di].QI_error
		
		mov	cx, PSCT_COMPLETE	; assume successful
		cmp	al, SI_KEEP_GOING
		je	sendToGCN

		mov	cx, PSCT_ERROR		; nope -- maybe error?
		cmp	al, SI_ERROR
		je	sendToGCN

		mov	cx, PSCT_CANCELED	; nope -- was canceled
		cmp	al, SI_DETACH
		jne	sendToGCN
	    ;
	    ; Don't send out canceled notification on detach unless job is
	    ; actually being canceled due to the detach; the thing is just
	    ; suspended, so notification isn't appropriate.
	    ;
		mov	bx, ds:[bx]
		test	ds:[bx].JIS_info.JP_spoolOpts, mask SO_SHUTDOWN_ACTION
		jz	done
sendToGCN:
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	si, GCNSLT_PRINT_JOB_STATUS
		mov	ax, MSG_PRINT_STATUS_CHANGE
		mov	di, mask GCNLSF_FORCE_QUEUE
		call	GCNListRecordAndSend
done:
		.leave
		ret
SendJobNotification		endp

QueueManagement	ends



idata	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDeviceQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alloc a queue for a specific device

CALLED BY:	INTERNAL
		SpoolAddJob

PASS:		*ds:si	- chunk handle of job info block for job to start 
			  queue for (in locked/owned PrintQueue block)

RETURN:		ds	- still points at PrintQueue, but may have changed
			  value
		bx	- handle of allocated queue
			- zero if unable to create thread

DESTROYED:	es

PSEUDO CODE/STRATEGY:
		Alloc a chunk for the info, init the info.
		Update the affected PrintQueue variables

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This function is in IDATA so that the thread creation is done
		from a fixed block.  This minimizes the possibility that 
		ThreadCreate is called from a movable (locked) block that is
		right above the FIXED part of the heap.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocDeviceQueue proc	near
		uses	ax, cx, dx, di, si, bp
		.enter

		; allocate & initialize the queue chunk

		call	AllocDeviceQueueLow

		; start up the thread that will be associated with the
		; queue.  It is OK to do this now, since the first thing
		; that the thread will do is try to PLock the PrintQueue
		; buffer, which is currently owned by this thread.  We
		; won't release it until we've initialized everything, so
		; we're OK.
tryCreateThread:
		push	bx			; save queue handle
		push	di			; preserve frame ptr
		mov	cx, dgroup		; starting address for thread
		mov	dx, offset dgroup:SpoolThreadBirth
		mov	al, PRIORITY_LOW	; start things off in backgrnd
		mov	di, SPOOL_THREAD_STACK_SIZE
		mov	bp, handle 0		; have spooler own them
		call	ThreadCreate
		jnc	threadOK		; allocated things ok

		; some problem allocating a stack for the thread, try again

		mov	ax, 30			; sleep for a while
		call	TimerSleep		;
		mov	al, PRIORITY_LOW	; don't need high priority
		call	ThreadCreate		; try again
		jc	threadCreateError	; if error, deal with it

		; success - store the thread handle
threadOK:
		pop	di			; restore frame ptr
		mov	ds:[di].QI_thread, bx 	; save thread handle
		pop	bx			; restore queue handle


if _DUAL_THREADED_PRINTING
		push	bx
		mov	ax, size PrintThreadInfo
		mov	cx, (mask HF_SHARABLE or mask HF_FIXED) or \
			    (mask HAF_ZERO_INIT or mask HAF_NO_ERR) shl 8
		call	MemAlloc		; bx <- PrintThreadInfo handle
		mov	es, ax

		; create semaphores for synchronizing threads

		push	bx
		mov	bx, 1
		call	ThreadAllocSem
		mov	es:[PTI_dataSem], bx
		mov	bx, 1
		call	ThreadAllocSem
		mov	es:[PTI_printSem], bx
		pop	bx

		; allocate print thread

		push	bx, di
		mov	al, PRIORITY_LOW
		mov	cx, vseg PrintThreadPrintSwaths
		mov	dx, offset PrintThreadPrintSwaths
		mov	di, 500			; small stack
		mov	bp, handle 0		; have spooler own them
		call	ThreadCreate
		pop	bx, di
		jnc	pThreadOK

		; couldn't create print thread.  free semaphores and mem block.

		push	bx
		mov	bx, es:[PTI_dataSem]
		call	ThreadFreeSem
		mov	bx, es:[PTI_printSem]
		call	ThreadFreeSem
		pop	bx

		call	MemFree
		jmp	noPrintThread
pThreadOK:
		mov	ds:[di].QI_printThreadInfo, bx
noPrintThread:
		pop	bx
endif	; _DUAL_THREADED_PRINTING

done:
		.leave
		ret

		; Let the user decide what we should do
threadCreateError:
		pop	di, bx			; restore data
		call	AllocDeviceQueueError
		jnc	tryCreateThread		; try again if user so desires
		jmp	done		
AllocDeviceQueue endp

idata	ends



QueueManagement	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDeviceQueueLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a device queue chunk (but not the thread)

PASS:		*ds:si	- JobInfoStruct to be inserted into new queue

RETURN:		es:di	- new QueueInfo structure
		ds:si	- passed JobInfo structure
		bx	- handle of allocated queue chunk

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocDeviceQueueLow	proc	far
		.enter

		; get es -> PrintQueue too

		segmov	es, ds

		; first alloc a chunk to hold the queue info

		mov	cx, size QueueInfo	; need this much space
		clr	al			; no flags
		call	LMemAlloc
		mov	di, ax			; save chunk handle
		mov	di, ds:[di]		; ds:di -> queue info chunk

		; now that we're done with the LMemReAlloc, dereference the 
		; JobInfoStruct handle

		mov	si, ds:[si]		; dereference JIS handle

		; init the queue info
		; copy the device name first.   then the port info.

SBCS <		mov	cx, MAX_DEVICE_NAME_SIZE / 2 ; copy the whole buffer>
DBCS <		mov	cx, MAX_DEVICE_NAME_SIZE ; copy the whole buffer>
		add	si, JIS_info.JP_deviceName ; set pointer to name
		add	di, QI_device		; set up destination ptr
		rep	movsw
SBCS <		sub	si, MAX_DEVICE_NAME_SIZE + JIS_info.JP_deviceName>
SBCS <		sub	di, MAX_DEVICE_NAME_SIZE + QI_device		>
DBCS <		sub	si, MAX_DEVICE_NAME_SIZE*(size wchar) + JIS_info.JP_deviceName>
DBCS <		sub	di, MAX_DEVICE_NAME_SIZE*(size wchar) + QI_device		>

		mov	cx, size PrintPortInfo 	; copy the whole buffer
		add	si, JIS_info.JP_portInfo ; set pointer to name
		add	di, QI_portInfo		; set up destination ptr
		rep	movsb
		sub	si, size PrintPortInfo + JIS_info.JP_portInfo
		sub	di, size PrintPortInfo + QI_portInfo
		cmp	ds:[si].JIS_info.JP_portInfo.PPI_type, PPT_CUSTOM
		jne	clearOtherVars
		
		; For a custom port, specify a unique CPP_unit so the job
		; notification has something to send out that identifies the
		; queue.

		push	ds
		segmov	ds, dgroup, cx
		mov	cx, ds:[customQueueID]
		inc	cx
		xchg	cx, ds:[customQueueID]
		pop	ds
		mov	es:[di].QI_portInfo.PPI_params.PP_custom.CPP_unit, cx

clearOtherVars:
		clr	cx
		mov	es:[di].QI_curJob, cx	; clear the other variables
		mov	es:[di].QI_fileHan, cx
		mov	{word} es:[di].QI_filePos, cx
		mov	{word} es:[di].QI_filePos+2, cx
		mov	es:[di].QI_curPage, cx 	
		mov	es:[di].QI_curPhysPg, cx
		mov	es:[di].QI_numPhysPgs, cx
		mov	es:[di].QI_next, cx 	; this will be the last in line
		mov	es:[di].QI_thread, cx 	; no thread yet
		mov	es:[di].QI_error, SI_KEEP_GOING ; init to no error
if _DUAL_THREADED_PRINTING
		mov	es:[di].QI_printThreadInfo, cx
endif

		; now insert the queue into the queue chain

		cmp	ds:[PQ_firstQueue], 0	; is this the first one ?
		jne	followQueues		;  no, follow the chain
		mov	ds:[PQ_firstQueue], ax	; store chunk handle

		; queue is on list, bump the number we have
queueInserted:
		inc	ds:[PQ_numQueues]	; now we have one more
		mov	bx, ax			; return queue handle in bx

		.leave
		ret

		; follow the queue chain and insert this one at the end
followQueues:
		mov	bx, ds:[PQ_firstQueue]	; get chunk handle to first
		mov	bx, ds:[bx]		; get pointer to it
EC <		mov	cx, ds:[PQ_numQueues]	; search this many	>
findEndLoop:
		cmp	ds:[bx].QI_next, 0	; is this the end ?
		jz	foundEnd		;  yes, done looping
		mov	bx, ds:[bx].QI_next	;  no, get the next link
		mov	bx, ds:[bx]		; dereference next link
NEC <		jmp	findEndLoop		; assume it's ok for prod >
EC  <		loop	findEndLoop					>
EC  <		ERROR	SPOOL_INVALID_QUEUE_LIST ; something is wrong	>

		; ok, found the end of the chain.  Put ours in.
foundEnd:
		mov	ds:[bx].QI_next, ax	; put in our handle
		jmp	queueInserted		; and continue
AllocDeviceQueueLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocDeviceQueueError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an error to the user if a print thread cannot be
		created.

CALLED BY:	AllocDeviceQueue()

PASS:		BX	= QueueInfo chunk handle

RETURN:		Carry	= Clear (try again)
		BX	= preserved
			- or -
		Carry	= Set (abort queue creation)
		BX	= 0

DESTROYED:	CX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocDeviceQueueError	proc	far
		.enter

		; Put up a box and make the user decide what to do.

		mov	cx, SERROR_CANT_ALLOC_BITMAP ; this gives a good message
		clr	dx			; no queue yet
		call	SpoolErrorBox		; put up a box
		TestUserStandardDialogResponses	\
		SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK		; if affirmative, do it again
		je	done			; carry = clear

		; the user wants to cancel.  De-allocate the queue and exit
		; unlink the queue from the queue chain.  then free the chunk.

		mov_tr	ax, bx			; ax <- queue handle
		dec	ds:[PQ_numQueues]	; one less queue
		jnz	moreThanOneQueue	;  handle if more than one
		mov	ds:[PQ_firstQueue], 0	; null head queue pointer
freeQueue:
		call	LMemFree		; free the queue
		clr	bx			; queue handle = 0
		stc
done:
		.leave
		ret

		; more than one queue going.  find the one to unlink.
moreThanOneQueue:
		mov	bx, ds:[PQ_firstQueue]	; get pointer to first
delSearchLoop:
		mov	bx, ds:[bx]		; dereference handle
		cmp	ax, ds:[bx].QI_next	; is it the next one
		je	foundDelQ		; found queue to delete
		mov	bx, ds:[bx].QI_next	; follow the chain
EC <		tst	bx			; valid queue handle ?	>
EC <		ERROR_Z SPOOL_INVALID_QUEUE_LIST			>
		jmp	delSearchLoop
foundDelQ:
		mov	si, ax
		mov	si, ds:[si]
		mov	si, ds:[si].QI_next
		mov	ds:[bx].QI_next, si	; stuff new link
		jmp	freeQueue
AllocDeviceQueueError	endp

QueueManagement	ends
