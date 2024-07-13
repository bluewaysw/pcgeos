COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS (Network Extensions)
MODULE:		TELNET Library
FILE:		telnetEC.asm

AUTHOR:		Simon Auyeung, Aug  8, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------
    GLB ECCheckTelnetError	Assert the argument is TelnetError

    EXT ECCheckTelnetErrorAndFlags
				Assert the argument is TelnetError and
				carry is set if it is not TE_NORMAL

    GLB ECCheckTelnetInfo	Verify all parameters of TelnetInfo are
				correct

    EXT TelnetLockIDArray	Lock the TelnetIDArray to gain exclusive
				access

    EXT TelnetUnlockIDArray	Unlock TelnetIDArray to release exclusive
				access

    GLB ECCheckTelnetConnectionID
				Verify a TelnetConnectionID

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon		8/ 8/95   	Initial revision


DESCRIPTION:
	A file contains all EC codes.
		

	$Id: telnetEC.asm,v 1.1 97/04/07 11:16:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;				Macros
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Assert_TelnetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert the argument is TelnetError 

PASS:		expr	= the expression to check
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Assert_TelnetError		macro	expr
		PreserveAndGetIntoReg	ax, expr
		call	ECCheckTelnetError
		RestoreReg		ax, expr
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Assert_TelnetErrorAndFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert the argument is TelnetError and carry is set if it
		is not TE_NORMAL

PASS:		expr	= the expression to check
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Assert_TelnetErrorAndFlags		macro	expr
		PreserveAndGetIntoReg	ax, expr
		call	ECCheckTelnetErrorAndFlags
		RestoreReg		ax, expr
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Assert_TelnetConnectionID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert the passed expr is a TelnetConnectionID

PASS:		expr	= expression to check
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Assert_TelnetConnectionID		macro	expr
		PreserveAndGetIntoReg	bx, expr
		call	ECCheckTelnetConnectionID
		RestoreReg		bx, expr
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Assert_TelnetOptionRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert the expression is a valid TelnetOptionRequest

PASS:		expr	= expression to check (byte size)
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Assert_TelnetOptionRequest		macro	expr
		pushf
	;
	; Assert_etype is not used because it complains about the byte size
	; restriction of TelnetOptionRequest. Possibly it is because TC_DONT
	; (the largest etype value) is already 254.
	;
		cmp	expr, TOR_WILL
		ERROR_B	TELNET_INVALID_TELNET_OPTION_REQUEST
		cmp	expr, TOR_DONT
		ERROR_A	TELNET_INVALID_TELNET_OPTION_REQUEST
		popf
endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Assert_TelnetOptionID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert that the expression is a valid TelnetOptionID

PASS:		expr	= expression to check (byte size)
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Assert_TelnetOptionID		macro	expr
		pushf
		Assert_inList	expr, <TOID_TRANSMIT_BINARY, TOID_ECHO,	TOID_SUPPRESS_GO_AHEAD, TOID_STATUS, TOID_TIMING_MARK, TOID_TERMINAL_TYPE>
		popf
endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Assert_TelnetCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert that the expression is a valid TelnetCommand

PASS:		expr	= expression to check (byte size)
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Assert_TelnetCommand		macro	expr
                pushf
                cmp     expr, TC_EOF
                ERROR_B TELNET_INVALID_TELNET_COMMAND
                cmp     expr, TC_IAC
                ERROR_A TELNET_INVALID_TELNET_COMMAND
                popf
endm

;----------------------------------------------------------------------------
;				Codes
;----------------------------------------------------------------------------

ECCode	segment	resource
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTelnetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert the argument is TelnetError

CALLED BY:	(GLOBAL) Assert_TelnetError, ECCheckTelnetErrorAndFlags,
		TelnetSendSynch 
PASS:		ax	= TelnetError
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTelnetError	proc	far
if	ERROR_CHECK
		.enter
		pushf
		Assert	etype	al, TelnetError
		popf
		.leave
endif	; ERROR_CHECK
		ret
ECCheckTelnetError	endp

if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTelnetErrorAndFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert the argument is TelnetError and carry is set if it
		is not TE_NORMAL

CALLED BY:	(EXTERNAL) Assert_TelnetErrorAndFlags, TelnetSendSynch
PASS:		ax	= TelnetError
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TELNET_ERROR_NORMAL_WITH_CARRY_SET	enum	FatalErrors
TELNET_ERROR_NON_NORMAL_WITH_CARRY_CLEAR enum	FatalErrors
	
ECCheckTelnetErrorAndFlags	proc	far
		.enter
		pushf				; preserve flags
		call	ECCheckTelnetError	; flags preserved
	;
	; Check TelnetError against carry
	;
		jnc	checkNormal
		cmp	ax, TE_NORMAL		; shouldn't be TE_NORMAL
		ERROR_E TELNET_ERROR_NORMAL_WITH_CARRY_SET
		jmp	quit
		
checkNormal:
		cmp	ax, TE_NORMAL		; should be TE_NORMAL
		ERROR_NE TELNET_ERROR_NON_NORMAL_WITH_CARRY_CLEAR

quit:
		popf				; preserve flags
	
		.leave
		ret
ECCheckTelnetErrorAndFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTelnetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify all parameters of TelnetInfo are correct

CALLED BY:	GLOBAL
PASS:		bx	= TelnetConnectionID

		TelnetControl block must be locked already

RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTelnetInfo	proc	far
		ForceRef	ECCheckTelnetInfo
		uses	si, ds, ax, cx
		.enter
		pushf

		call	TelnetControlDeref	; ds <- sptr to TelnetControl 
	
		mov	si, ds:[bx]		; si <- nptr to TelnetInfo
		Assert_fptr	dssi
		cmp	bx, ds:[si].TI_debugID
	;
	; debug ID is the same as the lptr to TelnetInfo
	;
		ERROR_NE TELNET_INVALID_TELNET_INFO
		Assert_chunk	ds:[si].TI_cacheDataBuf, ds
		ChunkSizeHandle	ds, ds:[si].TI_cacheDataBuf, cx
		Assert_be	ds:[si].TI_cacheDataSize, cx
		push	si
		mov	ax, ds:[si].TI_cacheDataPtr
		mov	cx, ds:[si].TI_cacheDataSize
		mov	si, ds:[si].TI_cacheDataBuf
		mov	si, ds:[si]		; dssi = cache data buffer
		add	si, ax			; dssi = start of cache data
		Assert_buffer	dssi, cx
		pop	si
	
		Assert_chunk	ds:[si].TI_socketAddress, ds
		Assert_socket	ds:[si].TI_socket
		Assert_etype	ds:[si].TI_state, TelnetStateType	
		Assert_etype	ds:[si].TI_termTypeState, \
				TelnetTerminalSuboptionStateType 
		Assert_record	ds:[si].TI_enabledLocalOptions, \
				TelnetOptionStatus
		Assert_record	ds:[si].TI_enabledRemoteOptions, \
				TelnetOptionStatus
		Assert_record	ds:[si].TI_status, TelnetStatus
		Assert_etype	ds:[si].TI_error, TelnetError
		Assert_TelnetOptionID	ds:[si].TI_currentOption
		Assert_TelnetCommand	ds:[si].TI_currentCommand
		tst	ds:[si].TI_suboptionData.TBS_chunk
		jz	noSubOption
		Assert_chunk	ds:[si].TI_suboptionData.TBS_chunk, ds
		tst	ds:[si].TI_suboptionData.TBS_size
	;
	; If the suboption data exists, the size shouldn't be zero
	;
		ERROR_Z	TELNET_INVALID_TELNET_INFO
	
noSubOption:
		add	si, offset TI_termType	; si <- nptr to term type str
		Assert_nullTerminatedAscii	dssi
	
		popf
		.leave
		ret
ECCheckTelnetInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetLockIDArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the TelnetIDArray to gain exclusive access

CALLED BY:	(EXTERNAL) ECCheckTelnetConnectionID, TelnetAddConnection,
		TelnetRemoveConnection
PASS:		*ds:si	= TelnetIDArray
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetLockIDArray	proc	far
		uses	ax, bx
		.enter

		mov	bx, ds:[si]
		mov	bx, ds:[bx].TIDAH_sem
		call	ThreadPSem		; ax <- SemaphoreError
		
		.leave
		ret
TelnetLockIDArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetUnlockIDArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock TelnetIDArray to release exclusive access

CALLED BY:	(EXTERNAL) ECCheckTelnetConnectionID, TelnetAddConnection,
		TelnetRemoveConnection
PASS:		*ds:si	= TelnetIDArray
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetUnlockIDArray	proc	far
		uses	ax, bx
		.enter
	
		mov	bx, ds:[si]
		mov	bx, ds:[bx].TIDAH_sem
		call	ThreadVSem		; ax <- SemaphoreError
	
		.leave
		ret
TelnetUnlockIDArray	endp

endif	; if ERROR_CHECK

ECCode	ends

if	ERROR_CHECK
		
InitExitCode	segment	resource
	;
	; This is put in the same resource as callback TelnetFindConnection
	; so that ChunkArrayEnum can call it successfully.
	;

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTelnetConnectionID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a TelnetConnectionID

CALLED BY:	GLOBAL
PASS:		ds	= Telnet control block segment
		bx	= TelnetConnectionID
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTelnetConnectionID	proc	far
		uses	ax, bx, si, di
		.enter
	;
	; Note: We want to get exclusive access to chunk array here because
	; Telnet connection control structure can be accessed by different
	; threads can mess up ChunkArrayEnum. ChunkArrayEnum creates a temp
	; strucutre on the stack and its link in ChunkArrayHeader has
	; reference to it. If ChunkArrayEnum is called by another thread at
	; the same time, the reference will point to another thread's temp
	; structure and create problems.		-simon 3/26/96
	;
		pushf
		Assert	chunk	bx, ds
	;
	; Find out the ID in connection list
	;
		mov_tr	ax, bx
		mov	si, offset TelnetIDArray
		call	TelnetLockIDArray	
		CheckHack <segment ECCheckTelnetConnectionID eq \
			   segment TelnetFindConnection>
		mov	bx, cs
		mov	di, offset TelnetFindConnection
					; bx:di<-fptr to TelnetFindConnection
		call	ChunkArrayEnum	; carry set if found connection
					; ax <- nptr to elem
					; bx destroyed
		ERROR_NC TELNET_CONNECTION_NOT_FOUND
		call	TelnetUnlockIDArray

		popf
	
		.leave
		ret
ECCheckTelnetConnectionID	endp

InitExitCode	ends

endif	; if ERROR_CHECK
