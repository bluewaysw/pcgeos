COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		TCP/IP Driver	
FILE:		tcpipEntry.asm

AUTHOR:		Jennifer Wu, Jul  5, 1994

ROUTINES:
	Name			Description
	----			-----------
GLOBAL:
	TcpipStrategy		Entry point for all TCP/IP driver function
				calls

	TcpipClientStrategy	Entry point for all TCP/IP driver SCO calls

INTERNAL:	
	TcpipDoNothing		For unsupported SocketFunctions/SCOs
	TcpipError		For unsupported calls that should not be
				called
	
  Driver Functions:	see socketDr.def for descriptions
	TcpipInit		
	TcpipExit		
	TcpipSuspend
	TcpipRegister
	TcpipUnregister
	TcpipAllocConnection
	TcpipLinkConnectRequest	Establish a connection to another geos device
	TcpipDataConnectRequest	Establish a regular TCP connection
	TcpipStopDataConnect
	TcpipDisconnectRequest
	TcpipSendData
	TcpipStopSendData
	TcpipSendDatagram
	TcpipResetRequest
	TcpipAttach
	TcpipReject
	TcpipGetInfo			

	TcpipGetNothing
	TcpipGetMediaList
	TcpipGetMediumAndUnit
	TcpipGetAddrCtrl
	TcpipGetAddrSize
	TcpipGetLocalAddr
	TcpipGetRemoteAddr
	TcpipGetAddrCommon
	TcpipGetMediumConnection

	TcpipSetOption
	TcpipGetOption
	TcpipResolveAddr
  	TcpipStopResolve
	TcpipCloseMedium
	TcpipMediumConnectRequest
	TcpipSetMediumOption

  Extended Tcp Driver Functions: 	see ip.def for descriptions
	TcpipSendRawIp

  SCO Functions:	see socketInt.def for descriptions
	TcpipGetProtocol
	TcpipAddDomain
	TcpipLinkOpened
	TcpipLinkClosed
	TcpipReceivePacket

  Subroutines:
	TcpipGainAccess
	TcpipReleaseAccess
	TcpipGetMinDgramHdr

	TcpipRegisterNewClient
	TcpipCheckLinkIsMain

	TcpipCreateInputQueue
	TcpipDestroyInputQueue
	TcpipDestroyInputQueueCB

	TcpipCreateThreadAndTimer
	TcpipDestroyThreadAndTimer

	TcpipSendMsgToDriverThread	
	TcpipQueueSendDataRequest
	TcpipSendDatagramCommon
	TcpipDetachAllowed

	TcpipResolveIPAddr
	TcpipLoadResolver
	TcpipGetDefaultIPAddr
	TcpipCheckValidIPAddr

	ECCheckClientHandle
	ECCheckIPAddrSize		Verify size of IP address
	ECCheckIPAddr			Verifes address is not a broadcast,
					multicast or experimental address.
	ECCheckCallerThread		Warn if called by TCP thread

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/ 5/94		Initial revision

DESCRIPTION:
	TCP/IP driver info and strategy routine.

	$Id: tcpipEntry.asm,v 1.1 97/04/18 11:57:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;		Dgroup
;---------------------------------------------------------------------------

ResidentCode 	segment resource

	DriverTable	SocketDriverInfoStruct <
			<TcpipStrategy,
			0,
			DRIVER_TYPE_SOCKET>,
			TcpipClientStrategy,
			(mask SDPO_TYPE or mask SDPO_ADDRESS \
			 or mask SDPO_SUBLAYER or mask SDPO_MAX_PKT),
			0	
			>

ResidentCode	ends

ForceRef DriverTable

idata	segment
	;
	; Need this so we can call superclass because kernel code expects
	; first word in segment of process class to be a handle.  As we
	; created this in a driver, this isn't automatically true for us.
	; 
	myHandle	hptr	handle 0

	;
	; Minimum reserved datagram header.  Put in dgroup to make
	; retrieval faster.
	;
	minDgramHdr	byte	TCPIP_DATAGRAM_PACKET_HDR_SIZE

idata ends

ForceRef myHandle

udata	segment

	driverThread	hptr.HandleThread 	; current driver thread
	clientThread	hptr.HandleThread	; current clients' thread
	timerHandle	hptr 		
	hugeLMemBlock	hptr 		; global data storage unit

	inputQueue	optr		; input packet queue

	socketBlock	hptr 		; LMem block for all socket info
	socketList	lptr 		; chunk handle to socket list 
	linkTable	optr 		; table of physical link connections
	
	taskSem		hptr		; mutex for tcp actions that need
					;  to be synchronized

	regSem		hptr		; mutex for registration
	regStatus	RegisterStatus	; registration status of driver	 
	clients		TcpipClientInfo	; info about registered clients

	; DHCP variables.
	dhcpThread	hptr		; thread for doing dhcp
	dhcpStrategy	fptr		; Link driver entry point
	dhcpCookie	dword		; Cookie toIPINIT keep track of our session
	dhcpRenewTime	dword		; Seconds until renew
	dhcpRebindTime	dword		; Seconds until rebind
	dhcpExpireTime	dword		; Seconds until expire
	dhcpTimerId	hptr
	dhcpTimerHandle	hptr
	dhcpServerIp	IPAddr		; IP of server that gave us the lease

EC <	dropCount	word		; input packets dropped due to lack >
EC <					;  of space in TCP's input queue    >

udata	ends

;
; LMem for Tcp's input queue.
; 
InputQueue	segment lmem LMEM_TYPE_GENERAL, mask LMF_RETURN_ERRORS

InputQueue	ends

;---------------------------------------------------------------------------
;			Ini File Strings (have to be SBCS)
;---------------------------------------------------------------------------
Strings	segment	lmem	LMEM_TYPE_GENERAL
	;
	; Indicates name of link driver TCP/IP driver should use for 
	; establishing connections and the domain of that link driver.
	;
	categoryString		chunk.char "tcpip",0
		localize not
	linkDriverKeyString 	chunk.char "link",0
		localize not
    linkDriverPermanentKeyString    chunk.char "linkPermName",0
        localize not
	linkDomainKeyString 	chunk.char "linkDomain",0
		localize not

Strings	ends


;---------------------------------------------------------------------------
;		Strategy Routines
;---------------------------------------------------------------------------

ResidentCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all TCP/IP driver calls.

CALLED BY:	Socket Library
		SocketIsDisconnectedLink

PASS:		di	= SocketFunction or TcpipFunction
		see specific routine for other arguments

RETURN:		carry set if some error occurred
		see specific routines for return values

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If the function is a TcpipFunction, the high bit will be
		set so shifting left will set the carry.  This is used to
		determine which function table to use.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipStrategy	proc	far
		uses	di
		.enter
	
	;
	; Call the procedure to process the driver function, making sure
	; it is in range.
	;
		mov	ss:[TPD_dataAX], ax		
		mov	ss:[TPD_dataBX], bx
		
		shl	di, 1				; index (4-byte) fptrs
		jc	tcpipFunction
		
		cmp	di, size driverProcTable
		jae	notSupported
		
		movdw	bxax, cs:driverProcTable[di]
callIt:		
		call	ProcCallFixedOrMovable
exit::
		.leave
		ret

tcpipFunction:
		cmp	di, size tcpipProcTable
		jae	notSupported
		movdw	bxax, cs:tcpipProcTable[di]
		jmp	callIt				
notSupported:
		mov	ax, SDE_UNSUPPORTED_FUNCTION
		stc
		jmp	exit

TcpipStrategy	endp

driverProcTable		fptr.far	\
		TcpipInit,			; DR_INIT
		TcpipExit,			; DR_EXIT
		TcpipSuspend,			; DR_SUSPEND
		TcpipDoNothing,			; DR_UNSUSPEND
		TcpipRegister,			
		TcpipUnregister,		
		TcpipAllocConnection,		
		TcpipLinkConnectRequest,	
		TcpipDataConnectRequest,	
		TcpipStopDataConnect,
		TcpipDisconnectRequest,		
		TcpipSendData,			
		TcpipStopSendData,
		TcpipSendDatagram,		
		TcpipResetRequest,		
		TcpipAttach,			
		TcpipReject,			
		TcpipGetInfo,			
		TcpipSetOption,			
		TcpipGetOption,			
		TcpipResolveAddr,		
		TcpipStopResolve,
		TcpipCloseMedium,		
		TcpipMediumConnectRequest,
		TcpipDoNothing,			; DR_SOCKET_MEDIUM_ACTIVATED
		TcpipSetMediumOption,
		TcpipResolveLinkLevelAddress
	
tcpipProcTable		fptr.far	\
		TcpipSendRawIp			; DR_TCPIP_SEND_RAW_IP		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipClientStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all TCP/IP client operations.

CALLED BY:	Client Link Driver

PASS:		di	= SocketClientOperation
		see specific routine for other arguments
		
RETURN:		carry set if some error occurred
		see specific routines for return values

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipClientStrategy	proc	far
		uses	di
		.enter	

	;
	; Make sure the operation code is in range.
	;
		cmp	di, SocketClientOperation
		jae	badCall
	;
	; Call the procedure to process the client operation.
	;	
		
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		shl	di, 1				; index (4-byte) fptrs
		movdw	bxax, cs:clientProcTable[di]
		shr	di, 1				; restore di
		call	ProcCallFixedOrMovable
exit::
		.leave	
		ret

badCall:
EC<		ERROR	ERROR_INVALID_SOCKET_CLIENT_OPERATION	>	
NEC<		stc						>
NEC<		jmp	short exit				>

TcpipClientStrategy	endp

clientProcTable		fptr.far	\
		TcpipGetProtocol,		; SCO_GET_PROTOCOL
		TcpipAddDomain,			; SCO_ADD_DOMAIN
		TcpipError,			; SCO_LINK_OPENED
		TcpipError,			; SCO_LINK_CLOSED
		TcpipReceivePacket,		; SCO_RECEIVE_PACKET
		TcpipError,			; SCO_CONNECT_REQUESTED
		TcpipError,			; SCO_CONNECT_CONFIRMED
		TcpipError,			; SCO_CONNECT_FAILED
		TcpipError,			; SCO_EXCEPTION
		TcpipError,			; SCO_RECEIVE_URGENT_DATA
		TcpipError			; SCO_GET_INFO

;---------------------------------------------------------------------------
;		Driver Functions
;---------------------------------------------------------------------------

;
; Put this in fixed resource because we use this as the dummy 
; strategy routine for the loopback link driver.
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just clear the carry and pretend everything went well.

CALLED BY:	TcpipStrategy (DR_UNSUSPEND,
			       DR_SOCKET_LINK_ACTIVATED)

PASS:		nothing

RETURN:		carry clear		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDoNothing	proc	far
		
		clc
		ret

TcpipDoNothing	endp

.ioenable


COMMENT @----------------------------------------------------------------------

FUNCTION:	TcpipReceiveInterrupt

DESCRIPTION:	Intercept the video mode interrupt and fix up the
		power management.

CALLED BY:	INT 10h

PASS:
	al - video mode

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
TcpipReceiveInterrupt	proc	far

	pushf
	push	ax, bx, cx, dx, si, di, bp, ds, es
	;call	SysEnterInterrupt
	cld					;clear direction flag

	; scheduled receiving data
	mov	ax, MSG_TCPIP_START_RECEIVE_ASM
		
	push	bx
	mov	bx, handle dgroup
	call	MemDerefDS
	mov	bx, ds:[driverThread]
	
EC <		Assert	thread	bx				>		

	mov	cx, di			; cx = connection
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	bx

	;call	SysExitInterrupt
	pop	ax, bx, cx, dx, si, di, bp, ds, es
	popf
	ret

TcpipReceiveInterrupt	endp


	SetGeosConvention

TCPIPRECEIVESTOP	proc	far	connection:word
;regs		local	PMRealModeRegister
								uses	cx, ax, ds
newBuffer 	local	optr		
		.enter

		mov	cx, connection
		mov	bx, handle dgroup
		call	MemDerefES

EC <		WARNING	TCPIP_RECEIVE_STOP		>

	; close the socket on host side
		mov	ax, 1007
		int	0xB0
done:
		.leave
		ret
TCPIPRECEIVESTOP	endp


TCPIPRECEIVESTART	proc	far	connection:word
;regs		local	PMRealModeRegister
								uses	di, si, ds
newBuffer 	local	optr		
		.enter

		mov	bx, handle dgroup
		call	MemDerefES

closeLoop:
	; get next receive buffer size
		mov	ax, 1006		; get next receive close socket
		int	0xB0

		cmp	cx, 0
		je	recvLoop		; branch, no more closed links

	; send close to socket library

	;
	; close sockets.
	;		
if 0
		push	ax, dx

		mov	bx, handle dgroup
		call	MemDerefES

		mov	ax, cx			; ax = connection
		mov	cx, SCT_HALF	; cx = SocketCloseType

		push	es
		mov	di, SCO_CONNECTION_CLOSED
		movdw	bxdx, es:[clients].TCI_data.CI_entry	
		pushdw	bxdx
		mov	bx, es:[clients].TCI_data.CI_domain
		mov	dx, 11
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	
		pop	es

		pop	ax, dx				; ax = data size
							; dx = connection
endif

		jmp	closeLoop
recvLoop:
;EC <		WARNING	TCPIP_RECEIVE_START_LOOP		>


	; get next receive buffer size
		mov	ax, 1004		; get recv buf size
		int	0xB0

	; done if size 0 or below
		cmp	cx, 0
		je	done

doRecv:
		mov	ax, cx	; size now in ax

	; alloc buffer

		mov	dx, 0

	;
	; Allocate a new data buffer of packetSize bytes and fill in 
	; packet header.
	;
		mov	cx, es:[clients].TCI_data.CI_domain
		push	ax, cx, ds
		add	ax, size SequencedPacketHeader+200
		mov	bx, es:[hugeLMemBlock]
		mov	cx, HUGELMEM_ALLOC_WAIT_TIME
		call	HugeLMemAllocLock		; ^lax:cx = buffer
							; ds:di = buffer
		movdw	newBuffer, axcx
		segmov	es, ds				; es:di = buffer
		pop	ax, cx, ds		; size, domain, array segment
		jc	done				

		mov	es:[di].PH_flags, PacketFlags <0, 0, PT_SEQUENCED>
		mov	es:[di].PH_dataOffset, \
				size SequencedPacketHeader
		mov	es:[di].PH_dataSize, ax
		mov	es:[di].PH_domain, cx
		mov	dx, connection
		mov	es:[di].SPH_link, dx	
	;
	; Copy packetSize bytes of input data into the new buffer.
	;
		push	ax, dx				
		push 	di
		add	di, size SequencedPacketHeader	; es:di = place for data
		; ax is size in bytes

		mov	cx, ax
		mov	ax, 1005		; get recv buf size
		int	0xB0

		pop	di

		; fill in link
		mov	es:[di].SPH_link, dx	

		movdw	bxdx, newBuffer
		call	HugeLMemUnlock

	;
	; Deliver the data.
	;		
		mov	cx, bx				; ^lcx:dx = data buffer
		mov	bx, handle dgroup
		call	MemDerefES
		push	es
		mov	di, SCO_RECEIVE_PACKET
		movdw	bxax, es:[clients].TCI_data.CI_entry
		call	ProcCallFixedOrMovable
		pop	es
		pop	ax, dx				; ax = data size
							; dx = connection

		; try next block
		jmp	recvLoop
error:

done:
		.leave
		ret
TCPIPRECEIVESTART	endp
	SetDefaultConvention

ResidentCode	ends

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the carry to indicate that some error occurred.

CALLED BY:	TcpipClientStrategy (SCO_CONNECT_REQUESTED,
				     SCO_EXCEPTION,
				     SCO_RECEIVE_URGENT_DATA,
			             SCO_GET_INFO)

PASS:		nothing

RETURN:		carry set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipError	proc	far
		stc
		ret
TcpipError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the TCP/IP driver.

CALLED BY:	TcpipStrategy (DR_INIT)

PASS:		nothing

RETURN:		carry set if driver initialization failed
		carry clear if initialization succeeded

DESTROYED:	ax, cx, dx, di, si, ds, es (allowed)

PSEUDO CODE/STRATEGY:
		Create the HugeLMem
		Create the socket list 
		Create link table
		Initialize IP (reassembly queue and ID only)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version
	jwu	10/31/96		Added input queue

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipInit	proc	far
		uses	bx
		.enter
	
	;	
	; Check host call if network interface is available
	;
		mov	ax, 1 
		mov cx, 1
		int	0xB0

		cmp	ax, 0
		jne	error

	;
	; Hook into callback
	;
		segmov	es, <segment ResidentCode>
		mov	bx, offset ResidentCode:TcpipReceiveInterrupt
		mov	ax, 2
		int	0xB0

	;
	; Create the input queue.
	;
		mov	bx, handle dgroup
		call	MemDerefES		
		call	TcpipCreateInputQueue
		jc	error
	;
	; Create the hugeLMem.
	;
		clr	ax			; use default maximum
		mov	bx, MIN_OPTIMAL_BLOCK_SIZE
		mov	cx, MAX_OPTIMAL_BLOCK_SIZE
		call	HugeLMemCreate		; bx <- handle
		jc	error

		mov	es:[hugeLMemBlock], bx
	;
	; Create the socket list, link table and semaphores.
	;
		;call	TSocketCreateSocketList
		jc	error
		
		;call	LinkCreateLinkTable	; (expects es = dgroup)
		jc	error
	
		mov	bx, 1
		call	ThreadAllocSem
		mov	es:[regSem], bx
	
		mov	ax, handle 0
		call	HandleModifyOwner

		mov	bx, 1
		call	ThreadAllocSem
		mov	es:[taskSem], bx

		mov	ax, handle 0
		call	HandleModifyOwner
	;
	; Initialize the IP and UDP protocols.  None necessary for TCP.
	;
		;call	IpInit			
		;call	UdpInit
	;
	; Find out the minimum datagram header required by the link
	; driver.
	;
		;call	TcpipGetMinDgramHdr	

ifdef PROTO_CONFIG_ALLOWED		
		;call	TcpipConfigureProtocols
endif		

ifdef WRITE_LOG_FILE
		call	LogOpenFile
endif		
		
		clc				; init succeeded
		jmp	exit
error:
		call	TcpipExit
		stc
exit:
		.leave
		ret
TcpipInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the TCP/IP driver.

CALLED BY:	TcpipStrategy (DR_EXIT)
		TcpipInit

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, ds, es (allowed)

PSEUDO CODE/STRATEGY:
		Close any open link connections and unload link drivers
		Free link table
		Free HugeLMem (this will free all allocated chunks also)
		Free LMem holding socket info
NOTES:
		Socket library must have already unregistered TCP/IP driver.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version
	ed	7/10/00			Stop DHCP timers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipExit	proc	far

	; Reset the callback interrupt

		clr	bx
		mov	es, bx
		mov	ax, 2
		int	0xB0

		mov	bx, handle dgroup
		call	MemDerefDS		
	;
	; Destroy input queue, freeing any packets still in it.
	;
		call	TcpipDestroyInputQueue
	;
	; If hugeLMem, socket block, or link table not allocated,
	; TCP was never loaded, so we can skip EC checks.
	;
		tst	ds:[hugeLMemBlock]
		jz	exit

		tst	ds:[socketBlock]
		jz	freeHugeLMem		

		tst	ds:[linkTable].handle
		jz	freeSocketBlock

EC <		tst	ds:[regStatus]					>
EC <		WARNING_NE TCPIP_EXITING_WITH_CLIENTS_REGISTERED	>

EC <		;call	TSocketGetNumSockets				>
EC <		tst	cx						>
EC <		WARNING_NE TCPIP_EXITING_WITH_CONNECTIONS_OPEN		>
	;	
	; Free up memory used by the driver.
	;
		;call	IpExit			; may destroy all except bp
		
		mov	bx, ds:[regSem]
		call	ThreadFreeSem

		mov	bx, ds:[taskSem]
		call	ThreadFreeSem

ifdef WRITE_LOG_FILE
		call	LogCloseFile
endif

		;call	LinkTableDestroyTable

		mov	bx, ds:[dhcpTimerHandle]
		tst	bx
		jz	freeSocketBlock
		mov	ax, ds:[dhcpTimerId]
		call	TimerStop
freeSocketBlock:
		mov	bx, ds:[socketBlock]
		call	MemFree
freeHugeLMem:
		mov	bx, ds:[hugeLMemBlock]
		call	HugeLMemDestroy		
exit:
		ret
TcpipExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Only allow TCP/IP driver to be suspended if there are
		no connections.

CALLED BY:	TcpipStrategy (DR_SUSPEND)

PASS:		cx:dx	= buffer to place reason for refusal, if refused

RETURN:		carry set if suspension refused
			cx:dx	= buffer filled with null-terminated reason
				(DRIVER_SUSPEND_ERROR_BUFFER_SIZE bytes long)
		carry clear if suspension approved

DESTROYED:	ax, di (allowed)

PSEUDO CODE/STRATEGY:
		Find out if any connections exist
	
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipSuspend	proc	far
		uses	bx, cx, si, ds, es
		.enter
		
		Assert 	buffer, cxdx, DRIVER_SUSPEND_ERROR_BUFFER_SIZE	

		mov	es, cx				
		mov	di, dx				; es:di = buffer
	;
	; Find out if any connections exist.
	;
		;call	TSocketGetNumSockets		; cx <- # connections
		clc					; assume okay
		jcxz	exit
	
	;
	; Fill in reason for refusing the suspension.
	;
		mov	bx, handle Strings
		call	MemLock				
		mov	ds, ax
		mov	si, offset refuseSuspendString
		mov	si, ds:[si]			; ds:si = string
		
EC <		call	LocalStringSize		; cx = size w/o null	>
EC <		cmp	cx, DRIVER_SUSPEND_ERROR_BUFFER_SIZE		>
EC <		ERROR_AE TCPIP_REFUSE_SUSPEND_STRING_TOO_LONG		>

		LocalCopyString
		
		call	MemUnlock
		stc					; refuse suspension
exit:
		.leave
		ret
TcpipSuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Socket library is registering driver.

CALLED BY:	TcpipStrategy (DR_SOCKET_REGISTER)

PASS: 		bx	= domain handle of the driver
		cl	= SocketDriverType or TcpipDriverType
		ds:si	= null-term domain name (ignored by TCP/IP driver)
		dx:bp	= client entry point for SCO functions

RETURN:		carry set if error
		ax	= SocketDrError  (SDE_MEDIUM_BUSY)
		else
		bx	= client handle
		ch	= min header size for outgoing sequenced packets
		cl	= min header size for outgoing datagram packets.

DESTROYED:	di (preserved by caller)

PSEUDO CODE/STRATEGY:
		Attempt to create thread first so there's no need to
		cleanup if thread creation fails.  Registration only fails
		if another client of the same type is registered, in which
		case a thread already exists so there's no need to cleanup.

		Save geode handle of socket library
		Save domain handle of the driver
		Save client entry point for SCO functions 

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipRegister	proc	far
		uses	es
		.enter

EC <		call	ECCheckCallerThread			>

EC <		push	bx, si					>
EC <		movdw	bxsi, dxbp				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>

	;
	; Create thread for TCP/IP driver and timer if needed.
	; Do this first (see notes in header).
	;
		call	TcpipCreateThreadAndTimer
		mov	ax, SDE_INSUFFICIENT_MEMORY	; expect the worst...
		jc	exit
	;
	; Attempt to register the client.
	;
		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx 		

		call	TcpipRegisterNewClient		; bx = client handle
		jc	exit				; ax = SocketDrError
	;
	; Return amounts of space to reserve.
	;
		mov	ch, TCPIP_SEQUENCED_PACKET_HDR_SIZE
		mov	cl, es:[minDgramHdr]
		clc		
exit:
		.leave
		ret

TcpipRegister	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Socket library is unregistering driver.

CALLED BY:	TcpipStrategy (DR_SOCKET_UNREGISTER)

PASS:		bx	= client handle

RETURN:		bx	= domain handle

DESTROYED:	di (preserved by strategy routine)

PSEUDO CODE/STRATEGY:
		If raw IP client, allow unregister always.
		If link client, allow unregister if no link connection.
		If data client, allow unregister if no data connections.

NOTES:
		Client handle is a bit mask of the type of client that
		is registered.

		ThreadVSem returns a value in AX so have to include in 
		'.uses' line.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version
	jwu	3/27/95			Refuse unreg if have connections

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipUnregister	proc	far
		uses	ax, cx, es
		.enter

EC <		call	ECCheckCallerThread				>
EC <		call	ECCheckClientHandle				>

	;
	; Only process unregistration if it is allowed for this client.
	;
		mov	cx, bx				; cx = client handle
		mov	bx, handle dgroup
		call	MemDerefES
		
		mov	bx, es:[regSem]
		call	ThreadPSem			; get exclusive access

EC <		test	es:[regStatus], cx				>
EC <		ERROR_Z	TCPIP_NOT_REGISTERED				>
	;
	; Raw clients are always allowed to unregister.  If a connection 
	; of the client's type does not exist, allow the unregistration.
	;
		mov	bx, offset TCI_rawIp
		cmp	cx, mask RS_RAW_IP
		je	allowUnreg

		mov	bx, offset TCI_data
		mov	ax, SDT_DATA
		cmp	cx, mask RS_DATA
		je	findIt

		mov	bx, offset TCI_link
		mov	ax, SDT_LINK
findIt:
		;call	TSocketFindSocketOfDomain	
		jc	freeSem				; connection exists
allowUnreg:
	;
	; Unregister the client.  If no longer registered, destroy the 
	; thread and timer.  Any open links will be closed when thread
	; is being destroyed. CX = client handle, 
	;
		not	cx				
		and 	es:[regStatus], cx
		jnz	getDomain

		call	TcpipDestroyThreadAndTimer
getDomain:
		mov	cx, es:[clients][bx].CI_domain	; cx = domain handle
		clc					; unreg processed
freeSem:
		mov	bx, es:[regSem]
		call	ThreadVSem			; flags preserved
		mov	bx, cx				; bx = domain handle
		
		.leave
		ret 

TcpipUnregister	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipAllocConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate an empty socket.

CALLED BY:	TcpipStrategy (DR_SOCKET_ALLOC_CONNECTION)

PASS:		bx	= client handle

RETURN:		carry set if unable to allocate
		ax	= SocketDrError (SDE_INSUFFICIENT_MEMORY)
		else carry clear
		ax	= connection handle

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/29/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipAllocConnection	proc	far

		push	bx
EC <		call	ECCheckCallerThread				>
EC <		call	ECCheckClientHandle				>

		;call	TSocketCreateConnection		; ax = error or handle
		mov	ax, HF_NC_ALLOC_CONNECTION
		int	HOST_INT
		cmp	bx, 0
		je	success
		mov	ax, SDE_INSUFFICIENT_MEMORY
success:
		pop	bx
		ret
TcpipAllocConnection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipLinkConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish a connection to the well-known geos port.

CALLED BY:	TcpipStrategy (DR_SOCKET_LINK_CONNECT_REQUEST)

PASS:		cx	= timeout value (in ticks)
		bx	= connection handle
		ds:si	= buffer holding a non-null terminated string for
			  addr to connect to
		ax	= addr string size

RETURN:		carry set if connection failed
		ax = SocketDrError
		bx = connection handle (if ax = SDE_CONNECTION_EXISTS)
		otherwise
		carry clear

DESTROYED:	ax, bx if not returned
		di preserved by TcpipStrategy

PSEUDO CODE/STRATEGY:
		If loopback address, return SDE_INVALID_ADDR
		Set up parameters for remote port number and
		call TcpipDataConnectRequest
		If failed and error is SDE_CONNECTION_EXISTS
		find connection and return its handle
		if connection exists but isn't open, return SDE_TEMPORARY_ERROR

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version
	jwu	8/ 1/96			Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipLinkConnectRequest	proc	far
		uses	dx, bp
		.enter

EC <		call	ECCheckCallerThread			>

EC <		push	bx					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx					>

EC < 		call	ECCheckIPAddrSize			>
	;
	; Loopback addresses are not allowed for link connections.
	;
		push	si
		mov	dx, ds:[si]
		inc	si
		inc	si				; ds:si = link part
		add	si, dx				; ds:si = ip addr
		mov	dl, ds:[si]
		cmp	dl, LOOPBACK_NET
		pop	si				; ds:si = addr string
		jne	notLoopback
	;
	; Destroy connection before returning error.
	; 
		mov	cx, bx				; cx = connection handle
		;call	TSocketDestroyConnection
		mov	ax, SDE_INVALID_ADDR_FOR_LINK
		stc
		jmp	exit
notLoopback:
	;
	; Set the port numbers and then treat this as a normal
	; connect request. 
	;
		mov	dx, GEOS_WELL_KNOWN_TCP_PORT	; dx = remote port
		mov	bp, dx				; bx = local port
		call	TcpipDataConnectRequest
		jnc	exit
	;
	; If failed because connection exists, find the connection
	; and return its handle.
	;
		cmp	ax, SDE_CONNECTION_EXISTS
		jne	error

		;call	TSocketFindOpenConnection	; bx = connection handle
		jnc	error
		mov	ax, SDE_TEMPORARY_ERROR
error:
		stc
exit:
		.leave
		ret		
TcpipLinkConnectRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDataConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish a regular data connection.

CALLED BY:	TcpipStrategy (DR_SOCKET_DATA_CONNECT_REQUEST)
		TcpipLinkConnectRequest

PASS:		cx	= timeout value (in ticks)
		bx	= connection handle
		ds:si	= buffer holding a non-null terminated string for
			  addr to connect to
		ax	= addr string size
		dx	= remote port number
		bp	= local port number (0 is not a valid port)

RETURN:		carry set if connection failed
		ax = SocketDrError 
			(SDE_CONNECTION_EXISTS
			 SDE_INSUFFICIENT_MEMORY
			 SDE_CONNECTION_TIMEOUT
			 SDE_CONNECTION_REFUSED
			 SDE_CONNECTION_RESET
			 SDE_CONNECTION_RESET_BY_PEER
			if link not already open, then also:
			 SDE_DRIVER_NOT_FOUND
			 SDE_ALREADY_REGISTERED 
			 SDE_MEDIUM_BUSY	
			 SDE_LINK_OPEN_FAILED)


		otherwise carry clear

DESTROYED:	di (preserved by TcpipStrategy)
		ax (if not returned)

PSEUDO CODE/STRATEGY:
		Check to make sure connection doesn't already exist		
		Create the connection to specified port
		If link connection is closed, open it
		Start a timer to stop connection process if it takes too long
		Tell the driver's thread to establish the connection
		Block calling thread until connection has been established.
		
		If socket is now in open state, return connection handle
		If socket is in closed state, return SocketDrError based
			on error stored in the socket state and destroy
			the socket

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version
	jwu	8/ 1/96			Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDataConnectRequest	proc	far
		uses	bx, cx, si, ds, es
		.enter
EC <		call	ECCheckCallerThread			>

EC <		push	bx					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx					>

EC <		call	ECCheckIPAddrSize			>
EC <		call	ECCheckIPAddr				>

		mov	di, ds:[si]
		inc	si
		inc	si
		add	si, di
		movdw	disi, ds:[si]			; disi = remote addr

	;
	; If interrupted, return SDE_INTERRUPTED.  Set state 
	; to TSS_CONNECTING while we have access to the socket.
	;
		;push	ds, si
		;call	TSocketLockInfoExcl
		;mov	si, ds:[bx]
		;mov	ds:[si].TS_state, TSS_CONNECTING
		;mov	ax, ds:[si].TS_error
		;call	TSocketUnlockInfoExcl		; preserves flags
		;pop	ds, si

		;cmp	ax, SDE_INTERRUPTED
		;je	errorDestroy

	;
	; Have driver's thread establish the connection.
	;
		;mov	di, bx				; di = connection handle
		;mov	ax, MSG_TCPIP_OPEN_CONNECTION_ASM
		;call	TcpipSendMsgToDriverThread

		mov	ax, 1002
		int	0xB0


	; 
	; Send confirmation of data connect request.  Okay to 
	; keep socket info block locked.  Client should not be
	; calling us back for anything.
	;
		mov	ax, bx
		mov	bx, handle dgroup
		call	MemDerefES
		pushdw	es:[clients].TCI_data.CI_entry
		mov	bx, es:[clients].TCI_data.CI_domain
		mov	di, SCO_CONNECT_CONFIRMED
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		clc
		jmp	exit	

errorDestroy:
		mov	cx, bx				; cx = connection handle
		;call	TSocketDestroyConnection
		stc
exit:		
		.leave
		ret

TcpipDataConnectRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipStopDataConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt opening of a connection or close the connection
		if it has already been opened.

CALLED BY:	TcpipStrategy (DR_SOCKET_STOP_DATA_CONNECT)
			      (DR_SOCKET_STOP_LINK_CONNECT)

PASS:		bx	= connection handle

RETURN:		carry set if no such connection
		ax	= SocketDrError 
				(SDE_INVALID_CONNECTION_HANDLE)
		else, carry clear

DESTROYED:	di (allowed)
		ax if not returned

PSEUDO CODE/STRATEGY:
		Set TS_error to SDE_INTERRUPTED for other routines
		to check.

		If connection is opening or open, 
			reset connection

NOTES:
		If link connection is open or opening, it will stay
		open.  No good way to detect this and stop it because
		we can't tell which link is being used by the connection.

		DO NOT alter the state so that TSocketIsDisconnected
		knows whether to notify with SCO_CONNECT_FAILED or
		SCO_CONNECTION_CLOSED.


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/29/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipStopDataConnect	proc	far

		uses	cx, dx, di
		.enter
	;
	; Make sure connection exists.
	;
		mov	ax, bx
		;call	TSocketFindHandle		; destroys cx
		mov	ax, SDE_INVALID_CONNECTION_HANDLE
		jc	exit
	;
	; Set error to SDE_INTERRUPTED.  Do NOT alter the state.
	; [See header notes.]
	;
		;call	TSocketLockInfoExcl
		;mov	di, ds:[bx]
		;mov	dx, SDE_INTERRUPTED
		;mov	ds:[di].TS_error, dx
		;mov	al, ds:[di].TS_state
		;call	TSocketUnlockInfoExcl
	;
	; Send a reset request if the state is not TSS_NEW, 
	; TSS_CLOSED or TSS_DEAD.
	;

EC <		cmp	al, TSS_CONNECT_REQUESTED		>
EC <		ERROR_E TCPIP_BAD_SOCKET_STATE			>

		CheckHack <TSS_CLOSED lt TSS_CONNECT_REQUESTED>
		CheckHack <TSS_CONNECT_REQUESTED lt TSS_DEAD>
		CheckHack <TSS_DEAD eq TcpSocketState - 1>

		cmp	al, TSS_NEW
		je	exit				; carry clear

		cmp	al, TSS_CLOSED
		jae	exit				; carry clear

		mov	di, bx
		mov	ax, MSG_TCPIP_RESET_CONNECTION_ASM
		call	TcpipSendMsgToDriverThread
		clc
exit:
		.leave
		ret
TcpipStopDataConnect	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a connection

CALLED BY:	TcpipStrategy (DR_SOCKET_DISCONNECT_REQUEST)

PASS:		bx	= connection handle
		ax	= SocketCloseType

RETURN:		carry set if error
		ax = SDE_INVALID_CONNECTION_HANDLE
		

DESTROYED:	di (preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:
		Verify that the connection exists
		If connection is not open, do nothing
		Set socket state to disconnecting
		Queue msg for driver to process disconnection
		if full close block calling thread until connection 
			has been disconnected 
			Set destruct timer for connection to be destroyed
		else, we're done

NOTE:
		Using SCT_FULL will cause the caller to block until
		the 2MSL timer has expired.  Use SCT_FULL if caller
		wants to reopen connection after this returns.  Otherwise,
		the reopen may fail because the connection may still
		exist.

		Do not destroy the connection immediately after the PSem
		returns.  Let the driver destroy the connection to avoid
		destroying it while the driver's thread may still be doing 
		something with the connection.  (e.g. the message is queued,
		but the connection failed and the PSem returned, then the
		driver's thread gets the queued event)
		

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDisconnectRequest	proc	far
		uses	ax, bx, cx, si, ds
		.enter

		Assert	etype ax, SocketCloseType		

EC <		cmp	ax, SCT_FULL				>
EC <		jne	skipCheck				>
EC <		call	ECCheckCallerThread			>
EC <skipCheck:							>
	;
	; If connection doesn't exist, return error.
	;
		call	TcpipGainAccess
 		;xchg	ax, bx			; ax = conn, bx = SocketCloseType
		;call	TSocketFindHandle	; destroys cx	
		;jnc	checkState

		;mov	ax, SDE_INVALID_CONNECTION_HANDLE
		;call	TcpipReleaseAccess
		;jmp	exit
checkState:
	;
	; If socket is not open, no need to do anything.  This case
	; is NOT an error so return carry clear!
	;
		;call	TSocketLockInfoExcl
		;mov	di, ax						
		;mov	si, ds:[di]		; ds:si = TcpSocket	

		;cmp	ds:[si].TS_state, TSS_OPEN
		;je	disconnect
		
		;call	TSocketUnlockInfoExcl
		;call	TcpipReleaseAccess
		;jmp	done			
disconnect:
	;
	; Set state to disconnecting and wake blocked send request
	; on the connection, if any.
	;
		;mov	ds:[si].TS_state, TSS_DISCONNECTING		

		;mov	cx, bx			; cx = SocketCloseType
		;tst	ds:[si].TS_pendingData
		;je	afterVSend
EC <		WARNING	TCPIP_ABORTING_SEND_DATA_REQUEST		>
		;mov	bx, ds:[si].TS_sendSem
		;call	ThreadVSem
afterVSend:
	;
	; Get sempahore to block calling thread if full close.
	;
		;cmp	cx, SCT_HALF
		;je	doClose

EC <	;	tst	ds:[si].TS_waiter				>
EC <	;	ERROR_NZ TCPIP_OPERATION_IN_PROGRESS			>

		;mov	ds:[si].TS_waiter, TCPIP_WAITER_EXISTS
		;mov	bx, ds:[si].TS_sem
doClose:
		;call	TSocketUnlockInfoExcl
	;
	; Tell driver to disconnect the connection. 
	;
		mov	di, bx
		mov	ax, MSG_TCPIP_CLOSE_CONNECTION_ASM
		call	TcpipSendMsgToDriverThread

		call	TcpipReleaseAccess
	; 
	; If full close, block until disconnect completes.
	;
		;cmp	cx, SCT_HALF
		;je	exit				; carry already clear
		;call	ThreadPSem			
done:
		clc					
exit:		
		.leave
		ret

TcpipDisconnectRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Socket library is sending some data over a connection

CALLED BY:	TcpipStrategy (DR_SOCKET_SEND_DATA)

PASS:		dx:bp	= optr of buffer to send (hugeLMem chunk)
		cx	= size of data in buffer
		bx	= connection handle
		ax	= timeout value (or 0 for no blocking)
		si	= SocketSendMode
		
RETURN:		carry set if data could not be sent
		ax	= SocketDrError (SDE_CONNECTION_TIMEOUT,
				   	 SDE_INTERRUPTED,
					 SDE_CONNECTION_RESET_BY_PEER,
					 SDE_CONNECTION_RESET)
			
DESTROYED:	di (preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:
		Verify that the connection exists
		Add the data to the output queue for the connection
		Queue a message for the driver's thread to send the data

SIDE EFFECTS:
		Data buffer will be freed by the driver if send is
		successful.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipSendData	proc	far
savebp		local	word	push	bp
;regs		local	PMRealModeRegister
		uses	bx, cx, dx, ds
		.enter

EC <		call	ECCheckCallerThread			>

		Assert	etype, si, SocketSendMode		
		Assert 	optr, dxbp				

	;
	; If there is no data, just free the buffer but don't return 
	; error.
	;
		call	TcpipGainAccess

		clc				; no error		
		jcxz	freeBuffer

	; just send the data

		push	es, bx, cx, si
		push	dx
		push	bx				
		mov	bx, dx					
		call	HugeLMemLock				

		mov	es, ax					
		push	bp
		mov		bp, savebp
		mov	si, es:[bp]	
		pop	bp

	; skip header
		mov 	bx, es:[si].PH_dataSize
		add	si, es:[si].PH_dataOffset

		; es:si ptr to data to sent
		; bx connection handle
		pop	bx
		mov	ax, 1003
		int	0xB0
errDone:
		pop	dx
		mov		bx, dx
		call	HugeLMemUnlock				
		pop	es, bx, cx, si				

		;stc				; else, indicate error
		jmp		silentFreeBuf

freeBuffer:

EC <		WARNING TCPIP_DISCARDING_OUTPUT_BUFFER		>
silentFreeBuf:
		push	ax
		pushf
		push	bp
		mov	bp, savebp
		movdw	axcx, dxbp
		pop	bp
		call	HugeLMemFree
		popf
		pop	ax				; ax = error, if any
exit:
		call	TcpipReleaseAccess
		.leave
		ret		


TcpipSendData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipStopSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt a blocked send data request, if any.

CALLED BY:	TcpipStrategy (DR_SOCKET_STOP_SEND_DATA)	

PASS:		bx	= connection handle

RETURN:		carry set if error
		ax	= SocketDrError (SDE_INVALID_CONNECTION_HANDLE)
		else carry clear


DESTROYED:	di (allowed)
		ax if not returned

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/29/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipStopSendData	proc	far

		uses	bx, cx, si, ds
		.enter
	;
	; Gain access so we don't get preempted by a send data or a
	; disconnect request.  Verify connection handle.
	;
		mov_tr	ax, bx				; ax = handle
		mov	di, ax				; di = handle

		call	TcpipGainAccess
		;call	TSocketLockInfoListFar		; *ds:si = socket list

		;call	TSocketFindHandleNoLock		; destroys cx
		mov	ax, SDE_INVALID_CONNECTION_HANDLE
		jc	exit

	;
	; Interrupt a pending send data request if there is one.
	;
		mov	si, ds:[di]			; ds:si = TcpSocket
		tst_clc	ds:[si].TS_pendingData
		je	exit

		mov	ds:[si].TS_error, SDE_INTERRUPTED
		mov	bx, ds:[si].TS_sendSem
		call	ThreadVSem
		clc
exit:
		;call	TSocketUnlockInfoExcl		
		call	TcpipReleaseAccess

		.leave
		ret
TcpipStopSendData	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipSendDatagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Socket library is sending some unreliable data.

CALLED BY:	TcpipStrategy (DR_SOCKET_SEND_DATAGRAM)

PASS:		dx:bp	= optr of buffer to send
		ds:si	= remote address (non-null terminated string)
		ax	= address size
		bx	= client handle
		cx	= data size (ignored)

RETURN:		carry set
		ax = SocketDrError 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		pass to UDP output routine

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipSendDatagram	proc	far
		uses	cx
		.enter

EC <		call	ECCheckCallerThread			>

		Assert	optr dxbp				

EC <		cmp	bx, mask RS_DATA			>
EC <		ERROR_NE TCPIP_INVALID_CLIENT_HANDLE		>

EC <		push	bx					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx					>

		mov	cx, MSG_TCPIP_SEND_DATAGRAM_ASM
		call	TcpipSendDatagramCommon

		.leave
		ret

TcpipSendDatagram	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipResetRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Socket library wants to reset the connection.

CALLED BY:	TcpipStrategy (DR_SOCKET_RESET_REQUEST)

PASS:		ax	= connection handle

RETURN:		nothing

DESTROYED:	di (preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:
		Verify that the connection exists
		Set the socket state to closed
		Tell the driver's thread to reset the connection
		Block calling thread until connection has been reset

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version
	jwu	5/14/96			Use MF_CALL and no PSem version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipResetRequest	proc	far
		uses	ax, bx, cx, dx, si, ds
		.enter
EC <		call	ECCheckCallerThread				>

		;call	TSocketFindHandle		; destroys cx		
EC <		WARNING_C TCPIP_CONNECTION_DOES_NOT_EXIST		>
		jc	noSocket
	;
	; Set the socket state to closed and mark that we are
	; waiting for the connection to be closed.  (Must do this
	; even though we don't PSem here to prevent notifications 
	; from being sent.)
	;
		call	TcpipGainAccess

		;call	TSocketLockInfoExcl
		;mov	si, ax				; si = connection handle
		;mov_tr	cx, ax				; cx = connection handle
		;mov	si, ds:[si]			; ds:si = TcpSocket
		;tst	si
EC <	;	WARNING_Z TCPIP_CONNECTION_DOES_NOT_EXIST		>
		;jz	noSocketUnlock
		
EC <	;	tst	ds:[si].TS_waiter				>
EC <	;	ERROR_NZ TCPIP_OPERATION_IN_PROGRESS			>

		;mov	ds:[si].TS_waiter, TCPIP_WAITER_EXISTS		
		;mov	ds:[si].TS_state, TSS_CLOSED
	;
	; Wake up any pending sends.  Must do this AFTER marking socket 
	; closed.
	;
		;tst	ds:[si].TS_pendingData
		;je	noSend
EC <	;	WARNING TCPIP_ABORTING_SEND_DATA_REQUEST	>
		;mov	bx, ds:[si].TS_sendSem
		;call	ThreadVSem			; destroys ax
noSend:
		;call	TSocketUnlockInfoExcl
	;
	; Tell the driver to send a reset and wait until it completes.
	; Must use MF_CALL so we know that connection has been destroyed
	; when we return.
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[driverThread]

EC <		Assert	thread	bx				>	

		mov	dx, SDE_CONNECTION_RESET
		mov	ax, MSG_TCPIP_RESET_CONNECTION_ASM
		mov	di, mask MF_CALL
		call	ObjMessage
exit::
		call	TcpipReleaseAccess
noSocket:
		.leave
		ret

noSocketUnlock:
		;call	TSocketUnlockInfoExcl
		jmp	short exit

TcpipResetRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Socket library has decided to accept a connection 
		requested by the peer.

CALLED BY:	TcpipStrategy (DR_SOCKET_ATTACH)

PASS:		ax	= connection handle
		cx	= timeout value (in ticks)

RETURN:		carry set if error
		ax = SocketDrError

DESTROYED:	di (preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:
		Verify that the connection exists
		Tell the driver's thread to accept the connection
		Start a timer to stop the process if it takes too long
		Block calling thread until connection has been established

		If socket is now in open state, return connection handle
		If socket is in closed state, return SocketDrError based
			on error stored in the socket state and destroy
			the socket

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipAttach	proc	far
		uses	bx, cx
		.enter

EC <		call	ECCheckCallerThread				>

EC <		push	cx					>
;EC <		call	TSocketFindHandle	; destroys cx	>
EC <		pop	cx					>
EC <		ERROR_C TCPIP_INVALID_CONNECTION_HANDLE		>

	;
	; Set state to connecting and get the semaphore to block
	; caller's thread.
	;
		mov	bl, TSS_CONNECTING
		;call	TSocketSetStateAndGetSem		; bx = sem handle
	;
	; Tell the driver's thread to accept the connection, then wait.
	;
		mov_tr	di, ax				; di = connection handle
		mov	ax, MSG_TCPIP_ACCEPT_CONNECTION_ASM
		call	TcpipSendMsgToDriverThread

		call	ThreadPTimedSem			; ax = SemaphoreError
	;
	; Check if the connection has been successfully established or not.
	;
		mov	cx, di				; cx = connection handle
		;call	TSocketCheckIfConnected		; ax = SocketDrError
exit::
		.leave
		ret

TcpipAttach	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Socket library rejects the connection requested by 
		the peer.

CALLED BY:	TcpipStrategy (DR_SOCKET_REJECT)

PASS:		ax	= connection handle

RETURN: 	nothing

DESTROYED:	di (preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:
		Verify that the connection exists
		Set the socket state to dead and set waiter bit
		Tell the driver's thread to reject this connection
		Block until rejection completed
		
NOTE: 		Socket will be destroyed after a timeout period by tcpip
		thread.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version
	jwu	5/14/96			MF_CALL, no PSem version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipReject	proc	far
		uses	ax, bx, cx, dx, ds
		.enter

EC <		call	ECCheckCallerThread				>
	;
	; Verify that the connection exists.
	;
;EC <		call	TSocketFindHandle	; destroys cx	>
EC <		ERROR_C TCPIP_INVALID_CONNECTION_HANDLE		>

	;
	; Set the socket state to dead and set waiter flag to 
	; avoid notifications from being sent when connection is
	; closed.  
	;
		;call	TSocketLockInfoExcl
		;mov	si, ax			; si = connection handle
		;mov_tr	cx, ax			; cx = connection handle
		;mov	si, ds:[si]		; ds:si = TcpSocket

EC <	;	tst	ds:[si].TS_waiter				>
EC <	;	ERROR_NZ TCPIP_OPERATION_IN_PROGRESS			>

		;mov	ds:[si].TS_waiter, TCPIP_WAITER_EXISTS		
		;mov	ds:[si].TS_state, TSS_DEAD
		;call	TSocketUnlockInfoExcl
	;
	; Tell the driver's thread to reject the connection by sending
	; a reset.  Wait until the reset has been processed.  Connection
	; is destroyed by TCP's thread.
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[driverThread]

EC <		Assert	thread	bx				>	

		mov	dx, SDE_CONNECTION_RESET
		mov	ax, MSG_TCPIP_RESET_CONNECTION_ASM
		mov	di, mask MF_CALL
		call	ObjMessage
exit::
		.leave
		ret

TcpipReject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Furnish requested information.

CALLED BY:	TcpipStrategy (DR_SOCKET_GET_INFO)

PASS:		ax	= SocketGetInfoType
		other parameters vary by SocketGetInfoType

RETURN:		carry set if information not available, else
		depends on SocketGetInfoType

DESTROYED:	ax (if not used in return value)
		di (preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/21/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetInfo	proc	far
		uses	es
		.enter

		Assert	etype ax, SocketGetInfoType		
	;
	; Return error if SocketGetInfoType not supported by driver.
	;
		cmp	ax, size infoProcTable
		cmc
		jc	exit
		
		push	bx
		mov	bx, handle dgroup
		call	MemDerefES			; es = dgroup
		pop	bx

		mov	di, ax
		call	cs:infoProcTable[di]
exit:
		.leave
		ret

infoProcTable	nptr	\
	TcpipGetMediaList,		; SGIT_MEDIA_LIST
	TcpipGetMediumAndUnit,		; SGIT_MEDIUM_AND_UNIT
	TcpipGetAddrCtrl,		; SGIT_ADDR_CTRL
	TcpipGetAddrSize,		; SGIT_ADDR_SIZE
	TcpipGetLocalAddr,		; SGIT_LOCAL_ADDR
	TcpipGetRemoteAddr,		; SGIT_REMOTE_ADDR
	TcpipGetNothing,		; SGIT_MTU
	TcpipGetNothing,		; SGIT_PREF_CTRL
	TcpipGetMediumConnection,	; SGIT_MEDIUM_CONNECTION
	TcpipGetMediumLocalAddr		; SGIT_MEDIUM_LOCAL_ADDR

TcpipGetInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Something to do in your spare time.

CALLED BY:	TcpipGetInfo (SGIT_MTU, SGIT_PREF_CTRL)
PASS:		nothing
RETURN:		carry set  
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		set the carry flag because the info is not available

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetNothing	proc	near
		stc
		ret
TcpipGetNothing	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetMediaList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pp
SYNOPSIS:	Return a list of media supported by the driver.

CALLED BY:	TcpipGetInfo	(SGIT_MEDIA_LIST)

PASS: 		*ds:si	= chunk array for MediumType

RETURN:		*ds:si	= chunk array filled with MediumType

DESTROYED:	ax (allowed)	di (preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/21/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetMediaList	proc	near
		uses	bx
		.enter

EC <		push	cx					>
EC <		call	ChunkArrayGetCount			>
EC <		tst	cx					>
EC <		ERROR_NE TCPIP_INVALID_PARAMS_TO_GET_MEDIA_LIST >
EC <		pop	cx					>

		clr	bx				; first entry
makeList:
		call	ChunkArrayAppend		; ds:di = new element
		jc	exit
		
		mov	ax, cs:mediaTable[bx]
		mov	ds:[di].MET_id, ax
		mov	ds:[di].MET_manuf, MANUFACTURER_ID_GEOWORKS
		
		inc	bx	
		inc	bx
		cmp	bx, size mediaTable
		jb	makeList
		
		clc
exit:
		.leave
		ret

mediaTable	word \
	GMID_SERIAL_CABLE,
	GMID_DATA_MODEM

TcpipGetMediaList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetMediumAndUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the medium and unit.

CALLED BY:	TcpipGetInfo (SGIT_MEDIUM_AND_UNIT)

PASS:		ds:si	= non-null terminated addr string (ignored)
		dx	= addr size			  (ignored)
		es	dgroup

RETURN:		carry set if error, else
		cxdx	= MediumType
		bl	= MediumUnitType
		bp	= MediumUnit (port)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/21/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetMediumAndUnit	proc	near
		;call	LinkGetMediumAndUnit
		ret
TcpipGetMediumAndUnit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetAddrCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the pointer to the address controller class.  

CALLED BY:	TcpipGetInfo (SGIT_ADDR_CTRL)

PASS:		nothing

RETURN:		carry set on error
		else
		cx:dx	= pointer to class

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Domain and medium parameters are ignored because 
		there is only possible address controller.

		Increment ref count of driver.
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/31/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetAddrCtrl	proc	near
		uses	bx
		.enter
		mov	bx, handle 0
		call	GeodeAddReference

		mov	cx, segment IPAddressControlClass
		mov	dx, offset IPAddressControlClass
		clc

		.leave
		ret
TcpipGetAddrCtrl	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetAddrSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return significant bytes of resolved IP address only.  
		Link address is not accounted for in returned size

CALLED BY:	TcpipGetInfo (SGIT_ADDR_SIZE)

PASS:		nothing

RETURN:		ax 	= size of resolved IP address

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/21/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetAddrSize	proc	near
		mov	ax, size IPAddr
		clc
		ret
TcpipGetAddrSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetLocalAddr/TcpipGetRemoteAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the local/remote IP address used in its 4 byte 
		binary form.  (Not the extended IP address with link 
		address combined.)

CALLED BY:	TcpipGetInfo (SGIT_LOCAL_ADDR, SGIT_REMOTE_ADDR)

PASS:		cx	= connection handle (or 0 if connectionless)
		ds:bx	= buffer for addr string
		dx	= buffer size
		es	= dgroup

RETURN:		carry set if error, else
		ds:bx	= addr string (non null-terminated)
		ax	= address size

DESTROYED:	di (preserved by caller)

PSEUDO CODE/STRATEGY:
		Get local address of specified connection.  If no
		connection specified, get local address of main
		tcp link.  If main link not open, return carry set.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/21/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetLocalAddr	proc	near
		uses	bx, cx
		.enter

EC <		push	bx, si					>
EC <		movdw	bxsi, dsbx				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>

		mov	ax, IP_ADDR_SIZE
		cmp	ax, dx				; buffer big enough?
		ja	exit				; carry already clear

		jcxz	noAddr
		
		mov	di, offset TS_localAddr
		call	TcpipGetAddrCommon		
		jmp	exit
noAddr:
	;
	; Return address of main link, if opened.
	;
		push	si, es, ds
		movdw	essi, dsbx			; es:si = buffer
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		;call	LinkTableGetEntry		; ds:di = LCB
							; ^hbx = table
		movdw	es:[si], ds:[di].LCB_localAddr, cx
		mov	cl, ds:[di].LCB_state
		call	MemUnlockExcl
		pop	si, es, ds

		cmp	cl, LS_OPEN
		je	exit				; carry clear

		stc		
exit:		
		.leave
		ret
TcpipGetLocalAddr	endp


TcpipGetRemoteAddr	proc	near
EC <		tst	cx				>
EC <		ERROR_E TCPIP_INVALID_CONNECTION_HANDLE >

		mov	ax, IP_ADDR_SIZE
		cmp	ax, dx				; buffer big enough?
		ja	exit				; carry already clear
		
		mov	di, offset TS_remoteAddr
		call	TcpipGetAddrCommon		
exit:		
		ret
TcpipGetRemoteAddr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetAddrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the requested address.

CALLED BY:	TcpipGetLocalAddr, TcpipGetRemoteAddr

PASS:		cx	= connection handle 
		ds:bx	= buffer for addr string
		di	= offset to TS_localAddr or TS_remoteAddr

RETURN:		carry set if error, else
		ds:bx	= buffer for addr string

DESTROYED:	di (preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/24/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetAddrCommon	proc	near
		uses	cx, si
		.enter

EC <		push	ax					>
EC <		mov_tr	ax, cx					>
;EC <		call	TSocketFindHandle	; destroys cx	>
EC <		ERROR_C TCPIP_INVALID_CONNECTION_HANDLE		>
EC <		mov_tr	cx, ax					>
EC <		pop	ax					>

		push	ds
		;call	TSocketLockInfoShared
		mov	si, cx				; si = connection handle
		mov	si, ds:[si]			; ds:si = TcpSocket
		add	si, di				; ds:si = desired address
		movdw	cxdi, ds:[si]			; cxdi = IP address
		;call	TSocketUnlockInfoShared
		pop	ds

		movdw	ds:[bx], cxdi
		clc
		
		.leave
		ret
TcpipGetAddrCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetMediumConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if a connection exists over the specified unit of
		the medium.  If so, then return the connection address.

CALLED BY:	TcpipGetInfo (SGIT_MEDIUM_CONNECTION)
PASS:		es	= dgroup
		dx:bx	= MediumAndUnit
		ds:si	= address buffer		
		cx	= buffer size in bytes	

RETURN:		carry set if no connection is established over the unit of
		the medium.
		else
		ds:si	= filled in with address, up to value passed
			  in as buffer size.
		cx	= actual size of address in ds:si.  If cx
			  is greater than the buffer size that was
			  passed in, then address in ds:si is 
			  incomplete.
	
DESTROYED:	di (preserved by caller)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetMediumConnection	proc	near
		uses	bx
		.enter

EC <		push	si					>
EC <		push	bx					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	si					>
EC <		mov	bx, dx
EC <		call	ECAssertValidFarPointerXIP		>
EC <		mov	bx, si					>
EC <		pop	si					>

		;call	LinkGetMediumAndUnitConnection	; cx = link domain handle
		jc	exit				; no link
		mov_tr	cx, ax				; cx <- addr size
							;  (carry remains
							;  clear)
exit:
		.leave
		ret
TcpipGetMediumConnection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetMediumLocalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the local IP address (in its 4 byte binary form) 
		that would be used for outgoing connections/datagrams.

CALLED BY:	TcpipGetInfo

PASS:		es	= dgroup
		dx:bx	= MediumAndUnit (ignored)
		ds:si	= address buffer
		cx	= buffer size in bytes

RETURN:		carry set if address not available
		else
		ds:si	= filled in with address, if buffer big enough
		cx	= actual size of address in ds:si.  If cx is 
			  greater than the buffer size that was passed in,
			  then address in ds:si is incomplete.

DESTROYED:	ax, di (allowed/preserved by caller)

PSEUDO CODE/STRATEGY:
		Set up parameters and call TcpipGetLocalAddr.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/ 8/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetMediumLocalAddr	proc	near
		uses	bx, dx
		.enter

		mov	bx, si			; ds:bx = buffer for addr
		mov	dx, cx			; dx = buffer size
		clr	cx			; no connection
		call	TcpipGetLocalAddr

		mov_tr	cx, ax			; cx = addr size

		.leave
		ret
TcpipGetMediumLocalAddr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipSetOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an option for the connection.

CALLED BY:	TcpipStrategy (DR_SOCKET_SET_OPTION)

PASS:		ax	= SocketOptionType
		bx	= connection
		other params by option type:
			SOT_SEND_BUF:
			SOT_RECV_BUF:
				cx = size of receive buffer (-1 for no limit)
			SOT_INLINE: 
			SOT_NODELAY:
				cx = TRUE/FALSE

RETURN:		nothing

DESTROYED:	di	(preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/10/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipSetOption	proc	far
		uses	ax,bx,cx,dx,si,ds,es
		.enter

		Assert	etype ax, SocketOptionType		
	;
	; Find connection handle.
	;
		push	cx					
		xchg	ax, bx					
		;call	TSocketFindHandle	; destroys CX	
		xchg	ax, bx					
		pop	cx					
EC <		WARNING_C TCPIP_CONNECTION_HANDLE_IS_BAD	>
		jc	exit
	;
	; If setting send buffer size, do it here, else let C code 
	; handle it.
	; 
		cmp	ax, SOT_SEND_BUF
		jne	setProto

		;call	TSocketLockInfoExcl
		;mov	di, ds:[bx]		; ds:di = TcpSocket
		;mov	ds:[di].TS_maxData, cx	
		;call	TSocketUnlockInfoExcl
		jmp	exit
setProto:
		push	bx, ax, cx
		;call	TcpSetOption		; may destroy all but bp
exit:
		.leave
		ret
TcpipSetOption	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the value for a Tcp option from the connection.

CALLED BY:	TcpipStrategy (DR_SOCKET_GET_OPTION)

PASS:		ax	= SocketOptionType
		bx	= connection

RETURN:		cx	= option value

DESTROYED:	di (preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/10/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetOption	proc	far
		uses	ax, bx, dx, si, ds, es
		.enter

		Assert	etype ax, SocketOptionType		

		xchg	ax, bx					
		;call	TSocketFindHandle	; destroys CX	
		xchg	ax, bx					
EC <		WARNING_C TCPIP_CONNECTION_HANDLE_IS_BAD	>
		mov	cx, 0			; assume worst... preserve carry!
		jc	exit

EC <		cmp	ax, SOT_RECV_BUF			>
EC <		ERROR_E	TCPIP_QUERIED_FOR_RECV_BUFFER_LIMIT	>

		push	bx, ax
		;call	TcpGetOption		; ax = option value
						; may destroy all but bp
		mov_tr	cx, ax			
exit:
		.leave
		ret
TcpipGetOption	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipResolveAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve a socket address for TCP/IP.  Address is a
		combined link and IP address.  A zero sized IP address
		will be resolved as the default server or client address
		depending on whether a link is open or not.  This is useful
		for making direct connections between 2 GEOS devices which
		do not have IP addresses of their own.

CALLED BY:	TcpipStrategy (DR_SOCKET_RESOLVE_ADDR)
PASS:		ds:si 	= addr to resolve (non-null terminated)
				(ESACAddress format)
		cx	= size of addr (cannot be zero because there is 
					at least a word for size of link part)
		dx:bp	= buffer for resolved address
		ax	= size of buffer

RETURN:		carry clr if address returned
		  dx:bp = buffer filled w/non-null terminated addr if buffer
			  is big enough
		  cx	= size of resolved address

		carry set if couldn't resolve it
		  ax	= SocketDrError
		  SDE_DESTINATION_UNREACHABLE: address doesn't exist in network
		  SDE_TEMPORARY_ERROR: address unreachable temporarily
		  SDE_INVALID_ADDR
		  SDE_DRIVER_NOT_FOUND
		  and anything else that can be returned by connect and send
			routines

DESTROYED:	di (preserved by caller)

STRATEGY:
		make sure buffer is big enough before wasting our efforts

		copy link address part to buffer first so pointer to
		  addr string is automatically advanced to tcp part 

		if address is in dotted decimal notation, convert to 
		binary form

		else, use resolver to determine address of host name string

		return size of resolved address (equals size of link part
			plus IP_ADDR_SIZE)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/17/95    	Initial version
	jwu	2/23/95		2nd, 3rd, 4th and ... versions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipResolveAddr	proc	far
savebp		local	word	push	bp
;regs		local	PMRealModeRegister

		uses	bx, dx, bp, si, ds, es
		.enter

EC <		push	bx, si					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		movdw	bxsi, dxbp				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>

EC <		tst	cx					>
EC <		ERROR_E TCPIP_INVALID_IP_ADDRESS		>
	;
	; Check if buffer is big enough.
	;
		mov	di, cx			; di = total addr size
		mov_tr	bx, ax			; bx = buffer size
		lodsw				; ax = link size
		mov	cx, ax			; cx = link size
		sub	bx, IP_ADDR_SIZE + size word
		; TODO this seems wrong
		jb	setSize		; too small for IP addr and link size
	;
	; Have link driver resolve the link part of the address.
	;
		xchg	ax, bx			; bx = size of link address
						; ax = buffer size for link addr
		mov	es, dx	
		
	; 
	; TODO: Host integration driver doesn't care for the link
	;		
		;jcxz	afterLink

		;add	bp, size word		; es:bp = start of link part
		;call	LinkResolveLinkAddr	; cx = resolved addr size
						; dx = access ID, ax unchanged
		;jc	exit			;  or ax = SocketDrError
		
		;cmp	cx, ax			
		;ja	setSize			; buffer was too small

		;sub	bp, size word		; es:bp = start of buffer

		mov	cx, 3			; HstTcpip, assume same size
						; LT_ID
afterLink:
	;
	; Store resolved link address size.  
	;
		push	bp
		mov	bp, savebp
		mov	es:[bp], cx
		add	bp, size word
		add	bp, cx			; es:bp = resolved IP addr dest
	;
	; Advance pointers and update sizes.  
	;
		add	si, bx			; ds:si = unresolved IP addr
		add	bx, size word		; include word for link size
		sub	di, bx			; di = unresolved IP addr size
		mov	bx, cx			; bx = resolved link addr size
		mov	cx, di			; cx = unresolved IP addr size
		mov	di, bp			; es:di = resolved IP addr dest
		pop	bp

if 0
	;
	; Now resolve the IP part of the address.  If no IP address is 
	; provided, return the default IP address.
	;
		jcxz	getDefault		

	; alloc dos mem buffer 
	;  bx buffer size in paragraphs
	
		push	bx
		mov	bx, cx
		add	bx, IP_ADDR_SIZE
		shr	bx, 4		; div by 16 to have paragraphs
		inc	bx

		;call	SysAllocDOSBlock
		pop	bx

		jc	exit

	; now ax = real mode, dx = selector
	; copy string first
	; cx is unresolved IP addr size, ds:si is addr ptr
	; es:di should point to target yet

		push	es
		push	di

		push	cx
		push	ax
		mov	es, dx
		mov di, 0

		rep	movsb
		pop	ax
		pop	cx

	;
	; setup regs
	;
endif
if 0
        ;mov     ss:[regs.PMRMR_edi], 0 
        mov     ss:[regs.PMRMR_esi], 0 
        ;mov     ss:[regs.PMRMR_ebp], 0 
        ;mov     ss:[regs.PMRMR_reseverd], 0 
        ;mov     ss:[regs.PMRMR_ebx], ebx 
        ;mov     ss:[regs.PMRMR_edx], 0 
        mov     ss:[regs.PMRMR_ecx], ecx 
        mov     ss:[regs.PMRMR_eax], 1000
        mov     ss:[regs.PMRMR_flags], 0 
        ;mov     ss:[regs.PMRMR_es], ax 
        mov     ss:[regs.PMRMR_ds], ax 
		;mov     ss:[regs.PMRMR_fs], 0 
        ;mov     ss:[regs.PMRMR_gs], 0 
        ;mov     ss:[regs.PMRMR_ip], 0 
        ;mov     ss:[regs.PMRMR_cs], 0 
        mov     ss:[regs.PMRMR_sp], 0
        mov     ss:[regs.PMRMR_ss], 0
endif
if 0
		;lea	di, ss:regs
		mov	dx, ss
		mov	es, dx

		push	bx	; link address size
		mov	cx, 0
		mov	bh, 0
		mov 	bl, 0xB0 ; GEOS host

		mov ax, 1000		; resolve address
		int	0xB0
		
		;call    SysRealInterrupt		
		pushf
	; free dos mem buffer
		
		mov	dx, es
		;call	SysFreeDOSBlock


		;call	TcpipResolveIPAddr	; dxax = address or 

		popf
		pop	cx				; resolved link address size
		pop	di
		pop es
		jc	exit			;  ax = SocketDrError
		;mov		eax, regs.PMRMR_eax
		;mov		edx, regs.PMRMR_edx
endif
	;
	; Now resolve the IP part of the address.  If no IP address is 
	; provided, return the default IP address.
	;
		jcxz	getDefault		

		call	TcpipResolveIPAddr	; dxax = address or 
		jc	exit			;  ax = SocketDrError
haveAddr:
		movdw	es:[di], dxax
		mov	cx, bx			; cx = resolved link addr size
setSize:
		add	cx, IP_ADDR_SIZE + size word
		clc
exit:
		.leave
		ret

getDefault:
	;
	; Get the default remote IP address the client should use.
	;
		call	TcpipGetDefaultIPAddr	; dxax = address
		jmp	haveAddr	


TcpipResolveAddr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipStopResolve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt a resolve operation.

CALLED BY:	TcpipStrategy

PASS:		ds:si	= addr being resolved (non-null terminated)
				(ESACAddress format)
		cx	= size of addr (cannot be zero because there is 
					at least a word for size of link part)

RETURN:		carry set if error
		ax	= SocketDrError (SDE_DRIVER_NOT_FOUND)

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:

		Get link address 
		Tell link driver to stop resolving
		Get IP address
		If first char is alpha, 
			load resolver
			stop resolve
			unload resolver
		clc

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/29/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipStopResolve	proc	far

		uses	bx, cx, si
		.enter

EC <		tst	cx					>
EC <		ERROR_E TCPIP_INVALID_IP_ADDRESS		>

	;
	; Stop resolution of link part of address.
	;
		lodsw				; ax = link addr size
		xchg	cx, ax			; ax = total addr size
		jcxz	doIP			; no link address

		;call	LinkStopLinkResolve
doIP:
	;
	; Make sure address even needed resolving.  Address
	; is assumed to be in dotted decimal notation if the
	; first character is a digit. (RFC 1034, section 3.5)
	;
		add	si, cx			; ds:si = IP address
		sub	ax, cx
		dec	ax
		dec	ax
		mov_tr	cx, ax			; cx = IP address size
		jcxz	done

		clr	ax
		LocalGetChar	ax, dssi, NO_ADVANCE
		call	LocalIsDigit
		jnz	done
	;
	; Don't know how to check if a resolve is in progress so 
	; just pass the request along.
	;
ifdef STATIC_LINK_RESOLVER
	    mov bx, handle resolver
else
		call	TcpipLoadResolver		; ax = library handle 
		jc	exit				;  or SocketDrError
		push	ax
		mov_tr	bx, ax				; bx = library handle
endif

		mov	ax, enum ResolverStopResolve
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable		

ifndef STATIC_LINK_RESOLVER
		pop	bx
		call	GeodeFreeLibrary
endif
done:
		clc
ifndef STATIC_LINK_RESOLVER
exit:
endif
		.leave
		ret
TcpipStopResolve	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipCloseMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the link on the specified medium.

CALLED BY:	TcpipStrategy (DR_SOCKET_CLOSE_MEDIUM)

PASS:		ax	= non-zero to force close
		dx:bx	= MediumAndUnit

RETURN:		carry clear if medium closed

DESTROYED:	di (preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:
		Find the link of the specified medium.
		if the link is busy
			if (force = true)
				reset all connections
			else return carry clear
		if link is opening, interrupt it and return
		if link is opened, close link
		unregister and free link driver
		delete entry in link table if not main link driver

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/12/95			Initial version
	jwu	9/22/95			Release link table btwn calls
	jwu	7/29/96			interruptable version
	jwu	1/22/97			check LCB_options for busy link
	ed	6/30/00			GCN notification

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipCloseMedium	proc	far
		uses	ax, bx, cx, dx, si, ds, es
force		local	word		push	ax
drvrEntry	local	fptr
clientHan	local	word
		.enter

EC <		call	ECCheckCallerThread			>

EC <		push	bx, si					>
EC <		movdw	bxsi, dxbx				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>
	;
	; Find the link using the specified medium and unit.
	;
		call	TcpipGainAccess

		mov	cx, bx				; dx:cx = MediumAndUnit
		mov	bx, handle dgroup
		call	MemDerefES

		mov	bx, cx				; dx:bx = MediumAndUnit
		clr	cx				; no buffer for address
		;call	LinkGetMediumAndUnitConnection	; cx = link handle
		LONG	jc	clcExit			
	;
	; If link is busy and client is forcing close, reset
	; connection using the link.  Otherwise, reject close.
	;
		mov_tr	ax, cx				; ax = link handle

		mov	bx, ax
		;call	LinkTableGetEntry
		test	ds:[di].LCB_options, mask LO_ALWAYS_BUSY
		call	MemUnlockExcl
		jnz	busyLink
			
		;call	TSocketCheckLinkBusy
		jnc	unusedLink
busyLink:		
		mov	cx, force
		stc					; expect no close
		LONG	jcxz	exit			; preserves carry

	;
	; Set error to connection reset because user cancelled (that's
	; what forcing the medium close is treated as and no error note
	; should be displayed.)
	;
		mov	dx, (SSDE_CANCEL or SDE_CONNECTION_RESET)
		;call	TSocketResetConnectionsOnLink
unusedLink:
	;
	; If link is still being opened, interrupt it.  Set state to
	; CLOSED.  If link is closing, do nothing.  Else close link.
	;
		mov	cx, ax				; cx = link handle
		mov_tr	bx, ax				
		;call	LinkTableGetEntry

		mov	si, ds:[di].LCB_connection
		BitClr	ds:[di].LCB_options, LO_ALWAYS_BUSY

		mov	al, ds:[di].LCB_state
		cmp	al, LS_OPENING
		je	stopLinkOpen
	;
	; Already closing.  Do nothing and wait for link to close.
	;
		cmp	al, LS_CLOSING
		jne	closeLink

		call	MemUnlockExcl
		jmp	clcExit

stopLinkOpen:
	;
	; Link is opening. Interrupt it.
	;
		mov	ds:[di].LCB_state, LS_CLOSING
		mov	ds:[di].LCB_error, SDE_INTERRUPTED
		pushdw	ds:[di].LCB_strategy
		call	MemUnlockExcl

		mov	ax, TSNT_CLOSING
		;call	LinkSendNotification

		mov	bx, si
		mov	di, DR_SOCKET_STOP_LINK_CONNECT
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jmp	exit
closeLink:
	;
	; Disconnect the link if it is open.  MUST unlock link table
	; before calling out of driver.  Link driver will be unregistered
	; and unloaded.
	;
		mov	ds:[di].LCB_state, LS_CLOSED
		mov	dx, ds:[di].LCB_clientHan
		mov	clientHan, dx
		movdw	drvrEntry, ds:[di].LCB_strategy, dx
		clr	dx
		xchg	dx, ds:[di].LCB_drvr
		call	MemUnlockExcl

		push	ax
		mov	ax, TSNT_CLOSED
		;call	LinkSendNotification
		pop	ax

		tst_clc	dx
		je	exit				; no driver

		cmp	al, LS_CLOSED
		je	closed

		mov	bx, si				; bx = connection
		mov	di, DR_SOCKET_DISCONNECT_REQUEST
		pushdw	drvrEntry
		call	PROCCALLFIXEDORMOVABLE_PASCAL
closed:
	;
	; Unregister and free driver
	;
		mov	bx, clientHan
		mov	di, DR_SOCKET_UNREGISTER
		pushdw	drvrEntry
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		mov	bx, dx
	    cmp cx, MAIN_LINK_DOMAIN_HANDLE
	    jne notMain
	    ;call    LinkUnloadLinkDriverFar
	    jmp delete
notMain:
		call	GeodeFreeDriver
	;
	; If not main link driver, delete link entry.
	;
delete:
		cmp	cx, MAIN_LINK_DOMAIN_HANDLE
		je	exit

		movdw	bxsi, es:[linkTable]
		call	MemLockExcl
		mov	ds, ax
		mov_tr	ax, cx				; ax = link handle
		mov	cx, 1
		call	ChunkArrayDeleteRange
		call	MemUnlockExcl
clcExit:
		clc
exit:
		call	TcpipReleaseAccess
		.leave
		ret
TcpipCloseMedium	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipMediumConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the link for the given address if the link is
		not currently in use.  If link is already opened to
		the same address, the current link is returned.

CALLED BY:	TcpipStrategy

PASS:		cx	= timeout value (in ticks)
		bx	= client handle
		ds:si	= non-null terminated string for addr to connect to
		ax	= addr string size (ignored)

RETURN:		carry set if connection failed
		ax	= SocketDrError
		otherwise
		ax	= SDE_NO_ERROR

DESTROYED:	di (preserved by TcpipStrategy)

PSEUDO CODE/STRATEGY:
		call LinkOpenConnection to do all the work

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/19/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipMediumConnectRequest	proc	far

EC <		call	ECCheckCallerThread			>

EC <		call	ECCheckIPAddrSize			>

EC <		call	ECCheckClientHandle			>

EC <		push	ds					>
EC <		push	bx					>
EC <		mov	bx, handle dgroup			>
EC <		call	MemDerefDS				>
EC <		pop	bx					>
EC <		test	ds:[regStatus], bx			>
EC <		ERROR_Z TCPIP_NOT_REGISTERED			>
EC <		pop	ds					>

EC <		push	bx					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx					>

		;call	LinkOpenConnection		; ax = SocketDrError
		jc	exit
		clr	ax				
exit:
		ret
TcpipMediumConnectRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipSetMediumOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an option for the link over the given medium.

CALLED BY:	TcpipStrategy
PASS:		dxbx	= MediumAndUnit
		ax	= MediumOptionType
		other parameters vary depending on MediumOptionType
			MOT_ALWAYS_BUSY
				cx = TRUE/FALSE

RETURN:		carry set if error
DESTROYED:	di (preserved by TcpipStrategy)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	1/16/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipSetMediumOption	proc	far
		uses	ax, bx, cx, dx, si, ds, es
		.enter
	
EC <		call	ECCheckCallerThread			>
	
	;
	; If not MOT_ALWAYS_BUSY, do nothing.
	;
		cmp	ax, MOT_ALWAYS_BUSY
		jne	done
alwaysBusy::		
	; 
	; Find the link using the specified medium and unit.
	;
EC <		push	bx, si					>
EC <		movdw	bxsi, dxbx				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>
	
		push	cx				; save true/false
		mov	cx, bx				; dx:cx = MediumAndUnit
		mov	bx, handle dgroup		 
		call	MemDerefES

		mov	bx, cx				; dx:bx = MediumAndUnit
		clr	cx				; no buffer for address
		;call	LinkGetMediumAndUnitConnection	; cx = link handle
		mov	bx, cx
		pop	cx				; true/false
		LONG	jc	exit
	;
	; Set/clear option for link.
	;
		;call	LinkTableGetEntry		; bx = link table
							; ds:di = LCB
		CheckHack < FALSE eq 0 >
		jcxz	clearBusy
		BitSet	ds:[di].LCB_options, LO_ALWAYS_BUSY
		jmp	unlockTable
clearBusy:
		BitClr	ds:[di].LCB_options, LO_ALWAYS_BUSY
unlockTable:
		call	MemUnlockExcl
done:
		clc
exit:	
		.leave
		ret
TcpipSetMediumOption	endp
	

;---------------------------------------------------------------------------
;		Tcpip Extended Socket Driver Functions
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipSendRawIp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a raw IP datagram.  

CALLED BY:	TcpipStrategy (DR_TCPIP_SEND_RAW_IP)

PASS:		dx:bp	= optr of databuffer 
		ds:si	= remote IP address (non-null terminated)
		ax	= address size
		bx	= client handle

RETURN:		carry set if error
		ax = SocketDrError

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Queue a message for driver thread to send raw ip packet.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipSendRawIp	proc	far
		uses	cx
		.enter
		
if ERROR_CHECK
		call	ECCheckCallerThread			

		cmp	bx, mask RS_RAW_IP			
		ERROR_NE TCPIP_INVALID_CLIENT_HANDLE		

		Assert	optr, dxbp				

		push	bx					
		mov	bx, ds					
		call	ECAssertValidFarPointerXIP		
		pop	bx					
endif ; ERROR_CHECK

		mov	cx, MSG_TCPIP_SEND_RAW_IP_ASM
		call	TcpipSendDatagramCommon
		
		.leave
		ret
TcpipSendRawIp	endp


;---------------------------------------------------------------------------
;		Client Operations
;---------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the protocol level of the TCP/IP driver interface.
		The result should be compared with the callers notion of
		TCPIP_PROTO_MAJOR or TCPIP_PROTO_MINOR.

CALLED BY:	TcpipClientStrategy (SCO_GET_PROTOCOL)

PASS:		nothing

RETURN:		cx	= major protocol
		dx	= minor protocol

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/ 8/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetProtocol	proc	far
		mov	cx, SOCKET_PROTO_MAJOR	
		mov	dx, SOCKET_PROTO_MINOR
		ret
TcpipGetProtocol	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipAddDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the link driver loads the TCP/IP driver, it uses this 
		function to register itself.  Note that the TCP/IP driver
		always initiates unregistration, so there is no 
		SCO_REMOVE_DOMAIN call.

CALLED BY:	TcpipClientStrategy (SCO_ADD_DOMAIN)

PASS:		ax	= client handle (handle assigned to us by link driver)
		ch	= min header size for outgoing sequenced packets
		cl	= min header size for outgoing datagram packets
		dl	= SocketDriverType  (ignored by us)
		ds:si	= domain name (null terminated)
			(FXIP: string cannot be in a movable code resource)
		es:bx	= driver entry point (in fixed resource)
		bp	= driver handle

RETURN:		carry set if error
		else
		bx	= domain handle

DESTROYED:	BX if not returned

PSEUDO CODE/STRATEGY:
		Create thread first.

		Up the ref count of the link driver.  (to prevent it
			from exiting before we are done with it)
		Use the larger of the two minimums as the min header size
		Update all the info in the LinkControlBlock for the
			given protocol.
		Return the index of the LCB in the table as the domain handle

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipAddDomain	proc	far
		uses	cx, dx, ds
		.enter

if ERROR_CHECK
		push	bx					
		mov	bx, ds					
		call	ECAssertValidFarPointerXIP		
		pop	bx					
endif ; ERROR_CHECK
	;
	; Create thread for TCP/IP driver and timer if needed.
	;	
		call	TcpipCreateThreadAndTimer
		jc	exit
	;
	; Determine the minimum header size to use and put it in CL.
	;
		cmp	ch, cl
		jb	haveSize		
		mov	cl, ch
haveSize:	
	;
	; Up the ref count of the link driver.  If the driver is the
	; main link driver, fill in main link entry in link table.
	; Else, add a new entry to the link table.
	;		
		mov	dx, bx			; es:dx = driver entry point
		mov	bx, bp
		call	GeodeAddReference
		
		call	TcpipCheckLinkIsMain	
		jnc	exit

		mov	bx, handle dgroup
		call	MemDerefDS
		;call	LinkTableAddEntry	; bx = domain handle
		clc
exit:
		.leave
		ret
TcpipAddDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipReceivePacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	TcpipReceivePacket

C DECLARATION:	extern void _far
		_far _pascal TcpipReceivePacket(optr dataBuffer);

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
TCPIPRECEIVEPACKET	proc	far		
		C_GetOneDWordArg cx, dx, ax, bx
		call	TcpipReceivePacket
		ret
TCPIPRECEIVEPACKET	endp
	SetDefaultConvention



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipReceivePacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive an incoming packet from the link connection.

CALLED BY:	TcpipClientStrategy (SCO_RECEIVE_PACKET)
		TCPIPRECEIVEPACKET

PASS:		cxdx	= optr of packet (HugeLMem chunk)

RETURN:		nothing

DESTROYED:	nothing 
		(DO NOT destroy AX even though we are not returning anything!)

PSEUDO CODE/STRATEGY:
		Add the packet to the input queue.
		If first packet, send msg to driver's thread to start
			processing input.
			
		logBrkPt is used for swat to set a breakpoint for logging
		the contents of the packet
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 7/94			Initial version
	jwu	10/31/96		use input queue

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipReceivePacket	proc	far
		uses	ax, bx, cx, di, es, ds
		.enter

if ERROR_CHECK
		Assert	optr cxdx				

	; verify the packet header					
		push	cx						
		mov	bx, cx						
		call	HugeLMemLock					
		mov	es, ax						
		mov	di, dx			; *es:di = PH of buffer 
		mov	di, es:[di]		; es:di =  PH of buffer	
logBrkPt::								
		mov	bx, es:[di].PH_domain				
		;call	ECCheckLinkDomainHandle	; carry set if invalid	
		mov	bx, cx						
		call	HugeLMemUnlock					
		pop	cx						
		ERROR_C TCPIP_INVALID_DOMAIN_HANDLE			
endif ; ERROR_CHECK

	;
	; Only process if TCP has a thread.
	;
		mov	bx, handle dgroup
		call	MemDerefES

		mov	ax, cx			; ^lax:dx = buffer
		mov	bx, es:[driverThread]
		tst	bx		
		je	discard			; no thread, can't deliver
	;
	; Try to add the packet to the input queue.
	;
		movdw	bxsi, es:[inputQueue]
		mov	cx, RESIZE_QUEUE
		call	QueueEnqueueLock	; ds:di = new element
		jc	noRoom

		movdw	ds:[di], axdx
		call	QueueEnqueueUnlock
	;
	; If this is the first packet in the queue, send msg to start
	; processing input.
	;
		call	QueueNumEnqueues		; cx = number
		cmp	cx, 1		
		ja	exit

		mov	bx, es:[driverThread]
		Assert	thread	bx
		mov	ax, MSG_TCPIP_RECEIVE_DATA_ASM
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
exit:		
		.leave
		ret

noRoom:
EC <		inc	es:[dropCount]					>

discard:
EC <		WARNING TCPIP_DISCARDING_INPUT_BUFFER			>
		mov	cx, dx			; ^lax:cx = buffer
		call	HugeLMemFree		
		jmp	exit

TcpipReceivePacket	endp

;---------------------------------------------------------------------------
;		Subroutines
;---------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGainAccess/TcpipReleaseAccess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get/release exclusive access.  Allows serialization of 
		some critical operations.

CALLED BY:	TcpipDisconnectRequest 
		TcpipStopSendData
		TcpipResetRequest
		TcpipSendData
			These are serialized to prevent destruction of a 
			connection while a send call is in progress for it.

		TcpipCloseMedium
		LinkOpenConnection
			Serialized to prevent link table from being altered
			while it is unlocked during link driver calls.

		TcpipLinkOpened
		TcpipLinkClosed
			Serialized to make sure client has a chance to
			adjust semCount before these routines check its
			value.

PASS:		nothing		

RETURN:		nothing

DESTROYED:	nothing (flags preserved by TcpipReleaseAccess)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/22/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGainAccessFar	proc	far
		call	TcpipGainAccess
		ret
TcpipGainAccessFar	endp

TcpipGainAccess	proc	near
		uses	ax, bx, ds
		.enter

		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[taskSem]
		call	ThreadPSem			; ax = SemaphoreError

		.leave
		ret
TcpipGainAccess	endp

TcpipReleaseAccessFar	proc	far
		call	TcpipReleaseAccess
		ret
TcpipReleaseAccessFar	endp

TcpipReleaseAccess	proc	near
		uses	ax, bx, ds
		.enter
		pushf

		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[taskSem]
		call	ThreadVSem

		popf
		.leave
		ret
TcpipReleaseAccess	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetMinDgramHdr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the minimum datagram header required by the link driver
		and add it to space needed by TCP to get the total space
		clients need to reserve in datagram buffers.

CALLED BY:	TcpipInit

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Load main link driver and get its driver info.
		Then free it.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 5/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetMinDgramHdr	proc	near
		uses	ax, bx, si, ds
		.enter

		clr	ax			; assume no extra space
		;call	LinkLoadLinkDriverFar	; bx = driver handle
		jc	done		

		call	GeodeInfoDriver		; ds:si = DriverInfoStruct
		mov	al, ds:[si].SDIS_minDgramHdr
		;call	LinkUnloadLinkDriverFar
done:
		add	es:[minDgramHdr], al

		.leave
		ret
TcpipGetMinDgramHdr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipRegisterNewClient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the TCP/IP driver is already registered, saving
		domain handle and entry point if this is the first 
		registration.  Does not check who the client is.

CALLED BY:	TcpipRegister

PASS:		cl	= SocketDriverType or TcpipDriverType
		bx	= domain handle
		es	= dgroup
		dx:bp	= SCO entry point

RETURN:		carry set if already registered
		ax = SDE_MEDIUM_BUSY
		else
		bx	= client handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Client handle is the bit mask for the type of client
		in RegisterStatus.

		The mask is 1 shifted left by SocketDriverType or
			TcpipDriverType.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/25/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipRegisterNewClient	proc	near

		uses	cx
		.enter
	;
	; Grab semaphore first.
	;
		push	bx	
		mov	bx, es:[regSem]
		call	ThreadPSem
		pop	bx
	;
	; Compute the client handle which is a RegisterStatus bit mask.
	;
		mov	ax, 1			
		shl	ax, cl				; ax = client handle

		test	es:[regStatus], ax
		jz 	register

		mov	cx, SDE_MEDIUM_BUSY		; cx = error
		stc
		jmp	done
register:
	;
	; Store registration info and return client handle.
	;
		ornf	es:[regStatus], ax
		xchg	bx, cx				; bl = SocketDriverType
							; cx = domain handle
		clr	bh				; bx = SocketDriverType
		mov	bl, cs:clientOffsetTable[bx]
		mov	es:[clients][bx].CI_domain, cx
		movdw	es:[clients][bx].CI_entry, dxbp
			
		mov_tr	cx, ax				; cx = client handle
		clc
done:
	;
	; Release semaphore.
	;
		mov	bx, es:[regSem]
		call	ThreadVSem		; flags preserved
		mov_tr	ax, cx			; ax = error or client handle
		jc	exit			; was error
		mov_tr	bx, ax			; bx = client handle
exit:		
		.leave
		ret

TcpipRegisterNewClient	endp

clientOffsetTable	byte \
	TCI_data,
	TCI_link,
	TCI_rawIp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipCheckLinkIsMain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if link driver adding itself as a domain is the 
		main link driver.  If so, fill in the link entry in
		the link table.

CALLED BY:	TcpipAddDomain

PASS:		ax	= client handle
		cl	= min header size
		es:dx	= driver entry point
		bp	= driver handle
		ds:si	= domain name (null terminated)

RETURN:		carry set if not main link
		else
			bx	= domain handle of link

DESTROYED:	bx if not returned

PSEUDO CODE/STRATEGY:
		Read domain name of link from INI (alloc block because
			we don't know size)
		compare with passed domain name
		if not equal, return carry set

		Get link entry
		EC:  die if main driver already loaded
		fill in info
		unlock link table
		
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 7/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipCheckLinkIsMain	proc	near
		uses	ax, cx, dx, di, si, ds, es
drvrHandle	local	hptr		push bp
clientHan	local	word		push ax
minHdrSize	local	word		push cx
drvrEntry	local	fptr		push es, dx
domainName	local	fptr		push ds, si
		.enter
	;
	; Read domain name from INI file.
	;
		push	bp				; locals
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov_tr	cx, ax
		assume	ds:Strings
		mov	dx, ds:[linkDomainKeyString]	; cx:dx = key string
		mov	si, ds:[categoryString]		; ds:si = category
		assume	ds:nothing
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, 0>
		call	InitFileReadString		; bx = block
		pop	bp				; locals

		push	bx
		mov	bx, handle Strings
		call	MemUnlock			; flags preserved
		pop	bx
EC <		WARNING_C TCPIP_MISSING_LINK_DOMAIN_INI_SETTING	>
		jc	exit
	;
	; Compare domain name with passed domain name.
	;
		lds	si, domainName			; ds:si = drvr domain
		call	MemLock
		segmov	es, ax		
		clr	di				; es:di = main domain 
		clr	cx				; null terminated
		call	LocalCmpStringsNoCase

		lahf
		call	MemFree				; destroys flags
		sahf
		stc					; assume no match
		jnz	exit			
	;
	; Get main link entry and fill in the info.
	;
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		;call	LinkTableGetEntry		; ds:di = LCB
							; ^hbx = table
EC <		tst	ds:[di].LCB_drvr				>
EC <		ERROR_NE TCPIP_MAIN_LINK_ALREADY_REGISTERED		>

		mov	ax, drvrHandle
		mov	ds:[di].LCB_drvr, ax
		mov	ax, clientHan
		mov	ds:[di].LCB_clientHan, ax
		mov	ax, minHdrSize
		mov	ds:[di].LCB_minHdr, al
		movdw	axcx, drvrEntry
		movdw	ds:[di].LCB_strategy, axcx

		call	MemUnlockExcl

		mov	bx, MAIN_LINK_DOMAIN_HANDLE	; return domain handle
		clc
exit:
		.leave
		ret
TcpipCheckLinkIsMain	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipCreateInputQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the input queue.  

CALLED BY:	TcpipInit

PASS:		es	= dgroup

RETURN:		carry set if failed

DESTROYED:	ax, bx, cx

NOTES:
		Alloc separate HugeLMem block for the input queue 
		because its size will change and we don't want to
		risk causing any protocol related packets to move
		unexpectedly.  Want to keep this change safe...

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/31/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipCreateInputQueue	proc	near
		uses	dx
		.enter

		mov	bx, handle InputQueue
		mov	ax, size optr
		mov	cl, INIT_INPUT_QUEUE_CAPACITY
		mov	dx, MAX_INPUT_QUEUE_CAPACITY
		call	QueueLMemCreate			; ^lbx:cx = queue
		jc	exit

		movdw	es:[inputQueue], bxcx
exit:
		.leave
		ret
TcpipCreateInputQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDestroyInputQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the input queue, freeing any packets still in it.

CALLED BY:	TcpipExit

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/31/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDestroyInputQueue	proc	near
		uses	bx, cx, dx, si
		.enter

		tstdw	ds:[inputQueue]
		jz	exit				; no queue was created
	;
	; Destroy packets in queue.
	;
		movdw	bxsi, ds:[inputQueue]
		mov	cx, SEGMENT_CS
		mov	dx, offset TcpipDestroyInputQueueCB
		call	QueueEnum
	;
	; Destroy queue.
	;
		mov	cx, si				; ^lbx:cx = queue
		call	QueueLMemDestroy

		clr	bx
		movdw	ds:[inputQueue], bxbx
exit:
		.leave
		ret
TcpipDestroyInputQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDestroyInputQueueCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free packet in input queue.

CALLED BY:	TcpipDestroyInputQueue via QueueEnum 

PASS:		es:si	= current queue element

RETURN:		nothing

DESTROYED:	ax, cx (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/31/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDestroyInputQueueCB	proc	far

EC <		WARNING TCPIP_DISCARDING_OUTPUT_BUFFER		>

		movdw	axcx, es:[si]
		call	HugeLMemFree
		ret

TcpipDestroyInputQueueCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipCreateThreadAndTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a thread for the TCP/IP driver if one does not 
		already exist.  Also start the TCP/IP timer.
		Might as well do GCN list registration here, too.

CALLED BY:	TcpipRegister
		TcpipAddDomain

PASS:		nothing
RETURN:		carry set if error
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/23/94			Initial version
	jwu	9/13/95			Added GCN code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipCreateThreadAndTimer	proc	near
		uses	ax, bx, cx, dx, di, si, bp, ds 
		.enter
	;
	; Check if the thread already exists.
	;
		mov	bx, handle dgroup
		call	MemDerefDS

		tst_clc	ds:[driverThread]
		jne	done
	;
	; Create the TCP/IP driver's thread.
	;		
		call	ImInfoInputProcess	; use input process as parent
		mov	si, handle 0		; we own the thread
		mov	bp, TCPIP_THREAD_STACK_SIZE
ifdef PASCAL_CONV
		mov	cx, segment _TcpipProcessClass
		mov	dx, offset _TcpipProcessClass
else
		mov	cx, segment TcpipProcessClass
		mov	dx, offset TcpipProcessClass
endif
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER
		mov	di, mask MF_CALL
		call	ObjMessage		; ax <- handle of new thread
EC <		WARNING_C TCPIP_UNABLE_TO_CREATE_THREAD		>
		jc	done
    ;
    ; Increase the thread's base priority.
    ;
		mov_tr	bx, ax				; bx = thread handle
        mov ah, mask TMF_BASE_PRIO
        mov al, PRIORITY_UI
        call ThreadModify
	;
	; Create input queue.
	;
	;
	; Start the timer that controls both TCP and IP timeouts.
	;
EC <		Assert	thread	bx				>		

		mov	ds:[driverThread], bx
		mov	ds:[clientThread], bx

		mov	al, TIMER_EVENT_CONTINUAL
		mov	cx, TCPIP_TIMEOUT_INTERVAL	; first interval
		mov	di, cx				; same interval always
		mov	dx, MSG_TCPIP_TIMEOUT_OCCURRED_ASM
		mov	bp, handle 0
		;call	TimerStartSetOwner

		mov	ds:[timerHandle], bx
	;
	; Add ourself to GCN list for access point notification.
	;
		mov	cx, ds:[driverThread]
		clr	dx
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_ACCESS_POINT_CHANGE
		call	GCNListAdd
		clc
done:
		.leave
		ret
TcpipCreateThreadAndTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipDestroyThreadAndTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the TCP/IP timer and destroy the TCP/IP driver's thread.
		Might as well do GCN unregistration here.

CALLED BY:	TcpipUnregiseter
		LINKTABLEDELETEENTRY via TcpipDestroyThreadAndTimerFar

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	di (preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/23/94			Initial version
	jwu	9/13/95			Added GCN code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipDestroyThreadAndTimerFar	proc	far
		call	TcpipDestroyThreadAndTimer
		ret
TcpipDestroyThreadAndTimerFar	endp

TcpipDestroyThreadAndTimer	proc	near
		uses	ax, bx, cx, dx, bp
		.enter
	;
	; Remove ourselves from the GCN list for access point netmask
	; changes.
	;
		mov	cx, es:[driverThread]
		clr	dx
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_ACCESS_POINT_CHANGE
		call	GCNListRemove
	;
	; Stop the TCP/IP timer.
	;
		clr	ax, bx			; ax = 0 for continual timers
		xchg	bx, es:[timerHandle]
EC <		tst	bx					>
EC <		ERROR_Z	TCPIP_CANNOT_FIND_TIMER			>
		;call	TimerStop
	;
	; Destroy all Tcp connections.  MUST do it on TCP's thread.
	;
		mov	bx, es:[driverThread]
		mov	ax, MSG_TCPIP_DESTROY_CONNECTIONS_ASM
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Finally, tell the driver's thread to self-destruct.
	;
		clr	bx
		xchg	bx, es:[driverThread]
EC <		Assert	thread	bx				>
		clr	cx, dx, bp		; no ack needed
		mov	ax, MSG_META_DETACH
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		ret
TcpipDestroyThreadAndTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipSendMsgToDriverThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the driver's thread.

CALLED BY:	TcpipDataConnectRequest
		TcpipDisconnectRequest
		TcpipResetRequest
		TcpipAttach
		TcpipReject
		TcpipSendData

PASS:		ax	= msg to send
		di	= connection handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/24/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipSendMsgToDriverThread	proc	near
		uses	bx, cx, di, ds
		.enter

		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[driverThread]
	
EC <		Assert	thread	bx				>		

		mov	cx, di			; cx = connection
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		ret
TcpipSendMsgToDriverThread	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipQueueSendDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait for space in output queue and then try to queue 
		the data again.  Caller has called TcpipGainAccess.

CALLED BY:	TcpipSendData

PASS:		ax	= connection handle
		bx	= timeout value 
		cx	= amount of data in buffer
		^ldx:si	= data buffer

RETURN:		carry set if data not queued, in which case, caller
			is responsible for freeing buffer
		ax	= SocketDrError (SDE_CONNECTION_TIMEOUT, 
					 SDE_INTERRUPTED, 
					 SDE_CONNECTION_RESET_BY_PEER,
					 SDE_CONNECTION_RESET)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If timeout is zero, free buffer and return carry set.
		Else {
			lock socket info block
			lock output queue and get header
			store amount of data pending in output queue header
			allocate semaphore and store handle in queue header
			unlock output queue
			unlock socket info block
			ThreadPTimedSem		

			Check SemaphoreError, if timeout, reset amount
				of pending data, free sem and return carry 
			else, setup params to SocketNewOutputData and free
				sem, returning results
		}
			
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/11/95			Initial version
	jwu	8/ 1/96			Interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipQueueSendDataRequest	proc	near
		uses	bx, cx, dx, di, si, ds
connection	local	word		push ax
timeout		local	word		push bx
dataSize	local	word		push cx
dataBuffer	local	optr		push dx, si
		.enter
	;
	; Only queue if connection still exists and is open.
	;
		;call	TSocketLockInfoListFar	; *ds:si = socket list

		push	cx
		;call	TSocketFindHandleNoLock	; destroys cx
		pop	cx
EC <		WARNING_C TCPIP_CONNECTION_DOES_NOT_EXIST	>
		jc	noQueue	

		mov	di, ax
		mov	di, ds:[di]		; ds:di = TcpSocket
		cmp	ds:[di].TS_state, TSS_OPEN
		je	goAhead
noQueue:
		;call	TSocketUnlockInfoExcl
		mov	ax, SDE_CONNECTION_RESET
		stc
		jmp	exit
goAhead:
	;
	; Store amount of pending data.  Allocate initially locked 
	; semaphore and store its handle.
	;
		mov	ds:[di].TS_pendingData, cx

		clr	bx
		call	ThreadAllocSem		; bx = semaphore handle
		mov	ds:[di].TS_sendSem, bx	
		;call	TSocketUnlockInfoExcl

		call	TcpipReleaseAccess

		mov	cx, timeout
		call	ThreadPTimedSem		; ax = SemaphoreError
	;
	; If we awoke because of timeout or an interrupt, clear 
	; pendingData and return carry set after freeing the semaphore.  
	; Else, try to queue the data again if the connection is still open.  
	; If we fail, free the semaphore and return error.
	;
		call	TcpipGainAccess

		;call	TSocketLockInfoExcl
		;mov	di, connection
		;mov	di, ds:[di]

		;mov_tr	cx, ax
		;mov	ax, SDE_CONNECTION_TIMEOUT		; assume timeout
		;cmp	cx, SE_TIMEOUT
		;je	dontSend

		;mov	ax, ds:[di].TS_error
		;cmp	ax, SDE_INTERRUPTED
		;je	dontSend

		;mov	ax, SDE_CONNECTION_RESET_BY_PEER	; assume closed
		;cmp	ds:[di].TS_state, TSS_OPEN
		;je	okayToSend				; carry clear
dontSend:
		;clr	cx
		;xchg	cx, ds:[di].TS_pendingData
		;stc
okayToSend:
		;call	TSocketUnlockInfoExcl
		;jc	freeSem

		push	bp
		mov	cx, dataSize
		mov	ax, connection
		movdw	dxbp, dataBuffer
		;call	TSocketNewOutputData	; carry set if failed
		pop	bp
freeSem:
		call	ThreadFreeSem		; preserves flags
exit:
		.leave
		ret

TcpipQueueSendDataRequest	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipSendDatagramCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an IP datagram.

CALLED BY:	TcpipSendDatagram
		TcpipSendRawIp

PASS:		cx	= message for driver's thread
		bx	= client handle
		dx:bp	= databuffer
		ds:si	= remote address (non-null terminated string)
		ax	= address size

RETURN:		carry set if error
		ax = SocketDrError

DESTROYED:	cx	(saved by caller)

PSEUDO CODE/STRATEGY:
		EC:  verify addr size
		EC:  verify client is registered
		EC:  verify header of datagram packet
		Open link connection
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/14/94		Initial version
	ed	06/15/00		DHCP support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipSendDatagramCommon	proc	near
		uses	bx, di, si, ds, es
		.enter

if ERROR_CHECK
		call	ECCheckIPAddrSize			

		push	ds					
		push	bx					
		mov	bx, handle dgroup			
		call	MemDerefDS				
		pop	bx					
		test	ds:[regStatus], bx			
		ERROR_Z	TCPIP_NOT_REGISTERED			
		pop	ds					

		push	es, bx, cx, si				
		mov	cx, bx					
		mov	bx, dx					
		call	HugeLMemLock				
		mov	es, ax					
		mov	si, es:[bp]				
		cmp	cx, mask RS_RAW_IP			
		jne	checkOffset				
		cmp	es:[si].PH_flags, mask RIF_IP_HEADER	
		je	unlock					
checkOffset:						
		mov	ax, es:[si].PH_dataOffset		
		cmp	ax, TCPIP_DATAGRAM_PACKET_HDR_SIZE	
		ERROR_B	TCPIP_BAD_PACKET_HEADER			
unlock:							
		call	HugeLMemUnlock				
		pop	es, bx, cx, si				
endif ; ERROR_CHECK

	; DHCP workaround. When the time comes to send DHCP packets,
	; the link will be open, but the link structure will be exclusively
	; locked, therefore any attempts at checking if the link is open
	; will cause a deadlock. So, we compare the current thread handle
	; to the saved DHCP thread handle. If they match, then we know it's
	; safe to jump past the attempts to gain a lock.
	;		- Ed 6/15/00
if 0
		mov	ax, dgroup
		mov	es, ax
		mov	ax, es:[dhcpThread]
		cmp	ax, ss:[0].TPD_threadHandle
		je	doingDhcp
endif

	;
	; Check PacketFlags to see if link should be forced open. 
	;
		push	si
		mov	bx, dx
		call	HugeLMemLock
		mov	es, ax
		mov	si, es:[bp]
		test	es:[si].PH_flags, mask PF_OPEN_LINK	
		call	HugeLMemUnlock
		pop	si

		mov	bx, cx				; bx = msg
		jnz	openLink
		;call	LinkCheckOpen			; ax = link handle
		jmp	checkResult
openLink:
	;
	; Open link connection.
	;
		mov	cx, TCP_LINK_OPEN_WAIT_TIME
		;call	LinkOpenConnection		; ax = link handle
checkResult:
		jnc	sendIt
	; 
	; Free the data buffer since we can't send it.  Datagrams are 
	; supposed to be unreliable...  AX already contains error from 
	; LinkOpenConnection.
	;
EC <		WARNING TCPIP_DISCARDING_OUTPUT_BUFFER		>
		xchg	ax, dx				; dx = error
		mov	cx, bp				; ^lax:cx = buffer
		call	HugeLMemFree		
		xchg	ax, dx				; ax = error
		jmp	bad
sendIt:	
	;
	; Queue a message for driver's thread to send datagram.
	;
		mov_tr	cx, ax				; cx = link
		mov_tr	ax, bx				; ax = msg
		mov	bx, handle dgroup
		call	MemDerefDS
if 0
sendDhcp:
endif
		mov	bx, ds:[driverThread]
		mov	di, mask MF_CALL
		call	ObjMessage			; ax = SocketDrError

		tst_clc	ax
		je	exit
bad:
		stc
exit:		
		.leave
		ret
if 0
doingDhcp:
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	ax, ds
		mov	ax, cx
		mov	cx, ds:[dhcpDomain]
		jmp	sendDhcp
endif
TcpipSendDatagramCommon	endp

COMMENT @----------------------------------------------------------------

C FUNCTION:	TcpipDetachAllowed

DESCRIPTION: 	Determine if the TCP thread is allowed to be destroyed.
		Returns non-zero if detach is allowed.		

C DECLARATION:	extern word _far
		_far _pascal TcpipDetachAllowed(void);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/10/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TCPIPDETACHALLOWED		proc	far

	;
	; If no clients, close all links and allow detach.
	; If registered client is not the one this thread was created
	; for, allow detach, but don't close the links as the new
	; client may be using it.  Otherwise, reject detach.
	;
		segmov	es, ds, ax			; es = dgroup

		mov	bx, es:[regSem]
		call	ThreadPSem

		mov	cx, TRUE
		tst	es:[regStatus]
		jnz	checkThread

		;call	CloseAllLinks
		jmp	done
checkThread:
		mov	ax, ss:[TPD_threadHandle]
		cmp	ax, es:[clientThread]
		jne	done
		mov	cx, FALSE
done:
		call	ThreadVSem			; destroys ax
		mov_tr	ax, cx
		ret

TCPIPDETACHALLOWED		endp
	SetDefaultConvention




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipResolveIPAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve the IP part of the extended address.

CALLED BY:	TcpipResolveAddr

PASS:		ds:si 	= unresolved IP addr
		cx	= unresolved IP addr size
		dx	= access ID or 0 if none

RETURN:		carry clear if successful
			dxax 	= IP address in network order
		else
		carry set
			ax	= SocketDrError (SDE_INVALID_ADDR,
						 SDE_DESTINATION_UNREACHABLE,
						 SDE_TEMPORARY_ERROR,
						 SDE_INSUFFICIENT_MEMORY,
						 SDE_UNSUPPORTED_FUNCTION,
						 SDE_INTERRUPTED)

DESTROYED:	cx, bp

PSEUDO CODE/STRATEGY:
		If first character is a digit, parse the dotted decimal
		IP address into the binary form.  If not parsable, assume
		address needs to be resolved.

		Else, load resolver and have it do the query.  Unload 
		the driver when done.
		
		If error, return the proper errors.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/16/95			Initial version
	jwu	12/17/97		non-decimal addr can begin w/digit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipResolveIPAddr	proc	near
		uses	bx
		.enter
	;
	; If address is in dotted decimal notation, convert to binary.
	; Address is assumed to be in dotted decimal notation if the
	; first character is a digit. (RFC 1034, section 3.5)
	;
DBCS <		shr	cx				; cx = addr *length* >
		clr	ax
		LocalGetChar	ax, dssi, NO_ADVANCE
		call	LocalIsDigit
		jz	doQuery

		call	IPParseDecimalAddr		; dxax = address
		jc	invalid
checkValid:
		call	TcpipCheckValidIPAddr
		jnc	exit
invalid:
	;
	; Address begins with digit but parser detected it is not
	; a valid decimal IP address.  Turns out addresses can now
	; begin with a digit.  If there are any alpha chars, try
	; resolving.  Else, return invalid IP addr.    --jwu 12/17/97
	; 
		push	si, cx
alphaLoop:
		clr	ax
		LocalGetChar	ax, dssi
		call	LocalIsAlpha
		jnz	endAlphaLoop			; alpha found
		loop	alphaLoop
endAlphaLoop:
		pop	si, ax
		tst	cx
		mov	cx, ax			; cx = size, flags preserved
		jnz	doQuery

		mov	ax, SDE_INVALID_ADDR
		jmp	setC
doQuery:
	;
	; Query address from resolver.
	; 
		push	bx
		mov	ax, 1000			; resolve address
							; dxbp = addr or
							;  dx = ResolverError
		int	0xB0
		
		;lahf

		;sahf
		;mov	ax, bp				; dxax = resolved addr
		clc
		cmp	bx, 0
		je	noC
		stc
noC:
		pop 	bx
		jnc	checkValid
	;
	; Convert ResolverError to SocketDrError.
	;
		;mov	ax, SDE_DESTINATION_UNREACHABLE
		;cmp	dx, size ResolverToSDETable
		;jae	setC

		;mov	bx, dx				; bx = ResolverError
		;mov	al, cs:ResolverToSDETable[bx]
setC:
		stc
exit:
		.leave
		ret
TcpipResolveIPAddr	endp

ifndef STATIC_LINK_RESOLVER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipLoadResolver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the resolver.

CALLED BY:	TcpipResolveIPAddr

PASS:		nothing

RETURN:		carry set if error
			ax	= SDE_DRIVER_NOT_FOUND
		else 
			ax 	= library handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/13/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString	resolverName, <"EC Resolver", 0>	>
NEC<LocalDefNLString	resolverName, <"Resolver", 0>	>

TcpipLoadResolver	proc	near
		uses	bx, si, ds
		.enter

		call	FilePushDir

		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		jc	error

		clr	ax, bx
		segmov	ds, cs, si
		mov	si, offset resolverName
		call	GeodeUseLibrary			; bx = handle of library
error:
		call	FilePopDir
		mov	ax, SDE_DRIVER_NOT_FOUND	; just in case
		jc	exit
		mov_tr	ax, bx				; return handle
exit:
		.leave
		ret
TcpipLoadResolver	endp

endif   ; not STATIC_LINK_RESOLVER



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipGetDefaultIPAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the default remote IP address (for use when making
		a direct connection to another device).

CALLED BY:	TcpipResolveAddr

PASS:		dx	= access ID

RETURN:		dxax	= IP address (in network order)

DESTROYED:	ds 

PSEUDO CODE/STRATEGY:
		If link is open, get local address to determine if we
		are client or server.
		Else, return server address because we'll be dialing up
		to a server to open the link.

		EC code verifies that the address on the link is the
		server address if the client address is used.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipGetDefaultIPAddr	proc	near
		uses	bx, di
		.enter

		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		;call	LinkTableGetEntry		; ds:di = LCB
							; ^hbx = tabke
		cmp	ds:[di].LCB_state, LS_OPEN
		jne	useServer

		movdw	dxax, DEFAULT_CLIENT_IP_ADDR
		cmpdw	dxax, ds:[di].LCB_localAddr
		jne	done
useServer:
		movdw	dxax, DEFAULT_SERVER_IP_ADDR
done:

EC <		cmpdw	dxax, DEFAULT_CLIENT_IP_ADDR			  >
EC <		jne	okay						  >
EC <		push	bx						  >
EC <		cmpdw	ds:[di].LCB_localAddr, DEFAULT_SERVER_IP_ADDR, bx >
EC <		WARNING_NE TCPIP_USING_STRANGE_CLIENT_SERVER_ADDRESS	  >
EC <		pop	bx						  >
EC <okay:								  >
		call	MemUnlockExcl

		.leave
		ret
TcpipGetDefaultIPAddr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TcpipCheckValidIPAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quick validation of a resolved IP address.

		All 0's or all 1's is an invalid address.
		Host number for each class of IP address is all 1's 
			is an invalid address:
			Class A: 0--- ---- 1111 1111 1111 1111 1111 1111
			Class B: 10-- ---- ---- ---- 1111 1111 1111 1111
			Class C: 110- ---- ---- ---- ---- ---- 1111 1111
		First 3 bits are 1's is an invalid address:
			Class D: 1110 ---- ---- ---- ---- ---- ---- ----
			Class E: 1111 ---- ---- ---- ---- ---- ---- ----



CALLED BY:	TcpipResolveIPAddr
		ECCheckIPAddr

PASS:		dxax	= IP addr in network order
				(e.g. if IP address is 1.2.3.4,
					al = 1, ah = 2, dl = 3, dh = 4)

RETURN:		carry set if invalid

DESTROYED:	nothing


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/03/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TcpipCheckValidIPAddr	proc	near
		uses	ax, bx, cx, dx, di
		.enter
	;
	; Get address in host format instead of network format so
	; we can easily do comparisons against dwords.
	;
		xchg	dx, ax
		xchg	ah, al
		xchg	dh, dl			; dxax is addr in host format
	;
	; Check for all 0's or all 1's.	
	;
		tstdw	dxax				
		jz	invalid

		movdw	cxbx, dxax
		notdw	cxbx				
		tstdw	cxbx
		jz	invalid
	;
	; Check for class broadcast, multicast, or experimental address.
	;		
		mov	di, 12			; offset into tables
checkLoop:
		movdw	cxbx, cs:[maskTable][di]	
		and	cx, dx
		and	bx, ax
		cmpdw	cxbx, cs:[resultTable][di]
		je	invalid
		sub	di, 4			; dword entries in table
		jns	checkLoop	

		clc				; all's well...
		jmp	done
invalid:
		stc
done:
		.leave
		ret
TcpipCheckValidIPAddr	endp


maskTable	dword \
	0x80ffffff,	; Class A broadcast address
	0xc000ffff,	; Class B broadcast address
	0xc00000ff,	; Class C broadcast address
	0xe0000000	; Class D or E address

resultTable	dword \
	0x00ffffff,	
	0x8000ffff,
	0xc00000ff,
	0xe0000000

if ERROR_CHECK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckClientHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify client handle and ensure client is registered.

CALLED BY:	TcpipUnregister
		TcpipSendDatagram
		TcpipMediumConnectRequest

PASS:		bx	= client handle

RETURN:		only if client handle is valid 

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/27/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckClientHandle	proc	near

		cmp	bx, mask RS_DATA
		je	checkReg

		cmp	bx, mask RS_LINK
		je	checkReg

		cmp	bx, mask RS_RAW_IP
		ERROR_NE TCPIP_INVALID_CLIENT_HANDLE
checkReg:
		push	es
		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx
		test	es:[regStatus], bx
		ERROR_Z TCPIP_NOT_REGISTERED
		pop	es

		ret
ECCheckClientHandle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckIPAddrSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify IP address size.

CALLED BY:	TcpipSendDatagramCommon
		TcpipLinkConnectRequest
		TcpipDataConnectRequest
		TcpipMediumConnectRequest

PASS:		ds:si	= remote address (non-null terminated string)
		ax	= address size

RETURN:		only if size is valid		

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 6/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckIPAddrSize	proc	near
		push	ax
		sub	ax, ds:[si].ESACA_linkSize
		dec	ax				; exclude byte for size
		dec	ax
		cmp	ax, IP_ADDR_SIZE
		ERROR_NE TCPIP_INVALID_IP_ADDRESS
		pop	ax
		ret
ECCheckIPAddrSize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckIPAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify address is not a broadcast, multicast address or
		an experimental address.

CALLED BY:	TcpipDataConnectRequest

PASS:		ds:si	= string containing IP address (non-null terminated)

RETURN:		only if address is valid

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/ 3/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckIPAddr	proc	near
		uses	ax, dx, di
		.enter
	;
	; Get address, advancing address past any link params and
	; the word indicating the size of the link params. 
	;		
		mov	di, si
		mov	dx, ds:[di]		; dx = size of link part
		add	di, dx
		inc	di
		inc	di			
		movdw	dxax, ds:[di]		

		call	TcpipCheckValidIPAddr
		ERROR_C	TCPIP_INVALID_IP_ADDRESS			

		.leave
		ret
ECCheckIPAddr	endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCallerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure TCP is not being called with its own thread.

CALLED BY:	TcpipRegister
		TcpipUnregister
		TcpipLinkConnectRequest
		TcpipDataConnectRequest
		TcpipDisconnectRequest
		TcpipSendData
		TcpipSendDatagram
		TcpipResetRequest
		TcpipAttach
		TcpipReject
		TcpipCloseMedium
		TcpipMediumConnectRequest
		TcpipSendRawIp

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Print a warning if TCP is being called by its own thread.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/27/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckCallerThread	proc	near
		uses	bx, ds
		.enter

		mov	bx, handle dgroup
		call	MemDerefDS
		
		mov	bx, ss:[TPD_threadHandle]
		cmp	bx, ds:[driverThread]
		WARNING_E TCPIP_CALLED_WITH_OWN_THREAD

		.leave
		ret
ECCheckCallerThread	endp


endif	; ERROR_CHECK

;
; See comments on SocketResolveLinkLevelAddress... same pass/return
; Currently only works if the link is already open, as I can't figure out
; how to open it myself... - Ed 6/00
;
TcpipResolveLinkLevelAddress	proc	far
		bufSize		local	word	push	bx
		sockAddrPtr	local	fptr	push	ds, si
		.enter

		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		;call	LinkTableGetEntry	; ds:di = LCB
		push	bx
		mov	bl, ds:[di].LCB_state
		mov	si, bx
		pop	bx
		pushdw	ds:[di].LCB_strategy
		call	MemUnlockExcl
		mov	di, DR_SOCKET_RESOLVE_LINK_LEVEL_ADDRESS
		mov	bx, si
		cmp	bl, LS_OPEN
		jne	linkClosed
		movdw	dssi, sockAddrPtr
		mov	bx, bufSize
		call	PROCCALLFIXEDORMOVABLE_PASCAL

rllaDone:
		.leave
		ret

linkClosed:
		add	sp, 6
		movdw	dssi, sockAddrPtr
		mov	ax, SE_LINK_FAILED
		jmp	rllaDone
TcpipResolveLinkLevelAddress	endp



CommonCode	ends
