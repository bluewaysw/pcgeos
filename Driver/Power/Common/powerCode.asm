COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Common power management code
FILE:		powerCode.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/22/93		Initial revision

DESCRIPTION:
	This is common battery code

	$Id: powerCode.asm,v 1.1 97/04/18 11:48:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	PowerInit

DESCRIPTION:	Common initialization

CALLED BY:	INTERNAL

PASS:
	ds, es - dgroup

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
	Tony	4/22/93		Initial version

------------------------------------------------------------------------------@

PowerInit	proc	near

if	POLL_BATTERY

	; Install a timer so that we can poll some battery related stuff...

	mov	al, TIMER_ROUTINE_CONTINUAL
	mov	bx, cs
	mov	si, offset BatteryPoll
	mov	cx, BATTERY_POLL_INITIAL_WAIT
	mov	di, BATTERY_POLL_INTERVAL
	call	TimerStart
	mov	ds:[timerHandle], bx
	mov	ds:[timerID], ax

endif

if 	PCMCIA_SUPPORT
	;
	; Attempt to load the pcmcia library.
	;
	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath

	mov	ax, high pcmcia
	mov	bx, low pcmcia
	mov	si, offset pcmciaLibName
	push	ds
	segmov	ds, cs
	call	GeodeUseLibrary
	pop	ds
	call	FilePopDir
	jc	pcmciaDone
	
	mov	ds:[pcmciaLib], bx
pcmciaDone:
endif

	mov	cx, vseg PowerDeviceNotification
	mov	dx, offset PowerDeviceNotification
	mov	si, SST_DEVICE_POWER
	call	SysHookNotification

	ret

PowerInit	endp

if	PCMCIA_SUPPORT
EC <pcmciaLibName	TCHAR	'PCMCIAEC.GEO', 0>
NEC<pcmciaLibName	TCHAR	'PCMCIA.GEO', 0>
endif	; PCMCIA_SUPPORT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PowerDeviceNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the power driver's strategy routine to turn power
		on or off for a device.

CALLED BY:	(GLOBAL) SysSendNotification
PASS:		ax, bx, cx, dx	= for DR_POWER_DEVICE_ON_OFF call
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	none here

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/21/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PowerDeviceNotification proc	far
		.enter
		mov	di, DR_POWER_DEVICE_ON_OFF
		call	PowerStrategy
		.leave
		ret
PowerDeviceNotification endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	PowerExit

DESCRIPTION:	Common exit code

CALLED BY:	INTERNAL

PASS:
	ds, es - dgroup

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
	Tony	4/22/93		Initial version

------------------------------------------------------------------------------@

PowerExit	proc	near

if	POLL_BATTERY

	mov	bx, ds:[timerHandle]
	mov	ax, ds:[timerID]
	call	TimerStop

endif

if	PCMCIA_SUPPORT
	clr	bx
	xchg	bx, ds:[pcmciaLib]
	tst	bx
	jz	pcmciaDone
	
	mov	ax, enum PCMCIADetach
	push	bx
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	pop	bx
	
;;; Do not attempt to free the library, as this will cause a call to GLoad
;;; (NotifyNewLibraries) in the kernel, which we're not allowed to do here.
;;;	call	GeodeFreeLibrary
pcmciaDone:
endif	; PCMCIA_SUPPORT

	;
	; we never unhook the SST_DEVICE_POWER notification because
	; the requisite routine is in movable memory and cannot be called
	; from the exit routine of a system driver. It does no harm to
	; leave ourselves connected to it, in any case, as no one will call
	;
	ret

PowerExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PowerDeviceOnOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for fielding device on/off calls

CALLED BY:	(EXTERNAL)
PASS:		ax	= PowerDeviceType
		bx	= unit number
		cx	= non-zero if turning on device, zero if turning off
		dx	= device-specific data
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	PCMCIA library called if loaded and type is PDT_PCMCIA_SOCKET

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/21/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PowerDeviceOnOff proc	near
		.enter
if 	PCMCIA_SUPPORT
		cmp	ax, PDT_PCMCIA_SOCKET
		jne	done
	;
	; Is for pcmcia socket. Call the library if we loaded it.
	;
		push	bx, bp
		mov	bx, ds:[pcmciaLib]
		tst	bx
		jz	noLib
	;
	; Fetch device on/off routine address from the library.
	;
		mov	ax, enum PCMCIADeviceOnOff
		call	ProcGetLibraryEntry
	;
	; Store it on the stack for PCFOM_P and call the thing.
	;
		mov	bp, sp
		xchg	bx, ss:[bp+2]
		pop	bp
		push	ax
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; Restore AX for caller...
	;
		mov	ax, PDT_PCMCIA_SOCKET
		jmp	done
noLib:
		pop	bx, bp
done:
endif
		.leave
		ret
PowerDeviceOnOff endp



Resident ends
