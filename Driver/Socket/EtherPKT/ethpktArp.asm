COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Edward Di Geronimo Jr.  All rights reserved.

PROJECT:	Native ethernet support
MODULE:		Ethernet packet driver
FILE:		ethodiArp.asm

AUTHOR:		Edward Di Geronimo Jr.

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	04/29/02	Initial revision


DESCRIPTION:
		
	ARP

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktArpInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init the ARP module

CALLED BY:	EthDevInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Upon driver exit, we don't bother freeing the ARP table block and
	let the kernel automatically free it.  Saves a few bytes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	04/29/02	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktArpInit	proc	near
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter

	;
	; Get local Ethernet address from MLID.
	;
	GetDGroup	es, ax
	mov	di, offset localEtherAddr
	mov	ah, PDF_GET_ADDRESS	
	mov	bx, ds:[pktArpHandle]
	mov	cx, size NodeAddr
	call	callPacketDriver
EC <	ERROR_C	ERROR_GETTING_MAC_ADDRESS				>

	;
	; Create ARP table.
	;
		CheckHack <LMEM_TYPE_GENERAL eq 0>
	clr	ax, cx			; ax = LMEM_TYPE_GENERAL, cx = default
					;  header
	call	MemAllocLMem		; bx = LMem block
	mov	ax, mask HF_SHARABLE or (0 shl 8)	; set HF_SHARABLE
	call	MemModifyFlags
	mov	ax, handle 0		; driver own the block.
	call	HandleModifyOwner

	call	MemLock			; ax = sptr
	mov	ds, ax
	mov_tr	ax, bx			; ^hax = block
	mov	bx, size IpEtherArpEntry
	czr	cx, si			; cx still 0 (default header), si =
					;  alloc lptr
	call	ChunkArrayCreate	; *ds:si = array

	;
	; We can handle out-of-memory error when adding array entries, but we
	; couldn't handle it when creating the array itself.
	;
	BitSet	ds:[LMBH_flags], LMF_RETURN_ERRORS

	mov_tr	bx, ax			; ^lbx:si = array
	call	MemUnlock
	movdw	es:[arpTable], bxsi

	.leave
	ret
EthPktArpInit	endp

InitCode	ends

MovableCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktArpAddCompleteEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an complete entry in the ARP table, or replace an
		existing incomplete/complete entry.

CALLED BY:	(INTERNAL)
PASS:		dxax	= IPAddr of destination, in network byte order
		bx:si	= NodeAddr of remote machine handling this destination
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	All pending packets for this destination are transmitted

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	04/29/02	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktArpAddCompleteEntry	proc	near
	uses	ax, bx, cx ,dx, si, di, bp, ds, es
	.enter

	Assert	fptr, bxsi
	pushdw	bxsi			; save NodeAddr fptr

	;
	; See if an entry for this IP address exists.
	;
	mov_tr	cx, ax			; dxcx = IPAddr
	GetDGroup	ds, bx
	movdw	bxsi, ds:[arpTable]
	call	MemLock
	mov	ds, ax			; *ds:si = ARP table array
	mov	bx, SEGMENT_CS
	mov	di, offset EthPktArpCompareIp	; bx:di = callback
	call	ChunkArrayEnum		; CF if found, ds:ax = IpEtherArpEntry
	mov_tr	di, ax			; ds:di = IpEtherArpEntry if found
	jc	fillEntry

	;
	; Allocate new entry and store IP address.
	;
	call	ChunkArrayAppend	; ds:di = IpEtherArpEntry, all zeroed
	Assert	carryClear		;;; don't handler error for now
	movdw	ds:[di].IEAE_ipAddr, dxcx

fillEntry:
	;
	; Store Ethernet address.
	;
	segmov	es, ds			; es:di = IpEtherArpEntry
	popdw	dssi			; ds:si = NodeAddr to add
	push	di			; save IpEtherArpEntry nptr
	add	di, offset IEAE_addrOrTs.IAOT_etherAddr
					; es:di = IAOT_etherAddr
		CheckHack <(NODE_ADDR_SIZE and 1) eq 0>
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw
	pop	di
	segmov	ds, es			; ds:di = IpEtherArpEntry

	;
	; Set complete flag and get list of pending packets.
	;
EC <	test	ds:[di].IEAE_flags, mask AEF_COMPLETE			>
EC <	jz	10$							>
EC <	Assert	e, ds:[di].IEAE_packets.handle, NULL			>
EC <10$:								>
	BitSet	ds:[di].IEAE_flags, AEF_COMPLETE
	clr	ax			; ax = null handle
	xchg	ax, ds:[di].IEAE_packets.handle
	mov	si, ds:[di].IEAE_packets.chunk	; ^lax:si = pending packet

	;
	; Unlock ARP table.
	;
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	mov_tr	bx, ax			; ^lbx:si = pending packets if any
	GetDGroup	es, ax
	jmp	nextPacket

sendPacket:
	Assert	optr, bxsi

	;
	; Save the next packet down the list.
	;
	call	HugeLMemLock
	mov	ds, ax			; *ds:si = packet
	mov	di, ds:[si]
	pushdw	<ds:[di + PACKET_HEADER_MAX_SIZE].IPH_next>
	call	HugeLMemUnlock

	;
	; Send this packet.
	;
	movdw	dxbp, bxsi		; ^ldx:bp = packet
	mov	bx, es:[etherThread]
	Assert	thread, bx
	mov	ax, MSG_EP_SEND_PACKET
	clr	di
	call	ObjMessage

	;
	; Loop to next packet
	;
	popdw	bxsi			; ^lbx:si = next packet
nextPacket:
	tst	bx
	jnz	sendPacket

	.leave
	ret
EthPktArpAddCompleteEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktArpCompareIp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if passed IP address matches an existing entry.

CALLED BY:	(INTERNAL), via ChunkArrayEnum
PASS:		ds:di	= IpEtherArpEntry
		dxcx	= IPAddr, in network byte order
RETURN:		carry set if match
			ds:ax	= passed IpEtherArpEntry that match
		carry clear if not match
			ax unchanged
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed   	04/29/02    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktArpCompareIp	proc	far
	.enter

	cmpdw	dxcx, ds:[di].IEAE_ipAddr
	clc
	jne	done
	mov_tr	ax, di			; ds:ax = IpEtherArpEntry
	stc

done:
	.leave
	ret
EthPktArpCompareIp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktArpIpToEther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look up the ethernet address for the passed IP address.

CALLED BY:	EthODITransmitPacket
PASS:		dxax	= IPAddr to look up, in network byte order
		cx	= -1 if sending a packet, 0 if just doing lookup
		es:di	= NodeAddr buffer to fill in
		(rest of parameters only needed if cx = -1)
		^lbx:bp	= packet buffer (PacketHeader) beint sent to this addr
		*ds:bp	= ^lbx:bp
RETURN:		CF clear if address found
			NodeAddr buffer filled in
		CF set if not found
DESTROYED:	ax, dx
SIDE EFFECTS:	If Ethernet address is not found, packet is added to pending
		packet list for this IP address and will be sent later.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	04/29/02	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktArpIpToEther	proc	near
packetLptr		local	lptr	push	bp
packetHptr		local	hptr	push	bx
packetSptr		local	sptr	push	ds
etherAddrBufOffset	local	nptr	push	di
sendingPacket		local	word	push	cx
	uses	bx, cx, si, di, ds
	.enter

	Assert	buffer, esdi, NODE_ADDR_SIZE

	; Check if looking ourselves up
	push	cx
	mov	cx, dgroup
	mov	ds, cx
	pop	cx
	cmpdw	dxax, ds:[localIpAddr]
	je	returnLocalAddr
	cmpdw	dxax, 0100007Fh		; 127.0.0.1, gotta reverse the bytes
	je	returnLocalAddr

	; Check if it's a broadcast packet or not
	call	CheckForBroadcastAddress
	jc	broadcastPacket

	; See if we're on the same subnet as the destination or not
	call	CompareIpToLocalSubnet
	jnc	onSameSubnet

	; Test if we're actually sending a packet or just doing an arp lookup.
	; If just doing a lookup; we're done as it only works for the same
	; subnet. Otherwise, change the ip we're interested in to be the
	; gateway address.

	tst	cx
	stc
	jz	exitLookup

	; Actually sending a packet. Change the ip address we care about.
	movdw	dxax, ds:[gatewayAddr]
onSameSubnet:
	call	EthPktArpIpTableLookup
	push	bx
	jnc	notFound

	;
	; Found.  See if it is a complete entry.
	;
	mov_tr	di, ax			; ds:di = IpEtherArpEntry
	test	ds:[di].IEAE_flags, mask AEF_COMPLETE	; clears CF
	jz	incomplete		; => not complete, can't use

	;
	; Reset last-ref time.  Copy Ethernet address to buffer.
	;
	mov	ds:[di].IEAE_lastRef, 0
	lea	si, ds:[di].IEAE_addrOrTs.IAOT_etherAddr
					; ds:si = IAOT_etherAddr
	mov	di, ss:[etherAddrBufOffset]	; es:di = passed buffer
		CheckHack <(NODE_ADDR_SIZE and 1) eq 0>
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw
	Assert	carryClear		; hack

unlockTable:
	pop	bx			; bx = array hptr
	call	MemUnlock		; flags preserved

exitLookup:
	.leave
	ret

returnLocalAddr:
	mov	si, offset localEtherAddr
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw	
	clc
	jmp	exitLookup

broadcastPacket:
	mov	ax, 0FFFFh
	mov	cx, 3
copyBroadcastAddrLoop:
	mov	es:[di], ax
	add	di, 2
	loop	copyBroadcastAddrLoop
	clc
	jmp	exitLookup

notFound:
	;
	; Broadcast a request to the net.
	;
	call	EthPktArpBroadcastRequest

	;
	; Add an incomplete entry for this IP address.
	;
	call	ChunkArrayAppend	; ds:di = IpEtherArpEntry, all zeroed
	Assert	carryClear		;;; don't handle error for now
	movdw	ds:[di].IEAE_ipAddr, dxcx
	call	TimerGetCount		; bxax = count
	mov	ds:[di].IEAE_addrOrTs.IAOT_timestamp, ax
	clr	ds:[di].IEAE_packets.handle
	clr	ds:[di].IEAE_packets.chunk

incomplete:
	;
	; Prepend this packet to the list of pending packets.
	;		
	mov	si, ss:[sendingPacket]
	tst	si
	jz	gotoUnlockTable

	mov	es, ss:[packetSptr]
	mov	si, ss:[packetLptr]	; *es:si = PacketHeader
	mov	si, es:[si]
	movdw	<es:[si + PACKET_HEADER_MAX_SIZE].IPH_next>, \
		ds:[di].IEAE_packets, ax
	mov	bx, ss:[packetHptr]
	mov	ax, ss:[packetLptr]
	movdw	ds:[di].IEAE_packets, bxax

gotoUnlockTable:
	stc				; return addr not found
	jmp	unlockTable
EthPktArpIpToEther	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIArpIpTableLookup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches the ip table to see if we have info on the
		requested ip address.

CALLED BY:	EthODIArpIpToEther, EtherDoArpLookup
PASS:		dxax	= IPAddr to look up, in network byte order
RETURN:		CF clear if address found
		CF set if not found
		Whatever else ChunkArrayEnum returns
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		This code was simple moved from inside another function
		so it didn't have to be duplicated elsewhere.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	06/01/00	Moved from EthODIArpIpToEther

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktArpIpTableLookup	proc	far
	;
	; Search our table.
	;
	mov_tr	cx, ax			; dxcx = IPAddr
	GetDGroup	ds, bx
	movdw	bxsi, ds:[arpTable]
	push	bx			; save array hptr
	call	MemLock
	mov	ds, ax			; *ds:si = ARP table array
	mov	bx, SEGMENT_CS
	mov	di, offset EthPktArpCompareIp	; bx:di = callback
	call	ChunkArrayEnum		; CF if found, ds:ax = IpEtherArpEntry
	pop	bx
	ret
EthPktArpIpTableLookup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktArpBroadcastRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Broadcast an ARP request asking for the ethernet address for
		the passed IP address.

CALLED BY:	EthPktArpIpToEther
PASS:		dxcx	= IPAddr, in network byte order
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	04/29/02	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktArpBroadcastRequest	proc	near
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter

	;
	; Allocate a free buffer, if any.
	; Need to disable interrupt here since allocation can be done at
	; interrupt time.
	;
	GetDGroup	ds, ax
	mov	es, ax
	INT_OFF
	mov	si, ds:[recvBufFreeList]
	tst	si
	jz	exit			; can't alloc.  Do nothing.
	mov	ax, ds:[si].RB_nextLink
	mov	ds:[recvBufFreeList], ax
	INT_ON

	;
	; Use the data portion of the receive buffer as an arp structure
	; Fill in MAC header
	;
	mov	bx, cx			; dxbx = IPAddr
	mov	ds:[si].RB_macHeader.MACH_type, PACKET_TYPE_ARP
	;
	; Fill in ethernet address for broadcasting (ff:ff:ff:ff:ff:ff).
	;
	lea	di, ds:[si].RB_macHeader.MACH_dest
	mov	al, 0xff
	mov	cx, NODE_ADDR_SIZE
	rep	stosb
	;
	; Fill in source ethernet address
	;
	lea	di, ds:[si].RB_macHeader.MACH_source
	mov_tr	ax, si			; es:ax = receive buffer
	mov	si, offset localEtherAddr	; ds:si = localEtherAddr
		CheckHack <(NODE_ADDR_SIZE and 1) eq 0>
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw
	mov_tr	si, ax			; es:si = buffer

	;
	; Fill in ARP header.
	;
	lea	si, ds:[si].RB_data
	mov	ds:[si].IEA_arpHeader.AH_hwAddrFormat, AHAF_ETHER_NET_ORDER
	mov	ds:[si].IEA_arpHeader.AH_protAddrFormat, PACKET_TYPE_IP
	mov	ds:[si].IEA_arpHeader.AH_hwAddrLen, NODE_ADDR_SIZE
	mov	ds:[si].IEA_arpHeader.AH_protAddrLen, IP_ADDR_SIZE
	mov	ds:[si].IEA_arpHeader.AH_op, AO_REQUEST_NET_ORDER

	;
	; Fill in ARP addresses.
	;
	movdw	ds:[si].IEA_targetProtoAddr, dxbx
	movdw	dxax, ds:[localIpAddr]
	movdw	ds:[si].IEA_senderProtoAddr, dxax
	lea	di, ds:[si].IEA_senderHwAddr	; es:di = IEA_senderHwAddr
	mov_tr	ax, si			; es:ax = buffer
	mov	si, offset localEtherAddr	; ds:si = localEtherAddr
		CheckHack <(NODE_ADDR_SIZE and 1) eq 0>
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw
	mov_tr	si, ax			; es:si = buffer

	;
	; Pad with trailing zero's
	;
	CheckHack <((size IpEtherArp) and 1) eq 0>
	CheckHack <(size IpEtherArp + size MACHeader) lt MIN_PACKET_SIZE>
	lea	di, ds:[si + size IpEtherArp]
	clr	ax
	mov	cx, (MIN_PACKET_SIZE - size IpEtherArp - size MACHeader) / 2
	rep	stosw

	;
	; Send the request.
	;
	CheckHack <(offset RB_data) eq (offset RB_macHeader + size MACHeader)>
	sub	si, size MACHeader
	mov	bx, MAX_SEND_ATTEMPTS
	mov	ah, PDF_SEND_PKT
	mov	cx, MIN_PACKET_SIZE

retrySend:
	;pusha
	push	ax, cx, dx, bx, bp, si, di
	call	callPacketDriver
	pop	ax, cx, dx, bx, bp, si, di
	;popa
	jnc	freeBuffer
	dec	bx
	jnz	retrySend

	; Free the buffer
freeBuffer:
	sub	si, offset RB_macHeader
	INT_OFF
	mov	ax, si				; es:ax = buffer to free
	xchg	ax, ds:[recvBufFreeList]	; es:ax = old head of buf list
	mov	ds:[si].RB_nextLink, ax

ifdef	LOG
		pusha
		push	ds
		segmov	ds, dgroup
		mov	si, ds:[currentIndex]
		inc	ds:[currentIndex]
		mov	ds:[logBuf][si], LOG_ARP_SEND_COMP_END
		pop	ds
		popa
endif

exit:
	INT_ON

	.leave
	ret
EthPktArpBroadcastRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPProcessArpPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process an incoming ARP packet.

CALLED BY:	MSG_EP_PROCESS_ARP_PACKET

PASS:		ds	= dgroup
		dx:cx	= buffer allocated from our buffer list
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We assume that a network of GEOS clients is probably a network of
	machines for users to browse the web (which goes through the IP
	gateway) and telnet to a few local servers. GEOS clients probably
	never talk among themselves.  It is unlike a distributed computing
	environment (e.g. NOW) where clients mostly talk to other clients on
	the same local network.

	AO_REQUEST:
		Add the IP/Ethernet address pair of the requesting machine
		to our table, because it's very likely that we will be
		sending some IP packets to that machine very soon (probably
		a reply in some higher protocol).  Then send a reply.
	AO_REPLY:
		Add the IP/Ethernet address pair of the replying machine to
		our ARP table.
	AO_REVARP_REQUEST:
		Ignored.  We don't keep the necessary info to reply to this.
		Leave this job to a dedicated server.  Don't even bother
		adding the addresses of the requesting machine to our table.
	AO_REVARP_REPLY:
		Ignored.  We should never be getting this anyway because
		we never issue AO_REVARP_REQUEST.  The packet was probably
		caused by some error somewhere.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	04/30/02	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPProcessArpPacket	method dynamic EtherProcessClass, 
					MSG_EP_PROCESS_ARP_PACKET
	.enter

	Assert	dgroup, dx
	Assert	fptr, dxcx

	push	si

	;
	; Make sure it's large enough
	;
	cmp	ds:[si].RB_size, size IpEtherArp
	jb	freeBuf

	;
	; Ignore packet if format of protocol addrs is not IP.
	;
	CheckHack <offset RB_macHeader + size MACHeader eq offset RB_data>
	lea	si, ds:[si].RB_data
	cmp	ds:[si].IEA_arpHeader.AH_protAddrFormat, PACKET_TYPE_IP
	jne	freeBuf

	;
	; Ignore packet if target IP addrs doesn't match ours.
	;
	movdw	dxax, ds:[localIpAddr]
	cmpdw	dxax, ds:[si].IEA_targetProtoAddr
	jne	freeBuf

	;
	; Ignore if opcode is AO_REVARP_xxx or any opcode that we don't
	; understand (this can happen if new opcodes are added to ARP on
	; other machines in the future.)
	;
	cmp	ds:[si].IEA_arpHeader.AH_op, AO_REQUEST_NET_ORDER
	je	addAddr
	cmp	ds:[si].IEA_arpHeader.AH_op, AO_REPLY_NET_ORDER
	jne	freeBuf			; => AO_REVARP_xxx or unknown opcode

addAddr:
	;
	; Fill in our IP addr as the sender protocol addr, in case we do a
	; reply later.
	;
	xchgdw	dxax, ds:[si].IEA_senderProtoAddr	; dxax = remote IP addr
							;  in netowrk order

	;
	; Add the addrs of the requesting host to our ARP table.
	;
	push	si			; save IpEtherArp nptr
	mov	bx, ds
	add	si, offset IEA_senderHwAddr	; bx:si = remote NodeAddr
	call	EthPktArpAddCompleteEntry
	pop	si			; ds:si = IpEtherArp

	;
	; We are now done if opcode is AO_REPLY.
	;
	cmp	ds:[si].IEA_arpHeader.AH_op, AO_REPLY_NET_ORDER
	je	freeBuf

	;
	; Opcode is AO_REQUEST.  Construct a reply by reusing the buffer
	;
	mov	ds:[si].IEA_arpHeader.AH_op, AO_REPLY_NET_ORDER

	;
	; Use the sender's HW and protocol addrs as our target addrs.
	;
	push	si
	movdw	ds:[si].IEA_targetProtoAddr, dxax
	GetDGroup	es, di
	lea	di, ds:[si].IEA_targetHwAddr	; es:di = IEA_targetHwAddr
	add	si, offset IEA_senderHwAddr	; ds:si = IEA_senderHwAddr
		CheckHack <(NODE_ADDR_SIZE and 1) eq 0>
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw

	;
	; Fill in our Ethernet addr as the sender HW addr.
	;
	mov	si, offset localEtherAddr	; ds:si = localEtherAddr
		CheckHack <offset IEA_senderHwAddr + size IEA_senderHwAddr \
			eq offset IEA_senderProtoAddr>
		CheckHack <offset IEA_senderProtoAddr + \
			size IEA_senderProtoAddr eq offset IEA_targetHwAddr>
	sub	di, size IEA_targetHwAddr + size IEA_senderProtoAddr \
			+ size IEA_senderHwAddr	; es:di = IEA_senderHWAddr
		CheckHack <(NODE_ADDR_SIZE and 1) eq 0>
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw

	;
	; Fill in the MAC header
	;
	pop	di
	mov	si, di
	lea	si, ds:[si].IEA_targetHwAddr
	sub	di, size MACHeader
	push	di
	mov	es:[di].MACH_type, PACKET_TYPE_ARP
	CheckHack <(offset MACH_source) eq (offset MACH_dest + size NodeAddr)>
	lea	di, ds:[di].MACH_dest
	CheckHack <(NODE_ADDR_SIZE and 1) eq 0>
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw
	mov	si, offset localEtherAddr
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw

	pop	si
	mov	di, si
	sub	di, offset RB_macHeader
	mov	cx, es:[di].RB_size
	add	cx, size MACHeader
	mov	bx, MAX_SEND_ATTEMPTS
	mov	ah, PDF_SEND_PKT

retrySend:
	;pusha
	push	ax, cx, dx, bx, bp, si, di
	call	callPacketDriver
	;popa
	pop	ax, cx, dx, bx, bp, si, di
	jnc	freeBuf
	dec	bx
	jnz	retrySend

freeBuf:
	;
	; Free recv buffer.  Need to disable interrupt here since allocation
	; is done at interrupt time.
	;
	pop	si
	INT_OFF
	mov	ax, si				; ds:ax = buff to free
	xchg	ax, ds:[recvBufFreeList]	; ds:ax = old head of buf list
	mov	ds:[si].RB_nextLink, ax
	INT_ON

	.leave
	ret

EPProcessArpPacket	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherDoArpLookup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does an ARP lookup on the passed IP address. Returns the
		associated MAC address, if any.

CALLED BY:	EXTERNAL
PASS:		ds:si	= SocketAddress
		cx:dx	= buffer for MAC address (6 bytes)
		bx	= buffer size (0 just to know if MAC exists for an ip)
RETURN:		ax	= SocketError
		bx	= Address size
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	06/01/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherDoArpLookup	proc	far
	bufferSize	local	word	push	bx
	macBufferSeg	local	sptr	push	cx
	macBufferOff	local	lptr	push	dx
	ipAddr		local	dword	
	uses	cx, dx, ds, es, si, di
	.enter

	movdw	dxax, ({dword}({TcpAccPntResolvedAddress}ds:[si].SA_address).TAPRA_ipAddr)
	movdw	ipAddr, dxax

	cmpdw	dxax, 0100007Fh
	je	arpLoopback
	; if loopback, skip the subnet test and actually do the lookup,
	; will be translated there

	call	CompareIpToLocalSubnet
	jc	arpNotFound

arpLoopback:
	mov	cx, bufferSize
	cmp	cx, NODE_ADDR_SIZE
	jb	linkAddrBufferTooSmall

	clr	cx
	mov	di, macBufferSeg
	mov	es, di
	mov	di, macBufferOff
	call	EthPktArpIpToEther
	jnc	arpMatchFound
	
	; Sleep for a few seconds and try again...
	; this gives time for a response to come in
	mov	ax, 60 * 2	; 60 tics/sec * 2 sec
	call	TimerSleep

	; Try the arp lookup again. This time just look directly in
	; the table, so we don't queue another arp request.
	movdw	dxax, ipAddr
	call	EthPktArpIpTableLookup
	jnc	arpNotFound

	mov_tr	di, ax
	test	ds:[di].IEAE_flags, mask AEF_COMPLETE
	jz	arpNotFound

	mov	ax, SE_NORMAL
	mov	cx, bufferSize
	tst	cx
	jz	arpLookupDone

	lea	si, ds:[di].IEAE_addrOrTs.IAOT_etherAddr
	mov	di, macBufferSeg
	mov	es, di
	mov	di, macBufferOff
	mov	cx, NODE_ADDR_SIZE / 2
	rep	movsw
	mov	ax, SE_NORMAL

arpLookupDone:
	call	MemUnlock
arpLookupExit:
	.leave
	mov	bx, NODE_ADDR_SIZE	
	ret

arpMatchFound:
	mov	ax, SE_NORMAL
	jmp	arpLookupExit

linkAddrBufferTooSmall:
	mov	ax, SE_BUFFER_TOO_SMALL
	jmp	arpLookupExit

arpNotFound:
	mov	ax, SE_DESTINATION_UNREACHABLE
	jmp	arpLookupExit

EtherDoArpLookup	endp

MovableCode	ends
