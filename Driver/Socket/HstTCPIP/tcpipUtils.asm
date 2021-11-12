COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		
FILE:		tcpipUtils.asm

AUTHOR:		Jennifer Wu, Jul 14, 1994

ROUTINES:
	Name			Description
	----			-----------
	TcpipAllocDataBuffer	Allocate a data buffer with space
				reserved for headers

	TcpipDupDataBuffer	Copy a data buffer

	TcpipFreeDataBuffer	Free a data buffer

	TcpipLock		Lock/unlock a data buffer
	TcpipUnlock
	
	Checksum		Compute the 16-bit ones complement
				of 16-bit ones complement sum
	
	HostToNetworkWord
	HostToNetworkDWord
	NetworkToHostWord
	NetworkToHostDWord

	TcpipDequeuePacket	Get a packet from the input queue

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial revision

DESCRIPTION:
	Utility routines for TCP/IP driver.  (C stubs)

	$Id: tcpipUtils.asm,v 1.1 97/04/18 11:57:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource

SetGeosConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TcpipAllocDataBuffer

DESCRIPTION:	Allocate a data buffer of the requested size with
		addition space for the packet header and reserved
		space required by the link for the given socket.

C DECLARATION:	extern optr  _far 
		_far _pascal TcpipAllocDataBuffer (word bufferSize,
						   word link);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
TCPIPALLOCDATABUFFER	proc	far	bufferSize:word,
					link:word
		uses	si, di, ds
		.enter
	;
	; Determine how much reserved space is required for 
	; the link header used by this socket.
	;		
		mov	bx, link			; bx = link domain han
		call	LinkTableGetEntry		; ds:di = LCB
							; ^hbx = link table
		clr	ah
		mov	al, ds:[di].LCB_minHdr 		; ax = reserved space
		mov	si, ds:[di].LCB_clientHan
		call	MemUnlockExcl			; unlock link table
	;
	; Compute actual size of data buffer and allocate the space
	; in the HugeLMem block.
	;		
		push	ax				; save reserved space
		add	ax, bufferSize			; ax = total buffer size
		
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[hugeLMemBlock]
		mov	cx, HUGELMEM_ALLOC_WAIT_TIME
		call	HugeLMemAllocLock		; ^lax:cx = new buffer
							; ds:di = new buffer
		pop	bx				; bx = reserved space
		jc	error
	;
	; Fill in header information.
	;
		mov	ds:[di].SPH_common.PH_flags, PacketFlags\
					 <0, 0, PT_SEQUENCED>
		
		mov	ds:[di].SPH_common.PH_dataOffset, bx
		
		mov	bx, bufferSize
		mov	ds:[di].SPH_common.PH_dataSize, bx
		
		mov	ds:[di].SPH_common.PH_domain, si
	; 
	;
	; Unlock the hugeLMem chunk and set up the return values.
	;
		mov_tr	bx, ax				; ^lbx:cx = new buffer
		call	HugeLMemUnlock
		movdw	dxax, bxcx			; return new buffer
exit:		
		.leave
		ret
error:
		clrdw	dxax				; return 0
		jmp	short exit

TCPIPALLOCDATABUFFER	endp


COMMENT @----------------------------------------------------------------

C FUNCTION:	TcpipDupDataBuffer

DESCRIPTION:	Copy a data buffer.

C DECLARATION:	extern optr  _far 
		_far _pascal TcpipDupDataBuffer (fptr buffer,
						   word extraSize);
		Returned optr is locked.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/98	Initial version
-------------------------------------------------------------------------@

ifdef MERGE_TCP_SEGMENTS

TCPIPDUPDATABUFFER	proc	far	buffer:fptr,
					extraSize:word
		uses	si, di, ds, es
		.enter
	;
	; Compute actual size of data buffer and allocate the space
	; in the HugeLMem block.
	;
		movdw	dssi, buffer
		ChunkSizePtr	ds, si, ax
		mov	dx, ax
		add	ax, extraSize		; ax = total buffer size
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[hugeLMemBlock]
		mov	cx, 0			; don't wait at all
		call	HugeLMemAllocLock		; ^lax:cx = new buffer
							; ds:di = new buffer
		jc	error
	;
	; Copy everything from passed buffer
	;
		xchg	cx, dx				; ^lax:dx = new buffer
							; cx = passed buffer size
		segmov	es, ds, si			; es:di = new buffer
		movdw	dssi, buffer			; ds:si = passed buffer
		rep	movsb
	;
	; Leave buffer locked, set up the return values.
	;
		xchg	ax, dx				; return new buffer
exit:		
		.leave
		ret
error:
		clrdw	dxax				; return 0
		jmp	short exit

TCPIPDUPDATABUFFER	endp

endif


COMMENT @----------------------------------------------------------------

C FUNCTION:	TcpipFreeDataBuffer

DESCRIPTION:	Free the data buffer using HugeLMemFree as all data
		buffers are HugeLMem chunks.

C DECLARATION:	extern void _far *
		_far _pascal TcpipFreeDataBuffer (optr buffer);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@

TCPIPFREEDATABUFFER	proc	far	
		C_GetOneDWordArg ax, cx, bx, dx
		call	HugeLMemFree
		ret
TCPIPFREEDATABUFFER	endp


COMMENT @----------------------------------------------------------------

C FUNCTION:	TcpipLock

DESCRIPTION:	Lock the data buffer.

C DECLARATION:	extern void _far
		_far _pascal TcpipLock (MemHandle mh);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@

TCPIPLOCK		proc	far		
		C_GetOneWordArg bx, ax, cx		
		call	HugeLMemLock
		ret
TCPIPLOCK		endp


COMMENT @----------------------------------------------------------------

C FUNCTION:	TcpipUnlock

DESCRIPTION:	Unlock the data buffer.

C DECLARATION:	extern void _far
		_far _pascal TcpipUnlock(MemHandle mh);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@

TCPIPUNLOCK	proc	far		
		C_GetOneWordArg bx, ax, cx
		call	HugeLMemUnlock
		ret		
TCPIPUNLOCK	endp


COMMENT @----------------------------------------------------------------

C FUNCTION:	Checksum

DESCRIPTION:	Compute the 16-bit ones complement of 16-bit ones
		complement sum.

C DECLARATION:	extern word _far
		_far _pascal Checksum(word *buffer, word nbytes);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@

CHECKSUM	proc	far	buffer:fptr.word,
				nbytes:word
		uses	si, ds
		.enter

		lds	si, buffer			; ds:si = data
		clr	ax				; initialize sum
		mov	cx, nbytes
		shr	cx, 1				; num words
		pushf					
cksumLoop:
		add	ax, {word}ds:[si]
		jnc	cont
		inc	ax				; add in carry
cont:
		inc	si
		inc	si				; ds:si = next word
		loop	cksumLoop
		popf
		
		jnc	complement
	;
	; Add in the odd byte with a zero pad byte at the end. (network order)
	;
		mov	cl, {byte}ds:[si]
		clr	ch				; zero pad byte
		add	ax, cx
		jnc	complement
		inc	ax				; add in carry
complement:
		not	ax				; complement sum
		
		.leave
		ret
		
CHECKSUM	endp


COMMENT @----------------------------------------------------------------

C FUNCTION:	NetworkToHostWord (Also HostToNetworkWord)

DESCRIPTION:	Convert a 16-bit word from the network format to 
		our host format. (or vice versa)

C DECLARATION:	extern word _far
		_far _pascal NetworkToHostWord(word value);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@

NETWORKTOHOSTWORD	proc	far	
		C_GetOneWordArg	ax, bx, cx
		xchg	ah, al
		ret
NETWORKTOHOSTWORD	endp


COMMENT @----------------------------------------------------------------

C FUNCTION:	NetworkToHostDWord  (Also HostToNetworkDWord)

DESCRIPTION:	Convert a 32-bit word from the network format to 
		our host format. (or vice versa)

C DECLARATION:	extern dword _far
		_far _pascal NetworkToHostDWord(dword value);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@

NETWORKTOHOSTDWORD	proc	far	
		C_GetOneDWordArg ax, dx, cx, bx	; swaps high and low words
		xchg	ah, al			; swap bytes in low word
		xchg	dh, dl			; swap bytes in high word
		ret
NETWORKTOHOSTDWORD	endp

COMMENT @----------------------------------------------------------------

C FUNCTION:	TcpipDequeuePacket

DESCRIPTION:	Get a packet from the input queue.  If more packets 
		in queue, queues another message for driver thread
		to keep processing input.

C DECLARATION:	extern optr _far
			_pascal TcpipDequeuePacket(void);

STRATEGY:
		Take advantage of dgroup being DS as we are called
		from C code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
TCPIPDEQUEUEPACKET	proc	far

		uses	di, si, ds
		.enter
	;
	; Get a packet.
	;
		segmov	es, ds, cx			; es = dgroup
		movdw	bxsi, es:[inputQueue]
		mov	cx, NO_WAIT
		call	QueueDequeueLock		; ds:di = front element
		jc	none

		movdw	dxax, ds:[di]			; ^ldx:ax = buffer
		call	QueueDequeueUnlock
	;
	; Queue another message if more packets.
	;
		push	dx
		call	QueueNumEnqueues		; cx = number
		pop	dx
		jcxz	exit			

		push	ax
		mov	bx, es:[driverThread]		
		Assert	thread	bx					
		mov	ax, MSG_TCPIP_RECEIVE_DATA_ASM
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	ax
		jmp	exit
none:
		clr	dx, ax
exit:
		.leave
		ret

TCPIPDEQUEUEPACKET	endp

SetDefaultConvention

CommonCode	ends


