COMMENT @********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound

DATEI:		bsstrate.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init
        DL	22.12.1999	Ableitung fÅr NewWave
        DL	22.08.2000	Translation for ND

ROUTINE:
	Name			Description
	----			-----------
	SoundDriverStrategy	The Strategy for the driver

*****************************************************************@

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

SoundBoardNames		lptr.char	cardName1
			lptr.char	0

cardName1		chunk.char	'Soundblaster 16 (or compatible)',0

	;
	;  The one word of data which gets used for all these
	;	sound devices is as follows:
	;  Uses timer 2
	;  Supports synthesized sounds
	;  Supports sampled sounds

OUR_WORD_OF_DATA	equ	SoundWordOfData <1,1,1,>

SoundBoardInfoTable	word		OUR_WORD_OF_DATA	; SB 1.0

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
	push	ds

	push	di				; save command
	mov	di, segment dgroup		; di <- dgroup of driver
	mov	ds, di				; ds <- dgroup of driver
	pop	di				; restore command

	call	cs:routineJumpTable[di]

	pop	ds
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
			SBDDACFlushDACNear,

; mixer control
                        BSMixerGetCapNear,
                        BSMixerGetValueNear,
                        BSMixerSetValueNear,
                        BSMixerSetDefaultNear,
                        BSMixerTokenToTextNear,
                        BSMixerSpecValueNear,
                        BSMixerGetSubTokenNear,

; recording
			BSRecordGetRMSValueNear,
                        BSDRecSetSamplingNear,
                        BSDRecStartRecordingNear,
                        BSDStopRecOrPlayNear,
                        BSDRecGetDataNear,
                        BSDRecGetMaxPropertiesNear,
; NewWave
			BSDNWAllocSecBufNear,
                        BSDNWGetStatusNear,
                        BSDNWStartPlayNear,
                        BSDNWGetAIStateNear,
                        BSDNWSetPauseNear


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

;---------------------
;	Mixer
;---------------------
BSMixerGetCapNear	proc	near
	call	BSMixerGetCap
	ret
BSMixerGetCapNear	endp

BSMixerGetValueNear	proc	near
	call	BSMixerGetValue
	ret
BSMixerGetValueNear	endp

BSMixerSetValueNear	proc	near
	call	BSMixerSetValue
	ret
BSMixerSetValueNear	endp

BSMixerSetDefaultNear	proc	near
	call	BSMixerSetDefault
	ret
BSMixerSetDefaultNear	endp

BSMixerTokenToTextNear	proc	near
	call	BSMixerTokenToText
	ret
BSMixerTokenToTextNear	endp

BSMixerSpecValueNear	proc	near
	call	BSMixerSpecValue
	ret
BSMixerSpecValueNear	endp

BSMixerGetSubTokenNear	proc	near
	call	BSMixerGetSubToken
	ret
BSMixerGetSubTokenNear	endp

;--------------------------------------
;	Recording
;--------------------------------------

BSRecordGetRMSValueNear	proc	near
	call	BSRecordGetRMSValue
        ret
BSRecordGetRMSValueNear	endp

BSDRecSetSamplingNear	proc	near
	call	BSDRecSetSampling
        ret
BSDRecSetSamplingNear	endp


BSDRecStartRecordingNear	proc	near
	call	BSDRecStartRecording
        ret
BSDRecStartRecordingNear	endp

BSDStopRecOrPlayNear	proc	near
	call	BSDStopRecOrPlay
        ret
BSDStopRecOrPlayNear	endp

BSDRecGetDataNear	proc	near
	call	BSDRecGetData
        ret
BSDRecGetDataNear	endp

BSDRecGetMaxPropertiesNear	proc near
	call	BSDRecGetMaxProperties
        ret
BSDRecGetMaxPropertiesNear	endp


;--------------------------------------
;	NewWave - Play
;--------------------------------------

BSDNWAllocSecBufNear	proc near
; IN:	cx = size
; OUT:	cx = real size
;	axdx = Pointer
        push	ds
        mov	ax, segment dgroup
        mov	ds,ax

	call	BSSecondAlloc

	mov	ax,ds:[bufferSegment]	; Segmentaddress
        mov	cx,ds:[bufferLen]	; size
        clr	dx			; Offset = 0
	pop	ds
        ret
BSDNWAllocSecBufNear	endp

BSDNWGetStatusNear	proc near
	call	BSDNWGetStatus
        ret
BSDNWGetStatusNear	endp

BSDNWStartPlayNear	proc near
	call	BSDNWStartPlay
        ret
BSDNWStartPlayNear	endp

BSDNWGetAIStateNear	proc near
	call	BSDNWGetAIState
        ret
BSDNWGetAIStateNear	endp

BSDNWSetPauseNear	proc near
	call	BSDNWSetPause
        ret
BSDNWSetPauseNear	endp

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
