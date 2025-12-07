COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IdlePower power management driver
FILE:		IdlePower.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/92		Initial version of NoPower
	MeyerK	12/25		Initial version of IdlePower, based on NoPower

DESCRIPTION:
	This is a power management driver that does nothing special. It
	puts the processor on HLT whenever GEOS is idle. This reduces the
	amount of power drawn and fan noise significantly on modern systems
	and when running under a host os (emulation).

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include lmem.def		; for extended driver info segment
include geode.def
include resource.def
include	ec.def

include Internal/heapInt.def	; for ProcCallFixedOrMovable defs.

;------------------------------------------------------------------------------
;			Constants & more Include files
;------------------------------------------------------------------------------

DISPLAY_MESSAGES 		=	FALSE
PCMCIA_SUPPORT			equ	FALSE		; don't attempt pcmcia support

NUMBER_OF_CUSTOM_POWER_WARNINGS = 	1
PW_IDLE_POWER_CUSTOM_WARNING	equ	<PW_CUSTOM_1>
IDLE_POWER_DRIVER_UNSUPPORTED_FUNCTION	enum	Warnings

POLL_BATTERY			=	FALSE
BATTERY_POLL_INITIAL_WAIT 	=	30*60	; 30 seconds
BATTERY_POLL_INTERVAL 		=	4*60	; 4 seconds

PowerStrategy			equ	<IdlePowerStrategy>

NEEDS_SERIAL_PASSIVE		= FALSE	; No special SERIAL_PASSIVE handling in powerConstants.def

include powerGeode.def

;------------------------------------------------------------------------------
;		ForceRefs to suppress warnings
;------------------------------------------------------------------------------

ForceRef PowerDeviceOnOff

;------------------------------------------------------------------------------
;		Driver Information structure
;------------------------------------------------------------------------------

idata segment

DriverTable	DriverInfoStruct <
	IdlePowerStrategy,
	<>,
	DRIVER_TYPE_POWER_MANAGEMENT
>

	ForceRef	DriverTable

idata ends

;------------------------------------------------------------------------------
;		Variables
;------------------------------------------------------------------------------

idata segment

notifyAboutDevices	BooleanByte	BB_TRUE

idata ends

udata	segment
udata	ends

;------------------------------------------------------------------------------
;		Code
;------------------------------------------------------------------------------

; This is for testing and demonstration purposes

Resident segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerStrategy

DESCRIPTION:	Strategy routine

CALLED BY:	EXTERNAL

PASS:
	di = function code

RETURN:
	depends on function called

DESTROYED:
	depends on function called

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
IdlePowerStrategy	proc	far	uses ds, es
	.enter

	cmp	di, size functions
	cmc
	jc	done

	push	ax
	mov	ax, idata
	mov	ds, ax
	mov	es, ax
	pop	ax

	call	cs:functions[di]
done:
	.leave
	ret

IdlePowerStrategy	endp

functions	nptr	\
	IdlePowerInit,
	IdlePowerExit,
	IdlePowerSuspend,
	IdlePowerUnsuspend,
	IdlePowerIdle,
	IdlePowerNotIdle,
	IdlePowerNotIdleOnInterruptCompletion,
	IdlePowerLongTermIdle,
	IdlePowerGetStatus,
	IdlePowerSetStatus,
	IdlePowerDeviceOnOff,
	IdlePowerSetPassword,
	IdlePowerVerifyPassword,
	IdlePowerRegisterPowerOnOffNotify,
	IdlePowerDisablePassword,
	IdlePowerRTCAck,
	IdlePowerOnOffUnregister,
	IdlePowerEscCommand

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerInit

DESCRIPTION:	Initialize the driver

CALLED BY:	IdlePowerStrategy (DR_INIT)

PASS:
	ds, es - idata

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
powerCat	char	'power', 0
showDevicesKey	char	'showDevices', 0

IdlePowerInit	proc	near

	; Device specific initialization

	push	ds
	segmov	ds, cs, cx
	mov	si, offset powerCat
	mov	dx, offset showDevicesKey
	call	InitFileReadBoolean
	pop	ds
	jc	devSpecDone
	tst	ax
	jnz	devSpecDone

	mov	ds:[notifyAboutDevices], BB_FALSE
devSpecDone:

	; Common initialization

	call	PowerInit

	clc						;no error
	ret

IdlePowerInit	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerExit

DESCRIPTION:	Exit the driver

CALLED BY:	IdlePowerStrategy (DR_EXIT)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
IdlePowerExit	proc	near

	; Comon exit code

	call	PowerExit

	; Device specific exit code

	ret

IdlePowerExit	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerSuspend

DESCRIPTION:	Suspend our control of the power-management

CALLED BY:	IdlePowerStrategy (DR_SUSPEND)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)
	cx:dx - buffer for error message if suspend refused

RETURN:
	none

DESTROYED:
	ax, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/22/93		Initial version

------------------------------------------------------------------------------@
IdlePowerSuspend	proc	near	uses ax, bx, cx, dx, si, bp
	.enter

	; The common method for suspending/unsuspending the driver is to
	; do the same thing as init/exit

	call	IdlePowerExit

	.leave
	ret

IdlePowerSuspend	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerUnsuspend

DESCRIPTION:	IdlePowerStrategy (DR_UNSUSPEND)

CALLED BY:	INTERNAL

PASS:
	ds, es - dgroup (from IdlePowerStrategy)

RETURN:
	none

DESTROYED:
	ax, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/22/93		Initial version

------------------------------------------------------------------------------@
IdlePowerUnsuspend	proc	near	uses ax, bx, cx, dx, si, bp
	.enter

	; The common method for suspending/unsuspending the driver is to
	; do the same thing as init/exit

	call	IdlePowerInit

	.leave
	ret

IdlePowerUnsuspend	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerIdle

DESCRIPTION:	Called during the idle (dispatch) loop when there are no
		runnable threads.  The CPU can be turned off until the next
		IRQ happens.

CALLED BY:	IdlePowerStrategy (DR_POWER_IDLE)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)

RETURN:
	none

DESTROYED:
	di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MeyerK	12/07/25	Initial version

------------------------------------------------------------------------------@
IdlePowerIdle     proc    near
	.enter

	sti		; allow wake events
	int	28h	; optional: DOS idle hint for TSRs
	hlt		; sleep until next interrupt

	.leave
	ret
IdlePowerIdle     endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerNotIdle

DESCRIPTION:	Called when an interrupt occurs and GEOS is in the idle state.
		Drivers that slow (rather than stop) the clock on
		DR_POWER_IDLE should speed it up again on DR_POWER_NOT_IDLE.

CALLED BY:	IdlePowerStrategy (DR_POWER_NOT_IDLE)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)

RETURN:
	none

DESTROYED:
	di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
IdlePowerNotIdle	proc	near
	.enter

	.leave
	ret

IdlePowerNotIdle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerNotIdleOnInterruptCompletion

DESCRIPTION:	Called when a thread has been woken up (usually as the result
		of an IRQ).  If the CPU has been halted in the DR_POWER_IDLE
		call, this provides notification that the CPU should not be
		idle when the interrupt completes. (Generally meaning that
		there is now a runnable thread.)

CALLED BY:	IdlePowerStrategy (DR_POWER_NOT_IDLE_ON_INTERRUPT_COMPLETION)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)

RETURN:
	none

DESTROYED:
	di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
IdlePowerNotIdleOnInterruptCompletion	proc	near
	.enter

	.leave
	ret

IdlePowerNotIdleOnInterruptCompletion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerLongTermIdle

DESCRIPTION:	Called when the screen saver is about to be invoked, meaning
		that the user has done nothing for the screen saver idle time
		(typically one to five minutes).

CALLED BY:	IdlePowerStrategy (DR_POWER_LONG_TERM_IDLE)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)

RETURN:
	carry - set if machine has been turned off and has been awakened
		by new user activity (this causes the screen saver to be
		bypassed).

DESTROYED:
	di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
IdlePowerLongTermIdle	proc	near
	.enter

	; we return with carry clear as we DON'T want any special treatment for
	; the screen saver. The screen saver DOES increase processor load tho
	; and maybe it would be a good idea to handle it differently...
	clc

	.leave
	ret

IdlePowerLongTermIdle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerGetStatus

DESCRIPTION:	Return power management status

CALLED BY:	IdlePowerStrategy (DR_POWER_GET_STATUS)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)
	ax - PowerGetStatusType

RETURN:
	carry set if error (not supported)
	ax, bx, cx, dx - return value based on PowerGetStatusType

DESTROYED:
	di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
IdlePowerGetStatus	proc	near
	.enter

	; *** This code is for demonstration and testing

	cmp	ax, PGST_POWER_ON_WARNINGS
	jnz	notPowerOn

	mov	ax, 0				;return no warnings
	mov	bx, mask PowerWarnings or mask PW_IDLE_POWER_CUSTOM_WARNING
	jmp	doneGood

notPowerOn:
	cmp	ax, PGST_POLL_WARNINGS
	stc
	jnz	notPoll

	mov	ax, 0				;return no warnings
	mov	bx, mask PowerWarnings or mask PW_IDLE_POWER_CUSTOM_WARNING
	jmp	doneGood

notPoll:
	cmp	ax, PGST_STATUS
	stc
	jnz	done
	clr	ax, bx				;bx <- no PowerStatus supported
doneGood:
	clc
done:
	.leave
	ret

IdlePowerGetStatus	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerSetStatus

DESCRIPTION:	Set the power management status

CALLED BY:	IdlePowerStrategy (DR_POWER_SET_STATUS)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)
	bx - PowerSetStatusType
	dx:ax - value to set based on PowerSetStatusType

RETURN:
	carry set if error (not supported)

DESTROYED:
	di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
IdlePowerSetStatus	proc	near
	.enter

	;WARNING IDLE_POWER_DRIVER_UNSUPPORTED_FUNCTION
	stc

	.leave
	ret

IdlePowerSetStatus	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerDeviceOnOff

DESCRIPTION:	Called when a device is going to be used or is finished
		being used.

CALLED BY:	IdlePowerStrategy (DR_POWER_DEVICE_ON_OFF)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)
	ax - PowerDeviceType
	bx - unit number
	cx - non-zero if turning on device, zero if turning off

RETURN:
	none

DESTROYED:
	di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@

IdlePowerDeviceOnOff	proc	near	uses si, di, bp
	.enter

	clc			;Return no error

	.leave
	ret

IdlePowerDeviceOnOff	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerSetPassword

DESCRIPTION:	Set the BIOS password (if the BIOS supports a password).

CALLED BY:	IdlePowerStrategy (DR_POWER_SET_PASSWORD)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)
	cx:dx - password (size BIOS_PASSWORD_SIZE)

RETURN:
	carry - set if error (function not supported)

DESTROYED:
	di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
IdlePowerSetPassword	proc	near
	.enter

	;WARNING IDLE_POWER_DRIVER_UNSUPPORTED_FUNCTION
	stc

	.leave
	ret

IdlePowerSetPassword	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IdlePowerVerifyPassword

DESCRIPTION:	Verify the BIOS password (if the BIOS supports a password).

CALLED BY:	IdlePowerStrategy (DR_POWER_VERIFY_PASSWORD)

PASS:
	ds, es - dgroup (from IdlePowerStrategy)
	cx:dx - password to verify (size BIOS_PASSWORD_SIZE)

RETURN:
	carry - set if error (function not supported)
	ax - non-zero if passwords do not match

DESTROYED:
	di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/31/92		Initial version

------------------------------------------------------------------------------@
IdlePowerVerifyPassword	proc	near
	.enter

	;WARNING IDLE_POWER_DRIVER_UNSUPPORTED_FUNCTION
	stc

	.leave
	ret

IdlePowerVerifyPassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdlePowerRegisterPowerOnOffNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing.

CALLED BY:	IdlePowerStrategy (DR_POWER_ON_OFF_NOTIFY)

PASS:		dx:cx = fptr to call back routine

		Routine called:
			PASS:
			ax = PowerNotifyChange

RETURN:		carry set if too many routines already registered
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdlePowerRegisterPowerOnOffNotify	proc	near
		.enter

		;WARNING IDLE_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
IdlePowerRegisterPowerOnOffNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdlePowerDisablePassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing

CALLED BY:	PowerStrategy (DR_POWER_DISABLE_PASSWORD_OLD)

PASS:		undocumented in powerDr.def, sadly
RETURN:
DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdlePowerDisablePassword	proc	near
		.enter

		;WARNING IDLE_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
IdlePowerDisablePassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdlePowerRTCAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing.

CALLED BY:	PowerStrategy (DR_POWER_RTC_ACK_OLD)

PASS:		undocumented in powerDr.def, unfortunately
RETURN:
DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdlePowerRTCAck	proc	near
		.enter

		;WARNING IDLE_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
IdlePowerRTCAck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdlePowerOnOffUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing

CALLED BY:	PowerStrategy (DR_POWER_ON_OFF_UNREGISTER)

PASS:		dx:cx = fptr to call back routine

RETURN:		carry set if no such routine existed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdlePowerOnOffUnregister	proc	near
		.enter

		;WARNING IDLE_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
IdlePowerOnOffUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdlePowerEscCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing.

CALLED BY:	PowerStrategy (DR_POWER_ESC_COMMAND)

PASS:
		si	-> PowerEscCommand to execute
		others	-> as command

RETURN:		carry set if EscCommand not supported

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdlePowerEscCommand	proc	near
		.enter

		;WARNING IDLE_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
IdlePowerEscCommand	endp


Resident ends
