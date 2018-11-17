COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		intialization routines for IRLAP
FILE:		irlapInitExit.asm

AUTHOR:		Cody Kwok, Apr 15, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/15/94   	Initial revision

DESCRIPTION:
	Init and exit procedures for IRLAP driver.

	$Id: irlapInitExit.asm,v 1.1 97/04/18 11:56:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapCommonCode	segment	resource

; ****************************************************************************
; 
;  			     INIT ROUTINES
; 
; ****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapAllocClientEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a free entry in dgroup:irlapClientTable	

CALLED BY:	IrlapAddStation
PASS:		es	= dgroup
RETURN:		di	= offset to free client table entry
		carry set if all entries are filled
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapAllocClientEntry	proc	far
		uses	cx
		.enter

		mov	di, offset irlapClientTable
	; The client table can't start at 0
EC <		cmp	di, 0						>
EC <		ERROR_Z	-1						>
		mov	cx, IRLAP_MAX_NUM_CLIENTS		; counter
	;
	; Linear search through the table until we find an entry with
	; ICF_active bit clear
	;
searchLoop:
		test	es:[di].IC_flags, mask ICF_RESERVED
		jnz	next
		test	es:[di].IC_flags, mask ICF_ACTIVE
		clc
		jz	done
next:
		add	di, size IrlapClient
		loop	searchLoop
		stc
done:
		.leave
		ret
IrlapAllocClientEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapLinkInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the link
CALLED BY:	IrlapSetupPhysicalLayer
PASS:		es	= dgroup
		ds	= station
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Get the random seed
	Generate random device address

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapLinkInit	proc	near
		uses	ax
		.enter
	;
	; Initialize the random number generator
	;
		call	TimerGetCount	; initialize the random # generator
		mov	es:[randomSeed], ax		
	;
	; Generate device address
	;
		call	IrlapGenerateRandom32		; dxax = 32 bit addr
		movdw	ds:IS_devAddr, dxax

		.leave
		ret
IrlapLinkInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapInitStation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do misc initialization for a station that is not defined
		in any state
		Later may be we incorporate all the initialization in this
		routine

CALLED BY:	IrlapNativeRegister

PASS:		ds 	= station
		es	= dgroup
		cx	= serial port to use (or IRLAP_DEFAULT_PORT)

RETURN:		carry set if error
			the only error condition is "media busy"
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/ 6/94    	Initial version
	SJ	8/ 2/94		re-organized for dynamic allocation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapInitStation	proc	far
		uses	ax, bx, bx, bp, di, cx
		.enter
	;
	; Set initial values to be read in from geos.ini file
	;
		call	IrlapGetParamsFromInitFile
	;
	; Initialize threads
	;
		call	IrlapSetupServerThread		; nothing changed
		jc	mediaBusy
		call	IrlapSetupEventThread		; nothing changed
		call	ApplyDefaultConnectionParams	; nothing changed
		call	InitConnectionState
		mov	ds:IS_sleepTime, IRLAP_SLEEP_TIMEOUT_TICKS
	;
	; Set initial state
	;
		ChangeState	NDM, ds
mediaBusy:
		.leave
		ret
IrlapInitStation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapGetParamsFromInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize IS_serialPort and IS_connectionParams from the
		initfile or hard-coded defaults.

CALLED BY:	IrlapInitStation
PASS:		ds	= IrlapStation segment
		cx	= serial port to use (or IRLAP_DEFAULT_PORT)
RETURN:		These are initialized:
			ds:IS_serialPort
			ds:IS_connectionParams
DESTROYED:	nothing

CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapGetParamsFromInitFile	proc	near
		uses	ax,cx,dx,si,di,bp,ds,es
		.enter

		segmov	es, ds, ax		; es = station

if _SOCKET_INTERFACE
	;
	; get link mgt mode
	;
		clr	es:[IS_linkMgtMode]
endif ;_SOCKET_INTERFACE

	;
	; get serial port, unless one is already specified
	;
		mov	bx, handle IrlapStrings
		call	MemLock
		mov	ds, ax

		cmp	cx, IRLAP_DEFAULT_PORT
		je	getPort
		
		mov	es:[IS_serialPort], cx	
		jmp	getAddress
getPort:
	;
	; Get necessary strings from IrlapStrings
	;
		mov	cx, ds
		mov	si, offset portKeyword	
		mov	dx, ds:[si]		;cx:dx = portKeyword
		mov	si, offset irlapCategory
		mov	si, ds:[si]		;ds:si = irlapCategory
		mov	ax, SERIAL_COM1
		call	InitFileReadInteger	;ax = integer
		mov	es:[IS_serialPort], ax
getAddress:
if _SOCKET_INTERFACE
	;
	; If we are not socket client, skip this and leave whatever is
	; currently in DiscoveryInfo section of XID frame alone
	;
		test	es:IS_status, mask ISS_SOCKET_CLIENT
		jz	skipAddress
	;
	; ds = IrlapStrings segment
	; ds:si = irlapCategory
	;
		mov	si, offset irlapCategory
		mov	si, ds:[si]		; ds:si = irlapCategory
		mov	cx, ds
	;
	; read in address for the device
	; keyword = "address"
	;
		mov	di, offset addressKeyword
		mov	dx, ds:[di]		  ; cx:dx = portKeyword
		mov	di, offset IS_discoveryXIDFrame +\
			    offset IDXF_discoveryInfo
		mov	bp, IRLAP_ADDRESS_LEN
		call	InitFileReadString ;-> es:di = filled in; bx destroyed
					   ;   bx = destroyed
		jnc	addressFound	   ;   cx = num bytes read
	;
	; address not found( default address = "UNKNOWN" )
	;
		mov	si, offset defaultAddressStr
		mov	si, ds:[si]	   ; ds:si = default addr
		mov	cx, (8 / 2)	   ; length of default addr
		mov_tr	dx, di
		rep	movsw
		mov_tr	di, dx
		mov	cx, 7
addressFound:	
	;
	; es:di = IDXF_discoveryInfo field in IS_discoveryXIDFrame
	; cx    = length of address string
	;
		cmp	cx, IRLAP_ADDRESS_LEN; the max lenght of address field
		jb	rightSize
		dec	cx		; truncate last character if cx = 16
rightSize:
		add	di, cx
		clr	{byte}es:[di]	; store null terminator for string

skipAddress:
endif ;_SOCKET_INTERFACE

	;
	; es = station, ds = IrlapStrings segment
	;
		
	;
	; Get default negotiation parameters
	;
		call	InitializeNegotiationParams
	;
	; Unlock string block
	;
		mov	bx, handle IrlapStrings
		call	MemUnlock
		.leave
		ret
IrlapGetParamsFromInitFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeNegotiationParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get default connection parameters from .ini file or by other
		means, and put them into station structure in
		IS_connectionParams field.

CALLED BY:	IrlapGetParamsFromInitFile
		PrepareNegotiationParams

PASS:		es	= station
		ds	= IrlapStrings segment
RETURN:		nothing( IS_connectionParams filled in with connection params )
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeNegotiationParams	proc	far
		uses	ax, bx, si, di, cx, dx, bp
		.enter
	;
	; Parameters gotten from .ini file:
	;
	; 	Parameter		Default
	;	---------		-------
	; 	baudRate		9600 bps
	;	maxTurnaround		500 ms
	;	dataSize		64 bytes
	;	windowSize		1 frame
	; 	numBOFs			5
	;	minTurnaround		10 ms
	;   	linkDisconnect		3 secs
	;
		mov	di, offset IS_connectionParams	;es:di = IS_connParams
		mov	si, offset irlapCategory
		mov	si, ds:[si]			;ds:si = category str
		mov	cx, ds				;cx = IrlapStrings seg
	;
	; baudrate
	;
		mov	bp, offset baudrateKeyword
		mov	dx, ds:[bp]
		mov	ax, mask IPBR_9600BPS		
		call	InitFileReadInteger
		mov	es:[di].ICP_baudRate, al
	;
	; max turnaround
	;
		mov	bp, offset maxTurnaroundKeyword
		mov	dx, ds:[bp]
		mov	ax, mask IPMTA_500MS 		
		call	InitFileReadInteger
		mov	es:[di].ICP_maxTurnAround, al
	;
	; data size
	;
		mov	bp, offset dataSizeKeyword
		mov	dx, ds:[bp]
		mov	ax, mask IPDS_64BYTES
		call	InitFileReadInteger
		mov	es:[di].ICP_dataSizeIn, al
	;
	; window size
	;
		mov	bp, offset windowSizeKeyword
		mov	dx, ds:[bp]
		mov	ax, mask IPWS_1FRAME
		call	InitFileReadInteger
		mov	es:[di].ICP_windowSizeIn, al
	;
	; number of BOFs
	;
		mov	bp, offset numBOFsKeyword
		mov	dx, ds:[bp]
		mov	ax, mask IPNB_5BOF
		call	InitFileReadInteger
		mov	es:[di].ICP_numBof, al
	;
	; minimum turnaround
	;
		mov	bp, offset minTurnaroundKeyword
		mov	dx, ds:[bp]
		mov	ax, mask IPMT_10MS
		call	InitFileReadInteger
		mov	es:[di].ICP_minTurnAround, al
	;
	; link disconnect
	;
		mov	bp, offset linkDisconnectKeyword
		mov	dx, ds:[bp]
		mov	ax, mask IPLTT_3SEC
		call	InitFileReadInteger
		mov	es:[di].ICP_linkDisconnect, al
		.leave
		ret
InitializeNegotiationParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSetupEventThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup event thread if there isn't already one running.

CALLED BY:	IrlapInitStation, IrlapConnectRequest
PASS:		ds	= station
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
	If there is no thread running for this station,
		create an event thread with IRLAP as the owner
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSetupEventThread	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Check if there is already a thread running here
	;
		tst	ds:IS_eventThreadHandle
		jnz	skip
	;
	; sets up event-driven thread of IrlapProcessClass for the
	; state machine.
	;
		push	ds
		mov	bx, handle ui
		
		mov	bp, 400h			;use a 1k stack 
		movfptr	cxdx, IrlapProcessClass
		mov	si, handle 0
		mov	di, mask MF_CALL
	 	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER
		call	ObjMessage
		pop	ds				; restore station
		mov	ds:IS_eventThreadHandle, ax	; save thread handle

	;
	; Increase the priority of the event thread.
	;
		mov	bx, ax				;bx = thread handle
		mov	ah, mask TMF_BASE_PRIO
		mov	al, PRIORITY_HIGH
		call	ThreadModify			;bx = thread handle

		mov	ax, TGIT_QUEUE_HANDLE
		call	ThreadGetInfo
		mov	ds:IS_eventQueue, ax
	;
	; Allocate a queue for pending events (freed in IDCDetach)
	;
		push	bx				;save thread handle
		call	GeodeAllocQueue
		mov	ax, handle 0			;set owner to irlap
		call	HandleModifyOwner
		mov	ds:IS_pendingEventQueue, bx
		pop	bx				;bx = thread
	;
	; ds = station segment
	; This is done because MSG_META_ATTACH has no way to get params
	; (MSG_META_ATTACH is
	; the first msg)
	;
		mov	ax, ds				; ax = station segment
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
skip:
		.leave
		ret
IrlapSetupEventThread	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSetupServerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup a server thread so that irlap state machine can start
		receiving events.  If there is already a thread running for
		this station, don't create it.

CALLED BY:	IrlapInitStation
		IrlapEnableReceiver
PASS:		ds	= IrlapStation
		es	= dgroup
RETURN:		carry set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Create a thread that runs server loop in IrlapResidentCode

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 2/94    	Initial version
	jwu	12/13/94	Added serial lurker changes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSetupServerThread	proc	far
		uses	ax,bx,cx,dx,bp
		.enter
	;
	; Check if there is already a server thread running, if so skip
	; creating the thread
	;
		tst_clc	ds:[IS_serverThreadHandle]
		jnz	exit
		
		and	ds:[IS_status], not mask ISS_GOING_AWAY
	;
	; Open serial connection
	;
		mov	ax, mask SOF_TIMEOUT
		mov	bx, ds:[IS_serialPort]
		mov	cx, IRLAP_INPUT_BUFFER_SIZE
		mov	dx, IRLAP_OUTPUT_BUFFER_SIZE
		mov	bp, IRLAP_SERIAL_OPEN_TIMEOUT
		mov	di, DR_SERIAL_OPEN_FOR_DRIVER
		mov	si, handle 0
		call	es:[serialStrategy]
		jc	openFailed
	; 
	; setup the recv thread of the station
	;
		mov	al, PRIORITY_TIME_CRITICAL
 		mov	di, IRLAP_RECV_STACK_SIZE
		movfptr	cxdx, IrlapRecvLoop
		mov	bx, ds			; pass this to cx of RecvLoop
		mov	bp, handle 0		; owner = IRLAP
		call	ThreadCreate		; -> bx = thread handle, cx = 0
EC <		ERROR_C	IRLAP_UNABLE_TO_CREATE_THREAD			>
		mov	ds:[IS_serverThreadHandle], bx
		clc
exit:
		.leave
		ret
		
openFailed:
	;
	; Notify lurker that port was preempted by another geode, if
	; lurker loaded this driver.
	;
		clr	dl
		xchg	dl, es:[lurkerUsed]
		tst_clc	dl
		je	done

		mov	dx, GWNT_LOST_SERIAL_CONNECTION
		call	IrlapNotifyLurker
done:		
		stc
		jmp	exit
		
IrlapSetupServerThread	endp


; ****************************************************************************
; ****************************************************************************
; ***********************      EXIT ROUTINES       ***************************
; ****************************************************************************
; ****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapCleanupServerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kills the server thread

CALLED BY:	IrlapNativeUnregister
PASS:		ds	= station
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 8/94    	Initial version
	jwu	12/13/94	Added serial lurker changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapCleanupServerThread	proc	near
		uses	ax,bx,cx,dx,di
		.enter
	;
	; Set goingAway flag
	;
		BitSet	ds:IS_status, ISS_GOING_AWAY
	;
	; Wait untile server thread is done using serial driver.
	; or give enough time for the flag to be read by server thread
	;
		mov	bx, ds:IS_serialSem
		mov	cx, IRLAP_SERIAL_SEM_TIMEOUT
		call	ThreadPTimedSem			; ax destroyed
		call	ThreadVSem
	;
	; Close the port so that any threads blocking on it will exit
	;
		clr	bx
		xchg	bx, ds:IS_serialPort
		mov	ax, STREAM_DISCARD
		mov	di, DR_STREAM_CLOSE
		call	es:serialStrategy
	;
	; Return port to serial lurker, if necessary.
	;
		clr	dl
		xchg	dl, es:lurkerUsed
		tst	dl
		je	exit				
		
		mov	dx, GWNT_END_SERIAL_CONNECTION
		call	IrlapNotifyLurker
exit:
		.leave
		ret
IrlapCleanupServerThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapCleanupEventThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kills the thread that runs event loop

CALLED BY:	IrlapSocketUnregister
PASS:		ds	= station
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapCleanupEventThread	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	; Set disconnected state, as we're a goner
	;
		ChangeState	NDM, ds
	;
	; Send dummy event to flush pending real events
	;
		mov	bx, ds:IS_eventThreadHandle
		mov	ax, (ILE_CONTROL shl 8) or IDC_CHECK_STORED_EVENTS 
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; Send a MSG_META_DETACH to event thread
	;
		clr	bx
		xchg	bx, ds:IS_eventThreadHandle
		mov	ah, ILE_CONTROL
		mov	al, IDC_DETACH
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; Stop all the timers so that the kernel doesn't send message to a
	; dead thread
	;
		movdw	axbx, ds:IS_pTimer
		call	TimerStop
		
		movdw	axbx, ds:IS_fTimer
		call	TimerStop
		
		.leave
		ret
IrlapCleanupEventThread	endp


;
; Sniff open utilities
;

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapDisableReceiver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes serial port

CALLED BY:	SniffTImerExpiredSNIFF
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapDisableReceiver	proc	far
		uses	ax
		.enter
	;
	; Kill server thread
	;
		GetDgroup es, ax
		call	IrlapCleanupServerThread		
		.leave
		ret
IrlapDisableReceiver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapEnableReceiver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open serial port
		Start server thread

CALLED BY:	IDCAbortSniff
		SleepTimerExpiredSLEEP
PASS:		ds	= station segment
RETURN:		nothing
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		Open serial port
		Setup server thread accroding to the configuration of
		the station

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapEnableReceiver	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Setup server thread
	;
		GetDgroup es, ax
		call	IrlapSetupServerThread
		call	ApplyConnectionParameters
		.leave
		ret
IrlapEnableReceiver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapNotifyLurker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the serial lurker a notification about the port.

CALLED BY:	IrlapSetupServerThread
		IrlapCleanupServerThread

PASS:		dx	= GWNT_END_SERIAL_CONNECTION or
			  GWNT_LOST_SERIAL_CONNECTION
		es	= dgroup
		ds	= station

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapNotifyLurker	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		clrdw	bxsi				; no optr
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	bp, ds:[IS_serialPort]
		mov	ax, MSG_META_NOTIFY
		mov	di, mask MF_RECORD
		call	ObjMessage			; di = event handle

		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_NOTIFY_SERIAL_LURKER
		mov	cx, di				; cx = event handle
		clr	dx, bp				; no data nor flags
		call	GCNListSend
		
		.leave
		ret
IrlapNotifyLurker	endp


IrlapCommonCode	ends

