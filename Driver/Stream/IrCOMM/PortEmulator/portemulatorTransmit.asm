COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrCOMM
FILE:		portemulatorTransmit.asm

AUTHOR:		Greg Grisco, Jan  9, 1996

ROUTINES:
	Name				Description
	----				-----------
GLB	PortEmulatorNotify		Stream notifier to send data
GLB	PortEmulatorSendNow		Timer callback to empty stream
GLB	PortEmulatorRestart		Input has drained, notify TinyTP
INT	PortEmulatorWriteControlData	Write control data to stream
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 9/96   	Initial revision


DESCRIPTION:
	Routines for handling data send and receive 
		

	$Id: portemulatorTransmit.asm,v 1.1 97/04/18 11:46:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notifier routine for data output

CALLED BY:	GLOBAL (Stream driver via a write operation)
PASS:		dx	= stream token (ignored)
		bx	= stream segment
		ax	= unit number
		cx	= # bytes available
		bp	= STREAM_READ (ignored)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	If we're being called the first time (no data in stream yet)
		Acknowledge the notification
	else if we're being called the first time data went in (less
	than a full packet)
		Increase the threshold to 3/4 of the stream size
		Set a one-shot timer so that data in the stream
		  doesn't sit around forever
		Acknowledge the notification
	else
		Stop the timer
		Send a full packet
		Set the threshold back to 0 if stream empty, or restart timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorNotify	proc	far
	uses	ax,bx,cx,si,ds,es
	.enter

	mov	es, bx				; es = stream segment
	;
	; If we get notified with zero bytes (due to the threshold
	; being set to zero) do nothing...
	;
	jcxz	doAck				; set ack

	mov_tr	bx, ax
EC <	call	ECValidateUnitNumber					>

	call	IrCommGetDGroupDS		; ds = dgroup
	;
	; There's no need to set the timer if we have enough data for
	; a packet.  This could happen if the application is writing
	; blocks of data.
	;
	cmp	cx, ds:[bx].ISPD_packetDataSize
	jae	noSet

	test	ds:[bx].ISPD_send, mask ICSF_TIMER
	jz	setTimer			; if no timer set
noSet:
	;
	; We have enough data for a packet.  Stop the timer if one was
	; set.
	;
	and	ds:[bx].ISPD_send, not mask ICSF_TIMER

	push	bx
	mov	ax, ds:[bx].ISPD_timerID
	mov	bx, ds:[bx].ISPD_timerHandle
	call	TimerStop
	pop	bx				; stream handle
sendLoop:
	call	PortEmulatorSend		; cx = bytes left in stream
	jcxz	resetThresh			; stream is empty
	cmp	cx, ds:[bx].ISPD_packetDataSize
	jae	sendLoop
	;
	; There are still bytes in the stream (they just wouldn't all
	; fit in the packet we just sent).  Reset the timer.
	;
	mov	si, bx				; si = unit number
	call	ResetTimer			; while keeping threshold...
	jmp	doAck
resetThresh:
	;
	; All the bytes have been read from the stream.  Reset the
	; threshold so we'll get called on the first byte.
	;
	clr	cx
	call	SetOutputThreshold
	jmp	doAck
setTimer:
	;
	; Adjust the threshold.  We will be notified when the stream
	; hits this threshold...unless the timer goes off first.
	;
	mov	si, bx				; si = unit number
	mov	cx, ds:[bx].ISPD_packetDataSize
	call	SetOutputThreshold
	;
	; Set a one-shot timer so data doesn't get stranded in the stream
	;
	call	ResetTimer
doAck:
	;
	; Acknowledge the notification
	;
	mov	es:[SD_reader.SSD_data].SN_ack, 0

	.leave
	ret
PortEmulatorNotify	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the data from the output buffer and send via an
		IrComm_Data.Request

CALLED BY:	PortEmulatorNotify, IrCommSendDataNow
PASS:		bx	= unit number
		cx	= number of bytes in output stream (nonzero)
		ds	= dgroup
RETURN:		cx	= number bytes left in stream
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorSend	proc	far
	uses	ax,bx,dx,si,di,bp,ds,es
	.enter

EC <	call	ECValidateUnitNumber					>
EC <	cmp	cx, ds:[bx].ISPD_outStreamSize				>
EC <	ERROR_G	-1							>

	push	cx				; save # bytes in stream

	segmov	es, ds, ax			; es = dgroup
	mov	dx, cx				; dx = # bytes in stream

	test	es:[bx].ISPD_send, mask ICSF_CONTROL
	jnz	allocChunk
	;
	; There is no control data in the stream.  We need to account
	; for the size of the control length since we will be adding
	; the control length of 0 to the packet.
	;
	add	cx, CONTROL_LENGTH_SIZE		; add one for clen

allocChunk:
	add	cx, TTP_HEADER_SIZE
	mov	ax, es:[bx].ISPD_packetDataSize
	cmp	cx, ax				; more data than packetsize?
	jle	sizeOk
	add	ax, dx
	sub	ax, cx
	mov	dx, ax				; dx = # of bytes to read
	mov	cx, es:[bx].ISPD_packetDataSize
sizeOk:
	;
	; Pass the data to IrComm in a HugeLMem block
	;
	push	bx
	mov	ax, cx				; ax = size of chunk
	add	ax, 3
	and	ax, 0xfffc			; round up 
	mov	bx, es:[vmFile]
	mov	cx, FOREVER_WAIT
	call	HugeLMemAllocLock		; ^lax:cx = buffer
						; ds:di = buffer
	pop	bx				; bx = unit number

	push	ax, bx, cx
	mov	si, di				; ds:si = data block
	add	si, TTP_HEADER_SIZE		; advance past headers
	test	es:[bx].ISPD_send, mask ICSF_CONTROL
	jnz	readControl
	mov	{byte} ds:[si], 0		; clen = 0
	inc	si
readControl:
	mov	ax, STREAM_NOBLOCK		; we know there's enough
	mov	bx, es:[bx].ISPD_outStream
	mov	cx, dx				; number of bytes to read
	mov	di, DR_STREAM_READ
	call	StreamStrategy
EC <	ERROR_C	-1							>
	pop	ax, di, cx			; di = unit number
						; ^laxcx = HugeLMem block
	push	dx
	test	es:[di].ISPD_send, mask ICSF_CONTROL
	jnz	correctSize
	inc	dx				; account for clen
correctSize:
	and	es:[di].ISPD_send, not mask ICSF_CONTROL
	mov	bx, ax
	call	HugeLMemUnlock
	call	IrCommDataRequest
	; IrCommDataRequest already frees the HugeLMem if data request fails.
	; -Chung 5/31/96
	;jc	requestFailed
cleanup:
	pop	cx				; # bytes read from stream

	pop	dx				; # bytes originally
						; in stream

	xchg	cx, dx
	sub	cx, dx				; cx = # bytes left in stream

	.leave
	ret
; IrCommDataRequest already frees the HugeLMem if data request fails.
;requestFailed:
	;
	; We must destroy the HugeLMem block ourselves.
	;
;	movdw	esdi, cxdx
;	movdw	axcx, es:[di].IDA_data
;	call	HugeLMemFree
;	jmp	cleanup
PortEmulatorSend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorRestart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by the stream driver when the input buffer has
		drained below the low-water threshold.  Used for
		marking the state as not busy so we can begin
		accepting data from TinyTP again when it gives us data
		indications.

CALLED BY:	GLOBAL (Stream Driver)
PASS:		bp	= unit number
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorRestart	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	mov	bx, bp							>
EC <	call	ECValidateUnitNumber					>

	.leave
	ret
PortEmulatorRestart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommSendDataNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by timer message to wake up and send a packet

CALLED BY:	MSG_IRCOMM_SEND_DATA_NOW
PASS:		ax	= method
		cx:dx	= tick count
		bp	= timer ID
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommSendDataNow	method dynamic IrCommProcessClass, 
					MSG_IRCOMM_SEND_DATA_NOW
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	call	IrCommGetDGroupDS		; ds = dgroup
	;
	; Critical section.  Don't allow writing to the stream while
	; we're here, so we can keep an accurate count of the number
	; of bytes in the stream.
	;
	PSem	ds, outputSem

	mov	bx, ds:[portNum]

EC <	call	ECValidateUnitNumber					>
	;
	; The Notify routine might have already emptied the stream in
	; between the time this message was sent til now.  Check the
	; flag to see if the Notify routine tried to turn off the
	; timer.
	;
	test	ds:[bx].ISPD_send, mask ICSF_TIMER
	jz	done
	;
	; Find out how much data is in the output stream
	;
	push	bx
	mov	ax, STREAM_READ
	mov	bx, ds:[bx].ISPD_outStream
	mov	dx, bx
	mov	di, DR_STREAM_QUERY
	call	StreamStrategy			; ax = # bytes available
	pop	bx				; bx = unit number

	mov	cx, ax				; cx = number of bytes
	;
	; Write control routine could have been called while we
	; received this message.  Since the write control data routine
	; flushes the stream, check to see if we have anything left.
	;
	jcxz	resetThresh
	call	PortEmulatorSend		; cx = bytes left in stream
	jcxz	resetThresh

	mov	si, bx				; si = unit number
	call	ResetTimer

	jmp	done
resetThresh:
	;
	; Set the threshold back to 0
	;
	clr	cx
	call	SetOutputThreshold
	and	ds:[bx].ISPD_send, not mask ICSF_TIMER
done:
	VSem	ds, outputSem

	.leave
	ret
IrCommSendDataNow	endm


ResidentCode	ends


PortEmulatorCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorFlushData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush all of the data in the output buffer

CALLED BY:	(INTERNAL) PortEmulatorWriteControlData
PASS:		es	= dgroup
		bx	= unit number
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		
	Stop the timer
	repeat
		send a packet to IrCommConnectRequest
	until no more data in buffer
	Reset the threshold to 0

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorFlushData	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

EC <	call	ECValidateUnitNumber					>
	;
	; Stop the timer
	;
	push	bx
	mov	ax, es:[bx].ISPD_timerID
	mov	bx, es:[bx].ISPD_timerHandle
	call	TimerStop
	pop	bx				; stream handle
	;
	; Get the number of bytes in the stream
	;
	push	bx
	mov	ax, STREAM_READ
	mov	bx, es:[bx].ISPD_outStream
	mov	di, DR_STREAM_QUERY
	call	StreamStrategy			; ax = # of bytes
	pop	bx
	mov	cx, ax
	jcxz	done				; nothing to send?
	segmov	ds, es, ax
sendLoop:
	;
	; Send a packet
	;
	call	PortEmulatorSend		; cx = # bytes left
	jcxz	done
	jmp	sendLoop			; send another
done:
	;
	; Reset the threshold to 0, so our notifier will restart the
	; timer when the next byte is written.
	;
	clr	cx
	call	IrCommGetDGroupDS
	call	SetOutputThreshold
	.leave
	ret
PortEmulatorFlushData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorWriteControlData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes control data to the stream, flushing any data
		that might already be there (since control data needs
		to come first).

CALLED BY:	INTERNAL
PASS:		bx	= unit number
		ds:si	= encoded control data (Clen is first)
RETURN:		carry set on error
			ax = STREAM_CLOSED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Flush the data in the output buffer
	At this point, the timer is off and no other thread will be
	  writing data to the output stream.  This means that the
	  timer cannot be turned on (no fear of someone else reading
	  from the output stream) 
	Set the control flag to signal control data in the stream
	Write the encoded control data to the stream.  Our notifier
	  will get called on the first byte and restart the timer and
	  adjust the threshold.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorWriteControlDataFar	proc	far
	call	PortEmulatorWriteControlData
	ret
PortEmulatorWriteControlDataFar	endp

PortEmulatorWriteControlData	proc	near
	uses	bx,cx,di,bp,es
	.enter
EC <	call	ECValidateUnitNumber					>

	clr	cx
	mov	cl, {byte} ds:[si]
EC <	tst	cx							>
EC <	ERROR_LE	IRCOMM_ILLEGAL_CONTROL_LENGTH			>

	call	IrCommGetDGroupES		; ds = dgroup

	PSem	es, outputSem

	call	PortEmulatorFlushData

	or	es:[bx].ISPD_send, mask ICSF_CONTROL

	mov	bx, es:[bx].ISPD_outStream
	inc	cx				; # bytes, incuding clen
	mov	di, DR_STREAM_WRITE
	call	StreamStrategy

	VSem	es, outputSem

	.leave
	ret
PortEmulatorWriteControlData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the timer so that we will get notified at some
		point and send a packet.  This prevents data from
		being stranded due to the threshold never being met.

CALLED BY:	(INTERNAL) IrCommNotify, IrCommSendDataNow
PASS:		si	= unit number
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetTimer	proc	far
	uses	ax,bx,cx,dx,si,bp
	.enter

EC <	mov	bx, si							>
EC <	call	ECValidateUnitNumber					>

	mov	ds:[portNum], si

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[threadHandle]
	mov	si, 0
	mov	cx, ds:[flushTime]
	mov	dx, MSG_IRCOMM_SEND_DATA_NOW	; our handler
	mov	bp, 0
	call	TimerStart

	mov	si, ds:[portNum]		; si = unit number
	mov	ds:[si].ISPD_timerID, ax
	mov	ds:[si].ISPD_timerHandle, bx
	or	ds:[si].ISPD_send, mask ICSF_TIMER

	.leave
	ret
ResetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetOutputThreshold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the high-water threshold for the output stream

CALLED BY:	INTERNAL
PASS:		bx	= unit number
		cx	= threshold
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetOutputThreshold	proc	far
	uses	ax,bx,di
	.enter

EC <	call	ECValidateUnitNumber					>

EC <	cmp	cx, ds:[bx].ISPD_outStreamSize				>
EC <	ERROR_G	-1							>

	mov	ax, STREAM_READ
	mov	bx, ds:[bx].ISPD_outStream
	mov	di, DR_STREAM_SET_THRESHOLD
	call	StreamStrategy

	.leave
	ret
SetOutputThreshold	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorSendFlowControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the flow control settings to the peer

CALLED BY:	INTERNAL (IrCommSetFlowControl, IrCommEnableFlowControl)
PASS:		bx	= unit number
		cl	= Stop Control
		ch	= Stop Signal
		dl	= SerialFlow
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Convert the SerialFlow & SerialMode structs to IrCommFlowControl 
	and send to the peer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorSendFlowControl	proc	far
	uses	ax,si,ds
	.enter

	mov	al, not (mask ICFC_ENQ_ACK_INPUT or mask ICFC_ENQ_ACK_OUTPUT)
	test	dl, mask SF_INPUT
	jnz	checkOutput
	and	al, not (mask ICFC_XON_XOFF_INPUT or mask ICFC_RTS_CTS_INPUT or mask ICFC_DSR_DTR_INPUT)
checkOutput:
	test	dl, mask SF_OUTPUT
	jnz	checkSoft
	and	al, not (mask ICFC_XON_XOFF_OUTPUT or mask ICFC_RTS_CTS_OUTPUT or mask ICFC_DSR_DTR_INPUT)
checkSoft:
	test	dl, mask SF_SOFTWARE
	jnz	checkHW
	and	al, not (mask ICFC_XON_XOFF_INPUT or mask ICFC_XON_XOFF_OUTPUT)
checkHW:
	test	dl, mask SF_HARDWARE
	jnz	checkHWType
	and	al, not (mask ICFC_RTS_CTS_INPUT or mask ICFC_RTS_CTS_OUTPUT or mask ICFC_DSR_DTR_INPUT or mask ICFC_DSR_DTR_OUTPUT)
	jmp	sendIt
checkHWType:
	;
	; Find out what type of HW flow control the client wants by
	; looking at the modem bits it wants us to set/check.  Since
	; the serial driver maps RTS & CTS to the same bit, we are
	; checking both DTE and DCE settings.
	;
	test	cl, mask SMC_RTS
	jnz	checkDTR
	and	al, not (mask ICFC_RTS_CTS_INPUT)
checkDTR:
	test	cl, mask SMC_DTR
	jnz	checkSignals
	and	al, not (mask ICFC_DSR_DTR_INPUT)
checkSignals:
	test	ch, mask SMS_CTS
	jnz	checkDSR
	and	al, not (mask ICFC_RTS_CTS_OUTPUT)
checkDSR:
	test	ch, mask SMS_DSR
	jnz	sendIt
	and	al, not (mask ICFC_DSR_DTR_OUTPUT)
sendIt:
	sub	sp, 4				; clen + PI + PL + PV

	segmov	ds, ss
	mov	si, sp				; ds:si = encoded data
	mov	{byte} ds:[si], 3		; clen
	mov	{byte} ds:[si+1], ICCP_FLOW_CONTROL
	mov	{byte} ds:[si+2], 1		; PL
	mov	{byte} ds:[si+3], al		; PV

	call	PortEmulatorWriteControlData

	add	sp, 4
	.leave
	ret
PortEmulatorSendFlowControl	endp


PortEmulatorCode	ends
