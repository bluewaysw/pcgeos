COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		apmPoll.asm

AUTHOR:		Todd Stumpf, Aug  1, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94   	Initial revision


DESCRIPTION:
	
		

	$Id: apmPoll.asm,v 1.1 97/04/18 11:48:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Resident		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMPollBattery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up UI thread to poll the battery

CALLED BY:	TimerRoutineContinual

PASS:		nothing

RETURN:		nothing

DESTROYED:	everything

SIDE EFFECTS:
		Sets up message in UI thread to poll battery

PSEUDO CODE/STRATEGY:

		Determine if we've processed the last Poll we issued.
		If not bail
		if so, place message in UI's thread to call BatteryPoll

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	7/ 2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMPollBattery	proc	far
	.enter

if	USE_IM_FOR_INITIAL_POLLING
	;
	; If the initial time has passed, use the UI for normal polling.
	call	TimerGetCount		; bxax = count
	cmpdw	bxax, BATTERY_POLL_BY_IM_TIME
	jae	useUI			; => passed

	;
	; Do nothing if the IM thread hasn't been spawned.
	call	ImInfoInputProcess	; bx = IM thread
	tst	bx
	jz	done

	;
	;  See if last request has been processed
	segmov	ds, dgroup
	xchg	ds:[uiBusyElsewhere], bx	; test and set..
	tst	bx
	jnz	done			; => Nope. Still pending

	;
	; Issue next request.
	mov	di, segment APMBatteryPollStep2
	mov	bp, offset APMBatteryPollStep2
	call	CallRoutineInIM
	jmp	done

useUI:
endif	; USE_IM_FOR_INITIAL_POLLING

	;
	; Do nothing if the UI lib hasn't been loaded.  This can happen if
	; BATTERY_POLL_INITIAL_WAIT is set to very small or even zero by
	; some driver which wants polling to start as soon as possible.
	;
	; We could just call CallRoutineInUI and let it send
	; MSG_PROCESS_CALL_ROUTINE to NULL (which gets dropped) when the UI
	; lib hasn't been loaded, but since we have to keep uiBusyElsewhere
	; in balance, we need to check it ourselves.
	;
	mov	ax, SGIT_UI_PROCESS
	call	SysGetInfo				; ax <- ui handle
	tst	ax
	jz	done

	mov	di, segment dgroup			; di <- our dgroup
	mov	ds, di					; ds <- our dgroup

	;
	;  See if last request has been processed
	xchg	ds:[uiBusyElsewhere], di		; test and set..

	tst	di
	jnz	done	; => Nope. Still pending

	;
	;  Issue next request
	mov	di, segment APMBatteryPollStep2
	mov	bp, offset APMBatteryPollStep2
	call	CallRoutineInUI	

done:

	.leave
	ret
APMPollBattery	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMBatteryPollStep2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if we must wait for a response from a dialog
		we have displayed, or if we can continue polling the battery

CALLED BY:	APMPollBattery

PASS:		nothing

RETURN:		nothing

DESTROYED:	everything

SIDE EFFECTS:
		Fiddles with the Queue

PSEUDO CODE/STRATEGY:
		Identify receipt of event
		See if there is a response pending, if not
		poll the battery.
		If so, See if the response has been recieved.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMBatteryPollStep2	proc	far
	.enter
	segmov	ds, dgroup, ax

	;
	;  Acknowledge request
	clr	ds:[uiBusyElsewhere]

	;
	;  See if we're waiting for a response from the User
	tst	ds:[waitingForResponse]
	jnz	examineQueue	;=> We are

	;
	;  Poll that there battery again...
	call	APMPollForWarnings

done:

if	RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE
	tst	ds:[resuspendChecked]
	jnz	afterResuspendCheck
	mov	ax, SGIT_UI_PROCESS
	call	SysGetInfo		; ax = UI handle if loaded
	tst	ax
	jz	afterResuspendCheck
	call	CheckResuspend
	dec	ds:[resuspendChecked]
afterResuspendCheck:
endif	; RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE

if	HAS_ADDITIONAL_POLLING_TO_DO
	;
	;  Do whatever it is we need to do
							; ds -> dgroup
	call	APMAdditionalPeriodicPoll

endif

	.leave
	ret

examineQueue:
	;
	;  See if anyone put anything in our queue
	call	APMLookForResponse
	jmp	short done
APMBatteryPollStep2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the power status of various system elements

CALLED BY:	PowerStrategy

PASS:		ax	-> PowerGetStatusType

RETURN:		carry set if error (not supported)

		ax, bx, cx, dx = return value based on PowerGetStatusType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Gets called by the battery timer (twice a second)

		PGST_POWER_ON_WARNINGS:
			ax <- PowerWarnings
			bx <- mask of PowerWarnings flags supported

		PGST_POLL_WARNINGS:
			ax <- PowerWarnings
			bx <- mask of PowerWarnings flags supported

		PGST_STATUS:
			ax <- PowerStatus
			bx <- mask of PowerStatus flags supported

		PGST_BATTERY_CHARGE_MINUTES:
			dxax <- battery life in minutes

		PGST_BATTERY_CHARGE_PERCENT:
			dxax <- battery power available as compares to total
				(0-1000) : 0 means none, 1000 means all

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMGetStatus	proc	near
	uses	si
	.enter
	cmp	ax, PowerGetStatusType
	jae	unsupported

	mov_tr	si, ax				; si <- PowerGetStatusType
	shl	si, 1				; si <- word index
	shl	si, 1				; si <- dword index

	movdw	bxax, cs:commandJumpTable[si]		; call handler
	tst	bx
	jz	unsupported		
	call	ProcCallFixedOrMovable

done:
	.leave
	ret

unsupported:
	;  Mark as unsupported
	;
	stc
	jmp	short done

commandJumpTable	vfptr	APMGetStatusWarnings,		; POWER_ON
				APMGetStatusWarnings,		; POLL
				APMGetStatusACLine,		; STATUS
				APMGetStatusBatteryLifeMain,	; MINUTES
				APMGetStatusBatteryMain,	; PERCENT
				APMGetStatusBatteryLifeBackup,  ; MINUTES
				APMGetStatusBatteryBackup	; PERCENT

APMGetStatus	endp

Resident		ends

Movable			segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetStatusWarnings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return current power warnings

CALLED BY:	APMGetStatus (PGST_POWER_ON_WARNINGS)

PASS:		ds	-> dgroup
		
RETURN:		ax	<- new PowerWarnings
		bx	<- supported events

DESTROYED:	nothing

SIDE EFFECTS:
		None

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/27/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert PGST_POWER_ON_WARNINGS	eq	0
APMGetStatusWarnings	proc	far
	uses	cx, dx
	.enter

	;
	;  See if BIOS reports anything interesting...
	call	SysLockBIOS

	CallAPM	APMSC_GET_PM_EVENT	; carry set if no event
					; bx <- APMEvent
	call	SysUnlockBIOS

	jnc	processAPMEvent	; => handle event

if HAS_NON_STANDARD_WARNINGS
afterAPMEvent:
	;
	;  If there are any other special cases we
	;  need to handle, check 'em now.
	clr	bx				; force event
	call	handleEvent		; ax, bx, cx, dx trashed
else
afterAPMEvent:
endif

	mov	ax, ds:[currentWarnings]	; ax <- current state
	mov	bx, WARNINGS_SUPPORTED		; bx <- supported warnigns
	.leave
	ret

processAPMEvent:
	call	handleEvent		; ax, bx, cx, dx trashed
	jmp	afterAPMEvent

APMGetStatusWarnings	endp

	;
	;  PASS:
	;	ds	-> dgroup
	;  RETURN:
	;	ax, bx, cx, dx destroyed
handleEvent		proc	near
	call	APMHandleAPMEvent	; carry set if update warnings
					; bx <- currentWarnings to clear
					; ax <- currentWarnings to set
					; cx <- reportedWarnings clear
					; dx <- reportedWarnings to set
	jnc	fini

	;
	;  We need to update warnings & notifications
	andnf	ds:[currentWarnings], bx
	ornf	ds:[currentWarnings], ax
	andnf	ds:[reportedWarnings], cx
	ornf	ds:[reportedWarnings], dx
fini:
	ret
handleEvent		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMHandleAPMEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process APM Event

CALLED BY:	INTERNAL

PASS:		bx	-> APMEvent
		ds	-> dgroup

RETURN:		carry set if update warnings
		bx <- currentWarnings to clear
		ax <- currentWarnings to set
		cx <- reportedWarnings clear
		dx <- reportedWarnings to set

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMHandleAPMEvent	proc	near
	.enter
	;
	;  Handle the APM event (if immediate action required),
	;  and determine updated Battery Warnings
	cmp	bx, length eventCallTable
	jae	done	; => off table

	shl	bx, 1
	call	cs:eventCallTable[bx]		; carry set if update warnings
						; bx <- currentWarnings to clear
						; ax <- currentWarnings to set
						; cx <- reportedWarnings clear
						; dx <- reportedWarnings to set

done:
	.leave
	ret

if	APM_VERSION eq 0x0100	; v1.0

eventCallTable		nptr	APMProcessSpecialCase,	  ;Non-standard warnings
				APMIgnore,                ;APME_STAND_BY_REQUEST
				APMProcessSuspendRequest, ;APME_SUSPEND_REQUEST
				APMIgnore,                ;APME_NORMAL_RESUME
				APMProcessCriticalResume, ;APME_CRITICAL_RESUME
				APMProcessBatteryLow      ;APME_BATTERY_LOW

else				; v1.1 or above

eventCallTable		nptr	APMProcessSpecialCase,	  ;Non-standard warnings
				APMIgnore,                ;APME_STAND_BY_REQUEST
				APMProcessSuspendRequest, ;APME_SUSPEND_REQUEST
				APMIgnore,                ;APME_NORMAL_RESUME
				APMProcessCriticalResume, ;APME_CRITICAL_RESUME
				APMProcessBatteryLow,     ;APME_BATTERY_LOW
				APMIgnore,		  ;APME_POWER_STATUS_CHANGE
				APMIgnore,		  ;APME_UPDATE_TIME
				APMIgnore,		  ;APME_CRITICAL_SUSPEND
				APMIgnore,		  ;APME_USER_STANDBY_REQUEST
				APMProcessUserSuspendRequest	;APME_USER_SUSPEND_REQUEST

endif	; APM_VERSION eq 0x0100

APMHandleAPMEvent	endp

APMIgnore proc near
	clc			; stub for ignored events
	ret
APMIgnore endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMProcessSuspendRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	APM tells us we should suspend.  Foolish BIOS.

CALLED BY:	APME_SUSPEND_REQUEST

PASS:		ds	-> dgroup

RETURN:		carry set to update currentWarnings & reportedWarnings
		bx	<- currentWarnings to clear (via ANDNF)
		ax	<- currentWarnings to set   (via ORNF)
		cx	<- reportedWarnings to clear (via ANDNF)
		dx	<- reportedWarnings to set (via ORNF)

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMProcessSuspendRequest	proc	near
	.enter
	mov	bx, not ( 0 )			; don't clear any warnings
	mov	ax, mask PW_APM_BIOS_SUSPEND_REQUEST
	mov	cx, bx				; don't re-report anything
	clr	dx				; nothing reported

	stc					; update warning levels

	.leave
	ret
APMProcessSuspendRequest	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMProcessCriticalResume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	APM Tells us we are resuming from Critical Suspend

CALLED BY:	APME_CRITICAL_RESUME
PASS:		ds	-> dgroup

RETURN:		carry set to update currentWarnings & reportedWarnings
		bx	<- currentWarnings to clear (via ANDNF)
		ax	<- currentWarnings to set   (via ORNF)
		cx	<- reportedWarnings to clear (via ANDNF)
		dx	<- reportedWarnings to set (via ORNF)

DESTROYED:	nothing

PSUEDO_CODE:
criticalResume:
	;
	; We just found out we are coming back from a critical
	; suspend.  This must be handled according to each spec..
	call	APMRecoverFromCriticalSuspend	; carry set to avoid dialog
	jc	doneOK	; => they handled it fully
	jmp	short passBackWarning



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMProcessCriticalResume	proc	near
	.enter
	;
	;  Assume we need to update all the states, and
	;  display a warning dialog box.
	clr	bx				; clear all warnings
						; set CRITICAL_RESUME warning
	mov	ax, mask PW_APM_BIOS_RESTORE_FROM_CRITICAL_SUSPEND
	mov	cx, bx				; re-report everything
	mov	dx, bx				; reported nothing 

	call	APMRecoverFromCriticalSuspend	; carry set to avoid dialog
	jnc	afterDialogStatus	; => do It

	;
	;  The device-specific code displayed the dialog box.
	;  Therefore, we don't need to do that.
	mov	dx, mask PW_APM_BIOS_RESTORE_FROM_CRITICAL_SUSPEND

afterDialogStatus:
	stc					; update warning levels
	.leave
	ret
APMProcessCriticalResume	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMProcessBatteryLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	APM Tells us we have a low battery

CALLED BY:	APME_BATTERY_LOW
PASS:		ds	-> dgroup

RETURN:		carry set to update currentWarnings & reportedWarnings
		bx	<- currentWarnings to clear (via ANDNF)
		ax	<- currentWarnings to set   (via ORNF)
		cx	<- reportedWarnings to clear (via ANDNF)
		dx	<- reportedWarnings to set (via ORNF)

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMProcessBatteryLow	proc	near
	.enter
	mov	bx, not ( 0 )			; don't clear any warnings
	mov	ax, mask PW_MAIN_BATTERY	; set MAIN_BATTERY warning
	mov	cx, bx				; don't re-report anything
	clr	dx				; nothing reported

	stc					; update warning levels
	.leave
	ret
APMProcessBatteryLow	endp

if	APM_VERSION ge 0x0101		; v1.1 or above


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMProcessUserSuspendRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	APM tells us the user wants to suspend the machine.

CALLED BY:	APME_USER_SUSPEND_REQUEST
PASS:		ds	-> dgroup

RETURN:		carry set to update currentWarnings & reportedWarnings
		bx	<- currentWarnings to clear (via ANDNF)
		ax	<- currentWarnings to set   (via ORNF)
		cx	<- reportedWarnings to clear (via ANDNF)
		dx	<- reportedWarnings to set (via ORNF)

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/17/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMProcessUserSuspendRequest	proc	near

	or	ds:[miscState], mask MS_ON_OFF_PRESS	; clears CF

	ret
APMProcessUserSuspendRequest	endp

endif	; APM_VERSION ge 0x0101


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMProcessSpecialCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle non-APM power events in an APM-like manner

CALLED BY:	APMHandleAPMEvent
PASS:		ds	-> dgroup
RETURN:		carry set to update currentWarnings & reportedWarnings
		bx	<- currentWarnings to clear (via ANDNF)
		ax	<- currentWarnings to set   (via ORNF)
		cx	<- reportedWarnings to clear (via ANDNF)
		dx	<- reportedWarnings to set (via ORNF)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMProcessSpecialCase	proc	near
	.enter
if	HAS_NON_STANDARD_WARNINGS
	call	APMCheckExceptionalConditions	; carry set if warning
						;  ax <- warning mask if
						;		zero clear
						;  bx <- APM event if
						;		zero set
	jc	checkWarning; => do something
else
	clc					; how'd we get here?
endif	; HAS_NON_STANDARD_WARNINGS

done::
	.leave
	ret

if	HAS_NON_STANDARD_WARNINGS
checkWarning:
	jnz	done ; => not an APM event

	;
	;  We were told to act like an APM event.
	;  Do so, but not if we we'd come straight back here.
	tst	bx
	jz	done	 ; => No.  I refuse to call myself again.

	call	APMHandleAPMEvent
	jmp	done
endif	; HAS_NON_STANDARD_WARNINGS
APMProcessSpecialCase	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMCheckIfCalibrated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if still configuring system

CALLED BY:	INTERNAL

PASS:		nothing
RETURN:		carry set not calibrated
DESTROYED:	nothing

SIDE EFFECTS:
		Reads from .INI file

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HAS_DIGITIZER_TABLET
APMCheckIfCalibrated	proc	near
	uses	ax, cx, dx, si, ds
	.enter
	;
	;  Determine if we are to continue setup.
	mov	cx, cs
	mov	dx, offset penCalibrationKey
	mov	ds, cx
	mov	si, offset penCalibrationCategory
	call	InitFileReadBoolean	; carry set if not found
					; ax <- boolean TRUE/FALSE
	jc	error	; => not calibrated

	cmp	ax, TRUE
	je	error	; => not calibrated

	clc
done:
	.leave
	ret

error:
	stc
	jmp	short done
penCalibrationCategory		char	"system",0
penCalibrationKey		char	"continueSetup",0

APMCheckIfCalibrated	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMPollForWarnings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we have any warnings, and if so display dialogs

CALLED BY:	UI Thread via CallRoutineInUI
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Can display dialogs

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMPollForWarnings	proc	far
	uses	ax, bx, cx, dx, di, si, bp, ds
	.enter
	segmov	ds, dgroup, ax				; ds <- dgroup

	;
	;  Call PowerStrategy to get new warnings
	mov	ax, PGST_POLL_WARNINGS
	mov	di, DR_POWER_GET_STATUS
	call	PowerStrategy	; ax <- current warnings
				; bx <- supported warnings

	tst	ax
	jnz	checkWarnings	; => possible new warnings

done:
if HAS_COMPLEX_ON_OFF_BUTTON
	;
	;  If we have an on-off button, see if it was pressed
	;  recently (thus indicating we should turn off)
	test	ds:[miscState], mask MS_ON_OFF_PRESS
	jnz	handleOnOffPress
endif
fini:

	.leave
	ret

checkWarnings:
	;
	;  Before we worry about dialog boxes, see if we have
	;  any suspend requests...
	test	ax, mask PW_APM_BIOS_SUSPEND_REQUEST
	jnz	suspendRequest	; => got one

	;
	;  We didn't get a suspend-request this time.  Reset
	;  the shutdown counter so that we only force a suspend
	;  when we get a series of 20 requests in a row.
	mov	ds:[suspendRequestCountdown], SUSPEND_REQUEST_COUNTDOWN_VALUE

afterRequest:
	;
	;  Now, we got warnings.  If there are any new
	;  warnings, pass those back.  Otherwise,
	;  just ignore them.
	mov	si, ds:[reportedWarnings]	; si <- prev. reported events
	not	si				; si <- non-reported events
	and	ax, si				; si <- new events
	jz	done	; => nothing to report

if	HAS_DIGITIZER_TABLET
	;
	;  See if we want to display dialog boxes at this time.
	;  If we've not yet calibrated the pen, don't do it!
	call	APMCheckIfCalibrated	; carry set not calibrated
	jc	done	; => not calibrated
endif

	;
	;  Determine which warning to display, and
	;  update the reported warnings so we don't
	;  keep blabbing the same thing again, and again...
							; ax -> new warnings
							; bx -> supported
	call	APMDetermineNewWarning		; si <- dialog string
						; dx <- mask of new warning

displayWarning::
	;
	;  Display the passed string in a warning dialog box
	mov	ax, mask CDBF_SYSTEM_MODAL or \
			(CDT_WARNING shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
						; ax <- CustomDialogBoxFlags
						; si <- chunk in StringsUI
	call	DisplayMessage		; carry set if not displayed
	jc	done	; => not displayed

	;
	;  Mark warning is displayed
	ornf	ds:[reportedWarnings], dx
	jmp	short done


suspendRequest:
	;
	; We have recieved a suspend request from the device.
	; Decrement the countdown value, and if it reaches
	; zero, suspend no-matter-what.  Otherwise, follow
	; standard operating procedures...
	dec	ds:[suspendRequestCountdown]
	jz	forceSuspend	; => time's up, folks!

	call	APMCheckForOnOffPress	; carry clear on press
	jc	afterRequest	; => normal request

handleOnOffPress::
if HAS_COMPLEX_ON_OFF_BUTTON
	;
	;  Mark current press as handled.
	andnf	ds:[miscState], not (mask MS_ON_OFF_PRESS)
endif

	;
	; Well, they pressed the on-off button.  We need to see
	; if we can suspend.  If we can, we suspend, if we can't
	; we tell them why not (it's only polite...)
	call	APMVerifyLongTermIdleOKFar	; carry set on error
						; si <- reason for rejection
if	HAS_ADDITIONAL_ON_OFF_BUTTON_CONFIRM
	jc	noSuspend
	call	APMAdditionalOnOffButtonConfirm	; CF set on error, si = reason
endif
	jnc	forceSuspend	; => Do it.
noSuspend::

if	HAS_DIGITIZER_TABLET
	;
	;  See if we want to display dialog boxes at this time.
	;  If we've not yet calibrated the pen, don't do it!
	call	APMCheckIfCalibrated	; carry set not calibrated
	jc	done	; => not calibrated
endif

ifidn	HARDWARE_TYPE, <GPC1>
	;
	; On the GPC, we don't allow suspending at this point.  The only
	; question is whether or not the PM driver informs the user that he
	; can't suspend the machine.  So we check that.
	tst	si			; Any reason string?
	jnz	informUser		; => yes.  Inform user.

	;
	;  We don't know whether the user suspend request came from the
	;  front-panel On/Off switch via APM BIOS or from the on-screen Off
	;  button, so we make the request-rejected APM call as if the request
	;  was from APM BIOS.  In the case of software on-screen button, it
	;  is still okay as the APM BIOS will just ignore the call.
	mov	bx, APMDID_ALL_BIOS_DEVICES
	mov	cx, APMS_REQUEST_REJECTED
	CallAPM	APMSC_SET_DEVICE_STATE

	;
	;  Tell interested parties about it.
	mov	bp, ISRT_SUSPEND_REFUSED
	call	APMSendSuspendResumeGCN
	jmp	done

informUser:
endif	; HARDWARE_TYPE, <GPC1>

	;
	;  Hmmm.  There's a problem.  Let's see if the user
	;  wants to do something about it.  Throw up a
	;  dialog, and wait for a response.
	call	APMVerifySuspendWithUserFar
	jmp	short done

forceSuspend:
	;
	; Time to suspend.  Wait for the next Idle moment,
	; then it's nighty-night.  (Oh yeah, don't display
	; any pending dialogs as we want to suspend ASAP, and
	; throwing up a dialog will just delay it)
	ornf	ds:[powerDownOnIdle], mask AOIS_SUSPEND
		CheckHack <ISRT_SUSPEND eq 0>
	clr	bp			; bp = ISRT_SUSPEND
	call	APMSendSuspendResumeGCN
	call	InitFileCommit
	jmp	short fini	; => don't report stuff

APMPollForWarnings	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMDetermineNewWarning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine which warning (of many) to pass on to user

CALLED BY:	APMPollForWarnings
PASS:		ax	-> warning status
		bx	-> warnings supported

RETURN:		si	<- string chunk
		dx	<- mask of warning to display

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Go through new warnings (from 1st chunk to last),
		displaying first chunk encountered, and 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMDetermineNewWarning	proc	near
	uses	ax, bx, cx
	.enter
	mov	si, offset MainWarningString	; Always the 1st string
	mov	dx, mask PW_MAIN_BATTERY	; mask of warning
	mov	cx, 16				; # of possible warnings

	;
	;  Find supported warning
topOfLoop:
	shl	bx, 1
	jc	checkWarning	; => valid warning
	shl	ax, 1
nextWarning:
	add	si, size lptr			; access next warning chunk
	shr	dx, 1				; identify next mask bit
	loop	topOfLoop	; => one more time...

done:
	.leave
	ret

checkWarning:
	;
	;  See if this supported warning is pending
	shl	ax, 1
	jnc	nextWarning 	; => not active

	;
	;  See if we've already told the user about this
	;  particular power case.
	test	ds:[reportedWarnings], dx
	jnz	nextWarning	; => old news
	jmp	short done

APMDetermineNewWarning	endp



if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetBatteryStatus
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
	TS	2/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMGetBatteryStatus	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	uses	bx, cx
	.enter
	mov	bx, APMDID_ALL_BIOS_DEVICES

	call	SysLockBIOS
	CallAPM	APMSC_GET_POWER_STATUS
	call	SysUnlockBIOS
EC<	ERROR_C	-1				; ah <- error #		>

	;
	;  Return the percentage of power remaining in the
	;	battery as a XXX.X%.
	cmp	cl, 255
	je	unsupported

	clr	ch					; cx <- 0-100%

	mov	ax, 10					; dxax <- 0-1000
	mul	cx

	clc
done:
	.leave
	ret

unsupported:
	stc
	jmp	short done

	.leave
	ret
APMGetBatteryStatus	endp
endif

if	RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckResuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if we need to re-suspend the machine after the machine
		was rebooted while in suspend mode (probably due to power
		outage.)  If so, display a dialog to confirm with the user
		before re-suspending.

CALLED BY:	APMBatteryPollStep2
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	everything except ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/23/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckResuspend	proc	far
	uses	ds
	.enter

	;
	; Check the init file to see if we were in suspend mode during the
	; last GEOS session.
	;
	mov	cx, segment suspendedKey
	mov	dx, offset suspendedKey	; cx:dx = key
	mov	ds, cx
	mov	si, offset powerCat	; ds:si = cat
	clr	ax			; default = FALSE
	call	InitFileReadBoolean	; ax = FFFFh if true
	tst	ax
	jz	done			; => wasn't in suspend mode

	;
	; Write to init file that we are currently not in suspend mode
	; during this GEOS session.
	;
	inc	ax			; ax = FALSE
	call	InitFileWriteBoolean

	;
	; Lock the string block.
	;
	mov	bx, handle StringsUI
	call	MemLock
	mov	ds, ax
	mov	di, ds:[ResuspendConfirmString]	; ds:di = str

	;
	; Prepare parameters for putting up the timed dialog.
	;
	mov	ax, SGIT_UI_PROCESS
	call	SysGetInfo		; ax = UI handle
	Assert	ne, ax, NULL		; UI must be loaded if we are called
	mov_tr	bx, ax			; bx = UI handle
	call	GeodeGetAppObject	; ^lbx:si = app obj

	mov	dx, size GenAppDoTimedDialogParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADTDP_dialog.SDP_customFlags, CustomDialogBoxFlags \
			<1, CDT_QUESTION, GIT_AFFIRMATION, >
	movdw	ss:[bp].GADTDP_dialog.SDP_customString, dsdi
	clr	ss:[bp].GADTDP_dialog.SDP_helpContext.segment
	segmov	ds, dgroup
	mov	ax, ds:[responseQueue]
	mov	ss:[bp].GADTDP_finishOD.handle, ax
	mov	ss:[bp].GADTDP_message, \
			MSG_META_APP_VERIFY_RESUSPEND_DIALOG_RESPONDED
	mov	ss:[bp].GADTDP_timeout, RESUSPEND_DIALOG_TIMEOUT

	;
	; Tell the UI app object to do it.
	;
	; We don't want to do MF_CALL here, because it would block this
	; thread until the UI thread finishes its MSG_META_ATTACH handler
	; which takes several seconds.  If we are on the IM thread, it would
	; be bad to block for several seconds.  So we do a send.  The
	; drawback is that we can't unlock the strnig block right after
	; sending the message because we're passing a fptr to the string.
	; So we have to wait at least till the dialog has come up on screen.
	; For convenience, we simply wait till the user responds or a timeout
	; occurs to unlock the block.
	;
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_TIMED_DIALOG
	mov	di, mask MF_STACK
	call	ObjMessage

	add	sp, size GenAppDoTimedDialogParams

	;
	; Mark dialog as active.
	;
	inc	ds:[waitingForResponse]

done:
	.leave
	ret
CheckResuspend	endp

endif	; RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE

Movable				ends


