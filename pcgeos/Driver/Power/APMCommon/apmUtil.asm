COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Power Drivers
FILE:		apmUtil.asm

AUTHOR:		Todd Stumpf, Aug  1, 1994

ROUTINES:
	Name			Description
	----			-----------
	APMGetStatusACLine	Is AC Adapter Connected?
	APMGetStatusBattery	What is Battery Status?
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94   	Initial revision

DESCRIPTION:
	This file contains the default routines for determining if
	the AC adapter is connected to the system, and what the current
	battery level is.

	$Id: apmUtil.asm,v 1.1 97/04/18 11:48:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetStatusACLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if we are hooked up to AC power source

CALLED BY:	APMGetStatus

PASS:		ds	-> dgroup

RETURN:		ax	<- PowerStatus
		bx	<- PowerStatus supprted

DESTROYED:	nothing

SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/27/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	USE_DEFAULT_AC_ADAPTER_CODE
APMGetStatusACLine	proc	far
	.enter
	mov	bx, APMDID_ALL_BIOS_DEVICES

	call	SysLockBIOS
	CallAPM	APMSC_GET_POWER_STATUS		; bh <- ACLineStatus
	call	SysUnlockBIOS

	clr	ax				; assume it's off or

	cmp	bh, ACLS_UNKNOWN		; is AC detect supported?
	je	unsupported

	cmp	bh, ACLS_ON_LINE		; is AC connected?
	jne	supported

	mov	ax, mask PS_AC_ADAPTER_CONNECTED

supported:
	mov	bx, mask PS_AC_ADAPTER_CONNECTED

	clc
done:
	.leave
	ret

unsupported:
	czr	ax, bx				; nothing supported
	stc
	jmp	short done
APMGetStatusACLine	endp
endif
Resident		ends

Movable			segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetStatusBattery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine % of charge remaining in battery

CALLED BY:	APMGetStatus

PASS:		ds	-> dgroup

RETURN:		dxax	<- % remaining (0-1000)

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/27/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	USE_DEFAULT_BATTERY_LEVEL_CODE
APMGetStatusBattery	proc	far
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
	cmp	cl, -1				; returns -1 if unsuported
	je	done	; => carry clear

	clr	dx					; dxax <- ax
	mov	ch, dl					; cx <- 0-100%

	shl	cx, 1					; cx <- cx * 2
	mov	ax, cx					; ax <- cx * 2
	shl	cx, 1					; cx <- cx * 4
	shl	cx, 1					; cx <- cx * 8
	add	ax, cx					; ax <- cx * 10
	clr	dx					; dxax <- 0-1000

	stc
done:
	cmc
	.leave
	ret
APMGetStatusBattery	endp
endif
Movable				ends

Resident		segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMDisableGPM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable DOS-level (and BIOS-level) global power management.

CALLED BY:	APMInit, APMUnsuspend, APMRecoverFromSuspend
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HAS_DOS_LEVEL_APM
APMDisableGPM	proc	near
	.enter

ifidn	HARDWARE_TYPE, <GPC1>
	;
	; The only DOS-level GPM feature is auto screen blanking by BIOS OEM
	; extension, but the function is not tied to the APM BIOS, so we have
	; to call the BIOS extension instead of using APM calls to disable it.
	;
	pusha
	mov	ax,(BIOS_OEM_EXT_MAJOR_COMMAND shl 8) or BOEF_SET_VIDEO_TIMEOUT
	mov	bl, 0xff		; OFF
	int	BIOS_OEM_EXT_INTERRUPT	; CF set if func not supported, which
					;  can happen on older BIOS versions.
					;  Just ignore it.
	popa
endif	; HARDWARE_TYPE, <GPC1>

	.leave
	ret
APMDisableGPM	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMEnableGPM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable DOS-level (and BIOS-level) global power management.

CALLED BY:	APMExit, APMSuspend
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HAS_DOS_LEVEL_APM
APMEnableGPM	proc	near
	.enter

ifidn	HARDWARE_TYPE, <GPC1>
	;
	; The only DOS-level GPM feature is auto screen blanking by BIOS OEM
	; extension, but the function is not tied to the APM BIOS, so we have
	; to call the BIOS extension instead of using APM calls to enable it.
	;
	pusha
	mov	ax,(BIOS_OEM_EXT_MAJOR_COMMAND shl 8) or BOEF_SET_VIDEO_TIMEOUT
	.assert	DEFAULT_GPM_TIMEOUT * 60 / 16 gt 1	; 0 and 1 are invalid
	.assert	DEFAULT_GPM_TIMEOUT * 60 / 16 lt 0xff	; 0xff means OFF
	mov	bl, DEFAULT_GPM_TIMEOUT * 60 / 16	; # of 16-sec intervals
	int	BIOS_OEM_EXT_INTERRUPT	; CF set if func not supported, which
					;  can happen on older BIOS versions.
					;  Just ignore it.
	popa
endif	; HARDWARE_TYPE, <GPC1>

	.leave
	ret
APMEnableGPM	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMLockBIOSNB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the BIOS lock, only grabbing it if available

CALLED BY:	GLOBAL
PASS:		ds	-> dgroup
RETURN:		c flag set if bios lock owned
			call	CheckBiosLock
			jc 	someoneAlreadyHasBiosLock
		Interrupts enabled
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMLockBIOSNB	proc	near
	uses	ax, si, ds
	.enter
EC<	mov	ax, ds							>
EC<	cmp	ax, segment dgroup					>
EC<	ERROR_NE	-1						>
	pushf

	INT_OFF
	lds	si, ds:[biosLockAddress]	; ds:bx <- biosLock

	cmp	ds:[si].TL_sem.Sem_value, 1
	clc					; assume error
	jne	done	; => return Error

grabIt::
	;
	;  The following butchered code was taken from ThreadLock
	;  (a macro that exists in the kernel).  As this code
	;  will never be called _unless_ we can get the semaphore,
	;  it is much simpler than that particular macro.
	;  It's also probably buggier.  :(
	lock	dec	ds:[si].TL_sem.Sem_value
EC<	ERROR_S	-1	; bad code, eh todd?				>

	mov	ax, ss:[TPD_threadHandle]		; hey, we're a driver!
						;   leave us alone...

	mov	ds:[si].TL_owner, ax
	inc	ds:[si].TL_nesting

	stc					; return success
done:
	lahf						; ah <- normal flags
	call	SafePopf				; restore Ints
	sahf						; restore normal flags
	cmc
	.leave
	ret
APMLockBIOSNB	endp

SafePopf	proc	far
	iret
SafePopf	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMUnlockBIOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Because we Lock BIOS in an odd way, we unlock it oddly

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMUnlockBIOS	proc	near
	uses	ax, bx, si, ds
	.enter

EC<	mov	ax, ds							>
EC<	cmp	ax, segment dgroup					>
EC<	ERROR_NE	-1						>

	lds	si, ds:[biosLockAddress]	; ds:bx <- biosLock

EC<	mov	ax, ss:[TPD_threadHandle]				>
EC<	cmp	ax, ds:[si].TL_owner					>
EC<	ERROR_NE	-1						>

	pushf
	INT_OFF

	dec	ds:[si].TL_nesting
	jg	done

	mov	ds:[si].TL_owner, -1
	lock	inc	ds:[si].TL_sem.Sem_value
	jg	done

wakeAThread::
	mov	ax, ds
	lea	bx, ds:[si].TL_sem.Sem_queue
	call	ThreadWakeUpQueue

done:
	call	SafePopf

	.leave
	ret
APMUnlockBIOS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMEnforceWorldView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make all others believe as we do.

CALLED BY:	APMInit, APMUnsuspend, APMRecoverFromSuspend
PASS:		ds	-> dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Sets power states on all devices to last-known values

PSEUDO CODE/STRATEGY:
		Go through all of our devices and ensure they are
		in the state we have recorded in our dgroup

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMEnforceWorldViewFar	proc	far
	call	APMEnforceWorldView
	ret
APMEnforceWorldViewFar	endp

APMEnforceWorldView	proc	near
	uses	ax, bx, cx, dx, si
	.enter

if	HAS_PARALLEL_PORTS
ifidn	HARDWARE_TYPE, <GPC1>
	; GPC1 APM BIOS doesn't support parallel port, so don't call it.
else
	;
	;  For each parallel port we have, set the power
	;  state to the correct value
	mov	si, offset parallelPowerStatus	; si <- SuspendRestriction
	mov	bx, APMDID_PARALLEL_PORT_LPT1	; bx <- LPT's APM Device ID
	mov	dx, NUM_PARALLEL_PORTS - 1	; dx <- last valid ID
	add	dx, bx

	call	APMSetDeviceCategoryPower	; ax, bx, cx destroyed
endif	; HARDWARE_TYPE, <GPC1>
endif

if	HAS_SERIAL_PORTS
ifidn	HARDWARE_TYPE, <GPC1>
	; GPC1 APM BIOS doesn't support serial ports, so don't call it.
else
	;
	;  Adjust device # and mark serial port as on or off
	mov	si, offset serialPowerStatus	; si <- SuspendRestriction
	mov	bx, APMDID_SERIAL_PORT_COM1	; bx <- APM Device ID #
	mov	dx, NUM_SERIAL_PORTS - 1	; dx <- last valid ID
	add	dx, bx

	call	APMSetDeviceCategoryPower	; ax, bx, cx destroyed
endif	; HARDWARE_TYPE, <GPC1>
endif

if	HAS_DISPLAY_CONTROLS
	;
	;  Adjust the state of the display.
	mov	si, offset displayPowerStatus	; si <- SuspendRestriction
	mov	bx, APMDID_DISPLAY		; bx <- APM Device ID #
	mov	dx, NUM_DISPLAY_CONTROLS - 1	; dx <- last valid ID
	add	dx, bx

	call	APMSetDeviceCategoryPower	; ax, bx, cx destroyed
endif

if	HAS_PCMCIA_PORTS
%out	TODD - Hmmm.  Wonder what we should do here?
endif

	.leave
	ret
APMEnforceWorldView	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMSetDeviceCategoryPower
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a category of devices to specified power state

CALLED BY:	
PASS:		ds	-> dgroup
		bx	-> base DEVICE ID
		si	-> 1st SuspendRestriction for device type
		dx	-> last valid DEVICE ID
RETURN:		nothing
DESTROYED:	ax, bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMSetDeviceCategoryPower	proc	near
	.enter

deviceLoop:
	clr	cx					; cx <- APMS_READY
	test	{byte}ds:[si], mask SR_DEVICE_ON	; is it on?
	jnz	powerOnDevice	; => It is...

	mov	cx, APMS_OFF				; actually off	

powerOnDevice:
	call	SysLockBIOS
	CallAPM	APMSC_SET_DEVICE_STATE
EC<	ERROR_C -1		; ah <- APMErrorCode		>
	call	SysUnlockBIOS

	inc	bx					; next device #
	add	si, size SuspendRestriction		; next device status
	cmp	bx, dx
	jbe	deviceLoop

	.leave
	ret
APMSetDeviceCategoryPower	endp

Resident			ends






