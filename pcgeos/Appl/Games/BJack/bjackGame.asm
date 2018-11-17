COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Black Jack!
FILE:		bjackGame.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	bchow	3/93		Initial Version

DESCRIPTION:


RCS STAMP:
$Id: bjackGame.asm,v 1.1 97/04/04 15:46:12 newdeal Exp $
------------------------------------------------------------------------------@

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
;			Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Object Class include files
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

BJackGameClass		class	GameClass

MSG_BORROW_ONE_HUNDRED_DOLLARS	message

MSG_BORROW_ONE_HUNDRED_DOLLARS_SET_WAITING_FOR_NEW_GAME	message
;	Sent by CASH OUT/BORROW 100 box. The game is currently in
;	a BUSY status and needs to be changed to WAITING_FOR_NEW_GAME

MSG_DISPLAY_WELCOME_TEXT	message

MSG_STAY		message

MSG_DOUBLE_DOWN		message

MSG_SPLIT		message

MSG_INSURANCE		message

MSG_GAME_FADE_COUNT	message

MSG_FINISH_FADE		message

MSG_DISPLAY_CASH	message

MSG_BUST		message

MSG_HIT			message

MSG_CASH_OUT		message

MSG_CASH_OUT_SET_WAITING_FOR_NEW_GAME		message

;	Sent by CASH OUT/BORROW 100 box. The game is currently in
;	a BUSY status and needs to be changed to WAITING_FOR_NEW_GAME

MSG_CASH_TO_TEXT	message
;
;	Writes the current score (cash) to a text display object.
;
;	PASS:		^lcx:dx = text display object
;
;	RETURN:		nothing

MSG_CHECK_FUNDS		message

MSG_CHECK_MAXIMUM_BET	message
;
;	Makes sure that the passed value does not exceed the maximum payoff
;	for this Black Jack game. If it does, the maximum value is returned.
;
;	PASS:		dx = amount to check
;
;	RETURN:		dx = the lesser of the passed value and the max win

MSG_DEAL		message
;
;	Deals out cards for a new game.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_GET_NEXT_CARD	message
;
;	Removes the top card from the game's hand object.
;
;	PASS:		nothing
;
;	RETURN:		^lcx:dx = card popped from hand

MSG_INSERT_COIN		message
;
;	Add some $$$ to the wager amount, and correspondingly subtract an
;	equal amount of $$$ from the cash reserves. These changes are
;	automatically updated on the screen.
;
;	PASS:		dx = amount to insert
;
;	RETURN:		nothing

MSG_BET_IT_ALL		message
;
;	Begins a new game with the user's entire cash amount.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_LET_IT_RIDE		message
;
;	Begins a new game with the wager set to however much was won in the
;	previous game.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_NEW_GAME	message
;
;	Starts a new game by disabling UI that is to be unaccessible
;	during a game, collecting all the cards int the hand, redrawing
;	the decks, shuffling, and dealing.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_PREPARE_TO_HIT	message
;
;	Mark the game object as ready to accept user input w/respect to
;	the second "phase" of the game, wherein the user discards unwanted
;	cards and gets them replaced with new ones, etc.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SETTLE_BETS		message
;
;	Checks to see what Black Jack hand the user has been dealt,
;	then pays off the winnings if need be.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SET_FADE_STATUS	message
;
;	Turns fading either on or off for this game.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_TIDY_UP		message
;
;	Marks the game object as being ready for a new game.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_UPDATE_WAGER	message
;
;	Changes the amount of money being wagered.
;
;	PASS:		cx, dx = how to update the wager. the following
;				 convention is used:
;
;			if (cx) {
;					wager = cx;
;			}
;			else if (dx) {
;					wager += dx;
;			}
;			else {				/* cx = dx = 0 */
;				wager = 0;
;			}
;
;	RETURN:		nothing

MSG_FREE_MILLION	message

MSG_GAME_INITIALIZE	message

MSG_ADJUST_WAGER_AND_CASH	message
;	cx - amount to 	increase bet and decrease cash

MSG_ADJUST_WAGER_AND_CASH_FROM_TRIGGERS	message

MSG_ADJUST_WAGER_AND_CASH_NO_LIMIT	message

INITIAL_CASH = 100
INITIAL_WAGER = 5

FONT_SIZE = 10

MAXIMUM_BET = 5000

GAME_MAXIMUM = 21		;>21 = bust
GAME_MINIMUM = 17		;<17 dealer has to hit

DEAL_DELAY = 60			;1 second

BLACK_JACK_VALUE = (2 shl 8) or GAME_MAXIMUM
;
;	Value returned by MSG_SUM_DECK if hand is a black jack.
;

BJackAcesSplit			etype	word
ALL_SPLIT			enum	BJackAcesSplit
ACES_ONLY_SPLIT			enum	BJackAcesSplit

BJackDoubleDown			etype	word
DOUBLE_DOWN_ELEVEN		enum	BJackDoubleDown
DOUBLE_DOWN_TEN_AND_ELEVEN	enum	BJackDoubleDown

BJackDealerStay			etype	word
DEALER_STAY_HARD_SEVENTEEN	enum	BJackDealerStay
DEALER_STAY_SOFT_SEVENTEEN	enum	BJackDealerStay

BJackGameStatus			etype	byte
WAITING_FOR_NEW_GAME		enum	BJackGameStatus
WAITING_TO_HIT			enum	BJackGameStatus
WAITING_TO_HIT2			enum	BJackGameStatus
BUSY				enum	BJackGameStatus

BJackGameSpecial		etype	byte
NONE				enum	BJackGameSpecial, 0
DOUBLE_DOWN			enum	BJackGameSpecial, 1
SPLIT				enum	BJackGameSpecial, 2
INSURANCE			enum	BJackGameSpecial, 4


ATTR_BJACK_GAME_OPEN	vardata	byte
; indicates that the game object is open and has not yet been saved
; to state.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;			INSTANCE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BGI_special			BJackGameSpecial

BGI_cash			dword		;this represents the user's
						;cash won so far; in effect
						;his score. The score in 
						;GameClass is not used, as
						;it is crucial that the score
						;here be a dword, lest the
						;user easily overflow (or
						;underflow :) the score.

BGI_markers			word

BGI_wager			word			;amount bet this game
BGI_status			BJackGameStatus
BGI_haveName			word			;non zero if
							;have asked for 
							;loan name
BJackGameClass	endc

MyDeckClass			class		DeckClass

MSG_SET_CARD			message

MSG_SUM_DECK			message

MSG_SUM_DECK_FOR_DOUBLE_DOWN			message

MSG_PLAY			message

MSG_PLAY_LOOP			message

MSG_FLIP_SECOND_CARD		message

MyDeckClass			endc

BJackHighScoreClass	class	HighScoreClass
BJackHighScoreClass	endc


BJackInteractionClass	class	GenInteractionClass

MSG_BJACK_CHECK_HAVE_NAME	message

MSG_BJACK_SET_HAVE_NAME	message

BI_askedForLoanNameThisGame	word

BJackInteractionClass	endc


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

	BJackGameClass

	MyDeckClass

	BJackHighScoreClass

	BJackInteractionClass

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends

;------------------------------------------------------------------------------
;		Code for BJackGameClass
;------------------------------------------------------------------------------
CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackGameSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SETUP_GEOMETRY handler for BJackGameClass
		Arranges the game's objects according to how big a card
		is (which should give some indication of screen resolution).

CALLED BY:	

PASS:		cx = horizontal deck spacing
		dx = vertical deck spacing

CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameSetupGeometry	method	BJackGameClass, MSG_GAME_SETUP_GEOMETRY

	uses	ax, bx, cx, dx, si, di
	.enter

	mov	di, offset BJackGameClass
	call	ObjCallSuperNoLock

	mov	cx, HAND_LEFT
	mov	dx, HAND_TOP
	mov	bx, handle MyHand
	mov	si, offset MyHand
	call	BJackPositionDeck

	mov	cx, DECK1_LEFT
	mov	dx, DECK1_TOP
	mov	bx, handle Deck1
	mov	si, offset Deck1
	call	BJackPositionDeck

	;
	;	Hide the "Split" deck first.
	;
	mov	cx, -1000
	mov	dx, -1000
	mov	bx, handle Deck3
	mov	si, offset Deck3
	call	BJackPositionDeck

	mov	cx, DECK2_LEFT
	mov	dx, DECK2_TOP
	mov	bx, handle Deck2
	mov	si, offset Deck2
	call	BJackPositionDeck

	mov	cx, HAND_INSTRUCTION_LEFT
	mov	dx, HAND_INSTRUCTION_TOP
	mov	bx, handle HandInstructions
	mov	si, offset HandInstructions
	call	BJackPositionDeck

	mov	cx,HAND_INSTRUCTION_WIDTH
	mov	dx,INSTRUCTION_HEIGHT
	mov	ax,MSG_VIS_SET_SIZE
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx, DECK1_INSTRUCTION_LEFT
	mov	dx, DECK1_INSTRUCTION_TOP
	mov	bx, handle Deck1Instructions
	mov	si, offset Deck1Instructions
	call	BJackPositionDeck

	mov	cx,INSTRUCTION_WIDTH
	mov	dx,INSTRUCTION_HEIGHT
	mov	ax,MSG_VIS_SET_SIZE
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx, DECK2_INSTRUCTION_LEFT
	mov	dx, DECK2_INSTRUCTION_TOP
	mov	bx, handle Deck2Instructions
	mov	si, offset Deck2Instructions
	call	BJackPositionDeck

	mov	cx,INSTRUCTION_WIDTH
	mov	dx,INSTRUCTION_HEIGHT
	mov	ax,MSG_VIS_SET_SIZE
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx, DECK3_INSTRUCTION_LEFT
	mov	dx, DECK3_INSTRUCTION_TOP
	mov	bx, handle Deck3Instructions
	mov	si, offset Deck3Instructions
	call	BJackPositionDeck

	mov	cx,INSTRUCTION_WIDTH
	mov	dx,INSTRUCTION_HEIGHT
	mov	ax,MSG_VIS_SET_SIZE
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage


	;
	;	Place discard deck out of sight...
	;
	mov	cx, -1000
	mov	dx, -1000
	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	call	BJackPositionDeck

	mov	ax, MSG_GAME_SET_UP_SPREADS
	mov	cx, SPREAD
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_GAME_SET_DOWN_SPREADS
	mov	cx, SPREAD
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
BJackGameSetupGeometry	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackAdjustWagerAndCashFromTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow adjusting of wager and cash only between hands.
		This message is sent by the ui triggers so that the
		player cannot change the bet at illegal times.s

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BJackGameClass

		cx - amount to increase wager and decrease cash

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
	srs	6/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackAdjustWagerAndCashFromTriggers	method dynamic BJackGameClass, 
					MSG_ADJUST_WAGER_AND_CASH_FROM_TRIGGERS
	.enter

	cmp	ds:[di].BGI_status, WAITING_FOR_NEW_GAME
	jne	done

	mov	ax,MSG_ADJUST_WAGER_AND_CASH
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
BJackAdjustWagerAndCashFromTriggers		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackAdjustWager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the bet by the passed amount

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BJackGameClass

		cx - wager delta

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
	srs	6/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackAdjustWager	method dynamic BJackGameClass, 
						MSG_ADJUST_WAGER_AND_CASH
	uses	cx,dx
	.enter

	call	ObjMarkDirty

	;    Reset cash to total money player has
	;

	mov	ax,ds:[di].BGI_wager
	add	ds:[di].BGI_cash.low,ax
	adc	ds:[di].BGI_cash.high,0

	add	cx,ax				;delta + wager
	jcxz	toOne
	tst	cx
	js	toOne
	tst	ds:[di].BGI_cash.high
	jnz	checkMaxBet
	cmp	cx,ds:[di].BGI_cash.low
	jle	checkMaxBet
	mov	cx,ds:[di].BGI_cash.low
checkMaxBet:
	mov	dx,cx
	mov	ax,MSG_CHECK_MAXIMUM_BET
	call	ObjCallInstanceNoLock
	mov	cx,dx

setWager:
	mov	ds:[di].BGI_wager,cx
	mov	dx,cx
	clr	cx	
	call	DisplayBet

	;    Reset cash to total - bet
	;

	PointDi2 Game_offset
	mov	dx,ds:[di].BGI_wager
	sub	ds:[di].BGI_cash.low,dx
	sbb	ds:[di].BGI_cash.high,0
	mov	cx,ds:[di].BGI_cash.high
	mov	dx,ds:[di].BGI_cash.low
	call	DisplayCash

	.leave
	ret

toOne:
	mov	cx,1
	jmp	setWager

BJackAdjustWager		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackAdjustWagerNoLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the bet by the passed amount with out imposing
		the betting limit. This solves problems with
		doubling down and splitting

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BJackGameClass

		cx - wager delta

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
	srs	6/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackAdjustWagerNoLimit	method dynamic BJackGameClass, 
					MSG_ADJUST_WAGER_AND_CASH_NO_LIMIT
	uses	cx,dx
	.enter

	call	ObjMarkDirty

	;    Reset cash to total money player has
	;

	mov	ax,ds:[di].BGI_wager
	add	ds:[di].BGI_cash.low,ax
	adc	ds:[di].BGI_cash.high,0

	add	cx,ax				;delta + wager
	jcxz	toOne
	tst	cx
	js	toOne
	tst	ds:[di].BGI_cash.high
	jnz	setWager
	cmp	cx,ds:[di].BGI_cash.low
	jle	setWager
	mov	cx,ds:[di].BGI_cash.low
setWager:
	mov	ds:[di].BGI_wager,cx
	mov	dx,cx
	clr	cx	
	call	DisplayBet

	;    Reset cash to total - bet
	;

	PointDi2 Game_offset
	mov	dx,ds:[di].BGI_wager
	sub	ds:[di].BGI_cash.low,dx
	sbb	ds:[di].BGI_cash.high,0
	mov	cx,ds:[di].BGI_cash.high
	mov	dx,ds:[di].BGI_cash.low
	call	DisplayCash

	.leave
	ret

toOne:
	mov	cx,1
	jmp	setWager

BJackAdjustWagerNoLimit		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackPositionDeck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes a location from card size units to screen units,
		then moves a deck to that point.

CALLED BY:	KlondikeSetupGeometry

PASS:		^lbx:si	= deck to move
		cx,dx = left, top position
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackPositionDeck	proc	near
	uses	ax, di
	.enter

	;
	;	Move the deck to the newly calculated location
	;
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
BJackPositionDeck	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackGameUpdateScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_UPDATE_SCORE handler for BJackGameClass
		Had to subclass this baby because BJack score is
		a dword, and the score from the cards library is
		but a word. alas...

CALLED BY:	

PASS:		ds:di = BJackGame instance
		*ds:si = BJackGame object
		if score is to be zeroed:
			cx = dx = 0
		if score is to be set absolutely but not to 0:
			cx = value to set score to
		if score is to be incremented or decremented:
			cx = 0, dx = amount to add to current score
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		Sets up score, then calls DisplayCash.

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameUpdateScore	method	BJackGameClass, MSG_GAME_UPDATE_SCORE
	uses	cx,dx,bp
	.enter
	tst	cx				;set score absoultely?
	jnz	setCash				;if so, do it!
	tst	dx				;set score to zero?
	jz	setCash				;if so, do it too.
	;
	;	Since our score is a dword, we need to see whether
	;	the incremental amount of cash is positive or negative
	;	so that we can properly inc/dec the high word
	;
	jg	addToCash
	;
	;	The amount is negative, so we negate it and subtract it
	;
	neg	dx
	sub	ds:[di].BGI_cash.low, dx
	sbb	ds:[di].BGI_cash.high, 0	;the high word -= borrow bit
	jmp	setText
addToCash:
	;
	;	The amount is positive, so we add it
	;
	add	ds:[di].BGI_cash.low, dx
	adc	ds:[di].BGI_cash.high, 0	;the high word += carry bit
	jmp	setText
setCash:
	clr	ds:[di].BGI_cash.high
	mov	ds:[di].BGI_cash.low, cx
setText:
	mov	cx, ds:[di].BGI_cash.high
	mov	dx, ds:[di].BGI_cash.low
	call	DisplayCash
	.leave
	ret
BJackGameUpdateScore	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackGameUpdateWager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_UPDATE_WAGER handler for BJackGameClass
		Changes the amount of $$ currently being wagered.

CALLED BY:	

PASS:		*ds:si = BJackGame object
		ds:di = BJackGame instance

		cx,dx = how to update wager. read on:

		The following paradigm is in effect for wager updating:

		if (cx) {
				wager = cx;
		}
		else if (dx) {
				wager += dx;
		}
		else { 					/* cx = dx = 0 */
				wager = 0;
		}
		
CHANGES:	

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameUpdateWager	method	BJackGameClass, MSG_UPDATE_WAGER

	jcxz	relativeOrZero
dealWithWagerTrigger:
	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset
	mov	ds:[di].BGI_wager, cx
	mov	dx, cx
	clr	cx
	call	DisplayBet

	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset
	ret

relativeOrZero:
	tst	dx
	jz	dealWithWagerTrigger	
	mov	cx, ds:[di].BGI_wager		;the score relatively
	add	cx, dx
	jmp	dealWithWagerTrigger
BJackGameUpdateWager	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				BJackGameDeal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DEAL handler for BJackGameClass
		Deals out cards for a new BJack game
CALLED BY:	

PASS:		nothing
		
CHANGES:

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameDeal	method	BJackGameClass, MSG_DEAL
	uses	ax, dx, si, di, bp
	.enter


	;
	;	Pass dealer two cards, flip second card.
	;
	mov	ax, MSG_GET_NEXT_CARD
	call	ObjCallInstanceNoLock
	CallObject	Deck1, MSG_DECK_GET_DEALT, MF_FIXUP_DS

	mov	ax, MSG_GET_NEXT_CARD
	call	ObjCallInstanceNoLock
	CallObject	Deck1, MSG_DECK_GET_DEALT, MF_FIXUP_DS

	;
	;	Pass player two cards, flip both.
	;
	mov	ax, MSG_GET_NEXT_CARD
	call	ObjCallInstanceNoLock
	CallObject	Deck2, MSG_DECK_GET_DEALT, MF_FIXUP_DS
	CallObject	Deck2, MSG_CARD_FLIP_CARD, MF_FIXUP_DS

	mov	ax, MSG_GET_NEXT_CARD
	call	ObjCallInstanceNoLock
	CallObject	Deck2, MSG_DECK_GET_DEALT, MF_FIXUP_DS


	CallObject	Deck1, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
	CallObject	Deck2, MSG_CARD_FLIP_CARD, MF_FIXUP_DS

	.leave
	ret
BJackGameDeal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackGameGetNextCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GET_NEXT_CARD handler for BJackGameClass
		Grabs the top card off of the game's hand object

CALLED BY:	

PASS:		ds:di = game instance
		
CHANGES:	removes hand object's top card

RETURN:		^lcx:dx = card from top of hand object

DESTROYED:	ax, bx, di, si

PSEUDO CODE/STRATEGY:
		send a MSG_DECK_POP_CARD to the hand object

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameGetNextCard	method	BJackGameClass, MSG_GET_NEXT_CARD
	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	ax, MSG_DECK_POP_CARD
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	GOTO	ObjMessage
BJackGameGetNextCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				BJackGameNewGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_NEW_GAME handler for BJackGameClass
		Starts a new game by disabling UI that is to be unaccessible
		during a game, collecting all the cards int the hand, redrawing
		the decks, shuffling, and dealing.

CALLED BY:	

PASS:		*ds:si = game object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		gives the hand all the cards
		instructs the hand to shuffle the cards
		instructs the hand to deal the cards
		initializes time and score displays

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameNewGame	method	BJackGameClass, MSG_NEW_GAME

	cmp	ds:[di].BGI_status, WAITING_FOR_NEW_GAME
	jne	done

	;
	;	If there is no wager, then we can't play a game.
	;
	;	Something should be added here to tel the user why
	;	the game is not dealing. Maybe we should just force
	;	a $1 wager, and go with it
	;

	tst	ds:[di].BGI_wager
	jz	done

	mov	ds:[di].BGI_status, BUSY

	;	New Game:
	;
	;	Disable the gadgets that let the user add more $$$, add
	;	wild cards, etc.
	;
	mov	dl, VUM_NOW
	push	si
	CallObjectNS CashOutTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	CallObjectNS BorrowTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	CallObjectNS RulesInteraction, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	pop	si

	call	BJackGameClearCardsFromScreen

	;    just in case it didn't get shuffled before
	;

	call	BJackGameShuffleIfNecessary

	;
	;	shuffle the cards
	;
	;	We are just shuffling the cards within the hand, so
	;	it's ok (even though it says don't shuffle...)
	;
	CallObject	MyHand, MSG_HAND_SHUFFLE, MF_FIXUP_DS

	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset

	;
	;	Turn off double down, split and insurance.
	;
	mov	ds:[di].BGI_special, NONE

	;
	;	Prevent the player from doing anything stupid
	;	until the cards are on the screen and all
	;	dialog boxes have been displayed.
	;

	call	BJackIgnoreInput

	;
	;	Queue a method to deal the cards
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_DEAL
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	;
	;	Queue a method to prepare the game object for the
	;	second half of the game, wherein the user hits or stays.
	;	
	mov	ax, MSG_PREPARE_TO_HIT
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

done:
	ret
BJackGameNewGame	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackIgnoreInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GEN_APPLICATION_IGNORE_INPUT to the
		BJackApp

CALLED BY:	INTERNAL

PASS:		
		nothing

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
	srs	8/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackIgnoreInput		proc	near
	uses	ax,bx,si,di
	.enter

	mov	bx,handle BJackApp
	mov	si,offset BJackApp
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GEN_APPLICATION_IGNORE_INPUT
	call	ObjMessage

	.leave
	ret
BJackIgnoreInput		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackAcceptInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GEN_APPLICATION_ACCEPT_INPUT to the
		BJackApp

CALLED BY:	INTERNAL

PASS:		
		nothing

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
	srs	8/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackAcceptInput		proc	near
	uses	ax,bx,si,di
	.enter

	mov	bx,handle BJackApp
	mov	si,offset BJackApp
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	ObjMessage

	.leave
	ret
BJackAcceptInput		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameClearCardsFromScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate all decks.

CALLED BY:	INTERNAL

PASS:		
		nothing
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
	srs	6/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameClearCardsFromScreen		proc	near
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	CallObjectNS MyHand, MSG_VIS_INVALIDATE, MF_FIXUP_DS
	CallObjectNS Deck1, MSG_VIS_INVALIDATE, MF_FIXUP_DS
	CallObjectNS Deck2, MSG_VIS_INVALIDATE, MF_FIXUP_DS
	CallObjectNS Deck3, MSG_VIS_INVALIDATE, MF_FIXUP_DS

	mov	cx, handle DiscardDeck
	mov	dx, offset DiscardDeck
	CallObjectNS Deck1, MSG_DECK_GET_RID_OF_CARDS, MF_FIXUP_DS
	CallObjectNS Deck2, MSG_DECK_GET_RID_OF_CARDS, MF_FIXUP_DS
	CallObjectNS Deck3, MSG_DECK_GET_RID_OF_CARDS, MF_FIXUP_DS

	;
	;	Hide the "Split" deck again.
	;


	mov	bx,handle Deck3
	mov	si, offset Deck3
	mov	cx, -1000
	mov	dx, -1000
	call	BJackPositionDeck
	mov	si,offset BlankText
	call	SetDeck3InstructionsString

	mov	si, offset DealerText
	call	SetDeck1InstructionsString
	.leave
	ret
BJackGameClearCardsFromScreen		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameShuffleIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shuffle the deck if the appropriate number of
		cards have been played

CALLED BY:	INTERNAL

PASS:		*ds:si - game object

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
	srs	6/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameShuffleIfNecessary		proc	near
	.enter


	call	BJackGameDetermineIfShuffleTime
	jnc	done

	call	BJackGameShuffle

done:
	.leave
	ret

BJackGameShuffleIfNecessary		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameShuffle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shuffle the deck

CALLED BY:	INTERNAL
		BJackGameShuffleIfNecessary
		BJackGameCashOut

PASS:		
		nothing

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
	srs	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameShuffle		proc	near
	uses	ax,bx,cx,dx,bp,di
	.enter

	;
	;	Return any outstanding cards to the hand object
	;
	mov	ax, MSG_GAME_COLLECT_ALL_CARDS
	call	ObjCallInstanceNoLock

	CallObject MyHand, MSG_HAND_SHUFFLE, MF_FIXUP_DS

	.leave
	ret
BJackGameShuffle		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameDetermineIfShuffleTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if it is time to shuffle

CALLED BY:	INTERNAL

PASS:		
		nothing

RETURN:		
		stc - time to shuffle
		clc - not time to shuffle

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
	srs	6/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameDetermineIfShuffleTime		proc	near
	uses	bx,ax,di,cx,dx,bp
	.enter

	;    If less than 26 cards in the deck then shuffle
	;

	CallObject MyHand, MSG_DECK_GET_N_CARDS, MF_CALL
	cmp	cx, 26
	jl	shuffle

	clc
done:

	.leave
	ret

shuffle:
	stc
	jmp	done

BJackGameDetermineIfShuffleTime		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackGamePrepareToHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_PREPARE_TO_HIT handler for BJackGameClass
		Marks the game as being ready for the second phase of play,
		wherein the user discards, etc.

CALLED BY:	

PASS:		ds:di = BJackGame instance
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGamePrepareToHit	method	BJackGameClass, MSG_PREPARE_TO_HIT
	uses	dx, bp
	.enter

	;
	;	Finish fading first, so that player can see his
	;	cards.
	;	
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset
	mov	si, ds:[di].GI_fadeArray
	call	ChunkArrayGetCount
	pop	si
	jcxz	continue

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_PREPARE_TO_HIT
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	done

continue:
	PointDi2 Game_offset
	mov	ds:[di].BGI_status, WAITING_TO_HIT

	push	si				;game chunk
	mov	si, offset PlayText
	call	SetInstructionString
	mov	si,offset HitText
	call	SetHandInstructionsString
	mov	si,offset StayText
	call	SetDeck2InstructionsString
	pop	si				;game chunk

	call	HandleInsurance

	call	HandleBlackJack
	jc	acceptInput			;jmp if someone had black jack

	call	HandleDoubleDown
	jc	acceptInput			;jmp if doubled down

	call	HandleSplit

acceptInput:
	call	BJackAcceptInput
done:
	.leave
	ret
BJackGamePrepareToHit	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleInsurance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the dealer is showing an ace and player can afford
		insurance then ask the player if they want insurance.
		Do insurance if requested.

CALLED BY:	INTERNAL
		BJackGamePrepareToHit

PASS:		*ds:si - Game object

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
	srs	6/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleInsurance	proc	near
	class	BJackGameClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	;
	;	Check if dealer shows Ace (for insurance).
	;
	mov	bp, 0
	CallObject	Deck1, MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
	mov	dx, bp
	mov	cl, offset CA_RANK
	ANDNF	dx, mask CA_RANK
	shr	dx, cl
	cmp	dl, CR_ACE
	jne	done
	;
	;	Check if player can afford insurance (1/2 of wager)
	;
	PointDi2 Game_offset
	tst	ds:[di].BGI_cash.high		;if cash.high<> 0, has cash
	jnz	ask
	mov	cx, ds:[di].BGI_wager
	shr	cx, 1
	jnc	10$
	inc	cx				;round up
10$:
	cmp	ds:[di].BGI_cash.low, cx
	jge	ask

done:
	.leave
	ret

ask:
if WAV_SOUND
	mov	dx,BS_CAN_BUY_INSURANCE
	call	GameStandardSound
endif
	push	si				;game chunk
	mov	bx,handle InsuranceSummons
	mov	si,offset InsuranceSummons
	call	UserDoDialog
	pop	si				;game chunk
	cmp	ax,IC_NULL
	je	systemTermination
	cmp	ax,IC_NO
	je	done
	CallObject MyPlayingTable, MSG_INSURANCE, MF_FORCE_QUEUE
	jmp	done

systemTermination:
	jmp	done

HandleInsurance		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleBlackJack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If either player has black jack then end the hand

CALLED BY:	INTERNAL
		BJackGamePrepareToHit

PASS:		*ds:si - Game object

RETURN:		
		stc - someone had black jack
		clc - no one didn't have black jack

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
	srs	6/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleBlackJack	proc	near
	class	BJackGameClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	CallObject Deck1, MSG_SUM_DECK, MF_CALL
	cmp	ax, BLACK_JACK_VALUE		
	je	dealerHasBlackJack

	CallObject Deck2, MSG_SUM_DECK, MF_CALL
	cmp	ax, BLACK_JACK_VALUE		
	je	stopPlay

	clc

done:
	.leave
	ret

dealerHasBlackJack:
	;    Taunt the player
	;

	push	si
	mov	si,offset DealerBlackJackText
	call	SetInstructionString
	pop	si
stopPlay:
	mov	ax,MSG_STAY
	call	ObjCallInstanceNoLock
	stc
	jmp	done

HandleBlackJack		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleDoubleDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for player in position to double down. If so
		then ask the player if s/he wants double down. Give the
		player double down if asked for.

CALLED BY:	INTERNAL
		BJackGamePrepareToHit

PASS:		*ds:si - Game object

RETURN:		
		stc - player doubled down
		clc - player couldn't or wouldn't double down

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
	srs	6/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleDoubleDown		proc	near
	class	BJackGameClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	;
	;	Check if player can afford to double down (1X wager)
	;

	PointDi2 Game_offset
	tst	ds:[di].BGI_cash.high		;if cash.high<> 0, has cash
	jnz	checkDouble
	mov	cx, ds:[di].BGI_wager
	cmp	ds:[di].BGI_cash.low, cx
	jl	noDouble

checkDouble:
	CallObject DoubleDownRule, MSG_GEN_ITEM_GROUP_GET_SELECTION, MF_CALL

	push	ax, cx				;store DoubleDownRule
	;
	;	Allow double down if player's two cards sum to 10 or 11.
	;
	CallObject	Deck2, MSG_SUM_DECK_FOR_DOUBLE_DOWN, MF_CALL
	pop	cx, cx
	;
	;	If player has 11, always allow double down.
	cmp	al, 11
	je	ask11

	;
	;	If not "double at 10 and 11", don't allow double since not 11.
	;
	cmp	cx, DOUBLE_DOWN_TEN_AND_ELEVEN
	jne	noDouble

	;
	;	Double down if sum of hand = 10.
	;
	cmp	al, 10
	je	ask10

noDouble:
	clc

done:
	.leave
	ret

ask10:
if WAV_SOUND
	mov	dx,BS_CAN_DOUBLE_DOWN
	call	GameStandardSound
endif
	push	si				;game chunk
	mov	bx,handle DoubleDown10Summons
	mov	si,offset DoubleDown10Summons
	call	UserDoDialog
	pop	si				;game chunk
	cmp	ax,IC_NULL
	je	systemTermination
	cmp	ax,IC_NO
	je	noDouble
	CallObject MyPlayingTable, MSG_DOUBLE_DOWN, MF_FORCE_QUEUE
	stc
	jmp	done


ask11:
if WAV_SOUND
	mov	dx,BS_CAN_DOUBLE_DOWN
	call	GameStandardSound
endif
	push	si				;game chunk
	mov	bx,handle DoubleDown11Summons
	mov	si,offset DoubleDown11Summons
	call	UserDoDialog
	pop	si				;game chunk
	cmp	ax,IC_NULL
	je	systemTermination
	cmp	ax,IC_NO
	je	noDouble
	CallObject MyPlayingTable, MSG_DOUBLE_DOWN, MF_FORCE_QUEUE
	stc
	jmp	done

systemTermination:
	jmp	noDouble

HandleDoubleDown		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleSplit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the player with a pair. If so
		then ask the player if s/he wants to split. Give the
		player split if asked for.

CALLED BY:	INTERNAL
		BJackGamePrepareToHit

PASS:		*ds:si - Game object

RETURN:		
		stc - if player spliit
		clc - if  player didn't split

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
	srs	6/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleSplit		proc	near
	class	BJackGameClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	;
	;	Now check for split.  Allow split if player's two cards
	;	are the same rank (eg. 5 and 5,  or K and K).
	;
	clr	bp				;get card 0
	CallObject	Deck2, MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
	mov	dx, bp
	mov	cl, offset CA_RANK
	ANDNF	dx, mask CA_RANK
	shr	dx, cl
	push	dx				;store rank of card 0
	mov	bp, 1				;now get card 1
	CallObject	Deck2, MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
	mov	dx, bp
	mov	cl, offset CA_RANK
	ANDNF	dx, mask CA_RANK
	shr	dx, cl
	pop	cx
	cmp	cl, dl				;same rank?
	jne	noSplit

	;
	;	If it's not a pair of aces, check if House Rules allow split.
	;
	cmp	dl, CR_ACE
	je	checkCash
	CallObject AcesSplitRule, MSG_GEN_ITEM_GROUP_GET_SELECTION, MF_CALL
	cmp	ax, ACES_ONLY_SPLIT
	je	noSplit

checkCash:	
	;
	;	Check if player can afford to split (1X wager)
	;
	PointDi2 Game_offset
	tst	ds:[di].BGI_cash.high		;if cash.high<> 0, has cash
	jnz	ask
	mov	cx, ds:[di].BGI_wager
	cmp	ds:[di].BGI_cash.low, cx
	jge	ask

noSplit:
	clc

done:
	.leave
	ret

ask:
if WAV_SOUND
	mov	dx,BS_CAN_SPLIT
	call	GameStandardSound
endif
	push	si				;game chunk
	mov	bx,handle SplitSummons
	mov	si,offset SplitSummons
	call	UserDoDialog
	pop	si				;game chunk
	cmp	ax,IC_NULL
	je	systemTermination
	cmp	ax,IC_NO
	je	noSplit
	CallObject MyPlayingTable, MSG_SPLIT, MF_FORCE_QUEUE
	stc
	jmp	done

systemTermination:
	jmp	noSplit

HandleSplit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a card to the player`s deck, check for bust.

CALLED BY:	MSG_HIT
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameHit	method dynamic BJackGameClass, 
					MSG_HIT
	uses	ax, cx, dx, bp
	.enter

	;
	;	Ignore if still fading.
	;	
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset
	mov	si, ds:[di].GI_fadeArray
	call	ChunkArrayGetCount
	pop	si
	tst	cx
	jnz	done

	;
	;	Are we hitting for the "split" deck?
	;
	cmp	ds:[di].BGI_status, WAITING_TO_HIT2
	je	hit

	;
	;	Nope. Are we hitting for the first deck?
	;
	cmp	ds:[di].BGI_status, WAITING_TO_HIT
	jne	done
hit:
	PointDi2 Game_offset
	mov	al, ds:[di].BGI_special
	push	ax					;store "special" state
	;
	;	After hitting, can no longer use special triggers.
	;
	mov	ax, MSG_GET_NEXT_CARD
	call	ObjCallInstanceNoLock

	PointDi2 Game_offset
	;
	;	Are we hitting for first or second deck?
	;
	cmp	ds:[di].BGI_status, WAITING_TO_HIT
	jne	hit2
	;
	;	Hit for first deck.
	;
	push	si, cx
	CallObjectNS	Deck2, MSG_DECK_GET_DEALT, MF_FIXUP_DS
	CallObjectNS	Deck2, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
	CallObjectNS	Deck2, MSG_SUM_DECK, MF_CALL
	pop	si, cx
	jmp	finishHit
hit2:
	;
	;	Hit for second deck.
	;
	push	si, cx
	CallObjectNS	Deck3, MSG_DECK_GET_DEALT, MF_FIXUP_DS
	CallObjectNS	Deck3, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
	CallObjectNS	Deck3, MSG_SUM_DECK, MF_CALL
	pop	si, cx
finishHit:
	pop	cx

	;
	;	If "double-down", allow only 1 card.
	;
	and	cl, DOUBLE_DOWN
	jnz	stay
	cmp	al, GAME_MAXIMUM			;busted
	jg	busted					;
done:
	.leave
	ret

stay:
	mov	ax, MSG_STAY				;yes, so end game.
	call	ObjCallInstanceNoLock
	jmp	done	

busted:
	;   Player busted. Make sound right away.
	;

	push	si
	PointDi2 Game_offset
	mov	si,offset BustedText
	cmp	ds:[di].BGI_status, WAITING_TO_HIT
	jne	deck3	
	call	SetDeck2InstructionsString
	pop	si
bustedSound:
	mov	dx, BS_PLAYER_BUST
	call	GameStandardSound
	jmp	stay

deck3:	
	call	SetDeck3InstructionsString
	pop	si
	jmp	bustedSound

BJackGameHit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackGameTidyUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TIDY_UP handler for BJackGameClass
		Sets the game status to WAITING_FOR_NEW_GAME to indicate
		that the current game is over with.

CALLED BY:	

PASS:		ds:di = game instance
		
CHANGES:	ds:[di].BGI_status <- WAITING_FOR_NEW_GAME

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameTidyUp	method	BJackGameClass, MSG_TIDY_UP
	uses	cx, dx, bp
	.enter

	mov	ds:[di].BGI_status, BUSY
	;
	;	Finish fading first.
	;	
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset
	mov	si, ds:[di].GI_fadeArray
	call	ChunkArrayGetCount
	pop	si
	jcxz	continue

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_TIDY_UP
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	done
continue:
	tst	ds:[di].BGI_cash.high
	jnz	showDealText
	tst	ds:[di].BGI_cash.low
	jnz	showDealText
	tst	ds:[di].BGI_wager
	jz	bust	

	;
	;	The guy has cash, so let's go
	;
showDealText:
	call	BJackGameDetermineIfShuffleTime
	jnc	otherText

	;    The deck isn't actually being shuffled now, but it
	;    will be before the next hand is dealt. So tell
	;    the guy now so that he can count cards correctly.
	;

	push	si
	mov	si,offset BeingShuffledText
	call	SetInstructionString
if WAV_SOUND
	mov	dx,BS_SHUFFLE
	call	GameStandardSound
	mov	ax,90
	call	TimerSleep
	mov	dx,BS_SHUFFLE
	call	GameStandardSound
endif
	mov	si,offset HasBeenShuffledText
	call	SetInstructionString
	pop	si
otherText:
	push	si
	mov	si, offset DealText
	call	SetHandInstructionsString
	pop	si

	PointDi2 Game_offset
	mov	ds:[di].BGI_status, WAITING_FOR_NEW_GAME
done:
	.leave
	ret

bust:
	clr	cx,dx
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_BUST
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	si,offset BlankText
	call	SetHandInstructionsString
	mov	si, offset BlankText
	call	SetDeck2InstructionsString
	jmp	done

BJackGameTidyUp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackGameStay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_STAY handler for BJackGameClass


CALLED BY:	

PASS:		ds:[di] = game instance

CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameStay	method	BJackGameClass, MSG_STAY
	cmp	ds:[di].BGI_status, WAITING_TO_HIT2
	je	stay
	cmp	ds:[di].BGI_status, WAITING_TO_HIT
	jne	done
stay:
	;
	;	Finish fading first.
	;	
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset
	mov	si, ds:[di].GI_fadeArray
	call	ChunkArrayGetCount
	pop	si
	jcxz	continue

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_STAY
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	done
continue:
	PointDi2 Game_offset
	;
	;	If stay for second deck, SETTLE_BETS.
	;	If stay for first deck and no split, SETTLE_BETS.
	;	If stay for first deck and split, WAITING_TO_HIT2
	;
	cmp	ds:[di].BGI_status, WAITING_TO_HIT2
	je	settleBets
	mov	bl, ds:[di].BGI_special
	and	bl, SPLIT
	jz	settleBets
	
	mov	ds:[di].BGI_status, WAITING_TO_HIT2
	mov	si, offset Play2Text
	call	SetInstructionString
	mov	si, offset PlayOtherHandText
	call	SetDeck2InstructionsString
	mov	si, offset StayText
	call	SetDeck3InstructionsString
	jmp	done

settleBets:
	;    Get the hit/stay instructions off the screen
	;    so the user doesn't thinkg that he can do this
	;    stuff while the dealer is playing.
	;

	push	si
	mov	si,offset BlankText
	call	SetDeck3InstructionsString
	call	SetDeck2InstructionsString
	call	SetHandInstructionsString
	pop	si

	;
	;	Pay the user if she has won anything
	;
	mov	ax, MSG_SETTLE_BETS
	call	ObjCallInstanceNoLock

	;
	;	fix up anything that needs to be fixed up (in particular,
	;	indicate that we're no longer BUSY
	;
	mov	ax, MSG_TIDY_UP
	call	ObjCallInstanceNoLock

done:
	ret
BJackGameStay	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				BJackGameSettleBets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SETTLE_BETS handler for BJackGameClass
		Checks to see what BJack hand the user has been dealt,
		then pays off the winnings if there are any.

CALLED BY:	

PASS:		*ds:si = game object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
	srs	6/93		total rewrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameSettleBets	method	BJackGameClass, MSG_SETTLE_BETS
dealerSum	local	word
deck2Sum	local	word
deck3Sum	local	word
split		local	word
wagerPerHand	local	word
	.enter

EC <	mov	al,ds:[di].BGI_special 
EC <	test	al,SPLIT
EC <	jz	ecDone
EC <	test	al,DOUBLE_DOWN
EC <	ERROR_NZ BJACK_BOTH_DOUBLE_DOWN_AND_SPLIT
EC <ecDone:

	;    Init stack variables
	;

	clr	split
	mov	bx,ds:[di].BGI_wager
	mov	al, ds:[di].BGI_special
	and	al, SPLIT
	jz	10$
	shr	bx,1				;player split, wagerPerHand/2
	mov	split,TRUE
10$:	
	mov	wagerPerHand,bx

	;   Flip dealers face down card
	;

	CallObject	Deck1, MSG_FLIP_SECOND_CARD, MF_CALL

	;    Sum players hands
	;

	CallObject	Deck2, MSG_SUM_DECK, MF_CALL
	mov	deck2Sum, ax
	tst	split
	jz	checkDeck2ForBust
	CallObject	Deck3, MSG_SUM_DECK, MF_CALL
	mov	deck3Sum, ax

	;    Play the dealer's hand if at least one of the players
	;    hands didn't bust
	;

	cmp	al,GAME_MAXIMUM
	jle	playDealer
checkDeck2ForBust:
	mov	ax,deck2Sum
	cmp	al,GAME_MAXIMUM
	jg	processHands
playDealer:
	call	BJackGamePlayDealerUnlessPlayerHasBlackJack
	mov	dealerSum,ax

processHands:
	call	BJackGameSettleDeck2Bets
	call	BJackGameSettleDeck3Bets

	;    If the player split or played a normal hand then 
	;    wagerPerHand will be the wager at the begining
	;    of this hand. If the player doubled down
	;    then wagerPerHand will be twice the wager at
	;    the beginning of this hand. Set the wager 
	;    (which must currently be zero) to is value at
	;    the beginning of this and adjusts the cash
	;    appropriately for the next hand.
	;

	mov	cx,wagerPerHand
	PointDi2 Game_offset
	mov	al,ds:[di].BGI_special
	and	al, DOUBLE_DOWN
	jz	adjustWager
	shr	cx,1
adjustWager:
	mov	ax,MSG_ADJUST_WAGER_AND_CASH
	call	ObjCallInstanceNoLock


	;
	;	Enable some UI for the next game.
	;
	mov	dl, VUM_NOW
	CallObjectNS MoneyTriggers, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	CallObjectNS CashOutTrigger, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	CallObjectNS BorrowTrigger, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	CallObjectNS RulesInteraction, MSG_GEN_SET_ENABLED, MF_FIXUP_DS



	.leave
	ret

BJackGameSettleBets	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGamePlayDealerUnlessPlayerHasBlackJack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play the dealers hand unless the player has a black
		jack.


CALLED BY:	INTERNAL
		BJackGameSettleBets

PASS:		inherited stack frame

RETURN:		
		al - hand value
		ah - number of cards

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
	srs	6/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGamePlayDealerUnlessPlayerHasBlackJack		proc	near
	uses	bx,cx,dx,di,si
	.enter inherit BJackGameSettleBets

	;    If the player split then he can't have black jack
	;

	tst	split
	jnz	playDealer

	;    If the player has a black jack sum then dealers hand
	;    anyway, incase the dealer has a black jack
	;

	mov	ax,deck2Sum
	cmp	ax,BLACK_JACK_VALUE
	je	sumDealerHand

playDealer:
	CallObjectNS	Deck1, MSG_PLAY, MF_CALL
done:
	.leave
	ret

sumDealerHand:
	CallObjectNS	Deck1, MSG_SUM_DECK, MF_CALL
	jmp	done

BJackGamePlayDealerUnlessPlayerHasBlackJack		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameSettleDeck2Bets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the win/lost status of the deck2 hand. 
		Display	won or lost text above the deck. Put any winnings
		to cash. If hand won then move bet back to cash
		otherwise nuke bet.

CALLED BY:	INTERNAL	
		BJackGameSettleBets

PASS:		
		*ds:si - game object
		local frame from BJackGameSettleBets
			deck2Sum - set
			dealerSum - set, unless deck2Sum = GAME_MAXIMUM

RETURN:		
		BGI_cash - may have changed
		BGI_wager - changed

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
	srs	6/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameSettleDeck2Bets		proc	near
	uses	ax,bx,cx,dx,di,si
	class	BJackGameClass
	.enter inherit BJackGameSettleBets	
	
	;    Nuke the wager. If the hand was lost it is truly gone.
	;    If the hand is won it will be put back in the cash.
	;

	PointDi2 Game_offset
	mov	dx,wagerPerHand
	sub	ds:[di].BGI_wager,dx

	;    Check for player busting
	;

	mov	ax,deck2Sum
	cmp	al,GAME_MAXIMUM
	jg	lost				;no sound

	mov	bx,dealerSum

	;     Check for player with a black jack. Can't have black jack
	;     if player split.
	;

	tst	split
	jnz	checkForDealerBust
	cmp	ax,BLACK_JACK_VALUE
	je	checkForBlackJackDraw

checkForDealerBust:
	;    Check for dealer busting
	;

	cmp	bl,GAME_MAXIMUM
	jg	dealerBust

	cmp	bx,BLACK_JACK_VALUE
	je	dealerBlackJack

	;    Compare hand values
	;

	cmp	al,bl
	je	draw
	jl	lostHandSound

	mov	dx,BS_PLAYER_WON_HAND

wonSound:
	call	GameStandardSound

	;    Display text saying he won amount of bet
	;

	mov	dx,wagerPerHand
	clr	cx
	call	DisplayYouWonInDeck2Instructions

	;    Add the winnings and the original bet to the cash pot
	;

	PointDi2 Game_offset
	add	dx,wagerPerHand
	add	ds:[di].BGI_cash.low,dx
	adc	ds:[di].BGI_cash.high,0

	mov	si,offset FirstHandWinsText
	call	SetInstructionString

done:
	.leave
	ret

dealerBust:
  ;	mov	dx,BS_DEALER_BUST
	mov	dx,BS_PLAYER_WON_HAND
	jmp	wonSound

dealerBlackJack:
  ;	mov	dx,BS_DEALER_BLACK_JACK
	mov	dx,BS_PLAYER_LOST_HAND
	jmp	lostSound

lostHandSound:
	mov	dx,BS_PLAYER_LOST_HAND

lostSound:
	call	GameStandardSound

lost:
	;    Display text saying he lost amount of wager
	;

	clr	cx
	mov	dx,wagerPerHand
	call	DisplayYouLostInDeck2Instructions

	mov	si,offset DealerWins1Text
	call	SetInstructionString
	jmp	done

checkForBlackJackDraw:
	cmp	ax, bx				;deck2Sum, dealerSum
	jne	playerBlackJack			;jmp if player had black jack

draw:
	mov	dx,BS_PUSH_HAND
	call	GameStandardSound

	;    Add the original bet to the cash pot
	;

	PointDi2 Game_offset
	mov	dx,wagerPerHand
	add	ds:[di].BGI_cash.low,dx
	adc	ds:[di].BGI_cash.high,0

	mov	si,offset YouPushText
	call	SetDeck2InstructionsString
	mov	si,offset FirstHandPushText
	call	SetInstructionString
	jmp	done

playerBlackJack:
  ;	mov	dx,BS_PLAYER_BLACK_JACK
	mov	dx,BS_PLAYER_WON_HAND
	call	GameStandardSound

	;    Display text saying he won wager + one half of wager
	;

	mov	dx,wagerPerHand
	shr	dx,1
	add	dx,wagerPerHand
	clr	cx
	call	DisplayYouWonInDeck2Instructions 

	;    Add the winnings and the original bet to the cash pot.
	;

	PointDi2 Game_offset
	add	dx,wagerPerHand
	add	ds:[di].BGI_cash.low,dx
	adc	ds:[di].BGI_cash.high,0

	mov	si,offset BlackJackText
	call	SetInstructionString
	jmp	done

BJackGameSettleDeck2Bets		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameSettleDeck3Bets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the win/lost status of the deck3 hand. 
		Display	won or lost text above the deck. Put any winnings
		to cash. If hand won then move bet back to cash
		otherwise nuke bet.


CALLED BY:	INTERNAL	
		BJackGameSettleBets

PASS:		
		*ds:si - game object
		local frame from BJackGameSettleBets
			deck3Sum - set
			dealerSum - set, unless 
						deck3Sum = GAME_MAXIMUM
						or
						split = true

RETURN:		
		BGI_wager - changed
		BGI_cash - may have changed

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
	srs	6/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameSettleDeck3Bets		proc	near
	uses	ax,bx,cx,dx,di,si
	class	BJackGameClass
	.enter inherit BJackGameSettleBets	
	
	;    If no split, nothing to evaluate
	;

	tst	split
	jz	done

	;    Nuke the wager. If the hand was lost it is truly gone.
	;    If the hand is won it will be put back in the cash.
	;

	PointDi2 Game_offset
	mov	dx,wagerPerHand
	sub	ds:[di].BGI_wager,dx

	;    Check for player busting
	;

	mov	ax,deck3Sum
	cmp	al,GAME_MAXIMUM
	jg	lost

	;    Check for dealer busting
	;

	cmp	dealerSum.low, GAME_MAXIMUM
	jg	dealerBust

	;    Compare hand values
	;

	cmp	al,dealerSum.low
	je	draw
	jl	lostHand

	mov	dx,BS_PLAYER_WON_HAND

wonSound:
	call	GameStandardSound
	mov	dx,wagerPerHand
	clr	cx
	call	DisplayYouWonInDeck3Instructions

	;    Add the winnings and the original bet to the cash pot
	;

	PointDi2 Game_offset
	add	dx,wagerPerHand
	add	ds:[di].BGI_cash.low,dx
	adc	ds:[di].BGI_cash.high,0

	mov	si,offset SecondHandWinsText
	call	AppendInstructionString

done:
	.leave
	ret

dealerBust:
   ;	mov	dx,BS_DEALER_BUST
	mov	dx,BS_PLAYER_WON_HAND
	jmp	wonSound

lostHand:
	mov	dx,BS_PLAYER_LOST_HAND
	call	GameStandardSound
lost:
	clr	cx
	mov	dx,wagerPerHand
	call	DisplayYouLostInDeck3Instructions

	mov	si,offset DealerWins2Text
	call	AppendInstructionString
	jmp	done

draw:
	mov	dx,BS_PUSH_HAND
	call	GameStandardSound

	;    Add the original bet to the cash pot
	;

	PointDi2 Game_offset
	mov	dx,wagerPerHand
	add	ds:[di].BGI_cash.low,dx
	adc	ds:[di].BGI_cash.high,0

	mov	si,offset YouPushText
	call	SetDeck3InstructionsString
	mov	si,offset SecondHandPushText
	call	AppendInstructionString
	jmp	done

BJackGameSettleDeck3Bets		endp


if	FADING

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackGameSetFadeStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SET_FADE_STATUS handler for BJackGameClass
		Turns fading either on or off for this game.

CALLED BY:	

PASS:		nothing
		
CHANGES:	turns time on or off

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
anyway to get TimeGameEntry to send different methods depending on its own
state?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameSetFadeStatus	method	BJackGameClass, MSG_SET_FADE_STATUS

	CallObject	FadeList, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS,MF_CALL
	mov	dl, SDM_100			;SDM_100 = no fading
	test	al, 1
	jz	setStatus
	mov	dl, SDM_0			;SDM_0 = full fading
setStatus:
	mov	cl, SDM_25 - SDM_0

	;
	;	At this point, 	dl = initial fade mask
	;			cl = incremental fade mask
	;
	mov	ax, MSG_GAME_SET_FADE_PARAMETERS
	call	ObjCallInstanceNoLock
	ret
BJackGameSetFadeStatus	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BJackGameCheckMaximumBet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CHECK_MAXIMUM_BET handler for BJackGameClass

CALLED BY:	

PASS:		dx = amount to check
		
CHANGES:	

RETURN:		dx = the lesser of the passed dx and MAXIMUM_BET

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameCheckMaximumBet	method	BJackGameClass, MSG_CHECK_MAXIMUM_BET
	cmp	dx, MAXIMUM_BET
	jbe	done
	mov	dx, MAXIMUM_BET
done:
	ret
BJackGameCheckMaximumBet	endm


BJackGameCheckFunds	method	BJackGameClass, MSG_CHECK_FUNDS
	tst	ds:[di].BGI_cash.high
	jnz	done

	mov	ax, ds:[di].BGI_cash.low
	sub	ax, ds:[di].BGI_wager
	cmp	dx, ax
	ja	useMax
done:
	ret
useMax:
	mov_trash	dx, ax
	jmp	done
BJackGameCheckFunds	endm

BJackGameSetFontSize	method	BJackGameClass, MSG_GAME_SET_FONT_SIZE

	mov	dx, VisTextSetPointSizeParams
	sub	sp, dx
	mov	bp, sp				; structure => SS:BP
	clrdw	ss:[bp].VTSPSP_range.VTR_start
	movdw	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSPSP_pointSize.WWF_frac, 0
;	mov	ss:[bp].VTSPSP_pointSize.WWF_int, cx
; Passed font size too big, use FONT_SIZE instead of cx.
	mov	ss:[bp].VTSPSP_pointSize.WWF_int, FONT_SIZE

	CallObjectNS	HandInstructions, MSG_VIS_TEXT_SET_POINT_SIZE, MF_STACK
	CallObjectNS	Deck1Instructions, MSG_VIS_TEXT_SET_POINT_SIZE, MF_STACK
	CallObjectNS	Deck2Instructions, MSG_VIS_TEXT_SET_POINT_SIZE, MF_STACK
	CallObjectNS	Deck3Instructions, MSG_VIS_TEXT_SET_POINT_SIZE, MF_STACK

	add	sp, size VisTextSetPointSizeParams

	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	CallObject MyPlayingTable, MSG_VIS_VUP_UPDATE_WIN_GROUP, MF_FIXUP_DS
	CallObject HandInstructions, MSG_VIS_UPDATE_GEOMETRY, MF_FIXUP_DS
	CallObject Deck1Instructions, MSG_VIS_UPDATE_GEOMETRY, MF_FIXUP_DS
	CallObject Deck2Instructions, MSG_VIS_UPDATE_GEOMETRY, MF_FIXUP_DS
	CallObject Deck3Instructions, MSG_VIS_UPDATE_GEOMETRY, MF_FIXUP_DS

	ret
BJackGameSetFontSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameCashOutSetWaitingForNewGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BJackGameClass

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
	srs	8/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameCashOutSetWaitingForNewGame	method dynamic BJackGameClass, 
					MSG_CASH_OUT_SET_WAITING_FOR_NEW_GAME
	.enter

	mov	ax,MSG_CASH_OUT
	call	ObjCallInstanceNoLock

	PointDi2 Game_offset
	mov	ds:[di].BGI_status, WAITING_FOR_NEW_GAME

	.leave
	ret
BJackGameCashOutSetWaitingForNewGame		endm




BJackGameCashOut	method	BJackGameClass, MSG_CASH_OUT
cashString	local	CURRENCY_SYMBOL_LENGTH+11 dup (char)

	.enter
	push	bp

	push	si
	mov	bx, handle BJackBustedBox
	mov	si, offset BJackBustedBox
	mov	di,mask MF_FIXUP_DS
	mov	cx,IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjMessage
	pop	si


	;    Clear up the screen
	;

	call	BJackGameClearCardsFromScreen
	call	BJackGameShuffle

	PointDi2	Game_offset
	mov	ax, 1
	xchg	ax, ds:[di].BGI_markers
	mov	cx, 100
	mul	cx	
	;
	;	ax:dx <- score
	;
	mov	cx, ds:[di].BGI_cash.low
	mov	bx, ds:[di].BGI_cash.high
	add	cx, ds:[di].BGI_wager
	adc	bx,0

	sub	cx, ax
	sbb	bx, dx
	mov	dx, cx


	push	dx
	clr	ds:[di].BGI_wager
	clr	dx
	mov	cx, INITIAL_CASH
	call	StartFresh

	pop	dx

	mov_trash	ax, bx
	push	ax, dx
	tst	ax

if WAV_SOUND
	mov	cx, BS_WON_MONEY_ON_CASH_OUT	;assume
endif
	mov	di, offset LostMoneyText
	jl	lostMoney
	mov	di, offset WonMoneyText
	jg	moneyChangedHands
	tst	dx
	jnz	moneyChangedHands
	mov	di, offset EvenMoneyText
	clr	cx				;no arg string
	jmp	showText

lostMoney:
if WAV_SOUND
	mov	cx, BS_LOST_MONEY_ON_CASH_OUT
endif
	Neg32	dx, ax
moneyChangedHands:
	push	dx
	mov	dx,cx
if WAV_SOUND
	call	GameStandardSound
endif
	pop	dx

	push	es 
	;
	;	Set up $ string
	;
	segmov	es, ss
	lea	bp, cashString
	call	NumberToCashString

	mov	cx, es
	mov	dx, bp
	pop	es

showText:
	push	ax, bx, bp, es
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, CustomDialogBoxFlags \
		<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION,0>
	mov	bx, handle StuffResource
	call	MemLock
	mov	es, ax
	mov	ss:[bp].SDP_customString.segment, ax
	mov	ax, es:[di]
	mov	ss:[bp].SDP_customString.offset, ax

	clr	ss:[bp].SDP_helpContext.segment
	tst	cx
	jz	skipArg1
	mov	ss:[bp].SDP_stringArg1.segment, cx
	mov	ss:[bp].SDP_stringArg1.offset, dx
skipArg1:
	call	UserStandardDialog
	call	MemUnlock
	pop	ax, bx, bp, es

	pop	dx, cx

	tst	dx
	jg	winner
	jl	loser
	tst	cx
	jg	winner
	jl	loser

	;    In the case of a tie, clear the name for the next game
	;	

	clr	cx
	call	BJackSetHaveLoanName

done:	

	pop	bp
	.leave
	ret
winner:
	call	AddHighScore
	jmp	done ; clearName

loser:
	Neg32	cx, dx

	call	AddLowScore
	jmp	done ; clearName
BJackGameCashOut	endm

StartFresh	proc	near
	class	BJackGameClass
	uses	ax, bx, cx, dx, di, si
	.enter

	mov	ax, MSG_GAME_UPDATE_SCORE
	call	ObjCallInstanceNoLock

	;    If they player doesn't have a wager, give him/her the
	;    default one.
	;

	PointDi2 Game_offset
	tst	ds:[di].BGI_wager
	jnz	welcomeText
	mov	cx, INITIAL_WAGER
	mov	ax, MSG_ADJUST_WAGER_AND_CASH
	call	ObjCallInstanceNoLock

welcomeText:
	mov	si, offset WelcomeText
	call	SetInstructionString

	mov	si, offset DealText
	call	SetHandInstructionsString
	mov	si, offset BlankText
	call	SetDeck2InstructionsString
	mov	si, offset BlankText
	call	SetDeck3InstructionsString

	.leave
	ret
StartFresh	endp


;	es:bp - pointer to string to fill in
;	dx:ax - cash amount
;
NumberToCashString	proc	near
	uses	ax,bx,cx,dx,di
	.enter
	xchg	ax,dx
	mov	di, bp				
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	.leave
	ret
NumberToCashString	endp	
	
BJackGameBust	method	BJackGameClass, MSG_BUST
	mov	ax, MSG_UPDATE_WAGER
	call	ObjCallInstanceNoLock

	;
	;	Wait until all the cards are done fading
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset
	mov	si, ds:[di].GI_fadeArray
	call	ChunkArrayGetCount
	pop	si
	jcxz	doItNow

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_BUST
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	done

doItNow:
	mov	bx,handle BJackBustedBox
	mov	si,offset BJackBustedBox
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

done:
	ret

BJackGameBust	endm

BJackGameShutDown	method	BJackGameClass, MSG_GAME_SHUTDOWN

if STANDARD_SOUND
	; 
	; Turn sound off and free it.
	;
	call	SoundShutOffSounds
endif

	mov	di, offset BJackGameClass
	mov	ax, MSG_GAME_SHUTDOWN
	call	ObjCallSuperNoLock
	ret
BJackGameShutDown	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameBorrowOneHunderdDollarsSetWaitingForNewGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BJackGameClass

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
	srs	8/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameBorrowOneHunderdDollarsSetWaitingForNewGame	\
						method dynamic BJackGameClass, 
			MSG_BORROW_ONE_HUNDRED_DOLLARS_SET_WAITING_FOR_NEW_GAME
	.enter

	mov	ax,MSG_BORROW_ONE_HUNDRED_DOLLARS
	call	ObjCallInstanceNoLock

	PointDi2 Game_offset
	mov	ds:[di].BGI_status, WAITING_FOR_NEW_GAME

	.leave
	ret
BJackGameBorrowOneHunderdDollarsSetWaitingForNewGame		endm



BJackGameBorrowOneHundredDollars	method	BJackGameClass, MSG_BORROW_ONE_HUNDRED_DOLLARS
	uses	cx, dx, bp
	.enter

	push	si					;game chunk

	;    Make sure the busted box is no longer on the screen
	;

	mov	bx, handle BJackBustedBox
	mov	si, offset BJackBustedBox
	mov	di,mask MF_FIXUP_DS
	mov	cx,IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjMessage

	;    If we have already asked for a name then don't bother
	;    the guy


	call	BJackCheckHaveLoanName
	tst	cx
	jnz	afterLoanBox

	;    Be nice and select all the text, if there is any, so
	;    that it is easy for the player to change the name.
	;

	mov	bx, handle GetLoanText
	mov	si, offset GetLoanText
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_VIS_TEXT_SELECT_ALL
	call	ObjMessage

	mov	bx, handle GetLoanBox
	mov	si, offset GetLoanBox
	call	UserDoDialog

afterLoanBox:
	pop	si

if WAV_SOUND
	mov	dx,BS_BORROW_100
	call	GameStandardSound
endif

	mov	cx,TRUE
	call	BJackSetHaveLoanName

	clr	cx
	mov	dx, INITIAL_CASH
	call	StartFresh

	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset
	inc	ds:[di].BGI_markers		;increase debt by 1 unit ($100)

	.leave
	ret
BJackGameBorrowOneHundredDollars	endm

if	0
BJackGameBorrowOneHundredDollars	method	BJackGameClass, MSG_BORROW_ONE_HUNDRED_DOLLARS
	uses	cx, dx, bp
	.enter
	push	si

	mov	bx, handle GetLoanBox
	mov	si, offset GetLoanBox
	call	UserDoDialog

	pop	si

	clr	cx
	mov	dx, INITIAL_CASH
	call	StartFresh

	mov	di, ds:[si]
	add	di, ds:[di].BJackGame_offset
	inc	ds:[di].BGI_markers		;increase debt by 1 unit ($100)

	.leave
	ret
BJackGameBorrowOneHundredDollars	endm

endif

BJackGameFreeMillion	method	BJackGameClass, MSG_FREE_MILLION
	add	ds:[di].BGI_cash.low, 16959
	adc	ds:[di].BGI_cash.high, 15

	clr	cx
	mov	dx, 1
	call	StartFresh
	ret
BJackGameFreeMillion	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayCash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		cx:dx = cash

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayCash	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx

	segmov	es, ss, di
	sub	sp, 100
	mov	di, sp
	mov	bx, handle CashText
	call	MemLock
	mov	ds, ax
	mov	si, offset CashText
	mov	si, ds:[si]

labelLoop:
	lodsb
	tst	al
	jz	gotLabel
	stosb
	jmp	labelLoop
gotLabel:
	call	MemUnlock

	mov_trash	ax, cx			;ax <- cash high
	mov	bp, di				;es:bp <- string
	call	NumberToCashString

	mov	bx, handle CashTextDisplay
	mov	si, offset CashTextDisplay
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	pop	bx
	call	MemDerefDS

	.leave
	ret
DisplayCash	endp

SetInstructionString	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx


	sub	sp, 150
	mov	di, sp
	mov	bp, di
	segmov 	es, ss
	mov	bx, handle StuffResource
	call	MemLock
	jc	done
	mov	ds, ax
	mov	si, ds:[si]
readLoop:
	lodsb
	stosb
	tst	al
	jnz	readLoop

	call	MemUnlock

	mov	dx, es
	clr	cx
	mov	bx, handle InstructionsLine
	mov	si, offset InstructionsLine
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage

done:
	add	sp, 150

	pop	bx
	call	MemDerefDS


	.leave
	ret
SetInstructionString	endp


SetHandInstructionsString	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx


	sub	sp, 50
	mov	di, sp
	mov	bp, di
	segmov 	es, ss
	mov	bx, handle StuffResource
	call	MemLock
	jc	done
	mov	ds, ax
	mov	si, ds:[si]
readLoop:
	lodsb
	stosb
	tst	al
	jnz	readLoop

	call	MemUnlock

	mov	dx, es
	clr	cx
	mov	bx, handle HandInstructions
	mov	si, offset HandInstructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage

done:
	add	sp, 50

	pop	bx
	call	MemDerefDS

	.leave
	ret
SetHandInstructionsString	endp

SetDeck1InstructionsString	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx


	sub	sp, 50
	mov	di, sp
	mov	bp, di
	segmov 	es, ss
	mov	bx, handle StuffResource
	call	MemLock
	jc	done
	mov	ds, ax
	mov	si, ds:[si]
readLoop:
	lodsb
	stosb
	tst	al
	jnz	readLoop

	call	MemUnlock

	mov	dx, es
	clr	cx
	mov	bx, handle Deck1Instructions
	mov	si, offset Deck1Instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage

done:
	add	sp, 50

	pop	bx
	call	MemDerefDS

	.leave
	ret
SetDeck1InstructionsString	endp

SetDeck2InstructionsString	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx


	sub	sp, 50
	mov	di, sp
	mov	bp, di
	segmov 	es, ss
	mov	bx, handle StuffResource
	call	MemLock
	jc	done
	mov	ds, ax
	mov	si, ds:[si]
readLoop:
	lodsb
	stosb
	tst	al
	jnz	readLoop

	call	MemUnlock

	mov	dx, es
	clr	cx
	mov	bx, handle Deck2Instructions
	mov	si, offset Deck2Instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage

done:
	add	sp, 50

	pop	bx
	call	MemDerefDS

	.leave
	ret
SetDeck2InstructionsString	endp

SetDeck3InstructionsString	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx

	sub	sp, 50
	mov	di, sp
	mov	bp, di
	segmov 	es, ss
	mov	bx, handle StuffResource
	call	MemLock
	jc	done
	mov	ds, ax
	mov	si, ds:[si]
readLoop:
	lodsb
	stosb
	tst	al
	jnz	readLoop

	call	MemUnlock

	mov	dx, es
	clr	cx
	mov	bx, handle Deck3Instructions
	mov	si, offset Deck3Instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage

done:
	add	sp, 50

	pop	bx
	call	MemDerefDS


	.leave
	ret
SetDeck3InstructionsString	endp


AppendInstructionString	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx


	sub	sp, 50
	mov	di, sp
	mov	bp, di
	segmov 	es, ss
	mov	bx, handle StuffResource
	call	MemLock
	jc	done
	mov	ds, ax
	mov	si, ds:[si]
readLoop:
	lodsb
	stosb
	tst	al
	jnz	readLoop

	call	MemUnlock

	mov	dx, es
	clr	cx
	mov	bx, handle InstructionsLine
	mov	si, offset InstructionsLine
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	mov	di, mask MF_CALL
	call	ObjMessage

done:
	add	sp, 50

	pop	bx
	call	MemDerefDS


	.leave
	ret
AppendInstructionString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayBet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		cx:dx = cash

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayBet	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx

	segmov	es, ss, di
	sub	sp, 100
	mov	di, sp
	mov	bx, handle BetText
	call	MemLock
	mov	ds, ax
	mov	si, offset BetText
	mov	si, ds:[si]

labelLoop:
	lodsb
	tst	al
	jz	gotLabel
	stosb
	jmp	labelLoop
gotLabel:
	call	MemUnlock

	mov_trash	ax, cx			;ax <- cash high
	mov	bp, di				;es:bp <- string
	call	NumberToCashString

	mov	bx, handle BetTextDisplay
	mov	si, offset BetTextDisplay
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	pop	bx
	call	MemDerefDS

	.leave
	ret
DisplayBet	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayYouWonInDeck1Instructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		cx:dx = cash

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayYouWonInDeck1Instructions	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx


	segmov	es, ss, di
	sub	sp, 100
	mov	di, sp
	mov	bx, handle YouWonText
	call	MemLock
	mov	ds, ax
	mov	si, offset YouWonText
	mov	si, ds:[si]

labelLoop:
	lodsb
	tst	al
	jz	gotLabel
	stosb
	jmp	labelLoop
gotLabel:
	call	MemUnlock

	mov_trash	ax, cx			;ax <- cash high
	mov	bp, di				;es:bp <- string
	call	NumberToCashString

	mov	bx, handle Deck1Instructions
	mov	si, offset Deck1Instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	pop	bx
	call	MemDerefDS

	.leave
	ret
DisplayYouWonInDeck1Instructions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayYouLostInDeck1Instructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		cx:dx = cash

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayYouLostInDeck1Instructions	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx

	segmov	es, ss, di
	sub	sp, 100
	mov	di, sp
	mov	bx, handle YouLostText
	call	MemLock
	mov	ds, ax
	mov	si, offset YouLostText
	mov	si, ds:[si]

labelLoop:
	lodsb
	tst	al
	jz	gotLabel
	stosb
	jmp	labelLoop
gotLabel:
	call	MemUnlock

	mov_trash	ax, cx			;ax <- cash high
	mov	bp, di				;es:bp <- string
	call	NumberToCashString

	mov	bx, handle Deck1Instructions
	mov	si, offset Deck1Instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	pop	bx
	call	MemDerefDS

	.leave
	ret
DisplayYouLostInDeck1Instructions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayYouWonInDeck2Instructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		cx:dx = cash

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayYouWonInDeck2Instructions	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx


	segmov	es, ss, di
	sub	sp, 100
	mov	di, sp
	mov	bx, handle YouWonText
	call	MemLock
	mov	ds, ax
	mov	si, offset YouWonText
	mov	si, ds:[si]

labelLoop:
	lodsb
	tst	al
	jz	gotLabel
	stosb
	jmp	labelLoop
gotLabel:
	call	MemUnlock

	mov_trash	ax, cx			;ax <- cash high
	mov	bp, di				;es:bp <- string
	call	NumberToCashString

	mov	bx, handle Deck2Instructions
	mov	si, offset Deck2Instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	pop	bx
	call	MemDerefDS

	.leave
	ret
DisplayYouWonInDeck2Instructions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayYouLostInDeck2Instructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		cx:dx = cash

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayYouLostInDeck2Instructions	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx

	segmov	es, ss, di
	sub	sp, 100
	mov	di, sp
	mov	bx, handle YouLostText
	call	MemLock
	mov	ds, ax
	mov	si, offset YouLostText
	mov	si, ds:[si]

labelLoop:
	lodsb
	tst	al
	jz	gotLabel
	stosb
	jmp	labelLoop
gotLabel:
	call	MemUnlock

	mov_trash	ax, cx			;ax <- cash high
	mov	bp, di				;es:bp <- string
	call	NumberToCashString

	mov	bx, handle Deck2Instructions
	mov	si, offset Deck2Instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	pop	bx
	call	MemDerefDS

	.leave
	ret
DisplayYouLostInDeck2Instructions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayYouWonInDeck3Instructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		cx:dx = cash

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayYouWonInDeck3Instructions	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx


	segmov	es, ss, di
	sub	sp, 100
	mov	di, sp
	mov	bx, handle YouWonText
	call	MemLock
	mov	ds, ax
	mov	si, offset YouWonText
	mov	si, ds:[si]

labelLoop:
	lodsb
	tst	al
	jz	gotLabel
	stosb
	jmp	labelLoop
gotLabel:
	call	MemUnlock

	mov_trash	ax, cx			;ax <- cash high
	mov	bp, di				;es:bp <- string
	call	NumberToCashString

	mov	bx, handle Deck3Instructions
	mov	si, offset Deck3Instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	pop	bx
	call	MemDerefDS

	.leave
	ret
DisplayYouWonInDeck3Instructions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayYouLostInDeck3Instructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		cx:dx = cash

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayYouLostInDeck3Instructions	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es
	.enter

	mov	bx,ds:[LMBH_handle]
	push	bx

	segmov	es, ss, di
	sub	sp, 100
	mov	di, sp
	mov	bx, handle YouLostText
	call	MemLock
	mov	ds, ax
	mov	si, offset YouLostText
	mov	si, ds:[si]

labelLoop:
	lodsb
	tst	al
	jz	gotLabel
	stosb
	jmp	labelLoop
gotLabel:
	call	MemUnlock

	mov_trash	ax, cx			;ax <- cash high
	mov	bp, di				;es:bp <- string
	call	NumberToCashString

	mov	bx, handle Deck3Instructions
	mov	si, offset Deck3Instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	pop	bx
	call	MemDerefDS

	.leave
	ret
DisplayYouLostInDeck3Instructions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddHighScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddHighScore	proc	near
	uses	ax,bx,cx,dx,si,di,ds,bp

	.enter

	mov	ax, MSG_HIGH_SCORE_ADD_SCORE
	mov	bx, handle HallOfFame
	mov	si, offset HallOfFame
	clr	bp			;No extra info
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	jnc	notHighScore

done:
	.leave
	ret


notHighScore:
	;    Clear name for next game. Don't clear if player achieved high
	;    score because the name hasn't been taken out of the 
	;    GetLoanBox yet.
	;

	clr	cx
	call	BJackSetHaveLoanName
	jmp	done

AddHighScore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddLowScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddLowScore	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	ax, MSG_HIGH_SCORE_ADD_SCORE
	mov	bx, handle HallOfShame
	mov	si, offset HallOfShame
	clr	bp			;No extra info
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	jnc	notHighScore

done:
	.leave
	ret


notHighScore:
	;    Clear name for next game. Don't clear if player achieved high
	;    score because the name hasn't been taken out of the 
	;    GetLoanBox yet.
	;

	clr	cx
	call	BJackSetHaveLoanName
	jmp	done

AddLowScore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyDeckSumDeck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the value of the hand.

CALLED BY:	MSG_SUM_DECK
PASS:		*ds:si	= MyDeckClass object
		ds:di	= MyDeckClass instance data
		ds:bx	= MyDeckClass object (same as *ds:si)
		es 	= segment of MyDeckClass
		ax	= message #

RETURN:		al	= value of hand
		ah	= number of cards
		cx	= 0 if hard, TRUE if soft

DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyDeckSumDeck	method dynamic MyDeckClass, 
					MSG_SUM_DECK
	uses	dx, bp
	.enter

	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock	;cx = number of cards
	push	cx

	clr	bx			;number of Aces = 0
	clr	ax			;sum = 0
sumLoop:
	tst	cx			;if no more cards, exit
	jz	checkAces
	dec	cx
	mov	bp, cx
	push	ax, bx, cx
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	dx, bp			;dx = cardAttrs
	mov	cl, offset CA_RANK
	ANDNF	dx, mask CA_RANK
	shr	dx, cl
	pop	ax, bx, cx
	cmp	dl, CR_ACE
	jne	notAce
	inc	bx			;an Ace
notAce:
	cmp	dl, CR_TEN		;ten or larger?
	jle	notFace			;not J,Q,K
	mov	dl, CR_TEN		;make it ten
notFace:
	add	ax, dx			;add rank of card
	jmp	sumLoop
checkAces:
	;
	;	If no aces, cannot be "soft".
	;
	clr	cx
aceLoop:
	;
	;	Add 10 for each ace until value > GAME_MAXIMUM-10
	;
	tst	bx
	jz	goOn			;no more aces?
	cmp	ax, GAME_MAXIMUM-10
	jg	goOn			;cannot add - will bust!
	add	ax, 10
	mov	cx, TRUE		;yup, mark "soft"
	jmp	aceLoop
goOn:	
	pop	dx
	mov	ah, dl			;copy numCards to ah
	.leave
	ret
MyDeckSumDeck	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyDeckSumDeckForDoubleDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the value of the hand, with only two
		cards in it, treating aces
		as low except in case of black jack.

PASS:		*ds:si	= MyDeckClass object
		ds:di	= MyDeckClass instance data
		ds:bx	= MyDeckClass object (same as *ds:si)
		es 	= segment of MyDeckClass
		ax	= message #

RETURN:		al	= value of hand

DESTROYED:	none

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyDeckSumDeckForDoubleDown	method dynamic MyDeckClass, 
					MSG_SUM_DECK_FOR_DOUBLE_DOWN
	uses	cx,dx, bp
	.enter

	;    Get Rank of two cards in deck
	;

	clr	bp
	mov	ax,MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	dx,bp			;first card attrs
	mov	cl, offset CA_RANK
	ANDNF	dx, mask CA_RANK
	shr	dx, cl

	push	dx
	mov	bp,1
	mov	ax,MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax,bp			;second card attrs
	mov	cl, offset CA_RANK
	ANDNF	ax, mask CA_RANK
	shr	ax, cl
	pop	dx			;first card rank

	;    Set face card values to 10
	;

	cmp	dl,CR_TEN
	jle	10$
	mov	dl,CR_TEN
10$:
	cmp	al,CR_TEN
	jle	20$
	mov	al,CR_TEN
20$:

	;     Check for possiblity of black jack

	cmp	dl,CR_ACE
	je	checkBlackJack
	xchg	al,dl
	cmp	dl,CR_ACE
	je	checkBlackJack

normalSum:
	;    Neither card is an ace card so we don't have to
	;    worry about a black jack. So just sum the cards
	;

	add	al,dl

done:
	.leave
	ret

checkBlackJack:
	;    One of the card is an ace. If the other card is not a 10
	;    then we can just sum the values. If the other card
	;    is a 10 then we can't sum the cards because we would
	;    get eleven and then ask the guy to double down when
	;    he really has a black jack.
	;

	cmp	al,CR_TEN
	jne	normalSum
	mov	al,21
	jmp	done

MyDeckSumDeckForDoubleDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyDeckPlay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play out the dealers hand and return the sum

CALLED BY:	MSG_PLAY
PASS:		*ds:si	= MyDeckClass object
		ds:di	= MyDeckClass instance data
		ds:bx	= MyDeckClass object (same as *ds:si)
		es 	= segment of MyDeckClass
		ax	= message #

RETURN:		
		al = hand sum		
		ah = number of cards

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyDeckPlay	method dynamic MyDeckClass, 
					MSG_PLAY
	uses	cx, dx, bp
	.enter

	mov	ax,MSG_SUM_DECK
	call	ObjCallInstanceNoLock
	cmp	ax,BLACK_JACK_VALUE
	je	done

	CallObject DealerStayRule, MSG_GEN_ITEM_GROUP_GET_SELECTION, MF_CALL
	mov	cx, ax					;cx = Stay rule
	mov	ax, si					;save si
	mov	si, offset IPlayText
	call	SetInstructionString
	mov	si, ax
playLoop:
	mov	ax, DEAL_DELAY
	call	TimerSleep
	push	cx
	mov	ax, MSG_SUM_DECK			;sum my hand
	call	ObjCallInstanceNoLock
	mov	bx, cx					;bx = "soft" status
	pop	cx

	;
	;	If dealer stays at soft 17, compare his hand with 17
	;
	cmp	cx, DEALER_STAY_SOFT_SEVENTEEN
	jne	notStaySoftSeventeen
	cmp	al, 17
	jge	iStay
	jmp	loopAgain
notStaySoftSeventeen:
	;
	;	Dealer stays at hard 17, check if hand is soft.
	;	If soft, take another card.
	;
	cmp	al, 17
	jne	not17
	tst	bx					;soft?
	jnz	loopAgain
not17:
	cmp	al, 17
	jge	iStay
	jmp	loopAgain
loopAgain:
	push	cx
	CallObject	MyPlayingTable, MSG_GET_NEXT_CARD, MF_CALL
							;nope, hit!
	mov	ax, MSG_DECK_GET_DEALT
	call	ObjCallInstanceNoLock
	mov	ax, MSG_CARD_FLIP
	call	VisCallFirstChild
	mov	ax, MSG_CARD_NORMAL_REDRAW
	call	VisCallFirstChild

	mov	ax, si
	mov	si, offset IHitText
	call	AppendInstructionString
	mov	si, ax
	pop	cx
	jmp	playLoop
iStay:
	mov	si, offset IStayText
	cmp	al, GAME_MAXIMUM
	jle	notBust
	mov	si, offset IBustText
notBust:
	call	AppendInstructionString
	push	ax					;hand sum
	mov	ax, DEAL_DELAY
	call	TimerSleep
	pop	ax					;hand sum

done:
	.leave
	ret
MyDeckPlay	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyDeckFlipSecondCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_FLIP_SECOND_CARD
PASS:		*ds:si	= MyDeckClass object
		ds:di	= MyDeckClass instance data
		ds:bx	= MyDeckClass object (same as *ds:si)
		es 	= segment of MyDeckClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyDeckFlipSecondCard	method dynamic MyDeckClass, 
					MSG_FLIP_SECOND_CARD
	uses	ax, cx, dx, bp
	.enter

	;
	;	First we show first card.
	;
	mov	ax, MSG_CARD_FLIP
	mov	bp, 1
	call	DeckCallNthChild

	mov	ax, MSG_CARD_NORMAL_REDRAW
	mov	bp, 1
	call	DeckCallNthChild

	mov	ax, MSG_GAME_NOTIFY_CARD_FLIPPED
	call	VisCallParent

	.leave
	ret
MyDeckFlipSecondCard	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckCallNthChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to find the deck's Nth child and send a
		method to it.

		< Copied from deck.asm >

CALLED BY:	

PASS:		bp = Nth child
		ax = method number to send to Nth child
		*ds:si = deck object
		cx,dx = arguments to pass to card
CHANGES:	

RETURN:		carry set if Nth child was not found
		carry returned from method if child was found

DESTROYED:	bp, cx, dx, di

PSEUDO CODE/STRATEGY:
		search for nth card
		if found, send the method

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckCallNthChild	proc	near
	;
	;	get the OD of the nth card
	;
	push	si

	push	ax, cx, dx
	mov	dx, bp
	clr	cx
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock
	pop	ax, bx, si

	jc	afterCall
	xchg	bx, cx
	xchg	si, dx
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
afterCall:
	pop	si
	ret
DeckCallNthChild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GAME_RESTORE_STATE
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #

RETURN:		^hcx - block of saved data
		dx - # bytes written

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
BJackExtraSaveData	struct
	BESD_cashHigh			word
	BESD_cashLow			word
	BESD_markers			word
	BESD_wager			word
	BESD_status			word
BJackExtraSaveData	ends

BJackGameRestoreState	method dynamic BJackGameClass, 
					MSG_GAME_RESTORE_STATE
	uses	ax, bx, cx, es, di, bp
	.enter

	;
	;  Call superclass to alloc the block
	;

	mov	di, offset BJackGameClass
	call	ObjCallSuperNoLock

	;
	;  Read our important stuff out
	;
	mov	bx, cx
	call	MemLock
	jc	done

	mov	es, ax
	mov	di, dx

	mov	dx, di
	add	dx, size BJackExtraSaveData

	mov	bx, ds:[si]
	add	bx, ds:[bx].BJackGame_offset
	mov	ax, es:[di].BESD_cashHigh
	mov	ds:[bx].BGI_cash.high, ax
	mov	ax, es:[di].BESD_cashLow
	mov	ds:[bx].BGI_cash.low, ax
	mov	ax, es:[di].BESD_markers
	mov	ds:[bx].BGI_markers, ax
	mov	ax, es:[di].BESD_wager
	mov	ds:[bx].BGI_wager, ax
	mov	ax, es:[di].BESD_status
	mov	ds:[bx].BGI_status, al
	mov	ds:[bx].BGI_special, ah

	mov	bx, cx
	call	MemUnlock

done:
	.leave
	ret
BJackGameRestoreState	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GAME_SAVE_STATE
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #

RETURN:		^hcx - block of saved data
		dx - # bytes written

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
BJackGameSaveState	method dynamic BJackGameClass, 
					MSG_GAME_SAVE_STATE
	uses	ax, bx, si, di, es, bp
	.enter

	;
	;  Call superclass to alloc the block
	;

	mov	di, offset BJackGameClass
	call	ObjCallSuperNoLock

	mov	ax, dx
	add	ax, 7 * size word

	;
	;  need to alloc N words + 1 (to indicate how many) in the block
	;
	mov	di, dx
	mov	bx, cx
	mov	ch, HAF_STANDARD_NO_ERR_LOCK
	call	MemReAlloc
	mov	es, ax				;es:di <- data

	;
	; save our important stuff
	;
	mov	si, ds:[si]
	add	si, ds:[si].BJackGame_offset

	mov	ax, ds:[si].BGI_cash.high
	stosw
	mov	ax, ds:[si].BGI_cash.low
	stosw
	mov	ax, ds:[si].BGI_markers
	stosw
	mov	ax, ds:[si].BGI_wager
	stosw
	mov	al, ds:[si].BGI_status
	mov	ah, ds:[si].BGI_special
	stosw

	call	MemUnlock

	mov	cx, bx
	mov	dx, di

	.leave
	ret
BJackGameSaveState	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameDisplayCash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_DISPLAY_CASH
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameDisplayCash	method dynamic BJackGameClass, 
					MSG_DISPLAY_CASH
	uses	ax, cx, dx, bp
	.enter
	mov	cx, ds:[di].BGI_cash.high
	mov	dx, ds:[di].BGI_cash.low

	call	DisplayCash
	.leave
	ret
BJackGameDisplayCash	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameDisplayWelcomeText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_DISPLAY_WELCOME_TEXT
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameDisplayWelcomeText	method dynamic BJackGameClass, 
					MSG_DISPLAY_WELCOME_TEXT
	uses	si
	.enter
	mov	si, offset WelcomeText
	call	SetInstructionString
	.leave
	ret
BJackGameDisplayWelcomeText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameDoubleDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_DOUBLE_DOWN
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameDoubleDown	method dynamic BJackGameClass, 
					MSG_DOUBLE_DOWN
	uses	ax, bx, cx, dx, bp
	.enter

	;	Increase wager by current wager for double down.
	;
	or	ds:[di].BGI_special, DOUBLE_DOWN
	call	ObjMarkDirty

	mov	cx, ds:[di].BGI_wager
	mov	ax, MSG_ADJUST_WAGER_AND_CASH_NO_LIMIT
	call	ObjCallInstanceNoLock

	mov	ax, MSG_HIT
	call	ObjCallInstanceNoLock

	.leave
	ret
BJackGameDoubleDown	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameInsurance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_INSURANCE
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #
RETURN:		

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameInsurance	method dynamic BJackGameClass, 
					MSG_INSURANCE
	uses	ax, cx, dx, bp
	.enter
	mov	dx, ds:[di].BGI_wager
	shr	dx, 1
	jnc	10$
	inc	dx				;round up
10$:
	push	dx				;store half of wager

	mov	dl, VUM_NOW
	push	si
	CallObject Deck1, MSG_SUM_DECK, MF_CALL
	pop	si
	pop	dx				;dx = half of wager
	cmp	ax, BLACK_JACK_VALUE		;dealer BJ?
	jne	noBlackJack
	shl	dx				;2 to 1 for winning
	push	si
	clr	cx
	call	DisplayYouWonInDeck1Instructions
	pop	si
update:
	;
	;	If dx=0 (ie wager=1), cannot update otherwise stash will
	;	be reset to 0.
	;
	cmp	dx, 0
	je	done
	clr	cx				;relative wager change
	push	ax
	mov	ax, MSG_GAME_UPDATE_SCORE	;deduct from player's stash
	call	ObjCallInstanceNoLock
	pop	ax

done:
	.leave
	ret

noBlackJack:
	;
	;	Dealer does not have BJ, so minus DX from stash.
	;
	push	si
	clr	cx
	call	DisplayYouLostInDeck1Instructions
	pop	si

	neg	dx
	call	BJackGameNotifyPlayerOfLostInsuranceMoney
	jmp	update

BJackGameInsurance	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameNotifyPlayerOfLostInsuranceMoney
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the player that they lost their insurance money

CALLED BY:	INTERNAL
		BJackGameInsurance

PASS:		
		nothing

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
	srs	6/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameNotifyPlayerOfLostInsuranceMoney		proc	near
	uses	si
	.enter

	mov	si, offset LostInsuranceText
	call	SetInstructionString

	.leave
	ret
BJackGameNotifyPlayerOfLostInsuranceMoney		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameSplit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_SPLIT
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameSplit	method dynamic BJackGameClass, 
					MSG_SPLIT
	uses	ax, bx, cx, dx, bp
	.enter

	or	ds:[di].BGI_special, SPLIT
	call	ObjMarkDirty

	mov	cx, ds:[di].BGI_wager
	mov	ax, MSG_ADJUST_WAGER_AND_CASH_NO_LIMIT
	call	ObjCallInstanceNoLock

	push	si
	mov	cx, DECK3_LEFT
	mov	dx, DECK3_TOP
	mov	bx, handle Deck3
	mov	si, offset Deck3
	call	BJackPositionDeck
	mov	si,offset PlayOtherHandText
	call	SetDeck3InstructionsString

	CallObjectNS	Deck2, MSG_DECK_POP_CARD, MF_CALL
	CallObjectNS	Deck3, MSG_DECK_PUSH_CARD, MF_CALL
	pop	si

	mov	ax, MSG_GET_NEXT_CARD
	call	ObjCallInstanceNoLock

	push	si
	CallObjectNS	Deck2, MSG_DECK_GET_DEALT, MF_CALL
	CallObjectNS	Deck2, MSG_CARD_FLIP_CARD, MF_CALL
	pop	si

	mov	ax, MSG_GET_NEXT_CARD
	call	ObjCallInstanceNoLock

	push	si
	CallObjectNS	Deck3, MSG_DECK_GET_DEALT, MF_CALL
	CallObjectNS	Deck3, MSG_CARD_FLIP_CARD, MF_CALL
	pop	si
	;
	;	Check if the player split a pair of aces.
	;
	mov	bp, 1
	CallObject	Deck2, MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
	mov	dx, bp
	mov	cl, offset CA_RANK
	ANDNF	dx, mask CA_RANK
	shr	dx, cl
	cmp	dl, CR_ACE
	je	splitAces

done:
	.leave
	ret

splitAces:
	;
	;	Splitting aces gives only one card to each hand, and stays.
	;
	PointDi2 Game_offset
	mov	ds:[di].BGI_status, WAITING_TO_HIT2
	mov	ax, MSG_STAY
	call	ObjCallInstanceNoLock
	jmp	done


BJackGameSplit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameHandSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:	MSG_GAME_HAND_SELECTED
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	1) If WAITING_FOR_NEW_GAME, send MSG_NEW_GAME
	2) If WAITING_TO_HIT, send MSG_STAY
	3) If WAITING_TO_HIT2, send MSG_STAY

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameHandSelected	method dynamic BJackGameClass, 
					MSG_GAME_HAND_SELECTED
	uses	ax, cx, dx, bp
	.enter
	cmp	ds:[di].BGI_status, WAITING_FOR_NEW_GAME
	jne	notNewGame
	mov	ax, MSG_NEW_GAME
	call	ObjCallInstanceNoLock
	jmp	done

notNewGame:
	cmp	ds:[di].BGI_status, WAITING_TO_HIT
	je	hit
	cmp	ds:[di].BGI_status, WAITING_TO_HIT2
	jne	done
hit:
	mov	ax, MSG_HIT
	call	ObjCallInstanceNoLock
done:	
	.leave
	ret
BJackGameHandSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackGameDeckSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GAME_DECK_SELECTED
PASS:		*ds:si	= BJackGameClass object
		ds:di	= BJackGameClass instance data
		ds:bx	= BJackGameClass object (same as *ds:si)
		es 	= segment of BJackGameClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	1) If Deck1 selected, do nothing.
	2) If Deck2 selected:
		a) if WAITING_TO_HIT, stay
		b) else do nothing
	3) If Deck3 selected:
		a) if WAITING_TO_HIT, do nothing
		b) if WAITING_TO_HIT2, stay
		c) else do nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	4/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackGameDeckSelected	method dynamic BJackGameClass, 
					MSG_GAME_DECK_SELECTED
	uses	ax, cx, dx, bp
	.enter
	cmp	cx, handle Deck1
	jne	notDeck1
	cmp	dx, offset Deck1
	je	done

notDeck1:
	cmp	cx, handle Deck2
	jne	notDeck2
	cmp	dx, offset Deck2
	jne	notDeck2
	cmp	ds:[di].BGI_status, WAITING_TO_HIT
	jne	done
	mov	ax, MSG_STAY
	call	ObjCallInstanceNoLock
	jmp	done	

notDeck2:
	cmp	cx, handle Deck3
	jne	done
	cmp	dx, offset Deck3
	jne	done
	cmp	ds:[di].BGI_status, WAITING_TO_HIT2
	jne	done
	mov	ax, MSG_STAY
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
BJackGameDeckSelected	endm

MyDeckSetCard	method dynamic MyDeckClass, 
					MSG_SET_CARD
	.enter
	mov	ax, MSG_CARD_SET_ATTRIBUTES
	call	VisCallFirstChild
	.leave
	ret
MyDeckSetCard	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyDeckPopCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To fix a bug in the existing pop card.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of MyDeckClass

		^lcx:dx - card

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
	srs	6/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyDeckPopCard	method dynamic MyDeckClass, MSG_DECK_POP_CARD
	.enter

	mov	di,offset MyDeckClass
	call	ObjCallSuperNoLock

	push	ax,cx,dx,bp
	mov	ax,MSG_CARD_MAXIMIZE
	call	VisCallFirstChild
	pop	ax,cx,dx,bp

	.leave
	ret
MyDeckPopCard		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackCheckHaveName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return BI_askedForLoanNameThisGame

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BJackInteractionClass

RETURN:		
		cx - BI_askedForLoanNameThisGame
	
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
	srs	8/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackCheckHaveName	method dynamic BJackInteractionClass, 
						MSG_BJACK_CHECK_HAVE_NAME
	.enter

	mov	cx,ds:[di].BI_askedForLoanNameThisGame

	.leave
	ret
BJackCheckHaveName		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackSetHaveName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set BI_beenIntiatedThisGame

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BJackInteractionClass

		cx - BI_beenIntiatedThisGame

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
	srs	8/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackSetHaveName	method dynamic BJackInteractionClass, 
						MSG_BJACK_SET_HAVE_NAME
	.enter

	mov	ds:[di].BI_askedForLoanNameThisGame,cx

	.leave
	ret
BJackSetHaveName		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackHighScoreGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use the name in the GetLoanText box if there is one. 
		Otherwise call superclass to get name the normal way.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BJackHighScoreClass

		dx:bp - dest for name

RETURN:		
		name at dx:bp			

	
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
	srs	6/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackHighScoreGetName	method dynamic BJackHighScoreClass, 
						MSG_HIGH_SCORE_GET_NAME
	.enter

	;    If we asked for loan name this game and we were given a name
	;    then use it. Otherwise ask again by calling superclass
	;

	call	BJackCheckHaveLoanName
	jcxz	callSuper

	push	si,ax					;high score chunk, msg
	mov	bx,handle GetLoanText
	mov	si,offset GetLoanText
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage
	pop	si,ax					;high score chunk, msg

	;    Call the super class if there are no characters in
	;    name field.
	;

	jcxz	callSuper

clearHaveName:
	;    Clear have loan name so we will ask player for name
	;    next game if s/he requests a loan
	;

	clr	cx
	call	BJackSetHaveLoanName


	.leave
	ret

callSuper:
	mov	di,offset BJackHighScoreClass
	call	ObjCallSuperNoLock

	jmp	clearHaveName


BJackHighScoreGetName		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackCheckHaveLoanName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if we have gotten loan name from the user in 
		this game

CALLED BY:	INTERNAL
		BJackHighScoreGetName

PASS:		
		nothing

RETURN:		
		cx - non zero if have name

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
	srs	8/31/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackCheckHaveLoanName		proc	near
	uses	ax,bx,di,si
	.enter

	mov	bx, handle BJackSummonsGroup
	mov	si, offset BJackSummonsGroup
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_BJACK_CHECK_HAVE_NAME
	call	ObjMessage

	.leave
	ret
BJackCheckHaveLoanName		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackSetHaveLoanName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set variable that tells whether we have gotten a
		loan name this game

CALLED BY:	INTERNAL

PASS:		
		cx - zero if haven't got name
		     non zero if have got name

RETURN:		
		return

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
	srs	8/31/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackSetHaveLoanName		proc	near
	uses	ax,bx,di,si
	.enter

	mov	bx, handle BJackSummonsGroup
	mov	si, offset BJackSummonsGroup
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_BJACK_SET_HAVE_NAME
	call	ObjMessage

	.leave
	ret
BJackSetHaveLoanName		endp

CommonCode	ends		;end of CommonCode resource
