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
idata	segment

	basePortAddress		word		0h
	zeroFlag					byte		0h
	x10DriverCategory 	char		"X-10Control",0
	x10DriverKey 			char 		"port",0

idata	ends

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

SYNOPSIS:	Send out a command

CALLED BY:	Strategy Routine
PASS:    ds = dgroup of driver
			ah = house code
			al = unit number/function
RETURN:		nothing
DESTROYED:	nothing at all!
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Call appropriate Send1 or Send0 commands.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Send 		proc far
	uses ax, bx, cx
	.enter

	mov	cx, 4							; wait for 4 zero crossings
testz:
	call	X10TestZeroCrossing
	jnc	testz
	loop	testz

	mov	cx, 2							; send commands twice.

sendCommmand:
	call	X10Send1
	call 	X10Send1
	call	X10Send1
	call 	X10Send0						; send start code

	clr	bx
	mov	bh, ah						; get house code
	and	bh, 01h
	call	X10SendBit

	clr	bx
	mov	bh, ah
	and	bh, 02h
	call	X10SendBit

	clr	bx
	mov	bh, ah
	and	bh, 04h
	call	X10SendBit

	clr	bx
	mov	bh, ah
	and	bh, 08h
	call	X10SendBit

	clr	bx
	mov	bh, al                  ; get unit/function code
	and	bh, 01h
	call	X10SendBit

	clr	bx
	mov	bh, al
	and	bh, 02h
	call	X10SendBit

	clr	bx
	mov	bh, al
	and	bh, 04h
	call	X10SendBit

	clr	bx
	mov	bh, al
	and	bh, 08h
	call	X10SendBit

	clr	bx
	mov	bh, al
	and	bh, 10h
	call	X10SendBit             ; that's it!

	loop	sendCommmand

	mov	cx, 2							; wait for 2 zero crossings, to stay in sync.

testit:
	call	X10TestZeroCrossing
	jnc	testit
	loop	testit

	.leave
	ret
X10Send		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10SendBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a command

CALLED BY:	X10Send
PASS:    ds = dgroup of driver
			bh = bit to send
RETURN:		nothing
DESTROYED:	nothing at all!
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Call appropriate Send1 or Send0 commands.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10SendBit		proc	near
	.enter

	cmp	bh, 0
	je		zero

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
		X10ChangePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the port to which the X-10 codes are sent.

CALLED BY:	Strategy Routine

PASS:		cx = new port to use
RETURN:		dx = zero if no error, 1 if no port found.
DESTROYED:	nothing
SIDE EFFECTS:
		Initializes controller on new port.

PSEUDO CODE/STRATEGY:
		Store new port data in .ini file.
		Call X10Init.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10ChangePort		proc	far
	uses bx, cx, dx, bp, si
	.enter
	mov	bx, ds:[basePortAddress]		; store old port in bx
	mov	bp, cx                        ; bp <- integer to write to file
	mov	si, offset x10DriverCategory	; ds:si <- category asciiz
	mov	cx, ds								; cx:dx <- key asciiz
	mov	dx, offset x10DriverKey
	call	InitFileWriteInteger
	clr	dx										; assume no error
	call	X10Init
	jnc	done
	mov	bp, bx								; reset to old port.
	mov	dx, offset x10DriverKey
	call 	InitFileWriteInteger
	call	InitFileCommit
	mov	ds:[basePortAddress], bx
	mov	dx, 1									; return an error if X10Init doesn't work.
	
done:
	.leave
	ret
X10ChangePort		endp

X10ChangeSettings	proc	far
	ret
X10ChangeSettings	endp

LoadableCode		ends
