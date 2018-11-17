COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS Sound System
MODULE:		Tandy Sound Driver (Zoomer)
FILE:		tandyCodeFM.asm

AUTHOR:		Todd Stumpf, Aug 18, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/18/92		Initial revision


DESCRIPTION:
	This is code to manipulate the 3-voice chip used on the
		tandy 1000 computers.

	The chip has three square-wave tone generators with
		frequency and volume control as well as a
		single noise generator with volume control.

	Instrument patches are produced by using different
		harmonics and noise levels.  It doesn't sound
		really good, but it does sound better than
		nothing.

	$Id: tandyCodeFM.asm,v 1.1 97/04/18 11:57:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment

	;
	; The list of FM voice nodes
	;
   headOfList		VoiceVolumeFrequencyNode \
			<0,0,offset headOfList, offset tailOfList>

   voiceIntensity	VoiceTimbre	  VOICE_COUNT	dup (\
			<<0,0, offset headOfList, offset tailOfList>,
			 <0,0, offset headOfList, offset tailOfList>,
			 <0,0, offset headOfList, offset tailOfList>>)

   tailOfList		VoiceVolumeFrequencyNode \
			<0,0,offset headOfList, offset tailOfList>

	;
	; The list of Noise voice nodes
	;
   headOfNoiseList	VoiceVolumeFrequencyNode \
			<0,0,offset headOfNoiseList, offset tailOfNoiseList>

   noiseIntensity	VoiceTimbre \
			<<0,0, offset headOfNoiseList, offset tailOfNoiseList>,
			 <0,0, offset headOfNoiseList, offset tailOfNoiseList>,
			 <0,0, offset headOfNoiseList, offset tailOfNoiseList>>

   tailOfNoiseList	VoiceVolumeFrequencyNode \
			<0,0, offset headOfNoiseList, offset tailOfNoiseList>

idata		ends

udata		segment
	;
	;  The current envelope settings for the voices
	;
   voiceEnvelope	CTIEnvelopeFormat VOICE_COUNT 	dup (<>)

	;
	;  The current # of voices which are playing
	;
   activeVoices		word	0

udata		ends


ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDVoiceOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	turn on (probably) a note with a given intensity

CALLED BY:	Strategy Routine

PASS:		ax	-> frequency to generate in Hz
		bx	-> volume of note
		cx	-> voice to play on
		ds	-> dgroup of driver

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		alters the tone generator

PSEUDO CODE/STRATEGY:
		calculate new voiceIntensity by
			examining voiceTimbre

		Allocate voices to 3 loudest timbres
		Set metal to loudest metal		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert size VoiceVolumeFrequencyNode	eq 8
	.assert size CTIEnvelopeFormat		eq 4
TDVoiceOn	proc	near
	uses	ax, bx, cx, dx, si, di
	.enter
	;
	;  Determine if the voice # is even legal
	;
	cmp	cx, VOICE_COUNT			; only three voices
	jae	done

processNoteOn::

	mov	si, cx				; si <- voice #
	shl	si, 1				; si <- voice # * size word

	mov	di, cs:voiceEnvelopeOffsetTable[si]
	mov	si, cs:voiceIntensityOffsetTable[si]

	call	TDSetVoiceNoiseLevel

	;
	;  Determine frequency setting for given note
	cmp	ax, LOWEST_POSSIBLE_TONE
	jb	setLowNoteDivisor

	mov_tr	cx, ax				; cx <- frequency

	movdw	dxax, FM_CLOCK_SPEED
	div	cx				; ax <- setting for hardware
EC<	ERROR_C -1							>

saveDivisors:	
	mov	ds:[si].VT_timbre1.VVFN_freq, ax	; store fundamental

	shr	ax, 1					; double the freq.
	mov	ds:[si].VT_timbre2.VVFN_freq, ax	; store 1st harmonic

	shr	ax, 1					; double the freq.
	mov	ds:[si].VT_timbre3.VVFN_freq, ax	; store 2nd harmonic

	;
	;  Calculate the volumes for the various harmonics

	mov	cl, 4
	mov	ax, bx				; ax <- volume level
	mul	ds:[di].CTIEF_fundamental	; dxax <- 1st volume
	rol	dx, cl				; dx <- 4-bit volume
	and	dx, 0000fh
	mov	ds:[si].VT_timbre1.VVFN_vol, dx	; store high word

	mov	ax, bx				; ax <- volume level
	mul	ds:[di].CTIEF_secondPartial	; dxax <- 2nd volume
	rol	dx, cl				; dx <- 4-bit volume
	and	dx, 0000fh
	mov	ds:[si].VT_timbre2.VVFN_vol, dx	; store high word

	mov	ax, bx				; ax <- volume level
	mul	ds:[di].CTIEF_secondPartial	; dxax <- 3rd volume
	rol	dx, cl				; dx <- 4-bit volume
	and	dx, 0000fh
	mov	ds:[si].VT_timbre3.VVFN_vol, dx	; store high word

	;
	;  Rearrange the list so loud voices are at the front.
	
	lea	bx, [si].VT_timbre1		; remove from list
	call	TDRemoveVoiceFromList

	lea	bx, [si].VT_timbre2		; remove from list
	call	TDRemoveVoiceFromList

	lea	bx, [si].VT_timbre3		; remove from list
	call	TDRemoveVoiceFromList

	mov	di, si				; di <- base of voice

	;
	;  Remember to get new head of list for each insert,
	;	as the head of list could have changed when we
	;	inserted the previous voice...

						; ds:bx <- voice to insert
	mov	si, ds:[headOfList].VVFN_next	; ds:si <- start of list
	call	TDAddVoiceToList		; insert into correct place


	lea	bx, [di].VT_timbre2		; ds:bx <- voice to insert
	mov	si, ds:[headOfList].VVFN_next	; ds:si <- start of list
	call	TDAddVoiceToList		; insert into correct place

	lea	bx, [di].VT_timbre1		; ds:bx <- voice to insert
	mov	si, ds:[headOfList].VVFN_next	; ds:si <- start of list
	call	TDAddVoiceToList		; insert into correct place

	;
	;  Turn on the new voices...
	call	TDSetVoices

done:
	.leave
	ret

setLowNoteDivisor:
	;
	;  The note is so low, our division would get messed up.
	;  We just plug in the lowest possible frequency value
	;	and deal with it.
	mov	ax, 00fffh			; ax <- 112 Hz
	jmp	short saveDivisors

TDVoiceOn	endp

voiceEnvelopeOffsetTable	nptr	\
	offset voiceEnvelope,
	offset voiceEnvelope + size CTIEnvelopeFormat,
	offset voiceEnvelope + (size CTIEnvelopeFormat * 2)

voiceIntensityOffsetTable	nptr	\
	offset	voiceIntensity,
	offset	voiceIntensity + size VoiceTimbre,
	offset	voiceIntensity + (size VoiceTimbre * 2)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDVoiceOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off a voice

CALLED BY:	Strategy routine
PASS:		cx	-> voice # to turn off
		ds	-> dgroup of driver

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		silences a voice

PSEUDO CODE/STRATEGY:
		set voiceIntensity and metalLevel to zero		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		.assert size VoiceVolumeFrequencyNode	eq	8
TDVoiceOff	proc	near
	uses	ax, cx, di, es
	.enter
	;
	;  Make sure we are responding to a legal voice
	;
	cmp	cx, VOICE_COUNT
	jae	done

processNoteOff::
	mov	si, cx				; si <- voice #
	shl	si, 1				; si <- voice # * size word

	mov	di, cs:voiceEnvelopeOffsetTable[si]
	mov	si, cs:voiceIntensityOffsetTable[si]

	clr	bx				; set "volume" to zero
	call	TDSetVoiceNoiseLevel

	czr	bx, ds:[si].VT_timbre1.VVFN_vol	; set volume to zero
	czr	bx, ds:[si].VT_timbre1.VVFN_vol	; set volume to zero
	czr	bx, ds:[si].VT_timbre1.VVFN_vol	; set volume to zero

	;
	;  Update the voice list
	lea	bx, [si].VT_timbre1		; ds:bx <- voice to remove
	call	TDRemoveVoiceFromList		; remove from list

	lea	bx, [si].VT_timbre2		; ds:bx <- voice to remove
	call	TDRemoveVoiceFromList		; remove from list

	lea	bx, [si].VT_timbre3		; ds:bx <- voice to remove
	call	TDRemoveVoiceFromList		; remove from list


	mov	di, si				; di <- base of voice

	;
	;  Remember to get new head of list for each insert,
	;	as the head of list could have changed when we
	;	inserted the previous voice...

						; ds:bx <- voice to insert
	mov	si, ds:[headOfList].VVFN_next	; ds:si <- start of list
	call	TDAddVoiceToList		; insert into correct place


	lea	bx, [di].VT_timbre2		; ds:bx <- voice to insert
	mov	si, ds:[headOfList].VVFN_next	; ds:si <- start of list
	call	TDAddVoiceToList		; insert into correct place

	lea	bx, [di].VT_timbre1		; ds:bx <- voice to insert
	mov	si, ds:[headOfList].VVFN_next	; ds:si <- start of list
	call	TDAddVoiceToList		; insert into correct place

	;
	;  Turn on the correct voices...
	call	TDSetVoices	

done:
	.leave
	ret
TDVoiceOff	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDEnvelope
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set Timbral Information for a voice

CALLED BY:	Strategy Routine

PASS:		bx:si	-> buffer containing envelope info
		cx	-> voice to alter

RETURN:		carry if ok
		carry set if unsupported envelope format

DESTROYED:	ds (saved by strategy routine)

SIDE EFFECTS:	
		Sets up a voice to play with a given timbre information.

PSEUDO CODE/STRATEGY:
		copy the envelope into our idata		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		.assert size CTIEnvelopeFormat	eq	4
TDEnvelope	proc	near
	uses	bx,cx,si,di,es
	.enter
	;
	;  First, make sure we are dealing with a legal voice
	;
	cmp	cx, VOICE_COUNT
	jae	done

	tst	bx				; standard or non-standard?
	jnz	copySetting

	mov	bx, cs
	shl	si, 1				; si <- si * 2
	shl	si, 1				; si <- si * CTIEnvelopeFormat
	add	si, offset InstrumentTable

copySetting:
	;
	;  Copy the envelope settings into dgroup.  Do with
	;  by way of a string copy.
	;
	mov	es, bx				; es:di <- envelope descript.
	mov	di, si

	mov	si, cx
	mov	si, cs:voiceEnvelopeOffsetTable[si]

	mov	ax, es:[di]			; ax <- 1st, 2nd harmonic
	stosw

	mov	ax, es:[di]+2			; ax <- 3rd harmonic, noise
	stosw

done:
	.leave
	ret
TDEnvelope	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDSetVoices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set frequencies and volumes for voices

CALLED BY:	TDVoiceOn, TDVoiceOff, TDSilence

PASS:		ds	-> dgroup of driver

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		allocates the 3 FM voices and the noise generator
		to the 3 loudest frequencies and the loudest noise
		generator

PSEUDO CODE/STRATEGY:
		Read off 1st three voices on the list and
			stuff them onto the hardware
		Read off loudest noise generator and stuff
			it on the hardware

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
			.assert size VoiceVolumeFrequencyNode eq 8
TDSetVoices	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter
EC<	mov	ax, ds						>
EC<	cmp	ax, segment dgroup				>
EC<	ERROR_NE -1						>

	clr	bx					; bx <- offset "voice1"
	mov	cx,VOICE_COUNT				; cx <- # of voices

	mov	si, ds:[headOfList].VVFN_next		; si <- 1st voice

topOfLoop:
	;
	;  Before we reprogram the voice, we turn it
	;	off.  Why?  Well, casio seemed to
	;	think it was a good idea, and hey,
	;	who am I to argue?  :)
	clr	al					; al <- no volume

	mov	dx, cs:volumeVoicePort[bx]		; dx <- port for voice
	out	dx, al

	;
	;	Now, set first the fine-tune, then the course tune.
	mov	dx, cs:fineTuneVoicePort[bx]		; dx <- port for voice
	mov	ax, ds:[si].VVFN_freq			; ax <- freq setting

	out	dx, al		; send the fine-tune setting
	jmp	$+2

	mov	dx, cs:coarseTuneVoicePort[bx]
	mov	al, ah
	out	dx, al		; send the course-tune setting
	jmp	$+2

	;
	;  Finally, set the 4-bit volume level of the voice
	mov	ax, ds:[si].VVFN_vol			; ax <- 4-bit volume

	mov	dx, cs:volumeVoicePort[bx]		; dx <- port for voice
	out	dx, al		; send the volume setting

	add	bx, size word
	loop	topOfLoop

setNoise::
	;
	;  Now, set the metal level for the voice
	mov	si, ds:[headOfNoiseList].VVFN_next	; si <- loudest noise

	mov	ax, ds:[si].VVFN_vol			; ax <- 4-bit volume

	mov	dx, NOISE_AMPLITUDE_PORT		; set new level
	out	dx, al

	mov	ax, ds:[si].VVFN_freq			; ax <- noise "color"

	mov	dx, NOISE_FILTER_PORT			; set new filter
	out	dx, al

	.leave
	ret
TDSetVoices	endp


volumeVoicePort	word	CHANNEL_A_AMPLITUDE_PORT,	; Channel A Amplitude
			CHANNEL_B_AMPLITUDE_PORT,	; Channel B Amplitude
			CHANNEL_C_AMPLITUDE_PORT	; Channel C Amplitude

fineTuneVoicePort word	CHANNEL_A_FINE_TUNE_PORT,	; Fine-Tune Channel A
			CHANNEL_B_FINE_TUNE_PORT,	; Fine-Tune Channel B
			CHANNEL_C_FINE_TUNE_PORT	; Fine-Tune Channel C

coarseTuneVoicePort word CHANNEL_A_COARSE_TUNE_PORT,	; Course-Tune Channel A
			 CHANNEL_B_COARSE_TUNE_PORT,	; Course-Tune Channel B
			 CHANNEL_C_COARSE_TUNE_PORT	; Course-Tune Channel C

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDSetVoiceNoiseLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the noise generator for the given type and volume

CALLED BY:	TDVoiceOn, TDVoiceOff

PASS:		ds:si	-> voiceIntensity for voice
		ds:di	-> voiceEnvelope for voice
		cx	-> voice to set
		bx	-> voice volume

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		Set up noiseIntensity to match passes parameters

PSEUDO CODE/STRATEGY:

		Determine filter.
		Save filter.
		Determine volume.
		Save volume.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDSetVoiceNoiseLevel	proc	near
	uses	ax, bx, cx, dx
	.enter
	mov	dx, bx					; ax <- volume

	;
	;  Is voice even playing?
	tst	dx
	jz	storeVolume

	;
	;  Does voice have noise component?
	test	ds:[di].CTIEF_noise, mask NS_type
	jz	storeVolume

	mov	si, cx					; si <- voice
	shl	si, 1					; si <- word offset
	mov	si, cs:noiseLevelOffsetTable[si]	; si <- voice offset

	;
	;  Determine filter type
	mov	al, ds:[di].CTIEF_noise			; ax <- noise setting
	and	ax, mask NS_type			; ax <- noise type
	rol	al, 1					; ax <- hardware value

	mov	ds:[si].VVFN_freq, ax			; save filter type

	;
	;  Determine volume level
	mov	al, ds:[di].CTIEF_noise			; ax <- noise setting
	and	ax, mask NS_partialLevel		; ax <- intensity

	mul	bx
	and	dx, 0000fh				; dx <- 4-bit volume

	rol	dx, 1
	rol	dx, 1
	rol	dx, 1
	rol	dx, 1

storeVolume:
	mov	ds:[si].VVFN_vol, dx			; save volume

	mov	bx, si					; ds:bx <- voice
	call	TDRemoveVoiceFromList

	mov	si, ds:[headOfNoiseList].VVFN_next	; ds:si <- list
	call	TDAddVoiceToList

	.leave
	ret
TDSetVoiceNoiseLevel	endp

noiseLevelOffsetTable	nptr	offset noiseIntensity.VT_timbre1,
				offset noiseIntensity.VT_timbre2,
				offset noiseIntensity.VT_timbre3

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDAddVoiceToList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add node to list, where list is sorted loudest to quietest

CALLED BY:	INTERNAL

PASS:		ds:si	-> list to add to
		ds:bx	-> node to add to list

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	adds node to list in propper order

PSEUDO CODE/STRATEGY:
		TDan list until we find node with volume less
		than ours.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDAddVoiceToList	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;
	;  Get the volume of our node in a register
	;	so comparisons are quick.
	mov	ax, ds:[bx].VVFN_vol			; ax <- 4-bit vol.

topOfLoop:

	;
	;  See if we are louder than the node under
	;	examination.
	cmp	ax, ds:[si].VVFN_vol
	ja	addHere

	;
	;  Well, we aren't.  Get the next node to
	;	examine.
	mov	si, ds:[si].VVFN_next

	;
	;  See if we have reached the end of the list.
	;  We have if the next field of the node
	;  is equal to the node itself.
	cmp	si, ds:[si].VVFN_next
	jne	topOfLoop

addHere:
	;
	;  Set up our next/prev fields and adjust
	;  next/prev nodes to access our node.
	mov	ds:[bx].VVFN_next, si			; set our new next

	mov	di, bx					; di <- our offset
	xchg	di, ds:[si].VVFN_prev			; get & set prev offset

	mov	ds:[bx].VVFN_prev, di			; set our new prev

	mov	ds:[di].VVFN_next, bx			; set prev's next

	.leave
	ret
TDAddVoiceToList	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDRemoveVoiceFromList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a VFFN from the linked list

CALLED BY:	INTERNAL

PASS:		ds:bx	-> voice to remove

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		moves node from list

PSEUDO CODE/STRATEGY:
		set prev next node to next
		set next prev node to prev

		set our next to endOfList
		set our prev to headOfList

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDRemoveVoiceFromList	proc	near
	uses	ax, si
	.enter
	;
	;  Set following node's previous field to our previous
	mov	si, ds:[bx].VVFN_next			; ds:si <- next node

	mov	ax, ds:[bx].VVFN_prev			; ax <- our prev
	mov	ds:[si].VVFN_prev, ax			; set to our prev

	;
	;  Set predecesor's next field to our next field
	mov	si, ds:[bx].VVFN_prev			; ds:si <- prev node

	mov	ax, ds:[bx].VVFN_next			; ax <- our next
	mov	ds:[si].VVFN_next, ax			; set to our next

	;
	;  Mark our prev/next to be head/tail of list
	mov	ds:[bx].VVFN_prev, offset headOfList	; set prev to head
	mov	ds:[bx].VVFN_next, offset tailOfList	; set next to tail
	.leave
	ret
TDRemoveVoiceFromList	endp

;-----------------------------------------------------------------------------
;
;	Voice Patch Info
;
;-----------------------------------------------------------------------------

					; piano 1
InstrumentTable	CTIEnvelopeFormat	< 255, 30, 10, <NT_WHITE_NOISE, 10>>,
					< 255, 30, 10, <NT_WHITE_NOISE, 10>>,
					< 255, 30, 10, <NT_WHITE_NOISE, 10>>,
					< 255, 30, 10, <NT_WHITE_NOISE, 10>>,
					< 255, 30, 10, <NT_WHITE_NOISE, 10>>,
					< 255, 30, 10, <NT_WHITE_NOISE, 10>>,
					< 255, 30, 10, <NT_WHITE_NOISE, 10>>,
					< 255, 30, 10, <NT_WHITE_NOISE, 10>>,

					; celesta 1
					< 255, 50, 10, <NT_METAL_NOISE, 32>>,
					< 255, 50, 10, <NT_METAL_NOISE, 32>>,
					< 255, 50, 10, <NT_METAL_NOISE, 32>>,
					< 255, 50, 10, <NT_METAL_NOISE, 32>>,
					< 255, 50, 10, <NT_METAL_NOISE, 32>>,
					< 255, 50, 10, <NT_METAL_NOISE, 32>>,
					< 255, 50, 10, <NT_METAL_NOISE, 32>>,
					< 255, 50, 10, <NT_METAL_NOISE, 32>>,

					; organ 1
					< 255, 30, 20, <   NT_NO_NOISE,  0>>,
					< 255, 30, 20, <   NT_NO_NOISE,  0>>,
					< 255, 30, 20, <   NT_NO_NOISE,  0>>,
					< 255, 30, 20, <   NT_NO_NOISE,  0>>,
					< 255, 30, 20, <   NT_NO_NOISE,  0>>,
					< 255, 30, 20, <   NT_NO_NOISE,  0>>,
					< 255, 30, 20, <   NT_NO_NOISE,  0>>,
					< 255, 30, 20, <   NT_NO_NOISE,  0>>,

					; elec guit 1
					< 255,  6, 20, <NT_METAL_NOISE, 20>>,
					< 255,  6, 20, <NT_METAL_NOISE, 20>>,
					< 255,  6, 20, <NT_METAL_NOISE, 20>>,
					< 255,  6, 20, <NT_METAL_NOISE, 20>>,
					< 255,  6, 20, <NT_METAL_NOISE, 20>>,
					< 255,  6, 20, <NT_METAL_NOISE, 20>>,
					< 255,  6, 20, <NT_METAL_NOISE, 20>>,
					< 255,  6, 20, <NT_METAL_NOISE, 20>>,

					; bass 1
					< 200,  6, 10, <NT_METAL_NOISE, 20>>,
					< 200,  6, 10, <NT_METAL_NOISE, 20>>,
					< 200,  6, 10, <NT_METAL_NOISE, 20>>,
					< 200,  6, 10, <NT_METAL_NOISE, 20>>,
					< 200,  6, 10, <NT_METAL_NOISE, 20>>,
					< 200,  6, 10, <NT_METAL_NOISE, 20>>,
					< 200,  6, 10, <NT_METAL_NOISE, 20>>,
					< 200,  6, 10, <NT_METAL_NOISE, 20>>,

					; violin 1	
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,

					; ensamble 1
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,
					< 255, 16, 20, <NT_METAL_NOISE, 10>>,

					; brass
					< 255, 46, 20, <NT_WHITE_NOISE, 20>>,
					< 255, 46, 20, <NT_WHITE_NOISE, 20>>,
					< 255, 46, 20, <NT_WHITE_NOISE, 20>>,
					< 255, 46, 20, <NT_WHITE_NOISE, 20>>,
					< 255, 46, 20, <NT_WHITE_NOISE, 20>>,
					< 255, 46, 20, <NT_WHITE_NOISE, 20>>,
					< 255, 46, 20, <NT_WHITE_NOISE, 20>>,
					< 255, 46, 20, <NT_WHITE_NOISE, 20>>,

					; reed 1
					< 255,255, 20, <NT_WHITE_NOISE, 30>>,
					< 255,255, 20, <NT_WHITE_NOISE, 30>>,
					< 255,255, 20, <NT_WHITE_NOISE, 30>>,
					< 255,255, 20, <NT_WHITE_NOISE, 30>>,
					< 255,255, 20, <NT_WHITE_NOISE, 30>>,
					< 255,255, 20, <NT_WHITE_NOISE, 30>>,
					< 255,255, 20, <NT_WHITE_NOISE, 30>>,
					< 255,255, 20, <NT_WHITE_NOISE, 30>>,

					; flute
					< 180,255,120, <   NT_NO_NOISE, 0>>,
					< 180,255,120, <   NT_NO_NOISE, 0>>,
					< 180,255,120, <   NT_NO_NOISE, 0>>,
					< 180,255,120, <   NT_NO_NOISE, 0>>,
					< 180,255,120, <   NT_NO_NOISE, 0>>,
					< 180,255,120, <   NT_NO_NOISE, 0>>,
					< 180,255,120, <   NT_NO_NOISE, 0>>,
					< 180,255,120, <   NT_NO_NOISE, 0>>,

					; syn 1
					< 255,  0,  0, <   NT_NO_NOISE, 0>>,
					< 255,  0,  0, <   NT_NO_NOISE, 0>>,
					< 255,  0,  0, <   NT_NO_NOISE, 0>>,
					< 255,  0,  0, <   NT_NO_NOISE, 0>>,
					< 255,  0,  0, <   NT_NO_NOISE, 0>>,
					< 255,  0,  0, <   NT_NO_NOISE, 0>>,
					< 255,  0,  0, <   NT_NO_NOISE, 0>>,
					< 255,  0,  0, <   NT_NO_NOISE, 0>>,

					; syn 9
					< 200, 60,  0, <NT_WHITE_NOISE, 20>>,
					< 200, 60,  0, <NT_WHITE_NOISE, 20>>,
					< 200, 60,  0, <NT_WHITE_NOISE, 20>>,
					< 200, 60,  0, <NT_WHITE_NOISE, 20>>,
					< 200, 60,  0, <NT_WHITE_NOISE, 20>>,
					< 200, 60,  0, <NT_WHITE_NOISE, 20>>,
					< 200, 60,  0, <NT_WHITE_NOISE, 20>>,
					< 200, 60,  0, <NT_WHITE_NOISE, 20>>,

					; laser
					<  50,100,150, <NT_METAL_NOISE, 16>>,
					<  50,100,150, <NT_METAL_NOISE, 16>>,
					<  50,100,150, <NT_METAL_NOISE, 16>>,
					<  50,100,150, <NT_METAL_NOISE, 16>>,
					<  50,100,150, <NT_METAL_NOISE, 16>>,
					<  50,100,150, <NT_METAL_NOISE, 16>>,
					<  50,100,150, <NT_METAL_NOISE, 16>>,
					<  50,100,150, <NT_METAL_NOISE, 16>>,

					; percussive
					< 100, 20, 20, <NT_WHITE_NOISE, 60>>,
					< 100, 20, 20, <NT_WHITE_NOISE, 60>>,
					< 100, 20, 20, <NT_WHITE_NOISE, 60>>,
					< 100, 20, 20, <NT_WHITE_NOISE, 60>>,
					< 100, 20, 20, <NT_WHITE_NOISE, 60>>,
					< 100, 20, 20, <NT_WHITE_NOISE, 60>>,
					< 100, 20, 20, <NT_WHITE_NOISE, 60>>,
					< 100, 20, 20, <NT_WHITE_NOISE, 60>>,

					; sound FX
					<  30, 60, 30, <NT_METAL_NOISE, 32>>,
					<  30, 60, 30, <NT_METAL_NOISE, 32>>,
					<  30, 60, 30, <NT_METAL_NOISE, 32>>,
					<  30, 60, 30, <NT_METAL_NOISE, 32>>,
					<  30, 60, 30, <NT_METAL_NOISE, 32>>,
					<  30, 60, 30, <NT_METAL_NOISE, 32>>,
					<  30, 60, 30, <NT_METAL_NOISE, 32>>,
					<  30, 60, 30, <NT_METAL_NOISE, 32>>,

					; snare 1
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>,
					<   0,  0,  0, <NT_METAL_NOISE, 63>>


ResidentCode	ends
