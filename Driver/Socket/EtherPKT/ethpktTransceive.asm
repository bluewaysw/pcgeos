COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Edward Di Geronimo Jr. 2002 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethodiTransceive.asm

AUTHOR:		Edward Di Geronimo Jr.

ROUTINES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	2/24/02		Initial revision

DESCRIPTION:

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MovableCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktTransmitPacket
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
	ed	04/24/02	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktTransmitPacket	proc	near
	uses	ds
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
	pushdw	dxbp
	mov	bx, dx			; ^lbx:bp = buffer
	call	HugeLMemLock		; ax = buffer sptr
	mov	es, ax			; es = buffer sptr
	mov	ds, ax			; *ds:bp = buffer
	mov	si, ds:[bp]		; ds:si = PacketHeader
	mov	cx, ds:[si].PH_dataSize ; cx = packet data size
	add	cx, size MACHeader
EC <	cmp	cx, MIN_PACKET_SIZE					>
EC <	WARNING_B IP_PACKET_TOO_SMALL					>
	
	jae	largePacket
minPacket:
	inc	cx
	dec	cx
	mov cx, MIN_PACKET_SIZE
largePacket:	

	add	si, ds:[si].PH_dataOffset
	mov	di, si			; ds:di = PacketHeader
	sub	si, size MACHeader
	; ds:si = es:si = MACHeader
	push	cx			; need size later	

	;
	; Look up ethernet address of the node that handles this destination
	; IP address.
	;
	movdw	dxax, es:[di].IH_dest	; dxax = IPAddr
	lea	di, ds:[si].MACH_dest	; es:di = buffer mac dest
	mov	cx, -1			; say we've got a packet
	push	es
	call	EthPktArpIpToEther	; CF if ether addr not known yet
	pop	es
	jc	etherAddrNotKnownYet

	;
	; Fill in other stuff.
	;
	mov	cx, size NodeAddr
	lea	di, ds:[si].MACH_source
	GetDGroup	ds, ax
	mov	cx, size NodeAddr / 2
	push	si
	mov	si, offset localEtherAddr
	rep	movsw
	pop	si
	segmov	ds, es, ax
	mov	ds:[si].MACH_type, PACKET_TYPE_IP

	;
	; Send it. If error, try again until max retries.
	;
	; Using bx, as it's as good as any other register available
	; at this point.
	pop	cx	; get the packet size back
	mov	bx, MAX_SEND_ATTEMPTS
	mov	ah, PDF_SEND_PKT

retrySend:
	pusha
	call	callPacketDriver
	popa
	jnc	sentPacket
	dec	bx
	jnz	retrySend
cantSend2:
	popdw	dxcx
	stc
	jmp	cantSend

sentPacket:
	mov	ax, MSG_EP_SEND_PACKET_DONE
	popdw	dxcx
	GetDGroup	es, bx
	mov	bx, es:[etherThread]
	Assert	ne, bx, NULL		; It may be bad to "Assert thread" at
					;  interrupt time.
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage		; returns interrupt on

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
cantSend:
	.leave
	ret

etherAddrNotKnownYet:
	;
	; Unlock packet
	;
	call	HugeLMemUnlock
	add	sp, 6	; size word, buffer optr
	jmp	exit

EthPktTransmitPacket	endp

MovableCode		ends

ResidentCode	segment	resource

EthPktRecvHandlerThread	proc	far

	GetDGroup	ds, ax
again:
	tst	ds:[currentRecvBuf]
	jz	done
	
	INT_OFF
	
	mov	si, ds:[currentRecvBuf]
	mov	ds:[currentRecvBuf], 0
	
	INT_ON
doNext:
	movdw	dxcx, dssi		; dx:cx = buffer
	mov	ax, MSG_EP_PROCESS_IP_PACKET
	cmp	ds:[si].RB_macHeader.MACH_type, PACKET_TYPE_IP
	je	sendMsg
	mov	ax, MSG_EP_PROCESS_ARP_PACKET
	cmp	ds:[si].RB_macHeader.MACH_type, PACKET_TYPE_ARP
	je	sendMsg

	; free buffer, should not happen	
	jmp	done2

sendMsg: 

	mov bx, ds:[si].RB_nextLink
	push bx
	mov	bx, ds:[etherThread]
	Assert	ne, bx, NULL		; It may be bad to "Assert thread" at
					;  interrupt time.

	mov	di, mask MF_FORCE_QUEUE
	;WARNING ENTER_OBJ_MESSAGE
	push	ds
	push	si
	call	ObjMessage		; returns interrupt on
	pop		si
	pop	ds
	;WARNING LEFT_OBJ_MESSAGE
	pop		bx

done2:
	mov	si, bx
	cmp	si, 0
	jne	doNext

done:
    ; wait some time
    
	jmp	again

EthPktRecvHandlerThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktRecvHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called by the packet driver when a packet is ready
		to be received. This routine gets called twice; once when
		a packet begins coming in, to ensure that there is buffer
		space available, and a second time when the transfer is
		complete.

CALLED BY:	EXTERNAL (packet driver), at interrupt time
PASS:		Always:
			bx	= handle
			cx	= length
			interrupts off (???)
		Packet begins coming in:
			ax	= 0
		Packet finished coming in:
			ax	= 1
			ds:si	= buffer
RETURN:		es:di	= buffer (0:0 to reject packet)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We don't need to call SysEnterInterrupt/SysExitInterrupt, because
	the kernel Irq?Intercept routine already calls them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	04/24/02    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktRecvHandler	proc	far
	uses ds

	; no defined stack on call in
    ; test system (DosEMU) enters with interrupts of
    
	;GetDGroup	ss, di

	; setup own stack
	;mov	sp, offset endLocalStack
	
	.enter
	;call	SysEnterInterrupt
    ;WARNING	ENTER_RECEIVE

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
	tst	ax
	jnz	receiveComplete	

	CheckHack <IP_MIN_HEADER le (size IpEtherArp)>
	WARNING_B PACKET_TOO_SMALL
	jb	reject

	cmp	cx, RECV_BUFFER_SIZE + size MACHeader
EC <	WARNING_A PACKET_TOO_LARGE_FOR_US				>
	ja	reject

	;
	; If driver thread does not exist (ie. TCPIP is not registered with
	; us), we can't deliver IP packets.
	;
	GetDGroup	es, ax
	tst	es:[etherThread]
	jz	reject

	;
	; Allocate a free buffer, if any.
	;
	INT_OFF					; make sure
	mov	di, es:[recvBufFreeList]	; es:si = free buffer
	tst	di
EC <	WARNING_Z OUT_OF_RECV_BUFFERS					>
	jz	reject
	mov	ax, es:[di].RB_nextLink
	mov	es:[recvBufFreeList], ax
	sub	cx, size MACHeader
	mov	es:[di].RB_size, cx
	lea	di, es:[di].RB_macHeader

exit:

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

    ;WARNING	LEAVE_RECEIVE
	;INT_ON
	;call	SysExitInterrupt
	.leave
	ret

reject:
	clr	di
	mov	es, di
	jmp	exit

receiveComplete:
	INT_OFF
	sub	si, offset RB_macHeader
	movdw	dxcx, dssi		; dx:cx = buffer
	mov	ax, MSG_EP_PROCESS_IP_PACKET
	cmp	ds:[si].RB_macHeader.MACH_type, PACKET_TYPE_IP
	je	sendMsg
	mov	ax, MSG_EP_PROCESS_ARP_PACKET
	cmp	ds:[si].RB_macHeader.MACH_type, PACKET_TYPE_ARP
	je	sendMsg
	;
	; Other - discard
	;
	mov	ax, si				; ds:ax = buffer to free
	xchg	ax, ds:[recvBufFreeList]	; ds:ax = old head of buf list
	mov	ds:[si].RB_nextLink, ax
	jmp	exit
sendMsg:
	clr	bx
    tst		ds:[currentRecvBuf]
    jz		newRecvStack
    
	mov	bx, ds:[currentRecvBuf]
    
newRecvStack:
	cmp	bx, si
    ;WARNING_Z	ENTER_RECEIVE
	mov	ds:[si].RB_nextLink, bx
    mov		ds:[currentRecvBuf], si
    
    
	;tst	ds:[saveSS]
	;jnz	alreadyUsingStack
	;mov	ds:[saveSS], ss
	;mov	ds:[saveSP], sp
	;mov	bx, ds
	;mov	ss, bx
	;mov	sp, offset endLocalStack
	
	
	
	
	
	;mov	bx, ds:[etherThread]
	;Assert	ne, bx, NULL		; It may be bad to "Assert thread" at
					;  interrupt time.

	;mov	di, mask MF_FORCE_QUEUE
	;WARNING ENTER_OBJ_MESSAGE
	;;INT_ON
	;push	ds
	;call	ObjMessage		; returns interrupt on
	;pop	ds
	;WARNING LEFT_OBJ_MESSAGE
	;INT_OFF
	;;mov	ss, ds:[saveSS]
	;;mov	sp, ds:[saveSP]
	;WARNING LEFT_OBJ_MESSAGE
	;clr	ds:[saveSS]
	;WARNING LEFT_OBJ_MESSAGE
	;WARNING LEFT_OBJ_MESSAGE
	jmp	exit

alreadyUsingStack:
	; already using the stack. discard packet.
EC <	WARNING DISCARDING_PACKET_ALREADY_USING_STACK			>
	mov	ax, si
	xchg	ax, ds:[recvBufFreeList]
	mov	ds:[si].RB_nextLink, ax
	jmp	exit
EthPktRecvHandler	endp

ResidentCode	ends

MovableCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktProcessIpPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process an incoming IP packet.

CALLED BY:	EthDevProcessIpPacket
PASS:		ds	= dgroup
		dx:cx	= Buffer allocated from our buffer list
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
	ed   	04/29/02    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktProcessIpPacket	proc	far
	.enter

	Assert	dgroup, ds
	Assert	dgroup, dx
	Assert	fptr, dxcx

	;
	; Allocate a HugeLMem block to store a packet.  No need to check
	; if HugeLMem has already been created, since we create it before
	; hooking up to the packet driver, and destroy it after unhooking
	; from the packet driver.
	;
	mov	si, cx			; ds:si = ECB
	mov	ax, ds:[si].RB_size
	add	ax, PACKET_HEADER_MAX_SIZE + LINK_HEADER_SIZE
					; ax = size of chunk needed
	add	ax, 100
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
	mov	ds, dx			; ds = dgroup, ds:si = buffer
	mov	ax, ds:[clientDomainHandle]
	mov	es:[di].PH_domain, ax
	mov	cx, ds:[si].RB_size
	mov	es:[di].PH_dataSize, cx

	;
	; Copy data into packet.
	;
	push	si			; save buffer offset
	lea	si, ds:[si].RB_data
	add	di, PACKET_HEADER_MAX_SIZE + LINK_HEADER_SIZE
					; es:di = buffer for data
	shr	cx
	rep	movsw
	jnc	afterCopy
	movsb
afterCopy:
	pop	si			; ds:si = buffer

	;
	; Free recv buffer.
	; Need to disable interrupt here since allocation can be done at
	; interrupt time.
	;
	INT_OFF
	mov	ax, si				; ds:ax = buffer to free
	xchg	ax, ds:[recvBufFreeList]	; ds:ax = old head of buf list
	mov	ds:[si].RB_nextLink, ax
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
	mov	ax, si			; ds:ax = buffer to free
	xchg	ax, ds:[recvBufFreeList]	; ds:ax = old head of buf list
	mov	ds:[si].RB_nextLink, ax
	INT_ON
	jmp	exit

EthPktProcessIpPacket	endp

MovableCode	ends
