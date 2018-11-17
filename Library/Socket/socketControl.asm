COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Network extensions
MODULE:		socket library
FILE:		socketControl.asm

AUTHOR:		Eric Weber, Apr  8, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT ControlAttach           Initialize control-block related data

    EXT SocketGetDeliveryType   Get the delivery type for a socket

    INT WakeUpSocket            Wake up the thread which is blocked on a
				socket, if any

    INT WakeUpExcept            Wake up the thread which is blocked on a
				socket, if any

    EXT SocketFindPort          Locate a given port in the portmap

    EXT SocketFindFirstQueuedListen 
				Find the first PortInfo for the same port
				as that passed in that has anything on its
				listen queue.

    EXT SocketClearSemaphore    Free the wait semaphore from a socket, if
				present.

    EXT SocketClearExcept       Free the except semaphore from a socket, if
				present.

    EXT SetupPacketInfo         Copy information about a packet onto the
				stack

    INT SocketCreateLow         Low level function for allocating sockets

    EXT SocketFindOrCreatePort  Find or create a port

    EXT SocketImplicitBind      Choose a port and bind the socket to it

    INT SocketBindLow           low-level function to bind a socket to a
				port

    INT SocketAllocatePort      Create a port

    INT SocketConnectDatagram   Connect a datagram socket

    INT SocketRegisterConnection 
				Register the connection for a socket and
				add it to port's connection array

    INT RemoveSocketFromPort    Remove a socket from port's chunk array

    INT SocketClearConnection   Remove failed connection indication from a
				socket

    EXT SocketCreateListenQueue Create a listen queue chunk

    INT SocketListenLow         Set a socket to a listening state

    INT SocketCheckOpenState    Determine the outcome of an open operation

    INT SocketPreAccept         Initiate acceptance of a connection

    INT SocketPostLinkAccept    Clean up after accepting

    INT FreeListenQueue         Free a listen queue

    EXT FreePortListenQueue     Free the listen queue associated with a
				port, canceling all connections pending for
				it.

    EXT FreeListenQueueCallback callback for FreeListenQueue sends
				CCO_REFUSE and decrements link ref count

    INT SocketFreeLow           Free a socket chunk and possibly the port
				chunk

    EXT SocketFreePort          Free a port, if it is not in use

    INT SocketCheckReadySetup   Setup to wait on sockets

    INT SocketCheckReadyHere    See if a particular socket is ready

    INT SocketCheckReadyCleanup remove semaphore from all sockets currently
				containing it

    INT SocketPostDataAccept    Accept a connection from a data driver

    INT SetupDatagramInfo       Copy information about a packet onto the
				stack

    INT SocketGetLink           Get the domain and link a socket is using

    INT SocketGetAddress        Get default address for a datagram socket

    INT SocketGetDomainName     Get the domain name a socket is connect
				over

    INT SocketQueryAddress      Query a driver for either the local or
				remote name

    INT SocketGetRemotePort     Get remote port number

    INT SocketGetLocalPort      Get port this socket is bound to

    INT SocketPassOption        Pass an option through to the driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/ 8/94   	Initial revision


DESCRIPTION:
	Code for managing ports and sockets
		
	$Id: socketControl.asm,v 1.44 97/10/28 00:12:30 brianc Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SocketControl	segment lmem LMEM_TYPE_GENERAL, mask LMF_RETURN_ERRORS

SocketSocketArray	chunk	SocketArray
	ChunkArrayHeader <0, size word, 0, size SocketArray>
EC <	ControlChunkType CCT_SOCKET_ARRAY				>
SocketSocketArray	endc

SocketPortArray		chunk	PortArray
	ChunkArrayHeader <0, size PortArrayEntry, 0, size PortArray>
EC <	ControlChunkType CCT_PORT_ARRAY					>
SocketPortArray	endc

SocketDomainArray	chunk	DomainArray
	ChunkArrayHeader <0, size word, 0, size DomainArray>
EC <	ControlChunkType CCT_DOMAIN_ARRAY				>
SocketDomainArray	endc

SocketControl	ends

idata		segment

;
; where to read the implicit port range from the init file
;
minImplicitKey		char	"minImplicitPort",0
maxImplicitKey		char	"maxImplicitPort",0

idata		ends

udata		segment

;
; any implicitly bound ports will have port numbers between
; minImplicitPort+1 and maxImplicitPort inclusively.
;
minImplicitPort		word
maxImplicitPort		word

;
; this is the last implicit port which was assigned
;
curImplicitPort		word

udata		ends

UtilCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ControlAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize control-block related data

CALLED BY:	(INTERNAL) SocketEntry
PASS:		ds = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ControlAttach	proc	far
		uses	ax,cx,dx,si
		.enter
	;
	; read the min implicit port
	;
		Assert	dgroup, ds
		mov	si, offset ds:[socketCategory]
		mov	cx, ds
		mov	dx, offset ds:[minImplicitKey]
		mov	ax, IMPLICIT_PORT_MIN
		call	InitFileReadInteger
	;
	; the min port must be in the range 0..65534
	;
		cmp	ax, -1
		jne	minOK
		WARNING	INVALID_MIN_IMPLICIT_PORT
		mov	ax, -2
minOK:
		mov	ds:[minImplicitPort], ax
		mov	ds:[curImplicitPort], ax
	;
	; read the max implicit port
	;
		mov	dx, offset ds:[maxImplicitKey]
		mov	ax, IMPLICIT_PORT_MAX
		call	InitFileReadInteger
	;
	; the max port must be in the range min+1..65535
	;
		cmp	ax, ds:[minImplicitPort]
		ja	maxOK
		WARNING	INVALID_MAX_IMPLICIT_PORT
		mov	ax, ds:[minImplicitPort]
		inc	ax
maxOK:
		mov	ds:[maxImplicitPort], ax
		
		.leave
		ret
ControlAttach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetDeliveryType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the delivery type for a socket

CALLED BY:	(EXTERNAL) SocketConnect, SocketSend
PASS:		*ds:bx	- Socket
RETURN:		cx	- SocketDeliveryType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetDeliveryType	proc	far
		uses	si
		.enter
		mov	si, ds:[bx]
		mov	cl, ds:[si].SI_delivery
		clr	ch
		.leave
		ret
SocketGetDeliveryType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WakeUpSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wake up the thread which is blocked on a socket, if any

CALLED BY:	(INTERNAL) ConnectionAccept, ConnectionBegin,
		ConnectionCancel, ConnectionClose, ConnectionOpen,
		ConnectionRefuse, ReceiveDatagramDataPacket,
		ReceiveLinkDataPacket, ReceiveSequencedDataPacket,
		SocketConnectRequest, SocketConnectionClosed,
		SocketInterrupt, SocketRemoveConnection
PASS:		*ds:bx	- SocketInfo
RETURN:		z set if nobody waiting
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	use SI_semSem to control access to waitSem, to ensure that
	no other thread is in the middle of SocketClearSemaphore

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WakeUpSocket	proc	far
		uses	bx,si,di
		.enter
		mov	si,bx
EC <		call	ECCheckSocketLow				>
		mov	di, ds:[bx]
	;
	; lock semSem
	;
		mov	bx, ds:[di].SI_semSem
		call	ThreadPSem
	;
	; wake up waiter
	;
		call	WakeUpSocketLow
	;
	; unlock semSem
	;
		mov	bx, ds:[di].SI_semSem
		call	ThreadVSem
		.leave
		ret
WakeUpSocket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WakeUpExcept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wake up the thread which is blocked on a socket, if any

CALLED BY:	(INTERNAL) ReceiveUrgentDataPacket
PASS:		*ds:bx	- SocketInfo
RETURN:		z flag set if nobody waiting
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	use SI_semSem to control access to exceptSem, to ensure that
	no other thread is in the middle of SocketClearExcept

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WakeUpExcept	proc	far
		uses	bx,si,di
		.enter
		mov	si,bx
EC <		call	ECCheckSocketLow				>
		mov	di, ds:[bx]
	;
	; lock semSem
	;
		mov	bx, ds:[di].SI_semSem
		call	ThreadPSem
	;
	; wake up anyone waiting explicitly for exception/urgent
	;
		call	WakeUpExceptLow
	;
	; if nobody is waiting on exceptSem, set SF_EXCEPT and
	; wake up the waitSem instead
	;
checkWait::
		or	ds:[di].SI_flags, mask SF_EXCEPT
		call	WakeUpSocketLow
done::
		mov	bx, ds:[di].SI_semSem
		call	ThreadVSem
		.leave
		ret
WakeUpExcept	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WakeUpForClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wake everyone up, because receive just got disabled

CALLED BY:	
PASS:		*ds:bx	- socket
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WakeUpForClose	proc	far
		uses	bx,si,di
		.enter
	;
	; validate socket
	;
		mov	si,bx
EC <		call	ECCheckSocketLow				>
		mov	di, ds:[bx]
EC <		test	ds:[di].SI_flags, mask SF_RECV_ENABLE		>
EC <		ERROR_NZ RECEIVE_STILL_ENABLED				>
	;
	; grab semSem
	;
		mov	bx, ds:[di].SI_semSem
		call	ThreadPSem
	;
	; wake everyone up
	;
		call	WakeUpExceptLow
		call	WakeUpSocketLow
	;
	; release semSem
	;
		call	ThreadVSem
		.leave
		ret
WakeUpForClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WakeUpSocketLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wake up whomever is on the waitSem

CALLED BY:	WakeUpSocket, WakeUpExcept
PASS:		ds:di	- SocketInfo
		ds:di.SI_semSem locked if control block is shared
RETURN:		z set if nobody waiting
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WakeUpSocketLow	proc	far
		uses	bx, es
		.enter
	;
	; unlock waitSem
	;
		mov	bx, ds:[di].SI_waitSem
		tst	bx
		jz	done
		call	ThreadVSem
	;
	; write socket handle to waitPtr, if necessary
	;
		tst	ds:[di].SI_waitPtr.segment	; ptr exists?
		jz	done
writePtr::
		push	di
		movdw	esdi, ds:[di].SI_waitPtr
		mov	es:[di], si			; write socket han
		pop	di
done:
		.leave
		ret
WakeUpSocketLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WakeUpExceptLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wake up the thread on exceptSem

CALLED BY:	WakeUpExcept
PASS:		ds:di - socket
		ds:di.SI_semSem locked if control block locked shared
RETURN:		z flag - set if nobody waiting
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WakeUpExceptLow	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; unlock exceptSem
	;
		mov	bx, ds:[di].SI_exceptSem
		tst	bx
		jz	done
		call	ThreadVSem
	;
	; write socket handle to exceptPtr, if necessary
	;
		tst	ds:[di].SI_exceptPtr.segment	; ptr exists?
		jz	done
		push	di
		movdw	esdi, ds:[di].SI_exceptPtr
		mov	es:[di], si			; write socket han
		pop	di
done:
		.leave
		ret
WakeUpExceptLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFindPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate a given port in the portmap

CALLED BY:	(EXTERNAL) ConnectionAccept, ConnectionBegin,
		ConnectionCancel, ConnectionClose, ConnectionOpen,
		ConnectionRefuse, ECCheckPortLow,
		ReceiveDatagramDataPacket, ReceiveLinkDataPacket,
		SocketCheckListen, SocketConnectRequest,
		SocketFindOrCreatePort, SocketFreePort, SocketImplicitBind,
		SocketRemoveLoadOnMsgMem
PASS:		ds - control block
		axbx - SocketPort
		dx - domain handle

RETURN:		*ds:si - port array
		if found:
			carry clear
			ds:di - PortArrayEntry
		if not found:
			carry set
			ds:di - element before which to insert new port
				di = 0 if new port should be appended
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This routine is used as part of the process of looking up
	a socket for every incoming packet.  Therefore it must be fast.

	This is why it does it's own chunk array computations instead of
	using the ChunkArray functions in the kernel

	It doesn't really need to be that fast, but it works now so I'm
	not changing it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFindPort	proc	far
		uses	ax,bx,cx,dx,bp,es
		.enter
	;
	; save domain handle
	;
		push	dx
	;
	; locate the portmap and get a count of active ports
	;
		mov	si, offset SocketPortArray
		mov	di, ds:[si]
		mov	cx, ds:[di].CAH_count
	;
	; set up for loop
	;
		jcxz	append		; handle empty array
		clr	bp		; bp = lower bound = 0
		dec	cx		; cx = upper bound = count-1
		mov	dx,cx
		shr	dx		; dx = cx/2 = first element to check
	;
	; main loop:
	;	bp	= lower bound of element range (inclusive)
	;	dx	= element to check next
	;	cx	= upper bound of element range (inclusive)
	;	axbx	= SocketPort to search for
	;	*ds:si	= portmap
	;	(on stack) = domain handle
	;
top:
	;
	; if we have a negative region, we didn't find it
	;
		cmp	bp,cx
		jg	notFound
	;
	; get a pointer to the element
	;
		push	ax,dx
		mov	ax, size PortArrayEntry	; ax = size of element
		mul	dx			; dxax = offset to element

		mov	di, ds:[si]		; ds:di = array header
		add	di, ds:[di].CAH_offset	; ds:di = first element
		add	di, ax			; ds:di = desired element
		pop	ax,dx
	;
	; is this the one?
	;
		cmpdw	axbx, ds:[di].PAE_id
		jb	lower
		je	found
	;
	; we need to search higher in the array
	;
higher:
		inc	dx			; dx = new lower bound
		mov	bp,dx			; bp = new lower bound
		add	dx,cx			; dx = sum of bounds
		shr	dx			; dx = median of bounds
		jmp	top
	;
	; we need to search lower in the array
	;
lower:
		dec	dx			; dx = new upper bound
		mov	cx,dx			; cx = new upper bound
		add	dx,bp			; dx = sum of bounds
		shr	dx			; dx = median of bounds
		jmp	top
	;
	; the element wasn't found
	; bp = index at which to add new element
	;
notFound:
		mov	ax,bp
		call	ChunkArrayElementToPtr	; ds:di=elt, cf=out of bounds
		cmc
		jc	done			; jmp if not out of bounds
	;
	; the element is larger then the last element of the array
	;
append:
		clr	di
		stc
		jmp	done
	;
	; we found something with the right port number
	; ds:di = element, dx = index
	; compare the domains
	;
found:
		pop	ax			; domain to check
		push	ax
		tst_clc	ax
		jz	done			; unrestricted search
		
		mov	bx, ds:[di].PAE_info
		mov	bx, ds:[bx]		; ds:bx = PortInfo
		tst_clc	ds:[bx].PI_restriction
		jz	done			; port ok for all domains
		
		cmp	ax, ds:[bx].PI_restriction
		movdw	axbx, ds:[di].PAE_id	; restore port number
		ja	higher
		jb	lower
	;
	; Eureka! this port matches in all regards
	;
done:
		pop	ax			; discard domain handle
		.leave
		ret
SocketFindPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFindFirstQueuedListen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first PortInfo for the same port as that passed in
		that has anything on its listen queue.

CALLED BY:	(EXTERNAL) SocketCheckListen
PASS:		ds:di	= PortArrayEntry found (may not be the first one
			  in the array, though)
		*ds:si	= port array
RETURN:		carry set if no port is actually listening:
			ax	= SE_NOT_LISTENING
			si	= destroyed
		carry clear if found a listening port:
			ds:di	= PortInfo
			*ds:si	= listen queue
			ax	= destroyed
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFindFirstQueuedListen proc far
		uses	bx, dx, bp, cx
		.enter
	;
	; Load the port number into bxdx for convenience
	;
		movdw	bxdx, ds:[di].PAE_id
	;
	; Back up to the first entry for the port, in case the unrestricted
	; binary search landed us in the middle of the port range.
	;
		call	ChunkArrayPtrToElement
		call	ChunkArrayGetCount
		xchg	cx, ax
		sub	ax, cx
		
entryLoop:
		jcxz	haveFirst
	    ;
	    ; Check the previous entry to see if it's for the same port.
	    ;
		lea	si, ds:[di-size PortArrayEntry]
		cmpdw	ds:[si].PAE_id, bxdx
		jne	haveFirst		; => no, so ds:di is first

		dec	cx			; one fewer to look at before
						;  this one
		inc	ax			; one more to look at after
		mov	di, si			; ds:di <- prev
		jmp	entryLoop
haveFirst:
	;
	; ds:di = entry to look at first
	; ax = # entries left in the array following (and including) ds:di
	; bxdx = port #
	;
	; Now look at the listen queue for each one for this port until we
	; find one that has something in it.
	;
	; At the end of the loop, when nothing found that's listening:
	; 	ax = SE_PORT_NOT_LISTENING if nothing was listening
	;	ds:bp = PortArrayEntry for first port that was listening,
	;		if ax is 0
	;
		mov_tr	cx, ax			; cx <- # to examine
		mov	ax, SE_PORT_NOT_LISTENING
		clr	bp
findQueueLoop:
		cmpdw	ds:[di].PAE_id, bxdx
		jne	noneFound
		mov	si, ds:[di].PAE_info
		mov	si, ds:[si]		; ds:si <- PortInfo
		mov	si, ds:[si].PI_listenQueue
		tst	si
		jz	findQueueNext
		clr	ax			; found at least one that's
						;  listening
		tst	bp
		jnz	checkCount
		mov	bp, di
checkCount:
		mov	si, ds:[si]
		tst	ds:[si].CAH_count
		jnz	foundIt
findQueueNext:
		add	di, size PortArrayEntry
		loop	findQueueLoop
noneFound:
		tst	ax			; none listening?
		stc				; assume so
		jnz	done			; => so
		
		mov	di, bp			; ds:di <- first listener,
						;  though queue is empty
foundIt:
		mov	di, ds:[di].PAE_info
		mov	di, ds:[di]
		mov	si, ds:[di].PI_listenQueue
		clc
done:
		.leave
		ret

SocketFindFirstQueuedListen endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketClearSemaphore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the wait semaphore from a socket, if present.

CALLED BY:	(EXTERNAL) SocketAccept, SocketClose, SocketConnect,
		SocketPreAccept, SocketRecvLow
PASS:		*ds:bx	- SocketInfo
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	use SI_semSem to control access to waitSem, to ensure that
	no other thread is in the middle of WakeUpSocket

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketClearSemaphore	proc	far
		uses	ax,bx,si
		pushf
		.enter
		mov	si, ds:[bx]
		mov	bx, ds:[si].SI_semSem
		call	ThreadPSem
		clrdw	ds:[si].SI_waitPtr		; clear pointer
		clr	bx
		xchg	bx, ds:[si].SI_waitSem		; clear semaphore
		tst	bx
		jz	done
		call	ThreadFreeSem			; free semaphore
done:
		mov	bx, ds:[si].SI_semSem
		call	ThreadVSem
		.leave
		popf
		ret
SocketClearSemaphore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketClearExcept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the except semaphore from a socket, if present.

CALLED BY:	(EXTERNAL) SocketRecvLow
PASS:		*ds:bx	- SocketInfo
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	use SI_semSem to control access to exceptSem, to ensure that
	no other thread is in the middle of WakeUpExcept

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketClearExcept	proc	far
		uses	ax,bx,si
		pushf
		.enter
		mov	si, ds:[bx]
		mov	bx, ds:[si].SI_semSem
		call	ThreadPSem
		clrdw	ds:[si].SI_exceptPtr		; clear pointer
		clr	bx
		xchg	bx, ds:[si].SI_exceptSem	; clear semaphore
		tst	bx
		jz	done
		call	ThreadFreeSem			; free semaphore
done:
		mov	bx, ds:[si].SI_semSem
		call	ThreadVSem
		.leave
		popf
		ret
SocketClearExcept	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupPacketInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy information about a packet onto the stack

CALLED BY:	(EXTERNAL) SocketAccept, SocketClearConnection,
		SocketConnect, SocketSend, SocketSendClose
PASS:		*ds:bx	- SocketInfo
		*ds:cx	- DomainInfo
		dx	- link offset
	ON STACK
		uninitialized PacketInfo
RETURN:		PacketInfo filled in (args not popped)
		bx	- waitSem from socket
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupPacketInfo	proc	far	info:PacketInfo
		uses	ax,si,di
		.enter
	;
	; get information from the socket
	;
getSocket::
		mov	si, ds:[bx]			; ds:si = SocketInfo
		movdw	ss:[info].PI_destPort,ds:[si].SSI_connection.CE_port,ax
		mov	bx, ds:[si].SI_waitSem
	;
	; get information from the port
	;
		mov	di, ds:[si].SI_port
		mov	di, ds:[di]			; ds:di = PortInfo
		movdw	ss:[info].PI_srcPort, ds:[di].PI_number, ax
	;
	; get information from the domain
	;
		mov	di, cx
		mov	di, ds:[di]
		segmov	ss:[info].PI_driverType,ds:[di].DI_driverType, al
		segmov	ss:[info].PI_client,	ds:[di].DI_client, ax
		movdw	ss:[info].PI_entry,	ds:[di].DI_entry, ax
		mov	al, ds:[di].DI_seqHeaderSize
		clr	ah
		mov	ss:[info].PI_headerSize, ax
	;
	; get information from the link
	;
		add	di, dx				; ds:di = LinkInfo
		segmov	ss:[info].PI_link,	ds:[di].LI_handle, ax
	;
	; make sure socket and link agree
	;
EC <		cmp	ds:[si].SSI_connection.CE_domain, cx		>
EC <		ERROR_NE SOCKET_LINK_MISMATCH				>
EC <		mov	ax, ds:[di].LI_handle				>
EC <		cmp	ds:[si].SSI_connection.CE_link, ax		>
EC <		ERROR_NE SOCKET_LINK_MISMATCH				>
		
		.leave
		ret		; DO NOT POP ARGS
SetupPacketInfo	endp

UtilCode	ends

ApiCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCreateLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level function for allocating sockets

CALLED BY:	(INTERNAL) SocketCreate, SocketPreAccept
PASS:		ds	- control block
		ax	- SocketDeliveryType
RETURN:		ax	- Socket
		ds	- control block (possibly moved)
		carry set if out of memory
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCreateLow	proc	near
		uses	bx,cx,si,di
		.enter
	;
	; allocate a socket
	;
		mov	bx,ax			; save delivery type
		clr	al			; no object flags
		mov	cx, size SequencedSocketInfo	; chunk size
		cmp	bl, SDT_DATAGRAM
		jne	alloc
		mov	cx, size DatagramSocketInfo
alloc:
		call	LMemAlloc		; ax = chunk
		jc	done
	;
	; add it to the socket array
	;
		mov	si, offset SocketSocketArray
		call	ChunkArrayAppend
		jnc	appendOK
		call	LMemFree		; discard socket
		stc
		jmp	done
appendOK:
		mov	ds:[di], ax
	;
	; set the delivery type
	;
		mov	si, ax
		mov	si, ds:[si]		; ds:si = SocketInfo
		mov	ds:[si].SI_delivery, bl
	;
	; set the owner
	;
		call	GeodeGetProcessHandle	; bx = owner of this thread
		mov	ds:[si].SI_owner, bx
	;
	; allocate a semaphore
	;
		mov	bx, 1
		call	ThreadAllocSem		; bx = semaphore
		push	ax
		mov	ax, handle 0
		call	HandleModifyOwner
		pop	ax
		mov	ds:[si].SI_semSem, bx
	;
	; initialize the rest of the common fields
	;
EC <		mov	ds:[si].SI_type, CCT_SOCKET_INFO		>
		mov	ds:[si].SI_state, ISS_UNCONNECTED
		clr	bx			; bx <- 0 for initializing
						;  everything that needs to
						;  be zero
		mov	ds:[si].SI_flags, mask SF_INTERRUPTIBLE
		mov	ds:[si].SI_port, bx
		mov	ds:[si].SI_dataQueue, bx
		movdw	ds:[si].SI_curQueueSize, bxbx
		mov	ds:[si].SI_maxQueueSize.low, DEFAULT_MAX_RECV_QUEUE_SIZE
		mov	ds:[si].SI_maxQueueSize.high, bx
		mov	ds:[si].SI_maxSendSize, DEFAULT_MAX_SEND_QUEUE_SIZE
		mov	ds:[si].SI_queueToken, bx
		mov	ds:[si].SI_dataOffset, bx
		mov	ds:[si].SI_waitSem, bx
		movdw	ds:[si].SI_waitPtr, bxbx
		mov	ds:[si].SI_exceptSem, bx
		movdw	ds:[si].SI_exceptPtr, bxbx
	;
	; initialize sequenced or datagram specific fields
	;
			CheckHack <SDT_DATAGRAM eq 0>	; so that CF always
							;  clear after CMP.
		cmp	ds:[si].SI_delivery, SDT_DATAGRAM	; CF clear
		je	datagram
		movdw	ds:[si].SSI_urgent, bxbx
		mov	ds:[si].SSI_urgentSize, bx
	;
	; these fields don't strictly need to be initialized, but it makes
	; things cleaner while debugging
	;
EC <		mov	ds:[si].SSI_error, bx				>
EC <		mov	ds:[si].SSI_connection.CE_domain, bx		>
EC <		mov	ds:[si].SSI_connection.CE_link, bx		>
EC <		movdw	ds:[si].SSI_connection.CE_port, bxbx		>
		jmp	done
	;
	; initialize datagram fields
	;
datagram:
		mov	ds:[si].DSI_domain, bx
		mov	ds:[si].DSI_addressSize, bx
		mov	ds:[si].DSI_exception, bl
done:
		.leave
		ret

SocketCreateLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFindOrCreatePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find or create a port

CALLED BY:	(EXTERNAL) SocketAddLoadOnMsgMem, SocketBindLow
PASS:		axbx	- SocketPort
		dx:di	- domain to bind in (dx = 0 if none)
		ds	- control segment locked for writing
RETURN:		bx	- port handle
		ax	- SocketError (carry set on error)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFindOrCreatePort	proc	far
		uses	cx,dx,si,di,bp
		portNum	local	SocketPort	push ax,bx
		.enter
	;
	; was a domain passed?
	;
		clr	bx			; assume it doesn't
		tst	dx
		je	domainOK
	;
	; it was, but does it exist?
	; note that it doesn't matter what state the domain is in
	;
		push	bp
		mov	bp,di
		call	SocketFindDomainLow	; bx = domain
		jnc	updateDomain
	;
	; it doesn't, so create it
	;
		call	SocketCreateDomain	; bx = domain
		mov	ax, SE_OUT_OF_MEMORY
	;
	; check for errors
	;
updateDomain:
		pop	bp
		jc	done			; (carry from SocketCreate,
						;  when taken)
	;
	; got the domain, now locate the port
	;
domainOK:
		mov	dx,bx			
		movdw	axbx, ss:[portNum]
		call	SocketFindPort		; locate the entry
		jnc	located
		call	SocketAllocatePort	; or create it if needed
		mov	ax, SE_OUT_OF_MEMORY
		jc	done
	;
	; we may have found a restricted port on an unrestricted search
	; or vice versa
	;
located:
		mov	bx, ds:[di].PAE_info	; *ds:bx = PortInfo
		mov	di, ds:[bx]
		cmp	dx, ds:[di].PI_restriction
		je	done			; carry clear if equal
		mov	ax, SE_BIND_CONFLICT
		stc
done:
		.leave
		ret
SocketFindOrCreatePort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketImplicitBind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose a port and bind the socket to it

CALLED BY:	(EXTERNAL) SocketConnect, SocketSend
PASS:		bx	- socket
		cx	- domain
		ds	- control segment
RETURN:		carry	- set if error
		ax	- SocketError if error, preserved if no error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketImplicitBind	proc	far
		uses	bx,cx,dx,si,di,bp,es
		socketHan	local	word push bx
		domainHan	local	word push cx
		passedAX	local	word push ax
		.enter
	;
	; get dgroup pointer
	;
		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx
	;
	; validate socket
	;
EC <		mov	si, bx						>
EC <		call	ECCheckSocketLow				>
	;
	; check for an existing binding
	;
		mov	si, ds:[bx]
		tst_clc	ds:[si].SI_port
		jnz	done
	;
	; choose the manufacturer id
	;
		mov	si, cx
		mov	si, ds:[si]
		mov	ax, MANUFACTURER_ID_GEOWORKS
		cmp	ds:[si].DI_driverType, SDT_DATA
		jne	gotID
		mov	ax, MANUFACTURER_ID_SOCKET_16BIT_PORT
gotID:
	;
	; locate the start of that id in the port array
	;
		mov	bx, es:[curImplicitPort]
		cmp	bx, es:[maxImplicitPort]
		jb	startOK
		mov	bx, es:[minImplicitPort]
startOK:
		inc	bx
		clr	dx				; unrestricted search
		call	SocketFindPort
		jc	gotPort
	;
	; compute the upper bound of the array
	;
		push	ax,di
		mov	ax, CA_LAST_ELEMENT
		call	ChunkArrayElementToPtr		; ds:di = last element
		mov	dx,di
		pop	ax,di
	;
	; skip any entries with the same portnum
	;
skip:
		cmp	di, dx
		je	append
		add	di, size PortArrayEntry
		cmpdw	axbx, ds:[di].PAE_id
		je	skip
	;
	; try the next port number
	;
		cmp	bx, es:[curImplicitPort]
		je	busy
		cmp	bx, es:[maxImplicitPort]
		jne	nextPort
		mov	bx, es:[minImplicitPort]
nextPort:
		inc	bx
		cmpdw	axbx, ds:[di].PAE_id
		je	skip				; next port is busy too
	;
	; axbx is not in use
	; create a port for it
	;
gotPort:
		mov	es:[curImplicitPort], bx
		mov	dx, ss:[domainHan]		
		call	SocketAllocatePort
		jnc	initSocket
		mov	ax, SE_OUT_OF_MEMORY
		jmp	done
append:
		clr	di
		jmp	gotPort
	;
	; bind the socket
	;
initSocket:
		mov	di, ds:[di].PAE_info	; port handle
		mov	bx, ss:[socketHan]	
		mov	si, ds:[bx]		; ds:si = SocketInfo
		mov	ds:[si].SI_port, di
		mov	di, ds:[di]		; ds:di = PortInfo
		mov	ds:[di].PI_numActive, 1
	;
	; normal exit
	;
		clc
		mov	ax, ss:[passedAX]
done:
		.leave
		ret
	;
	; all portnums are in use
	; this can never happen, since we'd run out of memory first
	;
busy:
		mov	ax, SE_ALL_PORTS_BUSY
		stc
		jmp	done
		
SocketImplicitBind	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketBindLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	low-level function to bind a socket to a port

CALLED BY:	(INTERNAL) SocketBind, SocketBindInDomain
PASS:		ds	- control block
		*ds:si	- SocketInfo
		axbx	- SocketPort
		cx	- SocketBindFlags
		dx:di	- domain name	(dx = 0 if none)

RETURN:		carry	- set on error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketBindLow	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; find or create a port
	;
		call	SocketFindOrCreatePort	; bx = port
		jc	abort
	;
	; socket can't be bound already
	;
		mov	di, ds:[si]		; ds:di = socket info
		tst	ds:[di].SI_port
		jnz	alreadyBound
	;
	; treat datagrams differently
	;
		cmp	ds:[di].SI_delivery, SDT_DATAGRAM
		mov	di, ds:[bx]		; ds:di = port info
		je	datagram
	;
	; check for existing binds
	;
		tst	ds:[di].PI_numActive
		jz	activeOK
		test	cx, mask SBF_REUSE_PORT
		jz	portInUse
activeOK:
		inc	ds:[di].PI_numActive
	;
	; we've updated the port, now update the socket
	;
		mov	di, ds:[si]		; ds:di = SocketInfo
		mov	ds:[di].SI_port, bx	; pointer to PortInfo
		jmp	done
	;
	; the socket is already bound
	;
alreadyBound:
		mov	ax, SE_SOCKET_ALREADY_BOUND
		stc
		jmp	abort
	;
	; another socket is already bound to the port
	;
portInUse:
		stc
		mov	ax, SE_PORT_IN_USE
		jmp	abort
	;
	; check for other datagram users
	;
datagram:
		tst	ds:[di].PI_dgram
		jnz	portInUse
	;
	; create a data queue
	;
		push	bx
		mov	bx, si
		call	SocketAllocQueue
		pop	bx
		mov	ax, SE_OUT_OF_MEMORY
		jc	abort
	;
	; update port and socket
	;
		mov	ds:[di].PI_dgram, si
		mov	di, ds:[si]			; ds:di = SocketInfo
		mov	ds:[di].SI_port, bx
done::
		mov	ax, SE_NORMAL
		clc
abort:
		.leave
		ret

SocketBindLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAllocatePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a port

CALLED BY:	(INTERNAL) SocketFindOrCreatePort, SocketImplicitBind
PASS:		ds	- control block
		*ds:si	- port array
		ds:di   - PortArrayElement to precede
		axbx	- SocketPort
		dx	- domain handle

RETURN:		ds:di	- PortArrayEntry
		carry	- set if couldn't allocate memory

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	allocating the PAE will destroy the offset in di, so convert
	it to an index during the allocation and convert it back after

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAllocatePort	proc	near
		uses	ax,bx,cx,dx,bp,si
		portArray	local	nptr	push si
		portNum		local	dword	push ax,bx
		index		local	word
		.enter
	;
	; get the index of the PortArrayEntry
	;
		mov	ss:[index], CA_NULL_ELEMENT
		tst	di
		jz	alloc
		call	ChunkArrayPtrToElement
		mov	ss:[index], ax
	;
	; allocate the PortInfo
	;
alloc:
		mov	bx, size Socket		; element size
		mov	cx, size PortInfo	; header size
		clr	si			; new chunk
		call	ChunkArrayCreate	; *ds:si = array
		jc	done			; out of memory
	;
	; initialize the port
	;
		push	di
		mov	di, ds:[si]
EC <		mov	ds:[di].PI_type, CCT_PORT_INFO			>
		movdw	ds:[di].PI_number, ss:[portNum], ax
		mov	ds:[di].PI_restriction, dx
		pop	di
	;
	; insert or append a PortArrayEntry
	;
		mov	dx,si			; *ds:dx PortInfo
		mov	si, ss:[portArray]
		mov	ax, ss:[index]
		cmp	ax, CA_NULL_ELEMENT
		jne	insert
	;
	; append the new entry
	;
		call	ChunkArrayAppend	; ds:di = new element
		jnc	init
	;
	; if we couldn't allocate the PortArrayEntry, get rid of the PortInfo
	;
extendFailed:
		call	LMemFree		; free PortInfo
		stc
		jmp	done
	;
	; insert a new PortArrayEntry at ds:di
	;
insert:
		call	ChunkArrayElementToPtr	; ds:di = elt to insert before
		call	ChunkArrayInsertAt	; ds:di = new element
		jc	extendFailed
	;
	; initialize the PortArrayEntry
	;
init:
		movdw	ds:[di].PAE_id, ss:[portNum], bx
		mov	ds:[di].PAE_info, dx
		clc
done:
		.leave
		ret
SocketAllocatePort	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketConnectDatagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect a datagram socket

CALLED BY:	(INTERNAL) SocketConnect
PASS:		*ds:bx	= SocketInfo
		es:di	= SocketAddress
RETURN:		carry set on error
		ax	= SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketConnectDatagram	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; validate the socket
	;
		mov	si, bx
EC <		call	ECCheckSocketLow				>
	;
	; locate and lock the domain
	;
		call	SocketAddressToDomain		; dx = domain
		jc	done
	;
	; resize socket
	;
		mov	ax,si
		mov	cx, es:[di].SA_addressSize
		add	cx, size DatagramSocketInfo
		call	LMemReAlloc
		mov	ax, SE_OUT_OF_MEMORY
		jc	done
	;
	; now store the address in the socket
	;
		push	si, dx
		mov	bx, ds:[si]		; ds:bx = SocketInfo
		mov	ds:[bx].SI_state, ISS_CONNECTED
		xchg	ds:[bx].DSI_domain, dx	; store domain handle
		movdw	ds:[bx].DSI_port, es:[di].SA_port, ax
		mov	cx, es:[di].SA_addressSize
		mov	ds:[bx].DSI_addressSize, cx
		segxchg	ds,es
		lea	si, ds:[di].SA_address
		lea	di, es:[bx].DSI_address
EC <		call	ECCheckMovsb					>
		rep	movsb
		segxchg	ds,es				; restore for return

	; edwdig - time to kill the evil evil damn stupid udp bug!
	; die bug die!
	;
		pop	bx, cx
		mov	si, ds:[bx]
		tst	ds:[si].SI_port
		jnz	release
		call	SocketImplicitBind
		jc	release
		mov	di, ds:[si].SI_port
		mov	di, ds:[di]
		mov	ds:[di].PI_dgram, bx
		call	SocketAllocQueue
		mov	ax, SE_OUT_OF_MEMORY

	;
	; if there was a domain before, release our misc lock
	;
release:
		pushf
		tst	dx
		jz	cleanup
		mov	si, dx				; *ds:si = old domain
		call	SocketReleaseMiscLock
	;
	; clean up and exit
	;
cleanup:
		popf
		jc	done
		mov	ax, SE_NORMAL
		clc
done:
		.leave
		ret
SocketConnectDatagram	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRegisterConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register the connection for a socket and add it to port's
		connection array

CALLED BY:	(INTERNAL) SocketConnect
PASS:		ds	- control block
		bx	- Socket
		cx	- domain
		dx	- link offset
		es:di	- address
RETURN:		carry set on error
			ax	- SocketError
		carry clear if no error
			ax	- driver type
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRegisterConnection	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter

		movdw	axdi, es:[di].SA_port
		pushdw	axdi			; save SocketPort
	;
	; verify the socket
	;
		mov	si,bx			; si = Socket
EC <		call	ECCheckSocketLow				>
	;
	; verify the delivery type 
	;
		mov	si, ds:[si]
EC <		cmp	ds:[si].SI_delivery, SDT_DATAGRAM		>
EC <		ERROR_E ILLEGAL_OPERATION_ON_DATAGRAM_SOCKET		>
	;
	; verify 16-bit ports, if needed
	;
		mov	di, cx
		mov	di, ds:[di]
		cmp	ds:[di].DI_driverType, SDT_DATA
		jne	portOK
		cmp	ax, MANUFACTURER_ID_SOCKET_16BIT_PORT
		mov	ax, SE_DOMAIN_REQUIRES_16BIT_PORTS
		jne	error
	;
	; verify state
	;
portOK:
		cmp	ds:[si].SI_state, ISS_UNCONNECTED
		je	stateOK
		mov	ax, SE_SOCKET_IN_USE
		jmp	error
	;
	; allocate the data queue
	;
stateOK:
		call	SocketAllocQueue
		mov	ax, SE_OUT_OF_MEMORY
		jc	error
	;
	; store pointer to socket in port's array
	;
		mov	si, ds:[si].SI_port
EC <		call	ECCheckPortLow					>
		call	ChunkArrayAppend			; ds:di = entry
		mov	ax, SE_OUT_OF_MEMORY
		jc	portError
		mov	ds:[di], bx				; store socket
	;
	; update the state
	;		
		mov	si, ds:[bx]		; ds:si = SocketInfo
		mov	ds:[si].SI_state, ISS_CONNECTING
	;
	; store the domain and remote port
	;
		mov	ds:[si].SSI_connection.CE_domain, cx
		popdw	ds:[si].SSI_connection.CE_port
	;
	; allocate a semaphore
	;
		push	bx
		clr	bx
		call	ThreadAllocSem
		mov	ds:[si].SI_waitSem, bx
		pop	bx
	;
	; check driver type
	;
		mov	di, cx					; *ds:di = dom
		mov	di, ds:[di]
		mov	al, ds:[di].DI_driverType
		cmp	al, SDT_DATA
		push	ax
		je	data
	;
	; update the link reference count and get link handle
	;
		call	LinkIncRefCount				; ax=link hdl
		mov	ds:[si].SSI_connection.CE_link, ax
		jmp	done
data:
	;
	; store socket into ConnectionInfo
	;
		add	di, dx
		mov	ds:[di].CI_socket, bx
done:
		pop	ax					; ax = drv type
		clc
abort:
		.leave
		ret
	;
	; handle errors
	;
portError:
		call	SocketFreeQueue
error:
		popdw	bxbx		; discard SocketPort on stack
		stc
		jmp	abort
SocketRegisterConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveSocketFromPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a socket from port's chunk array

CALLED BY:	(INTERNAL) SocketClearConnection, SocketClose,
		SocketPostDataAccept, SocketPostLinkAccept, SocketDataConnect
PASS:		*ds:bx	- SocketInfo
RETURN:		ds:di	- PortInfo
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveSocketFromPort	proc	far
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
EC <		mov	si, bx						>
EC <		call	ECCheckSocketLow				>
	;
	; remove us from the port's array
	;
		mov	si, ds:[bx]
		mov	si, ds:[si].SI_port		; *ds:di = PortInfo
		mov	di, ds:[si]			; ds:di = PortInfo
		push	di
		mov	cx, ds:[di].CAH_count		; # of connected skts
		add	di, ds:[di].CAH_offset		; first socket
		mov	ax, bx				; handle to locate
		segmov	es,ds
		repne	scasw				; search array
EC <		ERROR_NE SOCKET_NOT_IN_PORT_ARRAY			>
		sub	di,2				; ds:di = elt to delete
		call	ChunkArrayDelete
done::
		pop	di				; ds:di = PortInfo
		.leave
		ret
RemoveSocketFromPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketClearConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove failed connection indication from a socket

CALLED BY:	(INTERNAL) SocketConnect
PASS:		bx	- socket
		ds	- control segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketClearConnection	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; see if we need to send a cancel message
	;
		mov	si, ds:[bx]			; ds:si = socket
		cmp	ds:[si].SI_state, ISS_CONNECTING
		jne	clear
	;
	; setup parameters for cancel
	;
		mov	cx, ds:[si].SSI_connection.CE_domain
		mov	dx, ds:[si].SSI_connection.CE_link
		call	SocketFindLinkByHandle		; dx = link offset
		sub	sp, size PacketInfo
		mov	ax, bx				; save socket
		call	SetupPacketInfo
		mov	bx, ax				; restore socket
	;
	; send the packet
	;
		call	SocketControlEndWrite
		mov	ax, CCO_CANCEL
		call	SendConnectionControl
		call	SocketControlStartWrite
		mov	si, ds:[bx]			; ds:si = SocketInfo
	;
	; remove reference to link
	;
update::
		mov	si, ds:[bx]			; ds:si = socket
		mov	cx, ds:[si].SSI_connection.CE_domain
		mov	dx, ds:[si].SSI_connection.CE_link
		call	SocketFindLinkByHandle		; dx = link offset
		call	LinkDecRefCount
	;
	; remove data queue
	;
		call	SocketFreeQueue
	;
	; clear the connection related fields
	;
clear::
		mov	ds:[si].SI_state, ISS_UNCONNECTED
		clr	ds:[si].SSI_connection.CE_domain
		clr	ds:[si].SSI_connection.CE_link
		clrdw	ds:[si].SSI_connection.CE_port
	;
	; remove socket from port's array
	;
		call	RemoveSocketFromPort
done::
		.leave
		ret
SocketClearConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCreateListenQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a listen queue chunk

CALLED BY:	(EXTERNAL) FreePortListenQueue, SocketAddLoadOnMsgMem,
		SocketListenLow
PASS:		*ds:si	- PortInfo
		cx	- size of listen queue
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCreateListenQueue	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; allocate a listen queue
	;
		mov	di, si				; *ds:di = PortInfo
		mov	bp, cx				; bp = queue length
		mov	bx, size ConnectionEndpoint	; element size
		mov	cx, size ListenQueue		; header size
		clr	si				; alloc new chunk
		clr	al				; no flags
		call	ChunkArrayCreate		; *ds:si = array
	;
	; record it in the port
	;
		mov	di, ds:[di]			; ds:di = PortInfo
		mov	ds:[di].PI_listenQueue, si
	;
	; initialize the queue
	;
		mov	si, ds:[si]			; ds:si = ListenQueue
EC <		mov	ds:[si].LQ_type, CCT_LISTEN_QUEUE
		mov	ds:[si].LQ_maxEntries, bp
		.leave
		ret
SocketCreateListenQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketListenLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a socket to a listening state

CALLED BY:	(INTERNAL) SocketListen
PASS:		ds	- control segment
		es	- dgroup
		bx	- Socket
		cx	- # of pending connections to permit
RETURN:		carry set on error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketListenLow	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; validate the socket handle
	;
		mov	si, bx			;  *ds:si = SocketInfo
EC <		call	ECCheckSocketLow				>
	;
	; check delivery type
	;
		mov	si, ds:[si]		;  ds:si = SocketInfo
EC <		cmp	ds:[si].SI_delivery, SDT_DATAGRAM		>
EC <		ERROR_E ILLEGAL_OPERATION_ON_DATAGRAM_SOCKET		>
	;
	; verify that the socket is bound
	;
EC <		tst	ds:[si].SI_port					>
EC <		ERROR_Z SOCKET_NOT_BOUND				>
	;
	; make sure the socket isn't busy
	;
checkState::
		cmp	ds:[si].SI_state, ISS_UNCONNECTED
		je	derefPort
		mov	ax, SE_SOCKET_BUSY
		stc
		jmp	done
	;
	; locate the port descriptor
	;
derefPort:
		mov	si, ds:[si].SI_port	; *ds:si = PortInfo
EC <		call	ECCheckPortLow					>
		mov	di, ds:[si]		;  ds:di = PortInfo
	;
	; check for existing listeners
	;
		tst	ds:[di].PI_listener
		jz	doListen
		mov	ax, SE_PORT_ALREADY_LISTENING
		stc
		jmp	done
	;
	; create a listen queue
	;
doListen:
		tst	ds:[di].PI_listenQueue
		jnz	queueExists
		call	SocketCreateListenQueue
		mov	ax, SE_OUT_OF_MEMORY
		jc	done
	;
	; register with the port
	;
register:
		mov	di, ds:[si]			; ds:di = PortInfo
		mov	ds:[di].PI_listener, bx
	;
	; change the socket state and turn on interrupts
	;
		mov	si, ds:[bx]
		mov	ds:[si].SI_state, ISS_LISTENING
		ornf	ds:[si].SI_flags, mask SF_INTERRUPTIBLE
	;
	; everything's ok
	;
		mov	ax, SE_NO_ERROR
		clc
done:
		.leave
		ret
	;
	; A listen queue already exists, presumably from
	; LoadOnMsg.  Put the new size into it.
	;
queueExists:
		mov	di, ds:[di].PI_listenQueue
		mov	di, ds:[di]
		mov	ds:[di].LQ_maxEntries, cx
		jmp	register
		
SocketListenLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCheckOpenState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the outcome of an open operation

CALLED BY:	(INTERNAL) SocketConnect
PASS:		*ds:bx	= SocketInfo
RETURN:		carry	= set if error
		ax	= error code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCheckOpenState	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter
		mov	si, ds:[bx]		; ds:si = SocketInfo
	;
	; test for successful connection
	;
		mov	ax, SE_NORMAL
		cmp	ds:[si].SI_state, ISS_CONNECTED
		je	success
	;
	; test for time out
	;
		mov	ax, SE_TIMED_OUT
		cmp	ds:[si].SI_state, ISS_CONNECTING
		stc
		je	done
	;
	; test for miscellaneous errors
	;
		mov	ax, ds:[si].SSI_error
		cmp	ds:[si].SI_state, ISS_ERROR
		stc
		je	done
	;
	; state is UNCONNECTED, LISTENING, ACCEPTING, or CLOSED
	;
		ERROR	UNEXPECTED_SOCKET_STATE
success:
		clc
done:
		.leave
		ret
SocketCheckOpenState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketPreAccept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate acceptance of a connection

CALLED BY:	(INTERNAL) SocketAccept
PASS:		*ds:bx	= SocketInfo
		ss:bp	= timeout info
RETURN:	if error
		carry set
		ax	= SocketError
	else
		carry clear
		bx	= new socket
		cx	= domain of connection
		dx	= link handle of connection
DESTROYED:	nothing
SIDE EFFECTS:	
	allocates a wait sem in the socket

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketPreAccept	proc	near
		uses	si,di
		origAX		local	word		push ax
		newSocket	local	lptr.SocketInfo
		domain		local	lptr.DomainInfo
		linkHan		local	word
		.enter
	;
	; verify the delivery type 
	;
		mov	di, ds:[bx]			; ds:di = SocketInfo
EC <		cmp	ds:[di].SI_delivery, SDT_DATAGRAM		>
EC <		ERROR_E ILLEGAL_OPERATION_ON_DATAGRAM_SOCKET		>
	;
	; verify that the socket is listening
	;	
		cmp	ds:[di].SI_state, ISS_LISTENING
		mov	ax, SE_SOCKET_NOT_LISTENING
		stc
		jne	done				; check result of cmp
	;
	; make sure nobody else is accepting on the socket
	;
		tst	ds:[di].SI_waitSem
		mov	ax, SE_SOCKET_BUSY		
		stc
		jnz	done				; check result of tst
	;
	; find the listen queue
	;
		mov	si, ds:[di].SI_port		; *ds:si = PortInfo
		mov	si, ds:[si]			
		mov	si, ds:[si].PI_listenQueue	; *ds:si = ListenQueue
	;
	; retrieve the first element
	;
dequeue:
		mov	di, ds:[bx]			; ds:di = SocketInfo
		test	ds:[di].SI_flags, mask SF_INTERRUPT
		jnz	gotInterrupt
		clr	ax				; first element
		call	ChunkArrayElementToPtr		; di=ConnectionEndpoint
		jnc	accept
	;
	; allocate a semaphore
	;
allocSem::
		mov	di, ds:[bx]			; ds:di = SocketInfo
EC <		tst	ds:[di].SI_waitSem				>
EC <		ERROR_NZ UNEXPECTED_SOCKET_STATE			>
		push	bx				; save socket chunk
		clr	bx				; initial count 0
		call	ThreadAllocSem			; bx = semaphore
		mov	ds:[di].SI_waitSem, bx
	;
	; wait for a connection
	;
semWait::
		mov	cx, ss:[bp]
		call	SocketControlEndWrite
		call	SocketPTimedSem
		call	SocketControlStartWrite
pastWait::
	;
	; check result of wait
	;
		pop	bx				; *ds:bx = socket
		call	SocketClearSemaphore
		jnc	dequeue
		mov	ax, SE_TIMED_OUT
done:
	;
	; Preserve AX if not returning an error.
	;
		jc	reallyDone
		mov	ax, ss:[origAX]			
reallyDone:
		.leave
		ret
	;
	; the operation was interrupted
	;
gotInterrupt:
		and	ds:[di].SI_flags, not mask SF_INTERRUPT
		mov	ax, SE_INTERRUPT
		stc
		jmp	done
	;
	; couldn't get enough memory to complete the accept
	;
queueFailed:
		mov	bx, si
		call	SocketFreeLow
createFailed:
		pop	si, bx
acceptFailed:
		mov	ax, SE_OUT_OF_MEMORY
		stc
		jmp	done
	;
	; We have a connection to accept
	;
	; *ds:bx = old socket
	; *ds:si = listen queue
	; ds:di  = ConnectionElement in queue
	;
	; Start by extending the port's array, so we can get out easily
	; if that fails.
	;
accept:
EC <		call	ECCheckConnectionEndpoint			>
		sub	di, ds:[si]			; get offset to CE
		push	si, di
		mov	si, ds:[bx]			; ds:si = SocketInfo
		mov	si, ds:[si].SI_port
		call	ChunkArrayAppend		; ds:di = new element
		pop	si, di
		jc	acceptFailed
create::
		push	si, bx
		mov	bx, ds:[bx]
		mov	al, ds:[bx].SI_delivery
		call	SocketCreateLow
		jc	createFailed
		mov	ss:[newSocket], ax
		add	di, ds:[si]			; ds:di = CE from queue
		mov	si, ax
	;
	; create a data queue for the new socket
	;
		mov	bx, si
		call	SocketAllocQueue
		jc	queueFailed
	;
	; copy ConnectionEndpoint from listen queue and pop the queue
	;
EC <		call	ECCheckConnectionEndpoint			>
		mov	si, ds:[si]			; ds:si= new SocketInfo
		add	si, offset SSI_connection	; si=ConnectionEndpoint
		mov	dx, ds:[di].CE_domain
		mov	ds:[si].CE_domain, dx
		mov	ss:[domain], dx
		mov	dx, ds:[di].CE_link		; dx=link
		mov	ds:[si].CE_link, dx
		mov	ss:[linkHan], dx
		movdw	ds:[si].CE_port, ds:[di].CE_port, cx
EC <		push	di						>
EC <		mov	di,si						>
EC <		call	ECCheckConnectionEndpoint			>
EC <		pop	di						>
		pop	si,bx				; bx=old skt, si=queue
		call	ChunkArrayDelete
		
	;
	; initialize the other fields of the new socket
	;
		mov	si, ss:[newSocket]
		mov	si, ds:[si]			; ds:si= new SocketInfo
		mov	di, ds:[bx]			; ds:di= old SocketInfo
		mov	ds:[si].SI_state, ISS_ACCEPTING
		segmov	ds:[si].SI_port, ds:[di].SI_port, cx
	;
	; allocate a semaphore for new socket
	; will be used to wait for the BEGIN packet
	;
		clr	bx
		call	ThreadAllocSem			; bx = semaphore
		mov	ds:[si].SI_waitSem, bx
	;
	; insert socket in port array slot we allocated above
	;
		mov	si, cx				; *ds:si = PortInfo
		mov	cx, CA_LAST_ELEMENT
		call	ChunkArrayElementToPtr		; ds:di = element
		segmov	ds:[di], ss:[newSocket], ax	; nptr to new socket
	;
	; update socket count in port
	;
		mov	di, ds:[si]
		inc	ds:[di].PI_numActive
	;
	; return new socket to user
	;
		mov	bx,ss:[newSocket]			; bx = socket
		mov	cx,ss:[domain]				; cx = domain
		mov	dx,ss:[linkHan]
	;
	; validate the socket one more time
	;
EC <		call	ECCheckDomainLow				>
EC <		mov	di, ds:[bx]					>
EC <		add	di, offset SSI_connection			>
EC <		call	ECCheckConnectionEndpoint			>
		clc
		jmp	done
SocketPreAccept	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketPostLinkAccept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after accepting

CALLED BY:	(INTERNAL) SocketAccept
PASS:		*ds:bx	- SocketInfo
RETURN:		carry 	- set to retry accept
		if connection established
			carry clear
			ax	- SE_NORMAL
		if the connection was canceled
			carry set
			bx	- master socket
		if we aren't connected for some other reason
			carry clear
			ax	- SocketError

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketPostLinkAccept	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; see if we connected
	;
		mov	si, ds:[bx]
		cmp	ds:[si].SI_state, ISS_CONNECTED
		je	success
	;
	; states NOT_CONNECTED, LISTENING, ACCEPTING, OPENING,
	; SEND_CLOSED, and CLOSED are all illegal here
	;
EC <		cmp	ds:[si].SI_state, ISS_ERROR			>
EC <		ERROR_NE UNEXPECTED_SOCKET_STATE			>
	;
	; we didn't get a connection, so delete the temporary socket
	;
		mov	cx, ds:[si].SSI_error		; remember error code
		call	RemoveSocketFromPort		; ds:di = PortInfo
		mov	ax, bx				; *ds:ax = socket
		call	SocketFreeLow
	;
	; if the error isn't a cancelation, abort the accept
	;
		mov	ax,cx				; ax = SocketError
		cmp	ax, SE_CONNECTION_CANCELED
		clc
		jne	done
	;
	; if it was a cancelation, tell Accept to try again
	;
		stc
		jmp	done
	;
	; we have a connection
	;
success:
		mov	ax, SE_NORMAL
		clc
done:
		.leave
		ret
SocketPostLinkAccept	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeListenQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a listen queue

CALLED BY:	(INTERNAL) SocketClose
PASS:		*ds:bx	= SocketInfo of listening socket
RETURN:		ds	= control segment (possibly moved)
DESTROYED:	nothing
SIDE EFFECTS:	sends CCO_CANCEL for all entries in queue

PSEUDO CODE/STRATEGY:
	The listen related state of the port is cleared before we start
	canceling connections.  This prevents somebody from seeing and
	being confused by the partially closed listen queue and socket.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeListenQueue	proc	near
		uses	si
		.enter
	;
	; get pointer to socket and port
	;
		mov	si, ds:[bx]
		mov	di, ds:[si].SI_port
	;
	; validate stuff
	;
EC <		cmp	ds:[si].SI_state, ISS_LISTENING			>
EC <		ERROR_NE UNEXPECTED_SOCKET_STATE			>
EC <		mov	si, ds:[di]					>
EC <		cmp	ds:[si].PI_listener, bx				>
EC <		ERROR_NE CORRUPT_PORT					>
EC <		tst	ds:[si].PI_listenQueue				>
EC <		ERROR_Z CORRUPT_PORT					>

		call	FreePortListenQueue
		.leave
		ret
FreeListenQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreePortListenQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the listen queue associated with a port, canceling
		all connections pending for it.

CALLED BY:	(EXTERNAL) ConnectionOpen, FreeListenQueue,
		SocketRemoveLoadOnMsgMem
PASS:		*ds:di	= PortInfo (write access)
RETURN:		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreePortListenQueue proc far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		Assert	writeControl, ds
	;
	; stop listening
	;
	; This will prevent anyone else from messing with the listen
	; queue while we are shutting it down. 
	;
		mov	si, di			; *ds:si <- PortInfo, for
						;  SocketCreateListenQueue...
		mov	di, ds:[si]
		clr	ds:[di].PI_listener
		clr	bx
		xchg	bx, ds:[di].PI_listenQueue
	;
	; if there is load info, create a new listen queue now
	;
		tst	ds:[di].PI_loadInfo
		jz	doEnum
		mov	cx, LOM_LISTEN_QUEUE_SIZE
		call	SocketCreateListenQueue
	;
	; enumerate the listen queue to refuse the connections
	;
doEnum:
		mov	di, ds:[si]
		movdw	axdx, ds:[di].PI_number
		mov	si, bx			; *ds:si <- listen queue
		mov	bx,cs
		mov	di,offset FreeListenQueueCallback
		call	ChunkArrayEnum
	;
	; free the listen queue
	;
		mov	ax, si
		call	LMemFree
		.leave
		ret
FreePortListenQueue endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeListenQueueCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback for FreeListenQueue
		sends CCO_REFUSE and decrements link ref count
CALLED BY:	(EXTERNAL) FreePortListenQueue via ChunkArrayEnum
PASS:		ds:di	- ConnectionEndpoint
		axdx	- source port
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	send CCO_CLOSE
	dec link count

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeListenQueueCallback	proc	far
		uses	ax,dx,bp
		.enter
	;
	; get information from ConnectionEndpoint
	;
		sub	sp, size PacketInfo
		mov	bp,sp
		movdw	ss:[bp].PI_srcPort,	axdx
		movdw	ss:[bp].PI_destPort,	ds:[di].CE_port, ax
		segmov	ss:[bp].PI_link,	ds:[di].CE_link, dx
	;
	; get information from domain
	;
		mov	bx, ds:[di].CE_domain
		mov	di, ds:[bx]
		segmov	ss:[bp].PI_driverType,  ds:[di].DI_driverType, al
		segmov	ss:[bp].PI_client,	ds:[di].DI_client,ax
		movdw	ss:[bp].PI_entry,	ds:[di].DI_entry, ax
		mov	al, ds:[di].DI_seqHeaderSize
		clr	ah
		mov	ss:[bp].PI_headerSize, ax
	;
	; check driver type
	;
		cmp	ss:[bp].PI_driverType, SDT_DATA
		je	data
	;
	; update link but don't close it yet
	;
link::
		mov	cx,bx			; cx = domain handle
		call	SocketFindLinkByHandle	; dx = link offset
		jc	abort
		call	LinkDecRefCountNoClose
	;
	; send a REFUSE packet
	;
	; this should prompt the other side to close the link
	;
		call	SocketControlEndWrite
		mov	ax, CCO_REFUSE
		call	SendConnectionControl
		call	SocketControlStartWrite
		jmp	done
	;
	; if the link is gone, clean up and exit
	;
abort:
EC <		WARNING	REDUNDENT_CLOSE					>
		add	sp, size PacketInfo
		jmp	done
	;
	; notify driver that we don't want this connection
	;
data:
		call	SocketControlEndWrite
		mov	di, DR_SOCKET_REJECT
		mov	ax, ss:[bp].PI_link
		lea	bp, ss:[bp].PI_entry
		call	{fptr}ss:[bp]
	;
	; delete connection
	;
		call	SocketControlStartWrite
		mov	ax, ss:[bp].PI_link
		add	sp, size PacketInfo
		clr	dx
		call	SocketRemoveConnection
	;
	; continue enumeration
	;
done:
		clc
		.leave		
		ret
FreeListenQueueCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFreeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a socket chunk and possibly the port chunk

CALLED BY:	(INTERNAL) SocketClose, SocketPostLinkAccept
PASS:		*ds:bx	- SocketInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFreeLow	proc	far
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; free the permanent semaphore
	;
		mov	si, ds:[bx]
		push	bx
		mov	bx, ds:[si].SI_semSem
		call	ThreadFreeSem
		pop	bx
	;
	; free data queue if needed
	;
		call	SocketFreeQueue
	;
	; remember the port
	;
savePort::
		mov	dl, ds:[si].SI_delivery
		mov	si, ds:[si].SI_port
	;
	; free the socket
	;
		mov	ax,bx
		call	LMemFree
	;
	; remove it from the socket array
	;
		push	si
		segmov	es, ds
		mov	si, offset SocketSocketArray
		mov	di, ds:[si]
		mov	cx, ds:[di].CAH_count
		add	di, ds:[di].CAH_offset
		repne	scasw
EC <		ERROR_NE SOCKET_NOT_IN_SOCKET_ARRAY			>
		dec	di
		dec	di
		call	ChunkArrayDelete
		pop	si
	;
	; unbind the socket
	;
unbind::
		tst	si
		jz	done			; jump if not bound
		mov	di, ds:[si]		; ds:di = PortInfo
		cmp	dl, SDT_DATAGRAM
		je	datagram
	;
	; decrement socket count in port
	;
		dec	ds:[di].PI_numActive
EC <		ERROR_S CORRUPT_PORT					>
		jmp	freePort
	;
	; clear PI_dgram
	;
datagram:
EC <		cmp	ds:[di].PI_dgram, ax				>
EC <		ERROR_NE CORRUPT_SOCKET					>
		clr	ds:[di].PI_dgram
freePort:
		call	SocketFreePort
done:
		.leave
		ret
SocketFreeLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketFreePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a port, if it is not in use

CALLED BY:	(EXTERNAL) SocketAddLoadOnMsgMem, SocketFreeLow,
		SocketRemoveLoadOnMsgMem
PASS:		*ds:si	- PortInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketFreePort	proc	far
		uses	ax,bx,dx,si,di
		.enter
	;
	; check counters in port
	;
		mov	di, ds:[si]		; ds:di = PortInfo
		tst	ds:[di].PI_numActive
		jnz	done			; sequenced sockets exist
		tst	ds:[di].PI_dgram
		jnz	done			; datagram socket exists
		tst	ds:[di].PI_loadInfo
		jnz	done			; LoadOnMsg exists
	;
	; find port array entry for this port
	;
		push	si
		mov	si, offset SocketPortArray
		
		movdw	axbx, ds:[di].PI_number
		mov	dx, ds:[di].PI_restriction
		call	SocketFindPort		; ds:di = PortArrayEntry
EC <		ERROR_C CORRUPT_PORT					>
		pop	ax			; *ds:ax = PortInfo
	;
	; free the PortArrayEntry and the PortInfo
	;
		call	ChunkArrayDelete
		call	LMemFree
	;
	; clean up the domain, if any
	;
		tst	dx
		jz	done
		mov	si, dx
	;
	; we no longer free domain chunks, so the bind count is
	; irrelevant, and doing a SocketRemoveDomain is dangerous
	;
if 0
		mov	di, ds:[si]
		dec	ds:[di].DI_bindCount
		jnz	done
		call	SocketRemoveDomain
endif
done:
		.leave
		ret
SocketFreePort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCheckReadySetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup to wait on sockets

CALLED BY:	(INTERNAL) SocketCheckReady
PASS:		es:di	- array of SocketCheckRequest
		es	- control segment
		cx	- number of sockets to check
		dx	- segment of control block
		bx	- semaphore
		ss:si	- address where sem handle will be written
RETURN:		carry	- set on error
		if carry set:
			ax - SocketError
			cx - socket causing error
	  	if carry clear:
			cx - socket meeting condition (0 if none)

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCheckReadySetup	proc	near
		uses	bx,dx,si,di,bp
		sem		local	hptr		push bx
		whichPtr	local	word		push si
		busy		local	word
		error		local	word
		ForceRef sem
		ForceRef whichPtr
		.enter
	;
	; note any busy or error conditions
	; see if any socket is already in desired condition
	;
		clr	ss:[busy]
		clr	ss:[error]
pass1:
		mov	si, es:[di].SCR_socket
		mov	bl, es:[di].SCR_condition
		add	di, size SocketCheckRequest
		call	SocketCheckReadyHere
		jc	ready			; socket is ready
		loop	pass1
	;
	; no socket was discovered to be ready
	; return busy or error if appropriate, otherwise on to pass 2
	;
		mov	cx,ss:[error]
		jcxz	notError
		mov	ax, SE_IMPROPER_CONDITION
		stc
		jmp	done
notError:
		mov	cx, ss:[busy]
		jcxz	notBusy
		mov	ax, SE_SOCKET_BUSY
		stc
		jmp	done
	;
	; we didn't find a ready socket, but didn't find any errors
	; either
	;
notBusy:
		clc
		jmp	done
	;
	; if we found a ready socket, return it now
	;
ready:
		mov	cx, si
		clc
done:
		.leave
		ret
SocketCheckReadySetup	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCheckReadyHere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a particular socket is ready

CALLED BY:	(INTERNAL) SocketCheckReadySetup
PASS:		ds	- control segment
		si	- socket
		bl	- SocketCondition
RETURN:
		carry	- set if socket meets condition
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	9/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCheckReadyHere	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter inherit SocketCheckReadySetup
	;
	; validate
	;
EC <		Assert	etype, bl, SocketCondition			>
EC <		call	ECCheckSocketLow				>
	;
	; setup loop
	;
		mov	di, ds:[si]			; ds:di = SocketInfo
		clr	ax
		clr	bh
		shl	bl
		jmp	cs:[jumpTable][bx]
	;
	; see if there is urgent data
	;
checkUrgent:
		cmp	ds:[di].SI_state, ISS_CONNECTED
		jne	invalidState
		tst	ds:[di].SSI_urgentSize
		jnz	socketOK
		jmp	checkExceptBusy
	;
	; see if we can wait for an exception
	;
checkException:
	;
	; see if the exception semaphore is busy
	;
checkExceptBusy:
		tst_clc	ds:[di].SI_exceptSem
		jz	exceptNotBusy
		mov	ss:[busy], si
		jmp	done
exceptNotBusy:
		segmov	ds:[di].SI_exceptSem, ss:[sem], ax
		segmov	ds:[di].SI_exceptPtr.offset, ss:[whichPtr], ax
		mov	ds:[di].SI_exceptPtr.segment, ss
		jmp	done
	;
	; see if an accept operation would block
	;
checkAccept:
		cmp	ds:[di].SI_state, ISS_LISTENING
		jne	invalidState
		mov	bx, ds:[di].SI_port
		mov	bx, ds:[bx]
		mov	bx, ds:[bx].PI_listenQueue
		mov	bx, ds:[bx]
		tst_clc	ds:[bx].CAH_count
		jz	checkBusy
		jmp	socketOK
	;
	; see if a write operation would block
	;
checkWrite:
		cmp	ds:[di].SI_state, ISS_CONNECTED
		je	socketOK
	;
	; the requested operation is not valid given the socket state
	;
invalidState:
		mov	ss:[error], si
		clc
		jmp	done
	;
	; see if a read operation would block
	;
checkRead:
		cmp	ds:[di].SI_state, ISS_CONNECTED
		jne	invalidState
		test	ds:[di].SI_flags, mask SF_RECV_ENABLE
		jz	socketOK
		test	ds:[di].SI_flags, mask SF_FAILED
		jnz	socketOK
	;
	; the read operation will block if there is no data
	;
readStateOK::
		call	SocketCheckQueue
		jc	checkBusy
	;
	; the socket meets the requested condition
	;
socketOK:
		stc
		jmp	done
	;
	; the condition is valid, but the socket does not yet meet
	; the specified condition, so see if it's busy
	;
checkBusy:
		tst_clc	ds:[di].SI_waitSem
		jz	notBusy
		mov	ss:[busy], si
		jmp	done
notBusy:
		segmov	ds:[di].SI_waitSem, ss:[sem], ax
		segmov	ds:[di].SI_waitPtr.offset, ss:[whichPtr], ax
		mov	ds:[di].SI_waitPtr.segment, ss
done:
		.leave
		ret

jumpTable	nptr \
		checkRead,
		checkWrite,
		checkAccept,
		checkException,
		checkUrgent
		
SocketCheckReadyHere	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCheckReadyCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remove semaphore from all sockets currently containing it

CALLED BY:	(INTERNAL) SocketCheckReady
PASS:		es:di	- array of SocketCheckRequest
		ax	- length of array
		bx	- semaphore
		cx	- socket to look for
RETURN:		cx	- index of socket
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	don't both looking at the SocketCondition, just check both
	semaphores

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCheckReadyCleanup	proc	near
		uses	ax,bx,dx,si,di
		.enter
	;
	; setup for loop
	;
		xchg	ax,cx
		mov	dx,-1
		jcxz	done
		push	cx,di
	;
	; compare next socket to target of search
	; remember index in dx if it matches
	;
top:
		mov	si, es:[di].SCR_socket
		cmp	ax,si
		jne	checkWait
		mov	dx,cx
	;
	; see if we need to clear wait sem
	;
checkWait:	
		mov	si, ds:[si]
		cmp	ds:[si].SI_waitSem, bx
		jne	checkExcept
		clr	ds:[si].SI_waitSem
		clrdw	ds:[si].SI_waitPtr
	;
	; see if we need to clear except sem
	;
checkExcept:
		cmp	ds:[si].SI_exceptSem, bx
		jne	next
		clr	ds:[si].SI_exceptSem
		clrdw	ds:[si].SI_exceptPtr
	;
	; go to next socket
	;
next:
		add	di, size SocketCheckRequest
		loop	top
	;
	; convert loop index to array index
	;
		pop	cx,di		; cx = original loop bound
		cmp	dx,-1		; see if dx still has original value
		je	noMatch
		sub	cx,dx		; cx = index of matching socket
	;
	; make sure we really have the match we think we have
	;
		.assert (size SocketCheckRequest eq 4)
EC <		mov	bx,cx						>
EC <		shl	bx						>
EC <		shl	bx						>
EC <		cmp	ax, es:[di][bx]					>
EC <		ERROR_NE SOCKET_NOT_IN_CHECK_ARRAY			>
done:
		.leave
		ret
	;
	; we didn't find the socket we were looking for
	; this is permissible only if we weren't really looking
	;
noMatch:
EC <		tst	ax						>
EC <		ERROR_NZ SOCKET_NOT_IN_CHECK_ARRAY			>
		mov	cx,-1
		jmp	done
		
SocketCheckReadyCleanup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketPostDataAccept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accept a connection from a data driver

CALLED BY:	(INTERNAL) SocketAccept
PASS:		bx	= socket
		cx	= domain of connection
		dx	= connection handle of connection
		ss:ax	= timeout
		ds	= control segment

RETURN:		if connection timed out:
			carry set
		if connection succeeds:
			carry clear
			ax = SE_NORMAL
		if connection failed for some other reason:
			carry clear
			ax = SocketError		

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketPostDataAccept	proc	near
		uses	bx,cx,dx,si,di,bp
		entry	local	fptr.far
		.enter
	;
	; get the driver entry point
	;
		push	ax
		mov	si, cx				; *ds:si = domain
		mov	di, ds:[si]
		movdw	ss:[entry], ds:[di].DI_entry, ax
	;
	; update the domain with the socket handle NOW so we're prepared in
	; case the driver sends us some data before we come back from calling
	; the driver.
	;
		mov	ax, dx				; ax = conn handle
		call	SocketFindLinkByHandle		; dx = offset
		add	di, dx				; ds:di = ConnectionInfo
		mov	ds:[di].CI_socket, bx
		mov	dx, ax				; dx = conn handle
	;
	; compute timeout
	;
		pop	cx
		call	SocketGetTimeout		; cx = timeout
	;
	; call the driver
	;
callDriver::
		push	bx
		call	SocketControlEndWrite
		mov	di, DR_SOCKET_ATTACH
		mov	ax, dx				; ax = conn handle
		lea	bx, ss:[entry]
		call	{fptr}ss:[bx]
		call	SocketControlStartWrite
		pop	bx				; *ds:bx = socket
		jnc	success
	;
	; we didn't get a connection, so delete the temporary socket
	;
failed::
		push	ax				; remember error
		call	RemoveSocketFromPort		; ds:di = PortInfo
		mov	ax, bx				; *ds:ax = socket
		call	LMemFree
		pop	ax
	;
	; for some errors, we simply try again
	;
		cmp	al, SDE_CONNECTION_TIMEOUT
		jne	notTimeout
		stc
		jmp	done
notTimeout:
	;
	; for everything else, abort the accept
	; (note that if operands to cmp are equal, carry will be clear)
	;
		cmp	al, SDE_CONNECTION_REFUSED
		jne	notRefused
		mov	al, SE_CONNECTION_REFUSED
		jmp	done
notRefused:
		cmp	al, SDE_INSUFFICIENT_MEMORY
		jne	notMemory
		mov	al, SE_OUT_OF_MEMORY
		jmp	done
	;
	; If it's an error we didn't know about when this code was written,
	; return the misc error code.  Otherwise, anything not listed
	; above is not supposed to be possible.
	;
notMemory:
		mov	ah,al
		cmp	al, SocketDrError
		jae	miscError			; jae=jnc
		mov	al, SE_INTERNAL_ERROR
		clc
		jmp	done
miscError:
		mov	al, SE_CONNECTION_ERROR
		jmp	done
	;
	; we have a connection, so update connection info
	;
	; bx = socket
	; si = domain
	;
success:
		mov	cx,si					; cx = domain
		mov	di, ds:[bx]				; ds:di=socket
		mov	ds:[di].SI_state, ISS_CONNECTED
		ornf	ds:[di].SI_flags, mask SF_SEND_ENABLE or mask SF_RECV_ENABLE or mask SF_INTERRUPTIBLE
		mov	dx, ds:[di].SSI_connection.CE_link	; dx = con hdl
	;
	; got a connection
	;
		mov	ax, SE_NORMAL
		clc
done:
		.leave
		ret
SocketPostDataAccept	endp

ApiCode	ends

ExtraApiCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupDatagramInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy information about a packet onto the stack

CALLED BY:	(INTERNAL) SocketSend
PASS:		*ds:bx	- SocketInfo
		es:di	- SocketAddress
		dx	- domain handle
	ON STACK
		uninitialized PacketInfo
RETURN:		PacketInfo filled in (args not popped)
		es:di	- address to use
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupDatagramInfo	proc	near	info:PacketInfo
		uses	ax,si,di
		.enter
	;
	; get information from the port
	;
		mov	si, ds:[bx]			; ds:si = SocketInfo
		mov	di, ds:[si].SI_port
		mov	di, ds:[di]			; ds:di = PortInfo
		movdw	ss:[info].PI_srcPort, ds:[di].PI_number, ax
	;
	; get information from the domain
	;
		mov	di, dx
		mov	di, ds:[di]
		segmov	ss:[info].PI_driverType,ds:[di].DI_driverType, al
		segmov	ss:[info].PI_client,	ds:[di].DI_client, ax
		movdw	ss:[info].PI_entry,	ds:[di].DI_entry, ax
		mov	al, ds:[di].DI_dgramHeaderSize
		clr	ah
		mov	ss:[info].PI_headerSize, ax
		
		.leave
		ret		; DO NOT POP ARGS
SetupDatagramInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSetSendFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the SF_SENDING flag

CALLED BY:	SocketSend
PASS:		*ds:bx	- SocketInfo
RETURN:		carry set if error
			ax	- SocketError (SE_SOCKET_BUSY)
		carry clear otherwise
			ax	- preserved	
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketSetSendFlag	proc	near
		uses	dx, si
		.enter
EC <		mov	si, bx						>
EC <		call	ECCheckSocketLow				>
EC <		call	ECEnsureSocketNotClosing			>
	;
	; check for interrupt
	;
		mov	si, ds:[bx]
		mov	dx, ds:[si].SI_flags
		and	ds:[si].SI_flags, not mask SF_SINTERRUPT
		test	dx, mask SF_SINTERRUPT
		jnz	interrupt
	;
	; check for busy
	;
		or	ds:[si].SI_flags, mask SF_SENDING
		test	dx, mask SF_SENDING
		jz	done
		mov	ax, SE_SOCKET_BUSY
		jmp	gotError
interrupt:
		mov	ax, SE_INTERRUPT
gotError:
		stc
done:
		.leave
		ret
SocketSetSendFlag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketClearSendFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the SF_SENDING flag

CALLED BY:	SocketSend
PASS:		bx	- socket
		control block unlocked
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketClearSendFlag	proc	near
		uses	ds, si
		pushf
		.enter
		call	SocketControlStartWrite
		mov	si, ds:[bx]
		and	ds:[si].SI_flags, not mask SF_SENDING
		call	SocketControlEndWrite
		.leave
		popf
		ret
SocketClearSendFlag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the domain and link a socket is using

CALLED BY:	(INTERNAL) SocketSend
PASS:		*ds:bx	- SocketInfo
RETURN:		cx	- domain
		dx	- offset to link
		carry	- set on error
		ax	- SocketError if error, preserved otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetLink	proc	near
		uses	si
		.enter
	;
	; socket must be connected
	;
		mov	si, ds:[bx]
		cmp	ds:[si].SI_state, ISS_CONNECTED
		jne	notConnected
		mov	ax, ds:[si].SI_flags
		test	ax, mask SF_FAILED
		jnz	failed
		test	ax, mask SF_SEND_ENABLE
		jz	closed
	;
	; search for the link
	;
		mov	cx, ds:[si].SSI_connection.CE_domain
		mov	dx, ds:[si].SSI_connection.CE_link
		call	SocketFindLinkByHandle
		jc	linkNotFound
done:
		.leave
		ret
notConnected:
		mov	ax, SE_SOCKET_NOT_CONNECTED
		stc
		jmp	done
failed:
		mov	ax, ds:[si].SSI_error
		stc
		jmp	done
closed:
		mov	ax, SE_CONNECTION_CLOSED
		stc
		jmp	done
linkNotFound:
		ornf	ds:[si].SI_flags, mask SF_FAILED
		mov	ax, SE_LINK_FAILED
		stc
		jmp	done
		
SocketGetLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get default address for a datagram socket

CALLED BY:	(INTERNAL) SocketSend
PASS:		*ds:bx	- SocketInfo
RETURN:		es:di	- SocketAddress (port and adress initialized)
		dx	- domain
		carry set if error
		ax	- SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetAddress	proc	near
		uses	bx,cx,si
		.enter
	;
	; verify that socket is connected
	;
EC <		mov	si,bx						>
EC <		call	ECCheckSocketLow				>
		mov	si, ds:[bx]
		cmp	ds:[si].SI_state, ISS_CONNECTED
		jne	notConnected
	;
	; get domain handle
	;
		mov	dx, ds:[si].DSI_domain
	;
	; compute size of output
	;
		mov	ax, size SocketAddress+2
		add	ax, ds:[si].DSI_addressSize
		mov	cx, ALLOC_DYNAMIC_LOCK
	;
	; allocate a block and store handle in block
	;
		call	MemAlloc
		jc	allocFailed
		mov	es,ax
		mov	es:0, bx
	;
	; initialize the address
	;
	; since the address starts at offset 2, we need to add 2 to
	; all of the SA field offsets
	;
		clrdw	es:[SA_domain+2]
		movdw	es:[SA_port+2], ds:[si].DSI_port, ax
		segmov	es:[SA_addressSize+2], ds:[si].DSI_addressSize, cx
		lea	di, es:[SA_address+2]
		add	si, offset DSI_address
EC <		call	ECCheckMovsb					>
		rep	movsb
	;
	; return pointer to address
	;
		mov	di,2
		clc
done:
		.leave
		ret
notConnected:
		mov	ax, SE_SOCKET_NOT_CONNECTED
		stc
		jmp	done
allocFailed:
		mov	ax, SE_OUT_OF_MEMORY
		stc
		jmp	done
		
SocketGetAddress	endp


ExtraApiCode	ends

InfoApiCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetDomainName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the domain name a socket is connect over

CALLED BY:	(INTERNAL) SocketGetPeerName, SocketGetSocketName
PASS:		*ds:si - SocketInfo
		es:di  - SocketAddress
RETURN:		ax	= SocketError (carry set if error)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetDomainName	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; verify that we are connected
	;
		mov	si, ds:[si]
		mov	ax, SE_SOCKET_NOT_CONNECTED
		cmp	ds:[si].SI_state, ISS_CONNECTED
		stc
		jne	done
	;
	; find the domain and check name size
	;
		mov	bx, ds:[si].SSI_connection.CE_domain
		mov	si, ds:[bx]
		mov	cx, es:[di].SA_domainSize
		jcxz	pastCopy
		dec	cx		; because DI_nameSize doesn't include
					;  null
		cmp	cx, ds:[si].DI_nameSize
		jbe	gotSize
		mov	cx, ds:[si].DI_nameSize
gotSize:
		inc	cx		; restore space for null
	;
	; copy the name
	;
		push	es,di,si
		lea	si, ds:[si].DI_name
		movdw	esdi, es:[di].SA_domain
EC <		call	ECCheckMovsb					>
		rep	movsb
		pop	es,di,si
pastCopy:
	;
	; get the size to return
	;
		mov	cx, ds:[si].DI_nameSize
		inc	cx		; include null
		mov	es:[di].SA_domainSize, cx
		clc
		mov	ax, SE_NORMAL
done:
		.leave
		ret
SocketGetDomainName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketQueryAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query a driver for either the local or remote name

CALLED BY:	(INTERNAL) SocketGetPeerName, SocketGetSocketName
PASS:		*ds:si	- SocketInfo		(locked shared)
		es:di	- SocketAddress
		ax	- SGIT_LOCAL_ADDR or SGIT_REMOTE_ADDR
RETURN:		carry set on error
		ax 	- SocketError
		ds	- control segment	(locked exclusive)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketQueryAddress	proc	near
		uses	bx,cx,dx,si,di,bp,es
		.enter
	;
	; verify that we are connected
	;
		mov	si, ds:[si]
		cmp	ds:[si].SI_state, ISS_CONNECTED
		jne	notConnected
		test	ds:[si].SI_flags, mask SF_SEND_ENABLE
		jz	closed
	;
	; find the domain and link
	;
		mov	cx, ds:[si].SSI_connection.CE_link
		mov	si, ds:[si].SSI_connection.CE_domain
		push	si				; save domain handle
		call	SocketGrabMiscLock
	;
	; get the entry point
	;
getEntry::
		push	es,di				; save address buf
		segxchg	ds,es
		mov	si, es:[si]			; es:si = DomainInfo
		pushdw	es:[si].DI_entry
		mov	bp, sp			; ss:[bp] = entry point (fptr)
	;
	; call the driver
	;
		lea	bx, ds:[di].SA_address		; ds:bx = addr buffer
		mov	dx, ds:[di].SA_addressSize	; dx = size of buffer
		mov	di, DR_SOCKET_GET_INFO
		call	SocketControlEndRead
		call	{fptr}ss:[bp]			; ax = address size
		popdw	bpbp				; pop entry point fptr
	;
	; release the misc lock
	; do not disturb the flags
	;
pastDriver::
		call	SocketControlStartWrite
		pop	es,di				; es:di = SocketAddress
		pop	si
		call	SocketReleaseMiscLock
	;
	; handle any errors from the driver call above
	;
		jnc	checkSize
		mov	ax, SE_INFO_NOT_AVAILABLE
		jmp	done
checkSize:
		xchg	es:[di].SA_addressSize, ax
		cmp	ax, es:[di].SA_addressSize
		mov	ax, SE_BUFFER_TOO_SMALL
		jc	done				; jc=jb
		mov	ax, SE_NORMAL
done:
		.leave
		ret
notConnected:
		mov	ax, SE_SOCKET_NOT_CONNECTED
		stc
		jmp	done
closed:
		mov	ax, SE_SOCKET_CLOSED
		stc
		jmp	done
SocketQueryAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketQueryMediumAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for SocketCheckMediumConnection and
		SocketGetMediumAddress

CALLED BY:	SocketCheckMediumConnection, SocketGetMediumAddress

PASS:		ds:si	= domain name (null-terminated string)
		es:di	= buffer for address, large enough to accomodate
			  the expected address.  
		cx	= size of address buffer, in bytes.
		dx:ax	= MediumAndUnit
		bx	= SocketGetInfoType

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
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketQueryMediumAddress	proc	near
domainName	local	fptr.char		push ds, si
addrBuffer	local	fptr			push es, di
addrBufferSize	local	word			push cx
mediumAndUnit	local	fptr.MediumAndUnit	push dx, ax
queryType	local	word			push bx		
domain		local	lptr
driverEntry	local	fptr.far
	uses	bx,dx,ds,si,di,ds
	.enter
	;
	; find and lock driver
	;
	push	bp
	call	SocketControlStartRead		;ds = control segment
	movdw	dxbp, domainName		;dx:bp = domain name
	call	SocketFindDomain		;bx = domain handle
	pop	bp
	jc	noConnection1			;return "no connection"

	mov	ss:[domain], bx
	mov	si, bx				;*ds:si = DomainInfo
	call	SocketGrabMiscLock
	;
	; Get driver entry point
	;
	mov	di, ds:[si]			;ds:di = DomainInfo
	movdw	ss:[driverEntry], ds:[di].DI_entry, ax
	call	SocketControlEndRead		
	;
	; query the driver
	;
	mov	di, DR_SOCKET_GET_INFO
	mov	cx, ss:[addrBufferSize]	
	movdw	dssi, ss:[addrBuffer]	
	movdw	dxbx, ss:[mediumAndUnit]
	mov	ax, ss:[queryType]
	call	ss:[driverEntry]		;cx = actual size of address
	;
	; release the driver.  Flags preserved throughout.
	;
	call	SocketControlStartWrite		;ds = control segment
	mov	si, ss:[domain]			;*ds:si = DomainInfo
	call	SocketReleaseMiscLock
	call	SocketControlEndWrite
	;
	; return answer
	;
	jc	noConnection2
	mov	ax, SE_NORMAL
exit:
	.leave
	ret

noConnection1:
	WARNING DOMAIN_NOT_FOUND
	call	SocketControlEndRead		; unlock SocketControl
		
noConnection2:
	mov	ax, SE_CONNECTION_ERROR
	jmp	exit

SocketQueryMediumAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetRemotePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get remote port number

CALLED BY:	(INTERNAL) SocketGetPeerName
PASS:		*ds:si	- SocketInfo		must be connected
		es:di	- SocketAddress
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetRemotePort	proc	near
		uses	ax,si
		.enter
		mov	si, ds:[si]
		movdw	es:[di].SA_port, ds:[si].SSI_connection.CE_port, ax
		.leave
		ret
SocketGetRemotePort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetLocalPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get port this socket is bound to

CALLED BY:	(INTERNAL) SocketGetSocketName
PASS:		*ds:si	- SocketInfo		must be bound
		es:di	- SocketAddress
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetLocalPort	proc	near
		uses	ax,si
		.enter
		mov	si, ds:[si]
		mov	si, ds:[si].SI_port
		mov	si, ds:[si]
		movdw	es:[di].SA_port, ds:[si].PI_number, ax
		.leave
		ret
SocketGetLocalPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketPassOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass an option through to the driver

CALLED BY:	(INTERNAL) SocketSetSocketOption
PASS:		ds:si	- SocketInfo
		ax,cx	- parameters to DR_SOCKET_SET_OPTION
RETURN:		ds	- socket control segment (possibly moved)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	No attempt is made to ensure that the socket will still be open
	when the request is passed to the driver.  The driver, however,
	will disregard

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketPassOption	proc	near
		uses	bx,si,di,bp
		.enter
	;
	; verify that we are connected
	;
		cmp	ds:[si].SI_state, ISS_CONNECTED
		jne	skip
	;
	; find the domain and link
	;
		mov	bx, ds:[si].SSI_connection.CE_link
		mov	si, ds:[si].SSI_connection.CE_domain
		tst	si
		jz	skip
		mov	di, ds:[si]
		cmp	ds:[di].DI_driverType, SDT_DATA
		jne	skip
		call	SocketGrabMiscLock
	;
	; get the entry point
	;
getEntry::
		pushdw	ds:[di].DI_entry
		mov	bp, sp			; ss:[bp] = entry point (fptr)
	;
	; call the driver
	;
		mov	di, DR_SOCKET_SET_OPTION
		call	SocketControlEndRead
		call	{fptr}ss:[bp]
		popdw	bpbp				; pop entry point fptr
	;
	; release the misc lock
	;
pastDriver::
		call	SocketControlStartWrite
		call	SocketReleaseMiscLock
skip:
		.leave
		ret
SocketPassOption	endp

InfoApiCode	ends
