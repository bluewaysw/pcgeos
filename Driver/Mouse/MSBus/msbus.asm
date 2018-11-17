COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Microsoft Bus Mouse (non-8255 version)
		device-dependent code
FILE:		msbus.asm

AUTHOR:		Adam de Boor

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Initialize device
	MouseDevExit		Exit device

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/89		Initial version
	Adam	3/24/89		Converted to new driver format

DESCRIPTION:
	Input for the Microsoft Bus Mouse. Accesses the device directly
	every clock tick, reading the state of the counters and generating
	an event if they're non-zero.
	
	There appear to be two versions of the microsoft bus mouse. One is
	based on the 8255 chip and can be run with the logibus driver. A
	second-generation version, however, uses a custom chip (and precious
	little else) whose registers etc. I've attempted to reverse-engineer.

	$Id: msbus.asm,v 1.1 97/04/18 11:48:01 newdeal Exp $
------------------------------------------------------------------------------@

MOUSE_NUM_BUTTONS	= 2
MOUSE_SEPARATE_INIT	= 1	; We use a separate Init resource

include		../mouseCommon.asm
include 	timer.def

;
; Additional error code(s)
;
MOUSE_REPORT_RATE_ZERO enum FatalErrors

;------------------------------------------------------------------------------
;
;			 BUS MOUSE CONSTANTS
;
;------------------------------------------------------------------------------
MOUSE_ADDR_PORT		= 23ch	; "Address" port, similar to that used on a
				;  6845. Contains the register number to be
				;  accessed via MOUSE_DATA_PORT. Known
				;  registers are:
				;  	0	buttons, et al:
				;		bit 0	right
				;		bit 1	?
				;		bit 2	left
				;		bit 3	<used>
				;		bit 4	?
				;		bit 5	<used w/bit 2>
				;		bit 6
				;		bit 7
				;	1	deltaX (two's complement)
				;	2	deltaY
				;	7	control
				;		bit 0
				;		bit 1
				;		bit 2
				;		bit 3	interrupt enable
				;		bit 4
				;		bit 5	latch counters
				;		bit 6
				;		bit 7	disable mouse

MOUSE_STATUS	= 0
MOUSE_DELTAX	= 1
MOUSE_DELTAY	= 2
MOUSE_CONTROL	= 7

MOUSE_DATA_PORT		= 23dh
;
; Register definitions
;
MouseStatus	record :5, MMS_LEFT:1, :1, MMS_RIGHT:1
MouseControl	record MMC_DISABLE:1, :1, MMC_LATCH:1, :1, MMC_IEN:1, :3


;------------------------------------------------------------------------------
;				DEVICE STRINGS
;------------------------------------------------------------------------------
MouseExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

mouseExtendedInfo	DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		length mouseNameTable,		; Number of supported devices
		offset mouseNameTable,
		offset mouseInfoTable
>

mouseNameTable	lptr.char	newMSBus
		lptr.char	0

LocalDefString newMSBus	<'Microsoft Bus Mouse (circular plug)', 0>

; no special flags for these, as they're not serial, and we don't need an
; interrupt for them...
mouseInfoTable	MouseExtendedInfo	\
		0	; newMSBus

MouseExtendedInfoSeg	ends
		


;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

;
;	Store the handle of the timer used to get calls every tick
;
timerHandle	word

reentrantFlag	byte	1		; Kind of like a semaphore.  If
					; 1, we can go ahead & poll the
					; mouse.  If  not, we skip the poll.
					; Is decremented on entry to
					; MouseDevHandler, inc'd on exit.
					; Used to keep us from performing
					; reentrant reads of the mouse.

initIEN		MouseControl		; Initial control register so we can
					;  restore IEN to its initial state
;
; Table of available rates. Must be in ascending order.
;
mouseRates	byte	10, 12, 15, 20, 30, 60, 255
MOUSE_NUM_RATES	equ	size mouseRates
;
; Clock ticks for timer corresponding to each rate. note that "continuous"
; is still 60 times/second only.
;
mouseTicks	byte	6, 5, 4, 3, 2, 1, 1
idata		ends

MOUSE_DELAY	=	1		; # ticks between polls


Init segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the device

CALLED BY:	MouseInit

PASS:		es=ds=dgroup

RETURN:		carry	- set on error

DESTROYED:	di

PSEUDO CODE/STRATEGY:
	Start our polling timer
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	3/10/89		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevInit	proc	far	uses dx, ax, cx, si, bx
		.enter
	;
	; Disable interrupts for the mouse while we're operating.
	;
		INT_OFF
		mov	dx, MOUSE_ADDR_PORT
		mov	al, MOUSE_CONTROL
		out	dx, al
		inc	dx
		in	al, dx
		mov	ds:[initIEN], al
		andnf	al, not (mask MMC_IEN or mask MMC_DISABLE)
		out	dx, al
		INT_ON

	;
	; Turn on the timer so we read the mouse...
	;
		mov	ax,TIMER_ROUTINE_CONTINUAL
		mov	bx, segment Resident
		mov	si,offset Resident:MouseDevHandler
		mov	cx,MOUSE_DELAY
		mov	di,cx
		call	TimerStart
		mov	ds:[timerHandle],bx
	;
	; Change ownership to us so the timer stays while we do
	;
		mov	ax, handle 0
		call	HandleModifyOwner
		
		clc			; no error
		.leave
		ret
MouseDevInit	endp

Init		ends

Resident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves

CALLED BY:	MouseExit

PASS:		Nothing

RETURN:		carry	- set on error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/8/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevExit	proc	far
		clr	bx
		xchg	bx,ds:[timerHandle]
		tst	bx		; were we initialized?
		jz	done		; no
		clr	ax		; 0 => continual
		call	TimerStop
	;
	; Restore interrupts to their initial condition.
	;
		INT_OFF
		mov	dx, MOUSE_ADDR_PORT	; point to control register
		mov	al, MOUSE_CONTROL
		out	dx, al

		inc	dx
		in	al, dx			; fetch current status
		mov	ah, ds:[initIEN]
		andnf	ah, mask MMC_IEN or mask MMC_DISABLE
		or	al, ah			; merge in initial IEN and
						;  DISABLE bits
		out	dx, al
		INT_ON

done:
		clc				; No errors
		ret
MouseDevExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on the device.

CALLED BY:	DRE_SET_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Just call the device-initialization routine in Init		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetDevice	proc	near
		.enter
		call	MouseDevInit
		.leave
		ret
MouseSetDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the device specified is present.

CALLED BY:	DRE_TEST_DEVICE	
PASS:		dx:si	= null-terminated name of device (ignored, here)
RETURN:		ax	= DevicePresent enum
		carry set if string invalid, clear otherwise
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseTestDevice	proc	near	uses dx
		.enter
	;
	; Disable interrupts for the mouse while we're operating.
	;
		INT_OFF

		;
		; First see if the mouse be out there by setting the
		; address port to 1. If it stays 1, assume the mouse be
		; out there. This should rule out logibus...
		; 
		mov	dx, MOUSE_ADDR_PORT
		mov	al, 1
		out	dx, al
		jmp	$+2
		in	al, dx
		cmp	al, 1
		jnz	absent
		mov	ax, DP_PRESENT
done:
		INT_ON
		clc
		.leave
		ret
absent:
		mov	ax, DP_NOT_PRESENT
		jmp	done
MouseTestDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevSetRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the report rate for the mouse. For the bus mouse,
		running off the timer interrupt, this can't be more
		than 60 reports a second. There's not a whole lot of
		point in doing this, of course, since we can only do
		things like 60, 30, 20, 15, 12... All but 60 produce
		a strange double-mouse effect (sort of like a binary star).

CALLED BY:	MouseSetRate
PASS:		DS	= dgroup
		CX	= index of desired rate
RETURN:		Nothing
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevSetRate	proc	far
		push	bx, si, cx, dx
		;
		; Shut off the timer first so we can restart it with the 
		; (potentially) different rate.
		;
		mov	bx, ds:[timerHandle]
		clr	ax		; 0 => continual
		call	TimerStop

		;
		; Set the interval into CX (initial delay) and DX (interval),
		; point BX:SI at the handler and start the timer going again.
		; 
		mov	si, cx
		mov	cl, ds:mouseTicks[si]
		mov	dx, cx

		mov	bx, segment Resident
		mov	si, offset Resident:MouseDevHandler
		mov	ax, TIMER_ROUTINE_CONTINUAL
		call	TimerStart
		;
		; Save the handle for exit etc.
		;
		mov	ds:[timerHandle], bx
		pop	bx, si, cx, dx
		clc
		ret
MouseDevSetRate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	mouse handler routine

CALLED BY:	Timer interrupt

PASS:
RETURN:		Nothing

DESTROYED:	May nuke AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

		
KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/10/89		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevHandler	proc	far
		push	si, di, ds	; Needed for event sending

		mov	si, dgroup
		mov	ds, si

		dec	ds:[reentrantFlag]	; enter "semaphore"
		js	MDH_exit		; as long as we aren't
						; re-entering this code,
						; continue.
		;
		; Faster to mov dx, si than mov dx, MOUSE_CTRL_PORT. Since
		; we need to preserve SI and DI anyway, might as well use them
		; for something...
		; 
		mov	si, MOUSE_ADDR_PORT
		mov	di, MOUSE_DATA_PORT
addr_port	equ	<si>
data_port	equ	<di>

		;
		; Latch counters and buttons
		;
		mov	al, MOUSE_CONTROL
		mov	dx, addr_port
		out	dx, al
		mov	dx, data_port
		in	al, dx
		andnf	al, not mask MMC_LATCH	; Clear the LATCH bit in
						;  case it's already set,
						;  for whatever reason.
		mov	bl, al
		ornf	al, mask MMC_LATCH
		out	dx, al
		
		;
		; Fetch deltaX
		;
		mov	al, MOUSE_DELTAX
		mov	dx, addr_port
		out	dx, al
		mov	dx, data_port
		in	al, dx
		cbw
		mov	cx, ax
		;
		; Fetch deltaX
		;
		mov	al, MOUSE_DELTAY
		mov	dx, addr_port
		out	dx, al
		mov	dx, data_port
		in	al, dx
		cbw
		push	ax		; Save for transfer to DX
		;
		; Fetch buttons
		;
		mov	al, MOUSE_STATUS
		mov	dx, addr_port
		out	dx, al
		mov	dx, data_port
		in	al, dx
		;
		; Clear all but the two buttons the mouse has (they're in the
		; proper positions already), shift the buttons to BH for
		; M.S.E., then invert all the bits, since M.S.E. wants 0 =>
		; down. This ensures that all unsupported buttons are 
		; considered up at all times.
		;
		and	al, mask MOUSE_B0 or mask MOUSE_B2
		mov	bh, al
		not	bh
		
		;
		; Release counters
		;
		mov	al, MOUSE_CONTROL
		mov	dx, addr_port
		out	dx, al
		mov	al, bl		; recover control bits
		mov	dx, data_port
		out	dx, al

		pop	dx		; recover deltaY

		call	MouseSendEvents

MDH_exit:
		inc	ds:[reentrantFlag]	; we're out of here

		pop	si, di, ds
		ret
MouseDevHandler	endp


Resident ends

		end
