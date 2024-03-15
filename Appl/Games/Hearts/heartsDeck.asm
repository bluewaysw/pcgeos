COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hearts (trivia project)
FILE:		heartsDeck.asm

AUTHOR:		Peter Weck, Jan 20, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/20/93   	Initial revision


DESCRIPTION:
	
		

	$Id: heartsDeck.asm,v 1.1 97/04/04 15:19:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

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
;			Resources
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

;Class definition is stored in the application's idata resource here.
	HeartsDeckClass

;initialized variables


idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends


;------------------------------------------------------------------------------
;		Code for HeartsDeckClass
;------------------------------------------------------------------------------
CommonCode	segment resource		;start of code resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will save the state of the deck.
		Then if not MyDeck, pass the message on to the 
		neighbor.

CALLED BY:	HeartsDeckRestoreState
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data
		^hcx 	= block of saved data
		dx 	= # bytes written


RETURN:		^hcx - block of saved data
		dx - # bytes written

DESTROYED:	ax

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSaveState	method dynamic HeartsDeckClass, 
					MSG_DECK_SAVE_STATE
	uses	bp

playedCardPtr		local	optr
playersDataPtr		local	optr
chunkPointer		local	optr

	.enter

	call	ObjMarkDirty

	Deref_DI Deck_offset
	tst	ds:[di].HI_deckIdNumber
	jz	exitRoutine

	movdw	playedCardPtr, ds:[di].HI_playedCardPtr, ax
	movdw	playersDataPtr, ds:[di].HI_playersDataPtr, ax
	movdw	chunkPointer, ds:[di].HI_chunkPointer, ax

	movdw	bxsi, playedCardPtr, ax
	call	MemLock
	mov	ds, ax
	call	ObjMarkDirty
	call	MemUnlock
	
	movdw	bxsi, playersDataPtr, ax
	call	MemLock
	mov	ds, ax
	call	ObjMarkDirty
	call	MemUnlock

	movdw	bxsi, chunkPointer, ax
	call	MemLock
	mov	ds, ax
	call	ObjMarkDirty
	call	MemUnlock

exitRoutine:
	.leave
	ret
HeartsDeckSaveState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckDrawScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the score of the deck on to the view.  You can
		pass it a GState or it will create a one, and you can specify
		if you want the score drawn highlighted or not.

CALLED BY:	MSG_HEARTS_DECK_DRAW_SCORE
PASS:		*ds:si	= HeartsDeckClass object
		bp	= passed GState (0 if no GState)
		cx	= color (0 = white, 
				 1 = Grey,
				 DRAW_SCORE_AS_BEFORE = same as before)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will change the sceen

PSEUDO CODE/STRATEGY:
		Create a GState
		Draw the text on the screen, near the current position of
		the deck, and then invalidate the region to get it to 
		redraw the score.
		Destroy the GState

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckDrawScore	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_DRAW_SCORE
	uses	ax, cx, dx, bp

passedGState		local	word	push	bp
currentGState		local	word
position		local	dword

	.enter

	mov	cx, passedGState
	tst	cx
	jnz	GStateAlreadyExists

	push	bp				;save locals
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	cx, bp				;cx <= GState
	pop	bp				;restore locals


GStateAlreadyExists:
	mov	currentGState, cx
	mov	di, cx			;di <= GState

	mov	cx, FID_BERKELEY
	mov	dx, TEXT_POINT_SIZE 
	clr	ah			;point size (fraction) = 0
	call	GrSetFont		;change the GState

	mov	ah, CF_INDEX		;indicate we are using a pre-defined
					;color, not an RGB value.
	mov	al, C_BLACK		;set text color value
	call	GrSetTextColor		;set text color in GState

	mov	al, C_GREEN		;set text color value
	call	GrSetAreaColor		;set area color in GState

	push	bp				;save locals
	mov	ax, MSG_HEARTS_DECK_GET_SCORE_POSITION
	call	ObjCallInstanceNoLock
	pop	bp				;restore locals
	movdw	position, cxdx

	;    Draw players name
	;

	movdw	axbx,cxdx
	add	cx, NAME_LENGTH
	add	dx, NAME_HEIGHT
	call	GrFillRect			;draw over old score	
	clr	cx				;null terminated string
	push	si
	Deref_DI Deck_offset
	mov	si, ds:[di].HI_nameString
	mov	si,ds:[si]
	mov	di,currentGState
	call	GrDrawText
	pop	si

	;    Draw this rounds score
	;

	mov	cx,1				;get this rounds score
	mov	ax,MSG_HEARTS_DECK_GET_SCORE
	call	ObjCallInstanceNoLock
	mov	dx,cx				;this rounds score
	mov	di,currentGState
	movdw	axbx,position
	mov	ax,CHART_HAND_TEXT_X
	call	HeartsDrawNumber

	;    Draw total score
	;

	Deref_DI Deck_offset
	mov	dx, ds:[di].HI_score
	mov	di,currentGState
	movdw	axbx,position
	mov	ax,CHART_GAME_TEXT_X
	call	HeartsDrawNumber

	tst	passedGState		
	jnz	dontDestroyGState
	call	GrDestroyState			;destroy the graphics state

dontDestroyGState:

	.leave
	ret
HeartsDeckDrawScore	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDrawNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a number as an ascii string

CALLED BY:	INTERNAL
		HeartsDeckDrawScore

PASS:		dx - number
		ax - x location
		bx - y location
		di - gstate

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
	srs	7/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDrawNumber		proc	far

positionX	local   word	push ax
positionY	local	word	push bx
score		local	word	push dx
gstate		local	word	push di
memHandle	local	word

	uses	ax,bx,cx,dx,es,di,ds,si
	.enter

	;    Clear area to draw to.
	;

	mov	ah,CF_INDEX
	mov	al,C_GREEN
	call	GrSetAreaColor
	mov	ax,positionX
	mov	bx,positionY
	movdw	cxdx, axbx
	add	cx, SCORE_LENGTH
	add	dx, SCORE_HEIGHT
	call	GrFillRect			;draw over old score	

	;    Create string with score in it
	;

	mov	ax, SIZE_OF_SCORE
	mov	cx, (mask HAF_LOCK or mask HAF_NO_ERR) shl 8 + mask HF_SWAPABLE
	call	MemAlloc
	mov	memHandle, bx			;save the handle to Memory
	mov	es, ax				;mov seg ptr to es
	clr	di				;set offset to zero
	mov	dx,score 
	call	BinToAscii
	segmov	ds, es
	clr	si, cx

	;    Draw the score
	;

	mov	ax,positionX
	mov	bx,positionY
	mov	di,gstate
	clr	cx				;null terminated string
	call	GrDrawText

	mov	bx, memHandle		;get back handle to Mem block
	call	MemFree				;free the block of memory

	.leave
	ret
HeartsDrawNumber		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckDrawName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the name of the deck on to the view.  You can
		pass it a GState or it will create a one

CALLED BY:	MSG_HEARTS_DECK_DRAW_NAME
PASS:		*ds:si	= HeartsDeckClass object
		bp	= passed GState (0 if no GState)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will change the sceen

PSEUDO CODE/STRATEGY:
		Create a GState
		Draw the text on the screen, near the current position of
		the deck, and then invalidate the region to get it to 
		redraw the score.
		Destroy the GState

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckDrawName	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_DRAW_NAME
	uses	ax, cx, dx, bp

passedGState		local	word	push	bp
currentGState		local	word
position		local	Point
yCharAdjust		local	word

	.enter

	mov	di, passedGState
	tst	di
	jnz	GStateAlreadyExists

	push	bp				;save locals
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp				;cx <= GState
	pop	bp				;restore locals

GStateAlreadyExists:
	mov	currentGState, di
	call	GrSaveState

	mov	cx, FID_BERKELEY
	mov	dx, TEXT_POINT_SIZE 
	clr	ah			;point size (fraction) = 0
	call	GrSetFont		;change the GState

	mov	ah, CF_INDEX		;indicate we are using a pre-defined
					;color, not an RGB value.
	mov	al, C_BLACK		;set text color value
	call	GrSetTextColor		;set text color in GState

	mov	al, C_GREEN		
	call	GrSetAreaColor		

	push	bp				;save locals
	mov	ax, MSG_HEARTS_DECK_GET_NAME_POSITION
	call	ObjCallInstanceNoLock
	pop	bp				;restore locals
	mov	position.P_x,cx
	mov	position.P_y,dx
	mov	yCharAdjust,ax

	Deref_DI Deck_offset
	mov	si, ds:[di].HI_nameString
	mov	si,ds:[si]
	mov	di, currentGState		;retrieve GState
	tst	yCharAdjust
	jnz	verticalText

	mov	ax, position.P_x		;retrieve position
	mov	bx, position.P_y		;retrieve position
	movdw	cxdx,axbx
	add	cx, NAME_LENGTH
	add	dx, NAME_HEIGHT
	call	GrFillRect			;draw over old score	

	clr	cx				;null terminated string
	call	GrDrawText

restoreState:
	call	GrRestoreState

	mov	di, passedGState		;retrieve passed GState
	tst	di
	jnz	dontDestroyGState
	call	GrDestroyState			;destroy the graphics state

dontDestroyGState:

	.leave
	ret

verticalText:
	mov	ax, position.P_x		;retrieve position
	mov	bx, position.P_y		;retrieve position
	movdw	cxdx,axbx
	add	cx, NAME_VERT_WIDTH
	add	dx, NAME_VERT_HEIGHT
	call	GrFillRect			;draw over old score	

drawCharLoop:
	mov	dl,ds:[si]
	tst	dl
	jz	restoreState
	inc	si
	call	GrDrawChar
	add	bx,yCharAdjust			;advance y position
	jmp	drawCharLoop

HeartsDeckDrawName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetScorePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the position where the score should be printed.

CALLED BY:	HeartsDeckDrawScore
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		cx,dx	= position for score
DESTROYED:	ax, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetScorePosition	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_SCORE_POSITION
	.enter

ifdef	STEVE

	mov	ax, MSG_VIS_GET_POSITION
	call	ObjCallInstanceNoLock
endif
	Deref_DI Deck_offset

	mov	cx, ds:[di].HI_scoreXPosition
	mov	dx, ds:[di].HI_scoreYPosition

	.leave
	ret
HeartsDeckGetScorePosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetNamePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the position where the name should be printed.

CALLED BY:	HeartsDeckDrawName
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		cx,dx	= position for name
		ax 	= rotation for name
		
DESTROYED:	bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetNamePosition	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_NAME_POSITION
	.enter

	mov	ax, MSG_VIS_GET_POSITION
	call	ObjCallInstanceNoLock

	Deref_DI Deck_offset
	add	cx, ds:[di].HI_namePosition.P_x
	add	dx, ds:[di].HI_namePosition.P_y
	mov	ax, ds:[di].HI_nameYCharAdjust

	.leave
	ret
HeartsDeckGetNamePosition	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckTurnRedIfWinner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will highlight the score of the winner(s).

CALLED BY:	MSG_HEARTS_DECK_TURN_RED_IF_WINNER
PASS:		*ds:si	= HeartsDeckClass object
		cx	= winners score

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will turn text red if winning score

PSEUDO CODE/STRATEGY:
		check if the winners score, and if it is then
		call HeartsDeckDrawScore with cx = 1 (draw red)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckTurnRedIfWinner	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_TURN_RED_IF_WINNER
	uses	ax, cx, bp
	.enter

	cmp	ds:[di].HI_score, cx
	jne	exitRoutine

	clr	bp				;no GState exists
	mov	cx, DRAW_SCORE_HIGHLIGHTED
	mov	ax, MSG_HEARTS_DECK_DRAW_SCORE
	call	ObjCallInstanceNoLock

exitRoutine:
	.leave
	ret
HeartsDeckTurnRedIfWinner	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BinToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts dx to null terminated ascii string

CALLED BY:	

PASS:		dx	- value to convert	
		es:di	- buffer for ascii string		

RETURN:		es:di	- null terminated ascii string

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	08/24/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BinToAscii	proc 	near

	mov	ax, dx
	push  bx, cx, dx, bp
	mov     bx, 10                          ;print in base ten
	clr     cx, bp

	cmp	ax, 0				;check if negative
	jge	nextDigit
;negative:
	neg	ax				;make positive
	inc	bp
nextDigit:
	clr     dx
	div     bx
	add     dl, '0'                         ;convert to ASCII
	push    dx                              ;save resulting character
	inc     cx                              ;bump character count
	tst     ax                              ;check if done
	jnz     nextDigit                   	;if not, do next digit

	tst	bp				;check if negative
	jz	nextChar
;negative:
	mov	al, '-'
	stosb
nextChar:
	pop     ax                              ;retrieve character (in AL)
	stosb                                   ;stuff in buffer
	loop    nextChar                    	;loop to stuff all
	clr     al
	stosb                                   ;null-terminate it
	pop bx, cx, dx, bp
	ret
BinToAscii	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckInvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inverts the top card of the deck

CALLED BY:	HeartsDeckPlayCard
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	inverts top card of deck

PSEUDO CODE/STRATEGY:
		call superclass with MSG_DECK_INVERT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckInvert	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_INVERT
	uses	ax, cx, dx, bp
	.enter

;saving ax,bx,cx,bp because the superclass destroyes these registers

	mov	ax, MSG_DECK_INVERT
	mov	di, offset HeartsDeckClass
	call	ObjCallSuperNoLock

	.leave
	ret
HeartsDeckInvert	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartDeckInvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We are subclassing this method because we don't want it to
		do anything.  Normally it inverts the top card of the deck.
		If you want to call this routine, you can call
		MSG_HEARTS_DECK_INVERT it calls the superclasses routine
		MSG_DECK_INVERT

CALLED BY:	MSG_DECK_INVERT
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data
		ds:bx	= HeartsDeckClass object (same as *ds:si)
		es 	= segment of HeartsDeckClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartDeckInvert	method dynamic HeartsDeckClass, 
					MSG_DECK_INVERT
	.enter
	.leave
	ret
HeartDeckInvert	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of HeartDeckClass

RETURN:		

	
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
	srs	5/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckStartSelect	method dynamic HeartsDeckClass, 
						MSG_META_START_SELECT
	.enter

	mov	di,offset HeartsDeckClass
	call	ObjCallSuperNoLock

	.leave
	ret
HeartsDeckStartSelect		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckCardSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when one of the deck's face up cards receives a
		click event.  If the deck is MyDeck, then will send the
		card to the discard deck if it is ok to.
		If the deck is DiscardDeck and four cards have been played,
		then it will transfer the cards to MyDiscardDeck.

CALLED BY:	Game object

PASS:		*ds:si	= HeartsDeckClass object
		bp	= # of child in composite that was double-clicked
			  (bp = 0 for first child)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	may move the card to the discard deck

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckCardSelected	method dynamic HeartsDeckClass, 
					MSG_DECK_UP_CARD_SELECTED
	uses	ax, cx, dx, bp
	.enter

	;    Only accept clicks on face up cards in the players deck
	;

	mov	bx, handle MyDeck
	cmp	bx, ds:[LMBH_handle]
	jne	done
	cmp	si, offset MyDeck
	jne 	done

	;     Check for being in passing cards mode
	;

	push	cx				;mouse x position
	mov	ax, MSG_HEARTS_GAME_GET_GAME_ATTRS
	call	VisCallParent
	mov	ax,cx				;attrs
	pop	cx				;mouse x position
	test	al, mask HGA_PASSING_CARDS
	jnz	passingCards			

	;    See if card can be placed in trick
	;

	push	bp					;save card number
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	push	cx, dx					;save ^lcx:dx
	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_TEST_SUIT_CONDITION
	call	ObjMessage
	mov	al, cl					;al <= explaination
	pop	cx, dx					;restore ^lcx:dx
	pop	bp					;restore card number
	jc	moveCards				;will accept

	;    Can't play card, let the player know
	;

	mov	cl, al					;cl <= explaination
	mov	dx, HS_WRONG_PLAY			;dx <= sound to play
	mov	ax, MSG_HEARTS_DECK_EXPLAIN
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage


done:
	.leave
	ret

passingCards:
	call	HeartsDeckAddToChunkArray
	jmp	done

moveCards:
	xchg	bx, cx					;switch donnor and
	xchg	si, dx					;reciever
	xchg	cx, bp					;setup card number
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_SHIFT_CARDS
;	clr	ch					;redraw deck
	call	ObjMessage

	mov	cx, bp					;setup reciever
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_PLAY_TOP_CARD
	call	ObjMessage

	push	si					;save offset
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	ax, MSG_HEARTS_GAME_GET_CARDS_PLAYED
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	inc	cl					;increment cards played
	mov	ax, MSG_HEARTS_GAME_SET_CARDS_PLAYED
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si					;restore offset

	;    Play sounds associated with card played if any
	;

	mov	ax, MSG_HEARTS_GAME_CHECK_PLAY_SOUND
	call	VisCallParent

	mov	ax, DRAW_SCORE_HIGHLIGHTED		;redraw score highlight
	call	HeartsDeckSetComputerPlayer


	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_neighborPointer
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
				;changed to force_queue to make sure
				;deck updated itself before the next
				;card is played
	mov	ax, MSG_HEARTS_DECK_PLAY_CARD
	call	ObjMessage
	jmp	done

HeartsDeckCardSelected	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckDownCardSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for MSG_DECK_DOWN_CARD_SELECTED.
		The procedure intercepts the message so that
		clicking on a down card will not flip it over.

CALLED BY:	MSG_DECK_DOWN_CARD_SELECTED
PASS:		*ds:si	= HeartsDeckClass object
		bp = # of selected child in composite

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckDownCardSelected	method dynamic HeartsDeckClass, 
					MSG_DECK_DOWN_CARD_SELECTED
	uses	ax, cx, dx, bp
	.enter

	mov	ax, ds:[LMBH_handle]
	cmp	ax, handle MyDiscardDeck
	jnz	notMyDiscardDeck
	cmp	si, offset MyDiscardDeck
	jnz	notMyDiscardDeck
;isMyDiscardDeck:
	test	ds:[di].HI_deckAttributes, mask HDA_FLIPPING_TAKE_TRICK
	jnz	notMyDiscardDeck
	push	si					;save offset
	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	ax, MSG_VIS_GET_ATTRS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si					;restore offset
	test	cl, mask VA_DETECTABLE
	jz	notMyDiscardDeck
	call	HeartsDeckFlipLastTrick

notMyDiscardDeck:
	;nothing here because we don't want to do anything.

	.leave
	ret
HeartsDeckDownCardSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFlipLastTrick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will Flip the last trick that was played

CALLED BY:	HeartsDeckDownCardSelected
PASS:		*ds:si	= MyDiscardDeck

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will flip the top NUMBER_OF_PLAYERS card of the deck

PSEUDO CODE/STRATEGY:
		Will move ShowLastTrickDeck to a visible point on the screen,
		then will Pop the top NUMBER_OF_PLAYERS cards from 
		MyDiscardDeck and push them face up onto ShowLastTrickDeck
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/25/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFlipLastTrick	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	class	HeartsDeckClass

	clr	ax				;don't redraw the score
	call	HeartsDeckSetComputerPlayer	;disable player movements
	Deref_DI Deck_offset
	BitSet	ds:[di].HI_deckAttributes, HDA_FLIPPING_TAKE_TRICK
	call	ObjMarkDirty
;	call	HeartsDeckSetComputerPlayer	;disable futher play

	push	si				;save offset

	mov	cx, SHOWLASTTRICKDECK_DISPLAY_X_POSITION
	mov	dx, SHOWLASTTRICKDECK_DISPLAY_Y_POSITION
	mov	bx, handle ShowLastTrickDeck
	mov	si, offset ShowLastTrickDeck
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	movdw	cxdx, bxsi			;^lcx:dx <= ShowLastTrickDeck
	pop	si				;restore handle

	mov	ax, MSG_HEARTS_DECK_TRANSFER_N_CARDS
	mov	bp, NUMBER_OF_CARDS_IN_TRICK
	call	ObjCallInstanceNoLock

	mov	ax, MSG_CARD_MAXIMIZE		;make sure deck doesn't 
	call	VisCallFirstChild		;disappear

	mov	bx, segment CardClass
	mov	si, offset CardClass
	mov	ax, MSG_CARD_TURN_FACE_UP
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	cx, di				;cx <= event
	mov	bx, handle ShowLastTrickDeck
	mov	si, offset ShowLastTrickDeck
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_SEND_TO_CHILDREN
	call	ObjMessage

	mov	ax, MSG_DECK_REDRAW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax,SHOW_LAST_TRICK_TIMER_INTERVAL
	call	TimerSleep

	mov	bx, handle MyDiscardDeck 
	mov	si, offset MyDiscardDeck
	mov	ax, MSG_HEARTS_DECK_DONE_FLIPPING
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HeartsDeckFlipLastTrick	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HearstDeckTransferNCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfers a specified number of cards to another deck.

CALLED BY:	HeartsDeckFlipLastTrick

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
		recipient and each time a card is removed, maximize it.

KNOWN BUGS/IDEAS:
*WARNING*
A deck must never transfer to itself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckTransferNCards	method	HeartsDeckClass,
				 MSG_HEARTS_DECK_TRANSFER_N_CARDS
	push	cx,dx,bp
	mov	ds:[di].DI_lastRecipient.handle, cx
	mov	ds:[di].DI_lastRecipient.chunk, dx
	mov	ds:[di].DI_lastGift, bp
	call	ObjMarkDirty
	
	mov	ax, MSG_GAME_SET_DONOR
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	VisCallParent
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

	mov	bp, si					;save offset
	pop	bx,si					;restore recipient OD
	push	bp					;push donor offset
	push	bx,si

	push	cx,dx					;save card OD
	mov	ax, MSG_DECK_PUSH_CARD			;give card to recipient
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx,si					;restore card OD
	mov	ax, MSG_CARD_MAXIMIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	cx, dx
	pop	si					;restore donor offset
	pop	bp					;restore count

	jmp	startDeckTransferNCards

endDeckTransferNCards:
	ret
HeartsDeckTransferNCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckDoneFlipping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the flipped cards to MyDiscardDeck from
		ShowLastTrickDeck

CALLED BY:	The timer and sent to MyDiscardDeck
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= instance data

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will remove cards from ShowLastTrickDeck and add them to 
		MyDiscardDeck

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckDoneFlipping	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_DONE_FLIPPING
	uses	ax, cx, dx, bp
	.enter

	BitClr	ds:[di].HI_deckAttributes, HDA_FLIPPING_TAKE_TRICK
	call	ObjMarkDirty
	movdw	axbx, ds:[di].HI_timerData	;restore ID and Handle
	call	TimerStop

;	call	HeartsDeckSetComputerPlayer	;disable futher play

	mov	bx, handle ShowLastTrickDeck
	mov	si, offset ShowLastTrickDeck
	mov	ax, MSG_VIS_GET_BOUNDS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL	
	call	ObjMessage
	push	ax,bp,cx,dx			;save boundry

	mov	cx, handle MyDiscardDeck
	mov	dx, offset MyDiscardDeck
	mov	ax, MSG_HEARTS_DECK_TRANSFER_ALL_CARDS_FACE_DOWN
	mov	di, mask MF_FIXUP_DS or mask MF_CALL	
	call	ObjMessage

	mov	si, offset MyDiscardDeck
	mov	ax, MSG_CARD_MAXIMIZE
	call	VisCallFirstChild

	mov	cx, SHOWLASTTRICKDECK_X_POSITION
	mov	dx, SHOWLASTTRICKDECK_Y_POSITION
;	mov	bx, handle ShowLastTrickDeck
	mov	si, offset ShowLastTrickDeck
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	si, offset MyDiscardDeck
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp				;di <= GState

	pop	ax,bx,cx,dx			;restore boundry
	call	GrInvalRect
	call	GrDestroyState

	clr	ax				;don't draw score in red.
	call	HeartsDeckSetHumanPlayer	;enable player movements
;	mov	bx, handle MyDiscardDeck
;	mov	si, offset MyDiscardDeck
;	mov	ax, MSG_DECK_REDRAW
;	mov	di, mask MF_FIXUP_DS or mask MF_CALL
;	call	ObjMessage


	.leave
	ret
HeartsDeckDoneFlipping	endm



ifdef STEVE
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckUpCardSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_UP_CARD_SELECTED handler for DeckClass
		This method determines which card will
		be dragged as a result of this card selection

CALLED BY:	CardStartSelect

PASS:		*ds:si = deck object
		cx,dx = mouse
		bp = # of card selected

RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckUpCardSelected	method dynamic HeartsDeckClass, 
					MSG_DECK_UP_CARD_SELECTED
	.enter

	push	cx				;save mouse x-position
	mov	ax, MSG_HEARTS_GAME_GET_GAME_ATTRS
	call	VisCallParent
	test	cl, mask HGA_PASSING_CARDS
	jz	notPassingCards

;passingCards:
	pop	cx				;restore mouse x-position
	call	HeartsDeckAddToChunkArray
	jmp	exitRoutine

notPassingCards:
	pop	cx				;restore mouse x-position
	mov	ax, bp
	mov	ds:[di].HI_chosenCard, al
	call	ObjMarkDirty
	mov	bp, 1			;we only want to move one card
	mov	ax, MSG_DECK_DRAGGABLE_CARD_SELECTED
	call	ObjCallInstanceNoLock

exitRoutine:
	.leave
	ret
HeartsDeckUpCardSelected	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckAddToChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will add or delete the card in bp to/from the chunk array

CALLED BY:	HeartsDeckUpCardSelected
PASS:		*ds:si	= deck object
		cx,dx	= mouse
		bp	= # of card selected

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	may add or delete card to/from chunk array

PSEUDO CODE/STRATEGY:
		If card is already in the chunk array, then uninvert it
		and delete it from the chunk array.

		If the card is not already in the chunk array and
		not too many cards have been selected, then invert the
		card and add it to the chunk array.

		If the card is not in the chunk array, but the maximum
		number of cards have been selected, then remove the
		most recently selected card and add the currently selected
		card to the chunk array.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/22/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckAddToChunkArray	proc	near

cardSelected		local	word	push	bp
mouse			local	dword	push	cx,dx
cardAttrs		local	byte
numPassCards		local	byte
deckOptr		local	optr

	.enter
	class	HeartsDeckClass

	mov	ax, ds:[LMBH_handle]
	movdw	deckOptr, axsi

	push	bp				;save local vars ptr
	mov	bp, cardSelected
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp				;al <= card attrs.
	pop	bp				;restore local vars ptr
	mov	cardAttrs, al

	mov	ax, MSG_HEARTS_GAME_GET_NUMBER_OF_PASS_CARDS
	call	VisCallParent
	mov	numPassCards, cl

	movdw	bxsi, ds:[di].HI_chunkPointer
	call	MemLock
	mov	ds, ax

	call	ChunkArrayGetCount
	mov	dx, cardSelected		;dl <= card to search for
	mov	dh, cl				;dh <= # array elements

			;search to see if the card is already selected
	clr	ax				;ax <= counter

continueSearch:
	cmp	dh, al
	jz	elementNotFound			;counter = # array elements

	call	ChunkArrayElementToPtr
	cmp	dl, ds:[di].PCD_cardNumber	;test the card number
	jz	foundElement
	inc	al
	jmp	continueSearch

elementNotFound:
	mov	al, numPassCards
	cmp	dh, al
	je	alreadyEnoughSelected
	dec 	al
	cmp	dh, al
	jl	addElement

;enable the take trigger
	push	bx,si,bp			;save handle, offset, local
	mov	bx, handle HeartsPassTrigger
	mov	si, offset HeartsPassTrigger
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx,si,bp			;restore handle, offset, local
	jmp	addElement

alreadyEnoughSelected:
	mov	cl, ds:[di].PCD_cardNumber
	call	ChunkArrayDelete		;delete last element

	mov	bx, ds:[LMBH_handle]
	xchgdw	bxsi, deckOptr, ax
	call	MemDerefDS
	mov	ax, MSG_HEARTS_DECK_CLEAR_INVERTED_NTH_CARD
	call	ObjCallInstanceNoLock
	xchgdw	bxsi, deckOptr, ax
	call	MemDerefDS
	
addElement:
	call	ChunkArrayAppend
	mov	ax, cardSelected
	mov	ds:[di].PCD_cardNumber, al
	mov	al, cardAttrs
	mov	ds:[di].PCD_cardAttribute, al
	jmp	invertCard

foundElement:	
	call	ChunkArrayDelete		;delete the element

;disable the take trigger
	push	bx,si,bp			;save handle, offset, local
	mov	bx, handle HeartsPassTrigger
	mov	si, offset HeartsPassTrigger
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx,si,bp			;restore handle, offset, local

invertCard:
	call	ObjMarkDirty
	call	MemUnlock			;release chunk array
	movdw	bxsi, deckOptr
	call	MemDerefDS
	movdw	cxdx, mouse
	mov	ax, MSG_CARD_INVERT
	push	bp				;save local vars ptr
	call	VisCallChildUnderPoint
	pop	bp				;restore local vars ptr
	
;exitRoutine:
	.leave
	ret
HeartsDeckAddToChunkArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckClearInvertedNthCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will uninvert the nth card of the deck

CALLED BY:	MSG_HEARTS_DECK_CLEAR_INVERTED_NTH_CARD
PASS:		*ds:si	= HeartsDeckClass object
		cl	= card to invert (0 is first card)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will uninvert the nth card in the deck

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckClearInvertedNthCard	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_CLEAR_INVERTED_NTH_CARD
	uses	ax, cx, dx, bp
	.enter

	mov	dl, cl
	clr	dh				;dx <= child to invert
	clr	cx
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock		;now ^lcx:dx = child

	movdw	bxsi, cxdx
	mov	ax, MSG_CARD_CLEAR_INVERTED
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
HeartsDeckClearInvertedNthCard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckUninvertChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will uninvert the cards associated with the chunk array

CALLED BY:	MSG_HEARTS_DECK_UNINVERT_CHUNK_ARRAY
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will uninvert cards in the deck

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckUninvertChunkArray	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_UNINVERT_CHUNK_ARRAY
	uses	ax, cx, dx, bp


	.enter

	tstdw	ds:[di].HI_chunkPointer
	jz	exitRoutine			;no chunk array

	mov	ax, MSG_CARD_CLEAR_INVERTED
	call	VisSendToChildren

exitRoutine:
	.leave
	ret
HeartsDeckUninvertChunkArray	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckClearChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will clear the Chunk array if it points anywhere

CALLED BY:	MSG_HEARTS_DECK_CLEAR_CHUNK_ARRAY
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will clear the chunk array

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckClearChunkArray	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_CLEAR_CHUNK_ARRAY
	uses	ax, cx, dx
	.enter

	tstdw	ds:[di].HI_chunkPointer
	jz	exitRoutine			;no chunk array

;clearTheArray:
	movdw	bxsi, ds:[di].HI_chunkPointer
	call	MemLock				;lock down LMemBlock
	mov	ds, ax
	call	ChunkArrayZero			;clear all elements
	call	ObjMarkDirty
	call	MemUnlock			;unlock the LMemBlock

exitRoutine:
	.leave
	ret
HeartsDeckClearChunkArray	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetNeighborPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the neighborPointer instance data

CALLED BY:	MSG_HEARTS_DECK_UPDATE_PASS_POINTER
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		^lcx:dx	= neighborPointer
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetNeighborPointer	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_NEIGHBOR_POINTER
	.enter

	movdw	cxdx, ds:[di].HI_neighborPointer

	.leave
	ret
HeartsDeckGetNeighborPointer	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckClearPassPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will clear the passPointer instance data

CALLED BY:	MSG_HEARTS_DECK_CLEAR_PASS_POINTER
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will clear the passPointer instance data

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckClearPassPointer	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_CLEAR_PASS_POINTER
	.enter

	clrdw	ds:[di].HI_passPointer
	call	ObjMarkDirty

	.leave
	ret
HeartsDeckClearPassPointer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HeartsDeckDropDrags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_DROP_DRAGS handler for HeartsDeckClass

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
			and then issues a MSG_HEARTS_DECK_PLAY_CARD to its
			neighbor
		else:
			issues a MSG_DECK_REPAIR_FAILED_TRANSFER to self

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/26/93		Initial Version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckDropDrags	method		HeartsDeckClass, MSG_DECK_DROP_DRAGS

	.enter

	mov	ax, MSG_DECK_GET_DROP_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GAME_DROPPING_DRAG_CARDS
	mov	cx, ds:[LMBH_handle]			;tell parent to
	mov	dx, si					;advertise the dropped
	call	VisCallParent				;cards
							
	jnc	repair

	mov	ax, MSG_DECK_REPAIR_SUCCESSFUL_TRANSFER
	call	ObjCallInstanceNoLock
	
	;;call the next player to play a card

	mov	ax, MSG_HEARTS_GAME_GET_CARDS_PLAYED
	call	VisCallParent
	inc	cl					;increment cards played
	mov	ax, MSG_HEARTS_GAME_SET_CARDS_PLAYED
	call	VisCallParent

	mov	ax, DRAW_SCORE_HIGHLIGHTED		;redraw score in Green
	call	HeartsDeckSetComputerPlayer
	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_neighborPointer
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	ax, MSG_HEARTS_DECK_PLAY_CARD
	call	ObjMessage

	jmp	repairDone

repair:
	mov	ax, MSG_DECK_REPAIR_FAILED_TRANSFER	;do visual repairs
	call	ObjCallInstanceNoLock

repairDone:
	.leave
	ret
HeartsDeckDropDrags	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the chunk-arrays in the same segment as the 
		HeartsDeckClass objects, and stores the handles to the 
		chunk arrays in the object's instance data.  
		The chunk arrays are of variable length, but each entry
		 is a fixed size

CALLED BY:	HeartsGameSetupGeometry
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	may move around the local memory heap it is given

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetChunkArray	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_SET_CHUNK_ARRAY
	uses	ax, cx

localMemHandle		local	word
deckOD			local	optr
chunkPointerOffset	local	lptr
playersDataOffset	local	lptr
playedCardOffset	local	lptr

	.enter

	mov	bx, ds:[LMBH_handle]
	mov	localMemHandle, bx
	movdw	deckOD, bxsi

	mov	bx, size PassCardData		
	clr	cx, si
	mov	ax, mask OCF_DIRTY
	call	ChunkArrayCreate
	mov	chunkPointerOffset, si

	mov	bx, size PlayerData
	clr	si
	call	ChunkArrayCreate
	mov	playersDataOffset, si

	mov	bx, size TrickData
	clr	si
	call	ChunkArrayCreate
	mov	playedCardOffset, si

	movdw	bxsi, deckOD
	call	MemDerefDS
	Deref_DI Deck_offset
	mov	ax, localMemHandle		;get local mem block handle
	mov	cx, chunkPointerOffset
	movdw	ds:[di].HI_chunkPointer, axcx

	mov	cx, playersDataOffset
	movdw	ds:[di].HI_playersDataPtr, axcx

	mov	cx, playedCardOffset
	movdw	ds:[di].HI_playedCardPtr, axcx
	call	ObjMarkDirty

	.leave
	ret
HeartsDeckSetChunkArray	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will return a handle to the chunk array of the deck

CALLED BY:	HeartsDeckSwitchPassCards
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		^lcx:dx	= handle to the chunk array
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetChunkArray	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_CHUNK_ARRAY
	.enter

	movdw	cxdx, ds:[di].HI_chunkPointer

	.leave
	ret
HeartsDeckGetChunkArray	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetNeighbor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the neighbor instance data for the deck.

CALLED BY:	MSG_HEARTS_DECK_SET_NEIGHBOR
PASS:		*ds:si	= HeartsDeckClass object
		^lcx:dx	= the optr of the neighbor

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	set the instance data for the deck

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetNeighbor	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_SET_NEIGHBOR
	.enter

	movdw	ds:[di].HI_neighborPointer, cxdx
	call	ObjMarkDirty

	.leave
	ret
HeartsDeckSetNeighbor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckDrawPlayerInstructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws text above the players cards

CALLED BY:	INTERNAL

PASS:		*ds:si - an object in the visual tree
		di - offset of string in StringResource

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
	srs	7/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckDrawPlayerInstructions		proc	far
	uses	ax,bx,cx,dx,di,bp,ds,si
	.enter

	push	di				;string offset

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp				;cx <= GState

	mov	cx, FID_BERKELEY
	mov	dx, TEXT_POINT_SIZE 
	clr	ah			;point size (fraction) = 0
	call	GrSetFont		;change the GState

	mov	ah, CF_INDEX		;indicate we are using a pre-defined
					;color, not an RGB value.
	mov	al, C_BLACK		;set text color value
	call	GrSetTextColor		;set text color in GState

	mov	al, C_GREEN		
	call	GrSetAreaColor		

   ;	mov	ax, 0     jfh changed
	mov	ax, INSTRUCTION_TEXT_X
	mov	bx, INSTRUCTION_TEXT_Y
	movdw	cxdx,axbx
	add	cx, INSTRUCTION_TEXT_WIDTH
	add	dx, INSTRUCTION_TEXT_HEIGHT
	call	GrFillRect			;draw over old score	

	mov	bx,handle StringResource
	call	MemLock
	mov	ds,ax
	pop	si				;string offst
	mov	si,ds:[si]
	;lodsw					;was: ax <-- x pos
			; RB: this value was not really used, see below
			; So, the corresponding ui code has been changed 
			; by removing the x-offset value. This primarily
			; makes the strings localizable.
	clr	cx				;null terminated string
	mov	ax, INSTRUCTION_TEXT_X       ; jfh added
	mov	bx, INSTRUCTION_TEXT_Y
	call	GrDrawText
	mov	bx,handle StringResource
	call	MemUnlock

	call	GrDestroyState			;destroy the graphics state

	.leave
	ret

HeartsDeckDrawPlayerInstructions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetHumanPlayer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will enable the human player to choose a card and 
		place it on the discard pile.

CALLED BY:	HeartsDeckPlayCard
PASS:		ax	= DRAW_SCORE_HIGHLIGHTED if the score should be draw
				in red
			!= DRAW_SCORE_HIGHLIGHTED, don't redraw the score.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetHumanPlayer	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	class	HeartsDeckClass

	mov	bx, handle MyDeck
	mov	si, offset MyDeck

	cmp	ax, DRAW_SCORE_HIGHLIGHTED
	jne	dontRedrawScoreInRed

	clr	bp				;no GState to pass
	mov	cx, DRAW_SCORE_HIGHLIGHTED
	mov 	ax, MSG_HEARTS_DECK_DRAW_SCORE
	mov	di, mask MF_CALL
	call	ObjMessage

dontRedrawScoreInRed:
;	mov	bx, handle MyDeck
;	mov	si, offset MyDeck
	mov	ax, MSG_VIS_SET_ATTRS
	mov	dl, VUM_NOW
	mov	cx, mask VA_DETECTABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage


	.leave
	ret
HeartsDeckSetHumanPlayer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetComputerPlayer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will disable the human player from being able to move
		any cards.

CALLED BY:	HeartsDeckDropDrags
PASS:		ax	= DRAW_SCORE_HIGHLIGHTED if the score of MyDeck should
				be un-highlighted
			!= DRAW_SCORE_HIGHLIGHTED, don't redraw the score.

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetComputerPlayer	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	class	HeartsDeckClass

	mov	bx, handle MyDeck
	mov	si, offset MyDeck

	cmp	ax, DRAW_SCORE_HIGHLIGHTED
	jne	dontRedrawScoreInRed

	clr	bp				;no GState to pass
	clr	cx				;don't draw score in Red
	mov 	ax, MSG_HEARTS_DECK_DRAW_SCORE
	mov	di, mask MF_CALL
	call	ObjMessage

dontRedrawScoreInRed:
;	mov	bx, handle MyDeck
;	mov	si, offset MyDeck
	mov	ax, MSG_VIS_SET_ATTRS
	mov	dl, VUM_NOW
	mov	cx, (mask VA_DETECTABLE) shl 8
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HeartsDeckSetComputerPlayer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetDiscardDeck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will set or unset the DiscardDeck as dectectable

CALLED BY:	
PASS:		cx	= 0 for setting undectable
			= 1 for setting dectable
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di
SIDE EFFECTS:	will set or unset discarddeck

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/19/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetDiscardDeck	proc	near
	.enter

	mov	ax, (mask VA_DETECTABLE) shl 8
	jcxz	setUndetectable
;setDetectable:
	mov	ax, mask VA_DETECTABLE
setUndetectable:
	mov	cx, ax

	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	ax, MSG_VIS_SET_ATTRS
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HeartsDeckSetDiscardDeck	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetTakeTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up the timer to take the trick.

CALLED BY:	HeartsDeckPlayCard
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/27/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetTakeTrigger	proc	near
	uses	ax,bx,cx,dx,si,di
	.enter
	class	HeartsDeckClass

	mov	ax,SHOW_TRICK_BEFORE_TAKING_IT_TIMER_INTERVAL
	call	TimerSleep

	mov	bx, handle DiscardDeck 
	mov	si, offset DiscardDeck
	mov	ax, MSG_HEARTS_DECK_TAKE_TRICK
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HeartsDeckSetTakeTrigger	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetupDrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_SETUP_DRAG handler for DeckClass
		Prepares the deck's drag instance data for dragging.

CALLED BY:	

PASS:		*ds:si = deck object
		cx,dx = mouse position
		bp = # of children to drag

RETURN:		nothing
DESTROYED:	ax, bp
SIDE EFFECTS:	fills in some drag data	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetupDrag	method dynamic HeartsDeckClass, 
					MSG_DECK_SETUP_DRAG
	.enter

	push	cx,dx					;save mouse position
	push	bp
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock
	Deref_DI Deck_offset
	mov	ax, ds:[di].DI_offsetFromUpCardX
	mov	ah, ds:[di].HI_chosenCard
	mul 	ah
	add	cx, ax					;add offset to the
							;right position
	mov	ds:[di].DI_initRight, cx
	mov	ds:[di].DI_initBottom, dx
	pop	bp

	mov	cx, VUQ_CARD_DIMENSIONS
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
	push	dx

	Deref_DI Deck_offset
	mov	ds:[di].DI_nDragCards, bp
	mov	al, ds:[di].HI_chosenCard
	clr	ah
	mov	bp, ax					;bp <- drag card #
	push	bp					;save drag card #

	mov	ax, ds:[di].DI_offsetFromUpCardX	;ax <- horiz. offset
	mul	bp					;ax <- offset * #cards
							; = total offset

;	add	cx, ax
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

	.leave
	ret
HeartsDeckSetupDrag	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetDropCardAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the drop cards attributes

CALLED BY:	MSG_DECK_GET_DROP_CARD_ATTRIBUTES
PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		
RETURN:		bp = CardAttrs of the drop card
		The "drop card" is the card in a drag group whose attributes
		must be checked when determining the legality of a transfer

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetDropCardAttributes	method dynamic HeartsDeckClass, 
					MSG_DECK_GET_DROP_CARD_ATTRIBUTES
	.enter

	mov	al, ds:[di].HI_chosenCard
	clr	ah
	mov	bp, ax
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock

	.leave
	ret
HeartsDeckGetDropCardAttributes	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckTransferDraggedCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_TRANSFER_DRAGGED_CARDS handler for DeckClass
		Transfers the deck's drag cards (if any) to another deck.
CALLED BY:	MSG_DECK_TRANSFER_DRAGGED_CARDS

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		^lcx:dx = deck to which to transfer the cards
		
RETURN:		nothing

DESTROYED:	ax, bp, cx, dx

SIDE EFFECTS:	deck *ds:si transfers its cards to deck ^lcx:dx	

PSEUDO CODE/STRATEGY:
		forwards the call to MSG_HEARTS_DECK_TRANSFER_NTH_CARD, 
		setting N to the number of dragged card

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckTransferDraggedCards	method dynamic HeartsDeckClass, 
					MSG_DECK_TRANSFER_DRAGGED_CARDS
	.enter

	mov	al, ds:[di].HI_chosenCard	;set bp = # drag card
	clr	ah
	mov	bp, ax
	mov	ax, MSG_HEARTS_DECK_TRANSFER_NTH_CARD	;and transfer them
	call	ObjCallInstanceNoLock

	.leave
	ret
HeartsDeckTransferDraggedCards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckTestSuitCondition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	test to see if the deck will accept the card that is
		being discarded.

CALLED BY:	MSG_HEARTS_DECK_TEST_SUIT_CONDITION

PASS:		*ds:si = instance data of deck
		bp = CardAttr of the drop card (bottom card in the drag)
		^lcx:dx = potential donor deck

RETURN:		carry set if transfer occurs,
		carry clear if not
		cl	= reason card not accepted

DESTROYED:	ax, ch, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	check if this is the first play of the game and if it is, then
	only accept the two of clubs.
	
	check if the deck is empty, and if so, then accept the card
	if not then :
		check to see if the card being discarded is of the same
		suit as the first card in the deck, and if it is then accept
		it and if not then:
			check if the donor deck is out of the suit that was
			lead (the suit of the first card in the deck), and
			if so, accept the card and if not, then reject the
			card.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckTestSuitCondition	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_TEST_SUIT_CONDITION
	.enter

	push	cx				;save handle of donnor deck
	mov	ax, MSG_HEARTS_GAME_GET_CARDS_PLAYED
	call	VisCallParent
	cmp	cl, 0
	pop	cx				;restore handle of donnor deck
	jge	notFirstCardOfGame

	mov	cl, MUST_PLAY_TWO_OF_CLUBS
	and	bp, SUIT_MASK or RANK_MASK
	cmp	bp, TWO or CLUBS
	jne	dontAcceptCard
	clr	cl				;set number of cards played
						;to zero
	mov	ax, MSG_HEARTS_GAME_SET_CARDS_PLAYED
	call	VisCallParent
	stc
	jmp	acceptCard

notFirstCardOfGame:

	push	cx

	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	mov	ax, cx
	pop	cx
	tst	ax				;check if deck is empty
	jnz	deckNotEmpty
;deckEmpty:
	and	bp, SUIT_MASK
	mov	ax, HEARTS
	cmp	ax, bp				;check if it is a heart
	stc
	jne	acceptCard
;heartPlayed:
	push	cx				;save handle
	mov	ax, MSG_HEARTS_GAME_CHECK_HEARTS_BROKEN
	call	VisCallParent
	tst	cl
	stc
	pop	cx				;restore handle
	jnz	acceptCard
	call	HeartsDeckMakeSureNotJustHeartsLeft
	jc	acceptCard
	mov	cl, HEARTS_NOT_BROKEN_YET
	jmp	dontAcceptCard	

deckNotEmpty:
	push	bp				;save card attributes
	mov	bp, ax
	dec	bp				;set bp to bottom card number
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	pop	ax				;restore card attributes
	push	bp				;save card attributes
	and	bp, SUIT_MASK
	and	ax, SUIT_MASK
	cmp	ax, bp				;check if suits are the same
	pop	bp				;restore card attributes
	stc
	jz	acceptCard
	
	;;not the same suits

	mov	bx, cx
	mov	si, dx
;	clr	cx				;doesn't matter here if
						;we search for highest or
						;lowest card, but chosing
						;highest
	mov	ax, MSG_HEARTS_DECK_FIND_HIGH_OR_LOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	stc
	jcxz	acceptCard
	mov	cl, MUST_FOLLOW_SUIT

dontAcceptCard:
	clc
acceptCard:

	.leave
	ret
HeartsDeckTestSuitCondition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckMakeSureNotJustHeartsLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will check and see if the only cards in the players deck 
		are hearts.

CALLED BY:	HeartsDeckTestSuitCondition

PASS:		^lcx:dx	= deck to check

RETURN:		carry set if only hearts are left
		carry clear if more than just hearts left

DESTROYED:	ax, bx, cx, bp, si, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckMakeSureNotJustHeartsLeft	proc	near
	.enter

	movdw	bxsi, cxdx
	mov	ax, MSG_DECK_GET_N_CARDS
	mov	di, mask MF_CALL
	call	ObjMessage

keepChecking:
	mov	bp, cx
	dec	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	mov	di, mask MF_CALL
	call	ObjMessage

	and	bp, SUIT_MASK
	cmp	bp, HEARTS
	jne	notAllHearts
	
	loop	keepChecking

	stc
	jmp	exitRoutine

notAllHearts:
	clc

exitRoutine:
	.leave
	ret
HeartsDeckMakeSureNotJustHeartsLeft	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckExplain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will Bring up a dialog box to explain why the card is not
		accepted.

CALLED BY:	MSG_HEARTS_DECK_EXPLAIN
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data
		cl	= NonAcceptanceReason
		dx	= sound to play (0 for no sound)

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	will bring up a dialog box

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckExplain	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_EXPLAIN
	.enter

	xchg	cx, dx
	jcxz	dontPlaySound
	call	HeartsGamePlaySound
dontPlaySound:
	xchg	cx, dx

	mov	al, size optr
	mul	cl				;ax <= offset in table
	mov	bx, offset heartsDeckExplainationTable
	add	bx, ax
	mov	dx, cs:[bx].handle
	mov	bp, cs:[bx].offset		;^ldx:bp <= string to display

	mov	bx, handle HeartsExplainText
	mov	si, offset HeartsExplainText
	clr	cx				;null terminated string.
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, handle HeartsExplaining
	mov	si, offset HeartsExplaining
	call	UserDoDialog

	.leave
	ret
HeartsDeckExplain	endm

heartsDeckExplainationTable	optr	\
	PlayTwoOfClubs,
	HeartsNotBroken, 
	MustFollowSuit



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFindHighOrLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of the card in the deck with the 
		highest/lowest card of the suit passed in bp.
		Also, can set a zero point so that it will find the highest
		card less than a certain number, or the lowest card greater
		than a certain number.

CALLED BY:	MSG_HEARTS_DECK_FIND_HIGH_OR_LOW
PASS:		*ds:si	= HeartsDeckClass object
		bp 	= CardAttr of suit

		ch	= 0 (find absolute highest/lowest)
			= NON_ZERO (use this as zero point)
		cl	= 0 to find highest card
			= non-zero to find lowest card

RETURN:		ch	= number of highest card of that suit in deck
		cl	= value of highest card of that suit in the deck
			   (0 if no cards of that suit)			  

DESTROYED:	nothing
SIDE EFFECTS:	none
     

PSEUDO CODE/STRATEGY:
		Find the first card of the suit you are looking for.
		Check all the other cards of the deck with the same 
			suit to see if they match the request better.

		You can either be searching for the absolute highest or
		lowest card, or you can be searching for the highest card
		below a certain value, or the lowest card above a certain
		value.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/29/93   	Initial version
	PW	2/05/93		modified to add the non-absolute search

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFindHighOrLow 	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_FIND_HIGH_OR_LOW
	uses	ax, dx, bp
	.enter

	clr	bh
	mov	bl, cl				;save check for high or low
	mov	cl, ch
	clr 	ch
	mov	di, cx				;save zero point

	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	tst	cx
	jnz	deckNotEmpty	
;deckEmpty:
	jmp	exitRoutine
deckNotEmpty:
	mov	dx, bp				;save card attributes
	and	dx, SUIT_MASK
	mov	bp, cx
	clr	cx

countingLoop:
	dec	bp				;set bp to current card number
	push	bp				;save card number
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp
	and	bp, SUIT_MASK
	cmp	dx, bp				;check if suits are the same
	jnz	notTheSameSuit
;areTheSameSuit:
	call	HeartsDeckGetCardRank		;al <= card rank
	tst	di
	jz	firstCard			;jump if looking for absolute
	jcxz	firstCard			;jump if this the first card
						;of the correct suit


;this code deals with finding a card that is the largest up to
;a certain card, or smallest above a certain card.


	push	dx				;save suit variable
	mov	dx, di				;move ZERO_POINT into dx
	mov	dh, dl
	sub	dl, cl				;normalize card value
	sub	dh, al				;normalize card value
	tst	bx				;check if searching for 
						;high or low
	jz	searchingForLargest

;searchingForSmallest:
	cmp	dl, 0				;check if previous card was
						;big enough after normalization
	jg	smallFindHighest
	jz	smallNotTheSameSuit
	cmp	dh, 0				;check if this card is big
						;enough after normalization
	pop	dx				;restore suit variable
	jle	firstCard
	jmp	notTheSameSuit
smallFindHighest:
	pop	dx				;restore suit variable
	cmp	al, cl
	jl	notTheSameSuit
	jmp	markAsBest
smallNotTheSameSuit:
	pop	dx				;restore suit variable
	jmp	notTheSameSuit


searchingForLargest:
	cmp	dl, 0				;check if previous card was 
						;small enough after
						;normalization
	jl	largeFindLowest
	jz	largeNotTheSameSuit
	cmp	dh, 0				;check if this card is small
						;enough after normalization
	pop	dx				;restore suit variable
	jge	firstCard
	jmp	notTheSameSuit
largeFindLowest:
	pop	dx				;restore suit variable
	cmp	al, cl
	jg	notTheSameSuit
	jmp	markAsBest
largeNotTheSameSuit:
	pop	dx				;restore suit variable
	jmp	notTheSameSuit



;end of code dealing with finding a card that is the largest up to
;a certain card, or smallest above a certain card.

	

firstCard:
	cmp	al, cl				;check if the card rank is
						;greater than largest one so 
						;far

	xchg	bx, cx				
	jcxz	findHighest			;check for high/low
	xchg	bx, cx
	jcxz	markAsBest			;first card of suit
	jg	notTheSameSuit
	jmp	markAsBest			;lower card found

findHighest:
	xchg	bx, cx
;	cmp	al, cl
	jl	notTheSameSuit			;taken if current card being
						;looked at not as big as
						;the best card seen so far.
markAsBest:
	pop	bp				;get card number
	push	bp				;save card number
	mov	cx, bp
	mov	ch, cl
	mov	cl, al

notTheSameSuit:
	pop	bp				;restore card number
	tst	bp
	jz	exitRoutine
	jmp	countingLoop
	

exitRoutine:
	.leave
	ret
HeartsDeckFindHighOrLow 	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckCountNumberOfSuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the number of cards of a given suit and the
		highest card of that suit.

CALLED BY:	MSG_HEARTS_DECK_COUNT_NUMBER_OF_SUIT
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data
		bp	= card attrs. of suit to find

RETURN:		cl	= number of cards of given suit
		ch	= rank of hightest card of given suit
		dx	= number of highest card in deck

DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckCountNumberOfSuit	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_COUNT_NUMBER_OF_SUIT

cardAttrs	local	word		push	bp
numCards	local	word
numSuit		local	byte
highestCard	local	byte		;rank of highest card
highestCardNum	local	word		;number of card in deck

	.enter

	clr	numSuit, highestCard
	push	bp					;save locals
	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	pop	bp					;restore locals
	jcxz	exitRoutine
	mov	numCards, cx
	and	cardAttrs, SUIT_MASK

searchingLoop:
	dec	numCards
	push	bp					;save locals
	mov	bp, numCards
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp					;ax <= card attrs.
	pop	bp					;restore locals
	mov	dx, ax
	and	dx, SUIT_MASK
	cmp	dx, cardAttrs
	jne	continueLoop
	;
	;a card of the correct suit has been found
	;
	inc	numSuit
	call	HeartsDeckGetCardRank
	cmp	al, highestCard
	jl	continueLoop
	;
	;a higher card has been found
	;
	mov	highestCard, al
	mov	ax, numCards
	mov	highestCardNum, ax

continueLoop:
	tst	numCards
	jnz	searchingLoop

	mov	cl, numSuit
	mov	ch, highestCard
	mov	dx, highestCardNum

exitRoutine:
	.leave
	ret
HeartsDeckCountNumberOfSuit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetChanceOfTaking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will return the chance of taking the trick based on what has
		already been played

CALLED BY:	
PASS:		*ds:si	= instance data of object
		ax	= card attributes of card to play

RETURN:		cx	= number of cards still out that could take
			  the trick if this card was played.
			  (-1 if card will not take trick)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Go through MyDiscardDeck and see how many cards could take
		this card and then return :
		Rank of Ace - Rank of card - # of cards already played.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetChanceOfTaking	proc	near
	uses	ax,bx,dx,bp,ds,si,di
	.enter
	class	HeartsDeckClass

	mov	bp, ax
	call	HeartsDeckCheckIfLastCard
	mov	dx, bp				;save card attributes
	jc	lastCard

	mov	ax, MSG_HEARTS_GAME_GET_CARDS_PLAYED
	call	VisCallParent
	cmp	cl, 0
	jle	setTake				;card is highest of cards
						;lead, since its first card.
	jmp	notFirstCardPlayed

lastCard:
	mov	cl, NUM_PLAYERS -1

notFirstCardPlayed:
	push	cx				;save # of cards played
	mov	ax, MSG_HEARTS_GAME_GET_TAKE_CARD_ATTR
	call	VisCallParent
	mov	bl, cl				;bl <= takeCardAttr.
	pop	cx				;restore # of cards played
	mov	al, dl				;restore card attributes
	and	al, SUIT_MASK
	and	bl, SUIT_MASK
	cmp	al, bl
	jne	wontTakeTrick			;not the same suit, can't win
	
;sameSuit:
	mov	al, dl				;restore card attributes
	and	al, RANK_MASK
	cmp	al, RANK_ACE
	je	takeTheTrick			;if an ace, it takes the trick
	push	ax, cx				;save card attr. and # cards
						;played
	mov	ax, MSG_HEARTS_GAME_GET_TAKE_CARD_ATTR
	call	VisCallParent
	mov	bl, cl				;bl <= takeCardAttr.
	pop	ax, cx				;restore card attr. and #
						;cards played
	and	bl, RANK_MASK
	cmp	bl, RANK_ACE
	je	wontTakeTrick			;if take card is ace, can't win
	cmp	al, bl
	jl	wontTakeTrick			;card is smaller
	cmp	cl, NUM_PLAYERS -1
	je	takeTheTrick			;if last card out, will win
	
setTake:
	mov	al, dl				;restore card attributes
	and	dl, SUIT_MASK
	call	HeartsDeckGetCardRank
	mov	dh, al				;dh <= card rank

	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	clr	bp				;clear # of cards greater
	mov	bx, ds:[LMBH_handle]
	call	HeartsDeckDiscardLoop		;calculate # of cards greater
	
	mov	bx, handle MyDiscardDeck
	mov	si, offset MyDiscardDeck
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjMessage
	jcxz	discardDeckEmpty

;discardDeckNotEmpty:
	call	HeartsDeckDiscardLoop		;calculate # of card greater

discardDeckEmpty:
	mov	cx, ACE_VALUE				;cx <= rank ace
	sub	cl, dh				;return rank ace - rank card
	sub	cx, bp				;cx <= cx - # greater cards
	jmp	exitRoutine

wontTakeTrick:
	mov	cx, -1
	jmp	exitRoutine

takeTheTrick:
	clr	cx

exitRoutine:

	.leave
	ret
HeartsDeckGetChanceOfTaking	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckDiscardLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will determine the number of cards greater than the give
		card.

CALLED BY:	HeartsDeckGetChanceOfTaking

PASS:		bp	= number of card already greater than card to 
			  compair with.
		cx	= number of cards in deck
		^lbx:si	= deck to count cards of
		dl	= suit of card to compair with
		dh	= rank of card to compair with

RETURN:		bp	= # of cards greater than card to compair with

DESTROYED:	cx	= 0 at the end
		di, ax

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/12/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckDiscardLoop	proc	near
	.enter
	class	HeartsDeckClass
	
	push	bp				;save number of cards 
						;greater than compair card
discardLoop:
	mov	bp, cx				;bp <= card number to find
	dec	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjMessage
	mov	ax, bp				;ax <= nth card attr.
	and	al, SUIT_MASK
	cmp	al, dl				;check if same suit
	jne	continueLoop
	mov	ax, bp				;ax <= nth card attr.
	call	HeartsDeckGetCardRank
	cmp	al, dh				;compair the card ranks
	jle	continueLoop
	pop	bp
	inc	bp				;increment # cards greater
						;than passed card
	push	bp
continueLoop:
	loop	discardLoop

	pop	bp				;restore # of card greater
						;than passed card

	.leave
	ret
HeartsDeckDiscardLoop	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetStrategicCardValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the strategic card value that is used to 
		determine the value of taking a particular card

CALLED BY:	
PASS:		ax	= CardAttrs
RETURN:		cx 	= strategic card value
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Jack of Diamonds	=	+100
	Queen of Spades		=	-180
	Heart			=	(5 - # of Heart) * 3
	Club			=	10 - # of Club
	Diamond			=	# of Diamond
		(Queen)		=	20
		(King)		=	21
		(Ace)		=	22
	Spade			=	# of Spade
		(Ace)		=	-21
		(King)		=	-20
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetStrategicCardValue	proc	near
	uses	ax
	.enter

	clr	ch					;make sure that
							;cx = cl

	mov	ah, al					;save CardAttrs
	and	al, RANK_MASK or SUIT_MASK
	cmp	al, JACK or DIAMONDS
	je	jackOfDiamonds
	mov	al, ah					;restore CardAttrs
	and	al, RANK_MASK or SUIT_MASK
	cmp	al, QUEEN or SPADES
	je	queenOfSpades
	mov	al, ah					;restore CardAttrs

;;calculate rank for card and store in ah

	call	HeartsDeckGetCardRank
	xchg	al, ah

;;done calculating rank

;findSuit:	
	and	al, SUIT_MASK
	cmp	al, HEARTS
	je	isHearts
	cmp	al, CLUBS
	je	isClubs
	cmp	al, DIAMONDS
	je	isDiamonds
;isSpades:
	mov	al, ah
	cmp	al, 13
	jl	notAceOrKing
	mov	al, -7
	sub	al, ah
notAceOrKing:
	cbw					;make sure ax is signed
	mov	cx, ax
	jmp	exitRoutine
jackOfDiamonds:
	mov	cx, 100
	jmp	exitRoutine
queenOfSpades:
	mov	cx, -180
	jmp	exitRoutine
isHearts:
	mov	al, 3
	mul	ah				;al <= 3 * card rank
	mov	ah, 3*5				;ah <= 15
	xchg	al, ah
	sub	al, ah				;al <= 15 - card rank * 3
	cbw
	mov	cx, ax
	jmp	exitRoutine
isClubs:
	mov	al, 10
	sub	al, ah
	cbw
	mov	cx, ax
	jmp	exitRoutine
isDiamonds:
	cmp	ah, 12
	jl	notGreaterThanJack
	add	ah, 8
notGreaterThanJack:
	mov	cl, ah
;	jmp	exitRoutine

exitRoutine:
	.leave
	ret
HeartsDeckGetStrategicCardValue	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetTakeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will set the two global variables that indicate who is
		going to take the trick.  (The two variables are :
			TakeCardAttr, TakePointer).

CALLED BY:	
PASS:		bp	= card attributes of discard card
		^lcx:dx	= donor deck

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	sets Take global variables

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetTakeData	proc	near
	uses	ax,bx,bp,si,di

discardAttr	local	word	push	bp
donorDeck	local	optr	push	cx, dx
takeCardAttr	local	byte

	.enter

	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	ax, MSG_HEARTS_GAME_GET_CARDS_PLAYED
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	cmp	cl, 0
	jle	setTake				;firstCardPlayed

;notFirstCardPlayed:
	mov	ax, MSG_HEARTS_GAME_GET_TAKE_CARD_ATTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage	
	mov	takeCardAttr, cl
	mov	bl, takeCardAttr
	mov	ax, discardAttr
	and	al, SUIT_MASK
	and	bl, SUIT_MASK
	cmp	al, bl
	jne	exitRoutine			;not the same suit, can't win
	
;sameSuit:
	mov	ax, discardAttr
	and	al, RANK_MASK
	cmp	al, RANK_ACE
	je	setTake				;if an ace, it takes the trick
	mov	bl, takeCardAttr
	and	bl, RANK_MASK
	cmp	bl, RANK_ACE
	je	exitRoutine			;if an ace, it takes the trick
	cmp	al, bl
	jl	exitRoutine			;card is smaller

setTake:
	mov	cx, discardAttr
	mov	bx, handle HeartsPlayingTable
	mov	ax, MSG_HEARTS_GAME_SET_TAKE_CARD_ATTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage	

	mov	cx, donorDeck.handle
;	mov	dx, donorDeck.offset		;dx is never changed.
	mov	ax, MSG_HEARTS_GAME_SET_TAKE_POINTER
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage	

exitRoutine:
	movdw	cxdx, donorDeck			;restore donorDeck

	.leave
	ret
HeartsDeckSetTakeData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HeartsDeckTakeCardsIfOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_TAKE_CARDS_IF_OK handler for HeartsDeckClass
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
	PW	1/29/93		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckTakeCardsIfOK	method		HeartsDeckClass, 
					MSG_DECK_TAKE_CARDS_IF_OK

dropCardAttr	local	word	push 	bp
donorDeck	local	optr	push	cx, dx

	.enter

	mov	ax, MSG_DECK_TEST_ACCEPT_CARDS
	call	ObjCallInstanceNoLock

	LONG jnc	endDeckTakeCardsIfOK	;deck wont accept cards

	movdw	cxdx, donorDeck
	push	bp				;save bp for local vars
	mov	bp, dropCardAttr
	mov	ax, MSG_HEARTS_DECK_TEST_SUIT_CONDITION
	call	ObjCallInstanceNoLock
	pop	bp				;restore bp for local vars

	jc	willAccept
	push	bp				;save locals
	mov	dx, HS_WRONG_PLAY		;dx <= sound to play
	mov	ax, MSG_HEARTS_DECK_EXPLAIN
	call	ObjCallInstanceNoLock
	pop	bp				;restore locals
	clc					;indiate not taking cards
	jmp	endDeckTakeCardsIfOK		;deck wont accept cards

willAccept:
	movdw	cxdx, donorDeck
	push	bp				;save bp for local vars
	mov	bp, dropCardAttr
	call	HeartsDeckSetTakeData
	pop	bp				;restore bp for local vars

	push	bp				;save locals
	push	si				;save offset
	movdw	bxsi, donorDeck
	clr	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	cx, bp				;cl <= card attrs.	
	mov	ax, MSG_HEARTS_DECK_GET_DECK_ID_NUMBER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_HEARTS_GAME_SET_PLAYERS_DATA
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si				;restore offset	
	pop	bp				;restore locals

;	mov	ax, MSG_GAME_GET_DRAG_TYPE
;	call	VisCallParent

;transferCards:
	movdw	cxdx, donorDeck
	mov	bx, ds:[LMBH_handle]
	xchgdw	bxsi, cxdx
							;^lbx:si = donor
							;^lcx:dx = recipient
	mov	ax, MSG_DECK_TRANSFER_DRAGGED_CARDS	;do the transfer
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	push	bp				;save locals
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	ax, MSG_HEARTS_GAME_SET_SHOOT_DATA
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp				;restore locals

	stc						;indicate that we took
							;the cards
endDeckTakeCardsIfOK:
	.leave
	ret

HeartsDeckTakeCardsIfOK	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HeartsDeckTestAcceptCards
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

DESTROYED:	ax, cx, dx

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
HeartsDeckTestAcceptCards	method	HeartsDeckClass, 
			MSG_DECK_TEST_ACCEPT_CARDS

	push	bp
	test	ds:[di].DI_deckAttrs, mask DA_WANTS_DRAG
	jz	endTest
	mov	ax, ds:[LMBH_handle]
	cmp	ax, cx
	jnz	notTheSameObject	
	cmp	si, dx
	clc
	jz	endTest

notTheSameObject:
	mov	ax, MSG_DECK_CHECK_DRAG_CAUGHT	;see if the drag area is in the
	call	ObjCallInstanceNoLock		;right place

endTest:
	pop	bp
	;;the carry bit will now be set if the deck will accept the cards
	ret

HeartsDeckTestAcceptCards	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckTransferNthCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shifts the nth card to make it the first card on the deck,
		and then transfers the top card to the other deck

CALLED BY:	HeartsDeckTransferDraggedCards

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		bp = number of card to transfer
		^lcx:dx = instance of VisCompClass to receive the cards
		(usually another Deck)
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	The bp card of the deck at *ds:si is transferred
		to the top of deck at ^lcx:dx. The order of the cards is
		preserved.

PSEUDO CODE/STRATEGY:
		pop the n'th card and push it on the recipient deck

KNOWN BUGS/IDEAS:
*WARNING*
A deck must never transfer to itself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckTransferNthCard	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_TRANSFER_NTH_CARD
	.enter

	push	cx
	mov	cx, bp
	mov	ax, MSG_HEARTS_DECK_SHIFT_CARDS
	mov	di, mask MF_FIXUP_DS
;	clr	ch					;redraw deck
	call 	ObjCallInstanceNoLock

	pop	cx
	mov	bp, 1					;transfers 1 card
	mov	ax, MSG_DECK_TRANSFER_N_CARDS
	call	ObjCallInstanceNoLock

	.leave
	ret
HeartsDeckTransferNthCard	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckCalculateScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will calculate the amount of points in the deck

CALLED BY:	HeartsDeckTakeTrick
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		cx	= points
		al	= positive points
		ah	= negative points
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckCalculateScore	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_CALCULATE_SCORE
	uses	dx, bp
	.enter

	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	jcxz	exitRoutine
	mov	dx, cx					;store number of cards
	clr	cx					;store total score
Scoreloop:
	dec	dx
	mov	bp, dx
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	call	HeartsDeckGetCardScore
	mov	ax, bp
	cmp	ax, 0
	jz	continueLoop
	jl	negativeValue
;positiveValue:
	add	cl, al
	jmp	continueLoop	

negativeValue:
	add	ch, al

continueLoop:
	tst	dx
	jnz	Scoreloop

	mov	ax, cx
	add	al, ah
	cbw
	xchg	ax, cx

exitRoutine:
	.leave
	ret
HeartsDeckCalculateScore	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetCardScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calculate the value of a card given it's attributes

CALLED BY:	HeartsDeckCalculateScore
PASS:		bp	= card attributes
RETURN:		bp	= card value
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 3/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetCardScore	proc	near
	uses	ax
	.enter

	mov	ax, bp				;save card attr.
	and	al, SUIT_MASK
	cmp	al, HEARTS
	je	isHearts
;notHearts:
	cmp	al, DIAMONDS
	je	isDiamonds
;notDiamonds:
	cmp	al, CLUBS
	je	isClubs
;notClubs:
;isSpades:
	mov	ax, bp
	and	al, RANK_MASK
	cmp	al, QUEEN
	jne	isClubs
	mov	bp, QUEEN_OF_SPADES_POINTS
	jmp	exitRoutine

isHearts:
	mov	bp, HEARTS_POINTS
	jmp	exitRoutine
isDiamonds:
	mov	ax, bp
	and	al, RANK_MASK
	cmp	al, JACK
	jne	isClubs
	mov	bp, JACK_OF_DIAMONDS_POINTS
	jmp	exitRoutine
isClubs:
	clr	bp

		
exitRoutine:
	.leave
	ret
HeartsDeckGetCardScore	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetRawScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns both the positive and negative points recieved for
		this round

CALLED BY:	HeartsGameCheckShootMoon, HeartsGameGetAbsolutePoints
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		cl	= positive points
		ch	= negative points

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetRawScore	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_RAW_SCORE
	.enter

	mov	cx, ds:[di].HI_thisRoundScore

	.leave
	ret
HeartsDeckGetRawScore	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the score of this round, or the total score

CALLED BY:	MSG_HEARTS_DECK_GET_SCORE
PASS:		*ds:si	= HeartsDeckClass object
		cx	= 0 (total score)
			= 1 (get this round's score)

RETURN:		cx	= score
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetScore	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_SCORE
	.enter

	jcxz	getTotalScore
;getThisRoundsScore:
	xchg	ax, cx					;save ax
	mov	ax, ds:[di].HI_thisRoundScore
	add	al, ah					;al<=thisRoundScore
	cbw
	xchg	ax, cx					;restore ax, cx<=score
	
	jmp	exitRoutine

getTotalScore:
	mov	cx, ds:[di].HI_score

exitRoutine:
	.leave
	ret
HeartsDeckGetScore	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckResetScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will set the score instance data to zero for either just
		this rounds score, or both this round and the total score.

CALLED BY:	HeartsGameResetGame
PASS:		*ds:si	= HeartsDeckClass object
		cx	= 0 (reset just this rounds score)
			= 1 (reset total score)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will set the score instance data

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckResetScore	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_RESET_SCORE
	.enter

	clr	ds:[di].HI_thisRoundScore
	jcxz	exitRoutine
;resetTotalScore:
	clr	ds:[di].HI_score

exitRoutine:
	call	ObjMarkDirty

	.leave
	ret
HeartsDeckResetScore	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckIncrementScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment both this rounds score and the total score

CALLED BY:	MSG_HEARTS_DECK_INCREMENT_SCORE
PASS:		*ds:si	= HeartsDeckClass object
		cl	= positive score
		ch	= negative score

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	changes score

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckIncrementScore	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_INCREMENT_SCORE
	uses	ax
	.enter
	
	mov	ax, ds:[di].HI_thisRoundScore
	add	al, cl
	add	ah, ch
	xchg	ax, cx
	add	al, ah
	cbw
	add	ds:[di].HI_score, ax
	mov	ds:[di].HI_thisRoundScore, cx
	call	ObjMarkDirty

;	add	ds:[di].HI_score, cx
;	mov	ax, ds:[di].HI_thisRoundScore
;	cmp	cl, 0
;	jl	incrementNegative
;incrementPositive:
;	add	al, cl
;	jmp	saveThisRoundScore
;incrementNegative:
;	add	ah, cl
;saveThisRoundScore:
;	mov	ds:[di].HI_thisRoundScore, ax


	.leave
	ret
HeartsDeckIncrementScore	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckTakeTrick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cards to MyDiscardDeck.
		Also, it sets up the HeartsBroken instance data for the
		parent class.  This method should only be sent to
		DiscardDeck, since it is the only proper discard deck.

CALLED BY:	HeartsDeckSetTakeTrigger
PASS:		*ds:si	= HeartsDeckClass object to pass cards

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckTakeTrick	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_TAKE_TRICK
	uses	ax, cx, dx, bp
	.enter

	push	si					;save offset
	call	HeartsDeckCompleteTrickData

	mov	ax, MSG_HEARTS_GAME_CHECK_HEARTS_BROKEN
	call	VisCallParent
	tst	cl
	jnz	noHearts				;hearts already broken

	mov	bp, HEARTS				;check if heart played
	clr	cx					;search for highest
	mov	ax, MSG_HEARTS_DECK_FIND_HIGH_OR_LOW
	call	ObjCallInstanceNoLock
	tst	cx
	jnz	heartsAreBroken

	mov	dl, QUEEN or SPADES
	call	HeartsDeckFindCardGivenAttr
	cmp	cx, 0
	jl	noHearts				;queen not played
heartsAreBroken:
	mov	ax, MSG_HEARTS_GAME_SET_HEARTS_BROKEN
	call	VisCallParent
noHearts:
	mov	ax, MSG_HEARTS_DECK_CALCULATE_SCORE
	call	ObjCallInstanceNoLock
	push	ax					;save score

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock
	Deref_DI Deck_offset			;save the original position
	mov	ds:[di].DI_initLeft, ax
	mov	ds:[di].DI_initTop, bp
	mov	ds:[di].DI_initRight, cx
	mov	ds:[di].DI_initBottom, dx
	call	ObjMarkDirty

	clr	cx
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock
	push	si				;save offset
	movdw	bxsi, cxdx			;^bx:si <= card to move
	mov	cx, handle MyDiscardDeck
	mov	dx, offset MyDiscardDeck
	call	HeartsDeckMoveCardToDiscard
	pop	si				;restore offset

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_TRANSFER_ALL_CARDS_FACE_DOWN
	call	ObjCallInstanceNoLock
	mov	ax, MSG_CARD_MAXIMIZE		;make sure top card is now
	call	VisCallFirstChild		;set to full size

	mov	ax, MSG_DECK_INVALIDATE_INIT	;invalidate old region
	call	ObjCallInstanceNoLock

	mov	ax, MSG_HEARTS_GAME_GET_TAKE_POINTER
	call	VisCallParent

	movdw	bxsi, cxdx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_INVERT
	call	ObjMessage

	pop	cx				;retrieve score
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_INCREMENT_SCORE
	call	ObjMessage
	add	cl, ch				;cl <= increment in score

	mov	ax, MSG_HEARTS_DECK_GET_DECK_ID_NUMBER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	push	si				;save offset
	mov	ah, ch				;ah <= deck ID number
	clr	al				;clear indicator
	mov	dl, cl				;dl <= incremental score
	clr	cx				;don't set anything but score
	call	HeartsGameModifyPlayersData
	pop	si				;restore offset

	clr	bp, cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_DRAW_SCORE
	call	ObjMessage

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjMessage
	pop	ax				;ax <= offset
	tst	cx				;check if there are cards 
	jnz	cardsLeft
;noCardsLeft:
	mov	si, ax				;si <= offset
	mov	ax, MSG_HEARTS_GAME_CHECK_SHOOT_MOON
	call	VisCallParent			;adjust scores if moon was shot
	mov	ax, MSG_HEARTS_GAME_GET_MAX_SCORE
	call	VisCallParent
	mov	dx, cx				;dx <= max score
	mov	cx, 1				;we want to find highest score
	mov	ax, MSG_HEARTS_GAME_GET_PLAYERS_SCORE
	call	VisCallParent
	cmp	cx, dx				;check if anyone went over
						;maximum score
	jl	gameNotOver
;gameOver:
	mov	ax, MSG_HEARTS_GAME_GAME_OVER
	call	VisCallParent
	jmp	exitRoutine
gameNotOver:
	mov	ax, MSG_HEARTS_GAME_DEAL_ANOTHER_HAND
	call	VisCallParent
	jmp	exitRoutine

cardsLeft:
	push	si				;save next players offset
	mov	si, ax				;si <= DiscardDeck offset
	mov	cx, MAXIMUM_ABSOLUTE_POINTS
	mov	ax, MSG_HEARTS_GAME_GET_ABSOLUTE_POINTS
	call	VisCallParent
	pop	si				;restore next players offset
	cmp	cx, MAXIMUM_ABSOLUTE_POINTS
	je	exitRoutine

	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_PLAY_CARD
	call	ObjMessage

exitRoutine:
	.leave
	ret
HeartsDeckTakeTrick	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckCompleteTrickData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will add this trick to all the decks instance data pertaining
		to what cards have been played. 

CALLED BY:	HeartsDeckTakeTrick
PASS:		*ds:si	= Discard Deck

RETURN:		ds	= segment of Discard Deck, may have changed
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get the attributes of all four cards in the deck, and
		then send that to the HeartsPlayingTable to set all the
		decks with the proper information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckCompleteTrickData	proc	near

	.enter

;perform four consecutive function calls because it is eaier than looping
;for such a short number of calls.

	clr	bp					;get first card attr.
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	push	bp					;save first card attr.

	mov	bp, 1					;get second card attr.
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	push	bp					;save second card attr.

	mov	bp, 2
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	push	bp					;save third card attr.

	mov	bp, 3
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock

	mov	ax, bp
	mov	cl, al					;cl <= 4th card attr.

	pop	bp
	mov	ax, bp
	mov	ch, al					;ch <= 3rd card attr.

	pop	bp
	mov	ax, bp
	mov	dl, al					;dl <= 2nd card attr.

	pop	bp
	mov	ax, bp
	mov	dh, al					;dh <= 1st card attr.

	mov	ax, MSG_HEARTS_GAME_SET_TRICK_DATA
	call	VisCallParent

	.leave
	ret
HeartsDeckCompleteTrickData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckComputerShotMoonGloat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler see message definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of HeartsDeckClass

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
	srs	7/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckComputerShotMoonGloat	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_COMPUTER_SHOT_MOON_GLOAT
	uses	cx,dx,bp
	.enter

	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, CustomDialogBoxFlags \
		<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION, 0>
	mov	ss:[bp].SDP_stringArg1.segment, ds
	mov	di,ds:[di].HI_nameString
	mov	di,ds:[di]
	mov	ss:[bp].SDP_stringArg1.offset, di
	mov	bx, handle StringResource
	call	MemLock
	mov	es, ax
	mov	ss:[bp].SDP_customString.segment, ax
	mov	di,offset ComputerPlayerShotMoonText
	mov	ax, es:[di]
	mov	ss:[bp].SDP_customString.offset, ax
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialog
	call	MemUnlock

	.leave
	ret
HeartsDeckComputerShotMoonGloat		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetPlayedCardPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the instance data HI_playedCardPtr

CALLED BY:	MSG_HEARTS_DECK_GET_PLAYED_CARD_POINTER
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		^lcx:dx	= playedCardPtr.
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetPlayedCardPointer	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_PLAYED_CARD_POINTER
	.enter

	movdw	cxdx, ds:[di].HI_playedCardPtr

	.leave
	ret
HeartsDeckGetPlayedCardPointer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetPlayersDataPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the instance data HI_playersDataPtr

CALLED BY:	MSG_HEARTS_DECK_GET_PLAYERS_DATA_POINTER
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		^lcx:dx	= playerDataPtr
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetPlayersDataPointer	method dynamic HeartsDeckClass, 
				MSG_HEARTS_DECK_GET_PLAYERS_DATA_POINTER
	.enter

	movdw	cxdx, ds:[di].HI_playersDataPtr

	.leave
	ret
HeartsDeckGetPlayersDataPointer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetDeckIdNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the decks ID number

CALLED BY:	HeartsDeckTakeCardsIfOK
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		ch	= deckIdNumber
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetDeckIdNumber	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_DECK_ID_NUMBER
	.enter

	mov	ch, ds:[di].HI_deckIdNumber

	.leave
	ret
HeartsDeckGetDeckIdNumber	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckClearStrategyData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will clear the two chunk arrays pointed to by :
			HI_playedCardPtr & HI_playersDataPtr
		Then it will initialize the HI_playersDataPtr by adding
			all the players with no information about them.

CALLED BY:	MSG_HEARTS_DECK_CLEAR_STRATEGY_DATA
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckClearStrategyData	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_CLEAR_STRATEGY_DATA

playersDataOD		local	optr

	.enter

	movdw	playersDataOD, ds:[di].HI_playersDataPtr, bx

	movdw	bxsi, ds:[di].HI_playedCardPtr
	call	MemLock
	mov	ds, ax
	call	ChunkArrayZero
	call	ObjMarkDirty
	call	MemUnlock

	movdw	bxsi, playersDataOD
	call	MemLock
	mov	ds, ax
	call	ChunkArrayZero

	clr	bl
	mov	cx, NUM_PLAYERS

morePlayersLoop:
	call	ChunkArrayAppend
	inc	bl
	mov	ds:[di].PD_playerId, bl
	clr	ds:[di].PD_voidSuits
	clr	ds:[di].PD_points
	clr	ds:[di].PD_cardAssumptions
	loop	morePlayersLoop

	mov	bx, playersDataOD.handle
	call	ObjMarkDirty
	call	MemUnlock

	.leave
	ret
HeartsDeckClearStrategyData	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			HeartsDeckTransferAllCardsFaceDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfers all of a decks cards to another deck and
		flips the cards face down, as it does so.

CALLED BY:	HeartsDeckTakeTrick

PASS:		ds:di = deck instance
		*ds:si = instance data of deck
		^lcx:dx = instance of VisCompClass to receive the cards
		(usually another Deck)
		
CHANGES:	The cards of deck at *ds:si are transferred
		to the top of deck at ^lcx:dx. The order of the cards is
		preserved.

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		loops bp times, popping cards (starting with the bp'th, ending
		with the top)from the donor and pushing them to the
		recipient

KNOWN BUGS/IDEAS:
*WARNING*
A deck must never transfer to itself because the cards then get lost in
space.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/26/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckTransferAllCardsFaceDown	method dynamic HeartsDeckClass, 
			MSG_HEARTS_DECK_TRANSFER_ALL_CARDS_FACE_DOWN

	mov	bp, ds:[di].DI_nCards		;set bp = all cards
	push	cx,dx,bp
	mov	ds:[di].DI_lastRecipient.handle, cx
	mov	ds:[di].DI_lastRecipient.chunk, dx
	mov	ds:[di].DI_lastGift, bp
	call	ObjMarkDirty
	
	mov	ax, MSG_GAME_SET_DONOR
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	VisCallParent
	pop	cx,dx,bp

startDeckTransferNCards:

	dec	bp					;see if we're done
	cmp	bp, 0
	jl	endDeckTransferNCards

	push	bp					;save count

	push	cx, dx					;save OD of recipient
	clr	cx					;cx:dx <- # of child
	mov	dx, bp					;to remove
	mov	ax, MSG_DECK_REMOVE_NTH_CARD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjCallInstanceNoLock			;^lcx:dx <- OD of card

	push	si
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_CARD_TURN_FACE_DOWN
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
;	mov	ax, MSG_CARD_MAXIMIZE
;	call	ObjMessage

	pop	bp					;save donor offset
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
HeartsDeckTransferAllCardsFaceDown	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckPassCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will pass a number of cards to another player, and then
		tell its neighbor to pass cards.

CALLED BY:	MSG_HEARTS_DECK_PASS_CARDS
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will pass the number of cards indicated in the instance
		data.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckPassCards	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_PASS_CARDS
	uses	ax, cx, dx, bp
	.enter

	test	ds:[di].HI_deckAttributes, mask HDA_COMPUTER_PLAYER
	jz	humanPlayer

;computerPlayer:
	call	HeartsDeckComputerPassCards
	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_neighborPointer
	mov	ax, MSG_HEARTS_DECK_PASS_CARDS
	mov	di, mask MF_CALL
	call	ObjMessage
	jmp	exitRoutine

humanPlayer:
	mov	ax, MSG_HEARTS_GAME_GET_GAME_ATTRS
	call	VisCallParent
	BitSet	cl, HGA_PASSING_CARDS
	mov	ax, MSG_HEARTS_GAME_SET_GAME_ATTRS
	call	VisCallParent

	Deref_DI Deck_offset
	push	si				;save offset
	movdw	bxsi, ds:[di].HI_passPointer
	mov	ax, MSG_HEARTS_DECK_GET_PASS_STRING
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si				;restore offset

	Deref_DI Deck_offset
	push	si				;save offset
	mov	bx, handle HeartsPassText
	mov	si, offset HeartsPassText
	clr	cx				;null terminated string.
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si				;restore offset

	clr	cx				;set undetectable
	call	HeartsDeckSetDiscardDeck

	mov	bx, handle HeartsPassing
	mov	si, offset HeartsPassing
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL
	call	ObjMessage

exitRoutine:	
	.leave
	ret
HeartsDeckPassCards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetPassString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return an Optr to the pass string (the instance data)

CALLED BY:	MSG_HEARTS_DECK_GET_PASS_STRING
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		^ldx:bp	= the pass string instance data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetPassString	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_PASS_STRING
	.enter

	mov	dx, ds:[LMBH_handle]		;there in the same resource
	mov	bp, ds:[di].HI_passString

	.leave
	ret
HeartsDeckGetPassString	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckComputerPassCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will set up the chunk array with the cards the deck wishes
		to pass.  Do not call procedure with zero passCards.

CALLED BY:	HeartsDeckPassCards
PASS:		*ds:si	= deck object

RETURN:		*ds:si	= deck object (ds may have changed)
DESTROYED:	ax,bx,cx,dx,bp,di
SIDE EFFECTS:	will add some entries to the chunk array

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckComputerPassCards	proc	near

passProcedure		local	word
backupProcedure		local	word
chunkArray		local	optr
numPassCards		local	byte
numNuetralCards		local	byte
numDeckCards		local	byte
deckOptr		local	optr

cardAttrs		local	PassCardData
counter			local	word
numberClubs		local	byte
numberDiamonds		local	byte
highestDiamond		local	byte
switchCards		local	word

ForceRef	cardAttrs
ForceRef	counter
ForceRef	numberClubs
ForceRef	numberDiamonds
ForceRef	highestDiamond
ForceRef	switchCards

	.enter
	class	HeartsDeckClass

	mov	bx, ds:[LMBH_handle]
	movdw	deckOptr, bxsi

	mov	ax, MSG_HEARTS_GAME_GET_NUMBER_OF_PASS_CARDS
	call	VisCallParent
	mov	numPassCards, cl

	mov	ax, MSG_HEARTS_DECK_GET_PASS_STYLE
	call	ObjCallInstanceNoLock
	mov	numNuetralCards, al
	mov	passProcedure, cx
	mov	backupProcedure, dx

	Deref_DI Deck_offset
	mov	ax, ds:[di].DI_nCards
	mov	numDeckCards, al
	movdw	chunkArray, ds:[di].HI_chunkPointer, ax
	mov	bx, chunkArray.handle
	call	MemLock

	call	passProcedure

;endOfLoop:
	movdw	bxsi, chunkArray
	call	MemDerefDS
	call	ObjMarkDirty
	call	MemUnlock
	movdw	bxsi, deckOptr
	call	MemDerefDS

	.leave
	ret
HeartsDeckComputerPassCards	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetPassStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will return the pass style that should be used

CALLED BY:	MSG_HEARTS_DECK_GET_PASS_STYLE
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		al	= numNuetralCards
		cx	= passProcedure
		dx	= backupProcedure

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetPassStyle	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_PASS_STYLE
	uses	bp

	.enter

	call	TimerGetCount
	mov	dx, ax
	mov	ax, MSG_GAME_SEED_RANDOM
	call	VisCallParent

	mov	dx, MAX_ODDS
	mov	ax, MSG_GAME_RANDOM
	call	VisCallParent

;	Deref_DI Deck_offset
	cmp	dl, ds:[di].HI_passStyle.HPS_oddsOnAlternate
	lea	di, ds:[di].HI_passStyle.HPS_mainMethod
	jge	methodOK
;useAlternateMethod:
	add	di, HPS_alternateMethod - HPS_mainMethod
methodOK:
	mov	al, ds:[di].HPM_numNuetralCards
	mov	bp, ds:[di].HPM_passProcedure
	mov	cx, cs:[heartsDeckPassProcedureTable][bp]
	mov	bp, ds:[di].HPM_backupProcedure
	mov	dx, cs:[heartsDeckPassProcedureTable][bp]

	.leave
	ret
HeartsDeckGetPassStyle	endm


heartsDeckPassProcedureTable	nptr.near \
	HeartsDeckComputerPassVoidSuit,
	HeartsDeckSwitchRunOfCards,
	HeartsDeckComputerPassDontBeDumb





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckComputerPassVoidSuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will reorder the deck so that the last cards are the cards
		that the deck should pass following the "Void Suit"
		tacktic.  (Pass cards that will make the deck void in either
		clubs or diamonds).  The deck must be arraged in order (ie.
		the deck must be sorted by MSG_HEARTS_DECK_SORT_DECK) in order
		that this procedure works properly.

CALLED BY:	HeartsDeckComputerPassCards
PASS:		*ds:si	= HeartsDeckClass object
		bp	= pointer to stack frame of HeartsDeckComputerPassCards
		backupProcedure	=	procedure to call if cannot void
		chunkArray	=	optr to chunkarray to store pass cards
		numPassCards	=	number of cards to pass
		numNuetralCards	=	number of nuetral cards to pass
		numDeckCards	=	number of cards in the deck
		deckOptr	=	optr to the deck passing cards
		cardAttrs	=	PassCardData temp variable

RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	will mess up the local variables and will add some
		elements to the chunk array

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckComputerPassVoidSuit	proc	near

	.enter	inherit	HeartsDeckComputerPassCards

	clr	counter
	clr	al, numberClubs, numberDiamonds, highestDiamond

	push	bp					;save locals
	mov	bp, DIAMONDS
	mov	ax, MSG_HEARTS_DECK_COUNT_NUMBER_OF_SUIT
	call	ObjCallInstanceNoLock
	pop	bp					;restore locals
	mov	numberDiamonds, cl
	mov	highestDiamond, ch
	push	bp					;save locals
	mov	bp, CLUBS
	mov	ax, MSG_HEARTS_DECK_COUNT_NUMBER_OF_SUIT
	call	ObjCallInstanceNoLock
	pop	bp					;restore locals
	mov	numberClubs, cl

	clr	ah
	mov	al, cl					;al <= numberClubs
	cmp	highestDiamond, RANK_VALUE_OF_JACK
	jge	lessClubs				;has card that can
							;take Jack, so don't
							;void Diamonds
	clr	cl
	mov	ch, al					;ch <= #Clubs
	add	ch, numberDiamonds			;ch <= #Clubs + #Diam
	cmp	ch, numPassCards
	jle	switchTheCards				;pass all diamond and
							;clubs
	cmp	numberDiamonds, al
	jg	lessClubs
;lessDiamonds:
	clr	cl
	mov	ch, numberDiamonds
	cmp	ch, numPassCards
	jg	TooManyCardsToVoid
	jmp	switchTheCards
lessClubs:
	mov	cl, numberDiamonds
	mov	ch, cl
	add	ch, al					;ch <= #Diam + #Clubs
	cmp	al, numPassCards
	jg	TooManyCardsToVoid	

switchTheCards:
	mov	switchCards, cx
	call	HeartsDeckSwitchRunOfCards
	jmp	exitRoutine

TooManyCardsToVoid:
	mov	switchCards, cx
	call	backupProcedure
;	jmp	exitRoutine

exitRoutine:

	.leave
	ret
HeartsDeckComputerPassVoidSuit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSwitchRunOfCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will switch a run of consecutive cards with the cards
		in the back of the deck and add them to the chunk array
		as cards to pass.  It will only switch a maximum of 
		(numPassCards), and if less that that are requested to be
		switched, then it will call HeartsDeckComputerPassDontBeDumb
		to take care of the rest of the cards.

CALLED BY:	HeartsDeckComputerPassVoidSuit
PASS:		switchCards.low	= First Card to switch to back of deck
			.high	= last card (don't actually switch it)
					(high-low cards are switched.)
		chunkArray	=	optr to chunkarray to store pass cards
		numPassCards	=	number of cards to pass
		numNuetralCards	=	number of nuetral cards to pass
		numDeckCards	=	number of cards in the deck
		deckOptr	=	optr to the deck passing cards
		cardAttrs	=	PassCardData temp variable
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/19/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSwitchRunOfCards	proc	near

	.enter	inherit	HeartsDeckComputerPassCards

	mov	cx, switchCards
	cmp	cl, ch
	jl	switchSomeCards
	jmp	notEnoughCardsSwitched

switchSomeCards:
	sub	ch, numPassCards
	cmp	cl, ch
	jge	passLoop
					;too many cards trying to be switched
					;so only switch the last of the cards
	mov	switchCards.low, ch

passLoop:
	dec	switchCards.high
	dec	numPassCards
	dec	numDeckCards

	clr	ch
	mov	cl, switchCards.high

	clr	dh
	mov	dl, numDeckCards			;switch with the last 
							;card.
	mov	ax, MSG_HEARTS_DECK_SWITCH_CARDS
	call	ObjCallInstanceNoLock

	push	bp					;save locals
	mov	cardAttrs.PCD_cardNumber, dl
	mov	bp, dx					;bp <= card #
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	cx, bp					;cx <= card attrs.
	pop	bp					;restore locals
	mov	cardAttrs.PCD_cardAttribute, cl

	movdw	bxsi, chunkArray
	call	MemDerefDS
	call	ChunkArrayAppend

CheckHack <size PassCardData eq size word>
	mov	ax, {word} cardAttrs
	mov	ds:[di], ax				;chunkArray <= card

	movdw	bxsi, deckOptr
	call	MemDerefDS

	mov	cx, switchCards
	cmp	cl, ch
	jl	passLoop

	tst	numPassCards
	jz	exitRoutine

;not enough cards switched so call HeartsDeckComputerPassDontBeDumb

	clr	numNuetralCards

notEnoughCardsSwitched:
	call	HeartsDeckComputerPassDontBeDumb

exitRoutine:
	.leave
	ret
HeartsDeckSwitchRunOfCards	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckComputerPassDontBeDumb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will reorder the deck so that the last cards are the cards
		that the deck should pass following the "Dont be Dumb"
		tacktic.  (Pass one nuetral card and the rest your worst
		cards)

CALLED BY:	HeartsDeckComputerPassCards
PASS:		*ds:si	= HeartsDeckClass object
		bp	= pointer to stack frame of HeartsDeckComputerPassCards
		chunkArray	=	optr to chunkarray to store pass cards
		numPassCards	=	number of cards to pass
		numNuetralCards	=	number of nuetral cards to pass
		numDeckCards	=	number of cards in the deck
		deckOptr	=	optr to the deck passing cards
		cardAttrs	=	PassCardData temp variable

RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	will mess up the local variables and will add some
		elements to the chunk array

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckComputerPassDontBeDumb	proc	near
	.enter	inherit	HeartsDeckComputerPassCards

passLoop:
	push	bp					;save locals

	clr	ch
	mov	cl, numDeckCards			;find lowest card
							;from all card unchosen
	mov	al, numNuetralCards
	cmp	numPassCards, al
	jg	getLowest
;getNuetral:
	call	HeartsDeckGetNuetralCard
	jmp	doneGetting
getLowest:
	call	HeartsDeckGetLowestCard
doneGetting:
	pop	bp					;restore locals

	dec	numPassCards
	dec	numDeckCards

	clr	dh
	mov	dl, numDeckCards			;switch the worst card
							;with the last card.
	mov	ax, MSG_HEARTS_DECK_SWITCH_CARDS
	call	ObjCallInstanceNoLock

	push	bp					;save locals
	mov	cardAttrs.PCD_cardNumber, dl
	mov	bp, dx					;bp <= card #
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	cx, bp					;cx <= card attrs.
	pop	bp					;restore locals
	mov	cardAttrs.PCD_cardAttribute, cl

	movdw	bxsi, chunkArray
	call	MemDerefDS
	call	ChunkArrayAppend

CheckHack <size PassCardData eq size word>
	mov	ax, {word} cardAttrs
	mov	ds:[di], ax				;chunkArray <= card

	movdw	bxsi, deckOptr
	call	MemDerefDS

	tst	numPassCards
	jg	passLoop

	.leave
	ret
HeartsDeckComputerPassDontBeDumb	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckCompletePassCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	message sent to MyHand to indicate that the pass cards
		have been selected and ready to do the pass, and then
		start the game

CALLED BY:	HeartsPassTrigger
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckCompletePassCards	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_COMPLETE_PASS_CARDS
	uses	ax, cx, dx, bp
	.enter

	;
	;	Check to see if the number of passing cards is equal
	;	to the number of cards selected to pass.
	;	I'm assuming this method only gets called for MyDeck.
	;	(*ds:si = MyDeck).
	;	Added to correct for a timing hole where
	;	MSG_DECK_UP_CARD_SELECTED can be handled after the
	;	"Pass Cards" trigger has been pressed, but before we
	;	we get here.  Later in this method handler, we set
	;	MyDeck not enabled to prevent any further 
	;	MSG_DECK_UP_CARD_SELECTED from being handled.
	;

	mov	ax, MSG_HEARTS_GAME_GET_NUMBER_OF_PASS_CARDS
	call	VisCallParent
	mov	dl, cl			; dl <= num pass cards

	push	si			; save offset
	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_chunkPointer
	call	MemLock
	jc	exitRoutine		; error locking
	mov	ds, ax

	call	ChunkArrayGetCount	; cl <= # cards selected
	call	MemUnlock
	pop	si			; restore offset
	cmp	cl, dl
	jne	exitRoutine		; # cards selected != # pass cards

	;    If we are not passing cards then bail.
	;

	mov	ax, MSG_HEARTS_GAME_GET_GAME_ATTRS
	call	VisCallParent
	test	cl,mask HGA_PASSING_CARDS
	jz	exitRoutine

	;     Clear our passing mode bit
	;

	BitClr	cl, HGA_PASSING_CARDS
	mov	ax, MSG_HEARTS_GAME_SET_GAME_ATTRS
	call	VisCallParent

	mov	cx, 1				;set detectable
	call	HeartsDeckSetDiscardDeck

	call	HeartsDeckRemovePassTrigger
	
	;    Don't let player click on any more cards until the game
	;    starts
	;

	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	ax, MSG_VIS_SET_ATTRS
	mov	dl, VUM_NOW
	mov	cx, (mask VA_DETECTABLE) shl 8
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

;pass the cards around.
	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	ax, MSG_HEARTS_DECK_SWITCH_PASS_CARDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage


	;   Start the game, but do it via the queue so that
	;   the screen can redraw before the delay at
	;   the begining of the handler for the message
	;   we are about to send.
	;

	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	ax, MSG_HEARTS_DECK_START_GAME_AFTER_PASSING
	call	ObjMessage


exitRoutine:
	.leave
	ret
HeartsDeckCompletePassCards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckStartGameAfterPassing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will clear the inverted cards in MyDeck and then call
		HeartsDeckStartGame

CALLED BY:	HeartsDeckCompletePassCards
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will start the game

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckStartGameAfterPassing	method dynamic HeartsDeckClass, 
				MSG_HEARTS_DECK_START_GAME_AFTER_PASSING
	uses	ax, cx, dx, bp
	.enter

	mov	di,offset YourCardsText
	call	HeartsDeckDrawPlayerInstructions

	;   Let the player look at his/her new cards
	;

	mov	ax, SHOW_PASSED_CARDS_TIMER_INTERVAL
	call	TimerSleep

;clear the inverted cards in MyDeck
	mov	bx, handle MyDeck
	mov	si, offset MyDeck
	mov	ax, MSG_HEARTS_DECK_UNINVERT_CHUNK_ARRAY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

;start the game
	mov	bx, handle ComputerDeck3
	mov	si, offset ComputerDeck3
	mov	ax, MSG_HEARTS_DECK_START_GAME
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HeartsDeckStartGameAfterPassing	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckRemovePassTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will remove the PassTrigger associated dialog box from
		the screen, and disable the PassTrigger

CALLED BY:	HeartsDeckCompletePassCards
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckRemovePassTrigger	proc	near
	.enter

;disable the pass trigger
	mov	bx, handle HeartsPassTrigger
	mov	si, offset HeartsPassTrigger
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

;remove the pass dialog box
	mov	bx, handle HeartsPassing
	mov	si, offset HeartsPassing
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HeartsDeckRemovePassTrigger	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckUpdataPassPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will move the pass pointer to the next person to pass to.

CALLED BY:	MSG_HEARTS_DECK_UPDATE_PASS_POINTER
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		cx	= 0 if passing to another deck
DESTROYED:	ax, dx, bp
SIDE EFFECTS:	will set the passPointer instance data

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckUpdataPassPointer	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_UPDATE_PASS_POINTER
	.enter


	tstdw	ds:[di].HI_passPointer
	jz	initializePointer

;move passPointer to next person to pass to.
	push	si					;save offset
	movdw	bxsi, ds:[di].HI_passPointer
	mov	ax, MSG_HEARTS_DECK_GET_NEIGHBOR_POINTER
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si					;restore offset
	Deref_DI Deck_offset
	mov	ax, ds:[LMBH_handle]
	cmpdw	axsi, cxdx				;check if passing to
							;oneself
	jne	validPass
;invalidPass:
	clrdw	ds:[di].HI_passPointer			;set passPointer to
							;initial state
	mov	cx, HOLD_HAND
	jmp	exitRoutine

validPass:
	movdw	ds:[di].HI_passPointer, cxdx
	jmp	doneSettingPointer

initializePointer:
	movdw	ds:[di].HI_passPointer, ds:[di].HI_neighborPointer, ax

doneSettingPointer:
	clr	cx					;passing valid

exitRoutine:
	call	ObjMarkDirty

	.leave
	ret
HeartsDeckUpdataPassPointer	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSwitchPassCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will switch the cards for all the people passing cards
		and resort the deck.  Note that number of cards to
		pass must not be zero because we are looping and not checking
		for the initial zero case.

CALLED BY:	MSG_HEARTS_DECK_SWITCH_PASS_CARDS
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will switch the cards

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSwitchPassCards	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_SWITCH_PASS_CARDS
	uses	ax, cx, dx, bp

deckAttrs		local	byte
deckOptr		local	optr
numPassCards		local	byte
cardAttrs		local	byte
passArray		local	optr
deckArray		local	optr

	.enter

	mov	bx, ds:[LMBH_handle]
	movdw	deckOptr, bxsi
	mov	al, ds:[di].HI_deckAttributes
	mov	deckAttrs, al

	mov	ax, MSG_HEARTS_GAME_GET_NUMBER_OF_PASS_CARDS
	call	VisCallParent
	mov	numPassCards, cl
	Deref_DI Deck_offset

	movdw	bxdx, ds:[di].HI_chunkPointer
	call	MemLock
	movdw	deckArray, bxdx

	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_passPointer
	mov	ax, MSG_HEARTS_DECK_GET_CHUNK_ARRAY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	bx, cx					;bx <= chunk handle
	call	MemLock
	movdw	passArray, bxdx

switchingLoop:
	dec	numPassCards
	clr	ah
	mov	al, numPassCards
	movdw	bxsi, passArray
	call	MemDerefDS
	call	ChunkArrayElementToPtr
	mov	bl, ds:[di].PCD_cardAttribute
	mov	cardAttrs, bl
	movdw	bxsi, deckArray
	call	MemDerefDS
	call	ChunkArrayElementToPtr
	clr	dx
	mov	cl, ds:[di].PCD_cardNumber
	clr	ch					;cx <= card #

	push	bp					;save locals
	movdw	bxsi, deckOptr
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp					;restore locals

	mov	al, cardAttrs
	movdw	bxsi, cxdx				;^lbx:si <= card optr
	call	HeartsDeckSetTheNewAttributes

	tst	numPassCards
	jnz	switchingLoop

	movdw	bxsi, deckOptr 
	call	MemDerefDS
	movdw	axbx, deckArray
	movdw	cxdx, passArray
	call	HeartsDeckSetPassReceiveData

;unlockLMem:
	mov	bx, deckArray.handle
	call	MemUnlock
	mov	bx, passArray.handle
	call	MemUnlock

	test	deckAttrs, mask HDA_COMPUTER_PLAYER
	jz	notComputerPlayer
;computerPlayer:
	movdw	bxsi, deckOptr
	call	MemDerefDS
	mov	ax, MSG_HEARTS_DECK_SORT_DECK
	call	ObjCallInstanceNoLock
	push	bp					;save locals
	mov	ax, MSG_HEARTS_DECK_REDRAW_IF_FACE_UP
	call	ObjCallInstanceNoLock
	pop	bp					;restore locals
	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_neighborPointer
	mov	ax, MSG_HEARTS_DECK_SWITCH_PASS_CARDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jmp	exitRoutine

notComputerPlayer:
if WAV_SOUND
	mov	cx,HS_CARDS_PASSED
	call	HeartsGamePlaySound
endif

	movdw	bxsi, deckOptr
	call	MemDerefDS
	mov	ax, MSG_HEARTS_DECK_SORT_DECK
	call	ObjCallInstanceNoLock
	push	bp					;save locals
	mov	ax, MSG_DECK_REDRAW
	call	ObjCallInstanceNoLock
	pop	bp					;restore locals

exitRoutine:
	.leave
	ret
HeartsDeckSwitchPassCards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetPassReceiveData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will Set the HI_passedCards and HI_receivedCards instance
		data.

CALLED BY:	HeartsDeckSwitchPassCards
PASS:		ds:si	= HeartsDeck object
		^lax:bx	= deckArray (locked down)
		^lcx:dx	= passArray (locked down)

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetPassReceiveData	proc	near

deckArray	local	optr	push	ax,bx
passArray	local	optr	push	cx,dx
deckOptr	local	optr

	.enter
	class	HeartsDeckClass

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	movdw	deckOptr, cxdx
	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_passPointer
	movdw	ds:[di].HI_receivedCards.PD_passerOD, bxsi
	mov	ax, MSG_HEARTS_DECK_SET_PASS_TO_POINTER
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	movdw	bxsi, passArray
	call	MemDerefDS

	call	HeartsDeckGetCardAttributesFromArray
	push	dx,cx					;save received cards

	movdw	bxsi, deckArray
	call	MemDerefDS
	
	call	HeartsDeckGetCardAttributesFromArray

	movdw	bxsi, deckOptr
	call	MemDerefDS
	Deref_DI Deck_offset
	mov	ds:[di].HI_passedCards.PD_cardsPassed.HPC_card1, dl
	mov	ds:[di].HI_passedCards.PD_cardsPassed.HPC_card2, dh
	mov	ds:[di].HI_passedCards.PD_cardsPassed.HPC_card3, cl

	pop	dx,cx					;restore received cards
	mov	ds:[di].HI_receivedCards.PD_cardsPassed.HPC_card1, dl
	mov	ds:[di].HI_receivedCards.PD_cardsPassed.HPC_card2, dh
	mov	ds:[di].HI_receivedCards.PD_cardsPassed.HPC_card3, cl
	call	ObjMarkDirty

	.leave
	ret
HeartsDeckSetPassReceiveData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetCardAttributesFromArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the top threee card attributes from the 
		chunk array

CALLED BY:	HeartsDeckSetPassReceiveData
PASS:		*ds:si	= chunk array

RETURN:		dl	= first card Attribute
		dh	= second card Attribute
		cl	= third card Attribute

DESTROYED:	ax, ch, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 8/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetCardAttributesFromArray	proc	near
	.enter

	clr	ax
	call	ChunkArrayElementToPtr
	mov	dl, ds:[di].PCD_cardAttribute
	inc	al
	call	ChunkArrayElementToPtr
	mov	dh, ds:[di].PCD_cardAttribute
	inc	al
	call	ChunkArrayElementToPtr
	mov	cl, ds:[di].PCD_cardAttribute

	.leave
	ret
HeartsDeckGetCardAttributesFromArray	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetPassToPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will set the HI_passedCards.PD_passerOD instance data 

CALLED BY:	MSG_HEARTS_DECK_SET_PASS_TO_POINTER
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data
		^lcx:dx	= player your passing to.

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will set the instance data

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 5/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetPassToPointer	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_SET_PASS_TO_POINTER
	.enter

	movdw	ds:[di].HI_passedCards.PD_passerOD, cxdx
	call	ObjMarkDirty

	.leave
	ret
HeartsDeckSetPassToPointer	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFlipCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will flip all the cards in the deck and redraw the deck

CALLED BY:	HeartsGameFlipComputerDecks
PASS:		*ds:si	= HeartsDeckClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	will flip the deck and redraw itself

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFlipCards	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_FLIP_CARDS
	.enter

		;mark all the cards as dirty.

	mov	ax, MSG_CARD_MARK_DIRTY_IF_FACE_DOWN
	call	VisSendToChildren

	mov	ax, MSG_CARD_FLIP
	call	VisSendToChildren

	mov	ax, MSG_DECK_REDRAW
	call	ObjCallInstanceNoLock

	.leave
	ret
HeartsDeckFlipCards	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckRedrawIfFaceUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will do a deck redraw if the top card is face up.

CALLED BY:	MSG_HEARTS_DECK_REDRAW_IF_FACE_UP
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	may redraw the deck

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckRedrawIfFaceUp	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_REDRAW_IF_FACE_UP
	.enter

	clr	bp				;clear attributes
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	VisCallFirstChild

	test	bp, mask CA_FACE_UP
	jz	exitRoutine			;top card not face up

	mov	ax, MSG_DECK_REDRAW
	call	ObjCallInstanceNoLock

exitRoutine:
	.leave
	ret
HeartsDeckRedrawIfFaceUp	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSetTheNewAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will set the attributes for a card

CALLED BY:	HeartsDeckSwitchPassCards

PASS:		al	= new card attributes
		^lbx:si	= card to set the attributes for

RETURN:		nothing
DESTROYED:	ax,dx,di
SIDE EFFECTS:	will set the attributes of the card

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSetTheNewAttributes	proc	near
	uses	bp
	.enter

	mov	dl, al				;dl <= card attrs.
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	ax, bp				;ax <= cards old attrs.
	and	al, not (RANK_MASK or SUIT_MASK)
	and	dl, RANK_MASK or SUIT_MASK
	or	al, dl
	mov	bp, ax				;bp <= new card attrs.
	mov	ax, MSG_CARD_SET_ATTRIBUTES
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
HeartsDeckSetTheNewAttributes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckPlayTopCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will move the top card from the deck to the discard
		deck

CALLED BY:	MSG_HEARTS_DECK_PLAY_TOP_CARD

PASS:		*ds:si	= HeartsDeckClass object to pass card
		^lcx:dx	= handle to deck to recieve card

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	pop card from the giving deck and push card on recieving deck

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckPlayTopCard	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_PLAY_TOP_CARD
	uses	ax, cx, dx, bp

receivingDeck		local	optr	push cx,dx
donorDeck		local	optr
topCard			local	optr

	.enter

	mov	ax, ds:[LMBH_handle]
	movdw	donorDeck, axsi

	push	bp				;save locals

	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock
	Deref_DI Deck_offset			;save the original position
	mov	ds:[di].DI_initLeft, ax
	mov	ds:[di].DI_initTop, bp
	mov	ds:[di].DI_initRight, cx
	mov	ds:[di].DI_initBottom, dx
	call	ObjMarkDirty

	clr	cx				;find first child
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock
	pushdw	cxdx				;save card optr

	clr	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	cx, bp				;cl <= card attrs.	
	Deref_DI Deck_offset
	mov	ch, ds:[di].HI_deckIdNumber
	mov	ax, MSG_HEARTS_GAME_SET_PLAYERS_DATA
	call	VisCallParent

	mov	bp, 1
	mov	ax, MSG_CARD_MAXIMIZE
	call	HeartsDeckCallNthChild

	popdw	bxsi				;restore card optr
	mov	ax, MSG_CARD_TURN_FACE_UP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_CARD_NORMAL_REDRAW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	bp				;restore locals
	push	bp				;save locals
	movdw	cxdx, receivingDeck
	call	HeartsDeckMoveCardToDiscard

	pop	bp				;restore locals
	push	bp				;save locals
	movdw	topCard, bxsi
	movdw	cxdx, donorDeck
	push	dx				;save offset

	mov	ax, MSG_CARD_GET_ATTRIBUTES
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	call	HeartsDeckSetTakeData

	pop	si				;restore offset
	mov	ax, MSG_DECK_POP_CARD
	call	ObjCallInstanceNoLock

	mov	ax, MSG_DECK_INVALIDATE_INIT
	call	ObjCallInstanceNoLock

;	clr	bp
;	mov	ax, MSG_CARD_MAXIMIZE		;make sure top card is now
;	call	HeartsDeckCallNthChild		;set to full size

	pop	bp				;restore locals
	push	bp				;save locals
	movdw	cxdx, topCard
	movdw	bxsi, receivingDeck

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_DECK_PUSH_CARD
	call	ObjMessage

	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	ax, MSG_HEARTS_GAME_SET_SHOOT_DATA
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	pop	bp				;restore locals

	.leave
	ret
HeartsDeckPlayTopCard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HeartsDeckCallNthChild
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
		cx,dx,bp	= return values

DESTROYED:	ax, di

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
HeartsDeckCallNthChild	proc	near
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
HeartsDeckCallNthChild	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckMoveCardToDiscard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will visually move the card in ^lbx:si to the discard
		deck.

CALLED BY:	HeartsDeckPlayTopCard
PASS:		^lbx:si	= card to move
		^lcx:dx	= deck moving to

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will move the card in ^lbx:si to the discard deck

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckMoveCardToDiscard	proc	near
	uses	ax,bx,cx,dx,si,di,bp

receivingDeck			local	optr	push 	cx,dx
gState				local	word
originalTopPosition		local	dword
originalBottomPosition		local	dword
discardPosition			local	dword

	.enter
	class	HeartsDeckClass

	pushdw	bxsi				;save card to move
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	ax, MSG_HEARTS_GAME_GET_GAME_ATTRS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	popdw	bxsi				;restore card to move
	test	cl, mask HGA_DONT_SHOW_MOVEMENT
	LONG jnz	exitRoutine		;dont show the movement

	push	bp				;save locals

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	di, bp				;cx <= GState
	pop	bp				;restore locals
	mov	gState, di

	;change the graphics state to our liking and draw the outline
	mov	al, MM_INVERT
	call	GrSetMixMode			;set invert mode

	clr	ax, dx
	call	GrSetLineWidth			;set line width = 1


	push	bp					;save locals
	mov	ax, MSG_VIS_GET_BOUNDS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	bx, bp					;bx <= top
	pop	bp					;restore locals

	movdw	originalTopPosition, axbx
	movdw	originalBottomPosition, cxdx

	push	bp					;save locals
	movdw	bxsi, receivingDeck
	mov	ax, MSG_HEARTS_DECK_GET_PUSH_CARD_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp					;restore locals
	movdw	discardPosition, cxdx

	mov	di, gState
	movdw	axbx, originalTopPosition
	movdw	cxdx, originalBottomPosition
	call	GrDrawRect

	cmp	bx, discardPosition.offset
	jz	yPositionOK
	jg	moveCardUp

moveCardDown:
	call	GrDrawRect
	add	bx, CARD_Y_MOVEMENT_AMOUNT		;bx <= new top pos.
	add	dx, CARD_Y_MOVEMENT_AMOUNT		;dx <= new bottom pos.
	cmp	bx, discardPosition.offset
	jge	lastYMove

	call	GrDrawRect
	jmp	moveCardDown

moveCardUp:
	call	GrDrawRect
	sub	bx, CARD_Y_MOVEMENT_AMOUNT		;bx <= new top pos.
	sub	dx, CARD_Y_MOVEMENT_AMOUNT		;dx <= new bottom pos.
	cmp	bx, discardPosition.offset
	jle	lastYMove

	call	GrDrawRect
	jmp	moveCardUp

lastYMove:
	sub	dx, bx
	mov	bx, discardPosition.offset
	add	dx, bx
	call	GrDrawRect

yPositionOK:	
	cmp	ax, discardPosition.handle
	jz	xPositionOK
	jg	moveCardLeft

moveCardRight:
	call	GrDrawRect
	add	ax, CARD_X_MOVEMENT_AMOUNT		;bx <= new left pos.
	add	cx, CARD_X_MOVEMENT_AMOUNT		;dx <= new right pos.
	cmp	ax, discardPosition.handle
	jge	lastXMove

	call	GrDrawRect
	jmp	moveCardRight

moveCardLeft:	
	call	GrDrawRect
	sub	ax, CARD_X_MOVEMENT_AMOUNT		;bx <= new left pos.
	sub	cx, CARD_X_MOVEMENT_AMOUNT		;dx <= new right pos.
	cmp	ax, discardPosition.handle
	jle	lastXMove

	call	GrDrawRect
	jmp	moveCardLeft

lastXMove:
	sub	cx, ax
	mov	ax, discardPosition.handle
	add	cx, ax
	call	GrDrawRect

xPositionOK:
	call	GrDrawRect
	call	GrDestroyState

exitRoutine:
	.leave
	ret
HeartsDeckMoveCardToDiscard	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetPushCardPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will return the position where the next card to push should
		go.

CALLED BY:	MSG_HEARTS_DECK_GET_PUSH_CARD_POSITION
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		cx	= left edge of object
		dx	= top edge of object

DESTROYED:	ax, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetPushCardPosition	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_GET_PUSH_CARD_POSITION
	.enter

	clr	bp
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	VisCallFirstChild
	tst	bp			;see if we got anything back (i.e.,
					;see if we have any children)
	jnz	gotTopCardAttrs		;if so, we've got its attributes in bp

;noKids:
					;just returns the deck position
	mov	ax, MSG_VIS_GET_POSITION
	call	ObjCallInstanceNoLock
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
	add	cx, ds:[di].DI_topCardLeft	;add the offsets to the topCard
	add	dx, ds:[di].DI_topCardTop	;position

endDeckOffsetTopLeft:

	.leave
	ret
HeartsDeckGetPushCardPosition	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckShiftCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will exchange the cx card with the first card and shift
		all the other cards down accordingly to preserve the deck
		order.

CALLED BY:	MSG_HEARTS_DECK_SHIFT_CARDS
PASS:		*ds:si	= HeartsDeckClass object
		cl	= the card to swap with the first card.
				(first card is card 0)
		ch	= 0 to redraw the deck if face up when done,
			  1 not to redraw deck when done

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will alter the deck by shifting the cards

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckShiftCards	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_SHIFT_CARDS
	uses	ax, cx, dx, bp
	.enter
	
;setup for loop
	mov	bp, cx				;save cx
	clr	ch				;eliminate interference by ch
	jcxz	exitRoutine			;card already in place

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_SWITCH_CARDS

;perform loop 

switchLoop:
	mov	dx, cx
	dec	cx
	call	ObjCallInstanceNoLock
	tst	cx
	jnz	switchLoop

	mov	cx, bp				;restore cx
	tst	ch
	jnz	exitRoutine			;dont redraw deck
	mov	ax, MSG_HEARTS_DECK_REDRAW_IF_FACE_UP
	call	ObjCallInstanceNoLock

exitRoutine:
	.leave
	ret
HeartsDeckShiftCards	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSortDeck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rearranges the cards in the deck in order by suit
		and card number

CALLED BY:	MSG_HEARTS_DECK_SORT_DECK
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data
		ds:bx	= HeartsDeckClass object (same as *ds:si)
		es 	= segment of HeartsDeckClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Rearranges the cards in the deck

PSEUDO CODE/STRATEGY:	To perform a selection sort on the cards in
		the deck, and two cards are switched simply by exchanging
		there suit and card number

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSortDeck	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_SORT_DECK
	uses	ax, cx, dx, bp

loopCounter		local	word
numberOfCards		local	word

	.enter
	
;setup for loop

	clr	loopCounter
	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	jcxz	exitRoutine				;no card in deck
	mov	numberOfCards, cx

;perform loop 

sortLoop:
	mov	dx, loopCounter
	mov	ax, MSG_HEARTS_DECK_FIND_SMALLEST_CARD
	call	ObjCallInstanceNoLock
	cmp	cx, loopCounter
	je	noSwitchCards

	mov	dx, loopCounter
	mov	ax, MSG_HEARTS_DECK_SWITCH_CARDS
	call	ObjCallInstanceNoLock

noSwitchCards:
	inc	loopCounter
	mov	cx, numberOfCards
	cmp	loopCounter, cx
	jl	sortLoop

exitRoutine:
	.leave
	ret
HeartsDeckSortDeck	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckSwitchCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	switch two card in a deck

CALLED BY:	MSG_HEARTS_DECK_SORT_DECK

PASS:		cx, dx	= the cards to switch
		*ds:si	= instance data of deck

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Find the first childs attributes (dx child), and push
		them on the stack.
		Find the second childs attributs (cx child), set to first
		childs attributes, and set first child to have second
		childs original attributes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/25/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckSwitchCards	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_SWITCH_CARDS
	uses	ax, cx, dx, bp
	.enter

	cmp	cx, dx
	je	exitRoutine			;the cards are the same, 
						;nothing to do.
	push	cx, si

	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock
	mov	bx, cx
	mov	si, dx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	ObjMessage
	
	mov	di, si
	pop	dx, si				;find attributes of next child
	push	bx, di				
	push	bp				;save attributes of prev child

	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock
	mov	bx, cx
	mov	si, dx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	ObjMessage

	mov	ax, bp
	pop	bp
	push	ax
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CARD_SET_ATTRIBUTES 
	call	ObjMessage

	pop	bp
	pop	bx, si
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CARD_SET_ATTRIBUTES 
	call	ObjMessage

exitRoutine:
	.leave
	ret
HeartsDeckSwitchCards	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFindSmallestCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the smallest cards value and where in the deck it
		is located.

CALLED BY:	MSG_HEARTS_DECK_SORT_DECK

PASS:		cx	= number of cards in deck
		dx	= starting loop number
		*ds:si	= instance data of deck

RETURN:		cx 	= the number of smallest card in deck
		dx	= the smallest card value (13*suit + rank)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		loop through the deck to find the smallest card
		and return the value

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/25/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFindSmallestCard	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_FIND_SMALLEST_CARD
	uses	ax, bp

	smallestCardValue	local	byte
	actualCardValue		local	byte
	smallestCard		local	word
	loopCounter		local	word
	numberOfCards		local	word

	.enter

	mov	smallestCardValue, MAX_CARD_VALUE
	clr	smallestCard
	mov	loopCounter, dx
	mov	numberOfCards, cx


firstLoop:
	push	bp				;save local variable reg
	clr	cx
	mov	dx, loopCounter			;set which child to find
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock
	push	si				;save si
	mov	bx, cx
	mov	si, dx

	call	HeartsDeckGetCardValue		;get value of card
	mov	ah, al				;save card value
	call	HeartsDeckFixupCardValue	;make it so suits are ordered
						;in correct order.
	pop	si				;restore si
	pop	bp				;restore local variable reg

	cmp	smallestCardValue, al
	jl	noAdjustments

	mov	smallestCardValue, al
	mov	actualCardValue, ah
	push	loopCounter
	pop	smallestCard

noAdjustments:
	inc	loopCounter
	mov	ax, numberOfCards
	cmp	loopCounter, ax
	jl	firstLoop
	
	mov	cx, smallestCard
	clr	dh
	mov	dl, actualCardValue

	.leave
	ret
HeartsDeckFindSmallestCard	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			HeartsDeckPushCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DECK_PUSH_CARD, MSG_DECK_PUSH_CARD_NO_EFFECTS handler
		for HeartsDeckClass
		Adds a card to the deck's composite, and does some visual
		operations that reflect the adoption. The two methods
		are identical at this level, but exist independently so
		they can be subclassed differently.  Also adds the card to
		the decks chunk array

CALLED BY:	

PASS:		*ds:si = instance data of deck
		^lcx:dx = card to be added
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		call the superclass, and then add the element to the
		chunk array.

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/27/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0

HeartsDeckPushCard   method  HeartsDeckClass, 
			MSG_DECK_PUSH_CARD, MSG_DECK_PUSH_CARD_NO_EFFECTS


	mov	di, offset HeartsDeckClass
	call	ObjCallSuperNoLock

	ret
HeartsDeckPushCard	endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFixupCardValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will make it so the order of cards is diamond, clubs, hearts
		and spades, instead of diamonds, hearts, clubs, spades

CALLED BY:	HeartsDeckFindSmallestCard
PASS:		al	= card value
RETURN:		al	= modified card value
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 6/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFixupCardValue	proc	near
	.enter

	cmp	al, 40
	jg	exitRoutine
	cmp	al, 15
	jl	exitRoutine
	cmp	al, 27
	jg	fixupClubs
;fixupHearts:
	add	al, 13			;make hearts greater than clubs
	jmp	exitRoutine

fixupClubs:
	sub	al, 13			;make clubs smaller than hearts

exitRoutine:
	.leave
	ret
HeartsDeckFixupCardValue	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetCardValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the a number (between 2 and 53) to represent the 
		card.

CALLED BY:	
PASS:		^lbx:si	= handle to card
RETURN:		ax	= number representing card
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		find the rank and suit of the card and return
		13*suit + rank

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetCardValue	proc	near
	uses	di,bp
	.enter
	class	HeartsDeckClass

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CARD_GET_ATTRIBUTES
	call	ObjMessage
	mov	ax, bp				;move CI_cardAttrs into ax
	call	HeartsDeckConvertCardAttributes

	.leave
	ret
HeartsDeckGetCardValue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckConvertCardAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert the card attributes to a number between 2 and 53
		to represent the card

CALLED BY:	HeartsDeckGetCardValue
PASS:		ax	= cardAttrs
RETURN:		ax	= number representing card
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 8/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckConvertCardAttributes	proc	near
	uses	cx
	.enter

	mov	cl, al
	call	HeartsDeckGetCardRank
	xchg	al, cl
;findSuit:
	and	al, SUIT_MASK			;mask out the suit
	shr	al, 1				;move suit to low order bits
	mov	ah, 13
	mul	ah				;muliply suit by 13
	add	al, cl				;add rank to 13*suit

	.leave
	ret
HeartsDeckConvertCardAttributes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetCardRank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will return the card rank (a number between 2 and 14)

CALLED BY:	
PASS:		al	= card attributes
RETURN:		al	= rank of card
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetCardRank	proc	near
	.enter

	and	al, RANK_MASK			;mask out the rank of the
						;card
	cmp	al, RANK_ACE
	jne	notAce
;isAce:
	mov	al, ACE_VALUE			;set al to the highest value
	jmp	exitRoutine
notAce:
	shr	al, 1				;move rank to low order bits
	shr	al, 1
	shr	al, 1
exitRoutine:

	.leave
	ret
HeartsDeckGetCardRank	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckDeleteCardFromArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will delete the card whose value is passed in ax from
		the chunk array pointed to by ^lbx:si

CALLED BY:	
PASS:		^lbx:si	= handle to chunk array
		ax	= card value to delete

RETURN:		Carry set if not in deck
DESTROYED:	nothing
SIDE EFFECTS:	will remove the card value from the chunk array

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0

HeartsDeckDeleteCardFromArray	proc	near
	uses	ax,cx,dx,di,ds
	.enter
	class	HeartsDeckClass

	mov	dx, ax				;save the card value

	call	MemLock
	mov	ds, ax
	clr	ax

	call	ChunkArrayGetCount
	push	bx
	mov	bx, cx

continueSearch:
	cmp	bx, ax
	jz	elementNotFound

	call	ChunkArrayElementToPtr
	cmp	dl, ds:[di]			;test the card number
	jz	foundElement
	inc	ax
	jmp	continueSearch

elementNotFound:
	pop	bx
	stc
	jmp	exitRoutine	

foundElement:
	pop	bx
	call	ChunkArrayDelete
	clc

exitRoutine:
	call	MemUnlock

	.leave
	ret
HeartsDeckDeleteCardFromArray	endp

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				HeartsDeckRemoveNthCard
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
		call the superclass to actually do the removing
		then remove the card from the ChunkArray if necessary

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/28/93		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0

HeartsDeckRemoveNthCard		method		HeartsDeckClass,
					 MSG_DECK_REMOVE_NTH_CARD

	mov	di, offset HeartsDeckClass
	call	ObjCallSuperNoLock
	ret

HeartsDeckRemoveNthCard		endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckStartGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the deck has the two of clubs and if
		it does, then it starts the game and if not then it
		sends the START_GAME message to its neighbor.

CALLED BY:	MSG_HEARTS_DECK_START_GAME
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data
		ds:bx	= HeartsDeckClass object (same as *ds:si)
		es 	= segment of HeartsDeckClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckStartGame	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_START_GAME
	uses	ax, cx, dx
	.enter

	mov	dl, TWO or CLUBS
	call	HeartsDeckFindCardGivenAttr
	cmp	cx, 0
	jl	notInTheDeck

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_PLAY_CARD	
	call	ObjCallInstanceNoLock

	jmp	exitRoutine

notInTheDeck:
	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_neighborPointer
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_DECK_START_GAME
	call	ObjMessage

exitRoutine:
	.leave
	ret
HeartsDeckStartGame	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckPlayCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will play the next card if the deck is a computer player
		or will give up control to the user if it is the users
		turn to play a card.  If 4 cards have been played, then 
		it will enable to the take trigger, else it will send
		a message to the next player for him to play a card.

CALLED BY:	MSG_HEARTS_DECK_PLAY_CARD
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data
		ds:bx	= HeartsDeckClass object (same as *ds:si)
		es 	= segment of HeartsDeckClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	watch for the special case of the beginning of the game because
	then the two of clubs must be played.

	If the deck is a computer player then :
		strategy is to figure out what card to play next
		switch that card with the first card
		play the first card
		call the neighbor to play a card
	else
		strategy is to let the user play a valid card
		call the neighbor to play a card

	also must check to see if 4 cards have been played.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckPlayCard	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_PLAY_CARD
	uses	ax, cx, dx, bp
	.enter


	mov	ax, MSG_HEARTS_GAME_GET_CARDS_PLAYED
	call	VisCallParent	
	cmp	cl, NUM_PLAYERS
	jz	fourCardsPlayed
	cmp	cl, 0
	jg	dontSetTheLead
;setTheLead:
	push	cx				;save number of cards played
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_HEARTS_GAME_SET_LEAD_POINTER
	call	VisCallParent
	pop	cx				;restore number of cards played

dontSetTheLead:
	mov	ax, handle MyDeck
	cmp	ax, ds:[LMBH_handle]
	jnz	computerPlayer
	mov	ax, offset MyDeck
	cmp	ax, si
	jz	humanPlayer
	
computerPlayer:
	mov	di,offset BlankText
	call	HeartsDeckDrawPlayerInstructions

	;    Slow the computer down a little so as not to boggle the user
	;

	mov	ax,COMPUTER_PLAYER_DELAY_TIMER_INTERVAL
	call	TimerSleep

	cmp	cl, 0
	jl	playTwoClubs
	jz	playFirstCard

	call	HeartsDeckFollowSuit
	jmp	playTopCard	                  

fourCardsPlayed:
	;    Play sounds associated with trick taken
	;
if WAV_SOUND
	mov	ax, MSG_HEARTS_GAME_CHECK_TAKEN_SOUND
	call	VisCallParent
endif
	;    Show which player took the trick
	;

	push	si
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_GAME_GET_TAKE_POINTER
	call	ObjMessage
	mov	bx, cx				;bx <= take card handle
	mov	si, dx				;si <= take card offset
	mov	ax, MSG_HEARTS_DECK_INVERT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si

	;    Do the business of actually taking the trick
	;
	
	clr	cl				;set cards played to zero
	mov	ax, MSG_HEARTS_GAME_SET_CARDS_PLAYED
	call	VisCallParent
	call	HeartsDeckSetTakeTrigger

	jmp	exitRoutine
	
playFirstCard:
	call	HeartsDeckPlayFirstCard
	jmp	playTopCard
	

playTwoClubs:
	clr	cl				;set cards played to zero
	mov	ax, MSG_HEARTS_GAME_SET_CARDS_PLAYED
	call	VisCallParent
	call	HeartsDeckPlayTwoClubs
	jmp	playTopCard


humanPlayer:
	mov	di,offset StartWithTwoOfClubsText
	cmp	cl,0
	jl	drawInstructions
	mov	di,offset ItsYourTurnText
drawInstructions:
	call	HeartsDeckDrawPlayerInstructions
	mov	ax, DRAW_SCORE_HIGHLIGHTED
	call	HeartsDeckSetHumanPlayer
	jmp	exitRoutine

playTopCard:
	mov	cx, handle DiscardDeck
	mov	dx, offset DiscardDeck
	mov	ax, MSG_HEARTS_DECK_PLAY_TOP_CARD
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_HEARTS_GAME_GET_CARDS_PLAYED
	call	VisCallParent
	inc	cl				;cards played++
	mov	ax, MSG_HEARTS_GAME_SET_CARDS_PLAYED
	call	VisCallParent

	;    Play sounds associated with card played if any
	;

	mov	ax, MSG_HEARTS_GAME_CHECK_PLAY_SOUND
	call	VisCallParent

	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_neighborPointer
	mov	ax, MSG_HEARTS_DECK_PLAY_CARD
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
				;changed to force-queue to make the playing
				;of the top card finish updating the screen
				;before playing the next card.
	call	ObjMessage

exitRoutine:
	.leave
	ret
HeartsDeckPlayCard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckPlayFirstCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will switch the top card of the deck with a card from the
		deck that should be played first

CALLED BY:	HeartsDeckPlayCard
PASS:		*ds:si	= instance data of the deck

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will probably switch the order to two cards in the deck

PSEUDO CODE/STRATEGY:
		Check to see if there are any card of the correct suit in
		the deck, and if there are, then play the smallest one.

		If void in that suit, then play the worst card that is in
		the deck.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckPlayFirstCard	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	class	HeartsDeckClass

	mov	ax, MSG_HEARTS_GAME_CHECK_HEARTS_BROKEN
	call	VisCallParent
	mov	bl, cl				;bl <= Hearts Broken
	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	mov	bp, cx				;bp <= card #
	clr	dx				;dl <= best card number
						;dh <= best chance
bestCardLoop:
	dec 	bp
	push	bp				;save card #
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp				;ax <= card attr.
	and	al, SUIT_MASK
	xor	al, HEARTS			;al <= 0 if hearts
	or	al, bl				;al <= 0 if hearts and
						;hearts not broken
	tst	al
	jz	continueLoop
;heartsBroken:	
	mov	ax, bp				;ax <= card attr.
	call	HeartsDeckGetChanceOfTaking
	and	al, SUIT_MASK or RANK_MASK
	cmp	al, JACK or DIAMONDS
	jne	notTheJack
	tst	cl
	jz	takeThisOne			;we will win by leading
						;jack of d.
	tst	dh
	jnz	continueLoop
	mov	cl, 1
	jmp	newBestCard			;every card till now would
						;definitly win, so lead
						;jack to lose lead.

notTheJack:
	cmp	cx, 0
	jl	takeThisOne			;we won't win by leading
						;this.
	cmp	cl, dh
	jl	continueLoop			;better chance of losing 
						;lead with other card
newBestCard:
	pop	dx				;get card number
	push	dx				;save card number
	mov	dh, cl				;set new best chance
	jmp	continueLoop

takeThisOne:
	pop	cx
	jmp	switchCards

continueLoop:
	pop	bp
	cmp	bp, 0
	jg	bestCardLoop

;endLoop:
	mov	cl, dl				;cl <= best card number
;	clr	ch
	
switchCards:
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_SHIFT_CARDS
	clr	ch					;redraw deck
;	mov	ch, 1					;don't redraw deck
	call	ObjCallInstanceNoLock

;exitRoutine:
	.leave
	ret
HeartsDeckPlayFirstCard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckCheckJackAndQueen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check and see if the Jack of Diamonds or the 
		Queen of Spades is an appropriate card to play

CALLED BY:	HeartsDeckFollowSuit
PASS:		*ds:si	= instance data of the deck
		al	= take card attributes
		cx	= score of discard deck
				
RETURN:		Carry set if card appropriate to play and
		cx	= location of card to play
DESTROYED:	ax, dx, cx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Check if Jack will take the trick and that taking the trick
		with the Jack is good.
		Check if Queen will not take the trick.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckCheckJackAndQueen	proc	near
	.enter

	and	al, SUIT_MASK
	cmp	al, DIAMONDS			;check if lead card is diamond
	jne	notDiamonds
	cmp	cx, MAXIMUM_POINTS_BEFORE_DEFINITELY_BAD
	jg	noTake				;not worth taking with jack
	mov	dl, JACK or DIAMONDS
	call	HeartsDeckFindCardGivenAttr
	cmp	cx, 0
	jl	noTake				;don't have the jack
	mov	dx, cx				;dx <= location of jack
	mov	al, JACK or DIAMONDS
	call	HeartsDeckGetChanceOfTaking
	tst	cx
	jnz	noTake				;not guaranteed to take jack
	mov	cx, dx				;cx <= location of jack
	stc
	jmp	exitRoutine

notDiamonds:
	cmp	al, SPADES			;check if lead card is spade
	jne	noTake
	mov	dl, QUEEN or SPADES
	call	HeartsDeckFindCardGivenAttr
	cmp	cx, 0
	jl	noTake				;don't have the queen
	mov	dx, cx				;dx <= location of queen
	mov	al, QUEEN or SPADES
	call	HeartsDeckGetChanceOfTaking
	cmp	cx, 0
	jge	noTake				;not guaranteed to lose
	mov	cx, dx				;cx <= location of jack
	stc
	jmp	exitRoutine

noTake:
	clc
exitRoutine:

	.leave
	ret
HeartsDeckCheckJackAndQueen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFollowingPreventShoot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will switch the top card of the deck with a card from the 
		deck that best prevents someone from shooting the moon.

CALLED BY:	HeartsDeckFollowSuit
PASS:		*ds:si	= instance data of the deck
		cl	= deck ID of deck trying to shoot

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,bp,di

SIDE EFFECTS:	will probably switch the order of two cards in the deck

PSEUDO CODE/STRATEGY:
		check if deck is void in suit lead
		if not void :
			see if the highest card of the suit lead will take the
			trick or beat the card played by the shooter.  
			If so, then lead that card, if not, then
			lead the smallest card of that suit.
		if void:
			Check if there are points in the discardDeck, and if 
			there are, then don't play a heart.
			check if the shooter's card will take the trick, and
			if so, then dont play a heart.
			Otherwise dump a low bad card (smallest heart or
			the Queen of Spades).

		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFollowingPreventShoot	proc	near

deckOffset		local	word	push	si
shootDeck		local	word	push	cx
takeCardAttr		local	byte
cardNumber		local	byte
cardAttr		local	byte

ForceRef	deckOffset
ForceRef	shootDeck
ForceRef	cardAttr

	.enter
	class	HeartsDeckClass
	
	mov	ax, MSG_HEARTS_GAME_GET_TAKE_CARD_ATTR
	call	VisCallParent
	mov	takeCardAttr, cl
	push	bp					;save locals
	mov	bp, cx					;bp <= take card attr.
	mov	ax, MSG_HEARTS_DECK_COUNT_NUMBER_OF_SUIT
	call	ObjCallInstanceNoLock
	pop	bp					;restore locals
	jcxz	voidInSuit
;notVoid:
	mov	cardNumber, dl
	cmp	cl, 1
	je	playCard				;only one card of 
							;correct suit.
	call	HeartsDeckFollowingPreventShootNotVoid
	jmp	playCard

voidInSuit:
	call	HeartsDeckFollowingPreventShootVoid

playCard:
	mov	cl, cardNumber
	clr	ch					;redraw deck
	mov	ax, MSG_HEARTS_DECK_SHIFT_CARDS
	call	ObjCallInstanceNoLock

	.leave
	ret
HeartsDeckFollowingPreventShoot	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFollowingPreventShootNotVoid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will take care of the not void case for
		HeartsDeckFollowingPreventShoot

CALLED BY:	HeartsDeckFollowingPreventShoot

PASS:		dx	= # of highest card.
		deckOffset
		shootDeck
		takeCardAttr
		cardNumber
		cardAttr

RETURN:		modified local varibles, namely cardNumber as the card
		to play.

DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		see if the highest card of the suit lead will take the
		trick or beat the card played by the shooter.  
		If so, then lead that card, if not, then
		lead the smallest card of that suit.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/ 8/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFollowingPreventShootNotVoid	proc	near

	.enter	inherit	HeartsDeckFollowingPreventShoot

	push	bp					;save locals
	mov	bp, dx					;bp <= # of high card
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp					;ax <= high card attrs.
	and	bp, SUIT_MASK
	cmp	bp, SPADES
	pop	bp					;restore locals
	mov	cardAttr, al
	jne	notSpades
;checkIfQueenHasBeenPlayed:
	mov	al, takeCardAttr
	call	HeartsDeckGetCardRank
	cmp	al, RANK_VALUE_OF_QUEEN
	jge	notGaranteedToTakeTrick			;the queen or a higher
							;card are out, dont
							;try and take trick
	mov	dl, mask HA_NO_QUEEN
	call	HeartsDeckCheckIfCardHasBeenPlayed	
	tst	ch
	jnz	notGaranteedToTakeTrick			;queen hasnt been 
							;played yet, dont
							;try and take trick
notSpades:
	mov	cx, shootDeck
	mov	ax, MSG_HEARTS_GAME_CHECK_IF_DECK_PLAYED
	call	VisCallParent
	cmp	cl, ch					;check if shooter has
							;gone yet
	jl	shooterHasGone
;shooterHasntGone:
	mov	al, cardAttr
	call	HeartsDeckGetChanceOfTaking
	jcxz	exitRoutine				;will take trick
	jmp	notGaranteedToTakeTrick

shooterHasGone:
	inc	cl
	sub	ch, cl
	xchg	ch, cl
	clr	ch					;cx <= # of shooter
							;	card
	push	bp					;save locals
	mov	bp, cx					;bp <= # of shooter
							;	card
	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, bp					;ax <= shooter card 
							;	attr.
	pop	bp					;restore locals
	mov	si, deckOffset					;restore offset
	call	HeartsDeckGetCardRank
	mov	ah, al					;ah <= rank of shooter
							;	card
	mov	al, cardAttr
	call	HeartsDeckGetCardRank
	cmp	al, ah
	jg	exitRoutine				;will beat shooters
							;card
notGaranteedToTakeTrick:
	push	bp					;save locals
	mov	al, takeCardAttr
	mov	bp, ax
	mov	cx, 1					;find lowest card
	mov	ax, MSG_HEARTS_DECK_FIND_HIGH_OR_LOW
	call	ObjCallInstanceNoLock
	pop	bp					;restore locals
	mov	cardNumber, ch

exitRoutine:
	mov	cl, cardNumber
	clr	ch
	mov	di, 1					;only check if Jack or
							;Queen
	call	HeartsDeckMakeSureNotDumbMove
	mov	cardNumber, cl


	.leave
	ret
HeartsDeckFollowingPreventShootNotVoid	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFollowingPreventShootVoid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will take care of the void case for
		HeartsDeckFollowingPreventShoot

CALLED BY:	HeartsDeckFollowingPreventShoot

PASS:		deckOffset
		shootDeck
		takeCardAttr
		cardNumber
		cardAttr

RETURN:		modified local varibles, namely cardNumber as the card
		to play.

DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Check if there are points in the discardDeck, and if 
		there are, then don't play a heart.
		check if the shooter's card will take the trick, and
		if so, then dont play a heart.
		Otherwise dump a low bad card (smallest heart or
		the Queen of Spades).
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/ 8/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFollowingPreventShootVoid	proc	near

	.enter	inherit	HeartsDeckFollowingPreventShoot

	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	ax, MSG_HEARTS_DECK_CALCULATE_SCORE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, deckOffset				;restore offset
	tst	al					;check if any (+) pts.
	jg	dontPlayHeart				;there are pts in deck

;checkIfShooterWillTakeTrick:
	mov	cx, shootDeck
	mov	ax, MSG_HEARTS_GAME_CHECK_IF_DECK_PLAYED
	call	VisCallParent
	cmp	cl, ch					;check if shooter has
							;gone yet
	jge	playLowHeart				;shooter hasn't gone

;shooterHasGone:
	cmp	ch, NUM_PLAYERS -1
	je	dontPlayHeart				;were last deck to play
							;card, shooter will
							;take trick.
	inc	cl
	sub	ch, cl
	xchg	ch, cl
	clr	ch					;cx <= # of shooter
							;	card
	push	bp					;save locals
	mov	bp, cx					;bp <= # of shooter
							;	card
	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, bp					;ax <= shooter card 
							;	attr.
	pop	bp					;restore locals
	mov	si, deckOffset				;restore offset
	call	HeartsDeckGetChanceOfTaking
	jcxz	dontPlayHeart				;shooter will take 
							;trick

playLowHeart:
	mov	dl, QUEEN or SPADES
	call	HeartsDeckFindCardGivenAttr
	tst	cx
	jge	playQueen
	push	bp					;save locals
	mov	bp, HEARTS
	mov	cx, 1					;find lowest card
	mov	ax, MSG_HEARTS_DECK_FIND_HIGH_OR_LOW
	call	ObjCallInstanceNoLock
	pop	bp					;restore locals
	jcxz	dontPlayHeart				;dont have any hearts
	mov	cardNumber, ch
	jmp	exitRoutine

playQueen:
	mov	cardNumber, cl
	jmp	exitRoutine

dontPlayHeart:
	push	bp					;save locals
	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock

	mov	dx, MAXIMUM_STRATEGIC_POINTS	;dx <= lowest str. card val.
	mov	bl, 1				;bl <= lowest card number + 1

getNuetralCardVal:
	mov	bp, cx				;bp <= card number
	dec	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp				;ax <= nth card attr.
	and	bp, SUIT_MASK
	cmp	bp, HEARTS
	je	notValidCard
	mov	bp, cx				;save card number
	call	HeartsDeckGetStrategicCardValue
	cmp	cx, 0
	jge	valueIsPositive
	neg	cx
valueIsPositive:
	cmp	cx, dx
	jg	continueLoop
	mov	bx, bp				;bx <= card number
	mov	dx, cx				;dx <= str. card val.
continueLoop:
	mov	cx, bp				;restore card number
notValidCard:
	loop	getNuetralCardVal

	dec	bl
	pop	bp					;restore locals
	mov	cardNumber, bl	

exitRoutine:

	.leave
	ret
HeartsDeckFollowingPreventShootVoid	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckCheckIfPreventing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the deck ID of the deck that we are trying to 
		prevent from shooting, or zero if we're not trying to prevent
		shooting.

CALLED BY:	HeartsDeckFollowSuit
PASS:		*ds:si	= HeartsDeckClass object
		ds:di	= HeartsDeckClass instance data

RETURN:		cx	= 0 if not trying to prevent moon shoot
			= deck ID of deck trying to shoot 

DESTROYED:	ax, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckCheckIfPreventing	method dynamic HeartsDeckClass, 
					MSG_HEARTS_DECK_CHECK_IF_PREVENTING
	.enter

	mov	ax, MSG_HEARTS_GAME_GET_SHOOT_DATA
	call	VisCallParent
	cmp	cl, 0				;cmp shootData, 0
	jg	someonePossiblyShooting
;noOneShooting:
	BitClr	ds:[di].HI_shootStyle.HSS_currentInfo, HSI_PREVENTING_SHOOT
	jmp	dontPrevent

someonePossiblyShooting:
	clr	ch				;cx <= deck ID of deck 
						;	possibly shooting
	test	ds:[di].HI_shootStyle.HSS_currentInfo, 
			mask HSI_PREVENTING_SHOOT
	jnz	exitRoutine			;currently preventing

;notCurrentlyPreventing:
	push	cx				;save deck ID
	call	TimerGetCount
	mov	dx, ax
	mov	ax, MSG_GAME_SEED_RANDOM
	call	VisCallParent

	mov	dx, MAX_ODDS
	mov	ax, MSG_GAME_RANDOM
	call	VisCallParent
	pop	cx				;restore deck ID

	cmp	dl, ds:[di].HI_shootStyle.HSS_oddsOnPreventing
	jge	probablyDontPrevent
;tryAndPrevent:
	BitSet	ds:[di].HI_shootStyle.HSS_currentInfo, HSI_PREVENTING_SHOOT
	jmp	exitRoutine

probablyDontPrevent:				;check if shooter lead a
						;shooting card

	cmp	dl, ds:[di].HI_shootStyle.HSS_oddsOnBeingCautious
	jge	dontPrevent			;dont try and prevent shooting

	mov	bx, cx				;bx <= deck ID
	mov	ax, MSG_HEARTS_GAME_GET_TAKE_CARD_ATTR
	call	VisCallParent
	mov	bp, cx				;bp <= take card attr
	and	cl, SUIT_MASK
	cmp	cl, HEARTS
	jne	dontPrevent

	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	cmp	cl, MANY_CARDS_LEFT
	jl	dontPrevent			;too late in the game to be
						;suspicious.

	mov	cl, bl				;restore deck ID
	mov	di, offset heartsDeckPlayersTable
	dec	cl
CheckHack < size optr eq 4 >
	shl	cl, 1
	shl	cl, 1				;multiply cl * 4 (size optr)
	clr	ch
	add	di, cx				;di <= offset for shooter deck
	
	mov	ax, MSG_HEARTS_GAME_GET_LEAD_POINTER
	call	VisCallParent

	cmpdw	cs:[di], cxdx			;check if shooter lead.
	mov	cx, bx				;restore deck ID
	jne	dontPrevent			;shooter didnt lead
	mov	ax, bp				;ax <= take card attr
	;
	;	the take card attr is the same as the lead attribute because
	;	the person trying to shoot has to take the trick or it
	;	it is impossible to shoot.
	;
	call	HeartsDeckGetCardRank
	cmp	al, RANK_VALUE_OF_JACK
	jge	exitRoutine			;shooter lead higher than a 
						;jack of hearts, prevent
						;from shooting.
dontPrevent:
	clr	cx
exitRoutine:

	.leave
	ret
HeartsDeckCheckIfPreventing	endm



heartsDeckPlayersTable		optr	\
	ComputerDeck3,
	ComputerDeck2,
	ComputerDeck1,
	MyDeck




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFollowSuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will switch the top card of the deck with a card from the
		deck that obeys the follow suit rule.

CALLED BY:	HeartsDeckPlayCard
PASS:		*ds:si	= instance data of the deck

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	will probably switch the order of two cards in the deck

PSEUDO CODE/STRATEGY:
		Check to see if there are any card of the correct suit in
		the deck, and if there are, then play the smallest one.

		If void in that suit, then play the worst card that is in
		the deck.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFollowSuit	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	class	HeartsDeckClass
	
	mov	ax, MSG_HEARTS_DECK_CHECK_IF_PREVENTING
	call	ObjCallInstanceNoLock
	jcxz	notPreventingShootingMoon
;preventingShootingMoon:
	call	HeartsDeckFollowingPreventShoot
	jmp	exitRoutine

notPreventingShootingMoon:	
	push	si				;save offset

	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_CALCULATE_SCORE
	call	ObjMessage
	pop	si				;restore offset
	xchg	dx, cx				;save worth taking?
	mov	ax, MSG_HEARTS_GAME_GET_TAKE_CARD_ATTR
	call	VisCallParent
	mov	al, cl				;al <= takeCardAttr
	mov	bp, ax
	xchg	dx, cx				;restore worth taking?
	cmp	cx, 0
	jge	notWorthTaking
;worthTaking:
	clr	cx				;search for highest card
	jmp	checkForSuit

notWorthTaking:

;check to see if Jack of Diamonds or Queen of Spades is an 
;appropriate card to play

	call	HeartsDeckCheckJackAndQueen
	jc	switchCards			;Jack or Queen is appropriate
	
	push	si				;save offset
	clr	cx				;search for highest card
	mov	si, offset DiscardDeck
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_FIND_HIGH_OR_LOW
	call	ObjMessage

	pop	si				;restore offset
	mov	ch, cl
	clr	cl				;search for highest card 
						;that still wont take the
						;trick

	push	cx				;save what to search for
	mov	ax, bp				;ax <= takeCardAttr
	and	al, SUIT_MASK
	cmp	al, DIAMONDS
	jne	notDiamonds
;isDiamond:
	mov	dl, mask HA_NO_JACK
	call	HeartsDeckCheckIfCardHasBeenPlayed
	tst	ch
	jz	notDiamonds			;jack has been played
;jackHasntBeenPlayed:
	pop	cx
	cmp	ch, RANK_VALUE_OF_JACK
	jl	checkForSuit			;highest card is lower than 
						;jack
	mov	ch, RANK_VALUE_OF_JACK
	jmp	checkForSuit

notDiamonds:
	pop	cx

checkForSuit:
	mov	ax, MSG_HEARTS_DECK_FIND_HIGH_OR_LOW
	call	ObjCallInstanceNoLock
	tst	cx
	jnz	notVoid				;not void in suit

;voidInSuit:
	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock

	call	HeartsDeckGetLowestCard

	jcxz	exitRoutine
	jmp	switchCards

notVoid:
	mov	cl, ch				;move card number into cl
	clr	ch
	clr	di				;check if deck is last.
	call	HeartsDeckMakeSureNotDumbMove

switchCards:
	mov	ax, MSG_HEARTS_DECK_SHIFT_CARDS
	clr	ch					;redraw deck
	call	ObjCallInstanceNoLock

exitRoutine:

	.leave
	ret
HeartsDeckFollowSuit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetNuetralCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the number of the card that is most nuetral
		in the first cx cards of the deck

CALLED BY:	HeartsDeckComputerPassCards
PASS:		*ds:si	= deck object
		cx	= number of cards to look through, starting at 
			  zero

RETURN:		cx	= number of card with the lowest value.
DESTROYED:	ax,bx,dx,bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetNuetralCard	proc	near
	.enter
	class	HeartsDeckClass

	mov	dx, MAXIMUM_STRATEGIC_POINTS	;dx <= lowest str. card val.
	clr	bx				;bx <= lowest card number

getNuetralCardVal:
	mov	bp, cx				;bp <= card number
	dec	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp				;ax <= nth card attr.
	mov	bp, cx				;save card number
	call	HeartsDeckGetStrategicCardValue
	cmp	cx, 0
	jge	valueIsPositive
	neg	cx
valueIsPositive:
	cmp	cx, dx
	jg	continueLoop
	mov	bx, bp				;bx <= card number
	mov	dx, cx				;dx <= str. card val.
continueLoop:
	mov	cx, bp				;restore card number
	loop	getNuetralCardVal

	dec	bx
	mov	cx, bx				;cx <= card number

	.leave
	ret
HeartsDeckGetNuetralCard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckGetLowestCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the number of the card with the lowest value in
		the first cx cards of the deck

CALLED BY:	HeartsDeckFollowSuit
PASS:		*ds:si	= deck object
		cx	= number of cards to look through, starting at 
			  zero

RETURN:		cx	= number of card with the lowest value.
DESTROYED:	ax,bx,dx,bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckGetLowestCard	proc	near
	.enter
	class	HeartsDeckClass

	mov	dx, MAXIMUM_STRATEGIC_POINTS	;dx <= lowest str. card val.
	clr	bx				;bx <= lowest card number

getLowestStrCardVal:
	mov	bp, cx				;bp <= card number
	dec	bp
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp				;ax <= nth card attr.
	mov	bp, cx				;save card number
	call	HeartsDeckGetStrategicCardValue
	cmp	cx, dx
	jg	continueLoop
	mov	bx, bp				;bx <= card number
	mov	dx, cx				;dx <= str. card val.
continueLoop:
	mov	cx, bp				;restore card number
	loop	getLowestStrCardVal

	dec	bx
	mov	cx, bx				;cx <= card number

	.leave
	ret
HeartsDeckGetLowestCard	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckMakeSureNotDumbMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will make sure that the Jack of Diamonds is not played 
		if it won't take the trick.  Also, will check that the
		Queen of Spades is not played if were going to take the
		trick

CALLED BY:	HeartsDeckFollowSuit
PASS:		cx	= card number to play
		di	= 0 if should also adjust for deck being last player
				of trick.
			!= 0 if should only check about jack and queen
		*ds:si	= HeartsDeck playing the card

RETURN:		cx	= card number that should be played (possibly
			  changed)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		assumption made:  that the deck is sorted.

		check if bad card to play, and if it is then check if
		there is a better card to play of the same suit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckMakeSureNotDumbMove	proc	near
	uses	ax,bx,dx,bp,di
	.enter
	class	HeartsDeckClass

	push	cx				;save card number
	mov	bp, cx				;bp <= card number
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	push	bp				;save card attr.
	mov	ax, MSG_HEARTS_DECK_COUNT_NUMBER_OF_SUIT
	call	ObjCallInstanceNoLock
	pop	bp				;restore card attr.
	mov	ax, bp				;ax <= card attr.
	pop	dx				;restore card number
	cmp	cl, 1
	LONG je	exitRoutine			;only one card of this suit
						;(don't have any choice)
	and	al, SUIT_MASK or RANK_MASK
	cmp	al, JACK or DIAMONDS
	LONG je	checkJackOfDiamonds
	cmp	al, QUEEN or SPADES
	je 	checkQueenOfSpades

	tst	di
	LONG jnz	exitRoutine		;dont check if deck is last
;checkIfLastCard:
	call	HeartsDeckCheckIfLastCard
	LONG jnc	exitRoutine
;lastCard:
	mov	ax, bp				;ax <= card attr.
	call	HeartsDeckGetChanceOfTaking
	push	cx				;save chance of taking

	push	si				;save offset
	mov	bx, handle DiscardDeck
	mov	si, offset DiscardDeck
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_CALCULATE_SCORE
	call	ObjMessage
	pop	si				;restore offset
	pop	ax				;ax <= chance of taking
	jcxz	willTakeTrick			;no bad points, so take
						;it high
	cmp	ax, 0
	LONG jl	exitRoutine			;won't take trick
	cmp	cx, 0
	mov	cx, 0				;search for highest card
	jl	findHighestCard			;going to take trick and
						;get jack, make sure highest 
						;diamond is played

willTakeTrick:
	mov	ax, bp				;ax <= card attr
	and	al, SUIT_MASK
	cmp	al, DIAMONDS
	jne	findHighestCard
;findLowestCard:
	push	dx				;save card to play
	mov	dl, mask HA_NO_JACK
	call	HeartsDeckCheckIfCardHasBeenPlayed
	pop	dx				;restore card to play

findHighestCard:
	mov	ax, MSG_HEARTS_DECK_FIND_HIGH_OR_LOW
	call	ObjCallInstanceNoLock

;check to make sure not playing the queen of spades of jack of diamonds

	mov	cl, ch				;set cx to card numher
	clr	ch
	mov	bp, cx				;bp <= card number
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp				;ax <= card attr.
	and	al, SUIT_MASK or RANK_MASK
	cmp	al, JACK or DIAMONDS
	je	exitRoutine
	cmp	al, QUEEN or SPADES
	je 	exitRoutine

	mov	dx, cx				;set dx to new card to play
	jmp	exitRoutine

checkQueenOfSpades:
	mov	ax, bp				;ax <= card attr.
	call	HeartsDeckGetChanceOfTaking
	cmp	cx, 0
	jl	exitRoutine			;queen won't take trick
	mov	bl, SPADES			;bl <= suit to check for
	tst	dx				;check card number
	jz	checkGreaterCard
	jmp	checkSmallerCard

checkJackOfDiamonds:
	mov	ax, bp				;ax <= card attr.
	call	HeartsDeckGetChanceOfTaking
	tst	cx
	jz	exitRoutine			;jack will take trick
	mov	bl, DIAMONDS			;bl <= suit to check for
	tst	dx				;check card number
	jz	checkGreaterCard
;	jmp	checkSmallerCard

checkSmallerCard:
	dec	dx				;dx <= card # - 1
	mov	bp, dx				;bp <= card # - 1
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp				;ax <= card attr.
	and	al, SUIT_MASK
	cmp	al, bl				;check if same suit
	je	exitRoutine
	inc	dx				;dx <= card #

checkGreaterCard:
	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	dec	cx
	cmp	cx, dx				;check if dx = last card
	je	exitRoutine			;dx = last card
	inc	dx				;dx <= card # + 1
	mov	bp, dx				;bp <= card # + 1
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	ax, bp				;ax <= card attr.
	and	al, SUIT_MASK
	cmp	al, bl				;check if same suit
	je	exitRoutine
	dec	dx				;dx <= card #

exitRoutine:
	mov	cx, dx	

	.leave
	ret
HeartsDeckMakeSureNotDumbMove	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckCheckIfCardHasBeenPlayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return RANK_VALUE_OF_JACK if the jack has not been
		played, or zero if the Jack has been played

CALLED BY:	HeartsDeckMakeSureNotDumbMove
PASS:		*ds:si	= HeartsDeckClass object playing the card
		dl	= mask HA_NO_JACK or mask HA_NO_QUEEN depending
				if checking if jack or queen has been
				played.
RETURN:		ch	= RANK_VALUE_OF_JACK if jack has not been played
			= 0 if card has been played.
		ds	= updated segment (possibly moved)

DESTROYED:	ax, bx, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckCheckIfCardHasBeenPlayed	proc	near
	uses	dx,si,bp

deckOD		local	word
loopCounter	local	word

	.enter
	class	HeartsDeckClass

	mov	ax, ds:[LMBH_handle]
	mov	deckOD, ax
	mov	loopCounter, NUM_PLAYERS -1

	Deref_DI Deck_offset
	movdw	bxsi, ds:[di].HI_playersDataPtr
	call	MemLock
	mov	ds, ax

continueLoop:
	mov	ax, loopCounter
	call	ChunkArrayElementToPtr
	test	ds:[di].PD_cardAssumptions, dl
	jz	jackNotPlayedYet
	dec	loopCounter
	jge	continueLoop

;jackHasBeenPlayed:
	clr	ch
	jmp	exitRoutine

jackNotPlayedYet:
	mov	ch, RANK_VALUE_OF_JACK		;search for greatest card
						;lower than a jack

exitRoutine:
	call	MemUnlock
	mov	bx, deckOD
	call	MemDerefDS

	.leave
	ret
HeartsDeckCheckIfCardHasBeenPlayed	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckCheckIfLastCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check and see if this player is the last player to have
		suit that was lead.

CALLED BY:	HeartsDeckMakeSureNotDumbMove

PASS:		*ds:si	= HeartsDeckClass object
		bp	= card attrs of card lead

RETURN:		ds	= updated segment (possibly moved)
		carry set if person is last person with proper suit

DESTROYED:	ax, bx, cx, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		if three NUM_PLAYERS -1 cards have been played, then this is
		the last person to play.
		Check to see if the remaining players that have to play cards 
		are void in the suit lead, and if all them are, then
		you are the last person to play a card.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/25/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckCheckIfLastCard	proc	near
	uses	dx,si,bp

cardLead		local	word		push	bp
deckOD			local	word
loopCounter		local	byte
arrayElement		local	byte
cardSuit		local	byte

	.enter
	class	HeartsDeckClass

	mov	ax, ds:[LMBH_handle]
	mov	deckOD, ax
	mov	ax, MSG_HEARTS_GAME_GET_CARDS_PLAYED
	call	VisCallParent
	cmp	cl, NUM_PLAYERS - 1
	je	isLastCard
	mov	loopCounter, NUM_PLAYERS - 1
	sub	loopCounter, cl

	mov	ax, cardLead
	clr	cardSuit
	and	al, SUIT_MASK
	cmp	al, HEARTS
	je	setHearts
	cmp	al, DIAMONDS
	je	setDiamonds
	cmp	al, CLUBS
	je	setClubs
;setSpades:
	BitSet	cardSuit, HS_SPADES
	jmp	doneSettingSuit

setHearts:
	BitSet	cardSuit, HS_HEARTS
	jmp	doneSettingSuit

setDiamonds:
	BitSet	cardSuit, HS_DIAMONDS
	jmp	doneSettingSuit

setClubs:
	BitSet	cardSuit, HS_CLUBS


doneSettingSuit:
	Deref_DI Deck_offset
	mov	ch, ds:[di].HI_deckIdNumber
	and	ch, ID_NUMBER_MASK
	mov	arrayElement, ch		;arrayElement <= next deck's
						;		 ID number.
	movdw	bxsi, ds:[di].HI_playersDataPtr
	call	MemLock
	mov	ds, ax

checkingLoop:
	clr	ah
	mov	al, arrayElement
	call	ChunkArrayElementToPtr
	mov	cl, ds:[di].PD_voidSuits
	test	cl, cardSuit
	jz	notVoidInSuit
	dec	loopCounter
	jz	noOneLeftWithSuit
	inc	arrayElement
	and	arrayElement, ID_NUMBER_MASK
	jmp	checkingLoop

notVoidInSuit:
	call	MemUnlock
	clc
	jmp	exitRoutine

noOneLeftWithSuit:
	call	MemUnlock
isLastCard:
	stc

exitRoutine:
	mov	bx, deckOD
	call	MemDerefDS

	.leave
	ret
HeartsDeckCheckIfLastCard	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckPlayTwoClubs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will switch the two of clubs with the first card in the deck.

CALLED BY:	HeartsDeckPlayCard
PASS:		*ds:si	= instance data of deck

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	changes order of cards in deck

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckPlayTwoClubs	proc	near
	uses	ax,cx,dx,di
	.enter
	class	HeartsDeckClass

	mov	dl, TWO or CLUBS
	call	HeartsDeckFindCardGivenAttr
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_HEARTS_DECK_SHIFT_CARDS
	clr	ch					;redraw deck
;	mov	ch, 1					;don't redraw deck
	call	ObjCallInstanceNoLock

	.leave
	ret
HeartsDeckPlayTwoClubs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFindCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the card number of the card in the deck

CALLED BY:	HeartsDeckPlayTwoClubs
PASS:		*ds:si	= instance data of the deck
		ax	= card value to find

RETURN:		cx	= number of the card in the deck
			  (-1 if not found)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0

HeartsDeckFindCard	proc	near
	uses	ax,dx
	.enter
	class	HeartsDeckClass

	mov	cl, 13				;number of cards in a suit
	div	cl
	cmp	ah, 1				;check the remainder
;	je	fixupAce
	jl	fixupKing
	jne	doneFixup
;fixupAce:
	sub	al, 1				;fixup the quotient
	jmp	doneFixup
fixupKing:
	mov	ah, 13
doneFixup:
	shl	ah, 1
	shl	ah, 1
	shl	ah, 1
	shl	al, 1
	or	al, ah

	mov	dl, al				;dx <= card attributes
	call	HeartsDeckFindCardGivenAttr
;exitRoutine:
	

	.leave
	ret
HeartsDeckFindCard	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsDeckFindCardGivenAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the card number of the card in the deck

CALLED BY:	HeartsDeckFindCard
PASS:		*ds:si	= instance data of the deck
		dl	= card attributes to find

RETURN:		cx	= number of the card in the deck
			  (-1 if not found)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	2/22/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsDeckFindCardGivenAttr	proc	near
	uses	ax,bx,bp
	.enter
	class	HeartsDeckClass

	mov	ax, MSG_DECK_GET_N_CARDS
	call	ObjCallInstanceNoLock
	jcxz	notFound

countingLoop:
	dec	cx
	mov	bp, cx				;set card to find
	mov	ax, MSG_DECK_GET_NTH_CARD_ATTRIBUTES
	call	ObjCallInstanceNoLock
	mov	bx, bp
	and	bl, RANK_MASK or SUIT_MASK
	cmp	bl, dl				;check if the same card
	jz	foundCard

	tst	cx
	jnz	countingLoop	

notFound:
	mov	cx, -1				;card was not found
	
foundCard:
	;cx is already set to card number	

	.leave
	ret
HeartsDeckFindCardGivenAttr	endp





CommonCode	ends				;end of CommonCode resource
