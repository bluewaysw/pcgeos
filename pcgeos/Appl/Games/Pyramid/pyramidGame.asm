COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1995.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Pyramid
FILE:		pyramidGame.asm

AUTHOR:		Jon Witort, Jan 7, 1991

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GAME_RESTORE_STATE  Handle restoring from state.

    MTD MSG_GAME_SETUP_GEOMETRY Arranges the game's objects according to
				how big a card is (which should give some
				indication of screen resolution).

    MTD MSG_GAME_SET_UP_SPREADS Intercepted to do nothing.

    INT PyramidPositionDeck     Computes a location from card size units to
				screen units, then moves a deck to that
				point.

    MTD MSG_PYRAMID_NEW_GAME    Starts a new game by disabling UI that is
				to be unaccessible during a game,
				collecting all the cards in the hand,
				redrawing the decks, shuffling, and
				dealing.

    INT MaybeResetHand          Possibly let user cycle through deck.

    MTD MSG_PYRAMID_SEND_NUKE   Nuke a card.

    MTD MSG_PYRAMID_INC_NUKES   Increment the count of nuked cards.

    MTD MSG_PYRAMID_DEC_NUKES   Decrement the nukes (from Undo operation).

    MTD MSG_PYRAMID_QUERY_HIDE  See if cards are being hidden.

    MTD MSG_PYRAMID_UNDO_MOVE   Undo!

    INT UndoCardNukage          Do a reverse- MSG_PYRAMID_DECK_SELECTED
				move.

    INT PutCardBack             Put a card from the discard pile back on
				its deck.

    INT NotifyParentsOfResurrection 
				Have passed deck tell parents of its
				resurrection.

    MTD MSG_PYRAMID_SET_UNDO_OPTR 
				Store away the optr of the last deck.

    MTD MSG_PYRAMID_SET_LAST_MOVE_TYPE 
				Set the PyramidMoveType in instance data.

    INT DecNukesIfDeckInTree    Decrement the nuke-count if they restored a
				tree card.

    MTD MSG_PYRAMID_NUKE_UNDO_OPTRS 
				Clear out PI_undoInfo.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version
	stevey	8/10/91		added Undo stuff

DESCRIPTION:


	$Id: pyramidGame.asm,v 1.1 97/04/04 15:15:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidGameRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle restoring from state.

CALLED BY:	MSG_GAME_RESTORE_STATE

PASS:		*ds:si	= PyramidClass object
		ds:di	= PyramidClass instance data
		^hcx - mem block

RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	Feb 18, 1993 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidGameRestoreState	method dynamic	PyramidClass, MSG_GAME_RESTORE_STATE
	uses	cx, dx, bp
	.enter

	;
	;  call super to do the dirty work
	;

	mov	di, offset PyramidClass
	call	ObjCallSuperNoLock

	;
	; send a MSG_PYRAMID_DECK_BECOME_DETECTABLE_IF_SONS_DEAD. how handy!
	;

	clr	cx, bx			; no children initially; first child

	mov	di, FIRST_TABLEAU_ELEMENT
	pushdw	bxdi
	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	push	di
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	mov	ax, MSG_PYRAMID_DECK_BECOME_DETECTABLE_IF_SONS_DEAD
	call	ObjCompProcessChildren

	;
	;  Set the number of "nukes" = children in MyDiscard
	;

	mov	di, ds:[si]
	add	di, ds:[di].Pyramid_offset

	sub	cl, 28
	neg	cl
	mov	ds:[di].PI_nNukes, cl

	.leave
	ret
PyramidGameRestoreState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PyramidSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arranges the game's objects according to how big a card
		is (which should give some indication of screen resolution).

PASS:		cx = horizontal deck spacing
		dx = vertical deck spacing

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidSetupGeometry	method dynamic	PyramidClass, MSG_GAME_SETUP_GEOMETRY

cardWidth		local	word
cardHeight		local	word

	uses	cx, dx
	.enter

 ;	push	cx				;save horizontal spacing

	mov	di, offset PyramidClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Game_offset
	mov	ax, ds:[di].GI_cardWidth
	mov	ss:[cardWidth], ax
	mov	ax, ds:[di].GI_cardHeight
	mov	ss:[cardHeight], ax
	mov	di, ds:[di].GI_upSpreadY
 ;	pop	ax				;ax <- horizontal spacing
	mov	ax, 10				;ax <- horizontal spacing jfh

	mov	cx, length deckPositionTable
	mov	bx, offset deckPositionTable

	;
	;  Construct the pyramid according to the formula:
	;
	;  x = horizontal spacing +
	;      (nth card in row + (6 - row)/2)(cardWidth + horiz. spacing)
	;
	;  y = (row + 1/2) * vertical spacing
	;
	;  

positionLoop:
	push	ax, bx, cx, di
	mov	si, ax				;si <- spacing
	add	ax, ss:[cardWidth]		;ax <- h spacing + cardWidth
	mov	cl, cs:[bx].DPE_nthCard
	shl	cl
	sub	cl, cs:[bx].DPE_row
	add	cl, 6
	clr	ch
	clr	dx
	mul	cx
	shr	ax
	mov_tr	cx, ax
	add	cx, si				;cx <- x

	mov	al, cs:[bx].DPE_row
	shl	al
	inc	ax
	clr	ah
	mul	di
	shr	ax
	mov_tr	dx, ax				;dx <- y

	mov	si, cs:[bx].DPE_deckChunk
	mov	bx, handle StuffResource

	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	ax, bx, cx, di
	add	bx, size DeckPositionEntry
	loop	positionLoop

doneLoop::
	;
	;  Now place the hand, tophand, and talon. All three have
	;
	;  y = 7 1/2 vertical spacings + 1 cardHeight
	;

	push	ax				;save horizontal spacing
	mov	ax, 15				;7 1/2 * 2
	mul	di
	shr	ax
	mov_tr	dx, ax
	add	dx, ss:[cardHeight]		;dx <- top

	pop	di				;di <- horizontal spacing
	mov	cx, di				;cx <- horizontal spacing
	add	di, ss:[cardWidth]		;di <- horiz. space + width
	add	cx, di
	add	cx, di				;cx <- 2 widths, 3 spacings

	mov	bx, handle MyHand
	mov	si, offset MyHand
	call	PyramidPositionDeck

	add	cx, di				;cx <- 3 widths, 4 spacings
	mov	bx, handle TopOfMyHand
	mov	si, offset TopOfMyHand
	call	PyramidPositionDeck

	add	cx, di				;cx <- 4 widths, 5 spacings
	mov	bx, handle MyTalon
	mov	si, offset MyTalon
	call	PyramidPositionDeck

	.leave
	ret
PyramidSetupGeometry	endm

DeckPositionEntry	struct
	DPE_row		byte
	DPE_nthCard	byte
	DPE_deckChunk	lptr
DeckPositionEntry	ends

deckPositionTable	DeckPositionEntry	\
	<0, 0, offset DeckA1>,
	<1, 0, offset DeckB1>,
	<1, 1, offset DeckB2>,
	<2, 0, offset DeckC1>,
	<2, 1, offset DeckC2>,
	<2, 2, offset DeckC3>,
	<3, 0, offset DeckD1>,
	<3, 1, offset DeckD2>,
	<3, 2, offset DeckD3>,
	<3, 3, offset DeckD4>,
	<4, 0, offset DeckE1>,
	<4, 1, offset DeckE2>,
	<4, 2, offset DeckE3>,
	<4, 3, offset DeckE4>,
	<4, 4, offset DeckE5>,
	<5, 0, offset DeckF1>,
	<5, 1, offset DeckF2>,
	<5, 2, offset DeckF3>,
	<5, 3, offset DeckF4>,
	<5, 4, offset DeckF5>,
	<5, 5, offset DeckF6>,
	<6, 0, offset DeckG1>,
	<6, 1, offset DeckG2>,
	<6, 2, offset DeckG3>,
	<6, 3, offset DeckG4>,
	<6, 4, offset DeckG5>,
	<6, 5, offset DeckG6>,
	<6, 6, offset DeckG7>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PyramidSetUpSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to do nothing.

CALLED BY:	PyramidOpenApplication

PASS:		*ds:si = game instance
		cx, dx = x, y spreads for face upcards

RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	27 nov 1992	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidSetUpSpreads	method dynamic	PyramidClass, MSG_GAME_SET_UP_SPREADS
		.enter

		mov	ds:[di].GI_upSpreadX, cx
		mov	ds:[di].GI_upSpreadY, dx

		.leave
		ret
PyramidSetUpSpreads	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PyramidPositionDeck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes a location from card size units to screen units,
		then moves a deck to that point.

CALLED BY:	PyramidSetupGeometry

PASS:		^lbx:si	= deck to move
		(bp,di) = width, height units
		(cx,dx) = left, top position to move to in units of bp, di
		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidPositionDeck	proc	near
		uses	ax, di
		.enter
	;
	;  Move the deck to the newly calculated location
	;
		mov	ax, MSG_VIS_SET_POSITION
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		
		.leave
		ret
PyramidPositionDeck	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deals out cards for a new klondike game

CALLED BY:	PyramidNewGame

PASS:		nothing
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	for (n = 1; n <= 7; n++) {
		deal an up card to tableauElement #n
		for (m = n + 1; m<=7; m++) {
			deal a down card to tableauElement #m
		}
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
	jon	9/90		took this function out of hand.asm
				and put it into pyramid.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeal	method	PyramidClass, MSG_PYRAMID_DEAL
		.enter
	;
	;  Get the composite locations of the first and last tableau
	;  elements.
	;
		mov	bp, LAST_TABLEAU_ELEMENT
		push	bp
		
		mov	bp, FIRST_TABLEAU_ELEMENT
		push	bp
startLoop:
	;
	;  Get the next card from the Hand.
	;
		CallObject	MyHand, MSG_DECK_POP_CARD, MF_CALL
		jc	endLoop			; if no child to pop, end
	;
	;  Flip it if we're not hiding cards.
	;
		mov	ax, MSG_PYRAMID_QUERY_HIDE
		call	ObjCallInstanceNoLock
		jc	afterTurnUp	; carry set if hiding cards
		
		CallObjectCXDX	MSG_CARD_TURN_FACE_UP, MF_FIXUP_DS
afterTurnUp:
		pop	bp		; bp = # of tE to receive face up card
		push	bp
		push	cx, dx		; save card OD
		mov	dx, bp		; dx <- te #
		clr	cx
	;
	;  Get the OD of the tableau element to receive the next card.
	;
		mov	ax, MSG_VIS_FIND_CHILD
		call	ObjCallInstanceNoLock
	;
	;  Give the card to the tableau element.
	;
		mov	bx, cx		; bx = handle of recip. tableauElement
		mov	bp, dx		; bp = offset of recip. tableauElement
		pop	cx, dx		; restore card OD
		push	si		; save game offset
		mov	si, bp		; si = offset of recip. tableauElement
		mov	ax, MSG_DECK_PUSH_CARD
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		
		pop	si		; restore game offset
		
		pop	cx		; number of guy who got the up card
		pop	dx		; number of last TE
		cmp	cx, dx		; done yet?
		jge	endLoop
		push	dx		; number of last TE
		inc	cx
		push	cx		; number of guy who got the up card
		jmp	startLoop
endLoop:
	;
	;  If we're hiding cards, then all the cards are currently
	;  face-down, so flip the bottom row back over.
	;
		mov	ax, MSG_PYRAMID_QUERY_HIDE
		call	ObjCallInstanceNoLock
		jnc	enableRedeal
		
		CallObjectNS	DeckG1, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
		CallObjectNS	DeckG2, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
		CallObjectNS	DeckG3, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
		CallObjectNS	DeckG4, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
		CallObjectNS	DeckG5, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
		CallObjectNS	DeckG6, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
		CallObjectNS	DeckG7, MSG_CARD_FLIP_CARD, MF_FIXUP_DS
enableRedeal:
	;
	;  Re-enable the Redeal Trigger.
	;
		mov	dl, VUM_NOW
		CallObjectNS RedealTrigger, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
		
		.leave
		ret
PyramidDeal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PyramidNewGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a new game by disabling UI that is to be unaccessible
		during a game, collecting all the cards in the hand, redrawing
		the decks, shuffling, and dealing.

CALLED BY:	PyramidOpenApplication

PASS:		*ds:si	= game object
		ds:di	= PyramidClass instance
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- gives the hand all the cards
	- instructs the hand to shuffle the cards
	- instructs the hand to deal the cards
	- initializes time and score displays

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidNewGame	method	dynamic	PyramidClass, MSG_PYRAMID_NEW_GAME
	.enter

	BitClr	ds:[di].GI_gameAttrs, GA_USE_WIN_BACK

	cmp	ds:[di].PI_nNukes, 28
	jne	afterWinBack

	BitSet	ds:[di].GI_gameAttrs, GA_USE_WIN_BACK

afterWinBack:
	clr	ds:[di].PI_nNukes
	clrdw	ds:[di].PI_undoInfo.PUI_optr1
	clrdw	ds:[di].PI_undoInfo.PUI_optr2
	;
	;  Disable the redeal trigger so that we don't get fucked
	;  by multiple methods.
	;
	mov	dl, VUM_NOW
	CallObject	RedealTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	CallObject	UndoTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	CallObject	SumToInteraction, MSG_GEN_SET_ENABLED, MF_FIXUP_DS

	mov	ax, MSG_PYRAMID_SET_SUM_TO
	call	ObjCallInstanceNoLock

	;
	;  Clear the chosen card fields.
	;
	mov	ax, MSG_PYRAMID_CLEAR_CHOSEN
	call	ObjCallInstanceNoLock

	;
	;  Return any outstanding cards to the hand object.
	;
	mov	ax, MSG_GAME_COLLECT_ALL_CARDS
	call	ObjCallInstanceNoLock

	;
	;  Shuffle the cards.
	;
	push	si
	PointDi2 Game_offset
	mov	bx, ds:[di].GI_hand.handle
	mov	si, ds:[di].GI_hand.chunk
	mov	ax, MSG_HAND_SHUFFLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	;
	;  Queue a message to deal the cards.
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_PYRAMID_DEAL
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	;
	;  Resurrect all the tableau element children.  For
	;  decks other than G1-G7, this will also clear the
	;  VA_DETECTABLE bit.
	;
	;  IMPORTANT NOTE:  If you decide to try to be clever, and
	;  substitute VisSendToChildren for the ObjCompProcessChildren
	;  below, you will wind up with a very boring game.  Don't do
	;  it.  -stevey
	;
	mov	cl, (mask PDF_LEFT_SON_DEAD or mask PDF_RIGHT_SON_DEAD)
	mov	ax, MSG_PYRAMID_DECK_RESURRECT_SONS
	clr	bx			; initial child (first
	push	bx			; child of composite)
	mov	bx, FIRST_TABLEAU_ELEMENT
	push	bx

	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	push	di
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp

	;
	; DO NOT CHANGE THIS TO A GOTO!  We are passing stuff on the stack.
	;
	call	ObjCompProcessChildren	; must use a call (no GOTO) since
					; parameters are passed on the stack
	.leave
	ret
PyramidNewGame	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PyramidHandSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User clicked on the hand.

CALLED BY:	MSG_GAME_HAND_SELECTED, DealTrigger

PASS:		*ds:si = PyramidClass object
		ds:di  = PyramidClass instance

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- clear selected card, if any
	- find out how many cards are left in the Hand:

		none left:  	do nothing (quit)

		one left:	- flip it onto the MyHand deck
				- invalidate the Hand to draw deck marker

		two left:	- flip it onto the MyHand deck

	- push top the Talon card
	- move the last MyHand card onto the Talon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidHandSelected	method	PyramidClass, MSG_GAME_HAND_SELECTED
	.enter
	;
	;  Un-invert selected card, if any.
	;
	mov	ax, MSG_PYRAMID_CLEAR_CHOSEN
	call	ObjCallInstanceNoLock

	;
	;  Set up undo info.
	;
	PointDi2 Game_offset
	mov	ds:[di].PI_undoInfo.PUI_lastMove, PMT_CLICKED_HAND

	mov	dl, VUM_NOW
	CallObject UndoTrigger, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	;
	;  Get the number of cards left.
	;
	CallObject	MyHand, MSG_DECK_GET_N_CARDS, MF_CALL
	cmp	cx, 1				; one card left?
	jl	maybeReset
	jg	doIt

	CallObject	MyHand, MSG_VIS_INVALIDATE, MF_FIXUP_DS
doIt:
	;
	;  Get the next card from the TopOfMyHand and put it on the Talon.
	;
	CallObject	TopOfMyHand, MSG_DECK_POP_CARD, MF_CALL
	jc	next				; carry set => no children

	CallObject	MyTalon, MSG_DECK_PUSH_CARD, MF_FIXUP_DS
next:
	;
	;  Get the next card from MyHand and put it on the TopOfMyHand.
	;
	CallObject	MyHand, MSG_DECK_POP_CARD, MF_CALL
	jc	done
	;
	;  The card from MyHand needs to be turned face-up.
	;
	CallObjectCXDX	MSG_CARD_TURN_FACE_UP, MF_FIXUP_DS
	CallObject	TopOfMyHand, MSG_DECK_PUSH_CARD, MF_FIXUP_DS
done:
	.leave
	ret
maybeReset:
	call	MaybeResetHand
	jmp	done
PyramidHandSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaybeResetHand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Possibly let user cycle through deck.

CALLED BY:	PyramidHandSelected

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/10/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MaybeResetHand	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Check whether the cycle-option is set.
	;
		mov	bx, handle GameOptions
		mov	si, offset GameOptions
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage
		jc	done			; no selections

		test	ax, mask PGO_CYCLE_THROUGH_DECK
		jz	done
	;
	;  For now, just do it.
	;
		mov	cx, handle MyHand
		mov	dx, offset MyHand
		CallObject TopOfMyHand, MSG_DECK_POP_ALL_CARDS, MF_CALL
		CallObject MyTalon, MSG_DECK_POP_ALL_CARDS, MF_CALL
	;
	;  Do contortions to cause empty decks to redraw.
	;
		CallObject TopOfMyHand, MSG_PYRAMID_DECK_ENABLE_REDRAW, MF_CALL
		CallObject MyTalon, MSG_PYRAMID_DECK_ENABLE_REDRAW, MF_CALL

		CallObject MyHand, MSG_VIS_INVALIDATE, MF_CALL
	;
	;  Sadly, the stuff we just did would be very difficult to
	;  undo, so disable the Undo trigger.
	;
		mov	dl, VUM_NOW
		CallObject UndoTrigger, MSG_GEN_SET_NOT_ENABLED, MF_CALL
done:
		.leave
		ret
MaybeResetHand	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PyramidDeckSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User selected a card from a Tableau Element.

CALLED BY:	MSG_GAME_DECK_SELECTED

PASS:		*ds:si	= game object
		ds:[di] = game instance
		^lcx:dx = deck that was selected

RETURN:		nothing

DESTROYED:	ax, bx, di, si

PSEUDO CODE/STRATEGY:

	- if no currently selected card, make this card the chosen
	  card and bail.  Note:  check to see if it meets the sum-to
	  requirements, which it might, if it's a King.

	- if we already have a chosen card, check the newly-selected
	  card against the chosen one and see if they sum.  Nuke if so.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckSelected	method	PyramidClass, MSG_GAME_DECK_SELECTED
		.enter
	;
	;  If we don't currently, have a chosen card make
	;  this one it.
	;
		tst	ds:[di].PI_chosenOne.handle
		jz	newChosen
		
		cmp	cx, ds:[di].PI_chosenOne.handle	; sums to 13 or 14?
		jne	checkSum
		cmp	dx, ds:[di].PI_chosenOne.offset
		LONG	je	clearChosen
checkSum:
	;
	;  Add the value of this card to the current chosen-rank
	;  value, and see if they sum up.
	;
		push	cx, dx, si
		push	ds:[di].PI_chosenRank
		movdw	bxsi, cxdx
		clr	bp
		mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	bx
		andnf	bp, mask CA_RANK
		mov	cl, offset CA_RANK
		shr	bp, cl
		pop	cx, dx, si
		
		PointDi2 Game_offset
		
		add	bp, bx
		cmp	bp, ds:[di].PI_sumTo
		jne	newChosen
	;
	;  They sum up.  Nuke them both.  First clear out the undo
	;  optr(s) from the last move.
	;
		mov	ax, MSG_PYRAMID_NUKE_UNDO_OPTRS
		call	ObjCallInstanceNoLock		
		
		mov	ax, MSG_PYRAMID_SEND_NUKE
		call	ObjCallInstanceNoLock
		
		PointDi2 Game_offset
		clr	cx, dx
		mov	ds:[di].PI_chosenRank, cx
		xchg	cx, ds:[di].PI_chosenOne.handle
		xchg	dx, ds:[di].PI_chosenOne.chunk
		mov	ax, MSG_PYRAMID_SEND_NUKE
		call	ObjCallInstanceNoLock
		
		jmp	done
newChosen:
	;
	;  Invert the card and get its rank.
	;
		push	cx, dx
		CallObjectCXDX	MSG_DECK_INVERT, MF_FIXUP_DS
		clr	bp
		CallObjectCXDX	MSG_DECK_GET_NTH_CARD_ATTRIBUTES, MF_CALL
		
		PointDi2 Game_offset
		
	;
	;  See if it's a king.
	;
		ANDNF	bp, mask CA_RANK
		mov	cl, offset CA_RANK
		shr	bp, cl
		pop	cx, dx
		cmp	bp, ds:[di].PI_sumTo
		jne	notAKing
	;
	;  Yep!  Nuke it.
	;
		mov	ax, MSG_PYRAMID_NUKE_UNDO_OPTRS
		call	ObjCallInstanceNoLock
		
		mov	ax, MSG_PYRAMID_SEND_NUKE
		call	ObjCallInstanceNoLock
		
clearChosen:
		clr	cx, dx, bp
		
notAKing:
	;
	;  Set the chosen-card OD in the Game instance.
	;
		PointDi2 Game_offset
		mov	ds:[di].PI_chosenRank, bp
		xchg	ds:[di].PI_chosenOne.handle, cx
		xchg	ds:[di].PI_chosenOne.chunk, dx
		jcxz	done
		
		CallObjectCXDX	MSG_DECK_CLEAR_INVERTED, MF_FIXUP_DS
done:
		.leave
		ret
PyramidDeckSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PyramidClearChosen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear selected card, if any.

CALLED BY:	MSG_PYRAMID_CLEAR_CHOSEN

PASS:		ds:di	= PyramidClass instance
		*ds:si	= PyramidClass object
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidClearChosen  method  PyramidClass, MSG_PYRAMID_CLEAR_CHOSEN

	clr	cx, dx
	mov	ds:[di].PI_chosenRank, cx
	xchg	ds:[di].PI_chosenOne.handle, cx
	xchg	ds:[di].PI_chosenOne.offset, dx
	jcxz	done
	CallObjectCXDX	MSG_DECK_CLEAR_INVERTED, MF_FIXUP_DS
done:
	ret
PyramidClearChosen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PyramidSetSumTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the sum-to to 13 or 14.

CALLED BY:	MSG_PYRAMID_SET_SUM_TO (GenTrigger in UI)

PASS:		nothing		
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		set GI_dragType, then either enable or disable the
		UserModeList, depending on whether we're setting full
		or outline dragging

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidSetSumTo	method	PyramidClass, MSG_PYRAMID_SET_SUM_TO
		.enter
	;
	;  Get selection & set it.
	;
		push	si
		mov	bx, handle SumToList
		mov	si, offset SumToList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si

		PointDi2 Game_offset
		mov	ds:[di].PI_sumTo, ax

		.leave
		ret
PyramidSetSumTo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidSetGameOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns hiding cards on or off.

CALLED BY:	MSG_PYRAMID_SET_HIDE_STATUS (trigger in UI)  no such msg - jfh
			MSG_PYRAMID_SET_GAME_OPTIONS <- really called from this one
PASS:		nothing
RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

	any way to get TimeGameEntry to send different
	methods depending on its own state?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
	stevey	8/95		mutated horribly, and probably put in bugs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidSetGameOptions	method	PyramidClass, MSG_PYRAMID_SET_GAME_OPTIONS
		.enter
	;
	;  We're toggling card-hiding.
	;
		mov	ax, MSG_PYRAMID_DECK_CARD_FLIP_IF_COVERED
		clr	bx			; initial child (first
		push	bx			; child of composite)
		mov	bx, FIRST_TABLEAU_ELEMENT
		push	bx
		
		mov	bx, offset VI_link	; Pass offset to LinkPart
		push	bx
		clr	bx			; Use standard function
		push	bx
		mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
		push	di
		mov	bx, offset Vis_offset
		mov	di, offset VCI_comp
	;
	; DO NOT CHANGE THIS TO A GOTO!  We are passing stuff on the stack.
	;
		call	ObjCompProcessChildren
	;
	;  Save our new options to the INI file.

		call	GeodeGetProcessHandle
		mov	ax, MSG_META_SAVE_OPTIONS
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
PyramidSetGameOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidSendNuke
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke a card.

CALLED BY:	MSG_PYRAMID_SEND_NUKE

PASS:		*ds:si	= PyramidClass object
		ds:di	= PyramidClass instance data
		^lcx:dx	= card to nuke

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidSendNuke	method dynamic PyramidClass, 
					MSG_PYRAMID_SEND_NUKE
	.enter

	push	cx, dx
	mov	dl, VUM_NOW
	CallObject   SumToInteraction, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS

	pop	bx, si
	mov	ax, MSG_PYRAMID_DECK_NUKE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
PyramidSendNuke	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidIncNukes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment the count of nuked cards.

CALLED BY:	MSG_PYRAMID_INC_NUKES (via MSG_PYRAMID_DECK_NUKE)

PASS:		*ds:si	= PyramidClass object
		ds:di	= PyramidClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidIncNukes	method dynamic PyramidClass, 
					MSG_PYRAMID_INC_NUKES
	.enter

	inc 	ds:[di].PI_nNukes
	cmp	ds:[di].PI_nNukes, NUM_CARDS_NUKED_TO_WIN
	je	winner
done:
	.leave
	ret
winner:
	; Tell the user he/she won.
	;
	clr	ax
	pushdw	axax			; SDOP_helpContext
	pushdw	axax			; SDOP_customTriggers
	pushdw	axax			; SDOP_stringArg2
	pushdw	axax			; SDOP_stringArg1
	mov	bx, handle StringBlock
	mov	ax, offset WinningString
	pushdw	bxax			; SDOP_customString
	mov	ax, CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE or \
		    GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE
	push	ax
	call	UserStandardDialogOptr

	mov	ax, MSG_PYRAMID_NEW_GAME
	call	ObjCallInstanceNoLock
	jmp	done

PyramidIncNukes	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDecNukes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the nukes (from Undo operation).

CALLED BY:	MSG_PYRAMID_DEC_NUKES (PyramidUndoMove)

PASS:		*ds:si	= PyramidClass object
		ds:di	= PyramidClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDecNukes	method dynamic PyramidClass, 	MSG_PYRAMID_DEC_NUKES
		.enter

EC <		tst	ds:[di].PI_nNukes				>
EC <		ERROR_Z NUM_NUKES_DECREMENTED_BELOW_ZERO		>

		dec 	ds:[di].PI_nNukes		

		.leave
		ret
PyramidDecNukes	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidQueryHide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if cards are being hidden.

CALLED BY:	MSG_PYRAMID_QUERY_HIDE

PASS:		*ds:si	= PyramidClass object
		ds:di	= PyramidClass instance data

RETURN:		carry set if cards are being hidden.

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidQueryHide	method dynamic PyramidClass, 
					MSG_PYRAMID_QUERY_HIDE
	uses	cx, dx, bp
	.enter

	CallObject	GameOptions, \
			MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS, MF_CALL
	test	al, mask PGO_HIDE_CARDS			; clears carry
	jnz	yesHide
done:
	.leave
	ret
yesHide:
	stc
	jmp	done

PyramidQueryHide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidUndoMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo!

CALLED BY:	MSG_PYRAMID_UNDO_MOVE

PASS:		*ds:si	= PyramidClass object
		ds:di	= PyramidClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	Do the steps to undo the last move, depending on what it was.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidUndoMove	method dynamic PyramidClass, MSG_PYRAMID_UNDO_MOVE
		.enter
	;
	;  Disable the Undo trigger.
	;
		mov	dl, VUM_NOW
		CallObject UndoTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	;
	;  In any case, clear the chosen card.
	;
		mov	ax, MSG_PYRAMID_CLEAR_CHOSEN
		call	ObjCallInstanceNoLock
	;
	;  Get the type of move to undo.  Currently there are
	;  only two types of move, so I'm not using a table or
	;  anything clever like that.
	;
		PointDi2 Game_offset
		mov	bl, ds:[di].PI_undoInfo.PUI_lastMove

		Assert	etype	bl, PyramidMoveType

		cmp	bl, PMT_NUKED_CARDS
		jne	clickedHand
	;
	;  Need to do the reverse of MSG_PYRAMID_DECK_SELECTED (tricky).
	;
		call	UndoCardNukage
		jmp	done
clickedHand:
	;
	;  We need to do a sort of reverse-MSG_GAME_HAND_SELECTED.
	;  First pop the top card from TopOfMyHand (if any) and
	;  push it onto MyHand.
	;
		CallObject	TopOfMyHand, MSG_DECK_POP_CARD, MF_CALL
		jc	next			; carry set => no children

		CallObjectCXDX	MSG_CARD_TURN_FACE_DOWN, MF_CALL
		CallObject	MyHand, MSG_DECK_PUSH_CARD, MF_CALL
next:
	;
	;  Get the top card from MyTalon and put it on the TopOfMyHand.
	;
		CallObject	MyTalon, MSG_DECK_POP_CARD, MF_CALL
		jc	done

		CallObject	TopOfMyHand, MSG_DECK_PUSH_CARD, MF_CALL
done:
		CallObject	MyHand, MSG_VIS_INVALIDATE, MF_CALL
		CallObject	TopOfMyHand, MSG_VIS_INVALIDATE, MF_CALL
	;
	;  Invalidate the now-empty Talon
	;
		CallObject	MyTalon, MSG_PYRAMID_DECK_ENABLE_REDRAW, MF_CALL

		.leave
		ret
PyramidUndoMove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoCardNukage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a reverse- MSG_PYRAMID_DECK_SELECTED move.

CALLED BY:	PyramidUndoMove

PASS:		*ds:si	= Pyramid object
		ds:di	= Pyramid instance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We need to recover the last 1 or 2 nuked cards.  This
	means:
	
		- put the card(s) back on the correct decks
		- decrement the number of nukes accordingly
		- notify the parents that the sons are resurrected

	If optr2 is nonzero, then there are 2 cards to recover.
	The first popped card goes in optr2.

	If optr2 is zero, then pop one card and stick it in optr1.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UndoCardNukage	proc	near
		class	PyramidClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Get the top card from the MyDiscard deck.
	;
		CallObject MyDiscard, MSG_DECK_POP_CARD, MF_CALL
if 0
	;
	;  This error-checking is a bit over-zealous.
	;
EC <		ERROR_C EXPECTED_CARD_IN_DISCARD_PILE			>
endif
		jnc	gotCard
	;
	;  We have some harmless race-conditions where you can
	;  try to undo a move when there is no move to undo.
	;  We'll just disable the undo trigger.
	;
		mov	dl, VUM_NOW
		CallObject UndoTrigger, MSG_GEN_SET_NOT_ENABLED, MF_CALL
		jmp	done
gotCard:
	;
	;  If optr2 is nonzero, put the popped card in there.
	;
		PointDi2 Game_offset
		push	si
		tst	ds:[di].PI_undoInfo.PUI_optr2.chunk
		jz	putIn1
		movdw	bxsi, ds:[di].PI_undoInfo.PUI_optr2
		jmp	putCardBack
putIn1:
		movdw	bxsi, ds:[di].PI_undoInfo.PUI_optr1
putCardBack:
		call	PutCardBack
		pop	si
	;
	;  Get the next card, if any, and put in optr1.
	;
		PointDi2 Game_offset
		tst	ds:[di].PI_undoInfo.PUI_optr2.chunk
		jz	done2nd
		
		CallObject MyDiscard, MSG_DECK_POP_CARD, MF_CALL
		jc	done2nd

		PointDi2 Game_offset
		push	si
		movdw	bxsi, ds:[di].PI_undoInfo.PUI_optr1
		call	PutCardBack
		pop	si				; *ds:si = Game
done2nd:
	;
	;  Have the two optrs notify their left/right parents,
	;  if any, that their right/left son was resurrected,
	;  respectively.
	;
		PointDi2 Game_offset
		push	si
		movdw	bxsi, ds:[di].PI_undoInfo.PUI_optr1
		call	NotifyParentsOfResurrection
		pop	si				; *ds:si = Game

		PointDi2 Game_offset
		push	si
		movdw	bxsi, ds:[di].PI_undoInfo.PUI_optr2
		call	NotifyParentsOfResurrection
		pop	si				; *ds:si = Game
	;
	;  Undo nukes, one per valid undo optr.  Exception:
	;  if an optr isn't in the tree, don't dec the nukes
	;  for that optr.
	;
		PointDi2 Game_offset
		movdw	cxdx, ds:[di].PI_undoInfo.PUI_optr1
		tst	dx
		jz	noOptr1

		call	DecNukesIfDeckInTree	
noOptr1:
		movdw	cxdx, ds:[di].PI_undoInfo.PUI_optr2
		tst	dx
		jz	doneNukes

		call	DecNukesIfDeckInTree
doneNukes:
	;
	;  Clear out the undo optrs.
	;
		mov	ax, MSG_PYRAMID_NUKE_UNDO_OPTRS
		call	ObjCallInstanceNoLock
done::
		.leave
		ret
UndoCardNukage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutCardBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put a card from the discard pile back on its deck.

CALLED BY:	UndoCardNukage

PASS:		^lbx:si = optr of deck on which to put card.
		^lcx:dx = card

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutCardBack	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter

		Assert	objectOD bxsi, PyramidDeckClass
		Assert	objectOD cxdx, CardClass
	;
	;  First put the card back on the deck, as advertised.
	;
		mov	ax, MSG_DECK_PUSH_CARD
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	;  Make sure the deck & card are drawable, sized correctly,
	;  etc.
	;
		call	MemDerefDS			; *ds:si = deck
		mov	ax, MSG_PYRAMID_DECK_ENABLE_REDRAW
		call	ObjCallInstanceNoLock

		.leave
		ret
PutCardBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyParentsOfResurrection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have passed deck tell parents of its resurrection.

CALLED BY:	UndoCardNukage

PASS:		^lbx:si = deck being resurrected (can be zero)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get left parent
	- tell left parent right son is resurrecting
	- get right parent
	- tell right parent left son is resurrecting

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyParentsOfResurrection	proc	near
		class	PyramidDeckClass
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter

		tst	si
		jz	done
	;
	;  Dereference the passed deck to get at instance.
	;
		call	MemDerefDS
		mov	di, ds:[si]
		add	di, ds:[di].PyramidDeck_offset
	;
	;  Get & save right parent.
	;
		movdw	bxsi, ds:[di].PDI_rightParent
		pushdw	bxsi			; save right parent
	;
	;  Get & notify left parent.
	;
		movdw	bxsi, ds:[di].PDI_leftParent
		tst	si
		jz	doneLeft

		mov	cl, mask PDF_RIGHT_SON_DEAD
		mov	ax, MSG_PYRAMID_DECK_RESURRECT_SONS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
doneLeft:
	;
	;  Restore & notify right parent.
	;
		popdw	bxsi
		tst	si
		jz	done

		mov	cl, mask PDF_LEFT_SON_DEAD
		mov	ax, MSG_PYRAMID_DECK_RESURRECT_SONS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
NotifyParentsOfResurrection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidSetUndoOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store away the optr of the last deck.

CALLED BY:	MSG_PYRAMID_SET_UNDO_OPTR

PASS:		*ds:si	= PyramidClass object
		ds:di	= PyramidClass instance data
		^lcx:dx	= optr of deck to store

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Store the optr in the first slot, unless it's full,
	in which case we store it in the second slot.

	There's a crazy exception that we have to handle -- if
	we're summing to 13, and we just nuked a King, then we
	always store it in the first slot.  Otherwise we can
	have undo information for multiple moves stored, and
	bad things will happen.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidSetUndoOptr	method dynamic PyramidClass, 
					MSG_PYRAMID_SET_UNDO_OPTR
		.enter
	;
	;  Validate input.
	;
		Assert	optr	cxdx

		mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
		call	PyramidIgnoreAcceptInput
	;
	;  If first optr is empty, store there.
	;
		PointDi2 Game_offset
		tst	ds:[di].PI_undoInfo.PUI_optr1.chunk
		jnz	doSecond

		PointDi2 Game_offset
		movdw	ds:[di].PI_undoInfo.PUI_optr1, cxdx
		jmp	done
doSecond:
	;
	;  Otherwise store in 2nd spot.
	;
EC <		tst	ds:[di].PI_undoInfo.PUI_optr2.chunk		>
EC <		ERROR_NZ UNDO_OPTR_UNEXPECTEDLY_NONZERO			>
		movdw	ds:[di].PI_undoInfo.PUI_optr2, cxdx
done:
		mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
		call	PyramidIgnoreAcceptInput

		.leave
		ret
PyramidSetUndoOptr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidSetMoveType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the PyramidMoveType in instance data.

CALLED BY:	MSG_PYRAMID_SET_MOVE_TYPE

PASS:		*ds:si	= PyramidClass object
		ds:di	= PyramidClass instance data
		cl	= PyramidMoveType

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidSetMoveType	method dynamic PyramidClass, 
					MSG_PYRAMID_SET_LAST_MOVE_TYPE
		.enter

		Assert	etype	cl, PyramidMoveType

		mov	ds:[di].PI_undoInfo.PUI_lastMove, cl

		.leave
		ret
PyramidSetMoveType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DecNukesIfDeckInTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the nuke-count if they restored a tree card.

CALLED BY:	UndoCardNukage

PASS:		*ds:si	= Pyramid object
		^lcx:dx	= optr of deck being restored

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DecNukesIfDeckInTree	proc	near
		uses	ax,bx,cx,dx,di,bp
		.enter
	;
	;  See if passed optr is in tree.
	;
		push	si
		movdw	bxsi, cxdx
		mov	ax, MSG_PYRAMID_DECK_GET_FLAGS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si

		test	cl, mask PDF_DECK_NOT_IN_TREE
		jnz	done			; not in tree
	;
	;  Dec nuke for this optr.
	;
		mov	ax, MSG_PYRAMID_DEC_NUKES
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
DecNukesIfDeckInTree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidNukeUndoOptrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear out PI_undoInfo.

CALLED BY:	MSG_PYRAMID_NUKE_UNDO_OPTRS (PyramidDeckNuke)

PASS:		*ds:si	= PyramidClass object
		ds:di	= PyramidClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidNukeUndoOptrs	method dynamic PyramidClass, 
					MSG_PYRAMID_NUKE_UNDO_OPTRS

		clrdw	ds:[di].PI_undoInfo.PUI_optr1
		clrdw	ds:[di].PI_undoInfo.PUI_optr2

		ret
PyramidNukeUndoOptrs	endm


CommonCode	ends

