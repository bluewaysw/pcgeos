COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Mouse Driver - CuteMouse based with wheel support
FILE:		ctm.asm

AUTHOR:		Adam de Boor, Jul 20, 1989
		MeyerK, 09/2021

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Intialize the device, registering a handler with the DOS Mouse driver
	MouseDevExit		Deinitialize the device, nuking our handler.
	MouseDevHandler	 	Handler for DOS driver to call.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/20/89		Initial revision
	MeyerK 09/05/21		Wheel support


DESCRIPTION:
	Generic mouse driver that sits on top of the CuteMouse driver that has wheel support.

	This is intended only as a stop-gap for new/unknown mice until a
	proper driver can be written for it.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; The following constants are used in mouseCommon.asm -- see that
; file for documentation.
;
MOUSE_GEOS_NATIVE_WHEEL_SUPPORT	= TRUE	; enable this if GEOS has native wheel support in the kernel/ui
MOUSE_NUM_BUTTONS	= 3		; Assume 3 for now -- we'll set it in MouseDevInit
MIDDLE_IS_DOUBLE_PRESS	= 1		; fake double-press with middle button
MOUSE_CANT_SET_RATE	= 1		; Microsoft driver doesn't specify a function
					; to change the report rate.
MOUSE_SEPARATE_INIT	= 1		; We use a separate Init resource

MOUSE_DONT_ACCELERATE	= 1		; We'll handle acceleration in our monitor
MOUSE_ACCELERATE_FUNCS	= 1		; ...so access the acceleration function
MOUSE_COMBINE_DISCARD	= 1		; Discard new event if duplicate found.

include		../mouseCommon.asm		 ; Include common definitions/code.

include		win.def
include		Internal/grWinInt.def
include		Internal/videoDr.def	; for gross video-exclusive hack

;------------------------------------------------------------------------------
;	DEVICE STRINGS
;------------------------------------------------------------------------------
MouseExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

mouseExtendedInfo	DriverExtendedInfoTable <
	{},				; lmem header added by Esp
	length mouseNameTable,		; Number of supported devices
	offset mouseNameTable,
	offset mouseInfoTable
>

if MOUSE_GEOS_NATIVE_WHEEL_SUPPORT
	mouseNameTable	lptr.char	ctPageMouse,
					ctCursorMouse,
					ctNativeMouse
			lptr.char	0	; null-terminator

	ctPageMouse	chunk.char	'CTMOUSE.EXE /O (Wheel = Page Up/Down)', 0
	ctCursorMouse	chunk.char	'CTMOUSE.EXE /O (Wheel = Cursor Up/Down)', 0
	ctNativeMouse	chunk.char	'CTMOUSE.EXE /O (Native Wheel Support)', 0

	mouseInfoTable	MouseExtendedInfo	\
			mask MEI_GENERIC or MOUSE_WHEEL_ACTION_PAGE   shl offset MEI_WHEEL_VERTICAL,	; pageMouse
			mask MEI_GENERIC or MOUSE_WHEEL_ACTION_CURSOR shl offset MEI_WHEEL_VERTICAL,	; cursorMouse
			mask MEI_GENERIC or MOUSE_WHEEL_ACTION_NATIVE shl offset MEI_WHEEL_VERTICAL	; nativeMouse
else
	mouseNameTable	lptr.char	ctPageMouse,
					ctCursorMouse
			lptr.char	0	; null-terminator

	ctPageMouse	chunk.char	'CTMOUSE.EXE /O (Wheel = Page Up/Down)', 0
	ctCursorMouse	chunk.char	'CTMOUSE.EXE /O (Wheel = Cursor Up/Down)', 0

	mouseInfoTable	MouseExtendedInfo	\
			mask MEI_GENERIC or MOUSE_WHEEL_ACTION_PAGE   shl offset MEI_WHEEL_VERTICAL,	; pageMouse
			mask MEI_GENERIC or MOUSE_WHEEL_ACTION_CURSOR shl offset MEI_WHEEL_VERTICAL	; cursorMouse
endif

MouseExtendedInfoSeg	ends
ForceRef	mouseExtendedInfo

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

	GEN_MOUSE_MAGIC	= 0adebh 	; Magical delta given to MouseSendEvents if there's
					; mouse motion so our input monitor knows to do
					; funky things with the IM_PTR_CHANGE event.

	mouseMonitor	Monitor	<>

	mouseSet	byte	0	; non-zero if device-type set

	mouseRates	label	byte	; to avoid assembly errors
	MOUSE_NUM_RATES	equ	0

idata	ends


MouseFuncs	etype	byte
		MF_RESET			enum	MouseFuncs
		MF_SHOW_CURSOR			enum	MouseFuncs
		MF_HIDE_CURSOR			enum	MouseFuncs
		MF_GET_POS_AND_BUTTONS		enum	MouseFuncs
		MF_SET_POS			enum	MouseFuncs
		MF_GET_BUTTON_PRESS_INFO	enum	MouseFuncs
		MF_GET_BUTTON_RELEASE_INFO	enum	MouseFuncs
		MF_SET_X_LIMITS			enum	MouseFuncs
		MF_SET_Y_LIMITS			enum	MouseFuncs
		MF_DEFINE_GRAPHICS_CURSOR	enum	MouseFuncs
		MF_DEFINE_TEXT_CURSOR		enum	MouseFuncs
		MF_READ_MOTION			enum	MouseFuncs
		MF_DEFINE_EVENT_HANDLER		enum	MouseFuncs
		MF_ENABLE_LIGHT_PEN		enum	MouseFuncs
		MF_DISABLE_LIGHT_PEN		enum	MouseFuncs
		MF_SET_ACCELERATOR		enum	MouseFuncs
		MF_CONDITIONAL_HIDE_CURSOR	enum	MouseFuncs
		MF_SET_ACCEL_THRESHOLD		enum	MouseFuncs

MouseEvents	record
		ME_MIDDLE_RELEASE:1
		ME_MIDDLE_PRESS:1
		ME_RIGHT_RELEASE:1
		ME_RIGHT_PRESS:1
		ME_LEFT_RELEASE:1
		ME_LEFT_PRESS:1
		ME_MOTION:1
MouseEvents	end

Resident segment resource


Init		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:
PASS:
RETURN:
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FAKE_GSTATE	equ	1	 	; bogus GState "handle" passed to
					; the video driver as the exclusive
					; gstate. The driver doesn't care if
					; the handle's legal or not. Since we
					; can't get a legal one w/o a great
					; deal of work, we don't bother.

bogusStrategy	fptr.far	farRet

Resident	segment	resource
farRet:		retf
Resident	ends

MouseReset	proc	far	uses cx, dx, di, ds, si, bp
		.enter
	;
	; Assume no video driver around -- makes life easier
	;
		segmov	ds, cs
		mov	si, offset bogusStrategy - offset DIS_strategy

		push	bx
		mov	ax, GDDT_VIDEO
		call	GeodeGetDefaultDriver
		mov	bx, ax
		tst	bx
		jz	haveDriver
		call	GeodeInfoDriver

haveDriver:
		mov	bx, FAKE_GSTATE
		mov	di, DR_VID_START_EXCLUSIVE
		call	ds:[si].DIS_strategy

	;
	; Reset the DOS-level driver, now the system is protected from its
	; potential for messing with video card registers.
	;
		pop	bx		; recover default # buttons (in
		;	some cases)

		mov	ax, MF_RESET
		int	51

	;
	; Release the video driver now the mouse driver reset is accomplished
	;
		push	ax, bx
		mov	di, DR_VID_END_EXCLUSIVE
		mov	bx, FAKE_GSTATE
		call	ds:[si].DIS_strategy

		tst	ax		; any operation interrupted?
		jz	invalDone	; no

		mov	ax, si		; ax <- left
		push	di		; save top
		call	ImGetPtrWin	; bx <- driver, di <- root win
		pop	bx		; bx <- top

		tst	di
		jz	invalDone

		segmov	ds, dgroup, si
		test	ds:[mouseStratFlags], mask MOUSE_SUSPENDING
		jnz	invalDone

		clr	bp, si		; rectangular region, thanks
		call	WinInvalTree
invalDone:
		pop	ax, bx
		.leave
		ret
MouseReset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the device

CALLED BY:	MouseInit

PASS:		es=ds=dgroup

RETURN:		carry	- set on error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Install our interrupt vector and initialize our state.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/8/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevInit	proc	far	uses dx, ax, cx, si, bx
		.enter

	; fetch and save driver variant
		call	MouseSetWheelAction

	; start resetting
		dec	ds:[mouseSet]

		mov	bx, 3		; Early LogiTech drivers screw up and
					; restore all registers, so default
					; number of buttons to 3.
		call	MouseReset
	;
	; The mouse driver initialization returns bx == # of buttons
	; on the mouse. Some two-button drivers get upset if we request
	; events from the third (non-existent) button, so we check the
	; number of buttons available, and set the mask accordingly.
	;
		mov	ds:[DriverTable].MDIS_numButtons, bx
		mov	cx, 1fh			;cx <- all events (2 buttons)
		cmp	bx, 2
		je	twoButtons
		mov 	cx, 11111111b 		; cx <- all events (3 buttons and the wheel)
twoButtons:
		segmov	es, Resident, dx	; Set up Event handler
		mov	dx, offset Resident:MouseDevHandler
		mov	ax, MF_DEFINE_EVENT_HANDLER
		int	51

	;
	; Install a monitor to read the actual motion counters from the driver.
	;
		mov	bx, offset mouseMonitor
		mov	al, ML_DRIVER
		mov	cx, Resident
		mov	dx, offset MouseMonitor
		call	ImAddMonitor

		clc			; no error
		.leave
		ret
MouseDevInit	endp


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
	;
		assume	es:MouseExtendedInfoSeg
		cmp	es:mouseInfoTable[di], mask MEI_GENERIC or MOUSE_WHEEL_ACTION_PAGE shl offset MEI_WHEEL_VERTICAL
		je	pageKey
		cmp	es:mouseInfoTable[di], mask MEI_GENERIC or MOUSE_WHEEL_ACTION_CURSOR shl offset MEI_WHEEL_VERTICAL
		je	cursorKey
		cmp	es:mouseInfoTable[di], mask MEI_GENERIC or MOUSE_WHEEL_ACTION_NATIVE shl offset MEI_WHEEL_VERTICAL
		je	native

pageKey:
		mov	ds:[driverVariant], MOUSE_WHEEL_ACTION_PAGE
		jmp 	finish
cursorKey:
		mov	ds:[driverVariant], MOUSE_WHEEL_ACTION_CURSOR
		jmp	finish
native:
		mov	ds:[driverVariant], MOUSE_WHEEL_ACTION_NATIVE
		jmp	finish

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

Init		ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves

CALLED BY:	MouseExit

PASS:		Nothing

RETURN:		carry	- set on error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Contact the driver to remove our handler

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/8/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevExit	proc	near
		tst	ds:[mouseSet]
		jz	done
		call	MouseReset
if 0
		clr	dx
		mov	es, dx			; NULL event handler address
		mov	ax, MF_DEFINE_EVENT_HANDLER
		clr	cx			; No events
		int	51
endif
		segmov	ds, dgroup, bx
		mov	bx, offset mouseMonitor
		mov	al, mask MF_REMOVE_IMMEDIATE
		call	ImRemoveMonitor
		clc	; No errors
done:
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
MouseTestDevice	proc	near	uses bx
	.enter
	; XXX: SOME DRIVERS DON'T DO THIS RIGHT!
		call	MouseReset
		tst	ax
		mov	ax, DP_PRESENT
		jnz	done
		mov	ax, DP_NOT_PRESENT
done:
	.leave
	ret
MouseTestDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse handler routine to take the event and pass it to
		MouseSendEvents

CALLED BY:	EXTERNAL

PASS:	 ax	- mask of events that occurred:
			b0	pointer motion
			b1	left down
			b2	left up
			b3	right down
			b4	right up
			b5	middle down
			b6	middle up
	bx	- button state
			b0	left
			b1	right
			b2	middle
			1 => pressed
			Alternatively: bh holds the wheel info
	cx	- X position
	dx	- Y position

RETURN:		Nothing

DESTROYED:	Anything (Logitech driver saves all)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	7/19/89		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far
		clr	cx		; Assume not motion
		clr	dx
		test	ax, mask ME_MOTION
		jz	mangleButtons
		mov	cx, GEN_MOUSE_MAGIC
		mov	dx, cx

mangleButtons:
	;
	; Load dgroup into ds. We pay no attention to the event
	; mask we're passed, since MouseSendEvents just works from the
	; data we give it. So we trash AX here.
	;
		mov	ax, dgroup
		mov	ds, ax
	;
	; save wheel action, if any
	;
		mov	ds:[wheelAction], bh
	;
	; not a wheel event, button stuff or ptr...
	; Now have to transform the button state. We're given
	; <M,R,L> with 1 => pressed, which is just about as bad as
	; we can get, since MouseSendEvents wants <L,M,R> with
	; 0 => pressed. The contortions required to perform the
	; rearrangement are truly gruesome.
	;
		andnf	bx, 7		; Make sure high bits are clear (see below)
		shr	bl, 1		; L => CF
		rcl	bh, 1		; L => BH<0>
		shl	bh, 1		; L => BH<1>
		shl	bh, 1		; L => BH<2>
		or	bh, bl	 	; Merge in M and R
		not	bh		; Invert the sense (want 0 => pressed)
					; and make sure uncommitted bits all
			 		; appear as UP.
	;
	; Ship the events off.
	;
		call	MouseSendEvents
		ret
MouseDevHandler	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Input monitor to transform bogus IM_PTR_CHANGE events into ones
		that contain real deltas

CALLED BY:	Input Manager
PASS:		al	= mask MF_DATA
		di	= event type
		MSG_IM_PTR_CHANGE:
			cx	= pointer X position
			dx	= pointer Y position
			bp<15>	= X-is-absolute flag
			bp<14>	= Y-is-absolute flag
			bp<0:13>= timestamp
		si	= event data
RETURN:		al	= mask MF_DATA if event is to be passed through
			0 if we've swallowed the event (as will happen if
			MF_READ_MOTION returns no motion)
DESTROYED:	ah, bx, ds, es (possibly)
		cx, dx, si, bp (if event swallowed)

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseMonitor	proc	far
	.enter

	;
	; See if the event is one of our IM_PTR_CHANGE events.
	;
		cmp	di, MSG_IM_PTR_CHANGE
		jne	done
		cmp	cx, GEN_MOUSE_MAGIC
		jne	done
		cmp	dx, GEN_MOUSE_MAGIC
		jne	done
	;
	; It seems to be. Read the motion counters. If they are both zero,
	; just swallow the event (else, return them, of course)
	;
		mov	ax, MF_READ_MOTION
		int	51
		mov	ax, cx
		or	ax, dx
		jz	done		; MF_DATA flag already clear

	;
	; Accelerate the motion returned.
	;
		push	di
		xchg	ax, cx
		call	MouseAccelerate
		xchg	ax, cx
		xchg	ax, dx
		call	MouseAccelerate
		xchg	ax, dx
		pop	di

		mov	al, mask MF_DATA

done:
	.leave
	ret
MouseMonitor	endp

Resident ends

end
