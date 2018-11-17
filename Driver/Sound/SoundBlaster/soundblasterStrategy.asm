COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Sound Driver	
FILE:		soundblasterStrategy.asm

AUTHOR:		Todd Stumpf, Aug  6, 1992

ROUTINES:
	Name			Description
	----			-----------
	SoundDriverStrategy	The Strategy for the driver
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 6/92		Initial revision


DESCRIPTION:
	The strategy routine for this driver.  This driver
	supports the Sound Blaster 1.0, Sound Blaster 1.5, and
	the Sound Blaster MicroChannel.

	As the 2.0 and Pro are downward compatible, it also supports
	them as well (actually, they support us, I guess...).  But,
	since they have extra capabilities that the 1.0, 1.5 and
	MC don't, we have a seperate driver for those boards.

	$Id: soundblasterStrategy.asm,v 1.1 97/04/18 11:57:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		dgroup DATA
;-----------------------------------------------------------------------------
idata	segment

DriverTable	DriverExtendedInfoStruct <
		<SoundStrategy,
		 mask DA_HAS_EXTENDED_INFO,
	 	 DRIVER_TYPE_SOUND>,
		SoundExtendedInfoSegment
		>

idata	ends

SoundExtendedInfoSegment	segment lmem LMEM_TYPE_GENERAL

SoundExtendedDriverInfoTable	DriverExtendedInfoTable <
					{},
					length SoundBoardNames,
					offset SoundBoardNames,
					offset SoundBoardInfoTable
				>

SoundBoardNames		lptr.char	soundBlaster1_0,
					soundBlaster1_5,
					soundBlasterMC
			lptr.char	0

soundBlaster1_0		chunk.char	'Sound Blaster 1.0',0
soundBlaster1_5		chunk.char	'Sound Blaster 1.5',0
soundBlasterMC		chunk.char	'Sound Blaster Micro Channel',0

	;
	;  The one word of data which gets used for all these
	;	sound devices is as follows:
	;  Uses timer 2
	;  Supports synthesized sounds
	;  Supports sampled sounds

OUR_WORD_OF_DATA	equ	SoundWordOfData <1,1,1,>

SoundBoardInfoTable	word		OUR_WORD_OF_DATA,	; SB 1.0
					OUR_WORD_OF_DATA,	; SB 1.5
					OUR_WORD_OF_DATA	; SB MC
			
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

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		The command is passed in di.  Look up the near pointer
		to the routine that handles that command in a jump table
		and jump to it.

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

	push	di				; save command
	mov	di, segment dgroup		; di <- dgroup of driver
	mov	ds, di				; ds <- dgroup of driver
	pop	di				; restore command

	cmp	di, DRE_SOUND_MIXER_GET_MASTER_VOLUME
	jae	done
	call	cs:routineJumpTable[di]
done:
	.leave
	ret
SoundStrategy	endp

routineJumpTable nptr	SBDInitBoardNear,
			SBDExitDriverNear,
			SBDSuspendNear,
			SBDUnsuspendNear,
			SBDTestDeviceNear,
			SBDSetDeviceNear,
			SBDDeviceQueryNear,
			SBDVoiceOn,
			SBDVoiceOff,
			SBDVoiceSilence,
			SBDChangeEnvelope,
			SBDDACAttachToStreamNear,
			SBDDACDettachFromStreamNear,
			SBDDACSetSample,
			SBDDACCheckSample,
			SBDDACResetADPCM,
			SBDDACFlushDACNear

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBD...Near
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

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	1/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDInitBoardNear	proc	near
	call	SBDInitBoard
	ret
SBDInitBoardNear	endp

SBDExitDriverNear	proc	near
	call	SBDExitDriver
	ret
SBDExitDriverNear	endp

SBDSuspendNear		proc	near
	call	SBDSuspend
	ret
SBDSuspendNear		endp

SBDUnsuspendNear	proc	near
	call	SBDUnsuspend
	ret
SBDUnsuspendNear	endp

SBDTestDeviceNear	proc	near
	call	SBDTestDevice
	ret
SBDTestDeviceNear	endp

SBDSetDeviceNear	proc	near
	call	SBDSetDevice
	ret
SBDSetDeviceNear	endp

SBDDeviceQueryNear	proc	near
	call	SBDDeviceQuery
	ret
SBDDeviceQueryNear	endp

SBDDACAttachToStreamNear	proc	near
	call	SBDDACAttachToStream
	ret
SBDDACAttachToStreamNear	endp

SBDDACDettachFromStreamNear	proc	near
	call	SBDDACDettachFromStream
	ret
SBDDACDettachFromStreamNear	endp

SBDDACFlushDACNear	proc	near
	call	SBDDACFlushDAC
	ret
SBDDACFlushDACNear	endp

ResidentCode		ends

LoadableCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDeviceQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the capabilities of the sound device selected

CALLED BY:	Strategy Routine
PASS:		ds	-> dgroup of driver

RETURN:		ax	<- # of individual FM voices available
		dx	<- # of DAC devices on the board
		bx	<- native SoundEnvelopeFormat
		cx	<- SoundDriverCapability
		di	<- SoundDriverDACCapability
		bp:si	<- Stream driver strategy routine to use

DESTROYED:	nothing
SIDE EFFECTS:	
		none

PSEUDO CODE/STRATEGY:
		load up the proper register and return.

		This is very simple only because all the FM chips
		are the same on all the current SoundBlaster boards.
		Once they come out with a new chip, well, then it
		might get a little more hairy.

		The SoundDriverCapability currently is:
			Doesn't support noise generation (which is odd...)
			SDWFC = SELECT - 
			   There are four differnt wave forms on the FM chip.
			SDTC  = MODULATOR -
			   The board can actually do a selective wave form
				by using the 18 cells additively, but the
				driver does not operate that way (yet...)
			SDEC  = ADSR -
			   Attack/Decay/Sustain/Release.  That's all she
				wrote.

		The SoundDriverDACCapability currently is:
			SDDACC_DMA = does DMA transfer
			SDDACC_INT = generates INT after transfer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDeviceQuery	proc	far
	.enter
	mov	ax, ds:[numOfVoices]			; 9 or 20 voices
	mov	dx, ds:[numOfDACs]			; 1 8-bit DAC
	mov	bx, SEF_SBI_FORMAT			; SBIData, if possible
	mov	cx, SoundDriverCapability <SDNC_NO_NOISE,
					   SDWFC_SELECT,
					   SDTC_MODULATOR,
					   SDEC_ADSR,>
	mov	di, SoundDriverDACCapability <1,1,>

	clrdw	bpsi
	.leave
	ret
SBDDeviceQuery	endp

LoadableCode	ends
