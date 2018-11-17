COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Breadbox Computer 1999 -- All Rights Reserved

PROJECT:	Breadbox Home Automation
MODULE:		X-10 Power Code Driver
FILE:		x10Send.asm

AUTHOR:		David Hunter
	
DESCRIPTION:
	This file contains the routines to setup and communicate with the
	X-10 serial computer interface CM11.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Equates
;-----------------------------------------------------------------------------

SerialFormatData    	equ  SerialFormat < 0, 0, SP_NONE, 0, SL_8BITS >

SERIAL_BUFSIZE			equ	20		; stream buffer size

SERIAL_INIT_TIMEOUT		equ 30		; status request timeout in ticks
SERIAL_SEND_TIMEOUT		equ	10*60	; send (transmit) timeout in ticks
SERIAL_RECV_TIMEOUT		equ	30		; receive timeout in ticks
SERIAL_POLL_TIMEOUT		equ 90		; poll duration in ticks (plus a little)

SERIAL_INIT_RETRY		equ 10		; # of times to retry for initialization
SERIAL_SEND_RETRY		equ	10		; # of times to retry for proper chksum

SERIAL_PROTO_OK				equ 000h	; OK for transmission byte
SERIAL_PROTO_READY			equ 055h	; interface ready byte
SERIAL_PROTO_RECV_POLL		equ 05ah	; interface poll for receive byte
SERIAL_PROTO_RECV_POLL_RESP	equ 0c3h	; reponse to interface poll byte
SERIAL_PROTO_PFMD_POLL		equ 0a5h	; power-fail macro download poll byte
;SERIAL_PROTO_PFMD_POLL_RESP	equ 0fbh	; response to interface poll byte
SERIAL_PROTO_PFMD_POLL_RESP	equ 09bh	; response to interface poll byte
SERIAL_PROTO_IFF_POLL		equ 0f3h	; input filter fail poll byte
SERIAL_PROTO_IFF_POLL_RESP	equ 0f3h	; response to interface poll byte
SERIAL_PROTO_STATUS_REQ		equ 08bh	; status request byte
SERIAL_PROTO_STATUS_COUNT	equ	14		; status request response byte count

;-----------------------------------------------------------------------------

udata	segment
	buffer	db 14 dup (?)
udata	ends

ResidentCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10ReceiveNotifyCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	Serial Driver
PASS:    	
RETURN:		
DESTROYED:	
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10SerialReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait for a specified amount of time to receive a single byte.

CALLED BY:	X10SendSerial
PASS:    	cx <- timeout in ticks (1/60 second)
			bl <- serial unit
RETURN:		if cf is set, al = returned byte; otherwise, al = undefined
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
	Perform non-blocking byte read on serial stream
	If success, return byte
	Otherwise, sleep for a tick and try again
	Repeat at most cx times

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10SerialReceive	proc far
	uses di,cx
	.enter

;	Read the stream.
	mov		di, DR_STREAM_READ_BYTE
tryForByte:
	mov		ax, STREAM_NOBLOCK			; ax <- no blocking on stream
	call	ds:[serialStrategy]			; try reading the byte
	jnc		done						; if no carry, we got it

	mov		ax, 1						; otherwise, we sleep
	call	TimerSleep					; for one tick
	loop	tryForByte					; and quit when cx is out
	WARNING	X10DRVR_SERIAL_RECEIVE_TIMEOUT
	stc									; ensure cf is set

done:
	.leave
	ret
X10SerialReceive	endp


ResidentCode		ends


InitCode			segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10SerialInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the serial stream and test for presence of interface.

CALLED BY:	X10Init, X10ChangePortSerial
PASS:    ds = dgroup of driver
RETURN:		cf = cleared for success or no port set
DESTROYED:	nothing at all!
SIDE EFFECTS:
		Leaves serial stream open if interface found.

PSEUDO CODE/STRATEGY:
		Get the serial driver's strategy routine.
		Open the serial stream.
		Send out status request. (NOTE: only works for HD11)
		Receive 14 bytes of status data, or
		timeout and fail after SERIAL_INIT_TIMEOUT ticks.
		If fail, close stream.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10SerialInit	proc	far
	uses ax,bx,cx,dx,es,si,di,bp
	initCount	local	word
	.enter
	
	mov		ss:[initCount], SERIAL_INIT_RETRY

	cmp		ds:[portHandle], NoPortOpen	; starting out with no port?
	jne		close

	; Get the serial driver's strategy routine.
    mov  bx, handle serial             ; get the serial driver's handle
    push ds
    call GeodeInfoDriver               ; and get its info: ds:si
    segmov es, ds, ax                  ; make that: es:si
    pop  ds                            ; and restore ds
    jnc  gotit
    jmp	 done
gotit:
    movdw ds:[serialStrategy], es:[si], ax  ; got the strategy routine

	; Open the serial stream.
    mov		di, DR_STREAM_OPEN
	mov		ax, mask SOF_TIMEOUT
	mov		bx, ds:[X10Port]	; bx <- 0 = none, 1 = COM1, ...
	tst		bx							; is the port = none?
	clc
	jz		done						; no port set, return no error

	dec		bl
	shl		bl, 1						; bx <- SerialPortNum enum
	mov		cx, SERIAL_BUFSIZE			; cx <- input buffer size
	mov		dx, SERIAL_BUFSIZE			; dx <- output buffer size
	xchg	si, bp
	mov		bp, SERIAL_INIT_TIMEOUT		; bp <- port open timeout
	call	ds:[serialStrategy]			; open the port
	xchg	bp, si
	jc		done

	; Set the serial parameters.
	mov		di, DR_SERIAL_SET_FORMAT
	mov		al, SerialFormatData		; al <- word/stop/parity
	mov		ah, SM_RAW					; ah <- no XON/XOFF
	mov		cx, SB_4800					; cx <- baud rate
	call	ds:[serialStrategy]			; set the parameters
	mov		di, DR_SERIAL_SET_FLOW_CONTROL
	clr		ax							; ax <- no handshaking
	call	ds:[serialStrategy]			; set the handshaking

	; Send out status request.
tryAgain:
	mov		di, DR_STREAM_WRITE_BYTE
	mov		ax, STREAM_BLOCK
	mov		cl, SERIAL_PROTO_STATUS_REQ	; cl <- byte to write
	call	ds:[serialStrategy]			; write the byte
	jc		close						; bad error, shouldn't happen
	
	; Receive 14 bytes of status data or timeout.
	mov		dx, SERIAL_PROTO_STATUS_COUNT
	mov		si, offset buffer
	mov		cx, SERIAL_INIT_TIMEOUT
moreBytes:
	call	X10SerialReceive
	jc		pollCheck
	mov		ds:[si], al
	inc		si
	dec		dx
	jnz		moreBytes

	; Success!
	mov		ds:[portHandle], bx			; store handle in memory
	jmp		done

pollCheck:
	call 	X10HandlePoll
	jc		close
	dec		ss:[initCount]
	WARNING	X10DRVR_SERIAL_INIT_RETRYING
	jnz		tryAgain
	jmp		close
	
	; If fail, close stream.
close:
	mov		di, DR_STREAM_CLOSE
	mov		ax, STREAM_DISCARD
	call	ds:[serialStrategy]			; close the port
	stc									; reinforce the error state

done:
	.leave
	ret
X10SerialInit	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10CloseSerial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the serial port if currently open.

CALLED BY:	X10Close
PASS:    	nothing.
RETURN:		nothing.
DESTROYED:	nothing.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10CloseSerial proc far
	uses ax,bx,di
	.enter
	
	mov	bx, ds:[portHandle]
	cmp	bx, NoPortOpen
	je	done
	mov		di, DR_STREAM_CLOSE
	mov		ax, STREAM_DISCARD
	call	ds:[serialStrategy]			; close the port
	mov	ds:[portHandle], NoPortOpen
done:
	.leave
	ret
X10CloseSerial	endp


InitCode			ends


;Load reg1 with reg2, with the bit order reversed.
;Registers must be of byte width.
;Perform operation on the LSN (nibble) only.
;Transfer MSN unmodified.
;Destroyed: reg2, cf
ReverseBits	macro	reg1, reg2
	rcr reg2, 1
	rcl reg1, 1		; reg1(3) <- reg2(0)
	rcr reg2, 1
	rcl reg1, 1		; reg1(2) <- reg2(1)
	rcr reg2, 1
	rcl reg1, 1		; reg1(1) <- reg2(2)
	rcr reg2, 1
	rcl reg1, 1		; reg1(0) <- reg2(3)
	; reg2 MSN is now in LSN
	shl	reg2, 1
	shl	reg2, 1
	shl	reg2, 1
	shl	reg2, 1
	and reg2, 0f0h	; clear LSN of reg2
	and reg1, 00fh	; clear MSN of reg1
	or	reg1, reg2	; xfer MSN
endm	

LoadableCode		segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10SendSerial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a transmission command to the interface

CALLED BY:	Strategy Routine
PASS:    ds = dgroup of driver
			ah = house code
			al = unit number/function
			cl = dim/bright count
RETURN:		cf set on error
DESTROYED:	nothing at all!
SIDE EFFECTS:

ODD NOTE:	The serial module requires that the house code and unit number
			(or function) be sent _bitwise backwards_ with respect to the
			bit order specified for the TW523.  To prevent the application
			from having to make this distinction, we do the work here.

PSEUDO CODE/STRATEGY:
		Send the header and code bytes, calculating checksum.
		Receive the checksum; retry SERIAL_SEND_RETRY times until success.
		Send the OK byte.
		Receive the ready byte; timeout after SERIAL_SEND_TIMEOUT seconds.
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10SendSerial	proc far
	retryCount	local	word
	dimCount	local	byte
	uses ax,bx,cx,dx,si,di
	.enter
	
	mov 	ss:[retryCount], SERIAL_SEND_RETRY
	inc		cl
	mov		ss:[dimCount], cl
	
	; Reverse the bits in al and ah by moving into dl and dh.
	ReverseBits	dl, al
	ReverseBits	dh, ah
	
	; Get the serial port.
	mov		bx, ds:[portHandle]
	cmp	bx, NoPortOpen
	clc
	je		done						; no port set, return no error

	; Check if data is sitting in the receive stream.
	; This is a possible sign that the interface has been polling us.
	mov		di, DR_STREAM_QUERY
	mov		ax, STREAM_READ
	call	ds:[serialStrategy]
	jc		done						; bad error, let's leave
	tst		ax							; any bytes waiting?
	jz		send						; nothing - go ahead and send.
	call	X10HandlePoll				; something - try for poll.
	jnc		send						; it worked, let's send.
	jmp		done						; otherwise, abort.
	
	; Flush the receive stream.
resend:
	mov		di, DR_STREAM_FLUSH
	mov		ax, STREAM_READ				; read side only
	call	ds:[serialStrategy]
	
	; Send header and code bytes.
	; Header = (d4)(d3)(d2)(d1)(d0) 1  (c4) 0
	; Code   = (h3)(h2)(h1)(h0)(c3)(c2)(c1)(c0)
	; where d is dim count, c is code, h is house
send:
	mov		di, DR_STREAM_WRITE_BYTE
	mov		al, ss:[dimCount]		; al <- X X X (d4)(d3)(d2)(d1)(d0)
	mov		cl, 3
	shl		al, cl					; al <- (d4)(d3)(d2)(d1)(d0) 0 0 0
	or		al, (1 shl 2)			; al <- (d4)(d3)(d2)(d1)(d0) 1 0 0
	test	dx, (1 shl 4)			; look at (c4)
	jz		isUnit					; unit doesn't have (c4) set
	or		al, (1 shl 1)			; al <- (d4)(d3)(d2)(d1)(d0) 1 1 0
isUnit:
	mov		cl, al					; cl <- byte to write
	mov		si, cx					; si <- checksum so far
	mov		ax, STREAM_BLOCK
	call	ds:[serialStrategy]		; write the byte
	mov		ax, dx					; al = X X X X (c3)(c2)(c1)(c0)
	and		al, 0fh					; al = 0 0 0 0 (c3)(c2)(c1)(c0)
	mov		cl, 4					; ah = X X X X (h3)(h2)(h1)(h0)
	shl		ah, cl					; ah = (h3)(h2)(h1)(h0) 0 0 0 0
	or		al, ah					; al = (h3)(h2)(h1)(h0)(c3)(c2)(c1)(c0)
	mov		cl, al					; cl <- byte to write
	add		si, cx					; si <- checksum so far
	mov		ax, STREAM_BLOCK
	call	ds:[serialStrategy]		; write the byte

	; Receive the checksum.
	mov		cx, SERIAL_RECV_TIMEOUT		; cx <- timeout
	call	X10SerialReceive			; al <- checksum
	jc		retry
	mov		dx, si						; dl <- checksum
	cmp		al, dl						; do they match?
	jnz		retry
	
	; Send the acknowledgement.
	mov		cl, SERIAL_PROTO_OK			; cl <- byte to write
	mov		ax, STREAM_BLOCK
	call	ds:[serialStrategy]			; write the byte
	
	; Receive the ready byte.
	mov		cx, SERIAL_SEND_TIMEOUT		; cx <- timeout
	call	X10SerialReceive			; al <- ready byte
	jc		retry						; try again on timeout
	cmp		al, SERIAL_PROTO_READY		; is it the ready byte?
	je		done						; fallthru to retry on fail

retry:
;	call	X10HandlePoll
;	jc		done
	dec		ss:[retryCount]			; can we try again?
	jnz		resend
	stc								; out of chances, fail
	
done:
	.leave
	ret
X10SendSerial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10ChangePortSerial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the port to which the X-10 codes are sent.

CALLED BY:	Strategy Routine

PASS:		cx = new port to use: 0 = none, 1 = COM1, 2 = COM2, ...
RETURN:		dx = zero if no error, 1 if no port found.
DESTROYED:	nothing
SIDE EFFECTS:
		Tests for controller on new port.
		Modifies .INI file ALWAYS.

PSEUDO CODE/STRATEGY:
		Close old port.
		Set and test the new port.
		If no error, use the new port; otherwise, use no port.
		Store new port data via WriteIniFileSettings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10ChangePortSerial	proc	far
	uses ax,bx,di
	.enter
	
	; Close old port.
	mov		bx, ds:[X10Port]	; retrieve port currently in use
	tst		bx
	jz		openNew						; no port to close, skip to open
	dec		bl
	shl		bl, 1						; bx <- SerialPortNum enum
	mov		di, DR_STREAM_CLOSE
	mov		ax, STREAM_DISCARD
	call	ds:[serialStrategy]			; close the port
	
	; Set and test new port.
openNew:
	clr		dx							; assume no error
	mov		ds:[X10Port], cx	; set the new port
	call	X10SerialInit				; and test it
	jnc		write						; it worked, write the change
	clr		ds:[X10Port]		; Error occurred, use no port.
	inc		dx
	
	; Store new port data via WriteIniFileSettings.
write:
	call 	WriteIniFileSettings		; write the change

	.leave
	ret
X10ChangePortSerial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10HandlePoll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for and attempt to handle a poll request from the interface

CALLED BY:	various routines

PASS:		bx <- serial unit
RETURN:		cf clear on no poll or sucess, set on failure
DESTROYED:	nothing
SIDE EFFECTS:
		none

NOTES:	Since this routine is usually called when a normal receive fails,
		the calling routine should retry its initial send/receive procedure
		from the start if the poll is handled successfully.

PSEUDO CODE/STRATEGY:
		Receive a single byte with fixed poll timeout
		If no byte, no poll - return success
		Send appropriate pseudo-answer according to request byte

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10HandlePoll	proc	far
	uses ax,cx,di
	.enter
	
	WARNING	X10DRVR_HANDLE_POLL
	
	; Flush the receive stream.
	mov		di, DR_STREAM_FLUSH
	mov		ax, STREAM_READ				; read side only
	call	ds:[serialStrategy]
	
	; Receive a single byte with fixed poll timeout.
	mov		cx, SERIAL_POLL_TIMEOUT
	call	X10SerialReceive
	jnc		poll
	clc									; no byte, no poll
	WARNING	X10DRVR_HANDLE_POLL_NO_POLL
	jmp		done						; no error, all done

	; Determine which poll response should be sent.
poll:
	cmp		al, SERIAL_PROTO_RECV_POLL
	jne		pfmd
	
	; Receive poll:
	mov		di, DR_STREAM_WRITE_BYTE
	mov		ax, STREAM_BLOCK
	mov		cl, SERIAL_PROTO_RECV_POLL_RESP
	call	ds:[serialStrategy]			; write the byte
	
	; Receive the buffer length.
	mov		cx, SERIAL_RECV_TIMEOUT
	call	X10SerialReceive
	jnc		getbuf
	WARNING	X10DRVR_HANDLE_POLL_RECV_POLL_TIMEOUT
	jmp		done
getbuf:
	mov		dl, al
	; Receive the entire buffer.
getmorebuf:
	dec		dl
	jz		success
	call	X10SerialReceive
	jnc		getmorebuf
	WARNING	X10DRVR_HANDLE_POLL_RECV_POLL_TIMEOUT
	jmp		done
	
pfmd:
	cmp		al, SERIAL_PROTO_PFMD_POLL
	jne		iff
	
	; Power fail macro download poll:
	call	SetInterfaceClock

;	mov		di, DR_STREAM_WRITE_BYTE
;	mov		ax, STREAM_BLOCK
;	mov		cl, SERIAL_PROTO_PFMD_POLL_RESP
;	call	ds:[serialStrategy]			; write the byte
;	; Send an empty 42-byte macro.
;	mov		dl, 42
;sendmacro:
;	mov		di, DR_STREAM_WRITE_BYTE
;	mov		ax, STREAM_BLOCK
;	clr		cl
;	call	ds:[serialStrategy]			; write the byte
;	dec		dl
;	jnz		sendmacro
;	; Expect back a zero checksum.
;	mov		cx, SERIAL_RECV_TIMEOUT
;	call	X10SerialReceive
;	jnc		gotchksum
;	WARNING	X10DRVR_HANDLE_POLL_PFMD_CHKSUM_TIMEOUT
;	jmp		done
;gotchksum:
;	cmp		al, 0
;	stc
;	je		chkgood
;	WARNING	X10DRVR_HANDLE_POLL_PFMD_CHKSUM_BAD
;	jmp		done
;	; Send the acknowledge.
;chkgood:
;	mov		di, DR_STREAM_WRITE_BYTE
;	mov		ax, STREAM_BLOCK
;	mov		cl, SERIAL_PROTO_OK
;	call	ds:[serialStrategy]			; write the byte
;	; Receive the ready.
;	mov		cx, SERIAL_RECV_TIMEOUT
;	call	X10SerialReceive
;	jnc		chkready
;	WARNING	X10DRVR_HANDLE_POLL_PFMD_READY_TIMEOUT
;	jmp		done
;chkready:
;	cmp		al, SERIAL_PROTO_READY
;	je		success
;	stc
;	WARNING	X10DRVR_HANDLE_POLL_PFMD_NOT_READY
	jmp		done

iff:
	cmp		al, SERIAL_PROTO_IFF_POLL
	jne		unknown
		
	; Input Filter Fail:
	mov		di, DR_STREAM_WRITE_BYTE
	mov		ax, STREAM_BLOCK
	mov		cl, SERIAL_PROTO_IFF_POLL_RESP
	call	ds:[serialStrategy]			; write the byte
	jmp		success

unknown:
	stc
	WARNING	X10DRVR_HANDLE_POLL_UNKNOWN_POLL
	jmp		done	

success:
	WARNING	X10DRVR_HANDLE_POLL_SUCCESS
	clc
	
done:
	.leave
	ret
X10HandlePoll	endp


SetInterfaceClock	proc near
	uses	ax,bx,cx,dx,si,di,es
	.enter
	
	mov		si, offset SICdata
	clr		dl
	mov		cx, 6
sum:
	add		dl, cs:[si]
	inc		si
	loop	sum

	; Send the header and data.
	mov		di, DR_STREAM_WRITE_BYTE
	mov		ax, STREAM_BLOCK
	mov		cl, SERIAL_PROTO_PFMD_POLL_RESP
	call	ds:[serialStrategy]			; write the byte
	segmov	es, ds, ax
	push	ds
	segmov	ds, cs, ax
	mov		di, DR_STREAM_WRITE
	mov		ax, STREAM_BLOCK
	mov		cx, 6
	mov		si, offset SICdata
	call	es:[serialStrategy]
	pop		ds
	jc		done

	; Receive the checksum.
	mov		cx, SERIAL_RECV_TIMEOUT
	call	X10SerialReceive
	jnc		gotchksum
	WARNING	X10DRVR_HANDLE_POLL_PFMD_CHKSUM_TIMEOUT
	jmp		done
gotchksum:
	cmp		al, dl
	stc
	je		chkgood
	WARNING	X10DRVR_HANDLE_POLL_PFMD_CHKSUM_BAD
	jmp		done
	; Send the acknowledge.
chkgood:
	mov		di, DR_STREAM_WRITE_BYTE
	mov		ax, STREAM_BLOCK
	mov		cl, SERIAL_PROTO_OK
	call	ds:[serialStrategy]			; write the byte
	; Receive the ready.
	mov		cx, SERIAL_RECV_TIMEOUT
	call	X10SerialReceive
	jnc		chkready
	WARNING	X10DRVR_HANDLE_POLL_PFMD_READY_TIMEOUT
	jmp		done
chkready:
	cmp		al, SERIAL_PROTO_READY
	je		success
	stc
	WARNING	X10DRVR_HANDLE_POLL_PFMD_NOT_READY
	jmp		done

success:
	WARNING	X10DRVR_HANDLE_POLL_PFMD_SUCCESS
	clc
done:
	.leave
	ret

SetInterfaceClock	endp

SICdata	byte	0,0,0,0,1,060h

LoadableCode		ends

