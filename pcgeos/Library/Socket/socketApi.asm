COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Network extensions
MODULE:		Socket library
FILE:		socketApi.asm

AUTHOR:		Eric Weber, Apr 26, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB SocketCreate            Create a socket

    GLB SocketBind              Bind a socket to a port

    GLB SocketBindInDomain      Bind a socket in one domain only

    GLB SocketListen            Initialize a socket for receiving

    GLB SocketConnect           Connect to a remote port

    GLB SocketCheckListen       get domain of first connect request

    GLB SocketAccept            Accept a connection on a sequenced or
				stream socket

    GLB SocketCloseSend         Close a socket for sending

    GLB SocketClose             Close a socket

    GLB SocketCheckReady        Wait until one or more sockets are ready

    GLB SocketNotImplemented    Stub for unimplemented functions

    GLB SocketSend              Send a packet to a particular address

    GLB SocketRecv              Receive a packet

    GLB SocketAddLoadOnMsg      Load geode when packet arrives on a port

    GLB SocketAddLoadOnMsgInDomain 
				Load geode when packet arrives on a port

    GLB SocketRemoveLoadOnMsg   Remove a load request

    GLB SocketRemoveLoadOnMsgInDomain 
				Remove a load request

    GLB SocketInterrupt         Abort current or next SocketRecv or
				SocketAccept

    GLB SocketGetSocketOption   Set an option for a socket

    GLB SocketSetSocketOption   Set option for a socket

    GLB SocketGetDomains        Get a chunk array of domain names

    GLB SocketGetDomainMedia    Get all media supported by a domain

    GLB SocketGetAddressMedium  Get the medium for an address

    GLB SocketCheckMediumConnection 
				Check if there is an active connection
				through the specified unit of the medium.

				If a point-to-point connection exists
				(e.g., an IRLAP connection), then return
				the address to which the connection exists.
				If the connection is not to a specific
				address (e.g., TCP/IP), then return a null
				address (zero-sized.)

    GLB SocketGetAddressController 
				Get address controller class for a domain

    GLB SocketGetSocketName     Get the address of a connected socket, for
				the domain in which it is connected

    GLB SocketGetPeerName       Get the address to which this socket is
				connected

    GLB SocketResolve           Convert an address into a form that the
				driver can use

    GLB SocketCreateResolvedAddress 
				Creates a SocketAddress structure in a
				global memory block using the passed domain
				and the resolved form of the passed
				unresolved address.

    GLB SocketGetAddressSize    Get the maximum address size for a domain

    GLB SocketOpenDomainMedium  Initialize a low level connection

    GLB SocketCloseDomainMedium Force a domain to close a given medium

    GLB SocketSetMediumBusy	Set whether the medium should appear busy.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/26/94   	Initial revision


DESCRIPTION:
	Exported routines for socket library
		

	$Id: socketApi.asm,v 1.55 97/10/28 00:12:05 brianc Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ApiCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a socket

CALLED BY:	GLOBAL
	
PASS:		al = SocketDeliveryType

RETURN:		carry set on error
		ax = SocketError
		bx = Socket

FATAL ERRORS:	ILLEGAL_DELIVERY_TYPE
		out of memory

PSEUDO CODE/STRATEGY:
	currently there are no errors which can be returned to the user,
	but ax is reserved for future use

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCreate	proc	far
		uses	bp,ds,es
		.enter
		Assert	etype, al, SocketDeliveryType
		call	SocketControlStartWrite
		call	SocketCreateLow
		call	SocketControlEndWrite
		mov	bx,ax				; bx = socket
		mov	ax,0
		jnc	done
		mov	ax, SE_OUT_OF_MEMORY
done:
		.leave
		ret
SocketCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketBind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bind a socket to a port

CALLED BY:	GLOBAL

PASS:		bx	= Socket
		cxdx	= SocketPort
			  (cx = SP_manuf, dx = SP_port)
		bp	= SocketBindFlags
RETURN:		carry set on error
		ax	= SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketBind	proc	far
		uses	bx,cx,dx,si,ds,es
		.enter
		Assert	record, bp, SocketBindFlags
	;
	; reorganize the arguments
	;
		mov	si, bx				; *ds:si = SocketInfo
		movdw	axbx, cxdx			; axbx = SocketPort
		mov	cx, bp				; cx = SocketBindFlags
		clr	dx				; no domain restriction
	;
	; lock control block and call common routine
	;
		call	SocketControlStartWrite
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
		call	SocketBindLow
		call	SocketControlEndWrite
		.leave
		ret
SocketBind	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketBindInDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bind a socket in one domain only

CALLED BY:	GLOBAL
PASS:		bx	= Socket
		cxdx	= SocketPort
			  (cx = SP_manuf, dx = SP_port)
		ds:si	= domain name
		bp	= SocketBindFlags
RETURN:		carry	= set on error
		ax	= SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketBindInDomain	proc	far
		uses	bx,cx,dx,si,di,bp,ds
		.enter
		Assert	record, bp, SocketBindFlags
	;
	; reorganize the arguments
	;
		mov	di, si
		mov	si, bx
		movdw	axbx, cxdx
		mov	cx, bp
		mov	dx, ds
	;
	; lock control block and invoke common routine
	;
		call	SocketControlStartWrite
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
		call	SocketBindLow
		call	SocketControlEndWrite
		.leave
		ret
SocketBindInDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketListen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a socket for receiving

CALLED BY:	GLOBAL

PASS:		bx	= Socket
		cx 	= number of pending connections permitted

RETURN:		carry set on error
		ax	= SocketError
			SE_OUT_OF_MEMORY
			SE_PORT_ALREADY_LISTENING
	
FATAL ERRORS:	ILLEGAL_SOCKET
		ILLEGAL_OPERATION_ON_DATAGRAM_SOCKET
		ILLEGAL_OPERATION_ON_PASSIVE_SOCKET
		SOCKET_NOT_BOUND
		
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketListen	proc	far
		uses	si,ds,es
		.enter
		call	SocketControlStartWrite
		mov	si, bx
EC <		call	ECEnsureSocketNotClosing			>
		call	SocketListenLow
		call	SocketControlEndWrite
		.leave
		ret
SocketListen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to a remote port

CALLED BY:	GLOBAL
PASS:		bx	= Socket
		cx:dx	= SocketAddress
		bp	= timeout
RETURN:		carry set on error
		ax	= SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	check for existing connection
	record potential connection
	send connection request
	block
	if timed out, cleanup and send cancel notice
	return status

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketConnect	proc	far
		uses	bx,cx,dx,si,di,bp,ds,es
		socketHan	local	word	push bx
		timeout		local	dword
		.enter
	;
	; compute the timeout info
	;
		lea	ax, ss:[timeout]
		call	SocketSetupTimeout
	;
	; check the delivery type
	;
		movdw	esdi, cxdx
		call	SocketControlStartWrite
EC <		mov	si, bx						>
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
		call	SocketGetDeliveryType	; cx = SocketDeliveryType
		cmp	cx, SDT_DATAGRAM
		jne	findDomain
		call	SocketConnectDatagram
		jmp	unlockAndExit
	;
	; find the domain, then bind the socket if needed
	;
findDomain:
		call	SocketCheckConnectInterrupt
		jc	unlockAndExit
		
		lea	ax, ss:[timeout]
		call	SocketAddressToLink		; cx = dom,
							; dx = link offset
		jc	unlockAndExit
		call	SocketImplicitBind
		jc	unlockAndExit
	;
	; record details of the pending connection
	;
		call	SocketRegisterConnection	; ax = driver type
		jc	unlockAndExit
	;
	; if we are dealing with a data driver, the connection sequence
	; is handled by a different routine
	;
		cmp	ax, SDT_DATA
		jne	link
		lea	ax, ss:[timeout]
		call	SocketDataConnect
		jmp	unlockAndExit
link:
	;
	; save all the important information on the stack
	;
		sub	sp, size PacketInfo
		call	SetupPacketInfo			; bx = waitSem
		call	SocketControlEndWrite
	;
	; grab the driver exclusively and send the packet
	;
		mov	ax, CCO_OPEN
		call	SendConnectionControl		; send the packet
	;
	; wait for a response
	;
		lea	cx, ss:[timeout]
		call	SocketPTimedSem
	;
	; find out what happened
	; "if at first you don't succeed, destroy all evidence you ever tried"
	;
pastBlock::
		call	SocketControlStartWrite	
		mov	bx, ss:[socketHan]
		call	SocketClearSemaphore
		call	SocketCheckOpenState		; carry set on error,
							; ax = error code
		jc	clearConnection
	;
	; we have a connection, allocate a data queue
	;
		call	SocketAllocQueue
	;
	; unlock control segment and exit
	;
unlockAndExit:
		call	SocketClearSemaphore
		call	SocketControlEndWrite
done::
		.leave
		ret
		
clearConnection:
		call	SocketClearConnection
		jmp	unlockAndExit
		
SocketConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCheckListen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get domain of first connect request

CALLED BY:	GLOBAL

PASS:		axbx	= SocketPort
			  (ax = SP_manuf, bx = SP_port)
		ds:si	= buffer for domain name
		cx	= length of buffer

RETURN:		carry set on error:
			ax	= SocketError
			dx	= destroyed
		carry clear if ok:
			cx	= length of domain name
			ds:si	= non-null terminated domain name
			dxax	= MediumType for the connection
			
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if buffer is too small, copy as much data as will fit and
	return the length of the name before truncation

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCheckListen	proc	far
		uses	bx,si,di,ds,es
		buffer	local	fptr.char	push ds,si
		.enter
	;
	; find the port
	;
		call	SocketControlStartRead
		clr	dx				; no restriction
		call	SocketFindPort			; ds:di=PortArrayEntry
		mov	ax, SE_PORT_NOT_LISTENING
		jc	done
	;
	; find the first port with anything on its listen queue.
	;
		call	SocketFindFirstQueuedListen	; ds:di <- PortInfo
							; *ds:si <- listen queue
		jc	done				; => no socket is
							;  listening
	;
	; find first entry in queue
	;
		clr	ax
		call	ChunkArrayElementToPtr
		mov	ax, SE_LISTEN_QUEUE_EMPTY
		jc	done
	;
	; find the domain and check name size
	;
		mov	bx, ds:[di].CE_domain
		mov	dx, ds:[di].CE_link
		mov	di, ds:[bx]
DBCS <		shl	cx						>
		cmp	cx, ds:[di].DI_nameSize
		jbe	gotSize
		mov	cx, ds:[di].DI_nameSize
gotSize:
	;
	; copy the name
	;
		jcxz	pastCopy
		push	di
		lea	si, ds:[di].DI_name
		movdw	esdi, ss:[buffer]
EC <		call	ECCheckMovsb					>
		rep	movsb
		pop	di
pastCopy:
	;
	; get the size to return
	;
		mov	cx, ds:[di].DI_nameSize
DBCS <		shr	cx						>
DBCS <		ERROR_C INVALID_DOMAIN_NAME_SIZE			>
	;
	; Now determine the medium over which the connection is coming. This
	; is a multi-stage process, since data connections don't record the
	; address with the link.
	;
		call	SocketLinkGetMediumForLink
		clc					; happy
done:
		call	SocketControlEndRead
		.leave
		ret
		
SocketCheckListen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAccept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accept a connection on a sequenced or stream socket

CALLED BY:	GLOBAL
PASS:		bx	= Socket
		bp	= timeout (in ticks)
RETURN:		cx	= new socket for connection
		ax	= SocketError
			SE_TIMED_OUT
		carry	= set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAccept	proc	far
		uses	bx,dx,si,di,bp,ds,es
		timeout	local	dword
		.enter
	;
	; initialize the timeout information
	;
		lea	ax, ss:[timeout]
		call	SocketSetupTimeout
		push	bp
		mov	bp,ax
	;
	; allocate a new socket and initialize it
	;
retry:
		call	SocketControlStartWrite
EC <		mov	si, bx						>
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
		call	SocketPreAccept			; bx=socket,
							; cx=domain, dx=link
		jc	timedOut
	;
	; if this is a data driver, notify the driver
	;
		mov	si, cx
		mov	si, ds:[si]
		cmp	ds:[si].DI_driverType, SDT_DATA
		jne	link
		call	SocketClearSemaphore
		call	SocketPostDataAccept
		call	SocketControlEndWrite
		jc	retry
		jmp	finish		
	;
	; for link drivers, send an ACCEPT packet and wait for a response
	;
link:
		push	bx
		call	SocketFindLinkByHandle		; dx = link offset
		sub	sp, size PacketInfo
		call	SetupPacketInfo			; bx = wait sem
		call	SocketControlEndWrite
	;
	; send the accept packet
	;
		mov	ax, CCO_ACCEPT
		call	SendConnectionControl
	;
	; wait for a response
	;
		call	ThreadPSem			; no timeout
	;
	; find out what happened and update socket appropriately
	;
		call	SocketControlStartWrite
		pop	bx				; bx = new socket
		call	SocketClearSemaphore
		call	SocketPostLinkAccept
		call	SocketControlEndWrite
	;
	; if we got a cancelation, try the next candidate
	;
		jc	retry
finish:
		mov	cx,bx				; cx = new socket
		cmp	ax, SE_NORMAL
		jz	done
		stc
done:
		pop	bp
		.leave
		ret
timedOut:
		call	SocketControlEndWrite
		jmp	done
		
SocketAccept	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCloseSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a socket for sending

CALLED BY:	GLOBAL
PASS:		bx	- socket to close
RETURN:		carry	- set if error
		ax	- SocketError
			SE_SOCKET_NOT_CONNECTED
			SE_SOCKET_ALREADY_CLOSED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCloseSend	proc	far
		uses	si,ds,es
		.enter
		call	SocketControlStartWrite
EC <		mov	si,bx						>
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
	;
	; make sure socket is connected
	;
		mov	ax, SE_SOCKET_NOT_CONNECTED
		mov	si, ds:[bx]
		cmp	ds:[si].SI_state, ISS_CONNECTED
		jne	abort
	;
	; see if it is already closed
	;
		mov	ax, SE_SOCKET_ALREADY_CLOSED
		test	ds:[si].SI_flags, mask SF_SEND_ENABLE
		jnz	stateOK
abort:
		stc
		jmp	done
	;
	; send CCO_CLOSE
	;
stateOK:
		call	SocketSendClose
done:
		call	SocketControlEndWrite
		.leave
		ret
SocketCloseSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a socket

CALLED BY:	GLOBAL
PASS:		bx	- socket
RETURN:		carry	- set on error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:
	Discards any unread data.

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketClose	proc	far
		uses	bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; get exclusive access to control block
	;
		call	SocketControlStartWrite
EC <		mov	si, bx						>
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
	;
	; if the socket handle is zero, just ignore it and pretend
	; everything went fine.  This is just here to avoid crashes,
	; not to be intended functionality.
	;
		tst	bx
	LONG	jz	exitNormal
	;
	; see if the socket is busy
	;
		mov	si, ds:[bx]
		tst	ds:[si].SI_waitSem
		jnz	returnBusy
	;
	; handle datagram socket differently
	;
		cmp	ds:[si].SI_delivery, SDT_DATAGRAM
		jne	sequenced
datagram::
		cmp	ds:[si].SI_state, ISS_CONNECTED
	LONG	jne	freeSocket
	;
	; decrement reference count on driver
	;
		mov	si, ds:[si].DSI_domain
		call	SocketReleaseMiscLock
		mov	si, ds:[bx]
		jmp	freeSocket
	;
	; jump to the appropriate handler
	;
sequenced:
		mov	al, ds:[si].SI_state
		clr	ah
		mov	bp, ax			; bp = InternalSocketState
		jmp	cs:[socketCloseFunctions][bp]

	;
	; can't close a socket if Connect or Accept in progress
	;
returnBusy:
		mov	ax, SE_SOCKET_BUSY
		stc
done:
		call	SocketControlEndWrite
		.leave
		ret

	;
	; send a CCO_CLOSE or call DR_DISCONNECT_REQUEST
	;
sendClose:
		andnf	ds:[si].SI_flags, not mask SF_INTERRUPTIBLE
		ornf	ds:[si].SI_flags, mask SF_DISCARD
		test	ds:[si].SI_flags, mask SF_SEND_ENABLE
		jz	checkClose
		mov	si, ds:[si].SSI_connection.CE_domain
		call	SocketSendClose
		jc	done
	;
	; We must not free the socket until the driver has closed the
	; data connection, which is a full close from its perspective.
	; In the linger case, we block until the full close happens.
	; In the non-linger case, we either free the socket now if the
	; full close happened, or set the closing state and let the
	; full close handler free the socket.  So...
	;
	;	if linger flag clear
	;		if data connection closed
	;			free socket
	;		else if data connection open
	;			set closing state
	;	else if linger flag set
	;		if receive enabled
	;			block until close
	;		free socket
	;
checkClose:
		mov	si, ds:[bx]
EC <		cmp	ds:[si].SI_state, ISS_CONNECTED			>
EC <		ERROR_NE UNEXPECTED_SOCKET_STATE			>
EC <		test	ds:[si].SI_flags, mask SF_SEND_ENABLE		>
EC <		ERROR_NZ UNEXPECTED_SOCKET_STATE			>
		test	ds:[si].SI_flags, mask SF_LINGER
		jnz	linger
		tst	ds:[si].SSI_connection.CE_link
		jz	cleanupConnection	; data connection closed
		mov	ds:[si].SI_state, ISS_CLOSING
		jmp	exitNormal
linger:
		test	ds:[si].SI_flags, mask SF_RECV_ENABLE
		jz	cleanupConnection
	;
	; wait for a CCO_CLOSE packet
	; will wake up prematurely if a data packet arrives, so put
	; it in a loop
	;
waitClose::
		push	bx
		clr	bx
		call	ThreadAllocSem
		mov	ds:[si].SI_waitSem, bx
		call	SocketControlEndWrite		
		call	ThreadPSem		; wait for close or data
		call	SocketControlStartWrite
		pop	bx
		call	SocketClearSemaphore
		jmp	checkClose
	;
	; remove socket from port array
	;
cleanupConnection:
		call	RemoveSocketFromPort
	;
	; free the socket chunk and possibly the port chunk
	;
freeSocket:
		call	SocketFreeLow
exitNormal:
		mov	ax, SE_NORMAL
		clc
		jmp	done
	;
	; free a listening socket
	;
freeListenQueue:
		call	FreeListenQueue
		jmp	freeSocket

socketCloseFunctions	nptr \
	freeSocket,		; ISS_UNCONNECTED
	freeListenQueue,	; ISS_LISTENING
	returnBusy,		; ISS_ACCEPTING
	returnBusy,		; ISS_CONNECTING
	sendClose,		; ISS_CONNECTED
	returnBusy,		; ISS_CLOSING
	freeSocket		; ISS_ERROR		
		
SocketClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a connection with extreme predjudice

CALLED BY:	GLOBAL
PASS:		bx	- socket to reset
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The connection will be unilaterally terminated with no regard
	for the normal handshaking expected by the protocol.  Use
	with caution.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketReset	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
		call	SocketControlStartWrite
EC <		mov	si,bx						>
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
	;
	; make sure socket is connected
	;
		mov	ax, SE_SOCKET_NOT_CONNECTED
		mov	si, ds:[bx]
		cmp	ds:[si].SI_state, ISS_CONNECTED
		jne	abort
	;
	; see if it is already closed
	;
		mov	ax, SE_SOCKET_ALREADY_CLOSED
		test	ds:[si].SI_flags, mask SF_SEND_ENABLE or mask SF_RECV_ENABLE
		jnz	stateOK
abort:
		stc
		jmp	done
	;
	; reset it
	;
stateOK:
		call	SocketResetLow
done:
		call	SocketControlEndWrite
		.leave
		ret
SocketReset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCheckReady
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait until one or more sockets are ready

CALLED BY:	GLOBAL
PASS:		ax	- number of sockets
		ds:si	- array of SocketCheckRequest
		bp	- timeout (in ticks)
RETURN:		cx	- index of socket meeting conditions
		carry	- set on error
		ax	- SocketError
			SE_TIMED_OUT
			SE_SOCKET_BUSY (cx = index of busy socket)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCheckReady	proc	far
		uses	bx,dx,si,di,bp,ds,es
		len	local	word	push ax
		timeout	local	dword
		which	local	word
		.enter
	;
	; set up timeout information
	;
		mov	cx,ax
		lea	ax, ss:[timeout]
		call	SocketSetupTimeout
	;
	; verify array of sockets
	;
		mov	ax, SE_TIMED_OUT
		stc
		jcxz	done
EC <		call	verifyArray					>
	;
	; get exclusive access to control block
	; exclusive access makes it easier to undo any changes later
	;
		segmov		es,ds
		mov		di,si
		call	SocketControlStartWrite
	;
	; setup sockets
	;
		clr	bx
		call	ThreadAllocSem
		lea	si, ss:[which]
		call	SocketCheckReadySetup
pastSetup::
		jc	cleanup			; are the parameters invalid?
		tst	cx			; did we already find a match?
		jnz	pastWait
	;
	; wait on the semaphore
	;
		call	SocketControlEndWrite
		lea	cx, ss:[timeout]
		call	SocketPTimedSem
		call	SocketControlStartWrite
		mov	cx, ss:[which]
		jnc	pastWait
		clr	cx
	;
	; remove our semaphore from the sockets
	;
pastWait:
		mov	ax, ss:[len]
		call	SocketCheckReadyCleanup		; cx = index
	;
	; see if we succeeded
	;
	; since -1 is the largest possible unsigned number, any other
	; number will be below it, so carry will be set if and only if the
	; cmp operands are unequal
	;
		mov	ax, SE_NORMAL
		cmp	cx, -1
		cmc
		jne	cleanup
		mov	ax, SE_TIMED_OUT
	;
	; release control block and exit
	;
cleanup:
		call	ThreadFreeSem
		call	SocketControlEndWrite
done:
		.leave
		ret
	;
	; verify an array of cx SocketCheckRequest at ds:si
	;
if ERROR_CHECK
		.assert (size SocketCheckRequest) eq 4
verifyArray:
		push	cx,si
		Assert	fptr, dssi
		shl	cx
		ERROR_C ADDRESS_OUT_OF_BOUNDS
		shl	cx
		ERROR_C ADDRESS_OUT_OF_BOUNDS
		add	si, cx
		dec	si
		Assert	fptr, dssi
		pop	cx,si
		retn
endif
		
SocketCheckReady	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketNotImplemented
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for unimplemented functions

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry clear
		ax = SE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SocketNotImplemented:far

SocketNotImplemented	proc	far
		WARNING	WARNING_UNIMPLEMENTED_FUNCTION
		stc
		mov	ax, SE_NOT_IMPLEMENTED
		ret
SocketNotImplemented	endp

ApiCode	ends

ExtraApiCode segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a packet to a particular address

CALLED BY:	GLOBAL
PASS:		es:di	= SocketAddress (only if SSF_ADDRESS is set)
		bx	= Socket
		ds:si	= data to send
		cx	= size of data
		ax	= SocketSendFlags
RETURN:		carry	= set on error
		ax	= SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

NOTES:
	SSF_ADDRESS can only be used with datagram sockets
	SSF_URGENT can only be used with non-datagram sockets
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketSend	proc	far
		uses	cx,dx,si,di,bp,ds,es
		dataSize	local	word		push cx
		dataBuffer	local	fptr		push ds,si
		sendFlags	local	SocketSendFlags push ax
		tempStorage	local	word
		.enter
	;
	; validate, validate, validate
	;
		Assert	fptrXIP, dssi
		Assert	record, ax, SocketSendFlags
	;
	; turn on the send flag
	;
		push	bx				; save socket han
		call	SocketControlStartWrite
		call	SocketSetSendFlag
		jnc	getType
		call	SocketControlEndWrite
		pop	bx				; restore socket han
		jmp	busy
	;
	; see what kind of socket we are dealing with
	;
getType::
		call	SocketControlWriteToRead
		call	SocketGetDeliveryType	; cx = SocketDeliveryType
		cmp	cx, SDT_DATAGRAM
		je	datagram
	;
	; SEQUENCED PACKET
	; get the link info
	;
seqPacket::
EC <		test	ss:[sendFlags], mask SSF_ADDRESS		>
EC <		ERROR_NZ ADDRESS_FLAG_REQUIRES_DATAGRAM_SOCKET		>
EC <		test	ss:[sendFlags], mask SSF_OPEN_LINK		>
EC <		ERROR_NZ OPEN_LINK_FLAG_IS_FOR_DATAGRAM_SOCKETS		>
		call	SocketGetLink		; cx = domain handle,
						; dx = link info offset
		jc	unlockAndExit
	;
	; transfer the important info onto stack so we can release
	; our lock on the originals
	;
transfer::
		sub	sp, size PacketInfo
		call	SetupPacketInfo
		call	SocketControlEndRead
	;
	; send the actual data packet
	;
		mov	ax, ss:[sendFlags]
		mov	cx, ss:[dataSize]
		movdw	dssi, ss:[dataBuffer]
		mov	di, sp
		cmp	ss:[di].PI_driverType, SDT_DATA
		jne	link
	;
	; send data via data driver
	;
data::
		call	SocketSendSequencedData
		jmp	done
	;
	; send data via link driver
	;
link:
		call	SocketSendSequencedLink
		jmp	done
	;
	; in case of error, bail out
	;
unlockAndExit:
		call	SocketControlEndRead
		jmp	done
	;
	; DATAGRAM
	;
datagram:
EC <		test	ss:[sendFlags], mask SSF_URGENT			>
EC <		ERROR_NZ URGENT_FLAG_REQUIRES_NON_DATAGRAM_SOCKET	>
	;
	; see if user supplied an address
	;
		test	ss:[sendFlags], mask SSF_ADDRESS
		jnz	userAddress
	;
	; get default address from socket
	;
		call	SocketGetAddress		; es:di=SocketAddress,
							; dx = domain
		jnc	setupDatagram
		call	SocketControlEndRead
		jmp	done
	;
	; parse a user supplied domain
	;
userAddress:
EC <		Assert fptr esdi					>
	;
	; find the domain and get a misc lock on it
	;
		call	SocketControlReadToWrite
		call	SocketAddressToDomain		; dx = domain, ax=err
		jc	cleanupDatagram
setupDatagram:
	;
	; bind the socket, if needed
	;
		mov	cx,dx
		call	SocketImplicitBind
	;
	; copy vital information to stack
	;
		sub	sp, size PacketInfo
		call	SetupDatagramInfo
	;
	; send the packet
	;
		call	SocketControlSuspendLock	; ax = lockType
		mov	ss:[tempStorage], ax
		movdw	dssi, ss:[dataBuffer]
		mov	cx, ss:[dataSize]
		mov	ax, ss:[sendFlags]
		call	SocketSendDatagram		; ax = SocketError
		xchg	ax, ss:[tempStorage]		; ax = lockType
		call	SocketControlResumeLock
		mov	ax, ss:[tempStorage]		; ax = SocketError
	;
	; clean things up, preserving flags and ax
	;
cleanupDatagram:
		pushf
		test	ss:[sendFlags], mask SSF_ADDRESS
		jnz	cleanupUser
	;
	; If the address was in a socket, it is now in a block
	; whose first word is the block handle.  Free it.
	;
		mov	bx, es:0
		call	MemFree
		jmp	cleanupCommon
	;
	; If the address came from the user, we need to release the
	; lock on the domain
	;
cleanupUser:
		mov	si,dx
		call	SocketReleaseMiscLock
	;
	; unlock control block and exit
	; note that EndRead/EndWrite are interchangeable
	;
cleanupCommon:
		call	SocketControlEndRead
		popf					; restore carry
done:
		pop	bx				; bx = socket
		call	SocketClearSendFlag
busy:
		.leave
		ret
SocketSend	endp

FixedCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a packet

CALLED BY:	GLOBAL

PASS:		bx	= Socket
		es:di	= buffer for received data
		cx	= size of buffer
		bp	= timeout (in ticks)
		ax	= SocketReceiveFlags
		ON STACK (only if SRF_ADDRESS is set)
			fptr to SocketAddress structure
			SA_domain, SA_domainSize, SA_addressSize initialized
RETURN:
		cx	= size of data received
		es:di	= filled in with data
		ax	= SocketError
			SE_TIMED_OUT
			SE_CONNECTION_FAILED

DESTROYED:	nothing

NOTES:
	SRF_ADDRESS can only be used with datagram sockets
	SRF_URGENT can only be used with non-datagram sockets

PSEUDO CODE/STRATEGY:
				

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/26/94    	Initial version
	brianc	10/22/98	Moved into fixed code for resolver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRecv	proc	far	userAddress:fptr
		uses	bx,dx,di,ds,es, si
		.enter
		mov	si,ax			; si = receive flags
	;
	; lock the control segment
	;
		call	SocketControlStartRead	; ds=control seg
EC <		call	validateParms					>
	;
	; read the actual data
	;
		push	bp
		pushdw	userAddress
		mov	bp, ss:[bp]
		call	SocketRecvLow
		pop	bp
	;
	; clean up
	;
unlockAndExit::
		call	SocketControlEndRead
		jc	errorExit
		test	si, mask SRF_ADDRESS
		clc
		jmp	done
errorExit:
		test	si, mask SRF_ADDRESS
		stc
done:
		.leave
		jnz	popArgs
		ret
popArgs:
		ret	@ArgSize
	;
	; validate, validate, validate
	;
if ERROR_CHECK
validateParms:
		jcxz	bufferOK
		Assert	fptrXIP, esdi
bufferOK:
		Assert	record, si, SocketRecvFlags
		test	si, mask SRF_ADDRESS
		jz	noAddress
		Assert	fptrXIP, ss:[userAddress]
noAddress:
		push	si
		mov	si,bx
		call	ECCheckSocketLow
		call	ECEnsureSocketNotClosing
		pop	si
		retn
endif

SocketRecv	endp

FixedCode ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddLoadOnMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load geode when packet arrives on a port

CALLED BY:	GLOBAL

PASS:		axbx	= SocketPort
			  (ax = SP_manuf, bx = SP_port)
		bp	= disk handle
		ds:si	= path
		cx	= SocketLoadType

RETURN:		ax	= SocketError
		carry set on error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddLoadOnMsg	proc	far
		uses	dx
		.enter
EC <		Assert	nullTerminatedAscii,dssi			>
EC <		Assert	diskHandle, bp					>
		clr	dx
	;
	; since adding to the file can't fail, add to memory first
	;
		call	SocketAddLoadOnMsgMem
		jc	done
		call	SocketAddLoadOnMsgFile
		mov	ax, SE_NORMAL
		clc
done:
		.leave
		ret
SocketAddLoadOnMsg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddLoadOnMsgInDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load geode when packet arrives on a port

CALLED BY:	GLOBAL

PASS:		axbx	= SocketPort
			  (ax = SP_manuf, bx = SP_port)
		bp	= disk handle
		ds:si	= path
		es:di	= domain name
		cx	= SocketLoadType

RETURN:		ax	= SocketError
		carry set on error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddLoadOnMsgInDomain	proc	far
EC <		Assert	nullTerminatedAscii, dssi			>
EC <		Assert	nullTerminatedAscii, esdi			>
EC <		Assert	diskHandle, bp					>
	;
	; since adding to the file can't fail, add to memory first
	;
		mov	dx,es
		call	SocketAddLoadOnMsgMem
		jc	done
		call	SocketAddLoadOnMsgFile
		mov	ax, SE_NORMAL
		clc
done:
		ret
SocketAddLoadOnMsgInDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRemoveLoadOnMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a load request

CALLED BY:	GLOBAL
PASS:		axbx	= SocketPort
			  (ax = SP_manuf, bx = SP_port)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRemoveLoadOnMsg	proc	far
		uses	dx
		.enter
		clr	dx
		call	SocketRemoveLoadOnMsgFile
		call	SocketRemoveLoadOnMsgMem
		.leave
		ret
SocketRemoveLoadOnMsg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRemoveLoadOnMsgInDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a load request

CALLED BY:	GLOBAL
PASS:		axbx	= SocketPort
			  (ax = SP_manuf, bx = SP_port)
		dx:di	= domain name
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRemoveLoadOnMsgInDomain	proc	far
		call	SocketRemoveLoadOnMsgFile
		call	SocketRemoveLoadOnMsgMem
		ret
SocketRemoveLoadOnMsgInDomain	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort current or next socket operation on this socket

CALLED BY:	GLOBAL
PASS:		bx	- socket handle
RETURN:		carry	- set if error
		ax	- SocketError
			SE_SOCKET_NOT_INTERRUPTIBLE
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If nobody is receiving/accepting/connecting now, this will
	affect the next thread to do so.

	If nobody is sending right now, this will NOT affect the next
	send.  Interrupting sends is therefore subject to race conditions.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketInterrupt	proc	far
		uses	bx,cx,dx,si,di,bp,ds
		.enter
		call	SocketControlStartWrite
EC <		mov	si, bx						>
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
		mov	di, ds:[bx]	; ds:di = SocketInfo
		test	ds:[di].SI_flags, mask SF_INTERRUPTIBLE
		jz	atomic
	;
	; if we are connecting, interrupt the connection
	;
	; note that if we are neither connected nor connecting, it doesn't
	; hurt to check for senders and receivers, although there won't be
	; any of them
	;
		cmp	ds:[di].SI_state, ISS_CONNECTING
		jne	wakeRecv
		call	SocketInterruptConnect		; releases control blk
		jmp	done
	;
	; wake up receivers, present or future
	; no need to grab SI_semSem, since we have exclusive access
	; to control block
	;
wakeRecv:
		or	ds:[di].SI_flags, mask SF_INTERRUPT or mask SF_SINTERRUPT
		call	WakeUpExceptLow
		jnz	wakeSend
		call	WakeUpSocketLow
	;
	; wake up any senders
	;
	; if there is one, turn SINTERRUPT off again so we don't interrupt
	; the next send as well
	;
wakeSend:
		test	ds:[di].SI_flags, mask SF_SENDING
		jz	normal
		and	ds:[di].SI_flags, not mask SF_SINTERRUPT
		call	SocketInterruptSend
normal:
		clr	ax
doneUnlock:
		call	SocketControlEndWrite
done:	
		.leave
		ret
atomic:
		mov	ax, SE_SOCKET_NOT_INTERRUPTIBLE
		stc
		jmp	doneUnlock
SocketInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetSocketOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an option for a socket

CALLED BY:	GLOBAL
PASS:		ax	- SocketOption
		bx	- socket
RETURN:		carry set if information could not be obtained
		others depending on option:
			SO_RECV_BUF:
			SO_SEND_BUF:
				cx = size of buffer (-1 for no limit)
			SO_INLINE: 
			SO_NODELAY:
			SO_LINGER
				cx = TRUE/FALSE

RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The receive queue size is internally a dword, but can only be set
	to a word sized value.  Hence we only need return the low word.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetSocketOption	proc	far
		uses	bx,si,ds
		.enter
	;
	; verify the socket and option
	;
		call	SocketControlStartWrite
EC <		mov	si,bx						>
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
		mov	si, ds:[bx]
		Assert	etype, ax, SocketOption
		mov	bx,ax
		jmp	cs:[getOptionHandlers][bx]
	;
	; read the receive buffer size
	;
recvHandler:
		mov	cx, ds:[si].SI_maxQueueSize.low
		jmp	done
sendHandler:
		mov	cx, ds:[si].SI_maxSendSize
		jmp	done
inlineHandler:
		mov	cx, BW_FALSE
		test	ds:[si].SI_flags, mask SF_INLINE
		jz	done
		mov	cx, BW_TRUE
		jmp	done
nodelayHandler:
		mov	cx, BW_FALSE
		test	ds:[si].SI_flags, mask SF_NODELAY
		jz	done
		mov	cx, BW_TRUE
		jmp	done
ownerHandler:
		mov	cx, ds:[si].SI_owner
		jmp	done
lingerHandler:
		mov	cx, BW_FALSE
		test	ds:[si].SI_flags, mask SF_LINGER
		jz	done
		mov	cx, BW_TRUE
done:				
		clc
		call	SocketControlEndWrite
		.leave
		ret

getOptionHandlers	nptr \
		recvHandler,
		sendHandler,
		inlineHandler,
		nodelayHandler,
		ownerHandler,
		lingerHandler
		
SocketGetSocketOption	endp

ExtraApiCode	ends

InfoApiCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSetSocketOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set option for a socket

CALLED BY:	GLOBAL
PASS:		ax	- SocketOption
		bx	- socket
		others depending on option
			SO_RECV_BUF:
			SO_SEND_BUF:
				cx = size of buffer (-1 for no limit)
			SO_INLINE: 
			SO_NODELAY:
			SO_LINGER:
				cx = TRUE/FALSE

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketSetSocketOption	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	; verify the socket and option
	;
		call	SocketControlStartWrite
EC <		mov	si,bx						>
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
		mov	si, ds:[bx]
		Assert	etype, ax, SocketOption
		mov	bx,ax
		jmp	cs:[setOptionHandlers][bx]
    ;
    ; update the linger flag
    ;
lingerHandler:
		and	ds:[si].SI_flags, not mask SF_LINGER
		and	cx, mask SF_LINGER
		or	ds:[si].SI_flags, cx
		jmp done
	;
	; set the owner
	;
ownerHandler:
EC <		mov	bx, cx						>
EC <		call	ECCheckGeodeHandle				>
		mov	ds:[si].SI_owner, cx
		jmp	done
	;
	; set the receive buffer size
	;
recvHandler:
		clr	ds:[si].SI_maxQueueSize.high
		mov	ds:[si].SI_maxQueueSize.low, cx
		cmp	cx,-1
		mov	ax, SOT_RECV_BUF
		jne	callDriver
		mov	ds:[si].SI_maxQueueSize.high, cx
		jmp	callDriver
	;
	; set the send buffer size
	;
sendHandler:
		mov	ds:[si].SI_maxSendSize, cx
		mov	ax, SOT_SEND_BUF
		jmp	callDriver
	;
	; update the inline flag
	;
inlineHandler:
		and	ds:[si].SI_flags, not mask SF_INLINE
		mov	ax, cx
		and	ax, mask SF_INLINE
		or	ds:[si].SI_flags, ax
		mov	ax, SOT_INLINE
		jmp	callDriver
	;
	; update the nodelay flag
	;
nodelayHandler:
		and	ds:[si].SI_flags, not mask SF_NODELAY
		mov	ax, cx
		and	ax, mask SF_NODELAY
		or	ds:[si].SI_flags, ax
		mov	ax, SOT_NODELAY
	;
	; if we're connected, tell the driver
	; what the new value is
	;
callDriver:
		call	SocketPassOption
done:
		call	SocketControlEndWrite
		.leave
		ret

setOptionHandlers	nptr \
			recvHandler,
			sendHandler,
			inlineHandler,
			nodelayHandler,
			ownerHandler,
			lingerHandler

SocketSetSocketOption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetDomains
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a chunk array of domain names

CALLED BY:	GLOBAL
PASS:		^hbx	- lmem heap
		si	- chunk to use (0 to allocate)
RETURN:		if successful:
			carry clear
			ax = SE_NONE
			si = chunk array of domain names
		if unable to allocate chunk:
			carry set
			ax = SE_OUT_OF_MEMORY
			si = 0
		if unable to resize chunk:
			carry set
			ax = SE_OUT_OF_MEMORY
			si = chunk array with some domain names
			
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetDomains	proc	far
		uses	bx,cx,ds
		.enter
	;
	; lock the lmem block
	;
		Assert	lmem, bx
		call	MemLock
		mov	ds,ax		; ds = segment of lmem
	;
	; allocate a chunk array
	;
		clr	bx		; variable size
		clr	cx		; default header
		clr	al		; no ObjChunkFlags
		call	ChunkArrayCreate
		jc	allocErr
	;
	; fill in the data
	;
		call	SocketGetDomainsLow
		jc	error
		mov	ax, SE_NORMAL
done:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		.leave
		ret
	;
	; if we didn't initialize the array, clear si
	; even if the user supplied a chunk, this tells them it was
	; not initialized
	;
allocErr:
		clr	si
error:
		mov	ax, SE_OUT_OF_MEMORY
		stc
		jmp	done
SocketGetDomains	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetDomainMedia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all media supported by a domain

CALLED BY:	GLOBAL

PASS:		^lbx	= lmem heap
		si	= chunk handle (0 to allocate)
		ds:di	= domain name


RETURN:		carry set on error
		ax	= SocketError
		^lbx:si	= chunk array of MediumType

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetDomainMedia	proc	far
		uses	bx,cx,dx,di,bp,ds,es
		outChunk	local	word	push si
		domain		local	word
		.enter
	;
	; locate driver
	;
		mov	si,bx
		push	bp
		mov	dx,ds
		mov	bp,di				; dx:bp = dom name
		call	SocketControlStartWrite
		call	SocketFindDomain		; bx = dom handle
		jc	noDomain
		pop	bp				; bp = frame pointer
	;
	; lock driver so it can't exit
	;
grab:
		mov	ss:[domain], bx
		xchg	si,bx				; bx=param, si=domain
		call	SocketGrabMiscLock
	;
	; get the driver's entry point
	;
		mov	di, ds:[si]
		pushdw	ds:[di].DI_entry
		call	SocketControlEndWrite
	;
	; lock the user's heap
	;
		Assert	lmem, bx
		call	MemLock
		mov	ds,ax
	;
	; allocate a chunk array
	;
		mov	si, ss:[outChunk]
		mov	bx, size MediumType	; element size
		clr	cx			; default header
		clr	al			; no ObjChunkFlags
		call	ChunkArrayCreate
		jc	allocErr
	;
	; call the driver
	;
callDriver::
		mov	di, DR_SOCKET_GET_INFO
		mov	ax, SGIT_MEDIA_LIST
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		mov	ax, SE_INFO_NOT_AVAILABLE
	;
	; unlock user's block
	;
unlock:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
	;
	; release the driver
	;
		call	SocketControlStartWrite
		push	si
		mov	si, ss:[domain]
		call	SocketReleaseMiscLock
		pop	si
		call	SocketControlEndWrite
	;
	; set return code
	; (carry is still as it was returned from driver)
	;
		jc	done
		mov	ax, SE_NORMAL
done:
		.leave
		ret
	;
	; couldn't allocate chunk array
	;
allocErr:
		popdw	bxax				; discard driver entry
		clr	si
		mov	ax, SE_OUT_OF_MEMORY
		stc
		jmp	unlock
	;
	; domain isn't loaded
	;
noDomain:
		call	SocketLoadDriver
		pop	bp				; bp = frame pointer
		jnc	grab
		call	SocketControlEndWrite
		mov	si, ss:[outChunk]
		jmp	done
		
SocketGetDomainMedia	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetAddressMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the medium for an address

CALLED BY:	GLOBAL
PASS:		ds:di	= SocketAddress
RETURN:		cxdx	= MediumType
		bl	= MediumUnitType
		bp	= MediumUnit
		carry	= set on error
		ax	= SocketError
			SE_OUT_OF_MEMORY
			
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetAddressMedium	proc	far
		uses	si,di,ds,es
		addr		local	fptr	push ds,di
		domain		local	word
		entry		local	fptr.far
		.enter
	;
	; locate driver
	;
		push	bp
		movdw	dxbp, ds:[di].SA_domain
		mov	cx, ds:[di].SA_domainSize	; cx = size of name
		call	SocketControlStartWrite
		call	SocketFindDomain		; bx = dom handle
		jc	noDomain
		pop	bp				; bp = frame pointer
	;
	; lock driver so it can't exit
	;
grab:
		mov	ss:[domain], bx
		mov	si,bx				; si=domain
		call	SocketGrabMiscLock
	;
	; get the driver's entry point
	;
		mov	di, ds:[si]
		movdw	ss:[entry], ds:[di].DI_entry, ax
		call	SocketControlEndWrite
	;
	; call the driver
	;
		push	bp
		movdw	dssi, ss:[addr]
		mov	dx, ds:[si].SA_addressSize
		add	si, offset SA_address
		mov	di, DR_SOCKET_GET_INFO
		mov	ax, SGIT_MEDIUM_AND_UNIT
		lea	bx, ss:[entry]
		call	{fptr}ss:[bx]
		mov	ax,bp
		pop	bp
		mov	ss:[bp], ax		; set return value of bp
		mov	ax, SE_INFO_NOT_AVAILABLE
	;
	; release the driver
	;
release::
		call	SocketControlStartWrite
		mov	si, ss:[domain]
		call	SocketReleaseMiscLock
		call	SocketControlEndWrite
	;
	; set return code
	; (carry is still as it was returned from driver)
	;
		jc	done
		mov	ax, SE_NORMAL
done:
		.leave
		ret
	;
	; domain isn't loaded
	;
noDomain:
		call	SocketLoadDriver
		pop	bp				; bp = frame pointer
		jnc	grab
		call	SocketControlEndWrite
		jmp	done

SocketGetAddressMedium	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCheckMediumConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if there is an active connection through the 
		specified unit of the medium.

		If a point-to-point connection exists (e.g., an IRLAP
		connection), then return the address to which the
		connection exists.  If the connection is not to a
		specific address (e.g., TCP/IP), then return a null
		address (zero-sized.)

CALLED BY:	GLOBAL

PASS:		ds:si	= domain name (null-terminated string)
		es:di	= buffer for address, large enough to accomodate
			  the expected address.  
		cx	= size of address buffer, in bytes.
		dx:ax	= MediumAndUnit

RETURN:   	carry set on error (no connection exists over the unit 
		of the medium):
			ax	= SocketError
				SE_CONNECTION_ERROR
		carry clear if connection exists:
			es:di	= filled in with the address.  If the address
				  is larger than the size of the buffer,
				  then only the beginning of the address, up
				  to the buffer size, will be copied in.
			cx	= number of bytes in address returned.  Caller
				  should check if value returned in cx is 
				  greater than the value passed in.  If so,
				  it may be necessary to call this function
				  again, with a larger address buffer.
			ax	= SE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCheckMediumConnection	proc	far
		uses	bx
		.enter
		mov	bx, SGIT_MEDIUM_CONNECTION
		call	SocketQueryMediumAddress
		.leave
		ret
SocketCheckMediumConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetMediumAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out what the local address of the connection on
		a medium is.  

CALLED BY:	GLOBAL

PASS:		ds:si	= domain name (null-terminated string)
		es:di	= buffer for address, large enough to accomodate
			  the expected address.  
		cx	= size of address buffer, in bytes.
		dx:ax	= MediumAndUnit

RETURN:   	carry set on error (no connection exists over the unit 
		of the medium):
			ax	= SocketError
				SE_CONNECTION_ERROR
		carry clear if connection exists:
			es:di	= filled in with the address.  If the address
				  is larger than the size of the buffer,
				  then only the beginning of the address, up
				  to the buffer size, will be copied in.
			cx	= number of bytes in address returned.  Caller
				  should check if value returned in cx is 
				  greater than the value passed in.  If so,
				  it may be necessary to call this function
				  again, with a larger address buffer.
			ax	= SE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetMediumAddress	proc	far
		uses	bx
		.enter
		mov	bx, SGIT_MEDIUM_LOCAL_ADDR
		call	SocketQueryMediumAddress
		.leave
		ret
SocketGetMediumAddress	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetAddressController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get address controller class for a domain

CALLED BY:	GLOBAL

PASS:		ds:si	= domain name

RETURN:		carry set on error
		ax	= SocketError
		cx:dx	= pointer to class

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetAddressController	proc	far
		uses	bx,si,di,ds
		domain		local	word
		entry		local	fptr.far
		.enter
	;
	; locate driver
	;
		push	bp
		mov	dx,ds
		mov	bp,si				; dx:bp = domain name
		call	SocketControlStartWrite
		call	SocketFindDomain		; bx = dom handle
		jc	noDomain
		pop	bp				; bp = frame pointer
	;
	; lock driver so it can't exit
	;
grab:
		mov	ss:[domain], bx
		mov	si,bx				; si=domain
		call	SocketGrabMiscLock
	;
	; get the driver's entry point
	;
		mov	di, ds:[si]
		movdw	ss:[entry], ds:[di].DI_entry, ax
		call	SocketControlEndWrite
	;
	; call the driver
	;
		add	si, offset SA_address
		mov	di, DR_SOCKET_GET_INFO
		mov	ax, SGIT_ADDR_CTRL
		lea	bx, ss:[entry]
		call	{fptr}ss:[bx]
		mov	ax, SE_INFO_NOT_AVAILABLE
	;
	; release the driver
	;
release::
		call	SocketControlStartWrite
		mov	si, ss:[domain]
		call	SocketReleaseMiscLock
		call	SocketControlEndWrite
	;
	; set return code
	; (carry is still as it was returned from driver)
	;
		jc	done
		mov	ax, SE_NORMAL
done:
		.leave
		ret
	;
	; domain isn't loaded
	;
noDomain:
		call	SocketLoadDriver
		pop	bp				; bp = frame pointer
		jnc	grab
		call	SocketControlEndWrite
		jmp	done

SocketGetAddressController	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetSocketName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the address of a connected socket, for the domain
		in which it is connected
CALLED BY:	GLOBAL
PASS:		bx	- Socket
		es:di	- SocketAddress
			SA_domain pointer initialized
			SA_domainSize, SA_addressSize set to buffer sizes
RETURN:		es:di	- filled in, sizes updated
		carry set on error
		ax	= SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

NOTES:
	If the domain buffer is too small, the domain name will be truncated
	to fit.  This means the null will be truncated, and on a DBCS system
	half a character may be copied if the buffer is of odd size.

	If the address buffer is too small, all that is guaranteed is that
	SA_addressSize will be the required size.  The driver may or may not
	write any data to the address buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetSocketName	proc	far
		uses	bx,cx,dx,si,di,bp,ds
		.enter
	;
	; validate the socket
	;
		call	SocketControlStartRead
		mov	si,bx
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
	;
	; copy the domain name and port number
	;
		call	SocketGetDomainName
		call	SocketGetLocalPort
	;
	; query the driver for the address
	;
		mov	ax, SGIT_LOCAL_ADDR
		call	SocketQueryAddress		; upgrades lock
		call	SocketControlEndWrite
		
		.leave
		ret
SocketGetSocketName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetPeerName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the address to which this socket is connected

CALLED BY:	GLOBAL
PASS:		bx	- Socket
		es:di	- SocketAddress
			SA_domain pointer initialized
			SA_domainSize, SA_addressSize set to buffer sizes
RETURN:		es:di	- filled in, sizes updated
		carry set on error
		ax	= SocketError
DESTROYED:	nothing

NOTES: see notes under SocketGetSocketName

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetPeerName	proc	far
		uses	si,ds
		.enter
	;
	; validate the socket
	;
		call	SocketControlStartRead
		mov	si,bx
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
	;
	; copy the domain name and port number
	;
		call	SocketGetDomainName
		call	SocketGetRemotePort
	;
	; query the driver for the address
	;
		mov	ax, SGIT_REMOTE_ADDR
		call	SocketQueryAddress		; upgrades lock
		call	SocketControlEndWrite
		.leave
		ret
SocketGetPeerName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketResolve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an address into a form that the driver can use

CALLED BY:	GLOBAL
PASS:		dx:bp	= domain name
		ds:si	= buffer for address to be resolved
		cx	= size of the address
		es:di	= buffer for resolved address
		ax	= size of resolved address buffer
RETURN:		carry clr if address returned
		  es:di = buffer filled w/non-null terminated addr if buffer
			  is big enough
		  cx	= size of resolved address

		carry set if couldn't resolve it or buffer too small
		  ax	= SocketError
		  SE_DESTINATION_UNREACHABLE: address doesn't exist in network
		  SE_TEMPORARY_ERROR: address unreachable temporarily
		  SE_CANT_LOAD_DRIVER: driver for the domain is not found
		  SE_BUFFER_TOO_SMALL: buffer was too small
		  	cx	= buffer size needed

DESTROYED:	contents of es:di if error occurs

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketResolve	proc	far
		uses	bx,dx,bp,es,di,ds,si
		.enter
	;
	; Find or load the appropriate driver to call
	;
		push	ds, si
		call	SocketControlStartWrite	; ds	= control segment
		call	SocketFindDomain	; bx	= domain handle
		jnc	domainExist
		call	SocketLoadDriver	; bx	= domain handle
		jc	driverError
domainExist:
	;
	; bx = domain handle of the driver to query
	;
		mov	si, bx			; *ds:si = domain info
		call	SocketGrabMiscLock	; nothing changed
		mov	si, ds:[si]		; ds:si = domain info
		movdw	dxbp, esdi		; dxbp = buff for resovled addr
		segmov	es, ds:[si].DI_entry.high
		mov	di, ds:[si].DI_entry.low; esdi = entry point
driverError:
		call	SocketControlEndWrite	; nothing changed
		pop	ds, si
		jc	loadFailure
	;
	; Resolve the address
	; esdi = driver entry point
	;
		push	ax				; save buffer size
		push	bx				; save domain handle

		push	di				; save entry offset
		pushdw	esdi				; push args to PCFOM
		mov	di, DR_SOCKET_RESOLVE_ADDR
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; cx = output size
		pop	di				; es:di = entry point
	;
	; Unlock driver.
	;
		call	SocketControlStartWrite
		pop	si				; *ds:si = DomainInfo
		call	SocketReleaseMiscLock
		call	SocketControlEndWrite
		jnc	checkSize
	;
	; convert error message
	;
		pop	dx			; discard buffer size
		cmp	al, SDE_DESTINATION_UNREACHABLE
		jne	next2
		mov	al, SE_DESTINATION_UNREACHABLE
		jmp	doneC
next2:
		cmp	al, SDE_INTERRUPTED
		jne	next3
		mov	al, SE_INTERRUPT
		jmp	doneC
next3:
		cmp	al, SDE_LINK_OPEN_FAILED
		jne	next4
		mov	al, SE_LINK_FAILED
		jmp	doneC
next4:
		mov	al, SE_TEMPORARY_ERROR
doneC:
		stc
		jmp	done
	;
	; check for short output buffer
	;
checkSize:
		pop	ax		; ax = user buffer size
		cmp	ax, cx
		mov	ax, SE_BUFFER_TOO_SMALL
		jc	done		; jc = jb - buffer was too small
		mov	ax, SE_NORMAL
done:
		.leave
		ret
loadFailure:
		mov	ax, SE_CANT_LOAD_DRIVER
		jmp	doneC
SocketResolve	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCreateResolvedAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a SocketAddress structure in a global memory block
		using the passed domain and the resolved form of the passed
		unresolved address.

CALLED BY:	(GLOBAL)
PASS:		dx:bp	= domain name
		ds:si	= unresolved address
		cx	= size of the unresolved address
RETURN:		carry clear if address returned:
			ax	= handle of block holding the SocketAddress
				  (with domain pointing to the passed
				  domain string; it's not copied in)
		carry set if couldn't create address:
			ax	= SocketError
		  SE_DESTINATION_UNREACHABLE: address doesn't exist in network
		  SE_TEMPORARY_ERROR: address unreachable temporarily
		  SE_CANT_LOAD_DRIVER: driver for the domain is not found
		  SE_OUT_OF_MEMORY: unable to allocate SocketAddress block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCreateResolvedAddress proc	far
		uses	bx, cx, ds, si, es, di
		.enter
	;
	; Perform initial resolution attempt to get the proper size for the
	; resolved address buffer. Can't use SocketGetAddressSize, since some
	; drivers can't provide accurate info without seeing the unresolved
	; address.
	;
EC <		movdw	esdi, dssi	; prevent bound-check death	>
		mov	bx, cx		; save unres address size
   		clr	ax
		call	SocketResolve
		jnc	haveSize	; !!!
		cmp	ax, SE_BUFFER_TOO_SMALL
		jne	error
haveSize:
	;
	; Use the returned size to allocate a block for the SocketAddress and
	; the data.
	;
		mov	ax, cx
		add	ax, size SocketAddress
		push	bx, cx		; save unres addr size & res addr size
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		mov_tr	di, ax
		pop	cx, ax		; cx <- unres addr size
					; ax <- res addr buffer size
		jc	noMemory
	;
	; Resolve again to actually yield the resolved address.
	;
		mov	es, di
		movdw	es:[SA_domain], dxbp
		mov	es:[SA_addressSize], ax
		mov	di, offset SA_address
		call	SocketResolve
		jc	freeBuffer
	;
	; Unlock the buffer and return its handle.
	;
		call	MemUnlock
		mov_tr	ax, bx		; ax <- buffer handle
done:
		.leave
		ret

freeBuffer:
		call	MemFree
error:
		stc
		jmp	done

noMemory:
		mov	ax, SE_OUT_OF_MEMORY
		jmp	error
SocketCreateResolvedAddress endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetAddressSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the maximum address size for a domain

CALLED BY:	GLOBAL
PASS:		ds:si	- domain name
RETURN:		cx	- maximum address size
		ax	- SocketError
		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetAddressSize	proc	far
		uses	bx,dx,si,di,ds
		entry	local	fptr.far
		domain	local	lptr
		.enter
	;
	; locate driver
	;
		push	bp
		mov	dx, ds
		mov	bp, si				; dx:bp = domain name
		call	SocketControlStartWrite
		call	SocketFindDomain		; bx = dom handle
		jc	noDomain
		pop	bp				; bp = frame pointer
	;
	; lock driver so it can't exit
	;
grab:
		mov	ss:[domain], bx
		mov	si, bx				; si=domain
		call	SocketGrabMiscLock
	;
	; get the driver's entry point
	;
		mov	di, ds:[si]
		movdw	ss:[entry], ds:[di].DI_entry, ax
		call	SocketControlEndWrite
	;
	; call the driver
	;
		add	si, offset SA_address
		mov	di, DR_SOCKET_GET_INFO
		mov	ax, SGIT_ADDR_SIZE
		lea	bx, ss:[entry]
		call	{fptr}ss:[bx]			; ax = size
		mov	cx, ax
		mov	ax, SE_INFO_NOT_AVAILABLE
	;
	; release the driver
	;
release::
		call	SocketControlStartWrite
		mov	si, ss:[domain]
		call	SocketReleaseMiscLock
		call	SocketControlEndWrite
	;
	; set return code
	; (carry is still as it was returned from driver)
	;
		jc	done
		mov	ax, SE_NORMAL
done:
		.leave
		ret
	;
	; domain isn't loaded
	;
noDomain:
		call	SocketLoadDriver
		pop	bp				; bp = frame pointer
		jnc	grab
		call	SocketControlEndWrite
		jmp	done

SocketGetAddressSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketOpenDomainMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a low level connection

CALLED BY:	GLOBAL
PASS:		cx:dx	- SocketAddress
		bp	- timeout
RETURN:		carry set on error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	9/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketOpenDomainMedium	proc	far
		uses	bx,cx,dx,si,di,bp,ds,es
		.enter
		Assert	fptrXIP, cxdx
	;
	; locate driver
	;
		push	cx,dx,bp
		movdw	esdi, cxdx
		movdw	dxbp, es:[di].SA_domain		; dx:bp = domain
		Assert	fptrXIP, dxbp
		call	SocketControlStartWrite
		call	SocketFindDomain		; bx = dom handle
		jnc	grab
		call	SocketLoadDriver
		jc	error
	;
	; lock driver so it can't exit
	;
grab:
		mov	si, bx				; si=domain
		call	SocketGrabMiscLock
	;
	; get the driver's entry point
	;
		mov	si, ds:[si]
		movdw	esdi, ds:[si].DI_entry, ax
		mov	ax, ds:[si].DI_client
error:
		call	SocketControlEndWrite
		pop	ds,si,bp
		jc	done
	;
	; call the driver
	;
		push	bx
		pushdw	esdi				; driver entry point
		mov	cx, bp				; cx = timeout
		mov	bx, ax				; bx = client handle
		mov	ax, ds:[si].SA_addressSize	; ax = addr size
		add	si, offset SA_address		; ds:si = addr
		mov	di, DR_SOCKET_MEDIUM_CONNECT_REQUEST
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; ax = error
		pop	bx
	;
	; release the driver
	;
release::
		call	SocketControlStartWrite
		mov	si, bx
		call	SocketReleaseMiscLock
		call	SocketControlEndWrite
	;
	; set return code
	; (carry is still as it was returned from driver)
	;
		CheckHack <SDE_NO_ERROR eq SE_NORMAL>
		jnc	done
		call	SocketMapConnectError
done:
		.leave
		ret
		
SocketOpenDomainMedium	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCloseDomainMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force a domain to close a given medium

CALLED BY:	GLOBAL

PASS:		ds:si	- domain name
		dxbx	- MediumAndUnit
		ax	- nonzero to force close

RETURN:		carry	- clear if actually closed
		ax	- nonzero if carry set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If ax=0, a link will not be closed if there is a connection
	over it.  If ax=1, it will be closed regardless.

	Carry is returned if either:
	   * no links exist in the domain and medium specified
	   * a link exists but is busy, and force close was not specified

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCloseDomainMedium	proc	far
		uses	bx,dx,si,di,ds
		passedBX	local	word	push bx
		entry		local	fptr.far
		domain		local	lptr
		.enter
		Assert	fptrXIP, dxbx
	;
	; locate driver
	;
		push	bp, dx
		mov	dx, ds
		mov	bp, si				; dx:bp = domain name
		call	SocketControlStartWrite
		call	SocketFindDomain		; bx = dom handle
		pop	bp, dx				; bp = frame pointer
		jc	noDomain
	;
	; lock driver so it can't exit
	;
grab::
		mov	ss:[domain], bx
		mov	si, bx				; si=domain
		call	SocketGrabMiscLock
	;
	; get the driver's entry point
	;
		mov	di, ds:[si]
		movdw	ss:[entry], ds:[di].DI_entry, si
		call	SocketControlEndWrite
	;
	; call the driver
	;
		push	bp, bx
		mov	di, DR_SOCKET_CLOSE_MEDIUM
		mov	bx, ss:[passedBX]
		lea	bp, ss:[entry]
		call	{fptr}ss:[bp]			; ax = size
		pop	bp, bx
	;
	; release the driver
	;
release::
		call	SocketControlStartWrite
		mov	si, ss:[domain]
		call	SocketReleaseMiscLock
noDomain:
		call	SocketControlEndWrite
	;
	; ax=BW_TRUE if carry set, BW_FALSE otherwise
	; (carry is still as it was returned from driver)
	;
		mov	ax, 0
		rcl	ax
		neg	ax
done::
		.leave
		ret

SocketCloseDomainMedium	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSetMediumBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set whether the given medium looks busy even when
		there are no active connections.  Medium should
		be restored to normal as soon as medium may be
		allowed to close.

CALLED BY:	GLOBAL

PASS:		ds:si	= domain name 
		dxbx	= MediumAndUnit
		cx	= TRUE to mark medium always busy
			  FALSE to return medium to normal

RETURN:		carry set if error

DESTROYED:	nothing

NOTES:
		Should only be used by applications wishing to prevent
		non-forcing SocketCloseDomainMedium from closing the
		medium when there are no active connections.  An
		example would be an application which makes a series
		of connections with pauses between each connection
		and doesn't want the medium closed during a pause.


PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/17/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketSetMediumBusy	proc	far
		uses	ax, bx, dx, bp, si, di, ds, es
		.enter

		Assert	fptrXIP, dxbx
	;
	; locate driver
	;
		push	dx, bx, ds, si
		mov	dx, ds
		mov	bp, si				; dx:bp = domain name
		call	SocketControlStartWrite
		call	SocketFindDomain		; bx = dom handle
		mov	si, bx				; *ds:si = DomainInfo
		pop	dx, bx, es, bp			; dx:bx = med & unit
							; es:bp = domain name
		jc	noDomain
	;
	; lock driver so it can't exit & get driver's entry point
	;
		call	SocketGrabMiscLock
		mov	di, ds:[si]
		pushdw	ds:[di].DI_entry
		call	SocketControlEndWrite
	;
	; call the driver
	;
		xchg	si, bp				; bp = domain
		segmov	ds, es, ax			; ds:si = domain name
		mov	ax, MOT_ALWAYS_BUSY
		mov	di, DR_SOCKET_SET_MEDIUM_OPTION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; release the driver.  flags preserved below.
	;
		call	SocketControlStartWrite
		mov	si, bp				; *ds:si = DomainInfo
		call	SocketReleaseMiscLock
noDomain:
		call	SocketControlEndWrite		

		.leave
		ret
SocketSetMediumBusy	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketInterruptResolve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt SocketResolve

CALLED BY:	GLOBAL
PASS:		dx:bp	= domain name
		ds:si	= address being resolved
		cx	= size of address
RETURN:		carry set on error
		ax	= SocketExtendedError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketInterruptResolve	proc	far
		uses	bx, si, di, ds, es
		.enter
	;
	; validate
	;
		Assert	fptrXIP, dxbp
		Assert	fptrXIP, dssi
	;
	; locate driver
	;
		segmov	es, ds				; es:si = address
		call	SocketControlStartWrite
		call	SocketFindDomain		; bx = dom handle
		jc	noDomain
	;
	; lock driver so it can't exit
	;
Grab::
		Push	si
		mov	si, bx				; *ds:si = domain
		call	SocketGrabMiscLock
		pop	si
	;
	; get the driver's entry point
	;
		mov	di, ds:[bx]
		pushdw	ds:[di].DI_entry
		call	SocketControlEndWrite
	;
	; call the driver
	;
		segmov	ds, es				; ds:si = address
		mov	di, DR_SOCKET_STOP_RESOLVE
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; release the driver
	;
release::
		call	SocketControlStartWrite
		mov	si, bx				; *ds:si = domain
		call	SocketReleaseMiscLock
noDomain:
		call	SocketControlEndWrite
done::
	;
	; Don't bother trying to figure out if the interrupt happened
	; or not.  
	;
		clr	ax
		.leave
		ret
SocketInterruptResolve	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketResolveLinkLevelAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a socket level address (i.e. ip address) into the
		address the hardware address the link driver delivers it to
		(i.e. ethernet mac addresss). Most link drivers won't support
		this. When supported, will most likely only work if the
		requested SocketAddress exists on the same local network.

CALLED BY:	GLOBAL
PASS:		ds:si   = SocketAddress
		cx:dx   = buffer
		bx	= size of buffer (0 if just checking for existance)
RETURN:		ax	= SocketError
		bx	= Address size
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ED	06/02/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketResolveLinkLevelAddress	proc	far
	uses	ax, bx, cx, dx, di, si, ds, es
		bufSize		local	word	push bx
		addr		local	fptr	push ds,si
		buffer		local	fptr	push cx,dx
		domain		local	word
		.enter

		segmov	es, ds, ax
		call	SocketControlStartWrite
		mov	di, si
		call	SocketAddressToDomain		; dx = dom handle
		jc	srllaNoDomain

	; get entry point
		mov	si, dx
		mov	ss:[domain], si
		mov	di, ds:[si]
		pushdw	ds:[di].DI_entry
		call	SocketControlEndWrite
	; call the driver
		movdw	dssi, addr
		mov	di, DR_SOCKET_RESOLVE_LINK_LEVEL_ADDRESS
		movdw	cxdx, buffer
	; load ax with error in case the link driver doesn't support
	; the function.
		mov	ax, SE_NOT_IMPLEMENTED
		mov	bx, bufSize
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	; release the driver
		call	SocketControlStartWrite
		push	si
		mov	si, ss:[domain]
		call	SocketReleaseMiscLock
		pop	si
		call	SocketControlEndWrite
		
srllaNoDomain:

		.leave
		ret
SocketResolveLinkLevelAddress	endp

InfoApiCode	ends
