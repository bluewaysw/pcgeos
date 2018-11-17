COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File
FILE:		fileLocal.asm

AUTHOR:		Dennis Chow, December 12, 1989

METHODS:
	Name			Description
	----			-----------
	FileWriteBuf
	FileWriteChar

	AckPacket
	StripPacket
	CopyPacketToBuf

	IncRecvPackets
	IncRecvErrs
	IncRecvTimeout
	
	FileStartTimer
	FileRestartTimer
	FileCheckPacketNum
	FileCheckPackCompl
	FileProcessPacket	
	FileCheck1
	FileCheck2
	FileSendNakNow
	FileRecvEnd
	FileAbortRecv

	CalcCRC
	FileTransInit
	FileTransEnd

	IncSendPacket
	SendPacket
	SendChecksumCRC
	IncSendTimeout
	IncSendErrors

	HandleRecvTimeout
	HandleSendTimeout

	GetRecvProto
	SetRecvProto
	SetSendPacketSize
	GetSendPacketSize

	CalcChecksum
	SendEndOfFile
	FileSendEnd
	FileOpenForSend

	ReadInPacket
	SetFileName

	DoAsciiSend
	SendAsciiPacket
	SendAsciiPacketToFoamDoc
	EndAsciiSend
	CheckAsciiSend
	DoAsciiRecv
	EndAsciiRecv
	WriteAsciiPacket

	InitSerialForFileTrans
	RestoreSerialFromFileTrans
	ResetSendTriggers
	ResetRecvTriggers
	ResetSendStatus
	ResetRecvStatus

	FileSendReset
	FileRecvReset

	RegisterDocument		Register document with IACP
	UnregisterDocument		Unregister document with IACP
	RegisterUnregisterCommon	Get document info for registration

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dc		12/12/89        Initial revision.
	hirayama	3/30/94

DESCRIPTION:
	Internally callable routines for this module.
	No routines inside this file should be called from outside this
	module.

	$Id: fileLocal.asm,v 1.1 97/04/04 16:56:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWriteBuf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the current buffer

CALLED BY:	(INTERNAL) FileRecvAbort, FileSendAbort
PASS:		es		- dgroup
		cx		- number of chars in buffer
		ds:si		- buffer to write chars from 

RETURN:		C		- set if couldn't write the buffer
				  clear if things okay

DESTROYED:	ax, bx, si, di	

PSEUDO CODE/STRATEGY:
	
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileWriteBuf	proc	near
	uses	ds, es				;
	.enter
	mov	ax, ds				;
	mov	bx, es				;
	mov	ds, bx				;
	mov	es, ax				;es:si - buffer to write from
	CallMod	SendBuffer			;ds    - dgroup
	.leave
	ret
FileWriteBuf	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWriteChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a single character

CALLED BY:	(INTERNAL) FileRecvStart
PASS:		ds, es		- dgroup
		cl		- character to write out

RETURN:		---

DESTROYED:	ax, bx, cx, si, di	

PSEUDO CODE/STRATEGY:
		borrow buffer from utils segment.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileWriteChar	proc	near
	uses	ds, cx
	.enter
	segmov	ds, es, ax			;
	CallMod	SendChar			;write out the char
	.leave
	ret
FileWriteChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AckPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge a good packet

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:
		write packet to disk
		send ACK
		update all internal variables and states

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When I sent the ACK before I wrote packet to disk,	
		I got a bug because the ACK would be echoed back
		and I stuck it into my packet before writing
		to disk.  whatever
		
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dennis		12/13/89	Initial version
	hirayama	4/1/94

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AckPacket	proc 	near
	push	ds				; #1 save dgroup segment 
	clr	dx				;ds:dx->start of buffer
	mov	bp, ds:[fileHandle]		;get file to write to
	mov	cx, ds:[packetSize]		;get number of chars to write
	mov	bx, ds:[packetHandle]
	push	bx				; #2
	call	MemLock
	mov	ds, ax				;ds->packet segment
	tst	es:[recvText]			;if receiving binary file
	je	10$				;then don't strip packet
	call	StripPacket
10$:
	CallMod	WriteBufToDisk			
	pop	bx				; #2
	call	MemUnlock
	pop	ds				; #1 restore dgroup segment
	
	;
	; Check whether the user has clicked the 'Abort' trigger.
	; If not, continue as normal.  If so, do cleanup work.
	;
	test	ds:[currentFileFlags], mask FF_RECV_ABORT_TRIGGER_CLICKED
	jnz	handleAbort

sendAck::
	mov	cl, CHAR_ACK			;assume line free now
	call	FileWriteChar			;  and ACK the packet

	mov	ds:[tranState], TM_GET_SOH	;set state to wait for packet
	mov	dl, ds:[packetNum]		
	mov	ds:[prevPacket], dl		;update last packet received
	inc	ds:[packetNum]			;update next packet expected
	clr	ds:[packetHead]			;point to start of packet
	call	IncRecvPackets
	jmp	done

handleAbort:
	call	FileAbortRecv
		
done:
	ret
AckPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StripPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	strip packet of sync chars

CALLED BY:	FileProcessPacket

PASS:		ds:dx	- buffer to search
		cx	- number of character in buffer
		bp	- file handle
		es	- dgroup


DESTROYED:	ax, di	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StripPacket	proc 	near
	push	es
	segmov	es, ds, ax
	mov	di, dx			
	add	di, cx			;es:[di] ->past end of buffer
	dec	di			;es:[di] ->end of buffer
	mov	al, CHAR_PAD
	std				;we're searching backwards
	repe 	scasb			;
	cld
	inc	cx			;offset by one
exit:
	pop	es
	ret
StripPacket	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPacketToBuf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy packet data to internal buffer

CALLED BY:	FileProcessPacket

PASS:		ds		- dgroup
		ds:si		- start of buffer
		cx		- number of character in packet
		bx		- number of chars not copied to packet


DESTROYED:	di

RETURN:		carry set if ERROR and bytes not copied
		carry clear if OK

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dennis		12/14/89	Initial version
	hirayama	4/12/94		Handle user Aborts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyPacketToBuf	proc 	near
	push	bx			; #1
	mov	bx, ds:[packetHandle]
	tst	bx			; packetHandle == NULL?
	jnz	doTheCopy		; no, go ahead a copy...

	;
	; Looks like packetHandle is NULL, so make sure that the
	; user has clicked 'Abort'.  If so, just ignore all the
	; data.  If not, FatalError for now.  -mkh
	;
	test	ds:[currentFileFlags], mask FF_RECV_ABORT_TRIGGER_CLICKED
EC <	ERROR_Z	-1			; handle error here...		>
	stc				; bytes not copied
	jmp	done
		
doTheCopy:
	push	es, si, cx		; #2
	call	MemLock
	mov	es, ax			;es:di->packet buffer to copy to
	mov	di, ds:[packetHead]	;
					;ds:si->packet to copy from
	rep 	movsb			;mov ds:si to es:di
	call	MemUnlock
	pop	es, si, cx		; #2
	add	ds:[packetHead], cx	;update ptr into buffer
	clc				; bytes copied
done:
	pop	bx			; #1
	ret
CopyPacketToBuf	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncRecvPackets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	increment number packets received in dialog box

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncRecvPackets	proc 	near
	tst	ds:[numPacketErr]		;reset error count
	jz	10$
	clr	dx
	mov	ds:[numPacketErr], dl		;update packet errors
	GetResourceHandleNS	RecvErrors, bp	; bp:si = counter
	mov     si, offset RecvErrors
	mov	di, offset dgroup:errorBuf
	CallMod	UpdateNoDupCounter
10$:
	tst	ds:[numTimeouts]
	jz	20$ 
	clr	dx
	mov	ds:[numTimeouts], dl
	GetResourceHandleNS	RecvTimeouts, bp	; bp:si = counter
	mov     si, offset RecvTimeouts
	mov	di, offset dgroup:timeoutBuf
	CallMod	UpdateNoDupCounter
20$:
	tst     ds:[numPacketRecv]		;if this is first packet 
	jnz	30$				;  received then disable
	;
	; Instead of disabling the 'Abort' trigger, change the state to
	; indicate that we have started receiving packets, but *don't*
	; disable the trigger!  -mkh 3/30/94
	;
	ornf	ds:[currentFileFlags], mask FF_BEGAN_RECEIVING_PACKETS
if 0		
	mov     ax, MSG_GEN_SET_NOT_ENABLED  ;  the abort receive trigger
	GetResourceHandleNS	NoRecvTrigger, bx
	mov     si, offset NoRecvTrigger
	mov     dl, VUM_NOW
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
endif

30$:
	inc     ds:[numPacketRecv]
	mov	dx, ds:[numPacketRecv]		;update # packets received	
	GetResourceHandleNS	RecvPackets, bp	; bp:si = packet counter
	mov     si, offset RecvPackets
	mov     di, offset dgroup:packetNumBuf
	CallMod	UpdateNoDupCounter
	ret
IncRecvPackets	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncRecvErrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	increment number receive errors in dialog box

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		carry set if too many errors

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncRecvErrs	proc 	near
	inc     ds:[numPacketErr]
	mov	dl, ds:[numPacketErr]		;update # errors	
	clr	dh				;byte value
	GetResourceHandleNS	RecvErrors, bp	; bp:si = counter
	mov     si, offset RecvErrors
	mov     di, offset dgroup:errorBuf
	CallMod	UpdateNoDupCounter
	mov	al, ds:[numPacketErr]
	cmp	al, MAX_PACKET_ERRS
	jl	stillOK
	mov	bp, ERR_SEND_ABORT		; same error as send errors
	CallMod	DisplayErrorMessage
	call	FileRecvEnd
	stc
	jmp	short exit
stillOK:
	clc
exit:
	ret
IncRecvErrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncRecvTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Increment count of receive timeouts

CALLED BY:      FileRecvData

PASS:           ds, es  - dgroup

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:
	increment number of timeouts
	if exceeded max timeout
		display	error message
		abort file transfer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
        if number of maximum timeouts doesn't change, can make it into
		a constant.

REVISION HISTORY:
	Name    	Date            Description
	----    	----            -----------
	dennis  	12/13/89        Initial version
	hirayama	4/6/94

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IncRecvTimeout  proc    near
	;
	; If user has clicked 'Abort', cancel the receive!  -mkh
	;
	test	ds:[currentFileFlags], mask FF_RECV_ABORT_TRIGGER_CLICKED
	jz	abortNotClicked

	mov	cx, LEN_CAN
	push	ds, si
	segmov	ds, cs
	mov	si, offset abortStr
	call	FileWriteBuf
	pop	ds, si
	call	FileRecvEnd
	jmp	exit
		
abortNotClicked:
	inc     ds:[numTimeouts]
	mov	dl, ds:[numTimeouts]	
	clr	dh
	GetResourceHandleNS	RecvTimeouts, bp	; bp:si = counter
	mov     si, offset RecvTimeouts
	mov     di, offset dgroup:timeoutBuf
	CallMod	UpdateNoDupCounter
	mov	al, ds:[numTimeouts]
	cmp     al, ds:[maxTimeouts]                 ;if max timed out
	jl      exit
	mov	bp, ERR_NO_HOST
	CallMod	DisplayErrorMessage
	call	FileRecvEnd
exit:
	ret
IncRecvTimeout  endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileStartTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start a timer

CALLED BY:	FileDoReceive

PASS:		ds, es		- dgroup
		di		- interval between timer events

RETURN:		---

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileStartTimer	proc	near
	mov	ds:[timerInterval], di		;save timer interval
	mov	cx, di				;first event occurs one 
						;	interval from now
	mov	ax, TIMER_EVENT_CONTINUAL	;send event when time out 
	mov	bx, ds:[termProcHandle]		;get process handle
	mov	dx, MSG_TIMEOUT
	call	TimerStart
	mov	ds:[timerHandle], bx		;save timer handle
	ret					;continual timers
						;  can ignore timer ID
FileStartTimer	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRestartTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restart the timer

CALLED BY:	FileRecvData

PASS:		ds, es		- dgroup

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		could 'restarting' a timer be done in another
		way instead of stopping and starting the timer?

		If FF_RECV_ABORT_TRIGGER_CLICKED is set, *and*
		termStatus is ON_LINE, then *don't* restart the
		timer.  Please note that this is a pretty hacky
		thing to do....		-mkh

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileRestartTimer	proc	near
	call	FileStopTimer			;stop the timer

	; \begin{hack}

	test	ds:[currentFileFlags], mask FF_RECV_ABORT_TRIGGER_CLICKED
	jz	startTimer
	cmp	ds:[termStatus], ON_LINE
	jnz	startTimer
	jmp	done
		
	; \end{hack}

startTimer:
	mov	di, ds:[timerInterval]		;and start it up again
	call	FileStartTimer
done:
	ret
FileRestartTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCheckPacketNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the packet number

CALLED BY:	FileRecvData

PASS:		ds		- dgroup
		ds:si		- beginning of packet
		cx		- number of characters in packet

RETURN:		C		- set if error (packet number no good)
				- clear if packet number ok

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
	If the packet number is valid
		restart the timer
		advance tranState variable 
	else
		reset tranState variable
		(let the timer run, when we timeout a NAK will be sent)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCheckPacketNum	proc	near
	mov	bl, ds:[si] 			;get packet number
	inc	si				;advance packet ptr
	dec	cx
	cmp	bl, ds:[packetNum]		;is it the one we want
	je	ok				;yes, check complement
	cmp	bl, ds:[prevPacket]
	je	sendAck
	jmp	error				;exit
sendAck:
	mov	ds:[sendACK], TRUE		;packet may be duplicate
	jmp	ok				;	send ACK when line clear
error:
	mov	ds:[tranState], TM_GET_SOH	;packet # dorked, reset state
	stc					;set error flag
	jmp	short exit
ok:
	mov	ds:[tranState], TM_GET_PAK_CMPL	;get packet complement
	clc
exit:			
	ret
FileCheckPacketNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCheckPackCompl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the packet number complement

CALLED BY:	FileRecvData

PASS:		ds		- dgroup
		ds:si		- beginning of packet
		cx		- number of characters in packet

RETURN:		cx		- number of chars left to process

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
	If the complement valid and sendACK != TRUE
		process rest of packet
	else
		clear out CX
		reset tranState variable
		(let the timer run, when we timeout a NAK will be sent)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCheckPackCompl	proc	near
	mov	bl, ds:[si] 			;get compl number
	mov	bh, bl				;store it in bh and bl
	inc	si				;advance packet ptr
	dec	cx				;decrement # of chars in pack
	add	bl, ds:[packetNum]		;is this complement of exp
	cmp	bl, PACKET_NUM_CHECK		;	packet?
	je	ok				;nope
checkPrev:
	add	bh, ds:[prevPacket]		;is this complement of prev
	cmp	bh, PACKET_NUM_CHECK		;	packet?
	jne	error				;nope complement dorked
	mov	ds:[tranState], TM_SEND_ACK	;yes, ack the complement
	clr	cx				;ignore this packet
	jmp	short exit
ok:	
	mov	ds:[tranState], TM_IN_PACKET	;we're inside a packet now
	clr	ds:[checksumCRC]		;zero out checksum
	clc					;flag no error
	jmp	exit
error:
	mov	ds:[sendACK], FALSE		;don't send ACK
	mov	ds:[tranState], TM_GET_SOH	;packet number goofed
						;look for start of packet
	stc					;set error flag
exit:			
	ret
FileCheckPackCompl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileProcessPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	process packet of characters

CALLED BY:	FileRecvData

PASS:		ds		- dgroup
		ds:si		- buffer to read chars from
		cx		- number of characters in packet

RETURN:		---

DESTROYED:	dx


PSEUDO CODE/STRATEGY:
	calculate checksum
	if packet done
	    if checksum good
		write packet out to disk
		update expected packet number and previous packet
	    else 
		send NAK
	else (if packet not done)
	    calc checksum
	    store packet into packetBuffer
	
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	***I know the packet of chars we get is in idata, so es = ds

	***Will it hurt to assume the checksum will be in the buffer, if
	   the rest of the packet is there?  Lets find out how bad of
	   an assumption this is

	***Processing of characters are a bit inefficent since characters
	   go from serial Driver to a temp buffer (es:bp), from this temp
	   buffer into packet buffer. Oh well, when time allows... 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileProcessPacket	proc	near
	call	FileStopTimer
	cmp	cx, ds:[expChars]		;is rest of packet here?
	jl	doChecksumCRC			;nope
packetDone:
	mov	bx, cx				;calc how many chars left
	mov	cx, ds:[expChars]		;	after packet data
	sub	bx, cx				;
doChecksumCRC:	
	sub	ds:[expChars], cx		;reduce num of expected chars
	call	CopyPacketToBuf			;copy charcters to packetbuf
	jc	dontRestartTimer		;just exit.
	cmp	ds:[useChecksum], TRUE		;are we using checksum?
	jne	doCRC				;CRC INSERT HERE
	call	CalcChecksum
	jmp	short storeChecksum
doCRC:
	call	CalcCRC				;calculate CRC for packet	
storeChecksum:
	mov	ds:[checksumCRC], ax		;update checksum count
	tst	ds:[expChars]			;is packet finished?
	je	packetFin			;yes
	mov	ds:[timerInterval], THREE_SECOND;nope, restart char timer
	jmp	short exit
packetFin:
	tst	bx				;is checksum here?
	jz	noChecksum			;nope		
	mov	cx, bx				;pass, # chars in buffer
	call	FileCheck1			;  and check the checksum
	jmp	short exit			;
noChecksum:
	mov	ds:[tranState], TM_GET_CHECK_1	;get checksum

exit:
	; don't wait for timeout to send NAK -- brianc 2/23/94
	call	FileSendNakNow
	call	FileRestartTimer

dontRestartTimer:
	ret
FileProcessPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCheck1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check first byte of checksum

CALLED BY:	FileRecvData, FileProcessPacket

PASS:		ds		- dgroup
		ds:si		- beginning of packet
		cx		- number of characters in packet

RETURN:		---

DESTROYED:	bx, dx	

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCheck1	proc	near
	mov	bh, ds:[si] 			;checksum/crc byte to check
	inc	si				;increment packet ptr
	dec	cx				;decrement packet count
	cmp	ds:[useChecksum], TRUE		;if using checksum
	jne	doCRC
	mov	bl, {byte} ds:[checksumCRC]	;get our checksum
	cmp	bh, bl				;does it match packet checksum?
	jne	error				;nop
ok:
	call	AckPacket
	jmp	short	exit
doCRC:
	mov	dx, ds:[checksumCRC]		
	cmp	dh, bh				;does first byte match
	jne	error
checkCRC2:
	mov	ds:[tranState],TM_GET_CHECK_2	;get second checkybte
	jcxz	exit
	call	FileCheck2			;check second byte
	jmp	short exit
error:
	mov	ds:[tranState], TM_SEND_NAK	;go into dorked state and
						;  wait for timeout to send NAK
exit:
	ret
FileCheck1	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCheck2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check second byte of CRC

CALLED BY:	FileRecvData, FileCheck1

PASS:		ds		- dgroup
		ds:si		- beginning of packet
		cx		- number of characters in packet

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCheck2	proc	near
	mov	bx, ds:[checksumCRC]		;get our checksum
	cmp	bl, ds:[si]			;see if equal
	je	ok
	mov	ds:[tranState], TM_SEND_NAK	;go into dorked state and
						;  wait for timeout to send NAK
	jmp	short exit
ok:
	call	AckPacket
exit:
	ret
FileCheck2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendNakNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send NAK now if needed, instead of waiting for timeout

CALLED BY:	FileRecvData, FileProcessPacket

PASS:		ds - dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSendNakNow	proc	near
EC <	call	ECCheckDS_dgroup					>
	cmp	ds:[tranState], TM_SEND_NAK
	jne	done
	push	ax, bx, di
	mov	ax, MSG_TIMEOUT			; fake timeout now
	mov	bx, ds:[termProcHandle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	ax, bx, di
done:
	ret
FileSendNakNow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRecvEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do tasks associated with having finished receiving a file

CALLED BY:	TermXModemRecv

PASS:		ds		- dgroup

RETURN:		---

DESTROYED:	ax, bx, si, di	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileRecvEnd	proc	near
		call	FileStopTimer			;stop the timer 
		call	ResetRecvTriggers 
		mov	bx, BOGUS_VAL
		xchg	bx, ds:[fileHandle]		;close up the file
		cmp	bx, BOGUS_VAL
		je	freeMem
	;
	; Make sure fileHandle was initialized to BOGUS_VAL in
	; FileRecvStart.  Encountered a bug where the fileHandle
	; wasn't initialized and had a null value, so FileClose
	; fataled error on this bad file handle.
	; 6/2/95 - ptrinh
	;
EC <		Assert	ne	bx, 0 				>
	;
	; Unregister document with IACP.  Do it first because FileClose
	; frees file handle.
	;
		call	UnregisterDocument

		mov	al, FILE_NO_ERRORS
		call	FileClose
		call	SendFileCloseFileChange
freeMem:
		clr	bx
		xchg	bx, ds:[packetHandle]	; get handle to packet buffer
		tst	bx
		jz	noBuf
		call	MemFree				; and free it
noBuf:
		clr	dx
		mov	ds:[numPacketRecv], dx
		call	ResetRecvStatus 	; reset file receive status

		call	FileTransEnd		; reset program variables
	
if	not _TELNET
		call	RestoreSerialFromFileTrans 
endif	; !_TELNET
	
		CallMod	EnableFileTransfer	; enable file transfer triggers

if	not _TELNET
		CallMod EnableScripts
		CallMod EnableProtocol
		CallMod EnableModemCmd
endif	; !_TELNET

	ret
FileRecvEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAbortRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has clicked 'Abort' trigger, so handle the
		cancellation of the recieve session.

CALLED BY:	AckPacket

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	- Send buffer of CHAR_CAN bytes.
	- Call FileRecvEnd.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	hirayama	4/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

abortStrBuf	db	LEN_CAN dup (CHAR_CAN)

FileAbortRecv	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	; Send off buffer filled with CHAR_CAN's...
	;
		mov	cx, LEN_CAN
		push	ds				; #1 store dgroup
		segmov	ds, cs
		mov	si, offset abortStr
		call	FileWriteBuf
		pop	ds				; #1 restore dgroup
	;
	; Handle cleanup work.
	;
		call	FileRecvEnd

		.leave
		ret
FileAbortRecv	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCRC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate CRC

CALLED BY:	FileProcessPacket

PASS:		ds:si		- packet of chars to calculate CRC for
		cx		- number of chars in packet
		bx		- # extra chars available
		es		- dgroup

RETURN:		ax		- CRC

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/22/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

crcTable	label	word
dw	0x0000,  0x1021,  0x2042,  0x3063,  0x4084,  0x50a5,  0x60c6,  0x70e7
dw	0x8108,  0x9129,  0xa14a,  0xb16b,  0xc18c,  0xd1ad,  0xe1ce,  0xf1ef
dw	0x1231,  0x0210,  0x3273,  0x2252,  0x52b5,  0x4294,  0x72f7,  0x62d6
dw	0x9339,  0x8318,  0xb37b,  0xa35a,  0xd3bd,  0xc39c,  0xf3ff,  0xe3de
dw	0x2462,  0x3443,  0x0420,  0x1401,  0x64e6,  0x74c7,  0x44a4,  0x5485
dw	0xa56a,  0xb54b,  0x8528,  0x9509,  0xe5ee,  0xf5cf,  0xc5ac,  0xd58d
dw	0x3653,  0x2672,  0x1611,  0x0630,  0x76d7,  0x66f6,  0x5695,  0x46b4
dw	0xb75b,  0xa77a,  0x9719,  0x8738,  0xf7df,  0xe7fe,  0xd79d,  0xc7bc
dw	0x48c4,  0x58e5,  0x6886,  0x78a7,  0x0840,  0x1861,  0x2802,  0x3823
dw	0xc9cc,  0xd9ed,  0xe98e,  0xf9af,  0x8948,  0x9969,  0xa90a,  0xb92b
dw	0x5af5,  0x4ad4,  0x7ab7,  0x6a96,  0x1a71,  0x0a50,  0x3a33,  0x2a12
dw	0xdbfd,  0xcbdc,  0xfbbf,  0xeb9e,  0x9b79,  0x8b58,  0xbb3b,  0xab1a
dw	0x6ca6,  0x7c87,  0x4ce4,  0x5cc5,  0x2c22,  0x3c03,  0x0c60,  0x1c41
dw	0xedae,  0xfd8f,  0xcdec,  0xddcd,  0xad2a,  0xbd0b,  0x8d68,  0x9d49
dw	0x7e97,  0x6eb6,  0x5ed5,  0x4ef4,  0x3e13,  0x2e32,  0x1e51,  0x0e70
dw	0xff9f,  0xefbe,  0xdfdd,  0xcffc,  0xbf1b,  0xaf3a,  0x9f59,  0x8f78
dw	0x9188,  0x81a9,  0xb1ca,  0xa1eb,  0xd10c,  0xc12d,  0xf14e,  0xe16f
dw	0x1080,  0x00a1,  0x30c2,  0x20e3,  0x5004,  0x4025,  0x7046,  0x6067
dw	0x83b9,  0x9398,  0xa3fb,  0xb3da,  0xc33d,  0xd31c,  0xe37f,  0xf35e
dw	0x02b1,  0x1290,  0x22f3,  0x32d2,  0x4235,  0x5214,  0x6277,  0x7256
dw	0xb5ea,  0xa5cb,  0x95a8,  0x8589,  0xf56e,  0xe54f,  0xd52c,  0xc50d
dw	0x34e2,  0x24c3,  0x14a0,  0x0481,  0x7466,  0x6447,  0x5424,  0x4405
dw	0xa7db,  0xb7fa,  0x8799,  0x97b8,  0xe75f,  0xf77e,  0xc71d,  0xd73c
dw	0x26d3,  0x36f2,  0x0691,  0x16b0,  0x6657,  0x7676,  0x4615,  0x5634
dw	0xd94c,  0xc96d,  0xf90e,  0xe92f,  0x99c8,  0x89e9,  0xb98a,  0xa9ab
dw	0x5844,  0x4865,  0x7806,  0x6827,  0x18c0,  0x08e1,  0x3882,  0x28a3
dw	0xcb7d,  0xdb5c,  0xeb3f,  0xfb1e,  0x8bf9,  0x9bd8,  0xabbb,  0xbb9a
dw	0x4a75,  0x5a54,  0x6a37,  0x7a16,  0x0af1,  0x1ad0,  0x2ab3,  0x3a92
dw	0xfd2e,  0xed0f,  0xdd6c,  0xcd4d,  0xbdaa,  0xad8b,  0x9de8,  0x8dc9
dw	0x7c26,  0x6c07,  0x5c64,  0x4c45,  0x3ca2,  0x2c83,  0x1ce0,  0x0cc1
dw	0xef1f,  0xff3e,  0xcf5d,  0xdf7c,  0xaf9b,  0xbfba,  0x8fd9,  0x9ff8
dw	0x6e17,  0x7e36,  0x4e55,  0x5e74,  0x2e93,  0x3eb2,  0x0ed1,  0x1ef0

CalcCRC	proc	near
	push	bx				;save extra char count
	mov	ax, es:[checksumCRC]		;get crc 
doCRC:
	mov	bx, ax				;		
	xor	bh, ds:[si]			; (chksm>>8)^c]
	inc	si				; advance char ptr
	mov	bp, offset crcTable		;
	mov	bl, bh				;point to table
	clr	bh
	shl	bx, 1				;compute offset into table
	add	bp, bx				;index into crc Table
	mov	dx, cs:[bp]			;	crctab[(chksm>>8)^c]   
	mov	ah, al 				;
	clr	al				;chksm<<8
	xor	ax, dx				;chksm<<8 ^ crctab[(chksm>>8)^c]
	loop	doCRC
	pop	bx
	ret
CalcCRC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileTransInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	init file transfer variables

CALLED BY:	FileRecvStart, FileSendStart

PASS:		ds		- dgroup

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dennis		12/27/89	Initial version
	hirayama	3/30/94

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileTransInit	proc	near
    	clr     cx
	mov     ds:[numTimeouts], cl            ;init transfer variables
	mov     ds:[numPacketErr], cl
	mov     ds:[numPacketRecv], cx
	mov     ds:[numPacketSent], cx
	mov     ds:[checksumCRC], cx            ;init packet checksum

	mov     ds:[useChecksum], TRUE		;default to standard xmodem
	mov     ds:[packetSize], PACKET_128     ;default to 128 byte packet
	mov     ds:[packetNum], FIRST_PACKET_NUM;set expected packet number
	mov     ds:[prevPacket], FIRST_PACKET_NUM
	clr	ds:[currentFileFlags]		; mkh 3/30/94
;;done in InitSerialForFileTrans - brianc 9/10/90
;;	mov     ch, SM_RAW                     	;set Raw serial line
;;	CallMod SetSerialLine
	ret
FileTransInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileTransEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reset program and file transfer variables after file
			transfer done

CALLED BY:	FileRecvStart, FileSendStart

PASS:		ds		- dgroup

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileTransEnd	proc	near
	cmp	ds:[termStatus], FILE_SEND
	je	closeSend
	GetResourceHandleNS	RecvStatusSummons, bx
	mov	si, offset RecvStatusSummons
	jmp	short dismissBox
closeSend:	
	GetResourceHandleNS	SendStatusSummons, bx
	mov	si, offset SendStatusSummons
dismissBox:
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

;;done in InitSerialForFileTrans - brianc 9/10/90
;;	mov	ch, SM_COOKED
;;	CallMod	SetSerialLine			;assume regular line is cooked
	CallMod	SetScreenInput 			;reset terminal mode
	clr	dl				;reset transfer variables
	mov	ds:[numTimeouts], dl		;
	mov	ds:[numPacketErr], dl
	ret
FileTransEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncSendPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	increment number packets sent in dialog box

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncSendPacket	proc 	near
	tst	ds:[numPacketErr]
	jz	10$
	clr	dx
	mov	ds:[numPacketErr], dl		;reset error count
	GetResourceHandleNS	SendErrors, bp	; bp:si = counter
	mov     si, offset SendErrors
	mov     di, offset dgroup:errorBuf
	CallMod	UpdateNoDupCounter
10$:
	tst	ds:[numTimeouts]
	jz	15$
	clr	dx
	mov	ds:[numTimeouts], dl
	GetResourceHandleNS	SendTimeouts, bp	; bp:si = counter
	mov	si, offset SendTimeouts
	mov	di, offset dgroup:timeoutBuf
	CallMod	UpdateNoDupCounter
15$:
	inc     ds:[numPacketSent]
	mov	dx, ds:[numPacketSent]			;update # packet errors
	GetResourceHandleNS	SentPackets, bp		; bp:si = counter
	mov     si, offset SentPackets
	mov     di, offset dgroup:packetNumBuf
	CallMod	UpdateNoDupCounter
	cmp	ds:[fileDone], TRUE			;if
	je	finished
	mov	ax, ds:[packetSize]			;advance ptr to next 
	sub	ds:[fileSize.low], ax			;update #chars to send
	jnc	20$
	dec	ds:[fileSize.high]
20$:
	inc	ds:[packetNum]				;increment packet #	
	call	ReadInPacket				;read in next packet
	call	SendPacket				;and send it 
	jc	sendErr
	jmp	short exit
sendErr:
	mov	ds:[fileDone], TRUE			;if
finished:
	call	SendEndOfFile				;tell remote we're done 
	mov	ds:[tranState], TM_ACK_EOT		;wait for ACK
exit:
	ret
IncSendPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a packet of characters 

CALLED BY:	IncSendPacket, IncSendErrors

PASS:		ds, es		- dgroup
		
RETURN:		C		- set if error writing packet	
				  clear if packet send ok

DESTROYED:

PSEUDO CODE/STRATEGY:
		The packet is assumed to be already set up
		We calculate the CRC everytime we send the packet
			could keep it around so that when we do have to
			resend we could do it faster (not going to yet).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendPacket	proc 	near
	cmp	ds:[tranState], TM_SEND_EOT
	jne	sendData
	call	SendEndOfFile
	jmp	exitOk
sendData:
	clr	ds:[checksumCRC]		;reset the packet checksum
	cmp	ds:[packetSize], PACKET_1K	;big or small packets?
	je	size1K
	mov	cl, CHAR_SOH
	jmp	short sendSize
size1K:
	mov	cl, CHAR_STX
sendSize:
	call	FileWriteChar			;send packet size

	mov	cl, ds:[packetNum]		;get packet num
	mov	dl, cl				;  (save it)		
	call	FileWriteChar			;write it out
	mov	cl, dl			
	not	cl
	call	FileWriteChar			;and its complement

	mov	cx, ds:[packetSize]		;set #chars in packet
	clr	si				;ds:si ->buffer to write out
	mov	bx, ds:[packetHandle]
	push	bx
	call	MemLock
	mov	ds, ax
	call	FileWriteBuf			;send packet data section
	pop	bx
	call	MemUnlock
	segmov	ds, es, cx
	jc	exit
	call	SendChecksumCRC			;send packet checksum/CRC
	mov	ds:[tranState], TM_GET_ACK	;	and wait for an ACK
	mov	di, FIVE_SECOND			;start timer waiting for ACK
	call	FileRestartTimer
exitOk:
	clc					;clear error flag
exit:
	ret
SendPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendChecksumCRC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send packet checksum or CRC

CALLED BY:	

PASS:		es		- dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendChecksumCRC	proc 	near
	mov	cx, ds:[packetSize]		;set #chars in packet
	clr	si				;compute from start of packet
	mov	bx, ds:[packetHandle]
	push	bx
	call	MemLock				; (ax = packet buffer segment)
	cmp	ds:[useChecksum], TRUE		;do checksum or CRC ?
	mov	ds, ax
	je	doCheck				; checksum, do it
	call	CalcCRC				;-- do CRC
	mov	dx, ax				;save CRC
	mov	cl, dh
	call	FileWriteChar			;send CRC Hi
	mov	cl, dl	
	jmp	short writeByte 		;send CRC Lo

doCheck:					;-- do checksum
	call	CalcChecksum	
	mov	dx, ax
	mov	cl, dl
writeByte:
	pop	bx				; unlock packet buffer first
	call	MemUnlock
	segmov	ds, es				;restore ds to dgroup		
	call	FileWriteChar			;write out checksum
						; (preserves dx)
	mov	ds:[checksumCRC], dx		;store checksum
	ret
SendChecksumCRC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncSendTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	increment number of send timeouts

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncSendTimeout	proc 	near
	inc     ds:[numTimeouts]
	clr	dh				;timeout only a byte value
	mov	dl, ds:[numTimeouts]		;update # packets received	
	GetResourceHandleNS	SendTimeouts, bp	; bp:si = counter
	mov     si, offset SendTimeouts
	mov     di, offset dgroup:timeoutBuf
	CallMod	UpdateNoDupCounter
	mov	al, ds:[numTimeouts]
	cmp     al, ds:[maxTimeouts]                 ;if max timed out
	jl      exit
	mov	bp, ERR_SEND_ABORT
	CallMod	DisplayErrorMessage
	call	FileSendAbort
exit:
	ret
IncSendTimeout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncSendErrors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	increment number of send timeouts

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		C		- set if error resending packet	
				  clear if packet ok

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncSendErrors	proc 	near
	inc     ds:[numPacketErr]
	clr	dh				;only a byte value
	mov	dl, ds:[numPacketErr]		;update # packets received	

	cmp	dl, MAX_PACKET_ERRS		;if too many errors then
	jb	10$				;then abort
	mov	bp, ERR_SEND_ABORT		; the transfer
	CallMod	DisplayErrorMessage		;
	call	FileSendAbort			;
;	clc					;clear error flag
;return error for this case - brianc 9/20/90
	stc
	jmp	short	exit			;
10$:
	GetResourceHandleNS	SendErrors, bp	; bp:si = counter
	mov     si, offset SendErrors
	mov     di, offset dgroup:errorBuf
	CallMod	UpdateNoDupCounter
	call	SendPacket			;resend packet
exit:
	ret
IncSendErrors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleRecvTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a file receive timeout

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleRecvTimeout	proc 	near
	cmp     ds:[packetNum], FIRST_PACKET_NUM;  if so is the host dorked?
	jne     notCRC                          ;    nope
	cmp     ds:[useChecksum], FALSE         ;are we timing out cause
	jne     notCRC                          ;  host doesn't handle CRC?
	cmp     ds:[numCRCrequest], MAX_CRC_REQUEST
	jge     screwCRC
	inc     ds:[numCRCrequest]
	mov     cl, CHAR_CRC                    ;try CRC again
	call    FileWriteChar
	jmp     exit
screwCRC:
if	not _TELNET
	mov	cx, RECV_CHECKSUM
	call	SetRecvProto
endif
	 mov	ds:[useChecksum], TRUE		;use checksum method
	mov	cl, CHAR_NAK			;send NAK let host know we're
	jmp	short writeChar			;	here
notCRC:
	cmp     ds:[sendACK], TRUE              ;should we send an ACK
	jne     sendNAK                         ;nope
	mov     ds:[sendACK], FALSE             ;yep, reset flag
	mov     cl, CHAR_ACK                    ;send ACK if got duplicate
        jmp     short writeChar                 ;       packets
sendNAK:
;send NAK even if waiting for SOH - brianc 9/19/90
;	cmp	ds:[tranState], TM_GET_SOH	;if waiting for packet don't
;	je	20$				;send NAK, just inc timer
	cmp	ds:[tranState], TM_SEND_NAK	; checksum errors?
	jne	notCheckErr			; nope
	call	IncRecvErrs			; else, bump error counter
	jc	countedAsErr			; if too many errors, done
notCheckErr:
	mov     cl, CHAR_NAK                    ;
writeChar:
	call    FileWriteChar                   ;
	cmp	ds:[tranState], TM_SEND_NAK	; checksum errors?
	je	countedAsErr			; yep, counted as error
	call    IncRecvTimeout                  ;increment timeout count
countedAsErr:
	mov     ds:[tranState], TM_GET_SOH      ;reset state of file transfer
	clr     ds:[packetHead]                 ;point to start of packet buf
	mov     cx, ds:[packetSize]             ;
	mov     ds:[expChars], cx               ;set #of chars to expect
exit:
	ret
HandleRecvTimeout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleSendTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a timeout during file send

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		C		- set if error  resending  

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleSendTimeout	proc 	near
	cmp	ds:[tranState], TM_GET_REMOTE	;
	je	noRemote
regTimeout:
	call	IncSendTimeout
	call	SendPacket
	jmp	short exit
noRemote:
	mov	bp, ERR_NO_REMOTE		
	CallMod	DisplayErrorMessage
	call	FileSendAbort
	clc
exit:
	ret
HandleSendTimeout	endp

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRecvProto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get protocol to use to receive packets 

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Can't tell it to receive in 1K chunks
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRecvProto	proc 	near
	mov	si, offset RecvFileType		;is this a text download?
	mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	CallTransferUI				;ax = type
	cmp     ax, RECV_TEXT
	je	getText
	mov	ds:[recvText], FALSE
	jmp	short getProt
getText:
	mov	ds:[recvText], TRUE
getProt:
	mov     si, offset RecvProtocol
	mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	CallTransferUI				;ax = proto
	cmp     ax, RECV_CRC
	jne    	exit
crc:
	mov     ds:[useChecksum], FALSE         ;xmodem crc
exit:
	ret
GetRecvProto	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRecvProto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set protocol to use to receive packets 

CALLED BY:	

PASS:		ds, es		- dgroup
		cx		- proto to set
		
RETURN:		

DESTROYED:	ax, bx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRecvProto	proc 	near
	push	si, cx
	mov     si, offset RecvProtocol
	clr	dx
	mov     ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	SendTransferUI				;send event to transferUI
	pop	si, cx
exit:
	ret
SetRecvProto	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSendPacketSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set size of packets to send

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSendPacketSize	proc 	near
	push	cx, si
	clr	dx
	mov     si, offset SendPacketSize
	mov     ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	SendTransferUI				;send event to TransferUI
	pop	cx, si
	ret
SetSendPacketSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSendPacketSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get size of packets to send

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSendPacketSize	proc 	near
	mov     si, offset SendPacketSize
	mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	CallTransferUI				; ax = size (128 or 1024)
	cmp	ax, 128				;default is 128
	je	exit
	mov     ds:[packetSize], PACKET_1K      	;xmodem 1K
exit:
	ret
GetSendPacketSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcChecksum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calculate packet checksum

CALLED BY:	

PASS:		es		- dgroup
		cx		- #chars in buffer
		ds:si		- packet to compute checksum for
		
RETURN:		ax		- checksum

DESTROYED:	si, ax, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcChecksum	proc 	near
	mov	al, {byte} es:[checksumCRC]	;get current checksum
doChecksum:
	add	al, ds:[si]			;add character to check sum
	inc	si
	loop	doChecksum
	ret
CalcChecksum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendEndOfFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	tell remote we're done sending

CALLED BY:	

PASS:		ds, es		- dgroup
		
RETURN:		C		- clear if no error
				- set if should stop transfer

DESTROYED:	

PSEUDO CODE/STRATEGY:
		Send EOT
		keep track of number of times we've sent EOT
		abort when we hit SEND_EOT_MAX

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendEndOfFile	proc 	near
	mov	ds:[tranState], TM_ACK_EOT
	inc	ds:[numEOTsent]
	cmp	ds:[numEOTsent], MAX_SEND_EOT
	je	completeErr
	mov	cl, CHAR_EOT
	call	FileWriteChar
	clc						;flag no error
	jmp	short exit
completeErr:
	mov	bp, ERR_RESP_COMPLETE			;remote isn't responding
	CallMod	DisplayErrorMessage			;to EOT
	stc						;flag error - file quit
exit:
	ret
SendEndOfFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quit trying to send the file

CALLED BY:	

PASS:		
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSendEnd	proc 	near
	;
	; Stop timer and close file if file handle set to BOGUS_VAL.
	;
		call	FileStopTimer
		mov	bx, BOGUS_VAL
		xchg	bx, ds:[fileSendHandle]		; close up the file
		cmp	bx, BOGUS_VAL
		je	noClose
	; 
	; Unregister document with IACP.  Do this first because FileClose
	; will invalidate the file handle.
	;
		call	UnregisterDocument

		mov	al, FILE_NO_ERRORS
		call	FileClose
noClose:
		clr	bx
		xchg	bx, ds:[packetHandle]		; free packet buffer
		tst	bx
		jz	noBuf
		call	MemFree
noBuf:
		call	ResetSendTriggers
		call	FileTransEnd
		clr	dx
		mov	ds:[numPacketSent], dx
		call	ResetSendStatus			; reset send display

		call	RestoreSerialFromFileTrans 
		CallMod	EnableFileTransfer			

		CallMod EnableScripts
		CallMod EnableProtocol
		CallMod EnableModemCmd

		ret
FileSendEnd	endp

endif	; !_TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpenForSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do junk associated with sending a file 

CALLED BY:	(INTERNAL) FileSendFileOpenControlOpenFile
PASS:		ds:dx		- file to open
		(ds - dgroup)
		es		- dgroup	

		Responder also:

		ds:si		- DocumentInfo

RETURN:		fileSize	- set to size of file	
		fileSendHandle	- handle of file to send
		packetHandle	- contains handle of buffer segment
		C		- set if error condition
		ds		- dgroup
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpenForSend	proc 	near
		uses	dx, bp
		.enter


	;
	; Open regular doc.
	;
		mov     al, (mask FFAF_RAW) or FILE_ACCESS_R or FILE_DENY_NONE
		call    FileOpen			;either GEOS or DOS
afterOpen:
		jc	errorHandler
		mov	es:[fileSendHandle], ax		;save file handle
		mov     bx, ax                  	;pass file handle in BX

	
		mov     al, FILE_POS_END       		;jump to end
		clr     cx                     		;clear offsets
		clr     dx
		call    FilePos
		mov	es:[fileSize.high], dx
		mov	es:[fileSize.low], ax

		mov	al, FILE_POS_START		; back to the beginning
		clr     cx                      	
		clr     dx
		call    FilePos

allocPacket::
		mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE
if DBCS_PCGEOS
		cmp	ds:[sendProtocol], NONE		;ascii send?
		jne	10$			;xmodem, use FILE_BUF_SIZE
		mov	ax, (PACKET_1K)*5		;1-to-2 and 2-to-5 expansion
		jmp	short 15$
10$:
		mov	ax, FILE_BUF_SIZE	;alloc a packet of memory
15$:
else
		mov	ax, FILE_BUF_SIZE	;alloc a packet of memory
	
endif 	; if DBCS_PCGEOS
	
	
		call    MemAlloc                ; if can't get memory flag
		jnc	packetAllocated				
		mov	bx, es:[fileSendHandle]				
		call	UnregisterDocument				
RSP <		call	FoamDocClose					>
		mov	bp, ERR_NO_MEM_FTRANS	; not enough mem for transfer
		jmp	useTermErr					
	
packetAllocated:
		mov	es:[packetHandle], bx
		clc					;flag no error
		jmp	short exit

errorHandler:
	;
	; ds:dx = filename
	;
		cmp	ax, ERROR_SHARING_VIOLATION	; sharing error?
		jne	noSharing			; nope
	
sharingErr::
SBCS <		call	ConvertDSDXDOSToGEOS		; convert filename >
		mov	cx, ds				; cx:dx = filename
		mov	bp, ERR_FILE_OPEN_SHARING_DENIED
		jmp	short useTermErr

	
noSharing:
		mov	bp, ERR_FTRANS_FILE_OPEN	; can't open
useTermErr:
		segmov	ds, es, ax
		CallMod	DisplayErrorMessage
errorExit:
		stc
exit:
		segmov	ds, es, cx

		.leave
		ret
FileOpenForSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadInPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read in a packet of characters

CALLED BY:	FileSendData, IncSendPacket

PASS:		ds	- dgroup	

RETURN:		
	
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
	if we have a packet of chars
		read it in
	Else
		if can reduce packet size
			reduce it and try to read in new packet
		Else 
			stuff the packet
			set end of file flags


KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadInPacket	proc 	near
getPacket:
	mov	cx, ds:[packetSize]		;
	sub	cx, ds:[fileSize.low]		;is there a full packet to send
	jb	fullPacket			;yes,
	tst	ds:[fileSize.high]		
	jnz	fullPacket
shrinkPacket:					;nope
	cmp	ds:[packetSize], PACKET_128	;can we reduce packet size
	je	stuffPacket			;nope	
	mov	ds:[packetSize], PACKET_128
;	mov	cx, 128				;reduce packet
;	call	SetSendPacketSize
	jmp	short getPacket
stuffPacket:
	mov	ds:[fileDone], TRUE
	mov	bp, cx				;save #chars to stuff
	mov	cx, ds:[fileSize.low]		;set #chars to read
	jmp	short doRead
fullPacket:
	mov	cx, ds:[packetSize]		;set# chars to read
	clr	bp				;no chars to stuff
doRead:
	mov	bx, ds:[packetHandle]
	push	bx
	call	MemLock
	mov	bx, ds:[fileSendHandle]
	mov	ds, ax
	mov	di, ax				; save segment for later
						;read a packet of chars into
	clr	dx				;	packetBuffer
	clr	al				;set to report errors
	call	FileRead
	segmov	ds, es, dx			;restore ds to dgroup
	tst	bp				;do we have to stuff packet?
	jz	packetDone			;nope, done with packet
	mov	es, di				;yep, go to end of packet
	mov	di, cx				;
	mov	cx, bp				;     set #chars to stuff
	mov	al, CHAR_PAD			;
	rep	stosb				;     stuff CHAR_PAD into es:di
	segmov	es, ds, dx			;     restore es to dgroup
packetDone:
	pop	bx				; bx = packet buffer handle
	call	MemUnlock
	ret
ReadInPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the name of the file we're sending

CALLED BY:	(INTERNAL) FileRecvStart
PASS:		bx:si	- chunk:offset of text object
		ds:dx	- name of file to send
RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFileName	proc 	near
	uses	dx, es, ds
	.enter
if not DBCS_PCGEOS
	;
	; copy onto stack buffer and DOS->GEOS convert
	;
	mov	cx, FILE_LONGNAME_BUFFER_SIZE
	sub	sp, cx
	segmov	es, ss, ax			; es:di = stack buffer
	mov	di, sp
	push	si				; save chunk
	mov	si, dx				; ds:si = name
	mov	dx, di
	rep movsb				; copy over
	mov	ds, ax				; ds:dx = stack name
	call	ConvertDSDXDOSToGEOS		; convert to GEOS for display
	pop	si				; retrieve chunk
endif
	clr	cx				;null terminated string	
	mov	bp, dx				;	
	mov	dx, ds				;dx:bp->string to set
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
if not DBCS_PCGEOS
	add	sp, FILE_LONGNAME_BUFFER_SIZE
endif
	.leave
	ret
SetFileName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoAsciiSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the name of the file we're sending

CALLED BY:	SendFile	

PASS:		bx:si	- chunk:offset of text object
		ds:dx	- name of file to send
RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoAsciiSend	proc 	near
	mov     ax, MSG_GEN_SET_NOT_USABLE
	mov     dl, VUM_NOW                     ;xmodem packet status not
	GetResourceHandleNS	SendStatus, bx
	mov	si, offset SendStatus 		;
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	GetResourceHandleNS	SendStatusSummons, bx
	mov     si, offset SendStatusSummons    ;enable send status box
	mov     ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	mov	cx, mask TSF_STRIP_LINEFEED
	mov	si, offset TextSendList		;should we strip linefeeds?
	CallTransferUI				;
	jc	5$				;yes
	mov	ds:[stripLF], FALSE
	jmp	short 10$
5$:
	mov	ds:[stripLF], TRUE
10$:
	mov	ds:[inMiddleOfPacket], FALSE	; start with new packets
if DBCS_PCGEOS	;------------------------------------------------------------
	mov	ax, ds:[bbsRecvCP]
	mov	ds:[echoPacketCP], ax
	call	StartEcho
endif	;--------------------------------------------------------------------
	call	SendAsciiPacket
	mov	ds:[fileDone], FALSE		;
	ret
DoAsciiSend	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendAsciiPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a packet from an ascii file

CALLED BY:	(INTERNAL) FileSendAsciiPacket, FileSendFileOpenControlOpenFile
PASS:		ds	- dgroup

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendAsciiPacket	proc 	near
	
EC <	call	ECCheckDS_ES_dgroup					>
	cmp	ds:[fileTransferCancelled], TRUE	; cancelled?
	jne	continue				; nope, continue
cancelled:
RSP <	jmp	done
NRSP <	call	FileSendAbort				; yes, abort	>
NRSP <	jmp	exit							>

continue:
	cmp	ds:[inMiddleOfPacket], TRUE	; in middle of packet?
	jne	normalPacket			; no, handle normally
	mov	cx, ds:[middleOfPacketSize]	; cx = size of rest of packet
	mov	si, ds:[middleOfPacketOffset]	; si = offset to rest of packet
	jmp	sendPacket			; send rest of packet

normalPacket:
	mov     cx, PACKET_1K			;
	;
	; In Responder, in order to read a Foam doc, you have to continuously
	; read it until it has nothing.returned. This is mainly because the
	; text length previous retrieved assumes GEOS char set. But the real
	; # chars read would be DOS based (line feed inserted). So we can't
	; continuously subtract the #chars read from file size to see how
	; many chars left to be read.
	;
	; So, the size of data to read is always 1 full packet.
	;
	cmp     cx, ds:[fileSize.low]           ;is there a full packet to send
	jb      fullPacket                      ;yes, do it
	tst     ds:[fileSize.high]
	jnz     fullPacket
	mov	ds:[fileDone], TRUE		;this is last packet to send
	mov	cx, ds:[fileSize.low]	
	tst	cx
	jnz	readInPacket
	jmp	done

fullPacket:
	mov	cx, PACKET_1K			;			
readInPacket:
	mov	bx, ds:[packetHandle]
	push	bx
	call	MemLock				; ax = packet buffer segment
	mov     bx, ds:[fileSendHandle]
SBCS <	push	ds:[bbsCP]			; save destination code page>
	mov     ds, ax				;read a packet of chars into
SBCS <	clr     dx                              ;	packetBuffer	>
	;
	; DBCS: read into end of packet buffer to allow for
	; 	conversion expansion
	;
DBCS <	mov	dx, (PACKET_1K)*4					>
	
	
	clr     al                              ;set to report errors
	call    FileRead
	
doneFileRead::
SBCS <	pop	dx				;dx = BBS code page	>
	LONG jc	sendErr				; if error, bail out
	;
	; convert from DOS code page (disk file) to BBS code page
	;	cx = number of DOS code page chars read in
	;	SBCS: dx = BBS code page
	;	es = dgroup
	;
if DBCS_PCGEOS	;-------------------------------------------------------------
	push	es				; save dgroup
	mov	bp, cx				; bp = # DOS code page bytes
retryConvert:
	;
	; convert from DOS code page at end of buffer to GEOS at beg of buffer
	;	cx = # DOS code page bytes
	;
	push	es:[bbsSendCP]
	push	bx				; save file handle
	segmov	es, ds, ax
	mov	ax, MAPPING_DEFAULT_CHAR
	mov	si, (PACKET_1K)*4		; ds:si = conv. source
	clr	di				; es:di = conv. dest
	mov	bx, di				; from DOS code page
	mov	dx, di				; primary FSD
	call	LocalDosToGeos			; DOS code page to GEOS
	pop	bx				; bx = file handle
	pop	dx				; dx = BBS code page
	jnc	convertOK
	cmp	al, DTGSS_CHARACTER_INCOMPLETE
EC <	WARNING_NE	XFER_OUT_CONVERSION_ERROR			>
	stc					; in case not CHAR_INCOMPLETE
	jne	convertErr
	;
	; handle character incomplete, back up DOS code page chars and
	; try again -- not the most effiect way, but simpler than saving
	; incomplete characters until next buffer set
	;	bx = file handle
	;
	mov	al, FILE_POS_RELATIVE
	movdw	cxdx, -1
	call	FilePos
	dec	bp				; one less DOS code page char
	mov	cx, bp				; cx = # DOS code page chars
	pop	es				; es = dgroup
	push	es
	jmp	short retryConvert

convertOK:
	;
	; move GEOS chars from beg of buffer to end of buffer
	;	cx = # GEOS chars
	;	dx = BBS code page
	;
	push	cx
	clr	si				; ds:si = move source
	mov	di, (PACKET_1K)*3		; es:di = move dest
	rep	movsw
	;
	; convert GEOS chars to BBS code page chars
	;
	pop	cx				; cx = # GEOS chars
	mov	si, (PACKET_1K)*3		; ds:si = conv. source
	clr	di				; es:di = conv. dest
	mov	ax, MAPPING_DEFAULT_CHAR
	mov	bx, dx				; bx = BBS code page
	clr	dx				; primary FSD
	call	LocalGeosToDos			; cx = # BBS code page chars
EC <	WARNING_C	XFER_OUT_CONVERSION_ERROR			>
convertErr:
	pop	es
	jnc	doneConvert
PrintMessage <SendAsciiPacket: report conversion error?>
	jmp	convertExit

doneConvert:
	xor	si, si				; ds:si = buffer to send
						; (clears carry)
else	;---------------------------------------------------------------------

	clr	si				; ds:si = buffer
	;
	; Responder foam lib will do Code page conversion, so we don't
	; need to do it here.
	;
	mov	ax, MAPPING_DEFAULT_CHAR
	call	LocalDosToGeos			; convert to GEOS char set
	mov	bx, dx				; bx = destination code page
	call	LocalGeosToCodePage		; convert to BBS code page
if INPUT_OUTPUT_MAPPING
	call	OutputMapBuffer
endif
	
RSP <	pop	ax				; restore 		>

endif	;---------------------------------------------------------------------

DBCS <convertExit:							>
	pop	bx
	call	MemUnlock			; preserves flags
	segmov  ds, es, dx                      ;restore ds to dgroup
DBCS <	jc	sendErr							>
	
	;
	; AX <- chars in file to be processed. It may not necessarily
	; mean the number of characters to be sent as the convertion
	; routines may add or remove characters.
	; 
if DBCS_PCGEOS
	;
	; bp = # DOS code page chars
	;
	sub     ds:[fileSize.low], bp           ;update #chars left to send
	jnc     20$
	dec     ds:[fileSize.high]
20$:
else
	
	sub     ds:[fileSize.low], cx           ;update #chars left to send
	jnc     20$
	dec     ds:[fileSize.high]
20$:
endif
sendPacket:
	call	CheckAsciiSend			;send out packet and check
						; cx = # bytes sent
						; bp = offset to bytes sent
	jc	sendErr
;
; we echo manually instead of calling BufferedSendBuffer in CheckAsciiSend
; for performance reasons - brianc 1/8/91
;
	cmp	ds:[halfDuplex], TRUE		;if in half duplex mode
	jne	40$				;then echo data on screen
	mov	bx, ds:[packetHandle]
	push	bx
	call	MemLock
	mov	dx, ax				;pass buffer(dx:bp) to read
						;  (bp from CheckAsciiSend)
;;	mov	ax, MSG_READ_BUFFER		;  to serial thread
;;	mov	bx, ds:[threadHandle]
;;	mov     di, mask MF_FORCE_QUEUE
;;	call	ObjMessage
;;block will not be around when this method is processed!
	call	SendMethodReadBlock		; copy data to buffer and send
						;	method to serial thread
;;
	pop	bx
	call	MemUnlock
	segmov	es, ds, dx			; es= dgroup
40$:
	tst	ds:[fileDone]			; any more packets?
	jz	sendNext			; yes
	cmp	ds:[inMiddleOfPacket], TRUE	; in middle of packet?
	je	sendNext			; yes
	jmp	done				; if not, done sending file

sendNext:

	cmp	ds:[fileTransferCancelled], TRUE	; user cancelled?
	LONG je	cancelled				; yes

;;	mov	ax, MSG_SEND_ASCII_PACKET	;then send method to get
;;	mov     bx, ds:[termProcHandle]         ; us to send next packet
;;	mov     di, mask MF_FORCE_QUEUE		;
;;	call    ObjMessage			;	
;;delay a bit
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[termProcHandle]
	mov	cx, ONE_SECOND/4
	mov	dx, MSG_SEND_ASCII_PACKET
	call	TimerStart
;;
	jmp	short exit			;
sendErr:
	mov	ds:[fileDone], TRUE		;we're fudged, we're brownies
done:
if DBCS_PCGEOS	;------------------------------------------------------------
	mov	ax, ds:[echoPacketCP]		; ax = desired CP
	call	EndEcho
endif	;--------------------------------------------------------------------
	call	EndAsciiSend	
exit:
	ret
SendAsciiPacket	endp 

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndAsciiSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do tasks associated when finish sending an ascii file	 

CALLED BY:	(INTERNAL) FileSendAbort, SendAsciiPacket
PASS:		ds	- dgroup

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:
	close the file
	enable the xmodem status stuff
	take down the status box

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndAsciiSend	proc 	near
	mov	bx, BOGUS_VAL
	xchg	bx, ds:[fileSendHandle]		;close up the file	
	cmp	bx, BOGUS_VAL			;if file not even opened
	je	20$				;then forget it
	;
	; Unregister document before close.
	;
	call	UnregisterDocument
	mov	al, FILE_NO_ERRORS
	call	FileClose
20$:
	clr	bx
	xchg	bx, ds:[packetHandle]			;free packet buffer
	tst	bx
	jz	noBuf
	call	MemFree
noBuf:
;not needed for ASCII transfer - brianc 9/7/90
;	call	RestoreSerialFromFileTrans 
	CallMod	EnableFileTransfer		;enable file transfer triggers

if	not _TELNET
	CallMod EnableScripts
	CallMod EnableProtocol
	CallMod EnableModemCmd
endif	; !_TELNET

	GetResourceHandleNS	SendStatusSummons, bx
	mov     si, offset SendStatusSummons    ;enable send status box
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov     ax, MSG_GEN_SET_USABLE
	mov     dl, VUM_NOW                     ;xmodem packet status not
	GetResourceHandleNS	SendStatus, bx
	mov	si, offset SendStatus 		;
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	
	ret
EndAsciiSend	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAsciiSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send packet checking for CR/LF pairs

CALLED BY:	(INTERNAL) SendAsciiPacket
PASS:		ds		- dgroup
		cx		- #chars in packet
		ds:[packetHandle]	- packet buffer handle
		si		- offset to start of packet

		(characters in BBS code page)

RETURN:		cx		- # bytes sent
		bp		= offset to bytes sent
		C		- set if couldn't send packet
				  clear if okay
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckAsciiSend	proc 	near
	mov	bx, ds:[packetHandle]
	push	bx
	call	MemLock
	mov	es, ax
	mov	dx, cx				;save buffer size
;;check later as we want to delay after each line - brianc 10/4/90
;;	tst	ds:[stripLF]
;;	jz	20$				;okay strip time
	mov	di, si				;copy ptr to start of buffer
searchBuf:
	mov	cx, dx				;pass buffer size
	mov	si, di				;es:si->buffer to search
	;
	; CX = DX = size of data to send
	; ES:SI = ES:DI -> buffer to send
	;
;DBCS: we don't care if we find a CHAR_CR sitting in a two-byte encoding --
;it won't be the high-byte because JIS and SJIS don't allow CHAR_CR as the
;high-byte, if it is the low-byte, the following byte can be the high-byte
;of another two-byte char or an escape, neither of these can be a CHAR_LF
	mov	al, CHAR_CR			;	
	repne	scasb				;search for CR/LF
	jnz	20$				;if no CR/LF found then
						;  send the buffer
	xchg	cx, dx				;update #chars left in file
	sub	cx, dx				;cx - #chars to write 

if 0	; old linefeed strip
	tst	ds:[stripLF]			; strip LFs?
	jz	10$				; nope, send this line

	tst	dx				; any chars after CR?
	jz	10$				; if not, no LF stripping
	cmp	{byte} es:[di], CHAR_LF
	jne	10$
	inc	di				;advance ptr past LF
	dec	dx				;reduce #chars left to process
endif	; if 0

10$:
	mov	ax, MAX_NUM_BUFFERED_SEND_CHARS
	cmp	cx, ax
	jbe	sendEm
	xchg	ax, cx				; ax = count, cx = max
	sub	ax, cx				; ax = count of chars not sent
	add	dx, ax				; add back onto remainder count
	sub	di, ax				; push back offset into packet
sendEm:
	;
	; strip linefeeds if needed
	;	assumption here is that LF will follow CR, since we stopped
	;	at CR, LF will be at beginning of next buffer
	;
	tst	ds:[stripLF]
	jz	50$
	cmp	{byte} es:[si], CHAR_LF
	jne	50$
	inc	si				; skip LF
	dec	cx				; one less char to send
50$:
	mov	bp, si				; set up return value
	call	SendBuffer			;es:si ->buffer to send
	jc	exit				;exit if send error

	;
	; If not all the bytes can be sent, we reset the size and pointers
	; for the next packet to send.
	;				
	sub	si, bp				; si = #chars sent
	sub	cx, si				; cx = #chars unsent
	jz	dataSent
	
	;
	; Reset the pointers and remaining file size
	; 
EC <	WARNING TERM_ASCII_SEND_FAIL					>
	sub	di, cx				; di <- reset packet Offet
	add	dx, cx				; dx <- reset remaining dataSz
	
dataSent:
	tst	dx				; buffer done?
	mov	ds:[inMiddleOfPacket], FALSE	; assume so
	jz	doneWithPacket			; yes
	mov	ds:[middleOfPacketOffset], di	; save offset within packet
	mov	ds:[middleOfPacketSize], dx	; save packet size
	mov	ds:[inMiddleOfPacket], TRUE	; flag that we are in a packet

doneWithPacket:
	clc					;clear error flag
exit:
	pop	bx				; unlock packet buffer
	call	MemUnlock
	ret		; <-- EXIT HERE

20$:
	;
	; no CR found, send rest of packet
	;	es:si = rest of packet
	;	es:di = pointer past end of packet
	;	dx = packet size
	;
	mov	cx, dx				;pass #chars to write
	clr	dx				; no chars left in packet
	cmp	cx, MAX_NUM_BUFFERED_SEND_CHARS	; few enough chars to write?
	ja	10$				; no, send partial packet
	jmp	sendEm				; else, send rest of packet
CheckAsciiSend	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoAsciiRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start receive an ascii file

CALLED BY:	(INTERNAL) FileRecvStart
PASS:		ds		- dgroup

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoAsciiRecv	proc 	near

	GetResourceHandleNS	AsciiRecvSummons, bx
	mov     si, offset AsciiRecvSummons    ;enable recv status box
	mov     ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	mov	cx, mask TRF_CONVERT_CR
	mov	si, offset TextRecvList		;should we convert CR to CR/LF?
	CallTransferUI				;
	jc	5$				;yes

	mov	ds:[checkCRLF], FALSE
	jmp	short 50$
5$:
	mov	ds:[checkCRLF], TRUE
50$:						;return the focus to the
DBCS <	mov	ds:[checkLFNextTime], BB_FALSE				>
	mov     ax, MSG_GEN_MAKE_FOCUS		;screen object 
	GetResourceHandleNS	TermView, bx
	mov     si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	ret
DoAsciiRecv	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndAsciiRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End ascii receive file

CALLED BY:	(INTERNAL) FileRecvAbort
PASS:		ds		- dgroup

RETURN:		
	
DESTROYED:	ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndAsciiRecv	proc 	near
	mov	bx, BOGUS_VAL
	xchg	bx, ds:[fileHandle]		;close up the receive file
	cmp	bx, BOGUS_VAL
	je	noClose
	mov	al, FILE_NO_ERRORS
	;
	; Unregister document with IACP before closing file.
	;
	call	UnregisterDocument
	call	FileClose
	call	SendFileCloseFileChange
noClose:
	clr	bx
	xchg	bx, ds:[packetHandle]		; free packet buffer
	tst	bx
	jz	noBuf
	call	MemFree
noBuf:
	CallMod	SetScreenInput 			;reset terminal mode
;not needed for ASCII transfer - brianc 9/7/90
;	call	RestoreSerialFromFileTrans 
	CallMod	EnableFileTransfer

if	not _TELNET
	CallMod EnableScripts
	CallMod EnableProtocol
	CallMod EnableModemCmd
endif	; !_TELNET

	GetResourceHandleNS	AsciiRecvSummons, bx
	mov     si, offset AsciiRecvSummons    	;dismiss recv status box
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
EndAsciiRecv	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteAsciiPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write out ascii packet to disk

CALLED BY:	(INTERNAL) AsciiRecvData
PASS:		es,ds	- dgroup (non _CAPTURE_CLEAN_TEXT)
		es	- dgroup (_CAPTURE_CLEAN_TEXT)
		ds:si	- buffer of chars
		cx	- #chars in buffer	

		(characters are in BBS code page)

RETURN:		carry set if there was an error
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteAsciiPacket proc 	near

if	not _TELNET
if	not _CAPTURE_CLEAN_TEXT
EC <	call	ECCheckRunBySerialThread				>
endif	; !_CAPTURE_CLEAN_TEXT
endif	; !_TELNET

if DBCS_PCGEOS	;-------------------------------------------------------------

	uses	si, cx
numGEOSChars	local	word
charReplaced	local	wchar
charOffset	local	word
charsSaved	local	word
saveOffset	local	word
	.enter



if	_CAPTURE_CLEAN_TEXT
EC <	call	ECCheckES_dgroup					>
else
EC <	call	ECCheckDS_ES_dgroup					>
endif	; _CAPTURE_CLEAN_TEXT	
	
	mov	charsSaved, 0
	;
	; prepend any saved chars
	;
CCT <	push	ds							>
CCT <	GetResourceSegmentNS	dgroup, ds				>
	mov	ax, cx				; ax = # incoming bytes
	mov	cx, ds:[numAsciiRecvUnconvertedBytes]			
	jcxz	noneSaved			; no unconverted bytes
	push	si
	mov	si, offset asciiRecvUnconvertedBytesBuf ; ds:si = saved chars
	mov	di, offset convertBuf2
	rep	movsb				; copy saved chars
	pop	si				; ds:si = incoming bytes
	mov	cx, ax				; cx = # incoming bytes
CCT <	pop	ds							>
	rep	movsb				; tack on new incoming bytes
CCT <	GetResourceSegmentNS	dgroup, ds				>
	mov	si, offset convertBuf2		; ds:si = joined bytes
	add	ax, ds:[numAsciiRecvUnconvertedBytes]	; ax = total # bytes
EC <	cmp	cx, AUX_BUF_SIZE					>
EC <	WARNING_A	BUFFER_OVERFLOW					>
noneSaved:
	mov	cx, ax				; cx = # incoming bytes
	;
	; convert from BBS code page to GEOS char set
	;	ds:si = BBS code page chars
	;	cx = # BBS code page chars
	;	ds = es = dgroup
	;
convertEntry:
	mov	saveOffset, si			; initialize offset of chars
	add	saveOffset, cx			;	to save
	mov	ds:[numAsciiRecvUnconvertedBytes], 0			
convertTop:
	push	cx				; save # BBS code page chars
 	mov	bx, es:[bbsRecvCP]		; bx = BBS code page
	mov	ax, MAPPING_DEFAULT_CHAR
	mov	di, offset convertBuf		; es:di = conversion buffer
	clr	dx
	call	LocalDosToGeos			; cx = # GEOS chars
	pop	dx				; dx = # BBS code page chars
	jnc	convertOK
	cmp	al, DTGSS_CHARACTER_INCOMPLETE
	je	convertInc
	;
	; other conversion error, throw away any unconverted bytes and
	; start afresh with next bunch of input, hopefully we'll sync up
	; again
	;
EC <	WARNING	XFER_IN_CONVERSION_ERROR				>
PrintMessage <WriteAsciiPacket: improve this if converted count is returned>
	
	;
	; use returned count of GEOS chars successfully converted and throw
	; away the rest
	;
convertErr:
	mov	ds:[numAsciiRecvUnconvertedBytes], 0			
PrintMessage <WriteAsciiPacket: report conversion error?>
doneJMP:
	jmp	done

convertInc:
PrintMessage <WriteAsciiPacket: improve this if converted count is returned>
	;
	; handle character incomplete -- try again with one less character
	; in input buffer
	;	ds:si = BBS code page chars
	;	dx = # BBS code page chars
	;
	inc	charsSaved		; one more char to save
	dec	saveOffset		; back up save char pointer
	mov	cx, dx			; cx = # BBS code page chars
	dec	cx
	jcxz	doneJMP
	jmp	convertTop
	
convertOK:
	;
	; write to disk while converted CRs to CR-LFs, if necessary
	;	es:di = GEOS chars buffer
	;	cx = # GEOS chars
	;	es = ds = dgroup
	;	bx = updated BBS code page
	;
;Don't update bbsRecvCP as the buffer of data will go the FSM.  We don't
;want to change bbsRecvCP until the FSM process its chars.  The FSM will
;update bbsRecvCP.
;	mov	ds:[bbsRecvCP], bx		; update for JIS
writeMore:
EC <	call	ECCheckDS_ES_dgroup					>
EC <	cmp	cx, AUX_BUF_SIZE					>
EC <	WARNING_A	BUFFER_OVERFLOW					>
	mov	charReplaced, 0			; indicate last write
	mov	si, di				; ds:si = GEOS chars buffer
	tst	ds:[checkCRLF]			;should we check if lines are
	jz	writeBuf			;  terminated by CR/LF?
	mov	numGEOSChars, cx		; save # GEOS chars
	mov	ax, CHAR_CR
	tst	ds:[checkLFNextTime]		; if LF pending from last
	jnz	checkLF				;	buffer, check it
findCR:
	repne	scasw
	jne	writeRemainder			; no CR, convert and write
	jcxz	lfPending			; no CR, convert and write
checkLF:
	mov	ds:[checkLFNextTime], BB_FALSE
	cmp	{wchar} es:[di], CHAR_LF	; CR-LF already?
	je	findCR				; yes, keep searching
	;
	; found CR -- add LF, convert to DOS code page and write out bytes up
	; to this point
	;	es:di = char after CHAR_CR
	;
	mov	ax, CHAR_LF
	xchg	ax, es:[di]
	mov	charReplaced, ax
	mov	charOffset, di
	xchg	cx, numGEOSChars		; cx = total # GEOS chars
						; numGeosChars = # remaining
	sub	cx, numGEOSChars		; cx = # GEOS chars processed
	inc	cx				; cx = # GEOS chars to write
						;	(include LF)
	jmp	writeBuf

lfPending:
	mov	ds:[checkLFNextTime], BB_TRUE	; check for LF next time
writeRemainder:
	mov	cx, numGEOSChars
writeBuf:
	mov	di, offset convertBuf2
	
	;
	; Network writes to file in straight GEOS, since Memo app requires
	; it that way.
	;
	;
	; Responder foam lib will do Code page conversion, so we don't
	; need to do it here.
	;
	mov	ax, MAPPING_DEFAULT_CHAR
	clr	bx, dx				; DOS code page, primary FSD
	call	LocalGeosToDos			; cx = # DOS code page chars
EC <	WARNING_C	XFER_IN_CONVERSION_ERROR			>
	LONG jc	convertErr

EC <	call	ECCheckDS_ES_dgroup					>

	mov	dx, di				; ds:dx = DOS code page buffer

	push	bp
	mov	bp, es:[fileHandle]		; bp = capture file handle
	call	WriteBufToDisk
	pop	bp
	
	jc	done				; error, return carry set
	mov	ax, charReplaced
	tst_clc	ax
	jz	done				; no more to write, done
	mov	di, charOffset
	mov	es:[di], ax
	mov	cx, numGEOSChars		; cx = # GEOS chars left
	jmp	writeMore

done:
	mov	cx, charsSaved			; any chars to save?
	jcxz	exit				; nope, yippee!
EC <	cmp	cx, length asciiRecvUnconvertedBytesBuf			>
EC <	ERROR_A	-1							>
	mov	si, saveOffset			; ds:si = chars to save
	mov	di, offset asciiRecvUnconvertedBytesBuf	; es:di = save dest
	mov	ds:[numAsciiRecvUnconvertedBytes], cx
	rep	movsb				; copy chars to save
exit:
	clc					; no error -- let screen
						;	get characters no
						;	matter what happens
						;	here
	.leave
	ret

else	;---------------------------------------------------------------------

if	_CAPTURE_CLEAN_TEXT
EC <	call	ECCheckES_dgroup					>
else
EC <	call	ECCheckDS_ES_dgroup					>
endif	; _CAPTURE_CLEAN_TEXT	

	push	ds, si, cx			;save buffer variables 
	mov	dx, cx				;pass (and save) # input bytes
	;
	; convert from BBS code page to DOS code page, nondestructively
	;
	cmp	cx, 16				; check if heap buffer better
	jae	useHeap
	sub	sp, 16
	mov	bp, sp
	clr	bx
	push	bx				; indicate no buffer to free
	; optimiziation - usually only one char comes in and it doesn't need
	; translating
	cmp	cx, 1
	jne	noOpt
	cmp	{byte} ds:[si], MIN_MAP_CHAR
	jb	noMapping
noOpt:
	push	es				; save es = dgroup
	segmov	es, ss, ax			; es:di = stack buffer
	mov	di, bp
	rep movsb
	mov	si, bp
	jmp	short haveBuffer
useHeap:
	push	cx				; save # input bytes
	mov	ax, cx
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	pop	cx				; retrieve # input bytes
	LONG jc	noMem				; no capture if error
	push	bx				; save buffer handle
	push	es				; save dgroup
	mov	es, ax
	clr	di
	rep movsb				; copy over buffer
	clr	si				; ds:si = buffer of chars
haveBuffer:
	mov	ds, ax				; ds:si = input buffer
	pop	es				; retrieve es = dgroup
	mov	cx, dx				; cx = # input bytes
if INPUT_OUTPUT_MAPPING
	call	InputMapBuffer
endif
	;
	; Responder foam lib will do Code page conversion, so we don't
	; need to do it here.
	;
NRSP <	mov	bx, es:[bbsCP]			; source code page	>
NRSP <	mov	ax, MAPPING_DEFAULT_CHAR	; default character	>
NRSP <	call	LocalCodePageToGeos		; convert from serial line>
NRSP <	call	LocalGeosToDos			; convert to disk file	>
	
noMapping:
	tst	es:[checkCRLF]			;should we check if lines are
	jz	writeBuf			;  terminated by CR/LF?
	;
	; process buffer (add LF to CRs)
	;	ds:si = bufer of characters
	;
	mov	di, si				;set ptr to start of buf 	
topLoop:
	mov	cx, dx				;set size of buffer
	mov	ax, CHAR_CR			;search for CR
scanBuf:
	push	es				; save es=dgroup
	segmov	es, ds				; es:di = buffer
	repne	scasb
	pop	es				; retrieve es=dgroup
	jnz	writeBuf			;if no CR found or buffer empty 
	jcxz	writeBuf			;then write buffer out
	cmp	{byte} ds:[di], CHAR_LF		;else if CR followed by LF
	je	scanBuf				;then its okay and can continue
						;else write out a LF
	mov	ah, ds:[di]			;save byte following CR
	mov	{byte} ds:[di], CHAR_LF
	inc	dx
	xchg	cx, dx				;else write out till first CR
	sub	cx, dx
	push	ax, dx
	mov	dx, si
	mov	bp, es:[fileHandle]
	push	ds				; save buffer segment
	CallMod	WriteBufToDisk
	pop	ds				; retrieve buffer segment
	mov	si, di				;update start of buffer
	pop	ax, dx				;if file write errors 
	jc	error				;  bail out
	tst	dx
	jz	error
	tst	ah				;if we stuffed in a LF?
	jz	topLoop				;then restore the byte
	mov	{byte} ds:[di], ah		;
	jmp	short topLoop
writeBuf:
	mov	cx, dx				;pass size of buffer
	mov     dx, si                          ;  write it out to disk
	mov     bp, es:[fileHandle]             ;
	push	ds				; save buffer segment
	CallMod	WriteBufToDisk                  ;  then display info on screen
	lahf					; save flags from saving
	pop	ds				; retrieve buffer segment
	pop	bx				; retreive buffer handle
	tst	bx
	jnz	heapFree
	add	sp, 16				; free stack bufer
	jmp	short restoreFlagsAndExit
	
heapFree:
	call	MemFree				; free it
	
restoreFlagsAndExit:
	sahf					; restore flags from saving
exit:
        pop	ds, si, cx			;retrieve buffer info
	ret
noMem:
        mov     bp, ERR_NO_MEM_FTRANS           ; (not enough mem for transfer)
        CallMod DisplayErrorMessage		; error message
	stc
	jmp	exit				; exit with carry set
error:
	pop	bx				; retreive buffer handle
	tst	bx
	jnz	memFree
	add	sp, 16				; free stack bufer
	jmp	short quit
memFree:
	call	MemFree				; free it
quit:
	stc				
	jmp	exit				; exit with carry set

endif	;---------------------------------------------------------------------

WriteAsciiPacket endp

if	not _TELNET
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitSerialForFileTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable software flow control and set 8-bit word length

CALLED BY:	FileRecvStart, SendFile (XModem send/receive)

PASS:		ds	- dgroup

RETURN:		C		- set if errorreseting port
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitSerialForFileTrans proc 	near

	mov	al, ds:[serialFormat]
	mov	ds:[saveSerialFormat], al	; save old format
						; set up file trans. protocol
	mov	ds:[serialFormat], SerialFormat <0, 0, SP_NONE, 0, SL_8BITS>
	call	SetSerialFormat			; do it

	mov	cx, ds:[serialFlowCtrl]
	test	cx, mask SFC_SOFTWARE
	jz	noSoft
	mov	ds:[softFlowCtrl], TRUE
	andnf	cx, not mask SFC_SOFTWARE		; clear software
	CallMod	SerialSetFlowControl
	jmp	short exit
noSoft:
	mov	ds:[softFlowCtrl], FALSE
	clc						;clear error flag
exit:
	ret
InitSerialForFileTrans endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreSerialFromFileTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable software flow control

CALLED BY:	EndAsciiRecv, EndAsciiSend, FileSendEnd, FileRecvEnd	

PASS:		ds	- dgroup

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:
		This routine really isn't necessary, because when reset the
		serial line to COOKED mode, it turns on software flow control.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreSerialFromFileTrans proc 	near

	cmp	ds:[serialPort], NO_PORT
	je	exit

	mov	al, ds:[saveSerialFormat]	; get saved format
	mov	ds:[serialFormat], al
	call	SetSerialFormat			; do it

	tst	ds:[softFlowCtrl]
	jz	exit
	mov	cx, ds:[serialFlowCtrl]
	ornf	cx, mask SFC_SOFTWARE		; restore software
	CallMod	SerialSetFlowControl
exit:
	ret
RestoreSerialFromFileTrans endp

endif	; !_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetSendTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset file send triggers 

CALLED BY:	FileSendEnd, FileReset

PASS:		ds	- dgroup

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	08/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetSendTriggers proc 	near
	mov	ax, MSG_GEN_SET_ENABLED		;enable Cancel triggers
	GetResourceHandleNS	NoSendTrigger, bx
	mov	si, offset NoSendTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
ResetSendTriggers endp 

ResetRecvTriggers proc 	near
	mov	ax, MSG_GEN_SET_ENABLED	;turn back on the stop trigger
	GetResourceHandleNS	NoRecvTrigger, bx
	mov     si, offset NoRecvTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
ResetRecvTriggers endp

ResetSendStatus proc 	near
	clr     dx
	GetResourceHandleNS	SentPackets, bp		; bp:si = counter
	mov     si, offset SentPackets
	mov     di, offset dgroup:packetNumBuf
	CallMod UpdateDisplayCounterNow
	clr     dx
	GetResourceHandleNS	SendErrors, bp		; bp;si = counter
	mov     si, offset SendErrors
	mov     di, offset dgroup:errorBuf
	CallMod UpdateDisplayCounterNow
	clr     dx
	GetResourceHandleNS	SendTimeouts, bp	; bp:si = counter
	mov     si, offset SendTimeouts
	mov     di, offset dgroup:timeoutBuf
	CallMod UpdateDisplayCounterNow
	ret
ResetSendStatus endp 

ResetRecvStatus proc	near 
	clr	dx
	GetResourceHandleNS	RecvPackets, bp		; bp:si = counter
	mov	si, offset RecvPackets
	mov     di, offset dgroup:packetNumBuf
	CallMod	UpdateDisplayCounterNow
	clr	dx
	mov     di, offset dgroup:errorBuf
	GetResourceHandleNS	RecvErrors, bp		; bp:si = counter
	mov	si, offset RecvErrors
	CallMod	UpdateDisplayCounterNow
	clr	dx
	mov     di, offset dgroup:timeoutBuf
	GetResourceHandleNS	RecvTimeouts, bp	; bp:si = counter
	mov	si, offset RecvTimeouts
	CallMod	UpdateDisplayCounterNow
	ret
ResetRecvStatus endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset file send ui objects 

CALLED BY:	FileReset

PASS:		ds	- dgroup

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	08/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSendReset proc 	near
	mov     ax, MSG_GEN_GUP_INTERACTION_COMMAND      ;bring down the send
	mov	cx, IC_DISMISS
	GetResourceHandleNS	SendStatusSummons, bx
	mov     si, offset SendStatusSummons            ;   status box
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	call    ResetSendTriggers
	call	ResetSendStatus
	ret
FileSendReset endp 

FileRecvReset proc 	near
;bring down xmodem stuff
	mov     ax, MSG_GEN_GUP_INTERACTION_COMMAND	;bring down the send
	mov	cx, IC_DISMISS
	GetResourceHandleNS	RecvStatusSummons, bx
	mov     si, offset RecvStatusSummons		;   status box
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	call    ResetRecvStatus
	call    ResetRecvTriggers

	mov     ax, MSG_GEN_GUP_INTERACTION_COMMAND	;bring down the text
	mov	cx, IC_DISMISS
	GetResourceHandleNS	AsciiRecvSummons, bx
	mov     si, offset AsciiRecvSummons		;   send status box
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
FileRecvReset endp 



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegisterDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register document with IACP.

CALLED BY:	(EXTERNAL) RespGetRecvFileHandle
PASS:		bx	= file handle

RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/14/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RegisterDocumentFar	proc	far
		call	RegisterDocument
		ret
RegisterDocumentFar	endp

RegisterDocument	proc	near

		ret
RegisterDocument	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnregisterDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister the document with IACP.  File must still be
		open at this point!

CALLED BY:	EndAsciiSend		
		EndAsciiRecv

PASS:		bx	= file handle

RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/14/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnregisterDocumentFar	proc	far
		call	RegisterDocument
		ret
UnregisterDocumentFar	endp

UnregisterDocument	proc	near
		ret
UnregisterDocument	endp


