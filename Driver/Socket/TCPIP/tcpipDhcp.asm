COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 2000.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		TCP/IP Driver
FILE:		tcpipDhcp.asm

AUTHOR:		Edward Di Geronimo Jr., Jun 15, 2000

ROUTINES:
	Name			Description
	----			-----------
	TcpipStartDhcp		Starts the DHCP process

	TcpipDhcpBuildPacket	Allocates packet and fills in header info

	TcpipDhcpGetHWAddr	Gets the hardware address of local machine

	TcpipBuildSockAddr	Fills in a SocketAddress struct

	TcpipDhcpCheckIfInUse	Checks if an IP address is in use

	TcpipDhcpValidateResponse
				Checks validity of incoming packet

	TcpipDhcpThreadStart	Fixed code, called on thread creation

	TcpipDhcpCopyServerID	Searches for a server id in a DHCP packet,
				and if found, copies it to another packet

	TcpipDhcpParseAndSendNotification
				Parses an incoming DHCP packet for useful
				info, send out GCN notification, and inform
				the resolver of DNS servers.

	TCPIPDHCPHANDLERENEW	Called from C method handler, handles lease
				renewal, status notifications

	TcpipDhcpBuildRenewPakcet
				Builds a packet to renew a DHCP lease

	TCPIPDHCPLEASEEXPIRED	Called from C method handler when the DHCP
				lease expires without being successfully
				renewed. Closes the link and sends
				notification via GCN.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/15/00   	Initial revision


DESCRIPTION:
	TCP/IP Dynamic Host Configuration Protocol support.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetGeosConvention

DhcpCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipStartDhcp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new thread and runs DHCP on it

CALLED BY:	TcpipLinkOpened
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/28/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipStartDhcp	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		mov	al, PRIORITY_STANDARD
		mov	di, 1000	; Guessing stack size
		mov	bp, handle 0
		mov	bx, dx
		mov	cx, vseg TcpipDoDhcp
		mov	dx, offset TcpipDoDhcp
		call	ThreadCreate

		.leave
		ret
TcpipStartDhcp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDoDhcp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begins the DHCP process

CALLED BY:	ThreadCreate
PASS:		cx	- domain handle (for LCB)
RETURN:		cx, dx clear
DESTROYED:	whatever we want
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/15/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDoDhcp		proc	far
		domainHandle	local	word	push	cx
		resolvedAddr	local	TcpAccPntResolvedAddress
		sockAddr	local	SocketAddress
		sock		local	Socket
		outboundMH	local	hptr
		recvMH		local	hptr
		recv2MH		local	hptr
		requestMH	local	hptr
		startTime	local	dword
		retries		local	word
		retries2	local	word
	; On own thread, so don't care about registers
	;		uses	ax, bx, cx, dx, di, si, ds, es
		.enter

		CheckHack <offset resolvedAddr eq (offset sockAddr + size SocketAddress)>

		clr	recvMH
		clr	requestMH

	; Create the socket
		mov	al, SDT_DATAGRAM
		call	SocketCreate
		LONG	jc	socketError
		mov	sock, bx
	; Bind the socket
		mov	cx, MANUFACTURER_ID_SOCKET_16BIT_PORT
		mov	dx, DHCP_CLIENT_PORT
		push	bp
		clr	bp
		call	SocketBind
		pop	bp
		LONG	jc	closeSocket
	; Connect the socket
		segmov	es, ss, di
		lea	di, sockAddr
		call	TcpipBuildSockAddr
		movdw	({dword}resolvedAddr.TAPRA_ipAddr), 0FFFFFFFFh	; broadcast ip
		mov	sockAddr.SA_port.SP_port, DHCP_SERVER_PORT
		push	bp
		clr	bp
		movdw	cxdx, esdi
		call	SocketConnect
		pop	bp
		mov	bx, handle Strings
		call	MemUnlock
		LONG	jc	closeSocket

	; store current thread handle
		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, ss:[0].TPD_threadHandle
		mov	es:[dhcpThread], bx

	; Allocate space for a 2 receive buffers
		mov	ax, MAX_DHCP_PACKET_SIZE
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	recvMH, bx
		mov	ax, MAX_DHCP_PACKET_SIZE
		call	MemAlloc
		mov	recv2MH, bx

	; Build the DHCP packet
		mov	ax, SIZEOF_DMT_REQUEST
		call	TcpipDhcpBuildPacket
		mov	outboundMH, bx
		add	si, offset DM_options + SIZEOF_DHCP_COOKIE
		mov	{DHCPMessageOption}ds:[si], DMO_DHCP_MESSAGE_TYPE
		inc	si
		mov	{byte}ds:[si], 1	; option length
		inc	si
		mov	{DHCPMessageType}ds:[si], DMT_DISCOVER
		inc	si
		mov	{DHCPMessageOption}ds:[si], DMO_PARAMETER_REQUEST
		inc	si
		mov	{byte}ds:[si], 6	; requesting 6 options
		inc	si
		mov	{DHCPMessageOption}ds:[si], DMO_RENEWAL_TIME
		inc	si
		mov	{DHCPMessageOption}ds:[si], DMO_REBINDING_TIME
		inc	si
		mov	{DHCPMessageOption}ds:[si], DMO_LEASE_TIME
		inc	si
		mov	{DHCPMessageOption}ds:[si], DMO_SUBNET_MASK
		inc	si
		mov	{DHCPMessageOption}ds:[si], DMO_ROUTER
		inc	si
		mov	{DHCPMessageOption}ds:[si], DMO_DNS
		inc	si
		mov	{DHCPMessageOption}ds:[si], DMO_END
EC <		call	ECCheckBounds					>

	; Store start time
		call	TimerGetCount
		movdw	startTime, bxax
		clr	retries
		
dhcpSend:
	; Send DHCP DISCOVER packet
	;		mov	cx, size DHCPMessage + 13

		mov	bx, outboundMH
		call	MemDerefDS
		clr	si
	; This level of precision is fine, as DHCP will abort before running
	; long enough to cause an overflow here.
		call	TimerGetCount
		subdw	bxax, startTime
		mov	bl, 60
		div	bl
		clr	ah
		mov	ds:[si].DM_secs, ax

		mov	cx, SIZEOF_DMT_REQUEST
		mov	bx, sock
		clr	ax
		call	SocketSend

	; Wait for a response
dhcpRecvAgain:
		mov	bx, recvMH
		call	MemDerefES
		clr	di
		mov	bx, sock
		mov	cx, MAX_DHCP_PACKET_SIZE
		clr	ax
		push	bp
		mov	bp, DHCP_QUERY_TIMEOUT_BASE
		call	SocketRecv
		pop	bp

		mov	dl, DMT_OFFER
		call	TcpipDhcpValidateResponse
		jnc	gotResponse
dhcpTryAgain:
		cmp	ax, SE_TIMED_OUT
		jne	dhcpRecvAgain
		inc	retries
		mov	dx, retries
		cmp	dx, MAX_DHCP_RETRIES
		LONG	ja	dhcpFailed
		mov	ax, 60
		call	TimerSleep
		jmp	dhcpSend

gotResponse:
		movdw	dxax, es:[0].DM_yiaddr
		call	TcpipDhcpCheckIfInUse
		jnc	ipIsGood

	; Address in use. Decline it.
		pushdw	cxbx
		push	dx
		mov	ax, SIZEOF_DMT_REQUEST
		call	TcpipDhcpBuildPacket
		mov	ax, bx
		pop	dx
		popdw	cxbx
		push	ax
		movdw	ds:[si].DM_yiaddr, dxbx
		add	si, offset DM_options + SIZEOF_DHCP_COOKIE
		mov	{DHCPMessageOption}ds:[si], DMO_DHCP_MESSAGE_TYPE
		inc	si
		mov	{byte}ds:[si], 1	; option length
		inc	si
		mov	{DHCPMessageType}ds:[si], DMT_DECLINE
		inc	si
		call	TcpipDhcpCopyServerID
		mov	{DHCPMessageOption}ds:[si], DMO_END
EC <		call	ECCheckBounds					>
		clr	si
		mov	ax, es:[0].DM_secs
		mov	ds:[si].DM_secs, ax
		
		mov	bx, sock
		clr	si
		mov	cx, SIZEOF_DMT_DECLINE
		clr	ax
		call	SocketSend
		pop	bx
		call	MemFree
		jmp	dhcpTryAgain

ipIsGood:
	; Send out a DHCP REQUEST packet to take the address offered to us.
		mov	ax, SIZEOF_DMT_REQUEST
		tst	requestMH
		jnz	alreadyAllocedRequest
		call	TcpipDhcpBuildPacket
		mov	requestMH, bx
alreadyAllocedRequest:
		movdw	ds:[si].DM_siaddr, es:[0].DM_siaddr, bx
		add	si, offset DM_options + SIZEOF_DHCP_COOKIE
		mov	{DHCPMessageOption}ds:[si], DMO_DHCP_MESSAGE_TYPE
		inc	si
		mov	{byte}ds:[si], 1	; option length
		inc	si
		mov	{DHCPMessageType}ds:[si], DMT_REQUEST
		inc	si
		mov	{DHCPMessageOption}ds:[si], DMO_REQUESTED_IP
		inc	si
		mov	{byte}ds:[si], 4	; option length
		inc	si
		movdw	ds:[si], es:[0].DM_yiaddr, ax
		add	si, 4
		mov	{DHCPMessageOption}ds:[si], DMO_END
EC <		call	ECCheckBounds					>

		clr	retries2
dhcpSendRequest:
		mov	bx, requestMH
		call	MemDerefDS
		clr	si
		mov	bx, sock
		mov	cx, SIZEOF_DMT_REQUEST
		clr	ax
		call	SocketSend

	; Wait for a response
dhcpRequestRecv:
		mov	bx, recv2MH
		call	MemDerefES
		mov	bx, sock
		mov	cx, MAX_DHCP_PACKET_SIZE
		clr	ax
		push	bp
		mov	bp, DHCP_QUERY_TIMEOUT_BASE
		call	SocketRecv
		pop	bp

		mov	dl, DMT_NAK
		call	TcpipDhcpValidateResponse
		LONG	jnc	dhcpTryAgain
		mov	dl, DMT_ACK
		clc
		call	TcpipDhcpValidateResponse
		jnc	dhcpRequestValid

		cmp	ax, SE_TIMED_OUT
		jne	dhcpRequestRecv
		inc	retries2
		cmp	retries2, MAX_DHCP_RETRIES
		ja	dhcpFailed
		mov	ax, 60
		call	TimerSleep
		jmp	dhcpSendRequest

dhcpRequestValid:
		mov	bx, recvMH
		call	MemDerefES
		clr	bx
		call	TcpipDhcpParseAndSendNotification
		jc	dhcpFailed
	; Don't do this here. Let the link driver do it in its GCN handler.
	; Needs to be this way for sync reasons.
if 0
		mov	bx, domainHandle
		call	LinkTableGetEntry
		mov	ax, ds:[di].LCB_connection
		call	MemUnlockExcl
		mov	di, SCO_LINK_OPENED
		segmov	ds, es, si
		mov	si, offset DM_yiaddr
		mov	bx, domainHandle
		mov	cx, size IPAddr
		call	TcpipLinkOpened
endif
		jmp	dhcpFinished

dhcpFailed:
	; Build notification that DHCP failed
		mov	ax, size TcpipDhcpNotificationData
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	ds, ax
		mov	ds:[0].TDND_status, TDSNT_REQUEST_FAILED
		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount

	; Record the message
		push	bp
		mov	bp, bx
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		clr	bx, si
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_TCPIP_DHCP_STATUS
		mov	di, mask MF_RECORD
		call	ObjMessage

	; Send it to the GCN list
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_TCPIP_STATUS_NOTIFICATIONS
		mov	cx, di
		mov	dx, bp
		clr	bp
		call	GCNListSend
		pop	bp
		
	; DHCP failed, so tell TCP the connection failed
		mov	bx, domainHandle
		call	LinkTableGetEntry
		mov	ax, ds:[di].LCB_connection
		call	MemUnlockExcl
		mov	dx, SDE_LINK_OPEN_FAILED
		mov	di, SCO_CONNECT_FAILED
		mov	bx, domainHandle
		call	TcpipLinkClosed
		
dhcpFinished:
	; Free buffers
		mov	bx, outboundMH
		call	MemFree
		tst	recvMH
		jz	noRecvMH
		mov	bx, recvMH
		call	MemFree
		mov	bx, recv2MH
		call	MemFree
noRecvMH:
		tst	requestMH
		jz	closeSocket
		mov	bx, requestMH
		call	MemFree

closeSocket:
	; Close socket
		mov	bx, sock
		call	SocketClose

	; Clear stored thread handle
		clr	es:[dhcpThread]

socketError:
		clr	cx, dx
		.leave
		ret
TcpipDoDhcp		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpBuildPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a memory block for a DHCP packet, and fills in
		info required for all DHCP packets.

CALLED BY:	TcpipStartDhcp
		TcpipDhcpBuildRenewPacket
PASS:		ax	- size of packet to allocate
RETURN:		bx	- MemHandle of packet
		ds:si	- DHCPMessage
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/21/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpBuildPacket	proc	far
		uses	es
		.enter

		mov	bx, handle dgroup
		call	MemDerefES
		
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc	; ax = segment, bx = handle
		push	bx
		mov	ds, ax

		clr	si
		mov	ds:[si].DM_op, BO_REQUEST
		mov	ds:[si].DM_flags.low, (mask DMF_BROADCAST shr 8)

		cmpdw	es:[dhcpCookie], 0
		jne	alreadyHaveCookie
		call	NetGenerateRandom32
		movdw	es:[dhcpCookie], dxax
alreadyHaveCookie:
		incdw	es:[dhcpCookie]
		movdw	ds:[si].DM_xid, es:[dhcpCookie], cx

	; Set up hardware medium type
		push	ds
		push	si
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	cx, ax
		mov	dx, ds:[linkMediumTypeKeyString]
		mov	si, ds:[categoryString]
		mov	ax, 1		; default to ethernet
		call	InitFileReadInteger
		pop	si
		pop	ds
		mov	ds:[si].DM_htype, al

	; Get hardware address
		call	TcpipDhcpGetHWAddr
		mov	bx, handle Strings
		call	MemUnlock

		movdw	({dword}ds:[si].DM_options), DHCP_PERMUTED_COOKIE

		pop	bx
		.leave
		ret
TcpipDhcpBuildPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpGetHWAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills in the DM_chaddr field of a DHCP packet

CALLED BY:	TcpipDhcpBuildPacket
PASS:		ds:si	- DHCPMessage
RETURN:		ds:[si].DM_chaddr filled in
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Does an ARP lookup on the loopback address (127.0.0.1).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/21/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpGetHWAddr	proc	near
	; these 2 structs must be consecutive
		mesg		local	fptr	push	ds, si
		resolvedAddr	local	TcpAccPntResolvedAddress
		sockAddr	local	SocketAddress
		uses	di, es
		.enter

		CheckHack <offset resolvedAddr eq (offset sockAddr + size SocketAddress)>

		movdw	mesg, dssi
		mov	bx, handle dgroup
		call	MemDerefDS
		pushdw	ds:[dhcpStrategy]
		segmov	es, ss, di
		lea	di, sockAddr
		call	TcpipBuildSockAddr
		movdw	({dword}resolvedAddr.TAPRA_ipAddr), 0100007Fh	; loopback ip
		mov	cx, mesg.segment
		lea	dx, ds:[si].DM_chaddr
		mov	bx, size DM_chaddr
		movdw	dssi, esdi
		mov	ax, SE_NOT_IMPLEMENTED
		mov	di, DR_SOCKET_RESOLVE_LINK_LEVEL_ADDRESS
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		cmp	ax, SE_NORMAL
		je	getAddrNoError
		clr	bx
getAddrNoError:
		movdw	dssi, mesg
		mov	ds:[si].DM_hlen, bl

		mov	bx, handle Strings
		call	MemUnlock

		.leave
		ret
TcpipDhcpGetHWAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipBuildSockAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	TcpipStartDhcp
		TcpipDhcpCheckIfInUse
		TcpipDhcpGetHWAddr
PASS:		es:di	- SocketAddress, followed by TcpAccPntResolvedAddress
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Strings resource is locked on return. SocketAddress struct
		contains pointers into it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/21/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipBuildSockAddr	proc	near
		uses	ax, bx, ds
		.enter

		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	es:[di].SA_port.SP_manuf, MANUFACTURER_ID_SOCKET_16BIT_PORT
		mov	es:[di].SA_domain.segment, ds
		mov	ax, ds:[tcpipDomainString]
		mov	es:[di].SA_domain.offset, ax
		ChunkSizeHandle	ds, tcpipDomainString, ax
		sub	ax, size TCHAR	; don't count trailing null
		mov	es:[di].SA_domainSize, ax
		mov	es:[di].SA_addressSize, size TcpAccPntResolvedAddress
		mov	({TcpAccPntResolvedAddress}es:[di].SA_address).TAPRA_linkSize, 3
		mov	({TcpAccPntResolvedAddress}es:[di].SA_address).TAPRA_linkType, LT_ID
		mov	({TcpAccPntResolvedAddress}es:[di].SA_address).TAPRA_accPntID, 1

		.leave
		ret
TcpipBuildSockAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpCheckIfInUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed IP address is in use

CALLED BY:	TcpipStartDhcp
PASS:		dxax	- ip address
RETURN:		carry set if ip in use
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Calls link driver to do an ARP lookup on the IP address.
		If the driver gets a response, IP is in use, therefore
		exit with carry set. Otherwise, exit carry clear.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/26/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpCheckIfInUse	proc	near
	; these 2 structs must be consecutive
		resolvedAddr	local	TcpAccPntResolvedAddress
		sockAddr	local	SocketAddress
		uses	ax, bx, cx, dx, si, di, ds, es
		.enter

		CheckHack <offset resolvedAddr eq (offset sockAddr + size SocketAddress)>

		mov	bx, handle dgroup
		call	MemDerefDS
		pushdw	ds:[dhcpStrategy]
		segmov	es, ss, di
		lea	di, sockAddr
		call	TcpipBuildSockAddr
		movdw	({dword}resolvedAddr.TAPRA_ipAddr), dxax
		clr	bx
		clr	cx
		clr	dx
		movdw	dssi, esdi
		mov	ax, SE_NOT_IMPLEMENTED
		mov	di, DR_SOCKET_RESOLVE_LINK_LEVEL_ADDRESS
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		mov	bx, handle Strings
		call	MemUnlock

		cmp	ax, SE_NORMAL
		clc
		jne	addrNotInUse
		stc
addrNotInUse:

		.leave
		ret
TcpipDhcpCheckIfInUse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpValidateResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the return values of SocketRecv, and the packet that
		was read for errors.

CALLED BY:	TcpipStartDhcp
PASS:		ax	- Socket Error
		dl	- DHCP message type expected
		cx	- buffer size
		es:di	- buffer
		carry	- As set by SocketRecv
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/27/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpValidateResponse	proc	near
		uses	bx, dx, ds
		.enter

		jc	validateDone
		cmp	ax, SE_NORMAL
		jne	invalid
		cmp	cx, MIN_DHCP_PACKET_SIZE
		jb	invalid
		cmp	cx, MAX_DHCP_PACKET_SIZE
		ja	invalid
		cmp	es:[0].DM_op, BO_REPLY
		jne	invalid
		cmpdw	({dword}es:[0].DM_options), DHCP_PERMUTED_COOKIE
		jne	invalid
		mov	bx, handle dgroup
		call	MemDerefDS
		cmpdw	ds:[dhcpCookie], es:[0].DM_xid, bx
		jne	invalid

	; Check for desired message type
		mov	bx, offset DM_options + SIZEOF_DHCP_COOKIE
validateLoop:
		cmp	bx, cx
		je	invalid
		cmp	{DHCPMessageOption}es:[bx], DMO_PAD
		je	skipPad
		cmp	{DHCPMessageOption}es:[bx], DMO_DHCP_MESSAGE_TYPE
		je	foundType
		cmp	{DHCPMessageOption}es:[bx], DMO_END
		je	invalid
		inc	bx
		add	bl, {byte}es:[bx]
		adc	bh, 0
		jmp	validateLoop

skipPad:
		inc	bx
		jmp	validateLoop

foundType:
		add	bx, size DHCPOptionCommon
		cmp	{DHCPMessageType}es:[bx], dl
		jne	invalid

		clc
validateDone:
		.leave
		ret

invalid:
		stc
		jmp validateDone
TcpipDhcpValidateResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpCopyServerID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks for a DHCP server id in an incoming packet, and copies
		it into an outgoing packet.

CALLED BY:	TcpipDoDhcp
PASS:		es:0	- Source DHCP packet
		ds:si	- Location in destination packet to put id
RETURN:		if server id found, si points after the server id info
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/29/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpCopyServerID	proc	near
		uses	ax, bx
		.enter

		mov	bx, offset DM_options
findIDloop:
		cmp	bx, cx
		jae	notFound
		cmp	{DHCPMessageOption}es:[bx], DMO_END
		je	notFound
		cmp	{DHCPMessageOption}es:[bx], DMO_PAD
		je	skipPadding
		cmp	{DHCPMessageOption}es:[bx], DMO_DHCP_SERVER_ID
		je	foundServerID
		inc	bx
		add	bl, {byte}es:[di]
		adc	bh, 0
		jmp	findIDloop

skipPadding:
		inc	di
		jmp	findIDloop

foundServerID:
		mov	{DHCPMessageOption}ds:[si], DMO_DHCP_SERVER_ID
		inc	si
		mov	{byte}ds:[si], IP_ADDR_SIZE
		inc	si
		add	bx, size DHCPOptionCommon
		movdw	({dword}ds:[si]), ({dword}es:[bx]), ax
		add	si, IP_ADDR_SIZE

notFound:
		.leave
		ret
TcpipDhcpCopyServerID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpParseAndSendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parses DHCP packet and sends out GCN notification of DHCP
		status.

CALLED BY:	TcpipDoDhcp
		TCPIPDHCPHANDLERENEW
PASS:		es:0	- DHCP Message
		bx	- zero if parsing initial lease, non-zero if renewal
		cx	- size of DHCP message
RETURN:		carry set if lease invalid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/30/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpParseAndSendNotification	proc	near
		parsingRenew	local	word	push	bx
		renewTime	local	dword
		rebindTime	local	dword
		expireTime	local	dword
		serverIp	local	IPAddr
		uses	ax, bx, cx, dx, si, di, ds
		.enter

		clr	ax
		clrdw	renewTime, ax
		clrdw	rebindTime, ax
		clrdw	expireTime, ax

		mov	ax, size TcpipDhcpNotificationData
		push	cx
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		pop	cx
		mov	ds, ax
		mov	ds:[0].TDND_status, TDSNT_CONFIGURATION
		tst	parsingRenew
		jz	notRenew
		mov	ds:[0].TDND_status, TDSNT_LEASE_RENEWED
notRenew:
		movdw	({dword}ds:[0].TDND_ipAddr), es:[0].DM_yiaddr, ax
		push	bx, cx, es
		push	ds
		push	offset TDND_leaseReceived
		call	TIMERGETDATEANDTIME
		pop	bx, cx, es
		
		mov	di, offset DM_options + SIZEOF_DHCP_COOKIE
		clr	dh	; Clear now so we can just set dl later
findDataLoop:
		cmp	di, cx
		LONG	jae	doneProcessing
		cmp	{byte}es:[di], DMO_END
		LONG	je	doneProcessing
		cmp	{byte}es:[di], DMO_PAD
		jne	notPadding
		inc	di
		jmp	findDataLoop
notPadding:
		tst	parsingRenew
		jnz	beginRenewalChecks
		cmp	{byte}es:[di], DMO_SUBNET_MASK
		jne	notSubnet
		add	di, size DHCPOptionCommon
		movdw	({dword}ds:[0].TDND_netmask), ({dword}es:[di]), ax
		add	di, IP_ADDR_SIZE
		jmp	findDataLoop
notSubnet:
		cmp	{byte}es:[di], DMO_ROUTER
		jne	notGateway
		inc	di
		mov	dl, es:[di]
		inc	di
		movdw	({dword}ds:[0].TDND_gateway), ({dword}es:[di]), ax
		add	di, IP_ADDR_SIZE
		jmp	findDataLoop
notGateway:
		cmp	{byte}es:[di], DMO_DNS
		jne	notDNS
		inc	di
		mov	dl, {byte}es:[di]
		inc	di
ifdef STATIC_LINK_RESOLVER
		call	ResolverAddDhcpDnsServers
else
		PrintMessage "DNS CONFIGURATION VIA DHCP NOT SUPPORTED"
endif
		movdw	({dword}ds:[0].TDND_dns1), ({dword}es:[di]), ax
		add	di, IP_ADDR_SIZE
		sub	dl, IP_ADDR_SIZE
		LONG	jz	findDataLoop
		movdw	({dword}ds:[0].TDND_dns2), ({dword}es:[di]), ax
		add	di, dx
		jmp	findDataLoop
notDNS:
beginRenewalChecks:
	; These four checks must be last, as they are the only ones we want
	; to process when handling a renewal.
		cmp	{byte}es:[di], DMO_DHCP_SERVER_ID
		jne	notServerId
		add	di, size DHCPOptionCommon
		mov     ax, ({dword}es:[di]).low
		mov     ({dword}ds:[0].TDND_dhcpServer).low, ax
		mov     serverIp.low, ax
		mov     ax, ({dword}es:[di]).high
		mov     ({dword}ds:[0].TDND_dhcpServer).high, ax
		mov     serverIp.high, ax
		add	di, IP_ADDR_SIZE
		jmp	findDataLoop
notServerId:
		cmp	{DHCPMessageOption}es:[di], DMO_RENEWAL_TIME
		jne	notRenewalTime
		add	di, size DHCPOptionCommon
	; Stored in network byte order, we have to reverse it to Intel order
		mov	ax, ({dword}es:[di]).high
		xchg	al, ah
		mov	renewTime.low, ax
		mov	ax, ({dword}es:[di]).low
		xchg	al, ah
		mov	renewTime.high, ax
		add	di, SIZEOF_DHCP_LEASE_TIME
		jmp	findDataLoop
notRenewalTime:
		cmp	{DHCPMessageOption}es:[di], DMO_REBINDING_TIME
		jne	notRebindTime
		add	di, size DHCPOptionCommon
	; Stored in network byte order, we have to reverse it to Intel order
		mov	ax, ({dword}es:[di]).high
		xchg	al, ah
		mov	rebindTime.low, ax
		mov	ax, ({dword}es:[di]).low
		xchg	al, ah
		mov	rebindTime.high, ax
		add	di, SIZEOF_DHCP_LEASE_TIME
		jmp	findDataLoop
notRebindTime:
		cmp	{DHCPMessageOption}es:[di], DMO_LEASE_TIME
		jne	notLeaseTime
		add	di, size DHCPOptionCommon
	; Stored in network byte order, we have to reverse it to Intel order
		mov	ax, ({dword}es:[di]).high
		xchg	al, ah
		mov	expireTime.low, ax
		mov	ax, ({dword}es:[di]).low
		xchg	al, ah
		mov	expireTime.high, ax
		add	di, SIZEOF_DHCP_LEASE_TIME
		jmp	findDataLoop
notLeaseTime:
		inc	di
		mov	al, es:[di]
		inc	di
		clr	ah
		add	di, ax
		jmp	findDataLoop
		
doneProcessing:
	; Test to ensure we have valid renew, rebind, and lease times.
		tstdw	expireTime
		LONG	jz	leaseInvalid
		cmpdw	rebindTime, expireTime, ax
		ja	rebindInvalid
		tstdw	rebindTime
		jnz	rebindValid
rebindInvalid:
		movdw	rebindTime, expireTime, ax
		shrdw	rebindTime
		movdw	dxax, rebindTime
		shrdw	dxax
		adddw	rebindTime, dxax
rebindValid:
		cmpdw	renewTime, rebindTime, ax
		ja	renewInvalid
		tstdw	renewTime
		jnz	renewValid
renewInvalid:
		movdw	dxax, expireTime
		shrdw	dxax
		cmpdw	rebindTime, dxax
		jae	baseOffExpire
		movdw	dxax, rebindTime
		shrdw	dxax
baseOffExpire:
		movdw	renewTime, dxax

renewValid:
		push	bx, es
	; Store the lease time
	;		PrintMessage "Testing code to force lease value"
	;		movdw	renewTime, 18*60 ; 18 min
	;		movdw	rebindTime, 18*60*2 ; 18 min later
	;		movdw	expireTime, 18*60*3 ; another 18 min later

		mov	bx, handle dgroup
		call	MemDerefES
		movdw	({dword}es:[dhcpServerIp]), serverIp, ax
		movdw	es:[dhcpRenewTime], renewTime, ax
		movdw	es:[dhcpRebindTime], rebindTime, ax
		subdw	es:[dhcpRebindTime], renewTime, ax
		movdw	es:[dhcpExpireTime], expireTime, ax
		subdw	es:[dhcpExpireTime], rebindTime, ax

		call	TcpipDhcpSetNextTimer

	; Convert the seconds into TimerDateAndTime structs
		push	ds
		push	offset TDND_leaseReceived	; start time
		push	ds
		push	offset TDND_renewTime		; end time buffer
		pushdw	renewTime			; renewal time
		call	TCPIPDHCPCONVERTTIME
		push	ds
		push	offset TDND_leaseReceived	; start time
		push	ds
		push	offset TDND_rebindTime		; end time buffer
		pushdw	rebindTime			; rebind time
		call	TCPIPDHCPCONVERTTIME
		push	ds
		push	offset TDND_leaseReceived	; start time
		push	ds
		push	offset TDND_expireTime		; end time buffer
		pushdw	expireTime			; expire time
		call	TCPIPDHCPCONVERTTIME
		pop	bx, es

		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount

	; Record message to send to GCN list
		push	bp
		mov	bp, bx
		clr	bx, si
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_TCPIP_DHCP_STATUS
		mov	di, mask MF_RECORD
		call	ObjMessage
		
	; Send to GCN list
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_TCPIP_STATUS_NOTIFICATIONS
		mov	cx, di
		mov	dx, bp
		clr	bp
		call	GCNListSend
		pop	bp

		clc

done:
		.leave
		ret

leaseInvalid:
		mov	bx, cx
		call	MemFree
		stc
		jmp	done

TcpipDhcpParseAndSendNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpHandleRenew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to renew the DHCP lease via a unicast send to the
		server that gave the lease, or via a broadcast send.
		On success, updates status and sends GCN notification. On
		failure, sets next timer.

CALLED BY:	(Timer)
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/21/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCPIPDHCPSTARTRENEW	proc	far
		uses	di, si, ds
		.enter

		mov	al, PRIORITY_STANDARD
		mov	cx, vseg TcpipDhcpHandleRenew
		mov	dx, offset TcpipDhcpHandleRenew
		mov	di, 1000	; Guessing stack size
		mov	bp, handle 0
		call	ThreadCreate

		.leave
		ret
TCPIPDHCPSTARTRENEW	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpHandleRenew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to renew the DHCP lease via a unicast send to the
		server that gave the lease, or via a broadcast send.
		On success, updates status and sends GCN notification. On
		failure, sets next timer.

CALLED BY:	ThreadCreate
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/21/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpHandleRenew	proc	far
		uses	di, si, ds
		recvMH		local	hptr	push	0
		renewPacket	local	hptr	push	0
		attempts	local	word	push	0
		sock		local	Socket	push	0
		phase		local	word	push	DRP_RENEW
		resolvedAddr	local	TcpAccPntResolvedAddress
		sockAddr	local	SocketAddress
		.enter

		CheckHack <offset resolvedAddr eq (offset sockAddr + size SocketAddress)>

		mov	bx, handle dgroup
		call	MemDerefES

		clr	es:[dhcpTimerId]
		clr	es:[dhcpTimerHandle]

		tstdw	es:[dhcpRebindTime]
		jnz	gotPhase
		inc	phase
		tstdw	es:[dhcpExpireTime]
		jnz	gotPhase
		inc	phase
gotPhase:
		call	TcpipDhcpSetNextTimer

	; Allocate a receive buffer
		mov	ax, MAX_DHCP_PACKET_SIZE
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		LONG	jc	error
		mov	recvMH, bx

	; Create a socket
		mov	al, SDT_DATAGRAM
		call	SocketCreate
		LONG	jc	error
		mov	sock, bx
	; Bind the socket
		mov	cx, MANUFACTURER_ID_SOCKET_16BIT_PORT
		mov	dx, DHCP_CLIENT_PORT
		push	bp
		clr	bp
		call	SocketBind
		pop	bp
		LONG	jc	error
	; Connect the socket
		segmov	es, ss, di
		lea	di, sockAddr
		call	TcpipBuildSockAddr
		movdw	dxax, 0FFFFFFFFh	; broadcast ip
		cmp	phase, DRP_RENEW
		jne	doBroadcast
		tstdw	es:[dhcpServerIp]
		jz	doBroadcast
		movdw	dxax, es:[dhcpServerIp]
doBroadcast:
		movdw	({dword}resolvedAddr.TAPRA_ipAddr), dxax
		mov	sockAddr.SA_port.SP_port, DHCP_SERVER_PORT
		push	bp
		clr	bp
		movdw	cxdx, esdi
		call	SocketConnect
		pop	bp
		mov	bx, handle Strings
		call	MemUnlock
		jc	error
		call	TcpipDhcpBuildRenewPacket
		mov	renewPacket, bx

sendAgain:
		inc	attempts
		cmp	attempts, MAX_DHCP_RETRIES
		ja	error

		mov	cx, SIZEOF_DMT_RENEWAL
		clr	ax
		mov	bx, sock
		call	SocketSend

		push	bp
		mov	bx, recvMH
		call	MemDerefES
		clr	di
		mov	bx, sock
		mov	cx, MAX_DHCP_PACKET_SIZE
		mov	bp, DHCP_QUERY_TIMEOUT_BASE
		clr	ax
		call	SocketRecv
		pop	bp

		mov	dl, DMT_ACK
		call	TcpipDhcpValidateResponse
		jnc	gotResponse
		mov	dl, DMT_NAK
		call	TcpipDhcpValidateResponse
		jc	sendAgain

		call	TcpipDhcpLeaseExpired
		jmp	cleanup

gotResponse:
		mov	bx, 0FFFFh
		call	TcpipDhcpParseAndSendNotification
		jc	sendAgain
		jmp	cleanup

error:
		cmp	phase, DRP_EXPIRE
		jne	cleanup
		call	TcpipDhcpLeaseExpired

cleanup:
	; Cleanup time
		tst	renewPacket
		jz	freeRecvBuf
		mov	bx, renewPacket
		call	MemFree
freeRecvBuf:
		tst	recvMH
		jz	closeSocket
		mov	bx, recvMH
		call	MemFree
closeSocket:
		tst	sock
		jz	done
		mov	bx, sock
		call	SocketClose
done:
		clr	cx, dx
		.leave
		ret
TcpipDhcpHandleRenew	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpBuildRenewPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds a packet for renewing the DHCP lease. Can be used
		both for renew and rebind phases.

CALLED BY:	TcpipDhcpHandleRenew
PASS:		nothing
RETURN:		ds:si	- Renew packet (size = SIZEOF_DMT_RENEWAL)
DESTROYED:	ax, bx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/21/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpBuildRenewPacket	proc	near
		.enter

		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry
		pushdw	ds:[di].LCB_localAddr
		call	MemUnlockExcl
		mov	ax, SIZEOF_DMT_RENEWAL
		call	TcpipDhcpBuildPacket
		popdw	ds:[si].DM_ciaddr
		movdw	ds:[si].DM_yiaddr, ds:[si].DM_ciaddr, ax
		push	si
		add	si, offset DM_options + SIZEOF_DHCP_COOKIE
		mov	{DHCPMessageOption}ds:[si], DMO_DHCP_MESSAGE_TYPE
		inc	si
		mov	{byte}ds:[si], 1	; option length
		inc	si
		mov	{DHCPMessageType}ds:[si], DMT_REQUEST
		inc	si
		mov	{DHCPMessageType}ds:[si], DMO_END
		pop	si
		.leave
		ret
TcpipDhcpBuildRenewPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpLeaseExpired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the link and sends out GCN notification

CALLED BY:	TcpipDhcpHandleRenew
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything but bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/25/00    	Initial version
	ed	10/29/00	Changed from timer routine to timer event

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpLeaseExpired	proc	far
		uses	bp
		.enter

		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry
		pushdw	ds:[di].LCB_localAddr
		call	MemUnlockExcl
	; Build notification that DHCP lease expired
		mov	ax, size TcpipDhcpNotificationData
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	ds, ax
		mov	ds:[0].TDND_status, TDSNT_LEASE_EXPIRED
		popdw	({dword}ds:[0].TDND_ipAddr)
		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount

	; Record the message
		mov	bp, bx
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		clr	bx, si
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_TCPIP_DHCP_STATUS
		mov	di, mask MF_RECORD
		call	ObjMessage

	; Send it to the GCN list
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_TCPIP_STATUS_NOTIFICATIONS
		mov	cx, di
		mov	dx, bp
		clr	bp
		call	GCNListSend

	; Tell the resolver to clear its DNS entries
		call	ResolverRemoveDhcpDnsServers

	; DHCP failed, so tell TCP the connection failed
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry
		mov	ax, ds:[di].LCB_connection
		call	MemUnlockExcl
		mov	dx, SDE_LINK_OPEN_FAILED
		mov	di, SCO_CONNECT_FAILED
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	TcpipLinkClosed

		.leave
		ret
TcpipDhcpLeaseExpired	endp

DhcpCode	ends

ResidentCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCPIPDHCPTIMERHANDLER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up & handles DHCP timer events

CALLED BY:	TcpipDhcpParseAndSendNotification
		System timer
PASS:		ax	- TimerType
		cx:dx	- TimerGetCount's tick count
		bp	- timer ID/interval
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Check if there is at least 15 min remaining until its time
		for the next DHCP event. If so, decrement remaining time
		by 15 min and set another timer. If we have work to do,
		spawn another thread to do it. This code has to stay small
		as its in a fixed block, and has to be quick since it's
		being called from a system thread. It's in a fixed block
		since we're calling it regularly and don't want to be loading
		in code resources at awkward times because of it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/25/00    	Initial version
	ed	10/29/00	Changed from timer routine to timer event
	ed	1/29/00		Rewritten

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
TCPIPDHCPTIMERHANDLER	proc	far
		uses	di, si, bp
		.enter

		mov	bx, handle dgroup
		call	MemDerefES
		clr	ax
		tstdw	es:[dhcpRenewTime]
		jz	checkRebindTime
		cmpdw	es:[dhcpRenewTime], DHCP_TIMER_FREQUENCY_SECS
		jbe	setRenewTimer
		subdw	es:[dhcpRenewTime], DHCP_TIMER_FREQUENCY_SECS
		jmp	done

checkRebindTime:
		tstdw	es:[dhcpRebindTime]
		jz	checkExpireTime
		cmpdw	es:[dhcpRebindTime], DHCP_TIMER_FREQUENCY_SECS
		jbe	setRebindTimer
		subdw	es:[dhcpRebindTime], DHCP_TIMER_FREQUENCY_SECS
		jmp	done

checkExpireTime:
	; We should never hit this timer if Expire Time is 0.
EC <		tstdw	es:[dhcpExpireTime]				>
EC <		ERROR_Z TCPIP_INTERNAL_ERROR				>
		cmpdw	es:[dhcpExpireTime], <DHCP_TIMER_FREQUENCY_SECS + DHCP_LEASE_PANIC_TIME_SECS>
		jbe	setPanicTimer
		subdw	es:[dhcpExpireTime], DHCP_TIMER_FREQUENCY_SECS
		jmp	done

setRenewTimer:
	; We're here if <= 15 min remaining, which fits into one word,
	; so we know the high word of the dword is clear.
		xchg	ax, es:[dhcpRenewTime].low
		mov	cx, DRP_RENEW
		jmp	startTimer
setRebindTimer:
	; We're here if <= 15 min remaining, which fits into one word,
	; so we know the high word of the dword is clear.
		xchg	ax, es:[dhcpRebindTime].low
		mov	cx, DRP_REBIND
		jmp	startTimer
setPanicTimer:
	; We're here if <= 17 min remaining, which fits into one word,
	; so we know the high word of the dword is clear. However, we want
	; the timer to go off 2 min before our time runs out, so we have time
	; to do a last hope renewal attempt. We're guarenteed to have at
	; least 2 min remaining when we reach here.
		xchg	ax, es:[dhcpExpireTime].low
		sub	ax, DHCP_LEASE_PANIC_TIME_SECS
		mov	cx, DRP_PANIC
startTimer:
		mov	bx, 60	; ticks/sec
		mul	bx
	; dx should be zero, as multiply should be <= 54000 (15*60*60)
EC <		tst	dx						>
EC <		ERROR_NZ TCPIP_INTERNAL_ERROR				>
		mov_tr	si, cx
		mov_tr	cx, ax
		mov	al, TIMER_EVENT_ONE_SHOT
		clr	di
	;		mov	bx, segment ResidentCode
	;		mov	si, offset TcpipDhcpHandleRenew
		mov	bx, es:[driverThread]
		mov	dx, MSG_TCPIP_DHCP_RENEW_NOW_ASM
		mov	bp, handle 0
		call	TimerStartSetOwner
		push	ax
		push	bx
		mov	bx, es:[dhcpTimerHandle]
		mov	ax, es:[dhcpTimerId]
		call	TimerStop
		pop	es:[dhcpTimerHandle]
		pop	es:[dhcpTimerId]
		
done:
		.leave
		ret
TCPIPDHCPTIMERHANDLER	endp
endif

TCPIPDHCPTIMERHANDLER	proc	far
		uses	di, si
		.enter

		mov	bx, handle dgroup
		call	MemDerefES

		tstdw	es:[dhcpRenewTime]
		jz	checkRebind
		cmpdw	es:[dhcpRenewTime], DHCP_TIMER_FREQUENCY_SECS
		jbe	setTimer
		subdw	es:[dhcpRenewTime], DHCP_TIMER_FREQUENCY_SECS, bx
		jmp	done

checkRebind:
		tstdw	es:[dhcpRebindTime]
		jz	checkExpire
		cmpdw	es:[dhcpRebindTime], DHCP_TIMER_FREQUENCY_SECS
		jbe	setTimer
		subdw	es:[dhcpRebindTime], DHCP_TIMER_FREQUENCY_SECS, bx
		jmp	done

checkExpire:
EC <		tstdw	es:[dhcpExpireTime]				>
EC <		ERROR_Z TCPIP_INTERNAL_ERROR				>
		cmpdw	es:[dhcpExpireTime], DHCP_TIMER_FREQUENCY_SECS
		jbe	setTimer
		subdw	es:[dhcpExpireTime], DHCP_TIMER_FREQUENCY_SECS, bx
		jmp	done		

setTimer:
		call	TcpipDhcpSetNextTimer
done:
		.leave
		ret
TCPIPDHCPTIMERHANDLER	endp

ResidentCode	ends

DhcpCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDhcpSetNextTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the next timer for DHCP

CALLED BY:	
PASS:		es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Looks at the remaining time, and decides how to set the
		next timer, and what message to use.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	1/29/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDhcpSetNextTimer	proc	far
		uses	bp
		.enter

		clr	ax, bx
		xchg	bx, es:[dhcpTimerHandle]
		xchg	ax, es:[dhcpTimerId]
		tst	bx
		jz	noTimer
		call	TimerStop
noTimer:

		mov	ax, DHCP_TIMER_FREQUENCY_SECS
		mov	di, MSG_TCPIP_DHCP_RENEW_TIMER_ASM
		mov	si, TIMER_EVENT_CONTINUAL
		tstdw	es:[dhcpRenewTime]
		jz	checkRebindTime
		cmpdw	es:[dhcpRenewTime], DHCP_TIMER_FREQUENCY_SECS, bx
		jbe	renewTime
		subdw	es:[dhcpRenewTime], DHCP_TIMER_FREQUENCY_SECS, bx
		jmp	gotTime

renewTime:
		clr	ax
		xchg	ax, es:[dhcpRenewTime].low
		mov	di, MSG_TCPIP_DHCP_RENEW_NOW_ASM
		mov	si, TIMER_EVENT_ONE_SHOT
		jmp	gotTime

checkRebindTime:
		tstdw	es:[dhcpRebindTime]
		jz	checkExpireTime
		cmpdw	es:[dhcpRebindTime], DHCP_TIMER_FREQUENCY_SECS, bx
		jbe	rebindTime
		subdw	es:[dhcpRebindTime], DHCP_TIMER_FREQUENCY_SECS, bx
		jmp	gotTime

rebindTime:
		clr	ax
		xchg	ax, es:[dhcpRebindTime].low
		mov	di, MSG_TCPIP_DHCP_RENEW_NOW_ASM
		mov	si, TIMER_EVENT_ONE_SHOT
		jmp	gotTime

checkExpireTime:
		tstdw	es:[dhcpExpireTime]
		jz	done
		cmpdw	es:[dhcpExpireTime], DHCP_TIMER_FREQUENCY_SECS, bx
		jbe	expireTime
		subdw	es:[dhcpRebindTime], DHCP_TIMER_FREQUENCY_SECS, bx
		jmp	gotTime

expireTime:
		clr	ax
		xchg	ax, es:[dhcpExpireTime].low
		mov	di, MSG_TCPIP_DHCP_RENEW_NOW_ASM
		mov	si, TIMER_EVENT_ONE_SHOT
gotTime:
		mov	cx, 60
		mul	cx
	; Timer value can't be more than 16 bit number of ticks
EC <		tst	dx						>
EC <		ERROR_NZ TCPIP_INTERNAL_ERROR				>
		mov_tr	cx, ax
		mov_tr	dx, di
		mov	di, cx
		mov_tr	ax, si
		mov	bp, handle 0
		mov	bx, es:[driverThread]
		call	TimerStartSetOwner
		mov_tr	es:[dhcpTimerHandle], bx
		mov_tr	es:[dhcpTimerId], ax

done:
		.leave
		ret
TcpipDhcpSetNextTimer	endp

DhcpCode	ends

SetDefaultConvention
