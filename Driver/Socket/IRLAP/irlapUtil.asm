COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlapUtil.asm

AUTHOR:		Cody Kwok, Mar 28, 1994

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/28/94   	Initial revision


DESCRIPTION:
	Utility functions for IRLAP-SIR driver.
		

	$Id: irlapUtil.asm,v 1.1 97/04/18 11:56:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapActionCode	segment	resource

; ****************************************************************************
; ****************************************************************************
; ********************      TRANSMITTING PACKETS       ***********************
; ****************************************************************************
; ****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapRecordDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Records information about a data request and returns a
		hugelmem chunk handle for DataRequestParams:

		DataRequestParams	struct
			DRP_dataOffset	word
			DRP_seqInfo	word
			DRP_buffer	optr
		DataRequestParams	ends

		You need to send this structure to IrlapStation event thread
		to send I frames or UI frames.

CALLED BY:	Internal Utility
PASS:		ax   = data offset into the buffer
		bx   = client handle
		cx   = data size
		dxbp = packet buffer chunk
		es   = dgroup
		if socket interface:
			si   = seqInfo
RETURN:		dxbp = hugelmem chunk that holds DataRequestParams
		carry set if memory problem occurred
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapRecordDataRequest	proc	far
		uses	bx,di,ds
		.enter
	;
	; Allocate a DataRequestParams structure
	;
		push	ax, bx, cx
		mov	ax, size DataRequestParams
		mov	bx, es:hugeLMemHandle
		mov	cx, NO_WAIT		; if mem error return
		call	HugeLMemAllocLock	; axcx = optr; dsdi = fptr
		jc	memError
		movdw	ds:[di].DRP_buffer, dxbp
		movdw	dxbp, axcx
		pop	ax, bx, cx
if _SOCKET_INTERFACE
		mov	ds:[di].DRP_seqInfo, si
endif
		mov	ds:[di].DRP_dataOffset, ax
		test	es:[bx].IC_flags, mask ICF_SOCKET
	;
	; Unlock parameter block
	;
		mov_tr	di, bx
		mov	bx, dx
		call	HugeLMemUnlock		
done:
		.leave
		ret
memError:
		pop	ax, bx, cx
		jmp	done
IrlapRecordDataRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapUnwrapDataRequestParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unwraps recorded DataRequest and returns original parameters

CALLED BY:	Internal Utility
PASS:		dxbp = DataRequestParams chunk optr
RETURN:		dxbp = Data packet buffer optr
		si   = data offset
		if socket interface:
			di   = seqInfo
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapUnwrapDataRequestParams	proc	far
		uses	ax, cx, es
		.enter
		movdw	axcx, dxbp
		IrlapLockPacket	esdi, dxbp
		movdw	dxbp, es:[di].DRP_buffer
		mov	si, es:[di].DRP_dataOffset
if _SOCKET_INTERFACE
		mov	di, es:[di].DRP_seqInfo
endif
		IrlapUnlockPacket ax
		call	HugeLMemFree
		.leave
		ret
IrlapUnwrapDataRequestParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSendUFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send Unnumbered frame.
		Characteristics:
			There might be I field

CALLED BY:	Various event handlers
PASS:		ch	= destination address + C/R bit
		cl	= IrlapUnnumberedCommand or
			  IrlapUnnumberedResponse
		bx	= number of bytes in buffer
		es:di	= buffer to send (reserved field + I field )
		ds	= station

	if UI frame,
		bp	= seqInfo

RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSendUFrame	proc	far
		uses	ax,bx,cx
		.enter

EC <		WARNING	_U_FRAME_SENT					>

		mov	ax, cx				; ax = IrLAP header
		mov	cx, ds:IS_serialPort		; bx = serial port
		xchg	cx, bx				; cx = data size
		call	IrlapSendPacket
		
		.leave
		ret
IrlapSendUFrame	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSendIFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send Information frame.
		Characteristics:
			Ns, Nr is included in control field
			There is I field always

CALLED BY:	Various event handling routines
PASS:		cl	= 0 or (mask IICF_PFbit)
			  to indicate whether to clear or set P/F bit
		bx	= number of bytes in buffer
		es:di	= buffer to send
		ds	= station

	If socketLib client:
		bp	= seqInfo

		Irlap performs segmentation for socket library client.
		So, in case of I frames, seqInfo must be inserted between
		IRLAP header and data if we are in socket library client mode.

RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSendIFrame	proc far
		uses	ax,bx,cx
		.enter
EC <		WARNING	_I_FRAME_SENT					>
		mov	al, cl
		or	al, ds:IS_vs
		or	al, ds:IS_vr
		mov	ah, ds:IS_connAddr
		mov	cx, ds:IS_serialPort
		xchg	bx, cx
		call	IrlapSendPacket
		.leave
		ret
IrlapSendIFrame	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSendSFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send Supervisory frame.
		Characteristics:
			Always include Nr.
			No I field.

CALLED BY:	Various event handling routines
PASS:		cl	= IrlapSupervisoryCommand or
			  IrlapSupervisoryResponse
		ds	= station
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSendSFrame	proc	far
		uses	ax,bx,cx
		.enter

EC <		WARNING	_S_FRAME_SENT					>
		mov	al, ds:IS_vr
		or	al, cl				; record Nr
		mov	ah, ds:IS_connAddr
		mov	bx, ds:IS_serialPort
		clr	cx
		call	IrlapSendPacket

		.leave
		ret
IrlapSendSFrame	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSendPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the buffer passed in over serial line, adding CRC at the
		end of transmission.

CALLED BY:	various send packet routines
PASS:		ah = A field (local conn addr shl 1 + CRbit)
		al = C field
		bx = SerialPortNum
		es:di = pointer to I field
		ds    = station
		cx = size of I field

In case of I frame or UI frame(only when socket interface):
		bp = seqInfo

		Irlap performs segmentation for socket library client.
		So, in case of I frames, seqInfo must be inserted between
		IRLAP header and data if we are in socket library client mode.

RETURN:		nothing
DESTROYED:	ax,bx,cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	; SendLoop:
	; GrabPacket from Queue <- not doing this if we use app's thread
	send each byte: BOF first
	send A and C field as escaped buffers,  while adding to checksum
	send I field  as escaped buffers,  while adding to checksum
	calc CRC-CCITT.
	send EOF
	; jmp SendLoop <- not doing this if we use app's thread

	Currently if no packet we'll busy wait

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSendPacketFar proc far
		call	IrlapSendPacket
		ret
IrlapSendPacketFar endp
IrlapSendPacket	proc	near
		uses	cx,dx,di,si,es,bp
		.enter
		push	ds			; save station segment
EC <		cmp	cx, ds:IS_maxIFrameSize				>
EC <		WARNING_G	IRLAP_PACKET_TOO_LARGE			>
EC <		tst	cx						>
EC <		jz	skipTest					>
EC <		call	ECCheckESDI					>
EC < skipTest:								>

	;
	; if in IS_extStatus, IES_MIN_TURNAROUND Is set, we can skip this
	; delay
	;
		test	ds:IS_extStatus, mask IES_MIN_TURNAROUND
		jz	takeDelay
contFromDelay:
	;
	; proceed with the normal business
	;
		mov	dx, es			; save es
		GetDgroup es, si
		push	cx			; size of I field
		push	ax			; Address and Control field
	;
	; Send a begin packet code to start
	;
		clr	ch
		mov	cl, ds:IS_numBof	; extra Bof's to send
		inc	cx
sendAnotherBOF:
		push	cx
		mov	cl, IRLAP_BOF		;cl <- byte to send
		call	IrlapSendByte
		pop	cx
		jc	popExit
		loop	sendAnotherBOF
	;
	; send address and control field,  which is on stack already
	;
		mov	si, sp
		push	ds			; save station segment
		segmov	ds, ss, ax		;DS:SI <- ptr to fields
		mov	ax, IRLAP_PPP_INIT_FCS
	;
	; We want to send address first and then control field.
	;
		mov	cl, {byte}ds:[si]
		xchg	cl, {byte}ds:[si+1]
		xchg	cl, {byte}ds:[si]
		mov	cx, size word
		call	CalcFcs			; ax - FCS
	;
	; Actually send out bytes
	;
		push	dx			; save buffer segment
		mov	dx, size word		;DX <- size of CRC word
		call	WriteEscapedBuffer	; restore buffer segment
		pop	dx
		pop	ds			; restore station segment
		pop	cx			; do a dummy pop
		mov	{byte}ds:IS_cField, ch	; save control field
		pop	cx			; restore I field size
		jc	exit

if _SOCKET_INTERFACE
	;
	; If we are in SocketLib client mode & this is a fragment of larger
	; I frame, send sequence information
	;	bp = seqInfo
	;	ds = station seg
	;
		
	;
	; If we are in socketLib client mode, we also need to worry about
	; segmentation of packets
	;
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jz	nativeClient
		test	{byte}ds:IS_cField, 00000001b ; check for I frame
		jz	iFrame
		and	{byte}ds:IS_cField, not mask IUCF_PFBIT
		cmp	{byte}ds:IS_cField, IUC_UI_CMD
		je	iFrame
		cmp	{byte}ds:IS_cField, IUR_UI_RSP
		jne	nonIFrame
iFrame:
	;
	; This is an I frame, and we are in socket lib client mode.
	; Send one word of seqInfo
	;
		push	dx
		push	bp
		mov_tr	bp, cx			; save cx( size of I field )
		segmov	ds, ss, cx
		mov	si, sp
		mov	cx, size word		;
		call	CalcFcs			; ax - FCS including seqInfo
		mov	dx, size word		; 
		call	WriteEscapedBuffer	; 
		pop	cx			; pop off a dummy word
		mov_tr	cx, bp
		pop	dx
		jc	exit
nonIFrame:
nativeClient:

endif ;_SOCKET_INTERFACE

	;
	; Write out the data: bx = port number
	;
		jcxz	noData
		movdw	dssi, dxdi			; restore I field
		call	CalcFcs				; ax = final crc
		xchg	dx, cx				;dx <- byte counter
		call	WriteEscapedBuffer
		xchg	cx, dx				; restore dx
		jc	exit
noData::
	;
	; Write CRC into frame
	;
		not	ax			; invert final crc
		push	ax	
		segmov	ds, ss, dx		;DS:SI <- ptr to CRC word
		mov	si, sp	
		mov	dx, size word		;DX <- size of CRC word
		call	WriteEscapedBuffer
		pop	ax			; restore stack
		jc	exit

	;
	; Send an end of packet code, bx= stream token
	;
		mov	cl, IRLAP_EOF			;cl <- byte to write
		call	IrlapSendByte
		jc	exit
	;
	; Reduce the priority of the irlap event thread.  This priority
	; is periodically cranked up by a timer routine.
	;
	; No!  We will be blocked when we are idle anyways...
	;  -SJ
	;
	;	clr	bx				;modify current thread
	;	mov	ah, mask TMF_BASE_PRIO
	;	mov	al, PRIORITY_STANDARD
	;	call	ThreadModify			;bx = thread handle
	;
		
exitClr:		
		clc
exit:
		pop	ds			; ds = station segment
	;
	; we re-initialize IS_recvCount here so that we can receive packets
	;
		clr	ds:IS_recvCount
		.leave
		ret
popExit:
		pop	cx, ax
		jmp	exit
takeDelay:
		call	WaitMinimumTurnaroundDelay
		jmp	contFromDelay
IrlapSendPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WaitMinimumTurnaroundDelay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait minimum turnaround delay, so that the remote station
		can be ready for our response in time.

CALLED BY:	various SXfer routines
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WaitMinimumTurnaroundDelay	proc	near
		uses	ax, bx
		.enter
	;
	; mark that we have waited the delay
	;
		BitSet ds:IS_extStatus, IES_MIN_TURNAROUND
	;
	; Sleep for minimum turn around delay
	;
		mov	ax, ds:IS_minTurnAround
		tst	ax
		jz	exit

		call	TimerSleep
exit:
		.leave
		ret
WaitMinimumTurnaroundDelay		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteEscapedBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes out a buffer, after inserting any needed escapes.

CALLED BY:	GLOBAL
PASS:		ds:si - data to send
		dx - # bytes to send
		bx - stream token to write
		es	= dgroup
RETURN:		carry set if error
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteEscapedBuffer	proc	near
	uses	ax, cx, dx, si, ds, bp
	.enter
	;
	; Check the buffer for escapes or end sequences
	;
	clr	cx				;cx <- no bytes since escape
EC <	call	ECCheckDSSI						>
sendLoop:
EC <	call	ECCheckDSSI						>
	mov	al, {byte} ds:[si]
	;
	; IRLAP complement method: write a control escape byte,  then
	; complement the following byte by IRLAP_ESCAPE_COMPLEMENT
	;
	cmp	al, IRLAP_BOF
	je	sendEscape
	cmp	al, IRLAP_EOF
	je	sendEscape
	cmp	al, IRLAP_CONTROL_ESCAPE
	je 	sendEscape

	inc	cx				;cx <- bytes since escape
	inc	si				;ds:si <- ptr to next byte
	dec	dx				;dx <- one less byte to send
	jnz	sendLoop			;branch if more to send
	;
	; Send the bytes we've scanned so far
	;
	sub	si, cx				;ds:si <- ptr to bytes
EC <	call	ECCheckDSSI						>
	call	IrlapWriteBuffer
exit:
	.leave
	ret
sendEscape:
	mov	ah, IRLAP_CONTROL_ESCAPE
	EscapeByte	al
 	xchg	ah, al		; correct byte order
	;
	; Send a special cIaracter (ESC_ESC or ESC_END) and then the
	; complemented char
	;
	push	ax
	;
	; Send any bytes up to the end or escape
	;
	jcxz	noExtraBytes
	sub	si, cx				;ds:si <- ptr to bytes
	call	IrlapWriteBuffer
	jc	popExit

	add	si, cx
noExtraBytes:
	;
	; Send the CONTROL_ESCAPE + complemented char pushed on the stack
	;
	movdw	axbp, dssi		; save dssi
	segmov	ds, ss, cx		;DS:SI <- ptr to the 2 chars
	mov	si, sp	
	mov	cx, size word		;DX <- size of 2 chars
	call	IrlapWriteBuffer
	movdw	dssi, axbp		; restore dssi
	pop	ax			; pop dummy to restore stack
	jc	exit
	;
	; Reset the count of bytes send since the last end escape
	;
	clr	cx				;cx <- reset # of bytes scanned
	inc	si				;ds:si <- next byte
	dec	dx				;dx <- one less byte to send
EC <	ERROR_S	-1							>
	jnz	sendLoop			;branch if no more bytes
	clc
	jmp	exit
popExit:
	pop	cx
	jmp	exit
WriteEscapedBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapWriteBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a buffer of bytes to the serial driver

CALLED BY:	UTILITY
PASS:		ds:si - ptr to bytes to send
		cx - # bytes to send
		bx - stream token
		es	= dgroup
RETURN:		none
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapWriteBuffer		proc	near
	uses	ax, di
	.enter

EC <	push	cx							>
EC <	call	ECCheckDSSI						>
	mov	ax, STREAM_BLOCK
	mov	di, DR_STREAM_WRITE
	call	es:[serialStrategy]
EC <	pop	ax				;ax <- # bytes passed	>
EC <	cmp	ax, cx				;all bytes written?	>
EC <	ERROR_NE IRLAP_SHORT_SERIAL_WRITE				>

	.leave
	ret
IrlapWriteBuffer		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSendByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a byte to the stream

CALLED BY:	
PASS:		cl - byte to send
		bx - stream token
RETURN:		carry - set if (?)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSendByte	proc	near
	uses	ax, di
	.enter
	mov	ax, STREAM_BLOCK
	mov	di, DR_STREAM_WRITE_BYTE
	call	es:[serialStrategy]
	.leave
	ret
IrlapSendByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapWaitForOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait for all the data to be transmitted.  Granularity is
		16.6 ms.
CALLED BY:	ConnectResponseCONN
PASS:		bx	= SerialPortNum
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapWaitForOutput	proc	far
	uses	ax,di
	.enter

	mov	di, DR_STREAM_QUERY
queryLoop:
	mov	ax, STREAM_WRITE
	call	es:[serialStrategy]		;ax = number of bytes
						;  available

	cmp	ax, IRLAP_OUTPUT_BUFFER_SIZE
	je	exit

	mov	ax, 1				;sleep 16.6ms
	call	TimerSleep
	jmp	queryLoop
		
exit:
	mov	ax, 1
	call	TimerSleep	; sleep 16.6ms more to make sure
				; that transmitter is flushed out
	.leave
	ret
IrlapWaitForOutput	endp

if 0
; replaced with STREAM_QUERY method above.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapFlushOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to wait until all the data has been flushed out,
		so we set up a routine to be notified when all the data 
		is gone, block on a semaphore, then nuke the notification
		when the data is all gone.

CALLED BY:	GLOBAL
PASS:		bx 	= SerialPortNum
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapFlushOutput	proc	far
		uses	ax, cx, dx, di, ds, bp
		.enter
		GetDgroup ds, ax
	;
	; Tell the serial driver that we want to be notified whenever the
	; output queue has been flushed (the threshold has already been
	; set in CommOpenPort).
	;
	; Stream notify is set for the writer in which case we will be notified
	; when room is available for writing.
	;
		mov	ax, SNE_DATA shl offset SNT_EVENT or \
			    SNM_ROUTINE shl offset SNT_HOW
		mov	di, DR_STREAM_SET_NOTIFY
		mov	cx, segment NotifyStreamFlushed
		mov	dx, offset NotifyStreamFlushed
		mov	bp, bx
		call	ds:[serialStrategy]
		jc	streamClosed
	;
	; Block until notification
	;
		shl	bx, 1	; bx = offset into irlapFlushSem table
		PSem	ds, <[irlapFlushSem][bx]>, TRASH_AX
		clr	ds:[irlapFlushSem][bx].Sem_value
		shr	bx, 1	; recover SerialPortNum
	;
	; Nuke the notification.
	;
		mov	ax, SNE_DATA shl offset SNT_EVENT or \
			    SNM_NONE shl offset SNT_HOW
		mov	di, DR_STREAM_SET_NOTIFY
		call	ds:[serialStrategy]
		cld
streamClosed:
		.leave
		ret
IrlapFlushOutput	endp
ForceRef	IrlapFlushOutput

endif

fcsTable        label   word
dw      0x0000,0x1189,0x2312,0x329b,0x4624,0x57ad,0x6536,0x74bf
dw      0x8c48,0x9dc1,0xaf5a,0xbed3,0xca6c,0xdbe5,0xe97e,0xf8f7
dw      0x1081,0x0108,0x3393,0x221a,0x56a5,0x472c,0x75b7,0x643e
dw      0x9cc9,0x8d40,0xbfdb,0xae52,0xdaed,0xcb64,0xf9ff,0xe876
dw      0x2102,0x308b,0x0210,0x1399,0x6726,0x76af,0x4434,0x55bd
dw      0xad4a,0xbcc3,0x8e58,0x9fd1,0xeb6e,0xfae7,0xc87c,0xd9f5
dw      0x3183,0x200a,0x1291,0x0318,0x77a7,0x662e,0x54b5,0x453c
dw      0xbdcb,0xac42,0x9ed9,0x8f50,0xfbef,0xea66,0xd8fd,0xc974
dw      0x4204,0x538d,0x6116,0x709f,0x0420,0x15a9,0x2732,0x36bb
dw      0xce4c,0xdfc5,0xed5e,0xfcd7,0x8868,0x99e1,0xab7a,0xbaf3
dw      0x5285,0x430c,0x7197,0x601e,0x14a1,0x0528,0x37b3,0x263a
dw      0xdecd,0xcf44,0xfddf,0xec56,0x98e9,0x8960,0xbbfb,0xaa72
dw      0x6306,0x728f,0x4014,0x519d,0x2522,0x34ab,0x0630,0x17b9
dw      0xef4e,0xfec7,0xcc5c,0xddd5,0xa96a,0xb8e3,0x8a78,0x9bf1
dw      0x7387,0x620e,0x5095,0x411c,0x35a3,0x242a,0x16b1,0x0738
dw      0xffcf,0xee46,0xdcdd,0xcd54,0xb9eb,0xa862,0x9af9,0x8b70
dw      0x8408,0x9581,0xa71a,0xb693,0xc22c,0xd3a5,0xe13e,0xf0b7
dw      0x0840,0x19c9,0x2b52,0x3adb,0x4e64,0x5fed,0x6d76,0x7cff
dw      0x9489,0x8500,0xb79b,0xa612,0xd2ad,0xc324,0xf1bf,0xe036
dw      0x18c1,0x0948,0x3bd3,0x2a5a,0x5ee5,0x4f6c,0x7df7,0x6c7e
dw      0xa50a,0xb483,0x8618,0x9791,0xe32e,0xf2a7,0xc03c,0xd1b5
dw      0x2942,0x38cb,0x0a50,0x1bd9,0x6f66,0x7eef,0x4c74,0x5dfd
dw      0xb58b,0xa402,0x9699,0x8710,0xf3af,0xe226,0xd0bd,0xc134
dw      0x39c3,0x284a,0x1ad1,0x0b58,0x7fe7,0x6e6e,0x5cf5,0x4d7c
dw      0xc60c,0xd785,0xe51e,0xf497,0x8028,0x91a1,0xa33a,0xb2b3
dw      0x4a44,0x5bcd,0x6956,0x78df,0x0c60,0x1de9,0x2f72,0x3efb
dw      0xd68d,0xc704,0xf59f,0xe416,0x90a9,0x8120,0xb3bb,0xa232
dw      0x5ac5,0x4b4c,0x79d7,0x685e,0x1ce1,0x0d68,0x3ff3,0x2e7a
dw      0xe70e,0xf687,0xc41c,0xd595,0xa12a,0xb0a3,0x8238,0x93b1
dw      0x6b46,0x7acf,0x4854,0x59dd,0x2d62,0x3ceb,0x0e70,0x1ff9
dw      0xf78f,0xe606,0xd49d,0xc514,0xb1ab,0xa022,0x92b9,0x8330
dw      0x7bc7,0x6a4e,0x58d5,0x495c,0x3de3,0x2c6a,0x1ef1,0x0f78



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcFcs(V)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate FCS based on IRLAP draft 5.0.

CALLED BY:	HandleDataPacket
PASS:		ax = previous FCS (pass IRLAP_PPP_INIT_FCS if packet is new)
		cx = len of data
		ds:si = data
RETURN:		ax = new fcs
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcFcs		proc	near
		uses	bx, si, cx
		.enter
		jcxz	done
fcsLoop:
		mov	bx, ax
EC <		call	ECCheckDSSI					>
		xor	bl, {byte}ds:[si]
		and	bx, 0xff
		inc	si			; bx = fcs.low ^ *data++
		shl	bx, 1			; get size word
		mov	al, ah			; (fcs>>8)
		clr	ah
		xor	ax, cs:fcsTable[bx]
		loop	fcsLoop
done:
		.leave
		ret
CalcFcs		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapCheckMediaBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if physical medium is in use by anyone.
IMPORTANT:	This should not called by Server thread.
CALLED BY:	Utility
PASS:		ds - station
		es - dgroup
RETURN:		carry - set if busy
			clear if not busy
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
	Clear ISS_MEDIA_BUSY flag
	sleep for 500ms
	See if ISS_MEDIA_BUSY flag was set by IrlapRecv

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/24/94    	Initial version
	SJ	3/14/95		Changed it to use flag
				It's been one year! :)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapCheckMediaBusy	proc	far
		uses	ax, bx
		.enter
	;
	; check last time we received something
	;
		call	TimerGetCount	; bxax <- sys counter
		subdw	bxax, ds:IS_lastReceiptTime
		tst	bx
		jnz	done
		cmp	ax, IRLAP_CHECK_BUSY_TICKS
		jb	doneC
		clc
done:
		.leave
		ret
doneC:
		stc
		jmp	done
IrlapCheckMediaBusy	endp


; **************************************************************************
; **************************************************************************
; *********************      RECEIVING PACKETS      ************************
; **************************************************************************
; **************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleDataPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab bytes from port, and construct a valid IrLAP frame
CALLED BY:	IrlapRecv
PASS:		ds	= station
RETURN:		carry set on error
			ax = error condition ( IrlapCondition )
		carry clear if returning a valid frame
			^ldx:si	= HugeLMem buffer of SequencedPacketHeader
				followed by the I field of frame, organized 
				as follows:

				1. Address (A) and Control (C) bytes are 
				stored 	in SPH_link.  
				2. PH_dataOffset is the offset to the byte 
				after the C byte (normally, the start of the 
				I field).
				3. PH_dataSize is the number of bytes in 
				the buffer following PH_dataOffset, which
				is also the size of the I field.
			
					-CHL 10/26/95

			ah	= address field
			al	= control field
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/15/95    	Rewritten

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleDataPacket	proc	far
		header		local	word
		buffHandle	local	optr
		buffStart	local	word
		uses	bx,cx,di,es,ds
		.enter
	;
	; P IS_serialSem
	;
		mov	bx, ds:IS_serialSem
		call	ThreadPSem		; ax trashed
	;
	; initialize local variable
	;
		clr	ax
		mov	buffHandle.high, ax
		mov	buffHandle.low, ax
	;
	; Process frame header
	;
		mov	bx, ds:IS_serialPort
		mov	si, DR_STREAM_READ_BYTE
		call	ProcessFrameHeader
		jc	error
	;
	; Returned from ProcessFrameHeader:
	; 	buffHandle	= HugeLMem optr to buffer.
	; 	header.high 	= address (A) byte
	;	header.low	= control (C) byte
	;	es:di		= locked HugeLMem data buffer, pointing
	;			right after A and C bytes.
	;	buffStart	= offset of A field (initially 2 bytes
	;			before di)
	;	cx		= remaining bytes in es:di
	;				
	; CHL 10/25/95

	; Invariant:		
	;	bx    = serial port #	
	;	cx    = remaining buffer size
	;	si    = DR_STREAM_READ_BYTE
	;	es:di = data buffer
	;	ds    = station
	;
readByte:
		test	ds:IS_status, mask ISS_GOING_AWAY
		jnz	shutdown
		xchg	si, di
		mov	ax, STREAM_BLOCK
		call	ds:IS_serialStrategy	; al = char read
		xchg	si, di
		jc	shutdown
	;
	; check for special byte
	;
		cmp	al, IRLAP_CONTROL_ESCAPE
		je	escapeByte
		cmp	al, IRLAP_BOF
		je	frameError
		cmp	al, IRLAP_EOF
		je	checkSum
cont:
	;
	; Store the byte read
	;
		tst	cx
		jz	frameTooBig
		dec	cx			; bufferSize--
		stosb				; di adjusted
		jmp	readByte
escapeByte:
	;
	; bx = port number
	; si = DR_STREAM_READ_BYTE
	;
		test	ds:IS_status, mask ISS_GOING_AWAY
		jnz	shutdown
		xchg	si, di
		mov	ax, STREAM_BLOCK
		call	ds:IS_serialStrategy	; al = char read
		xchg	si, di
		jc	shutdown
		EscapeByte al			; carry clear
		jmp	cont
checkSum:
	;
	; Check for too small a packet
	;
		sub	di, 2			; exclude checksum
		mov	si, buffStart
		cmp	di, si
		jbe	frameTooSmall
	;
	; Prepare
	;
		mov	ax, IRLAP_PPP_INIT_FCS	; ax = init fcs
		mov	cx, di			; cx = buffEnd
		sub	cx, si			;      - buffStart
	;
	; Compute Checksum
	;	ax   = prev FCS
	;	cx   = len of data
	;       es:si= data
	;
		push	ds
		segmov	ds, es, bx		; ds:si = data received
		add	cx, 2			; cx includes FCS
		call	CalcFcs			; ax = new fcs
		sub	cx, 2			; cx excludes FCS
		pop	ds			; ds = station
		cmp	ax, IRLAP_PPP_GOOD_FCS	; cmp with GOOD_FCS
		jne	corruptCrc
	;
	; Prepare return values
	;
		mov	ax, header		; al = ctrl , ah = addr
		mov	dx, buffHandle.high
		mov	si, buffHandle.low
		mov	di, es:[si]		; deref data packet -> es:di
		sub	cx, size word		; exclude 2 byte IrLAP header
		mov	es:[di].PH_dataSize, cx	; store data size
		mov	es:[di].PH_dataOffset, IRLAP_SOCKET_HEADER_SIZE
	;
	; Unlock packet
	;
		mov	bx, dx
		call	HugeLMemUnlock
		jmp	exitNC
exitC:
	;
	; ax      = error code
	; dx = si = 0
	;
		stc
		jmp	exit
exitNC:
	;
	; ah      = conn addr
	; al      = control byte
	; ^ldx:si = hugelmem data buffer
	;
		clc
exit:
	;
	; Record the time this was received
	;
		push	ax, bx
		call	TimerGetCount		; bxax = sys counter
		movdw	ds:IS_lastReceiptTime, bxax
		pop	ax, bx
	;
	; V IS_serialSem
	;
		mov_tr	di, ax
		mov	bx, ds:IS_serialSem
		call	ThreadVSem		   ; ax trashed
		mov_tr	ax, di
		.leave
		ret
corruptCrc:
EC <		WARNING	IRLAP_CRC_CORRUPT_PACKET			>
		mov	ax, IC_CRC_CORRUPT_FRAME
		jmp	error
frameError:
		mov	ax, IC_BAD_FRAMING
		jmp	error
frameTooSmall:
EC <		WARNING	IRLAP_PACKET_TOO_SMALL				>
		mov	ax, IC_FRAME_TOO_SMALL
		jmp	error
frameTooBig:
EC <		WARNING	IRLAP_PACKET_TOO_LARGE				>
		mov	ax, IC_FRAME_TOO_LARGE
		jmp	error
shutdown:
EC <		WARNING	IRLAP_STREAM_CLOSING
		mov	ax, IC_PORT_CLOSED
error:
	;
	; ax = ErrorCode
	;
		movdw	dxsi, buffHandle
		tst	dx
		jz	exitC
	;
	; We need to unlock and free packet buffer
	;
		push	ax			; save error code
		mov	bx, dx
		call	HugeLMemUnlock
		movdw	axcx, dxsi
		call	HugeLMemFree
		clr	dx, si
		pop	ax
		jmp	exitC
		
HandleDataPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessFrameHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads connection address and control byte of IrLAP header,
		and allocate a buffer for the rest of the packet.

CALLED BY:	HandleDataPacket
PASS:		ds	= station
		bx	= serial port to read from
		si	= DR_STREAM_READ_BYTE
		ss:bp	= inherited frame
				header
				buffHandle
				buffStart

RETURN:		carry set if error
			ax = error code
		carry clear if ok
			header.high = connAddr (C byte)
			header.low  = control field (A byte)

			es:di = locked HugeLMem data buffer, pointing right
				after A and C bytes.
			buffStart = offset of A field. (initially 2 bytes 
				before di)

			cx = remaining # of bytes in es:di

DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessFrameHeader	proc	near
		uses	bx,dx,si
		.enter	inherit HandleDataPacket
	;
	; Read address
	;
getAnother:
		test	ds:IS_status, mask ISS_GOING_AWAY
		jnz	shutdown
		GetEscapedByteAL	; al = conn address
		jc	shutdown
		jz	escapedByte
		cmp	al, IRLAP_EOF	; if 0xC1 was escaped, it cannot be the
		je	aborted		; end flag, so we just accept it as
escapedByte:				; normal data that happened to be 0xC1.
		cmp	al, IRLAP_BOF
		je	getAnother
	;
	; check address
	;
		mov	header.high, al	; header.high = connAddr
		mov	ds:IS_lastCField.high, al; store recv'd frame's address
		BitClr	al, IAF_CRBIT
		cmp	al, IRLAP_BROADCAST_CONNECTION_ADDR
		je	proceed
		mov	ah, ds:IS_connAddr
		BitClr	ah, IAF_CRBIT
		cmp	al, ah
		jne	misdelivered
proceed:
	;
	; Read control byte
	;
		test	ds:IS_status, mask ISS_GOING_AWAY
		jnz	shutdown
		GetEscapedByteAL		; al = control byte
		jc	shutdown
	;
	; Store control byte
	;
		mov	header.low, al		; header.low =  control byte
		mov	ds:IS_lastCField.low, al; store c field of recv'd frame
	;
	; Get appropriate buffer size
	;
		test	al, 00000001b
		jz	iframe
		test	al, 00000010b
		jnz	uframe
		mov	ax, IRLAP_S_FRAME_MAX_SIZE	; s frame
allocBuff:
	;
	; ax = buffer size
	; ds = station
	;
EC <		IrlapCheckStation ds					>
		push	ax, ds
		mov	bx, ds:IS_hugeLMemHandle
		clr	cx				; no wait
EC <		tst	ax						>
EC <		ERROR_Z	IRLAP_GENERAL_FAILURE				>
		call	HugeLMemAllocLock	;ds:di = buffer
						;^lax:cx = buffer (HugeLMem)
		movdw	buffHandle, axcx
		segmov	es, ds, ax		;es:di = fptr 
		pop	cx, ds			;cx = available buffer size
						;ds = station
		jc	memoryError
	;
	; Prepare return args
	;
		mov	es:[di].PH_dataOffset, IRLAP_SOCKET_HEADER_SIZE
	;
	; See if the frame is UI frame
	;
		mov	al, header.low
		BitClr	al, IUCF_PFBIT
		cmp	al, IUC_UI_CMD
		jne	notExpeditedIFrame
	;
	; See if the frame is expedited I frame
	;
		clr	es:[di].PH_reserved
		mov	al, header.high
		BitClr	al, IAF_CRBIT
		cmp	al, IRLAP_BROADCAST_CONNECTION_ADDR
		je	notExpeditedIFrame
	;
	; This frame is expedited I frame
	;
		BitSet	es:[di].PH_reserved, IDRT_EXPEDITED

notExpeditedIFrame:
	;
	; Why does the [A|C] word go into SPH_link?  -CHL 10/25/95
	; Answer: That's where it goes, since the space allocated
	;         shouldn't include the A and C bytes.
	;		
		add	di, offset SPH_link
		mov	buffStart, di		; start of data buffer
	;
	; Store A and C bytes in SPH_link, which is the last field
	; of SequencedPacketHeader.
	; 
		mov	ax, header		
		xchg	al, ah
		stosw				; di adjusted

	;
	; Adjust cx = number of free bytes in es:di
	;
		sub	cx, IRLAP_SOCKET_HEADER_SIZE
		clc
done:
		.leave
		ret
iframe:	
	;
	; i frame == [socket header][A|C][seqInfo][idata][CRC]. 
	;
	; Notes: 
	;	1. If there is no socket interface, we don't need [seqInfo].
	; 	2. A and C actually go into SPH_link, so we don't need to
	; 	   allocate extra space for it.
	; -CHL 10/25/95
	;
		mov	ax, ds:IS_maxIFrameSizeIn	;ax = data size
		add	ax, IRLAP_SOCKET_HEADER_SIZE + size word
							;add header and CRC.
if _SOCKET_INTERFACE
	;
	; add room for [seqInfo]
	;
		add	ax, size word
endif
		jmp	allocBuff

uframe:
	;
	; Check first for UI (Unnumbered Information) frames, which contain
	; an I field, and thus have the same size as I frames.
	;
		cmp	al, 00000011b
		je	iframe				; ui frame
		cmp	al, 00010011b
		je	iframe				; ui frame
		cmp	al, 11110011b
		je	iframe				; test frame
		cmp	al, 11100011b
		je	iframe				; test frame
		mov	ax, IRLAP_U_FRAME_MAX_SIZE
		jmp	allocBuff

shutdown:
EC <		WARNING IRLAP_STREAM_CLOSING				>
		mov	ax, IC_PORT_CLOSED
		jmp	done
misdelivered:
EC <		WARNING	IRLAP_MISDELIVERY				>
		mov	ax, IC_MISDELIVERED_FRAME
		stc
		jmp	done
aborted:
EC <		WARNING	IRLAP_PACKET_ABORTED				>
		mov	ax, IC_FRAME_ABORTED
		stc
		jmp	done
memoryError:
EC <		WARNING	IRLAP_MEM_ALLOC_ERROR				>
		mov	buffHandle.high, 0
		mov	buffHandle.low, 0
		mov	ax, IC_INSUFFICIENT_MEMORY
		stc		; frames are ignored when insufficient memory
		jmp	done
ProcessFrameHeader	endp



; ***************************************************************************
; ***************************************************************************
; ********************     User Notification Utility    *********************
; ***************************************************************************
; ***************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a message dialog on screen

CALLED BY:	Utility
PASS:		ax	= CustomDialogBoxFlags
		si	= chunk handle of string in IrlapStrings resource
RETURN:		nothing
DESTROYED:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/23/93		Initial version
	SJ	9/28/93		Stole

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayMessage	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		params	local	GenAppDoDialogParams
		.enter
	; do a warning

		mov	params.GADDP_dialog.SDP_customFlags, ax
		clr	bx
		clrdw	params.GADDP_dialog.SDP_stringArg1, bx
		clrdw	params.GADDP_dialog.SDP_stringArg2, bx
		clrdw	params.GADDP_dialog.SDP_customTriggers, bx
		clrdw	params.GADDP_dialog.SDP_helpContext, bx
		clrdw	params.GADDP_finishOD, bx
		mov	bx, handle IrlapStrings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]
		movdw	params.GADDP_dialog.SDP_customString, dssi

		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo
		mov_tr	bx, ax
		tst	bx
		jz	noNotify
		call	GeodeGetAppObject
	
		mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		mov	dx, size GenAppDoDialogParams
		mov	di, mask MF_CALL or mask MF_STACK
		push	bp
		lea	bp, params
		call	ObjMessage
		pop	bp
noNotify:
		mov	bx, handle IrlapStrings
		call	MemUnlock
		.leave
		ret
DisplayMessage	endp



; ***************************************************************************
; ***************************************************************************
; ********************     Miscellanous Utilities      **********************
; ***************************************************************************
; ***************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapFindSocketClient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the IrlapClient entry for socket library

CALLED BY:	Utility
PASS:		es	= dgroup
RETURN:		si	= clint handle for socket library
		es:si   = IrlapClient structure
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapFindSocketClient	proc	far
		uses	cx
		.enter
		mov	si, offset irlapClientTable
		mov	cx, IRLAP_MAX_NUM_CLIENTS
checkLoop:
		test	es:[si].IC_flags, mask ICF_ACTIVE
		jz	notFound
		test	es:[si].IC_flags, mask ICF_SOCKET
		jz	notFound
		clc
		jmp	done
notFound:
		loop	checkLoop
		stc
done:
		.leave
		ret
IrlapFindSocketClient	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapGenerateRandomAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates a 32bit random number

CALLED BY:	Various discovery routines
PASS:		nothing  (es:[randomSeed] should be initialized)
RETURN:		dx.ax = 32bit random number
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapGenerateRandom32	proc	far
	.enter
generateAddr:
	mov	dl, 255		; 2^8=256
	call	IrlapGenerateRandom8
	mov	al, dl
	mov	dl, 255
	call	IrlapGenerateRandom8
	mov	ah, dl
	mov	dl, 255
	call	IrlapGenerateRandom8
	mov	dh, dl
	mov	dl, 255
	call	IrlapGenerateRandom8
	tstdw	dxax				; make sure it isn't null
	jz	generateAddr	
	cmpdw	dxax, IRLAP_BROADCAST_DEV_ADDR	; make sure it isn't broadcast
	je	generateAddr
	.leave
	ret
IrlapGenerateRandom32	endp
ForceRef	IrlapGenerateRandom32

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			IrlapGenerateRandom8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a 8 bit random number between 0 and DL

CALLED BY:	
PASS:		DL	= max for returned number
RETURN:		DL	= number between 0 and DL
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This random number generator is not a very good one; it is sufficient
	for a wide range of tasks requiring random numbers (it will work
	fine for shuffling, etc.), but if either the "randomness" or the
	distribution of the random numbers is crucial, you may want to look
	elsewhere.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/11/89		Initial version
	jon	10/90		Customized for GameClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapGenerateRandom8	proc	far
		uses	ax, bx, cx, es
		.enter
		tst	dl
		jz	done
		GetDgroup es, ax
		mov	cx, dx
		mov	ax, es:[randomSeed]
		mov	dx, 4e6dh
		mul	dx
		mov	es:[randomSeed], ax
		sar	dx, 1
		ror	ax, 1
		sar	dx, 1
		ror	ax, 1
		sar	dx, 1
		ror	ax, 1
		sar	dx, 1
		ror	ax, 1
		push	ax
		mov	al, 255
		mul	cl
		mov	dx, ax
		pop	ax
Random2:
		sub	ax, dx
		ja	Random2
		add	ax, dx
		div	cl
		clr	dx
		mov	dl, ah
done:
		.leave
		ret
IrlapGenerateRandom8	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapGenConnAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	generate 7-bit connection addr

CALLED BY:	IrlapConnectRequest
PASS:		nothing
RETURN:		dl = addr
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapGenConnAddr	proc	far
	.enter
genConnAddr:
	mov	dl, 0xff		; generate full byte
	call	IrlapGenerateRandom8
	shr	dl, 1			; mod 2 = 7 bit #
	;
	; Don't generate reserved addr
	;
	cmp	dl, IRLAP_NULL_CONNECTION_ADDR
	je	genConnAddr
	cmp	dl, IRLAP_BROADCAST_CONNECTION_ADDR
	je	genConnAddr
	.leave
	ret
IrlapGenConnAddr	endp

if _SOCKET_INTERFACE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DuplicateDataBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicates a hugelmem buffer

CALLED BY:	ResendUnackedFrames
PASS:		ax	= data offset
		cx	= data size
		dxbp	= source hugelmem buffer
RETURN:		dxbp	= new duplicated hugelmem buffer that contains
		          the data
			  ( so, dataOffset is 0, and data size is the same as
			    the buffer size )
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DuplicateDataBuffer	proc	far
		uses	ax,bx,cx,si,di,ds,es
		.enter
	;
	; Allocate a new hugelmem buffer for data
	;
		GetDgroup ds, di
		pushdw	axcx				; save data offset&size
		mov_tr	ax, cx
		mov	bx, ds:hugeLMemHandle		; bx = hugelmem handle
		mov	cx, NO_WAIT
		call	HugeLMemAllocLock		; ^lax:cx = optr
		jc	abortPop			; ds:di = new buffer
	;
	; Lock the old buffer
	;
		mov	bx, dx				; bx = old buffer block
		mov_tr	dx, ax				; dx = new buffer block
		call	HugeLMemLock			; ax = old buffer seg
		mov	es, ax				; es = old buffer seg
		mov	si, es:[bp]			; deref old buffer
		mov	bp, cx				; dxbp = new buff optr
		push	ds, es				; ds:si = old buffer
		pop	es, ds				; es:di = new buffer
		popdw	axcx				; cx = data size
		add	si, ax				; add dataOffset(ax)
		shr	cx, 1
		jnc	cxEven
		movsb
cxEven:
		rep	movsw
		clc
unlockBuffers:
	;
	; Unlock buffers
	;
		call	HugeLMemUnlock			; unlock old buffer
		mov	bx, dx
		call	HugeLMemUnlock			; unlock new buffer
	;
	; Carry set if memory problem; carry flag preserved 
	;
		.leave
		ret
abortPop:
		popdw	axcx				; carry is set
		jmp	unlockBuffers
DuplicateDataBuffer	endp

endif	; _SOCKET_INTERFACE

;---------------------------------------------------------------------------
;
; Processing urgent message
;
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapPostUrgentEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maintains a queue of urgent messages
		Events that are most recently sent are considered to be the
		most urgent.

		ATTENTION!!

		Since I have some extra space reserved in IrlapWindowArray,
		I will use that as urgent event queue.  So, urgent events
		are stored in IW_extended.EIW_urgentEvent field.  And queue
		is just a circular buffer used for IS_store.  Sorry about
		this.

CALLED BY:	Utility
PASS:		bx	 = destination thread handle
		ax	 = event code
		ds	 = station segement
		cx,dx,bp = event words
RETURN:		carry set if UrgentEvent stack is full
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapPostUrgentEvent	proc	far
		uses	bx, ax, di
		.enter
	;
	; Record event
	;
		mov	di, mask MF_RECORD
		call	ObjMessage		; di = recorded event
	;
	; Post the event if room is available
	;
		clr	bh
		mov	bl, ds:IS_urgentQueueEnd
		test	ds:[IS_store][bx].IW_flags, mask IWF_URGENT_EVENT
		jz	postIt
		stc
finish:
		.leave
		ret
postIt:
		BitSet	ds:[IS_store][bx].IW_flags, IWF_URGENT_EVENT
		mov	ds:[IS_store][bx].IW_extended.EIW_urgentEvent, di
		add	bl, IrlapWindowIndexInc
		and	bl, IrlapWindowIndexRange
		mov	ds:IS_urgentQueueEnd, bl
	;
	; Send a dummy event so that the urgent event posted is actually
	; checked in IrlapEventLoop
	;
		mov	bx, ds:IS_eventThreadHandle
		mov	ah, ILE_CONTROL
		mov	al, IDC_CHECK_STORED_EVENTS
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		clc
		jmp	finish
IrlapPostUrgentEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapGetUrgentEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an urgent event from urgent event queue(IS_store)
		Urgent events are first in first out in this queue but
		the most recent event will be handled first because of the
		way Irlap event handling system works.

CALLED BY:	Utility
PASS:		ds	= station segment
RETURN:		ax	= event
		carry set if urgent event stack is empty
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapGetUrgentEvent	proc	far
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; If no more urgent event, return carry set
	;
		clr	bh
		mov	bl, ds:IS_urgentQueueFront
		test	ds:[IS_store][bx].IW_flags, mask IWF_URGENT_EVENT
		stc
		jz	done_C
	;
	; Get event and update current front
	;
		BitClr	ds:[IS_store][bx].IW_flags, IWF_URGENT_EVENT
		mov	ax, ds:[IS_store][bx].IW_extended.EIW_urgentEvent
		add	bl, IrlapWindowIndexInc
		and	bl, IrlapWindowIndexRange
		mov	ds:IS_urgentQueueFront, bl
		clc
done_C:
		.leave
		ret
IrlapGetUrgentEvent	endp

IrlapActionCode		ends

IrlapResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapBusyClearCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HugeLMem says it has plenty of free space now

CALLED BY:	hugelmem::FreeSpaceAvailable
PASS:		ax	= irlap station segment
RETURN:		nothing
DESTROYED:	nothing		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapBusyClearCallback	proc	far
		uses	ds
		.enter
		mov	ds, ax
		call	IrlapBusyCleared
		.leave
		ret
IrlapBusyClearCallback	endp

IrlapResidentCode	ends
