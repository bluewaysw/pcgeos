COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Breadbox Computer 1995 -- All Rights Reserved

PROJECT:	Breadbox Home Automation
MODULE:	X-10 Power Code Driver
FILE:		x10strat.asm

AUTHOR:		Fred Goya

ROUTINES:
	Name					Description
	----					-----------
	X10Strategy			The strategy for the driver
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		dgroup DATA
;-----------------------------------------------------------------------------
idata	segment

DriverTable	DriverInfoStruct <
		X10Strategy,
		0,
		DRIVER_TYPE_OUTPUT>

idata	ends


;-----------------------------------------------------------------------------
;		STRATEGY ROUTINE FOR X10 DRIVER
;-----------------------------------------------------------------------------

ResidentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Strategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the correct driver function when passed a legal
            command.

CALLED BY:	External

PASS:		di	-> command

RETURN:		see routines

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		The command is passed in di.  Look up the near pointer
		to the routine that handles that command in a jump table
		and jump to it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Strategy	proc	far
	push	ds

	push	di								; save command
	mov	di, segment dgroup		; di <- dgroup of driver
	mov	ds, di						; ds <- dgroup of driver
	pop	di								; restore command
	cmp	di, 8
	jne	doCommand					; allows us to change settings when debugging.
	tst	ds:[basePortAddress]		; if this is zero, it means we're debugging,
	jz		done							; and don't want to actually send commands.
doCommand:
	call	cs:routineJumpTable[di]
done:
	pop	ds
	ret
X10Strategy	endp

routineJumpTable nptr	X10InitNear,			; DR_INIT
			X10ExitDriverNear,                  ; DR_EXIT
			X10SuspendNear,                     ; DR_SUSPEND
			X10UnsuspendNear,                   ; DR_UNSUSPEND
			X10SendNear,								; DR_POWERCODE_SEND_COMMAND
			X10ChangePortNear,                  ; DR_POWERCODE_CHANGE_PORT
			X10ChangeSettingsNear               ; DR_POWERCODE_CHANGE_SETTINGS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10...Near
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A near routine to make a far call through

CALLED BY:	Strategy Routine
PASS:		<see routine>
RETURN:		<see routine>
DESTROYED:	nothing
SIDE EFFECTS:
		<see routine>

PSEUDO CODE/STRATEGY:
		There are a couple of routines which don't need
		to remain resident at all times.  There are many
		way to call such routines, but to make calling
		the other routines as fast as possible (and the
		other routines are time-critical rouines that
		get called at interrupt time...), we do near
		calls to everything.

		Since some of the routines are not in this code
		segment, however, we are actualy doing near
		calls to routines which to Far calls to the
		routines.

		Get it?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10InitNear	proc	near
	call	X10Init
	ret
X10InitNear	endp

X10ExitDriverNear	proc	near
	call	X10ExitDriver
	ret
X10ExitDriverNear	endp

X10SuspendNear		proc	near
	call	X10Suspend
	ret
X10SuspendNear		endp

X10UnsuspendNear	proc	near
	call	X10Unsuspend
	ret
X10UnsuspendNear	endp

X10SendNear proc	near
	call X10Send
	ret
X10SendNear endp

X10ChangePortNear	proc	near
	call	X10ChangePort
	ret
X10ChangePortNear	endp

X10ChangeSettingsNear	proc	near
	call	X10ChangeSettings
	ret
X10ChangeSettingsNear	endp

ResidentCode		ends


