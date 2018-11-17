COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Mouse Driver -- Absolute Generic Mouse Device-dependent routines
FILE:		absgen.asm

AUTHOR:		Adam de Boor, Jul 16, 1991

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Intialize the device, registering a handler
				with the DOS Mouse driver
	MouseDevExit		Deinitialize the device, nuking our handler.
	MouseDevHandler		Handler for DOS driver to call.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/20/89		Initial revision


DESCRIPTION:
	Generic mouse driver that sits on top of the standard DOS one,
	using the absolute coordinates provided by the driver, rather than
	being relative as the other generic mouse driver is.
	

	$Id: absgen.asm,v 1.1 97/04/18 11:47:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse			= 1

;
; The following constants are used in mouseCommon.asm -- see that
; file for documentation.
;
MOUSE_NUM_BUTTONS = 3	; Assume 3 for now -- we'll set it in MouseDevInit
MOUSE_CANT_SET_RATE	=1	; Microsoft driver doesn't specify a function
				;  to change the report rate.
MOUSE_SEPARATE_INIT	= 1	; We use a separate Init resource
MOUSE_DONT_ACCELERATE	= 1	; We'll handle acceleration in our monitor
MOUSE_USES_ABSOLUTE_DELTAS = 1	; We pass absolute coordinates

include		../mouseCommon.asm	; Include common definitions/code.

include		win.def
include		Internal/grWinInt.def
include		Internal/videoDr.def	; for gross video-exclusive hack

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

mouseNameTable	lptr.char	genLightPen,
				genTouchScreen,
				genTablet,
				genDigitizer,
				unmouse,
				elodev,
				summa,
				wacomArtPad
		lptr.char	0	; null-terminator

genLightPen	chunk.char	'Generic Light Pen', 0
genTouchScreen	chunk.char	'Generic Touch Screen', 0
genTablet	chunk.char	'Generic Tablet', 0
genDigitizer	chunk.char	'Generic Digitizer', 0
unmouse		chunk.char	'UnMouse Touch Tablet', 0
elodev		chunk.char	'Elographics Touch Screen', 0
summa		chunk.char	'SummaGraphics SummaSketch', 0
wacomArtPad	chunk.char	'Wacom ArtPad', 0

mouseInfoTable	MouseExtendedInfo	\
		mask MEI_GENERIC,	; genLightPen
		mask MEI_GENERIC,	; genTouchScreen
		mask MEI_GENERIC,	; genTablet
		mask MEI_GENERIC,	; genDigitizer
		mask MEI_GENERIC,	; unmouse
		mask MEI_GENERIC,	; elodev
		mask MEI_GENERIC,	; summa
		mask MEI_GENERIC	; Wacom ArtPad

MouseExtendedInfoSeg	ends
		
;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment


mouseSet	byte	0	; non-zero if device-type set

mouseRates	label	byte	; to avoid assembly errors
MOUSE_NUM_RATES	equ	0
idata	ends

MouseFuncs	etype	byte
    MF_RESET			enum	MouseFuncs
    MF_SHOW_CURSOR		enum	MouseFuncs
    MF_HIDE_CURSOR		enum	MouseFuncs
    MF_GET_POS_AND_BUTTONS	enum	MouseFuncs
    MF_SET_POS			enum	MouseFuncs
    MF_GET_BUTTON_PRESS_INFO	enum	MouseFuncs
    MF_GET_BUTTON_RELEASE_INFO	enum	MouseFuncs
    MF_SET_X_LIMITS		enum	MouseFuncs
    MF_SET_Y_LIMITS		enum	MouseFuncs
    MF_DEFINE_GRAPHICS_CURSOR	enum	MouseFuncs
    MF_DEFINE_TEXT_CURSOR	enum	MouseFuncs
    MF_READ_MOTION		enum	MouseFuncs
    MF_DEFINE_EVENT_HANDLER	enum	MouseFuncs
    MF_ENABLE_LIGHT_PEN		enum	MouseFuncs
    MF_DISABLE_LIGHT_PEN	enum	MouseFuncs
    MF_SET_ACCELERATOR		enum	MouseFuncs
    MF_CONDITIONAL_HIDE_CURSOR	enum	MouseFuncs
    MF_SET_ACCEL_THRESHOLD	enum	MouseFuncs

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

SYNOPSIS:	Reset the mouse while dealing with non-standard drivers that
		like to modify video state.  Ensures that geos isn't
		trying to draw by grabbing the video-exclusive for the
		default video driver.

CALLED BY:	MouseDevInit, MouseDevExit, MouseTestDevice
PASS:		nothing
RETURN:		ax	= non-zero if driver present
		bx	= # buttons on mouse.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FAKE_GSTATE	equ	1		; bogus GState "handle" passed to
					;  the video driver as the exclusive
					;  gstate. The driver doesn't care if
					;  the handle's legal or not. Since we
					;  can't get a legal one w/o a great
					;  deal of work, we don't bother.

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
		tst	ax
		jz	haveDriver
		mov_tr	bx, ax	
		call	GeodeInfoDriver

haveDriver:
		mov	bx, FAKE_GSTATE
		mov	di, DR_VID_START_EXCLUSIVE
		clr	ax			; no override
		call	ds:[si].DIS_strategy
		
	;
	; Reset the DOS-level driver; now the system is protected from its
	; potential for modifying video card registers.
	;
		pop	bx		; recover default # buttons (in
					;  some cases)

		mov	ax, MF_RESET
		int	51
		
	;
	; Release the video driver now the mouse driver reset is accomplished
	; 
		push	ax, bx
		mov	bx, FAKE_GSTATE
		mov	di, DR_VID_END_EXCLUSIVE
		call	ds:[si].DIS_strategy
		tst	ax		; any operation interrupted?
		jz	invalDone	; no

		mov	ax, si		; ax <- left
		push	di		; save top
		call	ImGetPtrWin	; bx <- driver, di <- root win
		pop	bx		; bx <- top

		tst	di
		jz	invalDone
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
		dec	ds:[mouseSet]

		mov	bx, 3		; Early LogiTech drivers screw up and
					;  restore all registers, so default
					;  number of buttons to 3.
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
		mov	cx, 7fh			;cx <- all events (3 buttons)
twoButtons:
		segmov	es, Resident, dx	; Set up Event handler
		mov	dx, offset Resident:MouseDevHandler
		mov	ax, MF_DEFINE_EVENT_HANDLER
		int	51

	;
	; Set the bounds over which the mouse is allowed to roam to match
	; the dimensions of the default video screen, if we can...
	;
		mov	ax, GDDT_VIDEO
		call	GeodeGetDefaultDriver	;ax <- default video
		tst	ax
		jz	done
		mov_tr	bx, ax
		
		push	ds
		call	GeodeInfoDriver
		mov	cx, ds:[si].VDI_pageW
		mov	dx, ds:[si].VDI_pageH
		pop	ds
		
		push	cx
		clr	cx		; min Y is 0, max Y in dx
		
		mov	ax, MF_SET_Y_LIMITS
		int	51
		
		pop	dx		; dx <- max X
		clr	cx		; min X is 0
		mov	ax, MF_SET_X_LIMITS
		int	51
		
done:
		clc			; no error
		.leave
		ret
MouseDevInit	endp

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
		clc				; No errors
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

PASS:		ax	- mask of events that occurred:
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
	adam	7/16/91		Changed to use absolute deltas

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far
	;
	; Load dgroup into ds. We pay no attention to the event
	; mask we're passed, since MouseSendEvents just works from the
	; data we give it. So we trash AX here.
	;
		mov	ax, dgroup
		mov	ds, ax
	;
	; Now have to transform the button state. We're given
	; <M,R,L> with 1 => pressed, which is just about as bad as
	; we can get, since MouseSendEvents wants <L,M,R> with
	; 0 => pressed. The contortions required to perform the
	; rearrangement are truly gruesome.
	;
		andnf	bx, 7		; Make sure high bits are clear (see
					; below)
		shr	bl, 1		; L => CF
		rcl	bh, 1		; L => BH<0>
		shl	bh, 1		; L => BH<1>
		shl	bh, 1		; L => BH<2>
		or	bh, bl		; Merge in M and R
		not	bh		; Invert the sense (want 0 => pressed)
					; and make sure uncommitted bits all
					; appear as UP.
	;
	; Ship the events off.
	;
		call	MouseSendEvents
		ret
MouseDevHandler	endp

Resident ends

	end
