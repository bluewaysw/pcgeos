COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		Modem Driver
FILE:		modemSend.asm

AUTHOR:		Jennifer Wu, Mar 16, 1995

ROUTINES:
	Name			Description
	----			-----------
ModemFunctions:
	ModemDial
	ModemAnswerCall
	ModemHangup
	ModemReset
	ModemFactoryReset
	ModemInitModem
	ModemAutoAnswer

Methods:
	ModemDoDial
	ModemDoAnswerCall
	ModemDoHangup
	ModemDoReset
	ModemDoFactoryReset
	ModemDoInitModem
	ModemDoAutoAnswer	

Subroutines:
	ModemDoCommand
	ModemCheckConnect
	ModemSendError
	ModemSendByteAsAscii
	ModemSwitchToCommandMode
	ModemSendEscapeSecondCmd

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/16/95		Initial revision

DESCRIPTION:
	Code for sending commands to the modem.

	$Id: modemSend.asm,v 1.1 97/04/18 11:47:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource

;---------------------------------------------------------------------------
;			Modem Command Strings
;---------------------------------------------------------------------------

cmdATPrefix		char	"AT"
cmdEscapeSequence	char	"+++"
cmdDialPrefix		char	"ATD";  "ATW2X1D"
cmdCheckDialTone	char	"ATDW", C_CR
cmdAnswerCall		char	"ATA", C_CR
cmdHangup		char	"ATH0", C_CR
cmdReset		char	"ATZ", C_CR
cmdFactoryReset		char	"AT&F", C_CR
cmdAutoAnswerPrefix	char	"ATS0="

ifdef HANGUP_LOG
cmdDialStatus		char	"AT&V1", C_CR
logFileName		char	"MODEM.LOG", 0
endif

;---------------------------------------------------------------------------
;			ModemFunctions
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the modem dial the given string, which may contain
		dial modifiers.

CALLED BY:	ModemStrategy

PASS:		bx	= port number
		cx:dx	= dial string (not null terminated)
		ax	= size of dial string
		es	= dgroup

RETURN:		ax	= ModemResultCode
		carry clear if connection established

DESTROYED:	di (preserved by ModemStrategy)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDial	proc	far
		push	bp
		mov_tr	bp, ax				; bp = size
		mov	ax, MSG_MODEM_DO_DIAL
		call	ModemDoCommand			
		pop	bp
		ret
ModemDial	endp

ifdef HANGUP_LOG

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDialStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the modem report its last dial status so that we can
		log it.

CALLED BY:	ModemClose

PASS:		bx	= port number
		es	= dgroup

RETURN:		nothing
DESTROYED:	di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/12/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDialStatus	proc	far
		push	ax
		mov	ax, MSG_MODEM_DO_DIAL_STATUS
		call	ModemDoCommand
		pop	ax
		ret
ModemDialStatus	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemCheckDialTone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check dial tone.

CALLED BY:	ModemStrategy

PASS:		bx	= port number
		es	= dgroup
		cx	= timeout in ticks

RETURN:		ax	= ModemResultCode
		carry clear if connection established

DESTROYED:	di (preserved by ModemStrategy)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	brianc	8/19/99			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemCheckDialTone	proc	far
		mov	ax, MSG_MODEM_DO_CHECK_DIAL_TONE
		call	ModemDoCommand			
		ret
ModemCheckDialTone	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemAnswerCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the modem answer an incoming call.

CALLED BY:	ModemStrategy

PASS:		bx	= port number
		es	= dgroup

RETURN:		ax	= ModemResultCode
		carry clear if connection established

DESTROYED:	di (preserved by ModemStrategy)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemAnswerCall	proc	far
		mov	ax, MSG_MODEM_DO_ANSWER_CALL
		call	ModemDoCommand
		ret
ModemAnswerCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemHangup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the modem terminate the current connection.

CALLED BY:	ModemStrategy

PASS:		bx 	= port number
		es	= dgroup

RETURN:		ax	= ModemResultCode
		carry set if error

DESTROYED:	di (preserved by ModemStrategy)

NOTES:
		Wait a few seconds after sending hangup and getting back an OK
		to allow the modem time to terminate the connection.  Prevents
		problems when the user tries to re-establish a new connection 
		immediately after hanging up.  Sigh...dumb user. :-b

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemHangup	proc	far
		mov	ax, MSG_MODEM_DO_HANGUP
		call	ModemDoCommand
	;
	; Wait before returning control to user.  See header notes.
	;
		pushf
		xchg	ax, di
		mov	ax, ESC_GUARD_TIME		; should be enough...
		call	TimerSleep
		xchg	ax, di
		popf

		ret
ModemHangup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the modem, terminating any existing connection.

CALLED BY:	ModemStrategy

PASS:		bx	= port number
		es	= dgroup

RETURN:		ax	= ModemResultCode
		cary set if error		

DESTROYED:	di (preserved by ModemStrategy)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemReset	proc	far
		mov	ax, MSG_MODEM_DO_RESET
		call	ModemDoCommand
		ret
ModemReset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemFactoryReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the modem to its factory configuration.

CALLED BY:	ModemStrategy

PASS:		bx	= port number
		es	= dgroup

RETURN:		ax	= ModemResultCode
		carry set if error

DESTROYED:	di (preserved by ModemStrategy)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/25/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemFactoryReset	proc	far
		mov	ax, MSG_MODEM_DO_FACTORY_RESET
		call	ModemDoCommand
		ret
ModemFactoryReset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemInitModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the modem's user profile with the given 
		initialization string.

CALLED BY:	ModemStrategy

PASS:		bx	= port number
		cx:dx	= initialization string (not null-terminated)
		ax	= size of initialization string
		es	= dgroup

RETURN:		ax	= ModemResultCode
		carry set if error

DESTROYED:	di (preserved by ModemStrategy)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemInitModem	proc	far

		push	bp
		mov_tr	bp, ax				; bp = size
		mov	ax, MSG_MODEM_DO_INIT_MODEM
		call	ModemDoCommand			; ax = ModemResultCode
		pop	bp
		ret
ModemInitModem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemAutoAnswer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the number of rings before the modem answers an
		incoming call.

CALLED BY:	ModemStrategy

PASS:		bx	= port number
		al	= number of rings (0 disables auto answer function)
		es	= dgroup

RETURN:		ax	= ModemResultCode
		carry set if error

DESTROYED:	di (preserved by ModemStrategy)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemAutoAnswer	proc	far
		push	cx
		mov_tr	cx, ax			; cl = number of rings
		mov	ax, MSG_MODEM_DO_AUTO_ANSWER
		call	ModemDoCommand
		pop	cx
		ret
ModemAutoAnswer	endp

;---------------------------------------------------------------------------
;			Methods
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the dial command to the modem and set the driver up
		to interpret the response.

CALLED BY:	MSG_MODEM_DO_DIAL
PASS: 		cx:dx	= dial string (not null terminated)
			    (FXIP: String must not be in movable code resource)
		bp	= size of string

RETURN:		nothing		
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		EC: verify in command mode
		send ATD
		send dial string
		send <CR>
		set parse routine
		start response timer
		if error sending command, set result to MRC_ERROR and 
			V the client, clearing the flag

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoDial	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_DIAL

		mov	bx, handle dgroup
		call	MemDerefES

EC <		call	ECCheckMode				>	
EC <		tst	bp					>
EC <		ERROR_E ZERO_LENGTH_MODEM_DIAL_STRING		>

	; Synchronize with possible aborting thread.  If we are supposed
	; to be "disconnecting", don't bother dialing.  This catches a case
	; where the abort call comes between the DR_MODEM_DIAL command and
	; this message getting processed from the queue.
	;
		mov	bx, es:[abortSem]
		call	ThreadPSem
		test	es:[modemStatus], mask MS_ABORT_DIAL
		call	ThreadVSem			; flags preserved
		jnz	error

	;
	; Send "ATD".
	;
		push	cx
		mov	bx, es:[portNum]
		segmov	ds, cs, cx
		mov	si, offset cmdDialPrefix	; ds:si = "ATD"
		mov	cx, size cmdDialPrefix

FXIP <		call	SysCopyToStackDSSI			>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

FXIP <		call	SysRemoveFromStack			>

		pop	ds				; ds:dx = dial string

		cmp	cx, size cmdDialPrefix
		jne	error
	;
	; Send the dial string followed by a <CR>.
	;
		mov	si, dx				; ds:si = dial string
		mov	cx, bp				; cx = dial string size
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]
		
		cmp	cx, bp
		jne	error

		mov	cl, C_CR
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE_BYTE
		call	es:[serialStrategy]
		jc	error
	;
	; Set the parse routine for the response and start the 
	; response timer.
	;
		mov	es:[parser], offset ModemParseDialResponse
		mov	cx, LONG_RESPONSE_TIMEOUT
		call	ModemStartResponseTimer
exit:
		ret
error:
		call	ModemSendError
		jmp	exit

ModemDoDial	endm

ifdef HANGUP_LOG

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoDialStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the last dial status report command to the modem, open
		the log file, and set the driver up to receive the results.

CALLED BY:	MSG_MODEM_DO_DIAL_STATUS

PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		Open the log file
		Write the current date and time
		Send the dial status string
		Setup our special parser and a short timeout.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/12/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoDialStatus	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_DIAL_STATUS
		.enter
		mov	bx, handle dgroup
		call	MemDerefES
	;
	; Open the log file for append.
	;
		call	FilePushDir
		mov	ax,  SP_TOP
		call	FileSetStandardPath
	LONG	jc	errorPopDir
		push	ds
		segmov	ds, cs, ax
		mov	ax, (((FILE_CREATE_NO_TRUNCATE shl offset FCF_MODE) \
			or mask FCF_NATIVE) shl 8) or FILE_ACCESS_W \
			or FILE_DENY_W or (FA_WRITE_ONLY shl offset FAF_MODE)
		mov	dx, offset logFileName
		clr	cx
		call	FileCreate
		pop	ds
		call	FilePopDir
	LONG	jc	done
		mov	es:[logFile], ax
		mov	bx, ax
		mov	al, FILE_POS_END
		clrdw	cxdx
		call	FilePos
	;
	; Write the current date and time.
	;
		mov	di, offset es:[responseBuf]	; es:di = buffer
		mov	al, '('
		stosb
		call	TimerGetDateAndTime
		mov	si, DTF_ZERO_PADDED_SHORT
		push	cx
		call	LocalFormatDateTime
		add	di, cx
		mov	{byte}es:[di], ' '
		inc	di
		pop	cx
		mov	si, DTF_HMS_24HOUR
		call	LocalFormatDateTime
		add	di, cx
		mov	al, ')'
		stosb
		mov	al, C_CR
		stosb
		mov	al, C_LF
		stosb
		push	ds
		segmov	ds, es, ax
		mov	al, FILE_NO_ERRORS
		mov	cx, di
		mov	dx, offset es:[responseBuf]	; ds:dx = response
		sub	cx, dx
		mov	bx, es:[logFile]
		call	FileWrite
		pop	ds
	;
	; Send the dial status string.
	;
		push	ds, si
		segmov	ds, cs, si
		mov	bx, es:[portNum]
		mov	si, offset cmdDialStatus
		mov	cx, size cmdDialStatus

FXIP <		call	SysCopyToStackDSSI				>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

FXIP <		call	SysRemoveFromStack				>

		pop	ds, si
		
		cmp	cx, size cmdDialStatus
		jne	errorClose
	;
	; Setup our special parser and a short timeout.
	;
		mov	es:[parser], offset ModemParseDialStatusResponse
		mov	cx, SHORT_RESPONSE_TIMEOUT
		call	ModemStartResponseTimer
done:
		.leave
		ret
errorPopDir:
		call	FilePopDir
		jmp	done
errorClose:
		mov	ax, es:[logFile]
		call	FileClose
		jmp	done
ModemDoDialStatus	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoCheckDialTone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the command to the modem and set the driver up
		to interpret the response.

CALLED BY:	MSG_MODEM_DO_CHECK_DIAL_TONE
PASS: 		cx	= timeout in ticks

RETURN:		nothing		
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		EC: verify in command mode
		send ATDW
		send <CR>
		set parse routine
		start response timer
		if error sending command, set result to MRC_ERROR and 
			V the client, clearing the flag

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/19/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoCheckDialTone	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_CHECK_DIAL_TONE

		mov	bx, handle dgroup
		call	MemDerefES

EC <		call	ECCheckMode				>	
EC <		tst	bp					>
EC <		ERROR_E ZERO_LENGTH_MODEM_DIAL_STRING		>

	;
	; Send "ATD".
	;
		push	cx				; save timeout
		mov	bx, es:[portNum]
		segmov	ds, cs, cx
		mov	si, offset cmdCheckDialTone	; ds:si = "ATDW<CR>"
		mov	cx, size cmdCheckDialTone

FXIP <		call	SysCopyToStackDSSI			>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

FXIP <		call	SysRemoveFromStack			>

		cmp	cx, size cmdCheckDialTone
		pop	cx				; cx = timeout
		jne	error
	;
	; Set the parse routine for the response and start the 
	; response timer.
	;
		mov	es:[parser], offset ModemParseDialResponse
		call	ModemStartResponseTimer
exit:
		ret
error:
		call	ModemSendError
		jmp	exit

ModemDoCheckDialTone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoAnswerCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the command to the modem to make it answer an incoming
		call and set up the driver to interpret the response.	

CALLED BY:	MSG_MODEM_DO_ANSWER_CALL
PASS: 		nothing
RETURN:		nothing		
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		EC: verify in command mode
		send ATA<CR>
		set parse routine
		start response timer
		if error sending command, set result to MRC_ERROR and
			V the client, clearing the flag

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoAnswerCall	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_ANSWER_CALL

		mov	bx, handle dgroup
		call	MemDerefES

EC <		call	ECCheckMode				>
	;
	; Send "ATA"<CR>.
	;
		mov	bx, es:[portNum]
		segmov	ds, cs, si
		mov	si, offset cmdAnswerCall
		mov	cx, size cmdAnswerCall

FXIP <		call	SysCopyToStackDSSI			>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

FXIP <		call	SysRemoveFromStack			>

		cmp	cx, size cmdAnswerCall
		jne	error
	;
	; Set parse routine and start response timer.
	;
		mov	es:[parser], offset ModemParseAnswerCallResponse
		mov	cx, LONG_RESPONSE_TIMEOUT
		call	ModemStartResponseTimer
exit: 
		ret
error:
		call	ModemSendError
		jmp	exit

ModemDoAnswerCall	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoHangup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the command the modem to hangup any existing connection.

CALLED BY:	MSG_MODEM_DO_HANGUP
PASS: 		nothing
RETURN:		nothing		
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		Sleep for the escape guard time
		Send +++
		Sleep for the escape guard time
		Send ATH0<CR>
		Set parser
		Start response timer
		if error, set result as MRC_ERROR and wake up client

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoHangup	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_HANGUP
	;
	; Send escape sequence.  If in data mode, it will switch us to
	; command mode.  Else, it has no effect.
	;
		mov	bx, handle dgroup
		call	MemDerefES
	;
	; During hangup, we need a little more time to pause to switch to
	; command mode. Otherwise, some modems cannot change to command
	; mode. 
	;
		mov	ax, EXTRA_HANGUP_ESC_GUARD_TIME
		call	TimerSleep		; ax destroyed
		
		mov	dl, es:[modemStatus]	; save this momentarily

		mov	bx, es:[portNum]
		call	ModemSwitchToCommandMode
		jc	error

	;
	; Set up the second part of the command, the actual hangup
	; command.  This will be sent once the "+++" has been
	; acknowledged.
	;
		mov	es:[escapeSecondCmd], offset cmdHangup
		mov	es:[escapeSecondCmdLen], size cmdHangup

	; Check to see if we were in command mode before calling
	; ModemSwitchToCommandMode.  If so, just send off the hangup command
	; straight away.
	;
		test	dl, mask MS_COMMAND_MODE
		jnz	sendSecondCommandNow

	; Otherwise, finish setting up the escape attempt stuff..
	;
		mov	es:[escapeAttempts], 2
		mov	es:[parser], offset ModemParseEscapeResponse

	;
	; Set up the timer appropriately.
	;
		mov	cx, ESCAPE_RESPONSE_TIMEOUT
		call	ModemStartResponseTimer
exit:
		ret
error:
		call	ModemSendError
		jmp	exit

sendSecondCommandNow:
		call	ModemSendEscapeSecondCmd
		jmp	exit

ModemDoHangup	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the modem the command to reset the user profile,
		terminating any existing connections.

CALLED BY:	MSG_MODEM_DO_RESET

PASS: 		nothing
RETURN:		nothing		
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		switch to command mode if needed
		Send ATZ<CR> 
		set parser
		start response timer
		if error, handle it

NOTES:
	If previous command was "ATD", the first <CR> will send the 
	command.  The second <CR> will cancel the dial command.  Then
	the ATZ will reset the modem.  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/17/95   	Initial version
	dhunter	5/31/2000	Do something special if in data mode

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoReset	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_RESET
	;
	; If in data mode, do something special.
	;
		mov	bx, handle dgroup
		call	MemDerefES

		mov	bx, es:[portNum]
		test	es:[modemStatus], mask MS_COMMAND_MODE
		jz	dataReset			; branch if in data mode
	;
	; Send <CR>, pause for a bit, repeat, then send "ATZ"<CR>.
	;
		mov	dx, NUM_CR_FOR_RESET
crloop:
		mov	cl, C_CR
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE_BYTE
		call	es:[serialStrategy]
		jc	error

		mov	ax, 10
		call	TimerSleep
		
		dec	dx
		jnz	crloop
	;
	; Pause again, then send ATZ<CR>.  Must pause or else the
	; ATZ may be appended to a previous unfinished command 
	; on some modems.  
	;
		mov	ax, 10
		call	TimerSleep

		segmov	ds, cs, si
		mov	si, offset cmdReset		
		mov	cx, size cmdReset		

FXIP <		call	SysCopyToStackDSSI			>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

FXIP <		call	SysRemoveFromStack			>

		cmp	cx, size cmdReset
		jne	error
	;
	; Set parse routine and start response timer.
	;
		mov	es:[parser], offset ModemParseBasicResponse
		mov	cx, SHORT_RESPONSE_TIMEOUT
		call	ModemStartResponseTimer
exit:
		.leave
		ret
error:
		call	ModemSendError
		jmp	exit

dataReset:
	; The idea is to send the escape sequence to switch us to
	; command mode, then wait for the OK before sending the
	; reset command.  Carry out the first step.
	;
		call	ModemSwitchToCommandMode
		jc	error
	;
	; Set up the second part of the command, the actual reset
	; command.  This will be sent once the "+++" has been
	; acknowledged.
	;
		mov	es:[escapeSecondCmd], offset cmdReset
		mov	es:[escapeSecondCmdLen], size cmdReset
		mov	es:[escapeAttempts], 1
		mov	es:[parser], offset ModemParseEscapeResponse
	;
	; Set up the timer appropriately.  Use the shorter timeout
	; if MSS_MODE_UNCERTAIN is set, indicating we're pretty sure
	; the modem was already in command mode.
	;
		mov	cx, ESCAPE_RESPONSE_TIMEOUT
		test	es:[miscStatus], mask MSS_MODE_UNCERTAIN
		jz	certain
		mov	cx, RESET_ESCAPE_RESPONSE_TIMEOUT
certain:
		call	ModemStartResponseTimer
		jmp	exit

ModemDoReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoFactoryReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset modem to its factory configuration.

CALLED BY:	MSG_MODEM_DO_FACTORY_RESET
PASS: 		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		EC: verify mode
		send AT&F
		set parser
		start response timer
		if error, handle it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoFactoryReset	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_FACTORY_RESET

		mov	bx, handle dgroup
		call	MemDerefES

EC <		call	ECCheckMode				>
	;
	; Send AT&F<CR>.
	;
		mov	bx, es:[portNum]
		segmov	ds, cs, cx
		mov	si, offset cmdFactoryReset
		mov	cx, size cmdFactoryReset

FXIP <		call	SysCopyToStackDSSI			>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]
		
FXIP <		call	SysRemoveFromStack			>

		cmp	cx, size cmdFactoryReset
		jne	error
	;
	; Set the parse routine and start the response timer.
	;
		mov	es:[parser], offset ModemParseBasicResponse
		mov	cx, SHORT_RESPONSE_TIMEOUT
		call	ModemStartResponseTimer
exit:
		ret
error:
		call	ModemSendError
		jmp	exit

ModemDoFactoryReset	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoInitModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the initialization string to the modem.  String should
		begin with an AT, but AT will be prepended if it does not.

CALLED BY:	MSG_MODEM_DO_INIT_MODEM
PASS:		cx:dx	= initialization string (not null terminated)
			    (FXIP: String must not be in movable code resource)
		bp	= size of string

RETURN:		nothing 
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/17/95   	Initial version
	jwu	2/27/96		Changed to prepend AT if needed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoInitModem	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_INIT_MODEM

		mov	bx, handle dgroup
		call	MemDerefES

EC <		call	ECCheckMode				>
	;
	; Check init string for "AT".  Checking for an "A" at the start 
	; is sufficient because an "A" should not be in the init string.
	;
		mov	bx, es:[portNum]
		movdw	dssi, cxdx			; ds:si = init string

		mov	al, ds:[si]
		cmp	al, 'a'
		je	sendString
		cmp	al, 'A'
		je	sendString
	;
	; Send "AT" to modem.
	;
		push	ds, si
		segmov	ds, cs, si
		mov	si, offset cmdATPrefix
		mov	cx, size cmdATPrefix

FXIP <		call	SysCopyToStackDSSI				>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

FXIP <		call	SysRemoveFromStack				>

		pop	ds, si
		
		cmp	cx, size cmdATPrefix
		jne	error
sendString:
	;
	; Send the init string followed by a <CR>.
	;
		mov	cx, bp				; cx = init string size
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

		cmp	cx, bp
		jne	error

		mov	cl, C_CR
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE_BYTE
		call	es:[serialStrategy]
		jc	error
	;
	; Set the parse routine and start the response timer.
	;
		mov	es:[parser], offset ModemParseBasicResponse
		mov	cx, SHORT_RESPONSE_TIMEOUT
		call	ModemStartResponseTimer
exit:
		ret
error:
		call	ModemSendError
		jmp	exit

ModemDoInitModem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoAutoAnswer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the modem the command to set the number of rings
		before modem answers an incoming call.

CALLED BY:	MSG_MODEM_DO_AUTO_ANSWER
PASS: 		cl	= number of rings (0 disables auto answering)

RETURN:		nothing		
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		EC : verify mode
		send ATSO=
		convert number to ascii string
		send it
		send <CR>
		set parser
		start response timer
		if error, handle it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoAutoAnswer	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_AUTO_ANSWER

		mov	bx, handle dgroup
		call	MemDerefES

EC <		call	ECCheckMode				>
	;
	; Send "ATSO="
	;
		push	cx
		mov	bx, es:[portNum]
		segmov	ds, cs, si
		mov	si, offset cmdAutoAnswerPrefix
		mov	cx, size cmdAutoAnswerPrefix

FXIP <		call	SysCopyToStackDSSI			>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

FXIP <		call	SysRemoveFromStack			>

		pop	ax				; al = # of rings

		cmp	cx, size cmdAutoAnswerPrefix
		jne	error
	;
	; Convert number of rings to decimal number in ascii and send it
	; followed by a <CR>.
	;
		call	ModemSendByteAsAscii
		jc	error

		mov	cl, C_CR
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE_BYTE
		call	es:[serialStrategy]
		jc	error
	;
	; Set parser and start response timer.
	;
		mov	es:[parser], offset ModemParseBasicResponse
		mov	cx, SHORT_RESPONSE_TIMEOUT
		call	ModemStartResponseTimer
exit:
		ret
error:
		call	ModemSendError
		jmp	exit

ModemDoAutoAnswer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoAbortDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the abort dial function.  Essentially just sends
		a space to the modem which will cause the ATDxxx command
		to abort (with OK or NO CARRIER).

CALLED BY:	MSG_MODEM_DO_ABORT_DIAL

PASS:		ax	= message #

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/09/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoAbortDial	method dynamic ModemProcessClass, 
					MSG_MODEM_DO_ABORT_DIAL

		mov	bx, handle dgroup
		call	MemDerefES

		mov	bx, es:[abortSem]
		call	ThreadPSem

	; Don't do if we are not in command mode and someone hasn't
	; requested an abort.  (safety check).
	;
		test	es:[modemStatus], mask MS_COMMAND_MODE
		jz	done
		test	es:[modemStatus], mask MS_ABORT_DIAL
		jz	done

	; Send some char.. a space will do.  Don't use a CR because
	; that can cause other problems!.
	;
		mov	cl, C_SPACE
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE_BYTE
		mov	bx, es:[portNum]
		call	es:[serialStrategy]

done:
		mov	bx, es:[abortSem]
		call	ThreadVSem
		ret
ModemDoAbortDial	endm


;---------------------------------------------------------------------------
;			Subroutines
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemDoCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the modem driver's thread send the modem a 
		command and make the client wait for the response.

CALLED BY:	ModemDial
		ModemAnswerCall
		ModemHangup
		ModemReset
		ModemFactoryReset
		ModemInitModem
		ModemAutoAnswer

PASS:		bx	= port number
		ax	= MSG_MODEM_DO_*
		cx, dx, bp  = parameters for message, if any
		es	= dgroup

RETURN:		ax	= ModemResultCode
		if attempting to make a connection, 
			carry set if connect attempt unsucessful
		else, carry set if error

DESTROYED:	di  (allowed by caller)

PSEUDO CODE/STRATEGY:
		EC:  die if current thread is modem driver's thread
		EC:  die if there is another client blocked 
		EC:  warning if modem driver is in data mode, unless command
			is to hangup
		check if modem is busy, return error if so
		set up modem driver if not already set up
		set flag indicating that there is a client blocked
		queue message for modem driver's thread
		Psem

		get result
		if not dialing or answering a call, 
			and response is error, set carry
		else if response is connect
			clear carry and enter data mode

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemDoCommand	proc	near
		uses	bx
		.enter

EC <		call	ECCheckCallerThread				>
EC <		call	ECCheckClientStatus				>

	;
	; Synchronize with thread that might be calling ABORT_DIAL.  We
	; want the pendingMsg to accurately reflect that the message is
	; being handled by the modem thread or is at least on its queue.
	;
		mov	di, ax				; save msg! P,V clr ax
		mov	bx, es:[abortSem]
		call	ThreadPSem

	; If ABORT_DIAL is set and we are about to do a dial, skip the
	; dial command and just return DIAL_ABORTED to the client.
	;
		test	es:[modemStatus], mask MS_ABORT_DIAL
		jz	savePend

		cmp	di, MSG_MODEM_DO_DIAL
		jne	savePend

		BitClr	es:[modemStatus], MS_ABORT_DIAL
		mov	ax, MRC_DIAL_ABORTED
		stc
		jmp	exit

savePend:
		mov	es:[pendingMsg], di

	;
	; Set the flag now so that the modem driver's thread will know 
	; it has to V the semaphore in case it gets there before we
	; do the PSem here.  
	;
		BitSet	es:[modemStatus], MS_CLIENT_BLOCKED
				
		mov	ax, di
		mov	bx, es:[modemThread]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		mov_tr	di, ax				; di = msg again

		mov	bx, es:[abortSem]
		call	ThreadVSem
		mov	bx, es:[responseSem]
		call	ThreadPSem

		mov	bx, es:[abortSem]
		call	ThreadPSem
		mov	es:[pendingMsg], 0
	;
	; Get the result and reset it.
	;
		clr	ax
		xchg	ax, es:[result]
EC <		Assert	etype, ax, ModemResultCode			>
	;
	; If connecting, check connect result.  Else set carry if 
	; response is not OK.
	;
		CheckHack <MSG_MODEM_DO_DIAL+1 eq MSG_MODEM_DO_ANSWER_CALL>
		cmp	di, MSG_MODEM_DO_ANSWER_CALL
		ja	checkResult			
		
		call	ModemCheckConnect		

		pushf
		test	es:[modemStatus], mask MS_ABORT_DIAL
		jnz	checkAbortDialResult
		popf

		jmp	exit
checkResult:
		cmp	ax, MRC_OK
		je	exit
		stc
exit:
		push	ax
		mov	bx, es:[abortSem]		; preserves flags
		call	ThreadVSem
		pop	ax
		.leave
		ret

checkAbortDialResult:
		BitClr	es:[modemStatus], MS_ABORT_DIAL
		popf				; from ModemCheckConnect
		mov	ax, MRC_DIAL_ABORTED
		jc	exit			; no connect, return _ABORTED

	; OK, at this point we have a connection.  We need to force a
	; hangup now while still making the client wait.
	; Reset the abort dial bit so that any callers of ABORT_DIAL
	; will do nothing.
	;
		ornf	es:[modemStatus], mask MS_ABORT_DIAL or \
					  mask MS_CLIENT_BLOCKED
		mov	ax, MSG_MODEM_DO_HANGUP
		mov	bx, es:[modemThread]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		mov	bx, es:[abortSem]		; don't block with
		call	ThreadVSem			; abortSem held!
		mov	bx, es:[responseSem]
		call	ThreadPSem			; block!
		mov	bx, es:[abortSem]
		call	ThreadPSem
		BitClr	es:[modemStatus], MS_ABORT_DIAL
		mov	ax, MRC_DIAL_ABORTED
		stc
		jmp	exit
		
ModemDoCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemCheckConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the result is some form of CONNECT.  If connected,
		set mode to data mode.

CALLED BY:	ModemDoCommand

PASS:		ax	= ModemResultCode

RETURN:		carry clear if result indicates CONNECT

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if MRC_CONNECT <= ax < MRC_BLACKLISTED
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemCheckConnect	proc	near
		cmp	ax, MRC_CONNECT
		jb	exit					; carry set

		cmp	ax, MRC_BLACKLISTED
		cmc			; sets carry if blacklisted or delayed
		jc	exit					

		BitClr	es:[modemStatus], MS_COMMAND_MODE	; clears carry
		BitClr	es:[miscStatus], MSS_MODE_UNCERTAIN
exit:
		ret
ModemCheckConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemSendEscapeSecondCmd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempts to send the escape second command.
		Can be called even if escapeSecondCmd is null.
		Nothing will happen in that case.

CALLED BY:	ModemParseEscapeResponse
		ModemResponseTimeout

PASS:		es	= dgroup

RETURN:		carry clear if response sent ok.
		carry set if no response to be sent (ax preserved)
		carry set if sent failed (ax = MRC_ERROR)

DESTROYED:	nothing

SIDE EFFECTS:	escapeSecondCmd, escapeSecondCmdLen, and escapeAttempts
		are all cleared.
		Response timer is started if command successfully sent.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/23/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemSendEscapeSecondCmd	proc	near
		uses	bx,cx,dx,si,di,ds
		.enter

		tst	es:[escapeSecondCmd]
		stc
		jz	done

	;
	; If we have a second command to send, load it up.
	;
		clr	es:[escapeAttempts]
		mov	si, es:[escapeSecondCmd]
		clr	cx
		mov	cl, es:[escapeSecondCmdLen]

		push	ax

	;
	; We also want to pause a little longer before sending second
	; command.
	;
		mov	ax, EXTRA_HANGUP_ESC_GUARD_TIME
		call	TimerSleep		; ax destroyed

	;
	; Write that second command out to the modem.
	;
		segmov	ds, cs, ax

FXIP <		call	SysCopyToStackDSSI				>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		mov	bx, es:[portNum]
		call	es:[serialStrategy]

FXIP <		call	SysRemoveFromStack				>

		clr	ax
		mov	es:[escapeSecondCmd], ax
		xchg	es:[escapeSecondCmdLen], al
		cmp	cx, ax
		pop	ax
		jne	sendError

	; Add a little more time here.  This modem can be really slow
	; responding to the hangup command and it is cleaner to actually
	; wait for the OK before closing the serial port.
	;
		mov	es:[parser], offset ModemParseBasicResponse
		mov	cx, SHORT_RESPONSE_TIMEOUT + 5*ONE_SECOND
		call	ModemStartResponseTimer
		
		clr	cx

		clc
done:
		.leave
		ret

sendError:
EC <		WARNING MODEM_DRIVER_UNABLE_TO_SEND_COMMAND		>
		mov	ax, MRC_ERROR
		stc
		jmp	done
ModemSendEscapeSecondCmd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemSendError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up some stuff if unable to send the command to the
		modem.  Reset parse routine.

CALLED BY:	ModemDoDial
		ModemDoAnswerCall
		ModemDoHangup
		ModemDoReset
		ModemDoInitModem
		ModemDoAutoAnswer

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	bx, ax  (allowed by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/17/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemSendError	proc	near
	;
	; Set result to MRC_ERROR.  Reset parse routine.
	; Clear flag and V semaphore to wake up client.
	;
EC <		WARNING MODEM_DRIVER_UNABLE_TO_SEND_COMMAND		>
		mov	es:[result], MRC_ERROR

		mov	es:[parser], offset ModemParseNoConnection

		BitClr	es:[modemStatus], MS_CLIENT_BLOCKED
		mov	bx, es:[responseSem]
		call	ThreadVSem		
		ret
ModemSendError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemSendByteAsAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a byte as an ascii decimal string.

CALLED BY:	ModemDoAutoAnswer

PASS:		es	= dgroup
		bx	= SerialPortNum
		al	= byte 

RETURN:		carry set if error		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/17/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemSendByteAsAscii	proc	near
		uses	ax, cx, dx, di, si, ds, es
		.enter

		sub	sp, ASCII_BUFFER_SIZE
		mov	di, sp
		segmov	ds, es, cx		; ds = dgroup
		segmov	es, ss, cx		; es:di = buffer for string
		clr	dx, cx
		clr	ah
		call	UtilHex32ToAscii	; cx = length of string

EC <		cmp	cx, MAX_ASCII_ARG_SIZE				>
EC <		ERROR_A INVALID_ARGUMENT_TO_MODEM_COMMAND		>

		mov	dx, cx			; dx = size
		segxchg	ds, es
		mov	si, di			; ds:si = ascii string
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]
		add	sp, ASCII_BUFFER_SIZE

		cmp	cx, dx			; carry set if less than

		.leave
		ret
ModemSendByteAsAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemSwitchToCommandMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch the modem to command mode.

CALLED BY:	ModemDoHangup
		ModemDoReset

PASS:		es	= dgroup
		bx	= port number

RETURN:		carry set if error

DESTROYED:	ax, cx, di, si, ds (allowed)

NOTES:
		Do NOT provide this as an API call to the modem driver
		as it should be used with extreme caution.  Allowed for
		ATZ and ATH0 because the responses to should always
		be OK.  ERROR may be returned if the arguments are not
		supported by the modem or are wrong, but the modem 
		driver uses the basic forms of these two commands which
		all modems should support.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/31/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemSwitchToCommandMode	proc	near

	;
	; No need to switch if already in command mode.
	;
		test	es:[modemStatus], mask MS_COMMAND_MODE
		jnz	exit				; carry clear
	;
	; Switch to command mode by sending <guard>"+++"<guard>.
	;
		BitSet	es:[modemStatus], MS_COMMAND_MODE

	; Flush the read buffer.  If for some reason, our client hasn't
	; read the stream for a while, we will not get responses to our
	; escape and/or hangup commands.  So read all chars till we don't
	; have anymore.  NOTE: for some reason, DR_STREAM_FLUSH did not
	; have the same effect.
	;
		sub	sp, 64			; use 64 bytes from stack
		segmov	ds, ss, si		; as buffer.
		mov	si, sp

readMore:
		mov	ax, STREAM_NOBLOCK
		mov	cx, 64
		mov	di, DR_STREAM_READ
		call	es:[serialStrategy]
		tst	cx			; any chars?
		jnz	readMore		; if so, try again.

		add	sp, 64

		mov	ax, ESC_GUARD_TIME
		call	TimerSleep

		segmov	ds, cs, si
		mov	si, offset cmdEscapeSequence
		mov	cx, size cmdEscapeSequence

	; Write the +'s out slowly.. 3 fast +'s may not always
	; be caught.
	;
writeBlock:
		mov	ax, 10
		call	TimerSleep
		push	cx
		lodsb
		mov	cl, al
		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE_BYTE
		call	es:[serialStrategy]
		jc	exit
		pop	cx
		dec	cx
		jnz	writeBlock

if 0	; The old way -- writing 3+'s all at once.  I don't think this may
	; matter much, but it seems that I've seen this problem before on
	; other modems.  --JimG 9/9/99
FXIP <		call	SysCopyToStackDSSI			>

		mov	ax, STREAM_NOBLOCK
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]

FXIP <		call	SysRemoveFromStack			>

		cmp	cx, size cmdEscapeSequence
		stc					; be pessimistic
		jne	exit
endif	; end old way ---------------
		
		mov	ax, ESC_GUARD_TIME
		call	TimerSleep		
		clc
exit:
		ret

ModemSwitchToCommandMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemAbortDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by non-client thread to abort a dial in progress.
		Sets the MS_ABORT_DIAL bit and may send the DO_ABORT_DIAL
		message if a dial is in progress.

CALLED BY:	ModemStrategy

PASS:		es	= dgroup

RETURN:		carry: set if too late -- already in data mode.
		       clear otherwise.

DESTROYED:	di (preserved by ModemStrategy)

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/08/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemAbortDial	proc	far
		uses	bx, cx, ax, di
		.enter

		mov	bx, es:[abortSem]
		call	ThreadPSem

	; If there is no client or we have already been called, do nothing.
	; Also, don't do anything if a DIAL is not in progress.
	;
		test	es:[modemStatus], mask MS_HAVE_CLIENT
		jz	doneVSem				; clc
		test	es:[modemStatus], mask MS_ABORT_DIAL
		jnz	doneVSem				; clc
		cmp	es:[pendingMsg], MSG_MODEM_DO_DIAL
		jne	noDialMsgPending

		BitSet	es:[modemStatus], MS_ABORT_DIAL

	; Send the message to the modem thread to actually talk to the
	; serial port.  Insert this at the front of the queue just in
	; case we can squeeze in ahead of the MSG_MODEM_DO_DIAL message.
	;
	; We don't call ModemDoCommand here because we are circumventing
	; the requirements about a non-client calling the modem thread.
	;
		mov	ax, MSG_MODEM_DO_ABORT_DIAL
		mov	bx, es:[modemThread]
		mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
		call	ObjMessage

doneCLC:
		clc

doneVSem:
		mov	bx, es:[abortSem]
		call	ThreadVSem		; flags preserved

		.leave
		ret

noDialMsgPending:
	; There is no dial message pending.  If we are in data mode, then
	; we need to return carry so that the caller knows that there's
	; nothing we could do at this point -- he is too late!
	; 
	; If we are in command mode then set the ABORT_DIAL bit anyway
	; in case the DR_MODEM_DIAL command was just about to happen and
	; it will prevent the dial command from being issued.
	;
		test	es:[modemStatus], mask MS_COMMAND_MODE
		stc
		jz	doneVSem

		BitSet	es:[modemStatus], MS_ABORT_DIAL
		jmp	doneCLC

ModemAbortDial	endp


CommonCode	ends
