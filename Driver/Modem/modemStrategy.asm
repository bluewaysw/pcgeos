COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		Modem Driver
FILE:		modemStrategy.asm

AUTHOR:		Jennifer Wu, Mar 14, 1995

ROUTINES:
	Name			Description
	----			-----------
	ModemStrategy
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/14/95		Initial revision

DESCRIPTION:
	Driver info and strategy routine for modem driver.

	$Id: modemStrategy.asm,v 1.1 97/04/18 11:47:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;			Driver Information
;---------------------------------------------------------------------------

ModemClassStructures	segment resource
	ModemProcessClass	mask CLASSF_NEVER_SAVED	
ModemClassStructures	ends

ResidentCode	segment resource

DriverTable	DriverExtendedInfoStruct <
		<ModemStrategy,	
		 mask DA_HAS_EXTENDED_INFO, 
		 DRIVER_TYPE_MODEM>,
		ModemExtendedInfo
		>	 	

ForceRef	DriverTable

ResidentCode ends

ModemExtendedInfo		segment lmem LMEM_TYPE_GENERAL

ModemExtendedInfoTable	DriverExtendedInfoTable <
			{},			
			length ModemDeviceNames,
			offset ModemDeviceNames,
			offset ModemDeviceInfoTable
			>

ModemDeviceNames	lptr.char	accura288,
					maxlite14_4,
					nokia
			lptr.char	0

accura288	chunk.char	'Accura 288', 0
maxlite14_4	chunk.char	'Macronix Maxlite 14.4', 0
nokia		chunk.char	'Nokia', 0

;
; A table associating a word of data with each modem.  We don't
; need such a things at this point so it's not initialized to 
; anything special.
;
ModemDeviceInfoTable	word	0			; generic modem

ModemExtendedInfo	ends

ForceRef	ModemExtendedInfoTable


;---------------------------------------------------------------------------
;		Dgroup
;---------------------------------------------------------------------------

idata	segment
	portNum		SerialPortNum		-1		
idata	ends


udata	segment	

	modemStatus	ModemStatus
	miscStatus	ModemMiscStatus	; more flags!
	modemThread	hptr		
	clientSem	hptr.Semaphore

	serialStrategy	fptr		

	dataNotify	StreamNotifier	; info for data notifications
	respNotify	StreamNotifier	; info for response notifications
	signalNotify	StreamNotifier	; info for modem signal notifications

	parser		nptr		; routine for parsing response

	responseSem	hptr.Semaphore	; to wait for modem response
	responseTimer	hptr
	responseTimerID	word
	responseBuf	char	RESPONSE_BUFFER_SIZE dup (?)
	responseSize	word

	result		ModemResultCode	; for client to check after awakening

	baudRate	word		; store the baud rate for PPP query

	escapeSecondCmd	word		; offset of command to send after
					; escape sequence.
	escapeSecondCmdLen byte		; length of said command
	escapeAttempts	byte		; number of type remaining to retry
					; escape attempt.

	pendingMsg	word		; If a client is blocked waiting for
					; a modem response, this will contain
					; the MSG_MODEM_.. msg number sent
					; to the modem thread.  Used for
					; ABORT_DIAL mechanism.

	abortSem	hptr.Semaphore	; used to synchronize client thread
					; with thread calling _ABORT_DIAL.
ifdef HANGUP_LOG
	logFile		hptr		; Handle to open log file
endif

udata	ends

;---------------------------------------------------------------------------
;		Strategy routine 
;---------------------------------------------------------------------------

ResidentCode 	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all modem driver calls.

CALLED BY:	GLOBAL

PASS:		di	= ModemFunction
		other parameters depend on ModemFunction

RETURN:		depends on ModemFunction

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:  

	Set ES to dgroup before calling the appropriate routine.  
	None of the ModemFunctions uses ES as a parameter.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/14/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemStrategy	proc	far
		uses	di, es
		.enter

		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx

		mov	bx, handle dgroup
		call	MemDerefES

		shl	di, 1			; di = index
		cmp	di, size driverProcTable
		jb	doIt

		mov	ax, MRC_NOT_SUPPORTED
		stc
		jmp	exit
doIt:
		movdw	bxax, cs:driverProcTable[di]
		call	ProcCallFixedOrMovable
exit:		
		.leave
		ret
ModemStrategy	endp

driverProcTable		fptr.far	\
	ModemInit,			; DR_INIT
	ModemExit,			; DR_EXIT
	ModemDoNothing,			; DR_SUSPEND
	ModemDoNothing,			; DR_UNSUSPEND
	ModemTestDevice,		; DRE_TEST_DEVICE
	ModemSetDevice,			; DRE_SET_DEVICE
	ModemOpen,			; DR_MODEM_OPEN
	ModemClose,			; DR_MODEM_CLOSE	
	ModemSetNotify,			; DR_MODEM_SET_NOTIFY
	ModemDial,			; DR_MODEM_DIAL
	ModemAnswerCall,		; DR_MODEM_ANSWER_CALL
	ModemHangup,			; DR_MODEM_HANGUP
	ModemReset,			; DR_MODEM_RESET
	ModemFactoryReset,		; DR_MODEM_FACTORY_RESET
	ModemInitModem,			; DR_MODEM_INIT_MODEM
	ModemAutoAnswer,		; DR_MODEM_AUTO_ANSWER
	ModemGrabSerialPort,		; DR_MODEM_GRAB_SERIAL_PORT
	ModemGetBaudRate,		; DR_MODEM_GET_BAUD_RATE
	ModemCheckDialTone,		; DR_MODEM_CHECK_DIAL_TONE
	ModemAbortDial			; DR_MODEM_ABORT_DIAL

ResidentCode	ends

CommonCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemGetBaudRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	ModemStrategy

PASS:		nothing

RETURN:		ax = baud rate

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	mzhu	12/2/98			initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemGetBaudRate	proc	far
		.enter

		mov	ax, es:[baudRate]		

		.leave
		ret
ModemGetBaudRate	endp

CommonCode	ends
