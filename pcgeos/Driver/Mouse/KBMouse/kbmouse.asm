COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Mouse Drivers -- KBMouse (keyboard driven mouse, for people
				 only use computers on the floor of CES shows...
FILE:		kbmouse.asm

AUTHOR:		Eric E. Del Sesto, Dec 1991.

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
	Eric	12/91		Initial version (adapted from GenMouse)
	Doug	2/92		Ported to V2.0

DESCRIPTION:
	Keyboard-driven mouse for hand-held PCs.  To use, set up your .ini
	file to read:

	[mouse]
	device = Arrow Key Mouse (Use Ins, Del, and F4.)
	driver = kbmouse.geo				(or kbmouseec.geo if EC)


	$Id: kbmouse.asm,v 1.1 97/04/18 11:48:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse			= 1

MOUSE_NUM_BUTTONS	= 2
MOUSE_FLAGS		= mask MDIF_KEYBOARD_ONLY	; yes, we're kbd only

MOUSE_CANT_SET_RATE	= 1	;cannot set the report rate for this mouse.

MOUSE_SEPARATE_INIT	= 1	;We use a separate Init resource

MOUSE_DONT_ACCELERATE	= 1	;We'll handle acceleration in our monitor
MOUSE_COMBINE_DISCARD	= 1	;Discard new event if duplicate found.

;INDEPENDENT_ACCELERATION	;define this to any value to enable indep.
				;acceleration in X and Y axes.

MOUSE_PTR_FLAGS 	= mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE \
				or mask PF_DISEMBODIED_PTR

include		mouseCommon.asm	; Include common definitions/code.

include		Internal/im.def
include		Internal/videoDr.def
include		Objects/inputC.def
include		win.def
include		timer.def


;------------------------------------------------------------------------------
;				DEVICE STRINGS
;------------------------------------------------------------------------------

MouseExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

mouseExtendedInfo	DriverExtendedInfoTable <
		{},				; lmem header added by Esp
		length mouseNameTable,		; Number of supported devices
		offset mouseNameTable,
		offset mouseInfoTable
>

mouseNameTable	lptr.char	kbMouseName
		lptr.char	0		; null-terminator

; NOTE!  If the following device string is changed, the UI (userMain.asm), &
; any other place that loads this driver directly will have to be changed 
; to match.	-- Doug 1/93
;
LocalDefString	kbMouseName <'Arrow Key Mouse (Use F4, Ins, and Del.)', 0>

mouseInfoTable	MouseExtendedInfo	\
		0				; kbMouse

MouseExtendedInfoSeg	ends
		
;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

MOUSE_INITIAL_X_DELTA		equ	1*256		;32
MOUSE_X_ACCELERATION		equ	32
MOUSE_MAX_X_ACCELERATION	equ	8*256

ifdef INDEPENDENT_ACCELERATION
MOUSE_INITIAL_Y_DELTA		equ	1*256		;32
MOUSE_Y_ACCELERATION		equ	32
MOUSE_MAX_Y_ACCELERATION	equ	8*256
endif

MOUSE_CONTINUAL_TIMER_INITIAL_INTERVAL	equ	1	;1/60ths of a second
MOUSE_CONTINUAL_TIMER_INTERVAL		equ	1	;1/60ths of a second

;This structure is used to indicate the current direction of the mouse
;pointer. Notice that at least 8 directions are supported. If we permit
;independent acceleration for X and Y, than many directions will be available.
;DO NOT RE-ARRANGE THESE FIELDS.

KBMouseDirection	record
    KBMD_UP:1
    KBMD_DOWN:1
    KBMD_RIGHT:1
    KBMD_LEFT:1
    :4
KBMouseDirection	end

MASK_KBMD_ANY_DIRECTION		equ	mask KBMD_UP or mask KBMD_DOWN or \
					mask KBMD_RIGHT or mask KBMD_LEFT

;Fatal Errors:

KBMOUSE_ERROR				enum FatalErrors


;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

mouseMonitor	Monitor	<>	;monitor structure

mouseSet	byte	0	;non-zero if device-type set

mouseDirection	KBMouseDirection <>
				;current direction of mouse

mouseXDeltaBB	word	MOUSE_INITIAL_X_DELTA

ifdef INDEPENDENT_ACCELERATION
mouseYDeltaBB	word	MOUSE_INITIAL_Y_DELTA
endif

mouseButtonState	MouseButtonBits <
			  1,	;all off (1) by default
			  1,
			  1,
			  1
			>

mouseArrowKeyCatch	byte	FALSE
				;TRUE if we want mouse ptr image to be shown.
				;This is set if the user presses F4, & also
				;when exiting, so as to return the mouse ptr
				;image to the unhidden status it had when
				;this driver was launched.

mouseArrayDisplayed	byte	TRUE
				;TRUE if we aren't between HIDE & SHOW calls
				;to the video driver.

mouseTimerID	word
mouseTimerHandle hptr		;handle of timer we use to provide continuous
				;mouse movement, even though keyboards don't
				;work that way.

;this variable is not used.

mouseRates	label	byte	; to avoid assembly errors
MOUSE_NUM_RATES	equ	0

idata	ends

;---------------------------

Resident segment resource

Init segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		bx = default # of buttons

RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseReset	proc	far
		uses cx, dx, di, ds, si
		.enter

if 0
;HERE: usually, we call the DOS-level mouse driver at this point.
;we do not need to do this.
		mov	ax, MF_RESET
		int	51
endif

		.leave
farRet		label	far
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

	call	MouseReset

	; Install a monitor to read the actual motion counters from the driver.
	;
	mov	bx, offset mouseMonitor
	mov	al, ML_DRIVER+1		;KBMouse: Gene suggests
					;driver+1 level
	mov	cx, Resident
	mov	dx, offset MouseMonitor
	call	ImAddMonitor

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

		; Remove the input monitor
		;
		segmov	ds, dgroup, bx
		mov	bx, offset mouseMonitor
		mov	al, mask MF_REMOVE_IMMEDIATE
		call	ImRemoveMonitor

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

	call	MouseReset
	tst	ax
	mov	ax, DP_PRESENT
	jnz	done

	mov	ax, DP_NOT_PRESENT

done:		
	.leave
	ret
MouseTestDevice	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MouseMonitor

DESCRIPTION:	This routine is the "monitor" that we install into the
		input stream. The Input Manager calls this routine,
		to see if we want to mangle any events that are coming through.

CALLED BY:	ProcessUserInput (IM library)

PASS:		al 		- MF_DATA
		di		- event type	(MSG_META_KBD_CHAR)
		cx, dx, bp, si 	- event data	(
						cx = character value
						dl = CharFlags
						dh = ShiftState
						bp low = ToggleState
						bp high = scan code
		ds		- segment of Monitor being called
		bx		- offset within segment to Monitor
		ss:sp 		- stack frame of Input Manager

RETURN:		al		- flags about result:
					MF_DATA	= data returned
				(clear all flags if event has been swallowed)

		di		- event type
		cx, dx, bp, si 	- event data
		ss:sp		- unchanged
		ah, bx, ds, es	- trashed

OK TO DESTROY:	ax, bx, cx, dx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

MouseMonitor	proc	far
	uses	bx
	.enter

	;make sure is a keyboard event, and that it is the first or repeat
	;press, or a release.

	cmp	di, MSG_META_KBD_CHAR
	jne	done			;skip to end if not...

	;we only care about first presses, and releases

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS or \
							mask CF_RELEASE
	jz	done			;skip to end if not...

;------------------------------------------------------------------------------
	;check for the F4 key

	tst	dh			;should be F4 with no ShiftState
	jnz	10$
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F4				>
DBCS <	cmp	cx, C_SYS_F4						>
	jne	10$
	test	dl, mask CF_FIRST_PRESS
	jz	done			;done if not a press

if	(0)
	not	ds:[mouseArrowKeyCatch]	;toggle state
	jnz	done			;skip if is now TRUE...

	;reset velocity of mouse.
	;(this kind of bothers me... I feel like I should be grabbing
	;a semaphore before I do this.)

	clr	ds:[mouseDirection]
	mov	ds:[mouseXDeltaBB], MOUSE_INITIAL_X_DELTA
ifdef INDEPENDENT_ACCELERATION
	mov	ds:[mouseYDeltaBB], MOUSE_INITIAL_Y_DELTA
endif

else
	; Turn mouse mode ON anytime F4 hit
	mov	ds:[mouseArrowKeyCatch], TRUE	;turn mouse mode on
endif
	clr	al			;we have eaten this event
	jmp	short done		;skip to end...

;------------------------------------------------------------------------------
10$:
	; if "mouseArrowKeyCatch" is true, then check for some extra keys
	;
	tst	ds:[mouseArrowKeyCatch]
	jz	done


;------------------------------------------------------------------------------

; Don't need to specially check escape key, since any non-modifier nukes
; mouse mode.
;
if	(0)
	;check for the ESCAPE key

	cmp	cx, (CS_CONTROL shl 8) or VC_ESCAPE
	jne	20$
	test	dl, mask CF_FIRST_PRESS
	jz	done			;done if not a press...

	; Turn mouse mode OFF anytime ESC hit
	mov	ds:[mouseArrowKeyCatch], 0	; turn off mouse mode

	;reset velocity of mouse.
	;(this kind of bothers me... I feel like I should be grabbing
	;a semaphore before I do this.)

	clr	ds:[mouseDirection]
	mov	ds:[mouseXDeltaBB], MOUSE_INITIAL_X_DELTA
ifdef INDEPENDENT_ACCELERATION
	mov	ds:[mouseYDeltaBB], MOUSE_INITIAL_Y_DELTA
endif
	jmp	short done		;skip to end...
endif

;------------------------------------------------------------------------------
20$:

;If we use the Ctrl key as the left button, and the Ctrl & Alt key as the
;right button, then we must ignore the shift state.
;	tst	dh			;ShiftState
;	jnz	done

    	;Check for keys we map to RIGHT mouse button here
	mov	bl, mask MOUSE_B2
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_DEL	;check for DEL key >
DBCS <	cmp	cx, C_SYS_DELETE			;check for DEL key >
	je	mouseButtonKeyPressed
							;check for numpad period
							; (shifted DEL)
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_NUMPAD_PERIOD		>
DBCS <	cmp	cx, C_SYS_NUMPAD_PERIOD					>
	je	mouseButtonKeyPressed

; This is a problem as well, for the same reason as below -- conflicts w/
; standard keyboard-based usage (i.e. tabbing around fields) -- Doug 6/92
;
;	cmp	cx, (CS_CONTROL shl 8) or VC_TAB	;check for TAB key
;	je	mouseButtonKeyPressed

	;Check for keys we map to LEFT mouse button here
	mov	bl, mask MOUSE_B0
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_INS	;check for INS key >
DBCS <	cmp	cx, C_SYS_INSERT			;check for INS key >
	je	mouseButtonKeyPressed
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_NUMPAD_0	;check for 0	>
DBCS <	cmp	cx, C_SYS_NUMPAD_0			;check for 0	>
	je	mouseButtonKeyPressed			; (shifted INS)

; These are problems.  They conflict w/standard keyboard usage, & the first
; actually makes it near impossible to get past the mouse installation
; screen in graphical setup.  Users will just have to learn to use the INS
; key for the left mouse button if they are to use this option. -- Doug 6/92
;
;	cmp	cx, (CS_CONTROL shl 8) or VC_ENTER	;check for ENTER key
;	je	mouseButtonKeyPressed
;	cmp	cx, VC_BLANK				;check for SPACE key
;	je	mouseButtonKeyPressed

	jmp	50$

mouseButtonKeyPressed:
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	30$			;skip if is released...

	;key is pressed

	not	bl
	ANDNF	ds:[mouseButtonState], bl
	jmp	short forceEvent

30$:	;key is not pressed
	ORNF	ds:[mouseButtonState], bl

forceEvent:
	;if the mouse is not moving, then we cannot rely upon the next
	;timer firing to send events out.

	test	ds:[mouseDirection], MASK_KBMD_ANY_DIRECTION
	jnz	done			;skip if is moving...

	call	MouseTimerExpired

	clr	al			;we have eaten this event
	jmp	short done

;------------------------------------------------------------------------------
50$:	;see if is an arrow key

;	test	dl, mask CF_EXTENDED
;	jz	done

	;convert cx to 0-3 value (up, down, right, left)

	push	cx

	; Convert NUMPAD numbers to arrow keys they represent.  Allows
	; us to process SHIFT-<arrow key> correctly.
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_NUMPAD_8			>
DBCS <	cmp	cx, C_SYS_NUMPAD_8					>
	jne	51$
SBCS <	mov	cx, (CS_CONTROL shl 8) or VC_UP				>
DBCS <	mov	cx, C_SYS_UP						>
51$:
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_NUMPAD_4			>
DBCS <	cmp	cx, C_SYS_NUMPAD_4					>
	jne	52$
SBCS <	mov	cx, (CS_CONTROL shl 8) or VC_LEFT			>
DBCS <	mov	cx, C_SYS_LEFT						>
52$:
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_NUMPAD_6			>
DBCS <	cmp	cx, C_SYS_NUMPAD_6					>
	jne	53$
SBCS <	mov	cx, (CS_CONTROL shl 8) or VC_RIGHT			>
DBCS <	mov	cx, C_SYS_RIGHT						>
53$:
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_NUMPAD_2			>
DBCS <	cmp	cx, C_SYS_NUMPAD_2					>
	jne	54$
SBCS <	mov	cx, (CS_CONTROL shl 8) or VC_DOWN			>
DBCS <	mov	cx, C_SYS_DOWN						>
54$:

SBCS <	sub	cx, (CS_CONTROL shl 8) or VC_UP				>
DBCS <	sub	cx, C_SYS_UP						>
	js	notArrow

SBCS <	cmp	cx, VC_LEFT-VC_UP					>
DBCS <	cmp	cx, C_SYS_LEFT-C_SYS_UP					>
	ja	notArrow

	;using index in CL, determine new direction status

	call	MouseDetermineDirectionStatus
	pop	cx
	clr	al			;we have eaten this event
	jmp	short done

;------------------------------------------------------------------------------
notArrow:
	pop	cx

	;check for ANY non-state key

	test	dl, mask CF_STATE_KEY
	jnz	done			;allows modifiers...

	; Something else hit -- turn OFF mouse mode.
	;
	mov	ds:[mouseArrowKeyCatch], 0	; turn off mouse mode

	;reset velocity of mouse.
	;(this kind of bothers me... I feel like I should be grabbing
	;a semaphore before I do this.)

	clr	ds:[mouseDirection]
	mov	ds:[mouseXDeltaBB], MOUSE_INITIAL_X_DELTA
ifdef INDEPENDENT_ACCELERATION
	mov	ds:[mouseYDeltaBB], MOUSE_INITIAL_Y_DELTA
endif

;------------------------------------------------------------------------------
done:
	push	ax
	; See if mouse visibility set correctly
	;
	mov	al, ds:[mouseArrowKeyCatch]
	cmp	al, ds:[mouseArrayDisplayed]
	je	90$

	; If not, call routine to get it there.
	call	SetMouseVisibility
90$:
	pop	ax
	.leave
	ret

MouseMonitor	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	SetMouseVisibility

DESCRIPTION:	Set mouse to be visible or hidden, depending on whether we're
		in "mouse" mode or not

CALLED BY:	INTERNAL
		MouseMonitor

PASS:		ds	- idata

RETURN:		nothing

DESTROYED:	nothing, flags preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/92		Initial version
------------------------------------------------------------------------------@

SetMouseVisibility	proc	far
	uses	ax
	.enter
	pushf

	mov	al, ds:[mouseArrowKeyCatch]
	mov	ds:[mouseArrayDisplayed],al	; store to indicated updated
						; (since we're about to do
						; just that)

	tst	al				; check state

	mov	ax, (mask PF_DISEMBODIED_PTR or \
		    mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE) shl 8

	jnz	gotFlags

	xchg	al, ah

gotFlags:
	call	ImSetPtrFlags
	popf

	.leave
	ret

SetMouseVisibility	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	MouseDetermineDirectionStatus

DESCRIPTION:	Determine the new direction for the mouse.

CALLED BY:	MouseMonitor

PASS:		ds	= dgroup
		cl	= index indicating which arrow key is pressed or
				released
		dl = CharFlags

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

MouseDetermineDirectionStatus	proc	near
	;this is a legal arrow key press or release

EC <	cmp	cl, 3							>
EC <	ERROR_A	KBMOUSE_ERROR						>

	.assert (mask KBMD_UP) eq 0x80
	mov	al, mask KBMD_UP	;set this flag
	shr	al, cl
	clr	ah			;clear no flags

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jnz	haveMask

	xchg	al, ah			;key has been released: plan on
					;clearing a bit flag instead

haveMask:
	;al = KBMouseDirectionStruct flags to set
	;ah = KBMouseDirectionStruct flags to clear

	mov	bl, ds:[mouseDirection]	;get current flags
	ORNF	bl, al			;set a flag
	not	ah			;prepare to clear flags
	ANDNF	bl, ah			;reset a flag

	test	ds:[mouseDirection], MASK_KBMD_ANY_DIRECTION
	jnz	wasAlreadyMoving

wasNotMoving:
	ForceRef wasNotMoving

	;was not moving: if is moving now, then start the timer

	test	bl, MASK_KBMD_ANY_DIRECTION
	jz	saveNewDirection	;skip if still not moving...

	push	bx
	mov	al, TIMER_ROUTINE_CONTINUAL
	mov	bx, segment Resident	;bx:si = fixed timer routine
	mov	si, offset Resident:MouseTimerExpired
	mov	cx, MOUSE_CONTINUAL_TIMER_INITIAL_INTERVAL
					;timer count until first timeout
	mov	di, MOUSE_CONTINUAL_TIMER_INTERVAL
					;timer interval
	call	TimerStart
	mov	ds:[mouseTimerID], ax	;save timer ID
	mov	ds:[mouseTimerHandle], bx ;save timer handle
	pop	bx
	jmp	short saveNewDirection

wasAlreadyMoving:
	;was moving: if has stopped, then kill the timer

	test	bl, MASK_KBMD_ANY_DIRECTION
	jnz	saveNewDirection	;skip if still moving...

	;ALL STOP!

	push	bx
	mov	ax, ds:[mouseTimerID]
	mov	bx, ds:[mouseTimerHandle]
	call	TimerStop
EC <	ERROR_C KBMOUSE_ERROR						>

	;this kind of bothers me... I feel like I should be grabbing
	;a semaphore before I do this.

	mov	ds:[mouseXDeltaBB], MOUSE_INITIAL_X_DELTA
ifdef INDEPENDENT_ACCELERATION
	mov	ds:[mouseYDeltaBB], MOUSE_INITIAL_Y_DELTA
endif
	pop	bx

saveNewDirection:
	;IMPORTANT: this should be an atomic operation (in case the kernel
	;thread interrupts, to deliver a timer event -- this byte value
	;will be read in that case.)

	mov	ds:[mouseDirection], bl
	ret
MouseDetermineDirectionStatus	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MouseTimerExpired

DESCRIPTION:	

CALLED BY:	kernel

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

MouseTimerExpired	proc	far
if 0
PrintMessage <TEST>
	mov	ax, 0xB800
	mov	ds, ax
	inc	ds:[5]
endif

	mov	ax, segment idata
	mov	ds, ax

	mov	al, ds:[mouseDirection]
	call	MouseGetDeltas

	mov	bh, ds:[mouseButtonState]

;	mov	bh, mask MOUSE_B3 or mask MOUSE_B0 or \
;		    mask MOUSE_B1 or mask MOUSE_B2
;					;bh = MouseButtonBits (0 means pushed)

					;pass ds = idata segment for this driver
	call	MouseSendEvents
	ret
MouseTimerExpired	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MouseGetDeltas

DESCRIPTION:	

CALLED BY:	MouseTimerExpired

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

ifndef INDEPENDENT_ACCELERATION	;----------------------------------------------

MouseGetDeltas	proc	near

;simple acceleration

checkXDirection:
	ForceRef checkXDirection

	;check X direction

	clr	cx
	test	al, mask KBMD_LEFT or mask KBMD_RIGHT
	jz	checkYDirection

;movingHorizontally:
	mov	cl, ds:[mouseXDeltaBB].high
					;ignore fractional portion

	test	al, mask KBMD_RIGHT
	jnz	checkYDirection

	neg	cx

checkYDirection:
	;check Y direction

	clr	dx
	test	al, mask KBMD_UP or mask KBMD_DOWN
	jz	updateAcceleration

;movingVertically:
	mov	dl, ds:[mouseXDeltaBB].high
					;ignore fractional portion

	test	al, mask KBMD_DOWN
	jnz	updateAcceleration

	neg	dx

updateAcceleration:
	test	al, MASK_KBMD_ANY_DIRECTION
	jz	done

	cmp	ds:[mouseXDeltaBB], MOUSE_MAX_X_ACCELERATION
	jae	done

	add	ds:[mouseXDeltaBB], MOUSE_X_ACCELERATION

done:
	ret
MouseGetDeltas	endp


else	;----------------------------------------------------------------------


MouseGetDeltas	proc	near

;complex acceleration

checkXDirection:
	ForceRef checkXDirection

	;check X direction

	clr	cx
	test	al, mask KBMD_LEFT or mask KBMD_RIGHT
	jnz	movingHorizontally

	;stopped moving horizontally

	mov	ds:[mouseXDeltaBB], MOUSE_INITIAL_X_DELTA
	jmp	short checkYDirection
	
movingHorizontally:
	mov	cl, ds:[mouseXDeltaBB].high
					;ignore fractional portion

	cmp	ds:[mouseXDeltaBB], MOUSE_MAX_X_ACCELERATION
	jae	10$

	add	ds:[mouseXDeltaBB], MOUSE_X_ACCELERATION

10$:
	test	al, mask KBMD_RIGHT
	jnz	checkYDirection

	neg	cx

checkYDirection:
	;check Y direction

	clr	dx
	test	al, mask KBMD_UP or mask KBMD_DOWN
	jnz	movingVertically

	mov	ds:[mouseYDeltaBB], MOUSE_INITIAL_Y_DELTA
	jmp	short done
	
movingVertically:
	mov	dl, ds:[mouseYDeltaBB].high
					;ignore fractional portion

	cmp	ds:[mouseYDeltaBB], MOUSE_MAX_Y_ACCELERATION
	jae	20$

	add	ds:[mouseYDeltaBB], MOUSE_Y_ACCELERATION

20$:
	test	al, mask KBMD_DOWN
	jnz	done

	neg	dx

done:
	ret
MouseGetDeltas	endp

endif	;----------------------------------------------------------------------

Resident ends
