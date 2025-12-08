COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		HLT Power Management Driver
FILE:		hltpwr.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/92		Initial version of NoPower
	MeyerK	12/25		Initial version of hltpwr, based on NoPower

DESCRIPTION:
	This power management driver puts the processor on HLT whenever
	GEOS is idle. This reduces the amount of power drawn. Less cooling is
	needed, and fan noise is significantly reduced on modern systems
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
PW_HLT_POWER_CUSTOM_WARNING	equ	<PW_CUSTOM_1>
HLT_POWER_DRIVER_UNSUPPORTED_FUNCTION	enum	Warnings

POLL_BATTERY			=	FALSE
BATTERY_POLL_INITIAL_WAIT 	=	30*60	; 30 seconds
BATTERY_POLL_INTERVAL 		=	4*60	; 4 seconds

PowerStrategy			equ	<HLTPowerStrategy>

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
	HLTPowerStrategy,
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

FUNCTION:	HLTPowerStrategy

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
HLTPowerStrategy	proc	far	uses ds, es
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

HLTPowerStrategy	endp

functions	nptr	\
	HLTPowerInit,
	HLTPowerExit,
	HLTPowerSuspend,
	HLTPowerUnsuspend,
	HLTPowerIdle,
	HLTPowerNotIdle,
	HLTPowerNotIdleOnInterruptCompletion,
	HLTPowerLongTermIdle,
	HLTPowerGetStatus,
	HLTPowerSetStatus,
	HLTPowerDeviceOnOff,
	HLTPowerSetPassword,
	HLTPowerVerifyPassword,
	HLTPowerRegisterPowerOnOffNotify,
	HLTPowerDisablePassword,
	HLTPowerRTCAck,
	HLTPowerOnOffUnregister,
	HLTPowerEscCommand

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerInit

DESCRIPTION:	Initialize the driver

CALLED BY:	HLTPowerStrategy (DR_INIT)

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

HLTPowerInit	proc	near

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

HLTPowerInit	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerExit

DESCRIPTION:	Exit the driver

CALLED BY:	HLTPowerStrategy (DR_EXIT)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)

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
HLTPowerExit	proc	near

	; Comon exit code

	call	PowerExit

	; Device specific exit code

	ret

HLTPowerExit	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerSuspend

DESCRIPTION:	Suspend our control of the power-management

CALLED BY:	HLTPowerStrategy (DR_SUSPEND)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)
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
HLTPowerSuspend	proc	near	uses ax, bx, cx, dx, si, bp
	.enter

	; The common method for suspending/unsuspending the driver is to
	; do the same thing as init/exit

	call	HLTPowerExit

	.leave
	ret

HLTPowerSuspend	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerUnsuspend

DESCRIPTION:	HLTPowerStrategy (DR_UNSUSPEND)

CALLED BY:	INTERNAL

PASS:
	ds, es - dgroup (from HLTPowerStrategy)

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
HLTPowerUnsuspend	proc	near	uses ax, bx, cx, dx, si, bp
	.enter

	; The common method for suspending/unsuspending the driver is to
	; do the same thing as init/exit

	call	HLTPowerInit

	.leave
	ret

HLTPowerUnsuspend	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerIdle

DESCRIPTION:	Called during the idle (dispatch) loop when there are no
		runnable threads.  The CPU can be turned off until the next
		IRQ happens.

CALLED BY:	HLTPowerStrategy (DR_POWER_IDLE)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)

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
HLTPowerIdle     proc    near
	.enter

	sti		; allow wake events
	int	28h	; optional: DOS idle hint for TSRs
	hlt		; sleep until next interrupt

	.leave
	ret
HLTPowerIdle     endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerNotIdle

DESCRIPTION:	Called when an interrupt occurs and GEOS is in the idle state.
		Drivers that slow (rather than stop) the clock on
		DR_POWER_IDLE should speed it up again on DR_POWER_NOT_IDLE.

CALLED BY:	HLTPowerStrategy (DR_POWER_NOT_IDLE)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)

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
HLTPowerNotIdle	proc	near
	.enter

	.leave
	ret

HLTPowerNotIdle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerNotIdleOnInterruptCompletion

DESCRIPTION:	Called when a thread has been woken up (usually as the result
		of an IRQ).  If the CPU has been halted in the DR_POWER_IDLE
		call, this provides notification that the CPU should not be
		idle when the interrupt completes. (Generally meaning that
		there is now a runnable thread.)

CALLED BY:	HLTPowerStrategy (DR_POWER_NOT_IDLE_ON_INTERRUPT_COMPLETION)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)

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
HLTPowerNotIdleOnInterruptCompletion	proc	near
	.enter

	.leave
	ret

HLTPowerNotIdleOnInterruptCompletion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerLongTermIdle

DESCRIPTION:	Called when the screen saver is about to be invoked, meaning
		that the user has done nothing for the screen saver idle time
		(typically one to five minutes).

CALLED BY:	HLTPowerStrategy (DR_POWER_LONG_TERM_IDLE)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)

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
HLTPowerLongTermIdle	proc	near
	.enter

	; we return with carry clear as we DON'T want any special treatment for
	; the screen saver. The screen saver DOES increase processor load tho
	; and maybe it would be a good idea to handle it differently...
	clc

	.leave
	ret

HLTPowerLongTermIdle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerGetStatus

DESCRIPTION:	Return power management status

CALLED BY:	HLTPowerStrategy (DR_POWER_GET_STATUS)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)
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
HLTPowerGetStatus	proc	near
	.enter

	; *** This code is for demonstration and testing

	cmp	ax, PGST_POWER_ON_WARNINGS
	jnz	notPowerOn

	mov	ax, 0				;return no warnings
	mov	bx, mask PowerWarnings or mask PW_HLT_POWER_CUSTOM_WARNING
	jmp	doneGood

notPowerOn:
	cmp	ax, PGST_POLL_WARNINGS
	stc
	jnz	notPoll

	mov	ax, 0				;return no warnings
	mov	bx, mask PowerWarnings or mask PW_HLT_POWER_CUSTOM_WARNING
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

HLTPowerGetStatus	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerSetStatus

DESCRIPTION:	Set the power management status

CALLED BY:	HLTPowerStrategy (DR_POWER_SET_STATUS)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)
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
HLTPowerSetStatus	proc	near
	.enter

	;WARNING HLT_POWER_DRIVER_UNSUPPORTED_FUNCTION
	stc

	.leave
	ret

HLTPowerSetStatus	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerDeviceOnOff

DESCRIPTION:	Called when a device is going to be used or is finished
		being used.

CALLED BY:	HLTPowerStrategy (DR_POWER_DEVICE_ON_OFF)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)
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

HLTPowerDeviceOnOff	proc	near	uses si, di, bp
	.enter

	clc			;Return no error

	.leave
	ret

HLTPowerDeviceOnOff	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerSetPassword

DESCRIPTION:	Set the BIOS password (if the BIOS supports a password).

CALLED BY:	HLTPowerStrategy (DR_POWER_SET_PASSWORD)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)
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
HLTPowerSetPassword	proc	near
	.enter

	;WARNING HLT_POWER_DRIVER_UNSUPPORTED_FUNCTION
	stc

	.leave
	ret

HLTPowerSetPassword	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HLTPowerVerifyPassword

DESCRIPTION:	Verify the BIOS password (if the BIOS supports a password).

CALLED BY:	HLTPowerStrategy (DR_POWER_VERIFY_PASSWORD)

PASS:
	ds, es - dgroup (from HLTPowerStrategy)
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
HLTPowerVerifyPassword	proc	near
	.enter

	;WARNING HLT_POWER_DRIVER_UNSUPPORTED_FUNCTION
	stc

	.leave
	ret

HLTPowerVerifyPassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HLTPowerRegisterPowerOnOffNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing.

CALLED BY:	HLTPowerStrategy (DR_POWER_ON_OFF_NOTIFY)

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
HLTPowerRegisterPowerOnOffNotify	proc	near
		.enter

		;WARNING HLT_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
HLTPowerRegisterPowerOnOffNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HLTPowerDisablePassword
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
HLTPowerDisablePassword	proc	near
		.enter

		;WARNING HLT_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
HLTPowerDisablePassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HLTPowerRTCAck
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
HLTPowerRTCAck	proc	near
		.enter

		;WARNING HLT_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
HLTPowerRTCAck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HLTPowerOnOffUnregister
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
HLTPowerOnOffUnregister	proc	near
		.enter

		;WARNING HLT_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
HLTPowerOnOffUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HLTPowerEscCommand
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
HLTPowerEscCommand	proc	near
		.enter

		;WARNING HLT_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
HLTPowerEscCommand	endp


Resident ends
