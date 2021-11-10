COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PROJECT:  PC GEOS
MODULE:   Mouse Drivers - IntelliMouse-style PS/2 3-button wheel mice
FILE:     imps2.asm

DESCRIPTION:
	Device-dependent support for IntelliMouse PS2 mouse port. The PS2 BIOS
	defines a protocol that all mice connected to the port employ. Rather
	than interpreting it ourselves, we trust the BIOS to be efficient
	and just register a routine with it. Keeps the driver smaller and
	avoids problems with incompatibility etc.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; The following constants are used in mouseCommon.asm -- see that
; file for documentation.
;
MOUSE_HAS_WHEEL		= 1		; define/uncomment this if GEOS 
					; has native wheel support in the kernel/ui, 
					; disable ...HAS_WHEEL_KEYS
;MOUSE_HAS_WHEEL_KEYS	= 1		; define/uncomment this for a version of the driver 
					; that has the wheel simulate keypresses, 
					; disable ...HAS_WHEEL
MOUSE_NUM_BUTTONS		= 3	; Wheel mice have at least 3 buttons
MIDDLE_IS_DOUBLE_PRESS		= 1	; fake double-press with middle button
MOUSE_SEPARATE_INIT		= 1	; We use a separate Init resource

include    ../mouseCommon.asm  		; Include common definitions/code.

include    Internal/interrup.def
include    Internal/dos.def      ; for equipment configuration...
include    system.def

;------------------------------------------------------------------------------
;        DEVICE STRINGS
;------------------------------------------------------------------------------
MouseExtendedInfoSeg  segment  lmem LMEM_TYPE_GENERAL

mouseExtendedInfo  DriverExtendedInfoTable <
	{},                       ; lmem header added by Esp
	length mouseNameTable,    ; Number of supported devices
	offset mouseNameTable,
	offset mouseInfoTable
>

ifdef MOUSE_HAS_WHEEL
	mouseNameTable  lptr.char  	imps2NativeMouse
			lptr.char	0  ; null-terminator

	imps2NativeMouse  chunk.char	'Intellimouse-compatible PS/2 Wheel Mouse', 0

	mouseInfoTable  MouseExtendedInfo  \
			0	; nativeMouse
endif

ifdef MOUSE_HAS_WHEEL_KEYS
	mouseNameTable  lptr.char  	imps2PageMouse,
					imps2CursorMouse
			lptr.char	0  ; null-terminator

	imps2PageMouse    chunk.char	'IM PS/2 Wheel Mouse (Wheel: Page Up/Down)', 0
	imps2CursorMouse  chunk.char	'IM PS/2 Wheel Mouse (Wheel: Cursor Up/Down)', 0

	mouseInfoTable  MouseExtendedInfo  \
			0,	; pageMouse
			0	; cursorMouse
endif

MouseExtendedInfoSeg  ends
ForceRef  mouseExtendedInfo


;------------------------------------------------------------------------------
;          VARIABLES/DATA/CONSTANTS
;------------------------------------------------------------------------------
idata    segment
;
; All the mouse BIOS calls are through interrupt 15h, function c2h.
; All functions return CF set on error, ah = MouseStatus
;
MOUSE_ENABLE_DISABLE	equ	0c200h  ; Enable or disable the mouse. BH = 0 to disable, 1 to enable.
	MOUSE_ENABLE    equ	1
	MOUSE_DISABLE   equ	0

MOUSE_RESET				equ	0c201h  ; Reset the mouse.
	MAX_NUM_RESETS			equ	3       ; # times we will send MOUSE_RESET command
	MOUSE_RESET_RESEND_ERROR	equ	04h     ; Error returned from MOUSE_RESET call if it wants you to resend command

; Set report rate
MOUSE_SET_RATE    equ  0c202h  ; Set sample rate:
	MOUSE_RATE_10	equ	0
	MOUSE_RATE_20	equ	1
	MOUSE_RATE_40	equ	2
	MOUSE_RATE_60	equ	3
	MOUSE_RATE_80	equ	4
	MOUSE_RATE_100	equ	5
	MOUSE_RATE_200	equ	6

; Resolution
MOUSE_SET_RESOLUTION		equ	0c203h  ; Set device resolution BH =
	MOUSE_RES_1_PER_MM	equ	0  ; 1 count per mm
	MOUSE_RES_2_PER_MM	equ	1  ; 2 counts per mm
	MOUSE_RES_4_PER_MM	equ	2  ; 4 counts per mm
	MOUSE_RES_8_PER_MM	equ	3  ; 8 counts per mm

; Device Type
MOUSE_GET_TYPE			equ 0c204h  ; Get device ID.
	MOUSE_ONE_WHEEL		equ 3       ; Device ID returned if Mouse has 1 Wheel

; Init packet size
MOUSE_INIT			equ  0c205h    ; Set interface parameters. BH = # bytes per packet.
	MOUSE_PACKET_SIZE	equ 4          ; We've got at least one wheel, hence 4 bytes!

; extended commands
MOUSE_EXTENDED_CMD		equ  0c206h   ; Extended command. BH =
	MOUSE_EXTC_STATUS	equ 0         ; Get device status
	MOUSE_EXTC_SINGLE_SCALE	equ 1         ; Set scaling to 1:1
	MOUSE_EXTC_DOUBLE_SCALE	equ 2         ; Set scaling to 2:1

; set handler
MOUSE_SET_HANDLER	equ	0c207h  ; Set mouse handler. ES:BX is address of routine

; original GeoWorks definitions
MouseStatus			etype	byte
MS_SUCCESSFUL			enum	MouseStatus, 0
MS_INVALID_FUNC			enum	MouseStatus, 1
MS_INVALID_INPUT		enum	MouseStatus, 2
MS_INTERFACE_ERROR		enum	MouseStatus, 3
MS_NEED_TO_RESEND		enum	MouseStatus, 4
MS_NO_HANDLER_INSTALLED		enum	MouseStatus, 5

mouseRates  byte  10, 20, 40, 60, 80, 100, 200, 255
MOUSE_NUM_RATES  equ  size mouseRates
mouseRateCmds  byte  MOUSE_RATE_10, MOUSE_RATE_20, MOUSE_RATE_40
		byte  MOUSE_RATE_60, MOUSE_RATE_80, MOUSE_RATE_100
		byte  MOUSE_RATE_200, MOUSE_RATE_200

idata    ends

MDHStatus  record
		MDHS_Y_OVERFLOW:1,	; Y overflow
		MDHS_X_OVERFLOW:1,	; X overflow
		MDHS_Y_NEGATIVE:1,	; Y delta is negative (just need to
					; sign-extend, as delta is already in
					; single-byte two's complement form)
		MDHS_X_NEGATIVE:1,	; X delta is negative
		MDHS_MUST_BE_ONE:1=1,
		MDHS_MIDDLE_DOWN:1,	; Middle button is down
		MDHS_RIGHT_DOWN:1,	; Right button is down
		MDHS_LEFT_DOWN:1,	; Left button is down
MDHStatus  end



Resident segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  HandleMem the receipt of an interrupt

CALLED BY:  	BIOS
PASS:    	ON STACK:
RETURN:    	Nothing
DESTROYED:  	Nothing

PSEUDO CODE/STRATEGY:
	Overflow is ignored.

	For delta Y, positive => up, which is the opposite of what we think

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Some BIOSes rely on DS not being altered, while others do not.
	To err on the side of safety, we save everything we biff.

REVISION HISTORY:
	Name  Date    Description
	----  ----    -----------
	ardeb  10/12/89  Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevHandler proc 	far  	:byte,            ; first byte is unused
				:byte,            ; second byte is unused
				deltaZ:sbyte,     ; wheel
				:byte,            ; unused
				deltaY:sbyte,     ; y axis
				:byte,            ; unused
				status:MDHStatus, ; buttons
				deltaX:sbyte      ; x axis

	uses  ds, ax, bx, cx, dx, si, di, es
	.enter

	; Prevent switch while sending
		call	SysEnterInterrupt
	;
	; Store away the wheel info before the action really starts
	; But first make sure we have access to the dgroup
	;
		mov 	ax, segment dgroup
		mov 	ds, ax
		clr	ax
	;
	; Store away the wheel info before the action really starts
	;
		mov 	dh, ss:[deltaZ]
		mov	ds:[wheelData], dh
	;
	; The deltas are already two's-complement, so just sign extend them
	; ourselves.
	; XXX: verify sign against bits in status byte to confirm its validity?
	; what if overflow bit is set?
	;
		mov	al, ss:[deltaY]
		cbw
		xchg	dx, ax      ; (1-byte inst)

		mov	al, ss:[deltaX]
		cbw
		xchg	cx, ax      ; (1-byte inst)

	; Fetch the status, copying the middle and right button bits
	; into BH.
		mov	al, ss:[status]
		test	al, mask MDHS_Y_OVERFLOW or mask MDHS_X_OVERFLOW
		jnz	packetDone  	; if overflow, drop the packet on the
					; floor, since the semantics for such
					; an event are undefined...
		mov	bh, al
		and	bh, 00000110b

	; Make sure the packet makes sense by checking the ?_NEGATIVE bits
	; against the actual signs of their respective deltas. If the two
	; don't match (as indicated by the XOR of the sign bit of the delta
	; with the ?_NEGATIVE bit resulting in a one), then hooey this packet.
		shl	al
		shl	al
		tst	dx
		lahf
		xor	ah, al
		js	packetDone

		shl	al
		tst	cx
		lahf
		xor	ah, al
		js	packetDone

	; Mask out all but the left button and merge it into the
	; middle and right buttons that are in BH. We then have
	;  0000LMR0
	; in BH, which is one bit off from what we need (and also
	; the wrong polarity), so shift it right once and complement
	; the thing.
		and 	al, mask MDHS_LEFT_DOWN shl 3
		or  	bh, al
		shr 	bh, 1
		not 	bh

	; Make delta Y be positive if going down, rather than
	; positive if up, as the BIOS provides it.
		neg	dx

	; Registers now all loaded properly -- send the event.
		call  	MouseSendEvents

packetDone:
		call  SysExitInterrupt

	; Recover and return.
	.leave
	ret

MouseDevHandler  endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  Finish things out

CALLED BY:  MouseExit
PASS:    DS=ES=CS
RETURN:    Carry clear
DESTROYED:  BX, AX

PSEUDO CODE/STRATEGY:
		Just calls the serial driver to close down the port

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name  Date    Description
	----  ----    -----------
	ardeb  5/20/89    Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevExit  proc  near

	; Disable the mouse by setting the handler to 0
	; XXX: How can we restore it? Do we need to?
		mov	ax, MOUSE_ENABLE_DISABLE
		mov	bh, MOUSE_DISABLE    ; Disable it please
		int	15h

		clr	bx
		mov	es, bx
		mov	ax, MOUSE_SET_HANDLER
		int	15h
		ret

MouseDevExit  endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  Turn on the device.

CALLED BY:  DRE_SET_DEVICE
PASS:    dx:si  = pointer to null-terminated device name string
RETURN:    nothing
DESTROYED:  nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name  Date    Description
	----  ----    -----------
	ardeb  9/27/90    Initial version
	ayuen  10/17/00  Moved most of the code to MouseDevInit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetDevice  proc  near  uses es, bx, ax, di, ds
	.enter

ifdef MOUSE_HAS_WHEEL_KEYS
	; fetch and save device variant
	; if it fails, resets "device" to the PAGE variant (which should always work)
		call	MouseSetWheelAction
endif

	; lock BIOS
		call	SysLockBIOS

	; set packet size - must be called first!
		mov	ax, MOUSE_INIT         ; Init mouse
		mov	bh, MOUSE_PACKET_SIZE  ; We've got at least one wheel, hence 4 bytes!
		int	15h

	; strategy for wheel activation used in "InitializeWheel" by Bret E. Johnson
		mov	bh, MOUSE_RATE_200  ; Set Sample rate 200
		mov	ax, MOUSE_SET_RATE
		int	15h
		mov	bh, MOUSE_RATE_100  ; Set Sample Rate 100
		mov	ax, MOUSE_SET_RATE
		int	15h
		mov	bh, MOUSE_RATE_80   ; Set Sample Rate 80
		mov	ax, MOUSE_SET_RATE
		int	15h

	; install handler
		segmov	es, <segment Resident>
		mov 	bx, offset Resident:MouseDevHandler
		mov	ax, MOUSE_SET_HANDLER
		int	15h

	; sampling
		mov	ax, MOUSE_SET_RATE
		mov	bh, MOUSE_RATE_60
		int	15h

	; resolution
		mov	ax, MOUSE_SET_RESOLUTION
		mov	bh, MOUSE_RES_8_PER_MM
		int	15h

	; scaling
		mov	ax, MOUSE_EXTENDED_CMD
		mov	bh, MOUSE_EXTC_SINGLE_SCALE
		int	15h

	; enable
		mov	ax, MOUSE_ENABLE_DISABLE
		mov	bh, MOUSE_ENABLE   ; Enable it please
		int	15h

		call  SysUnlockBIOS

	.leave
	ret
MouseSetDevice  endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  See if the device specified is present.

CALLED BY:  DRE_TEST_DEVICE
PASS:    dx:si  = null-terminated name of device (ignored, here)
RETURN:    ax  = DevicePresent enum
		carry set if string invalid, clear otherwise
DESTROYED:  di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name  Date    Description
	----  ----    -----------
	ardeb  9/27/90    Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseTestDevice  proc  near  uses ax, bx, es, cx

	.enter

	;lock BIOS
		call	SysLockBIOS

	; init to see if (wheel) mouse exists
		mov	ax, BIOS_DATA_SEG
		mov	es, ax
		test	es:[BIOS_EQUIPMENT], mask EC_POINTER
		jz	notPresent

	; packet size
		mov	ax, MOUSE_INIT         ; Init packet size
		mov	bh, MOUSE_PACKET_SIZE  ; We've got at least one wheel, hence 4 bytes!
		int	15h

	;strategy used in "InitializeWheel" by Bret E. Johnson
		mov	bh, MOUSE_RATE_200    ; Set Sample rate 200
		mov	ax, MOUSE_SET_RATE
		int	15h
		mov	bh, MOUSE_RATE_100    ; Set Sample Rate 100
		mov	ax, MOUSE_SET_RATE
		int	15h
		mov	bh, MOUSE_RATE_80     ; Set Sample Rate 80
		mov	ax, MOUSE_SET_RATE
		int	15h

	; check if wheel mouse
		mov	ax, MOUSE_GET_TYPE  ; Get the Device ID in BH
		int	15h
		cmp	bh, MOUSE_ONE_WHEEL ; Is it an intellimouse with one wheel and three buttons?
		jne	notPresent          ; if not, then got to notPresent

	; reset
		mov	cx, MAX_NUM_RESETS  ; # times we will resend this command
resetLoop:
		mov	ax, MOUSE_RESET
		int	15h
		jnc	noerror    ;If no error, branch
		cmp	ah, MS_NEED_TO_RESEND
		jne	notPresent  ;If not "resend" error, just exit with carry set.
		loop	resetLoop

notPresent:
		mov	ax, DP_NOT_PRESENT
		jmp	done

noerror:
		mov	ax, DP_PRESENT

done:
		call	SysUnlockBIOS
		clc
	.leave
	ret

MouseTestDevice  endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetWheelAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  Extract the wheel action

CALLED BY:  MouseDevInit etc
PASS:    dx:si  = device string
DESTROYED:  nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name  	Date    	Description
	----  	----    	-----------
	MeyerK  10/2021  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef MOUSE_HAS_WHEEL_KEYS
MouseSetWheelAction  proc  far  uses cx, di, es, ds
	.enter
	;
	; find driver variant aka "device"
	;
		EnumerateDevice MouseExtendedInfoSeg
	;
	; make sure we have access to the dgroup
	;
		mov	cx, segment dgroup
		mov	ds, cx
	;
	; carry set if EnumerateDevice failed
	;
		jc	error
	;
	; read out and store the driver variant
	; we don't need the complicated setup of ct/ctmabs
	; because the imps2 driver will always be separate
	; from the other drivers and only offer support
	; for wheel mice due to the different byte structure
	; on the event handler...
	;
		cmp	di, 0		; pageMouse
		je	pageKey
		cmp	di, 2		; cursorMouse
		je	cursorKey
pageKey:
		mov	ds:[driverVariant], MOUSE_WHEEL_ACTION_PAGE
		jmp 	finish
cursorKey:
		mov	ds:[driverVariant], MOUSE_WHEEL_ACTION_CURSOR

finish:
	;
	; release the info block that has been locked by EnumerateDevice...
	;
		call	MemUnlock
		jmp	exit
error:
	;
	; if error, set device index back to 0
	;
		mov	ds:[driverVariant], MOUSE_WHEEL_ACTION_PAGE
exit:
	.leave
	ret
MouseSetWheelAction  endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevSetRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  Set the report rate for the mouse

CALLED BY:  MouseSetRate
PASS:    CX  = index of rate to set
RETURN:    carry clear if successful
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name  Date    Description
	----  ----    -----------
	ardeb  10/12/89  Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevSetRate  proc  near

		push  ax, bx, cx, si
		mov  si, cx
		mov  bh, ds:mouseRateCmds[si]
		mov  ax, MOUSE_SET_RATE
		int  15h
		pop  ax, bx, cx, si
		ret

MouseDevSetRate  endp

Resident ends

end
