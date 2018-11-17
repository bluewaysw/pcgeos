COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS Sound System
MODULE:		Sound Driver for SoundBlaster boards
FILE:		soundblasterTimeDelay.asm

AUTHOR:		Todd Stumpf, Jul 27, 1992

ROUTINES:
	Name			Description
	----			-----------
	InitMicroTimer		Set up timer 2 to allow calls to MicroTimer
	MicroDelay		Micro second (sure. right.) accurate timer
					routine for delays.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	7/30/92		Initial Version


DESCRIPTION:
	These routines involve the appropriation of timer 2.  As timer 0
	is used for the 60Hz multi-tasking clock and timer 1 is used
	for the memory re-fresh cycle, the only timer left to play with
	is timer 2.

	Thus, when using this delay routine, the PC speaker can not be
	used for making sounds.
		

	$Id: soundblasterTimeDelay.asm,v 1.1.20.1 93/05/11 05:44:52 steve Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitMicroTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up timer2 to allow us to do micro-second timing.

CALLED BY:	global

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Alter the timer2 to generate a count by n timer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:`
		Uses timer2, thus making it impossible to use both
		the sound blaster and the PC speaker.  Since it would
		be nice to do so (music on SB, FX on speaker..) it
		might be possible to use timer0.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitMicroTimer	proc	far
	uses	al
	.enter
	mov	al, TT_TIMER_2 or TRL_WORD or TM_RATE_GEN or TC_BINARY
	out	I8253.Mode, al		; set timer 2 to rate-gen counter
	mov	al, 0FFh		; init. timer 2 to value 65536
	out	I8253.Counter2, al
	jmp	$+2			; delay for fast AT
	jmp	$+2
	out	I8253.Counter2, al
	jmp	$+2			; delay for fast AT
	jmp	$+2

	in	al, I8255.portB		; al <- portB settings
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	or	al, 00000001b		; set gate2 high to enable timer2
	and	al, 11111101b		; set spkr_enbl low to turn off PC
	out	I8255.portB, al		; set new values
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer
	.leave
	ret
InitMicroTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MicroDelay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delay for at least a given # of micro seconds

CALLED BY:	global

PASS:		dx	-> # of ticks to wait for

RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		Get current clock value
		poll clock, checking if difference between current
			time and original time is greater than
			the # of ticks to wait for.
		If so, leave, if not, poll again..
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MicroDelay	proc	far
	uses	bx, cx
	.enter
	mov	al, TT_TIMER_2 or TRL_LATCH or TM_RATE_GEN or TC_BINARY
	out	I8253.Mode, al		; latch down current clock time
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	in	al, I8253.Counter2	; read in low byte
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	mov	ah, al			; ah <- lsb of timer
	in	al, I8253.Counter2	; read in high byte
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	xchg	al, ah			; re-order high-low
	mov	bx, ax			; bx <- original time
poleTimer2:
	mov	cx, bx			; save original time
	mov	al, TT_TIMER_2 or TRL_LATCH or TM_RATE_GEN or TC_BINARY
	out	I8253.Mode, al
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	in	al, I8253.Counter2	; read in low byte
	jmp	$+2			; delay for fast computer
	jmp	$+2			; delay for fast computer

	mov	ah, al
	in	al, I8253.Counter2	; read in high byte

	xchg	al, ah			; re-order bytes
	sub	cx, ax			; cx <- cx - ax 
	cmp	cx, dx			; waited longer than delay time?
	jb	poleTimer2		; do again.
	.leave
	ret
MicroDelay	endp


ResidentCode	ends
