COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS	
MODULE:		IrCOMM
FILE:		portemulatorMain.asm

AUTHOR:		Greg Grisco, Dec  5, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95   	Initial revision


DESCRIPTION:
	Port Emulation interface to IrCOMM
		

	$Id: portemulatorMain.asm,v 1.1 97/04/18 11:46:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Internal/strDrInt.def
include	timer.def

;------------------------------------------------------------------------------
;	Driver info table
;------------------------------------------------------------------------------

ResidentCode	segment	resource

DriverTable	DriverInfoStruct	<
	IrCommStrategy, mask DA_CHARACTER, DRIVER_TYPE_STREAM
>

ForceRef	DriverTable

ResidentCode	ends


IrCommClassStructure	segment	resource
    IrCommProcessClass	mask CLASSF_NEVER_SAVED
IrCommClassStructure	ends


;------------------------------------------------------------------------------
;		       MISCELLANEOUS VARIABLES
;------------------------------------------------------------------------------

idata		segment

vmFile		hptr		-1	; handle to HugeLMem file

openAddr	dword			; address of printer to talk to
ircommLSAP	byte			; LSAP in printer to talk to

discoverySem	Semaphore <0>		; place to block waiting for discovery 
outputSem	Semaphore <1>		; lock for output stream
creditSem	Semaphore <1>		; lock credit tracker

streamSemaphore	Semaphore <1,>		; When dealing with the stream,
					; we lock this semaphore so
					; no other thread can free
					; or change the stream data

iasIgnore	byte			; set true after first Ias response,
					;  so if get disconnect indication,
					;  while attempting to connect to
					;  IrCOMM LSAP we ignore it and don't
					;  V the discoverySem

threadHandle	hptr			; event thread for timer mesg

portNum		word			; used for passing data to timer 
					; method.  We'll use a lock for this 
					; if we ever allow more than one port.

flushTime	word			; number of ticks to wait before 
					; forcing a packet to be sent
if HANDLE_JEOPARDY_CASE
rwStartTime	dword			; the time at which we started
					; a read or a write.
endif

irPort		IrSerialPortData	<0,0,0,0,0,0,0,0>

idata		ends



ResidentCode	segment	resource
DefFunction	macro	funcCode, routine
if ($-ircommFunctions) ne funcCode
	ErrMessage <routine not in proper slot for funcCode>
endif
		nptr	routine
		endm

ircommFunctions	label	nptr
DefFunction	DR_INIT,			IrCommInit
DefFunction	DR_EXIT,			IrCommExit
DefFunction	DR_SUSPEND,			IrCommNull
DefFunction	DR_UNSUSPEND,			IrCommNull
DefFunction	DR_STREAM_GET_DEVICE_MAP,	IrCommGetDeviceMap
DefFunction	DR_STREAM_OPEN,			IrCommOpen
DefFunction	DR_STREAM_CLOSE,		IrCommClose
DefFunction	DR_STREAM_SET_NOTIFY,		IrCommSetNotify
DefFunction	DR_STREAM_GET_ERROR,		IrCommCallStreamDriver
DefFunction	DR_STREAM_SET_ERROR,		IrCommCallStreamDriver
DefFunction	DR_STREAM_FLUSH,		IrCommCallStreamDriver
DefFunction	DR_STREAM_SET_THRESHOLD,	IrCommCallStreamDriver
DefFunction	DR_STREAM_READ,			IrCommRead
DefFunction	DR_STREAM_READ_BYTE,		IrCommReadByte
DefFunction	DR_STREAM_WRITE,		IrCommWrite
DefFunction	DR_STREAM_WRITE_BYTE,		IrCommWriteByte
DefFunction	DR_STREAM_QUERY,		IrCommCallStreamDriver
DefFunction	DR_SERIAL_SET_FORMAT,		IrCommSetFormat
DefFunction	DR_SERIAL_GET_FORMAT,		IrCommGetFormat
DefFunction	DR_SERIAL_SET_MODEM,		IrCommSetModem
DefFunction	DR_SERIAL_GET_MODEM,		IrCommGetModem

DefFunction	DR_SERIAL_OPEN_FOR_DRIVER,	IrCommNull

DefFunction	DR_SERIAL_SET_FLOW_CONTROL,	IrCommSetFlowControl

DefFunction	DR_SERIAL_DEFINE_PORT,		IrCommNull
DefFunction	DR_SERIAL_STAT_PORT,		IrCommNull
DefFunction	DR_SERIAL_CLOSE_WITHOUT_RESET,	IrCommNull
DefFunction	DR_SERIAL_REESTABLISH_STATE,	IrCommNull
DefFunction	DR_SERIAL_PORT_ABSENT,		IrCommNull

DefFunction	DR_SERIAL_GET_PASSIVE_STATE,	IrCommNull

DefFunction	DR_SERIAL_GET_MEDIUM,		IrCommNull
DefFunction	DR_SERIAL_SET_MEDIUM,		IrCommNull

DefFunction	DR_SERIAL_SET_BUFFER_SIZE,	IrCommNull
DefFunction	DR_SERIAL_ENABLE_FLOW_CONTROL,	IrCommEnableFlowControl
DefFunction	DR_SERIAL_SET_ROLE,		IrCommSetRole


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all ircomm-driver functions

CALLED BY:	GLOBAL
PASS:		di	= routine number
		bx	= port number
RETURN:		depends on function, but can always return:
		carry set with AX = StreamError
DESTROYED:	

PSEUDO CODE/STRATEGY:
		
	IrCOMM does not currently handle passive connections the same
	way as the serial driver.  In the serial driver, a passive
	port is opened and notifies the SNE_PASSIVE callback when data
	is put into the input buffer (no writes are allowed in the
	passive case).  When the client gets notified, it may open the
	port actively, in which case the passive port is preempted and
	the active port inherits all of the data in the passive port's
	buffer. 

	Using IrCOMM, an application may want to open the port without
	attempting to make a connection, but rather to act as the
	secondary  and receive connect indications.  To allow this, an
	application will connect "passively" in which Discovery, IAS
	query, and Connect Request will not happen.  The streams are
	not created until a connection has been established until
	which time the client is not allowed to write to the stream.

	Of course, if an application opens an "active" port but the
	connect request doesn't happen (or fails), the port remains
	open and will accept connect indications from the remote.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrCommStrategy proc	far	
	uses	bx,es,ds
	.enter
if 0
	;
	; Force a "Passive" connection for testing purposes.
	;
	or	bx, SERIAL_PASSIVE
endif

EC <	cmp	di, SerialFunction					>
EC <	ERROR_AE	IRCOMM_ILLEGAL_FUNCTION				>

	segmov	es, ds				; In case seg passed in ds

	call	IrCommGetDGroupDS		; ds = dgroup

	cmp	di, DR_STREAM_OPEN
	jbe	notYetOpen

	call	UtilsGetPortData		; bx = index to port data
	jc	exit

EC <	call	ECValidateUnitNumber					>
notYetOpen:
	PSem	ds, streamSemaphore
	push	ds				; save dgroup in case the
						;   called routine trashes
						;   it.
	call	cs:ircommFunctions[di]		; call the function
	pop	ds				; ds = dgroup
	pushf
	VSem	ds, streamSemaphore
	popf
exit:
	.leave
	ret
IrCommStrategy endp

global	IrCommStrategy:far



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a HugeLMem file which will be used for creating
		the data blocks which are passed to the lower layers
		of the Ir stack.

CALLED BY:	DR_INIT
PASS:		ds	= dgroup (set by IrCommStrategy)
RETURN:		carry set if driver initialization failed (couldn't
		create the HugeLMem due to lack of memory)
DESTROYED:	nothing
SIDE EFFECTS:	

	vmFile filled in with handle to newly created HugeLMem file

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommInit	proc	near
	uses	ax,bx,cx
	.enter

	mov	ax, 32				; default max # of blocks
	mov	bx, 1024			; min size for optimal block
	mov	cx, 4096			; max size for optimal block

	call	HugeLMemCreate			; bx = handle of HugeLMem
	jc	done				; couldn't create
	mov	ds:[vmFile], bx
done:
	.leave
	ret
IrCommInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exiting the driver...destroy the HugeLMem file as it
		will no longer be needed.

CALLED BY:	DR_EXIT
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

	HugeLMem file destroyed and vmFile set to -1

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommExit	proc	near
	uses	bx,ds
	.enter

	call	IrCommGetDGroupDS		; ds = dgroup
	mov	bx, ds:[vmFile]
	cmp	bx, -1				; does one exist?
	je	done

	call	HugeLMemDestroy
done:
	.leave
	ret
IrCommExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommGetDeviceMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns all ports as being valid

CALLED BY:	DR_STREAM_GET_DEVICE_MAP
PASS:		nothing
RETURN:		ax	= SerialDeviceMap
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommGetDeviceMap	proc	near
	.enter

	mov	ax, mask SDM_COM1 or mask SDM_COM2 or mask SDM_COM3 or mask SDM_COM4

	.leave
	ret
IrCommGetDeviceMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init function, does nothing for non-hardware

CALLED BY:	DR_INIT, DR_EXIT (IrCommStrategy)
PASS:		ds	= dgroup
RETURN:		Carry clear if we're happy
DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommNull	proc	near
		clc
		ret
IrCommNull	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the Ir port

CALLED BY:	DR_STREAM_OPEN (IrCommStrategy)
PASS:		ax	= StreamOpenFlags
		bx	= port number
		cx	= input buffer size
		dx	= output buffer size
		bp	= timeout value if SOF_TIMEOUT
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		carry set on error
			ax	= error code
DESTROYED:	ax if no error
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Assign a new element in the array
	Register with TinyTP
	Register with IAS server
	Attempt to connect

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommOpen	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter
PrintMessage <"Fix STREAM_DEVICE_IN_USE when STREAM_BLOCK passed">
	;
	; DR_STREAM_OPEN should only return STREAM_DEVICE_IN_USE if
	; NO_BLOCK or TIMEOUT was passed.  Fix this!
	;
	call	UtilsGetPortData		; bx = index to port data
	tst	ds:[bx].ISPD_outStream
	jnz	alreadyInUse			; return error
	;
	; The process handled will be used later when we create the
	; event thread (after a connection is established)
	;
	push	bx
	call	GeodeGetProcessHandle
	mov	si, bx
	pop	bx				; bx = index to port data
	mov	ds:[bx].ISPD_procHandle, si	; save process handle
	;
	; Save the port number for the timer handlers
	;
EC <	call	ECValidateUnitNumber					>
	mov	ds:[portNum], bx

	test	ds:[bx].ISPD_passive, mask SPS_PASSIVE
	jz	openActive
	;
	; Open the port passively, do not initiate the connection
	;
	call	IrCommPassiveOpen
	jmp	done				; just exit
	;
	; Open the Active Port
	;
openActive:
if ERROR_CHECK
	test	ax, not StreamOpenFlags
	ERROR_NZ	-1
	test	ax, mask SOF_NOBLOCK or mask SOF_TIMEOUT
	jz	flagsOk				; neither is ok
	jpo	flagsOk				; just one is fine
	ERROR		-1
flagsOk:
endif
	mov	ds:[bx].ISPD_inStreamSize, cx	; size of input stream
	mov	ds:[bx].ISPD_outStreamSize, dx	; size of output stream

	mov	ds:[bx].ISPD_state, ICFS_IDLE	; initially in idle state
	;
	; Register with TinyTP
	;
	mov	cl, IRLMP_ANY_LSAP_SEL
	mov	dx, vseg IrCommTTPCallback
	mov	ax, offset IrCommTTPCallback
	call	TTPRegister			; si = client, cl = LSAP
	jc	errorNoUnregister		; exit if register failed

	mov	ds:[bx].ISPD_client, si		; save TinyTP client handle
	;
	; Create an IAS object and add it to the IAS server
	;
;	call	IrAddToIas
	;
	; Connect if someone out there is listening.  If the
	; connection was already made passively, no further action
	; will be taken.
	;
	call	PortEmulatorEstablishConnection
	jc	error
if 0
;
; Now, we're going to return an error if the connection could not be
; made.  Although this might be a bit inconvenient (the application
; will need to call DR_STREAM_OPEN again when the other device is in
; range) it keeps things from getting messy (subsequent calls to other
; functions will result in error instead of prompting multiple
; discoveries).
;
	;
	;  The port has been opened, regardless of whether we've made
	;  a connection or not.  Since the serial driver does not
	;  return error if nobody is listening on the other side,
	;  neither shall we.
	;
	clc					; regardless of conn status
endif
done:
	.leave
	ret
error:
	;
	; We were unable to establish the connection.  Unregister from
	; TinyTP and return error.
	;
	mov	si, ds:[bx].ISPD_client
	call	TTPUnregister
errorNoUnregister:
	;
	; We had trouble making an Ir connection for one reason or
	; another.  Return the proper error.
	;
	mov	ax, STREAM_NO_DEVICE
	stc
	jmp	done
alreadyInUse:
	mov	ax, STREAM_DEVICE_IN_USE
	stc
	jmp	done
IrCommOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommPassiveOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens a passive connection for the client which does
		not make a connect request, but rather waits to be
		connected to.  The passive connection will never send
		data, so creation of the output stream is unnecessary.
		The passive connection may be preempted by any client
		trying to make an active connection on the same port.

CALLED BY:	IrCommOpen
PASS:		bx	= unit number
		cx	= input buffer size
		dx	= output buffer size
		ds	= dgroup
RETURN:		carry set and ax set to one of the following:
		  ax 	= STREAM_NO_DEVICE if device doesn't exist
			= STREAM_DEVICE_IN_USE if the passive port is in use.
			= STREAM_ACTIVE_IN_USE if the passive port was opened
			  in a PREEMPTED state.

		carry clear if the port opened with no problems.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommPassiveOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	andnf	ds:[bx].ISPD_passive, not (mask SPS_BUFFER_FULL or mask SPS_PREEMPTED)
	mov	ds:[bx].ISPD_inStreamSize, cx
	mov	ds:[bx].ISPD_outStreamSize, dx
	;
	; Register with TinyTP
	;
	mov	cl, IRLMP_ANY_LSAP_SEL
	mov	dx, vseg IrCommTTPCallback
	mov	ax, offset IrCommTTPCallback
	call	TTPRegister			; si = client, cl = LSAP
	jc	done
	clr	ch
	mov	ds:[bx].ISPD_client, si		; save TinyTP client handle
	;
	; Create an IAS object and add it to the IAS server
	;
	call	IrAddToIas
	jc	error
done:
	.leave
	ret
error:
	;
	; Unregister from TinyTP
	;
	clr	ds:[bx].ISPD_client
	call	TTPUnregister
	stc
	jmp	done
IrCommPassiveOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the Ir Port

CALLED BY:	DR_STREAM_CLOSE (IrCommStrategy)
PASS:		ax	= STREAM_LINGER or STREAM_DISCARD
		bx	= unit number
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	If we are connected:

		Destroy the streams (this will flush them)
		Wait til TinyTP & IrLMP have sent everything
		Send a disconnect request

	If stream was opened (which it was if we were connected):

		Remove the IAS entry
		Unregister from TinyTP
		Destroy the IrComm entry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommClose	proc	near
	uses	dx
	.enter

	mov	dx, ds:[bx].ISPD_state
	cmp	dx, ICFS_CONN			; are we connected?
	jne	noConnect
	;
	; Streams exist and data may be hanging around.  Destroy the
	; streams (which will flush them), and wait til everything sent.
	;
	; We free the semaphore here because PortEmulatorDestroyStreams
	; will want to lock it down.
	;
	VSem	ds, streamSemaphore
	call	PortEmulatorDestroyStreams
	PSem	ds, streamSemaphore
noConnect:
	cmp	dx, ICFS_IDLE
	je	idleState
	;
	; A connection has either been established or is pending.  We
	; need to send a disconnect request.
	;
	call	PortEmulatorDisconnect
idleState:
	;
	; No connection or streams exist.  Remove the IAS entry,
	; Unregister from TinyTP and destory the IrComm entry.
	;
	call	PortEmulatorCleanup
	call	PortEmulatorClearNotifiers

	.leave
	ret
IrCommClose	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommCallStreamDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Passes the request to the stream driver

CALLED BY:	SerialStrategy
PASS:		bx	= unit number
		di	= function
		ds	= dgroup (passed by IrCommStrategy)
		other registers depend on di
RETURN:		depends on di
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommCallStreamDriver	proc	near
	uses	bx,bp
	.enter

EC <	call	ECValidateUnitNumber		; is bx ok?		>
	mov	bp, bx				; bp = unit number

	mov	bx, ds:[bp].ISPD_inStream	; bx = input stream token
	cmp	ax, STREAM_READ
	je	gotStream
	mov	bx, ds:[bp].ISPD_outStream	; bx = output stream token
gotStream:
	tst	bx
	jz	error
	call	StreamStrategy			; pass the call along
done:
	.leave
	ret
error:
	stc
	jmp	done
IrCommCallStreamDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommSetNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a notifier for the caller

CALLED BY:	DR_STREAM_SET_NOTIFY
PASS:		ax	= StreamNotifyType
		bx	= unit number
		cx:dx	= address of handling routine if SNT_ROUTINE
			  destination of output if SNT_MESSAGE
		bp	= AX to pass if SNM_ROUTINE (except for SNE_DATA with
			  threshold of 1, in which case value is passed in CX);
			  method to send if SNM_MESSAGE.
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommSetNotify	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Find out what type of event it is
	;
	mov	si, ax				; si = StreamNotifyType
	and	si, mask SNT_EVENT		; isolate the event field

	call	PortEmulatorSetEventLocal

	cmp	si, SNE_MODEM shl offset SNT_EVENT
if NOTIFY_WHEN_SNE_MODEM_CHANGED
	je	modemNotify
else
	je	done
endif
	cmp	si, SNE_PASSIVE shl offset SNT_EVENT
	je	done
	;
	; Let the stream driver take care of the rest
	;
	mov	si, bx				; si = unit number
	mov	bx, ds:[si].ISPD_inStream
	test	ax, mask SNT_READER
	jne	gotStream
	mov	bx, ds:[si].ISPD_outStream
gotStream:
	tst	bx				; does stream exist?
	jz	done
	call	StreamStrategy
done:
	clc
	.leave
	ret
if NOTIFY_WHEN_SNE_MODEM_CHANGED
modemNotify:
	call	PortEmulatorNotifyModemEventChanged
	jmp	done
endif

IrCommSetNotify	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorSetEventLocal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the event locally, just so that it can be
		retrieved later if the streams must be created again 
		due to re-connect.  Stream notifications will be
		handled by the stream driver, whereas ircomm will use
		these settings for modem & passive callbacks.

CALLED BY:	IrCommSetNotify
PASS:		ax	= StreamNotifyType
		bx	= unit number
		cxdx	= address of handling routine if SNM_ROUTINE
			  destination of output if SNM_MESSAGE
		si	= StreamEvent
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorSetEventLocal	proc	near
	uses	ax,di
	.enter

	lea	di, ds:[bx].ISPD_modemEvent
	cmp	si, SNE_MODEM shl offset SNT_EVENT
	je	setLocal

	lea	di, ds:[bx].ISPD_dataEvent
	cmp	si, SNE_DATA shl offset SNT_EVENT
	je	setLocal

	lea	di, ds:[bx].ISPD_errorEvent
	cmp	si, SNE_ERROR shl offset SNT_EVENT
	je	setLocal

	lea	di, ds:[bx].ISPD_passiveEvent
setLocal:
	andnf	ax, mask SNT_HOW
	mov	ds:[di].SN_type, al
	mov	ds:[di].SN_dest.SND_routine.low, dx
	mov	ds:[di].SN_dest.SND_routine.high, cx
	mov	ds:[di].SN_data, bp

	.leave
	ret
PortEmulatorSetEventLocal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorNotifyModemEventChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the notifier callback (routine or message) to
		let it know the current state of the modem.

CALLED BY:	INTERNAL (IrCommSetNotify)
PASS:		bx	= unit number
		ds	= dgroup
RETURN:		carry set if no stream
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if NOTIFY_WHEN_SNE_MODEM_CHANGED

PortEmulatorNotifyModemEventChanged	proc	near
	uses	ax,cx,di,es
	.enter
	;
	; The client might want to know the initial settings of DTR &
	; RTS.  Lets send those right away.
	;
	mov	ax, ds:[bx].ISPD_inStream
	tst	ax
	jnz	haveStream
	mov	ax, ds:[bx].ISPD_outStream
haveStream:
	tst	ax
	jz	error
	mov	cl, ds:[bx].ISPD_modemStatus
	;
	; Mark the status bits as having changed so that the client
	; will pay attention to them.
	;
	or	cl, mask SMS_DTR_CHANGED or mask SMS_RTS_CHANGED or mask SMS_DSR_CHANGED or mask SMS_CTS_CHANGED

	mov	es, ax				; es = stream
	lea	di, ds:[bx].ISPD_modemEvent	; ds:di=streamNotifier
	mov	ah, STREAM_NOACK
	call	StreamNotify			; send notification
done:
	.leave
	ret
error:
	stc					; signal error
	jmp	done
PortEmulatorNotifyModemEventChanged	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read data from the Ir port

CALLED BY:	DR_STREAM_READ (IrCommStrategy)
PASS:		ax	= STREAM_BLOCK / STREAM_NO_BLOCK
		bx	= unit number
		cx	= number of bytes to read
		es:si	= buffer which to read to (was ds:si)
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		carry set if no input stream
		cx	= number of bytes read
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	In order to keep connections "in-jeopardy" transparent from
	the application, we need to block while the connection is
	uncertain even though the application specified
	STREAM_NO_BLOCK.  This means that we also need to block for at
	least three seconds if there is no data in the stream since
	that is the amount of time in Ir that it takes to establish
	that the connection is in jeopardy. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version
	grisco	 5/22/96	Conditional compile for jeopardy case

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommRead	proc	near
blockFlag	local	word	push ax
bytesToRead	local	word	push cx
	uses	bx,dx

	.enter

	call	CheckConnection
	jc	noInputStream			; error - no char read
if HANDLE_JEOPARDY_CASE
	;
	; Get the current time in case we need to wait later for the
	; connection status to be determined.
	;
	push	bx
	call	TimerGetCount
	movdw	ds:[rwStartTime], bxax
	pop	bx
endif
	;
	; Read from the stream and see if we were successful
	;
	mov	dx, bx				; save unit number
	mov	bx, ds:[bx].ISPD_inStream
	tst	bx
	jz	noInputStream
	segxchg	ds, es, ax			; ds:si = buffer to write to
						; es:dx = IrSerialPortData
if HANDLE_JEOPARDY_CASE
readByte:
endif
	mov	ax, ss:[blockFlag]
	mov	cx, ss:[bytesToRead]
	call	StreamStrategy			; cx = # of bytes read
if HANDLE_JEOPARDY_CASE
	jcxz	checkJeopardy			; no bytes read
else
	jcxz	done
endif
	;
	; We read some bytes.  Now update the counter so that we know
	; whether to advance credits or not.
	;
	push	ds, si
	mov	si, dx				; si = unit number
	segmov	ds, es, ax			; ds = dgroup
	call	HandleCreditCounterRead
	pop	ds, si				; ds:si = buffer
	clc					; no error
done:
	.leave
	ret
if HANDLE_JEOPARDY_CASE
checkJeopardy:
	;
	; A byte could not be read.  If we are in jeopardy, block
	; until the connection is re-established or lost.
	;
	push	ds, si
	segmov	ds, es, ax			; ds = dgroup
	mov	si, dx				; si = unit number
	call	BlockWhileInJeopardy
	pop	ds, si
	jc	done				; connection lost
	;
	; Ok.  There was no byte to read and we are not in jeopardy.
	; BUT, it takes three seconds or so for Ir to detect that the
	; connection is blocked.  Loop for three seconds before we
	; return an error.
	;
	push	bx, ds
	segmov	ds, es, ax			; ds = dgroup
	movdw	bxax, ds:[rwStartTime]
	call	AllowJeopardyToBeDetected
	pop	bx, ds
	jnc	readByte
	;
	; There was no byte to read and the connection was not
	; blocked.  Return an error.
	;
	clr	cx
	jmp	done
endif
noInputStream:
	mov	ax, STREAM_CLOSED
	clr	cx				; no bytes read
	stc					; signal error
	jmp	done

IrCommRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommReadByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a single byte from the Ir port

CALLED BY:	DR_STREAM_READ_BYTE (IrCommStrategy)
PASS:		ax	= STREAM_BLOCK / STREAM_NO_BLOCK
		bx	= unit number
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		al	= byte read
		carry set if no byte available and STREAM_NO_BLOCK
DESTROYED:	bx	(saved by IrCommStrategy)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	In order to keep connections "in-jeopardy" transparent from
	the application, we need to block while the connection is
	uncertain even though the application specified
	STREAM_NO_BLOCK.  This means that we also need to block for at
	least three seconds if there is no data in the stream since
	that is the amount of time in Ir that it takes to establish
	that the connection is in jeopardy.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version
	grisco	 5/22/96	Conditional compile for jeopardy case

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommReadByte	proc	near
blockFlag	local	word	push ax
	uses	cx, si
	.enter

	call	CheckConnection
	jc 	done				; no char -- return error
if HANDLE_JEOPARDY_CASE
	;
	; Get the current time in case we need to wait later for the
	; connection status to be determined.
	;
	push	bx
	call	TimerGetCount
	movdw	ds:[rwStartTime], bxax
	pop	bx
endif
	;
	; Read from the stream and see if we were successful
	;
	mov	si, bx				; save unit number
	mov	bx, ds:[bx].ISPD_inStream
	tst	bx
	jz	noInputStream
if HANDLE_JEOPARDY_CASE
readByte:
endif
	mov	ax, ss:[blockFlag]		; ax = STREAM_BLOCK/NO_BLOCK
	call	StreamStrategy			; al = byte read if no carry
if HANDLE_JEOPARDY_CASE
	jc	checkJeopardy			; no byte to be read
else
	jc	done				; return error
endif
	;
	; We read a byte.  Now update the counter so that we know
	; whether to advance a credit or not.
	;
	mov	cx, 1				; one byte read
	call	HandleCreditCounterRead
	clc					; no error
done:
	.leave
	ret
if HANDLE_JEOPARDY_CASE
checkJeopardy:
	;
	; A byte could not be read.  If we are in jeopardy, block
	; until the connection is re-established or lost.
	;
	call	BlockWhileInJeopardy
	jc	done				; connection lost
	;
	; Ok.  There was no byte to read and we are not in jeopardy.
	; BUT, it takes three seconds or so for Ir to detect that the
	; connection is blocked.  Loop for three seconds before we
	; return an error.
	;
	push	bx
	movdw	bxax, ds:[rwStartTime]
	call	AllowJeopardyToBeDetected
	pop	bx
	jnc	readByte
	;
	; There was no byte to read and the connection was not
	; blocked.  Return an error.
	;
	stc
	jmp	done
endif
noInputStream:
	mov	ax, STREAM_CLOSED
	pop	bx
	stc					; signal error
	jmp	done

IrCommReadByte	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes a buffer to the Ir port

CALLED BY:	DR_STREAM_WRITE (IrCommStrategy)
PASS:		ax	= STREAM_BLOCK / STREAM_NO_BLOCK
		bx	= unit number
		cx	= number of bytes to write
		es:si	= buffer from which to write (was ds:si)
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		cx	= number of bytes written
		carry set if no output stream
			ax = STREAM_CLOSED
		else
			ax = destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Write to the stream.  When the stream rises above the
	threshold it will call our callback routine, PortEmulatorNotify()

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version
	grisco	 5/22/96	Conditional compile for jeopardy case

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommWrite	proc	near
blockFlag	local	word	push ax
numBytes	local	word	push cx
	uses	bx,ds
	.enter

	call	CheckConnection
	jc	noOutputStream			; exit if no connection

	mov	bx, ds:[bx].ISPD_outStream	; point to output stream
	tst	bx				; do we have one?
	jz	noOutputStream
	push	ds
if HANDLE_JEOPARDY_CASE
	;
	; Get the current time so that we know how long to wait for
	; jeopardy to be detected if the write fails.
	;
	push	bx
	call	TimerGetCount
	movdw	ds:[rwStartTime], bxax
	pop	bx
writeBlock:
endif
	;
	; Block before writing the byte if the timer method handler is
	; reading bytes from the stream to send them off.
	;
	PSem	ds, outputSem
	segmov	ds, es				; ds <- buffer segment for
						;  stream driver
	mov	ax, ss:[blockFlag]
	mov	cx, ss:[numBytes]
	call	StreamStrategy			; write to the stream
	pop	ds				; ds = dgroup
	VSem	ds, outputSem
if HANDLE_JEOPARDY_CASE
	jcxz	checkJeopardy
endif
done:
	.leave
	ret
if HANDLE_JEOPARDY_CASE
checkJeopardy:
	;
	; A byte could not be written.  If we are in jeopardy, block
	; until the connection is re-established or lost.
	;
	call	BlockWhileInJeopardy
	jc	done				; connection lost
	;
	; Ok.  There was no byte to read and we are not in jeopardy.
	; BUT, it takes three seconds or so for Ir to detect that the
	; connection is blocked.  Loop for three seconds before we
	; return an error.
	;
	push	bx
	movdw	bxax, ds:[rwStartTime]
	call	AllowJeopardyToBeDetected
	pop	bx
	push	ds
	jnc	writeBlock
	pop	ds				; ds = dgroup
	;
	; There was no byte to read and the connection was not
	; blocked.  Return an error.
	;
	jmp	done
endif
noOutputStream:
	mov	ax, STREAM_CLOSED
	clr	cx				; no bytes written
	stc					; signal error
	jmp	done

IrCommWrite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommWriteByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes a single byte to the Ir port

CALLED BY:	DR_STREAM_WRITE_BYTE (IrCommStrategy)
PASS:		ax	= STREAM_BLOCK / STREAM_NO_BLOCK
		bx	= unit number
		cl	= byte to write
		ds	= dgroup (passed from IrCommStrategy)
RETURN:		carry set if byte couldn't be written and STREAM_NO_BLOCK
			ax = STREAM_CLOSED
		else
			ax = destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Write the byte to the output stream.  If this causes the
	stream to reach the threshold then this will cause our
	data callback to be called and data to be sent.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version
	grisco	 5/22/96	Conditional compile for jeopardy case

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommWriteByte	proc	near
blockFlag	local	word	push ax
	uses	bx
	.enter

	call	CheckConnection
	jc	error				; exit if no connection

	mov	bx, ds:[bx].ISPD_outStream	; point to output stream
	tst	bx				; do we have one?
	jz	error
if HANDLE_JEOPARDY_CASE
	;
	; Get the current time so that we know how long to wait for
	; jeopardy to be detected if the write fails.
	;
	push	bx
	call	TimerGetCount
	movdw	ds:[rwStartTime], bxax
	pop	bx
writeByte:
endif
	;
	; Block before writing the byte if the timer method handler is
	; reading bytes from the stream to send them off.
	;
	PSem	ds, outputSem
	mov	ax, ss:[blockFlag]
	call	StreamStrategy			; write the byte
	VSem	ds, outputSem
if HANDLE_JEOPARDY_CASE
	jc	checkJeopardy
endif
done:
	.leave
	ret
if HANDLE_JEOPARDY_CASE
checkJeopardy:
	;
	; A byte could not be written.  If we are in jeopardy, block
	; until the connection is re-established or lost.
	;
	call	BlockWhileInJeopardy
	jc	done				; connection lost
	;
	; Ok.  There was no byte to read and we are not in jeopardy.
	; BUT, it takes three seconds or so for Ir to detect that the
	; connection is blocked.  Loop for three seconds before we
	; return an error.
	;
	push	bx
	movdw	bxax, ds:[rwStartTime]
	call	AllowJeopardyToBeDetected
	pop	bx
	jnc	writeByte
	;
	; There was no byte to read and the connection was not
	; blocked.  Return an error.
	;
	jmp	done
endif
error:
	stc					; signal error
	mov	ax, STREAM_CLOSED
	jmp	done
IrCommWriteByte	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set data format, baud rate, and mode for a port

CALLED BY:	DR_SERIAL_SET_FORMAT
PASS:		al	= SerialFormat
		ah	= SerialMode
		bx	= unit number
		cx	= SerialBaud
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		carry set if passed an invalid format
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	If the client is a DCE, then don't store the information
	locally until we get word from the DTE that the setting is
	accepted.

NOTES:

	Most of the settings here do not actually affect the way IrLAP
	transmits/recieves data.  SerialMode, however, is necessary
	for setting the service type of the connection.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommSetFormat	proc	near

dataFormat	local	IrCommDataFormat
dataRate	local	dword
serviceType	local	IrCommServiceType

	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter
	;
	; First make the settings locally
	;
	cmp	ds:[bx].ISPD_clientRole, SR_DCE
	je	sendToPeer

	mov	ds:[bx].ISPD_curState.SPS_baud, cx
	mov	ds:[bx].ISPD_curState.SPS_format, al
	mov	ds:[bx].ISPD_mode, ah
	;
	; Send the changes to the peer
	;
sendToPeer:

	call	CheckConnection
	jc	noError				; exit if no connection

	call	MapSerialFormatToIrCommFormat	; dataFormat, serviceType,
						; and dataRate filled in.

if (ENCODED_FORMAT_PARAMS_SIZE and 1)
	sub	sp, size IrlmpDataArgs + ENCODED_FORMAT_PARAMS_SIZE + CONTROL_LENGTH_SIZE
else
	sub	sp, size IrlmpDataArgs + ENCODED_FORMAT_PARAMS_SIZE + CONTROL_LENGTH_SIZE + 1
endif
	mov	si, sp				; ss:bp = encoded params

	mov	{byte} ss:[si], ENCODED_FORMAT_PARAMS_SIZE	; Clen
	;
	; Encode the mode (service type) setting
	;
	mov	{byte} ss:[si+1], ICCP_SERVICE_TYPE	; PI
	mov	{byte} ss:[si+2], 1			; PL
	mov	al, ss:[serviceType]
	mov	{byte} ss:[si+3], al			; PV
	;
	; Encode the data format setting
	;
	mov	{byte} ss:[si+4], ICCP_DATA_FORMAT	; PI
	mov	{byte} ss:[si+5], 1			; PL
	mov	al, ss:[dataFormat]
	mov	{byte} ss:[si+6], al			; PV
	;
	; Encode the baud rate
	;
	mov	{byte} ss:[si+7], ICCP_DATA_RATE	; PI
	mov	{byte} ss:[si+8], 4			; PL
	movdw	cxdx, ss:[dataRate]
	xchg	ch, cl
	xchg	dh, dl
	mov	ss:[si+9], cx
	mov	ss:[si+11], dx				; PV

	segmov	ds, ss, ax
	call	PortEmulatorWriteControlDataFar

if (ENCODED_FORMAT_PARAMS_SIZE and 1)
	add	sp, size IrlmpDataArgs + ENCODED_FORMAT_PARAMS_SIZE + CONTROL_LENGTH_SIZE
else
	add	sp, size IrlmpDataArgs + ENCODED_FORMAT_PARAMS_SIZE + CONTROL_LENGTH_SIZE + 1
endif
	;
	; Set the flow control according to the mode.
	;
noError:
	clc

	.leave
	ret
IrCommSetFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Get the communications settings for the port

CALLED BY:	DR_SERIAL_GET_FORMAT
PASS:		bx	= unit number
RETURN:		al	= SerialFormat
		ah	= SerialMode
		cx	= SerialBaud
		ds	= dgroup (passed by IrCommStrategy)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommGetFormat	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	call	ECValidateUnitNumber			; is bx ok?	>

	mov	al, ds:[bx].ISPD_curState.SPS_format
	mov	ah, ds:[bx].ISPD_mode
	mov	cx, ds:[bx].ISPD_curState.SPS_baud

	.leave
	ret
IrCommGetFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommSetModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the modem-control bits for a port

CALLED BY:	DR_SERIAL_SET_MODEM
PASS:		al	= modem control bits (SerialModem)
		bx	= unit number
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Map SerialModem to IrCommDCESettings or IrCommDTESettings
	depending on the role.

	Encode these settings on the stack

	Pass both IrlmpDataArgs and the encoded parameters on the
	stack to IrCommControlRequest

	Store the settings locally

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommSetModem	proc	near
	.enter

EC <	test	al, not SerialModem					>
EC <	ERROR_NZ	IRCOMM_BAD_MODEM_FLAGS				>

	;
	; Make the setting locally, making sure to adjust the delta
	; bits appropriately.
	;
	cmp	ds:[bx].ISPD_clientRole, SR_DCE
	je	doDCE
	;
	; The client is a DTE.  Check if RTS or DTR changed
	;
	mov	ah, al
	and	ah, mask SMC_RTS or mask SMC_DTR
	shl	ah
	shl	ah				; ah = IrCommDTESetting
	mov	dl, ds:[bx].ISPD_curState.SPS_modem
	xor	al, dl				; al = bits that changed
	test	al, mask SMC_RTS		; did RTS change states?
	jz	testDTR
	or	ah, mask ICDTE_RTS_DELTA
testDTR:
	test	al, mask SMC_DTR		; did DTR change states?
	jz	saveDTE
	or	ah, mask ICDTE_DTR_DELTA
saveDTE:
	mov	ds:[bx].ISPD_dteSetting, ah
	mov	ds:[bx].ISPD_curState.SPS_modem, al
send:
	call	CheckConnection
	jc	noError				; exit if no connection

	call	PortEmulatorSendLineSettingsFar
noError:
	clc

	.leave
	ret
doDCE:
	;
	; The client is a DCE.  Set the current state for DCE
	;
	clr	ah
	test	al, mask SMC_DSR
	jz	testCTS
	or	ah, mask ICDCE_DSR_STATE
testCTS:
	test	al, mask SMC_CTS
	jz	testDCD
	or	ah, mask ICDCE_CTS_STATE
testDCD:
	test	al, mask SMC_DCD
	jz	testRI
	or	ah, mask ICDCE_CD_STATE
testRI:
	test	al, mask SMC_RI
	jz	testDelta
	or	ah, mask ICDCE_RI_STATE
testDelta:
	;
	; Check which lines changed and set the appropriate delta
	; bits.
	;
	mov	dl, al
	xchg	dl, ds:[bx].ISPD_curState.SPS_modem
	xor	al, dl				; al = bits that changed
	test	al, mask SMC_DSR		; did DSR change states?
	jz	ctsDelta
	or	ah, mask ICDCE_DSR_DELTA
ctsDelta:
	test	al, mask SMC_CTS		; did CTS change states?
	jz	dcdDelta
	or	ah, mask ICDCE_CTS_DELTA
dcdDelta:
	test	al, mask SMC_DCD
	jz	riDelta
	or	ah, mask ICDCE_CD_DELTA
riDelta:
	test	al, mask SMC_RI
	jz	saveDCE
	or	ah, mask ICDCE_RI_DELTA
saveDCE:
	mov	ds:[bx].ISPD_dceSetting, ah
	jmp	send

IrCommSetModem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommGetModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current state of the modem-control bits for a port

CALLED BY:	DR_SERIAL_GET_MODEM
PASS:		bx	= unit number
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		al	= SerialModem
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommGetModem	proc	near
	.enter

EC <	call	ECValidateUnitNumber		; is bx ok?		>
	;
	; The current setting is stored locally.
	;
	mov	al, ds:[bx].ISPD_curState.SPS_modem

EC <	test	al, not SerialModem					>
EC <	ERROR_NZ	IRCOMM_BAD_MODEM_FLAGS				>

	.leave
	ret
IrCommGetModem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommSetRole
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the role of the driver to DCE or DTE

CALLED BY:	DR_SERIAL_SET_ROLE (SerialStrategy)
PASS:		al	= SerialRole
		bx	= unit number
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Maybe we should check that this function isn't being called
	after UserData has been sent.  If this is the case, then
	perhaps we should return an error or just ignore it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommSetRole	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	call	ECValidateUnitNumber		; is bx ok?		>

EC <	cmp	al, SerialRole						>
EC <	ERROR_AE	IRCOMM_ILLEGAL_ROLE				>

	mov	ds:[bx].ISPD_clientRole, al

	call	CheckConnection
	jc	noError				; exit if no connection

	call	PortEmulatorSendLineSettingsFar
noError:
	clc

	.leave
	ret
IrCommSetRole	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommSetFlowControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the flow control used by a port

CALLED BY:	DR_SERIAL_SET_FLOW_CONTROL
PASS:		ax	= SerialFlowControl
		bx	= unit number
		cl	= SerialModem (signal to tell remote to stop 
			  sending)
		ch	= SerialModemStatus (signal(s) which remote
			  can de-assert to cause us to stop sending)
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommSetFlowControl	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	test	ax, not SerialFlowControl				>
EC <	ERROR_NZ	-1						>

	call	CheckConnection
	jc	noError				; exit if no connection

	mov	dl, ds:[bx].ISPD_flow		; get current setting
	test	ax, mask SFC_SOFTWARE
	jz	clearSoftware
	or	dl, mask SF_SOFTWARE
	jmp	checkHardware
clearSoftware:
	and	dl, not (mask SF_SOFTWARE or mask SF_XON or mask SF_XOFF or mask SF_SOFTSTOP)
checkHardware:
	test	ax, mask SFC_HARDWARE
	jz	clearHW
	or	dl, mask SF_HARDWARE
sendFC:
	mov	ds:[bx].ISPD_stopCtrl, cl
	mov	ds:[bx].ISPD_stopSignal, ch
	mov	ds:[bx].ISPD_flow, dl

	call	PortEmulatorSendFlowControl
noError:
	clc

	.leave
	ret
clearHW:
	and	dl, not (mask SF_HARDWARE or mask SF_HARDSTOP)
	jmp	sendFC

IrCommSetFlowControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommEnableFlowControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets which side of the port that flow control is
		enabled for:  INPUT/OUTPUT/BOTH

CALLED BY:	DR_SERIAL_ENABLE_FLOW_CONTROL
PASS:		ax	= STREAM_READ/STREAM_WRITE/STREAM_BOTH
		bx	= unit number
		ds	= dgroup (passed by IrCommStrategy)
RETURN:		carry set on error
			ax	= STREAM_NO_DEVICE / STREAM_CLOSED
		carry clear if ok
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Adjust the SF_INPUT and SF_OUTPUT bits in ISPD_flow field
	Send the current flow settings to the peer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommEnableFlowControl	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	call	CheckConnection
	jc	noError				; exit if no connection

	cmp	ax, STREAM_READ

	mov	dl, ds:[bx].ISPD_flow
	or	dl, mask SF_INPUT or mask SF_OUTPUT

CheckHack < (STREAM_WRITE and 1) eq 0 >
CheckHack < (STREAM_BOTH  and 1) eq 0 >
	test	ax, 1				; just READ?
	jz	checkInput
	;
	; Either disabled, or STREAM_READ.  Disable flow control for
	; output.
	;
	and	dl, not (mask SF_OUTPUT)
checkInput:
CheckHack < (STREAM_READ and 0x8000) eq 0x8000>
CheckHack < (STREAM_BOTH and 0x8000) eq 0x8000>
	tst	ax
	js	setIt
	and	dl, not (mask SF_INPUT)
setIt:
	mov	ds:[bx].ISPD_flow, dl

	mov	cl, ds:[bx].ISPD_stopCtrl
	mov	ch, ds:[bx].ISPD_stopSignal
	call	PortEmulatorSendFlowControl
noError:
	clc

	.leave
	ret
IrCommEnableFlowControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleCreditCounterRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keeps track of the number of bytes read and advances
		TTP credits when appropriate

CALLED BY:	IrCommRead, IrCommReadByte
PASS:		si	= unit number
		cx	= number of bytes read
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	4/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleCreditCounterRead	proc	near
	uses	ax,bx,cx,dx
	.enter

EC <	push	bx							>
EC <	mov	bx, si							>
EC <	call	ECValidateUnitNumber					>
EC <	pop	bx							>

	PSem	ds, creditSem

	add	ds:[si].ISPD_bytesDealtWith, cx
	mov	ax, ds:[si].ISPD_packetDataSizeIn

	clr	dx				; initally no credits
						; to advance
creditLoop:
	cmp	ax, ds:[si].ISPD_bytesDealtWith
	ja	advance				; not enough to fit a packet

	sub	ds:[si].ISPD_bytesDealtWith, ax

	inc	dx				; dx = # credits to advance
	jmp	creditLoop
advance:
	VSem	ds, creditSem
	tst	dx
	jz	noCredits			; no credits to advance

	mov	cx, dx				; cx = # credits to advance
	mov	bx, si				; bx = unit number
	call	IrCommAdvanceTTPCredit

noCredits:
	.leave
	ret
HandleCreditCounterRead	endp




if HANDLE_JEOPARDY_CASE
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlockWhileInJeopardy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	While the connection is in jeopardy, sleep for a while
		and check again.
CALLED BY:	INTERNAL (IrCommRead, IrCommReadByte)
PASS:		si	= unit number
		ds	= dgroup
RETURN:		carry set if connection lost
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	4/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlockWhileInJeopardy	proc	near
	uses	ax, bx
	.enter

EC <	mov	bx, si							>
EC <	call	ECValidateUnitNumber					>

waitToUnblock:
	cmp	ds:[si].ISPD_irlapStatus, ISIT_BLOCKED
	jne	notBlocked
	mov	ax, JEOPARDY_SLEEP_TIME
	call	TimerSleep			; wait til we check again
	;
	; Get the current time so we can reset the start time.  This
	; will allow us to wait for jeopardy to be detected after we
	; recover from jeopardy.
	;
	call	TimerGetCount			; bxax = current time
	movdw	ds:[rwStartTime], bxax
	jmp	waitToUnblock
notBlocked:
	cmp	ds:[si].ISPD_irlapStatus, ISIT_OK
	je	done

	stc					; connection lost
done:
	.leave
	ret
BlockWhileInJeopardy	endp
endif



if HANDLE_JEOPARDY_CASE
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllowJeopardyToBeDetected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There were not enough bytes in the stream for us to
		read.  The connection might be be on the brink of
		falling into jeopardy so we'll sleep a little while
		before trying again.  If we've waited long enough for
		the connection status to be determined then we'll just
		return an error.

CALLED BY:	INTERNAL (IrCommRead, IrCommReadByte)
PASS:		bxax	= time at which we started the read
RETURN:		carry set if we've waited long enough
DESTROYED:	nothing
SIDE EFFECTS:	

	This routine sleeps a little while before returning

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	4/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllowJeopardyToBeDetected	proc	near
	uses	ax,bx,cx,dx
	.enter

	movdw	dxcx, bxax			; dxcx = start time
	call	TimerGetCount			; bxax = current time

	subdw	bxax, dxcx			; bxax = elapsed time
	cmpdw	bxax, TIME_TO_DETECT_JEOPARDY
	jae	timeElapsed
	;
	; We haven't waited long enough for the jeopardy state to be
	; detected.  Sleep a little while and we'll check again later.
	;
	mov	ax, JEOPARDY_SLEEP_TIME
	call	TimerSleep
done:
	.leave
	ret
timeElapsed:
	stc
	jmp	done
AllowJeopardyToBeDetected	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapSerialFormatToIrCommFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes the SerialFormat, SerialMode, and SerialBaud
		settings and maps them to the appropriate IrComm
		settings.

CALLED BY:	INTERNAL (IrCommSetFormat)
PASS:		al	= SerialFormat
		ah	= SerialMode
		cx	= SerialBaud		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

	Local variables of inherited stack frame are filled in:

	dataFormat, serviceType, and dataRate

PSEUDO CODE/STRATEGY:
		
NOTES:

	I'm only worried about the service type now since the other
two settings do not affect how data is transferred.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapSerialFormatToIrCommFormat	proc	far
	uses	ax,cx,dx
	.enter inherit IrCommSetFormat

;EC <	cmp	ah, SM_RAW						>
;EC <	ERROR_E	IRCOMM_SERVICE_TYPE_NOT_SUPPORTED			>

	cmp	ah, SM_RARE
	jne	isCooked
	mov	ss:[serviceType], mask ICST_3_WIRE
	jmp	doFormat
isCooked:
	mov	ss:[serviceType], mask ICST_9_WIRE
doFormat:
	;
	; IrCommDataFormat is the same as SerialFormat with SF_BREAK
	; and SF_DLAB cleared
	;
	and	al, not (mask SF_DLAB or mask SF_BREAK)
	mov	ss:[dataFormat], al

	call	MapBaudToDataRate
	movdw	ss:[dataRate], axdx

	.leave
	ret
MapSerialFormatToIrCommFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapBaudToDataRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts from SerialBaud to numerical data rate

CALLED BY:	MapSerialFormatToIrCommFormat
PASS:		cx	= SerialBaud
RETURN:		axdx	= numerical data rate
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapBaudToDataRate	proc	near
	.enter

	clr	ax
	mov	dx, 0x240
	cmp	cx, SB_2400
	jge	done

	mov	dx, 0x960
	cmp	cx, SB_9600
	jge	done

	mov	ax, 0x1
	mov	dx, 0x9200
	cmp	cx, SB_19200
	jge	done

	mov	ax, 0x3
	mov	dx, 0x8400
	cmp	cx, SB_38400
	jge	done

	mov	ax, 0x5
	mov	dx, 0x7600
	cmp	cx, SB_57600
	jge	done

	mov	ax, 0x11
	mov	dx, 0x5200
done:
	.leave
	ret
MapBaudToDataRate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if connection exists

CALLED BY:	INTERNAL
PASS:		bx	= unit number
		ds	= dgroup
RETURN:		carry set if not connected

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/ 1/96    	Initial version
	grisco	4/26/96		Do not try to establish connection

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckConnection	proc	near
	.enter

EC <	call	ECValidateUnitNumber					>

	cmp	ds:[bx].ISPD_state, ICFS_CONN	; are we connected?
	stc
	jne	done
if 0
;
; Return an error if the connection doesn't exist.  We will not
; attempt to establish a connection, instead we will just return
; error.
;
	;
	; Our idea of a "passive" connection is one which cannot
	; initiate a connection, but may act normally if a connection
	; exists (initiated by the remote)
	;
	tst	ds:[bx].ISPD_passive
	jnz	error

	call	PortEmulatorEstablishConnection	; attempt to connect
else
	clc					; we have a connection
endif
done:
	.leave
	ret
if 0
error:
	stc					; signal an error
	jmp	done
endif
CheckConnection	endp

ResidentCode	ends
