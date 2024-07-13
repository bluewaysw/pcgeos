COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS (Network Extensions)
MODULE:		TELNET Library
FILE:		telnetParser.asm

AUTHOR:		Simon Auyeung, Aug  1, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------
    INT TelnetParseInput	Parse the input data for control data

    INT TelnetGroundStateHandler
				Handle a character input at TST_GROUND
				state. This is the fresh state.

    INT TelnetControlReadyStateHandler
				Handle a character input at
				TST_CONTROL_READY state. This state is
				reached after getting the first IAC byte.

    INT TelnetOptionStartStateHandler
				Handle a character input in
				TST_OPTION_START state. This stage is
				reached when TelnetOptionRequest is
				requested.

    INT TelnetSuboptionStartStateHandler
				Handle a character input in
				TST_SUBOPTION_START state. This stage is
				reached when suboption negotiation starts

    INT TelnetSuboptionReadStateHandler
				Handle a character input in
				TST_SUBOPTION_READ state. This stage is
				reached when suboption data should be read

    INT TelnetSuboptionEndReadyStateHandler
				Handle a character input in
				TST_SUBOPTION_END_READY state. This stage
				is reached when suboption data is being
				read and a IAC byte is encountered. We need
				to wait for the next byte to determine
				whether this is a data byte or an escape
				byte.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon		8/ 1/95   	Initial revision


DESCRIPTION:
	This file contains routines to parse data according to TELNET
	protocol. 
		

	$Id: telnetParser.asm,v 1.1 97/04/07 11:16:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetParseInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the input data for control data

CALLED BY:	(INTERNAL) TelnetRecvFromCache, TelnetRecvLow
PASS:		es:di	= fptr to buffer
		cx	= size of data
		bx	= TelnetConnectionID
		ds	= TelnetControl segment
RETURN:		carry clear if no error
		bx	= TelnetDataType
		ax	= TE_NORMAL
		cx	= size of data actually returned to TelnetRecv
		es:di	= fptr to byte past the last byte parsed

		TelnetDataType =

			TDT_DATA:			
				nothing

			TDT_NOTIFICATION:
				dx	= TelnetNotificationType

			TDT_OPTION:
				dx	= TelnetOptionID
				bp	= TelnetOptionRequest

			TDT_SUBOPTION:
				dx	= TelnetOptionID

		carry set if error
		ax	= TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	TelnetInfo tinfo;
	TelnetStateType state;
	char cur_char;
	returnIndex = 0;
	index = 0;

	Deref TelnetInfo;
	state = tinfo.TI_state;
	while (buffer_size - index > 0) {
		cur_char = inputData[index++]
		switch (state) {
		case TST_GROUND:
			TelnetGroundStateHandler(cur_char, inputData,
				returnIndex, tinfo);
			break;
		case TST_CONTROL_READY:
			TelnetControlReadyStateHandler(cur_char, inputData,
				returnIndex, tinfo);
			break;
		case TST_OPTION_START:
		case TST_SUBOPTION_START:
		case TST_SUBOPTION_READ:
		case TST_SUBOPTION_END_READY:
		case TST_EXEC_COMMAND:
		default:
			/* unimplemented */
			break;
		}
	}
	Save state to TelnetInfo;
	Set up params to return;
	Unlock TelnetInfo;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetParseInput	proc	near
		uses	dx, si, bp
		.enter
EC <		tst	cx						>
EC <		ERROR_Z TELNET_PARSE_EMPTY_INPUT_DATA			>
EC <		Assert_buffer	esdi, cx				>
		mov	si, bx			; *ds:si <- TelnetInfo
		mov	si, ds:[si]		; ds:si <- TelnetInfo
		mov	bx, ds:[si].TI_state	; bx <- TelnetStateType
		mov	bp, di			; bp <- nptr of begin of buf
		mov	dx, si			; ds:dx <- TelnetInfo
		clr	ah
		push	di			; save buffer begin ptr
	;
	; ES:DI <- current character, ES:BP <- current space to write char
	; DS:DX <- TelnetInfo
	; BX <- current state, CX <- size of buffer, AL <- current char
	;
parseLoop:
EC <		Assert_fptr	esdi					>
		mov	al, es:[di]		; al <- current byte (char)
		mov	si, offset StateHandlerOffsetTable
EC <		Assert_etype	bx, TelnetStateType			>
		add	si, bx			; *cs:si <- entry of
						; StateHandlerOffsetTable 
		call	cs:[si]			; carry set if return data
						; immediately 
		inc	di			; advance di
		jc	parseLoopEnd
		loop	parseLoop
	;
	; Done parsing the data. Set up the params
	;
parseLoopEnd:
		mov_tr	ax, di			; save di
		pop	di			; di <- nptr to begin of buf
		sub	bp, di			; bp <- # chars returned
						; (end - start)
		mov	cx, bp			; cx <- # chars returned
		mov_tr	di, ax			; esdi = past last byte parsed
	;
	; Store state info
	;
		mov	si, dx			; ds:si <- fptr to TelnetInfo
		mov	ds:[si].TI_state, bx
		jcxz	checkError
		clc
		mov	ax, TE_NORMAL		; no err then if data returned
		
done:
		mov	bx, TDT_DATA

		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret

checkError:
	;
	; No data. If there is internal error, return it.
	;
		TelnetCheckIntError		; carry set if internal error
						; ax <- TelnetError
		jmp	done
TelnetParseInput	endp

CheckHack<segment TelnetParseInput eq segment TelnetGroundStateHandler>
CheckHack<segment TelnetParseInput eq segment TelnetControlReadyStateHandler>
CheckHack<segment TelnetParseInput eq segment TelnetOptionStartStateHandler>
CheckHack<segment TelnetParseInput eq segment TelnetSuboptionStartStateHandler>
CheckHack<segment TelnetParseInput eq segment TelnetSuboptionReadStateHandler>
CheckHack<segment TelnetParseInput eq segment TelnetSuboptionEndReadyStateHandler>

StateHandlerOffsetTable	nptr \
	offset	TelnetGroundStateHandler,
	offset	TelnetControlReadyStateHandler,
	offset	TelnetOptionStartStateHandler,
	offset	TelnetSuboptionStartStateHandler,
	offset	TelnetSuboptionReadStateHandler,
	offset	TelnetSuboptionEndReadyStateHandler


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetGroundStateHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a character input at TST_GROUND state. This is the
		fresh state.

CALLED BY:	TelnetParseInput
PASS:		al	= char
		es:bp	= fptr to buffer to store any char
		bx	= TelnetStateType
		ds:dx	= fptr to TelnetInfo
RETURN:		bx	= TelnetStateType (next state)
		carry set if TelnetDataType changes signaling data should be
			returned immediately
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	switch (cur_char) {
	case TC_IAC:
		/* got first IAC byte */
		state = TST_CONTROL_READY;
		break;
	default:
		inputData[returnIndex++] = cur_char;
	}
	break;
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetGroundStateHandler	proc	near
		.enter
	
		cmp	al, TC_IAC
		jne	notIAC
		mov	bx, TST_CONTROL_READY
		jmp	done
	;
	; Copy the data to output buffer
	;
notIAC:
		call	TelnetWriteCharRecvBuf	; bp updated
done:
		clc				; continue parsing
	
		.leave
		ret
TelnetGroundStateHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetControlReadyStateHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a character input at TST_CONTROL_READY state. This
		state is reached after getting the first IAC byte.

CALLED BY:	TelnetParseInput
PASS:		al	= char
		es:bp	= fptr to buffer to store any char
		bx	= TelnetStateType
		ds:dx	= fptr to TelnetInfo 
RETURN:		bx	= TelnetStateType (next state)
		carry set if TelnetDataType changes signaling data should be
			returned immediately
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	switch (cur_char) {
	case TC_IAC:
		/* It's a data byte */
		inputData[returnIndex++] = cur_char;
		state = TST_GROUND;
		break;
	case TC_WILL:
	case TC_WONT:
	case TC_DO:
	case TC_DONT:
		/* it's an option */
		tinfo.TI_currentRequest = cur_char;
		state = TST_OPTION_START;
		break;
	default:
		/* Got a command */
		tinfo.TI_currentCommand = cur_char;
		TelnetExecCommand(cur_char);
		state = TST_GROUND;
	}
	break;


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetControlReadyStateHandler	proc	near
		uses	si
		.enter

		CheckHack	<TC_IAC eq 255>
		cmp	al, TC_IAC
		jne	gotCommand
		call 	TelnetWriteCharRecvBuf	; if double IAC->1 IAC byte
		mov	bx, TST_GROUND		; back to ground state
		jmp	contRead

gotCommand:
	;
	; It must one of TelnetCommands
	;
		mov	si, dx			; ds:si <- TelnetInfo
		mov	ds:[si].TI_currentCommand, al
		CheckHack	<TOR_DONT eq 254>
		cmp	al, TOR_WILL
		jb	checkSuboption
EC <		Assert_fptr	dsdx					>
		mov	bx, TST_OPTION_START
		jmp	contRead
		
checkSuboption:
	;
	; Check if it is a suboption. If not, then exec command.
	;
		cmp	al, TC_SB
		je	suboption
		call	TelnetExecIncomingCommand; carry set if return data
						; immediately 
		jc	done
	
contRead:
		clc
done:
		.leave
		ret
	
suboption:
%out	~~~~ TelnetControlReadyStateHandler: Only send out suboption data, but not receive it ~~~~
		mov	bx, TST_SUBOPTION_START
		jmp	contRead
TelnetControlReadyStateHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetOptionStartStateHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a character input in TST_OPTION_START state. This
		stage is reached when TelnetOptionRequest is requested.

CALLED BY:	TelnetParseInput
PASS:		al	= char
		es:bp	= fptr to buffer to store any char
		bx	= TelnetStateType
		ds:dx	= fptr to TelnetInfo 
RETURN:		bx	= TelnetStateType (next state)
		carry set if TelnetDataType changes signaling data should be
			returned immediately
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	tinfo.TI_currentOption = cur_char;
	TelnetHandleOption();
	state = TST_GROUND;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetOptionStartStateHandler	proc	near
		uses	ax, si
		.enter
	
		mov	si, dx
	;
	; If there is internal error, don't handle option
	;
		push	ax
		TelnetCheckIntError		; carry set if error
						; ax <- TelnetError
		pop	ax
		jc	retNoErr
		mov	ds:[si].TI_currentOption, al
		call	TelnetHandleIncomingOption
						; carry set if TelnetError
						; ax <- TE_NORMAL if no sys err
		jnc	checkNotification
EC <		WARNING_C TELNET_CANNOT_SEND_OPTION			>
		mov	ds:[si].TI_error, ax
		jmp	done

checkNotification:
		call	TelnetCheckNotification	; carry set if notification
		jmp	done

retNoErr:
		clc				; don't return data yet, wait
						; to see if there is any more
						; to parse
done:
		mov	bx, TST_GROUND
		.leave
		ret
TelnetOptionStartStateHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSuboptionStartStateHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a character input in TST_SUBOPTION_START state. This
		stage is reached when suboption negotiation starts

CALLED BY:	TelnetParseInput
PASS:		al	= character
		es:bp	= fptr to buffer to store any char
		bx	= TelnetStateType
		ds:dx	= fptr to TelnetInfo 
RETURN:		bx	= TelnetStateType (next state)
		carry set if TelnetDataType changes signaling data should be
			returned immediately
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSuboptionStartStateHandler	proc	near
		uses	si
		.enter
		mov	si, dx			; ds:si <- TelnetInfo
EC <		push	cx						>
EC <		mov	cl, al						>
EC <		call	TelnetOptionIDToMask	; carry set if option not>
						; supported
						; cx <- mask of
						; TelnetOptionStatus bit 
EC <		WARNING_C TELNET_RECV_UNSUPPORTED_SUBOPTION_OPTION_ID	>
EC <		TelnetIsOptionEnabled	cx, LOCAL; ZF set if not enabled>
EC <		ERROR_Z TELNET_RECV_DISABLED_SUBOPTION			>
EC <		pop	cx						>
		mov	ds:[si].TI_currentOption, al
		mov	bx, TST_SUBOPTION_READ	
		clc
		.leave
		ret
TelnetSuboptionStartStateHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSuboptionReadStateHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a character input in TST_SUBOPTION_READ state. This
		stage is reached when suboption data should be read

CALLED BY:	TelnetParseInput
PASS:		al	= character
		es:bp	= fptr to buffer to store any char
		bx	= TelnetStateType
		ds:dx	= fptr to TelnetInfo 
RETURN:		bx	= TelnetStateType (next state)
		carry set if TelnetDataType changes signaling data should be
			returned immediately
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSuboptionReadStateHandler	proc	near
		uses	si
		.enter
		cmp	al, TC_IAC
		je	suboptionEnd
		mov	si, dx			; ds:si <- fptr to TelnetInfo
	;
	; Right now, we only support suboption of Terminal type. Other
	; options and bytes before SE will be ignored.
	;
		mov	bx, TST_SUBOPTION_READ
		cmp	ds:[si].TI_currentOption, TOID_TERMINAL_TYPE
		jne	noErr
		call	TelnetTermTypeParseSuboption
						; bx <- TelnetStateType
noErr:
		clc

		.leave
		ret

suboptionEnd:
	;
	; Ready to wait for SE byte or another IAC byte
	;
		mov	bx, TST_SUBOPTION_END_READY
		jmp	noErr
TelnetSuboptionReadStateHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSuboptionEndReadyStateHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a character input in TST_SUBOPTION_END_READY
		state. This stage is reached when suboption data is being
		read and a IAC byte is encountered. We need to wait for the
		next byte to determine whether this is a data byte or an
		escape byte. 

CALLED BY:	TelnetParseInput
PASS:		al	= character
		es:bp	= fptr to buffer to store any char
		bx	= TelnetStateType
		ds:dx	= fptr to TelnetInfo 
RETURN:		bx	= TelnetStateType (next state)
		carry set if TelnetDataType changes signaling data should be
			returned immediately
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSuboptionEndReadyStateHandler	proc	near
		uses	si, ax
		.enter

		mov	si, dx			; ds:si<- fptr to TelnetInfo
		cmp	al, TC_IAC
		je	foundIACDataByte
		cmp	al, TC_SE
		je	processSuboption
EC <		WARNING TELNET_SUBOPTION_EXPECTS_SE			>
		clc				; unexpected TelnetCommand
		mov	bx, TST_GROUND		; reset itself
		mov	ds:[si].TI_termTypeState, TTSST_NONE
	
done:
		.leave
		ret

foundIACDataByte:
		call	TelnetTermTypeParseSuboption
						; bx <- TelnetStateType
		clc				; no problem
		jmp	done

processSuboption:
		call	TelnetHandleParsedSuboption
						; carry set if error sending
						; ax <- TelnetError	
		jnc	suboptProcessed
		mov	ds:[si].TI_error, ax
		clc
		
suboptProcessed:
		mov	bx, TST_GROUND
		jmp	done
TelnetSuboptionEndReadyStateHandler	endp

CommonCode	ends
