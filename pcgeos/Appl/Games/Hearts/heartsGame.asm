COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		hearts
FILE:		heartsGame.asm

AUTHOR:		Peter Weck, Jan 20, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/20/93   	Initial revision


DESCRIPTION:
	
		

	$Id: heartsGame.asm,v 1.1 97/04/04 15:19:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

	HeartsGameClass

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends

;------------------------------------------------------------------------------
;		Code for HeartsGameClass
;------------------------------------------------------------------------------
CommonCode	segment	resource	;start of code resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will redraw the screen (all the children of the Game)

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= HeartsGameClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		call the masterclass, and then
		redraw the scores

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameVisDraw	method dynamic HeartsGameClass, 
					MSG_VIS_DRAW
	uses	ax
	.enter

	mov	di, offset HeartsGameClass
	call	ObjCallSuperNoLock

	call	HeartsDrawPlayerNames
	call	HeartsDrawScoreChart

;	mov	di,bp
;	mov	ax, 48
;	mov	bx, 59 
;	mov	cx, 209
;	mov	dx, 178
;	call	GrDrawRect

	mov	cx, DRAW_SCORE_AS_BEFORE
	mov	ax, MSG_HEARTS_GAME_SETUP_SCORE
	call	ObjCallInstanceNoLock

	.leave
	ret
HeartsGameVisDraw	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDrawPlayerNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the names of the player next to their decks

CALLED BY:	INTERNAL
		HeartsGameVisDraw

PASS:		*ds:si - HeartsGameObject
		^hbp - GState

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
	srs	7/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDrawPlayerNames		proc	near
	uses	ax,bx,cx,dx,di,si
	.enter

	mov	ax, MSG_HEARTS_DECK_DRAW_NAME

	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage


	.leave
	ret
HeartsDrawPlayerNames		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDrawScoreChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the static part of the score chart at the bottom
		of the screen

CALLED BY:	INTERNAL
		HeartsGameVisDraw

PASS:		*ds:si - Game object
		^hbp - gstate

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
	srs	7/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDrawScoreChart		proc	near
	uses	ax,bx,cx,di,ds,si
	.enter

	push	ds,si				;game chunk

	mov	di,bp				;gstate
	mov	bx,handle StringResource
	call	MemLock
	mov	ds,ax

	mov	si,ds:[PlayerText]
	clr	cx
	mov	ax,CHART_PLAYER_TEXT_X
	mov	bx,CHART_PLAYER_TEXT_Y
	call	GrDrawText

	mov	si,ds:[HandText]
	clr	cx
	mov	ax,CHART_HAND_TEXT_X
	mov	bx,CHART_HAND_TEXT_Y
	call	GrDrawText

	mov	si,ds:[GameText]
	mov	ax,CHART_GAME_TEXT_X
	mov	bx,CHART_GAME_TEXT_Y
	call	GrDrawText

	mov	si,ds:[PlayingUntilText]
	mov	ax,CHART_PLAYING_UNTIL_TEXT_X
	mov	bx,CHART_PLAYING_UNTIL_TEXT_Y
	call	GrDrawText

	mov	bx,handle StringResource
	call	 MemUnlock

	pop	ds,si				;game chunk
	
	call	HeartsDrawChartPlayingUntil


	.leave
	ret
HeartsDrawScoreChart		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDrawChartPlayingUntil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the max score in the chart area

CALLED BY:	INTERNAL
		HeartsDrawScoreChart

PASS:		*ds:si - Game object
		bp - gstate

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
	srs	7/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDrawChartPlayingUntil		proc	near
	class	HeartsGameClass
	uses	ax,bx,dx,di
	.enter

	Deref_DI Game_offset
	mov	dx,ds:[di].HGI_maxScore
	mov	di,bp				;gstate
	mov	ax,CHART_PLAYING_UNTIL_X
	mov	bx,CHART_PLAYING_UNTIL_Y
	call	HeartsDrawNumber

	.leave
	ret
HeartsDrawChartPlayingUntil		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetPassCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will set the number of cards to pass

CALLED BY:	MSG_HEARTS_GAME_SET_PASS_CARDS
PASS:		*ds:si	= HeartsGameClass object
		cl	= number of cards to pass (either 0 or 3)

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	will set the HGI_passCards.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetPassCards	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_PASS_CARDS

	.enter

	mov	ds:[di].HGI_passCards, cl		;set pass cards
	tst	cl					;check if no longer 
							;passing cards
	jnz	exitRoutine				;still passing cards

	test	ds:[di].HGI_gameAttributes, mask HGA_PASSING_CARDS
	jz	exitRoutine				;not in the process
							;of passing
;wasPassing:
	BitClr	ds:[di].HGI_gameAttributes, HGA_PASSING_CARDS
	call	HeartsGameStopPassingCards
	
exitRoutine:
	call	ObjMarkDirty

	.leave
	ret
HeartsGameSetPassCards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameStopPassingCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will stop the the round of passing and start the game

CALLED BY:	HeartsGameSetPassCards
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameStopPassingCards	proc	near
	.enter

	call	HeartsDeckRemovePassTrigger
	mov	cx, 1					;set detectable
	call	HeartsDeckSetDiscardDeck

	mov	ax, MSG_HEARTS_DECK_CLEAR_PASS_POINTER
	mov	di, mask MF_CALL			;or MF_FIXUP_DS
	call	HeartsGameSendToPlayers

	mov	ax, MSG_HEARTS_DECK_CLEAR_CHUNK_ARRAY
	mov	di, mask MF_CALL			;or MF_FIXUP_DS
	call	HeartsGameSendToPlayers

	mov	ax, MSG_DECK_CLEAR_INVERTED
	mov	di, mask MF_CALL			;or MF_FIXUP_DS
	call	HeartsGameSendToPlayers

	mov	ax, MSG_HEARTS_DECK_SORT_DECK		;sort all the decks
	mov	di, mask MF_CALL			;or mask MF_FIXUP_DS
	call	HeartsGameSendToPlayers

	mov	ax, MSG_HEARTS_DECK_REDRAW_IF_FACE_UP
	mov	di, mask MF_CALL			;or mask MF_FIXUP_DS
	call	HeartsGameSendToPlayers

	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	ax, MSG_HEARTS_DECK_START_GAME
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HeartsGameStopPassingCards	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGameOver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts a dialog box on the screen telling the user that
		the game is over

CALLED BY:	HeartsDeckTakeTrick
PASS:		*ds:si	= HeartsGameClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGameOver	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GAME_OVER
tie	local	word

	.enter

	clr	tie				;not a tie yet

	push	si				;save offset

	clr	cx				;get total score
	mov	ax, MSG_HEARTS_DECK_GET_SCORE
	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	dx,cx				;our score

	clr	cx				;get total score
	mov	ax, MSG_HEARTS_DECK_GET_SCORE
	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	dx,cx
	jg	playerLost
	jl	check2
	inc	tie				;could be a tie
	
check2:
	clr	cx				;get total score
	mov	ax, MSG_HEARTS_DECK_GET_SCORE
	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	dx,cx
	jg	playerLost
	jl	check3
	inc	tie				;could be a tie

check3:
	clr	cx				;get total score
	mov	ax, MSG_HEARTS_DECK_GET_SCORE
	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	dx,cx
	jg	playerLost
	je	itsATie
	tst	tie
	jnz	itsATie

	;   Woo woo we won
	;

	pop	si				;game chunk
	mov	cx,HS_WINNER
	call	HeartsGamePlaySound
	mov	bx,handle HeartsWinner
	mov	si,offset HeartsWinner	

showBox:
	push	bp				;locals
	mov	di,mask MF_FIXUP_DS
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
	pop	bp				;locals

	.leave
	ret

playerLost:
	;   ha ha we lost
	;

	pop	si				;game chunk
	mov	cx,HS_LOSER
	call	HeartsGamePlaySound
	mov	bx,handle HeartsLoser
	mov	si,offset HeartsLoser
	jmp	showBox


itsATie:
	pop	si				;game chunk
	mov	bx,handle HeartsTied
	mov	si,offset HeartsTied
	jmp	showBox

HeartsGameGameOver	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameShowWinners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will show the winners score on the screen in RED

CALLED BY:	HeartsGameGameOver
PASS:		*ds:si	= HeartsGameClass object
		cx	= winning score

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will change color of winners score on screen

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameShowWinners	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SHOW_WINNERS
	uses	ax
	.enter

	mov	ax, MSG_HEARTS_DECK_TURN_RED_IF_WINNER

	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	di, mask MF_CALL
	call	ObjMessage


	.leave
	ret
HeartsGameShowWinners	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameCheckShootMoon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check if someone shot the moon and will adjust the
		score accordingly.

CALLED BY:	HeartsDeckTakeTrick
PASS:		*ds:si	= HeartsGameClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	may change the decks scores if someone shot the moon.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 5/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameCheckShootMoon	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_CHECK_SHOOT_MOON
	uses	ax, cx, dx, bp
	.enter


	mov	dx, handle MyDeck
	mov	bp, offset MyDeck
	call	HeartsGameCheckDeckShotMoon
	jc	shotMoon

	mov	dx, handle ComputerDeck1
	mov	bp, offset ComputerDeck1
	call	HeartsGameCheckDeckShotMoon
	jc	shotMoon

	mov	dx, handle ComputerDeck2
	mov	bp, offset ComputerDeck2
	call	HeartsGameCheckDeckShotMoon
	jc	shotMoon

	mov	dx, handle ComputerDeck3
	mov	bp, offset ComputerDeck3
	call	HeartsGameCheckDeckShotMoon
	jnc	done

shotMoon:
	;give everyone points

	cmp	bp,offset MyDeck
	je	humanShotMoon

	call	HeartsPutUpComputerShotMoonBox

adjustScore:
	mov	cx, SHOOT_MOON_SCORE
	mov	ax, MSG_HEARTS_DECK_INCREMENT_SCORE
	push	dx,bp					;save shooter
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	HeartsGameSendToPlayers
	pop	dx,bp					;restore shooter

	;    The player who shot the moon should end up with
	;    the same number of points they had when the
	;    round started. So subtract the 26 the got for
	;    getting all the hearts and the queen, subtract
	;    the 26 that was added to everyone's score just a
	;    moment ago and add 10 to negate getting the 
	;    jack of diamons.
	;

	push	si					;game offset

	movdw	bxsi, dxbp				;shooter od
	mov	ch, (SHOOT_MOON_SCORE * -2) - JACK_OF_DIAMONDS_POINTS
	clr	cl
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_INCREMENT_SCORE
	call	ObjMessage

	pop	si					;game offset
	clr	cx, bp					;no GState, and 
							;don't highlight scores
	mov	ax, MSG_HEARTS_GAME_SETUP_SCORE
	call	ObjCallInstanceNoLock	

done:

	.leave
	ret

humanShotMoon:
	call	HeartsPutUpHumanShotMoonBox
	jmp	adjustScore



HeartsGameCheckShootMoon	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameCheckDeckShotMoon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the passed deck shot the moon

CALLED BY:	INTERNAL
		HeartsGameCheckDeckShotMoon

PASS:		^ldx:bp - od of deck to check

RETURN:		
		stc - if shot
		clc - if not shot

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
	srs	7/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameCheckDeckShotMoon		proc	near
	uses	ax,bx,di,si,cx
	.enter

	mov	bx, dx
	mov	si, bp
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_GET_RAW_SCORE
	call	ObjMessage
	cmp	cl,SHOOT_MOON_SCORE
	jne	noShot
	cmp	ch,JACK_OF_DIAMONDS_POINTS
	je	shotMoon

noShot:
	clc
done:
	.leave
	ret

shotMoon:
	stc
	jmp	done

HeartsGameCheckDeckShotMoon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsPutUpComputerShotMoonBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up dialog box saying that a computer player just
		shot the moon

CALLED BY:	INTERNAL
		HeartsGameCheckShootMoon

PASS:		^ldx:bp - od of deck of moon shooter

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
	srs	7/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsPutUpComputerShotMoonBox		proc	near
	uses	ax,bx,si
	.enter

	mov	bx,dx
	mov	si,bp
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_HEARTS_DECK_COMPUTER_SHOT_MOON_GLOAT
	call	ObjMessage

	.leave
	ret
HeartsPutUpComputerShotMoonBox		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsPutUpHumanShotMoonBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up dialog box saying that a human player just
		shot the moon

CALLED BY:	INTERNAL
		HeartsGameCheckShootMoon

PASS:		^ldx:bp - od of deck of moon shooter

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
	srs	7/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsPutUpHumanShotMoonBox		proc	near
	uses	ax,bx,cx,si
	.enter

	mov	cx, HS_SHOT_MOON
	call	HeartsGamePlaySound

	mov	bx,handle HeartsHumanShotMoon
	mov	si,offset HeartsHumanShotMoon
	call	UserDoDialog

	.leave
	ret
HeartsPutUpHumanShotMoonBox		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetPlayersScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return either the highest or lowest players score
		(lowest score if cx = 0 , or highest score if cx = 1)

CALLED BY:	HeartsDeckTakeTrick
PASS:		*ds:si	= HeartsGameClass object
		cx	= 0 (get lowest score)
			= 1 (get highest score)

RETURN:		cx	= score (min or max)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetPlayersScore	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GET_PLAYERS_SCORE
	uses	ax, dx, bp
	.enter

	mov	ax, MSG_HEARTS_DECK_GET_SCORE
	jcxz	getLowestScore

;getHighestScore:	
	clr	cx					;get total score
	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	dx, cx

	clr	cx					;get total score
	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	cmp	cx, dx
	jl	$1
	mov	dx, cx
$1:
	clr	cx					;get total score
	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	cmp	cx, dx
	jl	$2
	mov	dx, cx
$2:
	clr	cx					;get total score
	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	cmp	cx, dx
	jg	exitRoutine
	mov	cx, dx					;set largest one
	jmp	exitRoutine

getLowestScore:
	clr	cx					;get total score
	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	dx, cx

	clr	cx					;get total score
	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	cmp	cx, dx
	jg	$3
	mov	dx, cx
$3:
	clr	cx					;get total score
	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	cmp	cx, dx
	jg	$4
	mov	dx, cx
$4:
	clr	cx					;get total score
	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	cmp	cx, dx
	jl	exitRoutine
	mov	cx, dx					;set smallest one

exitRoutine:
	.leave
	ret
HeartsGameGetPlayersScore	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameCheckPlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the card just played was the queen or jack, make sound.

CALLED BY:	HeartsDeckPlayCard
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	may play a sound

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameCheckPlaySound	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_CHECK_PLAY_SOUND
	.enter

	tst	ds:[di].HGI_cardsPlayed
	jle	done				;no cards have been played yet

	push	si				;save offset
	clr	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si				;restore offset

	Deref_DI Game_offset
	and	bp, SUIT_MASK or RANK_MASK
	cmp	bp, JACK or DIAMONDS
	je	jackOfDiamonds
	cmp	bp, QUEEN or SPADES
	je	queenOfSpades
		
done:
	.leave
	ret

jackOfDiamonds:
	BitSet	ds:[di].HGI_soundAttributes, HSA_JACK_PLAYED
	mov	cx,HS_DEAL_CARDS
	jmp	playPlayedSound	

queenOfSpades:
	BitSet	ds:[di].HGI_soundAttributes, HSA_QUEEN_PLAYED
  ;	mov	cx,HS_QUEEN_PLAYED   jfh - don't have in std sound
	mov	cx,HS_LOSER
playPlayedSound:
	call	HeartsGamePlaySound

	;   This prevents sounds that might closely follow this
	;   sound from getting missed. Particularly the
	;   trick taken sounds.
	;

	mov	ax, APPRECIATE_QUEEN_OR_JACK_BEING_PLAYED_TIME
	call	TimerSleep

	jmp	done

HeartsGameCheckPlaySound	endm



if WAV_SOUND
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameCheckTakenSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the queen or jack was in trick just taken play sound

CALLED BY:	HeartsDeckPlayCard
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	may play a sound

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameCheckTakenSound	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_CHECK_TAKEN_SOUND

	.enter

	cmp	ds:[di].HGI_cardsPlayed, NUM_PLAYERS
	je	trickTaken

done:
	.leave
	ret

trickTaken:
	;    If neither card or both cards were taken in the trick
	;    then don't make any noise.
	;    

	Deref_DI Game_offset
	test	ds:[di].HGI_soundAttributes,
			(mask HSA_JACK_PLAYED or mask HSA_QUEEN_PLAYED)
	jz	clearBits
	jpe	clearBits

	;    Make sounds depending on who took what
	;

	cmp	ds:[di].HGI_takePointer.handle, handle MyDeck
	jne	computerTakes
	cmp	ds:[di].HGI_takePointer.offset, offset MyDeck
	je	humanTakes

computerTakes:
	mov	cx,HS_JACK_TAKEN_BY_COMPUTER
	test	ds:[di].HGI_soundAttributes, mask HSA_JACK_PLAYED
	jnz	playTakenSound
	mov	cx,HS_QUEEN_TAKEN_BY_COMPUTER


playTakenSound:
	call	HeartsGamePlaySound

	;   This prevents sounds that might closely follow this
	;   sound from getting missed. Particularly the
	;   hearts broken and shot moon sound.
	;

	mov	ax, APPRECIATE_QUEEN_OR_JACK_BEING_TAKEN_TIME
	call	TimerSleep

clearBits:
	;    Clear the taken bits
	;

	Deref_DI Game_offset
	andnf	ds:[di].HGI_soundAttributes, 
			not (mask HSA_JACK_PLAYED or mask HSA_QUEEN_PLAYED)
	jmp	done


humanTakes:
	mov	cx,HS_JACK_TAKEN_BY_HUMAN
	test	ds:[di].HGI_soundAttributes, mask HSA_JACK_PLAYED
	jnz	playTakenSound
	mov	cx,HS_QUEEN_TAKEN_BY_HUMAN
	jmp	playTakenSound

HeartsGameCheckTakenSound	endm

endif   ; WAV_SOUND



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameCheckHeartsBroken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the instance data telling whether or not
		hearts have been broken

CALLED BY:	HeartsDeckTakeTrigger
PASS:		*ds:si	= HeartsGameClass object

RETURN:		cl	= instance data

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameCheckHeartsBroken	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_CHECK_HEARTS_BROKEN
	.enter

	mov	cl, ds:[di].HGI_heartsBroken

	.leave
	ret
HeartsGameCheckHeartsBroken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetHeartsBroken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will set the HGI_heartsBroken instance data to 1

CALLED BY:	HeartsDeckTakeTrick
PASS:		*ds:si	= HeartsGameClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetHeartsBroken	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_HEARTS_BROKEN
	uses	ax,cx
	.enter

	mov	ds:[di].HGI_heartsBroken, 1
	call	ObjMarkDirty

	mov	di,offset HeartsHaveBeenBrokenText
	call	HeartsDeckDrawPlayerInstructions
                                       
	mov	cx,HS_HEARTS_BROKEN
	call	HeartsGamePlaySound

	;   If the player took the trick in which hearts were broken
	;   the this text just displayed will be immediately wiped out
	;   by the "Hey, it's your turn" text. So leave it on the screen
	;   for a moment

	mov	ax,30
	call	TimerSleep

	.leave
	ret
HeartsGameSetHeartsBroken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetMaxScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the maximum score before game should end.

CALLED BY:	MSG_HEARTS_GAME_GET_MAX_SCORE
PASS:		*ds:si	= HeartsGameClass object

RETURN:		cx	= maximum score
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetMaxScore	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GET_MAX_SCORE
	.enter

	mov	cx, ds:[di].HGI_maxScore;

	.leave
	ret
HeartsGameGetMaxScore	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetMaxScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the maximum score before the game should end.

CALLED BY:	HeartsScoreValue (a GenValue)
PASS:		*ds:si	= HeartsGameClass object
		dx	= score

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetMaxScore	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_MAX_SCORE
	.enter

	;   If it didn't change don't do anything
	;

	cmp	ds:[di].HGI_maxScore,dx
	je	done


	Deref_DI	Game_offset
	mov	ds:[di].HGI_maxScore, dx
	call	ObjMarkDirty

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	call	HeartsDrawChartPlayingUntil
	mov	di,bp
	call	GrDestroyState


done:
	.leave
	ret


HeartsGameSetMaxScore	endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameCloseMaxScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the value

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of HeartsGameClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameCloseMaxScore	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_CLOSE_MAX_SCORE
	.enter

	clr	bp
	mov	cx,ds:[di].HGI_maxScore
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle HeartsScoreValue
	mov	si,offset HeartsScoreValue
	mov	ax,MSG_GEN_VALUE_SET_INTEGER_VALUE
	call	ObjMessage

	.leave
	ret
HeartsGameCloseMaxScore		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetCardsPlayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will get instance data, HGI_cardsPlayed

CALLED BY:	MSG_HEARTS_GAME_GET_CARDS_PLAYED
PASS:		*ds:si	= HeartsGameClass object

RETURN:		cl	= cardsPlayed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetCardsPlayed	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GET_CARDS_PLAYED
	.enter

	mov	cl, ds:[di].HGI_cardsPlayed

	.leave
	ret
HeartsGameGetCardsPlayed	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetCardsPlayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will set instance data, HGI_cardsPlayed

CALLED BY:	MSG_HEARTS_GAME_SET_CARDS_PLAYED
PASS:		*ds:si	= HeartsGameClass object
		cl	= cardsPlayed

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will set instance data, HGI_cardsPlayed

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetCardsPlayed	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_CARDS_PLAYED
	.enter

	mov	ds:[di].HGI_cardsPlayed, cl
	call	ObjMarkDirty

	.leave
	ret
HeartsGameSetCardsPlayed	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetTakeCardAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will get the instance data HGI_takeCardAttr

CALLED BY:	MSG_HEARTS_GAME_GET_TAKE_CARD_ATTR
PASS:		*ds:si	= HeartsGameClass object

RETURN:		cl	= takeCardAttr
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetTakeCardAttr	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GET_TAKE_CARD_ATTR
	.enter

	mov	cl, ds:[di].HGI_takeCardAttr

	.leave
	ret
HeartsGameGetTakeCardAttr	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetTakeCardAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will set the instance data HGI_takeCardAttr

CALLED BY:	MSG_HEARTS_GAME_SET_TAKE_CARD_ATTR
PASS:		*ds:si	= HeartsGameClass object
		cl	= takeCardAttr

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will set the instance data HGI_takeCardAttr

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetTakeCardAttr	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_TAKE_CARD_ATTR
	.enter

	mov	ds:[di].HGI_takeCardAttr, cl
	call	ObjMarkDirty

	.leave
	ret
HeartsGameSetTakeCardAttr	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetTakePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will set the instance data HGI_takePointer

CALLED BY:	MSG_HEARTS_GAME_SET_TAKE_POINTER
PASS:		*ds:si	= HeartsGameClass object
		^lcx:dx	= pointer to the deck that is taking the trick

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will set the instance data HGI_takePointer

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetTakePointer	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_TAKE_POINTER
	.enter

	movdw	ds:[di].HGI_takePointer, cxdx
	call	ObjMarkDirty

	.leave
	ret
HeartsGameSetTakePointer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetTakePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will get the instance data HGI_takePointer

CALLED BY:	MSG_HEARTS_GAME_GET_TAKE_POINTER
PASS:		*ds:si	= HeartsGameClass object
		
RETURN:		^lcx:dx	= pointer to the deck that is taking the trick
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetTakePointer	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GET_TAKE_POINTER
	.enter

	movdw	cxdx, ds:[di].HGI_takePointer

	.leave
	ret
HeartsGameGetTakePointer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameLeadPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will set the instance data HGI_leadPointer

CALLED BY:	MSG_HEARTS_GAME_SET_LEAD_POINTER
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		^lcx:dx	= pointer to the deck that is taking the trick

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will set the instance data

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameLeadPointer	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_LEAD_POINTER
	.enter

	movdw	ds:[di].HGI_leadPointer, cxdx
	call	ObjMarkDirty

	.leave
	ret
HeartsGameLeadPointer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetLeadPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will get the instance data HGI_leadPointer

CALLED BY:	MSG_HEARTS_GAME_GET_LEAD_POINTER
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data

RETURN:		^lcx:dx	= who lead that last trick
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetLeadPointer	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GET_LEAD_POINTER
	.enter

	movdw	cxdx, ds:[di].HGI_leadPointer

	.leave
	ret
HeartsGameGetLeadPointer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetNumberOfPassCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the instance data telling how many cards to pass

CALLED BY:	MSG_HEARTS_GAME_GET_NUMBER_OF_PASS_CARDS
PASS:		*ds:si	= HeartsGameClass object
		ax	= message #

RETURN:		cl	= number of cards to pass
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetNumberOfPassCards	method dynamic HeartsGameClass, 
				MSG_HEARTS_GAME_GET_NUMBER_OF_PASS_CARDS
	.enter

	mov	cl, ds:[di].HGI_passCards

	.leave
	ret
HeartsGameGetNumberOfPassCards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetGameAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will get the instance data HGI_gameAttributes

CALLED BY:	MSG_HEARTS_GAME_GET_GAME_ATTRS
PASS:		*ds:si	= HeartsGameClass object

RETURN:		cl	= HGI_gameAttributes
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetGameAttrs	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GET_GAME_ATTRS
	.enter

	mov	cl, ds:[di].HGI_gameAttributes

	.leave
	ret
HeartsGameGetGameAttrs	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetGameAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will set the instance data HGI_gameAttributes

CALLED BY:	MSG_HEARTS_GAME_SET_GAME_ATTRS
PASS:		*ds:si	= HeartsGameClass object
		cl	= HGI_gameAttributes

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will set the instance data

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetGameAttrs	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_GAME_ATTRS
	.enter

	mov	ds:[di].HGI_gameAttributes, cl
	call	ObjMarkDirty

	.leave
	ret
HeartsGameSetGameAttrs	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetAbsolutePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the sum of the absolute value of all the cards
		that have been played so far.  (Will sum up the abs of all
		the points of all the decks).  If the sum is equal to 
		the maximum number of points, then activate the dialog
		box asking if the user wants to trash the rest of the hand.

CALLED BY:	HeartsDeckTakeTrick
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		cx	= maximum number of points in a round

RETURN:		cx	= number of points
DESTROYED:	nothing
SIDE EFFECTS:	may bring up a dialog box

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetAbsolutePoints	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GET_ABSOLUTE_POINTS
	uses	ax, dx, bp

maximumPoints		local	word		push	cx
gameOD			local	optr
takeOD			local	optr
gameAttrs		local	byte
totalPoints		local	byte
playerOffset		local	word

	.enter

	mov	bx, ds:[LMBH_handle]
	movdw	gameOD, bxsi
	movdw	takeOD, ds:[di].HGI_takePointer, ax
	mov	al, ds:[di].HGI_gameAttributes
	mov	gameAttrs, al
	clr	totalPoints
	mov	playerOffset, offset heartsGamePlayersTable
	mov	dx, NUM_PLAYERS
	mov	ax, MSG_HEARTS_DECK_GET_RAW_SCORE

morePlayersLoop:
	mov	bx, playerOffset
	mov	si, cs:[bx].offset
	mov	bx, cs:[bx].handle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	sub	cl, ch
	add	totalPoints, cl
	add	playerOffset, size optr
	dec	dx
	jg	morePlayersLoop

	mov	cl, totalPoints
	clr	ch
	cmp	cx, maximumPoints
	jl	exitRoutine
	push	bp, cx				;save locals, totalPoints
	test	gameAttrs, mask HGA_END_EARLY
	jnz	playNextCard

	mov	bx, handle HeartsTrashHand
	mov	si, offset HeartsTrashHand
	mov	di,mask MF_FIXUP_DS
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
	jmp	done

playNextCard:
	movdw	bxsi, takeOD
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_PLAY_CARD
	call	ObjMessage

done:
	pop	bp, cx				;restore locals, totalPoints

exitRoutine:
	.leave
	ret
HeartsGameGetAbsolutePoints	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSkipToEndOfHand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler, see message definition
		

CALLED BY:	MSG_HEARTS_GAME_SKIP_TO_END_OF_HAND

PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSkipToEndOfHand	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SKIP_TO_END_OF_HAND
	.enter

	mov	ax, MSG_HEARTS_GAME_CHECK_SHOOT_MOON
	call	ObjCallInstanceNoLock		;adjust scores if moon was shot
	mov	cx, 1				;we want to find highest score
	mov	ax, MSG_HEARTS_GAME_GET_PLAYERS_SCORE
	call	ObjCallInstanceNoLock
	Deref_DI Game_offset
	cmp	cx, ds:[di].HGI_maxScore	;check if anyone went over
						;maximum score
	jl	gameNotOver
	mov	ax, MSG_HEARTS_GAME_GAME_OVER
	call	ObjCallInstanceNoLock

done:

	.leave
	ret

gameNotOver:
	mov	ax, MSG_HEARTS_GAME_DEAL_ANOTHER_HAND
	call	ObjCallInstanceNoLock
	jmp	done

HeartsGameSkipToEndOfHand	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameDontSkipToEndOfHand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default hander, see definition
		

CALLED BY:	MSG_HEARTS_GAME_DONT_SKIP_TO_END_OF_HAND

PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameDontSkipToEndOfHand	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_DONT_SKIP_TO_END_OF_HAND
	.enter

	BitSet	ds:[di].HGI_gameAttributes, HGA_END_EARLY
 	call	ObjMarkDirty

	movdw	bxsi, ds:[di].HGI_takePointer
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_PLAY_CARD
	call	ObjMessage

	.leave
	ret
HeartsGameDontSkipToEndOfHand	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameToggleOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will toggle the bit indicating if the movement of
		the cards should be shown or the bit indicating if 
		sound should be on or not..

CALLED BY:	HeartsToggleOptions
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameToggleOptions		method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_TOGGLE_OPTIONS
	.enter

	test	bp, mask HTOS_CARD_MOVEMENT_BOOLEAN
	jz	dontChangeMovement

;changeMovement:
	xor	ds:[di].HGI_gameAttributes, mask HGA_DONT_SHOW_MOVEMENT

dontChangeMovement:
	test	bp, mask HTOS_PASS_BOOLEAN
	jz	dontChangePassing

;changePassing:
	push	bp					;save switched booleans
	mov	ax, MSG_HEARTS_GAME_SET_PASS_CARDS
	mov	cl, ds:[di].HGI_passCards
	xor	cl, NUMBER_PASS_CARDS			;will switch between
							;0 and 3
	call	ObjCallInstanceNoLock
	pop	bp					;restore switched
							;booleans

dontChangePassing:
	call	ObjMarkDirty

	.leave
	ret
HeartsGameToggleOptions		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameResetGameWithQueueFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler see definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of HeartsGameClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameResetGameWithQueueFlush	method dynamic HeartsGameClass, 
				MSG_HEARTS_GAME_RESET_GAME_WITH_QUEUE_FLUSH
	uses	ax,cx
	.enter
	
	;    Prevent the user from dorking anything up while we
	;    make sure the queues are clear
	;

	push	si				;game chunk
	mov	bx, handle HeartsApp
	mov	si, offset HeartsApp
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_APPLICATION_IGNORE_INPUT
	call	ObjMessage
	pop	si				;game chunk

	;    This is the number of times to resend 
	;    MSG_HEARTS_GAME_RESET_GAME_INTERNAL on the queue to
	;    make sure the queue is empty. 
	;    The computer decks have a habit of sending a message
	;    on the queue to the next computer deck, which then
	;    handles the message and sends that message to the
	;    next computer deck on the queue. 
	;    As best I can tell the worst case scenario is this.
	;    (I refer to MSG_HEARTS_DECK_PLAY_CARD as PLAY_CARD)
	;    	Human leads the hand and immediately hits New Game.
	;       Human player queues PLAY_CARD to west player (1)
	;	West player queues PLAY_CARD to north player (2)
	;       North player queue PLAY_CARD to east player (3) 
	;       East player queues PLAY_CARD to human player (4)
	;       West player wins so human player queues PLAY_CARD to West (5)
	;       West player queues PLAY_CARD to north player (6)
	;       North Player queues PLAY_CARD to east player (7)
	;       East Player queues PLAY_CARD to human player (8)
	;
	;    I can only safely do new game when it is the humans turn. So
	;    I must resend RESET_GAME_INTERNAL via queue at least
	;    8 times to prevent stray PLAY_CARD messages from coming
	;    in right after a new game is started. Just in case
	;    I will use 9.
	;

	mov	cx,9

	mov	bx,ds:[LMBH_handle]
	mov	di,mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	ax,MSG_HEARTS_GAME_RESET_GAME_INTERNAL
	call	ObjMessage


	.leave
	ret
HeartsGameResetGameWithQueueFlush		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameResetGameInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler see definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of HeartsGameClass
		
		cx - number of times to resend message

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameResetGameInternal	method dynamic HeartsGameClass, 
				MSG_HEARTS_GAME_RESET_GAME_INTERNAL
	uses	ax,cx
	.enter
	
	jcxz	resetGame
	dec	cx

	mov	bx,ds:[LMBH_handle]
	mov	di,mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	ax,MSG_HEARTS_GAME_RESET_GAME_INTERNAL
	call	ObjMessage

done:
	.leave
	ret


resetGame:
	push	si				;game chunk
	mov	bx, handle HeartsApp
	mov	si, offset HeartsApp
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	ObjMessage
	pop	si				;game chunk

	mov	ax,MSG_HEARTS_GAME_RESET_GAME
	call	ObjCallInstanceNoLock

	jmp	done

HeartsGameResetGameInternal		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameResetGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will reset the scores for each deck and will
		redeal the game

CALLED BY:	MSG_HEARTS_GAME_RESET_GAME
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		ds:bx	= HeartsGameClass object (same as *ds:si)
		es 	= segment of HeartsGameClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will restart the game.

PSEUDO CODE/STRATEGY:
		reset the score instance data for all the decks, and then
		call MSG_HEARTS_GAME_RESET_STUFF

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameResetGame	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_RESET_GAME
	uses	ax, cx, dx, bp
	.enter

;	BitClr	ds:[di].HGI_gameAttributes, HGA_DONT_SHOW_MOVEMENT
;	call	ObjMarkDirty

	mov	cx, 1					;reset total score
	mov	ax, MSG_HEARTS_DECK_RESET_SCORE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	HeartsGameSendToPlayers

	mov	ax, MSG_HEARTS_DECK_CLEAR_PASS_POINTER
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	HeartsGameSendToPlayers

	mov	ax, MSG_DECK_CLEAR_INVERTED
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	HeartsGameSendToPlayers

	mov	ax, MSG_HEARTS_GAME_RESET_STUFF
	call	ObjCallInstanceNoLock	

	.leave
	ret
HeartsGameResetGame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameDealAnotherHand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will signal that all the cards have been played and bring
		up a redeal trigger.

CALLED BY:	MSG_HEARTS_GAME_DEAL_ANOTHER_HAND
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	will bring up a redeal trigger

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameDealAnotherHand	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_DEAL_ANOTHER_HAND
	.enter

	mov	ax, MSG_HEARTS_GAME_RESET_STUFF
	call	ObjCallInstanceNoLock

	.leave
	ret
HeartsGameDealAnotherHand	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameResetStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reset the game and redeal

CALLED BY:	HeartsResetTrigger

PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		ds:bx	= HeartsGameClass object (same as *ds:si)
		es 	= segment of HeartsGameClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will restart the game

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameResetStuff	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_RESET_STUFF
	uses	ax, cx, dx
	.enter

	clr	ds:[di].HGI_heartsBroken
	clr	ds:[di].HGI_takeCardAttr
	clr	ds:[di].HGI_shootData
	mov	ds:[di].HGI_cardsPlayed, -1
	BitClr	ds:[di].HGI_gameAttributes, HGA_END_EARLY
	call	ObjMarkDirty

	push	si					;save offset
	call	HeartsDeckSetHumanPlayer
	pop	si					;restore offset

	clr	cx					;just reset this
							;rounds score
	mov	ax, MSG_HEARTS_DECK_RESET_SCORE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	HeartsGameSendToPlayers

	;    Always uninvert cards because there is a timing window
	;    where hitting New Game will leave cards inverted.	
	;

	Deref_DI Game_offset
	BitClr	ds:[di].HGI_gameAttributes, HGA_PASSING_CARDS
	push	si					;save offset

	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_UNINVERT_CHUNK_ARRAY
	call	ObjMessage

	call	HeartsDeckRemovePassTrigger
	mov	cx, 1					;set detectable
	call	HeartsDeckSetDiscardDeck

	pop	si					;restore offset

	mov	ax, MSG_HEARTS_DECK_CLEAR_CHUNK_ARRAY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	HeartsGameSendToPlayers

	;
	;	Seed random number generator for shuffling
	;
	call	TimerGetCount
	mov	dx, ax
	mov	ax, MSG_GAME_SEED_RANDOM
	call	ObjCallInstanceNoLock

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_HEARTS_GAME_NEW_GAME
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
HeartsGameResetStuff	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure that all sound is stopped before shutdown.

CALLED BY:	MSG_GAME_SHUTDOWN
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		ds:bx	= HeartsGameClass object (same as *ds:si)
		es 	= segment of HeartsGameClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameShutdown	method dynamic HeartsGameClass, 
					MSG_GAME_SHUTDOWN
	uses	ax, cx, dx, bp
	.enter

if	STANDARD_SOUND

	; 
	; Turn sound off and free it.
	;
	CallMod	SoundShutOffSounds
endif

	;
	; call superclass.
	;
	mov	di, offset es:HeartsGameClass
	mov	ax, MSG_GAME_SHUTDOWN
	call	ObjCallSuperNoLock


	.leave
	ret
HeartsGameShutdown	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetupStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will collect all the card and then call 
		MSG_HEARTS_GAME_NEW_GAME

CALLED BY:	MSG_GAME_SETUP_STUFF
PASS:		*ds:si	= HeartsGameClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetupStuff	method dynamic HeartsGameClass, 
					MSG_GAME_SETUP_STUFF
	uses	ax, cx, dx,bp
	.enter

	;
	;	Call the super class to take care of vm files, geometry, etc.
	;
	mov	di, offset HeartsGameClass
	call	ObjCallSuperNoLock
	push	bp				;save handle

if	STANDARD_SOUND

	;
	; Set up sounds.
	;
	CallMod	SoundSetupSounds
endif

	;
	; Set the card back to use.
	;
	push	ds,si				; save ds,si
	mov  ax, 1		; set default back
	mov	cx, cs
	mov	ds, cx
	mov	si, offset categoryString	; ds:si = category ASCIIZ string
	mov	dx, offset keyString		; cx:dx = key ASCIIZ string
	call	InitFileReadInteger		; ax = value if successful
						; else ax is unchanged
	pop	ds, si				; restore ds, si
	mov	cx, ax
	mov	ax, MSG_GAME_SET_WHICH_BACK
	call	ObjCallInstanceNoLock

	;
	;	Seed random number generator for shuffling
	;
	call	TimerGetCount
	mov	dx, ax
	mov	ax, MSG_GAME_SEED_RANDOM
	call	ObjCallInstanceNoLock

	Deref_DI Game_offset
	mov	ds:[di].GI_hand.handle, handle MyHand	;setup instance data
	mov	ds:[di].GI_hand.chunk, offset MyHand
;	mov	ds:[di].GI_userMode, ADVANCED_MODE
	call	ObjMarkDirty

	pop	bp				;restore handle

	.leave
	ret
HeartsGameSetupStuff	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will save the state so that it can be restored when entering
		hearts again.

CALLED BY:	MSG_GAME_SAVE_STATE
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data


RETURN:		^hcx - block with saved data
		dx - bytes written to block

DESTROYED:	ax

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSaveState	method dynamic HeartsGameClass, 
					MSG_GAME_SAVE_STATE
	uses	bp
	.enter

	call	ObjMarkDirty

	mov 	ax, MSG_DECK_SAVE_STATE
	call	VisSendToChildren

	.leave
	ret
HeartsGameSaveState	endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetupNeighbors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets up the neighbor instance data for the players
		of the hearts game

CALLED BY:	MSG_HEARTS_GAME_SETUP_NEIGHBORS
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		ds:bx	= HeartsGameClass object (same as *ds:si)
		es 	= segment of HeartsGameClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	sets the instance data for the children of the game
		class

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/28/93   	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetupNeighbors	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SETUP_NEIGHBORS
	uses	ax, cx, dx, bp

	.enter

	mov	ax, MSG_HEARTS_DECK_SET_NEIGHBOR

	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	cx, handle ComputerDeck3
	mov	dx, offset ComputerDeck3
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, cx
	mov	si, dx
	mov	cx, handle ComputerDeck2
	mov	dx, offset ComputerDeck2
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, cx
	mov	si, dx
	mov	cx, handle ComputerDeck1
	mov	dx, offset ComputerDeck1
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, cx
	mov	si, dx
	mov	cx, handle MyDeck
	mov	dx, offset MyDeck
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage


	.leave
	ret
HeartsGameSetupNeighbors	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetupScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets up the scores for the decks.  (Draws them on
		the screen)

CALLED BY:	MSG_HEARTS_GAME_SETUP_SCORE
PASS:		*ds:si	= HeartsGameClass object
		bp	= GState to draw through or 0 if no GState
		cx	= way to draw score (as before, or not highlighted)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	draws the scores on the screen

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetupScore	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SETUP_SCORE
	uses	ax

	.enter

	mov	ax, MSG_HEARTS_DECK_DRAW_SCORE
	mov	di, mask MF_CALL

	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	call	ObjMessage

	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	clr	di
	call	ObjMessage

	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	clr	di
	call	ObjMessage

	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	clr	di
	call	ObjMessage


	.leave
	ret
HeartsGameSetupScore	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will setup the location of all the decks.

CALLED BY:	MSG_GAME_SETUP_GEOMETRY
PASS:		*ds:si	= HeartsGameClass object
		cx = horizontal deck spacing
		dx = vertical deck spacing

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetupGeometry	method dynamic HeartsGameClass, 
					MSG_GAME_SETUP_GEOMETRY
	uses	ax, cx, dx, bp

	.enter

	mov	di, offset HeartsGameClass
	call	ObjCallSuperNoLock

	mov	cx, MYDECK_X_POSITION
	mov	dx, MYDECK_Y_POSITION

	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_HEARTS_DECK_SET_CHUNK_ARRAY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	
	mov	cx, COMPUTERDECK1_X_POSITION
	mov	dx, COMPUTERDECK1_Y_POSITION

	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_HEARTS_DECK_SET_CHUNK_ARRAY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	cx, COMPUTERDECK2_X_POSITION
	mov	dx, COMPUTERDECK2_Y_POSITION

	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_HEARTS_DECK_SET_CHUNK_ARRAY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	cx, COMPUTERDECK3_X_POSITION
	mov	dx, COMPUTERDECK3_Y_POSITION

	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_HEARTS_DECK_SET_CHUNK_ARRAY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	cx, DISCARDDECK_X_POSITION
	mov	dx, DISCARDDECK_Y_POSITION

	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	cx, MYDISCARDDECK_X_POSITION
	mov	dx, MYDISCARDDECK_Y_POSITION

	mov	bx, handle MyDiscardDeck
	mov	si, offset MyDiscardDeck
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	cx, MYHAND_X_POSITION
	mov	dx, MYHAND_Y_POSITION

	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	cx, SHOWLASTTRICKDECK_X_POSITION
	mov	dx, SHOWLASTTRICKDECK_Y_POSITION

	mov	bx, handle ShowLastTrickDeck
	mov	si, offset ShowLastTrickDeck
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
HeartsGameSetupGeometry	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetUpSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the upSpread instance data

CALLED BY:	MSG_GAME_SET_UP_SPREADS
PASS:		*ds:si	= HeartsGameClass object
		cx, dx = x,y spreads for face upcards

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	sets the two pieces of instance data about
		the spreads.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetUpSpreads	method dynamic HeartsGameClass, 
					MSG_GAME_SET_UP_SPREADS
	.enter

	mov	ds:[di].GI_upSpreadX, cx
	mov	ds:[di].GI_upSpreadY, dx
	call	ObjMarkDirty

	.leave
	ret
HeartsGameSetUpSpreads	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetDownSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the downSpacing instance data.

CALLED BY:	MSG_GAME_SET_DOWN_SPREADS
PASS:		*ds:si	= HeartsGameClass object
		cx, dx  = x,y spreads for face down cards

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetDownSpreads	method dynamic HeartsGameClass, 
					MSG_GAME_SET_DOWN_SPREADS
	.enter

	mov	ds:[di].GI_downSpreadX, cx
	mov	ds:[di].GI_downSpreadY, dx
	call	ObjMarkDirty

	.leave
	ret
HeartsGameSetDownSpreads	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameNewGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deals the cards, sets up the score, does the passing, and
		then starts the game.

CALLED BY:	MSG_HEARTS_GAME_NEW_GAME
PASS:		*ds:si	= HeartsGameClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameNewGame	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_NEW_GAME
	uses	ax, cx, dx, bp
	.enter

	;    If the hand has all the cards don't do the collect.
	;    This elimiates a double redraw problem on start up.
	;    The collect does an invalidate.
	;

	push	si
	mov	bx,handle MyHand
	mov	si,offset MyHand
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_DECK_GET_N_CARDS
	call	ObjMessage
	pop	si
	cmp	cx,52
	je	shuffle

	mov	ax, MSG_GAME_COLLECT_ALL_CARDS
	call	ObjCallInstanceNoLock

shuffle:
	;
	;	shuffle the cards
	;
	push	si
	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	ax, MSG_HAND_SHUFFLE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si


	clr	cx, bp					;no GState and don't
							;highlight scores
	mov	ax, MSG_HEARTS_GAME_SETUP_SCORE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_HEARTS_DECK_CLEAR_STRATEGY_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	HeartsGameSendToPlayers

	;
	;	deal the cards
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_HEARTS_GAME_DEAL
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage

	Deref_DI Game_offset

	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3

	mov	cl, ds:[di].HGI_passCards
	tst	cl
	jz	dontPassCards

;passCards:
	mov	ax, MSG_HEARTS_DECK_UPDATE_PASS_POINTER
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	HeartsGameSendToPlayers
	tst	cx
	jnz	dontPassCards				;hold hand
;passHand:
	mov	ax, MSG_HEARTS_DECK_PASS_CARDS
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
				;changed to force_queue to make sure
				;this happens after we are done dealing
	call	ObjMessage
	jmp	exitRoutine

dontPassCards:
	mov	ax, MSG_HEARTS_DECK_START_GAME
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
				;changed to force_queue to make sure
				;this happens after we are done dealing
	call	ObjMessage


;	mov	ch, mask VA_DETECTABLE
;	clr	cl
;	mov	dl, VUM_NOW
;	GetResourceHandleNS MyDeck, bx
;	mov	si, offset MyDeck
;	mov	ax, MSG_VIS_SET_ATTRS
;	mov	di, mask MF_FIXUP_DS
;	call	ObjMessage

exitRoutine:
	.leave
	ret
HeartsGameNewGame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetTrickData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will add another trick to the chunk array (HI_playedCardPtr)
		of each player.

CALLED BY:	MSG_HEARTS_GAME_SET_TRICK_DATA
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		cl	= 4th card attr.
		ch	= 3rd card attr.
		dl	= 2nd card attr.
		dh	= 1st card attr.

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetTrickData	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_TRICK_DATA

deckCards		local	dword	push	cx,dx
playerOffset		local	word
takeId			local	byte
leadId			local	byte
counter			local	byte

	.enter

	mov	playerOffset, offset heartsGamePlayersTable

	push	si
	movdw	bxsi, ds:[di].HGI_takePointer
	mov	ax, MSG_HEARTS_DECK_GET_DECK_ID_NUMBER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	takeId, ch
	pop	si

	Deref_DI Game_offset
	push	si
	movdw	bxsi, ds:[di].HGI_leadPointer
	mov	ax, MSG_HEARTS_DECK_GET_DECK_ID_NUMBER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	leadId, ch
	pop	si

	mov	counter, NUM_PLAYERS

morePlayersLoop:
	mov	bx, playerOffset
	mov	si, cs:[bx].offset
	mov	bx, cs:[bx].handle		;^lbx:si <= deck
	mov	ax, MSG_HEARTS_DECK_GET_PLAYED_CARD_POINTER
	mov	di, mask MF_CALL
	call	ObjMessage
	movdw	bxsi, cxdx			;^lbx:si <= chunk array
	call	MemLock
	mov	ds, ax				;ds <= locked block
	call	ChunkArrayAppend
	mov	al, leadId
	mov	ds:[di].TD_whoLeadId, al
	mov	al, takeId
	mov	ds:[di].TD_whoTookId, al
CheckHack <size HeartsTrickCards eq size dword>
	movdw	ds:[di].TD_cardsPlayed, deckCards, ax
	call	ObjMarkDirty
	call	MemUnlock
	add	playerOffset, size optr
	dec	counter
	jg	morePlayersLoop
	
	.leave
	ret
HeartsGameSetTrickData	endm


heartsGamePlayersTable		optr	\
	ComputerDeck3,
	ComputerDeck2,
	ComputerDeck1,
	MyDeck



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetPlayersData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will set all the players data pointed to by HI_playerDataPtr 
		to reflect the knowledge gained by a card being played.

CALLED BY:	MSG_HEARTS_GAME_SET_PLAYERS_DATA
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		ch	= deckIdNumber of deck playing the card
		cl	= card attributes of card just played.

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will modify data in chunk pointed to by (HI_playerDataPtr)
		for all the players

PSEUDO CODE/STRATEGY:
		If the card is the Queen of Spades, then set all the players
			as not having the Queen of Spades (its already been
			played).
		If the card is the Jack of Diamonds, then set all the players
			as not having the Jack of Diamonds (its already been
			played).
		If the card played does not follow suit, then set that player
			as void in the suit.
		If the suit the player is void in is Spades, then set the
			player as not having the Queen of Spades
		If the suit the player is void in is Diamonds, then set the
			player as not having the Jack of Diamonds.
		If the player is not void in the suit lead, the suit is
			Diamonds, the player is the last one to go,  
			if the Jack was played it would take the trick,
			and it would be benificial to take the trick, then 
			set the player as not having the Jack of Diamonds.
		If the player is not void in the suit lead, the suit is
			Spades, and the King or Ace of spades has already
			been played, then set the player as not having
			the Queen of Spades.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetPlayersData	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_PLAYERS_DATA
	uses	ax, cx, dx

deckIdNumber		local	byte
cardsPlayed		local	byte
takeCardAttr		local	byte
newAssumptions		local	HeartsAssumptions
newVoidSuits		local	HeartsSuits
setIndicator		local	byte

	.enter

	mov	deckIdNumber, ch
	mov	al, ds:[di].HGI_cardsPlayed
	mov	cardsPlayed, al
	mov	al, ds:[di].HGI_takeCardAttr
	mov	takeCardAttr, al
	clr	newAssumptions, newVoidSuits, setIndicator

	and	cl, RANK_MASK or SUIT_MASK
	cmp	cl, QUEEN or SPADES
	jne	notTheQueenOfSpades
;isQueenOfSpades:
	push	ax, cx
;	or	newAssumptions, mask HA_NO_QUEEN
	mov	ch, mask HA_NO_QUEEN
;	mov	setIndicator, SET_ASSUMPTIONS_FOR_ALL_PLAYERS
	mov	al, SET_ASSUMPTIONS_FOR_ALL_PLAYERS
	jmp	setAllAssumptions

notTheQueenOfSpades:
	cmp	cl, JACK or DIAMONDS
	jne	checkVoid

;isJackOfDiamonds:
	push	ax, cx
;	or	newAssumptions, mask HA_NO_JACK
	mov	ch, mask HA_NO_JACK
;	mov	setIndicator, SET_ASSUMPTIONS_FOR_ALL_PLAYERS
	mov	al, SET_ASSUMPTIONS_FOR_ALL_PLAYERS

setAllAssumptions:
;	mov	al, setIndicator
	mov	ah, deckIdNumber
	mov	cl, newVoidSuits
;	mov	ch, newAssumptions
	clr	dl				;incremental score = 0
	call	HeartsGameModifyPlayersData
	pop	ax, cx

checkVoid:
	tst	cardsPlayed
	jz	notVoid				;first card of trick
	and	cl, SUIT_MASK
	and	al, SUIT_MASK
	cmp	al, cl
	je	notVoid				;will jump if not void

;void:	
	cmp	al, SPADES
	jne	notVoidInSpades
;voidInSpades:
	or	newAssumptions, mask HA_NO_QUEEN
	or	newVoidSuits, mask HS_SPADES
	jmp	startSettingData
notVoidInSpades:
	cmp	al, DIAMONDS
	jne	notVoidInDiamonds
	or	newAssumptions, mask HA_NO_JACK
	or	newVoidSuits, mask HS_DIAMONDS
	jmp	startSettingData
notVoidInDiamonds:
	cmp	al, HEARTS
	jne	voidInClubs
	or	newVoidSuits, mask HS_HEARTS
	jmp	startSettingData
voidInClubs:
	or	newVoidSuits, mask HS_CLUBS
	jmp	startSettingData

notVoid:
	mov	ah, al				;ah <= take card suit
	mov	al, takeCardAttr
	call	HeartsDeckGetCardRank		;al <= rank of card (2-14)
	cmp	ah, DIAMONDS
	jne	notDiamonds
;isDiamonds:
	cmp	cardsPlayed, NUM_PLAYERS - 1
	jl	startSettingData		;jump if not the last player
	cmp	al, RANK_VALUE_OF_JACK
	jg	startSettingData		;jump if take card > Jack

	mov	ax, MSG_HEARTS_DECK_CALCULATE_SCORE
	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	cx, MAXIMUM_POINTS_BEFORE_DEFINITELY_BAD
	jg	startSettingData		;jump if taking would be bad

	or	newAssumptions, mask HA_NO_JACK
	jmp	startSettingData
notDiamonds:
	cmp	ah, SPADES
	jne	startSettingData		;jump if suit is not spades
	cmp	al, RANK_VALUE_OF_QUEEN
	jl	startSettingData		;jump if take card < queen
	or	newAssumptions, mask HA_NO_QUEEN


startSettingData:
	mov	al, setIndicator
	mov	ah, deckIdNumber
	mov	cl, newVoidSuits
	mov	ch, newAssumptions
	clr	dl				;incremental score = 0
	call	HeartsGameModifyPlayersData

	.leave
	ret
HeartsGameSetPlayersData	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameModifyPlayersData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will modify the PlayersData for all the playing decks.

CALLED BY:	HeartsGameSetPlayersData

PASS:		ds	= seg pointer

		al	= setIndicator
		ah	= deckIdNumber
		cl	= newVoidSuits
		ch	= newAssumptions
		dl	= incremental score

RETURN:		ds	= updated seg pointer
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/12/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameModifyPlayersData	proc	near

newStuff		local	word	push	cx
segPointer		local	lptr
setIndicator		local	byte
deckIdNumber		local	byte
playerOffset		local	word
counter			local	byte

	.enter

	mov	dh, ch				;dh <= newAssumptions
	mov	setIndicator, al
	dec	ah				;adjust deck ID for array
	mov	deckIdNumber, ah
	mov	bx, ds:[LMBH_handle]
	mov	segPointer, bx
	mov	playerOffset, offset heartsGamePlayersTable
	mov	counter, NUM_PLAYERS

morePlayersLoop:
	push	dx				;save incremental score
	mov	bx, playerOffset
	mov	si, cs:[bx].offset
	mov	bx, cs:[bx].handle		;^lbx:si <= deck
	mov	ax, MSG_HEARTS_DECK_GET_PLAYERS_DATA_POINTER
	mov	di, mask MF_CALL
	call	ObjMessage
	movdw	bxsi, cxdx			;^lbx:si <= chunk array
	pop	dx				;restore incremental score
	call	MemLock
	mov	ds, ax				;ds <= locked block

	clr	ax
	cmp	setIndicator, SET_ASSUMPTIONS_FOR_ALL_PLAYERS
	jne	dontSetEveryonesAssumptions
setEveryonesAssumptions:
	call	ChunkArrayElementToPtr
	or	ds:[di].PD_cardAssumptions, dh
	inc	al
	cmp	al, NUM_PLAYERS
	jl	setEveryonesAssumptions

dontSetEveryonesAssumptions:
	mov	al, deckIdNumber
	call	ChunkArrayElementToPtr
	mov	cx, newStuff
	or	ds:[di].PD_voidSuits, cl
	or	ds:[di].PD_cardAssumptions, ch
	add	ds:[di].PD_points, dl
	call	ObjMarkDirty
	call	MemUnlock
	add	playerOffset, size optr
	dec	counter
	jg	morePlayersLoop

	mov	bx, segPointer
	call	MemDerefDS

	.leave
	ret
HeartsGameModifyPlayersData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSetShootData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will set the shoot data which indicates who, if anyone
		is possibly trying to shoot.

CALLED BY:	HeartsDeckTakeCardsIfOK, and HeartsDeckPlayTopCard
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/ 5/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSetShootData	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_SET_SHOOT_DATA

gameOffset		local	word		push	si
shootingDeckID		local	byte

	.enter

	mov	al, ds:[di].HGI_shootData
	cmp	al, SHOOTING_NOT_POSSIBLE
	LONG je	exitRoutine
	cmp	al, SHOOTING_NOT_DETERMINED
	je	shootingNotDetermined
	cmp	al, SHOOTING_SET_AS_TAKER
	je	shootingSetAsTaker
;checkStillShooting:
	mov	shootingDeckID, al
	movdw	bxsi, ds:[di].HGI_takePointer
	mov	ax, MSG_HEARTS_DECK_GET_DECK_ID_NUMBER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	shootingDeckID, ch			;check if deck shooting
							;is taking trick
	je	exitRoutine
	call	HeartsGameCheckIfPointsOut
	jnc	exitRoutine				;no Points played

	mov	si, gameOffset
	mov	cl, shootingDeckID
	mov	ax, MSG_HEARTS_GAME_CHECK_IF_DECK_PLAYED
	call	ObjCallInstanceNoLock
	cmp	cl, ch					;when deck plays <=>
							;number cards played

	jg	exitRoutine				;shooting deck hasnt
							;gone yet.

;shooting deck has gone and isnt taking trick with points in it.

	mov	si, gameOffset
	Deref_DI Game_offset
	mov	ds:[di].HGI_shootData, SHOOTING_NOT_POSSIBLE
	jmp	exitRoutine


shootingNotDetermined:
	call	HeartsGameCheckIfPointsOut
	jnc	exitRoutine				;no Points played.
	Deref_DI Game_offset
	cmp	ds:[di].HGI_cardsPlayed, NUM_PLAYERS - 1
	je	setTaker				;last person to go
	mov	ds:[di].HGI_shootData, SHOOTING_SET_AS_TAKER
	jmp	exitRoutine

shootingSetAsTaker:
	cmp	ds:[di].HGI_cardsPlayed, NUM_PLAYERS - 1
	jne	exitRoutine				;not last person to
							;go; don't do anything
setTaker:
	movdw	bxsi, ds:[di].HGI_takePointer
	mov	ax, MSG_HEARTS_DECK_GET_DECK_ID_NUMBER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, gameOffset				;restore offset
	Deref_DI Game_offset
	mov	ds:[di].HGI_shootData, ch		;shootdata <= deck ID

exitRoutine:

	.leave
	ret
HeartsGameSetShootData	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameGetShootData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return who, if anyone, is possibly trying to shoot.

CALLED BY:	MSG_HEARTS_GAME_GET_SHOOT_DATA
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data

RETURN:		cl	= shootData

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameGetShootData	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_GET_SHOOT_DATA
	.enter

	mov	cl, ds:[di].HGI_shootData

	.leave
	ret
HeartsGameGetShootData	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameCheckIfDeckPlayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return when the deck will play a card (ie. 0 if
		the deck is leading, and NUM_CARDS-1 if deck is last
		deck to play)

CALLED BY:	HeartsGameSetShootData & 
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		cl	= deck ID

RETURN:		cl	= when deck plays card.
		ch	= number of cards played.

DESTROYED:	ax, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameCheckIfDeckPlayed	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_CHECK_IF_DECK_PLAYED
	.enter

	mov	dl, ds:[di].HGI_cardsPlayed		;dl <= cards played
	movdw	bxsi, ds:[di].HGI_leadPointer
	mov	ax, MSG_HEARTS_DECK_GET_DECK_ID_NUMBER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	cl, ch					;cmp deckID <=> leadID
							;check if adjustment is
							;needed for order of 
							;play
	jge	noAdjustmentNeeded
;adjust:
	add	cl, NUM_PLAYERS
noAdjustmentNeeded:
	sub	cl, ch					;cl <= when deck plays
	mov	ch, dl					;ch <= cards played

	.leave
	ret
HeartsGameCheckIfDeckPlayed	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameCheckIfPointsOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check to see if any hearts or the Queen of Spades
		are in DiscardDeck.

CALLED BY:	HeartsGameSetShootData
PASS:		nothing
RETURN:		carry set if points in DiscardDeck
		carry not set if not bad cards in DiscardDeck

DESTROYED:	ax, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameCheckIfPointsOut	proc	near
	uses	si
	.enter

	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	ax, MSG_HEARTS_DECK_CALCULATE_SCORE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	tst	al				;check number of positive
						;points
	clc
	jz	exitRoutine
	stc					;there are bad cards in the
						;discard deck.

exitRoutine:
	.leave
	ret
HeartsGameCheckIfPointsOut	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameSendToPlayers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will send the message in ax to all the players of the game

CALLED BY:	HeartsGameNewGame
PASS:		*ds:si	= instance data of game
		ax	= message
		di	= MessageFlags
		cx,dx,bp = data to send to players

RETURN:		ax	= destroyed
		cx,dx,bp = return values from human player
		bx,si,di = unchanged
		ds	= updated segment

DESTROYED:	nothing
SIDE EFFECTS:	ds must point to a valid segment because MF_FIXUP_DS is sent
		to all the players.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/24/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameSendToPlayers	proc	near
	uses	bx,si,di
	.enter

	push	ax,cx,dx,bp,di				;save data
	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	call	ObjMessage

	pop	ax,cx,dx,bp,di				;restore data
	push	ax,cx,dx,bp,di				;save data
	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	call	ObjMessage

	pop	ax,cx,dx,bp,di				;restore data
	push	ax,cx,dx,bp,di				;save data
	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	call	ObjMessage

	pop	ax,cx,dx,bp,di				;restore data
	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	call	ObjMessage

	.leave
	ret
HeartsGameSendToPlayers	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameDeal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_HEARTS_GAME_DEAL handler for HeartsGameClass
		Deals out cards for a new Hearts game

CALLED BY:	MSG_HEARTS_GAME_DEAL
PASS:		*ds:si	= HeartsGameClass object
		ds:di	= HeartsGameClass instance data
		ds:bx	= HeartsGameClass object (same as *ds:si)
		es 	= segment of HeartsGameClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameDeal	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_DEAL
	.enter


	mov	cx, 13			;number of rounds of deals
	push	si			;game offset

RoundsLoop:
	push	cx			;save number of rounds to deal

	;   We want this to be fast. So let's try it in line.
	;

	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_DECK_POP_CARD
	call	ObjMessage

	;    Players card is face up
	;

	movdw	bxsi,cxdx			
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CARD_TURN_FACE_UP
	call	ObjMessage

	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_DECK_PUSH_CARD
	call	ObjMessage

	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_DECK_POP_CARD
	call	ObjMessage

	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_DECK_PUSH_CARD
	call	ObjMessage

	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_DECK_POP_CARD
	call	ObjMessage

	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_DECK_PUSH_CARD
	call	ObjMessage

	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_DECK_POP_CARD
	call	ObjMessage

	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_DECK_PUSH_CARD
	call	ObjMessage

	pop	cx
	dec	cx
	jcxz	sort
	jmp	RoundsLoop

sort:
	pop	si					;game offset
	mov	ax, MSG_HEARTS_DECK_SORT_DECK		;sort all the decks
	mov	di, mask MF_CALL			;or mask MF_FIXUP_DS
	call	HeartsGameSendToPlayers

if WAV_SOUND
	mov	cx,HS_CARD_ARRANGE
	call	HeartsGamePlaySound
endif

	mov	di, mask MF_CALL			;or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_REDRAW_IF_FACE_UP
	call	HeartsGameSendToPlayers

	.leave
	ret
HeartsGameDeal	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameFlipComputerDecks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will flip all the cards of the computer decks

CALLED BY:	HeartsFlipTrigger
PASS:		*ds:si	= HeartsGameClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	will flip the cards of the computer decks

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameFlipComputerDecks	method dynamic HeartsGameClass, 
					MSG_HEARTS_GAME_FLIP_COMPUTER_DECKS
	.enter

	mov	bx, handle ComputerDeck1
	mov	si, offset ComputerDeck1
	mov	di, mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_FLIP_CARDS
	call	ObjMessage

	mov	bx, handle ComputerDeck2
	mov	si, offset ComputerDeck2
	mov	di, mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_FLIP_CARDS
	call	ObjMessage

	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	di, mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_FLIP_CARDS
	call	ObjMessage

	.leave
	ret
HeartsGameFlipComputerDecks	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGameQueryDragCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_QUERY_DRAG_CARD handler for HeartsGameClass
		This is the method that a deck calls when one of
		its cards is selected. This method determines whether
		a given card should be included in the drag or not,
		depending on the deck's attributes. For example, in the
		following scenario:


			+--------------------+
			!                    !
			! 6 Hearts           !
			!                    !
			+--------------------+
			!                    !
			! 5 Clubs            !
			!                    !
			+--------------------+
			!                    !
			! 4 Diamonds         !
			!                    !
			+--------------------+
			!                    !
			! 3 Clubs            !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			+--------------------+

		if the 4 is selected, and we are playing hearts
		we want to drag only the 4.



CALLED BY:	MSG_GAME_QUERY_DRAG_CARD
PASS:		ds:di = game instance
		*ds:si = game object
		ch = # of selected card		;(the 4 in the above example)
		cl = attrs of selected card	;(the 4 in the above example)

		dh = # of query card
		dl = attrs of query card

		bp = deck attrs

RETURN:		carry set if accept
		carry clear if no accept
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGameQueryDragCard	method dynamic HeartsGameClass, 
					MSG_GAME_QUERY_DRAG_CARD
	.enter

	cmp	ch, dh		;check if query card = selected card
	clc			;clear the carry flag, to indicate no drag
	jnz	HeartsGameQueryDone
	stc			;set the carry flag because we
				;want to be able to drag this card
	
HeartsGameQueryDone:

	.leave
	ret
HeartsGameQueryDragCard	endm



CommonCode 	ends		;end of CommonCode resource
