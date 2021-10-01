COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Common code
FILE:		mouse.asm

AUTHOR:		Adam de Boor, March 24, 1989

ROUTINES:
	Name			Description
	----			-----------
	DriverStrategy		Driver strategy routine

	routines internal to driver:

	MouseInit		Initialize the driver
	MouseExit		Deinitialize the driver
	MouseSetRate		Set the mouse reporting rate.
	MouseGetRates		Return table of available report rates.
	MouseSendEvents		Accepts mouse change and sends events
	MouseGetAcceleration	Fetches current mouse acceleration factors
	MouseSetAcceleration	Allows setting of mouse acceleration

	routines required of device-specific code:

	MouseDevExit		Deinitialize the device.
	mouseRates		byte-table of available report rates, in
				ascending order. Should end with 255 so
				ridiculously high report rates can be handled.
				Such a thing should be interpreted as
				"continuous", probably.
	MOUSE_NUM_RATES		length of same.
	MouseDevSetRate		Set the report rate for the mouse. CX contains
				the index into mouseRates of the rate to use.

	MouseTestDevice		See if the requested device is present.

	MouseSetDevice		Configure driver to support the indicated
				device. MouseTestDevice will have been called,
				so MouseSetDevice can assume the device is
				present.

	MouseExtendedInfo	Resource containing a DriverExtendedInfoTable
				for the driver.

	configuration constants that control how code is compiled:

	MOUSE_CANT_SET_RATE	If defined, MouseSetRate will return an
				error, so MouseDevSetRate needn't be defined.
	MOUSE_DONT_ACCELERATE	If defined, MouseSendEvents will not apply
				acceleration to the mouse deltas.
	MOUSE_SEPARATE_INIT	If defined, driver has a separate Init resource
				into which MouseInit can be put.
	MOUSE_USES_ABSOLUTE_DELTAS
				If defined, inverts sense of EC code in
				MouseCombineEvent, makes MouseSendEvents
				assume pointer position always passed.
	MOUSE_COMBINE_DISCARD	If defined,causes MouseCombineEvent to just
				discard any new event if a IM_PTR_CHANGE event
				is already in the IM's queue.
	MOUSE_CANT_TEST_DEVICE	If defined, this file will define a trivial
				MouseTestDevice that tells the caller the
				driver is unable to determine if the device
				is present.

	MOUSE_CAN_BE_CALIBRATED	If defined, this file will not define the
				trivial calibration stubs, and instead will
				allow the specific driver to define those
				functions:
					MouseGetCalibrationPoints
					MouseSetCalibrationPoints
					MouseGetRawCoordinate

	MOUSE_PTR_FLAGS		PtrFlags that mouse driver wants to
				set when starting up.

	MOUSE_SUPPORT_MOUSE_COORD_BUFFER
				If defined, driver supports escape functions
				to return mouse co-ordinates in a buffer.
				Driver must include (using DefFarEscape) the
				common routines provided here in its own
				escape table.

	MOUSE_STORE_FAKE_MOUSE_COORDS
				If defined, the driver stores fake mouse
				coords in the coord buffer and sends off
				a MSG_IM_READ_DIGITIZER_COORDS after each
				fake coord is stored. This depends on
				MOUSE_SUPPORT_MOUSE_COORD_BUFFER also being
				defined. This is useful if you want to use
				the GenMouse driver to simulate collecting
				the mouse coords on a PC demo.
				You may also want to modify
				Kernel/IM/imPen.asm::StoreDigitizerCoords
				to convert the fake coords into simulated
				digitizer coords based on the current
				pointer screen position.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/89		Initial version

DESCRIPTION:
	Boiler-plate code for all mouse drivers. The idea here is to provide
	the interface to the system via the functions in this file. Each
	specific type of mouse will have its own device-dependent file
	that initializes, turns off and reads the state changes for that
	device. State changes are communicated to the system via the
	MouseSendEvents function.

	The device-dependent file includes this one.

	$Id: mouseCommon.asm,v 1.1 97/04/18 11:47:58 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			  SYSTEM DEFINITIONS
;------------------------------------------------------------------------------


_MouseDriver		=	1

;--------------------------------------
;	Include files
;--------------------------------------

include geos.def
include heap.def
include lmem.def		; for extended driver info segment
include geode.def
include resource.def
include ec.def
include assert.def
include driver.def
include initfile.def
include char.def
include timer.def

include input.def
include timedate.def
include sem.def

include Internal/im.def
include Internal/heapInt.def
include Internal/interrup.def
UseDriver Internal/kbdMap.def
UseDriver Internal/kbdDr.def
DefDriver Internal/mouseDr.def

	.ioenable	; Tell Esp to let us use I/O instructions

;------------------------------------------------------------------------------
;			CONSTANTS/DECLARATIONS
;------------------------------------------------------------------------------

DEBUG_COMBINE		=	FALSE

				; THESE are currently not generated. Looking
				; for bug.
MOUSE_ABS_MOUSE_CHANGE			enum FatalErrors
COMMAND_UNKNOWN				enum FatalErrors
ALREADY_INITIALIZED			enum FatalErrors
ALREADY_EXITED				enum FatalErrors

MOUSE_DEVICE_CANNOT_BE_CALIBRATED	enum Warnings

ifndef MOUSE_PTR_FLAGS
    ; By default -- turn OFF all PtrFlags
    MOUSE_PTR_FLAGS = PtrFlags shl 8
endif

;
; State flags
;
MouseStratFlags	record	MOUSE_ON:1, MOUSE_SUSPENDING:1

;
; These are the bits expected by MouseSendEvents for the current state of
; the mouse buttons. A 1 implies the button is up. This record is in the
; "wrong" order because of historical inertia.
;
MouseButtonBits record MOUSE_B3:1=1, MOUSE_B0:1=1, MOUSE_B1:1=1, MOUSE_B2:1=1



;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata		segment

ifndef	MOUSE_FLAGS
	MOUSE_FLAGS equ 0		; If not specified, no flags.
endif

;
; Driver information table. Mouse driver tables are followed by the number
; of buttons supported by the mouse, and the digitizer resolution (or 0,0 if
; the driver is for a mouse).
;

ifndef	DIGITIZER_X_RES
DIGITIZER_X_RES	equ	0
DIGITIZER_Y_RES	equ	0
endif

DriverTable	MouseDriverInfoStruct	<
	<
	    <
	        MouseStrategy,
		mask DA_HAS_EXTENDED_INFO,
		DRIVER_TYPE_INPUT
	    >,
	    MouseExtendedInfoSeg	; Specify resource of extended info
					;  for the driver
	>,
	MOUSE_NUM_BUTTONS,

	DIGITIZER_X_RES,		;The resolution if driver is for
	DIGITIZER_Y_RES,		; a digitizer
	MOUSE_FLAGS
>
ForceRef	DriverTable

mouseStratFlags	MouseStratFlags	<0>	; Flags for strategy routine
mouseButtons	MouseButtonBits <>	; Assume all buttons up
mouseAccelThreshold	word	5	; Pixels/report threshold
mouseAccelMultiplier	word	1	; Multiplier past threshold
					; (Default is 1:1, in case mouse
					; itself does something...)
		even

mouseLastDeltaX	word	0x8000
mouseLastDeltaY	word	0x8000

ifdef MOUSE_USES_ABSOLUTE_DELTAS
mouseLastX	word	-1		; Variables for determining if pointer
mouseLastY	word	-1		;  has moved since last call.
endif

ifndef MOUSE_DONT_ACCELERATE
; Variables for handling acceleration for relative device drivers.
; When accelerating, if current ptr event happens soon enough after the previous
; ptr event, the new raw deltas are added to the previous raw deltas and the
; result accelerated. The previous accelerated deltas are subtracted from
; the result and the difference is sent as the IM_PTR_CHANGE event.
; The timestamp is set to the new event, so continual motion all gets
; accelerated, but it's *not* accelerated exponentially (though some might
; like that, and it could be arranged...)
mouseLastTime	word	0		; Time stamp of previous ptr event
mouseRawDeltaX	word	0		; Change in X of previous ptr event
mouseRawDeltaY	word	0		; Change in Y of previous ptr event
mouseAccDeltaX	word	0		; Accelerated deltaX
mouseAccDeltaY	word	0
endif

;
; Table of handler routines for use by MouseStrategy
;
mouseHandlers	nptr.near Resident:MouseInit		; DR_INIT
		nptr.near Resident:MouseExit		; DR_EXIT
		nptr.near Resident:MouseSuspend		; DR_SUSPEND
		nptr.near Resident:MouseUnsuspend	; DR_UNSUSPEND
		nptr.near Resident:MouseTestDevice
		nptr.near Resident:MouseSetDevice
		nptr.near Resident:MouseSetRate		; DR_MOUSE_SET_RATE
		nptr.near Resident:MouseGetRates	; DR_MOUSE_GET_RATES
		nptr.near Resident:MouseSetAcceleration	; DR_MOUSE_SET_ACCELERATION
		nptr.near Resident:MouseGetAcceleration	; DR_MOUSE_GET_ACCELERATION
		nptr.near Resident:MouseSetCombineMode 	; DR_MOUSE_SET_COMBINE_MODE
		nptr.near Resident:MouseGetCombineMode 	; DR_MOUSE_GET_COMBINE_MODE
		nptr.near Resident:MouseGetCalibrationPoints
		nptr.near Resident:MouseSetCalibrationPoints
		nptr.near Resident:MouseGetRawCoordinate
		nptr.near Resident:MouseChangeOutput	; only in BULLET on...
		nptr.near Resident:MouseStartCalibration
		nptr.near Resident:MouseStopCalibration

;
; Process to which events should be sent
;
mouseOutputHandle hptr	0

mouseCombineMode	MouseCombineMode	MCM_COMBINE

noStoreDeltasFlag		byte	0

if	DEBUG_COMBINE
combineCount		word
noCombineCount		word
endif

idata		ends

udata	segment

oldPtrFlags	PtrFlags



ifdef	MOUSE_SUPPORT_MOUSE_COORD_BUFFER

mouseCoordBuf		sptr.MouseCoordsCircularBufferStruct	NULL

curStrokeDropped	BooleanByte	; true if the current stroke has been
					;  truncated or totally dropped.  It
					;  happens if the buffer was full
					;  sometime earlier in the middle of
					;  this stroke.

prevEventIsPenUp	byte		; zero if the previous event is
					;  pen-down/move, non-zero if pen-up.
					;  Initialized when the very first
					;  event is stored into buffer.

endif	; MOUSE_SUPPORT_MOUSE_COORD_BUFFER

ifdef	MOUSE_STORE_FAKE_MOUSE_COORDS
leftButtonDown		BooleanByte	; true if the left mouse button is
					; currently down.
endif	; MOUSE_STORE_FAKE_MOUSE_COORDS


udata	ends


Resident segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse driver strategy routine

CALLED BY:	EXTERNAL

PASS:		di	- DR_MOUSE?  command code.  Operation & other data
		passed, returned depends on command.  Current operations are:


	-----------------------------------------------------------
	PASS:	di	- DR_INIT
		cx:dx	- parameter string

	RETURN: carry clear, for no error

	-----------------------------------------------------------
	PASS:	di	- DR_EXIT

	RETURN: carry clear, for no error


	-----------------------------------------------------------
	PASS:	di	- DR_TEST_DEVICE
		dx:si	- pointer to null-terminated device name string

	RETURN: ax	- DriverPresent code


	-----------------------------------------------------------
	PASS:	di	- DR_SET_DEVICE
		dx:si	- pointer to null-terminated device name string

	RETURN: nothing



	-----------------------------------------------------------
	PASS:	di	- DR_MOUSE_SET_RATE
		cx	- desired report rate (# reports per second)

	RETURN:	carry clear, for no error
		cx	- actual report rate for mouse.

	-----------------------------------------------------------
	PASS:	di	- DR_MOUSE_GET_RATES

	RETURN:	carry clear, for no error
		es:di	- table of available rates (bytes)
		cx	- length of table

DESTROYED:	Depends on function, though best to assume all registers
		that are not returning a value
		(Segment registers are preserved)
		Only BP, DS, ES are preserved.

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/10/89		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseStrategy	proc	far
		push	bp, ds, es
		mov	bp, dgroup
		mov	ds, bp
		mov	es, bp

		HandleFarEscape	mouse, MS_Done

		cmp	di, MouseFunction	; Beyond last mouse function?
		ja	MS_Unknown		; yup

		;
		; Call the handler...
		;
		call	ds:mouseHandlers[di]

MS_Done:
		pop	bp, ds, es
		ret

MS_Unknown:
EC <		ERROR	COMMAND_UNKNOWN					>
NEC <		stc			; error -- undefined command	>
NEC <		jmp	MS_Done						>
MouseStrategy	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the module

CALLED BY:	MouseStrategy

PASS:		es=ds=dgroup

RETURN:		carry	- set on error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Initialize device-independent state.
	Call MouseDevInit to initialize the device-dependent stuff.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	3/10/89		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef MOUSE_SEPARATE_INIT
MouseInit	proc	near
		call	MouseRealInit
		ret
MouseInit	endp

startinitfunc	equ	<MouseRealInit proc far>
endinitfunc	equ	<MouseRealInit endp>

Init		segment	resource

else

startinitfunc	equ	<MouseInit proc near>
endinitfunc	equ	<MouseInit endp>

endif

inputCategoryStr	char	"input", 0
accelThresholdStr	char	"mouseAccelThreshold", 0
accelMultiplierStr	char	"mouseAccelMultiplier", 0

startinitfunc
		;
		; See if we've already been initialized.
		;
		test	ds:mouseStratFlags, MASK MOUSE_ON
		jnz	MIError

		mov	ax, MOUSE_PTR_FLAGS
		call	ImSetPtrFlags
		mov	ds:[oldPtrFlags], al

		;
		; Fetch the process handle of the input manager and squirrel
		; it away.
		;
		call	ImInfoInputProcess
		mov	ds:mouseOutputHandle, bx
		;
		; Make sure mouseButtons is initialized to all UP
		;
		mov	ds:mouseButtons, MouseButtonBits

		mov	dx, offset cs:[accelThresholdStr]
		call	FetchIniInteger
		jc	afterAccelThreshold
		mov	ds:[mouseAccelThreshold], ax
afterAccelThreshold:
		mov	dx, offset cs:[accelMultiplierStr]
		call	FetchIniInteger
		jc	afterAccelMultiplier
		mov	ds:[mouseAccelMultiplier], ax
afterAccelMultiplier:

		;
		; Note that the driver's initialized
		;
		or	ds:mouseStratFlags, MASK MOUSE_ON	; (clc)
		ret
MIError:
EC <		ERROR	ALREADY_INITIALIZED				>
NEC <		stc							>
NEC <		ret							>
endinitfunc


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchIniInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetches an integer value from .ini file

CALLED BY:	MouseInit

PASS:		cs:dx	- ptr to integer field string

RETURN:		carry	- clear if integer found
		ax	- integer

DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
	Does nothing for now

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/9/90		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FetchIniInteger	proc	near
						;cs:dx is ptr to field string
		push	ds
		segmov	ds, cs, cx		; ds, cx <- cs
		mov	si, offset cs:[inputCategoryStr]
		call	InitFileReadInteger	;ax <- integer value
		pop	ds
		ret
FetchIniInteger	endp

ifdef	MOUSE_SEPARATE_INIT
Init		ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves

CALLED BY:	MouseStrategy

PASS:		ds - dgroup

RETURN:		carry	- set on error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Does nothing for now

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	6/8/88		Initial Revision
	adam	3/24/89		Adapted to common-code format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseExit	proc	near
		;
		; Make sure we've been initialized
		;
		test	ds:mouseStratFlags, MASK MOUSE_ON
		jz	MEError		; Choke

		; Set the ptr flags to what they were initially
		;
		mov	al, ds:[oldPtrFlags]
		mov	ah, al
		not	ah
		call	ImSetPtrFlags

		;
		; Turn off the device
		;
		call	MouseDevExit
		jc	MEErrorRet

		;
		; Note that the driver is off
		;
		and	ds:mouseStratFlags, NOT MASK MOUSE_ON
		clc				; No errors
		ret
MEError:
EC <		ERROR	ALREADY_EXITED					>
NEC <		stc							>
MEErrorRet:
		ret
MouseExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off the mouse for the duration of our stasis

CALLED BY:	DR_SUSPEND
PASS:		cx:dx	= buffer to fill with error message
		ds	= dgroup (from MouseStrategy)
RETURN:		carry set if couldn't suspend
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSuspend	proc	near
		; MouseExit can destroy ax, bx, cx, dx, si, di, ds, es
		; we can destroy ax, di
		uses	bx, cx, dx, si, ds, es
		.enter

		BitSet	ds:[mouseStratFlags], MOUSE_SUSPENDING

		call	MouseExit

		BitClr	ds:[mouseStratFlags], MOUSE_SUSPENDING

		.leave
		ret
MouseSuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn the mouse back on again.

CALLED BY:	DR_UNSUSPEND
PASS:		ds	= dgroup (from MouseStrategy)
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseUnsuspend	proc	near
		uses	dx, si, cx, bx
		.enter
	;
	; Re-initialize the driver, since we exited it.
	;
		call	MouseInit
	;
	; Pass null pointer as signal that we're re-initializing what we had
	; before.
	;
		clr	dx, si
		call	MouseTestDevice
		call	MouseSetDevice
		.leave
		ret
MouseUnsuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the report rate for the mouse

CALLED BY:	MouseStrategy
PASS:		CX	= desired report rate as number of reports per second
RETURN:		CX	= actual mouse report rate set, if carry clear
		Carry set if requested rate was bogus.
DESTROYED:	DI, AX, ES (saved by MouseStrategy)

PSEUDO CODE/STRATEGY:
		The rate to be set is compared against those offered by
		the mouse. If the rate doesn't match any offered rate exactly,
		the lowest rate greater than the requested one is chosen
		(I can't think of a good argument either way, and it's
		easier to implement this way).

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetRate	proc	near
ifdef MOUSE_CANT_SET_RATE
		stc
else
		mov	al, cl
		mov	cx, MOUSE_NUM_RATES
		segmov	es, ds, di
		mov	di, offset mouseRates
		cld
MSRLoop:
		scasb
		jbe	MSRFound	; If AL is below ES:DI, we've got it.
		loop	MSRLoop
		stc			; Return error
		jmp	short MSRRet
MSRFound:
		;
		; Convert the rate into an index. Just as easy to do this
		; with CX as di-mouseRates (easier, actually, as we needn't
		; deal with di having been incremented). Yields CX being
		; the 0-origin index into mouseRates.
		;
		sub	cx, MOUSE_NUM_RATES
		neg	cx

		;
		; Contact the device-dependent portion to set the rate
		; MAY NOT MODIFY CX.
		;
		call	MouseDevSetRate
		;
		; Fetch the actual rate used from the table. Assumes table
		; is shorter than 256 bytes long so CH is clear.
		;
		mov	di, cx
		lea	di, mouseRates[di]	; Don't modify carry
		mov	cl, es:[di]
MSRRet:
endif ; MOUSE_CANT_SET_RATE
		ret
MouseSetRate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetRates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find available report rates for mouse

CALLED BY:	MouseStrategy (DR_MOUSE_GET_RATES)
PASS:		DS	= dgroup
RETURN:		ES:DI	= address byte-table containing available rates
			  (in reports/sec)
		CX	= length of table.
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseGetRates	proc	near
		segmov	es, ds, di
		mov	di, offset mouseRates
		mov	cx, MOUSE_NUM_RATES
		clc
		ret
MouseGetRates	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetAcceleration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set acceleration for mouse

CALLED BY:	MouseStrategy (DR_MOUSE_SET_ACCELERATION)
PASS:		DS	= dgroup
		CX	= threshold
		DX	= multiplier
RETURN:
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetAcceleration	proc	near
		mov	ds:[mouseAccelThreshold], cx
		mov	ds:[mouseAccelMultiplier], dx
		clc
		ret
MouseSetAcceleration	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetAcceleration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current acceleration info from driver

CALLED BY:	MouseStrategy (DR_MOUSE_GET_ACCELERATION)
PASS:		DS	= dgroup
RETURN:		CX	= threshold
		DX	= multiplier
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseGetAcceleration	proc	near
		mov	cx, ds:[mouseAccelThreshold]
		mov	dx, ds:[mouseAccelMultiplier]
		clc
		ret
MouseGetAcceleration	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetCombineMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set combine mode for mouse

CALLED BY:	MouseStrategy (DR_MOUSE_SET_ACCELERATION)
PASS:		DS	= dgroup
		CL	= MouseCombineMode
RETURN:
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetCombineMode	proc	near
		mov	ds:[mouseCombineMode], cl
		clc
		ret
MouseSetCombineMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetCombineMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get combine mode

CALLED BY:	MouseStrategy (DR_MOUSE_GET_ACCELERATION)
PASS:		DS	= dgroup
RETURN:		CL	= MouseCombineMode
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseGetCombineMode	proc	near
		mov	cl, ds:[mouseCombineMode]
		clc
		ret
MouseGetCombineMode	endp


ifdef MOUSE_CANT_TEST_DEVICE
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Trivial routine to inform the caller that this driver has
		no *idea* whether there's a mouse of the given type out
		there.

CALLED BY:	DRE_TEST_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		ax	= DevicePresent code (always DP_CANT_TELL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseTestDevice	proc	near
		.enter
		mov	ax, DP_CANT_TELL
		clc
		.leave
		ret
MouseTestDevice	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSendEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends appropriate events to the system

CALLED BY:	Device handler

PASS:		DS	= Driver's data segment
		BH	= MouseButtonBits for current state of buttons
			  (0 in bit => pressed)
		SI/DI	saved on stack
		ifndef MOUSE_USES_ABSOLUTE_DELTAS
			CX	= change in X (positive = right)
			DX	= change in Y (positive = down)
		else
			CX	= current mouse X position
			DX	= current mouse Y position
		endif

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, DI

PSEUDO CODE/STRATEGY:

		Send as output to Input Manager:


		di	- MSG_IM_PTR_CHANGE
		cx	- mouse X change
		dx	- mouse Y change
		bp	- PtrInfo
		si	- unused


		di	- MSG_IM_BUTTON_CHANGE
		cx	- timestamp LO
		dx	- timestamp HI
		bp	- <0>:<buttonInfo>
			   buttonInfo:
				Bit     7 = set for press, clear for relase
				Bits  2-0 = button #
					B0 = 0
					B1 = 1
					B2 = 2
		si	- unused


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/10/89		Initial Revision
	Adam	3/24/89		Changed to be MouseSendEvents
	Steve	12/7/89		Added time stamp to bp for MSG_IM_PTR_CHANGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Macro to test if a button has changed state and call MouseSendButtonEvent to
; generate the proper MSG_IM_BUTTON_CHANGE event.
;
CheckAndSend	macro	bit, num
		local	noSend
		test	al, MASK MOUSE_&bit	; Changed?
		jz	noSend			; No
		mov	bl, num			; Load bl with button #
		test	bh, MASK MOUSE_&bit	; Set ZF true if button now
						;  down
		call	MouseSendButtonEvent
noSend:
		endm


MouseSendEvents	proc	near
	;
	; See if there was any position change.
	;
ifndef MOUSE_USES_ABSOLUTE_DELTAS
		mov	ax, cx		; Store in CX.
		or	ax, dx		; See if there was any movement
		jz	afterSendEvent	; No -- don't send event.
else
		cmp	cx, ds:[mouseLastX]
		jne	sendPtr
		cmp	dx, ds:[mouseLastY]
		je	afterSendEvent
sendPtr:
endif
	;
	; Send IM_PTR_CHANGE event...
	;
					; But first, perform any mouse
					; acceleration needed
		push	bp		; Preserve passed BP
		push	bx		; Save button state
		call	TimerGetCount
ifdef MOUSE_USES_ABSOLUTE_DELTAS
		ornf	ax, (mask PI_absX or mask PI_absY)
else
		andnf	ax, not (mask PI_absX or mask PI_absY) ;both relative
endif
		xchg	bp, ax
ifndef MOUSE_DONT_ACCELERATE
		call	MousePreparePtrEvent
endif
	;
	; Push address of routine onto the stack
	;
		mov	di, mask MF_FORCE_QUEUE
		cmp	ds:[mouseCombineMode], MCM_NO_COMBINE
		jz	sendEvent

		push	cs
		mov	ax, offset Resident:MouseCombineEvent
		push	ax
		mov	di, mask MF_FORCE_QUEUE or \
			    mask MF_CHECK_DUPLICATE or \
			    mask MF_CUSTOM or \
			    mask MF_CHECK_LAST_ONLY
sendEvent:
		mov	bx, ds:[mouseOutputHandle]
		mov	ax, MSG_IM_PTR_CHANGE
		call	ObjMessage
		pop	bx		; and button state.
		pop	bp		; Restore passed BP

ifdef MOUSE_STORE_FAKE_MOUSE_COORDS
	;
	; Store some fake mouse coords if we're between a left button
	; down event and up event.
	;
	; Note: We can't just check if the MOUSE_B0 bit is clear in BH
	; because we need to make sure we only collect mouse coords
	; and send MSG_IM_READ_DIGITIZER_COORDS messages between the
	; MSG_IM_BUTTON_CHANGEs indicating the button-down and the
	; button-up because that is what the ink finite state machine is
	; expecting.
	;
		tst	ds:[leftButtonDown]
		jz	leftButtonNotDown
		push	bx, cx, dx
		clr	bh	; pen-move event
		mov	cx, 2	; fake X coord
		mov	dx, 2	; fake Y coord
		call	MouseStoreMouseCoordsInBuffer
		pop	bx, cx, dx
leftButtonNotDown:
endif ; MOUSE_STORE_FAKE_MOUSE_COORDS

	;
	; Store the deltas (if case we need them for combining the
	; next event), unless the noCombine flag was set (meaning
	; that the mouse event just sent was combined with the last
	; event and the delta was updated there)
	;
		clr	ax
		xchg	al, ds:noStoreDeltasFlag
		tst	al
		jnz	afterDelta
ifdef MOUSE_USES_ABSOLUTE_DELTAS
		mov	ax, cx
		sub	ax, ds:[mouseLastX]
		mov	ds:[mouseLastDeltaX], ax
		mov	ax, dx
		sub	ax, ds:[mouseLastY]
		mov	ds:[mouseLastDeltaY], ax
afterDelta:
		mov	ds:[mouseLastX], cx
		mov	ds:[mouseLastY], dx
else
		mov	ds:[mouseLastDeltaX], cx
		mov	ds:[mouseLastDeltaY], dx
afterDelta:
endif


afterSendEvent:
	;
	; Check for changes in the button state. XOR the current
	; and previous states together to find any button bits that
	; changed. A bit is 0 if the button is pressed.
	;
		and	bh, MouseButtonBits	; Make sure only defined
						; bits are around...
		mov	al, bh
		xor	al, ds:mouseButtons
		jz	MH_Done			; Nothing changed -- all done.
	;
	; Save current button state (do it now since we don't
	; reference it again and we want to avoid doubled events in
	; the case of our event sending being interrupted)
	;
		mov	ds:mouseButtons, bh

		push	bp		; Preserve passed BP

		CheckAndSend B0, 0

ifdef MIDDLE_IS_DOUBLE_PRESS
	;
	; If mapping the middle button to double presses, just send
	; a press and release of the left button for each status change.
	; We'll send one pair on the press and one pair on the release.
	;
		test	al, mask MOUSE_B1	;middle button changed?
		jz	noMiddle		;branch if not
		push	bx
		clr	bl			;bl <- left button
		andnf	bh, not mask MOUSE_B1	;bh <- button down
		test	bh, mask MOUSE_B1	;set Z flag
		call	MouseSendButtonEvent
		ornf	bh, mask MOUSE_B1	;bh <- button up
		test	bh, mask MOUSE_B1	;set Z flag
		call	MouseSendButtonEvent
		pop	bx
noMiddle:
else
		CheckAndSend B1, 1
endif
		CheckAndSend B2, 2
		CheckAndSend B3, 3

		;CheckAndSend B0, 0
		;CheckAndSend B1, 1
		;CheckAndSend B2, 2
		;CheckAndSend B3, 3

		pop	bp		; Restore passed BP
MH_Done:
		ret
MouseSendEvents	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MouseAccelerate

DESCRIPTION:	Accelerate passed mouse differential

CALLED BY:	INTERNAL
		MouseSendEvents

PASS:
	ds - driver's data segment
	ax - value to accelerate

RETURN:
	ax - new value

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/90		Initial version
------------------------------------------------------------------------------@

ifndef	MOUSE_DONT_ACCELERATE
	MOUSE_ACCELERATE_FUNCS = 1
endif

ifdef	MOUSE_ACCELERATE_FUNCS
MouseAccelerate	proc	near
	push	dx
	mov	di, ds:[mouseAccelThreshold]
	mov	dx, ax
	tst	ax
	jns	checkThreshold
	neg	di		; use negative threshold for negative delta

checkThreshold:
	sub	ax, di

	mov	dl, ah		; save high byte of result...
	lahf			; sign change?
	xor	ah, dh
	mov	ah, dl		; recover high byte of result
	js	afterMultiplier	; SF set => sign change => motion too small to
				;  accelerate

	imul	ds:[mouseAccelMultiplier]	; Amplify amount over threshold
afterMultiplier:
	add	ax, di		; add threshold back in to possibly amplified
				;  delta
	pop	dx
	ret
MouseAccelerate	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSendButtonEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for MouseHandler

CALLED BY:	MouseHandler
PASS:		BL	= button number for event:
				0 = left
				1 = middle
				2 = right
				3 = fourth button
		ZF	= Set if button now down
RETURN:		Nothing
DESTROYED:	CX, DX, BP, DI

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSendButtonEvent	proc	near
		push	ax
		push	bx
		jnz	SBE_10			; See if press bit set
      		or	bl, MASK BI_PRESS	; Set press flag
SBE_10:
						; store button #/press flag
		clr	bh
		mov	bp, bx

ifdef	MOUSE_STORE_FAKE_MOUSE_COORDS
		; If this is a left-button-UP event, store fake mouse coords
		; bp low = buttonInfo
		test	bp, mask BI_PRESS or mask BI_BUTTON
		jnz	notLeftButtonUpEvent

		push	bx, cx, dx
		mov	bh, -1	; pen-up event
		mov	cx, 3	; fake X coord
		mov	dx, 3	; fake Y coord
		call	MouseStoreMouseCoordsInBuffer
		pop	bx, cx, dx

		; Clear the left button down flag
		clr	ds:[leftButtonDown]
notLeftButtonUpEvent:
endif	; MOUSE_STORE_FAKE_MOUSE_COORDS

						; Get current time NOW
		call	TimerGetCount		; Fetch <bx><ax> = system time
		mov	cx, ax			; set <dx><cx> = system time
		mov	dx, bx

		mov	bx, ds:mouseOutputHandle
      		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_IM_BUTTON_CHANGE
		call	ObjMessage		; Send the event

ifdef	MOUSE_STORE_FAKE_MOUSE_COORDS
		; If this is a left-button-DOWN event, store fake mouse coords
		; bp low = buttonInfo

		test	bp, mask BI_PRESS	; is button down?
		jz	notLeftButtonDownEvent	; nope --> skip
		test	bp, mask BI_BUTTON	; left button?
		jnz	notLeftButtonDownEvent	; nope --> skip

		push	bx, cx, dx
		clr	bh	; pen-down event
		mov	cx, 1	; fake X coord
		mov	dx, 1	; fake Y coord
		call	MouseStoreMouseCoordsInBuffer
		pop	bx, cx, dx

		; Set the left button down flag
		mov	ds:[leftButtonDown], BB_TRUE
notLeftButtonDownEvent:
endif	; MOUSE_STORE_FAKE_MOUSE_COORDS

		pop	bx
		pop	ax
		ret
MouseSendButtonEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MousePreparePtrEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare the registers for sending out a IM_PTR_CHANGE event

CALLED BY:	MouseSendEvents, drivers that define MOUSE_DONT_ACCELERATE
PASS:		cx	= delta X
		dx	= delta Y
		bp	= PtrInfo w/timestamp
		ds	= dgroup
RETURN:		cx, dx, bp properly massaged
DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 1/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef MOUSE_DONT_ACCELERATE
MousePreparePtrEvent	proc	near
		.enter
	;
	; If the events occurred close enough together (within
	; MOUSE_ACCEL_THRESH ticks of each other), perform any needed
	; acceleration on the two.
	;
		push	bp
		sub	bp, ds:[mouseLastTime]
		andnf	bp, mask PI_time	; deal with timer wrap-around
						;  by clearing insignificant
						;  bits.
		cmp	bp, MOUSE_ACCEL_THRESH
		pop	bp			; restore new timestamp for
						;  event.
		ja	notCloseEnough

	;
	; Add the new deltas to the previous raw deltas and save that.
	;
		add	cx, ds:[mouseRawDeltaX]
		add	dx, ds:[mouseRawDeltaY]
		mov	ds:[mouseRawDeltaX], cx
		mov	ds:[mouseRawDeltaY], dx

	;
	; Accelerate the resulting cumulative raw deltas, then trim the results
	; back by the previous accelerated deltas, providing us with continuous
	; time-based acceleration. We save the new accelerated deltas for the
	; next time, of course.
	;
		xchg	ax, cx
		call	MouseAccelerate
		mov	cx, ax
		xchg	ax, ds:[mouseAccDeltaX]
		sub	cx, ax

		xchg	ax, dx
		call	MouseAccelerate
		mov	dx, ax
		xchg	ax, ds:[mouseAccDeltaY]
		sub	dx, ax

done:
		.leave
		ret

notCloseEnough:
	;
	; Perform single-event acceleration and setup the state variables for
	; the next IM_PTR_CHANGE event.
	;
		mov	ds:[mouseLastTime], bp
		mov	ds:[mouseRawDeltaX], cx
		mov	ds:[mouseRawDeltaY], dx
		xchg	ax, cx
		call	MouseAccelerate
		mov	ds:[mouseAccDeltaX], ax	; (smaller than mov from cx)
		xchg	ax, cx

		xchg	ax, dx
		call	MouseAccelerate
		mov	ds:[mouseAccDeltaY], ax	; (smaller than mov from dx)
		xchg	ax, dx
		jmp	done
MousePreparePtrEvent	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseCombineEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for MouseSendEvents via ObjMessage

CALLED BY:	ObjMessage
PASS:		DS:BX	= address of event to check
		AX	= method from event being sent
		CX	= CX from event being sent
		DX	= DX from event being sent
		BP	= BP from event being sent

RETURN:		DI	= PROC_SE_EXIT if combined with existing event
			  PROC_SE_STORE_AT_BACK if should stop scan and just
			  	store the event. Since we can only be called
				for the last event in the queue, we return
				PROC_SE_STORE_AT_BACK unless we actually
				have combined things.
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/89		Initial version
	Steve	12/7/89		Added combining of time stamps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef MOUSE_USES_ABSOLUTE_DELTAS
deltaerr equ <ERROR_NZ>
else
deltaerr equ <ERROR_Z>
endif

MouseCombineEvent proc	far
		mov	ax, ds:[bx].HE_method	; get event type of entry
		cmp	ax, MSG_IM_PTR_CHANGE; see if we should update
		LONG jne noCombine

ifndef MOUSE_COMBINE_DISCARD
	;
	; Check for colinear mode
	;
		push	es
		mov	di, dgroup
		mov	es, di
		cmp	es:[mouseCombineMode], MCM_COMBINE
		jz	combine
	;
	; Do colinear check -- for now just toss things one pixel apart
	;

		push	ax, bx, cx, dx
 ifdef MOUSE_USES_ABSOLUTE_DELTAS
		sub	cx, ds:[bx].HE_cx
		sub	dx, ds:[bx].HE_dx
 endif
		mov	ax, es:mouseLastDeltaX
		mov	bx, es:mouseLastDeltaY
	;
	; ax, bx = delta1 = delta from last position to position before that
	; cx, dx = delta2 = delta from last position
	;
	; add deltas in (assuming that we will combine)
	;
		add	es:mouseLastDeltaX, cx
		add	es:mouseLastDeltaY, dx
	;
	; if (delta1 == delta2) then combine
	;
		cmp	ax, cx
		jnz	10$
		cmp	bx, dx
		jz	popAndCombine
10$:
	;
	; if (delta1.X ==0) and (delta2.X == 0) then combine  /* vertical */
	; if (delta1.Y ==0) and (delta2.Y == 0) then combine  /* horizontal */
	;
		tst	ax
		jnz	20$
		jcxz	popAndCombine
20$:
		tst	bx
		jnz	30$
		tst	dx
		jz	popAndCombine
30$:
	;
	; if (delta1 is one unit) and (delta2 is one unit) then combine
	;
		tst	ax
		jns	40$
		neg	ax			;ax = abs(ax)
40$:
		tst	bx
		jns	50$
		neg	bx			;bx = abs(bx)
50$:
		tst	cx
		jns	60$
		neg	cx			;cx = abs(cx)
60$:
		tst	dx
		jns	70$
		neg	dx			;dx = abs(dx)
70$:
		add	ax, bx
		cmp	ax, 1
		ja	popNoCombine
		add	cx, dx
		cmp	cx, 1
		ja	popNoCombine

popAndCombine:
if	DEBUG_COMBINE
		inc	es:[combineCount]
endif
		pop	ax, bx, cx, dx
		mov	es:[noStoreDeltasFlag], 1
combine:
		pop	es

 ifndef MOUSE_USES_ABSOLUTE_DELTAS
	;
	; Sum the two events.
	;
		add	cx, ds:[bx].HE_cx
		add	dx, ds:[bx].HE_dx
 endif
		mov	ds:[bx].HE_cx, cx
		mov	ds:[bx].HE_dx, dx

endif
		mov	ds:[bx].HE_bp, bp	; update time stamp
		mov	di, PROC_SE_EXIT	; show we're done
		ret

ifndef MOUSE_COMBINE_DISCARD
popNoCombine:
 if	DEBUG_COMBINE
		inc	es:[noCombineCount]
 endif
		pop	ax, bx, cx, dx
		pop	es
endif
noCombine:
		mov	di, PROC_SE_STORE_AT_BACK
		ret

MouseCombineEvent endp

ifndef		MOUSE_CAN_BE_CALIBRATED

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetCalibrationPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the calibration points for the current device

CALLED BY:	MouseStrategy

PASS:		DX:SI	= Buffer holding up to MAX_NUM_CALIBRATION_POINTS
			  calibration points

RETURN:		DX:SI	= Buffer filled with calibration points
		CX	= # of calibration points

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseGetCalibrationPoints	proc	near
		WARNING	MOUSE_DEVICE_CANNOT_BE_CALIBRATED
		clr	cx
		ret
MouseGetCalibrationPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetCalibrationPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the calibration points for the current device

CALLED BY:	MouseStrategy

PASS:		DX:SI	= Buffer holding up the calibration points
		CX	= # of calibration points

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseSetCalibrationPoints	proc	near
		WARNING	MOUSE_DEVICE_CANNOT_BE_CALIBRATED
		ret
MouseSetCalibrationPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetRawCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current calibrated & non-calibrated coordinate

CALLED BY:	MouseStrategy

PASS:		Nothing

RETURN: 	Carry	= set (error, no point returned)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseGetRawCoordinate	proc	near
		stc
		ret
MouseGetRawCoordinate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStartCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:
PASS:
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseStartCalibration	proc	near
	WARNING	MOUSE_DEVICE_CANNOT_BE_CALIBRATED
	ret
MouseStartCalibration	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStopCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:
PASS:
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseStopCalibration	proc	near
	WARNING	MOUSE_DEVICE_CANNOT_BE_CALIBRATED
	ret
MouseStopCalibration	endp


else

ifidn	HARDWARE_TYPE, <GULLIVER>
else	; HARDWARE_TYPE is not BULLET, JEDI, GULLIVER, PENELOPE or DOVE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStartCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:
PASS:
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseStartCalibration	proc	near
	FALL_THRU	MouseStopCalibration
MouseStartCalibration	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStopCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:
PASS:
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseStopCalibration	proc	near
	ret
MouseStopCalibration	endp
endif	; HARDWARE_TYPE is not BULLET, JEDI, GULLIVER, PENELOPE or DOVE

endif		; ifndef MOUSE_CAN_BE_CALIBRATED


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseChangeOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the destination of the Mouse events

CALLED BY:	Strategy Routine

PASS:		bx	-> handle of queue where to send to
RETURN:		bx	<- handle of previous queue
DESTROYED:	nothing

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Swap out the destination queue

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseChangeOutput	proc	near
	xchg	ds:[mouseOutputHandle], bx
	ret
MouseChangeOutput	endp

Resident	ends

ifdef	MOUSE_SUPPORT_MOUSE_COORD_BUFFER

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseEscSetMouseCoordBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the circular buffer for storing mouse coordinates.

CALLED BY:	(GLOBAL) DR_MOUSE_ESC_SET_MOUSE_COORD_BUFFER
PASS:		cx	= segment of fixed circular buffer
			  (MouseCoordsCircularBufferStruct)
		es	= dgroup (by MouseStrategy)
RETURN:		carry clear
DESTROYED:	di, ds (ds preserved by MouseStrategy)
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	allen	12/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseEscSetMouseCoordBuffer	proc	far

	Assert	e, es:[mouseCoordBuf], NULL
	Assert	segment, cx

	;
	; Initialize the buffer.
	;
	mov	ds, cx
	mov	di, offset MCCBS_data
	mov	ds:[MCCBS_nextRead], di
	mov	ds:[MCCBS_nextWritten], di
	clr	di			; clears carry (says Adam)
	czr	di, ds:[MCCBS_count]

	mov	es:[curStrokeDropped], BB_FALSE

	;
	; Store the buffer.  (Do this LAST!)
	;
	mov	es:[mouseCoordBuf], cx

	; carry cleared by "clr" above.

	ret
MouseEscSetMouseCoordBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseEscRemoveMouseCoordBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the circular buffer for storing mouse coordinates.

CALLED BY:	(GLOBAL) DR_MOUSE_ESC_REMOVE_MOUSE_COORD_BUFFER
PASS:		ds	= dgroup (by MouseStrategy)
RETURN:		carry clear
DESTROYED:	di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	allen	12/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseEscRemoveMouseCoordBuffer	proc	far

	Assert	segment, ds:[mouseCoordBuf]

	clr	di			; clears carry (says Adam :-))
	czr	di, ds:[mouseCoordBuf]	; flags preserved

	ret
MouseEscRemoveMouseCoordBuffer	endp

Init	ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStoreMouseCoordsInBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store mouse coordinates in circular buffer

CALLED BY:	(EXTERNAL) Device handler
PASS:		ds	= dgroup
		cx, dx	= current mouse coordinates
		bh	= zero if pen-down or pen-move, non-zero if pen-up
RETURN:		interrupt possibly ON
DESTROYED:	nothing
SIDE EFFECTS:	MSG_IM_READ_DIGITIZER_COORDS is sent as appropriate

PSEUDO CODE/STRATEGY:
	This routine is non-reentrant.  Even if it is, invoking it
	recursively means it may be recording the points in the wrong order,
	and the IM will think the pen is moving backward for that few points.
	Hence, this routine should be called before IC_GENEOI is sent.

	NOTE:	If the event is pen-down or pen-move, this interrupt handler
		should call this routine AFTER calling MouseSendEvents.  If
		the event is pen-up, the handler should call this routine
		BEFORE MouseSendEvents.

	(For the pen-down/move and buffer not full case (most frequent case),
	optimize for speed because this is interrupt code.  For other cases,
	optimize for size because this is in fixed resource.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	allen	12/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseStoreMouseCoordsInBuffer	proc	near
	uses	ax, bx, cx, di, bp, ds, es
	.enter

	tst	ds:[mouseCoordBuf]
	LONG	jz	done		; => no buffer registered

	mov	bl, bh
	xchg	bl, ds:[prevEventIsPenUp]	; bl = old prevEventIsPenUp
						;  value.  If it hasn't been
						;  init'd, the old value won't
						;  be used anyway because of
						;  our logic.

	;
	; See if current stroke is being dropped.
	;
	tst	ds:[curStrokeDropped]
	LONG	jnz	strokeDropped

	segmov	es, ds, di
	mov	ds, ds:[mouseCoordBuf]	; ds = MouseCoordsCircularBufferStruct

	;
	; Make sure IM did't screw up the buffer.  :-)
	;
	Assert	urange, ds:[MCCBS_nextRead], <offset MCCBS_data>, \
			<offset MCCBS_data + size MCCBS_data>
	Assert	urange, ds:[MCCBS_nextWritten], <offset MCCBS_data>, \
			<offset MCCBS_data + size MCCBS_data>
		.assert MAX_MOUSE_COORDS gt 1
	Assert	b, ds:[MCCBS_count], <MAX_MOUSE_COORDS / 2>

	;
	; See if buffer has become full after the previous event came in (ie.
	; only one slot left).
	;
	mov	di, ds:[MCCBS_nextWritten]
	mov	ax, ds:[MCCBS_nextRead]
	sub	ax, di
	cmp	ax, size InkPoint
	je	full			; => only 1 slot left, full
	cmp	ax, - (MAX_MOUSE_COORDS * size InkPoint)
	je	full			; => 1 slot left (wrap-around case)

	;
	; Record this event.
	;
	tst	bh			; non-zero if pen-up
	jz	recordEvent
	BitSet	cx, IXC_TERMINATE_STROKE
recordEvent:
	movdw	ds:[di], dxcx
	add	di, size InkPoint
	cmp	di, offset MCCBS_data + size MCCBS_data
	jne	advancePtr
	mov	di, offset MCCBS_data
advancePtr:
	mov	ds:[MCCBS_nextWritten], di

	;
	; Send message to IM if we have collected half as many new points as
	; the maximum, or if it's a pen-up.
	;
	mov	cx, ds:[MCCBS_count]
	inc	cx
	mov	ds:[MCCBS_count], cx
		.assert MAX_MOUSE_COORDS gt 1
ifdef MOUSE_STORE_FAKE_MOUSE_COORDS
	; Send off a MSG_IM_READ_DIGITIZER_COORDS each time so the IM can
	; replace the fake mouse coords with values based on the current
	; pointer screen position as the MSG_IM_READ_DIGITIZER_COORDSs come
	; are handled.
	cmp	cx, 1
else
	cmp	cx, MAX_MOUSE_COORDS / 2
endif
	je	normalPrepareMsg
	tst	bh			; non-zero if pen-up
	jnz	normalPrepareMsg	; => pen-up.  Send message.

done:
	.leave
	ret

	; <---------------------------------------------------------->

normalPrepareMsg:
	clr	bp			; no ReadDigitizerCoordFlags set

sendMsg:
	mov	bx, es:[mouseOutputHandle]
	mov	ax, MSG_IM_READ_DIGITIZER_COORDS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage		; di = MESSAGE_NO_ERROR

		CheckHack <MESSAGE_NO_ERROR eq 0>
	czr	di, ds:[MCCBS_count]	; zero the count in all cases
	jmp	done

full:
	;
	; Either the buffer has just become full after the previous
	; pen-down/move or pen-up event, or the buffer has been full for a
	; while but the previous event was a pen-up.  Either way, Ignore
	; this event, and ignore the next one also if this one is a
	; pen-down/move.
	;
	Assert	e, es:[curStrokeDropped], BB_FALSE
	tst	bl			; non-zero if pen-up
	jnz	fullPrepareMsg		; => pen-up.  Don't ignore next event.
	dec	es:[curStrokeDropped]	; pen-down/move.  Ignore next event.

fullPrepareMsg:
	;
	; See if we should truncate the current stroke (previous event was
	; pen-down/move) or drop this new stroke (previous event was pen-up).
	; Set message flags accordingly.
	;
	; (We cannot simply look at whether the current event is pen-down/move
	; or pen-up, because we may get two pen-up events in a row if hardware
	; is flaky.  Who knows.  In that case it is conceptually wrong to send
	; an RDCF_STROKE_TRUNCATED message with no preceeding pen-down events.)
	;
	mov	bp, mask RDCF_STROKE_DROPPED
	tst	bh			; bh = old prevEventIsPenUp value
	jnz	sendMsg			; => prev is pen-up.  Drop.

	mov	bp, mask RDCF_STROKE_TRUNCATED
	mov	cx, ds:[MCCBS_count]
	jmp	sendMsg

strokeDropped:
	;
	; Current stroke is being dropped.  Continue dropping if this is a
	; pen-move.
	;
	tst	bh			; non-zero if pen-up
	jz	done			; => dropped and not pen-up.  Ignore.

	;
	; Current stroke is being dropped but now we have a pen-up.  Stop
	; dropping now (i.e. ignore this event but not the next one).
	;
	clr	ds:[curStrokeDropped]
	jmp	done

MouseStoreMouseCoordsInBuffer	endp

Resident ends

endif	; MOUSE_SUPPORT_MOUSE_COORD_BUFFER
