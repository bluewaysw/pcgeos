COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlap.asm

AUTHOR:		Cody Kwok, Mar 23, 1994

ROUTINES:
	Name				Description
	----				-----------
	IrlapInit		 	DR_INIT
	IrlapExit		 	DR_EXIT
	IrlapSuspend		 	DR_SUSPEND
	IrlapUnsuspend		 	DR_UNSUSPEND
	IrlapSocketRegister		DR_SOCKET_REGISTER
	IrlapSocketUnregister		DR_SOCKET_UNREGISTER
	IrlapSocketConnectRequest	DR_SOCKET_CONNECT_REQUEST
	IrlapSocketDisconnectRequest	DR_SOCKET_DISCONNECT_REQUEST
	IrlapSocketSendData		DR_SOCKET_SEND_DATA
	IrlapSocketSendDatagram		DR_SOCKET_SEND_DATAGRAM
	IrlapSocketResetRequest		DR_SOCKET_RESET_REQUEST
	IrlapSocketDoNothing		DR_SOCKET_ATTACH
	IrlapSocketDoNothing		DR_SOCKET_REJECT
	IrlapSocketGetInfo		DR_SOCKET_GET_INFO
	IrlapSocketLinkActivated	DR_SOCKET_LINK_ACTIVATED
	IrlapSocketSetOption		DR_SOCKET_SET_OPTION
	IrlapSocketGetOption		DR_SOCKET_GET_OPTION
	IrlapSocketResolveAddr		DR_SOCKET_RESOLVE_ADDR
	;
	; Native interface
	;
 	IrlapNativeRegister		NIR_REGISTER_NATIVE_CLIENT
 	IrlapNativeRegister		NIR_REGISTER_SOCKET_CLIENT
	IrlapNativeUnregister		NIR_UNREGISTER
	IrlapNativeAddIrlapDomain	NIR_ADD_IRLAP_DOMAIN
 	IrlapNativeDiscoveryRequest	NIR_DISCOVERY_REQUEST
 	IrlapNativeDiscoveryResponse	NIR_DISCOVERY_RESPONSE
 	IrlapNativeUnitdataRequest	NIR_UNITDATA_REQUEST
 	IrlapNativeConnectRequest	NIR_CONNECT_REQUEST
 	IrlapNativeConnectResponse	NIR_CONNECT_RESPONSE
 	IrlapNativeSniffRequest		NIR_SNIFF_REQUEST
 	IrlapNativeDataRequest		NIR_DATA_REQUEST
 	IrlapNativeStatusRequest	NIR_STATUS_REQUEST
 	IrlapNativeQQSRequest		NIR_QQS_REQUEST
 	IrlapNativeResetRequest		NIR_RESET_REQUEST
 	IrlapNativeResetResponse	NIR_RESET_RESPONSE
 	IrlapNativeDisconnectRequest	NIR_DISCONNECT_REQUEST
	IrlapNativeAbortSniff		NIR_ABORT_SNIFF
	IrlapNativeSetSniffVariables	NIR_SET_SNIFF_VARIABLES
	IrlapNativeFlushDataRequests	NIR_FLUSH_DATA_REQUESTS
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/23/94   	Initial revision


DESCRIPTION:
	Driver interface and strategy routine for IRLAP-SIR driver.

	$Id: irlap.asm,v 1.1 97/04/18 11:56:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapResidentCode	segment	resource

DefIrlapProc   macro   routine, cnst
.assert ($-IrlapProcs) eq cnst*2, <function table is corrupted>
.assert (type routine eq far)
                fptr.far        routine
                endm

IrlapProcs	label	fptr.far
DefIrlapProc	IrlapInit,			DR_INIT
DefIrlapProc	IrlapExit,			DR_EXIT
DefIrlapProc	IrlapSuspend,			DR_SUSPEND
DefIrlapProc	IrlapUnsuspend,			DR_UNSUSPEND

if _SOCKET_INTERFACE

DefIrlapProc	IrlapSocketRegister,		DR_SOCKET_REGISTER
DefIrlapProc	IrlapSocketUnregister,		DR_SOCKET_UNREGISTER
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_ALLOC_CONNECTION
DefIrlapProc	IrlapSocketConnectRequest,	DR_SOCKET_LINK_CONNECT_REQUEST
DefIrlapProc	IrlapSocketNotSupported,       	DR_SOCKET_DATA_CONNECT_REQUEST
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_STOP_DATA_CONNECT
DefIrlapProc	IrlapSocketDisconnectRequest,	DR_SOCKET_DISCONNECT_REQUEST
DefIrlapProc	IrlapSocketSendData,		DR_SOCKET_SEND_DATA
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_STOP_SEND_DATA
DefIrlapProc	IrlapSocketSendDatagram,	DR_SOCKET_SEND_DATAGRAM
DefIrlapProc	IrlapSocketResetRequest,	DR_SOCKET_RESET_REQUEST
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_ATTACH
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_REJECT
DefIrlapProc	IrlapSocketGetInfo,		DR_SOCKET_GET_INFO
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_SET_OPTION
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_GET_OPTION
DefIrlapProc	IrlapSocketResolveAddr,		DR_SOCKET_RESOLVE_ADDR
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_STOP_RESOLVE
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_CLOSE_MEDIUM
DefIrlapProc	IrlapSocketNotSupported,       DR_SOCKET_MEDIUM_CONNECT_REQUEST
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_MEDIUM_ACTIVATED
DefIrlapProc	IrlapSocketNotSupported,	DR_SOCKET_SET_MEDIUM_OPTION
DefIrlapProc	IrlapSocketDoNothing,		DR_SOCKET_RESOLVE_LINK_LEVEL_ADDRESS

endif ;_SOCKET_INTERFACE

DefIrlapNativeProc macro routine, cnst
.assert ($-IrlapNativeProcs) eq (cnst - SOCKET_DR_FIRST_SPEC_FUNC)*2,\
		<function table is corrupted>
		.assert (type routine eq far)
		fptr.far	routine
		endm

IrlapNativeProcs label fptr.far
DefIrlapNativeProc IrlapNativeRegister,		NIR_REGISTER_NATIVE_CLIENT
DefIrlapNativeProc IrlapNativeRegister,		NIR_REGISTER_SOCKET_CLIENT
DefIrlapNativeProc IrlapNativeUnregister,	NIR_UNREGISTER
DefIrlapNativeProc IrlapNativeAddIrlapDomain,	NIR_ADD_IRLAP_DOMAIN
DefIrlapNativeProc IrlapNativeDiscoveryRequest,	NIR_DISCOVERY_REQUEST
DefIrlapNativeProc IrlapNativeDiscoveryResponse,NIR_DISCOVERY_RESPONSE
DefIrlapNativeProc IrlapNativeUnitdataRequest,	NIR_UNITDATA_REQUEST
DefIrlapNativeProc IrlapNativeConnectRequest,	NIR_CONNECT_REQUEST
DefIrlapNativeProc IrlapNativeConnectResponse,	NIR_CONNECT_RESPONSE
DefIrlapNativeProc IrlapNativeSniffRequest,	NIR_SNIFF_REQUEST
DefIrlapNativeProc IrlapNativeDataRequest,	NIR_DATA_REQUEST
DefIrlapNativeProc IrlapNativeStatusRequest,	NIR_STATUS_REQUEST
DefIrlapNativeProc IrlapNativeQOSRequest,	NIR_QOS_REQUEST
DefIrlapNativeProc IrlapNativeResetRequest,	NIR_RESET_REQUEST
DefIrlapNativeProc IrlapNativeResetResponse,	NIR_RESET_RESPONSE
DefIrlapNativeProc IrlapNativeDisconnectRequest,NIR_DISCONNECT_REQUEST
DefIrlapNativeProc IrlapNativeAbortSniff,	NIR_ABORT_SNIFF
DefIrlapNativeProc IrlapNativeSetSniffVariables,NIR_SET_SNIFF_VARIABLES
DefIrlapNativeProc IrlapNativeFlushDataRequests,NIR_FLUSH_DATA_REQUESTS
DefIrlapNativeProc IrlapNativePrimaryRequest,	NIR_PRIMARY_REQUEST
DefIrlapNativeProc IrlapNativePrimaryResponse,	NIR_PRIMARY_RESPONSE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine

CALLED BY:	Client
PASS:		di	= function code + urgent bit(= most significant bit)
		rest	= varies
RETURN:		varies
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapStrategy	proc	far
		cmp	di, SOCKET_DR_FIRST_SPEC_FUNC
		jb	socketFunction

		GOTO	IrlapNativeStrategy

socketFunction:
		push	di
		shl	di
		add	di, offset IrlapProcs
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		mov	bx, cs:[di].segment
		mov	ax, cs:[di].offset
		pop	di
		call	ProcCallFixedOrMovable
		ret
IrlapStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls a native function

CALLED BY:	IrlapStartegy
PASS:		di = function code
		rest = depends on di
RETURN:		variable
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeStrategy	proc	far
		push	di
		sub	di, SOCKET_DR_FIRST_SPEC_FUNC
		shl	di
		add	di, offset IrlapNativeProcs
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		mov	bx, cs:[di].segment
		mov	ax, cs:[di].offset
		pop	di
		call	ProcCallFixedOrMovable
		ret
IrlapNativeStrategy	endp



; ****************************************************************************
; ****************************************************************************
; ***********************     Fixed Callbacks     ****************************
; ****************************************************************************
; ****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapRecvLoop (V)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	A loop that reads packet from the stream, alloc the buffer
		for this data,  and call a callback.

CALLED BY:	IrlapDriverInit (ThreadCreate)
PASS:		cx - station segment(fixed)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Loop:
		Fetch a valid packet
		dispatch it as IRLAP event
	end Loop
	Since the thread dies here,  who cares what registers it trashes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/ 1/94    	Initial version
	SJ	8/3/94		dynamic allocation of station

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapRecvLoop	proc	far
		
		mov	ds, cx
EC <		IrlapCheckStation	ds				>
recvLoop:
	;
	; Get serial port number
	;
		call	IrlapRecv			; dx:bp = packet
		jc	exit				; ah = A, al = C field
	;
	; Find out the packet type and send the corresponding event to
	; IRLAP state machine.
	;
		mov	cx, ax			; cl = control field
		and	ah, mask IAF_CRBIT	; ah = IrlapExternalEvent
EC <		Assert	etype, ah, IrlapExternalEvent			>
EC <		IrlapCheckStation	ds				>
		mov	bx, ds:IS_eventThreadHandle
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	recvLoop
exit:
	;
	; NOTE: the call to ThreadDestroy() must be in fixed code and
	; not have been called to from a movable resource, or the
	; resource will not get unlocked since this will not return.
	;
		movdw	ds:IS_serverThreadHandle, 0
 		clr	cx, dx, bp
		jmp	ThreadDestroy
		.warn	-unreach
		ret
		.warn	@unreach
IrlapRecvLoop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get one valid packet

CALLED BY:	IrlapRecvLoop
PASS:		ds = station segment

RETURN:		carry set if port closed,
		otherwise
			dx:bp - handle of memhandle of packet
			al, ah - station conn addr + control

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get first 3 (BOF, addr, control) from stream
	Get I field
	check CRC		
	if valid, resize (?) I field to correct size

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapRecv	proc	near
		uses	bx, cx, di, es, si
		.enter
restart:
		mov	di, DR_STREAM_READ_BYTE
getPacketStartLoop:
	;
	; Get bytes until we get to the start of a packet followed by
	; a valid type.
	;
EC <		IrlapCheckStation	ds				>
EC <		cmp	di, DR_STREAM_READ_BYTE 			>
EC <		ERROR_NE	-1					>
		Assert	dgroup, es
	;
	; Check if we are exitting right now
	;
		test	ds:IS_status, mask ISS_GOING_AWAY
		stc
		jnz	exit
	;
	; P serial sem: look for IS_serialSem for documentation
	;
		mov	bx, ds:IS_serialSem
		call	ThreadPSem		; ax destroyed
	;
	; Get a byte from serial driver
	;
		mov	ax, STREAM_BLOCK
		mov	bx, ds:IS_serialPort
		call	ds:IS_serialStrategy	;al = byte read
	;
	; V serial sem
	;
		push	ax	
		mov	bx, ds:IS_serialSem
		call	ThreadVSem		; ax trashed, flags preserved
		pop	ax			; restore byte read
		jc	exit			; the port is closed
	;
	; Record the time this was received
	;
		push	ax, bx
		call	TimerGetCount		; bxax = sys counter
		movdw	ds:IS_lastReceiptTime, bxax
		pop	ax, bx
	;
	; Is this beginning of a packet?
	;
		cmp	al, IRLAP_EOF
		je	checkBusy
		cmp	al, IRLAP_BOF		; beginning of packet?
		jne	getPacketStartLoop	; no
	;
	; if we haven't handled the last frame with PF bit set, don't receive
	; any more frames
	;
		tst	ds:IS_recvCount
		jnz	getPacketStartLoop
	;
	; Don't let a discovery slot expire in the middle of receiving data
	;
		cmp	ds:IS_state, IMS_QUERY
		jne	notQuery

		call	StopSlotTimer

notQuery:
	;
	; Set Media busy flag in IS_status
	;
		BitSet	ds:IS_status, ISS_MEDIA_BUSY
	;
	; We've received the start of a data packet.  Loop through until
	; we get the end of the packet marker.
	;
		call	HandleDataPacket	;dx:si = packet
						;ax = frame header (A and C
						;  fields.
		jc	error			;handle error
		mov_tr	bp, si			;return ^ldx:bp = HugeLMem 
						;  packet
	;
	; increment IS_recvCount( explained in irlapInt.def )
	; only if PF bit is set, we increment the recv counter
	;
		test	al, mask ISCF_PFBIT
		jz	skipInc
	;
	; We handle I frames the same way we handle other frames, as long as
	; they have P/F bit set.
	;
	;	test	al, 00000001b		; iframe?
	;	jz	skipInc
	;
		
	lock	inc	ds:IS_recvCount
skipInc:
	;
	; If we're in the middle of discovery, we should restart the 
	; slot-timer, so that the next slot doesn't start, even if the slot 
	; timeout is reached.  This fixes the problem of discovery reply 
	; events slipping by a slot.
	;
		cmp	ds:IS_state, IMS_QUERY
		jne	exitCarryClear
		call	StartSlotTimerNoWait
exitCarryClear:
		clc
exit:
		.leave
		ret
checkBusy:
	;
	; Send an event that corresponds to the frame that would have been
	; supposedly received if memory error didn't happen.
	;
		test	ds:IS_extStatus, mask IES_MEMORY_SHORT
		jz	getPacketStartLoop
		push	ax, bx, cx, dx, bp, di, si
		mov	bx, ds:IS_eventThreadHandle
		mov	ax, ds:IS_lastCField
		mov	cx, ax			; cl = control field
		and	ah, mask IAF_CRBIT
		clr	dx, bp			; we have no frame actually
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage		
		pop	ax, bx, cx, dx, bp, di, si
		jmp	getPacketStartLoop
error:
	;
	; was that memory allocation error?
	;
		cmp	ax, IC_INSUFFICIENT_MEMORY
		je	busyCondition
if IRLAP_STAT
	;
	; CRC corrupted or frame is too large
	;
		inc	ds:IS_badCrc
		jmp	restart
skipBadCrc:
endif
	;
	; Is port closed?
	;
		cmp	ax, IC_PORT_CLOSED
		jne	restart
		stc
		jmp	exit
busyCondition:
	;
	; we enqueue a busy event
	; ds = station segment
	;
		call	IrlapBusyDetected
		jmp	restart
		
IrlapRecv	endp

if 0
;IrlapFlushOutput was replaced with IrlapWaitForOutput.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyStreamFlushed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine that is called whenever the output queue is empty.

CALLED BY:	IrlapFlushData
PASS:		cx	= SerialPortNum
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyStreamFlushed	proc	far
		shl	cx, 1			; SerialPortNum => offset into
		mov_tr	bx, cx			;           IrlapFlushSemArray
		GetDgroup ds, cx
		tst	ds:[irlapFlushSem][bx].Sem_value
		jz	done			; no one is blocked on queue
		VSem	ds, <[irlapFlushSem][bx]>, TRASH_AX
done:
		ret
NotifyStreamFlushed	endp
endif

IrlapResidentCode	ends

IrlapCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Blocks irlap event thread
		This is mainly used in testing in order to make irlap handle
		requests in deterministic manner.

CALLED BY:	GLOBAL
PASS:		bx	= client handle
RETURN:		nada
DESTROYED:	nada

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSuspend	proc	far
		uses	ds
		.enter
	;
	; suspend irlap event thread
	;
		GetDgroup ds, di
		mov	ds, ds:[bx].IC_station
		cmp	ds:IS_state, IMS_NDM	; if we are in NDM, we cannot
		je	done			; suspend
		PSem	ds, IS_suspendSem
			; irlap thread will be blocked on this semaphore
		clc	; next time it P'es it.
done:
		.leave
		ret
IrlapSuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unblocks irlap event thread
		This is mainly used in testing in order to make irlap handle
		requests in deterministic manner.

CALLED BY:	GLOBAL
PASS:		bx	= client handle
RETURN:		nada
DESTROYED:	nada

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapUnsuspend	proc	far
		uses	ds
		.enter
	;
	; unsuspend irlap event thread
	;
		GetDgroup ds, di
		mov	ds, ds:[bx].IC_station
		cmp	ds:IS_suspendSem.Sem_value, 0
		jg	done
		VSem	ds, IS_suspendSem
done:
		.leave
		ret
IrlapUnsuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Group all init functions together

CALLED BY:	DR_INIT
PASS:		nothing
RETURN:		carry set if driver intialization was unsuccessful
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Allocate hugelmem to use in this driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/24/94    	Initial version
	SJ	8/2/94		SocketDr interface change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapInit	proc	far
		uses 	ax, bx, cx, di, es
		.enter
	;
	; Create the global heap for this driver
	;
		GetDgroup es, ax
		mov	ax, IRLAP_MAX_NUM_BUFFER_BLOCK
		mov	bx, IRLAP_MIN_BLOCK_SIZE
		mov	cx, IRLAP_MAX_BLOCK_SIZE
		call	HugeLMemCreate			; bx = hugelmem handle
		jc	done				; carry set if error
		mov	es:hugeLMemHandle, bx
	;
	; Make sure that client table and semaphore table only contains 0
	;
CheckHack <not ( ( (size IrlapFlushSemArray) + (size IrlapClientArray)) and 1 )>
		clr	ax
		mov	cx, size IrlapClientArray
		add	cx, size IrlapFlushSemArray	; must be even number
		shr	cx, 1				; # bytes => # words
		mov	di, offset irlapFlushSem
		rep	stosw
	;
	; Load serial driver
	;
		push	ds, si
		mov	bx, handle serial
		call	GeodeInfoDriver
		movdw	bxax, ds:[si].DIS_strategy
		pop	ds, si
		movdw	es:[serialStrategy], bxax
		clc
done:
		.leave
		ret
IrlapInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit driver and clean up

CALLED BY:	DR_EXIT
PASS:		nothing
RETURN:		nothing
DESTROYED:	ds, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapExit	proc	far
EC <		WARNING	IRLAP_EXIT					>
	;
	; Deallocate huge lmem heap
	;
		GetDgroup ds, bx
		mov	bx, ds:hugeLMemHandle
		call	HugeLMemDestroy
		ret
IrlapExit	endp

;==========================================================================
;
;			   SocketDr Interface
;
;==========================================================================



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registration routine to call to register with this driver

CALLED BY:	IrlapStrategy
PASS:		bx    	= domain handle of the driver
 		ds:si 	= domain name (null terminated)
         	dx:bp 	= client entry point for SCO functions (virtual fptr)
		cl	= SocketDriverType ( always assumed to be SDT_LINK )

		IrlapSocketRegisterNear only:
		cx	= serial port to use
			  (or IRLAP_DEFAULT_PORT to read from .ini file)
			
RETURN:		bx	= client handle
		ch	= min header size for outgoing sequenced packets
		cl	= min header size for outgoing datagram packets
		carry set if error:
			ax = SocketDrError( SDE_ALREADY_REGISTERED or
					    SDE_MEDIUM_BUSY )
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketRegister	proc	far
EC <		cmp	cl, SDT_LINK					>
EC <		ERROR_NE IRLAP_INVALID_PARAM_VALUE			>
		mov	cx, IRLAP_DEFAULT_PORT
		call	IrlapSocketRegisterNear
		ret
IrlapSocketRegister	endp

IrlapSocketRegisterNear	proc	near
		uses	di, es
		.enter
	;
	; Register with Native Irlap driver
	;
		push	dx
		mov_tr	ax, cx				; ax = port to use
		mov	cx, segment IrlapSocketIndicationHandler
		mov	dx, offset IrlapSocketIndicationHandler
		mov	di, NIR_REGISTER_SOCKET_CLIENT
		call	IrlapNativeRegister		; bx = client handle
		pop	dx
		jc	done
	;
	; Access client handle and set SCO_ callback routine
	;	bx   = client handle
	;	dxbp = callback for SCO_ functions
	;
		call	InitializeSocketClient		; nothing changed
	;
	; allocate blockSem
	;
		GetDgroup es, cx
		mov_tr	di, bx
		clr	bx
		call	ThreadAllocSem			; bx = sem
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	es:[di].IC_connectBlockSem, bx
	
		clr	bx
		call	ThreadAllocSem			; bx = sem
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	es:[di].IC_discoveryBlockSem, bx
	
		clr	bx
		call	ThreadAllocSem			; bx = sem
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	es:[di].IC_addrDialogBlockSem, bx
		mov_tr	bx, di
	;
	; Determine min header sizes
	;
		mov	ch, size SequencedPacketHeader
		mov	cl, size IrlapDatagramHeader
		mov	dl, SDT_LINK
		clc
done:
		.leave
		ret
IrlapSocketRegisterNear	endp

endif ;_SOCKET_INTERFACE



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregisters a client and nukes the station entry
		corresponding to the client.

CALLED BY:	IrlapStrategy
PASS:		bx	= client handle
RETURN:		bx	= domain handle
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketUnregister	proc	far
		uses	di,es
		.enter
	;
	; Free block sem
	;
		GetDgroup es, di
		mov	di, bx
		mov	bx, es:[di].IC_connectBlockSem
		call	ThreadFreeSem
		mov	bx, es:[di].IC_discoveryBlockSem
		call	ThreadFreeSem
		mov	bx, es:[di].IC_addrDialogBlockSem
		call	ThreadFreeSem
		mov_tr	bx, di
	;
	; call IrlapNativeUnregister
	;
		call	IrlapNativeUnregister	; bx = domain handle
		.leave
		ret
IrlapSocketUnregister	endp

endif ;_SOCKET_INTERFACE



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Library requested datalink link connection

CALLED BY:	DR_SOCKET_CONNECT_REQUEST

PASS:		bx	= client handle to make connection to.
		cx	= timeout value
		ds:si	= buffer to hold a non-null terminated string for
			  addr to connect to.  IRLAP_CURRENT_LINK_ADDR to
			  reuse current connection( in this case, one should
			  pass IRLAP_CURRENT_ADDR_LEN in cx  )
 		ax	= addr string size

RETURN:		carry set if connection failed
			ax = SocketDrError
		otherwise
			ax = connection handle
DESTROYS:	nothing

PSEUDO CODE/STRATEGY:

	Find the state machine for this client
	Send connection.request to the state machine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketConnectRequest	proc	far
		uses	bx,cx,dx,bp,es,di,ds,si
		.enter
	;
	; If we already have a link connection, check if this address is
	; the address of our remote party, if so, connection is successful,
	; otherwise failure
	;
		push	cx			; save timeout
		GetDgroup es, cx
		mov	es, es:[bx].IC_station
	;
	; Grab mutex for Connection related operations
	;
		PSem	es, IS_connMutex
	;
	; We are about to attempt connecting to the remote machine
	;
		BitSet	es:IS_status, ISS_IRLAP_CONNECT_PROGRESS
	;
	; cx = number of discoveryLogs in discovery block
	; Are we already connected?
	;
		test	es:IS_status, mask ISS_SOCKET_LINK_OPEN
		jz	noLinkConnection
	;
	; Get number of entries in discovery block
	;
		push	ax, bx, es
		mov	bx, es:IS_discoveryLogBlock
EC <		tst	bx			; 0 if no discovery block>
EC <		ERROR_Z	IRLAP_STATION_CORRUPTED	; there can't be a connection >
		call	MemLock			; without a log entry
		mov	es, ax
		mov	cl, es:DLB_lastIndex	; cl = # of logs - 1
	;	inc	cl			; cl = # of logs
		clr	ch
		call	MemUnlock
		pop	ax, bx, es
		jmp	checkAddressAlias
noLinkConnection::
	;
	; Do discovery to get available remote devices
	;
		call	IrlapSocketDoDiscovery	; cx = number of discovery logs
		
checkAddressAlias:
	;
	; Launch address controller to decide where to connect to
	;
		call	ResolveConnectionAddress; cxbp	= device address to
		jc	addressNotFound		;         connect to
	;
	; If we already have socket LINK connection open,
	;	if (dev address to connect = current dest address)
	;	    do nothing
	;	else
	;	    return error
	; else
	;	Establish the initial connection
	;
		test	es:IS_status, mask ISS_SOCKET_LINK_OPEN
		jz	initialConnection
		cmpdw	cxbp, es:IS_destDevAddr
		jne	driverAlreadyUsed
		jmp	existingConnection
initialConnection:
	;
	; Initialize connection failure count
	; es = station
	;
		clr	es:IS_connFailureCount
	;
	; Call native connect request
	;	cxbp = 32 bit device address
	;
		mov	ax, es:IS_linkMgtMode		; IrlapConnectionType
		or	ax, mask ICF_SOCKET_INIT
	;
	; Prepare QOS parameter
	;
		push	ds, si
		segmov	ds, es, si
		mov	si, offset IS_qos
		movdw	ds:[si].QOS_devAddr, cxbp
		BitSet	ds:[si].QOS_flags, QOSF_DEFAULT_PARAMS
	;
	; Call native connect.request routine
	;
		call	IrlapNativeConnectRequest
		pop	ds, si
		jc	resourceError
	;
	; We P the semaphore with timeout = 0 to get rid of possible
	; semaphore value caused by previous request timeout 
	;
		GetDgroup ds, ax
		mov	bx, es:IS_clientHandle
		mov	bx, ds:[bx].IC_connectBlockSem
		clr	cx		; get rid of unnecessary sem count
		call	ThreadPTimedSem			; ax = trashed
	;
	; Wait here until connect.confirm;
	; ISS_SOCKET_LINK_OPEN is set on in connect.confirm
	; clear ISS_CONNECT_REQ_TIMED_OUT
	;
		BitClr	es:IS_status, ISS_CONNECT_REQ_TIMED_OUT
		pop	cx				; restore timeout
		call	ThreadPTimedSem			; ax = trashed
		cmp	ax, SE_TIMEOUT
		je	requestTimeout
	;
	; Inform the world that we are connected.
	;
		mov	bx, es:[IS_serialPort]		;bx = unit number
		clr	cx				;primary medium
		mov	di, DR_SERIAL_GET_MEDIUM
		call	ds:[serialStrategy]		;dxax = MediumType
		mov	cx, dx
		mov	dx, ax				;cxdx = MediumType
		mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_CONNECTED
	        mov     al, MUT_INT
		call	SysSendNotification
	;
	; All in a good day's work.
	;
		mov	ax, es:IS_clientHandle
		BitSet	es:IS_status, ISS_SOCKET_LINK_OPEN
		clc
done:
	;
	; Release the mutex semaphore
	;
		pushf
		BitClr	es:IS_status, ISS_IRLAP_CONNECT_PROGRESS
		VSem	es, IS_connMutex
		popf
		.leave
		ret
existingConnection:
		pop	cx
		mov	ax, SDE_CONNECTION_EXISTS
		stc
		jmp	done
addressNotFound:
		pop	cx
		mov	ax, SDE_CONNECTION_TIMEOUT
		stc
		jmp	done
requestTimeout:
		BitSet	es:IS_status, ISS_CONNECT_REQ_TIMED_OUT
		mov	bx, es:IS_clientHandle
		call	IrlapNativeDisconnectRequest
		mov	ax, SDE_CONNECTION_TIMEOUT
		stc
		jmp	done		
driverAlreadyUsed:
		pop	cx
		mov	ax, SDE_MEDIUM_BUSY
		stc
		jmp	done
resourceError:
		pop	cx
		mov	ax, SDE_INSUFFICIENT_MEMORY
		jmp	done
		
IrlapSocketConnectRequest	endp

endif ;_SOCKET_INTERFACE



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_SOCKET_DISCONNECT_REQUEST

CALLED BY:	IrlapStrategy

PASS:		bx = connection handle
		ax = SocketCloseType( ignored )
RETURN:		carry set on error; ax = SocketDrError
DESTROYS:	nothing

PSEUDO CODE/STRATEGY:

	Find the station to send the request to
	Send the disconnect.request to the station		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketDisconnectRequest	proc	far
		uses	ax,bx,cx,dx,es,ds,si,di
		.enter
	;
	; We need to reconnect in order to disconnect... ( we need to notify
	; the other side of socket link disconnection ); set connFailureCount
	; so that only 1 connection attempt is carriedi out.
	;
		GetDgroup ds, ax
		mov	ds, ds:[bx].IC_station
	;
	; Grab mutex for Connection related operations
	;
		PSem	ds, IS_connMutex
	;
	; If the link is not open, we don't need to close it
	;
		test	ds:IS_status, mask ISS_SOCKET_LINK_OPEN
		jz	done
		mov	ds:IS_connFailureCount, IRLAP_CONN_FAILURE_THRESHOLD
		call	IrlapSocketReconnect
		call	IrlapNativeDisconnectRequest
		BitClr	ds:IS_status, ISS_SOCKET_LINK_OPEN
	;
	; Tell the world we're disconnected.
	; : ds = station
	;
		mov	bx, ds:[IS_serialPort]		;bx = SerialPortNum
		segmov	es, ds, ax
		GetDgroup ds, ax			;ds = dgroup
		clr	cx				;primary medium
		mov	di, DR_SERIAL_GET_MEDIUM
		call	ds:[serialStrategy]		;dxax = MediumType
		mov	cx, dx
		mov	dx, ax				;cxdx = MediumType
	        mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_NOT_CONNECTED
	        mov     al, MUT_INT
		call	SysSendNotification
		clc
done:
	;
	; Release the mutex semaphore
	;
		pushf
		VSem	es, IS_connMutex
		popf
		.leave
		ret
IrlapSocketDisconnectRequest	endp

endif ;_SOCKET_INTERFACE



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	socket lib sends some data over a connection

CALLED BY:	DR_SOCKET_SEND_DATA

PASS:		ax    = timeout value
 		bx    = client handle( = connection handle )
 		cx    = size of buffer
		dx:bp = hugelmem buffer to send
		si    = SocketSendMode ( ignored )

RETURN:		carry set on error
			ax    = SocketDrError
			The buffer in dx:bp is not deallocated in case of
			an error.
		carry clear if successful( or at least if things look fine at
		the time this routine was called )
			The buffer in dx:bp is deallocated by the driver
			after it successfully sends data in it over connection.
			
DESTROYS:	nothing

PSEUDO CODE/STRATEGY:

	Segment the packet into appropriate sizes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketSendData	proc	far
		uses	di, ds, es
		.enter
	;
	; Check if there is a link
	;
		GetDgroup ds, di
		mov	ds, ds:[bx].IC_station
		test	ds:IS_status, mask ISS_SOCKET_LINK_OPEN
EC <		WARNING_Z IRLAP_DEBUG_THIS_NO_LINK_CONNECTION		>
		jz	noLinkConnection
	;
	; Extract the offset to real data
	;
		IrlapLockPacket	esdi, dxbp
		mov	ax, es:[di].PH_dataOffset ; ax = real data offset
		IrlapUnlockPacket dx
	;
	; We might need to fragment the packet
	;
		mov	di, NIR_DATA_REQUEST
		call	IrlapFragmentAndSend
EC <		ERROR_C	IRLAP_GENERAL_FAILURE				>
	;
	; Reconnect if there is currently no irlap connection
	;
		call	IrlapSocketReconnect
		clc
done:
		.leave
		ret
noLinkConnection:
		stc
		jmp	done
IrlapSocketSendData	endp

endif ;_SOCKET_INTERFACE



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketSendDatagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a datagram over IRLAP protocol
		
CALLED BY:	DR_SOCKET_SEND_DATAGRAM
PASS:		dx:bp = optr of buffer to send
 		cx    = size of buffer
 		bx    = client handle
 		ax    = offset of real data
 		ds:si = null term. string of address to send to
RETURN:		carry set on error
		ax = SocketDrError
DESTROYS:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketSendDatagram	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Get station segment
	;
		GetDgroup ds, ax
		mov	es, ds:[bx].IC_station		; es = station
	;
	; Copy information in DatagramPacketHeader into the data portion of
	; buffer.  We will send all the bytes after DatagramPacketHeader as
	; data.
	;
		IrlapLockPacket	dssi, dxbp
	;
	; Resolve address
	; : decide on address
	;
		call	IrlapSocketResolveDatagramAddress
		jc	cancelDatagram
	;
	; Send everything right after DatagramPacketHeader as data
	;
		mov	ax, ds:[si].PH_dataOffset
		sub	ax, size DatagramPacketHeader
		add	ds:[si].PH_dataSize, ax
		mov	ds:[si].IDH_info.IDI_dataOffset, ax
		mov	ds:[si].PH_dataOffset, size DatagramPacketHeader
	;
	; Insert Irlap datagram signature
	; : this identifies the first fragment of a packet
	;
		mov	ds:[si].IDH_info.IDI_sig1, IRLAP_DATAGRAM_SIG1
		mov	ds:[si].IDH_info.IDI_sig2, IRLAP_DATAGRAM_SIG2
	;
	; Adjust address offset
	;
		movm	ds:[si].IDH_info.IDI_addrSize, ds:[si].DPH_addrSize, al
		mov	al, ds:[si].DPH_addrOffset
		sub	al, size DatagramPacketHeader
		mov	ds:[si].IDH_info.IDI_addrOffset, al
	;
	; Swap destination and source
	;
		movm	ds:[si].IDH_info.IDI_localPort, \
			ds:[si].DPH_remotePort, ax
		movm	ds:[si].IDH_info.IDI_remotePort, \
			ds:[si].DPH_localPort, ax
		mov	ax, ds:[si].PH_dataOffset	; ax = data offset
		mov	cx, ds:[si].PH_dataSize		; cx = data size
		clc
cancelDatagram:
		IrlapUnlockPacket dx
		jc	addressUnreachable
		segmov	ds, es, bx
	;
	; Fragment and send the packet
	; ax = data offset
	; cx = size of data
	; dxbp = hugelmem buffer
	; ds = station segment
	;
		mov	di, NIR_UNITDATA_REQUEST
		call	IrlapFragmentAndSend		; nothing changed
done:
		.leave
		ret
addressUnreachable:
	;
	; Free the packet
	;
		movdw	axcx, dxbp
		call	HugeLMemFree
		mov	ax, SDE_DESTINATION_UNREACHABLE
		stc
		jmp	done
IrlapSocketSendDatagram	endp

endif ;_SOCKET_INTERFACE



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketResetRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset connection

CALLED BY:	DR_SOCKET_RESET_REQUEST
PASS:		ax	= connection handle
RETURN:		carry set if error
		ax	= SocketError
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketResetRequest	proc	far
		uses	ax, bx
		.enter
		mov_tr	bx, ax
		call	IrlapNativeResetRequest
		.leave
		ret
IrlapSocketResetRequest	endp

endif ;_SOCKET_INTERFACE



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets various information according to SocketGetInfoType

CALLED BY:	IrlapStrategy
PASS:		ax	= SocketGetInfoType
RETURN:		carry set if info not available
		ax or dx:ax = value depending on SocketGetInfoType
DESTROYED:	dx if not holding value

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketGetInfo	proc	far
		call	IrlapSocketGetInfoReal
			; this code is in irlapSocket.asm, at the end.
		ret
IrlapSocketGetInfo	endp

endif ;_SOCKET_INTERFACE



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketLinkActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by serial lurker after it loads the driver.

CALLED BY:	IrlapStrategy

PASS:		bx	= serial port number

RETURN:		carry set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set flag indicating lurker in use
		call IrlapNativeAddIrlapDomain to force irlap to add
			itself to socket lib as a domain and other setup stuff
		if fail, clear flag and return carry set

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketLinkActivated	proc	far
		uses	ax, cx, es
		.enter

	;
	; Set flag to indicate lurker in use so that lurker will be 
	; notified if opening the port results in failure.   Then have
	; Irlap register itself with the socket library.
	;
		GetDgroup	es, ax
		mov	es:[lurkerUsed], BB_TRUE

		mov	cx, bx				; cx = serial port
		call	IrlapNativeAddIrlapDomain
		jnc	exit
	;
	; Clear lurker flag
	;
		mov	es:[lurkerUsed], BB_FALSE
exit:
		.leave
		ret
IrlapSocketLinkActivated	endp

endif ;_SOCKET_INTERFACE



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketResolveAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve address for socket lib

CALLED BY:	DR_SOCKET_RESOLVE_ADDR

PASS:		ds:si 	= addr to resolve (non-null terminated)
		cx	= size of addr 
		dx:bp	= buffer for resolved address
		ax	= size of buffer

RETURN:		carry set if error
                   ax = SocketDrError
                        SDE_DESTINATION_UNREACHABLE
                        SDE_TEMPORARY_ERROR: address unreachable temporarily
                        SDE_INVALID_ADDR
                else carry clear
                   dx:bp = buffer filled w/non-null terminated addr if buffer
                           is big enough
                   cx    = size of resolved address
 
        NOTE:   Caller is responsible for checking if the address size returned
                exceeds the buffer size before assuming the buffer contains
                an address.
 
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketResolveAddr	proc	far
		.enter
		cmp	ax, cx
		jb	bufferTooSmall		; carry set
		push	cx, es, di, si
		movdw	esdi, dxbp
		rep	movsb
		pop	cx, es, di, si
bufferTooSmall:
		clc
		.leave
		ret
IrlapSocketResolveAddr	endp

endif ;_SOCKET_INTERFACE

; ****************************************************************************
; 
; 			   Native Interface
;
; ****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register with native Irlap driver

CALLED BY:	NIR_REGISTER_NATIVE_CLIENT or
		NIR_REGISTER_SOCKET_CLIENT

PASS:		ax	= serial port to use( or IRLAP_DEFAULT_PORT )
		cx:dx	= client entry point for indications( fptr.far )

		if NIR_REGISTER_SOCKET_CLIENT
			ds:si	= domain name
			bx	= domain handle
		otherwise ( NIR_REGISTER_NATIVE_CLIENT )
			ds:si	= 32 byte discovery info

RETURN:		bx	= client handle
		carry set on error
			bx = IrlapError( IE_MEM_ALLOC_ERROR,
					 IE_SHORT_OF_RESOURCE )

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version
	SJ	3/21/95		Rewrote using local variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeRegister	proc	far
		requestType	local	word	push	di
		comPort		local	word	push	ax
		domainHandle	local	word	push	bx
		clientCallback	local	dword
		uses	ax,cx,dx,di,si,es,ds,bp
		.enter
	;
	; Store parameters
	;
		movdw	clientCallback, cxdx
	;
	; Compute station size
	;
		mov	ax, size IrlapStation
		cmp	di, NIR_REGISTER_NATIVE_CLIENT
		je	skipLen
		segmov	es, ds, di
		mov	di, si

		SBStringLength			; cx = num of chars

		inc	cx			;      + null
		add	ax, cx
skipLen:
	;
	; Allocate the station size
	;
		push	cx
		mov	cl, mask HF_FIXED or mask HF_SHARABLE
		mov	ch, mask HAF_ZERO_INIT
		mov	bx, handle 0
		call	MemAllocSetOwner		; ax = segment
		jc	notEnoughMem			; bx = handle
		mov	es, ax				; es = segment
	;
	; initialize suspend semaphore
	;
		mov	es:IS_suspendSem.Sem_value, 1
	;
	; Initialize last receipt time
	;
		push	ax, bx
		call	TimerGetCount		; bxax = sys counter
		movdw	es:IS_lastReceiptTime, bxax
		mov	ax, IRLAP_CHECK_BUSY_TICKS
		call	TimerSleep		; we sleep here to check
		pop	ax, bx			; medium before we initiate the
	;					; very first transaction
	; record station handle
	;
		mov	es:IS_stationHandle, bx
		pop	cx
	;
	; Copy domain name into the station if this is socket client
	;
if _SOCKET_INTERFACE
		cmp	requestType, NIR_REGISTER_NATIVE_CLIENT
		je	skipDomainName
	;
	; ds:si = domain name
	; cx	= domain name size( incl null )
	;
		mov	di, offset IS_domainName	; es:di - domain name
		rep movsb
skipDomainName:
	;
	;	copy discovery info field if this is not socket client
	;

		cmp	requestType, NIR_REGISTER_SOCKET_CLIENT
		je	skipDiscoveryInfo
endif ;_SOCKET_INTERFACE

	;
	; ds:si	= 32 bytes discovery info
	;
		mov	cx, size DiscoveryInfo
		mov	di, offset IS_discoveryXIDFrame + \
			    offset IDXF_discoveryInfo
		rep movsb
		mov	es:[di].IS_discoveryXIDFrame.IDXF_version,
				IDXF_VERSION_1_0
skipDiscoveryInfo:
	;
	; Allocate a client structure for this client in irlapClientTable
	;
		segmov	ds, es, cx		; ds = station segment
		GetDgroup es, cx		; es = dgroup
		call	IrlapAllocClientEntry	; di = offset to free entry
		jc	noFreeEntry
	;
	; Fill in irlapClientTable entry
	;
		mov	ax, mask ICF_ACTIVE

if _SOCKET_INTERFACE
		cmp	requestType, NIR_REGISTER_SOCKET_CLIENT
		jne	notSocket
		or	ax, mask ICF_SOCKET
notSocket:

endif ;_SOCKET_INTERFACE

		mov	es:[di].IC_flags, ax
		segmov	es:[di].IC_station, ds, ax
	;
	; Allocate serial semaphore
	;
		mov	bx, 1
		call	ThreadAllocSem		; bx = semaphore
		mov	ax, handle 0
		call	HandleModifyOwner	; ax destroyed
		mov	ds:IS_serialSem, bx
	;
	; Set IS_connMutex
	;
		mov	ds:IS_connMutex.Sem_value, 1
	;
	; initialize recvCount
	;
		clr	ds:IS_recvCount
	;
	; Store socket lib related variables
	;
if _SOCKET_INTERFACE
		BitClr	ds:IS_status, ISS_SOCKET_CLIENT
		cmp	requestType, NIR_REGISTER_SOCKET_CLIENT
		jne	notSocketClient
		BitSet	ds:IS_status, ISS_SOCKET_CLIENT
		segmov	ds:IS_domainHandle, domainHandle, ax
notSocketClient:
endif ;_SOCKET_INTERFACE

	;
	; Store other variables
	;
		mov	ds:IS_maxIFrameSize, IRLAP_DEFAULT_IFRAME_SIZE
		mov	ds:IS_clientHandle, di
		movdw	ds:IS_clientCallback, clientCallback, bx
		movdw	ds:IS_serialStrategy, es:serialStrategy, bx
		segmov	ds:IS_hugeLMemHandle, es:hugeLMemHandle, bx
	;
	; Initialize the station
	;
		call	IrlapLinkInit		; nothing changed
		mov	cx, comPort
		call	IrlapInitStation	; nothing changed
		jc	resourceError
	;
	; return client handle
	;
		mov_tr	bx, di			; flags preserved
done:
		.leave
		ret
notEnoughMem:
		pop	cx
		mov	bx, IE_MEM_ALLOC_ERROR
		jmp	done
resourceError:
	;
	; clean up the mess
	; es = dgroup
	; ds = station segment
	; 1. deallocate serial sem
	; 2. deallocate client structure
	; 3. deallocate station segment
	;
		mov	bx, ds:IS_serialSem
		call	ThreadFreeSem
		mov	bx, ds:IS_clientHandle
		clr	es:[bx].IC_flags
		mov	bx, ds:IS_stationHandle
		call	MemFree
		mov	bx, IE_INITIALIZATION_ERROR
		stc
		jmp	done
noFreeEntry:
		mov	bx, IE_CANNOT_ALLOCATE_CLIENT
		jmp	done
		
IrlapNativeRegister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregisters a client and nukes the station entry
		corresponding to the client.

CALLED BY:	NIR_UNREGISTER, IrlapSocketUnregister
PASS:		bx	= client handle
RETURN:		if socket client:
			bx	= domain handle
		else
			bx destroyed
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeUnregister	proc	far
		uses	ax,ds,es
		.enter
	;
	; Sleep to allow data to be flushed before we close down the
	; serial port.  This allows the final disconnect frame to be
	; sent.
	;
		mov	ax, 15
		call	TimerSleep
	;
	; Find the station to delete and deref it
	;
		GetDgroup es, ax
		clr	es:[bx].IC_flags
		mov	ds, es:[bx].IC_station
	;
	; V the suspend semaphore in case irlap event thread is stuck there
	;
		VSem	ds, IS_suspendSem
	;
	; Kill server thread
	;
		call	IrlapCleanupServerThread
	;
	; Deallocate serial sem
	;
		mov	bx, ds:IS_serialSem
		call	ThreadFreeSem
	;
	; Deallocate discovery log block if there is one
	;
		mov	bx, ds:IS_discoveryLogBlock
		tst	bx
		jz	skipFreeLog
		call	MemFree
skipFreeLog:
	;
	; Return domain handle
	;
if _SOCKET_INTERFACE
		mov	bx, ds:IS_domainHandle
endif ;_SOCKET_INTERFACE
	;
	; Kill event thread ( station structure is not valid anymode )
	;
		call	IrlapCleanupEventThread
		clc
		.leave
		ret
IrlapNativeUnregister	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeAddIrlapDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forces IrLAP driver to add itself to the socket lib as a
		domain.  

		Does nothing if Socket Lib interface is not enabled.

CALLED BY:	NIR_ADD_IRLAP_DOMAIN
		IrlapSocketLinkActivated
PASS:		cx	= serial port to use (or 0 for default)
RETURN:		carry clear if successful
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/12/94    	Initial version
	jwu	12/13/94	Updated code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeAddIrlapDomain	proc	far
if _SOCKET_INTERFACE
		uses	ax,bx,cx,dx,si,di,ds,es,bp
		.enter
	;
	; Register a dummy library and get Irlap's domain name.
	;
		mov	bx, handle IrlapStrings
		call	MemLockShared
		mov	ds, ax
		mov	si, offset irlapDomainName
		mov	si, ds:[si]			; ds:si = domain name
		clr	bx, dx, bp	; dummy domain handle and client entry
		call	IrlapSocketRegisterNear	; bx	= client handle
						; ch, cl = min hdr sizes
	;
	; Register with the socket library.  
	;
		mov_tr	ax, bx				; ax = client handle
		mov	di, segment IrlapStrategy
		mov	es, di
		mov	bx, offset IrlapStrategy	; es:bx = IrlapStrategy
		mov	dl, SDT_LINK
		mov	di, SCO_ADD_DOMAIN
		mov	bp, handle 0			; bp <- driver handle
		call	SocketRegister			; bx = domain handle
							; cx:dx = SCO entry 
		jc	regFailed
	;
	; Record the values returned from SocketRegister in client entry
	;
		mov_tr	di, ax				; di = client handle
		GetDgroup ds, ax
		movdw	ds:[di].IC_scoCallback, cxdx
		mov	ds, ds:[di].IC_station
EC <		IrlapCheckStation	ds				>
		mov	ds:[IS_domainHandle], bx
	;
	; Unlock the string block
	;
		mov	bx, handle IrlapStrings
		call	MemUnlockShared
		clc
exit:		
		.leave
		ret

regFailed:
	;
	; Registration with socket library failed.  Clean up after ourselves.
	;
		mov_tr	bx, ax				; bx = client handle
		call	IrlapSocketUnregister
		stc
		jmp	exit
else
		ret
endif ;_SOCKET_INTERFACE
IrlapNativeAddIrlapDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeDiscoveryRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request discovery

CALLED BY:	NIR_DISCOVERY_REQUEST
PASS:		di	= NIR_DISCOVERY_REQUEST
			  maybe masked with IRLAP_URGENT_REQUEST
		bx	= client handle
		ch	= IrlapDiscoveryType
		cl	= IrlapUserTimeSlot
		if ch = IDT_ADDRESS_RESOLUTION
			dxbp	= target dev address
RETURN:		nothing
DESTROYED:	di
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeDiscoveryRequest	proc	far
		uses	ax,bx,ds
		.enter
	;
	; Get station segment
	;
		GetDgroup ds, ax
		mov	ds, ds:[bx].IC_station
	;
	; Send event to station
	;
		test	di, IRLAP_URGENT_REQUEST_MASK
		mov	di, mask MF_FORCE_QUEUE
		jz	cont
		or	di, mask MF_INSERT_AT_FRONT
cont:
		mov	bx, ds:IS_eventThreadHandle
		mov	ax, (ILE_REQUEST shl 8) or mask IRV_DISCOVERY
		call	ObjMessage
		
		.leave
		ret
IrlapNativeDiscoveryRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeDiscoveryResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Simply update discoveryInfo

CALLED BY:	NIR_DISCOVERY_RESPONSE
PASS:		di 	= NIR_DISCOVERY_RESPONSE
		bx	= client handle
		ds:si	= 32 byte DiscoveryInfo
		( no synchronization provided yet )
RETURN:		nothing
DESTROYED:	di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeDiscoveryResponse	proc	far
		uses	cx,si,es
		.enter
	;
	; Copy DiscoveryInfo to our buffer
	;
		GetDgroup es, ax
		mov	es, es:[bx].IC_station
EC <		IrlapCheckStation	es				>
		mov	di, offset IS_discoveryXIDFrame + \
			    offset IDXF_discoveryInfo
		mov	cx, (size DiscoveryInfo / 2)
		rep	movsw
		
		.leave
		ret
IrlapNativeDiscoveryResponse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeUnitdataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send unit data

CALLED BY:	NIR_UNITDATA_REQUEST
PASS:		di	= NIR_UNITDATA_REQUEST
			  IRLAP_URGENT_REQUEST_MASK ignored
		ax	= data offset into buffer
		bx	= client handle
		cx	= Data size
		dxbp	= data buffer ( HugeLMem buffer )
	if socket library interface
		si	= seqInfo

RETURN:		carry set if error
		di	= IrlapError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeUnitdataRequest	proc	far
		uses	ax,bx,cx,dx,bp,si,ds,es
		.enter
	;
	; Get station segment
	;
		GetDgroup es, di
		mov	ds, es:[bx].IC_station
	;
	; Check for data size
	;
		tst	cx
		jz	dataTooSmall
		cmp	cx, ds:IS_maxIFrameSize
		ja	dataTooBig
	;
	; Allocate a DatarequestParams
	;
		call	IrlapRecordDataRequest; dxbp = DataRequestParams chunk
		jc	memError
	;
	; Send the event
	;	cx	= data size
	;	dxbp	= DataRequestParams
	;
		inc	ds:IS_pendingData
		mov	di, mask MF_FORCE_QUEUE
		mov	bx, ds:IS_eventThreadHandle
		mov	ax, (ILE_REQUEST shl 8) or mask IRV_UNIT_DATA
		call	ObjMessage
done:
		.leave
		ret
dataTooSmall:
		popf
		mov	di, IE_DATA_FRAME_TOO_SMALL
		stc
		jmp	done
memError:
		popf
		mov	di, IE_MEM_ALLOC_ERROR
		jmp	done
dataTooBig:
		popf
		mov	di, IE_DATA_FRAME_TOO_BIG
		stc
		jmp	done
IrlapNativeUnitdataRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request link connection

CALLED BY:	NIR_CONNECT_REQUEST
PASS:		ax	= IrlapConnectionFlags
		bx	= client handle
		ds:si	= QualityOfService struct
RETURN:		carry clear if success
		carry set if error
			ax = error code
DESTROYED:	di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeConnectRequest	proc	far
		uses	ax, bx, ds, dx, es
		.enter
	;
	; Find the station for the client handle
	;
		GetDgroup es, di
		mov	bx, es:[bx].IC_station	; bx = station segment
		mov	es, bx
	;
	; Allocate a buffer for QualityOfService
	; and copy QOS in ds:si into it
	;
		call	AllocQOSBuffer		; cxbp = QOS hugelmem buffer
		jc	memError
	;
	; Pass connection request flag along
	;
		push	ax
		mov	ds, bx			; ds = station segment
		mov_tr	dx, ax			; dx = IrlapConnectionFlags
	;
	; Send event
	;
		mov	bx, ds:IS_eventThreadHandle
		test	di, IRLAP_URGENT_REQUEST_MASK
		mov	di, mask MF_FORCE_QUEUE
		jz	cont
		or	di, mask MF_INSERT_AT_FRONT
cont:
		mov	ax, (ILE_REQUEST shl 8) or mask IRV_CONNECT
		call	ObjMessage
		pop	ax
done:
		.leave
		ret
memError:
		mov	ax, IE_MEM_ALLOC_ERROR
		jmp	done
IrlapNativeConnectRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeConnectResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to connection request from remote machine

CALLED BY:	NIR_CONNECT_RESPONSE
PASS:		bx	= connection handle
		ds:si	= QualityOfService struct
RETURN:		carry clear if success
			ds:si = connection parameter part filled in
				QualityOfService struct
		carry set if fail
			ax = IrlapError
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeConnectResponse	proc	far
		uses	bx, di, ds
		.enter
	;
	; Find the station for the client handle
	;
		GetDgroup es, di
		mov	bx, es:[bx].IC_station	; bx = station segment
		mov	es, bx
	;
	; Allocate a buffer for QualityOfService
	;
		call	AllocQOSBuffer		; cxbp = QOS hugelmem buffer
		jc	memError
		push	ax
		mov	ds, bx			; ds = station segment
	;
	; Send event
	;
		mov	bx, ds:IS_eventThreadHandle
		test	di, IRLAP_URGENT_REQUEST_MASK
		mov	di, mask MF_FORCE_QUEUE
		jz	cont
		or	di, mask MF_INSERT_AT_FRONT
cont:
		mov	ax, (ILE_RESPONSE shl 8) or mask IRSV_CONNECT
		call	ObjMessage
		pop	ax
done:
		.leave
		ret
memError:
		mov	ax, IE_MEM_ALLOC_ERROR
		jmp	done
IrlapNativeConnectResponse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeSniffRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate sniff open procedure

CALLED BY:	NIR_SNIFF_REQUEST
PASS:		bx	= client handle
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeSniffRequest	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Find client
	;
		GetDgroup ds, cx
		mov	ds, ds:[bx].IC_station
	;
	; Send event
	;
		mov	bx, ds:IS_eventThreadHandle
		mov 	di, mask MF_FORCE_QUEUE
		mov	ax, (ILE_REQUEST shl 8) or mask IRV_SNIFF
		call	ObjMessage
		
		.leave
		ret
IrlapNativeSniffRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send data

CALLED BY:	NIR_DATA_REQUEST
PASS:		ax	= offset into buffer
		bx	= connection handle
		cx	= number of bytes to send
		dxbp	= user data buffer ( HugeLMem optr )
	if socket library interface
		si	= seqInfo
	else ( client is native client )
		si	= IrlapDataRequestType
		
RETURN:		carry set if error
		di	= IrlapError
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeDataRequest	proc	far
		uses	ax,bx,cx,dx,si,bp,ds,es
		.enter

		test	di, IRLAP_URGENT_REQUEST_MASK
		pushf
	;
	; Test if the data size is in right range
	;
		GetDgroup es, di
		mov	ds, es:[bx].IC_station
		tst	cx
		jz	dataTooSmall
		cmp	cx, ds:IS_maxIFrameSize
		ja	dataTooBig
	;
	; Create DataRequestParam buffer
	;
		call	IrlapRecordDataRequest	; dxbp = DataRequestParam chunk
		jc	memError
	;
	; Get station segment
	;
		mov	ds, es:[bx].IC_station
	;
	; Check for expedited data request.  In that case, send it as a
	; UI frame.
	;
if _SOCKET_INTERFACE
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jnz	cont
endif
		test	si, mask IDRT_EXPEDITED
		jz	cont
	;
	; Expedited data: send as UI frame with connection address
	;
		mov	ax, ILE_REQUEST shl 8 or mask IRV_UNIT_DATA
		jmp	sendEvent
	;
	; Send event
	;	cx	= dataSize
	;	dxbp	= parameter block
	;	es:bx	= IrlapClient
	;
cont::
		inc	ds:IS_pendingData
		inc	ds:IS_pendingConnectedData
		mov	ax, ILE_REQUEST shl 8 or mask IRV_DATA
sendEvent:
		mov	bx, ds:IS_eventThreadHandle
		mov	di, mask MF_FORCE_QUEUE
		popf
		jnz	urgentEvent

		call	ObjMessage
		jmp	done
urgentEvent:
		call	IrlapPostUrgentEvent
done:
		.leave
		ret
dataTooSmall:
		popf
		mov	di, IE_DATA_FRAME_TOO_SMALL
		stc
		jmp	done
memError:
		popf
		mov	di, IE_MEM_ALLOC_ERROR
		jmp	done
dataTooBig:
		popf
		mov	di, IE_DATA_FRAME_TOO_BIG
		stc
		jmp	done
IrlapNativeDataRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeStatusRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query the status of connection

CALLED BY:	NIR_STATUS_REQUEST
PASS:		bx	= connection handle 
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeStatusRequest	proc	far
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	; See if we have any unacknowledged data
	;
		GetDgroup ds, ax
		mov	ds, ds:[bx].IC_station
		mov	ax, mask CS_UNACKED_DATA
		tst	ds:IS_pendingData
		jnz	sendConfirm
		mov	bx, offset IS_store
		mov	cx, IRLAP_MAX_WINDOWS
checkForUnackedFrame:
		test	ds:[bx].IW_flags, mask IWF_VALID
		jnz	sendConfirm
		add	bx, size IrlapWindow
		loop	checkForUnackedFrame
		clr	ax
sendConfirm:
		call	StatusConfirm
		.leave
		ret
IrlapNativeStatusRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeQOSRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Currently not supported

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeQOSRequest	proc	far
	;
	; currently not supported by the state machine
	;
		ret
IrlapNativeQOSRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeResetRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request connection reset

CALLED BY:	NIR_RESET_REQUEST
PASS:		bx	= connection handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeResetRequest	proc	far
		uses	ax,bx,di,ds
		.enter
	;
	; Find the station for the client handle
	;
		GetDgroup ds, dx
		mov	ds, ds:[bx].IC_station
	;
	; Send event
	;
		mov	bx, ds:IS_eventThreadHandle
		test	di, IRLAP_URGENT_REQUEST_MASK
		mov	di, mask MF_FORCE_QUEUE
		jz	cont
		or	di, mask MF_INSERT_AT_FRONT
cont:
		mov	ax, (ILE_REQUEST shl 8) or mask IRV_RESET
		call	ObjMessage
		.leave
		ret
IrlapNativeResetRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeResetResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to reset request from remote machine

CALLED BY:	NIR_RESET_RESPONSE
PASS:		bx	= connection handle
RETURN:		nothing
DESTROYED:	di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeResetResponse	proc	far
		uses	ax,bx,ds
		.enter
	;
	; Find the station for the client handle
	;
		GetDgroup ds, ax
		mov	ds, ds:[bx].IC_station
	;
	; Send event
	;
		mov	bx, ds:IS_eventThreadHandle
		test	di, IRLAP_URGENT_REQUEST_MASK
		mov	di, mask MF_FORCE_QUEUE
		jz	cont
		or	di, mask MF_INSERT_AT_FRONT
cont:
		mov	ax, (ILE_RESPONSE shl 8) or mask IRSV_RESET
		call	ObjMessage
				
		.leave
		ret
IrlapNativeResetResponse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disconnect link	

CALLED BY:	NIR_DISCONNECT_REQUEST
PASS:		bx	= connection handle
RETURN:		nothing
DESTROYED:	di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeDisconnectRequest	proc	far
		uses	ax, bx, ds
		.enter
	;
	; Find the station for the client handle
	;
		GetDgroup ds, di
		mov	ds, ds:[bx].IC_station
	;
	; Set disconnect request flag
	;
		BitSet	ds:IS_status, ISS_PENDING_DISCONNECT
	;
	; Send the message to the station
	;
		mov	bx, ds:IS_eventThreadHandle
		test	di, IRLAP_URGENT_REQUEST_MASK
		mov	di, mask MF_FORCE_QUEUE
		jz	cont
		or	di, mask MF_INSERT_AT_FRONT
cont:
		mov	ax, ILE_REQUEST shl 8 or mask IRV_DISCONNECT
		call	ObjMessage
		clc
		.leave
		ret
IrlapNativeDisconnectRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeAbortSniff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort a sniff procedure
		This works for both sniff-open and conenct-to-sniffer

CALLED BY:	NIR_ABORT_SNIFF
PASS:		bx	= client handle
		di	= NIR_ABORT_SNIFF maybe masked by
			  IRALP_URGENT_REQUEST_MASK
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeAbortSniff	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Find the station for the client handle
	;
		GetDgroup ds, dx
		mov	ds, ds:[bx].IC_station
	;
	; Send the message to the station
	;
		mov	bx, ds:IS_eventThreadHandle
		test	di, IRLAP_URGENT_REQUEST_MASK
		mov	di, mask MF_FORCE_QUEUE
		jz	cont
		or	di, mask MF_INSERT_AT_FRONT
cont:
		mov	ah, ILE_CONTROL
		mov	al, IDC_ABORT_SNIFF
		call	ObjMessage
		clc
		
		.leave
		ret
IrlapNativeAbortSniff	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeSetSniffVariables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets variables in sniff procedure

CALLED BY:	NIR_SET_SNIFF_VARIABLES
PASS:		bx	= client handle
		ax	= sleep time in ticks
		di	= NIR_SET_SNIFF_VARIABLES
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeSetSniffVariables	proc	far
		uses	cx
		.enter
	;
	; Set sleep time
	;
		GetDgroup es, cx
		mov	es, es:[bx].IC_station
		mov	es:IS_sleepTime, ax
		.leave
		ret
IrlapNativeSetSniffVariables	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativeFlushDataRequests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush all data requests in the event queue
		Done in order to reinitialize Socket Link connection for
		example.
CALLED BY:	GLOBAL
PASS:		bx	= client handle
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativeFlushDataRequests	proc	far
		uses	ax,bx,di,ds
		.enter
	;
	; Find the client
	;
		GetDgroup ds, ax
		mov	ds, ds:[bx].IC_station
		mov	bx, ds:IS_eventThreadHandle
		mov	ah, ILE_CONTROL
		mov	al, IDC_START_FLUSH_DATA_REQUESTS
		mov	di, mask MF_FORCE_QUEUE
		call	IrlapPostUrgentEvent
	;
	; Send Stop flushing with MF_FORCE_QUEUE flag
	;
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, ILE_RESPONSE shl 8 or mask IRSV_STOP_FLUSH
		call	ObjMessage
		.leave
		ret
IrlapNativeFlushDataRequests	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativePrimaryRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upper layer requested to become the primary
CALLED BY:	NIR_PRIMARY_REQUEST
PASS:		bx	= connection (client) handle
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativePrimaryRequest	proc	far
		uses	ax,bx,cx,dx,si,di,bp,es,ds
		.enter
	;
	; Get station
	;
		GetDgroup ds, ax
		mov	ds, ds:[bx].IC_station
	;
	; Send event
	;
		mov	bx, ds:IS_eventThreadHandle
		mov 	di, mask MF_FORCE_QUEUE
		mov	ax, (ILE_LOCAL_BUSY shl 8) or mask ILBV_SXCHG_REQ
		call	ObjMessage
		.leave
		ret
IrlapNativePrimaryRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNativePrimaryResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to the remote station's request to become the
		primary
CALLED BY:	NIR_PRIMARY_RESPONSE
PASS:		bx	= connection(Client) handle
		cx	= PrimaryXchgFlag
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNativePrimaryResponse	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Get station
	;
		GetDgroup ds, ax
		mov	ds, ds:[bx].IC_station
	;
	; Send event
	;		
		mov	bx, ds:IS_eventThreadHandle
		mov 	di, mask MF_FORCE_QUEUE
		mov	ax, (ILE_RESPONSE shl 8) or mask IRSV_SXCHG
		call	ObjMessage
		.leave
		ret
IrlapNativePrimaryResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For the functions that are not supported yet

CALLED BY:	IrlapStrategy
PASS:		variable
RETURN:		variable
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Do nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	7/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketDoNothing	proc	far
		uses	ax
		.enter

EC <		WARNING	IRLAP_DO_NOTHING				>
		
		.leave
		ret
IrlapSocketDoNothing	endp
ForceRef	IrlapSocketDoNothing


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketNotSupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsupported functions return carry set and
		SDE_UNSUPPORTED_FUNCTION error
CALLED BY:	IrlapStrategy
PASS:		nothing
RETURN:		ax = SDE_UNSUPPORTED_FUNCTION
		carry set
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketNotSupported	proc	far
		stc
		mov	ax, SDE_UNSUPPORTED_FUNCTION
		ret
IrlapSocketNotSupported	endp


IrlapCommonCode	ends

