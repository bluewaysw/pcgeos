COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Solitaire
FILE:		talon.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	6/90		Initial Version

DESCRIPTION:
	this file contains handlers for VisTalon class

RCS STAMP:
$Id: solitaireTalon.asm,v 1.1 97/04/04 15:46:55 newdeal Exp $

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

SolitaireTalonClass	class	DeckClass
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;				METHODS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
MSG_TALON_FLUSH		method
;
;	This method causes the talon to return all of its cards to the
;	hand object. Cards are returned so that their order in the talon
;	and in the hand is reversed (as if you turned the entire talon over).
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_TALON_POST_PUSH	method
;
;	Fixes up the visual state of affairs after the hand
;	delivers cards to the talon. In particular, if the hand
;	runs out of cards, there may be some cards underneath the
;	ones just pushed to the talon that should be hidden.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_TALON_PRE_PUSH		method
;
;	This method informs the talon that it is about to get a sequence
;	of cards, and that it should prepare accordingly. This basically
;	consists in setting all current children to not drawable and storing
;	the talon's current vis bounds for future clean up refernce (see
;	MSG_TALON_POST_PUSH).
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_TALON_UNCOVER		method
;
;	This method should be passed to the talon whenever the last
;	of its visible cards is removed from its composite; this
;	method will redisplay a certain number of cards that have
;	been "uncovered".
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_TALON_CHECK_UNCOVER	method
;
;	Checks to see whether or not a MSG_TALON_UNCOVER is needed for the
;	talon, and issues one if so.
;
;	PASS:		nothing
;
;	RETURN:		nothing

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;				INSTANCE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
TI_hand		optr				;ptr to the hand object

SolitaireTalonClass	endc

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

;Class definition is stored in the application's idata resource here.

	SolitaireTalonClass

;initialized variables
if FULL_EXECUTE_IN_PLACE
SolitaireClassStructures	ends
else
idata	ends
endif


;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends

;------------------------------------------------------------------------------
;		Code for MathProcessClass
;------------------------------------------------------------------------------
CommonCode	segment	resource	;start of code resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TalonCheckUncover
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TALON_CHECK_UNCOVER handler for SolitaireTalonClass
		This method is called after a card has been popped from the
		talon to see if we have to uncover some cards (i.e. see if
		all the drawable cards are gone; if so, then we need to
		display some more.)

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		if it's the case that the talon has cards, but no DRAWable
		cards, then issue a MSG_TALON_UNCOVER to self.

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonCheckUncover	method	SolitaireTalonClass, MSG_TALON_CHECK_UNCOVER
	RESET	ds:[di].DI_deckAttrs, DA_JUST_UNCOVERED

	tst	ds:[di].DI_nCards			;if the talon has no
	jz	endTalonCheckUncover			;cards, then don't
							;uncover

	mov	ax, MSG_CARD_QUERY_DRAWABLE		;is the top card
	call	VisCallFirstChild			;drawable? If so,
	jc	endTalonCheckUncover			;don't uncover

	;
	;	At this point we've found that we have cards, and
	;	that none of them are drawable.  We need to uncover.
	;
	mov	ax, MSG_TALON_UNCOVER			
	call	ObjCallInstanceNoLock
endTalonCheckUncover:
	ret
TalonCheckUncover	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TalonRepairSuccessfulTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_REPAIR_SUCCESSFUL_TRANSFER handler for SolitaireTalonClass
		Check to see if we need to uncover before calling the
		superclass.

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
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonRepairSuccessfulTransfer	method	SolitaireTalonClass, MSG_DECK_REPAIR_SUCCESSFUL_TRANSFER
	;
	;	Uncover if necessary
	;
	clr	ds:[di].DI_nDragCards
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_TALON_CHECK_UNCOVER
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	Call the superclass
	;
	mov	di, segment SolitaireTalonClass
	mov	es, di
	mov	di, offset SolitaireTalonClass
	mov	ax, MSG_DECK_REPAIR_SUCCESSFUL_TRANSFER
	call	ObjCallSuperNoLock				;call super

	ret
TalonRepairSuccessfulTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				TalonFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TALON_FLUSH handler for SolitaireTalonClass
		Returns all cards to the Hand.

CALLED BY:	HandStartSelect when hand has no cards and wants them back

PASS:		nothing
		
CHANGES:	

RETURN:		carry set if no cards to flush

DESTROYED:	

PSEUDO CODE/STRATEGY:
		store vis size for later invalidation
		pop all cards to hand
		invalidate old vis bounds

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonFlush	method	SolitaireTalonClass, MSG_TALON_FLUSH
	;
	;	We don't want to flush if the game is iconified, as
	;	that leads to a crash bug :(
	;
	mov	cx, VUQ_GAME_ATTRIBUTES
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
	test	cl, mask GA_ICONIFIED
	jz	notIconified
	jmp	endTalonFlush
notIconified:
	;
	;	Make sure we have cards to flush...
	;
	PointDi2 Deck_offset
	tst	ds:[di].DI_nCards
	jnz	flush
	stc
	jmp	endTalonFlush

flush:
	;
	;	First, let's register this transfer with the proper
	;	authorities (i.e. remember where the cards went and
	;	tell the game object that we're the last donators).
	;
	RESET	ds:[di].DI_deckAttrs, DA_JUST_UNCOVERED
	mov	bp, ds:[di].DI_nCards
	mov	cx, ds:[di].TI_hand.handle
	mov	dx, ds:[di].TI_hand.offset
	mov	ds:[di].DI_lastRecipient.handle, cx
	mov	ds:[di].DI_lastRecipient.offset, dx
	mov	ds:[di].DI_lastGift, bp

	;
	;	Increment the number of times we've flushed the talon
	;
	mov	cx, 1
	mov	ax, MSG_SOLITAIRE_UPDATE_TIMES_THRU
	call	VisCallParent			;cx <- timesThru - draw#

	;
	;	Penalize the player, if necessary
	;
	PointDi2 Deck_offset
	mov	dx, ds:[di].DI_flipPoints
	tst	dx
	jz	afterScore

	tst	cx				;been thru too much?
	jle	updateScore

	mov	ax, dx				;ax <- penalty
	mul	cx				;ax <- scaled penalty
	mov	dx, ax				;dx <- scaled penalty
updateScore:
	clr	cx
	CallObject	MyPlayingTable, MSG_GAME_UPDATE_SCORE, MF_FIXUP_DS

afterScore:
	;
	;	Get our vis bounds before the transfer so that we can
	;	invalidate the proper area after the transfer.
	;
	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock
	push	cx, dx

	;
	;	Give all the cards to the hand. MSG_DECK_GET_RID_OF_CARDS is
	;	used in place of MSG_DECK_POP_ALL_CARDS because the former is
	;	simply the latter with the handy suppression of score change
	;	due to popping cards off the talon.
	;
	PointDi2 Deck_offset
	mov	cx, ds:[di].TI_hand.handle
	mov	dx, ds:[di].TI_hand.offset
	mov	ax, MSG_DECK_GET_RID_OF_CARDS
	call	ObjCallInstanceNoLock

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GAME_SET_DONOR
	call	VisCallParent

	;
	;	Clean up any area of the screen we might need to.
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	PointDi2 Vis_offset
	mov	cx, ds:[di].VI_bounds.R_left
	mov	dx, ds:[di].VI_bounds.R_top
	pop	ax,bx				;restore old size

	CONVERT_WHLT_TO_LTRB

	mov	di, bp				;di <- graphics state
	call	GrInvalRect			;invalidate area
	call	GrDestroyState			;kill the gstate
	clc
endTalonFlush:
	ret
TalonFlush	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TalonMoveAndClip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_MOVE_AND_CLIP handler for SolitaireTalonClass
		Makes sure there is a top card and that it is drawable before
		passing this one on to the superclass

CALLED BY:	

PASS:		nothing
		
CHANGES:	DI_topCardLeft, DI_topCardTop

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonMoveAndClip	method	SolitaireTalonClass, MSG_DECK_MOVE_AND_CLIP
	;
	;	If no cards, then don't bother movin' and clippin'
	;
	tst	ds:[di].DI_nCards
	jz	endTalonMoveAndClip

	;
	;	If the top card isn't drawable, then there's no need
	;	to clip its bounds anyway
	;
	mov	ax, MSG_CARD_QUERY_DRAWABLE
	call	VisCallFirstChild
	jnc	endTalonMoveAndClip

	;
	;	Call the superclass
	;
	mov	di, segment SolitaireTalonClass
	mov	es, di
	mov	di, offset SolitaireTalonClass
	mov	ax, MSG_DECK_MOVE_AND_CLIP
	call	ObjCallSuperNoLock
endTalonMoveAndClip:
	ret
TalonMoveAndClip	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TalonPostPush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TALON_POST_PUSH handler for SolitaireTalonClass
		Fixes up the visual state of affairs after the hand
		delivers cards to the talon. In particular, if the hand
		runs out of cards, there may be some cards underneath the
		ones just pushed to the talon that should be hidden.

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
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonPostPush	method	SolitaireTalonClass, MSG_TALON_POST_PUSH
	;
	;	Get a graphics state to invalidate through
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	tst	bp
	jz	endTalonPostPush

	push	bp
	mov	ax, MSG_DECK_CLEAN_AFTER_SHRINK
	call	ObjCallInstanceNoLock
	pop	di
	call	GrDestroyState
endTalonPostPush:
	ret
TalonPostPush	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				TalonInvalidateInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_INVALIDATE_INIT handler for SolitaireTalonClass
		Makes sure that the talon didn't just uncover before
		calling the superclass.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:
none

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonInvalidateInit	method	SolitaireTalonClass, MSG_DECK_INVALIDATE_INIT
	test	ds:[di].DI_deckAttrs, mask DA_JUST_UNCOVERED
	jnz	done

	mov	di, offset SolitaireTalonClass
	call	ObjCallSuperNoLock
done:
	ret
TalonInvalidateInit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TalonPrePush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TALON_PRE_PUSH handler for SolitaireTalonClass
		Prepares the talon to receive a series of pushes from the
		hand.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		set all children not drawable
		store width, height in DI_dragWidth and DI_dragHeight so
		that we know if we need an invalidate in post push.

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonPrePush	method	SolitaireTalonClass, MSG_TALON_PRE_PUSH
	PointDi2 Deck_offset
	tst	ds:[di].DI_nDragCards
	jz	prepareForPushing
	stc
	jmp	endTalonPrePush

prepareForPushing:
	mov	ax, MSG_CARD_SET_NOT_DRAWABLE
	call	VisSendToChildrenWithTest

	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock

	PointDi2 Deck_offset
	mov	ds:[di].DI_topCardLeft, ax
	mov	ds:[di].DI_topCardTop, bp
	mov	ds:[di].DI_initRight, cx
	mov	ds:[di].DI_initBottom, dx
	clc
endTalonPrePush:
	ret
TalonPrePush	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TalonPushCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_PUSH_CARD handler for SolitaireTalonClass

CALLED BY:	

PASS:		^lcx:dx = card to be pushed
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		turn card face up (cards in hand are face down)
		call super class
		undo the MSG_CARD_SET_NOT_DRAWABLE from the super class
KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonPushCard	method	SolitaireTalonClass, MSG_DECK_PUSH_CARD
	;
	;	Turn card face up and make it drawable
	;
	push	si
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_CARD_TURN_FACE_UP
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_CARD_SET_DRAWABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	
	push	cx,dx				;save card OD
	mov	ax, MSG_DECK_MOVE_AND_CLIP	;prepare to push card
	call	ObjCallInstanceNoLock
	pop	cx,dx				;restore card OD

	push	cx, dx				;save card OD
	mov	ax, MSG_DECK_ADD_CARD_FIRST	;push it
	call	ObjCallInstanceNoLock

	;
	;	Do the score thing
	;
	PointDi2 Deck_offset
	mov	dx, ds:[di].DI_pushPoints
	tst	dx
	jz	afterScore
	clr	cx
	CallObject	MyPlayingTable, MSG_GAME_UPDATE_SCORE, MF_FIXUP_DS
afterScore:

	pop bx, si				;restore card OD

	mov	ax, MSG_CARD_FADE_REDRAW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
TalonPushCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TalonRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Talon method for MSG_DECK_RESTORE_STATE

		This is subclassed so that the talon doesn't go wild
		and restore its cards all the way to the right of the
		screen.

Called by:	MSG_DECK_RESTORE_STATE

Pass:		*ds:si = Talon object
		ds:di = Talon instance

		^hcx:dx - data

Return:		^hcx:dx - updated past restored data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 18, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireTalonRestoreState	method dynamic	SolitaireTalonClass,
				MSG_DECK_RESTORE_STATE
	uses	bp
	.enter

	;
	;  Clear the offsets so all the cards get pushed in one spot
	;
	clr	bx, bp
	xchg	ds:[di].DI_offsetFromUpCardX, bx
	xchg	ds:[di].DI_offsetFromUpCardY, bp

	push	bx, bp

	mov	di, offset SolitaireTalonClass
	call	ObjCallSuperNoLock

	;
	;  Fixup the damage done
	;
	pop	bx, ax
	mov	di, ds:[si]
	add	di, ds:[di].SolitaireTalon_offset
	mov	ds:[di].DI_offsetFromUpCardX, bx
	mov	ds:[di].DI_offsetFromUpCardY, ax

	.leave
	ret
SolitaireTalonRestoreState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TalonPushCardNoEffects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_PUSH_CARD_NO_EFFECTS handler for SolitaireTalonClass
		Talon flips a passed card face up and pushes into it
		into its composite (no fading effects).

CALLED BY:	

PASS:		^lcx:dx = card to be pushed
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonPushCardNoEffects	method	SolitaireTalonClass, MSG_DECK_PUSH_CARD_NO_EFFECTS
	CallObjectCXDX	MSG_CARD_TURN_FACE_UP, MF_FIXUP_DS

	mov	ax, MSG_DECK_PUSH_CARD_NO_EFFECTS		;call super class
	mov	di, segment SolitaireTalonClass
	mov	es, di
	mov	di, offset SolitaireTalonClass		;to add card to tree
	call	ObjCallSuperNoLock
	ret
TalonPushCardNoEffects	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				TalonUncover
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TALON_UNCOVER handler for SolitaireTalonClass.
		This method should be passed to the talon whenever the last
		of its visible cards is removed from its composite; this
		method will redisplay a certain number of cards that have
		been "uncovered".

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		We pop the number of cards to the hand, then request them
		back.

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonUncover	method	SolitaireTalonClass, MSG_TALON_UNCOVER
	CallObject	MyPlayingTable, MSG_SOLITAIRE_GET_DRAW_NUMBER, MF_CALL

	;
	;	We don't want to award the user for uncovering, so we'll
	;	temporarily tell the talon that its popPoints are 0.
	;

	PointDi2 Deck_offset
	clr	bp
	xchg	bp, ds:[di].DI_popPoints
	push	bp,si
	mov	dx, ds:[di].DI_nCards

	cmp	cx, dx
	jle	cxCardsToUncover

	mov	cx, dx

cxCardsToUncover:
	jcxz	endTalonUncover
	push	cx

	;
	;	Give cx cards to the hand
	;
	mov	cx, ds:[di].TI_hand.handle
	mov	dx, ds:[di].TI_hand.offset

	pop	bp
	push	bp
	push	cx, dx
	mov	ax, MSG_DECK_POP_N_CARDS
	call	ObjCallInstanceNoLock
	pop bx,si

	;
	;	Get the cards back
	;
	pop	cx
	mov	bp, MSG_DECK_PUSH_CARD
	mov	ax, MSG_PLAY_TO_TALON
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
endTalonUncover:
	;
	;	Restore the talon's popPoints
	;
	pop	bp,si
	PointDi2 Deck_offset
	mov	ds:[di].DI_popPoints, bp
	SET	ds:[di].DI_deckAttrs, DA_JUST_UNCOVERED
	ret
TalonUncover	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				TalonReturnCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_RETURN_CARDS handler for SolitaireTalonClass
		The Talon and the Hand are the only two objects that
		return n cards in reverse order (i.e. the last card given
		is the first card returned). As such, we need to subclass
		this method to reflect this strange behavior...
		Also, there's a call to check whether we need to uncover.

CALLED BY:	

PASS:		bp = number of cards to return
		^lcx:dx = who to give them to
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonReturnCards	method	SolitaireTalonClass, MSG_DECK_RETURN_CARDS
	tst	ds:[di].DI_nCards		;superfluous check to see if
	jz	endTalonReturnCards		;we have any cards???

	push	ds:[di].DI_popPoints
	clr	ds:[di].DI_popPoints

	push	cx,dx,bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	cx,dx,bp

	mov	ax, MSG_DECK_POP_N_CARDS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_CARD_MAXIMIZE
	call	VisCallFirstChild

	mov	ax,MSG_TALON_CHECK_UNCOVER
	call	ObjCallInstanceNoLock

	PointDi2 Deck_offset
	pop	ds:[di].DI_popPoints
endTalonReturnCards:
	ret
TalonReturnCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				TalonRetrieveCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_RETRIEVE_CARDS handler for SolitaireTalonClass
		Retrieves DI_lastGift cards from DI_lastRecipient.

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
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TalonRetrieveCards	method	SolitaireTalonClass, MSG_DECK_RETRIEVE_CARDS
	;
	;	If the talon did NOT just uncover, then we can just
	;	call the superclass
	;
	test	ds:[di].DI_deckAttrs, mask DA_JUST_UNCOVERED
	jnz	justUncovered
	mov	di, offset SolitaireTalonClass
	call	ObjCallSuperNoLock
	jmp	endTalonRetrieveCards

	;
	;	The tricky part is when we DID just uncover; we treat this
	;	as sort of a hand -> talon exchange.
	;
justUncovered:
	mov	ax, MSG_TALON_PRE_PUSH
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	mov	di, segment SolitaireTalonClass
	mov	es, di
	mov	di, offset SolitaireTalonClass
	mov	ax, MSG_DECK_RETRIEVE_CARDS
	call	ObjCallSuperNoLock

	mov	ax, MSG_DECK_UPDATE_TOPLEFT
	call	ObjCallInstanceNoLock

	mov	ax, MSG_TALON_POST_PUSH
	call	ObjCallInstanceNoLock
endTalonRetrieveCards:
	ret
TalonRetrieveCards	endm
CommonCode	ends		;end of CommonCode resource
