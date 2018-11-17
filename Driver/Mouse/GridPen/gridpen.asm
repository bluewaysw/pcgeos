COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Mouse Driver -- GRiDPAD pen mouse driver
FILE:		gridpen.asm

AUTHOR:		Gene Anderson, July 18th, 1990

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
	Gene	7/18/90		Initial revision


DESCRIPTION:
	Mouse driver to support the GRiDPAD pen.

	$Id: gridpen.asm,v 1.1 97/04/18 11:48:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse			= 1

MOUSE_NUM_BUTTONS = 1
MOUSE_CANT_SET_RATE = 1
MOUSE_SEPARATE_INIT = 1
MOUSE_DONT_ACCELERATE = 1
MOUSE_USES_ABSOLUTE_DELTAS = 1

include		mouseCommon.asm		; Include common definitions/code.
include		timer.def
include		graphics.def

;------------------------------------------------------------------------------
;			GRiD Constants
;------------------------------------------------------------------------------

GRID_DISPLAY_X	=	640
GRID_DISPLAY_Y	=	400

GRID_MAX_OVERLAY_COORD	=	0x3ff

;
; The Grid pen reports its pen movements via interrupt feh
;
GRID_PEN_INTERRUPT	equ	0xfe
;
; The GridSystemFunctions are accessed via interrupt 15h, with the
; subsystem number (e4h) in AH. The function number goes in AL.
;
GRID_INTERRUPT		equ	0x15
GRID_SUBSYSTEM_INT	equ	0xe4

CallGrid	macro	function
	mov	ax, (GRID_SUBSYSTEM_INT shl 8) or function
	int	GRID_INTERRUPT
endm

GridSystemFunctions	etype	byte
    GSF_TEST_OVERLAY		enum	GridSystemFunctions, 60h
    GSF_INIT_OVERLAY		enum	GridSystemFunctions, 61h
    GSF_EXIT_OVERLAY		enum	GridSystemFunctions, 62h
    GSF_PEEK_POINT		enum	GridSystemFunctions, 63h
    GSF_GET_POINT		enum	GridSystemFunctions, 64h
    GSF_GET_STATUS		enum	GridSystemFunctions, 65h
    GSF_READ_CALIBRATION	enum	GridSystemFunctions, 66h
    GSF_WRITE_CALIBRATION	enum	GridSystemFunctions, 67h
    GSF_READ_AD_CONVERTER	enum	GridSystemFunctions, 68h
    GSF_FLUSH_POINTS		enum	GridSystemFunctions, 69h
    GSF_GENERATE_INTERRUPT	enum	GridSystemFunctions, 6ah
    GSF_GET_OVERLAY_VERSION	enum	GridSystemFunctions, 6bh
    GSF_READ_OVERLAY_RAM	enum	GridSystemFunctions, 6dh
    GSF_WRITE_OVERLAY_RAM	enum	GridSystemFunctions, 6eh
    GSF_WRITE_RTC_CMOS_RAM	enum	GridSystemFunctions, 6fh
    GSF_READ_RTC_CMOS_RAM	enum	GridSystemFunctions, 70h
    GSF_DEFINE_CALIBRATION	enum	GridSystemFunctions, 71h
    GSF_ACCESS_CALIBRATION	enum	GridSystemFunctions, 72h
    GSF_GET_UNCALIBRATED_POINT	enum	GridSystemFunctions, 73h

GridOverlayErrors	etype	byte, 1
    GOE_FUNCTION_OUT_OF_RANGE	enum	GridOverlayErrors
    GOE_BUFFER_NOT_ESTABLISHED	enum	GridOverlayErrors
    GOE_BUFFER_EMPTY		enum	GridOverlayErrors
    GOE_UNRECOGNIZED_CODE	enum	GridOverlayErrors
    GOE_NO_RESPONSE		enum	GridOverlayErrors
    GOE_BUFFER_TOO_SMALL	enum	GridOverlayErrors


;------------------------------------------------------------------------------
;			Other constants
;------------------------------------------------------------------------------
;;;MOUSE_DELAY	=	1		; # ticks between polls
MOUSE_DELAY	=	4		; # ticks between polls

BAD_MOUSE_COORDINATE			enum	FatalErrors

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

mouseNameTable	lptr.char	gridPenName
		lptr.char	0	; null-terminator

gridPenName	chunk.char	'GRiDPAD Pen', 0

mouseInfoTable	MouseExtendedInfo	\
		0	; non-serial, no interrupt, not generic

ForceRef	mouseExtendedInfo

MouseExtendedInfoSeg	ends
;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment


mouseRates	label	byte	; to avoid assembly errors
MOUSE_NUM_RATES	equ	0

idata	ends

udata	segment

;
;	Handle of the timer used to get calls every tick
;
timerHandle	word

;
; The GRiDPAD pen requires a static buffer to return pen positions.
;
OVERLAY_BUFFER_SIZE	=	256

penOverlayBuffer	byte	OVERLAY_BUFFER_SIZE+2 dup (?)

;
; Adjustment values to center the pen, and sizes to scale it to the display
;
upperLeftX	word
upperLeftY	word

mouseScaleX	word
mouseScaleY	word

;
; Last known position of pen (in screen & overlay coordinates)
; for (a) releases, since BIOS doesn't pass the position on a
; release (b) ignoring events, since there can be multiple pen
; events at a single point.
;
lastXPos	word
lastYPos	word

lastXOverlay	word
lastYOverlay	word

udata	ends

Resident	segment	resource
Init		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the device
CALLED BY:	MouseSetDevice()

PASS:		es=ds=dgroup
RETURN:		carry	- set on error (s/b nothing)
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/18/90		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevInit	proc	far	uses ax, bx, cx, dx, si
	.enter
	;
	; Initialize the GRiD overlay system. The first word
	; in the buffer must be the size of the buffer. This
	; function may return a buffer too small error.
	;
	mov	{word} ds:penOverlayBuffer, OVERLAY_BUFFER_SIZE
	mov	bx, offset penOverlayBuffer
	mov	cx, ds				;cx:bx <- ptr to buffer
	CallGrid	GSF_INIT_OVERLAY
	jc	error
	;
	; Get the calibration / adjustment overlay values.
	;
	CallGrid	GSF_READ_CALIBRATION
	;
	; The overlay grid returns values from 0-3FFh, which
	; are adjusted by the calibration values. Unfortunately,
	; we want values sized for the display, which goes
	; from 1-640 & 1-400 in x & y, respectively. So we set
	; up here to do some gross scaling.
	;
	mov	ds:upperLeftX, ax
	mov	ds:upperLeftY, bx
	sub	cx, ax				;cx <- calibrated x size
	sub	dx, bx				;dx <- calibrated y size
	mov	ds:mouseScaleX, cx
	mov	ds:mouseScaleY, dx
	;
	; Turn on the timer so we read the mouse. Initially, I tried
	; just setting up an interrupt handler. Unfortunately, what
	; amounted to an infinite number of NMIs came through,
	; resulting in death, destruction and stack overflow.
	; So now we just poll the mouse.
	;
	mov	ax, TIMER_ROUTINE_CONTINUAL
	mov	bx, segment Resident
	mov	si, offset Resident:MouseDevHandler
	mov	cx, MOUSE_DELAY
	mov	di, cx
	call	TimerStart
	mov	ds:[timerHandle],bx
if 0
	;
	; Set up interrupt vector 0xfe to report pen changes.
	;
	mov	ax, GRID_PEN_INTERRUPT		;ax <- interrupt number
	mov	bx, segment MouseDevHandler
	mov	cx, offset MouseDevHandler	;bx:cx <- ptr to new routine
	mov	di, offset oldIntVector		;es:di <- storage for old vector
	call	SysCatchInterrupt
	;
	; Tell GRiD overlay to inform us via interrupt 0xfe.
	;
	mov	dl, TRUE			;dl <- start interrupts
	CallGrid	GSF_GENERATE_INTERRUPT
endif

	clc					;indicate no error
error:
	.leave
	ret
MouseDevInit	endp

Init	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves
CALLED BY:	MouseExit()

PASS:		none
RETURN:		carry	- set on error
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/18/90		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevExit	proc	near
	;
	; Shut off our fine polling timer...
	;
	clr	bx
	xchg	bx,ds:[timerHandle]
	tst	bx		; initialized?
	jz	done		; no => nothing to do here.
	clr	ax		; 0 => continual
	call	TimerStop
if 0
; See MouseDevInit() about infinite NMIs...
	;
	; Tell GRiD to stop generating interrupts
	;
	mov	dl, FALSE			;dl <- stop generating ints
	CallGrid	GSF_GENERATE_INTERRUPT
	;
	; Restore old interrupt 0xfe vector.
	;
	mov	ax, GRID_PEN_INTERRUPT		;ax <- interrupt number
	segmov	es, dgroup, bx
	mov	di, offset oldIntVector		;es:di <- storage for old vector
	call	SysCatchInterrupt
endif
	;
	; Deinitialize the overlay controller buffer and remove
	; the "buffer valid" flag. All registers are preserved,
	; except AX. This function may return a timeout error.
	;
	CallGrid	GSF_EXIT_OVERLAY
done:
	ret
MouseDevExit	endp


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
MouseTestDevice	proc	near
		.enter
	;
	; Test the GRiD overlay system. If it is not connected,
	; this function returns a timeout error.
	;
		CallGrid	GSF_TEST_OVERLAY
		mov	ax, DP_PRESENT
		jc	error
done:
		clc
		.leave
		ret
error:
		mov	ax, DP_NOT_PRESENT
		jmp	done
MouseTestDevice	endp

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
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse handler routine to take the event and pass it to
		MouseSendEvents()
CALLED BY:	EXTERNAL (interrupt feh)

PASS:		cs:inHandler -- semaphore for handler routine
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/18/90		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

inHandler	byte	1

MouseDevHandler	proc	far
	uses	si, di, ds

	dec	cs:inHandler
	jns	notInHandler
	jmp	endInterrupt			;branch if already in routine
notInHandler:

	.enter

	;
	; Get the current (x,y) pen position. It is a
	; 10-bit value, so the range for both the x and
	; y coordinates is 0-3FFh. A variety of errors
	; can be returned here, including buffer empty (=03h)
	;
pointLoop:
	CallGrid	GSF_GET_POINT
	jc	done
	;
	; RETURNS:
	;	AL = 1	-> pen down
	;	AL = 2	-> pen up (BX = CX = 0xffff)
	;
;pointFound:
	segmov	ds, dgroup, dx			;ds <- seg addr of udata
	dec	ax
	jnz	buttonUp			;branch if button release
	;
	; Check to see if the pen actually moved
	;
	cmp	ds:lastXOverlay, bx
	jne	penMoved
	cmp	ds:lastYOverlay, cx
	je	pointLoop			;branch if (x,y) didn't change
penMoved:
	mov	ds:lastXOverlay, bx
	cmp	bx, GRID_MAX_OVERLAY_COORD
	jae	pointLoop
	mov	ds:lastYOverlay, cx
	cmp	cx, GRID_MAX_OVERLAY_COORD
	jae	pointLoop
	;
	; The pen is down. We have a positional value based on the
	; size of the overlay grid, so we need to scale it to the
	; size of the display.
	;
	sub	bx, ds:upperLeftX
	sub	cx, ds:upperLeftY		;adjust for calibration

	mov	ax, GRID_DISPLAY_Y
	mul	cx				;dx.ax <- position*display
	div	ds:mouseScaleY			;ax <- position*display/scale
	mov	bp, ax				;bp <- scaled y position
	mov	ax, GRID_DISPLAY_X
	mul	bx				;dx.ax <- position*display
	div	ds:mouseScaleX			;ax <- position*display/scale
	;
	; Put the (x,y) position in the correct registers for
	; MouseSendEvents(), and save the position for any
	; subsequent release -- releases have no position
	; information, and we need those values.
	;
	cmp	ax, 0
	jl	pointLoop
	cmp	bp, 0
	jl	pointLoop
EC <	cmp	ax, MAX_COORD			;>
EC <	ERROR_AE	BAD_MOUSE_COORDINATE	;>
EC <	cmp	bp, MAX_COORD			;>
EC <	ERROR_AE	BAD_MOUSE_COORDINATE	;>
	mov	cx, ax				;ax <- scaled x position
	mov	dx, bp				;dx <- scaled y position
	mov	bh, not mask MOUSE_B0		;mark b0 down, others up
	mov	ds:lastXPos, cx			;save (x,y) for release
	mov	ds:lastYPos, dx
	;
	; Send the position and button state off to the system...
	;
sendEvent:
	call	MouseSendEvents
	jmp	pointLoop

	;
	; The pen is up. The hardware has no position information
	; with a release, so we use the last known (x,y) position.
	;
buttonUp:
	mov	cx, ds:lastXPos			;cx <- last known x
	mov	dx, ds:lastYPos			;dx <- last known y
	mov	bh, not 0			;mark all buttons up
	jmp	sendEvent

done:

	.leave

endInterrupt:
	inc	cs:inHandler
	ret
MouseDevHandler	endp

Resident ends

end
