COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		
FILE:		slip.asm

AUTHOR:		Jennifer Wu, Sep 12, 1994

ROUTINES:
	Name			Description
	----			-----------
	SlipStrategy

Driver Routines:
----------------
	SlipDoNothing
	SlipError

	SlipInit
	SlipExit
	SlipSuspend
	SlipRegister
	SlipUnregister

	SlipAllocConnection
	SlipLinkConnectRequest
	SlipStopLinkConnect
	SlipDisconnectRequest

	SlipSendDatagram

	SlipResetRequest
	SlipGetInfo
	SlipResolveAddr

	SlipMediumActivated

Driver setup:
-------------
	SlipGainAccess
	SlipReleaseAccess
	
	SlipLoadSerialDriver
	SlipGetInitFileInfo
	SlipReadInitFileInteger
	SlipFindLocalAddress
	SlipAsciiToIpAddr

	SlipAllocThread
	SlipDestroyThread
	SlipAllocSem
	SlipDestroySem

	SlipGetClientIfNone
	SlipLoadTcpDriver
	SlipRegisterTcpDriver

	SlipLinkOpened
	SlipLinkClosed

Input/Output:
-------------	
	SlipOpenSerialPort
	SlipCloseSerialPort
	SlipSend

	SlipReceiveData
	SlipProcessInputByte
	SlipDecodeByte

	SlipAllocDataBuffer
	SlipDeliverPacket
	SlipDownsizeBuffer
	SlipGetBuffer
	SlipFreeBuffer

Methods:
--------	
	SlipOpenLink
	SlipCloseLink
	SlipVerifyConnection
	SlipProcessInput
	SlipDetach

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	9/12/94		Initial revision

DESCRIPTION:
	Main code for slip driver.

	$Id: slip.asm,v 1.1 97/04/18 11:57:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;	Dgroup
;---------------------------------------------------------------------------

idata 	segment
	;
	; Need this so we can call superclass because kernel code expects
	; first word in segment of process class to be a handle.  As we
	; created this in a driver, this isn't automatically true for us.
	; 
	myHandle	hptr	handle 0 
	
	DriverTable	SocketDriverInfoStruct <
		<SlipStrategy,
		0,
		DRIVER_TYPE_SOCKET>,
		0,
		(mask SDPO_MAX_PKT or mask SDPO_UNIT \
		 or mask SDPO_BAUDRATE),
		0
	>
	
	slipPort	SerialPortNum SERIAL_COM1
	localAddr	IPAddr <192, 0, 2, 1>	
	slipBaud	SerialBaud	SB_9600
	maxFrame	word	SLIP_MIN_MTU

EC <	outputBuffer	char	BUFFER_SIZE dup (0xff)			>
EC <	outBufPtr	nptr	offset outputBuffer			>
EC <	outBufEnd	nptr	(offset outputBuffer + BUFFER_SIZE)	>

idata	ends

ForceRef myHandle
ForceRef DriverTable


udata 	segment
	
	slipThread	hptr.HandleThread	; handle of slip driver's thread
	hugeLmem	hptr			; handle of huge lmem block
	slipSem		hptr			; for blocking open requests
	statusSem	hptr			; mutex for checking status
	slipStatus	SlipDrStatus		

		CheckHack <SS_CLOSED eq 0>
	slipState	SlipState  		

		CheckHack <SDE_NO_ERROR eq 0>
	slipError	SocketDrError	

	timerHan	hptr			; timer used to verify slip
	timerID		word			; connections started by lurker

	domain		word			; our assigned domain handle
	clientEntry	fptr			; SCO entry point of client
	
	serialStrategy	fptr			
	serialDrvr	hptr			
	
	inputBuffer	hptr			; handle of input buffer's block
	inputEnd	word			; end of input data
	inputStart	word			; start of input data

	count		word			; # of bytes in slip frame
	dataPtr		fptr			; address of data in buffer
	dataBuffer	optr			; optr of huge lmem chunk
						;  holding slip frame
					
if _TIA
	loginSize	byte			; size of login	
	login		SlipLogin

	passwordSize	byte			; size of password
	password	SlipPassword
endif
 
udata	ends		


;---------------------------------------------------------------------------
;		Ini File Strings (have to be SBCS)
;---------------------------------------------------------------------------
Strings	segment		lmem	LMEM_TYPE_GENERAL
	slipCategory	chunk.char "slip",0
	portKey		chunk.char "port",0
	addrKey		chunk.char "addr",0
	baudKey		chunk.char "baud",0
	maxFrameKey	chunk.char "maxFrame",0
	portDriverKey	chunk.char "portDriver",0
Strings	ends

;---------------------------------------------------------------------------
;		Strategy Routines
;---------------------------------------------------------------------------

ResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all SLIP driver calls.

CALLED BY:	Tcpip Driver

PASS:		di	= SocketFunction
		see specific routine for other arguments

RETURN:		carry set if some error occurred
		see specific routines for return values

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version
	jwu	8/12/96			Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipStrategy	proc	far
		uses	di
		.enter
	;
	; Call the procedure to process the driver function.
	;
		shl	di, 1			; index (4-byte) fptrs
		cmp	di, size driverProcTable
		jae	badCall

		pushdw	cs:driverProcTable[di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
exit:
		.leave
		ret
badCall:
		mov	ax, SDE_UNSUPPORTED_FUNCTION
		stc						
		jmp	exit				


SlipStrategy	endp

driverProcTable		fptr.far	\
		SlipInit, 		
		SlipExit, 		
		SlipSuspend,		
		SlipDoNothing,		; DR_UNSUSPEND
		SlipRegister,		
		SlipUnregister,		
		SlipAllocConnection,	
		SlipLinkConnectRequest,	
		SlipDoNothing,		; DR_SOCKET_DATA_CONNECT_REQUEST
		SlipStopLinkConnect,	
		SlipDisconnectRequest,	
		SlipError,		; DR_SOCKET_SEND_DATA
		SlipDoNothing,		; DR_SOCKET_STOP_SEND_DATA
		SlipSendDatagram,
		SlipResetRequest,
		SlipError,		; DR_SOCKET_ATTACH
		SlipError,		; DR_SOCKET_REJECT
		SlipGetInfo,		
		SlipDoNothing,		; DR_SOCKET_SET_OPTION
		SlipDoNothing,		; DR_SOCKET_GET_OPTION
		SlipResolveAddr,	
		SlipDoNothing,		; DR_SOCKET_STOP_RESOLVE
		SlipDoNothing,		; DR_SOCKET_CLOSE_MEDIUM
		SlipDoNothing,		; DR_SOCKET_MEDIUM_CONNECT_REQUEST
		SlipMediumActivated,
		SlipDoNothing,		; DR_SOCKET_SET_MEDIUM_OPTION
		SlipDoNothing		; DR_SOCKET_RESOLVE_LINK_LEVEL_ADDRESS

ResidentCode	ends


;---------------------------------------------------------------------------
;		Driver Functions
;---------------------------------------------------------------------------

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipDoNothing/SlipError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SlipDoNothing:  clear carry
		SlipError:	set carry

CALLED BY:	SlipStrategy

PASS:		nothing

RETURN:		carry clear/set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipDoNothing	proc	far
		clc
		ret
SlipDoNothing	endp

SlipError	proc	far
		stc
		ret
SlipError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the slip driver.

CALLED BY:	SlipStrategy

PASS:		nothing

RETURN:		carry set if driver initialization failed
		carry clear if initializatino succeeded

DESTROYED:	ax, cx, dx, di, si, bp, ds, es (allowed)

PSEUDO CODE/STRATEGY:
		Load appropriate serial driver
		Initialize slip state to closed
		 and status to no waiter, not registered
		Load login and password from special file
		Alloc huge lmem block
		Alloc semaphore
		Allocate block for input buffer.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipInit	proc	far
		uses	bx
		.enter
	;
	; Load appropriate serial driver and get serial strategy 
	; routine.
	;
		mov	bx, handle dgroup
		call	MemDerefES		; es = dgroup

		call	SlipLoadSerialDriver	; bx = handle
		jc	exit
		call	GeodeInfoDriver		; ds:si = DriverInfoStruct
		movdw	bxax, ds:[si].DIS_strategy
		movdw	es:[serialStrategy], bxax
	;
	; Get INI info.
	;		
		call	SlipGetInitFileInfo	; destroys all but ES
if _TIA	
	;
	; Load login and password strings.
	;
		call	SlipGetLoginInfo
		jc	exit
endif	
	;
	; Allocate block for input buffer and make sure we own it.
	;
		mov	ax, BUFFER_SIZE
		mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE
		mov	bx, handle 0
		call	MemAllocSetOwner		; bx = block handle
		jc	exit
	
		mov	es:[inputBuffer], bx
	;
	; Allocate huge lmem.
	;
		clr	ax				; use default
		mov	bx, SLIP_OPTIMAL_BLOCK_SIZE
		mov	cx, bx				; max = min size
		call	HugeLMemCreate			; bx = mem handle
		jc	exit
		
		mov	es:[hugeLmem], bx
	;
	; Allocate semaphore for access to slip status.
	;
		mov	bx, 1				; initially unlocked
		call	ThreadAllocSem		
		mov	es:[statusSem], bx			
		
		mov	ax, handle 0			; we own the sem!
		call	HandleModifyOwner
		clc					; driver initialized
exit:
		.leave
		ret
SlipInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the slip driver.

CALLED BY:	SlipStrategy

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, ds, es (allowed)

PSEUDO CODE/STRATEGY:
		EC: Ensure state is closed
		EC: Ensure no caller blocked on semaphore
		Free input buffer block (if allocated)
		Free huge lmem block (if allocated)
		Free sem 
 
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipExit	proc	far

		mov	bx, handle dgroup
		call	MemDerefDS			; ds = dgroup

EC <		cmp	ds:[slipState], SS_CLOSED		>
EC <		WARNING_NE SLIP_EXITING_BEFORE_LINK_CLOSED	>

EC <		test	ds:[slipStatus], mask SDS_WAITER_EXISTS	>
EC <		WARNING_NZ SLIP_EXITING_WITH_WAITER_BLOCKED	>

	;
	; Unload serial driver, if loaded.  If not, nothing else
	; was done so it's okay to exit.
	;
		clr	bx
		xchg	bx, ds:[serialDrvr]
		tst	bx
		je	exit		
		call	GeodeFreeDriver
	;
	; Free input buffer which would only exists by now if this
	; is a dirty shutdown so force the destroy.
	;
		clr	bx, cx
		xchgdw	bxcx, ds:[dataBuffer]
		tstdw	bxcx
		je	freeInput
EC <		WARNING SLIP_DESTROYING_INCOMPLETE_FRAME	>
		call	HugeLMemForceDestroy
freeInput:
	;
	; Free input buffer block, if allocated.  If not allocated, then
	; huge lmem block was not allocated so it is safe to exit.
	;
		clr	bx
		xchg	bx, ds:[inputBuffer]
		tst	bx
		je	exit
		
		call	MemFree
	;
	; Free huge lmem block, if allocated.  If not, then semaphore was
	; never allocated so again, it is safe to exit.
	;
		clr	bx
		xchg	bx, ds:[hugeLmem]
		tst	bx
		je	exit

		call	HugeLMemDestroy
	;
	; Free semaphore for access to slip status.  
	;
		clr	bx
		xchg	bx, ds:[statusSem]
		call	ThreadFreeSem
exit:
		ret
SlipExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend the slip driver.

CALLED BY:	SlipStrategy

PASS:		cx:dx	= buffer in which to place reason for refusal
 			   (DRIVER_SUSPEND_ERROR_BUFFER_SIZE bytes long)

RETURN:		carry set if suspension refused
		cx:dx	= buffer filled with null-terminated reason
		carry clear if suspension approved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipSuspend	proc	far
		uses	ax, bx, si, di, ds, es
		.enter

		mov	bx, handle dgroup
		call	MemDerefDS			; ds = dgroup
		cmp	ds:[slipState], SS_CLOSED
		je	exit
	;
	; Refuse suspension.  Give reason.
	;
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, offset refuseSuspendString
		mov	si, ds:[si]			; ds:si = refusal string
		movdw	esdi, cxdx			; es:di = dest buffer
		LocalCopyString
		
		call	MemUnlock
		stc
exit:
		.leave
		ret
SlipSuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a client.

CALLED BY:	SlipStrategy

PASS:		bx	= domain handle of driver
		dx:bp	= client entry point for SCO functions
		cl	= SocketDriverType  (SDT_LINK)

RETURN:		carry set if error
		ax	= SocketDrError (SDE_ALREADY_REGISTERED)
					(SDE_MEDIUM_BUSY)
		bx	= client handle
		ch	= min hdr size for outgoing sequenced packets
		cl	= min hdr size for outgoing datagram packets

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipRegister	proc	far
		uses	dx, si, ds
		.enter
		
EC <		cmp	cl, SDT_LINK				>		
EC <		ERROR_NE SLIP_INVALID_SOCKET_DRIVER_TYPE	>
	;
	; If slip driver is already registered, deny this request.
	;		
		mov_tr	ax, bx				; ax = domain
		mov	bx, handle dgroup
		call	MemDerefDS
		call	SlipGainAccess
		test	ds:[slipStatus], mask SDS_REGISTERED
		jnz	isBusy
	;
	; Mark slip driver as registered, save domain handle and entry point.
	;		
		BitSet	ds:[slipStatus], SDS_REGISTERED
		mov	ds:[domain], ax
		movdw	ds:[clientEntry], dxbp
	;
	; Create the thread.  Return header sizes and client handle.
	;
		call	SlipAllocThread

		mov	bx, SLIP_CLIENT_HANDLE	; assume registered
		mov	cx, (size DatagramPacketHeader shl 8) or \
				size DatagramPacketHeader
		clc				
		jmp	releaseSem
isBusy:
		mov	ax, SDE_MEDIUM_BUSY		
		stc
releaseSem:	
		call	SlipReleaseAccess	; flags preserved
exit::
		.leave
		ret


SlipRegister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister the client with the slip driver.

CALLED BY:	SlipStrategy

PASS:		bx	= client handle

RETURN:		bx	= domain handle

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipUnregister	proc	far
		uses	ax, cx, dx, bp, ds
		.enter
	
EC <		cmp	bx, SLIP_CLIENT_HANDLE			>
EC <		ERROR_NE SLIP_INVALID_CLIENT_HANDLE		>		

		mov	bx, handle dgroup
		call	MemDerefDS
		call	SlipGainAccess

EC <		cmp	ds:[slipState], SS_CLOSED		>
EC <		ERROR_NE SLIP_CONNECTION_MUST_BE_CLOSED_FIRST	>
EC <		test	ds:[slipStatus], mask SDS_REGISTERED	>
EC <		ERROR_Z	SLIP_NOT_REGISTERED			>

		BitClr	ds:[slipStatus], SDS_REGISTERED
	;
	; Clear client entry and stop timer for verifying SLIP 
	; connections started by lurker.
	;		
		clr	ax, bx
		movdw	ds:[clientEntry], axbx

		xchg	bx, ds:[timerHan]
		xchg	ax, ds:[timerID]
		tst	bx
		jz	destroyThread
		call	TimerStop
destroyThread:
		call	SlipDestroyThread
		mov	bx, ds:[domain]			; return domain handle
		call	SlipReleaseAccess
		
		.leave
		ret
SlipUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipAllocConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assign a connection handle to client for use with
		DR_SOCKET_LINK_CONNECT_REQUEST.

CALLED BY:	SlipStrategy

PASS:		bx	= client handle

RETURN:		carry clear
		ax 	= connection handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/12/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipAllocConnection	proc	far

EC <		cmp	bx, SLIP_CLIENT_HANDLE			>
EC <		ERROR_NE SLIP_INVALID_CLIENT_HANDLE		>	

		mov	ax, SLIP_CONNECTION_HANDLE
		clc

		ret
SlipAllocConnection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipLinkConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open link connection.

CALLED BY:	SlipStrategy

PASS:		cx	= timeout value	in ticks (ignored)
		bx	= connection handle
		ds:si	= non-null terminated addr to connect to (ignored)
		ax	= addr string size (ignored)

RETURN:		carry clear if successful
		else
		carry set
		ax	= SocketDrError (SDE_INTERRUPTED)

DESTROYED:	di (allowed)
		ax if not returned

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version
	jwu	8/12/96			Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipLinkConnectRequest	proc	far
		uses	bx, ds
		.enter

EC <		cmp	bx, SLIP_CONNECTION_HANDLE		>
EC <		ERROR_NE SLIP_INVALID_CONNECTION_HANDLE		>	
	
	;
	; If closed, open it.    If interrupted, return error.
	;		
		mov	bx, handle dgroup
		call	MemDerefDS
		call	SlipGainAccess
		
		clr	ax
		xchg	ax, ds:[slipError]
		cmp	ax, SDE_INTERRUPTED
		jne	checkState

EC <		cmp	ds:[slipState], SS_CLOSED		>
EC <		ERROR_NE SLIP_INTERNAL_ERROR			>
		stc
		jmp	done
		
checkState:
	;
	; If state is not closed, then the link is opening.  Return
	; success.
	;
		CheckHack <SS_CLOSED eq 0>
		cmp	ds:[slipState], SS_CLOSED
		ja	done			

	;
	; Set state to connecting so no other requests get queued.
	; Queue a message for the driver to open the link.  
	;
		mov	ds:[slipState], SS_CONNECTING

		mov	bx, ds:[slipThread]
		mov	ax, MSG_SLIP_OPEN_LINK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		clc
done:
		call	SlipReleaseAccess

		.leave
		ret

SlipLinkConnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipStopLinkConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt a link connect request.

CALLED BY:	SlipStrategy

PASS:		bx	= connection handle

RETURN:		carry clear

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/12/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipStopLinkConnect	proc	far
		uses	ax, bx, ds
		.enter

EC <		cmp	bx, SLIP_CONNECTION_HANDLE		>
EC <		ERROR_NE SLIP_INVALID_CONNECTION_HANDLE		>

	;
	; If link is closing, do nothing.
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		call	SlipGainAccess

		CheckHack <SS_QUIT_TIA gt SS_OPEN>
		CheckHack <SS_SENT_LOGOUT gt SS_QUIT_TIA>
		cmp	ds:[slipState], SS_OPEN
		ja	done
	;
	; Set error.  If beyond connecting state, send message
	; to close link.  Otherwise, driver will check before 
	; advancing out of connecting state and stop on its own.
	;
		mov	ds:[slipError], SDE_INTERRUPTED
		cmp	ds:[slipState], SS_CONNECTING
		jbe	done		

		mov	bx, ds:[slipThread]
EC <		Assert	thread	bx				>
		mov	ax, MSG_SLIP_CLOSE_LINK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage		
done:
		call	SlipReleaseAccess

		.leave
		ret
SlipStopLinkConnect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the link connection.

CALLED BY:	SlipStrategy

PASS:		bx	= connection handle

RETURN:		carry set if error

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version
	jwu	8/12/96			Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipDisconnectRequest	proc	far
		uses	ax,bx,cx,dx,si,ds
mediumType	local	MediumType
		.enter

EC <		cmp	bx, SLIP_CONNECTION_HANDLE		>
EC <		ERROR_NE SLIP_INVALID_CONNECTION_HANDLE		>
	;
	; If link isn't open, then return as if disconnect succeeded.
	;		
		clrdw	mediumType

		mov	bx, handle dgroup
		call	MemDerefDS
		call	SlipGainAccess

		cmp	ds:[slipState], SS_OPEN
		jne	exit
	;
	; Queue a message for the driver to close the link.  Release
	; access to status. Wait until driver is done.
	;

EC <		test	ds:[slipStatus], mask SDS_WAITER_EXISTS	>
EC <		ERROR_NE SLIP_CANNOT_CLOSE_LINK_WITH_WAITER	>

		BitSet	ds:[slipStatus], SDS_WAITER_EXISTS
		call	SlipAllocSem
		
		mov	bx, ds:[slipThread]
EC <		Assert	thread	bx				>
		mov	ax, MSG_SLIP_CLOSE_LINK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage		

		call	SlipReleaseAccess

		mov	bx, ds:[slipSem]
		call	ThreadPSem		

		clc
exit:
		.leave
		ret
SlipDisconnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipSendDatagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send data across the connection.

CALLED BY:	SlipStrategy

PASS:		dx:bp	= optr of buffer to send
		cx	= size of data in buffer
		bx	= client handle

RETURN:		nothing

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipSendDatagram	proc	far
		uses	ax, bx, ds 
		.enter

EC <		cmp	bx, SLIP_CLIENT_HANDLE				>
EC <		ERROR_NE SLIP_INVALID_CLIENT_HANDLE			>
	;
	; Have the driver send the data so we don't have
	; to worry about the driver's thread killing the connection
	; if it was just started recently by the lurker.
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		
		mov	bx, ds:[slipThread]
		mov	ax, MSG_SLIP_SEND_FRAME
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		ret
SlipSendDatagram	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipResetRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the slip connection.

CALLED BY:	SlipStrategy

PASS:		ax	= connection handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Disconnect slip connection.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipResetRequest	proc	far
		uses	bx
		.enter
		
		mov	bx, ax			; bx = connection handle
		call	SlipDisconnectRequest
		
		.leave
		ret
SlipResetRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get info from the driver.

CALLED BY:	SlipStrategy

PASS:		ax	= SocketGetInfoType
		if SGIT_LOCAL_ADDR
			ds:bx	= buffer for address
			dx	= buffer size

RETURN:		if SGIT_MTU, 
			ax	= maximum packet size
		if SGIT_LOCAL_ADDR,
			ds:bx	= address filled in
		if SGIT_MEDIUM_AND_UNIT
			cxdx	= MediumType
			bp	= unit 
			bl	= MediumUnitType

		otherwise, carry set

DESTROYED:	ax if not used for return value
		di (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipGetInfo	proc	far
		
		uses	es
		.enter

		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx

		cmp	ax, size infoTypeTable
		jae	notSupported

		mov	di, ax
		jmp	cs:infoTypeTable[di]

mtu:
		mov	ax, es:[maxFrame]
		jmp	done
address:
		mov	ax, IP_ADDR_SIZE
		cmp	ax, dx
		ja	exit				; carry already clear

		movdw	ds:[bx], es:[localAddr], di
		jmp	done
medAndUnit:
		clr	cx				; get primary  medium
		mov	di, DR_SERIAL_GET_MEDIUM
		mov	bx, es:[slipPort]
		call	es:[serialStrategy]		; dxax = MediumType
EC <		ERROR_C	-1		; bad port number	>
		
		movdw	cxdx, dxax			; cxdx = MediumType
		mov	bp, bx				; bp = SerialPortNum
		mov	bl, MUT_INT			; bl = MediumUnitType
done:
		clc	
		jmp	exit
notSupported:
		stc
exit:		
		.leave
		ret

infoTypeTable	nptr	\
	offset notSupported,		; SGIT_MEDIA_LIST
	offset medAndUnit,		; SGIT_MEDIUM_AND_UNIT
	offset notSupported,		; SGIT_ADDR_CTRL
	offset notSupported,		; SGIT_ADDR_SIZE
	offset address,			; SGIT_LOCAL_ADDR
	offset notSupported,		; SGIT_REMOTE_ADDR
	offset mtu,			; SGIT_MTU
	offset notSupported, 		; SGIT_PREF_CTRL
	offset notSupported		; SGIT_MEDIUM_CONNECTION

SlipGetInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipResolveAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve a link level address for SLIP.

CALLED BY:	SlipStrategy

PASS:		ds:si	= addr to resolve
		cx	= size of addr (including word for linkSize)
		dx:bp	= buffer for resolved address
		ax	= buffer size

RETURN:		carry clear
		dx:bp	= buffer filled with address if buffer is big enough
		cx	= size of resolved address

DESTROYED:	di (preserved by SlipStrategy)

PSEUDO CODE/STRATEGY:
		If buffer is big enough, copy the link address to the
		buffer.  SLIP doesn't need the address resolved.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/10/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipResolveAddr	proc	far

	;
	; If buffer if big enough, copy the link address to it.
	;
		cmp	ax, cx
		jb	exit
		
		push	cx, si, es
		movdw	esdi, dxbp
		rep	movsb
		pop	cx, si, es
exit:
		clc

		ret
SlipResolveAddr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipMediumActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by lurker after it loads SLIP driver.

CALLED BY:	SlipStrategy

PASS:		dx:bx	= MediumUnitType  (port passively opened by lurker)

RETURN:		carry set if error

DESTROYED:	di (preserved by SlipStrategy)

PSEUDO CODE/STRATEGY:
	If port differs from expected port or if link isn't closed,
		return error.

	If SLIP is not registered, 
		allocate thread
		allocate semaphore

	Pretend SLIP is registered (if it's not already)
	Remember client is waiting for data and that a waiter exists
	Have driver thread open link and wait until open
	If failed and no client,
		reset slip status, free thread, free semaphore and return
		error
	If successful, 
		If no client, 
			load tcp driver
			register tcp driver 
		tell tcp driver link opened
		set timer to verify connection			

	
	MUST be sure to release access before calling tcp driver or
	may deadlock!
		
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipMediumActivated	proc	far
		uses	ax, bx, cx, dx, si, bp, ds
		.enter

		mov	ds, dx
		mov	bx, ds:[bx].MU_unit		; bx = port number

EC <		test	bx, 0x0001			>
EC <		ERROR_NZ -1		; bad com port #>
EC <		cmp	bx, LAST_ACTIVE_SERIAL_PORT	>
EC <		ERROR_A  -1		; bad com port #>
	;
	; Verify port is what we expect.
	;
		mov_tr	cx, bx				; cx = port
		mov	bx, handle dgroup
		call	MemDerefDS

		cmp	cx, ds:[slipPort]
		stc					; assume error
		LONG	jne	exit
	;
	; Check registered status.  Allocate SLIP thread if not already
	; registered.
	;
		call	SlipGainAccess
		cmp	ds:[slipState], SS_CLOSED
		jne	errorRelease
				
		tstdw	ds:[clientEntry]
		jnz	openLink

		call	SlipAllocThread
openLink:
	;
	; Have driver thread open link and wait until done.
	;
		call	SlipAllocSem
		ornf	ds:[slipStatus], (mask SDS_WAITING_FOR_DATA or \
				mask SDS_WAITER_EXISTS or mask SDS_REGISTERED)

		mov	bx, ds:[slipThread]
		mov	ax, MSG_SLIP_OPEN_LINK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		call	SlipReleaseAccess

		mov	bx, ds:[slipSem]
		call	ThreadPSem
	;
	; Regain access.  Clear waiter bit and destroy sem.  If link is
	; not opened, destroy the slip thread unless we had a client.
	;
		call	SlipGainAccess

		BitClr	ds:[slipStatus], SDS_WAITER_EXISTS
		call	SlipDestroySem

		cmp	ds:[slipState], SS_OPEN
		je	release				; carry clear

		BitClr	ds:[slipStatus], SDS_WAITING_FOR_DATA
		tstdw	ds:[clientEntry]
		jnz	errorRelease

		BitClr	ds:[slipStatus], SDS_REGISTERED
		call	SlipDestroyThread
errorRelease:
		stc
release:
		call	SlipReleaseAccess		; preserves flags
		jc	exit
	;
	; Set timer to verify connection.
	;
		mov	bx, ds:[slipThread]
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, SLIP_VERIFY_CONNECTION_TIMEOUT
		mov	dx, MSG_SLIP_VERIFY_CONNECTION
		mov	bp, handle 0			; we own it!
		call	TimerStartSetOwner 
		mov	ds:[timerHan], bx
		mov	ds:[timerID], ax		
		clc
exit:
		.leave
		ret
SlipMediumActivated	endp



;---------------------------------------------------------------------------
;		Subroutines
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipGainAccess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain access to slip status values.

CALLED BY:	GLOBAL

PASS:		ds	= dgroup

RETURN:		when access obtained

DESTROYED:	bx	(safe since most times, this is called after
			ds is set to dgroup which already trashes bx)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/ 1/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipGainAccess	proc	near
		uses	ax
		.enter

		mov	bx, ds:[statusSem]
		call	ThreadPSem		; ax = SemaphoreError

		.leave
		ret
SlipGainAccess	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipReleaseAccess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release access to slip status values.

CALLED BY:	GLOBAL

PASS:		ds	= dgroup

RETURN:		nothing 

DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/ 1/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipReleaseAccess	proc	near
		uses	ax, bx
		.enter
		pushf
		
		mov	bx, ds:[statusSem]
		call	ThreadVSem		; ax = SemaphoreError
		
		popf
		.leave
		ret
SlipReleaseAccess	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipLoadSerialDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the standard serial driver unless the INI specifies
		a different serial driver to be used.

CALLED BY:	SlipInit

PASS:		es	= dgroup

RETURN:		carry set if error
		else
		bx	= driver handle

DESTROYED:	ax, cx, dx, di, si, ds (allowed)

PSEUDO CODE/STRATEGY:
		Check the ini file for a portDriver entry under the
		SLIP category.  If no driver name found, then load
		standard serial driver.  

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 3/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString	serialName, <"serialec.geo", 0>		>
NEC<LocalDefNLString	serialName, <"serial.geo", 0>		>

SlipLoadSerialDriver	proc	near
driverName		local	FileLongName
		.enter
	;
	; See if there is a special driver listed in the INI file.
	;
		push	bp, es
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov_tr	cx, ax
		mov	si, offset portDriverKey
		mov	dx, ds:[si]			; cx:dx = key
		mov	si, offset slipCategory
		mov	si, ds:[si]			; ds:si = category
		segmov	es, ss, di
		lea	di, driverName			; es:di = buffer for name
		mov	bp, InitFileReadFlags \
				<IFCC_INTACT, 0, 0, FILE_LONGNAME_BUFFER_SIZE>
		call	InitFileReadString		
		segmov	ds, es, si
		mov	si, di				; ds:si = driver name
		pop	bp, es

		mov	bx, handle Strings
		call	MemUnlock
		jnc	loadDriver
	;
	; Nothing in the ini file.  Use standard serial driver.
	;
		segmov	ds, cs, si
		mov	si, offset serialName
loadDriver:
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		jc	done

		mov	ax, SERIAL_PROTO_MAJOR
		mov	bx, SERIAL_PROTO_MINOR
		call	GeodeUseDriver
		jc	done

		mov	es:[serialDrvr], bx
done:
		call	FilePopDir

		.leave
		ret
SlipLoadSerialDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipGetInitFileInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get INI settings, if any.  If no entries in the INI, the 
		default settings will be used.

CALLED BY:	SlipInit

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si, bp, ds

PSEUDO CODE/STRATEGY:
		
		Get the category string.
		Find the com port
		Find the baud rate
		Find the max slip frame
		Find the local address
		
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipGetInitFileInfo	proc	near

		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, offset slipCategory
		mov	si, ds:[si]			; ds:si = category string
	;
	; Get com port.
	;
		mov	bp, offset slipPort
		mov	di, offset portKey
		call	SlipReadInitFileInteger
	;
	; Get baud rate.
	;		
		mov	bp, offset slipBaud
		mov	di, offset baudKey
		call	SlipReadInitFileInteger
	;
	; Get maximum SLIP frame.  Ensure that it exceeds the required
	; minimum size.
	;
		mov	bp, offset maxFrame
		mov	di, offset maxFrameKey
		call	SlipReadInitFileInteger

		cmp	es:[maxFrame], SLIP_MIN_MTU
		jae	findAddr
		mov	es:[maxFrame], SLIP_MIN_MTU
findAddr:
	;
	; Get local IP address for link.
	;
		call	SlipFindLocalAddress		

		call	MemUnlock

		ret
SlipGetInitFileInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipReadInitFileInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read an integer from the INI file and store its value in
		dgroup if found.

CALLED BY:	SlipGetInitFileInfo

PASS:		di	= offset of chunk for key string
		bp	= offset of variable for value in dgroup
		ds:si	= category string
		es	= dgroup

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/ 9/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipReadInitFileInteger	proc	near

		mov	cx, ds
		mov	dx, ds:[di]		; cx:dx = key string
		call	InitFileReadInteger	; ax = value
		jc	exit

		mov	es:[bp], ax
exit:
		ret
SlipReadInitFileInteger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipFindLocalAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the local IP address from the INI settings or
		use the default if no INI entry or INI entry is bad.

CALLED BY:	SlipGetInitFileInfo	

PASS:		es	= dgroup
		ds:si	= category string

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipFindLocalAddress	proc	near
		uses	ax, bx, cx, dx, di, bp, ds
		.enter

		mov	cx, ds
		mov	di, offset addrKey
		mov	dx, ds:[di]			; cx:dx = key string
		clr	bp				; InitFileReadFlags
		call	InitFileReadString		; cx = # chars in string
		jc	exit
	;
	; Get the address string (in x.x.x.x format) and convert
	; each field to a number.
	;		
		call	MemLock
		mov	ds, ax			
		clr	di			; ds:si = address string
		call	SlipAsciiToIpAddr	; dxax = addr (network format)
		
		pushf	
		call	MemFree
		popf
		
		jc	exit
		
		movdw	es:[localAddr], dxax
		
exit:
		.leave
		ret
SlipFindLocalAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipAsciiToIpAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a string in x.x.x.x format into an IP address.

CALLED BY:	SlipFindLocalAddress

PASS:		ds:di	= address string
		cx	= # chars in string

RETURN:		carry set if address is invalid
		dxax	= IP address in network order

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipAsciiToIpAddr	proc	near
		uses	bx, cx, di, si, es
laddr		local	dword
		.enter
	;
	; Replace all the dots in address with null to form 4 strings 
	; of ascii decimals.
	;
		push	di
		segmov	es, ds

		clr	dx
replaceLoop:
		mov	ax, '.'
		LocalFindChar
		jne	beginConvert

		LocalPrevChar	esdi
		clr	ax
		LocalPutChar	esdi, ax
		inc	dx
		jmp	replaceLoop
beginConvert:	
	;
	; Check that we have 4 parts and turn each part into an integer.
	;
		pop	di			; ds:di = string
		
		cmp	dx, IP_ADDR_SIZE - 1	; wrong # of parts in addr
		jne	badAddr

		lea	si, laddr
		clr	bx
convertLoop:
		tst	{byte}ds:[di]		; any numbers?
		je	badAddr				
		
		call	LocalAsciiToFixed	; dx:ax = value
						; di points after last digit
		tst	dh			; # was too big?
		jne	badAddr
		mov	ss:[si], dl
		
		LocalNextChar	dsdi		; ds:di = next string
		inc	si
		inc	bx
		cmp	bx, IP_ADDR_SIZE
		jb	convertLoop	

		movdw	dxax, laddr
		clc
exit:
		.leave
		ret
badAddr:
		stc	
		jmp	exit

SlipAsciiToIpAddr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipAllocThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a thread for the slip driver.

CALLED BY:	SlipRegister
		SlipMediumActivated

PASS:		ds	= dgroup
		
RETURN:		nothing

DESTROYED:	ax, dx, di, si, bp

PSEUDO CODE/STRATEGY:
		Create thread and save handle in dgroup

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipAllocThread	proc	near

		uses	cx
		.enter
	;
	; Create the driver's thread.
	;		
		call	ImInfoInputProcess	; use input process as parent
		mov	si, handle 0		; we own the thread
		clr	bp			; default stack size
		mov	cx, segment SlipProcessClass
		mov	dx, offset SlipProcessClass
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER
		mov	di, mask MF_CALL
		call	ObjMessage		; ax = handle of new thread

EC <		ERROR_C	SLIP_UNABLE_TO_CREATE_THREAD		>
		mov	ds:[slipThread], ax

		.leave
		ret

SlipAllocThread	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipDestroyThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the slip thread.

CALLED BY:	SlipUnregister
		SlipMediumActivated	

PASS:		ds	= dgroup		

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
		Must use MF_CALL so detach handler will check registered
		status before returning.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 4/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipDestroyThread	proc	near
		uses	ax, bx, cx, dx, bp, di
		.enter

		clr	bx
		xchg	bx, ds:[slipThread]
EC <		Assert	thread bx				>
		clr	cx, dx, bp		; no ack neeced
		mov	ax, MSG_META_DETACH
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
SlipDestroyThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipAllocSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a semaphore for blocking a operation.

CALLED BY:	SlipDisconnectRequest
		SlipMediumActivated

PASS:		ds	= dgroup

RETURN:		bx	= semaphore handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 7/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipAllocSem	proc	near
		uses	ax
		.enter
	;
	; Create semaphore for blocking operations.
	;
		clr	bx			; initially locked
		call	ThreadAllocSem		; bx = sem handle
		mov	ds:[slipSem], bx

		mov	ax, handle 0		; we own the sem!
		call	HandleModifyOwner	

		.leave
		ret
SlipAllocSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipDestroySem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the semaphore for blocking operations.

CALLED BY:	SlipLinkConnectRequest
		SlipDisconnectRequest
		SlipMediumActivated

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 7/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipDestroySem	proc	near
		uses	bx
		.enter

		clr	bx
		xchg	bx, ds:[slipSem]
		call	ThreadFreeSem

		.leave
		ret
SlipDestroySem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipGetClientIfNone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If SLIP doesn't already have a client, get one now and
		notify the client that the link has opened.

CALLED BY:	SlipLinkOpened

PASS:		ds	= dgroup
		(SlipGainAccess called by caller)

RETURN:		carry set if error

DESTROYED:	ax, bx, cx, si, di (allowed)

PSEUDO CODE/STRATEGY:
		if no client 
			Load tcp driver
			register tcp driver 
			unload tcp driver
		if failed, close link

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/ 2/95			Initial version
	jwu	8/12/96			Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipGetClientIfNone	proc	near
		uses	dx, bp
		.enter

	;
	; If no client, load and register TCP.  Unload	
	; TCP afterwards to remove our reference to it.
	;
		tstdw	ds:[clientEntry]		
		jnz	gotClient

		call	SlipLoadTcpDriver		; bx = driver handle
							; cxdx = client entry
		jc	error

		mov	bp, bx				; bp = driver handle
		call	SlipRegisterTcpDriver		; bx = domain handle

		lahf
		xchg	bx, bp				; bx = tcp driver handle
		call	GeodeFreeDriver
		sahf
		jc	error
		
		movdw	ds:[clientEntry], cxdx
		mov	ds:[domain], bp
gotClient:
		clc
		jmp	exit
error:
	;
	; Something went wrong.  Close the link.
	;
		mov	bx, ds:[slipThread]
		mov	ax, MSG_SLIP_CLOSE_LINK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		stc
exit:
		.leave
		ret
SlipGetClientIfNone	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipLoadTcpDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the Tcp/Ip driver and get its client entry point.

CALLED BY:	SlipGetClientIfNone

PASS:		nothing

RETURN:		carry set if error
		else
		bx	= driver handle
		cxdx	= client entry point

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString	tcpipName, <"tcpipec.geo", 0>		>
NEC<LocalDefNLString	tcpipName, <"tcpip.geo", 0>		>

LocalDefNLString socketString, <"socket", 0>

SlipLoadTcpDriver	proc	near
		uses	ax, si, ds
		.enter

		call	FilePushDir
	
		mov	bx, SP_SYSTEM
		segmov	ds, cs, si
		mov	dx, offset socketString
		call	FileSetCurrentPath
		jc	done

		mov	si, offset tcpipName
		mov	ax, SOCKET_PROTO_MAJOR
		mov	bx, SOCKET_PROTO_MINOR
		call	GeodeUseDriver		; bx = driver handle
done:		
		call	FilePopDir
		
		jc	exit

		call	GeodeInfoDriver		; ds:si = SocketDriverInfoStruct
		movdw	cxdx, ds:[si].SDIS_clientStrat
exit:
		.leave
		ret
SlipLoadTcpDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipRegisterTcpDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register with Tcp Driver

CALLED BY:	SlipMediumActivated

PASS:		cxdx	= client entry point	

RETURN:		carry set if error
		else
		bx	= domain handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
NOTE:		Caller has access.
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipRegisterTcpDriver	proc	near
		uses	ax, cx, dx, di, bp, es, ds
		.enter

		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, offset slipCategory
		mov	si, ds:[si]		; ds:si = slip domain name

		pushdw	cxdx			; pass entry point on stack
		mov	bp, handle 0		; bp = driver handle
		mov	ax, SLIP_CLIENT_HANDLE
		mov	bx, segment SlipStrategy
		mov	es, bx
		mov	bx, offset SlipStrategy		; es:bx = SlipStrategy
		mov	cx, (size DatagramPacketHeader shl 8) or \
				size DatagramPacketHeader
		mov	dl, SDT_LINK
		mov	di, SCO_ADD_DOMAIN
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; bx = domain handle
		mov_tr	ax, bx				

		mov	bx, handle Strings
		call	MemUnlock			; flags preserved
		jc	exit		

		mov_tr	bx, ax				; return domain handle
exit:		
		.leave
		ret
SlipRegisterTcpDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipLinkOpened
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Link has opened.  Take care of notifications.

CALLED BY:	SlipOpenLink (non-TIA)
		SlipConnectComplete (TIA only)

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if no client, get a client
		if no waiter, notify with SCO_CONNECT_CONFIRMED
		else 
			wake waiter
			notify with SCO_LINK_OPENED

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/13/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipLinkOpened	proc	near
		uses	ax, bx, cx, di, si
		.enter
	;
	; Make sure we have a client.  If fail, link will be 
	; closed.
	;
		call	SlipGainAccess
		call	SlipGetClientIfNone
		jc	exit

	;
	; If no waiter, notify with SCO_CONNECT_CONFIRMED.
	; Okay to hold access during notification.  Caller
	; should not be calling us back.
	; Else wake waiter and notify with SCO_LINK_OPENED.
	;
		mov	di, SCO_CONNECT_CONFIRMED
		test	ds:[slipStatus], mask SDS_WAITER_EXISTS
		jz	notify

		BitClr	ds:[slipStatus], SDS_WAITER_EXISTS
		mov	bx, ds:[slipSem]
		call	ThreadVSem

		mov	di, SCO_LINK_OPENED
		mov	cx, IP_ADDR_SIZE
		mov	si, offset localAddr		; ds:si = local address
notify:
		mov	ax, SLIP_CONNECTION_HANDLE
		mov	bx, ds:[domain]
		pushdw	ds:[clientEntry]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		
		call	SlipNotifyMediumConnected

exit:
		call	SlipReleaseAccess

		.leave
		ret
SlipLinkOpened	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipLinkClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Link has closed.  Take care of notifications.

CALLED BY:	SlipCloseLink (non TIA)
		SlipDisconnectComplete (TIA only)

PASS:		ds 	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Gain access
		close port
		free input buffer
		swap CLOSED for old state
		swap zero for error 		
		get status and clear waiter bit
		release access
		
		if waiter, wake waiter
		else if previous state is lt OPEN, notify with 
			SCO_CONNECT_FAILED
		else notify with SCO_CONNECTION_CLOSED
		
NOTE:
		Caller should NOT set state to CLOSED before calling 
		this.  Code needs former state to determine which
		notification to send.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/13/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipLinkClosed	proc	near
		uses	ax, bx, cx, dx, di
		.enter
	;
	; Gain access, close port, free input buffer, reset state,
	; error and status, release access.
	;
		call	SlipGainAccess

		call	SlipCloseSerialPort
		call	SlipFreeBuffer

		clr	dx
		xchg	dx, ds:[slipError]

		mov	ax, SS_CLOSED
		xchg	ax, ds:[slipState]

		mov	cl, ds:[slipStatus]
		BitClr	ds:[slipStatus], SDS_WAITER_EXISTS

		call	SlipReleaseAccess
	;
	; If there is a waiter, wake waiter.
	;
		test	cl, mask SDS_WAITER_EXISTS
		jz	doNotify

		mov	bx, ds:[slipSem]
		call	ThreadVSem
		jmp	exit
doNotify:
	;
	; If former state is less than OPEN, notify with SCO_CONNECT_FAILED.
	; Else notify with SCO_CONNECTION_CLOSED.
	;
		mov	di, SCO_CONNECT_FAILED
		cmp	dx, SS_OPEN
		jl	notifyNow

		mov	di, SCO_CONNECTION_CLOSED
		mov	cx, SCT_FULL
notifyNow:
		mov	ax, SLIP_CONNECTION_HANDLE
		mov	bx, ds:[domain]
		pushdw	ds:[clientEntry]
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		call	SlipNotifyMediumNotConnected

exit:
		.leave
		ret
SlipLinkClosed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipNotifyMediumConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send medium notifications about the link being connected.

CALLED BY:	SlipLinkOpened

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/13/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipNotifyMediumConnected	proc	near
		uses	ax, bx, cx, dx, di, si
		.enter


		clr	cx				; fetch primary medium
		mov	di, DR_SERIAL_GET_MEDIUM
		mov	bx, ds:[slipPort]
		call	ds:[serialStrategy]		; dxax = MediumType
		jc	exit

		movdw	cxdx, dxax
		mov	al, MUT_INT
		mov	si, SST_MEDIUM
		mov	di, MESN_MEDIUM_CONNECTED
		call	SysSendNotification

		BitSet	ds:[slipStatus], SDS_MEDIUM_CONNECTED

exit:
		.leave
		ret
SlipNotifyMediumConnected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipNotifyMediumNotConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send medium notifications about the link being disconnected
		if notifications had been previously sent.

CALLED BY:	SlipLinkClosed

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/13/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipNotifyMediumNotConnected	proc	near
		uses	ax, bx, cx, dx, di, si
		.enter

		test	ds:[slipStatus], mask SDS_MEDIUM_CONNECTED
		jz	exit

		BitClr	ds:[slipStatus], SDS_MEDIUM_CONNECTED

		clr	cx				; fetch primary medium
		mov	di, DR_SERIAL_GET_MEDIUM
		mov	bx, ds:[slipPort]
		call	ds:[serialStrategy]		; dxax = MediumType
		jc	exit		

		movdw	cxdx, dxax
		mov	al, MUT_INT
		mov	si, SST_MEDIUM
		mov	di, MESN_MEDIUM_NOT_CONNECTED
		call	SysSendNotification
exit:
		.leave
		ret
SlipNotifyMediumNotConnected	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipOpenSerialPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the serial port, configure it and register for read
		notification.

CALLED BY:	SlipOpenLink
		SlipMediumActivated

PASS:		ds 	=  dgroup

RETURN:		carry set if could not open serial port

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOTE:	Caller must have called SlipGainAccess before this.
		
		These are required by tia:
			no XON/XOFF
			use hardware handshaking 	
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipOpenSerialPort	proc	near
		uses	ax, bx, cx, dx, bp, di, si
		.enter
	;
	; Don't do anything if already opened.
	;
		test	ds:[slipStatus], mask SDS_PORT_OPEN  ; clears carry 
		jnz	exit
	;
	; Open the serial port.
	;		
		mov	bx, ds:[slipPort]
		mov	ax, mask SOF_NOBLOCK	; don't block if port in use
		mov	cx, SLIP_SERIAL_BUFFER_SIZE
		mov	dx, cx			;d same as input buffer
		mov	si, handle 0		; we own it!
		mov	di, DR_SERIAL_OPEN_FOR_DRIVER
		call	ds:[serialStrategy]
		jc	exit
	;
	; Configure the port.
	;
		mov	ax, (SM_RAW shl 8) or SerialFormat \
				<0, 0, SP_NONE, 0, SL_8BITS>
		mov	cx, ds:[slipBaud]
		mov	di, DR_SERIAL_SET_FORMAT
		call	ds:[serialStrategy]
EC <		ERROR_C	-1			; invalid serial format	>

if _TIA	
	;
	; Set hardware flow control.
	;
		mov	ax, SerialFlowControl <0, 1>	; hardware
		mov	cx, (mask SMS_CTS shl 8) or mask SMC_RTS
		mov	di, DR_SERIAL_SET_FLOW_CONTROL
		call	ds:[serialStrategy]
endif	
	
	;
	; Register for read notification. 
	;
		mov	ax, StreamNotifyType \
				<1, SNE_DATA, SNM_MESSAGE>
		mov	cx, ds:[slipThread]
		mov	bp, MSG_SLIP_PROCESS_INPUT
		mov	di, DR_STREAM_SET_NOTIFY
		call	ds:[serialStrategy]
		
		BitSet	ds:[slipStatus], SDS_PORT_OPEN

		clc
exit:
		.leave
		ret
SlipOpenSerialPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipCloseSerialPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the serial port.

CALLED BY:	SlipLinkClosed

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOTE:  Caller must have called SlipGainAccess first.
		
		If we have port open, close it.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipCloseSerialPort	proc	near
		uses	ax, bx, di
		.enter
	;
	; Close port if necessary.
	;
		test	ds:[slipStatus], mask SDS_PORT_OPEN
		jz	exit

		mov	ax, STREAM_DISCARD
		mov	bx, ds:[slipPort]
		mov	di, DR_STREAM_CLOSE
		call	ds:[serialStrategy]

		andnf 	ds:[slipStatus], not (mask SDS_PORT_OPEN or \
					      mask SDS_WAITING_FOR_DATA)
exit:
		.leave
		ret
SlipCloseSerialPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the data, escaping the special chars.

CALLED BY:	SlipSendFrame

PASS:		ds:si	= data
		cx	= # of bytes

RETURN:		nothing		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		EC code writes each byte we send across serial line
		to the output buffer so we can verify the slip frame
		is as we expect.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
	;
	; Expects byte in CL and ES pointing to dgroup.
	;
LogOutputByte	macro
		local	storePtr
		push	di					
		mov	di, es:[outBufPtr]			
		mov	al, cl					
		stosb						
		cmp	di, es:[outBufEnd]			
		jne	storePtr
		mov	di, offset outputBuffer
storePtr:							
		mov	es:[outBufPtr], di			
		pop	di					
endm
endif

SlipSend	proc	near
		uses	ax, bx, cx, dx, si, di, es
		.enter

		mov	dx, cx				; dx = byte count
		
		mov	bx, handle dgroup
		call	MemDerefES

		mov	bx, es:[slipPort]
		mov	di, DR_STREAM_WRITE_BYTE
	;
	; Send an end-of-frame flag to flush any line garbage.
	;
		mov	ax, STREAM_BLOCK
		mov	cl, SLIP_FR_END
		call	es:[serialStrategy]
EC <		LogOutputByte					>
	
	;
	; For each byte in the data, if it is an escape or an end-of-frame
	; byte, send an escape followed by the transposed value of the byte.  
	; Otherwise, just send the byte.
	;
sendLoop:		
		mov	cl, ds:[si]
		inc	si			; advance pointer in data
		
		cmp	cl, SLIP_FR_END
		jne	checkEsc

		mov	ax, STREAM_BLOCK
		mov	cl, SLIP_FR_ESC
		call	es:[serialStrategy]
EC <		LogOutputByte					>

		mov	ax, STREAM_BLOCK
		mov	cl, SLIP_T_FR_END
		call	es:[serialStrategy]
EC <		LogOutputByte					>		
		
		jmp	next
checkEsc:
	;
	; The byte is either an escape or a regular byte.  Send the byte
	; and if it was an escape, send the transposed escape after it.
	;		
		mov	ax, STREAM_BLOCK
		call	es:[serialStrategy]	
EC <		LogOutputByte					>
		
		cmp	cl, SLIP_FR_ESC
		jne	next

		mov	ax, STREAM_BLOCK
		mov	cl, SLIP_T_FR_ESC
		call	es:[serialStrategy]
EC <		LogOutputByte					>

next:
		dec	dx
		LONG	jnz	sendLoop
	;
	; Send an end-of-frame to mark the end of this frame.
	;
		mov	ax, STREAM_BLOCK
		mov	cl, SLIP_FR_END
		call	es:[serialStrategy]
EC <		LogOutputByte					>

		.leave
		ret
SlipSend	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipReceiveData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive data for a SLIP frame.

CALLED BY:	SlipProcessInput

PASS: 		es 	= dgroup
		ds	= segment of input buffer
		cx	= number of bytes read
		inputStart marks beginning of data
		inputEnd points to byte after end of data

RETURN:		nothing		

DESTROYED:	ax, cx, di (preserved by caller)

PSEUDO CODE/STRATEGY:
		If slip not registered, no point in processing data.
		Set inputStart to inputEnd so that old data will 
			not be reprocessed.
		Get a byte from the input buffer until there 
			are no more bytes
			Process the byte

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipReceiveData	proc	near
	;
	; Processing data only if we have a client.
	;
		tstdw	es:[clientEntry]
		je	exit
	;
	; Advance start of input so driver will not reprocess old data.
	;
		mov	di, es:[inputStart]	; di = start of new data
		mov	ax, es:[inputEnd]
		mov	es:[inputStart], ax
dataLoop:
	;
	; Process each byte of input.
	;		
		mov	al, ds:[di]
		inc	di
		call	SlipProcessInputByte
		loop	dataLoop
exit:
		ret
SlipReceiveData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipProcessInputByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a received byte.

CALLED BY:	SlipReceiveData

PASS:		es 	= dgroup
		ds	= segment of input buffer 
		al	= byte read

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
		
		if byte is frame end
			set escape flag to false
			if buffer exists
			downsize buffer
			deliver buffer to the client
			set buffer to none
			ret

		if byte is escape
			set escape flag to true
			ret

		if escape flag is true
			set escape flag to false
			translate byte back to original byte 
		
		Get the buffer
			[If no buffer, one will be allocated.]
			allocate one of size = mtu (will be downsized)
			initialize count to zero

		place byte in buffer
		increment count
		
		
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipProcessInputByte	proc	near
		uses	ax, bx, cx, dx, di, ds
		.enter

		cmp	al, SLIP_FR_END
		jne	checkEsc
	;
	; Reset escape flag and counter.  If buffer exists, downsize 
	; the buffer and deliver to the client.  Clear waiting for data
	; flag since we've seen a slip frame marker.
	;
		andnf	es:[slipStatus], not(mask SDS_ESCAPE or \
					mask SDS_WAITING_FOR_DATA)
		clr	cx, dx, di
		xchg	di, es:[count]
		xchgdw	cxdx, es:[dataBuffer]		; ^lcx:dx = buffer
		tstdw	cxdx
		je	exit

		call	SlipDownsizeBuffer		
		call	SlipDeliverPacket
		jmp	exit
		
checkEsc:
		cmp	al, SLIP_FR_ESC
		jne	checkFlag

		BitSet	es:[slipStatus], SDS_ESCAPE
		jmp	exit
checkFlag:
	;
	; Check escape flag and  clear it if set.
	;		
		test	es:[slipStatus], mask SDS_ESCAPE
		je	haveByte

		BitClr	es:[slipStatus], SDS_ESCAPE		
		call	SlipDecodeByte			; al = unescaped byte
		jc	exit				
haveByte:	
	;
	; AL contains a byte of data to be placed in the buffer.
	;		
		call	SlipGetBuffer			; ds:di = place for data

EC <		WARNING_C SLIP_COULDNT_GET_BUFFER_SO_DROPPING_BYTE >
		jc	exit				; no memory... drop byte

		inc	es:[count]
		mov	cx, es:[maxFrame]
		cmp	es:[count], cx
		ja	drop
		
		mov	ds:[di], al			; store byte in buffer
		jmp	exit

drop:
EC <		WARNING SLIP_FRAME_EXCEEDS_MTU			>
	;
	; Drop buffer so we don't overflow.
	;						
		clr	bx, cx
		mov	es:[count], bx
		xchgdw	bxcx, es:[dataBuffer]
		call	HugeLMemUnlock
		mov_tr	ax, bx				; ^lax:cx = data buffer
		call	HugeLMemFree
exit:		
		
		.leave
		ret
SlipProcessInputByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipDecodeByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate an escaped byte back to its original value.

CALLED BY:	SlipProcessInputByte

PASS:		al	= escaped byte

RETURN:		al	= unescaped byte
		carry set if byte should be dropped

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipDecodeByte	proc	near

		cmp	al, SLIP_T_FR_END
		jne	checkEsc
		
		mov	al, SLIP_FR_END
		jmp	exit				; carry clear from cmp
checkEsc:
		cmp	al, SLIP_T_FR_ESC		
		jne	badByte

		mov	al, SLIP_FR_ESC			; carry clear from cmp
exit:
		ret

badByte:
		stc					
		jmp	exit				

SlipDecodeByte	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipAllocDataBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a data buffer for the slip driver.

CALLED BY:	SlipGetBuffer

PASS:		ax	= size of data
		es	= dgroup

RETURN:		carry set if allocation failed
		otherwise:
		^lax:cx = new buffer (optr)
		ds:di	= new buffer (fptr)

DESTROYED:	ax, cx, ds, di if failed

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipAllocDataBuffer	proc	near
		uses	bx, dx, si
		.enter
	;
	; Allocate the buffer.
	;
		push	ax				; save actual size
		mov	dx, size DatagramPacketHeader
		add	ax, dx				; ax = total size
		mov	cx, SLIP_WAIT_TIME
		
		mov	bx, es:[hugeLmem]
		call	HugeLMemAllocLock		; ^lax:cx = new buffer
							; ds:di = new buffer
		pop	dx				; dx = actual size
		jc	exit
	;
	; Store the data size, offset, and domain handle.
	;
		mov	ds:[di].PH_flags, PacketFlags <0, 0, PT_DATAGRAM>
		mov	ds:[di].PH_dataSize, dx
		mov	ds:[di].PH_dataOffset, size DatagramPacketHeader
		mov	bx, es:[domain]
		mov	ds:[di].PH_domain, bx
exit:
		.leave
		ret
SlipAllocDataBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipDeliverPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deliver a complete packet to the client.

CALLED BY:	SlipProcessInputByte

PASS:		cx:dx	= packet
		es	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx, di (allowed)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipDeliverPacket	proc	near

	;
	; Deliver if we have a client.
	;
		mov	di, SCO_RECEIVE_PACKET
		movdw	bxax, es:[clientEntry]
		tstdw	bxax						
		je	exit
		call	ProcCallFixedOrMovable
exit:
		ret
SlipDeliverPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipDownsizeBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Downsize a buffer to be the size of the data and unlock it.

CALLED BY:	SlipProcessInputByte

PASS:		^lcx:dx = buffer
		di	= size to downsize buffer to		
		es	= dgroup

RETURN:		^lcx:dx	= downsized buffer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipDownsizeBuffer	proc	near
		uses	ax, bx, si, ds
		.enter

EC <		tst	di						>
EC <		ERROR_E MUST_HAVE_SLIP_DATA_IF_BUFFER_EXISTS		>

EC <		mov	ax, dgroup					>
EC <		mov	bx, es						>
EC <		cmp	ax, bx						>
EC <		ERROR_NE -1	; es not dgroup!			>

		mov	bx, cx			; ^lbx:dx = buffer
		
		movdw	dssi, es:[dataPtr]	; ds:si = data portion
		sub	si, size DatagramPacketHeader	; ds:si = DPH
		mov	ds:[si].PH_dataSize, di	; decrease size
		mov	ax, dx			; *ds:ax = buffer
		mov	cx, di				
		add	cx, size DatagramPacketHeader	; cx = new size

EC <		push	ds					>
		
		call	HugeLMemReAlloc

EC <		pop	ax					>
EC <		mov	cx, ds					>
EC <		cmp	cx, ax					>
EC <		ERROR_NE BLOCK_MOVED_ON_DOWNSIZE		>
		
		call	HugeLMemUnlock
		mov	cx, bx			; ^lcx:dx = buffer 

		.leave
		ret
SlipDownsizeBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipGetBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the location to store the input byte.

CALLED BY:	SlipProcessInputByte

PASS:		es 	= dgroup

RETURN:		carry set if out of memory
		else 
		ds:di	= ptr to destination for byte

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Store address of data in dataPtr instead of address of buffer
		so we don't have to add size of DatagramPacketHeader everytime
		a new byte is inserted.  Small optimization but every little
		bit helps...

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipGetBuffer	proc	near
		uses	ax, bx, cx
		.enter
		
		movdw	bxcx, es:[dataBuffer]
		tstdw	bxcx
		jne	haveBuffer
	;
	; Allocate a new data buffer and reset the count.  Buffer
	; will be downsized later.  Set pointer to beginning of data.
	;
		mov	es:[count], bx			; zero count
		mov	ax, es:[maxFrame]
		call	SlipAllocDataBuffer		; ^lax:cx = buffer
							; ds:di = buffer
		jc	exit

		movdw	es:[dataBuffer], axcx
		add	di, size DatagramPacketHeader	; ds:di = start of data
		movdw	es:[dataPtr], dsdi
		jmp	done
haveBuffer:
	;
	; Return location for next byte of data.
	;		
		
		movdw	dsdi, es:[dataPtr]
		add	di, es:[count]
done:		
		clc
exit:	
		.leave
		ret
SlipGetBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipFreeBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free buffer containing partially reconstructed SLIP frame.
		Reset pointers into buffer and count of received bytes.

CALLED BY:	SlipLinkClosed
PASS:		ds	= dgroup

RETURN:		nothing		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Do this on SLIP driver's thread so we don't accidently
		free the buffer while the driver is using it.

		Also because it has to be unlocked by the same thread
		that locked it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	9/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipFreeBuffer	proc	near

		uses	ax, cx		
		.enter

		clr	ax, cx
		mov	ds:[inputEnd], ax
		mov	ds:[inputStart], ax
		mov	ds:[count], ax
		xchgdw	axcx, ds:[dataBuffer]
		tstdw	axcx
		je	done
		call	HugeLMemFree
done:
		.leave
		ret
SlipFreeBuffer	endp




;---------------------------------------------------------------------------
;		Methods for SlipProcessClass
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipOpenLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish the SLIP connection.

CALLED BY:	MSG_SLIP_OPEN_LINK
PASS:		*ds:si	= SlipProcessClass object
		ds:di	= instance data
		es 	= segment of SlipProcessClass

RETURN:		nothing		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Open the serial serial.
		Reset pointers to input buffer.
		Then send a <CR> across the line to begin TIA login
		process.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	9/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipOpenLink	method dynamic SlipProcessClass, 
					MSG_SLIP_OPEN_LINK

	;
	; Check if interrupted.
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		call	SlipGainAccess
		
		mov	ax, ds:[slipError]
		cmp	ax, SDE_INTERRUPTED
		je	error

	;
	; Open the port.  
	;
		call	SlipOpenSerialPort
		mov	ax, SDE_MEDIUM_BUSY		; assume error
		jc	error

if _TIA	
	;
	; Send a <CR> across the serial line to initiate login.
	; 
		mov	ax, STREAM_NOBLOCK
		mov	bx, ds:[slipPort]
		mov	cl, C_CR
		mov	di, DR_STREAM_WRITE_BYTE
		call	ds:[serialStrategy]
EC <		ERROR_C	-1		; Must be able to write 1st byte!>
		
		mov	ds:[slipState], SS_SENT_CR
		call	SlipReleaseAccess
		jmp	exit
else
	;
	; Set state to open. 
	;		
		mov	ds:[slipState], SS_OPEN
		call	SlipReleaseAccess
		call	SlipLinkOpened
		jmp	exit
endif

error:
	;
	; Reset state and status. Release access and notify or 
	; wake client.
	;
		mov	ds:[slipState], SS_CLOSED
		mov	bl, ds:[slipStatus]
		BitClr	ds:[slipStatus], SDS_WAITER_EXISTS
		call	SlipReleaseAccess

		test	bl, mask SDS_WAITER_EXISTS
		jz	notify

		mov	bx, ds:[slipSem]
		call	ThreadVSem
		jmp	exit
notify:
		mov_tr	dx, ax				; dx = error
		mov	ax, SLIP_CONNECTION_HANDLE
		mov	di, SCO_CONNECT_FAILED
		mov	bx, ds:[domain]
		pushdw	ds:[clientEntry]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
exit:
		ret

SlipOpenLink	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipCloseLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the slip connection.

CALLED BY:	MSG_SLIP_CLOSE_LINK
PASS:		*ds:si	= SlipProcessClass object
		es 	= segment of SlipProcessClass

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp  (okay because this msg is FORCE_QUEUE-d)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	9/15/94   	Initial version
	jwu	8/13/96		Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipCloseLink	method dynamic SlipProcessClass, 
					MSG_SLIP_CLOSE_LINK
		mov	bx, handle dgroup
		call	MemDerefDS
		
if _TIA	
		call	SlipQuitTia
		call	SlipGainAccess
		mov	ds:[slipState], SS_QUIT_TIA
		call	SlipReleaseAccess
else

		call	SlipLinkClosed

endif

		ret
SlipCloseLink	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipSendFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the buffer's data in a slip frame.

CALLED BY:	MSG_SLIP_SEND_FRAME
PASS:		*ds:si	= SlipProcessClass object
		dx:bp	= optr of buffer
		cx	= # of bytes of data
		
RETURN:		nothing		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	12/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipSendFrame	method dynamic SlipProcessClass, 
					MSG_SLIP_SEND_FRAME
	;
	; If no data in packet or if link is closed, drop packet.  
	;		
		jcxz	freeBuffer

		mov	bx, handle dgroup
		call	MemDerefDS
		cmp	ds:[slipState], SS_OPEN
		jne	freeBuffer
	; 
	; Find data in buffer and send it.
	;
		mov	bx, dx				; ^lbx:bp = buffer
		call	HugeLMemLock
		mov	ds, ax				
		mov	si, ds:[bp]			; ds:si = DPH
		
		add	si, ds:[si].PH_dataOffset	; ds:si = data
		call	SlipSend			
	;						
	; Free the buffer.
	;		
		call	HugeLMemUnlock
freeBuffer:
		movdw	axcx, dxbp 			; ^lax:cx = buffer
		call	HugeLMemFree

		ret
SlipSendFrame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipVerifyConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if we've seen valid SLIP data arrive on the 
		connection yet.  

CALLED BY:	MSG_SLIP_VERIFY_CONNECTION
PASS:		*ds:si	= SlipProcessClass object
		es 	= segment of SlipProcessClass

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	11/28/94   	Initial version
	jwu	 8/13/96	Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipVerifyConnection	method dynamic SlipProcessClass, 
					MSG_SLIP_VERIFY_CONNECTION
	;
	; If we aren't waiting for data anymore, than all is well.
	; Or, if we are no longer registered, then don't do anything.
	;
		mov	bx, handle dgroup
		call	MemDerefDS

		call	SlipGainAccess
		clr	ax
		mov	ds:[timerHan], ax
		mov	ds:[timerID], ax
		mov	al, ds:[slipStatus]
		call	SlipReleaseAccess

		test	al, mask SDS_WAITING_FOR_DATA 
		jz	done
	;
	; Assume connection is bad because we still haven't seen any 
	; SLIP frame markers.  
	;
		call	SlipLinkClosed
done:

		ret
SlipVerifyConnection	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipProcessInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read notification handler for the serial port.

CALLED BY:	MSG_SLIP_PROCESS_INPUT
PASS:		*ds:si	= SlipProcessClass object
		ds:di	= SlipProcessClass instance data
		es 	= segment of SlipProcessClass

RETURN:		nothing		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Read all of the data or no further notifications will 
		arrive for remaining data.  If too much to fit in buffer,
		read again after processing some of the data.

		Check the state and process data accordingly.
NOTE:
		Safe to reset buffer when full because data is processed
		each time through the loop.  The only exception is in
		the beginning before a client is registered.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	9/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipProcessInput	method dynamic SlipProcessClass, 
					MSG_SLIP_PROCESS_INPUT
		uses	ax, cx, dx, bp
		.enter
	;
	; If state is closed, serial port is closed, so no point in reading.
	; Otherwise, must read something to get future notifications.
	;
		mov	bx, handle dgroup
		call	MemDerefDS

		call	SlipGainAccess
		mov	bx, ds:[slipState]
		call	SlipReleaseAccess

		cmp	bx, SS_CLOSED
		je	exit

		segmov	es, ds, bx			; es = dgroup
		mov	bx, es:[inputBuffer]
		call	MemLock
		mov	ds, ax
readLoop:
	;
	; Read what we can fit in the buffer.  If buffer is full 
	; for data, reset it.  
	;
		mov	si, es:[inputEnd]	; ds:si = buffer for input
		mov	cx, BUFFER_SIZE		; cx = total size of input buffer
		sub	cx, si			; cx = space in input buffer
		jnz	read

		clr	si
		mov	es:[inputEnd], si
		mov	es:[inputStart], si
		mov	cx, BUFFER_SIZE		
read:		
		mov	dx, cx			
		mov	bx, es:[slipPort]
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_READ
		call	es:[serialStrategy]	; cx = # bytes read 
		jcxz	exit
		
		add	es:[inputEnd], cx
		sub	dx, cx			; dx = bytes not read
	;
	; Call handler to process the input data.  
	;
if _TIA
		call	SlipReceiveDataTia
else
		call	SlipReceiveData
endif
	;
	; If the read returned the amount of data requested, keep reading
	;  because there may be more data.
	;
		tst	dx			
		je	readLoop

		mov	bx, es:[inputBuffer]
		call	MemUnlock
exit:
		.leave
		ret
SlipProcessInput	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to decide if detach is allowed yet.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= SlipProcessClass object
		es 	= segment of SlipProcessClass
		ax	= message #
		cx	= caller's ID
		dx:bp	= caller's OD		

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If SLIP has a client, then do not handle this because
		client will unregister us and then we can detach.

		Else, call superclass.

		NOTE: Caller MUST have access!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	1/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipDetach	method dynamic SlipProcessClass, 
					MSG_META_DETACH

		push	ds
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bl, ds:[slipStatus]
		pop	ds

		test	bl, mask SDS_REGISTERED
		jnz	exit

		mov	di, offset SlipProcessClass
		call	ObjCallSuperNoLock
exit:
		ret
SlipDetach	endm


CommonCode	ends
