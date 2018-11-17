COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		sound.asm

AUTHOR:		Jennifer Wu, Feb  3, 1993

ROUTINES:
	Name			Description
	----			-----------
	SoundSetupSounds	Allocate all sounds.
	SoundPlaySound		Plays the specified sound.
	SoundShutOffSounds	Stops all sounds and frees them.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	2/ 3/93		Initial revision
	pw	2/29/93		modified for Hearts

DESCRIPTION:
	

	$Id: heartsSound.asm,v 1.1 97/04/04 15:19:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameSoundSetting	etype	byte
GSS_SOUND_ON				enum	GameSoundSetting
GSS_SOUND_OFF				enum	GameSoundSetting
GSS_SOUND_USE_SYSTEM_DEFAULT		enum	GameSoundSetting

if WAV_SOUND
HeartsSounds	etype	word, 0, 2
	HS_WINNER		enum HeartsSounds
	HS_LOSER		enum HeartsSounds
	HS_SHOT_MOON		enum HeartsSounds
	HS_HEARTS_BROKEN	enum HeartsSounds
	HS_CARD_ARRANGE		enum HeartsSounds
	HS_WRONG_PLAY		enum HeartsSounds
	HS_CARDS_PASSED		enum HeartsSounds
	HS_JACK_PLAYED		enum HeartsSounds
	HS_QUEEN_PLAYED		enum HeartsSounds
	HS_JACK_TAKEN_BY_COMPUTER 	enum HeartsSounds
	HS_JACK_TAKEN_BY_HUMAN 		enum HeartsSounds
	HS_QUEEN_TAKEN_BY_COMPUTER 	enum HeartsSounds
	HS_QUEEN_TAKEN_BY_HUMAN 	enum HeartsSounds
endif

if	STANDARD_SOUND

HS_JACK_PLAYED		equ  0
HS_WRONG_PLAY		equ  1
HS_DEAL_CARDS		equ  2
HS_WINNER			equ  3
HS_SHOT_MOON		equ  4
HS_LOSER			equ  5
HS_HEARTS_BROKEN	equ  6



TWICE_NUM_SOUNDS	equ	14
DEAL_CARDS_TEMPO	equ	16
WINNER_TEMPO		equ	8
SHOT_MOON_TEMPO		equ	8
JACK_PLAYED_TEMPO	equ	16
LOSER_TEMPO		equ	16
HEARTS_BROKEN_TEMPO	equ	16

;---------------------------------
;	idata
;---------------------------------
idata	segment	

jackPlayedSound	label	word
	ChangeEnvelope	0, IP_TINKLE_BELL
	General		GE_SET_TEMPO
		word	JACK_PLAYED_TEMPO
	Natural		0, LOW_A,	SIXTEENTH,	MEZZO_FORTE
	Natural		0, MIDDLE_A,	SIXTEENTH,	MEZZO_FORTE
	Natural		0, HIGH_A,	SIXTEENTH,	MEZZO_FORTE	
	General		GE_END_OF_SONG

wrongPlaySound	label 	word
	ChangeEnvelope	0, IP_CELLO
	DeltaTick	1
	VoiceOn		0, LOW_G, MEZZO_FORTE
	DeltaTick	10
	VoiceOff	0
	General		GE_END_OF_SONG

dealCardsSound	label	word			; beginning of Fur Elise
	ChangeEnvelope	0, IP_VIOLIN
	General		GE_SET_TEMPO
		word	DEAL_CARDS_TEMPO
	Natural		0, HIGH_E, 	EIGHTH,  	MEZZO_FORTE
	Natural		0, HIGH_D_SH, 	EIGHTH,  	MEZZO_PIANO
	Natural		0, HIGH_E, 	EIGHTH,  	MEZZO_FORTE
	Natural		0, HIGH_D_SH, 	EIGHTH,  	MEZZO_PIANO
	Natural		0, HIGH_E, 	EIGHTH,  	MEZZO_FORTE
	Natural		0, MIDDLE_B, 	EIGHTH,  	MEZZO_FORTE
	Natural		0, HIGH_D, 	EIGHTH,  	MEZZO_PIANO
	Natural		0, HIGH_C, 	EIGHTH,  	MEZZO_FORTE
	Natural		0, MIDDLE_A, 	QUARTER, 	MEZZO_FORTE
	
	General		GE_END_OF_SONG


winnerSound	label	word
	ChangeEnvelope	0, IP_TUBULAR_BELLS
	General	GE_SET_TEMPO
		word	WINNER_TEMPO
	Natural 	0, LOW_A/2,	WHOLE,		FORTE
	Natural 	0, LOW_E,	WHOLE,		FORTE
	Natural 	0, LOW_A,	WHOLE,		FORTE
	Rest	HALF
	Natural 	0, MIDDLE_C_SH,	QUARTER,	FORTE 
	Natural 	0, MIDDLE_C,	WHOLE,		FORTE

	General	GE_END_OF_SONG	

; wavin' my arms in the air (HUCK)
shotMoonSound	label	word
	ChangeEnvelope	0, IP_TRUMPET
	General	GE_SET_TEMPO
		word	SHOT_MOON_TEMPO
	Natural  	0, MIDDLE_C_SH,	HALF,		FORTE
	Natural  	0, MIDDLE_E,	HALF,		FORTE 
	Natural  	0, MIDDLE_C_SH,	QUARTER,	FORTE
	Natural  	0, LOW_B,	HALF,		FORTE
	Natural  	0, LOW_A,	WHOLE+QUARTER,	FORTE
	Natural  	0, MIDDLE_D,	QUARTER,	FORTE
	Natural  	0, MIDDLE_D,	QUARTER,	FORTE
	Natural  	0, MIDDLE_C_SH,	QUARTER,	FORTE
	Natural  	0, LOW_B,	HALF,		FORTE

	General	GE_END_OF_SONG


loserSound	label	word
	ChangeEnvelope	0, IP_REED_ORGAN
	General		GE_SET_TEMPO
		word	LOSER_TEMPO
	Natural		0, LOW_D,	DOTTED_EIGHTH,	FORTE
	Natural		0, LOW_D,	DOTTED_EIGHTH,	FORTE
	Natural		0, LOW_D,	SIXTEENTH,	FORTE
	Natural		0, LOW_D,	DOTTED_EIGHTH,	FORTE
	Natural		0, LOW_F,	DOTTED_EIGHTH,	FORTE
	Natural		0, LOW_E,	SIXTEENTH,	FORTE
	Natural		0, LOW_E,	DOTTED_EIGHTH,	FORTE
	Natural		0, LOW_D,	SIXTEENTH,	FORTE
	Natural		0, LOW_D,	DOTTED_EIGHTH,	FORTE
	Natural		0, LOW_D_b,	SIXTEENTH,	FORTE
	Natural		0, LOW_D,	DOTTED_EIGHTH,	FORTE

	General	GE_END_OF_SONG
	
heartsBrokenSound	label	word
	ChangeEnvelope	0, IP_TINKLE_BELL
	General		GE_SET_TEMPO
		word	HEARTS_BROKEN_TEMPO
	Natural		0, LOW_A,	SIXTEENTH,	MEZZO_FORTE
	Natural		0, MIDDLE_A,	SIXTEENTH,	MEZZO_FORTE
	Natural		0, HIGH_A,	SIXTEENTH,	MEZZO_FORTE	
	General		GE_END_OF_SONG



idata	ends

;----------------------------------
;	udata
;----------------------------------
udata	segment

	jackPlayedSoundHandle	word		; sound handles for all the 
	wrongPlaySoundHandle	word		; sounds in Hearts
	dealCardsSoundHandle	word
	winnerSoundHandle	word
	shotMoonSoundHandle	word
	loserSoundHandle	word
	heartsBrokenSoundHandle	word

udata	ends

endif	;if STANDARD_SOUND

SoundCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GetGameSoundSetting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns the currrent GameSoundSetting for this game.

Pass:		nothing

Return:		bp = GameSoundSetting

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGameSoundSetting	proc	near
	uses	ax, bx, cx, dx, di, si
	.enter
	mov	bx, handle SoundList
	mov	si, offset SoundList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	bp, ax
	.leave
	ret
GetGameSoundSetting	endp

if	STANDARD_SOUND


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundSetupSounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate all sounds and save all sound handles.

CALLED BY:	GLOBAL

PASS:		es	= idata

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 3/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundSetupSounds	proc	far
	uses	bx,cx,bp,si,di
	.enter

	clr	bp
soundLoop:
	mov	bx, es
	mov	si, cs:soundOffsetTable[bp]
	mov	cx, cs:soundNumVoicesTable[bp]
	call	SoundAllocMusic			; allocate the sound
						; handle returned in bx
	mov	di, cs:soundHandleTable[bp]
	mov	es:[di], bx			; save the handle
	add	bp, 2
	cmp	bp, TWICE_NUM_SOUNDS		; are we done?
	jl	soundLoop

	.leave
	ret

soundOffsetTable	word \
	offset jackPlayedSound,
	offset wrongPlaySound,
	offset dealCardsSound,
	offset winnerSound,
	offset shotMoonSound,
	offset loserSound,
	offset heartsBrokenSound

soundNumVoicesTable	word \
	1,			; jackPlayed
	1,			; wrongPlay
	1,			; dealCards
	1,			; winnerSound
	1,			; shotMoon
	1,			; loserSound
	1			; heartsBrokenSound

soundHandleTable	word \
	jackPlayedSoundHandle,
	wrongPlaySoundHandle,
	dealCardsSoundHandle,
	winnerSoundHandle,
	shotMoonSoundHandle,
	loserSoundHandle,
	heartsBrokenSoundHandle

SoundSetupSounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGamePlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays the specified sound.

CALLED BY:	GLOBAL

PASS:		cx	= HeartsSounds type
		es	= idata

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 3/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGamePlaySound	proc	far
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	mov	dx,cx				;sound

	call	GetGameSoundSetting		;bp <- GameSoundSetting

	;
	;	If sound is off, do nothing
	;

	cmp	bp, GSS_SOUND_OFF
	je	done

	;
	;	If sound is on, send it directly to the sound library
	;
	cmp	bp, GSS_SOUND_ON
	je	soundOn

	;
	;	System default
	;

	push	dx,ds				;sound
	mov	cx,cs
	mov	dx,offset soundString
	mov	ds,cx
	mov	si,offset uiCategory
	call	InitFileReadBoolean
	pop	dx,ds				;sound
	jc	soundOn				;no string assume on
	tst	ax
	jz	done				;bail if false

soundOn:
  ;	mov	bp, cx
	shl  dx, 1
	mov	bp, dx
	mov	di, cs:soundHandleTable[bp]
	mov	bx, es:[di]
	mov	dl, mask EOSF_UNLOCK
	mov	ax, cs:soundPriorityTable[bp]
	mov	cx, 16
	call	SoundPlayMusic

done:
	.leave
	ret

soundPriorityTable	word	\
	SP_GAME,			; match made
	SP_GAME,			; wrong play
	SP_BACKGROUND,			; deal cards
	SP_GAME,			; winner
	SP_GAME,			; shot moon
	SP_GAME,				; new sound
	SP_GAME				; nearts broken

HeartsGamePlaySound	endp

uiCategory	char	"ui",0
soundString	char	"sound",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundShutOffSounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops all sounds and frees them.

CALLED BY:	GLOBAL

PASS:		es	= idata

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 3/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundShutOffSounds	proc	far
	uses	bx,bp,di
	.enter

	clr	bp
shutoffLoop:
	mov	di, cs:soundHandleTable[bp]
	mov	bx, es:[di]
	call	SoundStopMusic
	call	SoundFreeMusic
	add	bp, 2
	cmp	bp, TWICE_NUM_SOUNDS
	jl	shutoffLoop

	.leave
	ret

SoundShutOffSounds	endp

endif



if	 WAV_SOUND


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGamePlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays the specified sound.

CALLED BY:	GLOBAL

PASS:		cx	= HeartsSounds type
		es	= idata

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 3/93			Initial version
	srs	8/20/93			Modified for wav sounds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGamePlaySound	proc	far
	uses	ax,cx,dx,bp,si,ds
	.enter

	mov	dx,cx				;HeartsSound

	call	GetGameSoundSetting		;bp <- GameSoundSetting

	;
	;	If sound is off, do nothing
	;

	cmp	bp, GSS_SOUND_OFF
	je	done

	;
	;	If sound is on, send it directly to the sound library
	;
	cmp	bp, GSS_SOUND_ON
	je	soundOn

	;
	;	System default
	;

	push	dx				;HeartsSound
	mov	cx,cs
	mov	dx,offset soundString
	mov	ds,cx
	mov	si,offset uiCategory
	call	InitFileReadBoolean
	pop	dx				;HeartsSound
	jc	soundOn				;no string assume on
	tst	ax
	jz	done				;bail if false

soundOn:
	call	HeartsPlayWavFile

done:
	.leave
	ret

HeartsGamePlaySound	endp

uiCategory	char	"ui",0
soundString	char	"sound",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsPlayWavFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play the wav file associated with the sound type

CALLED BY:	INTERNAL

PASS:		
		dx - HeartsSoundsType
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsPlayWavFile		proc	near
	uses	ax,bx,dx,di,es,ds
	.enter

	mov	ax,cs
	mov	ds,ax				;segment for path
	mov	es,ax				;segment for filename

	mov	di,dx				;sound enum
	add	di,offset wavFilenameOffsetTable
	mov	di,ds:[di]			;offset to sound

	mov	bx,SP_USER_DATA
	mov	dx,offset soundPath		;offset to path
	call	WavPlayFile

	.leave
	ret
HeartsPlayWavFile		endp

soundPath char "Sound\\QuickSh",0

wavFilenameOffsetTable	word \
	offset winner,
	offset loser,
	offset shotTheMoon,
	offset heartsBroken,
	offset cardArrange,
	offset wrongPlay,
	offset cardsPassed,
	offset jackPlayed,
	offset queenPlayed,
	offset jackTakenByComputer,
	offset jackTakenByHuman,
	offset queenTakenByComputer,
	offset queenTakenByHuman

CheckHack <length wavFilenameOffsetTable eq (HeartsSounds/2)>

winner char "CSHOUTW.WAV",0
loser char "CSHOUTL.WAV",0
shotTheMoon char "MOONSHOT.WAV",0
heartsBroken char "HRTSBRKN.WAV",0
cardArrange char "CARDARR.WAV",0
wrongPlay char "CUCKOO.WAV",0
cardsPassed char "BELL.WAV",0
jackPlayed char "JACK.WAV",0
queenPlayed char "QUEEN.WAV",0
jackTakenByComputer char "BOO.WAV",0
jackTakenByHuman char "CHEER.WAV",0
queenTakenByComputer char "CHEER.WAV",0
queenTakenByHuman char "BOO.WAV",0


endif

SoundCode	ends



