COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		Modem Driver
FILE:		modemAdmin.asm

AUTHOR:		Jennifer Wu, Mar 14, 1995

ROUTINES:
	Name			Description
	----			-----------
ModemFunctions:
	ModemDoNothing
	ModemInit
	ModemExit
	ModemTestDevice
	ModemSetDevice
	ModemOpen
	ModemClose
	ModemSetNotify

Methods:
	ModemResponseTimeout

Subroutines:
	ModemCreateThread
	ModemDestroyThread

	ModemStartResponseTimer
	ModemStopResponseTimer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/14/95		Initial revision

DESCRIPTION:
	Routines for administrative tasks in the modem driver.

	$Id: modemAdmin.asm,v 1.1 97/04/18 11:47:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource

;---------------------------------------------------------------------------
;			ModemFunctions
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Twiddle our thumbs.

CALLED BY:	ModemStrategy

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Clear the carry

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/14/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoNothing	proc	far
		clc
		ret
ModemDoNothing	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the modem.

CALLED BY:	ModemStrategy

PASS:		cx	= di passed to GeodeLoad.  Garbage if loaded via
			  GeodeUseDriver
		dx	= bp passed to GeodeLoad.  Garbage if loaded via
			  GeodeUseDriver
		es	= dgroup

RETURN:		carry clear if initialization successful

DESTROYED:	ax (cx, dx, bp, di, si, ds, es  - allowed)

PSEUDO CODE/STRATEGY:
		Allocate response semaphore 
		Make modem driver own semaphore

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/14/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemInit	proc	far
		uses	bx
		.enter
	;
	; Allocate blocking semaphore owned by modem driver.
	;
		clr	bx
		call	ThreadAllocSem				 
		mov	es:[responseSem], bx
		
		mov	ax, handle 0
		call	HandleModifyOwner
	;
	; And a regular semaphore for synchronizing client access.
	;
		mov	bx, 1
		call	ThreadAllocSem
		mov	es:[clientSem], bx

		mov	ax, handle 0
		call	HandleModifyOwner

		mov	bx, 1
		call	ThreadAllocSem
		mov	es:[abortSem], bx
		mov	ax, handle 0
		call	HandleModifyOwner

		clc

		.leave
		ret
ModemInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit driver

CALLED BY:	ModemStrategy

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx, di (cx, dx, si, ds, es - allowed)

PSEUDO CODE/STRATEGY:
		If response timer exists, stop it
		Free semaphores

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/14/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemExit	proc	far

		call	ModemStopResponseTimer

		clr	bx
		xchg	bx, es:[responseSem]
		call	ThreadFreeSem

		clr	bx
		xchg	bx, es:[clientSem]
		call	ThreadFreeSem

		clr	bx
		xchg	bx, es:[abortSem]
		call	ThreadFreeSem

		ret
ModemExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test the existence of a particular device that the 
		driver supports

CALLED BY:	ModemStrategy

PASS:		dx:si	= pointer to null-terminated device name string

RETURN:		ax	= DevicePresent

DESTROYED:	di, es (preserved by ModemStrategy)

PSEUDO CODE/STRATEGY:
		See if the device name maps to a modem supported by 
		the driver.  If not, ax is already set to 
		DP_INVALID_DEVICE, otherwise, unlock the info resource 
		and return DP_CANT_TELL	because at this point, the driver
		has no idea which port the modem is connected to.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/15/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemTestDevice	proc	far
		uses	bx
		.enter

		EnumerateDevice	ModemExtendedInfo
		jc	exit

		call	MemUnlock
		mov	ax, DP_CANT_TELL
exit:
		.leave
		ret
ModemTestDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set which device the driver is to support.

CALLED BY:	ModemStrategy

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
		At this point, all devices behave the same so we
		don't care which device is being supported.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/15/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemSetDevice	proc	far
		clc
		ret
ModemSetDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the port for modem communications.  Only allow 
		this operation if modem driver does not have another 
		client. 

CALLED BY:	ModemStrategy 

PASS:		ax	= StreamOpenFlags
		bx	= port number
		cx	= input buffer size
		dx	= output buffer size
		bp	= timeout value if SOF_TIMEOUT
		si	= handle of serial driver to use
		es	= dgroup

RETURN:		carry set if port couldn't be opened or if modem driver
			already has a client

DESTROYED:	di (preserved by ModemStrategy)

PSEUDO CODE/STRATEGY:
		if already have a client, return carry set
		get serial strategy routine
		Open serial port, owned by modem driver
		if successful { 
			create modem thread 
 			register for data notifications 
			Set flag indicating have a client
			Set parser for no connection state
			EC <store port number>
		}
		else unload serial driver

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/29/95			Initial version
	jwu	10/5/95			Restrict access using clientSem

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemOpen	proc	far
		uses	ax, bx, cx, bp, si, ds
		.enter
	;
	; If already have a client, do not process this one.
	;
EC <		CheckPortNum	bx				>
		push	ax, bx
		mov	bx, es:[clientSem]
		call	ThreadPSem
		pop	ax, bx

		test	es:[modemStatus], mask MS_HAVE_CLIENT
		jnz	error
	;
	; Get serial driver's entry point, then open the serial port.
	;
		push	bx
		mov	bx, si
		call	GeodeInfoDriver
		movdw	es:[serialStrategy], ds:[si].DIS_strategy, bx
		pop	bx

		mov	si, handle 0			
		mov	di, DR_SERIAL_OPEN_FOR_DRIVER
		call	es:[serialStrategy]
		jc	exit
	;
	; Create the modem thread and register for data notification.
	; If either fails, close port and unload serial.  If successful
	; set flag indicating client exists and set parse routine.
	;
		call	ModemCreateThread
		jc	cleanup
	;
	; Save port number BEFORE setting up notification, in case there
	; is data arriving on the port so the msg handler will use the
	; correct port number! -SJ
	;
EC <		CheckPortNum	bx					>
		mov	es:[portNum], bx

		call	ModemGrabSerialPort
	;
	; We have a client, but do not assume the modem is in command
	; mode.  Hope the client will first do a reset, which will send
	; the escape sequence. -dhunter 5/31/2000
	;
		ornf	es:[modemStatus], mask MS_HAVE_CLIENT
		ornf	es:[miscStatus], mask MSS_MODE_UNCERTAIN
		mov	es:[parser], offset ModemParseNoConnection
		jmp	exit			    ; carry clear from BitSet
cleanup:
		mov	ax, STREAM_DISCARD
		mov	di, DR_STREAM_CLOSE
		call	es:[serialStrategy]
error:
		stc
exit:
		mov	bx, es:[clientSem]
		call	ThreadVSem

		.leave
		ret
ModemOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemGrabSerialPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the serial port to notify us when data received

CALLED BY:	INTERNAL ModemOpen, DR_MODEM_GRAB_SERIAL_PORT
PASS:		bx	= port number
		es	= dgroup
RETURN:		carry set if notification registration failed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemGrabSerialPort	proc	far
	uses	ax,cx,bp,di
	.enter
	;
	; Send serial data to us.
	;
		mov	ax, StreamNotifyType <1, SNE_DATA, SNM_MESSAGE>
		mov	cx, es:[modemThread]
		mov	bp, MSG_MODEM_RECEIVE_DATA
		mov	di, DR_STREAM_SET_NOTIFY
		call	es:[serialStrategy]
EC <		ERROR_C MODEM_SET_NOTIFY_FAILED				>
		pushf
	;
	; In case someone else was using the serial port before us,
	; clear out error notifications, as we won't use it.
	;
		mov	ax, StreamNotifyType <1, SNE_ERROR, SNM_NONE>
		mov	di, DR_STREAM_SET_NOTIFY
		call	es:[serialStrategy]
EC <		WARNING_C MODEM_SET_NOTIFY_FAILED_WHO_CARES		>

	;
	; Catch modem signals in case someone is interested.
	;
		mov	ax, StreamNotifyType <1, SNE_MODEM, SNM_MESSAGE>
		mov	cx, es:[modemThread]
		mov	bp, MSG_MODEM_MODEM_LINE_CHANGE
		mov	di, DR_STREAM_SET_NOTIFY
		call	es:[serialStrategy]
EC <		WARNING_C MODEM_SET_NOTIFY_FOR_MODEM_SIGNALS_FAILED	>

		popf
	.leave
	ret
ModemGrabSerialPort	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the serial port being used for the modem connection
		and note that there is no longer a client.

CALLED BY:	ModemStrategy

PASS:		ax	= STREAM_LINGER or STREAM_DISCARD
		bx	= port number
		es	= dgroup

RETURN:		nothing

DESTROYED:	di (preserved by ModemStrategy)

PSEUDO CODE/STRATEGY:
		Close the serial port
		Reset modem status
		Reset response buffers and sizes
		Clear notifications
		EC <clear the port number>
		destroy modem driver's thread

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/29/95			Initial version
	jwu	10/5/95			Restrict access using clientSem

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemClose	proc	far

		uses	ax, bx
		.enter

ifdef HANGUP_LOG
	; Log the last reason for disconnect before we go bye-bye.
	;
		call	ModemDialStatus
endif

		push	ax, bx
		mov	bx, es:[clientSem]
		call	ThreadPSem
		pop	ax, bx

EC <		call	ECCheckClientStatus				>

		mov	di, DR_STREAM_CLOSE
		call	es:[serialStrategy]

		clr	ax
		mov	es:[parser], ax
		mov	es:[dataNotify].SN_type, al
		mov	es:[respNotify].SN_type, al
		mov	es:[signalNotify].SN_type, al
		mov	es:[result], ax
		mov	es:[responseSize], ax
		mov	es:[modemStatus], al
		mov	es:[miscStatus], al

		mov	es:[portNum], -1				

		call	ModemDestroyThread

		mov	bx, es:[clientSem]
		call	ThreadVSem

		.leave
		ret
ModemClose	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemSetNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers a notifier for incoming data.

CALLED BY:	ModemStrategy

PASS:		ax	= StreamNotifyType (only SNT_READER supported)
		bx	= port number 
		cx:dx	= address of handling routine, if SNM_ROUTINE;
			  destination of output if SNM_MESSAGE
		bp	= AX to pass if SNM_ROUTINE (except for SNE_DATA
			  with threshold of 1, in which case this value 
			  is passed in CX); method to send if SNM_MESSAGE
		es	= dgroup

RETURN:		nothing

DESTROYED:	di (preserved by ModemStrategy)

PSEUDO CODE/STRATEGY:
		EC: Die if current thread is modem driver's thread.
		EC: Die if StreamNotifyType is not SNT_READER

		If already have a client, return MRC_DRIVER_IN_USE

		EC: Die, if StreamNotifyEvent is not SNE_DATA or SNE_RESPONSE
		Figure out which StreamNotifyEvent is desired and 
			store information in appropriate notifier,
			adjusting port number

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/15/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemSetNotify	proc	far
		uses	ax, si
		.enter

EC <		call	ECCheckCallerThread			>
EC <		call	ECCheckClientStatus			>
EC <		test	ax, mask SNT_READER			>
EC <		ERROR_Z MODEM_CAN_ONLY_NOTIFY_READER		>

	;
	; Store notification information in appropriate data structure.
	; Both routine and method notifications have cx:dx in 
	; the same place, so just store them as if it's routine
	; notifications.
	;
		mov	si, ax
		andnf	si, mask SNT_EVENT
		shr	si
		shr	si			; si = StreamNotifyEvent
		mov	di, offset dataNotify
		cmp	si, SNE_DATA
		je	storeInfo

		mov	di, offset signalNotify
		cmp	si, SNE_MODEM_SIGNAL
		je	storeInfo

EC <		cmp	si, SNE_RESPONSE			>
EC <		ERROR_NE UNSUPPORTED_STREAM_NOTIFY_EVENT	>

		mov	di, offset respNotify
storeInfo:
		andnf	al, mask SNT_HOW
EC <		cmp	al, StreamNotifyMode			>
EC <		ERROR_AE MODEM_SET_NOTIFY_BAD_FLAGS		>

		mov	es:[di].SN_type, al
		mov	es:[di].SN_data, bp
		mov	es:[di].SN_dest.SND_routine.low, dx
		mov	es:[di].SN_dest.SND_routine.high, cx

		.leave
		ret
ModemSetNotify	endp

;---------------------------------------------------------------------------
;		Methods
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemResponseTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the response timer event.

CALLED BY:	MSG_MODEM_RESPONSE_TIMEOUT
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		If there is a client blocked {
		  Clear the flag
		  Set the result to MRC_TIMEOUT for client to check
			upon waking up, unless there is already another
			response
		  Clear response timer and id fields
		  V the semaphore
		}
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemResponseTimeout	method dynamic ModemProcessClass, 
					MSG_MODEM_RESPONSE_TIMEOUT

		mov	bx, handle dgroup
		call	MemDerefES

	;
	; If this was a timeout to an escape (+++) attempt, check if
	; we want to resend it.  Escape handling added 8/23/99, JimG.
	;
		tst	es:[escapeAttempts]
		jz	doneEscaping
		dec	es:[escapeAttempts]
	;
	; If this is the last resend attempt AND there is a follow-up
	; command, send that command rather then the "+++" stream since
	; we might be in command node and not realize it.  (We don't
	; get a CR after "+++" so we never get a full response to parse.)
	;
		tst	es:[escapeSecondCmd]
		jz	sendEscape
		tst	es:[escapeAttempts]
		jnz	sendEscape
		call	ModemSendEscapeSecondCmd
		jmp	done
sendEscape:
	;
	; Otherwise, resend the escape sequence.  We need to set the
	; modemStatus so that it is NOT in command mode or else
	; ModemSwitchToCommandMode will not send the sequence.
	;
		mov	bx, es:[portNum]
		BitClr	es:[modemStatus], MS_COMMAND_MODE
		call	ModemSwitchToCommandMode
		mov	cx, ESCAPE_RESPONSE_TIMEOUT
		call	ModemStartResponseTimer
		jmp	done
doneEscaping:

ifdef HANGUP_LOG
	; Close the log file if we were using it.
	;
		cmp	es:[parser], offset ModemParseDialStatusResponse
		jne	fileClosed
		mov	ax, es:[logFile]
		call	FileClose
fileClosed:
endif
		test	es:[modemStatus], mask MS_CLIENT_BLOCKED
		je	done

		BitClr	es:[modemStatus], MS_CLIENT_BLOCKED
	;
	; If there is a better result, use it.  Otherwise, the result
	; is timeout.
	;
		tst	es:[result]
		jne	clearTimer

		mov	es:[result], MRC_TIMEOUT
clearTimer:
		clr	bx
		mov	es:[responseTimer], bx
		mov	es:[responseTimerID], bx

		mov	bx, es:[responseSem]
		call	ThreadVSem
done:
		ret
ModemResponseTimeout	endm

;---------------------------------------------------------------------------
;		Subroutines
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemCreateThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a thread for the modem driver.

CALLED BY:	ModemOpen

PASS:		es	= dgroup

RETURN:		carry set if unsuccessful

DESTROYED:	di (preserved by ModemOpen)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/15/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemCreateThread	proc	near
		uses	ax, bx, cx, dx, bp, si
		.enter
	;
	; Use input process thread as parent instead of the client's
	; thread to avoid deadlock in the case that the client is 
	; calling us on its process thread.
	;
		call	ImInfoInputProcess	
		mov	si, handle 0		
		clr	bp			
		mov	cx, segment ModemProcessClass
		mov	dx, offset ModemProcessClass
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER
		mov	di, mask MF_CALL
		call	ObjMessage			
EC <		WARNING_C MODEM_DRIVER_UNABLE_TO_CREATE_THREAD		>
		jc	exit
    ;
    ; Increase the thread's base priority.
    ;
        xchg ax, bx
        mov ah, mask TMF_BASE_PRIO
        mov al, PRIORITY_HIGH
        call ThreadModify

		mov	es:[modemThread], bx
exit:
		.leave
		ret
ModemCreateThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDestroyThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the modem driver's thread.

CALLED BY:	ModemClose

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	di (allowed by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/15/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDestroyThread	proc	near
		uses	bx
		.enter

		clr	bx
		xchg	bx, es:[modemThread]
		tst	bx
		je	exit

		push	ax, cx, dx, bp
		clr	cx, dx, bp			; no ack needed
		mov	ax, MSG_META_DETACH
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	ax, cx, dx, bp
exit:
		.leave
		ret
ModemDestroyThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemStartResponseTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the response timer.

CALLED BY:	ModemDoDial
		ModemDoAnswerCall
		ModemDoHangup
		ModemDoReset
		ModemDoInitModem
		ModemDoAutoAnswer

PASS:		es	= dgroup		
		cx	= timer interval

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemStartResponseTimer	proc	near
		uses	ax, bx, cx, dx
		.enter
	;
	; Start the one shot response timer and store its handle 
	; and ID.  This is called from modem driver's thread so 
	; timer is already owned by modem driver.
	;
		mov	bx, ss:[TPD_threadHandle]
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	dx, MSG_MODEM_RESPONSE_TIMEOUT
		call	TimerStart
		
		mov	es:[responseTimer], bx
		mov	es:[responseTimerID], ax

		.leave
		ret
ModemStartResponseTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemStopResponseTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the response timer.

CALLED BY:	ModemExit

PASS:		es	= dgroup		

RETURN:		nothing

DESTROYED:	ax, bx (allowed by ModemExit)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemStopResponseTimer	proc	near

		clr	bx
		xchg	bx, es:[responseTimer]
		tst	bx
		je	exit

		mov	ax, es:[responseTimerID]
		call	TimerStop
exit:
		ret
ModemStopResponseTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemModemLineChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification from serial driver when serial hardware signals
		change.  Used to provide client with ring and DCD
		notifications.

CALLED BY:	MSG_MODEM_MODEM_LINE_CHANGE

PASS:		ds	= dgroup
		es 	= segment of ModemProcessClass
		ax	= message #
		cx	= SerialModemStatus
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/02/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHack <(mask SMS_DCD) eq (mask MLS_DCD)>
CheckHack <(mask SMS_RING) eq (mask MLS_RING)>
CheckHack <(mask SMS_DCD_CHANGED) eq (mask MLS_DCD_CHANGED)>
CheckHack <(mask SMS_RING_CHANGED) eq (mask MLS_RING_CHANGED)>

ModemModemLineChange	method dynamic ModemProcessClass, 
					MSG_MODEM_MODEM_LINE_CHANGE

	; Does anyone care??
	;
		mov	al, ds:[signalNotify].SN_type
		cmp	al, SNM_NONE
		je	done

	; We only forward carrier detect and ring indicator.
	;
		test	cx, mask SMS_DCD_CHANGED or mask SMS_RING_CHANGED
		jz	done

	; Take out the bits we are going to forward on.  Since
	; the bit fields for SMS and MLS are the same (checked above)
	; we can just do this simple AND.
	;
		andnf	cx, mask SMS_DCD or mask SMS_RING or \
				mask SMS_DCD_CHANGED or \
				mask SMS_RING_CHANGED

	; Send notification by routine or message call, whatever the
	; client wants.  (Stolen from ModemDataNotify.)
	;
CheckHack <SNM_ROUTINE lt SNM_MESSAGE>
		cmp	al, SNM_ROUTINE

		mov	ax, ds:[signalNotify].SN_data
		ja	notifyMethod
		pushdw	ds:[signalNotify].SN_dest.SND_routine
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jmp	done

notifyMethod:
		mov	bx, ds:[signalNotify].SN_dest.SND_message.handle
		mov	si, ds:[signalNotify].SN_dest.SND_message.chunk
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		ret
ModemModemLineChange	endm


CommonCode	ends



