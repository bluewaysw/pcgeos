COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Network extensions
MODULE:		Socket library
FILE:		socketError.asm

AUTHOR:		Eric Weber, May 11, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB ECCheckSocket           Verify a socket handle

    EXT ECCheckSocketLow        Validate a socket handle

    INT ECCheckPortLow          Validate a PortInfo structure

    INT ECCheckOutgoingPacket   Verify an incoming packet

    INT ECCheckIncomingPacketLow 
				Verify an incoming packet

    INT ECCheckPacketLow        Verify an incoming packet

    INT ECCheckDomainLow        Verify a domain

    INT ECCheckLinkInfo         Validate a link info

    INT ECCheckConnectionEndpoint 
				Validate a ConnectionEndpoint

    INT ECCheckMovsb            Verify the parameters for a rep movsb

    INT ECCheckControlSeg       Make sure the passed segment is for
				SocketControl which is locked the right
				way.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/11/94   	Initial revision


DESCRIPTION:
	Error checking code for the socket library
		
	$Id: socketError.asm,v 1.1 97/04/07 10:46:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


UtilCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a socket handle

CALLED BY:	(GLOBAL)
PASS:		bx - Socket
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	May cause caller to block

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckSocket	proc	far
if ERROR_CHECK
		uses	si,ds,es
		.enter
		call	SocketControlStartRead
		mov	si,bx
		call	ECCheckSocketLow
		call	SocketControlEndRead
		.leave
endif
		ret
ECCheckSocket	endp

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSocketLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate a socket handle

CALLED BY:	(EXTERNAL) ECCheckSocket, SocketRecv
PASS:		ds - control segment
		si - socket handle
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckSocketLow	proc	far
		uses	ax,bx,cx, si, di
		.enter
	;
	; validate the segments and chunk
	;
		Assert segment ds
		Assert chunk si ds
	;
	; check the type of the chunk
	;
		mov	si, ds:[si]
		cmp	ds:[si].SI_type, CCT_SOCKET_INFO
		ERROR_NE	ILLEGAL_SOCKET
	;
	; check size of the chunk
	;
		mov	ax, size SequencedSocketInfo
		cmp	ds:[si].SI_delivery, SDT_DATAGRAM
		jne	checkSize
		mov	ax, size DatagramSocketInfo
		add	ax, ds:[si].DSI_addressSize
checkSize:
		ChunkSizePtr ds, si, cx
		cmp	ax, size SocketInfo
		ERROR_L	CORRUPT_SOCKET
	;
	; check the port pointer
	;
		tst	ds:[si].SI_port
		jz	checkDomain
		mov	di, ds:[si].SI_port
		Assert chunk di, ds
		mov	di, ds:[di]
		cmp	ds:[di].PI_type, CCT_PORT_INFO
		ERROR_NE CORRUPT_SOCKET
	;
	; check the remote domain pointer
	;
checkDomain:
		cmp	ds:[si].SI_delivery, SDT_DATAGRAM
		je	done
		tst	ds:[si].SSI_connection.CE_domain
		jz	done
		Assert chunk ds:[si].SSI_connection.CE_domain, ds
done:
		.leave
		ret
ECCheckSocketLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECEnsureSocketNotClosing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure the socket state is not closing.

CALLED BY:	(INTERNAL)
PASS:		ds - control segment
		si - socket handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		If state == ISS_CLOSING then FatalError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/26/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECEnsureSocketNotClosing	proc	far
	uses	si
	.enter

	mov	si, ds:[si]			; ds:si = SocketInfo
	cmp	ds:[si].SI_state, ISS_CLOSING
	ERROR_E	CANNOT_USE_SOCKET_AFTER_CLOSED

	.leave
	ret
ECEnsureSocketNotClosing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPortLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate a PortInfo structure

CALLED BY:	(INTERNAL)
PASS:		ds - control segment
		si - port handle
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPortLow	proc	far
		uses	ax,bx,dx,si,di
		.enter
	;
	; make sure this is really a port info
	;
		call	ECCheckChunkArray
		mov	si, ds:[si]
EC <		cmp	ds:[si].PI_type, CCT_PORT_INFO			>
EC <		ERROR_NE	CORRUPT_PORT				>
	;
	; verify that we are in the port array
	;
		movdw	axbx, ds:[si].PI_number
		mov	dx, ds:[si].PI_restriction
		push	si
		call	SocketFindPort
EC <		ERROR_C PORT_NOT_IN_PORT_ARRAY				>
		pop	si
	;
	; check pointers
	;
		tst	ds:[si].PI_listener
		jz	listenerOK
		mov	di, ds:[si].PI_listener
		Assert  chunk di,ds
EC <		mov	di, ds:[di]					>
EC <		cmp	ds:[di].SI_type, CCT_SOCKET_INFO		>
EC <		ERROR_NE CORRUPT_PORT					>

listenerOK:
		tst	ds:[si].PI_listenQueue
		jz	queueOK
		mov	di, ds:[si].PI_listenQueue
		Assert  chunk di,ds
EC <		mov	di, ds:[di]					>
EC <		cmp	ds:[di].LQ_type, CCT_LISTEN_QUEUE		>
EC <		ERROR_NE CORRUPT_PORT					>
queueOK:
		tst	ds:[si].PI_dgram
		jz	dgramOK
		mov	di,  ds:[si].PI_listenQueue
		Assert  chunk di,ds
EC <		mov	di, ds:[di]					>
EC <		cmp	ds:[di].SI_type, CCT_SOCKET_INFO		>
EC <		ERROR_NE CORRUPT_PORT					>
dgramOK:
		.leave
		ret
ECCheckPortLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckOutgoingPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify an incoming packet

CALLED BY:	(INTERNAL)
PASS:		^lcx:dx	- packet
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckOutgoingPacket	proc	far
		uses	bp,ds,es
		.enter
		call	SocketControlStartRead
		mov	bp, PDD_OUTGOING
		call	ECCheckPacketLow
		call	SocketControlEndRead
		.leave
		ret
ECCheckOutgoingPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckIncomingPacketLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify an incoming packet

CALLED BY:	(INTERNAL)
PASS:		^lcx:dx	- packet
		ds	- control segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckIncomingPacketLow	proc	far
		uses	bp
		.enter
		mov	bp, PDD_INCOMING
		call	ECCheckPacketLow
		.leave
		ret
ECCheckIncomingPacketLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPacketLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify an incoming packet

CALLED BY:	(INTERNAL) ECCheckIncomingPacketLow, ECCheckOutgoingPacket
PASS:		^lcx:dx	- packet
		ds	- control segment
		bp	- PacketDeliveryDirection
RETURN:		nothing
DESTROYED:	bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPacketLow	proc	near
		pushf
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; verify the optr of the packet
	;
		Assert	handle, cx
		mov	bx, cx
		call	HugeLMemLock
if 0
	;
	; The HugeLMem heap is shared among multiple threads, making EC
	; code unreliable if it is being written to.
	;
EC <		push	ds						>
EC <		mov	ds,ax						>
EC <		call	ECLMemValidateHeap				>
EC <		pop	ds						>
endif
		mov	es,ax
		Assert	chunk, dx, es
		mov	si, dx
		mov	di, es:[si]		; es:di = PacketHeader
	;
	; verify the size of the packet
	;
verifySize::
		mov	ax, es:[di].PH_dataOffset	; ax = offset to data
		cmp	ax, size PacketHeader
		ERROR_B CORRUPT_PACKET
		add	ax, es:[di].PH_dataSize		; ax = end of data
		ChunkSizePtr	es,di,cx
		cmp	ax, cx
		ERROR_A	CORRUPT_PACKET
	;
	; verify the domain (incoming only)
	;
verifyDomain::
		cmp	bp, PDD_OUTGOING
		je	verifyFlags
		Assert	chunk, es:[di].PH_domain, ds
EC <		mov	si, es:[di].PH_domain				>
EC <		mov	si, ds:[si]					>
EC <		cmp	ds:[si].DI_type, CCT_DOMAIN_INFO		>
EC <		ERROR_NE CORRUPT_PACKET					>
	;
	; verify the flags
	;
verifyFlags::
		mov	al, es:[di].PH_flags
		and	al, mask PF_TYPE
		Assert	etype	al, PacketType
	;
	; unlock the packet
	;
unlockAndExit::
		call	HugeLMemUnlock
		.leave
		popf
		ret
ECCheckPacketLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckDomainLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a domain

CALLED BY:	(INTERNAL) ECCheckConnectionEndpoint
PASS:		*ds:cx	- domain
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckDomainLow	proc	far
		uses	bx,si,di
		pushf
		.enter
	;
	; make sure it's a chunk and chunk array
	;
		mov	si, cx
		Assert	chunk,si,ds
		Assert	ChunkArray,dssi
	;
	; check the type
	;
		mov	di, ds:[si]
EC <		cmp	ds:[di].DI_type, CCT_DOMAIN_INFO		>
EC <		ERROR_NE CORRUPT_DOMAIN					>
	;
	; check the links
	;
		cmp	ds:[di].DI_driverType, SDT_DATA
		je	done
		mov	bx,cs
		mov	di, offset ECCheckLinkInfo
		call	ChunkArrayEnum
done:
		.leave
		popf
		ret

ECCheckDomainLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckLinkInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate a link info

CALLED BY:	(INTERNAL)
PASS:		*ds:si	- DomainInfo
		ds:di	- LinkInfo
		ax	- size of LinkInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckLinkInfo	proc	far
		uses	ax
		.enter
	;
	; validate link info
	;
		tst	ds:[di].LI_handle
		WARNING_Z WARNING_NULL_CONNECTION_HANDLE		
		sub	ax, size LinkInfo				
		cmp	ax, ds:[di].LI_addrSize				
		ERROR_NE CORRUPT_DOMAIN					
		clc							
		
		.leave
		ret
ECCheckLinkInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckConnectionEndpoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate a ConnectionEndpoint

CALLED BY:	(INTERNAL)
PASS:		ds:di - ConnectionEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckConnectionEndpoint	proc	far
		uses	cx,dx,si
		pushf
		.enter
	;
	; check the domain
	;
		mov	cx, ds:[di].CE_domain
		call	ECCheckDomainLow
	;
	; check the driver type
	;
		mov	si, cx
		mov	si, ds:[si]
		cmp	ds:[si].DI_driverType, SDT_DATA
		je	done
	;
	; verify link, for link drivers only
	;
		mov	dx, ds:[di].CE_link
		call	SocketFindLinkByHandle
		ERROR_C CORRUPT_ENDPOINT
done:
		.leave
		popf
		ret
ECCheckConnectionEndpoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckMovsb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the parameters for a rep movsb

CALLED BY:	(INTERNAL)
PASS:		registers set up for rep movsb
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckMovsb	proc	far
		Assert	okForRepMovsb
		ret
ECCheckMovsb	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckControlSeg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed segment is for SocketControl which is
		locked the right way.

CALLED BY:	(INTERNAL)
PASS:		ax	= segment to check
		bx	= lock type
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 	ERROR_CHECK
ECCheckControlSeg proc	far
		pushf
		uses	ds
		.enter
	;
	; First make sure the passed segment is for SocketControl.
	;
		push	bx
		mov	bx, handle SocketControl
		call	MemDerefDS		; makes sure it's locked...
		mov	bx, ds
		cmp	ax, bx
		ERROR_NE	SEGMENT_NOT_SOCKET_CONTROL
	;
	; Now check the lock type.
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		pop	bx
		cmp	ds:[lockType], bx
		ERROR_NE	CONTROL_SEGMENT_NOT_LOCKED_RIGHT
		.leave
		popf
		ret
ECCheckControlSeg endp
endif	; ERROR_CHECK

UtilCode	ends


