COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Process
FILE:		processDualThread.asm

AUTHOR:		Joon Song, Apr 13, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/13/95   	Initial revision


DESCRIPTION:
	
		

	$Id: processDualThread.asm,v 1.1 97/04/07 11:11:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGraphics	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwathNoBlocking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap on another thread

CALLED BY:	GLOBAL

PASS:		bx	- PState handle
		dx.cx	- VM file and block handle for Huge bitmap
RETURN:		carry	- set if some error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _DUAL_THREADED_PRINTING	;----------------------------------------------

PrintSwathNoBlocking	proc	far
curJob	local	SpoolJobInfo
	uses	ax,cx,si,di,ds,es
	.enter	inherit

	; Can we print using print thread?

	call	LockQueue
	mov	ds, ax
	mov	si, curJob.SJI_qHan	; get chunk handle of queue
	mov	si, ds:[si]		; ds:si <- QueueInfo
	mov	si, ds:[si].QI_printThreadInfo
	call	UnlockQueue
	tst	si			; si <- PrintThreadInfo block handle
	jnz	otherThread

	; Print it ourself

	mov	di, DR_PRINT_SWATH
	call	curJob.SJI_pDriver
	jmp	done

otherThread:
	; Wait for previous swath to finish

	xchg	bx, si			; bx <- PrintThreadInfo, si <- PState
	call	MemDerefDS

	mov	bx, ds:[PTI_printSem]
	call	ThreadPSem
	mov	bx, ds:[PTI_dataSem]
	call	ThreadPSem

	clr	ax
	xchg	ah, ds:[PTI_errorFlags]
	sahf
	jnc	noError

	call	ThreadVSem
	mov	bx, ds:[PTI_printSem]
	call	ThreadVSem
	jmp	done			; carry set

noError:
	; Now print using print thread

	mov	ds:[PTI_pstate], si
	movdw	ds:[PTI_bitmap], dxcx
	movdw	ds:[PTI_driverEntry], curJob.SJI_pDriver, ax
	call	ThreadVSem		; PTI_dataSem
done:
	.leave
	ret
PrintSwathNoBlocking	endp

endif	; _DUAL_THREADED_PRINTING ---------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintThreadPrintSwaths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print swaths

CALLED BY:	AllocDeviceQueue via ThreadCreate

PASS:		ds = es = owning geode's dgroup
		cx	= PrintThreadInfo block handle
		ax, bx	= undefined
		dx, bp	= 0
		si	= owning geode handle
		di	= LCT_NEW_CLIENT_THREAD
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _DUAL_THREADED_PRINTING	;----------------------------------------------

PrintThreadPrintSwaths	proc	far

	; Print swaths until we're done printing.

	mov	bx, cx			; bx <- PrintThreadInfo block handle
	call	MemDerefDS
	push	bx			; save PrintThreadInfo block handle

swathLoop:
	cmp	ds:[PTI_status], PTIS_EXIT
	je	exit

	; Do we have a swath ready to print?

	mov	bx, ds:[PTI_dataSem]
	call	ThreadPSem
	clrdw	dxcx
	xchgdw	dxcx, ds:[PTI_bitmap]
	mov	bp, ds:[PTI_pstate]
	call	ThreadVSem

	tstdw	dxcx
	jnz	printSwath

	mov	ax, 15			; sleep for 0.25 seconds
	call	TimerSleep
	jmp	swathLoop

printSwath:
	; Got swath.  Print it.

	mov	di, DR_PRINT_SWATH
	mov	bx, bp
	call	ds:[PTI_driverEntry]

	lahf
	mov	ds:[PTI_errorFlags], ah

	mov	bx, ds:[PTI_printSem]
	call	ThreadVSem
	jmp	swathLoop

exit:
	mov	bx, ds:[PTI_dataSem]
	call	ThreadFreeSem

	mov	bx, ds:[PTI_printSem]
	call	ThreadFreeSem

	pop	bx			; restore PrintThreadInfo block handle
	call	MemFree
	clr	cx, dx, bp, si		; setup arguments for ThreadDestroy
	ret
PrintThreadPrintSwaths	endp

endif	; _DUAL_THREADED_PRINTING ---------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintBlockOnPrintThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Block until print thread is finished printing

CALLED BY:	PrintGraphicsPage
PASS:		inherit stack frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	7/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _DUAL_THREADED_PRINTING	;----------------------------------------------

PrintBlockOnPrintThread	proc	near
curJob	local	SpoolJobInfo
	uses	ax,bx,ds
	.enter	inherit

	call	LockQueue
	mov	ds, ax
	mov	bx, curJob.SJI_qHan	; get chunk handle of queue
	mov	bx, ds:[bx]		; ds:bx <- QueueInfo
	mov	bx, ds:[bx].QI_printThreadInfo
	call	UnlockQueue
	tst	bx			; bx <- PrintThreadInfo block handle
	jz	done

	; Wait for print thread to finish

	call	MemDerefDS
	mov	bx, ds:[PTI_printSem]
	call	ThreadPSem
	call	ThreadVSem
done:
	.leave
	ret
PrintBlockOnPrintThread	endp

endif	; _DUAL_THREADED_PRINTING ---------------------------------------------

PrintGraphics	ends
