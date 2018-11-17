COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		
FILE:		pppUtils.asm

AUTHOR:		Jennifer Wu, May 16, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT PPPGetDriverNameFromIni	Look in the ini for an alternative driver
				to load.

    INT PPPLoadSerialDriver	Load the standard serial driver unless the
				INI specifies a different serial driver to
				be loaded.  Get the strategy routine if
				driver loaded.  Store values in dgroup.

    INT PPPGetPortSettings	Find out which port the user wants to use,
				what baud and what type of flow control.

    INT PPPCreateThread		Spawn the thread for the PPP driver.

    INT PPPDestroyThread	Destroy the PPP thread.

    INT PPPStartTimer		Start the PPP timer.

    INT PPPStopTimer		Stop the PPP timer.

    INT PPPGetIPClient		Load TCP and register with it.  Tell TCP
				the link has been opened.  Store any
				information in dgroup.

    INT PPPLoadTCPDriver	Load the TCP driver.

    INT PPPRegisterWithTCP	Register with the TCP driver by adding
				ourselves as a domain.  Store registration
				information.

    none PPPALLOCBUFFER		Allocate a data buffer of the requested
				size with addition space for the packet
				header.

    none PPPFREEBUFFER		Free the data buffer.

    none PPPGETBUFFEROPTR	Get the data buffer's optr.

    none PPPFREEBLOCK		Free the block if the handle is non-zero.

    none PPPGETPEERPASSWD	Get peer's password.

    INT PPPCheckForInterrupt	Check if the connect request has been
				interrupted.

    INT PPPSetAccessInfo	Look up the local IP address, the username
				and the secret from the access point
				database for the entry specified in the
				link address.

    INT PPPSetAccessInfoAfterLogin
				Looks up any information that might be
				(re)set by the login application, after it
				has completed.

    INT PPPCleanupAccessInfo	Removes any temporary access point
				information when the link is closed

    INT PPPSetAccessIPAddr	Get the local IP address for this access
				point.  If found, set it as our address but
				allow it to be overridden if the peer
				suggests a different one.

    INT PPPParseDecimalAddr	Parse an IP address string in x.x.x.x
				format into a binary IP address.

    INT PPPSetAccessUsername	Get username from access point database and
				set it.

    INT PPPSetAccessSecret	Get the user's secret from access point
				database and set it.

    INT PPPQuerySecret		Put up a dialog asking user to enter the
				password for the connection.  Get the
				password and set it before returning.

    INT PPPBeginNegotiations	Start PPP timer and activate LCP.

    none PPPDELIVERPACKET	Deliver packet of data to client.

    none PPPLINKOPENED		Inform the client that the link is now
				open.

    INT PPPLINKCLOSED		Inform the client that the link has closed.

    INT PPPNotifyLinkOpened	Notify client the PPP link has been opened.

    INT PPPNotifyLinkClosed	Notify client the PPP link is closed.

    none PPPDEVICEWRITE		Write output data to device driver.

    INT PPPDEVICECLOSE		Close the physical connection.  Returns
				zero if close was not performed.

    INT PPPDeviceOpen		Open the physical connection.

    INT PPPSerialOpen		Open the serial connection and set up data
				notification.

    INT PPPModemOpen		Establish the modem connection and setup
				data notification.

    INT PPPConfigurePort	Configure serial port's baud rate, flow
				control, parity, extra stop bit, length.

    INT PPPSetPortNotify	Set up data notification for the port.

    INT PPPLoadModemDriver	Load the modem driver and get its strategy
				routine.  Store values in dgroup.

    INT PPPResetModem		Reset the modem.

    INT PPPStandardModemInit	Send the standard init string to the modem.

    INT PPPInitV42Compression	Enable V.42bis compression if used.

    INT PPPInitializeModem	Look up modem initialization string in
				access point database and initialize modem
				with it.

    INT PPPCloseAndUnloadModem	Close the modem port and unload the modem
				driver. Hangup first if caller wants us to.

    MTD MSG_PPP_PROMPT_PASSWORD	Put up a dialog to query the user for the
				password. NOTE: This MUST be called by the
				UI thread created by PPP.

    INT PPPStartPasswordTimer	Start the timer which will bring down the
				password dialog if the user does not
				respond in the given amount of time.

    INT PPPCheckAccpnt		Verify the access point ID type is either
				APT_INTERNET or APT_APP_LOCAL.

    INT PPPNotifyMediumConnected
				Send a system notification about the medium
				being connected.

    INT PPPNotifyMediumDisconnected
				Send a system notification about the medium
				no longer being connected.

    INT PPPGetLoginMode		Get the login mode for the access point.

    INT PPPLoginCallback	Callback routine for Term to have PPP check
				input data and for Term to notify PPP of a
				terminated/completed login process.

    INT PPPScanForPPPData	Scans input stream for PPP signature bytes
				7E, FF, 03.  If found, sends it to input
				thread for handling, and starts the
				negotiation phase.

    INT PPPStartManualLogin	Begin the manual login process.

    INT PPPInitManualLogin	Tell login app to initialize itself.

    INT PPPStopManualLogin	Send a notification to Term to stop the
				login process.

    MTD MSG_PPP_MANUAL_LOGIN_INIT_COMPLETE
				Sent by manual login app when it's finished
				initializing itself

    MTD MSG_PPP_MANUAL_LOGIN_COMPLETE
				Advance PPP to negotations stage if login
				has been completed successfully.  Else
				terminate the link opening process.

    INT PPPRegisterECIAll	Register for ECI notification of the
				following: ECI_CALL_CREATE_STATUS
				ECI_CALL_RELEASE_STATUS
				ECI_CALL_TERMINATE_STATUS

    INT PPPRegisterECIEnd	Register for ECI notification of the
				following: ECI_CALL_RELEASE_STATUS
				ECI_CALL_TERMINATE_STATUS

    INT PPPRegisterECICommon	Register for ECI notification of call
				termination. ECI_CALL_RELEASE_STATUS is
				received when mobile user ends the call.
				ECI_CALL_TERMINATE_STATUS is received when
				the remote user or network ends the call.

    INT PPPUnregisterECI	Unregister from ECI notifications.

    INT PPPECICallback		Callback routine for ECI notifications.

    MTD MSG_PPP_ECI_NOTIFICATION
				Process the ECI notification.

    INT PPPClearBlacklist	Send an ECI message to clear the blacklist.

    INT PPPLogCallStart		Log the start of a call with Contact Log.

    INT PPPLogCallEnd		Log the end of the call with Contact Log if
				the start of the call was logged.  Reset
				LogEntry values for next call.

Medium notificaions:
	PPPNotifyMediumConnected
	PPPNotifyMediumDisconnected

Manual login code:
	PPPGetLoginMode
	PPPLoginCallback
	PPPStartManualLogin
	PPPStopManualLogin
	PPPManualLoginComplete

Responder only:
	PPPRegisterECIAll	Registers for create, release & terminate
				status.
	PPPRegisterECIEnd	Registers for release & terminate status.
	PPPRegisterECICommon
	PPPUnregisterECI		
	PPPECICallback
	PPPECINotification

	PPPClearBlacklist

	PPPLogCallStart		Log start of call with Contact Log
	PPPLogCallEnd		Log end of call with Contact Log

Penelope only:
	PPPPADOpen		
	PPPLoadPAD
	PPPUnloadPAD
	PPPRegisterWithPAD
	PPPUnregisterFromPAD
	PPPSetPADCapability
	PPPConnectWithPAD
	PPPDisconnectFromPAD
	PPPGetPADResponse

	PPPStrAllocCopy
	PPPStrAllocStrcat

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/16/95		Initial revision

DESCRIPTION:
	Utility routines for PPP driver to get its work done.

	$Id: pppUtils.asm,v 1.67 98/08/14 10:35:07 jwu Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;		Ini File Strings (have to be SBCS)
;---------------------------------------------------------------------------
Strings	segment	lmem LMEM_TYPE_GENERAL

	pppCategory	chunk.char "ppp",0
			localize not
	portKey		chunk.char "port",0
			localize not
	baudKey		chunk.char "baud",0
			localize not
	softKey		chunk.char "xonxoff",0
			localize not
	hardKey		chunk.char "rtscts",0
			localize not
	portDriverKey	chunk.char "portDriver",0
			localize not
	tcpDriverKey	chunk.char "tcpDriver",0
			localize not

	svcCategory	chunk.char "services",0
			localize not
	modemInitKey	chunk.char "modemInit",0
			localize not
	v42bisKey	chunk.char "v42bis",0
			localize not
	dialtoneKey	chunk.char "dialtone",0
			localize not

	pppAuthCategory	chunk.char "pppSecrets",0
			localize not

	accpntCategory	chunk.char "accpnt",0
			localize not
	activeKey	chunk.char "active0",0
			localize not
	idialTokenKey	chunk.char "idialToken", 0
			localize not

if not _PENELOPE

	manualLoginCategory	chunk.char LOGIN_APP_CAT_STRING, 0
			localize not
	useManualLoginKey	chunk.char USE_LOGIN_APP_KEY_STRING, 0
			localize not
	manualLoginKey		chunk.char LOGIN_APP_KEY_STRING, 0
			localize not

endif ; not _PENELOPE

if _PENELOPE
;---------------------------------------------------------------------------
;		PAD Command Strings (have to be SBCS)
;---------------------------------------------------------------------------

	padATD		chunk.char "ATD",0		; dial
				localize not
	padATH		chunk.char "ATH",0		; hangup
				localize not
	padOffline	chunk.char "+++",0		; go offline
				localize not
	padOnline	chunk.char "ATO",0		; go online
				localize not

endif ; _PENELOPE

Strings	ends

InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPGetDriverNameFromIni
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look in the ini for an alternative driver to load.

CALLED BY:	PPPLoadSerialDriver
		PPPLoadTcpDriver

PASS:		si	= offset key string in Strings resource
		ss:di	= buffer on stack for filename

RETURN:		carry set if not found
		else
		ds:si = driver name

DESTROYED:	ds, si if not returned

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/19/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPGetDriverNameFromIniFar	proc	far
		call	PPPGetDriverNameFromIni
		ret
PPPGetDriverNameFromIniFar	endp

PPPGetDriverNameFromIni	proc	near
		uses	ax, bx, cx, dx, di, bp, es
		.enter

		segmov	es, ss, bx			; es:di = buffer
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov_tr	cx, ax
		mov	dx, ds:[si]			; cx:dx = key string
		assume	ds:Strings
		mov	si, ds:[idialTokenKey]
		assume	ds:nothing
		mov	bp, InitFileReadFlags \
				<IFCC_INTACT, 0, 0, FILE_LONGNAME_BUFFER_SIZE>
		call	InitFileReadString		; carry set if none

		segmov	ds, es, si
		mov	si, di				; ds:si = driver name

		mov	bx, handle Strings
		call	MemUnlock

		.leave
		ret
PPPGetDriverNameFromIni	endp

if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPLoadSerialDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the standard serial driver unless the INI specifies
		a different serial driver to be loaded.  Get the 
		strategy routine if driver loaded.  Store values in 
		dgroup.

CALLED BY:	PPPInit

PASS:		ds	= dgroup

RETURN:		carry set if error

DESTROYED:	ax, bx, cx, di, si, es (allowed)

PSEUDO CODE/STRATEGY:
		Check the ini file for a portDriver entry under the PPP
		category.  If no driver name found, then load the standard
		serial driver.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString	serialName, <"serialec.geo", 0>		>
NEC<LocalDefNLString	serialName, <"serial.geo", 0>		>

PPPLoadSerialDriver	proc	near
		uses	ds
driverName		local	FileLongName
		.enter
	;
	; See if there is a special driver listed in the INI file.
	; If not, use standard serial driver.
	;
		segmov	es, ds, di			; es = dgroup
		mov	si, offset portDriverKey
		lea	di, driverName
		call	PPPGetDriverNameFromIni
		jnc	loadDriver			; got driver?

		segmov	ds, cs, si
		mov	si, offset serialName		; ds:si = driver name
loadDriver:
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		jc	done

		mov	ax, SERIAL_PROTO_MAJOR
		mov	bx, SERIAL_PROTO_MINOR
		call	GeodeUseDriver
EC <		WARNING_C PPP_COULD_NOT_LOAD_SERIAL_DRIVER		>
		jc	done

		mov	es:[serialDr], bx
	;
	; Get the strategy routine.
	;
		call	GeodeInfoDriver
		movdw	es:[serialStrategy], ds:[si].DIS_strategy, ax
		clc
done: 
		call	FilePopDir			; preserves flags

		.leave
		ret
PPPLoadSerialDriver	endp

endif ; not _PENELOPE


if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPGetPortSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out which port the user wants to use, what baud and
		what type of flow control.

CALLED BY:	PPPInit	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si, es (allowed)

PSEUDO CODE/STRATEGY:
		Read entries from INI file and store values in dgroup.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPGetPortSettings	proc	near
		uses	ds
		.enter
	;
	; Find out which port to use.
	;
		segmov	es, ds, bx
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	cx, ax
		assume	ds:Strings
		mov	dx, ds:[portKey]		; cx:dx = key
		mov	si, ds:[pppCategory]		; ds:si = category
		assume	ds:nothing
		call	InitFileReadInteger		; ax = port
		jc	getBaud

		mov	es:[port], ax
getBaud:
	;
	; Find out what baud rate to use.
	;
		assume	ds:Strings
		mov	dx, ds:[baudKey]
		assume	ds:nothing
		call	InitFileReadInteger
		jc	getSoft

		mov	es:[baud], ax
getSoft:
	; 
	; Use software flow control if user so desires.  Set software
	; settings without trashing hardware settings in case default 
	; flow control is used.
	;
		assume	ds:Strings
		mov	dx, ds:[softKey]
		assume	ds:nothing
		call	InitFileReadBoolean	; ax = -1 if TRUE, 0 if FALSE
		jc	getHard

		andnf	al, mask SFC_SOFTWARE
		ornf	es:[flowCtrl], al	
getHard:
	;
	; Use hardware flow control if user so desires.
	;
		assume 	ds:Strings
		mov	dx, ds:[hardKey]
		assume	ds:nothing
		call	InitFileReadBoolean	; ax = -1 if TRUE, 0 if FALSE
		jc	done
	
		andnf	al, mask SFC_HARDWARE
		ornf	es:[flowCtrl], al	
done:
		mov	bx, handle Strings
		call	MemUnlock

		.leave
		ret
PPPGetPortSettings	endp

endif;  if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPCreateThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spawn the thread for the PPP driver.

CALLED BY:	PPPRegister
		PPPMediumActivated

PASS:		ds	= dgroup

RETURN:		carry set if error 
			di	= SDE_INSUFFICIENT_MEMORY
		else carry clear
			di	= destroyed

DESTROYED:	ax, bx, cx  (allowed)

PSEUDO CODE/STRATEGY:
		Create thread with us as the owner.
		Save handle of thread in dgroup.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPCreateThread	proc	far
		uses	bp, si
		.enter
	;
	; Thread should not exist yet, but just in case...
	;
		tst_clc	ds:[pppThread]
		jnz	exit

		call	ImInfoInputProcess	; use input process as parent
		mov	si, handle 0		; we own thread
		mov	bp, PPP_STACK_SIZE
		mov	cx, segment PPPProcessClass
		mov	dx, offset PPPProcessClass
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER
		mov	di, mask MF_CALL
		call	ObjMessage		

		mov	di, SDE_INSUFFICIENT_MEMORY
		jc	exit
    ;
    ; Increase the thread's base priority.
    ;
        xchg ax, bx
        mov ah, mask TMF_BASE_PRIO
        mov al, PRIORITY_HIGH
        call ThreadModify

		mov	ds:[pppThread], bx
		
exit:
		.leave
		ret
PPPCreateThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPDestroyThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the PPP thread.

CALLED BY:	PPPUnregister
		PPPMediumActivated

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	bx (allowed)

STRATEGY:
		Must use MF_CALL for detach message to get detach
		handler to check registered bit before returning.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPDestroyThread	proc	far
		uses	ax, cx, dx, bp, di
		.enter

		clr	bx
		xchg	bx, ds:[pppThread]
		clr	cx, dx, bp			; no ack
		mov	ax, MSG_META_DETACH
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
PPPDestroyThread	endp

InitCode		ends

ConnectCode		segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStartTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the PPP timer.

CALLED BY:	PPPOpenLink

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp (allowed)

PSEUDO CODE/STRATEGY:
		Start the continual timer 
		save timer handle in dgroup

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStartTimer	proc	near

		mov	bx, ds:[pppThread]
		mov	al, TIMER_EVENT_CONTINUAL
		mov	cx, PPP_TIMEOUT_INTERVAL	; first interval
		mov	di, cx				; same interval always
		mov	dx, MSG_PPP_TIMEOUT
		mov	bp, handle 0			; we own it
		call	TimerStartSetOwner

		mov	ds:[timerHandle], bx

		ret
PPPStartTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStopTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the PPP timer.  

CALLED BY:	PPPLINKCLOSED

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx (allowed)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStopTimer	proc	near

		clr	bx, ax			; continual timers use ID 0
		xchg	bx, ds:[timerHandle]
		call	TimerStop
		ret
PPPStopTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPGetIPClient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load TCP and register with it.  Tell TCP the link has 
 		been opened.  Store any information in dgroup.

CALLED BY:	PPPLinkOpened

PASS:		ds	= dgroup

RETURN:		carry set if error 

DESTROYED:	ax, dx, di, si, es (allowed)

PSEUDO CODE/STRATEGY:
		load tcp driver
		if failed, exit

		register with tcp driver
		if successful, store registration information

		unload tcp driver to remove our reference to it
		if registration failed, return carry
 
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/17/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPGetIPClient	proc	near
		uses	bx, cx
drvrHandle	local	hptr
		.enter

		call	PPPLoadTCPDriver	; cxdx = client entry point
						; bx = driver handle
		jc	exit

		mov	drvrHandle, bx
		call	PPPRegisterWithTCP	; bx = domain handle

		lahf
		mov	bx, drvrHandle
		call	GeodeFreeDriver		
		sahf
exit:
		.leave
		ret
PPPGetIPClient	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPLoadTCPDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the TCP driver.

CALLED BY:	PPPGetIPClient

PASS:		nothing

RETURN:		carry clear if successful
		bx	= driver handle
		cxdx	= TCP's client entry point
		else
		carry set

DESTROYED:	bx, cx, dx if not returned
		ax, si (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/17/95			Initial version
	jwu	12/18/96		Look in ini for driver name

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString	tcpipName, <"tcpipec.geo", 0>		>
NEC<LocalDefNLString	tcpipName, <"tcpip.geo", 0>		>

LocalDefNLString 	socketString, <"socket", 0>

PPPLoadTCPDriver	proc	near
		uses	ds
driverName	local	FileLongName
		.enter

	;
	; Get driver name from ini.  If none, use regular ol' TCP.
	;
		mov	si, offset tcpDriverKey
		lea	di, driverName
		call	PPPGetDriverNameFromIniFar
		jnc	loadDriver			; got name?

		segmov	ds, cs, si			
		mov	si, offset tcpipName		; ds:si = driver name

loadDriver:
		call	FilePushDir

		push	ds
		mov	bx, SP_SYSTEM
		segmov	ds, cs, si
		mov	dx, offset socketString
		call	FileSetCurrentPath
		pop	ds				; ds:si = driver name
		jc	done

		mov	ax, SOCKET_PROTO_MAJOR
		mov	bx, SOCKET_PROTO_MINOR
		call	GeodeUseDriver			; bx = driver handle
		jc	done				; carry set if failed
	;
	; Get strategy routine.
	;
		call	GeodeInfoDriver			
		movdw	cxdx, ds:[si].SDIS_clientStrat
		clc
done:
		call	FilePopDir			; preserves flags

		.leave
		ret
PPPLoadTCPDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPRegisterWithTCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register with the TCP driver by adding ourselves as a 
		domain.  Store registration information.

CALLED BY:	PPPGetIPClient

PASS:		ds	= dgroup
		cxdx	= TCP's client entry point 

RETURN:		carry clear if registered
		bx	= domain handle
		else
		carry set 

DESTROYED:	bx if not returned
		ax, di, si, es  (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/17/95			Initial version
	PT	7/24/96			DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPRegisterWithTCP	proc	near
		uses	cx, dx, bp
		.enter

		movdw	ds:[clientInfo].PCI_clientEntry, cxdx

		push	ds
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, offset pppDomain
		mov	si, ds:[si]			; ds:si = domain name

		pushdw	cxdx				
		mov	bp, handle 0			; bp = driver handle
		mov	ax, offset clientInfo		; ax = client handle
		mov	bx, segment PPPStrategy
		mov	es, bx
		mov	bx, offset PPPStrategy		; es:bx = PPPStrategy
		mov	cx, (PPP_MIN_HDR_SIZE shl 8) or PPP_MIN_HDR_SIZE
		mov	dl, SDT_LINK
		mov	di, SCO_ADD_DOMAIN
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; bx = domain handle
		mov_tr	ax, bx

		mov	bx, handle Strings
		call	MemUnlock
		pop	ds				; ds = dgroup
		jc	exit

		mov_tr	bx, ax				; bx = domain handle
		mov	ds:[clientInfo].PCI_domain, bx
exit:
		.leave
		ret
PPPRegisterWithTCP	endp

ConnectCode		ends

PPPCODE			segment public 'CODE'


COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPAllocBuffer

DESCRIPTION:	Allocate a data buffer of the requested size with
		addition space for the packet header.

C DECLARATION:	extern PACKET * _far 
		_far _pascal PPPAllocBuffer (word bufSize);

STRATEGY:
		Allocate buffer, leaving room for packet header
		Take advantage of being called from C to have dgroup in DS
		Store optr of buffer in header 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPALLOCBUFFER		proc	far	
		C_GetOneWordArg dx, ax, bx		; dx = size
	;
	; Allocate the buffer, adding space for the header.
	;
		push	di, ds				; save regs
		push	ds:[clientInfo].PCI_domain

		mov	ax, PPP_MIN_HDR_SIZE
		add	ax, dx				; ax = total size

		mov	bx, ds:[hugeLMem]
		mov	cx, HUGELMEM_ALLOC_WAIT_TIME
		call	HugeLMemAllocLock		; ^lax:cx = new buffer
							; ds:di = new buffer
		pop	bx				; bx = domain
		jc	error
	;
	; Fill in packet header information.  Don't include room for the 
	; FCS in the data offset.
	;		
		mov	ds:[di].PPH_common.PH_domain, bx
		mov	ds:[di].PPH_common.PH_dataSize, dx
		mov	ds:[di].PPH_common.PH_dataOffset, PPP_MIN_HDR_SIZE
		movdw	ds:[di].PPH_optr, axcx
		mov	ds:[di].PPH_common.PH_flags, PacketFlags \
							<0, 0, PT_DATAGRAM>

		movdw	dxax, dsdi			; return fptr 
		jmp	exit
error:
		clr	dx, ax
exit:
		pop	di, ds				; restore regs
		ret
PPPALLOCBUFFER		endp
	SetDefaultConvention


COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPFreeBuffer

DESCRIPTION:	Free the data buffer.

C DECLARATION:	extern void _far 
		_far _pascal PPPFreeBuffer(PACKET *p);

STRATEGY:
		Grab optr from header. 
		Unlock buffer
		free buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPFREEBUFFER		proc	far
		C_GetOneDWordArg es, bx, ax, cx	; es:bx = PppPacketHeader

		movdw	axcx, es:[bx].PPH_optr
		mov	bx, ax
		call	HugeLMemUnlock
		call	HugeLMemFree

		ret
PPPFREEBUFFER		endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPGetBufferOptr

DESCRIPTION:	Get the data buffer's optr.

C DECLARATION:	extern optr _far
		_far _pascal PPPGetBufferOptr(PACKET *p);

STRATEGY:
		Grab optr from header. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPGETBUFFEROPTR	proc	far

		C_GetOneDWordArg es, bx, ax, cx	; es:bx = PppPacketHeader

		movdw	dxax, es:[bx].PPH_optr
		ret
PPPGETBUFFEROPTR	endp
	SetDefaultConvention


COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPFreeBlock

DESCRIPTION:	Free the block if the handle is non-zero.

C DECLARATION:	extern void _far 
		_far _pascal PPPFreeBlock(Handle h);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPFREEBLOCK		proc	far
		C_GetOneWordArg	bx, ax, dx		; bx = handle
		tst	bx
		je	exit
		call	MemFree
exit:
		ret
PPPFREEBLOCK		endp
	SetDefaultConvention

PPPCODE		ends

PAPCODE		segment public 'CODE'


COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPGetPeerPasswd

DESCRIPTION:	Get peer's password.

C DECLARATION:	extern void _far
		_far _pascal PPPGetPeerPasswd(unsigned char *peername,
					      Handle *passwd,
					      word *len);

STRATEGY:	Read the string from the INI file.  Category is PPP,
		the peer's name is the key.
		Allocate a block for the passwd and return the handle.
		Return length of passwd if retrieved.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/18/95		Initial Version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPGETPEERPASSWD	proc	far	peername:fptr.char,
					passwd:fptr.hptr,
					len:fptr.word
		uses	si, ds
		.enter

		push	bp
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax 
		assume	ds:Strings
		mov	si, ds:[pppAuthCategory]	; ds:si = category
		assume	ds:nothing
		movdw	cxdx, peername			; cx:dx = key
		clr	bp				; InitFileReadFlags
		call	InitFileReadString		; bx = handle
							; cx = # of chars
		pop	bp				
		jc	done
		jcxz	freeBlk			; block still needs to be freed

		lds	si, passwd
		mov	ds:[si], bx
		lds	si, len
		mov	ds:[si], cx
		jmp	done
freeBlk:
		call	MemFree
done:
		mov	bx, handle Strings
		call	MemUnlock

		.leave
		ret
PPPGETPEERPASSWD	endp
	SetDefaultConvention

PAPCODE			ends

ConnectCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPCheckForInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the connect request has been interrupted.

CALLED BY:	PPPSetAccessSecret

PASS:		ds	= dgroup

RETURN:		carry set if interrupted
			ax	= SDE_INTERRUPTED

DESTROYED:	nothing

NOTES:		Caller MUST NOT have access or will deadlock!
		(If caller has access, simpler for caller to do the
		 check directly.)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPCheckForInterrupt	proc	near
		uses	bx
		.enter

	;
	; Rely on OPENING being greater than CLOSING to clear the
	; carry with the cmp instruction.
	;
		CheckHack <PLS_OPENING gt PLS_CLOSING>

		push	ax
		mov	bx, ds:[taskSem]
		call	ThreadPSem
		cmp	ds:[clientInfo].PCI_linkState, PLS_CLOSING
		call	ThreadVSem			; preserves flags
		pop	ax		

		jne	exit				; carry clear from cmp

		mov	ax, SDE_INTERRUPTED
		stc
exit:
		.leave
		ret
PPPCheckForInterrupt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSetAccessInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look up the local IP address, the username and the secret
		from the access point database for the entry specified
		in the link address.  Also get compression setting.

CALLED BY:	PPPOpenLink

PASS:		dx:bp	= link address
		cx	= size of link address
		ds	= dgroup

RETURN:		carry set if error
		ax	= SpecSocketDrError
				(SSDE_INVALID_ACCPNT,
				 SSDE_CANCEL,
				 SSDE_NO_USERNAME)
			  - or - SocketDrError (SDE_INTERRUPTED)

DESTROYED:	bx, di, si, es (allowed)

PSEUDO CODE/STRATEGY:
		If no address, do nothing.
		If address type not Link ID, do nothing.

		Else, save accpnt ID, get login mode
			look up local IP address, set it in IPCP state info.
			look up user name and set it 
			look up secret and set it

NOTES:
		Caller has access.  Return with access held!

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version
	jwu	7/19/96			Store accpnt and get login mode

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSetAccessInfo	proc	near
		uses 	cx, dx, bp
		.enter
	;
	; If no address or if not a link ID, just return.
	;
		jcxz	good

		mov	es, dx				; es:bp = address
		mov	cl, es:[bp]			; cl = LinkType
		cmp	cl, LT_ID
		jne	good
	;
	; Verify access point ID is valid.
	;
		mov	di, bp				; es:di = address
		inc	di

		mov	ax, es:[di]			; ax = acc pnt ID
		call	PPPCheckAccpnt			; ax = error	
		jc	exit
	;
	; Lock access point to prevent changes to it during connection.
	; Save access point ID for future reference and get login mode.
	;
		call	AccessPointLock
		mov	ds:[clientInfo].PCI_accpnt, ax
		call	PPPGetLoginMode
		jc	exit
	;
	; Release access to give user a chance to cancel now that
	; we're done modifying clientInfo for a while.  
	;
		push	ax
		mov	bx, ds:[taskSem]
		call	ThreadVSem
		pop	ax			
	;
	; Get data compression setting.
	;
		call	PPPSetDataCompress
	;
	; Look up local IP address.  Get username.
	; Look for password only if there is a username.
	;
		call	PPPSetAccessIPAddr		
		call	PPPSetAccessUsername		
		call	PPPSetAccessSecret	; carry set to cancel open
						; ax = error
	;
	; Regain access for caller.  
	;
		pushf
		push	ax
		mov	bx, ds:[taskSem]
		call	ThreadPSem		; destroys carry
		pop	ax					
		popf
		jmp	exit
good:
		clc
exit:
		.leave
		ret
PPPSetAccessInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSetAccessInfoAfterLogin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks up any information that might be (re)set by the
		login application, after it has completed.

CALLED BY:	INTERNAL PPPManualLoginComplete
PASS:		ds	dgroup
RETURN:		carry set if error
		ax	= SpecSocketDrError
				(SSDE_INVALID_ACCPNT,
				 SSDE_CANCEL,
				 SSDE_NO_USERNAME)
			  - or - SocketDrError (SDE_INTERRUPTED)
DESTROYED:	possibly ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	cthomas 	2/21/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSetAccessInfoAfterLogin	proc	near
	uses	bx,cx,dx,si,di,bp,es
	.enter

	;
	; If not using access points, nothing to do.
	;
		mov	ax, ds:[clientInfo].PCI_accpnt
		tst	ax
		jz	exit
	;
	; Look up automatic IP address.
	;
		call	PPPSetAccessIPAddr		
exit:
		clc
	.leave
	ret
PPPSetAccessInfoAfterLogin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPCleanupAccessInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes any temporary access point information
		when the link is closed

CALLED BY:	INTERNAL
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	cthomas 	2/21/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPCleanupAccessInfo	proc	near
	uses	ax, cx, dx
	.enter

	;
	; If not using access points, nothing to do.
	;
		mov	ax, ds:[clientInfo].PCI_accpnt
		tst	ax
		jz	exit
	;
	; Get rid of any automatic IP address.
	;
		clr	cx
		mov	dx, APSP_AUTOMATIC or APSP_ADDRESS
		call	AccessPointDestroyProperty
	;
	; Get rid of any negotiated DNS addresses.
	;
		mov	dx, APSP_AUTOMATIC or APSP_DNS1
		call	AccessPointDestroyProperty
		mov	dx, APSP_AUTOMATIC or APSP_DNS2
		call	AccessPointDestroyProperty
exit:
	.leave
	ret
PPPCleanupAccessInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSetDataCompress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the compression setting for this access point.

CALLED BY:	PPPSetAccessInfo

PASS:		ds	= dgroup
		ax	= access point ID

RETURN:		nothing

DESTROYED:	bx, cx, dx, bp, di, si, es (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/14/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSetDataCompress	proc	near
		uses	ax
		.enter
	;
	; Get compression setting from access point.
	;
		clr	cx			; standard property
		mov	dx, APSP_COMPRESSION
		call	AccessPointGetIntegerProperty	; ax = value
if _RESPONDER
		jnc	setIt
		mov	ax, FALSE		; false by default if not set
setIt:
else
		jc	exit
endif
		push	ax			; pass compress setting
		call	PPPSetDataCompression
exit::
		.leave
		ret
PPPSetDataCompress	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSetAccessIPAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the local IP address for this access point.  If found,
		set it as our address but allow it to be overridden if 
		the peer suggests a different one.

CALLED BY:	PPPSetAccessInfo

PASS:		ds	= dgroup
		ax	= access point ID

RETURN:		nothing

DESTROYED:	bx, cx, dx, bp, di, si, es (allowed)

PSEUDO CODE/STRATEGY:
		Read address from access point library.
		If found, parse address into binary IP address in host 
			format and set it as our address, allowing override

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSetAccessIPAddr	proc	near
		uses	ax
		.enter
	;
	; Get address string from access point, looking for APSP_AUTOMATIC
	; first.
	;
		clr	cx, bp			; standard property, alloc buf
		mov	dx, APSP_AUTOMATIC or APSP_ADDRESS
		call	AccessPointGetStringProperty	; bx = handle of block
							; cx = size of addr
		jnc	haveAddr

		clr	cx, bp			; standard property, alloc buf
		mov	dx, APSP_ADDRESS
		call	AccessPointGetStringProperty	; bx = handle of block
							; cx = size of addr
		jc	exit
haveAddr:
DBCS <		shl	cx, 1			; length -> size	>
	;
	; Parse address string into binary IP address.
	; 
		call	PPPParseDecimalAddr	; dxdi = addr in host form
		lahf
		call	MemFree			; free string block
		sahf
		jc	exit

		push	bp			; pass unit of 0
		pushdw	dxdi			; pass our addr
		pushdw	bpbp			; pass peer addr of 0
		push	cx			; allow override (non-zero)
		push	cx			; allow override (non-zero)
		call	SetIPAddrs		
exit:
		.leave
		ret
PPPSetAccessIPAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPParseDecimalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse an IP address string in x.x.x.x format into a binary
		IP address.   

CALLED BY:	PPPSetAccessIPAddr

PASS:		bx 	= block holding IP address string (freed by caller)
		cx	= size of address  (may be zero)

RETURN:		carry set if address is invalid
		else carry clear
		dxdi	= address in host format

DESTROYED:	ax, si, es (allowed)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPParseDecimalAddr	proc	near
		uses	bx, cx, ds
laddr		local	dword
		.enter
	;
	; Make sure address is a reasonable length.
	;
		jcxz	error

DBCS <		shr	cx					>
		cmp	cx, MAX_IP_DECIMAL_ADDR_LENGTH
		ja	error

		call	MemLock
		mov	ds, ax
		clr	si				; ds:si = address
	;
	; Strip any trailing garbage (non-digit) in the address.
	;
		push	si
		add	si, cx
DBCS <		add	si, cx					>
		clr	ax
scanLoop:
		LocalPrevChar	dssi			; ds:si = last valid char
		LocalGetChar	ax, dssi, NO_ADVANCE	
		call	LocalIsDigit
		jnz	stopScanning

		dec	cx
		jnz	scanLoop			
stopScanning:
		pop	si
		jcxz	error
	;
	; Convert the string to the binary address, detecting
	; any errors.  Each part of the address must begin with 
	; a digit.  The rest may be a digit or a dot, except for
	; the last part.  Max value of each part is 255.
	;
		lea	di, laddr
		mov	bx, MAX_IP_ADDR_OFFSET
digitOnly:
		clr	ax
		LocalGetChar	ax, dssi
		sub	ax, '0'
		cmp	ax, 9
		ja	error				; not a digit
		dec	cx
		jz	noMore
digitOrDot:
		clr	dx
		LocalGetChar	dx, dssi
		cmp	dx, '.'
		je	isDot
		sub	dx, '0'
		cmp	dx, 9
		ja	error				; not a digit

		push	cx
		mov	cl, 10
		mul	cl
		pop	cx
		add	ax, dx
		tst	ah
		jnz	error				; overflow

		loop	digitOrDot
		jmp	noMore
isDot:
		mov	ss:[bx][di], al
		dec	bx
		js	error

		loop	digitOnly
		jmp	error
noMore:
	;
	; Store the final value and make sure there are enough parts
	; for a valid IP address.
	;
		mov	ss:[bx][di], al
		tst_clc	bx
		je	exit
error:		
		stc
exit:
		movdw	dxdi, laddr			; return address
		.leave
		ret
PPPParseDecimalAddr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSetAccessUsername
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get username from access point database and set it.

CALLED BY:	PPPSetAccessInfo

PASS:		ds	= dgroup
		ax	= access point ID

RETURN:		^hbx	= username
		cx	= size

DESTROYED:	dx, bp, di, si, es

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSetAccessUsername	proc	near
		uses	ax
		.enter

		clr	cx, bp			; allocate a block
		mov	dx, APSP_USER
		call	AccessPointGetStringProperty	; ^lbx = name
							; cx = size
		jc	noName
		jcxz	nullName				

if DBCS_PCGEOS
	;
	; Convert the username to SBCS.
	;
		push	ax, cx, es, di
		call	MemLock
		mov	es, ax
		clr	di
		call	PPPConvertDBCSToSBCS
		call	MemUnlock
		pop	ax, cx, es, di
endif

		push	bx, cx
		push	bp				; pass unit of 0
		push	bx				; pass name block
		push	cx				; pass name size
		call	PPPSetUsername
		pop	bx, cx				; username and size
		clc
		jmp	exit
nullName:
		call	MemFree				; free name block
noName:		
		clr	cx
exit:
		.leave
		ret

PPPSetAccessUsername	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSetAccessSecret
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the user's secret from access  point database and
		set it.  

CALLED BY:	PPPSetAccessInfo

PASS:		ds	= dgroup
		ax	= access point ID
		^hbx 	= username
		cx	= size

RETURN:		carry set if error
		ax	= SpecSocketDrError
				(SSDE_CANCEL,
				 SSDE_NO_USERNAME)
			  - or - SDE_INTERRUPTED

DESTROYED:	bx, cx, dx, bp, di, si, es

PSEUDO CODE/STRATEGY:
		Find out if user needs to be prompted for password.
		If yes, prompt for it
		else, query access point for it.

NOTE:		Not having a password does not result in error.  Carry
	  	is only returned when user cancels the open when prompted
		for a password.	

		Caller MUST NOT have access!

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version
	jwu	11/27/95		Added password prompting
	jwu	7/19/96			Check for interrupt before prompting

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSetAccessSecret	proc	near
	;
	; Find out if password needs to be prompted.
	;
		push	ax, cx
		clr	cx
		mov	dx, APSP_PROMPT_SECRET
		call	AccessPointGetIntegerProperty	
		mov_tr	cx, ax				; cx = value
		pop	ax, dx				; ax = access ID
							; dx = username size
		jc	noPrompt
		jcxz	noPrompt
	;
	; Check for interrupt before prompting for password.
	;
		call	PPPCheckForInterrupt		; ax = SDE_INTERRUPTED
		jc	exit

		mov	cx, dx				; cx = username size
		jcxz	noName				; need username!
		call	PPPQuerySecret			; carry set to cancel
							; ^hbx = secret
							; cx = size
		jnc	setSecret

		mov	ax, SSDE_CANCEL
		jmp	exit
noName:
		mov	ax, SSDE_NO_USERNAME
		stc
		jmp	exit
noPrompt:
	;
	; Query access point for secret.
	;
		clr	cx, bp				; alloc a block
		mov	dx, APSP_SECRET
		call	AccessPointGetStringProperty	; ^hbx = secret
							; cx = length
		jc	okay
		jcxz	nullName
setSecret:
if DBCS_PCGEOS
		push	cx, es, di
		call	MemLock
		mov	es, ax
		clr	di
		call	PPPConvertDBCSToSBCS		; es:di = SBCS
		call	MemUnlock
		pop	cx, es, di
endif
		clr	ax
		push	ax				; pass unit of 0
		push	bx				; pass secret block
		push	cx				; pass size
		call	PPPSetSecret
		jmp	okay
nullName:
	;
	; Block still needs to be freed.
	;
		call	MemFree
okay:
		clc
exit:
		ret
PPPSetAccessSecret	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPCreateUIThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to create a new UI thread owned
		by the system UI thread.

CALLED BY:	PPPQuerySecret, PPPCheckDiskspace

PASS:		nothing

RETURN:		carry clear if thread created
			^hbx = handle of new thread

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/12/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPCreateUIThread	proc	near
		uses	ax, cx, dx, di, bp
		.enter
	;
	; Get System UI thread.
	;
		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo		; ax = UI thread handle
		mov_tr	bx, ax			
	;
	; Create new thread with System UI thread as owner.
	;
		mov	bp, PPP_STACK_SIZE
		mov	cx, segment PPPUIClass
		mov	dx, offset PPPUIClass
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
		mov	di, mask MF_CALL
		call	ObjMessage		; ax = new UI thread
		mov_tr	bx, ax

		.leave
		ret
PPPCreateUIThread	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPQuerySecret
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog asking user to enter the password for the
	   	connection.  Get the password and set it before returning.

CALLED BY:	PPPSetAccessSecret

PASS:		ds	= dgroup
		ax	= accpnt ID
		^hbx	= username
		cx	= username size

RETURN:		carry set if error
		else
		cx	= length of secret (excluding null)
		^hbx	= secret

DESTROYED:	ax, bx, dx, bp, di, si, es (allowed)

PSEUDO CODE/STRATEGY:
		Get system UI thread.
		Create a new ui thread owned by system UI.
		Have the UI thread put up the dialog and do all the work 
			(including destroying itself)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/27/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPQuerySecret	proc	near

	;
	; Get system UI thread and create a new UI thread owned by it.
	;
		mov	dx, bx			; ^hdx = username
		call	PPPCreateUIThread	; ^hbx = new thread
		jc	exit
if DBCS_PCGEOS
		call	PPPConvertUsername	; ^hdx = DBCS username
						; cx   = size
		shr	cx, 1			; cx   = length
		push	dx
endif
	;
	; Have new UI thread do the work of querying user for the 
	; password.  UI thread will destroy itself when done.
	;
		mov	bp, ax			; bp = accpnt ID
		mov	ax, MSG_PPP_UI_PROMPT_PASSWORD
		mov	di, mask MF_CALL
		call	ObjMessage		; carry set to cancel, else
						; ^hcx = password
						; ax = size (no null)
if DBCS_PCGEOS
	;
	; Correctly set the length (if no error).  Free the DBCS
	; username block.  Preserve the carry in case there was an
	; error entering the password. 
	;
		pop	bx			; bx = username block
		pushf
		jc	notLength
		shr	ax, 1			; ax = length
notLength:
		call	MemFree
		popf
endif
		mov_tr	bx, cx			
		mov_tr	cx, ax			
exit:
		ret

PPPQuerySecret	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPConvertUsername
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the SBCS username string to DBCS.

CALLED BY:	PPPQuerySecret
PASS:		^hdx	= SBCS username string
		cx	= size of SBCS string
RETURN:		^hdx	= new block with DBCS username
		cx	= size of DBCS string
DESTROYED:	nothing
SIDE EFFECTS:	
		Creates a new block which must be freed by the caller.
		The reference to the original block is not preserved.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	10/23/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
PPPConvertUsername	proc	near
		uses	ax,bx,si,di,bp,ds,es
		.enter
	;
	; Convert the username to DBCS so that it can be displayed in
	; the dialog.  First, lock down the username block.
	;
		mov	bx, dx
		call	MemLock
		mov	ds, ax
		clr	si			; ds:si = username
	;
	; Next, create a new block where the DBCS string will go.
	;
		push	cx
		shl	cx, 1			; new block size
		mov	ax, ALLOC_DYNAMIC_LOCK
		xchg	ax, cx
		call	MemAlloc		; ^hbx = block handle
		mov	dx, bx
		mov	es, ax
		clr	di			; es:di = new block
		pop	cx
	;
	; Now, do the conversion.
	;
		push	dx
		mov	ax, C_PERIOD
		mov	bx, CODE_PAGE_SJIS
		mov	dx, 0
		call	LocalDosToGeos		; cx = new string length
		pop	dx			; ^hdx = new username

		shl	cx, 1			; cx = new string size

		mov	bx, dx
		call	MemUnlock

		.leave
		ret
PPPConvertUsername	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPBeginNegotiations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start PPP timer and activate LCP.

CALLED BY:	PPPOpenLink

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si, es (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPBeginNegotiations	proc	near
	;
	; Setup idle timeout.
	;
		call	PPPSetIdleTimeout

	;
	; Start timer and bring LCP to OPEN state.
	;
		call	PPPStartTimer			

		clr	ax
		push	ax				; pass unit of 0
		call	lcp_open
	;
	; If in active mode, tell LCP the lower layer is UP (the 
	; physical layer is the lower layer) so link configuration 
	; will begin.
	;
		test	ds:[clientInfo].PCI_status, mask CS_PASSIVE
		jnz	exit

		clr	ax
		push	ax				; pass unit of 0
		call	lcp_lowerup
exit:
		ret
PPPBeginNegotiations	endp

ConnectCode		ends

PPPCODE			segment public 'CODE'

COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPDeliverPacket

DESCRIPTION:	Deliver packet of data to client.

C DECLARATION:	extern void _far 
		_far _pascal PPPDeliverPacket(PACKET *packet, int unit);

STRATEGY:
		downsize buffer if needed 
		Grab optr from header
		Unlock buffer
		if no client, free buffer
		else call client with SCO_RECEIVE_DATA

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/17/95		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPDELIVERPACKET		proc	far	packet:fptr.PppPacketHeader,
						unit:word
		uses	di, si, ds
		.enter

		ForceRef 	unit
	;
	; Eliminate any excess size from the end of the buffer 
	; before delivery by downsizing the buffer to only contain
	; the data.
	;
		segmov	es, ds, cx		; es = dgroup

		lds	si, packet		; ds:si = PppPacketHeader
		mov	cx, ds:[si].PPH_common.PH_dataSize

	;
	; increase the count - bytesReceived
	;
		movdw	axbx, es:[bytesReceived]
		add	bx, cx
		jnc	addBytes
		inc	ax
addBytes:
		movdw	es:[bytesReceived], axbx
		
		mov	ax, ds:[si].PPH_common.PH_dataOffset 
		add	cx, ax			; cx = new size
		movdw	bxax, ds:[si].PPH_optr	; ^lbx:ax = buffer
		call	HugeLMemReAlloc
	;
	; Unlock the buffer and deliver to client.  If no client,
	; then just free the buffer.
	;
		call	HugeLMemUnlock

		tstdw	es:[clientInfo].PCI_clientEntry
		jnz	deliver

		movdw	axcx, bxax
		call	HugeLMemFree
		jmp	exit
deliver:
		
EC <		test	es:[clientInfo].PCI_status, mask CS_REGISTERED	>
EC <		ERROR_Z PPP_CORRUPT_CLIENT_INFO				>

		movdw	cxdx, bxax		; ^lcx:dx = buffer
		pushdw	es:[clientInfo].PCI_clientEntry
		mov	di, SCO_RECEIVE_PACKET
		call	PROCCALLFIXEDORMOVABLE_PASCAL

exit:
		.leave
		ret
PPPDELIVERPACKET		endp
	SetDefaultConvention

PPPCODE			ends

ConnectCode		segment resource

COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPLinkOpened

DESCRIPTION:	Inform the client that the link is now open.

C DECLARATION:	extern void _far
		_far _pascal PPPLinkOpened (void);

STRATEGY:	
		Stop client timer 
		if state is CLOSING, 
			release taskSem and return (open interrupted so
				don't bother notifying)
		else
			EC (check state is PLS_NEGOTIATING)
			set state to PLS_OPEN
			if accpnt ID, PPPSetAccessDNS	
		if have a client {
			if waiter is blocked {
				wake the waiter
				if not passive mode, exit
			}
			notify client link is open
		}						
		Else {
			get a client
			if error 
				set sate to CLOSING
 				queue MSG_PPP_CLOSE_LINK
				release taskSem
				exit
			else
				clr CS_BLOCKED
				if was blocked (must be passive if blocked)
					V Sem
					use SCO_LINK_OPENED 
				else 
					use SCO_CONNECT_CONFIRMED
				notify client link opened using correct SCO
				send medium notifications
				release taskSem
				exit
		}

NOTES:
		Take advantage of DS being dgroup because this is 
		called from C.	

		HOLDING taskSem during notifications is safe because
		PPPGetInfo does not P the taskSem.  TCP will get info
		about the link when notified the link is open and should
		not attempt to do anything else on the PPP thread.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/18/95		Initial Version
	jwu	7/31/96		Nonblocking and interruptible version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPLINKOPENED	proc	far			
		uses	di, si, ds
		.enter
	;
	; Gain access and stop client timer.  If state is CLOSING, 
	; opening the link was interrupted so don't bother sending 
	; any notifications until the link closes. 
	;
		mov	bx, ds:[taskSem]
		call	ThreadPSem

		clr	ds:[clientInfo].PCI_timer	

		cmp	ds:[clientInfo].PCI_linkState, PLS_CLOSING
		LONG	je	releaseAccess		
	;
	; Set state to OPEN, and get DNS info from access point if used.
	;
EC <		cmp	ds:[clientInfo].PCI_linkState, PLS_NEGOTIATING	>
EC <		ERROR_B PPP_INTERNAL_ERROR				>

	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_OPEN
		call	PPPSendNotice
		pop	bp

		mov	ds:[clientInfo].PCI_linkState, PLS_OPEN
		tst	ds:[clientInfo].PCI_accpnt
		jz	checkClient

		push	ds:[clientInfo].PCI_accpnt
		call	PPPSetAccessDNS

checkClient:
	;
	; If no client, get one now.  (Means PPP is being opened
	; in passive mode.)  Close link if unsuccessful.
	;
		tstdw	ds:[clientInfo].PCI_clientEntry
		jnz	haveClient

		call	PPPGetIPClient			
		jnc	haveClient

	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_CLOSING
		call	PPPSendNotice
		pop	bp

		mov	ds:[clientInfo].PCI_linkState, PLS_CLOSING

		mov	bx, ds:[pppThread]
		mov	ax, MSG_PPP_CLOSE_LINK
		mov	di, mask MF_FORCE_QUEUE 	; must force queue!
		call	ObjMessage
		jmp	releaseAccess			; no Clavin stuff
haveClient:
	;
	; If no waiter, notify with connect confirmed.  Slurker
	; is the only one who blocks so wake the slurker and 
	; send a link opened notification to the client.
	;
		mov	di, SCO_CONNECT_CONFIRMED
		test	ds:[clientInfo].PCI_status, mask CS_BLOCKED
		jz	notify		

EC <		test	ds:[clientInfo].PCI_status, mask CS_PASSIVE	>
EC <		ERROR_Z	PPP_INTERNAL_ERROR	; only slurker blocks!	>

		BitClr	ds:[clientInfo].PCI_status, CS_BLOCKED
		mov	bx, ds:[clientInfo].PCI_mutex
		call	ThreadVSem			; wake slurker

		mov	di, SCO_LINK_OPENED		; notify client 
notify:
		call	PPPNotifyLinkOpened

if _SEND_NOTIFICATIONS
		call	PPPNotifyMediumConnected
endif ; _SEND_NOTIFICATIONS

releaseAccess:
		mov	bx, ds:[taskSem]
		call	ThreadVSem
exit::
		.leave
		ret
PPPLINKOPENED	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPLinkClosed

DESCRIPTION:	Inform the client that the link has closed.

CALLED BY:	lcp_closed

C DECLARATION:	extern void _far
		_far _pascal PPPLinkClosed (word error);

STRATEGY:	
		Stop PPP timer
		grab taskSem
		if PCI_error is SDE_INTERRUPTED, do not store new
			error but use the stored error instead
		get former state and set new state to PLS_CLOSED, 
		get status and clr CS_BLOCKED
		if CS_BLOCKED
			wake client
		else if client exists
			grab regSem
			if error is SDE_INTERRUPTED or if former state
			is PLS_NEGOTIATING
				use SCO_CONNECT_FAILED
			else use SCO_LINK_CLOSED
			notify client, passing error
			release regSem
		send medium notifications
		release taskSem		

NOTE:
		MUST hold registration semaphore when notifying the
		client that the link is closed to prevent client 
		from unregistering us and then exiting before our
		thread has a chance to return from the client's code.

		This happens when TCP was loaded by PPP and TCP has
		no clients, so that TCP will unregister PPP and exit
		when told the PPP link has closed.

		MUST hold taskSem until done sending medium notifications
		or else client could attempt to open another connection 
		before status is updated.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/18/95		Initial Version
	jwu	7/31/96		Non-blocking and interruptible version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPLINKCLOSED		proc	far
		C_GetOneWordArg	dx, ax, bx	; dx = error
	;
	; Stop timer and grab taskSem.  Store error unless previous
	; error is SDE_INTERRUPTED.  If generic error has not been set
	; but the specific error is set, set the generic error to
	; SDE_CONNECTION_RESET. 
	;
		call	PPPStopTimer

		mov	bx, ds:[taskSem]
		call	ThreadPSem

		cmp	ds:[clientInfo].PCI_error.low, SDE_INTERRUPTED
		je 	afterError

		tst	dx
		je	storeError				; no error
		tst	dl
		jne	storeError			
		mov	dl, SDE_CONNECTION_RESET
storeError:
		mov	ds:[clientInfo].PCI_error, dx
afterError:
	;
	; Unlock access point now that connection has closed.
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
		mov	cl, PLS_CLOSED
		xchg	cl, ds:[clientInfo].PCI_linkState	
		mov	dl, ds:[clientInfo].PCI_status		
		BitClr 	ds:[clientInfo].PCI_status, CS_BLOCKED	
	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_CLOSED
		call	PPPSendNotice
		pop	bp
	;
	; If client is waiting for close to complete, unblock client.
	;
		test	dl, mask CS_BLOCKED
		jz	notify

		mov	bx, ds:[clientInfo].PCI_mutex
		call	ThreadVSem
		jmp	done
notify:
	;
	; Notify client if there is one.  Must hold regSem before
	; calling out to client.  (See notes in header.)
	;

		tstdw	ds:[clientInfo].PCI_clientEntry			
		jz	done

EC <		test	ds:[clientInfo].PCI_status, mask CS_REGISTERED	>
EC <		ERROR_E	PPP_CORRUPT_CLIENT_INFO				>

		mov	bx, ds:[regSem]
		call	ThreadPSem
	;
	; Must pass an error to get TCP to close any connections using
	; the PPP link.  Client didn't initiate the close so we claim
	; the connection is reset.
	;
		mov	dx, ds:[clientInfo].PCI_error
		tst	dl
		jnz	gotError
		mov	dl, SDE_CONNECTION_RESET
gotError:
	;
	; If error is SDE_INTERRUPTED or former state is
	; PLS_NEGOTIATING, notify client connect has failed.  Else
	; send a link closed notification.
	; 
		mov	di, SCO_CONNECT_FAILED
		cmp	dl, SDE_INTERRUPTED
		je	notifyNow
		cmp	cl, PLS_NEGOTIATING
		je	notifyNow

		mov	di, SCO_LINK_CLOSED
notifyNow:
		push	bx
		call	PPPNotifyLinkClosed
		pop	bx
		call	ThreadVSem			; regSem
done:

if _SEND_NOTIFICATIONS
		call	PPPNotifyMediumDisconnected
endif ; _SEND_NOTIFICATIONS

		mov	bx, ds:[taskSem]
		call	ThreadVSem
exit::
		ret	
PPPLINKCLOSED		endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPNotifyLinkOpened
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify client the PPP link has been opened.  

CALLED BY:	PPPLINKOPENED

PASS:		ds 	= dgroup
		di	= SCO_LINK_OPENED or SCO_CONNECT_CONFIRMED

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si, es (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 6/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPNotifyLinkOpened	proc	near
		uses	ds
addrBuffer	local	dword
		.enter

EC <		test	ds:[clientInfo].PCI_status, mask CS_REGISTERED	>
EC <		ERROR_Z PPP_BAD_CLIENT_STATUS				>

		pushdw	ds:[clientInfo].PCI_clientEntry
		mov	bx, ds:[clientInfo].PCI_domain

		cmp	di, SCO_CONNECT_CONFIRMED
		je	callClient

		push	di, bx
		call	GetLocalIPAddr		; dxax = addr in host format
		xchg	dh, dl
		xchg	ah, al			; axdx = addr in network format
		movdw	addrBuffer, axdx
		pop	di, bx			

		segmov	ds, ss, si
		lea	si, addrBuffer		; ds:si = address
		mov	cx, IP_ADDR_SIZE
callClient:
		mov	ax, PPP_CONNECTION_HANDLE
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		clc

		.leave
		ret
PPPNotifyLinkOpened	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPNotifyLinkClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify client the PPP link is closed.

CALLED BY:	PPPOpenLink
		PPPLINKCLOSED

PASS:		ds	= dgroup
		di	= SCO_LINK_CLOSED or SCO_CONNECT_FAILED
		dx	= SocketDrError

RETURN:		nothing

DESTROYED:	ax, bx, cx, di (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPNotifyLinkClosed	proc	near

EC <		test	ds:[clientInfo].PCI_status, mask CS_REGISTERED	>
EC <		ERROR_Z PPP_BAD_CLIENT_STATUS				>

		pushdw	ds:[clientInfo].PCI_clientEntry

		cmp	di, SCO_CONNECT_FAILED
		je	callClient

		mov	cx, SCT_FULL

callClient:
		mov	ax, PPP_CONNECTION_HANDLE
		mov	bx, ds:[clientInfo].PCI_domain
		call	PROCCALLFIXEDORMOVABLE_PASCAL			

		ret
PPPNotifyLinkClosed	endp

ConnectCode		ends

PPPCODE			segment public 'CODE'

if not _PENELOPE

COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPDeviceWrite

DESCRIPTION:	Write output data to device driver.

C DECLARATION:	extern void _far
		_far _pascal PPPDeviceWrite (unsigned char *data,
						word numBytes);
STRATEGY:
		Just write the data to the serial port. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/18/95		Initial Version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPDEVICEWRITE		proc	far	data:fptr.byte,
					numBytes:word
		uses	si, di, ds
		.enter

		segmov	es, ds, ax			; es = dgroup
		mov	bx, es:[port]
		lds	si, data			; ds:si = output data
		mov	ax, STREAM_BLOCK
		mov	cx, numBytes
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

		.leave
		ret

PPPDEVICEWRITE		endp
	SetDefaultConvention

endif ; not _PENELOPE

PPPCODE			ends

ConnectCode		segment resource

if not _PENELOPE

COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPDeviceClose

DESCRIPTION:	Close the physical connection.  Returns zero if 
		close was not performed.

CALLED BY:	lcp_closed
		PPPShutdown

C DECLARATION:	extern unsigned short _far
		_far _pascal PPPDeviceClose (void);

PSEUDO CODE/STRATEGY:
		If modem driver is loaded, 
			tell modem to handup
			close the modem connection 
			unload the modem driver
		Else, close the serial port.

NOTE:		Do NOT unload serial driver here.  Modem driver is
		loaded if used by a PPP connection, but serial driver
		is loaded for the lifetime of the PPP driver.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/18/95		Initial Version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPDEVICECLOSE		proc	far
		uses	di
		.enter
	;
	; If device was closed and no modem driver was used, then
	; no need to do anything.  
	;
		mov	al, ds:[clientInfo].PCI_status
		and	al, mask CS_DEVICE_OPENED
		jnz	wasOpen
		clr	ah
		or	ax, ds:[modemDr]
		jz	exit			

		clr	di				; just unload driver
		call	PPPCloseAndUnloadModem
		jmp	closed
wasOpen:
	;
	; Device was open.  Either close modem connection or close
	; serial port.
	;
		BitClr	ds:[clientInfo].PCI_status, CS_DEVICE_OPENED
		mov	bx, ds:[port]

		tst	ds:[modemDr]
		jne	doModem
	;
	; Close serial port.
	;
		mov	ax, STREAM_DISCARD
		mov	di, DR_STREAM_CLOSE
		call	ds:[serialStrategy]
		jmp	closed
doModem:

if _RESPONDER
		call	PPPUnregisterECI	
endif
	;
	; Hangup, close modem port and free modem driver.
	;
		mov	di, DR_MODEM_HANGUP
		call	PPPCloseAndUnloadModem
closed:
		mov	ax, TRUE
exit:
		.leave
		ret
PPPDEVICECLOSE		endp
	SetDefaultConvention 

endif ; not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPDeviceOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the physical connection.

CALLED BY:	PPPOpenLink

PASS:		ds	= dgroup
		cx	= address string size
		dx:bp	= non-null terminated address string

RETURN:		carry clear if successful
		else
		carry set 
		ax	= SpecSocketDrError
				(SSDE_INVALID_ACCPNT
				 SSDE_DEVICE_ERROR	-- responder-only
				 SSDE_DEVICE_NOT_FOUND  -- no modem driver
				 SSDE_DEVICE_BUSY
				 SSDE_CALL_FAILED
				 SSDE_DEVICE_TIMEOUT
				 SSDE_DIAL_ERROR
				 SSDE_LINE_BUSY
				 SSDE_NO_DIALTONE
				 SSDE_NO_ANSWER
				 SSDE_NO_CARRIER
				 SSDE_BLACKLISTED
				 SSDE_DELAYED)
			 - or -  SocketDrError (SDE_INTERRUPTED)


DESTROYED:	ax if not returned

PSEUDO CODE/STRATEGY:
		Get phone number from address 
		If no number, (direct serial connection)
			open serial port
			if failed, return specific error
			else
				configure port
				return success
		else (modem connection)
			load modem driver
			get modem strategy
			open modem connection
			if failed, unload modem driver 
				return specific error
			else
				configure port
				dial number
				if failed, close modem connection
					unload modem driver
					return specific error 
				else 
					return success

NOTES:
		Caller has access so be sure to return with access held!


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/19/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPDeviceOpen	proc	near
		uses	bx, cx, dx, bp, di, es
		.enter
	;
	; If mediumType indicates cell_modem, PPP is in passive mode
	; with no link address.
	;
		clr	bx, ax				; no address nor ID
		cmp	ds:[mediumType].MET_id, GMID_CELL_MODEM
		je	doModem
	;
	; If no address, then use regular serial connection.
	; If phone number provided in address, just pass it to 
	; the modem.  Else, look up the number in the access 
	; point database.
	;
		jcxz	doSerial

 		mov	es, dx
		mov	di, bp
		mov	dl, es:[di]
		inc	di				; es:di = link params
		cmp	dl, LT_ADDR
		je	doModem

EC <		cmp	dl, LT_ID				>
EC <		ERROR_NE PPP_INVALID_LINK_ADDRESS_TYPE		>
		mov	ax, es:[di]			; ax = acc pnt ID
		call	PPPCheckAccpnt			; ax = error
		jc	exit

		clr	cx				; alloc a buf
		clr	bx
		call	AccessPointGetPhoneStringWithOptions
						; bx = block, cx = length
		jnc	doSerial			; carry clear - no PHONE
		jcxz	freeBlkDoSerial

		push	ax
		call	MemLock
		mov	es, ax
		clr	di				; es:di = phone #

DBCS <		call	PPPConvertDBCSToSBCS		; es:di = SBCS string>

		pop	ax				; ax = access ID
doModem:		
	;
	; Open modem connection and setup data notification.
	;
if _PENELOPE
		call  	PPPPADOpen			; ax = error, if any
else
		call	PPPModemOpen			; ax = error, if any
endif
		pushf
		tst	bx
		je	freed
		call	MemFree
freed:
		popf
		jmp	exit

freeBlkDoSerial:
	;
	; Zero-sized number string still requires block to be freed.
	;
		call	MemFree
doSerial:

if _MUST_HAVE_PHONE_NUMBER
		mov	ax, SSDE_INVALID_ACCPNT		; error because no #
		stc
else
	;
	; Open serial connection and setup data notification.
	;
		call	PPPSerialOpen			; ax = error, if any
endif

exit:
		.leave
		ret
PPPDeviceOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPConvertDBCSToSBCS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a DBCS string to SBCS in-place by removing
		the nulls (assumes string is made up of Roman
		characters)

CALLED BY:	PPPDeviceOpen, PPPInitializeModem
PASS:		es:di	= DBCS string
		cx	= string length
RETURN:		es:di	= valid SBCS string (nulls removed)
		cx	= string size (same as length passed)
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	10/15/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
PPPConvertDBCSToSBCS	proc	near
		uses	cx, bp, di
		.enter
	;
	; di will advance through the string, pointing at the next
	; DBCS byte that needs to be moved.  bp points to the end of
	; the SBCS string where the DBCS byte is to be placed.
	;
		mov	bp, di				; beginning
		dec	cx
		jz	noLoop
		inc	bp				; first char stays put
		LocalNextChar	esdi			; advance two bytes
loopTop:
		mov	al, {byte} es:[di]
		mov	{byte} es:[bp], al
		LocalNextChar	esdi
		inc	bp
		loop	loopTop
		mov	{byte} es:[bp], 0		; null terminate
noLoop:
		.leave
		ret
PPPConvertDBCSToSBCS	endp
endif


if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSerialOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the serial connection and set up data notification.

CALLED BY:	PPPDeviceOpen

PASS:		ds	= dgroup

RETURN:		carry clear if successful
		else
		carry set
		ax	= SpecSocketDrError
				(SSDE_DEVICE_BUSY)

DESTROYED:	ax, bx, cx, dx, bp, di, si, es (allowed)

PSEUDO CODE/STRATEGY:
		Open serial port.
		If failed, return SSDE_DEVICE_BUSY

		configure serial port
		setup data notification
		return success

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _MUST_HAVE_PHONE_NUMBER

PPPSerialOpen	proc	near
	;
	; Open serial port.
	;
		mov	ax, mask SOF_NOBLOCK
		mov	bx, ds:[port]
		mov	cx, PPP_SERIAL_BUFFER_SIZE
		mov	dx, cx				; output = input sizes
		mov	si, handle 0			; we own it
		mov	di, DR_SERIAL_OPEN_FOR_DRIVER
		call	ds:[serialStrategy]
		jnc	configPort

		mov	ax, SSDE_DEVICE_BUSY
		jmp	exit
configPort:
	;
	; Configure serial port's baud rate, flow control, parity,
	; extra stop bit, length.  Setup data notification.
	;
		call	PPPConfigurePort
		mov	di, DR_STREAM_SET_NOTIFY
		call	PPPSetPortNotify
exit:
		ret
PPPSerialOpen	endp

endif ; not _MUST_HAVE_PHONE_NUMBER

endif ; not _PENELOPE

if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPModemOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish the modem connection and setup data notification.

CALLED BY:	PPPDeviceOpen

PASS:		ds	= dgroup
		es:di	= phone number (non-null terminated) 
		cx	= size of phone number string (0 if passive mode)
		ax	= access ID (0 if none) (ignored if passive mode)

RETURN:		carry clear if successful
		else
		carry set
		ax	= SpecSocketDrError
				(SSDE_DEVICE_ERROR	-- responder-only
				 SSDE_DEVICE_NOT_FOUND  -- no modem driver
				 SSDE_DEVICE_BUSY
				 SSDE_CALL_FAILED
				 SSDE_DEVICE_TIMEOUT
				 SSDE_DIAL_ERROR
				 SSDE_LINE_BUSY
				 SSDE_NO_DIALTONE
				 SSDE_NO_ANSWER
				 SSDE_NO_CARRIER
				 SSDE_BLACKLISTED
				 SSDE_DELAYED)

DESTROYED:	ax, cx, dx, di, es (allowed)

PSEUDO CODE/STRATEGY:
		release access to give user a chance to cancel
		RESPONDER ONLY: Check if phone is on and clear black list

		load modem driver, handling error
		get modem strategy
		open modem connection, handling error
		configure port
		setup data notification.
		reset modem, handling error
		initialize modem
		if passive mode, {
			answer the phone, handling error
		} else {
 			if accpnt ID used, initialize modem 
			check for interrupt
			REPONDER ONLY: register for ECI
			dial number, handling error
			check again for interrupt if dialing is successful
		}

NOTES: 	
		Caller has access so return with access held!

		Must hold access after dialing so PPPOpenLink can
		change the state before user interrupts the connect request.
		If user slips in, no message will be sent to PPP to stop
		the connect process.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version
	jwu	2/20/96			Added SecurityCheckSIMCardAndPhone
	jwu	7/19/96			Added checks for interrupt.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPModemOpen	proc	near
		uses	bx, si
phone		local	fptr			push es, di
theSize		local	word			push cx
accID		local	word			push ax
		.enter
	;
	; Release access to give user a chance to cancel.  
	;
		mov	bx, ds:[taskSem]	
		call	ThreadVSem

if _RESPONDER
	;
	; Check if phone is on and SIM card is okay.
	;
		call	SecurityCheckSIMCardAndPhone
		cmp	ax, CPMS_OK
		je	checkDisk
		mov	ax, SSDE_DEVICE_ERROR
		jmp	gotError
checkDisk:
	;
	; Check if enough diskspace.
	;
		call	PPPCheckDiskspace
		mov	ax, SSDE_CANCEL
		jc	regainAccess
	;
	; Clear black list before every call.
	;
		call	PPPClearBlacklist
endif	; _RESPONDER
		
	;
	; Load modem driver and get strategy.
	;
		call	PPPLoadModemDriver		
		jnc	openIt

		mov	ax, SSDE_DEVICE_NOT_FOUND
		jmp	regainAccess
openIt:
	;
	; Open modem connection.  Unload modem driver if failed.
	;		
		mov	bx, ds:[port]
		mov	ax, mask SOF_NOBLOCK
		mov	cx, PPP_SERIAL_BUFFER_SIZE
		mov	dx, cx
		mov	si, ds:[serialDr]		
		mov	di, DR_MODEM_OPEN
		call	ds:[modemStrategy]
		jnc	configPort

		clr	di				; just unload driver
		call	PPPCloseAndUnloadModem

		mov	ax, SSDE_DEVICE_BUSY
		stc
		jmp	regainAccess

configPort:
		call	PPPConfigurePort
		mov	di, DR_MODEM_SET_NOTIFY
		call	PPPSetPortNotify

		call	PPPResetModem			; ax = ModemResultCode
		jc	failed

		call	PPPStandardModemInit		; ax = ModemResultCode
		jc	failed
		call	PPPInitV42Compression

	;
	; Now indicate that the opening phase is done by setting
	; the status to dialing (even though we might not be dialing..
	; wasn't my idea.) --JimG 8/20/99
	;
		push	bp
		mov	bp,	PPP_STATUS_DIALING
		call	PPPSendNotice
		pop	bp

	;
	; If in passive mode, answer the phone.
	;
		test	ds:[clientInfo].PCI_status, mask CS_PASSIVE
		jz	doActive

		mov	di, DR_MODEM_ANSWER_CALL
		call	ds:[modemStrategy]		; ax = ModemResultCode
		jc	failed
if _RESPONDER
		call	PPPRegisterECIEnd
		clc
endif
		jmp	regainAccess
		
doActive:		
	;
	; Initialize the modem if we have an accpnt from which to 
	; look up the custom init string.
	;
		tst	accID
		je	dial
		mov	ax, accID
		call	PPPInitializeModem		; ax = ModemResultCode
		jc	failed
		call	PPPOtherInitializeModem		; ax = ModemResultCode
		jc	failed
dial:

		call	PPPCheckForInterrupt		; ax = SDE_INTERRUPT
		cmc					; don't translate error
		jnc	failed				

if _RESPONDER
		call	PPPRegisterECIAll
endif	
		movdw	cxdx, phone
		mov	ax, theSize
		mov	di, DR_MODEM_DIAL
		call	ds:[modemStrategy]		; ax = ModemResultCode
		jnc	connected

if _RESPONDER
		call	PPPUnregisterECI			
		stc					; must translate error
endif

failed:
	;
	; Close port, unload modem driver and return correct error.
	; If carry is not set, don't translate error.
	;
		pushf
		push	ax				; ax = error
		mov	di, DR_MODEM_CLOSE
		call	PPPCloseAndUnloadModem
		pop	ax				
		popf
		jnc	gotError

		mov	bx, ax				; bx = ModemResultCode
		shl	bx				; word index
		mov	ax, cs:errorTable[bx]		
gotError:
		stc
regainAccess:
		pushf
		push	ax
		mov	bx, ds:[taskSem]
		call	ThreadPSem			; carry destroyed
		pop	ax
		popf
		jmp	exit

connected:

if _RESPONDER
		call	PPPLogCallStart
endif ; _RESPONDER

	;
	; get the baud rate after connect
	;
		mov	bx, ds:[port]
		mov	di, DR_MODEM_GET_BAUD_RATE
		call	ds:[modemStrategy]		; ax = baud rate

		mov	ds:[baudRate], ax

	;
	; Check again for cancel.  Hold access after checking.
	; See notes in header for explanation.
	;
		mov	bx, ds:[taskSem]
		call	ThreadPSem

		cmp	ds:[clientInfo].PCI_linkState, PLS_OPENING
		je	exit				; carry clear

		mov	bx, ds:[port]
		mov	di, DR_MODEM_HANGUP
		call	PPPCloseAndUnloadModem
		mov	ax, SDE_INTERRUPTED
		stc
exit:
		.leave
		ret

errorTable	word	\
	0,				; nothing
	SSDE_CALL_FAILED,		; MRC_NOT_SUPPORTED (should never happen)
	SSDE_DEVICE_BUSY, 		; MRC_DRIVER_IN_USE
	SSDE_DEVICE_TIMEOUT,		; MRC_TIMEOUT
	SSDE_CALL_FAILED,		; MRC_UNKNOWN_RESPONSE
	0,				; MRC_OK
	SSDE_DIAL_ERROR,		; MRC_ERROR
	SSDE_LINE_BUSY,			; MRC_BUSY
	SSDE_NO_DIALTONE,		; MRC_NO_DIALTONE
	SSDE_NO_ANSWER,			; MRC_NO_ANSWER
	SSDE_NO_CARRIER,		; MRC_NO_CARRIER
	0,				; MRC_CONNECT
	0,				; MRC_CONNECT_1200
	0,				; MRC_CONNECT_2400
	0,				; MRC_CONNECT_4800
	0,				; MRC_CONNECT_9600
	SSDE_BLACKLISTED, 		; MRC_BLACKLISTED
	SSDE_DELAYED,			; MRC_DELAYED
	SSDE_DIAL_ABORTED		; MRC_DIAL_ABORTED


PPPModemOpen	endp

endif ; not _PENELOPE

if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPConfigurePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Configure serial port's baud rate, flow control, parity,
		extra stop bit, length.  

CALLED BY:	PPPSerialOpen
		PPPModemOpen	

PASS:		bx	= port number 
		ds	= dgroup

RETURN:		nothing

DESTROYED:	ax, cx, di

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPConfigurePort	proc	near

		mov	ax, (SM_RARE shl 8 ) or SerialFormat \
					<0, 0, SP_NONE, 0, SL_8BITS>
		mov	cx, ds:[baud]
		mov	di, DR_SERIAL_SET_FORMAT
		call	ds:[serialStrategy]

		clr	ah
		mov	al, ds:[flowCtrl]
		mov	cx, (mask SMS_CTS shl 8) or mask SMC_RTS
		mov	di, DR_SERIAL_SET_FLOW_CONTROL
		call	ds:[serialStrategy]
		ret
PPPConfigurePort	endp

endif ; not _PENELOPE

if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSetPortNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up data notification for the port.

CALLED BY:	PPPModemOpen
		PPPSerialOpen
		PPPManualLoginComplete

PASS:		ds	= dgroup
		bx	= port
		di	= DR_STREAM_SET_NOTIFY or DR_MODEM_SET_NOTIFY
			  or DR_MODEM_GRAB_SERIAL_PORT

RETURN:		nothing

DESTROYED:	ax, cx, di (allowed)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSetPortNotify	proc	near
		uses	bp
		.enter

		;
		; StreamFunction & ModemFunction have overlapping ranges,
		; so we can't distinguish between them if the values in
		; question aren't distinct.
		;
		CheckHack <DR_MODEM_GRAB_SERIAL_PORT ne DR_STREAM_SET_NOTIFY>
		cmp	di, DR_MODEM_GRAB_SERIAL_PORT
		je	callModem

		mov	cx, ds:[pppThread]

		cmp	di, DR_MODEM_SET_NOTIFY
		jne	notModem

		; If we are using the modem, be sure to ask for the modem 
		; signal notifications as well.
		;
		mov	ax, StreamNotifyType <1, SNE_MODEM_SIGNAL, SNM_MESSAGE>
		mov	bp, MSG_PPP_MODEM_SIGNAL_CHANGE
		call	ds:[modemStrategy]

notModem:
		mov	ax, StreamNotifyType <1, SNE_DATA, SNM_MESSAGE>
		mov	bp, MSG_PPP_HANDLE_DATA_NOTIFICATION

		CheckHack <DR_MODEM_SET_NOTIFY ne DR_STREAM_SET_NOTIFY>
		cmp	di, DR_MODEM_SET_NOTIFY
		jne	doSerial
callModem:
		call	ds:[modemStrategy]
		jmp	done
doSerial:
EC <		cmp	di, DR_STREAM_SET_NOTIFY			>
EC <		ERROR_NE PPP_INTERNAL_ERROR				>	
		call	ds:[serialStrategy]
done:
		.leave
		ret
PPPSetPortNotify	endp

endif ; not _PENELOPE

if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPLoadModemDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the modem driver and get its strategy routine.  Store
		values in dgroup.

CALLED BY:	PPPModemOpen

PASS:		ds	= dgroup

RETURN:		carry set if error

DESTROYED:	ax, bx, si, es

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString	modemName, <"modemec.geo", 0>		>
NEC<LocalDefNLString	modemName, <"modem.geo", 0>		>

PPPLoadModemDriver	proc	near
		uses	ds
		.enter

		segmov	es, ds, ax			; es = dgroup

		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		jc	done

		segmov	ds, cs, si
		mov	si, offset modemName
		mov	ax, MODEM_PROTO_MAJOR
		mov	bx, MODEM_PROTO_MINOR
		call	GeodeUseDriver
EC <		WARNING_C PPP_COULD_NOT_LOAD_MODEM_DRIVER		>
		jc	done

		mov	es:[modemDr], bx

		call	GeodeInfoDriver
		movdw	es:[modemStrategy], ds:[si].DIS_strategy, ax
		clc
done:
		call	FilePopDir		

		.leave
		ret
PPPLoadModemDriver	endp

endif ; not _PENELOPE

if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPResetModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the modem.

CALLED BY:	PPPModemOpen

PASS:		ds	= dgroup
		bx	= port

RETURN:		carry set if failed
			ax	= ModemResultCode

DESTROYED:	di (allowed)
		ax if not returned

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPResetModem	proc	near
		uses	dx
		.enter

	;
	; Reset the modem using ATZ to terminate an existing connection
	; leftover from a previous session or clear up garbage previously
	; sent to the modem.  (Attempts ATZ again if the first time failed.)
	;  (Retry changes: 8/23/99 JimG)
	;
		mov	dx, 2				; num reset retries

resetRetry:
		tst	dx
		jz	skipReset
		dec	dx
		mov	di, DR_MODEM_RESET
		call	ds:[modemStrategy]		; ax = ModemResultCode
EC <		WARNING_C PPP_MODEM_RESET_ERROR			>
		jc	resetRetry

skipReset:
	;
	; Reset the modem to its factory configuration. 
	;
		mov	di, DR_MODEM_FACTORY_RESET
		call	ds:[modemStrategy]		; ax = ModemResultCode
EC <		WARNING_C PPP_MODEM_RESET_ERROR			>

		.leave
		ret
PPPResetModem	endp

endif ; not _PENELOPE

if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStandardModemInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the standard init string to the modem.

CALLED BY:	PPPModemOpen

PASS:		ds	= dgroup
		bx	= port number

RETURN:		carry set if error
		ax	= ModemResultCode

DESTROYED:	cx, dx, di, si, es 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/18/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStandardModemInit	proc	near
		uses	bx, bp
		.enter
	;
	; Look up init string from ini file.
	;
		push	bx, ds
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	cx, ax
		assume	ds:Strings
		mov	dx, ds:[modemInitKey]		; cx:dx = key
		mov	si, ds:[svcCategory]		; ds:si = category
		assume	ds:nothing
		clr	bp				; InitFileReadFlags
		call	InitFileReadString		; bx = handle
							; cx = # of chars
		pop	bp, ds				; bp = port number

		cmc
		jnc	exit				; carry clr if no ini

		clc
		jcxz	freeBlk				; carry cleared
	;
	; Send the init string to the modem.
	;
		mov	si, bx				
		call	MemLock
if DBCS_PCGEOS
		push	es, di, ax
		mov	es, ax
		clr	di
		call	PPPConvertDBCSToSBCS
		pop	es, di, ax
endif
		xchg	cx, ax				; ax = str size
		clr	dx				; cx:dx = init string
		mov	bx, bp				; bx = port number
		mov	di, DR_MODEM_INIT_MODEM
		call	ds:[modemStrategy]
EC <		WARNING_C PPP_MODEM_INIT_ERROR			>

		mov	bx, si
freeBlk:
		pushf
		call	MemFree
		popf
exit:
		mov	bx, handle Strings
		call	MemUnlock			

		.leave
		ret
PPPStandardModemInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPInitV42Compression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable V.42bis compression if it is used.

CALLED BY:	PPPModemOpen

PASS:		ds	= dgroup
		bx	= port number

RETURN:		nothing

DESTROYED:	ax, cx, dx, di, si, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/05/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPInitV42Compression	proc	near
		uses	bx, bp
		.enter
	;
	; Look up init string from ini file.
	;
		push	bx, ds
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	cx, ax
		assume	ds:Strings
		mov	dx, ds:[v42bisKey]		; cx:dx = key
		mov	si, ds:[svcCategory]		; ds:si = category
		assume	ds:nothing
		clr	bp
		call	InitFileReadString		; bx = handle
							; cx = # of chars
		pop	bp, ds				; bp = port number
		jc	exit
		jcxz	freeBlk
	;
	; Send the init string to the modem.
	;
		mov	si, bx
		call	MemLock
if DBCS_PCGEOS
		push	es, di, ax
		mov	es, ax
		clr	di
		call	PPPConvertDBCSToSBCS
		pop	es, di, ax
endif
		xchg	cx, ax				; ax = str size
		clr	dx				; cx:dx = init string
		mov	bx, bp				; bx = port number
		mov	di, DR_MODEM_INIT_MODEM
		call	ds:[modemStrategy]
EC <		WARNING_C PPP_MODEM_INIT_ERROR				>

		mov	bx, si
freeBlk:
		call	MemFree
exit:
		mov	bx, handle Strings
		call	MemUnlock		
		
		.leave
		ret
PPPInitV42Compression	endp

endif ; not _PENELOPE

if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPInitializeModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look up modem initialization string in access point database
		and initialize modem with it.

CALLED BY:	PPPModemOpen

PASS:		ax	= access ID
		ds	= dgroup
		bx	= unit

RETURN: 	ax	= ModemResultCode
		carry set if error

DESTROYED:	cx, dx, di, si, es (allowed by caller)

PSEUDO CODE/STRATEGY:
		Look up initialization string in accpnt database
		if none, exit
		else initialize modem

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/27/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPInitializeModem	proc	near
		uses	bx, bp
		.enter
	;
	; Look up initialization string.  
	;
		push	bx
		clr	cx, bp				; alloc a buf
		mov	dx, APSP_MODEM_INIT
		call	AccessPointGetStringProperty	; cx = str len
		pop	dx				; dx = port number
		jc	noInit
		jcxz	freeBlk
if DBCS_PCGEOS
	;
	; The modem init string (^hbx) is DBCS.  We need to convert it
	; to SBCS and make sure cx has the correct SIZE.
	;
		push	ax, es, di
		call	MemLock
		mov	es, ax
		mov	di, 0				; es:di = DBCS
		call	PPPConvertDBCSToSBCS		; es:di = SBCS
		call	MemUnlock
		pop	ax, es, di
endif

		push	bx				; save block handle
		call	MemLock
		mov	bx, dx				; bx = port number
		xchg	cx, ax				; ax = str size
		clr	dx				; cx:dx = init string
		mov	di, DR_MODEM_INIT_MODEM
		call	ds:[modemStrategy]		; ax = ModemResultCode
EC <		WARNING_C PPP_MODEM_INIT_ERROR			>
		pop	bx
freeBlk:
		pushf
		call	MemFree
		popf
exit:
		.leave
		ret

noInit:
		clc
		jmp	exit

PPPInitializeModem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPOtherInitializeModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look up other modem initialization options.

CALLED BY:	PPPModemOpen

PASS:		ax	= access ID
		ds	= dgroup
		bx	= unit

RETURN: 	ax	= ModemResultCode
		carry set if error

DESTROYED:	cx, dx, di, si, es (allowed by caller)

PSEUDO CODE/STRATEGY:
		Look up initialization string in accpnt database
		if none, exit
		else initialize modem

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	brianc	1/24/00			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPOtherInitializeModem	proc	near
		uses	bx, bp
		.enter
	;
	; Check if we need this
	;
		sub	sp, size AccessPointDialingOptions
		mov	dx, sp
		mov	cx, ss
		call	AccessPointGetDialingOptions
		mov	bp, dx
		mov	al, ss:[bp].APDO_waitForDialtone
		add	sp, size AccessPointDialingOptions
		tst_clc	al
		jnz	exit				; carry clear
	;
	; Look up init string from ini file.
	;
		push	bx, ds
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	cx, ax
		assume	ds:Strings
		mov	dx, ds:[dialtoneKey]		; cx:dx = key
		mov	si, ds:[svcCategory]		; ds:si = category
		assume	ds:nothing
		clr	bp				; InitFileReadFlags
		call	InitFileReadString		; bx = handle
							; cx = # of chars
		pop	bp, ds				; bp = port number

		cmc
		jnc	done				; carry clr if no ini

		clc
		jcxz	freeBlk				; carry cleared
	;
	; Send the init string to the modem.
	;
		mov	si, bx				
		call	MemLock
if DBCS_PCGEOS
		push	es, di, ax
		mov	es, ax
		clr	di
		call	PPPConvertDBCSToSBCS
		pop	es, di, ax
endif
		xchg	cx, ax				; ax = str size
		clr	dx				; cx:dx = init string
		mov	bx, bp				; bx = port number
		mov	di, DR_MODEM_INIT_MODEM
		call	ds:[modemStrategy]
EC <		WARNING_C PPP_MODEM_INIT_ERROR			>

		mov	bx, si
freeBlk:
		pushf
		call	MemFree
		popf
done:
		mov	bx, handle Strings
		call	MemUnlock			
exit:
		.leave
		ret
PPPOtherInitializeModem	endp

endif ; not _PENELOPE

if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPCloseAndUnloadModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the modem port and unload the modem driver.
		Hangup first if caller wants us to.

CALLED BY:	PPPModemOpen 
		PPPDeviceClose	

PASS:		ds	= dgroup
		bx	= port 
		di	= DR_MODEM_HANGUP (if hangup, desired)
			  DR_MODEM_CLOSE (if can close without hangup)
			  0 to unload without close or hangup

RETURN:		nothing

DESTROYED:	ax, bx, di (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPCloseAndUnloadModem	proc	near

	;
	; Hangup and close only if needed.
	;
		tst	di
		je	unload

		cmp	di, DR_MODEM_HANGUP
		jne	closePort
if _RESPONDER
	;
	; If call already ended, don't send hangup command, 'cause
	; it might hang up someone else's call
	; (see PPPECINotification)
	;
		tst	ds:[callEnded]
		jnz	logCall
endif ; _RESPONDER

		call	ds:[modemStrategy]
EC <		WARNING_C PPP_MODEM_HANGUP_ERROR			>

if _RESPONDER
logCall:
		call	PPPLogCallEnd
endif ; _RESPONDER

closePort:
		mov	ax, STREAM_DISCARD
		mov	di, DR_MODEM_CLOSE
		call	ds:[modemStrategy]

unload:
		clr	bx		
		movdw	ds:[modemStrategy], bxbx
		xchg	bx, ds:[modemDr]
		call	GeodeFreeDriver

		ret
PPPCloseAndUnloadModem	endp

endif ; not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPUIPromptPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog to query the user for the password.
		NOTE: This MUST be called by the UI thread created by PPP.

CALLED BY:	MSG_PPP_UI_PROMPT_PASSWORD
PASS:		*ds:si	= PPPPasswordClass object
		^hdx	= username block
		cx	= length
		bp	= accpnt ID

RETURN:		carry set if user cancelled 
		else
		^hcx 	= password
		ax	= size (excluding null terminator)

DESTROYED:	dx, bp

PSEUDO CODE/STRATEGY:
		Create dialog.
		Fill in username in dialog.
		UserDoDialog and wait for response.
		if okay
			Get password in block and its size
		else
			set carry
		Destroy dialog.
		Queue detach message for calling thread. 


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	11/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPUIPromptPassword	method dynamic PPPUIClass, 
					MSG_PPP_UI_PROMPT_PASSWORD
	;
	; Create the dialog.
	;
		mov	bx, handle PasswordDialog
		mov	si, offset PasswordDialog
		call	UserCreateDialog		; ^lbx:si = dialog
	;
	; Fill in username.
	;
		push	si, bp
		mov	si, offset UsernameText		; ^lbx:si = text obj
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	si, ax				; ^lbx:si = dialog
							; ax = accpnt ID
	;
	; Fill in provider name.
	;
		push	bx
		clr	cx, bp				; alloc a block
		mov	dx, APSP_NAME
		call	AccessPointGetStringProperty	; cx = str len
		mov_tr	dx, bx				; ^hdx = string
		pop	bx
		jc	afterName

		push	si, dx
		mov	si, offset ProviderText		; ^lbx:si = text obj
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	si, dx

		xchg	bx, dx				
		call	MemFree
		mov_tr	bx, dx				; ^lbx:si = dialog
afterName:
	;
	; Start timer to bring down dialog if user doesn't respond in the
	; given amount of time.
	;
		call	PPPStartPasswordTimer		; cx = timer ID
							; dx = timer handle
	;
	; Bring up dialog and wait for response.  Stop timer after response.
	;
		call	UserDoDialog			; ax = response

		xchg	bx, dx				; bx = timer handle
		xchg	ax, cx				; ax = timer ID
		call	TimerStop
		mov_tr	ax, cx				; ax = response
		mov_tr	bx, dx				; ^lbx:si = dialog

		CheckHack <IC_DISMISS lt IC_APPLY>
		cmp	ax, IC_APPLY
		jne	destroy				; carry set by cmp
	;
	; Get user entered password into a block.
	;
		push	si
		mov	si, offset PasswordText
		clr	dx				; alloc a block
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		mov	di, mask MF_CALL
		call	ObjMessage			; ^hcx = password
							; ax = length (no null)
DBCS <		shl	ax				; ax = size	>
		pop	si
		clc
destroy:
	;
	; Destroy the dialog and this thread.
	;
		pushf
		call	UserDestroyDialog

		push	cx, ax
		mov	bx, ss:[TPD_threadHandle]
		clr	cx, dx, bp			; no ack needed
		mov	ax, MSG_META_DETACH
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	cx, ax
		popf
done::
		ret
PPPUIPromptPassword	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPUIWarnDiskspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display dialog warning user about low memory and ask
		if user wants to continue or cancel.

		NOTE: Must be called by UI thread created by PPP.
		Thread will be destroyed at end of handler.

CALLED BY:	MSG_PPP_UI_WARN_DISKSPACE
PASS:		*ds:si	= PPPUIClass object
		ds:di	= PPPUIClass instance data
		ds:bx	= PPPUIClass object (same as *ds:si)
		es 	= segment of PPPUIClass
		ax	= message #
RETURN:		ax	= IC_YES to continue
DESTROYED:	cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	8/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPUIWarnDiskspace	method dynamic PPPUIClass, 
					MSG_PPP_UI_WARN_DISKSPACE

if _RESPONDER
	;
	; Create standard question dialog and get response.
	;
		mov	cx, handle PPPDiskspaceString
		mov	dx, offset PPPDiskspaceString
		call	FoamDisplayQuestion	; ax = IC_YES to continue
endif ; _RESPONDER

	;
	; Destroy the thread.
	;
		push	ax
		mov	bx, ss:[TPD_threadHandle]
		clr	cx, dx, bp			; no ack needed
		mov	ax, MSG_META_DETACH
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	ax

		ret
PPPUIWarnDiskspace	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStartPasswordTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the timer which will bring down the password dialog
		if the user does not respond in the given amount of time.

CALLED BY:	PPPPromptPassword

PASS:		^lbx:si	= password dialog

RETURN:		cx	= timer ID
		dx	= timer handle

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:
		Send MSG_GEN_TRIGGER_SEND_ACTION to the cancel trigger
		to make the timeout have the same effect as the user 
		selecting Cancel.  Trigger does not have a double press
		action message so the trigger will send out its	action 
		message regardless of the value in CL.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/15/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStartPasswordTimer	proc	near
		uses	ax, bx, si
		.enter

		mov	al, TIMER_EVENT_ONE_SHOT
		mov	si, offset PasswordCancelTrigger
		mov	cx, PPP_PASSWORD_PROMPT_TIMEOUT
		mov	dx, MSG_GEN_TRIGGER_SEND_ACTION
		call	TimerStart

		mov_tr	cx, ax				; cx = timer ID
		mov_tr	dx, bx				; dx = timer handle

		.leave
		ret
PPPStartPasswordTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPCheckAccpnt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the access point ID type is either APT_INTERNET
		or APT_APP_LOCAL.

CALLED BY:	PPPSetAccessInfo
		PPPDeviceOpen

PASS:		ax	= access point ID (0 if none)

RETURN:		carry clear if accpnt is valid
		ax	= SpecSocketDrError
				(SSDE_INVALID_ACCPNT)

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/27/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPCheckAccpnt	proc	near
		uses	bx
		.enter

		tst_clc	ax
		jz	exit

		call	AccessPointGetType		; bx = AccessPointType

		tst_clc	bx
		jz	badAccpnt

		cmp	bx, APT_INTERNET
		je	exit				; carry clear

		cmp	bx, APT_APP_LOCAL
		je	exit				; carry clear
badAccpnt:
		mov	ax, SSDE_INVALID_ACCPNT
		stc
exit:
		.leave
		ret
PPPCheckAccpnt	endp


if _SEND_NOTIFICATIONS

COMMENT |------------------------------------------------------------------

			 NOTIFICATIONS 

--------------------------------------------------------------------------|


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPNotifyMediumConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a system notification about the medium being connected.

CALLED BY:	PPPLINKOPENED

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

NOTE:		Caller has taskSem held so it's safe to modify the status.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/ 1/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPNotifyMediumConnected	proc	near
		uses	ax, bx, cx, dx, di, si
		.enter
	;
	; If we haven't done so already, notify the system that the link 
	; is open. Remember that notification has been sent.
	;
		test	ds:[clientInfo].PCI_status, mask CS_MEDIUM_CONNECTED
		jnz	exit				; already notified

if _PENELOPE
	; 
	; For PENELOPE, the medium is GMID_CELL_MODEM and unit is 0.
	;
		clr	bx				; bx = unit number
		mov	dx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GMID_CELL_MODEM		; dxax = MediumType
else
		clr	cx
		mov	di, DR_SERIAL_GET_MEDIUM
		mov	bx, ds:[port]			; bx = unit number
		call	ds:[serialStrategy]		; dxax = MediumType
		jc	exit
endif

EC <		cmp	dx, ManufacturerID				>
EC <		WARNING_A SERIAL_DRIVER_RETURNED_INVALID_MANUFACTURER_ID>

		BitSet	ds:[clientInfo].PCI_status, CS_MEDIUM_CONNECTED

		movdw	ds:[mediumType], dxax		; save it for closing
		mov	cx, dx
		mov	dx, ax				; cxdx = MediumType
	;
	; XXX: Assumes MUT_INT if not GMID_CELL_MODEM!
	;
		mov	al, MUT_INT
		cmp	dx, GMID_CELL_MODEM
		jne	gotType	
		mov	al, MUT_NONE
gotType:

if _SEND_MEDIUM_NOTIFICATIONS
		mov	si, SST_MEDIUM
		mov	di, MESN_MEDIUM_CONNECTED
		call	SysSendNotification		
endif 	; _SEND_MEDIUM_NOTIFICATIONS

if _SEND_SOCKET_NOTIFICATIONS
		mov	si, SST_SOCKET
		mov	di, SSN_LINK_CONNECTED
		call	SysSendNotification		
endif 	; _SEND_SOCKET_NOTIFICATIONS

exit:
		.leave
		ret
PPPNotifyMediumConnected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPNotifyMediumDisconnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a system notification about the medium no longer
		being connected.

CALLED BY:	PPPLINKCLOSED

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

NOTE:		Caller has taskSem held so it's safe to modify the status.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/ 1/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPNotifyMediumDisconnected	proc	near
		uses	ax, bx, cx, dx, di, si
		.enter
	;
	; Notify the system that the link is closed.  Only send 
	; notification if medium connected notification had been sent.
	;
		clrdw	cxdx
		xchgdw	cxdx, ds:[mediumType]

		test	ds:[clientInfo].PCI_status, mask CS_MEDIUM_CONNECTED
		jz	exit			; never notified of open
		BitClr	ds:[clientInfo].PCI_status, CS_MEDIUM_CONNECTED

EC <		tst	dx						>
EC <		ERROR_Z	PPP_INTERNAL_ERROR	; medium should be set!	>
	;
	; XXX: Assumes MUT_INT if not GMID_CELL_MDOEM.
	;
		mov	al, MUT_INT
		cmp	dx, GMID_CELL_MODEM
		jne	gotType
		mov	al, MUT_NONE
gotType:

if _PENELOPE
	;
	; For PENELOPE, medium is GMID_CELL_MODEM and Unit is 0.
	;
		clr	bx			; unit = 0
else
		mov	bx, ds:[port]
endif

if _SEND_MEDIUM_NOTIFICATIONS
		mov	si, SST_MEDIUM
		mov	di, MESN_MEDIUM_NOT_CONNECTED
		call	SysSendNotification
endif 	; _SEND_MEDIUM_NOTIFICATIONS

if _SEND_SOCKET_NOTIFICATIONS
		mov	si, SST_SOCKET
		mov	di, SSN_LINK_NOT_CONNECTED
		call	SysSendNotification
endif 	; _SEND_SOCKET_NOTIFICATIONS

exit:
		.leave
		ret
PPPNotifyMediumDisconnected	endp

endif ; _SEND_NOTIFICATIONS

ConnectCode		ends

COMMENT |------------------------------------------------------------------
			MANUAL LOGIN CODE

--------------------------------------------------------------------------|

if not _PENELOPE

if LOGIN_PROTOCOL ne 1
; If the external login API changes, change the code to support it, then
; update this message.
PrintMessage <PPP only supports login server protocol 1>
endif

idata	segment

	;
	; IACP connection PPP driver uses to send notifications to
	; manual login application
	;
	loginConnection	IACPConnection	0

idata	ends

udata	segment

	;
	; Current phone number to dial & it's length
	;
	pppAddr		byte MAX_PHONE_NUMBER_LENGTH dup (?)
	pppAddrSize	word

	;
	; GeodeToken of manual login app
	;
	loginToken	GeodeToken	<>

	;
	; PPP signature FSM state
	;
	loginState	nptr.FSMTransition

	;
	; Small buffer to store PPP signature as we recognize it
	;
	loginData	char 6 dup (?)
	loginDataPos	nptr.char

	;
	; size of PPP data recognized
	;
	pppDataSize	word

udata	ends

endif ; not _PENELOPE

ConnectCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPGetLoginMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the login mode for the access point.

CALLED BY:	PPPSetAccessInfo

PASS:		ax	= accpnt ID
		ds	= dgroup

RETURN:		carry set if login mode configured incorrectly
			ax	= SpecSocketDrError
					(SSDE_NO_LOGIN_APP)
		otherwise ax unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Query the access point library for the login mode.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PPPGetLoginMode	proc	near

if not _PENELOPE

		uses	ax, bx, cx, dx, bp, ds, es, di, si
		.enter

		BitClr	ds:[clientInfo].PCI_status, CS_MANUAL_LOGIN

		segmov	es, ds, dx			; es=dgroup (for later)

		mov_tr	cx, ax
		mov	bx, handle Strings
		call	MemLock				; ax = Strings segment
		mov	ds, ax				; ds = Strings
		xchg	ax, cx				; cx=Strings, ax=accpnt
	;
	; See if manual login desired
	;
		push	ax
		mov	dx, ds:[offset useManualLoginKey]
		call	AccessPointGetIntegerProperty	; carry if not found
		mov_tr	cx, ax				; cx = value
		pop	ax				; ax = accpt ID

		cmc					; carry clear if
		jnc	exit				;   not found
		clc					; return no error
		jcxz	exit				;   if not manual login
	;
	; Try to get manual login name from access point
	;
		mov	cx, ds
		mov	dx, ds:[offset manualLoginKey]  ; cx:dx = key
		clr	bp			        ; allocate block
		call	AccessPointGetStringProperty	; ^hbx = buffer
		jnc	setLoginApp			;   cx = length
	;
	; Not in access point, use default from PPP category
	;
		mov	cx, ds			; cx:dx = key
		mov	si, ds:[offset pppCategory]	; ds:si = ppp cat
		call	InitFileReadString		; ^hbx = buffer
							;   cx = length
		jc	exit			; Abort if error

setLoginApp:	; ^hbx = login app name
		;   cx = name length (not including NULL)
		; ds = Locked Strings segment
		; es = dgroup
	;
	; Have name of login app. We're going to use it to fetch
	; the associated GeodeToken.  But first, we must make sure
	; it is acceptable to use as an INI key.
	;
		push	bx			; save name buffer
		push	es, ds			; save dgroup/Strings segs
	;
	; Expand name buffer to hold canonicalized key...
	;   (need additional 2 * length in SBCS or DBCS, so just increase
	;	 to 4 times original length)
	;
		inc	cx			; add NULL
		shl	cx, 1
		push	cx
		mov_tr	ax, cx
		shl	ax, 1			; ax = length * 4
		mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
		call	MemReAlloc		; ax = segment
	;
	; ... and canonicalize
	;
		mov	ds, ax
		clr	si			; ds:si = login app name
		mov	es, ax
		pop	di			; es:di = buffer for
						;  canonicalized key
		call	InitFileMakeCanonicKeyCategory
	;
	; Use canonicalized string as actual key for GeodeToken lookup
	;
		pop	es, ds			; restore dgroup/Strings segs
		mov	cx, ax
		mov	dx, di			; cx:dx = login app key
		mov	si, ds:[offset manualLoginCategory] ; ds:si = category
		mov	di, offset loginToken	; es:di = GeodeToken buffer
		mov	bp, size loginToken
		call	InitFileReadData	; cx = data length
		jc	exitCleanStack		; if not found
		cmp	cx, size loginToken	; sets carry
		jb	exitCleanStack		;    if <
	;
	; Flag client as being a manual login client
	;
		BitSet	es:[clientInfo].PCI_status, CS_MANUAL_LOGIN
		clc				; Config was OK.
exitCleanStack:
		lahf				; store error condition
		pop	bx			; ^hbx = app name buffer
		call	MemFree
		sahf
exit:
	;
	; Unlock strings resource
	;
		mov	bx, handle Strings
		call	MemUnlock		; (preserves carry)

		.leave				; (restore ax=access point)
	;
	; If error, load error code into ax
	;
		jnc	haveError
		mov	ax, SSDE_INVALID_ACCPNT
haveError:

else ; not _PENELOPE

		clc

endif ; not _PENELOPE

		ret

PPPGetLoginMode	endp


if not _PENELOPE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPLoginCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for Term to have PPP check input data
		and for Term to notify PPP of a terminated/completed
		login process.

CALLED BY:	Term via PPPStartManualLogin's callback

PASS:		cx = # bytes of data in buffer
		bx = LAI_connection token
		dx:bp = input data to check for PPP data

RETURN:		carry set to end login process
		cx	= number of bytes of Term data in buffer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		If state set to closing, return carry set to end
			login process

		Else
			check input for PPP data, looking for the 
			sequence: 7E, FF, 03 (flag, address, control)
			Remember what has been seen.  When confirmed, 
			insert these 3 bytes into inputBuffer and copy
			any other data after them.
			Return Stop to Term.


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPLoginCallback	proc	far

	uses	ax,bx,dx,si,di,bp,ds
	.enter
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS		; ds = dgroup
	;
	; Grab the client info for duration of callback
	;
		mov	bx, ds:[taskSem]
		push	ax
		call	ThreadPSem
		pop	ax
		pop	bx
	;
	; Make sure callback being called for one of our connections
	;
		cmp	bx, ds:[clientInfo].PCI_accpnt
EC <		ERROR_NE PPP_INVALID_MANUAL_LOGIN_CONNECTION		>
		jne	doneContinue

		jcxz	doneContinue
	;
	; If anything but LOGIN state, just tell app to stop.
	;
		cmp	ds:[clientInfo].PCI_linkState, PLS_LOGIN
		stc
		jne	done
	;;
	;; Scan input buffer for PPP signature
	;;
		call	PPPScanForPPPData	; cx, carry set appropriately
		jmp	done
doneContinue:
		clc
done:
		mov	bx, ds:[taskSem]
		call	ThreadVSem		; doesn't trash flags

		.leave
		ret

PPPLoginCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPScanForPPPData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scans input stream for PPP signature bytes
		7E, FF, 03.  If found, sends it to input thread
		for handling, and starts the negotiation phase.

CALLED BY:	PPPLoginCallback

PASS:		ds = dgroup
		cx = # bytes of data in buffer
		dx:bp = input buffer to check for PPP data
		taskSem grabbed

RETURN:		carry set to end if data found
		cx	= number of bytes of Term data in buffer
			 (unchanged if data not found)
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

	Because each byte could be replaced with an <escape, escaped byte>
	pair, the FSM for the actual string we must recognize
	has 7 states, 7 "interesting" input characters, and
	about 18 transitions.  Each state is a linked
	list of FSMTransitions, and we'll keep track of what state we're
	currently in by keeping a pointer to the head of the state's
	transition list.

	The FSM recognizes the string (anywhere in the input stream):

		(A|ZD)(B|ZE)(C|ZF)

	Where:

		A = 7E
		B = FF
		C = 03
		Z = 7D (the PPP escape byte)
		D = 5E (escaped value of A)
		E = DF (escaped value of B)
		F = 23 (escaped value of C)

BUGS/TODO:
		data buffer cannot be larger than PPP input buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; PppRecognitionState nodes for FSM
;

; transition name     <matching input,	new state, transition fn, next trans>
;----------------------------------------------------------------------------

prsI	FSMTransition <PPP_FLAG,	prsF,	sfdOutput,	prsI1	>
 prsI1	FSMTransition <PPP_ESCAPE,	prsFE,	sfdOutput,	NULL	>

prsFE	FSMTransition <PPP_FE,		prsF,	sfdOutput,	prsFE1	>
 prsFE1	FSMTransition <PPP_ESCAPE,	prsFE,	sfdNext,	prsFE2	>
 prsFE2	FSMTransition <PPP_FLAG,	prsF,	sfdResetOutput,	NULL	>

prsF	FSMTransition <PPP_ALLSTATIONS,	prsA,	sfdOutput,	prsF1	>
 prsF1	FSMTransition <PPP_ESCAPE,	prsAE,	sfdOutput,	prsF2	>
 prsF2	FSMTransition <PPP_FLAG,	prsF,	sfdNext,	NULL	>

prsAE	FSMTransition <PPP_AE,		prsA,	sfdOutput,	prsAE1	>
 prsAE1	FSMTransition <PPP_ESCAPE,	prsFE,	sfdResetOutput,	prsAE2	>
 prsAE2	FSMTransition <PPP_FLAG,	prsF,	sfdResetOutput,	prsAE3	>
 prsAE3 FSMTransition <PPP_FE,		prsF,	sfdEscOutput,	NULL	>

prsA	FSMTransition <PPP_UI,		NULL,	sfdOutput,	prsA1	>
 prsA1	FSMTransition <PPP_ESCAPE,	prsUE,	sfdOutput,	prsA2	>
 prsA2	FSMTransition <PPP_FLAG,	prsF,	sfdResetOutput,	NULL	>

prsUE	FSMTransition <PPP_UE,		NULL,	sfdOutput,	prsUE1	>
 prsUE1	FSMTransition <PPP_ESCAPE,	prsFE,	sfdResetOutput,	prsUE2	>
 prsUE2	FSMTransition <PPP_FLAG,	prsF,	sfdResetOutput,	prsUE3	>
 prsUE3 FSMTransition <PPP_FE,		prsF,	sfdEscOutput,	NULL	>

;
; When nothing matches, use this transition
;
dftTran FSMTransition <0,		prsI,	sfdReset,	NULL	>

PPPScanForPPPData	proc	near
	uses	ax, bx, dx, bp, es, ds, di, si
	.enter

EC <		tst	cx						>
EC <		ERROR_Z PPP_INTERNAL_ERROR				>
		jcxz	doNothing

		segmov	es, ds, di		; es = dgroup
		mov	ds, dx
		mov	si, bp			; ds:si = input
		mov	bp, es:[loginState]	; *cs:bp = State
		mov	di, es:[loginDataPos]	; es:di = output bufer
		mov	dx, cx

	; REGISTER USAGE IN FSM
	;	cs:bp	= FSMTransition (bp=0 == exit state)
	;	ds:si	= input buffer
	;	es:di	= next position in output buffer (loginData)
	;	cx	= input length remaining
	;	dx	= original input length

sfdNext		label	near
	;
	; If reached end of machine, we found the data.
	;
		tst	bp
		jz	foundData
	;
	; If ran out of input buffer, we didn't match the pattern yet.
	;
		jcxz	notFound
	;
	; Try to match one of the transitions' inputs
	;
		dec	cx
		lodsb				; al = input
transLoop:
		cmp	al, cs:[bp].FSMT_input
		je	useTrans
		mov	bp, cs:[bp].FSMT_next
		tst	bp
		jnz	transLoop
	;
	; No transition matched.  Use the default to go back to the initial
	; state;
	;
		mov	bp, offset dftTran
useTrans:
	;
	; Move to the new state, with al = input character
	;
		mov	bx, cs:[bp].FSMT_action
		mov	bp, cs:[bp].FSMT_newState
	;
	; And execute the action associated with the transition.
	;
		jmp	bx

notFound:
	;
	; If exiting without matching the pattern, update the FSM state
	; and output buffer, then return the original input buffer
	; length.
	;
		mov	es:[loginState], bp
		mov	es:[loginDataPos], di
		mov	cx, dx
doNothing:
		clc
done:
		.leave
		ret

	;;--------------------------------------------------
	;;
	;; TRANSITION ACTIONS used in the FSM.
	;;   passed:		al = input byte
	;;   can destroy:	ax, bx
	;; Should jmp to sfdNext when done
	;;

sfdEscOutput	label	near
	;
	; Reset the output position, write a
	; PPP_ESC to the output, then copy the
	; input to the output
	;
		mov	{byte}es:[loginData], PPP_ESCAPE
		mov	di, offset loginData + 1
		jmp	sfdOutput

sfdResetOutput	label	near
	;
	; Reset the output position before copying
	; input to output
	;
		mov	di, offset loginData

sfdOutput	label	near
	;
	; copy input to output
	;
		stosb				; output buffer <- input byte
		jmp	sfdNext

sfdReset	label	near
	;
	; Reset output position
	;
		mov	di, offset loginData
		jmp	sfdNext

	;;--------------------------------------------------
foundData:
	;;
	;; We found the data.  Copy the PPP data into the input buffer
	;;
	;; es			= dgroup
	;; es:loginData		= recognized data
	;; di - loginData	= data length
	;; cx			= # bytes left in input buffer
	;; ds:si		= remainder of login app's input buffer
	;; dx			= input buffer original length

		push	es			; +1 : save dgroup
		push	ds, si			; +2 : save login input buffer
		push	cx			; +3 : save buffer length
		mov	bx, es:[inputBuffer]
		segmov	ds, es, bp
		mov	si, offset loginData	; ds:si = recognized data
	;
	; If PPP data is larger than input buffer, enlarge input buffer
	;
		add	cx, di
		sub	cx, offset loginData
		mov	ax, MGIT_SIZE
		call	MemGetInfo		; ax = size
		cmp	cx, ax
		jb	bigEnough

		mov	bp, cx			; bp = input buffer size
		mov	ax, cx			; ax = desired size
		mov	ch, mask HAF_LOCK
		call	MemReAlloc		; ax = seg, carry = error
		jnc	inputLocked
	;
	; Couldn't realloc.  Truncate input to fit in existing buffer.
	;
		pop	cx			; -3 : throw out input size
		add	bp, offset loginData
		sub	bp, di		 	; size -= (di-loginData)
		add	dx, offset loginData
		sub	dx, di		 	; total size -= (di-loginData)
		push	bp			; +3 : store truncated size
bigEnough:
		call	MemLock
inputLocked:
		mov	es, ax
		mov	cx, di
		sub	cx, offset loginData
		clr	di			; es:di = inputBuffer
	;
	; Copy the recognized data
	;
		rep	movsb
	;
	; Copy the remainder of the input buffer
	;
		pop	cx			; -3 : cx = input length
		pop	ds, si			; -2 : ds:si = input buffer
		rep	movsb			; di = size of data

		call	MemUnlock
	;
	; Stuff size of PPP data into var to be picked up when
	; we get the LOGIN_COMPLETE response.
	;
		pop	ds			; -1 : Restore dgroup
		mov	ds:[pppDataSize], di
	;
	; Figure out how much of buffer was non-ppp data
	;
		sub	dx, di
		jae	returnStop
		clr	dx			; pattern started in previous
						; buffer, so cx > dx
returnStop:
		mov_tr	cx, dx			; return non-PPP length
		stc
		jmp	done

PPPScanForPPPData	endp

endif ; not _PENELOPE



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStartManualLogin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin the manual login process.

CALLED BY:	PPPOpenLink

PASS:		ds	= dgroup

RETURN:		carry set if couldn't initiate login sequence
			ax = SpecSocketDrError (SSDE_NO_LOGIN_APP)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		notify Term via IACP and MSG_META_NOTIFY_WITH_DATA_BLOCK
		to start the login process

			Pass Term:  port number,
				    serial strategy 
				    vfptr to callback

			Callback:
		  	  Pass:	bx = connection handle

				If cx = zero 
				   ax = LoginStatusNotification
				- else - 
				   cx = # bytes of data in buffer
				   dx:bp = input data to check for PPP data
			  Return:
				carry set if PPP data confirmed (login done)
				cx = bytes of Term data in buffer
				buffer contents unchanged


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStartManualLogin	proc	near
if not _PENELOPE

	uses	bx, cx, dx, bp, si, di, es
	.enter

		mov	bp, ds:[loginConnection]
		tst	bp
EC <		WARNING_Z PPP_MANUAL_LOGIN_ERROR			>
		LONG	jz	errorWithConnection
	;
	; Initialize PPP recognition FSM
	;
		mov	ds:[loginState], offset prsI ; = Initial state
		mov	ds:[loginDataPos], offset loginData
		clr	ds:[pppDataSize]
	;
	; Setup LoginAttach params to pass to login server
	;
		mov	ax, size LoginAttachInfo
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		mov	bx, handle geos
		call	MemAllocSetOwner	; bx <- handle
					; ax <- address
		mov	es, ax

		movdw	es:[LAI_strategy], ds:[serialStrategy], ax

		mov	ax, ds:[port]
		mov	es:[LAI_port], ax

		mov	ax, ds:[clientInfo].PCI_accpnt ; access point for link
		mov	es:[LAI_connection], ax ; use accpnt as connection ID

		mov	ax, handle PPPLoginCallback
		GetVSEG	ax
		mov	es:[LAI_callback].handle, ax
		mov	es:[LAI_callback].offset, offset PPPLoginCallback

	; Send completion of login notification back to us

		mov	ax, ds:[pppThread]
		mov	es:[LAI_responseOptr].handle, ax
		clr	es:[LAI_responseOptr].chunk
		mov	es:[LAI_responseMsg], MSG_PPP_MANUAL_LOGIN_COMPLETE
		
		call	MemUnlock
	;
	; Prepare block to be sent in MSG_META_NOTIFY
	;
		mov	ax, 1
		call	MemInitRefCount
	;
	; Record the notification event
	;
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_LOGIN_ATTACH
		mov	bp, bx		; ^hbp <- data block
		mov	bx, segment MetaClass
		mov	si, offset MetaClass
		mov	di, mask MF_RECORD
		call	ObjMessage	; di <- message
	;
	; And deliver the event to the login server
	;
		mov	bx, di
		mov	bp, ds:[loginConnection]
		mov	dx, TO_SELF
		clr	cx		; no completion message
		mov	ax, IACPS_CLIENT
		call	IACPSendMessage	; ax <- # receivers
		tst	ax			; carry clear
EC <		ERROR_Z PPP_MANUAL_LOGIN_ERROR				>
		jz	errorWithConnection
done:
	.leave
	ret

errorWithConnection:
	;
	; there is a connection, but something is wrong with it
	;
		mov	bp, ds:[loginConnection]
		clr	cx
		call	IACPShutdown

		clr	ds:[loginConnection]
		mov	ax, SSDE_LOGIN_FAILED
		stc
		jmp	done

else ; not _PENELOPE
		ret

endif ; not _PENELOPE

PPPStartManualLogin	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPInitManualLogin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell login app to initialize itself.

CALLED BY:	PPPOpenLink

PASS:		ds	= dgroup
		ss:bp	= address
		cx	= address size

RETURN:		carry set if couldn't initiate login sequence
			ax = SpecSocketDrError (SSDE_NO_LOGIN_APP)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPInitManualLogin	proc	near
if not _PENELOPE

	uses	bx, cx, dx, bp, si, di, es
	.enter

		tst	ds:[loginConnection]
EC <		WARNING_NZ PPP_MANUAL_LOGIN_ERROR			>
		LONG	jnz	errorWithConnection
	;
	; Stuff passed address in global var, to be used later,
	; in MSG_PPP_MANUAL_LOGIN_INIT_COMPLETE
	;
		cmp	cx, MAX_PHONE_NUMBER_LENGTH
		jbe	storeAddr
		mov	cx, MAX_PHONE_NUMBER_LENGTH
storeAddr:
		mov	ds:[pppAddrSize], cx

		segmov	es, ds
		mov	di, offset pppAddr	; es:di = dest variable
		segmov	ds, ss
		mov	si, bp			; ds:si = passed addr
		rep	movsb

		segmov	ds, es			; ds = dgroup
	;
	; make IACP connection to talk to term app
	;
		mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACPCreateDefaultLaunchBlock  ; ^hdx = AppLaunchBlock
EC <		ERROR_C	PPP_MANUAL_LOGIN_ERROR				>
		mov	ax, SSDE_LOGIN_FAILED
		LONG    jc	done
	;
	; Don't immediately bring the app up, because it might have
	; to make itself presentable first.
	;
		mov	bx, dx
		call	MemLock			; ax <- ALB
		mov	es, ax
		ornf	es:[ALB_launchFlags], mask ALF_OPEN_IN_BACK or \
					      mask ALF_DO_NOT_OPEN_ON_TOP
		call	MemUnlock
	;
	; Create connection to login app
	;
		segmov	es, ds, di
		mov	di, offset loginToken
		mov	ax, mask IACPCF_FIRST_ONLY or \
			(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
		call	IACPConnect	; bp <- IACPConnection
					; ax, bx, cx <- destroyed
		mov	ax, SSDE_LOGIN_FAILED
		LONG_EC jc	done

		mov	ds:[loginConnection], bp
	;
	; Setup LoginInit params to pass to login server.  Make owned
	; by kernel, in case this thread goes away while the login app
	; is playing with it.
	;
		mov	ax, size LoginInitInfo
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		mov	bx, handle geos
		call	MemAllocSetOwner ; bx <- handle
					; ax <- address
		mov	es, ax
		mov	es:[LII_protocol], LOGIN_PROTOCOL

		mov	ax, ds:[clientInfo].PCI_accpnt ; access point for link
		mov	es:[LII_accessPoint], ax

		mov	es:[LII_connection], ax ; use accpnt as connection ID

	; Send completion of intitialization back to us

		mov	ax, ds:[pppThread]
		mov	es:[LII_responseOptr].handle, ax
		clr	es:[LII_responseOptr].chunk
		mov	es:[LII_responseMsg], MSG_PPP_MANUAL_LOGIN_INIT_COMPLETE

		call	MemUnlock
	;
	; Prepare block to be sent in MSG_META_NOTIFY
	;
		mov	ax, 1
		call	MemInitRefCount
	;
	; Record the notification event
	;
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_LOGIN_INITIALIZE
		mov	bp, bx		; ^hbp <- data block
		mov	bx, segment MetaClass
		mov	si, offset MetaClass
		mov	di, mask MF_RECORD
		call	ObjMessage	; di <- message
	;
	; And deliver the event to the login server
	;
		mov	bx, di
		mov	bp, ds:[loginConnection]
		mov	dx, TO_SELF
		clr	cx		; no completion message
		mov	ax, IACPS_CLIENT
		call	IACPSendMessage	; ax <- # receivers
		tst	ax			; carry clear
EC <		ERROR_Z PPP_MANUAL_LOGIN_ERROR				>
		jz	errorWithConnection
done:
	.leave
	ret

errorWithConnection:
	;
	; there is a connection, but something is wrong with it
	;
		mov	bp, ds:[loginConnection]
		clr	cx
		call	IACPShutdown

		mov	ax, SSDE_LOGIN_FAILED
		stc
		jmp	done

else ; not _PENELOPE

	; This routine should never be called in Penelope

		ERROR	0 

endif 
PPPInitManualLogin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStopManualLogin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a notification to Term to stop the login process.

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		notify Term via IACP with MSG_META_NOTIFY to stop
		the login process

		login app will send a response message when it has actually
		stopped.  PPP should always rely on receiving this message to 
		know when login app has finished, and can safely conclude
		the connection.

NOTES:
		Caller has access so don't do anything else here
		beyond sending the notification.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/19/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStopManualLogin	proc	near

if not _PENELOPE

	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

		mov	bx, handle dgroup
		call	MemDerefES
	;
	; We must be in login mode to do this
	;
		clr	bp
		xchg	es:[loginConnection], bp
		tst	bp
EC <		WARNING_Z PPP_NO_MANUAL_LOGIN_CONNECTION		>
		jz	done
	;
	; Record notification to stop
	;
		mov	ax, MSG_META_NOTIFY
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_LOGIN_DETACH
		mov	bx, segment MetaClass
		mov	si, offset MetaClass
		mov	di, mask MF_RECORD
		call	ObjMessage	; di <- message
	;
	; Send it
	;
		mov	bx, di
		mov	dx, TO_SELF
		clr	cx
		mov	ax, IACPS_CLIENT
		call	IACPSendMessage	; ax <- # receivers
					; bx, cx, dx, destroyed
EC <		tst	ax					>
EC <		ERROR_Z PPP_MANUAL_LOGIN_ERROR			>
	;
	; shut down the connection to the login app
	;
		clr	cx			; client shutting down
		call	IACPShutdown		; ax destroyed

done:

	.leave

endif ; not _PENELOPE

	ret

PPPStopManualLogin	endp


if not _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPManualLoginInitComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent by manual login app when it's finished initializing
		itself

CALLED BY:	MSG_PPP_MANUAL_LOGIN_INIT_COMPLETE
PASS:		*ds:si	= PPPProcessClass object
		ds:di	= PPPProcessClass instance data
		ds:bx	= PPPProcessClass object (same as *ds:si)
		es 	= segment of PPPProcessClass
		ax	= message #
		cx	= connection token (access point id)
		dx	= LoginResponse
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	12/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPManualLoginInitComplete	method dynamic PPPProcessClass, 
					MSG_PPP_MANUAL_LOGIN_INIT_COMPLETE

response	local	LoginResponse	push	dx
	.enter

	;
	; Gain access to globals
	;
		mov	bx, ds:[taskSem]
		call	ThreadPSem
	;
	; Match connection tokens.  If not one of ours, ignore.
	;
		cmp	cx, ds:[clientInfo].PCI_accpnt
EC <		ERROR_NE PPP_INCORRECT_CONNECTION_TOKEN			>
		jne	done
	;
	; If client cancelled while we were initializing, go no further.
	;
		clr	ax			; no particular error (yet)
		cmp	ds:[clientInfo].PCI_linkState, PLS_CLOSING
		je	errorBeforeOpen
	;
	; Should now be in PLS_LOGIN_INIT phase.  Move to PLS_OPENING
	; phase.
	;
		cmp	ds:[clientInfo].PCI_linkState, PLS_LOGIN_INIT
EC <		ERROR_NE	PPP_MANUAL_LOGIN_ERROR			>
		jne	errorBeforeOpen
	;
	; Test response from login app.  If error, abort 
	;
		CheckHack <(LoginStatus lt 256) and (offset LR_STATUS eq 0)>
		cmp	dl, LS_CONTINUE
		jne	errorBeforeOpen
	;
	; Everything OK to proceed to PLS_OPENING phase.
	;
		mov	ds:[clientInfo].PCI_linkState, PLS_OPENING
		clr	ss:[response]

	; Open the modem & dial

		push	bp
		mov	dx, ds
		mov	bp, offset pppAddr		; dx:bp = address
		mov	cx, ds:[pppAddrSize]		; cx = address length
		call	PPPDeviceOpen			; ax = error
		pop	bp
		jc	errorBeforeOpen

		BitSet	ds:[clientInfo].PCI_status, CS_DEVICE_OPENED
	;
	; Check for interrupt while we were dialing
	;
		mov	bx, ds:[taskSem]
		call	ThreadVSem

		call	PPPCheckForInterrupt		; ax = SDE_INTERRUPTED

		call	ThreadPSem
		jc	errorAfterOpen

		mov	ds:[clientInfo].PCI_linkState, PLS_LOGIN
	;
	; Now move into manual login phase
	;
		call	PPPStartManualLogin		; ax = SSDE
		jc	errorAfterOpen
done:
		mov	bx, ds:[taskSem]
		call	ThreadVSem			; release access
	;
	; And quit, waiting for a response to come back from the login app
	;
		.leave
		ret

errorAfterOpen:
		push	ax
if _RESPONDER
		call	PPPUnregisterECI
endif ; _RESPONDER

		mov	bx, ds:[port]
		mov	di, DR_MODEM_HANGUP
		call	PPPCloseAndUnloadModem
		pop	ax
errorBeforeOpen:
		push	ax
		call	PPPStopManualLogin
	;
	; Aborted from manual login.  Close the link
	;
	;
		BitClr	ds:[clientInfo].PCI_status, CS_DEVICE_OPENED

	; unlock the access point

		mov	ax, ds:[clientInfo].PCI_accpnt
		call	PPPCleanupAccessInfo
		call	AccessPointUnlock
	;
	; reset client timer, state, accpnt ID
	;
		clr	ax
		mov	ds:[clientInfo].PCI_accpnt, ax
		mov	ds:[clientInfo].PCI_timer, ax
		mov	cl, PLS_CLOSED
		xchg	cl, ds:[clientInfo].PCI_linkState
		mov	dl, ds:[clientInfo].PCI_status
		BitClr 	ds:[clientInfo].PCI_status, CS_BLOCKED
	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_CLOSED
		call	PPPSendNotice
		pop	bp
		
	;
	; Notify client link closed (SCO_CONNECT_FAILED, unless connection
	; was interrupted).
	;
	; If user already interrupted, use SDE_INTERRUPTED regardless
	; of actual error.
	;
		pop	ax			; ax = error

		mov	dx, ds:[clientInfo].PCI_error
		cmp	dl, SDE_INTERRUPTED
		je	haveError
		mov	dl, SDE_LINK_OPEN_FAILED
	;
	; If something in this routine returned a particular error,
	; return that, instead of a generic login error.
	;
		tst	al
		jz	haveDriverError		; use default login error
		mov	dl, al
haveDriverError:
		tst	dh			; use previous spec error
		jnz	haveError		;  if any
		mov	dh, ah			; else use new error
		tst	dh			;  if any
		jnz	haveError
		mov	dh, SSDE_LOGIN_FAILED shr 8 ; else use login error
		test	ss:[response], mask LR_NO_NOTIFY
		jz	haveError
	;
	; If no_notify flag was set, promote spec error to NO_NOTIFY
	;
	CheckHack <SSDE_LOGIN_FAILED_NO_NOTIFY-SSDE_LOGIN_FAILED eq 100h>
		inc	dh
haveError:
		mov	di, SCO_CONNECT_FAILED
		call	PPPNotifyLinkClosed

		jmp	done

PPPManualLoginInitComplete	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPManualLoginComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance PPP to negotations stage if login has been completed
		successfully.  Else terminate the link opening process.

CALLED BY:	MSG_PPP_MANUAL_LOGIN_COMPLETE
PASS: 		cx	= connection token in LII_connection
		dx	= LoginResponse

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		set dgroup to DS for C code
		Resume control of serial port
		gain access
		if state is PLS_LOGIN,
			move to PLS_NEGOTIATING mode
			release access
			call PPPBeginNegoitations in active mode
			lock inputBuffer and pass info to PPPProcessInput
			queue self a data notification to get things started
		else 
		   EC (state is PLS_CLOSING)
		   clr device opened bit
		   Responder (PPPUnregisterECI)
		   call PPPCloseAndUnloadModem with hangup
		   reset client timer, state, accpnt ID
		   release access
		   notify client link closed (SCO_CONNECT_FAILED)


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPManualLoginComplete	method dynamic PPPProcessClass, 
					MSG_PPP_MANUAL_LOGIN_COMPLETE
response	local	LoginResponse	push	dx
		.enter
		push	bp
	;
	; Gain access to globals
	;
		mov	bx, ds:[taskSem]
		call	ThreadPSem

		cmp	cx, ds:[clientInfo].PCI_accpnt
EC <		ERROR_NE PPP_INCORRECT_CONNECTION_TOKEN			>
		LONG	jne	done
	;
	; Close IACP connection to login application
	;
		push	bp
		clr	bp
		xchg	ds:[loginConnection], bp
		tst	bp
		jz	connectionClosed
		clr	cx			; client side
		call	IACPShutdown
connectionClosed:
		pop	bp
	;
	; re-register for serial data notifications
	;
		mov	bx, ds:[port]
		mov	di, DR_MODEM_GRAB_SERIAL_PORT
		call	PPPSetPortNotify
	;
	; If error from login app, close link
	;
		cmp	dl, LS_CONTINUE
		jne	abort
	;
	; Do appropriate thing for new state
	;
		cmp	ds:[clientInfo].PCI_linkState, PLS_LOGIN
		je	startNegotiating
		cmp	ds:[clientInfo].PCI_linkState, PLS_CLOSING
EC <		ERROR_NE	PPP_MANUAL_LOGIN_ERROR			>
		jne	done
abort:
	;
	; Aborted from manual login.  Close the link
	;
		BitClr	ds:[clientInfo].PCI_status, CS_DEVICE_OPENED

if _RESPONDER
		call	PPPUnregisterECI
endif ; _RESPONDER

		mov	bx, ds:[port]
		mov	di, DR_MODEM_HANGUP
		call	PPPCloseAndUnloadModem

		mov	ax, ds:[clientInfo].PCI_accpnt
		tst	ax
		jz	resetStuff
		call	PPPCleanupAccessInfo
		call	AccessPointUnlock
resetStuff:
	;
	; reset client timer, state, accpnt ID
	;
		clr	ax
		mov	ds:[clientInfo].PCI_accpnt, ax
		mov	ds:[clientInfo].PCI_timer, ax
		mov	cl, PLS_CLOSED
		xchg	cl, ds:[clientInfo].PCI_linkState
		mov	dl, ds:[clientInfo].PCI_status
		BitClr 	ds:[clientInfo].PCI_status, CS_BLOCKED
	;
	; send notification
	;
		push	bp
		mov	bp,	PPP_STATUS_CLOSED
		call	PPPSendNotice
		pop	bp
	;
	; Notify client link closed (SCO_CONNECT_FAILED, unless connection
	; was interrupted).  If error codes have already been placed in
	; PCI_error, use them instead of the default login error.
	;
		mov	dx, ds:[clientInfo].PCI_error
		tst	dh
		jnz	haveSpecError
		mov	dh, SSDE_LOGIN_FAILED shr 8
		test	ss:[response], mask LR_NO_NOTIFY
		jz	haveSpecError
		CheckHack <SSDE_LOGIN_FAILED_NO_NOTIFY-SSDE_LOGIN_FAILED eq 100h>
		inc	dh			; promote to NO_NOTIFY
haveSpecError:
		tst	dl
		jnz	haveError
		mov	dl, SDE_LINK_OPEN_FAILED
haveError:
		mov	di, SCO_CONNECT_FAILED
		call	PPPNotifyLinkClosed
done:
	;
	; Release variable access
	;
		mov	bx, ds:[taskSem]
		call	ThreadVSem
doneNoV:
		pop	bp
		.leave
		ret

startNegotiating:
	;
	; Deal with any access info that may have been set by the login
	; process.
	;
		call	PPPSetAccessInfoAfterLogin
	;
	; Move into NEGOTIATING phase
	;
		mov	ds:[clientInfo].PCI_linkState, PLS_NEGOTIATING
		mov	bx, ds:[taskSem]
		call	ThreadVSem

		call	PPPBeginNegotiations	; nukes ax,bx,cx,bp,es,di
	;
	; If the callback grabbed data from the login app,
	; send it in for processing
	;
		mov	bx, ds
		mov	es, bx			; es = dgroup
		mov	cx, ds:[pppDataSize]
		jcxz	afterInput
	;
	; Set up pointer to data buffer
	;
		mov	bx, es:[inputBuffer]
		call	MemLock
		mov	ds, ax
		clr	si			; ds:si = place for data
	;
	; Process input data.
	;
		push	cx, si, es, ds		; may be destroyed by C
		pushdw	dssi			; pass pointer to input
		push	cx			; pass size of input
		segmov	ds, es, cx		; ds = dgroup for C
		call	PPPProcessInput
		pop	cx, si, es, ds

		mov	bx, es:[inputBuffer]
		call	MemUnlock
	;
	; If buffer was enlarged to hold callback data, shrink it now.
	;
		cmp	cx, (PPP_INPUT_BUFFER_SIZE+15) and 0xfff0
		jbe	afterInput
		mov	ax, PPP_INPUT_BUFFER_SIZE
		clr	ch
		call	MemReAlloc
afterInput:
	;
	; Jump-start the serial reader
	;
		mov	ax, MSG_PPP_HANDLE_DATA_NOTIFICATION
		mov	bx, es:[pppThread]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		jmp	doneNoV
PPPManualLoginComplete	endm

endif ; not _PENELOPE

ConnectCode		ends

COMMENT |------------------------------------------------------------------

			RESPONDER ONLY

--------------------------------------------------------------------------|

if _RESPONDER

ConnectCode		segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPRegisterECIAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register for ECI notification of the following:
			ECI_CALL_CREATE_STATUS
			ECI_CALL_RELEASE_STATUS
			ECI_CALL_TERMINATE_STATUS

CALLED BY:	PPPModemOpen

PASS:		ds	= dgroup

RETURN:		nothing		

DESTROYED:	ax, cx, dx, di, si, es

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/29/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPRegisterECIAll	proc	near

	;
	; Put ECI IDs on stack and register.
	;
		mov	ax, ECI_CALL_CREATE_STATUS
		push	ax
		mov	ax, ECI_CALL_TERMINATE_STATUS
		push	ax			
		mov	ax, ECI_CALL_RELEASE_STATUS
		push	ax
		mov	ax, sp				; ss:ax = ECI ID array

		mov	cx, PPP_NUM_ECI_ALL
		call	PPPRegisterECICommon		
	;
	; Remove IDs from stack.
	;
		pop	ax
		pop	ax
		pop	ax

		ret
PPPRegisterECIAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPRegisterECIEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register for ECI notification of the following:
			ECI_CALL_RELEASE_STATUS
			ECI_CALL_TERMINATE_STATUS

CALLED BY:	PPPModemOpen	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	ax, cx, dx, di, si, es

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/29/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPRegisterECIEnd	proc	near

	;
	; Put ECI IDs on stack and register.
	;
		mov	ax, ECI_CALL_TERMINATE_STATUS
		push	ax			
		mov	ax, ECI_CALL_RELEASE_STATUS
		push	ax
		mov	ax, sp				; ss:ax = ECI ID array

		mov	cx, PPP_NUM_ECI_END
		call	PPPRegisterECICommon		
	;
	; Remove IDs from stack.
	;
		pop	ax
		pop	ax

		ret
PPPRegisterECIEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPRegisterECICommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register for ECI notification of call termination.
		ECI_CALL_RELEASE_STATUS is received when mobile user
		ends the call.  ECI_CALL_TERMINATE_STATUS is received 
	 	when the remote user or network ends the call.  

CALLED BY:	PPPModemOpen

PASS:		ds 	= dgroup
		ss:ax	= ECI ID array
		cx	= num IDs in array

RETURN:		nothing

DESTROYED:	ax, cx, dx, di, si, es 

PSEUDO CODE/STRATEGY:

 		Fill in VpRegisterClientParams
		Register with VP lib

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/31/95			Initial version
	jwu	10/9/95			Added ECI_CALL_RELEASE_STATUS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPRegisterECICommon	proc	near
		uses	bx, bp
		.enter
	;
	; Fill in registration params.
	;
		sub	sp, size VpRegisterClientParams
		mov	bp, sp

		mov	ss:[bp].VRCP_eciReceive.segment, \
				vseg PPPECICallback
		mov	ss:[bp].VRCP_eciReceive.offset, \
				offset PPPECICallback

		mov	ss:[bp].VRCP_eciMessageIdArray.segment, ss
		mov	ss:[bp].VRCP_eciMessageIdArray.offset, ax
		mov	ss:[bp].VRCP_numberOfEciMessages, cx

		mov	ss:[bp].VRCP_vpClientToken.segment, ds
		mov	ss:[bp].VRCP_vpClientToken.offset, offset vpClientToken
	;
	; Register and remove values from stack.  
	;		
		call	VpRegisterClient	; ax = VpRegisterClientResult
		add	sp, size VpRegisterClientParams

EC <		cmp	ax, VPRC_OK				>
EC <		WARNING_NE PPP_ECI_REGISTRATION_FAILED		>
	;
	; Mark that the call has not yet ended
	;
		mov	ds:[callEnded], FALSE

		.leave
		ret
PPPRegisterECICommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPUnregisterECI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister from ECI notifications.

CALLED BY:	PPPDeviceClose
		PPPModemOpen

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	cx, dx, di, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/31/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PPPUnregisterECI	proc	near
		uses	ax, bx, si, bp
		.enter
	;
	; Unregister, clearing stored token and call ID.
	;
		sub	sp, size VpUnregisterClientParams
		mov	bp, sp
		clr	ax
		mov	ds:[vpCallID], al		
		xchg	al, ds:[vpClientToken]		
		mov_tr	ss:[bp].VUCP_vpClientToken, ax
		call	VpUnregisterClient	; ax = VpUnregisterClientResult
		add	sp, size VpUnregisterClientParams

EC <		cmp	ax, VPUC_FAILED					>
EC <		WARNING_E PPP_ECI_UNREGISTRATION_FAILED			>

		.leave
		ret
PPPUnregisterECI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPECICallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for ECI notifications.

CALLED BY:	VP library

PASS:		on stack:
			messageID	word
			memHandle	word

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		Queue message for PPP thread to handle.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/31/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPECICallback	proc	far	messageID:word,
				memHandle:word
		uses	si, di, es
		.enter

		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, es:[pppThread]
		mov	cx, memHandle
		mov	dx, messageID
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_PPP_ECI_NOTIFICATION
		call	ObjMessage

		.leave
		ret
PPPECICallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPECINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the ECI notification.

CALLED BY:	MSG_PPP_ECI_NOTIFICATION
PASS:		cx	= mem handle of data block
		dx	= ECI message ID

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		Grab first 3 bytes out of data block.
		(Use CheckHacks to ensure position of fields.)
		if ECI_CALL_CREATE_STATUS
			if data call mode and successful, store ID
		if ECI_CALL_RELEASE_STATUS or 
			ECI_CALL_TERMINATE_STATUS
			if call ID matches ours, close connection

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	8/31/95   	Initial version
	jwu	3/29/96		completely rewritten
	jwu	7/24/96		manual login version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPECINotification	method dynamic PPPProcessClass, 
					MSG_PPP_ECI_NOTIFICATION

	;
	; Extract data and then begin processing.  We only care about
	; the first 3 bytes in the data, regardless of the ECI message.
	; 
		mov	bx, cx			; ^hbx = data block
		call	MemLock
		mov	ds, ax
		clr	si			; ds:si = message info 

		lodsb				
		mov	cl, al			; cl = 1st data byte
		lodsb	
		mov	ch, al			; ch = 2nd data byte
		lodsb				; al = 3rd data byte

		call	MemFree
	;
	; If msg is ECI_CALL_CREATE_STATUS, store the call ID if 
	; data call was successfully created.
	;
		mov	bx, handle dgroup
		call	MemDerefDS

		cmp	dx, ECI_CALL_CREATE_STATUS			
		jne	checkEnd

		CheckHack <offset status_2004 eq 0>
		CheckHack <offset call_id_2004 eq 1>
		CheckHack <offset call_mode_2004 eq 2>

		cmp	al, ECI_CALL_MODE_DATA		; check mode
		LONG	jne	done
		cmp	cl, ECI_OK			; check status
		LONG	jne	done

EC <		tst	ds:[vpCallID]				>
EC <		WARNING_NE PPP_BAD_ECI_NOTIFICATION		>

		mov	ds:[vpCallID], ch		; store call ID		
		jmp	done
checkEnd:
	;
	; If msg is ECI_CALL_RELEASE_STATUS or ECI_CALL_TERMINATE_STATUS,
	; terminate call only if call ID matches.
	;
EC <		cmp	dx, ECI_CALL_RELEASE_STATUS		>
EC <		je	checkID					>
EC <		cmp	dx, ECI_CALL_TERMINATE_STATUS		>
EC <		ERROR_NE PPP_BAD_ECI_NOTIFICATION		>
EC <checkID:							>

		CheckHack <offset call_id_2015 eq 0>
		CheckHack <offset call_id_2016 eq 0>

		cmp	cl, ds:[vpCallID]
		jne	done
	;
	; Mark call as already ended, so we don't try to hang up later.
	;
		mov	ds:[callEnded], TRUE
	;
	; If device wasn't opened, nothing to close.
	;
		mov	bx, ds:[taskSem]
		call	ThreadPSem			; gain access

		mov	cl, ds:[clientInfo].PCI_status
		mov	ch, ds:[clientInfo].PCI_linkState

		call	ThreadVSem			; release access

	;
	; If in manual login phase, stop login
	;
		cmp	ch, PLS_LOGIN_INIT
		jb	stopProto
		cmp	ch, PLS_LOGIN
		ja	stopProto

		test	cl, mask CS_MANUAL_LOGIN
		jz	done
	;
	; Log the fact that the call was dropped as the error to return
	; to the client.
	;
		call	ThreadPSem			; gain access

		cmp	ds:[clientInfo].PCI_error.low, SDE_INTERRUPTED
		je	haveError
		mov	ds:[clientInfo].PCI_error, SSDE_NO_CARRIER or \
						   SDE_LINK_OPEN_FAILED
haveError:
		call	ThreadVSem			; release access

		call	PPPStopManualLogin
		jmp	done
stopProto:
	;
	; else, terminate protocol.
	;
		test	cl, mask CS_DEVICE_OPENED
		jz	done

		push	bx				; save semaphore
		clr	ax
		push	ax				; pass unit #
		call	PPPCallTerminated
		pop	bx				; restore semapohore
done:
		ret
PPPECINotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPClearBlacklist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an ECI message to clear the blacklist.	

CALLED BY:	PPPModemOpen

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/17/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPClearBlacklist	proc	near
		uses	ax, bx, cx, dx, bp, es
		.enter

		sub	sp, size VpSendEciMessageParams
		mov	bp, sp
		clr	ax
		mov	ss:[bp].VSEMP_eciMessageID, ECI_CALL_CLEAR_BLACKLIST
		movdw	ss:[bp].VSEMP_eciStruct, axax
		call	VpSendEciMessage
		add	sp, size VpSendEciMessageParams

		.leave
		ret
PPPClearBlacklist	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPLogCallStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Log the start of a call with Contact Log.  

CALLED BY:	PPPModemOpen

PASS:		ds	= dgroup
		inherit stack frame from PPPModemOpen:
				phone		fptr
				theSize		word
				accID		word

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Log call, providing access point name if have one, 
		else use phone number.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/26/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPLogCallStart	proc	near
		uses	ax, bx, cx, dx, di, si, es
		.enter inherit PPPModemOpen

		Assert_dgroup	ds
	;
	; Get access point name, if any.
	;
		segmov	es, ds, di
		lea	di, es:[pppLogEntry].LE_number	

		mov	ax, accID
		tst	ax
		jz	usePhone

		push	bp
		clr	cx
		mov	dx, APSP_NAME
		mov	bp, size NameOrNumber
		call	AccessPointGetStringProperty
		pop	bp

		jnc	getTime
		tst	cx
		jnz	getTime
usePhone:
	;
	; No access point name.  Use phone number.  
	;
		push	ds
		lds	si, phone			; ds:si = phone #
		mov	cx, theSize			; size of phone string
		cmp	cx, size NameOrNumber - size TCHAR
		jbe	copyNow
		mov	cx, size NameOrNumber - size TCHAR
copyNow:
		rep	movsb

		clr	ax
		LocalPutChar	esdi, ax		; null terminate
		pop	ds
getTime:
	;
	; Fill in start time and date.
	;
		call	TimerGetDateAndTime
		mov	si, offset ds:[pppLogEntry]
		mov	ds:[si].LE_datetime.DAT_year, ax
		mov	ds:[si].LE_datetime.DAT_month, bl
		mov	ds:[si].LE_datetime.DAT_day, bh
		mov	ds:[si].LE_datetime.DAT_hour, ch
		mov	ds:[si].LE_datetime.DAT_minute, dl
	;
	; Clear out duration so we don't log this as an end call.
	;
		movdw	ds:[si].LE_duration, 0
	;
	; Get count so we can figure out duration at end of call.
	;
		call	TimerGetCount			; bxax = count
		pushdw	bxax

		call	LogAddEntry
EC <		WARNING_C PPP_LOG_ADD_ENTRY_FAILED			>

		popdw	ds:[si].LE_duration

exit::
		.leave
		ret
PPPLogCallStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPLogCallEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Log the end of the call with Contact Log if the start of
		the call was logged.  Reset LogEntry values for next call.

CALLED BY:	PPPCloseAndUnloadModem

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/26/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPLogCallEnd	proc	near
		uses	ax, bx, si
		.enter

		Assert_dgroup	ds
	;
	; Only log end if start of call was logged.
	;
		mov	si, offset ds:[pppLogEntry]
		tst	ds:[si].LE_flags
		jz	reset				; not logged
	;
	; Calculate duration in seconds.
	;
		call	TimerGetCount			; bxax = count
		mov	dx, bx			
		subdw	dxax, ds:[si].LE_duration

		mov	cx, ONE_SECOND
		div	cx				

		tst	dx
		jz	store

		clr	dx
		add	ax, 1				; round up to next second
		adc	dx, 0
store:
		movdw	ds:[si].LE_duration, dxax
		call	LogAddEntry
EC <		WARNING_C PPP_LOG_ADD_ENTRY_FAILED		>

reset:
	;
	; Reset LogEntry settings for next call.
	;
		clr	ax
		movdw	ds:[si].LE_duration, axax
		mov	ds:[si].LE_flags, al
		movdw	ds:[si].LE_contactID, LECI_INVALID_CONTACT_ID

		.leave
		ret
PPPLogCallEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPCheckDiskspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if diskspace is above warning level.

CALLED BY:	PPPModemOpen

PASS:		nothing

RETURN:		carry set to cancel
		else carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/12/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPCheckDiskspace	proc	near
		uses	ax, bx, cx, dx, bp, di
		.enter
	;
	; Check diskspace.
	;
		call	FoamCheckIfOutOfSpace	; ax = FoamDiskSpaceStatus
		cmp	ax, FDSS_NOT_FULL
		je	done
	;
	; Low diskspace situation.  Ask if user wants to cancel connection. 
	; Create UI thread to display dialog.
	;
		call	PPPCreateUIThread	; ^hbx = new thread
		mov	ax, MSG_PPP_UI_WARN_DISKSPACE
		mov	di, mask MF_CALL
		call	ObjMessage		; ax = IC_YES to continue

		cmp	ax, IC_YES
		je	done			; carry clear

		stc
done:
		.leave
		ret
PPPCheckDiskspace	endp

ConnectCode		ends

endif	; _RESPONDER



COMMENT |------------------------------------------------------------------

			PENELOPE ONLY

--------------------------------------------------------------------------|

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPPADOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish the modem connection and setup data notification.
		This routine mirrors PPPModemOpen and must have the same
		return codes.

CALLED BY:	PPPDeviceOpen

PASS:		ds	= dgroup
		es:di	= phone number (non-null terminated) 
		cx	= size of phone number string (0 if passive mode)
		ax	= access ID (0 if none) (ignored if passive mode)

RETURN:		carry clear if successful
		else
		carry set
		ax	= SpecSocketDrError
				(SSDE_DEVICE_NOT_FOUND  -- no PAD
				 SSDE_DEVICE_BUSY
				 SSDE_DIAL_ERROR
				 SSDE_NO_CARRIER
				 SSDE_NO_DIALTONE)

DESTROYED:	cx, dx, di, es (allowed)

PSEUDO CODE/STRATEGY:
		release access to give user a chance to cancel
		load PAD, handling error
		register with PAD, handling error
		connect with PAD, handling error

NOTES: 	
		Caller has access so return with access held!

		Must hold access after dialing so PPPOpenLink can
		change the state before user interrupts the connect request.
		If user slips in, no message will be sent to PPP to stop
		the connect process.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	kkee	11/19/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPPADOpen	proc	near
		uses	bx, si
phone		local	fptr			push es, di
theSize		local	word			push cx
accID		local	word			push ax
		.enter
	;
	; Release access to give user a chance to cancel.  
	;
		mov	bx, ds:[taskSem]	
		call	ThreadVSem

	;
	; Initialize variables dealing with PAD.
	;
		mov	ds:[padResponse], PAD_AT_OK
		mov	ds:[padStatus], 0x0040    ; Carrier detect set

	;
	; Load PAD.
	;
		call	PPPLoadPAD
		jnc	register
		mov	ax, SSDE_DEVICE_NOT_FOUND
		jmp	exit

register:
	;
	; Register with PAD. PPP must have created a thread before we 
	; can register with PAD.
	;
		call 	PPPRegisterWithPAD		; cx:dx = errorCode
		tst	cx
		jz	capability
		mov	ax, SSDE_DEVICE_BUSY		; ax = errorCode
		stc
		jmp	regainAccess

capability:
	;
	; Set barrier capability of PAD.
	;
		mov	ax, accID
		call	PPPSetPADCapability
		jnc	connect
		mov	ax, SSDE_DEVICE_BUSY		; ax = errorCode
		jmp	regainAccess

connect:
	;
	; Request a connection from PAD.
	;
		movdw	esdi, phone
		mov	cx, theSize
		call 	PPPConnectWithPAD		; ax = errorCode
		jnc	checkInterrupt

regainAccess:
		pushf
		push	ax				; return code
		mov	bx, ds:[taskSem]
		call	ThreadPSem			; carry destroyed
		pop	ax
		popf
		jmp	exit

checkInterrupt:
	;
	; Check again for cancel.  Hold access after checking.
	; See notes in header for explanation.
	;
		mov	bx, ds:[taskSem]
		call	ThreadPSem
		
		cmp	ds:[clientInfo].PCI_linkState, PLS_OPENING
		je	exit				; carry clear

		mov	ax, SDE_INTERRUPTED
		stc
exit:
		.leave
		ret

PPPPADOpen	endp

endif ; _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPLoadPAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load PAD and get its optr for messaging.  Store PAD library
		handle in dgroup::padLibrary, and PAD optr in 
		dgroup::padOptr.

CALLED BY:	PPPPADOpen

PASS:		ds	= dgroup

RETURN:		carry set if error

DESTROYED:	ax, bx, cx, dx, si, es (allowed by caller)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	kkee	11/19/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString	padName, <"padec.geo", 0>		>
NEC<LocalDefNLString	padName, <"pad.geo", 0>			>

PPPLoadPAD	proc	near
		uses	ds
		.enter

		segmov	es, ds, ax			; es = dgroup

		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		jc	done

		segmov	ds, cs, si
		mov	si, offset padName
		mov	ax, 0				; PAD_PROTO_MAJOR
		mov	bx, 0				; PAD_PROTO_MINOR
		call	GeodeUseLibrary
EC <		WARNING_C PPP_COULD_NOT_LOAD_PAD		>
		jc	done

		mov	es:[padLibrary], bx

	;
	; 0, the first exported PAD routine must return PAD's optr.
	;
		mov	ax, 0 
		call	ProcGetLibraryEntry	; bx:ax = routine vfptr
		call	ProcCallFixedOrMovable	; dx:ax = PAP's optr
EC <		Assert	thread, dx				>
		movdw	es:[padOptr], dxax
		clc
done:
		call	FilePopDir		

		.leave
		ret
PPPLoadPAD	endp

endif ; _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPRegisterWithPAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register with the PAD library by adding ourself as a client
		of PAD, providing PAD with messages to respond to our 
		requests which we will make later after registration is ok.

CALLED BY:	PPPPADOpen
PASS:		ds	= dgroup
RETURN:		cx:dx 	= one of PAD error codes, ERR_PAD_... 
			  (see Include/pad.def)
DESTROYED:	ax, bx, si, es (allowed by caller)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPRegisterWithPAD	proc	near
	uses	bp
	.enter

	;
	; Pass data on stack to MSG_PAD_INIT_CLIENT
	;
		mov	dx, size padInit_s
		sub 	sp, dx
		mov	bp, sp

	;
	; padInit_s.padClientMessageList_s.
	;
		mov	ss:[bp].clientMsg.clientDataMessage, 
					MSG_CLIENT_DATA_PROTO
		mov	ss:[bp].clientMsg.clientConnectMessage, 
					MSG_CLIENT_CONNECT_PROTO
		mov 	ss:[bp].clientMsg.clientErrorMessage, 
					MSG_CLIENT_ERROR_PROTO
		mov	ss:[bp].clientMsg.clientModeMessage,
					MSG_CLIENT_MODE_PROTO

	;
	; padInit_s.padClientId_e.
	;	
		clr 	ah
		mov 	al, PAD_PPP_CLIENT
		mov	ss:[bp].clientId, ax

	;
	; padInit_s.optr.
	;
		mov	ax, ds:[pppThread]
		clr	bx
		movdw	ss:[bp].clientOptr, axbx

	;
	; Now call PAD, passing PPP's padInit_s on stack.
	;
		mov	ax, MSG_PAD_INIT_CLIENT
		movdw	bxsi, ds:[padOptr]
		mov	di, mask MF_STACK or mask MF_CALL
		call	ObjMessage
		add	sp, (size padClientMessageList_s) + 6
	.leave
	ret
PPPRegisterWithPAD	endp
	
endif ; _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPUnregisterFromPAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister PPP from PAD.

CALLED BY:	PPPDeviceClose
PASS:		ds	= dgroup
RETURN:		Nothing
DESTROYED:	ax, bx, cx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPUnregisterFromPAD	proc	near
	uses	dx, bp
	.enter
	;
	; Remove PPP from PAD's client list.
	;
		movdw	bxsi, ds:[padOptr]
		tst	bx
		jz	done
		mov	cx, PAD_PPP_CLIENT
		mov	ax, MSG_PAD_DELETE_CLIENT
		mov	di, mask MF_CALL
		call	ObjMessage

done:
	.leave
	ret
PPPUnregisterFromPAD	endp

endif ; _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPUnloadPAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unloads PAD.

CALLED BY:	PPPExit
PASS:		ds	= dgroup
RETURN:		Nothing
DESTROYED:	Nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPUnloadPAD	proc	near
	uses	bx
	.enter
		clr	bx
		xchg	bx, ds:[padLibrary]
		tst	bx	
		jz	exit
		call	GeodeFreeLibrary
exit:
	.leave
	ret
PPPUnloadPAD	endp

endif ; _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPConnectWithPAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request a data connection from PAD. If successful, we will
		get an upstream handle for which to read data, and a
		dnstream handle for which to write data.

CALLED BY:	PPPPADOpen

PASS:		es:si	= phone number string, not null-terminated.
		cx	= string length in bytes

RETURN:		carry clear if successful
		else
		carry set
		ax	= SpecSocketDrError
				(0				
				 SSDE_DEVICE_BUSY
				 SSDE_DIAL_ERROR
				 SSDE_NO_CARRIER
				 SSDE_NO_DIALTONE)

DESTROYED:	bx, cx, dx, si, es (allowed by caller)

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		ForceQueue a request message to PAD;
		Go into a loop to check our message queue for reply;
		If we get a message in {MSG_CLIENT_DATA_PROTO,
			MSG_CLIENT_CONNECT_PROTO,
			MSG_CLIENT_ERROR_PROTO}
		   we handle it;
		else
		   we ignore it;


		WHY?
		This strategy is used since we have to return with either
		success or failure, not some intermediate state. If we
		return without looping for PAD messages, we would have to 
		implement PPP as a finite state machine. That's not easy
		considering that we do not want to mess around too much
		with PPP's original design.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPConnectWithPAD	proc	near
	uses	dx
	.enter
	;
	; Combine ATD command and phone number into "ATD123456789".
	;
		push	ds
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[padATD]			; ds:si = "ATD"
		mov	dx, cx
		mov	cx, 3				; string length
		call	PPPStrAllocStrcat		; bx = new block
		pop	ds
		pushf
		push	bx
		mov	bx, handle Strings	
		call 	MemUnlock
		pop	bx
		popf
		jc	failed

		mov	cx, PAD_PPP_CLIENT		; clientId
		mov	dx, bx				; dataBlock
		mov	ax, MSG_PAD_DATA
		movdw	bxsi, ds:[padOptr]
		mov	di, mask MF_FORCE_QUEUE
		call 	ObjMessage			; dataBlock deleted

	;
	; Loop to wait for response from PAD.
	;
		call	PPPGetPADResponse
		jc 	failed
		jmp	exit
failed:
	;
	; Translate PAD response error to SpecSocketDrError.
	;
		mov	bx, ax				; PAD response error
		shl	bx				; word index
EC <		cmp	bx, size padResponseErrorTable			>
EC <		ERROR_A	PPP_INVALID_PAD_ERROR				>
		mov	ax, cs:padResponseErrorTable[bx]
		stc
exit:
	.leave
	ret

	;
	; This table must be kept updated with padAtTranslationType_e
	; table in Include/pad.def.
	;
padResponseErrorTable	word	\
	0,				; PAD_AT_OK
	0,				; PAD_AT_CONNECT
	SSDE_DEVICE_BUSY,		; PAD_AT_RING (Not sure here..)
	SSDE_NO_CARRIER,		; PAD_AT_NO_CARRIER
	SSDE_DEVICE_ERROR,		; PAD_AT_ERROR
	SSDE_NO_DIALTONE,		; PAD_AT_NO_DIALTONE
	SSDE_DEVICE_BUSY, 		; PAD_AT_BUSY
	SSDE_NO_ANSWER			; PAD_AT_NO_ANSWER


PPPConnectWithPAD	endp

endif ; _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPDisconnectFromPAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disconnect from PAD.

CALLED BY:	PPPDeviceClose

PASS:		ds	= dgroup

RETURN:		carry clear if success
		else
		carry set (even if we fail, caller should just let it pass
			   without further action)

DESTROYED:	ax, bx, cx, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: 
		Send ATH (modem hangup command) to PAD.
		Close all streams (streams must be closed from 
 		both sides, the other side is PAD).
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPDisconnectFromPAD	proc	near
	uses	dx, bp
	.enter
	;
	; If we are disconnected abnormally, then do not send +++
	; and ATH commands.  
	;
		mov	bl, ds:[padAbnormalDisconnect]
		tst	bl
		jz	normalDisconnect
		jmp	done

normalDisconnect:
	;
	; We don't use DR_STREAM_CLOSE strategy routine to close dnStream
	; and upStream as PAD is taking care of closing all streams.
	; We simply set them to 0 and send "ATH" to PAD.
	;	
		mov	bx, ds:[padOptr].handle
		tst	bx
		jz	done

	;
	; Send "+++" offline command to PAD and then send "ATH" hangup
	; command to PAD.
	;
		push	ds
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[padOffline]		; ds:si = "+++"
		mov	cx, 3				; string length
		call	PPPStrAllocCopy			; bx = new block
		pop	ds
		pushf
		push	bx
		mov	bx, handle Strings	
		call 	MemUnlock
		pop	bx
		popf
		jc	done

		mov	cx, PAD_PPP_CLIENT		; clientId
		mov	dx, bx				; dataBlock
		mov	ax, MSG_PAD_DATA
		movdw	bxsi, ds:[padOptr]
		mov	di, mask MF_FORCE_QUEUE
		call 	ObjMessage			; dataBlock deleted

	;
	; Wait for response to "+++" command. We must get the response
	; to make sure PAD has time to disconnect.
	;
		call 	PPPGetPADResponse
		jc	done

	;
	; Now send "ATH" command.
	;
		push	ds
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[padATH]			; ds:si = "ATH"
		mov	cx, 3				; string length
		call	PPPStrAllocCopy			; bx = new block
		pop	ds
		pushf
		push	bx
		mov	bx, handle Strings	
		call 	MemUnlock
		pop	bx
		popf
		jc	done

		mov	cx, PAD_PPP_CLIENT		; clientId
		mov	dx, bx				; dataBlock
		mov	ax, MSG_PAD_DATA
		movdw	bxsi, ds:[padOptr]
		mov	di, mask MF_FORCE_QUEUE
		call 	ObjMessage			; dataBlock deleted

	;
	; Wait for ATH response from PAD. We must get the response
	; to make sure that PAD has disconnected.
	;
		call 	PPPGetPADResponse 
		clc

done:
	.leave
	ret
PPPDisconnectFromPAD	endp

endif ; _PENELOPE

if _PENELOPE

COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPDeviceWrite

DESCRIPTION:	Write output data to device driver.

C DECLARATION:	extern void _far
		_far _pascal PPPDeviceWrite (unsigned char *data,
						word numBytes);
STRATEGY:
		Just write the data to padDnStream.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/23/96	Initial Version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPDEVICEWRITE		proc	far	data:fptr.byte,
					numBytes:word
		uses	si, di, ds
		.enter

		segmov	es, ds, ax			; es = dgroup
		mov	bx, es:[padDnStream]
		lds	si, data			; ds:si = output data
		mov	ax, STREAM_BLOCK
		mov	cx, numBytes
		mov	di, DR_STREAM_WRITE
		tstdw	es:[padStreamStrategy]
		jz	exit
		call	es:[padStreamStrategy]
exit:
		.leave
		ret

PPPDEVICEWRITE		endp
	SetDefaultConvention

endif ; _PENELOPE

if _PENELOPE

COMMENT @----------------------------------------------------------------

C FUNCTION:	PPPDeviceClose

DESCRIPTION:	Close the connection with PAD.  Returns zero if 
		close was not performed. We only close PAD if
		PAD was used.

CALLED BY:	lcp_closed
		PPPShutdown

C DECLARATION:	extern unsigned short _far
		_far _pascal PPPDeviceClose (void);

PSEUDO CODE/STRATEGY:
		There is no need to unload PAD here. PAD is only
		unloaded in PPPExit.
		
		hangup connection with PAD.
		unregister from PAD.
		If we have a serial handle, 
			close the serial port? (ask Ericsson)
			unloade the serial driver? (ask Ericsson)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/20/96	Initial Version
-------------------------------------------------------------------------@
	SetGeosConvention
PPPDEVICECLOSE		proc	far
		uses	bx, di, ds
		.enter

		mov	bx, handle dgroup
		call	MemDerefDS		; ds = dgroup
	;
	; If PAD was not used, then no need to unregister.
	;
		clr	ax
		or	ax, ds:[padOptr].handle
		jz	notLoaded

wasLoaded:
	;
	; Reset stream so we don't call streamStrategy as
	; stream might be invalid, causing PPP to crash.
	;
		clr	ds:[padUpStream]
		clr	ds:[padDnStream]
		movdw	ds:[padStreamStrategy], 0
		clr	ds:[padStreamDr]

	;
	; PAD was open. Disconnect and unregister from PAD.
	;
		call 	PPPDisconnectFromPAD
		call 	PPPUnregisterFromPAD

	;
	; Reset PAD.
	;
		movdw	ds:[padOptr], 0
		clr	ds:[padAbnormalDisconnect]
		
notLoaded:
	;
	; Return TRUE if the device was opened. 
	;
 		mov	al, ds:[clientInfo].PCI_status
		and	al, mask CS_DEVICE_OPENED
		jz	exit
		BitClr	ds:[clientInfo].PCI_status, CS_DEVICE_OPENED
		mov	ax, TRUE      ; device was opened
exit:
		.leave
		ret
PPPDEVICECLOSE		endp
	SetDefaultConvention 

endif ; _PENELOPE


if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSetPADCapability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the barrier capability of PAD.

CALLED BY:	PPPConnectWithPAD
PASS:		ax = access point ID
RETURN:		Carry set if error
			ax = error code from PAD.
		Carry clear no error.
DESTROYED:	bx, cx, dx, si, es (allowed by caller)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kkee    	6/30/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSetPADCapability	proc	near
	uses	bp
	.enter
	;
	; Look up bearer capability string in accesspoint
	;
		clr	cx, bp				; alloc a buffer
		mov	dx, APSP_BEARER_CAPABILITY
		call	AccessPointGetStringProperty	; cx = strlen
							; bx = dataBlock
EC <		WARNING_C	PPP_PAD_NO_BEARER_CAPABILITY               >
		jc	noBearer
		jcxz	freeBlk		; block still needs to be freed

	;
	; Send the capability data to PAD and PAD will free it.
	;
		mov	cx, PAD_PPP_CLIENT		; clientId
		mov	dx, bx				; dataBlock
		mov	ax, MSG_PAD_DATA
		movdw	bxsi, ds:[padOptr]
		mov	di, mask MF_FORCE_QUEUE
		call 	ObjMessage			; dataBlock deleted

	;
	; Get PAD response and return, if any, carry flag and ax=errorCode.
	;
		call	PPPGetPADResponse	; return carry flag & ax
		jmp	exit
freeBlk:	
		pushf
		call	MemFree
		popf
exit:		
		.leave
		ret

noBearer:
		clc
		jmp	exit

PPPSetPADCapability	endp

endif ; if _PENELOPE


if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPGetPADResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get PAD's response(s). Other messages sent to PPP process 
		will be ignored except those by PAD. We return when we get
		a serial driver handle or a failure message from PAD.

CALLED BY:	PPPConnectWithPAD

PASS:		ds	= dgroup

RETURN:		carry clear if success
			ax =  atTranslationType_e
				 (PAD_AT_CONNECT, 
				  PAD_AT_OK)

			and   ds:[padStreamDr],
			      ds:[padDnStream], &
	                      ds:[padUpStream] 
			can be used for communication.

		carry set if error
			ax = atTranslationType_e
				(PAD_AT_NO_CARRIER,
				 PAD_AT_NO_DIALTONE,
			   	 PAD_AT_BUSY,
				 PAD_AT_ERROR)

DESTROYED:	ax, bx, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: Sit in a loop to wait for PAD messages.

		      If not in {MSG_CLIENT_DATA_PROTO, 
				MSG_CLIENT_CONNECT_PROTO,
				MSG_CLIENT_ERROR_PROTO,
				MSG_META_NULL},
			then return PAD_AT_ERROR.

		      else if not MSG_META_NULL
			call the method handler
			check our state after calling the method
			return if error or connected.

		      else
			ignore MSG_META_NULL
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPGetPADResponse	proc	near
	uses	di
queue		local	word				; uses bp
	.enter
		mov	ax, TGIT_QUEUE_HANDLE
		mov	bx, ds:[pppThread]
		call	ThreadGetInfo
		mov	ss:queue, ax

nextMsg:
		mov	bx, ss:queue
		call 	QueueGetMessage
		mov	bx, ax				; ax = message handle
	
		call	ObjGetMessageInfo
		cmp	ax, MSG_META_NULL
		jne	dontIgnore				
		jmp 	nextMsg

dontIgnore:	
	;
	; Must process _DATA_, _CONNECT_, and _ERROR_ messages. Others are
	; considered as errors.
	;
		cmp	ax, MSG_CLIENT_DATA_PROTO
		jne	ok1
		jmp	processPADMsg

ok1:
		cmp	ax, MSG_CLIENT_CONNECT_PROTO
		jne	ok2
		jmp	processPADMsg

ok2:
		cmp	ax, MSG_CLIENT_ERROR_PROTO
		je	processPADMsg
	;
	; I am expecting a PAD message. Do not process non-PAD that
  	; that use padUpStream/padDnStream as these vars are not
        ; valid for communication while we are talking to PAD.
	;
		jmp	nextMsg

processPADMsg:	
		mov	ds:[padSignalDone], 0		; FALSE
		mov	di, mask MF_CALL		; always direct call
		push	bp
		call	MessageDispatch			; destroys bp
		pop	bp
		tst	ds:[padSignalDone]
		jz	nextMsg
		mov	ax, ds:[padResponse]

	;
	; The only success codes are PAD_OK and PAD_AT_CONNECT. If we 
	; decide to support PAD_AT_RING, then we will accept this code
	; as no error as well.
	;
		cmp	ax, PAD_AT_OK
		jne	checkConnect
		clc	
		jmp	exit
checkConnect:
		cmp	ax, PAD_AT_CONNECT
		jne	error
		clc
		jmp	exit

error:
		stc
exit:
	.leave
	ret
PPPGetPADResponse	endp

endif ; _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStrAllocCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a memory block and copy a string to it.

CALLED BY:	PPPDisconnectFromPAD

PASS:		ds:si 	= string to allocate and copy (need not be
			  null-terminated)
		cx	= length of string in bytes

RETURN:		bx 	= new memory block containing null-terminated
			  string
		Else carry set if error

DESTROYED:	ax, cx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStrAllocCopy	proc	near
	.enter
		push	cx
		inc	cx			; if not null-terminated
		mov	ax, cx
		mov	cx, ALLOC_DYNAMIC_LOCK or \
				(mask HAF_ZERO_INIT shl 8) or \
				mask HF_SHARABLE
		mov	bx, handle 0		; PPP is owner of block
		call	MemAllocSetOwner	; ax = address of block
		pop	cx
		jc	error

	;
	; Copy the passed in string to allocated buffer.
	;	
		push	es, di, ax
		pop	es
		clr	di			; es:di = target
		rep	movsb			; for cx, do ds:si -> es:di 
		pop	es, di
		call	MemUnlock
		clc
error:
	.leave
	ret
PPPStrAllocCopy	endp

endif ; _PENELOPE

if _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPStrAllocStrcat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block and concate two strings.

CALLED BY:	PPPConnectWithPAD

PASS:		ds:si 	= first string
		cx 	= length of first string
		es:di	= second string
		dx	= length of second string

RETURN:		bx 	= new block containing ds:si + es:di.
		else
		carry set if error

DESTROYED:	ax, cx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kkee	11/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPStrAllocStrcat	proc	near
	uses	dx,si
	.enter
	;
	; Allocate a block of size (cx + dx + 1) and initialize to zero.
	; 
		push	cx
		mov	ax, cx
		add	ax, dx			
		inc	ax			; ax = new string length
		mov	cx, ALLOC_DYNAMIC_LOCK or \
				(mask HAF_ZERO_INIT shl 8) or \
				mask HF_SHARABLE
		mov	bx, handle 0		; PPP is owner of block
		call	MemAllocSetOwner	; ax = address of block
		pop	cx
		jc	error

	;
	; Concate two strings.
	;	
		push	es, di
		mov	es, ax
		clr	di			; es:di = target
		rep	movsb			; first string
		mov	cx, dx
		pop	ds, si			; ds:di	= second string
		push	ds, si
		rep	movsb			; second string
		pop	es, di
		call	MemUnlock
		clc
error:
	.leave
	ret
PPPStrAllocStrcat	endp

endif ; _PENELOPE

ConnectCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPModemSignalChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we get a carrier detect drop while connected, we have
		to force terminate the connection.

CALLED BY:	MSG_PPP_MODEM_SIGNAL_CHANGE

PASS:		ds	= dgroup
		es 	= segment of PPPProcessClass
		ax	= message #
		cx	= ModemLineStatus

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/02/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPModemSignalChange	method dynamic PPPProcessClass, 
					MSG_PPP_MODEM_SIGNAL_CHANGE
		test	cx, mask MLS_DCD_CHANGED
		jz	done
		test	cx, mask MLS_DCD
		jnz	done

	; At this point, we know that the carrier detect has dropped.
	; If we had a connection, we need to terminate this whole shebang
	; and get outta dodge!
	;
		cmp	ds:[clientInfo].PCI_linkState, PLS_CLOSING
		jbe	done

		clr	ax
		push	ax			; unit # ???
		call	PPPCallTerminated

done:
		ret
PPPModemSignalChange	endm


ConnectCode	ends




