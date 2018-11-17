COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		
FILE:		slipTia.asm

AUTHOR:		Jennifer Wu, Oct 18, 1994

ROUTINES:
	Name			Description
	----			-----------
	SlipGetLoginInfo
	SlipReadInfo

	SlipQuitTia

	SlipSendLogin
	SlipParseLogin

	SlipFindInputCharBackward

	SlipSendPassword
	SlipParsePassword

	SlipSendTia
	SlipConnectComplete
	
	SlipSendLogout

	SlipParsePrompt

	SlipDisconnectComplete

	SlipInputError
	SlipReceiveDataTia

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/18/94	Initial revision

DESCRIPTION:
	Code that lets SLIP work with TIA.  Separated to make 
	it easier to exclude.

	$Id: slipTia.asm,v 1.1 97/04/18 11:57:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipGetLoginInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get login name and password.

CALLED BY:	SlipInit

PASS:		es	= dgroup

RETURN:		carry set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Read login name and password from special file
	and save the info.
		
	Login file is in privdata directory and is named:
	"Slip Login".  Format of file is:
	<size of login (byte)><login><size of password (byte)><password>

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
slipFileName	char	"login.slp", 0

SlipGetLoginInfo	proc	near
		uses	ax, bx, dx, ds
		.enter
	;
	; Switch to directory holding file.
	;
		call	FilePushDir

		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
	;
	; Open file.
	;
		segmov	ds, cs, ax
		mov	dx, offset slipFileName		; ds:dx = file name
		mov	al, FileAccessFlags \
				<FE_DENY_WRITE, FA_READ_ONLY>	
		call	FileOpen			; ax = file handle
		jc	popDir
	;
	; Read the login and password from the file.  
	;
		mov	bx, ax				; bx = file handle
		call	SlipReadInfo			; carry set if error
	;
	; Close the file.
	;		
		pushf		
		clr	al
		call	FileClose
EC <		ERROR_C	SLIP_COULD_NOT_CLOSE_LOGIN_FILE		>
		popf
popDir:	
		call	FilePopDir

		.leave
		ret
SlipGetLoginInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipReadInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read login and password from passed file.

CALLED BY:	SlipGetLoginInfo

PASS:		bx	= file handle
		es	= dgroup

RETURN:		carry set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
		Read size of login string
		Read login string to dgroup
		Read size of password string
		Read password string to dgroup

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipReadInfo	proc	near
		uses	ax, cx, dx, ds
		.enter
	;
	; Read size of login string.
	;
		segmov	ds, es, ax

		clr	al
		mov	cx, 1			
		mov	dx, offset loginSize		; ds:dx = place for size
		call	FileRead
		jc	exit
	;
	; Read login.  (not null terminated)
	;
		clr	ch
		mov	cl, ds:[loginSize]		; cx = size of login 
		
EC <		cmp	cx, SLIP_LOGIN_SIZE				>
EC <		ERROR_A	-1		; constant needs to be bigger	>
		
		mov	dx, offset login
		clr	al
		call	FileRead
		jc	exit
	;
	; Read size of password.
	;
		clr	al
		mov	cx, 1
		mov	dx, offset passwordSize		; ds:dx = place for size
		call	FileRead			
		jc	exit
	;
	; Read password. (not null terminated)
	;
		clr	ch
		mov	cl, ds:[passwordSize]
		
EC <		cmp	cx, SLIP_PASSWORD_SIZE				>
EC <		ERROR_A -1		; constant needs to be bigger	>
		
		mov	dx, offset password
		clr	al
		call	FileRead
		jc	exit

		clc	
exit:
		.leave
		ret
SlipReadInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipQuitTia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quit Tia or else we won't be able to open the connection
		next time around.

CALLED BY:	SlipDisconnectRequest

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/15/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipQuitTia	proc	near
		uses	ax, bx, cx, dx, di
		.enter
	;
	; To quit tia, send 5 slow control-C's so that 2 seconds elapse
	; between the first and final Ctrl-C.
	;
		mov	dx, NUM_CTRL_C_TO_QUIT_TIA
		mov	bx, ds:[slipPort]
		mov	di, DR_STREAM_WRITE_BYTE
quitLoop:
	;
	; Send a Ctrl-C.  Pause afterwards.
	;
		mov	ax, STREAM_BLOCK
		mov	cl, C_CTRL_C
		call	ds:[serialStrategy]

		dec	dx
		jz	exit
		
		mov	ax, PAUSE_BETWEEN_CTRL_C_TO_QUIT_TIA
		call	TimerSleep
		jmp	quitLoop
exit:		
		.leave
		ret
SlipQuitTia	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipSendLogin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that input is "login: " and send our login name.

CALLED BY:	SlipProcessInput

PASS: 		es	= dgroup
		ds	= segment of input buffer
		inputStart marks beginning of input data
		inputEnd marks end of input data

RETURN:		nothing

DESTROYED:	ax, bx, cx, di, si (preserved by caller)

PSEUDO CODE/STRATEGY:
		Read input from serial port.  Verify that the data
		is "login: " and send our login followed by a <CR>.

		Advance the state to SS_SENT_LOGIN.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipSendLogin	proc	near

		uses	es, ds
		.enter
	;
	; Find "login: " in buffer.
	;
		segxchg	es, ds			; ds = dgroup, es = input buffer
		call	SlipParseLogin
		jc	exit			; not found
	;
	; Send our login and send a <CR>.
	;
		mov	ax, STREAM_BLOCK
		mov	bx, ds:[slipPort]
		clr	ch
		mov	cl, ds:[loginSize]
		mov	si, offset login	; ds:si = login string
		mov	di, DR_STREAM_WRITE
		call	ds:[serialStrategy]

		mov	ax, STREAM_BLOCK
		mov	cl, C_CR
		mov	di, DR_STREAM_WRITE_BYTE
		call	ds:[serialStrategy]
	;
	; Advance to next state.
	;
		call	SlipGainAccess
		mov	ds:[slipState], SS_SENT_LOGIN
		call	SlipReleaseAccess
exit:		
		.leave
		ret

SlipSendLogin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipParseLogin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find "login:" in the input buffer.

CALLED BY:	SlipSendLogin

PASS:		ds 	= dgroup
		es	= segment of input buffer
		inputStart marks beginning of data
		inputEnd marks end of data

RETURN:		carry clr if "login:" found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Scan input backwards for ':' as it marks the 
		end of the login prompt.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
loginString	char	"login:"

SlipParseLogin	proc	near
		uses	ax, cx, di, si
		.enter
	;
	; Scan input for ':'.  
	;
		mov	ax, ':'
		call	SlipFindInputCharBackward ; es:di = byte after ':'
		jc	exit			; not found
	;
	; Compare with loginString. 
	;
		push	ds
		mov	cx, size loginString
		sub	di, cx			; es:di = "login:", I hope
		segmov	ds, cs
		mov	si, offset loginString
		call	LocalCmpStrings
		pop	ds

		stc				; assume no match
		jne	exit

		mov	di, ds:[inputEnd]	
		mov	ds:[inputStart], di
		clc
exit:
		.leave
		ret
SlipParseLogin	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipFindInputCharBackward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a specific character in the input data.

CALLED BY:	SlipParseLogin
		SlipParsePassword
		SlipParsePrompt

PASS:		ds	= dgroup
		es	= segment of input buffer
		ax	= char to find
		inputStart marks beginning of input data
		inputEnd marks end of input data

RETURN:		carry set if char not found
		else, es:di points to byte after char in input

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/15/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipFindInputCharBackward	proc	near
		uses	cx
		.enter

		mov	di, ds:[inputEnd]
		mov	cx, di
		sub	cx, ds:[inputStart]	; # bytes of input data
		dec	di			; es:di = last byte of input
		LocalFindCharBackward
		je	found

		stc	
		jmp	exit
found:	
	;
	; ES:DI points to byte before char that matched.
	;
		inc	di
		inc	di			; es:di = byte after char
		clc		
exit:
		.leave
		ret
SlipFindInputCharBackward	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipSendPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the input is "password: " and send our password.

CALLED BY:	SlipProcessInput

PASS:		es	= dgroup
		ds	= segment of input buffer
		inputStart marks beginning of input data
		inputEnd marks end of input data

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di (preserved by caller)

PSEUDO CODE/STRATEGY:
		Read input from serial port.  Verify that the data
		is "password: " and send our password followed by
		a <CR>.
		
		Send "tia"<CR>.

		Advance state to SS_OPEN.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipSendPassword	proc	near
		uses	es, ds
		.enter
	;
	; Find "password: " in buffer.
	;
		segxchg	es, ds			; ds = dgroup, es = input buffer
		call	SlipParsePassword
		jc	exit			; not found		
	;
	; Send our password followed by a <CR>.
	;
		mov	ax, STREAM_BLOCK
		mov	bx, ds:[slipPort]
		clr	ch
		mov	cl, ds:[passwordSize]
		mov	si, offset password	; ds:si = password string
		mov	di, DR_STREAM_WRITE
		call	ds:[serialStrategy]

		mov	ax, STREAM_BLOCK
		mov	cl, C_CR
		mov	di, DR_STREAM_WRITE_BYTE
		call	ds:[serialStrategy]
	;
	; Advance to next state.
	;
		call	SlipGainAccess
		mov	ds:[slipState], SS_SENT_PASSWORD
		call	SlipReleaseAccess
exit:		
		.leave
		ret
SlipSendPassword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipParsePassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find "Password:" in the input buffer.

CALLED BY:	SlipSendPassword

PASS:		ds 	= dgroup
		es	= segment of input buffer
		cx	= number of bytes read
		bufferStart marks beginning of data
		bufferOff marks end of data

RETURN:		carry clr if "Password:" found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
passwordString	char	"Password:"

SlipParsePassword	proc	near
		uses	ax, cx, di, si
		.enter
	;
	; Scan input for ':'.  
	;
		mov	ax, ':'
		call	SlipFindInputCharBackward ; es:di = byte after ':'
		jc	exit			; not found
	;
	; Compare with passwordString. 
	;
		push	ds
		mov	cx, size passwordString
		sub	di, cx			; es:di = "Password:", I hope
		segmov	ds, cs
		mov	si, offset passwordString
		call	LocalCmpStrings
		pop	ds

		stc				; assume no match
		jne	exit

		mov	di, ds:[inputEnd]	
		mov	ds:[inputStart], di
		clc
exit:		
		.leave
		ret
SlipParsePassword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipSendTia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send tia once we've received the prompt.

CALLED BY:	SlipProcessInput

PASS:		es 	= dgroup
		ds	= segment of input buffer
		inputStart marks beginning of input
		inputEnd marks end of input

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di (preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tiaString	char	"tia", C_CR
SlipSendTia	proc	near

	;
	; Find the prompt.
	;
		call	SlipParsePrompt
		jc	exit
	;
	; Send "tia"<CR>.
	;
		mov	ax, STREAM_NOBLOCK
		mov	bx, es:[slipPort]
		mov	cx, size tiaString
		segmov	ds, cs, si
		mov	si, offset tiaString
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]
	;
	; Advance to next state.
	;
		call	SlipGainAccess
		mov	es:[slipState], SS_SENT_TIA
		call	SlipReleaseAccess
exit:
		ret
SlipSendTia	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipConnectComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait for "Ready to start your SLIP software." before 
		claiming link is open.  This will avoid control characters
		in the slip data from interfering with tia before it
		enters slip mode.

CALLED BY:	SlipProcessInput

PASS:		es 	= dgroup
		ds	= segment of input buffer
		inputStart marks beginning of input
		inputEnd marks end of input

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di (preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/23/94			Initial version
	jwu	8/12/96			Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
readyString	char	"SLIP software."

SlipConnectComplete	proc	near
		uses	ds, es
		.enter
	;
	; Scan input for '.'
	;
		segxchg	es, ds			; ds = dgroup, es = input buffer
		mov	ax, '.'
		call	SlipFindInputCharBackward 	; es:di = byte after '.'
		jc	exit			; not found
	;
	; Compare with readyString.
	;		
		push	ds
		mov	cx, size readyString
		sub	di, cx			; es:di = "SLIP software."
		segmov	ds, cs
		mov	si, offset readyString
		call	LocalCmpStrings
		pop	ds			; ds = dgroup
		jne	exit
	;
	; Reset inputBuffer.
	;
		clr	di
		mov	ds:[inputStart], di
		mov	ds:[inputEnd], di
	;
	; Advance to open state.
 	;
		call	SlipGainAccess
		mov	ds:[slipState], SS_OPEN
		call	SlipReleaseAccess
		call	SlipLinkOpened
exit:
		.leave
		ret
SlipConnectComplete	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipSendLogout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send "logout" once we've received the prompt.

CALLED BY:	SlipProcessInput

PASS:		es 	= dgroup
		ds	= segment of input buffer
		inputStart marks beginning of input
		inputEnd marks end of input

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di (preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/15/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
logoutString	char	"logout", C_CR

SlipSendLogout	proc	near
	;
	; Find the prompt.
	;
		call	SlipParsePrompt
		jc	exit
	;
	; Send "logout"<CR>.
	;
		mov	ax, STREAM_NOBLOCK
		mov	bx, es:[slipPort]
		mov	cx, size logoutString
		segmov	ds, cs
		mov	si, offset logoutString
		mov	di, DR_STREAM_WRITE
		call	es:[serialStrategy]
	;
	; Advance to next state.
	;
		call	SlipGainAccess
		mov	es:[slipState], SS_SENT_LOGOUT
		call	SlipReleaseAccess
exit:
		ret
SlipSendLogout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipParsePrompt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find login name in the input data as it marks the end of 
		the prompt.  

CALLED BY:	SlipSendTia
		SlipSendLogout

PASS:		es 	= dgroup
		ds	= segment of input buffer
		inputStart marks beginning of input data
		inputEnd marks end of input data

RETURN:		carry clr if prompt found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	ifdef LOGIN_NAME_IN_PROMPT
		Search backwards to find the last char in the login
		name so that we only have to search once each time.  
		
		The first letter of the login name may be repeated
		in the login itself so we can't use the first char.
		Also if we search forwards, the char may appear in
		other data so we would have to search the entire data
		for instances of the letter.
	else
		Search for a '%' which marks the end of the prompt.
	endif
	
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipParsePrompt	proc	near
		uses	ax, bx, cx, di, si, es, ds
		.enter
		
		segxchg	es, ds			; ds = dgroup, es = input buffer

if _LOGIN_NAME_IN_PROMPT	
	;
	; Find last letter of login name in string, searching backwards.
	;
		clr	bh, ah
		mov	bl, ds:[loginSize]	; bx = login size
		dec	bx			
		mov	al, ds:[login][bx]	; ax = last char in login
		call	SlipFindInputCharBackward
		jc	exit
	;
	; Compare the string with the login name.  
	;
		clr	ch
		mov	cl, ds:[loginSize]	; cx = login size
		sub	di, cx			; es:di = what should be login
		mov	si, offset login	; ds:si = login name
		call	LocalCmpStrings
		stc
		jne	exit

else
	;
	; Find "%" in string, searching backwards.
	;
		mov	ax, PROMPT_SYMBOL
		call	SlipFindInputCharBackward	; es:di = byte after '%'
		jc	exit				; not found
endif
	
	;
	; Discard the data since we found the prompt.
	;
		mov	di, ds:[inputEnd]
		mov	ds:[inputStart], di
		clc

exit:				
		.leave
		ret
SlipParsePrompt	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipDisconnectComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the "login: " request.  If found, it is safe to
		close the serial port so wake up the waiter. 

CALLED BY:	SlipProcessInput

PASS:		es 	= dgroup
		ds	= segment of input buffer
		inputStart marks beginning of input
		inputEnd marks end of input

RETURN:		nothing

DESTROYED:	bx (preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/15/94			Initial version
	jwu	8/12/96			Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipDisconnectComplete	proc	near
		uses	es, ds
		.enter
	;
	; Find "login: " in input.  If found, it is safe to 
	; close the link.
	;
		segxchg	es, ds			; ds = dgroup, es = input buffer
		call	SlipParseLogin
		jc	exit			; not found

		call	SlipLinkClosed
exit:		
		.leave
		ret
SlipDisconnectComplete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipInputError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received input when there should be none. 

CALLED BY:	SlipProcessInput

PASS: 		es	= dgroup
		ds	= segment of input buffer

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp	(preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipInputError	proc	near

		stc
EC <		ERROR_C	-1	; shouldn't be receiving input yet...>
		ret
SlipInputError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlipReceiveDataTia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate routine to handle the data depending
		on what state slip is in.

CALLED BY:	SlipProcessInput

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/13/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlipReceiveDataTia	proc	near
		uses	bx
		.enter

		mov	bx, es:[slipState]
		call	cs:inputProcTable[bx]

		.leave
		ret
SlipReceiveDataTia	endp

inputProcTable		nptr	\
	SlipInputError,			; SS_CLOSED
	SlipInputError,			; SS_LOGIN
	SlipSendLogin,			; SS_SENT_CR
	SlipSendPassword,		; SS_SENT_LOGIN
	SlipSendTia,			; SS_SENT_PASSWORD
	SlipConnectComplete,		; SS_SENT_TIA
	SlipReceiveData,		; SS_OPEN
	SlipSendLogout,			; SS_QUIT_TIA
	SlipDisconnectComplete		; SS_SENT_LOGOUT

CommonCode	ends

