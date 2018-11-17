COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethodiTransceive.asm

AUTHOR:		Todd Stumpf, Aug 18th, 1998

ROUTINES:

DESCRIPTION:

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MovableCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODITransmitPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transmit a packet to the remote host.

CALLED BY:	EtherSendDatagram
PASS:		dx:bp	= optr of buffer to send (PacketHeader)
		ds	= dgroup
RETURN:		carry clear if success
			buffer may be locked or unlocked or freed.  If not
			freed yet, will be freed (after unlocking if needed)
			later.
		carry set if error
			ax	= SocketDrError
			buffer not locked and not freed
DESTROYED:	ax, bx, cx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	First, the passed buffer starts with this layout:
	PacketHeader, padded to PACKET_HEADER_MAX_SIZE
	ECB with one PacketFragmentPtr

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
		packet data

	ipovly overlays ip (which is IpHeader in asm).
	Most things are passed in network byte order.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/04/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODITransmitPacket	proc	near
	uses	dx
	.enter

ifdef	LOG
		pusha
		pushf
		cli
		push	ds
		segmov	ds, dgroup
		mov	si, ds:[currentIndex]
		mov	ds:[logBuf][si], LOG_TRANSMIT_START
		inc	ds:[currentIndex]
		cmp	ds:[currentIndex], size logBuf
		jb	popDS
		clr	ds:[currentIndex]
		
popDS:
		pop	ds
		popf
		popa
endif

	Assert	dgroup, ds

	;
	; Fill in the self reference for this packet
	;
	mov	bx, dx			; ^lbx:bp = buffer
	call	HugeLMemLock		; ax = buffer sptr
	mov	es, ax			; es = buffer sptr
	mov	ds, ax			; *ds:bp = buffer
	mov	si, ds:[bp]		; ds:si = PacketHeader
	mov	cx, ds:[si].PH_dataOffset
	add	cx, ds:[si].PH_dataSize	; cx = packet data size
	mov	di, si			; ds:di = PacketHeader
	add	si, PACKET_HEADER_MAX_SIZE	; ds:si = es:si = ECB
	movdw	ds:[si].ECB_protocolWS.LSLPR_self, bxbp

	;
	; Fill in pointer and size of data
	;
	mov	ds:[si].ECB_dataLen, cx
	mov	ds:[si].ECB_fragCount, 1
	mov	ds:[si].ECB_fragments.PFP_size, cx
	add	di, ds:[di].PH_dataOffset    ; ds:di = IpHeader, start of data
	movdw	ds:[si].ECB_fragments.PFP_addr, dsdi

	;
	; Look up ethernet address of the node that handles this destination
	; IP address.
	;
	movdw	dxax, ds:[di].IH_dest	; dxax = IPAddr
	lea	di, ds:[si].ECB_immAddr	; es:di = ECB_immAddr
	mov	cx, -1			; ed - say we've got a packet
	call	EthODIArpIpToEther	; CF if ether addr not known yet
	jc	etherAddrNotKnownYet

	;
	; Fill in other stuff.
	;
	mov	ds:[si].ECB_ESR.segment, segment EthODITransmitCompleteHandler
	mov	ds:[si].ECB_ESR.offset, offset EthODITransmitCompleteHandler
	GetDGroup	ds, ax
	mov	ax, ds:[ipStackId]
	mov	es:[si].ECB_stackID, ax
	mov	ax, ds:[lslBoardNum]
	mov	es:[si].ECB_boardNum, ax

	;
	; Fill in protocol ID.
	;
	lea	di, es:[si].ECB_protID	; es:di = ECB_protID
	push	si			; save ECB offset
	mov	si, offset ipProtoId	; ds:si = lslProtoId
		CheckHack <(PROTOCOL_ID_SIZE and 1) eq 0>
	mov	cx, PROTOCOL_ID_SIZE / 2
	rep	movsw
	pop	si			; es:si = ECB

	;
	; Send it.
	;
	mov	bx, LSLPF_SEND_PACKET
	call	SysLockBIOS
	call	ds:[lslProtoEntry]	; returns interrupt off
	INT_ON
	call	SysUnlockBIOS

exit:

ifdef	LOG
		pusha
		push	ds
		segmov	ds, dgroup
		mov	si, ds:[currentIndex]
		inc	ds:[currentIndex]
		mov	ds:[logBuf][si], LOG_TRANSMIT_END
		pop	ds
		popa
endif

	clc				; return success
	.leave
	ret

etherAddrNotKnownYet:
	;
	; Unlock packet
	;
	call	HugeLMemUnlock
	jmp	exit

EthODITransmitPacket	endp

MovableCode		ends

ResidentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODITransmitCompleteHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called by LSL whenever outgoing packet is completely
		transmitted.

CALLED BY:	EXTERNAL (LSL.COM), either at interrupt time or at process time
PASS:		es:si	= ECB
		interrupt off
RETURN:		interrupt off
DESTROYED:	ax, bx, cx, dx, di, es (ax, bx, cx, dx, si, di, es allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The Novell ODI spec (p. 6-8) isn't clear on whether we can turn on
	interrupts during this routine.  I assume we can.

	We don't need to call SysEnterInterrupt/SysExitInterrupt.  If we
	are called from hardware interrupt, the kernel Irq?Intercept routine
	already calls them.  If we are called from software interrupt in LSL,
	we can't prevent context-switching until after exiting anyway because
	we need to call SysExitInterrupt before exiting.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/20/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODITransmitCompleteHandler	proc	far
	.enter

	;
	; Cannot error-check fptr or lptr here, since we may be called at
	; interrupt time.  We may be able to error-check hptr here, I'm not
	; sure, but don't bother.
	;

	; Transmission should always be successful, even if the destination
	; node does not exist.
	Assert	e, es:[si].ECB_status, LSLEC_SUCCESSFUL

	;
	; Ask the process to free the packet.
	;
	mov	ax, MSG_EP_SEND_PACKET_DONE
	movdw	dxcx, es:[si].ECB_protocolWS.LSLPR_self	; ^ldx:cx = packet
	GetDGroup	es, bx
	mov	bx, es:[etherThread]
	Assert	ne, bx, NULL		; It may be bad to "Assert thread" at
					;  interrupt time.
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage		; returns interrupt on
	INT_OFF				; turns it back off before exiting

	.leave
	ret
EthODITransmitCompleteHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIIpRecvHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called by LSL whenever incoming packet starts being
		received.

CALLED BY:	EXTERNAL (LSL.COM), at interrupt time
PASS:		ds:di	= LookAheadStruct
		interrupts off
RETURN:		if protocol stack will consume the packet
			ax	= LSLEC_SUCCESSFUL
			es:si	= ECB allocated from our free list
		else
			ax	= LSLEC_OUT_OF_RESOURCES
		ZF set according to AX
		interrupts off
DESTROYED:	nothing (bx, cx, dx allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The Novell ODI spec (p. 5-9) says interrupt must remain disabled
	during this routine.

	We don't need to call SysEnterInterrupt/SysExitInterrupt, because
	the kernel Irq?Intercept routine already calls them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/25/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODIIpRecvHandler	proc	far
	.enter

ifdef	LOG
		pusha
		push	ds
		segmov	ds, dgroup
		mov	si, ds:[currentIndex]
		inc	ds:[currentIndex]
		mov	ds:[logBuf][si], LOG_IPRECV_START
		pop	ds
		popa
endif
	GetDGroup	es, si

if	ERROR_CHECK
	pusha
	lea	si, ds:[di].LAS_protId	; ds:si = LAS_protId
	mov	di, offset ipProtoId	; es:di = lslProtoId
	mov	cx, size ProtocolID
	repe	cmpsb
	ERROR_NE PROTOCOL_ID_MISMATCH
	popa

	cmp	ds:[di].LAS_dataSize, -1
	ERROR_E	PACKET_SIZE_MUST_BE_KNOWN
endif	; ERROR_CHECK

	cmp	ds:[di].LAS_dataSize, IP_MIN_HEADER
EC <	WARNING_B IP_PACKET_TOO_SMALL					>
	jb	reject

	cmp	ds:[di].LAS_dataSize, RECV_BUFFER_SIZE
EC <	WARNING_A IP_PACKET_TOO_LARGE_FOR_US				>
	ja	reject

	;
	; If driver thread does not exist (ie. TCPIP is not registered with
	; us), we can't deliver IP packets.
	;
	tst	es:[etherThread]
	jz	reject

	;
	; Allocate a free ECB, if any.
	;
	mov	si, es:[recvEcbFreeList]	; es:si = free ECB
	tst	si
EC <	WARNING_Z OUT_OF_RECV_BUFFERS					>
	jz	reject
	mov	ax, es:[si].ECB_nextLink.offset
	mov	es:[recvEcbFreeList], ax
	mov	es:[si].ECB_ESR.segment, segment EthODIIpRecvCompleteHandler
	mov	es:[si].ECB_ESR.offset, offset EthODIIpRecvCompleteHandler
		CheckHack <LSLEC_SUCCESSFUL eq 0>
	clr	ax			; ax = LSLEC_SUCCESSFUL

exit:
	tst	ax			; set ZF for return

ifdef	LOG
		pusha
		push	ds
		segmov	ds, dgroup
		mov	si, ds:[currentIndex]
		inc	ds:[currentIndex]
		mov	ds:[logBuf][si], LOG_IPRECV_END
		pop	ds
		popa
endif

	.leave
	ret

reject:
	mov	ax, LSLEC_OUT_OF_RESOURCES
	jmp	exit

EthODIIpRecvHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIIpRecvCompleteHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called by LSL whenever incoming packet is completely
		received.

CALLED BY:	EXTERNAL (LSL.COM), usually at interrupt time
PASS:		es:si	= ECB
		interrupts off
RETURN:		interrupts off
DESTROYED:	ax, bx, cx, dx, di (ax, bx, cx, dx, si, di, es allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The Novell ODI spec (p. 5-13) says this routine can enable
	interrupts and context-switches.

	We don't need to call SysEnterInterrupt/SysExitInterrupt.  If we
	are called from hardware interrupt, the kernel Irq?Intercept routine
	already calls them.  If we are called from software interrupt in LSL,
	we can't prevent context-switching until after exiting anyway because
	we need to call SysExitInterrupt before exiting.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/07/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODIIpRecvCompleteHandler	proc	far
	.enter
ifdef	LOG
		pusha
		push	ds
		segmov	ds, dgroup
		mov	si, ds:[currentIndex]
		inc	ds:[currentIndex]
		mov	ds:[logBuf][si], LOG_IPRECV_COMP_START
		pop	ds
		popa
endif
	;
	; Cannot error-check fptr here, since we my be called at interrupt
	; time.
	;

	mov	bx, es:[etherThread]
	Assert	ne, bx, NULL		; It may be bad to "Assert thread" at
					;  interrupt time.

	mov	ax, MSG_EP_PROCESS_IP_PACKET
	movdw	dxcx, essi		; dx:cx = ECB
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage		; returns interrupt on
	INT_OFF				; turns it back off before exiting

ifdef	LOG
		pusha
		push	ds
		segmov	ds, dgroup
		mov	si, ds:[currentIndex]
		inc	ds:[currentIndex]
		mov	ds:[logBuf][si], LOG_IPRECV_COMP_END
		pop	ds
		popa
endif

	.leave
	ret
EthODIIpRecvCompleteHandler	endp

ResidentCode	ends

MovableCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIProcessIpPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process an incoming IP packet.

CALLED BY:	EthDevProcessIpPacket
PASS:		ds	= dgroup
		dx:cx	= ECB allocated from our buffer list
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Free receiving buffer as soon as possible, even before unlocking
	packet chunk.

	We can check and discard packets whose IH_dest is different from
	ours (this can happen if the source machine's IP->Ether address
	lookup is invalid), but this happens only rarely.  Therefore we
	skip the check to save some cycles, and let any bad packets go all
	the way to IpInput() and be discarded there.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen   	11/07/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODIProcessIpPacket	proc	near
	.enter

	Assert	dgroup, ds
	Assert	dgroup, dx
	Assert	fptr, dxcx

	;
	; Check receive status.
	;
	mov	si, cx			; ds:si = ECB
	cmp	ds:[si].ECB_status, LSLEC_SUCCESSFUL
	jne	errorFreeBuf

	;
	; Allocate a HugeLMem block to store a packet.  No need to check
	; if HugeLMem has already been created, since we create it before
	; hooking up to LSL, and destroy it after unhooking from LSL.
	;
	mov	ax, ds:[si].ECB_dataLen
	add	ax, PACKET_HEADER_MAX_SIZE + LINK_HEADER_SIZE
					; ax = size of chunk needed
	mov	bx, ds:[recvHugeLMem]
	mov	cx, HUGELMEM_ALLOC_WAIT_TIME
	call	HugeLMemAllocLock	; ^lax:cx = ds:di = buffer, CF on error
	jc	errorFreeBuf

	;
	; Fill in PacketHeader
	;
	mov	ds:[di].PH_dataOffset, PACKET_HEADER_MAX_SIZE+LINK_HEADER_SIZE
	pushdw	axcx			; save packet optr
	segmov	es, ds			; es:di = PacketHeader
	mov	ds, dx			; ds = dgroup, ds:si = ECB
	mov	ax, ds:[clientDomainHandle]
	mov	es:[di].PH_domain, ax
	mov	cx, ds:[si].ECB_dataLen
	mov	es:[di].PH_dataSize, cx

	;
	; Copy data into packet.
	;
	Assert	e, ds:[si].ECB_fragCount, 1
	Assert	dgroup, ds:[si].ECB_fragments.PFP_addr.segment
	Assert	fptr, ds:[si].ECB_fragments.PFP_addr
	push	si			; save ECB offset
	mov	si, ds:[si].ECB_fragments.PFP_addr.offset ; ds:si = data recvd
	add	di, PACKET_HEADER_MAX_SIZE + LINK_HEADER_SIZE
					; es:di = buffer for data
	shr	cx
	rep	movsw
	jnc	afterCopy
	movsb
afterCopy:
	pop	si			; ds:si = ECB

	;
	; Free recv buffer.
	; Need to disable interrupt here since allocation can be done at
	; interrupt time.
	;
	INT_OFF
	mov	ax, si			; ds:ax = ECB to free
	xchg	ax, ds:[recvEcbFreeList]	; ds:ax = old head of buf list
	mov	ds:[si].ECB_nextLink.offset, ax
	INT_ON

	;
	; Unlock packet and forward it.
	;
	popdw	cxdx			; ^lcx:dx = packet
	mov	bx, cx
	call	HugeLMemUnlock
	mov	di, SCO_RECEIVE_PACKET
	SCOIndication

exit:
	.leave
	ret

errorFreeBuf:
	;
	; Free buffer.  Need to disable interrupt here since allocation
	; is done at interrupt time.
	;
	INT_OFF
	mov	ax, si			; ds:ax = ECB to free
	xchg	ax, ds:[recvEcbFreeList]	; ds:ax = old head of buf list
	mov	ds:[si].ECB_nextLink.offset, ax
	INT_ON
	jmp	exit

EthODIProcessIpPacket	endp

MovableCode	ends
