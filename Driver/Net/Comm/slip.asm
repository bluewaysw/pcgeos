COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Communication Driver
FILE:		slip.asm

AUTHOR:		In Sik Rhee  4/92

ROUTINES:
	Name			Description
	----			-----------
*	SlipSend		sends packet
*	SlipReceive		receives packet
	CalcChecksum		calculate checksum of packet
	CalcCRC			calculate CRC value of packet
	SendBuffer		packetize and send buffer (CRC attached)
	SendReplyCode		send ACK,ERR,NAK back 

* - calls external to file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	4/10/92		Getting started


DESCRIPTION:

	Packet-level driver implementing SLIP (Serial Line IP) and
	Xmodem 16-bit CRC

	$Id: slip.asm,v 1.1 97/04/18 11:48:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Send	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes buffer [less than or equal to MAX_PACKET_SIZE] and
		makes it into a packet and sends it through the port

CALLED BY:	stream driver
PASS: 		ss:bp	- StreamVars struct
		cx	- size of packet (not including header)
RETURN:		carry set on error, ax - error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Calculate CRC, attach to end of buffer
	Send buffer as it becomes packetized	[byte-by-byte]
	Wait for reply (ACK or ERR)
	if ERR, repeat process	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipSend	proc	near
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter

EC <	mov	bl, ss:[bp].SV_header.PH_type				>
EC <	cmp	bl, FIRST_DATA_PACKET_ID				>
EC <	ERROR_B	BAD_PACKET_TYPE						>
EC <	cmp	bl, LAST_DATA_PACKET_ID					>
EC <	ERROR_A	BAD_PACKET_TYPE						>
	;
	; fill the packet header first
	;
	segmov	ds, dgroup, bx
	mov	bx, ss:[bp].SV_packetID
	mov	bl, ds:[packetIDout][bx]
	MOVW	ss:[bp].SV_header.PH_destSocket, ss:[bp].SV_destID, ax
	MOVW	ss:[bp].SV_header.PH_extraData, ss:[bp].SV_extraData, ax
	mov	ss:[bp].SV_header.PH_ID, bl
	mov	ss:[bp].SV_header.PH_dataLen, cx

;	Calculate the CRC for the data (the checksum of both the PacketHeader
;	and the data we are sending).

	segmov	es, ss
	lea	di, ss:[bp].SV_header
	mov	cx, size SV_header
	clr	ax
	mov	dx, CHECKSUM_STARTING_DX_VALUE
	call	CalcChecksumLow		; ax - checksum
	mov	cx, ss:[bp].SV_header.PH_dataLen
	jcxz	noData
	les	di, ss:[bp].SV_data
	call	CalcChecksumLow
noData:
	call	CalcCRC			; ax - CRC
	clr	dx			; use dx as a counter 
sendPacket:
;
; CX - # bytes of data to send
; ES:DI - data to send (if any)
; AX - CRC value
;
	inc	dx			; send #
	cmp	dx, MAX_RETRY_VALUE	; have we exceeded max value?
	LONG ja	errorSend
	call	SendBuffer
	LONG jc	errorSend
EC <	inc	ds:[debugStat].DS_packetSent	>
blockOnSem:
	mov	bx, ss:[bp].SV_ackSem
	push	ax,cx
	mov	cx, ss:[bp].SV_timeOut	; timeOut value
	call	ThreadPTimedSem
	cmp	ax, SE_TIMEOUT		; use this code to do timeouts
	pop	ax,cx
NEC <	je	sendPacket		; packet lost, resend	>
EC <	LONG je	timeOutEC		; packet lost, resend	>
	;
	; here, we received a reply, see what reply it is and process it.
	; If it is "ERR_PACKET", then no socket is set up on the other
	; 	side, so return an error
	;
	; If it is an ACK, then we are done
	;
	; Otherwise, resend
	;
	clr	dx		;If we've gotten a reply, that means that the
				; connection is still good, so reset the 
				; timeout count (the # times we retry before
				; giving up)

	; Check to see if the reply was for this block, both by checking the
	; ID and by checking the checksum

	mov	bl, ds:[packetReply].PR_ID	; get reply ID
	cmp	bl, ss:[bp].SV_header.PH_ID	; does it match send ID?
NEC <	jne	blockOnSem			; no, ignore and wait >
EC  <	LONG jne	ackErrorEC					>

	cmp	ds:[packetReply].PR_type, NAK_PACKET
NEC <	je	sendPacket						>
EC <	LONG je	packetErrorEC						>

	cmp	ax, ds:[packetReply].PR_CRC
NEC <	jne	blockOnSem						>
EC <	WARNING_NE	MISMATCHED_REPLY_CRC				>
EC <	jne	ackErrorEC						>

	cmp	ds:[packetReply].PR_type, ERR_PACKET	
	je	errReceived					
	cmp	ds:[packetReply].PR_type, ACK_PACKET	; get reply type
NEC <	jne	sendPacket 					>
EC  <	jne 	packetErrorEC 					>
	;
	; here, we received an ACK 
	;
EC <	inc	ds:[debugStat].DS_ackPacket	>
	mov	bx, ss:[bp].SV_packetID
	call	PpacketIDout
	IncPacketID	ds:[packetIDout][bx]
	call	VpacketIDout
	clc				; no error, clear carry
exit:
	.leave
	ret
errReceived:
EC <	WARNING ERR_PACKET_RECEIVED					>
EC <	inc	ds:[debugStat].DS_errPacket				>
	mov	ax, NET_ERR_REPLY_ERROR
	stc
	jmp	exit

errorSend:
EC <	WARNING	PACKET_SEND_ERROR		>
EC <	inc	ds:[debugStat].DS_packetFail	>
	mov	ax, NET_ERR_SEND_TIMEOUT
	stc				; set carry
	jmp	exit

if ERROR_CHECK

timeOutEC:
	WARNING	RESENDING_AFTER_TIMEOUT
	inc	ds:[debugStat].DS_packetTO	
	jmp	sendPacket

ackErrorEC:
	WARNING	RECEIVED_ACK_FOR_DIFFERENT_PACKET
	inc	ds:[debugStat].DS_ackError
	jmp	blockOnSem

packetErrorEC:
	WARNING NAK_PACKET_RECEIVED
	inc	ds:[debugStat].DS_nakPacket  
	jmp	sendPacket
endif

SlipSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts buffer into packet, sending while converting over
		the correct port.  CRC attached at end.

		At this level, we have exclusive rights on the port for 
		writing. 

CALLED BY:	SlipSend
PASS:		ds	- dgroup
		es:di 	- buffer 
		ss:bp   - StreamVars (containing packet header)
		cx	- size
		ax	- CRC

RETURN:		carry on error
DESTROYED:	bx

PSEUDO CODE/STRATEGY:

	Glue CRC to end of buffer
	send BEGIN char
	send buffer, encoding ESC and END characters [see SLIP doc]
	send END char

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendBuffer	proc	near
	uses	ax,cx,dx,di,si,ds
	.enter

EC <	call	ECCommCheckESDI						>
EC <	call	ECCommCheckStreamVars					>

	push	ax, cx, di
	mov	bx, ss:[bp].SV_sendPacketSem
	call	ThreadPSem

	mov	bx, ss:[bp].SV_strToken		;bx <- stream token
	;
	; Send a begin packet code to start
	;
	mov	cl, BEGIN_CHAR			;cl <- byte to send
	call	CommWriteByte
	pop	ax, cx, di			;AX <- CRC value
	jc	exit

;	Write out the header
	
	segmov	ds, ss
	lea	si, ss:[bp].SV_header
	mov	dx, size SV_header
	call	WriteEscapedBuffer
	jc	exit

;	Write out the data

	jcxz	noData
	segmov	ds, es
	mov	si, di				;ds:si <- ptr to buffer
	mov	dx, cx				;dx <- byte counter
	call	WriteEscapedBuffer
	jc	exit

noData:

;	Write out the CRC

	push	ax
	segmov	ds, ss			;DS:SI <- ptr to CRC word
	mov	si, sp	
	mov	dx, size word		;DX <- size of CRC word
	call	WriteEscapedBuffer
	pop	ax
	jc	exit

	;
	; Send an end of packet code
	;

	mov	cl, END_CHAR			;cl <- byte to write
	call	CommWriteByte
	jc	exit

	;
	; We don't want to return until all the data has been written out,
	; so flush the stream here (otherwise, we could start waiting for
	; the reply before we've actually finished sending the data, and
	; timeout spuriously).
	;

	call	CommFlushOutput
	clc
exit:
	pushf
	mov	bx, ss:[bp].SV_sendPacketSem
	call	ThreadVSem
	popf
	.leave
	ret

SendBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommFlushOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to wait until all the data has been flushed out,
		so we set up a routine to be notified when all the data 
		is gone, block on a semaphore, then nuke the notification
		when the data is all gone.

CALLED BY:	GLOBAL
PASS:		ss:bp - StreamVars
		bx - stream token
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommFlushOutput	proc	near	uses	ax, cx, dx, bp, di, ds
	.enter
	segmov	ds, dgroup, ax
EC <	tst	ds:[flushOutputSem].Sem_value				>
EC <	ERROR_NZ	NON_ZERO_FLUSH_SEM				>

;	Tell the serial driver that we want to be notified whenever the
;	output queue has been flushed (the threshold has already been
;	set in CommOpenPort).
;

	mov	ax, SNE_DATA shl offset SNT_EVENT or SNM_ROUTINE shl offset SNT_HOW
	mov	di, DR_STREAM_SET_NOTIFY
	mov	cx, segment Resident
	mov	dx, offset NotifyStreamFlushed
EC <	call	ECCommCheckStreamVars					>
	call	ss:[bp].SV_serDrvr
	jc	streamClosed
	PSem	ds, flushOutputSem, TRASH_AX

;	Nuke the notification.

	mov	ax, SNE_DATA shl offset SNT_EVENT or SNM_NONE shl offset SNT_HOW
	mov	di, DR_STREAM_SET_NOTIFY
EC <	call	ECCommCheckStreamVars					>
	call	ss:[bp].SV_serDrvr
streamClosed:
	.leave
	ret
CommFlushOutput	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteEscapedBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes out a buffer, after inserting any needed escapes.

CALLED BY:	GLOBAL
PASS:		ds:si - data to send
		dx - # bytes to send
RETURN:		carry set if error
DESTROYED:	dx, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteEscapedBuffer	proc	near	uses	ax, cx, di
	.enter

	;
	; Check the buffer for escapes or end sequences
	;
	clr	cx				;cx <- no bytes since escape
sendLoop:
EC <	call	ECCommCheckDSSI						>
	cmp	{byte} ds:[si], END_CHAR
	je	sendEnd
	cmp	{byte} ds:[si], ESC_CHAR
	je	sendEsc
	inc	cx				;cx <- bytes since escape
	inc	si				;ds:si <- ptr to next byte
	dec	dx				;dx <- one less byte to send
	jnz	sendLoop			;branch if more to send
	;
	; Send the bytes we've scanned so far
	;
	sub	si, cx				;ds:si <- ptr to bytes
EC <	call	ECCommCheckDSSI						>
	call	CommWriteBuffer
exit:
	.leave
	ret

	;
	; Send an escape character for escape
	;
sendEsc:
	mov	di, ESC_ESC			;di <- code to send
	jmp	sendCode

	;
	; Send an escape character for end
	;
sendEnd:
	mov	di, ESC_END			;di <- code to send
	;
	; Send a special character (ESC_ESC or ESC_END)
	;
sendCode:
	push	di
	;
	; Send any bytes up to the end or escape
	;
	jcxz	noExtraBytes
	sub	si, cx				;ds:si <- ptr to bytes
	call	CommWriteBuffer
	jc	popExit

	add	si, cx
noExtraBytes:
	;
	; Send an escape
	;
	mov	cl, ESC_CHAR			;cl <- byte to write
	call	CommWriteByte
	pop	cx				;cl <- byte to write
	jc	exit

	;
	; Send the escape code (ESC_ESC or ESC_END)
	;
	call	CommWriteByte
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
		CommWriteBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a buffer of bytes to the serial driver

CALLED BY:	UTILITY
PASS:		ds:si - ptr to bytes to send
		cx - # bytes to send
		ss:bp - ptr to StreamVars
		bx - stream token
RETURN:		none
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommWriteBuffer		proc	near
	.enter

EC <	push	cx							>
EC <	call	ECCommCheckDSSI						>
	mov	ax, STREAM_BLOCK
	mov	di, DR_STREAM_WRITE
EC <	call	ECCommCheckStreamVars					>
	call	ss:[bp].SV_serDrvr
EC <	pop	ax				;ax <- # bytes passed	>
EC <	cmp	ax, cx				;all bytes written?	>
EC <	ERROR_NE COMM_SHORT_SERIAL_WRITE				>

	.leave
	ret
CommWriteBuffer		endp

Send	ends

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyStreamFlushed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine that is called whenever the output queue is empty.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyStreamFlushed	proc	far		uses	ax, ds
	.enter	
	segmov	ds, dgroup, ax
EC <	cmp	ds:[flushOutputSem].Sem_value,0				>
EC <	ERROR_G	NON_ZERO_FLUSH_SEM					>
	VSem	ds, flushOutputSem, TRASH_AX
	.leave
	ret
NotifyStreamFlushed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	receives a packet and sends it to stream driver for
		processing.  also processes ACK and ERR replies.

CALLED BY:	Stream Driver
PASS:		ss:bp	- ServerStruct
RETURN:		carry - set if driver is closing
		ds	- segment of packet (variable length start ds:0)
		cx	- socket token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipReceive	proc	far
	uses	ax,bx,dx,si,di,bp,es
	.enter	

EC <	call	ECCommCheckServerStruct					>

	segmov	ds, dgroup, ax
	;
	; Get bytes until we get to the start of a packet followed by
	; a valid type.
	;
getPacket:
	mov	bx, ss:[bp].SE_strToken
	mov	di, DR_STREAM_READ_BYTE
getPacketStartLoop:
	mov	ax, STREAM_BLOCK
	call	ss:[bp].SE_serDrvr	; get a byte
	jc	exit
	cmp	al, BEGIN_CHAR		; beginning of packet?
	jne	getPacketStartLoop
	mov	ax, STREAM_BLOCK
	call	ss:[bp].SE_serDrvr	; get next byte (packet type)
	jc	exit
	cmp	al, ACK_PACKET		; ack or err?
	je	ackOrErr
	cmp	al, NAK_PACKET
	je	ackOrErr
	cmp	al, ERR_PACKET
	je	ackOrErr
	cmp	al, FIRST_DATA_PACKET_ID
NEC <	jb	getPacketStartLoop					>
EC <	LONG jb	packetLostEC						>

	cmp	al, LAST_DATA_PACKET_ID
NEC <	ja	getPacketStartLoop					>
EC <	LONG ja	packetLostEC						>
	;
	; We've received the start of a data packet.  Loop through until
	; we get the end of the packet marker.
	;
	mov	dx, ax			; save packet type

	call	HandleDataPacket
	jc	exit
	tst	bx
	jz	getPacket

	call	MemDerefDS
	clc				;carry <- no error
exit:
EC<	WARNING_C	CLOSING_INPUT_STREAM		>
	.leave
	ret
EC <packetLostEC:						>
EC <	inc	ds:[debugStat].DS_packetLost			>
EC <	WARNING	UNKNOWN_PACKET_TYPE				>
EC <	jmp	getPacketStartLoop				>

	;
	; We've received an ACK or an error (ie. a non-data packet)
	;
ackOrErr:

;
;	I wonder about this code - if a ACK comes in, followed by an NAK,
;	then we will overwrite the ACK. The caller of SlipSend
;	will end up resending the block, and possibly getting things out
;	of sequence.
;
;	Only one person can be sending at a time, so this may not be
;	a problem in general (there is a semaphore around the calls to
;	SlipSend in CommCallService so only one packet should be waiting
;	for an ack at a time).
;

	mov	ds:[packetReply].PR_type, al	; store reply

;	The next two bytes to read in should be the packet type, repeated.
;	We make sure these values all match.

	mov	ax, STREAM_BLOCK	;
	call	ss:[bp].SE_serDrvr	;
	jc	exit
	cmp	al, ds:[packetReply].PR_type
EC <	WARNING_NE	GARBLED_REPLY					>
	jne	getPacket

	mov	ax, STREAM_BLOCK	;
	call	ss:[bp].SE_serDrvr	;
	jc	exit
	cmp	al, ds:[packetReply].PR_type
EC <	WARNING_NE	GARBLED_REPLY					>
	LONG jne	getPacket

;	Get the ID, and notify the sender that it has a valid reply.

	mov	ax, STREAM_BLOCK	;
	call	ss:[bp].SE_serDrvr	;
	jc	exit
	mov	ds:[packetReply].PR_ID, al

	mov	ax, STREAM_BLOCK
	mov	di, DR_STREAM_READ_BYTE
	call	ss:[bp].SE_serDrvr
	jc	exit
	mov	ds:[packetReply].PR_CRC.low, al

	mov	ax, STREAM_BLOCK
	mov	di, DR_STREAM_READ_BYTE
	call	ss:[bp].SE_serDrvr
	jc	exit
	mov	ds:[packetReply].PR_CRC.high, al

	mov	ax, STREAM_BLOCK
	mov	di, DR_STREAM_READ_BYTE
	call	ss:[bp].SE_serDrvr
	LONG jc	exit
	cmp	al, END_CHAR
EC <	WARNING_NE	GARBLED_REPLY					>
	LONG jne	getPacket

haveReply:			;Used by swat
ForceRef haveReply
	mov	bx, ss:[bp].SE_ackSem	;
	call	ThreadVSem		; release semaphore so sender can
					; process reply
	jmp	getPacket		; next packet! (re-use buffer)

SlipReceive	endp
Resident	ends
Receive	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleDataPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs CRC/sanity checks on the incoming packet.

CALLED BY:	SlipReceive
PASS:		dl - packet type
		ss:bp - ServerStruct
RETURN:		carry set if stream closing
		bx - handle of data (0 if corrupt)
		cx - socket token
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleDataPacket	proc	far	uses	ax, dx, di, si, es, ds
	.enter
;
;	If we don't do this, we can never turn EC ALL on
;
EC <	segmov	es, 0xa000, ax		>
	segmov	ds, idata, ax
	;
	; Allocate a buffer to handle the data from the serial driver
	;
	;Buffer will hold:
	;
	; 	PacketHeader<>
	;	up to MAX_PACKET_SIZE bytes
	; 	16-bit CRC
	;

	mov	ax, MAX_PACKET_SIZE + size PacketHeader + size word
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	mov	bx, handle 0
	call	MemAllocSetOwner	; bx is mem handle
	mov	es,ax
	mov	ss:[bp].SE_dataPacketHan, bx

	mov	es:[PH_type], dl	; packet type
	mov	di, offset PH_ID	;
	mov	bx, ss:[bp].SE_strToken
getByteLoop:

	mov	ax, STREAM_BLOCK
	mov	si, di
	mov	di, DR_STREAM_READ_BYTE
	call	ss:[bp].SE_serDrvr	; get byte
	jc	streamError
	cmp	al,END_CHAR		; END of packet?
	je	checkCRC		
	cmp	al,ESC_CHAR		; esc code?
	je	handleEscape

copyAndGet:
	cmp	si, MAX_PACKET_SIZE + size PacketHeader + size word
					; don't overrun our buffer space
	jae	corruptPacket		; (corrupt packet here) 
EC <	segxchg	ds, es						>
EC <	call	ECCheckBounds					>
EC <	segxchg	ds, es						>
	mov	di, si
	stosb	
	jmp	getByteLoop

handleEscape:
	;
	; The byte was an escape flag -- get the next byte as data.
	; We only escape out the escape char and the end char, so if
	; the following char is any other character, then the packet is
	; corrupt.
	;
	mov	ax, STREAM_BLOCK
	call	ss:[bp].SE_serDrvr	; get next byte
	LONG jc	exit
	mov	ah, al
	mov	al, ESC_CHAR
	cmp	ah, ESC_ESC
	je	copyAndGet
	mov	al, END_CHAR
	cmp	ah, ESC_END
	je	copyAndGet
	;
	; The packet came in, but was: too large, had weird data, or the CRC
	; did not match. Send a NAK and try again.
	;
corruptPacket:
EC<	WARNING CORRUPT_PACKET_RECEIVED	>
	mov	dl,NAK_PACKET
	mov	bx, ss:[bp].SE_packetID
	mov	dh,ds:[packetIDin][bx]	; packet ID
	call	SendReplyCode
EC<	inc	ds:[debugStat].DS_nakSent	>

invalidPacket:
	mov	bx, ss:[bp].SE_dataPacketHan
	call	MemFree
	clr	bx			;Clears carry
EC <	ERROR_C	-1							>
	jmp	exit

streamError:
	mov	bx, ss:[bp].SE_dataPacketHan
	call	MemFree
	stc
	jmp	exit

	;
	; We got a packet -- see if the checksum matches
	;
checkCRC:
	mov	cx,si			; size of buffer	
	clr	di
	call	CalcChecksum
	tst	ax			; checksum OK?
	jnz	corruptPacket		; branch if checksum not OK

	inc	ss:[bp].SE_okPacketCount ; another valid data packet seen

EC <	cmp	es:[PH_dataLen], MAX_PACKET_SIZE			>
EC <	ERROR_A	PACKET_TOO_LARGE					>
	mov	al, es:[PH_ID]
	mov	bx, ss:[bp].SE_packetID	; offset in packet table
EC <	cmp	bx, length packetIDin					>
EC <	ERROR_AE	COMM_BAD_PACKET_ID				>
	mov	ah, ds:[packetIDin][bx]	; ah <- expected packet ID
idCheck:			;Used by swat
ForceRef idCheck
	tst	al
	jnz	checkID
	;
	; 0 packet ID means a fresh port connection 
	;
EC<	WARNING	FRESH_CONNECTION					>
	; Now, expect the next packet we receive to be 1.
	mov	ds:[packetIDin][bx], 1
	jmp	dropPacket
checkID:
	cmp	al, ah			; match?
	je	packetIDOK
;
;	AH will be 0 if we just opened the port, and have not received a
;	synchronization	packet (a packet with ID=0). This can happen if
;	the remote machine still had the port open from an old connection
;	to a machine. We go ahead and synchronize with the current ID,
;	as we won't ever get a synchronization packet from the remote
;	connection -- in general, this won't happen, as ports *always*
;	send synchronization packets before any data packets.
;
	tst	ah
	jz	rematchPacketNumber
	;
	; no match, packet may be redundant
	;
	IncPacketID	al
	cmp	al, ah
	LONG je	isRepeatPacket		; if so, that's fine
	DecPacketID	al
;
;	THIS CHECK CHOKED IF THE PACKET WRAPS AROUND (WE EXPECT 0xFF, AND
;	ACTUALLY RECEIVE 0x01). IF THIS EVER HAPPENS, THE SYSTEM IS LIKELY
;	TO BE FUCKED ANYWAY (THE REMOTE SIDE THINKS WE'VE RECEIVED A PACKET
;	THAT WE HAVEN'T RECEIVED), SO JUST RE-SYNCHRONIZING HERE SEEMS LIKE
;	THE ONLY THING WE CAN DO.
;
;	cmp	al, ah
;	ERROR_B	OUT_OF_SEQUENCE_PACKET					>
;	jb	getNextPacket		; if not, then we're screwed
;

rematchPacketNumber:
	mov 	ds:[packetIDin][bx],al	; correct error
EC<	WARNING REMATCH_PACKET_NUMBER	>

	;
	; Get the socket the packet was intended for, and make sure
	; that socket still exists
	;
packetIDOK: 
	;
	; Note another new packet received.
	;
	inc	ss:[bp].SE_packetCount

	mov	ax, es:[PH_destSocket]	; socket #
	call	VerifyAndGetSocketToken
	LONG jc	wrongSocket
	;
	; We've got the full packet.  Resize the block down to the actual
	; size used by the packet
	;


;	Buffer holds:
;		PacketHeader<>
;		DATA
;		CRC Value (one word)

	push	ax
	mov	bx, ss:[bp].SE_dataPacketHan
EC <	cmp	es:[PH_strLen], MAX_PACKET_SIZE				>
EC <	ja	skipCheck						>
EC <	mov	ax, cx							>
EC <	sub	ax, size PacketHeader + size word 			>
EC <	cmp	ax, es:[PH_strLen]					>
EC <	ERROR_NE STREAM_LENGTH_DOES_NOT_MATCH_DATA_RECEIVED		>
EC <skipCheck:								>
	mov	ax, cx			; ax <- new size
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc		; shrink buffer to be packet size
	;
	; ACK the packet so the sender knows it has been received OK.
	;
EC<	inc	ds:[debugStat].DS_ackSent	>
	mov	bx, ss:[bp].SE_packetID
	call	PpacketIDin
	mov	dh,ds:[packetIDin][bx]	; packet ID
	mov	dl,ACK_PACKET
	call	SendReplyCode
	;
	; Update the packet count
	;
	IncPacketID	ds:[packetIDin][bx]
	call	VpacketIDin
	mov	bx, ss:[bp].SE_dataPacketHan
	pop	cx
	clc
exit:
	.leave
	ret


	;
	; Redundant packet received -- ACK it
	;
isRepeatPacket:

EC<	WARNING REPEAT_PACKET_RECEIVED		>
EC<	inc	ds:[debugStat].DS_packetRepeat	>
	DecPacketID	al		; Ack previous packet (ACK might 
					; have been garbled)

dropPacket:

;	Ack the packet that we are ignoring, then return to get the next packet

	mov	dl, ACK_PACKET		; send another ACK for the previous
	mov	dh, al
	call	SendReplyCode
	jmp	invalidPacket

wrongSocket:
	;
	; We received a packet, but it was for the wrong socket
	; (ie. one that is closed).  Send an error in reply
	; and try again.
	;

EC<	WARNING	INVALID_SOCKET_ID_RECEIVED	>
	mov	dl,ERR_PACKET
	mov	bx, ss:[bp].SE_packetID
	mov	dh,ds:[packetIDin][bx]	; packet ID
	call	SendReplyCode
EC<	inc	ds:[debugStat].DS_errSent	>
	jmp	invalidPacket

HandleDataPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendReplyCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends reply packet

CALLED BY:	Server
PASS:		dl - code (ACK/ERR/NAK_PACKET)
		dh - packet ID
		ss:bp - ptr to ServerStruct

		if dl = ACK_PACKET or ERR_PACKET
			es - segment of data containing PacketHeader
		(es not used if dl = NAK_PACKET)
		
RETURN:		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

Ack,Nak, or Err packet:

<byte> BEGIN_CHAR
<byte> PacketType (ACK_PACKET, NAK_PACKET, ERR_PACKET)
<byte> PacketType (ACK_PACKET, NAK_PACKET, ERR_PACKET)
<byte> PacketType (ACK_PACKET, NAK_PACKET, ERR_PACKET)
<byte> packet ID
<word> packet CRC
<byte> END_CHAR

KNOWN BUGS/SIDE EFFECTS/IDEAS:

if reply packet gets garbled, then we get another packet from the remote side.
there is no efficient way to make sure this things gets through...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendReplyCode proc	near
	uses	ax,bx,cx,dx,di
	.enter

EC <	cmp	dl, NAK_PACKET						>
EC <	je	10$							>
EC <	cmp	dl, ERR_PACKET						>
EC <	je	10$							>
EC <	cmp	dl, ACK_PACKET						>
EC <	je	10$							>
EC <	ERROR	BAD_REPLY_PACKET_TYPE					>
EC <10$:								>
EC <	call	ECCommCheckServerStruct					>

	mov	bx, ss:[bp].SE_sendPacketSem
	call	ThreadPSem

	mov	bx, ss:[bp].SE_strToken
	;
	; Send a begin code
	;
	mov	cl, BEGIN_CHAR			;cl <- byte to send
	call	writeByte
	jc	exit
	;
	; Send the code (ACK_CHAR or ERR_CHAR). We send it 3 times in a 
	; row as error checking (it used to be just one byte of NAK/ACK, but
	; it is too easy to have a NAK changed to an ACK, and vice versa).
	;
	mov	cl, dl			; send code
	call	writeByte
	jc	exit

	mov	cl, dl
	call	writeByte
	jc	exit

	mov	cl, dl
	call	writeByte
	jc	exit

	;
	; Send the packet ID
	;
	mov	cl, dh			; send ID
	call	writeByte

	cmp	dl, NAK_PACKET		;If we are nak-ing the packet, don't
	je	noChecksum		; bother to do the checksum, as it is
					; probably garbage anyhow - just write
					; out any old value.

	;
	; Send the block checksum
	;
	mov	cx, es:[PH_dataLen]
	add	cx, size PacketHeader
	clr	di
	call	CalcChecksum		;Returns AX = checksum
	call	CalcCRC

noChecksum:
	mov	dx, ax
	mov	cl, dl
	call	writeByte
	mov	cl, dh
	call	writeByte

	mov	cl, END_CHAR
	call	writeByte
exit:
	pushf
	mov	bx, ss:[bp].SE_sendPacketSem
	call	ThreadVSem
	popf
	.leave
	ret

writeByte:
	mov	ax, STREAM_BLOCK
	mov	di, DR_STREAM_WRITE_BYTE
	call	ss:[bp].SE_serDrvr
	retn
SendReplyCode endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyAndGetSocketToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure socket ID is valid and returns Socket token

XFCALLED BY:	slip.asm
PASS:		ax - socket ID
		ss:bp - ServerStruct
RETURN:		carry set if error
		ax - socket token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyAndGetSocketToken	proc	near
	uses	bx,di,si,ds
	.enter

	segmov	ds, dgroup, di
	mov	bx, ds:[lmemBlockHandle]
	push	bx
	push	ax
	call	MemLockShared
	mov	ds, ax
	mov	si, ss:[bp].SE_socketArray	; *ds:si - socket array
	mov	bx, segment FindSocketIDCallBack
	mov	di, offset Resident:FindSocketIDCallBack
	pop	ax
	call	ChunkArrayEnum
	cmc					;carry <- set if error
EC< 	WARNING_C	INVALID_SOCKET_NUMBER 	>
	pop	bx
	call	MemUnlockShared

	.leave
	ret
VerifyAndGetSocketToken	endp

Receive	ends

Common	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcChecksum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calculate packet checksum

CALLED BY:	SlipSend, SlipReceive

PASS:		cx		- #chars in buffer
		es:di		- packet to compute checksum for
		
RETURN:		ax		- checksum

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Fletcher's Algorithm as described in Dr. Dobb's Journal May 1992

	int i, sum1, sum2
	sum1 = sum2 = 0
	for i = 1 to message length
		sum1 = (sum1 + message[i]) mod 255
		sum2 += sum1
	end
	sum2 %= 255

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	insik	1/25/93		Implemented Fletcher's CRC algorithm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CHECKSUM_STARTING_DX_VALUE	equ	0xfe00
CalcChecksum	proc 	far
	uses	cx,dx
	.enter

FXIP <	push	bx, si							>
FXIP <	mov	bx, es							>
FXIP <	mov	si, di				; bx:si = buffer	>
FXIP <	call	ECAssertValidFarPointerXIP				>
FXIP <  pop	bx, si							>
	
	clr	ax				;start from 0
	mov	dx, CHECKSUM_STARTING_DX_VALUE
	call	CalcChecksumLow
	.leave
	ret
CalcChecksum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcChecksumLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates a checksum using the passed-in data. This allows
		callers to calculate a checksum of data in multiple buffers

CALLED BY:	GLOBAL
PASS:		ax, dx - data from previous calls to CalcChecksumLow
		(for the first call, use ax=0, dx=CHECKSUM_STARTING_DX_VALUE)
RETURN:		ax, dx - checksum up to this point
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcChecksumLow	proc	far	uses	di, cx
	.enter
doChecksum:
EC <	call	ECCommCheckESDI						>
	add	al, es:[di]			;add character to check sum
	adc 	al, dl		
	cmp	dh,al
	adc	al, dl				; mod 255
	add	ah, al
	adc	ah, dl
	cmp	dh,ah
	adc	ah, dl				; mod 255
	inc	di
	loop	doChecksum
	.leave
	ret
CalcChecksumLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCRC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate 16-bit CRC

CALLED BY:	SlipSend

PASS:		ax		- checksums 	(ah - sum2, al - sum1)
RETURN:		ax		- CRC		(ah - check2, al - check1)

DESTROYED:	none

PSEUDO CODE/STRATEGY:

See CalcChecksum

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	insik	1/25/93		Fletcher's Algorithm for second part

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcCRC	proc	far
	uses	bx,cx,dx
	.enter
	clr	dl
	mov	dh,0feh
	mov	bx,ax
	clr	ah
	add	al,bh		
	adc	al,dl
	cmp	dh,al
	adc	al,dl		; al = sum(checksums) mod 255
	mov	cl,0ffh
	sub	cl,al		; cl = check1
	mov	al,cl
	add	al,bl
	adc	al,dl
	cmp	dh,al
	adc	al,dl		; al = (check1+sum1) mod 255
	mov	ch,0ffh
	sub	ch,al
	mov	ax,cx
	.leave
	ret
CalcCRC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PpacketIDin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	P packetINsem

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PpacketIDin	proc	far
	uses	bx,ds
	.enter
	segmov	ds,dgroup,bx
	mov	bx,offset packetINsem
	PSem	ds, [bx], TRASH_BX
	.leave
	ret
PpacketIDin	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VpacketIDin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	V packetINsem

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VpacketIDin	proc	far
	uses	bx,ds
	.enter
	segmov	ds,dgroup,bx
	mov	bx,offset packetINsem
	VSem	ds, [bx], TRASH_BX
	.leave
	ret
VpacketIDin	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PpacketIDout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	P packetOUTsem

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PpacketIDout	proc	far
	uses	bx,ds
	.enter
	segmov	ds,dgroup,bx
	mov	bx,offset packetOUTsem
	PSem	ds, [bx], TRASH_BX
	.leave
	ret
PpacketIDout	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VpacketIDout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	V packetOUTsem

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VpacketIDout	proc	far
	uses	bx,ds
	.enter
	segmov	ds,dgroup,bx
	mov	bx,offset packetOUTsem
	VSem	ds, [bx], TRASH_BX
	.leave
	ret
VpacketIDout	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommWriteByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a byte to the serial driver

CALLED BY:	UTILITY
PASS:		cl - byte to send
		ss:bp - ptr to StreamVars
		bx - stream token
RETURN:		carry - set if byte could
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommWriteByte		proc	far
	.enter

	mov	ax, STREAM_BLOCK
	mov	di, DR_STREAM_WRITE_BYTE
EC <	call	ECCommCheckStreamVars					>
	call	ss:[bp].SV_serDrvr

	.leave
	ret
CommWriteByte		endp
Common	ends
