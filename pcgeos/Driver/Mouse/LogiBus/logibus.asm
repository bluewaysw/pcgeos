COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Logitech Bus Mouse device-dependent code
FILE:		logibus.asm

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
	Input for the Logitech Bus Mouse. Accesses the device directly
	every clock tick, reading the state of the counters and generating
	an event if they're non-zero.

	$Id: logibus.asm,v 1.1 97/04/18 11:47:56 newdeal Exp $
------------------------------------------------------------------------------@

MOUSE_NUM_BUTTONS	= 3

MOUSE_SEPARATE_INIT	= 1	; We use a separate Init resource

include		../mouseCommon.asm
include		localize.def
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
MOUSE_CONFIG_PORT	= 23fh	; Configuration for 8255
MOUSE_CONFIG_BYTE	= 91h	; From technical spec. I don't know what
				; it means.
MOUSE_CTRL_PORT		= 23eh	; Control port. Bits are:
				; 0-3 unused
				; 4 Interrupt enable (active low(?))
				; 5 High/Low nibble selector
				; 6 X/Y counter selector
				; 7 Counter latch (active high)
MOUSE_HC		= 80h
MOUSE_X			= 00h
MOUSE_Y			= 40h
MOUSE_HIGH		= 20h
MOUSE_LOW		= 00h
MOUSE_NO_INT		= 10h
MOUSE_IEN		= 00h
MOUSE_SIG_PORT		= 23dh	; Signature port. Usually a5, but can be
				;  altered.
MOUSE_STANDARD_SIG	= 0xa5	; Standard signature.
MOUSE_DATA_PORT		= 23ch	; Data port. Low four bits are a nibble from
				; one of the counters (selected by <5:6> in
				; the CTRL_PORT). High four bits are button
				; state with a 0 indicating the button is
				; pressed.

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

mouseNameTable	lptr.char	logiBus,
				oldMSBus,
				logiBusTM,
				otherBM,
				logiBusHR,
				atiWonder
		lptr.char	0	; null-terminator

LocalDefString	logiBus,	<'Logitech Bus Mouse', 0>
LocalDefString	oldMSBus,	<'Microsoft Bus Mouse (large 9-pin plug)', 0>
LocalDefString	logiBusTM,	<'Logitech Bus Trackball', 0>
LocalDefString	otherBM,	<'Other Bus Mouse', 0>
LocalDefString	logiBusHR,	<'Logitech Hi-Rez Bus Mouse', 0>
LocalDefString	atiWonder,	<'ATI VGA Wonder+ Bus Mouse', 0>

; no special flags for these, as they're not serial, and we don't need an
; interrupt for them...
mouseInfoTable	MouseExtendedInfo	\
		0,	; logiBus
		0,	; oldMSBus
		0,	; logibusTM
		0,	; otherBM
		0,	; logibusHR
		0	; atiWonder

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
	Initialize the mouse (turning off interrupts from it)
	Start our polling timer

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	3/10/89		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevInit	proc	far	uses dx, ax, cx, si, bx
		.enter
		INT_OFF
	;
	; Turn off interrupts from the mouse -- we'll do it ourselves
	; based on the clock.
	;
		mov	dx, MOUSE_CTRL_PORT
		mov	al, MOUSE_NO_INT
		out	dx, al
		
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
	; Change ownership to us so the timer stays around while
	; we do...
	;
		mov	ax, handle 0
		call	HandleModifyOwner
		clc			; no error
		INT_ON		; All set -- reenable
		.leave
		ret
MouseDevInit	endp

Init		ends

Resident	segment	resource


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
		; The LogiTech driver apparently assumes that once it's
		; enabled the interrupts for the mouse, they'll never be
		; turned off. To make sure the mouse works when we leave
		; PC GEOS, turn the interrupts back on...
		; 
		INT_OFF
		mov	dx, MOUSE_CTRL_PORT
		mov	al, MOUSE_IEN
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
		INT_OFF		; INTS off while we configure...
	;
	; Send configuration byte to configuration port. These are
	; constant and their meaning is unknown. I think this needs
	; to be done before the signature port is mangled so the
	; poor chip knows what port is what...
	;
		mov	dx, MOUSE_CONFIG_PORT
		mov	al, MOUSE_CONFIG_BYTE
		out	dx, al

	;
	; Make sure the thing is *not* a microsoft bus mouse. That mouse
	; uses MOUSE_SIG_PORT as the data port for its register file. Since
	; it usually leaves the file pointing to its control register, writing
	; random stuff there is an unhappy thing to do. To detect a microsoft
	; bus mouse, just try writing a 0 to 23c. If the 0 stays, it's
	; most likely not a logibus...
	;
		mov	dx, MOUSE_DATA_PORT
		clr	al
		out	dx, al
		jmp	$+2
		in	al, dx
		tst	al
		jz	absent
	;
	; Make sure the thing actually is out there.
	;
		mov	dx, MOUSE_SIG_PORT
		mov	al, MOUSE_STANDARD_SIG
		out	dx, al
		jmp	$+2
		in	al, dx
		cmp	al, MOUSE_STANDARD_SIG
		jne	absent
		mov	ax, DP_PRESENT
done:
		clc
		INT_ON
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
	; Change ownership to us so the timer stays around while
	; we do...
	;
		mov	ax, handle 0
		call	HandleModifyOwner
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
		mov	si, MOUSE_CTRL_PORT
		mov	di, MOUSE_DATA_PORT
control_port	equ	<si>
data_port	equ	<di>
		;
		; Latch the counters and set up to fetch high nibble of deltaX.
		; Also clears AH.
		;
		mov	dx, control_port
		mov	ax, MOUSE_HC OR MOUSE_X OR MOUSE_HIGH OR MOUSE_NO_INT
		out	dx, al

		;
		; Fetch buttons and high nibble of X
		;
		mov	dx, data_port
		in	al, dx
		;
		; Nibble-swap
		;
		mov	cl, 4
		shl	ax, cl			; Get button state in AH,
						; high nibble in high nibble
						; of AL
		mov	bx, ax			; Preserve both
		;
		; Fetch the low nibble
		;
		mov	dx, control_port
		mov	al, MOUSE_HC OR MOUSE_X OR MOUSE_LOW OR MOUSE_NO_INT
		out	dx, al
		mov	dx, data_port
		in	al, dx
	
		and	al, 0fh			; Clear high nibble
		or	bl, al			; Merge in with high nibble
		;
		; Set to read high nibble of deltaY
		;
		mov	dx, control_port
		mov	al, MOUSE_HC OR MOUSE_Y OR MOUSE_HIGH OR MOUSE_NO_INT
		out	dx, al
		mov	dx, data_port
		in	al, dx

		;
		; Shift high nibble into high nibble of AH. Since high nibble
		; of AH is clear (button state only in low nibble and we
		; cleared AH up above), we don't need to clear anything.
		; CL still contains 4.
		;
		ror	ax, cl
		;
		; Fetch low nibble
		;
		mov	dx, control_port
		mov	al, MOUSE_HC OR MOUSE_Y OR MOUSE_LOW OR MOUSE_NO_INT
		out	dx, al
		mov	dx, data_port
		in	al, dx
		
		and	al, 0fh
		or	ah, al

		;
		; Release the latches but keep interrupts off
		;
		mov	dx, control_port
		mov	al, MOUSE_NO_INT
		out	dx, al

		;
		; Shift buttons into proper position (starting at b0, not b1)
		;
		shr	bh, 1
		or	bh, NOT 111b	; Make sure unsupported buttons are UP

		;
		; Sign-extend deltaY (in AH) and transfer to DX for M.S.E.
		;
		mov	al, ah
		cbw
		mov	dx, ax
		;
		; Sign-extend deltaX (in BL) and place in CX for M.S.E.
		;
		mov	al, bl
		cbw
		mov	cx, ax

		call	MouseSendEvents

MDH_exit:
		inc	ds:[reentrantFlag]	; we're out of here

		pop	si, di, ds
		ret
MouseDevHandler	endp


Resident ends

		end
