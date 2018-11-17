COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Network Extensions
MODULE:		socket library
FILE:		socketLink.asm

AUTHOR:		Eric Weber, May 17, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT RemoveDomainInterrupt   Timer interrupt asking to free a domain

    INT SocketSpawnThread       Create a thread to remove a domain

    EXT SocketFindDomain        Convert a domain name to a domain handle,
				considering only fully open domains

    EXT SocketFindDomainLow     Convert a domain name to a domain handle

    EXT SocketFindLink          Given a domain handle and address, return
				the offset in the domain info chunk of the
				link info for the corresponding link

    EXT SocketAddLink           Record a link

    EXT SocketRemoveConnection  Remove a ConnectionInfo

    EXT SocketRemoveDomain      Remove an unused domain

    EXT RemoveDomainThread      Remove a domain by request of a timer

    INT SocketRemoveDomainLow   Remove a domain right now

    INT LinkIncRefCount         Increment reference count on a link

    INT LinkDecRefCount         Reduce the reference count of a link and
				possibly close link

    INT LinkDecRefCountoClose  Reduce the reference count of a link

    INT SocketCloseLink         Close a link

    EXT CloseLinkThread         Really close a link

    INT FindClosingLink         Nuke the link which is being opened.

    EXT SocketCreateDomain      Create a new domain

    INT CompareDomains          Compare two domain names

    INT CompareAddresses        Compare two addresses

    EXT SocketFreeDomain        Free a domain info chunk

    EXT SocketFindLinkByHandle  Translate a link handle to its offset in
				the domain

    EXT SocketFindLinkById      Translate a link id to its offset in the
				domain

    INT SocketResetDomain       Reset a domain to the standby state

    EXT SocketStopDomainTimer   Stop the timer in a domain

    INT SocketAddDomain         Add a new domain

    INT SocketRemoveLink        Remove a link which was closed by the
				driver

    INT FindFailedSockets       Find all sockets using a link, and mark
				them failed

    EXT FailedPortCallback      Find any failed sockets in this port

    EXT FailedSocketCallback    See if this socket is using a failed link

    INT SocketAddressToLink     Given a SocketAddres, find or create a
				domain and link

    INT SocketLockForCreateLink Lock domain and verify that link really
				doesn't exist

    INT SocketCreateLink        Open an remember a link

    INT DestroyOpeningLink      Nuke the link which is being opened.

    EXT SocketLoadDriver        Load the driver for a domain

    INT SocketGrabMiscLock      Increment the misc counter in a domain

    EXT SocketReleaseMiscLock   Release a misc lock and possibly close
				domain

    EXT SocketAddressToDomain   Given a SocketAddress, find or create its
				domain

    INT SocketGetDomainsLow     Get a chunk array of domain names

    EXT SocketGetDomainsCallback 
				callback from SocketGetDomains

    EXT SocketLinkGetMediumForLink 
				Query the driver to find the medium used
				for a particular link.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/17/94   	Initial revision


DESCRIPTION:
	Routines pertaining to management of driver-level connections

	$Id: socketLink.asm,v 1.1 97/04/07 10:45:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

;
; the driver semaphore is locked whenever a thread is in the process of
; either loading or unloading a driver
;
driverSem	Semaphore <>

nextID		word	1

socketCategory			char	"socket",0
domainsKey			char	"domains",0
driverKey			char	"driver",0
typeKey				char	"driverType",0
driverCloseDelayKey		char	"driverCloseDelay",0
sendTimeoutKey			char	"sendTimeout",0
driverPath			TCHAR	"socket",0

idata	ends


udata	segment

driverCloseDelay	word		; time (in ticks) to wait before
					;  shutting down a driver when there
					;  are no more references to it
udata	ends


FixedCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveDomainInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timer interrupt asking to free a domain

CALLED BY:	EXTERNAL SocketRemoveDomain via timer
PASS:		ax	- domain handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	get UI thread
	ask it to call FreeDomainCallback

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	; We turn off read/write checking for this routine, because
	; r/w checking code grabs heap semaphore, which should not occur in
	; timer invoked routines.  --- AY 3/27/95
		.norcheck
		.nowcheck

RemoveDomainInterrupt	proc	far
		uses	ax,bx,cx,dx,bp,di
		.enter
	;
	; get the UI's thread
	;
		mov	cx,ax			; save domain handle
		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo		; ax = handle, dx destroyed
		mov	bx,ax
	;
	; set up parameters to callback
	;
		sub	sp, size ProcessCallRoutineParams
		mov	bp,sp
		mov	ss:[bp].PCRP_address.segment, vseg SocketSpawnThread
		mov	ss:[bp].PCRP_address.offset, offset SocketSpawnThread
		mov	ss:[bp].PCRP_dataBX, cx			; domain handle
		mov	ss:[bp].PCRP_dataCX, vseg RemoveDomainThread
		mov	ss:[bp].PCRP_dataDX, offset RemoveDomainThread
	;
	; ask UI to call the callback on its thread
	;
		mov	dx, size ProcessCallRoutineParams
		mov	ax, MSG_PROCESS_CALL_ROUTINE
		mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
		call	ObjMessage
		add	sp, size ProcessCallRoutineParams
		.leave
		ret
RemoveDomainInterrupt	endp

ifdef	READ_CHECK
		.rcheck
endif

ifdef	WRITE_CHECK
		.wcheck
endif

FixedCode ends

UtilCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSpawnThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a thread to remove a domain

CALLED BY:	(INTERNAL) SocketCloseLink
PASS:		bx	- domain handle
		cx	- segment of routine to run
		dx	- offset of routine to run
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We can't have ProcessCallRoutine call ThreadCreate directly because
	we can't pass bp through it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	1/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketSpawnThread	proc	far
		.enter
	;
	; spawn a thread
	;
		mov	ax, PRIORITY_STANDARD
		mov	di, DRIVER_CLOSE_STACK
		mov	bp, handle 0
		call	ThreadCreate
		.leave
		ret
SocketSpawnThread	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFindDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a domain name to a domain handle, considering
		only fully open domains

CALLED BY:	(EXTERNAL) SocketAddressToDomain, SocketAddressToLink,
		SocketCheckMediumConnection, SocketCloseDomainMedium,
		SocketGetAddressController, SocketGetAddressMedium,
		SocketGetAddressSize, SocketGetDomainMedia,
		SocketOpenDomainMedium, SocketResolve
PASS:		ds	- control segment
		dx:bp	- domain name

RETURN:		carry	- set if not found
		bx	- domain handle

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If the domain exists, but is OCS_OPENING or OCS_CLOSING, it is treated
	as if it didn't exist.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFindDomain	proc	far
		uses	di
		.enter
		
		call	SocketFindDomainLow
		jc	done
		mov	di, ds:[bx]
		cmp	ds:[di].DI_state, OCS_OPEN
		je	done				; z set implies c clear
		stc
done:
		.leave
		ret
SocketFindDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFindDomainLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a domain name to a domain handle

CALLED BY:	(EXTERNAL) SocketAddDomain, SocketFindDomain,
		SocketFindOrCreatePort, SocketLoadDriver,
		SocketRemoveLoadOnMsgMem
PASS:		ds	- control segment
		dx:bp	- domain name

RETURN:		carry	- set if not found
		bx	- domain handle

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFindDomainLow	proc	far
		uses	ax,cx,dx,si,di,bp,es
		.enter
EC <		Assert segment ds					>
EC <		Assert fptr dxbp					>
	;
	; get the size of the domain name excluding NULL
	; we want the size, not the length, so we can use a strcmp later
	;
		movdw	esdi, dxbp
		call	LocalStringSize
	;
	; find the first domain in the domain array
	;
		mov	ax,cx				; ax = size of dx:bp
		mov	si, offset SocketDomainArray	; *ds:si = domain array
		mov	di, ds:[si]			; ds:di = domain array
		mov	cx, ds:[di].CAH_count		; cx = no. of domains
		jcxz	domainNotFound
		add	di, ds:[di].CAH_offset		; ds:di = first domain
	;
	; loop through domains searching for the one the user wants
	;
checkDomain:
		call	CompareDomains
		je	domainFound
	;	
	; not this one, go on to next
	;
		inc	di	
		inc	di
		loop	checkDomain
	;
	; not in the array
	;
domainNotFound:
		stc
		jmp	done
domainFound:
		mov	bx, ds:[di]			; *ds:bx = DomainInfo
		clc
done:
		.leave
		ret
SocketFindDomainLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFindLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a domain handle and address, return the offset
		in the domain info chunk of the link info for
		the corresponding link

CALLED BY:	(EXTERNAL) SocketAddressToLink, SocketLinkOpened,
		SocketLockForCreateLink
PASS:		ds	- control segment
		bx	- domain handle
		dx:bp	- address
		cx	- size of address
RETURN:		carry	- set on error
		dx	- offset of link info in domain chunk
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFindLink	proc	far
		uses	ax,bx,cx,si,di,bp
		.enter
	;
	; search through the addresses in the link info array
	;
		mov	si, bx
		clr	ax
linkLoop:
		push	cx		
		call	ChunkArrayElementToPtr  ; ds:di = LinkInfo, cx=size
	;
	; validate link info
	;
EC <		jc	skipValidate					>
EC <		tst	ds:[di].LI_handle				>
EC <		WARNING_Z WARNING_NULL_CONNECTION_HANDLE		>
EC <		sub	cx, size LinkInfo				>
EC <		cmp	cx, ds:[di].LI_addrSize				>
EC <		ERROR_NE CORRUPT_DOMAIN					>
EC <		clc							>
skipValidate:
		pop	cx
		jc	done
	;
	; compare the addresses
	;
		inc	ax
		call	CompareAddresses
		jne	linkLoop
	;
	; the link is at ds:di
	;
		cmp	ds:[di].LI_state, OCS_OPEN
		jne	closing
		mov	dx, di			; ds:dx = LinkInfo
		mov	di, ds:[si]		; ds:di = DomainInfo
		sub	dx, di			; offset of link info
		clc
done:
		.leave
		ret
closing:
		stc
		jmp	done
NEC <		ForceRef skipValidate					>
SocketFindLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record a link

CALLED BY:	(EXTERNAL) SocketCreateLink, SocketLinkOpened
PASS:		dx:bp	- address
		cx	- address size
		ax	- link handle
		bx	- domain handle
RETURN:		ds:si	- LinkInfo
		ax	- link id
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddLink	proc	far
		uses	bx,cx,dx,di,bp,es
		.enter
	;
	; stop any timer which is running so domain doesn't shut down
	;
		push	ax
		mov	si,bx
		call	SocketStopDomainTimer
	;
	; Allocate a new link info
	;
alloc::
		mov	ax, size LinkInfo
		add	ax,cx
		call	ChunkArrayAppend		; ds:di = LinkInfo
		pop	ax
	;
	; set the fixed fields
	;
		segmov	es,ds,si			; es:di = LinkInfo
		mov	es:[di].LI_state, OCS_OPEN
		mov	es:[di].LI_handle, ax		; not open yet
		clr	es:[di].LI_refCount		; no connections yet
		mov	es:[di].LI_addrSize, cx
	;
	; copy the address
	;
copyAddress::
		movdw	dssi, dxbp
		push	es,di
		add	di, offset LI_address
EC <		call	ECCheckMovsb					>
		rep	movsb
		pop	ds,si				; ds:si = LinkInfo
	;
	; set the link id
	;
		mov	bx, handle dgroup
		call	MemDerefES
		segmov	ds:[si].LI_id, es:[nextID], ax
		inc	es:[nextID]
done::
		.leave
		ret
SocketAddLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRemoveConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a ConnectionInfo for a data driver

CALLED BY:	(EXTERNAL) FreeListenQueueCallback, SocketConnectionClosed,
		SocketFullClose
PASS:		bx	- domain
		ax	- connection handle
		dx	- SocketDrError
RETURN:		carry set on error (redundent close)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRemoveConnection	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; find the ConnectionInfo
	;
		mov	cx, bx
		xchg	dx, ax				; ax = error
		call	SocketFindLinkByHandle
		jc	done
		mov	si, bx
		mov	di, ds:[bx]
		add	di, dx
	;
	; see if anyone is using it
	;
		tst	ds:[di].CI_socket
		jz	delete
	;
	; mark socket as closed
	;
		mov	bx, ds:[di].CI_socket
		mov	bx, ds:[bx]
		and	ds:[bx].SI_flags, not (mask SF_RECV_ENABLE or mask SF_SEND_ENABLE)
	;
	; check the state
	;
EC <		cmp	ds:[bx].SI_state, ISS_CONNECTING		>
EC <		je	stateOK						>
EC <		cmp	ds:[bx].SI_state, ISS_CONNECTED			>
EC <		je	stateOK						>
EC <		cmp	ds:[bx].SI_state, ISS_CLOSING			>
EC <		ERROR_NE UNEXPECTED_SOCKET_STATE			>
stateOK::
	;
	; get the error, if any
	;
		tst	ax
		jz	wakeup
		call	SocketMapConnectError
	;
	; If timing out after already connected, use CONNECTION_FAILED
	; instead of SE_TIMED_OUT.  This avoids conflict with the use
	; of SE_TIMED_OUT to indicate a normal timeout on a recv.
	;
		cmp	al, SE_TIMED_OUT
		jne	goterr
		cmp	ds:[bx].SI_state, ISS_CONNECTING
		je	goterr
		mov	al, SE_CONNECTION_FAILED
goterr:
		mov	ds:[bx].SSI_error, ax
		ornf	ds:[bx].SI_flags, mask SF_FAILED
	;
	; Clear out the CE_link field so we know the connection to the
	; driver is no more.  (It's passed on, it's ceased to be!)
	;
wakeup:
		clr	ds:[bx].SSI_connection.CE_link
		mov	bx, ds:[di].CI_socket
		call	WakeUpForClose
	;
	; Check if SocketClose was already called. If so, clean up the socket.
	;
		push	di, si
		mov	si, ds:[bx]
		cmp	ds:[si].SI_state, ISS_CLOSING
		jne	doDelete
		call	RemoveSocketFromPort
		call	SocketFreeLow
doDelete:
		pop	di, si
	;
	; delete the ConnectionInfo
	;
delete:
		call	ChunkArrayDelete
	;
	; close domain if needed
	;
		call	SocketRemoveDomain
		clc
done::
EC <		WARNING_C REDUNDENT_CLOSE				>
		.leave
		ret
		
SocketRemoveConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRemoveDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an unused domain

CALLED BY:	(EXTERNAL) CloseLinkThread, DestroyOpeningLink,
		SocketConnectRequest, SocketConnectionClosed,
		SocketFreePort, SocketReleaseMiscLock,
		SocketRemoveConnection, SocketRemoveDomainLow,
		SocketRemoveLink
PASS:		*ds:si - DomainInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRemoveDomain	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
EC <		mov	ax,ds						>
EC <		mov	bx, SCLT_WRITE					>
EC <		call	ECCheckControlSeg				>
	;
	; check counts
	;
		mov	di, ds:[si]
		tst	ds:[di].CAH_count
		jnz	done
		tst	ds:[di].DI_miscCount
		jnz	done
	;
	; We should only be in this routine if one of the above counts
	; just now reached zero.  Therefore the domain should not already
	; be closing.
	;
EC <		tst	ds:[di].DI_timer				>
EC <		ERROR_NZ CORRUPT_DOMAIN					>
	;
	; create a timer
	;
	; before that, we want to check if the delay==0. because 0 means
	; disable this function
	;
		mov	bx, handle dgroup
		call	MemDerefES
		mov	cx, es:[driverCloseDelay]

		jcxz	done
		
		mov	dx, si				; domain handle
		mov	al, TIMER_ROUTINE_ONE_SHOT
		mov	bx, handle RemoveDomainInterrupt
		call	MemDerefES
		mov	bx,es
		mov	si, offset RemoveDomainInterrupt ; bx:si = handler
		mov	bp, handle 0			; owner for timer
		call	TimerStartSetOwner		; ax=id, bx=handle
		mov	ds:[di].DI_timer, bx
		mov	ds:[di].DI_timerID, ax
done:
		.leave
		ret
SocketRemoveDomain	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveDomainThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a domain by request of a timer

CALLED BY:	(EXTERNAL) thread created by SocketRemoveDomainInterrupt
PASS:		cx	- domain handle
		es	- dgroup
RETURN:		parameters for ThreadDestroy
		cx	- return code (0)
		dxbp	- object to receive ACK (0)
		si	- data to pass with ACK (undefined)
DESTROYED:	bx, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveDomainThread	proc	far
		PSem	es, driverSem
		call	SocketControlStartWrite
	;
	; If there is no timer handle in the domain, it means somebody
	; tried to stop us, but were too late.  We will honor their
	; wishes and do nothing.
	;
		mov	si,cx
		mov	di, ds:[si]
		tst	ds:[di].DI_timer
		jz	skip
		clr	ds:[di].DI_timer
		clr	ds:[di].DI_timerID
	;
	; go ahead and remove the domain
	;
		call	SocketRemoveDomainLow
skip:
		call	SocketControlEndWrite
		VSem	es, driverSem
	;
	; set up parameters for ThreadDestroy
	;
		clr	cx			; exit code 0
		clrdw	dxbp			; no ACK required
		ret
RemoveDomainThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRemoveDomainLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a domain right now

CALLED BY:	(INTERNAL) RemoveDomainThread
PASS:		*ds:si	- DomainInfo
		es	- dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRemoveDomainLow	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; check counts
	;
		mov	di, ds:[si]
		tst	ds:[di].CAH_count
		jnz	skipClose
		tst	ds:[di].DI_miscCount
		jz	countsOK
skipClose:
		jmp	done
countsOK:
	;
	; verify domain isn't already being closed
	; (we shouldn't be here if it is being opened)
	;
		cmp	ds:[di].DI_state, OCS_OPEN
		je	pastValidate

EC <		cmp	ds:[di].DI_state, OCS_CLOSING			>
EC <		ERROR_NE CORRUPT_DOMAIN					>
abortClose::
		jmp	done
		
pastValidate::
	;
	; set state to closing
	; this prevents any additional threads from blocking on the
	; mutexes
	;
		mov	ds:[di].DI_state, OCS_CLOSING
	;
	; wait for both mutex queues to clear
	;
		mov	bx, ds:[di].DI_openMutex
		mov	cx, ds:[di].DI_closeMutex
		call	SocketControlEndWrite
		call	ThreadPSem
		call	ThreadVSem
		mov	bx,cx
		call	ThreadPSem
		call	ThreadVSem
		call	SocketControlStartWrite
	;
	; make sure no links were opened, or misc operations started
	;
pastMutex::
		mov	di, ds:[si]
		tst	ds:[di].CAH_count
		jnz	lateAbortClose
		tst	ds:[di].DI_miscCount
		jnz	lateAbortClose
	;
	; save some info for freeing driver below
	;
		mov	al, ds:[di].DI_flags
		mov	cx, ds:[di].DI_driver
	;
	; unregister the domain
	;
		pushdw	ds:[di].DI_entry
		mov	bx, ds:[di].DI_client
		mov	di, DR_SOCKET_UNREGISTER
		call	SocketControlEndWrite
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jc	refused
	;	
	; remove our reference to the driver, so it can exit
	;
		mov	bx, cx
		test	al, mask DF_SELF_LOAD
		je	selfload
		call	GeodeFreeDriver
		jmp	reset
selfload:
		call	GeodeRemoveReference
	;
	; remove the lock on ourselves created when this driver was
	; registered
	;
		mov	bx, handle 0
		call	GeodeRemoveReference
	;
	; reset this domain to standby mode, since domain chunks
	; are never freed unless the library exits
	;
reset:
		call	SocketControlStartWrite
		mov	di, ds:[si]
		call	SocketResetDomain
done:
		.leave
		ret
	;
	; Return domain to open state.
	;
	; If we are aborting, but the domain is still unused, we
	; will try to remove it again later.  This only happens when
	; the driver refuses unregistration.
	;
refused:
		call	SocketControlStartWrite
		mov	di, ds:[si]
lateAbortClose:
		mov	ds:[di].DI_state, OCS_OPEN
		call	SocketRemoveDomain
		jmp	done
		
SocketRemoveDomainLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkIncRefCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment reference count on a link

CALLED BY:	(INTERNAL) ListenQueueAppend, SocketRegisterConnection
PASS:		*ds:cx	- domain
		dx	- link offset
RETURN:		ax	- link handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkIncRefCount	proc	far
		uses	bx,dx,si
		.enter
		mov	si,cx			; *ds:si = DomainInfo
		mov	si, ds:[si]		; ds:si = DomainInfo
		mov	bx, dx			; ds:si+bx = LinkInfo
		inc	ds:[si][bx].LI_refCount	; update count
		mov	ax, ds:[si][bx].LI_handle
	;
	; make sure that we just modified a real domain and link
	;
EC <		cmp	ds:[si].DI_type, CCT_DOMAIN_INFO		>
EC <		ERROR_NE CORRUPT_DOMAIN					>
EC <		mov	dx, ax						>
EC <		call	SocketFindLinkByHandle				>
EC <		ERROR_C CORRUPT_DOMAIN					>
EC <		cmp	bx,dx						>
EC <		ERROR_NE CORRUPT_DOMAIN					>
		
		.leave
		ret
LinkIncRefCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkDecRefCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reduce the reference count of a link and possibly close link

CALLED BY:	(INTERNAL) ConnectionCancel, ConnectionClose, ConnectionRefuse,
		ListenQueueDelete, SocketClearConnection
PASS:		*ds:cx	- DomainInfo
		dx	- offset of LinkInfo inside domain chunk
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	may close link and/or free driver

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkDecRefCount	proc	far
		call	LinkDecRefCountNoClose
		jc	done
		jnz	done
		call	SocketCloseLink
done:
		ret
LinkDecRefCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkDecRefCountNoClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reduce the reference count of a link

CALLED BY:	(INTERNAL) FreeListenQueueCallback, LinkDecRefCount,
		SocketSendClose
PASS:		*ds:cx	- DomainInfo
		dx	- offset of LinkInfo inside domain chunk
RETURN:		zero flag - set if link count is now zero
		carry flag - set if called on a data driver domain
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkDecRefCountNoClose	proc	far
		uses	bx,dx,si
		.enter
	;
	; find the counter
	;
		mov	si,cx
		mov	si,ds:[si]			; ds:di = DomainInfo
		mov	bx,dx				; ds:di+bx = LinkInfo
		cmp	ds:[si].DI_driverType, SDT_DATA
		stc
		je	done
	;
	; validate domain and link
	;
EC <		push	dx						>
EC <		cmp	ds:[si].DI_type, CCT_DOMAIN_INFO		>
EC <		ERROR_NE CORRUPT_DOMAIN					>
EC <		mov	dx, ds:[si][bx].LI_handle			>
EC <		call	SocketFindLinkByHandle				>
EC <		ERROR_C CORRUPT_DOMAIN					>
EC <		cmp	bx,dx						>
EC <		ERROR_NE CORRUPT_DOMAIN					>
EC <		tst	ds:[si][bx].LI_refCount				>
EC <		ERROR_Z	LINK_ALREADY_CLOSED				>
EC <		pop	dx						>
	;
	; decrement the count
	;
		dec	ds:[si][bx].LI_refCount
EC <		ERROR_S CORRUPT_DOMAIN					>
		clc
done::
		.leave
		ret
LinkDecRefCountNoClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCloseLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a link

CALLED BY:	(INTERNAL) LinkDecRefCount
PASS:		*ds:cx	- DomainInfo
		dx	- offset to LinkInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCloseLink	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		domain		local	nptr	push cx
		id		local	nptr
		.enter
	;
	; remember the link id
	;
		mov	si,cx
		mov	di, ds:[si]
		mov	bx,dx
		segmov	ss:[id], ds:[di][bx].LI_id, bx
	;
	; grab exclusive right to manipulate links
	;
		mov	bx, ds:[di].DI_closeMutex
		call	SocketControlEndWrite
		call	ThreadPSem
		call	SocketControlStartWrite
	;
	; relocate the link, if it still exists
	;
findLink::
		mov	si, ss:[domain]
		mov	bx, ss:[id]
		call	SocketFindLinkById
		jc	unlockDomain
	;
	; make sure ref count is still zero
	; (a connection may have opened while waiting for the lock)
	;
		mov	di, ds:[si]
		tst	ds:[di][bx].LI_refCount
		jnz	unlockDomain
		mov	ds:[di][bx].LI_state, OCS_CLOSING
	;
	; spawn a thread to really close the link
	;
		mov	bx,si
		mov	cx, vseg CloseLinkThread
		mov	dx, offset CloseLinkThread
		push	bp,si
		call	SocketSpawnThread
		pop	bp,si
		jmp	done
	;
	; release the exclusive lock on the driver
	;
unlockDomain:
		mov	di, ds:[si]		; ds:di = DomainInfo
		mov	bx, ds:[di].DI_closeMutex
		call	ThreadVSem
done:
		.leave
		ret
		
SocketCloseLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseLinkThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Really close a link

CALLED BY:	(EXTERNAL) thread created by SocketCloseLink
PASS:		cx	- domain handle
		es	- dgroup
RETURN:		parameters for ThreadDestroy
		cx	- return code (0)
		dxbp	- object to receive ACK (0)
		si	- data to pass with ACK (undefined)
DESTROYED:	bx, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseLinkThread	proc	far
	;
	; locate the domain
	;
		call	SocketControlStartWrite
EC <		call	ECCheckDomainLow				>
	;
	; find the closing link
	;
		mov	si,cx
		call	FindClosingLink
		jc	unlockDomain
	;
	; make sure ref count is still zero
	; (a connection may have opened while this thread was spawning)
	;
		mov	bx, ds:[si]
		tst	ds:[di].LI_refCount
		jnz	unlockDomain
	;
	; close the actual link
	;
callDriver::
		pushdw	ds:[bx].DI_entry
		mov	bx, ds:[di].LI_handle
		mov	di, DR_SOCKET_DISCONNECT_REQUEST
		mov	ax, SCT_FULL
		call	SocketControlEndWrite
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		call	SocketControlStartWrite
		ERROR_C UNEXPECTED_SOCKET_DRIVER_ERROR
	;
	; verify once again that the link still exists
	;
		call	FindClosingLink
		jc	unlockDomain
	;
	; actually delete it from the domain
	;
		call	ChunkArrayDelete
	;
	; release the exclusive lock on the driver
	;
unlockDomain:
		mov	di, ds:[si]		; ds:di = DomainInfo
		mov	bx, ds:[di].DI_closeMutex
		call	ThreadVSem
	;
	; possibly free the domain
	;
		call	SocketRemoveDomain
		call	SocketControlEndWrite
done::
	;
	; set up parameters for ThreadDestroy
	;
		clr	cx			; exit code 0
		clrdw	dxbp			; no ACK required
		ret
CloseLinkThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindClosingLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the link which is being opened. 

CALLED BY:	(INTERNAL) CloseLinkThread
PASS:		*ds:si - DomainInfo
RETURN:		ds:di	 - DomainInfo
		carry set if not found
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindClosingLink	proc	near
		uses	ax,cx
		.enter
	;
	; start at the end of the array
	;
		call	ChunkArrayGetCount		; cx = # of elements
		mov	ax,cx
	;
	; get previous entry and check it's state
	;
top:
		dec	ax
		stc
		js	done
		call	ChunkArrayElementToPtr		; ds:di = LinkInfo
		cmp	ds:[di].LI_state, OCS_CLOSING
		jne	top
	;
	; we found the link
	;
		clc
done:
		.leave
		ret
FindClosingLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCreateDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new domain

CALLED BY:	(EXTERNAL) SocketAddDomain, SocketFindOrCreatePort,
		SocketLoadDriver
PASS:		ds	- control segment
		es	- dgroup
		dx:bp	- domain name

RETURN:		carry	- set on error
		bx	- domain handle

DESTROYED:	nothing
SIDE EFFECTS:	
    initial values:
	DI_header		as per ChunkArrayCreate
	DI_type			CCT_DOMAIN_INFO
	DI_id			next unique id
	DI_driverType		0
	DI_flags		0
	DI_driver		0
	DI_client		0
	DI_entry		0
	DI_state		OCS_STANDBY
	DI_openMutex		semaphore handle
	DI_closeMutex		semaphore handle
	DI_miscCount		0
	DI_bindCount		0
	DI_seqHeaderSize	0
	DI_dgramHeaderSize	0
	DI_nameSize		as passed
	DI_name			as passed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 8/94    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCreateDomain	proc	far
		uses	ax,cx,dx,si,di,bp,es
		.enter
	;
	; get the size of the domain name in bytes, excluding null
	;
		movdw	esdi, dxbp
		call	LocalStringSize			; cx = size
	;
	; locate dgroup
	;	
		mov	bx, handle dgroup
		call	MemDerefES	
	;
	; allocate a new domain info
	;
		clr	bx				; var size array
		add	cx, size DomainInfo + size TCHAR; header size and null
		clr	si				; new chunk
		clr	al				; no flags
		call	ChunkArrayCreate		; *ds:si = array
	LONG	jc	allocError
		sub	cx, size DomainInfo + size TCHAR; domain name size
	;
	; initialize it
	;
		push	ds,si
		mov	di,ds:[si]			; ds:di = DomainInfo
EC <		mov	ds:[di].DI_type, CCT_DOMAIN_INFO		>
		segmov	ds:[di].DI_id, es:[nextID], ax
		inc	es:[nextID]
		mov	ds:[di].DI_state, OCS_STANDBY
		mov	ds:[di].DI_nameSize, cx
	;
	; allocate semaphores owned by library
	;
		mov	bx,1
		call	ThreadAllocSem			; bx = semaphore
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	ds:[di].DI_openMutex, bx
		mov	bx,1
		call	ThreadAllocSem			; bx = semaphore
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	ds:[di].DI_closeMutex, bx
		mov	bx,1
		clr	ds:[di].DI_miscCount
	;	clr	ds:[di].DI_bindCount
	;
	; copy the domain name
	;
		segmov	es,ds
		add	di, offset DI_name		; es:di = name buffer
		movdw	dssi, dxbp			; ds:si = name
EC <		call	ECCheckMovsb					>
		rep	movsb
		clr	ax				; append a null
		LocalPutChar	esdi,ax
		pop	ds,bx				; *ds:bx = DomainInfo
	;
	; add it to the domain array
	;
		mov	si, offset SocketDomainArray
		call	ChunkArrayAppend		; ds:di = new elt
		jc	appendError
		mov	ds:[di], bx
allocError:
		.leave
		ret

appendError:
	;
	; Error occured.  Free the chunk array we allocated.
	;
		mov_tr	ax, bx
		call	LMemFree
		stc
		jmp	allocError
SocketCreateDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareDomains
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two domain names

CALLED BY:	(INTERNAL) SocketFindDomainLow
PASS:		dx:bp	= domain name
		ax	= size of domain name
		ds:di = **DomainInfo
RETURN:		zero flag - set if equal
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareDomains	proc	near
		uses	cx,si,di,es
		.enter
	;
	; dereference the string in the domain info
	;
		mov	si, ds:[di]		; *ds:si = DomainInfo
		mov	si, ds:[si]		; ds:si = DomainInfo
		mov	cx, ds:[si].DI_nameSize
EC <		tst	cx						>
EC <		ERROR_Z INVALID_DOMAIN					>
		add	si, offset DI_name	; ds:si = domain name 1
	;
	; set up pointer to passed string
	;
		mov	es, dx
		mov	di, bp			; es:di = domain name 2
		cmp	cx, ax			; compare sizes
		jne	done
	;
	; now compare ds:si to es:di
	;
EC <		call	ECCheckMovsb					>
DBCS <		shr	cx						>
		call	LocalCmpStringsNoCase
done:
		.leave
		ret
CompareDomains	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two addresses

CALLED BY:	(INTERNAL) SocketFindLink
PASS:		ds:di - LinkInfo
		dx:bp - address
		cx    - address size
RETURN:		zero flag - set if equal
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareAddresses	proc	near
		uses	cx,si,di,es
		.enter
	;
	; check the sizes
	;
EC <		tst	cx						>
EC <		ERROR_Z INVALID_ADDRESS					>
		cmp	cx, ds:[di].LI_addrSize		; same size?
		jne	done
	;
	; set up registers
	;
		add	di, offset LI_address		; ds:di = address
		mov	si,di				; ds:si = address 1
		movdw	esdi, dxbp			; es:di = address 2
	;
	; now compare ds:si to es:di
	;
EC <		call	ECCheckMovsb					>
		repe	cmpsb
done:
		.leave
		ret
CompareAddresses	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFreeDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a domain info chunk

CALLED BY:	(EXTERNAL) SocketLoadDriver
PASS:		*ds:bx	- DomainInfo to free
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFreeDomain	proc	far
		uses	ax,bx,cx,si,di,es
		.enter
	;
	; get pointer to list of domains
	;
		mov	si, offset SocketDomainArray
		mov	di, ds:[si]			; ds:di = domain array
		mov	cx, ds:[di].CAH_count
		add	di, ds:[di].CAH_offset
	;
	; search for the target domain
	;
		segmov	es,ds,ax
		mov	ax,bx
EC <		shl	cx		; assume # domains < 2^15	>
EC <		Assert	okForRepScasb					>
EC <		shr	cx						>
		repne	scasw
EC <		ERROR_NE DOMAIN_NOT_IN_DOMAIN_ARRAY			>
	;
	; delete the chunk array entry
	;
		dec	di
		dec	di				; ds:di = matching elt
		call	ChunkArrayDelete
	;
	; free the semaphores
	;
		mov	si,ax
		mov	di,ds:[si]
		mov	bx, ds:[di].DI_openMutex
		call	ThreadFreeSem
		mov	bx, ds:[di].DI_closeMutex
		call	ThreadFreeSem
	;
	; free the chunk
	;
		call	LMemFree
		.leave
		ret
SocketFreeDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFindLinkByHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a link handle to its offset in the domain

CALLED BY:	(EXTERNAL) ConnectionCancel, ConnectionClose, ConnectionRefuse,
		ECCheckConnectionEndpoint, FreeListenQueueCallback,
		ListenQueueAppend, ListenQueueDelete,
		ReceiveSequencedDataPacket, ReceiveUrgentDataPacket,
		SocketAccept, SocketClearConnection,
		SocketConnectionClosed, SocketDataGetInfo, SocketGetLink,
		SocketPostDataAccept, SocketRemoveConnection,
		SocketRemoveLink, SocketSendClose, SocketConnectConfirm
PASS:		*ds:cx	- DomainInfo
		dx	- link handle
RETURN:		carry	- set if not found
		dx	- offset of link in domain
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ignores links which are not OCS_OPEN		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFindLinkByHandle	proc	far
		.assert	(offset LI_handle) eq (offset CI_handle)
		uses	ax,bx,cx,si,di,bp
		.enter
EC <		call	ECCheckDomainLow				>
	;
	; search through the addresses in the link info array
	;
		mov	si, cx			; *ds:si = DomainInfo
		mov	bx, ds:[si]		; ds:bx = DomainInfo
		clr	ax			; elmeent 0
linkLoop:
		call	ChunkArrayElementToPtr  ; ds:di = LinkInfo, cx=size
	;
	; validate link info (link drivers only)
	;
EC <		jc	skipValidate					>
EC <		cmp	ds:[bx].DI_driverType, SDT_DATA			>
EC <		je	skipValidate		; carry clear if z set	>
EC <		cmp	ds:[di].LI_state, OCS_OPEN			>
EC <		jne	handleOK					>
EC <		tst	ds:[di].LI_handle				>
EC <		WARNING_Z WARNING_NULL_CONNECTION_HANDLE		>
handleOK::
EC <		sub	cx, size LinkInfo				>
EC <		cmp	cx, ds:[di].LI_addrSize				>
EC <		ERROR_NE CORRUPT_DOMAIN					>
EC <		clc							>
skipValidate::
		jc	done
		inc	ax			; next element
		cmp	dx, ds:[di].LI_handle
		jne	linkLoop
		cmp	ds:[bx].DI_driverType, SDT_DATA
		je	success
		cmp	ds:[di].LI_state, OCS_OPEN
		jne	linkLoop
	;
	; compute offset
	;
success:
		mov	dx, di			; ds:dx = LinkInfo
		sub	dx, ds:[si]		; dx <- offset from base
		clc
done:
		.leave
		ret
SocketFindLinkByHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFindLinkById
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a link id to its offset in the domain

CALLED BY:	(EXTERNAL) SocketCloseLink, SocketCreateLink
PASS:		*ds:si	- DomainInfo
		bx	- link handle
RETURN:		bx	- offset of link in domain
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFindLinkById	proc	far
		uses	ax,cx,dx,si,di,bp
		.enter
	;
	; search through the addresses in the link info array
	;
		clr	ax			; elmeent 0
linkLoop:
		call	ChunkArrayElementToPtr  ; ds:di = LinkInfo, cx=size
	;
	; validate link info
	;
EC <		jc	skipValidate					>
EC <		cmp	ds:[di].LI_state, OCS_OPEN			>
EC <		jne	handleOK					>
EC <		tst	ds:[di].LI_handle				>
EC <		WARNING_Z WARNING_NULL_CONNECTION_HANDLE		>
handleOK::
EC <		sub	cx, size LinkInfo				>
EC <		cmp	cx, ds:[di].LI_addrSize				>
EC <		ERROR_NE CORRUPT_DOMAIN					>
EC <		clc							>
skipValidate::
	;
	; check the id
	;
		jc	done
		inc	ax			; next element
		cmp	bx, ds:[di].LI_id
		jne	linkLoop
	;
	; compute offset
	;
		mov	bx, di			; ds:dx = LinkInfo
		mov	di, ds:[si]		; ds:di = DomainInfo
		sub	bx,di
		clc
done:
		.leave
		ret
SocketFindLinkById	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFindLinkBySocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the ConnectionInfo corresponding to a socket

CALLED BY:	SocketDataConnect
PASS:		*ds:si	- DomainInfo
		bx	- socket handle
RETURN:		ds:di	- ConnectionInfo
		carry set if not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFindLinkBySocket	proc	far
		uses	ax,bx,cx,dx,si,bp
		.enter
	;
	; validate parameters
	;
EC <		mov	cx, si						>
EC <		call	ECCheckDomainLow				>
EC <		mov	di, ds:[si]					>
EC <		cmp	ds:[di].DI_driverType, SDT_DATA			>
EC <		ERROR_NE CORRUPT_DOMAIN					>
	;
	; search through the addresses in the link info array
	;
		clr	ax			; elmeent 0
linkLoop:
		call	ChunkArrayElementToPtr  ; ds:di=ConnectionInfo, cx=size
	;
	; check for a matching socket pointer
	;
		jc	done
EC <		cmp	cx, size ConnectionInfo				>
EC <		ERROR_NE CORRUPT_DOMAIN					>
		inc	ax			; next element
		cmp	bx, ds:[di].CI_socket
		jne	linkLoop
		clc
done:
		.leave
		ret
SocketFindLinkBySocket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketResetDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset a domain to the standby state

CALLED BY:	(INTERNAL) SocketRemoveDomainLow
PASS:		ds:di	- DomainInfo
		*ds:si	- DomainInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
   sets the following values:
	DI_driverType		0
	DI_driver		0
	DI_client		0
	DI_entry		0
	DI_state		OCS_STANDBY
	DI_seqHeaderSize	0
	DI_dgramHeaderSize	0
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketResetDomain	proc	far
		uses	ax,cx
		.enter
EC <		mov	cx,si					>
EC <		call	ECCheckDomainLow			>
	;
	; clear data fields
	;
		mov	ds:[di].DI_state, OCS_STANDBY
		clr	ax
		czr	ax, \
			ds:[di].DI_driver, \
			ds:[di].DI_client, \
			ds:[di].DI_entry.segment, \
			ds:[di].DI_entry.offset
		czr	al, \
			ds:[di].DI_driverType, \
			ds:[di].DI_seqHeaderSize, \
			ds:[di].DI_dgramHeaderSize
		.leave
		ret
SocketResetDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketStopDomainTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the timer in a domain

CALLED BY:	(EXTERNAL) SocketAddLink, SocketConnectRequest,
		SocketGrabMiscLock
PASS:		*ds:si	- DomainInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketStopDomainTimer	proc	far
		uses	ax,bx,di
		.enter
		mov	di, ds:[si]
		tst	ds:[di].DI_timer
		jz	done
		clrdw	axbx
		xchg	ax, ds:[di].DI_timerID
		xchg	bx, ds:[di].DI_timer
		call	TimerStop
done:
		.leave
		ret
SocketStopDomainTimer	endp

UtilCode	ends

StrategyCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new domain

CALLED BY:	(INTERNAL) SocketAddDomainRaw
PASS:		ax	- client handle
		ch	- minimum header size for outgoing sequenced packets
		cl	- minimum header size for outgoing datagram packets
		dl	- SocketDriverType
		ds:si	- domain name (null terminated)
		es:bx	- driver entry point (fptr)
		bp	- driver handle
RETURN:		bx	- domain handle
		carry	- set if domain already registered or
                          unable to allocate chunk
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddDomain	proc	near
		uses	ax,cx,dx,si,di,bp,ds,es
		client		local	word	push ax
		entry		local	fptr	push es,bx
		hdrSizes	local	word	push cx
		dtype		local	word	push dx
		.enter
	;
	; get all the appropriate locks
	;
		push	bp
		movdw	dxbp, dssi
		mov	bx, handle dgroup
		call	MemDerefES
		PSem	es, driverSem
		call	SocketControlStartWrite
	;
	; see if the domain is already registered
	; if so, return the existing domain handle
	;
		push	es
		movdw	esdi, dxbp		; es:di = domain name
		call	LocalStringSize		; cx = size of name
		pop	es
		call	SocketFindDomainLow	; bx = domain handle
		jc	alloc
	;
	; the domain exists in some form
	; if it's only in standby mode, we need to initialize it
	;
	; If it's OPENING or CLOSING, we have an overlap between
	; a driver request and a library request.  This is acceptable,
	; just return the existing handle.
	;
		pop	bp
		mov	si, ds:[bx]
		cmp	ds:[si].SI_state, OCS_STANDBY
		je	init
		clc
		jmp	done
	;
	; we need to allocate a new domain record
	;
alloc:
		call	SocketCreateDomain	; bx = domain handle
		pop	bp
		jc	done
		mov	si, ds:[bx]
	;
	; initialize the domain
	;
init:
		mov	cx, ss:[hdrSizes]
		mov	ds:[si].DI_state, OCS_OPEN
		segmov	ds:[si].DI_driver, ss:[bp], ax
		segmov	ds:[si].DI_driverType, ss:[dtype].low, al
		mov	ds:[si].DI_flags, mask DF_SELF_LOAD
		segmov	ds:[si].DI_client, ss:[client], ax
		mov	ds:[si].DI_seqHeaderSize, ch
		mov	ds:[si].DI_dgramHeaderSize, cl
		movdw	ds:[si].DI_entry, ss:[entry], ax
		clc
	;
	; unlock and exit
	;
done:
		call	SocketControlEndWrite
		VSem	es, driverSem
		.leave
		ret

SocketAddDomain	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRemoveLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a link which was closed by the driver

CALLED BY:	(INTERNAL) SocketLinkClosed
PASS:		*ds:bx	- domain
		ax	- link handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRemoveLink	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; find the link
	;
		mov	cx,bx
		mov_tr	dx,ax
		call	SocketFindLinkByHandle
EC <		WARNING_C REDUNDENT_CLOSE		>
		jc	done
	;
	; delete it from the domain
	;
		mov	si,bx
		mov	di,ds:[si]
		add	di,dx
	;
	; if anybody is using it, mark them as dead
	;
		tst	ds:[di].LI_refCount
		jz	noSockets
		call	FindFailedSockets
noSockets:
		call	ChunkArrayDelete
		call	SocketRemoveDomain
done:
		.leave
		ret
SocketRemoveLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFailedSockets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find all sockets using a link, and mark them failed

CALLED BY:	(INTERNAL) SocketRemoveLink
PASS:		ds:di	- LinkInfo
		*ds:bx	- DomainInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFailedSockets	proc	near
		uses	ax,bx,si,di
		.enter
		mov	ax,bx
		mov	dx, ds:[di].LI_handle
		mov	si, offset SocketPortArray
		mov	bx, cs
		mov	di, offset FailedPortCallback
		call	ChunkArrayEnum
		.leave
		ret
FindFailedSockets	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FailedPortCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find any failed sockets in this port

CALLED BY:	(EXTERNAL) FindFailedSockets via ChunkArrayEnum
PASS:		dx	- link handle
		ax	- domain handle
		ds:di	- PortArrayEntry
RETURN:		nothing
DESTROYED:	bx,si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FailedPortCallback	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		mov	si, ds:[di].PAE_info
EC <		call	ECCheckPortLow					>
		mov	bx,cs
		mov	di, offset FailedSocketCallback
		call	ChunkArrayEnum
		clc
		.leave
		ret
FailedPortCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FailedSocketCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this socket is using a failed link

CALLED BY:	(EXTERNAL) FailedPortCallback (via ChunkArrayEnum)
PASS:		dx	- link handle
		ax	- domain handle
		ds:di	- pointer to socket handle
RETURN:		nothing
DESTROYED:	si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FailedSocketCallback	proc	far
		.enter
		mov	si, ds:[di]		; *ds:si <- SocketInfo
EC <		call	ECCheckSocketLow				>
		mov	si, ds:[si]		; ds:si <- SocketInfo
		cmp	ds:[si].SI_state, ISS_CONNECTED
		jne	done
		cmp	ds:[si].SSI_connection.CE_domain, ax
		jne	done
		cmp	ds:[si].SSI_connection.CE_link, dx
		jne	done
	;
	; this socket has failed and is no longer connected
	;
		or	ds:[si].SI_flags, mask SF_FAILED
		and	ds:[si].SI_flags, not ( mask SF_SEND_ENABLE or \
					  mask SF_RECV_ENABLE )
		clr	ds:[si].SSI_connection.CE_link
done:
		clc
		.leave
		ret
FailedSocketCallback	endp

StrategyCode	ends


ApiCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddressToLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a SocketAddres, find or create a domain and link

CALLED BY:	(INTERNAL) SocketConnect
PASS:		ds	- control segment
		es:di	- SocketAddress
		ss:ax	- timeout
RETURN:		cx	- domain handle
		dx	- offset of LinkInfo in domain chunk
		carry	- set on error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddressToLink	proc	near
		uses	bx,si,di,bp,es
		.enter
	;
	; extract domain name from SocketAddress
	;
		movdw	dxbp, es:[di].SA_domain		; dx:bp = domain name
	;
	; search for existing domain
	;
		call	SocketFindDomain		; bx = domain
		jc	domainNotFound
	;
	; check domain type
	;
domainOK:
		mov	si, ds:[bx]
		cmp	ds:[si].DI_driverType, SDT_LINK
		je	findLink
	;
	; this is a data driver
	; don't try to open a connection here, but do create a ConnectionInfo
	;
		mov	si, bx
		mov	ax, size ConnectionInfo
		call	ChunkArrayAppend
		mov	ax, SE_OUT_OF_MEMORY
		jc	done
		call	SocketStopDomainTimer
		mov	dx, di
		sub	dx, ds:[si]
		clc	
		jmp	done
	;
	; Extract address string from SocketAddress
	;
findLink:
		mov	cx, es:[di].SA_addressSize	; cx = size of addr
		add	di, offset SA_address		; es:di = address
	;
	; look for existing link
	;
		movdw	dxbp, esdi			; dx:bp = address
		call	SocketFindLink			; dx = offset of addr
		jc	linkNotFound
		mov	ax, SE_NO_ERROR
		jmp	done
linkNotFound::
	;
	; create a new link
	;
		sub	di, offset SA_address		; es:di =SocketAddress
		call	SocketCreateLink
		jmp	done
domainNotFound:
	;
	; load the driver
	;
		call	SocketLoadDriver		; bx = domain
		jnc	domainOK
done:
		mov	cx,bx				; cx = domain handle
		.leave
		ret
SocketAddressToLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketLockForCreateLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock domain and verify that link really doesn't exist

CALLED BY:	(INTERNAL) SocketCreateLink
PASS:		*ds:bx	- DomainInfo
		es:di	- SocketAddress
		ss:ax	- timeout
RETURN:		ds	- control block (possibly moved)
		carry clear if link should not be opened
		   dx = 0 if timed out
	           dx = link offset if link already open
                carry set if link should be opened
			dx destroyed
DESTROYED:	see above
SIDE EFFECTS:
	may block
	returns with DI_openMutex locked if carry set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketLockForCreateLink	proc	near
		uses	ax,bx,cx,si,di,bp,es
		.enter
	;
	; grab both open and close mutexes (mutexen?)
	; this guarantees no links are opening or closing
	; 
		push	bx,di,es
		mov	si, ds:[bx]			; ds:si = DomainInfo
		mov	bx, ds:[si].DI_openMutex	; bx = open sem
		mov	dx, ds:[si].DI_closeMutex	; dx = close sem
		mov	cx, ax				; cx = timeout
		call	SocketControlEndWrite
		call	SocketPTimedSem			; lock open sem
		jc	timeout
		xchg	bx,dx
		call	SocketPTimedSem			; lock close sem
		jc	unlockTimeout
pastLocks::
		call	SocketControlStartWrite
		pop	bx,di,es
	;
	; see if link opened while we were waiting
	;
findAddress::
		mov	cx, es:[di].SA_addressSize	; cx = size of addr
		movdw	dxbp, esdi			; dx:bp = SocketAddress
		add	bp, offset SA_address		; es:di = address
		call	SocketFindLink			; dx = link offset
		jc	unlockClose
	;
	; unlock open mutex
	;
		mov	si, ds:[bx]
		mov	bx, ds:[si].DI_openMutex
		call	ThreadVSem
	;
	; unlock close mutex (flags preserved)
	;
unlockClose:
		mov	bx, ds:[si].DI_closeMutex
		call	ThreadVSem
done:
		.leave
		ret
	;
	; timed out reading
	;
unlockTimeout:
		mov	bx,dx
		call	ThreadVSem
timeout:
		call	SocketControlStartWrite
		clr	dx			; also clears carry
		pop	bx,di,es
		jmp	done
SocketLockForCreateLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCreateLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open an remember a link

CALLED BY:	(INTERNAL) SocketAddressToLink
PASS:		*ds:bx	- DomainInfo
		es:di	- SocketAddress
		ss:ax	- timeout
RETURN:		carry	- set on error
		ax	- SocketError
		dx	- offset of LinkInfo
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	lock open mutex
	lock close mutex
	verify link didn't open while we were waiting
	release close mutex
	open the link

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCreateLink	proc	near
		uses	bx,cx,si,di,bp,es
		timeout		local	word	push ax
		info		local	word	push bx
		addr		local	fptr	push es,di
		id		local	word
		.enter
	;
	; lock domain and reverify that link doesn't exist
	;
		call	SocketLockForCreateLink
		jc	storeEntry			; continue creation
		tst_clc	dx
		jnz	linkExists
		mov	ax, SE_TIMED_OUT
		stc
linkExists:
		jmp	done
	;
	; remember driver entry point
	;
storeEntry:
		mov	bx, ss:[info]			; *ds:bx = DomainInfo
	;
	; add a new link info entry to the domain
	;
		push	bp
		clr	ax
		mov	cx, es:[di].SA_addressSize	; cx = size of addr
		movdw	dxbp, esdi
		add	bp, offset SA_address
		call	SocketAddLink			; ds:si = link
		pop	bp
	;
	; remember link
	;
		mov	ds:[si].LI_state, OCS_OPENING
		mov	ss:[id], ax
	;
	; setup timeout info
	;
		mov	cx, ss:[timeout]
		call	SocketGetTimeout
		jnc	callDriver
	;
	; we timed out
	;
timedOut:
		mov	si, ss:[info]
		call	DestroyOpeningLink
		mov	si, ds:[si]
		mov	ax, SE_TIMED_OUT
		stc
		jmp	unlockDomain
	;
	; open the actual link
	;
callDriver:
		mov	bx, ds:[bx]			; ds:bx = DomainInfo
		pushdw	ds:[bx].DI_entry
		mov	bx, ds:[bx].DI_client		; client handle
		call	SocketControlEndWrite
		movdw	dssi, ss:[addr]
		mov	ax, ds:[si].SA_addressSize
		add	si, offset SA_address		; ds:si <- link address
		mov	di, DR_SOCKET_LINK_CONNECT_REQUEST
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; ax = link handle,
							; carry on error
		WARNING_C LINK_CONNECT_REQUEST_FAILED		
	;
	; restore control segment pointers
	;
		call	SocketControlStartWrite
		jc	timedOut
		mov	si, ss:[info]
		mov	bx, ss:[id]
		call	SocketFindLinkById
	;
	; record link handle
	;
		mov	si, ds:[si]
		mov	ds:[si][bx].LI_handle, ax
		mov	ds:[si][bx].LI_state, OCS_OPEN
		mov	dx,bx
		mov	ax, SE_NORMAL
	;
	; release lock on domain
	;
unlockDomain:
		mov	bx, ds:[si].DI_openMutex
		push	ax
		call	ThreadVSem
		pop	ax
done:
		.leave
		ret
		
SocketCreateLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyOpeningLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the link which is being opened. 

CALLED BY:	(INTERNAL) SocketCreateLink
PASS:		*ds:si - DomainInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	may initiate domain shutdown

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyOpeningLink	proc	near
		uses	ax,cx,di
		.enter
	;
	; start at the end of the array
	;
		call	ChunkArrayGetCount		; cx = # of elements
		mov	ax,cx
	;
	; get previous entry and check it's state
	;
top:
		dec	ax
		ERROR_S CORRUPT_DOMAIN
		call	ChunkArrayElementToPtr		; ds:di = LinkInfo
		cmp	ds:[di].LI_state, OCS_OPENING
		jne	top
	;
	; remove this link
	;
		call	ChunkArrayDelete
	;
	; possibly schedule the domain to be unloaded
	;
		call	SocketRemoveDomain
done::
		.leave
		ret
DestroyOpeningLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketLoadDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the driver for a domain

CALLED BY:	(EXTERNAL) SocketAddressToDomain, SocketAddressToLink,
		SocketGetAddressController, SocketGetAddressMedium,
		SocketGetAddressSize, SocketGetDomainMedia,
		SocketOpenDomainMedium, SocketResolve
PASS:		ds	- control segment
		dx:bp	- domain name

RETURN:		carry	- set on error
		ax	- SocketError if carry set, preserved otherwise
		bx	- domain handle


DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketLoadDriver	proc	far
		uses	cx,dx,si,di,bp,es
		passedAX	local	word	push	ax
		domainSegment	local	word	push	dx
		driverHandle	local	hptr
		domainHandle	local	lptr
		driverEntry	local	fptr
		driverType	local	byte
		driverName	local	hptr
		.enter
	;
	; grab the driver semaphore
	;
		call	SocketControlEndWrite
		mov	bx, handle dgroup
		call	MemDerefES
		PSem	es, driverSem
		call	SocketControlStartWrite
	;
	; make sure the domain wasn't added while we are waiting
	;
		push	bp
		mov	bp, ss:[bp]
		call	SocketFindDomainLow		; bx = domain
		pop	bp
		jc	alloc
	;
	; if the domain exists in STANDBY mode, go ahead and open
	; it for real
	;
		mov	di, ds:[bx]
		cmp	ds:[di].DI_state, OCS_STANDBY
		je	gotHandle
		clc
		jmp	done
	;
	; handle errors allocating the domain chunk
	;
allocError:
		mov	ax, SE_OUT_OF_MEMORY
		jmp	done
	;
	; allocate a domain
	;
alloc:
		push	bp
		mov	bp, ss:[bp]
		call	SocketCreateDomain		; bx = domain
		pop	bp
		jc	allocError
	;
	; record domain handle
	;
gotHandle:
		mov	di, ds:[bx]
		mov	ds:[di].DI_state, OCS_OPENING
		mov	ss:[domainHandle], bx
		call	SocketControlEndWrite
	;
	; look up the driver name
	;
		push	bp
		mov	ds, ss:[domainSegment]
		mov	si, ss:[bp]			; ds:si = domain name
		ConvDomainNameToIniCat
		mov	cx, es
		mov	dx, offset es:[driverKey]	; cx:dx = key
		clr	bp				; no flags, alloc block
		call	InitFileReadString		; ^hbx=name, cx=size
		pop	bp
		mov	ss:[driverName], bx
		jnc	getType
		ConvDomainNameDone
		mov	ax, SE_UNKNOWN_DOMAIN
		jmp	error
	;
	; look up the driver type
	;
getType:
		mov	cx,es
		mov	dx, offset es:[typeKey]
		call	InitFileReadInteger		; ax = value
		jnc	checkType
		mov	al, SDT_LINK			; default value
checkType:
		Assert	etype, al, SocketDriverType
		mov	ss:[driverType], al
		ConvDomainNameDone
	;
	; move to the driver directory
	;
setPath::
		call	FilePushDir
		mov	bx, SP_SYSTEM			; bx = disk
		segmov	ds,es,ax
		mov	dx, offset es:[driverPath]	; ds:dx = path
		call	FileSetCurrentPath
		jc	cleanup
	;
	; load the driver
	;
useDriver::
		mov	bx, ss:[driverName]
		call	MemLock
		mov	ds,ax
		clr	si				; ds:si = filename
		mov	ax, SOCKET_PROTO_MAJOR
		mov	bx, SOCKET_PROTO_MINOR
		call	GeodeUseDriver			; bx = driver handle
EC <		WARNING_C GEODE_USE_DRIVER_FAILED			>
		mov	ss:[driverHandle], bx
	;
	; whether we succeed or fail, clean up
	;
cleanup:
		pushf
		call	FilePopDir
		mov	bx, ss:[driverName]
		call	MemFree
		popf
	;
	; now check the result of GeodeUseDriver
	;
		mov	ax, SE_CANT_LOAD_DRIVER
		jc	error
	;
	; find the strategy
	;
		mov	bx, ss:[driverHandle]
		call	GeodeInfoDriver		; ds:si = DriverInfoStruct
		movdw	ss:[driverEntry], ds:[si].DIS_strategy, ax
	;
	; call registration
	;
registerDriver::
		push	bp
		pushdw	ss:[driverEntry]
		mov	bx, ss:[domainHandle]		; domain handle
		mov	ds, ss:[domainSegment]
		mov	si, ss:[bp]			; ds:si = domain name
		mov	cl, ss:[driverType]		; SocketDriverType
		mov	dx, vseg SocketDataStrategy
		mov	bp, offset SocketDataStrategy	; dx:bp = callback
		cmp	cl, SDT_DATA
		je	gotStrategy
		mov	dx, vseg SocketLinkStrategy
		mov	bp, offset SocketLinkStrategy
gotStrategy:
		mov	di, DR_SOCKET_REGISTER
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	bp
		jc	regFailed
	;
	; lock library into memory.
	;
	; Please note that this cannot be called while having access to
	; SocketControl because other libraries may be unloaded at the same
	; time and they can need exclusive access to SocketControl.
	;
		mov	dx, bx				; ^hdx = saved client 
		mov	bx, handle 0
		call	GeodeAddReference
		mov	bx, dx				; restore client handle
	;
	; driver returns
	;	ax      = SocketDrError (SDE_ALREADY_REGISTERED)
	;	bx	= client handle
	;	ch	= min header size for outgoing sequenced packets
	;	cl	= min header size for outgoing datagram packets
	;
	; if requested header sizes are smaller then those required by
	; library, use library requirement instead
	;
		cmp	ch, size SequencedPacketHeader
		jge	seqOK
		mov	ch, size SequencedPacketHeader
seqOK:
		cmp	cl, size DatagramPacketHeader
		jge	dgramOK
		mov	cl, size DatagramPacketHeader
dgramOK:
	;	
	; store sizes in domain info
	;
storeInfo::
		call	SocketControlStartWrite
		mov	si, ss:[domainHandle]
		mov	di, ds:[si]			; ds:si = DomainInfo
		mov	ds:[di].DI_client, bx
		mov	ds:[di].DI_seqHeaderSize, ch
		mov	ds:[di].DI_dgramHeaderSize, cl
		movdw	ds:[di].DI_entry, ss:[driverEntry], ax
		segmov	ds:[di].DI_driver, ss:[driverHandle], ax
		segmov	ds:[di].DI_driverType, ss:[driverType], al
		mov	ds:[di].DI_state, OCS_OPEN
	;
	; set up return values
	;
success::
		mov	bx, si
		mov	ax, ss:[passedAX]
		clc
done:
		push 	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx
		VSem	es, driverSem
		.leave
		ret
	;
	; unload driver
	;
regFailed:
		mov	bx, ss:[driverHandle]
		call	GeodeFreeDriver
		mov	bl, al
		mov	ax, SE_CANT_LOAD_DRIVER
		cmp	bl, SDE_MEDIUM_BUSY
		jne	error
		mov	ax, SE_MEDIUM_BUSY
error:
	;
	; destroy the incomplete driver record
	;
		call	SocketControlStartWrite
		mov	bx, ss:[domainHandle]
		call	SocketFreeDomain
		stc
		jmp	done
		
SocketLoadDriver	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGrabMiscLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment the misc counter in a domain

CALLED BY:	(INTERNAL) SocketAddressToDomain,
		SocketCheckMediumConnection, SocketCloseDomainMedium,
		SocketDataConnect, SocketGetAddressController,
		SocketGetAddressMedium, SocketGetAddressSize,
		SocketGetDomainMedia, SocketLinkGetMediumForLink,
		SocketOpenDomainMedium, SocketPassOption,
		SocketQueryAddress, SocketResolve, SocketSendClose
PASS:		*ds:si - DomainInfo (may be locked shared)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGrabMiscLock	proc	far
		uses	di
		.enter
	;
	; increment the ref count
	;
		mov	di, ds:[si]
EC <		cmp	ds:[di].DI_state, OCS_OPEN			>
EC <		ERROR_NE UNEXPECTED_DOMAIN_STATE			>
		inc	ds:[di].DI_miscCount
	;
	; if a shutdown timer is running, kill it
	;
		call	SocketStopDomainTimer
		.leave
		ret
SocketGrabMiscLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketReleaseMiscLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a misc lock and possibly close domain

CALLED BY:	(EXTERNAL) SocketCheckMediumConnection, SocketClose,
		SocketCloseDomainMedium, SocketConnectDatagram,
		SocketDataConnect, SocketGetAddressController,
		SocketGetAddressMedium, SocketGetAddressSize,
		SocketGetDomainMedia, SocketLinkGetMediumForLink,
		SocketOpenDomainMedium, SocketPassOption,
		SocketQueryAddress, SocketResolve, SocketSend,
		SocketSendClose
PASS:		*ds:si - DomainInfo	(must be locked exclusive)
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketReleaseMiscLock	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		pushf
		.enter
	;
	; decrement the misc count
	;
		mov	di, ds:[si]
		dec	ds:[di].DI_miscCount
		jnz	done
	;
	; we are the last misc - check to see if we should close
	;
		tst	ds:[di].CAH_count	; any links?
		jnz	done
		call	SocketRemoveDomain
done:
		.leave
		popf
		ret
SocketReleaseMiscLock	endp


ApiCode	ends

ExtraApiCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddressToDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a SocketAddress, find or create its domain

CALLED BY:	(EXTERNAL) SocketConnectDatagram, SocketSend
PASS:		es:di	- SocketAddress
		ds	- control segment (locked for write)
RETURN:		dx	- domain
		ax	- SocketError
		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	increments DI_miscCount

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddressToDomain	proc	far
		uses	bx,cx,si,di,bp
		.enter
	;
	; find the domain
	;
		movdw	dxbp, es:[di].SA_domain
		call	SocketFindDomain		; bx = domain
		jnc	gotDomain
		call	SocketLoadDriver
		jc	done
gotDomain:
	;
	; set a misc lock on domain
	;
		mov	si,bx
		call	SocketGrabMiscLock
		clc
done:
		mov	dx,bx
		.leave
		ret
SocketAddressToDomain	endp

ExtraApiCode	ends

InfoApiCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       	 SocketGetDomainsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a chunk array of domain names

CALLED BY:	(INTERNAL) SocketGetDomains
PASS:		*ds:si	- variable ChunkArray
RETURN:		carry	- set if ChunkArrayAppend failed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
        Name	Date		Description
        ----	----		-----------
        EW	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetDomainsLow	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; enumerate all the domains in the ini file
	;
		segmov	es, ds, ax			; *es:si = array
		mov	bx, handle dgroup
		call	MemDerefDS			; ds = dgroup
		mov	bx, si				; *es:bx = array
		mov	cx,ds
		mov	dx, offset ds:[domainsKey]	; cx:dx = category
		mov	si, offset ds:[socketCategory]	; ds:si = key
		mov	bp, InitFileReadFlags
		mov	di,cs
		mov	ax, offset SocketGetDomainsCallback
		call	InitFileEnumStringSection
		segmov	ds,es
done::
		.leave
		ret
		
SocketGetDomainsLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetDomainsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback from SocketGetDomains

CALLED BY:	(EXTERNAL) SocketGetDomainsLow via InitFileEnumStringSection
PASS:		ds:si	= string
		cx	= length of string
		es,bx	= data
RETURN:		carry	= set to abort enumeration
DESTROYED:	ax,cx,dx,di,si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetDomainsCallback	proc	far
		uses	bx,ds
		data	local	fptr	push ds,si
		.enter
	;
	; add new chunk array entry
	;
		movdw	dssi, esbx
		mov	ax, cx
		call	ChunkArrayAppend	; ds:di = elt
		jc	done
	;
	; copy string
	;
		segmov	es,ds			; es:di = destination
		movdw	dssi, ss:[data]		; ds:si = source
		LocalCopyNString
		clc
done:
		.leave
		ret
SocketGetDomainsCallback	endp

InfoApiCode	ends


ApiCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketLinkGetMediumForLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query the driver to find the medium used for a particular
		link.

CALLED BY:	(EXTERNAL) SocketCheckListen
PASS:		*ds:bx	= DomainInfo (read access to control segment)
		dx	= link handle
RETURN:		dxax	= MediumType
DESTROYED:	si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketLinkGetMediumForLink proc	near
		uses	cx
		entry	local	fptr.far
		.enter
	;
	; Grab the misc lock of the domain so the domain continues to exist
	; throughout this procedure.
	;
		mov	si, bx
		call	SocketGrabMiscLock
	;
	; Fetch the driver entry into our local variable for the calls and
	; unlock the control segment, as suggested by Eric.
	;
		mov	si, ds:[bx]			; ds:si <- DomainInfo
		movdw	ss:[entry], ds:[si].DI_entry, ax
		call	SocketControlEndRead
		push	bx				; save domain for
							;  unlock
	;
	; First we find the size of an address for the link.
	;
		mov	ax, SGIT_ADDR_SIZE
		mov	di, DR_SOCKET_GET_INFO
		call	ss:[entry]			; ax <- addr size
	;
	; Make room for an address on the stack.
	;
		inc	ax				; word-align the
		andnf	ax, not 1			;  size, please, so
							;  as not to dork the
							;  stack
		sub	sp, ax
	;
	; Ask the driver for the local address of the link, on the assumption
	; we can use it to find the medium.
	;
		segmov	ds, ss
		mov	bx, sp				; ds:bx <- buffer
		push	ax				; save adjustment for
							;  clearing...
		xchg	dx, ax				; dx <- buf size
							; ax <- conn handle
							; (1-byte inst)
		mov_tr	cx, ax				; cx <- conn handle
		mov	ax, SGIT_LOCAL_ADDR
		mov	di, DR_SOCKET_GET_INFO
		call	ss:[entry]			; ax <- addr size
	;
	; Pass that address off to the driver to get the medium & unit.
	;
		mov_tr	dx, ax				; dx <- actual size
		mov	si, bx				; ds:si <- address
		mov	ax, SGIT_MEDIUM_AND_UNIT
		mov	di, DR_SOCKET_GET_INFO
		push	bp
		call	ss:[entry]			; cxdx <- medium
							; bl, bp <- unit info
							;  (ignored)
		pop	bp
	;
	; Clear the address off the stack, please.
	;
		pop	ax				; ax <- buffer size
		add	sp, ax
	;
	; Return the medium in dxax on success.
	;
		mov_tr	ax, cx				; ax <- medium.high
		xchg	ax, dx				; ax <- medium.low,
							;  dx <- medium.high
	;
	; Release the misc lock on the domain.
	;
		call	SocketControlStartWrite		; ds <- control seg
		pop	si				; *ds:si <- domain
		call	SocketReleaseMiscLock
		call	SocketControlWriteToRead
		.leave
		ret
SocketLinkGetMediumForLink		endp

ApiCode		ends
