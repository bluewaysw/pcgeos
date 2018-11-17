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
	mkh	7/16/93		Modified for FreeCell

DESCRIPTION:
	

	$Id: freecellSound.asm,v 1.1 97/04/04 15:02:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TWICE_NUM_SOUNDS	equ	4
DEAL_CARDS_TEMPO	equ	16
WINNER_TEMPO		equ	16

;
; Need a couple extra low notes for the Entertainer theme.
;

VERY_LOW_G	= 196
VERY_LOW_A_b	= 207
VERY_LOW_A	= 220
VERY_LOW_B	= 247


FreeCellSounds	etype	word, 0, 2
	FCS_DEAL_CARDS		enum FreeCellSounds
	FCS_WINNER		enum FreeCellSounds

;---------------------------------
;	idata
;---------------------------------
idata	segment	

dealCardsSound	label	word			; beginning of Entertainer.
	ChangeEnvelope	0, IP_VIOLIN
	General		GE_SET_TEMPO
		word	DEAL_CARDS_TEMPO
	Staccato	0, HIGH_D,	 	EIGHTH,  	FORTE
	Staccato	0, HIGH_E, 		EIGHTH,  	FORTE
	Staccato	0, HIGH_C, 		EIGHTH,  	FORTE
	Staccato	0, MIDDLE_A,	 	QUARTER,  	FORTE
	Staccato	0, MIDDLE_B, 		EIGHTH,  	FORTE
	Staccato	0, MIDDLE_G, 		EIGHTH,  	FORTE
	Rest					EIGHTH

	Staccato	0, MIDDLE_D,	 	EIGHTH,  	FORTE
	Staccato	0, MIDDLE_E, 		EIGHTH,  	FORTE
	Staccato	0, MIDDLE_C, 		EIGHTH,  	FORTE
	Staccato	0, LOW_A,	 	QUARTER,  	FORTE
	Staccato	0, LOW_B, 		EIGHTH,  	FORTE
	Staccato	0, LOW_G, 		EIGHTH,  	FORTE
	Rest					EIGHTH

	Staccato	0, LOW_D,	 	EIGHTH,  	FORTE
	Staccato	0, LOW_E, 		EIGHTH,  	FORTE
	Staccato	0, LOW_C, 		EIGHTH,  	FORTE
	Staccato	0, VERY_LOW_A,	 	QUARTER,  	FORTE
	Staccato	0, VERY_LOW_B, 		EIGHTH,  	FORTE
	Staccato	0, VERY_LOW_A,	 	EIGHTH,  	FORTE
	Staccato	0, VERY_LOW_A_b, 	EIGHTH,  	FORTE
	Staccato	0, VERY_LOW_G, 		QUARTER,  	FORTE
	Rest					QUARTER

	Staccato	0, LOW_G, 		QUARTER,  	FORTE
	


	General		GE_END_OF_SONG


winnerSound	label	word			; Fanfare
	ChangeEnvelope	0, IP_TUBULAR_BELLS
	General		GE_SET_TEMPO
		word	WINNER_TEMPO
	Staccato	0, MIDDLE_G,	EIGHTH,		FORTE
	Rest		EIGHTH
	Staccato	0, MIDDLE_G,	EIGHTH,		FORTE
	Staccato	0, MIDDLE_G,	EIGHTH,		FORTE
	Natural		0, HIGH_C,	HALF,		FORTE
	
	General		GE_END_OF_SONG

idata	ends

;----------------------------------
;	udata
;----------------------------------
udata	segment

	dealCardsSoundHandle	word		; sound handles for all the 
	winnerSoundHandle	word		; sounds in Concentration

udata	ends


SoundCode	segment	resource


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
	offset dealCardsSound,
	offset winnerSound

soundNumVoicesTable	word \
	1,			; dealCards
	1			; winnerSound

soundHandleTable	word \
	dealCardsSoundHandle,
	winnerSoundHandle

SoundSetupSounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays the specified sound.

CALLED BY:	GLOBAL

PASS:		cx	= ConcenSounds type
		es	= idata

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 3/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlaySound	proc	far
	uses	ax,bx,cx,dx,bp,di
	.enter

	mov	bp, cx
	mov	di, cs:soundTypeToHandleTable[bp]
	mov	bx, es:[di]
	mov	dl, mask EOSF_UNLOCK
	mov	ax, cs:soundPriorityTable[bp]
	mov	cx, 16
	call	SoundPlayMusic

	.leave
	ret

soundTypeToHandleTable	word	\
	dealCardsSoundHandle,		; FCS_DEAL_CARDS
	winnerSoundHandle		; FCS_WINNER

soundPriorityTable	word	\
	SP_BACKGROUND,			; deal cards
	SP_BACKGROUND			; winner

SoundPlaySound	endp


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
	mov	di, cs:soundHandleToStopTable[bp]
	mov	bx, es:[di]
	call	SoundStopMusic
	call	SoundFreeMusic
	add	bp, 2
	cmp	bp, TWICE_NUM_SOUNDS
	jl	shutoffLoop

	.leave
	ret

soundHandleToStopTable	word	\
	dealCardsSoundHandle,
	winnerSoundHandle

SoundShutOffSounds	endp


SoundCode	ends



