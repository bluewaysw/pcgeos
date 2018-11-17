COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Network extensions
MODULE:		socket library
FILE:		socketPacket.asm

AUTHOR:		Eric Weber, May 23, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT PacketAttach            create a huge lmem for packets

    INT PacketDetach            free the huge lmem for packets

    EXT SendConnectionControl   Send a connection control packet

    EXT ConnectionControlReply  Reply to a connection control packet (send
				another CCP to the sender of the first
				packet)

    INT SocketRecvLow           Fetch a sequenced packet for the user

    INT SocketAllocRecvSem      Setup a semaphore for a recv

    INT SocketVerifyRecvState   Analyze socket's state for purposes of recv

    INT SocketGetUrgent         Get data from a socket

    INT SocketGetUrgentRegs     Copy data from a dword register into memory

    INT SocketGetUrgentChunk    Copy data from a huge lmem chunk

    INT SocketGetData           Get data from a socket

    INT SocketRecvCallback      Copy data from one packet into user's
				buffer

    INT SocketGetDataAddress    Get address from first packet in a datagram
				socket

    INT SocketSendSequencedLink Send a sequenced packet via link driver

    INT SocketSendSequencedData Send a sequenced packet via data driver

    INT SocketSendDatagram      Create and send a datagram packet

    INT ReceiveConnectionControlPacket 
				Handle a connection control packet

    INT ReceiveLinkDataPacket   Find a home for an incoming data packet

    INT ReceiveSequencedDataPacket 
				Receive a sequenced packet from a data
				driver

    INT ReceiveDatagramDataPacket 
				Receive a datagram packet from a data
				driver

    INT ReceiveUrgentDataPacket Store an urgent packet into a socket

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/23/94   	Initial revision


DESCRIPTION:
	
		

	$Id: socketPacket.asm,v 1.50 97/11/06 20:51:28 brianc Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SMALL_BLOCK_SIZE	equ	4000
LARGE_BLOCK_SIZE	equ	8000

udata	segment

packetHeap	word	; handle of huge lmem containing packets
sendTimeout	word	; time to wait for send queue to empty

udata	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPacketHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the hugelmem handle containing packets

PASS:		nothing

RETURN:		bx	- hugelmem handle
		es	- dgroup

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPacketHeap	macro
		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, es:[packetHeap]
endm

UtilCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PacketAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a huge lmem for packets

CALLED BY:	(INTERNAL) SocketEntry
PASS:		nothing
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		*HACK* ax should be set from ini file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PacketAttach	proc	near
		uses	ax,bx,cx,ds
		.enter
		mov	ax, 0			; *HACK* max # of blocks
		mov	bx, SMALL_BLOCK_SIZE
		mov	cx, LARGE_BLOCK_SIZE	; maximum size of a block
		call	HugeLMemCreate		; bx = handle
		jc	done
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS		; ds = dgroup
		pop	bx
		mov	ds:[packetHeap], bx	; save handle
done:
		.leave
		ret
PacketAttach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PacketDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	free the huge lmem for packets

CALLED BY:	(INTERNAL) SocketEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PacketDetach	proc	near
		uses	bx,es
		.enter
		GetPacketHeap
		call	HugeLMemDestroy
		.leave
		ret
PacketDetach	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendConnectionControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a connection control packet

CALLED BY:	(EXTERNAL) ConnectionControlReply, FreeListenQueueCallback,
		SocketAccept, SocketClearConnection, SocketConnect,
		SocketSendClose
PASS:		ax		ConnectionControlOperation
	ON STACK:
		PacketInfo	(pushed first)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/23/94    	Init1ial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendConnectionControl	proc	far	info:PacketInfo
		uses	ax,bx,cx,dx,si,ds,es
		operation	local	ConnectionControlOperation
		packetSize	local	word
		.enter
		mov	ss:[operation], al
	;
	; compute size of final packet
	;
		mov	ax, size ConnectionControlPacket
		mov	ss:[packetSize], ax
		add	ax, ss:[info].PI_headerSize
	;
	; allocate a chunk for it
	;
		clr	cx			; don't wait for memory
		GetPacketHeap			; bx = heap
		call	HugeLMemAllocLock	;^lax:cx = new buffer,
						; ds:di = new buffer
		jnc	init
EC <		WARNING	CANT_ALLOCATE_CONTROL_PACKET			>
		jmp	done
	;
	; initialize driver header
	;
init:
		mov	ds:[di].PH_dataSize,	size ConnectionControlPacket
		segmov	ds:[di].PH_dataOffset,	ss:[info].PI_headerSize, bx
		mov	ds:[di].PH_flags, 	PacketFlags <1,0,PT_SEQUENCED>
		segmov	ds:[di].PH_domain, 	ss:[info].PI_client, bx
		segmov	ds:[di].SPH_link, 	ss:[info].PI_link, bx
	;
	; initialize library header
	;
		mov	bx, ss:[info].PI_headerSize
		add	di, bx
		mov	ds:[di].CCP_type,	LPT_CONNECTION_CONTROL
		movdw	ds:[di].CCP_source,	ss:[info].PI_srcPort, bx
		movdw	ds:[di].CCP_dest,	ss:[info].PI_destPort, bx
		segmov	ds:[di].CCP_opcode, 	ss:[operation], bl
	;
	; unlock the packet
	;
		mov	bx, ax
		call	HugeLMemUnlock
	;
	; verify the packet
	;
verify::
EC <		push	cx,dx						>
EC <		mov	dx,cx		; offset of packet		>
EC <		mov	cx,ax		; handle of packet		>
EC <		call	ECCheckOutgoingPacket				>
EC <		pop	cx,dx						>
	;
	; send the packet (^lax:cx)
	;
send::
		push	bp				; save frame pointer
		pushdw	ss:[info].PI_entry		; save entry point
		pushdw	axcx				; save packet
		mov	ax, -1				; no timeout
		mov	bx, ss:[info].PI_link		; link handle
		mov	cx, ss:[packetSize]		; size of packet
		popdw	dxbp				; packet optr
		mov	si, SSM_NORMAL
		mov	di, DR_SOCKET_SEND_DATA		; SocketFunction
callDriver::
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; send the packet
		pop	bp				; bp = frame pointer
done::
		.leave
		ret	@ArgSize
SendConnectionControl	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectionControlReply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reply to a connection control packet
		(send another CCP to the sender of the first packet)
CALLED BY:	(EXTERNAL) ConnectionAccept, ConnectionOpen
PASS:		ds	- control segment  (locked for write)
		es:di	- PacketHeader of original packet
		cx	- offset of ConnectionControlPacket from es:di
		ax	- ConnectionControlOperation to send
RETURN:		ds	- possibly moved
DESTROYED:	es
SIDE EFFECTS:	unlocks and relocks control segment

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectionControlReply	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; allocate a PacketInfo
	;
		sub	sp, size PacketInfo
		mov	bx, sp
		push	ax				; save CCO
	;
	; copy some info from the PacketHeader
	;
		segmov	ss:[bx].PI_link, es:[di].SPH_link, dx
		mov	dx, es:[di].PH_domain		; dx = domain handle
	;
	; copy some info from the ConnectionControlPacket
	;
		add	di, cx
		movdw	ss:[bx].PI_srcPort, es:[di].CCP_dest, ax
		movdw	ss:[bx].PI_destPort, es:[di].CCP_source, ax
	;
	; copy some info from the DomainInfo
	;
		mov	si, dx
		mov	si, ds:[si]
		segmov	ss:[bx].PI_client, ds:[si].DI_client, ax
		movdw	ss:[bx].PI_entry, ds:[si].DI_entry, ax
		mov	al, ds:[si].DI_seqHeaderSize
		clr	ah
		mov	ss:[bx].PI_headerSize, ax
	;
	; unlock control segment and send packet
	;
		call	SocketControlEndWrite
		pop	ax			; ax=ConnectionControlOperation
		call	SendConnectionControl
	;
	; relock control segment and exit
	;
		call	SocketControlStartWrite
		.leave
		ret
ConnectionControlReply	endp

UtilCode	ends

ExtraApiCode		segment resource

FixedCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRecvLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a sequenced packet for the user

CALLED BY:	(INTERNAL) SocketRecv
PASS:		bx	= Socket
		es:di	= buffer for received data
		cx	= size of buffer
		bp	= timeout (in ticks)
		si	= SocketReceiveFlags
		ds	= control segment (locked for read)
		ON STACK
			fptr to SocketAddress structure
			SA_domain, SA_domainSize, SA_addressSize initialized
RETURN:
		cx	= size of data received
		es:di	= filled in with data
		ax	= SocketError
			SE_TIMED_OUT
			SE_CONNECTION_FAILED
			SE_CONNECTION_CLOSED

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 5/94    	Initial version
	brianc	10/22/98	Moved into fixed code for resolver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRecvLow	proc	far	abuf:fptr
		uses	bx,dx,si,di,bp
		socketHan	local	word			push bx
		buffer		local	fptr			push es,di
		bufSize		local	word			push cx
		bufRemaining	local	word			push cx
		flags		local	SocketRecvFlags		push si
		deliveryType	local	SocketDeliveryType
		dataSize	local	word
		pktCount	local	word
		dataOffset	local	word
		header		local	word
		timeout		local	dword

		ForceRef	abuf
		ForceRef	socketHan
		ForceRef	buffer
		ForceRef	bufSize
		ForceRef	bufRemaining
		ForceRef	flags
		ForceRef	deliveryType
		ForceRef	dataSize
		ForceRef	pktCount
		ForceRef	dataOffset
		ForceRef	header
		.enter
	;
	; compute the timeout information
	;
		lea	ax, ss:[timeout]
		call	SocketSetupTimeout
	;
	; set up the semaphore
	;
		mov	di, ds:[bx]			; ds:di = SocketInfo
		call	SocketAllocRecvSem		; bx=semaphore
		jnc	checkState
		mov	ax, SE_SOCKET_BUSY
		jmp	exit
	;
	; analyze the socket's state
	;
checkState:
		call	SocketVerifyRecvState
		jc	timedOut
	;
	; see if data is available
	;
checkData::
		test	si, mask SRF_URGENT
		jz	checkQueue
	;
	; check for urgent data
	;
checkUrgent::
		and	ds:[di].SI_flags, not mask SF_EXCEPT
		tst	ds:[di].SSI_urgentSize
		jz	noData
		call	SocketGetUrgent
		jmp	cleanup
	;
	; check the data queue
	;
checkQueue:
		call	SocketCheckQueue
		jc	noData
		call	SocketGetData
		jmp	cleanup
	;
	; no data, see if we should wait for data
	;
noData:
		tst	dx
		jz	timedOut
	;
	; go ahead and wait
	;
waitData::
		lea	cx, ss:[timeout]		; ss:cx = timeout
		call	SocketControlEndRead
		call	SocketPTimedSem			; carry set if timeout
	;
	; if we timed out, exit with error code set above
	; otherwise back to the top and check the state again
	;
pastBlock::
		call	SocketControlStartRead
		mov	di, ss:[socketHan]
		mov	di, ds:[di]
		jnc	checkState
		
timedOut:
		clr	cx
		stc
	;
	; clean up any semaphore still in the socket
	;
	; this is done last, since the existence of the semaphore prevents
	; any other recv from happening on this socket, which would lead
	; to nasty race conditions in SocketGetData
	;
cleanup:
		mov	bx, ss:[socketHan]
		pushf
		test	si, mask SRF_URGENT
		jz	clearWait
		call	SocketClearExcept
		jmp	done
clearWait:
		call	SocketClearSemaphore
done:
		popf
exit:
		.leave
		ret	@ArgSize
SocketRecvLow	endp

FixedCode ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAllocRecvSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup a semaphore for a recv

CALLED BY:	(INTERNAL) SocketRecvLow
PASS:		ds:di	- SocketInfo
		si	- SocketReadFlags

RETURN:		carry set if socket busy
		bx	= semaphore to wait on (trashed if carry set)

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/23/95    	Initial version
	brianc	10/22/98	Made far for SocketRecvLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAllocRecvSem	proc	far
		uses	ax,cx,dx,si,di,bp
		.enter
	;
	; allocate a semaphore to wait for data
	;
	; since we don't have an exclusive lock on the data block
	; we need to use the permanent semSem to ensure consistent
	; access to waitSem
	;
		mov	bx, ds:[di].SI_semSem
		call	ThreadPSem			; lock the semSem
	;
	; if reading URGENT, use the exceptSem
	; otherwise use the waitSem
	;
		test	si, mask SRF_URGENT
		jz	checkWaitSem
	;
	; see if somebody else is already waiting
	;
		tst	ds:[di].SI_exceptSem
		stc
		jnz	cleanup
	;
	; if not, allocate a new semaphore and stick it into exceptSem
	;
		clr	bx
		call	ThreadAllocSem
		mov	ds:[di].SI_exceptSem, bx
		jmp	pastAlloc
	;
	; see if anybody is waiting on the waitSem
	;
checkWaitSem:
		tst	ds:[di].SI_waitSem
		stc
		jnz	cleanup
	;
	; allocate a new waitSem
	;
		clr	bx				; initial count 0
		call	ThreadAllocSem			; bx = semaphore
		mov	ds:[di].SI_waitSem, bx		; store in socket
pastAlloc:
		clc
cleanup:
		push	bx
		mov	bx, ds:[di].SI_semSem		; bx = semSem
		call	ThreadVSem			; unlock semSem
		pop	bx
done::		
		.leave
		ret

SocketAllocRecvSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketVerifyRecvState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Analyze socket's state for purposes of recv

CALLED BY:	(INTERNAL) SocketRecvLow
PASS:		ds:di	- SocketInfo
		si	- SocketReadFlags

RETURN:		ax	- SocketError to give if recv fails
		dx	- BB_TRUE if timeout should be used
		carry	- set to abort recv without checking for data

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/23/95    	Initial version
	brianc	10/22/98	Made far for SocketRecvLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketVerifyRecvState	proc	far
		uses	bx,cx,si,di,bp
		.enter
	;
	; abort in case of interrupt
	;
		test	ds:[di].SI_flags, mask SF_INTERRUPT
		jz	checkException
		test	si, mask SRF_URGENT
		jz	interruptReset
	;
	; if an urgent read is interrupted, check for normal read also
	;
		mov	bx, ds:[di].SI_semSem
		call	ThreadPSem
		call	WakeUpSocketLow
		call	ThreadVSem
		jnz	interruptCommon
interruptReset:
		and	ds:[di].SI_flags, not mask SF_INTERRUPT
interruptCommon:
		mov	ax, SE_INTERRUPT
		stc
		jmp	done
	;
	; abort in case of exception/urgent data
	; this does not apply to urgent reads, naturally
	;
	; for datagrams, put the exception into the error code
	;
checkException:
		test	si, mask SRF_URGENT
		jnz	checkState
		test	ds:[di].SI_flags, mask SF_EXCEPT
		jz	checkState
		and	ds:[di].SI_flags, not mask SF_EXCEPT
		mov	ax, SE_EXCEPTION
		cmp	ds:[di].SI_delivery, SDT_DATAGRAM
		stc
		jne	done
		mov	ah, ds:[di].DSI_exception
		jmp	done
	;
	; datagram and sequenced sockets have different checks
	;
checkState:
		cmp	ds:[di].SI_delivery, SDT_DATAGRAM
NEC <		je	default						>
nec_bottom::
NEC <		.assert	offset nec_bottom eq offset checkSequenced	>
EC <		jne	checkSequenced					>
	;
	; a datagram socket is ok as long as it is bound
	;
EC <		test	si, mask SRF_URGENT				>
EC <		ERROR_NZ URGENT_FLAG_REQUIRES_NON_DATAGRAM_SOCKET	>
EC <		tst	ds:[di].SI_port					>
EC <		ERROR_Z SOCKET_NOT_BOUND				>
EC <		jmp	default						>
	;
	; a sequenced socket must be connected, and able to receive data
	;
checkSequenced::
EC <		cmp	ds:[di].SI_state, ISS_CONNECTED			>
EC <		ERROR_NE	SOCKET_NOT_CONNECTED			>
	;
	; determine whether we should wait for data
	; determine what error to give if no data exists
	;
		mov	dx, BB_FALSE
		mov	ax, ds:[di].SSI_error
		test	ds:[di].SI_flags, mask SF_FAILED
		jnz	done
		
		mov	ax, SE_CONNECTION_CLOSED
		test	ds:[di].SI_flags, mask SF_RECV_ENABLE
		jz	done
default:
		mov	dx, BB_TRUE
		mov	ax, SE_TIMED_OUT
done:
		.leave
		ret
SocketVerifyRecvState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetUrgent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get data from a socket

CALLED BY:	(INTERNAL) SocketRecvLow
PASS:		ds:di	= SocketINfo
		ss:bp	= inherited stack frame

RETURN:		cx	= size of data received
		ax	= SE_NORMAL
		carry clear

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/15/95    	Initial version
	brianc	10/22/98	Made far for SocketRecvLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetUrgent	proc	far
		uses	bx,dx,si,di,es
		.enter inherit SocketRecvLow
	;
	; initialize pointers
	;
		mov	si,di				; ds:si = SocketInfo
		movdw	esdi, ss:[buffer]		; es:di = user buffer
		movdw	bxax, ds:[si].SSI_urgent
	;
	; determine size to copy
	;
		mov	dx, ds:[si].SSI_urgentSize
		mov	cx, ss:[bufSize]
		cmp	cx,dx
		jbe	clearSSI
		mov	cx,dx
	;
	; possibly clear the socket
	;
clearSSI:
		test	ss:[flags], mask SRF_PEEK
		jnz	checkSize
		clrdw	ds:[si].SSI_urgent
		clr	ds:[si].SSI_urgentSize
	;
	; cx=size to copy, dx=original size
	;
	; if dx<=4, data is in bxax
	; if dx>4, data is in ^lbx:ax
	;
checkSize:
		cmp	dx,4
		ja	getChunk
		call	SocketGetUrgentRegs
		jmp	done
getChunk:
		call	SocketGetUrgentChunk
		test	ss:[flags], mask SRF_PEEK
		jnz	done
	;
	; free the data chunk
	;
		mov_tr	cx,ax
		mov	ax,bx
		call	HugeLMemFree
	;
	; return original size to user
	;
done:
EC <		test	ss:[flags], mask SRF_ADDRESS			>
EC <		ERROR_NE ADDRESS_FLAG_REQUIRES_DATAGRAM_SOCKET		>
		mov	cx,dx
		clr	ax			; ax=SE_NORMAL, carry clear
		.leave
		ret
SocketGetUrgent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetUrgentRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy data from a dword register into memory

CALLED BY:	(INTERNAL) SocketGetUrgent
PASS:		bxax	- urgent data
		cx	- number of bytes to copy
		es:di	- buffer for data

RETURN:		nothing
DESTROYED:	cx,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/15/95    	Initial version
	brianc	10/22/98	Made far for SocketRecvLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetUrgentRegs	proc	far
		.enter
		jcxz	done
		stosb				; byte 0 = al
		dec	cx
		jz	done
		mov	al,ah
		stosb				; byte 1 = ah
		dec	cx
		jz	done
		mov	al,bl
		stosb				; byte 2 = bl
		dec	cx
		jz	done
		mov	al,bh
		stosb				; byte 3 = bh
done:
		.leave
		ret
SocketGetUrgentRegs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetUrgentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy data from a huge lmem chunk

CALLED BY:	(INTERNAL) SocketGetUrgent
PASS:		^lbx:ax = urgent data
		cx	= number of bytes to copy
		es:di	= buffer for data
RETURN:		nothing
DESTROYED:	si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/15/95    	Initial version
	brianc	10/22/98	Made far for SocketRecvLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetUrgentChunk	proc	far
		uses	ax,ds
		.enter
		jcxz	done
	;
	; lock and dereference the huge lmem chunk
	;
		mov	si,ax
		call	HugeLMemLock
		mov	ds,ax
		mov	si, ds:[si]			; ds:si = data
	;
	; copy the data
	;
EC <		call	ECCheckMovsb					>
		rep	movsb
	;
	; release the huge lmem
	;
		call	HugeLMemUnlock
done:
		.leave
		ret
SocketGetUrgentChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get data from a socket

CALLED BY:	(INTERNAL) SocketRecvLow
PASS:		ds:di	= SocketINfo
		ss:bp	= inherited stack frame

RETURN:		cx	= size of data received
		ax	= SE_NORMAL
		carry clear
	

DESTROYED:	bx,dx,si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/12/94    	Initial version
	brianc	10/22/98	Made far for SocketRecvLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetData	proc	far
		.enter	inherit SocketRecvLow
	;
	; initialize state for callback
	;
		push	ds,di
		segmov	ss:[deliveryType], ds:[di].SI_delivery, al
		segmov	ss:[dataOffset], ds:[di].SI_dataOffset, ax
		clr	ss:[dataSize]
		clr	ss:[pktCount]
	;
	; enumerate the queue
	;
		mov	bx, handle SocketQueues
		mov	si, ds:[di].SI_dataQueue
		mov	cx, SEGMENT_CS
		mov	dx, offset SocketRecvCallback
		movdw	dsdi, ss:[buffer]
		call	QueueEnum
		pop	ds,di			; ds:di = SocketInfo
	;
	; possibly copy the address out of the socket
	;
copyAddress::
		test	ss:[flags], mask SRF_ADDRESS
		jz	discard
		mov	cx, ss:[pktCount]
		jcxz	checkSize
		push	es, di, bx
		movdw	esdi, ss:[abuf]
		mov	bx, ss:[socketHan]
		call	SocketGetDataAddress
		pop	es, di, bx
	;
	; for RECV, set dataSize to number of bytes actually copied,
	; which is (bufSize - bufRemaining)
	;
discard:
		test	ss:[flags], mask SRF_PEEK
		jnz	checkSize		; no discard on peek
		mov	cx, ss:[pktCount]	; # of packets to discard
		jcxz	checkSize		; queue was empty
		cmp	ss:[deliveryType], SDT_STREAM
		jne	countOK			
	;
	; if we didn't completely read the last packet, leave it on
	; the queue for the next receive
	;
	; as long as we're messing with dataOffset, copy it back to
	; the socket
	;
		mov	ax, ss:[dataOffset]
		mov	ds:[di].SI_dataOffset, ax
		tst	ax			; did we finish last pkt?
		jz	countOK
		dec	cx			; don't discard unfinished pkt
	;
	; actually discard the packets
	; note: ^lbx:si = queue, cx = count
	;
countOK:
		call	SocketDequeuePackets
		clr	dx
		subdw	ds:[di].SI_curQueueSize, dxcx
EC <		ERROR_C CORRUPT_SOCKET					>
	;
	; for RECV, return number of bytes actually read
	; for PEEK, return number of bytes available for reading
	;
checkSize:
		mov	cx, ss:[bufSize]
		sub	cx, ss:[bufRemaining]
		test	ss:[flags], mask SRF_PEEK
		jz	success
		mov	cx, ss:[dataSize]
	;
	; we successfully read some data
	;
success:
		mov	ax, SE_NORMAL
		clc
done::
		.leave
		ret
SocketGetData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRecvCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy data from one packet into user's buffer

CALLED BY:	(INTERNAL)
PASS:		ss:bp	- inherited stack frame
		ds:di   - pointer to end of data in user's buffer
		es:si	- current queue element

		ss:[dataOffset]		offset to start reading in packet
		ss:[bufRemaining]	space remaining in user's buffer
		ss:[flags]		receive flags
		ss:[dataSize]		size of all packets examined previously
		ss:[pktCount]		number of packets visited previously

RETURN:		carry	- set to abort
		ds:di	- moved past copied data

		ss:[dataOffset]		if non-zero, offset we stopped at
		ss:[bufRemaining]	space remaining in user's buffer
		ss:[pktSize]		size of this packet
		ss:[dataSize]		size of all packets examined
		ss:[pktCount]		number of packets visited

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRecvCallback	proc	far
		uses	ax,bx,cx,dx,si,bp,ds,es
		.enter inherit SocketGetData
	;
	; lock the packet
	;
		movdw	bxsi, es:[si]		; ^lbx:si = packet
		push	bx
		segmov	es,ds,ax		; es:di = user buffer
		call	HugeLMemLock
		mov	ds,ax			; *ds:si = packet
		mov	si, ds:[si]		; ds:si = packet
		mov	ss:[header], si
	;
	; skip over the packet header
	;
skipHeaders::
		mov	al, ds:[si].PH_flags
		mov	cx, ds:[si].PH_dataSize		; cx = size of lib data
		add	si, ds:[si].PH_dataOffset	; si = data
	;
	; for packets from link drivers, skip the library's headers also
	;
		test	al, mask PF_LINK
		jz	addOffset
EC <		cmp	ds:[si].LDP_type, LPT_USER_DATA			>
EC <		ERROR_NE UNEXPECTED_PACKET_TYPE				>
		mov	bl, ds:[si].LDP_offset
		clr	bh
		add	si, bx				; ds:si = data
		sub	cx, bx				; cx= size of user data
	;
	; take data offset into account
	;
addOffset:
		clr	ax
		xchg	ax, ss:[dataOffset]		; ax = old offset
		add	si, ax
		sub	cx, ax				; remaining data size
	;
	; update various counters
	;
gotSize::
		add	ss:[dataSize], cx
		inc	ss:[pktCount]			; count pkt as read
		sub	ss:[bufRemaining], cx
	;
	; if buffer >= data, proceed with copy
	; dataOffset is already zero, which is correct for this case
	;		
		jge	copyData
	;
	; buffer is too small, so adjust cx by the deficit
	;
		add	cx, ss:[bufRemaining]		; cx=original buf size
		clr	ss:[bufRemaining]
	;
	; remember offset for next read
	;
		test	ss:[flags], mask SRF_PEEK
		jnz	copyData
		add	ax,cx				; add new offset to old
		mov	ss:[dataOffset], ax		; write combined offset
	;
	; copy the data into the buffer
	;
copyData:
		jcxz	pastCopy
EC <		call	ECCheckMovsb					>
		rep	movsb
	;
	; decide whether to continue enumeration
	; 	SEQ and DGRAM always stops
	;	RECV STREAM stops if buffer is full
	;	PEEK STREAM always continues
	;
pastCopy::
		cmp	ss:[deliveryType], SDT_STREAM
		stc
		jne	done
		
		test	ss:[flags], mask SRF_PEEK		; clears carry
		jnz	done

		tst_clc	ss:[bufRemaining]
		jnz	done
		stc
done:
		pop	bx
		call	HugeLMemUnlock
		.leave
		ret
SocketRecvCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketGetDataAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get address from first packet in a datagram socket

CALLED BY:	(INTERNAL) SocketGetData
PASS:		es:di	- SocketAddress
		*ds:bx	- SocketInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketGetDataAddress	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
		mov	si, ds:[bx]
		cmp	ds:[si].SI_delivery, SDT_DATAGRAM
EC <		ERROR_NE ADDRESS_FLAG_REQUIRES_DATAGRAM_SOCKET		>
NEC <		jne	done						>
	;
	; for datagram sockets, find the first packet
	;
		mov	bx, handle SocketQueues
		mov	si, ds:[si].SI_dataQueue
		push	di				; save buf offset
		mov	cx, NO_WAIT
		call	QueueDequeueLock
		pop	cx				; cx = buf offset
		jc	done
		movdw	bxax, ds:[di]
		call	QueueAbortDequeue
		mov	si, ax				; bx:si = hugelmem
		call	HugeLMemLock
		mov	ds,ax
		mov	si, ds:[si]
		mov	di, cx				; es:di = buffer
	;
	; get the address
	;
		push	si,di
		add	di, offset SA_address		; es:di = buffer
		mov	cl, ds:[si].DPH_addrSize
		clr	ch				; cx = addr size
		mov	al, ds:[si].DPH_addrOffset
		clr	ah
		add	si, ax				; ds:si = address
EC <		call	ECCheckMovsb					>
		rep	movsb
		pop	si,di
	;
	; get the port
	;
		test	ds:[si].PH_flags, mask PF_LINK
		jnz	link
	;
	; 16 bit port is in the DatagramPacketHeader
	;
		mov	es:[di].SA_port.SP_manuf, MANUFACTURER_ID_SOCKET_16BIT_PORT
		segmov	es:[di].SA_port.SP_port, ds:[si].DPH_remotePort, ax
		jmp	cleanup
	;
	; 32 bit port is in the LinkDataPacket
	;
link:
		add	si, ds:[si].PH_dataOffset
		movdw	es:[di].SA_port, ds:[si].LDP_source, ax
cleanup:
		call	HugeLMemUnlock
done::
		.leave
		ret
SocketGetDataAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSendSequencedLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a sequenced packet via link driver

CALLED BY:	(INTERNAL) SocketSend
PASS:		ds:si	- data to send
		cx	- size of data
	ON STACK
		PacketInfo

RETURN:		carry set if error
		ax = SocketError

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketSendSequencedLink	proc	near info:PacketInfo
		uses	bx,cx,dx,si,ds,es
		packetData	local	fptr	push ds,si
		dataSize	local	word	push cx
		packetSize	local	word	; user data + LDP
		packetChunk	local	optr
		.enter
	;
	; compute size of final packet
	;
		mov	ax, size LinkDataPacket
		add	ax,cx
		mov	ss:[packetSize], ax
		add	ax, ss:[info].PI_headerSize
	;
	; allocate a chunk for it
	;
		clr	cx			; don't wait for memory
		GetPacketHeap			; bx = heap
		call	HugeLMemAllocLock	;^lax:cx = new buffer,
						; ds:di = new buffer
		movdw	ss:[packetChunk], axcx
		jnc	initPacket
	;
	; can't alloc memory
	;
		mov	ax, SE_OUT_OF_MEMORY
		jmp	done
	;
	; initialize driver header
	;
initPacket:
		segmov	ds:[di].PH_dataSize,	ss:[dataSize], bx
		add	ds:[di].PH_dataSize,	size LinkDataPacket
		segmov	ds:[di].PH_dataOffset,  ss:[info].PI_headerSize, bx
		mov	ds:[di].PH_flags,	PacketFlags <1,0,PT_SEQUENCED>
		segmov	ds:[di].PH_domain, 	ss:[info].PI_client, bx
		segmov	ds:[di].SPH_link,	 ss:[info].PI_link, bx
	;
	; compute offset to library header and initialize it
	;
		add	di, ss:[info].PI_headerSize
		mov	ds:[di].LDP_type,	LPT_USER_DATA
		movdw	ds:[di].LDP_source,	ss:[info].PI_srcPort, bx
		movdw	ds:[di].LDP_dest,	ss:[info].PI_destPort, bx
		mov	ds:[di].LDP_offset, size LinkDataPacket
	;
	; copy the user's data
	;
copyData::
		segmov	es,ds,si
		add	di, size LinkDataPacket
		movdw	dssi, ss:[packetData]
		mov	cx, ss:[dataSize]
EC <		call	ECCheckMovsb					>
		rep	movsb
	;
	; unlock the packet
	;
		mov	bx, ax
		call	HugeLMemUnlock
	;
	; verify the packet (trashes cx,dx)
	;
verifyPacket::
EC <		movdw	cxdx, ss:[packetChunk]				>
EC <		mov	cx,ax						>
EC <		call	ECCheckOutgoingPacket				>
	;
	; send the packet
	;
callDriver::
		push	bp				; save frame pointer
		lea	di, ss:[info]			; ss:di = PacketInfo
		pushdw	ss:[di].PI_entry		; driver entry
		mov	cx, ss:[packetSize]		; size of packet
		mov	dx, ss:[packetChunk].handle
		mov	bp, ss:[packetChunk].offset	; ^ldx:bp = packet
		mov	bx, ss:[di].PI_link		; connection handle
		mov	ax, DEFAULT_SEND_TIMEOUT	; timeout in ticks
		mov	si, SSM_NORMAL
		mov	di, DR_SOCKET_SEND_DATA		; SocketFunction
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; send the packet
		pop	bp				; bp = frame pointer
		mov	ax, SE_NORMAL
		jnc	done
		mov	ax, SE_TIMED_OUT
done:
		.leave
		ret	@ArgSize

SocketSendSequencedLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSendSequencedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a sequenced packet via data driver

CALLED BY:	(INTERNAL) SocketSend
PASS:		ds:si	- data to send
		cx	- size of data
		ax	- SocketSendFlags
	ON STACK
		PacketInfo

RETURN:		carry set if error
			ax = SocketError (SE_TIMED_OUT,
					  SE_OUT_OF_MEMORY)
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketSendSequencedData	proc	near	info:PacketInfo
		uses	bx,cx,dx,si,di,bp
		packetData	local	fptr	push ds,si
		dataSize	local	word	push cx
		flags		local	word	push ax
		packetChunk	local	optr
		.enter
	;
	; compute size of packet, including header
	;
		mov	ax, ss:[info].PI_headerSize
		add	ax, cx
	;
	; allocate a packet chunk
	;
		clr	cx			; don't wait for memory
		GetPacketHeap			; bx = heap
		call	HugeLMemAllocLock	;^lax:cx = new buffer,
						; ds:di = new buffer
		movdw	ss:[packetChunk], axcx
		jnc	initPacket
		mov	ax, SE_OUT_OF_MEMORY
		jmp	done
	;
	; initialize driver header
	;
initPacket:
		segmov	ds:[di].PH_dataSize,	ss:[dataSize], bx
		mov	ds:[di].PH_flags,	PacketFlags <0,0,PT_SEQUENCED>
		segmov	ds:[di].PH_domain, 	ss:[info].PI_client, bx
		segmov	ds:[di].SPH_link,	 ss:[info].PI_link, bx
		segmov	ds:[di].PH_dataOffset,  ss:[info].PI_headerSize, bx
	;
	; copy the user's data
	;
copyData::
		segmov	es,ds,si
		add	di, bx			; es:di = data buffer
		movdw	dssi, ss:[packetData]	; ds:si = user's data
		mov	cx, ss:[dataSize]
EC <		call	ECCheckMovsb					>
		rep	movsb
	;
	; unlock the packet and grab dgroup
	;
		mov	bx, ax
		call	HugeLMemUnlock
		mov	bx, handle dgroup
		call	MemDerefES
	;
	; send the data
	;
callDriver::
		push	bp
		pushdw	ss:[info].PI_entry		; routine to call
		mov	cx, ss:[dataSize]		; size of data
		mov	bx, ss:[info].PI_link		; connection handle
		mov	ax, es:[sendTimeout]		; timeout in ticks
		mov	si, SSM_NORMAL
		test	ss:[flags], mask SSF_URGENT	
		jz	gotMode
		mov	si, SSM_URGENT
gotMode:
		mov	di, DR_SOCKET_SEND_DATA
		movdw	dxbp, ss:[packetChunk]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; parse the result codes
	;
result::
		pop	bp
		jnc	normal
		mov	dx, ax
		mov	al, SE_TIMED_OUT
		cmp	dl, SDE_CONNECTION_TIMEOUT
		je	failed
		mov	al, SE_INTERRUPT
		cmp	dl, SDE_INTERRUPTED
		je	failed
		mov	al, SE_CONNECTION_CLOSED
		cmp	dl, SDE_CONNECTION_RESET
		je	failed
EC <		cmp	dl, SDE_CONNECTION_RESET_BY_PEER		>
EC <		ERROR_NE UNEXPECTED_SOCKET_DRIVER_ERROR			>
failed:
		stc
		jmp	done
normal:
		clr	ax
done:
		.leave
		ret	@ArgSize
SocketSendSequencedData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketSendDatagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and send a datagram packet

CALLED BY:	(INTERNAL) SocketSend
PASS:		ds:si	- data to send
		cx	- size of data
		ax	- sendFlags
		es:di	- SocketAddress
		(on stack)  PacketInfo
RETURN:		args popped
		carry set if error
		ax - SocketError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketSendDatagram	proc	near	info:PacketInfo
		uses	bx,cx,dx,si,di,bp,ds,es
		buffer		local	fptr	push ds,si
		bufSize		local	word	push cx
		flags		local	word	push ax
		packet		local	optr
		packetSize	local	word
		addressFptr	local	fptr.SocketAddress
		.enter
	;
	; Store a fptr to socketAddress structure
	;
		movdw	ss:[addressFptr], esdi
	;
	; compute size of packet
	;
	; this includes the driver header and address, and possibly a library
	; header
	;
		mov	ax,cx
		cmp	ss:[info].PI_driverType, SDT_DATA
		je	gotSize
		add	ax, size LinkDataPacket
gotSize:
		mov	ss:[packetSize], ax
		add	ax, es:[di].SA_addressSize
		add	ax, ss:[info].PI_headerSize
	;
	; allocate a chunk for it
	;
		mov	si,di			; es:si = address
		push	bx,cx,es
		clr	cx			; don't wait for memory
		GetPacketHeap			; bx = heap, es trashed
		call	HugeLMemAllocLock	;^lax:cx = new buffer,
						; ds:di = new buffer
		movdw	ss:[packet], axcx
		pop	bx,cx,es
		jnc	initDPH
		mov	ax, SE_OUT_OF_MEMORY
		jmp	exit
	;
	; initialize DatagramPacketHeader size fields
	;
initDPH:
		segxchg	es,ds			; ds:si = address,
						; es:di = packet
		segmov	es:[di].PH_dataSize, ss:[packetSize], ax
		mov	ax, ds:[si].SA_addressSize
		mov	es:[di].DPH_addrSize, al
		add	ax, ss:[info].PI_headerSize
		mov	es:[di].PH_dataOffset, ax
		mov	ax, ss:[info].PI_headerSize
		mov	es:[di].DPH_addrOffset, al
	;
	; initialize the remaining fields
	; the portnums don't need to be initialized for link drivers
	; but its easier to just do it then to check PI_driverType
	;
		mov	al, PacketFlags<0,0,PT_DATAGRAM>		
		mov	cx, flags
		and	cx, mask SSF_OPEN_LINK
		jz	gotFlags
		ornf	al, mask PF_OPEN_LINK
gotFlags:
		mov	es:[di].PH_flags, al
		segmov	es:[di].PH_domain, ss:[info].PI_client, ax
		segmov	es:[di].DPH_localPort, ss:[info].PI_srcPort.SP_port, ax
		segmov	es:[di].DPH_remotePort, ds:[si].SA_port.SP_port, ax
	;
	; copy the address, moving di past the address
	;
copyAddr::
		mov	cx, ds:[si].SA_addressSize
		add	di, ss:[info].PI_headerSize
		push	si
		add	si, offset SA_address
EC <		call	ECCheckMovsb					>
		rep	movsb
		pop	si
	;
	; initialize LinkDataPacket, if needed
	;
initLDP::
		cmp	ss:[info].PI_driverType, SDT_DATA
		je	copyBuffer
		mov	es:[di].LDP_type, LPT_USER_DATA
		mov	es:[di].LDP_offset, size LinkDataPacket
		movdw	es:[di].LDP_source, ss:[info].PI_srcPort, ax
		movdw	es:[di].LDP_dest,  ds:[si].SA_port, ax
		add	di, size LinkDataPacket
	;
	; copy the user's buffer
	;
copyBuffer:
		movdw	dssi, ss:[buffer]
		push	si
		mov	cx, ss:[bufSize]
EC <		call	ECCheckMovsb					>
		rep	movsb
		pop	si
	;
	; unlock packet
	;
		mov	bx, ss:[packet].handle
		call	HugeLMemUnlock
	;
	; call driver
	;
callDriver::
		push	bp
		pushdw	ss:[info].PI_entry
		movdw	dssi, ss:[addressFptr]
		mov	ax, ds:[si].SA_addressSize
		add	si, offset SA_address
		mov	cx, ss:[packetSize]
		mov	bx, ss:[info].PI_client
		movdw	dxbp, ss:[packet]
		mov	di, DR_SOCKET_SEND_DATAGRAM
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	bp
	;
	; check outcome
	;
pastDriver::
		cmc
		jc	done
		cmp	al, SDE_DESTINATION_UNREACHABLE
		jne	notUnreachable
		mov	al, SE_DESTINATION_UNREACHABLE
		jmp	done
notUnreachable:
		cmp	al, SDE_DRIVER_NOT_FOUND
		jne	notDriver
		mov	al, SE_CANT_LOAD_DRIVER
		jmp	done
notDriver:
		cmp	al, SDE_LINK_OPEN_FAILED
		jne	notLink
		mov	al, SE_LINK_FAILED
		jmp	done
notLink:
		mov	ah,al
		mov	al, SE_INTERNAL_ERROR
		clc
done:
		cmc
exit:
		.leave
		ret	@ArgSize
SocketSendDatagram	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketInterruptSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt a SocketSend

CALLED BY:	SocketInterrupt
PASS:		ds:di = SocketInfo
RETURN:		ds:di = same socket (may have moved)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketInterruptSend	proc	near
		uses	bx, si
		.enter
	;
	; find the driver and connection
	;
		mov	bx, ds:[di].SSI_connection.CE_link
		mov	si, ds:[di].SSI_connection.CE_domain
		mov	di, ds:[si]
	;
	; lock driver
	;
		call	SocketGrabMiscLock
		pushdw	ds:[di].DI_entry
		call	SocketControlEndWrite
	;
	; tell it to stop sending
	;
		mov	di, DR_SOCKET_STOP_SEND_DATA
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; release driver
	;
		call	SocketControlStartWrite
		call	SocketReleaseMiscLock
		mov	di, ds:[si]
		
		.leave
		ret
SocketInterruptSend	endp

ExtraApiCode	ends

StrategyCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReceiveConnectionControlPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a connection control packet

CALLED BY:	(INTERNAL) SocketLinkPacket
PASS:		ds	- control segment
		es:di	- SequencedPacketHeader
		bx	- offset of ConnectionControlPacket
		cxdx	- optr to packet
RETURN:		carry	- set to free packet
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
connectionControlTable	nptr.near	\
	ConnectionOpen,
	ConnectionAccept,
	ConnectionBegin,
	ConnectionRefuse,
	ConnectionClose,
	ConnectionCancel

ReceiveConnectionControlPacket	proc	near
		uses	ax,bp
		.enter
	;
	; verify that it is sequenced
	;
EC <		mov	al, es:[di].PH_flags				>
EC <		and	al, mask PF_TYPE				>
EC <		cmp	al, PT_SEQUENCED				>
EC <		ERROR_NE CORRUPT_PACKET					>
	;
	; upgrade our lock, since we will probably need to manipulate
	; chunks to carry out the operation
	;
		call	SocketControlReadToWrite
	;
	; get the ConnectionControlOperation
	;
		mov	al, es:[di][bx].CCP_opcode
		clr	ah
		mov	bp,ax
		call	cs:[connectionControlTable][bp]
	;
	; mark the packet for deletion and exit
	;
		stc
		call	SocketControlWriteToRead
		.leave
		ret
ReceiveConnectionControlPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReceiveLinkDataPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a home for an incoming data packet

CALLED BY:	(INTERNAL) SocketLinkPacket
PASS:		es:di - SequencedPacketHeader
		bx    - offset to LinkDataPacket
		cxdx  - optr to packet
RETURN:		carry set to free packet
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReceiveLinkDataPacket	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		packet		local	optr	push cx,dx
		linkHeader	local	word	push di
		dataHeader	local	word	push bx
		.enter
	;
	; get the control segment
	;
		call	SocketControlStartRead		; ds=control, es=dgroup
	;
	; find the port
	;
findPort::
		movdw	axbx, es:[di][bx].LDP_dest	; destination port
		mov	dx, es:[di].PH_domain		; domain handle
		call	SocketFindPort			; ds:di=PortArrayEntry
EC <		WARNING_C ORPHANED_PACKET			>
		jc	done
	;
	; get the delivery type
	;
getType::
		mov	si,ds:[di].PAE_info		; *ds:si = PortInfo
		mov	di, ss:[linkHeader]		; es:di = PacketHeader
		mov	bx, ss:[dataHeader]
		mov	al, es:[di].PH_flags
		and	al, mask PF_TYPE
		cmp	al, PT_DATAGRAM
		je	findDatagram
	;
	; find the socket for a sequenced packet
	;
findSequenced::
		mov	cx, dx				; *ds:cx = DomainInfo
		mov	dx, es:[di].SPH_link		; link handle
		movdw	axbx, es:[di][bx].LDP_source	; source port
		call	FindSocketByConnection		; *ds:di=SocketInfo
		jnc	findQueue
EC <		WARNING ORPHANED_PACKET			>
		jmp	done				; (carry set to free)
	;
	; find the socket for a datagram packet
	;
findDatagram:
		mov	di, ds:[si]
		mov	di, ds:[di].PI_dgram		; *ds:di=SocketInfo
		tst	di
EC <		WARNING_Z ORPHANED_PACKET			>
		stc					; indicate caller
							;  should free
		jz	done
	;
	; find the data queue
	; any socket found above must have a data queue
	;
findQueue::
		mov	bx, ss:[linkHeader]
		mov	si, ds:[di]			; ds:si = SocketInfo
		movdw	cxdx, ss:[packet]
		ChunkSizePtr	es, bx, ax		; ax <- packet size
							;  for enqueueing
		xchg	bx, cx
		call	HugeLMemUnlock
		xchg	bx, cx

		call	SocketEnqueue
	;
	; wake up any listeners
	;
		mov	bx,di				; *ds:bx = SocketInfo
		call	WakeUpSocket
		clc					; don't free the
							;  packet, please
done:
		call	SocketControlEndRead
		.leave
		ret
ReceiveLinkDataPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReceiveSequencedDataPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a sequenced packet from a data driver

CALLED BY:	(INTERNAL) SocketDataPacket
PASS:		es:di	- SequencedPacketHeader
		cxdx	- optr to packet
		ds	- control segment (locked for read)
RETURN:		carry	- set to free packet
		bxax	- space remaining in queue
DESTROYED:	nothing
SIDE EFFECTS:	
	clear PF_LINK in packet to indicate it came from a data driver

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReceiveSequencedDataPacket	proc	near
		uses	cx,dx,si,di,bp
		packet		local	optr	push cx,dx
		packetSize	local	word
		.enter
		ChunkSizePtr	es,di,ax
		mov	ss:[packetSize], ax
	;
	; clear the link flag
	;
		and	es:[di].PH_flags, not mask PF_LINK
	;
	; get the domain and connection handles
	;
		mov	dx, es:[di].SPH_link
		mov	cx, es:[di].PH_domain
	;
	; find the socket
	;
		call	SocketFindLinkByHandle		; dx = offset of link
		jc	orphan
		mov	di, cx
		mov	di, ds:[di]
		add	di, dx			
		mov	bx, ds:[di].CI_socket
		tst	bx
		jz	orphan
EC <		mov	si,bx						>
EC <		call	ECCheckSocketLow				>
	;
	; unlock the packet
	;
		push	bx
		movdw	cxdx, ss:[packet]
		mov	bx, cx
		call	HugeLMemUnlock
		pop	bx
	;
	; find the data queue
	;
findQueue::
		mov	si, ds:[bx]			; ds:si = SocketInfo
		call	SocketEnqueue			; dxcx  = queue size
	;
	; wake up any listeners
	;
		call	WakeUpSocket
		movdw	bxax, dxcx
		clc
done:
		.leave
		ret
orphan:
		WARNING	ORPHANED_PACKET
		jmp	done
ReceiveSequencedDataPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReceiveDatagramDataPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a datagram packet from a data driver

CALLED BY:	(INTERNAL) SocketDataPacket
PASS:		es:di	- SequencedPacketHeader
		cxdx	- optr to packet
		ds	- control segment (locked for read)
RETURN:		carry	- set to free packet
		bxax	- space remaining in queue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Do not give a warning about orphan packets, since it is quite common
        to receive broadcast TCP packets for which nobody is listening.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReceiveDatagramDataPacket	proc	near
		uses	cx,dx,si,di,bp
		.enter
	;
	; clear the link flag
	;
		and	es:[di].PH_flags, not mask PF_LINK
	;
	; get the portnum
	;
		push	dx
		mov	ax, MANUFACTURER_ID_SOCKET_16BIT_PORT
		mov	bx, es:[di].DPH_localPort
		mov	dx, es:[di].PH_domain
		push	di
		call	SocketFindPort			; ds:di=PortArrayEntry
		pop	bx				; es:bx <- PacketHeader
		pop	dx
		jc	done
	;
	; find the receiver
	;
		mov	si, ds:[di].PAE_info		; *ds:si = PortInfo
		mov	si, ds:[si]			; ds:si = PortInfo
		mov	si, ds:[si].PI_dgram		; *ds:si = SocketInfo
		tst	si
		stc
		jz	done
EC <		call	ECCheckSocketLow				>
	;
	; unlock the packet
	;
		ChunkSizePtr	es, bx, ax		; ax <- packet size
							;  for enqueueing
		mov	bx, cx
		call	HugeLMemUnlock
	;
	; store the packet
	;
		push	si
		mov	si, ds:[si]			; ds:si = SocketInfo
		call	SocketEnqueue
		pop	bx				; *ds:bx <- SocketInfo
							;  for wakeup
		call	WakeUpSocket
		movdw	bxax, dxcx
		clc
done:
		.leave
		ret
ReceiveDatagramDataPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReceiveUrgentDataPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store an urgent packet into a socket

CALLED BY:	(INTERNAL) SocketUrgentData
PASS:		cx	= domain handle
		dx	= connection handle
		bp	= size of data
		if (bp <= 4)
			bxax = zero padded right justified data
		if (bp > 4)
			^lbx:ax = optr to chunk containing data
	
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	use an exclusive lock so we can write SI_urgentData atomicly

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReceiveUrgentDataPacket	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		call	SocketControlStartWrite
EC <		call	ECCheckDomainLow				>
	;
	; find the link
	;
		call	SocketFindLinkByHandle
EC <		WARNING_C ORPHANED_PACKET			>
		jc	cleanup			; throw away this data
	;
	; find the socket
	;
		mov	si, cx
		mov	di, ds:[si]
		add	di, dx
		mov	si, ds:[di].CI_socket
		tst	si
EC <		WARNING_Z ORPHANED_PACKET			>
		jz	cleanup
EC <		call	ECCheckSocketLow				>
	;
	; store data or pointer
	;
		mov	di, ds:[si]
		or	ds:[di].SI_flags, mask SF_EXCEPT
		xchgdw	ds:[di].SSI_urgent, bxax
		xchg	ds:[di].SSI_urgentSize, bp
		mov	bx,si
		call	WakeUpExcept
	;
	; free the urgent data in bxax, whose size is bp
	;
	; this can be the new data, in case of an error, or old data
	; we overwrote in the socket
	;
cleanup:
		cmp	bp,size dword		; is there a chunk?
		jbe	done			; nope, nothing to free
		mov_tr	cx,ax
		mov	ax,bx
		call	HugeLMemFree
done:
		call	SocketControlEndWrite
		.leave
		ret
		
ReceiveUrgentDataPacket	endp

StrategyCode	ends




