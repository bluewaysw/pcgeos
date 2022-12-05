COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		pccomIntegrity.asm

AUTHOR:		Robert Greenwalt, Oct  2, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 2/95   	Initial revision


DESCRIPTION:
	code to buck up the reliability of the protocol
		

	$Id: pccomIntegrity.asm,v 1.1 97/04/05 01:26:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata		segment
negotiationStatus		byte	(0)

	;
	; This flag will only be set upon abort.  If someone aborts,
	; we need to tell it to reset to a default state.  Upon doing
	; that in PCComNegotiatte, we will clear this flag
	;
robustResetRemoteState		byte	(0)

robustInputBuffer		byte	BUFFER_SIZE dup(0)
robustOutputBuffer		byte	BUFFER_SIZE dup(0)
tempInputBuffer			byte	TEMP_BUFFER_SIZE dup(0)
tempOutputBuffer		byte	TEMP_BUFFER_SIZE dup(0)
tempInputStart			word	(0)
tempInputEnd			word	(0)
tempOutputLength		word	(0)
robustOutputLength		word	(0)
robustInputStart		word	(0)
robustInputEnd			word	(0)
currentPacketNumber		byte	(0)
lastIncomingPacketNumber	byte	(0)

udata		ends

REAL_GOTO	macro	routineName
		jmp	routineName
	endm


Main	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComNegotiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to use the robust protocol.  Check the other side.

CALLED BY:	ActiveStartupChecks
PASS:		ds - dgroup
		robustResetRemoteState - indicates that we need to
			renegotiate. we aborted the last command for
			some reason. 
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	negotiationStatus <- PNS_ROBUST or PNS_BASE

PSEUDO CODE/STRATEGY:
	send escape sequence "<ESC>RB"
	put into robust mode and wait for response
	if timeout
		pop out of robust mode and if tries<3, try again

	proper sequence
	send	<ESC>RB
	switch to robust
	send	[\0ah<ESC>RK]

	if you don't get the proper ack (the robust block won't go
	through) then dump down to Base


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComNegotiate	proc	near
	uses	ax,cx
	.enter
EC<		call	ECCheckDS_dgroup				>

	;
	; If we are in base mode, there's no need to negotiate again
	;
		cmp	ds:[negotiationStatus], PNS_BASE
		je	toJZDone
	;
	; If we're in Robust Mode, we'll need to do some tricky stuff
	; to speek things up.
	; 6/16/96 - ptrinh
	;
		cmp	ds:[negotiationStatus], PNS_ROBUST
		jne	negotiate
	;
	; If we don't need to reset the remote state, then we can skip
	; over the negotiation process
	; 6/16/96 - ptrinh
	;
		tst	ds:[robustResetRemoteState]
toJZDone:
		jz	done
negotiate:
	;
	; Ok, we're re-negotiating (which has the side-effect of
	; reseting the state of the remote machine).  Hop to it, man!
	;
		clr	ds:[robustResetRemoteState]
		mov	ds:[negotiationStatus], PNS_UNDECIDED
		mov	cx, NEGOTIATION_ATTEMPTS
loopTop:
		mov	ax, ROBUST_NEGOTIATION
		call	PCComSendCommand

		mov	ds:[negotiationStatus], PNS_ROBUST
	;
	; Reset lastIncomingPacketNumber
	;
		mov	ds:[lastIncomingPacketNumber], 1
	;
	; This first char isn't really part of a command, but is there
	; to insure our packet numbers are synched.  With alternating
	; bits, if we are out-o-sync, the first is blindly acked, but
	; the rest will be in sync, and we end up in sync with the
	; command actually understood..  without the first padding
	; char the <ESC> would be ignored (on an OoS condition) and
	; the command would be jibberish.
	;
		mov	al, 0ah
		call	ComWrite
		jc	nextLoop

		call	RobustCollectOn
		mov	al, 1bh
		call	ComWrite

		mov	al, 'R'
		call	ComWrite

		mov	al, 'K'
		call	ComWrite
		call	RobustCollectOff
		jnc	done	
nextLoop:
		mov	ds:[negotiationStatus], PNS_BASE
		loop	loopTop
	;
	; Hey!  They acknowledged; we're done.
	;
done:
	;
	; If we failed to negotiate Robust mode, then pccomAbortType
	; would be set with PCCAT_CONNECTION_LOST.  So, we need to
	; clear it because it's not really a literal "broken
	; connection" but a failure in protocol.
	;
		mov	ds:[pccomAbortType], PCCAT_DEFAULT_ABORT
		BitClr	ds:[sysFlags], SF_EXIT
		clr	ds:[err]
	.leave
	ret

PCComNegotiate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRobust
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The other side has requested we step up.  Go For it.

CALLED BY:	ParseSeq
PASS:		ds = dgroup
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	go into robust mode, receive the Robust Acknowledgement
	command.  Since we are in robust mode, if the second command
	arrives ok they will automatically get an Ack to let them know
	we know.

	If we send the ack and finish the routine and go back to idle
	and they don't get the ack, they will keep sending and
	ConsumeOneByte will keep replying for us.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileRobust	proc	near
	.enter
EC<		call	ECCheckDS_dgroup				>

		mov	ds:[negotiationStatus], PNS_ROBUST
		call	RobustReset
	;
	; Read padding char - see PCComNegotiate
	;
		call	ComReadWithWait
		jc	error
		cmp	al, 1bh
		je	haveFirst
	;
	; OK, now read their command
	;
		call	ComReadWithWait
		jc	error
		cmp	al, 1bh
		jne	error

haveFirst:
		call	ComReadWithWait
		jc	error
		cmp	al, 'R'
		jne	error

		call	ComReadWithWait
		jc	error
		cmp	al, 'K'
		jne	error
done:
	.leave
	ret
	;
	; That wasn't what we expected!  The first (unprotected) RB
	; command must have been erroneous (or somethings really tweaked!)
	;
error:
		mov	ds:[negotiationStatus], PNS_BASE
		jmp	done
FileRobust	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear state variables.

CALLED BY:	ParseSeq, FileRobust
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	resets things like ackOnOff, the input buffer
	pointers.  Does not reset packet numbers, because if we
	received this and they mean anything at all, then we're
	already in sync.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustReset	proc	near
	.enter
EC<		call	ECCheckDS_dgroup				>
	;
	; Now reset state
	;
		mov	ds:[pccomAbortType], PCCAT_DEFAULT_ABORT
		call	RobustFlushInputBuffer
		mov	ds:[robustOutputLength], 0
		mov	ds:[ackBack], 0
		mov	ds:[echoBack], 0
		mov	ds:[currentPacketNumber], 0

	.leave
	ret
RobustReset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComSendCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send off an <ESC> command sequence

CALLED BY:	Internal
PASS:		ds - dgroup
		ax - char sequence to send
RETURN:		carry set if not acknowledged
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComSendCommand	proc	near
	uses	cx,si,ds,es
	.enter
EC<		call	ECCheckDS_dgroup				>
		push	ax		; stack -> LO         al:ah    HI
		mov	ax, 1b00h
		push	ax		; stack -> LO   00:1b:al:ah    HI
		segmov	es, ds		;		^  ^
		segmov	ds, ss		;		|  |
		mov	si, sp		;	ss:sp --|  |
		inc	si		;       ds:si -----|
		mov	cx, 3
		call	ComWriteBlock
		pop	ax
		pop	ax
	.leave
	ret
PCComSendCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustSendChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send this char in its' own special packet

CALLED BY:	Internal
PASS:		ds - dgroup
		al - byte
		SF_COLLECT_OUTPUT is off
RETURN:		carry set if not acknowledged

DESTROYED:	ax, bx, cx, ds
SIDE EFFECTS:	
		pccomAbortType <= PCCAT_CONNECTION_LOST if timed out

PSEUDO CODE/STRATEGY:
		ax - crc
		dh - data char
		dl - quote or ROBUST_START_*
		bh - ROBUST_START_* or quote
		bl - quote

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustSendCharES	proc	near
	uses	ds
	.enter
		segmov	ds, es
		call	RobustSendChar
	.leave
	ret
RobustSendCharES	endp

RobustSendChar	proc	near
retries	local	word
	uses	dx,si,es
	.enter
EC<		call	ECCheckDS_dgroup				>
EC<		test	ds:[sysFlags], mask SF_COLLECT_OUTPUT		>
EC<		ERROR_NZ	BURST_MODE_SHOULD_BE_OFF		>

		call	RobustCheckErrors
		LONG jc	reallyDone

		mov	ss:[retries], CHAR_RESEND_ATTEMPTS
		mov	dh, al		; store away data char

	;
	; Create the send buffer on the stack.  so we can 'push' data
	; into buffer (optimization).
	;
		segmov	es, ds, ax
		segmov	ds, ss, ax
		mov	si, sp		; ds:si - end of send buffer
		mov	cx, 5		; num bytes in buffer to send
	;
	; Calculate CRC value starting with the header
	;
		mov	ax, 0xFFFF	; starting CRC
		mov	bl, es:[currentPacketNumber]
		call	IncCRC		; ax <= new CRC
		mov	dl, bl		; dl <= packet number
	;
	; Now do the data character
	;
		mov	bl, dh
		call	IncCRC		; ax <= new CRC
	;
	; and the terminator, but first check if we are aborting (look
	; at SF_EXIT).  If we are, send NAK_QUIT instead of END.
	;
		mov	bx, ROBUST_NAK_QUIT or (ROBUST_QUOTE shl 8)
		inc	es:[err]
		test	es:[sysFlags], mask SF_EXIT
		LONG_EC	jnz	aborting

		CheckHack <ROBUST_NAK_QUIT eq (ROBUST_END + 1)>
		dec	es:[err]
		dec	bl		; not aborting - change to END
		call	IncCRC		; ax <= CRC includes terminator
		push	bx		; dummy push to get to 4 counts
		sub	si, 2		; so si + cx won't include dummies
haveLastChar:
		xchg	bl, bh		; bh=NAK_QUIT or END, bl=QUOTE
		push	bx		; stack-> LO          bl:bh	HI
	;
	; now check if the data must be quoted
	;
		mov	bx, (ROBUST_QUOTE shl 8) or ROBUST_QUOTE
		cmp	dh, bl		; is data=ROBUST_QUOTE?
		LONG_EC	je	quoteIt
quoted:
		sub	si, cx		; ds:si - beginning of send buffer
		push	dx		; dl=QUOTE or packet# : dh=data
		push	bx		; bl=QUOTE : bh=packet# or QUOTE
		mov	dx, ax		; save the CRC
		mov	bx, es:[serialPort]
sendAgain:
		Assert	le, cx, 8	; assert buffer size

		mov	ax, STREAM_BLOCK
		CallSer	DR_STREAM_WRITE, es

		mov	ax, dx
		call	RobustSendCRC	; CF CLEARED

		call	RobustAwaitAck
		jnc	done
		dec	ss:[retries]
		jnz	sendAgain
	;
	; we sent this blasted packet X times and never got a
	; satisfactory response.  Dump out of the protocol (this'll
	; really trash things) and notify anybody that cares.
	; We have to reset our packet number as well...
	;
		call	RobustTimedOut
done:
	;
	; Deallocate buffer and fix up stack.
	;
		lahf			; preserve CF
		add	sp, 8		; 4 pushes
		sahf			; restore CF

reallyDone:

	.leave
	ret

aborting:
	;
	; Must add abort code to the package.  Be sure to include the
	; code in the CRC calculation.
	; bl = ROBUST_NAK_QUIT, bh = ROBUST_QUOTE, ax = CRC value
	;
EC <		call	ECCheckES_dgroup				>
		call	IncCRC		; for NAK_QUIT terminator
		mov	bl, es:[pccomAbortType]
		call	IncCRC		; ax <- new CRC
	;
	; Abort code can never be equal to ROBUST_QUOTE, see
	; PCComPushAbortType.
	;
		clr	bh		; won't be read...
		dec	si		; so si + cx won't get to it
		push	bx		; stack-> LO  code:00h  HI
		inc	cx		; adjust for abort code

	;
	; reset the input buffer - discard any other data since this
	; command is hosed.
	;
		mov	bx, es:[robustInputEnd]
		mov	es:[robustInputStart], bx

		mov	bx, ROBUST_NAK_QUIT or (ROBUST_QUOTE shl 8)
		jmp	haveLastChar

quoteIt:
	;
	; ok, the data was the same as our quote character..  so
	; precede it with a quote..  just like C strings : "\\"
	; Do this by swapping the start char with it's command quote.
	; Note that we already stored another command quote ahead of
	; that.  also increment the string length so we send it all
	; and so that we start from the right place
	;
		xchg	bh, dl		; bh=packet number, dl=QUOTE
		inc	cx
		jmp	quoted
RobustSendChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustSendBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a robust block of data from a buffer and wait for ack

CALLED BY:	ComWriteBlock
PASS:		es - dgroup
		ds:si - buffer to send
		cx - number of bytes in buffer
RETURN:		carry set if not ever acknowledged
			pccomAbortType = PCCAT_CONNECTION_LOST if
					 timed out.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustSendBlock	proc	near
retries	local	word
	uses	ax,bx,cx,dx,si,di
	.enter

		call	RobustCheckErrorsES
		LONG_EC jc	done
	;
	; Setup for the attempt
	;
		mov	di, es:[blockRetransAttempts]
		mov	ss:[retries], di

		mov	di, cx			; store length
EC<		call	ECCheckES_dgroup				>
		tst	cx
		LONG_EC	jz	done
retryLoopTop:
		test	es:[sysFlags], mask SF_EXIT
		jnz	abort
	;
	; Start off the CRC
	;
		mov	bl, es:[currentPacketNumber]
		mov	ax, 0xFFFF
		call	IncCRC
		mov	dx, ax
	;
	; OK, Send the packet header
	;
		mov	cl, bl
		mov	bx, es:[serialPort]
		call	RobustSendQuotedCommand
	;
	; And calc the CRC for the data
	;
		mov	ax, dx			; ax <- current crc
		mov	cx, di			; cx <- length of data
		segxchg	es, ds, dx
		mov	di, si			; es:di <- data
		call	CalcCRC	; es:di - packet, ax - init val, cx - # char
		segxchg	es, ds, dx
		mov	dx, ax
		mov	di, cx
	;
	; And send the data
	;
		push	di
		jmp	writeLoop
	;
	; skip over this -------------------------
	;
timeoutAbort:
	;
	; We've timed out a bunch of times and I really don't think the
	; other side is there.  Consider the connection terminated.
	; If we don't do this and we had been in the middle of some
	; op, we would hit the consumeonebyte loop and blindly ack
	; everything and the other side may assume the op was
	; successfull.
	; 
		call	RobustTimedOut
		jmp	done
abort:
	;
	; Set the flag so that the next packet (containing junk) will
	; be terminated by an Abort marker, signaling the abort.
	;
		BitSet	es:[sysFlags], SF_EXIT
		call	RobustSendCharES
done:		
	.leave
	ret

	;
	; down to here ---------------------------
	;
writeLoop:
		lodsb

		mov	cl, al
		cmp	cl, ROBUST_QUOTE
		je	quoteIt

		call	UnprotectedComBlockWrite
	;
	; decrement the counter and see if we are done
	;
dataWritten:
		dec	di		
		jnz	writeLoop
		pop	di
	;
	; Done with data - send packet terminator, calc crc, and send
	; 
		mov	cl, ROBUST_END
		call	RobustSendQuotedCommand

		mov	bl, cl
		mov	ax, dx
		call	IncCRC

		call	RobustSendCRC
	;
	; OK.  Now we just need to sit around and wait for
	; acknowledgement.
	;
		call	RobustAwaitAck
		jnc	done
	;
	; we didn't get a good Ack, try again
	;
		sub	si, di		; position at start of block
		dec	ss:[retries]
		jz	timeoutAbort
		jmp	retryLoopTop
quoteIt:
	;
	; the character was the reserved char, so we preceed
	; it with a quote char.
	;
		call	RobustSendQuotedCommand
		jmp	dataWritten
RobustSendBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustReceiveBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to read in another packet.

CALLED BY:	ComRead
PASS:		es - dgroup
		serialHandle verified

		empty buffer =>
			robustInputStart = robustInputEnd &&
			robustInputEnd = offset robustInputBuffer

RETURN:		buffer pointers set
		robustInputBuffer filled in
		carry set if nothing read
DESTROYED:	ax, bx
SIDE EFFECTS:	
		err = 1 and sysFlags = SF_EXIT on abort
		pccomAbortType <= PCCAT_CONNECTION_LOST if
				  timed out

PSEUDO CODE/STRATEGY:
		This routine is used for both ComReadWithWait and
ComRead.  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustReceiveBlock	proc	near
	uses	cx, dx, si, di, bp
	.enter
EC<		call	ECCheckES_dgroup				>
EC<		mov	di, es:[robustInputStart]			>
EC<		cmp	di, es:[robustInputEnd]				>
EC<		ERROR_NE	YOU_HAVE_NOT_EATEN_EVERYTHING_YET	>

		mov	dh, 0		; clear PCCRSF_WRITE, ie. reading
		call	RobustReadHeader
EC<		call	ECCheckInputBufferPtrs				>
		jnc	done
	;
	; we have timed out.  Dump out of the protocol.
	;
		call	RobustTimedOut
done:
	.leave
	ret
RobustReceiveBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustSendAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an Ack with the next number

CALLED BY:	RobustReceiveBlock
PASS:		es - dgroup
		serialHandle has been checked!
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	
		if timed-out
			pccomAbortType = PCCAT_CONNECTION_LOST

PSEUDO CODE/STRATEGY:
	If SF_EXIT is lit but err=0, send NQ, CRC
	If both are lit, send regular Ack packet

	RobustReceiveBlock will set err when we get the confirming B,NQ,CRC
	packet.

Now, if we are initiating the abort it goes something like this:

We receive a packet, and send back a NQ instead of an Ack, then wait
for another packet.

The next packet should be a NQ.  If it is not, they didn't get our NQ,
so we send it again.  Repeat until we get a NQ.  SF_EXIT is still set,
indicating this mode.

Once we've sent a NAK_QUIT, we try to receive the required next
packet.  If the didn't get the NAK_QUIT, we blindly acknowledge, but
don't want to fall through and stack another call to
RobustReceiveBlock..  So we use err to indicate that we've already
been through that and don't call again.

When we get a NQ, we can set es:[err] and acknowledge that we have a
confirmed abort.  Then we can shut down.  If they don't get our
confirmation, then we keep acking the continuous incoming NQ packets.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustSendAck	proc	near
	uses	cx, ax
	.enter
EC<		call	ECCheckES_dgroup				>
EC<		tst	es:[serialHandle]				>
EC<		ERROR_Z	INVALID_SERIAL_PORT				>
	;
	; We've accepted the current packet number, advance to the
	; next one
	;
		xor	es:[lastIncomingPacketNumber], 1
	;
	; And send an ack for the last
	;
		mov	bl, es:[lastIncomingPacketNumber]
		add	bl, ROBUST_ACK_EVEN
	;
	; Reset CRC value
	;
		mov	ax, 0xFFFF
	;
	; check if we are aborting(SF_EXIT), and then see if they
	; already know(err) 
	;
		test	es:[sysFlags], mask SF_EXIT
		jnz	needToAbort
	;
	; we are aborting and they don't yet know it..  send a
	; NAK_QUIT
	;
sendAck:
		call	IncCRC			; for ACK_EVEN
		mov	cl, bl			; ROBUST_ACK_EVEN
		mov	bx, es:[serialPort]
		call	RobustSendQuotedCommand

		call	RobustSendCRC

done:
	.leave
	ret

needToAbort:
	;
	; we think we need to abort, check to see if we already have
	;
EC<		call	ECCheckES_dgroup				>
		tst	es:[err]
		jnz	sendAck

		call	RobustSendNak
		jmp	done

RobustSendAck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustSendNak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send ROBUST_NAK_QUIT, and abort code with it.

CALLED BY:	RobustSendAck

PASS:		nothing
RETURN:		CF - SET if timed-out
DESTROYED:	ax,bx,cx
SIDE EFFECTS:	
		robustInputEnd <= robustInputStart
		err <= 1

		if timed-out
			pccomAbortType = PCCAT_CONNECTION_LOST

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustSendNak	proc	near
	.enter
	;
	; we are aborting and they don't yet know it..  send a
	; NAK_QUIT
	;
		mov	ax, 0xFFFF	; CRC seed
		mov	bl, ROBUST_NAK_QUIT
		call	IncCRC

		mov	cl, bl		; ROBUST_NAK_QUIT
		mov	bx, es:[serialPort]
		call	RobustSendQuotedCommand
	;
	; Now calculate the CRC for the abort code...
	;
		mov	bl, es:[pccomAbortType]
		call	IncCRC
	;
	; then send it off.
	;
		mov	cl, es:[pccomAbortType]
		mov	bx, es:[serialPort]
		call	UnprotectedComBlockWrite

		call	RobustSendCRC
	;
	; Reset buffers pointers.
	;
		mov	ax, es:[robustInputStart]
		mov	es:[robustInputEnd], ax
	;
	; If we abort on an Ack the other side is required to send
	; again.
	;
		call	RobustReceiveBlock
	.leave
	ret
RobustSendNak	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustAwaitAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait for an Ack with the current number

CALLED BY:	internal
PASS:		es - dgroup
		serialHandle has been checked!
RETURN:		carry set on timeout or error
DESTROYED:	ax
SIDE EFFECTS:	
		Toggles the packetnumber if successful
		Will abort if requested by remote
		timeoutTime <= timeoutTime/2

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustAwaitAck	proc	near
	uses	bx, cx, dx, di, si, bp
	.enter
EC<		call	ECCheckES_dgroup				>
EC<		tst	es:[serialHandle]				>
EC<		ERROR_Z	INVALID_SERIAL_PORT				>
	;
	; Protocol Check: input buffer should be empty.  
	; Even if we're supporting simultaneous transactions, ie. the
	; other side has issued a command and is being carried out and
	; at the same time, this side has issued a command is being
	; carrited out.  If we're to support simultaneous transaction,
	; we should have two seperate input buffers.  1/6/96 - ptrinh
	;
EC<		mov	di, es:[robustInputStart]			>
EC<		cmp	di, es:[robustInputEnd]				>
EC<		ERROR_NE	YOU_HAVE_NOT_EATEN_EVERYTHING_YET	>

		shr	es:[timeoutTime]
		mov	dh, mask PCCRSF_WRITE
		call	RobustReadHeader
		jc	done

		xor	es:[currentPacketNumber],1
EC<		cmp	es:[currentPacketNumber], 3			>
EC<		ERROR_NC	INVALID_PACKET_NUMBER			>
EC<		clc	; cause the cmp probably set it..		>

EC<		call	ECCheckInputBufferPtrs				>
done:
		mov	ax, es:[defaultTimeout]
		mov	es:[timeoutTime], ax
	.leave
	ret
RobustAwaitAck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnprotectedComReadWithWait
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to read, waiting the preset amount

CALLED BY:	internal
PASS:		es - dgroup
RETURN:		carry set if timed out
		else al - byte read
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnprotectedComReadWithWait	proc	near

EC<		call	ECCheckES_dgroup				>
	;
	; Check if we already have a byte - the polling loop has
	; overhead we'd like to avoid if we can.
	;
		push	bx
		call	UnprotectedComRead
		pop	bx
		jc	UnprotectedComPoll
		ret
UnprotectedComReadWithWait	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnprotectedComPoll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Poll the port

CALLED BY:	jmped to by UnprotectedComReadWithWait
PASS:		es - dgroup
RETURN:		al - character
		carry set if timed out
DESTROYED:	nothing
SIDE EFFECTS:	temp buffer may be filled in..

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnprotectedComPoll	proc	near
time		local	dword
		uses	bx, di
		.enter
EC<		call	ECCheckES_dgroup				>

		mov	di, es:[timeoutTime]
	;
	; save the current clock count (in ticks, where 60 ticks = 1 sec)
	;
		call	TimerGetCount
		movdw	ss:[time], bxax

readLoop:
		call	UnprotectedComRead
		jnc	endPolling
	;
	; Check if we really, really want to keep polling
	;
		;test	es:[sysFlags], mask SF_EXIT
		;jnz	timeOut
		cmp	es:[negotiationStatus], PNS_DEAD
		je	timeOut
	;
	; See how much time has elapsed - if it is more than the
	; number of ticks specified (60/per second) we will time out.
	;
		call	TimerGetCount
		subdw	bxax, ss:[time]
		tst	bx
		jnz	timeOut
		cmp	ax, di
		jb	readLoop
timeOut:
		stc
endPolling:
		.leave
		ret
UnprotectedComPoll	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnprotectedComRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a byte from the serial port

CALLED BY:	internal
PASS:		es - dgroup
RETURN:		carry set if nothing there
		else
		al contains byte
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		tempInputStart is an index into the buffer 
		tempInputBuffer[tempInputStart] = first data char

		tempInputEnd is an index into the buffer
		tempInputBuffer[tempInputEnd] = one past last data.
		If the buffer is full tempInputEnd=size

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnprotectedComRead	proc	near
	.enter
EC<		call	ECCheckES_dgroup				>
EC<		Assert ge, es:[tempInputEnd], 0				>
EC<		Assert le, es:[tempInputEnd], <size tempInputBuffer>	>
EC<		Assert ge, es:[tempInputStart], 0			>
EC<		Assert le, es:[tempInputStart], <size tempInputBuffer>	>

		mov	bx, es:[tempInputStart]
		cmp	bx, es:[tempInputEnd]
		je	haveNoData
haveData:
		mov	al, es:[tempInputBuffer][bx]
		inc	es:[tempInputStart]
		clc
done:
	.leave
	ret

haveNoData:
	;
	; Try to read another block
	;
		push	ds, si, cx
		mov	bx, es:[serialPort]
		segmov	ds, es, ax
		mov	ax, STREAM_NOBLOCK
		mov	cx, size tempInputBuffer
		mov	si, offset tempInputBuffer
		CallSer	DR_STREAM_READ, es
		mov	ax, cx
		pop	ds, si, cx
	;
	; Did we get anything?  ax <- bytes read
	;
		tst	ax
		stc
		jz	done

		clr	bx
		mov	es:[tempInputStart], bx
		mov	es:[tempInputEnd], ax
		jmp	haveData		
UnprotectedComRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnprotectedComBlockWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do unprotected writes, but bundle them up into blocks

CALLED BY:	internal
PASS:		es - dgroup
		bx - serialPort
		cl - byte to write
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnprotectedComBlockWrite	proc	near
EC <		call	ECCheckES_dgroup				>
EC<		cmp	bx, es:[serialPort]				>
EC<		ERROR_NE	INVALID_SERIAL_PORT			>

		push	bx
		mov	bx, es:[tempOutputLength]
		mov	es:[tempOutputBuffer][bx], cl
		inc	bx
		mov	es:[tempOutputLength], bx
		cmp	bx, size tempOutputBuffer
		pop	bx
		je	FlushTempOutputBuffer
		ret
UnprotectedComBlockWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlushTempOutputBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the whole output buffer and reset tempOutputLength

CALLED BY:	internal
PASS:		es - dgroup
		bx - serialPort
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlushTempOutputBuffer	proc	near
	uses	ds, ax, cx, si
	.enter
EC <		call	ECCheckES_dgroup				>
EC<		cmp	es:[serialPort], bx				>
EC<		ERROR_NE	INVALID_SERIAL_PORT			>
		segmov	ds, es, ax
		mov	ax, STREAM_BLOCK
		mov	cx, es:[tempOutputLength]
		mov	si, offset tempOutputBuffer
		CallSer	DR_STREAM_WRITE, es
		clr	es:[tempOutputLength]
	.leave
	ret
FlushTempOutputBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustSendCRC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to send the CRC, but we don't want any
		non-zero values	below ROBUST_QUOTE

CALLED BY:	internal
PASS:		es - dgroup
		ax - 16-bit CRC value to send
		serialHandle verified

RETURN:		CF - CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustSendCRC	proc	near
	uses	ax,bx,cx
	.enter
EC<		call	ECCheckES_dgroup				>
		mov	cx, ax
		mov	bx, es:[serialPort]

		cmp	al, ROBUST_QUOTE
		je	fixFirst

		call	UnprotectedComBlockWrite
firstDone:
		mov	cl, ch
		cmp	cl, ROBUST_QUOTE
		je	fixSecond

		call	UnprotectedComBlockWrite
secondDone:
		call	FlushTempOutputBuffer
		clc
	.leave
	ret
fixFirst:
		push	cx
		call	RobustSendQuotedCommand
		pop	cx
		jmp	firstDone
fixSecond:
		call	RobustSendQuotedCommand
		jmp	secondDone
RobustSendCRC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustComRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to read a char.

CALLED BY:	ComReadWithWait, ComRead
PASS:		es - dgroup
		serialHandle Checked
RETURN:		carry set if nothing read
			else 
		al - byte read
DESTROYED:	nothing
SIDE EFFECTS:	
		if timed-out
			pccomAbortType <- PCCAT_CONNECTION_LOST
				  

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustComReadFar	proc	far
		call	RobustComRead
		ret
RobustComReadFar	endp

RobustComRead	proc	near
	uses	bx
	.enter
EC<		call	ECCheckES_dgroup				>

		call	RobustCheckErrorsES
		LONG_EC jc	done

	;
	; Check for chars in the buffer.  Note that the order of the
	; cmp is important: if we do it the other way and have chars
	; in the buffer (start<end) then the carry flag would be set
	; by the opposite order..  oops!
	;
		mov	bx, es:[robustInputStart]
		cmp	es:[robustInputEnd], bx
		ja	haveChars
	;
	; OK, try to get the next block.
	;
		call	RobustReceiveBlock
		LONG_EC	jc	done
		call	RobustSendAck
	;
	; Are we aborting?
	;
		test	es:[sysFlags], mask SF_EXIT
		jnz	haveCharDone
	;
	; Verify that the buffer has something
	;
		mov	bx, es:[robustInputStart]
		cmp	bx, es:[robustInputEnd]
EC <		WARNING_E	ENCOUNTERED_NON_DATA_PACKET		>
		je	haveCharDone

haveChars:
		mov	al, es:[bx]		; get char
		inc	es:[robustInputStart]
EC<		call	ECCheckInputBufferPtrs				>
haveCharDone:
		clc
done:
	.leave
	ret
RobustComRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustCollectOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on the collection of chars from comWrite

CALLED BY:	internal
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustCollectOn	proc	near
	.enter
EC <		call	ECCheckDS_dgroup				>
EC<		test	ds:[sysFlags], mask SF_COLLECT_OUTPUT		>
EC<		ERROR_NZ	ALREADY_IN_BURST_MODE			>
		clr	ds:[robustOutputLength]
		BitSet	ds:[sysFlags], SF_COLLECT_OUTPUT
	.leave
	ret
RobustCollectOn	endp

RobustCollectOnES	proc	near
	.enter
EC <		call	ECCheckES_dgroup				>
EC<		test	es:[sysFlags], mask SF_COLLECT_OUTPUT		>
EC<		ERROR_NZ	ALREADY_IN_BURST_MODE			>
		clr	es:[robustOutputLength]
		BitSet	es:[sysFlags], SF_COLLECT_OUTPUT
	.leave
	ret
RobustCollectOnES	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustCollectOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off the collection of chars from ComWrite

CALLED BY:	internal
PASS:		ds - dgroup
RETURN:		carry set on timeout
DESTROYED:	nothing
SIDE EFFECTS:	
		sends any previously collected but unsent characters
		if (negotiationStatus = PNS_ROBUST) && timed out
			pccomAbortType = PCCAT_CONNECTION_LOST

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustCollectOff	proc	near
	.enter
EC <		call	ECCheckDS_dgroup				>
		BitClr	ds:[sysFlags], SF_COLLECT_OUTPUT
		cmp	ds:[negotiationStatus], PNS_ROBUST
		clc
		jne	done

		push	cx, si, es

		segmov	es, ds, cx
		mov	si, offset robustOutputBuffer
		mov	cx, ds:[robustOutputLength]
		call	RobustSendBlock
		mov	ds:[robustOutputLength], 0

		pop	cx, si, es
done:
	.leave
	ret
RobustCollectOff	endp

RobustCollectOffES	proc	near
	uses	si,cx,ds
	.enter
EC <		call	ECCheckES_dgroup				>
		BitClr	es:[sysFlags], SF_COLLECT_OUTPUT
		cmp	es:[negotiationStatus], PNS_ROBUST
		clc
		jne	done
		mov	si, offset robustOutputBuffer
		segmov	ds, es, cx
		mov	cx, es:[robustOutputLength]
		call	RobustSendBlock
		mov	es:[robustOutputLength],0
done:
	.leave
	ret
RobustCollectOffES	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustCollectChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add this char to the collection buffer.  Send if full.

CALLED BY:	internal
PASS:		ds - dgroup
		al - char to send
RETURN:		carry set on timeout
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustCollectChar	proc	near
	uses	cx,di,es
	.enter
EC <		call	ECCheckDS_dgroup				>
		segmov	es, ds, cx
	;
	; store the new char
	;
		mov	di, offset robustOutputBuffer
		mov	cx, ds:[robustOutputLength]
		add	di, cx
		stosb
	;
	; check to see if we've filled the buffer
	;
		inc	cx
		cmp	cx, (size robustOutputBuffer)
		jl	done
	;
	; send the buffer if full
	;
		
		sub	di, cx
		xchg	si, di
		call	RobustSendBlock
		mov	cx, 0
		xchg	si, di
done:		
	;
	; store the new length
	;
EC<		cmp	cx, 0					>
EC<		ERROR_S INVALID_PCCOM_COMMAND_EXIT_TYPE		>
		mov	ds:[robustOutputLength], cx
	.leave
	ret
RobustCollectChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustCollectBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We are in burst mode - add this to the outgoing buffer.

CALLED BY:	RobustSendBlock
PASS:		es - dgroup
		ds:si -  buffer to send
		cx - number of bytes in buffer (non-zero)
RETURN:		carry set if not acknowledged
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustCollectBlock	proc	near
	uses	dx, di, bx, cx, si
	.enter
EC <		call	ECCheckES_dgroup				>
EC<		tst	cx						>
EC<		ERROR_Z	MISC_ERROR					>
		mov	dx, cx
	;
	; if buff_remain <= new_chars
	;	new_char -= buff_remain
	;	copy buff_remain of the new chars
	;	send buffer
	;	buff_remain=buff_size
	;	loop
	; else
	;	copy new_chars of the new chars
	;
		mov	di, es:[robustOutputLength]
		mov	bx, (size robustOutputBuffer)
		sub	bx, di
		add	di, offset robustOutputBuffer
loopTop:
		cmp	bx, dx	; cmp buff_remain vs new_char
		jg	done
	;
	; ok, buff_remain <= new_chars, decrement new_chars
	;
		sub	dx, bx
	;
	; copy buff_remain of the new chars
	;
		mov	cx, bx
		rep movsb
	;
	; send the buffer
	;
		push	ds, si
		segmov	ds, es
		mov	cx, (size robustOutputBuffer)
		mov	si, di
		sub	si, cx
		call	RobustSendBlock
		mov	di, si
		pop	ds, si
		jc	error
	;
	; buff_remain=buff_size
	;
		mov	bx, cx
	;
	; loop
	;
		jmp	loopTop
done:
	;
	; finally, buff_remain > new_chars
	;
		mov	cx, dx
		rep movsb
		sub	di, offset robustOutputBuffer
EC<		cmp	di, 0					>
EC<		ERROR_S INVALID_PCCOM_COMMAND_EXIT_TYPE		>
		mov	es:[robustOutputLength], di
error:
	.leave
	ret
RobustCollectBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustFileSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alternate protocol for sending files - assumes the
		communications are reliable.

CALLED BY:	FileSend
PASS:		es - dgroup
		ds:[di] - FSRA stuff:
			ds:[di].FSRA_name = null terminated filename
			ds:[di].FSRA_size = file size
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Send
		Receive
	name(null if geos file), null term
	size(4 bytes), true size including header
loopTop
			size<1024? -> done
	Send 1024 data bytes
			jmp	loopTop
done
	Send size data bytes

To abort, send ROBUST_NAK_QUIT with valid CRC
	then stop.  Send no more.
If get NAK_QUIT instead of SYNC, abort.  Send no more

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustFileSend	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter
EC <		call	ECCheckES_dgroup				>
	;
	; Verify name is null terminated
	;
EC<		push	es, cx, di					>
EC<		mov	cx, size FSRA_name				>
EC<		segmov	es, ds						>
EC<		add	di, FSRA_name					>
EC<		call	ECVerifyFileName				>
EC<		pop	es, cx, di					>
	;
	; Store away the uncorrupted file size and find the initial
	; block size
	;
		movdw	axcx, ds:[di].FSRA_size
		movdw	es:[fSize], axcx
	;
	; Now send out starting notification
	;
		mov	cl, PCCRT_FILE_STARTING
		call	SendStatusES

		call	RobustCollectOnES
	;
	; Check if we are renaming
	;
		mov	si, di
		add	si, offset FSRA_dosname
		tst	es:[destname]
		jz	notRenaming

		segmov	ds, es
		mov	si, offset destname

notRenaming:
	;
	; ds:si - fptr to buffer
	;
		lodsb
		call	ComWrite
		tst	al
		jnz	notRenaming
	;
	; Now send the file size
	;
		segmov	ds, es
		mov	si, offset fSize
		mov	cx, size fSize
		call	ComWriteBlock

		mov	si, offset general_buf	; for our RobustSendBlock
		mov	dx, offset general_buf	; for the FileRead
		mov	cx, size general_buf

		call	RobustCollectOff
		jc	toDone
blockLoop:
	;
	; Check for abort
	;
		tst	es:[err]
		jnz	weHaveAborted
	;
	; Read from the file
	;
		call	PCComFileRead
		jc	blockLoop
		jcxz	fileDone
	;
	; send the data
	;
		call	RobustSendBlock
toDone:
		jc	done
	;
	; adjust the size remaining
	;
		sub	es:[fSize].low, cx
		sbb	es:[fSize].high, 0
	;
	; and send out notification
	;
		mov	ax, cx
		mov	cl, PCCRT_TRANSFER_CONTINUES
		call	SendStatus
		mov	cx, ax
		jmp	blockLoop

fileDone:
		call	RobustSendCharES	; send 1 additional
						; character
		jc	done
		tst	es:[err]
		jnz	weHaveAborted

		mov	cl, PCCRT_FILE_COMPLETE
		call	SendStatus
done:
	.leave
	ret
weHaveAborted:
		stc
		jmp	done
RobustFileSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustFileReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stripped down file receive, assuming reliable communication.

CALLED BY:	FileReceive
PASS:		ds, es - dgroup
		ds:[pathname], ds:[fSize] filled in
RETURN:		bx - file handle
		ready to jump back into FileReceive at fileOpened
		CF - SET on error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Send
			Receive
				Action
			name, null term
Enter here>
				Create the file
			size(4 bytes), true size including header
				if
loopTop
			size<(size robustInputBuffer) -> done
			sf_exit? -> abort
		get 1024 data bytes
			jmp loopTop
done
		get size data bytes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustFileReceive	proc	near
	uses	ax,cx,dx,si,di,bp
EC <		call	ECCheckES_dgroup				>
EC <		call	ECCheckDS_dgroup				>
	.enter
	;
	; Are we just interested in size?  If so, we've already gotten
	; it.  Check FileReceive for details.
	;
		test	ds:[sysFlags], mask SF_JUST_GET_SIZE
		jz	notJustSize
		mov	cl, PCCRT_FILE_STARTING
		call	SendStatus
		BitSet	ds:[sysFlags], SF_EXIT

notJustSize:
	;
	;	Check if we are renaming.  If so, copy the destname
	;	over and set SF_USE_DOS_NAME so that we don't use the
	;	longname of an incoming (but renamed) geos file
	;
		tst	ds:[destname]
		jz	noDestname
		mov	di, offset pathname
		mov	si, offset destname
		mov	cx, size destname
		call	CopyNullTermStringToBuffer
		clr	{byte}ds:[destname]
		BitSet	ds:[sysFlags], SF_USE_DOS_NAME
noDestname:
		call	CopyPathnameToDataBlock
	;
	; Read the file size
	;
		lea	di, es:[fSize]		; es:di <- fSize
		mov	cx, size fSize
		call	FileReadNBytes		
		jc	abort
	;
	; Now read in the first block - check it for a Geos Header
	;
		call	GetSizeToRead		; cx< = size to read
		cmp	cx, size GeosFileHeader
		jbe	haveSize
		mov	cx, size GeosFileHeader
haveSize:
CheckHack <(size GeosFileHeader) lt (size general_buf)>
		call	RFRReadBlock		; carry <= set on abort
		jc	abortCheck
	;
	; Okay, aborting because we received an abort.
	;
		test	ds:[sysFlags], mask SF_EXIT
		jnz	abortCheck	; received abort

		mov	di, offset general_buf
		call	CheckForGeosFileHeader	; sets SF flags used
						; in FileReceiveStart
		call	FileReceiveStart
		jc	sendAckAndAbort

		call	RFRReadWrite
		jc	abortCheck

		call	RobustComRead		; read the last
						; required char
		tst	ds:[err]		; check if either side
						; had a problem
		jnz	abort
done:
	.leave
	ret

abortCheck:
	;
	; We know there is an abort happening, but we don't know if the
	; remote knows about it yet.
	;
		tst	ds:[err]
		jnz	abort

sendAckAndAbort:
		push	bx
		call	RobustSendAck
		pop	bx
abort::
	;
	; Yep, we have a confirmed abort on both sides.  Check out
	; There may still be garbage in our robustInputBuffer, so
	; clear that out, then leave.
	;
		Assert ne ds:[err], 0
		call	RobustFlushInputBuffer
		stc				; indicate ERROR
		jmp	done

RobustFileReceive	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizeToRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to read to the end of the buffer or the end of
		the file, which-ever comes first

CALLED BY:	RobustFileReceive
PASS:		es - dgroup
		fSize filled in
RETURN:		cx - number of bytes to read
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizeToRead	proc	near
	.enter
EC<		call	ECCheckES_dgroup				>
	;
	; How much should we read?
	;  if fSize>(size general_buf) we want to fill the buffer
	;  else we want to get fSize worth
	;
		mov	cx, size general_buf
		tst	es:[fSize].high
		jnz	done
		cmp	es:[fSize].low, cx
		jb	reSize
done:
	.leave
	ret
reSize:
		mov	cx, es:[fSize].low
		jmp	done
GetSizeToRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSizeRemaining
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We have read cx worth - adjust fSize

CALLED BY:	RobustFileReceive
PASS:		es - dgroup
		cx - amount read

RETURN:		ax - 0
DESTROYED:	Nothing
SIDE EFFECTS:	fSize - decresed by cx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustSizeRemaining	proc	near
	.enter
EC<		call	ECCheckES_dgroup				>
		clr	ax
		subdw	es:[fSize], axcx
	.leave
	ret
AdjustSizeRemaining	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFRReadBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in cx worth of the block into robustInputBuffer.

CALLED BY:	RobustFileReceive
PASS:		es - dgroup
		cx - amount to read,   0 <= cx <= BUFFER_SIZE
			if cx = 0, will fall thru w/ CF CLEAR

RETURN:		CF - SET on abort
DESTROYED:	nothing
SIDE EFFECTS:	
		if timed-out
			pccomAbortType <- PCCAT_CONNECTION_LOST

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFRReadBlock	proc	near
	uses	cx, di
	.enter
EC<		call	ECCheckES_dgroup				>
		Assert	srange	cx, 0, BUFFER_SIZE

	;
	; If nothing to read, then just fall through.
	;
		cmp	cx, 0				
		je	done			; CF clear

		mov	di, offset general_buf
loopTop:
		tst	es:[err]		; CF <= CLEAR
		jnz	abort
		call	RobustComRead
		jc	done			; ABORT if jmp
		stosb
		loop	loopTop
done:
	.leave
	ret

abort:
		stc
		jmp	done

RFRReadBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFRReadWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've already read a block before coming in.  Now
		write it out to the file.  Read another block, then
		loop to write the new block to file.

CALLED BY:	
PASS:		bx - file handle to write out to
		cx - bytes to write, 0 <= cx <= BUFFER_SIZE
			if cx=0, full thru w/ CF CLEAR
		es - dgroup

RETURN:		CF - SET on abort
			sysFlags - SF_EXIT set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFRReadWrite	proc	near
	uses	ax, ds
	.enter

EC<		call	ECCheckES_dgroup				>
		Assert	srange	cx, 0, BUFFER_SIZE

	;
	; Prepare the segment register for FileWrite.
	;
		LoadDGroup	ds, ax

nextBlock:
	;
	; either filled the buffer, or finished the file
	; so write to disk
	;
		call	AdjustSizeRemaining	; ax <= 0
		mov	dx, offset general_buf
		; al = 0, no flags for FileWrite
		call	PCComFileWrite		; cx <= bytes written
	;
	; Now that the file has been written, we are really, really
	; ready to read more serial port stuff.
	;
;		pushf				; push CF
;		push	bx			; file handle
;		call	RobustSendAck
;		pop	bx			; file handle
;		popf				; pop CF
	;
	; Check if the write was good.
	;
		jc	abort			; abort if write err

		mov	cl, PCCRT_TRANSFER_CONTINUES
		call	SendStatus

		call	GetSizeToRead		; cx <= bytes to read
	;
	; If nothing to write, then fall through.
	;
		jcxz	happyDone

		call	RFRReadBlock
		jc	abort
		jmp	nextBlock

happyDone:
		clc
done:
		.leave
		ret
abort:
EC<		call	ECCheckES_dgroup				>
		mov	ax, es:[robustInputStart]
		mov	es:[robustInputEnd], ax
		BitSet	es:[sysFlags], SF_EXIT
		stc
		jmp	done
RFRReadWrite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustSendQuotedCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a quoted command

CALLED BY:	internal
PASS:		es - dgroup
		bx - es:[serialPort]
		cl - data
RETURN:		nothing
DESTROYED:	ch
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustSendQuotedCommand	proc	near
	uses	ax
	.enter
EC<		call	ECCheckES_dgroup				>
		mov	ch, cl				; ch <= data
		mov	cl, ROBUST_QUOTE
		call	UnprotectedComBlockWrite

		mov_tr	cl, ch				; cl <= data
		call	UnprotectedComBlockWrite
	.leave
	ret
RobustSendQuotedCommand	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustFlushInputBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flushes the robustInputBuffer

CALLED BY:	Various Robust routines.

PASS:		ds - dgroup

RETURN:		nothing
DESTROYED:	CF preserved
SIDE EFFECTS:	
	robustInputStart = robustInputEnd = offset robustInputBuffer

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	12/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustFlushInputBuffer	proc	near
	.enter

EC<	call	ECCheckDS_dgroup				>
	mov	ds:[robustInputStart], offset robustInputBuffer
	mov	ds:[robustInputEnd], offset robustInputBuffer

	.leave
	ret
RobustFlushInputBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustReadHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The beginning - find out what we're dealing with

CALLED BY:	RobustAwaitAck, RobustReceiveBlock
PASS:		es - dgroup
		dh - PCComRobustStateFlags, READING bit set if appropriate
RETURN:		carry set on timeout
DESTROYED:	ax,bx,cx,dx,si,di,bp
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
		reset everything
			end(si)		- RobustReadHeader
			data(bp)	- RobustReadHeader
			StateFlags:
				abort - Complex
				abortStatus - none
			currentCRC(bx)	- FFFF
		jmp RobustReadToken

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustReadHeader	proc	near
EC<		call	ECCheckES_dgroup				>
		mov	si, offset RobustReadHeader
		mov	bp, si
		and	dx, (mask PCCRSF_WRITE shl 8)
		BitSet	dh, PCCRSF_COMPLEX_ABORT
		mov	bx, 0xFFFF
		REAL_GOTO	RobustReadToken
RobustReadHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustReadData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've read a data byte - deal with it

CALLED BY:	RobustReadToken
PASS:		es - dgroup
		end(si)		- RobustReadCRCStart
		data(bp)	- RobustReadData
		StateFlags(dh)	- PCComRobustStateFlags
			abort - simple
			abortStatus - none
		al - new char
		bx - old crc
		di - point to next char in input buffer
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
		if nextchar pointer = past buffer
			jmp RobustReadHeader
		call	IncCRC
		if reading
			if new
				write
		advance pointer
		jmp RobustReadToken

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustReadData	proc	near
EC<		call	ECCheckES_dgroup				>
	;
	; Check if the buffer is full
	;
		cmp	di, offset robustInputBuffer + size robustInputBuffer
		jae	tooManyChars
	;
	; calc the new crc
	;
		xchg	ax, bx
		call	IncCRC
		xchg	ax, bx
	;
	; Only store the char if we intended to read(!WRITE) AND the
	; packet was new(!OLD)
	;
		test	dh, (mask PCCRSF_WRITE or mask PCCRSF_OLD)
		jnz	incPointer

		stosb
		REAL_GOTO	RobustReadToken
tooManyChars:
	;
	; We've read in more chars than we can allow - something is
	; wrong.  Start over
	;
EC <		WARNING		FSM_DATA_BUFFER_OVERFLOW		>
		REAL_GOTO	RobustReadHeader
incPointer:
	;
	; not writing, but keep track of the # of chars anyway.
	;
		inc	di
		REAL_GOTO	RobustReadToken
RobustReadData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustReadAbortType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have read the abort code.  Store it then read CRC.	

CALLED BY:	RobustReadToken
PASS:		es - dgroup
		end(si)		- RobustReadHeader
		data(bp)	- RobustReadAbortType
		StateFlags(dh)	- PCComRobustStateFlags
		al - new char
		bx - old crc
		di - point to next char in input buffer

RETURN:		n/a
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustReadAbortType	proc	near

		mov	cl, al			; abort code

		xchg	ax, bx			; ax = old CRC, bl = code
		call	IncCRC
		mov_tr	bx, ax			; bx = new CRC

		REAL_GOTO	RobustReadCRCStart

RobustReadAbortType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustReadCRCStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to start reading our CRC value.

CALLED BY:	RobustReadToken
PASS:		es - dgroup
		bx - currentCRC
		dh - PCComRobustStateFlags
		cl - PCComAbortType, if aborting
		
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
		data(bp)	- RobustReadCRCHaveFirstChar
		end(si)		- RobustReadHeader
		StateFlags(dh)
				- complex
		jmp	RobustReadToken

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustReadCRCStart	proc	near
EC<		call	ECCheckES_dgroup				>
	;
	; set the jump vectors, data and endPacket respectively
	;
		mov	bp, offset RobustReadCRCHaveFirstChar
		mov	si, offset RobustReadHeader
	;
	; setup state flags - clear simple, set complex
	;
		BitClr	dh, PCCRSF_SIMPLE_ABORT
		BitSet	dh, PCCRSF_COMPLEX_ABORT
		REAL_GOTO	RobustReadToken
RobustReadCRCStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustReadCRCHaveFirstChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have Read the first (low) byte of the CRC, check it.

CALLED BY:	RobustReadCRCStart via RobustReadToken
PASS:		es - dgroup
		bx - current CRC
		dh - PCComRobustStateFlags
		si - offset RobustReadHeader
		al - low crc value from remote
		cl - PCComAbortType, if aborting

RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
		cmp data with CRC
		jne RobustReadHeader
		data - RobustReadCRCHaveLastChar
		jmp	RobustReadToken		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustReadCRCHaveFirstChar	proc	near
EC<		call	ECCheckES_dgroup				>
	;
	; verify the CRC
	;
		cmp	al, bl
		jne	notValid
	;
	; setup the data jump vector
	; Args: es, dh, si - from parameter
	;
		mov	bp, offset RobustReadCRCHaveLastChar
		REAL_GOTO	RobustReadToken
notValid:
	;
	; oops, go back to the beginning
	; Args: es, dh - from parameters.
	;
		REAL_GOTO	RobustReadHeader
RobustReadCRCHaveFirstChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustReadCRCHaveLastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have read the second (high) byte of the CRC, check it.

CALLED BY:	RobustReadCRCHaveFirstChar via RobustReadToken
PASS:		es - dgroup
		al - high byte of crc
		bx - current CRC
		dh - PCComRobustStateFlags
		si - offset RobustReadHeader
		di - offset to byte after last char in buffer
		cl - PCComAbortType, if aborting

RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
		cmp data with rest of CRC
		jne RobustReadHeader
		if abortStatus = Simple
			SendAck
			set abort flags
			ret
		if abortStatus = complex
			Set abort flags
			Send Char
			ret
		if initialToken is data Packet
			if OLD
				SendAck
				jmp RobustReadHeader
			if Reading		
				update pointers
				ret
			jmp RobustReadHeader
		if initialToken is ack Packet
			if Reading
				jmp RobustReadHeader
			if Old
				jmp RobustReadHeader
			ret
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustReadCRCHaveLastChar	proc	near
EC<		call	ECCheckES_dgroup				>
	;
	; Verify the CRC value
	;
		cmp	al, bh
		jne	failedCRC

		mov	bl, cl			; PCComAbortType
	;
	; Use table to determine which routine to call
	;
		push	es, di			; dgroup, offset into buffer
		segmov	es, cs, di
		mov	di, offset cs:[HLCSwitchTable]
		mov	cx, size HLCSwitchTable
		mov	al, dh			; control bitfield
	; 
	; Mask out uinteresting bits
	;
		and	al, not mask PCCRSF_COMPLEX_ABORT and \
			    not mask PCCRSF_SIMPLE_ABORT
		Assert	okForRepScasb
		repne	scasb			; cx <= count down
		pop	es, di			; dgroup, offset into buffer
		jne	bogusBitFields
	;
	; Found something in the switch table.  Use count as index
	; into reversed table
	;
		mov	si, cx			; si <= index
		shl	si			; word-sized
		REAL_GOTO	cs:[HLCRoutineTable][si]

bogusBitFields:
EC <		ERROR	FSM_BOGUS_CONTROL_BITFIELDS			>

failedCRC:
EC <		WARNING FSM_FAILED_CRC					>

		REAL_GOTO	RobustReadHeader
RobustReadCRCHaveLastChar	endp


HLCSwitchTable	PCComRobustStateFlags	\
	0,					; Reading and New Packet
	mask PCCRSF_WRITE,			; Writing and New Packet
	mask PCCRSF_OLD,			; Old packet
	mask PCCRSF_OLD or mask PCCRSF_WRITE,
	mask PCCRSF_ACK,			; Ack packet
	mask PCCRSF_ACK or mask PCCRSF_WRITE,
	mask PCCRSF_ACK or mask PCCRSF_OLD,
	mask PCCRSF_ACK or mask PCCRSF_WRITE or mask PCCRSF_OLD,
	mask PCCRSF_DOING_COMPLEX,		; Complex Abort
	mask PCCRSF_DOING_COMPLEX or mask PCCRSF_WRITE,
	mask PCCRSF_DOING_COMPLEX or mask PCCRSF_OLD,
	mask PCCRSF_DOING_COMPLEX or mask PCCRSF_OLD or mask PCCRSF_WRITE,
	mask PCCRSF_DOING_SIMPLE,		; Simple Abort
	mask PCCRSF_DOING_SIMPLE or mask PCCRSF_WRITE,
	mask PCCRSF_DOING_SIMPLE or mask PCCRSF_OLD,
	mask PCCRSF_DOING_SIMPLE or mask PCCRSF_WRITE or mask PCCRSF_OLD
	
HLCRoutineTable	nptr.near \
	RobustSimpleAborting,
	RobustSimpleAborting,
	RobustSimpleAborting,
	RobustSimpleAborting,
	RobustComplexAborting,
	RobustComplexAborting,
	RobustComplexAborting,
	RobustComplexAborting,
	RobustHaveAckPacket,
	RobustHaveAckPacket,
	RobustHaveAckPacket,
	RobustHaveAckPacket,
	RobustHaveOldDataPacket,
	RobustHaveOldDataPacket,
	RobustHaveNewDataPacketWriting,
	RobustHaveNewDataPacketReading

CheckHack < length HLCSwitchTable eq length HLCRoutineTable >



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustSimpleAborting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received data packet with ROBUST_NAK_QUIT terminator.
		We know that the other side has already aborted.

CALLED BY:	RobustReadCRCHaveLastChar
PASS:		es - dgroup
		dh - PCComRobustStateFlags
		bl - PCComAbortType

RETURN:		nothing
DESTROYED:	everything

SIDE EFFECTS:	
		sysFlags <- SF_EXIT
		err <- 1
		pccomAbortType <- bl

PSEUDO CODE/STRATEGY:

	** Part of the RobustReadHeader FSM **
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustSimpleAborting	proc	near
EC <		call	ECCheckES_dgroup				>
EC <		test	dh, mask PCCRSF_DOING_SIMPLE			>
EC <		ERROR_Z	FSM_IMPROPER_CONTROL_BITFIELDS_FOR_ROUTINE	>

		BitSet	es:[sysFlags], SF_EXIT
		mov	es:[err], 1

		mov_tr	ah, bl			; abort code
		ornf	ah, PCCAT_REMOTE_ABORT
		call	PCComPushAbortTypeES

EC <		WARNING	FSM_SIMPLE_ABORTING				>
		call	RobustSendAck		; sending an abort, NAK_QUIT
		clc

		ret
RobustSimpleAborting	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustComplexAborting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received ack packet with ROBUST_NAK_QUIT terminator.
		The other side hasn't aborted yet, so we need to
		respond with a data packet with ROBUST_NAK_QUIT so
		that they'll do a RobustSimpleAborting.

CALLED BY:	RobustReadCRCHaveLastChar
PASS:		es - dgroup
		dh - PCComRobustStateFlags
		bl - PCComAbortType

RETURN:		nothing
DESTROYED:	everything

SIDE EFFECTS:	
		sysFlags <- SF_EXIT
		err <- 1
		pccomAbortType <- bl

PSEUDO CODE/STRATEGY:
		
	** Part of the RobustReadHeader FSM **


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustComplexAborting	proc	near
EC <		call	ECCheckES_dgroup				>
EC <		test	dh, mask PCCRSF_DOING_COMPLEX			>
EC <		ERROR_Z	FSM_IMPROPER_CONTROL_BITFIELDS_FOR_ROUTINE	>

		mov_tr	ah, bl			; abort code
		ornf	ah, PCCAT_REMOTE_ABORT
		call	PCComPushAbortTypeES

EC <		WARNING	FSM_COMPLEX_ABORTING				>
	;
	; Our data packet's been effectively ACK'd (the otherside
	; advanced our packetnum) but we haven't yet advanced our
	; packetnum, so do it now...
	;
		xor	es:[currentPacketNumber], 1
	;
	; The only problem is that when we return RobustAwaitAck will
	; do it again.  So do it now, call our buddy routine, and
	; change it back.  Agh!
	;
		mov	al, 32
		call	RobustSendCharES

		mov	es:[err], 1		; it's been confirmed

		xor	es:[currentPacketNumber], 1	; CF <= CLEAR
		ret
RobustComplexAborting	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustHaveAckPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've received a valid Ack packet.

CALLED BY:	RobustReadCRCHaveLastChar
PASS:		es - dgroup
		dh - PCComRobustStateFlags

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustHaveAckPacket	proc	near
EC <		call	ECCheckES_dgroup				>
EC <		test	dh, mask PCCRSF_ACK				>
EC <		ERROR_Z	FSM_IMPROPER_CONTROL_BITFIELDS_FOR_ROUTINE	>

	;
	; We received an Ack.  If we were reading, this is gibberish
	; to us, start over
	;
		test	dh, mask PCCRSF_WRITE
EC <		WARNING_Z	FSM_GOT_GIBBERISH_ACK_PACKET	>
		jz	startOver
	;
	; Ok, we got an ack, and were looking for one, but is it new?
	;
		test	dh, mask PCCRSF_OLD	; CF <= CLEAR
EC <		WARNING_NZ	FSM_GOT_OLD_ACK_PACKET		>
		jnz	startOver
	; 	clc
		ret
startOver:
		REAL_GOTO	RobustReadHeader
RobustHaveAckPacket	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustHaveNewDataPacketReading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a new data packet and we're reading
		(expecting a new one), so this is the end of the FSM.

CALLED BY:	RobustReadCRCHaveLastChar

PASS:		es - dgroup
		dh - PCComRobustStateFlags
		di - offset to byte after last char in buffer

RETURN:		CF - SET if received an empty data packet

DESTROYED:	everything
SIDE EFFECTS:	
	robustInputStart <= offset robustInputBuffe
	robustInputEnd	 <= di

PSEUDO CODE/STRATEGY:

	** Part of the RobustReadHeader FSM **
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustHaveNewDataPacketReading	proc	near
EC <		call	ECCheckES_dgroup				>
EC <		test	dh, mask PCCRSF_WRITE or mask PCCRSF_OLD 	>
EC <		ERROR_NZ FSM_IMPROPER_CONTROL_BITFIELDS_FOR_ROUTINE	>

	;
	; How can we receive an empty data packet?  Yep, but we won't take 
	; it though.  Startover.
	; 12/31/95 - ptrinh
	;
		cmp	di, offset robustInputBuffer
		je	nullDataPacket
	;
	; Ah!  We're done.  Update the buffer pointers and return!
	;
		mov	es:[robustInputStart], offset robustInputBuffer
		mov	es:[robustInputEnd], di
EC<		call	ECCheckInputBufferPtrs				>

		clc
		ret

nullDataPacket:
EC <		WARNING	FSM_GOT_EMPTY_DATA_PACKET			>
		REAL_GOTO	RobustReadHeader
	
RobustHaveNewDataPacketReading	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustHaveNewDataPacketWriting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	OK.  Here's the situation: 
		We sent our packet.  They've received it.  They sent
		the ACK, but we didn't get it.  Thus, we now have a
		race condition.  If we time out first, we resend the
		packet and all's ok...  BUT they may timeout first and
		resend the new packet again and we repeat until one of
		us gives up.  Solution: we'll decrease our timeout
		interval.

		NOTE: They won't hit this code because they are
		receiving old data packets, which are always acked.
		Also, the changed timeout time will be fixed in
		RobustAwaitAck.


CALLED BY:	RobustReadCRCHaveLastChar

PASS:		es - dgroup
		dh - PCComRobustStateFlags

RETURN:		nothing
DESTROYED:	everything

SIDE EFFECTS:	
		timeoutTime is reduced in half

PSEUDO CODE/STRATEGY:
		
	** Part of the RobustReadHeader FSM **


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustHaveNewDataPacketWriting	proc	near
EC <		call	ECCheckES_dgroup				>
EC <		test	dh, mask PCCRSF_WRITE				>
EC <		ERROR_Z	FSM_IMPROPER_CONTROL_BITFIELDS_FOR_ROUTINE	>
EC <		test	dh, mask PCCRSF_OLD 				>
EC <		ERROR_NZ FSM_IMPROPER_CONTROL_BITFIELDS_FOR_ROUTINE	>

EC <		WARNING	FSM_POSSIBLE_RACE_CONDITION			>
		shr	es:[timeoutTime]

	;
	; Args: es, dh - from parameters
	;
		REAL_GOTO	RobustReadHeader

RobustHaveNewDataPacketWriting	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustHaveOldDataPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Always, always, always Ack old data packets..  the
		other side is resending because they haven't gotten
		an ACK from us yet.  Then start over.

CALLED BY:	RobustReadCRCHaveLastChar

PASS:		es - dgroup
		dh - PCComRobustStateFlags

RETURN:		nothing
DESTROYED:	everything

SIDE EFFECTS:	
		lastIncomingPacketNumber is flipped

PSEUDO CODE/STRATEGY:

	** Part of the RobustReadHeader FSM **
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustHaveOldDataPacket	proc	near
EC<		call	ECCheckES_dgroup				>
EC <		test	dh, mask PCCRSF_OLD 				>
EC <		ERROR_Z FSM_IMPROPER_CONTROL_BITFIELDS_FOR_ROUTINE	>


EC <		WARNING	FSM_GOT_OLD_DATA_PACKET				>
	;
	; Ack old packet
	;
		xor	es:[lastIncomingPacketNumber], 1
		call	RobustSendAck
	;
	; Args: es, dh - from parameters
	;
		REAL_GOTO	RobustReadHeader

RobustHaveOldDataPacket	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustReadToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to read from the port and do the right thing

CALLED BY:	RobustReadHeader
		RobustReadData		
		RobustReadCRCStart
		RobustReadCRCHaveFirstChar
PASS:		es - dgroup
		dh - PCComRobustStateFlags
		si - packet end jump vector
		bp - data char jump vector
		cl - PCCcomAbortType, if aborting

RETURN:		carry set on timeout as per RobustReadHeader
DESTROYED:	
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
	Read With Wait
8	carry - jmp RobustReadTimeOut
7	not quote - jmp data
	ReadWithWait
8	carry - jmp RobustReadTimeOut
7	quote - jmp data
5	abort - 
		mov abortStatus, abort
		jmp RobustReadCRCStart
6	end - end
	move byte into initialToken
1,2	packetstart - 
		end - RobustReadCRCStart
		data - RobustReadData
		abort - simple
		abortStatus - none
		nextchar pointer reset
		jmp RobustReadToken
3,4	packetAck - 
		end - RobustReadHeader
		data - RobustReadHeader
		abort - complex
		abortStatus - none
		jmp RobustReadCRCStart
9	else - jmp RoubstReadHeader

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustReadToken	proc	near
EC<		call	ECCheckES_dgroup				>
EC<		cmp	bp, offset RobustReadHeader			>
EC<		je	bpChecked					>
EC<		cmp	bp, offset RobustReadCRCHaveFirstChar		>
EC<		je	bpChecked					>
EC<		cmp	bp, offset RobustReadCRCHaveLastChar		>
EC<		je	bpChecked					>
EC<		cmp	bp, offset RobustReadData			>
EC<		je	bpChecked					>
EC<		cmp	bp, offset RobustReadAbortType			>
EC<		ERROR_NE	YOU_HAVE_NOT_EATEN_EVERYTHING_YET	>
EC<bpChecked:								>
EC<		cmp	si, offset RobustReadHeader			>
EC<		je	siChecked					>
EC<		cmp	si, offset RobustReadCRCStart			>
EC<		ERROR_NE	YOU_HAVE_NOT_EATEN_EVERYTHING_YET	>
EC<siChecked:								>
	;
	; Read the character
	;
		call	UnprotectedComReadWithWait
		jc	timeOut
	;
	; is it data, or is it a quote char
	;
		cmp	al, ROBUST_QUOTE
		je	haveQuote
	;
	; Done.  Jump using data vector.
	;
usingDataVector:
		REAL_GOTO	bp

timeOut:
	;
	; On timeout we want to dump 
		ret

haveQuote:
	;
	; We found a quote - read the next char to see what to do.
	;
		call	UnprotectedComReadWithWait
		jc	timeOut
	;
	; Is it actually a data char?
	;
		cmp	al, ROBUST_QUOTE
		je	usingDataVector
	;
	; Nope, it's a control char...
	;
		xchg	ax, bx
		call	IncCRC
		xchg	ax, bx
	;
	; ...check to see what type
	;
		cmp	al, ROBUST_NAK_QUIT
		jne	notAbort

EC <		WARNING	FSM_GOT_ABORT_PACKET				>
		REAL_GOTO	RobustStartAbort

notAbort:
	;
	; did we reach the end of a data packet?  Then jump according
	; to the end vector (si)
	;
		cmp	al, ROBUST_END
		jne	notEndMarker
		REAL_GOTO	si

notEndMarker:
	;
	; did we find a start marker?
	;
		cmp	al, ROBUST_START_ODD
		ja	notDataPacket
		REAL_GOTO	RobustStartData

notDataPacket:
	;
	; There is one last option:  An Ack packet.  Is this one?
	;
		cmp	al, ROBUST_ACK_ODD
		ja	notAckPacket
		REAL_GOTO	RobustStartAck

notAckPacket:
	;
	; We don't know what this is..  start over..
	;
EC <		WARNING	FSM_GOT_BOGUS_CONTROL_CHARACTER			>
		REAL_GOTO	RobustReadHeader
RobustReadToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustStartAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We Received an abort marker

CALLED BY:	RobustReadToken
PASS:		dh - PCComRobustStateFlags

RETURN:		n/a
DESTROYED:	nothing
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustStartAbort	proc	near
	;
	; we are aborting!  Shift the desired abort mode into the
	; DOING flags.  We are now doing that abort.
	;
		mov	al, dh

CheckHack < (mask PCCRSF_COMPLEX_ABORT shr 2) eq mask PCCRSF_DOING_COMPLEX>
		and	al, mask PCCRSF_COMPLEX_ABORT or mask PCCRSF_SIMPLE_ABORT
		shr	al
		shr	al
		or	dh, al

	;
	; set the jump vectors
	;
		mov	bp, offset RobustReadAbortType
		mov	si, offset RobustReadHeader

		REAL_GOTO	RobustReadToken

RobustStartAbort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustStartData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We received a data packet header

CALLED BY:	RobustReadToken
PASS:		es - dgroup
		dh - control bitfield
RETURN:		n/a
DESTROYED:	nothing
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/20/95    	Initial version

o%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustStartData	proc	near
EC<		call	ECCheckES_dgroup				>
	;
	; yep - we are starting a data packet
	;
		mov	si, offset RobustReadCRCStart	; set end vector
		mov	bp, offset RobustReadData	; set data vector
		and	dh, (((not mask PCCRSF_COMPLEX_ABORT) and \
				(not mask PCCRSF_DOING_SIMPLE)) and \
				((not mask PCCRSF_DOING_COMPLEX) and \
				(not mask PCCRSF_ACK))) and \
				(not mask PCCRSF_OLD)
		BitSet	dh, PCCRSF_SIMPLE_ABORT		; set abort flag
		mov	di, offset robustInputBuffer	; reset the buffer
		cmp	al, es:[lastIncomingPacketNumber]
		jne	isNew				; set OLD correctly
		BitSet	dh, PCCRSF_OLD
isNew:
		REAL_GOTO	RobustReadToken
RobustStartData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustStartAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We received an ack packet header

CALLED BY:	RobustReadToken
PASS:		es - dgroup
		dh - PCComRobustStateFlags

RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

	** Part of the RobustReadHeader FSM **

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustStartAck	proc	near
EC<		call	ECCheckES_dgroup				>
	;
	; Yep.  Set the abort type and the Ack flag and old as
	; appropriate
	;
		mov	si, offset RobustReadHeader
		mov	bp, si
		and 	dh, ((not mask PCCRSF_SIMPLE_ABORT) and \
				(not mask PCCRSF_DOING_SIMPLE)) and \
				(not mask PCCRSF_DOING_COMPLEX) and \
				(not mask PCCRSF_OLD)
		or	dh, mask PCCRSF_COMPLEX_ABORT or mask PCCRSF_ACK
		sub	al, ROBUST_ACK_EVEN
		cmp	al, es:[currentPacketNumber]
		je	isNewAck
		BitSet	dh, PCCRSF_OLD
isNewAck:
	;
	; Args: es - from parameters
	;
		REAL_GOTO	RobustReadCRCStart
RobustStartAck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustTimedOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	drop down to Dead mode

CALLED BY:	timeout locations
PASS:		es - dgroup
RETURN:		carry set
		SF_EXIT set
		err set
DESTROYED:	ax
SIDE EFFECTS:	abort type pushed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustTimedOut	proc	near
	.enter
EC<		call	ECCheckES_dgroup				>
		mov	es:[negotiationStatus], PNS_DEAD
		mov	ah, PCCAT_CONNECTION_LOST
		call	PCComPushAbortTypeES	; sets SF_EXIT
		mov	es:[err], 1
		stc
	.leave
	ret
RobustTimedOut	endp


if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckInputBufferPtrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	INTERNAL: Verify that robustInput[Start/End] are valid.

CALLED BY:	Various Robust routines
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing, FLAGS preserved
SIDE EFFECTS:	
	Execution halts on failed assertion.

PSEUDO CODE/STRATEGY:
		offset robustInputBuffer <= Start 
		Start <= End 
		End <= (offset robustInputBuffer + BUFFER_SIZE)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	12/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckInputBufferPtrs	proc	near
	uses	ax, ds
	.enter
	pushf

	LoadDGroup	ds, ax

	mov	ax, ds:[robustInputStart]
	cmp	ax, offset robustInputBuffer
	jl	error

	cmp	ax, ds:[robustInputEnd]
	jg	error

	cmp	ds:[robustInputEnd], offset robustInputBuffer + BUFFER_SIZE
	jg	error

	popf
	.leave
	ret

error:
	ERROR	CORRUPT_INPUT_BUFFER_POINTERS

ECCheckInputBufferPtrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies that the given string is null-terminated and
		ASCII based.

		SBCS version only.

CALLED BY:	RobustFileSend

PASS:		es:di	- fptr to string
		cx	- length of string not including null-terminator

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyFileName	proc	near
	uses	ax,cx
	.enter

	inc	cx				; to check last char
	clr	ax				; looking for null
	pushdw	esdi				; ptr to buffer
	repnz	scasb
	popdw	esdi				; ptr to buffer
	cmp	cx, 0
	ERROR_Z	FILE_NAME_NOT_NULL_TERMINATED

	Assert	nullTerminatedAscii	esdi

	.leave
	ret
ECVerifyFileName	endp

endif ; ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustCheckErrors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if SF_EXIT and err is set.

CALLED BY:	INTERNAL Robust routines

PASS:		ds	- dgroup

RETURN:		CF	- SET if SF_EXIT and err is set
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustCheckErrors	proc	near
	uses	es
	.enter

		segmov	es, ds				; dgroup
		call	RobustCheckErrorsES

	.leave
	ret
RobustCheckErrors	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RobustCheckErrorsES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if SF_EXIT and err is set.

CALLED BY:	INTERNAL Robust routines

PASS:		es	- dgroup

RETURN:		CF	- SET if SF_EXIT and err is set
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RobustCheckErrorsES	proc	near
	.enter

EC<		call	ECCheckES_dgroup				>

		test	es:[sysFlags], mask SF_EXIT
		jnz	possibleError

doneNoError:
		clc
done:
	.leave
	ret

possibleError:
		tst	es:[err]
		jz	doneNoError
error::
EC<		WARNING ATTEMPTING_COM_READ_WRITE_WITH_ERROR_SET	>
		stc
		jmp	done
	
RobustCheckErrorsES	endp


Main	ends




