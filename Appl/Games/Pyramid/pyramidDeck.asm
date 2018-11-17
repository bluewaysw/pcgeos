COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1991-1995.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Pyramid
FILE:		pyramidDeck.asm

AUTHOR:		Jon Witort, Jan 7, 1991

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_PYRAMID_DECK_NUKE   Nuke this card!

    MTD MSG_PYRAMID_DECK_NOTIFY_SON_IS_DEAD 
				We're being told that one of our children
				is history.

    MTD MSG_PYRAMID_DECK_BECOME_DETECTABLE_IF_SONS_DEAD 
				Recover our detectable state based on dead
				sons.

    MTD MSG_DECK_DRAW_MARKER    Draw the dithered background on which the
				deck sits.

    MTD MSG_DECK_UPDATE_TOPLEFT Don't do anything for MyDiscard deck.

    MTD MSG_DECK_PUSH_CARD      Add a card to this deck.

    MTD MSG_PYRAMID_DECK_RESURRECT_SONS 
				Fixup instance to show that this card has
				two children.

    MTD MSG_PYRAMID_DECK_CARD_FLIP_IF_COVERED 
				If we're not detectable, flip over (face
				down).

    MTD MSG_PYRAMID_DECK_GET_FLAGS 
				Return flags for this deck.

    MTD MSG_PYRAMID_DECK_ENABLE_REDRAW 
				Jump through hoops to make deck redraw.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version

DESCRIPTION:

	this file contains handlers for VisTalon class

	$Id: pyramidDeck.asm,v 1.1 97/04/04 15:14:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckNuke
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke this card!

CALLED BY:	MSG_PYRAMID_DECK_NUKE

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckNuke	method dynamic PyramidDeckClass, MSG_PYRAMID_DECK_NUKE
		.enter
	;
	;  Clear the currently selected card.
	;
		mov	ax, MSG_DECK_CLEAR_INVERTED
		call	ObjCallInstanceNoLock	; ...if it was inverted
	;
	;  Enable the Undo trigger.
	;
		mov	dl, VUM_NOW
		CallObject UndoTrigger, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	;
	;  If we're nuking a card from the Discard deck,
	;  don't count it towards winning.
	;
		PointDi2 Game_offset
		test	ds:[di].PDI_deckFlags, mask PDF_DECK_NOT_IN_TREE
		jnz	nuke
	;
	;  Inc number of nukes, see if they won, etc.
	;
		mov	ax, MSG_PYRAMID_INC_NUKES
		call	VisCallParent
nuke:
	;
	;  Update undo information to say a card was nuked.
	;
		mov	cl, PMT_NUKED_CARDS
		mov	ax, MSG_PYRAMID_SET_LAST_MOVE_TYPE
		call	VisCallParent
	;
	;  Take the card off the deck...
	;
		mov	ax, MSG_DECK_POP_CARD
		call	ObjCallInstanceNoLock
		jc	done
	;
	;  ...and put it in the Discard pile.
	;
		CallObject	MyDiscard, MSG_DECK_PUSH_CARD, MF_FIXUP_DS
	;
	;  Stuff the first optr in the undoInfo, or if that's
	;  already set, the second, with the optr of this deck.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	ax, MSG_PYRAMID_SET_UNDO_OPTR
		call	VisCallParent
	;
	;  Set up the instance data for this deck to indicate
	;  that there's no card in it, and redraw.
	;
		mov	ax, MSG_PYRAMID_DECK_ENABLE_REDRAW
		call	ObjCallInstanceNoLock
	;
	;  Notify left parent (if any) that we're dead.
	;
		push	si
		PointDi2 Deck_offset
		mov	bx, ds:[di].PDI_leftParent.handle
		tst	bx
		jz	afterLeftParent
		mov	si, ds:[di].PDI_leftParent.chunk
		mov	cl, mask PDF_RIGHT_SON_DEAD
		mov	ax, MSG_PYRAMID_DECK_NOTIFY_SON_IS_DEAD
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
afterLeftParent:
	;
	;  Notify right parent (if any) that we're dead.
	;
		pop	si
		PointDi2 Deck_offset
		mov	bx, ds:[di].PDI_rightParent.handle
		tst	bx
		jz	done
		mov	si, ds:[di].PDI_rightParent.chunk
		mov	cl, mask PDF_LEFT_SON_DEAD
		mov	ax, MSG_PYRAMID_DECK_NOTIFY_SON_IS_DEAD
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
PyramidDeckNuke	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckNotifySonIsDead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We're being told that one of our children is history.

CALLED BY:	MSG_NOTIFY_SON_IS_DEAD (via PyramidDeckNuke)

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckNotifySonIsDead	method dynamic PyramidDeckClass, 
					MSG_PYRAMID_DECK_NOTIFY_SON_IS_DEAD
		.enter
	;
	;  Both children dead?  If not => done.
	;
		ornf	ds:[di].PDI_deckFlags, cl
		cmp	ds:[di].PDI_deckFlags, mask PDF_LEFT_SON_DEAD \
					 or mask PDF_RIGHT_SON_DEAD
		jne	done
	;
	;  Make ourselves detectable.
	;
		mov	cx, mask VA_DETECTABLE
		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_SET_ATTRS
		call	ObjCallInstanceNoLock
	;
	;  If cards are being hidden, and we've just become
	;  detectable, flip ourselves over.
	;
		mov	ax, MSG_PYRAMID_QUERY_HIDE
		call	VisCallParent
		jnc	done
		
		mov	ax, MSG_CARD_FLIP_CARD
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
PyramidDeckNotifySonIsDead	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckBecomeDetectableIfSonsDead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recover our detectable state based on dead sons.

CALLED BY:	PyramidGameRestoreState

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckBecomeDetectableIfSonsDead	method dynamic PyramidDeckClass, 
				MSG_PYRAMID_DECK_BECOME_DETECTABLE_IF_SONS_DEAD
		.enter
	;
	;  assume dead
	;
		ornf	ds:[di].PDI_deckFlags, mask PDF_LEFT_SON_DEAD \
					 or mask PDF_RIGHT_SON_DEAD
	;
	;  add our # of children to the passed #
	;
		mov	bx, cx
		mov	ax, MSG_DECK_GET_N_CARDS
		call	ObjCallInstanceNoLock
		
		add	bx, cx
		push	bx
	;
	;  Check left son for pulse.
	;
		mov	di, ds:[si]
		add	di, ds:[di].PyramidDeck_offset
		pushdw	ds:[di].PDI_rightChild
		movdw	bxax, ds:[di].PDI_leftChild
		tst	bx
		jz	checkRight
		
		push	si
		mov_tr	si, ax
		mov	ax, MSG_DECK_GET_N_CARDS
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	si
		
		jcxz	checkRight
		
		mov	di, ds:[si]
		add	di, ds:[di].PyramidDeck_offset
		BitClr	ds:[di].PDI_deckFlags, PDF_LEFT_SON_DEAD
		
checkRight:
		popdw	bxax
		tst	bx
		jz	doCheck
		
		push	si
		mov_tr	si, ax
		mov	ax, MSG_DECK_GET_N_CARDS
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	si
		
		mov	di, ds:[si]
		add	di, ds:[di].PyramidDeck_offset
		
		jcxz	doCheck
		
		BitClr	ds:[di].PDI_deckFlags, PDF_RIGHT_SON_DEAD
doCheck:
	;
	;  Now that we've set our instance properly, see if we
	;  should be detectable.
	;
		test	ds:[di].PDI_deckFlags, mask PDF_LEFT_SON_DEAD
		jz	done
		test	ds:[di].PDI_deckFlags, mask PDF_RIGHT_SON_DEAD
		jz	done
		
		mov	cx, mask VA_DETECTABLE
		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_SET_ATTRS
		call	ObjCallInstanceNoLock
done:
		pop	cx			;cx <- total cards so far
		
		.leave
		ret
PyramidDeckBecomeDetectableIfSonsDead	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckDrawMarker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the dithered background on which the deck sits.

CALLED BY:	MSG_DECK_DRAW_MARKER

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckDrawMarker	method dynamic PyramidDeckClass, 
					MSG_DECK_DRAW_MARKER
		.enter
	;
	;  Only draw the markers for the talon & topOfHand decks.
	;
		test	ds:[di].PDI_deckFlags, mask PDF_DECK_NOT_IN_TREE
		jz	done
		test	ds:[di].PDI_deckFlags, mask PDF_IS_DISCARD
		jnz	done
		
		mov	di, offset PyramidDeckClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
PyramidDeckDrawMarker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckUpdateTopLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't do anything for MyDiscard deck.

CALLED BY:	MSG_DECK_UPDATE_TOPLEFT

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckUpdateTopLeft	method dynamic PyramidDeckClass, 
					MSG_DECK_UPDATE_TOPLEFT
		.enter
		
		test	ds:[di].PDI_deckFlags, mask PDF_IS_DISCARD
		jnz	done

		mov	di, offset PyramidDeckClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
PyramidDeckUpdateTopLeft	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckPushCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a card to this deck.

CALLED BY:	MSG_DECK_PUSH_CARD

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data

RETURN:		nothing
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckPushCard	method dynamic PyramidDeckClass, 
					MSG_DECK_PUSH_CARD
		uses	ax
		.enter
	;
	;  Discard deck?  If not => call super.
	;
		test	ds:[di].PDI_deckFlags, mask PDF_IS_DISCARD
		jz	callSuper
	;
	;  We're pushing a card onto the discard deck:  make the
	;  card so small as to be invisible.
	;
		push	cx, dx, si
		
		movdw	bxsi, cxdx
		mov	cx, -1
		mov	dx, -1
		mov	ax, MSG_VIS_SET_SIZE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		pop	cx, dx, si
callSuper:
		.leave
		mov	di, offset PyramidDeckClass
		GOTO	ObjCallSuperNoLock
PyramidDeckPushCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckResurrectSons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup instance to show that this card has two children.

CALLED BY:	PyramidNewGame, PyramidUndoMove

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data
		cl	= mask of PyramidDeckFlags to clear

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckResurrectSons	method dynamic PyramidDeckClass, 
					MSG_PYRAMID_DECK_RESURRECT_SONS
		uses	ax, cx, dx, bp
		.enter
	;
	;  Make sure they're not trying to clear any bits
	;  besides LEFT_SON_DEAD or RIGHT_SON_DEAD.
	;
EC <		test	cl, not (mask PDF_LEFT_SON_DEAD or mask PDF_RIGHT_SON_DEAD) >
EC <		ERROR_NZ TRYING_TO_SET_INVALID_BITS_IN_RESURRECT_SONS	>

		not	cl
		andnf	ds:[di].PDI_deckFlags, cl
	;
	;  If we're not always detectable, clear the VA_DETECTABLE
	;  bit.
	;
		test	ds:[di].PDI_deckFlags, mask PDF_ALWAYS_DETECTABLE
		jnz	done

		mov	cx, (mask VA_DETECTABLE shl 8)		; clear it
		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_SET_ATTRS
		call	ObjCallInstanceNoLock		
	;
	;  If we're hiding cards, turn top card face down.
	;
		mov	ax, MSG_PYRAMID_QUERY_HIDE
		call	VisCallParent			; carry set = hidden
		jnc	done
		
		mov	ax, MSG_CARD_TURN_FACE_DOWN
		call	VisCallFirstChild

		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
PyramidDeckResurrectSons	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckFlipIfCovered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flip face-up or face-down depending on passed option.

CALLED BY:	PyramidSetHideStatus

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data
		cx	= PyramidGameOptions

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial Version
	stevey	8/95		rewrote & probably mangled horribly

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckFlipIfCovered	method dynamic PyramidDeckClass, 
					MSG_PYRAMID_DECK_CARD_FLIP_IF_COVERED
		uses	cx
		.enter
	;
	;  If we're not-detectable, flip face-down (hide cards)
	;  or face-up (!hide cards).  Detectable cards must be
	;  redrawn because the cards above them covered them if
	;  they flip.  This means we get a flicker when you change
	;  a non-hide option, but I can live with it.
	;
		PointDi2 Vis_offset
		test	ds:[di].VI_attrs, mask VA_DETECTABLE
		jnz	done

		mov	ax, MSG_CARD_TURN_FACE_DOWN
		clr	dx				; not CA_FACE_UP
		test	cx, mask PGO_HIDE_CARDS
		jnz	flip
		mov	ax, MSG_CARD_TURN_FACE_UP
		mov	dx, mask CA_FACE_UP
flip:
	;
	;  To avoid redraws when changing options other than
	;  PGO_HIDE_CARDS, we don't redraw if we're not changing.
	;
		clr	bp				; top card
		push	ax, dx
		mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
		call	ObjCallInstanceNoLock		; bp = CardAttrs
		pop	ax, dx
		jc	exit				; error!

		andnf	bp, mask CA_FACE_UP		; isolate
		cmp	bp, dx
		je	exit				; no change!

		call	VisCallFirstChild
done:
		mov	ax, MSG_DECK_REDRAW
		call	ObjCallInstanceNoLock
exit:
		.leave
		ret
PyramidDeckFlipIfCovered	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return flags for this deck.

CALLED BY:	MSG_PYRAMID_DECK_GET_FLAGS (UTILITY)

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data

RETURN:		cl = PyramidDeckFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckGetFlags	method dynamic PyramidDeckClass, 
					MSG_PYRAMID_DECK_GET_FLAGS

		mov	cl, ds:[di].PDI_deckFlags

		ret
PyramidDeckGetFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidDeckEnableRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Jump through hoops to make deck redraw.

CALLED BY:	INTERNAL (after anyone pops a card from a deck).

PASS:		*ds:si	= PyramidDeckClass object
		ds:di	= PyramidDeckClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidDeckEnableRedraw	method dynamic PyramidDeckClass, 
					MSG_PYRAMID_DECK_ENABLE_REDRAW
		uses	ax, cx, dx, bp
		.enter
	;
	;  I don't know why all this stuff is necessary...
	;
		mov	ax, MSG_CARD_SET_DRAWABLE
		call	VisCallFirstChild
		mov	ax, MSG_CARD_MAXIMIZE
		call	VisCallFirstChild
		mov	ax, MSG_DECK_UPDATE_TOPLEFT
		call	ObjCallInstanceNoLock
		
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock

		.leave
		ret
PyramidDeckEnableRedraw	endm


CommonCode	ends
