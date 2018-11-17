COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		Socket library
FILE:		socketConnection.asm

AUTHOR:		Eric Weber, Jun  5, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT ListenQueueAppend       Add a new connection request to a listen
				queue

    INT ListenQueueDelete       Delete an entry from a listen queue

    INT ListenQueueFind         Search for a connection in a listen queue

    EXT ListenQueueFindCallback callback for ListenQueueFind

    INT ConnectionOpen          Receive an open request

    INT ConnectionAccept        A connection has been accepted

    INT ConnectionBegin         Our accept has been acknowledged

    INT ConnectionRefuse        A connection has been refused

    INT ConnectionClose         Close a connection

    INT ConnectionCancel        Unilaterally terminate a connection

    INT FindSocketByConnection  Locate the socket handling a connection

    INT SocketSendClose         Setup to close a socket

    INT SocketFullClose         Completely close a data driver connection

    INT SocketDataConnect       Create a data connection

    INT SocketMapConnectError   Translate a driver error to a socket error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94   	Initial revision


DESCRIPTION:
	Code for managing connections
		

	$Id: socketConnection.asm,v 1.28 97/04/21 20:49:36 simon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StrategyCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ListenQueueAppend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new connection request to a listen queue

CALLED BY:	(INTERNAL) ConnectionOpen, SocketConnectRequest
PASS:		*ds:si	- ListenQueue
		cx	- domain handle
		dx	- link handle
		axbx	- source port 

RETURN:		carry	- set if entry could not be added
			(out of space or identical entry already in queue)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ListenQueueAppend	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; make sure it isn't already there
	;
		call	ListenQueueFind
		cmc
		jc	done
	;
	; check for room in listen queue
	;
		mov	di, ds:[si]
		mov	bp, ds:[di].LQ_maxEntries
		cmp	bp, ds:[di].CAH_count
		stc
		jle	done
	;
	; put source information in listen queue
	;
		call	ChunkArrayAppend		; ds:di = new element
		jc	done
		mov	ds:[di].CE_domain, cx
		mov	ds:[di].CE_link, dx
		movdw	ds:[di].CE_port, axbx
EC <		call	ECCheckConnectionEndpoint			>
	;
	; update link ref count
	;
		mov	si, cx
		mov	si, ds:[si]
		cmp	ds:[si].DI_driverType, SDT_DATA
		je	done
		call	SocketFindLinkByHandle
		call	LinkIncRefCount
done:
		.leave
		ret
ListenQueueAppend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ListenQueueDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an entry from a listen queue

CALLED BY:	(INTERNAL) ConnectionCancel
PASS:		*ds:si 	- ListenQueue
		cx	- domain
		dx	- link handle
		axbx	- source port
RETURN:		carry	- set if not found
		ds	- control segment (possibly moved)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ListenQueueDelete	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; find the entry
	;
		call	ListenQueueFind		; ds:di = entry
		jc	done
	;
	; delete it
	;
		call	ChunkArrayDelete
	;
	; update the link
	;
		call	SocketFindLinkByHandle
		call	LinkDecRefCount
done:
		.leave
		ret
ListenQueueDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ListenQueueFind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a connection in a listen queue

CALLED BY:	(INTERNAL) ListenQueueAppend, ListenQueueDelete
PASS:		*ds:si 	- ListenQueue
		cx	- domain
		dx	- link handle
		axbx	- source port
RETURN:		carry	- set if not found
		ds:di	- matching entry (ConnectionEndpoint)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ListenQueueFind		proc	near
		uses	ax,bx,bp,si
		.enter
		mov	bp,bx			; axbp = port
		mov	di,offset ListenQueueFindCallback
		mov	bx,cs			; bx:di = callback routine
		call	ChunkArrayEnum		; carry set if found
		cmc				; invert carry
		jc	done
		mov	di,ax			; ds:di = matching entry
done:
		.leave
		ret
ListenQueueFind	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ListenQueueFindCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback for ListenQueueFind

CALLED BY:	(EXTERNAL) ListenQueueFind via ChunkArrayEnum
PASS:		ds:di	- ConnectionEndpoint
		cx	- domain
		dx	- link
		axbp	- port
RETURN:		carry	- set if match
		ax	- offset of queue element if match
			  otherwise preserved
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ListenQueueFindCallback	proc	far
		cmp	cx, ds:[di].CE_domain
		jne	continue
		cmp	dx, ds:[di].CE_link
		jne	continue
		cmpdw	axbp, ds:[di].CE_port
		jne	continue
		mov	ax,di
		stc
		jmp	done
continue:
		clc
done:
		ret
ListenQueueFindCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectionOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive an open request

CALLED BY:	(INTERNAL) ReceiveConnectionControlPacket
PASS:		ds	- control segment
		es:di	- SequencedPacketHeader
		bx	- offset of ConnectionControlPacket
		cxdx	- optr to packet
RETURN:		ds	- possibly moved
DESTROYED:	es
SIDE EFFECTS:	may block

PSEUDO CODE/STRATEGY:
	either the request goes in the listen queue, or it is refused

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

	EW	6/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectionOpen	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		linkHeader	local	word	push di
		controlHeader	local	word	push bx
		.enter
	;
	; find the port -- if not found, refuse connection
	;
		movdw	axbx, es:[di][bx].CCP_dest	; destination port
		mov	dx, es:[di].PH_domain		; domain handle
EC <		Assert	chunk, dx, ds					>
		call	SocketFindPort			; ds:di=PortArrayEntry
		jc	refuse
	;
	; check for existing connection
	;
		mov	si,ds:[di].PAE_info		; *ds:si = PortInfo
		mov	di, ss:[linkHeader]		; es:di = PacketHeader
		mov	bx, ss:[controlHeader]
		mov	cx, es:[di].PH_domain
		mov	dx, es:[di].SPH_link
		movdw	axbx, es:[di][bx].CCP_source	; source port
		
		push	di
		call	FindSocketByConnection		; *ds:di=SocketInfo
		pop	di
		jnc	refuse
	;
	; anybody listening?
	;
		mov	di,si				; *ds:di = PortInfo
		mov	si, ds:[si]			; ds:si = PortInfo
		tst	ds:[si].PI_listenQueue
		jz	refuse
	;
	; add new entry to listen queue
	;
		mov	si, ds:[si].PI_listenQueue
		call	ListenQueueAppend
		jc	refuse
	;
	; notify acceptor
	;
		mov	bx, ds:[di]
		mov	bx, ds:[bx].PI_listener
		tst	bx
		jnz	wakeup
	;
	; there's a listen queue, but nobody is listening
	; must be a LoadOnMsg
	;
noListener::
		mov	si, ds:[si]		; ds:si <- listen queue CAH
		cmp	ds:[si].CAH_count, 1
		clc
		jne	done			; => not the first one, so
						;  assume someone else is
						;  loading and will handle
						;  canceling the thing if
						;  it can't load.
		mov	si, di
		call	SocketActivateLoadOnMsg
		jnc	done
	;
	; Couldn't load, so refuse all pending connections.
	;
		call	FreePortListenQueue
		jmp	done
	;
	; wake up whomever is blocked
	; *ds:bx = listener
	;
wakeup:
		call	WakeUpSocket
done:		
		.leave
		ret
	;
	; send a refuse packet
	;
refuse:
		mov	di, ss:[linkHeader]
		mov	cx, ss:[controlHeader]
		mov	ax, CCO_REFUSE
		call	ConnectionControlReply
		jmp	done
ConnectionOpen	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectionAccept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A connection has been accepted

CALLED BY:	ReceiveConnectionControlPacket
PASS:		ds	- control segment
		es:di	- SequencedPacketHeader
		bx	- offset of ConnectionControlPacket
		cxdx	- optr to packet
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectionAccept	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		linkHeader	local	word	push di
		controlHeader	local	word	push bx
		.enter
	;
	; find the port
	;
		movdw	axbx, es:[di][bx].CCP_dest	; destination port
		mov	dx, es:[di].PH_domain		; domain handle
		call	SocketFindPort			; ds:di=PortArrayEntry
		jc	done
	;
	; find the socket
	;
		mov	si,ds:[di].PAE_info		; *ds:si = PortInfo
		mov	di, ss:[linkHeader]		; es:di = PacketHeader
		mov	bx, ss:[controlHeader]
		movdw	axbx, es:[di][bx].CCP_source	; source port
		mov	cx, es:[di].PH_domain
		mov	dx, es:[di].SPH_link
		call	FindSocketByConnection		; *ds:di=SocketInfo
		jc	noSocket
	;
	; mark the socket as CONNECTED
	;
		mov	bx,di
		mov	di, ds:[di]			; ds:di = SocketInfo
EC <		cmp	ds:[di].SI_state, ISS_CONNECTING		>
EC <		ERROR_NE UNEXPECTED_SOCKET_STATE 			>
		mov	ds:[di].SI_state, ISS_CONNECTED
		ornf	ds:[di].SI_flags, mask SF_SEND_ENABLE or mask SF_RECV_ENABLE or mask SF_INTERRUPTIBLE
	;
	; notify the remote side to proceed
	;
		mov	ax, CCO_BEGIN
reply:
		mov	di, ss:[linkHeader]
		mov	cx, ss:[controlHeader]
		call	ConnectionControlReply
	;
	; wake up anyone who is waiting
	;
		call	WakeUpSocket
done:
		.leave
		ret
	;
	; nobody is trying to connect - they must have timed out
	;
noSocket:
		mov	ax, CCO_CANCEL
		jmp	reply
ConnectionAccept	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectionBegin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Our accept has been acknowledged

CALLED BY:	ReceiveConnectionControlPacket
PASS:		ds	- control segment
		es:di	- SequencedPacketHeader
		bx	- offset of ConnectionControlPacket
		cxdx	- optr to packet
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectionBegin	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		linkHeader	local	word	push di
		controlHeader	local	word	push bx
		.enter
	;
	; find the port
	;
		movdw	axbx, es:[di][bx].CCP_dest	; destination port
		mov	dx, es:[di].PH_domain		; domain handle
		call	SocketFindPort			; ds:di=PortArrayEntry
		jc	done
	;
	; find the socket
	;
		mov	si,ds:[di].PAE_info		; *ds:si = PortInfo
		mov	di, ss:[linkHeader]		; es:di = PacketHeader
		mov	bx, ss:[controlHeader]
		movdw	axbx, es:[di][bx].CCP_source	; source port
		mov	cx, es:[di].PH_domain
		mov	dx, es:[di].SPH_link
		call	FindSocketByConnection		; *ds:di=SocketInfo
		jc	done
	;
	; mark the socket as CONNECTED
	;
		mov	bx, di
		mov	di, ds:[di]
EC <		cmp	ds:[di].SI_state, ISS_ACCEPTING			>
EC <		ERROR_NE UNEXPECTED_SOCKET_STATE 			>
		mov	ds:[di].SI_state, ISS_CONNECTED
		ornf	ds:[di].SI_flags, mask SF_SEND_ENABLE or mask SF_RECV_ENABLE or mask SF_INTERRUPTIBLE
	;
	; wake up anyone who is waiting
	;
		call	WakeUpSocket
done:
		.leave
		ret
ConnectionBegin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectionRefuse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A connection has been refused

CALLED BY:	ReceiveConnectionControlPacket
PASS:		ds	- control segment
		es:di	- SequencedPacketHeader
		bx	- offset of ConnectionControlPacket
		cxdx	- optr to packet
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectionRefuse	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		linkHeader	local	word	push di
		controlHeader	local	word	push bx
		.enter
	;
	; find the port
	;
		movdw	axbx, es:[di][bx].CCP_dest	; destination port
		mov	dx, es:[di].PH_domain		; domain handle
		call	SocketFindPort			; ds:di=PortArrayEntry
		jc	done
	;
	; find the socket
	;
		mov	si,ds:[di].PAE_info		; *ds:si = PortInfo
		mov	di, ss:[linkHeader]		; es:di = PacketHeader
		mov	bx, ss:[controlHeader]
		movdw	axbx, es:[di][bx].CCP_source	; source port
		mov	cx, dx				; cx = domain
		mov	dx, es:[di].SPH_link		; dx = link
		call	FindSocketByConnection		; *ds:di=SocketInfo
		jc	done
	;
	; mark the socket as REFUSED
	;
		mov	bx, di
		mov	di, ds:[di]
EC <		cmp	ds:[di].SI_state, ISS_CONNECTING		>
EC <		ERROR_NE UNEXPECTED_SOCKET_STATE 			>
		mov	ds:[di].SI_state, ISS_ERROR
		mov	ds:[di].SSI_error, SE_CONNECTION_REFUSED
	;
	; decrement the link ref count
	;
updateLink::
		call	SocketFindLinkByHandle
EC <		ERROR_C CORRUPT_SOCKET					>
		call	LinkDecRefCount
	;
	; wake up anyone who is waiting
	;
		call	WakeUpSocket
done:
		.leave
		ret
ConnectionRefuse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectionClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a connection

CALLED BY:	ReceiveConnectionControlPacket
PASS:		ds	- control segment
		es:di	- SequencedPacketHeader
		bx	- offset of ConnectionControlPacket
		cxdx	- optr to packet
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectionClose	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		linkHeader	local	word	push di
		controlHeader	local	word	push bx
		.enter
	;
	; find the port
	;
		movdw	axbx, es:[di][bx].CCP_dest	; destination port
		mov	dx, es:[di].PH_domain		; domain handle
		call	SocketFindPort			; ds:di=PortArrayEntry
		jc	done
	;
	; find the socket
	;
		mov	si,ds:[di].PAE_info		; *ds:si = PortInfo
		mov	di, ss:[linkHeader]		; es:di = PacketHeader
		mov	bx, ss:[controlHeader]
		movdw	axbx, es:[di][bx].CCP_source	; source port
		mov	cx, es:[di].PH_domain
		mov	dx, es:[di].SPH_link
		call	FindSocketByConnection		; *ds:di=SocketInfo
		jc	done
	;
	; verify state
	;
		mov	bx, di
		mov	di, ds:[di]
EC <		cmp	ds:[di].SI_state, ISS_CONNECTED			>
EC <		ERROR_NE UNEXPECTED_SOCKET_STATE			>
	;
	; close socket for receiving
	; see if it's still open for sending
	;
		and	ds:[di].SI_flags, not mask SF_RECV_ENABLE
		test	ds:[di].SI_flags, mask SF_SEND_ENABLE
		jnz	wakeUp
	;
	; both sides have closed - update (and possibly close) the link
	;
		mov	cx, ds:[di].SSI_connection.CE_domain
		mov	dx, ds:[di].SSI_connection.CE_link
		clr	ds:[di].SSI_connection.CE_domain
		clr	ds:[di].SSI_connection.CE_link
		call	SocketFindLinkByHandle
EC <		WARNING_C WARNING_CONNECTION_HAS_NO_LINK		>
		jc	wakeUp
		call	LinkDecRefCount
	;
	; wake up anybody on the socket (either a recv or a close)
	;
wakeUp:
		call	WakeUpForClose
done:
		.leave
		ret
ConnectionClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectionCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unilaterally terminate a connection

CALLED BY:	ReceiveConnectionControlPacket
PASS:		ds	- control segment
		es:di	- SequencedPacketHeader
		bx	- offset of ConnectionControlPacket
		cxdx	- optr to packet
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectionCancel	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		linkHeader	local	word	push di
		controlHeader	local	word	push bx
		.enter
	;
	; find the port
	;
		movdw	axbx, es:[di][bx].CCP_dest	; destination port
		mov	dx, es:[di].PH_domain		; domain handle
		call	SocketFindPort			; ds:di=PortArrayEntry
		jc	done
	;
	; find the socket
	;
		mov	si,ds:[di].PAE_info		; *ds:si = PortInfo
		mov	di, ss:[linkHeader]		; es:di = PacketHeader
		mov	bx, ss:[controlHeader]
		movdw	axbx, es:[di][bx].CCP_source	; source port
		mov	cx, es:[di].PH_domain
		mov	dx, es:[di].SPH_link
		call	FindSocketByConnection		; *ds:di=SocketInfo
		jc	noSocket
	;
	; change the socket state
	;
		mov	bx, di
		mov	di, ds:[di]
		cmp	ds:[di].SI_state, ISS_CONNECTED
		je	connected
		mov	ds:[di].SI_state, ISS_ERROR
		mov	ds:[di].SSI_error, SE_CONNECTION_CANCELED
		jmp	updateLink
connected:
		or	ds:[di].SI_flags, mask SF_FAILED
		and	ds:[di].SI_flags, not (mask SF_RECV_ENABLE or mask SF_SEND_ENABLE)
	;
	; decrement the link ref count
	;
updateLink:
		call	SocketFindLinkByHandle
EC <		ERROR_C CORRUPT_SOCKET					>
		call	LinkDecRefCount
	;
	; wake up anyone who is waiting
	;
		call	WakeUpForClose
done:
		.leave
		ret
	;
	; no socket exists for this connection
	; possibly it is in the listen queue
	;
noSocket:
		mov	si, ds:[si]			; ds:si = PortInfo
		mov	si, ds:[si].PI_listenQueue	; *ds:si = ListenQueue
		call	ListenQueueDelete		; ds:di = element
		jmp	done
		
ConnectionCancel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindSocketByConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the socket handling a connection

CALLED BY:	(INTERNAL) ConnectionAccept, ConnectionBegin,
		ConnectionCancel, ConnectionClose, ConnectionOpen,
		ConnectionRefuse, ReceiveLinkDataPacket
PASS:		axbx	- source SocketPort
		cx	- domain
		dx	- link
		*ds:si	- destination PortInfo
RETURN:		*ds:di	- destination SocketInfo
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindSocketByConnection	proc	near
		uses	si,bp
		.enter
EC <		call	ECCheckPortLow					>
	;
	; find the first socket
	;
		mov	si, ds:[si]		; ds:si = PortInfo
		mov	bp, ds:[si].CAH_count
		add	si, ds:[si].CAH_offset	; ds:si = first CA entry
	;
	; enumerate sockets until we either run out, or find our target
	;
		inc	bp
		sub	si,2
top:
		dec	bp
		stc
		jz	done			; not in the array
		add	si,2
		mov	di, ds:[si]		; *ds:si = SocketInfo
		mov	di, ds:[di]		; ds:si = SocketInfo
EC <		cmp	ds:[di].SI_type, CCT_SOCKET_INFO		>
EC <		ERROR_NE CORRUPT_PORT					>
		cmp	cx, ds:[di].SSI_connection.CE_domain
		jne	top
		cmp	dx, ds:[di].SSI_connection.CE_link
		jne	top
		cmpdw	axbx, ds:[di].SSI_connection.CE_port
		jne	top
	;
	; we have a match
	;
		mov	di, ds:[si]		; *ds:di = SocketInfo
EC <		xchg	si,di						>
EC <		call	ECCheckSocketLow				>
EC <		xchg	si,di						>
done:
		.leave
		ret
FindSocketByConnection	endp

StrategyCode	ends

ApiCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSendClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup to close a socket

CALLED BY:	(INTERNAL) SocketClose, SocketCloseSend
PASS:		*ds:bx		- SocketInfo
RETURN:		carry		- set on error
		ax		- SocketError (if carry set)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Grab a misc lock to prevent domain from being removed while
	our thread is in driver.  This could happen if we receive a close
	after sending our close but before control returns to the socket
	library.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketSendClose	proc	near
		uses	bx,cx,dx,si,di,bp
		domain	local	word
		.enter
	;
	; find the domain
	;
		mov	si, ds:[bx]
		mov	cx, ds:[si].SSI_connection.CE_domain
	;
	; get a misc lock
	;
		mov	ss:[domain], cx
		xchg	cx,si
		call	SocketGrabMiscLock
		xchg	cx,si
	;
	; find the link
	;
		mov	dx, ds:[si].SSI_connection.CE_link
		call	SocketFindLinkByHandle
	;
	; update the state
	;
		and	ds:[si].SI_flags, not mask SF_SEND_ENABLE
	;
	; check driver type
	;
checkType::
		mov	di, cx
		mov	di, ds:[di]
		cmp	ds:[di].DI_driverType, SDT_DATA
		je	data
	;
	; is socket now fully closed?
	;
link::
		mov	si, ds:[bx]
		test	ds:[si].SI_flags, mask SF_RECV_ENABLE
		jnz	sendit
	;
	; dec the link count
	;
		mov	cx, ds:[si].SSI_connection.CE_domain
		mov	dx, ds:[si].SSI_connection.CE_link
		call	SocketFindLinkByHandle
EC <		ERROR_C CORRUPT_SOCKET					>
		call	LinkDecRefCountNoClose
	;
	; send the close packet
	;
sendit:
		push	bx
		sub	sp, size PacketInfo
		call	SetupPacketInfo		; copy info to stack
		call	SocketControlEndWrite
		mov	ax, CCO_CLOSE
		call	SendConnectionControl	; send the packet
		call	SocketControlStartWrite
		pop	bx
		clr	ax
		jmp	done
	;
	; if socket is already half-closed and linger flag is set, do
	; full close instead
	;
data:
		test	ds:[si].SI_flags, mask SF_RECV_ENABLE
		jnz	sendDisconnect
		test	ds:[si].SI_flags, mask SF_LINGER
		jnz	full		; branch if linger set
	;
	; call DR_SOCKET_DISCONNECT_REQUEST
	;
sendDisconnect:
		push	bx
		pushdw	ds:[di].DI_entry
		mov	bx, ds:[si].SSI_connection.CE_link
		call	SocketControlEndWrite
		mov	ax, SCT_HALF
		mov	di, DR_SOCKET_DISCONNECT_REQUEST
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		call	SocketControlStartWrite
		pop	bx
		mov	ax, SE_NORMAL
		jnc	done
	;
	; we got an error - restore old socket state
	;
restore::
		mov	si, ds:[bx]
		or	ds:[si].SI_flags, mask SF_SEND_ENABLE
	;
	; see what the error was
	;
		cmp	al, SDE_UNSUPPORTED_FUNCTION
		jne	notUnsupported
	;
	; do a full close instead of a half close
	;
full:
		call	SocketFullClose
		jmp	done
notUnsupported:
		mov	ah,al
		mov	al, SE_INTERNAL_ERROR
		stc
done:
		mov	si, ss:[domain]
		call	SocketReleaseMiscLock
		.leave
		ret
SocketSendClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFullClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Completely close a data driver connection

CALLED BY:	(INTERNAL) SocketSendClose
PASS:		*ds:bx	- SocketInfo
RETURN:		carry	- set on error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFullClose	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; update the state
	; if called form SocketSendClose, the enable bit will alrady be clear
	;
		mov	si, ds:[bx]			; ds:si = socket
		and	ds:[si].SI_flags, not mask SF_SEND_ENABLE
	;
	; find the domain
	;
findDomain::
		mov	di, ds:[si].SSI_connection.CE_domain
		mov	di, ds:[di]			; ds:di = domain
EC <		cmp	ds:[di].DI_driverType, SDT_DATA			>
EC <		ERROR_NE UNEXPECTED_DOMAIN_TYPE				>
	;
	; call DR_SOCKET_DISCONNECT_REQUEST
	;
data::
		push	bx
		pushdw	ds:[di].DI_entry
		mov	bx, ds:[si].SSI_connection.CE_link
		mov	ax, SCT_FULL
		mov	di, DR_SOCKET_DISCONNECT_REQUEST
		call	SocketControlEndWrite
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		call	SocketControlStartWrite
		pop	bx
		jc	failed
	;
	; mark socket as fully closed
	;
mark::
		mov	si, ds:[bx]
		and	ds:[si].SI_flags, not mask SF_RECV_ENABLE
	;
	; clean up the domain
	;
		mov	bx, ds:[si].SSI_connection.CE_domain
		mov	ax, ds:[si].SSI_connection.CE_link
		clr	ds:[si].SSI_connection.CE_domain
		clr	dx
		call	SocketRemoveConnection
done:
		.leave
		ret
	;
	; it didn't work - restore socket state and bail
	;
failed:
		mov	si, ds:[bx]
		or	ds:[si].SI_flags, mask SF_SEND_ENABLE
		mov	ah,al
		mov	al, SE_INTERNAL_ERROR
		stc
		jmp	done
SocketFullClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAllocConnectionHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a connection handle from a driver

CALLED BY:	SocketDataConnect
PASS:		*ds:cx	- DomainInfo
		ON STACK - driver entry point
RETURN:		ARGS POPPED
		cary set if error
			ax = SocketDrError
		else
			ax = connection handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAllocConnectionHandle	proc	near
		uses	bx, si
		.enter
	;
	; get info from the domain
	;
		mov	si, cx
		mov	si, ds:[si]		; ds:si = DomainInfo
		pushdw	ds:[si].DI_entry
		mov	bx, ds:[si].DI_client
	;
	; call the driver
	;
		call	SocketControlEndWrite
		mov	di, DR_SOCKET_ALLOC_CONNECTION
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; ax = handle
		call	SocketControlStartWrite
		.leave
		ret
SocketAllocConnectionHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestorePointersForConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find ConnectionInfo for this connection

CALLED BY:	SocketDataConnect

PASS:		ss:bp	 - inherited stack frame
		ds	 - control block

RETURN:		*ds:bx	- SocketInfo
		*ds:si	- DomainInfo
		ds:di	- ConnectionInfo

DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestorePointersForConnect	proc	near
		.enter inherit SocketDataConnect
		pushf
		mov	bx, ss:[socketHan]
		mov	si, ss:[domain]
		call	SocketFindLinkBySocket
EC <		ERROR_C CORRUPT_DOMAIN					>
		popf
		.leave
		ret
RestorePointersForConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketDataConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a data connection

CALLED BY:	(INTERNAL) SocketConnect
PASS:		*ds:bx	- SocketInfo
		*ds:cx	- DomainInfo
		es:di	- SocketAddress
		ss:ax	- timeout

RETURN:		carry set on error
		ax	- SocketError

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketDataConnect	proc	near
		uses	bx,cx,dx,si,di,bp
		socketHan	local	word	push bx
		domain		local	word	push cx
		timeout		local	word	push ax
		localPort	local	word
		ForceRef	domain
		ForceRef	localPort
		.enter
	;
	; verify the socket
	;
		mov	si,bx			; si = Socket
EC <		call	ECCheckSocketLow				>
	;
	; get a connection handle
	;
getHandle::
		mov	dx, di
		call	SocketAllocConnectionHandle
		call	RestorePointersForConnect
		jc	failed1
		mov	ds:[di].CI_handle, ax		; remember conn handle
		mov	di, dx				; es:di = address
	;
	; update the socket
	;
		mov	bx, ds:[bx]		; ds:bx = SocketInfo
		mov	ds:[bx].SSI_connection.CE_link, ax	; store link
		push	ds:[bx].SI_waitSem	; save wait semaphore
		push	bp			; save frame pointer
	;
	; get local port
	;
		mov	bx, ds:[bx].SI_port
		mov	bx, ds:[bx]		; ds:bx = PortInfo
		mov	dx, ds:[bx].PI_number.SP_port	; dx = local port
	;
	; get driver entry point
	; NO PUSHES BEYOND THIS POINT
	;
		mov	si, ds:[si]			; ds:si = domain
		pushdw	ds:[si].DI_entry
	;
	; setup remaining parameters and call driver
	;
connect::
		call	SocketControlEndWrite
		mov	cx, ss:[timeout]		
		call	SocketGetTimeout		; cx = timeout
		mov	bx, ax				; bx = conn handle
		mov	bp, es:[di].SA_port.SP_port
		xchg	dx,bp				; dx=remote, bp=local
		mov	ax, es:[di].SA_addressSize	; ax = addr size
		segmov	ds,es
		lea	si, es:[di].SA_address		; ds:si = address
		mov	di, DR_SOCKET_DATA_CONNECT_REQUEST
		call	PROCCALLFIXEDORMOVABLE_PASCAL
afterDriver::
		pop	bp
		pop	bx
		jc	failed2
	;
	; wait for further feedback
	;
		call	ThreadPSem
		call	ThreadFreeSem
	;
	; see what happened
	;
	; In case of error, all the heavy cleanup work has been done
	; by SocketRemoveConnection; so all we have to do is check the
	; error status.
	;
		call	SocketControlStartWrite
		mov	bx, ss:[socketHan]
		mov	si, ds:[bx]
		clr	ax
		czr	ax, ds:[si].SI_waitSem
		cmp	ds:[si].SI_state, ISS_CONNECTED
		je	done
		mov	ds:[si].SI_state, ISS_UNCONNECTED
		mov	ax, ds:[si].SSI_error
		stc
done:
		.leave
		ret
	;
	; connection failed - clean up socket
	;
failed2:
		call	SocketControlStartWrite
		call	RestorePointersForConnect
	;
	; bx = socket
	; si = domain
	; ds:di=ConnectionInfo
	;
failed1:
	;
	; nuke the ConnectionInfo, and possibly the domain too
	;
		call	ChunkArrayDelete
		call	SocketRemoveDomain
	;
	; clean up the socket
	;
		call	SocketFreeQueue
		mov	si, ds:[bx]
		mov	ds:[si].SI_state, ISS_UNCONNECTED
		clr	ds:[si].SSI_connection.CE_domain
		clrdw	ds:[si].SSI_connection.CE_port
	;
	; clean up port
	;
		call	RemoveSocketFromPort
	;
	; translate error
	;
		call	SocketMapConnectError
		jmp	done

SocketDataConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketMapConnectError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a driver error to a socket error

CALLED BY:	SocketDataConnect, SocketOpenDomainMedium
PASS:		ax	- SocketDrError
RETURN:		ax	- SocketError
		carry set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Under normal circumstances, AH remains unchanged.	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketMapConnectError	proc	far
		uses	bx,cx
		.enter
	;
	; translate driver error (currently in ax)
	;
		cmp	al, size connectErrorMap
		jge	unknown
		mov	bx, offset cs:[connectErrorMap]
		mov	cl,al
		xlatb	cs:
		cmp	al, SE_INTERNAL_ERROR
		jne	done
		mov	ah,cl
		jmp	done
unknown:
		mov	ah,al
		mov	al, SE_CONNECTION_ERROR
done:
		stc
		.leave
		ret
		
connectErrorMap	SocketError \
	SE_INTERNAL_ERROR,		; SDE_NO_ERROR (but carry was set!)
	SE_CONNECTION_REFUSED,		; SDE_CONNECTION_REFUSED
	SE_TIMED_OUT,			; SDE_CONNECTION_TIMEOUT
	SE_MEDIUM_BUSY,			; SDE_MEDIUM_BUSY
	SE_OUT_OF_MEMORY,		; SDE_INSUFFICIENT_MEMORY
	SE_INTERNAL_ERROR,		; SDE_NOT_REGISTERED
	SE_INTERNAL_ERROR,		; SDE_ALREADY_REGISTERED
	SE_NON_UNIQUE_CONNECTION,	; SDE_CONNECTION_EXISTS
	SE_LINK_FAILED,			; SDE_LINK_OPEN_FAILED
	SE_CANT_LOAD_DRIVER,		; SDE_DRIVER_NOT_FOUND
	SE_DESTINATION_UNREACHABLE,	; SDE_DESTINATION_UNREACHABLE
	SE_CONNECTION_RESET, 		; SDE_CONNECTION_RESET_BY_PEER
	SE_CONNECTION_RESET,		; SDE_CONNECTION_RESET
	SE_INTERNAL_ERROR,		; SDE_UNSUPPORTED_FUNCTION
	SE_INTERNAL_ERROR,		; SDE_INVALID_CONNECTION_HANDLE
	SE_INTERNAL_ERROR,		; SDE_INVALID_ADDR_FOR_LINK
	SE_INTERNAL_ERROR,		; SDE_INVALID_ADDR
	SE_INTERNAL_ERROR,		; SDE_TEMPORARY_ERROR
	SE_INTERRUPT			; SDE_INTERRUPTED


SocketMapConnectError	endp

ApiCode		ends

UtilCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeClientSockets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up any sockets owned by this geode

CALLED BY:	SocketEntry
PASS:		bx	- geode whose sockets should be nuked
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeClientSockets	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		call	SocketControlStartWrite
		mov	dx, bx
		mov	si, offset SocketSocketArray
		mov	bx, cs
		mov	di, offset FreeClientSocket
		call	ChunkArrayEnum
		call	SocketControlEndWrite
		.leave
		ret
FreeClientSockets	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeClientSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up this socket, if owned by the given geode

CALLED BY:	FreeClientSockets (via ChunkArrayEnum)
PASS:		**ds:di	- SocketInfo
		bp	- geode handle
RETURN:		nothing
DESTROYED:	bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeClientSocket	proc	far
		.enter
	;
	; do we care about this socket?
	;
		mov	bx, ds:[di]
		mov	di, ds:[bx]
		cmp	ds:[di].SI_owner, bp
		jne	done
	;
	; we surely do, so disconnect and purge it
	;
		cmp	ds:[di].SI_state, ISS_CONNECTED
		jne	free
	;		call	SocketResetLow
free:
		call	SocketFreeLow
done:
		clc
		.leave
		ret
FreeClientSocket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketResetLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the connection on a socket

CALLED BY:	FreeClientSocket, SocketReset
PASS:		*ds:bx	- SocketInfo
RETURN:		carry set on error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketResetLow	proc	far
		uses	bx,cx,dx,si,di,bp
		.enter
EC <		mov	si, bx						>
EC <		call	ECCheckSocketLow				>
		mov	di, ds:[bx]
EC <		cmp	ds:[di].SI_delivery, SDT_DATAGRAM		>
EC <		ERROR_E ILLEGAL_OPERATION_ON_DATAGRAM_SOCKET		>
	;
	; verify that socket is connected
	;
		mov	ax, SE_SOCKET_NOT_CONNECTED
		cmp	ds:[di].SI_state, ISS_CONNECTED
		stc
		jne	done
	;
	; clear out any receivers
	;
		and	ds:[di].SI_flags, not ( mask SF_SEND_ENABLE or mask SF_RECV_ENABLE )
		or	ds:[di].SI_flags, mask SF_FAILED or mask SF_DISCARD
		mov	ds:[di].SSI_error, SE_CONNECTION_RESET
		call	WakeUpForClose
	;
	; check driver type
	;
		mov	si, ds:[di].SSI_connection.CE_domain
		mov	si, ds:[si]
		cmp	ds:[si].DI_driverType, SDT_DATA
		je	data
		call	SocketResetLinkConnection
		jmp	done
data:
		call	SocketResetDataConnection
done:
		.leave
		ret
SocketResetLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketResetLinkConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset a link

CALLED BY:	SocketResetLow
PASS:		*ds:bx	- socket info
		ds:si	- socket info
RETURN:		carry set on error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketResetLinkConnection	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; extract some useful info
	;
		mov	cx, ds:[si].SSI_connection.CE_domain
		mov	dx, ds:[si].SSI_connection.CE_link
		call	SocketFindLinkByHandle
EC <		ERROR_C CORRUPT_SOCKET					>
		push	bx
		sub	sp, size PacketInfo
		call	SetupPacketInfo		; copy info to stack
	;
	; send the close packet
	;
sendit::
		call	SocketControlEndWrite
		mov	ax, CCO_CANCEL
		call	SendConnectionControl	; send the packet
		call	SocketControlStartWrite
	;
	; clean up and exit
	;
		pop	bx
		clr	ax
		.leave
		ret
SocketResetLinkConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketResetDataConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify data driver that a connection has been reset

CALLED BY:	SocketResetLow
PASS:		*ds:bx	- socket
RETURN:		carry set on error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketResetDataConnection	proc	near
		uses	cx, si, di
		.enter
	;
	; find the domain
	;
		mov	si, ds:[bx]
		mov	cx, ds:[si].SSI_connection.CE_domain
	;
	; get a misc lock
	;
		xchg	cx,si
		call	SocketGrabMiscLock
		mov	di, ds:[si]
		xchg	cx,si
	;
	; call DR_SOCKET_RESET
	;
		pushdw	ds:[di].DI_entry
		mov	ax, ds:[si].SSI_connection.CE_link
		call	SocketControlEndWrite
		mov	di, DR_SOCKET_RESET_REQUEST
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		call	SocketControlStartWrite
	;
	; clean up the connection table
	;
	; there's a slight possibility that the driver simultaneously
	; asked us to close the same conneciton, so don't worry if
	; it isn't there any more
	;
		mov	si, cx			; *ds:si = domain info
		call	SocketFindLinkBySocket	; ds:di = connection info
		jc	release	
		call	ChunkArrayDelete
	;
	; release misc lock, possibly removing domain
	;
release:
		call	SocketReleaseMiscLock
		clr	ax
		.leave
		ret
SocketResetDataConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketInterruptConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt a connect request

CALLED BY:	SocketInterrupt
PASS:		ds:di = SocketInfo
RETURN:		carry set if error
		ax = SocketError
DESTROYED:	nothing
SIDE EFFECTS:	unlocks control block

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/17/00		Fixed failure to deref domain for non-EC
	EW	7/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketInterruptConnect	proc	far
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; find domain
	;
		mov	si, ds:[di].SSI_connection.CE_domain
		mov	si, ds:[si]		; ds:si <- DomainInfo
	;
	; if this is a link driver, the interruptable flag should be off
	; and we should never get here
	;
EC <		cmp	ds:[si].DI_driverType, SDT_DATA			>
EC <		ERROR_NE CORRUPT_SOCKET					>
	;
	; notify driver
	;
		pushdw	ds:[si].DI_entry
		mov	bx, ds:[di].SSI_connection.CE_link
		call	SocketControlEndWrite
		mov	di, DR_SOCKET_STOP_DATA_CONNECT
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; the only possible error is INVALID_CONNECTION_HANDLE, in which
	; case we assume the connection has been closed in the meanwhile
	; and just disregard the error
	;
EC <		jnc	done						>
EC <		cmp	ax, SDE_INVALID_CONNECTION_HANDLE		>
EC <		ERROR_NE UNEXPECTED_SOCKET_DRIVER_ERROR			>
done::
		clr	ax
		.leave
		ret
SocketInterruptConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCheckConnectInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for interrupts

CALLED BY:	SocketConnect
PASS:		*ds:bx	- SocketInfo
RETURN:		carry set to abort
			ax	- SE_INTERRUPT
		carry clear to continue
			ax	- unchanged
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCheckConnectInterrupt	proc	far
		uses	si
		.enter
		mov	si, ds:[bx]
		test	ds:[si].SI_flags, mask SF_INTERRUPT
		jz	done
		and	ds:[si].SI_flags, not (mask SF_INTERRUPT or mask SF_SINTERRUPT)
		mov	ax, SE_INTERRUPT
		stc
done:
		.leave
		ret
SocketCheckConnectInterrupt	endp

UtilCode	ends
