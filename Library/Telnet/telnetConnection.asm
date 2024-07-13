COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS (Network Extensions)
MODULE:		TELNET library
FILE:		telnetConnection.asm

AUTHOR:		Simon Auyeung, Jul 10, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------
    INT TelnetResetInfo		Initialize TelnetInfo during TelnetCreate

    INT TelnetConnectSocket	Connect to a socket

    INT TelnetDisconnectSocket	Disconnect a socket

    INT TelnetConnectParseOptions
				Parse telnet options and update TelnetInfo

    INT TelnetCleanupOptions	Clean up telnet option related data
				structures

    INT TelnetInitSocket	Initialize sockets and make connection

    INT TelnetExitSocket	Close the socket we have created for a
				connection

    INT TelnetInitInfo		Initialize connection's TelnetInfo

    INT TelnetInitTelnetInfo	Initialize the parameters of a TelnetInfo
				structure

    INT TelnetInitTelnetInfoSocketAddress
				Store the SocketAddress into a chunk
				attached to a TelnetInfo structure

    INT TelnetCloseMedium	Close the socket medium

    INT TelnetParseReqOptions	Parse the TelnetOptionDesc array to extract
				TelnetOption data

    INT TelnetAddConnection	Add new connection to internal list

    INT TelnetExitInfo		Clean up TelnetInfo associated with a
				connection

    INT TelnetRemoveConnection	Remove a connection from internal list

    INT TelnetFindConnection	Find the connection

    INT TelnetSendSocket	Send data to socket

    EXT TelnetSendBuffer	An inner routine to send out a stream of
				bytes to a TELNET connection

    EXT TelnetSendByte		An inner routine to send out a byte to a
				TELNET connection

    INT TelnetSendIACByte	Send a IAC byte

    INT TelnetSendDoubleIACByte	Send out two IAC bytes which indicates a
				single IAC data byte

    EXT TelnetRecvLow		Inner function of TelnetRecv

    INT TelnetRecvFromCache	Parse data from input cached data if
				available

    INT TelnetCacheData		Cache incoming data for next read

    INT TelnetMakeCache		Create cache buffer

    INT TelnetCleanupCache	Clean up cache

    INT TelnetResetCache	Reset the information and buffer pertaining
				to the cache

    INT TelnetExpandCache	Expand the cache data buffer

    INT TelnetRecvPrepareNotification
				Check and prepare notification, if any, for
				TelnetRecv

    INT TelnetSendSynch		Send a TELNET Synch signal

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon		7/10/95   	Initial revision


DESCRIPTION:
	This file contains routines mainly for transferring data,
	establishing and closing telnet connections. 
		

	$Id: telnetConnection.asm,v 1.1 97/04/07 11:16:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitExitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetResetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize TelnetInfo during TelnetCreate

CALLED BY:	(INTERNAL) TelnetCreate
PASS:		bx	= TelnetConnectionID
		ds	= TelnetControl segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Everything in TelnetInfo except TI_socket is reset;		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetResetInfo	proc	near
		uses	ax, si
		.enter

		mov	si, bx			
		mov	si, ds:[si]		; dssi = TelnetInfo
EC <		Assert	chunkPtr	si, ds				>
EC <		mov	ds:[si].TI_debugID, bx				>
		mov	ds:[si].TI_chunkHandle, bx
		clr	ax
		mov	ds:[si].TI_socketAddress, ax
		mov	ds:[si].TI_state, TST_GROUND
		mov	ds:[si].TI_notification, TNT_NO_NOTIFICATION
		mov	ds:[si].TI_termTypeState, TTSST_NONE
		mov	ds:[si].TI_enabledRemoteOptions, ax
		mov	ds:[si].TI_enabledLocalOptions, ax
		mov	ds:[si].TI_needReplyOptions, ax
		mov	ds:[si].TI_status, al
		mov	ds:[si].TI_currentOption, TOID_NULL_OPTION_ID
		mov	ds:[si].TI_currentCommand, TC_NULL_COMMAND
		mov	ds:[si].TI_error, TE_NORMAL
		mov	ds:[si].TI_suboptionData.TBS_chunk, NULL
		mov	ds:[si].TI_suboptionData.TBS_size, NULL
		mov	ds:[si].TI_cacheDataBuf, NULL
		mov	ds:[si].TI_cacheDataSize, ax
		mov	ds:[si].TI_cacheDataPtr, ax

		.leave
		ret
TelnetResetInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetConnectSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to a socket

CALLED BY:	(INTERNAL) TelnetConnect
PASS:		bx	= TelnetConnectionID
		ss:bp	= inherited stack from TelnetConnect
RETURN:		carry set if error
			ax	= TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get the socket;
	Update the flag;
	SocketConnect;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetConnectSocket	proc	near
		uses	bx, cx, dx, ds, si
		.enter	inherit TelnetConnect
	;
	; Get socket and set flag
	;
		call	TelnetControlStartWrite	; ds = TelnetControl segment
		mov	si, bx
		mov	si, ds:[si]		; dssi = TelnetInfo
EC <		BitTest	ds:[si].TI_status, TS_CONNECTING		>
EC <		ERROR_NZ TELNET_INVALID_CONNECTION_STATUS		>
EC <		BitTest ds:[si].TI_status, TS_CONNECTION_OPEN		>
EC <		ERROR_NZ TELNET_INVALID_CONNECTION_STATUS		>
		BitSet	ds:[si].TI_status, TS_CONNECTING
		mov	bx, ds:[si].TI_socket	; bx = Socket
		call	TelnetControlEndWrite
	;
	; Make socket connection
	;
		push	bp
		movdw	cxdx, ss:[sockAddr]
		mov	bp, ss:[timeout]
		call	SocketConnect		; carry set if error
		pop	bp
	;
	; Unset flag
	;
		pushf
		call	TelnetControlStartWrite
		mov	si, ss:[id]
		mov	si, ds:[si]		; dssi = TelnetInfo
EC <		BitTest	ds:[si].TI_status, TS_CONNECTING		>
EC <		ERROR_Z TELNET_INVALID_CONNECTION_STATUS		>
		BitClr	ds:[si].TI_status, TS_CONNECTING
		popf
		jnc	done
	;
	; Parse SocketError and return the right one
	;
parseErr::
		cmp	al, SE_INTERRUPT
		jne	checkTimeout
		mov	ax, TE_INTERRUPT
		jmp	error

checkTimeout:
		cmp	al, SE_TIMED_OUT
		jne	checkUnreach
		mov	ax, TE_TIMED_OUT
		jmp	error

checkUnreach:
		cmp	al, SE_DESTINATION_UNREACHABLE
		jne	checkMemory
		mov	ax, TE_DESTINATION_UNREACHABLE
		jmp	error

checkMemory:
		cmp	al, SE_OUT_OF_MEMORY
		jne	defaultConnectErr
		mov	ax, TE_INSUFFICIENT_MEMORY
		jmp	error
			
defaultConnectErr:
	;
	; Only these SocketErrors are expected
	;
EC <		pushf							>
EC <		Assert_inList	al, <SE_OUT_OF_MEMORY, SE_CONNECTION_REFUSED, \
			SE_CONNECTION_FAILED, SE_CONNECTION_ERROR, \
			SE_LINK_FAILED, SE_CONNECTION_CLOSED, \
			SE_MEDIUM_BUSY,	SE_CONNECTION_RESET, \
			SE_NON_UNIQUE_CONNECTION, SE_INTERRUPT>>
EC <		popf							>
		cmp	al, SE_CONNECTION_REFUSED
		jne	useDefault
		mov	ax, TE_CONNECTION_REFUSED
		jmp	error
useDefault:
		mov	al, TE_CONNECTION_FAILED

error:
		call	TelnetControlEndWrite
		stc
		jmp	exit
		
done:
EC <		BitTest ds:[si].TI_status, TS_CONNECTION_OPEN		>
EC <		ERROR_NZ TELNET_INVALID_CONNECTION_STATUS		>
		BitSet	ds:[si].TI_status, TS_CONNECTION_OPEN
		call	TelnetControlEndWrite
		clc
		
exit:
		.leave
		ret
TelnetConnectSocket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetDisconnectSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disconnect a socket

CALLED BY:	(INTERNAL) TelnetClose, TelnetConnect
PASS:		bx	= TelnetConnectionID
		ds	= TelnetControl segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetDisconnectSocket	proc	near
		uses	ax, bx, si
		.enter	

		mov	si, bx
		mov	si, ds:[si]		; dssi = TelnetInfo
	;
	; Reset flag
	;
		BitTest	ds:[si].TI_status, TS_CONNECTION_OPEN
		jz	done
		BitClr	ds:[si].TI_status, TS_CONNECTION_OPEN

		mov	bx, ds:[si].TI_socket
	;
	; Disconnect now
	;
		call	SocketCloseSend		; carry set if error
		call	SocketReset
done:
		.leave
		ret
TelnetDisconnectSocket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetConnectParseOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse telnet options and update TelnetInfo

CALLED BY:	(INTERNAL) TelnetConnect
PASS:		ds	= TelnetControl segment
		bx	= TelnetConnectionID
		ss:bp	= inherited stack of TelnetConnect
RETURN:		carry set if error
			ax	= TelnetError
DESTROYED:	nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it. Yet, DS still points to
	  	  the segment of lmem-heap block.
	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Parse the options;
	Realloc TelnetInfo, if necessary;
	Allocate and store SocketAddress;
	Update TelnetInfo;
	Allocate and copy term type option, if any;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetConnectParseOptions	proc	near
		uses	bx, cx, dx, si, di, es
		.enter	inherit TelnetConnect
	;
	; Retrieve options passed in
	;
		call	TelnetParseReqOptions	; cx <- size of extra data
						; ss:[localOpt],ss:[remoteOpt],
						; ss:[termTypePtr] filled  
		jcxz	initSockAddr
	;
	; Realloc telnet info
	;
		mov	ax, bx			; ax = chunk
		add	cx, size TelnetInfo
		call	LMemReAlloc		; carry set if error
		jc	noMemory
	;
	; Allocate space to store SocketAddress
	;
initSockAddr:
		call	TelnetInitTelnetInfoSocketAddress
						; carry set if error
						;  ax = chunk of SocketAddress
		jc	noMemory
	;
	; Update TelnetControl info
	;
		mov	si, bx
		mov	si, ds:[si]		; dssi = TelnetInfo
EC <		Assert	chunkPtr	si, ds				>
		mov	ds:[si].TI_socketAddress, ax
		movm	ds:[si].TI_enabledLocalOptions, ss:[localOpt], ax
		movm	ds:[si].TI_enabledRemoteOptions, ss:[remoteOpt], ax
		mov	al, ss:[opMode]
		ornf	ds:[si].TI_status, al
	;
	; Copy terminal type string if Terminal type option enabled
	;
copyTermType::
		BitTest	ds:[si].TI_enabledLocalOptions, TOS_TERMINAL_TYPE
EC <	LONG	jz	noError			; don't copy term type string>
NEC <		jz	noError			; don't copy term type string>
		push	ds
		movdw	esdi, dssi		; es:di <- fptr to TelnetInfo
		add	di, offset TI_termType	; es:di <- fptr to TI_termType
		lds	si, ss:[termTypePtr]	; ds:si <- fptr to string
EC <		Assert_nullTerminatedAscii	dssi			>
EC <		push	cx						>
EC <		push	es, di						>
EC <		movdw	esdi, dssi 					>
EC <		ByteStrLength	includeNull
EC <		pop	es, di						>
if 	DBCS_PCGEOS
EC <		shl	cx			; double # bytes	>
endif
EC <		Assert_okForRepMovsb					>
EC <		pop	cx						>
		ByteCopyString			; si,di,ax destroyed	
		pop	ds

noError:
		clc
		jmp	done
			
noMemory:
		mov	ax, TE_INSUFFICIENT_MEMORY

done:
		.leave
		ret
TelnetConnectParseOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetCleanupOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up telnet option related data structures

CALLED BY:	(INTERNAL) TelnetClose, TelnetConnect
PASS:		bx	= TelnetConnectionID
		ds	= TelnetControl segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetCleanupOptions	proc	near
		uses	ax, si
		.enter
	;
	; Clean up SocketAddress
	;
		mov	si, bx
		mov	si, ds:[si]
EC <		Assert	chunkPtr	si, ds				>
		clr	ax
		xchg	ax, ds:[si].TI_socketAddress
		tst	ax
		jz	done

		call	LMemFree

done:
		.leave
		ret
TelnetCleanupOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetInitTelnetInfoSocketAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the SocketAddress into a chunk attached to a TelnetInfo
		structure 

CALLED BY:	(INTERNAL) TelnetConnectParseOptions
PASS:		ss:bp	= inherited stack from TelnetConnectParseOptions
			or TelnetInitTelnetInfo
			ss:[sockAddr]: SocketAddress to save
		ds	= segment of LMem block to create chunk 
RETURN:		carry set if cannot allocate
		carry clear:
			^lax = chunk storing SocketAddress
		ds	= updated segment of lmem block
DESTROYED:	nothing
SIDE EFFECTS:	
		WARNING: This may move/shuffle the LMem heap
		in which the SocketAddress chunk is allocated,
		invalidating offsets into the heap.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetInitTelnetInfoSocketAddress	proc	near
		uses	bx, cx, es, si, di
		.enter	inherit	TelnetConnectParseOptions
EC <		Assert_lmem	ds:LMBH_handle				>
	;
	; Calculate size of SocketAddress
	;
		les	di, ss:[sockAddr]	; esdi <- src SocketAddress
EC <		Assert_fptr	esdi					>
		mov	cx, size SocketAddress
		add	cx, es:[di].SA_addressSize
						; cx <- SocketAddress size
	;
	; Allocate chunk for SocketAddress
	;
		clr	ax
		call	LMemAlloc		; carry set if error
						; *ds:ax <- chunk
		jc	done
	;
	; Initialize SocketAddress in new chunk
	;
		mov	si, ax
		mov	si, ds:[si]		; ds:si <- dest SocketAddress
		push	ds
		segxchg	ds, es
		xchg	si, di			; ds:si <- src SocketAddress
						; es:di <- dest SocketAddress
		rep	movsb
		pop	ds
		clc				; ^lax <- copied SocketAddress 
done:
		.leave
		ret
TelnetInitTelnetInfoSocketAddress	endp

if	_CLOSE_MEDIUM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetCloseMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the socket medium

CALLED BY:	(INTERNAL) TelnetExitSocket
PASS:		ds:si	= fptr to SocketAddress 
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetCloseMedium	proc	near
	medium	local	MediumAndUnit		; medium to close
		uses	ax, bx, cx, dx, bp, ds, es, si, di
		.enter
EC <		Assert_fptr	dssi					>
	;
	; Update domain name pointer in passed in SocketAddress since we know
	; there is only one kind of domain.
	;
		mov	bx, handle Strings
		call	MemLock			; ax <- sptr of Strings
		mov	es, ax
		mov	di, offset TCPIPText	; *es:di <- TCPIPText
		mov	di, es:[di]		; es:di <- TCPIPText
		pushdw	ds:[si].SA_domain	; save old domain name pointer
		mov	ds:[si].SA_domain.segment, ax
		mov	ds:[si].SA_domain.offset, di
EC <		Assert_nullTerminatedAscii	esdi			>
	;
	; Get the address medium
	;
		push	bp
		mov	di, si			; ds:di <- SocketAddress
		call	SocketGetAddressMedium	; carry set if error
						;   ax <- SocketError
						; carry clear if no err
						;   cxdx <- MediumType
						;   bl <- MediumUnitType
						;   bp <- MediumUnit
EC <		WARNING_C TELNET_CANNOT_GET_ADDRESS_MEDIUM		>
		mov	ax, bp			; ax <- MediumUnit
		pop	bp			; restore stack
		jc	done
	;
	; Construct medium argument and close medium
	;
		movdw	ss:[medium].MU_medium, cxdx
		mov	ss:[medium].MU_unitType, bl
		mov	ss:[medium].MU_unit, ax
		pushdw	dssi
		lds	si, ds:[si].SA_domain	; dssi <- TCPIP string
		mov	ax, 1			; force close
		mov	dx, ss
		lea	bx, ss:[medium]		; dxbx <- MediumAndUnit
		call	SocketCloseDomainMedium	; carry set if error
		popdw	dssi
EC <		WARNING_C TELNET_CANNOT_CLOSE_DOMAIN_MEDIUM		>
		
done:
		popdw	ds:[si].SA_domain	; restore domain name ptr
		mov	bx, handle Strings
		call	MemUnlock
		.leave
		ret
TelnetCloseMedium	endp

endif	; _CLOSE_MEDIUM
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetParseReqOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the TelnetOptionDesc array to extract TelnetOption data

CALLED BY:	(INTERNAL) TelnetInitInfo, TelnetConnectParseOptions
PASS:		ds	= TelnetControl segment
		ss:bp	= inherited stack from TelnetConnectParseOptions
			or TelnetInitInfo
RETURN:		cx	= size of additional data TelnetInfo should have
		ss:[localOpt] filled
		ss:[remoteOpt] filled
		ss:[termTypePtr] filled
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	numOpt = optDesc.TODA_numOpt;
	descPtr = &optDesc.TOD_optDesc;
	addDataSz = 0;
	while (numOpt--) {
		optID = descPtr.TOD_option;
		switch (optID) {
		case TOID_TRANSMIT_BINARY:
		case TOID_ECHO:
		case TOID_SUPPRESS_GO_AHEAD:
		case TOID_STATUS:
		case TOID_TIMING_MARK:
		case TOID_TERMINAL_TYPE:
			optMask = TelnetGetOptionMask(optID);
			/* If option already enabled, ignore option */
			if (localOpt & optMask || remoteOpt & optMask) {
				break;
			}
			if (descPtr.TOD_flags & TOF_LOCAL) {
				localOpt &= optMask;
			}
			if (descPtr.TOD_flags & TOF_REMOTE) {
				remoteOpt &= optMask;
			}
			if (optID == TOID_TERMINAL_TYPE) {
				termTypePtr = &descPtr.TOD_data;
				dataSz = ByteStrLength(descPtr.TOD_data);
				/* Advance pointer by string size */
				descPtr += dataSz;
				addDataSz += dataSz;
			}
			/* Advance pointer */
			descPtr += sizeof(TelnetOptionDesc);
			break;
		default:
			/* Unrecognized option: Do nothing */
		}
	}
	return addDataSz;
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetParseReqOptions	proc	near
		uses	ax, bx, dx, es, di
		.enter	inherit TelnetConnectParseOptions
EC <		Assert_segment	ds					>
	;
	; The TelnetOptionDesc is arranged as an array. So we need to parse
	; them one by one.
	;
		clr	bx			; bx <- total extra data size
		les	di, ss:[optDesc]	; esdi<-TelnetOptionDescArray
		mov	cx, es:[di].TODA_numOpt
	LONG	jcxz	done
		add	di, offset TODA_optDesc	; esdi<-TelnetOptionDesc
		clr	ss:[localOpt], ss:[remoteOpt]
parseOptLoop:
EC <		Assert_fptr	esdi					>
		push	cx
		mov	cl, es:[di].TOD_option	; cl <- TelnetOptionID
		call	TelnetOptionIDToMask	; carry set if option
						;   unsupported 
						; cx <- mask of
						;   TelnetOptionStatus 
	LONG	jc	ignoreOpt
	;
	; Check if the option has already been enabled previously, if so
	; ignore this one.
	;
		test	ss:[localOpt], cx
EC <		WARNING_NZ TELNET_TELNET_CREATE_PARSE_REPEATED_OPTION	>
	LONG	jnz	ignoreOpt
		test	ss:[remoteOpt], cx
EC <		WARNING_NZ TELNET_TELNET_CREATE_PARSE_REPEATED_OPTION	>
		jnz	ignoreOpt
	;
	; Set the option now
	;
		test	es:[di].TOD_flags, mask TOF_LOCAL
		jz	testRemoteFlag
		ornf	ss:[localOpt], cx

testRemoteFlag:
		test	es:[di].TOD_flags, mask TOF_REMOTE
		jz	testTermType
		ornf	ss:[remoteOpt], cx
		
testTermType:
	;
	; If this is Terminal type option, we need to do something special
	; about it.
	;
		test	cx, mask TOS_TERMINAL_TYPE
		jz	next
	;
	; Terminal type option parsed: find out extra data needed and update
	; pointer.
	;
		add	di, offset TOD_data	; esdi <- string
EC <		Assert_nullTerminatedAscii	esdi			>
		movdw	ss:[termTypePtr], esdi	; update pointer
		ByteStrLength	includeNull	; cx <- strlen w/ NULL
						; ax destroyed
		add	bx, cx			; bx <- total extra data size
	
ignoreOpt:
next:
		add	di, size TelnetOptionDesc; esdi <-next TelnetOptionDesc
		pop	cx
		dec	cx			; update opt count
		jcxz	done
	LONG	jmp	parseOptLoop		; too far for loop to jmp, so
						; use LONG jmp
done:
		mov	cx, bx			; return extra data size
		
		.leave
		ret
TelnetParseReqOptions	endp

if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetAddConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add new connection to internal list

CALLED BY:	(INTERNAL) TelnetInitInfo
PASS:		ds	= TelnetControl segment
		bx	= TelnetConnectionID
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ChunkArrayAppend to TelnetIDArray

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetAddConnection	proc	near
		uses	ax, si, di
		.enter
EC <		Assert_segment	ds					>
EC <		Assert_chunk	bx, ds					>
	;
	; Check if the connection is already existing
	;
if	ERROR_CHECK
		push	bx
		mov_tr	ax, bx			; ax <- TelnetConnectionID
		mov	si, offset TelnetIDArray; *dssi<-chunk array
		call	TelnetLockIDArray
		mov	bx, cs
		mov	di, offset TelnetFindConnection
		call	ChunkArrayEnum		; carry set if found connection
						; di<-nptr to elem
EC <		ERROR_C	TELNET_CONNECTION_DUPLICATED			>
		pop	bx
else
		mov	si, offset TelnetIDArray
endif	; if ERROR_CHECK
		
	;
	; Append new connection's ID to TelnetIDArray
	;
		mov	ax, size TelnetConnectionID
		call	ChunkArrayAppend	; carry set if err
						; carry clear,
						;   ds:di <- fptr to element
EC <		ERROR_C TELNET_CANNOT_APPEND_ID_ARRAY			>
		mov	ds:[di], bx
		call	TelnetUnlockIDArray
		
		.leave
		ret
TelnetAddConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetRemoveConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a connection from internal list

CALLED BY:	(INTERNAL) TelnetExitInfo
PASS:		bx	= TelnetConnectionID
		ds	= TelnetControl segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ChunkArrayEnum to find the right element;
	ChunkArrayDelete the element;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetRemoveConnection	proc	near
		uses	ax, bx, si, di
		.enter
EC <		Assert_segment	ds					>
EC <		Assert_chunk	bx, ds					>
	;
	; Delete a connection chunk from connection list. Assume
	; ChunkArrayEnum can take fptr to callback routine even in XIP
	; version.
	;
		mov_tr	ax, bx
		mov	si, offset TelnetIDArray
		call	TelnetLockIDArray
		mov	bx, cs
		mov	di, offset TelnetFindConnection
					; bxdi <- fptr to TelnetFindConnection
		call	ChunkArrayEnum	; carry set if found connection
					; ax <- nptr to element to delete
					; bx destroyed
EC <		ERROR_NC TELNET_CONNECTION_NOT_FOUND			>
	;
	; Delete TelnetConnectionID from chunk array
	;
		mov_tr	di, ax		; di <- nptr to element to delete
		call	ChunkArrayDelete
		call	TelnetUnlockIDArray

		.leave
		ret
TelnetRemoveConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetFindConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the connection

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= chunk array
		ds:di	= fptr to current chunk array element being enumerated
		ax	= TelnetConnectionID
RETURN:		carry set if TelnetConnectionID matched current element
			ax	= nptr to chunk array element
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Compare the stored TelnetConnectionID of element with the passed one;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetFindConnection	proc	far
		.enter
	
EC <		Assert_fptrXIP	dsdi					>
		cmp	ax, ds:[di]		; cmp stored TelnetConnectionID
		jne	notFound		; carry clear if equal
	;
	; Found element
	;
		mov	ax, di
		stc				; indicate found
done:
		.leave
		ret
notFound:
		clc				; indicate not found
		jmp	done
TelnetFindConnection	endp

endif	; if ERROR_CHECK

InitExitCode	ends

CommonCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send data to socket 

CALLED BY:	(INTERNAL) TelnetSendBuffer, TelnetSendByte,
		TelnetSendCommandSocket, TelnetSendDoubleIACByte,
		TelnetSendIACByte, TelnetSendOptionReal,
		TelnetSendSuboptionSocket
PASS:		bx	= Socket
		ds:si	= fptr to data to send
		cx	= size of data (in bytes)
		ax	= SocketSendFlags
RETURN:		carry set if error
			ax	= TE_INSUFFICIENT_MEMORY
				  TE_CONNECTION_FAILED
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendSocket	proc	far
		.enter
EC <		Assert_socket	bx					>
		call	SocketSend		; carry set if error
						; al <- SocketError
		jnc	done
	;
	; Find out what error
	;
		cmp	al, SE_OUT_OF_MEMORY
		jne	checkTimeout
		mov	ax, TE_INSUFFICIENT_MEMORY
		jmp	error
	;
	; Fail because of timeout?
	;
checkTimeout:
		cmp	al, SE_TIMED_OUT
		jne	checkInterrupt
		mov	ax, TE_TIMED_OUT
		jmp	error

checkInterrupt:
		cmp	al, SE_INTERRUPT
		jne	defaultErr
		mov	ax, TE_INTERRUPT
		jmp	error

	;
	; Other socket errors generate this default telnet error
	;
defaultErr:
		mov	ax, TE_CONNECTION_FAILED
		
error:
		stc

done:
		.leave
		ret
TelnetSendSocket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An inner routine to send out a stream of bytes to a TELNET
		connection 

CALLED BY:	(EXTERNAL) TelnetSend
PASS:		bx	= Socket
		ds:si	= fptr to data to send
		cx	= size of data (in bytes, non-zero)
RETURN:		carry set if error
			ax	= TE_INSUFFICIENT_MEMORY
				  TE_CONNECTION_FAILED
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	bytesLeft = size of data passed in;
	startPtr = ptr passed in;

	while (bytesLeft > 0) {
		bytesScanned = number of bytes scanned before finding IAC;
		/* Send bytes including IAC byte */
		TelnetSendSocket(startPtr, bytesScanned);
		if (error sending data) {
			return error;
		}
		if (found IAC from previous scan) {
			/* Send one more IAC byte */
			TelnetSendIACByte(socket); 
		}
		bytesLeft -= bytesScanned;
		startPtr += bytesScanned;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendBuffer	proc	far
	foundIAC	local	byte		; TRUE/FALSE
		uses	bx, cx, dx, es, di, si
		.enter
EC <		Assert_socket	bx					>
		mov	ax, TE_NORMAL
		jcxz	noError			; no data to send
		mov	dx, cx			; dx <- size of data
		segmov	es, ds, ax
		mov	di, si			; es:di <- buf ptr to start
	
sendLoop:
	;
	; Search for IAC. In the loop:
	; CX <- #bytes to be processed, DX <- # bytes to be sent in
	; current iteration 
	;
		mov	al, TC_IAC
		repne	scasb			; cx <- bytes left
		jnz	noMatch
		mov	ss:[foundIAC], TRUE	; remember to send 2 IACs
		jmp	sendData
		
noMatch:
		mov	ss:[foundIAC], FALSE

sendData:
	;
	; Send data
	;
		xchg	cx, dx			; cx <- # bytes unsent
		sub	cx, dx			; cx <- # bytes to send
		clr	ax			; no SocketSendFlags
		call	TelnetSendSocket	; carry set if error
						; ax <- TelnetError
		jc	done
		CheckHack <FALSE eq 0>
	;
	; If found IAC, send an extra IAC first
	;
		tst	ss:[foundIAC]
		jz	updatePtr
		call	TelnetSendIACByte	; carry set if error
						; ax <- TelnetError
		jc	done

updatePtr:
		add	si, cx			; ds:si <- next round start ptr
		mov	cx, dx			; cx <- bytes left to process
		tst	cx			; any byte to send?
		jnz	sendLoop

noError:
		clc
	
done:
		.leave
		ret		
TelnetSendBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An inner routine to send out a byte to a TELNET connection

CALLED BY:	(EXTERNAL) TelnetSend
PASS:		bx	= Socket
		ds:si	= fptr to data to send
		cx	= 1
RETURN:		carry set if error
			ax	= TE_INSUFFICIENT_MEMORY
				  TE_CONNECTION_FAILED
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (*incomingData == TC_IAC) {
		TelnetSendDoubleIACByte();
	} else {
		TelnetSendSocket(incomingData);
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendByte	proc	far
		.enter

		cmp	ds:[si], TC_IAC
		jne	sendNonIACByte
		call	TelnetSendDoubleIACByte	; carry set if error
						; ax <- TelnetError
		jmp	done

sendNonIACByte:
		call	TelnetSendSocket	; carry set if error
						; ax <- TelnetError	
done:		
		.leave
		ret
TelnetSendByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendIACByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a IAC byte

CALLED BY:	(INTERNAL) TelnetSendBuffer
PASS:		bx	= Socket
RETURN:		carry set if error
			ax	= TE_INSUFFICIENT_MEMORY
				  TE_CONNECTION_FAILED
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendIACByte	proc	near
	IACbyte	local	byte			; byte to send out
		uses	ds, si, cx
		.enter
	
		mov	ss:[IACbyte], TC_IAC
		segmov	ds, ss, ax
		lea	si, ss:[IACbyte]
		clr	ax			; no SocketSendFlags
		mov	cx, 1			; 1 byte of IAC to send
		call	TelnetSendSocket	; carry set if error
						; ax <- TelnetError
		.leave
		ret
TelnetSendIACByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendDoubleIACByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out two IAC bytes which indicates a single IAC data byte 

CALLED BY:	(INTERNAL) TelnetSendByte
PASS:		bx	= Socket
RETURN:		carry set if error
			ax	= TE_INSUFFICIENT_MEMORY
				  TE_CONNECTION_FAILED
		carry clear if no error
			ax	= TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendDoubleIACByte	proc	near
	IACbytes	local	word		; 2 bytes to send out
		uses	ds, si, cx
		.enter
	;
	; Prepare two IAC bytes to send out
	;
		mov	ss:[IACbytes], TC_IAC or (TC_IAC shl 8)
		segmov	ds, ss, ax
		lea	si, ss:[IACbytes]
		clr	ax			; no SocketSendFlags
		mov	cx, 2			; 1 byte of IAC to send
		call	TelnetSendSocket	; carry set if error
						; ax <- TelnetError
		.leave
		ret
TelnetSendDoubleIACByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetRecvLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inner function of TelnetRecv

CALLED BY:	(EXTERNAL) TelnetRecv
PASS:		bx	= TelnetConnectionID
		ds	= TelnetControl segment
		es:di	= fptr to buffer
		cx	= size of buffer
		bp	= timeout (in ticks)
RETURN:		carry set if error
			ax	= TE_TIMED_OUT
				  TE_CONNECTION_FAILED
				  TE_CONNECTION_CLOSED
				  TE_CONNECTION_REFUSED
		carry clear if no error
			ax	= TE_NORMAL
			bx	= TelnetDataType
			cx	= size of data received
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	In this case TE_CONNECTION_REFUSED means SSDE_AUTH_FAILED, which
        means for some reason PPP had to reauthenticate itself, and the
	password was not accepted.

	<HACK> We treat loss of carrier the same as a normal close, as
	an expedient way to get the application to ignore the
	error. </HACK>

	if (there is notification) {
		return TelnetNotificationType;
	}
	if (there is data in cache) {
		Parse data from cache;
	} else {
		Read data from socket;
		if (urgent data) {
			Set params;
			Read urgent data from socket;
		}
		Return error if any;
		if (the #bytes recv from socket != #bytes parsed) {
			Store the rest to cache;
		}
		Return any data;
	}
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetRecvLow	proc	far
	timeout		local	word			push	bp
	connectID	local	TelnetConnectionID	push	bx
	bufSize		local	word			push	cx
	bytesRecv	local	word		; #bytes recv from socket
	bytesParsed	local	word		; #bytes of data parsed
		uses	si, di
		.enter
EC <		Assert_chunk	bx, ds					>
	;
	; If we have notification to reply, don't bother getting any more
	; data
	;
		call	TelnetRecvPrepareNotification
		jnc	done			; carry clear if got
						; notificaiton 
	;
	; If we have cached data, we parse cached data first. 
	;
		call	TelnetRecvFromCache	; carry set if no cached data
		jc	noCachedData
		cmp	ax, TE_NORMAL		; carry clear if TE_NORMAL
		je	inputParsed
		jmp	error
		
noCachedData:
	;
	; We have to grab data from socket to parse
	;
		call	TelnetGetSocket		; ax <- Socket
		clr	bx			; report and urgent data
		xchg	bx, ax			; bx <- Socket, ax <- no flags

recv:
		push	bp
		mov	bp, ss:[timeout]
		call	TelnetControlEndWrite	; release access to free up
						; TelnetControl resource
		call	SocketRecv		; cx <- size of data
						; es:di <- filled with data
						; al <- SocketError
		call	TelnetControlStartWrite
		pop	bp
	;
	; Error handling ------> 
	;   Timeout - report timeout
	;   Urgent data - re-read data
	;   normal - read data
	;   others - failure or link closed
	;
		cmp	al, SE_TIMED_OUT
		je	connectTimeout		; no data
		cmp	al, SE_URGENT
		je	urgentData
		cmp	al, SE_NORMAL
		jne	connectClose

parseData::
	;
	; Filter and process incoming stream for control data
	;
		jcxz	connectTimeout		; if no data, same as timeout
		mov	ss:[bytesRecv], cx
		mov	bx, ss:[connectID]
		push	di			; save original ptr
		call	TelnetParseInput	; esdi = past last byte
		jnc	parseInputSucceed
		pop	di			; restore stack
		jmp	done

parseInputSucceed:
	;
	; Check if all data have been parsed. If not, save the rest to
	; cache data buffer.
	;
		pop	ax			; ax = orig ptr
		push	di
		sub	di, ax			; di = bytes parsed
		mov	ss:[bytesParsed], di
		cmp	di, ss:[bytesRecv]	; all bytes parsed?
		pop	di			; esdi = byte past parsed data
		mov	ax, TE_NORMAL
		je	inputParsed		; jmp if all bytes parsed
		call	TelnetCacheData		; carry set if error
						; ax = TelnetError
		jc	done

inputParsed:
	;
	; RETURNS: carry set if error, ax <- TelnetError
	; bx <- TelnetDataType, cx <- size of data received
	; es:di <- data returned to TelnetRecv   
	; 
	; Return if data type is not data
	;
		cmp	bx, TDT_DATA
		clc
		jne	done
	;
	; Check if there is any data. If not, raise timeout error
	;
		jcxz	connectTimeout
		jmp	done
error:
		stc	
done:
		.leave
		ret
		
connectTimeout:
		mov	ax, TE_TIMED_OUT
		jmp	error

connectClose:
		cmp	al, SE_INTERRUPT
		jne	checkIdleTimeout
		mov	ax, TE_INTERRUPT
		jmp	error

checkIdleTimeout:
		cmp	ah, (SSDE_IDLE_TIMEOUT shr 8)
		jne	checkLinkFailed
		mov	ax, TE_CONNECTION_IDLE_TIMEOUT
		jmp	error
		
checkLinkFailed:
		cmp	ah, (SSDE_LQM_FAILURE shr 8)
		jne	checkAuthFailed
		mov	ax, TE_LINK_FAILED
		jmp	error

checkAuthFailed:
		cmp	ah, (SSDE_AUTH_FAILED shr 8)
		jne	checkNoCarrier
		mov	ax, TE_CONNECTION_REFUSED
		jmp	error
checkNoCarrier:
		cmp	ah, (SSDE_NO_CARRIER shr 8)
		jne	realClose
		mov	ax, TE_CONNECTION_CLOSED
		jmp	error
realClose:
		cmp	al, SE_CONNECTION_CLOSED
		jne	connectFailed
		mov	ax, TE_CONNECTION_CLOSED
		jmp	error

connectFailed:
EC <		WARNING TELNET_RECV_CONNECTION_FAIL			>
		mov	ax, TE_CONNECTION_FAILED
		jmp	error
	
urgentData:
	;
	; Got urgent data. Set the flag that we have received urgent
	; data. Then read the urgent data.
	;
		mov	si, ss:[connectID]
		mov	si, ds:[si]		; ds:si <- TelnetInfo
EC <		Assert_chunkPtr	si, ds					>
		BitSet	ds:[si].TI_status, TS_SYNCH_MODE
		mov	ax, mask SRF_URGENT	; indicate to read urgent data
		mov	cx, ss:[bufSize]
		jmp	recv
TelnetRecvLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetRecvFromCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse data from input cached data if available

CALLED BY:	(INTERNAL) TelnetRecvLow
PASS:		bx	= TelnetConnectionID
		ds	= TelnetControl segment
		es:di	= fptr to destination buffer
		cx	= size of buffer
		ss:bp	= inherited stack of TelnetRecvLow
RETURN:		carry set if no cached data

		carry clear if there is cached data processed:
			ax	= TelnetError
			if ax = TE_NORMAL:
				bx	= TelnetDataType
				cx	= size of data actually returned to
					TelnetRecv
				es:di	= fptr to buffer containing returned
					to TelnetRecv 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If (cached data) {
		TelnetParseInput(cached_data_buf, cached_data_size);
		Update cache data buffer pointers ans size;
		if (cached data all parsed) {
			Resize cached data chunk;
		}
		if (there is data to return) {
			Copy parsed data from cache to dest buffer;
		}
		if (non data) {
			return notification or other things;
		}
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetRecvFromCache	proc	near
	destBuf		local	fptr		push	es, di
						; dest buf to write to
	cacheDataStart	local	word		; offset within cache buf
						; where useful data starts
		uses	si
		.enter
	;
	; Check if there is any cached data
	;
		mov	si, ds:[bx]		; dssi = TelnetInfo
		tst	ds:[si].TI_cacheDataSize
		stc
		jz	done
	;
	; Set up the parameters to parse data
	;
		movm	ss:[cacheDataStart], ds:[si].TI_cacheDataPtr, ax
		mov	di, ds:[si].TI_cacheDataBuf
		segmov	es, ds, ax	
		mov	di, es:[di]		
		add	di, ds:[si].TI_cacheDataPtr
						; esdi = cached data to parse
		mov	cx, ds:[si].TI_cacheDataSize

		call	TelnetParseInput	; carry set if error
		jc	cachedDataReturn	; don't care if error
	;
	; Update the cache data buffer pointers and sizes
	;
		mov_tr	ax, di			; esax = last byte parsed
		mov	di, ds:[si].TI_cacheDataBuf
		mov	di, ds:[di]		; dsdi = cache buf
		sub	ax, di			; ax = #bytes parsed in cache
		sub	ax, ss:[cacheDataStart]	; ax = #bytes parsed
		add	ds:[si].TI_cacheDataPtr, ax
		sub	ds:[si].TI_cacheDataSize, ax
	;
	; Copy data to dest buffer
	;
copyData::
		jcxz	checkResetCache
		push	si, cx
		mov	si, ds:[si].TI_cacheDataBuf
		mov	si, ds:[si]		; dssi = cache buf
		add	si, ss:[cacheDataStart]	; dssi = ptr to useful data
		les	di, ss:[destBuf]	; esdi = dest buf
		rep	movsb
		pop	si, cx
	;
	; Reset the cache data buffer if empty.
	;
checkResetCache:
		mov	ax, TE_NORMAL		; default TelnetError
		tst	ds:[si].TI_cacheDataSize
		jnz	cachedDataReturn

		call	TelnetResetCache	; carry set if error
		jnc	cachedDataReturn
		mov	ax, TE_INSUFFICIENT_MEMORY

cachedDataReturn:
		les	di, ss:[destBuf]	; esdi = dest buf
		clc

done:
		.leave
		ret
TelnetRecvFromCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetCacheData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cache incoming data for next read

CALLED BY:	(INTERNAL) TelnetRecvLow
PASS:		es:di	= fptr to buffer where unprocessed data starts
		ds	= TelnetControl segment
		ss:bp	= inherited stack of TelnetRecvLow		
RETURN:		ds	= TelnetControl segment (block may be moved)
		carry set if cannot cache data
			ax	= TelnetError
DESTROYED:	nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetCacheData	proc	near
		uses	bx, cx, di, si
		.enter	inherit TelnetRecvLow

		mov	bx, ss:[connectID]
		mov	si, bx			; si = TelnetConnectionID
		mov	cx, ss:[bytesRecv]
		sub	cx, ss:[bytesParsed]	; cx = #bytes unparsed
EC <		jns	checkExpand					>
EC <		ERROR	TELNET_INCORRECT_CACHE_BYTE_CALCULATION		>

checkExpand::
	;
	; expand cache data buffer if necessary
	;
		cmp	cx, TELNET_RECV_TEMP_BUF_SIZE
		jbe	writeCache
EC <		push	si, cx						>
EC <		mov	si, ds:[si]					>
EC <		mov	si, ds:[si].TI_cacheDataBuf			>
EC <		ChunkSizeHandle	ds, si, cx				>
EC <		cmp	cx, TELNET_RECV_TEMP_BUF_SIZE			>
EC <		ERROR_A	TELNET_INVALID_CACHE_DATA_BUF_SIZE		>
EC <		pop	si, cx						>
		call	TelnetExpandCache	; carry set if error
		jc	noMemory
		
writeCache:
	;
	; Copy rest of data from recv buffer to cache
	;
		mov	si, ds:[si]		; dssi = TelnetInfo
EC <		Assert_chunkPtr	si, ds					>
		mov	ds:[si].TI_cacheDataSize, cx
		clr	ds:[si].TI_cacheDataPtr
		mov_tr	ax, di			; ax = nptr to src
		mov	di, ds:[si].TI_cacheDataBuf
		segxchg	ds, es
		mov	di, es:[di]		; esdi = dest
		mov_tr	si, ax			; dssi = src, esdi = dest
EC <		Assert_okForRepMovsb					>
		rep	movsb
		segxchg	ds, es
		mov	ax, TE_NORMAL
		clc
		jmp	done

noMemory:
		mov	ax, TE_INSUFFICIENT_MEMORY

done:
		.leave
		ret
TelnetCacheData	endp

CommonCode	ends

InitExitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetMakeCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create cache buffer

CALLED BY:	(INTERNAL) TelnetConnect
PASS:		ds	= TelnetControl segment
		bx	= TelnetConnectionID
RETURN:		carry set if error
			ax	= TelnetError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetMakeCache	proc	near
		uses	cx, si
		.enter

		clr	al			; no ObjChunkFlags
		mov	cx, TELNET_RECV_TEMP_BUF_SIZE
		call	LMemAlloc		; ax = chunk
		jc	noMemory
	;
	; Update TelnetInfo
	;
		mov	si, bx
		mov	si, ds:[si]		; dssi = TelnetInfo
EC <		pushf							>
EC <		Assert	chunkPtr	si, ds				>
EC <		popf							>
		mov	ds:[si].TI_cacheDataBuf, ax
		jmp	done

noMemory:
		mov	ax, TE_INSUFFICIENT_MEMORY

done:
		.leave
		ret
TelnetMakeCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetCleanupCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up cache

CALLED BY:	(INTERNAL) TelnetClose, TelnetConnect
PASS:		bx	= TelnetConnectionID
		ds	= TelnetControl segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetCleanupCache	proc	near
		uses	ax, si
		.enter

		mov	si, bx
		mov	si, ds:[si]
EC <		Assert	chunkPtr	si, ds				>
		clr	ax
		xchg	ax, ds:[si].TI_cacheDataBuf
		tst	ax
		jz	done
		call	LMemFree

done:
		.leave
		ret
TelnetCleanupCache	endp

InitExitCode	ends

CommonCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetResetCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the information and buffer pertaining to the cache

CALLED BY:	(INTERNAL) TelnetRecvFromCache
PASS:		ds:si	= fptr to TelnetInfo
RETURN:		carry set if cannot reisze cache data buffer

		* NOTE *

		If the chunk is resized, the block may be moved. In this
		case, if DS or ES points to TelnetControl block, they will be
		updated.

DESTROYED:	nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Reset the cache parameters;
	if (chunk size > minimun) {
		Resize the chunk to minimum;
		Fix up offsets;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetResetCache	proc	near
		uses	ax, cx
		.enter
EC <		Assert_chunkPtr	si, ds					>
		clr	ax
		mov	ds:[si].TI_cacheDataSize, ax
		mov	ds:[si].TI_cacheDataPtr, ax
	;
	; If the recv buffer is bigger than it should be, shrink it down to
	; minimal. 
	;
		ChunkSizeHandle	ds, ds:[si].TI_cacheDataBuf, ax
	;
	; The chunk size is round up to 4. So, we make sure the size is also
	; a multiple of 4.
	;
		CheckHack <(TELNET_RECV_TEMP_BUF_SIZE mod 4) eq 0> 
		cmp	ax, TELNET_RECV_TEMP_BUF_SIZE
		je	done			; carry clear if jmp

EC <		WARNING TELNET_SHRINK_TEMP_RECV_BUF			>
		push	ds:[si].TI_chunkHandle
		mov	ax, ds:[si].TI_cacheDataBuf
		mov	cx, TELNET_RECV_TEMP_BUF_SIZE
		call	LMemReAlloc		; carry set if error
						; ds,es updated
EC <		WARNING_C TELNET_CANNOT_SHRINK_TEMP_RECV_BUF		>
		pop	si			; *dssi = TelnetInfo
		mov	si, ds:[si]		; dssi = TelnetInfo
		
done:
		.leave
		ret
TelnetResetCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetExpandCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand the cache data buffer

CALLED BY:	(INTERNAL) TelnetCacheData
PASS:		*ds:si	= TelnetInfo
		cx	= size of cache desired
RETURN:		carry set if cannot expand cache
DESTROYED:	*ds:si	= TelnetInfo (TelnetControl block may be moved)
		nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetExpandCache	proc	near
		uses	si, ax
		.enter inherit TelnetCacheData

		mov	si, ds:[si]	
EC <		Assert_chunkPtr	si, ds					>
		mov	ax, ds:[si].TI_cacheDataBuf
		call	LMemReAlloc		; carry set if error

		.leave
		ret
TelnetExpandCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetRecvPrepareNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check and prepare notification, if any, for TelnetRecv

CALLED BY:	(INTERNAL) TelnetRecvLow
PASS:		bx	= TelnetConnectionID
		ds	= TelnetControl segment
RETURN:		carry clear if received notification
			ax	= TE_NORMAL
			bx	= TDT_NOTIFICATION
			cx	= size of extra data
			dx	= TelnetNotificationType
			
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetRecvPrepareNotification	proc	near
		uses	si
		.enter
		mov	si, bx
		mov	si, ds:[si]
		cmp	ds:[si].TI_notification, TNT_NO_NOTIFICATION
		stc				; default no notification
		je	done
	;
	; Return notification to caller
	;
		CheckHack <size TelnetDataType eq 2>
		mov	dx, TNT_NO_NOTIFICATION
		xchg	dx, ds:[si].TI_notification
		mov	bx, TDT_NOTIFICATION
		mov	ax, TE_NORMAL
%out	~~~~ TelnetRecvPrepareNotification: No extra data returned to caller yet ~~~~
		clr	cx			; no data returned to caller
		clc				; got notification

done:
		.leave
		ret
TelnetRecvPrepareNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendSynch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a TELNET Synch signal

CALLED BY:	(INTERNAL) TelnetSendCommandSocket
PASS:		bx	= Socket
RETURN:		ax	= TelnetError
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Send IAC as non-urgent data;
	Send DM as urgent data;		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	2/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendSynch	proc	near
		uses	cx, ds, si
		.enter
EC <		Assert_socket	bx					>
		
	;
	; We first send IAC as non-urgent data
	;
		mov	ax, TC_IAC
		push	ax
		segmov	ds, ss, ax
		mov	si, sp			; ds:si <- buf containg IAC
		mov	cx, 1
		clr	ax			; no flags
		call	TelnetSendSocket	; ax <- TelnetError
						; carry set if error
		pop	si			; not pop AX b/c AX returned
		jc	done
	;
	; Then we send out DM as urgent data
	;
		mov	ax, TC_DM
		push	ax
		mov	si, sp			; ds:si <- buf containing DM
		mov	ax, mask SSF_URGENT
		call	TelnetSendSocket	; ax <- TelnetError
						; carry set if error
		pop	cx			; not pop AX b/c AX returned
done:
		.leave
		ret
TelnetSendSynch	endp

CommonCode	ends
