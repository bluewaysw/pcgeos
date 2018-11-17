COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Cards library
FILE:		hand.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	6/90		Initial Version

DESCRIPTION:
	This file contains handlers for HandClass.

RCS STAMP:
$Id: hand.asm,v 1.1 97/04/04 17:44:24 newdeal Exp $

------------------------------------------------------------------------------@

CardsClassStructures	segment	resource
	HandClass
CardsClassStructures	ends

;---------------------------------------------------

CardsCodeResource segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_DRAW handler for HandClass

CALLED BY:	

PASS:		bp = gstate
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HandDraw	method		HandClass, MSG_VIS_DRAW
	;
	;
	;	First see whether or not we have any cards
	;
	tst	ds:[di].DI_nCards
	jz	drawSelf

	;
	;	If we DO have cards, we want to draw the top one
	;
	push	bp
	mov	ax, MSG_VIS_DRAW
	call	VisCallFirstChild
	pop	bp					;restore gstate
	mov	di,bp					;di <- gstate
	mov	si, PCT_NULL			;clear clip rect
	jmp	endHandDraw
drawSelf:

	;
	;	If we have no cards, we draw our marker
	;
	mov	ax, MSG_DECK_DRAW_MARKER
	call	ObjCallInstanceNoLock
endHandDraw:
	ret
HandDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_START_SELECT handler for HandClass
		Informs the game object that the hand has been selected.

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
HandSelect	method	HandClass, MSG_META_START_SELECT, MSG_META_START_MOVE_COPY
	mov	ax, MSG_GAME_HAND_SELECTED
	call	VisCallParent

	mov	ax, mask MRF_PROCESSED
	ret
HandSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandPushCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_PUSH_CARD handler for HandClass
		Adds card into first position of hand's child tree

CALLED BY:	

PASS:		^lcx:dx = OD of card to push
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		sets card to full size
		turns it face down
		adds it

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandPushCard	method		HandClass, MSG_DECK_PUSH_CARD
	;
	;	Add the card to the hand's composite
	;
	mov	ax, MSG_DECK_ADD_CARD_FIRST
	call	ObjCallInstanceNoLock

	;
	;	Make sure it is full sized
	;
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_CARD_MAXIMIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	Make sure it is face down
	;
	mov	ax, MSG_CARD_TURN_FACE_DOWN
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
HandPushCard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_PTR handler for HandClass
		There should be no action taken when the hand receives
		a MSG_META_PTR, so we must subclass the method with a "null"
		handler.

CALLED BY:	

PASS:		nothing
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandPtr		method		HandClass, MSG_META_PTR
	mov	ax, mask MRF_PROCESSED
	ret
HandPtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_END_SELECT handler for HandClass
		There should be no action taken when the hand receives
		a MSG_META_END_SELECT, so we must subclass the method with a
		"null" handler.

CALLED BY:	

PASS:		nothing
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandEndSelect		method		HandClass, MSG_META_END_SELECT
	mov	ax, mask MRF_PROCESSED
	ret
HandEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandMakeFullHand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_HAND_MAKE_FULL_HAND handler for HandClass
		Creates and adds a full set of 52 cards to the hand's
		composite.

CALLED BY:	PlayingTableInitialize

PASS:		nothing
		
CHANGES:	instantiates a full deck of cards and adds them as children

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		cycles through each rank and suit, instantiating cards and
		pushing them on as children

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandMakeFullHand	method		HandClass, MSG_HAND_MAKE_FULL_HAND
	mov	dh, CR_ACE				;dh <- initial rank
	clr	dl
startLoop:
	
	push	si					;save hand offset
	push	dx					;save card rank & suit

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
	pop	dx					;dx <- card rank & suit
	push	dx
	mov	cl, offset CA_RANK
	shl	dh, cl

	mov	cl, offset CA_SUIT
	shl	dl, cl

	ORNF	dl, dh
	clr	dh					;dx is now in the
							;format of CardAttrs
	mov	bp, dx					;bp <- card attrs

	;
	;  Set the cards attributes
	;
	mov	ax, MSG_CARD_SET_ATTRIBUTES
	call	ObjCallInstanceNoLock

	pop	bp					;restore card rank&suit
	mov	cx, ds:[LMBH_handle]
	pop	dx					;restore hand offset
	xchg	dx, si					;dx <- card offset,
							;si <- hand offset
	push	bp					;save card rank & suit
	mov	ax, MSG_DECK_PUSH_CARD
	call	ObjCallInstanceNoLock

	pop	dx					;restore card rank&suit

	cmp	dh, CR_KING				;is it a king?
	je	incrementSuit				;if so, time for a
							;new suit

	inc	dh					;otherwise, inc rank
	jmp	startLoop

incrementSuit:

	cmp	dl, CS_SPADES				;is it a spade?
	je	endLoop					;if so, we're done

	inc	dl					;otherwise inc rank
	mov	dh, CR_ACE				;start over with ace
	jmp	startLoop

endLoop:
	ret
HandMakeFullHand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandShuffle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_HAND_SHUFFLE handler for HandClass
		Shuffles the hand's cards

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		for (i = 0; i <= number of children; i++){
			j = random number between 0 and # of children
			swap attributes of card i and card j
		}

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandShuffle	method	HandClass, MSG_HAND_SHUFFLE
	mov	dx, ds:[di].DI_nCards
	dec	dx					;dx <- # of last card
	clr	bp					;bp <- # of first child
	
startLoop:
	cmp	bp, dx					;done yet?
	jg	endLoop

	push	dx					;save # of children
	push	bp					;save index

	mov	ax, MSG_GAME_RANDOM
	call	VisCallParent

	pop	cx					;cx <- index
	push	cx
	mov	ax, MSG_HAND_EXCHANGE_CHILDREN		;swap attributes of
	call	ObjCallInstanceNoLock			;card cx and card dx

	pop	bp					;restore index
	inc	bp					;inc index
	pop	dx					;restore # of children
	jmp	startLoop
endLoop:
	ret
HandShuffle	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandExchangeChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_HAND_EXCHANGE_CHILDREN handler for HandClass

CALLED BY:	HandShuffle

PASS:		cx, dx = children to swap attributes
		
CHANGES:	card A gets card B's attributes, and card B gets
		card A's attributes

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		find card B
		get card B's attributes
		find card A
		get card A's attributes
		set card A's attributes
		set card B's attributes

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandExchangeChildren	method	HandClass, MSG_HAND_EXCHANGE_CHILDREN
	push	cx					;save #A
	clr	cx					;cx:dx = #B
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock

	pop	di					;get #A off stack
	push	cx,dx					;save OD of B
	push	di					;put #A back on stack

	CallObjectCXDX	MSG_CARD_GET_ATTRIBUTES, MF_CALL	;get B's attributes

	pop	dx					;restore #A
	push	bp					;save B's attrs
	clr	cx					;cx:dx = #A
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock

	push	cx,dx					;save OD of A
	CallObjectCXDX	MSG_CARD_GET_ATTRIBUTES, MF_CALL	;bp <- A's attrs
	pop	cx,dx					;restore OD of A
	pop	ax					;restore B's attrs
	push	bp					;save A's attrs
	mov	bp, ax					;bp <- B's attrs
	CallObjectCXDX	MSG_CARD_SET_ATTRIBUTES, MF_FIXUP_DS	;A <- B's attrs
	pop	bp					;restore A's attrs
	pop	cx,dx					;restore B's OD
	CallObjectCXDX	MSG_CARD_SET_ATTRIBUTES, MF_FIXUP_DS	;B <- A's attrs
	ret
HandExchangeChildren	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HandGetRidOfCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_GET_RID_OF_CARDS handler for HandClass
		This method is basically here so that decks can give all
		their cards to the hand object; since the hand already
		has its own cards, there is nothing to do.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandGetRidOfCards	method	HandClass, MSG_DECK_GET_RID_OF_CARDS
	ret
HandGetRidOfCards	endm

CardsCodeResource ends
