COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Breadbox Computer 1995 -- All Rights Reserved

PROJECT:	Breadbox Home Automation
MODULE:	X-10 Power Code Driver
FILE:		x10Send.asm

AUTHOR:		Fred Goya
	
DESCRIPTION:
	This file contains the routines to send X-10 power codes whenever the AC
	power line crosses zero.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10TestZeroCrossing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for zero-crossing point

CALLED BY:	X10Init, X10Send*
PASS:    ds = dgroup of driver
RETURN:		carry set if crossing found.
DESTROYED:	nothing at all!
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Read waiting byte from port.
		Make sure byte is a zero.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10TestZeroCrossing	proc	far
	uses	ax, cx, dx
	.enter

	call	SysEnterInterrupt			; prevent context switches
	cli									; ...and interrupts, too
	mov	dx, ds:[basePortAddress]; lets us use dx to specify port
	add	dx, 6							; the original code does this, so I do, too...
	in		al, dx						; read byte from port
	andnf	al, 20h						; another original code thing
	mov	cl, ds:[zeroFlag]			; store old zeroFlag
	mov	ds:[zeroFlag], al			; save new byte for later
	xor	cl, al						; compare zeroes--this also clears carry flag
	jz		notZero						; not complementary? then stop wasting my time!
	stc									; it *is* a zero crossing!
notZero:
	sti									; re-enable interrupts...
	call	SysExitInterrupt			; ...and context switches
	.leave
	ret
X10TestZeroCrossing	endp

ResidentCode	ends

LoadableCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Send
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a standard house code and unit number/function pair

CALLED BY:	Strategy Routine
PASS:    ds = dgroup of driver
			ah = house code
			al = unit number/function
			cl = dim/bright count
RETURN:		nothing
DESTROYED:	nothing at all!
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Call appropriate Send1 or Send0 commands.
		If bright or dim command is to be sent, this will repeat the
		command bl times without pausing between commands.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Send 		proc far
	uses ax, bx, cx
	.enter

	tst	ds:[basePortAddress]			; don't want to actually send commands
	jz	done							; if we don't have a port!

	mov	bx, cx							; preserve cl

;	mov	cx, 4							; wait for 4 zero crossings
testz:
	call	X10TestZeroCrossing
	jnc	testz
;	loop	testz

	mov	cx, 2							; send normal commands twice.

	cmp al, 10010b						; dim command
	je	dimOrBright
	cmp	al, 11010b						; bright command
	je	dimOrBright
	jmp	sendCommand
dimOrBright:
	mov	cl, bl
	inc	cx					; bright/dim commands get sent bl + 1 times

sendCommand:
	call	X10Send1
	call 	X10Send1
	call	X10Send1
 	call 	X10Send0						; send start code

	clr	bx
	mov	bl, ah						; get house code
	call	X10SendBit				; bit 0

	shr bl, 1
	call	X10SendBit				; bit 1

	shr bl, 1
	call	X10SendBit				; bit 2

	shr bl, 1
	call	X10SendBit				; bit 3

	clr	bx
	mov	bl, al                  ; get unit/function code
	call	X10SendBit				; bit 0

	shr bl, 1
	call	X10SendBit				; bit 1

	shr bl, 1
	call	X10SendBit				; bit 2

	shr bl, 1
	call	X10SendBit				; bit 3

	shr bl, 1
	call	X10SendBit             ; bit 4 - that's it!

	loop	sendCommand

	mov	cx, 3							; wait for 3 zero crossings, to stay in sync.

testit:
	call	X10TestZeroCrossing
	jnc	testit
	loop	testit

done:
	.leave
	ret
X10Send		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10SendBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a command

CALLED BY:	X10Send
PASS:    ds = dgroup of driver
			bl bit 0 = bit to send
RETURN:		nothing
DESTROYED:	nothing at all!
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Call appropriate Send1 or Send0 commands.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10SendBit		proc	near
	.enter

	test	bl, 1						; you can look, but not touch bit 0
	jz		zero

	call	X10Send1					; bit is a 1
	call 	X10Send0
	jmp	done

zero:
	call 	X10Send0					; bit is a 0
	call  X10Send1

done:
	.leave
	ret
X10SendBit		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Send1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a half-bit one

CALLED BY:	X10Send*
PASS:    ds = dgroup of driver
RETURN:		nothing
DESTROYED:	nothing at all!
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Send out bits on zero crossings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Send1		proc	near
	uses	ax, cx, dx
	.enter
   clr	ax

testz:
	call	X10TestZeroCrossing
	jnc	testz

	mov	dx, ds:[basePortAddress]	; get base port
	add	dx, 4								; why? 'cause the source code says so!

	mov	al, 3                      ; start sending the pulses which indicate a
	out	dx, al                     ;	 one to the controller.
	mov	cx, DELAY1000
	call	X10Sleep							; routine for timing.
	mov	al, 1
	out	dx, al
	mov	cx, DELAY1778
	call	X10Sleep							; routine for timing.
	mov	al, 3
	out	dx, al
	mov	cx, DELAY1000
	call	X10Sleep							; routine for timing.
	mov	al, 1
	out	dx, al
	mov	cx, DELAY1778
	call	X10Sleep							; routine for timing.
	mov	al, 3
	out	dx, al
	mov	cx, DELAY1000
	call	X10Sleep							; routine for timing.
	mov	al, 1
	out	dx, al

	.leave
	ret
X10Send1		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Send0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a half-bit zero

CALLED BY:	X10Send*
PASS:    ds = dgroup of driver
RETURN:		nothing
DESTROYED:	nothing at all!
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Since a zero is indicated by silence to the controller, just wait for one
		zero crossing.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Send0		proc	near

testz:
	call	X10TestZeroCrossing
	jnc	testz

	ret
X10Send0		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10GetPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the port settings currently in use.

CALLED BY:	Strategy Routine

PASS:		nothing
RETURN:		cx = port: 0 = none, 1 = COM1, .., 4 = COM4.
DESTROYED:	nothing
SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		Recall current port setting

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10GetPort		proc	far
	mov	cx, ds:[X10Port]					; cx <- X10Port
	ret
X10GetPort		endp

X10ChangeSettings	proc	far
	ret
X10ChangeSettings	endp

LoadableCode		ends
