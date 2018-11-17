COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Network extensions
MODULE:		Socket library
FILE:		socketMisc.asm

AUTHOR:		Eric Weber, May 25, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT SocketEntry             Entry point for library

    INT SocketSetupTimeout      Convert a delta timeout value into an
				absolute time

    INT SocketPTimedSem         P a semaphore in an environment with a
				timeout

    INT SocketGetTimeout        Compute time remaining in a timeout

    INT SocketControlStartRead  Start reading the control block

    INT SocketControlEndRead    Stop reading the control block

    INT SocketControlStartWrite Start an update to the control block

    INT SocketControlEndWrite   End an update to the control block

    INT SocketControlReadToWrite 
				Upgrade our control block lock

    INT SocketControlWriteToRead 
				downgrade our control block lock

    INT SocketControlSuspendLock 
				Release either a read or write lock

    INT SocketControlResumeLock Restore the lock on the control segment
				suspended earlier

    EXT SocketCheckQueue        See if there are any packets in a queue

    EXT SocketEnqueue           Put a packet onto a queue

    EXT SocketDequeuePackets    Pop some packets off the queue

    EXT SocketAllocQueue        Allocate a data queue for a socket

    EXT SocketFreeQueue         Free a socket's data queue

    GLB DomainNameToIniCat      Translate a domain name (DBCS) to a .INI
				category name (SBCS)

    GLB DomainNameToIniCatLow   Translate a domain name (DBCS) to a .INI
				category name (SBCS)

    GLB DomainNameDone          Done with domain .INI category name from
				DomainNameToIniCat()

    GLB DomainNameDoneLow       Done with domain .INI category name from
				DomainNameToIniCat()

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/94   	Initial revision


DESCRIPTION:
	Miscelaneous routines
		

	$Id: socketMisc.asm,v 1.25 97/04/21 20:49:46 simon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SocketControlLockType	etype	word
SCLT_READ	enum	SocketControlLockType
SCLT_WRITE	enum	SocketControlLockType

SocketQueues	segment lmem LMEM_TYPE_GENERAL, mask LMF_RETURN_ERRORS

SocketQueues	ends

udata	segment
lockType	SocketControlLockType
udata	ends

UtilCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for library

CALLED BY:	EXTERNAL (kernel)
PASS:		di	= LibraryCallType
RETURN:		carry	= set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketEntry	proc	far
		ForceRef SocketEntry
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	; get dgroup
	;
		mov	bx, handle dgroup
		call	MemDerefDS
	;
	; initialize the library on ATTACH
	;
		cmp	di, LCT_ATTACH
		jne	notAttach
		call	PacketAttach
		jc	done
		call	LoadAttach
		call	ControlAttach
		call	SocketGetInitParameters
		jmp	done
	;
	; clean up after sloppy apps on CLIENT_EXIT
	;
notAttach:
		cmp	di, LCT_CLIENT_EXIT
		jne	notClientDetach
		call	FreeClientSockets
	;
	; free everything on DETACH
	;
notClientDetach:
		cmp	di, LCT_DETACH
		jne	done
		call	PacketDetach
done:
		.leave
		ret
SocketEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetInitParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read assorted parameters from init file

CALLED BY:	SocketEntry
PASS:		ds	- socket dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetInitParameters	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; read driver-close-delay
	;
		mov	si, offset ds:[socketCategory]
		mov	cx, ds
		mov	dx, offset ds:[driverCloseDelayKey]
		mov	ax, DEFAULT_DRIVER_CLOSE_DELAY	; default value
		call	InitFileReadInteger	; ax = time (seconds)
		mov	cx, 60			; # ticks per second
		mul	cx
		jnc	delayInRange
		mov	ax, 0xffff		; value in .INI too big, use
						;  max. possible value
delayInRange:
		mov	ds:[driverCloseDelay], ax
	;
	; read send timeout
	;
		mov	cx, ds
		mov	dx, offset ds:[sendTimeoutKey]
		mov	ax, DEFAULT_SEND_TIMEOUT
		call	InitFileReadInteger
		mov	cx, 60
		mul	cx
		jnc	timeoutInRange
		mov	ax, 0xffff		; value in .INI too big, use
						;  max. possible value
		clc
timeoutInRange:
		mov	ds:[sendTimeout], ax

		.leave
		ret
SocketGetInitParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSetupTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a delta timeout value into an absolute time

CALLED BY:	(INTERNAL) SocketAccept, SocketCheckReady, SocketConnect,
		SocketRecvLow
PASS:		ss:ax	- address to write timeout
		ss:bp	- timeout in ticks
			0 to never block
			SOCKET_NO_TIMEOUT to block forever
RETURN:		ss:ax	- initialized to drop dead time
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.assert SOCKET_NO_TIMEOUT eq -1
; any value other then -1 will break the following code

SocketSetupTimeout	proc	far
		uses	ax,bx,cx,dx,bp,di
		.enter
	;
	; if bp is -1, timeout should be -1 also
	;
		mov	bp, ss:[bp]
		mov	di, ax
		mov	ss:[di].low, bp
		mov	ss:[di].high, bp
		cmp	bp, SOCKET_NO_TIMEOUT
		je	done
	;
	; don't allow timeouts > 32767
	;
EC <		tst	bp						>
EC <		ERROR_S EXCESSIVE_TIMEOUT				>
	;
	; compute the time at which to time out
	;
		call	TimerGetCount		; bxax = time since startup
EC <		tstdw	bxax						>
EC <		ERROR_Z TIMEOUT_FAULT					>
		clr	dx
		mov	cx, bp			; dxcx = timeout interval
		adddw	bxax, dxcx		; bxax = drop dead time
	;
	; assuming it's reasonable, write it out
	;
EC <		ERROR_O EXCESSIVE_TIMEOUT				>
EC <		cmpdw	bxax, SOCKET_NO_TIMEOUT				>
EC <		ERROR_E	TIMEOUT_FAULT					>
		movdw	ss:[di], bxax	; remember timeout info
done:
		.leave
		ret
SocketSetupTimeout	endp

FixedCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketPTimedSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	P a semaphore in an environment with a timeout

CALLED BY:	(INTERNAL) SocketCheckReady, SocketConnect,
		SocketLockForCreateLink, SocketPreAccept, SocketRecvLow
PASS:		bx	- handle of semaphore
		ss:cx	- time at which to time out
RETURN:		carry	- set if timed out
		ax	- SE_TIMED_OUT if carry set, otherwise preserved
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/94    	Initial version
	brianc	10/22/98	Moved into fixed code for resolver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketPTimedSem	proc	far
		uses	cx,dx,bp
		.enter
EC <		Assert fptr   sscx					>
	;
	; first make sure we really have a timeout
	;
		mov	dx,ax			; save initial ax 
		jcxz	noTimeout
		mov	bp,cx
		cmpdw	ss:[bp], SOCKET_NO_TIMEOUT
		je	noTimeout
	;
	; we do, so figure out how much time we have left
	;
		push	bx
		call	TimerGetCount		; bxax = time
		subdw	bxax, ss:[bp]		; -bxax = time remaining
		jge	timeout			; we're out of time
		negdw	bxax			; bxax = time remaining
	;
	; if its more then a word, we did something wrong
	;
EC <		tst	bx						>
EC <		ERROR_NZ EXCESSIVE_TIMEOUT				>
	;
	; go ahead and P the semaphore
	;
		mov	cx, ax
		pop	bx
		call	ThreadPTimedSem
	;
	; check the outcome of the P operation
	;
		tst	ax			; errors?
		clc
		jz	done			; if not, exit
EC <		cmp	ax, SE_TIMEOUT					>
EC <		ERROR_NE UNEXPECTED_SEMAPHORE_ERROR			>
		stc
		mov	dx, SE_TIMED_OUT	; semaphore timed out
done:
		mov	ax,dx
		.leave
		ret
	;
	; don't bother looking at the semaphore - the timeout has already
	; expired
	;
timeout:
		pop	bx
		stc
		mov	dx, SE_TIMED_OUT
		jmp	done
	;
	; the user wants to wait forever...
	;
noTimeout:
		push	ax
		call	ThreadPSem		; ax = SemaphoreError
EC <		tst	ax						>
EC <		ERROR_NZ UNEXPECTED_SEMAPHORE_ERROR			>
		pop	ax
		clc
		jmp	done
SocketPTimedSem	endp

FixedCode ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute time remaining in a timeout

CALLED BY:	(INTERNAL) SocketCreateLink, SocketDataConnect,
		SocketPostDataAccept
PASS:		ss:cx   - time at which to time out
RETURN:		cx	- ticks remaining util timeout
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetTimeout	proc	far
		uses	ax,bx,bp
		.enter
	;
	; first make sure we really have a timeout
	;
		jcxz	noTimeout
		mov	bp,cx
		mov	cx, -1
		cmpdw	ss:[bp], SOCKET_NO_TIMEOUT
		je	done
	;
	; we do, so figure out how much time we have left
	;
		call	TimerGetCount		; bxax = time
		subdw	bxax, ss:[bp]		; -bxax = time remaining
		jge	timeout			; we're out of time
		negdw	bxax			; bxax = time remaining
	;
	; if its more then a word, we did something wrong
	;
EC <		tst	bx						>
EC <		ERROR_NZ EXCESSIVE_TIMEOUT				>
	;
	; return value to user
	;
		mov	cx, ax
		clc
done:
		.leave
		ret
noTimeout:
		mov	cx,-1
		clc
		jmp	done
timeout:
		stc
		jmp	done
SocketGetTimeout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketControlStartRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start reading the control block

CALLED BY:	(INTERNAL) ECCheckOutgoingPacket, ECCheckSocket,
		ReceiveLinkDataPacket, SocketCheckListen,
		SocketCheckMediumConnection, SocketDataPacket,
		SocketGetPeerName, SocketGetSocketName, SocketLinkPacket,
		SocketRecv, SocketRecvLow, SocketSend
PASS:		nothing
RETURN:		ds	- control segment
DESTROYED:	nothing
SIDE EFFECTS:	may block

PSEUDO CODE/STRATEGY:
	Reading is permitted as long as no thread is currently modifying
	the data structures.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketControlStartRead	proc	far
		uses	ax,bx,es
		pushf
		.enter
	;
	; lock the control segment
	;
		mov	bx, handle SocketControl
		call	MemLockShared
		mov	ds,ax
	;
	; record lock
	;
		mov	bx, handle dgroup
		call	MemDerefES
		mov	es:[lockType], SCLT_READ
done::
		.leave
		popf
		ret
		
SocketControlStartRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketControlEndRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop reading the control block

CALLED BY:	(INTERNAL) ECCheckOutgoingPacket, ECCheckSocket,
		ReceiveLinkDataPacket, SocketCheckListen,
		SocketCheckMediumConnection, SocketDataPacket,
		SocketLinkGetMediumForLink, SocketLinkPacket,
		SocketPassOption, SocketQueryAddress, SocketRecv,
		SocketRecvLow, SocketSend
PASS:		nothing
RETURN:		nothing (flags preserved)
DESTROYED:	if EC and segment error checking on, and either DS or ES
		is the control segment, it will be replaced by NULL_SEGMENT
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If this is the last reader, allow writers in again.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketControlEndRead	proc	far
		uses	bx
		.enter
	;
	; unlock the control block
	;
		mov	bx, handle SocketControl
		call	MemUnlockShared
		.leave
		ret
SocketControlEndRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketControlStartWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start an update to the control block

CALLED BY:	(INTERNAL) CloseLinkThread, ConnectionControlReply,
		FreeListenQueueCallback, ReceiveUrgentDataPacket,
		RemoveDomainThread, SocketAccept, SocketActivateLoadOnMsg,
		SocketAddDomain, SocketAddLoadOnMsgMem, SocketBind,
		SocketBindInDomain, SocketCheckMediumConnection,
		SocketCheckReady, SocketClearConnection, SocketClose,
		SocketCloseDomainMedium, SocketCloseLink, SocketCloseSend,
		SocketConnect, SocketConnectRequest,
		SocketConnectionClosed, SocketCreate, SocketCreateLink,
		SocketDataConnect, SocketDataGetInfo, SocketFullClose,
		SocketGetAddressController, SocketGetAddressMedium,
		SocketGetAddressSize, SocketGetDomainMedia,
		SocketGetSocketOption, SocketInterrupt, SocketLinkClosed,
		SocketLinkGetMediumForLink, SocketLinkOpened, SocketListen,
		SocketLoadDriver, SocketLockForCreateLink,
		SocketOpenDomainMedium, SocketPassOption,
		SocketPostDataAccept, SocketPreAccept, SocketQueryAddress,
		SocketRemoveDomainLow, SocketRemoveLoadOnMsgMem,
		SocketResolve, SocketSendClose, SocketSetSocketOption
PASS:		nothing
RETURN:		ds	- control segment
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Writing is permitted only when no other thread is reading or writing
	the control block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketControlStartWrite	proc	far
		pushf
		uses	ax,bx,es
		.enter
	;
	; lock the control block
	;
		mov	bx, handle SocketControl
		call	MemLockExcl
		mov	ds,ax
	;
	; record lock
	;
		mov	bx, handle dgroup
		call	MemDerefES
		mov	es:[lockType], SCLT_WRITE
		.leave
		popf
		ret
SocketControlStartWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketControlEndWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End an update to the control block

CALLED BY:	(INTERNAL) CloseLinkThread, ConnectionControlReply,
		FreeListenQueueCallback, ReceiveUrgentDataPacket,
		RemoveDomainThread, SocketAccept, SocketActivateLoadOnMsg,
		SocketAddDomain, SocketAddLoadOnMsgMem, SocketBind,
		SocketBindInDomain, SocketCheckMediumConnection,
		SocketCheckReady, SocketClearConnection, SocketClose,
		SocketCloseDomainMedium, SocketCloseLink, SocketCloseSend,
		SocketConnect, SocketConnectRequest,
		SocketConnectionClosed, SocketCreate, SocketCreateLink,
		SocketDataConnect, SocketDataGetInfo, SocketFullClose,
		SocketGetAddressController, SocketGetAddressMedium,
		SocketGetAddressSize, SocketGetDomainMedia,
		SocketGetPeerName, SocketGetSocketName,
		SocketGetSocketOption, SocketInterrupt, SocketLinkClosed,
		SocketLinkOpened, SocketListen, SocketLoadDriver,
		SocketLockForCreateLink, SocketOpenDomainMedium,
		SocketPostDataAccept, SocketPreAccept,
		SocketRemoveDomainLow, SocketRemoveLoadOnMsgMem,
		SocketResolve, SocketSendClose, SocketSetSocketOption
PASS:		nothing
RETURN:		nothing (flags preserved)
DESTROYED:	if EC and segment error checking on, and either DS or ES
		is the control segment, it will be replaced by NULL_SEGMENT
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketControlEndWrite	proc	far
		uses	bx
		.enter
		mov	bx, handle SocketControl
		call	MemUnlockExcl
		.leave
		ret
SocketControlEndWrite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketControlReadToWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upgrade our control block lock

CALLED BY:	(INTERNAL) ReceiveConnectionControlPacket, SocketSend
PASS:		nothing
RETURN:		ds, es	= fixed up to possibly new block location, if
			  they were pointing to the block on entry.
DESTROYED:	nothing (flags preserved)

SIDE EFFECTS:	If the block is locked shared by other threads, this
		will block and the memory block may move on the heap
		before exclusive access is granted.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketControlReadToWrite	proc	far
		uses	ax,bx,dx
		pushf
		.enter
	;
	; upgrade the lock
	;
		mov	bx, handle SocketControl
		call	MemUpgradeSharedLock
	;
	; update the lock type in dgroup
	;
		push	es
		mov	bx, handle dgroup
		call	MemDerefES
		mov	es:[lockType], SCLT_WRITE
		pop	es
		.leave
		popf
		ret
SocketControlReadToWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketControlWriteToRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	downgrade our control block lock

CALLED BY:	(INTERNAL) ReceiveConnectionControlPacket,
		SocketLinkGetMediumForLink
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketControlWriteToRead	proc	far
		uses	ax,bx
		pushf
		.enter
		mov	bx, handle SocketControl
		call	MemDowngradeExclLock
		push	es
		mov	bx, handle dgroup
		call	MemDerefES
		mov	es:[lockType], SCLT_READ
		pop	es
		.leave
		popf
		ret
SocketControlWriteToRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketControlSuspendLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release either a read or write lock

CALLED BY:	(INTERNAL) SocketEnqueue, SocketSend
PASS:		nothing
RETURN:		ax	- data for SocketControlResumeLock
DESTROYED:
	Non-EC: Nothing (flags preserved)

	EC:	Nothing (flags preserved), except, possibly for DS and ES:

		If segment error-checking is on, and either DS or ES
		is pointing to a block that has become unlocked,
		then this register will be set to NULL_SEGMENT upon
		return from this procedure. 

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketControlSuspendLock	proc	far
		pushf
		uses	bx
		.enter
	;
	; get lock type
	;
		push	es
		mov	bx, handle dgroup
		call	MemDerefES
		mov	ax, es:[lockType]
		pop	es
	;
	; unlock block
	;
		mov	bx, handle SocketControl
		call	MemUnlockShared
		
		.leave
		popf
		ret
SocketControlSuspendLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketControlResumeLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the lock on the control segment suspended earlier

CALLED BY:	(INTERNAL) SocketEnqueue, SocketSend
PASS:		ax - data from SocketControlSuspendLock
RETURN:		ds - control segment
DESTROYED:	nothing - flags preserved
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketControlResumeLock	proc	far
		pushf
		uses	ax,bx,dx,es
		.enter
	;
	; get dgroup
	;
		mov	bx, handle dgroup
		call	MemDerefES
	;
	; do the appropriate lock
	;
		mov	bx, handle SocketControl
		cmp	ax, SCLT_READ
		je	read
		call	MemLockExcl
		mov	es:[lockType], SCLT_WRITE
		jmp	pastLock
read:
		call	MemLockShared
		mov	es:[lockType], SCLT_READ
pastLock:
	;
	; return segment
	;
		mov	ds,ax
		.leave
		popf
		ret
SocketControlResumeLock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCheckQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there are any packets in a queue

CALLED BY:	(EXTERNAL) SocketCheckReadyHere, SocketRecvLow
PASS:		ds:di	- SocketInfo
RETURN:		carry	- set if queue is empty
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCheckQueue	proc	far
		uses	bx,cx,si,di,ds
		.enter
		mov	bx, handle SocketQueues
		mov	si, ds:[di].SI_dataQueue
		mov	cx, NO_WAIT
		call	QueueDequeueLock	; ds:di = element
		jc	done
		call	QueueAbortDequeue
		clc
done:
		.leave
		ret
SocketCheckQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketEnqueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put a packet onto a queue

CALLED BY:	(EXTERNAL) ReceiveDatagramDataPacket, ReceiveLinkDataPacket,
		ReceiveSequencedDataPacket
PASS:		ds:si	- SocketInfo
		cxdx	- packet
		ax	- packet size
		control block must be locked

RETURN:		carry	- set on error
		ds	- control segment
		dxcx	- size remaining in queue

DESTROYED:	nothing
SIDE EFFECTS:	may invalidate control block pointers

PSEUDO CODE/STRATEGY:
	If queue is full, will wait indefinately for it for something to
	be dequeued.  In this case, the control block will be unlocked
	and other threads can manipulate it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketEnqueue	proc	far
		uses	ax,bx,bp,di,es
		.enter
	;
	; If discard flag is set, just drop the packet, and set
	; the return values as if the queue was empty.  In fact, there
	; is probably still data in there, but since we are discarding
	; we will never actually fill the queue.
	;
		test	ds:[si].SI_flags, mask SF_DISCARD
		jz	enqueue
		movdw	axcx, cxdx
		call	HugeLMemFree
		movdw	dxcx, ds:[si].SI_maxQueueSize
		jmp	abort
	;
	; compute space remaining in queue
	;
enqueue:
		clr	bx
		adddw	ds:[si].SI_curQueueSize, bxax
		movdw	bxax, ds:[si].SI_maxQueueSize
		subdw	bxax, ds:[si].SI_curQueueSize
		jnc	sizeOK
		clrdw	bxax				; cur > max
sizeOK:
		pushdw	bxax
	;
	; find the queue
	;
		mov	si, ds:[si].SI_dataQueue
EC <		tst	si						>
EC <		ERROR_Z CORRUPT_SOCKET					>
		mov	bx, handle SocketQueues		; ^lbx:si = queue
	;
	; try to lock the queue
	;
		mov	bp,cx				; ^lbp:dx = packet
		mov	cx, RESIZE_QUEUE
		call	QueueEnqueueLock		; ds:di = element
		jc	lockFailed
	;
	; insert element and unlock
	;
		movdw	ds:[di], bpdx
		call	QueueEnqueueUnlock
	;
	; get control segment
	;
		mov	bx, handle SocketControl
		call	MemDerefDS
done:
		popdw	dxcx
abort:
		.leave
		ret
lockFailed:
	;
	; we should only be here because the queue couldn't be resized
	;
EC <		cmp	cx, QE_TOO_BIG					>
EC <		ERROR_NE UNEXPECTED_QUEUE_ERROR				>
	;
	; release control segment and lock queue
	;
		call	SocketControlSuspendLock
		mov	cx, FOREVER_WAIT
		call	QueueEnqueueLock
		movdw	ds:[di], bpdx			; write queue elt
	;
	; release queue and relock control segment
	;
		call	QueueEnqueueUnlock
		call	SocketControlResumeLock
		jmp	done
		
SocketEnqueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketDequeuePackets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop some packets off the queue

CALLED BY:	(EXTERNAL) SocketGetData
PASS:		^lbx:si	- queue
		cx	- number of packets to dequeue
RETURN:		cx	- combined size of packet chunks
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketDequeuePackets	proc	far
		uses	dx,bp,di,ds
		.enter
		clr	bp
		jcxz	done
		mov	dx,cx
top:
	;
	; pop one element from the queue
	;
		mov	cx, RESIZE_QUEUE
		call	QueueDequeueLock		; ds:di = element
		ERROR_C UNEXPECTED_QUEUE_ERROR
		movdw	axcx, ds:[di]
		call	HugeLMemFree
		add	bp,cx
		call	QueueDequeueUnlock
	;
	; repeat until done
	;
		dec	dx
		jnz	top
done:
		mov	cx,bp
		.leave
		ret
		
SocketDequeuePackets	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAllocQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a data queue for a socket

CALLED BY:	(EXTERNAL) SocketBindLow, SocketConnect, SocketDataConnect,
		SocketPostDataAccept, SocketPostLinkAccept
PASS:		ds	- control segment
		*ds:bx	- SocketInfo
RETURN:		carry set if allocation failed
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAllocQueue	proc	far
		uses	ax,bx,cx,dx,si,di
		.enter
	;
	; validate
	;
		mov	si, bx
EC <		call	ECCheckSocketLow				>
	;
	; figure out the maximum combined space of the send and receive
	; queues, in Kilobytes
	;
		mov	di, ds:[si]
EC <		tst	ds:[di].SI_maxQueueSize.high			>
EC <		ERROR_NZ UNREASONABLE_QUEUE_SIZE			>
		mov	ax, ds:[di].SI_maxQueueSize.low
		add	ax, ds:[di].SI_maxSendSize	; might overflow so...
		rcr	ax				; bring carry back in
		mov	cl, 9
		shr	ax, cl				; rotate 9 more times
		mov	cx, ax				; cx = size in KB
	;
	; There are two advantages to reserving heap space in the name
	; of the UI, rather than whatever thread we happen to be on:
	;	1. this thread may belong to a non-application geode
	;	2. we don't have to worry about changing the reservation
	;          if the socket owner changes
	;
		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo			; ax = UI geode han
	;
	; reserve heap space for the queue size determined above
	;
request::
		mov	bx, ax
		call	GeodeRequestSpace
		jnc	requestOK
		WARNING CANT_RESERVE_SPACE
		clr	ds:[di].SI_queueToken
		jmp	alloc
requestOK:
		mov	ds:[di].SI_queueToken, bx
	;
	; allocate the queue
	;
alloc:
		mov	bx, handle SocketQueues
		mov	ax, size optr			; queue of optrs
		mov	cl, INITIAL_DATA_QUEUE_LENGTH	; initial length
		mov	dx, MAX_DATA_QUEUE_LENGTH	; max length
		call	QueueLMemCreate			; ^hbx:cx = queue
		jc	failed
	;
	; store it in socket and return
	;
		mov	ds:[di].SI_dataQueue, cx
done:
		.leave
		ret
	;
	; if we couldn't allocate, return the space we reserved
	;
failed:
		mov	bx, ds:[di].SI_queueToken
		call	GeodeReturnSpace
		stc
		jmp	done
		
SocketAllocQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFreeQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a socket's data queue

CALLED BY:	SocketFreeLow, SocketDataConnect, SocketFreeLow,
		SocketRegisterConnection
PASS:		*ds:bx	- SocketInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFreeQueue	proc	far
		uses	bx,cx,si
		.enter
	;
	; check the socket
	;
EC <		mov	si, bx						>
EC <		call	ECCheckSocketLow				>
	;
	; locate the queue
	;
		mov	si, ds:[bx]
		clr	cx
		xchg	cx, ds:[si].SI_dataQueue
		jcxz	done
	;
	; clear any remaining packets
	;
		push	bx
		mov	bx, handle SocketQueues
		mov	si, cx
		mov	cx, SEGMENT_CS
		mov	dx, offset SocketFreeQueueCallback
		call	QueueEnum
	;
	; free the queue
	;
		mov	cx, si			; ^lbx:cx = queue
		call	QueueLMemDestroy
	;
	; release any reservations
	;
		pop	bx			; *ds:bx = socket
		mov	si, ds:[bx]
		clr	bx
		xchg	bx, ds:[si].SI_queueToken
		tst	bx
		jz	done
		call	GeodeReturnSpace
done:
		.leave
		ret
SocketFreeQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFreeQueueCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a packet from a queue

CALLED BY:	SocketFreeQueue (via QueueEnum)
PASS:		es:si	- current element
RETURN:		carry set to abort enum
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFreeQueueCallback	proc	far
		uses	cx
		.enter
		movdw	axcx, es:[si]
		call	HugeLMemFree
		clc
		.leave
		ret
SocketFreeQueueCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DomainNameToIniCat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a domain name (DBCS) to a .INI category name (SBCS)

CALLED BY:	(GLOBAL) ConvDomainNameToIniCat
PASS:		ds:si	= Domain name
RETURN:		ds:si 	= .INI category
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Users of ConvDomainNameToIniCat must also have a corresponding
	incantation of ConvDomainNameDone.

	If you change this, see also DomainNameToIniCat() in:
		Library/Config/Pref/prefClass.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	12/ 7/93    	Initial version
	eca	7/8/94		re-named, re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DomainNameToIniCat	proc	far
DBCS <		call	DomainNameToIniCatLow				>
		ret
DomainNameToIniCat	endp

if DBCS_PCGEOS
DomainNameToIniCatLow	proc	near
		uses	ax, bx, cx, dx, es, di
		.enter
	;
	; Allocate a buffer for the .INI category
	;
		mov	ax, (size DomainNameStruct)
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		push	bx
		mov	es, ax
		clr	di
			CheckHack <(offset DNS_blockHandle) eq 0>
		mov	ax, bx			;ax <- block handle
		stosw
			CheckHack <(offset DNS_namePtr.low) eq 2>
		mov	ax, si
		stosw
			CheckHack <(offset DNS_namePtr.high) eq 4>
		mov	ax, ds
		stosw
			CheckHack <(offset DNS_iniCat) eq 6>
	;
	; Convert the string into SBCS
	;
		clr	cx			;cx <- length (SBCS)
		push	di
charLoop:
		LocalGetChar ax, dssi		;ax <- character
		LocalCmpChar ax, 0x80		;ASCII?
		jbe	gotChar			;branch if so
	;
	; For non-ASCII, stick in a couple of hex digits.  The digits aren't
	; in the correct order and they aren't all there, but it doesn't
	; matter as long as they are consistent
	;
		call	toHexDigits
DBCS <		mov	al, ah			;al <- high byte	>
DBCS <		call	toHexDigits					>
		jmp	charLoop

gotChar:
		stosb				;store SBCS character
		inc	cx			;cx <- one more character
		tst	al
		jnz	charLoop
	;
	; Return ds:si as a ptr to the .INI category name
	;
		segmov	ds, es			;ds:si <- ptr to category name
		pop	si
		pop	bx			;bx <- buffer handle

		.leave
		ret

toHexDigits:
		push	ax
	;
	; Second hex digit
	;
		push	ax
		andnf	al, 0x0f		;al <- low nibble
		call	convHexDigit
		pop	ax
	;
	; First hex digit
	;
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1			;al <- high nibble
		call	convHexDigit

		pop	ax
		retn

convHexDigit:
		add	al, '0'
		cmp	al, '9'
		jbe	gotDig
		add	al, 'A'-'9'-1
gotDig:
		stosb
		inc	cx			;cx <- one more character
		retn
DomainNameToIniCatLow	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DomainNameDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Done with domain .INI category name from DomainNameToIniCat()

CALLED BY:	(GLOBAL) ConvDomainNameDone
PASS:		ds:si - .INI category
RETURN:		ds:si - registers passed to DomainNameToIniCat
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DomainNameDone		proc	far
DBCS <		call	DomainNameDoneLow				>
		ret
DomainNameDone	endp

if DBCS_PCGEOS
DomainNameDoneLow	proc	near
		uses	bx
		.enter

		pushf
		mov	bx, ds:DNS_blockHandle		;bx <- our handle
		mov	si, ds:DNS_namePtr.low
		mov	ds, ds:DNS_namePtr.high		;ds:si <- ori. ptr
		call	MemFree
		popf

		.leave
		ret
DomainNameDoneLow		endp
endif

UtilCode	ends

