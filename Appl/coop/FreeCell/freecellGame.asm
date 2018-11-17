COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		freecellGame.asm

AUTHOR:		Mark Hirayama, July 8, 1993

ROUTINES:
	Name				Description
	----				-----------
	FreeCellSetupStuff		Performs setup duties required
					before playing the first game of
					FreeCel.

	FreeCellSetupGeometry		Manually setups decks in the view
					content.

	FreeCellPositionDeck		Draws the passed deck object on the
					playing table.

	FreeCellSetFoundationSpreads	Set Foundation deck spreads to 0,0.

	FreeCellNewGame			Shuffles cards, saves state, then
					sends a DEAL_CARDS message.

	FreeCellNewGameMenuSelect	Handler for selecting 'New Game'
					from the menu.

	FreeCellRedeal			Distributes the 52 cards to the
					8 WorkSpace decks in the same order
					as the saved state indicates.

	FreeCellRedealMenuSelect	Handler for selecting 'Redeal'
					from the menu.

	FreeCellUndo			Handler for selecing 'Undo' from
					the menu.

	FreeCellDealCards		Distributes the 52 cards in the
					game's Hand object to the 8 WorkSpace
					decks.

	FreeCellRegisterDrag		Whenever a drag is registered, also
					want to check to see if we have a
					winner.

	FreeCellCheckForWinner		Checks to see if all Foundation decks
					are full (i.e. contains 13 cards).

	FreeCellFinishGame		Handler for when the player wins a
					game.

	FreeCellSetSound		Sets sound to either TRUE or FALSE
					(ON or OFF), depending on the state
					of the option in the menu.

	FreeCellSetDrag			Sets drag option to either DRAG_OUTLINE
					or DRAG_FULL.

	FreeCellSaveState		Saves the state of the 52 cards in
					the game's Hand object.

	FreeCellShutDown		Performs necessary shutdown routines.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/ 8/93		Initial revision

DESCRIPTION:
	Implementation of the FreeCell class

	$Id: freecellGame.asm,v 1.1 97/04/04 15:02:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	FreeCellClass		; have to put the class definition somewhere...
idata	ends

CommonCode	segment	resource


;
; workSpaceTable will be used to get the optr to each WorkSpace deck.
; This table is used in the handlers for MSG_GAME_DEAL_CARDS and
; MSG_GAME_REDEAL
;

workSpaceTable	optr \
	WorkSpace1,
	WorkSpace2,
	WorkSpace3,
	WorkSpace4,
	WorkSpace5,
	WorkSpace6,
	WorkSpace7,
	WorkSpace8


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellSetupStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs tasks required before playing first game
		of FreeCell.

CALLED BY:	FreeCellProcessOpenApplication (in freecell.asm module)

PASS:		*ds:si	= FreeCellClass object
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
	- Dispatch message to our superclass.
	- Set up sounds.
	- Choose which card back design to use.
	- Change the default spreads for each of the decks.
	- Set default offset spread for decks at 20,0.
	- Set foundation deck spreads at 0,0.
	- Create a full hand of 52 cards.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellSetupStuff	method dynamic FreeCellClass, 
					MSG_GAME_SETUP_STUFF
	uses	ax, cx, dx, bp
	.enter

	;
	; Allow superclass to handle this message also.
	;
		mov	di, offset es:FreeCellClass
		call	ObjCallSuperNoLock
	;
	; Execute setup routine for playing sounds
	;
		CallMod	SoundSetupSounds
	;
	; Choose which card back design to use.
	; Note: Currently this chooses a default.  Later, may want to
	;       implement the Cardback Chooser.....
	;
		mov	cx, 3			; cx <-default design
		mov	ax, MSG_GAME_SET_WHICH_BACK
		call	ObjCallInstanceNoLock	; set card back design
	;
	; Set default spreads for all decks at (20,0).
	;
		mov	cx, 0
		mov	dx, 20
		mov	ax, MSG_GAME_SET_UP_SPREADS
		call	ObjCallInstanceNoLock
	;
	; Set Foundation deck offsets (should be 0,0)
	;
		mov	ax, MSG_FREECELL_SET_FOUNDATION_SPREADS
		call	ObjCallInstanceNoLock
	;
	; Create a hand of 52 standard cards
	;
		GetResourceHandleNS MyHand, bx		; bx <- block handle
		mov	si, offset MyHand		; si <- object handle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS	; di <- flags
		mov	ax, MSG_HAND_MAKE_FULL_HAND	; ax <- message
		call	ObjMessage
		
	.leave
	ret
FreeCellSetupStuff	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to manually set decks in viewing space.

CALLED BY:	MSG_GAME_SETUP_GEOMETRY

PASS:		*ds:si	= FreeCellClass object
		es 	= dgroup (segment of class definition)

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
	- Dispatch this message to our superclass
	- Store the card width and card height in some local variables
	- Set MyHand deck at a negative value so it doesn't show up on
	  visible space.
	- Display cards in their correct positions
	- NOTE: in order to make the Hand object invisible, I am placing
		it at a negative coordinate.  Is there a better way to do
		this?

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	MH	7/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellSetupGeometry	method dynamic FreeCellClass, 
					MSG_GAME_SETUP_GEOMETRY
cardWidth	local	word
cardHeight	local	word
		
	uses	ax, cx, dx, bp
	.enter

	;
	; Dispatch this message to our superclass
	;
		mov	di, offset FreeCellClass
		call	ObjCallSuperNoLock
	;
	; Store card width and card height.  (first need to dereference
	; instance data again, since di was destroyed by calling superclass)
	;
		mov	di, ds:[si]
		add	di, ds:[di].FreeCell_offset	; dereference instance

		mov	bx, ds:[di].GI_cardWidth
		mov	ss:[cardWidth], bx		; store card width
		mov	bx, ds:[di].GI_cardHeight
		mov	ss:[cardHeight], bx		; store card height
	;
	; Hide MyHand deck at a negative coordinate so won't show up.
	;
		mov	cx, MY_HAND_SPACING		; MyHand
		mov	dx, MY_HAND_SPACING
		mov	bx, handle MyHand
		mov	si, offset MyHand
		call	FreeCellPositionDeck
	;
	; Display FreeSpace decks on upper left of table.
	;
		mov	cx, FREE_SPACE_SPACING_LEFT	; FreeSpace1
		mov	dx, FREE_SPACE_SPACING_TOP
		mov	bx, handle FreeSpace1
		mov	si, offset FreeSpace1
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; FreeSpace2
		add	cx, STANDARD_SPACING
		mov	bx, handle FreeSpace2
		mov	si, offset FreeSpace2
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; FreeSpace3
		add	cx, STANDARD_SPACING
		mov	bx, handle FreeSpace3
		mov	si, offset FreeSpace3
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; FreeSpace4
		add	cx, STANDARD_SPACING
		mov	bx, handle FreeSpace4
		mov	si, offset FreeSpace4
		call	FreeCellPositionDeck
	;
	; Display Foundation decks on upper right of table
	;
		mov	cx, FOUNDATION_SPACING_LEFT	; Foundation1
		mov	dx, FOUNDATION_SPACING_TOP
		mov	bx, handle Foundation1
		mov	si, offset Foundation1
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; Foundation2
		add	cx, STANDARD_SPACING
		mov	bx, handle Foundation2
		mov	si, offset Foundation2
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; Foundation3
		add	cx, STANDARD_SPACING
		mov	bx, handle Foundation3
		mov	si, offset Foundation3
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; Foundation4
		add	cx, STANDARD_SPACING
		mov	bx, handle Foundation4
		mov	si, offset Foundation4
		call	FreeCellPositionDeck
	;
	; Display WorkSpace decks in middle of table.
	;
		mov	cx, WORK_SPACE_SPACING_LEFT	; WorkSpace1
		mov	dx, ss:[cardHeight]
		add	dx, WORK_SPACE_SPACING_TOP
		mov	bx, handle WorkSpace1
		mov	si, offset WorkSpace1
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; WorkSpace2
		add	cx, STANDARD_SPACING
		mov	bx, handle WorkSpace2
		mov	si, offset WorkSpace2
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; WorkSpace3
		add	cx, STANDARD_SPACING
		mov	bx, handle WorkSpace3
		mov	si, offset WorkSpace3
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; WorkSpace4
		add	cx, STANDARD_SPACING
		mov	bx, handle WorkSpace4
		mov	si, offset WorkSpace4
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; WorkSpace5
		add	cx, STANDARD_SPACING
		mov	bx, handle WorkSpace5
		mov	si, offset WorkSpace5
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; WorkSpace6
		add	cx, STANDARD_SPACING
		mov	bx, handle WorkSpace6
		mov	si, offset WorkSpace6
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; WorkSpace7
		add	cx, STANDARD_SPACING
		mov	bx, handle WorkSpace7
		mov	si, offset WorkSpace7
		call	FreeCellPositionDeck

		add	cx, ss:[cardWidth]		; WorkSpace8
		add	cx, STANDARD_SPACING
		mov	bx, handle WorkSpace8
		mov	si, offset WorkSpace8
		call	FreeCellPositionDeck

	.leave
	ret
FreeCellSetupGeometry	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellPositionDeck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the deck object on the table.

CALLED BY:	FreeCellSetupGeometry

PASS:		^lbx:si = deck to position
		cx = left edge of deck
		dx = top edge of deck

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- calls MSG_VIS_SET_POSITION to draw the deck at this position
	- invalidates deck so it shows up immediately.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellPositionDeck	proc	near
	uses	ax, cx, dx, bp
	.enter

	;
	; everything is already set up except di and ax
	;
		mov	di, mask MF_FIXUP_DS
		mov	ax, MSG_VIS_SET_POSITION
		call	ObjMessage
	;
	; invalidate bounding region for the deck, so it shows up
	;
		mov	di, mask MF_FIXUP_DS
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjMessage

	.leave
	ret
FreeCellPositionDeck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellSetFoundationSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to set Foundation deck spreads to 0,0.

CALLED BY:	FreeCellSetupStuff

PASS:		*ds:si	= FreeCellClass object
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- use MSG_DECK_SET_UP_SPREADS on each Foundation deck to set
	  its spread to 0,0.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellSetFoundationSpreads	method dynamic FreeCellClass, 
					MSG_FREECELL_SET_FOUNDATION_SPREADS
	uses	ax, cx, dx, bp
	.enter

	;
	; Move message into ax, then send message to each Foundation deck
	; in turn.
	;
		clr	cx				; offsetX = 0
		clr	dx				; offsetY = 0
		mov	ax, MSG_DECK_SET_UP_SPREADS	; message for all
		
		mov	bx, handle Foundation1		; Foundation1
		mov	si, offset Foundation1
		mov	di, mask MF_CALL
		call	ObjMessage

		mov	si, offset Foundation2		; Foundation2
		mov	di, mask MF_CALL
		call	ObjMessage

		mov	si, offset Foundation3		; Foundation3
		mov	di, mask MF_CALL
		call	ObjMessage

		mov	si, offset Foundation4		; Foundation4
		mov	di, mask MF_CALL
		call	ObjMessage
		
	.leave
	ret
FreeCellSetFoundationSpreads	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellNewGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for new game -- either upon startup, or when
		New Game is selected from the menu.

CALLED BY:	FreeCellProcessOpenApplication and
		FreeCellNewGameMenuSelect

PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Set attribute to indicate that we haven't won a game since
	  the last redeal.
	- Shuffle cards.
	- Save the state of the game (after shuffling, but before dealing),
	  in case user wants to restart the same game.
	- Send DEAL_CARDS message.
	- Mark the window invalid.
	- Disable Undo trigger and enable the Redeal trigger.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellNewGame	method dynamic FreeCellClass, 
					MSG_FREECELL_NEW_GAME
	uses	ax, cx, dx, bp
	.enter

	;
	; Clear the GA_JUST_WON_A_GAME flag
	;
		RESET	ds:[di].GI_gameAttrs, GA_JUST_WON_A_GAME
	;
	; Shuffle the hand
	;
		GetResourceHandleNS MyHand, bx
		mov	si, offset MyHand
		mov	di, mask MF_CALL
		mov	ax, MSG_HAND_SHUFFLE
		call	ObjMessage
	;
	; Save current state, in case we want to start this game over
	;
		GetResourceHandleNS MyPlayingTable, bx
		mov	si, offset MyPlayingTable
		mov	di, offset es:FreeCellClass
		mov	ax, MSG_GAME_SAVE_STATE
		call	ObjCallInstanceNoLock			; cxdx <- state
	;
	; dereference instance, and store the handle and length of state.
	;
		mov	di, ds:[si]
		add	di, ds:[di].FreeCell_offset		; dereference
		
		mov	ds:[di].FCI_savedStateHandle, cx	; store handle
		mov	ds:[di].FCI_savedStateLength, dx	; store length
	;
	; Check for sound mode.  (NOTE: di already points to instance)
	;
		tst	ds:[di].FCI_soundMode
		jz	skipSound
	;
	; Play music for dealing cards.
	;
		mov	cx, FCS_DEAL_CARDS
		CallMod	SoundPlaySound

skipSound:
	;
	; Send DEAL_CARDS message to game object.
	;
		mov	ax, MSG_FREECELL_DEAL_CARDS
		call	ObjCallInstanceNoLock
	;
	; Make sure the window is marked as invalid, so we can start
	; playing.
	;
		mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
		mov	dl, VUM_NOW
		call	VisMarkInvalid
	;
	; Disable the Undo trigger, since we're at the beginning of the
	; game, there can be nothing to undo.
	;
		GetResourceHandleNS UndoTrigger, bx
		mov	si, offset UndoTrigger
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjMessage
	;
	; Enable the Redeal trigger (it is disabled if you've just won
	; a game.
	;
		GetResourceHandleNS RedealTrigger, bx
		mov	si, offset RedealTrigger
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_ENABLED
		call	ObjMessage


	.leave
	ret
FreeCellNewGame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellNewGameMenuSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for selecting New Game from menu trigger.

CALLED BY:	MSG_FREECELL_NEW_GAME_MENU_SELECT (from NewGameTrigger)

PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Determine whether a game was just previously won or not.
	  If so, deal new game.  If not, display a dialog box to confirm
	  whether the user actually wants a new game.
	- If want a new game, collect cards and send NEW_GAME message.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellNewGameMenuSelect	method dynamic FreeCellClass, 
					MSG_FREECELL_NEW_GAME_MENU_SELECT
	uses	ax, cx, dx, bp
	.enter

	;
	; Make sure we haven't just won a game.
	;
		test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
		jnz	newGame
	;
	; Display Standard dialog box, confirming the redeal.  The user
	; will have to option to click 'Yes' or 'No'.
	;
		sub	sp, size StandardDialogParams	; leave space on stack
		mov	bp, sp				; bp <- top of stack
		mov	ss:[bp].SDP_customFlags,  \
			CustomDialogBoxFlags <0,CDT_WARNING,GIT_AFFIRMATION,0>
		mov	ss:[bp].SDP_customString.segment, handle StringBlock
		mov	ss:[bp].SDP_customString.offset, offset ConfirmString
		movdw	ss:[bp].SDP_stringArg1, 0
		movdw	ss:[bp].SDP_stringArg2, 0
		movdw	ss:[bp].SDP_customTriggers, 0
		movdw	ss:[bp].SDP_helpContext, 0
		
		call	UserStandardDialogOptr		; ax <- response
	;
	; 'Yes': Start a new game.
	; 'No':  Continue with current game.
	;
		cmp	ax, IC_NO			; 'No' clicked?
		je	done				; If so, done.
		
newGame:
	;
	; If 'Yes' was clicked, user wants to start another game, so
	; gather all the cards, and send NEW_GAME message.
	;
		mov	ax, MSG_GAME_COLLECT_ALL_CARDS
		call	ObjCallInstanceNoLock

		mov	ax, MSG_FREECELL_NEW_GAME
		call	ObjCallInstanceNoLock

done:
	.leave
	ret
FreeCellNewGameMenuSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellRedeal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Almost identical to DEAL_CARDS, except that attributes
		are inserted from the saved state as each card is dealt.
		Has the effect of restarting same game over (i.e. without
		shuffling cards).

CALLED BY:	FreeCellRedealMenuSelect

PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Lock saved state block.
	- Initialize card index (for saved state data retrieval) and
	  deck index (to determine which deck receives next card).
	- Pop a card from MyHand.  If MyHand empty, done.  Otherwise,
	  continue.
	- Change the attributes of this card to the stored attributes.
	- Turn card faceup, and set it on appropriate deck.
	- Either increment deck index by 1 (if just placed card on decks
	  1 thru 7) or set index to 1 (if just placed card on deck 8).
	- Loop.
	- When done, restore stack to original position, and unlock
	  the memblock.

	- NOTE:  Remember, this handler is using local variables, so need
		 to maintain value in bp whenever it is destroyed.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellRedeal	method dynamic FreeCellClass, 
					MSG_FREECELL_REDEAL
cardIndex	local	word
cardSegment	local	word		
deckIndex	local	word
		
	uses	ax, cx, dx, bp
	.enter
	;
	; Lock the memblock containing saved state data
	;
		mov	bx, ds:[di].FCI_savedStateHandle ; bx <- mem handle
		call	MemLock				; ax <- mem segment
		mov	ss:[cardSegment], ax		; store mem segment
	;
	; Initilize the card index and the workspace deck index.  The card
	; index will increment from 0 to 51, and the deck index will range
	; between FIRST_WORKSPACE_DECK and LAST_WORKSPACE_DECK.
	;
		clr	ss:[cardIndex]
		mov	ss:[deckIndex], FIRST_WORKSPACE_DECK

redealLoop:
	;
	; Get a card from the hand by popping it off MyHand.  Also, make
	; sure that a card is in fact returned.
	; NOTE: after this call, si still contains offset to FreeCellClass
	;       object, not the hand object.....
	;
		push	bp				; save bp
		CallObject MyHand, MSG_DECK_POP_CARD, MF_CALL ; ^lcx:dx <- card
		jc	done				; no card -> done
	;
	;	Change the attributes of the card to the ones stored...
	;
	;	NOTE: bp needs to be restored, because a local variable
	;             is being accessed.
	;
	;	NOTE: cx and dx are *NOT* being saved/restored when
	;	      CallObjectCXDX is called.  Although cx and dx are
	;	      potentially destroyed, with these messages they are.
	;	      If a problem arises, may want to save/restore cx and
	;	      dx at each CallObjectCXDX call.
	;
		pop	bp				; restore bp
		push	bp				; store bp again
		push	ds				; save game handle
		mov	ds, ss:[cardSegment]		; ds <- card segment
		mov	di, ss:[cardIndex]		; di <- card index
		add	ss:[cardIndex], 2		; increment card index
		mov	bp, ds:[di]			; bp <- CardAttrs
		pop	ds				; restore game handle
		CallObjectCXDX MSG_CARD_SET_ATTRIBUTES, MF_CALL

setCardOnNextDeck::
	;
	; Turn this card face up.
	;
		CallObjectCXDX MSG_CARD_TURN_FACE_UP, MF_CALL
	;
	; Place the index of the next deck to recieve a card in cx, in
	; order to get the optr of this deck.  Also, preserve the game
	; offset, because we're going to use si to index the WorkSpace
	; table.
	;
		pop	bp				; restore bp
		push	bp				; store bp again
		push	si				; game offset

	;
	; Now, set up registers so we can place this card on this
	; deck.
	;
		mov	si, ss:[deckIndex]		; si <- current deck
		shl	si, 1				; si <- si * 4
		shl	si, 1				;   (for table index)
		movdw	bxsi, cs:workSpaceTable[si]	; ^lbx:si <- deck optr
		mov	ax, MSG_DECK_GET_DEALT		; message to pass
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		
		pop	si				; restore game offset
	;
	; Increment the number (i.e. index) of the current WorkSpace deck.
	; If that was the last workspace deck, then go back to the first one.
	; Then just loop back to setCardOnNextDeck.
	;
		pop	bp				; retore bp
		inc	ss:[deckIndex]			; next deck

		cmp	ss:[deckIndex], LAST_WORKSPACE_DECK ; too far?
		jg	backToFirstDeck			; yes: back to first
		jmp	redealLoop			; loop

backToFirstDeck:
		mov	ss:[deckIndex], FIRST_WORKSPACE_DECK ; bp <- 1st deck
		jmp	redealLoop

done:
	;
	; Restore stack to original position, and unlock the memblock.
	;
		pop	bp				; restore stack

		mov	di, offset MyPlayingTable	; di <- game offset
		mov	di, ds:[di]			; di <- object offset
		add	di, ds:[di].FreeCell_offset	; dereference
		mov	bx, ds:[di].FCI_savedStateHandle ; bx <- mem handle
		call	MemUnlock

	.leave
	ret
FreeCellRedeal	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellRedealMenuSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restores the state, and redeals the cards

CALLED BY:	MSG_FREECELL_REDEAL_MENU_SELECT (from RedealTrigger)

PASS:		*ds:si	= FreeCellClass object
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Present dialog box, asking user if he really wants to do
	  this.
	- If yes, then collect cards, and send REDEAL message.
	- Invalidate window, and disable Undo trigger.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellRedealMenuSelect	method dynamic FreeCellClass, 
					MSG_FREECELL_REDEAL_MENU_SELECT
	uses	ax, cx, dx, bp
	.enter

	;
	; Display Standard dialog box, confirming the redeal.  The user
	; will have to option to click 'Yes' or 'No'.
	;
		sub	sp, size StandardDialogParams	; leave space on stack
		mov	bp, sp				; bp <- top of stack
		mov	ss:[bp].SDP_customFlags,    \
			CustomDialogBoxFlags <0,CDT_WARNING,GIT_AFFIRMATION,0>
		mov	ss:[bp].SDP_customString.segment, handle StringBlock
		mov	ss:[bp].SDP_customString.offset, offset ConfirmString
		movdw	ss:[bp].SDP_stringArg1, 0
		movdw	ss:[bp].SDP_stringArg2, 0
		movdw	ss:[bp].SDP_customTriggers, 0
		movdw	ss:[bp].SDP_helpContext, 0
		
		call	UserStandardDialogOptr		; ax <- response
	;
	; 'Yes': Start a new game.
	; 'No':  Continue with current game.
	;
		cmp	ax, IC_NO			; 'No' clicked?
		je	done				; If so, done.
		
redeal::
	;
	; If 'Yes' was clicked, user wants to start this game over.
	; Need to collect cards to MyHand, and send REDEAL message to
	; self.
	;
		mov	ax, MSG_GAME_COLLECT_ALL_CARDS
		call	ObjCallInstanceNoLock

		mov	ax, MSG_FREECELL_REDEAL
		call	ObjCallInstanceNoLock
	;
	; Make sure the window is marked as invalid, so we can start
	; playing.
	;
		mov	si, offset MyPlayingTable
		mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
		mov	dl, VUM_NOW
		call	VisMarkInvalid
	;
	; Disable the Undo trigger, since we're at the beginning of the
	; game, there can be nothing to undo.
	;
		GetResourceHandleNS UndoTrigger, bx
		mov	si, offset UndoTrigger
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjMessage
done:

	.leave
	ret
FreeCellRedealMenuSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for the Undo menu item.

CALLED BY:	MSG_FREECELL_UNDO (from UndoTrigger)

PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Make sure we actually have something to undo.
	- Perform the undo.
	- Disable the Undo trigger.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellUndo	method dynamic FreeCellClass, 
					MSG_FREECELL_UNDO
	uses	ax, cx, dx, bp
	.enter

	;
	; Make sure that the lastDoner field is not NULL -- if so, we
	; can't undo anything.  Also, want to clear the lastDoner field.
	;
		clr	bx
		xchg	bx, ds:[di].GI_lastDonor.handle	; bx <- last handle
		tst	bx				; last handl null?
		jz	done				; yes: can't undo

		clr	si
		xchg	si, ds:[di].GI_lastDonor.chunk	; si <- last chunk
		mov	di, mask MF_FIXUP_DS		; di <- flags
		mov	ax, MSG_DECK_RETRIEVE_CARDS
		call	ObjMessage
	;
	; Disable the Undo trigger -- only one undo at a time.
	;
		GetResourceHandleNS UndoTrigger, bx
		mov	si, offset UndoTrigger
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjMessage

done:
	.leave
	ret
FreeCellUndo	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellDealCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assumes the cards are in the game's hand object.  In
		FreeCell, all 52 cards should be in the hand object
		whenever this message is called.

CALLED BY:	FreeCellNewGame and FreeCellRestartGame

PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		ds:bx	= FreeCellClass object (same as *ds:si)
		es 	= segment of FreeCellClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- At the bottom of the stack we will keep track of the current
	  WorkSpace deck to receive the next card.  Usually this will
	  temporarily be held in bp, where we will increment and test...
	- Get a card off the hand, and make sure that a card is in fact
	  returned.
	- Turn the card face up.
	- Set card on appropriate deck.  
	- Return to the second instruction, (i.e. getting a card off the
	  hand), and loop until the hand is empty.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellDealCards	method dynamic FreeCellClass, 
					MSG_FREECELL_DEAL_CARDS
		
	uses	ax, cx, dx, bp
	.enter

	;
	; Initialize the current WorkSpace deck to 0, and place this data
	; at the bottom of the stack.
	;
		mov	bp, FIRST_WORKSPACE_DECK	; first deck
		push	bp				; bp -> bottom of stack

dealLoop:
	;
	; Get a card from the hand by popping it off MyHand.
	; NOTE: after this call, si still contains offset to FreeCellClass
	;       object, not the hand object.....
	;
		CallObject MyHand, MSG_DECK_POP_CARD, MF_CALL ; ^lcx:dx <- card
	;
	; Make sure a card was returned
	;
		jc	done				; no card -> done
		
setCardOnNextDeck::
	;
	; Move the number of the current WorkSpace deck into bp, but
	; also keep this data at the bottom of the stack.  Then save
	; the hand offset and the card optr on the stack.
	;
		pop	bp				; bp <- current deck
		push	bp				; bp -> bottom of stack
		push	si				; save game offset
		push	cx, dx				; save card optr
		CallObjectCXDX MSG_CARD_TURN_FACE_UP, MF_CALL
	;
	; Now, set up registers so we can place this card on this
	; deck.
	;
		shl	bp, 1				; bp <- bp * 4 
		shl	bp, 1				; (for table index)
		movdw	bxsi, cs:workSpaceTable[bp]	; ^lbx:si <- deck
		pop	cx, dx				; ^lcx:dx <- card optr
		mov	ax, MSG_DECK_GET_DEALT		; message to pass
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		
		pop	si				; restore game offset
	;
	; Increment the number (i.e. index) of the current WorkSpace deck.
	; If that was the last workspace deck, then go back to the first one.
	; Then just loop back to setCardOnNextDeck.
	;
		pop	bp				; bp <- current deck
		inc	bp				; next

		cmp	bp, LAST_WORKSPACE_DECK		; too far?
		jg	backToFirstDeck			; yes: back to first
		push	bp				; store next stack
		jmp	dealLoop			; loop

backToFirstDeck:
		mov	bp, FIRST_WORKSPACE_DECK	; bp <- 4 (first deck)
		push	bp				; store next stack
		jmp	dealLoop

done:
		pop	bp				; to restore sp
		
	.leave
	ret
FreeCellDealCards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellRegisterDrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Want our game object to intercept this call to check
		whether the user has won.

CALLED BY:	MSG_GAME_REGISTER_DRAG
PASS:		*ds:si	= FreeCellClass object
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Dispatch message to superclass.
	- Dispatch CHECK_FOR_WINNER message to self.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellRegisterDrag	method dynamic FreeCellClass, 
					MSG_GAME_REGISTER_DRAG
	uses	ax, cx, dx, bp
	.enter

	;
	; Allow our superclass to handle this message
	;
		mov	di, offset es:FreeCellClass
		call	ObjCallSuperNoLock
	;
	; Send CHECK_FOR_WINNER message to game object
	;
		GetResourceHandleNS MyPlayingTable, bx
		mov	si, offset MyPlayingTable
		mov	ax, MSG_FREECELL_CHECK_FOR_WINNER
		call	ObjCallInstanceNoLock

	.leave
	ret
FreeCellRegisterDrag	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellCheckForWinner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if all the Foundation decks contain 13
		cards.  If even one of them doesn't, then continue with
		game.  Otherwise, user has won.

CALLED BY:	FreeCellRegisterDrag

PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	if the user has won, GA_JUST_WON_A_GAME flag is set

PSEUDO CODE/STRATEGY:
	- Check each foundation deck in turn to see if it is full,
	  i.e. contains 13 cards.
	- If all of them do, then set GA_JUST_WON_A_GAME flag,
	  and dispatch FINISH_GAME message.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellCheckForWinner	method dynamic FreeCellClass, 
					MSG_FREECELL_CHECK_FOR_WINNER
	uses	ax, cx, dx, bp
		.enter

	;
	; Check each foundation deck to see if they all contain 13 cards
	;
		mov	ax, MSG_DECK_GET_N_CARDS
		mov	di, mask MF_CALL

		GetResourceHandleNS Foundation1, bx	; check Foundation1
		mov	si, offset Foundation1
		mov	di, mask MF_CALL
		call	ObjMessage
		cmp	cx, FOUNDATION_FULL
		LONG jl	done

		GetResourceHandleNS Foundation2, bx	; check Foundation2
		mov	si, offset Foundation2
		mov	di, mask MF_CALL
		call	ObjMessage
		cmp	cx, FOUNDATION_FULL
		LONG jl	done

		GetResourceHandleNS Foundation3, bx	; check Foundation3
		mov	si, offset Foundation3
		mov	di, mask MF_CALL
		call	ObjMessage
		cmp	cx, FOUNDATION_FULL
		jl	done

		GetResourceHandleNS Foundation4, bx	; check Foundation4
		mov	si, offset Foundation4
		mov	di, mask MF_CALL
		call	ObjMessage
		cmp	cx, FOUNDATION_FULL
		jl	done

weHaveAWinner::
	;
	; Here we need to put things for game to do when someone wins.
	;

	;
	; Set flag that we have just won a game
	;
		mov	si, offset MyPlayingTable	; si <- object handle
		mov	di, ds:[si]
		add	di, ds:[di].FreeCell_offset	; dereference inst
		SET	ds:[di].GI_gameAttrs, GA_JUST_WON_A_GAME
	;
	; Disable the Undo trigger
	;
		GetResourceHandleNS UndoTrigger, bx
		mov	si, offset UndoTrigger
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjMessage
	;
	; Disable the Redeal trigger
	;
		GetResourceHandleNS RedealTrigger, bx
		mov	si, offset RedealTrigger
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjMessage
	;
	; Send FINISH_GAME message, and tack it to end of queue.
	; (need to use ObjMessage, because want to force message to
	; be at the end of the queue.
	;
		GetResourceHandleNS MyPlayingTable, bx
		mov	si, offset MyPlayingTable
		mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
		mov	ax, MSG_FREECELL_FINISH_GAME
		call	ObjMessage
		
done:

	.leave
	ret
FreeCellCheckForWinner	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellFinishGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This handler is added so it can be queued at the end,
		allowing all redrawing of cards/decks to be completed
		before any dialog boxes are displayed.

CALLED BY:	FreeCellCheckForWinner

PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Play winner's sound.
	- Display 'congratulations' dialog box.
	- Splay cards.
	- Maybe later add some other stuff...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellFinishGame	method dynamic FreeCellClass, 
					MSG_FREECELL_FINISH_GAME
	uses	ax, cx, dx, bp
	.enter

	;
	; Check for sound mode.  (NOTE: di already points to instance)
	;
		tst	ds:[di].FCI_soundMode
		jz	skipSound
	;
	; Play winner's sound
	;
		mov	cx, FCS_WINNER
		CallMod	SoundPlaySound
		
skipSound:
		
if 0

	; ********** The spraying routine isn't really working....*******
	;
	; Gather all the cards, and give to MyHand
	;
		mov	ax, MSG_GAME_COLLECT_ALL_CARDS
		call	ObjCallInstanceNoLock
	;
	; To test the spray deck message
	;
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE	; ^hbp <- GState
		call	ObjCallInstanceNoLock

;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; Apply an initial translation
	;
		mov	dx, ds:[di].GI_cardWidth	;dx <- 4 * cardWidth
		shl	dx
		shl	dx
		mov	bx, 50
		push	bx
		mov	bx, 800
		push	bx
		clr	cx
		clr	ax
		mov	di, bp
		call	GrApplyTranslation

	;
	;	Now we apply the intial rotation to the gstate (subsequent
	;	rotations are carried out by the cards themselves).
	;
		clr	cx
		mov	dx, 1			; EFFECTS_ANGLE
		call	GrApplyRotation

		mov	bp, di
		pop	cx
		pop	bx
		sub	cx, bx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; Tell MyHand to spray itself.
	;
		GetResourceHandleNS MyHand, bx
		mov	si, offset MyHand
;		mov	cx, 200				; radius
;		mov	dx, 5				; degrees per card
		mov	di, mask MF_FIXUP_DS
		mov	ax, MSG_DECK_SPRAY_CARDS
		call	ObjMessage

endif

	;
	; Put up the Finish dialog box
	;
		mov	bx, handle FinishBox		;FinishBox resource
		mov	si, offset FinishBox
		call	UserDoDialog

		
	.leave
	ret
FreeCellFinishGame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellSetSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets sound to either TRUE or FALSE

CALLED BY:	MSG_FREECELL_SET_SOUND (from SoundItemGroup)

PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		es 	= segment of FreeCellClass
		ax	= message #
		cx	= option

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellSetSound	method dynamic FreeCellClass, 
					MSG_FREECELL_SET_SOUND
	.enter

	;
	; Insert into instance data.  TRUE = SoundOn, FALSE = SoundOff
	;
		mov	ds:[di].FCI_soundMode, cx	; store option
		
	.leave
	ret
FreeCellSetSound	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellSetDrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the drag option to either DRAG_OUTLINE or DRAG_FULL.

CALLED BY:	MSG_FREECELL_SET_DRAG
PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		es 	= segment of FreeCellClass
		ax	= message #
		cx	= option

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellSetDrag	method dynamic FreeCellClass, 
					MSG_FREECELL_SET_DRAG
	.enter

	;
	; Insert into instance data, either DRAG_OUTLINE or DRAG_FULL
	;
		mov	ds:[di].GI_dragType, cl		; store option
		
	.leave
	ret
FreeCellSetDrag	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves CardAttrs for each of 52 cards in the Game object's
		hand.

CALLED BY:	FreeCellNewGame

PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		ds:bx	= FreeCellClass object (same as *ds:si)
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		cx - handle to memblock with data
		dx - length of data

DESTROYED:	cx, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Check to make sure a saved state block does/doesn't exist.
	- Either lock existing block, or create a new one.
	- Store attributes of each card into the block.
	- Unlock the block.
	- return handle to block in cx, length in dx.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellSaveState	method dynamic FreeCellClass, 
					MSG_GAME_SAVE_STATE
	uses	ax, bp
	.enter

	;
	; Check to see if there is a pre-existing saved state block.
	; If there is, lock the block before continuing.  If there is
	; not, allocate a new block (locked and swappable) before
	; continuing.
	;
		mov	bx, ds:[di].FCI_savedStateHandle ; bx <- state handle
		tst	bx				; existing state?
		jz	allocateNewMemBlock		; no: allocate new one

stateMemBlockExists::
	;
	; If the block already exists, the just lock it, and begin storing.
	; card data.
	;
		call	MemLock				; ax <- mem segment
		jmp	storeData			; continue

allocateNewMemBlock:
	;
	; Need to allocate 52 + 1 words -- last one indicates how many --
	; in the block.  The block that is returned will be locked, and
	; it is swappable.
	;
		mov	ax, 53 * size word
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc			; ax <- block segment
		jc	done				; error -> done

storeData:
	;
	; Now store data.  New memory block is locked, so move it to es:di
	; bx will be pushed onto stack, to be popped into cx just before
	; exiting this handler
	;
		mov	es, ax				; es:di <- store data
		clr	di
		push	bx				; stack <- handle
	;
	; Keep track of which card we're on with bp on the stack.
	;
		clr	bp
		
getAttributesLoop:
	;
	; Push current count onto stack and store data offset
	;
		push	bp				; stack <- count
		push	di				; store data offset
	;
	; Get attributes of Nth card.
	;
		GetResourceHandleNS MyHand, bx
		mov	si, offset MyHand
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
		call	ObjMessage			; bp <- CardAttrs
	;
	; Store attributes
	;
		mov	ax, bp				; ax <- CardAttrs
		pop	di				; es:di <- data
		stosw					; store data
	;
	; Check to see if we're done.  If not, increment bp, and loop.
	;
		pop	bp				; bp <- count
		inc	bp				; increment count
		cmp	bp, 52				; 52nd card?
		jne	getAttributesLoop		; no: loop
		
doneWithLoop::
	;
	; When done with loop, unlock memblock, then need to return
	; handle to memblock in cx, and length in dx.
	;
		pop	bx				; bx <- memblock handle
		call	MemUnlock			; unlock block
		
		mov	cx, bx				; cx <- memblock handle
		mov	dx, di				; dx <-length
done:
	.leave
	ret
FreeCellSaveState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellShutDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Necessary shutdown routines, including shutting off sounds

CALLED BY:	MSG_GAME_SHUT_DOWN
PASS:		*ds:si	= FreeCellClass object
		ds:di	= FreeCellClass instance data
		ds:bx	= FreeCellClass object (same as *ds:si)
		es 	= segment of FreeCellClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Send message to superclass
	- Shut off shounds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellShutDown	method dynamic FreeCellClass, 
					MSG_GAME_SHUTDOWN
	uses	ax, cx, dx, bp
	.enter

	;
	; Send to superclass
	;
		mov	di, offset es:FreeCellClass
		call	ObjCallSuperNoLock
	;
	; Shut off sounds.
	;
		CallMod	SoundShutOffSounds
		
	.leave
	ret
FreeCellShutDown	endm


CommonCode	ends
