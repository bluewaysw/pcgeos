COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		PPP Driver
FILE:		pppMain.asm

AUTHOR:		Jennifer Wu, Apr 19, 1995

ROUTINES:
	Name			Description
	----			-----------
Socket driver function handlers:
--------------------------------
	PPPStrategy

	PPPDoNothing

	PPPInit
	PPPExit
	PPPSuspend
	PPPRegister
	PPPUnregister
	PPPAllocConnection
	PPPLinkConnectRequest
	PPPStopLinkConnect
	PPPDisconnectRequest
	PPPSendDatagram
	PPPResetRequest
	PPPGetInfo
	PPPResolveAddr
	PPPMediumActivated
	PADCallTerminated			  ; Penelope PAD
	
Method handlers for PPPProcessClass:
------------------------------------
	PPPDetach
	PPPTimeout
	PPPOpenLink
	PPPCloseLink
	PPPSendFrame
	PPPHandleDataNotification
	PPPHandlePadStreamStatus		 ; Penelope PAD
	PPPPClientDataProto                      ; Penelope PAD
	PPPPClientConnectProto			 ; Penelope PAD
	PPPPClientErrorProto			 ; Penelope PAD

Misc:
-----
	ECCheckClientInfo

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	4/19/95		Initial revision

DESCRIPTION:
	

	$Id: pppMain.asm,v 1.34 98/08/12 17:24:12 jwu Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;			Dgroup
;---------------------------------------------------------------------------

ResidentCode	segment resource

DriverTable	SocketDriverInfoStruct <
		<PPPStrategy,
		0,
		DRIVER_TYPE_SOCKET>,
		0,
		(mask SDPO_MAX_PKT or mask SDPO_UNIT),
		PPP_MIN_DGRAM_HDR
		>

ForceRef DriverTable

ResidentCode	ends


idata	segment

	;
	; First word in segment of process class must be a handle or 
	; kernel code will die when calling superclass.  Process class
	; created in drivers must manually put the handle in dgroup.
	;
	myHandle	hptr		handle 0

	port		SerialPortNum	PPP_DEFAULT_PORT
	baud		SerialBaud	PPP_DEFAULT_BAUD

if _RESPONDER
	;
	; Data structure for logging outgoing calls with Contact Log.
	;
	pppLogEntry	LogEntry <
			0,				; LE_number
			LECI_INVALID_CONTACT_ID,	; LE_contactID
			LET_DATA,			; LE_type
			LED_SENT,			; LE_direction
			0,				; LE_duration
			<0>,				; LE_datetime
			0>				; LE_flags
endif ; _RESPONDER

idata	ends

ForceRef myHandle

udata	segment

	pppThread	hptr.HandleThread	
	timerHandle	hptr			
	hugeLMem	hptr
	inputBuffer	hptr

	regSem		hptr		; semaphore for registering clients
	taskSem		hptr		; mutex for PPP actions that need to
					;  be synchronized
	clientInfo	PppClientInfo

	flowCtrl	SerialFlowControl 

	serialStrategy	fptr
if not _PENELOPE
	serialDr	hptr
	modemStrategy	fptr
	modemDr		hptr		; only loaded when needed
	baudRate	word		; the baud rate from modem
endif
	mediumType	MediumType	; for Clavin notifications

	spaceToken	word		; token from GeodeRequestSpace

if _RESPONDER
	vpClientToken	VpClientToken	; token assigned by VP library
	vpCallID	byte
	callEnded	BooleanByte
endif

if _PENELOPE
	padOptr		optr		; PAD's optr to send messages
	padLibrary	hptr		; PAD's library handle

	padResponse	AtTranslationType_e ; latest response from PAD
	padStatus       word            ; initially 0x0040 (CD set).
	padSignalDone	byte		; -1 TRUE, 0 FALSE for
					; PPPGetPADResponse
        padAbnormalDisconnect byte      ; -1 if PAD disconnects us 
                      			; abnormally, else 0
	padStreamDr	hptr
	padStreamStrategy	fptr
	padUpStream	word		; StreamToken to read data
	padDnStream	word		; StreamToken to write data
endif

udata	ends

idata	segment
;; The data will be used by internet dial-up application.
       bytesSent	 dword		0
       bytesReceived	 dword		0
       idRegistered	 byte		0
idata	ends


PPPClassStructures	segment resource
	PPPProcessClass	
	PPPUIClass
	PPPAddressControlClass
	PPPSpecialTextClass
PPPClassStructures	ends


;---------------------------------------------------------------------------
;			Strategy Routine
;---------------------------------------------------------------------------

ResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all PPP driver calls.

CALLED BY:	EXTERNAL (PPP client)

PASS:		di	= SocketFunction
		see specific socket function for other arguments

RETURN:		carry set if some error occurred
		see specific socket function for return values

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/19/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStrategy	proc	far
		uses	di
		.enter

EC <		call	ECCheckClientInfo				>

		cmp	di, SOCKET_DR_FIRST_SPEC_FUNC
		jge	dialup

		shl	di				; index (4-byte) fptrs
		cmp	di, size driverProcTable
		jae	badCall

		pushdw	cs:driverProcTable[di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
exit:
		.leave
		ret

dialup:
	;check if the function is one of our special functions defined for the
	;internet dialup application
		sub	  di, SOCKET_DR_FIRST_SPEC_FUNC
		shl	  di
		cmp	  di, size PPPIDFuncTable
		jae	  badCall

		pushdw	  cs:PPPIDFuncTable[di]
		call	  PROCCALLFIXEDORMOVABLE_PASCAL

		jmp	  exit
		
badCall:
		
		mov	ax, SDE_UNSUPPORTED_FUNCTION
		stc
		jmp	exit

PPPStrategy	endp

driverProcTable		fptr.far	\
	PPPInit,	
	PPPExit,		
	PPPSuspend,
	PPPDoNothing,			; DR_UNSUSPEND
	PPPRegister,
	PPPUnregister,
	PPPAllocConnection,
	PPPLinkConnectRequest,
	PPPDoNothing, 			; DR_SOCKET_DATA_CONNECT_REQUEST
	PPPStopLinkConnect,
	PPPDisconnectRequest,		
	PPPDoNothing,			; DR_SOCKET_SEND_DATA
	PPPDoNothing,			; DR_SOCKET_STOP_SEND_DATA
	PPPSendDatagram,	
	PPPResetRequest,
	PPPDoNothing,			; DR_SOCKET_ATTACH
	PPPDoNothing,			; DR_SOCKET_REJECT
	PPPGetInfo,
	PPPDoNothing,			; DR_SOCKET_SET_OPTION
	PPPDoNothing,			; DR_SOCKET_GET_OPTION
	PPPResolveAddr,		
	PPPDoNothing,			; DR_SOCKET_STOP_RESOLVE
	PPPDoNothing,			; DR_SOCKET_CLOSE_MEDIUM
	PPPDoNothing,			; DR_SOCKET_MEDIUM_CONNECT_REQUEST
	PPPMediumActivated,
	PPPDoNothing,			; DR_SOCKET_SET_MEDIUM_OPTION
	PPPDoNothing			; DR_SOCKET_RESOLVE_LINK_LEVEL_ADDRESS

PPPIDFuncTable		fptr.far	\
	PPPIDGetBaudRate,
	PPPIDGetBytesSent,
	PPPIDGetBytesReceived,
	PPPIDRegister,
	PPPIDUnregister,
	PPPIDForceDisconnect


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just clear the carry.

CALLED BY:	PPPStrategy

RETURN:		carry clear

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPDoNothing	proc	far
		clc
		ret
PPPDoNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckClientInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate clientInfo structure.  

CALLED BY:	PPPStrategy

PASS:		nothing

RETURN:		only if clientInfo is valid

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/25/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECCheckClientInfo	proc	far
		uses	bx, ds
		.enter

		mov	bx, handle dgroup
		call	MemDerefDS
		
		tst	ds:[clientInfo].PCI_unit	
		ERROR_NE PPP_CORRUPT_CLIENT_INFO

		mov	bl, ds:[clientInfo].PCI_linkState
		Assert	etype, bl, PppLinkState	
		
		mov	bx, ds:[clientInfo].PCI_mutex
		tst	bx
		je	checkError
		test	bl, 00001111b		; just check 16 byte boundary
		ERROR_NE PPP_CORRUPT_CLIENT_INFO
checkError:
		mov	bx, ds:[clientInfo].PCI_error
		tst	bx
		je	exit
		Assert	etype, bl, SocketDrError
		clr	bl
		Assert 	etype, bx, SpecSocketDrError
exit:
		.leave
		ret
ECCheckClientInfo	endp



endif	; ERROR_CHECK

ResidentCode	ends

InitCode		segment resource
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the PPP driver.

CALLED BY:	PPPStrategy

PASS:		nothing

RETURN:		carry clear if driver successfully initialized

DESTROYED:	ax, cx, dx, bp, di, si, ds, es (allowed)

PSEUDO CODE/STRATEGY:
		Load appropriate serial driver and get strategy routine
		Allocate input buffer block
		Allocate a HugeLMem
		Allocate registration semaphore
		call PPPSetup to initialize the protocols

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPInit	proc	far
		uses	bx
		.enter
	;
	; Get some elbow room.  (Use UI for the app.)  Bail if 
	; request is denied.
	;
		mov	bx, handle dgroup
		call	MemDerefDS		

		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo		; ax = UI handle

		mov	cx, PPP_SPACE_NEEDED
		mov_tr	bx, ax
		call	GeodeRequestSpace	; bx = reservation token
		jc	exit	

		mov	ds:[spaceToken], bx
	;
	; Load appropriate serial driver and get serial strategy routine.
	
	;
	; For Penelope, PAD loads the serial driver and returns to us a
	; stream handle. So serial driver is not always loaded.
	;
if _PENELOPE
	; 
	; For PENELOPE, medium is GMID_CELL_MODEM and Unit is 0. Port
	; is used as the Unit in many routines in PPP.
	;
		mov	ds:[port], 0		; unit = 0 (for Medium
						; and Unit).
else 
		call	PPPLoadSerialDriver
		jc	error
	;
	; Read port and baud settings.
	;
		call	PPPGetPortSettings
endif
	;
	; Allocate block for input buffer and make sure we own it.
	;
		mov	ax, PPP_INPUT_BUFFER_SIZE
		mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE
		mov	bx, handle 0
		call	MemAllocSetOwner
		jc	error

		mov	ds:[inputBuffer], bx
	;
	; Create huge lmem for allocating buffers.  
	;
		clr	ax
		mov	bx, MIN_OPTIMAL_BLOCK_SIZE
		mov	cx, MAX_OPTIMAL_BLOCK_SIZE
		call	HugeLMemCreate
		jc	error

		mov	ds:[hugeLMem], bx
	;
	; Allocate the semaphore for synchronizing client registration
	; and link open/closes.   Make sure we own both!
	;
		mov	bx, 1
		call	ThreadAllocSem
		mov	ds:[regSem], bx
	
		mov	ax, handle 0
		call	HandleModifyOwner		; destroys AX

		mov	bx, 1
		call	ThreadAllocSem
		mov	ds:[taskSem], bx
	
		mov	ax, handle 0
		call	HandleModifyOwner
	;
	; Initialize PPP protocols.  DS already points to dgroup for
	; the C routine.
	;
		call	PPPSetup
		clc
		jmp	exit
error:
		call	PPPExit
		stc
exit:
		.leave
		ret
PPPInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shutdown the PPP driver.

CALLED BY:	PPPStrategy
		PPPInit

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, ds, es (allowed)

PSEUDO CODE/STRATEGY:
		Shutdown PPP protocol.
		Close any open devices.
		Free input buffer
		Free HugeLmem
		Free registration semaphore
		Return requested space.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPExit	proc	far

	;
	; Only cleanup if not doing a dirty shutdown.  
	;
		mov	bx, handle dgroup
		call	MemDerefDS		

		mov	al, ds:[clientInfo].PCI_status
		and	ax, mask CS_REGISTERED  
EC <		WARNING_NZ PPP_DIRTY_SHUTDOWN				>
		push	ax		
		call	PPPShutdown

if _PENELOPE
	;
	; Unregister from PAD and unload PAD. PAD is responsible for
	; loading and unloading serial driver.
	;
		call 	PPPUnloadPAD
else
	;
	; Unload serial driver, if loaded.  If not, then we didn't get
	; any further so just return the borrowed space.
	;
		clr	bx
		xchg	bx, ds:[serialDr]
		tst	bx
		je	returnSpace
		call	GeodeFreeDriver
endif
	;
	; Free input buffer.  If not allocated, then hugelmem and
	; reg semaphore never got created.
	;
		clr	bx
		xchg	bx, ds:[inputBuffer]
		tst	bx
		je	returnSpace
		call	MemFree
	;
	; Free huge lmem and registration semaphore.  If huge lmem was
	; not allocated, then we didn't allocate a semaphore.
	;
		clr	bx
		xchg	bx, ds:[hugeLMem]
		tst	bx
		je	returnSpace
		call	HugeLMemDestroy

		clr	bx
		xchg	bx, ds:[regSem]
		call	ThreadFreeSem

		clr	bx
		xchg	bx, ds:[taskSem]
		call	ThreadFreeSem
returnSpace:
	;
	; Return borrowed space.  Do this last!
	;
		clr	bx
		xchg	bx, ds:[spaceToken]
		tst	bx
		jz	exit
		call	GeodeReturnSpace
exit:
		ret
PPPExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow suspension if no connections are open.

CALLED BY:	PPPStrategy

PASS:		cx:dx	= buffer to place reason for for refusal, if refused

RETURN:		carry set if suspension refused
			cx:dx	= buffer filled with null terminated reason
			(DRIVER_SUSPEND_ERROR_BUFFER_SIZE bytes long)
		carry clear if suspension approved

DESTROYED:	ax, di (allowed)

PSEUDO CODE/STRATEGY:
		Find out if a connection is not closed

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSuspend	proc	far
		uses	bx, si, ds, es
		.enter

EC <		Assert	buffer, cxdx, DRIVER_SUSPEND_ERROR_BUFFER_SIZE	>
	;
	; Allow suspension if PPP link is closed.
	;
		mov	bx, handle dgroup
		call	MemDerefES

		cmp	es:[clientInfo].PCI_linkState, PLS_CLOSED
		je	exit				; carry clear 
	;
	; Refuse suspension.  Give reason.
	;
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, offset refuseSuspendString
		mov	si, ds:[si]

EC <		push	cx						>
EC <		movdw	esdi, dssi					>
EC <		call	LocalStringSize		; cx = size w/o null	>
EC <		cmp	cx, DRIVER_SUSPEND_ERROR_BUFFER_SIZE		>
EC <		ERROR_AE PPP_REFUSE_SUSPEND_STRING_TOO_LONG		>
EC <		pop	cx						>

		movdw	esdi, cxdx
		LocalCopyString

		call	MemUnlock
		stc
exit:
		.leave
		ret
PPPSuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a client to use PPP.

CALLED BY:	PPPStrategy

PASS:		bx	= domain handle of the driver
		ds:si 	= domain name (null terminated)  (ignored)
		dx:bp	= client entry point for SCO functions (virtual fptr)
		cl	= SocketDriverType (ignored)

RETURN:		carry set if error
		ax	= SocketDrError (SDE_ALREADY_REGISTERED,
					 SDE_MEDIUM_BUSY)
		else
		bx	= client handle
		cl	= min header size required

DESTROYED:	ax, bx if not returned (di allowed)

PSEUDO CODE/STRATEGY:
		Grab the reg sem 
		if client is already registered 
			if client is same client
				return error with SDE_ALREADY_REGISTERED
			else
				return error with SDE_MEDIUM_BUSY
		else
			store registration info
			allocate mutex for client
			spawn thread
			start timer
			return registration info
		release reg sem

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPRegister	proc	far
		uses	ds
		.enter

EC <		push	bx, si					>
EC <		movdw	bxsi, dxbp				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>

	;
	; Get in line for registration.
	;
		mov	di, bx				; di = domain handle
		mov	bx, handle dgroup
		call	MemDerefDS

		mov	bx, ds:[regSem]
		call	ThreadPSem

	;
	; Only allow registration if not already registered.
	;
		test	ds:[clientInfo].PCI_status, mask CS_REGISTERED
		jne	busy

	;
	; Store registration info.  Allocate mutex, spawn thread and
	; start timer.  
	;
		BitSet	ds:[clientInfo].PCI_status, CS_REGISTERED
		mov	ds:[clientInfo].PCI_domain, di
		movdw	ds:[clientInfo].PCI_clientEntry, dxbp

		clr	bx				; blocking sem
		call	ThreadAllocSem			; bx = semaphore
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	ds:[clientInfo].PCI_mutex, bx

		call	PPPCreateThread			; di = error, if any
		jc	error

		mov	cl, PPP_MIN_HDR_SIZE
		clc
		jmp	done
busy:
	;
	; If client is already registered, determine if client is
	; the same or different.  PPP driver can only be registered
	; once.  (For now because it only supports one interface.)
	;
		mov	di, SDE_MEDIUM_BUSY
		cmpdw	dxbp, ds:[clientInfo].PCI_clientEntry
		jne	error

		mov	di, SDE_ALREADY_REGISTERED
error:
		stc
done:
		mov	bx, ds:[regSem]
		call	ThreadVSem		; trashes AX
		mov_tr	ax, di			; return any error
		mov	bx, offset clientInfo	; return client handle

		.leave
		ret
PPPRegister	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister the client.

CALLED BY:	PPPStrategy

PASS:		bx	= client handle

RETURN:		carry clear if unregisterd
		bx	= domain handle

DESTROYED:	bx if unregister refused
		di (allowed)

PSEUDO CODE/STRATEGY:
		get in line before doing anything
		Refuse unregistration if link state is not closed.
		Else
			reset client info
			free mutex
			destroy thread			

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPUnregister	proc	far
		uses	ax, si, ds
		.enter

EC <		cmp	bx, offset clientInfo			>
EC <		ERROR_NE PPP_INVALID_CLIENT_HANDLE		>	
	;
	; Get in line.
	;
		mov_tr	si, bx				
		mov	bx, handle dgroup
		call	MemDerefDS			; ds:si = client info

		mov	bx, ds:[regSem]
		call	ThreadPSem
	;
	; Is client even registered?
	;
		test	ds:[si].PCI_status, mask CS_REGISTERED
		je	error
		
		cmp	ds:[si].PCI_linkState, PLS_CLOSED
EC <		WARNING_NE PPP_CLIENT_UNREGISTERING_BEFORE_LINK_CLOSED	>
		jne	error
	;
	; Reset client information.  Free the mutex, stop the timer
	; and destroy the thread.
	;
		BitClr	ds:[si].PCI_status, CS_REGISTERED
		clr	bx
		movdw	ds:[si].PCI_clientEntry, bxbx
		mov	ds:[si].PCI_linkState, bl
		mov	ds:[si].PCI_timer, bx
		mov	ds:[si].PCI_error, bx

		xchg	bx, ds:[si].PCI_mutex
		call	ThreadFreeSem
		
		call	PPPDestroyThread
	;
	; Return domain handle.  
	;
		clr	di				; clears carry
		xchg	di, ds:[si].PCI_domain		; carry still clear
		jmp	exit
error:
		stc
exit:
		mov	bx, ds:[regSem]
		call	ThreadVSem			; preserves flags
		mov	bx, di				; return domain handle

		.leave
		ret
PPPUnregister	endp

InitCode		ends
	
ConnectCode		segment resource
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPAllocConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assign a connection handle to client for use with 
		DR_SOCKET_LINK_CONNECT_REQUEST.

CALLED BY:	PPPStrategy

PASS:		bx	= client handle

RETURN:		carry set if error
			ax 	= SocketDrError	(SDE_MEDIUM_BUSY)
		else carry clear 
			ax	= connection handle

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:
		
		grab taskSem
		if status shows a blocked client, a passive
			connect is occurring, so return SDE_MEDIUM_BUSY
		if closed, set state to OPEN
		release taskSem
		return connection handle

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/18/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPAllocConnection	proc	far
		uses	bx, es
		.enter

EC <		cmp	bx, offset clientInfo			>
EC <		ERROR_NE PPP_INVALID_CLIENT_HANDLE		>	

	;
	; Get in line.
	;
		mov	bx, handle dgroup		
		call	MemDerefES

		mov	bx, es:[taskSem]
		call	ThreadPSem			; destroys AX

	;
	; if the internet dialup not registered,
	; we need to launch internet dialup application and block here
	; until the IDialup tells us to go
	; we want to check the domain name, but it's ignored...
	;
		movdw	es:[bytesSent], 0
		movdw	es:[bytesReceived], 0
		tst	es:[idRegistered]
		jnz	cont
		call	PPPLaunchIDial
cont:
	;
	; May be blocked if a passive connection is being opened.
	;
		mov	di, SDE_MEDIUM_BUSY
		test	es:[clientInfo].PCI_status, mask CS_BLOCKED
		stc
		jnz	done
	;
	; If CLOSED, set state to OPENING and clear error.
	; Otherwise, connection is already open or will about to 
	; be so just return connection handle.
	;
		cmp	es:[clientInfo].PCI_linkState, PLS_CLOSED
		jne	retHandle

		mov	es:[clientInfo].PCI_linkState, PLS_OPENING
		mov	es:[clientInfo].PCI_error, SDE_NO_ERROR		

EC <		test	es:[clientInfo].PCI_status, mask CS_REGISTERED	>
EC <		ERROR_Z PPP_INTERNAL_ERROR				>
EC <		tst	es:[clientInfo].PCI_accpnt			>
EC <		ERROR_NZ PPP_INTERNAL_ERROR				>
EC <		tst	es:[clientInfo].PCI_timer			>
EC <		ERROR_NZ PPP_INTERNAL_ERROR				>

	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_OPENING
		call	PPPSendNotice
		pop	bp


retHandle:
		mov	di, PPP_CONNECTION_HANDLE
		clc
done:
	;
	; Release access and return result.
	;
		call	ThreadVSem			; preserves flags
		mov_tr	ax, di				; ax = SDE or handle

		.leave
		ret
PPPAllocConnection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPLinkConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open up the PPP link.

CALLED BY:	PPPStrategy

PASS:		cx	= timeout value (in ticks)
		bx	= connection  handle
		ds:si 	= non-null terminated string for addr to connect to
		ax	= addr string size

RETURN:		carry set if connect failed immediately
		ax	= SocketDrError with SpecSocketDrError
			  (SDE_LINK_OPEN_FAILED,
			   SDE_CONNECTION_TIMEOUT,
			   SDE_CONNECTION_RESET,
			   SDE_CONNECTION_RESET_BY_PEER,
			   SDE_CONNECTION_EXISTS,
			   SDE_INSUFFICIENT_MEMORY
			  possibly with
			   SSDE_INVALID_ACCPNT
			   SSDE_CANCEL
			   SSDE_NO_USERNAME	
			   SSDE_DEVICE_ERROR
			   SSDE_DEVICE_NOT_FOUND
			   SSDE_DEVICE_BUSY
			   SSDE_CALL_FAILED
			   SSDE_DEVICE_TIMEOUT
			   SSDE_DIAL_ERROR
			   SSDE_LINE_BUSY
			   SSDE_NO_DIALTONE
			   SSDE_NO_ANSWER
			   SSDE_NO_CARRIER
			   SSDE_BLACKLISTED
			   SSDE_DELAYED
			   SSDE_AUTH_FAILED
			   SSDE_AUTH_REFUSED
			   SSDE_NEG_FAILED
			   SSDE_LQM_FAILURE)		   
		otherwise, carry clear

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:

		grab taskSem
		if blocked, {
			release taskSem
			return busy (passive opening in progress)
		}
		if PLS_OPENING {
		 	convert timeout to intervals and store
			queue MSG_PPP_OPEN_LINK
		}
		release taskSem
		return connection handle

		Client handle is offset to client info.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version
	jwu	7/18/96			Non-blocking version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPLinkConnectRequest	proc	far
		uses	bx, cx, dx, bp, si, es, ds
		.enter

EC <		cmp	bx, PPP_CONNECTION_HANDLE		>
EC <		ERROR_NE PPP_INVALID_CONNECTION_HANDLE		>

EC <		push	bx					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx					>

	;
	; Get in line.
	;
		mov_tr	dx, ax				; dx = addr string size
		mov	bx, handle dgroup
		call	MemDerefES

		mov	bx, es:[taskSem]
		call	ThreadPSem			; destroys AX

	;
	; if the internet dialup not registered,
	; we need to launch internet dialup application and block here
	; until the IDialup tells us to go
	; we want to check the domain name, but it's ignored...
	;
		movdw	es:[bytesSent], 0
		movdw	es:[bytesReceived], 0
		tst	es:[idRegistered]
		jnz	cont
		call	PPPLaunchIDial
cont:
	;
	; May be blocked if a passive connection is being opened.
	;
		mov	ax, (SSDE_DEVICE_BUSY or SDE_LINK_OPEN_FAILED)
		test	es:[clientInfo].PCI_status, mask CS_BLOCKED	
		jnz	errorDone
	;
	; If link is already opened, return SDE_ALREADY_EXISTS
	; so client won't keep waiting for a notification.
	;
		mov	ax, SDE_CONNECTION_EXISTS
		cmp	es:[clientInfo].PCI_linkState, PLS_OPEN
		je	errorDone
	;
	; If beyond OPENING state, return success.  Link is in process
	; of opening so notification will be sent.  If state is less
	; than opening, connection is in process of closing so return 
	; connection exists.
	;
		CheckHack < PLS_CLOSING lt PLS_OPENING 	>
		CheckHack < PLS_OPENING lt PLS_LOGIN 	>
		CheckHack < PLS_LOGIN lt PLS_NEGOTIATING>
		CheckHack < PLS_NEGOTIATING lt PLS_OPEN	>

		cmp	es:[clientInfo].PCI_linkState, PLS_OPENING
		ja	done				; carry clear from cmp
		jb	errorDone			; ax = SDE_CONN_EXISTS

	;
	; Store timeout, converting from ticks to intervals and
	; rounding up.  Then queue a msg for the driver's thread
	; to open the link.
	;
		push	dx				; addr size
		mov_tr	ax, cx				
		clr	dx				; dx:ax = timeout
		mov	cx, PPP_TIMEOUT_INTERVAL		
		div	cx				; ax = quotient
							; dx = remainder
		tst	dx			
		jz	storeTime

		inc	ax
storeTime:
		mov	es:[clientInfo].PCI_timer, ax
		pop	cx				; cx = addr size
	;
	; Copy address to stack in case caller has it on their stack
	; and intends to free it as soon as this routine returns.
	;
		mov	bx, es:[pppThread]
		mov	di, mask MF_FORCE_QUEUE
		jcxz	sendMsg				; no address to copy

		push	es
		mov	dx, cx				; dx = addr size
		sub	sp, cx
		segmov	es, ss, di
		mov	di, sp
		rep	movsb
		mov	bp, sp				; ss:bp = address
		mov	cx, dx				; cx = addr size
		mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
sendMsg:
		mov	ax, MSG_PPP_OPEN_LINK
		call	ObjMessage
		jcxz	wellDone

		add	sp, cx
		pop	es				; es = dgroup
wellDone:
		clc
		jmp	done

errorDone:
		stc
done:
	;
	; Release access and return result.
	;
		xchg	cx, ax				; cx = result
		mov	bx, es:[taskSem]
		call	ThreadVSem			; preserves flags
		xchg	ax, cx				; ax = error, if any

		.leave
		ret
PPPLinkConnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStopLinkConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt a DR_SOCKET_LINK_CONNECT_REQUEST.

CALLED BY:	PPPStrategy

PASS:		bx	= connection handle

RETURN:		carry clear

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:
		grab taskSem

		if state is CLOSED or CLOSING, do nothing

		set state to PLS_CLOSING
		store SDE_INTERRUPTED as error

		if state is OPENING, do nothing
			(Other code will check for cancellation and
			stop the physical connection process)
		else if state is LOGIN,
			Notify Term to stop login process
		else if state is NEGOTIATING or OPENED
			queue driver MSG_PPP_CLOSE_LINK
	
		release taskSem
			
NOTES:
		Difference between this and PPPDisconnectRequest is that
		the latter blocks until link is already closed.  Also,
		PPPDisconnectRequest expects the link to be either opened
		or closed, but will not interrupt a partially opened link.


		CANNOT queue driver MSG_PPP_MANUAL_LOGIN_COMPLETE here.
		Must wait for Term to respond via the callback before
		continuing because Term may still be working with the
		serial port.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/18/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStopLinkConnect	proc	far
		uses	ax, bx, es
		.enter

EC <		cmp	bx, PPP_CONNECTION_HANDLE		>
EC <		ERROR_NE PPP_INVALID_CONNECTION_HANDLE		>

	;
	; Gain access.
	;
		mov	bx, handle dgroup
		call	MemDerefES

		mov	bx, es:[taskSem]
		call	ThreadPSem			; destroys AX

	;
	; If link is not opening or open, do nothing.
	;
		CheckHack < (PLS_CLOSED+1) eq PLS_CLOSING >

		mov	al, es:[clientInfo].PCI_linkState
		cmp	al, PLS_CLOSING
		jbe	done

	;
	; Set state and error BEFORE queuing messages for driver.
	;
		mov	es:[clientInfo].PCI_linkState, PLS_CLOSING
		mov	es:[clientInfo].PCI_error, SDE_INTERRUPTED
	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_CLOSING
		call	PPPSendNotice
		pop	bp


	;
	; If manual login in progress, notify Term to stop it.
	; Else, close link if beyond login process.
	;
		CheckHack <PLS_LOGIN_INIT lt PLS_OPENING>
		CheckHack <PLS_OPENING lt PLS_LOGIN>
		CheckHack <PLS_LOGIN lt PLS_NEGOTIATING>
		CheckHack <PLS_NEGOTIATING lt PLS_OPEN>

		cmp	al, PLS_LOGIN_INIT
		jb	done
		cmp	al, PLS_LOGIN
		ja	closeLink

		test	es:[clientInfo].PCI_status, mask CS_MANUAL_LOGIN
		jz	done

		call	PPPStopManualLogin
		jmp	done

closeLink:
		mov	ax, MSG_PPP_CLOSE_LINK
		mov	bx, es:[pppThread]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
	;
	; Release access and return success.
	;
		mov	bx, es:[taskSem]
		call	ThreadVSem
		clc

		.leave
		ret
PPPStopLinkConnect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the PPP link.

CALLED BY:	PPPStrategy

PASS:		bx	= connection handle
		ax	= SocketCloseType (ignored)

RETURN:		carry set if not connected
		ax 	= SDE_NO_ERROR

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:
		if link is already closed, return carry set
		else
			set CS_BLOCKED in client status
			queue message for driver thread to close link
			block on mutex

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPDisconnectRequest	proc	far
		uses	bx, es
		.enter

EC <		cmp	bx, PPP_CONNECTION_HANDLE		>
EC <		ERROR_NE PPP_INVALID_CONNECTION_HANDLE		>
	;
	; Get in line.
	;
		mov	bx, handle dgroup
		call	MemDerefES

		mov	bx, es:[taskSem]
		call	ThreadPSem			; destroys AX

EC <		test	es:[clientInfo].PCI_status, mask CS_BLOCKED	>
EC <		ERROR_NE PPP_TOO_MANY_TASKS				>
	;
	; If link closed, return carry.  Take advantage of PLS_CLOSED
	; being less than PLS_OPEN in doing the cmp to set carry.  
	; Don't forget to release task sem before returning.
	;
		CheckHack <PLS_CLOSED lt PLS_OPEN>
		cmp	es:[clientInfo].PCI_linkState, PLS_OPEN
		je	closeIt			

EC <		pushf							>
EC <		cmp	es:[clientInfo].PCI_linkState, PLS_CLOSED	>
EC <		ERROR_NE PPP_INTERNAL_ERROR	; use stop to interrupt >
EC <		popf							>

		call	ThreadVSem			; preserves flags
		jmp	exit				; carry set by cmp
closeIt:
	;
	; Remember that we are blocked.  
	;
		BitSet	es:[clientInfo].PCI_status, CS_BLOCKED	
		mov	es:[clientInfo].PCI_linkState, PLS_CLOSING
		call	ThreadVSem			; release task sem
	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_CLOSING
		call	PPPSendNotice
		pop	bp

	;
	; Have driver's thread do the close and wait for task to 
	; complete.
	;		
		mov	bx, es:[pppThread]
		mov	ax, MSG_PPP_CLOSE_LINK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		mov	bx, es:[clientInfo].PCI_mutex
		call	ThreadPSem
		clc
exit:
		mov	ax, SDE_NO_ERROR
		.leave
		ret
PPPDisconnectRequest	endp

ConnectCode		ends

PPPCODE			segment public 'CODE'


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSendDatagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a packet enclosed in a PPP frame.

CALLED BY:	PPPStrategy

PASS:		dx:bp	= optr of buffer
		cx	= size of data in buffer
		bx	= client handle
		ax	= size of address (ignored)
		ds:si	= non-null term. string for address (ignored)

RETURN:		carry clear	

DESTROYED:	ax, di (allowed)

PSEUDO CODE/STRATEGY:
		Pass buffer to driver thread to do the send.  

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSendDatagram	proc	far
		uses	bx, es
		.enter

EC <		Assert	optr, dxbp				>

EC <		cmp	bx, offset clientInfo			>
EC <		ERROR_NE PPP_INVALID_CLIENT_HANDLE		>

		mov	bx, handle dgroup
		call	MemDerefES		

		mov	bx, es:[pppThread]
		mov	ax, MSG_PPP_SEND_FRAME
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

	;
	; increase the count - bytesSent
	;
		push    bx
		movdw	axbx, es:[bytesSent]
		add	bx, cx
		jnc	done
		inc	ax
done:
		movdw	es:[bytesSent], axbx
		pop	bx

		clc
		.leave
		ret
PPPSendDatagram	endp

PPPCODE			ends

ConnectCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPResetRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the PPP link.  

CALLED BY:	PPPStrategy

PASS:		ax	= connection handle

RETURN:		nothing

DESTROYED:	di (allowed)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPResetRequest	proc	far
		uses	ax, bx
		.enter

		mov_tr	bx, ax			; bx = connection handle
		call	PPPDisconnectRequest

		.leave
		ret
PPPResetRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get info from the driver.

CALLED BY:	PPPStrategy

PASS:		ax	= SocketGetInfoType
		if SGIT_LOCAL_ADDR
			ds:bx	= buffer for address
			dx	= size of buffer

RETURN:		carry clear if info is available and
		   SGIT_MTU
			ax 	= maximum packet size
		   SGIT_LOCAL_ADDR
			ds:bx	= buffer filled with address if big enough
			ax	= address size
		   SGIT_MEDIUM_AND_UNIT
			cxdx	= MediumType
			bp	= GeoworksMediumID
			bl	= MediumUnitType
		   SGIT_ADDR_CTRL
			cx:dx	= pointer to class
		else, carry set

DESTROYED:	ax if not used for return value
		di (preserved by PPPStrategy)

PSEUDO CODE/ STRATEGY:
		use jump table and SocketGetInfoType to jump to 
		a label in routine for processing.  

		Be careful not to destroy any registers which aren't used
		as return values for that info type.

		Return carry set if info is not available

NOTE:
		MUST NOT grab taskSem because PPPLINKOPENED holds the 
		taskSem during notifications.  TCP will call this routine
		with the PPP thread to get info about the link.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/17/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPGetInfo	proc	far
		uses	di, es
		.enter

EC <		Assert	etype ax, SocketGetInfoType		>

		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx

		cmp	ax, size infoTable
		LONG	jae	noInfo
		
		mov_tr	di, ax
		jmp	cs:infoTable[di]
medAndUnit:
	;
	; Medium and unit.  Query for info.
	; XXX: Assumes MUT_INT if not GMID_CELL_MODEM!
	;
if _PENELOPE
	;
	; PPPP connects to PAD and PAD does not have a named medium. 
	; We assign PAD's medium to be as follows.
	;
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GMID_CELL_MODEM		; cxdx = MediumType
		clr	bp				; bp = nothing
		mov	bl, MUT_NONE
		jmp	done
else
		clr	cx
		mov	bx, es:[port]
		mov	di, DR_SERIAL_GET_MEDIUM
		call	es:[serialStrategy]		; dxax = MediumType

EC <		cmp	dx, ManufacturerID				>
EC <		WARNING_A SERIAL_DRIVER_RETURNED_INVALID_MANUFACTURER_ID>

		movdw	cxdx, dxax
		mov	bp, bx				; bp = port

		mov	bl, MUT_INT		
		cmp	dx, GMID_CELL_MODEM
		LONG	jne	done
		mov	bl, MUT_NONE
		jmp	done
endif

addrCtrl:
	;
	; Address control.  Return class for controller.  Increment
	; ref count of driver.
	;
		push	bx
		mov	bx, handle 0
		call	GeodeAddReference
		pop	bx

		mov	cx, vseg PPPAddressControlClass
		mov	dx, offset PPPAddressControlClass
		jmp	done
address:
	;
	; Local address.  Return local IP address used for link
	; if negotiated.  If none negotiated yet, then the info
	; is not avaiable at this moment.  Make sure buffer is 
	; big enough.
	;
EC <		Assert 	buffer dsbx, dx				>

		mov	ax, IP_ADDR_SIZE
		cmp	ax, dx
		ja	exit			; carry already clear

		push	bx, cx, si, ds		; destroyed by C
		segmov	ds, es, ax		; ds = dgroup for C
		call	GetLocalIPAddr		; dxax = IP addr
		pop	bx, cx, si, ds
		tstdw	dxax
		je	noInfo			; none yet

	;
	; Convert address to network form before copying to buffer.
	;
		xchg	dh, dl			
		xchg	ah, al			
		movdw	ds:[bx], axdx
		mov	ax, IP_ADDR_SIZE
		jmp	done
mtu:
	;
	; Ask LCP to return the negotiated MTU (aka MRU).
	;
		push	bx, cx, dx, si, ds	; destroyed by C
		segmov	ds, es, ax		; ds = dgroup for C
		call	GetInterfaceMTU		; ax = mtu
		pop	bx, cx, dx, si, ds
done:
		clc
		jmp	exit
noInfo:
		stc
exit:
		.leave
		ret

infoTable	nptr \
	offset noInfo,			; SGIT_MEDIA_LIST
	offset medAndUnit,		; SGIT_MEDIUM_AND_UNIT
	offset addrCtrl,		; SGIT_ADDR_CTRL
	offset noInfo,			; SGIT_ADDR_SIZE
	offset address,			; SGIT_LOCAL_ADDRESS
	offset noInfo,			; SGIT_REMOTE_ADDRESS
	offset mtu,			; SGIT_MTU
	offset noInfo,			; SGIT_PREF_CTRL
	offset noInfo			; SGIT_MEDIUM_CONNECTION

PPPGetInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPResolveAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve a link level address for PPP.

CALLED BY:	PPPStrategy

PASS:		ds:si 	= addr to resolve
		cx	= size of addr (including word for linkSize)
		dx:bp 	= buffer for resolved address
		ax	= buffer size 

RETURN:		carry clear
		dx:bp	= buffer filled with address if buffer is big enough
		cx	= size of resolved address

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:
		If buffer is big enough, copy the link address to the
		buffer.  PPP doesn't need the address resolved.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/17/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPResolveAddr	proc	far

EC <		Assert 	buffer dxbp, ax				>

EC <		push	bx, si					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		movdw	bxsi, dxbp				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>

	;
	; If buffer is big enough, copy link address to buffer.
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
PPPResolveAddr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPMediumActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by lurker after it loads PPP driver or by application
		detecting an incoming call.

CALLED BY:	PPPStrategy

PASS:		dx:bx	= MediumUnitType
			  (port is passively opened by lurker if port used)

		if RESPONDER:
			cl 	= call ID

RETURN:		carry set if error

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:
		If link isn't closed, return error
		If cell modem, store medium type 
		else if port differs from expected port, return error

		If PPP has no client, 
			allocate mutex
			Allocate a thread for PPP driver
		
		pretend we are registered (if we're not already)
		Remember client is passive
		Set PPP in passive mode
		set client timer
		have driver's thread open link and block
			until open has completed 

		if successful, 
			if no client
				get the IP client
				if failed, free mutex, destroy thread
					and clear register bit
				else return carry clear
			else just tell client link is opened and
				return carry clear
		if failed 
			if had no client
				free mutex, destroy thread and
				clear registered bit
			return carry
NOTES:
		Must P taskSem first, then regSem to avoid possible
		deadlock situations.  PPPLINKCLOSED also grabs both
		semaphores in this order.


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/17/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPMediumActivated	proc	far
		uses	ax, bx, cx, dx, si, ds, es
noClient	local	word
		.enter

EC <		push	bx, si					>
EC <		movdw	bxsi, dxbx				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>

	;
	; If link isn't closed, return error.
	;
		clr	noClient
		mov_tr	di, bx				; dx:di = MediumAndUnit
		mov	bx, handle dgroup
		call	MemDerefDS			; set DS dgroup for C
		
		mov	bx, ds:[taskSem]
		call	ThreadPSem			; gain access

		mov	bx, ds:[regSem]	
		call	ThreadPSem

		cmp	ds:[clientInfo].PCI_linkState, PLS_CLOSED
		LONG	jne	errorVSem
if _RESPONDER
	;
	; Store call ID.
	;
		mov	ds:[vpCallID], cl
endif
	;
	; Store medium type and continue if cell modem.  Else verify the
	; port is the same as the one PPP should be using.
	;
		mov	es, dx				; es:di = MediumAndUnit
		movdw	dxcx, es:[di].MU_medium
		movdw	ds:[mediumType], dxcx
		cmp	cx, GMID_CELL_MODEM
		je	okayToProceed

		mov	cx, es:[di].MU_unit
		cmp	ds:[port], cx
		LONG	jne	errorVSem
okayToProceed:
	;
	; The mutex and PPP driver thread aren't created until PPP
	; has a client so do it now if PPP doesn't have a client already.
	;
		test	ds:[clientInfo].PCI_status, mask CS_REGISTERED
		jnz	openLink			; have client

		call	PPPCreateThread
		LONG	jc	errorVSem

		clr	bx				
		call	ThreadAllocSem			
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	ds:[clientInfo].PCI_mutex, bx
		mov	noClient, bx			; bx is non-zero 
openLink:
	;
	; Set registered bit so we don't have to worry about a client
	; trying to register while we're doing this and remember PPP
	; is in the passive mode.  Might as well set the blocked flag
	; now since we're mucking with the status.
	;
		ornf	ds:[clientInfo].PCI_status, mask CS_REGISTERED \
				or mask CS_PASSIVE or mask CS_BLOCKED
	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_OPENING
		call	PPPSendNotice
		pop	bp


		mov	ds:[clientInfo].PCI_linkState, PLS_OPENING
		mov	ds:[clientInfo].PCI_timer, PPP_DEFAULT_OPEN_TIMEOUT

		call	PPPPassiveMode

		mov	bx, ds:[regSem]
		call	ThreadVSem

		mov	bx, ds:[taskSem]
		call	ThreadVSem		; release access

	;
	; Have driver's thread open the link and wait until completed.
	;
		clr	cx			; no address
		mov	bx, ds:[pppThread]
		mov	ax, MSG_PPP_OPEN_LINK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		mov	bx, ds:[clientInfo].PCI_mutex
		call	ThreadPSem

	;
	; Process result of opening the link.  
	;
		mov	bx, ds:[taskSem]
		call	ThreadPSem			; gain access

		mov	bx, ds:[regSem]
		call	ThreadPSem

		BitClr	ds:[clientInfo].PCI_status, CS_PASSIVE
		cmp	ds:[clientInfo].PCI_linkState, PLS_OPEN
		je	releaseAccess			; carry clear

	;
	; If no client, clear registered bit, free mutex, and destroy 
	; thread.
	;
		tst	noClient
		jz	errorVSem

		BitClr	ds:[clientInfo].PCI_status, CS_REGISTERED
		clr	bx
		xchg	bx, ds:[clientInfo].PCI_mutex
		call	ThreadFreeSem
		call	PPPDestroyThread

errorVSem:
		stc

if _RESPONDER
		mov	ds:[vpCallID], 0
endif

releaseAccess:
		mov	bx, ds:[regSem]
		call	ThreadVSem			; preserves flags

		mov	bx, ds:[taskSem]
		call	ThreadVSem			; preserves flags
exit::
		.leave
		ret
PPPMediumActivated	endp


if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PADCallTerminated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PAD has terminated PPP's call. We call PPPCallTerminated.

CALLED BY:	PPPHandlePadStreamStatus, 
		PPPPClientDataProto,
		PPPPClientErrorProto
PASS:		ds - dgroup
RETURN:		Nothing
DESTROYED:	Nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kkee    	7/ 7/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PADCallTerminated	proc	near
		uses	ax, bx, cx
		.enter
	;
	; Log the fact that the call was dropped as the error to return
	; to the client.
	;
		mov	bx, ds:[taskSem]
		call	ThreadPSem			; gain access
		mov	ds:[clientInfo].PCI_error, SSDE_NO_CARRIER or \
						   SDE_LINK_OPEN_FAILED
		call	ThreadVSem			; release access

	;
	; Reset stream so we don't call streamStrategy as
	; stream might be invalid, causing PPP to crash.
	;
		clr	ds:[padUpStream]
		clr	ds:[padDnStream]
		movdw	ds:[padStreamStrategy], 0
		clr	ds:[padStreamDr]

	;
	; Terminate protocol.
	;
		clr	ax
		push	ax
		call	PPPCallTerminated
done:
		.leave
		ret
PADCallTerminated	endp

endif

ConnectCode		ends

InitCode		segment resource

;---------------------------------------------------------------------------
;		Method Handlers for PPPProcessClass
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to decide if detach is allowed.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= PPPProcessClass object
		es 	= segment of PPPProcessClass
		cx	= caller's ID
		dx:bp	= caller's OD

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		If PPP has a client, then do not handle this because
		client will unregister us and then we can detach.

		Else, call superclass.

NOTE:		Caller MUST have P-ed regSem.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPDetach	method dynamic PPPProcessClass, 
					MSG_META_DETACH

		push	ds
		mov	bx, handle dgroup
		call	MemDerefDS

		test	ds:[clientInfo].PCI_status, mask CS_REGISTERED
		pop	ds
		jne	exit

		push	cx, dx, si, es		; preserve around C call
		call	PPPReset
		pop	cx, dx, si, es

		mov	ax, MSG_META_DETACH
		mov	di, offset PPPProcessClass
		call	ObjCallSuperNoLock
exit:
		ret
PPPDetach	endm

InitCode		ends

COMMONCODE		segment public 'CODE'


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process interval timer expiring.

CALLED BY:	MSG_PPP_TIMEOUT
PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPTimeout	method dynamic PPPProcessClass, 
					MSG_PPP_TIMEOUT
	;
	; Don't bother processing if the timer has been stopped since
	; this event was queued.
	;
		mov	bx, handle dgroup
		call	MemDerefDS		; setup dgroup for C

		tst	ds:[timerHandle]
		jz	exit
	;
	; Process client timer first.  If client timer expires,
	; LCP will stop all protocol timers and wake client.
	;
		tst	ds:[clientInfo].PCI_timer
		je	doProto			

		dec	ds:[clientInfo].PCI_timer
		jnz	doProto			

		call	lcp_client_timeout
		jmp	exit
doProto:
	;
	; Process PPP protocol timers.  DS already set to dgroup.
	;
		call	PPPHandleTimeout
exit:
		ret
PPPTimeout	endm

COMMONCODE		ends

ConnectCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPOpenLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open up the PPP link.

CALLED BY: 	PPPLinkConnectRequest and PPPMediumActivated
		via MSG_PPP_OPEN_LINK

PASS: 		cx 	= addr size 
		ss:bp	= non-null terminated address 

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		Check for interrupt throughout to catch a cancel and
		stop link connection as soon as possible.  Once LCP 
		has started, checking for interrupts is no longer 
		necessary.

		gain access
		Reset PPP protocol variables
		Get access point info
		if successful,
			Open device to specified address
			if failed
				clear timer, set error, wake up client
			else if not passive:
				Tell LCP the lower layer is up
				Signal LCP with the open event 
		release access

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95   	Initial version
	jwu	7/19/96		Check for interrupts and do manual login

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPOpenLink	method dynamic PPPProcessClass, 
					MSG_PPP_OPEN_LINK

	;
	; Clear former PPP protocol settings.  Must do this before access
	; point info is set or we will erase the new settings.
	;	
		mov	bx, handle dgroup
		call	MemDerefDS			; setup dgroup for C 

		push	cx
		call	PPPReset			; destroys all but bp
		pop	cx
	;
	; If have address, get info from access point.
	;
		mov	bx, ds:[taskSem]
		call	ThreadPSem

		cmp	ds:[clientInfo].PCI_linkState, PLS_CLOSING
		jbe	interrupted

		jcxz	openDevice			

EC <		test	ds:[clientInfo].PCI_status, mask CS_PASSIVE>
EC <		ERROR_NE PPP_INTERNAL_ERROR	; must be active mode! >

		mov	dx, ss				; dx:bp = address
		call	PPPSetAccessInfo		; ax = error
		jnc	openDevice
		
	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_ACCPNT
		call	PPPSendNotice
		pop	bp

		jmp	error		

openDevice:
	;
	; If manual login, initialize login app before continuing.
	;
		test	ds:[clientInfo].PCI_status, mask CS_MANUAL_LOGIN
		jz	noLogin

		mov	ds:[clientInfo].PCI_linkState, PLS_LOGIN_INIT
		call	PPPInitManualLogin		; ax = SSDE
		jc	error
		
		mov	bx, ds:[taskSem]
		call	ThreadVSem			; release access
		jmp	exit

noLogin:
	;
	; send notification
	;   XXX - This use to send PPP_STATUS_DIALING notification
	;         but it was done WAY too early.  It is now sent from
	;	  PPPModemOpen once the initialization of the modem
	;	  has been successful; directly BEFORE dialing.
	;		  --JimG 8/23/99
	;
		call	PPPDeviceOpen			; ax = error
		jc	error

		BitSet	ds:[clientInfo].PCI_status, CS_DEVICE_OPENED
	;
	; Begin PPP negotiation phase, releasing access first.
	;
		mov	ds:[clientInfo].PCI_linkState, PLS_NEGOTIATING

	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_CONNECTING
		call	PPPSendNotice
		pop	bp
		
		mov	bx, ds:[taskSem]
		call	ThreadVSem			; release access

		call	PPPBeginNegotiations
		jmp	exit
error:
	;
	; Store error, reset client timer, accpnt, status and state.
	;
		tst	al
		jnz	storeIt
		mov	al, SDE_LINK_OPEN_FAILED
storeIt:
		mov	ds:[clientInfo].PCI_error, ax
interrupted:
		mov_tr	dx, ax				; dx = SocketDrError
	;
	; Unlock access point if used.
	;
		mov	ax, ds:[clientInfo].PCI_accpnt
		tst	ax
		jz	resetStuff

		call	PPPCleanupAccessInfo
		call	AccessPointUnlock

		clr	ax
		mov	ds:[clientInfo].PCI_accpnt, ax
resetStuff:
		mov	ds:[clientInfo].PCI_timer, ax
		mov	ds:[clientInfo].PCI_linkState, PLS_CLOSED

		mov	cl, ds:[clientInfo].PCI_status
		BitClr	ds:[clientInfo].PCI_status, CS_BLOCKED

		mov	bx, ds:[taskSem]
		call	ThreadVSem			; release access
	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_CLOSED
		call	PPPSendNotice
		pop	bp

	;
	; Wake client if blocked, else notify client.
	;				
		test	cl, mask CS_BLOCKED
		jz	notify

		mov	bx, ds:[clientInfo].PCI_mutex
		call	ThreadVSem			; wake client
		jmp	exit
notify:
		mov	di, SCO_CONNECT_FAILED
		call	PPPNotifyLinkClosed
exit:
		ret
PPPOpenLink	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPCloseLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the PPP link in an orderly manner.  (No fair just
		closing the physical connection.  Must terminate link
		with consent of peer.)

CALLED BY:	MSG_PPP_CLOSE_LINK
PASS: 		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPCloseLink	method dynamic PPPProcessClass, 
					MSG_PPP_CLOSE_LINK
		mov	bx, handle dgroup
		call	MemDerefDS		; setup dgroup for C

		clr	ax
		push	ax			; pass unit of 0
		call	lcp_close

	;
	; send notification
	;   XXX - This use to send PPP_STATUS_CLOSED notification
	;         but it was done WAY too early.  It is also sent from
	;	  PPPLINKCLOSED, which is more appropriate, once the 
	;	  closing has completed.  This makes the UI more
	;	  accurate.
	;		  --JimG 8/23/99
	;
		
		ret
PPPCloseLink	endm

ConnectCode		ends

PPPCODE			segment public 'CODE'


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSendFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the buffer's data enclosed in a PPP frame.

CALLED BY:	MSG_PPP_SEND_FRAME
PASS: 		dx:bp	= optr of buffer
		cx	= size of data in buffer

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		Set up dgroup in DS for C code

		Lock down buffer and store optr of buffer in the header
		so C code can simply deal with a fptr. 

		Pass locked buffer to ppp_ip_output

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSendFrame	method dynamic PPPProcessClass, 
					MSG_PPP_SEND_FRAME

		mov	bx, dx
		call	HugeLMemLock
		mov	es, ax				
		mov	di, es:[bp]		; es:di = PppPacketHeader
		movdw	es:[di].PPH_optr, dxbp

EC <		cmp	cx, es:[di].PPH_common.PH_dataSize		>
EC <		ERROR_NE PPP_BAD_DATA_SIZE				>
EC <		cmp	es:[di].PPH_common.PH_dataOffset, PPP_MIN_HDR_SIZE>
EC <		ERROR_B PPP_BAD_DATA_OFFSET				>

		mov	bx, handle dgroup
		call	MemDerefDS			; setup dgroup for C
		push	ds:[clientInfo].PCI_unit	; pass unit
		pushdw	esdi				; pass packet
		call	ppp_ip_output

		ret
PPPSendFrame	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPHandleDataNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data notification handler for incoming data.

CALLED BY:	MSG_PPP_HANDLE_DATA_NOTIFICATION
PASS:		nothing

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		Lock input buffer

		Read all of the data or no further notifications will 
		arrive for remaining data.  If too much to fit in buffer,
		read again after processing some of the data.

		Data is read to the input buffer.
		Pass input buffer to PPPProcessInput for processing.

		Safe to reset buffer when full because data is processed
		each time through the loop.

		If read a full buffer size, try to read again just to make
		sure we get all the data.

		Unlock input buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95   	Initial version
	jwu	7/19/96		Manual login version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPHandleDataNotification	method dynamic PPPProcessClass, 
					MSG_PPP_HANDLE_DATA_NOTIFICATION
	;
	; Make sure device is still open.  This message may have been
	; in queue before device was closed.
	;
		mov	bx, handle dgroup
		call	MemDerefES
		test	es:[clientInfo].PCI_status, mask CS_DEVICE_OPENED
		je	exit

	;
	; If in manual login phase, don't touch the input.  It belongs
	; to Term.
	;
		mov	bx, es:[taskSem]
		call	ThreadPSem
		cmp	es:[clientInfo].PCI_linkState, PLS_LOGIN
		call	ThreadVSem		
		je	exit

		mov	bx, es:[inputBuffer]
		call	MemLock
		mov	ds, ax
		clr	si			; ds:si = place for data
readLoop:
	;
	; Read as much as will fit in the buffer.
	;
if _PENELOPE
		mov	bx, es:[padUpStream]
else
		mov	bx, es:[port]
endif
		mov	cx, PPP_INPUT_BUFFER_SIZE
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_READ
if _PENELOPE
		tstdw	es:[padStreamStrategy]
		jnz 	streamValid
		clr	cx
		jmp	done
streamValid:
		call	es:[padStreamStrategy]	; cx = # bytes read
else
		call	es:[serialStrategy]	; cx = # bytes read
endif
		jcxz	done

	;
	; Process input data.  Then try to read more if we read an 
	; entire buffer, in case there is more data that couldn't fit
	; in the earlier read.
	;
		push	cx, si, es, ds		; may be destroyed by C
		pushdw	dssi			; pass pointer to input
		push	cx			; pass size of input
		segmov	ds, es, cx		; ds = dgroup for C
		call	PPPProcessInput
		pop	cx, si, es, ds

		cmp	cx, PPP_INPUT_BUFFER_SIZE
		je	readLoop
done:
		mov	bx, es:[inputBuffer]
		call	MemUnlock
exit:
		ret
PPPHandleDataNotification	endm

PPPCODE			ends

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPHandlePadStreamStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle error generated by PAD (via RLP) to upStream.

CALLED BY:	MSG_PPP_HANDLE_PAD_STREAM_STATUS
PASS:		*ds:si	= PPPProcessClass object
		ds:di	= PPPProcessClass instance data
		ds:bx	= PPPProcessClass object (same as *ds:si)
		es 	= segment of PPPProcessClass
		ax	= message #
RETURN:		Nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Initially CarrierDetect bit (0x0040) is 1.
		In PPP-PAD connected mode, if the CarrierDetect
		bit toggles from 0 to 1, then disconnect with ATH. 

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kkee    	6/30/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPHandlePadStreamStatus	method dynamic PPPProcessClass, 
					MSG_PPP_HANDLE_PAD_STREAM_STATUS
	.enter
		mov	bx, handle dgroup
		call	MemDerefDS

		mov	bx, ds:[padUpStream]
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_GET_ERROR
		tstdw	ds:[padStreamStrategy]
		jz	exit
		call	ds:[padStreamStrategy]	; ax = error token
	
	;
	; Deal with the error code in ax. If connected to PAD and 
	; carrier detect bit toggles from 0 to 1, then disconnect.
	;
		cmp	ds:[padResponse], PAD_AT_CONNECT
		jne	exit
		and	ds:[padStatus], 0x0040
		jnz	keepAlive
		and	ax, 0x0040
		jnz	shutDown
keepAlive:	
		mov	ds:[padStatus], ax	; for future toggle check
		jmp	exit
shutDown:
	;
	; Carrier detect has toggled from 0 to 1 while connected.
	;
		call	PADCallTerminated
exit:
	.leave
	ret
PPPHandlePadStreamStatus	endm


endif  ; if _PENELOPE


if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPPClientDataProto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by PAD to send data responses to PPP. This message
		is sent by PAD and serviced by PPPGetPADResponse.

CALLED BY:	MSG_CLIENT_DATA_PROTO

PASS:		*ds:si	= PPPProcessClass object
		ds:di	= PPPProcessClass instance data
		ds:bx	= PPPProcessClass object (same as *ds:si)
		es 	= segment of PPPProcessClass
		ax	= message #

		cx	= atTranslationType_e
		dx	= dataBlock, null-terminated string. NULL if no data.

RETURN:		Nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		All state changes between PPP and PAD *must* happen here.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPPClientDataProto	method dynamic PPPProcessClass, 
					MSG_CLIENT_DATA_PROTO
	.enter
		tst	dx	
		jz	nodata
		mov	bx, dx
		call 	MemFree				; no use for data.

nodata:
		mov	bx, handle dgroup
		call	MemDerefDS

	;
	; Save PAD response code and signal done. padSignalDone is
	; used by PPPGetPADGetResponse.
	;
		mov	ds:[padResponse], cx
		mov	ds:[padSignalDone], -1		; TRUE

	;
	; The only good return codes we should be looking for are
	; PAD_AT_OK, PAD_AT_CONNECT, and PAD_AT_RING. Anything else
	; is error and we should shut down.
	;
		cmp 	cx, PAD_AT_RING
		jbe	exit
		mov	ds:[padAbnormalDisconnect], -1

	;
	; Set link state closed and report error to client.
	;
		call	PADCallTerminated
exit:
	.leave
	ret
PPPPClientDataProto	endm

endif  ; if _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPPClientConnectProto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by PAD to send established data-link to PPP. This 
		message	is sent by PAD and serviced by PPPGetPADResponse.

CALLED BY:	MSG_CLIENT_CONNECT_PROTO

PASS:		*ds:si	= PPPProcessClass object
		ds:di	= PPPProcessClass instance data
		ds:bx	= PPPProcessClass object (same as *ds:si)
		es 	= segment of PPPProcessClass
		ax	= message #

		cx	= GeodeHandle, stream handle from GeodeUseDriver
		dx	= StreamToken for upStream
		bp	= StreamToken for dnStream
		
RETURN:		Nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Save the strategy routines of PAD's stream driver.

		Save upStream and dnStream. dnStream has been initialized
		by PAD.

		Initialize upStream. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPPClientConnectProto	method dynamic PPPProcessClass, 
					MSG_CLIENT_CONNECT_PROTO
	.enter
EC <		push	bx						>
EC <		mov	bx, cx						>
EC <		call	ECCheckGeodeHandle				>
EC <		pop	bx						>

		mov	bx, handle dgroup
		call	MemDerefES

	;	
	; We must not connect unless we are in PLS_OPENING state.
	; In fact, we should not get this message at all if our state
	; is not PLS_OPENING.
	;
		cmp	es:[clientInfo].PCI_linkState, PLS_OPENING
EC <		ERROR_NE PPP_PAD_CONNECTING_WHILE_NOT_OPENING          >
		jne	exit

		mov	es:[padStreamDr], cx
		mov	bx, cx
		call	GeodeInfoDriver

		movdw	es:[padStreamStrategy], ds:[si].DIS_strategy, ax
		mov	es:[padUpStream], dx	
		mov	es:[padDnStream], bp

	;
	; Setup data notification with upStream.
	; dnStream has been initialized by PAD.
	;	
		mov	ax, StreamNotifyType <1, SNE_DATA, SNM_MESSAGE>
		mov	bx, es:[padUpStream]
		mov	cx, es:[pppThread]
		mov	bp, MSG_PPP_HANDLE_DATA_NOTIFICATION
		mov	di, DR_STREAM_SET_NOTIFY
		call	es:[padStreamStrategy]

	;
	; Setup error notification with upStream. Upstream errors are 
	; generated by RLP (Radio Link Protocol).
	;
		mov	ax, StreamNotifyType <1, SNE_ERROR, SNM_MESSAGE>
		mov	bx, es:[padUpStream]
		mov 	cx, es:[pppThread]
		mov	bp, MSG_PPP_HANDLE_PAD_STREAM_STATUS
		mov	di, DR_STREAM_SET_NOTIFY
		call	es:[padStreamStrategy]

exit:			
	.leave
	ret
PPPPClientConnectProto	endm

endif  ; if _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPPClientErrorProto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by PAD to send error codes to PPP. This message is
 		sent by PAD and serviced by PPPGetPADResponse.

CALLED BY:	MSG_CLIENT_ERROR_PROTO

PASS:		*ds:si	= PPPProcessClass object
		ds:di	= PPPProcessClass instance data
		ds:bx	= PPPProcessClass object (same as *ds:si)
		es 	= segment of PPPProcessClass
		ax	= message #

		cx:dx	= one of ERR_PAD_... error codes.

RETURN:		dgroup::padSignalDone = 0 if no error.
		else
		dgroup::padSignalDone = -1 if error
			dgroup::padResponse = atTranslationType_e
				(PAD_AT_OK,
				 PAD_AT_ERROR)

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		PAD is shutting us down. We must unregister from PAD.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPPClientErrorProto	method dynamic PPPProcessClass, 
					MSG_CLIENT_ERROR_PROTO
	.enter
		mov	bx, handle dgroup
		call	MemDerefDS

		tst	dx	; as cx is always 0.
		jz	exit  	; no error

	;
	; Convert error code in cx:dx to ds:[padResponse].
	;
		mov	ds:[padSignalDone], -1		; a final state
		mov	ds:[padResponse], PAD_AT_ERROR
		mov	ds:[padAbnormalDisconnect], -1

	;
	; Set link state closed and report error to client.
	;
		call	PADCallTerminated
exit:
	.leave
	ret
PPPPClientErrorProto	endm

endif ; if _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPPClientModeProto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does nothing as this message is never sent to PPP by
		PAD as PAD only send it to System Bus Handler (sbh).

CALLED BY:	MSG_CLIENT_MODE_PROTO
PASS:		*ds:si	= PPPProcessClass object
		ds:di	= PPPProcessClass instance data
		ds:bx	= PPPProcessClass object (same as *ds:si)
		es 	= segment of PPPProcessClass
		ax	= message #
	
		cx	= sbgMsg, System Bus Handler message.

RETURN:		Nothing
DESTROYED:	Nothing
SIDE EFFECTS:	Nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kkee    	3/ 5/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPPClientModeProto	method dynamic PPPProcessClass, 
					MSG_CLIENT_MODE_PROTO
	ret
PPPPClientModeProto	endm

endif  ; if _PENELOPE

IDialupCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPIDGetBaudRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	PPPStrategy

PASS:		nothing

RETURN:		ax = baud rate

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	mzhu	11/30/98		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPIDGetBaudRate	proc	far
		uses	es, ds, di, bx
		.enter

		mov	bx, handle dgroup
		call	MemDerefES

		mov	ax, es:[baudRate]
		clr	dx

		.leave
		ret
PPPIDGetBaudRate	endp

IDialupCode		ends

COMMONCODE		segment public 'CODE'


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPIDGetBytesSent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	PPPStrategy

PASS:		

RETURN:		dxax = bytes sent

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	mzhu	11/30/98		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPIDGetBytesSent	proc	far
		uses	es, bx, cx, ds
		.enter

		mov	bx, handle dgroup
		call	MemDerefES

		movdw	dxax, es:[bytesSent]

		.leave
		ret
PPPIDGetBytesSent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPIDGetBytesReceived
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	PPPStrategy

PASS:		nothing

RETURN:		dxax = bytes received

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	mzhu	11/30/98		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPIDGetBytesReceived	proc	far
		uses	es, bx, cx, ds
		.enter

		mov	bx, handle dgroup
		call	MemDerefES

		movdw	dxax, es:[bytesReceived]

		.leave
		ret
PPPIDGetBytesReceived	endp

COMMONCODE		ends

IDialupCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPIDRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	PPPStrategy

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	mzhu	11/30/98		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPIDRegister	proc	far
		uses	es, bx
		.enter

		mov	bx, handle dgroup
		call	MemDerefES

		mov	es:[idRegistered], -1

		.leave
		ret
PPPIDRegister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPIDUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	PPPStrategy

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	mzhu	11/30/98		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPIDUnregister	proc	far
		uses	es, bx, ax
		.enter

		mov	bx, handle dgroup
		call	MemDerefES

		mov	bx, es:[taskSem]
		call	ThreadPSem			; destroys AX
		
		mov	es:[idRegistered], 0

		call	ThreadVSem

		.leave
		ret
PPPIDUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPIDForceDisconnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force a disconnect.  The most useful reason for this
		function's existence is to abort a dial in progress.

CALLED BY:	PPPStrategy
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		Calling PPPCallTerminated doesn't always cause PPP to
		close (particularly if no connection is established).
		Seems to work once it is established, though.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/08/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPIDForceDisconnect	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
		mov	bx, handle dgroup
		call	MemDerefDS
		
		cmp	ds:[clientInfo].PCI_linkState, PLS_CLOSING
		jbe	done

		cmp	ds:[clientInfo].PCI_linkState, PLS_OPENING ;dialing
		je	slamModem

terminateCall:
		clr	ax
		push	ax
		call	PPPCallTerminated

done:
		.leave
		ret

slamModem:
	; Tell the modem driver to abort the dial.  If it could not be
	; done because the connection has already been made, then
	; revert to having PPP terminate the call.
	;
		tst	ds:[modemStrategy].handle
		jz	done

		mov	di, DR_MODEM_ABORT_DIAL
		call	ds:[modemStrategy]
		jc	terminateCall
		jmp	done
PPPIDForceDisconnect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPLaunchIDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch internet dialup application.

CALLED BY:	PPPOpenDevice

PASS:		nothing

RETURN:		carry set if error

DESTROYED:	ax, cx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	12/04/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPLaunchIDial		proc	far
		uses	dx, si, es, ss, bx, cx, dx, di, ds
if DBCS_PCGEOS
idTokenString	local	5 dup (TCHAR)  ; 4 token chars plus null
endif
idToken		local	GeodeToken
	.enter
		push	bp
		
	; check if it's already launched
; "test xxx, 0" always gives you zero, so it will never jump to done, which
; is not what you want.  --- AY
;;;		test	ds:[idcbfunc], 0

		mov	bx, handle dgroup
		call	MemDerefDS

	;		tstdw	ds:[idcbfunc]
	;		jnz	exit

	; get the geode token from ini file

		segmov	es, ss, bx			; es:di = buffer
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov_tr	cx, ax
		mov	dx, ds:[idialTokenKey]		; cx:dx = key string
		assume	ds:Strings
		mov	si, ds:[pppCategory]
		assume	ds:nothing
if DBCS_PCGEOS
		lea	di, idTokenString		; es:di = token chars
else
		lea	di, idToken			; es:di = GeodeToken
endif
		push	bp
if DBCS_PCGEOS
		mov	bp, InitFileReadFlags \
				<IFCC_INTACT, 0, 0, size idTokenString>
else
		mov	bp, InitFileReadFlags \
				<IFCC_INTACT, 0, 0, size GeodeToken>
endif
		call	InitFileReadString		; carry set if none
		pop	bp

if DBCS_PCGEOS
		lea	di, idToken
		mov	ax, {TCHAR}idTokenString[0*(size TCHAR)]
		mov	es:[di].GT_chars[0], al
		mov	ax, {TCHAR}idTokenString[1*(size TCHAR)]
		mov	es:[di].GT_chars[1], al
		mov	ax, {TCHAR}idTokenString[2*(size TCHAR)]
		mov	es:[di].GT_chars[2], al
		mov	ax, {TCHAR}idTokenString[3*(size TCHAR)]
		mov	es:[di].GT_chars[3], al
endif
		mov	idToken.GT_manufID, MANUFACTURER_ID_GEOWORKS

		jc	done

	; create a default launch block

		mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACPCreateDefaultLaunchBlock	; ^hdx = AppLaunchBlock
		mov	bx, dx

		call	MemLock
		mov	ds, ax
		clr	si
		mov	bx, 0
		call	ThreadAllocSem
		mov	ds:[si].ALB_extraData, bx	; send the semaphore to IDial
		push	bx
		mov	bx, dx
		call	MemUnlock

	; launch the application

		mov	ax, mask IACPCF_FIRST_ONLY or \
			(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
		call	IACPConnect			; bp = IACPConnection
							; ax, bx, cx destroyed

		pop	bx							
		jc	done				; something wrong

	; block here till IDial release the semaphore
		call	ThreadPSem
		call	ThreadFreeSem

		clr	cx
		call	IACPShutdown

done:		
		mov	bx, handle Strings
		call	MemUnlock

exit:
		pop	bp
	.leave
	ret
PPPLaunchIDial		endp

IDialupCode		ends

ConnectCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSendNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a notification

CALLED BY:	
PASS:		bp	- PPPStatus
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	destroys any segment pointing to block

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	12/7/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSendNotice	proc	near
		uses	ax, bx, cx, dx, di, si, ds
		.enter

		mov	bx, handle dgroup
		call	MemDerefDS
	;;
	; add error message to bp
	;
		or	bp, ds:[clientInfo].PCI_error
	;
	; record an event
	;
		mov	ax, MSG_META_NOTIFY
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_PPP_STATUS_NOTIFICATION
		mov	di, mask MF_RECORD
		clr	bx
		clr	si
		call	ObjMessage	; di = event handle
	;
	; dispatch the event
	;
		mov	cx, di
		clr	dx
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_PPP_STATUS_NOTIFICATIONS
		mov	bp, mask GCNLSF_FORCE_QUEUE or mask GCNLSF_SET_STATUS
		call	GCNListSend
		.leave
		ret
PPPSendNotice	endp

ConnectCode		ends





