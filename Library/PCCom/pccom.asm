COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        PCCom
FILE:		pccom.asm

AUTHOR:		Cassie Hartzog, Nov  9, 1993

ROUTINES:
	Name			Description
	----			-----------
	PCComEntry		library entry point
	PCComInit		initialize serial port connection
	PCComExit		reset serial port
	PCComAbort		abort the current file transfer operation
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	11/ 9/93	Initial revision

DESCRIPTION:

	$Id: pccom.asm,v 1.1 97/04/05 01:25:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init            segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PCComEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Do-nothing routine required b/c we're a library.

CALLED BY:      Kernel
PASS:           various and sundry
RETURN:         carry clear to indicate happiness
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        ardeb   6/17/90         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComEntry       proc    far
	ForceRef PCComEntry
	clc
        ret
PCComEntry       endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the appropriate communications port

CALLED BY:	GLOBAL

PASS: 		on stack:
			flags
			callbackOptr
			timeout
			SerialBaud
			SerialPortNum

RETURN:		al = PCComReturnType
			carry set if error

DESTROYED:	bx,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/93	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
EC <serialDriverName	wchar	"serialec.geo", 0			>
NEC <serialDriverName	wchar	"serial.geo", 0				>
EC <irCommDriverName	wchar	"ircommec.geo", 0			>
NEC <irCommDriverName	wchar	"ircomm.geo", 0				>
else
EC <serialDriverName	char	"serialec.geo", 0			>
NEC <serialDriverName	char	"serial.geo", 0				>
EC <irCommDriverName	char	"ircommec.geo", 0			>
NEC <irCommDriverName	char	"ircomm.geo", 0				>
endif
	SetGeosConvention
PCCOMINIT	proc	far	port:SerialPortNum, baud:SerialBaud, 
				timeout:word, callbackOptr:optr, flags:word
		uses	si,di,ds,es
		.enter
		LoadDGroup	es, ax
	;
	; Lock the critical section
	;
		PSem	es, initExitLock, TRASH_AX_BX
	;
	; PCCom can't serve more than one client at a time,
	; so first check that noone else is already using PCCom.
	;
		segmov	ds, es, ax
		call	CheckCaller		; Z set if same client or none
		LONG	jnz	error		; al <- PCComReturnType
	;
	; If a port is already set, don't re-initialize
	;
		mov	al, PCCRT_ALREADY_INITIALIZED
		cmp	es:[serialPort], NO_PORT
		LONG	jne	error

	;
	; Save information passed by user
	;
		mov	ax, ss:[flags]		; save notification types
		mov	es:[sysFlags], ax	;  caller wants to receive
	;
	; Verify callback optr if ouput flags passed
	;
		movdw	es:[callbackOD], 0	; no notifications will be sent
		test	ax, mask PCCIF_NOTIFY_OUTPUT or mask PCCIF_NOTIFY_EXIT
		jz	getBaud
		
		movdw	bxsi, ss:[callbackOptr]	; save optr of object that
		movdw	es:[callbackOD], bxsi	;  will receive notifications
EC <		call	ECCheckOD					>

getBaud:
		mov	cx, DEFAULT_BAUD
		cmp	ss:[baud], -1
		je	useDefaultBaud
		mov	cx, ss:[baud]
useDefaultBaud:
		mov	es:[serialBaud], cx

		mov	cx, DEFAULT_PORT
		cmp	ss:[port], -1
		je	useDefaultPort
		mov	cx, ss:[port]
useDefaultPort:
		mov	es:[serialPort], cx

	;
	; load the driver, will return error if no serial card available
	;
		mov	es:[serialDriver].high, 0	; in case of error...
		clr	es:[serialHandle]		; in case of error...
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath		; In EC, chokes on err
		segmov	ds, cs, ax
	;
	; check which type of driver
	;
		test	es:[sysFlags], mask PCCIF_IR_STREAM
		jz	useSerial
		mov	es:[defaultTimeout], DEFAULT_IR_TIMEOUT
		mov	es:[blockRetransAttempts], IR_BLOCK_RESEND_ATTEMPTS
		mov	si, offset irCommDriverName
		mov	ax, IRCOMM_PROTO_MAJOR
		mov	bx, IRCOMM_PROTO_MINOR
		jmp	loadDriver
useSerial:
		mov	es:[defaultTimeout], DEFAULT_TIMEOUT
		mov	es:[blockRetransAttempts], BLOCK_RESEND_ATTEMPTS
		mov	si, offset serialDriverName
		mov	ax, SERIAL_PROTO_MAJOR
		mov	bx, SERIAL_PROTO_MINOR
loadDriver:
		call	GeodeUseDriver
		mov	es:[serialHandle], bx		; save driver handle
		call	FilePopDir			; flags preserved
		mov	al, PCCRT_CANNOT_LOAD_SERIAL_DRIVER
		LONG	jc	nukePortAndError
	;
	; Now set the timeout time
	;
		mov	ax, es:[defaultTimeout]
		mov	es:[timeoutTime], ax
	;
	; Get the strategy routine for the serial driver.
	;
		call 	GeodeInfoDriver			;get ptr to info table
		movdw	bxdx, ds:[si]			;get the routine offset
		movdw	es:[serialDriver], bxdx		;store driver fptr
	;
	; Create the thread which will monitor the serial port.
	;
		call	InitThreads			;al <- PCComReturnType
		LONG_EC	jc	nukePortAndError
	;
	; Save client's handle now that we have successfully created
	; a thread for it.  If this is not set, PCComExit won't be
	; executed for this client, and it may be called below, if the
	; serial port cannot be opened.
	;
		call	GeodeGetProcessHandle	; bx <- process handle
		mov	es:[client], bx		; save new client handle

	;
	; Try to open the specified serial port for stream operations
	;
		BitSet 	es:[sysFlags], SF_INITIALIZING	; we're attempting to open
							;  a port
		push	bp
		mov	bp, ss:[timeout]
		mov	bx, es:[serialPort]
		mov	ax, mask SOF_TIMEOUT
		mov	cx, BUFFER_SIZE
		mov	dx, BUFFER_SIZE
		CallSer	DR_STREAM_OPEN, es		;ax <- StreamError
		pop	bp
		LONG_EC jc	destroyThread
		mov	es:[timeoutTime], DEFAULT_TIMEOUT

	;
	; Reset the internal states like echoback, ackBack, and clear the
	; initializing flag in sysFlags, indicating that we've successfully
	; opened and own the port.
	;
		BitClr 	es:[sysFlags], SF_INITIALIZING
		call	PCComResetStates		;destroy nothing
		call	SetSerialFormat

SBCS<		call	PCComCheckRemoteCodePage			>

		mov	al, PCCRT_NO_ERROR
		clc
done:
		pushf					
EC <		call	ECCheckES_dgroup				>
EC <		Assert_PCComReturnType	al				>
		VSem	es, initExitLock, TRASH_BX
		popf						
		.leave
		ret
		
nukePortAndError:
		mov	es:[serialPort], NO_PORT
error:
	;
	; An error occurred before we even modified serialPort, so
	; don't change its setting to NO_PORT now (a connection may
	; already be active), just set carry flag and return.
	;
		stc
		jmp	done

destroyThread:
	;
	; Couldn't open the stream, so want to destroy the new
	; thread. Turn off SF_NOTIFY_EXIT, as we don't need to notify
	; callbackOD that we are exiting if we couldn't even init
	; correctly. serialPort will be reset in PCComDetach.
	;
	; ax	= StreamError
	;
		BitClr 	es:[sysFlags], SF_NOTIFY_EXIT
		VSem	es, initExitLock
		push	ax			; #1 save StreamError
		call	PCCOMEXIT
		pop	bx			; #1 bx <- StreamError
	;
	; Return PCCRT_IN_USE if we get that specific error message
	; from the driver.  Otherwise, we don't really know what
	; went wrong, so return a more generic error message.
	;
		mov	al, PCCRT_CANNOT_ALLOC_STREAM ; most errors generic...
		cmp	bx, STREAM_DEVICE_IN_USE
		jne	notInUse
		mov	al, PCCRT_IN_USE	; ...but we do recognize IN_USE
notInUse:
		stc
		jmp	done
PCCOMINIT		endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComCheckRemoteCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check ini file for Remote codepage setting

CALLED BY:	PCCOMINIT
PASS:		es - dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, ds
SIDE EFFECTS:	
		remoteCodePage filled in
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	3/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
else
codepageCategory	char	"remote", 0
codepageKey		char	"codePage", 0
PCComCheckRemoteCodePage	proc	near
	.enter
EC <		call	ECCheckES_dgroup				>
	;
	; Check for a remote code page entry in the INI file
	;
		mov	ax, CODE_PAGE_US	; ax <- default code page
						; note that InitFileReadInteger
						; preserves AX if ini entry
						; is not found
		segmov	ds, cs
		mov	si, offset cs:[codepageCategory]
		mov	cx, cs
		mov	dx, offset cs:[codepageKey]
		call	InitFileReadInteger	; ax <- code page

	;
	; Save the code page in the global variable
	;
		mov	es:[remoteCodePage], ax
	.leave
	ret
PCComCheckRemoteCodePage	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitThreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a thread which will run a PCComClass object,
		which will grab serial input from the stream driver.

CALLED BY:	PCComInit

PASS:		es	- dgroup

RETURN:		carry set - error: couldn't allocate memory error or use port
			al - PCComReturyType
		carry clear - thread was created

DESTROYED:	bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/25/89	Initial version
	eric	9/90		doc update

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitThreads	proc	near
		uses	bp
		.enter
EC <		call	ECCheckES_dgroup				>

		call	GeodeGetProcessHandle		;^hbx <- process
		
		mov	bp, 400h			;use a 1k stack
	;
	; while it's true (I think) that es is our dgroup, our class
	; structures no longer live there.  Put seg of classes in cx.
	;
		push	bx, es
		mov	bx, handle PCComClassStructures
		call	MemDerefES
		mov	cx, es
		pop	bx, es

		mov	dx, offset PCComClass		;run by PCComClass
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
		mov	di, mask MF_CALL
		call	ObjMessage
		jc	error				;can't create thread
		
EC <		call	ECCheckES_dgroup				>
		mov	es:[threadHandle], ax		;save thread handle
	;
	; wait for serial thread to come fully to life (this semaphore is
	; V-ed by SerialAttach, the handler for MSG_META_ATTACH in
	; PCComClass.)
	;
		PSem	es, startSem
		mov	al, PCCRT_NO_ERROR
		clc				; ...and indicate success
exit:
EC <		Assert_PCComReturnType	al				>
		.leave
		ret
error:
		mov	al, PCCRT_CANNOT_CREATE_THREAD
		jmp 	exit
InitThreads	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the first method that this PCComClass object
		will receive. It is sent by SerialInThread when it creates
		this object and a thread to run it. We must initialize some 
		variables, and V a semaphore that the application thread 
		has been blocked on.

CALLED BY:	MSG_META_ATTACH

PASS:		nothing

RETURN:		nothing

DESTROYED:
 
PSEUDO CODE/STRATEGY:
		Just V the startSem to let the application thread continue.
		It can then shove our thread handle in the old global
		variable so it's clear we're here and ready for service.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialAttach	method	PCComClass, MSG_META_ATTACH

	LoadDGroup	es, ax
EC <	call	ECCheckES_dgroup					>

	; V a semaphore which our application thread has been blocked on.

	VSem	es, startSem
	ret
SerialAttach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComResetStates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the internal states.

CALLED BY:	PCCOMINIT
PASS:		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	2/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComResetStates	proc	near
		.enter
	;
	; The default is no echoback and no ackBack. 
	;
EC <		call	ECCheckES_dgroup				>
		clr	es:[echoBack]
		clr	es:[ackBack]
		mov	es:[delimiter], DEFAULT_DELIMITER
	;
	; setup robust mode stuff
	;
		mov	es:[negotiationStatus], PNS_UNDECIDED
		mov	es:[pccomAbortType], PCCAT_DEFAULT_ABORT
		mov	es:[lastIncomingPacketNumber], 1
		mov	es:[currentPacketNumber], 0
		mov	es:[robustInputStart], offset robustInputBuffer
		mov	es:[robustInputEnd], offset robustInputBuffer
		mov	es:[robustOutputLength], 0
		.leave
		ret
PCComResetStates	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSerialFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the serial port baud rate and mode, notification
		callbacks.

CALLED BY:	PCComInit

PASS:		es	- dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/12/93	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSerialFormat	proc	near
		uses	bp
		.enter

	;
	; Set the format of the serial line: raw mode, no parity, 8 bits
	; 
		mov	ah, SM_RAW
		mov	al, SerialFormat<0,0,SP_NONE,0,SL_8BITS>
		mov	cx, es:[serialBaud]		; set current baud rate
		mov	bx, es:[serialPort]		; set port to use 
		CallSer	DR_SERIAL_SET_FORMAT, es

	;
	; Tell the Stream driver to call PCComReadData when there 
	; are incoming characters waiting to be buffered.
	;
		mov	cx, es:[threadHandle]
		clr	dx	
		mov     ax, StreamNotifyType <1,SNE_DATA,SNM_MESSAGE>
		mov     bx, es:[serialPort]
		mov	bp, MSG_PCCOM_READ_DATA
		CallSer DR_STREAM_SET_NOTIFY, es
	;
	; Set the threshold for such notification: even if there is only
	; one byte of input data, we want to know about it.
	;
		mov     ax, STREAM_READ
		mov     cx, 1
		CallSer DR_STREAM_SET_THRESHOLD, es

		.leave
		ret
SetSerialFormat	endp

Init 	ends


Fixed	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComReadData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy data coming in on port to a buffer

CALLED BY:	StreamDriver

PASS:		cx      - number of bytes available
		
RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/93	initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComReadData 		method	PCComClass, MSG_PCCOM_READ_DATA

		LoadDGroup	es, ax
		segmov	ds, es, ax

	;
	; If in the midst of processing a command, don't read data.
	; Let the command handler read it as needed.
	;
		test	ds:[sysFlags], mask SF_SUSPEND_INPUT
		jnz	done			;skip if suspending input...

	;
	; if there was an error opening COM port: just skip to end.
	;
		cmp	ds:[serialPort], NO_PORT
		je	done			

	;
	; Suspend input until handler tells us to do otherwise.
	;
		BitSet	ds:[sysFlags], SF_SUSPEND_INPUT
		call	ConsumeOneByte

done:
		ret
PCComReadData	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlushQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes all MSG_PCCOM_READ_DATAs from the queue

CALLED BY:	ObjMessage
PASS:		ax, cx, dx, si, bp - fake event (MSG_META_NULL
		ds:bx - event in queue (structure event)
RETURN:		di - flags
			PROC_SE_EXIT
			PROC_SE_STORE_AT_BACK
			PROC_SE_CONTINUE
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlushQueue	proc	far
	.enter
	;
	; check for the target message
	;
		cmp	ds:[bx].HE_method, MSG_PCCOM_READ_DATA
		jne	continue
	;
	; change the event to a harmless method
	;
		mov	ds:[bx].HE_method, MSG_META_DUMMY
continue:
		mov	di, PROC_SE_CONTINUE
	.leave
	ret
FlushQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConsumeOneByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data has just been read from serial port. 
		Consume one byte and let the parser handle it.

CALLED BY:	PCComReadData
PASS:		ds	- dgroup
		es	- dgroup
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		if timed-out && PNS_ROBUST
			pccomAbortType <- PCCAT_CONNECTION_LOST

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConsumeOneByte	proc	near
		.enter
parseLoop:
	;
	; Get the next waiting byte, if any.
	; We first have to check that the connection is still open, 
	; for it may have been closed remotely (ScrExit)
	;

		cmp	es:[negotiationStatus], PNS_ROBUST
		je	isRobust

		mov	bx, ds:[serialPort]
		mov	ax, STREAM_NOBLOCK		
		CallSer	DR_STREAM_READ_BYTE, ds

comWasRead:
;
; DR_STREAM_READ_BYTE is not documented to return StreamError in ax.
; Please, refer to your corresponding .def file.  4/19/96 - ptrinh
;		jc	noByte		; ax <- StreamError

		jc	noByte
		call	ParseInput

		test	ds:[sysFlags], mask SF_EXIT
		jnz	abort		; user wants to abort this operation

		jmp	parseLoop
isRobust:
		call	RobustComReadFar
		jnc	comWasRead
	;
	; had an error - but don't want a dead connection because of
	; "phantom" byte notifications from serial..
	;
		mov	ds:[negotiationStatus], PNS_ROBUST
		jmp	noByte

abort:
	;
	; Flush the queue and Reset sysFlags for next operation
	;
		call	ComDrainQueue
		andnf	ds:[sysFlags], RESET_SYSFLAGS_MASK
		clr	ds:[err]
exit:
		.leave
		ret

noByte:
	;
	; Nothing waiting, so reset SUSPEND flag and return.
	; When more data arrives, the serial driver will call
	; PCComRead, which will in turn call this routine, resuming
	; the parse loop.
	;
		BitClr	ds:[sysFlags], SF_SUSPEND_INPUT
;
; Not part of API, thus can't use it.  .def documentation of
; DR_STREAM_READ_BYTE doesn't match those of StreamReadByte.
; 4/19/96 - ptrinh
;		cmp	ax, STREAM_CLOSING
;		jne	exit
	;
	; Reset error flags
	;
		BitClr	ds:[sysFlags], SF_EXIT
		clr	ds:[err]
		jmp	exit

ConsumeOneByte	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	V's our semaphore, then calls ThreadDestroy.

CALLED BY:	MSG_META_DETACH
PASS:		cx	= ack ID
		dx:bp	= ack OD
		ax	= message #

RETURN:		never
DESTROYED:	nothing
SIDE EFFECTS:	detroys the thread

PSEUDO CODE/STRATEGY:
		the thread is destroyed here, rather than calling the
 			superclass, as we don't actually have a bound
			event queue, but ProcessClass does a force-queue
			using the thread handle, which wouldn't work

		this routine *must* be in fixed memory, as the stack will
			not unwind following the call to ThreadDestroy (the
			stack gets biffed), which would leave this resource 
			locked if it were movable.

	* Header was copied from PCMTDetach. *

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	11/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCCDetach	method dynamic PCComClass, 
					MSG_META_DETACH
	;
	; Test to see if we need to V destroySem. No, if called from ScrExit.
	;
		mov	bx, handle dgroup
		call	MemDerefES

		test	es:[sysFlags], mask SF_SCREXIT
		jnz	suicide

		VSem	es, destroySem, TRASH_AX_BX	
suicide:
		jmp	ThreadDestroy

PCCDetach	endm

Fixed	ends


Main	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMEXIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the stream, free the Serial Library, 
		shutdown the thread.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		al	= PCComReturnType
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMEXIT	proc	far
		ForceRef PCCOMEXIT
		uses	di,ds,es,bx
		.enter

	;
	; Lock the critical section
	;
		LoadDGroup	ds, ax
		PSem	ds, initExitLock, TRASH_AX
	;
	; Make sure that the caller is the same as the app who
	; initialized PCCom.
	;
		call	CheckCaller		; carry set if different
		stc	
		jnz	done			; al <- PCComReturnType
	;
	; Abort the current operation, if any.
	;
		call	PCCOMABORT
	;
	; If no thread handle, the serial driver was not loaded,
	; because the thread is created first.
	;
		mov	bx, ds:[threadHandle]
		tst	bx
		jz	threadDestroyed
	;
	; Tell the thread to die, via the queue 
	;
		mov	ax, MSG_PCCOM_DETACH
		mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
		call	ObjMessage
EC <		call	ECCheckDS_dgroup				>

	;
	; Wait until the thread is finished BUT don't wait if called
	; from ScrExit. 
	;
		test	ds:[sysFlags], mask SF_SCREXIT
		jnz	threadDestroyed
		PSem	ds, destroySem, TRASH_AX_BX
	
threadDestroyed:
		mov	ax, PCCRT_NO_ERROR
		clc				; indicate success
	
done:
		pushf
EC <		call	ECCheckDS_dgroup				>
EC <		Assert_PCComReturnType	al				>
		VSem	ds, initExitLock 
		popf						
		.leave
		ret

PCCOMEXIT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMABORT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort the current operation and flush the output queue.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

		pccomAbortType <= PCCAT_EXTERNAL_ABORT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCCOMABORT		proc	far
		uses	ax, bx, ds
		ForceRef	PCCOMABORT
		.enter

		LoadDGroup	ds, ax
	;
	; Make sure that the caller is the same as the app who
	; initialized PCCom.
	;
		call	CheckCaller		; zero set if the same
		jnz	done			; al <- PCComReturnType
	;
	; Set the SF_EXIT flag so that the serial thread will know it
	; should abort the current operation when it has the opportunity
	;
		BitSet	ds:[sysFlags], SF_EXIT

		mov	ah, PCCAT_EXTERNAL_ABORT
		call	PCComPushAbortType
	;
	; DONT flush the stream now though, because you really want
	; the currently active code to find the right spot in the
	; stream to send a NAK_QUIT indicator..  else the remote has
	; to timeout three times to discover we've quit!
	;

done:
		.leave
		ret
PCCOMABORT	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kill the PCCom thread.

CALLED BY:	MSG_PCCOM_DETACH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDetach		method dynamic PCComClass,
				MSG_PCCOM_DETACH

		LoadDGroup	ds, ax
	;
	; See if this message has already been handled.
	;
		tst	ds:[serialHandle]
		LONG_EC jz	done
	;
	; If there is a connection, notify client we are exiting
	;
		segmov	es, ds, ax
		call	NotifyClientOfExit

		mov	bx, NO_PORT
		xchg	bx, ds:[serialPort]
	;
	; Close the stream if we own it, discarding any data in output Queue
	;
		test	ds:[sysFlags], mask SF_INITIALIZING
		jnz	freeLibrary		; jump if not our port
		mov	ax, STREAM_DISCARD	
		CallSer	DR_STREAM_CLOSE, ds

freeLibrary:
		clr	bx
		xchg	bx, ds:[serialHandle]
		call	GeodeFreeLibrary
	;
	; Send exit notification if one is desired
	;
		test 	es:[sysFlags], mask SF_NOTIFY_EXIT
		jz	noNotify
		mov	bp, es:[threadHandle]	; pass the thread handle
		mov	dx, GWNT_PCCOM_EXIT
		mov	ax, MSG_META_NOTIFY
		call	SendNotification
noNotify:
	;
	; There is no need to send MSG_META_ACK to the callback 
	; object. The application's process can intercept
	; MSG_PROCESS_NOTIFY_THREAD_EXIT if it needs to know when the
	; thread has been destroyed.
	;						- cassie 2/16/95
	;
		LoadDGroup	es, ax
		clr	ax
		mov	es:[client], ax
		xchg	es:[threadHandle], ax	; ax - process thread
		mov_tr	bx, ax			; bx - process thread
		clr	si			; sending to thread
		clr	dx, bp, cx		; no ID, nor ack OD
		mov	ax, MSG_META_DETACH
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		ret
PCComDetach		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyClientOfExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send <ESC>EX to client

CALLED BY:	PCComExit
PASS:		ds - pccom dgroup
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/14/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyClientOfExit		proc	near
		uses	bx
		.enter

EC <		call	ECCheckDS_dgroup				>

	;
	; If we're being called by ScrExit, ie. the other side sent us
	; an EX command, then skip notification.
	;
		test	ds:[sysFlags], mask SF_SCREXIT
		LONG_EC jnz	done
	;
	; If we failed to open the serial port, leave without writing anything
	; to it.
	;
		test	ds:[sysFlags], mask SF_INITIALIZING
		LONG_EC jnz	done

		cmp	ds:[serialPort], NO_PORT
		je	done
	;
	; Wait a little bit for the client to get the abort notification
	; before sending the exit command, so that it knows the next 3
	; bytes are not part of any data.
	;
		mov	ax, 30			; 60 ticks = 1 second
		call	TimerSleep		
	;
	; Since EX is a client command, we need to re-negotiate
	; as expected by the Robust protocol.
	;
		cmp	ds:[negotiationStatus], PNS_ROBUST
		jne	writeEX
		call	ActiveStartupChecks
		jc	done
	;
	; write the exit command to the serial port.  If The first
	; char doesn't get acknowledged when it should the SF_EXIT
	; flag will be set..  don't bother with the other chars.
	;	
	;
	; To be more efficient, we'll package the 3 writes into a
	; packet so we don't need to send 3 seperate single-byte
	; packets.  4/19/96 - ptrinh
	;
writeEX:
		call	RobustCollectOn
		mov	al, 0x1b
		call	ComWrite
		mov	al, 'E'
		call	ComWrite
		mov	al, 'X'
		call	ComWrite
		call	RobustCollectOff
	;
	; Wait again for chars to get there before proceeding, as it seems
	; if the port is closed too quickly, the chars don't get there
	; correctly.
	;
		mov	ax, 30			; 60 ticks = 1 second
		call	TimerSleep		
	;
	; Now flush the write stream to make sure it gets there.
	;
		mov	bx, ds:[serialPort]
		mov	ax, STREAM_WRITE
		CallSer	DR_STREAM_FLUSH, ds
	;
	; If in Robust-Mode, do cleanup.
	;
		cmp	ds:[negotiationStatus], PNS_ROBUST
		jne	done
		call	ActiveShutdownDuties

done:
		.leave
		ret
NotifyClientOfExit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCaller
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether current client is different from
		calling geode.

CALLED BY:	PCCOMINIT, PCCOMEXIT, PCCOMABORT
PASS:		ds - dgroup

RETURN:		Z flag set if same client, or no client
		Z flag clear if different client
			al - PCCRT_IN_USE

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/14/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckCaller		proc	far
		uses	bx
		.enter

EC <		call	ECCheckDS_dgroup				>

	; first check if there is a client
		
		tst	ds:[client]
		jz	done

	; get the application's process handle
		
		call	GeodeGetProcessHandle	; bx <- handle
		mov	al, PCCRT_IN_USE
		cmp	bx, ds:[client]		; Z flag clear if different
		
done:		
		.leave
		ret
CheckCaller		endp

Main	ends


