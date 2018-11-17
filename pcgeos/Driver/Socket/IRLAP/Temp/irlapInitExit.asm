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

	$Id: irlapInitExit.asm,v 1.1 97/04/18 11:56:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapInitExitCode	segment	resource

; ****************************************************************************
; ****************************************************************************
; ***********************      INIT ROUTINES       ***************************
; ****************************************************************************
; ****************************************************************************



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapLoadSerialDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads serial driver

CALLED BY:	IrlapRegisterLib

PASS:		es	= dgroup

RETURN:		carry set on error ( this means "couldn't open serial port" )

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		Init link
		Load serial driver
		Open serial connection

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC < serialDriverName	char	"serialec.geo", 0		>
NEC< serialDriverName	char	"serial.geo", 0			>
IrlapLoadSerialDriver	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
		mov	di, ds				; save station
	;
	; Load serial driver
	;
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		segmov	ds, cs, ax
		mov	si, offset serialDriverName
		clr	ax, bx
		call	GeodeUseDriver
		mov	es:serialHandle, bx
		call	FilePopDir
		jc	error
	;
	; Get serial driver's strategy routine
	;
		call	GeodeInfoDriver
		movdw	bxdx, ds:[si].DIS_strategy
		movdw	es:serialStrategy, bxdx
done:
		.leave
		ret
error:
		jmp	done
		
IrlapLoadSerialDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapAddStation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a station to IrlapInfoResource block

CALLED BY:	IrlapStrategy

PASS: 		bx    	= domain handle of the driver
		dx	= reserved client handle
			  (0 if nothing was reserved)
 		ds:si 	= domain name (null terminated)
		cx:di 	= callback for IRLAP native indications

RETURN:		bx	= client handle
		carry set on error

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapAddStation	proc	far
		domainHandle	local	word
		clientCallback	local	fptr
		uses	ax,	cx,dx,si,di,bp,ds,es
		.enter
	;
	; Store parameters
	;
		mov	domainHandle, bx
		movdw	clientCallback, cxdi
	;
	; Real station size = station size + domain name length
	;
		segmov	es, ds, di
		mov	di, si
		call	LocalStringLength		;-> cx = num of chars
		inc	cx				;   include null
		mov	ax, size IrlapStation		;
		add	ax, cx				; ax = memory needed
	;
	; Allocate a memory block for the station
	;
		push	cx
		mov	cl, mask HF_FIXED
		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
		call	MemAlloc			; ax = segment
		mov	es, ax				; bx = handle
		mov	es:IS_stationHandle, bx
		pop	cx				; cx = domain name len
	;
	; Copy the domain name into a newly allocated chunk
	;
		mov	di, offset IS_domainName
		rep	movsb
	;
	; Allocate a client structure for this client in dgroup
	;
		segmov	ds, es, di			; ds = station
		segmov	es, dgroup, di			; es = dgroup
		mov_tr	di, dx
		tst	di
		jnz	reservedClientHandle
		call	IrlapAllocClientEntry		; di = offset to client
		jc	error				;      table entry
reservedClientHandle:
		or	es:[di].IC_flags, mask ICF_active; native by default
		mov	es:[di].IC_station, ax		; store station segment
	;
	; Allocate serial semaphore
	;
		mov	bx, 1
		call	ThreadAllocSem			;-> bx = semaphore
		mov	ds:IS_serialSem, bx
	;
	; Initialize the station
	;
		call	IrlapLinkInit			; nothing changed
		call	IrlapInitStation		; nothing changed
	;
	; Store Interface information in station structure
	;
		mov	ds:IS_clientHandle, di		; store client handle
		segmov	ds:IS_domainHandle, domainHandle, bx
		movdw	ds:IS_clientCallback, clientCallback, bx
		clc
finish:
	;
	; di = real offset(from beginning of dgroup) to client entry
	;      in dgroup. (client entry is in dgroup:irlapClientTable)
	;
		mov_tr	bx, di
		.leave
		ret
error:
		jmp	finish
IrlapAddStation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapAllocClientEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a free entry in dgroup:irlapClientTable	

CALLED BY:	IrlapAddStation
PASS:		es	= dgroup
RETURN:		di	= offset to free client table entry
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
		mov	cx, IRLAP_MAX_NUM_CLIENTS		; counter
	;
	; Linear search through the table until we find an entry with
	; ICF_active bit clear
	;
searchLoop:
		test	es:[di].IC_flags, mask ICF_reserved
		jnz	next
		test	es:[di].IC_flags, mask ICF_active
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

CALLED BY:	IrlapSocketRegister

PASS:		ds 	= station
		es	= dgroup
RETURN:		nothing
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
	; Initialize threads
	;
		call	IrlapSetupEventThread		; nothing changed
		call	IrlapSetupServerThread		; nothing changed
		call	ApplyDefaultConnectionParams	; nothing changed
	;
	; Set initial values to be read in from geos.ini file
	;
		call	IrlapGetParamsFromInitFile
	;
	; Set negotiation parameters
	; : these parameters represent capacity of this machine
	;
		call	InitializeNegotiationParams
	;
	; Initialize connection related variables
	;
		mov	ds:IS_maxWindows, 3
		mov	ds:IS_maxIFrameSize, 4096
		call	InitConnectionState
		mov	ds:IS_sleepTime, IRLAP_SLEEP_TIMEOUT_TICKS
	;
	; Set initial state
	;
		ChangeState	NDM, ds
		.leave
		ret
IrlapInitStation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapGetParamsFromInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in parameters from geos.ini file and initialize station
		accrodingly
CALLED BY:	IrlapInitStation
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing
CODE/STRATEGY:
	1. get link mgt mode
	2. get irlap human-readable address

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
irlapKeyword		char	"irlap", 0
addressKeyword		char	"address", 0
portKeyword		char	"port",0
defaultAddressStr	char	"UNKNOWN", 0		; length = 8
defaultPort		SerialPortNum	SERIAL_COM1

IrlapGetParamsFromInitFile	proc	near
		uses	ax,cx,dx,si,di,bp,ds,es
		.enter
	;
	; get link mgt mode
	;
		clr	ds:IS_linkMgtMode
	;
	; get serial port
	;
		segmov	es,ds,cx
		mov	cx, cs
		mov	ds, cx
		mov	si, offset irlapKeyword
		mov	dx, offset portKeyword
		mov	ax, cs:[defaultPort]
		call	InitFileReadInteger
		mov	es:[IS_serialPort], ax
	;
	; read in address for the device
	; keyword = "address"
	;
		mov	dx, offset addressKeyword
		mov	di, offset IS_discoveryXIDFrame +\
			    offset IDXF_discoveryInfo
		mov	bp, 16
		call	InitFileReadString ;-> es:di = filled in; bx destroyed
					   ;   bx = destroyed
		jnc	addressFound	   ;   cx = num bytes read
	;
	; address not found( default address = "UNKNOWN" )
	;
		mov	si, offset defaultAddressStr
		mov	cx, (8 / 2)
		mov_tr	dx, di
		rep	movsw
		mov_tr	di, dx
		mov	cx, 7
addressFound:	
	;
	; es:di = IDXF_discoveryInfo field in IS_discoveryXIDFrame
	; cx    = length of address string
	;
		cmp	cx, 16		; 16 is the max lenght of address field
		jb	rightSize
		dec	cx		; truncate last character if cx = 16
rightSize:
		add	di, cx
		clr	{byte}es:[di]	; store null terminator for string
	;
	; es = station, ds = cs
	;
		
	;
	; Get the rest 16 bytes of information
	;
		
done::
		.leave
		ret
IrlapGetParamsFromInitFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeNegotiationParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get default connection parameters from .ini file or by other
		means, and put them into station structure in
		IS_connectionParams field.

CALLED BY:	Initialization routines
PASS:		ds	= station
RETURN:		nothing( IS_connectionParams filled in with connection params )
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeNegotiationParams	proc	near
		uses	si
		.enter
	;
	; Get parameters and fill in IS_connectionParams field
	; (for now I just hard code it)
	;
		mov	si, offset IS_connectionParams
		mov	ds:[si].ICP_baudRate, mask IPBR_9600bps or \
					      mask IPBR_2400bps
		mov	ds:[si].ICP_maxTurnAround, mask IPMTA_500ms
		mov	ds:[si].ICP_dataSize, mask IPDS_64bytes
		mov	ds:[si].ICP_windowSize, mask IPWS_4frame or \
						mask IPWS_3frame or \
						mask IPWS_2frame or \
						mask IPWS_1frame
		mov	ds:[si].ICP_numBof, mask IPNB_12BOF
		mov	ds:[si].ICP_minTurnAround, mask IPMT_001ms
		mov	ds:[si].ICP_pTimer, mask IPT_normal
		mov	ds:[si].ICP_linkDisconnect, mask IPLTT_3sec
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
		call	GeodeGetProcessHandle		;this process is parent
		mov	bp, 400h			;use a 1k stack 
		movfptr	cxdx, IrlapProcessClass
		mov	si, handle 0
		mov	di, mask MF_CALL
	 	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER
		call	ObjMessage
		pop	ds				; restore station
		mov	ds:IS_eventThreadHandle, ax	; save thread handle
		mov	bx, TGIT_QUEUE_HANDLE
		xchg	ax, bx
		call	ThreadGetInfo
		mov	ds:IS_eventQueue, ax
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

CALLED BY:	IrlapInitStation, IrlapConnectRequest
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSetupServerThread	proc	far
		uses	ax,bx,cx,dx,bp
		.enter
	;
	; Check if there is already a server thread running, if so skip
	; creating the thread
	;
		tst	ds:IS_serverThreadHandle
		jnz	skip
		
		and	ds:IS_status, not mask ISS_goingAway
	;
	; Open serial connection
	;
		mov	ax, mask SOF_TIMEOUT
		mov	bx, ds:IS_serialPort
		mov	cx, IRLAP_INPUT_BUFFER_SIZE
		mov	dx, IRLAP_OUTPUT_BUFFER_SIZE
		mov	bp, IRLAP_SERIAL_OPEN_TIMEOUT
		mov	di, DR_STREAM_OPEN
		call	{fptr.far}es:serialStrategy
		jc	skip
	; 
	; setup the recv thread of the station
	;
		mov	al, PRIORITY_UI
 		mov	di, IRLAP_RECV_STACK_SIZE
		movfptr	cxdx, IrlapRecvLoop
		mov	bx, ds			; pass this to cx of RecvLoop
		mov	bp, handle 0		; owner = IRLAP
		call	ThreadCreate		; -> bx = thread handle, cx = 0
EC <		ERROR_C	IRLAP_UNABLE_TO_CREATE_THREAD			>
		mov	ds:IS_serverThreadHandle, bx
skip:
		.leave
		ret
		
IrlapSetupServerThread	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The event handler of the new thread,  never
		returns.

CALLED BY:	MSG_META_ATTACH
PASS:		ds, es	= dgroup
		ax	= MSG_META_ATTACH
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapAttach	method dynamic IrlapProcessClass, MSG_META_ATTACH
		.enter
	;
	; Get the event queue of current thread
	;
		mov	ax, TGIT_QUEUE_HANDLE
		clr	bx			; get info about current thread
		call	ThreadGetInfo		; ax = queue handle
		mov	dx, ax			; dx = queue handle
		mov	ax, TGIT_THREAD_HANDLE	; get the current thread handle
		call	ThreadGetInfo
		mov	bp, ax			; bp = thread handle
	;
	; Get the station segment.
	; Should be the second message ever sent to this thread.
	;
		mov_tr	bx, dx			;
		call	QueueGetMessage		; ax = event handle
		mov	bx, ax			; bx = event handle
		call	ObjGetMessageInfo	; ax = station segment
		mov	ds, ax			;
	;	mov	ds:IS_eventQueue, dx	; store queue handle(done)
		call	ObjFreeMessage		; free this dummy
		call	IrlapEventLoop		; infinite loop
		.leave				; not reached
		ret
IrlapAttach	endm


; ****************************************************************************
; ****************************************************************************
; ***********************      EXIT ROUTINES       ***************************
; ****************************************************************************
; ****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapDeleteStation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a station structure from the list of stations and
		Destroys any thing that blongs to that station.

CALLED BY:	IrlapSocketUnregister
PASS:		bx = client handle for the station
RETURN:		bx = domain handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapDeleteStation	proc	far
		uses	ax
		.enter
	;
	; Find the station to delete and deref it
	;
		segmov	es, dgroup, ax		; es:[bx] = client entry
		clr	es:[bx].IC_flags
		mov	ds, es:[bx].IC_station
	;
	; Kill the threads
	;
		call	IrlapCleanupServerThread
		call	IrlapCleanupEventThread
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
		mov	bx, ds:IS_domainHandle
		clc
		.leave
		ret
IrlapDeleteStation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapCleanupServerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kills the server thread

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
IrlapCleanupServerThread	proc	near
		uses	ax,bx,di
		.enter
	;
	; Wait until somebody is done using serial 
	;
		mov	bx, ds:IS_serialSem
		mov	cx, IRLAP_SERIAL_SEM_TIMEOUT
		call	ThreadPTimedSem
		BitSet	ds:IS_status, ISS_goingAway
		call	ThreadVSem			; ax destroyed
	;
	; Set goingAway flag
	;
		or	ds:IS_status, mask ISS_goingAway
	;
	; Close the port so that any threads blocking on it will exit
	;
		clr	bx
		xchg	bx, ds:IS_serialPort
		mov	ax, STREAM_DISCARD
		mov	di, DR_STREAM_CLOSE
		call	{fptr.far}es:serialStrategy

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
	; Send a MSG_META_DETACH to event thread
	;
		clr	bx
		xchg	bx, ds:IS_eventThreadHandle
		mov	ah, ILE_CONTROL
		mov	al, IDC_DETACH
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
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
		segmov	es, dgroup, ax
		call	IrlapCleanupServerThread		
		.leave
		ret
IrlapDisableReceiver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapEnableReceiver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open serial port
		Start server thread

CALLED BY:	SleepTimerExpiredSLEEP
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
		segmov	es, dgroup, ax
		call	IrlapSetupServerThread
		call	ApplyConnectionParameters
		.leave
		ret
IrlapEnableReceiver	endp



IrlapInitExitCode	ends

