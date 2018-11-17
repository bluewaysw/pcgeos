COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		System Spooler
FILE:		processQueue.asm

AUTHOR:		Jim DeFrisco, 9 March 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/13/90		Initial revision


DESCRIPTION:
	This file contains the code to implement the printer job queues

	The routines in this file generally manipulate a structure called
	the PrintQueue.  This is a block of memory that contains the 
	print queues for all the devices that have print jobs queued for
	them.  There is a separate thread spawned for each queue, whe
	the queue is created.  Queues are created only when a job comes
	in for a device/port combo that has no queue yet.  All jobs are 
	added via the library call SpoolAddJob (see below).

	Since the PrintQueue block is shared between all the queue threads,
	access to it is synchronized, via LockQueue/UnlockQueue.  The routines
	in this file will generally lock/own the block for their duration,
	which is designed to be relatively short.  Each thread will copy
	the small amount of information about the job into some local storage
	at the beginning of its spool file processing, so that it doesn't
	have to access the block for most of its printing time, which could
	be pretty long.  When it is finished processing the file, it will
	again lock/own the block in order to remove the print job from the
	queue and start the next job.

	When a queue thread has finished processing all the jobs in its 
	queue, it will kill itself, along with the storage used for the queue.

	$Id: processQueue.asm,v 1.1 97/04/07 11:11:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


QueueManagement	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolAddJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the spooler thread has started up, and
		start one up if it hasn't.  Add the passed gstring file
		to the print queue

CALLED BY:	GLOBAL

PASS:		dx:si	- pointer to JobParameters.  

RETURN:		cx	- print job ID

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolAddJob	proc	far
		push	ds

		; grab the next jobID to use from dgroup -- this ensures that 
		; the job IDs are unique over the life of the spooler in the
		; system.

		mov	cx, dgroup
		mov	ds, cx
		mov	cx, ds:[nextJobID]
		inc	ds:[nextJobID]

		; add the job to the system

		call	SpoolAddJobInternal
		pop	ds
		ret
SpoolAddJob	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolAddJobInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal version of SpoolAddJob that accepts a job ID, so
		restarted print jobs can have the same ID as they had before.

CALLED BY:	(INTERNAL) SpoolAddJob
PASS:		dx:si	= JobParameters
		cx	= job ID to use
RETURN:		cx	= job ID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolAddJobInternal proc	far
		uses	ds, es, ax, bx, dx, si, di
jobID		local	word	push cx
jobHandle	local	lptr
		.enter

		; before we do anything, make sure we're not detaching.  In that
		; case, just bail

		mov	ax, dgroup
		mov	ds, ax
		PSem	ds, queueSemaphore
		test	ds:[spoolStateFlags], mask SS_DETACHING	; see if going
		jz	lockQueue

		; bad news, we're detaching.  Just ignore this print job.

		VSem	ds, queueSemaphore
		jmp	exit

		; we're not detaching.  Continue normally.  This recreates what
		; code is in the routine LockQueue.  We don't want to give up 
		; the queueSemaphore now that we have it
lockQueue:
		mov	bx, ds:[queueHandle]	; get handle
		tst	bx			; see if anything there yet
		jnz	validHandle		;  no, quit with error

		; bad queue handle, probably have to create one

		call	AllocPrintQueue		; first time around baby
		jmp	haveQueue
validHandle:
		call	MemPLock		; lock it down
haveQueue:
		mov	ds, ax
EC <		call	ECLMemValidateHeap				>

		; alloc a job buffer, inc the right vars, copy the info
		; over from the passed block

		mov	es, dx
		mov	cx, size JobInfoStruct	; size of job block
		add	cx, es:[si].JP_size	; ass in size of JobParameters
		clr	al			; no flags
		call	LMemAlloc		; allocate a chunk
		mov	jobHandle, ax		; save job chunk handle
		segmov	es, ds, cx		; set es -> PrintQueue
		mov	ds, dx			; ds -> passed block
		mov	di, ax			; di = job chunk handle
		mov	di, es:[di]		; es:di -> job chunk
		clr	es:[di].JIS_next	; init next field
		push	di
		add	di, JIS_info		; offset to where info stored
		mov	cx, ds:[si].JP_size
		rep	movsb			; copy all of JobParameters
		pop	di
		segmov	ds, es, cx		; get Q ptr back in ds
		mov	si, di			; ds:si -> job info chunk

		; time stamp the job

		call	TimerGetDateAndTime
		mov	ds:[si][JIS_time].STS_hour, ch ; set time in info struct
		mov	ds:[si][JIS_time].STS_minute, dl
		mov	ds:[si][JIS_time].STS_second, dh

		; set the jobID to that we were passed.

		mov	dx, ss:[jobID]
		mov	ds:[si].JIS_jobID, dx	; save it
		push	dx			; save it so we can return it

		; Locate the right queue, alloc one if we don't find it

		add	si, JIS_info.JP_portInfo ; point at port info 
		segmov	es, ds			; es:si -> string
		call	FindRightQueue		; find the queue we should be
		sub	si, JIS_info.JP_portInfo ; set pointer back to start
		tst	bx			; if not found, alloc one
		jz	allocAQueue		;  found one, continue
		mov	ds:[si][JIS_queue], bx	; save queue handle in job info

		; the job block is all initialized, so 
		; now that we have the queue, insert the job

		mov	ax, jobHandle		; pass handle of job info
		call	InsertJobIntoQueue	; do the dirty deed
		mov_tr	bx, ax			; job chunk handle to bx
		call	SendJobAddedNotification
		inc	ds:[PQ_numJobs]		; one more job in queue
done:
		call	UnlockQueue		; release it
		pop	cx			; return jobID in cx
exit:
		.leave
		ret

		; there is no queue, so send a message to allocate one
allocAQueue:
		mov	bx, handle 0		; sending it to ourself
		mov	di, mask MF_FORCE_QUEUE 
		mov	cx, jobHandle		; pass print queue handle here
		mov	ax, MSG_SPOOL_CREATE_THREAD
		call	ObjMessage
		jmp	done
SpoolAddJobInternal endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolDelJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a job from the spooler queue

CALLED BY:	GLOBAL

PASS:		cx	- print job id

RETURN:		ax	- status of operation (enum of type SpoolOpStatus):
				SPOOL_OPERATION_SUCCESSFUL
				SPOOL_JOB_NOT_FOUND
				SPOOL_QUEUE_EMPTY

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolDelJob	proc	far
		uses	ds, bx, cx
		.enter

		; get the handle of the PrintQueue, check validity

		call	LockQueue		; get control of queue
		jc	queueEmpty		;  nothing to get
		mov	ds, ax			; ds -> queue

		; map the job ID to a valid job handle

		call	MapJobIDtoHandle	; bx = job handle
		tst	bx			; if zero, something is wrong
		jz	jobNotFound

		; dereference the job handle, find out which queue it is in

		mov	di, ds:[bx]		; ds:di -> job info
		mov	si, ds:[di].JIS_queue	; get queue chunk handle
		mov	si, ds:[si]		; ds:si -> queue
		cmp	ds:[si].QI_curJob, bx	; is job to delete curr active? 
		je	deleteActive		;  yes, do something special

		; it's not the currently active job, so we can nuke the 
		; chunk altogether.  We first need to un-link it from the
		; queue, and delete the spool file if that option is set.

		mov	si, ds:[si].QI_curJob	; get link to next job
chainLoop:
		mov	si, ds:[si]		; get pointer to next job
		tst	si			; see if at the end of queue
		je	jobNotFound		;  something is screwy
		cmp	ds:[si].JIS_next, bx	; is this the one ?
		je	foundPrevJob		;  yes, unlink it
		mov	si, ds:[si].JIS_next	;  no, on to the next one
		jmp	chainLoop		; on to next one
foundPrevJob:
		mov	ax, ds:[di].JIS_next	; copy link over to prev job
		mov	ds:[si].JIS_next, ax	; job is now unlinked
		call	SendJobRemovedNotification

		; job is unlinked, so delete the file if needed and nuke the
		; chunk

		test	ds:[di].JIS_info.JP_spoolOpts, mask SO_DELETE
		jz	freeChunk
		lea	dx, ds:[di].JIS_info.JP_fname ; set up pointer
		call	FileDelete
freeChunk:
		mov	ax, bx			; set up for LMemFree
		call	LMemFree		; nuke the chunk

done:
		call	UnlockQueue		; release it
exit:	
		.leave
		ret

		; there is no print queue allocated
queueEmpty:
		mov	ax, dgroup		; ds -> dgroup
		mov	ds, ax
		VSem	ds, [queueSemaphore]	; release it
		mov	ax, SPOOL_QUEUE_EMPTY	; get ready for possible failure
		jmp	exit

		; Delete a job that is currently active in the queue.  
		; this means signalling the thread that it should abort.  We do
		; this by setting the QI_error variable in the QueueInfo 
		; structure.
deleteActive:
		mov	ds:[si].QI_error, SI_ABORT ; signal thread
		mov	ax, SPOOL_OPERATION_SUCCESSFUL
		jmp	done
		
		; Job not found.
		; this probably means something is really screwed up.
jobNotFound:
		mov	ax, SPOOL_JOB_NOT_FOUND
		jmp	done

SpoolDelJob	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return information from the spooler

CALLED BY:	GLOBAL

PASS:		CX	= SpoolInfoType
				SIT_JOB_INFO
					see SpoolInfoJob
				SIT_QUEUE_INFO
					see SpoolInfoQueue
				SIT_JOB_PARAMETERS
					see SpoolInfoJobParameters

RETURN: 	see appropriate routine

DESTROYED:	see appropriate routine

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/13/90	Initial version
	don	04/01/91	Cleaned up documentation, calling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

spoolInfoTable	label	word
	word	offset	SpoolInfoJob
	word	offset	SpoolInfoQueue
	word	offset	SpoolInfoJobParameters

SpoolInfo	proc	far
		.enter

		; Call the appropriate routine
		;
EC <		cmp	cx, SpoolInfoType				>
EC <		ERROR_A	SPOOL_BAD_SPOOL_INFO_TYPE			>
		mov	bx, cx
		call	{word} cs:[spoolInfoTable][bx]

		.leave
		ret
SpoolInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolInfoJobParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the JobParameters for thee passed JobID

CALLED BY:	SpoolInfo

PASS:		dx	- print job id
		cx	- SpoolInfoType

RETURN:		ax	- status of info (SpoolOpStatus enum)
				SPOOL_OPERATION_SUCCESSFUL
				SPOOL_JOB_NOT_FOUND
				SPOOL_QUEUE_EMPTY

		if ax = SPOOL_OPERATION_SUCCESSFUL:
		bx	- handle of block holding JobParameters

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolInfoJobParameters	proc	near
		FALL_THRU	SpoolInfoJob
SpoolInfoJobParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolInfoJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a bunch of info about the jobs in a queue

CALLED BY:	SpoolInfo

PASS:		dx	- print job id
		cx	- SpoolInfoType
				

RETURN:		ax	- status of info (SpoolOpStatus enum)
				SPOOL_OPERATION_SUCCESSFUL
				SPOOL_JOB_NOT_FOUND
				SPOOL_QUEUE_EMPTY

		if ax = SPOOL_OPERATION_SUCCESSFUL:
		bx	- handle of block holding JobStatus

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The structures are placed one after another in the buffer,
		in the order that they sit in the queue, so the first 
		one is the currently active job, etc..

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SPOOL_INFO_FLAGS  equ	<ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE>

SpoolInfoJob	proc	near
		uses	di, si, bp, ds, es
		.enter

		; get the handle of the PrintQueue, check validity

		mov	bp, cx			; SpoolInfoType -> bp
		mov	cx, dx			; job ID -> cx
		call	LockQueue		; get queue exclusive
		jnc	haveQueue

		; release the queue semaphore, as we're not going to allocate
		; the block, then return an error

		mov	ax, dgroup		; get ds -> dgroup
		mov	ds, ax
		VSem	ds, [queueSemaphore]	; release it
		mov	ax, SPOOL_QUEUE_EMPTY
		jmp	exit

haveQueue:
		mov	ds, ax			; ds -> queue

		; try to find the job, exit if we can't
		; map the job ID to a valid job handle

		call	MapJobIDtoHandle	; bx = job handle
		tst	bx			; if zero, something is wrong
		mov	ax, SPOOL_JOB_NOT_FOUND	; assume the worst
		jz	done

		; if the abort flag for this job's queue is set and
		; this job is the curJob then don't return the job
		; because it has been aborted
		
		mov	si, ds:[bx]
		mov	si, ds:[si].JIS_queue
		mov	si, ds:[si]
		cmp	ds:[si].QI_error, SI_ABORT
		jne	validJob
		cmp	ds:[si].QI_curJob, bx
		mov	ax, SPOOL_JOB_NOT_FOUND
		je	done

		; ok, now we have a valid job.  allocate some memory to copy
		; over the proper info.  and copy it already...
validJob:
		mov	si, ds:[bx]		; deref job handle
		push	bx			; save job's chunk handle
		push	si			; also save start of JIS
		add	si, JIS_info		; offset to JobParameters blk
		cmp	bp, SIT_JOB_PARAMETERS
		je	jobParameters
		mov	ax, size JobStatus	; get size of indiv structure
		mov	cx, SPOOL_INFO_FLAGS	; MemAlloc flags
		call	MemAlloc
		mov	es, ax			; es -> block
		clr	di			; start at beginning of block
		mov	cx, offset JS_time	; copy up to JS_time
		rep	movsb			; copy the necc info
		mov	cx, size SpoolTimeStruct
		pop	si			; restore start of JobInfoStruct
		push	ds:[si].JIS_queue	; save queue chunk handle
		add	si, JIS_time
		rep	movsb			; move over the time

		; see if we are the first job in the queue
		; does NOT take into account two queues on the same port
		
		mov	es:[JS_printing], SJP_NOT_PRINTING
						; assume job not printing
		pop	si			; restore queue chunk handle
		pop	ax			; JobInfoStruct's chunk => AX
		mov	si, ds:[si]		; dereference the queue handle
		cmp	ds:[si].QI_curJob, ax	; is the first job us ?
		jne	cleanUp			; no, so we can't be printing
		mov	es:[JS_printing], SJP_PRINTING ; else we must be printing
		mov	ax, ds:[si].QI_numPhysPgs
		mov	es:[JS_totalPage], ax
		mov	ax, ds:[si].QI_curPhysPg
		mov	es:[JS_curPage], ax

		; done copying, so unlock the block and return proper info
cleanUp:
		call	MemUnlock		; unlock the info block
		mov	ax, SPOOL_OPERATION_SUCCESSFUL ; indicate all ok
done:
		call	UnlockQueue		; release it
exit:
		.leave
		ret

		; copy all of the JobParameters, not just the JobStatus
jobParameters:
		mov	ax, ds:[si].JP_size
		mov	cx, SPOOL_INFO_FLAGS	; MemAlloc flags
		call	MemAlloc
		mov	es, ax			; es -> block
		clr	di			; start at beginning of block
		mov	cx, ds:[si].JP_size
		rep	movsb			; copy the necessary info
		add	sp, 4			; clean up the stack
		jmp	cleanUp
SpoolInfoJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolInfoQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a list of all job ids in the queue

CALLED BY:	GLOBAL

PASS:		dx:si	= pointer to port info of queue to get info about
			  (PrintPortInfo structure)
		dx	= -1 to determine if any print queues are active
			  only returns SPOOL_QUEUE_EMPTY
			               SPOOL_QUEUE_NOT_EMPTY

RETURN:		ax	= status of info (SpoolOpStatus enum)
				SPOOL_OPERATION_SUCCESSFUL
				SPOOL_QUEUE_EMPTY
				SPOOL_QUEUE_NOT_EMPTY
				SPOOL_QUEUE_NOT_FOUND

		if ax = SPOOL_OPERATION_SUCCESSFUL:
		cx	= number of job ids in block
		bx	= handle of block with id's in it

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The ids are placed one after another in the buffer,
		in the order that they sit in the queue, so the first 
		one is the currently active job, etc..

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SPOOL_INFO_FLAGS  equ	<ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE>

SpoolInfoQueue	proc	near
		uses	ds, es, si, di, dx
		.enter
		mov	ax, offset SetCarry
		call	SpoolInfoQueueCommon
		.leave
		ret

SpoolInfoQueue	endp

SetCarry	proc	near
		stc
		ret
SetCarry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolInfoQueueCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to fetch the jobs for a queue

CALLED BY:	SpoolInfoQueue, SpoolInfoQueueForPrinter

PASS:		dx:si	= pointer to port info of queue to get info about
			  (PrintPortInfo structure)
		dx	= -1 to determine if any print queues are active
			  only returns SPOOL_QUEUE_EMPTY
			               SPOOL_QUEUE_NOT_EMPTY

		ax	- callback routine to determine whether a job
			  should be added to the list

		es, di 	- data to pass to callback


RETURN:		ax	= status of info (SpoolOpStatus enum)
				SPOOL_OPERATION_SUCCESSFUL
				SPOOL_QUEUE_EMPTY
				SPOOL_QUEUE_NOT_EMPTY
				SPOOL_QUEUE_NOT_FOUND

		if ax = SPOOL_OPERATION_SUCCESSFUL:
		bx	= handle of block with id's in it
		cx	= number of job ids in block

DESTROYED:	dx,ds,si,es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolInfoQueueCommon	proc near
					
callback	local	nptr.near	push	ax
dataDI		local	word		push	di
dataES		local	word		push	es
		.enter

	;		
	; get the handle of the PrintQueue, check validity
	;
		call	LockQueue		; get queue exclusive
		jnc	continue

	;
	; there is no queue, signal and quit
	;
		segmov	ds, dgroup, ax
		VSem	ds, [queueSemaphore]
		mov	ax, SPOOL_QUEUE_EMPTY
		jmp	exit
continue:
		mov	ds, ax			; ds -> queue
	;
	; try to find the queue, exit if we can't
	;
		mov	ax, SPOOL_QUEUE_NOT_EMPTY
		cmp	dx, -1			; check for any queue ??
		je	unlockQueue		; yes, do we're done	

		mov	es, dx			; es:si -> PrintPortInfo
		call	FindRightQueue		
		mov	ax, SPOOL_QUEUE_NOT_FOUND
		tst	bx			; check queue handle
		jz	unlockQueue		;  quit if nothing to return
	;
	; ok, now we have a valid queue, determine how many jobs are
	; in the queue and size a block to copy the info
	;
		mov	si, ds:[bx]		; ds:si -> queue block
		clr	cx			; clear job count
		mov	si, ds:[si].QI_curJob	; get handle to first

		push	si			; save handle for copy loop

countJobLoop:
		mov	si, ds:[si]		; deref JobInfoStruct
		call	checkJob
		
		jnc	countNext
		inc	cx
countNext:
		mov	si, ds:[si].JIS_next
		tst	si
		jnz	countJobLoop

		mov	ax, SPOOL_QUEUE_EMPTY
		jcxz	unlockQueue
	;
	; all done counting, calc size of block and allocate it
	;
		push	cx
		mov_tr	ax, cx			;number of ids
		shl	ax, 1			;ids are words
EC <		ERROR_C SPOOL_INVALID_QUEUE_LIST			>
		mov	cx, SPOOL_INFO_FLAGS	; memalloc flags
		call	MemAlloc
		mov	es, ax			; es -> block
		clr	di			; start at beginning of block

	;
	; now follow the chains, copying the ids as we go
	;
		pop	cx			; count
		pop	si			; restore handle to start
copyLoop:
		mov	si, ds:[si]		; dereference handle
		call	checkJob
		jnc	copyNext
		
		GetJobID	ds, si, ax
		stosw
copyNext:
		mov	si, ds:[si].JIS_next

		tst	si			; if zero, we're done
		jnz	copyLoop		; keep going
	;
	; done copying, so unlock the block and return proper info
	;
		call	MemUnlock		; unlock the info block
		mov	ax, SPOOL_OPERATION_SUCCESSFUL ; indicate all ok
unlockQueue:
		call	UnlockQueue		; release it
exit:
		.leave
		ret

checkJob:

	;
	; See if we should add this job to the list
	; ds:si - JobInfoStruct
	; ss:[dataDI] - data to pass to callback in DI
	; ss:[dataES] - data to pass to callbakc in ES
	; RETURN: carry SET to add, carry CLEAR otherwise
	;
		push	di, es
		mov	di, ss:[dataDI]
		mov	es, ss:[dataES]
		call	ss:[callback]
		pop	di, es
		retn
SpoolInfoQueueCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolInfoQueueForPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the list of jobs in the queue for this printer.
		This was written for Wizard, where there are often
		multiple printers on the same queue, and thus, the
		printer control panel needs to display a subset of the
		queue list for any given printer by checking the
		printer name of each job in the queue

CALLED BY:	SpoolGetQueueInfoForPrinter

PASS: 		dx:si - PrintPortInfo structure -- used to find queue
		es:di - printer name string

RETURN:		ax	= status of info (SpoolOpStatus enum)
				SPOOL_OPERATION_SUCCESSFUL
				SPOOL_QUEUE_EMPTY
				SPOOL_QUEUE_NOT_EMPTY
				SPOOL_QUEUE_NOT_FOUND

		if ax = SPOOL_OPERATION_SUCCESSFUL:
		cx	= number of jobs.  If cx is nonzero:
			bx	= handle of block with id's in it

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _CONTROL_PANEL
SpoolInfoQueueForPrinter	proc far
		uses	dx, di, si, ds, es
		.enter
		
		mov	ax, offset SpoolCheckJobAndPrinter
		call	SpoolInfoQueueCommon

		.leave
		ret		
SpoolInfoQueueForPrinter	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCheckJobAndPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this JobInfoStruct is destined for this printer

CALLED BY:	SpoolInfoQueueForPrinter via SpoolInfoQueueCommon

PASS:		es:di - printer name
		ds:si - JobInfoStruct

RETURN:		carry SET if printer names match, carry CLEAR otherwise

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/29/93   	Initial version.
	don	7/13/94		Added support for print-to-file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _CONTROL_PANEL
SpoolCheckJobAndPrinter	proc near
		uses	si, cx
		
		.enter

	;
	; Since we display all the print-to-file jobs in one place
	; (to simplify the Printer Control Panel), we need to ignore
	; any differences in printer name.
	;
		cmp	ds:[si].JIS_info.JP_portInfo.PPI_type, PPT_FILE
		stc
		je	done
		lea	si, ds:[si].JIS_info.JP_printerName
		clr	cx
		call	LocalCmpStrings
		stc
		je	done
		clc
done:
		.leave
		ret
SpoolCheckJobAndPrinter	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolHurryJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put a job to the beginning of the queue

CALLED BY:	GLOBAL

PASS:		CX	= print job id

RETURN:		AX	= one of the now-famous SpoolOpStatus enums

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		lock the queue, do the necc link manipulation

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Don	04/91		Now uses common code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolHurryJob	proc	far
		mov	ax, SJA_HURRY
		call	SpoolJobCommonAction	; return AX = SpoolOpStatus
		ret
SpoolHurryJob	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolDelayJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put a job to the end of the queue

CALLED BY:	GLOBAL

PASS:		CX	= job id of job to delay

RETURN:		AX	= one of the now-famous SpoolOpStatus enums

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		lock the queue, do the necc link manipulation

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Don	04/91		Now uses common code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolDelayJob	proc	far
		mov	ax, SJA_DELAY
		call	SpoolJobCommonAction	; return AX = SpoolOpStatus
		ret
SpoolDelayJob	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolModifyPriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify the priority of a queue's thread

CALLED BY:	GLOBAL

PASS:		CX	= job to modify the priority for
		DL	= ThreadPriority: new priority to set

RETURN:		AX	= SpoolOpStatus code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Find the queue, then bump the thread's priority

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolModifyPriority proc far
		mov	ax, SJA_PRIORITY
		call	SpoolJobCommonAction	; return AX = SpoolOpStatus
		ret
SpoolModifyPriority endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolJobCommonAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the common work of accessing a job in a print queue

CALLED BY:	INTERNAL
	
PASS:		AX	= SpoolJobAction enum
				SJA_HURRY
				SJA_DELAY
				SJA_PRIORITY
		CX	= Job ID
		DX	= Other data

RETURN:		AX	= SpoolOpStatus

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

spoolJobActionTable	label	word
	nptr	offset SpoolJobCommonHurry
	nptr	offset SpoolJobCommonDelay
	nptr	offset SpoolJobCommonModifyPriority

SpoolJobCommonAction	proc	near
		uses	bx, di, si, ds
		.enter

		; get the handle of the PrintQueue, check validity
		;
		xchg	ax, si			; SpoolJobAction => SI
		call	LockQueue		; lock it down, get pointer
		jc	queueEmpty
		mov	ds, ax			; ds -> queue

		; map the job ID to a valid job handle
		;
		call	MapJobIDtoHandle	; bx = job handle
		tst	bx			; if zero, something is wrong
		jz	jobNotFound

		; Perform the specific action
		;
		call	cs:[spoolJobActionTable][si]
done:
		call	UnlockQueue		; release it
exit:
		.leave
		ret

		; there is no queue, exit
queueEmpty:
		mov	ax, dgroup		; get ds -> dgroup
		mov	ds, ax			;	
		VSem	ds, [queueSemaphore]	; release it
		mov	ax, SPOOL_QUEUE_EMPTY	; get ready for possible failure
		jmp	exit

		; there is not job by that name
jobNotFound:
		mov	ax, SPOOL_JOB_NOT_FOUND
		jmp	done
SpoolJobCommonAction	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolJobCommonHurry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The actual code the moves a print job to the front (next
		position to print) in the queue

CALLED BY:	SpoolJobCommonAction
	
PASS:		DS	= Segment of print queue
		BX	= Job chunk handle

RETURN:		AX	= SpoolOpStatus
				SPOOL_OPERATION_SUCCESSFUL
				SPOOL_OPERATION_FAILED

DESTROYED:	BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/10/91	Initial version (from Jim)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolJobCommonHurry	proc	near
		.enter

		; find the queue that the job is in, and do the right thing

		mov	si, ds:[bx]		; ds:si -> job
		mov	di, ds:[si].JIS_queue	; 
		mov	di, ds:[di]		; ds:di -> queue
		mov	di, ds:[di].QI_curJob	; get handle of active job
		mov	di, ds:[di]		; ds:di -> first job in queue
		cmp	ds:[di].JIS_next, bx	; if already there, done
		mov	ax, SPOOL_OPERATION_FAILED
		je	done
		mov	ax, bx			; ax = our job's handle

		; head job -> us, ax -> job that used to follow head job 

		xchg	ax, ds:[di].JIS_next	; ax = job to follow us

		; we -> job that used to follow head job, 
		; ax -> job that used to follow us

		xchg	ax, ds:[si].JIS_next	; our job linked in. 

		; follow chain til we get to the job that was pointing to 
		; us and set his link to our old link
followLoop:
		mov	si, ds:[si].JIS_next	; start following chain til 
		mov	si, ds:[si]		; deref next handle
		cmp	ds:[si].JIS_next, bx	; did we find it ?
		jne	followLoop		;  yes, deal with it
		mov	ds:[si].JIS_next, ax	; unlink us from where we were
		mov	ax, SPOOL_OPERATION_SUCCESSFUL
done:
		.leave
		ret
SpoolJobCommonHurry	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolJobCommonDelay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The action code to delay a print job to the end of the queue

CALLED BY:	SpoolJobCommonAction
	
PASS:		DS	= Segment of print queue
		BX	= Job chunk handle

RETURN:		AX	= SpoolOpStatus
				SPOOL_OPERATION_SUCCESSFUL
				SPOOL_OPERATION_FAILED

DESTROYED:	BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/10/91	Initial version (from Jim)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolJobCommonDelay	proc	near

		; follow the links til we get to the job that points to us
		;
		mov	si, ds:[bx]		; ds:si -> job
		cmp	ds:[si].JIS_next, 0	; if already at end, quit
		je	fail
		mov	ax, ds:[si].JIS_next	; get job that follows us
		mov	di, ds:[si].JIS_queue	; 
		mov	di, ds:[di]		; ds:di -> queue
		mov	di, ds:[di].QI_curJob	; get handle of active job
		cmp	di, bx			; if they want to delay this one
		je	fail			;  they're out of luck
findLoop:
		mov	di, ds:[di]		; ds:di -> next job in queue
		cmp	ds:[di].JIS_next, bx	; is the next job us ??
		jne	findLoop
		mov	ds:[di].JIS_next, ax	; unlink ourselves

		; now find the end of the queue
		;
		mov	di, ax			; keep following the links
findEndLoop:
		mov	di, ds:[di]		; get next one 
		cmp	ds:[di].JIS_next, 0	; found end yet ?
		je	foundEnd
		mov	di, ds:[di].JIS_next	; get next one
		jmp	findEndLoop

		; Failure - return proper SpoolOpStatus
		;
fail:
		mov	ax, SPOOL_OPERATION_FAILED
		ret

		; We found the end. Link me in and clean up
		;
foundEnd:
		mov	ds:[di].JIS_next, bx	; link ourselves in
		mov	ds:[si].JIS_next, 0	; set ourselves to be last
		mov	ax, SPOOL_OPERATION_SUCCESSFUL
		ret
SpoolJobCommonDelay	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolJobCommonModifyPriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The guts of the priority modification code for a print job

CALLED BY:	SpoolJobCommonAction
	
PASS:		DS	= Segment of print queue
		BX	= Job chunk handle
		DL	= ThreadPriority: new priority to set

RETURN:		AX	= SpoolOpStatus
				SPOOL_OPERATION_SUCCESSFUL

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/10/91	Initial version (from Jim)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolJobCommonModifyPriority	proc	near
		.enter

		; dereference the job handle and get the handle for the queue
		; that this job belongs in

		mov	bx, ds:[bx]		; ds:bx -> job
		mov	bx, ds:[bx].JIS_queue	; get the queue handle
		mov	bx, ds:[bx]		; get pointer to queue info
		mov	bx, ds:[bx].QI_thread	; get thread handle
		mov	al, dl			; pass new priority
		cmp	al, PRIORITY_STANDARD	; limit it to this
		ja	priorityChecked
		mov	al, PRIORITY_STANDARD
priorityChecked:
		mov	ah, mask TMF_BASE_PRIO	; set right bit
		call	ThreadModify		; do it to it
		mov	ax, SPOOL_OPERATION_SUCCESSFUL

		.leave
		ret
SpoolJobCommonModifyPriority	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolQueueCheckJobsWantingWarning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look through all the queues to see if there's one job that
		wants the user warned if s/he chooses to detach while it's
		queued.

CALLED BY:	(EXTERNAL) SpoolApplicationDetachConfirm
PASS:		nothing
RETURN:		carry set if found a job that wants to warn the user
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolQueueCheckJobsWantingWarning proc	far
		uses	ds, ax, bx, si
		.enter
		call	LockQueue
		cmc
		jnc	done
		mov	ds, ax

		mov	bx, ds:[PQ_firstQueue]
queueLoop:
		tst_clc	bx
		jz	done
		mov	bx, ds:[bx]
		mov	si, ds:[bx].QI_curJob
jobLoop:
		tst	si
		jz	nextQueue
		mov	si, ds:[si]
	;
	; If the job will be saved, we want to warn the user that it's around.
	; 
	CheckHack <SSJA_SAVE_JOB eq 0 and width SO_SHUTDOWN_ACTION eq 1>
		test	ds:[si].JIS_info.JP_spoolOpts, mask SO_SHUTDOWN_ACTION
		stc
		jz	done
		
		mov	si, ds:[si].JIS_next
		jmp	jobLoop

nextQueue:
		mov	bx, ds:[bx].QI_next
		jmp	queueLoop

done:
		lahf			; preserve carry flag, please
		call	UnlockQueue
		sahf
		.leave
		ret
SpoolQueueCheckJobsWantingWarning endp

QueueManagement	ends
