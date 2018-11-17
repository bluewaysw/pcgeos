COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		NoPower power management driver
FILE:		nopower.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/92		Initial version

DESCRIPTION:
	This is a power management driver that does nothing special.  It
	is intended as a template for power management drivers and as a
	test for common functionality.

RCS STAMP:
	$Id: nopower.asm,v 1.1 97/04/18 11:48:16 newdeal Exp $

------------------------------------------------------------------------------@

include geos.def
include heap.def
include lmem.def		; for extended driver info segment
include geode.def
include resource.def
include	ec.def

include Internal/heapInt.def	; for ProcCallFixedOrMovable defs.

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

POLL_BATTERY	=	-1
DISPLAY_MESSAGES =	-1
PCMCIA_SUPPORT	equ	-1		; attempt pcmcia support, please

NUMBER_OF_CUSTOM_POWER_WARNINGS = 1
PW_NO_POWER_SAMPLE_CUSTOM_WARNING	equ	<PW_CUSTOM_1>

BATTERY_POLL_INITIAL_WAIT =	30*60	; 30 seconds
BATTERY_POLL_INTERVAL =	4*60		; 4 seconds

NO_POWER_DRIVER_UNSUPPORTED_FUNCTION	enum	Warnings

PowerStrategy	equ	<NoPowerStrategy>

NEEDS_SERIAL_PASSIVE	= 1	; Sets SERIAL_PASSIVE in powerConstants.def
include powerGeode.def

include nopowerStrings.asm

;------------------------------------------------------------------------------
;		Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;		Driver Information structure
;------------------------------------------------------------------------------

idata segment

DriverTable	DriverInfoStruct <
	NoPowerStrategy,
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

comPortsOpen	word	4 dup(?)
comPPortsOpen	word	4 dup(?)
lptPortsOpen	word	4 dup(?)

udata	ends

;------------------------------------------------------------------------------
;		Code
;------------------------------------------------------------------------------

; This is for testing and demonstration purposes

Resident segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerStrategy

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
NoPowerStrategy	proc	far	uses ds, es
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

NoPowerStrategy	endp

functions	nptr	\
	NoPowerInit,
	NoPowerExit,
	NoPowerSuspend,
	NoPowerUnsuspend,
	NoPowerIdle,
	NoPowerNotIdle,
	NoPowerNotIdleOnInterruptCompletion,
	NoPowerLongTermIdle,
	NoPowerGetStatus,
	NoPowerSetStatus,
	NoPowerDeviceOnOff,
	NoPowerSetPassword,
	NoPowerVerifyPassword,
	NoPowerRegisterPowerOnOffNotify,
	NoPowerDisablePassword,
	NoPowerRTCAck,
	NoPowerOnOffUnregister,
	NoPowerEscCommand

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerInit

DESCRIPTION:	Initialize the driver

CALLED BY:	NoPowerStrategy (DR_INIT)

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

NoPowerInit	proc	near

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

NoPowerInit	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerExit

DESCRIPTION:	Exit the driver

CALLED BY:	NoPowerStrategy (DR_EXIT)

PASS:
	ds, es - dgroup (from NoPowerStrategy)

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
NoPowerExit	proc	near

	; Comon exit code

	call	PowerExit

	; Device specific exit code

	ret

NoPowerExit	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerSuspend

DESCRIPTION:	Suspend our control of the power-management

CALLED BY:	NoPowerStrategy (DR_SUSPEND)

PASS:
	ds, es - dgroup (from NoPowerStrategy)
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
NoPowerSuspend	proc	near	uses ax, bx, cx, dx, si, bp
	.enter

	; The common method for suspending/unsuspending the driver is to
	; do the same thing as init/exit

	call	NoPowerExit

	.leave
	ret

NoPowerSuspend	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerUnsuspend

DESCRIPTION:	NoPowerStrategy (DR_UNSUSPEND)

CALLED BY:	INTERNAL

PASS:
	ds, es - dgroup (from NoPowerStrategy)

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
NoPowerUnsuspend	proc	near	uses ax, bx, cx, dx, si, bp
	.enter

	; The common method for suspending/unsuspending the driver is to
	; do the same thing as init/exit

	call	NoPowerInit

	.leave
	ret

NoPowerUnsuspend	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerIdle

DESCRIPTION:	Called during the idle (dispatch) loop when there are no
		runnable threads.  The CPU can be turned off until the next
		IRQ happens.

CALLED BY:	NoPowerStrategy (DR_POWER_IDLE)

PASS:
	ds, es - dgroup (from NoPowerStrategy)

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
NoPowerIdle	proc	near
	.enter

	.leave
	ret

NoPowerIdle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerNotIdle

DESCRIPTION:	Called when an interrupt occurs and GEOS is in the idle state.
		Drivers that slow (rather than stop) the clock on
		DR_POWER_IDLE should speed it up again on DR_POWER_NOT_IDLE.

CALLED BY:	NoPowerStrategy (DR_POWER_NOT_IDLE)

PASS:
	ds, es - dgroup (from NoPowerStrategy)

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
NoPowerNotIdle	proc	near
	.enter

	.leave
	ret

NoPowerNotIdle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerNotIdleOnInterruptCompletion

DESCRIPTION:	Called when a thread has been woken up (usually as the result
		of an IRQ).  If the CPU has been halted in the DR_POWER_IDLE
		call, this provides notification that the CPU should not be
		idle when the interrupt completes. (Generally meaning that
		there is now a runnable thread.)

CALLED BY:	NoPowerStrategy (DR_POWER_NOT_IDLE_ON_INTERRUPT_COMPLETION)

PASS:
	ds, es - dgroup (from NoPowerStrategy)

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
NoPowerNotIdleOnInterruptCompletion	proc	near
	.enter

	.leave
	ret

NoPowerNotIdleOnInterruptCompletion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerLongTermIdle

DESCRIPTION:	Called when the screen saver is about to be invoked, meaning
		that the user has done nothing for the screen saver idle time
		(typically one to five minutes).

CALLED BY:	NoPowerStrategy (DR_POWER_LONG_TERM_IDLE)

PASS:
	ds, es - dgroup (from NoPowerStrategy)

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
NoPowerLongTermIdle	proc	near
	.enter

	; *** This code is for demonstration and testing

	push	ax, bx, di
	mov	ax, SGIT_UI_PROCESS
	call	SysGetInfo			;ax = ui handle
	mov_tr	bx, ax

	mov	ax, MSG_USER_PROMPT_FOR_PASSWORD
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	ax, bx, di

	stc

	.leave
	ret

NoPowerLongTermIdle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerGetStatus

DESCRIPTION:	Return power management status

CALLED BY:	NoPowerStrategy (DR_POWER_GET_STATUS)

PASS:
	ds, es - dgroup (from NoPowerStrategy)
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
NoPowerGetStatus	proc	near
	.enter

	; *** This code is for demonstration and testing

	cmp	ax, PGST_POWER_ON_WARNINGS
	jnz	notPowerOn

	mov	ax, 0				;return no warnings
	mov	bx, mask PowerWarnings or mask PW_NO_POWER_SAMPLE_CUSTOM_WARNING
	jmp	doneGood

notPowerOn:
	cmp	ax, PGST_POLL_WARNINGS
	stc
	jnz	notPoll

	mov	ax, 0				;return no warnings
	mov	bx, mask PowerWarnings or mask PW_NO_POWER_SAMPLE_CUSTOM_WARNING
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

NoPowerGetStatus	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerSetStatus

DESCRIPTION:	Set the power management status

CALLED BY:	NoPowerStrategy (DR_POWER_SET_STATUS)

PASS:
	ds, es - dgroup (from NoPowerStrategy)
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
NoPowerSetStatus	proc	near
	.enter

	stc

	.leave
	ret

NoPowerSetStatus	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerDeviceOnOff

DESCRIPTION:	Called when a device is going to be used or is finished
		being used.

CALLED BY:	NoPowerStrategy (DR_POWER_DEVICE_ON_OFF)

PASS:
	ds, es - dgroup (from NoPowerStrategy)
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

NoPowerDeviceOnOff	proc	near	uses si, di, bp
	.enter

	; handle PCMCIA stuff first.

	call	PowerDeviceOnOff

	; *** This code is for demonstration and testing

	tst	ds:[notifyAboutDevices]
	jz	done

	cmp	ax, PDT_PARALLEL_PORT		; Catch LPT1 being opened
	jnz	notParallel
	mov	si, offset OpenLPT1String
	mov	bp, offset lptPortsOpen
	jmp	displayString

notParallel:
	cmp	ax, PDT_SERIAL_PORT		; Catch COM2 being opened
	jnz	notSerial

	;
	; We don't yet handle passive serial ports.  When we do, nuke the three
	; following lines.
	;
EC  <	test	bx, SERIAL_PASSIVE					>
EC  <	ERROR_NZ PASSIVE_SERIAL_PORTS_NOT_SUPPORTED			>
NEC <	and	bx, not SERIAL_PASSIVE					>

	mov	bp, offset comPortsOpen
	mov	si, offset OpenCOM1String
	test	bx, SERIAL_PASSIVE
	jz	computeSerialString
	mov	bp, offset comPPortsOpen
	mov	si, offset OpenPCOM1String
computeSerialString:
	and	bx, not SERIAL_PASSIVE

displayString:
	shl	bx
	add	si, bx				; correct string => SI
	add	bx, bp
	mov	ax, cx
	xchg	ds:[bx], ax
	jcxz	done				; if turning off, do nothing
	tst	ax
	jnz	done				; was on before, so do nothing
	mov	di, vseg DisplayMessage
	mov	bp, offset DisplayMessage
	mov	ax, mask CDBF_SYSTEM_MODAL or \
			(CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	CallRoutineInUI
notSerial:

done:
	clc			;Return no error
	.leave
	ret

NoPowerDeviceOnOff	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerSetPassword

DESCRIPTION:	Set the BIOS password (if the BIOS supports a password).

CALLED BY:	NoPowerStrategy (DR_POWER_SET_PASSWORD)

PASS:
	ds, es - dgroup (from NoPowerStrategy)
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
NoPowerSetPassword	proc	near
	.enter

	stc

	.leave
	ret

NoPowerSetPassword	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NoPowerVerifyPassword

DESCRIPTION:	Verify the BIOS password (if the BIOS supports a password).

CALLED BY:	NoPowerStrategy (DR_POWER_VERIFY_PASSWORD)

PASS:
	ds, es - dgroup (from NoPowerStrategy)
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
NoPowerVerifyPassword	proc	near
	.enter

	stc

	.leave
	ret

NoPowerVerifyPassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoPowerRegisterPowerOnOffNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing.

CALLED BY:	NoPowerStrategy (DR_POWER_ON_OFF_NOTIFY)

PASS:	dx:cx = fptr to call back routine

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
NoPowerRegisterPowerOnOffNotify	proc	near
		.enter

		WARNING NO_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
NoPowerRegisterPowerOnOffNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoPowerDisablePassword
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
NoPowerDisablePassword	proc	near
		.enter

		WARNING NO_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
NoPowerDisablePassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoPowerRTCAck
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
NoPowerRTCAck	proc	near
		.enter

		WARNING NO_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
NoPowerRTCAck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoPowerOnOffUnregister
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
NoPowerOnOffUnregister	proc	near
		.enter

		WARNING NO_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
NoPowerOnOffUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoPowerEscCommand
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
NoPowerEscCommand	proc	near
		.enter

		WARNING NO_POWER_DRIVER_UNSUPPORTED_FUNCTION
		stc

		.leave
		ret
NoPowerEscCommand	endp


Resident ends
