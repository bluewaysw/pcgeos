COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Generic APM Power Driver
MODULE:		Power Manager
FILE:		apmpwr.asm

AUTHOR:		Todd Stumpf, Jun 21, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/21/94   	Initial revision


DESCRIPTION:
	This file contains the common routines needed to communicate
	with a BIOS-level APM implementation.

	This file can be easily customized through the apmConfigure.def
	file.

	$Id: apmStrategy.asm,v 1.1 97/04/18 11:48:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include	Internal/heapInt.def

;------------------------------------------------------------------------------
;		Driver Information structure
;------------------------------------------------------------------------------

idata	segment

	DriverTable	DriverInfoStruct < PowerStrategy,
					   <>,
					   DRIVER_TYPE_POWER_MANAGEMENT	>

	ForceRef	DriverTable

idata	ends

;----------------------------------------------------------------------------
;		Code
;-----------------------------------------------------------------------------

Resident		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMPowerStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine for APM driver

CALLED BY:	GLOBAL

PASS:		DI	= PowerManagementFunction
		depends upon function called

RETURN:		depends upon function called

DESTROYED:	DI, depends upon function called

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Todd	6/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMPowerStrategy	proc	far
	.enter
	;
	;  Make sure we have a legal command
	cmp	di, PowerManagementFunction
	jae	error

	push	es, ds				; save trashed seg. registers

	;
	; Set up dgroup, and call function
	push	ax				; save trashed registers

	mov	ax, segment dgroup
	mov	ds, ax				; ds <- dgroup
	mov	es, ax				; es <- dgroup

	pop	ax				; restore register

	call	cs:powerFunctions[di]		; call routine

	pop	es, ds				; restore seg. registers

done:
	.leave
	ret
error:
	stc
	jmp	done
APMPowerStrategy	endp

powerFunctions	label	nptr
DefFunction	DR_INIT,			APMInit
DefFunction	DR_EXIT,			APMExit
DefFunction	DR_SUSPEND,			APMSuspend,
DefFunction	DR_UNSUSPEND,			APMUnsuspend,
DefFunction	DR_POWER_IDLE,			APMIdle,
DefFunction	DR_POWER_NOT_IDLE,		APMNotIdle,
DefFunction	DR_POWER_NOT_IDLE_ON_INTERRUPT_COMPLETION,\
					APMNotIdleOnInterruptCompletion,
DefFunction	DR_POWER_LONG_TERM_IDLE,	APMLongTermIdle,
DefFunction	DR_POWER_GET_STATUS,		APMGetStatus,
DefFunction	DR_POWER_SET_STATUS,		APMNotSupported,
DefFunction	DR_POWER_DEVICE_ON_OFF,		APMDeviceOnOff,
DefFunction	DR_POWER_SET_PASSWORD_OLD,	APMSetPassword,
DefFunction	DR_POWER_VERIFY_PASSWORD_OLD,	APMCheckPassword,
DefFunction	DR_POWER_ON_OFF_NOTIFY,		APMRegisterPowerOnOffNotify,
DefFunction	DR_POWER_DISABLE_PASSWORD_OLD,	APMDisablePassword,
DefFunction	DR_POWER_PASSWORD_OK_OLD,	APMPasswordOK
DefFunction	DR_POWER_RTC_ACK_OLD,		APMRTCAck
DefFunction	DR_POWER_ON_OFF_UNREGISTER,	APMOnOffUnregister
DefFunction	DR_POWER_ESC_COMMAND,		APMEscCommand
DefFunction	DR_POWER_LONG_TERM_IDLE_END,	APMNotSupported

; Ensure end of table doesn't grow without us knowing

.assert DR_POWER_LONG_TERM_IDLE_END+2 eq PowerManagementFunction


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver

CALLED BY:	PowerStrategy

PASS:		DS, ES	-> DGroup

RETURN:		Carry	<- Clear (success)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		Check existance of APM BIOS
			if fail => Bail
		Register with APM BIOS

		Remove DOS level Power Control

		Allocate Queue for getting YES/NO responses

		Begin Polling for Battery Level Events

		Disable BIOS password control

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Todd	6/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMInit	proc	near
	uses	ax, bx, cx, dx, si, di
	.enter

	;
	;  Establish connection with BIOS

	mov	bx, APMDID_SYSTEM_BIOS
	call	SysLockBIOS
	CallAPM	APMSC_CHECK_EXISTANCE
	call	SysUnlockBIOS			; ax <- protocol #
						; bx <- "PM"
						; cx <- APMSupportFlag
	jc	done	; => No APM found


if	APM_VERSION eq 0x0100
	cmp	ax, (APM_MAJOR_VERSION_BCD shl 8) or APM_MINOR_VERSION_BCD
	stc					;carry <- in case of error
	jne	done				;branch if wrong version
endif
	;
	; save the version
	;	
	mov	ds:protoMajorMinor, ax
	;
	;  Check return values to ensure they are what
	;	we expect.
	cmp	bx, ('P' shl 8) or 'M'
	stc					; assume not found
	jne	done	; => No APM found

	mov	ds:[supportFlags], cx

	;
	;  Establish connection with BIOS
	mov	bx, APMDID_SYSTEM_BIOS

	call	SysLockBIOS
tryConnect:
	CallAPM	APMSC_ESTABLISH_CONNECTION
	; If BIOS returns an error, it's because an earlier connection wasn't
	; disconnected properly.  This can happen if the user suspended the
	; machine and then switched the AC power off and on, or if GEOS
	; crashed and then the machine was rebooted.  In either case, we
	; fake a disconnect for the previous connection, and then try to
	; establish a connection again.
	;
	; (Theoretically we could also just ignore the BIOS error and
	; pretend that we are the previously connected client.  However, at
	; least on the GPC machine this doesn't work for some reason.  When
	; it doesn't work, the APM BIOS doesn't return any APM event to us
	; when we poll it with APMSC_GET_PM_EVENT.  Then the PM driver
	; doesn't have any control when the user requests for suspend since
	; we don't get any APME_USER_SUSPEND_REQUEST.)
EC <	WARNING_C RETRYING_ESTABLISH_CONNECTION_WITH_BIOS		>
	jnc	connected
	Assert	e, ah, APMEC_CONNECTION_ALREADY_ESTABLISHED
	CallAPM	APMSC_DISCONNECT
	jmp	tryConnect

connected:
	call	SysUnlockBIOS

if	APM_VERSION ge 0x0101		; v1.1 or above
	;
	; Tell BIOS what version we want.
	mov	bx, APMDID_SYSTEM_BIOS
	mov	cx, (APM_MAJOR_VERSION_BCD shl 8) or APM_MINOR_VERSION_BCD
	call	SysLockBIOS
	CallAPM	APMSC_DRIVER_VERSION	; ah = major ver, al = minor ver, CF
	call	SysUnlockBIOS
	Assert	carryClear
	Assert	e, ax, cx		; make sure version numbers match
endif	; APM_VERSION ge 0x0101

if	HAS_DOS_LEVEL_APM
	;
	;  Disable BIOS Level support for APM (DOS-Level)

	call	APMDisableGPM
endif


	;
	;  Eventually, we need to to SysLockBIOSNB, but of course,
	;  that routine doesn't actually exist.  :(
	;  We fake it by determining the location of the BIOS lock
	;  and doing our own lock...
	mov	ax, SGIT_BIOS_LOCK
	call	SysGetInfo		; dx:ax <- ptr to biosLock

	movdw	ds:[biosLockAddress], dxax

	;
	;  Set up response Queue
	call	GeodeAllocQueue		; bx <- Queue

	mov	ds:[responseQueue], bx

	;
	;  Set up timer to start polling
	mov	al, TIMER_ROUTINE_CONTINUAL	; set up continual timer
	mov	bx, cs				; call APMPollBattery
	mov	si, offset APMPollBattery
	mov	cx, BATTERY_POLL_INITIAL_WAIT	; wait for 30 seconds
	mov	di, BATTERY_POLL_INTERVAL	; then start polling
	call	TimerStart		; bx <- Timer Handle
					; ax <- Timer ID

	mov	ds:[pollingTimerHandle], bx	; save handle and ID
	mov	ds:[pollingTimerID], ax

	mov	cx, vseg PowerDeviceNotification
	mov	dx, offset PowerDeviceNotification
	mov	si, SST_DEVICE_POWER
	call	SysHookNotification

	;
	;  Now, make sure the devices are the way we want them.
						; ds -> dgroup
	call	APMEnforceWorldView

if	HAS_BIOS_LEVEL_PASSWORD
	;
	;  Inform BIOS we will be dealing with the password screen
	call	APMDisableBIOSPassword	; carry set on error
else
	clc
endif

done:

	.leave
	ret
APMInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the power management driver

CALLED BY:	PowerStrategy

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMExit	proc	near
	uses	ax, bx, cx, dx, ds, si
	.enter

	;
	;  Stop timer
	mov	bx, ds:[pollingTimerHandle]
	mov	ax, ds:[pollingTimerID]
	call	TimerStop

	;
	; Clean up connection
	;
	mov	bx, APMDID_SYSTEM_BIOS

	call	SysLockBIOS
	CallAPM	APMSC_DISCONNECT
	call	SysUnlockBIOS

EC<	ERROR_C -1		; ah should have error			>

if	HAS_DOS_LEVEL_APM

	;
	;  Re-enable the APO and GPM values for DOS
	call	APMEnableGPM

endif

if	HAS_BIOS_LEVEL_PASSWORD
	;
	;  Inform BIOS we will no longer be dealing with the password screen
	

endif

	;
	;  Free up response Queue
;can't call movable resource in DR_EXIT of system driver.  However, since we
;are exiting, this isn't really necessary - brianc 4/25/95
;	mov	bx, ds:[responseQueue]		; bx <- Queue
;	call	GeodeFreeQueue		

if	HAS_PCMCIA_PORTS
	;
	; Tell PCMCIA library to unregister itself and otherwise clean up.
	; The drivers themselves should have already received DR_EXIT calls
	call	PCMCIADetach
endif


done::
	;
	; we never unhook the SST_DEVICE_POWER notification because
	; the requisite routine is in movable memory and cannot be called
	; from the exit routine of a system driver. It does no harm to
	; leave ourselves connected to it, in any case, as no one will call
	;

	clc
	.leave
	ret
APMExit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend this driver

CALLED BY:	PowerStrategy

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	di, ds, es

PSEUDO CODE/STRATEGY:
		Release all hooks.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Todd	6/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMSuspend	proc	near
	.enter
	;
	;  As we'll be temporarily indispossed (while we go
	;  do whatever it is we're going to do), we need to
	;  enable DOS level APM (if they have such a thing)
if	HAS_DOS_LEVEL_APM
	call	APMEnableGPM
endif
	;
	;  That's really all we need to do in this case, as
	;  we're just suspending...
	clc

	.leave
	ret
APMSuspend	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend this driver

CALLED BY:	PowerStrategy

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Todd	6/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMUnsuspend	proc	near
	.enter
	;
	;  Now that we're back in the captains seat, 
	;  disable BIOS level support for APM...
if	HAS_DOS_LEVEL_APM
	call	APMDisableGPM
endif

	;
	;  Just in case anyone screwed with the devices,
	;  make sure they're just the way we want them.
						; ds -> dgroup
	call	APMEnforceWorldView

	clc
	.leave
	ret
APMUnsuspend	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMNotSupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry set as function is not supported

CALLED BY:	PowerStrategy
PASS:		nothing
RETURN:		carry set
DESTROYED:	nothing
SIDE EFFECTS:
		none
PSEUDO CODE/STRATEGY:
		set carry		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/27/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMNotSupported	proc	near
	.enter
	stc
	.leave
	ret
APMNotSupported	endp

Resident		ends

