COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethercomTransceive.asm

AUTHOR:		Todd Stumpf, Aug 18th, 1998

ROUTINES:

REVISION HISTORY:
    INT EtherSendData        Send a sequenced data packet
    INT EtherSendDatagram    Send a datagram

DESCRIPTION:

	Routines for transmitting and receiving ethernet packets that
	are common to all ethernet link drivers.

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MovableCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a sequenced data packet

CALLED BY:	DR_SOCKET_SEND_DATA

PASS:		dx:bp = optr of buffer to send
 		bx    = connection handle
IGNORED:	cx    = size of data in buffer
		ax    = timeout value
		si    = SocketSendMode
RETURN:		carry set if error
		ax = SocketDrError
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherSendData	proc	far
if 0	; This routine doesn't work at all and needs to be updated.
		uses	ds
		.enter
	;
	; Make sure link has been set up to our linking.
	;
		GetDGroup ds, ax
		tst	ds:[linkEstablished]
		jz	invalidLink

	;
	;  Make sure they're not bluffing us with a
	;  bad connection handle.
		cmp	bx, ETHER_CONNECTION_HANDLE
		jne	invalidConnection

	;
	;  Actually send the packet.
		EthDevSendDXBP		; AX <- SocketDrError
					; carry set on error
done:
		.leave
		ret

invalidLink:
		mov	ax, SDE_DESTINATION_UNREACHABLE
		stc
		jmp	done

invalidConnection:
		mov	ax, SDE_INVALID_CONNECTION_HANDLE
		stc
		jmp	done
endif
ERROR -1
EtherSendData	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherSendDatagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a datagram

CALLED BY:	DR_SOCKET_SEND_DATAGRAM

PASS:		WARINING: TCPIP does not pass parameters to us as described
		in socketDr.def!  Don't ask me why.  Looks like the following
		is what it really passes to us:
		dx:bp	= optr of buffer to send (PacketHeader)
		cx	= size of packet data in buffer, excluding
			  PacketHeader (padded), link header (if any), and
			  any unused bytes that follow
		bx	= client handle
		ax	= offset of packet data within buffer (after link
			  header)
		ds, si	= garbage
RETURN:		carry clear (TCPIP doesn't check CF or any error returned
		here anyway.)
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Holy christ!  It looks like TCPIP passes these things to us:

	First, the passed buffer starts with this layout:
	PacketHeader, padded to PACKET_HEADER_MAX_SIZE
	link layer header, if any (depends on particular ethernet driver)

	Then, these structures follow:
	For TCP:
		tcpiphdr (in Driver/Socket/TCPIP/tcp.h)
			ipovly (in Driver/Socket/TCPIP/ip.h)
			tcphdr (in Driver/Socket/TCPIP/tcp.h)
		TCP options, variable size
	For UDP:
		9 unused bytes (size TcpAccPntResolvedAddress, resulted
		from UdpOutput() removing the TcpAccPntResolvedAddress between
		udpiphdr and data by shifting udpiphdr forward to overwrite
		it.)
		udpiphdr (in Driver/Socket/TCPIP/udp.h)
			ipovly (in Driver/Socket/TCPIP/ip.h)
			udphdr (in Driver/Socket/TCPIP/udp.h)
		udp packet data

	ipovly overlays ip (which is IpHeader in asm).
	Most things are passed in network byte order.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/04/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherSendDatagram	proc	far
	uses	ax, bx, di, ds
	.enter

	Assert	e, bx, ETHER_CLIENT_HANDLE
	Assert	optr, dxbp
	Assert	ae, ax, <PACKET_HEADER_MAX_SIZE + LINK_HEADER_SIZE>
	Assert	ae, cx, IP_MIN_HEADER	; data must start with IpHeader

	;
	; Send a message to our thread to actually send the packet.
	;
	; For EtherODI, the LSL notifies us of sending-complete via an
	; interrupt, where we can't unlock the packet.  So we have to
	; force-queue a message to our driver thread to unlock and free the
	; packet.  Then since we can't lock and unlock HugeLMem chunks on
	; different threads, we can't lock the packet right here to send it
	; because here is the TCPIP driver thread.
	;
	; If it turns out that other Ethernet drivers work differently, we'll
	; re-arrange the common code.
	;
	GetDGroup	ds, bx
	mov	bx, ds:[etherThread]
	Assert	thread, bx
	mov	ax, MSG_EP_SEND_PACKET
	clr	di
	call	ObjMessage

	clc				; return CF clear

	.leave
	ret
EtherSendDatagram	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherAbortSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop a data delivery that is currently blocking.

CALLED BY:	DR_SOCKET_STOP_SEND_DATA

PASS:		bx = connection handle
RETURN:		carry set if error
		ax = SocketDrError
DESTROYED:	nothing

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherAbortSendData		proc	far
		.enter
	;
	;  Gosh... what can we do here?

		.leave
		ret
EtherAbortSendData		endp
	
MovableCode		ends
