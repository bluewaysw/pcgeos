COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		Modem Driver
FILE:		modemParse.asm

AUTHOR:		Jennifer Wu, Mar 16, 1995

ROUTINES:
	Name			Description
	----			-----------
Method:
	ModemReceiveData	Data notification handler

Subroutines:
	ModemDataNotify
	ModemResponseNotify
	
	ModemBuildResponse
	ResponseDoNone
	ResponseDoSawBeginCR
	ResponseDoRecvResponse
	ResponseDoSawEndCR
	ResponseDoSawBeginEcho
	ResponseDoRecvEcho

	ModemParseNoConnection
	ModemParseBasicResponse
	ModemParseDialResponse
	ModemParseAnswerCallResponse
	ModemParseEscapeResponse

	ModemParseConnectResponse
	ModemParseConnectBaud
	ModemBaudToUnsignedInt
	ModemCheckCommandEcho

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/16/95		Initial revision

DESCRIPTION:
	Code for processing modem responses	

	$Id: modemParse.asm,v 1.1 97/04/18 11:47:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CommonCode	segment resource

;---------------------------------------------------------------------------
; 		Modem Response Strings
;---------------------------------------------------------------------------

responseOk		char	"OK"
responseError		char	"ERROR"
responseBusy		char	"BUSY"
responseNoDialtone	char	"NO DIALTONE"
responseNoAnswer	char	"NO ANSWER"
responseNoCarrier	char	"NO CARRIER"
responseConnect		char	"CONNECT"
responseBlacklisted	char	"BLACKLISTED"
responseDelayed		char	"DELAYED"


;---------------------------------------------------------------------------
;		Data notification handler
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemReceiveData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data notification handler.

CALLED BY:	MSG_MODEM_RECEIVE_DATA
PASS: 		*ds:si	= ModemProcessClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
PSEUDO CODE/STRATEGY:
		NOTE: If client is not registered for data notification,
		then the modem driver will not get further notifications
		until the client has read at least one byte from the serial
		port.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/20/95   	Initial version
	jwu	9/11/96		keep reading data after a response

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemReceiveData	method dynamic ModemProcessClass, 
					MSG_MODEM_RECEIVE_DATA
	;
	; Make sure this notification didn't come in after modem 
	; thread is being destroyed.  If it did, just exit because
	; the port has been closed.	
	;
		mov	bx, handle dgroup
		call	MemDerefES

		tst	es:[modemThread]
		LONG	je	exit
dataLoop:
	;
	; If in command mode, look for a response.  Else notify
	; client of data.
	;
		test	es:[modemStatus], mask MS_COMMAND_MODE 
		jnz	isResponse

		cmp	es:[dataNotify].SN_type, SNM_NONE		
		je	flushInput
		call	ModemDataNotify
		jmp	exit
isResponse:
	;
	; Build the modem response.  If a complete response has been
	; received, send out any needed response notifications.  Then,
	; parse the response.
	;
		call	ModemBuildResponse		
		jc	exit
		cmp	es:[respNotify].SN_type, SNM_NONE
		je	parse
		call	ModemResponseNotify
parse:
		call	es:[parser]
	;
	; Reset response status and response size.
	;
		lahf
		andnf	es:[modemStatus], not mask MS_RESPONSE_INFO
		mov	es:[responseSize], 0
		sahf
		jc	dataLoop
	;
	; Wake up client, if any, so they can check response.  Stop
	; response timer, unless it has already expired.
	;
		test	es:[modemStatus], mask MS_CLIENT_BLOCKED
		jz	exit
		
		clr	bx
		xchg	bx, es:[responseTimer]
EC <		tst	bx					>
EC <		ERROR_E	RESPONSE_TIMER_MISSING			>
		mov	ax, es:[responseTimerID]
		call	TimerStop

		BitClr	es:[modemStatus], MS_CLIENT_BLOCKED
		mov	bx, es:[responseSem]
		call	ThreadVSem
	;
	; Continue reading data in case more follows the response.
	;
		jmp	dataLoop

flushInput:
	;
	; Make sure port is still open after we release
	; es:[responseSem] as another thread could be closing
	; modem. Port is closed if es:[portNum] == -1.
	;
EC <		WARNING MODEM_DRIVER_FLUSHING_INPUT_DATA		>
		mov	bx, es:[portNum]
		cmp	bx, -1
		je 	exit
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_FLUSH
		call	es:[serialStrategy]
exit:
		ret

ModemReceiveData	endm


;---------------------------------------------------------------------------
;			Subroutines
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDataNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the client of incoming data using the method 
		requested by the client.

CALLED BY:	ModemReceiveData

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx, di, si

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/20/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDataNotify	proc	near

CheckHack <SNM_ROUTINE lt SNM_MESSAGE>
		mov	al, es:[dataNotify].SN_type
		cmp	al, SNM_ROUTINE

		mov	ax, es:[dataNotify].SN_data
		ja	notifyMethod

		pushdw	es:[dataNotify].SN_dest.SND_routine
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jmp	done
notifyMethod:
		mov	bx, es:[dataNotify].SN_dest.SND_message.handle
		mov	si, es:[dataNotify].SN_dest.SND_message.chunk
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		ret
ModemDataNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemResponseNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the client about a modem response using the method
		requested by the client.

CALLED BY:	ModemReceiveData

PASS:		es	= dgroup
		response is in responseBuf
		responseSize contains size of response (not null terminated)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di, si

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/20/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemResponseNotify	proc	near

	;
	; Figure out how to deliver response to client.
	;
CheckHack <SNM_ROUTINE lt SNM_MESSAGE>
		mov	cx, es:[responseSize]
		mov	al, es:[respNotify].SN_type
		cmp	al, SNM_ROUTINE
		ja	notifyMethod
	;
	; Do routine notification.
	;		
		mov	ax, es:[respNotify].SN_data
		mov	dx, es
		mov	bp, offset responseBuf
		pushdw	es:[respNotify].SN_dest.SND_routine
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jmp	done
notifyMethod:
	;
	; Allocate a block for the response.  If failed, just bail.
	;
		mov	dx, cx				; dx = size
		mov_tr	ax, cx			
		mov	cx, (mask HAF_LOCK shl 8) or mask HF_SHARABLE or \
					mask HF_SWAPABLE
		call	MemAlloc			
		jc	done

		push	ds, es
		mov	ds, ax
		segxchg	ds, es				
		clr	di				; es:di = dest.
		mov	si, offset responseBuf		; ds:si = response
		mov	cx, dx				; cx = size
		rep	movsb				
		call	MemUnlock
		pop	ds, es
	;
	; Send notification.
	;
		mov_tr	cx, dx				; cx = size
		mov_tr	dx, bx				; ^hdx = response
		mov	ax, es:[respNotify].SN_data	; ax = msg
		movdw	bxsi, es:[respNotify].SN_dest.SND_message
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		ret

ModemResponseNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemBuildResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the modem response from the incoming data.  The 
		ending <CR> is included in the response.

CALLED BY:	ModemReceiveData

PASS:		es = ds	= dgroup

RETURN:		carry clear if complete response has been received

DESTROYED:	ax, bx, cx, di, si

PSEUDO CODE/STRATEGY:
		get current state 
	read loop:
		read byte
		call the routine for the current response state
		go to read loop if more data is needed

	storeState:
		store the new  state into dgroup
		
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/20/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemBuildResponse	proc	near

	;
	; Get the common info now so it's only done once.
	;
		mov	si, offset es:[responseBuf]
		add	si, es:[responseSize]		; ds:si = place for data

		clr	ch
		mov	cl, es:[modemStatus]
		andnf	cl, mask MS_RESPONSE_INFO	; cl = current state
		mov	bx, es:[portNum]
readLoop:
	;
	; Read one byte of data at a time.  Then call the appropriate
	; routine to process it, depending on the state.
	;
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_READ_BYTE
		call	es:[serialStrategy]		; al = byte read
		jc	done			

		mov	bp, cx				
		shl	bp, 1				; index into table
		call	cs:responseTable[bp]
		jc	readLoop
done:
	;
	; Store the new state in the modem status and update response size.
	;
		lahf
		andnf	es:[modemStatus], not mask MS_RESPONSE_INFO
		ornf	es:[modemStatus], cl
		sub	si, offset es:[responseBuf]
		mov	es:[responseSize], si

EC <		cmp	si, RESPONSE_BUFFER_SIZE			>
EC <		ERROR_A MODEM_INTERNAL_ERROR	; overflowed buffer 	>

		sahf


		ret

responseTable	nptr	\
	offset	ResponseDoNone,		; MRS_NONE
	offset  ResponseDoSawBeginCR,	; MRS_SAW_BEGIN_CR
	offset	ResponseDoRecvResponse,	; MRS_RECV_RESPONSE
	offset	ResponseDoSawEndCR,	; MRS_SAW_END_CR
	offset  ResponseDoSawBeginEcho,	; MRS_SAW_BEGIN_ECHO
	offset  ResponseDoRecvEcho	; MRS_RECV_ECHO

ModemBuildResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseDoNone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the data byte in the state where nothing has
		been received from the modem yet.

CALLED BY:	ModemBuildResponse
		ResponseDoSawBeginEcho
		ResponseDoRecvEcho

PASS:		al	= byte
		ds:si	= place for data byte in response buffer
		es	= dgroup

RETURN:		cl	= next ModemResponseState
		ds:si	= place for next data byte
		carry set

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:
		if byte is <CR>, assume it is part of <CR><LF> pair and
			set state to MRS_SAW_BEGIN_CR
		if byte is "A" or "+", assume it is begining of command echo 
			and set state to MRS_SAW_BEGIN_ECHO
		else if byte is <LF> assume modem is beginning response 
			without complete leading <CR><LF> pair and 
			set state to MRS_RECV_RESPONSE
		else store byte, assuming modem is beginning response
			without leading <CR><LF> pair and set state
			to MRS_RECV_RESPONSE
		return carry set

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/20/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseDoNone	proc	near

EC <		cmp	si, offset responseBuf			>
EC <		ERROR_NE MODEM_BAD_RESPONSE_STATE		>
EC <		cmp	cl, MRS_NONE				>
EC <		ERROR_NE MODEM_BAD_RESPONSE_STATE		>

	;
	; Look for <CR>.
	;	
		cmp	al, C_CR
		jne	checkA
		mov	cl, MRS_SAW_BEGIN_CR
		jmp	done
checkA:
	;
	; Look for "A" or "+".  If neither, then assume modem is 
	; beginning the response without the <CR><LF> pair.  Store 
	; the byte and advance to the appropriate state.
	;
		mov	cl, MRS_SAW_BEGIN_ECHO		; assume echo
		cmp	al, 'A'
		je	storeByte
		
		cmp	al, '+'
		je	storeByte
	;
	; If <LF>, just set state else store byte also.
	;
		mov	cl, MRS_RECV_RESPONSE		; start response
		cmp	al, C_LF
		je	done
storeByte:
		mov	ds:[si], al
		inc	si
done:
		stc
		ret
ResponseDoNone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseDoSawBeginCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the data byte in the state where only a <CR> has
		been received from the modem.

CALLED BY:	ModemBuildResponse

PASS:		al	= byte
		ds:si	= place for data byte in response buffer
		es	= dgroup
		cl	= MRS_SAW_BEGIN_CR

RETURN:		cl	= next ModemResponseState
		ds:si	= place for next data byte
		carry set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If byte is <LF>, set state to MRS_RECV_RESPONSE
		else (assume the previous <CR> was line garbage) 
			return state to MRS_NONE and reprocess byte in case
				it is a <CR>
		return carry set

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/20/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseDoSawBeginCR	proc	near

EC <		cmp	si, offset responseBuf			>
EC <		ERROR_NE MODEM_BAD_RESPONSE_STATE		>
EC <		cmp	cl, MRS_SAW_BEGIN_CR			>
EC <		ERROR_NE MODEM_BAD_RESPONSE_STATE		>
	;
	; Assume a <LF> follows the <CR> for the opening <CR><LF> pair.
	;
		mov	cl, MRS_RECV_RESPONSE
		cmp	al, C_LF
		je	done
	;
	; Reset modem response state and reprocess current byte as it
	; may be a <CR>.
	;
		mov	cl, MRS_NONE
		call	ResponseDoNone
done:
		stc
		ret
ResponseDoSawBeginCR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseDoRecvResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the data byte as part of the response or check
		for the ending <CR><LF> pair.

CALLED BY:	ModemBuildResponse
		ResponseDoSawEndCR

PASS:		al	= byte
		ds:si	= place for data byte in response buffer
		es	= dgroup
		cl	= MRS_RECV_RESPONSE

RETURN:		cl	= next ModemResponseState
		ds:si	= place for next data byte
		carry set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If buffer will overflow, discard data in buffer 
			reprocess byte from start
		else 
			stick the byte in the buffer
			if byte is <CR>, assume it is part of <CR><LF> pair and
				set state to MRS_SAW_END_CR
			return carry set

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/20/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseDoRecvResponse	proc	near

EC <		cmp	cl, MRS_RECV_RESPONSE			>
EC <		ERROR_NE MODEM_BAD_RESPONSE_STATE		>

	;
	; Check for possible overflow.  
	; to overflow the buffer so data must be garbage.
	;
CheckHack <offset responseBuf + RESPONSE_BUFFER_SIZE eq offset responseSize>
		cmp	si, offset responseSize 
		jb	storeByte

EC <		WARNING MODEM_CORRECTING_RESPONSE_BUFFER_OVERFLOW	>
		mov	si, offset responseBuf
		mov	cl, MRS_NONE
		call	ResponseDoNone
		jmp	done
storeByte:
	;
	; Store byte and check if end of response.
	;
		mov	ds:[si], al
		inc	si

		cmp	al, C_CR
		jne	done

		mov	cl, MRS_SAW_END_CR
done:
		stc
		ret
ResponseDoRecvResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseDoSawEndCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the data byte where the ending <LF> of the final
		<CR><LF> pair is expected.

CALLED BY:	ModemBuildResponse

PASS:		al	= byte
		ds:si	= place for data byte in response buffer
		cl	= MRS_SAW_END_CR

RETURN:		cl	= next ModemResponseState
		ds:si	= place for next data byte
		carry clear if a complete response has been received

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if byte is LF, return with carry clear
		else assume the previous <CR> was part of the data and 
			stick that into the buffer.  Set state back to
			MRS_RECV_RESPONSE, and call ResponseDoRecvResponse

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/20/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseDoSawEndCR	proc	near

EC <		cmp	cl, MRS_SAW_END_CR			>
EC <		ERROR_NE MODEM_BAD_RESPONSE_STATE		>
	;
	; If <LF>, then we have a complete response.  
	; 
		cmp	al, C_LF
		jne	notEnd
	;
	; If response only contains 1 byte, then assume this is the 
	; start of a new response.  The single byte is the <CR> that
	; brought us to this phase.  Do NOT reprocess the <LF>.
	;
		cmp	si, offset responseBuf + 1	; only > possible
		ja	exit				; carry clear

		dec	si				; discard previous <CR>
		mov	cl, MRS_RECV_RESPONSE		
		jmp	done
notEnd:
	;
	; The previous <CR> is part of the response.  Continue receiving 
	; the response.  Reprocess the current byte in case it may be a <CR>.
	;
		mov	cl, MRS_RECV_RESPONSE
		call	ResponseDoRecvResponse
done:
		stc
exit:
		ret
ResponseDoSawEndCR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseDoSawBeginEcho
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the data byte where the "T" or "+" of the start of a 
		command echo is expected.

CALLED BY:	ModemBuildResponse	

PASS:		al	= byte
		ds:si	= place for data byte in response buffer
		cl	= MRS_SAW_BEGIN_ECHO

RETURN:		cl	= next ModemResponseState
		ds:si	= place for next data byte
		carry set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If byte is "T" or "+", store it in response buffer and set 
			state to MRS_RECV_ECHO
		else, decrement SI, set state to MRS_NONE and 
			call ResponseDoNone to reprocess byte 
			in case it is a <CR>

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/17/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseDoSawBeginEcho	proc	near

EC <		cmp	cl, MRS_SAW_BEGIN_ECHO			>
EC <		ERROR_NE MODEM_BAD_RESPONSE_STATE		>

	;
	; If "T" or "+", then assume this is a command echo.  
	;
		cmp	al, 'T'
		je	beginEcho

		cmp	al, '+'
		jne	startOver
beginEcho:
		mov	ds:[si], al
		inc	si
		mov	cl, MRS_RECV_ECHO		
		jmp	done
startOver:
	;
	; Discard "A".  Reprocess byte in case it's a <CR>.  
	;
		dec	si
		mov	cl, MRS_NONE
		call	ResponseDoNone
done:
		stc
		ret
ResponseDoSawBeginEcho	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseDoRecvEcho
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the data byte as part of the command echo or 
		check for the ending <CR>.  <CR> is included in response.

CALLED BY:	ModemBuildResponse	

PASS:		al	= byte
		ds:si	= place for data byte in response buffer
		es	= dgroup
		cl	= MRS_RECV_ECHO

RETURN:		cl	= next ModemResponseState
		ds:si	= place for next data byte
		carry clear if a complete echo has been received

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If buffer will overflow, discard data in buffer and
			reprocess byte from start
		else store byte
			if <CR>, complete response received
NOTE:
		Need to check for overflowing response buffer in case 
		"AT" or "++" happened to be in the input data stream, causing
		us to collect the garbage data as a command echo.  We will
		continue until a <CR> is received if this check is missing.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/17/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseDoRecvEcho	proc	near

EC <		cmp	cl, MRS_RECV_ECHO				>
EC <		ERROR_NE MODEM_BAD_RESPONSE_STATE			>

	;
	; Check for possible overflow.  No response or echo is long enough 
	; to overflow the buffer so data must be garbage.
	;
CheckHack <offset responseBuf + RESPONSE_BUFFER_SIZE eq offset responseSize>
		cmp	si, offset responseSize 
		jb	storeByte

EC <		WARNING MODEM_CORRECTING_RESPONSE_BUFFER_OVERFLOW	>
		mov	si, offset responseBuf
		mov	cl, MRS_NONE
		call	ResponseDoNone
		jmp	exit
storeByte:
	;
	; Store byte and check if end of echo.
	;
		mov	ds:[si], al
		inc	si

		cmp	al, C_CR
		je	exit			; carry clear
		stc
exit:
		ret
ResponseDoRecvEcho	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemParseNoConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a CONNECT response, dropping all others.

CALLED BY:	ModemReceiveData

PASS:		es	= dgroup

RETURN:		carry clear if CONNECT received

DESTROYED:	ax, cx, dx, ds, di, si 

PSEUDO CODE/STRATEGY:
		if responseSize < CONNECT, don't bother to compare
		compare response to CONNECT, if equal return carry clear

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/20/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemParseNoConnection	proc	near
	;
	; Is response at least long enough to be CONNECT?  CONNECT
	; responses may also be followed by the baud rate.
	;
		mov	cx, size responseConnect
		cmp	cx, es:[responseSize]
		ja	notFound			; response too short
	;
	; Compare with CONNECT.
	;
		push	ds
		mov	di, offset es:[responseBuf]	; es:di = response
		segmov	ds, cs, si
		mov	si, offset responseConnect	; ds:si = "CONNECT"
		repe	cmpsb
		pop	ds
		jnz 	notFound
	;
	; Connected.  Parse baud rate to generate more specific result.
	; Then set driver to data mode.
	;
		mov	ax, MRC_CONNECT		
		call	ModemParseConnectBaud		 ; ax = MRC_CONNECT_*
EC <		Assert	etype, ax, ModemResultCode		>
		mov	es:[result], ax

		BitClr	es:[modemStatus], MS_COMMAND_MODE
		BitClr	es:[miscStatus], MSS_MODE_UNCERTAIN
		clc
		jmp	exit
notFound:
		stc
exit:
		ret
ModemParseNoConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemParseBasicResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for echo of the command, OK or ERROR responses.
		Treat any other as an unexpected response, but keep
		looking for more.

CALLED BY:	ModemReceiveData

PASS:		es	= dgroup

RETURN:		carry clear if OK or ERROR received

DESTROYED:	ax, cx, di, si

PSEUDO CODE/STRATEGY:
		compare response to OK
		if equal, store result as MRC_OK and return carry clear
		
		compare response to ERROR and NO CARRIER
		if equal, store result as MRC_ERROR, 
			reset parser to no connection because the basic
				response is for commands issued when there is no
				connection yet
			return carry clear		
		
		check if response is a command
		if yes, return carry set

		else store result as MRC_UNKNOWN_RESPONSE and return carry set
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/21/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemParseBasicResponse	proc	near
		uses	ds
		.enter
	;
	; Check if response is "OK".
	;
		segmov	ds, cs, cx
		mov	cx, es:[responseSize]
		mov	di, offset es:[responseBuf]	; es:di = response

		cmp	cx, size responseOk
		jb	unknown				; what's less than OK?

		mov	ax, MRC_OK			; assume OK
		push	di, cx
		mov	si, offset responseOk		; ds:si = "OK"
		mov	cx, size responseOk
		repe	cmpsb
		pop	di, cx
		jz	stopLooking
	;
	; Check if response is "ERROR" or "NO CARRIER".  We let "NO
	; CARRIER" be the same as an ERROR because sometimes the
	; initialization sequence will result in NO CARRIER (due to
	; hangup problems) and we want to respond to that quickly,
	; rather then letting the timeout expire.
	;
		mov	ax, MRC_ERROR			; assume ERROR
		cmp	cx, size responseNoCarrier
		jb	checkError

		push	di, cx
		mov	si, offset responseNoCarrier
		mov	cx, size responseNoCarrier
		repe	cmpsb
		pop	di, cx
		jz	stopLooking

checkError:
		cmp	cx, size responseError
		jb	checkEcho			

		push	di, cx
		mov	si, offset responseError
		mov	cx, size responseError
		repe	cmpsb
		pop	di, cx
		jnz	checkEcho
stopLooking:
	;
	; Reset parser.
	;
		mov	es:[parser], offset ModemParseNoConnection
		clc		
		jmp	exit		
checkEcho:
	;
	; Check if response is an echo of the command sent to the modem.
	;
		call	ModemCheckCommandEcho
		clr	ax				; assume echo
		jz	keepLooking
unknown:
		mov	ax, MRC_UNKNOWN_RESPONSE
keepLooking:
		stc		
exit:
		mov	es:[result], ax
		.leave
		ret
ModemParseBasicResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemParseEscapeResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for echo of the command, OK or ERROR.
		The escape sequence is normally the first part of
		a two part sequence.  If OK is returned, then the
		second part will be sent.

CALLED BY:	ModemReceiveData
PASS:		es	= dgroup
RETURN:		carry clear for ModmeReceiveData to stop looking
		for properly formatted response.  (If OK received,
		  next command is sent.)
DESTROYED:	ax, cx, di, si

PSEUDO CODE/STRATEGY:
		compare response to OK
		if equal, and an escapeSecondCmd is specified, the second
		  command is sent; else store result as MRC_OK.
	          Both cases return carry clear to continue waiting.
		
		compare response to NO CARRIER
		if equal, will attempt to do same as OK (some cases this
		  is needed.)

		compare response to ERROR
		if equal, store result as MRC_ERROR, 
			reset parser to no connection because the basic
			response is for commands issued when there is no
				connection yet
			return carry clear		
		
		check if response is a command echo
		if yes, return carry set

		else store result as MRC_UNKNOWN_RESPONSE and return carry set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/23/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemParseEscapeResponse	proc	near
		uses	ds, bx
		.enter
	;
	; Check if response is "OK".
	;
		segmov	ds, cs, cx
		mov	cx, es:[responseSize]
		mov	di, offset es:[responseBuf]	; es:di = response

		cmp	cx, size responseOk
	LONG	jb	unknown				; what's less than OK?

		mov	ax, MRC_OK			; assume OK
		push	di, cx
		mov	si, offset responseOk		; ds:si = "OK"
		mov	cx, size responseOk
		repe	cmpsb
		pop	di, cx
		jnz	checkNoCarrier

	;
	; We have an OK (or NO CARRIER).  The escape sequence was
	; (relatively) successful.  Stop the timer and send the
	; second part of the command, if any.
	;
sendSecondCmd:
		push	ax
		clr	bx
		xchg	bx, es:[responseTimer]
		tst	bx
		jz	noTimerSet
		mov	ax, es:[responseTimerID]
		call	TimerStop
noTimerSet:
		pop	ax

		call	ModemSendEscapeSecondCmd
		jc	stopLooking			; no 2nd cmd or error
		jmp	keepLooking			; else sent correctly

	; Handle no carrier similarly to OK since it is necessary
	; sometimes when hanging up.
	;
checkNoCarrier:
		mov	cx, es:[responseSize]
		cmp	cx, size responseNoCarrier
		jb	checkError
		mov	di, offset es:[responseBuf]	; es:di = response
		call	ModemParseConnectResponse
		jc	checkError
		cmp	ax, MRC_NO_CARRIER
		je	sendSecondCmd

checkError:
	;
	; Check if response is "ERROR".
	;
		cmp	cx, size responseError
		jb	checkEcho			

		mov	ax, MRC_ERROR			; assume ERROR
		push	di, cx
		mov	si, offset responseError
		mov	cx, size responseError
		repe	cmpsb
		pop	di, cx
		jnz	checkEcho
stopLooking:
	;
	; Reset parser.
	;
		mov	es:[parser], offset ModemParseNoConnection
		clc		
		jmp	exit		
checkEcho:
	;
	; Check if response is an echo of the command sent to the modem.
	;
		call	ModemCheckCommandEcho
		clr	ax				; assume echo
		jz	keepLooking
unknown:
		mov	ax, MRC_UNKNOWN_RESPONSE
keepLooking:
		stc		
exit:
		mov	es:[result], ax
		.leave
		ret
ModemParseEscapeResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemParseDialResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the responses to dialing a phone number.
		(command echo, CONNECT, NO CARRIER, ERROR, NO DIALTONE,
		NO ANSWER, BUSY)  (if virtual serial: BLACKLISTED, DELAYED)

CALLED BY:	ModemReceiveData

PASS:		es	= dgroup

RETURN:		carry clear if no further responses are expected

DESTROYED:	ax, cx, di, si

PSEUDO CODE/STRATEGY:
		look for CONNECT, NO CARRIER, and ERROR first because 
			these are common responses to ATD and ATA commands
		if not found, then try to match the response to NO DIALTONE,
		NO ANSWER, BUSY
		ifdef virtual serial, try to match response to BLACKLISTED,
		DELAYED
		finally, check if response is a command echo
		if not, set result to MRC_UNKNOWN_RESPONSE
		return carry set
		Otherwise, carry is clear for everything except a command echo

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/21/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemParseDialResponse	proc	near
		uses	ds
		.enter
	;
	; Attempt to match response to a description of the 
	; connection status: CONNECT, NO CARRIER, ERROR.
	;
		segmov	ds, cs, cx
		mov	cx, es:[responseSize]
		mov	di, offset es:[responseBuf]
		call	ModemParseConnectResponse	; ax = ModemResultCode
	   LONG	jnc	done
	;
	; Attempt to match response to reasons while dialing failed:
	; BUSY, NO ANSWER, NO DIALTONE.  Process them in order of 
	; increasing length to stop comparing as soon as length of 
	; response is less than the response being compared against.
	;
		cmp	cx, size responseOk
		jb	checkOther

	; If we are aborting the dial and we get an OK, it is the equivalent
	; of a no carrier -- I don't know why the modem doesn't just give us
	; a no carrier.. anyway, check for that case and return NO_CARRIER
	; to the client.
	;
		test	es:[modemStatus], mask MS_ABORT_DIAL
		jz	skipOK
		mov	ax, MRC_NO_CARRIER
		push	di, cx
		mov	si, offset responseOk
		mov	cx, size responseOk
		repe	cmpsb
		pop	di, cx
		jz	stopLooking

skipOK:
		cmp	cx, size responseBusy
		jb	checkOther

		mov	ax, MRC_BUSY
		push	di, cx
		mov	si, offset responseBusy
		mov	cx, size responseBusy
		repe	cmpsb
		pop	di, cx
		jz	stopLooking

		cmp	cx, size responseNoAnswer
		jb	checkOther
		
		mov	ax, MRC_NO_ANSWER
		push	di, cx
		mov	si, offset responseNoAnswer
		mov	cx, size responseNoAnswer
		repe	cmpsb
		pop	di, cx
		jz	stopLooking

		cmp	cx, size responseNoDialtone
		jb	checkOther

		mov	ax, MRC_NO_DIALTONE		
		push	di, cx
		mov	si, offset responseNoDialtone
		mov	cx, size responseNoDialtone
		repe	cmpsb
		pop	di, cx
		jnz	checkOther
stopLooking:
		clc
		jmp	done
checkOther:		
	; 
	; This label defined to leave room for other responses 
	; that may be specific to a particular product.
	;

ifdef VIRTUAL_SERIAL
	;
	; Virtual serial may also return DELAYED or BLACKLISTED. 
	;
		cmp	cx, size responseDelayed
		jb	doneVSChecks

		mov	ax, MRC_DELAYED
		push	di, cx
		mov	si, offset responseDelayed
		mov	cx, size responseDelayed
		repe	cmpsb
		pop	di, cx
		jz	stopLooking

		cmp	cx, size responseBlacklisted
		jb	doneVSChecks

		mov	ax, MRC_BLACKLISTED
		push	di, cx
		mov	si, offset responseBlacklisted
		mov	cx, size responseBlacklisted
		repe	cmpsb
		pop	di, cx
		jz	stopLooking
doneVSChecks:
endif

	;
	; Check if response is a command echo.  If not, then the
	; response is a mystery.
	;
		call	ModemCheckCommandEcho
		clr	ax
		jz	keepLooking
		mov	ax, MRC_UNKNOWN_RESPONSE
keepLooking:
		stc
done:
		mov	es:[result], ax
		.leave
		ret
ModemParseDialResponse	endp

ifdef HANGUP_LOG

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemParseDialResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write every response to the dial status command to the log.
		When we get an OK, close the file and stop reading responses.

CALLED BY:	ModemReceiveData

PASS:		es	= dgroup

RETURN:		carry clear if no further responses are expected

DESTROYED:	ax, cx, di, si

PSEUDO CODE/STRATEGY:
		If response is OK, close log file and return carry clear
		If response is not command echo, write it to log file
		Return carry set

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	dhunter	10/12/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemParseDialStatusResponse	proc	near
		uses	ds, bx, dx
		.enter
	;
	; Check if response is "OK".
	;
		segmov	ds, cs, cx
		mov	cx, es:[responseSize]
		mov	di, offset es:[responseBuf]	; es:di = response

		cmp	cx, size responseOk
	LONG	jb	notOK

		mov	ax, MRC_OK			; assume OK
		push	di, cx
		mov	si, offset responseOk		; ds:si = "OK"
		mov	cx, size responseOk
		repe	cmpsb
		pop	di, cx
		jnz	notOK
	;
	; It's OK.  Close the file and return carry clear.
	;
		mov	es:[result], ax
		segmov	ds, es, ax
		mov	al, FILE_NO_ERRORS
		mov	bx, es:[logFile]
		mov	cx, 2
		add	di, size responseOk
		mov	dx, di
		inc	di
		mov	{byte}es:[di], C_LF
		call	FileWrite
		mov	al, FILE_NO_ERRORS
		call	FileClose
		clc
		jmp	done
	;
	; Check if it's a command echo.
	;
notOK:
		call	ModemCheckCommandEcho
		jz	doneMore
	;
	; It's another status line.  Write it to the log and return
	; carry set.
	;
		segmov	ds, es, ax
		mov	al, FILE_NO_ERRORS
		mov	bx, es:[logFile]
		mov	cx, es:[responseSize]
		mov	dx, offset es:[responseBuf]	; ds:dx = response
		mov	si, dx
		add	si, cx
		mov	{byte}ds:[si], C_LF
		inc	si
		inc	cx
		call	FileWrite
doneMore:
		stc
done:
		.leave
		ret
ModemParseDialStatusResponse	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemParseAnswerCallResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the response to answering an incoming call.
		(command echo, CONNECT, NO CARRIER, ERROR)

CALLED BY:	ModemReceiveData

PASS:		es	= dgroup

RETURN:		carry clear if no further responses are expected

DESTROYED:	ax, cx, di, si

PSEUDO CODE/STRATEGY:
		Look for CONNECT, ERROR, NO CARRIER
		if found, store result and return carry clear
		else, look for command echo
		if not found, response is unknown
		return carry set

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/21/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemParseAnswerCallResponse	proc	near
		uses	ds
		.enter
	;
	; Attempt to match response to a description of the connection
	; status: CONNECT, NO CARRIER, ERROR.
	;
		segmov	ds, cs, cx
		mov	cx, es:[responseSize]
		mov	di, offset es:[responseBuf]
		call	ModemParseConnectResponse	; ax = ModemResultCode
		jnc	done
	;
	; Check if response is a command echo.  If not, then response
	; is a mystery.  Store result, but keep looking for a response.
	;
		call	ModemCheckCommandEcho
		clr	ax
		jz	keepLooking
		mov	ax, MRC_UNKNOWN_RESPONSE
keepLooking:
		stc
done:
		mov	es:[result], ax
		.leave
		ret
ModemParseAnswerCallResponse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemParseConnectResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Match the response against those that describe the status
		of a connection: CONNECT, NO CARRIER or ERROR.

CALLED BY:	ModemParseDialResponse
		ModemParseAnswerCallResponse

PASS:		es:di	= response (in dgroup)
		cx	= size of response

RETURN:		carry set if no match
		else 
		ax 	= ModemResultCode		

DESTROYED:	si (ax if not returned)

PSEUDO CODE/STRATEGY:
		Check the responses in increasing order of length so
		the we can stop comparing as soon as the response
		is too short for a response, plus carry will be set
		for us by the cmp instruction.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/21/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemParseConnectResponse	proc	near
		uses	cx, di
		.enter

		cmp	cx, size responseError
		jb	exit

		mov	ax, MRC_ERROR
		push	di, cx
		mov	si, offset responseError
		mov	cx, size responseError
		repe	cmpsb
		pop	di, cx
		jz	found

		cmp	cx, size responseConnect
		jb	exit
	;
	; If connected, take state out of command mode.
	;
		mov	ax, MRC_CONNECT
		push	di, cx
		mov	si, offset responseConnect
		mov	cx, size responseConnect
		repe	cmpsb
		mov	si, di				
		pop	di, cx
		jnz	checkCarrier

		mov	di, si				
		call	ModemParseConnectBaud		; ax = MRC_CONNECT_*
		BitClr	es:[modemStatus], MS_COMMAND_MODE
		BitClr	es:[miscStatus], MSS_MODE_UNCERTAIN
		jmp	found
checkCarrier:
		cmp	cx, size responseNoCarrier
		jb	exit

		mov	ax, MRC_NO_CARRIER
		mov	si, offset responseNoCarrier
		mov	cx, size responseNoCarrier
		repe	cmpsb
		stc					; expect the worst...
		jnz	exit
found:
		clc
exit:
		.leave
		ret
ModemParseConnectResponse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemParseConnectBaud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the baud rate string after a CONNECT response, if
		any, to determine what baud rate the modem is using.

CALLED BY:	ModemParseNoConnection
		ModemParseConnectResponse

PASS:		es:di	= byte after CONNECT in response buffer
		ax	= MRC_CONNECT

RETURN:		ax = MRC_CONNECT_* where * is baud rate

DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
		if (responseSize - size of CONNECT) > 0 
			look for a space followed by an ascii decimal string
			convert ascii to integer 
			map to appropriate ModemResultCode
		else	
			return MRC_CONNECT 

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/21/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemParseConnectBaud	proc	near
	;
	; If there is no data after the CONNECT, then don't bother 
	; looking for a baud rate.
	;
		mov	cx, es:[responseSize]
		sub	cx, size responseConnect	; cx = remaining data
		jcxz	exit
	;
	; Advance pointer past the space and then convert the ascii number
	; to an unsigned integer.
	;
EC <		cmp	{byte}es:[di], C_SPACE			>
EC <		WARNING_NE UNUSUAL_CONNECT_RESPONSE_FORMAT	>
		inc	di
		dec	cx				; cx = # chars in number
		call	ModemBaudToUnsignedInt		; ax = number

	;
	; save the baud rate
	;
		mov	es:[baudRate], ax
		
	;
	; Map the number to a ModemResultCode.  
	;
		cmp	ax, 1200
		jne	try2400
		mov	ax, MRC_CONNECT_1200
		jmp	exit
try2400:
		cmp	ax, 2400
		jne	try4800
		mov	ax, MRC_CONNECT_2400
		jmp	exit
try4800:
		cmp	ax, 4800
		jne	try9600
		mov	ax, MRC_CONNECT_4800
		jmp	exit
try9600:
		cmp	ax, 9600
		jne	noBaud
		mov	ax, MRC_CONNECT_9600
		jmp	exit
noBaud:
		mov	ax, MRC_CONNECT
exit:
		ret
ModemParseConnectBaud	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemBaudToUnsignedInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an ASCII number to an unsigned value.

CALLED BY:	ModemParseConnectBaud

PASS:		es:di 	= ASCII string (not null-terminated)
		cx	= # of chars in ASCII string 

RETURN:		ax	= number

DESTROYED:	cx, dx, di 

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/21/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemBaudToUnsignedInt	proc	near
		
		clr	ax
digit:
		clr	dx
		mov	dl, es:[di]
		sub	dl, '0'
		jb	done
		cmp	dl, 9
		ja	done
		inc	di

		push	dx
		mov	dx, 10
		mul	dx
		pop	dx
		jc	overflow
		
		add	ax, dx
		jc	overflow
		loop	digit
done:
		ret
overflow:
EC <		WARNING MODEM_BAUD_RATE_TOO_BIG			>
		clr	ax				; use no baud rate
		jmp	done

ModemBaudToUnsignedInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemCheckCommandEcho
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the response is an echo of the command sent
		to the modem.

CALLED BY:	ModemParseBasicResponse
		ModemParseDialResponse
		ModemParseAnswerCallResponse

PASS:		es:di	= response 

RETURN:		Z flag set if response is a command echo

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		No modem responses begin with "AT" so look
		for these at the start of the response.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/21/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemCheckCommandEcho	proc	near
		
	;
	; Look for 'AT' as first two characters of response.
	;
		mov	ax, es:[di]		; AL = 1st char, AH = 2nd char
		cmp	al, 'A'				 
		jne	checkEsc
		cmp	ah, 'T'			; Z flag set if equal
		jmp	exit
checkEsc:
	;
	; Modem might also be echoing '+++' escape sequence.  No normal
	; responses begin with '+' so checking first character is enough.
	;
		cmp	al, '+'			; Z flag set if equal
exit:
		ret
ModemCheckCommandEcho	endp

CommonCode	ends







