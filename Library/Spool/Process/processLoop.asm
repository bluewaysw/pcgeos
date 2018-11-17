COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		System Spooler
FILE:		processLoop.asm

AUTHOR:		Jim DeFrisco, 26 March 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/26/90		Initial revision


DESCRIPTION:
	This file contains the code to implement the spooler thread loop

	$Id: processLoop.asm,v 1.1 97/04/07 11:11:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolThreadBirth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called by ThreadCreate() for a new spool thread

CALLED BY:	GLOBAL

PASS:		CX	= chunk handle of queue

RETURN:		never returns

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolThreadBirth	proc	far
		call	SpoolerLoop		; loop 'til no more jobs
		clr	cx, dx
		jmp	ThreadDestroy		; exit this thread
SpoolThreadBirth	endp

idata		ends



PrintThread	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolerLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the starting point for the threads that are 
		associated with each queue.

CALLED BY:	INTERNAL

PASS:		cx	- chunk handle of queue

RETURN:		never returns

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Just loop around getting new jobs to print;
		if no more jobs
		    call library routine to get rid of us.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolerLoop	proc	far
curJob		local	SpoolJobInfo	; all we need to process this job
heapResv	local	hptr.HandleReservation
		.enter
	
		; save the queue handle, we'll need it later.  

		mov	curJob.SJI_qHan, cx
		mov	curJob.SJI_sHan, 0	; init these for use as
		mov	curJob.SJI_pdHan, 0	;  flags
		mov	curJob.SJI_prev_pdHan, 0	;  
if _PRINTING_DIALOG
		mov	curJob.SJI_prDialogAlready, 0
endif
		; Before we start printing, check to see if we should
		; wait (this feature is used by the "Print to Screen"
		; application).

		segmov	ds, cs, cx
		mov	si, offset spoolCatString
		mov	dx, offset waitKeyString
pauseLoop:
		clr	ax			; assume FALSE
		call	InitFileReadBoolean	
		tst	ax
		jz	startPrinting
		mov	ax, 60 * 15		; sleep for 15 seconds
		call	TimerSleep
		jmp	pauseLoop
startPrinting:
		call	GeodeGetProcessHandle
		mov	cx, SPOOL_STANDARD_RESERVATION
		call	GeodeRequestSpace
		mov	heapResv, bx
		jnc	resvOK

		mov	cx, SERROR_RESERVATION_ERROR
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox
		call	StoppedByError
removeAgain:
		call	RemoveJob
		jnc	removeAgain
		jmp	jumpOffBridge

resvOK:
		; allocate a PState for use in printing.  We'll re-use this
		; one for all the print jobs

		mov	ax, (size PState) + (size JobParameters)
		mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE 
		call	MemAlloc		; alloc the pstate
		mov	curJob.SJI_pstate, bx	; save handle

		; This is the main spooler loop.  Lock the queue and get
		; the next job in the queue.  Copy the info locally, so
		; we don't have the PrintQueue owned too long. Load the
		; drivers from fixed memory to minimize the problems with
		; locked blocks above the fixed part of the heap. If there 
		; are no jobs left, then just exit and commit hari-kari
spoolLoop:
		call	GetJobInfo		; copy job info to local space
		call	LoadPrinterDriver	; load in the driver
		jc	nextJob			; some problem...bail
		call	LoadPortDriver
		jc	nextJob			; some problem...bail
		call	PrintFile		; print the file
nextJob:
		call	RemoveJob		; get it out of there
		jnc	spoolLoop		; do the next one
						; else exit the thread
						; in this case the PrintQueue
						; is not unlocked

;-------------------------------------------------------------------------
;		Death, death, death
;-------------------------------------------------------------------------

		; release the PState that we allocated earlier

		mov	bx, curJob.SJI_pstate	; get handle
		call	MemFree			; biff it

		; release the heap Reservation

		mov	bx, heapResv
		call	GeodeReturnSpace
jumpOffBridge:

if _DUAL_THREADED_PRINTING
		mov	di, curJob.SJI_qHan
		mov	di, ds:[di]
		clr	bx
		xchg	bx, ds:[di].QI_printThreadInfo
		tst	bx
		jz	noPTI

		push	ds
		call	MemDerefDS			; tell print thread to
		mov	ds:[PTI_status], PTIS_EXIT	;  exit as well
		pop	ds
noPTI:
endif

		; one less print queue.  If last one, REALLY die.

		dec	ds:[PQ_numQueues]	; one less queue
		jz	realFieryDeath		; whoa! biff the whole shabang

		; still some-one printing, leave the block alone
		; but biff the queue and the thread.  First we need to
		; unlink the queue from the queue list

		mov	ax, ds:[si].QI_next	; get next queue handle
		mov	cx, curJob.SJI_qHan	; get our handle
		mov	bx, ds:[PQ_firstQueue]	; get head of queue list
		cmp	bx, cx			; see if we were head job
		jne	followQueues		; just store our successor there
		mov	ds:[PQ_firstQueue], ax	; store our next link as first
		jmp	continueDeath
followQueues:
		mov	di, ds:[bx]		; ds:di -> next queue
		mov	bx, ds:[di].QI_next	; get next link
		cmp	cx, bx			; find it yet ?
		jne	followQueues
		mov	ds:[di].QI_next, ax	; store our link there

		; we've unlinked the queue, so now kill it and the thread
continueDeath:
		mov	ax, cx			; get q handle in ax
		call	LMemFree		; free the chunk
goodbyeSweetWorld:
		call	UnlockQueue		; release the print queue
;		mov	ax, dgroup		; ds -> idata
;		mov	ds, ax
;		VSem	ds, [queueSemaphore]	; V the semaphore

		; before we call it quits for good, be sure to take the 
		; supporting cast with us.

		mov	bx, curJob.SJI_sHan	; free the port driver
		tst	bx			; if zero, don't try to free
		jz	freePrinterDriver
		call	GeodeFreeDriver		; all done
freePrinterDriver:
		mov	bx, curJob.SJI_pdHan	; free the print driver
		tst	bx			; if zero, don't try to free
		jz	exitThread
		call	GeodeFreeDriver		; all done

		; that's it.  it's a wrap.
exitThread:
		;
		; NOTE: we don't call ThreadDestroy() here, but let
		; our caller back in fixed code do it.  If it is called
		; here, then ResourceCallInt() has been called through
		; but never returned to, meaning a lock is left on
		; this code resource which won't go away until the
		; user exits GEOS.
		;
		.leave
		ret

		; this is what we call ultimate death.  All the jobs are done
		; in this queue.  There are no more queues left.  What is 
		; there to live for ?
realFieryDeath:
		mov	ax, dgroup
		mov	ds, ax
		clr	bx			; store zero as queue handle
		xchg	bx, ds:[queueHandle]	; get handle of mem block
		call	MemFree			; free the block
		jmp	goodbyeSweetWorld

SpoolerLoop	endp

spoolCatString	char	"spool", 0
waitKeyString	char	"noPrinting", 0

PrintThread	ends



PrintInit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadPrinterDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load in the right printer driver

CALLED BY:	INTERNAL
		SpoolerLoop

PASS:		curJob 

RETURN:		carry	- set if some unrecoverable problem loading driver

DESTROYED:	ax,bx,cx,dx,di,es

PSEUDO CODE/STRATEGY:
		Load in the driver.  If any trouble, notify the user

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadPrinterDriver proc	far
curJob          local   SpoolJobInfo
		.enter  inherit

		; just try to load in the printer driver

		push	si
		segmov  ds, ss, si              ; ds:si -> driver category
		lea     si, curJob.SJI_info.JP_printerName
		ConvPrinterNameToIniCat
 		mov	bx, curJob.SJI_pstate	; PState handle -> BX
 		mov	cx, PRINT_PROTO_MAJOR	; protocol -> CX.DX
 		mov	dx, PRINT_PROTO_MINOR
		mov	ax, SP_PRINTER_DRIVERS
		call    UserLoadExtendedDriver	; load the driver
		ConvPrinterNameDone
		pop	si
		jc	loadProblem             ; found it

		; loaded successfully, record some info.  Unload the previous
		; one

		mov	curJob.SJI_pdHan, bx	; save away the handle

		; we should also save it in the print queue so we can biff
		; it later should this thread be killed.

		push	ds,ax,si
		call	LockQueue		; lock it down
EC <		ERROR_C	SPOOL_INVALID_PRINT_QUEUE		>
		mov	ds, ax			; ds -> queue
		mov	si, curJob.SJI_qHan	; *ds:si -> QueueInfo
		mov	si, ds:[si]		; dereference it
		mov	ds:[si].QI_pdHan, bx	; save away the handle
		call	UnlockQueue		; 
		pop	ds,ax,si

		mov	ax, bx			; save handle
		xchg	curJob.SJI_prev_pdHan, bx ; get old one
		tst	bx			; any old one around ?
		jz	getStrategyRoutine		;  no, all done
		call	GeodeFreeDriver		;  yes, free it
getStrategyRoutine:
		mov	bx, ax			; restore handle
		call	GeodeInfoDriver		; get pointer to info block
		mov	ax, ds:[si].DIS_strategy.offset
		mov	bx, ds:[si].DIS_strategy.segment
		mov	curJob.SJI_pDriver.offset, ax
		mov	curJob.SJI_pDriver.segment, bx
done:
		.leave
		ret

		; trouble loading driver.  notify user and quit with error
loadProblem:
		mov     cx, SERROR_NO_PRINT_DRIVER ; put up error message
		mov     dx, curJob.SJI_qHan
		call    SpoolErrorBox           ;
		stc                             ; signal error
		jmp	done

LoadPrinterDriver endp

PrintInit	ends
