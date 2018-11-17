COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethercomClient.asm

AUTHOR:		Todd Stumpf, July 8th, 1998

ROUTINES:

REVISION HISTORY:
    INT EtherClientAlloc     Allocate a new client
    INT EtherRegister        Registers a client
    INT EtherUnregister      Unregister a client

DESCRIPTION:

	Routines dealing with registering and unregistering a
	client that are common to all ethernet link drivers

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MovableCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherClientRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers the a client with this driver (usually Socket lib)

CALLED BY:	DR_SOCKET_REGISTER

PASS:		bx    -> domain handle of the driver
 		ds:si -> domain name (null terminated)
         	dx:bp -> socketLib entry point for SCO functions (virtual fptr)
		cl    -> SocketDriverType
RETURN:		carry set if error
 		ax    <- SocketDrError (SDE_ALREADY_REGISTERED | SDE_MEDIUM_BUSY)
		bx    <- client handle
		ch    <- min header size for outgoing sequenced packets
		cl    <- min header size for outgoing datagram packets
				(min header sizes include space for
					Sequenced/DatagramPacketHeaders)
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherClientRegister	proc	far
		uses	dx, si, di, bp, ds, es
		.enter

	;
	;  First things first, if they don't want a link
	;  driver, we don't want to talk to them...
		cmp	cl, SDT_LINK
		jne	wrongType

	;
	; Record passed SocketLibrary information
	;
		movdw	esdi, dssi		; es:di = domain name
		GetDGroup ds, ax
		mov	ds:[clientStrategy].offset, bp
		mov	ds:[clientStrategy].segment, dx	; store segmant last,
							;  for sync purpose.
		Assert	e, ds:[clientDomainHandle], 0
		mov	ds:[clientDomainHandle], bx

	;
	; Create driver thread.
	;
		call	ImInfoInputProcess	; bx = input process
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER
		mov	cx, segment EtherProcessClass
		mov	dx, offset EtherProcessClass
		mov	bp, ETHER_THREAD_STACK_SIZE
		mov	si, handle 0		; we own the thread
		mov	di, mask MF_CALL
		call	ObjMessage		; ax = new thread, CF
		jc	outOfMem
		mov	ds:[etherThread], ax
	; ed - let's try increasing the thread priority to see performance
		mov	bx, ax
		mov	al, PRIORITY_HIGH
		mov	ah, mask TMF_BASE_PRIO
		call	ThreadModify

	;
	; Return ethernet parameters...
	;
		mov	bx, ETHER_CLIENT_HANDLE
		mov	ch, size SequencedPacketHeader + LINK_HEADER_SIZE
		mov	cl, size DatagramPacketHeader + LINK_HEADER_SIZE
		clr	ax			; clears carry

done:
		.leave
		ret

wrongType:
		mov	ax, SDE_UNSUPPORTED_FUNCTION
		stc
		jmp	done

outOfMem:
		mov	ax, SDE_INSUFFICIENT_MEMORY
		jmp	done

EtherClientRegister	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherClientUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister the socket library

CALLED BY:	DR_SOCKET_UNREGISTER

PASS:		bx = client handle
RETURN:		bx = domain handle
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/ 8/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherClientUnregister	proc	far
		uses	ax, dx, di, bp, ds
		.enter

	;
	; Tell driver thread to exit.
	;
		GetDGroup	ds, bx
		clr	bx
		xchg	bx, ds:[etherThread]
		Assert	thread, bx
		mov	ax, MSG_META_DETACH
		clr	dx, bp, di	; no ack, send msg
		call	ObjMessage

		mov	bx, ds:[clientDomainHandle]

		.leave
		ret
EtherClientUnregister	endp

MovableCode			ends
