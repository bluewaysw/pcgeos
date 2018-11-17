COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Power Drivers
FILE:		apmOnOff.asm

AUTHOR:		Todd Stumpf, Aug  1, 1994

ROUTINES:
	Name			Description
	----			-----------
	APMDeviceOnOff		Change the power state of a peripheral
	APMPCMPowerOnOff	Change the power state of a PCMCIA card
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94   	Initial revision


DESCRIPTION:
	
		

	$Id: apmOnOff.asm,v 1.1 97/04/18 11:48:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMDeviceOnOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn the power to a specific device on/off

CALLED BY:	PowerStrategy

PASS:		DS, ES	-> DGroup
		AX	-> PowerDeviceType
		cx	-> zero if turning off, non-zero if on
		bx, dx	-> See Pseudo-code/Strategy

RETURN:		carry set if no device (or some such error)
		      clear otherwise
		ax	<- PowerDeviceError

DESTROYED:	di, ds, es

PSEUDO CODE/STRATEGY:
		PDT_SERIAL_PORT:
			bx	-> 0 for com1, 1 for com2 ...
			dx	-> SerialPowerInfo
		PDT_PARALLEL_PORT:
			bx	-> 0 for lpt1, 1 fpr lpt2 ...
		PDT_PCMCIA_SOCKET:
			bx	-> socket #
			dx	-> PCMCIAPowerInfo
		PDT_KEYBOARD:

		PDT_DISPLAY:
			bx	-> 0 for 1st display, 1 for 2nd display

KNOWN BUGS/SIDE EFFECTS/IDEAS:
v
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Todd	6/22/94		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMDeviceOnOff	proc	near
	uses	bx, cx, si
	.enter

	call	PowerDeviceOnOff		; handle common stuff

if	DEVICE_SPECIFIC_DEVICE_ON_OFF_CODE
	call	APMDeviceOnOffHWCode
endif

	;
	;  Get proper on/off status
	tst	cx				; turning on or off?

	mov	cx, APMS_OFF			; does not affect flags	

	jz	jumpToDeviceHandler		; jump on on/off condition

	clr	cx				; cx <- APMS_READY

jumpToDeviceHandler:
	mov_tr	si, ax				; si <- device type
	mov	ax, PDE_NO_SUCH_DEVICE
	shl	si, 1				; si <- word index
	cmp	si, size powerDeviceJumpTable
	jae	error	; => Off Table (carry clear)

	jmp	cs:powerDeviceJumpTable[si]

adjBit:
	or	{byte}ds:[si], mask SR_DEVICE_ON		; assume on
	jcxz	exit						; is it?
	and	{byte}ds:[si], not mask SR_DEVICE_ON		; guess not
	jmp	exit

adjBitCallAPM:
	ornf	{byte}ds:[si], mask SR_DEVICE_ON		; assume on
	jcxz	callAPM						; is it?
	andnf	{byte}ds:[si], not mask SR_DEVICE_ON		; guess not

callAPM:
	call	SysLockBIOS

	CallAPM	APMSC_SET_DEVICE_STATE

EC<	ERROR_C -1		; ah <- APMErrorCode		>
	call	SysUnlockBIOS

	stc					; return carry clear

error:
	cmc
exit:
	.leave
	ret

dev_parallel:
if	HAS_PARALLEL_PORTS
	;
	;  Adjust device # and mark parallel port as on or off
	mov	si, offset parallelPowerStatus	; si <- SuspendRestriction
	add	si, bx
ifidn	HARDWARE_TYPE, <GPC1>
	; GPC1 APM BIOS doesn't support parallel port, so don't call it.
	jmp	adjBit
else
	add	bx, APMDID_PARALLEL_PORT_LPT1	; bx <- APM Device ID #
	jmp	adjBitCallAPM
endif	; HARDWARE_TYPE, <GPC1>
else
	clc					; return carry set
	jmp	error
endif

dev_serial:
if	HAS_SERIAL_PORTS
	;
	;  Adjust device # and mark serial port as on or off
	mov	si, offset serialPowerStatus	; si <- SuspendRestriction
	add	si, bx
ifidn	HARDWARE_TYPE, <GPC1>
	; GPC1 APM BIOS doesn't support serial ports, so don't call it.
	jmp	adjBit
else
	add	bx, APMDID_SERIAL_PORT_COM1	; bx <- APM Device ID #
	jmp	adjBitCallAPM
endif	; HARDWARE_TYPE, <GPC1>
else
	clc					; return carry set
	jmp	error
endif


dev_pcmcia:
if	HAS_PCMCIA_PORTS
	call	APMPCMPowerOnOff
endif
	jmp	exit

dev_keyboard:
if	HAS_DETACHABLE_KEYBOARD
	call	APMCheckKeyboard
else
	clc
endif
	jmp	exit

dev_display:
if	HAS_DISPLAY_CONTROLS
	;
	;  Adjust the state of the display.
	mov	si, offset displayPowerStatus	; si <- SuspendRestriction
	add	si, bx
	add	bx, APMDID_DISPLAY		; bx <- APM Device ID #
	jmp	adjBitCallAPM
else
	clc					; return carry set
	jmp	error
endif

dev_speaker:
if	HAS_SPEAKER_CONTROLS
	;
	;  Adjust device # and mark speaker as on or off
	mov	si, offset speakerPowerStatus	; si <- SuspendRestriction
	add	si, bx
	jmp	adjBit
else
	clc			;Return carry clear (speaker cannot be 
				; controlled currently, and we'll let Todd
				; mess with this for Obiwan)
	jmp	exit
endif

powerDeviceJumpTable			nptr	dev_serial,
						dev_parallel,
						dev_pcmcia,
						dev_keyboard,
						dev_display,
						dev_speaker

APMDeviceOnOff	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMPCMPowerOnOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn power on/off to a socket

CALLED BY:	APMDeviceOnOff

PASS:		bx	-> logical socket #
		cx	-> APMS_READY/APMS_OFF
		dx	-> PCMCIAPowerInfo


RETURN:		carry set on error
		ax	<- error

DESTROYED:	ax, bx, cx, si all possible (saved by caller)

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HAS_PCMCIA_PORTS
APMPCMPowerOnOff	proc	near
	uses	dx,di,bp
	.enter
	cmp	bx, NUM_PCMCIA_PORTS
	jae	noSuchDevice

	;
	;  Determine which pcmcia SuspendRestrictions to mess with...
	mov	si, offset pcmciaPowerStatus		; si <- SR to fiddle
	add	si, bx

	;
	; compute flags to set in powerOffOK in AL. When turning the device on,
	; we set the RESTRICTED bit for the appropriate slot only if the
	; NO_POWER_OFF bit is set in the PCMCIAPowerInfo record.

	mov	al, mask SR_DEVICE_ON
	tst	cx
	jnz	setRestrictedBit		; always clear restricted
						;  bit if turning device OFF
	test	dx, mask PCMCIAPI_NO_POWER_OFF
	jz	setFlags

setRestrictedBit:
	ornf	ax, mask SR_RESTRICTED

setFlags:
	; always merge in bits if on, as new device might want to restrict
	; power off where previous caller didn't...

	ornf	{byte}ds:[si], al				; assume on
	jcxz	incRefCount					; is it?
	
EC <	tst	ds:[socketOnCount][bx]					>
EC <	ERROR_Z	SOCKET_POWER_COUNT_UNDERFLOW				>

	dec	ds:[socketOnCount][bx]
	jnz	doneOK				; leave bits alone unless
						;  actually powering off
	
	not	al
	andnf	{byte}ds:[si], al				; guess not

doneOK:
	clc
done:
	.leave
	ret

incRefCount:
	inc	ds:[socketOnCount][bx]
EC <	ERROR_Z	SOCKET_POWER_COUNT_OVERFLOW				>
   	jmp	doneOK

noSuchDevice:
	mov	ax, PDE_NO_SUCH_DEVICE
	stc
	jmp	done
APMPCMPowerOnOff	endp
endif
Resident			ends
