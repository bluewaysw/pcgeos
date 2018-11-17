COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Any Mouse in IBM PS/2 port
FILE:		ps2.asm

AUTHOR:		Adam de Boor, September 29, 1989

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Initialize device
	MouseDevExit		Exit device
	MouseDevHandler		Interrupt routine
	MouseDevSetRate		Routine to change rate.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/29/89		Initial revision


DESCRIPTION:
	Device-dependent support for PS2 mouse port. The PS2 BIOS defines
	a protocol that all mice connected to the port employ. Rather
	than interpreting it ourselves, we trust the BIOS to be efficient
	and just register a routine with it. Keeps the driver smaller and
	avoids problems with incompatibility etc.
		
	$Id: ps2.asm,v 1.1 97/04/18 11:47:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
MOUSE_NUM_BUTTONS = 2		; Most have only 2
MOUSE_MIN_BUTTONS = 1		; Maybe something has 1...Better give us
		  		; the state on the left button...
MOUSE_IM_MAX_BUTTONS = 3		; This be all we can handle.
MOUSE_SEPARATE_INIT = 1		; We use a separate Init resource

include		../mouseCommon.asm	; Include common definitions/code.

include		Internal/interrup.def
include		Internal/dos.def	; for equipment configuration...
include		system.def

ifdef	CHECK_MOUSE_AFTER_POWER_RESUME
include		Internal/powerDr.def
include		ui.def

CHECK_MOUSE_AFTER_POWER_RESUME_DELAY	equ	6	; # ticks
endif

LOG_EVENTS	= FALSE

if LOG_EVENTS
%out EVENT LOGGING IS ON. ARE YOU SURE YOU WANT THAT?
endif

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

if PZ_PCGEOS
mouseNameTable	lptr.char	msps2
		lptr.char	0	; null-terminator

LocalDefString msps2		<'Microsoft PS/2 Mouse', 0>

mouseInfoTable	MouseExtendedInfo	\
		0		; msps2

else
mouseNameTable	lptr.char	ibmPS2Mouse,
				int12Mouse,
				auxPortMouse,
				ps2StyleMouse,
				logips2,
				logiSeries2,
				msps2,
				logiPS2TrackMan
		lptr.char	0	; null-terminator

LocalDefString ibmPS2Mouse	<'IBM PS/2 Mouse', 0>
LocalDefString int12Mouse	<'Interrupt-12-type Mouse', 0>
LocalDefString auxPortMouse	<'Auxiliary Port Mouse', 0>
LocalDefString ps2StyleMouse	<'PS/2-style Mouse', 0>
LocalDefString logips2		<'Logitech PS/2 Mouse', 0>
LocalDefString logiSeries2	<'Logitech Series 2 Mouse', 0>
LocalDefString msps2		<'Microsoft PS/2 Mouse', 0>
LocalDefString logiPS2TrackMan	<'Logitech TrackMan Portable (PS/2-style)', 0>

mouseInfoTable	MouseExtendedInfo	\
		0,		; ibmPS2Mouse
		0,		; int12Mouse
		0,		; auxPortMouse
		0,		; ps2StyleMouse
		0,		; logips2
		0,		; logiSeries2
		0,		; msps2
		0		; logiPS2TrackMan

ifdef	CHECK_MOUSE_AFTER_POWER_RESUME

;
; The following strings actually have nothing to do with the driver extended
; info.  They are placed here only because they need to be localizable and
; need to be in an lmem resource.  Creating a separate lmem resource for them
; seems overkill, so we put them in MouseExtendedInfoSeg to save some bytes.
;

LocalDefString	mouseNotConnectedErrorStr	<'The mouse is not connected.  Please turn off your PC, re-connect the mouse, then turn on the PC again.  (Or, you can press the Enter key to continue using Ensemble without a mouse.)', 0>
	localize "This is the string that is displayed when the mouse is not connected during power-on.  The user must power-off and on for the mouse to work."

LocalDefString	mouseNotConnectedErrorReconnectStr	<'The mouse is not connected.  Please re-connect the mouse and then press the Enter key.  (Or, you can press the Esc key to continue using Ensemble without a mouse.)', 0>
	localize "This is the string that is displayed when the mouse is not connected during power resume.  The user doesn't need to power-off and on for the mouse to work again."

endif	; CHECK_MOUSE_AFTER_POWER_RESUME

endif

MouseExtendedInfoSeg	ends
		
;------------------------------------------------------------------------------
;			    VARIABLES/DATA/CONSTANTS
;------------------------------------------------------------------------------
idata		segment

;
; All the mouse BIOS calls are through interrupt 15h, function c2h.
; All functions return CF set on error, ah = MouseStatus
;
MOUSE_ENABLE_DISABLE	equ	0c200h	; Enable or disable the mouse.
					;  BH = 0 to disable, 1 to enable
MOUSE_RESET		equ	0c201h	; Reset the mouse.
MAX_NUM_RESETS		equ	3	; # times we will send MOUSE_RESET
					;  command	

MOUSE_SET_RATE		equ	0c202h	; Set sample rate:
    MOUSE_RATE_10	equ	0
    MOUSE_RATE_20	equ	1
    MOUSE_RATE_40	equ	2
    MOUSE_RATE_60	equ	3
    MOUSE_RATE_80	equ	4
    MOUSE_RATE_100	equ	5
    MOUSE_RATE_200	equ	6

MOUSE_SET_RESOLUTION	equ	0c203h	; Set device resolution BH =
    MOUSE_RES_1_PER_MM	equ	0	;  1 count per mm
    MOUSE_RES_2_PER_MM	equ	1	;  2 counts per mm
    MOUSE_RES_4_PER_MM	equ	2	;  4 counts per mm
    MOUSE_RES_8_PER_MM	equ	3	;  8 counts per mm

MOUSE_GET_TYPE		equ	0c204h	; Get device ID.

MOUSE_INIT		equ	0c205h	; Set interface parameters
					;  BH = # bytes per packet.

MOUSE_EXTENDED_CMD	equ	0c206h	; Extended command. BH =
    MOUSE_EXTC_STATUS	equ	0	; Get device status
    MOUSE_EXTC_SINGLE_SCALE equ 1	; Set scaling to 1:1
    MOUSE_EXTC_DOUBLE_SCALE equ 2	; Set scaling to 2:1

MOUSE_SET_HANDLER	equ	0c207h	; Set mouse handler.
					;  ES:BX is address of routine

MouseStatus		etype	byte
MS_SUCCESSFUL		enum	MouseStatus, 0
MS_INVALID_FUNC		enum	MouseStatus, 1
MS_INVALID_INPUT	enum	MouseStatus, 2
MS_INTERFACE_ERROR	enum	MouseStatus, 3
MS_NEED_TO_RESEND	enum	MouseStatus, 4
MS_NO_HANDLER_INSTALLED	enum	MouseStatus, 5

mouseRates	byte	10, 20, 40, 60, 80, 100, 200, 255
MOUSE_NUM_RATES	equ	size mouseRates
mouseRateCmds	byte	MOUSE_RATE_10, MOUSE_RATE_20, MOUSE_RATE_40
		byte	MOUSE_RATE_60, MOUSE_RATE_80, MOUSE_RATE_100
		byte	MOUSE_RATE_200, MOUSE_RATE_200

idata		ends

udata		segment

ifdef	CHECK_MOUSE_AFTER_POWER_RESUME
errorDialogOnScreen	BooleanByte	BB_FALSE
endif

udata		ends

MDHStatus	record
    MDHS_Y_OVERFLOW:1,		; Y overflow
    MDHS_X_OVERFLOW:1,		; X overflow
    MDHS_Y_NEGATIVE:1,		; Y delta is negative (just need to
				;  sign-extend, as delta is already in
				;  single-byte two's complement form)
    MDHS_X_NEGATIVE:1,		; X delta is negative
    MDHS_MUST_BE_ONE:1=1,
    MDHS_MIDDLE_DOWN:1,		; Middle button is down
    MDHS_RIGHT_DOWN:1,		; Right button is down
    MDHS_LEFT_DOWN:1,		; Left button is down
MDHStatus	end
if	LOG_EVENTS
udata		segment
xdeltas		byte	1024 dup (?)
ydeltas		byte	1024 dup (?)
statii		MDHStatus	1024 dup (?)
index		word	0
udata		ends
endif

;------------------------------------------------------------------------------
;		       INITIALIZATION/EXIT CODE
;
;------------------------------------------------------------------------------

Resident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HandleMem the receipt of an interrupt

CALLED BY:	BIOS
PASS:		ON STACK:
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Overflow is ignored.

	For delta Y, positive => up, which is the opposite of what we think

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Some BIOSes rely on DS not being altered, while others do not.
	To err on the side of safety, we save everything we biff.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevHandler	proc	far	deltaZ:sbyte,
				:byte,		; For future expansion
				deltaY:sbyte,
				:byte,		; FFE
				deltaX:sbyte,
				:byte,		; FFE
				status:MDHStatus
		uses	ds, ax, bx, cx, dx, si, di
		.enter
	;
	; Prevent switch while sending
	;
		call	SysEnterInterrupt

if	LOG_EVENTS
		segmov	ds, dgroup, bx
		mov	bx, ds:[index]
		mov	al, ss:[deltaY]
		mov	ds:ydeltas[bx], al
		mov	al, ss:[deltaX]
		mov	ds:xdeltas[bx], al
		mov	al, ss:[status]
		mov	ds:statii[bx], al
		inc	bx
		andnf	bx, length ydeltas - 1
		mov	ds:[index], bx
endif

	;
	; The deltas are already two's-complement, so just sign extend them
	; ourselves.
	; XXX: verify sign against bits in status byte to confirm its validity?
	; what if overflow bit is set?
	;
		mov	al, ss:[deltaY]
		cbw
		xchg	dx, ax			; (1-byte inst)

		mov	al, ss:[deltaX]
		cbw
		xchg	cx, ax			; (1-byte inst)
	;
	; Fetch the status, copying the middle and right button bits
	; into BH.
	;
		mov	al, ss:[status]
		test	al, mask MDHS_Y_OVERFLOW or mask MDHS_X_OVERFLOW
		jnz	packetDone	; if overflow, drop the packet on the
					;  floor, since the semantics for such
					;  an event are undefined...
		mov	bh, al
		and	bh, 00000110b
		
	;
	; Make sure the packet makes sense by checking the ?_NEGATIVE bits
	; against the actual signs of their respective deltas. If the two
	; don't match (as indicated by the XOR of the sign bit of the delta
	; with the ?_NEGATIVE bit resulting in a one), then hooey this packet.
	;
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
	;
	; Mask out all but the left button and merge it into the
	; middle and right buttons that are in BH. We then have
	;	0000LMR0
	; in BH, which is one bit off from what we need (and also
	; the wrong polarity), so shift it right once and complement
	; the thing.
	;
		and	al, mask MDHS_LEFT_DOWN shl 3
		or	bh, al
		shr	bh, 1
		not	bh
	;
	; Make delta Y be positive if going down, rather than
	; positive if up, as the BIOS provides it.
	;
		neg	dx
	;
	; Point ds at our data for MouseSendEvents
	;
		mov	ax, segment dgroup
		mov	ds, ax
	;
	; Registers now all loaded properly -- send the event.
	;
		call	MouseSendEvents
	;
	; Allow context switches.
	; 
packetDone:
		call	SysExitInterrupt
	;
	; Recover and return.
	; 
		.leave
		ret
MouseDevHandler	endp

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on the device.

CALLED BY:	MouseSetDevice, MouseCheckDevAfterResumeStep3
PASS:		nothing
RETURN:		CF set on error
			ah	= MouseStatus
DESTROYED:	al, bx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/17/00    	Initial version (moved code from
				MouseSetDevice)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevInit	proc	far

		call	SysLockBIOS

	;
	; These are all done in this order by the Microsoft PS/2 mouse
	; driver. I suspect the really important one is setting the
	; report rate to 60, else RESEND bytes get inserted into the
	; packet stream...
	;
		mov	ax, MOUSE_SET_RESOLUTION
		mov	bh, MOUSE_RES_8_PER_MM
		int	15h

		segmov	es, <segment Resident>
		mov	bx, offset Resident:MouseDevHandler
		mov	ax, MOUSE_SET_HANDLER
		int	15h

		mov	ax, MOUSE_ENABLE_DISABLE
		mov	bh, 1		; Enable it please
		int	15h

		mov	ax, MOUSE_EXTENDED_CMD
		mov	bh, MOUSE_EXTC_SINGLE_SCALE
		int	15h

		mov	ax, MOUSE_SET_RATE
		mov	bh, MOUSE_RATE_60
		int	15h

		call	SysUnlockBIOS

		ret
MouseDevInit	endp

Init	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish things out

CALLED BY:	MouseExit
PASS:		DS=ES=CS
RETURN:		Carry clear
DESTROYED:	BX, AX

PSEUDO CODE/STRATEGY:
		Just calls the serial driver to close down the port

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevExit	proc	near

ifdef	CHECK_MOUSE_AFTER_POWER_RESUME
		;
		; Unhook from power driver for on/off notification.
		;
		push	di
		mov	di, DR_POWER_ON_OFF_UNREGISTER
		call	OnOffNotifyRegUnreg
		pop	di
endif	; CHECK_MOUSE_AFTER_POWER_RESUME

		;
		; Disable the mouse by setting the handler to 0
		; XXX: How can we restore it? Do we need to?
		;
		mov	ax, MOUSE_ENABLE_DISABLE
		mov	bh, 0		; Disable it please
		int	15h
		
		clr	bx
		mov	es, bx
		mov	ax, MOUSE_SET_HANDLER
		int	15h
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
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version
	ayuen	10/17/00	Moved most of the code to MouseDevInit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetDevice	proc	near	uses es, bx, ax
		.enter

		call	MouseDevInit

ifdef	CHECK_MOUSE_AFTER_POWER_RESUME
	;
	; Hook up to the power driver, so that we get on/off notified on a
	; power resume.
	;
		push	di
		mov	di, DR_POWER_ON_OFF_NOTIFY
		call	OnOffNotifyRegUnreg
		pop	di
endif	; CHECK_MOUSE_AFTER_POWER_RESUME

		.leave
		ret
MouseSetDevice	endp

ifdef	CHECK_MOUSE_AFTER_POWER_RESUME

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OnOffNotifyRegUnreg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register/unregister with the PM driver for on/off notification

CALLED BY:	MouseSetDevice, MouseDevExit
PASS:		di	= DR_POWER_ON_OFF_NOTIFY / DR_POWER_ON_OFF_UNREGISTER
RETURN:		CF set if driver not present or too many callbacks registered
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/16/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OnOffNotifyRegUnreg	proc	far
	uses	ds
	.enter
	pusha

	mov	ax, GDDT_POWER_MANAGEMENT
	call	GeodeGetDefaultDriver	; ax = driver handle
	tst	ax
	stc				; assume not present
	jz	afterRegister		; => driver not present

	mov_tr	bx, ax			; bx = driver handle
	call	GeodeInfoDriver		; ds:si = DriverInfoStruct
	mov	dx, segment MouseCheckDevAfterResume
	mov	cx, offset MouseCheckDevAfterResume
	call	ds:[si].DIS_strategy	; CF set on error

afterRegister:
	popa
	.leave
	ret
OnOffNotifyRegUnreg	endp

Init	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseCheckDevAfterResume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for on/off notification

CALLED BY:	Power driver
PASS:		ax	= PowerNotifyChange
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Here's the scenario:

	If the mouse is not connected, both MOUSE_ENABLE_DISABLE(BH=1) and
	MOUSE_GET_TYPE return MS_INTERACE_ERROR.

	If the mouse was disconnected and then re-connected, it defaults to
	disabled state.  At this point Both MOUSE_GET_TYPE and
	MOUSE_ENABLE_DISABLE(BH=1) return no error.

	We can use MOUSE_GET_TYPE to check if the mouse is connected without
	touching its state, and inform the user if it's not.  But if we find
	that it is connected, we then have no way to check if it is enabled or
	not.  Then we still have to enable it again to make sure it is
	enabled.

	So, to simplify things, we just re-eanble the mouse and check for any
	errors.  The downside is that we will be re-enabling an enabled mouse
	which *may* re-initialize the mouse (I'm not sure), but I think that's
	okay.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/16/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseCheckDevAfterResume	proc	far
	uses	es
	.enter
	pusha

		CheckHack <PNC_POWER_TURNING_ON eq 1>
		CheckHack <PNC_POWER_TURNED_OFF_AND_ON eq 2>
		CheckHack <PowerNotifyChange eq 4>
	or	ax, ax
	jp	done			; => _SHUTTING_OFF or _AUTO_OFF

	;
	; It seems like If we try to enable the mouse right away during a
	; resume notification, it doesn't always work.  Sometimes BIOS
	; returns MS_INTERFACE_ERROR and the mouse acts funny afterwards.
	; Delaying the enable calls seems to solve the problem.  So we set a
	; timer to do it on the UI thread later.  0.1 sec seems to work fine.
	;
	; We can't call BIOS in a timer routine because it'll be in interrupt
	; time.  So we use the UI thread to call our routine to do the work.
	; But then we can't use MSG_PROCESS_CALL_ROUTINE to set up an event
	; timer either, because there's no way to pass parameters to a timer
	; event.  So, we have to use a routine timer to send the message to
	; the UI thread to call our routine.  On well ...
	;
	mov	al, TIMER_ROUTINE_ONE_SHOT
	mov	bx, segment MouseCheckDevAfterResumeStep2
	mov	si, offset MouseCheckDevAfterResumeStep2
	mov	cx, CHECK_MOUSE_AFTER_POWER_RESUME_DELAY
	mov	bp, handle 0
	call	TimerStartSetOwner
	; Timer is short enough that we don't need to worry about stopping it
	; on the next resume or on shutdown.

done:
	popa
	.leave
	ret
MouseCheckDevAfterResume	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseCheckDevAfterResumeStep2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the mouse after a power resume.

CALLED BY:	MouseCheckDevAfterResume via TimerStartSetOwner
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, dx, di, bp (everything allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/17/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseCheckDevAfterResumeStep2	proc	far

	;
	; Can't call BIOS during interrupt time, so do it on the UI thread.
	;
	mov	ax, SGIT_UI_PROCESS
	call	SysGetInfo			;ax = ui handle
	mov_tr	bx, ax
	push	vseg MouseCheckDevAfterResumeStep3
	push	offset MouseCheckDevAfterResumeStep3
	mov	bp, sp			; ss:bp = PCRP_address
	mov	ax, MSG_PROCESS_CALL_ROUTINE
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	mov	dx, size ProcessCallRoutineParams
	call	ObjMessage
	popdw	axax			; discard PCRP_address

	ret
MouseCheckDevAfterResumeStep2	endp

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseCheckDevAfterResumeStep3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the mouse after a power resume.

CALLED BY:	MouseCheckDevAfterResumeStep2 via MSG_PROCESS_CALL_ROUTINE
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bp, ds (everything allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/17/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
triggerTable	StandardDialogResponseTriggerTable <2>
	StandardDialogResponseTriggerEntry	<NULL, IC_OK>
	StandardDialogResponseTriggerEntry	<NULL, IC_DISMISS>

MouseCheckDevAfterResumeStep3	proc	far

checkAgain:
	call	MouseDevInit	; CF set on error, ah = MouseStatus
	jnc	done

	;
	; If the user hits On/Off button again while the dialog is still on
	; screen, this routine will be called on the UI thread again.  This
	; is because when the thread is blocked in UserStandardDialogOptr,
	; it can actually watch its message queue and keeps on processing
	; messages.  So this routine can be called again while the first call
	; is still blocked inside UserStandardDialogOptr.  In order to
	; prevent putting up two error dialogs on screen, we keep a flag
	; around, and skip putting up a dialog if one is already on screen.
	;
	segmov	ds, dgroup
	tst	ds:[errorDialogOnScreen]
	jnz	done			; => already on screen
	dec	ds:[errorDialogOnScreen]; BB_TRUE

	;
	; Display the dialog.
	;
	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, CustomDialogBoxFlags \
			<1, CDT_ERROR, GIT_MULTIPLE_RESPONSE, >
	mov	ss:[bp].SDOP_customString.handle, \
			handle mouseNotConnectedErrorReconnectStr
	mov	ss:[bp].SDOP_customString.chunk, \
			offset mouseNotConnectedErrorReconnectStr
	clr	ax			; for czr below
	czr	ax, ss:[bp].SDOP_stringArg1.handle, \
			ss:[bp].SDOP_stringArg2.handle, \
			ss:[bp].SDOP_helpContext.segment
	mov	ss:[bp].SDOP_customTriggers.segment, cs
	mov	ss:[bp].SDOP_customTriggers.offset, offset triggerTable
	call	UserStandardDialogOptr	; ax = InteractionCommand

	inc	ds:[errorDialogOnScreen]; BB_FALSE

	;
	; If the user pressed Enter, check the mouse again.
	;
	cmp	ax, IC_OK
	je	checkAgain

done:
	ret
MouseCheckDevAfterResumeStep3	endp

Init	ends

endif	; CHECK_MOUSE_AFTER_POWER_RESUME


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
MouseTestDevice	proc	near	uses bx, es, cx
		.enter
		mov	ax, BIOS_DATA_SEG
		mov	es, ax
		test	es:[BIOS_EQUIPMENT], mask EC_POINTER
		jz	notPresent
		
		mov	ax, MOUSE_INIT	; Assume 3-byte packets
		mov	bh, 3
		int	15h

		mov	cx, MAX_NUM_RESETS	;# times we will resend this
						; command
resetLoop:
		mov	ax, MOUSE_RESET
		int	15h
		jnc	noerror		;If no error, branch
		cmp	ah, MS_NEED_TO_RESEND
		jne	notPresent	;If not "resend" error, just exit with
					; carry set.
		loop	resetLoop	;
notPresent:

ifdef	CHECK_MOUSE_AFTER_POWER_RESUME
		call	DisplayMouseNotConnectedDialog
endif	; CHECK_MOUSE_AFTER_POWER_RESUME

		mov	ax, DP_NOT_PRESENT
		jmp	done
noerror:
		mov	ax, DP_PRESENT
done:		
		clc
		.leave
		ret
MouseTestDevice	endp

ifdef	CHECK_MOUSE_AFTER_POWER_RESUME

Init	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayMouseNotConnectedDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the mouse not connected error dialog.

CALLED BY:	MouseTestDevice
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/19/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayMouseNotConnectedDialog	proc	far
	pusha

	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, CustomDialogBoxFlags \
			<1, CDT_ERROR, GIT_NOTIFICATION, >
	mov	ss:[bp].SDOP_customString.handle, \
			handle mouseNotConnectedErrorStr
	mov	ss:[bp].SDOP_customString.chunk, \
			offset mouseNotConnectedErrorStr
	clr	ax			; for czr below
	czr	ax, ss:[bp].SDOP_stringArg1.handle, \
			ss:[bp].SDOP_stringArg2.handle, \
			ss:[bp].SDOP_helpContext.segment
	call	UserStandardDialogOptr

	popa
	ret
DisplayMouseNotConnectedDialog	endp

Init	ends

endif	; CHECK_MOUSE_AFTER_POWER_RESUME


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevSetRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the report rate for the mouse

CALLED BY:	MouseSetRate
PASS:		CX	= index of rate to set
RETURN:		carry clear if successful
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevSetRate	proc	near
		push	ax, bx, cx, si
		mov	si, cx
		mov	bh, ds:mouseRateCmds[si]
		mov	ax, MOUSE_SET_RATE
		int	15h
		pop	ax, bx, cx, si
		ret
MouseDevSetRate	endp

Resident ends

		end
