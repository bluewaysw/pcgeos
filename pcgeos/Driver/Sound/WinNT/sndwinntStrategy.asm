COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS Sound System
MODULE:		Standard Sound Driver
FILE:		standardStrategy.asm

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
	drivers must support
	

	$Id: sndwinntStrategy.asm,v 1.1 97/04/18 11:57:59 newdeal Exp $

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

SoundChipNames		lptr.char	pcSpeakerChip
			lptr.char	0

pcSpeakerChip		chunk.char	'Standard PC Speaker (PC/AT)',0

	;
	;  The one word of data that gets associated with the
	;	devices supported is:
	;  Requires Timer 2
	;  Supports synthesized sounds
	;  Does not support sampled sounds
SoundChipInfoTable	word		SoundWordOfData <1,1,0,>

SoundExtendedInfoSegment	ends

;-----------------------------------------------------------------------------
;		STRATEGY ROUTINE FOR SOUND DRIVER
;-----------------------------------------------------------------------------

ResidentCode	segment	resource

if SUPPORT_LOW_FREQ_FLAG

SDBeginEscapeTable	standard
SDDefEscape		standard, SDF_ESC_SET_LOW_FREQUENCY, \
					SPCSetLowFrequencyFlag
SDEndEscapeTable	standard

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the correct driver function when passed a legal
		command.

CALLED BY:	External

PASS:		di	-> command

RETURN:		see routines

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The command is passed in di.  Look up the near pointer
		to the routine that handles that command in a jump table
		and calls it.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 6/92		Initial version
	kho	4/ 9/96		Handle escape code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundStrategy	proc	far
	uses	ds
	.enter
	push	di
	mov	di, segment dgroup		; di <- our dgroup
	mov	ds, di				; ds <- our dgroup
	pop	di

if SUPPORT_LOW_FREQ_FLAG
	;
	; deal with escape code first
	;
	SDHandleEscape	standard, done
endif

	cmp	di, DRE_SOUND_MIXER_GET_MASTER_VOLUME
	jae	done

	call	cs:PCSpeakerStdJumpTable[di]	; jump to routine
done:
	.leave
	ret
SoundStrategy	endp

PCSpeakerStdJumpTable	nptr	SPCInit,		; INIT
				SPCExit,		; EXIT
				SPCSuspend,		; SUSPEND
				SPCInitFM,		; UNSUSPEND
				SPCTest,		; TEST_DEVICE
				SPCSet,			; SET_DEVICE
				SPCDeviceCapability,	; QUERY_DEVICE...
				SPCVoiceOn,		; VOICE_ON
				SPCVoiceOff,		; VOICE_OFF
				SPCVoiceOff,		; VOICE_SILENCE
				SPCEnvelope,		; SET_ENVELOPE
				SPCError,		; DAC_ATTACH
				SPCDoNothing,		; DAC_DETTACH
				SPCSampleRate,		; DAC_SET_SAMPLE_RATE..
				SPCSampleRate,		; DAC_CHECK_SAMPLE...
				SPCDoNothing,		; DAC_RESET_REF...
				SPCDoNothing,		; DAC_FLUSH...
				SPCDoNothing		; DAC_IS_DAC_EMPTY

vddHandle	word	0		; handle for talking to dll

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize driver the 1st time its loaded

CALLED BY:	Strategy Routine
PASS:		cx	-> di passed to GeodeLoad.
			   Garbage if loaded via GeodeUseDriver
		dx	-> bp passed to GeodeLoad.
			   Garbage if loaded bia GeodeUseDriver
RETURN:		carry clear if initialization successful.
		carry set if initializiation failed.

DESTROYED:	(allowed) bp, ds, es, ax, di, si, cx, dx
		(destroyed) nothing

SIDE EFFECTS:
		Changes clock 2 setting and turns off speaker.

PSEUDO CODE/STRATEGY:
		call SPCInitFM

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DllName DB      "GEOSVDD.DLL",0
InitFunc  DB    "VDDRegisterInit",0
DispFunc  DB    "VDDDispatch",0
SPCInit	proc	near
	uses	si, di, bx, es
	.enter	
	;;
	;; Register with VDD
	;;
	; if we have already registered, don't do it again, buddy.
		cmp	cs:[vddHandle], 0
		jne	registered
	;
	; Register the dll
		push	cx, dx, ds
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
	        mov     si, offset DllName           ; ds:si = dll name
	        mov     di, offset InitFunc          ; es:di = init routine
	        mov     bx, offset DispFunc          ; ds:bx = dispatch routine
	
	        RegisterModule
		nop
		mov	cs:[vddHandle], ax
		pop	cx, dx, ds

registered:
	call	SPCInitFM
	clc
	.leave
	ret
SPCInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit driver

CALLED BY:	Strategy Routine

PASS:		nothing
RETURN:		nothing
DESTROYED:	(allowed) ax, bx, cx, dx, si, di, ds, es

SIDE EFFECTS:
		turns off speaker

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SPCExit	proc	near
	.enter
	;
	; Turn off any sound and unload the library.
	;
		mov	ax, cs:[vddHandle]
		mov	bx, VDD_FUNC_SPEAKER_OFF
		DispatchCall

		UnRegisterModule
		clr	cs:[vddHandle]
	.leave
	ret
SPCExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare device for being task-switched

CALLED BY:	Strategy Routine
PASS:		cx:dx	-> buffer to place refusal for suspension (if any)
			DRIVER_SUSPEND_ERROR_BUFFER_SIZE bytes long
RETURN:		carry set if suspension refused:
			cx:dx <- buffer filled with null-terminated reason,
				 standard PC/GEOS character set.
		carry clear if suspension approved

DESTROYED:	(allowed) ax, di
		(destroyed) nothing

SIDE EFFECTS:
		calls SPCInitFM

PSEUDO CODE/STRATEGY:
		call SPCInitFM

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPCSuspend	proc	near
	.enter
	call	SPCInitFM
	clc
	.leave
	ret
SPCSuspend	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return from task switching

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		nothing
DESTROYED:	(allowed) ax, di
		(destroyed) nothing

SIDE EFFECTS:
		calls SPCInitFM

PSEUDO CODE/STRATEGY:
		Call SPCInitFM directly....

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCTest
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
SPCTest	proc	near
	uses	cx, ds, es
	.enter
	EnumerateDevice SoundExtendedInfoSegment
	jc	done

	call	MemUnlock		; unlock resource

	;
	;  Well, someone wanted to select the Standard PC speaker driver.
	;  We can't be sure if its there, however.
	mov	ax, DP_CANT_TELL
done:
	.leave
	ret
SPCTest	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCSet
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
SPCSet	proc	near
	uses	ax, cx, ds, es
	.enter
	EnumerateDevice SoundExtendedInfoSegment
	jc	done

	call	MemUnlock		; unlock resource

	call	SPCInitFM		; set up speaker
done:
	.leave
	ret
SPCSet	endp

ResidentCode	ends

