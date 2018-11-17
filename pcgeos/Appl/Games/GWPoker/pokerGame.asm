COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWorks Poker
FILE:		pokerGame.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	6/90		Initial Version
	bchow	3/93		2.0 Conversion

DESCRIPTION:


RCS STAMP:
$Id: pokerGame.asm,v 1.1 97/04/04 15:20:12 newdeal Exp $
------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	Objects/vTextC.def
UseLib	game.def
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

PokerGameClass		class	GameClass

MSG_DISPLAY_CASH	message

MSG_BORROW_ONE_HUNDRED_DOLLARS	message

MSG_BUST		message

MSG_SOLITAIRE_CASH_OUT	message

MSG_SHOW_WINNINGS	message

MSG_ADD_JOKER		message
;
;	Adds a joker to the game's hand object's composite. There is no
;	corresponding MSG_REMOVE_JOKER.
;
;	PASS:		nothing
;
;	RETURN:		^lcx:dx = new joker (already added to hand's composite)

MSG_ANALYZE_HAND	message
;
;	Fills in the game's instance data regarding the distribution of the
;	cards (e.g., PGI_nSevens etc. and PGI_nClubs) so that a
;	METTHOD_DETERMINE_HAND can be later sent to figure out how well
;	the user has done.
;
;	PASS:		ch = low byte of CardAttrs for card #1
;			cl = low byte of CardAttrs for card #2
;			dh = low byte of CardAttrs for card #3
;			dl = low byte of CardAttrs for card #4
;			bp = CardAttrs for card #5
;
;			These cards are numbered 1-5 for reference only
;
;	RETURN:		nothing

MSG_CALCULATE_WINNINGS	message
;
;	Returns the amount of money that should be paid out given a
;	PokerHand.
;
;	PASS:		bp = PokerHand
;
;	RETURN:		dx = $ won (= wager * payoff rate)

MSG_CASH_TO_TEXT	message
;
;	Writes the current score (cash) to a text display object.
;
;	PASS:		^lcx:dx = text display object
;
;	RETURN:		nothing

MSG_CHECK_DISTRIBUTION	message
;
;	Fills in the PGI_mostOfAKind, PGI_rankOfMostOfAKind, and
;	PGI_variety fields once all the PGI_nAces etc. fields
;	have been filled in
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_CHECK_FUNDS		message

MSG_CHECK_MAXIMUM_BET	message
;
;	Makes sure that the passed value does not exceed the maximum payoff
;	for this poker game. If it does, the maximum value is returned.
;
;	PASS:		dx = amount to check
;
;	RETURN:		dx = the lesser of the passed value and the max win

MSG_CLEAN_ANALYSIS	message
;
;	Zeroes a bunch of instance data in preparation for a new hand.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_DEAL	message
;
;	Deals out five cards, one to each deck object, for the start of
;	a new game.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_DETERMINE_HAND	message
;
;	Returns the best poker hand represented by the dealt cards.
;	This method handler uses the game's instance data to
;	determine what that hand is (i.e., the cards themselves are
;	not polled for information at this point; that must have
;	been done previously to set up the instance data).
;
;	PASS:		nothing
;
;	RETURN:		bp = PokerHand
	
MSG_GET_NEXT_CARD	message
;
;	Removes the top card from the game's hand object.
;
;	PASS:		nothing
;
;	RETURN:		^lcx:dx = card popped from hand

MSG_GET_NEXT_NON_WILD_CARD	message
;
;	Removes the top non-wild card from the game's hand object. If the
;	top card is wild, it is exchanged with another card in the
;	composite, and the method calls itself recursively.
;
;	PASS:		nothing
;
;	RETURN:		^lcx:dx = card popped from hand object, guaranteed
;				  to be not wild.

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

MSG_SOLITAIRE_NEW_GAME	message
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

MSG_REGISTER_FLASHER	message
;
;	Records the OD of the payoff display that wants to hilight itself.
;	If there was any previous flasher, then it is restored to its
;	non-hilighted state
;
;	PASS:		cx:dx = OD of display object
;
;	RETURN:		nothing

MSG_VIS_TEXT_REPLACE_DISCARDED	message
;
;	This method causes the game object to deal new cards to any
;	and all decks that have their top card turned face down.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SETTLE_BETS		message
;
;	Checks to see what poker hand the user has been dealt,
;	then pays off the winnings if need be.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_SET_FADE_STATUS	message
;
;	Turns fading either on or off for this game.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SET_WILD		message
;
;	Sets up the payoff scheme for a wild/no wild poker game,
;	and shows the user the chart of the updated payoffs
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

MSG_ADJUST_WAGER_AND_CASH	message
;	cx - amount to change bet and cash

MSG_ADJUST_WAGER_AND_CASH_FROM_TRIGGERS	message


MSG_POKER_FLASH		message

MSG_POKER_STOP_FLASHING	message

MSG_FREE_MILLION	message

MSG_GAME_INITIALIZE	message



PokerHand	etype	byte
SHIT_HIGH		enum	PokerHand, 0		; must be zero
LOW_PAIR		enum	PokerHand, 1
HIGH_PAIR		enum	PokerHand, 2
TWO_PAIR		enum	PokerHand, 3
THREE_OF_A_KIND		enum	PokerHand, 4
STRAIGHT		enum	PokerHand, 5
FLUSH			enum	PokerHand, 6
FULL_HOUSE		enum	PokerHand, 7
FOUR_OF_A_KIND		enum	PokerHand, 8
STRAIGHT_FLUSH		enum	PokerHand, 11		; = STRAIGHT + FLUSH
ROYAL_FLUSH		enum	PokerHand, 12
FIVE_OF_A_KIND		enum	PokerHand, 13

WildChoice	etype	byte
NO_WILD		enum	WildChoice
JOKERS_WILD	enum	WildChoice
DEUCES_WILD	enum	WildChoice

INITIAL_CASH = 100
INITIAL_WAGER = 5

FONT_SIZE = 10

PayoffSchema	struct
	PS_whatsWild		WildChoice
	PS_maximumBet		word
	PS_fiveOfAKind		word
	PS_royalFlush		word
	PS_straightFlush	word
	PS_fourOfAKind		word
	PS_fullHouse		word
	PS_flush		word
	PS_straight		word
	PS_threeOfAKind		word
	PS_twoPair		word
	PS_highPair		word
	PS_lowPair		word
	PS_minimumPair		CardRank
PayoffSchema	ends

HandAnalysis	struct
	HA_nAces		byte
	HA_nTwos		byte
	HA_nThrees		byte
	HA_nFours		byte
	HA_nFives		byte
	HA_nSixes		byte
	HA_nSevens		byte
	HA_nEights		byte
	HA_nNines		byte
	HA_nTens		byte
	HA_nJacks		byte
	HA_nQueens		byte
	HA_nKings		byte
	HA_nWildcards		byte

	HA_nDiamonds		byte
	HA_nHearts		byte
	HA_nClubs		byte
	HA_nSpades		byte

	HA_highestIfAceHigh	CardRank
	HA_lowestIfAceHigh	CardRank
	HA_highestIfAceLow	CardRank
	HA_lowestIfAceLow	CardRank

	HA_variety		byte

	HA_mostOfAKind		byte
	HA_rankOfMostOfAKind	CardRank

HandAnalysis	ends

PokerGameStatus	etype	byte
WAITING_FOR_NEW_GAME		enum	PokerGameStatus
WAITING_TO_REPLACE_CARDS	enum	PokerGameStatus
BUSY				enum	PokerGameStatus

ATTR_POKER_GAME_OPEN	vardata	byte
; indicates that the game object is open and has not yet been saved
; to state.



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;			INSTANCE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PGI_cash			dword		;this represents the user's
						;cash won so far; in effect
						;his score. The score in 
						;GameClass is not used, as
						;it is crucial that the score
						;here be a dword, lest the
						;user easily overflow (or
						;underflow :) the score.

PGI_markers			word

PGI_flasherTimer		hptr
PGI_flasherTimerID		word

PGI_flasher			optr		;holds the OD of any payoff
						;display that is currently
						;hilighted

;
;	The following instance slots, suffixed with 'Payoff' are the factors
;	by which to scale the users wager before paying her for the
;	indicated hand
;
PGI_wager			word			;amount bet this game
PGI_status			PokerGameStatus

PGI_payoffSchema		nptr
PGI_handAnalysis		HandAnalysis
PGI_haveName			word			;non zero if
							;have asked for 
							;loan name

PokerGameClass	endc

InstDisplayClass	class	VisTextClass

InstDisplayClass endc

PokerHighScoreClass	class	HighScoreClass
PokerHighScoreClass	endc

PayoffVisCompClass	class	VisCompClass
PayoffVisCompClass	endc

PokerInteractionClass	class	GenInteractionClass

MSG_POKER_CHECK_HAVE_NAME	message

MSG_POKER_SET_HAVE_NAME	message

PI_askedForLoanNameThisGame	word

PokerInteractionClass	endc

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

	PokerGameClass
	InstDisplayClass
	PokerHighScoreClass
	PayoffVisCompClass
	PokerInteractionClass

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends

;------------------------------------------------------------------------------
;		Code for PokerGameClass
;------------------------------------------------------------------------------
CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameSetupStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SETUP_STUFF handler for PokerGameClass
		Sets up various sizes and defaults necessary when first
		loading the game in.

CALLED BY:	

PASS:		nothing
		
CHANGES:	initializes data slots

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
PokerGameSetupStuff	method	PokerGameClass, MSG_MY_SETUP_STUFF
	.enter

	;
	;	Call the super class to take care of vm files, geometry, etc.
	;
	mov	di, offset PokerGameClass
	call	ObjCallSuperNoLock

	tst	ss:[restoringFromState]
	jnz	skip
	;
	;	Initialize the score and wager fields if not restoring from
	;	state.
	;
	mov	ax, MSG_GAME_UPDATE_SCORE
	mov	cx, INITIAL_CASH
	call	ObjCallInstanceNoLock

	mov	ax, MSG_UPDATE_WAGER
	mov	cx, INITIAL_WAGER
	clr	dx
	call	ObjCallInstanceNoLock

	mov	ax, MSG_SHOW_WINNINGS
	clr	cx
	clr	dx
	call	ObjCallInstanceNoLock
skip:
	;
	;	Setup sounds.
	;
	CallMod	SoundSetupSounds

	;
	;	Read the UI to see whether or not we want wild cards to
	;	show up while playing
	;
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	mov	ax, MSG_SET_WILD
	call	ObjMessage

	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	mov	ax, MSG_SOLITAIRE_SET_FADE_STATUS
	call	ObjMessage

	.leave
	ret
PokerGameSetupStuff	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SETUP_GEOMETRY handler for PokerGameClass
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
PokerGameSetupGeometry	method	PokerGameClass, MSG_GAME_SETUP_GEOMETRY


	uses	ax, bx, cx, dx, si, di
	.enter

	push	cx,dx 				;deck spacing
	mov	di, offset PokerGameClass
	call	ObjCallSuperNoLock
	pop	cx,dx				;deck spacing
	
	call	PokerGetFieldSize
	cmp	bx,480
	jne	notVGA

doVGA:
	call	PokerVGAGameSetupGeometry

done:
	.leave
	ret

notVGA:
	cmp	bx,350
	jne	notEGA
	call	PokerEGAGameSetupGeometry
	jmp	done

notEGA:
	cmp	bx,348
	jne	notHerc
	call	PokerHercGameSetupGeometry	;EGA should work for herc
	jmp	done

notHerc:
	cmp	bx,200
	jne	notCGA
	call	PokerCGAGameSetupGeometry
	jmp	done

notCGA:
	cmp	ax,256
	jne	doVGA				;whatever
	call	PokerZoomerGameSetupGeometry
	jmp	done


PokerGameSetupGeometry	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerGetFieldSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width and height of the field object

CALLED BY:	INTERNAL
		PokerGameSetupGeometry

PASS:		nothing

RETURN:		
		ax - width
		bx - height

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
	srs	6/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGetFieldSize		proc	near
	uses	cx,dx,di,si,bp
	.enter

	;    Use VUP_QUERY to field to avoid building GenApp object.
	;

        mov     bx, segment GenFieldClass
        mov     si, offset GenFieldClass
        mov     ax, MSG_VIS_GET_SIZE
        mov     di, mask MF_RECORD
        call    ObjMessage                      ; di = event handle
        mov     cx, di                          ; cx = event handle
        mov     bx, handle PokerApp
        mov     si, offset PokerApp
        mov     ax, MSG_GEN_CALL_PARENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
        call    ObjMessage	          ; ah = display type, bp = ptsize

	mov	ax,cx
	mov	bx,dx

	.leave
	ret
PokerGetFieldSize		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerVGAGameSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Layout decks and instructions to fit on a desktop
		sized screen.

CALLED BY:	INTERNAL
		PokerrGameSetupGeometryy

PASS:		*ds:si - PokerGame
		cx,dx - deck spacing

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
	srs	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerVGAGameSetupGeometry		proc	near

cardWidth		local	word
cardHeight		local	word

	class	PokerGameClass
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].PokerGame_offset
	
	mov	bx, ds:[di].GI_cardWidth
	mov	ss:[cardWidth], bx
	mov	bx, ds:[di].GI_cardHeight
	mov	ss:[cardHeight], bx

	mov	ax,cx				;deck spacing
	mov	di,dx				;deck spacing

	mov	cx, VGA_INSTRUCTION_LEFT
	mov	dx, VGA_INSTRUCTION_TOP
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, VGA_INSTRUCTION2_LEFT
	mov	dx, VGA_INSTRUCTION2_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION2_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, VGA_HAND_LEFT
	mov	dx, VGA_HAND_TOP
	mov	bx, handle MyHand
	mov	si, offset MyHand
	call	PokerPositionDeck

	mov	cx, VGA_DECK_LEFT
	mov	dx, VGA_HAND_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	add	dx, di
	mov	bx, handle Deck1
	mov	si, offset Deck1
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck2
	mov	si, offset Deck2
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck3
	mov	si, offset Deck3
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck4
	mov	si, offset Deck4
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck5
	mov	si, offset Deck5
	call	PokerPositionDeck

	mov	cx, VGA_CHART_LEFT
	mov	dx, VGA_CHART_TOP
	mov	bx, handle ThePayoffChart
	mov	si, offset ThePayoffChart
	mov	ax, MSG_VIS_POSITION_BRANCH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GAME_SET_UP_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_GAME_SET_DOWN_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
PokerVGAGameSetupGeometry		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerEGAGameSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Layout decks and instructions to fit on a desktop
		sized screen.

CALLED BY:	INTERNAL
		PokerrGameSetupGeometryy

PASS:		*ds:si - PokerGame
		cx,dx - deck spacing

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
	srs	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerEGAGameSetupGeometry		proc	near

cardWidth		local	word
cardHeight		local	word

	class	PokerGameClass
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].PokerGame_offset
	
	mov	bx, ds:[di].GI_cardWidth
	mov	ss:[cardWidth], bx
	mov	bx, ds:[di].GI_cardHeight
	mov	ss:[cardHeight], bx

	mov	ax,cx				;deck spacing
	mov	di,dx				;deck spacing

	mov	cx, EGA_INSTRUCTION_LEFT
	mov	dx, EGA_INSTRUCTION_TOP
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, EGA_INSTRUCTION2_LEFT
	mov	dx, EGA_INSTRUCTION2_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	add	dx, di
	add	dx, di
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION2_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, EGA_HAND_LEFT
	mov	dx, EGA_HAND_TOP
	mov	bx, handle MyHand
	mov	si, offset MyHand
	call	PokerPositionDeck

	mov	cx, EGA_DECK_LEFT
	mov	dx, EGA_HAND_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	mov	bx, handle Deck1
	mov	si, offset Deck1
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck2
	mov	si, offset Deck2
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck3
	mov	si, offset Deck3
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck4
	mov	si, offset Deck4
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck5
	mov	si, offset Deck5
	call	PokerPositionDeck

	mov	cx, EGA_CHART_LEFT
	mov	dx, EGA_CHART_TOP
	mov	bx, handle ThePayoffChart
	mov	si, offset ThePayoffChart
	mov	ax, MSG_VIS_POSITION_BRANCH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GAME_SET_UP_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_GAME_SET_DOWN_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
PokerEGAGameSetupGeometry		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerHercGameSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Layout decks and instructions to fit on a desktop
		sized screen.

CALLED BY:	INTERNAL
		PokerrGameSetupGeometryy

PASS:		*ds:si - PokerGame
		cx,dx - deck spacing

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
	srs	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerHercGameSetupGeometry		proc	near

cardWidth		local	word
cardHeight		local	word

	class	PokerGameClass
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].PokerGame_offset
	
	mov	bx, ds:[di].GI_cardWidth
	mov	ss:[cardWidth], bx
	mov	bx, ds:[di].GI_cardHeight
	mov	ss:[cardHeight], bx

	mov	ax,cx				;deck spacing
	mov	di,dx				;deck spacing

	mov	cx, HERC_INSTRUCTION_LEFT
	mov	dx, HERC_INSTRUCTION_TOP
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, HERC_INSTRUCTION2_LEFT
	mov	dx, HERC_INSTRUCTION2_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	add	dx, di
	add	dx, di
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION2_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, HERC_HAND_LEFT
	mov	dx, HERC_HAND_TOP
	mov	bx, handle MyHand
	mov	si, offset MyHand
	call	PokerPositionDeck

	mov	cx, HERC_DECK_LEFT
	mov	dx, HERC_HAND_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	mov	bx, handle Deck1
	mov	si, offset Deck1
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck2
	mov	si, offset Deck2
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck3
	mov	si, offset Deck3
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck4
	mov	si, offset Deck4
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck5
	mov	si, offset Deck5
	call	PokerPositionDeck

	mov	cx, HERC_CHART_LEFT
	mov	dx, HERC_CHART_TOP
	mov	bx, handle ThePayoffChart
	mov	si, offset ThePayoffChart
	mov	ax, MSG_VIS_POSITION_BRANCH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GAME_SET_UP_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_GAME_SET_DOWN_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
PokerHercGameSetupGeometry		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerCGAGameSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Layout decks and instructions to fit on a desktop
		sized screen.

CALLED BY:	INTERNAL
		PokerrGameSetupGeometryy

PASS:		*ds:si - PokerGame
		cx,dx - deck spacing

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
	srs	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerCGAGameSetupGeometry		proc	near

cardWidth		local	word
cardHeight		local	word

	class	PokerGameClass
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].PokerGame_offset
	
	mov	bx, ds:[di].GI_cardWidth
	mov	ss:[cardWidth], bx
	mov	bx, ds:[di].GI_cardHeight
	mov	ss:[cardHeight], bx

	mov	ax,cx				;deck spacing
	mov	di,dx				;deck spacing

	mov	cx, CGA_INSTRUCTION_LEFT
	mov	dx, CGA_INSTRUCTION_TOP
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, CGA_INSTRUCTION2_LEFT
	mov	dx, CGA_INSTRUCTION2_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION2_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, CGA_HAND_LEFT
	mov	dx, CGA_HAND_TOP
	mov	bx, handle MyHand
	mov	si, offset MyHand
	call	PokerPositionDeck

	mov	cx, CGA_DECK_LEFT
	mov	dx, CGA_HAND_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	mov	bx, handle Deck1
	mov	si, offset Deck1
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck2
	mov	si, offset Deck2
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck3
	mov	si, offset Deck3
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck4
	mov	si, offset Deck4
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck5
	mov	si, offset Deck5
	call	PokerPositionDeck

	mov	bx, handle ThePayoffChart
	mov	si, offset ThePayoffChart
	mov	ax,MSG_VIS_COMP_SET_GEO_ATTRS
	mov	cl, mask VCGA_ALLOW_CHILDREN_TO_WRAP or \
			mask VCGA_WRAP_AFTER_CHILD_COUNT
	clr	ch,dl,dh
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax,MSG_VIS_RECALC_SIZE
	mov	di, mask MF_FIXUP_DS
	mov	cx,mask RSA_CHOOSE_OWN_SIZE
	mov	dx,mask RSA_CHOOSE_OWN_SIZE
	call	ObjMessage

	mov	cx, CGA_CHART_LEFT
	mov	dx, CGA_CHART_TOP
	mov	ax, MSG_VIS_POSITION_BRANCH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GAME_SET_UP_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_GAME_SET_DOWN_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
PokerCGAGameSetupGeometry		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PayoffVisCompGetWrapCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of children to wrap after in the
		payoff chart. Used for CGA mode only.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PayVisComp

RETURN:		
		cx = 5
	
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
	srs	6/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PayoffVisCompGetWrapCount	method dynamic PayoffVisCompClass, 
				MSG_VIS_COMP_GET_WRAP_COUNT
						
	.enter

	mov	cx,5

	.leave
	ret
PayoffVisCompGetWrapCount		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerZoomerGameSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerZoomerGameSetupGeometry		proc	near

cardWidth		local	word
cardHeight		local	word

	class	PokerGameClass
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].PokerGame_offset
	
	mov	bx, ds:[di].GI_cardWidth
	mov	ss:[cardWidth], bx
	mov	bx, ds:[di].GI_cardHeight
	mov	ss:[cardHeight], bx

	mov	ax,cx				;deck spacing
	mov	di,dx				;deck spacing

	mov	cx, ZOOMER_INSTRUCTION_LEFT
	mov	dx, ZOOMER_INSTRUCTION_TOP
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle InstructionDisplay
	mov	si, offset InstructionDisplay
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, ZOOMER_INSTRUCTION2_LEFT
	mov	dx, ZOOMER_INSTRUCTION2_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	call	PokerPositionDeck

	push	ax, di
	mov	cx, INSTRUCTION2_WIDTH
	mov	dx, INSTRUCTION_HEIGHT
	mov	ax, MSG_VIS_SET_SIZE
	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	clr	di
	call	ObjMessage
	pop	ax, di

	mov	cx, ZOOMER_HAND_LEFT
	mov	dx, ZOOMER_HAND_TOP
	mov	bx, handle MyHand
	mov	si, offset MyHand
	call	PokerPositionDeck

	mov	cx, ZOOMER_DECK_LEFT
	mov	dx, ZOOMER_HAND_TOP
	add	dx, ss:[cardHeight]
	add	dx, di
	add	dx, di
	add	dx, di
	add	dx, di
	mov	bx, handle Deck1
	mov	si, offset Deck1
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck2
	mov	si, offset Deck2
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck3
	mov	si, offset Deck3
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck4
	mov	si, offset Deck4
	call	PokerPositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Deck5
	mov	si, offset Deck5
	call	PokerPositionDeck

	mov	cx, ZOOMER_CHART_LEFT
	mov	dx, ZOOMER_CHART_TOP
	mov	bx, handle ThePayoffChart
	mov	si, offset ThePayoffChart
	mov	ax, MSG_VIS_POSITION_BRANCH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GAME_SET_UP_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_GAME_SET_DOWN_SPREADS
	clr	cx
	clr	dx
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage


	.leave
	ret
PokerZoomerGameSetupGeometry		endp


AdjustDisplay	proc	far
	CallObjectNS	FiveOfAKindDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	CallObjectNS	StraightFlushDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	CallObjectNS	FourOfAKindDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	CallObjectNS	FullHouseDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	CallObjectNS	FlushDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	CallObjectNS	StraightDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	CallObjectNS	ThreeOfAKindDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	CallObjectNS	TwoPairDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	CallObjectNS	PairDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	CallObjectNS	LostDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS

	add	dx, 2
;	CallObjectNS	MaxPayoffDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	mov	cx, INSTRUCTION_WIDTH
	CallObjectNS	InstructionDisplay, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	mov	cx, INSTRUCTION2_WIDTH
	CallObjectNS	Instruction2Display, MSG_RESIZE_AND_VALIDATE, MF_FIXUP_DS
	ret

AdjustDisplay	endp
	




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerAdjustWagerAndCashFromTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow adjusting of wager and cash only between hands.
		This message is sent by the ui triggers so that the
		player cannot change the bet at illegal times.s

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PokerGameClass

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
PokerAdjustWagerAndCashFromTriggers	method dynamic PokerGameClass, 
					MSG_ADJUST_WAGER_AND_CASH_FROM_TRIGGERS
	.enter

	cmp	ds:[di].PGI_status, WAITING_FOR_NEW_GAME
	jne	done

	mov	ax,MSG_ADJUST_WAGER_AND_CASH
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
PokerAdjustWagerAndCashFromTriggers		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerAdjustWager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the bet by the passed amount

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PokerGameClass

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
PokerAdjustWager	method dynamic PokerGameClass, 
						MSG_ADJUST_WAGER_AND_CASH
	uses	cx,dx,bp
	.enter

	;    Reset cash to total money player has
	;

	mov	ax,ds:[di].PGI_wager
	add	ds:[di].PGI_cash.low,ax
	adc	ds:[di].PGI_cash.high,0

	add	cx,ds:[di].PGI_wager
	jcxz	toOne
	tst	cx
	js	toOne
	tst	ds:[di].PGI_cash.high
	jnz	checkMaxBet
	cmp	cx,ds:[di].PGI_cash.low
  ;	jle	checkMaxBet        jfh - 6/28/00
	jbe	checkMaxBet
	mov	cx,ds:[di].PGI_cash.low
checkMaxBet:
	mov	bp,ds:[di].PGI_payoffSchema
	mov	bp,ds:[bp]
	cmp	cx,ds:[bp].PS_maximumBet
  ;	jle	setWager           jfh - 6/28/00
	jbe	setWager
	mov	cx,ds:[bp].PS_maximumBet

setWager:
	mov	ds:[di].PGI_wager,cx
	mov	dx,cx
	clr	cx	
	call	DisplayBet

	;    Reset cash to total - bet
	;

	PointDi2 Game_offset
	mov	dx,ds:[di].PGI_wager
	sub	ds:[di].PGI_cash.low,dx
	sbb	ds:[di].PGI_cash.high,0
	mov	cx,ds:[di].PGI_cash.high
	mov	dx,ds:[di].PGI_cash.low
	call	DisplayCash

	.leave
	ret

toOne:
	mov	cx,1
	jmp	setWager

PokerAdjustWager		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerPositionDeck
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
PokerPositionDeck	proc	near
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
PokerPositionDeck	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PokerGameAddJoker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_ADD_JOKER handler for PokerGameClass
		Adds a joker to the hand object.

CALLED BY:	

PASS:		*ds:si = Game object
		
CHANGES:	a joker is added to the hand object's composite

RETURN:		^lcx:dx = new joker (already added into hand's composite)

DESTROYED:	ax, bx, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:
		Instantiate a new card
		Set its attributes to be a joker
		Push it into the hand's composite

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameAddJoker	method	PokerGameClass, MSG_ADD_JOKER
	;
	;	Instantiate a new card
	;
	mov	di, segment CardClass
	mov	es, di
	mov	di, offset CardClass
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate

	;
	;	Set up some attributes for our new baby
	;
	mov	dh, CR_WILD
	mov	dl, CS_SPADES
	mov	cl, offset CA_RANK
	shl	dh, cl

	mov	cl, offset CA_SUIT
	shl	dl, cl

	ORNF	dl, dh
	clr	dh					;dx is now in the
							;format of CardAttrs
	mov	bp, dx					;bp <- card attrs

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_CARD_SET_ATTRIBUTES
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	Add the joker into the hand's composite
	;
	mov	cx, bx
	mov	dx, si

	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	ax, MSG_DECK_PUSH_CARD
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
PokerGameAddJoker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameUpdateScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_UPDATE_SCORE handler for PokerGameClass
		Had to subclass this baby because poker score is
		a dword, and the score from the cards library is
		but a word. alas...

CALLED BY:	

PASS:		ds:di = PokerGame instance
		*ds:si = PokerGame object
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
PokerGameUpdateScore	method	PokerGameClass, MSG_GAME_UPDATE_SCORE
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
	sub	ds:[di].PGI_cash.low, dx
	sbb	ds:[di].PGI_cash.high, 0	;the high word -= borrow bit
	jmp	setText
addToCash:
	;
	;	The amount is positive, so we add it
	;
	add	ds:[di].PGI_cash.low, dx
	adc	ds:[di].PGI_cash.high, 0	;the high word += carry bit
	jmp	setText
setCash:
	clr	ds:[di].PGI_cash.high
	mov	ds:[di].PGI_cash.low, cx
setText:
	mov	cx, ds:[di].PGI_cash.high
	mov	dx, ds:[di].PGI_cash.low
	call	DisplayCash
	ret
PokerGameUpdateScore	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameUpdateWager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_UPDATE_WAGER handler for PokerGameClass
		Changes the amount of $$ currently being wagered.

CALLED BY:	

PASS:		*ds:si = PokerGame object
		ds:di = PokerGame instance

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
PokerGameUpdateWager	method	PokerGameClass, MSG_UPDATE_WAGER

	jcxz	relativeOrZero

dealWithWagerTrigger:
	mov	di, ds:[si]
	add	di, ds:[di].PokerGame_offset
	mov	ds:[di].PGI_wager, cx
	mov	dx, cx
	clr	cx
	call	DisplayBet

	mov	di, ds:[si]
	add	di, ds:[di].PokerGame_offset
	ret


relativeOrZero:
	tst	dx
	jz	dealWithWagerTrigger	
	mov	cx, ds:[di].PGI_wager		;the score relatively
	add	cx, dx
	jmp	dealWithWagerTrigger
PokerGameUpdateWager	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PokerGameDeal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_DEAL handler for PokerGameClass
		Deals out cards for a new poker game
CALLED BY:	

PASS:		nothing
		
CHANGES:

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		for (n = 1; n <= 7; n++) {
			deal an up card to tableauElement #n
			for (m = n + 1; m<=7; m++) {
				deal a down card to tableauElement #m
			}
		}

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameDeal	method	PokerGameClass, MSG_SOLITAIRE_DEAL
	;
	;	If we're using wild cards, then we want to get the next
	;	card off the top of the hand object; If we're NOT using
	;	wild cards, then we want the next non-wild card off the
	;	top of the hand object.
	;
	;	^lcx:dx <- card
	;
	mov	ax, MSG_GET_NEXT_CARD
	mov	di, ds:[di].PGI_payoffSchema
	mov	di, ds:[di]
	cmp	ds:[di].PS_whatsWild, JOKERS_WILD
	je	deal
	mov	ax, MSG_GET_NEXT_NON_WILD_CARD
deal:
	;
	;	Turn card face up and pass it to deck 1
	;
	push	ax
	call	ObjCallInstanceNoLock
;	CallObjectCXDX	MSG_CARD_TURN_FACE_UP, MF_FIXUP_DS
	CallObject	Deck1, MSG_DECK_GET_DEALT, MF_FIXUP_DS
	pop	ax

	;
	;	Turn card face up and pass it to deck 2
	;
	push	ax
	call	ObjCallInstanceNoLock
;	CallObjectCXDX	MSG_CARD_TURN_FACE_UP, MF_FIXUP_DS
	CallObject	Deck2, MSG_DECK_GET_DEALT, MF_FIXUP_DS
	pop	ax

	;
	;	Turn card face up and pass it to deck 3
	;
	push	ax
	call	ObjCallInstanceNoLock
;	CallObjectCXDX	MSG_CARD_TURN_FACE_UP, MF_FIXUP_DS
	CallObject	Deck3, MSG_DECK_GET_DEALT, MF_FIXUP_DS
	pop	ax

	;
	;	Turn card face up and pass it to deck 4
	;
	push	ax
	call	ObjCallInstanceNoLock
;	CallObjectCXDX	MSG_CARD_TURN_FACE_UP, MF_FIXUP_DS
	CallObject	Deck4, MSG_DECK_GET_DEALT, MF_FIXUP_DS
	pop	ax

	;
	;	Turn card face up and pass it to deck 5
	;
	call	ObjCallInstanceNoLock
;	CallObjectCXDX	MSG_CARD_TURN_FACE_UP, MF_FIXUP_DS
	CallObjectNS	Deck5, MSG_DECK_GET_DEALT, MF_FIXUP_DS

	CallObjectNS	Deck1, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
	CallObjectNS	Deck2, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
	CallObjectNS	Deck3, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
	CallObjectNS	Deck4, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
	CallObjectNS	Deck5, MSG_CARD_FLIP_CARD, MF_FIXUP_DS

	ret
PokerGameDeal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameGetNextCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GET_NEXT_CARD handler for PokerGameClass
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
PokerGameGetNextCard	method	PokerGameClass, MSG_GET_NEXT_CARD
	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	ax, MSG_DECK_POP_CARD
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	GOTO	ObjMessage
PokerGameGetNextCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameGetNextNonWildCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GET_NEXT_NON_WILD_CARD handler for PokerGameClass
		Returns the next non wild card from the game's hand object.

CALLED BY:	

PASS:		*ds:si = game object
		
CHANGES:	the hand's top non-wild card is removed from its composite
		also, if the top card is initially a wild card, it gets
		shuffled down into the deck.

RETURN:		^lcx:dx = nono-wild card from the hand

DESTROYED:	

PSEUDO CODE/STRATEGY:
		if top card isn't wild, then return it.
		else swap the top (wild) card with another and try again

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameGetNextNonWildCard	method	PokerGameClass, MSG_GET_NEXT_NON_WILD_CARD
startLoop:
	;
	;	Get the attributes of the hand's top card
	;
	push	si
	mov	bx, handle MyHand
	mov	si, offset MyHand
	clr	bp					;child #0
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si

	;
	;	See if it's a wild card
	;
	CmpRank	bp, CR_WILD
	jne	getTop

	;
	;	The top card IS wild, so we need to exchange it with
	;	some random other card:
	;
	mov	dl, 30
	mov	ax, MSG_GAME_RANDOM
	call	ObjCallInstanceNoLock			;dx <- random number
	add	dx, 5					;between 5 and 35

	push	si
	mov	bx, handle MyHand
	mov	si, offset MyHand
	clr	cx
	mov	ax, MSG_HAND_EXCHANGE_CHILDREN
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	jmp	startLoop

getTop:
	;
	;	The top card is guaranteed to be non-wild, so
	;	return it
	;
	mov	ax, MSG_GET_NEXT_CARD
	call	ObjCallInstanceNoLock

;Done:
	ret
PokerGameGetNextNonWildCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PokerGameNewGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_NEW_GAME handler for PokerGameClass
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
PokerGameNewGame	method	PokerGameClass, MSG_SOLITAIRE_NEW_GAME

	clr	cx
	clr	dx
	mov	ax, MSG_REGISTER_FLASHER
	call	ObjCallInstanceNoLock

	;
	;	Disable the gadgets that let the user add more $$$, add
	;	wild cards, etc.
	;
	mov	dl, VUM_NOW
	push	si
	CallObjectNS WildInteraction, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	CallObjectNS CashOutTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	CallObjectNS BorrowTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	CallObjectNS FreeMillionTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	pop	si

	;
	;	Return any outstanding cards to the hand object
	;
	mov	ax, MSG_GAME_COLLECT_ALL_CARDS
	call	ObjCallInstanceNoLock

	;
	;	shuffle the cards
	;
	push	si
	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	ax, MSG_HAND_SHUFFLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	;
	;	Queue a method to deal the cards
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SOLITAIRE_DEAL
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	;
	;	Queue a method to prepare the game object for the
	;	second half of the game, wherein the user turns the cards
	;	he doesn't want face down, etc. etc.
	;	
	mov	ax, MSG_PREPARE_TO_HIT
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	ret
PokerGameNewGame	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameCollectAllCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_COLLECT_ALL_CARDS handler for PokerGameClass
		Collects all the cards into the hand object. Since the decks
		in poker never grow or shrink, we subclass this method to
		get rid of the MSG_VIS_INVALIDATE in the superclass, which
		is no longer needed.
		
CALLED BY:	

PASS:		nothing
		
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
PokerGameCollectAllCards method PokerGameClass, MSG_GAME_COLLECT_ALL_CARDS

	mov	cx, handle MyHand
	mov	dx, offset MyHand
	mov	ax, MSG_DECK_GET_RID_OF_CARDS	;tell all decks to return
						;cards to hand
	call	VisSendToChildren
	ret
PokerGameCollectAllCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGamePrepareToHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_PREPARE_TO_HIT handler for PokerGameClass
		Marks the game as being ready for the second phase of play,
		wherein the user discards, etc.

CALLED BY:	

PASS:		ds:di = PokerGame instance
		
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
PokerGamePrepareToHit	method	PokerGameClass, MSG_PREPARE_TO_HIT
	;
	;	Update our status as ready to flip/replace cards
	;
	mov	ds:[di].PGI_status, WAITING_TO_REPLACE_CARDS

	mov	si,offset KeepEmAllText
	call	SetInstructionString

	mov	si, offset DiscardText
	call	SetInstruction2String
	ret
PokerGamePrepareToHit	endm

PokerGameNotifyCardFlipped	method	PokerGameClass, MSG_GAME_NOTIFY_CARD_FLIPPED
	mov	bx, handle Deck1
	mov	si, offset Deck1
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	call	ObjMessage

	test	bp, mask CA_FACE_UP shl offset CK_TOP_CARD
	jz	done

	mov	bx, handle Deck2
	mov	si, offset Deck2
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	call	ObjMessage

	test	bp, mask CA_FACE_UP shl offset CK_TOP_CARD
	jz	done

	mov	bx, handle Deck3
	mov	si, offset Deck3
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	call	ObjMessage

	test	bp, mask CA_FACE_UP shl offset CK_TOP_CARD
	jz	done

	mov	bx, handle Deck4
	mov	si, offset Deck4
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	call	ObjMessage

	test	bp, mask CA_FACE_UP shl offset CK_TOP_CARD
	jz	done

	mov	bx, handle Deck5
	mov	si, offset Deck5
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	ret
PokerGameNotifyCardFlipped	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameHandSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_HAND_SELECTED handler for PokerGameClass

CALLED BY:	User clicking on the hand, DealTrigger

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameHandSelected	method	PokerGameClass, MSG_GAME_HAND_SELECTED
	;
	;	If clicking on the hand is supposed to deal out cards
	;	to any decks with face down cards, then do it
	;
	cmp	ds:[di].PGI_status, WAITING_TO_REPLACE_CARDS
	je	doHit
;Try New Game:
	;
	;	If clicking the hand is supposed to deal out a new game,
	;	then do that.
	;
	cmp	ds:[di].PGI_status, WAITING_FOR_NEW_GAME
	jne	done

	;
	;	If there is no wager, then we can't play a game.
	;
	;	Something should be added here to tel the user why
	;	the game is not dealing. Maybe we should just force
	;	a $1 wager, and go with it
	;
	tst	ds:[di].PGI_wager
	jz	done
;New Game:
	;
	;	Indicate that the game is busy for a moment
	;
	mov	ds:[di].PGI_status, BUSY

	;
	;	Check to see whether we need to clear a hilighted payoff
	;	display from the previous game.
	;
	clr	cx
	clr	dx
	mov	ax, MSG_REGISTER_FLASHER
	call	ObjCallInstanceNoLock

	;
	;	Instigate a new< game
	;
;After Flash Clear:
	mov	ax, MSG_SOLITAIRE_NEW_GAME
	call	ObjCallInstanceNoLock
	jmp	done

	;
	;	Replace any face down cards in the user's hand and
	;	pay him off if need be
	;
doHit:
	mov	ds:[di].PGI_status, BUSY		;indicate busy for now

	;
	;	Deal new cards to the decks with face down cards
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_DISCARDED		
	call	ObjCallInstanceNoLock

	;
	;	Pay the user if she has won anything
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SETTLE_BETS
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	;
	;	fix up anything that needs to be fixed up (in particular,
	;	indicate that we're no longer BUSY
	;
	mov	ax, MSG_TIDY_UP
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	
	;
	;	Enable some UI for the next game.
	;
	mov	dl, VUM_NOW
	CallObjectNS WildInteraction, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	CallObjectNS MoneyTriggers, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	CallObjectNS CashOutTrigger, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	CallObjectNS BorrowTrigger, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	CallObjectNS FreeMillionTrigger, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
done:
	ret
PokerGameHandSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameTidyUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TIDY_UP handler for PokerGameClass
		Sets the game status to WAITING_FOR_NEW_GAME to indicate
		that the current game is over with.

CALLED BY:	

PASS:		ds:di = game instance
		
CHANGES:	ds:[di].PGI_status <- WAITING_FOR_NEW_GAME

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
PokerGameTidyUp	method	PokerGameClass, MSG_TIDY_UP
	uses	cx
	.enter
	mov	ds:[di].PGI_status, WAITING_FOR_NEW_GAME

	tst	ds:[di].PGI_cash.high
	jnz	showDealText
	tst	ds:[di].PGI_cash.low
	jnz	showDealText
	tst	ds:[di].PGI_wager
	jz	bust

	;
	;	The guy has cash, so let's go
	;
showDealText:
	mov	si, offset DealText
showString:
	call	SetInstructionString

	.leave
	ret

bust:
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_BUST
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	mov	si, offset InsertText
	jmp	showString
PokerGameTidyUp	endm

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameReplaceDiscarded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_TEXT_REPLACE_DISCARDED handler for PokerGameClass
		Deals another card to all decks that have face down top cards.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameReplaceDiscarded   method   PokerGameClass, MSG_VIS_TEXT_REPLACE_DISCARDED
	;
	;	If we're using wild cards, then we want to get the next
	;	card off the top of the hand object; If we're NOT using
	;	wild cards, then we want the next non-wild card off the
	;	top of the hand object.
	;
	;	^lcx:dx <- card
	;
	mov	ax, MSG_GET_NEXT_CARD
	mov	di, ds:[di].PGI_payoffSchema
	mov	di, ds:[di]
	cmp	ds:[di].PS_whatsWild, JOKERS_WILD
	je	replace
	mov	ax, MSG_GET_NEXT_NON_WILD_CARD
replace:
	;
	;	See if Deck 1 needs a card
	;
	mov	cx, handle Deck1
	mov	dx, offset Deck1
	push	ax, si
	call	ReplaceCardIfNecessary
	pop	ax, si

	;
	;	See if Deck 2 needs a card
	;
	mov	cx, handle Deck2
	mov	dx, offset Deck2
	push	ax, si
	call	ReplaceCardIfNecessary
	pop	ax, si

	;
	;	See if Deck 3 needs a card
	;
	mov	cx, handle Deck3
	mov	dx, offset Deck3
	push	ax, si
	call	ReplaceCardIfNecessary
	pop	ax, si

	;
	;	See if Deck 4 needs a card
	;
	mov	cx, handle Deck4
	mov	dx, offset Deck4
	push	ax, si
	call	ReplaceCardIfNecessary
	pop	ax, si

	;
	;	See if Deck 5 needs a card
	;
	mov	cx, handle Deck5
	mov	dx, offset Deck5
	call	ReplaceCardIfNecessary

;Done:
	ret
PokerGameReplaceDiscarded	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ReplaceCardIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deals a card to the passed deck iff the deck's top card
		is face down.

CALLED BY:	PokerGameReplaceDiscarded

PASS:		*ds:si = game object
		ax = method number to send game object to get another card

		^lcx:dx = deck

CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceCardIfNecessary	proc	far
	;
	;	Save deck OD
	;
	push	cx, dx

	;
	;	Save method #, game chunk
	;
	push	ax, si

	;
	;	get top card attributes of deck
	;
	mov	bx, cx
	mov	si, dx
	clr	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	test	bp, mask CA_FACE_UP
	jnz	popAndLeave

	;
	;	Restore method #, game chunk
	;
	pop	ax, si

	;
	;	Get a card from the hand
	;
	call	ObjCallInstanceNoLock

	;
	;	turn the card face up
	;
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_CARD_TURN_FACE_UP
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	deal the card to the deck
	pop	bx, si
	mov	ax, MSG_DECK_GET_DEALT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	done
popAndLeave:
	;
	;	clear the stack
	;
	add	sp, 8
done:
	ret
ReplaceCardIfNecessary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameDeckSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_DECK_SELECTED handler for PokerGameClass
		If the game has status WAITING_TO_REPLACE_CARDS, then
		it flips the passed deck's card over. Otherwise the event is
		ignored.

CALLED BY:	

PASS:		ds:[di] = game instance
		^lcx:dx = deck that wants its card flipped

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
PokerGameDeckSelected	method	PokerGameClass, MSG_GAME_DECK_SELECTED
	cmp	ds:[di].PGI_status, WAITING_TO_REPLACE_CARDS
	jne	done

	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_CARD_FLIP_CARD
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	call	PokerGetNumberOfCardFaceDown
	mov	si,offset KeepEmAllText
	tst	cx
	jnz	check1

setInstruction:
	call	SetInstructionString

done:
	ret

check1:
	mov	si,offset DealMe1Text
	cmp	cx,1
	je	setInstruction

	mov	si,offset DealMe2Text
	cmp	cx,2
	je	setInstruction

	mov	si,offset DealMe3Text
	cmp	cx,3
	je	setInstruction

	mov	si,offset DealMe4Text
	cmp	cx,4
	je	setInstruction

	mov	si,offset DealMe5Text
	jmp	setInstruction


PokerGameDeckSelected	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerGetNumberOfCardFaceDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of cards that are face down

CALLED BY:	INTERNAL
		PokerGameDeckSelected

PASS:		
		*ds:si - Game Instance

RETURN:		
		cx - number of card face down in decks

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
	srs	6/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGetNumberOfCardFaceDown		proc	near
	uses	ax,bx,dx,si,di,bp
	.enter

	mov	bx, handle Deck1
	mov	si, offset Deck1
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	call	ObjMessage

	clr	cx
	test	bp, mask CA_FACE_UP shl offset CK_TOP_CARD
	jnz	deck2
	inc	cx

deck2:
	mov	bx, handle Deck2
	mov	si, offset Deck2
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	push	cx
	call	ObjMessage
	pop	cx

	test	bp, mask CA_FACE_UP shl offset CK_TOP_CARD
	jnz	deck3
	inc	cx

deck3:
	mov	bx, handle Deck3
	mov	si, offset Deck3
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	push	cx
	call	ObjMessage
	pop	cx

	test	bp, mask CA_FACE_UP shl offset CK_TOP_CARD
	jnz	deck4
	inc	cx

deck4:
	mov	bx, handle Deck4
	mov	si, offset Deck4
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	push	cx
	call	ObjMessage
	pop	cx

	test	bp, mask CA_FACE_UP shl offset CK_TOP_CARD
	jnz	deck5
	inc	cx

deck5:
	mov	bx, handle Deck5
	mov	si, offset Deck5
	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	mov	di, mask MF_CALL
	push	cx
	call	ObjMessage
	pop	cx


	test	bp, mask CA_FACE_UP shl offset CK_TOP_CARD
	jnz	done
	inc	cx

done:

	.leave
	ret
PokerGetNumberOfCardFaceDown		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PokerGameSettleBets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SETTLE_BETS handler for PokerGameClass
		Checks to see what poker hand the user has been dealt,
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameSettleBets	method	PokerGameClass, MSG_SETTLE_BETS
	;
	;	We need to retrieve the card attibutes.
	;
	;	dl <- 1st CardAttrs
	;	dh <- 2nd CardAttrs
	;	cl <- 3rd CardAttrs
	;	ch <- 4th CardAttrs
	;	bp <- 5th CardAttrs
	;
	push	si
	clr	bp
	CallObjectNS	Deck1, MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
	mov	dx, bp

	clr	bp
	CallObjectNS	Deck2, MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
	mov	bx, bp
	mov	dh, bl

	clr	bp
	CallObjectNS	Deck3, MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
	mov	cx, bp

	clr	bp
	CallObjectNS	Deck4, MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
	mov	bx, bp
	mov	ch, bl

	clr	bp
	CallObjectNS	Deck5, MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
	pop	si

	;
	;	Now we'll take a look at our cards and see what poker hand
	;	we've ended up with
	;
	mov	ax, MSG_ANALYZE_HAND
	call	ObjCallInstanceNoLock

	;
	;	Now that we know what we have, let's figure out what
	;	we've won:
	;
	mov	ax, MSG_CALCULATE_WINNINGS
	call	ObjCallInstanceNoLock
	mov	cx,dx			;won high
	mov	dx,ax			;won low

	tst	cx
	js	lostSomething
	jnz	displayYouWon
	tst	dx
	jz	brokeEven
displayYouWon:
	call	DisplayYouWonInInstruction2

	;    Add winnings to cash
	;

	PointDi2 Game_offset
	add	ds:[di].PGI_cash.low, dx
	adc	ds:[di].PGI_cash.high, cx
	mov	cx,ds:[di].PGI_cash.high
	mov	dx,ds:[di].PGI_cash.low
	call	DisplayCash

done:
	ret

brokeEven:
	mov	si,offset KeptYourBetText
	call	SetInstruction2String
	jmp	done

lostSomething:
	negdw	cxdx
	call	DisplayYouLostInInstruction2

	;    Zero out the wager that was lost and attempt
	;    to bet the same amount again
	;

	PointDi2 Game_offset
	clr	cx
	xchg	cx,ds:[di].PGI_wager
	mov	ax, MSG_ADJUST_WAGER_AND_CASH
	call	ObjCallInstanceNoLock
	jmp	done

PokerGameSettleBets	endm

if	STANDARD_SOUND

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameCalculateWinnings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CALCULATE_WINNINGS handler for PokerGameClass
		Given a game object (to access PGI_wager and PGI_*payoff)
		and a PokerHand, returns the amount of money that should
		be paid to the player.

CALLED BY:	

PASS:		ds:di = PokerGame instance
		*ds:si = PokerGame object
		bp = PokerHand
		
CHANGES:	

RETURN:		dx:ax = $ won. This amount is *not* automatically added to
			    the user's total, so that it can be checked
			    against the maximum payoff.

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameCalculateWinnings  method  PokerGameClass, MSG_CALCULATE_WINNINGS
	uses	cx,bp
	.enter
	mov	di, ds:[di].PGI_payoffSchema
	mov	di, ds:[di]

	;
	;	This method handler is a giant case statement with
	;	some quick math at the end. The case statement figures
	;	out which payoff to pay, and flashes the proper piece
	;	of text on the screen to show the user he has won
	;
	cmp	bp, SHIT_HIGH
	jne	checkLowPair
	clr	ax					;no odds
	mov	cx, handle LostDisplay
	mov	dx, offset LostDisplay
	jmp	checkForBust

checkLowPair:
	cmp	bp, LOW_PAIR
	jne	checkHighPair
	mov	ax,ds:[di].PS_lowPair
	mov	cx, handle LostDisplay
	mov	dx, offset LostDisplay
	jmp	checkForBust


checkHighPair:
	cmp	bp, HIGH_PAIR
	jne	checkTwoPair
	mov	ax,ds:[di].PS_highPair
	mov	cx, handle PairDisplay
	mov	dx, offset PairDisplay
	jmp	endPokerGameCalculateWinnings

checkTwoPair:
	cmp	bp, TWO_PAIR
	jne	checkThreeOfAKind
	mov	ax,ds:[di].PS_twoPair
	mov	cx, handle TwoPairDisplay
	mov	dx, offset TwoPairDisplay
	jmp	endPokerGameCalculateWinnings

checkThreeOfAKind:
	cmp	bp, THREE_OF_A_KIND
	jne	checkStraight
	mov	ax,ds:[di].PS_threeOfAKind
	mov	cx, handle ThreeOfAKindDisplay
	mov	dx, offset ThreeOfAKindDisplay
	jmp	endPokerGameCalculateWinnings

checkStraight:
	cmp	bp, STRAIGHT
	jne	checkFlush
	mov	ax,ds:[di].PS_straight
	mov	cx, handle StraightDisplay
	mov	dx, offset StraightDisplay
	jmp	endPokerGameCalculateWinnings

checkFlush:
	cmp	bp, FLUSH
	jne	checkFullHouse
	mov	ax,ds:[di].PS_flush
	mov	cx, handle FlushDisplay
	mov	dx, offset FlushDisplay
	jmp	endPokerGameCalculateWinnings

checkFullHouse:
	cmp	bp, FULL_HOUSE
	jne	checkFourOfAKind
	mov	ax,ds:[di].PS_fullHouse
	mov	cx, handle FullHouseDisplay
	mov	dx, offset FullHouseDisplay
	jmp	endPokerGameCalculateWinnings

checkFourOfAKind:
	cmp	bp, FOUR_OF_A_KIND
	jne	checkStraightFlush
	mov	ax,ds:[di].PS_fourOfAKind
	mov	cx, handle FourOfAKindDisplay
	mov	dx, offset FourOfAKindDisplay
	jmp	endPokerGameCalculateWinnings

checkStraightFlush:
	cmp	bp, STRAIGHT_FLUSH
	jne	fiveOfAKind
	mov	ax,ds:[di].PS_straightFlush
	mov	cx, handle StraightFlushDisplay
	mov	dx, offset StraightFlushDisplay
	jmp	endPokerGameCalculateWinnings

fiveOfAKind:
	mov	ax,ds:[di].PS_fiveOfAKind
	mov	cx, handle FiveOfAKindDisplay
	mov	dx, offset FiveOfAKindDisplay
	
endPokerGameCalculateWinnings:
	tst	ax				;odds
	jz	checkForBust
	
flashAndPlayTune:
	push	ax				;odds
	mov	ax, MSG_REGISTER_FLASHER
	call	ObjCallInstanceNoLock
	pop	cx				;odds
	jcxz	lost
	;
	;	Multiply the wager by the odds
	;
	PointDi2 Game_offset
	mov	ax, ds:[di].PGI_wager
	clr	dx
	dec	cx				;don't include orig wager
	mul	cx
done:
	.leave
	ret


checkForBust:
	;   We lost. If we are busted then don't play any tunes,
	;   because the busted tune is about to play anyway.
	;

	PointDi2 Game_offset
	tst	ds:[di].PGI_cash.low
	jnz	flashAndPlayTune
	tst	ds:[di].PGI_cash.high
	jnz	flashAndPlayTune

lost:
	;   We lost. Return -wager as the winnings
	;
	
	PointDi2 Game_offset
	mov	ax,ds:[di].PGI_wager
	neg	ax
	cwd
	jmp	done

PokerGameCalculateWinnings	endm
	
endif
if	WAV_SOUND


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameCalculateWinnings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CALCULATE_WINNINGS handler for PokerGameClass
		Given a game object (to access PGI_wager and PGI_*payoff)
		and a PokerHand, returns the amount of money that should
		be paid to the player.

CALLED BY:	

PASS:		ds:di = PokerGame instance
		*ds:si = PokerGame object
		bp = PokerHand
		
CHANGES:	

RETURN:		dx:ax = $ won. This amount is *not* automatically added to
			    the user's total, so that it can be checked
			    against the maximum payoff.

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameCalculateWinnings  method  PokerGameClass, MSG_CALCULATE_WINNINGS
	uses	cx,bp
	.enter
	mov	di, ds:[di].PGI_payoffSchema
	mov	di, ds:[di]

	;
	;	This method handler is a giant case statement with
	;	some quick math at the end. The case statement figures
	;	out which payoff to pay, and flashes the proper piece
	;	of text on the screen to show the user he has won
	;
	cmp	bp, SHIT_HIGH
	jne	checkLowPair
	clr	ax					;no odds
	mov	cx, handle LostDisplay
	mov	dx, offset LostDisplay
	jmp	setSound

checkLowPair:
	cmp	bp, LOW_PAIR
	jne	checkHighPair
	mov	ax,ds:[di].PS_lowPair
	mov	cx, handle LostDisplay
	mov	dx, offset LostDisplay
	jmp	setSound


checkHighPair:
	cmp	bp, HIGH_PAIR
	jne	checkTwoPair
	mov	ax,ds:[di].PS_highPair
	mov	cx, handle PairDisplay
	mov	dx, offset PairDisplay
	jmp	setSound

checkTwoPair:
	cmp	bp, TWO_PAIR
	jne	checkThreeOfAKind
	mov	ax,ds:[di].PS_twoPair
	mov	cx, handle TwoPairDisplay
	mov	dx, offset TwoPairDisplay
	jmp	setSound

checkThreeOfAKind:
	cmp	bp, THREE_OF_A_KIND
	jne	checkStraight
	mov	ax,ds:[di].PS_threeOfAKind
	mov	cx, handle ThreeOfAKindDisplay
	mov	dx, offset ThreeOfAKindDisplay
	jmp	setSound

checkStraight:
	cmp	bp, STRAIGHT
	jne	checkFlush
	mov	ax,ds:[di].PS_straight
	mov	cx, handle StraightDisplay
	mov	dx, offset StraightDisplay
	jmp	setSound

checkFlush:
	cmp	bp, FLUSH
	jne	checkFullHouse
	mov	ax,ds:[di].PS_flush
	mov	cx, handle FlushDisplay
	mov	dx, offset FlushDisplay
	jmp	setSound

checkFullHouse:
	cmp	bp, FULL_HOUSE
	jne	checkFourOfAKind
	mov	ax,ds:[di].PS_fullHouse
	mov	cx, handle FullHouseDisplay
	mov	dx, offset FullHouseDisplay
	jmp	setSound

checkFourOfAKind:
	cmp	bp, FOUR_OF_A_KIND
	jne	checkStraightFlush
	mov	ax,ds:[di].PS_fourOfAKind
	mov	cx, handle FourOfAKindDisplay
	mov	dx, offset FourOfAKindDisplay
	jmp	setSound

checkStraightFlush:
	cmp	bp, STRAIGHT_FLUSH
	jne	fiveOfAKind
	mov	ax,ds:[di].PS_straightFlush
	mov	cx, handle StraightFlushDisplay
	mov	dx, offset StraightFlushDisplay
	jmp	setSound

fiveOfAKind:
	mov	ax,ds:[di].PS_fiveOfAKind
	mov	cx, handle FiveOfAKindDisplay
	mov	dx, offset FiveOfAKindDisplay
	
setSound:
	call	PokerSetFlasherSound

	push	ax				;odds
	mov	ax, MSG_REGISTER_FLASHER
	call	ObjCallInstanceNoLock
	pop	cx				;odds
	jcxz	lost
	;
	;	Multiply the wager by the odds
	;
	PointDi2 Game_offset
	mov	ax, ds:[di].PGI_wager
	clr	dx
	dec	cx				;don't include orig wager
	mul	cx
done:
	.leave
	ret

lost:
	;   We lost. Return -wager as the winnings
	;
	
	PointDi2 Game_offset
	mov	ax,ds:[di].PGI_wager
	neg	ax
	cwd
	jmp	done

PokerGameCalculateWinnings	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerSetFlasherSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Based on the odds set the appropriate sound
		in the flasher

CALLED BY:	INTERNAL
		PokerGameCalculateWinnings

PASS:		^lcx:dx -flasher
		ax - odds

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
	srs	8/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerSetFlasherSound		proc	near
	uses	ax,bx,cx,dx,bp,di
	.enter

	mov	bp,PS_LOST_HAND			;assume
	tst	ax
	jz	setSound

	mov	bp,PS_BROKE_EVEN
	cmp	ax,1
	je	setSound

	mov	bp,PS_BASIC_WIN
	cmp	ax,9
	jle	setSound

	mov	bp,PS_BIG_WIN


setSound:
	CallObjectCXDX	MSG_SET_PLAY_TUNE, MF_FIXUP_DS

	.leave
	ret
PokerSetFlasherSound		endp


endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CheckFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the users cards constitute a flush

CALLED BY:	

PASS:		ds:di = PokerGame instance
		
CHANGES:	

RETURN:		carry set if the 5 cards make a flush

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFlush	proc	far
	class	PokerGameClass
	push	cx
	;
	;	Wild cards are suit wild, so we check the remaining suits
	;	to see if (# of cards in the suit) = 5 - (# wildcards)
	;
	mov	cl, 5
	sub	cl, ds:[di].PGI_handAnalysis.HA_nWildcards

	cmp	ds:[di].PGI_handAnalysis.HA_nSpades, cl
	je	complementCarry			;if the result of the cmp
						;was 'equal', then the carry
						;bit will be clear; we must
						;complement the carry before
						;returning it

	cmp	ds:[di].PGI_handAnalysis.HA_nHearts, cl
	je	complementCarry

	cmp	ds:[di].PGI_handAnalysis.HA_nClubs, cl
	je	complementCarry

	cmp	ds:[di].PGI_handAnalysis.HA_nDiamonds, cl	;carry = 0 iff
								;exist 5 dmnds
complementCarry:
	cmc
	pop	cx
	ret
CheckFlush	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CheckStraight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks to see if the users cards constitute a straight

CALLED BY:	

PASS:		ds:di = PokerGame instance
		
CHANGES:	

RETURN:		carry set if cards are a straight

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckStraight	proc	far
	class	PokerGameClass

	push	cx
	;
	;	First let's ensure that we don't have a natural pair, which
	;	is mutually exclusive with a straight
	;
	mov	cl, ds:[di].PGI_handAnalysis.HA_variety		
	add	cl, ds:[di].PGI_handAnalysis.HA_nWildcards
	cmp	cl, 5					;carry set if cl < 5
	cmc						;carry clear if cl < 5
	jl	done

	;
	;	now let's take the case that aces are high.
	;	we want to find the distance between the high and low
	;	natural cards
	;
	mov	cl, ds:[di].PGI_handAnalysis.HA_highestIfAceHigh
	sub	cl, ds:[di].PGI_handAnalysis.HA_lowestIfAceHigh
	cmp	cl, 5
	jl	done

	;
	;	now we take the case that aces are low
	;
	mov	cl, ds:[di].PGI_handAnalysis.HA_highestIfAceLow
	sub	cl, ds:[di].PGI_handAnalysis.HA_lowestIfAceLow
	cmp	cl, 5
done:
	pop	cx
	ret
CheckStraight	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameDeterminePokerHand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DETERMINE_HAND handler for PokerGameClass
		Returns the best poker hand represented by the dealt cards.
		This method handler uses the game's instance data to
		determine what that hand is (i.e., the cards themselves are
		not polled for information at this point; that must have
		been done previously to set up the instance data).

CALLED BY:	

PASS:		ds:di = poker instance
		
CHANGES:	

RETURN:		bp = PokerHand

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameDetermineHand	method	PokerGameClass, MSG_DETERMINE_HAND
	;
	;	Start at the bottom...
	;
	mov	bp, SHIT_HIGH

	;
	;	The best hand is Five-Of-A-Kind, so we'll check to see
	;	if we have one of those...
	;
	mov	cl, ds:[di].PGI_handAnalysis.HA_mostOfAKind
	add	cl, ds:[di].PGI_handAnalysis.HA_nWildcards
	cmp	cl, 5
	jl	checkStraight
	mov	bp, FIVE_OF_A_KIND
	jmp	done

	;
	;	Check to see if we have some kind of straight. Since
	;	a straight is mutually exclusive with all hands better
 	;	than it (excepting 5-of-a-kind, and with < 3 wildcards),
	;	we can check for it in arbitrary order.
	;
checkStraight:
	call	CheckStraight
	jnc	afterStraightCheck
	
	;
	;	If we have some type of straight, we'll note that here.
	;	We still have to check for the straight flush, though.
	;
	mov	bp, STRAIGHT

afterStraightCheck:
	call	CheckFlush
	jnc	noFlush

	;
	;	If we get here, then we have a flush. If bp is currently
	;	a straight, then we have STRAIGHT_FLUSH. Otherwise we
	;	have a FLUSH. STRAIGHT_FLUSH = STRAIGHT + FLUSH, we can
	;	just add FLUSH to the total and return it. A flush is also
	;	mutually exclusive with all hands better than it in a
	;	deck with less than 3 wildcards, so we can return FLUSH
	;	if it's found.
	;
	add	bp, FLUSH
	jmp	done

	;
	;	If we're here, we have no flush. If we have a straight, then
	;	that's all we're gonna get. Otherwise, we have to continue
	;	the check.
	;
noFlush:
	cmp	bp, STRAIGHT
	je	done

	;
	;	At this point, we've determined that we have neither
	;	5-of-a-kind nor a straight nor a flush; let's check
	;	four of a kind next:
	;
	cmp	cl, 4
	jl	checkThrees
	mov	bp, FOUR_OF_A_KIND
	jmp	done

	;
	;	The next two hands to check are FULL_HOUSE and THREE_OF_A_KIND
	;	Both of these hands have three like cards, inclusive of jokers.
	;
checkThrees:
	cmp	cl, 3
	jl	checkTwoPair

	;
	;	If the variety is more than 2, then the hand is just
	;	THREE_OF_A_KIND. Otherwise the variety = 2, and we have
	;	a FULL_HOUSE. If the variety is less than 2, then
	;	something wrong is happening; something very wrong.
	;
	mov	bp, THREE_OF_A_KIND
	cmp	ds:[di].PGI_handAnalysis.HA_variety, 2
	jg	done
	mov	bp, FULL_HOUSE
	jmp	done

checkTwoPair:
	;
	;	At this point, the variety should be 3, 4, or 5:
	;
	;	variety = 3 implies TWO_PAIR
	;	variety = 4 implies ONE_PAIR
	;	variety = 5 implies SHIT_HIGH
	;
	cmp	ds:[di].PGI_handAnalysis.HA_variety,4
	jge	checkPair
	mov	bp, TWO_PAIR
	jmp	done

checkPair:
	jg	done			;return SHIT_HIGH

	;
	;	At this point, variety = 4 and we have a pair. We must
	;	check it against the minimum allowable pair.
	;
	mov	bp, LOW_PAIR

	mov	di, ds:[di].PGI_payoffSchema
	mov	di, ds:[di]

	mov	dl, ds:[di].PS_minimumPair

	PointDi2 Game_offset
	tst	ds:[di].PGI_handAnalysis.HA_nWildcards
	jz	naturalPair

	cmp	ds:[di].PGI_handAnalysis.HA_highestIfAceHigh, dl
	jl	done
	mov	bp, HIGH_PAIR
	jmp	done

naturalPair:
	cmp	ds:[di].PGI_handAnalysis.HA_rankOfMostOfAKind, dl
	jl	done
	mov	bp, HIGH_PAIR
done:
	;
	;	I wrote this routine before adding the Deuces Wild option;
	;	I used the fact that the user could never have more than
	;	2 wildcards, which is no longer true :(. The following code
	;	was added to ensure that if the user has three or more
	;	wildcards, then we pay off at least 4 of a kind (what could
	;	happen previously is that if the user had 3 wild cards which
	;	combined with the rest of the hand to make a straight or a
	;	flush, he was awarded for this hand, instead of the obvious
	;	four of a kind.
	;
	cmp	bp, FOUR_OF_A_KIND
	jge	theEnd
	cmp	cl, 4
	jl	theEnd
	mov	bp, FOUR_OF_A_KIND
theEnd:
	ret
PokerGameDetermineHand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				AnalyzeHand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the poker object's instance data pertaining to
		n-of-a-kind, etc. given the card attributes of its hand

CALLED BY:	

PASS:		*ds:si = poker object
		ds:di = poker instance
		ch = low byte of CardAttrs for card #1
		cl = low byte of CardAttrs for card #2
		dh = low byte of CardAttrs for card #3
		dl = low byte of CardAttrs for card #4
		bp = CardAttrs for card #5
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameAnalyzeHand	method	PokerGameClass, MSG_ANALYZE_HAND
	;
	;	Clear out the game's instance data
	;
	push	cx, dx, bp
	mov	ax, MSG_CLEAN_ANALYSIS
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp

	call	CountRank				;count card #5
	jc	$10
	call	CountSuit

$10:
	mov	bp, cx
	call	CountRank				;count card #2
	jc	$20
	call	CountSuit

$20:
	mov	cl, ch
	mov	bp, cx
	call	CountRank				;count card #1
	jc	$30
	call	CountSuit

$30:
	mov	bp, dx
	call	CountRank				;count card #4
	jc	$40
	call	CountSuit

$40:
	mov	dl, dh
	mov	bp, dx
	call	CountRank				;count card #3
	jc	$50
	call	CountSuit

$50:
	mov	ax, MSG_CHECK_DISTRIBUTION
	call	ObjCallInstanceNoLock

	mov	ax, MSG_DETERMINE_HAND
	call	ObjCallInstanceNoLock	

	ret
PokerGameAnalyzeHand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CountSuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers a card's suit in the poker instance data
		(i.e., if card is a club, PGI_handAnalysis.HA_nClubs is incremented).

CALLED BY:	

PASS:		ds:di = poker instance
		bp = CardAttrs

CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CountSuit	proc	near
	class	PokerGameClass

	push	bp
	ANDNF	bp, mask CA_SUIT
	cmp	bp, CS_SPADES shl offset CA_SUIT
	jne	checkClubs
	inc	ds:[di].PGI_handAnalysis.HA_nSpades
	jmp	done
checkClubs:
	cmp	bp, CS_CLUBS shl offset CA_SUIT
	jne	checkHearts
	inc	ds:[di].PGI_handAnalysis.HA_nClubs
	jmp	done
checkHearts:
	cmp	bp, CS_HEARTS shl offset CA_SUIT
	jne	mustBeADiamond
	inc	ds:[di].PGI_handAnalysis.HA_nHearts
	jmp	done
mustBeADiamond:
	inc	ds:[di].PGI_handAnalysis.HA_nDiamonds
done:
	pop	bp
	ret
CountSuit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CountRank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	registers a card's rank with the poker object (i.e., if the
		card is a seven, PGI_handAnalysis.HA_nSevens is incremented

CALLED BY:	

PASS:		ds:di = poker instance
		bp = CardAttrs
CHANGES:	

RETURN:		carry set if card is a wild card

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CountRank	proc	near
	class	PokerGameClass

	push	si

	mov	si, ds:[di].PGI_payoffSchema
	mov	si, ds:[si]

	push	dx
	mov	dx, bp
	push	cx
	mov	cl, offset CA_RANK
	ANDNF	dx, mask CA_RANK
	shr	dx, cl
	pop	cx

	cmp	dl, CR_ACE
	jne	checkTwo
	inc	ds:[di].PGI_handAnalysis.HA_nAces
	jmp	checkExtrema
checkTwo:
	cmp	dl, CR_TWO
	jne	checkThree
	cmp	ds:[si].PS_whatsWild, DEUCES_WILD
	je	mustBeAWildcard
	inc	ds:[di].PGI_handAnalysis.HA_nTwos
	jmp	checkExtrema
checkThree:
	cmp	dl, CR_THREE
	jne	checkFour
	inc	ds:[di].PGI_handAnalysis.HA_nThrees
	jmp	checkExtrema
checkFour:
	cmp	dl, CR_FOUR
	jne	checkFive
	inc	ds:[di].PGI_handAnalysis.HA_nFours
	jmp	checkExtrema
checkFive:
	cmp	dl, CR_FIVE
	jne	checkSix
	inc	ds:[di].PGI_handAnalysis.HA_nFives
	jmp	checkExtrema
checkSix:
	cmp	dl, CR_SIX
	jne	checkSeven
	inc	ds:[di].PGI_handAnalysis.HA_nSixes
	jmp	checkExtrema
checkSeven:
	cmp	dl, CR_SEVEN
	jne	checkEight
	inc	ds:[di].PGI_handAnalysis.HA_nSevens
	jmp	checkExtrema
checkEight:
	cmp	dl, CR_EIGHT
	jne	checkNine
	inc	ds:[di].PGI_handAnalysis.HA_nEights
	jmp	checkExtrema
checkNine:
	cmp	dl, CR_NINE
	jne	checkTen
	inc	ds:[di].PGI_handAnalysis.HA_nNines
	jmp	checkExtrema
checkTen:
	cmp	dl, CR_TEN
	jne	checkJack
	inc	ds:[di].PGI_handAnalysis.HA_nTens
	jmp	checkExtrema
checkJack:
	cmp	dl, CR_JACK
	jne	checkQueen
	inc	ds:[di].PGI_handAnalysis.HA_nJacks
	jmp	checkExtrema
checkQueen:
	cmp	dl, CR_QUEEN
	jne	checkKing
	inc	ds:[di].PGI_handAnalysis.HA_nQueens
	jmp	checkExtrema
checkKing:
	cmp	dl, CR_KING
	jne	mustBeAWildcard
	inc	ds:[di].PGI_handAnalysis.HA_nKings
	jmp	checkExtrema
mustBeAWildcard:
	inc	ds:[di].PGI_handAnalysis.HA_nWildcards
	stc
	jmp	done

	;
	;	See whether this has been the highest/lowest card we've
	;	seen yet
	;
checkExtrema:
	cmp	dl, ds:[di].PGI_handAnalysis.HA_lowestIfAceLow
	jge	checkHighIfLow
	mov	ds:[di].PGI_handAnalysis.HA_lowestIfAceLow, dl

checkHighIfLow:
	cmp	dl, ds:[di].PGI_handAnalysis.HA_highestIfAceLow
	jle	checkIfAceHigh
	mov	ds:[di].PGI_handAnalysis.HA_highestIfAceLow, dl

checkIfAceHigh:
	cmp	dl, CR_ACE
	jne	continueCheck
	add	dl, CR_KING
continueCheck:
	cmp	dl, ds:[di].PGI_handAnalysis.HA_lowestIfAceHigh
	jge	checkHighIfHigh
	mov	ds:[di].PGI_handAnalysis.HA_lowestIfAceHigh, dl

checkHighIfHigh:
	cmp	dl, ds:[di].PGI_handAnalysis.HA_highestIfAceHigh
	jle	notWild
	mov	ds:[di].PGI_handAnalysis.HA_highestIfAceHigh, dl
notWild:
	clc
done:
	pop	dx
	pop	si
	ret
CountRank	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameCheckDistribution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CHECK_DISTRIBUTION handler for PokerGameClass
		Fills in the PGI_handAnalysis.HA_mostOfAKind, PGI_handAnalysis.HA_rankOfMostOfAKind, and
		PGI_handAnalysis.HA_variety fields once all the PGI_handAnalysis.HA_nAces etc. fields
		have been filled in

CALLED BY:	

PASS:		ds:di = poker instance
		
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
PokerGameCheckDistribution  method  PokerGameClass, MSG_CHECK_DISTRIBUTION
	;
	;	Make sure our workspace is clear before we do anything...
	;
	clr	ds:[di].PGI_handAnalysis.HA_mostOfAKind
	clr	ds:[di].PGI_handAnalysis.HA_rankOfMostOfAKind
	clr	ds:[di].PGI_handAnalysis.HA_variety

	;
	;	Now we're going to find the most of a kind in our hand,
	;	i.e., the maximum of PGI_handAnalysis.HA_nTwos,
	;	PGI_handAnalysis.HA_nThrees, ..., PGI_handAnalysis.HA_nAces
	;
	clr	ch
	mov	cl, ds:[di].PGI_handAnalysis.HA_nTwos
	mov	dl, CR_TWO
	call	CheckRank

;checkThrees:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nThrees
	mov	dl, CR_THREE
	call	CheckRank

;checkFours:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nFours
	mov	dl, CR_FOUR
	call	CheckRank

;checkFives:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nFives
	mov	dl, CR_FIVE
	call	CheckRank

;checkSixes:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nSixes
	mov	dl, CR_SIX
	call	CheckRank

;checkSevens:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nSevens
	mov	dl, CR_SEVEN
	call	CheckRank

;checkEights:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nEights
	mov	dl, CR_EIGHT
	call	CheckRank

;checkNines:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nNines
	mov	dl, CR_NINE
	call	CheckRank

;checkTens:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nTens
	mov	dl, CR_TEN
	call	CheckRank

;checkJacks:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nJacks
	mov	dl, CR_JACK
	call	CheckRank

;checkQueens:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nQueens
	mov	dl, CR_QUEEN
	call	CheckRank

;checkKings:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nKings
	mov	dl, CR_KING
	call	CheckRank

;checkAces:
	mov	cl, ds:[di].PGI_handAnalysis.HA_nAces
	;
	;	Since aces are always high when talking about pairs, etc.,
	;	we use the high ace ranking here
	;
	mov	dl, CR_ACE + CR_KING
	call	CheckRank
	ret
PokerGameCheckDistribution	endm

CheckRank	proc	near
	class	PokerGameClass
	jcxz	done
	inc	ds:[di].PGI_handAnalysis.HA_variety
	cmp	cl, ds:[di].PGI_handAnalysis.HA_mostOfAKind
	jl	done
	mov	ds:[di].PGI_handAnalysis.HA_mostOfAKind, cl
	mov	ds:[di].PGI_handAnalysis.HA_rankOfMostOfAKind, dl
done:
	ret
CheckRank	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameCleanAnalysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CLEAN_ANALYSIS handler for PokerGameClass
		Resets a bunch of instance data indicating that we're
		about to analyze a new poker hand.

CALLED BY:	

PASS:		ds:di = poker instance
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameCleanAnalysis	method	PokerGameClass, MSG_CLEAN_ANALYSIS
	;
	;	Clear out all the instance data regarding poker hand analysis
	;
	clr	ds:[di].PGI_handAnalysis.HA_nAces
	clr	ds:[di].PGI_handAnalysis.HA_nTwos
	clr	ds:[di].PGI_handAnalysis.HA_nThrees
	clr	ds:[di].PGI_handAnalysis.HA_nFours
	clr	ds:[di].PGI_handAnalysis.HA_nFives
	clr	ds:[di].PGI_handAnalysis.HA_nSixes
	clr	ds:[di].PGI_handAnalysis.HA_nSevens
	clr	ds:[di].PGI_handAnalysis.HA_nEights
	clr	ds:[di].PGI_handAnalysis.HA_nNines
	clr	ds:[di].PGI_handAnalysis.HA_nTens
	clr	ds:[di].PGI_handAnalysis.HA_nJacks
	clr	ds:[di].PGI_handAnalysis.HA_nQueens
	clr	ds:[di].PGI_handAnalysis.HA_nKings
	clr	ds:[di].PGI_handAnalysis.HA_nWildcards
	clr	ds:[di].PGI_handAnalysis.HA_nDiamonds
	clr	ds:[di].PGI_handAnalysis.HA_nHearts
	clr	ds:[di].PGI_handAnalysis.HA_nClubs
	clr	ds:[di].PGI_handAnalysis.HA_nSpades
	clr	ds:[di].PGI_handAnalysis.HA_highestIfAceHigh
	mov	ds:[di].PGI_handAnalysis.HA_lowestIfAceHigh, CR_KING + CR_KING
	clr	ds:[di].PGI_handAnalysis.HA_highestIfAceLow
	mov	ds:[di].PGI_handAnalysis.HA_lowestIfAceLow, CR_KING + CR_KING
	clr	ds:[di].PGI_handAnalysis.HA_mostOfAKind
	clr	ds:[di].PGI_handAnalysis.HA_rankOfMostOfAKind
	clr	ds:[di].PGI_handAnalysis.HA_variety
	ret
PokerGameCleanAnalysis	endm

if	FADING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameSetFadeStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_SET_FADE_STATUS handler for PokerGameClass
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
PokerGameSetFadeStatus	method	PokerGameClass, MSG_SOLITAIRE_SET_FADE_STATUS

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
PokerGameSetFadeStatus	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PokerGameSetWild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SET_WILD handler for PokerGameClass
		Sets up the payoff scheme for a wild/no wild poker game,
		and shows the user the chart of the updated payoffs

CALLED BY:	

PASS:		*ds:si = PokerGame object
		
CHANGES:	clears PGI_flasher

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameSetWild	method	PokerGameClass, MSG_SET_WILD

	CallObject	WildList, MSG_GEN_ITEM_GROUP_GET_SELECTION, MF_CALL
;register:
	push	ax				;push selected booleans
	clr	cx
	clr	dx
	mov	ax, MSG_REGISTER_FLASHER
	call	ObjCallInstanceNoLock
	pop	cx				;pop into cx
	PointDi2 Game_offset
	jcxz	noWild
;wild:
	;
	;	set payoff rates for the wild card game
	;
	mov	ds:[di].PGI_payoffSchema, offset JokersWildPayoffSchema
	cmp	cx, JOKERS_WILD
	je	alterDisplay
	mov	ds:[di].PGI_payoffSchema, offset DeucesWildPayoffSchema

alterDisplay:
	;
	;	Five of a kind is possible with wild cards, so we need to
	;	make sure that the payoff display is visible
	;
	mov	dl, VUM_NOW
	clr	ch
	mov	cl, mask VA_MANAGED or mask VA_DRAWABLE
	CallObject	FiveOfAKindDisplay, MSG_VIS_SET_ATTRS, MF_FIXUP_DS

	;
	;	We don't pay off pairs in the wild card game, so disable
	;	the display
	;
	clr	cl
	mov	ch, mask VA_MANAGED or mask VA_DRAWABLE
	CallObject	PairDisplay, MSG_VIS_SET_ATTRS, MF_FIXUP_DS
	jmp	setDisplay
noWild:
	;
	;	set payoff rates for the non-wild card game
	;
	mov	ds:[di].PGI_payoffSchema, offset NoWildPayoffSchema

	;
	;	Since 5 of a kind is an unattainable hand without
	;	wild cards, we disable the payoff display
	;
	mov	dl, VUM_NOW
	clr	cl
	mov	ch, mask VA_MANAGED or mask VA_DRAWABLE
	CallObject	FiveOfAKindDisplay, MSG_VIS_SET_ATTRS, MF_FIXUP_DS

	;
	;	We do pay jacks-or-better, so  enable the display
	;
	clr	ch
	mov	cl, mask VA_MANAGED or mask VA_DRAWABLE
	CallObject	PairDisplay, MSG_VIS_SET_ATTRS, MF_FIXUP_DS

setDisplay:
	;
	;	Let the chart know that we may have shuffled stuff
	;	around in its composite, so it needs to rethink its
	;	geometry.
	;
	CallObject ThePayoffChart, MSG_VIS_UPDATE_GEOMETRY, MF_FIXUP_DS
	CallObject ThePayoffChart, MSG_VIS_VUP_UPDATE_WIN_GROUP, MF_FIXUP_DS

	;
	;	Now we're going to tell the payoff displays the figure
	;	that they should display as the odds given for that hand.
	;	For example, say that a FullHouse pays $10 to every $1 bet.
	;	We need to set the text of the FullHouseDisplay to say
	;	"Full House pays 10 to 1"
	;

	mov	bp, ds:[si]
	add	bp, ds:[bp].Game_offset
	mov	bp, ds:[bp].PGI_payoffSchema
	mov	bp, ds:[bp]

	mov	dx, 1

	mov	cx, ds:[bp].PS_fiveOfAKind
	CallObjectNS	FiveOfAKindDisplay, MSG_SET_ODDS, MF_FIXUP_DS

	mov	cx, ds:[bp].PS_straightFlush
	CallObjectNS	StraightFlushDisplay, MSG_SET_ODDS, MF_FIXUP_DS

	mov	cx, ds:[bp].PS_fourOfAKind
	CallObjectNS	FourOfAKindDisplay, MSG_SET_ODDS, MF_FIXUP_DS

	mov	cx, ds:[bp].PS_fullHouse
	CallObjectNS	FullHouseDisplay, MSG_SET_ODDS, MF_FIXUP_DS
	
	mov	cx, ds:[bp].PS_flush
	CallObjectNS	FlushDisplay, MSG_SET_ODDS, MF_FIXUP_DS
	
	mov	cx, ds:[bp].PS_straight
	CallObjectNS	StraightDisplay, MSG_SET_ODDS, MF_FIXUP_DS
	
	mov	cx, ds:[bp].PS_threeOfAKind
	CallObjectNS	ThreeOfAKindDisplay, MSG_SET_ODDS, MF_FIXUP_DS

	mov	cx, ds:[bp].PS_twoPair
	CallObjectNS	TwoPairDisplay, MSG_SET_ODDS, MF_FIXUP_DS
	
	mov	cx, ds:[bp].PS_highPair
	CallObjectNS	PairDisplay, MSG_SET_ODDS, MF_FIXUP_DS

	clr	cx
	CallObjectNS	LostDisplay, MSG_SET_ODDS, MF_FIXUP_DS

;done:
	ret
PokerGameSetWild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameRegisterFlasher
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_REGISTER_FLASHER hanbdler for PokerGameClass

CALLED BY:	

PASS:		ds:di = PokerGame instance
		*ds:si = PokerGame object
		^lcx:dx = display to register as hilighted
		
CHANGES:	ds:[di].PGI_flasher <- cx:dx

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameRegisterFlasher  method  PokerGameClass, MSG_REGISTER_FLASHER

	mov	ax,MSG_POKER_STOP_FLASHING
	call	ObjCallInstanceNoLock

	;    If no one new to flash then bail
	;

	PointDi2 Game_offset
	mov	ds:[di].PGI_flasher.handle, cx
	mov	ds:[di].PGI_flasher.offset, dx
	jcxz	done

	CallObjectCXDX	MSG_PLAY_TUNE, MF_FIXUP_DS

	call	PokerStartAnotherFlashTimer

done:
	ret
PokerGameRegisterFlasher	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerFlash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flash the display and start a new one shot timer

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PokerGameClass

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
PokerFlash	method dynamic PokerGameClass, 
						MSG_POKER_FLASH
	uses	cx,dx,bp
	.enter

	mov	bx,ds:[di].PGI_flasher.handle
	tst	bx
	jz	checkTimer
	push	si					;game chunk
	mov	si,ds:[di].PGI_flasher.offset
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_FLASH
	call	ObjMessage
	pop	si					;game chunk

checkTimer:
	;    If timer has already been killed then don't
	;    start a new one
	;

	PointDi2 Game_offset
	tst	ds:[di].PGI_flasherTimer
	jz	done

	call	PokerStartAnotherFlashTimer
done:
	.leave
	ret
PokerFlash		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerStartAnotherFlashTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a new one shot timer

CALLED BY:	PokerFlash
		PokerGameRegisterFlasher

PASS:		
		*ds:si - Game instance

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
	srs	6/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerStartAnotherFlashTimer		proc	near
	uses	ax,bx,cx,dx,di
	class	PokerGameClass
	.enter

	call	PokerStopFlashTimer

	mov	bx, ds:[LMBH_handle]
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx,40
	mov	dx, MSG_POKER_FLASH
	call	TimerStart

	PointDi2 Game_offset
	mov	ds:[di].PGI_flasherTimer, bx
	mov	ds:[di].PGI_flasherTimerID, ax

	.leave
	ret
PokerStartAnotherFlashTimer		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerStopFlashTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop existing one shot timer

CALLED BY:	PokerFlash
		PokerGameRegisterFlasher

PASS:		
		*ds:si - Game instance

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
	srs	6/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerStopFlashTimer		proc	near
	uses	ax,bx,di
	class	PokerGameClass
	.enter

	PointDi2 Game_offset
	clr	bx
	xchg	bx, ds:[di].PGI_flasherTimer
	tst	bx
	jz	done
	clr	ax		
	xchg	ax,ds:[di].PGI_flasherTimerID
	call	TimerStop
	
done:
	.leave
	ret
PokerStopFlashTimer		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerStopFlashing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kill timer and reset flashing display

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PokerGameClass

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
PokerStopFlashing	method dynamic PokerGameClass, 
						MSG_POKER_STOP_FLASHING
	uses	cx,dx,bp
	.enter

	call	PokerStopFlashTimer

	PointDi2 Game_offset
	clr	bx,si
	xchg	bx,ds:[di].PGI_flasher.handle
	xchg	si,ds:[di].PGI_flasher.offset
	tst	bx
	jz	done
	mov	di,mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	ax,MSG_STOP_FLASHING
	call	ObjMessage
done:
	.leave
	ret
PokerStopFlashing		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PokerGameCheckMaximumBet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CHECK_MAXIMUM_BET handler for PokerGameClass

CALLED BY:	

PASS:		dx = amount to check
		
CHANGES:	

RETURN:		dx = the lesser of the passed dx and PGI_maximumBet

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerGameCheckMaximumBet	method	PokerGameClass, MSG_CHECK_MAXIMUM_BET
	mov	di, ds:[di].PGI_payoffSchema
	mov	di, ds:[di]

	cmp	dx, ds:[di].PS_maximumBet
	jbe	done
	mov	dx, ds:[di].PS_maximumBet
done:
	ret
PokerGameCheckMaximumBet	endm


PokerGameCheckFunds	method	PokerGameClass, MSG_CHECK_FUNDS
	tst	ds:[di].PGI_cash.high
	jnz	done

	mov	ax, ds:[di].PGI_cash.low
	sub	ax, ds:[di].PGI_wager
	cmp	dx, ax
	ja	useMax
done:
	ret
useMax:
	mov_trash	dx, ax
	jmp	done
PokerGameCheckFunds	endm

PokerGameSetFontSize	method	PokerGameClass, MSG_GAME_SET_FONT_SIZE
if 0
	mov	dx, VisTextSetPointSizeParams
	sub	sp, dx
	mov	bp, sp				; structure => SS:BP
	clrdw	ss:[bp].VTSPSP_range.VTR_start
	movdw	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSPSP_pointSize.WWF_frac, 0
;	mov	ss:[bp].VTSPSP_pointSize.WWF_int, cx
; Passed font size too big, use FONT_SIZE instead of cx.
	mov	ss:[bp].VTSPSP_pointSize.WWF_int, FONT_SIZE

	CallObjectNS	CashTextDisplay, MSG_VIS_TEXT_SET_POINT_SIZE, MF_STACK
	add	sp, size VisTextSetPointSizeParams
endif
	mov	dx, CHART_HEIGHT
	mov	cx, CHART_WIDTH
	call	AdjustDisplay
	CallObject ThePayoffChart, MSG_VIS_UPDATE_GEOMETRY, MF_FIXUP_DS
	CallObject InstructionDisplay, MSG_VIS_UPDATE_GEOMETRY, MF_FIXUP_DS
	CallObject Instruction2Display, MSG_VIS_UPDATE_GEOMETRY, MF_FIXUP_DS
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	CallObject ThePayoffChart, MSG_VIS_VUP_UPDATE_WIN_GROUP, MF_FIXUP_DS
	ret
PokerGameSetFontSize	endm

PokerGameCashOut	method	PokerGameClass, MSG_SOLITAIRE_CASH_OUT
cashString	local	CURRENCY_SYMBOL_LENGTH+11 dup (char)

	.enter
	push	bp

	clr	cx
	clr	dx
	mov	ax, MSG_REGISTER_FLASHER
	call	ObjCallInstanceNoLock

	push	si
	mov	bx, handle PokerBustedBox
	mov	si, offset PokerBustedBox
	mov	di,mask MF_FIXUP_DS
	mov	cx,IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjMessage
	pop	si


	PointDi2 Game_offset
	mov	ax, 1
	xchg	ax, ds:[di].PGI_markers
	mov	cx, 100
	mul	cx	
	;
	;	ax:dx <- score
	;
	mov	cx, ds:[di].PGI_cash.low
	mov	bx, ds:[di].PGI_cash.high
	add	cx, ds:[di].PGI_wager
	adc	bx,0

	sub	cx, ax
	sbb	bx, dx
	mov	dx, cx

	push	dx
	clr	ds:[di].PGI_wager
	clr	dx
	mov	cx, INITIAL_CASH
	call	StartFresh

	pop	dx

	mov_trash	ax, bx
	push	ax, dx
	tst	ax

	mov	cx,PS_WON_MONEY_ON_CASH_OUT	
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
	mov	cx,PS_LOST_MONEY_ON_CASH_OUT	
	Neg32	dx, ax
moneyChangedHands:
	push	dx
	mov	dx,cx
	call	GameStandardSound
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
		<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION, 0>
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

	;    In the case of a tie, clear the name for the next game.
	;	

	clr	cx
	call	PokerSetHaveLoanName

clearCards:

	;    Clean up the screen
	;

	call	PokerGameClearCardsFromScreen

	pop	bp
	.leave
	ret
winner:
	call	AddHighScore
	jmp	clearCards

loser:
	Neg32	cx, dx

	call	AddLowScore
	jmp	clearCards
PokerGameCashOut	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerGameClearCardsFromScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate all decks.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - Game object
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
PokerGameClearCardsFromScreen		proc	near
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	push	si
	CallObjectNS MyHand, MSG_VIS_INVALIDATE, MF_FIXUP_DS
	CallObjectNS Deck1, MSG_VIS_INVALIDATE, MF_FIXUP_DS
	CallObjectNS Deck2, MSG_VIS_INVALIDATE, MF_FIXUP_DS
	CallObjectNS Deck3, MSG_VIS_INVALIDATE, MF_FIXUP_DS
	CallObjectNS Deck4, MSG_VIS_INVALIDATE, MF_FIXUP_DS
	CallObjectNS Deck5, MSG_VIS_INVALIDATE, MF_FIXUP_DS
	pop	si

	mov	ax,MSG_GAME_COLLECT_ALL_CARDS
	call	ObjCallInstanceNoLock

	.leave
	ret
PokerGameClearCardsFromScreen		endp

StartFresh	proc	near
	class	PokerGameClass
	uses	ax, bx, cx, dx, di, si
	.enter
	mov	ax, MSG_GAME_UPDATE_SCORE
	call	ObjCallInstanceNoLock

	;    If they player doesn't have a wager, give him/her the
	;    default one.
	;

	PointDi2 Game_offset
	tst	ds:[di].PGI_wager
	jnz	dealText
	mov	cx, INITIAL_WAGER
	mov	ax, MSG_ADJUST_WAGER_AND_CASH
	call	ObjCallInstanceNoLock

dealText:
	mov	si, offset DealText
	call	SetInstructionString
	mov	si, offset BlankText
	call	SetInstruction2String

	.leave
	ret
StartFresh	endp


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
	
PokerGameBust	method	PokerGameClass, MSG_BUST
	clr	cx
	clr	dx
	mov	ax, MSG_UPDATE_WAGER
	call	ObjCallInstanceNoLock

	;
	;	Wait until all the cards are done fading
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].PokerGame_offset
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

if	STANDARD_SOUND
	mov	dx,PS_BUST
	call	GameStandardSound
endif

	mov	bx,handle PokerBustedBox
	mov	si,offset PokerBustedBox
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

done:
	ret
PokerGameBust	endm

PokerGameShutDown	method	PokerGameClass, MSG_GAME_SHUTDOWN
	clr	bx
	xchg	bx, ds:[di].PGI_flasherTimer
	tst	bx
	jz	afterTimerStop

	clr	ax		; 0 => continual
	call	TimerStop

afterTimerStop:
	;
	;	Turn off any flashing payoff.
	;
	clr	cx
	clr	dx
	mov	ax, MSG_REGISTER_FLASHER
	call	ObjCallInstanceNoLock

if	STANDARD_SOUND

	; 
	; Turn sound off and free it.
	;
	CallMod	SoundShutOffSounds

endif

	mov	di, segment PokerGameClass
	mov	es, di
	mov	di, offset PokerGameClass
	mov	ax, MSG_GAME_SHUTDOWN
	call	ObjCallSuperNoLock
	ret
PokerGameShutDown	endm


PokerGameBorrowOneHundredDollars	method	PokerGameClass, MSG_BORROW_ONE_HUNDRED_DOLLARS
	uses	cx, dx, bp
	.enter

	push	si					;game chunk

	;    Stop any flashing
	;

	clr	cx
	clr	dx
	mov	ax, MSG_REGISTER_FLASHER
	call	ObjCallInstanceNoLock

	;    Make sure the busted box is no longer on the screen
	;

	mov	bx, handle PokerBustedBox
	mov	si, offset PokerBustedBox
	mov	di,mask MF_FIXUP_DS
	mov	cx,IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjMessage

	;    If we have already asked for a name then don't bother
	;    the guy


	call	PokerCheckHaveLoanName
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

if 	WAV_SOUND
	mov	dx,PS_BORROW_100
endif
	call	GameStandardSound

	mov	cx,TRUE
	call	PokerSetHaveLoanName

	clr	cx
	mov	dx, INITIAL_CASH
	call	StartFresh

	mov	di, ds:[si]
	add	di, ds:[di].PokerGame_offset
	inc	ds:[di].PGI_markers		;increase debt by 1 unit ($100)

	.leave
	ret
PokerGameBorrowOneHundredDollars	endm

PokerGameFreeMillion	method	PokerGameClass, MSG_FREE_MILLION
	push	si
	clr	cx
	clr	dx
	mov	ax, MSG_REGISTER_FLASHER
	call	ObjCallInstanceNoLock
	pop	si

  ;	add	ds:[di].PGI_cash.low, 16959
  ;	adc	ds:[di].PGI_cash.high, 15
	add	ds:[di].PGI_cash.low, 32000
	adc	ds:[di].PGI_cash.high, 0

	clr	cx
	mov	dx, 1
	call	StartFresh
	ret
PokerGameFreeMillion	endm


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

	.leave
	ret
DisplayCash	endp



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
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

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

	.leave
	ret
DisplayBet	endp


SetInstructionString	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter
	sub	sp, 30
	mov	di, sp
	mov	bp, di
	segmov 	es, ss
	mov	bx, handle InstructionDisplay
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
	mov	si, offset InstructionDisplay
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	add	sp, 30
	.leave
	ret
SetInstructionString	endp


SetInstruction2String	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter
	sub	sp, 30
	mov	di, sp
	mov	bp, di
	segmov 	es, ss
	mov	bx, handle Instruction2Display
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
	mov	si, offset Instruction2Display
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	add	sp, 30
	.leave
	ret
SetInstruction2String	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayYouWonInInstruction2
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
DisplayYouWonInInstruction2	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

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

	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	.leave
	ret
DisplayYouWonInInstruction2	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DisplayYouLostInInstruction2
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
DisplayYouLostInInstruction2	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

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

	mov	bx, handle Instruction2Display
	mov	si, offset Instruction2Display
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, sp				;bp <- start of string
	clr	cx				;null terminated
	mov	di, mask MF_CALL		;no MF_FIXUP_DS
	call	ObjMessage
	add	sp, 100

	.leave
	ret
DisplayYouLostInInstruction2	endp



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
	clr	bp			;No extra information
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
	call	PokerSetHaveLoanName
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
	clr	bp			;No extra information
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
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
	call	PokerSetHaveLoanName
	jmp	done

AddLowScore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerGameRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GAME_RESTORE_STATE
PASS:		*ds:si	= PokerGameClass object
		ds:di	= PokerGameClass instance data
		ds:bx	= PokerGameClass object (same as *ds:si)
		es 	= segment of PokerGameClass
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
PokerExtraSaveData	struct
	PESD_cashHigh			word
	PESD_cashLow			word
	PESD_markers			word
	PESD_wager			word
	PESD_status			word
	PESD_payoffSchema		word
PokerExtraSaveData	ends

PokerGameRestoreState	method dynamic PokerGameClass, 
					MSG_GAME_RESTORE_STATE
	uses	ax, bx, cx, es, di, bp
	.enter

	;
	;  Call superclass to alloc the block
	;

	mov	di, offset PokerGameClass
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
	add	dx, size PokerExtraSaveData

	mov	bx, ds:[si]
	add	bx, ds:[bx].PokerGame_offset
	mov	ax, es:[di].PESD_cashHigh
	mov	ds:[bx].PGI_cash.high, ax
	mov	ax, es:[di].PESD_cashLow
	mov	ds:[bx].PGI_cash.low, ax
	mov	ax, es:[di].PESD_markers
	mov	ds:[bx].PGI_markers, ax
	mov	ax, es:[di].PESD_wager
	mov	ds:[bx].PGI_wager, ax
	mov	ax, es:[di].PESD_status
	mov	ds:[bx].PGI_status, al
	mov	ax, es:[di].PESD_payoffSchema
	mov	ds:[bx].PGI_payoffSchema, ax

	mov	bx, cx
	call	MemUnlock

done:
	.leave
	ret
PokerGameRestoreState	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerGameSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GAME_SAVE_STATE
PASS:		*ds:si	= PokerGameClass object
		ds:di	= PokerGameClass instance data
		ds:bx	= PokerGameClass object (same as *ds:si)
		es 	= segment of PokerGameClass
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
PokerGameSaveState	method dynamic PokerGameClass, 
					MSG_GAME_SAVE_STATE
	uses	ax, bx, si, di, es, bp
	.enter

	;
	;  Call superclass to alloc the block
	;

	mov	di, offset PokerGameClass
	call	ObjCallSuperNoLock

	mov	ax, dx
	add	ax, 8 * size word

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
	add	si, ds:[si].PokerGame_offset

	mov	ax, ds:[si].PGI_cash.high
	stosw
	mov	ax, ds:[si].PGI_cash.low
	stosw
	mov	ax, ds:[si].PGI_markers
	stosw
	mov	ax, ds:[si].PGI_wager
	stosw
	mov	al, ds:[si].PGI_status
	stosw
	mov	ax, ds:[si].PGI_payoffSchema
	stosw

	call	MemUnlock

	mov	cx, bx
	mov	dx, di

	.leave
	ret
PokerGameSaveState	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerGameDisplayCash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_DISPLAY_CASH
PASS:		*ds:si	= PokerGameClass object
		ds:di	= PokerGameClass instance data
		ds:bx	= PokerGameClass object (same as *ds:si)
		es 	= segment of PokerGameClass
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
PokerGameDisplayCash	method dynamic PokerGameClass, 
					MSG_DISPLAY_CASH
	uses	ax, cx, dx, bp
	.enter
	mov	cx, ds:[di].PGI_cash.high
	mov	dx, ds:[di].PGI_cash.low

	call	DisplayCash
	.leave
	ret
PokerGameDisplayCash	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerCheckHaveName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return PI_askedForLoanNameThisGame

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PokerInteractionClass

RETURN:		
		cx - PI_askedForLoanNameThisGame
	
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
PokerCheckHaveName	method dynamic PokerInteractionClass, 
						MSG_POKER_CHECK_HAVE_NAME
	.enter

	mov	cx,ds:[di].PI_askedForLoanNameThisGame

	.leave
	ret
PokerCheckHaveName		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerSetHaveName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set PI_beenIntiatedThisGame

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PokerInteractionClass

		cx - PI_beenIntiatedThisGame

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
PokerSetHaveName	method dynamic PokerInteractionClass, 
						MSG_POKER_SET_HAVE_NAME
	.enter

	mov	ds:[di].PI_askedForLoanNameThisGame,cx

	.leave
	ret
PokerSetHaveName		endm









COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerHighScoreGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use the name in the GetLoanText box if there is one. 
		Otherwise call superclass to get name the normal way.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PokerHighScoreClass

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
PokerHighScoreGetName	method dynamic PokerHighScoreClass, 
						MSG_HIGH_SCORE_GET_NAME
	uses	cx
	.enter

	;    If we asked for loan name this game and we were given a name
	;    then use it. Otherwise ask again by calling superclass
	;

	call	PokerCheckHaveLoanName
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
	call	PokerSetHaveLoanName

	.leave
	ret

callSuper:
	mov	di,offset PokerHighScoreClass
	call	ObjCallSuperNoLock

	jmp	clearHaveName


PokerHighScoreGetName		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerCheckHaveLoanName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if we have gotten loan name from the user in 
		this game

CALLED BY:	INTERNAL
		PokerHighScoreGetName

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
PokerCheckHaveLoanName		proc	near
	uses	ax,bx,di,si
	.enter

	mov	bx, handle PokerSummonsGroup
	mov	si, offset PokerSummonsGroup
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_POKER_CHECK_HAVE_NAME
	call	ObjMessage

	.leave
	ret
PokerCheckHaveLoanName		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerSetHaveLoanName
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
PokerSetHaveLoanName		proc	near
	uses	ax,bx,di,si
	.enter

	mov	bx, handle PokerSummonsGroup
	mov	si, offset PokerSummonsGroup
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_POKER_SET_HAVE_NAME
	call	ObjMessage

	.leave
	ret
PokerSetHaveLoanName		endp


CommonCode	ends		;end of CommonCode resource

