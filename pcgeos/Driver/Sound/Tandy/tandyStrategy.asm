COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS Sound System
MODULE:		Tandy Sound Driver
FILE:		tandyStrategy.asm

AUTHOR:		Todd Stumpf, Aug 14, 1992

ROUTINES:
	Name			Description
	----			-----------
	SoundStrategy		The Strategy for the driver
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 6/92		Initial revision


DESCRIPTION:
	The strategy routine and the first four routines that all
	drivers must support.

	$Id: tandyStrategy.asm,v 1.1 97/04/18 11:57:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		dgroup DATA for driver info table
;-----------------------------------------------------------------------------
idata	segment

DriverTable		DriverExtendedInfoStruct <
					<SoundStrategy,
			  		 mask DA_HAS_EXTENDED_INFO,
				 	 DRIVER_TYPE_SOUND>,
					 SoundExtendedInfoSegment>


idata	ends

SoundExtendedInfoSegment	segment lmem LMEM_TYPE_GENERAL

SoundExtendedDriverInfoTable	DriverExtendedInfoTable <
					{},
					length SoundChipNames,
					offset SoundChipNames,
					offset SoundChipInfoTable
				>

SoundChipNames		lptr.char	tandy1000Chip
			lptr.char	0

tandy1000Chip	chunk.char	'Tandy 1000 Speaker',0

	; the one word of data that gets associated with
	;	this particular device is:
	;
	;	Does not use Timer2
	;	Supports Synthsized sound,
	;	Does not support Sampled Sounds
SoundChipInfoTable	word		SoundWordOfData <0,1,0,>

SoundExtendedInfoSegment	ends


;-----------------------------------------------------------------------------
;		STRATEGY ROUTINE FOR SOUND DRIVER
;-----------------------------------------------------------------------------

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the correct driver function when passed a legal
		command.

CALLED BY:	External

PASS:		di	-> command

RETURN:		see routines

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		The command is passed in di.  Look up the near pointer
		to the routine that handles that command in a jump table
		and call it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundStrategy	proc	far
	uses	ds
	.enter
	push	di
	mov	di, segment dgroup		; di <- our dgroup
	mov	ds, di				; ds <- our dgroup
	pop	di
	call	cs:driverJumpTable[di]		; jump to routine
	.leave
	ret
SoundStrategy	endp

driverJumpTable	nptr		TDInit,			; DR_INIT
				TDExit,			; DR_EXIT
				TDExit,			; DR_SUSPEND
				TDInit,			; DR_UNSUSPEND
				TDTest,			; DR_TEST_DEVICE
				TDSet,			; DR_SET_DEVICE
				TDDeviceCapability,	; DR_QUERY_DEVICE...
				TDVoiceOn,		; DR_VOICE_ON
				TDVoiceOff,		; DR_VOICE_OFF
				TDVoiceOff,		; DR_VOICE_SILENCE
				TDEnvelope,		; DR_SET_ENVELOPE
				TDCarrySet,		; DR_DAC_ATTACH...
				TDCarryClear,		; DR_DAC_DETTACH...
				TDClearCXAndDX,		; DR_DAC_SET_SAMPLE...
				TDClearCXAndDX,		; DR_DAC_CHECK_SAMPLE..
				TDCarrySet,		; DR_DAC_RESTE_REF...
				TDCarrySet,		; DR_DAC_FLUSH_DAC
				TDCarrySet		; DR_DAC_IS_EMPTY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDDeviceCapability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the capabilities of the device

CALLED BY:	StrategyRoutine
PASS:		ds	-> dgroup

RETURN:		ax	<- # of FM voices
		dx	<- # of DACs
		bx	<- native SoundEnvelopeFormat
		cx	<- SoundDriverCapability
		di	<- SoundDriverDACCapability
		bp:si	<- fptr to stream strategy routine to use

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDDeviceCapability	proc	near
	.enter
	mov	ax, 3				; 3 voices
	clr	dx				; no DAC voices
	mov	bx, SEF_CTI_FORMAT		; 3 voice/metal info
	mov	cx, SoundDriverCapability <,SDNC_WHITE_NOISE,
					   SDWFC_NONE,
					   SDTC_ADDITIVE,
					   SDEC_NONE>
	clr	di, bp, si			; no dac capability
						; return null pointer
	.leave
	ret
TDDeviceCapability	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the sound chip for operation

CALLED BY:	Strategy Routine

PASS:		ds	-> dgroup of driver

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDInit		proc	near
	uses	ax, bx, cx, dx
	.enter
	clc
	.leave
	ret
TDInit		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut down sound driver

CALLED BY:	Strategy Routine

PASS:		ds	-> dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Disable speaker and chip.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/21/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDExit	proc	near
	uses	ax, bx, cx, dx
	.enter
	clc
	.leave
	ret
TDExit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if a device is present

CALLED BY:	Strategy Routine
PASS:		dx:si	-> pointer to null-terminate device name string

RETURN:		ax	<- DevicePresent
		carry set if DP_INVALID_DEVICE
		carry clear otherwise

DESTROYED:	(allowed) di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		determine if string accessed by dx:si is the same as
			the string in our extended table.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDTest	proc	near
	uses	cx, ds, es
	.enter
	EnumerateDevice SoundExtendedInfoSegment
	jc	done

	;
	;  Well, someone wanted to select the Casio speaker driver.
	;  We can't be sure if its there, however.
	mov	ax, DP_CANT_TELL

done:

	call	MemUnlock		; unlock resource
	.leave
	ret
TDTest	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Informs which device to support

CALLED BY:	Strategy Routine

PASS:		dx:si	-> pointer to null-terminated device name string

RETURN:		nothing

DESTROYED:	(allowed) di
		(destroyed) nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDSet	proc	near
	uses	ax, cx, ds, es
	.enter
	EnumerateDevice SoundExtendedInfoSegment
	jc	done

	call	TDInit			; set up speaker

done:
	call	MemUnlock		; unlock resource

	.leave
	ret
TDSet	endp

ResidentCode	ends

