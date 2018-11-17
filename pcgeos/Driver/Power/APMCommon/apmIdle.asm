COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Power Drivers
FILE:		apmIdle.asm

AUTHOR:		Todd Stumpf, Aug  1, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94   	Initial revision


DESCRIPTION:
	
		

	$Id: apmIdle.asm,v 1.1 97/04/18 11:48:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMIdle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Idle the processor

CALLED BY:	PowerStrategy

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	di, ds, es

PSEUDO CODE/STRATEGY:
	"Called during the idle (dispatch) loop when there are no
		runnable threads.  The CPU can be turned off until the
		next IRQ happens."

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Todd	6/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMIdle	proc	near
	uses	ax, bp
	.enter
	;
	;  See if we "stand-by" by powering down the CPU, or if we
	;  power-down, by powering off everything.
	test	ds:[powerDownOnIdle], mask AOIS_SUSPEND
	jnz	powerDown

	;
	;  If we slow down the processor, mark us as "slow" so that
	;  the next call to a NotIdle routine will speed us up.
	test	ds:[supportFlags], mask APMSF_CPU_IDLE_SLOWS_PROCESSOR
	jz	standBy

	ornf	ds:[powerDownOnIdle], mask AOIS_ON_STAND_BY

standBy:
	;
	;  See if we can talk to APM BIOS yet.  If not, wait for
	;  next Idle Loop...
	call	APMLockBIOSNB
	jc done

	;
	;  Enter the "Stand-by" state.  This can either be
	;  powering off the CPU until the next interrupt,
	;  or slowing the CPU down.  If it is just slowed
	;  down, we deal with speeding things up in
	;  APMNotIdle / APMNotIdleOnIntrruptCompletion.
	CallAPM	APMSC_CPU_IDLE			; ax destroyed

	call	APMUnlockBIOS
EC<	ERROR_C -1			; ah should have error #	>
standingBy:
	;
	;  Clear "warning" bit in currentWarnings
	andnf	ds:[currentWarnings], not mask PW_APM_BIOS_STAND_BY_REQUEST

done:
	.leave
	ret

powerDown:
	;
	;  See if we can talk to APM BIOS yet.  If not, wait for
	;  next Idle Loop...

	call	APMLockBIOSNB
	jc	done

	;
	;  Clear stand-by bit
	andnf	ds:[powerDownOnIdle], not mask AOIS_ON_STAND_BY

	;
	;  Enter the "Power-off" state
	call	APMSuspendMachine

	;
	;  Clear the suspend bit so we only do it once
	andnf	ds:[powerDownOnIdle], not mask AOIS_SUSPEND
	mov	bp, ISRT_RESUME
	call	APMSendSuspendResumeGCN

	call	APMUnlockBIOS
	jmp	short standingBy

APMIdle	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMNotIdle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Un-idle the processor

CALLED BY:	PowerStrategy

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	di, ds, es

PSEUDO CODE/STRATEGY:
	"Called when an interrupt occurs and PC/GEOS is in the idle
		state.	  Drivers that slow (rather than stop)
		the clock on DR_POWER_IDLE should speed it
		up again on DR_POWER_NOT_IDLE"

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Todd	6/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMNotIdle	proc	near
	;
	;  See if CPU slowed when we went into the IDLE
	;	state.  If not, then we have fully restored from
	;	the idle state (or we wouldn't even be
	;	able to execute this code) and we can continue.
	test	ds:[supportFlags], mask APMSF_CPU_IDLE_SLOWS_PROCESSOR
	jnz	speedUp

done:
	ret

speedUp:
	;
	;  Since we can slow the CPU, we need to make sure that we
	;  did.  We might have entered a power-off state instead.
	test	ds:[powerDownOnIdle], mask AOIS_ON_STAND_BY
	jz	done

reallySpeedUp::
	;
	;  We're really, really slow right now.  Speed up
	;	the processor.
	call	APMLockBIOSNB
	jc	done	; => Couldn't get to BIOS

	push	ax

	CallAPM	APMSC_CPU_BUSY			; ax destroyed

	pop	ax

	call	APMUnlockBIOS
EC <	ERROR_C -1		; ah should have error #		>

	;
	;  Mark ourselves as recovered
	andnf	ds:[powerDownOnIdle], not mask AOIS_ON_STAND_BY
	jmp	short done
APMNotIdle	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMNotIdleOnInterruptCompletion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the processor that we need to continue after this
		interrupt completes.

CALLED BY:	PowerStrategy

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	di, ds, es

PSEUDO CODE/STRATEGY:
	"Called when a thread has been woken up (usually as the result
	of an IRQ).  If the CPU has been halted in the DR_POWER_IDLE call,
	this provides notification that CPU should not be idle when the
	interrupt completes." (Generally meaning that there is now a
	runnable thread.)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Todd	6/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMNotIdleOnInterruptCompletion	proc	near
		GOTO	APMNotIdle
APMNotIdleOnInterruptCompletion	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMLongTermIdle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify that the machine will be idled due to long-term
		inactivity (shut down the video)

CALLED BY:	PowerStrategy

PASS:		DS, ES	= DGroup

RETURN:		carry - set if machine has been turned off and has been
			awakened by new user activity (this causes the screen
			saver to be bypassed).

DESTROYED:	di, ds, es

PSEUDO CODE/STRATEGY:
	"Called when the screen saver is about to be invoked, meaning
	that the user has done nothing for the screen saver idle time
	(typically one to five minutes)."

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Todd	6/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMLongTermIdle	proc	near
	uses 	ax, bx, si, bp
	.enter
	;
	;  Verify that we can shut down.  Do this
	;  By checking if any of the serial, parallel or
	;  pcmcia ports are open and shouldn't be shut down.
	call	APMVerifyLongTermIdleOK	; carry set if not ok
						; si <- reason for rejection
	jc	done

if	HAS_AC_ADAPTER

	;
	;  See if we are connected to an AC adapter.
	;  If so, don't suspend
	call	APMGetStatusACLine		; ax <- AC adapter status
						; bx <- PowerStatus supported

	test	ax, mask PS_AC_ADAPTER_CONNECTED	; clears CF
	jnz	done

endif

	;
	;  Well, the system is in a state where we can suspend the
	;  machine, and we aren't hooked up to an AC line, so we
	;  probably should suspend it.  Wait for the next Idle
	;  loop and then do so.
	ornf	ds:[powerDownOnIdle], mask AOIS_SUSPEND
		CheckHack <ISRT_SUSPEND eq 0>
	clr	bp			; bp = ISRT_SUSPEND
	call	APMSendSuspendResumeGCN
	call	InitFileCommit
	stc

done:
	.leave
	ret
APMLongTermIdle	endp

Movable	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMSendSuspendResumeGCN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send instant suspend/resume general change notifications

CALLED BY:	INTERNAL
PASS:		bp	= InstantSuspendResumeType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	It is important that threads receiving notifications have a chance
	to run after ISRT_SUSPEND notifications are sent and before actual
	suspend happens.  So make sure that either this routine is called on
	a non-kernel thread, or it is called on the kernel thread and the
	thread will reach Dispatch at least once before suspending.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/01/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMSendSuspendResumeGCN	proc	far
	.enter
	pusha

		CheckHack <MANUFACTURER_ID_GEOWORKS eq 0>
	clr	bx			; bx = MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_INSTANT_SUSPEND_RESUME_NOTIFICATIONS
	mov	ax, MSG_META_NOTIFY
	mov	cx, bx			; cx = MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_INSTANT_SUSPEND_RESUME_NOTIFICATION
					; cxdx = NotificationType
	mov	di, mask GCNLSF_FORCE_QUEUE
	call	GCNListRecordAndSend

	popa
	.leave
	ret
APMSendSuspendResumeGCN	endp

Movable	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMSuspendMachine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Place the machine into a suspended state

CALLED BY:	(INTERNAL) APMLongTermIdle

PASS:		es	-> dgroup
		ds	-> dgroup
		BIOS Lock held by caller

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Suspends the machine

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/22/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMSuspendMachine		proc	near
	uses	ax, bx, cx, dx, di, si
	.enter
	;
	;  We are suspsending the machine, so we should reset the suspend
	;  value (just incase we're close to suspending...), so BIOS doesn't
	;  get mixed messages.
	mov	ds:[suspendRequestCountdown], MAX_SUSPEND_REQUEST_LIMIT

	;
	;  Notify people who are "power concious" that we are going
	;  to be shutting down
	mov	ax, PNC_POWER_SHUTTING_OFF
	call	APMCallPowerNotifyCallbacks

	;
	; Hold up input to the UI, so that input won't bypass the
	; password dialog when we start up.
	call	APMGetUIAppObject
	mov	ax, MSG_GEN_APPLICATION_HOLD_UP_INPUT
	clr	di
	call	ObjMessage

if	RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE
	;
	; Record that we are going to be in suspended mode.
	mov	ax, TRUE
	call	APMWriteSuspendStateToIni
endif	; RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE

	;
	;  Do Hardware Specific pre-shutdown Code
if	DEVICE_SPECIFIC_PRE_SUSPEND_CODE
	call	APMPreSuspendHWCode
endif

suspendMachine::
	;
	;  Call BIOS to actually suspend
	mov	bx, APMDID_ALL_BIOS_DEVICES 	; (01h)
	mov	cx, APMS_SUSPEND		; (02h)


	CallAPM	APMSC_ENTER_SUSPEND_STATE


if	DEVICE_SPECIFIC_RESUME_REQUIREMENTS
	call	APMIsOkToContinue
	jc	suspendMachine
endif
	;--------------------------------------------------
	; NOW WE'RE STARTING UP AGAIN

	;
	;  Installed the Password Monitor to prevent shutdown.
	call	APMInstallPasswordMonitor

	;
	;  Now that we suspended, get the system back on the
	;  right time-footing, and verify the device's password
	;
	mov	ax, PNC_POWER_TURNING_ON
	call	APMRecoverFromSuspend

if	RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE
	;
	; Record that we are no longer in suspended mode.
	clr	ax
	call	APMWriteSuspendStateToIni
endif	; RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE

	;
	; And resume input, now that there's already a message in the
	; UI's queue to put up the password dialog (perhaps).
	call	APMGetUIAppObject
	mov	ax, MSG_GEN_APPLICATION_RESUME_INPUT
	clr	di
	call	ObjMessage

	clc

	.leave
	ret
APMSuspendMachine	endp

if	RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMWriteSuspendStateToIni
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write whether or not we are in suspended mode to init file.

CALLED BY:	APMSuspendMachine
PASS:		ax	= non-zero if TRUE, 0 if FALSE
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	init file committed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/26/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
powerCat	char	"power", 0
suspendedKey	char	"suspended", 0

APMWriteSuspendStateToIni	proc	near
	uses	ds
	.enter
	pusha

	mov	cx, cs
	mov	dx, offset suspendedKey	; cx:dx = key
	mov	ds, cx
	mov	si, offset powerCat	; ds:si = cat
	call	InitFileWriteBoolean
	call	InitFileCommit

	popa
	.leave
	ret
APMWriteSuspendStateToIni	endp

endif	; RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMWriteLockToIni
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	If we are going to need to prompt the user for the password,
	we need to write the locked string to the ini file now just
	incase the user reboots before we resume and write out the
	locked string when the password dialog box comes up.

CALLED BY:	APMSuspendMachine
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	7/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMRecoverFromSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with returning from a system-suspend

CALLED BY:	APMSuspendMachine

PASS:		ax	-> PowerNotifyChange
		ds	-> dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Many.
		Updates RTC, BIOS and anything else it can think of.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMRecoverFromSuspendFar	proc	far
	call	APMRecoverFromSuspend
	ret
APMRecoverFromSuspendFar	endp

APMRecoverFromSuspend	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter

	;
	; Keep track of the fact that we're in the middle of
	; recovering from a suspend.
	mov	ds:[suspendRecover], TRUE

	;
	; Update the RTC and DOS clocks
	call	APMUpdateClocks		; releases BIOS lock

	;
	;  Make sure power levels are the way they're supposed
	;  to be.
	call	APMEnforceWorldView

	;
	;  Notify people who are "power concious" that we
	;	are coming back online
	call	APMCallPowerNotifyCallbacks

	;
	;  Clear warning bits in currentWarnings, and
	;  reportedWarnings, as we want to re-inform the user of
	;  any pending power problems
	clr	ds:[currentWarnings]
	clr	ds:[reportedWarnings]

	;
	;  Do Hardware Specific post-shutdown Code
if	DEVICE_SPECIFIC_POST_SUSPEND_CODE
	call	APMPostSuspendHWCode
endif

	;
	;  Prompt for password.
	call	APMPromptForPassword
afterPassword::

if	HAS_DOS_LEVEL_APM
	;
	; Tell the BIOS to turn off Global Power Management
	call	APMDisableGPM
endif

	;
	; Check to see if APO is currently enabled.  If so, we need to
	; restart the screen saver so it'll time out x minutes from now.
	push	cx, dx, si, ds

	mov	cx, cs
	mov	dx, offset screenBlankerKey
	mov	ds, cx
	mov	si, offset screenBlankerCategory
	call	InitFileReadBoolean		; ax <- True/False

	pop	cx, dx, si, ds

	jc	doNotEnableScreenSaver 	; => fresh .INI file,
					;    screen saver must be off.

	tst	ax
	jz	doNotEnableScreenSaver	; => APO is off.

	;
	;  Inform Input Manager we just recovered from a suspend and that
	;  the APO timer should be restart.
	mov	ax, MSG_IM_DISABLE_SCREEN_SAVER
	call	ImInfoInputProcess		; bx <- handle of IM
	clr	di
	call	ObjMessage

	mov	ax, MSG_IM_ENABLE_SCREEN_SAVER
	clr	di
	call	ObjMessage

doNotEnableScreenSaver:
	;
	; No longer recovering from a suspend -- RTC alarms should "ack".
	mov	ds:[suspendRecover], FALSE

	.leave
	ret

screenBlankerCategory		char	"ui",0
screenBlankerKey		char	"screenBlanker",0

APMRecoverFromSuspend	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMUpdateClocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update DOS timer from RTC clock

CALLED BY:	APMRecoverFromSuspend

PASS:		ds	-> dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Updates DOS clock

PSEUDO CODE/STRATEGY:

	Restore our clocks and such so we agree with DOS. We don't
	actually want to get the time from DOS, however, as its
	clock might not be accurate at this time.  The APM BIOS
	updates the BIOS clock when it suspends, but expects DOS to
	do its own updating on the DOS timer tick.  This means we
	must use the RTC clock to ensure we are getting the correct
	time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMUpdateClocks	proc	near
	uses	ax, bx, cx, dx
	.enter

	call	APMReadRTC		; dh <- seconds
					; dl <- minutes
					; ch <- hours
					; bl <- month
					; bh <- day
					; ax <- century+year

	mov	cl, mask SDTP_SET_DATE or \
		    mask SDTP_SET_TIME or \
		    1 shl 5			; don't update DOS time,
						;   just our time...
	call    TimerSetDateAndTime	; ax, bx, cx, dx destroyed

	.leave
	ret
APMUpdateClocks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMVerifyLongTermIdleOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if it is ok to turn off APM

CALLED BY:	APMLongTermIdle

PASS:		ds	-> dgroup
		es	-> dgroup

RETURN:		carry set if not ok
		si	<- chunk of string to explain rejection, or NULL if
			   no dialog should be displayed.

DESTROYED:	nothing

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Examine the powerOffOK bits for any restricted
			permissions.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HAS_SERIAL_PORTS
	basePowerStatus		equ	serialPowerStatus
else
if	HAS_PARALLEL_PORTS
	basePowerStatus		equ	parallelPowerStatus
else
if	HAS_PCMCIA_PORTS
	basePowerStatus		equ	pcmciaPowerStatus
else
if	HAS_DISPLAY_CONTROLS
	basePowerStatus		equ	displayPowerStatus
else
if	HAS_SPEAKER_CONTROLS
	basePowerStatus		equ	speakerPowerStatus
endif
endif
endif
endif
endif

APMVerifyLongTermIdleOKFar		proc	far
	call	APMVerifyLongTermIdleOK
	ret
APMVerifyLongTermIdleOKFar		endp


APMVerifyLongTermIdleOK	proc	near
errorCount		local	word
errorValue		local	word
	uses	ax, cx, di
	.enter
	clr	ax, errorCount, errorValue

	mov	si, offset basePowerStatus
	mov	di, offset powerErrorStringTable

	;
	;  For each powered device on the device, see if it
	;  is on, and if we need to display an error
	mov	cx, NUM_OF_DEVICES

deviceLoop:
	cmp	{byte}ds:[si], mask SR_RESTRICTED or mask SR_DEVICE_ON
	jne	nextDevice

	mov	ax, cs:[di]		; errorValue <- error string
	mov	errorValue, ax

	inc	errorCount

nextDevice:
	inc	di				; advance to next error chunk
	inc	di
	inc	si				; advance to next power status

	loop	deviceLoop

	;
	;  Did we get any errors at all?
	tst_clc	errorCount
	jz	done		; => No errors, shut down.

if	HAS_DIGITIZER_TABLET
	;
	;  Did we get just one?
	cmp	errorCount, 1
	jne	error		; => More than 1 error, don't shut down

	;
	;  We got one Error.  See if we happen to have a secondary
	;  Mouse driver loaded.  If we do, we ignore this little
	;  problem, and let the system shut down.  If we don't,
	;  we complain.
	;  To see if have two drivers loaded, see if the pointer
	;  is always hidden (we don't have a secondary mouse
	;  driver) or if it is not (we do have a secondary mouse
	;  driver)
	;  p.s.  Kudos to Don for the "cool-hack"  -- todd
	call	ImGetPtrFlags		; al <- PtrFlags

	test	al, mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE
	jz	done

error:
endif

	mov	si, errorValue
	stc
done:
	.leave
	ret
APMVerifyLongTermIdleOK	endp

ifidn	HARDWARE_TYPE, <GPC1>
.assert (NUM_SERIAL_PORTS eq 2)
powerErrorStringTable	word	offset PowerOffSerialOnString	; COM1
			word	NULL				; COM2
			word	NUM_PARALLEL_PORTS	dup (\
						offset PowerOffParallelOnString)
			word	NUM_PCMCIA_PORTS	dup (\
						offset PowerOffPCMCIAOnString)
			word	NUM_DISPLAY_CONTROLS	dup (\
						offset PowerOffDisplayOnString)
			word	NUM_SPEAKER_CONTROLS	dup (\
						offset PowerOffSpeakerOnString)
else
powerErrorStringTable	word	NUM_SERIAL_PORTS	dup (\
						offset PowerOffSerialOnString)
			word	NUM_PARALLEL_PORTS	dup (\
						offset PowerOffParallelOnString)
			word	NUM_PCMCIA_PORTS	dup (\
						offset PowerOffPCMCIAOnString)
			word	NUM_DISPLAY_CONTROLS	dup (\
						offset PowerOffDisplayOnString)
			word	NUM_SPEAKER_CONTROLS	dup (\
						offset PowerOffSpeakerOnString)
endif	; HARDWARE_TYPE, <GPC1>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMEnableReboot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the REBOOT button, if we disabled it before

CALLED BY:	APMPasswordOK, APMExit

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	flags

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMEnableReboot	proc near
		uses	ax,cx, dx
		.enter
		.leave
		ret
APMEnableReboot	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMRTCAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge 

CALLED BY:	PowerStrategy, DR_POWER_RTC_ACK

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMRTCAck	proc near
if	HAS_RTC_INTERRUPT
		uses	ax, bx, cx, dx, ds
		.enter

	;
	; If we're recovering from a suspend, then don't do this ACK
	; now -- we'll do it later
	;

		segmov	ds, dgroup, ax
		tst	ds:[suspendRecover]
		jnz	done	; => are recovering

		call	APMSendRTCAck

done:
		
		.leave
endif
		ret
APMRTCAck	endp

Resident		ends

Movable			segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMRecoverFromCriticalSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When we receive a critical resume event, do something

CALLED BY:	
PASS:		ds	-> dgroup
RETURN:		carry set if shouldn't display dialog
DESTROYED:	nothing
SIDE EFFECTS:
		Updates BIOS clocks

PSEUDO CODE/STRATEGY:
		Oh joy.  The User pulled the batteries out.

		Try to respond in a "good way"


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMRecoverFromCriticalSuspend	proc	near
	uses	ax
	.enter

	;
	;  Joy.  We're hosed.  Big time.  Let's see what
	;  we can do.
	call	SysEnterCritical

	;
	;  First, let's clean up some state.  We shutdown recently,
	;  and so we might as well reset our request counter...
	mov	ds:[suspendRequestCountdown], MAX_SUSPEND_REQUEST_LIMIT

	;
	;  Also, let's try to throw up a dialog and make things "nice"
	call	APMInstallPasswordMonitorFar

	mov	ax, PNC_POWER_TURNED_OFF_AND_ON
	call	APMRecoverFromSuspendFar

	;
	;  Finally, make sure the device states are the way they're
	;  supposed to be.
	call	APMEnforceWorldViewFar

	;
	;  Now, let things "get back to normal"...
	;	HA!
	call	SysExitCritical

	clc					; normally display dialog
	.leave
	ret
APMRecoverFromCriticalSuspend	endp

Movable		ends



