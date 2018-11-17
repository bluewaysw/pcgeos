COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bjackSound.asm

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
	bchow	3/ 8/93		For BJack

DESCRIPTION:
	

	$Id: bjackSound.asm,v 1.1 97/04/04 15:46:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameSoundSetting	etype	byte
GSS_SOUND_ON				enum	GameSoundSetting
GSS_SOUND_OFF				enum	GameSoundSetting
GSS_SOUND_USE_SYSTEM_DEFAULT		enum	GameSoundSetting

if WAV_SOUND
BJackSounds	etype	byte, 0
BS_WON_MONEY_ON_CASH_OUT	enum BJackSounds
BS_LOST_MONEY_ON_CASH_OUT	enum BJackSounds
BS_PLAYER_BLACK_JACK		enum BJackSounds
BS_PLAYER_BUST			enum BJackSounds
BS_DEALER_BLACK_JACK		enum BJackSounds
BS_DEALER_BUST			enum BJackSounds
BS_PLAYER_WON_HAND		enum BJackSounds
BS_PLAYER_LOST_HAND		enum BJackSounds
BS_SHUFFLE			enum BJackSounds
BS_CAN_DOUBLE_DOWN		enum BJackSounds
BS_CAN_SPLIT			enum BJackSounds
BS_CAN_BUY_INSURANCE		enum BJackSounds
BS_BORROW_100			enum BJackSounds
BS_PUSH_HAND			enum BJackSounds
endif



if 	STANDARD_SOUND

BS_PLAYER_WON_HAND		equ 0
BS_PLAYER_LOST_HAND		equ 1
BS_PLAYER_BUST			equ 2
BS_PUSH_HAND			equ 3

TWICE_NUM_SOUNDS	equ	8
BJACK_TEMPO		equ	8
BJACK_VOICES		equ	1

;---------------------------------
;	idata
;---------------------------------

idata	segment	

WinSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	BJACK_TEMPO
	ChangeEnvelope	0, IP_ACOUSTIC_GRAND_PIANO
	DeltaTick	0
	MyNote 	MIDDLE_C, 10, 0
	MyNote 	MIDDLE_E, 10, 0
	MyNote 	MIDDLE_G, 10, 0
	MyNote 	HIGH_C, 15, 0
	MyNote 	MIDDLE_G, 8, 0
	MyNote 	HIGH_C, 25, 0
	General		GE_END_OF_SONG

LoseSoundBuffer	label	word
	General	GE_SET_TEMPO
		word	BJACK_TEMPO
	ChangeEnvelope	0, IP_ACOUSTIC_GRAND_PIANO
	DeltaTick	0
	MyNote 	LOW_D, 20, 1
	MyNote 	LOW_D, 20, 1
	MyNote 	LOW_D, 7, 1
	MyNote 	LOW_D, 20, 0
	MyNote 	LOW_F, 20, 0
	MyNote 	LOW_E, 7, 1
	MyNote 	LOW_E, 20, 0
	MyNote 	LOW_D, 7, 1
	MyNote 	LOW_D, 20, 0
	MyNote 	LOW_D_b, 7, 0
	MyNote 	LOW_D, 20, 0
	General		GE_END_OF_SONG

; Taps
BustSoundBuffer		label	word
	General	GE_SET_TEMPO
		word	BJACK_TEMPO
	ChangeEnvelope	0, IP_ACOUSTIC_GRAND_PIANO
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

; Odd couple
DrawSoundBuffer		label	word
	General	GE_SET_TEMPO
		word	BJACK_TEMPO
	ChangeEnvelope	0, IP_ACOUSTIC_GRAND_PIANO
	MyNatural LOW_G, QUARTER
	MyNatural MIDDLE_C, HALF
	MyNatural MIDDLE_G, QUARTER
	MyNatural MIDDLE_G, HALF
	MyNatural MIDDLE_F, QUARTER
	MyNatural MIDDLE_G, HALF_D
	General	GE_END_OF_SONG

idata	ends

;----------------------------------
;	udata
;----------------------------------
udata	segment

	WinSoundHandle			word	; sound handles for all the 
	LoseSoundHandle			word	; sounds in Poker
	BustSoundHandle			word
	DrawSoundHandle			word

udata	ends

endif


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
	mov	cx, BJACK_VOICES
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
	offset WinSoundBuffer,
	offset LoseSoundBuffer,
	offset BustSoundBuffer,
	offset DrawSoundBuffer

soundHandleTable	word \
	WinSoundHandle,
	LoseSoundHandle,
	BustSoundHandle,
	DrawSoundHandle

SoundSetupSounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays the specified sound.

CALLED BY:	GLOBAL

PASS:		dx	= BJackSounds type
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
	mov	cx, BJACK_TEMPO
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

endif


if	 WAV_SOUND


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays the specified sound.

CALLED BY:	GLOBAL

PASS:		dx	= BJackSounds type
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

	push	dx				;BJackSound
	mov	cx,cs
	mov	dx,offset soundString
	mov	ds,cx
	mov	si,offset uiCategory
	call	InitFileReadBoolean
	pop	dx				;BJackSound
	jc	soundOn				;no string assume on
	tst	ax
	jz	done				;bail if false

soundOn:
	call	BJackPlayWavFile

done:
	.leave
	ret

GameStandardSound	endp

uiCategory	char	"ui",0
soundString	char	"sound",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackPlayWavFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play the wav file associated with the sound type

CALLED BY:	INTERNAL

PASS:		
		dx - BJackSoundsType
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
BJackPlayWavFile		proc	near
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
BJackPlayWavFile		endp

soundPath char "Sound\\QuickSh",0

wavFilenameOffsetTable	word \
	offset wonMoneyOnCashOut,
	offset lostMoneyOnCashOut,
	offset playerBlackJack,
	offset playerBust,
	offset dealerBlackJack,
	offset dealerBust,
	offset playerWonHand,
	offset playerLostHand,
	offset shuffle,
	offset canDoubleDown,
	offset canSplit,
	offset canBuyInsurance,
	offset borrow100,
	offset pushHand

CheckHack <length wavFilenameOffsetTable eq BJackSounds>

wonMoneyOnCashOut char "CSHOUTW.WAV",0
lostMoneyOnCashOut char "CSHOUTL.WAV",0
playerBlackJack char "PLYRBJK.WAV",0
playerBust char "PLYRBUST.WAV",0
dealerBlackJack char "BOO.WAV",0
dealerBust char "CHEER.WAV",0
playerWonHand char "CHEER.WAV",0
playerLostHand char "LSTHND.WAV",0
shuffle char "SHUFL.WAV",0
canDoubleDown char "BELL.WAV",0
canSplit char "BELL.WAV",0
canBuyInsurance char "BELL.WAV",0
borrow100 char "BORROW.WAV",0
pushHand char "BRKEVEN.WAV",0

endif
SoundCode	ends



