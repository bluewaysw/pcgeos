COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Solitaire
FILE:		deck.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	6/90		Initial Version

DESCRIPTION:
	this file contains handlers for DeckClass

RCS STAMP:
$Id: deck.asm,v 1.1 97/04/04 17:44:40 newdeal Exp $
------------------------------------------------------------------------------@

CardsClassStructures	segment	resource
	DeckClass
CardsClassStructures	ends

;---------------------------------------------------

CardsCodeResource segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeckSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Deck method for MSG_DECK_SAVE_STATE

		marks the deck as dirty.

Called by:	MSG_DECK_SAVE_STATE

Pass:		*ds:si = Deck object
		ds:di = Deck instance

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 18, 1993 	Initial version.
	PW	March 23, 1993	modified.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckSaveState	method dynamic	DeckClass, MSG_DECK_SAVE_STATE
	.enter

	call	ObjMarkDirty

	.leave
	ret
DeckSaveState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeckRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Deck method for MSG_DECK_RESTORE_STATE

		does nothing, just there to subclass

Called by:	MSG_DECK_RESTORE_STATE

Pass:		*ds:si = Deck object
		ds:di = Deck instance

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 18, 1993 	Initial version.
	PW	March 23, 1993	modified.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRestoreState	method dynamic	DeckClass, MSG_DECK_RESTORE_STATE
	.enter

	.leave
	ret
DeckRestoreState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeckGetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Deck method for MSG_DECK_GET_VM_FILE

Called by:	MSG_DECK_GET_VM_FILE

Pass:		*ds:si = Deck object
		ds:di = Deck instance

Return:		cx = vm file

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckGetVMFile	method dynamic	DeckClass, MSG_DECK_GET_VM_FILE
	.enter

	mov	ax, MSG_GAME_GET_VM_FILE
	call	VisCallParent

	.leave
	ret
DeckGetVMFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckAddCardFirst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_ADD_CARD_FIRST handler for DeckClass
		This method moves the card into the proper position
		(DI_topCardLeft, DI_topCardTop), and then adds
		the card into the deck's child tree as the first child.

CALLED BY:	DeckPushCard, DeckGetDealt;

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		^lcx:dx = child to be added
		
CHANGES:	card in ^lcx:dx is moved to DI_topCardLeft, DI_topCardTop
		card is added to deck's vis tree as first child
		DI_nCards is updated accordingly

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		moves card
		adds card
		gets card's attributes

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckAddCardFirst	method		DeckClass, MSG_DECK_ADD_CARD_FIRST

	;;move the card (visually) to where it is supposed to be

	push	cx, dx, si			;save card OD and deck offset
	mov	bx, cx
	mov	si, dx				;^lbx:si = card
	mov	cx, ds:[di].DI_topCardLeft
	mov	dx, ds:[di].DI_topCardTop
	mov	ax, MSG_VIS_SET_POSITION			;move card to topCard(Left,Top)
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	cx, dx, si			;restore card OD and
						;deck offset

	;;add the card into the deck's composite
	mov	bp, CCO_FIRST or mask CCF_MARK_DIRTY
						;card as the first child
	mov	ax, MSG_VIS_ADD_CHILD
	GOTO	ObjCallInstanceNoLock
DeckAddCardFirst	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckCardDoubleClicked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_CARD_DOUBLE_CLICKED handler for DeckClass
		This method is called by a child card when it gets
		double clicked. The deck turns this event into a sort of
		psuedo-drag, then asks if anydeck wants it.

CALLED BY:	called by the double clicked card in CardStartSelect

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		bp = # of card double clicked in composite
		
CHANGES:	sends a message to the playing table to check its children
		for acceptance of the double clicked card.  If it is accepted,
		it is transferred.  Otherwise, no changes.

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		checks to make sure double clicked card is top card
		checks to make sure card is face up
		sets up drag data
		informs playing table of the double click
		if card is accepted by another deck:
			new top card of deck *ds:si is maximized
			DI_topCard(Left,Top) is updated
			we check if we need to uncover the deck (valid	
			only for TalonClass)

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckCardDoubleClicked	method	DeckClass, MSG_DECK_CARD_DOUBLE_CLICKED
	test	ds:[di].DI_deckAttrs, mask DA_IGNORE_DOUBLE_CLICKS
	jnz	endDCDC
	tst	bp				;test if card is first child
	jnz	endDCDC				;if not, jump to end

	mov	ax, MSG_CARD_GET_ATTRIBUTES		;get card's attrs
	call	VisCallFirstChild

	test	bp, mask CA_FACE_UP		;test if card is face up
	jz	endDCDC				;if not, jump to end
	push	bp				;save card attrs

	mov	bp,1				;bp <- # cards to drag
	mov	ax, MSG_DECK_SETUP_DRAG		;setup deck's drag data
	call	ObjCallInstanceNoLock

	pop	bp				;restore card attrs
	mov	ax, MSG_GAME_BROADCAST_DOUBLE_CLICK
	call	DeckCallParentWithSelf		;tell playing table to tell the
						;foundations that a card has
						;been double clicked

	jnc	endDCDC				;if nobody took the cards,
						;jump to end

	Deref_DI Deck_offset
	clr	ds:[di].DI_nDragCards		;clear # drag cards
	call	ObjMarkDirty

	mov	ax, MSG_DECK_REPAIR_SUCCESSFUL_TRANSFER
	call	ObjCallInstanceNoLock
endDCDC:
	Deref_DI Deck_offset
	clr	ds:[di].DI_nDragCards		;clear # drag cards 
	call	ObjMarkDirty
	ret
DeckCardDoubleClicked	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckDragOrFlip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DRAG_OR_FLIP handler for DeckClass
		Deck will either start a drag or flip a card, depending
		on whether the card is face up or face down.

CALLED BY:	called by the selected card

PASS:		*ds:si = instance data of deck
		cx,dx = mouse position
		bp = # of selected card in deck's composite

CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		issues a MSG_[UP|DOWN]_CARD_SELECTED to self, depending
		on the attrs of the selected card

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckDragOrFlip	method	DeckClass, MSG_DECK_DRAG_OR_FLIP
	push	bp					;save card #
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	DeckCallNthChild
	test	bp, mask CA_FACE_UP			;see if card is face up
	pop	bp					;restore card #
	jz	cardIsFaceDown				;if card face down, jmp
;cardIsFaceUp:
	Deref_DI Deck_offset
	mov	cx, ds:[di].DI_initLeft
	mov	dx, ds:[di].DI_initTop
	mov	ax, MSG_DECK_UP_CARD_SELECTED
	call	ObjCallInstanceNoLock
	jmp	endDeckDragOrFlip

cardIsFaceDown:
	mov	ax, MSG_DECK_DOWN_CARD_SELECTED
	call	ObjCallInstanceNoLock

endDeckDragOrFlip:
	ret
DeckDragOrFlip	endm	



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckCardSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_CARD_SELECTED handler for DeckClass

CALLED BY:	called by the selected card

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		cx,dx = mouse position
		bp = # of selected card in deck's composite

CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckCardSelected	method	DeckClass, MSG_DECK_CARD_SELECTED
	mov	ds:[di].DI_initLeft, cx
	mov	ds:[di].DI_initTop, dx
	call	ObjMarkDirty

	mov	ax, MSG_GAME_DECK_SELECTED
	call	DeckCallParentWithSelf
	ret
DeckCardSelected	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckFlipCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_FLIP_CARD handler for DeckClass.
		Flips the top card (i.e., if it's face up, turns
		it face down, and vice-versa) and sends it a fade redraw.

CALLED BY:	

PASS:		*ds:si = deck object
		
CHANGES:	top card gets flipped

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckFlipCard	method	DeckClass, MSG_CARD_FLIP_CARD
	mov	ax, MSG_CARD_FLIP
	call	VisCallFirstChild

	mov	ax, MSG_CARD_FADE_REDRAW
	call	VisCallFirstChild

	mov	ax, MSG_GAME_NOTIFY_CARD_FLIPPED
	call	VisCallParent

	ret
DeckFlipCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckCheckDragCaught
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_CHECK_DRAG_CAUGHT handler for DeckClass
		checks to see whether a drag area intersects with this
		deck's catch area
CALLED BY:	

PASS:		*ds:si = instance data of deck
		^lcx:dx = dragging deck
		
CHANGES:	nothing

RETURN:		carry set if drag area of deck ^lcx:dx overlaps with catch area
		of deck *ds:si

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckCheckDragCaught	method	DeckClass, MSG_DECK_CHECK_DRAG_CAUGHT
	CallObjectCXDX	MSG_DECK_GET_DRAG_BOUNDS, MF_CALL
	push	ax				;save drag left
	push	bp				;save drag top
	push	cx				;save drag right
	push	dx				;save drag bottom

	mov	ax, MSG_DECK_GET_CATCH_BOUNDS
	call	ObjCallInstanceNoLock
	mov	bx, bp

					;at this point,
					;ax = catch left
					;bx = catch top
					;cx = catch right
					;dx = catch bottom

	pop	bp			;bp <- drag bottom
	cmp	bx, bp
	jle	continue1		;if catch top <= drag bottom, continue

	add	sp, 6			;else clear stack
	jmp	noIntersect		;catch area is below drag area

continue1:
	pop	bp			;bp <- drag right
	cmp	ax, bp
	jle	continue2		;if catch left <= drag right, continue

	add	sp, 4			;else clear stack
	jmp	noIntersect		;catch area is to right of drag area

continue2:
	pop	bp			;bp <- drag top
	cmp	bp, dx
	jle	continue3		;if drag top <= catch bottom, continue

	add	sp, 2			;else clear stack
	jmp	noIntersect		;catch area is above drag area

continue3:
	pop	bp			;bp <- drag left
	cmp	bp, cx
	jg	noIntersect		;if drag left > catch right, drag area
					;is left of catch area

;yesIntersect:
	stc				;set carry to indicate that
					;areas intersect
	jmp	endDeckCheckDragCaught

noIntersect:
	clc				;clear carry to indicate that
					;areas do not intersect

endDeckCheckDragCaught:
	ret

DeckCheckDragCaught	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckClipNthCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_CLIP_NTH_CARD handler for DeckClass

CALLED BY:	used when full drag cards are misplaced, the card immediately
		under the drag cards must be re-clipped
		
PASS:		*ds:si = instance data of deck
		bp = nth card to clip (0 = top card)
		cx = (left of card to be placed onto nth) - (left of nth)
		dx = (top of card to be placed onto nth) - (top of nth)
		
CHANGES:	bp'th card is clipped according to offsets in cx,dx

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:
		calls MSG_VIS_FIND_CHILD with cx, dx as passed
		passes MSG_CARD_CLIP_BOUNDS to child returned (if any)

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckClipNthCard		method		DeckClass, MSG_DECK_CLIP_NTH_CARD
	tst	bp
	mov	ax, MSG_CARD_CLIP_BOUNDS		;tell card to clip its bounds
	jnz	callChild
	call	VisCallFirstChild		;for top card, do it quickly
	jmp	endDeckClipNthCard

callChild:
	call	DeckCallNthChild
endDeckClipNthCard:
	ret
DeckClipNthCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckDraggableCardSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DRAGGABLE_CARD_SELECTED handler for DeckClass

CALLED BY:	

PASS:		*ds:si = instance data of deck
		cx,dx = mouse position
		bp = # of children to drag
		
CHANGES:	GState is created (destroyed in DeckEndSelect)
		drag data is set up (via MSG_DECK_SETUP_DRAG)
		if outline dragging:
		       *inital outline is drawn (via MSG_DECK_DRAW_DRAG_OUTLINE)
		if full dragging:
		       *deck registers itself with the playing table in order
			to assure that it is redrawn during an exposed event
			(in case the drag goes off the screen, we don't want
			the graphics to be lost)
		       *card immediately beneath selected card is maximized

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		[0]: Grab mouse and Ptr Events
		[1]: Create GState
		[2]: call MSG_DECK_SETUP_DRAG on self
		[3]: check drag type from playing table
		[4 outline]: call MSG_DECK_DRAW_DRAG_OUTLINE
		[4 full]: register self as dragger with playing table
		[5 full]: maximize card below selected card


KNOWN BUGS/IDEAS:
			RENAME THIS TO REFLECT ACTUAL PURPOSE!!!!!!!!!
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckDraggableCardSelected    method   DeckClass, MSG_DECK_DRAGGABLE_CARD_SELECTED
	push	cx,dx,bp			;save mouse position, n cards

	call	VisForceGrabMouse		;grab mouse events
;	call	VisSendAllPtrEvents		;and ptr events

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	Deref_DI Deck_offset
	mov	ds:[di].DI_gState, bp		;save gstate for later use
	call	ObjMarkDirty

	pop	cx,dx,bp			;restore mouse position, n card
	mov	ax, MSG_DECK_SETUP_DRAG
	call	ObjCallInstanceNoLock		;set up drag data

	mov	ax, MSG_GAME_MARK_ACCEPTORS
	call	DeckCallParentWithSelf

	mov	ax, MSG_GAME_GET_DRAG_TYPE
	call	VisCallParent

	cmp	cl, DRAG_OUTLINE		;see if we're outline dragging
	jne	fullDragging			;if not, jump to full dragging

;outlineDragging:
	Deref_DI Deck_offset
	mov	di, ds:[di].DI_gState		;di <- graphics state

	;change the graphics state to our liking and draw the outline
	mov	al, MM_INVERT
	call	GrSetMixMode			;set invert mode

	clr	ax, dx
	call	GrSetLineWidth			;set line width = 1

	mov	ax, MSG_DECK_DRAW_DRAG_OUTLINE
	call	ObjCallInstanceNoLock		;draw the outline

	jmp	checkInvertAcceptors

fullDragging:

	; set first card under last drag card to drawable, full-size
	Deref_DI Deck_offset
	mov	bp, ds:[di].DI_nDragCards
	mov	ax, MSG_CARD_MAXIMIZE
	call	DeckCallNthChild

checkInvertAcceptors:

	mov	ax, MSG_DECK_GET_DROP_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GAME_INVERT_ACCEPTORS
	call	DeckCallParentWithSelf

	;the deck must register itself with the playing table as being a
	;dragger so that MSG_EXPOSEDs are passed to the deck no matter what
	
	mov	ax, MSG_GAME_REGISTER_DRAG
	call	DeckCallParentWithSelf
	ret
DeckDraggableCardSelected		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_DRAW handler for DeckClass

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		bp = gState
		
CHANGES:	draws deck

RETURN:		nothing
	
DESTROYED:	

PSEUDO CODE/STRATEGY:
	checks to see if deck owns any visible children.
	if so, processes them, then frees ClipRect
	if not, draws its marker

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckDraw	method		DeckClass, MSG_VIS_DRAW

	.enter

	;;we want to draw the marker instead of the children when the
	;number of cards in the deck is not greater than the number of drag
	;cards (i.e., when there are no undragged cards)

	mov	dx, ds:[di].DI_nCards		;dx <- # total cards
	sub	dx, ds:[di].DI_nDragCards	;dx <- (total - drag) cards
	jnz	drawChildren			;if the deck has any cards that
						;are not currently dragging,
						;then we want to draw them
	mov	ax, MSG_DECK_DRAW_MARKER
	call	ObjCallInstanceNoLock		;otherwise, draw the marker
	jmp	done

drawChildren:
	mov	ax, MSG_DECK_DRAW_REVERSE
	call	ObjCallInstanceNoLock		;draw children in reverse order
done:
	.leave
	ret
DeckDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckDrawDragOutline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DRAW_DRAG_OUTLINE handler for DeckClass

CALLED BY:	DeckDraggableCardSelected, DeckOutlinePtr, etc.

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		
CHANGES:	draws outine of drag cards

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
		draws a big box around entire drag area
		draws in horizontal lines as needed to show multiple cards

KNOWN BUGS/IDEAS:
this outline drawer will only look good if DI_offsetFromUpCardX is 0. For the
present, this is OK because it is 0.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckDrawDragOutline	method	DeckClass, MSG_DECK_DRAW_DRAG_OUTLINE
	mov	si, ds:[di].DI_offsetFromUpCardY	;si <- vert. offset
	mov	bp, ds:[di].DI_nDragCards		;bp <- # drag cards
	dec	bp					;bp <- # of extra
							;lines we have to
							;draw other than the
							;bounding box
	
	mov	ax, ds:[di].DI_dragWidth
	mov	bx, ds:[di].DI_dragHeight
	mov	cx, ds:[di].DI_prevLeft
	mov	dx, ds:[di].DI_prevTop

	CONVERT_WHLT_TO_LTRB

	;;now ax,bx,cx,dx = left,top,right,bottom of drag area

	mov	di, ds:[di].DI_gState			;di <- gState

	push	ax, dx
	mov	dx, 5
	clr	ax
	call	GrSetLineWidth			;set line width = 5
	pop	ax, dx

	call	GrDrawRect				;draw bounding outline

	;;this loop draws in the extra lines we need to indicate multiple cards
startLoop:
	dec	bp
;	tst	bp		;see if we're done yet
	jl	endLoop		;if so, end

	add	bx, si		;otherwise add vert. offset to top

;	mov	dx, bx		;set dx = bx so we get a horizontal line
;	call	GrDrawLine	;draw in our line

	call	GrDrawHLine	;This one line should replace the two
				;preceeding lines
	jmp	startLoop
endLoop:
	ret
DeckDrawDragOutline	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckDrawDrags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DRAW_DRAGS handler for DeckClass
		Deck sends MSG_VIS_DRAW's to each of its drag cards

CALLED BY:	PlayingTableDraw

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		bp = gstate

CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		draws drag cards.  used for conditions where the drag area
		has gone out of bounds and we need to expose the area.

KNOWN BUGS/IDEAS:
		This should be changed to use ObjCompProcessChildren
		stuff instead of the vis links.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckDrawDrags	method	DeckClass, MSG_DECK_DRAW_DRAGS
	mov	cx, ds:[di].DI_nDragCards	;cx <- # drag cards
	jcxz	endLoop
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	bx, ds:[si].VCI_comp.CP_firstChild.handle
	mov	si, ds:[si].VCI_comp.CP_firstChild.chunk

	mov	ax, MSG_VIS_DRAW
startLoop:
	dec	cx				;cx--
	tst	cx				;test for more drag cards 
	jl	endLoop				;if none, jump

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		;make the call

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	add	si, offset VI_link

	mov	bx, ds:[si].LP_next.handle	
	mov	si, ds:[si].LP_next.chunk
	jmp	startLoop		;jump to start of loop

endLoop:
	ret
DeckDrawDrags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckDrawMarker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DRAW_MARKER handler for DeckClass
		draws a colored box in the bounds of the deck

CALLED BY:	DeckDraw

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		bp = gstate
		
CHANGES:	changes color, area mask, draw mode of gstate, then
		fills a box in the vis bounds of the deck

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
probably want to put in cool bitmaps eventually to replace the colored boxes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckDrawMarker	method	DeckClass, MSG_DECK_DRAW_MARKER
	uses	ax, cx, dx, bp
	.enter
	mov	cl, ds:[di].DI_markerMask
	mov	al, ds:[di].DI_markerColor	;get our color into al
	mov	di,bp				;move gstate into di

	mov	ah, CF_INDEX
	call	GrSetAreaColor			;set our color

	mov	al, cl
	call	GrSetAreaMask

	mov	al, MM_COPY			;copy mode
	call	GrSetMixMode

	mov	al, CMT_DITHER
	call	GrSetAreaColorMap

	clr	cl				;clear CompBoundsFlags
	call	VisGetBounds		

	mov	cx, ax
	mov	dx, bx

	mov	ax, MSG_GAME_DRAW_BLANK_CARD
	call	VisCallParent

	mov	di, bp
	mov	al, SDM_100
	call	GrSetAreaMask
	.leave
	ret
DeckDrawMarker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckDrawReverse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DRAW_REVERSE handler for DeckClass

CALLED BY:	

PASS:		*ds:si = instance data of deck
		bp = graphics state
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		cycles through children and pushes their OD to the stack
		then pops each one off the stack and sends each a MSG_VIS_DRAW

KNOWN BUGS/IDEAS:
		THIS METHOD WONT BE NEEDED IF VIS BOUNDS DONT OVERLAP, WHICH
		WOULD HAPPEN IF EITHER OF THE DI_offsetFromUpCard IN TALON
		IS ZEROED

i would prefer the routine to use the next sibling links, rather than calling
MSG_VIS_FIND_CHILD each time

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckDrawReverse	method	DeckClass, MSG_DECK_DRAW_REVERSE
	push	bp	;gstate
	clr	dx
	clr	bx

startPushLoop:
	push	dx		;save # of child we're about to examine
	push	bx		;save # pushed so far
	clr	cx		;cx:dx = # of child
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock
	jc	endPushLoop	;if no children, we're done

	CallObjectCXDX MSG_CARD_QUERY_DRAWABLE, MF_CALL	;do we want to draw it?
	jnc	checkOutNext				;if not, check next

	;;otherwise, get the OD of this child onto the stack
	; we want it so that the OD's are always at the bottom of the stack:
;
;			+---------------------+
;	top of stack  ->|   # pushed so far   |
;			+---------------------+
;			|# of child to examine|
;			+---------------------+
;			|        gstate       |
;			+---------------------+
;			|         OD          |
;			|         #1          |
;			+---------------------+
;			|         OD          |
;			|         #2          |
;			+---------------------+
;			|         OD          |
;			|         #3          |
;			           .
;			           .
;			           .
;
;
	pop	bx		;get # pushed so far off stack
	pop	ax		;get # of child just examined off stack
	pop	bp		;get gstate off stack
	push	cx,dx		;push card OD
	push	bp		;put gstate back on stack
	push	ax		;put # of child just examined back on stack
	inc	bx		;increment # of OD's pushed on stack
	push	bx		;and push it onto the stack

checkOutNext:
	pop	bx		;restore # of OD's on stack so far
	pop	dx		;restore # of child just examined
	inc	dx		;get number of next child
	jmp	startPushLoop

endPushLoop:
	pop	bx	; # of ODs pushed
	pop	dx	; junk
	pop	bp	; gstate

startDrawLoop:
	dec	bx		;see if there are any more ODs on the stack
	jl	endDrawLoop	;if not, end
	pop	cx,si		;otherwise, pop one off
	push	bx		;save # of ODs
	mov	bx, cx		;^lbx:si <- OD
	mov	ax, MSG_VIS_DRAW	;draw the card
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	bx		;restore # of ODs
	jmp	startDrawLoop
endDrawLoop:
	ret
DeckDrawReverse	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckDropDrags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DROP_DRAGS handler for DeckClass

CALLED BY:	DeckEndSelect

PASS:		*ds:si = instance data of deck
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		sends a method to the playing table asking it to give
		the drag cards to any deck that'll take them.
		if the cards are taken:
			issues a MSG_DECK_REPAIR_SUCCESSFUL_TRANSFER to self
		else:
			issues a MSG_DECK_REPAIR_FAILED_TRANSFER to self

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckDropDrags	method		DeckClass, MSG_DECK_DROP_DRAGS
	push	si

	mov	ax, MSG_DECK_GET_DROP_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GAME_DROPPING_DRAG_CARDS
	call	DeckCallParentWithSelf			;tell parent to
							;advertise the dropped
							;cards
	pop	si
	mov	ax, MSG_DECK_REPAIR_SUCCESSFUL_TRANSFER
	jc	repair
	mov	ax, MSG_DECK_REPAIR_FAILED_TRANSFER	;do visual repairs
repair:
	call	ObjCallInstanceNoLock
	ret
DeckDropDrags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_END_SELECT, MSG_META_END_MOVE_COPY handler for DeckClass

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		
CHANGES:	DI_gState cleared
		DI_nDragCards zeroed

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, 

PSEUDO CODE/STRATEGY:
		[outline 0] erases last outline
		[full 0] invalidates last drag region
		[1] send self a MSG_DRAP_DRAGS
		[2] release mouse
		[3] destroy gState
		[4] clear DI_gState and DI_nDragCards
		[5] send a method to playing table to inform that it is no
			longer dragging

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckEndDrag	method	DeckClass, MSG_META_END_SELECT, MSG_META_END_MOVE_COPY
	tst	ds:[di].DI_gState	;if we have a gstate, we're dragging,
	jnz	getDragType		;so continue
	jmp	endDeckEndDrag	;otherwise, end

getDragType:
;	CallObject MyPlayingTable, MSG_GAME_GET_DRAG_TYPE, MF_CALL

	mov	ax, MSG_GAME_GET_DRAG_TYPE
	call	VisCallParent


	cmp	cl, DRAG_OUTLINE	;see what kind of drag we're doing
	jne	eraseDragArea		;if full dragging, erase drag area

;eraseOutline:
	mov	ax, MSG_DECK_DRAW_DRAG_OUTLINE	;erase the outline
	call	ObjCallInstanceNoLock

	jmp	invertAcceptors

eraseDragArea:
	Deref_DI Deck_offset
	mov	cx, ds:[di].DI_prevLeft
	mov	dx, ds:[di].DI_prevTop
	cmp	cx, ds:[di].DI_initLeft		;have we moved horizontally?
	jne	loadDimensions			;if so, go ahead with erasing
	cmp	dx, ds:[di].DI_initTop		;have we moved vertically?
	je	invertAcceptors			;if not, don't erase

loadDimensions:
	mov	ax, ds:[di].DI_dragWidth
	mov	bx, ds:[di].DI_dragHeight

	CONVERT_WHLT_TO_LTRB

	mov	di, ds:[di].DI_gState
	call	GrInvalRect			;erase the last drag area

invertAcceptors:
	mov	ax, MSG_GAME_GET_USER_MODE
	call	VisCallParent

	cmp	cl, INTERMEDIATE_MODE
	jne	$10

	clr	cx
	clr	dx
	mov	ax, MSG_GAME_REGISTER_HILITED
	call	VisCallParent

$10:
	mov	ax, MSG_DECK_GET_DROP_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GAME_INVERT_ACCEPTORS
	call	DeckCallParentWithSelf

	mov	ax, MSG_DECK_DROP_DRAGS		;drop these babies!!!
	call	ObjCallInstanceNoLock


	call	VisReleaseMouse		;We no longer want all the mouse events

	Deref_DI Deck_offset
	mov	di, ds:[di].DI_gState
	tst	di
	jz	cleanUp
	call	GrDestroyState		;Free the gstate

cleanUp:
	Deref_DI Deck_offset
	clr	ds:[di].DI_gState	;clear gstate pointer
	clr	ds:[di].DI_nDragCards	;no longer dragging any cards
	call	ObjMarkDirty

endDeckEndDrag:

	; do this since the mouse event is processed here (return code)
	mov	ax, mask MRF_PROCESSED

	ret
DeckEndDrag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckFullPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_FULL_ PTR handler for DeckClass

CALLED BY:	DeckPtr when the game is in full card dragging mode

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		cx,dx = mouse coordinates
		
CHANGES:	moves dragged cards to reflect new mouse position
		bit blts to reflect new mouse position

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		calculate spatial differences between this mouse
			event and the last (deltaX and deltaY)
		move the dragged cards by deltaX and deltaY 
			via (MSG_CARD_MOVE_RELATIVE)
		update the drag coordinates
		call GrBitBlt

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckFullPtr	method	DeckClass, MSG_DECK_FULL_PTR

	push	cx,dx				;save mouse position

	;;get the x and y distances between this mouse event and
	; the last one

	sub	cx, ds:[di].DI_dragOffsetX	;cx <- new left
	sub	dx, ds:[di].DI_dragOffsetY	;dx <- new top
	sub	cx, ds:[di].DI_prevLeft		;cx <- change in x from last
	sub	dx, ds:[di].DI_prevTop		;dx <- change in y from last
	mov	bp, ds:[di].DI_nDragCards	;bp <- # drag cards

	push	si

	tst	bp				;any drag cards?
	jz	endLoop

	;;Point to first child
	mov	si, ds:[si]			;load ^lbx:si with first child
	add	si, ds:[si].Vis_offset
	add	si, offset VCI_comp
;	mov	bx, ds:[si].CP_firstChild.handle
	mov	si, ds:[si].CP_firstChild.chunk
	
startLoop:
	dec	bp				;bp--
	tst	bp				;test for more drag cards 
	jl	endLoop				;if none, jump

	call	VisSetPositionRelative

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	add	si, offset VI_link

	mov	si, ds:[si].LP_next.chunk
	jmp	startLoop		;jump to start of loop

endLoop:

	pop	si

	pop	cx,dx
	mov	ax, MSG_DECK_UPDATE_DRAG		;update drag data
	call	ObjCallInstanceNoLock

	;
	;	See if the hilight status has changed.
	;
	;	Currently has visual bug
	;
	push	ax, bp, cx, dx
	mov	ax, MSG_GAME_CHECK_HILITES
	call	DeckCallParentWithSelf
	pop	ax, bx, cx, dx

	Deref_DI Deck_offset
	push	ds:[di].DI_dragHeight		;push height to stack

	mov	si, BLTM_MOVE
	push	si				;push BLTM_MOVE to stack

	mov	si, ds:[di].DI_dragWidth	;si <- width

	mov	di, ds:[di].DI_gState		;di <- gstate

	call	GrBitBlt			;do the move


	ret
DeckFullPtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckGetCatchBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_GET_CATCH_BOUNDS handler for DeckClass
		Returns the boundaries against which drag boundaries are
		tested.
		

CALLED BY:	

PASS:		*ds:si = instance data of deck
		
CHANGES:	nothing

RETURN:		ax = left of catch boundary
		bp = top of catch boundary
		cx = right of catch boundary
		dx = bottom of catch boundary

DESTROYED:	ax, bp, cx, dx

PSEUDO CODE/STRATEGY:
		currently, catch boundaries = vis boundaries, so this
		routine just passes the call on to MSG_VIS_GET_BOUNDS

KNOWN BUGS/IDEAS:
may want to change boundaries to be the bounds of just the first card in the
deck (i think the windows version does it this way)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckGetCatchBounds	method	DeckClass, MSG_DECK_GET_CATCH_BOUNDS
	;;for now, the catch bounds are the same as the vis bounds
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock
	ret
DeckGetCatchBounds	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckGetDragBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_GET_DRAG_BOUNDS handler for DeckClass
		Returns vis bounds of a deck's drag region

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck

CHANGES:	nothing

RETURN:		ax = left of drag region
		bp = top of drag region
		cx = right of drag region
		dx = bottom of drag region

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		loads in drag parameters and passes them to CovertWHLT2LTRB
		to get them into the proper format

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckGetDragBounds	method	DeckClass, MSG_DECK_GET_DRAG_BOUNDS
	mov	cx, ds:[di].DI_prevLeft
	mov	dx, ds:[di].DI_prevTop
	mov	ax, ds:[di].DI_dragWidth
	mov	bx, ds:[di].DI_dragHeight
	CONVERT_WHLT_TO_LTRB
	mov	bp, bx
	ret
DeckGetDragBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckGetDropCardAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_GET_DROP_CARD_ATTRIBUTES handler for DeckClass

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		
CHANGES:	nothing

RETURN:		bp = CardAttrs of the drop card
		The "drop card" is the card in a drag group whose attributes
		must be checked when determining the legality of a transfer
		For example, in the following drag group:

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

		the 6 of Hearts is the "drop card", because this group wants
		to find a black 7 to land on, and the red 6 is what dictates
		this criteria.  In general, the drop card is the last card
		in a drag group.

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		get attributes of card #(DI_nDragCards - 1)

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckGetDropCardAttributes   method   DeckClass, MSG_DECK_GET_DROP_CARD_ATTRIBUTES
	mov	bp, ds:[di].DI_nDragCards
	dec	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	ret
DeckGetDropCardAttributes	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckGetNthCardAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_GET_NTH_CARD_ATTRIBUTES handler for DeckClass
		Returns the attributes of the deck's nth card

CALLED BY:	

PASS:		bp = # of card to get attributes of (n=0 for top card)
		
CHANGES:	nothing

RETURN:		bp = attributes of nth card
		carry = clear for success

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckGetNthCardAttributes method	DeckClass, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	DeckCallNthChild
	ret
DeckGetNthCardAttributes	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckImplodeExplode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_IMPLODE_EXPLODE handler for DeckClass
		This is the effect of an illegal drop in outline dragging
		mode.  the outline of the drag region shinks to nothing
		(implodes), then an outline grows to the size of the drag,
		only relocated to where the drag began.

CALLED BY:	DeckRepairFailedTransfer

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		
CHANGES:	DI_dragOffset(X,Y) are changed to store the offset between
		the initial and final mouse coordinates of the drag

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		draw and erase a bunch of ever-shrinking outlines at the point
		where the cards were droped, then
		draw and erase a bunch of ever-growing outlines at the point
		where the cards were originally selected

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckImplodeExplode	method	DeckClass, MSG_DECK_IMPLODE_EXPLODE
	;draw first outline
	mov	cx, ds:[di].DI_prevLeft
	mov	dx, ds:[di].DI_prevTop

	; since we no longer need the info in DI_dragOffset(X,Y), we'll
	; use these slots to store the offset between the initial and final
	; mouse coordinates of the drag
	mov	ds:[di].DI_dragOffsetX, cx
	mov	ax, ds:[di].DI_initLeft
	sub	ds:[di].DI_dragOffsetX, ax

	mov	ds:[di].DI_dragOffsetY, dx
	mov	ax, ds:[di].DI_initTop
	sub	ds:[di].DI_dragOffsetY, ax
	call	ObjMarkDirty

	mov	ax, ds:[di].DI_dragWidth
	mov	bx, ds:[di].DI_dragHeight
	
	CONVERT_WHLT_TO_LTRB
	mov	di, ds:[di].DI_gState
	call	GrDrawRect		; draw the first outline
	clr	bp			; clear counter
startImplodeLoop:
	push	ax, bx, cx, dx	; old coords
	inc	ax		; increment left
	inc	bx		; increment top
	dec	cx		; decrement bottom
	dec	dx		; decrement right
	cmp	ax,cx
	jge	endImplodeLoop
	inc	bp		; increment the counter
	call	GrDrawRect	; draw the new outline
	pop	ax, bx, cx, dx	; restore old coords
	call	GrDrawRect	; erase the old outline
	inc	ax
	inc	bx		; shrink the outline
	dec	cx
	dec	dx
	jmp	startImplodeLoop	; loop back
endImplodeLoop:
	pop	ax, bx, cx, dx
	call	GrDrawRect	; erase last outline from imploding

	; reposition ourselves so we can explode where the dragging originated
	Deref_DI Deck_offset
	sub	ax, ds:[di].DI_dragOffsetX
	sub	bx, ds:[di].DI_dragOffsetY
	sub	cx, ds:[di].DI_dragOffsetX
	sub	dx, ds:[di].DI_dragOffsetY
	mov	di, ds:[di].DI_gState

	call	GrDrawRect	; draw initial outline
startExplodeLoop:
	push	ax, bx, cx, dx	; old coords
	dec	ax	;
	dec	bx	; grow the outline
	inc	cx	;
	inc	dx	;
	tst	bp
	jz	endExplodeLoop	
	dec	bp
	call	GrDrawRect	; draw new outline
	pop	ax, bx, cx, dx	; restore old coords
	call	GrDrawRect	; erase old outline
	dec	ax	;
	dec	bx	; grow the outline
	inc	cx	;
	inc	dx	;
	jmp	startExplodeLoop	; loop back
endExplodeLoop:
	pop	ax, bx, cx, dx	; restore old coords
	call	GrDrawRect	; erase last outline
	ret
DeckImplodeExplode	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckInvalidateInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_INVALIDATE_INIT handler for DeckClass
		Invalidates the initial drag area

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		creates a graphics state
		calculates initial drag area
		calls WinInvalRect on the area
		destroys th graphics state

KNOWN BUGS/IDEAS:
rename method to MSG_DECK_INVALIDATE_INIT_AREA

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckInvalidateInit	method	DeckClass, MSG_DECK_INVALIDATE_INIT
	tst	ds:[di].DI_gState
	jnz	clean

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	Deref_DI Deck_offset
	mov	ds:[di].DI_gState, bp
	call	ObjMarkDirty

clean:
	mov	bp, ds:[di].DI_gState
	push	bp
	mov	ax, MSG_DECK_CLEAN_AFTER_SHRINK
	call	ObjCallInstanceNoLock
	pop	bp

	tst	ds:[di].DI_nCards
	jz	drawMarker

	mov	ax, MSG_VIS_DRAW
	call	VisCallFirstChild
	jmp	done
drawMarker:
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
done:
	Deref_DI Deck_offset	
	clr	bp
	xchg	bp, ds:[di].DI_gState
	call	ObjMarkDirty
	mov	di, bp
	call	GrDestroyState
	ret
DeckInvalidateInit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckCleanAfterShrink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_CLEAN_AFTER_SHRINK handler for DeckClass
		This method invalidates the portion of a deck's original
		vis bounds that was clipped as a result of the deck
		shinking.
		(i.e., Let A = original deck bounds, B = new deck bounds:
			this method invalidates A - B)


CALLED BY:	

PASS:		bp = gstate to invalidate through.
		
		Also:
			DI_initRight and DI_initBottom should contain
			the right, bottom coordinates of the deck BEFORE
			any shrinking occurred.
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckCleanAfterShrink	method	DeckClass, MSG_DECK_CLEAN_AFTER_SHRINK
	push	bp
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock
	mov	bx, bp
	pop	bp
	Deref_DI Deck_offset
	cmp	cx, ds:[di].DI_initRight		;see if new right < old right
	jge	checkHeights
	push	ax, bx, cx, dx
	mov	ax, cx				;ax <- new right + 1
;	inc	ax
	mov	cx, ds:[di].DI_initRight		;cx <- old right
	mov	dx, ds:[di].DI_initBottom		;dx <- old top
	mov	di, bp
	call	GrInvalRect
	pop	ax, bx, cx, dx
checkHeights:
	Deref_DI Deck_offset
	cmp	dx, ds:[di].DI_initBottom
	jge	done
	mov	bx, dx
;	inc	bx
	mov	cx, ds:[di].DI_initRight		;cx <- old right
	mov	dx, ds:[di].DI_initBottom		;dx <- old top
	sub	bx, 2					; bx = top
	mov	di, bp
	call	GrInvalRect
done:
	ret
DeckCleanAfterShrink	endm	

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckMoveAndClip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_MOVE_AND_CLIP handler for DeckClass
		Prepares the deck to push a card into its composite.
		The data in DI_topCardLeft and DI_topCardTop are changed
		to reflect the new card coming, and the vis bounds of the
		current	top card are clipped.

CALLED BY:	

PASS:		*ds:si = instance data of deck
		
CHANGES:	DI_topCard(Left,Top) are updated via DeckOffsetTopLeft
		Deck's vis bounds are stretched to cover all cards
		Deck's top card's vis bounds are clipped	

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		bundle calls to MSG_DECK_OFFSET_TOP_LEFT,
				MSG_DECK_STRETCH_BOUNDS

KNOWN BUGS/IDEAS:
i'm not sure why i put MSG_DECK_STRETCH_BOUNDS here.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckMoveAndClip		method	DeckClass, MSG_DECK_MOVE_AND_CLIP
	;
	;	We need to update our records regarding the origin of
	;	the deck's top card.
	;
	;	cx <- amount added to DI_topCardLeft
	;	dx <- amount added to DI_topCardTop
	;
	mov	ax, MSG_DECK_OFFSET_TOP_LEFT
	call	ObjCallInstanceNoLock
					
	;
	;	Stretch the deck by the amount that the new card is offset
	;	from the old top card
	;
	push	cx,dx
	mov	ax, MSG_DECK_STRETCH_BOUNDS
	call	ObjCallInstanceNoLock
	pop	cx,dx

	;
	;	Clip the vis bounds of the deck's top card
	;
	mov	bp, 0
	mov	ax, MSG_DECK_CLIP_NTH_CARD
	call	ObjCallInstanceNoLock
	ret
DeckMoveAndClip	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckOffsetTopLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_OFFSET_TOP_LEFT handler for DeckClass
		Adds offsets to the deck's information about the origin of its
		top card.

CALLED BY:	

PASS:		*ds:si = instance data of deck
		
CHANGES:	DI_topCardLeft and DI_topCardTop are offset by
		DI_offsetFrom[Up|Down]Card[X|Y]

RETURN:		cx = offset added to DI_topCardLeft
		dx = offset added to DI_topCardTop

DESTROYED:	bp, cx, dx, di

PSEUDO CODE/STRATEGY:
		get attributes of first child
		if no children, clear cx,dx and return
		else use attributes to determine whether we want
		UpCard or DownCard offsets, then add them

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckOffsetTopLeft	method		DeckClass, MSG_DECK_OFFSET_TOP_LEFT
	clr	bp
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	VisCallFirstChild
	tst	bp			;see if we got anything back (i.e.,
					;see if we have any children)
	jnz	gotTopCardAttrs		;if so, we've got its attributes in bp

;noKids:
	clr	cx			;no kids, so no offsets
	clr	dx
	jmp	endDeckOffsetTopLeft

gotTopCardAttrs:
	Deref_DI Deck_offset
	test	bp, mask CA_FACE_UP
	jz	faceDown
;faceUp:	
	mov	cx, ds:[di].DI_offsetFromUpCardX	;if the card is face up
	mov	dx, ds:[di].DI_offsetFromUpCardY	;we want up offsets
	jmp	addOffsets

faceDown:
	mov	cx, ds:[di].DI_offsetFromDownCardX	;if card is face down,
	mov	dx, ds:[di].DI_offsetFromDownCardY	;we want down offsets

addOffsets:
	add	ds:[di].DI_topCardLeft, cx	;add the offsets to the topCard
	add	ds:[di].DI_topCardTop, dx	;position
	call	ObjMarkDirty

endDeckOffsetTopLeft:
	ret
DeckOffsetTopLeft	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckOutlinePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_OUTLINE_PTR handler for DeckClass
		Handles a new mouse event during a drag under outline
		dragging.

CALLED BY:	DeckPtr

PASS:		*ds:si = instance data of deck
		cx,dx = mouse position
		
CHANGES:	instance data in the deck is changed to reflect new mouse
		coordinates, old outline is erased, new outline is drawn

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		erase old outline
		update drag data
		draw new outline

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckOutlinePtr	method	DeckClass, MSG_DECK_OUTLINE_PTR
	push	cx,dx				;save mouse

	mov	ax, MSG_DECK_DRAW_DRAG_OUTLINE	;erase old outline
	call	ObjCallInstanceNoLock

	pop	cx,dx				;restore mouse

	mov	ax, MSG_DECK_UPDATE_DRAG		;update drag data
	call	ObjCallInstanceNoLock

	mov	ax, MSG_DECK_DRAW_DRAG_OUTLINE	;draw new outline
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GAME_CHECK_HILITES
	call	DeckCallParentWithSelf

	ret
DeckOutlinePtr	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckPopAllCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_POP_ALL_CARDS handler for DeckClass
		Pops all of a deck's cards to another deck. Relative
		order of the cards is reversed.
		
CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		^lcx:dx = instance of VisCompClass to receive the cards
		(usually another Deck)
		
CHANGES:	Deck's cards popped to deck in ^lcx:dx

RETURN:		nothing

DESTROYED:	ax, bp, di

PSEUDO CODE/STRATEGY:
		sends self a MSG_DECK_POP_N_CARDS with n = total # of cards

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckPopAllCards	method	DeckClass, MSG_DECK_POP_ALL_CARDS
	mov	bp, ds:[di].DI_nCards
	mov	ax, MSG_DECK_POP_N_CARDS		;set bp = total cards and
	call	ObjCallInstanceNoLock		;pop 'em all
	ret
DeckPopAllCards	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckPopCard				
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_POP_CARD handler for DeckClass
		Remove deck's top card from deck's composite.

CALLED BY:	

PASS:		*ds:si = instance data of deck
		
CHANGES:	if deck has children:
			its top card is removed from the vis tree

RETURN:		if deck has children:
			carry clear
			^lcx:dx = popped card
		if not:
			carry set

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckPopCard		method		DeckClass, MSG_DECK_POP_CARD
	clr	cx
	clr	dx
	mov	ax, MSG_DECK_REMOVE_NTH_CARD	;remove 1st card
	call	ObjCallInstanceNoLock
	ret
DeckPopCard		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckPopNCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_POP_N_CARDS handler for DeckClass
		Give a certain number of cards to another deck by popping
		them off, and pushing them onto the other deck.

CALLED BY:	

PASS:		*ds:si = instance data of deck
		bp = number of cards to transfer
		^lcx:dx = instance of VisCompClass to receive the cards
		(usually another Deck)
		
CHANGES:	The top bp cards of deck at *ds:si are popped
		to the top of deck at ^lcx:dx. The order of the cards is
		reversed (i.e., the top card of the donor will be the bp'th
		card of the recipient).

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
		loops bp times, popping cards (starting with the 0th, ending
		with the bp'th) from the donor and pushing them to the
		recipient

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckPopNCards	method	DeckClass, MSG_DECK_POP_N_CARDS
startLoop:
	dec	bp		;done yet?
	js	endLoop		;if so, end

	push	bp		;total left to pop

	push	cx, dx		;save OD of recipient
	mov	ax, MSG_DECK_POP_CARD
	call	ObjCallInstanceNoLock

	mov	bp, si			;save deck chunk in bp
	pop bx, si			;restore OD of recipient
	push	bp			;push deck chunk to stack
	push	bx, si			;save OD of recipient
	mov	ax, MSG_DECK_PUSH_CARD	;give card to recipient
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx			;restore OD of recipient
	pop	si			;restore deck chunk
	pop	bp			;restore cards left to pop
	jmp	startLoop

endLoop:
	ret

DeckPopNCards	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_PTR handler for DeckClass

CALLED BY:	

PASS:		*ds:si = instance data of deck
		cx,dx = mouse position
		bp = ButtonInfo
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		depending on the drag type, passes the call on to either
		MSG_DECK_OUTLINE_PTR or MSG_DECK_FULL_PTR

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckPtr		method		DeckClass, MSG_META_PTR
;	test	bp, mask BI_B0_DOWN or mask BI_B2_DOWN
;						;see if  button is still down
;	jz	endDeckPtr			;if not, end

	;
	;	We'll test the gstate to see whether or not the user is
	;	dragging. Could also just test DI_nDragCards.
	;
	tst	ds:[di].DI_gState		;see if we have a gstate (i.e.,
						;if we're dragging)
	jz	endDeckPtr			;if not, end

 	push	cx,dx				;save mouse position

	;; see what kind of drag we're supposed to be doing
;	CallObject MyPlayingTable, MSG_GAME_GET_DRAG_TYPE, MF_CALL

	mov	ax, MSG_GAME_GET_DRAG_TYPE
	call	VisCallParent


	cmp	cl, DRAG_OUTLINE
	pop	cx,dx				;restore mouse position
	jne	fullDragging

;outlineDragging:
	mov	ax, MSG_DECK_OUTLINE_PTR		;dispatch call to outline ptr
	call	ObjCallInstanceNoLock
	jmp	endDeckPtr

fullDragging:
	mov	ax, MSG_DECK_FULL_PTR		;dispatch call to full ptr
	call	ObjCallInstanceNoLock

endDeckPtr:
	mov	ax, mask MRF_PROCESSED		;the ptr event has been
						;processed

	ret
DeckPtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckPushCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_PUSH_CARD, MSG_DECK_PUSH_CARD_NO_EFFECTS handler
		for DeckClass
		Adds a card to the deck's composite, and does some visual
		operations that reflect the adoption. The two methods
		are identical at this level, but exist independently so
		they can be subclassed differently.

CALLED BY:	

PASS:		*ds:si = instance data of deck
		^lcx:dx = card to be added
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		[0] self-call MSG_DECK_MOVE_AND_CLIP
		[1] self-call MSG_DECK_ADD_CARD_FIRST
		[2] send added card MSG_CARD_SET_NOT_DRAWABLE
		[3] send added card MSG_CARD_SET_DRAWABLE via queue
		[4] send added card MSG_CARD_FADE_REDRAW via queue

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckPushCard   method  DeckClass, MSG_DECK_PUSH_CARD, MSG_DECK_PUSH_CARD_NO_EFFECTS
	push	cx,dx				;save card OD
	mov	ax, MSG_DECK_MOVE_AND_CLIP	;prepare to push card
	call	ObjCallInstanceNoLock
	pop	cx,dx				;restore card OD

	push	cx, dx				;save card OD
	mov	ax, MSG_DECK_ADD_CARD_FIRST	;push it
	call	ObjCallInstanceNoLock

	Deref_DI Deck_offset
	mov	dx, ds:[di].DI_pushPoints
	tst	dx
	jz	afterScore
	clr	cx

	mov	ax, MSG_GAME_UPDATE_SCORE
	call	VisCallParent

afterScore:	
	pop bx, si				;restore card OD

	mov	ax, MSG_CARD_SET_DRAWABLE
	mov	di, mask MF_FIXUP_DS		; or mask MF_FORCE_QUEUE
	call	ObjMessage
	
	mov	ax, MSG_CARD_NORMAL_REDRAW
	mov	di, mask MF_FIXUP_DS		; or mask MF_FORCE_QUEUE
	GOTO	ObjMessage
DeckPushCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_REDRAW handler for DeckClass

CALLED BY:	

PASS:		*ds:si = instance data of deck
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		generates a graphics state
		issues a MSG_VIS_DRAW to self
		destroys the graphics state

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRedraw	method		DeckClass, MSG_DECK_REDRAW
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	tst	bp
	jz	endDeckRedraw

	;;draw it
	push	bp
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock

	;;destroy the graphics state
	pop	di
	call	GrDestroyState
	
endDeckRedraw:
	ret
DeckRedraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckRemoveNthCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_REMOVE_NTH_CARD method handler for DeckClass
		Removes a card from the deck's composite
		
CALLED BY:	DeckPopCard, others

PASS:		*ds:si = instance data of deck
		^lcx:dx = child to remove
			- or -
		if cx = 0, dx = nth child to remove (0 = first child)
		
CHANGES:	if deck has children:
			the card indicated by cx,dx is removed 
			from the vis tree and DI_nCards
			is updated accordingly

RETURN:		if deck has children:
			carry clear
			^lcx:dx = removed card
		if not:
			carry set

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		locates the child
		removes it
		gets its attrs
		decrements n[Up|Down]Cards depending on attributes

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRemoveNthCard	method		DeckClass, MSG_DECK_REMOVE_NTH_CARD
	;;cx:dx = number of child to remove (for pop, cx=dx=0)
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock

	jc	cantFindNthCard

	;;now ^lcx:dx = nth child
	
	mov	bp, mask CCF_MARK_DIRTY
	mov	ax, MSG_VIS_REMOVE_CHILD
	call	ObjCallInstanceNoLock

;endDeckRemoveNthCard:
	push	cx,dx

	mov	dx, ds:[di].DI_popPoints
	tst	dx
	jz	afterScore

	clr	cx
;	CallObject	MyPlayingTable, MSG_GAME_UPDATE_SCORE, MF_FIXUP_DS

	mov	ax, MSG_GAME_UPDATE_SCORE
	call	VisCallParent

afterScore:
	mov	ax, MSG_DECK_UPDATE_TOPLEFT
	call	ObjCallInstanceNoLock
	pop	cx,dx

	clc	; clear carry to denote that we popped a card

cantFindNthCard:
	ret

DeckRemoveNthCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckRemoveVisChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_REMOVE_CHILD handler for DeckClass
		This method is subclassed from VisCompClass so that we can
		update the number of cards we have.

CALLED BY:	

PASS:	ds:di = deck instance
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_REMOVE_CHILD
	bp - mask CCF_MARK_DIRTY set if parent and siblings should be dirtied
	     appropriately

	cx:dx - child to remove

		
CHANGES:	card ^lcx:dx is removed from the deck's composite, DI_nCards
		is decremented accordingly

RETURN:		nothing

DESTROYED:	
	ax, bx, cx, dx, bp, si, di, ds, es

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/19/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRemoveVisChild	method	DeckClass, MSG_VIS_REMOVE_CHILD
	dec	ds:[di].DI_nCards
	call	ObjMarkDirty
	mov	di, offset DeckClass
	call	ObjCallSuperNoLock
	ret
DeckRemoveVisChild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckAddVisChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_ADD_CHILD handler for DeckClass
		This method is subclassed from VisCompClass so that we can
		update the number of cards we have.

CALLED BY:	

PASS:	ds:di = deck instance
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_ADD_CHILD

	cx:dx  - object to add
	bp - CompChildFlags
		
CHANGES:	card ^lcx:dx is added from the deck's composite, DI_nCards
		is incremented accordingly

RETURN:		nothing

DESTROYED:	
	ax, bx, cx, dx, bp, si, di, ds, es

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/19/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckAddVisChild	method	DeckClass, MSG_VIS_ADD_CHILD
	inc	ds:[di].DI_nCards
	call	ObjMarkDirty
	mov	di, offset DeckClass
	GOTO	ObjCallSuperNoLock
DeckAddVisChild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckRepairFailedTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_REPAIR_FAILED_TRANSFER handler for DeckClass
		Fixes up the state of affairs (both visual and internal)
		when cards are dropped and no deck accepts them.

CALLED BY:	DeckDropDrags

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		[0] clip the vis bounds of the top *UN*dragged card in the deck
			to prepare for the return of the dragged cards
		[1] get drag type from playing table
		[2] check to see if there was any mouse movement
			if no mouse movement:
				jump to the end
		[outline dragging 3] issue self a MSG_DECK_IMPLODE_EXPLODE
		[outline dragging 4] jump to end
		[full dragging 3] move the dragged cards back to their original
				  positions
		[full dragging 4] set the cards *NOT* drawable

we queue the calls in [5] and [6] so that the MSG_META_EXPOSED generated by the
call to WinInvalRect in DeckEndSelect can occur before [5] and [6]

		[full dragging 5] queue call to set drag cards drawable
		[full dragging 6] queue call to fade redraw drag cards

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRepairFailedTransfer 	method DeckClass, MSG_DECK_REPAIR_FAILED_TRANSFER

	;;the card below the drop card has been set to full size, so we must
	; re-clip its bounds to prepare for the return of the drag cards
	mov	bp, ds:[di].DI_nDragCards
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	DeckCallNthChild

	Deref_DI Deck_offset
	test	bp, mask CA_FACE_UP
	jnz	faceUp
;faceDown:
	mov	cx, ds:[di].DI_offsetFromDownCardX
	mov	dx, ds:[di].DI_offsetFromDownCardY
	jmp	clipCard
faceUp:
	mov	cx, ds:[di].DI_offsetFromUpCardX
	mov	dx, ds:[di].DI_offsetFromUpCardY
clipCard:
	mov	bp, ds:[di].DI_nDragCards
	mov	ax, MSG_DECK_CLIP_NTH_CARD
	call	ObjCallInstanceNoLock

	Deref_DI Deck_offset
	mov	cx, ds:[di].DI_initLeft
	mov	dx, ds:[di].DI_initTop
	sub	cx, ds:[di].DI_prevLeft	;cx <- total horizontal travel
	sub	dx, ds:[di].DI_prevTop	;dx <- total vertical travel
	jnz	notifyGame		;if we moved vertically, fixup
	jcxz	endRepair		;if we haven't moved, don't fixup

notifyGame:
	push	cx, dx
	mov     dx, si
	mov	cx, ds:[LMBH_handle]    ;^lcx:dx - self
        mov     ax, MSG_GAME_TRANSFER_FAILED
        call    VisCallParent

;checkType:
;	CallObject MyPlayingTable, MSG_GAME_GET_DRAG_TYPE, MF_CALL

	mov	ax, MSG_GAME_GET_DRAG_TYPE
	call	VisCallParent

	cmp	cl, DRAG_OUTLINE
	pop	cx, dx
	jne	failedFull

;failedOutline:
	tst	cx
	jge	checkHorizDisp
	neg	cx
checkHorizDisp:
	cmp	cx, MINIMUM_HORIZONTAL_DISPLACEMENT
	jg	implodeExplode

	tst	dx
	jge	checkVertDisp
	neg	dx
checkVertDisp:
	cmp	dx, MINIMUM_VERTICAL_DISPLACEMENT
	jle	endRepair

implodeExplode:
	mov	ax, MSG_DECK_IMPLODE_EXPLODE	;funky outline effect
	call	ObjCallInstanceNoLock
	jmp	endRepair

failedFull:
	mov	bp, MSG_CARD_MOVE_RELATIVE	;move drag cards back to where
	mov	di, mask MF_FIXUP_DS		;they came from
	call	DeckCallDrags

	mov	bp, MSG_CARD_SET_NOT_DRAWABLE	; set drags not drawable, so
	mov	di, mask MF_FIXUP_DS		; that when the area is cleaned
	call	DeckCallDrags			; up, they don't appear

	mov	bp, MSG_CARD_SET_DRAWABLE		; by queueing this request, we
						; make sure that WinInvalRect
						; is done before redrawing
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	DeckCallDrags

	mov	bp, MSG_CARD_FADE_REDRAW
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	DeckCallDrags

endRepair:

	;; Telling the game object that no deck is dragging anymore
	;; used to be handled at the end of DeckEndDrag, but that
	;; handler generated methods that needed to be handled before
	;; we can really say that there is no more dragger.
	;; Accordingly, the sent MSG_GAME_REGISTER_DRAG has been moved to
	;; the end of DeckRepairFailedTransfer and DeckRepairSuccessfulTransfer

	clr	cx
	clr	dx
	mov	ax, MSG_GAME_REGISTER_DRAG
	call	VisCallParent

	ret
DeckRepairFailedTransfer	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckCallDrags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a method to a deck's dragging cards. Used for
		stuff like sending a method to move to all the dragging
		cards, etc.

CALLED BY:	DeckRepairFailedTransfer

PASS:		*ds:si = instance data of deck
		bp = method number
		cx, dx = other data
		di = flags for ObjMessage
		
CHANGES:	the dragged cards (= the first DI_nDragCards) are
		called with message #bp and data cx,dx

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
	jon	10/90		merged two methods into one fuunction
				by letting the user pass in his own
				ObjMessage flags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckCallDrags	proc	near
	class	DeckClass
	push	si
	mov	ax, bp				;ax <- method #
	push	di
	Deref_DI Deck_offset
	mov	bp, ds:[di].DI_nDragCards	;bp <- # drag cards

	tst	bp				;any drag cards?
	pop	di
	jz	endLoop
	push	di
	;;set ^lbx:si to first child

	mov	si, ds:[si]			;load ^lbx:si with first child
	add	si, ds:[si].Vis_offset
	add	si, offset VCI_comp
	mov	bx, ds:[si].CP_firstChild.handle
	mov	si, ds:[si].CP_firstChild.chunk
	
startLoop:
	;;test for completion

	pop	di
	dec	bp				;decrement the number of cards
						;left to process
	tst	bp
	jl	endLoop				;if no more drag cards, jump

	;; make the call

	push	di
	call	ObjMessage		;make the call

	;;get the next child to process

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	add	si, offset VI_link

	mov	bx, ds:[si].LP_next.handle	;load ^lbx:si with next child
	mov	si, ds:[si].LP_next.chunk
	jmp	startLoop		;jump to start of loop

endLoop:
	pop	si
	ret

DeckCallDrags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckRepairSuccessfulTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_REPAIR_SUCCESSFUL_TRANSFER handler for DeckClass
		fixes up the visual state of affairs when cards are dropped
		successfully (i.e., the dragged cards are accepted by another
		deck).

CALLED BY:	DeckDropDrags

PASS:		*ds:si = instance data of deck
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		maximizes bounds of new top card, and issues a
		MSG_UPDATE_TOP_LEFT to self.

KNOWN BUGS/IDEAS:
		this method is really only necessary for outline dragging,
		but doesn't hurt in full dragging, and it's faster just
		to do it anyway.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRepairSuccessfulTransfer method DeckClass,MSG_DECK_REPAIR_SUCCESSFUL_TRANSFER
	mov	ax, MSG_CARD_MAXIMIZE		;make sure top card is now
	call	VisCallFirstChild		;set to full size

	clr	cx
	clr	dx
	mov	ax, MSG_GAME_REGISTER_DRAG
	call	VisCallParent

	mov	ax, MSG_DECK_INVALIDATE_INIT
	call	ObjCallInstanceNoLock
	ret
DeckRepairSuccessfulTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckRequestBlankCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_REQUEST_BLANK_CARD handler for DeckClass
		Draws a blank card at the specified location.

CALLED BY:	

PASS:		cx,dx = origin of blank card
		bp = gstate
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
should be turned into a VUQ in the game object, maybe?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRequestBlankCard	method	DeckClass, MSG_DECK_REQUEST_BLANK_CARD
	mov	ax, MSG_GAME_DRAW_BLANK_CARD
	call	VisCallParent
	ret
DeckRequestBlankCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckRequestFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_REQUEST_FRAME handler for DeckClass
		Draws a card frame at the specified location.

CALLED BY:	

PASS:		cx,dx = origin of blank card
		bp = gstate
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
should be turned into a VUQ in the game object, maybe?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRequestFrame	method	DeckClass, MSG_DECK_REQUEST_FRAME
	mov	ax, MSG_GAME_DRAW_FRAME
	call	VisCallParent
	ret
DeckRequestFrame	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckRequestFakeBlankCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_REQUEST_FAKE_BLANK_CARD handler for DeckClass
		Deck makes a request to the game object to draw a fake
		blank card at the specified position.

		A fake blank card is simply a black-bordered white rectangle
		the size of a card.

CALLED BY:	

PASS:		cx,dx = where to draw fake blank card
		bp = gstate
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRequestFakeBlankCard method	DeckClass, MSG_DECK_REQUEST_FAKE_BLANK_CARD
	mov	ax, MSG_GAME_FAKE_BLANK_CARD
	call	VisCallParent
	ret
DeckRequestFakeBlankCard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckStretchBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_STRETCH_BOUNDS handler for DeckClass
		Widens (or shrinks) a deck's vis bounds by a certain amount.

CALLED BY:	

PASS:		*ds:si = instance data of deck
		cx = incremental width
		dx = incremental height
		
CHANGES:	deck's vis dimensions are increased by cx,dx

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		get size
		add increments to size
		resize

KNOWN BUGS/IDEAS:
maybe turn into VisStretch?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckStretchBounds	method		DeckClass, MSG_DECK_STRETCH_BOUNDS
	push	cx, dx			;save increments
	mov	ax, MSG_VIS_GET_SIZE	;get current size
	call	ObjCallInstanceNoLock
	pop	ax, bx

	add	cx, ax			;add in increments
	add	dx, bx
	mov	ax, MSG_VIS_SET_SIZE	;resize
	call	ObjCallInstanceNoLock
	ret

DeckStretchBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckTakeCardsIfOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_TAKE_CARDS_IF_OK handler for DeckClass
		Determines whether a deck will accept a drop from another
		deck.  If so, issues a MSG_DECK_TRANSFER_DRAGGED_CARDS to
		the donor.

CALLED BY:	

PASS:		*ds:si = instance data of deck
		bp = CardAttr of the drop card (bottom card in the drag)
		^lcx:dx = potential donor deck
		
CHANGES:	If the transfer is accepted, the deck with OD ^lcx:dx
		transfers #DI_nDragCards cards to the deck

RETURN:		carry set if transfer occurs,
		carry clear if not

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		calls TestAcceptCards
		if deck accepts, issues a MSG_DECK_TRANSFER_DRAGGED_CARDS
		to donor

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckTakeCardsIfOK	method		DeckClass, MSG_DECK_TAKE_CARDS_IF_OK
	push	cx,dx				;save donor OD

	mov	ax, MSG_DECK_TEST_ACCEPT_CARDS
	call	ObjCallInstanceNoLock

	jc	willAccept		

;wontAccept:
	add	sp, 4				;clear OD off stack
	jmp	endDeckTakeCardsIfOK

willAccept:

	;;get drag type
;	CallObject	MyPlayingTable, MSG_GAME_GET_DRAG_TYPE, MF_CALL

	mov	ax, MSG_GAME_GET_DRAG_TYPE
	call	VisCallParent
	

	cmp	cl, DRAG_OUTLINE
	pop	cx,dx				;restore donor OD
	jne	transferCards

	;;tell donor to invalidate the initial drag area if we in outline mode
;	CallObjectCXDX	MSG_DECK_INVALIDATE_INIT, MF_FIXUP_DS

transferCards:
	mov	bx, ds:[LMBH_handle]
	xchg	bx, cx
	xchg	si, dx
							;^lbx:si = donor
							;^lcx:dx = recipient
	mov	ax, MSG_DECK_TRANSFER_DRAGGED_CARDS	;do the transfer
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	stc						;indicate that we took
							;the cards
endDeckTakeCardsIfOK:
	ret

DeckTakeCardsIfOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckTakeDoubleClickIfOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_TAKE_DOUBLE_CLICK_IF_OK handler for DeckClass
		Determines whether a deck wil accept a double click from
		another	deck.  If so, issues a MSG_DECK_TRANSFER_DRAGGED_CARDS
		to the donor.

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		bp = CardAttr of the double clicked card
		^lcx:dx = potential donor deck
		
CHANGES:	nothing

RETURN:		carry set if card(s) are accepted elsewhere

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		since only a foundation should be accepting a double click,
		this default routine returns carry clear, indicating no
		transfer.  See FoundationTakeDoubleClickIfOK for something
		more exciting.

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckTakeDoubleClickIfOK	method	DeckClass, MSG_DECK_TAKE_DOUBLE_CLICK_IF_OK

	test	ds:[di].DI_deckAttrs, mask DA_IGNORE_EXPRESS_DRAG
	jnz	endDeckTakeDoubleClickIfOK

	push	cx,dx					;save OD of donor
;	mov	ax, MSG_DECK_TEST_RIGHT_CARD		;check if right card
;	call	ObjCallInstanceNoLock

	mov	ax, MSG_DECK_GET_COMPARISON_KIT
	call	ObjCallInstanceNoLock

	pop	cx,dx
	push	cx,dx					;save OD of donor

	call	Test4RightCard
	pop	cx,dx					;restore OD of donor
	jc	willAccept

;wontAccept:
	jmp	clearCarry

willAccept:
;	CallObjectCXDX	MSG_DECK_INVALIDATE_INIT, MF_FIXUP_DS	;inval. donor

	mov	bx, ds:[LMBH_handle]
	xchg	bx, cx					;^lbx:si <- donor
	xchg	si, dx					;^lcx:dx <- acceptor
	mov	ax, MSG_DECK_TRANSFER_DRAGGED_CARDS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	stc						;we've taken the cards
	jmp	endDeckTakeDoubleClickIfOK

clearCarry:
	clc						;we didn't take cards
endDeckTakeDoubleClickIfOK:
	ret
DeckTakeDoubleClickIfOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckInvertSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_INVERT handler for DeckClass
		Deck visually inverts itself (its top card if it has one,
		its marker if not).

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = deck object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		if (deck has cards) {
			tell top card to invert itself;
		}
		else {
			create a gstate;
			set draw mode to MM_INVERT;
			get deck's vis bounds;
			invert the bounds;
			destroy gstate;
		}

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckInvertSelf	method	DeckClass, MSG_DECK_INVERT

	TOGGLE	ds:[di].DI_deckAttrs, DA_INVERTED
	call	ObjMarkDirty

	tst	ds:[di].DI_nCards
	jz	invertMarker

	mov	ax, MSG_CARD_INVERT
	call	VisCallFirstChild
	jmp	endDeckInvertSelf
invertMarker:

ifdef	I_DONT_REALLY_LIKE_THIS_EFFECT

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp

	mov	al, MM_INVERT
	call	GrSetMixMode			;set invert mode

	push	di	
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock

	mov	bx, bp
	pop	di

	call	GrFillRect

	call	GrDestroyState
endif
endDeckInvertSelf:
	ret
DeckInvertSelf	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckClearInverted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_CLEAR_INVERTED handler for DeckClass

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = deck object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	19 feb 92	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckClearInverted	method	DeckClass, MSG_DECK_CLEAR_INVERTED

	test	ds:[di].DI_deckAttrs, mask DA_INVERTED
	jz	done

	RESET	ds:[di].DI_deckAttrs, DA_INVERTED
	call	ObjMarkDirty

	tst	ds:[di].DI_nCards
	jz	done			;	jz	clearMarker
	
	mov	ax, MSG_CARD_CLEAR_INVERTED
	call	VisSendToChildren

ifdef	I_DONT_REALLY_LIKE_THIS_EFFECT

	jmp	done
clearMarker:
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
endif
done:
	ret
DeckClearInverted	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckInvertIfAccept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_INVERT_IF_ACCEPT handler for DeckClass.
		Deck visually inverts itself (or its top card, if any) if
		its DA_WANTS_DRAG bit is set.

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = deck object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		if (ds:[di].DI_deckAttrs && mask DA_WANTS_DRAG)
			send self MSG_DECK_INVERT

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckInvertIfAccept	method	DeckClass, MSG_DECK_INVERT_IF_ACCEPT
	test	ds:[di].DI_deckAttrs, mask DA_WANTS_DRAG
	jz	endDeckInvertIfAccept

	mov	ax, MSG_DECK_INVERT
	call	ObjCallInstanceNoLock

endDeckInvertIfAccept:
	ret
DeckInvertIfAccept	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckMarkIfAccept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_MARK_IF_ACCEPT handler for DeckClass
		This method sets the DA_WANTS_DRAG bit in the DeckAttrs
		iff the deck would accept the drag set from the passed dragger.

CALLED BY:	

PASS:		^lcx:dx = dragging deck
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
			

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckMarkIfAccept	method	DeckClass, MSG_DECK_MARK_IF_ACCEPT
	mov	ax, MSG_DECK_TEST_RIGHT_CARD
	call	ObjCallInstanceNoLock
	jnc	noAccept
;accept:
	Deref_DI Deck_offset
	SET	ds:[di].DI_deckAttrs, DA_WANTS_DRAG
	call	ObjMarkDirty
	jmp	endDeckMarkIfAccept
noAccept:
	Deref_DI Deck_offset
	RESET	ds:[di].DI_deckAttrs, DA_WANTS_DRAG
	call	ObjMarkDirty
endDeckMarkIfAccept:
	ret
DeckMarkIfAccept	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckCheckPotentialDrop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_CHECK_POTENTIAL_DROP handler for DeckClass
		Checks to see whether this deck would accept the drag
		if it were to be dropped right now. If it would, it sends
		a MSG_GAME_REGISTER_HILITED to the game object with its own OD.

CALLED BY:	

PASS:		*ds:si = deck object
		^lcx:dx = dragging deck
		
CHANGES:	

RETURN:		carry set if deck would accept cards

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckCheckPotentialDrop method	DeckClass, MSG_DECK_CHECK_POTENTIAL_DROP
	mov	ax, MSG_DECK_TEST_ACCEPT_CARDS
	call	ObjCallInstanceNoLock

	jnc	endDeckCheckPotentialDrop

	mov	ax, MSG_GAME_REGISTER_HILITED
	call	DeckCallParentWithSelf

	stc
endDeckCheckPotentialDrop:
	ret
DeckCheckPotentialDrop endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckTestAcceptCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_TEST_ACCEPT_CARDS handler for DeckClass
		Tests deck to see whether a set of dragged cards
		would be accepted to the drag if it were dropped right
		now (i.e., rank&suit are ok, and position is ok).

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		^lcx:dx = potential donor deck

CHANGES:	

RETURN:		carry set if deck would accept cards,
		carry clear otherwise

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		calls TestRightCard to see if the card type is correct
		calls CheckDragCaught to see if the bounds are correct

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckTestAcceptCards	method	DeckClass, MSG_DECK_TEST_ACCEPT_CARDS
	test	ds:[di].DI_deckAttrs, mask DA_WANTS_DRAG
	jz	endTest

	mov	ax, MSG_DECK_CHECK_DRAG_CAUGHT	;see if the drag area is in the
	call	ObjCallInstanceNoLock		;right place

endTest:
	;;the carry bit will now be set if the deck will accept the cards
	ret

DeckTestAcceptCards	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckTestRightCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_TEST_RIGHT_CARD handler for DeckClass
		Checks to see if the deck would accept the drag set from
		the passed deck (i.e., see if the catch card of this
		deck would take the drop card fom the drag deck).

CALLED BY:	

PASS:		^lcx:dx = dragging deck
		
CHANGES:	nothing

RETURN:		carry set if deck will accept card	
		carry clear else

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckTestRightCard	method	DeckClass, MSG_DECK_TEST_RIGHT_CARD
	push	cx,dx
	mov	ax, MSG_DECK_GET_COMPARISON_KIT	;get the info needed to
	call	ObjCallInstanceNoLock		;check for acceptance
	pop	cx,dx
	FALL_THRU	Test4RightCard
DeckTestRightCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				Test4RightCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see whether a deck has the appropriate catch card
		to take the drag from the dragging deck.

CALLED BY:	

PASS:		*ds:si = deck object
			^lcx:dx = potential donor deck
			bp = ComparisonKit of *ds:si deck
		
CHANGES:	

RETURN:		carry set if the deck's catch card would catch the dragging
		deck's drag card

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Test4RightCard	proc	far
	class	DeckClass

	;
	;	if there is a restriction on the number of cards that
	;	a deck can catch at any one time (such as the case of
	;	klondike's foundations, which only accept a drag of
	;	size one), then we must check that here.
	;
	test	bp, mask CAC_SINGLE_CARD_ONLY shl offset CK_CAC
	jz	testSuit

	;
	;	We want to access data from the deck at ^lcx:dx, so we'll
	;	lock its block, get the info, then swap back out.
	;
	mov	bx, cx				;bx <- block handle of dragger
	call	ObjSwapLock			;ds <- segment of dragger,
						;bx <- block handle of the
						;	deck we're checking
	mov	di, dx
	mov	di, ds:[di]
	add	di, ds:[di].Deck_offset

	cmp	ds:[di].DI_nDragCards, 1
	call	ObjSwapLock			;restore ds to original segment
						;(flags preserved).
	jne	returnCarry			;carry clear if cmp <>, so
						;we return it

	;
	;	Test the cards for suit compatibility
	;
testSuit:
	push	bp						;save Kit
	CallObjectCXDX MSG_DECK_GET_DROP_CARD_ATTRIBUTES, MF_CALL	;bp <- dropAttr
	pop	bx						;bx <- Kit
	push	bx, bp						;save Kit,
								;CardAttrs of
								;drop card
	call	TestSuit
	pop	bx, bp
	jnc	returnCarry					;if suit is
								;wrong, then
								;the cards
								;do not match

;testRank:
	call	TestRank			;at this point, it all rides
						;on TestRank, so we'll return
						;whatever it returns
returnCarry:
	ret
Test4RightCard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				TestSuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see whether a drop card would be suit-wise
		accepted according to a ComparisonKit

CALLED BY:	

PASS:		bp = CardAttrs of the drop card
		bx = ComparisonKit of catch deck
		
CHANGES:	

RETURN:		carry set if drop card is suit-wise compatible with the
		ComparisonKit

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		maybe could be done more efficiently when testing
		same/opposite color

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TestSuit	proc	near
	mov	dx, bx			;dx <- acceptor ComparisonKit

	ANDNF	dx, mask CAC_SAC shl offset CK_CAC	;filter thru SAC
	cmp	dx, SAC_ANY_SUIT shl (offset CAC_SAC + offset CK_CAC)
	je	returnTrue				;if any suit will
							;do, then we return
							;true

	ANDNF	bp, mask CA_SUIT			;filter dropsuit
	mov	cl, offset CK_TOP_CARD
	shr	bx, cl					;bx <- topcard
	ANDNF	bx, mask CA_SUIT			;filter suit

	cmp	dx, SAC_SAME_SUIT shl (offset CAC_SAC + offset CK_CAC)
	je	testSameSuit
	
	ANDNF	bp, CS_CLUBS shl offset CA_SUIT		;filter black bit
	ANDNF	bx, CS_CLUBS shl offset CA_SUIT		;filter black bit

	cmp	dx, SAC_OPPOSITE_COLOR shl (offset CAC_SAC + offset CK_CAC)
	je	testOppositeColor
;testSameColor:
	cmp	bx,bp
	je	returnTrue
	jmp	returnFalse
testOppositeColor:
	cmp	bx, bp
	jne	returnTrue
	jmp	returnFalse
testSameSuit:
	cmp	bx,bp
	je	returnTrue
returnFalse:
	clc
	jmp	endTestSuit
returnTrue:
	stc
endTestSuit:
	ret
TestSuit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				TestRank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see whether a drop card would be rank-wise
		accepted according to a ComparisonKit

CALLED BY:	

PASS:		bp = CardAttrs of the drop card
		bx = ComparisonKit of catch deck
		
CHANGES:	

RETURN:		carry set if drop card is rank-wise compatible with the
		ComparisonKit

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TestRank	proc	near
	mov	dx, bx			;dx <- acceptor comparison kit

	ANDNF	bp, mask CA_RANK	;filter thru droprank
	mov	cl, offset CA_RANK
	shr	bp, cl

	ANDNF	dx, mask CAC_RAC shl offset CK_CAC
	cmp	dx, RAC_ABSOLUTE_RANK shl (offset CAC_RAC + offset CK_CAC)
	je	absoluteRank

;relativeRank:
	ANDNF	bx, mask CA_RANK shl offset CK_TOP_CARD
	mov	cl, offset CA_RANK + offset CK_TOP_CARD
	shr	bx, cl

	dec	bx
	cmp	dx, RAC_ONE_LESS_RANK shl (offset CAC_RAC + offset CK_CAC)
	je	compare
	inc	bx
	cmp	dx, RAC_EQUAL_RANK shl (offset CAC_RAC + offset CK_CAC)
	je	compare
	inc	bx
	jmp	compare

absoluteRank:
	ANDNF	bx, mask CAC_RANK shl offset CK_CAC
	mov	cl, offset CAC_RANK + offset CK_CAC
	shr	bx, cl

	cmp	bx, CR_WILD
	je	returnTrue
compare:
	cmp	bx, bp
	je	returnTrue
;returnFalse:
	clc
	jmp	endTestRank
returnTrue:
	stc
endTestRank:
	ret
TestRank	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckGetRidOfCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_GET_RID_OF_CARDS handler for DeckClass
		Pops all the deck's cards to another deck.

CALLED BY:	

PASS:		ds:di = deck instance
		^lcx:dx = deck to receive cards
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckGetRidOfCards	method	DeckClass, MSG_DECK_GET_RID_OF_CARDS
	mov	bp, ds:[di].DI_popPoints
	push	bp
	clr	ds:[di].DI_popPoints
	call	ObjMarkDirty

	mov	ax, MSG_DECK_POP_ALL_CARDS
	call	ObjCallInstanceNoLock

	Deref_DI Deck_offset
	pop	ds:[di].DI_popPoints
	call	ObjMarkDirty
	ret
DeckGetRidOfCards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckTransferAllCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_TRANSFER_ALL_CARDS handler for DeckClass
		Transfers all of a deck's cards to another deck. Relative
		order of the cards is preserved.
		
CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		^lcx:dx = instance of VisCompClass to receive the cards
		(usually another Deck)
		
CHANGES:	Deck's cards transferred to deck in ^lcx:dx

RETURN:		nothing

DESTROYED:	ax, bp, di

PSEUDO CODE/STRATEGY:
		calls TransferNCards with n = total # of cards

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckTransferAllCards	method	DeckClass, MSG_DECK_TRANSFER_ALL_CARDS
	mov	bp, ds:[di].DI_nCards		;set bp = all cards
	mov	ax, MSG_DECK_TRANSFER_N_CARDS	;and transfer them
	call	ObjCallInstanceNoLock
	ret
DeckTransferAllCards	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckTransferDraggedCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_TRANSFER_DRAGGED_CARDS handler for DeckClass
		Transfers the deck's drag cards (if any) to another deck.
CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		^lcx:dx = deck to which to transfer the cards
		
CHANGES:	deck *ds:si transfers its cards to deck ^lcx:dx

RETURN:		nothing

DESTROYED:	ax, bp, cx, dx

PSEUDO CODE/STRATEGY:
		forwards the call to MSG_DECK_TRANSFER_N_CARDS, setting N to
		the number of dragged cards

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckTransferDraggedCards    method    DeckClass, MSG_DECK_TRANSFER_DRAGGED_CARDS
        mov     ax, MSG_GAME_TRANSFERRING_CARDS
        call    VisCallParent                   ;notify the game

	mov	bp, ds:[di].DI_nDragCards	;set bp = # drag cards
	mov	ax, MSG_DECK_TRANSFER_N_CARDS	;and transfer them
	call	ObjCallInstanceNoLock
	ret
DeckTransferDraggedCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckTransferNCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_TRANSFER_N_CARDS handler for DeckClass
		Transfers a specified number of cards to another deck.

CALLED BY:	DeckTransferAllCards, DeckTransferDragCards, etc.

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		bp = number of cards to transfer
		^lcx:dx = instance of VisCompClass to receive the cards
		(usually another Deck)
		
CHANGES:	The top bp cards of deck at *ds:si are transferred
		to the top of deck at ^lcx:dx. The order of the cards is
		preserved.

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
		loops bp times, popping cards (starting with the bp'th, ending
		with the top)from the donor and pushing them to the
		recipient

KNOWN BUGS/IDEAS:
*WARNING*
A deck must never transfer to itself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckTransferNCards	method	DeckClass, MSG_DECK_TRANSFER_N_CARDS
	push	cx,dx,bp
	mov	ds:[di].DI_lastRecipient.handle, cx
	mov	ds:[di].DI_lastRecipient.chunk, dx
	mov	ds:[di].DI_lastGift, bp
	call	ObjMarkDirty
	
	mov	ax, MSG_GAME_SET_DONOR
	call	DeckCallParentWithSelf
	pop	cx,dx,bp
startDeckTransferNCards:
	dec	bp					;see if we're done
	tst	bp
	jl	endDeckTransferNCards

	push	bp					;save count

	push	cx, dx					;save OD of recipient
	clr	cx					;cx:dx <- # of child
	mov	dx, bp					;to remove
	mov	ax, MSG_DECK_REMOVE_NTH_CARD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjCallInstanceNoLock			;^lcx:dx <- OD of card

	mov	bp, si					;save donor offset
	pop	bx,si					;restore recipient OD
	push	bp					;push donor offset
	push	bx,si
	mov	ax, MSG_DECK_PUSH_CARD			;give card to recipient
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx
	pop	si					;restore donor offset
	pop	bp					;restore count

	jmp	startDeckTransferNCards

endDeckTransferNCards:
	ret
DeckTransferNCards	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckUpdateDrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_UPDATE_DRAG handler for DeckClass
		Updates the deck's drag instance data to reflect a new
		mouse position.

CALLED BY:	various

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		cx,dx = new mouse position
		
CHANGES:	DI_prevLeft and DI_prevTop to reflect new mouse position

RETURN:		cx,dx = new prevLeft, new prevTop
		ax,bp = old prevLeft, old prevTop

DESTROYED:	ax, bp, cx, dx

PSEUDO CODE/STRATEGY:
		subtract the drag offsets from cx,dx to turn them from mouse
		positions to left,top of drag area

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckUpdateDrag	method		DeckClass, MSG_DECK_UPDATE_DRAG
	sub	cx, ds:[di].DI_dragOffsetX	;cx <- new left drag bound
	sub	dx, ds:[di].DI_dragOffsetY	;dx <- new top drag bound

	mov	ax, ds:[di].DI_prevLeft		;ax <- old left drag bound
	mov	bp, ds:[di].DI_prevTop		;bp <- old top drag bound

	mov	ds:[di].DI_prevLeft, cx
	mov	ds:[di].DI_prevTop, dx
	call	ObjMarkDirty
	ret
DeckUpdateDrag	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckUpdateTopLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_UPDATE_TOPLEFT handler for DeckClass
		Sets the instance data indicating the position of the deck's
		top card, and also resizes the deck to make a tight fit
		around its cards.

CALLED BY:	

PASS:		*ds:si = instance data of deck
		
CHANGES:	if deck has children:
			DI_topCard(Left,Top) are set to Left,Top of top child
			deck's Right,Bottom match Right,Bottom of top card
		if deck doesn't have children:
			DI_topCard(Left,Top) are set to Left,Top of deck
			deck is resized to the size of one card

RETURN:		nothing

DESTROYED:	ax, bp, cx, dx, di

PSEUDO CODE/STRATEGY:
		checks to see if deck has a card
		if so:
			gets bounds of top card
			sets DI_topCard(Left,Top)
			sets right,bottom vis bounds to deck
		if not:
			gets own bounds
			sets DI_topCard(Left,Top)

KNOWN BUGS/IDEAS:
		This method assumes (and the assumption is general over a
		large portion of the cards library) that overlapping cards
		go left -> right, top -> bottom. This should really by made
		more general.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckUpdateTopLeft	method		DeckClass, MSG_DECK_UPDATE_TOPLEFT
	clr	cx
 	clr	dx
	mov	ax, MSG_VIS_FIND_CHILD	;find first child
	call	ObjCallInstanceNoLock
	jc	noTopCard			;if no children, jump

;yesTopCard:
	CallObjectCXDX	MSG_VIS_GET_BOUNDS, MF_CALL	;get top card's bounds

	Deref_DI Deck_offset
	mov	ds:[di].DI_topCardLeft, ax		;set DI_topCardLeft to
							;left of top card
	mov	ds:[di].DI_topCardTop, bp		;set DI_topCardTop to
							;top of top card
	Deref_DI Vis_offset
	mov	ds:[di].VI_bounds.R_right, cx		;set right,bottom of
	mov	ds:[di].VI_bounds.R_bottom, dx		;deck to right,bottom
							;of top card
	call	ObjMarkDirty
	jmp	endDeckUpdateTopLeft

noTopCard:
	mov	cx, VUQ_CARD_DIMENSIONS
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent

	push	cx, dx
	mov	ax, MSG_VIS_GET_BOUNDS			;if no card, use self
	call	ObjCallInstanceNoLock			;	bounds

	Deref_DI Deck_offset
	mov	ds:[di].DI_topCardLeft, ax
	mov	ds:[di].DI_topCardTop, bp
	call	ObjMarkDirty

	pop	cx, dx
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock

endDeckUpdateTopLeft:
	ret
DeckUpdateTopLeft	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckReturnCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_RETURN_CARDS handler for DeckClass
		Gives a specified # of cards to a specified deck, and
		fixes things up visually. Used primarily for UNDO.

CALLED BY:	

PASS:		*ds:si = deck object
		^lcx:dx = deck to give cards to
		bp = # of cards to give
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckReturnCards	method	DeckClass, MSG_DECK_RETURN_CARDS

	.enter

	;
	; since the deck will soon be changing, we want to invalidate
	; its screen area now instead of after the change
	;
	push	cx,dx,bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	cx,dx,bp

	;
	; give the cards back to ^lcx:dx
	;
	mov	ax, MSG_DECK_TRANSFER_N_CARDS
	call	ObjCallInstanceNoLock

	;
	; Make the top card fully sized again
	;
	mov	ax, MSG_CARD_MAXIMIZE
	call	VisCallFirstChild

	.leave
	ret
DeckReturnCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckRetrieveCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_RETRIEVE_CARDS handler for DeckClass.
		Retrieves the last set of cards that were given to another
		deck. Used for UNDO

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = deck object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckRetrieveCards	method	DeckClass, MSG_DECK_RETRIEVE_CARDS
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, ds:[di].DI_lastRecipient.handle
	mov	si, ds:[di].DI_lastRecipient.chunk

	mov	bp, ds:[di].DI_lastGift
	mov	ax, MSG_DECK_RETURN_CARDS
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage
DeckRetrieveCards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckDownCardSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DOWN_CARD_SELECTED handler for DeckClass

CALLED BY:	CardStartSelect

PASS:		*ds:si = deck object
		bp = # of selected child in composite
		
CHANGES:	if card is top card, turns it face up

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		make sure card is top card
		if so,	turn it face up
			redraw it.
		
KNOWN BUGS/IDEAS:
don't know if the call to MSG_DECK_UPDATE_TOPLEFT does anything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckDownCardSelected	method	DeckClass, MSG_DECK_DOWN_CARD_SELECTED
	tst	bp				;see if bp = first child
	jnz	endDeckDownCardSelected		;do nothing unless top card

	mov	ax, MSG_CARD_FLIP_CARD
	call	ObjCallInstanceNoLock

	mov	ax, MSG_DECK_UPDATE_TOPLEFT	;update top left
	call	ObjCallInstanceNoLock

	Deref_DI Deck_offset
	mov	dx, ds:[di].DI_flipPoints
	tst	dx
	jz	afterScore
	clr	cx

	mov	ax, MSG_GAME_UPDATE_SCORE
	call	VisCallParent

afterScore:

	mov	dl, VUM_NOW
	mov	ax, MSG_GAME_DISABLE_UNDO
	call	VisCallParent

endDeckDownCardSelected:
	ret

DeckDownCardSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckGetDealt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_GET_DEALT handler for DeckClass

CALLED BY:	HandDeal

PASS:		*ds:si = deck object
		^lcx:dx = card to add
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		send self MSG_DECK_MOVE_AND_CLIP to prepare for the new card
		add the card
		set the card drawable
		get card's attributes
		if card is face up, fade it in
		if card is face down, just draw it

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckGetDealt	method	DeckClass, MSG_DECK_GET_DEALT
	push	cx,dx				;save card OD
	mov	ax, MSG_DECK_MOVE_AND_CLIP	;get ready for new card
	call	ObjCallInstanceNoLock
	pop	cx,dx				;restore card OD

	push	cx, dx				;save card OD
	mov	ax, MSG_DECK_ADD_CARD_FIRST	;add the card
	call	ObjCallInstanceNoLock

	pop	bx, si				;^lbx:si <- card OD
	mov	ax, MSG_CARD_SET_DRAWABLE		;set card drawable
	mov	di, mask MF_FIXUP_DS

	call	ObjMessage

	mov	ax, MSG_CARD_GET_ATTRIBUTES	;get card's attributes
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_CARD_NORMAL_REDRAW	;normal redraw for face down
	test	bp, mask CA_FACE_UP
	jz	redraw
	mov	ax, MSG_CARD_FADE_REDRAW		;fade in for face up
redraw:
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	ret
DeckGetDealt	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckSetupDrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_SETUP_DRAG handler for DeckClass
		Prepares the deck's drag instance data for dragging.

CALLED BY:	

PASS:		*ds:si = deck object
		cx,dx = mouse position
		bp = # of children to drag

CHANGES:	fills in some drag data

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckSetupDrag		method	DeckClass, MSG_DECK_SETUP_DRAG

	push	cx,dx					;save mouse position
	push	bp
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock
	Deref_DI Deck_offset
	mov	ds:[di].DI_initRight, cx
	mov	ds:[di].DI_initBottom, dx
	pop	bp

	mov	cx, VUQ_CARD_DIMENSIONS
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
	push	dx

	Deref_DI Deck_offset
	mov	ds:[di].DI_nDragCards, bp
	dec	bp					;bp <- # drag cards - 1
	push	bp					;save # drag cards - 1

	mov	ax, ds:[di].DI_offsetFromUpCardX	;ax <- horiz. offset
	mul	bp					;ax <- offset * #cards
							; = total offset

	add	cx, ax
	mov	ds:[di].DI_dragWidth, cx		;dragWidth = 
							;cardWidth + tot.offset

	mov	cx, ds:[di].DI_topCardLeft
	sub	cx,ax					;cx <- left drag bound
	mov	ds:[di].DI_prevLeft, cx
	mov	ds:[di].DI_initLeft, cx

	pop	ax
	mul	ds:[di].DI_offsetFromUpCardY

	pop	dx
	add	dx, ax
	mov	ds:[di].DI_dragHeight, dx		;dragHeight =
							;cardHeight + offset

	mov	dx, ds:[di].DI_topCardTop
	sub	dx,ax					;dx <- top drag bound
	mov	ds:[di].DI_prevTop, dx
	mov	ds:[di].DI_initTop, dx

	pop	ax,bx					;restore mouse position

	sub	ax, cx					;get offset from mouse
	mov	ds:[di].DI_dragOffsetX, ax		;left to drag left

	sub	bx, dx					;get offset from mouse
	mov	ds:[di].DI_dragOffsetY, bx		;top to drag top
	call	ObjMarkDirty

	ret
DeckSetupDrag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckUpCardSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_UP_CARD_SELECTED handler for DeckClass
		This method determines the number of cards that will
		be dragged as a result of this card selection

CALLED BY:	CardStartSelect

PASS:		*ds:si = deck object
		cx,dx = mouse
		bp = # of card selected
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckUpCardSelected	method	DeckClass, MSG_DECK_UP_CARD_SELECTED
	;
	;	Our first task is to load cx with:
	;
	;	ch = # of selected card in composite
	;	cl = low 8 bits of selected CardAttrs, which contains
	;		info on rank and suit
	;
	push	cx,dx			;stack-> mouseX,mouseY

	push	bp			;stack-> # selected
					;	 mouseX, mouseY

	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	DeckCallNthChild

	mov	cx, bp				;cl <- selected attrs
	pop	dx				;dx <- selected #
					;stack-> mouseX, mouseY
	mov	ch, dl				;ch <- selected #

	push	cx			;stack-> selected card
					;	 mouseX, mouseY

	clr	dx

	;
	;	Now we're going to go through our cards, starting with the
	;	first card, and find out which ones want to be dragged.
	;
startLoop:
	;
	;	We want to load:
	;
	;	dh = # of card we're checking for dragability in composite
	;		(so that we can compare its place with that of
	;		 the selected card)
	;
	;	dl = low 8 bits of CardAttrs of card we're examining (so we
	;		can check things like face up, etc.)
	;	
	push	dx			;stack-> # of card examining
					;	 selected card
					;	 mouseX, mouseY
	mov	bp, dx
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	jc	endLoop

	mov	dx, bp				;dl <- nth card attrs
	pop	cx				;cx <- # of card examining
					;stack-> selected card
					;	 mouseX, mouseY

	mov	dh, cl				;dh <- n
	pop	cx				;cx <- selected card
					;stack-> mouseX, mouseY
	push	cx
	Deref_DI Deck_offset
	mov	al, ds:[di].DI_deckAttrs
	clr	ah
	mov	bp, ax

	;
	;	Make the query on whether or not the examined card should
	;	be dragged.
	;
	mov	ax, MSG_GAME_QUERY_DRAG_CARD
	call	VisCallParent

	mov	dl, dh
	mov	dh, 0
	push	dx
	jnc	endLoop			;if we don't want to drag this one,
					;then screw all the rest, too.
;doDrag:
	pop	dx
	inc	dx
;	push	dx
	jmp	startLoop

endLoop:
	pop	bp
	add	sp, 2
	pop	cx,dx

	tst	bp
	jz	endDeckUpCardSelected
	mov	ax, MSG_DECK_DRAGGABLE_CARD_SELECTED
	call	ObjCallInstanceNoLock

endDeckUpCardSelected:
	ret
DeckUpCardSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DeckGetComparisonKit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GET_COMPARISION_KIT handler for DeckClass.
		Returns the comparison kit for this deck (see definition
		of ComparisonKit).

CALLED BY:	

PASS:		*ds:si = deck object
		
CHANGES:	

RETURN:		bp = ComparisonKit for this deck

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckGetComparisonKit	method	DeckClass, MSG_DECK_GET_COMPARISON_KIT
	clr	bp
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	VisCallFirstChild

	Deref_DI Deck_offset

	tst	bp
	jz	noCard

	mov	dx, bp
	mov	cl, offset CK_TOP_CARD
	shl	dx, cl

	test	bp, mask CA_FACE_UP
	jz	faceDown

;faceUp:
	mov	bp, ds:[di].DI_upCardAC
	jmp	makeKit
faceDown:
	mov	bp, ds:[di].DI_downCardAC
	jmp	makeKit
noCard:
	mov	bp, ds:[di].DI_noCardAC
	clr	dx
makeKit:
	mov	cl, offset CK_CAC
	shl	bp, cl
	ORNF	bp, dx
	ret
DeckGetComparisonKit	endm
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckSetPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_SET_POINTS handler for DeckClass
		Sets the # of points awarded/penalized for pushing,
		popping, and turning cards in this deck

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = deck object
		cx = points awarded for pushing a card to this deck
		dx = points awarded for popping a card from this deck
		bp = points awarded for flipping over a card in this deck
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckSetPoints	method	DeckClass, MSG_DECK_SET_POINTS
	mov	ds:[di].DI_pushPoints, cx
	mov	ds:[di].DI_popPoints, dx
	mov	ds:[di].DI_flipPoints, bp
	call	ObjMarkDirty

	ret

DeckSetPoints	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckSetUpSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_SET_UP_SPREADS handler for DeckClass

CALLED BY:	

PASS:		ds:di = deck instance
		cx, dx = x,y spreads for face up cards

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	27 nov 1992	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckSetUpSpreads	method dynamic	DeckClass, MSG_DECK_SET_UP_SPREADS
	.enter

	mov	ds:[di].DI_offsetFromUpCardX, cx
	mov	ds:[di].DI_offsetFromUpCardY, dx
	call	ObjMarkDirty

	.leave
	ret
DeckSetUpSpreads	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckSetDownSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_SET_DOWN_SPREADS handler for DeckClass

CALLED BY:	

PASS:		ds:di = deck instance
		cx, dx = x,y spreads for face down cards

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	27 nov 1992	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckSetDownSpreads	method dynamic	DeckClass, MSG_DECK_SET_DOWN_SPREADS
	.enter

	mov	ds:[di].DI_offsetFromDownCardX, cx
	mov	ds:[di].DI_offsetFromDownCardY, dx
	call	ObjMarkDirty

	.leave
	ret
DeckSetDownSpreads	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets deck's attrs to value passed

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = deck object
		cl = DeckAttrs
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckSetAttrs	method	DeckClass, MSG_DECK_SET_ATTRS
	mov	ds:[di].DI_deckAttrs, cl
	call	ObjMarkDirty
	ret
DeckSetAttrs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_SET_POSITION handler for DeckClass
		Moves the deck's vis bounds and sets DI_topCardLeft
		and DI_topCardTop to the new location (the assumption
		is that the deck has no cards when you move it).

CALLED BY:	

PASS:		cx, dx = horizontal, vertical displacements
		
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
DeckMove	method	DeckClass, MSG_VIS_SET_POSITION
	call	VisSetPosition
	Deref_DI Deck_offset
	mov	ds:[di].DI_topCardLeft, cx
	mov	ds:[di].DI_topCardTop, dx
	call	ObjMarkDirty
	ret
DeckMove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckChangeKidsBacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_CHANGE_KIDS_BACKS handler for DeckClass
		Marks any face down children as dirty, indicating that
		their bitmap has changed.

CALLED BY:	

PASS:		*ds:si = deck object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckChangeKidsBacks method DeckClass, MSG_DECK_CHANGE_KIDS_BACKS
	mov	ax, MSG_CARD_MARK_DIRTY_IF_FACE_DOWN
	call	VisSendToChildren
	ret
DeckChangeKidsBacks endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckSprayCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_SPRAY_CARDS handler for DeckClass
		Creates cool card fan visual effect with the cards in this
		deck.

CALLED BY:	

PASS:		ds:di = deck instance
		*ds:si = deck object
		bp = gstate (ready for first card)
		cx = distance from origin along y-axis to draw cards (radius of
			the fan)
		dx = # degrees to rotate the gstate after each card is drawn

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
DeckSprayCards	method	DeckClass, MSG_DECK_SPRAY_CARDS
	mov	bx, ds:[di].DI_nCards
	neg	cx					;cx <- -length
startLoop:
	dec	bx					;test for more cards
	js	done
	xchg	bx, dx					;dx<-# kid, bx <-angle 
	push	dx					;save #
	push	si					;save deck offset
	push	cx, bp					;save -length. gstate
	clr	cx
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock
	jnc	callChild
	add	sp, 8
	jmp	done

callChild:
	mov	si, dx					;si <- card offset
	mov	dx, bx					;dx <- angle
	mov	bx, cx					;bx <- card handle
	pop	cx, bp					;cx <- -length, gstate
	mov	ax, MSG_CARD_SPRAY_DRAW
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	si					;si <- deck offset
	pop	bx					;bx <- kid #
	jmp	startLoop
done:
	ret
DeckSprayCards	endm	

DeckGetNCards	method	DeckClass, MSG_DECK_GET_N_CARDS
	mov	cx, ds:[di].DI_nCards
	ret
DeckGetNCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				DeckCallNthChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to find the deck's Nth child and send a
		method to it.


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
			DeckCallParentWithSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the deck's OD into cx:dx and calls the deck's paren
		with the passed method.

CALLED BY:	

PASS:		*ds:si = deck object
		ax = method number for parent
		bp = additional data to pass to parent
		
CHANGES:	

RETURN:		return values from parent method handler

DESTROYED:	bp, cx, dx,

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/19/90	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeckCallParentWithSelf	proc	near
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	VisCallParent
	ret
DeckCallParentWithSelf	endp
CardsCodeResource ends
