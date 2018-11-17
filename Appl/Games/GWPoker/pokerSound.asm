COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pokerSound.asm

AUTHOR:		Jennifer Wu, Feb  3, 1993
		Bryan Chow, Mar  8, 1993

ROUTINES:
	Name			Description
	----			-----------
	SoundSetupSounds	Allocate all sounds.
	GameStandardSound	Plays the specified sound.
	SoundShutOffSounds	Stops all sounds and frees them.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	2/ 3/93		Initial revision
	bchow	3/ 8/93		For GWPoker

DESCRIPTION:
	

	$Id: pokerSound.asm,v 1.1 97/04/04 15:20:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameSoundSetting	etype	byte
GSS_SOUND_ON				enum	GameSoundSetting
GSS_SOUND_OFF				enum	GameSoundSetting
GSS_SOUND_USE_SYSTEM_DEFAULT		enum	GameSoundSetting

; jfh - for some reason the first two are needed even if std sound
;if	WAV_SOUND

PokerSounds	etype	byte, 0
PS_WON_MONEY_ON_CASH_OUT	enum PokerSounds
PS_LOST_MONEY_ON_CASH_OUT	enum PokerSounds
;PS_BIG_WIN			enum PokerSounds
;PS_BASIC_WIN			enum PokerSounds
;PS_BROKE_EVEN			enum PokerSounds
;PS_LOST_HAND			enum PokerSounds
;PS_BORROW_100			enum PokerSounds

;endif



PS_FIVEOFAKIND		equ	0
PS_STRAIGHTFLUSH	equ	1
PS_FOUROFAKIND		equ	2
PS_FULLHOUSE		equ	3
PS_FLUSH		equ	4
PS_STRAIGHT		equ	5
PS_THREEOFAKIND		equ	6
PS_TWOPAIR		equ	7
PS_PAIR			equ	8

if	STANDARD_SOUND
PS_BUST			equ	9
PS_LOST_HAND		equ	10



TWICE_NUM_SOUNDS	equ	22
POKER_TEMPO		equ	8
POKER_VOICES		equ	1

;---------------------------------
;	idata
;---------------------------------

idata	segment	

FiveOfAKindSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural LOW_A/2,WHOLE
	MyNatural LOW_E,WHOLE
	MyNatural LOW_A,WHOLE
	Rest	HALF
	MyNatural MIDDLE_C_SH,QUARTER 
	MyNatural MIDDLE_C,WHOLE
	General	GE_END_OF_SONG

; wavin' my arms in the air (HUCK)
StraightFlushSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural  MIDDLE_C_SH,HALF
	MyNatural  MIDDLE_E,HALF 
	MyNatural  MIDDLE_C_SH,QUARTER 
	MyNatural  LOW_B,HALF 
	MyNatural  LOW_A,WHOLE+QUARTER
	MyNatural  MIDDLE_D,QUARTER 
	MyNatural  MIDDLE_D,QUARTER 
	MyNatural  MIDDLE_C_SH,QUARTER 
	MyNatural  LOW_B,HALF 
	General	GE_END_OF_SONG

; Four ascending notes (SO SORRY)
FourOfAKindSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural  LOW_G,QUARTER 
	MyNatural  LOW_A,QUARTER 
	MyNatural  LOW_B,QUARTER 
	MyNatural  MIDDLE_C,QUARTER 
	General	GE_END_OF_SONG

; Brady Bunch
FullHouseSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural LOW_A,QUARTER
	MyNatural MIDDLE_C,QUARTER
	MyNatural MIDDLE_D,QUARTER
	MyNatural MIDDLE_C,HALF
	MyNatural MIDDLE_C,EIGHTH
	MyNatural MIDDLE_C,EIGHTH
	MyNatural MIDDLE_F,QUARTER
	MyNatural MIDDLE_G,QUARTER
	MyNatural MIDDLE_A,QUARTER
	MyNatural MIDDLE_F,HALF
	General	GE_END_OF_SONG

; Roto-rooter
FlushSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural LOW_G, HALF,
	MyNatural LOW_G, HALF,
	MyNatural MIDDLE_E, QUARTER,
	MyNatural MIDDLE_C, HALF,
	Rest QUARTER
	MyNatural LOW_A, HALF,
	MyNatural LOW_A, QUARTER,
	MyNatural MIDDLE_D, HALF
	General	GE_END_OF_SONG

; Spunk! #1
StraightSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural LOW_A/2, EIGHTH
	MyNatural LOW_A/2, EIGHTH	
	MyNatural MIDDLE_C, QUARTER
	MyNatural LOW_A/2, EIGHTH	
	MyNatural LOW_A/2, EIGHTH	
	MyNatural LOW_B, QUARTER
	MyNatural LOW_A/2, EIGHTH	
	MyNatural LOW_A, QUARTER
	MyNatural LOW_A/2, EIGHTH	
	MyNatural LOW_A/2, EIGHTH	
	MyNatural LOW_A, QUARTER
	MyNatural LOW_A/2, EIGHTH	
	MyNatural LOW_A, QUARTER
	General	GE_END_OF_SONG

; 3 blind mice
ThreeOfAKindSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural MIDDLE_E, QUARTER
	MyNatural MIDDLE_D, QUARTER
	MyNatural MIDDLE_C, HALF

	MyNatural MIDDLE_E, QUARTER
	MyNatural MIDDLE_D, QUARTER
	MyNatural MIDDLE_C, HALF

	MyNatural MIDDLE_G, QUARTER
	MyNatural MIDDLE_F, EIGHTH
	MyNatural MIDDLE_F, EIGHTH
	MyNatural MIDDLE_E, HALF

	MyNatural MIDDLE_G, QUARTER
	MyNatural MIDDLE_F, EIGHTH
	MyNatural MIDDLE_F, EIGHTH
	MyNatural MIDDLE_E, HALF
	General	GE_END_OF_SONG

; Tea for two
TwoPairSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural MIDDLE_C, HALF
	MyNatural LOW_A, QUARTER
	MyNatural LOW_B, HALF
	MyNatural LOW_A, QUARTER
	MyNatural MIDDLE_C, HALF
	MyNatural LOW_A, QUARTER
	MyNatural LOW_B, HALF
	General	GE_END_OF_SONG
	
; Odd couple
PairSoundBuffer		label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural LOW_G, QUARTER
	MyNatural MIDDLE_C, HALF
	MyNatural MIDDLE_G, QUARTER
	MyNatural MIDDLE_G, HALF
	MyNatural MIDDLE_F, QUARTER
	MyNatural MIDDLE_G, HALF_D
	General	GE_END_OF_SONG

; Taps
BustSoundBuffer		label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural LOW_G/2, QUARTER
	MyNatural LOW_G/2, EIGHTH
	MyNatural LOW_C, HALF_D

	MyNatural LOW_G/2, QUARTER
	MyNatural LOW_C, EIGHTH
	MyNatural LOW_E, HALF_D

	MyNatural LOW_C, QUARTER
	MyNatural LOW_E, EIGHTH
	MyNatural LOW_G, HALF_D
	MyNatural LOW_E, QUARTER_D
	MyNatural LOW_C, QUARTER
	MyNatural LOW_G/2, WHOLE
	
	MyNatural LOW_G/2, QUARTER
	MyNatural LOW_G/2, EIGHTH
	MyNatural LOW_C, WHOLE*2
	General	GE_END_OF_SONG

; End of Taps
LostHandSoundBuffer		label	word
	General	GE_SET_TEMPO
		word	POKER_TEMPO
	MyNatural LOW_G/2, QUARTER
	MyNatural LOW_G/2, EIGHTH
	MyNatural LOW_C, WHOLE
	General	GE_END_OF_SONG


idata	ends

;----------------------------------
;	udata
;----------------------------------
udata	segment

	FiveOfAKindSoundHandle		word	; sound handles for all the 
	StraightFlushSoundHandle	word	; sounds in Poker
	FourOfAKindSoundHandle		word
	FullHouseSoundHandle		word
	FlushSoundHandle		word
	StraightSoundHandle		word
	ThreeOfAKindSoundHandle		word
	TwoPairSoundHandle		word
	PairSoundHandle			word
	BustSoundHandle			word
	LostHandSoundHandle		word

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

if 	STANDARD_SOUND


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
	mov	cx, POKER_VOICES
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
	offset FiveOfAKindSoundBuffer,
	offset StraightFlushSoundBuffer,
	offset FourOfAKindSoundBuffer,
	offset FullHouseSoundBuffer,
	offset FlushSoundBuffer,
	offset StraightSoundBuffer,
	offset ThreeOfAKindSoundBuffer,
	offset TwoPairSoundBuffer,
	offset PairSoundBuffer,
	offset BustSoundBuffer,
	offset LostHandSoundBuffer

soundHandleTable	word \
	FiveOfAKindSoundHandle,
	StraightFlushSoundHandle,
	FourOfAKindSoundHandle,
	FullHouseSoundHandle,
	FlushSoundHandle,
	StraightSoundHandle,
	ThreeOfAKindSoundHandle,
	TwoPairSoundHandle,
	PairSoundHandle,
	BustSoundHandle,
	LostHandSoundHandle

SoundSetupSounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays the specified sound.

CALLED BY:	GLOBAL

PASS:		dx	= PokerSounds type
		es	= idata

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 3/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameStandardSound	proc	far
	uses	ax,bx,cx,dx,bp,di
	.enter

	call	GetGameSoundSetting		;bp <- GameSoundSetting

	;
	;	If sound is off, do nothing
	;

;PrintMessage < Hey you turned off the sound here>
	cmp	bp, GSS_SOUND_OFF
    ;	jmp	done
	je	done

	;
	;	If sound is on, send it directly to the sound library
	;
	cmp	bp, GSS_SOUND_ON
	je	soundOn

	;
	;	System default
	;
	shl	dx, 1
	mov	bp, dx
	mov	di, cs:soundHandleTable[bp]
	mov	cx, es:[di]
	mov	ax, SST_CUSTOM_SOUND
	call	UserStandardSound
	jmp	done
	
soundOn:
	shl	dx, 1
	mov	bp, dx
	mov	di, cs:soundHandleTable[bp]
	mov	bx, es:[di]
	mov	dl, mask EOSF_UNLOCK
	mov	ax, SP_GAME
	mov	cx, POKER_TEMPO
	call	SoundPlayMusic
done:
	.leave
	ret

GameStandardSound	endp



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

endif	;if STANDARD_SOUND


if	 WAV_SOUND


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays the specified sound.

CALLED BY:	GLOBAL

PASS:		dx	= PokerSounds type
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
GameStandardSound	proc	far
	uses	ax,cx,dx,bp,si,ds
	.enter

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

	push	dx				;PokerSound
	mov	cx,cs
	mov	dx,offset soundString
	mov	ds,cx
	mov	si,offset uiCategory
	call	InitFileReadBoolean
	pop	dx				;PokerSound
	jc	soundOn				;no string assume on
	tst	ax
	jz	done				;bail if false

soundOn:
	call	PokerPlayWavFile

done:
	.leave
	ret

GameStandardSound	endp

uiCategory	char	"ui",0
soundString	char	"sound",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerPlayWavFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play the wav file associated with the sound type

CALLED BY:	INTERNAL

PASS:		
		dx - PokerSoundsType
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
PokerPlayWavFile		proc	near
	uses	ax,bx,dx,di,es,ds
	.enter

	mov	ax,cs
	mov	ds,ax				;segment for path
	mov	es,ax				;segment for filename

	mov	di,dx				;sound enum
	shl	di,1
	add	di,offset wavFilenameOffsetTable
	mov	di,ds:[di]			;offset to sound

	mov	bx,SP_USER_DATA
	mov	dx,offset soundPath		;offset to path
	call	WavPlayFile

	.leave
	ret
PokerPlayWavFile		endp

soundPath char "Sound\\QuickSh",0

wavFilenameOffsetTable	word \
	offset wonMoneyOnCashOut,
	offset lostMoneyOnCashOut,
	offset bigWin,
	offset basicWin,
	offset brokeEven,
	offset playerLostHand,
  	offset borrow100

;CheckHack <length wavFilenameOffsetTable eq PokerSounds>

wonMoneyOnCashOut char "CSHOUTW.WAV",0
lostMoneyOnCashOut char "CSHOUTL.WAV",0
bigWin char "BIGWIN.WAV",0
basicWin char "CHEER.WAV",0
brokeEven char "BRKEVEN.WAV",0
playerLostHand char "LSTHND.WAV",0
borrow100 char "BORROW.WAV",0

endif


SoundCode	ends



