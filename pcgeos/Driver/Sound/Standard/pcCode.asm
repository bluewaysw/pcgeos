COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS Sound System
MODULE:		Standard Sound Driver
FILE:		pcCode.asm

AUTHOR:		Todd Stumpf, Aug 18, 1992

ROUTINES:
	Name			Description
	----			-----------
	SPCInitFM		Set up speaker for FM synthesis

	SPCVoiceOn		Turn on a note
	SPCVoiceOff		Turn off a note
	SPCEnvelope		"Deal" with changing an envelope
	SPCDeviceCapability	Return the capability of the PC speaker

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/18/92		Initial revision


DESCRIPTION:
	This contains the code for the standard PC speaker.
		

	$Id: pcCode.asm,v 1.1 97/04/18 11:57:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
udata		segment
	;
	;  To speed things up slightly, keep around the last setting
	;  so we don't have to re-set it.
	currentFrequency	word
udata		ends


if SUPPORT_LOW_FREQ_FLAG

idata		segment

lowFrequency	byte	0	; when set to non-zero, all the notes
				; will be played at a fraction of the
				; original frequency

lowFreqFactor byte	0	; how much should the frequency be
				; lowered if "lowFrequency" flag is
				; true? This is read from init file.

idata		ends

endif

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCInitFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the PC speaker to start working

CALLED BY:	Strategy routine

PASS:		ds	-> dgroup of driver

RETURN:

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Turn off the speaker.
		Set up clock to generate propper setting (square wave)
		Set up timer to count known value (18.2 Hz)
		Set up dgroup to reflect known state

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPCInitFM	proc	near
	uses	ax
	.enter
	SPEAKER_OFF

	;  Set up timer chip to generate a square wave, counting in
	;  binary.
	mov	al, TT_TIMER_2 or TRL_WORD or TM_SQUARE_WAVE or TC_BINARY
	out	I8253.Mode, al			; select wave form
	jmp	$+2				; delay for fast computers
	jmp	$+2				; delay for fast computers

	;  Load the timer up to maximum, so it counts for 65535 to 0
	;  and back again. (18.2 Hz)
	mov	al, 0ffh
	out	I8253.Counter2, al		; write lsb
	jmp	$+2				; delay for fast computers
	jmp	$+2				; delay for fast computers
	out	I8253.Counter2, al		; write msb

	;
	;  set up current frequency
	mov	ds:[currentFrequency], 18	; 18.2 Hz 
	.leave
	ret
SPCInitFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCVoiceOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on a voice on the PC speaker

CALLED BY:	strategy routine
PASS:		ax	-> frequency of tone to generate in Hz
		bx	-> volume of note
		cx	-> voice to play on

		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		calculate the value to load the timer with, then
		set it up and return
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPCVoiceOn	proc	near
	uses	ax,bx,cx,dx
	.enter

	;
	;  Check for legal voice value
	tst	cx				; we only have voice 0
	jnz	done

if SUPPORT_LOW_FREQ_FLAG			;----------------------------
	;
	;  Should we cut frequency of notes in half?
	tst	ds:[lowFrequency]
	jz	notLowered
	;
	;  Get the factor
	;
	push	cx
	mov	cl, ds:[lowFreqFactor]
	shr	ax, cl				; frequency lowered
	pop	cx
	
notLowered:
endif	; SUPPORT_LOW_FREQ_FLAG			;----------------------------
	
	;
	;  Check for note out of range
ifdef	_MIN_FREQ
	cmp	ax, MINIMUM_FREQUENCY
	jb	done
endif

ifdef	_MAX_FREQ
	cmp	ax, MAXIMUM_FREQUENCY
	ja	done
endif

	;
	;  Check for a silent note "on"
	tst	bx				; no volume, no note
	jz	done


	;
	;  Is timer currently set for the frequency?
	cmp	ds:[currentFrequency], ax	; currently set up for it?
	je	playNote

	;
	;  Change udata to reflect new frequency
	mov	ds:[currentFrequency], ax	; save frequency

	;  Calculate timer setting for specific frequency
	mov_tr	bx, ax				; bx <- frequency
	movdw	dxax, COUNTER_TICKS		; dx.ax <- Frequency of timer2
	div	bx				; ax <- setting for timer

	mov_tr	bx, ax				; bx <- clock setting

	;
	;  Set up Timer 2 to generate a Sqaure Wave to PC speaker
	mov	al, TT_TIMER_2 or TRL_WORD or TM_SQUARE_WAVE or TC_BINARY
	out	I8253.Mode, al			; set timer to square wave
	jmp	$+2				; delay for fast computers
	jmp	$+2				; delay for fast computers

	;
	;  Set least-significant-byte for timer value
	mov	al, bl				; al <- lsb for timer
	out	I8253.Counter2, al		; write lsb of frequency
	jmp	$+2				; delay for fast computers
	jmp	$+2				; delay for fast computers

	;
	;  Set most-signifiant-byte of timer value
	mov	al, bh				; al <- msb of timer
	out	I8253.Counter2, al		; write msb of frequenct
	jmp	$+2				; delay for fast computers
	jmp	$+2				; delay for fast computers

playNote:
	;
	;  Sound the note
	SPEAKER_ON			; start generating tone
done:
	.leave
	ret
SPCVoiceOn	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCVoiceOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn a note off

CALLED BY:	Strategy Routine
PASS:		cx	-> voice to release

		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		turn the PC speaker off

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPCVoiceOff	proc	near
	uses	ax
	.enter
	;
	;  Is event for correct voice?
	tst	cx				; only respond to voice 0
	jnz	done


	SPEAKER_OFF				; turn off speaker
done:
	.leave
	ret
SPCVoiceOff	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCSpeakerOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off speaker unconditionally

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		turns off speaker

PSEUDO CODE/STRATEGY:
		turn off speaker		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/28/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPCSpeakerOff	proc	near
	uses	ax
	.enter
	SPEAKER_OFF
	.leave
	ret
SPCSpeakerOff	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCEnvelope
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the envelope of the PC/SPEAKER

CALLED BY:	Strategy Routine
PASS:		cx	-> voice to change
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	
		clears the carry, turns off any note playing
PSEUDO CODE/STRATEGY:
		As the PC/SPEAKER is a tone generator, there is not
		much we can do with an envelope.  Makes coding this
		routine rather easy....

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPCEnvelope	proc	near
	uses	ax
	.enter
	;
	;  Check to see we are responding to a legal voice
	tst	cx
	jnz	done

	SPEAKER_OFF
done:
	clc					; everything went well
	.leave
	ret
SPCEnvelope	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCDeviceCapability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the device capability of the PC speaker

CALLED BY:	Sound Strategy routine
PASS:		nothing
RETURN:		ax	<- # of FM voices
		dx	<- # of DACs
		bx	<- native SoundEnvelopeFormat (pass it this format)
		cx	<- SoundDriverCapability
		di	<- SoundDriverDACCapability
		bp:si	<- fptr to stream driver to use

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SPCDeviceCapability	proc	near
	.enter
	mov	ax, 1					; 1 voice for speaker
	mov	bx, SEF_NO_FORMAT			; no envelope possible
	mov	cx, SoundDriverCapability <0,0,
					   SDWFC_NONE,
					   SDTC_TONE_GENERATOR,
					   SDEC_NONE>
	clr	dx, di, bp, si				; no DAC supported
							; no stream driver
	.leave
	ret
SPCDeviceCapability	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry set

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		sets carry flag

PSEUDO CODE/STRATEGY:
		set carry flag
		return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/ 1/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPCError	proc	near
	.enter
	stc
	.leave
	ret
SPCError	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	
		none
PSEUDO CODE/STRATEGY:
		return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/ 1/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPCDoNothing	proc	near
	.enter
	clc
	.leave
	ret
SPCDoNothing	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCSampleRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return acceptable sampling rates for our "DAC"

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		dx 	<- 0
		cx	<- 0
DESTROYED:	nothing
SIDE EFFECTS:
		clears cx and dx

PSEUDO CODE/STRATEGY:
		clear cx and dx
		return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/ 1/92    	Initial version

p%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPCSampleRate	proc	near
	.enter
	clr	cx, dx	; format not supported
			; stream size, given rate
	.leave
	ret
SPCSampleRate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCSetLowFrequencyFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the lowFrequency flag.

CALLED BY:	GLOBAL
PASS:		ds	= dgroup
		cx	= flag (TRUE/FALSE)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	global lowFrequency flag is changed, so sound output
		may now be different (see SPCVoiceOn)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SUPPORT_LOW_FREQ_FLAG

uiCategoryString	char	"ui", 0
lowSoundFactorString	char	"lowSoundFactor", 0

SPCSetLowFrequencyFlag	proc	far
		uses	ax, cx, dx, si
		.enter
	;
	; Fill in the flag
	;
		mov	ds:[lowFrequency], cl
	;
	; Also, read in [ui]lowSoundFactor into global variable
	;
		push	ds
		mov	ax, DEFAULT_LOW_SOUND_FACTOR
		segmov	ds, cs, cx			; ds:si - category
							; cx:dx - key
		mov	si, offset uiCategoryString
		mov	dx, offset lowSoundFactorString
		call	InitFileReadInteger		; ax - value,
							; ax not changed if
							; ini key not found
		mov_tr	cx, ax				; cx <- value
		Assert	be, cx, 255			; cx <= 255, and
							; positive
		pop	ds
		mov	ds:[lowFreqFactor], cl
		
		.leave
		ret
SPCSetLowFrequencyFlag	endp

endif

ResidentCode	ends







