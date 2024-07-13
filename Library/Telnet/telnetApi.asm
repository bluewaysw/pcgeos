COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS (Network Extensions)
MODULE:		TELNET library
FILE:		telnetApi.asm

AUTHOR:		Simon Auyeung, Jul  5, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------
    EXT TelnetCreate		Create telnet control information

    EXT TelnetConnect		Make a telnet connection

    EXT TelnetClose		Close and clean up a telnet connection

    EXT TelnetSendCommand	Send a command and associated
				data/negotiation to an established TELNET
				connection. It will block until it
				successfully handles the command.

    EXT TelnetSend		Send a stream of data to TELNET connection

    EXT TelnetRecv		Receive input data from a TELNET
				connection. If the function returns with no
				error, the data returned can be interpreted
				differently. All data returned is of one
				type even though more data have been
				received. So, the caller should not assume
				if all data have been arrived.

    EXT TelnetSetStatus		Set the status or behavior of a telnet
				connection.

    EXT TelnetInterrupt		Interrupt a telnet connection operation

    EXT TelnetSendOption	Initiate negotiation of an option and
				enable/disable options accordingly

    EXT TelnetSendSuboption	Send out a suboption (option subcommand
				data) to a remote connection. It simply
				encapsulates the data in a suboption packet
				and sends it. The routine overrides any
				option currently disabled.

    EXT TelnetFlushSendQueue	Actually send the buffered data in send
				queue to remote connection

    EXT TelnetResetSendQueue	Reset the send queue and remove all pending
				data from send queue so that they are not
				sent.

    EXT TelnetResetRecvQueue	Reset the receive and remove all data in
				receive queue. It ignores any stored
				incomplete option negotiation and command.

    EXT TelnetEnableOptions	Enable Telnet options and acknowledge them
				upon request

    EXT TelnetDisableOptions	Disable Telnet options and reject them upon
				request

    EXT TelnetSetOperationMode	Set the operation mode

    EXT TelnetSynch		Initiate a Synch signal. It blocks until it
				has been synchronized up.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon		7/ 5/95   	Initial revision


DESCRIPTION:
	This file contains API routines for Telnet library.
		

	$Id: telnetApi.asm,v 1.1 97/04/07 11:16:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitExitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create telnet control information

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		carry set if error
			ax	= TE_INSUFFICIENT_MEMORY
		carry clear if no error
			ax	= TE_NORMAL
			bx	= TelnetConnectionID		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Allocate and initialize TelnetInfo;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetCreate	proc	far
		ForceRef	TelnetCreate
		uses	ds, si, cx
		.enter

		call	TelnetControlStartWrite	; ds = TelnetControl segment
	;
	; Create a socket
	;
		mov	ax, SDT_STREAM
		call	SocketCreate		; bx = Socket
		jc	error
	;
	; Allocate space for TelnetInfo
	;
		clr	al			; no ObjChunkFlags
		mov	cx, size TelnetInfo
		call	LMemAlloc		; ax = chunk
		jc	cleanSocket
	;
	; Initialize TelnetInfo
	;
		mov	si, ax
		mov	si, ds:[si]
		mov	ds:[si].TI_socket, bx
		mov_tr	bx, ax			; bx = TelnetConnectionID
		call	TelnetResetInfo
EC <		call	TelnetAddConnection				>
		mov	ax, TE_NORMAL
		clc
		jmp	done

cleanSocket:
EC <		Assert	socket	bx					>
		call	SocketClose
		
error:
		mov	ax, TE_INSUFFICIENT_MEMORY
		stc

done:
		call	TelnetControlEndWrite

		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret
TelnetCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a telnet connection

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
		dl	= TelnetOperationMode
		bp	= timeout (in ticks) to wait for response from
			connection
		ds:si	= fptr to SocketAddress
			SA_port		= can be specified to
					TELNET_DEFAULT_PORT if default TELNET
					port should be used. 
			SA_domain	= "TCPIP"
			SA_domainSize	= 5 for SBCS
					  10 for DBCS
			SA_addressSize and SA_address filled with target IP
			address information.

		es:di	= fptr to array of TelnetOptionDescArray
		
RETURN:		carry set if error
			ax	= TelnetError
	
		carry clear if no error
			ax	= TE_NORMAL
			bx	= TelnetConnectionID
			dl	= TelnetOperationMode -- the mode of
				operation that has been negotiated
			es:di	= fptr to same array of TelnetOptionDescArray.
				TOD_flags will indicate whether the options
				are enabled or disabled

DESTROYED:	nothing
SIDE EFFECTS:	
	*** Notes ***

	* TelnetOperationMode overrides TelnetOptionStatus. In order to set
	the operation mode, some options specified by TelnetOptionStatus may
	be enabled or disabled, especially SUPPRESS_GO_AHEAD option.

	* If the caller is not satisfied with the negotiation result, it
	should actively all TelnetClose to terminate the connection.

        * Telnet connections cannot be re-used. That means once you have
        called TelnetConnect on a TelnetConnectionID, regardless of
        connection success or failure, it should be restarted by calling
        TelnetClose and then TelnetCreate again for subsequent
        connections. 

PSEUDO CODE/STRATEGY:
	SocketConnect;
	Allocate space for term type, if any;
	Allocate space for cache;
	Update TelnetInfo;
	Start initial option negotiation;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	ERROR_CHECK
TCPIPString	TCHAR	"TCPIP"
endif

TelnetConnect	proc	far
		timeout		local	word			push	bp
		id		local	TelnetConnectionID	push	bx
		optDesc		local	fptr.TelnetOptDescArray	push	es, di
		sockAddr	local	fptr.SocketAddress	push	ds, si
		localOpt	local	TelnetOptionStatus
		remoteOpt	local	TelnetOptionStatus
		termTypePtr	local	fptr.char
		opMode		local	byte
	
		ForceRef	TelnetConnect
		ForceRef	timeout
		ForceRef	id
		ForceRef	termTypePtr
		ForceRef	optDesc
		ForceRef	localOpt
		ForceRef	remoteOpt
		ForceRef	sockAddr
	
		uses	ds
		.enter
EC <		Assert_fptrXIP	esdi					>
EC <		Assert_fptrXIP	dssi					>
EC <		Assert_etype	dl, TelnetOperationMode			>
EC <		push	ds						>
EC <		call	TelnetControlStartRead	; ds = TelnetControl seg>
EC <		Assert_TelnetConnectionID	bx			>
EC <		call	TelnetControlEndRead				>
EC <		pop	ds						>
EC <		push	ds, es, si, di, ax, cx				>
EC <		cmp	ds:[si].SA_domainSize, size TCPIPString		>
EC <		ERROR_NE TELNET_CREATE_INCORRECT_SOCKET_ADDRESS_DOMAIN_SIZE>
EC <		segmov	es, cs, ax					>
EC <		mov	di, offset TCPIPString				>
EC <		lds	si, ds:[si].SA_domain	; dssi <- string	>
EC <		mov	cx, size TCPIPString				>
if	DBCS_PCGEOS
EC <		shr	cx						>
endif
EC <		call	LocalCmpStrings		; ax destroyed		>
EC <		ERROR_NZ TELNET_CREATE_INCORRECT_SOCKET_ADDRESS_DOMAIN	>
EC <		pop	ds, es, si, di, ax, cx				>
		CheckHack	<offset TS_OPERATION_MODE eq 0>
		mov	ss:[opMode], dl		; update TelnetOperationMode
	;
	; Connect socket
	;
		call	TelnetConnectSocket	; carry set if error
		jc	exit
	;
	; Parse options and update TelnetInfo
	;
		call	TelnetControlStartWrite
		call	TelnetConnectParseOptions; carry set if error
		jc	cleanupSocket
	;
	; Allocate space for cache
	;
		call	TelnetMakeCache		; carry set if error
		jc	cleanupOptions
	;
	; Negotiate initial telnet options
	;
		call	TelnetNegotiateInitOpt	; carry set if error
		jc	cleanupCache
		mov	ax, TE_NORMAL
		jmp	done

cleanupCache:
		call	TelnetCleanupCache

cleanupOptions:
		call	TelnetCleanupOptions
		call	TelnetResetInfo

cleanupSocket:
		call	TelnetDisconnectSocket
		stc				; indicate error
		
done:
		call	TelnetControlEndWrite

exit:
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret
TelnetConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close and clean up a telnet connection

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetClose	proc	far
		ForceRef	TelnetClose
		uses	ds
		.enter

		call	TelnetControlStartWrite	; ds = TelnetControl segment
EC <		Assert	TelnetConnectionID	bx			>
	;
	; Disconnect connection, if any
	;
		call	TelnetDisconnectSocket
	;
	; Clean up socket
	;
		push	bx
		mov	si, bx
		mov	si, ds:[si]
		mov	bx, ds:[si].TI_socket
EC <		Assert	socket	bx					>
		call	SocketClose
		pop	bx
	;
	; Clean up internal data
	;
		call	TelnetCleanupCache
		call	TelnetCleanupOptions
EC <		call	TelnetRemoveConnection				>
	;
	; Remove control data for this connection
	;
		mov	ax, bx
		call	LMemFree

		call	TelnetControlEndWrite
	;
	; If we cannot disconnect, we can do nothing. So, we just cleaned up
	; internal data and return no error;
	;
		clc
		mov	ax, TE_NORMAL
		
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret
TelnetClose	endp

InitExitCode	ends
		
ApiCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a command and associated data/negotiation to an
		established TELNET connection. It will block until it
		successfully handles the command.   

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
		al	= TelnetCommand

RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	*** Note ***

	* Some commands may require system option negotitation.

	if (internal error) {
		return internal error;
	} else {
		Send TELNET command;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendCommand	proc	far
		ForceRef	TelnetSendCommand
	cmdToSend	local	TelnetCommand
		uses	ds, si, bx
		.enter
	
		call	TelnetControlStartRead	; ds <- TelnetControl sptr
EC <		Assert_TelnetConnectionID	bx			>
EC <		Assert_TelnetCommand	al				>
		mov	ss:[cmdToSend], al
		mov	si, bx
		mov	si, ds:[si]		; dssi <- fptr to TelnetInfo
	;
	; If there is already error, return error
	;
		TelnetCheckIntError		; carry set if error
						; ax <- TelnetError
		jc	done
		mov	bx, ds:[si].TI_socket	; bx <- socket to send
	;
	; Perform command specific actions.
	;
		mov	al, ss:[cmdToSend]	; al <- TelnetCommand
		call	TelnetSendCommandSocket	; ax <- TelnetError
						; carry set if error
done:
		call	TelnetControlEndRead
		
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret
TelnetSendCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a stream of data to TELNET connection

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
		ds:si	= fptr to data to send
		cx	= size of data (in bytes)
RETURN:		carry set if error
			ax	= TE_INSUFFICIENT_MEMORY
				  TE_CONNECTION_FAILED
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	
	*** Notes ***

	If a TelnetCommand should be sent, use TelnetSendCommand.
	Any data byte in the data stream containing TC_IAC byte
	(Telnet command denoter) will be sent out as two consecutive
	TC_IAC bytes to be interpreted as data as specified in the TELNET
	protocol.  
	
PSEUDO CODE/STRATEGY:
	If (internal error) {
		return error;
	} else {
		Send data;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSend	proc	far
		ForceRef	TelnetSend
	dataPtr	local	fptr	push	ds, si
		uses	bx, ds, si
		.enter

EC <		Assert_buffer	dssi, cx				>
		call	TelnetControlStartRead	; ds <- TelnetControl segment
EC <		Assert_TelnetConnectionID	bx			>
		mov	si, bx
		mov	si, ds:[si]		; dssi <- TelnetInfo
	;
	; If there is already error, return error
	;
		TelnetCheckIntError		; carry set if error
						; ax <- TelnetError
		jc	done
	;
	; AX == 0 (no SocketSendFlags). The TELNET protocol requires a IAC
	; data byte must be sent as two consecutive IAC bytes. Scanning a
	; buffer may take some time. To optimize for connection sending data
	; byte by byte, there is a routine TelnetSendByte which does simple
	; checking on the byte and then send it.
	;
		CheckHack <TE_NORMAL eq 0>
		mov	bx, ds:[si].TI_socket	; bx <- Socket
		movdw	dssi, ss:[dataPtr]
		cmp	cx, 1			; just 1 byte of data to send?
		je	sendOneByte
		call	TelnetSendBuffer	; ax <- TelnetError
						; carry set if error
		jmp	done
	
sendOneByte:
		call	TelnetSendByte		; ax <- TelnetError
						; carry set if error
done:
		call	TelnetControlEndRead
	
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret
TelnetSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive input data from a TELNET connection. If the
		function returns with no error, the data returned can be
		interpreted differently. All data returned is of one type
		even though more data have been received. So, the caller
		should not assume if all data have been arrived.

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
		es:di	= fptr to buffer storing the data read
		cx	= size of buffer (in bytes) or number of bytes needed
			to read
		bp	= timeout for returning if no data available for
			reading. 
			
RETURN:		carry set if error
			ax	= TE_TIMED_OUT
				  TE_CONNECTION_IDLE_TIMEOUT
				  TE_LINK_FAILED
				  TE_CONNECTION_FAILED
				  TE_CONNECTION_CLOSED

			When there is no data, TelnetError = TE_TIMEOUT

		carry set if no error
			ax	= TE_NORMAL
			bx	= TelnetDataType
			
			TelnetDataType =

			TDT_DATA:			
			
				A stream of data should be interpreted as
				part of the normal data stream.
	
				es:di	= fptr to passed buffer filled with
					data (if cx is non-zero) 
				cx	= size of data returned (in bytes)

			TDT_NOTIFICATION:

				Notification about any change of behavior
				that application should be aware of:

				dx	= TelnetNotificationType
				es:di	= fptr to data associated with
					notification 
				cx	= size of data returned (in bytes)

			TDT_OPTION:

				dx	= TelnetOptionID
				bp	= TelnetOptionRequest

			TDT_SUBOPTION:

				dx	= TelnetOptionID
				es:di	= fptr to data contained in
					suboption. 
				cx	= size of data returned (in bytes)

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetRecv	proc	far
		ForceRef	TelnetRecv	
		uses	bp
		.enter	
EC <		Assert_buffer	esdi, cx				>
		call	TelnetControlStartWrite	; ds <- TelnetControl segment
EC <		Assert_TelnetConnectionID	bx			>
	;
	; It only retrieves data bytes now, but no control data.
	;
		call	TelnetRecvLow		; carry set if error
						; ax <- TelnetError
						; cx <- size of data
						; bx <- TelnetDataType
		call	TelnetControlEndWrite
		
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret
TelnetRecv	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSetStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the status or behavior of a telnet connection.

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
RETURN:		ax	= TelnetSetStatusCommand
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	3/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSetStatus	proc	far
		uses	ds, si
		.enter
EC <		Assert_etype	ax, TelnetSetStatusCommand		>
	;
	; Currently, we only support resetting Synch signal, which resumes
	; output.
	;
		cmp	ax, TSSC_RESET_SYNCH
		jne	done
	;
	; Reset the flag that discard otput
	;
		call	TelnetControlStartRead	; ds <- sptr of TelnetControl
EC <		Assert_TelnetConnectionID	bx			>
		mov	si, ds:[bx]		; ds:si <- TelnetInfo
		BitClr	ds:[si].TI_status, TS_SYNCH_MODE
		call	TelnetControlEndRead	
	
done:
		.leave
		ret
TelnetSetStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt a telnet connection operation

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetInterrupt	proc	far
		uses	bx, ds, si
		.enter

		call	TelnetControlStartWrite	; ds = TelnetControl segment
EC <		Assert	TelnetConnectionID	bx			>
	;
	; Get the socket and interrupt. It is the caller's
	; responsibility to make sure the socket is not closed at this
	; point.
	;
		mov	si, bx
		mov	si, ds:[si]		; dssi = TelnetInfo
		mov	bx, ds:[si].TI_socket
		call	SocketInterrupt		; carry set if error
		jnc	success
EC <		pushf							>
EC <		Assert	inList ax, <SE_SOCKET_NOT_INTERRUPTIBLE		>>
EC <		popf							>

notInterruptible::
		mov	ax, TE_NOT_INTERRUPTIBLE
		stc
		jmp	done

success:
		mov	ax, TE_NORMAL
		
done:
		call	TelnetControlEndWrite

		.leave
		ret
TelnetInterrupt	endp

if 0
	;------------------------------------------------------------
	;
	; The following functions will be supported in the future.
	;
	;------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate negotiation of an option and enable/disable options
		accordingly 

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
		al	= TelnetOptionRequest
		cl	= TelnetOptionID or option IDs

RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	
	*** Note ***

	* If cx contains recognized TelnetOptionID,

		case TOR_WILL:
			Enable the corresponding option;
			break;
		
		case TOR_WONT:
			Disbale the corresponding option;
			break;
		
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendOption	proc	far
		ForceRef	TelnetSendOption
		.enter
		.leave
		ret
TelnetSendOption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendSuboption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a suboption (option subcommand data) to a remote
		connection. It simply encapsulates the data in a
		suboption packet and sends it. The routine overrides
		any option currently disabled.   
		
CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
		al	= TelnetOptionID
		ds:si	= fptr to suboption data to send
		cx	= size (#bytes) of suboption data to send
RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	*** NOTE ***

	* If the option is supported and does not take suboption command, it
	will simply ignore it. For example, if TelnetOptionID = TO_ECHO, it
	will ignore it because this option does not take subcommand.

	* The suboption sent does not constitute whether the option is
	enabled	or disabled.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendSuboption	proc	far
		ForceRef	TelnetSendSuboption
		.enter
		.leave
		ret
TelnetSendSuboption	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetFlushSendQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually send the buffered data in send queue to
		remote connection   

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetFlushSendQueue	proc	far
		ForceRef	TelnetFlushSendQueue	
		.enter
		.leave
		ret
TelnetFlushSendQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetResetSendQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the send queue and remove all pending data from
		send queue so that they are not sent.

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetResetSendQueue	proc	far
		ForceRef	TelnetResetSendQueue
		.enter
		.leave
		ret
TelnetResetSendQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetResetRecvQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the receive and remove all data in receive queue. It
		ignores any stored incomplete option negotiation and command. 

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetResetRecvQueue	proc	far
		ForceRef	TelnetResetRecvQueue
		.enter
		.leave
		ret
TelnetResetRecvQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetEnableOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable Telnet options and acknowledge them upon request

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
		ax	= TelnetOptionStatus
RETURN:		carry set if error
			ax	= TelnetError
				= TE_REQUEST_FAIL
		carry clear if no error
			ax	= TE_NORMAL
			cx	= TelnetOptionStatus (indicate the current
				option status after negotiation)
DESTROYED:	nothing
SIDE EFFECTS:	
	*** Note ***

	Some options can be enabled/disabled because of the change of
	operation mode, especially SUPPRESS_GO_AHEAD. 

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetEnableOptions	proc	far
		ForceRef	TelnetEnableOptions
		.enter
		.leave
		ret
TelnetEnableOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetDisableOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable Telnet options and reject them upon request

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetDisableOptions	proc	far
		ForceRef	TelnetDisableOptions	
		.enter
		.leave
		ret
TelnetDisableOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSetOperationMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the operation mode 

CALLED BY:	EXTERNAL
PASS:		dl	= TelnetOperationMode
RETURN:		carry set if error
			ax	= TelnetError
				= TE_REQUEST_FAIL if the requested mode
				cannot be set
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	


PSEUDO CODE/STRATEGY:
	Negotiate for the new mode.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSetOperationMode	proc	far
		ForceRef	TelnetSetOperationMode	
		.enter
		.leave
		ret
TelnetSetOperationMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSynch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate a Synch signal. It blocks until it has been
		synchronized up. 

CALLED BY:	EXTERNAL
PASS:		bx	= TelnetConnectionID
RETURN:		carry set if error
			ax	= TelnetError
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSynch	proc	far
		ForceRef	TelnetSynch	
		.enter
		.leave
		ret
TelnetSynch	endp
endif	; if 0
		
ApiCode		ends
