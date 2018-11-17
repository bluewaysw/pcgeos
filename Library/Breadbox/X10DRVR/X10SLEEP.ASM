COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Breadbox Computer 1995 -- All Rights Reserved

PROJECT:	Breadbox Home Automation
FILE:		X10Sleep.asm

AUTHOR:		Fred Goya

ROUTINES:
	Name				Description
	----				-----------
	X10Sleep			Routine for waiting a specific number of microseconds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadableCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Sleep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pause for a given number of microseconds for timing purposes

CALLED BY:	X10SendBit
PASS:    ds = dgroup of driver
			cx = # of microseconds to wait
RETURN:		nothing
DESTROYED:	nothing at all!
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Prevent context switches.
		Prevent interrupts, too...
		Poll timer 0 (system multitasking clock) for initial time.
		Check timer to see whether enough time has gone by.
		If it has, return, after re-enabling context switches.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Sleep		proc	far
	uses ax, bx, cx, dx
	.enter

	call	SysEnterInterrupt	; prevent context-switching while we delay.
	cli
	mov	al, TT_TIMER_0 or TRL_LATCH or TM_RATE_GEN or TC_BINARY
	out	I8253.Mode, al		; latch down current clock time
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	in	al, I8253.Counter0	; read in low byte
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	mov	ah, al			; ah <- lsb of timer
	in	al, I8253.Counter0	; read in high byte
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	xchg	al, ah			; re-order high-low
	mov	bx, ax			; bx <- original time
pollTimer:
	mov	dx, bx			; save original time
	mov	al, TT_TIMER_0 or TRL_LATCH or TM_RATE_GEN or TC_BINARY
	out	I8253.Mode, al
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	in	al, I8253.Counter0	; read in low byte
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	mov	ah, al
	in	al, I8253.Counter0	; read in high byte

	xchg	al, ah			; re-order bytes
	cmp	ax, dx			; has timer rolled over?
	jb		noRoll
	push	dx					; save current timer
	mov	dx, 19876		; maximum timer count+1
	sub	dx, ax			; dx <- number of ticks since rollover
	mov	ax, dx			; ax <- number of ticks since rollover
	pop	dx					; restore current timer
	add	dx, ax			; total time = original count + ticks since rollover
	jmp	checkDelay		; now, check time
noRoll:
	sub	dx, ax			; dx <- dx - ax
checkDelay:
	cmp	dx, cx			; waited longer than delay time?
	jb		pollTimer		; do again.
	sti						; re-enable interrupts
	call	SysExitInterrupt	; re-enable context switches.
	.leave
	ret
X10Sleep		endp

LoadableCode	ends