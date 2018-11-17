COMMENT @----------------------------------------------------------------------


	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Solitaire
FILE:		card.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	6/90		Initial Version

DESCRIPTION:
	this file contains handlers for CardClass

RCS STAMP:
$Id: card.asm,v 1.1 97/04/04 17:44:34 newdeal Exp $
------------------------------------------------------------------------------@

CardsClassStructures	segment	resource
	CardClass
CardsClassStructures	ends

CardsCodeResource segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CardGetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Card method for MSG_CARD_GET_VM_FILE

Called by:	MSG_CARD_GET_VM_FILE

Pass:		*ds:si = Card object
		ds:di = Card instance

Return:		ax - vm file

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardGetVMFile	method dynamic	CardClass, MSG_CARD_GET_VM_FILE
	uses	cx, dx, bp
	.enter

	mov	ax, MSG_DECK_GET_VM_FILE
	call	VisCallParent
	mov_tr	ax, cx

	.leave
	ret
CardGetVMFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardClearFading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_CLEAR_FADING handler for CardClass
		Clears the CA_FADING bit fom the card's attributes

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = card object
		
CHANGES:	CA_FADING bit in CardAttrs is zeroed

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
CardClearFading	method	CardClass, MSG_CARD_CLEAR_FADING
	RESET	ds:[di].CI_cardAttrs, CA_FADING
	call	ObjMarkDirty
	ret
CardClearFading	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardClearFading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_CLEAR_FADING handler for CardClass
		Clears the CA_FADING bit fom the card's attributes

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = card object
		
CHANGES:	CA_FADING bit in CardAttrs is zeroed

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
CardClearInverted	method	CardClass, MSG_CARD_CLEAR_INVERTED
	test	ds:[di].CI_cardAttrs, mask CA_INVERTED
	jz	done

	mov	ax, MSG_CARD_INVERT
	call	ObjCallInstanceNoLock
done:
	ret
CardClearInverted	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CardClipBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_CLIP_BOUNDS handler for CardClass
		Card assumes that another card is going to be placed upon
		it, offset by some amount horizontally and vertically.  If
		either the horizontal or vertical offset is 0, then the
		card clips its vis bounds to no longer contain the area
		covered up by the placed card.
CALLED BY:	

PASS:		*ds:si = instance of CardClass
		cx = horizontal offset of to-be-placed card
		dx = vertical offset of to-be-placed card
		
CHANGES:	may change width and/or height of object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		if horizontal offset = 0, we set card's height = vert. offset
		if vertical offset = 0, we set card's width = horiz. offset


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardClipBounds	method	CardClass, MSG_CARD_CLIP_BOUNDS
	push	cx,dx			;save offsetX, offsetY
	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock	;cx,dx = current width,height
	pop	ax,bx			;restore offsetX, offsetY

	tst	ax			;horizontal offset?
	jnz	afterHeightClip		;if yes, skip height clip

;doClipHeight:
	mov	dx, bx			;no horiz.offset, so dx <- vert.offset

afterHeightClip:
	tst	bx			;vertical offset?
	jnz	afterWidthClip		;if so, skip width clip

;doClipWidth:
	mov	cx, ax			;no vert.offset, so cx <- horiz.offset
	
afterWidthClip:
	mov	ax, MSG_VIS_SET_SIZE	;width = cx
	call	ObjCallInstanceNoLock	;height = dx
	ret
CardClipBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_DRAW handler for CardClass

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = instance of CardClass
		bp = gstate
		
CHANGES:	clip rect may be altered

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
CardDraw	method	CardClass, MSG_VIS_DRAW
	;
	;	if the card is marked dirty, we need to update its
	;	bitmap, so check that here
	;
	test	ds:[di].CI_cardAttrs, mask CA_DIRTY
	jz	clipRect

	push	bp
	mov	ax, MSG_CARD_SET_BITMAP
	call	ObjCallInstanceNoLock
	pop	bp

clipRect:

	Deref_DI Vis_offset
	mov	ax, ds:[di].VI_bounds.R_left	;ax <- left bound
	mov	bx, ds:[di].VI_bounds.R_top	;bx <- top bound
	push	ax, bx				;push left, top so we can
						;eventually draw the bitmap
	mov	cx, ds:[di].VI_bounds.R_right	;cx <- right bound
	mov	dx, ds:[di].VI_bounds.R_bottom	;dx <- bottom bound

	mov	di, bp				;di <- gstate

	push	si				;push card chunk
	mov	si, PCT_REPLACE

	;
	;  Push the top bound up by one 'cause I don't
	;  understand the path code, and it seems to work.
	;
	dec	bx

	call	GrSetClipRect			;set clip rect = card bounds
	pop	si				;recover object chunk

	mov	ah, CF_INDEX			;set background = white
	mov	al, C_WHITE
	call	GrSetAreaColor

	mov	al, MM_COPY			;mode = copy
	call	GrSetMixMode

	push	di				; save the gstate
	
	mov	bp, di				; bp <- gstate
	Deref_DI Vis_offset
	mov	cx, ds:[di].VI_bounds.R_left	; cx,dx <- left, top of
	mov	dx, ds:[di].VI_bounds.R_top	; card

	Deref_DI Card_offset
	test	ds:[di].CI_cardAttrs, mask CA_MONO_BITMAP
	mov	ax, MSG_DECK_REQUEST_BLANK_CARD
	jnz	drawCard
	mov	ax, MSG_DECK_REQUEST_FRAME
drawCard:
	call	VisCallParent
	pop	dx				;dx <- gstate
	pop	ax, di
	push	ds, si
	push	ax, di

	mov	ax, MSG_CARD_GET_VM_FILE
	call	ObjCallInstanceNoLock
	mov_tr	bx, ax

	Deref_DI Card_offset
	mov	ax, ds:[di].CI_bitmap.handle
	mov	si, ds:[di].CI_bitmap.chunk
	call	VMLock
	mov	di,dx				;di <- gstate
	push	bp				;save for unlock

	mov	ds,ax				; set *ds:si = bitmap
	
	lodsw					; read color
	call	GrSetAreaColor			;set color (stored in bitmap)

	mov	al, CMT_DITHER
	call	GrSetAreaColorMap

	pop	dx				;clear this off the stack
						;for a minute...
	pop	ax, bx

	push	dx				;push it back.


	mov	dl, ds:[si].CB_simple.B_type
	and	dl, mask BMT_FORMAT
	cmp	dl, BMF_MONO
	mov	dx, 0
	jne	fullColor

	call	GrFillBitmap			; draw the bitmap

afterDraw:
	pop	bp
	call	VMUnlock

	;
	;	If card should be inverted, do it here
	;
	pop	ds, si

	mov	bx, ds:[si]
	add	bx, ds:[bx].Card_offset
	test	ds:[bx].CI_cardAttrs, mask CA_INVERTED
	jz	removePath

	mov	al, MM_INVERT
	call	GrSetMixMode			;set invert mode

	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock

	mov	bx, bp

	call	GrFillRect

removePath:
	mov	cx, PCT_NULL		;no restrictions
	call	GrSetClipPath

	ret

fullColor:
	call	GrDrawBitmap
	jmp	afterDraw
CardDraw		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardFadeDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_FADE_DRAW handler for CardClass

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = instance of CardClass
		bp = gstate
		cl = value to add to current fade mask
		
CHANGES:	

RETURN:		carry set if card is not marked as fading

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
		issues self repeated MSG_VIS_DRAWS with different draw masks

KNOWN BUGS/IDEAS:
currently masks AND to all 1's, but don't XOR to all 1's, meaning some bits get
drawn multiple times (as many as eight).  would like to see what it looks like
to have a set of masks that both AND & XOR to all 1's.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardFadeDraw	method	CardClass, MSG_CARD_FADE_DRAW
	mov	al, ds:[di].CI_areaMask			; al <- mask
	add	al, cl					;al <- next mask
	cmp	al, SDM_100				;if we're over 100,
	jge	saveMask				;then make it an
	mov	al, SDM_100				;even 100.
saveMask:
	mov	ds:[di].CI_areaMask, al			; save new mask
	call	ObjMarkDirty
;fadeCard:
	mov	di, bp					
	call	GrSetAreaMask				;set mask
	mov	bp, di					;bp <- gstate
	mov	ax, MSG_VIS_DRAW				;draw card
	call	ObjCallInstanceNoLock

	Deref_DI Card_offset
	cmp	ds:[di].CI_areaMask, SDM_100	;have we already done mask100?
	je	doneFading
	ret

	;
	;	The card is fully drawn, so we can tell the game object
	;	to remove it from its fade array
	;
doneFading:
	mov	bp, PLEASE_REMOVE_ME_FROM_THE_ARRAY
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	FALL_THRU CardUpdateFadeArray
CardFadeDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CardUpdateFadeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a method to the game object requesting addition
		or removal of a card from the fade array.

CALLED BY:	CardFadeRedraw, CardFadeDraw

PASS:		bp = PLEASE_ADD_ME_TO_THE_ARRAY or
		     PLEASE_REMOVE_ME_FROM_THE_ARRAY
		*ds:si = card object
		di = flags for ObjMessage when sending MSG_GAME_UPDATE_FADE_ARRAY

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
CardUpdateFadeArray	proc	far
	;
	;	Get game object OD
	;
	push	di					;save MF flags
	mov	cx, VUQ_GAME_OD
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
	pop	di					;restore MF flags

	mov	bx, cx
	xchg	si, dx
	mov	cx, ds:[LMBH_handle]
	mov	ax, MSG_GAME_UPDATE_FADE_ARRAY
	call	ObjMessage
	ret
CardUpdateFadeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardFadeRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_FADE_REDRAW handler for CardClass
		creates a graphics state, then sends MSG_CARD_FADE_DRAW

CALLED BY:	

PASS:		*ds:si = instance of CardClass

		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		create graphics state
		send MSG_CARD_FADE_DRAW to self
		destroy graphics state

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardFadeRedraw	method		CardClass, MSG_CARD_FADE_REDRAW

	.enter

	mov	cx, VUQ_INITIAL_FADE_MASK		;get the first
	mov	ax, MSG_VIS_VUP_QUERY			;fade mask
	call	VisCallParent

	;
	;  If there's no fading, just draw it
	;

	cmp	cl, SDM_100
	jne	fading

	mov	ax, MSG_CARD_NORMAL_REDRAW
	call	ObjCallInstanceNoLock
	jmp	done

fading:
	Deref_DI Card_offset
	mov	ds:[di].CI_areaMask, cl
	call	ObjMarkDirty

	;
	;	The following test to see whether a card is already
	;	marked as fading has been removed; the reason is that
	;	if for some reason a card is marked CA_FADING, but is not
	;	on the list (this *should* never happen, but...), then
	;	it is totally screwed. Since the game checks against
	;	duplicate entries on the fade list, there should be
	;	no harm in re-adding the card, and maybe it can finish
	;	fading this time...
	;

	SET	ds:[di].CI_cardAttrs, CA_FADING		;set fading bit
	call	ObjMarkDirty

	test	ds:[di].CI_cardAttrs, mask CA_DIRTY	;see if we need to
	jz	startFading				;update the bitmap

	mov	ax, MSG_CARD_SET_BITMAP
	call	ObjCallInstanceNoLock

	;
	;	Tell the game object that this card wants to begin fading.
	;
startFading:
	mov	bp, PLEASE_ADD_ME_TO_THE_ARRAY
	mov	di, mask MF_FIXUP_DS
	call	CardUpdateFadeArray

done:
	.leave
	ret
CardFadeRedraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardGetAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_GET_ATTRIBUTES handler for CardClass

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = instance of CardClass
		
CHANGES:	nothing

RETURN:		bp = CardAttrs structure
		carry = clear for success

DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CardGetAttributes	method		CardClass, MSG_CARD_GET_ATTRIBUTES
	mov	bp, ds:[di].CI_cardAttrs	;bp <- attrs
	clc					;carry <- success!
	ret
CardGetAttributes	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_INITIALIZE handler for CardClass
		Sets up various vis flags and attrs necessary for drawing
		cards to the screen

CALLED BY:	

PASS:		*ds:si = instance of CardClass

		
CHANGES:	VI_optFlags, VI_attrs, VI_specAttrs, vis bounds

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		sets a bunch of vis properties
		sets left,top = 0,0 and width,height

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardInitialize		method	CardClass, MSG_META_INITIALIZE
	;
	;	Call super class with MSG_META_DUMMY to build out the
	;	instance data
	;
	mov	ax, MSG_META_DUMMY
	mov	di, offset CardClass
	call	ObjCallSuperNoLock
	
	;; set flags - these must be set or the object will not appear
	; The values being assigned here were largely discovered by trial
	; and error
	Deref_DI	Vis_offset
	ANDNF	ds:[di].VI_optFlags, (mask VOF_GEOMETRY_INVALID or \
		mask VOF_GEO_UPDATE_PATH or \
		mask VOF_IMAGE_INVALID or \
		mask VOF_IMAGE_UPDATE_PATH)

	ORNF	ds:[di].VI_attrs, mask VA_FULLY_ENABLED

	ANDNF	ds:[di].VI_specAttrs, not mask SA_ATTACHED

	mov	ds:[di].VI_bounds.R_left, 0	;set left,top = 0,0
	mov	ds:[di].VI_bounds.R_top, 0
	ret
CardInitialize		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardInvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_INVERT handler for CardClass
		Fills an inverted rectangle in the bounds of the card

CALLED BY:	DeckInvertSelf

PASS:		ds:di = card instance
		*ds:si = instance of CardClass
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, bp, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardInvert	method	CardClass, MSG_CARD_INVERT
	test	ds:[di].CI_cardAttrs, mask CA_FADING
	jnz	mustWait

	TOGGLE	ds:[di].CI_cardAttrs, CA_INVERTED
	call	ObjMarkDirty

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	jnc	done

	mov	di, bp				;bp <- gstate

	mov	al, MM_INVERT
	call	GrSetMixMode			;set invert mode

	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock

	mov	bx, bp

	call	GrFillRect

	call	GrDestroyState
done:
	ret

mustWait:
	;;if the card is fading, we want to wait until it is
	;;done before inverting

	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	done
CardInvert	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardMaximize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_MAXIMIZE handler for CardClass

CALLED BY:	

PASS:		*ds:si = instance of CardClass

		
CHANGES:	card's dimensions are set to full card dimensions

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardMaximize	method		CardClass, MSG_CARD_MAXIMIZE
	;
	;	Get normal card dimensions
	;
	mov	cx, VUQ_CARD_DIMENSIONS
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent

	;
	;	Set my size
	;
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock

	;
	;	Tell our deck that we've resized and that he should resize
	;	himself as a result
	;
	mov	ax, MSG_DECK_UPDATE_TOPLEFT
	call	VisCallParent
	ret
CardMaximize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardMoveRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_MOVE_RELATIVE handler for CardClass

CALLED BY:	

PASS:		*ds:si = instance of CardClass
		cx = horizontal displacement
		dx = vertical displacement
		
CHANGES:	card's vis bounds are displaced by cx,dx

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		call VisSetPositionRelative

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardMoveRelative	method	CardClass, MSG_CARD_MOVE_RELATIVE
	call	VisSetPositionRelative
	ret
CardMoveRelative	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CardNormalRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_NORMAL_REDRAW
		Redraws the card (normal as opposed to fade)

CALLED BY:	TEGetDealt

PASS:		*ds:si = instance of CardClass

		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		create a graphics state
		send self a MSG_VIS_DRAW
		destroy graphics state

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardNormalRedraw	method		CardClass, MSG_CARD_NORMAL_REDRAW
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	tst	bp
	jz	endCardNormalRedraw

	push	bp
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock

	pop	di
	call	GrDestroyState
endCardNormalRedraw:
	ret
CardNormalRedraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CardQueryDrawable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_QUERY_DRAW

CALLED BY:	

PASS:		*ds:si = instance of CardClass

		
CHANGES:	nothing

RETURN:		carry set if card is drawable
		carry clear if card is not drawable

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		test VI_attrs for mask VA_DRAWABLE

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardQueryDrawable	method		CardClass, MSG_CARD_QUERY_DRAWABLE
	Deref_DI Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE	;is it drawable?
	jz	done					;test clears carry
	stc						;drawable, so stc
done:
	ret
CardQueryDrawable	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardSetAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_SET_ATTRIBUTES handler for CardClass

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = instance of CardClass
		bp = CardAttrs to set
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardSetAttributes	method		CardClass, MSG_CARD_SET_ATTRIBUTES
	SET	bp, CA_DIRTY
	mov	ds:[di].CI_cardAttrs, bp
	call	ObjMarkDirty

;	Taking the following two lines out, while still seeming like the
;	right thing to do, seems to have slowed things down a bit...
;
;	mov	ax, MSG_CARD_SET_BITMAP
;	call	ObjCallInstanceNoLock
	ret
CardSetAttributes	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardSetDrawable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_SET_DRAWABLE handler for CardClass

CALLED BY:	

PASS:		*ds:si = instance of CardClass

		
CHANGES:	bit VA_DRAWABLE of card's VI_attrs is set

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
may want to turn this into VisSetDrawable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardSetDrawable	method		CardClass, MSG_CARD_SET_DRAWABLE
	Deref_DI Vis_offset
	SET	ds:[di].VI_attrs, VA_DRAWABLE
	ret
CardSetDrawable		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardSetNotDrawable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_SET_NOT_DRAWABLE handler for CardClass

CALLED BY:	

PASS:		*ds:si = instance of CardClass

		
CHANGES:	bit VA_DRAWABLE of card's VI_attrs is cleared

RETURN:		carry = NOT(the old VA_DRAWABLE bit) i.e, carry is set if
			VA_DRAWABLE was already clear.

DESTROYED:	di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
may want to turn this into VisSetNotDrawable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardSetNotDrawable	method		CardClass, MSG_CARD_SET_NOT_DRAWABLE
	Deref_DI Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	stc
	jz	done
	clc
	RESET	ds:[di].VI_attrs, VA_DRAWABLE
done:
	ret
CardSetNotDrawable	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_START_SELECT handler for card class
		informs parent deck that the card has been selected

CALLED BY:	called when user clicks on the card

PASS:		ds:di = card instance
		*ds:si = instance of CardClass
		cx, dx = mouse position
		bp = ButtonInfo
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		card finds its place within the composite
		card checks to see if it was double-clicked
		if so, sends MSG_DECK_CARD_DOUBLE_CLICKED to parent
		if not, sends MSG_DECK_CARD_SELECTED to parent

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardStartSelect method	CardClass, MSG_META_START_SELECT, MSG_META_START_MOVE_COPY
	;
	;	If the card is fading, then ignore this event.
	;
	test	ds:[di].CI_cardAttrs, mask CA_FADING
	jnz	endCardStartSelect

	push	cx,dx,bp			;save mouse, button info
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_FIND_CHILD
	call	VisCallParent			;bp <- card # in composite

	pop	cx,dx,ax			;restore mouse, button info
	test	ax, mask BI_DOUBLE_PRESS	;check the double click
	mov	ax, MSG_DECK_CARD_SELECTED
	jz	callParent
	mov	ax, MSG_DECK_CARD_DOUBLE_CLICKED	;if the card was double-clicked
callParent:
	call	VisCallParent			;inform the deck of it
endCardStartSelect:
	mov	ax, mask MRF_PROCESSED

	ret
CardStartSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardFlip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_FLIP handler for CardClass

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = card object
		
CHANGES:	changes CA_FACE_UP bit

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		if card is face up, send MSG_CARD_TURN_FACE_DOWN
		if card is face down, send MSG_CARD_TURN_FACE_UP

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	9/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardFlip	method	CardClass, MSG_CARD_FLIP
	TOGGLE	ds:[di].CI_cardAttrs, CA_FACE_UP
	call	ObjMarkDirty
	GOTO	CardTurnCommon
CardFlip	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardTurnFaceDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_TURN_FACE_DOWN handler for CardClass
		Turns card face down (*NOT* visually. You have to do this
		yourself, if you want). Updates bitmap fields

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = instance of CardClass

		
CHANGES:	bit CA_FACE_UP in CI_cardAttrs is cleared. Bitmap = deck bitmap

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardTurnFaceDown	method		CardClass, MSG_CARD_TURN_FACE_DOWN
	RESET	ds:[di].CI_cardAttrs, CA_FACE_UP
	call	ObjMarkDirty
	GOTO	CardTurnCommon
CardTurnFaceDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardTurnFaceUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_TURN_FACE_UP handler for CardClass
		Turns card face up (*NOT* visually. You have to do this
		yourself, if you want). Updates bitmap fields

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = instance of CardClass

		
CHANGES:	bit CA_FACE_UP in CI_cardAttrs is set. Bitmap = deck bitmap

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardTurnFaceUp	method		CardClass, MSG_CARD_TURN_FACE_UP
	SET	ds:[di].CI_cardAttrs, CA_FACE_UP
	call	ObjMarkDirty
	FALL_THRU	CardTurnCommon
CardTurnFaceUp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardTurnCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks card dirty and updates its bitmap

CALLED BY:	CardFlip, CardTurnFaceUp, CardTurnFaceDown

PASS:		ds:di = card instance
		*ds:si = card object
		
CHANGES:	marks card dirty, updates bitmap

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardTurnCommon	proc	far
	class	CardClass
	SET	ds:[di].CI_cardAttrs, CA_DIRTY
	call	ObjMarkDirty

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_CARD_SET_BITMAP
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	GOTO	ObjMessage
CardTurnCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardSetBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_SET_BITMAP handler for CardClass

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = card object
		
CHANGES:	updates the card instance data to point to the proper
		bitmap

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardSetBitmap	method	CardClass, MSG_CARD_SET_BITMAP
	test	ds:[di].CI_cardAttrs, mask CA_DIRTY
	jz	endCardSetBitmap

	mov	bp, ds:[di].CI_cardAttrs

	mov	cx, VUQ_CARD_BITMAP
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
	jnc	done

	mov	ax, MSG_CARD_GET_VM_FILE
	call	ObjCallInstanceNoLock
	mov_tr	bx, ax

	Deref_DI Card_offset
	mov	ds:[di].CI_bitmap.handle, cx
	mov	ds:[di].CI_bitmap.chunk, dx
	RESET	ds:[di].CI_cardAttrs, CA_DIRTY
	SET	ds:[di].CI_cardAttrs, CA_MONO_BITMAP
	call	ObjMarkDirty
	push	si
	mov	ax, cx
	mov	si, dx
	call	VMLock
	push	bp
	push	ds
	mov	ds, ax
	lodsw
	mov	cl, ds:[si].B_type
	ANDNF	cl, mask BMT_FORMAT
	cmp	cl, BMF_MONO
	pop	ds
	pop	bp
	call	VMUnlock
	pop	si
	je	done
	Deref_DI Card_offset
	RESET	ds:[di].CI_cardAttrs, CA_MONO_BITMAP
	call	ObjMarkDirty
done:
endCardSetBitmap:
	ret
CardSetBitmap	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisSetPositionRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves vis objects by some amount from their present location

CALLED BY:	CardMoveRelative

PASS:		*ds:si = instance of VisClass
		cx = horizontal  displacement
		dx = vertical displacement
		
CHANGES:	adds cx to object's left and right vis bounds
		adds dx to object's top and bottom vis bounds

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
isn't there already a function like this???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisSetPositionRelative	proc	near
	class	VisClass

	Deref_DI Vis_offset
	add	ds:[di].VI_bounds.R_left, cx
	add	ds:[di].VI_bounds.R_top, dx
	add	ds:[di].VI_bounds.R_right, cx
	add	ds:[di].VI_bounds.R_bottom, dx
	ret
VisSetPositionRelative endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CardMarkDirtyIfFaceDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_CARD_MARK_DIRTY_IF_FACE_DOWN handler for CardClass
		If card is face up, the CA_DIRTY bit is set

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = card object
		
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
CardMarkDirtyIfFaceDown	method	CardClass, MSG_CARD_MARK_DIRTY_IF_FACE_DOWN
	test	ds:[di].CI_cardAttrs, mask CA_FACE_UP
	jnz	done
	SET	ds:[di].CI_cardAttrs, CA_DIRTY
	call	ObjMarkDirty
done:
	ret
CardMarkDirtyIfFaceDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		ds:di = card instance
		*ds:si = card object

CHANGES:	

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardRelocate	method	CardClass, reloc
	cmp	ax, MSG_META_RELOCATE
	jne	done
	SET	ds:[di].CI_cardAttrs, CA_DIRTY
	call	ObjMarkDirty
done:
	clc
	mov	di, offset CardClass
	call	ObjRelocOrUnRelocSuper
	ret
CardRelocate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardSprayDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	MSG_CARD_SPRAY_DRAW handler for CardClass
		Card rotates the passed gstate and draws itself along the
		y-axis. This is used to effect the 'card fan' visual effect

CALLED BY:	

PASS:		*ds:si = card object
		dx = # degrees to rotate gstate
		cx = y displacement of drawn card
		bp = gstate
		
		
CHANGES:	gstate is rotated by dx degrees

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

CardSprayDraw	method	CardClass, MSG_CARD_SPRAY_DRAW
	push	cx

	;; if a redeal has been requested, or if the game has been iconified,
	;; then we don't want to do anything here

	mov	cx, VUQ_GAME_ATTRIBUTES
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
	test	cl, mask GA_REDEAL_REQUESTED or mask GA_ICONIFIED
	pop	cx

	jnz	done

	push	cx

	clr	cx
	mov	di, bp
	call	GrApplyRotation		;rotate the gstate

	mov	ax, C_WHITE
	call	GrSetAreaColor

	mov	al, MM_COPY		;mode = copy
	call	GrSetMixMode


	pop	dx
	push	dx
	clr	cx
	push	di
	
	mov	bp, di


	;;	draw a generic card background

	mov	ax, MSG_DECK_REQUEST_FAKE_BLANK_CARD
	call	VisCallParent

	mov	ax, MSG_CARD_GET_VM_FILE
	call	ObjCallInstanceNoLock
	mov_tr	bx, ax

	Deref_DI Card_offset
	mov	ax, ds:[di].CI_bitmap.handle
	mov	si, ds:[di].CI_bitmap.chunk
	call	VMLock
	pop	di
	push	bp				;save for unlock

	mov	ds,ax				; set *ds:si = bitmap
	
	lodsw
	call	GrSetAreaColor			;set color (stored in bitmap)

	mov	al, CMT_DITHER
	call	GrSetAreaColorMap

	pop	dx				;clear this off the stack
						;for a minute...
	pop	bx
	clr	ax
	push	dx				;push it back.

	mov	dl, ds:[si].CB_simple.B_type
	and	dl, mask BMT_FORMAT
	cmp	dl, BMF_MONO
	mov	dx, 0
	jne	fullColor
	call	GrFillBitmap			; draw the bitmap
afterDraw:
	pop	bp
	call	VMUnlock
done:
	ret
fullColor:
	call	GrDrawBitmap			; draw the bitmap
	jmp	afterDraw
CardSprayDraw		endm

CardsCodeResource ends
