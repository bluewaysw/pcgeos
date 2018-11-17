COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processLockQueue.asm

AUTHOR:		Jim DeFrisco, 26 March 1990

ROUTINES:
	Name			Description
	----			-----------
	LockQueue		lock the print queue
	UnlockQueue		unlock the print queue

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/26/90		Initial revision


DESCRIPTION:
	This file contains the routines to lock and unlock the print queue.
	They're placed in idata since they are small and are needed by both
	the QueueManagement code and the PrintThread code.
		
	$Id: processLockQueue.asm,v 1.1 97/04/07 11:11:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks the PrintQueue

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		carry	- set if problem in locking (like bad queue handle)
		ax	- segment address of locked/owned queue (if carry clear)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lock the printqueue, ensuring single access
		validates queue LMem heap also

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockQueue	proc	far
		uses	ds, bx
		.enter

		mov	ax, dgroup
		mov	ds, ax
		PSem	ds,[queueSemaphore]	; ensure singular access
		mov	bx, ds:[queueHandle]	; get handle
		tst	bx			; see if anything there yet
		stc				; assume the worst
		jz	exit			; no handle - quit with error
		call	MemPLock		; lock it down
EC <		mov	ds, ax						>
EC <		call	ECLMemValidateHeap				>
		clc
exit:
		.leave
		ret
LockQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks the PrintQueue

CALLED BY:	INTERNAL

PASS:		nothing.  Assumes that the caller has the lock

RETURN:		nothing

DESTROYED:	ds	(set to point at Spool dgroup)

PSEUDO CODE/STRATEGY:
		unlock the printqueue

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		ds is left trashed since it could have been pointing to
		the PrintQueue, so we don't want to return an invalid segment.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnlockQueue	proc	far
		uses	ax, bx
		.enter

		mov	ax, dgroup
		mov	ds, ax
		mov	bx, ds:[queueHandle]	; get handle
		tst	bx			; if zero, nothing to unlock
		jz	releaseQ
		call	MemUnlockV		; unlock it down
releaseQ:
		VSem	ds,[queueSemaphore]	; release it 
		.leave
		ret
UnlockQueue	endp

idata	ends
