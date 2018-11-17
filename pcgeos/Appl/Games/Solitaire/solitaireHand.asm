COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Solitaire
FILE:		hand.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	6/90		Initial Version

DESCRIPTION:
	this file contains handlers for SolitaireHandClass

RCS STAMP:
$Id: solitaireHand.asm,v 1.1 97/04/04 15:46:54 newdeal Exp $

------------------------------------------------------------------------------@


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

SolitaireHandClass	class	HandClass
MSG_PLAY_TO_TALON		method
;
;	Give a number of cards to the talon, warning it beforehand so that
;	it can get ready to receive the cards.
;
;	PASS:		cx = # of cards to give to the talon
;			bp = method number to use when pushing cards to
;			    the talon:	MSG_DECK_PUSH_CARD for fading effects
;					MSG_DECK_PUSH_CARD_NO_EFFECTS otherwise
;
;	RETURN:		dx = # of cards played to the talon

MSG_TURN_OR_FLUSH		method
;
;	This method tells the hand to play cards to the talon if the hand
;	has cards; if the hand doesn't have cards, it instructs the talon
;	to flush its cards back to the hand.
;
;	PASS:		nothing
;
;	RETURN:		nothing

	KHI_talon	optr			;OD of the talon
SolitaireHandClass	endc

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

if FULL_EXECUTE_IN_PLACE
SolitaireClassStructures	segment	resource
else
idata	segment
endif

;;Class definition is stored in the application's idata resource here.

	SolitaireHandClass

;initialized variables
if FULL_EXECUTE_IN_PLACE
SolitaireClassStructures	ends
else
idata	ends
endif


;------------------------------------------------------------------------------
;		Code for SolitaireHandClass
;------------------------------------------------------------------------------
CommonCode	segment	resource	;start of code resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandTurnOrFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TURN_OR_FLUSH handler for HandClass
		Instructs the Hand object to either play a number of cards
		to the talon, or, in the case that the Hand has no cards,
		to flush the talon's cards back to the Hand.

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
SolitaireHandTurnOrFlush	method	SolitaireHandClass, MSG_TURN_OR_FLUSH
	;
	;	If either the Hand or Talon have fading cards, we'll
	;	disregard this method.
	;
	clr	bp
	mov	ax, MSG_CARD_GET_ATTRIBUTES		;check hand's top card
	call	VisCallFirstChild			;for fading
	test	bp, mask CA_FADING
	jnz	queueIt

	PointDi2 Deck_offset
	push	si
	mov	bx, ds:[di].KHI_talon.handle
	mov	si, ds:[di].KHI_talon.offset
	clr	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES	;check talon's top
	mov	di, mask MF_FIXUP_DS or mask MF_CALL	;card for fading
	call	ObjMessage		
	pop	si

	jc	doIt
	
	test	bp, mask CA_FADING
	jz	doIt
queueIt:
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_TURN_OR_FLUSH
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE
	call	ObjMessage
	jmp	endHandTurnOrFlush
doIt:
	;
	;	Get the number of cards we would like to play
	;
	mov	ax, MSG_SOLITAIRE_GET_DRAW_NUMBER
	call	VisCallParent

	PointDi2 Deck_offset
	tst	ds:[di].DI_nCards		;see if we have any cards to
	jz	flushTalon			;give to the talon
	jmp	pop2Talon

flushTalon:					;we have no cards, so we want
						;to get all of the cards from
						;the talon back into the hand

	;;first we want to see if flushing the talon would actually do anything
	;;i.e., is the # of cards in the talon <= the number we draw each time?
	push	si

	mov	si, ds:[di].KHI_talon.offset
	mov	si, ds:[si]
	add	si, ds:[si].Deck_offset

	cmp	cx, ds:[si].DI_nCards		;cmp # draw cards vs.
						;# talon cards
	pop	si
	jl	doFlush

	;
	;	If we get here, then the talon doesn't have enough cards to
	;	make flushing and re-turning them a good idea (i.e. after
	;	flushing and selecting the hand again, the talon's top card
	;	will be the same as it was before). Therefore, we'll just
	;	show the user all the cards in the talon by sending the
	;	talon a MSG_UNCOVER.
	;
	PointDi2 Deck_offset
	push	si
	mov	bx, ds:[di].KHI_talon.handle
	mov	si, ds:[di].KHI_talon.offset
	mov	ax, MSG_TALON_UNCOVER
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	jmp	endHandTurnOrFlush

doFlush:
	;
	;	See if flushing is OK
	;
	mov	ax, MSG_SOLITAIRE_QUERY_FLUSH_OK
	call	VisCallParent
	jnc	endHandTurnOrFlush

	;
	;	Flushing IS ok, so we do it.
	;
	PointDi2 Deck_offset
	push	si
	mov	bx, ds:[di].KHI_talon.handle
	mov	si, ds:[di].KHI_talon.offset
	mov	ax, MSG_TALON_FLUSH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	;
	;	Redraw the hand's top card to indicate that the
	;	hand now has some cards
	;
	mov	ax, MSG_CARD_FADE_REDRAW		;fade redraw self for visual
	call	VisCallFirstChild		;effect indicating we have some
	jmp	endHandTurnOrFlush		;cards now.

pop2Talon:
	;
	;	If we get here, then we have cards to play to the
	;	talon, so we do it.
	;

        PLAY_SOUND SS_CARD_MOVE_FLIP	; "flip over one or more cards to the talon" sound

	mov	bp, MSG_DECK_PUSH_CARD
	mov	ax, MSG_PLAY_TO_TALON	
	call	ObjCallInstanceNoLock
	push	dx				;push # cards played

	;
	;	Get our receipt...
	;
	PointDi2 Deck_offset
	mov	cx, ds:[di].KHI_talon.handle
	mov	dx, ds:[di].KHI_talon.offset
	mov	ds:[di].DI_lastRecipient.handle, cx
	mov	ds:[di].DI_lastRecipient.chunk, dx
	pop	ds:[di].DI_lastGift

	;
	;	Tell the game object that the last move was from
	;	the hand.
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GAME_SET_DONOR
	call	VisCallParent
endHandTurnOrFlush:
	;
	;	Indicate that the mouse event that spawned this method
	;	has been taken care of
	;
	mov	ax, mask MRF_PROCESSED
	ret
SolitaireHandTurnOrFlush	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandPlayToTalon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_PLAY_TO_TALON handler for HandClass

CALLED BY:	HandTurnOrFlush, ??TalonUncover??

PASS:		cx = number of cards to play to talon
		bp = method number to use when pushing cards to the talon
		     (e.g., MSG_DECK_PUSH_CARD or MSG_DECK_PUSH_CARD_NO_EFFECTS)
CHANGES:	

RETURN:		dx = # cards actually played

DESTROYED:	ax, bx, dx, bp, di

PSEUDO CODE/STRATEGY:
		send MSG_PRE_PUSH to talon
		loop cx times, popping a card to the talon each time

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireHandPlayToTalon	method	SolitaireHandClass, MSG_PLAY_TO_TALON
	;
	;	Inform the talon that we're about to give it some
	;	cards, so it should make the necessary arrangements
	;
	push	si
	mov	bx, ds:[di].KHI_talon.handle
	mov	si, ds:[di].KHI_talon.offset
	mov	ax, MSG_TALON_PRE_PUSH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	;
	;	the following loop pops a number of cards from the hand
	;	to the talon, and redraws the hand if it runs out of cards.
	;	At the end of the loop, dx = # of cards transfered.
	;
initLoop::
	clr	dx				;# cards pushed so far
startLoop:
	cmp	dx, cx				;# done = # to do?
	push	cx,dx
	jge	endLoop				;jump if done

	push	bp
	mov	ax, MSG_DECK_POP_CARD
	call	ObjCallInstanceNoLock
	pop	bp
	jc	endLoop				;if no child to pop, end

	PointDi2 Deck_offset
	mov	ax, ds:[di].DI_nCards		;see if the card we just
						;popped was our last one. If
	tst	ax				;it was, we want to redraw
	jnz	skipRedraw

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_DECK_REDRAW
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

skipRedraw:					;^lcx:dx = OD of popped card
	PointDi2 Deck_offset
	push	si
	mov	bx, ds:[di].KHI_talon.handle
	mov	si, ds:[di].KHI_talon.offset
	mov	ax, bp
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	pop	cx,dx
	inc	dx
	jmp	startLoop

endLoop:

	;;tell talon that we're done pushing
	;;the following call, when sent via the queue, causes a problem
	;;in that if the user clicks twice on the hand too quickly, the talon
	;;stretches its bounds out very far.  I'm going to take the call off
	;;the queue and see what happens...
	;;
	;;When taken off the queue, when the last cards from the hand are dealt
	;;the extra area is invalidated before the new cards are drawn.
	;;
	PointDi2 Deck_offset
	push	si
	mov	bx, ds:[di].KHI_talon.handle
	mov	si, ds:[di].KHI_talon.offset
	mov	ax, MSG_DECK_UPDATE_TOPLEFT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_TALON_POST_PUSH
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	si
	pop	cx,dx
endHandPlayToTalon::
	ret
SolitaireHandPlayToTalon		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireHandReturnCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_RETURN_CARDS handler for SolitaireHandClass
		Returns all of the hand's cards to the talon; since the
		talon only wants a few cards at a time, this method
		had to be subclassed. We know to return all the cards, since
		the only time the hand gets cards from the talon is during
		a flush.

CALLED BY:	

PASS:		nothing
		
CHANGES:	all the hand's cards are given to the talon

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireHandReturnCards	method	SolitaireHandClass, MSG_DECK_RETURN_CARDS
	;
	;	Wait until we're done fading to return the cards (otherwise
	;	funny things can happen on screen).
	;
	clr	bp
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	VisCallFirstChild
	test	bp, mask CA_FADING
	jz	getDrawNumber

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_DECK_RETURN_CARDS
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	done

getDrawNumber:
	mov	ax, MSG_SOLITAIRE_GET_DRAW_NUMBER	;cx <- draw number
	call	VisCallParent

doAFlip:
	mov	bp, MSG_DECK_PUSH_CARD_NO_EFFECTS
	mov	ax, MSG_PLAY_TO_TALON
	call	ObjCallInstanceNoLock

	PointDi2 Deck_offset
	tst	ds:[di].DI_nCards
	jnz	doAFlip

endHandReturnCards::
	mov	cx, -1
	mov	ax, MSG_SOLITAIRE_UPDATE_TIMES_THRU
	call	VisCallParent
done:
	ret
SolitaireHandReturnCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireHandRetrieveCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_RETRIEVE_CARDS handler for SolitaireHandClass
		We subclass this method to make sure that the hand is
		redrawn if it is empty before the transaction and has
		cards afterwards.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		push # cards
		call superclass
		see if pushed # == 0
		if so, redraw top card

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireHandRetrieveCards	method	SolitaireHandClass,MSG_DECK_RETRIEVE_CARDS
	;
	;	We need to see whether or not a redraw is in order for the
	;	hand (in the case that the hand has no cards before the
	;	return
	;
	push	ds:[di].DI_nCards
	mov	di, offset SolitaireHandClass
	call	ObjCallSuperNoLock

	pop	cx
	tst	cx
	jnz	done
	mov	ax, MSG_CARD_FADE_REDRAW
	call	VisCallFirstChild
done:
	ret
SolitaireHandRetrieveCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireHandRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_REDRAW handler for SolitaireHandClass
		Restricts drawing of the hand if flushing is illegal, so that
		the hand will not show up if it has no cards and flushing
		is illegal.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireHandRedraw	method	SolitaireHandClass, MSG_DECK_REDRAW
	;
	;	If we have cards, then we want to draw.
	;
	tst	ds:[di].DI_nCards
	jnz	callSuper

	;
	;	If we have no cards, we only want to draw if the talon
	;	can be flushed
	;
	mov	ax, MSG_SOLITAIRE_QUERY_FLUSH_OK
	call	VisCallParent
	jc	callSuper

	;
	;	If we're not drawing, we want to clear this space out.
	;
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	jmp	endSolitaireHandRedraw

callSuper:
	mov	di, segment SolitaireHandClass
	mov	es, di
	mov	di, offset SolitaireHandClass
	mov	ax, MSG_DECK_REDRAW
	call	ObjCallSuperNoLock
endSolitaireHandRedraw:
	ret
SolitaireHandRedraw	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireHandDrawMarker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DRAW_MARKER handler for SolitaireHandClass
		If the talon cannot be flushed, then we don't want to draw
		the hand's marker.

CALLED BY:	

PASS:		bp = gstate
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
none

KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireHandDrawMarker	method	SolitaireHandClass, MSG_DECK_DRAW_MARKER
	;
	;	If it's not OK to flush the talon, then we don't want to draw
	;
	mov	ax, MSG_SOLITAIRE_QUERY_FLUSH_OK
	call	VisCallParent
	jnc	endSolitaireHandDrawMarker

	mov	di, segment SolitaireHandClass
	mov	es, di
	mov	di, offset SolitaireHandClass
	mov	ax, MSG_DECK_DRAW_MARKER
	call	ObjCallSuperNoLock
endSolitaireHandDrawMarker:
	ret
SolitaireHandDrawMarker	endm
CommonCode	ends		;end of CommonCode resource
