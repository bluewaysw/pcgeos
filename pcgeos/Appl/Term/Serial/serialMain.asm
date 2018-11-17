COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	GeoComm
MODULE:		Serial
FILE:		serialMain.asm

AUTHOR:		Dennis Chow, September 6, 1989

ROUTINES:
	Name			Description
	----			-----------
	InitComUse		Set up use of serial driver 
	OpenComPort		Open the selected port and
	CloseComPort		Close the selected port and
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      9/6/89		Initial revision.
	eric	9/90		documentation update

DESCRIPTION:
	Initialization of buffers/vars for protocol use.  
	Start of communication with system.

	$Id: serialMain.asm,v 1.1 97/04/04 16:55:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitComUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up variables for using the Serial Driver routines.

CALLED BY:	InitTerm (Main/mainLocal.asm)

PASS:		ds:[serialPort]	- set to a usuable com port

RETURN:		serialDriver - serial dr. strategy routine
		carry set if error starting serial thread

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/25/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitComUse	proc	far

EC <	call	ECCheckDS_dgroup					>

	mov	ds:[serialBaud], SB_1200
	mov	ds:[serialFormat], SerialFormat <0,0,SP_NONE,0,SL_8BITS>
						; serial driver default to
						; software flow contrl
RSP <	mov	ds:[serialFlowCtrl], mask SFC_HARDWARE			>
NRSP <	mov	ds:[serialFlowCtrl], mask SFC_SOFTWARE			>
						;set default data format
	mov	ds:[serialDriver].high, 0	; in case of error
	mov	bx, ds:[serialHandle]		;get driver handle
	tst	bx
	stc					; assume error
	jz	noSerial
	mov	ax, ds				;save our seg register
	call 	GeodeInfoDriver			;get ptr to info table
	mov	bx, ds:[si]			;get the routine offset
	mov	dx, ds:[si+2]			;get routine segment
	mov	ds, ax				;restore ds
	mov	word ptr ds:serialDriver, bx	;store driver offset 
	mov	word ptr ds:serialDriver+2, dx	;store driver segment
	call	InitThreads			;create input thread 
						; (returns carry = status)
noSerial:
	ret
InitComUse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenComPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the com port and set buffer sizes, etc 

CALLED BY:	OpenPort (Main/mainLocal.asm)

PASS:		ds:[serialPort]	- set to a usuable com port
		es:dgroup

RETURN:		C		- set if error opening port
		ax		- StreamError if error

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
	There is a subset of operations that go on in here, which we
	want to have happen when we are acting as a login server.
	So we do things conditionally on login server mode.  This
	makes for ugly code.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/25/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenComPort	proc	far
	uses	di
	.enter

EC <	call	ECCheckDS_dgroup					>

	mov	bx, ds:[serialPort]		; set port to use

if	_LOGIN_SERVER
	PSem	ds, loginSem
	cmp	ds:[loginPhase], LP_ACTIVE
	je	noError
endif ; _LOGIN_SERVER

	mov	ax, mask SOF_NOBLOCK		; don't block if can't open port
	
	mov	cx, SERIAL_IN_SIZE		; size of serial input buffer
	mov	dx, SERIAL_OUT_SIZE		; size of serial output buffer
	CallSer DR_STREAM_OPEN			; open the port - carry updated
	jnc	noError

	;error opening COM port: reset our [serialPort] variable, so that
	;we don't attempt to send characters to that port

	mov	ds:[serialPort], NO_PORT	;preserve CF
	jmp	short exit			;skip to end (CF=1)...

noError:

if	_LOGIN_SERVER
	cmp	ds:[loginPhase], LP_ACTIVE
	je	afterSetFormat

endif ; _LOGIN_SERVER
if	_MODEM_STATUS
	;
	; Kill any existing connection first to prevent any unexpected data
	; coming in from the com port.
	;
	test	ds:[statusFlags], mask TSF_DONT_DROP_CARRIER
	jnz	afterDrop
	call	SerialDropCarrier
afterDrop:
endif	; _MODEM_STATUS
	call	SetSerialFormat			;set port to word length 8
						;	and in raw mode
afterSetFormat::
;	mov	cx, ds:[termProcHandle]		;send event when get stream err
;	mov	bp, MSG_SERIAL_ERROR		;method # in bp
	mov	cx, segment Fixed
	mov	dx, offset Fixed:SerialErrorRoutine
	mov	bx, ds:[serialPort]		;set  port #

if	_MODEM_STATUS
if	_LOGIN_SERVER
	cmp	ds:[loginPhase], LP_ACTIVE
	je	afterFlush
endif ; _LOGIN_SERVER
	mov	ax, STREAM_READ
	CallSer	DR_STREAM_FLUSH			; Get rid of input resulting
						; from dropping carrier,
						; so that we don't try
						; to read/parse it later
						; in the connection.
afterFlush::
endif	; _MODEM_STATUS

;	mov	ax, StreamNotifyType <1,SNE_ERROR,SNM_MESSAGE>
	mov	ax, StreamNotifyType <1,SNE_ERROR,SNM_ROUTINE>
	mov	bp, ds				; pass dgroup segment to err
						;	routine
	CallSer	DR_STREAM_SET_NOTIFY		;

;don't send modem status method as we don't use this and it could
;fill up the handle table - brianc 9/14/90
;	mov	cx, ds:[termProcHandle]		;if serial status changes
;	mov	bp, MSG_MODEM_STATUS		;  send a method 
;	mov	bx, ds:[serialPort]		;set  port #
;	mov	ax, StreamNotifyType <1,SNE_MODEM,SNM_MESSAGE>
;	CallSer	DR_STREAM_SET_NOTIFY		;
	mov     ds:[serialState], SERIAL_ACTIVE ;set serial state flag

	call	ConnectPortToThread
if	_VSER
if	_LOGIN_SERVER
	cmp	ds:[loginPhase], LP_ACTIVE
	je	afterECI
endif ; _LOGIN_SERVER
	call	TermRegisterECI			; carry set if error
afterECI::
endif ; _VSER

	clc					; indicate success
exit:

if	_LOGIN_SERVER
	VSem	ds, loginSem
endif ; _LOGIN_SERVER

	.leave
	ret
OpenComPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseComPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the com port

CALLED BY:	TermCloseAppl (Main/mainMain.asm)
		TermSetPort (Main/mainMain.asm)

PASS:		ds:[serialPort]	- set to a usuable com port

RETURN:		C		- set if error opening port

DESTROYED:	ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/25/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CloseComPort	proc	far
	uses	di
	.enter

EC <	call	ECCheckDS_dgroup					>
RSP <	cmp	ds:[serialPort], NO_PORT				>
RSP <	je	exit							>


	PSem	ds, serialMutex, TRASH_AX_BX
	mov	ds:[serialState], SERIAL_EXIT	;flag serial exit
	mov	bx, ds:[serialPort]		;  close off current com  
	mov	ax, STREAM_DISCARD		;  ditch any data in output Q
	CallSer	DR_STREAM_CLOSE			;
	mov	ds:[serialPort], NO_PORT
	VSem	ds, serialMutex, TRASH_AX_BX
if	_MODEM_STATUS
EC <	WARNING	TERM_COM_PORT_CLOSED					>
endif	; if _MODEM_STATUS

VSER <	call	TermUnregisterECI		; carry set if error	>
	
exit::
	.leave
	ret
CloseComPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSerialFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the serial port baud rate to current value

CALLED BY:	OpenComPort, TermSet1900, TermSet1200, ... 

PASS:		ds	- dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Do we want a raw line? what if we want the machines to operate in	
	tandem i.e. 'stty tandem'?

	when this gets called by the macro interpreter es:di->macro file
	so don't want it dorked

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/25/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetSerialFormat	proc	far

EC <	call	ECCheckDS_dgroup					>

	push	di
	cmp	ds:[serialPort], NO_PORT
	jne	doBaud
	clr	cx				;flag cx should be stuffed with
	mov	dx, offset serialFormErr	;  String resource	
	mov	bp, ERR_NO_COM			;no com port selected
	CallMod	DisplayErrorMessage		; ax, bx destroyed
	jmp	short exit
doBaud:
	mov	al, ds:[serialFormat]  		; set data format
	mov	cl, al
	andnf	cl, mask SF_LENGTH		; mask out length bits
	mov	ah, SM_RAW			; for 8 bits
	cmp	cl, SL_8BITS			; 8 bits?
	je	gotTemp				; yes, use SM_RAW
	mov	ah, SM_COOKED			; else, use SM_COOKED
gotTemp:
	mov	cx, ds:[serialBaud]		; set current baud rate
	mov	bx, ds:[serialPort]		; set port to use 
	CallSer	DR_SERIAL_SET_FORMAT		

	;
	; set flow control
	;
	mov	cx, ds:[serialFlowCtrl]
if _GET_FLOW_CONTROL_FROM_INI
	PrintMessage <This code is an aid in figuring out what kind>
	PrintMessage <of flow control works.  Probably will be removed.>
	push	si, dx
	mov	ax, cx
	mov	cx, ds
	mov	si, offset terminalCat
	mov	dx, offset serialFlowKey
	call	InitFileReadInteger		; ax = flow, or unchanged
	mov	cx, ax
	pop	si, dx
endif
	call	SerialSetFlowControl

exit:	
	pop	di
	ret
SetSerialFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSerialLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the serial line to pass 7 (COOKED) or 8 (RAW) bits of data

CALLED BY:	OpenComPort, TermSet1900, TermSet1200, ... 

PASS:		ch	- SM_COOKED
			- SM_RAW

RETURN:		nothing

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/25/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetSerialLine	proc	far

EC <	call	ECCheckDS_dgroup					>

EC <	cmp	ch, SM_COOKED						>
EC <	je	EC_10							>
EC <	cmp	ch, SM_RAW						>
EC <	ERROR_NZ	0						>
EC <EC_10:								>
	push	di
	cmp	ds:[serialPort], NO_PORT
	jne	doLine
	clr	cx				;flag cx should be stuffed with
	mov	dx, offset serialLineErr	;  String resource	
	mov	bp, ERR_NO_COM			;no com port selected
	CallMod	DisplayErrorMessage
	jmp	short exit
doLine:
	mov	al, ds:[serialFormat]  		; set data format
	mov	ah, ch				; set line COOKED/RAW
	mov	cx, ds:[serialBaud]		; set current baud rate
	mov	bx, ds:[serialPort]		; set port to use 
	CallSer	DR_SERIAL_SET_FORMAT		
exit:	
	pop	di
	ret
SetSerialLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSerialFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the format of data sent and received on the serial
		line.

CALLED BY:	whatever modifies serialFormat
PASS:		ds	= dgroup
		ch	= mask affected bits
		cl	= new value for those bits (guaranteed to be within
			  ch's mask, so we needn't mask it ourselves)
RETURN:		nothing
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AdjustSerialFormat	proc	far
		.enter

EC <	call	ECCheckDS_dgroup					>

		not	ch
		andnf	ds:[serialFormat], ch
		ornf	ds:[serialFormat], cl
		call	SetSerialFormat
		.leave
		ret
AdjustSerialFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetFlowControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/Disable software flow control
	

CALLED BY:	TermSetFlow
PASS:		ds	= dgroup
		cx	= SFC_HARDWARE, SFC_SOFWARE, 0
				what types of flow control should be enabled.

RETURN:		C	- set if couldn't set flow control

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	3/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialSetFlowControl	proc	far
	.enter

EC <	call	ECCheckDS_dgroup					>

	cmp	ds:[serialPort], NO_PORT
	jne	doFlow
	clr	cx				;flag cx should be stuffed with
	mov	dx, offset serialFlowErr	;  String resource	
	mov	bp, ERR_NO_COM			;no com port selected
	CallMod	DisplayErrorMessage
	stc					;set error flag
	jmp	short exit
doFlow:
	push	cx				; save flow settings
	mov	cl, ds:[serialFormat]  		; get data format
	andnf	cl, mask SF_LENGTH		; mask out length bits
	mov	ch, SM_RAW			; for 8 bits
	cmp	cl, SL_8BITS			; 8 bits?
	je	gotTemp				; yes, use SM_RAW
	mov	ch, SM_COOKED			; else, use SM_COOKED
gotTemp:
	call	SetSerialLine
	pop	ax				; retrieve flow settings
	mov	ds:[serialFlowCtrl], ax		;  save flow control
	mov     bx, ds:[serialPort]		;
;;	mov     cl, mask SMC_RTS                ;
;;	mov     ch, mask SMS_CTS                ;
	call	GetHardwareFlowSettings		; cx = flow control settings
;;
	CallSer	DR_SERIAL_SET_FLOW_CONTROL	;		
	clc					;clear error flag
exit:
	.leave
	ret
SerialSetFlowControl	endp

GetHardwareFlowSettings	proc	near
	uses	ax, bx, dx, si, di, bp
	.enter
EC <	call	ECCheckDS_dgroup					>

	GetResourceHandleNS	StopRemoteList, bx
	mov	si, offset StopRemoteList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax = remote settings (low)
	push	ax

	GetResourceHandleNS	StopLocalList, bx
	mov	si, offset StopLocalList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax = local settings (low)
	pop	cx
	mov	ch, al
	.leave
	ret
GetHardwareFlowSettings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSerialBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a BREAK signal out the serial line
	

CALLED BY:	ScreenKeyboard

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendSerialBreak	proc	far
	.enter
EC <	call	ECCheckDS_dgroup					>

						;turn on the break bit	
	mov	cx, (1 shl offset SF_BREAK) or (mask SF_BREAK shl 8);
	call	AdjustSerialFormat

	mov	ax, BREAK_LENGTH
	mov	bx, ds:[termProcHandle]
	call	TimerSleep
						;reset the break bit
	mov	cx, (0 shl offset SF_BREAK) or (mask SF_BREAK shl 8);
	call	AdjustSerialFormat
exit:
	.leave
	ret
SendSerialBreak	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialDropCarrier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Drop the carrier signal
	

CALLED BY:	TermCloseAppl

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, es, si

PSEUDO CODE/STRATEGY:
	We want to drop the modem's Carrier Detect signal.  Adam says
	one way to do it is to send '+++' to get the modem's attention
	then send 'ATH0' to hang up the phone.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	6/04/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

getModem	db	"+++"
hangUpModem	db	"ATH0",13

SerialDropCarrier	proc	far

EC <	call	ECCheckDS_dgroup					>

	push	es
	mov     bx, ds:[serialPort]             ; check for serial port
	cmp	ds:[serialPort], NO_PORT
	jne	doHangUp
	clr	cx				; flag that cx should be stuffed
	mov	dx, offset sendBufErr		;	with Strings resource
	mov	bp, ERR_NO_COM
	CallMod	DisplayErrorMessage
	jmp	short exit

doHangUp:
	segmov	es, cs, si

	mov	ax, ONE_SECOND
	mov	bx, ds:[termProcHandle]
	call	TimerSleep
	
	mov	si, offset getModem
	mov	cx, 3
	CallMod	SendBuffer

	mov	ax, TWO_SECOND
	mov	bx, ds:[termProcHandle]
	call	TimerSleep
	
	mov	si, offset hangUpModem
	mov	cx, 5
	CallMod	SendBuffer

	mov	ax, 120
	mov	bx, ds:[termProcHandle]
	call	TimerSleep
exit:
	pop	es
	ret
SerialDropCarrier	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialReadData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle data coming in port

CALLED BY:	StreamDriver via MSG_READ_DATA

PASS:		ds	- dgroup		
		cx      - number of bytes available
		bp      - STREAM_READ

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	if (serialSuspendInput = FALSE) {

	    call Stream Driver strategy routine to copy the characters
	         (if any) into auxBuf.

	    call one of:
		    ScriptInput		(when script is executing)
		    FileSendData	(when sendind a file)
		    FileRecvData	(when receiving a file)
		    FSMParseString	(when receiving input for screen)

		(routine is called with characters in buffer in DOS code
		 page of host computer, if any)

	} else {

	    /* we are in the process of executing a script, and auxBuf
	       still contains unprocessed characters. Abort for now. */

	}
	return

	MODEM_STATUS:

	When modem status feature is enabled, it checks the status of modem
	for connection. All it does is to parse the modem response
	string. So, we allocate a buffer to hold one line at a time and parse
	it immediately to determine the action to take. During capturing
	modem response, we suspend calling the callback routine stored in 
	dgroup:[routineHandle] and dgroup:[routineOffset]. To store
	the data coming in later processing, we just keep it in
	dgroup:[auxBuf]. So, we have dgroup:[responseAuxHead] to indicate
	where to store the next byte from serial line while checking modem
	status.

	dgroup:[responseBufHandle] is the condition to determine if we are in
	modem status checking mode. It is NULL if not in modem status
	checking mode, otherwise holding the block handle of response buffer. 
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/19/90	Initial version
	eric	9/90		added serialSuspendInput checking, to fix
				script bugs.
	simon	 7/ 2/95	Added modem status codes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialReadData 	method SerialReaderClass, MSG_READ_DATA

EC <	call	ECCheckDS_dgroup					>
EC <	call	ECCheckRunBySerialThread				>

	;if executing a script, and auxBuf still contains unprocessed
	;characters, then abort. When the script code hits a MATCH or PAUSE
	;command, it will call SerialContinueInput, which will reset this
	;flag, and call this routine, so that we will poll the Stream Driver
	;to get the characters which have been waiting.

	cmp	ds:[serialThreadMode], STM_SCRIPT_SUSPEND
	LONG je	done			;skip if suspending input...

if _LOGIN_SERVER
	; Protect serialPort with a the login semaphore, as we don't
	; want to read from the port if we've already shut down the
	; login server.
	PSem	ds, loginSem

	;if there was an error opening COM port: just skip to end.
	cmp	ds:[serialPort], NO_PORT
	jne	keepGoing			;skip if no port opened...
	VSem	ds, loginSem
	jmp	done
keepGoing:

else ; not _LOGIN_SERVER

	;if there was an error opening COM port: just skip to end.
	cmp	ds:[serialPort], NO_PORT
	LONG je	done			;skip if no port opened...

endif ; not _LOGIN_SERVER

	;regular operation: just grab up to 1K of data from the Stream Driver,
	;placing it into auxBuf.

;if ERROR_CHECK
;	mov	cx, AUX_BUF_SIZE
;	mov	al, 0
;	segmov	es, ds
;	mov	di, offset auxBuf
;	rep stosb
;endif

	mov	bx, ds:[serialPort]	;set port to read

if	_MODEM_STATUS
	cmp	ds:[responseBufHandle], NULL
	je	dontSaveInput		; jmp if not checking modem status
	mov	si, ds:[responseAuxHead]
	add	si, offset dgroup:auxBuf; si <- nptr to buffer to start
					; storing incoming data
	jmp	10$			; read data now

dontSaveInput:
	;
	; If ds:[responseAuxHead] is non-zero, it indicates that there is
	; data in buffer unprocessed by the callback routine. That also means
	; there has been data coming in since modem status checking starts.
	;
	clr	si			; si <- nptr (default buffer ptr)
	xchg	si, ds:[responseAuxHead]; any bytes left to process during
					;   response handling
	tst	si			; responseAuxHead is zero?
	jz	5$			; there's no unprocessed data
	add	si, offset dgroup:auxBuf; si <- nptr to buffer to store
					; incoming data
	jmp	10$
endif	; if _MODEM_STATUS

5$::
	mov	si, offset auxBuf	;read as many as are there,

10$::
	mov	cx, AUX_BUF_SIZE	;but don't make us wait
	PSem	ds, serialMutex, TRASH_AX
	mov	ax, STREAM_NOBLOCK		
	CallSer	DR_STREAM_READ		;returns cx = # characters
	VSem	ds, serialMutex, TRASH_AX_BX

SRD_read	label	near		; Convenient label for breakpoints
EC <	call	ECCheckDS_dgroup					>

if _LOGIN_SERVER
	;
	; If running in login server mode, pass data to comm protocol
	; callback for filtering.
	;
	cmp	ds:[loginPhase], LP_ACTIVE
	jne	notLoginMode
	jcxz	notLoginMode

	mov	dx, ds
	mov	bp, si				; dx:bp = input buffer

	mov	bx, ds:[loginAttachVars].LAI_connection
	mov	ss:[TPD_dataBX], bx

	mov	bx, ds:[loginAttachVars].LAI_callback.segment
	mov	ax, ds:[loginAttachVars].LAI_callback.offset

	call	ProcCallFixedOrMovable	; returns cx, carry
	jnc	notLoginMode

	;
	; Callback detected comm protocol data in buffer.  Stop processing
	; further data (don't wipe out loginCallback, 'cause we still need it)
	;
	mov	ds:[serialPort], NO_PORT	; prevents future reads

	push	cx
	mov	ax, MSG_TERM_DETACH_FROM_PORT
	mov	cx, LoginResponse <0, LS_CONTINUE>
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage	
	pop	cx

notLoginMode:
	VSem	ds, loginSem

endif ; _LOGIN_SERVER

	;;;
	;;; ds:si	= Input buffer
	;;; cx		= # chars in buffer
	;;;

EC <	call	ECCheckDS_dgroup					>

	;
	; Make sure we've processed all the input data in the stream.
	; If there may be more, queue up another notification.
	;
		cmp	cx, AUX_BUF_SIZE
		jb	afterQueue

		mov	bx, ds:[threadHandle]
		mov	ax, MSG_READ_DATA
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
afterQueue:
	;
	; Work around a "feature" of the LocalXXXToXXXX routines,
	; where conversion stops as soon as a NULL character is reached,
	; regardless of how big we said the buffer was.
	; Strip them out here so that real data can be successfuly
	; converted.  -CT 5/96
	;
DBCS <	PrintMessage <--- >						>
DBCS <	PrintMessage <--- DBCS Character boundaries not respected here>	>
DBCS <	PrintMessage <--- >						>

if not DBCS_PCGEOS	; StripNULFromBuffer crashes under DBCS
	call	StripNULFromBuffer		; cx <- new buffer size
endif ; not DBCS_PCGEOS

	;for the sake of the Script module, update the pointer which is
	;used to scan through auxBuf.

if	_MODEM_STATUS
	cmp	ds:[responseBufHandle], NULL
	je	parseFromBegin		; jmp if not checking modem status
	add	ds:[responseAuxHead], cx; responseAuxHead <- next pos to store
					;   chars 
	jmp	20$

parseFromBegin:
	mov	ax, si			; ax <- nptr to read from buf 
	sub	ax, offset dgroup:auxBuf; ax <- #unprocessed chars
	add	cx, ax			; cx <-# unprocessed + new chars
	mov	si, offset dgroup:auxBuf; si <- buffer begin to parse
endif	; if _MODEM_STATUS
	
	mov	ds:[auxHead], offset dgroup:auxBuf

20$::
	mov	ds:[auxNumChars], cx

	jcxz	done			;if no characters returned,
					; then don't call handler...

	;now call appropriate routine to handle this buffer. In the case
	;of simple "pass through to FSM" or file-transfer, the entire
	;buffer is processed synchronously. In the case of SCRIPT mode,
	;auxHead and auxNumChars will be updated to reflect how
	;much of auxBuf has not been processed.

	segmov	es, ds, bx		;es->dgroup

if	_MODEM_STATUS
	cmp	ds:[responseBufHandle], NULL
	je	dontCheckModem		;no need to check modem
	call	SerialCheckModemStatus	;nothing returns and destroyed
	jmp	done			;don't process anything until we are
					;done checking modem status

dontCheckModem:
endif	
	
	PSem	ds, inputDirectionSem	;block on semaphore if thread 0
	mov	ax, ds:[routineOffset]	;is changing these values.
	mov	bx, ds:[routineHandle]
	VSem	ds, inputDirectionSem

	call	ProcCallModuleRoutine	;call one of four routines
					;returns cx = # unprocessed chars

	;again, for the sake of scripts, let's keep track of how many
	;unprocessed chars remain in [auxBuf].

EC <	call	ECCheckDS_dgroup					>
	mov	ds:[auxNumChars], cx

done:
	ret
SerialReadData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallExternalCommProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the communication driver's callback function

CALLED BY:	INTERNAL
PASS:		(from documentation of callback routine)
		Pass:	cx = # bytes of data in buffer
			bx = LAI_connection token
			dx:bp = input data to check for PPP data
		
		Return:
			carry set if PPP data confirmed (login done)
			   app must not read/write port after getting this.
			cx = bytes of non-protocol data in buffer
			buffer contents unchanged.
		
DESTROYED: none

SIDE EFFECTS:	Dorks TPD_dataAX/BX

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	7/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _LOGIN_SERVER
CallExternalCommProtocol	proc	near
	uses	ds
	.enter


	.leave
	ret
CallExternalCommProtocol	endp

endif ; _LOGIN_SERVER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialFinishReadingData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The script is currently suspended by a PROMPT, PAUSE,
		or END command. Process the rest of the characters in
		[auxBuf], then tell the Serial module that it can
		accept chars from the Stream Driver again.

CALLED BY:	see Serial/serialScript.asm

PASS:		*ds:si		= SerialReaderClass object instance data
		ds:[auxBuf]	= buffer of unprocessed characters (may also
				contain some older processed characters,
				if we suspended input, and are now allowing
				input to continue)
		ds:[auxHead]	= pointer to start of unprocessed chars in auxBf
		ds:[auxNumChars]	= number of unprocessed chars in auxBuf

RETURN:		ds, es		= dgroup

DESTROYED: 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialFinishReadingData proc far

EC <	call	ECCheckDS_dgroup					>
EC <	call	ECCheckRunBySerialThread				>

;not necessary, due to new, cleaner states.
;	;first, see if this method is ariving too late: the PROMPT phase
;	;has already ended, and we are now in the middle of executing the
;	;script again. If so, ignore this method, leaving the auxBuf data
;	;as is. When we reach another PROMPT or PAUSE phase, or the script
;	;ends, we will get another MSG_SCRIPT_CONTINUE_INPUT, and will
;	;read the remainder of auxBuf.
;
;	cmp	ds:[serialThreadMode], STM_SCRIPT_SUSPEND
;	je	done

	;first see if there are any unprocessed characters in auxBuf:

	segmov	es, ds, ax
	tst	es:[auxNumChars]
	jz	notifySerial		;skip if not...

	call	ScriptInput		;process as many as we can

	tst	es:[auxNumChars]	;are there any left?
	jnz	done			;skip to end if so. We might be
					;in MATCH mode again, want to
					;leave unprocessed chars in auxBuf...

	;we might have lapsed back into STM_SCRIPT_SUSPEND mode. If so,
	;let's bail. Eventually the Stream Driver will send us another
	;MSG_READ_DATA.

	cmp	ds:[serialThreadMode], STM_SCRIPT_SUSPEND
	je	done

notifySerial:
	;all characters from [auxBuf] have been processed. Notify the
	;Serial module that the Stream Driver can be allowed to bring more
	;characters into [auxBuf].

	call	SerialContinueInput

done:
	ret
SerialFinishReadingData endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialContinueInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called by the script module, when it
		hits a MATCH of PAUSE command, and is ready to process more
		input.

CALLED BY:	handlers for:
			MSG_SERIAL_ENTER_SCRIPT_PROMPT_MODE
			MSG_SERIAL_ENTER_SCRIPT_PAUSE_MODE
			MSG_SERIAL_EXIT_SCRIPT_MODE

PASS:		ds, es	- dgroup		
		[serialThreadMode] = already changed to one of:
				STM_NORMAL
				STM_SCRIPT_PROMPT
				STM_SCRIPT_PAUSE

RETURN:		ds, es	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	10/90		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialContinueInput	proc	near

EC <	call	ECCheckDS_dgroup					>
EC <	call	ECCheckRunBySerialThread				>

	;reset a flag so that SerialReadData is allowed to respond to
	;notifications from the Stream Driver.

EC <	cmp	ds:[serialThreadMode], STM_SCRIPT_SUSPEND		>
EC <	ERROR_E TERM_ERROR						>

	;now, in case we have missed notification from the Stream Driver,
	;let's poll it to see if it wants to give us input.

	call	SerialReadData
	ret
SerialContinueInput	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialReadBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pass buffer of chars to be processed

CALLED BY:	MSG_READ_BUFFER

PASS:		ds	- dgroup		
		cx      - size  of buffer
		dx:bp	- segment of buffer	

		(characters are in BBS code page)

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialReadBuffer 	method SerialReaderClass, MSG_READ_BUFFER

EC <	call	ECCheckDS_dgroup					>

	segmov	es, ds, ax			;es - dgroup
	mov	ds, dx
	mov	si, bp				;ds:si - buffer to read	
	CallMod FSMParseString                  ;

	ret
SerialReadBuffer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialReadBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pass buffer of chars to be processed as a heap block

CALLED BY:	MSG_READ_BLOCK

PASS:		ds	- dgroup		
		cx      - size  of buffer
		dx	- handle of buffer

		(characters are in BBS code page)

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialReadBlock 	method SerialReaderClass, MSG_READ_BLOCK
	cmp	cx, size auxBuf			; paranoid check...
	jbe	sizeOK				; ...drop chars if too many
	mov	cx, size auxBuf			; (shouldn't happen)
sizeOK:

	push	ds				; save ds = dgroup
	push	cx				; save number of chars
	segmov	es, ds				; es - dgroup
	mov	bx, dx
	call	MemLock
	mov	ds, ax				; ds:si - buffer
	clr	si
	mov	di, offset auxBuf		; es:di = auxBuf
	rep movsb				; copy chars into auxBuf
	call	MemFree				; free block after copying
	pop	cx				; retrieve number of chars
	pop	ds				; ds = es = dgroup
	mov	si, offset auxBuf		; ds:si = auxBuf
	CallMod FSMParseString

	ret
SerialReadBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialReadChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pass chars to be processed

CALLED BY:	MSG_READ_CHAR

PASS:		ds	- dgroup		
		cl	- char to process 

		(character is in BBS code page)

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialReadChar 	method SerialReaderClass, MSG_READ_CHAR

EC <	call	ECCheckDS_ES_dgroup					>

	mov     si, offset dgroup:auxBuf

	mov     es:[si], cl                     ;echo character to screen
	segmov  ds, es, cx                      ;ds:si -> buffer
	mov     cx, 1				;
	CallMod FSMParseString                  ; (pass in BBS code page)

	ret
SerialReadChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCheckPorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check which ports are available

CALLED BY:	

PASS:		ds	- dgroup	

RETURN:		bp	- SerialDeviceMap record (1 SHL SERIAL_COM? set if
			  port SERIAL_COM? exists)

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialCheckPorts 	proc	far
EC <	call	ECCheckDS_dgroup					>

	CallSer	DR_STREAM_GET_DEVICE_MAP	; Fetch device map in AX
	xchg	ax, bp				; Return in bp...of course
	ret
SerialCheckPorts 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialNukeFSM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Queue up a method to nuke the fsm's

CALLED BY:	MSG_NUKE_FSM

PASS:		ds:[termTable]	- table to make room in
		es, ds		- dgroup
RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialNukeFSM 	method SerialReaderClass, MSG_NUKE_FSM
EC <	call	ECCheckDS_dgroup					>

	mov	ax, MSG_REALLY_NUKE_FSM	;queue up method to nuke
	SendSerialThread			;	FSMs
	ret
SerialNukeFSM	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialReallyNukeFSM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up all LMem blocks used for  terminal FSM

CALLED BY:	MSG_REALLY_NUKE_FSM

PASS:		ds:[termTable]	- table to make room in
		es, ds		- dgroup
RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialReallyNukeFSM 	method SerialReaderClass, MSG_REALLY_NUKE_FSM
EC <	call	ECCheckDS_dgroup					>
	mov	bp, offset dgroup:termTable	;point to terminal table
	mov	dl, ds:[bp].TTS_numEntries	;get number of table entries
	tst	dl				;if table empty exit
	jz	90$
	add	bp, TERM_TABLE_HEADER_SIZE	;offset to first entry
10$:	
	mov	cx, ds:[bp].TTE_termHandle 	;get fsm handle to free
	CallMod	FSMDestroy	
	add	bp, TERM_TABLE_ENTRY_SIZE	;point to next term entry
	dec	dl				;are we done with table
	tst	dl				;
	jz	90$
	jmp	short 10$			;	
90$:
	mov     ax, MSG_SCR_EXIT
	mov     bx, ds:[termuiHandle]
	CallScreenObj                           ;tell screen object to exit
	ret
SerialReallyNukeFSM	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndComUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	TermCloseAppl

PASS:	

RETURN:			

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	08/03/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EndComUse 	proc	far
EC <	call	ECCheckDS_dgroup					>
	mov     ax, MSG_PROCESS_EXIT
	clr     cx                              ;pass exit code
	mov     dx, cx                          ;no need to send out MSG_META_ACK
	mov     bp, cx                          ;shut down the thread
	mov     bx, ds:[threadHandle]
	mov     di, mask MF_FORCE_QUEUE         ;
	call    ObjMessage                      ;
	ret
EndComUse 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the first method that this SerialReaderClass object
		will receive. It is sent by SerialInThread
		(Serial/serialIn.asm), when it creates this object and a
		thread to run it. We must initialize some variables,
		and V a semaphore that the application thread (GeoComm #0)
		has been blocked on.

CALLED BY:	MSG_META_ATTACH

PASS:		ds	= dgroup

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
	eric	9/90		doc update, initializes serialSuspendInput

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialAttach	method	SerialReaderClass, MSG_META_ATTACH

EC <	call	ECCheckDS_dgroup					>

	;Reset a flag which is used by SerialReadData to determine if
	;we are allowed to grab more input chars from the Stream Driver.
	;This flag will be set by the script code as it is executing
	;a script.

	mov	ds:[serialThreadMode], STM_NORMAL

	;now V a semaphore which our application thread has been blocked on.

	VSem	ds, startSem
	ret
SerialAttach	endp

if	not _MODEM_STATUS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetTerminal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new FSM for us to use.

CALLED BY:	MSG_READ_SET_TERMINAL
PASS:		ds	= dgroup
		cl	= terminal type to use
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialSetTerminal	method	SerialReaderClass, MSG_READ_SET_TERMINAL
EC <	call	ECCheckDS_dgroup					>
	CallMod	ProcessTermcap
	ret
SerialSetTerminal	endp

endif	; if !_MODEM_STATUS
		
if	_MODEM_STATUS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCheckModemStatusStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin checking modem status. Alloc buffer to capture modem
		response 

CALLED BY:	MSG_SERIAL_CHECK_MODEM_STATUS_START
PASS:		*ds:si	= SerialReaderClass object
		ds:di	= SerialReaderClass instance data
		es 	= segment of SerialReaderClass
		ax	= message #
RETURN:		carry set if error
DESTROYED:	ax, cx
SIDE EFFECTS:	
	The buffer to hold modem response lines is locked.

	responseBufHandle	updated
	responseBufPtr		updated and reset
	responseAuxHead		reset

PSEUDO CODE/STRATEGY:
	MemAlloc block for storing modem response by lines;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialCheckModemStatusStart	method	dynamic	SerialReaderClass, 
					MSG_SERIAL_CHECK_MODEM_STATUS_START
		.enter
		GetResourceSegmentNS	dgroup, ds
	;
	; Allocate buffer for modem response
	;
		mov	ax, RESPONSE_BUF_SIZE
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; bx <- hptr of block
						; ax <- sptr of locked block
						; cx destroyed
						; carry set if error
		jc	done
	;
	; Reset variables
	;
		mov	ds:[responseBufHandle], bx
		mov	ds:[responseBufPtr].segment, ax
		clr	ds:[responseBufPtr].offset
						; reset response buffer ptr
		clr	ds:[responseAuxHead]	; reset aux head

done:
		.leave
		ret
SerialCheckModemStatusStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCheckModemStatusEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up checking modem status

CALLED BY:	MSG_SERIAL_CHECK_MODEM_STATUS_END
PASS:		*ds:si	= SerialReaderClass object
		ds:di	= SerialReaderClass instance data
		es 	= segment of SerialReaderClass
		ax	= message #
		dgroup:[responseBufHandle]	= hptr to block holding modem
						response 
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (responseBufHandle != NULL) {
		MemFree modem response block;
		Send a message to serial thread to read data to display any
			buffered data to screen;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialCheckModemStatusEnd	method	dynamic	SerialReaderClass,
					MSG_SERIAL_CHECK_MODEM_STATUS_END
		uses	ax, cx, dx, bp
		.enter

		GetResourceSegmentNS	dgroup, ds
		mov	bx, NULL
		xchg	bx, ds:[responseBufHandle]
		cmp	bx, NULL		; is there a buffer to kill?
		je	done			; no buffer to kill
		call	MemFree			; bx destroyed
	;
	; Send a message to itself to flush buffer data to screen so that we
	; don't have to wait until data actually comes in from serial
	; port. SerialReadData has to know there are bytes to process even
	; though no bytes actually sent in.
	;
		mov	ax, MSG_READ_DATA
		clr	cx			; no data
		mov	bp, STREAM_READ
		SendSerialThread
done:		
		.leave
		ret
SerialCheckModemStatusEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSendInternalModemCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send internal preset modem command

CALLED BY:	MSG_SERIAL_SEND_INTERNAL_MODEM_COMMAND
PASS:		*ds:si	= SerialReaderClass object
		ds:di	= SerialReaderClass instance data
		es 	= segment of SerialReaderClass
		ax	= message #
		dl 	= TermInternalModemInitString
			
RETURN:		carry set if connection error
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (responseBufHandle == NULL) {
		return;
	}
	if (not already received modem response) {
		Start a timer;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
modemInitFactoryCmd	char	"AT&F", CHAR_CR
modemInitInternalCmd	char	"ATE1", CHAR_CR

SerialSendInternalModemCommand	method dynamic SerialReaderClass, 
					MSG_SERIAL_SEND_INTERNAL_MODEM_COMMAND
		CheckHack <(size modemInitInternalCmd) ge (size modemInitFactoryCmd)>
                sendCmd local   (size modemInitInternalCmd) dup (char)
                                                ; command buf to send
		.enter
EC <		Assert_etype	dl, TermInternalModemInitString		>
	
		GetResourceSegmentNS	dgroup, es
		cmp	es:[responseBufHandle], NULL
		je	releaseSem		; nothing to process
	;
	; Check which init string to send
	;
		CheckHack <TIMIS_FACTORY eq 0>
		CheckHack <TermInternalModemInitString eq 2>
						; assume only two types
		tst	dl
		jz	factory
		mov	si, offset modemInitInternalCmd
		jmp	sendInit

factory:
		mov	si, offset modemInitFactoryCmd
	;
	; Send internal init string to modem
	;
sendInit:
                segmov  ds, cs, ax              ; dssi<-src string to copy
                segmov  es, ss, ax
                lea     di, ss:[sendCmd]        ; esdi<-dest buf to hold str
                copybuf <size sendCmd>
                GetResourceSegmentNS    dgroup, ds
                lea     si, ss:[sendCmd]        ; essi<-dest buf to send str
                mov     cx, size sendCmd
		call	SendBuffer		; essi <-points past text
						; carry set if error
						; ax,bx destroyed
		jc	done
	;
	; Pause a little for modem to consume the command
	;
		mov	ax, 10
		call	TimerSleep
	;
	; Start timer and wait for modem response
	;
		mov	ch, 1			; short timeout
		segmov	es, ds, ax
		call	SerialStartResponseTimer
		clc
done:
		.leave
		ret

releaseSem:
	;
	; Caller blocked on here. Probably, user has cancelled
	; connection. So, we have to release it.
	;
		VSem	es, responseReplySem, TRASH_AX_BX
		jmp	done
SerialSendInternalModemCommand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSendCustomModemCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send custom modem command

CALLED BY:	MSG_SERIAL_SEND_CUSTOM_MODEM_COMMAND
PASS:		*ds:si	= SerialReaderClass object
		ds:di	= SerialReaderClass instance data
		es 	= segment of SerialReaderClass
		ax	= message #
		ch	= timeout value:
			  if 0:	TERM_LONG_REPLY_TIMEOUT 
			  if 1: TERM_SHORT_REPLY_TIMEOUT
		cl	= number of characters to send (non-zero)
		dx:bp	= fptr of custom command string w/o CR character
			(SBCS)
			
RETURN:		carry set if connection error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (responseBufHandle == NULL) {
		return;
	}
	if (string to send does not start with "AT") {
		Send "AT";
	}
	Send custom command string;
	if (not already received modem response) {
		Start a timer;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
modemCommandPrefix	char	"AT"

SerialSendCustomModemCommand	method dynamic SerialReaderClass, 
					MSG_SERIAL_SEND_CUSTOM_MODEM_COMMAND
		.enter
EC <		tst	cx						>
EC <		ERROR_Z TERM_CANNOT_SEND_EMPTY_CUSTOM_MODEM_COMMAND	>
		push	cx
		GetResourceSegmentNS	dgroup, ds
		cmp	ds:[responseBufHandle], NULL
		je	releaseSem		; nothing to process

		movdw	essi, dxbp		; es:si <- fptr to command
EC <		Assert_fptrXIP	essi					>
	;
	; Check if the modem init string already has modem command prefix. If
	; it starts with 'A', we assume it is "AT..." and send it. That may
	; not cover the modem init strings "AE1". But this is fine since we
	; do not want to end up sending "ATAE1" anyway.
	;
		clr	ch
		cmp	{byte}es:[si], 'a'
		jz	sendCustomCommand
		cmp	{byte}es:[si], 'A'
		jz	sendCustomCommand
	;
	; Now, the string does not start with 'a'. Send "AT" command prefix.
	;
		push	es, si, cx
FXIP <		push	ax						>
FXIP <		segmov	ds, cs, ax					>
NOFXIP <	segmov	es, cs, si					>
		mov	si, offset modemCommandPrefix
		mov	cx, size modemCommandPrefix

FXIP <		call	SysCopyToStackDSSI				>
FXIP <		segmov	es, ds, ax		; es:si <- buffer to send>
	
		call	SendBuffer		; carry set if error

FXIP <		lahf							>
FXIP <		call	SysRemoveFromStack				>
FXIP <		sahf							>
		
FXIP <		pop	ax						>
		pop	es, si, cx
		jc	done
	
sendCustomCommand:
	;
	; Send the custom modem command
	;
		call	SendBuffer		; carry set if connection err
		jc	done
	;
	; Send CR character so that modem will process the command
	;
		mov	cl, C_CR
		call	SendChar		; carry set if connection err
		jc	done
	;
	; Start the timer and set up for waiting and parsing modem response
	;
		pop	cx			; ch <- timeout value
		segmov	es, ds, ax		; es <- dgroup
		call	SerialStartResponseTimer
		clc
		jmp	exit
done:
		pop	cx
exit:
		.leave
		ret
releaseSem:
	;
	; Caller blocked on here. Probably, user has cancelled
	; connection. So, we have to release it.
	;
		VSem	es, responseReplySem, TRASH_AX_BX
		jmp	done
SerialSendCustomModemCommand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSendDialModemCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send dial modem command

CALLED BY:	MSG_SERIAL_SEND_DIAL_MODEM_COMMAND
PASS:		*ds:si	= SerialReaderClass object
		ds:di	= SerialReaderClass instance data
		es 	= segment of SerialReaderClass
		ax	= message #
		cl	= number of characters to send
		dx:bp	= fptr of custom command string w/o CR character
	
RETURN:		carry set if connection error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (responseBufHandle == NULL) {
		return;
	}
	if (not already received modem response) {
		Start a timer;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dialPrefix	char	"ATD"
	
SerialSendDialModemCommand	method dynamic SerialReaderClass, 
					MSG_SERIAL_SEND_DIAL_MODEM_COMMAND
				
	dialPrefixToSend        local   (size dialPrefix) dup (char)
						; dial prefix to send for XIP
		.enter
		push	cx
		GetResourceSegmentNS	dgroup, ds
		cmp	ds:[responseBufHandle], NULL
		je	releaseSem		; nothing to process
	;
	; Send ATD prefix
	;
		segmov	ds, cs, ax
		mov	si, offset dialPrefix
		segmov	es, ss, ax
		lea	di, ss:[dialPrefixToSend]
		copybuf	<size dialPrefix>	; dialPrefixToSend filled
		GetResourceSegmentNS	dgroup, ds
		lea	si, ss:[dialPrefixToSend]
		mov	cx, size dialPrefix
		mov	ds:[systemErr], FALSE	; catch error in SendBuffer
		call	SendBuffer		; carry set if error
		jc	done			; check for send buf error
	;
	; Send Tone or Pulse
	;
		tst	ds:[toneDial]	
		jz      pulse
		mov     cl, CHAR_TONE
		jmp     20$
pulse:
		mov     cl, CHAR_PULSE
20$:
		call 	SendChar		; carry set if error	
		jc	done
	;
	; Send the phone number
	;
		pop	cx			; cl <- #chars to send
		clr	ch			; cx <- #chars to send
		mov	si, ss:[bp]
		mov	es, dx			; es:si <- string to send
EC <		Assert_fptrXIP	essi					>
		call	SendBuffer		; carry set if connection err
		jc	exit
	;
	; Send CR character so that modem will process the command
	;
		mov	cl, C_CR
		call	SendChar		; carry set if connection err
		jc	exit
	;
	; Start the timer and set up for waiting and parsing modem response
	;
		clr	ch			; long timeout
		segmov	es, ds, ax		; es <- dgroup
		call	SerialStartResponseTimer
		clc
		jmp	exit
done:
		pop	cx			; restore stack
exit:
		.leave
		ret

releaseSem:
	;
	; Caller blocked on here. Probably, user has cancelled
	; connection. So, we have to release it.
	;
		VSem	es, responseReplySem, TRASH_AX_BX
		jmp	done
SerialSendDialModemCommand	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialModemResponseTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timeout waiting for modem response

CALLED BY:	MSG_SERIAL_MODEM_RESPONSE_TIMEOUT
PASS:		*ds:si	= SerialReaderClass object
		ds:di	= SerialReaderClass instance data
		es 	= segment of SerialReaderClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (waiting for response) {
		Set responseType;
		Clear timer variables;
		VSem the semaphore;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialModemResponseTimeout	method dynamic SerialReaderClass, 
					MSG_SERIAL_MODEM_RESPONSE_TIMEOUT
		.enter

		GetResourceSegmentNS	dgroup, es
		BitTest	es:[statusFlags], TSF_WAIT_FOR_MODEM_RESPONSE
		jz	done
	;
	; Clear timer info and set result code
	;
		clr	ax
		mov	es:[termResponseTimer], ax
		mov	es:[termResponseTimerID], ax
		mov	es:[responseType], TMRT_TIMEOUT
		BitClr	es:[statusFlags], TSF_WAIT_FOR_MODEM_RESPONSE
		VSem	es, responseReplySem, TRASH_AX
done:
		.leave
		ret
SerialModemResponseTimeout	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCancelConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel the connection being established

CALLED BY:	MSG_SERIAL_CANCEL_CONNECTION
PASS:		*ds:si	= SerialReaderClass object
		ds:di	= SerialReaderClass instance data
		es 	= segment of SerialReaderClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialCancelConnection	method dynamic SerialReaderClass, 
					MSG_SERIAL_CANCEL_CONNECTION
		uses	ax, cx, dx, bp
		.enter
	;
	; At this point, the phone number should be dialing and the
	; connection may or may have been made. We do not need to close the
	; com port because TermMakeConnection will close it anyway.
	;
		GetResourceSegmentNS	dgroup, ds
		mov	ds:[responseType], TMRT_USER_CANCEL
	;
	; Check if we need to VSem responseReplySem. At this point, caller
	; for connection either has been V'ed or not V'ed (since it's also
	; V'ed by this serial thread). If it has been V'ed, that means it has
	; also called SerialCheckModemStatusEnd
	;
		cmp	ds:[responseBufHandle], NULL
		je	done
		mov	ax, MSG_SERIAL_CHECK_MODEM_STATUS_END
		CallSerialThread	
	;
	; Stop the timer
	;
		segmov	es, ds, ax		; es <- dgroup
		BitSet	es:[statusFlags], TSF_RECEIVED_MODEM_RESPONSE
	;
	; Need to unblock anyone?
	;
		BitTest	es:[statusFlags], TSF_WAIT_FOR_MODEM_RESPONSE
		jz	done
		BitClr	es:[statusFlags], TSF_WAIT_FOR_MODEM_RESPONSE
		call	SerialStopResponseTimer
		VSem	es, responseReplySem, TRASH_AX_BX
done:
		.leave
		ret
SerialCancelConnection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCheckModemStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the modem status depending on the modem response

CALLED BY:	SerialReadData
PASS:		es	= dgroup
		ds:si	= buffer of characters to parse
		cx	= number of new bytes in response buffer
		es:[responseBufPtr]	= fptr of response buffer	
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	(The code template is originally from Class1SendParseData in
	c1sMDriver.asm) 

	current_ptr = buffer_start;
	/*
	 * If there is a complete response in the packet (buffer), handle
	 * it. Exit 
	 */
	while (buffer_char_count-- && buffer not deleted) {
		switch (buffer[current_ptr]) {
		case C_CR:
		case C_LF:
			/*
			 * Modem response starts and ends
			 */
			if (responsePtr != 0) 	{	/* there's response */
				Parse response buffer for appropriate action;
				if (responseBufHandle == NULL) {
					/* done checking modem status */
					return;
				}
			}
			responsePtr = 0;
			break;
		default:
			/* Empty response buffer if full */
			if (responsePtr reached the end of buffer) {
				responsePtr = 0;
			}
			/* copy char to response buffer */
			responseBuf[responsePtr++] =
				buffer[current_ptr - 1];
		}
		current_ptr++;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialCheckModemStatus	proc	near
		uses	ax, bx, cx, dx, si, di, ds
		.enter
EC <		Assert_dgroup	es					>
EC <		push	es, di						>
EC <		movdw	esdi, dssi					>
EC <		Assert_okForRepScasb					>
EC <		pop	es, di						>
	;
	; If the response buffer is gone, then do nothing
	;
		cmp	es:[responseBufHandle], NULL
		je	done
	;
	; Get pointer to response buffer
	;
		mov	di, es:[responseBufPtr].offset
						; ds:di <- current response
						; buf fptr
	;
	; Scan the buffer for LF/CR as delimiter. Parse the modem response
	; buffer whenever a line has been read in.
	;
scanLoop:
		mov	al, ds:[si]		; al <- current char
		tst	al			; ignore NUL chars
		jz	nextChar
		cmp	al, C_CR
		je	foundLineBreak
		cmp	al, C_LF
		je	foundLineBreak
	;
	; Regular character. Store in response buffer.
	;
		push	ds
		mov	ds, es:[responseBufPtr].segment
						; ds <- response buf sptr
	;
	; If response buffer overflows, we will parse whatever in the
	; response buffer.
	;
	; ds:di <- fptr to response buffer to store next character
	;
		cmp	di, RESPONSE_BUF_SIZE
		jb	copyToResponse		; not overflow
EC <		WARNING TERM_RESPONSE_BUF_OVERFLOW			>
		call	SerialParseModemResponse
		clr	di			; reset response buffer ptr
		
copyToResponse:
EC <		Assert_fptr	dsdi					>
		mov	ds:[di], al		; copy char to response buf
		pop	ds			; ds <- sptr of src buffer
		inc	di			; update response buf ptr
		jmp	nextChar
	
foundLineBreak:
		tst	di			; response buffer empty?
		jz	nextChar		; do nothing if no response
						; in response buffer
		mov	es:[responseBufPtr].offset, di
		call	SerialParseModemResponse
		clr	di 			; reset buf ptr
	;
	; To test if we need to stop parsing the response by checking
	; response buffer.
	;
		cmp	es:[responseBufHandle], NULL
		je	updatePtr
		
nextChar:
		inc	si			; advance src buffer ptr
		loop	scanLoop		; scan next char

updatePtr:
		mov	es:[responseBufPtr].offset, di
						; update for next check
done:
		.leave
		ret
SerialCheckModemStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialParseModemResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a modem response string

CALLED BY:	SerialCheckModemStatus
PASS:		es	= dgroup
		es:[responseBufPtr]	= fptr to 1 byte beyond last byte in
					response buffer
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	TermModemResponseType response =
		SerialParseModemResponseLow(response buffer size,
					    response buffer beginning);
	SerialHandleModemResponse(response);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialParseModemResponse	proc	near
		uses	ds, di, si, ax, cx
		.enter

		lds	di, es:[responseBufPtr]	; ds:di <- byte following
						; response string
		clr	cx			; ds:cx <- begin of response
						; string 
		call	SerialParseModemResponseLow
						; carry set if no match
						; carry clear:
						;   ds:si <- pos after match
						;   ax <- TermModemResponseType
		call	SerialHandleModemResponse
		.leave
		ret
SerialParseModemResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialParseModemResponseLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inner routine to parse a modem response string

CALLED BY:	SerialParseModemResponse
PASS:		ds:cx	= beginning of response string
		ds:di	= byte immediately following response string
RETURN:		carry clear if match:
			ds:si <- position in response string after match was
				made 
			ax    <- TermModemResponseType
	
		carry set if no match
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	(The code is originally from c1sParse.asm.)		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	8/25/94    	Initial version
	simon	7/ 2/95		Copied from c1sParse.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialParseModemResponseLow	proc	near
		uses	bx,cx,dx,di,bp,es
		.enter
	;
	; we want to check the response string against the strings in the
	; error table
	;
		mov	ax, di
		sub	ax, cx				; length of response
		mov	si, cx				; ds:si is response
	;
	; start looping...
	;
		mov	dx, si				; save beginning
		segmov	es, cs, bx			; where the strings are
		mov	bx, -2				; first elements of tbl
stringCheckLoop:
		inc	bx
		inc	bx				; next entry
	;
	; the response string must be at least as long as the expected string
	;
		mov	cx, cs:[errorStringSizes][bx]
		tst	cx
		jz	failedToMatchAllStrings		; no more strings
		cmp	cx, ax
		ja	stringCheckLoop
	;
	; now compare the strings
	;
		mov	si, dx				; ds:si is response
		mov	di, cs:[errorStringTable][bx]	; es:di is expected str
							;cx is bytes to compare
		call	GenerousStringCompare		; carry clear on match
		jc	stringCheckLoop

haveMatch::
		clc					; got match
done:
		mov	ax, cs:[errorStringValues][bx]

		.leave
		ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;; below the ret line ;;;;;;;;;;;;;;;;;;;;;;;;
failedToMatchAllStrings:
		mov	si, dx				; restore beginning
		stc					; no match
		jmp	done

responseOK		char	"OK"
responseCONNECT		char	"CONNECT"
responseERROR		char	"ERROR"
responseBUSY		char	"BUSY"
responseNOCARRIER	char	"NO CARRIER"
responseNOANSWER	char	"NO ANSWER"
responseNODIALTONE	char	"NO DIALTONE"
responseRING		char	"RING"
		
errorStringTable	nptr	\
	offset	responseOK,
	offset	responseCONNECT,
	offset	responseERROR,
	offset	responseBUSY,
	offset	responseNOCARRIER,
	offset	responseNOANSWER,
	offset	responseNODIALTONE,
	offset	responseRING,
	NULL_STRING

errorStringSizes	word	\
	size	responseOK,
	size	responseCONNECT,
	size	responseERROR,
	size	responseBUSY,
	size	responseNOCARRIER,
	size	responseNOANSWER,
	size	responseNODIALTONE,
	size	responseRING,
	0					; should never be used

errorStringValues	TermModemResponseType	\
	TMRT_OK,
	TMRT_CONNECT,
	TMRT_ERROR,
	TMRT_BUSY,
	TMRT_NOCARRIER,
	TMRT_NOANSWER,
	TMRT_NODIALTONE,
	TMRT_RING,
	TMRT_UNEXPECTED_RESPONSE
	

.assert (size errorStringTable) eq (size errorStringSizes)
.assert (size errorStringTable) eq (size errorStringValues)

SerialParseModemResponseLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerousStringCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for string equality, but gives a bit of leeway with it

CALLED BY:	SerialParseModemResponseLow
PASS:		ds:si modem response
		es:di expected response
		cx max bytes to compare (in es:di)
RETURN:		si, di, cx, updated much like cmpsb would do
		carry CLEAR on a match
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	(The code is originally from c1sParse.asm.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	6/27/94    	Initial version
	simon	7/ 2/95		Copied from c1sParse.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerousStringCompare	proc	near
		uses	ax
		.enter
		mov	ax, GENEROUS_STRING_TOLERANCE+1	; full tolerence
	;
	; try for a match
	;
tryForMatch:
		repe	cmpsb				; check as far as can
		clc					; assume match
		jnz	mismatch			; got full match

done:
		.leave
		ret
;;;;;;;;;;;;;;;;;;;;;;;; below the ret line ;;;;;;;;;;;;;;;;;;;
mismatch:
	;
	; darn, a mismatch
	; try again
	;
		dec	di				; recheck last byte
		inc	cx				; from expected answer
		dec	ax				; a bad one
		jnz	tryForMatch

		stc					; no match
		jmp	done

GenerousStringCompare	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialHandleModemResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a certain modem response

CALLED BY:	SerialParseModemResponse
PASS:		ax	= TermModemResponseType
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	switch (TermModemResponseType) {
		case	TMRT_UNEXPECTED_RESPONSE:
			return;
	
		case	TMRT_OK:
			break;
	
		case	TMRT_ERROR:
		case	TMRT_BUSY:
		case	TMRT_NOCARRIER:
		case	TMRT_NOANSWER:
		case	TMRT_NODIALTONE:
		case	TMRT_RING:
			DisplayErrorMessage;
			call MSG_SERIAL_CHECK_MODEM_STATUS_END;
	}
	VSem	responseReplySem;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialHandleModemResponse	proc	near
		uses	ax, bx, bp, ds
		.enter
EC <		Assert_dgroup	es					>

		CheckHack <(TMRT_ERROR gt TMRT_OK) and \
			   (TMRT_ERROR gt TMRT_CONNECT)>
	;
	; If the user has cancelled the connection, responseBufHandle should
	; have been nulled and shouldn't reach here.
	; 
EC <		Assert_ne	es:[responseType], TMRT_USER_CANCEL	>

		cmp	ax, TMRT_UNEXPECTED_RESPONSE
		je	done			; ignore unexpected response
						; also 
		mov	es:[responseType], ax	; assign response type
	;
	; All errors are indicated as TMRT_ERROR and larger
	; TermModemResponseType. So, we only check on those.
	;
		cmp	ax, TMRT_ERROR
		jae	connectError
	;
	; No Error. When we detect CONNECT, we know we are done with modem
	; response checking and we can release response buffer immediately.
	;
		cmp	ax, TMRT_OK
		je	vSem
cleanup:
	;
	; Release response buffer and then VSem the caller is waiting.
	;
		segmov	ds, es, ax		; ds <- dgroup
		mov	ax, MSG_SERIAL_CHECK_MODEM_STATUS_END
		CallSerialThread	
vSem:
		BitSet	es:[statusFlags], TSF_RECEIVED_MODEM_RESPONSE
	;
	; Need to unblock anyone?
	;
		BitTest	es:[statusFlags], TSF_WAIT_FOR_MODEM_RESPONSE
		jz	done
		BitClr	es:[statusFlags], TSF_WAIT_FOR_MODEM_RESPONSE
		call	SerialStopResponseTimer
		VSem	es, responseReplySem, TRASH_AX_BX
						; release waiter on
						; responseReplySem 
done:
		.leave
		ret

connectError:
		CheckHack	<FALSE	 eq	0>
		tst	es:[modemInitStart]
		jz	cleanup
		jmp	done
SerialHandleModemResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialStartResponseTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the response timer for modem

CALLED BY:	TermSendModemCommand
PASS:		es	= dgroup		
		ch	= timeout value:
			  if 0:	TERM_LONG_REPLY_TIMEOUT 
			  if 1: TERM_SHORT_REPLY_TIMEOUT
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Copied from Modem driver

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialStartResponseTimer	proc	near
		uses	ax, bx, cx, dx
		.enter
EC <		call	ECCheckRunBySerialThread			>
EC <		Assert_dgroup	es					>
EC <		Assert_inList	ch, <0, 1>				>
	;
	; Set up params to wait for modem response
	;
		BitSet	es:[statusFlags], TSF_WAIT_FOR_MODEM_RESPONSE
		BitClr	es:[statusFlags], TSF_RECEIVED_MODEM_RESPONSE
		mov	es:[responseType], TMRT_TIMEOUT
						; default return type
	;
	; Select timeout value
	;
		tst	ch
		jz	longReply
		mov	cx, TERM_SHORT_REPLY_TIMEOUT
		jmp	startTimer
longReply:
		mov	cx, TERM_LONG_REPLY_TIMEOUT
	;
	; Start the one shot response timer and store its handle 
	; and ID.  
	;
startTimer:
		mov	bx, ss:[TPD_threadHandle]
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	dx, MSG_SERIAL_MODEM_RESPONSE_TIMEOUT
		call	TimerStart
		
		mov	es:[termResponseTimer], bx
		mov	es:[termResponseTimerID], ax

		.leave
		ret
SerialStartResponseTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialStopResponseTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the response timer for modem

CALLED BY:	SerialCancelConnection, SerialHandleModemResponse
PASS:		es	= dgroup		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Copied from Modem driver

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialStopResponseTimer	proc	near
		uses	ax, bx
		.enter
EC <		Assert_dgroup	es					>
		clr	bx
		xchg	bx, es:[termResponseTimer]
		tst	bx
		jz	exit

		mov	ax, es:[termResponseTimerID]
		call	TimerStop
exit:
		.leave
		ret
SerialStopResponseTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialOKToBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lets us know that we may MF_CALL, and otherwise block
		on the process thread.

CALLED BY:	MSG_SERIAL_OK_TO_BLOCK
PASS:		*ds:si	= SerialReaderClass object
		ds:di	= SerialReaderClass instance data
		ds:bx	= SerialReaderClass object (same as *ds:si)
		es 	= segment of SerialReaderClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/24/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialOKToBlock	method dynamic SerialReaderClass, 
					MSG_SERIAL_OK_TO_BLOCK
	.enter
EC <		BitTest	ds:[statusFlags], TSF_SERIAL_MAY_BLOCK		>
EC <		WARNING_NZ	TERM_UNEXPECTED_SERIAL_BLOCKING_MODE	>
		BitSet	ds:[statusFlags], TSF_SERIAL_MAY_BLOCK
	.leave
	ret
SerialOKToBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialStopBlocking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fields a request from the process to stop performing
		 any blocking operations.  We will, and send
		a message back, saying that we have.

CALLED BY:	MSG_SERIAL_STOP_BLOCKING
PASS:		*ds:si	= SerialReaderClass object
		ds:di	= SerialReaderClass instance data
		ds:bx	= SerialReaderClass object (same as *ds:si)
		es 	= segment of SerialReaderClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/24/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialStopBlocking	method dynamic SerialReaderClass, 
					MSG_SERIAL_STOP_BLOCKING
	.enter

	;
	; Revoke our permission to block
	;
EC <		BitTest		ds:[statusFlags], TSF_SERIAL_MAY_BLOCK	>
EC <		WARNING_Z	TERM_UNEXPECTED_SERIAL_BLOCKING_MODE	>
		BitClr		ds:[statusFlags], TSF_SERIAL_MAY_BLOCK
	;
	; And tell process that it may start blocking.
	;
		mov	ax, MSG_TERM_SERIAL_NOT_BLOCKING
		mov	bx, handle 0
		mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
		call	ObjMessage
	.leave
	ret
SerialStopBlocking	endm

endif	; if _MODEM_STATUS

