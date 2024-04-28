COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userUtils.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

DESCRIPTION:
	This file contains utility user interface routines, which are
	not associated with a particular object class or group
	(i.e. don't belong in genUtils.asm or visUtils.asm).


	$Id: userUtils.asm,v 1.1 97/04/07 11:46:14 newdeal Exp $

------------------------------------------------------------------------------@
NUM_STANDARD_SOUNDS equ 7

include Internal/prodFeatures.def
include Internal/patch.def

udata	segment
standardSoundHandles		word	NUM_STANDARD_SOUNDS dup (?)
;
;	The handles to the SoundControl blocks for each of the
;	StandardSoundTypes.
;

standardSoundCounts		word	NUM_STANDARD_SOUNDS dup (?)
;
;	Count ID for each standard sounds, to be returned by
;	UserStandardSound and passed to UserStopStandardSound.
;	The counts are guaranteed non-zero when the sound is played at
;	least once.
;


contextRegistrationCount	word
;
;	The count of how many objects are relying on getting context
;	notifications when the selection changes.
;

udata	ends

STD_ERROR_VOICES = 1
StdSoundErrorBeep	segment resource


	VOICE_HIGH = DYNAMIC_FFFF
	VOICE_LOW  = DYNAMIC_FFF



SimpleSoundHeader 	STD_ERROR_VOICES

		ChangePriority	<SP_SYSTEM_LEVEL + SP_IMMEDIATE>
		ChangeEnvelope	0, IP_TRUMPET
		DeltaTick	1
		VoiceOn		0, SS_MULTIPLIER*500, VOICE_HIGH	; 3 tick beep
		DeltaTick	3
		VoiceOff	0			; 2 tick pause
		DeltaTick	2
		VoiceOn		0, SS_MULTIPLIER*500, VOICE_HIGH	; 3 tick beep
		DeltaTick	3
		VoiceOff	0			; 2 tick pause
		DeltaTick	2
		VoiceOn		0, SS_MULTIPLIER*500, VOICE_HIGH	; 3 tick beep
		DeltaTick	3
		VoiceOff	0
		General		GE_END_OF_SONG

StdSoundErrorBeep	ends

STD_WARNING_VOICES = 1
StdSoundWarningBeep	segment resource


SimpleSoundHeader STD_WARNING_VOICES

		ChangePriority	<SP_SYSTEM_LEVEL + SP_IMMEDIATE>
		ChangeEnvelope	0, IP_REED_ORGAN
		DeltaTick	1
		VoiceOn		0, SS_MULTIPLIER*200, VOICE_HIGH
		DeltaTick	15
		VoiceOff	0
		General		GE_END_OF_SONG

StdSoundWarningBeep	ends

STD_NOTIFY_VOICES = 1
StdSoundNotifyBeep	segment resource

SimpleSoundHeader STD_NOTIFY_VOICES

		ChangePriority	<SP_SYSTEM_LEVEL>
		ChangeEnvelope	0, IP_TUBULAR_BELLS
		DeltaTick	1
		VoiceOn		0, SS_MULTIPLIER*400, VOICE_LOW	; 5 tick beep
		DeltaTick	5
		VoiceOff	0			; 2 tick pause
		DeltaTick	2
		VoiceOn		0, SS_MULTIPLIER*400, VOICE_HIGH	; 5 tick beep
		DeltaTick	5
		VoiceOff	0
		General		GE_END_OF_SONG

StdSoundNotifyBeep	ends

STD_NO_INPUT_VOICES = 1
StdSoundNoInputBeep		segment resource

SimpleSoundHeader STD_NO_INPUT_VOICES

		ChangePriority	<SP_SYSTEM_LEVEL>
		ChangeEnvelope	0, IP_OVERDRIVEN_GUITAR
		DeltaTick	1
		VoiceOn		0, SS_MULTIPLIER*800, VOICE_LOW	; 1.25 tick beep
		DeltaMS		20
		VoiceOff	0			; no  pause
		VoiceOn		0, SS_MULTIPLIER*500, VOICE_HIGH	; 1.25 tick beep
		DeltaMS		20
		VoiceOff	0
		General		GE_END_OF_SONG

StdSoundNoInputBeep		ends

STD_KEY_CLICK_VOICES = 1
StdSoundKeyClick		segment resource

SimpleSoundHeader STD_KEY_CLICK_VOICES

		ChangePriority	<SP_SYSTEM_LEVEL + SP_THEME>
		ChangeEnvelope	0, IP_REED_ORGAN
		DeltaTick	1
		VoiceOn		0, SS_MULTIPLIER*200, VOICE_LOW	; .35 tick beep
		DeltaMS		5
		VoiceOff	0
		General		GE_END_OF_SONG

StdSoundKeyClick		ends

STD_ALARM_VOICES = 1
StdSoundAlarm			segment resource

SimpleSoundHeader STD_ALARM_VOICES = 1

	;
	; other products
	;
	ChangePriority	<SP_SYSTEM_LEVEL + SP_IMMEDIATE>
        ChangeEnvelope  0, IP_FLUTE
        DeltaTick       1
        VoiceOn         0, SS_MULTIPLIER*HIGH_A, VOICE_LOW
        DeltaTick       8
        VoiceOff        0
        DeltaTick       2
        VoiceOn         0, SS_MULTIPLIER*HIGH_G, VOICE_LOW
        DeltaTick       8
        VoiceOff        0
        DeltaTick       2
        VoiceOn         0, SS_MULTIPLIER*HIGH_F, VOICE_LOW
        DeltaTick       8
        VoiceOff        0
        DeltaTick       2
        VoiceOn         0, SS_MULTIPLIER*HIGH_A, VOICE_LOW
        DeltaTick       8
        VoiceOff        0
        DeltaTick       2
        VoiceOn         0, SS_MULTIPLIER*HIGH_G, VOICE_LOW
        DeltaTick       8
        VoiceOff        0
        DeltaTick       2
        VoiceOn         0, SS_MULTIPLIER*HIGH_F, VOICE_LOW
        DeltaTick       8
        VoiceOff        0
        DeltaTick       2
        VoiceOn         0, SS_MULTIPLIER*HIGH_A, VOICE_LOW
        DeltaTick       8
        VoiceOff        0
        DeltaTick       2
        VoiceOn         0, SS_MULTIPLIER*HIGH_G, VOICE_LOW
        DeltaTick       10
        VoiceOff        0
        DeltaTick       2
        VoiceOn         0, SS_MULTIPLIER*HIGH_F, VOICE_LOW
        DeltaTick       12
        VoiceOff        0
        General         GE_END_OF_SONG


StdSoundAlarm			ends

STD_NO_HELP_VOICES = 1
StdSoundNoHelpBeep		segment resource

SimpleSoundHeader STD_NO_HELP_VOICES

		ChangePriority	<SP_SYSTEM_LEVEL>
		ChangeEnvelope	0, IP_OVERDRIVEN_GUITAR
		DeltaTick	1
		VoiceOn		0, SS_MULTIPLIER*800, VOICE_LOW	; 1.25 tick beep
		DeltaMS		20
		VoiceOff	0			; no  pause
		VoiceOn		0, SS_MULTIPLIER*500, VOICE_HIGH	; 1.25 tick beep
		DeltaMS		20
		VoiceOff	0
		General		GE_END_OF_SONG

StdSoundNoHelpBeep		ends


UserSound segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlayStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays a standard sound.

CALLED BY:	UserStandardSound
PASS:		di  - StandardSoundType

		(SST_      BUFFER           NOTE      SOUND
		(dx - segment of buffer / duration  / tempo  )
		(si - offset of buffer  /   --      /  --    )
		(cx - size of buffer    / frequency / handle )
		(The buffer pointed by dx:si *cannot* be in the movable XIP
			code resource.)
		ds - dgroup
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/21/90		Initial version
	TS	9/17/92		move to new sound library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

STANDARD_TEMPO		equ	8
STANDARD_PRIORITY	equ	SP_SYSTEM_LEVEL

PlayStandardSound	proc	far
	uses	ax, bx, cx, dx, ds, di
	.enter
EC <	cmp	di, StandardSoundType				>
EC <	ERROR_GE	-1					>

ifdef PLAY_WAV_FOR_ERRORS
	cmp	di, SST_NO_INPUT
	mov	bx, UIS_NO_INPUT
	je	playWAV
	cmp	di, SST_NO_HELP
	mov	bx, UIS_NO_HELP
	je	playWAV
endif

	cmp	di, SST_CUSTOM_SOUND		;Similar for the custom stream
	je	customSound

	cmp	di, SST_CUSTOM_NOTE		; if a custom note, branch
	je	customNote

	cmp	di, SST_CUSTOM_BUFFER		;If a custom sound, branch
	je	customBuffer

	mov	bx, segment udata		; bx <- dgroup of UI
	mov	ds, bx				; ds <- dgroup of UI

	shl	di				;DI <- offset into list of
						;standardSoundStreamHandles

	tst	ds:[standardSoundHandles]	;Is there anything there?
	jnz	loadHandle

	call	SetUpStandardSounds		; destroys ax, bx

loadHandle:
	mov	bx, ds:standardSoundHandles[di]
	mov	ax, STANDARD_PRIORITY + SP_IMMEDIATE

generateSound:
	mov	dl, mask EOSF_UNLOCK
	call	SoundPlayMusic

done:
	.leave
	ret

ifdef PLAY_WAV_FOR_ERRORS
playWAV:
	push	es
	sub	sp, size GeodeToken
	segmov	es, ss
	mov	di, sp
	push	bx			; save UIS_
	mov	ax, GGIT_TOKEN_ID
	mov	bx, handle 0
	call	GeodeGetInfo
	mov	cx, es
	mov	dx, di
	pop	bx			; bx = UIS_
	call	WavPlayInitSound
	add	sp, size GeodeToken
	pop	es
	jmp	done
endif

customSound:
	mov	ax, SP_SYSTEM_LEVEL		; ax <- priority
	mov	bx, cx				; bx <- stream handle
	mov	cx, dx				; cx <- tempo setting
	jmp	short generateSound

customNote:
	push	si				; save trashed register

	movdw	bxsi, IP_REED_ORGAN		; bx:si <- instrument
	mov_tr	ax, cx				; ax <- frequency
	mov	cx, DYNAMIC_MF			; cx <- volume
	mov	di, dx				; di <- duration
	mov	dx, SSDTT_TICKS			; dx <- duration type
	call	SoundAllocMusicNote

	pop	si				; restore trashed register
	jc	done				; out of memory?

	mov	ax, STANDARD_PRIORITY
	mov	dl, mask EOSF_UNLOCK or mask EOSF_DESTROY  ; dl <- EOS flags
	call	SoundPlayMusicNote
	jmp	done

customBuffer:
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, dx						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	push	cx				; save size

	;
	;  Allocate a block large enough to hold music and
	;	SimpleSoundHeader for one voice.  Make ourselves
	;	the owner, so it doesn't go away if calling
	;	thread exits.
	mov_tr	ax, cx				; ax <- size
	add	ax, size SoundControl + size SoundVoiceStatus
	mov	cx, mask HF_DISCARDABLE or mask HF_SHARABLE or \
		    (mask HAF_LOCK) shl 8

	mov	bx, handle 0			; have UI own it.
	call	MemAllocSetOwner	; bx <- handle of block allocated

	pop	cx				; restore size

	jc	done				; check for not enough memory

	push	si, es				; save trashed registers

	;
	;  Copy buffer from provided buffer to new block
	mov	ds, dx				; ds:si <- buffer
	mov	es, ax				; es:di <- destination
	mov	di, size SoundControl + size SoundVoiceStatus

	shr	cx, 1
	jnc	copyWords
	movsb
copyWords:
	rep	movsw				; copy buffer

	;
	;  Initialize new sound block
	;
	mov	cx, 1				; one voice
	call	SoundInitMusic			; init this block

	mov	ax, STANDARD_PRIORITY
	mov	cx, STANDARD_TEMPO
	mov	dl, mask EOSF_UNLOCK or mask EOSF_DESTROY
	call	SoundPlayMusic			; play it & destory it when

	pop	si, es				; restore trashed registers
	jmp	done				; finished
PlayStandardSound	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpStandardSounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create four simple sound streams for the system noises

CALLED BY:	Entry routine
PASS:		ds	-> dgroup of ui
RETURN:		nothing
DESTROYED:	ax,bx
SIDE EFFECTS:
		creates four SimpleSoundStreams to use in PlayStandardSound
PSEUDO CODE/STRATEGY:
		call SoundStreamAllocSimple for each sound

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpStandardSounds	proc	near
	uses	cx, si
	.enter

EC <	push	ax, bx							>
EC <	mov	bx, ds							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	ax, bx							>

	;
	;  Each standard stream has but one voice and should
	;  be owned by the UI.  NOT the 1st thread that runs
	;  through here.
	mov	cx, length handleSSTTable		; cx <- # of SST sounds
	clr	si					; si <- offset of 1t

topOfLoop:
	push	cx					; save count

	mov	bx, cs:handleSSTTable[si]		; bx <- handle of sound
	mov	cx, cs:voicesSSTTable[si]		; cx <- # of voices
	call	SoundInitMusic

	mov	ds:standardSoundHandles[si], bx

	mov	ax, handle 0				; owned by UI
	call	SoundChangeOwner

	inc	si					; index next handle
	inc	si

	pop	cx
	loop	topOfLoop


	.leave
	ret
SetUpStandardSounds	endp

	.assert NUM_STANDARD_SOUNDS eq 7
handleSSTTable	hptr	handle StdSoundErrorBeep,
			handle StdSoundWarningBeep,
			handle StdSoundNotifyBeep,
			handle StdSoundNoInputBeep,
			handle StdSoundKeyClick,
			handle StdSoundAlarm,
			handle StdSoundNoHelpBeep

	.assert NUM_STANDARD_SOUNDS eq 7
voicesSSTTable	word	STD_ERROR_VOICES,
			STD_WARNING_VOICES,
			STD_NOTIFY_VOICES,
			STD_NO_INPUT_VOICES,
			STD_KEY_CLICK_VOICES,
			STD_ALARM_VOICES,
			STD_NO_HELP_VOICES



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_UserStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C Stub for UserStandardSound

CALLED BY:	word _cdecl UserStandardSound(StandardSoundType type, ...)
RETURN:		countID for the standard sound

PSEUDO CODE/STRATEGY:
		_cdecl has arguments pushed from right to left,
			indicating that the first argument will always
			be on top.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/92		Initial version
	kho	2/26/96		Change the order of two instructions
				to get dx:si in SST_CUSTOM_BUFFER correctly.
	eca	4/19/99		Fixed si trashing with SST_CUSTOM_BUFFER

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.model medium, C
_UserStandardSound proc	far	stype:StandardSoundType,
		  		args:byte
		uses	si
		.enter
		mov	ax, ss:[stype]

		tst	ax
		jge	callIt

		cmp	ax, SST_CUSTOM_BUFFER
		je	getThreeArgs

		; it must be a custom sound

		mov	cx, {word} ss:[args]	; cx <- handle of sound / freq
		mov	dx, {word} ss:[args]+2	; dx <- starting tempo	/ dur.

callIt:
		call	UserStandardSound	; ax <- countID
		.leave
		ret

getThreeArgs:
		mov	dx, {word} ss:[args]+2		; dx:si <- buffer
		mov	si, {word} ss:[args]
		mov	cx, {word} ss:[args]+4		; cx <- size of buffer
		jmp	short callIt

_UserStandardSound endp

SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERSTOPSTANDARDSOUND
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C Stub for UserStopStandardSound

CALLED BY:	extern void _far _pascal
		UserStopStandardSound(StandardSoundType soundType,
				      word		countID)
RETURN:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
USERSTOPSTANDARDSOUND	proc	far
		.enter
	;
	; ax <- soundType, cx <- countID
	;
		C_GetTwoWordArgs	ax, cx, bx, dx	; bx, dx trashed
		call	UserStopStandardSound
		.leave
		ret
USERSTOPSTANDARDSOUND	endp

UserSound ends


Common segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		UserSendToApplicationViaProcess

DESCRIPTION:	Call the application object, but only after a method has
		been passed fully through the owning application's process.

CALLED BY:	GLOBAL (utility)

PASS:
	*ds:si	- generic object whose application object we'd like to send
		  a method to delayed via stack

	ax - Method to send to application object
	cx, dx, bp

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

UserSendToApplicationViaProcess	proc	far
	uses	bx, si, di, cx, dx, ax
	.enter
	clr	bx
	call	GeodeGetAppObject	; Get final dest = app obj in ^lbx:si
	mov	di, mask MF_RECORD
	call	ObjMessage		; record the message to deliver to it
	mov	cx, di
	mov	dx, mask MF_FORCE_QUEUE
	mov	ax, MSG_META_DISPATCH_EVENT
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret

UserSendToApplicationViaProcess	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserRegisterForTextContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers the passed object to receive context data

CALLED BY:	GLOBAL
PASS:		^lCX:DX - object to register
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserRegisterForTextContext	proc	far	uses	ax, es
	.enter
	mov	ax, segment idata
	mov	es, ax
	inc	es:[contextRegistrationCount]
EC <	ERROR_Z	TOO_MANY_REGISTERED_OBJECTS				>

	mov	ax, MSG_META_GCN_LIST_ADD
	call	AddToOrRemoveFromContextList
	.leave
	ret
UserRegisterForTextContext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserUnregisterForTextContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregisters the passed object to receive context data

CALLED BY:	GLOBAL
PASS:		^lCX:DX - object to unregister
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserUnregisterForTextContext	proc	far	uses	ax, es
	.enter
	mov	ax, segment idata
	mov	es, ax
	tst	es:[contextRegistrationCount]
EC <	ERROR_Z	OBJECT_NEVER_REGISTERED					>

	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	AddToOrRemoveFromContextList
	.leave
	ret
UserUnregisterForTextContext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERCHECKIFCONTEXTUPDATEDESIRED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if an object has registered to receive context
		changes.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax = zero if no notification desired
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
USERCHECKIFCONTEXTUPDATEDESIRED	proc	far	uses	es
	.enter
	mov	ax, segment idata
	mov	es, ax
	mov	ax, es:[contextRegistrationCount]
	.leave
	ret
USERCHECKIFCONTEXTUPDATEDESIRED	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddToOrRemoveFromContextList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the app has supplied a selection type (via the appropriate
		vardata entry), we add ourselves to the select state list.

CALLED BY:	GLOBAL
PASS:		ax - MSG_META_GCN_LIST_ADD/REMOVE
		^lcx:dx - object to add
RETURN:		nada
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddToOrRemoveFromContextList	proc	near	uses	bx, dx, bp, si
	.enter

	sub	sp, size GCNListParams
	mov	bp, sp
	movdw	ss:[bp].GCNLP_optr, cxdx
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_NOTIFY_TEXT_CONTEXT

	clr	bx
	call	GeodeGetAppObject

	mov	dx, size GCNListParams
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size GCNListParams
	.leave
	ret
AddToOrRemoveFromContextList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine takes a StandardSoundType in AX and plays the
		sound accordingly. All UI sounds should go through this
		routine, because it checks to see if the user has turned sound
		on or off.

CALLED BY:	GLOBAL
PASS:		ax - StandardSoundType

StandardSoundType	etype	word
	SST_ERROR	enum	StandardSoundType
	; Sound produced when an Error box comes up.

	SST_WARNING	enum	StandardSoundType
	; General warning beep sound

	SST_NOTIFY	enum	StandardSoundType
	; General notify beep

	SST_NO_INPUT	enum	StandardSoundType
	; Sound produced when the users keystrokes/mouse presses are not going
	; anywhere (if he clicks off a modal dialog box, or clicks on the
	; field or something)

	SST_KEY_CLICK	enum	StandardSoundType
	; Sound produced when the user presses a key on the keyboard or
	; when the user selects a key on the floating keyboard.

	SST_ALARM	enum	StandardSoundType
	; A standard alarm sound.  (ask Palm...)

	SST_NO_HELP	enum	StandardSoundType
	; Sound produced when no help is available.

	>>>>> plus, highest bit of ax inverted (or SST_??? or'd with
	SST_IGNORE_SOUND_OFF) if the sound is to be played regardless
	of [ui]sound (=off) or soundMask. <<<<<

	SST_CUSTOM_SOUND	equ	0xfffd
	; Allows applications to play a custom sound and does all the
	; checking for sound being off, etc.  This is not part of the
	; enumerated type to simplify error checking later on.
	; NOTE: The stream is given a priority of SP_SYSTEM_LEVEL.
	; If this is unacceptable, then the stream must use the general
	; commands to change the settings

	SST_CUSTOM_BUFFER	equ	0xfffe
	; Allows applications to play a custom song buffer and does all the
	; checking for sound being off, etc. This is not a part of the
	; enumerated type to simplify error checking later.
	; NOTE: The stream is given a priority of SP_SYSTEM_LEVEL
	; and the tempo set at 8 msec/128th note (rather quick...)
	; If this is unacceptable, then the stream must use the general
	; commands to change the settings.

	SST_CUSTOM_NOTE		equ	0xffff
	; Allows applications to play acustom note and does all the
	; checking for sound being off, etc.  This is not a part of
	; the enumerated type to simplify error checking later on.
	; NOTE: The note is given a priority of SP_SYSTEM_LEVEL and
	; played on a standard instrument.

	if AX=SST_CUSTOM_SOUND
			CX - sound handle
			DX - starting tempo

	if AX=SST_CUSTOM_NOTE
			CX - note frequency
			DX - note duration (in 1/60th second ticks)

	if AX=SST_CUSTOM_BUFFER,
			DX:SI - ptr to buffer of format described in sound.def
			CX    - size of buffer

RETURN:		interrupts on
		if SST_CUSTOM...
			ax = 0
		else
			ax = countID, guaranteed non-zero
					(countID is needed to call
					UserStopStandardSound)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	If sound is turned off, we might want to have some sort of stupid
	visual indication of some sound types.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/90		Initial version
	kho	8/29/95		Override "sound off" when highest bit
				is inverted. Do not work with SST_CUSTOM_???

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserStandardSound	proc	far

if	(1)	; Set to (0) to shut this dang thing up!

	uses	 bx, di, ds, cx
	.enter

	;
	; Get dgroup
	;
	mov	di, segment dgroup
	mov	ds, di
	;
	; See if we should play the sound regardless of "[ui]sound" on
	; or off: invert the highest bit, and see if we get StandardSoundType.
	;
	; SST_IGNORE_SOUND_OFF is 4 bytes!
	;
	xor	ah, SST_IGNORE_SOUND_OFF/256
	jz	play			; if ah == 0, play without checking
	xor	ah, SST_IGNORE_SOUND_OFF/256
					; if not, then SST_CUSTOM_???
					; or plain SST_??? is passed,
					; and let's change it back
EC<	cmp	ax, StandardSoundType			>
EC<	ERROR_GE	-1				>

	tst	ds:[soundDriver]
	jz	noPlay

	;
	; Check the more selective soundMask to see if we should be
	;   playing the particular sound.  Note that the "custom"
	;   standard sounds can't be masked out.
	;
	cmp	ax, StandardSoundType      ; A real standard sound type?
	jae	play
	mov	cl, al
	mov	bx, ds:[soundMask]
	shr	bx, cl
	shr	bx, 1		           ; is sound masked out
					   ; (set/clear carry)?
	jnc	noPlay			   ;   yes
play:
	;
	; Check one more thing: if global lowSoundFlag is set to true
	; in foam library, we will play one particular note, no matter
	; what is passed.
	; -- kho, 5/29/96
	;

	xchg	ax, di				;DI <- StandardSoundType
	CallMod	PlayStandardSound

	;
	; If SST_CUSTOM...: return ax = 0; else return ax = unique
	; count ID for the standard sound
	;
	cmp	di, 0
	jl	noPlay
	;
	; increment the unique count ID, and return it
	;
	shl	di
	mov	ax, ds:[standardSoundCounts][di]
increment:
	inc	ax
	jz	increment
	mov	ds:[standardSoundCounts][di], ax

quit:
	.leave
	ret
noPlay:
	clr	ax
	jmp	quit
else
	ret
endif			; if (1)
UserStandardSound	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserStopStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the standard sound being played.
		Will NOT stop SST_CUSTOM_... sounds because the sound
		handle could possibly be destroyed, and because we
		don't know what the custom handles are.

CALLED BY:	GLOBAL
PASS:		ax	= StandardSoundType
			SST_CUSTOM_... are NOT handled, but
			SST_IGNORE_SOUND_OFF bit is handled
		cx	= countID returned by UserStandardSound
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		If (countID == 0) or (SST_CUSTOM_...) {
			return
		}
		If (countID != standardSoundCounts[SST_...]) {
			return
		}
		call SoundStopMusic on sound handles found in
		standardSoundHandles

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserStopStandardSound	proc	far
		uses	ax, bx, ds, di
		.enter
	;
	; if countID invalid, just quit
	;
		jcxz	quit
	;
	; if ax has only the highest bit set
	; (ie. SST_IGNORE_SOUND_OFF) then handles it.
	; Otherwise, ax is SST_CUSTOM..., just return
	;
		clr	ah
		cmp	ax, StandardSoundType
		ja	quit
	;
	; See if countID matches standardSoundCounts[...] we have
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		mov_tr	di, ax
		shl	di			; word offset for array
		cmp	ds:[standardSoundCounts][di], cx
		jne	quit
	;
	; Call SoundStopMusic on the sound control handle
	;
		mov	bx, ds:[standardSoundHandles][di]
		call	SoundStopMusic		; carry clear if ok,
						; else ax <- SoundErrors
quit:
		.leave
		ret
UserStopStandardSound	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserCheckFoamLowSoundFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the lowSoundFlag in foam library.

CALLED BY:	(INTERNAL) UserStandardSound
PASS:		nothing
RETURN:		carry set if flag is true
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERGETSYSTEMSHUTDOWNSTATUS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine returns TRUE if system is shutting down.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax = -1 if system shutting down, 0 otherwise
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/4/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
USERGETSYSTEMSHUTDOWNSTATUS	proc	far	uses	ds
	.enter
	mov	ax, segment idata
	mov	ds, ax
	mov	ax, 0
	test	ds:[uiFlags], mask UIF_DETACHING_SYSTEM
	jz	done
	mov	ax, -1
done:
	.leave
	ret
USERGETSYSTEMSHUTDOWNSTATUS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERGETHWRLIBRARYHANDLE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the handle of the UI-loaded HWR library.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax - handle of HWR library (or 0 if not loaded/not pen mode)
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
USERGETHWRLIBRARYHANDLE	proc	far	uses	ds
	.enter
	mov	ax, segment idata
	mov	ds, ax
	mov	ax, ds:[hwrHandle]
	.leave
	ret
USERGETHWRLIBRARYHANDLE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserCreateInkDestinationInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine creates an "InkDestinationInfo" structure to
		be returned with MSG_META_QUERY_IF_PRESS_IS_INK.

CALLED BY:	GLOBAL
PASS:		cx, dx - optr
		bp - gstate for ink to be drawn through (or 0)
		ax - width/height of ink (or 0 for default)
		bx:di - virtual fptr of callback routine (to be passed to
			ProcCallFixedOrMovable) to determine whether
			a stroke is a gesture or not (BX:DI=0 if none)

RETURN:		bp - handle of IDI structure (or 0 if couldn't alloc)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserCreateInkDestinationInfo	proc	far	uses	bx, dx, ds
	.enter
if	FULL_EXECUTE_IN_PLACE
EC <	tst	bx						>
EC <	jz	continue					>
EC <	push	si						>
EC <	mov	si, di						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	pop	si						>
EC <continue:							>
endif

if	ERROR_CHECK
	tst	bp
	jz	noGState
	xchg	bx, bp
	call	ECCheckMemHandle
	xchg	bx, bp
noGState:
endif



;	Set passed object as the destination for the ink, and gstate

	pushdw	bxdi
	push	cx, ax
	mov	ax, size InkDestinationInfo
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc
	jc	allocError
	mov	ds, ax
	mov	ds:[IDI_gstate], bp
	pop	cx, ax
	popdw	ds:[IDI_gestureCallback]
	movdw	ds:[IDI_destObj], cxdx
	mov	ds:[IDI_brushSize], ax
	call	MemUnlock
	mov	bp, bx
exit:
	.leave
	ret
allocError:
	pop	cx, ax
	add	sp, size dword		;Pop callback from stack
	clr	bp
	jmp	exit
UserCreateInkDestinationInfo	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UserCopyChunkOut

DESCRIPTION:	Copy a part of a local memory chunk someplace else.

CALLED BY:	GLOBAL

PASS:
	*ds:bp - chunk to copy out

	if (cx = 0) -> a global memory block is allocated to copy to
	else if (dx = 0) -> cx = handle of lmem block to copy to
	else if (dx != 0) -> cx:dx = address to copy to (cx = segment!)

	ax - offset in chunk to start copying (inclusive)
	bx - 1 -> Add null terminator to end of copy
	     0 -> Do not add null terminator
	di - offset in chunk past end (exclusive)
		ax = 0, di = 0 -> copy entire chunk

RETURN:
	ax - chunk handle (if one created)
		*** NOTE: The copied chunk is marked as DIRTY.  The caller
			  must call ObjSetFlags or use MSG_META_SET_FLAGS to
			  set it otherwise.
	cx - number of characters copied (not including null-termination)
	ds - updated to point at segment of same block as on entry
		(only relevant if copying to lmem chunk)

DESTROYED:
	bx, dx, di, bp
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	Eric	11/89		Fixed bug: now returns ax = chunk handle

------------------------------------------------------------------------------@

UserCopyChunkOut	proc	far 	uses	si, es
	.enter
	push	bx			;save flag

	; get size of source

	mov	si, ds:[bp]		;ds:si = source ptr
	mov	bx, cx			;bx = passed cx
	ChunkSizePtr	ds, si, cx	;cx = size

	; clip offsets to valid range

	tst	di
	jz	UCCO_useEnd
	cmp	di,cx			;is end offset past the end of chunk ?
	jb	UCCO_inRange
UCCO_useEnd:
	mov	di,cx			;else clip
UCCO_inRange:

	; test for empty range to copy

	cmp	ax,di			;cmp start,end
	jb	UCCO_validCopy		;if valid then continue
	clr	ax			;return no range copied
	clr	cx
	pop	bx			;trash null termination flag
	jmp	UCCO_end
UCCO_validCopy:

	; compute real size to copy

	mov	cx,di
	sub	cx,ax			; cx = real size
	pop	di
	push	di
	add	cx,di			; add char for null-terminator if need
	add	si,ax			; si = start offset

	; test type of destination -- then get a pointer to the destination

					; bx = passed cx value
	tst	bx
	jz	UCCO_globalHandle	; branch if allocating global block:far

	tst	dx			; branch if copying to far ptr
	jnz	UCCO_farPtr

	; destination is a local memory block -- allocate the chunk

	push	ax			; save offset to start copying
	push	ds:[LMBH_handle]	; save handle of source block
	call	ObjLockObjBlock
	mov	ds, ax			; ds = dest
	mov	al, mask OCF_DIRTY
	call	LMemAlloc
	mov	di, ax

;	mov	di, ds:[di]
;	segmov	es, ds			; es:di = dest

;NEW
	segmov	es, ds			; es = destination segment

	mov	ax, bx			; save bx temp
	pop	bx			; get source block
	call	MemDerefDS		; convert back to segment
	mov	bx, ax			; restore bx
	pop	si			; recover offset to start copying
	add	si, ds:[bp]		; restore ds:si = source
	clr	bp			; DO unlock bx after move

;NEW
	mov	ax, di			; ax = new chunk handle
	mov	di, es:[di]		; es:di = destination chunk

	jmp	short UCCO_common

	; destination is a global memory block:far

UCCO_globalHandle:
	push	cx			; save size
	mov	ax,cx			; ax = size
	mov	cx,ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	pop	cx			; recover size
	mov	es,ax			; destination = es:di
	mov	ax,bx			; ax = handle
	clr	di
	clr	bp			; DO unlock bx after move
	jmp	short UCCO_common

	; destination is a far pointer

UCCO_farPtr:
	mov	es,bx
	mov	di,dx			; es:di = dest
	mov	bp, -2			; don't unlock bx after move

UCCO_common:
	pop	dx			; dx = null-termination flag
	sub	cx,dx			; don't pass nul as part of the count
	push	cx			; don't trash count
	call	CopyCommon
	pop	cx

UCCO_end:
	.leave
	ret

UserCopyChunkOut	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyCommon

DESCRIPTION:	Copy routine for UserCopyChunkOut

CALLED BY:	INTERNAL

PASS:
	ds:si - source
	es:di - dest
	cx - number of bytes to move (not including possible null-termination)
	bp - flag -> if bp=0 or bp=-1 then unlock bx after move
	dx - flag -> if dx != 0 then make last char a null-termination

RETURN:
	ax - same

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

CopyCommon	proc	near

	;ds:si = source, es:di = dest, cx = count

	rep	movsb

	; add null-termination if needed

	tst	dx
	jz	CC_noNull
	push	ax
	clr	ax
	stosb
	pop	ax
CC_noNull:

	inc	bp
	jz	CC_unlock
	dec	bp
	jnz	CC_farPtr
CC_unlock:
	push	ax
	call	MemUnlock
	pop	ax

CC_farPtr:
	ret

CopyCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserHaveProcessCopyChunkIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine figures out which process runs the dest block
		and sends MSG_PROCESS_COPY_CHUNK_IN to it.

CALLED BY:	GLOBAL
PASS:		Same parameters as MSG_PROCESS_COPY_CHUNK_IN:
		dx		- # of bytes on stack
		ss:bp		- pointer to:

		CopyChunkInFrame	struct
			CCIF_copyFlags	CopyChunkFlags
			CCIF_source	dword
			CCIF_destBlock	hptr
				(must be in an object block)
		CopyChunkInFrame	ends

RETURN:		ax - chunk handle of created chunk
		cx - # bytes copied over
		es,ds - updated if they moved (were the destination block)
DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserHaveProcessCopyChunkIn	proc	far
	uses	bx,dx,bp,si,di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ss:[bp].CCOVF_copyFlags			>
EC <		and	bx, mask CCF_MODE				>
EC <		cmp	bx, CCM_FPTR					>
EC <		jne	xipSafe						>
EC <		movdw	bxsi, ss:[bp].CCOVF_source			>
EC <		call	ECAssertValidFarPointerXIP			>
EC < xipSafe:								>
EC <		popdw	bxsi						>
endif

;	FIND OUT WHICH PROCESS IS RUNNING THE DESTINATION OBJECT BLOCK

	mov	bx, ss:[bp].CCIF_destBlock
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			;Returns ax <- id of process
						; that runs dest block.

;	SEND METHOD OFF TO PROCESS

	mov	bx, ax
	mov	ax, MSG_PROCESS_COPY_CHUNK_IN	;
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or \
				mask MF_FIXUP_ES or mask MF_STACK
	call	ObjMessage
	.leave
	ret
UserHaveProcessCopyChunkIn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserHaveProcessCopyChunkOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine figures out which process runs the source block
		and sends MSG_PROCESS_COPY_CHUNK_OUT to it. The source optr must be
		in an object block (the otherInfo field must be a thread
		handle).

CALLED BY:	GLOBAL
PASS:		Same parameters as MSG_PROCESS_COPY_CHUNK_OUT:
		dx		- # of bytes on stack
		ss:bp		- pointer to:

		CopyChunkOutFrame	struct
			CCOF_copyFlags	CopyChunkFlags
			CCOF_source	optr
			CCOF_dest	dword
		CopyChunkOutFrame	ends


RETURN:		ax - chunk handle of created chunk/block handle (if any)
		cx - # bytes copied
		es,ds - updated if they moved (were the destination block)
DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserHaveProcessCopyChunkOut	proc	far
	uses	bx,dx,bp,si,di
	.enter

;	FIND OUT WHICH PROCESS IS RUNNING THE SOURCE OBJECT BLOCK

	mov	bx,ss:[bp].CCOF_source.handle	;Get handle of source block
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			;Returns di <- id of process
						; that runs dest block.

;	SEND METHOD OFF TO PROCESS

	mov_tr	bx, ax
EC <	call	ECCheckThreadHandle					>
	mov	ax, MSG_PROCESS_COPY_CHUNK_OUT	;
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or \
					mask MF_FIXUP_ES or mask MF_STACK
	call	ObjMessage
	.leave
	ret
UserHaveProcessCopyChunkOut	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserHaveProcessCopyChunkOver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine figures out which process runs the dest block
		and sends MSG_PROCESS_COPY_CHUNK_OVER to it.

CALLED BY:	GLOBAL
PASS:		Same parameters as MSG_PROCESS_COPY_CHUNK_OVER:
		dx		- # of bytes on stack
		ss:bp		- pointer to:

		CopyChunkOVerFrame	struct
			CCOVF_copyFlags	CopyChunkFlags
			CCOVF_source	dword
			CCOVF_dest	optr
		CopyChunkOVerFrame	ends

RETURN:		cx - # bytes copied
		ax - chunk handle overwritten/created
		es,ds - updated if they moved (were the destination block)
DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserHaveProcessCopyChunkOver	proc	far
	uses	bx,dx,bp,si,di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ss:[bp].CCOVF_copyFlags			>
EC <		and	bx, mask CCF_MODE				>
EC <		cmp	bx, CCM_FPTR					>
EC <		jne	xipSafe					>
EC <		movdw	bxsi, ss:[bp].CCOVF_source			>
EC <		call	ECAssertValidFarPointerXIP			>
EC < xipSafe:								>
EC <		popdw	bxsi						>
endif

;	FIND OUT WHICH PROCESS IS RUNNING THE DEST OBJECT BLOCK

	mov	bx,ss:[bp].CCOVF_dest.handle	;Get handle of dest block
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			;Returns di <- id of process
						; that runs dest block.

;	SEND METHOD OFF TO PROCESS

	mov	bx, ax
	mov	ax, MSG_PROCESS_COPY_CHUNK_OVER	;
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or \
					mask MF_FIXUP_ES or mask MF_STACK
	call	ObjMessage
	.leave
	ret
UserHaveProcessCopyChunkOver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserCreateIconTextMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a combination icon/text moniker

CALLED BY:	EXTERNAL
PASS:		CreateIconTextMonikerParams on stack
RETURN:		^ldx:ax	= newly allocated moniker chunk
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/03/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserCreateIconTextMoniker	proc	far	\
	mParams:CreateIconTextMonikerParams
dsHandle	local	hptr		push	ds:[LMBH_handle]
gstate		local	hptr
newMoniker	local	optr
textPtr		local	fptr
textLength	local	word
textSize	local	Point
iconSize	local	Point
	uses	bx,cx,si,di,bp,es
	.enter

	; Let's first create a gstate for us to use to calculate sizes.

	cmp	ss:[mParams].CITMP_spacing, 11
	je	secondTry

	push	bp
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, bp
	pop	bp
	mov	ss:[gstate], ax
	jmp	haveGState

secondTry:
	push	di
	clr	di		; if not answered, create a GState that
	call	GrCreateState	; Assocate GState with window/null passed.
	mov	ax, di		; return in bp
	pop	di
	mov	ss:[gstate], ax

haveGState:

	; Make a copy of the icon moniker if necessary

	movdw	bxsi, ss:[mParams].CITMP_iconMoniker
	movdw	ss:[newMoniker], bxsi
	test	ss:[mParams].CITMP_flags, mask CITMF_CREATE_CHUNK
	jz	lockNewMoniker

	call	ObjLockObjBlock		; *ds:si = icon moniker
	push	bx, bp
	mov	ds, ax
	mov	cx, ss:[mParams].CITMP_destination
	mov	ss:[newMoniker].handle, cx
	clr	ax, bx, dx, di
	mov	bp, si
	call	UserCopyChunkOut	; *ds:ax = copied moniker
	pop	bx, bp
	call	MemUnlock

	mov	ss:[newMoniker].offset, ax

lockNewMoniker:
	; Lock the combination moniker and start combining

	movdw	bxsi, ss:[newMoniker]
	call	ObjLockObjBlock

	; Make sure we have a VMT_GSTRING icon moniker

	mov	ds, ax
	mov	si, ds:[si]		;ds:si = icon VisMoniker
	test	ds:[si].VM_type, mask VMT_GSTRING
	LONG jz	unlockNewMoniker

	; Get cached size and reset it and calculate moniker positions

	clr	ax
	xchg	ax, ds:[si].VM_width
	clr	bx
	xchg	bx, ds:[si].VM_data+VMGS_height

	mov	ss:[iconSize].P_x, ax
	mov	ss:[iconSize].P_y, bx

	; Get text moniker text and insert it into the new moniker.

	test	ss:[mParams].CITMP_flags, mask CITMF_TEXT_IS_FPTR
	jnz	textIsFptr

	movdw	bxdi, ss:[mParams].CITMP_textMoniker
	call	ObjLockObjBlock
	mov	es, ax
	mov	di, es:[di]
	clr	cx			;assume 0 length text
	mov	ss:[textLength], cx
	movdw	ss:[textPtr], esdi
	test	es:[di].VM_type, mask VMT_GSTRING
	jnz	insertText
	add	di, VM_data+VMT_text
	jmp	short commonFptr

textIsFptr:
	les	di, ss:[mParams].CITMP_textMoniker
commonFptr:
	movdw	ss:[textPtr], esdi
	LocalStrLength
	mov	ss:[textLength], cx

insertText:
	mov	ax, ss:[newMoniker].offset
	mov	bx, VM_data+VMGS_gstring
DBCS <	shl	cx, 1						>
	add	cx, (size OpDrawText) + (size OpMoveTo)
	call	LMemInsertAt
	; in case source text ptr is optr in same block as icon, rederef
	test	ss:[mParams].CITMP_flags, mask CITMF_TEXT_IS_FPTR
	jnz	noFixup
	push	ax
	movdw	bxdi, ss:[mParams].CITMP_textMoniker
	call	MemDerefES
	mov	di, es:[di]
	test	es:[di].VM_type, mask VMT_GSTRING
	jnz	doneFixup			; if gstring, textPtr not used
	add	di, VM_data+VMT_text
	movdw	ss:[textPtr], esdi
doneFixup:
	pop	ax
noFixup:

	push	ds
	segmov	es, ds
	mov	di, ax
	mov	di, es:[di]
	add	di, VM_data+VMGS_gstring+size OpDrawText
	lds	si, ss:[textPtr]
	mov	cx, ss:[textLength]
	LocalCopyNString
	pop	ds

	test	ss:[mParams].CITMP_flags, mask CITMF_TEXT_IS_FPTR
	jnz	afterUnlockText

	mov	bx, ss:[mParams].CITMP_textMoniker.handle
	call	MemUnlock
afterUnlockText:

	; Now calculate text size

	mov	di, ss:[gstate]
	mov	si, ss:[newMoniker].chunk
	mov	si, ds:[si]
	add	si, VM_data+VMGS_gstring+size OpDrawText ; ds:si = text
	mov	cx, ss:[textLength]
	call	GrTextWidth
	mov	ss:[textSize].P_x, dx

	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics
	mov	ss:[textSize].P_y, dx

	; Now calculate relative positions of icon and text

	mov	ax, ss:[iconSize].P_x
	mov	bx, ss:[iconSize].P_y
	mov	cx, ss:[textSize].P_x
	mov	dx, ss:[textSize].P_y
	test	ss:[mParams].CITMP_flags, mask CITMF_POSITION_ICON_ABOVE_TEXT
	jnz	vertical

horizontal::
	; Figure out horizontal positions

	test	ss:[mParams].CITMP_flags, mask CITMF_SWAP_ICON_TEXT
	jnz	swapHoriz
	mov	cx, ax
	add	cx, ss:[mParams].CITMP_spacing	; cx = text moniker x-position
	clr	ax			; ax = icon moniker x-position
	jmp	horizCommon

swapHoriz:
	mov	ax, cx
	add	ax, ss:[mParams].CITMP_spacing
	clr	cx
horizCommon:
	sub	dx, bx			; dx = difference in height
	mov	bx, 0			; bx = icon moniker y-position
	js	iconTaller
	sar	dx, 1			; center text moniker vertically
	xchg	dx, bx			; bx = icon moniker y-position
	jmp	drawText		; dx = text moniker y-position
iconTaller:
	sar	dx, 1			; center text moniker vertically
	neg	dx			; dx = text moniker y-position
	jmp	drawText

vertical:
	; Figure out vertical positions

	test	ss:[mParams].CITMP_flags, mask CITMF_SWAP_ICON_TEXT
	jnz	swapVert
	mov	dx, bx
	add	dx, ss:[mParams].CITMP_spacing	; dx = text moniker y-position
	clr	bx			; bx = icon moniker y-position
	jmp	vertCommon

swapVert:
	mov	bx, dx
	add	bx, ss:[mParams].CITMP_spacing
	clr	dx
vertCommon:
	sub	cx, ax			; cx = difference in width
	mov	ax, 0			; ax = icon moniker x-position
	js	iconWider
	sar	cx, 1			; center icon moniker horizontally
	xchg	cx, ax			; ax = icon moniker x-position
	jmp	drawText		; cx = text moniker x-position
iconWider:
	sar	cx, 1			; center text moniker horizontally
	neg	cx			; cx = text moniker x-position

drawText:
	; (ax,bx) = icon moniker position, (cx,dx) = text moniker position

	mov	si, ss:[newMoniker].chunk
	mov	si, ds:[si]
	add	si, VM_data+VMGS_gstring
	mov	ds:[si].ODT_opcode, GR_DRAW_TEXT
	mov	ds:[si].ODT_x1, cx
	mov	ds:[si].ODT_y1, dx
	mov	cx, ss:[textLength]
	mov	ds:[si].ODT_len, cx
DBCS <	shl	cx, 1						>
	add	si, size OpDrawText
	add	si, cx

	mov	ds:[si].OMT_opcode, GR_MOVE_TO
	mov	ds:[si].OMT_x1, ax
	mov	ds:[si].OMT_y1, bx

unlockNewMoniker:
	movdw	dxax, ss:[newMoniker]
	mov	bx, dx
	call	MemUnlock

	mov	di, ss:[gstate]
	call	GrDestroyState

	mov	bx, ss:[dsHandle]
	call	MemDerefDS

	.leave
	ret
UserCreateIconTextMoniker	endp

Common ends

;
;-------------
;

IniFile		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			UserGetInitFileCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to fetch .ini category for an object.
		Test application optimization flag for single category,
		to avoid recursive search if possible.

CALLED BY:	EXTERNAL
PASS:		*ds:si	- object needing .ini category
		cx:dx	- ptr to buffer needing filled
RETURN:		carry set if buffer filled (should always be the case...)
DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserGetInitFileCategory	proc	far	uses ax, bp
	class	GenApplicationClass
	.enter

	; If ATTR_GEN_USES_HIERARCHICAL_INIT_FILE_CATEGORY set on starting
	; object, recurse up to find correct category to use.
	;
	mov	ax, ATTR_GEN_USES_HIERARCHICAL_INIT_FILE_CATEGORY
	call	ObjVarFindData
	jc	recurse

	; Otherwise, check to see if app has a single .ini category that
	; we can use (instead of having to recurse like crazy)
	;
	push	si
	clr	bx				; current process
	call	GeodeGetAppObject		; get app object
	call	ObjTestIfObjBlockRunByCurThread	; see if we can lock
	clc
	jne	hardWay				; if not, do hard way

	push	di
	call	ObjSwapLock			; get access to app obj
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_optFlags, mask AOF_MULTIPLE_INIT_FILE_CATEGORIES
	jnz	multiple			; carry is clear
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock		; call app obj directly
						; carry returned set if
						; buffer filled
multiple:
	call	ObjSwapUnlock
	pop	di

hardWay:
	pop	si
	jc	done

recurse:
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
UserGetInitFileCategory	endp

IniFile		ends

;
;-------------
;

Resident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserGetDisplayType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the display type for the passed object.  Currently reads
		the global variable uiDisplayType, set by GenScreen in
		MSG_GEN_SCREEN_SET_VIDEO_DRIVER.

CALLED BY:	ConvertVisMoniker, Specific UI Init code ONLY!
		NOTE:  If you're not already using this, don't!  We're trying
		to wean people off this function...


PASS:		*ds:si - object to get the display type for
			 (for future expansion possibilities)
RETURN:		ah	- DisplayType
		al	- flag:  TRUE if displayType has been set (should only
			  be false before first screen object is put up)

DESTROYED:

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	10/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserGetDisplayType	proc	far	uses	ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax
                                                ;Get the display type
                                                ;for the system
	clr	al				;Presume not initialized
	test	ds:[uiFlags], mask UIF_HAVE_DISPLAY_TYPE
	jz	done
	dec	al				;Set flag to TRUE, to show
						;	initialized
        mov     ah, ds:[uiDisplayType]
done:
	.leave
	ret

UserGetDisplayType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserLimitDisplayTypeToStandard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	limit display type to DS_STANDARD as DS_LARGE artwork
		isn't complete

CALLED BY:	EXTERNAL

PASS:		ah - DisplayType

RETURN:		ah - modified DisplayType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserLimitDisplayTypeToStandard	proc	far
	uses	bx
	.enter
.assert DS_LARGE gt DS_STANDARD
.assert DS_HUGE gt DS_LARGE
	mov	bl, ah
	andnf	bl, mask DT_DISP_SIZE
	cmp	bl, DS_STANDARD shl offset DT_DISP_SIZE
	jbe	haveSize
	andnf	ah, not mask DT_DISP_SIZE
	ornf	ah, DS_STANDARD shl offset DT_DISP_SIZE
haveSize:
	;
	; map DAR_SQUISHED to DAR_NORMAL
	;
	mov	bl, ah
	andnf	bl, mask DT_DISP_ASPECT_RATIO
	cmp	bl, DAR_SQUISHED shl offset DT_DISP_ASPECT_RATIO
	jne	haveAspect
	andnf	ah, not mask DT_DISP_ASPECT_RATIO
		CheckHack <DAR_NORMAL eq 0>
	; If DAR_NORNAL is not 0, we have to do:
	; ornf	ah, DAR_NORMAL shl offset DT_DISP_ASPECT_RATIO
haveAspect:
	.leave
	ret
UserLimitDisplayTypeToStandard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserGetDefaultLaunchLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns InterfaceLevel

CALLED BY:	EXTERNAL

PASS:		nothing
RETURN:		ax	UIInterfaceLevel

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	8/92		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

USERGETDEFAULTLAUNCHLEVEL	proc	far	uses	ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax
	mov	ax, ds:[uiDefaultLaunchLevel]
	.leave
	ret

USERGETDEFAULTLAUNCHLEVEL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserGetDefaultUILevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns InterfaceLevel

CALLED BY:	EXTERNAL

PASS:		nothing
RETURN:		ax	UIInterfaceLevel

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	8/92		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

USERGETDEFAULTUILEVEL	proc	far	uses	ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax
	mov	ax, ds:[uiInterfaceLevel]
	.leave
	ret

USERGETDEFAULTUILEVEL	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UserGetInterfaceOptions

DESCRIPTION:	Get the interface options

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	ax - UIInterfaceOptions

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/92		Initial version

------------------------------------------------------------------------------@
USERGETINTERFACEOPTIONS	proc	far	uses ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax
	mov	ax, ds:[uiInterfaceOptions]
	.leave
	ret

USERGETINTERFACEOPTIONS	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserGetLaunchModel

DESCRIPTION:	Get the launch model

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	ax - UILaunchModel

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/23/92	Initial version

------------------------------------------------------------------------------@
USERGETLAUNCHMODEL	proc	far	uses ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax
	mov	ax, ds:[uiLaunchModel]
	.leave
	ret

USERGETLAUNCHMODEL	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserGetLaunchOptions

DESCRIPTION:	Get the UILaunchOptions

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	ax - UILaunchOptions

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/6/93		Initial version

------------------------------------------------------------------------------@
USERGETLAUNCHOPTIONS	proc	far	uses ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax
	mov	ax, ds:[uiLaunchOptions]
	.leave
	ret

USERGETLAUNCHOPTIONS	endp

Resident	ends

;
;---------------
;

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserSetDefaultMonikerFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the UI moniker font, size.
		NOTE: should only be called by the specific UI.

CALLED BY:	GLOBAL (SPUI)

PASS:
		cx	- fontID
		dx	- pointSize
RETURN:

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	10/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserSetDefaultMonikerFont	proc	far	uses	ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax
                                                ;Set the UI moniker font, size
	mov	ds:[uiDefaultMonikerFont], cx
	mov	ds:[uiDefaultMonikerPointSize], dx
	.leave
	ret
UserSetDefaultMonikerFont	endp

Init	ends

;
;---------------
;

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserGetDefaultMonikerFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the UI moniker font, size for the passed object.

CALLED BY:	GLOBAL,
		VisGetMonikerSize

PASS:		*ds:si - object to get the display type for
			 (for future expansion possibilities)
RETURN:		cx	- fontID
		dx	- pointSize

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	10/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserGetDefaultMonikerFont	proc	far	uses	ds
	.enter
	mov	cx, segment dgroup
	mov	ds, cx
                                                ;Get the UI moniker font, size
	mov	cx, ds:[uiDefaultMonikerFont]
	mov	dx, ds:[uiDefaultMonikerPointSize]
	.leave
	ret
UserGetDefaultMonikerFont	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UserCallFlow

DESCRIPTION:	Call the UI flow object

CALLED BY:	EXTERNAL

PASS:
	ax	- METHOD to pass to system object
	di	- flags as in ObjMessage
	cx, dx, bp	- data to pass on

RETURN:
	carry		- returned
	di, cx, dx, bp 	- data returned

	bx, si	- unchanged
	ds,es	- updated segments (depending on flags passed in di)

DESTROYED:
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version
------------------------------------------------------------------------------@

UserCallFlow	proc	far
	uses	bx,si
	.enter
	push	ds
	mov	bx, segment idata
	mov	ds,bx
	mov	bx, ds:[uiFlowObj].handle
	mov	si, ds:[uiFlowObj].chunk
	pop	ds

	call	ObjMessage
	.leave
	ret
UserCallFlow	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UserMessageIM

DESCRIPTION:	Send a message to the input manager

CALLED BY:	EXTERNAL

PASS:
	ax	- METHOD to pass to IM
	di	- flags as in ObjMessage
	cx, dx, bp	- data to pass on

RETURN:
	carry		- returned
	di, cx, dx, bp 	- data returned

	bx, si	- unchanged
	ds,es	- updated segments (depending on flags passed in di)

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/91		Initial version
------------------------------------------------------------------------------@

UserMessageIM	proc	far
	uses	bx
	.enter
	call	ImInfoInputProcess
	call	ObjMessage
	.leave
	ret
UserMessageIM	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UserLoadApplication

DESCRIPTION:	Loads a GEOS application.  Changes to standard application
		directory before attempting GeodeLoad on filename passed.
		Stores the filename being launched into the AppLaunchBlock,
		so that information needed to restore this application
		instance will be around later if needed.

		NOTE: Ownership of the launch block is transferred to the
		new geode and will be freed by it. If the application cannot
		be loaded, the block will be freed here. ON NO ACCOUNT SHOULD
		A PASSED AppLaunchBlock BE REFERRED TO AFTER THIS FUNCTION
		RETURNS.

CALLED BY:	GLOBAL

PASS:
	ah	- AppLaunchFlags (0 for default)
			mask ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE set if
			the actual launch should be done later by the UI, in
			a safe memory situation (no error code returned in
			this case)  If this flag is clear, then the caller
			should be calling from a fixed memory space, such
			that none of their movable code segments are locked.
			This is to provide the most favorable memory conditions
			for the new app to be loaded in.

	cx	- Application attach mode method, currently, one of:
		  0 - use appMode in AppLaunchBlock passed, or if none
		  there, use the default mode.  If this is non-zero,
		  any appMode in the launch block is overridden.

		  MSG_GEN_PROCESS_RESTORE_FROM_STATE
			State file MUST be passed, no data file should be
		  MSG_GEN_PROCESS_OPEN_APPLICATION
			State file normally should NOT be passed, although
			one could be to accomplish ui templates. A data
			file may be passed into the application as well
		  MSG_GEN_PROCESS_OPEN_ENGINE
			State file normally should NOT be passed.
			The data file on which the engine will operate
			MUST be passed.  If 0, the default data file should
			be used (Enforced by app, not GenProcessClass)

	dx	- Block handle of structure AppLaunchBlock (must be shareable),
		  or 0 for:
			* Mode = OPEN_APPLICATION
			* No data file
			* No template statefile
			* Launch in current default field
			* Current directory is data directory passed to app

	If si  = -1, then full pathname/filename/diskhandle is stored in
		     AppLaunchBlock.
	If si != -1, then either:
		    ds:si = absolute path of file to load (no drive letter), and
		    bx = handle of disk on which the file resides

		    or

		    ds:si = file to load (no path) from either SP_APPLICATION
			or SP_SYS_APPLICATION, and
		    bx = StandardPath to use
		(ds:si *can* be pointing to the movable XIP code resource.)
		Either of these takes precedence over data stored in any passed
		AppLaunchBlock.

RETURN:
	bx - geode process handle
	carry - clear if no error
		ax - segment of geode's core block
	carry - set if error
		ax - error code (GeodeLoadError)
DESTROYED:
	Nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

UserLoadApplication	proc	far	uses	cx, dx, si, di, bp, ds, es
	.enter

	clr	di			; Use default gen parent (unless passed
	clr	bp			; in block)
	call	PrepAppLaunchBlock	; get completed AppLaunchBlock in DX
	LONG jc	done			; exit if error

	mov	bx, dx
	call	MemLock
	mov	ds, ax
;
;	If no activation dialog set in ALB, then set UI Flag so "Activating"
;	dialog won't display.  This can be set in geodes such as the spooler
;	and savers where we don't want the dialog to come up.
;
	test	ds:[ALB_launchFlags], mask ALF_NO_ACTIVATION_DIALOG
	jz	noChange
	push	ax, es
	segmov	es, dgroup, ax
	ornf	es:[uiFlags], mask UIF_INIT
	pop	ax, es
noChange:

;	IF WE WANT TO HANDLE VIA THE UI QUEUE, SEND IT OFF

	mov	ah, ds:[ALB_launchFlags]
	andnf	ds:[ALB_launchFlags], \
			not mask ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE

	test	ah, mask ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE
	jz	loadNow

	mov	bx, dx
	call	MemUnlock		;Unlock the AppLaunchBlock

	mov	ax, MSG_USER_LAUNCH_APPLICATION
	mov	bx, handle 0			; send to ourselves
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	clr	ax				; (clears carry)
	mov	bx, ax
	jmp	done

loadNow:

	; Allocate space on stack to pass filename for launching

	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx
	segmov	es,ss		; ES:DI <- ptr to stack frame into which to
	mov	di, sp		;  build filename.
	push	di		; save offset on stack
	mov	bp, ds:[ALB_appRef.AIR_diskHandle]	; bp = app disk handle

	; set ds:si to be ptr to filename

	mov	si, offset ALB_appRef.AIR_fileName
	mov	cx, PATH_BUFFER_SIZE/2	; # of words to copy
	rep	movsw		; copy into stack area.
	segmov	ds,ss,ax
	pop	si			; ds:si points at filename
	call	MemUnlock
	clr	di			; Just pass 0 in di, which will be cx
	mov	bx, bp			; bx = application disk handle
	mov	bp, dx			; Block handle gets passed in bp

	call	FilePushDir

	tst	bx
	jz	UseSystemDisk
	test	bx, DISK_IS_STD_PATH_MASK; check if using system disk
	jnz	NotDiskHandle		; branch if so

	; disk handle passed -- use it

	push	ds			; save application
	segmov	ds, cs			;
	mov	dx, offset userLoadRootPath
	call	FileSetCurrentPath	; switch to specified disk
	pop	ds
if DBCS_PCGEOS
EC <	cmp	{wchar}ds:[si], C_BACKSLASH				>
else
EC <	cmp	{byte} ds:[si], C_BACKSLASH				>
endif
EC <	ERROR_NZ DISK_HANDLE_PASSED_WITHOUT_FULL_PATHNAME		>
	jmp	loadIt
NotDiskHandle:

	; If standard path passed in then set it

	mov	al, 1			;Do not report FILE_NOT_FOUND errors
	call	LoadApplication		;
	jnc	noError			;If no error loading app, branch
	cmp	ax, GLE_FILE_NOT_FOUND	;If not FILE_NOT_FOUND error, branch
	jne	loadError		;

UseSystemDisk:

;	If no disk handle passed in (System disk wanted), set disk handle
;	and full pathname in AppInstanceReference.


;	GO TO APPLICATION DIRECTORY AND LOOK THERE

	mov	ax, SP_APPLICATION
	call	StuffStdPath

	mov	al, 1			;Do not report FILE_NOT_FOUND errors
	call	LoadApplication		;
	jnc	noError			;If no error loading app, branch
	cmp	ax, GLE_FILE_NOT_FOUND	;If not FILE_NOT_FOUND error, branch
	jne	loadError		;

;	IF FILE NOT FOUND IN APPLICATION DIRECTORY, LOOK IN SYSAPPL DIRECTORY

	mov	ax, SP_SYS_APPLICATION
	call	StuffStdPath
loadIt:
	clr	ax			;Report FILE_NOT_FOUND errors
	call	LoadApplication		;Try to load application error
	jc	loadError

noError:
				; Release stack storage space
	add	sp, PATH_BUFFER_SIZE	; (must clear carry, as sp cannot wrap)

Finish:
	call	FilePopDir

	mov	bx, cx		; retrieve new geode's handle

done:
	;
	; Turn off the UIF_INIT flag in case it was set earlier
	;
	pushf
	push	ax, es
	segmov	es, dgroup, ax
	andnf	es:[uiFlags], not (mask UIF_INIT)
	pop	ax, es
	popf

	.leave
	ret

loadError:
if _HANDLE_NEW_DEFAULT_LAUNCHER_ON_RESTART
	call	DefaultLauncherCheck
endif		; if _HANDLE_NEW_DEFAULT_LAUNCHER_ON_RESTART
	mov	bx, bp		;
	call	MemFree		; Delete the AppAttachBlock, if still around

				; Release stack storage space
	add	sp, PATH_BUFFER_SIZE
	stc			; return with error from GeodeLoad
	jmp	Finish


UserLoadApplication	endp

LocalDefNLString userLoadRootPath <C_BACKSLASH, 0>

StuffStdPath	proc	near	uses ds
	.enter

	mov	bx, bp
	push	ax
	call	MemLock
	mov	ds, ax
	pop	ds:[ALB_appRef].AIR_diskHandle
	call	MemUnlock

	.leave
	ret

StuffStdPath	endp

	;
	; This was done only for the demo product, where we want
	; want to demonstrate our flexible UI.  So if we shut
	; down and come back up with another default launcher, all
	; will go well if the executable for the old default
	; launcher can't be found.  dlitwin 9/19/94
	;
if _HANDLE_NEW_DEFAULT_LAUNCHER_ON_RESTART

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultLauncherCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the application launch that just failed
		is for the application that used to be the default
		launcher.  If so, launch the new default launcher.
		The name of the old default launcher is written out into
		the .ini file by the Pref SPUI preferences module, when
		it shuts down with one default launcher and starts up with
		another

CALLED BY:	UserLoadApplication

PASS:		ds:si	= filename
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultLauncherCheck	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
iniDefaultLauncher	local	PathName
	.enter

	segmov	es, ds, di
	mov	di, si
	clr	ax			; search for null
	mov	cx, -1			; make sure we don't quit too soon...
	repne	scasb
	not	cx
	push	ds, si, cx		; save for later comparison

	mov	cx, cs
	mov	dx, offset oldDefaultLauncherKey
	mov	ds, cx
	mov	si, offset oldDefaultLauncherCategory
	segmov	es, ss, di
	lea	di, ss:[iniDefaultLauncher]
	push	bp			; save our frame pointer
	mov	bp, size PathName
	call	InitFileReadString
	pop	bp			; restore our frame pointer

	pop	ds, si, ax		; save our filename and size
	jc	bail			; if there is no old string, bail
	jcxz	bail

	mov	cx, ax			; size of our filename
	repe	cmpsb			; compare them
	jne	bail			; if not the old default launcher, bail

	;
	; OK, the old default launcher failed to launch, so launch
	; the new one.  Nuke the "old" default launcher string so
	; that if the old default launcher is the same as the new, we
	; won't get into an infinite loop if it fails.
	;
	push	bp
	mov	cx, cs			; cx:dx is key again
	mov	ds, cx
	mov	si, offset oldDefaultLauncherCategory	; ds:si is category
	call	InitFileDeleteEntry

	;
	; can't use UserCallSystem because it does a MF_FIXUP_DS
	;
	mov	ax, MSG_GEN_SYSTEM_GET_DEFAULT_FIELD
	segmov	ds, dgroup, bx
	movdw	bxsi, ds:[uiSystemObj]
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_GEN_FIELD_LOAD_DEFAULT_LAUNCHER
	mov	bx, cx
	mov	si, dx
	clr	di
	call	ObjMessage
	pop	bp

bail:
	.leave
	ret
DefaultLauncherCheck	endp

LocalDefNLString	oldDefaultLauncherKey, <'oldDefaultLauncher', 0>
LocalDefNLString	oldDefaultLauncherCategory, <'ui features', 0>
endif		; if _HANDLE_NEW_DEFAULT_LAUNCHER_ON_RESTART


COMMENT @----------------------------------------------------------------------

FUNCTION:	PrepAppLaunchBlock

DESCRIPTION:	Inits AppLaunchBlock for use in starting up a new
		GenProcessClass application.

CALLED BY:	GLOBAL

PASS:
	ah	- AppLaunchFlags (0 for default)
	cx	- Application attach mode method, currently, one of:
		  0 - use appMode in AppLaunchBlock passed, or if none
		  there, use the default mode.  If this is non-zero,
		  any appMode in the launch block is overridden.

		  MSG_GEN_PROCESS_RESTORE_FROM_STATE
			State file MUST be passed, no data file should be
		  MSG_GEN_PROCESS_OPEN_APPLICATION
			State file normally should NOT be passed, although
			one could be to accomplish ui templates. A data
			file may be passed into the application as well
		  MSG_GEN_PROCESS_OPEN_ENGINE
			State file normally should NOT be passed.
			The data file on which the engine will operate
			MUST be passed.  If 0, the default data file should
			be used (Enforced by app, not GenProcessClass)

	dx	- Block handle of structure AppLaunchBlock (must be shareable),
		  or 0 for:
			* Mode = OPEN_APPLICATION
			* No data file
			* No template statefile
			* Launch in current default field
			* Current directory is data directory passed to app

	If si  = -1, then full pathname/filename/diskhandle is stored in
		     AppLaunchBlock.
	If si != -1, then either:
		    ds:si = absolute path of file to load (no drive letter), and
		    bx = handle of disk on which the file resides

		    or

		    ds:si = file to load (no path) from either SP_APPLICATION
			or SP_SYS_APPLICATION, and
		    bx = StandardPath to use

		Either of these takes precedence over data stored in any passed
		AppLaunchBlock.

	^ldi:bp	- Generic parent to use, or zero to use current default

RETURN:	dx	- AppLaunchBlock
	carry	- set if error, error value returned in ax

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/2/92		Split out from UserLoadApplication.
	JDM	93.04.06	Code to match header...

------------------------------------------------------------------------------@

PrepAppLaunchBlock	proc	far	uses bx, cx, bp, si, di, ds, es
	.enter

	push	ax		; Save trashed error return register.

EC <	test	ah, not AppLaunchFlags					>
EC <	ERROR_NZ	UI_USER_LOAD_APP_BAD_FLAGS			>

	; if no AppLaunchBlock was passed then create one

	tst	dx
	jnz	HaveBlock

	push	ax,cx
	mov	ax, size AppLaunchBlock
	mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE or \
								ALLOC_DYNAMIC
	push	bx		;preserve any app disk handle
	call	MemAlloc
	mov	dx, bx		; Put block handle in dx
	pop	bx
	pop	ax,cx
	LONG jc	AllocError	;If error in allocation, branch

HaveBlock:
	xchg	bx, dx		;dx <- disk handle/std path, bx <- ALB handle
	push	ax

	; make the UI own the AppLaunchBlock

	mov	ax, handle 0
	call	HandleModifyOwner

	; lock the AppLaunchBlock and fill in the fields: flags, ...

	call	MemLock
	mov	es, ax
	tst	es:[ALB_genParent].handle,	; see if already set
	jnz	10$
	mov	es:[ALB_genParent].handle, di	; store gen parent to use,
	mov	es:[ALB_genParent].chunk, bp	;	if any.
10$:
	pop	ax
	tst	ah		; if launch flags passed, use them.
	jz	UseBlockLaunchFlags
	mov	es:[ALB_launchFlags], ah
UseBlockLaunchFlags:

	jcxz	UseBlockAppMode	; if appMode passed, stuff it into the
				; LaunchBlock.
	mov	es:[ALB_appMode], cx
UseBlockAppMode:

	; Test to make sure there's a real message stored in ALB_appMode.
	; If not, set to default value.
	;
	tst	es:[ALB_appMode]
	jnz	haveMode
	mov	cx, MSG_GEN_PROCESS_OPEN_APPLICATION
	mov	es:[ALB_appMode], cx
haveMode:

	cmp	si, -1		; See if filename passed via far ptr
	je	HaveFilename	; if not, then use that in AppLaunchBlock.
				; Copy filename into AppLaunchBlock.

	mov	di, offset ALB_appRef.AIR_fileName
	mov	cx, PATH_BUFFER_SIZE/2
	rep	movsw		; Copy into block

				; set disk handle from that passed
	mov	es:[ALB_appRef].AIR_diskHandle, dx
HaveFilename:

	segmov	ds, es		; copy segment of block to ds where it
				; will be handy
				; See if a path was passed

;	MAKE SURE NO RELATIVE PATH IS PASSED IN, unless disk handle is
;	StandardPath.

EC <	tst	ds:[ALB_appRef].AIR_diskHandle				>
EC <	jz	fullpath						>
EC <	test	ds:[ALB_appRef].AIR_diskHandle, DISK_IS_STD_PATH_MASK	>
EC <	jnz	fullpath						>
EC <	mov	si, offset ALB_appRef.AIR_fileName			>
EC <	LocalCmpChar ds:[si], C_BACKSLASH				>
EC <	je	fullpath						>

;	IF NOT FULL PATH, MAKE SURE NO "\"s ARE IN THE STRING

EC <looptop:								>
EC <	LocalGetChar ax, dssi						>
EC <	LocalIsNull ax							>
EC <	jz	fullpath   						>
EC <	LocalCmpChar ax, C_BACKSLASH					>
EC <	jne	looptop							>
EC <	ERROR	RELATIVE_PATH_PASSED_TO_USER_LOAD_APPLICATION		>
EC <fullpath:								>

	tst	ds:[ALB_diskHandle]	; path specified?
	jnz	HavePath		; yes

	; copy current path into launch block.

	mov	si, offset ALB_path
	push	bx
	mov	cx, size ALB_path
	call	FileGetCurrentPath	;bx <- disk handle
	mov	ds:[ALB_diskHandle], bx
	pop	bx
HavePath:

	push	bx			;Save handle of AppLaunchBlock

	tst_clc	ds:[ALB_genParent].handle
	jnz	haveField

;	GET PTR TO FIELD TO ADD APP TO (IF NONE PASSED, USE FIELD WITH EXCL)

	mov	cx, SQT_VIS_PARENT_FOR_APPLICATION
	push	ds
	mov	ax, segment idata	;Set DS to a segment that can be
	mov	ds, ax			; fixed up (What a HACK).
	mov	ax, MSG_SPEC_GUP_QUERY_VIS_PARENT
	call	UserCallSystem
	pop	ds
	cmc				;carry clear if parent found
	jnc	storeFieldOD

	; What happens if we don't find a parent for the application?
	; Instead of dying here in ec-code let's return carry set
	; (indicating error) and say the field was detaching.

;EC <	ERROR_NC UI_GEN_APPLICATION_COULDNT_FIND_A_VIS_PARENT		>
;EC <	tst	cx							>
;EC <	ERROR_Z	UI_NO_CURRENT_FIELD_EXCLUSIVE				>

	pop	dx
	pop	ax
	mov	ax, GLE_FIELD_DETACHING	; error code to be returned
	push	ax
	push	dx

storeFieldOD:
	mov	ds:[ALB_genParent].handle, cx
	mov	ds:[ALB_genParent].chunk, dx

haveField:
	pop	dx			; Restore handle of AppLaunchBlock
	mov	bx, dx
	call	MemUnlock
	pop	ax			; Restore trashed error return reg.

exit:
	.leave
	ret

AllocError:
	pop	ax			; Clean saved reg from stack since
					; we're going to return an error.
	mov	ax, GLE_MEMORY_ALLOCATION_ERROR
	stc				; return error
	jmp	exit

PrepAppLaunchBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the passed application.

CALLED BY:	GLOBAL
PASS:		bp - handle of AppLaunchBlock
		ds:si - ptr to filename
		ax - 0 if we want to report FILE_NOT_FOUND errors via the ack
			(If we are looking for an application both in the
			 \APPL and in the \SYSAPPL directories, we don't want
			 to whine about not finding it in the \APPL directory)

RETURN:		carry set if error
		      ax <- GeodeLoadError
		else, cx,bx <- handle of new Geode
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/19/90		Initial version
	pjc	5/23/95		Added multi-language support.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadApplication	proc	near
	uses	bp, si, di
	appLaunchBlock			local	hptr.AppLaunchBlock	\
					push	bp
	ignoreFileNotFoundErrors	local	word	\
					push	ax
	ackID				local	word
	ackOD				local	optr
	ackMsg				local	word
	parentField			local	optr
	diskHandle			local	hptr
	.enter

;	Get data from AppLaunchBlock

	mov	cx, ds
	mov	bx, appLaunchBlock		;BX <- handle of AppLaunchBlock
	call	MemLock
	mov	ds, ax
	movdw	ackOD, ds:[ALB_userLoadAckAD].AD_OD, ax
	mov	ax, ds:[ALB_userLoadAckAD].AD_message
	mov	ackMsg, ax
	mov	ax, ds:[ALB_userLoadAckID]
	mov	ackID, ax
	movdw	parentField, ds:[ALB_genParent], ax

	mov	ax, ds:[ALB_appRef].AIR_diskHandle	;save disk handle
	mov	diskHandle, ax
	call	MemUnlock	;Unlock the app launch block

	mov	ds, cx		;Restore DS segment (DS:SI - file name)

;	LET THE FIELD KNOW ANOTHER APP WILL BE ATTACHING TO IT.

	push	dx, bp, si
	movdw	bxsi, parentField
	mov	ax, MSG_GEN_FIELD_APP_STARTUP_NOTIFY
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	dx, bp, si
	jcxz	7$		;Branch if it is OK to start application
	mov	ax, GLE_FIELD_DETACHING
	stc			;Else, simulate error
	jmp	10$
7$:
	push	dx, bp, si
	movdw	bxsi, parentField
	mov	dx, appLaunchBlock		;Pass AppLaunchBlock in dx
	mov	ax, MSG_GEN_FIELD_ACTIVATE_INITIATE
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	dx, bp, si

	; If using a StandardPath then set it

	mov	ax, diskHandle				;get disk handle
	tst	ax
	jz	noStandardPath
	cmp	ax, StandardPath
	ja	noStandardPath
if MULTI_LANGUAGE
	; If we are in multi-language mode, look at the file links in
	; PRIVDATA\LANGUAGE\<Current Language>\WORLD, which have the correct
	; translated names.

	cmp	ax, SP_APPLICATION
	jne	normalStandardPath
	call	IsMultiLanguageModeOn
	jc	normalStandardPath
	call	GeodeSetLanguageStandardPath
	jmp	noStandardPath
normalStandardPath:
endif
	call	FileSetStandardPath

noStandardPath:

	; If we have a full path name, set the path appropriately and try
	; only to load the tail

	clr	di		;di = index of last \ + 1
	push	si
findBSLoop:
	LocalGetChar ax, dssi
	LocalIsNull ax
	jz	endOfPath
	LocalCmpChar ax, C_BACKSLASH
	jnz	findBSLoop
	mov	di, si
	jmp	findBSLoop
endOfPath:
	pop	si
	tst	di
	jz	noPathToSet
	mov	dx, si
SBCS <	push	{word} ds:[di-1]					>
DBCS <	push	{wchar} ds:[di-2]					>
SBCS <	mov	{char} ds:[di-1], 0					>
DBCS <	mov	{char} ds:[di-2], 0					>
	clr	bx
	call	FileSetCurrentPath
SBCS <	pop	{word} ds:[di-1]					>
DBCS <	pop	{word} ds:[di-2]					>
	jc	10$		;Exit if error setting path
	mov	si, di
noPathToSet:

	; If the application is in the WORLD/Desk Accessories directory,
	; launch as a desk accessory
	;	current directory set to launch app
	;	bp = AppLaunchBlock
	push	bp
	mov	bp, appLaunchBlock
	call	SetDeskAccessoryFlag

;	TRY TO LOAD THE APPLICATION

	mov	ax, PRIORITY_STANDARD
	mov	cx, mask GA_PROCESS or mask GA_APPLICATION
	clr	bx		;Match all filetypes
	mov	dx,bx		;All attributes are OK
	call	GeodeLoad
	pop	bp

	mov	cx, bx		;CX <- new geode's handle
	jc	10$		;If error, branch
	clr	ax		;Clear error flag
10$:
	mov	dx, ax		;DX <- error
	jnc	40$		;If no error, just branch

;	IF THERE WAS AN ERROR, LET THE FIELD KNOW THE APPLICATION WILL NOT BE
;	COMING UP.

	movdw	bxsi, parentField
	cmp	dx, GLE_FIELD_DETACHING
	je	30$		;If field detaching already, don't need to tell
				; it, since it isn't expecting an app to come
				; up.

	push	cx, dx, bp	;Save GeodeHandle and error code

	mov	ax, MSG_GEN_FIELD_APP_STARTUP_DONE
	mov	di, mask MF_CALL;Call, so processed before block is nuked.
	call	ObjMessage	;Let the field know the app didn't start up.
	pop	cx, dx, bp

	tst	ignoreFileNotFoundErrors
	jz	bringDownBox
	cmp	dx, GLE_FILE_NOT_FOUND
	je	30$

bringDownBox:
	push	cx, dx, bp
	clr	cx		;Don't know geode handle - wasn't allocated
	mov	dx, appLaunchBlock
	mov	ax, MSG_GEN_FIELD_ACTIVATE_DISMISS
	mov	di, mask MF_CALL;Call, so processed before block is nuked.
	call	ObjMessage	;Let the field know the app didn't start up.
	pop	cx, dx, bp
30$:
	stc			;Force the error (carry flag) set
40$:
	pushf			;Save carry (error) state
	push	bp
	mov	ax, ackMsg
	movdw	bxsi, ackOD
	tst	ignoreFileNotFoundErrors
	mov	bp, ackID
				;Restore flag (if 0, report FILE_NOT_FOUND
				; errors)

	jz	80$		;Branch if we want to report all errors
	cmp	dx, GLE_FILE_NOT_FOUND	;If FILE_NOT_FOUND error, don't send
	je	90$			; through the ack.
80$:
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
90$:
	pop	bp
	popf			;Restore carry (error) state
	mov	ax, dx		;AX <- error
	mov	bx, cx		;BX,CX <- new geode's handle
	.leave
	ret
LoadApplication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDeskAccessoryFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set ALF_DESK_ACCESSORY is app being launched is in
		WORLD/Desk Accessories directory

CALLED BY:	INTERNAL
			LoadApplication

PASS:		thread's current directory set to directory containing
			application to launch
		bp = AppLaunchBlock

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDeskAccessoryFlag	proc	near
	uses	ds, si, cx, bx, es, di, dx, ax
curPath	local	PathName
	.enter
	;
	; only set ALF_DESK_ACCESSORY, if UILaunchOptions allows it
	;
	call	UserGetLaunchOptions	; ax = UILaunchOptions
	test	ax, mask UILO_DESK_ACCESSORIES
	jz	done			; not allowed
	segmov	ds, ss			; ds:si = buffer
	lea	si, curPath
	mov	cx, size curPath
	call	FileGetCurrentPath	; bx = disk handle
	call	LockDAPathname		; cx:dx = desk accessory pathname
	mov	es, cx
	mov	di, dx
	mov	dx, SP_APPLICATION	; dx, es:di = WORLD/Desk Accessories
	mov	cx, bx			; cx = disk handle
					; cx, ds:si = current directory
	call	FileComparePaths	; al = PathCompareType
	call	UnlockDAPathname
	cmp	al, PCT_EQUAL		; not in WORLD/Desk Accessories, done
	jne	done
	mov	bx, ss:[bp]		; bx = AppLaunchBlock (thanks, .enter)
	call	MemLock
	mov	ds, ax
	ornf	ds:[ALB_launchFlags], mask ALF_DESK_ACCESSORY
	call	MemUnlock
done:
	.leave
	ret
SetDeskAccessoryFlag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockDAPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	lock desk accessory pathname

CALLED BY:	EXTERNAL
			SetDeskAccessoryFlag
			ExpressMenuControlGenerateUI
			CreateOtherAppsList

PASS:		nothing

RETURN:		cx:dx = desk accessory pathname

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/18/92	broke out for shared usage

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockDAPathname	proc	far
	uses	ax, bx, ds, si
	.enter
	mov	bx, handle Strings
	call	MemLock
	mov	cx, ax
	mov	ds, ax
	mov	si, offset deskAccessoryPathname
	mov	dx, ds:[si]			; cx:dx = pathname
	.leave
	ret
LockDAPathname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockDAPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unlock desk accessory pathname

CALLED BY:	EXTERNAL
			SetDeskAccessoryFlag
			ExpressMenuControlGenerateUI
			CreateOtherAppsList

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/18/92	broke out for shared usage

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockDAPathname	proc	far
	uses	bx
	.enter
	mov	bx, handle Strings
	call	MemUnlock
	.leave
	ret
UnlockDAPathname	endp


COMMENT @----------------------------------------------------------------------

METHOD:		UserCallApplication

DESCRIPTION:	Call application object of process which owns block passed

PASS:
	ax - Method to send to application
	cx, dx, bp - data to send on to application
	ds - any object block (for fixup)

RETURN:
	carry - clear if no call/method not handled
		else, whatever routine is.
	ds - updated to point at segment of same block as on entry

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

UserCallApplication	proc	far	uses	bx,si,di
	.enter
	clr	bx
	call	GeodeGetAppObject
	tst_clc	bx
	jz	exit

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	.leave
	ret

UserCallApplication	endp

Resident	ends

;
;-----------------
;

JustECCode	segment resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckForDamagedES

SYNOPSIS:	Checks to make sure that ES points to a valid LMem block.
		May be used in object code where *es:xx is supposed to
		be pointing at an object.

CALLED BY:	utility

PASS:		*es:xx -- object

RETURN:		nothing

DESTROYED:	nothing (flags preserved as well)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/ 2/89	Initial version

------------------------------------------------------------------------------@

CheckForDamagedES	proc	far
if	ERROR_CHECK
	pushf
	push	bx
	mov	bx, es:[LMBH_handle]
	call	ECCheckLMemHandleNS
	pop	bx
	popf
endif
	ret
CheckForDamagedES	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckODCXDX

DESCRIPTION:	Checks to see if cx:dx is a valid OD

CALLED BY:	EXTERNAL

PASS:
	cx:dx	- OD to check

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

ECCheckODCXDX	proc	far
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
EC <	call	ECCheckOD						>
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
	ret
ECCheckODCXDX	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckLMemODCXDX

DESCRIPTION:	Checks to see if cx:dx is a valid LMem OD (non-process)

CALLED BY:	EXTERNAL

PASS:
	cx:dx	- OD to check

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

ECCheckLMemODCXDX	proc	far
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
EC <	call	ECCheckLMemOD						>
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
	ret
ECCheckLMemODCXDX	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckUILMemODCXDX

DESCRIPTION:	Checks to see if cx:dx is a valid UI-run LMem OD (non-process)

CALLED BY:	EXTERNAL

PASS:
	cx:dx	- OD to check

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

ECCheckUILMemODCXDX	proc	far
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
EC <	call	ECCheckUILMemOD						>
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
	ret
ECCheckUILMemODCXDX	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckUILMemOD

DESCRIPTION:	Checks to see if bx:si is a valid UI-run LMem OD (non-process)

CALLED BY:	EXTERNAL

PASS:
	bx:si	- OD to check

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

ECCheckUILMemOD	proc	far
if	ERROR_CHECK
	pushf
	uses	ax, ds
	.enter
	tst	bx				; NULL OD is OK
	jz	Done
	call	ECCheckLMemOD			; First, make sure a valid
						; 	LMem obj OD

	mov	ax, segment idata		; Get to handle of UI thread
	mov	ds, ax
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			; Fetch otherInfo = running
						;	thread
	cmp	ax, ds:[uiThread]		; Do comparison - run by UI?
	ERROR_NZ	UI_OBJECT_NOT_RUN_BY_UI_THREAD_AS_IS_REQUIRED
Done:
	.leave
	popf
endif
	ret
ECCheckUILMemOD	endp

JustECCode	ends

;
;---------------
;

Navigation	segment	resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	UserCheckAcceleratorChar

SYNOPSIS:	Returns carry set if this is an accelerator-type character.

CALLED BY:	global

PASS:		cl	= character.
		dl	= CharFlags
		dh	= ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if accelerator char

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/90		Initial version

------------------------------------------------------------------------------@

UserCheckAcceleratorChar	proc	far

SBCS <	cmp	ch, CS_UI_FUNCS						>
SBCS <	je	accelChar	;treat UI functions chars as accel chars>

	; accent characters are not accelerators

	test	dl, mask CF_TEMP_ACCENT
	jnz	notAccelChar

	; otherwise anything with CONTROL or ALT is an accelerator, unless
	; both CONTROL and ALT are down, in which case it is reserved for
	; extended ASCII mapping

	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	noControl

	; CONTROL is down

	test	dh, mask SS_LALT or mask SS_RALT
	jz	accelChar		; CONTROL only, it's an accelerator
					; CONTROL and ALT pressed

SBCS <	cmp	ch, CS_CONTROL		; control character, not insertable >
DBCS <	cmp	ch, CS_CONTROL_HB	; control character, not insertable >
	je	accelChar
	jmp	notAccelChar		; else CONTROL+ALT+BSW char set
					; is some kind of extended character.

noControl:
	; CONTROL is not down

	test	dh, mask SS_LALT or mask SS_RALT
	jnz	accelChar		; ALT only -> accelerator

	; neither CONTROL nor ALT is down

if DBCS_PCGEOS
	cmp	ch, CS_CONTROL_HB
	jne	notAccelChar
	cmp	cx, C_SYS_TAB
	je	notAccelChar
	cmp	cx, C_SYS_ENTER
	je	notAccelChar
	cmp	cx, C_SYS_BACKSPACE
	je	notAccelChar
else
	cmp	ch, CS_CONTROL		; Not control char, do more checking
	jnz	notAccelChar
	cmp	cl, VC_TAB		; Any of these things are insertable.
	jz	notAccelChar
	cmp	cl, VC_ENTER
	jz	notAccelChar
	cmp	cl, VC_CTRL_L
	jz	notAccelChar
	cmp	cl, VC_BACKSPACE
	jz	notAccelChar

if	0

;	Nuked this, because this causes the text object to think that
;	page up and page down are insertable characters.

endif
endif

	; anything else with CS_CONTROL is an accelerator

accelChar:
	stc
	ret

notAccelChar:
	clc
	ret

UserCheckAcceleratorChar	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	UserGetKbdAcceleratorMode

SYNOPSIS:	Returns kbd accelerator mode status.

CALLED BY:	utility

PASS:		nothing

RETURN:		zero flag clear if on, set if off.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/15/92	Initial version

------------------------------------------------------------------------------@
UserGetKbdAcceleratorMode	proc	far		uses	ax, ds
	.enter
	mov	ax, dgroup
	mov	ds, ax
	tst	ds:uiKbdAcceleratorMode
	.leave
	ret
UserGetKbdAcceleratorMode	endp

Navigation	ends

;
;---------------
;

FlowCommon	segment	resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	UserCheckInsertableCtrlChar

SYNOPSIS:	Checks passed key to see if it is a control character that
		maps to an insertable ascii character.

CALLED BY:	CallKeyBindings

PASS:		cx -- character value
		dl - CharFlags
		dh - ShiftState
		bp (low) - ToggleState

RETURN:		carry set if convertable keypad char.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/13/90		Initial version

------------------------------------------------------------------------------@

UserCheckInsertableCtrlChar	proc	far
SBCS <	cmp	ch, CS_CONTROL			; not control char set, branch>
DBCS <	cmp	ch, CS_CONTROL_HB		; not control char set, branch>
	jne	noMatch				;
	test	dh, mask SS_LCTRL or mask SS_RCTRL  ; control key pressed, exit
	jnz	noMatch
	;
	; Check the characters that are not affected by the numlock.
	;	'*','+','-'	--> insertable
	;	'.'		--> check	(special case for delete)
	;	'/'		--> insertable
	;	'0'..'9'	--> check	(special cases for arrows)
	;
	cmp	cl, '*'				; not in range '*' to '/'
	jb	10$				;    then branch
	cmp	cl, '-'
	jbe	match
	cmp	cl, '/'
	je	match				; else say we have match
10$:
	;
	; Now let's convert the keys affected by the num-lock key, but only
	; if they're not on the extended character set (we don't want the
	; extended arrows to be converted to numbers).
	;
	test	bp, mask TS_NUMLOCK		; see if num-lock pressed
	jz	noMatch				; no, we won't convert.
	test	dl, mask CF_EXTENDED		; don't diddle with extendeds
	jnz	noMatch

	cmp	cl, '.'				; check range '.' to '9'
	jb	noMatch				; if not, no match
	cmp	cl, '9'				;
	ja	noMatch				;
match:
	stc					; say we had a match
	jmp	short exit			;
noMatch:					;
	clc					; return carry clear - no match
exit:						;
	ret					;
UserCheckInsertableCtrlChar	endp

FlowCommon	ends
;
;-------------------
;
UtilityUncommon	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserGetSpecUIProtocolRequirement

DESCRIPTION:	Returns protocol # that should be passed to GeodeUseLibrary
		in any attempt to load a specific user interface for use with
		this geode.

CALLED BY:	EXTERNAL

PASS:
	nothing

RETURN:
	bx	- Major Protocol #
	ax	- Minor Protocol #

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Currently used only by Welcome application, when starting up new
	fields.  This functionality will likely move back into the UI.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/91		Initial version
------------------------------------------------------------------------------@

UserGetSpecUIProtocolRequirement	proc	far
	mov	bx, SPUI_PROTO_MAJOR
	mov	ax, SPUI_PROTO_MINOR
	ret
UserGetSpecUIProtocolRequirement	endp

UtilityUncommon ends

;
;--------------
;

Init segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserLoadExtendedDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load an extended driver given the category of the ini
		file in which to find the "device" and "driver" keys for
		the thing.

CALLED BY:	TryLoadMouseDriver, UserScreenMakeOne, UserLoadTaskDriver,
		UserLoadExtendedDriverXIP
PASS:           ax	= StandardPath enum for directory to look in
		bx	= value to pass in bx to DRE_TEST_DEVICE and
			  DRE_SET_DEVICE; may be garbage if driver being
			  loaded doesn't expect anything.
		cx.dx	= protocol number expected
		ds:si	= category
RETURN:		carry clear if successful:
			bx	= handle of loaded and initialized driver
		carry set if unsuccessful:
			ax	= GeodeLoadError
DESTROYED:	cx, dx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

noDriverStr	char	'Error - no driver entry in INI file for:', 0
cantLoadStr	char	'Error - could not load this driver', 0
cantInitStr	char	'Error - could not initialize this driver', 0

UserLoadExtendedDriver	proc	far	uses ds

protocol	local	ProtocolNumber \
		push 	dx, cx

testAndSetBX	local	word	\
		push bx

strategy	local	fptr.far

		.enter
	;
	; Find the name of the driver to load.
	;
		push	ds, si
		mov	cx, cs
		mov	dx, offset cs:[driverStr]
		call	GetIniString		;ds:si <- driver name
						;^hbx  <- handle of block
		jc	errorNoDriverStr	;skip if none found...
	;
	; Log an entry
	;
		call	LogWriteInitEntry

	;
	; Try and load the thing.
	;
		push	bx			; save driver filename handle

		call	FilePushDir
		call	FileSetStandardPath	;  set dir passed
		mov	ax, ss:[protocol].PN_major
		mov	bx, ss:[protocol].PN_minor
		call	GeodeUseDriver
		call	FilePopDir		; doesn't biff anything
		LONG	jc	errorCantLoad
	;
	; Driver loaded ok. See if we can initialize the thing.
	; First find the driver's strategy routine.
	;
		pop	ax
		xchg	ax, bx			;bx <- driver filename
		call	MemFree
		xchg	bx, ax			;bx <- driver geode handle

		call	GeodeInfoDriver
		mov	ax, ds:[si].DIS_strategy.offset
		mov	ss:[strategy].offset, ax
		mov	ax, ds:[si].DIS_strategy.segment
		mov	ss:[strategy].segment, ax

	;
	; Now call the driver's TEST_DEVICE function to see if the thing
	; actually exists.
	;
		pop	ds, si			;ds:si <- category
		push	bx			;save geode handle

		mov	cx, cs
		mov	dx, offset deviceStr
		call	GetIniString
		jc	cannotInit
		push	bx
		mov	dx, ds
		mov	di, DRE_TEST_DEVICE
		mov	bx, ss:[testAndSetBX]
		call	ss:[strategy]
		jc	cannotInitFreeDevice
		cmp	ax, DP_NOT_PRESENT
		je	cannotInitFreeDevice

	;
	; Either the driver knows the device is there, or it can't tell.
	; In either case, we declare the load a success, and tell it to
	; serve whatever device was in the file.
	;
		mov	di, DRE_SET_DEVICE
		mov	bx, ss:[testAndSetBX]
		call	ss:[strategy]
	;
	; Free the device name
	;
		pop	bx
		call	MemFree
		pop	bx		; recover driver handle
		clc			; happiness R us
done:
		.leave
		ret

errorNoDriverStr:
	;
	; Log an entry
	;

NOFXIP <	segmov	ds, cs, si					>
FXIP <		mov	si, SEGMENT_CS					>
FXIP <		mov	ds, si						>
		mov	si, offset noDriverStr
		call	LogWriteEntry

		pop	ds, si		; retrieve category string

		call	LogWriteEntry
	;
	; No "driver" key in the passed category, so recover the category
	; and pretend we got a FILE_NOT_FOUND error.
	;
		mov	ax, GLE_FILE_NOT_FOUND
		stc
		jmp	done

popAndLeave:
		pop	ds, si
		jmp	done

cannotInitFreeDevice:
	;
	; Cannot initialize the driver, and we need to free the locked
	; mouse-device string we got from the ini file.
	;
		pop	bx
		call	MemFree
cannotInit:
	;
	; Cannot initialize the driver, but we loaded it, so we've got to
	; get rid of the thing.
	;
		pop	bx
		call	GeodeFreeDriver

	;
	; Log an entry
	;
		push	si
NOFXIP <	segmov	ds, cs, si					>
FXIP <		mov	si, SEGMENT_CS					>
FXIP <		mov	ds, si						>
		mov	si, offset cantInitStr
		call	LogWriteEntry
		pop	si

		mov	ax, GLE_DRIVER_INIT_ERROR
		stc
		jmp	done

errorCantLoad:
		pop	bx		; bx <- driver filename handle
		call	MemFree
	;
	; Log an entry
	;
NOFXIP <	segmov	ds, cs, si					>
FXIP <		mov	si, SEGMENT_CS					>
FXIP <		mov	ds, si						>
		mov	si, offset cantLoadStr
		call	LogWriteEntry

		stc
		jmp	popAndLeave
UserLoadExtendedDriver	endp

if FULL_EXECUTE_IN_PLACE
Init	ends
ResidentXIP	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserLoadExtendedDriverXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load an extended driver given the category of the ini
		file in which to find the "device" and "driver" keys for
		the thing.

CALLED BY:	TryLoadMouseDriver, UserScreenMakeOne, UserLoadTaskDriver,
		UserLoadExtendedDriver
PASS:           ax	= StandardPath enum for directory to look in
		bx	= value to pass in bx to DRE_TEST_DEVICE and
			  DRE_SET_DEVICE; may be garbage if driver being
			  loaded doesn't expect anything.
		cx.dx	= protocol number expected
		ds:si	= category
RETURN:		carry clear if successful:
			bx	= handle of loaded and initialized driver
		carry set if unsuccessful:
			ax	= GeodeLoadError
DESTROYED:	cx, dx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserLoadExtendedDriverXIP	proc	far
		.enter
	;
	; Copy the category string to the stack, and then execute
	; UserLoadExtendedDriver()
	;
		push	ds
		push	cx
		clr	cx
		call	SysCopyToStackDSSI	;dssi = category on stack
		pop	cx			;cxdx = protocol number
		call	UserLoadExtendedDriver
		lahf				;save the flags to ah
		call	SysRemoveFromStack	;release stack space
		sahf				;restore flags
		pop	ds
		.leave
		ret
UserLoadExtendedDriverXIP	endp


ResidentXIP	ends
Init	segment	resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserLoadSpecificExtendedDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load an extended driver given the exact "driver" and "device"
		names. (Does not involve the .ini file at all.)

CALLED BY:	UserScreenMakeOne (in the autodetect case)

PASS:           ax	= StandardPath enum for directory to look in
		bx	= value to pass in bx to DRE_TEST_DEVICE and
			  DRE_SET_DEVICE; may be garbage if driver being
			  loaded doesn't expect anything.
		cx.dx	= protocol number expected
		ds:si	= driver name (vga.geo, etc.)
		es:di	= device name (VGA 640x480 mumble...)
		(ds:si and es:di *cannot* be pointing to the movable
			XIP code resource.)

RETURN:		carry clear if successful:
			bx	= handle of loaded and initialized driver
		carry set if unsuccessful:
			ax	= GeodeLoadError
DESTROYED:	cx, dx, di, ds, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	12/9/92		copy of UserLoadExtendedDriver, with mods.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserLoadSpecificExtendedDriver	proc	far

protocol	local	ProtocolNumber \
		push 	dx, cx

testAndSetBX	local	word	\
		push bx

strategy	local	fptr.far

		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptrs passed in are valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	;
	; Log an entry
	;
		call	LogWriteInitEntry	;print ds:si to screen

	;
	; Try and load the thing.
	;
		call	FilePushDir
		call	FileSetStandardPath	;  set dir passed
		mov	ax, ss:[protocol].PN_major
		mov	bx, ss:[protocol].PN_minor
		call	GeodeUseDriver		; try to open ds:si
		call	FilePopDir		; doesn't biff anything

		mov	si, offset cantLoadStr
		LONG	jc errorCantLoad	; skip if failed...
						; (cs:si = error string,
						; ax = GeodeLoadError)
	;
	; Driver loaded ok. See if we can initialize the thing.
	; First find the driver's strategy routine.
	;
		call	GeodeInfoDriver
		mov	ax, ds:[si].DIS_strategy.offset
		mov	ss:[strategy].offset, ax
		mov	ax, ds:[si].DIS_strategy.segment
		mov	ss:[strategy].segment, ax

	;
	; Now call the driver's TEST_DEVICE function to see if the thing
	; actually exists.
	;
		push	bx			;save geode handle
		mov	dx, es			;dx:si = device name
		mov	si, di

		mov	di, DRE_TEST_DEVICE
		mov	bx, ss:[testAndSetBX]
		call	ss:[strategy]
		jc	cannotInitFreeDevice

		cmp	ax, DP_NOT_PRESENT
		je	cannotInitFreeDevice

	;
	; Either the driver knows the device is there, or it can't tell.
	; In either case, we declare the load a success, and tell it to
	; serve whatever device was in the file.
	;
		mov	di, DRE_SET_DEVICE
		mov	bx, ss:[testAndSetBX]
		call	ss:[strategy]

		pop	bx		; recover driver handle
		clc			; happiness R us
done:
		.leave
		ret

cannotInitFreeDevice:
	;
	; Cannot initialize the driver, but we loaded it, so we've got to
	; get rid of the thing.
	;
		pop	bx
		call	GeodeFreeDriver

		mov	ax, GLE_DRIVER_INIT_ERROR
		mov	si, offset cantInitStr

errorCantLoad:
	;
	; Log an entry
	;
NOFXIP <	segmov	ds, cs, di					>
FXIP <		mov	di, SEGMENT_CS					>
FXIP <		mov	ds, di						>
		call	LogWriteEntry

		stc
		jmp	done
UserLoadSpecificExtendedDriver	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	UserSetOverstrikeMode

SYNOPSIS:	Sets overstrike mode in the .ini file.  Always.

CALLED BY:	utility

PASS:		al -- 0ffh if overstrike is to be on, 0 if off.

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
      	Kept in Init module since seldom used, and makes the code simpler.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 8/91		Initial version

------------------------------------------------------------------------------@


UserSetOverstrikeMode	proc	far
	uses	cx, dx, si, ds, ax
	.enter
	mov	cx, dgroup
	mov	ds, cx
	mov	ds:uiOverstrikeMode, al		;store boolean value
	clr	ah
	tst	al				;sign extend to word
	jz	10$
	dec	ah
10$:
	mov	cx, cs				;setup ds:si = category
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	mov	dx, offset cs:[overstrikeModeStr]
	call	InitFileWriteBoolean		;write boolean value to .ini
	.leave
	ret
UserSetOverstrikeMode	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserAddAutoExec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an application to the list of those that are to be
		be loaded when the system is booted.

CALLED BY:	GLOBAL and UserAddAutoExecXIP
PASS:		ds:si	= name of application (in SP_APPLICATION or
			  SP_SYS_APPLICATION) to be loaded on startup
		(ds:si *can* be pointing to the movable XIP code resource.)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Search for given app already in execOnStartup:
			- if execOnStartup doesn't exist, create it with
			  default app as first string section, then fall-
			  through
			- if app not in execOnStartup, add string section
			  containing it


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Should have a semaphore to prevent two things from adding
		the same app to the thing at the same time...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserAddAutoExec	proc	far
		uses	ax, bx, cx, dx, si, di, es, ds, bp
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	;
	; Enumerate all elements looking for the one being added, so we
	; don't have it in there twice (we assume this would be a Bad Thing)
	;
		mov	bx, si
		segmov	es, ds
		segmov	ds, cs, cx
		mov	si, offset cs:[uiCategoryStr]
		mov	dx, offset cs:[execOnStartupStr]
		clr	bp
		mov	di, cs
		mov	ax, offset UAAE_callback
		push	bx
		call	InitFileEnumStringSection
		pop	ax
		jc	checkFound
addIt:
	;
	; Not in the set of strings, so append it.
	;
		mov	di, bx
		call	InitFileWriteStringSection
done:
		.leave
		ret
checkFound:
	;
	; If UAAE_callback found the thing, it returns BX different
	; from how it went in to signal this. If the key doesn't actually
	; exist in the ini file, InitFileEnumStringSection returns BX
	; untouched. This is how we differentiate the two possibilities.
	;
		cmp	bx, ax
		jne	done
		jmp	addIt
UserAddAutoExec	endp

if FULL_EXECUTE_IN_PLACE
Init	ends
ResidentXIP	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserAddAutoExecXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an application to the list of those that are to be
		be loaded when the system is booted.

CALLED BY:	GLOBAL
PASS:		ds:si	= name of application (in SP_APPLICATION or
			  SP_SYS_APPLICATION) to be loaded on startup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Search for given app already in execOnStartup:
			- if execOnStartup doesn't exist, create it with
			  default app as first string section, then fall-
			  through
			- if app not in execOnStartup, add string section
			  containing it


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Should have a semaphore to prevent two things from adding
		the same app to the thing at the same time...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserAddAutoExecXIP	proc	far
		.enter
	;
	; Copy the appl name onto the stack, and then exec the real routine
	;
		push	ds, si, cx
		clr	cx
		call	SysCopyToStackDSSI	;dssi = appl name on stack
		call	UserAddAutoExec		;exec the real routine
		call	SysRemoveFromStack	;release the stack space
		pop	ds, si, cx
		.leave
		ret
UserAddAutoExecXIP	endp

ResidentXIP	ends
Init	segment	resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UAAE_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this string section contains the name of the
		app being added.

CALLED BY:	UserAddAutoExec via InitFileEnumStringSection
PASS:		ds:si	= section to check
		cx	= length of section
		dx	= section number
		es:bx	= app being added
RETURN:		carry set to stop enumerating:
			bx	= different from entry to signal section
				  found.
		carry clear to keep going
DESTROYED:	ax, cx, dx, di, si, bp may all be biffed

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UAAE_callback	proc	far
		.enter
		mov	di, bx
		inc	cx			; include NULL in comparison
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		clc				; assume mismatch (keep going)
		jne	done			; no match, so continue enum
	;
	; Found a match. Return carry set and BX different from entry.
	;
		not	bx
		stc
done:
		.leave
		ret
UAAE_callback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserRemoveAutoExec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an application from the list of those to be launched
		on start-up

CALLED BY:	GLOBAL
PASS:		ds:si	= name of app to remove
		(ds:si *cannot* be pointing to the movable XIP code
			resource.)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserRemoveAutoExec proc	far
		uses	ax, bx, cx, dx, si, di, es, ds, bp
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	;
	; Enumerate all elements looking for the one being removed.
	;
		mov	bx, si
		segmov	es, ds
		segmov	ds, cs, cx
		mov	si, offset cs:[uiCategoryStr]
		mov	dx, offset cs:[execOnStartupStr]
		clr	bp
		mov	di, cs
		mov	ax, offset URAE_callback
		call	InitFileEnumStringSection
		jc	checkFound
done:
		.leave
		ret
checkFound:
	;
	; If URAE_callback found the thing, it returns BX being the
	; section number and ES 0 to signal it. If the key doesn't actually
	; exist in the ini file, InitFileEnumStringSection returns BX
	; untouched. This is how we differentiate the two possibilities.
	;
		mov	ax, es
		tst	ax
		jnz	done		; => didn't find the key

		mov	ax, bx
		call	InitFileDeleteStringSection
		jmp	done
UserRemoveAutoExec endp


if FULL_EXECUTE_IN_PLACE
Init  ends
UserCStubXIP    segment resource
endif

SetGeosConvention

USERREMOVEAUTOEXEC proc
		on_stack	retf
		stc
removeAddAutoexecCommon label near
		C_GetOneDWordArg ax, bx, cx, dx
		push	ds, si
		on_stack si ds retf
		mov	ds, ax
		mov	si, bx
		jc	remove
FXIP <		call	UserAddAutoExecXIP				>
NOFXIP <	call	UserAddAutoExec					>
done:
		pop	ds, si
		on_stack retf
		ret
remove:
		call	UserRemoveAutoExec
		jmp	done
USERREMOVEAUTOEXEC endp

USERADDAUTOEXEC proc
		clc
		jmp	removeAddAutoexecCommon
USERADDAUTOEXEC endp

if FULL_EXECUTE_IN_PLACE
UserCStubXIP    ends
Init  segment resource
endif



if	FULL_EXECUTE_IN_PLACE
Init	ends
ResidentXIP	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserRemoveAutoExecXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an application from the list of those to be launched
		on start-up

CALLED BY:	GLOBAL
PASS:		ds:si	= name of app to remove
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserRemoveAutoExecXIP	proc	far
		.enter
	;
	; Copy the appl name to the stack, and then exec the real routine
	;
		push	ds, si, cx
		clr	cx
		call	SysCopyToStackDSSI	;dssi = appl name on stack
		call	UserRemoveAutoExec	;exec the real routine
		call	SysRemoveFromStack	;release stack space
		pop	ds, si, cx
		.leave
		ret
UserRemoveAutoExecXIP	endp

ResidentXIP	ends
Init	segment	resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UAAE_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this string section contains the name of the
		app being removed.

CALLED BY:	UserRemoveAutoExec via InitFileEnumStringSection
PASS:		ds:si	= section to check
		cx	= length of section
		dx	= section number
		es:bx	= app being removed
RETURN:		carry set to stop enumerating:
			bx	= section number
			es	= 0 to signal app found
		carry clear to keep going
DESTROYED:	ax, cx, dx, di, si, bp may all be biffed

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
URAE_callback	proc	far
		.enter
		mov	di, bx
		inc	cx			; include NULL in comparison
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		clc				; assume mismatch (keep going)
		jne	done			; no match, so continue enum
	;
	; Found a match. Return carry set, bx = section number, and es = 0
	;
		clr	ax
		mov	es, ax
		mov	bx, dx
		stc
done:
		.leave
		ret
URAE_callback	endp

Init ends

;
;--------------
;

GetUncommon segment resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	UserGetOverstrikeMode

SYNOPSIS:	Returns overstrike mode status.

CALLED BY:	utility

PASS:		nothing

RETURN:		zero flag clear if on, set if off.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 8/91		Initial version

------------------------------------------------------------------------------@

UserGetOverstrikeMode	proc	far		uses	ax, ds
	.enter
	mov	ax, dgroup
	mov	ds, ax
	tst	ds:uiOverstrikeMode
	.leave
	ret
UserGetOverstrikeMode	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserCheckIfPDA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks if running on PDA (pda = true in .ini file)

CALLED BY:	EXTERNAL

PASS:		nothing

RETURN:		carry set if running on PDA
		carry clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		only used rarely (only on state file creation error), so okay
			to fetch from .ini, if this becomes more frequently
			used, cache info

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserCheckIfPDA	proc	far	uses	ax, ds, si, cx, dx
	.enter
	mov	cx, cs
	mov	ds, cx
	mov	si, offset pdaCategoryStr
	mov	dx, offset pdaKeyStr
	call	InitFileReadBoolean
	cmc					; carry clear if not found
	jnc	done
	cmp	ax, FALSE
	je	done				; false, carry clear
	stc					; else, indicate PDA
done:
	.leave
	ret
UserCheckIfPDA	endp

pdaCategoryStr	char	"system", 0
pdaKeyStr	char	"pda", 0

GetUncommon	ends


;
; -----------------------
;

UserUncommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserConfirmFieldChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used to initiate notification of a field change and to
		respond positively or negatively to that change.  Since
		all apps are detached when a field change occurs, those
		on the GSNSLT_FIELD_CHANGE_NOTIFICATIONS gcn list can
		chose to abort the field change if they desire.

		A lot of this was copied from SysShutdown.

CALLED BY:	GLOBAL/EXTERNAL
PASS:		ax	= ConfirmFieldChangeType
		other args depend on AX.  See ui.def for details.
RETURN:		Depends on AX.  See details in ui.def.
		(Only carry flag is sometimes returned)
DESTROYED:	Nothing.
SIDE EFFECTS:	May block.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/26/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserConfirmFieldChange	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	cmp	ax, ConfirmFieldChangeType
   LONG	jae	doneCarrySet

	mov	di, segment dgroup
	mov	ds, di

	mov_tr	di, ax
	shl	di
	jmp	cs:[fieldChangeTable][di]

fieldChangeTable  nptr.near	beginChange,	; CFCT_BEGIN_FIELD_CHANGE
				confirmStart,	; CFCT_CONFIRM_START
				confirmComplete	; CFCT_CONFIRM_COMPLETE

	;------
beginChange:
	tst	bx				; bx and dx must be
   LONG	jz	doneCarrySet			;  not null.
	tst	dx
   LONG	jz	doneCarrySet

	; Must save BX here! At least until we store the ack msg away.
	;
	PSem	ds, fieldChangeBroadcastSem, TRASH_AX
	tst	ds:[fieldChangeConfirmCount]
	jnz	failBegin

	; Store off the object and message we notify when done.
	; (Must be non-zero!)
	;
	movdw	ds:[fieldChangeAckOD], dxcx
	mov	ds:[fieldChangeAckMsg], bx

	; Start the count out with 1 for ourself and 10,000 for a buffer
	; in case some notification receivers are a higher priority then
	; this thread and they run before we can add in the return val
	; from GCNListRecordAndSend.
	;
	mov	ds:[fieldChangeConfirmCount], 10001
	VSem	ds, fieldChangeBroadcastSem, TRASH_AX_BX

	; Broadcast intent to change fields.
	;
	mov	ax, MSG_META_NOTIFY
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_FIELD_CHANGE_NOTIFICATIONS
	mov	dx, GWNT_CONFIRM_FIELD_CHANGE
	clr	di
	call	GCNListRecordAndSend		; cx = # notifications sent

	; Record the number of acks needed and remove our protective 10,000
	;
	add	ds:[fieldChangeConfirmCount], cx
	sub	ds:[fieldChangeConfirmCount], 10000

	; Now perform a positive CFCT_CONFIRM_COMPLETE for ourselves.
	; If no one ; received the message, then this will send
	; confirmation to the caller.
	;
	; (We need to hold the confirm sem before calling confirm
	;  complete since that V's the sem.)
	;
	PSem	ds, fieldChangeConfirmSem, TRASH_AX_BX
	mov	cx, TRUE
	jmp	confirmComplete

failBegin:
	VSem	ds, fieldChangeBroadcastSem, TRASH_AX_BX
	jmp	doneCarrySet

confirmStart:
	PSem	ds, fieldChangeConfirmSem, TRASH_AX_BX

	; If no one has refused, return carry clear.
	;
	tst	ds:[fieldChangeOK]
	jnz	done

	; Someone has already refused; call ourselves to deny this request
	; (so this caller doesn't have to) and return carry set.
	;
	clr	cx
	mov	ax, CFCT_CONFIRM_COMPLETE
	call	UserConfirmFieldChange
	jmp	doneCarrySet

confirmComplete:
	; If cx == FALSE (0), change is refused.
	;
	jcxz	denied

releaseConfirmSem:
	VSem	ds, fieldChangeConfirmSem, TRASH_AX_BX

	PSem	ds, fieldChangeBroadcastSem, TRASH_AX_BX
	dec	ds:[fieldChangeConfirmCount]
	jz	sendChangeConfirmAck

confirmEndComplete:
	VSem	ds, fieldChangeBroadcastSem, TRASH_AX_BX
	clc
	jmp	done

denied:
	; Someone denied us.. set the flag and bail.
	;
	mov	ds:[fieldChangeOK], FALSE
	jmp	releaseConfirmSem

sendChangeConfirmAck:
	; Send off message requested.  CX contains TRUE change field.
	; We force queue this message in case the original caller is
	; the one sending this message.  It's much nicer if the behavior
	; is consistent.
	;
	clr	cx
	mov	cl, TRUE
	xchg	ds:[fieldChangeOK], cl		; reset fieldChangeOK

	mov	bx, ds:[fieldChangeAckOD].handle
	mov	si, ds:[fieldChangeAckOD].chunk
	mov	ax, ds:[fieldChangeAckMsg]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	confirmEndComplete

doneCarrySet:
	stc
done:
	.leave
	ret
UserConfirmFieldChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_UserConfirmFieldChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	UserConfirmFieldChange

C DECLARATION:	extern Boolean
	    _cdecl UserConfirmFieldChange(ConfirmFieldChangeType type, ...);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	guggemos	8/26/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.model	medium, C
global _UserConfirmFieldChange:far

_UserConfirmFieldChange	proc	far	confirmType:ConfirmFieldChangeType,
					args:byte
	uses	ds, si, di
	.enter

	mov	ax, ss:[confirmType]
	cmp	ax, ConfirmFieldChangeType
	jae	doneBad

	mov	si, ax
	shl	si
	jmp	cs:[_fieldChangeTable][si]

_fieldChangeTable  nptr.near	_beginChange,	; CFCT_BEGIN_FIELD_CHANGE
				_confirmStart,	; CFCT_CONFIRM_START
				_confirmComplete ; CFCT_CONFIRM_COMPLETE

_beginChange:
	mov	dx, ({optr}ss:[args]).handle
	mov	cx, ({optr}ss:[args]).chunk
	mov	bx, {word}ss:[args+size optr]
	jmp	_confirmStart

_confirmComplete:
	mov	cx, {word}ss:[args]

_confirmStart:
	call	UserConfirmFieldChange

	; return non-zero if carry set.
	;
	mov	ax, 0
	jnc	done
doneDec:
	dec	ax

done:
	.leave
	ret
doneBad:
	clr	ax
	jmp	doneDec

_UserConfirmFieldChange	endp

	SetGeosConvention

UserUncommon	ends
