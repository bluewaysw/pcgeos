COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Kernel -- System notification
FILE:		sysError.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name		Description
	----		-----------
   GLB	SysNotify	HandleMem an error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version
	Cheng	9/89		Extended capability to handle floppy
				disk association messages and floppy disk
				prompting.
	Adam	2/90		Shifted into klib so we can avoid relocating
				kernel code.

DESCRIPTION:
	This file contains error handling routines.

	$Id: sysError.asm,v 1.1 97/04/05 01:14:57 newdeal Exp $

------------------------------------------------------------------------------@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the SysNotify box up on the current screen

CALLED BY:	SysNotify (Kernel)
PASS:		ax - SysNotifyFlags
		ds:si - first string to print (si = 0 for none)
		ds:di - second string to print (di = 0 for none)

RETURN:		If SNF_RETRY, SNF_ABORT, SNF_CONTINUE or SNF_EXIT passed and
		selected, returns same in ax to indicate action caller should
		take.
		
		If SNF_REBOOT passed and selected, this routine doesn't return.

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef HARDWARE_TYPE
HARDWARE_TYPE	equ	<PC>		; Choices include:
						;	PC
						;	ZOOMER (XIP only)
						;	BULLET (XIP only)

endif

SysNotify	proc	far	uses bx, cx, dx, si, di, es, ds, bp
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		tst	si				>
EC <		je	secondString			>
EC <		call	ECCheckBounds			>
secondString::
EC <		tst	di				>
EC <		je	xipOK				>
EC <		xchg	si, di				>
EC <		call	ECCheckBounds			>
EC <		xchg	si, di				>
xipOK::		
endif

ifdef	GPC_ONLY
	;
	; On GPC, we need to set the mapping windows to their unmapped states
	; so that we can perform video operations.
	;
		mov	cx, ds			; cx = string seg
		LoadVarSeg	ds
		INT_OFF
		call	UtilWindowSaveMapping	; old mappings saved on stack
		INT_ON
		mov	ds, cx			; ds = string seg

		mov_tr	cx, ax			; cx = SysNotifyFalgs
		mov	bx, -1			; no mapping
			.assert UTIL_WINDOW_NUM_WINDOWS eq 2
		clr	ax			; win 0
		call	MapUtilityWindow
		inc	ax			; win 1
		call	MapUtilityWindow
		mov_tr	ax, cx			; ax = SysNotifyFlags
endif	; GPC

		push	ds, di
		segmov	ds, dgroup, di
		PSem	ds, errorSem


		mov	ds:errorFlags, ax	; Save me, Spock
	;
	; Gain exclusive access to the screen and set up our cur* variables
	;
		call	LocateScreen		; di <- gstate
						;  curState, curWin, curRoot,
						;  curStrat set up.
	;
	; if we cannot find a gstate (e.g. video driver not loaded
	; yet) we should change SysNotifyFlag to SNF_REBOOT or SNF_BIZARRE
	;
		
		mov	bx, di
		tst	di
		jz	haveExclusive
		mov	di, DR_VID_START_EXCLUSIVE
		call	ds:[curStrat]
haveExclusive:
		pop	ds, di

	;
	; Draw what needs to be drawn.
	;
		push	bx			;save GState for white-out
		call	DrawErrorBox
		segmov	ds, dgroup, ax

	;
	; Redirect keyboard input to our queue and loop until our routine
	; says the user has answered.
	; 
if	USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
		call	SNGrabMouse
else	; USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
ifdef	GPC_ONLY
		mov	cx, ds:[errorKbdQueue]	; assume polling On/Off
		test	ds:[errorFlags], mask SNF_EXIT or mask SNF_REBOOT
		jnz	hasQueue
endif	; GPC
		call	SNGrabKeyboard
ifdef	GPC_ONLY
hasQueue::
endif
endif	; USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
		push	bx
		mov	bx, cx			; bx <- our queue
		mov	ds:[errorComplete], 0
inputLoop:
if	USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
	; do nothing
else
ifdef	GPC_ONLY
		test	ds:[errorFlags], mask SNF_EXIT or mask SNF_REBOOT
		jz	pollKbd
		call	SNPollOnOffButton
		jmp	afterPoll
pollKbd:
endif	; GPC_ONLY
		call	SNPollKeyboard
		jz	inputLoop
ifdef	GPC_ONLY
afterPoll::
endif
endif	; USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX

		push	bx
		call	QueueGetMessage		; block until we get an event
		mov_tr	bx, ax			; prepare to process it

						; di data not used at this time
		clr	si			; don't preserve
		push	cs			; Set up custom callback

if	USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
useMouseToReplyToSysErrorBox::
BULLET <	mov	ax, offset SysNotifyBulletCB			  >
GULL <		mov	ax, offset SysNotifyGulliverCB			  >

if	useMouseToReplyToSysErrorBox eq $
    ; Check if any code has been added between the label and the current
    ; code position.  If not, print an error.
    PrintMessage<Need a SysError callback				>
endif

else
ifdef	GPC_ONLY
		mov	ax, offset SysNotifyGPCCB
		test	ds:[errorFlags], mask SNF_EXIT or mask SNF_REBOOT
		jnz	hasCB
endif	; GPC_ONLY
		mov	ax, offset SNXlateScan				
ifdef	GPC_ONLY
hasCB::
endif
endif

		push	ax

		call	MessageProcess

		pop	bx
		tst	ds:[errorComplete]
		jz	inputLoop
		
	;
	; Redirect the keyboard input to its previous location.
	; 
		pop	bx			; bx <- value returned by
						;  SNGrabKeyboard/SNGrabMouse
if	USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
		call	SNReleaseMouse
else	; USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
ifdef	GPC_ONLY
		test	ds:[errorFlags], mask SNF_EXIT or mask SNF_REBOOT
		jnz	flushQueueLoop
endif	; GPC_ONLY
		call	SNReleaseKeyboard	; bx <- our queue
endif	; USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
	;
	; Clean out the queue for next time
	; 
flushQueueLoop:
		mov	si, ds:[bx].HQ_frontPtr
		tst	si			; any event to free?
		jz	queueFlushed		; no -- all done here
		mov	ax, ds:[si].HE_next	; ax <- next event
		andnf	ax, 0xfff0		; clear calling-thread-high bits
		mov	ds:[bx].HQ_frontPtr, ax	;  and set as new front
		xchg	bx, si			; bx <- event to free
						; si <- queue
		call	ObjFreeMessage
		mov	bx, si			; bx <- queue again
		jmp	flushQueueLoop


queueFlushed:
		mov	ds:[bx].HQ_backPtr, 0
		mov	ds:[bx].HQ_semaphore.Sem_value, 0
	;
	; Now white out the box so we acknowledge the input.
	;
		pop	di			; di <- curState
		tst	di
		jz	whiteOutComplete

if not MOTIF_COLOR_ONLY_SYSTEM	;normal systems
		mov	ax, C_WHITE
		call	GrSetAreaColor
		clr	ax
		mov	bx, ax
		mov	cx, ERROR_WIDTH
		mov	dx, ERROR_HEIGHT
		call	SNFillRect
else				;redwood
		mov	ax, C_LIGHT_GREY
		call	GrSetAreaColor
		clr	ax
		mov	bx, ax
		mov	cx, ERROR_WIDTH
		mov	dx, ERROR_HEIGHT
if	FULL_EXECUTE_IN_PLACE
		call	GrFillRect
else
		call	SNFillRect
endif
endif

	;
	; Release the screen again. 
	;
		mov	bx, di			; bx <- gstate
		mov	di, DR_VID_END_EXCLUSIVE
		call	ds:[curStrat]		; ax <- non-zero if some output
						;  operation was aborted
whiteOutComplete:
	;
	; Since our window is a root window outside the normal window tree,
	; we have to force a refresh of its area by hand. We don't want to do
	; it where we are because (a) we might be in the kernel thread and
	; someone could have the window tree semaphore down already, causing
	; us to block in the kernel and die (b) invalidation takes a while and
	; should really run on a known thread. So we ship the thing off to
	; the ui to handle, giving it the root window and our window as well.
	; Note: can't ship it to the IM as invalidation might cause the IM
	; to block, which would not stand us in good stead should another
	; notification box need to be put up.
	;
		mov	dx, ds:curWin		; dx <- error window
		mov	cx, ds:curRoot		; cx <- root window
	;
	; Release the error-exclusive and return declared return value. Done
	; before the ObjMessage so if the ObjMessage triggers the low-on-handles
	; abort, life doesn't go to hell in a handbasket.
	;
		push	ds:errorReturn
		VSem	ds, errorSem

		test	ds:[errorFlags], mask SNF_DONT_INVAL_WIN_TREE
		jnz	done

		jcxz	done			; => no window, so no refresh
		tst	ax			; refresh whole screen?
		jz	forceInvalidate		; no
		mov	dx, cx			; yes -- pass root window as
						;  thing from which to get
						;  the dimensions
forceInvalidate:
		mov	ax, MSG_META_INVAL_TREE
		mov	bx, ds:uiHandle
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

done:
		pop	ax			; ax <- return flags

ifdef	GPC_ONLY
	;
	; Restore the windows to their previous states.
	;
		INT_OFF
		call	UtilWindowRestoreMapping; restore mappings from stack
		INT_ON
endif	; GPC

		.leave
		ret
SysNotify	endp

if	USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX

else	; USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SNGrabKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take over the keyboard driver for the duration.

CALLED BY:	(INTERNAL) SysNotify

PASS:		ds	= dgroup

RETURN:		bx	= value to pass to SNReleaseKeyboard
		cx	= event queue to which keyboard events will come

DESTROYED:	ax

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SNGrabKeyboard	proc	near
		.enter
		mov	bx, ds:[errorKbdQueue]
		mov	di, DR_KBD_CHANGE_OUTPUT
		mov	cx, bx			; save in cx for the call

		tst	ds:[kbdStrategy].segment
		jz	ensureKeyboardEnabled

		call	ds:[kbdStrategy]
if	HARDWARE_PC_KEYBOARD
  ensureKeyboardEnabled:			; nothing to do here
else

done:
endif
		.leave
		ret

if	not HARDWARE_PC_KEYBOARD
ensureKeyboardEnabled:


endif
SNGrabKeyboard	endp
endif	; USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX

if	USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallMouseStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call the mouse driver	

CALLED BY:	SNGrabMouse, SNReleaseMouse

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallMouseStrategy	proc	near
		uses	ds, si
		.enter

	;
	; save the args to the startegy call
		push	ax, bx

	;
	; get the mouse handle
	;
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver

	;
	; bail if there's none
	;
		tst	ax
		jz	rebootNoStrategy

	;
	; get the strategy and call it
	;
		mov_tr	bx, ax
		call	GeodeInfoDriver
		pop	ax, bx
		call	ds:[si].DIS_strategy

		.leave
		ret

rebootNoStrategy:
	mov	ax, SST_REBOOT
	call	SysShutdown
	.unreached

CallMouseStrategy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SNGrabMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take over the mouse driver for the duration.

CALLED BY:	(INTERNAL) SysNotify (for BULLET only)

PASS:		ds	= dgroup

RETURN:		ax	= old MouseHardIconOutputType to later restore (BULLET)
		bx	= old event queue to later restore
		cx	= event queue to which mouse events will come

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/19/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SNGrabMouse	proc	near
		.enter

		mov	bx, ds:[errorMouseQueue]
		mov	cx, bx			;cx <- event queue to return
		mov	di, DR_MOUSE_CHANGE_OUTPUT
		call	CallMouseStrategy

		.leave
		ret
SNGrabMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SNReleaseMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cease our usurpation of mouse driver

CALLED BY:	SysNotify (bullet only)

PASS:		bx	= queue handle to restore
		ax	= MouseHardIconOutputType to restore (BULLET only)
		ds	= dgroup

RETURN:		bx	= event queue used

DESTROYED:	ax

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SNReleaseMouse	proc	near
		.enter
	;
	; return the mouse messages to the previous queue with the
	; previous MouseHardIconOutputType
	;
		mov	di, DR_MOUSE_CHANGE_OUTPUT
		call	CallMouseStrategy
		mov	bx, ds:[errorMouseQueue]

		.leave
		ret
SNReleaseMouse	endp

else

ifdef	GPC_ONLY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SNPollOnOffButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle polling of the front-panel On/Off button without
		invoking the power driver, since the power driver uses the
		system UI thread to poll but the thread might not be able
		to run at this point.

CALLED BY:	(INTERNAL) SysNotify
PASS:		ds	= dgroup
		bx	= handle on which to queue input events
RETURN:		nothing
DESTROYED:	ax, cx, dx, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/30/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APM_COMMAND_IRQ			equ	15h
APM_MAJOR_COMMAND		equ	53h
APMSC_SET_DEVICE_STATE		equ	07h	; APMSubCommand enum
APMSC_GET_PM_EVENT		equ	0bh	; APMSubCommand enum
APME_USER_SUSPEND_REQUEST	equ	000ah	; APMEvent enum
APMDID_ALL_BIOS_DEVICES		equ	0001h	; APMDeviceID enum
APMS_REQUEST_REJECTED		equ	0005h	; APMState enum

SNPollOnOffButton	proc	near
	uses	bx
	.enter

	mov	dx, bx			; dx = queue

	; APMSC_CHECK_EXISTANCE???

poll:
	;
	; Poll the BIOS for APM events.
	;
	mov	ax, APMSC_GET_PM_EVENT or (APM_MAJOR_COMMAND shl 8)
	call	SysLockBIOS	; Should we lock BIOS and risk deadlocking?
	int	APM_COMMAND_IRQ		; bx = APMEvent, ah = APMErrorCode, CF
	call	SysUnlockBIOS
	jc	poll			; => no event

	;
	; See if it's On/Off button press.
	;
	cmp	bx, APME_USER_SUSPEND_REQUEST
	jne	poll			; => no

	;
	; Tell the BIOS to ignore this event.
	;
	mov	ax, APMSC_SET_DEVICE_STATE or (APM_MAJOR_COMMAND shl 8)
	mov	bx, APMDID_ALL_BIOS_DEVICES
	mov	cx, APMS_REQUEST_REJECTED
	call	SysLockBIOS	; Should we lock BIOS and risk deadlocking?
	int	APM_COMMAND_IRQ
	call	SysUnlockBIOS

	;
	; Send a dummy message to the queue.
	;
	mov	bx, dx			; bx = queue
	mov	ax, MSG_META_DUMMY
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
SNPollOnOffButton	endp

endif	; GPC_ONLY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SNPollKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle any polling of the keyboard device necessitated by
		the absence of a driver.

CALLED BY:	(INTERNAL) SysNotify
PASS:		ds	= dgroup
		bx	= handle on which to queue input events
RETURN:		flags set so jz will take if no input available yet and
			SysNotify shouldn't block on the input queue
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SNPollKeyboard	proc	near
		.enter
		tst	ds:[kbdStrategy].segment
		jnz	done		; => have driver, so can block on the
					;  queue w/o worry

if	HARDWARE_PC_KEYBOARD

	;------------------------------------------------------------
	;
	;			PC BIOS HANDLER
	;

	;
	; Make sure there's a character waiting.
	; 
		mov	ah, 01h
		int	16h
		jz	done			; => no character there
	;
	; There is. Fetch it.
	; 
		mov	ah, 0
		int	16h			; al <- ascii value,
						;  ah <- scan code
		tst	al			; special char? (e.g. F1)
		jz	done			; yes, don't pass special chars
	;
	; Set up the event.
	; 
		mov	dl, mask CF_FIRST_PRESS	; dl <- always first press
if DBCS_PCGEOS
		mov	ah, 0			; assume printable char
		cmp	al, ' '
		jae	sendEvent		; yup
		mov	ah, CS_CONTROL_HB	; nope -- switch character set
						;  to control
else
		mov	ah, CS_BSW		; assume printable char
		cmp	al, ' '
		jae	sendEvent		; yup
		mov	ah, CS_CONTROL		; nope -- switch character set
						;  to control
endif
sendEvent:
		mov_tr	cx, ax			; cx <- CharValue
		mov	ax, MSG_META_KBD_CHAR	; ax <- post-translation event
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage		; queue the sucker
		ornf	ax, 1			; clear ZF for return (char
						;  available)

else


endif

	;------------------------------------------------------------
done:
		.leave
		ret
SNPollKeyboard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SNReleaseKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cease our usurpation of the keyboard driver

CALLED BY:	(INTERNAL) SysNotify
PASS:		bx	= value returned from SNGrabKeyboard
		ds	= dgroup
RETURN:		bx	= event queue used
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SNReleaseKeyboard proc	near
		.enter
		tst	ds:[kbdStrategy].segment
		jz	restoreKeyboard

		mov	di, DR_KBD_CHANGE_OUTPUT
		call	ds:[kbdStrategy]	; bx <- our queue
done:
		.leave
		ret
restoreKeyboard:
if	not HARDWARE_PC_KEYBOARD

	;------------------------------------------------------------------
	;		CUSTOM KEYBOARD HANDLING
	;

endif
		mov	bx, ds:[errorKbdQueue]
		jmp	done
SNReleaseKeyboard endp

endif	; USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocateScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the error state and window for the screen on which
		the pointer now resides.

CALLED BY:	SysNotify
PASS:		ds	= dgroup
RETURN:		di	= gstate to use (ds:curState also holds it)
		ds:curWin = error window
		ds:curStrat = strategy routine for video driver
		ds:curRoot = root window on the affected screen
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocateScreen	proc	near
		.enter
	;
	; First consult with the IM to get the window on which the pointer
	; currently resides.
	;
		call	ImGetPtrWin	; di = root window, bx = driver handle
		mov	ds:curDriver, bx; save for finish
		mov	ds:curRoot, di
		tst	bx
		jz	zeroEverything	; no driver loaded, so return 0 in both
					;  bx and di to signal this
		xchg	ax, di

	;
	; Look for it in our array of root windows (it *must* be there, really)
	;
		segmov	es, ds, cx
		mov	di, offset actualRoots
		mov	cx, ds:nextScreen
		shr	cx
		repne	scasw
	;
	; Fetch the window and store it away
	;
		mov	ax, ds:[di][errorWins-(actualRoots+2)]
		mov	ds:curWin, ax
	;
	; Fetch the strategy routine and store it away
	;
		mov	ax, ds:[di][errorStratOffs-(actualRoots+2)]
		mov	ds:curStrat.offset, ax
		mov	ax, ds:[di][errorStratSegs-(actualRoots+2)]
		mov	ds:curStrat.segment, ax
	;
	; Now fetch the gstate and save it
	;
		mov	ax, ds:[di][errorStates-(actualRoots+2)]
		mov	ds:curState, ax
		xchg	ax, di		; Return gstate in di
done:
		.leave
		ret
zeroEverything:
		mov	ds:[curState], bx
		mov	ds:[curStrat].segment, cs
		mov	ds:[curStrat].offset, offset SysEmptyRoutine
		mov	ds:[curWin], bx
		jmp	done
LocateScreen	endp



;
; non-RESPONDER version
;
COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawErrorBox

DESCRIPTION:	Draw the system error box

CALLED BY:	INTERNAL
		SysNotify

PASS:
	errorFlags - flags:
	ds:si - first string to print (si = 0 for none)
	ds:di - second string to print (di = 0 for none)
	bx - GState to use

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version
	Cheng	9/89		Extended capability to handle floppy
				disk association messages and floppy disk
				prompting.

------------------------------------------------------------------------------@
	;
	; -----------------------------------------
	; 		NON-RESPONDER!!!
	; -----------------------------------------
	;

DrawErrorBox	proc	near

	push	di
	push	si
	push	ds

	; Draw error box. NOTE: DO NOT USE GrPlayString -- that calls to a
	; movable module in KLib that cannot be counted on to be brought in
	; during an emergency.

	mov	di,bx			;GState
	tst	di
	jz	drawStrings

if not MOTIF_COLOR_ONLY_SYSTEM		;all normal systems
	;
	; Draw 4-pixel black box. 
	; 
	mov	ax, C_BLACK
	call	GrSetAreaColor
	clr	ax
	mov	bx, ax
	mov	cx, ERROR_WIDTH
	mov	dx, ERROR_HEIGHT
	call	SNFillRect
	;
	; Wash the rest with white
	;
	mov	ax, C_WHITE
	call	GrSetAreaColor
	mov	ax, 4
	add	bx, 4
	sub	cx, 4
	sub	dx, 4
	call	SNFillRect	

else ;MOTIF_COLOR_ONLY_SYSTEM

	mov	ax, C_LIGHT_GREY	;draw grey background
	call	GrSetAreaColor
	clr	ax
	mov	bx, ax
	mov	cx, ERROR_WIDTH
	mov	dx, ERROR_HEIGHT
if	FULL_EXECUTE_IN_PLACE
	call	GrFillRect
else
	call	SNFillRect
endif

	mov	ax, C_WHITE		;lt color (outdent rect)
	mov	bp, C_DARK_GREY		;rb color
	clr	bx			;no inset
	call	DrawInsetRect

	mov	bl, 3			;inset amount
	xchg	ax, bp			;indent rect
	call	DrawInsetRect

	inc	bx			;move inside another pixel
	xchg	ax, bp			;outdent rect for an etch
	call	DrawInsetRect
endif

drawStrings:

ifdef GPC
	; When handling an unrecoverable error, display the standard
	; shutdown message, followed by the two user strings.  The 
	; exit/reboot strings are never shown.

	segmov	ds, dgroup, ax
	test	ds:[errorFlags], mask SNF_REBOOT or mask SNF_EXIT
	mov	bx, ERROR_TEXT_Y_1
	jz	normalNotify

	; Draw the standard message.
	mov	ax, ds:[fixedStringsSegment]
	mov	ds, ax
	mov	bx, ERROR_SETEXT_Y
	mov	si, sp
	tst	{word}ss:[si+4]		;ss:[sp+4] = 2nd string
	jnz	gotSecondStr
	mov	bx, ERROR_SETEXT_Y2
gotSecondStr:
	mov	si, offset GPCErrorMsg1
	mov	cx, GPCErrorMsgCount
nextString:
	mov	ax,ERROR_TEXT_X
	push	bx, cx, si
	clr	cx
	mov	si, ds:[si]			;dereference chunk
	call	SNDrawText
	pop	bx, cx, si
	add	bx, ERROR_SETEXT_DY
	add	si, 2
	loop	nextString
	add	bx, ERROR_SETEXT_YN

normalNotify:
endif ; GPC
	; Draw user strings

	pop	ds			;first string
	pop	si
	tst	si
	jz	noString1
	mov	ax,ERROR_TEXT_X
ifndef GPC
	mov	bx,ERROR_TEXT_Y_1
endif ; GPC
	clr	cx

	call	SNDrawText					

noString1:
	pop	si			;second string
	tst	si
	jz	noString2
	mov	ax,ERROR_TEXT_X
ifdef GPC
	add	bx,(ERROR_TEXT_Y_2 - ERROR_TEXT_Y_1)
else
	mov	bx,ERROR_TEXT_Y_2
endif ; GPC
	clr	cx
	call	SNDrawText					

noString2:

	; Draw standard strings based on flags

; DO NOT USE TEXT STYLE AS THAT WILL GO TO FONT DRIVER, WHICH MAY NOT BE
; RESIDENT.
;	mov	ax,mask TS_BOLD or mask TS_ITALIC
;	call	GrSetTextStyle

	segmov	ds, dgroup, ax
	mov	ax,ds:[errorFlags]			;flags

ifdef GPC
	test	ax, mask SNF_REBOOT or mask SNF_EXIT
	jz	drawFlagStrings
	; All done!
	ret
endif ; GPC
	
ifdef GPC
drawFlagStrings:
endif
	;
	; Figure what string(s) to put up. First string ends up in si, second
	; (if any) in dx (0 if no second string).
	;
	mov	si, offset errorStringC	; Assume continuing
	clr	dx			;  and no second string
	test	ax, mask SNF_BIZARRE
	jz	checkContinue
	mov	dx, offset errorStringBiz; use TS Guide string as second if
					 ;  SNF_BIZARRE

checkContinue:
	test	ax,mask SNF_CONTINUE
	jz	notContinue

	test	ax, mask SNF_ABORT
	jz	gotIt

	mov	dx, offset errorStringA	; Abort allowed too
	jmp	gotIt

notContinue:
	;
	; On Jedi, any SNF_EXIT passed has already been mapped to reboot.
	;
ifndef GPC
	test	ax, mask SNF_EXIT	; If exiting allowed, use errorStringE
	jz	noExit			;  as the second string in all cases

	mov	si, offset errorStringBE1
	;
	; On bullet, there is only one string in this case:
	;
NOBULL <	mov	dx, offset errorStringBE2 >
BULLET < 	mov	dx, 0			  >
	;
	; But on Jedi, there are 3rd and 4th strings in this case.  Oh well ...
	;

	test	ax, mask SNF_REBOOT	; use B & E string if both given 
	jnz	gotIt							
	mov	dx, offset errorStringE					

noExit:
endif ; GPC

	mov	si,offset errorStringA	; Assume can abort

	test	ax, mask SNF_ABORT
	jz	notAborting
	test	ax, mask SNF_RETRY	; May we retry as well?
	jz	gotIt		; No -- strings set up
	mov	si, offset errorStringRA; Switch to retry/abort string as first
	jmp	gotIt
notAborting:

ifndef GPC
	test	ax, mask SNF_REBOOT
	jz	notRebooting
	

	mov	si, offset errorStringB
	test	ax, mask SNF_RETRY
	jz	gotIt
	mov	si, offset errorStringRB
	jmp	gotIt

notRebooting:
endif ; GPC
	mov	si, offset errorStringR	; Assume we may just retry
	test	ax, mask SNF_RETRY

	jnz	gotIt
	
	mov	si, dx			; Use second string if none of
					; the above
	clr	dx
	tst	si		; Do we have a string now?
	jnz	gotIt		; Yes -- happy
	;
	; "This should never happen"
	;
	mov	si, offset confusion
	ornf	ds:errorFlags, mask SNF_CONTINUE
	mov	dx, offset errorStringC

gotIt:
	mov	ax, ds:[fixedStringsSegment]
	mov	ds, ax
	mov	ax,ERROR_TEXT_X
	mov	bx,ERROR_TEXT_Y_3
	clr	cx
	mov	si, ds:[si]			;dereference chunk

REDWOOD <	call	GrDrawText					>
NORED   <	call	SNDrawText					>

	tst	dx
	jz	noSecondString
	mov	si,dx
	mov	ax,ERROR_TEXT_X
	mov	bx,ERROR_TEXT_Y_4
	clr	cx
	mov	si, ds:[si]			;dereference chunk

REDWOOD <	call	GrDrawText					>
NORED   <	call	SNDrawText					>

noSecondString:


	ret

DrawErrorBox	endp


ifndef	GPC_ONLY
SNAction	etype	word, 0, 2
    SNA_REBOOT	enum	SNAction
    SNA_ABORT	enum	SNAction
    SNA_RETRY	enum	SNAction
    SNA_EXIT	enum	SNAction
    SNA_CONTINUE enum	SNAction
else
SNAction	etype	word, 0, 2
    SNA_ABORT	enum	SNAction
    SNA_RETRY	enum	SNAction
    SNA_CONTINUE enum	SNAction
endif	; GPC





COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawInsetRect

SYNOPSIS:	Draws an etched rect using the colors passed.   Assumes the
		use of an XIP kernel so we don't have to worry about libraries
		being in memory.

CALLED BY:	DrawErrorBox

PASS:		ax -- left/top color
		bp -- right/bottom color
		cx -- width of window
		dx -- height of window
		bx -- amount inset from edges of window
		di -- gstate

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/93       	Initial version

------------------------------------------------------------------------------@

if MOTIF_COLOR_ONLY_SYSTEM

DrawInsetRect	proc	near		uses	ax, bx, cx, dx, bp
	.enter
	push	bp				;R/B color
if	FULL_EXECUTE_IN_PLACE
	call	GrSetLineColor			;set L/T color
else
	call	GrSetAreaColor
endif

	dec	cx				; adjust for line drawing
	dec	dx				;  (as opposed to GrFillRects)

	;
	; Draw top line.
	;
	mov	ax, bx				;y, left = inset
	sub	cx, bx				;right = width - inset + 1
	inc	cx
if	FULL_EXECUTE_IN_PLACE
	call	GrDrawHLine			
else
	call	SNDrawHLineAsRect
endif

	;
	; Draw left edge.
	;
						;x = inset
						;top = inset
	sub	dx, bx				;bottom = height - inset + 1
	inc	dx
if	FULL_EXECUTE_IN_PLACE
	call	GrDrawVLine			
else
	call	SNDrawVLineAsRect
endif

	pop	ax				;L/T color
if	FULL_EXECUTE_IN_PLACE
	call	GrSetLineColor
else
	call	GrSetAreaColor
endif

	;
	; Right edge.
	;
	mov	ax, cx				;x = width - inset
	dec	ax
						;top = inset
						;bottom = height - inset + 1
if	FULL_EXECUTE_IN_PLACE
	call	GrDrawVLine			
else
	call	SNDrawVLineAsRect
endif

	;
	; Bottom edge.
	;
	mov	ax, bx				;left = inset
						;right = width - inset + 1
	mov	bx, dx				;y = height - inset
	dec	bx
if	FULL_EXECUTE_IN_PLACE
	call	GrDrawHLine			
else
	call	SNDrawHLineAsRect
endif
	.leave
	ret
DrawInsetRect	endp


endif


ifidn HARDWARE_TYPE, <GULLIVER>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysNotifyGulliverCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to handle mouse events for sys notifies on
		Gulliver.  Shamelessly copied from the Bullet.

CALLED BY:	SysNotify via GeodeDispatchFromQueue

PASS:		AX	= Message (MSG_META_NOTIFY)
		CX	= Data (MANUFACTURER_ID_GEOWORKS)
		DX	= Data (GWNT_HARD_ICON_BAR_FUNCTION or
				GWNT_STARTUP_INDEXED_APP)
		BP	= Data (hard icon # or
				HIBF_DISPLAY_FLOATING_KEYBOARD)
		DS	= Kdata

RETURN:		Nothing 

DESTROYED:	AX, CX, DX, BP

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysNotifyGulliverCB	proc	far

TOP_HARD_ICON	equ	0

		.enter
	;
	; all we have to detect is whether the top or the bottom hard
	; icon have been hit.
	;
		mov	bx, ds:[errorFlags]
		cmp	ax, MSG_META_NOTIFY
		jne	done
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	done
		cmp	dx, GWNT_HARD_ICON_BAR_FUNCTION
		je	checkBottomHardIcon
		cmp	dx, GWNT_STARTUP_INDEXED_APP
		je	checkTopHardIcon
done:
		.leave
		ret
	;
	; See if the top hard icon was hit (index app #0)
	;
checkTopHardIcon:
		cmp	bp, TOP_HARD_ICON
		jne	done
		mov	ax, mask SNF_CONTINUE
		test	bx, ax
		jnz	gotCode
		mov	ax, mask SNF_RETRY
		test	bx, ax
		jz	done
gotCode:
		mov	ds:[errorReturn], ax
		mov	ds:[errorComplete], TRUE
		jmp	done
	;
	; See if the botton hard icon was hit (Express menu)
	;
checkBottomHardIcon:
		cmp	bp, HIBF_TOGGLE_EXPRESS_MENU
		jne	done
		test	bx, mask SNF_EXIT
		jnz	doExit
		test	bx, mask SNF_REBOOT
		jnz	reboot
		mov	ax, mask SNF_ABORT
		test	bx, ax
		jnz	gotCode
		jmp	done
	;
	; Reboot the system now
	;
reboot:
		mov	ax, SST_REBOOT
		call	SysShutdown
		.unreached
	;
	; Exit, but instead of going to DOS when the user does not
	; have a keyboard, just do a shutdown and then reboot
	;
doExit:
		mov	ax, SST_RESTART
		call	SysShutdown
		mov	ax, mask SNF_EXIT
		jmp	gotCode
		
SysNotifyGulliverCB	endp

elife	USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX

ifdef	GPC_ONLY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysNotifyGPCCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to handle On/Off button event for SysNotify.

CALLED BY:	SysNotify vis MessageProcess
PASS:		ds	= dgruop
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/30/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysNotifyGPCCB	proc	far
	uses	bx
	.enter

	test	ds:[errorFlags], mask SNF_REBOOT
	jnz	reboot

	;
	; Attempt to exit cleanly. Advance to next level of severity in case
	; this shutdown mode doesn't work.
	;
if SYS_NOTIFY_REBOOT_ON_EXIT
	ornf	ds:[exitFlags], mask EF_RESET
endif
	mov	ax, ds:[errorShutdownMode]
	inc	ds:[errorShutdownMode]
	mov	si, -1		; No message...
	call	SysShutdown
	mov	ax,mask SNF_EXIT

	mov	ds:[errorReturn], ax
	mov	ds:[errorComplete], TRUE
done:
	.leave
	ret

reboot:
	;
	; Reboot -- shutdown with the RESTART option.
	;
if SYS_NOTIFY_USE_REBOOT_IF_RESTART
	;
	; For errors like "conventional memory full", SST_RESTART can't
	; restart the system because it waits for all apps to shut down, which
	; requires all threads to finish, which is not possible because the
	; calling thread must have been calling MemAlloc with HAF_NO_ERR and
	; is not expecting any error returned.
	;
	; Changed the code from using SST_RESTART to SST_REBOOT instead, so
	; that restart is possible without waiting for apps to shut down.
	; Made it JEDI only because it may have side effects on other products.
	;
	; --- AY, 6/15/95
	;
	; The option is now a flag in kernelConstant.def, defined TRUE
	; for Jedi and responder for now.
	;
	mov	ax, SST_REBOOT
else
	mov	ax, SST_RESTART
	dec	ds:[errorComplete]		; set errorComplete to TRUE,
						;  so that SysNotify will
						;  return to it caller.
						;  --- AY 6/15/95
endif	; SYS_NOTIFY_USE_REBOOT_IF_RESTART
	call	SysShutdown
	jmp	done

SysNotifyGPCCB	endp

endif	; GPC_ONLY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SNXlateScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dispatch routine for keyboard events sent to our queue.

CALLED BY:	SysNotify via GeodeDispatchFromQueue
PASS:		ds	= dgroup
		ax	= MSG_IM_KBD_SCAN
		cx	= scan code
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SNXlateScan	proc	far
	.enter

	;
	; First translate the scan code. This'll give us back cx, dx, bp
	; being the normal parameters for a MSG_META_KBD_CHAR
	; 
	tst	ds:[kbdStrategy].segment
	jz	haveChar

	mov	di, DR_KBD_XLATE_SCAN
	call	ds:[kbdStrategy]

haveChar:
	test	dl,mask CF_FIRST_PRESS
	jz	done

	mov	bx,ds:[errorFlags]

if	HARDWARE_PC_KEYBOARD

	;
	; Check for Ctrl+Alt+Del and Enter first, as they're the only two
	; in the CS_CONTROL character set.
	; 
if DBCS_PCGEOS

	cmp	ch, CS_LATIN_1
	je	checkErrorKeys

ifndef	GPC_ONLY
ifdef	SYSTEM_SHUTDOWN_CHAR
	cmp	cx, SYSTEM_SHUTDOWN_CHAR
	je	reset
endif	; SYSTEM_SHUTDOWN_CHAR
endif	; GPC_ONLY

	cmp	cx, C_SYS_NUMPAD_ENTER
	jnz	done				; Not enter, so ignore

else

	cmp	ch, CS_BSW
	je	checkErrorKeys

ifndef	GPC_ONLY
ifdef	SYSTEM_SHUTDOWN_CHAR
	cmp	cl, SYSTEM_SHUTDOWN_CHAR
	je	reset
endif	; SYSTEM_SHUTDOWN_CHAR
endif	; GPC_ONLY

	cmp	cl,VC_NUMPAD_ENTER
	jnz	done				; Not enter, so ignore
endif				; DBCS

	mov	di, SNA_CONTINUE
	jmp	checkKeyAllowed			; see if continue is allowed
		
checkErrorKeys:

	;
	; See if the key is one of the possible input characters, after
	; converting it to upper-case.
	; 
SBCS <	mov	al, cl							>
DBCS <	mov	ax, cx							>
	cmp	al, 'a'
	jb	10$
	cmp	al, 'z'
	ja	10$
	sub	al, 'a' - 'A'
10$:
	mov	es, ds:[fixedStringsSegment]	; es:di <- table of defined
	assume	es:FixedStrings
	mov	di, es:[errorKeys]		;  input characters
	mov	cx, 4				; cx <- length (4 characters)
	LocalFindChar
	jne	done
		
SBCS <	stc					; subtract an extra to account>
SBCS <	sbb	di, es:[errorKeys]		;  for post-increment...>
SBCS <	shl	di				; convert to SNAction	>
DBCS <	sub	di, (size wchar)					>
DBCS <	sub	di, es:[errorKeys]					>

checkKeyAllowed:
	; di = SNAction
	; bx = errorFlags
	mov	ax, cs:[errorKeyMasks][di]	; ax <- SysNotifyFlags for
						;  the key just pressed
	test	bx, ax
	jz	done		; if that key isn't allowed, ignore the event


ifndef	GPC_ONLY
	jmp	cs:[errorKeyHandlers][di]

errorKeyHandlers nptr.near	reboot, abort, retry, exit, continue
	CheckHack <length errorKeyHandlers eq SNAction/2>
errorKeyMasks	SysNotifyFlags	mask SNF_REBOOT,
				mask SNF_ABORT,
				mask SNF_RETRY,
				mask SNF_EXIT,
				mask SNF_CONTINUE
exit:
	;
	; Attempt to exit cleanly. Advance to next level of severity in case
	; this shutdown mode doesn't work.
	;
if SYS_NOTIFY_REBOOT_ON_EXIT
	ornf	ds:[exitFlags], mask EF_RESET
endif
	mov	ax, ds:[errorShutdownMode]
	inc	ds:[errorShutdownMode]
	mov	si, -1		; No message...
	call	SysShutdown
	mov	ax,mask SNF_EXIT

abort:
continue:
retry:

endif	; GPC_ONLY

	mov	ds:[errorReturn], ax
	mov	ds:[errorComplete], TRUE
done:
	.leave
	ret

ifndef	GPC_ONLY
reboot:
	;
	; Reboot -- shutdown with the RESTART option.
	;
if SYS_NOTIFY_USE_REBOOT_IF_RESTART
	;
	; For errors like "conventional memory full", SST_RESTART can't
	; restart the system because it waits for all apps to shut down, which
	; requires all threads to finish, which is not possible because the
	; calling thread must have been calling MemAlloc with HAF_NO_ERR and
	; is not expecting any error returned.
	;
	; Changed the code from using SST_RESTART to SST_REBOOT instead, so
	; that restart is possible without waiting for apps to shut down.
	; Made it JEDI only because it may have side effects on other products.
	;
	; --- AY, 6/15/95
	;
	; The option is now a flag in kernelConstant.def, defined TRUE
	; for Jedi and responder for now.
	;
	mov	ax, SST_REBOOT
else
	mov	ax, SST_RESTART
	dec	ds:[errorComplete]		; set errorComplete to TRUE,
						;  so that SysNotify will
						;  return to it caller.
						;  --- AY 6/15/95
endif	; SYS_NOTIFY_USE_REBOOT_IF_RESTART
ifdef	SYSTEM_SHUTDOWN_CHAR
	jmp	doReset

reset:
	; XXX: need to check reboot-on-reset
	mov	ax, SST_REBOOT
	tst	ds:[rebootOnReset]
	jnz	doReset
	mov	ax, SST_DIRTY
	mov	si, -1

doReset:
endif	; SYSTEM_SHUTDOWN_CHAR
	call	SysShutdown
	jmp	done

else
errorKeyMasks	SysNotifyFlags	mask SNF_ABORT,
				mask SNF_RETRY,
				mask SNF_CONTINUE
	CheckHack <length errorKeyMasks eq SNAction/2>
endif	; GPC_ONLY

else

	;---------------------------------------------------------------------
	;	 CUSTOM KEYBOARDS
	;



endif

	assume	es:dgroup

SNXlateScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponderCheckErrorKeys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	SNXlateScan
PASS:		bx	= SysNotifyFlags
		cx 	= character value
			SBCS: ch = CharacterSet, cl = Chars
			DBCS: cx = Chars
		dl 	= CharFlags
		dh 	= ShiftState
		bp low 	= ToggleState
		bp high = scan code

RETURN:		carry set if input is legal (ie. F1/F4 CF_FIRST_PRESS,
		and it matches one flag in SysNotifyFlags)
		di	= SNAction
		ax	= SysNotifyFlags (mask SNF_RETRY, etc.)
		carry cleared otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
		Responder: 	possible cases are:
	
	F1	| Retry	| Abort	| Retry	| Retry	| 	| Cont.	| Cont.
		| 	| 	| 	| 	|	|	|
		| 	| 	| 	| 	|	|	|
	F4	| Abort	| 	| 	| Reboot| Reboot| 	| Abort


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	7/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

endif	; BULLET



