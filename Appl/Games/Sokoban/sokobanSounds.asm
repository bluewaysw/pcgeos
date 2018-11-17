COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992-1995.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		
FILE:		sound.asm

AUTHOR:		Jennifer Wu, Feb  3, 1993

ROUTINES:
	Name			Description
	----			-----------
    GLB SoundSetupSounds        Allocate all sounds and save all sound
				handles.

    GLB SoundPlaySound          Plays the specified sound.

    GLB SoundShutOffSounds      Stops all sounds and frees them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	2/ 3/93		Initial revision
	stevey	6/13/93		grabbed for sokoban

DESCRIPTION:
	

	$Id: sokobanSounds.asm,v 1.1 97/04/04 15:12:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;TWICE_NUM_SOUNDS	equ	8
START_GAME_TEMPO	equ	16
SAVE_BAG_TEMPO		equ	8
FINISH_LEVEL_TEMPO	equ	8
HIGH_SCORE_TEMPO	equ	6

;SokobanSounds	etype	word, 0, 2
	SS_START_GAME		equ 0
	SS_SAVE_BAG		equ 1
	SS_FINISH_LEVEL	equ 2
if HIGH_SCORES
	SS_HIGH_SCORE		equ 3
endif

;---------------------------------
;	Sound resources
;---------------------------------
StartGameSoundResource	segment	resource

	SimpleSoundHeader	1

	ChangeEnvelope	0, IP_REED_ORGAN
	General		GE_SET_TEMPO
		word	START_GAME_TEMPO

	DeltaTick	1

	Natural		0, MIDDLE_A,	THIRTYSECOND,	MEZZO_FORTE
	Natural		0, MIDDLE_G,	THIRTYSECOND,	MEZZO_PIANO
	Natural		0, MIDDLE_A,	DOTTED_QUARTER,	FORTE
	Rest		SIXTEENTH

	Natural		0, MIDDLE_G, 	SIXTEENTH,	MEZZO_FORTE
	Natural		0, MIDDLE_F, 	SIXTEENTH,	MEZZO_FORTE
	Natural		0, MIDDLE_E, 	SIXTEENTH,	MEZZO_FORTE
	Natural		0, MIDDLE_D, 	SIXTEENTH,	MEZZO_FORTE
	Legato		0, MIDDLE_C_SH,	DOTTED_QUARTER,		MEZZO_FORTE
	Natural		0, MIDDLE_D, 	DOTTED_QUARTER,		FORTE
	Rest		QUARTER

	Natural		0, LOW_A,	THIRTYSECOND,		MEZZO_FORTE
	Natural		0, LOW_G,	THIRTYSECOND,		MEZZO_PIANO
	Natural		0, LOW_A,	DOTTED_QUARTER,		MEZZO_FORTE
	Rest		SIXTEENTH

	Staccato	0, LOW_E,	DOTTED_EIGHTH,		MEZZO_PIANO
	Natural		0, LOW_F,	DOTTED_EIGHTH,		MEZZO_FORTE
	Staccato	0, LOW_C_SH,	DOTTED_EIGHTH,		MEZZO_PIANO
	Natural		0, LOW_D,	DOTTED_QUARTER,		FORTE

	General		GE_END_OF_SONG

StartGameSoundResource	ends

SaveBagSoundResource	segment	resource

	SimpleSoundHeader	1
	
	ChangeEnvelope	0, IP_TINKLE_BELL
	General		GE_SET_TEMPO
		word	SAVE_BAG_TEMPO

	DeltaTick	1

	Natural		0, LOW_D, 	EIGHTH,  	MEZZO_FORTE
	Natural		0, LOW_A, 	QUARTER,  	MEZZO_FORTE
	
	General		GE_END_OF_SONG

SaveBagSoundResource	ends

FinishLevelSoundResource	segment	resource

	SimpleSoundHeader	1

	ChangeEnvelope	0, IP_TINKLE_BELL
	General		GE_SET_TEMPO
		word	FINISH_LEVEL_TEMPO

	DeltaTick	1

	Natural		0, LOW_D, 	DOTTED_SIXTEENTH,	MEZZO_FORTE
	Natural		0, LOW_F_SH,	DOTTED_SIXTEENTH,	MEZZO_FORTE
	Natural		0, LOW_A,	DOTTED_SIXTEENTH,	MEZZO_FORTE
	Natural		0, MIDDLE_D,	DOTTED_SIXTEENTH,	MEZZO_FORTE
	Natural		0, LOW_A,	DOTTED_SIXTEENTH,	MEZZO_FORTE
	Natural		0, LOW_F_SH,	DOTTED_SIXTEENTH,  	MEZZO_FORTE
	Natural		0, LOW_D, 	QUARTER,  		MEZZO_FORTE

	General		GE_END_OF_SONG

FinishLevelSoundResource	ends

if HIGH_SCORES

HighScoreSoundResource	segment	resource

	SimpleSoundHeader	1

	ChangeEnvelope	0, IP_STRING_ENSEMBLE_1
	General		GE_SET_TEMPO
		word	HIGH_SCORE_TEMPO

	DeltaTick	1

	Natural		0, MIDDLE_D,	QUARTER,	FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, LOW_A,	EIGHTH,		FORTE
	Natural		0, LOW_F_SH,	EIGHTH,		FORTE
	Natural		0, LOW_A,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	QUARTER,	FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_F_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	QUARTER,	FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_C_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_F_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_F_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	QUARTER,	FORTE
	
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE

	Natural		0, MIDDLE_G,	QUARTER,	FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, LOW_B,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_G,	QUARTER,	FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_A,	EIGHTH,		FORTE
	Natural		0, MIDDLE_B,	EIGHTH,		FORTE
	Natural		0, MIDDLE_A,	EIGHTH,		FORTE
	Natural		0, MIDDLE_G,	QUARTER,	FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_F_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	QUARTER,	FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_C_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_C_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_C_SH,	QUARTER,	FORTE

	Natural		0, LOW_B,	EIGHTH,		FORTE
	Natural		0, MIDDLE_C_SH,	EIGHTH,		FORTE

	Natural		0, MIDDLE_D,	QUARTER,	FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, LOW_A,	EIGHTH,		FORTE
	Natural		0, LOW_F_SH,	EIGHTH,		FORTE
	Natural		0, LOW_A,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	QUARTER,	FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_F_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	QUARTER,	FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_C_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_D,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_F_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	EIGHTH,		FORTE
	Natural		0, MIDDLE_F_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	QUARTER,	FORTE

	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE

	Natural		0, MIDDLE_B,	QUARTER,	FORTE
	Natural		0, MIDDLE_B,	EIGHTH,		FORTE
	Natural		0, MIDDLE_B,	EIGHTH,		FORTE
	Natural		0, MIDDLE_B,	EIGHTH,		FORTE
	Natural		0, MIDDLE_A,	EIGHTH,		FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_A,	EIGHTH,		FORTE
	Natural		0, MIDDLE_B,	QUARTER,	FORTE
	Natural		0, MIDDLE_B,	EIGHTH,		FORTE
	Natural		0, MIDDLE_B,	EIGHTH,		FORTE
	Natural		0, MIDDLE_B,	EIGHTH,		FORTE
	Natural		0, MIDDLE_A,	EIGHTH,		FORTE
	Natural		0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, MIDDLE_A,	EIGHTH,		FORTE
	Natural		0, MIDDLE_B,	QUARTER,	FORTE
	Natural		0, LOW_A,	EIGHTH,		FORTE
	Natural		0, LOW_A,	EIGHTH,		FORTE
	Natural		0, LOW_A,	QUARTER,	FORTE
	Natural		0, LOW_A,	EIGHTH,		FORTE
	Natural		0, MIDDLE_F_SH,	EIGHTH,		FORTE
	Natural		0, MIDDLE_E,	HALF,		FORTE
	Natural		0, MIDDLE_D,	QUARTER,	FORTE

	General		GE_END_OF_SONG

HighScoreSoundResource	ends

endif	; HIGH_SCORES

SoundCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundSetupSounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate all sounds and save all sound handles.

CALLED BY:	GLOBAL

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/14/93			initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundSetupSounds	proc	far
		uses	bx,cx,bp,si,di
		.enter

		mov	bx, handle StartGameSoundResource
		mov	cx, 1			; 1 voice
		call	SoundInitMusic

		mov	bx, handle SaveBagSoundResource
		call	SoundInitMusic

		mov	bx, handle FinishLevelSoundResource
		call	SoundInitMusic
if HIGH_SCORES
		mov	bx, handle HighScoreSoundResource
		call	SoundInitMusic
endif		
		.leave
		ret
SoundSetupSounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays the specified sound.

CALLED BY:	GLOBAL

PASS:		cx	= SokobanSounds type

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey  2/ 3/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlaySound	proc	far
		uses	ax,bx,cx,dx,bp,ds,si
		.enter
	;
	;  First figure out whether to play anything or not...
	;
		cmp	es:[soundOption], SSO_SOUND_OFF
		je	done

		cmp	es:[soundOption], SSO_SOUND_ON
		je	play
	;
	;  Get the system default sound setting.
	;
		push	cx			; save SokobanSoundsType
		mov	cx, cs
		mov	ds, cx
		mov	si, offset uiCategory	; ds:si = category string
		mov	dx, offset uiSoundKey	; cx:dx = key string
		call	InitFileReadBoolean
		pop	cx			; SokobanSoundsType
		jc	play			; nothing there...just play it.

		cmp	ax, FALSE		; sound off?
		je	done
play:
	     shl  cx, 1  
		mov	bp, cx
		mov	bx, cs:soundTypeToHandleTable[bp]
		mov	dl, mask EOSF_UNLOCK
		mov	ax, SP_GAME
		mov	cx, cs:[soundTypeToTempoTable][bp]
		call	SoundPlayMusic
done:		
		.leave
		ret

uiCategory	char	"ui",0
uiSoundKey	char	"sound",0		

if HIGH_SCORES
soundTypeToHandleTable	word	\
	handle StartGameSoundResource,		; SS_START_GAME
	handle SaveBagSoundResource,		; SS_SAVE_BAG
	handle FinishLevelSoundResource,	; SS_FINISH_LEVEL
	handle HighScoreSoundResource		; SS_HIGH_SCORE
else		
soundTypeToHandleTable	word	\
	handle StartGameSoundResource,		; SS_START_GAME
	handle SaveBagSoundResource,		; SS_SAVE_BAG
	handle FinishLevelSoundResource		; SS_FINISH_LEVEL
endif

if HIGH_SCORES
soundTypeToTempoTable	word	\
	START_GAME_TEMPO,			; SS_START_GAME 
	SAVE_BAG_TEMPO,				; SS_SAVE_BAG
	FINISH_LEVEL_TEMPO,			; SS_FINISH_LEVEL
	HIGH_SCORE_TEMPO			; SS_HIGH_SCORE
else
soundTypeToTempoTable	word	\
	START_GAME_TEMPO,			; SS_START_GAME 
	SAVE_BAG_TEMPO,				; SS_SAVE_BAG
	FINISH_LEVEL_TEMPO			; SS_FINISH_LEVEL
endif

SoundPlaySound	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundShutOffSounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops all sounds and frees them.

CALLED BY:	GLOBAL

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/14/93			initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundShutOffSounds	proc	far
		uses	ax, bx
		.enter

		mov	bx, handle StartGameSoundResource
		call	SoundStopMusic

		mov	bx, handle SaveBagSoundResource
		call	SoundStopMusic

		mov	bx, handle FinishLevelSoundResource
		call	SoundStopMusic
if HIGH_SCORES
		mov	bx, handle HighScoreSoundResource
		call	SoundStopMusic
endif		
		.leave
		ret
SoundShutOffSounds	endp


SoundCode	ends



