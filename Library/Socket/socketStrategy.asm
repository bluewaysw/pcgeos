COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Network extensions
MODULE:		socket library
FILE:		socketStrategy.asm

AUTHOR:		Eric Weber, May 24, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB SocketRegister          Register a domain or get library protocol

    GLB SocketLinkStrategy      Entry point for socket drivers

    GLB SocketDataStrategy      Entry point for data drivers

    INT SocketInvalidOperation  The requested SCO is not valid for the
				entry point to which it was passed

    INT SocketGetProtocol       Get the protocol expected of a driver

    INT SocketAddDomainRaw      Add a domain

    INT SocketLinkOpened        Add a new link

    INT SocketLinkClosed        Driver has closed a link

    INT SocketLinkPacket        Receive a packet from a link driver

    INT SocketDataPacket        A data packet has arrived from a data
				driver

    INT SocketConnectRequest    Data driver wants to open a connection

    INT SocketConnectionClosed  A data driver connection has closed

    INT SocketDatagramException Handle an exception for a datagram socket

    INT SocketUrgentData        Receive an urgent data packet from a data
				driver

    INT SocketLinkGetInfo       Get information about a link connection

    INT SocketDataGetInfo       Get information about a data connection

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/24/94   	Initial revision


DESCRIPTION:
	Handle requests from the driver
		

	$Id: socketStrategy.asm,v 1.1 97/04/07 10:46:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StrategyCode	segment resource

DefSocketDispatch	macro	base, func, cnst
	.assert ($-base) eq cnst, <dispatch table is corrupted>
	.assert (type func eq near)
		nptr.near	func
endm

DefBasicDispatch	macro	func, cnst
		DefSocketDispatch socketBasicDispatchTable, func, cnst
endm

DefLinkDispatch		macro	func, cnst
		DefSocketDispatch socketLinkDispatchTable, func, cnst
endm

DefDataDispatch		macro	func, cnst
		DefSocketDispatch socketDataDispatchTable, func, cnst
endm


socketBasicDispatchTable label	nptr.near
	DefBasicDispatch	SocketGetProtocol	SCO_GET_PROTOCOL
	DefBasicDispatch	SocketAddDomainRaw	SCO_ADD_DOMAIN

BASIC_DISPATCH_TABLE_SIZE equ	$-socketBasicDispatchTable

socketLinkDispatchTable	label	nptr.near
	DefLinkDispatch	SocketGetProtocol	SCO_GET_PROTOCOL
	DefLinkDispatch	SocketInvalidOperation	SCO_ADD_DOMAIN
	DefLinkDispatch	SocketLinkOpened	SCO_LINK_OPENED
	DefLinkDispatch	SocketLinkClosed	SCO_LINK_CLOSED
	DefLinkDispatch	SocketLinkPacket	SCO_RECEIVE_PACKET
	DefLinkDispatch	SocketInvalidOperation	SCO_CONNECT_REQUESTED
	DefLinkDispatch	SocketInvalidOperation	SCO_CONNECT_CONFIRMED
	DefLinkDispatch	SocketInvalidOperation	SCO_CONNECT_FAILED
	DefLinkDispatch	SocketInvalidOperation	SCO_EXCEPTION
	DefLinkDispatch	SocketInvalidOperation	SCO_RECEIVE_URGENT_DATA
	DefLinkDispatch	SocketLinkGetInfo	SCO_GET_INFO

LINK_DISPATCH_TABLE_SIZE equ	$-socketLinkDispatchTable

socketDataDispatchTable label	nptr.near
	DefDataDispatch	SocketGetProtocol	SCO_GET_PROTOCOL
	DefDataDispatch	SocketInvalidOperation	SCO_ADD_DOMAIN
	DefDataDispatch	SocketInvalidOperation	SCO_LINK_OPENED
	DefDataDispatch	SocketConnectionClosed	SCO_CONNECTION_CLOSED
	DefDataDispatch	SocketDataPacket	SCO_RECEIVE_PACKET
	DefDataDispatch	SocketConnectRequest	SCO_CONNECT_REQUESTED
	DefDataDispatch	SocketConnectConfirm	SCO_CONNECT_CONFIRMED
	DefDataDispatch	SocketConnectFailed	SCO_CONNECT_FAILED
	DefDataDispatch	SocketDatagramException	SCO_EXCEPTION
	DefDataDispatch	SocketUrgentData	SCO_RECEIVE_URGENT_DATA
	DefDataDispatch	SocketDataGetInfo	SCO_GET_INFO

DATA_DISPATCH_TABLE_SIZE equ	$-socketDataDispatchTable


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a domain or get library protocol

CALLED BY:	GLOBAL (socket drivers)
PASS:		di - SocketClientOperation
		others depending on di
RETURN:		depends on di
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRegister	proc	far
		cmp	di, BASIC_DISPATCH_TABLE_SIZE
		ERROR_AE INVALID_SOCKET_CLIENT_OPERATION
		call	cs:[socketBasicDispatchTable][di]
done::
		ret
SocketRegister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketLinkStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for link drivers

CALLED BY:	GLOBAL
PASS:		di	- SocketClientOperation
		others depending on di
RETURN:		depends on di
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketLinkStrategy	proc	far
		cmp	di, LINK_DISPATCH_TABLE_SIZE
		ERROR_AE INVALID_SOCKET_CLIENT_OPERATION
		call	cs:[socketLinkDispatchTable][di]
done::
		ret
SocketLinkStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketDataStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for data drivers

CALLED BY:	GLOBAL

PASS:		di	- SocketClientOperation
		others depending on di
RETURN:		depends on di
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketDataStrategy	proc	far
		cmp	di, DATA_DISPATCH_TABLE_SIZE
		ERROR_AE INVALID_SOCKET_CLIENT_OPERATION
		call	cs:[socketDataDispatchTable][di]
done::
		ret
SocketDataStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketInvalidOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The requested SCO is not valid for the entry point to
		which it was passed

CALLED BY:	SocketLinkStrategy, SocketDataStrategy
PASS:		nothing
SIDE EFFECTS:	does not return

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketInvalidOperation	proc	near
		ERROR	INVALID_SOCKET_CLIENT_OPERATION
SocketInvalidOperation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the protocol expected of a driver

CALLED BY:	SocketLinkStrategy
PASS:		nothing
RETURN:		cx	- major protocol
		dx	- minor protocol
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetProtocol	proc	near
		mov	cx, SOCKET_PROTO_MAJOR
		mov	dx, SOCKET_PROTO_MINOR
		ret
SocketGetProtocol	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddDomainRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a domain

CALLED BY:	SocketLinkStrategy
PASS:		ax	- client handle
		ch	- minimum header size for outgoing sequenced packets
		cl	- minimum header size for outgoing datagram packets
		dl	- SocketDriverType
		ds:si	- domain name (null terminated)
		es:bx	- driver entry point (fptr)
RETURN:		bx	- domain handle
		cx:dx	- vfptr to appropriate strategy routine
		carry	- set if domain already registered
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddDomainRaw	proc	near
		call	SocketAddDomain
		pushf
	;
	; lock the driver and ourselves into memory
	;
		jc	getEntry
		push	bx
		mov	bx,bp
		call	GeodeAddReference
		mov	bx, handle 0
		call	GeodeAddReference
		pop	bx
	;
	; choose the appropriate entry point
	;
getEntry:
		cmp	dl, SDT_LINK
		je	link
		mov	cx, vseg SocketDataStrategy
		mov	dx, offset SocketDataStrategy
		jmp	done
link:
		mov	cx, vseg SocketLinkStrategy
		mov	dx, offset SocketLinkStrategy
done:
		popf
		ret
SocketAddDomainRaw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketLinkOpened
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new link

CALLED BY:	SocketLinkStrategy
PASS:		ds:si	- address
		cx	- address size
		ax	- connection handle
		bx	- domain handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	there is no need to grab domain specific semaphores, since the
	entire operation can be completed without unlocking the control
	block

	if the user is attempting to open this same link, we don't do
	anything, but assume the driver will return success on the user's
	thread

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketLinkOpened	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
		movdw	dxbp, dssi
		call	SocketControlStartWrite
	;
	; see if the link already is known
	;
		call	SocketFindLink	; dx = offset of link info
		jnc	update
	;
	; new link - add it to the table
	;
		call	SocketAddLink
		jmp	done
	;
	; we already know about the link
	;
	; unless the the driver is very confused, we must be trying to
	; open the link from our side at the same time the driver is
	; opening it from the driver's side
	;
update:
	;	call	SocketMarkLinkOpen
done:
		call	SocketControlEndWrite
		clc			; *HACK* undocumented return value
		.leave
		ret
SocketLinkOpened	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketLinkClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Driver has closed a link

CALLED BY:	SocketLinkStrategy
PASS:		ax	= link handle
		bx	= domain handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If the link is already being closed by this side, wait until our
	close request completes.

	The driver will not reuse the connection handle, since it knows this
	call is in progress.  Hence we don't need to worry about checking
	the link id, like we do in SocketCloseLink.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketLinkClosed	proc	near
		uses	ax,bx,ds,es
		.enter
	;
	; get the driver's link close semaphore
	;
	; this means that there will be no DR_SOCKET_DISCONNECT_REQUEST in
	; progress
	;
		push	bx,ax
		call	SocketControlStartWrite
		mov	bx, ds:[bx]
		mov	bx, ds:[bx].DI_closeMutex
		call	SocketControlEndWrite
		call	ThreadPSem
	;
	; remove the actual link, if it still exists
	;
		pop	bx,ax
		call	SocketControlStartWrite
		call	SocketRemoveLink
	;
	; unlock the semaphore
	;
		mov	bx, ds:[bx]
		mov	bx, ds:[bx].DI_closeMutex
		call	ThreadVSem
		call	SocketControlEndWrite
		.leave
		clc				; *HACK*
		ret
SocketLinkClosed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a packet from a link driver

CALLED BY:	SocketLinkStrategy
PASS:		cxdx	- packet
RETURN:		dxax	- space remaining in queue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketLinkPacket	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; get read access to controls segment
	;
		call	SocketControlStartRead
EC <		call	ECCheckIncomingPacketLow			>
	;
	; lock and dereference the packet
	;
		mov	bx,cx
		call	HugeLMemLock
		mov	es,ax
		mov	di,dx
		mov	di, es:[di]		; es:di = PacketHeader
	;
	; set the link flag
	;
		or	es:[di].PH_flags, mask PF_LINK
	;
	; dispatch on the packet type
	;
		mov	bx, es:[di].PH_dataOffset
		clr	ah
		mov	al, es:[di][bx]		; ax = LinkPacketType
		Assert etype, al, LinkPacketType
		mov	bp, ax
		call	cs:[linkPacketTable][bp]
		jnc	done
	;
	; if not queued, unlock and free the packet
	;
cleanup::
		mov	bx,cx
		call	HugeLMemUnlock
		movdw	axcx, cxdx
		call	HugeLMemFree
done:
		call	SocketControlEndRead
		.leave
		ret

linkPacketTable	nptr.near \
	ReceiveLinkDataPacket,
	ReceiveConnectionControlPacket

SocketLinkPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketDataPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A data packet has arrived from a data driver

CALLED BY:	SocketDataStrategy
PASS:		cxdx	- packet
RETURN:		dxax	- space remaining in queue
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketDataPacket	proc	near
		uses	bx,cx,si,di,bp,ds
		.enter
	;
	; get read access to controls segment
	;
		call	SocketControlStartRead
EC <		call	ECCheckIncomingPacketLow			>
	;
	; lock and dereference the packet
	;
		mov	bx,cx
		call	HugeLMemLock
		mov	es,ax
		mov	di,dx
		mov	di, es:[di]		; es:di = PacketHeader
	;
	; check packet type and dispatch accordingly
	;
		mov	al, es:[di].PH_flags
		and	al, mask PF_TYPE	; ax = PacketType
		cmp	al, PT_SEQUENCED
		jne	notSeq
		call	ReceiveSequencedDataPacket	; bxax = queue space
		jc	unlockBlock
		jmp	done
notSeq:
		call	ReceiveDatagramDataPacket	; bxax = queue space
		jnc	done
	;
	; if the packet was not queued, unlock and free it now
	;
unlockBlock:
		push	bx
		mov	bx, cx
		call	HugeLMemUnlock
		pop	bx
freeBlock::
		push	ax
		movdw	axcx, cxdx
		call	HugeLMemFree
		pop	ax
done:
		call	SocketControlEndRead
		mov	dx,bx			; dxax = queue space
		.leave
		ret
		
SocketDataPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data driver wants to open a connection

CALLED BY:	SocketDataStrategy
PASS:		ax	- connection handle
		bx	- domain handle
		cx	- local port
		dx	- remote port
RETURN:		carry set if no listener or listen queue is full
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketConnectRequest	proc	near
		uses	ax,bx,cx,dx,si,di,ds,es
		domain		local	nptr.DomainInfo		push bx
		portnum		local	word			push dx
		port		local	nptr.PortInfo
		listener	local	nptr.SocketInfo
		.enter
		call	SocketControlStartWrite
	;
	; stop the shutdown timer, if it exists
	;
		mov	si, bx
		call	SocketStopDomainTimer
	;
	; find the port
	;
		mov	dx, bx				; dx=domain
		mov	bx,cx				; bx=port
		mov	cx,ax				; cx=connection
		mov	ax, MANUFACTURER_ID_SOCKET_16BIT_PORT
		call	SocketFindPort			; ds:di=PortArrayEntry
		jc	error
	;
	; is it listening?
	;
		mov	si, ds:[di].PAE_info		; *ds:si = PortInfo
		mov	ss:[port], si
		mov	si, ds:[si]
		mov	bx, ds:[si].PI_listener
		mov	ss:[listener], bx
		tst	ds:[si].PI_listenQueue
		jz	error
	;
	; create a ConnectionInfo entry
	;
		mov	bx, ds:[si].PI_listenQueue	; *ds:bx = ListenQueue
		mov	si, dx				; *ds:si = DomainInfo
		mov	ax, size ConnectionInfo
		call	ChunkArrayAppend		; ds:di=ConnectionInfo
		jc	error
		clr	ds:[di].CI_socket
		mov	ds:[di].CI_handle, cx
	;
	; add to listen queue
	;
		mov	si,bx				; *ds:si = ListenQueue
		mov	bx, ss:[portnum]
		mov	ax, MANUFACTURER_ID_SOCKET_16BIT_PORT
		xchg	cx,dx				; cx=dom, dx=connection
		call	ListenQueueAppend
		jnc	notify
	;
	; if we can't add a listen queue entry, remove the ConnectionInfo
	; and abort
	;
	; since we appended our entry and have exclusive access, the 
	; last entry is always the one we want
	;
lqaFailed::
		mov	si, ss:[domain]
		mov	ax, CA_LAST_ELEMENT
		call	ChunkArrayElementToPtr
		call	ChunkArrayDelete
		jmp	error
	;
	; notify acceptor
	;
notify:
		mov	bx, ss:[listener]
		tst	bx
		jnz	wakeup
	;
	; there's a listen queue, but nobody is listening
	; must be a LoadOnMsg
	;
noListener::
		mov	si, ss:[port]
		call	SocketActivateLoadOnMsg
		clc
		jmp	done
	;
	; wake up the listener
	;
wakeup:
		call	WakeUpSocket
		clc
		jmp	done
	;
	; if the connection failed, consider removing the domain
	;
error:
		mov	si, ss:[domain]
		call	SocketRemoveDomain
		stc
done:
		call	SocketControlEndWrite
		.leave
		ret
		
SocketConnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketConnectConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A connection attempt succeeded

CALLED BY:	SocketDataStrategy
PASS:		ax	- connection handle
		bx	- domain handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketConnectConfirm	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter
	;
	; find the connection
	;
		call	SocketControlStartWrite
		mov	cx, bx
		mov	dx, ax
		call	SocketFindLinkByHandle		; dx = link offset
	;
	; find the socket
	;
		mov	di, ds:[bx]			; ds:di=DomainInfo
		add	di, dx				; ds:di=ConnectionInfo
		mov	si, ds:[di].CI_socket
EC <		tst	si						>
EC <		ERROR_Z CORRUPT_DOMAIN					>
EC <		call	ECCheckSocketLow				>
	;
	; update the state
	;
		mov	di, ds:[si]			; ds:di=SocketInfo
		mov	ds:[di].SI_state, ISS_CONNECTED
		ornf    ds:[di].SI_flags, mask SF_SEND_ENABLE or mask SF_RECV_ENABLE
	;
	; wake up the waiting thread
	;
		mov	bx, ds:[di].SI_waitSem
		call	ThreadVSem
	;
	; clean up
	;
		call	SocketControlEndWrite
		
		.leave
		ret
SocketConnectConfirm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketConnectFailed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A connection attempt failed

CALLED BY:	SocketDataStrategy
PASS:		ax	- connection handle
		bx	- domain handle
		dx	- SocketDrError
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketConnectFailed	proc	near
		uses	ds
		.enter
		call	SocketControlStartWrite
		call	SocketRemoveConnection
		call	SocketControlEndWrite
		.leave
		ret
SocketConnectFailed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketConnectionClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A data driver connection has closed

CALLED BY:	SocketDataStrategy
PASS:		ax	- connection handle
		bx	- domain handle
		cx	- SocketCloseType
		dx	- SocketDrError
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if dx != SDE_NO_ERROR, this is an abnormal close.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketConnectionClosed	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
		call	SocketControlStartWrite
	;
	; check close type
	;
		cmp	cx, SCT_FULL
		jne	half
	;
	; full close - dump the connection
	;
full::
		call	SocketRemoveConnection
		jmp	done
half:
	;
	; locate the socket
	;
		mov	cx, bx				; cx = domain
		mov	dx, ax				; dx = conn handle
							; ax = SocketDrError
		call	SocketFindLinkByHandle		; (*ds:cx)+dx = CI
		mov	si, ds:[bx]
		add	si, dx
		mov	si, ds:[si].CI_socket
	;
	; make sure the socket is real
	;
		tst	si
		jnz	socketOK
		WARNING CLOSING_UNUSED_CONNECTION
		jmp	done
socketOK:
EC <		call	ECCheckSocketLow				>
	;
	; update the socket's state
	;
		mov	di, ds:[si]			; ds:di = SocketInfo
EC <		cmp	ds:[di].SI_state, ISS_CONNECTED			>
EC <		ERROR_NE UNEXPECTED_SOCKET_STATE			>
EC <		test	ds:[di].SI_flags, mask SF_RECV_ENABLE		>
EC <		WARNING_Z REDUNDANT_CLOSE				>
		and	ds:[di].SI_flags, not mask SF_RECV_ENABLE
	;
	; wake up anyone waiting for data or closure
	;
wakeup::
		xchg	bx,si				; bx=socket, si=domain
		call	WakeUpForClose
	;
	; clean up the ConnectionInfo if necessary
	;
		test	ds:[di].SI_flags, mask SF_SEND_ENABLE
		jnz	done
		clr	ds:[di].SSI_connection.CE_domain
		clr	ds:[di].SSI_connection.CE_link
		mov	di, ds:[si]			; ds:di=DomainInfo
		add	di, dx				; ds:di=ConnectionInfo
		call	ChunkArrayDelete
	;
	; remove the domain if needed
	;
		call	SocketRemoveDomain
done:
		call	SocketControlEndWrite
		.leave
		ret
SocketConnectionClosed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketDatagramException
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an exception for a datagram socket

CALLED BY:	SocketDataStrategy
PASS:		al	= SocketDrException
		bx	= local port number
		dx	= domain handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This can't be implemented until the domain handle is added
	as a parameter.  Once that happens, we can locate the PortInfo,
	find the datagram receiver, and fill in DSI_exception.

	At this time, there is no way for the user to read DSI_exception.
	Whomever implements this can worry about that as well.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketDatagramException	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		call	SocketControlStartWrite
	;
	; look up the port
	;
		push	ax
		mov	ax, MANUFACTURER_ID_SOCKET_16BIT_PORT
		call	SocketFindPort		; ds:di = PortArrayEntry
		pop	ax
		jc	done
	;
	; anyone listening?
	;
		mov	si, ds:[di].PAE_info	; *ds:si = PortInfo
		mov	di, ds:[si]
		mov	si, ds:[di].PI_dgram	; *ds:si = SocketInfo or null
		tst	si			; does socket exist?
		stc
		jz	done
	;
	; store exception in socket
	;
		mov	di, ds:[si]		; ds:di = DatagramSocketInfo
EC <		tst	ds:[di].DSI_exception				>
EC <		WARNING_Z OVERWRITING_EXCEPTION				>
		mov	ds:[di].DSI_exception, al
	;
	; wake up anyone who is waiting
	;
		mov	bx, si			; *ds:bx = SocketInfo
		call	WakeUpExcept
		clc
done:
EC <		WARNING_C IGNORING_EXCEPTION				>
		call	SocketControlEndWrite
		.leave
		ret
SocketDatagramException	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketUrgentData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive an urgent data packet from a data driver

CALLED BY:	SocketDataStrategy
PASS:		ax	= connection handle
		bx	= domain handle
		cx	= size of data
		ds:si	= data (not null-terminated)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketUrgentData	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; handle different sizes of data differently
	;
		jcxz	done			; 0 bytes - disregard
		push	ax,bx
		cmp	cx, size dword
		ja	doChunk			; 5+ bytes - make a chunk
	;
	; load data into low bits of bxax
	;
		mov	bp,cx			; bp = size
EC <		clrdw	bxax			; clear unused bytes	>
		lodsb
		mov	dh,al			; dh = byte 0
		dec	cl
		jz	gotData
		lodsb
		mov	ah,al			; ah = byte 1
		dec	cl
		jz	gotData
		lodsb
		mov	bl,al			; bl = byte 2
		dec	cl
		jz	gotData
		lodsb
		mov	bh,al			; bh = byte 3
gotData:
		mov	al,dh			; al = byte 0
		jmp	store
		
	;
	; allocate a buffer for the data
	;
doChunk:
		push	ds,cx
		mov	ax, cx
		mov	cx, FOREVER_WAIT
		GetPacketHeap			; bx = heap
		call	HugeLMemAllocLock	;^lax:cx = new buffer,
						; ds:di = new buffer
		jc	allocError
		mov_tr	bx,ax
		mov	ax,cx			; ^lbx:ax = buffer

		segmov	es,ds
		pop	ds,cx
	;
	; copy data into buffer
	;
copy::
		push	cx
EC <		call	ECCheckMovsb					>
		rep	movsb
		call	HugeLMemUnlock
		pop	bp			; bp=size
	;
	; store buffer in socket
	;
store:
		pop	dx,cx			; dx=connection, cx=domain
		call	ReceiveUrgentDataPacket
done:
		.leave
		ret
	;
	; clean up the stack and bail
	;
	; this means we are losing data, but only if we waited for almost two
	; hours for memory to be available (65535 ticks)
	;
allocError:
		pop	ax, ax, ax, ax
		jmp	done
SocketUrgentData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketLinkGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about a link connection

CALLED BY:	SocketLinkStrategy
PASS:		ax	= SocketClientInfoType
RETURN:		carry set if info not available
DESTROYS:	nothing

Other parameters for each SocketClientInfoType
 SCIT_RECV_BUF
 	Pass:	bx	= connection
	Return:	dxax	= space available in recv buffer

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketLinkGetInfo	proc	near
		uses	bx,cx,si,di,bp
		.enter
EC <		cmp	ax, SCIT_RECV_BUF				>
EC <		ERROR_NE NOT_VALID_MEMBER_OF_ENUMERATED_TYPE		>
	;
	; link connections do not use the driver for flow control
	;
		movdw	dxax, -1		
		.leave
		ret
SocketLinkGetInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketDataGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about a data connection

CALLED BY:	SocketDataStrategy
PASS:		ax	= SocketClientInfoType
RETURN:		carry set if info not available
DESTROYS:	nothing

Other parameters for each SocketClientInfoType
 SCIT_RECV_BUF
 	Pass:	bx	= connection
		dx	= domain
	Return:	dxax	= space available in recv buffer

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketDataGetInfo	proc	near
		uses	cx,si,di,ds
		.enter
EC <		cmp	ax, SCIT_RECV_BUF				>
EC <		ERROR_NE NOT_VALID_MEMBER_OF_ENUMERATED_TYPE		>
	;
	; lock the control block
	;
	; lock exclusive to prevent avoid reading inconsistent data
	; from the dwords in SocketInfo below
	;
		call	SocketControlStartWrite
	;
	; find the link
	;
		mov	cx, dx
		mov	dx, bx
		call	SocketFindLinkByHandle
EC <		ERROR_C ILLEGAL_CONNECTION				>
	;
	; find the socket
	;
		mov	si, cx
		mov	di, ds:[si]
		add	di, dx
		mov	si, ds:[di].CI_socket
		tst	si
		jz	noConnection
EC <		call	ECCheckSocketLow				>
	;
	; if the socket is closing, lie about the buffer size
	;
		mov	si, ds:[si]
		movdw	dxax, ds:[si].SI_maxQueueSize
		test	ds:[si].SI_flags, mask SF_DISCARD
		jnz	done
	;
	; otherwise get the current buffer size
	;
		subdw	dxax, ds:[si].SI_curQueueSize
		jns	done
noConnection:
		clrdw	dxax
	;
	; cleanup and exit
	;
done:
		call	SocketControlEndWrite
		clc
		.leave
		ret
SocketDataGetInfo	endp


StrategyCode	ends



