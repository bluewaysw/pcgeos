COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		TELNET Library (Network Extensions)
FILE:		telnetOption.asm

AUTHOR:		Simon Auyeung, Jul 19, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------
    INT TelnetHandleIncomingOption
				Handle an option request from remote
				connection

    INT TelnetCheckAndUpdateOption
				Update current option array and determine
				if the option request should be
				acknowledged

    EXT TelnetGetOptionMask	Get the record offset of TelnetOptionStatus
				from a Telnet option

    INT TelnetHandleOptionReply	Handle the option reply if we are waiting
				for reply on that option

    INT TelnetAckOption		Acknowledge an option

    INT TelnetRejectOption	Reject an option

    EXT TelnetSendOptionReal	Lowest level to send option data to remote
				connection

    INT TelnetTermTypeParseSuboption
				Parse the suboption data of Terminal type
				Telnet option

    INT TelnetHandleParsedSuboption
				Process a complete suboption data packet
				that is just received.

    INT TelnetSendSuboptionSocket
				Send suboption data

    INT TelnetSendTermType	Send the terminal type suboption data to
				server

    INT TelnetNegotiateInitOpt	Negotiate initial Telnet options

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon		7/19/95   	Initial revision


DESCRIPTION:
	This file contains routines about negotiating TELNET options.
		

	$Id: telnetOption.asm,v 1.1 97/04/07 11:16:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetHandleIncomingOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an option request from remote connection

CALLED BY:	(INTERNAL) TelnetOptionStartStateHandler
PASS:		al	= TelnetOptionID
		ds:si	= fptr to TelnetInfo
RETURN:		carry set if data cannot be sent through socket
			ax = TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (currentByte in TelnetOptionID) {
		if (option not expecting reply) {
			/* acknowledge if option enabled */
			if (option enabled) {
				TelnetAckOption(currentRequest, currentByte);
			} 
		} else {
			Handle reply;
			return;
		}
	}
	/* reject unsupported option and disabled option */
	TelnetRejectOption(currentRequest, currentByte);
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetHandleIncomingOption	proc	near
		uses	bx, cx
		.enter
EC <		Assert_fptr	dssi					>
		mov_tr	cl, al			; cl <- TelnetOptionID
		mov	bx, ds:[si].TI_socket	; bx <- Socket to send
		mov	al, ds:[si].TI_currentCommand
		call	TelnetCheckAndUpdateOption
						; carry set if don't reply
						; carry clear:
						;   ZF - reject
						;   !ZF - acknowledge
		jc	dontReply
		jz	rejectOption
		call	TelnetAckOption		; carry set if error
						; ax <- TelnetError
		jmp	done
		
rejectOption:
		call	TelnetRejectOption	; carry set if error
						; ax <- TelnetError
done:
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret

dontReply:
		mov	ax, TE_NORMAL		; everything normal
		clc
		jmp	done
TelnetHandleIncomingOption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetCheckAndUpdateOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update current option array and determine if the option
		request should be acknowledged

CALLED BY:	(INTERNAL) TelnetHandleIncomingOption
PASS:		al	= TelnetOptionRequest (TOR_WILL or TOR_DO)
		cl	= TelnetOptionID
		ds:si	= fptr to TelnetInfo
RETURN:		carry set if don't reply option
		carry clear:
			ZF set if reject option
			ZF clear if acknowledge option
DESTROYED:	nothing
SIDE EFFECTS:	
	If the option is enabled and the request is to disable it (DONT)

PSEUDO CODE/STRATEGY:
	if (option ID is currently supported) {
		if (option needs reply) {
			switch (passed in TelnetOptionRequest) {
			case TOR_DONT:
				if (local option enabled) {
					Disable option internally;
				}
				break;
			case TOR_WONT:
				if (remote option enabled) {
					Disable option internally;
				}
				break;
			case TOR_DO:
				if (local option enabled) {
					return ACK;
				}
			case TOR_WILL:
				if (remote option enabled) {
					return ACK;
				}
			}
			return REJECT;
		} else {
			return DON'T REPLY;
		}
	}
	return REJECT;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetCheckAndUpdateOption	proc	near
		uses	ax, cx
		.enter
EC <		Assert_TelnetOptionRequest	al			>
EC <		Assert_fptrXIP	dssi					>
		call	TelnetOptionIDToMask	; carry set if option not
						; supported
						; cx <- mask of
						; TelnetOptionStatus bit
		jc	reject			; jmp if option not supportee
		call	TelnetHandleOptionReply	; carry set if don't reply
		jc	done			; don't reply
	;
	; Reject if request is WONT or DONT. CX <- mask of TelnetOptionStatus
	; bit 
	;
		cmp	al, TOR_DONT
		je	dont
		cmp	al, TOR_WONT
		je	wont
		cmp	al, TOR_DO
		je	do
		cmp	al, TOR_WILL
		je	will

dont:
		TelnetIsOptionEnabled	cx, LOCAL
		jz	reject
	;
	; Remote doesn't want the option. Update local option internally.
	;
		stc				; clear option also
		TelnetUpdateOption	cx, LOCAL
		jmp	reject
	
wont:
		TelnetIsOptionEnabled	cx, REMOTE
		jz	reject
	;
	; Remote doesn't want the option. Update remote option internally.
	;
		stc				; clear option also
		TelnetUpdateOption	cx, REMOTE
		jmp	reject

do:
		TelnetIsOptionEnabled	cx, LOCAL
		jz	reject			; jmp if we don't support
		jmp	ack

will:
		TelnetIsOptionEnabled	cx, REMOTE
		jz	reject			; jmp if we don't support
		jmp	ack
	
reject:
		clr	al
		tst	al			; set ZF
EC <		ERROR_NZ -1						>
		jmp	reply
	
ack:
		tst	cx			; clears ZF since cx <> 0
EC <		ERROR_Z -1						>

reply:
EC <		ERROR_C -1			; tst should clear CF	>

done:
		.leave
		ret
TelnetCheckAndUpdateOption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetOptionIDToMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the record offset of TelnetOptionStatus from a Telnet
		option  

CALLED BY:	(EXTERNAL) TelnetCheckAndUpdateOption, TelnetParseReqOptions
PASS:		cl	= TelnetOptionID
RETURN:		carry set if option not supported
			carry clear if option supported
			cx 	= mask of TelnetOptionStatus bit
				corresponding to the option
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Do linear search of pre-determined supported options. More efficient
	searching algorithm should be used when the supported option size
	increases. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetOptionIDToMask	proc	far
		uses	ax, es, di
		.enter

		segmov	es, cs, ax
		mov	di, offset TelnetOptionIDTable
		mov_tr	al, cl			; al <- TelnetOptionID
		mov	cx, size TelnetOptionIDTable
		repne	scasb			; ZF=0 if no match found
		jnz	noMatch			; cl <- offset of bit in
						; TelnetOptionStatus 
		mov	al, 1
		shl	al, cl
		mov_tr	cl, al			; cl <- mask
		clc
		jmp	done
		
noMatch:
		stc
done:
		.leave
		ret
TelnetOptionIDToMask	endp

CheckHack <offset TOS_TRANSMIT_BINARY gt offset TOS_ECHO>
CheckHack <offset TOS_ECHO gt offset TOS_SUPPRESS_GO_AHEAD>
CheckHack <offset TOS_SUPPRESS_GO_AHEAD gt offset TOS_STATUS>
CheckHack <offset TOS_STATUS gt offset TOS_TIMING_MARK>
CheckHack <offset TOS_TIMING_MARK gt offset TOS_TERMINAL_TYPE>
CheckHack <size TelnetOptionID eq 1>
		
TelnetOptionIDTable	byte \
	TOID_TRANSMIT_BINARY,
	TOID_ECHO,
	TOID_SUPPRESS_GO_AHEAD,
	TOID_STATUS,
	TOID_TIMING_MARK,
	TOID_TERMINAL_TYPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetHandleOptionReply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the option reply if we are waiting for reply on that
		option 

CALLED BY:	(INTERNAL) TelnetCheckAndUpdateOption
PASS:		ds:si	= fptr to TelnetInfo
		cx	= TelnetOptionStatus mask
RETURN:		carry set if don't reply
		carry clear if reply
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (option in wait-for-reply array) {
		Clear wait-for-reply flag of that option;
		if (option == TOID_TERMINAL_TYPE) {
			Send terminal type suboption;
		}
		return DONT-REPLY;
	} else {
		return REPLY;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetHandleOptionReply	proc	near
		uses	ax, cx
		.enter
EC <		Assert_fptr	dssi					>
	;
	; Test if we are waiting for reply of that option.
	;
		test	ds:[si].TI_needReplyOptions, cx	; carry clear
		jz	reply				; jmp if not waiting
							; for reply
	;
	; Received reply. Clear the waiting-for-reply bit of the option.
	;
		push	cx
		not	cx				; cx mask inverted
		and	ds:[si].TI_needReplyOptions, cx	; clear it!
		pop	cx
	;
	; Don't send terminal type info until the other side asks for it. 
	; 
if 0
	;
	; If it is a reply of Terminal type, we need to reply terminal type
	; data.
	;
		BitTest	cx, TOS_TERMINAL_TYPE
		jz	noReply				; not terminal type,
							; don't reply
		call	TelnetSendTermType		; carry set if error
							; ax <- TelnetError
		jnc	noReply
	;
	; Error occurs when we reply, set the error flag then
	;
		mov	ds:[si].TI_error, ax
endif	
noReply::
		stc					; indicate no reply
	
reply:
		.leave
		ret
TelnetHandleOptionReply	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetAckOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge an option

CALLED BY:	(INTERNAL) TelnetHandleIncomingOption
PASS:		al	= TelnetOptionRequest (TOR_WILL or TOR_DO)
		cl	= TelnetOptionID
		bx	= Socket
RETURN:		carry set if error sending data
			ax = TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	TelnetOptionRequest replyRequest;

	switch (request passed in) {
	case	DO:
		replyRequest = WILL;
		break;

	case	WILL:
		replyRequest = DO;
		break;
	}
	TelnetSend(IAC, replyRequest, option ID);

	* Note *

	WONT and DONT requests should be handled by TelnetRejectOption.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetAckOption	proc	near
		uses	dx
		.enter
	;
	; WONT and DONT  requests should be handled by TelnetRejectOption.
	;
EC <		cmp	al, TOR_WILL					>
EC <		je	doneCheck					>
EC <		cmp	al, TOR_DO					>
EC <		ERROR_NE TELNET_INVALID_TELNET_OPTION_REQUEST		>
EC < doneCheck:								>

		mov	dl, TOR_DO
		cmp	al, TOR_WILL		; reply DO if WILL request
		je	sendOption
		mov	dl, TOR_WILL		; it's DO request, reply WILL
		
sendOption:
		mov_tr	al, dl
		call	TelnetSendOptionReal	; carry set if not sent
						; ax <- TelnetError
		.leave
		ret
TelnetAckOption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetRejectOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reject an option

CALLED BY:	(INTERNAL) TelnetHandleIncomingOption
PASS:		al	= TelnetOptionRequest
		cl	= TelnetOptionID
		bx 	= Socket
RETURN:		carry set if error sending data
			ax = TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	TelnetOptionRequest replyRequest;

	switch (request passed in) {
	case WILL:
	case WONT:
		replyRequest = DONT;
		break;
	case DO:
	case DONT
		replyRequest = WONT;
	}
	TelnetSend(IAC, replyRequest, optionID);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetRejectOption	proc	near
		uses	dx
		.enter
	;
	; Send DONT if the request is WILL or WONT
	;
		mov	dl, TOR_DONT		; dl <- TelnetOptionRequest 
						; to return
		cmp	al, TOR_WONT
		je	sendOption
		cmp	al, TOR_WILL
		je	sendOption
	;
	; the request is DO or DONT. Send WONT back
	;
		mov	dl, TOR_WONT
	
sendOption:
		mov_tr	al, dl
		call	TelnetSendOptionReal	; carry set if not sent
						; ax <- TelnetError
		.leave
		ret
TelnetRejectOption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendOptionReal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lowest level to send option data to remote connection

CALLED BY:	(EXTERNAL) TelnetAckOption, TelnetNegotiateInitOpt,
		TelnetRejectOption
PASS:		al	= TelnetOptionRequest
		cl	= TelnetOptionID
		bx	= Socket
RETURN:		carry set if data cannot be sent
			ax	= TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendOptionReal	proc	far
	bufToSend	local	TelnetOptionPacket
		uses	ds, si, cx
		.enter
EC <		Assert_socket	bx					>
EC <		Assert_TelnetOptionRequest	al			>
		segmov	ds, ss
		lea	si, ss:[bufToSend]
		mov	ds:[si].TOP_escape, TC_IAC
		mov	ds:[si].TOP_request, al
		mov	ds:[si].TOP_optionID, cl
	;
	; Send the data to socket
	;
		mov	cx, size TelnetOptionPacket
		clr	ax			; no SocketSendFlags
		call	TelnetSendSocket	; carry set if error
						; ax <- TelnetError
		.leave
		ret
TelnetSendOptionReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetTermTypeParseSuboption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the suboption data of Terminal type Telnet option

CALLED BY:	(INTERNAL) TelnetSuboptionEndReadyStateHandler,
		TelnetSuboptionReadStateHandler
PASS:		al	= current character to parse
		ds:si	= fptr to TelnetInfo
RETURN:		bx	= TelnetStateType (next state)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetTermTypeParseSuboption	proc	near
		.enter
EC <		Assert_fptrXIP	dssi					>
		mov	bx, ds:[si].TI_termTypeState
		cmp	bx, TTSST_NONE		; just starting?
		je	starting
		cmp	bx, TTSST_SEND
	;
	; We shouldn't get TTSST_SEND since after receiving SEND byte, it
	; should get IAC SE sequence which should be caught in
	; TelnetSuboptionReadStateHandler and
	; TelnetSuboptionEndReadyStateHandler. Reset sttte
	;
EC <		WARNING_E TELNET_TERM_TYPE_SUBOPTION_EXPECTS_IAC_SE	>
		je	reset			; it shouldn't reach here
		cmp	bx, TTSST_RECV
		je	recving
	;
	; Do nothing if the state is unknown. Possibly sequence received is
	; incorrect.
	;
EC <		cmp	bx, TTSST_NONE					>
EC <		ERROR_NE TELNET_INVALID_TERMINAL_TYPE_STATE		>

contRead:
		mov	bx, TST_SUBOPTION_READ

done:
EC <		Assert_etype	bx, TelnetStateType			>
		.leave
		ret

starting:
	;
	; Figure out if we are receiving terminal type, or being asked to
	; send terminal type.
	;
		CheckHack	<IS eq 0>
		tst	al			; recv term type?
		jz	toRecv
		cmp	al, SEND		; need to send term type?
EC <		je	toSend						>
NEC <		jne	reset			; unexpected, reset!	>
	;
	; Unknown state, it should expect either IS or SEND. Reset the state.
	;
EC <		WARNING	TELNET_TERM_TYPE_SUBOPTION_EXPECTS_IS_OR_SEND>
EC <		jmp	reset						>

toSend::
		mov	ds:[si].TI_termTypeState, TTSST_SEND
		jmp	contRead
		
toRecv:
EC <		WARNING TELNET_CLIENT_SHOULD_NOT_ACCEPT_TERM_TYPE_SUBOPTION>
		mov	ds:[si].TI_termTypeState, TTSST_RECV
		jmp	contRead

recving:
	;
	; Currently, the terminal type string sent in is ignored.
	;
%out	~~~~ TelnetTermTypeParseSuboption: Not storing terminal type sent in ~~~~
		jmp	contRead
		
reset:
		mov	ds:[si].TI_termTypeState, TTSST_NONE
		mov	bx, TST_GROUND
		jmp	done
TelnetTermTypeParseSuboption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetHandleParsedSuboption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a complete suboption data packet that is just
		received. 

CALLED BY:	(INTERNAL) TelnetSuboptionEndReadyStateHandler
PASS:		ds:si	= fptr to TelnetInfo
RETURN:		carry set if error 
			ax = TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetHandleParsedSuboption	proc	near
		.enter
EC <		Assert_fptr	dssi					>
		cmp	ds:[si].TI_currentOption, TOID_TERMINAL_TYPE
		jne	retNormal
	;
	; Only Terminal type suboption is supported. Later, other suboptions
	; can be handled here depending on the current option ID.
	;
		cmp	ds:[si].TI_termTypeState, TTSST_SEND
		jne	retNormal		; ignore term type recv'ed
		call	TelnetSendTermType	; carry set if sending error
						; ax <- TelnetError
		jmp	done

retNormal:
		mov	ax, TE_NORMAL
		clc

done:
		mov	ds:[si].TI_termTypeState, TTSST_NONE
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret
TelnetHandleParsedSuboption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendSuboptionSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send suboption data

CALLED BY:	(INTERNAL) TelnetSendTermType
PASS:		bx	= Socket
		ds:si	= fptr to data to send
		cx	= size of data to send (in bytes)
		al	= TelnetOptionID
RETURN:		carry set if error (no gurantee how much data has actually
		been sent)
			ax = TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendSuboptionSocket	proc	near
	dataToSend	local	fptr	push	ds, si
	dataSzToSend	local	word	push	cx
	bufToSend	local	TELNET_SUBOPTION_PACKET_HEAD_SIZE dup (byte)
						; generic buf to send data 
		uses	bx, cx, dx, ds, si
		.enter
	;
	; We are using the same buffer "bufToSend" to send packet head and
	; tail. So, allocate space for the longest one.
	;
		CheckHack <TELNET_SUBOPTION_PACKET_HEAD_SIZE ge \
			   TELNET_SUBOPTION_PACKET_TAIL_SIZE>
EC <		Assert_socket	bx					>
EC <		Assert_buffer	dssi, cx				>
EC <		Assert_TelnetOptionID	al				>
	;
	; *Note*
	;
	; We are sending the suboption packet in 3 parts. It can be optimized
	; to put all data into a big buffer and deliver once.
	;
	; Send the packet head first "IAC SB TelnetOptionID".
	;
		segmov	ds, ss
		lea	si, ss:[bufToSend]
		mov	{byte}ds:[si], TC_IAC
		mov	{byte}ds:[si+1], TC_SB
		mov	ds:[si+2], al
		mov	cx, TELNET_SUBOPTION_PACKET_HEAD_SIZE
		clr	ax			; no SocketSendFlags
		call	TelnetSendSocket	; carry set if error
						; ax <- TelnetError
		jc	done
	;
	; Send the real data caller wants to send
	;
		lds	si, ss:[dataToSend]	; ds:si <- data to send
		mov	cx, ss:[dataSzToSend]	; cx <- size of data to send
		CheckHack <TE_NORMAL eq 0>
EC <		tst	ax						>
EC <		ERROR_NZ -1			; TelnetError=TE_NORMAL	>
		call	TelnetSendSocket	; carry set if error
						; ax <- TelnetError
		jc	done
	;
	; Send the packet tail. "IAC SE"
	;
		segmov	ds, ss			; we ax=0
		lea	si, ss:[bufToSend]
		mov	{byte}ds:[si], TC_IAC
		mov	{byte}ds:[si+1], TC_SE
		mov	cx, TELNET_SUBOPTION_PACKET_TAIL_SIZE
		CheckHack <TE_NORMAL eq 0>
EC <		tst	ax						>
EC <		ERROR_NZ -1			; TelnetError=TE_NORMAL	>
		call	TelnetSendSocket	; carry set if error
						; ax <- TelnetError
done:
		.leave
		ret
TelnetSendSuboptionSocket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendTermType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the terminal type suboption data to server

CALLED BY:	(INTERNAL) TelnetHandleOptionReply, TelnetHandleParsedSuboption
PASS:		ds:si	= fptr to TelnetInfo
RETURN:		carry set if error sending
			ax = TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendTermType	proc	near
	sendSocket	local	Socket
	bufToSendBlock	local	hptr		; chunk storing data to send
		uses	bx, cx, dx, es, di, si
		.enter
EC <		Assert_fptrXIP	dssi					>
		mov	bx, ds:[si].TI_socket	; socket for connection
		mov	ss:sendSocket, bx
EC <		Assert_socket	bx					>
	;
	; Allocate a chunk to send suboption data out. First, figure out how
	; long the term type string is. 
	;
		mov	di, si
		add	di, offset TI_termType	
		segmov	es, ds, ax		; es:di <- TI_termType
		ByteStrLength	includeNull	; cx <- strlen w/o NULL,
						; ax destroyed	
						; counting NULL is for IS byte
		inc	cx			; for 1 more IS byte
		push	cx
	;
	; We would like to use a chunk here, but we can't run
	; the risk of the TelnetInfo chunk moving when we do the
	; allocation, since the chunk handle isn't available to us.
	;
		mov	ax, ALLOC_DYNAMIC_LOCK
		xchg	ax, cx
		call	MemAlloc		; bx <- hptr of buffer
						; ax <- sptr of buffer
						; ds <- sptr of same block
		pop	cx
		jc	noMem			; carry set if error
	;
	; Copy data to new chunk to send.
	; 	IS <term type string>
	;
		mov	ss:[bufToSendBlock], bx	; save chunk handle
		mov	es, ax
		clr	di			; *es:di <- new buf to send
EC <		Assert_fptrXIP	esdi					>
		push	di			; save nptr to chunk
		mov	{byte}es:[di], IS	; put in IS byte
		inc	di			; es:di <- term type string
						; to fill
	;
	; Copy terminal type string
	;
		add	si, offset TI_termType	; ds:si <- term type string src
		ByteCopyString			; ax destroyed

		pop	si			; es:si <- data to send
		push	ds
		segmov	ds, es, ax		; ds:si <- data to send
		mov	bx, ss:[sendSocket]
		mov	al, TOID_TERMINAL_TYPE
		call	TelnetSendSuboptionSocket
						; carry set if error
						; ax <- TelnetError
	;
	; Free up the chunk just allocated to send data
	;
		pop	ds
		pushf
		mov	bx, ss:[bufToSendBlock]
		call	MemFree		; bx destroyed
		popf
done:
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret

noMem:
		mov	ax, TE_INSUFFICIENT_MEMORY
		jmp	done
TelnetSendTermType	endp

CommonCode	ends

InitExitCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetNegotiateInitOpt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negotiate initial Telnet options

CALLED BY:	(INTERNAL) TelnetConnect
PASS:		bx	= TelnetConnectionID
		ds	= TelnetControl segment
		ss:bp	= inherited stack of TelnetConnect
RETURN:		carry set if error
			ax	= TelnetError
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	infoPtr = Deref TelentInfo Ptr;
	if (infoPtr.TI_enabledRemoteOptions support SUPPRESS_GO_AHEAD) {
		retError = Send DO SUPPRESS_GO_AHEAD option;
		if (retError) {
			return retError;
		} else {
			Set infoPtr.TI_needReplyOptions SUPPRESS_GO_AHEAD
			flag;
		}
	}
	if (infoPtr.TI_enabledLocalOptions support TERMINAL_TYPE) {
		retError = Send WILL TERMINAL_TYPE option;
		if (retError) {
			return retError;
		} else {
			Set infoPtr.TI_needReplyOptions TERMINAL_TYPE
			flag;
		}
	}
	if (infoPtr.TI_enabledRemoteOptions support ECHO) {
		retError = Send DO ECHO option;
		if (retError) {
			return retError;
		} else {
			Set infoPtr.TI_needReplyOptions ECHO
			flag;
		}
	}
	return retError;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetNegotiateInitOpt	proc	far
		uses	si, bx, cx
		.enter	inherit TelnetConnect				
EC <		Assert_segment	ds					>
EC <		Assert_TelnetConnectionID	bx			>

		mov	si, bx
		mov	si, ds:[si]		; dssi<- TelnetInfo
		mov	bx, ds:[si].TI_socket	; bx <- Socket
EC <		Assert_socket	bx					>
	;
	; The initial options to negotiate: TERMINAL_TYPE, ECHO
	; SUPPRESS_GO_AHEAD of the host.
	;
	; If these options are enabled, send these option requests and wait
	; for reply. Currently, these codes are not set up too flexible to
	; change because we only want certain options should be sent out
	; initially. 
	;
		BitTest	ds:[si].TI_enabledRemoteOptions, \
			TOS_SUPPRESS_GO_AHEAD
		jz	termType
	;
	; Send Suppress Go Ahead option and set wait-for-reply flag
	;
		mov	al, TOR_DO
		mov	cl, TOID_SUPPRESS_GO_AHEAD
		call	TelnetSendOptionReal	; carry set if error
						;   ax <- TelnetError
		jc	done
		BitSet	ds:[si].TI_needReplyOptions, TOS_SUPPRESS_GO_AHEAD
		
termType:
	;
	; Check if local terminal type option is enabled. Send option if
	; enabled.
	;
		BitTest	ds:[si].TI_enabledLocalOptions, \
			TOS_TERMINAL_TYPE
		jz	remoteEcho
	;
	; Send Terminal type option and set wait-for-reply flag
	;
		mov	al, TOR_WILL
		mov	cl, TOID_TERMINAL_TYPE
		call	TelnetSendOptionReal	; carry set if error
						;   ax <- TelnetError
		jc	done
		BitSet	ds:[si].TI_needReplyOptions, TOS_TERMINAL_TYPE
						; carry clear
remoteEcho:
	;
	; Check if remote echo turned on
	;
		BitTest ds:[si].TI_enabledRemoteOptions, \
			TOS_ECHO
		jz	done
	;
	; Send remote echo option and set wait-for-reply flag
	;
		mov	al, TOR_DO
		mov	cl, TOID_ECHO
		call	TelnetSendOptionReal	; carry set if error
						;   ax <- TelnetError
		jc	done
		BitSet	ds:[si].TI_needReplyOptions, TOS_ECHO
						; carry clear
						; flags preserved
done:		
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret
TelnetNegotiateInitOpt	endp

InitExitCode	ends
