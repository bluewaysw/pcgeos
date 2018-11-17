COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		imScreenSaver.asm

AUTHOR:		Doug Fults, March 27, 1991

ROUTINES:

INT		InitScreenSaver

INT		BlankScreens
INT		UnBlankScreens

METHODS:

METHOD	IMScreenSaverStatus 	MSG_IM_ENABLE_SCREEN_SAVER
METHOD	IMScreenSaverStatus 	MSG_IM_DISABLE_SCREEN_SAVER
METHOD	IMSetSaverOD 		MSG_IM_INSTALL_SCREEN_SAVER
METHOD	IMSetSaverOD 		MSG_IM_REMOVE_SCREEN_SAVER
METHOD	IMSetSaverDelay 	MSG_IM_SET_SCREEN_SAVER_DELAY
METHOD	IMSaverCountdown 	MSG_IM_SCREEN_SAVER_COUNTDOWN

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/27/91		Initial revision


DESCRIPTION:
	Screen saver code

RESPONDER CHANGE:
	INTERVAL_BETWEEN_SCREEN_SAVER_COUNTDOWN_EVENTS has changed from 15 sec
	to 3.75 sec.  This means that input manager will get timer interrupt
	every 3.75 seconds now and SS_maxCount and SS_curCount has been
	increased by a factor of 4.  This is done to accomodate responder
	power maanger's need for even finer granularity in screen saver delay.
	Notice the changes in interfaces of MSG_IM_SET_SCREEN_SAVER_DELAY and
	MSG_IM_GET_SCREEN_SAVER_DELAY. 				-SJ

	$Id: imScreenSaver.asm,v 1.1 97/04/05 01:17:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitScreenSaver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize screen saver

CALLED BY:	EXTERNAL

PASS:		ds - dgroup

RETURN:	

DESTROYED:	

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitScreenSaver	proc	near
	mov	ds:[screenSaver].SS_maxCount, IM_DEFAULT_SCREEN_SAVER_COUNT*4
	mov	ds:[screenSaverDelay], IM_DEFAULT_SCREEN_SAVER_COUNT*4
	ret

InitScreenSaver	endp


ObscureInitExit	ends


IMResident	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		IMSaverCountdown -- IMClass MSG_IM_SCREEN_SAVER_COUNTDOWN

DESCRIPTION:	called via timer code to check for screen blanking

PASS:
		ds - dgroup
		ax 	- The method

RETURN: 	nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

------------------------------------------------------------------------------@

IMSaverCountdown	method IMClass, MSG_IM_SCREEN_SAVER_COUNTDOWN

	; NOTE:  This handler is in RESIDENT code, so that the IM thread will
	; not block each minute loading back in the resource needed to executed
	; it, which can cause the mouse to "catch" on screen.  This routine
	; has been written to be as small as possible.  Don't add stuff here
	; without first considering if you could stick it in a movable
	; resource somewhere, perhaps in the IMSaverCountdownReachedZero
	; handler (hint, hint)	-- Doug


	dec	ds:[screenSaver].SS_curCount		; decrement the count
	jns	countOK
	mov	ds:[screenSaver].SS_curCount, 0		;  yep, do it
countOK:
	jnz	done

	mov	ax, MSG_IM_SCREEN_SAVER_COUNTDOWN_REACHED_ZERO
	call	SendToIM
done:
	ret

IMSaverCountdown	endm


IMResident ends

;---------------------

IMMiscInput segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		IMSaverCountdownReachedZero

DESCRIPTION:	Called from IMSaverCountdown when counter has reached zero.
		The screen saver should be activated at this time.

PASS:
		ds - dgroup
		ax - MSG_IM_SCREEN_SAVER_COUNTDOWN_REACHED_ZERO

RETURN: 	nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version

------------------------------------------------------------------------------@

IMSaverCountdownReachedZero	method IMClass, \
				MSG_IM_SCREEN_SAVER_COUNTDOWN_REACHED_ZERO
	
	; first check to see if any application is busy
	; return immediatly if an app is
	;
	tst	ds:[disableAPOCount]	
	jz	cont
	inc	ds:[screenSaver].SS_curCount
	jmp	exit

cont:

	; second give the power management driver a shot at turning the machine
	; off.  If the power management driver returns carry set then it
	; has taken care of things.

	mov	ax, GDDT_POWER_MANAGEMENT
	call	GeodeGetDefaultDriver
	tst	ax
	jz	reallyBlank

	;
	; Don't check recent disk locks.  This ensures that the screen is
	; still blanked 1) when a long file operation is in progress, and 2)
	; when the user clicks "Screen Saver" trigger in Express Menu (which
	; may need to read discarded resources from disk when the menu is
	; dismissed and the screen is re-drawn).
	;
	mov_tr	bx, ax			;BX <- handle of power driver
if	0
	;
	; Check to see if a disk lock occurred recently.  If it did,
	; forget about the screen save this time.
	;
	; This is a hack to avoid allowing power off in the middle of a
	; long PCMCIA access. It doesn't prevent the user from powering
	; off manually, though, so it's kind of a stupid fix.
	;
	; All this stuff should be (and is) moved to the power driver for
	; Responder, and ought to be put there for other products too.
	;
	movdw	bxsi, ds:[systemCounter]
	subdw	bxsi, ds:[diskLastAccess]
	cmpdw	bxsi, MINIMUM_DISK_IDLE_TIME_FOR_APO
	mov_tr	bx, ax			;BX <- handle of power driver
	mov	ax, 1			;Try again in 1 tick if we've accessed
					; the disk too recently
	jb	resetIdleTime
endif

	; Give the power driver a chance to shut down the system

	push	si, ds
	call	GeodeInfoDriver
	mov	di, DR_POWER_LONG_TERM_IDLE
	call	ds:[si].DIS_strategy
	pop	si, ds
	jnc	reallyBlank		;Blank dem screens, if the power driver
					; didn't do it for us
	mov	ax, ds:[screenSaver].SS_maxCount
resetIdleTime::
	mov	ds:[screenSaver].SS_curCount, ax
exit:
	ret

reallyBlank:

	; Time to activate the screen saver action.  either blank the
	; screen or send a method off to someone.
	;
	call	BlankScreens
					; Mark as active
	or	ds:[screenSaver].SS_state, mask SSS_ACTIVE
	;
	; send out a notification to anyone who cares
	;
	call	SendSaverNotification
	ret

IMSaverCountdownReachedZero	endm


COMMENT @----------------------------------------------------------------------

METHOD:		IMSaverActivate -- IMClass MSG_IM_ACTIVATE_SCREEN_SAVER

DESCRIPTION:	called to cause immediate activation of screen saver

PASS:
		ds - dgroup
		ax 	- The method

RETURN: 	nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/91		Initial version

------------------------------------------------------------------------------@

IMSaverActivate	method dynamic	IMClass, MSG_IM_ACTIVATE_SCREEN_SAVER
	test	ds:[screenSaver].SS_state, mask SSS_ACTIVE
	jz	doIt
	ret

doIt:
	mov	ds:[screenSaver].SS_curCount, 1		; Force to 1, then
							; count down a tick..
							; that should do it!
	GOTO	IMSaverCountdown

IMSaverActivate	endm



COMMENT @----------------------------------------------------------------------

METHOD:		IMSaverActivate -- IMClass MSG_IM_DEACTIVATE_SCREEN_SAVER

DESCRIPTION:	called to cause immediate deactivation of screen saver

PASS:
		ds - dgroup

RETURN: 	nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/9/92		Initial version

------------------------------------------------------------------------------@

IMSaverDeactivate	method	IMClass, MSG_IM_DEACTIVATE_SCREEN_SAVER
	; reset counter
	mov	ax, ds:[screenSaver].SS_maxCount
	xchg	ds:[screenSaver].SS_curCount, ax
		
		
	tst	ax
	jnz	done		; => wasn't active

	call	UnBlankScreens
		
	;
	; On responder, this was already marked as not active above
	;
	andnf	ds:[screenSaver].SS_state, not mask SSS_ACTIVE
	;
	; send a notification to anyone who cares
	;
	call	SendSaverNotification
		
done:
	ret
IMSaverDeactivate	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSaverNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a notification to anyone who cares

CALLED BY:	UTILITY
PASS:		ds - dgroup
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/19/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendSaverNotification	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	;
	; record an event and send it
	;
	clr	ax
	mov	al, ds:[screenSaver].SS_state
	mov	bp, ax					;bp <- ScrSaverStatus
	mov	dx, GWNT_SCREEN_SAVER_STATUS_NOTIFICATION
	mov	ax, MSG_META_NOTIFY
	mov	bx, MANUFACTURER_ID_GEOWORKS		;cx <- ManufacturerID
	mov	si, GCNSLT_SCREEN_SAVER_NOTIFICATIONS
	mov	di, mask GCNLSF_FORCE_QUEUE
	call	GCNListRecordAndSend

	.leave
	ret
SendSaverNotification	endp


COMMENT @----------------------------------------------------------------------

METHOD:		BlankScreens

DESCRIPTION:	Disables the video screen

CALLED BY:	

PASS:
		ds - dgroup

RETURN:		nothing

DESTROYED:
		nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		initial version

------------------------------------------------------------------------------@
BlankScreens	proc	far

	tst	ds:[screenSaver].SS_OD.handle
	jnz	sendMethod

	; just do the default action, which is disabling the video

	push	di
	mov	di, DR_VID_SCREEN_OFF
	call	CallPtrDriver
	pop	di
	ret

	; send a method to some process/object.  This is an option over
	; just blanking the display.
sendMethod:
	push	ax
	mov	ax, ds:[screenSaver].SS_beginMethod ; get method number
	call	ObjMessageScreenSaverOD
	pop	ax
	ret
BlankScreens	endp



COMMENT @----------------------------------------------------------------------

METHOD:		UnBlankScreens	- respond to user input

DESCRIPTION:	Re-enables video display, if needed

CALLED BY:	CheckOnInputHoldUp

PASS:
		ds - dgroup

RETURN:		nothing

DESTROYED:
		nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		initial version

------------------------------------------------------------------------------@
UnBlankScreens	proc	far


	; Time to de-activate the screen saver action.  either unblank the
	; screen or send a method off to someone.

	tst	ds:[screenSaver].SS_OD.handle
	jnz	sendMethod

	; If no screen saver installed, just do the default action,
	; which is enabling the video
	;
	push	di
	mov	di, DR_VID_SCREEN_ON
	call	CallPtrDriver

	pop	di
	ret

	; Saver installed -- send a method to some process/object.  This is
	; an option over just blanking the display.
sendMethod:
	push	ax
	mov	ax, ds:[screenSaver].SS_endMethod	; get method number
	call	ObjMessageScreenSaverOD
	pop	ax
	ret
UnBlankScreens	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjMessageScreenSaverOD

DESCRIPTION:	Scrap of a routine to save bytes

CALLED BY:	INTERNAL

PASS:
	ds - dgroup
	ax	- method to send
	cx, dx, bp	- data to send

RETURN:

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
------------------------------------------------------------------------------@

ObjMessageScreenSaverOD	proc	near	uses	bx, si, di
	class	IMClass
	.enter
	mov	bx, ds:[screenSaver].SS_OD.handle ; get OD
	mov	si, ds:[screenSaver].SS_OD.chunk  
	mov	di, mask MF_FIXUP_DS			; put at end of queue
	call	ObjMessage
	.leave
	ret
ObjMessageScreenSaverOD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMEnableScreenSaver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable screen blanking

CALLED BY:	MSG_IM_ENABLE_SCREEN_SAVER
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	timer is started

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMEnableScreenSaver method dynamic IMClass, MSG_IM_ENABLE_SCREEN_SAVER
	.enter
	test	ds:[screenSaver].SS_state, mask SSS_ENABLED
	jnz	done				; if on already, leave it alone

	mov	bx, ss:[TPD_threadHandle]
	clr	si
	mov	dx, MSG_IM_SCREEN_SAVER_COUNTDOWN	; method we want
	mov	ax, TIMER_EVENT_CONTINUAL	; want continual events
	mov	cx, INTERVAL_BETWEEN_SCREEN_SAVER_COUNTDOWN_EVENTS
	mov	di, cx				; timer interval
	call	TimerStart
	mov	ds:[screenSaver].SS_timerHan, bx ; save timer info
	mov	ds:[screenSaver].SS_timerID, ax ; save timer info
	mov	ax, ds:[screenSaver].SS_maxCount
	mov	ds:[screenSaver].SS_curCount, ax
	ornf	ds:[screenSaver].SS_state, mask SSS_ENABLED
	;
	; send a notification to anyone who cares
	;
	call	SendSaverNotification
done:
	.leave
	ret
IMEnableScreenSaver endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMDisableScreenSaver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable screen blanking

CALLED BY:	MSG_IM_DISABLE_SCREEN_SAVER
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	timer is nuked

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMDisableScreenSaver method dynamic IMClass, MSG_IM_DISABLE_SCREEN_SAVER
	.enter

	; disable blanking.  Turn off timer, set instance variable.

	test	ds:[screenSaver].SS_state, mask SSS_ENABLED or mask SSS_ACTIVE
	jz	done				; if disabled already, leave it
						; alone, else disable the
						; timer.
EC <	pushf								>
EC <	Assert	bitSet, ds:[screenSaver].SS_state, SSS_ENABLED		>
EC <	popf								>
	jnp	stopTimer			; => enabled but not active
	call	IMSaverDeactivate

stopTimer:
	mov	ax, ds:[screenSaver].SS_timerID  ; fetch timer ID
	mov	bx, ds:[screenSaver].SS_timerHan ; fetch timer handle
	call	TimerStop			; stop the darned thing
	andnf	ds:[screenSaver].SS_state, not mask SSS_ENABLED
	;
	; send a notification to anyone who cares
	;
	call	SendSaverNotification

done:
	.leave
	ret
IMDisableScreenSaver endm


COMMENT @----------------------------------------------------------------------

METHOD:		IMGetSaverDelay

DESCRIPTION:	Fetch current screen saver delay

PASS:
	ds - dgroup
	ax 	- The method

RETURN:
	ax	- saver delay in minutes
[RESPONDER:]
	if ax == 0,
	   cx = previous count in 3.75 sec units( so for 1 min, cx = 16 )

DESTROYED:
	nothing

NOTE:
	See documentation at the top of the file for responder changes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/91		Initial version

------------------------------------------------------------------------------@

IMGetSaverDelay	method dynamic	IMClass, MSG_IM_GET_SCREEN_SAVER_DELAY
	.enter
	mov	ax, ds:[screenSaver].SS_maxCount	; get count

;	Convert timeout value in units of 15 seconds to timeout value
;	in units of 1 minute

	shr	ax, 1
	shr	ax, 1
	.leave
	ret
IMGetSaverDelay	endm


COMMENT @----------------------------------------------------------------------

METHOD:		IMSetSaverDelay -- IMClass MSG_IM_SET_SCREEN_SAVER_DELAY

DESCRIPTION:	Set scren saver delay

PASS:
	ds - dgroup
	ax 	- The method
	cx 	- new blank delay	(minutes)
[RESPONDER:]
	if cx == 0,
	   dx = delay time in 3.75 sec units( so 16 units = 1 min )

RETURN:
	nothing
[RESPONDER:]
	dx	- previous value

DESTROYED:
	nothing

NOTE:
	See documentation at the top of the file for responder changes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

------------------------------------------------------------------------------@

IMSetSaverDelay	method dynamic	IMClass, MSG_IM_SET_SCREEN_SAVER_DELAY
	.enter

;	Convert timeout value in units of 1 minute to timeout value
;	in units of 15 seconds (for responder, 15 sec unit to 3.75 sec unit)

	shl	cx, 1
	shl	cx, 1
	mov	ds:[screenSaver].SS_maxCount, cx	; set new count
	mov	ds:[screenSaverDelay], cx	

	; if the new count is less then than the time remaining until the
	;  next save, then change the time remaining to the next save
	;
	; No! If you do this the timeout that occurs could happen before
	; the timeout value just set, which would be inconsistent for the
	; user. -Don 7/13/93

;;;	cmp	cx, ds:[screenSaver].SS_curCount
;;;	jae	done
	mov	ds:[screenSaver].SS_curCount, cx	; set new count
;;;done:
	.leave
	ret
IMSetSaverDelay	endm


COMMENT @----------------------------------------------------------------------

METHOD:		IMSetSaver -- IMClass MSG_IM_[INSTALL/REMOVE]_SCREEN_SAVER

DESCRIPTION:	Set a new screen blanking action, or remove one

PASS:
	ds - dgroup
	ax 	- The method
	cx:dx	- OD of screen saver

	for MSG_IM_INSTALL_SCREEN_SAVER

		si	- begin method (sent to OD to turn saver ON)
		bp	- end method (sent to OD to turn saver OFF)

	for MSG_IM_REMOVE_SCREEN_SAVER

		Nothing additional.

RETURN:
	nothing

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version
	Doug	3/91		Re-wrote

------------------------------------------------------------------------------@

IMSetSaverOD	method dynamic	IMClass, MSG_IM_INSTALL_SCREEN_SAVER, \
				   MSG_IM_REMOVE_SCREEN_SAVER
						; if active, unBlank old saver
	test	ds:[screenSaver].SS_state, mask SSS_ACTIVE
	jz	HI_oldOK
	call	UnBlankScreens
HI_oldOK:

						; remove?
	cmp	ax, MSG_IM_REMOVE_SCREEN_SAVER
	je	handleRemove			;  yes, branch

	; Install new screen saver
	;
	mov	ds:[screenSaver].SS_OD.handle, cx	; set new OD
	mov	ds:[screenSaver].SS_OD.chunk, dx
	mov	ds:[screenSaver].SS_beginMethod, si	; set new methods
	mov	ds:[screenSaver].SS_endMethod, bp

						; if supposed to be active,
						; get it there, with new saver.
done:
	test	ds:[screenSaver].SS_state, mask SSS_ACTIVE
	jz	exit
	call	BlankScreens
exit:
	ret


handleRemove:
	; Remove screen saver, if current
	;
	cmp	ds:[screenSaver].SS_OD.handle, cx	; see if current OD
	jne	done
	cmp	ds:[screenSaver].SS_OD.chunk, dx
	jne	done

	clr	ds:[screenSaver].SS_OD.handle
	jmp	done

IMSetSaverOD	endm


IMMiscInput	ends

