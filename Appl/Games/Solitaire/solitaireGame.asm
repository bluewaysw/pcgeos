COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Solitaire
FILE:		Solitaire.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	9/90		Initial Version

DESCRIPTION:


RCS STAMP:
$Id: solitaireGame.asm,v 1.1 97/04/04 15:46:57 newdeal Exp $
------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------
	_JEDI	= FALSE

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;
;	This constant is stuck in the handle of the game's last donor
;	data indicating that no card transfers have taken place yet.
;
USER_HASNT_STARTED_PLAYING_YET = 0

;
;	ONE_SECOND is the number of ticks per second
;
ONE_SECOND = 60

;
;	The following constants are needed to set up STANDARD_SCORING
;

INITIAL_STANDARD_SCORE = 0
SS_MINIMUM_SCORE = 0		;min. score for STANDARD_SCORING
VS_MINIMUM_SCORE = -25000	;min. score for ST_VEGAS

SS_HAND_PUSH = 0
SS_HAND_POP = 0
SS_HAND_FLIP = 0

SS_TALON_PUSH = 0
SS_TALON_POP = 5
;
;	the 'cost' of turning over the talon is computed by the formula
;		points = 10 * (draw number) - 40
;	This means it costs 30 points for 1 card drawing, and 10 points
;	for 3 card drawing. See PTSetupStandardScoring for details...
;	

SS_FOUNDATION_PUSH = 10
SS_FOUNDATION_POP = -10
SS_FOUNDATION_FLIP = 0

SS_TABLEAU_PUSH = 0
SS_TABLEAU_POP = 0
SS_TABLEAU_FLIP = 5

;
;	The user is penalized SS_POINTS_PER_TAX every SS_SECONDS_PER_TAX secs.
;
SS_SECONDS_PER_TAX = 10
SS_POINTS_PER_TAX = -1


;
;	The following constants are used under ST_VEGAS
;
INITIAL_VEGAS_SCORE = -52	;initial score for ST_VEGAS (in $)

VS_HAND_PUSH = 0
VS_HAND_POP = 0
VS_HAND_FLIP = 0

VS_TALON_PUSH = 0
VS_TALON_POP = 0
VS_TALON_FLIP = 0

VS_FOUNDATION_PUSH = 5
VS_FOUNDATION_POP = -5
VS_FOUNDATION_FLIP = 0

VS_TABLEAU_PUSH = 0
VS_TABLEAU_POP = 0
VS_TABLEAU_FLIP = 0

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Object Class include files
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									   ;
;				METHODS					   ;
;									   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SolitaireClass	class	GameClass
MSG_SOLITAIRE_GET_COUNTDOWN_SECONDS_FROM_UI		method
MSG_SOLITAIRE_SET_UI_COUNTDOWN_SECONDS			method

MSG_SOLITAIRE_CASH_OUT			method

MSG_SOLITAIRE_CHECK_AUTO_FINISH_ENABLE	method
MSG_SOLITAIRE_AUTO_FINISH		method

MSG_SOLITAIRE_CHECK_FOR_WINNER		method
;
;	Checks whether or not the user has won the game yet, and
;	if so sends a method to itself to produce the win effect.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_DEAL			method
;
;	Deals out a new game of solitaire by passing out cards from the
;	hand to the tableau elements.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_GET_DRAW_NUMBER		method
;
;	Returns the number of cards that should be flipped over from the
;	hand to the talon each time the user clicks on the hand.
;
;	PASS:		nothing
;
;	RETURN:		cl = # of cards to draw

MSG_SOLITAIRE_GET_SCORING_TYPE		method
;
;	Returns the scoring mode that the game is being played under.
;
;	PASS:		nothing
;
;	RETURN:		cl = ScoringType

MSG_SOLITAIRE_INITIALIZE_SCORE		method
;
;	Sets up the scoring mechanism for the game (i.e., each deck
;	is informed of its point values, etc.) Also alters the score
;	to reflect a new game.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_INITIALIZE_TIME		method
;
;	Clears the game time, stops any current timer, and starts a
;	new timer.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_NEW_GAME			method
;
;	Cleans up any business from the preceeding game and initiates
;	a new game.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_ONE_SECOND_ELAPSED	method
;
;	This method tells the game that yet another second has gone by.
;	Solitaire increments its time counter and reflects the change
;	on screen
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_INIT_DATA_FROM_UI		method
;
;	Initializes the game object's instance data from various UI gadgetry
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_QUERY_FLUSH_OK		method
;
;	Checks to make sure that the talon hasn't been
;	flushed more than the number of cards that are flipped
;	each time (under vegas scoring only).
;
;	PASS:		nothing
;
;	RETURN:		carry set if OK to flush
	
MSG_SOLITAIRE_REDEAL			method
;
;	Begins a new game of solitaire by collecting all the cards,
;	shuffling, redealing, etc.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_SETUP_STANDARD_SCORING	method
;
;	Assigns the correct points to all the decks for standard scoring
;	(see function header to SolitaireSetupStandardScoring for more).
;
;	PASS:		nothing
;
;	RETURN:		nothing


MSG_SOLITAIRE_SETUP_ST_COUNTDOWN	method
MSG_SOLITAIRE_SET_COUNTDOWN_TIME	method
MSG_SOLITAIRE_SET_COUNTDOWN_TIME_AND_REDEAL	method
MSG_SOLITAIRE_USER_REQUESTS_COUNTDOWN_TIME_CHANGE	method
MSG_SOLITAIRE_SETUP_ST_VEGAS	method
;
;	Assigns the correct points to all the decks for vegas scoring
;	(see function header to SolitaireSetupVegasScoring for more).
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_SET_DRAW_NUMBER		method
;
;	Polls the UI gadgetry to determine how many cards the user wants
;	played on each hand selection, and stores this number in the
;	game's instance data.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_SET_FADE_STATUS		method
;
;	Polls the UI gadgetry to determine whether the user wants cards
;	to fade in at various times or not; stores this preference in the
;	game's instance data in the form of fade masks.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_SET_SOUND_STATUS          method
;
;       Checks the UI gadgetry to determine whether the user wants
;       the various game sounds muted and stores this preference in the
;       game's instance data.
;
;	 Pass:		cx = 1 if mute selected, otherwise zero.
;	 Return:	nothing

MSG_SOLITAIRE_SET_RULES		method
;
;	Changes the game's deck objects so that they will accept
;	cards on certain conditions; this has the effect of
;	changing the game rules from, for example, beginner to
;	advanced rules.
;
;	PASS:		cx = DeckDragWhichCards struct for tableau elements
;			dx = DeckDragWhichCards struct for foundations
;
;	RETURN:		nothing

MSG_SOLITAIRE_USER_REQUESTS_SCORING_TYPE_CHANGE	method
MSG_SOLITAIRE_USER_REQUESTS_DRAW_NUMBER_CHANGE		method
MSG_SOLITAIRE_USER_REQUESTS_USER_MODE_CHANGE		method

MSG_SOLITAIRE_SET_SCORING_TYPE_AND_REDEAL		method
MSG_SOLITAIRE_SET_DRAW_NUMBER_AND_REDEAL		method
MSG_SOLITAIRE_SET_USER_MODE_AND_REDEAL			method

MSG_SOLITAIRE_FIXUP_SCORING_TYPE_LIST			method
MSG_SOLITAIRE_FIXUP_DRAW_LIST				method
MSG_SOLITAIRE_FIXUP_USER_MODE_LIST			method

MSG_SOLITAIRE_SET_SCORING_TYPE		method
;
;	Polls the UI gadgetry to determine how the user wants the game
;	to be scored, then sets up that mode.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_SPRAY_DECK		method
;
;	This method tells the game object to instruct one of its decks
;	to do the cool can fan effect with any cards in its composite.
;
;	PASS:		cx = radius of the fan (in screen coordinates)
;			dx = # of deck in composite to spray
;			bp = gstate to spray through
;
;	RETURN:		nothing

MSG_SOLITAIRE_TURN_TIME_OFF		method
;
;	Sets KI_timeStatus to TIME_OFF, disables any active timers,
;	and disables the time displays.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_TURN_TIME_ON		method
;
;	Sets KI_timeStatus to TIME_ON, starts a timer, and enables the
;	time display.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_UNDO			method
;
;	This method undoes the last card transfer, and sets the score
;	to its previous value.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_UPDATE_TIME		method
;
;	Updates the time counter and tells the time display to indicate
;	the change.
;
;	PASS:		cx = # of seconds to add to the time
;
;	RETURN:		nothing

MSG_SOLITAIRE_UPDATE_TIMES_THRU	method
;
;	Updates the number of times the user has gone entirely through
;	the hand.
;
;	PASS:		cx = incremental # of times (probably +1, sometimes
;							-1 for undo)
;
;	RETURN:		nothing

MSG_SOLITAIRE_WE_HAVE_A_WINNER		method
;
;	Records that the game has been won and displays the winning
;	card fan, etc.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_RESET_SCORE		method
;
;	Resets score based on the scoring type.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SOLITAIRE_PLAY_SOUND                method
;
;       Plays a sound if the game sound is not muted.
;
;       PASS:           nothing
;                       Eventually, should be a handle or a constant
;                       that identifies which sound.
;
;       RETURN:         nothing

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									   ;
;			STRUCTURES, ENUMS, ETC.				   ;
;									   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;	ScoringType is the scoring paradigm to be used when playing the
;	game.
;
;	HACK HACK HACK
;
;	Make sure that the list entries in the scoring selection UI are in
;	the same order as here
;
ScoringType	etype	byte
ST_STANDARD_TIMED	enum ScoringType,0
ST_STANDARD_UNTIMED	enum ScoringType,1
ST_VEGAS		enum ScoringType,2
ST_COUNTDOWN		enum ScoringType,3
ST_NONE			enum ScoringType,4

;
;	TimeStatus indicates what state the timer is/should be in
;
TimeStatus	etype	byte
TIME_OFF		enum	TimeStatus,0	;game is not timed
TIME_ON			enum	TimeStatus	;timer is running normally
TIME_PAUSED		enum	TimeStatus	;timer is paused (e.g., when
						;the game is iconified)
TIME_STOPPED		enum	TimeStatus	;timer has been stopped for
						;this game (probably because
						;the user has won).
TIME_EXPIRED		enum	TimeStatus
TIME_NOT_ACTIVE		enum	TimeStatus	;set when solitaire is not
						;running in the foreground
TIME_WAITING_FOR_HOMEBOY_TO_STOP_DRAGGING	enum	TimeStatus

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									   ;
;			VARIABLE DATA					   ;
;									   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ATTR_SOLITAIRE_GAME_OPEN	vardata	byte
; indicates that the game object is open and has not yet been saved
; to state.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									   ;
;			INSTANCE DATA					   ;
;									   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

KI_drawNumber		byte
KI_scoringType		ScoringType
KI_cash			word
KI_totalCountdownTime	word
KI_time			word			;time (in seconds)
KI_countdownTime	word
KI_timerHandle		word
KI_timeStatus		TimeStatus
KI_nTimesThru		word
KI_nFaceDownCardsInTableau	word
KI_muteSound            byte                    ;non-zero to mute sound

SolitaireClass	endc

SolitaireDeckClass      class   DeckClass
SolitaireDeckClass      endc

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
	SolitaireClass
        SolitaireDeckClass

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
;		Code for SolitaireClass
;------------------------------------------------------------------------------
CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireGameSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Solitaire method for MSG_GAME_SAVE_STATE

Called by:	MSG_GAME_SAVE_STATE

Pass:		*ds:si = Solitaire object
		ds:di = Solitaire instance

Return:		^hcx - block of saved data
		dx - # bytes written

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 18, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireGameSaveState	method dynamic	SolitaireClass, MSG_GAME_SAVE_STATE
	uses	bp
	.enter

	mov	ax, 5 * size word

	;
	;  need to alloc N words + 1 (to indicate how many) in the block
	;
;	mov	di, dx
;	mov	bx, cx
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		;returns ax = segment of block
	jc	done
	mov	es, ax				;es:di <- data

	clr	di

	;
	; save our important stuff
	;
	mov	ax, MSG_SOLITAIRE_GET_COUNTDOWN_SECONDS_FROM_UI
	call	ObjCallInstanceNoLock

	mov	si, ds:[si]
	add	si, ds:[si].Solitaire_offset

	mov_tr	ax, cx				;cx <- UI countdown secs
	stosw

	mov	ax, ds:[si].KI_time
	stosw
	mov	ax, ds:[si].KI_countdownTime
	stosw
	mov	ax, ds:[si].KI_nTimesThru
	stosw
	mov	ax, ds:[si].KI_nFaceDownCardsInTableau
	stosw

	call	MemUnlock

	mov	cx, bx
	mov	dx, di

done:
	.leave
	ret
SolitaireGameSaveState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireGameRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Solitaire method for MSG_GAME_RESTORE_STATE

Called by:	MSG_GAME_RESTORE_STATE

Pass:		*ds:si = Solitaire object
		ds:di = Solitaire instance

Return:		^hcx - block of saved data
		dx - # bytes written

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 18, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SolitaireExtraSaveData	struct
	SESD_totalCountdownSecs		word
	SESD_time			word
	SESD_countdownTime		word
	SESD_nTimesThru			word
	SESD_nFaceDownCardsInTableau	word
SolitaireExtraSaveData	ends

SolitaireGameRestoreState	method dynamic	SolitaireClass,
				MSG_GAME_RESTORE_STATE
	uses	bp
	.enter

	;
	;  Read our important stuff out
	;
	mov	bx, cx
	call	MemLock
	jc	done

	mov	es, ax
	clr	di
;	mov	di, dx

	mov	cx, es:[di].SESD_totalCountdownSecs
	mov	ax, MSG_SOLITAIRE_SET_UI_COUNTDOWN_SECONDS
	call	ObjCallInstanceNoLock

	mov	cx, bx
	mov	dx, di
	add	dx, size SolitaireExtraSaveData

	mov	bx, ds:[si]
	add	bx, ds:[bx].Solitaire_offset
	mov	ax, es:[di].SESD_nFaceDownCardsInTableau
	mov	ds:[bx].KI_nFaceDownCardsInTableau, ax
	mov	ax, es:[di].SESD_time
	mov	ds:[bx].KI_time, ax
	mov	ax, es:[di].SESD_countdownTime
	mov	ds:[bx].KI_countdownTime, ax
	mov	ax, es:[di].SESD_totalCountdownSecs
	mov	ds:[bx].KI_totalCountdownTime, ax

	push	cx, dx

	mov	ax, MSG_SOLITAIRE_UPDATE_TIME
	call	ObjCallInstanceNoLock

	pop	cx, dx

	mov	bx, cx
	call	MemUnlock

done:
	.leave
	ret
SolitaireGameRestoreState	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetupStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SETUP_STUFF handler for SolitaireClass
		Does a few things that need to be done before playing the
		first game but do NOT need to be called for subsequent
		games.

CALLED BY:

PASS:		nothing
		
CHANGES:	initializes data slots

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireInitDataFromUI	method	SolitaireClass, MSG_SOLITAIRE_INIT_DATA_FROM_UI

	.enter

	;
	;	Read off the game's state from the menu gadgetry
	;
	mov	ax, MSG_SOLITAIRE_SET_DRAW_NUMBER
	call	ObjCallInstanceNoLock

	mov	ax, MSG_SOLITAIRE_SET_SCORING_TYPE
	call	ObjCallInstanceNoLock

	;
	;	The initial cash is -52, and the MSG_SOLITAIRE_NEW_GAME below
	;	is gonna charge another $52, so counter that here..
	;
	mov	ax, MSG_SOLITAIRE_GET_SCORING_TYPE
	call	ObjCallInstanceNoLock
	cmp	cl, ST_VEGAS
	jne	setUserMode

	clr	cx
	mov	dx, INITIAL_VEGAS_SCORE
	neg	dx
	mov	ax, MSG_GAME_UPDATE_SCORE
	call	ObjCallInstanceNoLock

setUserMode:
	mov	ax, MSG_GAME_SET_USER_MODE
	call	ObjCallInstanceNoLock

if _NDO2000
	mov	ax, MSG_GAME_SET_DRAG_TYPE
	call	ObjCallInstanceNoLock
endif

	mov	ax, MSG_SOLITAIRE_SET_FADE_STATUS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_SOLITAIRE_SET_SOUND_STATUS
	call	ObjCallInstanceNoLock

	.leave
	ret
SolitaireInitDataFromUI	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetupGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SETUP_GEOMETRY handler for SolitaireClass
		Arranges the game's objects according to how big a card
		is (which should give some indication of screen resolution).

PASS:		cx = horizontal deck spacing
		dx = vertical deck spacing

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetupGeometry	method dynamic	SolitaireClass, MSG_GAME_SETUP_GEOMETRY

cardWidth		local	word
cardHeight		local	word

	.enter

	mov	bx, ds:[di].GI_cardWidth
	mov	ss:[cardWidth], bx
	mov	bx, ds:[di].GI_cardHeight
	mov	ss:[cardHeight], bx

	push	cx, dx				;save spacing

	mov	di, offset SolitaireClass
	call	ObjCallSuperNoLock

	pop	ax, di				;ax, di <- deck spacing

	;
	;	Move all the decks to the right places.
	;
	mov	cx, 2
	mov	dx, 2
	mov	bx, handle MyHand
	mov	si, offset MyHand
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle MyTalon
	mov	si, offset MyTalon
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ss:[cardWidth]
	add	cx, ax
	add	cx, ax
	mov	bx, handle Foundation1
	mov	si, offset Foundation1
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Foundation2
	mov	si, offset Foundation2
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Foundation3
	mov	si, offset Foundation3
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle Foundation4
	mov	si, offset Foundation4
	call	SolitairePositionDeck

	mov	cx, 2
	add	dx, ss:[cardHeight]
	add	dx, di
	mov	bx, handle TE1
	mov	si, offset TE1
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle TE2
	mov	si, offset TE2
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle TE3
	mov	si, offset TE3
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle TE4
	mov	si, offset TE4
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle TE5
	mov	si, offset TE5
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle TE6
	mov	si, offset TE6
	call	SolitairePositionDeck

	add	cx, ss:[cardWidth]
	add	cx, ax
	mov	bx, handle TE7
	mov	si, offset TE7
	call	SolitairePositionDeck

	.leave
	ret
SolitaireSetupGeometry	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitairePositionDeck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes a location from card size units to screen units,
		then moves a deck to that point.

CALLED BY:	SolitaireSetupGeometry

PASS:		^lbx:si	= deck to move
		bp,di = width, height units
		cx,dx = left, top position to move to in units of bp, di
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitairePositionDeck	proc	near
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
SolitairePositionDeck	endp	



if _NDO2000
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetDragType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	METHOS_SET_DRAG_TYPE handler for SolitaireClass
		Sets the drag mode to either outline or full dragging

CALLED BY:	

PASS:		cl = DragType
		bp low  = ListEntryState (test for LES_ACTUAL_EXCL)
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		set GI_dragType, then either enable or disable the
		UserModeList, depending on whether we're setting full
		or outline dragging

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetDragType	method	SolitaireClass, MSG_GAME_SET_DRAG_TYPE
	CallObject	DragList, MSG_GEN_ITEM_GROUP_GET_SELECTION, MF_CALL
	mov_tr	cx, ax
	mov	ax, MSG_GAME_SET_DRAG_TYPE
	mov	di, segment SolitaireClass
	mov	es, di
	mov	di, offset SolitaireClass
	call	ObjCallSuperNoLock
	ret
SolitaireSetDragType	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetRules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_SET_RULES handler for SolitaireClass
		Changes the game's deck objects so that they will accept
		cards on certain conditions; this has the effect of
		changing the game rules from, for example, beginner to
		advanced rules.

		CURRENT RULES (12/5/90):

		Beginner:
			* Cards can be moved out of foundations.
			* Face up sequences can be split up to drag

		Intermediate:
			* Cards can not be moved out of foundations
			* Face up sequences can be split up to drag

		Advanced:
			* Cards can not be moved out of foundations
			* Face up sequences can not be split up to drag

CALLED BY:	

PASS:		cx = DeckDragWhichCards structure to pass to tableauElements
		dx = DeckDragWhichcards structure to pass to foundations
		
EXAMPLE:	For BEGINNER_MODE, pass in:

		cx = DDWC_UNTIL_SELECTED
		dx = DDWC_TOP_ONLY

		After the handler is through, the tableau elements will allow
		the user select any of its up cards, and the foundations
		will allow the user to drag their top cards around, which is
		what we expect in BEGINNER_MODE. In contrast, setting up
		ADVANCED_MODE, we would pass:

		cx = DDWC_TOP_OR_UPS
		dx = DDWC_NONE

		Which would make the tableau elements' up cards accessible for
		dragging only as entire groups, and would make the foundations'
		cards unaccessible to dragging.

CHANGES:	all tableauElements get the passed DDWC (OR'd 
		with DA_IGNORE_EXPRESS_DRAG)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		* Combine the DDWC in cx with the "ignore express drag" bit
			and send it to the tableau elements
		* Combine the DDWC in dx with the "ignore double click" bit
			and send it to the foundations

KNOWN BUGS/IDEAS:
		I decided pretty randomly that foundations should not transfer
		cards when double clicked since all this could ever do is
		just move aces around from foundation to foundation. If the
		user REALLY wants to do this, he can damn well drag them around

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetRules	method	SolitaireClass, MSG_SOLITAIRE_SET_RULES
	push	dx

	;
	;	Turn the DDWC into a DeckAttrs
	;
	mov	dx, cx
	mov	cl, offset DA_DDWC
	shl	dx, cl
	ORNF	dx, mask DA_IGNORE_EXPRESS_DRAG
	mov	cx, dx

	;
	;	Ship of the new DeckAtttrs to the tableauElements
	;
	mov	ax, MSG_DECK_SET_ATTRS
	call	CallTableauElements

	;
	;	Turn the DDWC into some DeckAttrs
	;
	pop	dx
	mov	cl, offset DA_DDWC
	shl	dx, cl
	ORNF	dx, mask DA_IGNORE_DOUBLE_CLICKS
	mov	cx, dx

	;
	;	Send the DeckAttrs off to the foundations
	;
	mov	ax, MSG_DECK_SET_ATTRS
	call	CallFoundations
	ret
SolitaireSetRules	endm

CallFoundations	proc	near
	push	ax
	mov	bx, handle Foundation1
	mov	si, offset Foundation1
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	bx, handle Foundation2
	mov	si, offset Foundation2
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	bx, handle Foundation3
	mov	si, offset Foundation3
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	mov	bx, handle Foundation4
	mov	si, offset Foundation4
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
CallFoundations	endp

CallTableauElements	proc	near
	push	ax
	mov	bx, handle TE1
	mov	si, offset TE1
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	bx, handle TE2
	mov	si, offset TE2
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	bx, handle TE3
	mov	si, offset TE3
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	bx, handle TE4
	mov	si, offset TE4
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	bx, handle TE5
	mov	si, offset TE5
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	bx, handle TE6
	mov	si, offset TE6
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	mov	bx, handle TE7
	mov	si, offset TE7
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
CallTableauElements	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetUserMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_USER_MODE handler for SolitaireClass
		Sets the User mode for the game, which in turn causes
		a change in the rules for the decks. See commentation to
		SolitaireSetRules.

CALLED BY:	

PASS:		cl = UserMode
		
CHANGES:	KI_userMode <- cl

RETURN:		nothing

DESTROYED:	cl, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetUserMode	method	SolitaireClass, MSG_GAME_SET_USER_MODE
	;
	;	Get the user mode
	;
	CallObject	UserModeList, MSG_GEN_ITEM_GROUP_GET_SELECTION, MF_CALL
	mov_tr	cx, ax

	mov	di, segment SolitaireClass
	mov	es, di
	mov	di, offset SolitaireClass
	mov	ax, MSG_GAME_SET_USER_MODE
	call	ObjCallSuperNoLock	

	;
	;	Now we'll set the rules by changing the DDWC's of the
	;	tableau elements and the foundations
	;
	mov	bl, cl
	mov	cx, DDWC_TOP_OR_UPS
	mov	dx, DDWC_NONE
	cmp	bl, ADVANCED_MODE
	je	setRules

	mov	cx, DDWC_UNTIL_SELECTED
	cmp	bl, INTERMEDIATE_MODE
	je	setRules

	mov	dx, DDWC_TOP_ONLY
setRules:
	mov	ax, MSG_SOLITAIRE_SET_RULES
	call	ObjCallInstanceNoLock
done::
	ret
SolitaireSetUserMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireGetScoringType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_GET_SCORING_TYPE handler for SolitaireClass
		Returns the scoring mode of the game.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		cl = ScoringType

DESTROYED:	cl, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireGetScoringType	method	SolitaireClass, MSG_SOLITAIRE_GET_SCORING_TYPE
	mov	cl, ds:[di].KI_scoringType
	ret
SolitaireGetScoringType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetScoringType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_SET_SCORING_TYPE handler for SolitaireClass
		Sets the scoring type for the game

CALLED BY:	

PASS:		cl = ScoringType

CHANGES:	KI_scoringType <- cl

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		set scoring type
		if scoring type is ST_NONE, disable score diplays
		else enavle score displays

KNOWN BUGS/IDEAS:
when score displays (or time displays) are enabled, the geometry is
screwed until you resize the window

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetScoringType	method	SolitaireClass, MSG_SOLITAIRE_SET_SCORING_TYPE
	;
	; Get scoring mode
	;
	push	si
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle ScoringList
	mov	si, offset ScoringList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;aX <- excl = ScoringType
	pop	si
	mov_tr	cx, ax

	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	mov	ds:[di].KI_scoringType, cl

	push	si
	mov	ax, MSG_GEN_SET_USABLE
	mov	bx, handle ScoreDisplay
	mov	si, offset ScoreDisplay
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_NOW

	cmp	cl, ST_VEGAS
	jle	hideOrShowDisplay

	mov	ax, MSG_GEN_SET_NOT_USABLE
hideOrShowDisplay:
	call	ObjMessage
	pop	si

CheckHack <ST_STANDARD_TIMED eq 0 >
	mov	ax, MSG_SOLITAIRE_TURN_TIME_ON
	jcxz	startTimer
	mov	ax, MSG_SOLITAIRE_TURN_TIME_OFF
startTimer:
	push	cx
	call	ObjCallInstanceNoLock
	pop	cx
checkStandard::
	cmp	cl, ST_STANDARD_UNTIMED
	mov	ax, MSG_SOLITAIRE_SETUP_STANDARD_SCORING
	jle	setup
	mov	ax, MSG_SOLITAIRE_SETUP_ST_VEGAS
	cmp	cl, ST_VEGAS
	je	setup
	cmp	cl, ST_COUNTDOWN
	jne	done
	mov	ax, MSG_SOLITAIRE_SETUP_ST_COUNTDOWN
setup:
	call	ObjCallInstanceNoLock

done:
	;
	;	Show the new score
	;
	mov	di, ds:[si]
	add	di, ds:[di].Game_offset
	mov	cx, ds:[di].GI_score
	clr	dx
	mov	ax, MSG_GAME_UPDATE_SCORE
	call	ObjCallInstanceNoLock
	ret
SolitaireSetScoringType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetFadeStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_SET_FADE_STATUS handler for SolitaireClass
		turns fading either on or off

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
SolitaireSetFadeStatus	method	SolitaireClass, MSG_SOLITAIRE_SET_FADE_STATUS
	CallObject	FadeList, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS,MF_CALL
	mov	dl, SDM_100			;SDM_100 = no fading
	test	al, 1
	jz	setStatus
	mov	dl, SDM_0			;SDM_0 = full fading
setStatus:
	mov	cl, -4 ; (SDM_12_5 - SDM_0)/2

	;
	;	At this point, 	dl = initial fade mask
	;			cl = incremental fade mask
	;
	mov	ax, MSG_GAME_SET_FADE_PARAMETERS
	call	ObjCallInstanceNoLock
	ret
SolitaireSetFadeStatus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetSoundStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_SET_SOUND_STATUS handler for SolitaireClass
		turns sound either on or off

CALLED BY:	

PASS:		nothing
		
CHANGES:	turns sound on or off

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	2/5/2000	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetSoundStatus	method	SolitaireClass, MSG_SOLITAIRE_SET_SOUND_STATUS

        ; Truly, this is easy.
	CallObject	SoundList, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS,MF_CALL
	PointDi2 Game_offset
	and	al, 1			;filter through mute bit
        mov     ds:[di].KI_muteSound, al
        ret
SolitaireSetSoundStatus endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireTurnTimeOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_TURN_TIME_ON handler for SolitaireClass
		Enables the time display and initializes the timer

CALLED BY:	

PASS:		nothing
		
CHANGES:	KI_timeStatus <- TIME_ON
		A timer is started to send MSG_SOLITAIRE_ONE_SECOND_ELAPSED's
		to MySolitaire every guess-how-often.
				   
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
SolitaireTurnTimeOn	method	SolitaireClass, MSG_SOLITAIRE_TURN_TIME_ON
	mov	ds:[di].KI_timeStatus, TIME_ON

	;
	;	Enable the time display
	;
	mov	dl, VUM_NOW
	CallObject	TimeDisplay, MSG_GEN_SET_USABLE, MF_FIXUP_DS

	;
	;	Set up the timer 'n stuff
	;
	mov	ax, MSG_SOLITAIRE_INITIALIZE_TIME
	GOTO	ObjCallInstanceNoLock
SolitaireTurnTimeOn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireTurnTimeOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_TURN_TIME_OFF handler for SolitaireClass
		Sets KI_timeStatus to TIME_OFF, disables any active timers,
		and disables the time displays.

CALLED BY:	

PASS:		nothing
		
CHANGES:	KI_timeStatus <- TIME_OFF
		KI_timerHandle <- 0
	
		timer that was in KI_timerHandle (if any) is stopped
		time displays are disabled.

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
SolitaireTurnTimeOff	method	SolitaireClass, MSG_SOLITAIRE_TURN_TIME_OFF
	mov	ds:[di].KI_timeStatus, TIME_OFF

	;
	;	If there's a timer going, we need to stop it
	;
	clr	bx
	xchg	bx, ds:[di].KI_timerHandle
	tst	bx
	jz	hideTime
	clr	ax		; 0 => continual
	call	TimerStop
hideTime:
	mov	dl, VUM_NOW
	CallObjectNS	TimeDisplay, MSG_GEN_SET_NOT_USABLE, MF_FIXUP_DS
	ret
SolitaireTurnTimeOff	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireInitializeScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_INITIALIZE_SCORE handler for SolitaireClass
		Figures out what the intial score should be depending on
		the scoring type, then calls MSG_GAME_UPDATE_SCORE

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
SolitaireInitializeScore	method	SolitaireClass, MSG_SOLITAIRE_INITIALIZE_SCORE
	mov	ax, MSG_SOLITAIRE_GET_SCORING_TYPE
	call	ObjCallInstanceNoLock			;cl <- scoring type

	cmp	cl, ST_STANDARD_UNTIMED		;standard scoring?
	jg	notStandard

	mov	ax, MSG_SOLITAIRE_SETUP_STANDARD_SCORING
	call	ObjCallInstanceNoLock

	mov	cx, INITIAL_STANDARD_SCORE
	jmp	init

notStandard:
	cmp	cl, ST_VEGAS			;vegas scoring?
	jne	endSolitaireInitializeScore		;default to no scoring

	mov	ax, MSG_SOLITAIRE_SETUP_ST_VEGAS
	call	ObjCallInstanceNoLock

	clr	cx
init:
	clr	dx
	mov	ax, MSG_GAME_UPDATE_SCORE
	call	ObjCallInstanceNoLock

endSolitaireInitializeScore:
	PointDi2 Deck_offset
	mov	ax, ds:[di].GI_score
	mov	ds:[di].GI_lastScore, ax
	ret
SolitaireInitializeScore	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetupStandardScoring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_SETUP_STANDARD_SCORING handler for SolitaireClass
		Sets up all the decks so that the points they award/penalize
		for etc. correspond to standard scoring.

		CURRENT STANDARD SCORING:
			* Lose 1 point every 10 seconds.
			* For Talon:
				5 point for removing a card
			* For Foundations:
				10 points for adding a card
				-15 points for removing a card
			* For Tableau Elements:
				5 points for flipping a card
			* For returning all the cards from talon to hand:
				10 * (# drawCards) - 40

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
SolitaireSetupStandardScoring	method	SolitaireClass,MSG_SOLITAIRE_SETUP_STANDARD_SCORING
	mov	ds:[di].GI_score, INITIAL_STANDARD_SCORE

if 0
	;
	;	Set current hi score file = vegas
	;
	push	es:[standardHiScoreFile]
	pop	es:[currentHiScoreFile]
	mov	es:[currentHiScoreFileNamePtr], offset standardHiScoreFileName

	;
	;	Set Time high score column usable, score column unusable
	;
	mov	dl, VUM_NOW
	CallObject	HighScoreScoreGroup, MSG_GEN_SET_USABLE, MF_FIXUP_DS
	CallObject	HighScoreTimeGroup, MSG_GEN_SET_USABLE, MF_FIXUP_DS
endif
	;
	;	Set up the hand's score values
	;
	mov	cx, SS_HAND_PUSH
	mov	dx, SS_HAND_POP
	mov	bp, SS_HAND_FLIP
	CallObject	MyHand, MSG_DECK_SET_POINTS, MF_FIXUP_DS

	;
	;	Compute the cost of returning all the cards from the talon
	;	to the hand. Formula is:
	;
	;	10 * (drawCards) - 40
	;
	PointDi2 Game_offset
	clr	ah
	mov	al, ds:[di].KI_drawNumber
	mov	bp, 10
	mul	bp
	sub	ax, 40
	mov	bp, ax
	mov	cx, SS_TALON_PUSH
	mov	dx, SS_TALON_POP
	CallObject	MyTalon, MSG_DECK_SET_POINTS, MF_FIXUP_DS

	;
	;	Set Foundation score values
	;
	mov	cx, SS_FOUNDATION_PUSH
	mov	dx, SS_FOUNDATION_POP
	mov	bp, SS_FOUNDATION_FLIP
	mov	ax, MSG_DECK_SET_POINTS
	call	CallFoundations

	;
	;	Set tableau element score values
	;
	mov	cx, SS_TABLEAU_PUSH
	mov	dx, SS_TABLEAU_POP
	mov	bp, SS_TABLEAU_FLIP
	mov	ax, MSG_DECK_SET_POINTS
	call	CallTableauElements
	ret
SolitaireSetupStandardScoring	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetupVegasScoring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_SETUP_ST_VEGAS handler for SolitaireClass
		Sets up all the decks so that the points they award/penalize
		for etc. correspond to vegas scoring.

		CURRENT VEGAS SCORING:
			* Lose 52 points for each new game
			* Get 5 points for each card played to foundations

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
SolitaireSetupVegasScoring method SolitaireClass,MSG_SOLITAIRE_SETUP_ST_VEGAS
	;
	;	score <- cash
	;
	mov	ds:[di].GI_score, INITIAL_VEGAS_SCORE

if 0
	;
	;	Set current hi score file = vegas
	;
	push	es:[vegasHiScoreFile]
	pop	es:[currentHiScoreFile]
	mov	es:[currentHiScoreFileNamePtr], offset vegasHiScoreFileName

	;
	;	Set Time high score column usable, score column unusable
	;
	mov	dl, VUM_NOW
	CallObject	HighScoreScoreGroup, MSG_GEN_SET_USABLE, MF_FIXUP_DS
	CallObject	HighScoreTimeGroup, MSG_GEN_SET_NOT_USABLE, MF_FIXUP_DS

endif
	mov	cx, VS_HAND_PUSH
	mov	dx, VS_HAND_POP
	mov	bp, VS_HAND_FLIP
	CallObjectNS	MyHand, MSG_DECK_SET_POINTS, MF_FIXUP_DS

	mov	cx, VS_TALON_PUSH
	mov	dx, VS_TALON_POP
	mov	bp, VS_TALON_FLIP
	CallObjectNS	MyTalon, MSG_DECK_SET_POINTS, MF_FIXUP_DS

	mov	cx, VS_FOUNDATION_PUSH
	mov	dx, VS_FOUNDATION_POP
	mov	bp, VS_FOUNDATION_FLIP

	mov	ax, MSG_DECK_SET_POINTS
	call	CallFoundations

	mov	cx, VS_TABLEAU_PUSH
	mov	dx, VS_TABLEAU_POP
	mov	bp, VS_TABLEAU_FLIP

	mov	ax, MSG_DECK_SET_POINTS
	call	CallTableauElements
	ret
SolitaireSetupVegasScoring	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireInitializeTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_INITIALIZE_TIME handler for SolitaireClass
		Clears # of seconds elapsed, stops any existing timers,
		then starts a new one.

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
SolitaireInitializeTime	method	SolitaireClass, MSG_SOLITAIRE_INITIALIZE_TIME
	;
	;	reset the number of seconds
	;
	cmp	ds:[di].KI_scoringType, ST_COUNTDOWN
	jne	checkStandard
	
	mov	ax, ds:[di].KI_countdownTime
	mov	ds:[di].KI_time, ax
	jmp	updateDisplay

checkStandard:
	cmp	ds:[di].KI_scoringType, ST_STANDARD_TIMED
	jne	done

	mov	ax, SS_SECONDS_PER_TAX
	inc	ax						;one more, so
								;that the first
								;tax doesn't
								;occur one
								;second early
	mov	ds:[di].KI_countdownTime, ax
	clr	ds:[di].KI_time					;default to 0
updateDisplay:
	mov	ds:[di].KI_timeStatus, TIME_ON
	mov	ax, MSG_SOLITAIRE_UPDATE_TIME
	call	ObjCallInstanceNoLock

	;
	;	check to see if we already have a timer
	;
	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	mov	cx, ds:[di].KI_timerHandle
	jcxz	startTimer

done:
	ret

startTimer:
	mov	bx, ds:[LMBH_handle]
	mov	al, TIMER_EVENT_CONTINUAL	;Timer Type
	mov	dx, MSG_SOLITAIRE_ONE_SECOND_ELAPSED	;what method to send?
	mov	di, ONE_SECOND			;how often?
	call	TimerStart

	PointDi2 Game_offset
	mov	ds:[di].KI_timerHandle, bx	;keep track of the timer handle
						;so we can shut the damn thing
						;off when needed.
	jmp	done
SolitaireInitializeTime	endm

SolitaireSetCountdownTime	method	SolitaireClass, MSG_SOLITAIRE_SET_COUNTDOWN_TIME

	call	SolitairePauseTimer

	push	si
	mov	bx, handle CountdownBox
	mov	si, offset CountdownBox
	call	UserDoDialog
	pop	si

	call	SolitaireUnpauseTimer

	; edwdig - was IC_APPLY, changed due to dialog type change
	cmp	ax, IC_OK
	jne	cancel

if 0
	mov	ax, MSG_SOLITAIRE_SETUP_ST_COUNTDOWN
	call	ObjCallInstanceNoLock
endif

	mov	cx, ST_COUNTDOWN
	mov	ax, MSG_SOLITAIRE_USER_REQUESTS_SCORING_TYPE_CHANGE
	call	ObjCallInstanceNoLock
done:
	ret
cancel:
	;
	; Need to reset the Minute and Second range objects to original values.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Solitaire_offset
		mov	cx, ds:[di].KI_totalCountdownTime
		mov	ax, MSG_SOLITAIRE_SET_UI_COUNTDOWN_SECONDS
		call	ObjCallInstanceNoLock
	;
	; Need to clear modified state in the Minute and Second range
	; objects so that OK trigger will be enabled if they are changed
	; the next time the dialog is put up.  IC_DISMISS doesn't do this
	; for us.  -- jwu 9/23/93
	;


	; edwdig - not needed anymore since the ok trigger is now
	; always enabled, hence, modified state doesn't matter.
if 0
		mov	ax, MSG_GEN_VALUE_SET_MODIFIED_STATE
		clr 	cx			; set to not modified
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		push	ax, cx, di		; save for SecondRange

		GetResourceHandleNS	MinuteRange, bx
		mov	si, offset MinuteRange
		call	ObjMessage

		pop	ax, cx, di		; msg, params...
		GetResourceHandleNS	SecondRange, bx
		mov	si, offset SecondRange
		call	ObjMessage
endif

	; edwdig - Death can pop up at times when we don't want him to...
	; So, let's just always set him not usable while we're here
		
		GetResourceHandleNS	TooEasyInteraction, bx
		mov	si, offset TooEasyInteraction
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjMessage
		mov	dl, VUM_NOW
		CallObject	CountdownBox, MSG_GEN_RESET_TO_INITIAL_SIZE, MF_FIXUP_DS
		
		jmp	short done
		
SolitaireSetCountdownTime	endm

SolitaireSetupCountdownScoring	method	SolitaireClass, MSG_SOLITAIRE_SETUP_ST_COUNTDOWN

if 0
	;
	;	Set current hi score file = countdown
	;
	push	es:[countdownHiScoreFile]
	pop	es:[currentHiScoreFile]
	mov	es:[currentHiScoreFileNamePtr], offset countdownHiScoreFileName

	;
	;	Set Time high score column usable, score column unusable
	;
	mov	dl, VUM_NOW
	CallObject	HighScoreScoreGroup, MSG_GEN_SET_NOT_USABLE, MF_FIXUP_DS
	CallObject	HighScoreTimeGroup, MSG_GEN_SET_USABLE, MF_FIXUP_DS

endif
	mov	ax, MSG_SOLITAIRE_GET_COUNTDOWN_SECONDS_FROM_UI
	call	ObjCallInstanceNoLock

	jcxz	noTime

	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	mov	ds:[di].KI_countdownTime, cx
	mov	ds:[di].KI_totalCountdownTime, cx

	mov	dl, VUM_NOW
	CallObject	TooEasyInteraction, MSG_GEN_SET_NOT_USABLE, MF_FIXUP_DS
	mov	dl, VUM_NOW
	CallObject	CountdownBox, MSG_GEN_RESET_TO_INITIAL_SIZE, MF_FIXUP_DS
	mov	ax, MSG_SOLITAIRE_INITIALIZE_TIME
	call	ObjCallInstanceNoLock

	mov	ax, MSG_SOLITAIRE_TURN_TIME_ON
	call	ObjCallInstanceNoLock
done:
	ret

noTime:
	mov	dl, VUM_MANUAL
	CallObject	TooEasyInteraction, MSG_GEN_SET_USABLE, MF_FIXUP_DS
	mov	dl, VUM_NOW
	CallObject	CountdownBox, MSG_GEN_RESET_TO_INITIAL_SIZE, MF_FIXUP_DS

	;
	; edwdig
	; Need to reset the Minute and Second range objects to original values.
	; Also need to make sure the timer shows
	;
	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	mov	cx, ds:[di].KI_totalCountdownTime
	mov	ds:[di].KI_countdownTime, cx	
	mov	ax, MSG_SOLITAIRE_SET_UI_COUNTDOWN_SECONDS
	call	ObjCallInstanceNoLock
	mov	ax, MSG_SOLITAIRE_INITIALIZE_TIME
	call	ObjCallInstanceNoLock	
	mov	ax, MSG_SOLITAIRE_TURN_TIME_ON
	call	ObjCallInstanceNoLock	
		
	mov	ax, MSG_SOLITAIRE_SET_COUNTDOWN_TIME
	call	ObjCallInstanceNoLock
	jmp	done
SolitaireSetupCountdownScoring	endm

SolitaireGetCountdownSecondsFromUI	method	SolitaireClass, MSG_SOLITAIRE_GET_COUNTDOWN_SECONDS_FROM_UI
	uses	ax, dx
	.enter
	CallObjectNS	MinuteRange, MSG_GEN_VALUE_GET_VALUE, MF_CALL
	mov	cx, dx
	clr	dx
	mov	ax, 60
	mul	cx
	push	ax
	CallObjectNS	SecondRange, MSG_GEN_VALUE_GET_VALUE, MF_CALL
	pop	ax
	add	dx, ax
	mov	cx, dx
	.leave
	ret
SolitaireGetCountdownSecondsFromUI	endm

SolitaireSetUICountdownSeconds	method	SolitaireClass,
				MSG_SOLITAIRE_SET_UI_COUNTDOWN_SECONDS
	uses	ax, cx, dx, bp
	.enter
	mov_trash	ax, cx
	clr	dx
	mov	cx, 60
	div	cx
	mov_trash	cx, ax
	push	dx
	mov	dx, cx
	clr	cx, bp
	CallObjectNS	MinuteRange, MSG_GEN_VALUE_SET_VALUE, MF_CALL
	pop	dx
	clr	bp, cx
	CallObjectNS	SecondRange, MSG_GEN_VALUE_SET_VALUE, MF_CALL
	.leave
	ret
SolitaireSetUICountdownSeconds	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireOneSecondElapsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_ONE_SECOND_ELAPSED handler for SolitaireClass
		Increments the seconds counter and updates time on the screen.

CALLED BY:	

PASS:		nothing
		
CHANGES:	increments the seconds counter

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
		increment the seconds counter and call MSG_SOLITAIRE_UPDATE_TIME

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireOneSecondElapsed   method  SolitaireClass, MSG_SOLITAIRE_ONE_SECOND_ELAPSED
	;
	;	Check to see whether or not the user has made a move.
	;	If not, disregard the event
	;
	cmp	ds:[di].GI_lastDonor.handle, USER_HASNT_STARTED_PLAYING_YET
	je	done

	cmp	ds:[di].KI_timeStatus, TIME_ON
	jg	done

	mov	ax, -1
	cmp	ds:[di].KI_scoringType, ST_COUNTDOWN
	je	updateTime
	neg	ax
updateTime:
	add	ds:[di].KI_time, ax			;one more second...
	mov	ax, MSG_SOLITAIRE_UPDATE_TIME
	call	ObjCallInstanceNoLock

done:
	ret
SolitaireOneSecondElapsed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireUpdateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the time internally and on screen

CALLED BY:	

PASS:		nothing

CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		sets up score, time then calls TimeToTextObject

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireUpdateTime	method	SolitaireClass, MSG_SOLITAIRE_UPDATE_TIME
	mov	cx, ds:[di].KI_time			;cx <- # seconds

	push	si
	mov	di, handle TimeValue
	mov	si, offset TimeValue
	
	segmov	es, ss
	push	cx					;save time
	call	TimeToTextObject			;write the time
	pop	cx					;cx <- time
	pop	si
	PointDi2 Game_offset
	cmp	ds:[di].GI_lastDonor.handle, USER_HASNT_STARTED_PLAYING_YET
	je	done
	cmp	ds:[di].KI_scoringType, ST_STANDARD_TIMED
	je	checkPenalty
	jcxz	outOfTime
	jmp	done

checkPenalty:
	dec	ds:[di].KI_countdownTime
	jz	penalize
done:
	ret

penalize:
	mov	ds:[di].KI_countdownTime, SS_SECONDS_PER_TAX

	;
	;	Yes, it's time to penalize!!!
	;
	clr	cx
	mov	dx, SS_POINTS_PER_TAX			;if so, tax 'em
	mov	ax, MSG_GAME_UPDATE_SCORE
	call	ObjCallInstanceNoLock
	jmp	done

outOfTime:
	clr	ax
	mov	bx, ax
	xchg	bx, ds:[di].KI_timerHandle
	call	TimerStop

	mov	ds:[di].KI_timeStatus, TIME_WAITING_FOR_HOMEBOY_TO_STOP_DRAGGING
	tst	ds:[di].GI_dragger.handle
	jnz	done

        PLAY_SOUND SS_OUT_OF_TIME	; "user is out of time" sound
	mov	ds:[di].KI_timeStatus, TIME_EXPIRED
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle OutOfTimeBox
	mov	si, offset OutOfTimeBox
	clr	di
	call	ObjMessage
	jmp	done
SolitaireUpdateTime	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireNewGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_NEW_GAME handler for SolitaireClass
		Starts a new game.

CALLED BY:	

PASS:		nothing
		
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
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireNewGame	method	SolitaireClass, MSG_SOLITAIRE_NEW_GAME
	;
	;	If the user has managed to slip in a bunch of
	;	redeal requests, we only want to handle one of them,
	;	so we check to see if this isn't the first...
	;
	test	ds:[di].GI_gameAttrs, mask GA_REDEAL_REQUESTED
	jnz	done

	BitSet	ds:[di].GI_gameAttrs, GA_REDEAL_REQUESTED

	;
	;	To redeal, we need to flush out the fade array, then
	;	send ourselves a method to start a new game.
	;
notRedealingYet::
	mov	ax, MSG_GAME_ZERO_FADE_ARRAY
	call	ObjCallInstanceNoLock

	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	ax, MSG_SOLITAIRE_REDEAL
	call	ObjMessage
done:
	ret
SolitaireNewGame	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireRedeal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_REDEAL handler for SolitaireClass
		Starts a new game of solitaire.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireRedeal	method	SolitaireClass, MSG_SOLITAIRE_REDEAL
	;
	;	Give the user the winner's card back design if he
	;	won the last game
	;
	RESET	ds:[di].GI_gameAttrs, GA_USE_WIN_BACK
	test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
	jz	disableTriggers
	SET	ds:[di].GI_gameAttrs, GA_USE_WIN_BACK

disableTriggers:
	RESET	ds:[di].GI_gameAttrs, GA_JUST_WON_A_GAME
	mov	dl, VUM_NOW
	push	si
	CallObjectNS	RedealTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	CallObjectNS	UndoTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS
	CallObjectNS	MyHand, MSG_DECK_GET_N_CARDS, MF_CALL

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	CallObjectNS	AutoFinishTrigger, MSG_GEN_SET_NOT_USABLE, MF_FIXUP_DS
	CallObjectNS	NewGameTrigger, MSG_GEN_SET_USABLE, MF_FIXUP_DS

	cmp	cx, 52
	je	handHasAllCards

	pop	si
	mov	ax, MSG_GAME_COLLECT_ALL_CARDS
	call	ObjCallInstanceNoLock

	push	si

handHasAllCards:
	CallObjectNS	MyHand, MSG_HAND_SHUFFLE, MF_FORCE_QUEUE
	CallObjectNS	MyPlayingTable, MSG_SOLITAIRE_DEAL, MF_FORCE_QUEUE
	pop	si

	PointDi2 Game_offset
	mov	ds:[di].GI_lastDonor.handle, USER_HASNT_STARTED_PLAYING_YET

	cmp	ds:[di].KI_scoringType, ST_VEGAS
	jne	initScore

	clr	cx
	mov	dx, INITIAL_VEGAS_SCORE
	mov	ax, MSG_GAME_UPDATE_SCORE
	call	ObjCallInstanceNoLock

	jmp	initTime

initScore:
	;
	;	Initialize the score
	;
	mov	ax, MSG_SOLITAIRE_INITIALIZE_SCORE
	call	ObjCallInstanceNoLock

	;
	;	Initialize the time
	;
initTime:
	mov	ax, MSG_SOLITAIRE_INITIALIZE_TIME
	call	ObjCallInstanceNoLock
	ret
SolitaireRedeal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireGetDrawNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_GET_DRAW_NUMBER handler for SolitaireClass

CALLED BY:	

PASS:		nothing
		
CHANGES:	nothing

RETURN:		cl = number of cards to be drawn from the hand each time

DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireGetDrawNumber	method	SolitaireClass, MSG_SOLITAIRE_GET_DRAW_NUMBER
	clr	ch
	mov	cl, ds:[di].KI_drawNumber
	ret
SolitaireGetDrawNumber	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetDrawNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_SET_DRAW_NUMBER handler for SolitaireClass
		Sets the number of cards to draw from the hand each time

CALLED BY:	

PASS:		cl = # to draw
		
CHANGES:	KI_drawNumber <- cl

RETURN:

DESTROYED:	cl, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetDrawNumber	method	SolitaireClass, MSG_SOLITAIRE_SET_DRAW_NUMBER
	CallObject	DrawList, MSG_GEN_ITEM_GROUP_GET_SELECTION, MF_CALL

setNumber::
	mov	di, ds:[si]
	add	di, ds:[di].Game_offset
	mov	ds:[di].KI_drawNumber, al
	cmp	ds:[di].KI_scoringType, ST_STANDARD_UNTIMED
	jg	done

	mov	bp, 10
	mul	bp
	sub	ax, 40
	mov_trash	bp, ax
	mov	cx, SS_TALON_PUSH
	mov	dx, SS_TALON_POP

	CallObjectNS	MyTalon, MSG_DECK_SET_POINTS, MF_FIXUP_DS
done:
	ret
SolitaireSetDrawNumber	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireUnmark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_UNMARK_ACCEPTORS handler for SolitaireClass
		Resets the DA_WANTS_DRAG bit in decks where that
		bit got set in MSG_GAME_MARK_ACCEPTORS and shouldn't have
		been. This happens when the drop card is an ace and
		the top card of the deck is a 2 of opposite color.

CALLED BY:	

PASS:		nothing
		
CHANGES:	may unmark certain decks as acceptors.

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
;
;	The constants (FIRST,LAST)_TABLEAU_ELEMENT represent the child
;	numbers of the first and last tableau elements
;

FIRST_TABLEAU_ELEMENT = 6
LAST_TABLEAU_ELEMENT = 12

SolitaireUnmarkAcceptors	method	SolitaireClass, \
					MSG_GAME_UNMARK_ACCEPTORS
	;
	;	Get the drop card attributes from the dropping deck
	;
	CallObjectCXDX MSG_DECK_GET_DROP_CARD_ATTRIBUTES, MF_CALL

	;
	;	If the user isn't dropping an ace, then there is no
	;	need to unmark anything
	;
	CmpRank	bp, CR_ACE
	jne	endSolitaireUnmark

	mov	dx, FIRST_TABLEAU_ELEMENT

startLoop:
	cmp	dx, LAST_TABLEAU_ELEMENT
	jg	endLoop
	push	dx
	clr	cx
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock		;^lcx:dx = TE

.warn -private
	mov	di, dx
	mov	di, ds:[di]
	add	di, ds:[di].Deck_offset
	RESET	ds:[di].DI_deckAttrs, DA_WANTS_DRAG
.warn @private
	pop	dx
	inc	dx
	jmp	startLoop

endLoop:
endSolitaireUnmark:
	ret
SolitaireUnmarkAcceptors	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeToTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a time string and sets the Text Object to display
		this string.

CALLED BY:	SolitaireUpdateTime

PASS:		ES	= DGroup
		DS	= Relocatable segment
		DI:SI	= Block:chunk of TextObject
		CX	= # of seconds

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	8/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimeToTextObject	proc	near
	uses	di, es
	.enter

	mov	bx, di				; BX:SI is the TextEditObject
	segmov	es, ss, dx			; SS to ES and DX!
	sub	sp, EVEN_DATE_TIME_BUFFER_SIZE	; allocate room on the stack
	mov	bp, sp				; ES:BP => buffer to fill
	mov_tr	ax, cx
	call	WriteTime
	clr	cx				; string is NULL terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; send the method
	add	sp, EVEN_DATE_TIME_BUFFER_SIZE	; restore the stack

	.leave
	ret
TimeToTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_UNDO handler for SolitaireClass
		Undoes the last transfer of cards performed.

CALLED BY:	

PASS:		nothing
		
CHANGES:	undoes last 'move' by returning any cards that
		exchanged ownership

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		calls deck in GI_lastDonor to retrieve the last donation,
		then resets the score to GI_lastScore

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireUndo	method	SolitaireClass, MSG_SOLITAIRE_UNDO
	;
	;	If the game is redealing, or was just won, forget about
	;	undoing anything
	;
	test	ds:[di].GI_gameAttrs, mask GA_REDEAL_REQUESTED
	jnz	endSolitaireUndo
	test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
	jnz	endSolitaireUndo

	PointDi2 Game_offset
	clr	bx
	xchg	bx, ds:[di].GI_lastDonor.handle
	tst	bx
	jz	endSolitaireUndo
getCardsBack::
	push	ds:[di].GI_lastScore
	push	si
	;
	;	Since we're undoing the transfer, we want to clear out the
	;	lastDonor field so it doesn't happen again.
	;
	clr	si
	xchg	si, ds:[di].GI_lastDonor.chunk

	mov	ax, MSG_DECK_RETRIEVE_CARDS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	cmp	si, offset MyTalon
	jne	updateScore
	
	;
	;	The talon is getting some cards back, so disable the
	;	auto finish trigger if need be.
	;
	mov	bx, handle AutoFinishTrigger
	mov	si, offset AutoFinishTrigger
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, handle NewGameTrigger
	mov	si, offset NewGameTrigger
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

updateScore:
	pop	si

	;
	;	Restore the score to what it was before the transfer
	;
	pop	cx
	clr	dx
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	ax, MSG_GAME_UPDATE_SCORE
	call	ObjMessage

	mov	dl, VUM_NOW
	CallObjectNS	UndoTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS

endSolitaireUndo:
	ret
SolitaireUndo	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireUpdateTimesThru
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_UPDATE_TIMES_THRU handler for SolitaireClass
		Updates the number of times the player has gone thru
		the hand.

CALLED BY:	TalonFlush, HandReturnCards

PASS:		cx = incremental amount (probably +1 or -1)
		
CHANGES:	

RETURN:		cx = times thru - draw number

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	9/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireUpdateTimesThru	method	SolitaireClass, MSG_SOLITAIRE_UPDATE_TIMES_THRU
	add	cx, ds:[di].KI_nTimesThru
	mov	ds:[di].KI_nTimesThru, cx
	
	mov	dl, ds:[di].KI_drawNumber
	clr	dh
	sub	cx, dx
	ret
SolitaireUpdateTimesThru	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireQueryFlushOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_QUERY_FLUSH_OK handler for SolitaireClass
		Checks to make sure that the talon hasn't been
		flushed more than the number of cards that are flipped
		each time (under vegas scoring only).

CALLED BY:	

PASS:		nothing
		
CHANGES:	nothing

RETURN:		carry set if ok to flush
		carry clear if not ok to flush

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireQueryFlushOK	method	SolitaireClass, MSG_SOLITAIRE_QUERY_FLUSH_OK
	;
	;	If the game is *not* vegas scoring, then there is never
	;	a time we would want to restrict flushing the talon, so
	;	we just return affirmatively
	;
	cmp	ds:[di].KI_scoringType, ST_VEGAS	;vegas scoring?
	jne	isOkay					;if not, don't worry

	mov	cx, ds:[di].KI_nTimesThru		;cx <- # times thru
	inc	cx
	cmp	cl, ds:[di].KI_drawNumber		;compare the # of
							;flushes already to
							;the number of cards
							;turned each time

	jl	isOkay					;if less, ok

	;
	;	Tell the user that it is NOT ok to flush the talon
	;
	clc
	jmp	endSolitaireQueryFlushOK
isOkay:
	stc
endSolitaireQueryFlushOK:
	ret
SolitaireQueryFlushOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireCheckMinimumScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_CHECK_MINIMUM_SCORE handler for SolitaireClass
		Checks to make sure that a score is not less than the
		minimum score allowed by the game.		

CALLED BY:	

PASS:		cx = score to check
		
CHANGES:	

RETURN:		cx = max(passed score, minimum allowable score)

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireCheckMinimumScore  method  SolitaireClass, MSG_GAME_CHECK_MINIMUM_SCORE
	cmp	ds:[di].KI_scoringType, ST_VEGAS
	je	checkVegas
	cmp	ds:[di].KI_scoringType, ST_STANDARD_UNTIMED
	jg	returnScore
	cmp	cx, SS_MINIMUM_SCORE		;have we gone below minimum
	jge	returnScore			;score? if so, rectify
	mov	cx, SS_MINIMUM_SCORE		;the situation by setting
						;score to the minimum
returnScore:
	ret
checkVegas:
 	cmp	cx, VS_MINIMUM_SCORE
	jge	returnScore
	mov	cx, VS_MINIMUM_SCORE
	jmp	returnScore
SolitaireCheckMinimumScore	endm

SolitaireUpdateScore	method	SolitaireClass, MSG_GAME_UPDATE_SCORE
	mov	di, offset SolitaireClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Game_offset

	cmp	ds:[di].KI_scoringType, ST_VEGAS
	je	vegas
done:
	ret
vegas:
	mov	ax, ds:[di].GI_score
	mov	ds:[di].KI_cash, ax
	jmp	done
SolitaireUpdateScore	endm

if 0
SolitaireCashOut	method	SolitaireClass, MSG_SOLITAIRE_CASH_OUT
	zero	ax, dx
	mov	cx, ds:[di].KI_cash
	tst	cx
	jle	updateScore
	mov	bl, ds:[di].KI_drawNumber
	mov	bh, ds:[di].GI_userMode
	call	HiScoreAddScore

updateScore:
	pushf
	mov	cx, dx				;cx, dx = 0
	mov	ax, MSG_GAME_UPDATE_SCORE
	call	ObjCallInstanceNoLock
	popf

	;
	;	If score made it into high scores, no need to redeal
	;	(done through the summons)
	;
	jc	done

	mov	ax, MSG_SOLITAIRE_REDEAL
	call	ObjCallInstanceNoLock	
done:
	ret
SolitaireCashOut	endm
endif		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireDeal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_DEAL handler for SolitaireClass
		Deals out cards for a new solitaire game

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
	jon	9/90		took this function out of hand.asm
				and put it into solitaire.asm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireDeal	method	SolitaireClass, MSG_SOLITAIRE_DEAL
	;
	;	Get the composite locations of the first and last tableau
	;	elements
	;
	mov	bp, LAST_TABLEAU_ELEMENT
	push	bp

	mov	bp, FIRST_TABLEAU_ELEMENT
	push	bp

startLoop1:
	CallObject	MyHand, MSG_DECK_POP_CARD, MF_CALL
	jnc	gotKid
	jmp	endLoop1	;if no child to pop, end

gotKid:
	CallObjectCXDX	MSG_CARD_TURN_FACE_UP, MF_FIXUP_DS
	pop	bp		;bp <- # of tE to receive face up card
	push	bp
	push	cx,dx		;save card OD
	mov	dx, bp		;dx <- te #
	clr	cx

	;
	;	Get the OD of the tableau element to receive the next card
	;
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock

	;
	;	Give the card to the tableau element
	;
	PLAY_SOUND SS_DEALING	;play the card dealt sound
	mov	bx, cx		;bx <- handle of recipient tableauElement
	mov	bp, dx		;bp <- offset of recipient tableauElement
	pop cx, dx		;restore card OD
	push	si		;save hand offset
	mov	si, bp		;si <- offset of recipient tableauElement
	mov	ax, MSG_DECK_GET_DEALT	;deal card
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si		;restore hand offset

	pop	cx	;number of guy who got the up card
	pop	dx	;number of last TE
	cmp	cx, dx	;done yet?
	jge	endLoop1
	push	cx	;number of guy who got the up card
	push	dx	;number of last TE
	push	cx	;index to use for number of guy to get down card
	
startLoop2:

	pop	cx	;# of te that got last card
	pop	dx	;# of te7
	inc	cx
	cmp	cx,dx	;done yet?
	jg	endLoop2

	push	dx	;push # of te7
	push	cx	;push # of te to receive next card

	CallObject	MyHand, MSG_DECK_POP_CARD, MF_CALL

	jc	endLoop2	;if no child to pop, end

	pop	bp	;bp <- # of te to receive next card
	push	bp
	push	cx,dx	;save card OD
	mov	dx, bp
	clr	cx

	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock

	mov	bx, cx			;bx <- handle of te to receive card
	mov	bp, dx			;bp <- offset of te to receive card
	pop cx, dx			;restore OD of card
	push	si			;save hand offset
	mov	si, bp			;si <- offset of recipient te
	mov	ax, MSG_DECK_GET_DEALT	;deal card
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	jmp	startLoop2
endLoop2:
	;
	; stack should contain only number of TE that got last up card
	;
	pop	cx	; number of TE that got last card
	push	dx	; number of TE7
	inc	cx	;point at next te
	push	cx	;push # of te to receive next card
	jmp	startLoop1
endLoop1:
	PointDi2 Game_offset
	RESET	ds:[di].GI_gameAttrs, GA_REDEAL_REQUESTED
	clr	ds:[di].KI_nTimesThru
	mov	ds:[di].KI_nFaceDownCardsInTableau, 21

	mov	dl, VUM_NOW
	CallObjectNS	RedealTrigger, MSG_GEN_SET_ENABLED, MF_FIXUP_DS
	ret
SolitaireDeal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireHandSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_HAND_SELECTED handler for SolitaireClass
		Instructs the hand object to either turn over more cards
		into the talon, or if the hand is out of cards, to
		get them back from the talon.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireHandSelected	method	SolitaireClass, MSG_GAME_HAND_SELECTED
	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	ax, MSG_TURN_OR_FLUSH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
SolitaireHandSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SHUTDOWN handler for SolitaireClass
		Makes sure that the timer is turned off before
		exiting.

CALLED BY:	

PASS:		nothing
		
CHANGES:	if KI_timerHandle is non-zero, call TimerStop on it

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
SolitaireShutdown	method	SolitaireClass, MSG_GAME_SHUTDOWN
	tst	ds:[di].KI_timerHandle
	jz	callSuper
	clr	bx
	xchg	bx, ds:[di].KI_timerHandle
	clr	ax		; 0 => continual
	call	TimerStop
callSuper:
	mov	di, segment SolitaireClass
	mov	es, di
	mov	di, offset SolitaireClass
	mov	ax, MSG_GAME_SHUTDOWN
	call	ObjCallSuperNoLock
	ret
SolitaireShutdown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetUpSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_UP_SPREADS handler for SolitaireClass
		Sets the visual spreads for Solitaire's decks for
		cards placed on face up cards.

CALLED BY:	

PASS:		dx = vertical displacement
		(horizontal displacement for Solitaire = 0)
		
CHANGES:	

RETURN:		nothing

DESTROYED:	bp, bx

PSEUDO CODE/STRATEGY:
		call SetSpreads after clearing the horizontal component

KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetUpSpreads	method dynamic	SolitaireClass, MSG_GAME_SET_UP_SPREADS
	.enter

	mov	ds:[di].GI_upSpreadX, cx
	mov	ds:[di].GI_upSpreadY, dx

	push	cx					;save horiz spread
	clr	cx					;no horiz up spread

	mov	ax, MSG_DECK_SET_UP_SPREADS

	mov	bx, handle TE1
	mov	si, offset TE1
	clr	di
	call	ObjMessage

	mov	si, offset TE2
	clr	di
	call	ObjMessage

	mov	si, offset TE3
	clr	di
	call	ObjMessage

	mov	si, offset TE4
	clr	di
	call	ObjMessage

	mov	si, offset TE5
	clr	di
	call	ObjMessage

	mov	si, offset TE6
	clr	di
	call	ObjMessage

	mov	si, offset TE7
	clr	di
	call	ObjMessage

	pop	cx					;cx <- horiz spread
	clr	dx
	mov	si, offset MyTalon
	clr	di
	call	ObjMessage

	.leave
	ret
SolitaireSetUpSpreads	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireSetDownSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_DOWN_SPREADS handler for SolitaireClass
		Sets the visual spreads for Solitaire's decks for
		cards placed on face down cards.

CALLED BY:	

PASS:		dx = vertical displacement
		(horizontal displacement for Solitaire = 0)
		
CHANGES:	

RETURN:		nothing

DESTROYED:	bp, bx

PSEUDO CODE/STRATEGY:
		call SetSpreads after clearing the horizontal component

KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetDownSpreads	method	SolitaireClass, MSG_GAME_SET_DOWN_SPREADS
	.enter

	mov	di, offset SolitaireClass
	call	ObjCallSuperNoLock

	clr	cx

	mov	ax, MSG_DECK_SET_DOWN_SPREADS

	mov	bx, handle TE1
	mov	si, offset TE1
	clr	di
	call	ObjMessage

	mov	si, offset TE2
	clr	di
	call	ObjMessage

	mov	si, offset TE3
	clr	di
	call	ObjMessage

	mov	si, offset TE4
	clr	di
	call	ObjMessage

	mov	si, offset TE5
	clr	di
	call	ObjMessage

	mov	si, offset TE6
	clr	di
	call	ObjMessage

	mov	si, offset TE7
	clr	di
	call	ObjMessage

	.leave
	ret
SolitaireSetDownSpreads	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireSetFontSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SET_FONT_SIZE handler for SolitaireClass
		Resizes the text in the status bar to the passed point size.

CALLED BY:	

PASS:		cx = point size
		
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
SolitaireSetFontSize	method	SolitaireClass, MSG_GAME_SET_FONT_SIZE

	mov	dx, size VisTextSetPointSizeParams
	sub	sp, dx
	mov	bp, sp				; structure => SS:BP
	clrdw	ss:[bp].VTSPSP_range.VTR_start
	movdw	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSPSP_pointSize.WWF_frac, 0
	mov	ss:[bp].VTSPSP_pointSize.WWF_int, cx

	CallObjectNS	ScoreLabel, MSG_VIS_TEXT_SET_POINT_SIZE, MF_STACK
	CallObjectNS	ScoreValue, MSG_VIS_TEXT_SET_POINT_SIZE, MF_STACK
	CallObjectNS	TimeLabel, MSG_VIS_TEXT_SET_POINT_SIZE, MF_STACK
	CallObjectNS	TimeValue, MSG_VIS_TEXT_SET_POINT_SIZE, MF_STACK
	add	sp, size VisTextSetPointSizeParams
	ret
SolitaireSetFontSize	endm

if 0	;I hate this damn effect


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireWeHaveAWinner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_WE_HAVE_A_WINNER handler for SolitaireClass
		Creates the lovely card-fan-effect when the game has been won.

CALLED BY:	

PASS:		nothing
		
CHANGES:	stops the game timer (if any)

RETURN:		nothing

DESTROYED:	all

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	;
	;	The following two constants define the amount of "spread"
	;	in the card fan. EFFECTS_ANGLE is the initial angle at which
	;	the fan begins drawing, and EFFECTS_DELTA_ANGLE is the amount
	;	the angle is increased for each new card being drawn
	;
EFFECTS_ANGLE = 28		
EFFECTS_DELTA_ANGLE = 1
FIRST_FOUNDATION = 2
LAST_FOUNDATION = 5
SolitaireWeHaveAWinner	method	SolitaireClass, MSG_SOLITAIRE_WE_HAVE_A_WINNER

	;
	;	Stop the game timer if need be
	;
	cmp	ds:[di].KI_timeStatus, TIME_EXPIRED
	je	createGState
	mov	ds:[di].KI_timeStatus, TIME_STOPPED
	clr	bx
	xchg	bx, ds:[di].KI_timerHandle
	tst	bx
	jz	checkHiScore
	clr	ax		; 0 => continual
	call	TimerStop
checkHiScore:
	mov	bl, ds:[di].KI_drawNumber
	mov	bh, ds:[di].GI_userMode

	cmp	ds:[di].KI_scoringType, ST_STANDARD_UNTIMED
	jg	checkCountDown

	mov	cx, ds:[di].GI_score
	clr	dx
	mov	ax, ds:[di].KI_time
;	call	HiScoreAddScore
	jmp	createGState

checkCountDown:
	cmp	ds:[di].KI_scoringType, ST_COUNTDOWN
	jne	createGState

	;
	;	Calculate a "score" for the countdown time
	;
	;	For now, = 3600 - time
	;
	mov	ax, ds:[di].KI_countdownTime
	mov	cx, 3600
	sub	cx, ax
	clr	dx
;	call	HiScoreAddScore
createGState:
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	;
	;	The fan is rotated about a point 4 card widths from the left
	;	edge of the screen and 800 pixels from the top of the screen,
	;	so we need to translate our gstate origin to that point
	;
	PointDi2 Game_offset
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
	mov	dx, EFFECTS_ANGLE
	call	GrApplyRotation

	mov	bp, di
	pop	cx
	pop	bx
	sub	cx, bx

	;
	;	Now we tell each of the foundations to spray their cards out
	;
	mov	dx, FIRST_FOUNDATION
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SOLITAIRE_SPRAY_DECK
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	mov	dx, FIRST_FOUNDATION + 1
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SOLITAIRE_SPRAY_DECK
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	mov	dx, FIRST_FOUNDATION + 2
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SOLITAIRE_SPRAY_DECK
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	mov	dx, LAST_FOUNDATION
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SOLITAIRE_SPRAY_DECK
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
endSolitaireWeHaveAWinner:
	ret
SolitaireWeHaveAWinner	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireSprayDeck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_SPRAY_DECK handler for SolitaireClass
		Sends a method to the indicated deck instructing it to
		spray out its cards.

CALLED BY:	

PASS:		cx = radius of the fan (in pixels)
		dx = # of child in composite to spray
		bp = gstate to spray through
		
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
SolitaireSprayDeck	method	SolitaireClass, MSG_SOLITAIRE_SPRAY_DECK
	test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
	jz	endSolitaireSprayDeck
	test	ds:[di].GI_gameAttrs, mask GA_REDEAL_REQUESTED or mask GA_ICONIFIED
	jnz	endSolitaireSprayDeck

	;
	;	

	push	cx, bp
	clr	cx
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock
	pop	bx, bp
	xchg	bx, cx
	jc	endSolitaireSprayDeck
	mov	si, dx
	mov	dx, EFFECTS_DELTA_ANGLE
	neg	dx
	mov	ax, MSG_DECK_SPRAY_CARDS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
endSolitaireSprayDeck:
	ret
SolitaireSprayDeck	endm

endif
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SolitaireCheckForWinner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SOLITAIRE_CHECK_FOR_WINNER handler for SolitaireClass
		Checks whether or not the user has won the game yet, and
		if so sends a method to itself to produce the win effect.

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
SolitaireCheckForWinner	method	SolitaireClass, MSG_SOLITAIRE_CHECK_FOR_WINNER
	CallObject	Foundation1, MSG_DECK_GET_N_CARDS, MF_CALL
	cmp	cx, 13
	LONG	jl	noWinner

	CallObject	Foundation2, MSG_DECK_GET_N_CARDS, MF_CALL
	cmp	cx, 13
	LONG	jl	noWinner

	CallObject	Foundation3, MSG_DECK_GET_N_CARDS, MF_CALL
	cmp	cx, 13
	LONG	jl	noWinner

	CallObject	Foundation4, MSG_DECK_GET_N_CARDS, MF_CALL
	cmp	cx, 13
	LONG    jl	noWinner

	mov	di, ds:[si]
	add	di, ds:[di].Game_offset
	test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
	jnz	noWinner
	SET	ds:[di].GI_gameAttrs, GA_JUST_WON_A_GAME
	mov	dl, VUM_NOW
	CallObject	UndoTrigger, MSG_GEN_SET_NOT_ENABLED, MF_FIXUP_DS

;;	call	SolitairePauseTimer
	;
	; Stop the timer because we have a winner.  Can't just
	; pause it or else it will unpause if we are transparently	
	; detached and then restarted.  --jwu 9/28/93
	;
	call	SolitaireStopTimer	

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	CallObject	AutoFinishTrigger, MSG_GEN_SET_NOT_USABLE, MF_FIXUP_DS
	CallObject	NewGameTrigger, MSG_GEN_SET_USABLE, MF_FIXUP_DS

	; Tell the user he/she won.
	;

        PLAY_SOUND SS_GAME_WON	; "user completed a game successfully" sound

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
if 0
	mov	ax, MSG_SOLITAIRE_NEW_GAME
	call	ObjCallInstanceNoLock
;else
	mov	ax, MSG_SOLITAIRE_WE_HAVE_A_WINNER
	call	ObjCallInstanceNoLock
endif
	jmp	done

noWinner:
	mov	di, ds:[si]
	add	di, ds:[di].Game_offset
	cmp	ds:[di].KI_timeStatus, TIME_WAITING_FOR_HOMEBOY_TO_STOP_DRAGGING
	je	outOfTime

done:
	ret

outOfTime:
        PLAY_SOUND SS_OUT_OF_TIME	; "user is out of time" sound
	mov	ds:[di].KI_timeStatus, TIME_EXPIRED
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle OutOfTimeBox
	mov	si, offset OutOfTimeBox
	clr	di
	call	ObjMessage
	jmp	done
SolitaireCheckForWinner	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireSetDonor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_DONOR handler for SolitaireClass
		Checks to see if the game has been won as a result of the
		last card transfer

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		carry set if user has won the game

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetDonor	method	SolitaireClass, MSG_GAME_SET_DONOR
	;
	;	see if the donor is the talon
	;
	cmp	dx, offset MyTalon
	jne	callSuper

	;
	;	It is the talon. Check for any face down cards in the
	;	tableau.
	;	
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SOLITAIRE_CHECK_AUTO_FINISH_ENABLE
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

callSuper:
	;
	;	Call super class
	;
	mov	di, segment SolitaireClass
	mov	es, di
	mov	di, offset SolitaireClass
	mov	ax, MSG_GAME_SET_DONOR
	call	ObjCallSuperNoLock

	;
	;	Queue a MSG_SOLITAIRE_CHECK_FOR_WINNER so that once this transfer
	;	is over, we can see whether or not the user has won.
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SOLITAIRE_CHECK_FOR_WINNER
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
SolitaireSetDonor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireLostSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to pause the timer.

CALLED BY:	MSG_META_LOST_SYS_TARGET_EXCL

PASS:		*ds:si	= SolitaireClass object
		ds:di	= SolitaireClass instance data

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	6/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireLostSysTargetExcl	method dynamic SolitaireClass, 
					MSG_META_LOST_SYS_TARGET_EXCL
	.enter
	;
	;	See if time is on...
	;
	cmp	ds:[di].KI_timeStatus, TIME_ON
	jne	callSuper

	;
	;	If the timer is going, set the time status to TIME_PAUSED
	;	and nuke the timer (it will be restarted in SolitaireVisOpen).
	;

	mov	ds:[di].KI_timeStatus, TIME_NOT_ACTIVE
	clr	bx
	xchg	bx, ds:[di].KI_timerHandle
	tst	bx
	jz	callSuper
	clr	ax		; 0 => continual
	call	TimerStop

callSuper:
	mov	di, segment SolitaireClass
	mov	es, di
	mov	di, offset SolitaireClass
	mov	ax, MSG_META_LOST_SYS_TARGET_EXCL
	call	ObjCallSuperNoLock

	.leave
	ret
SolitaireLostSysTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireGainedSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to Unpause the timer.

CALLED BY:	MSG_META_GAINED_SYS_TARGET_EXCL

PASS:		*ds:si	= SolitaireClass object
		ds:di	= SolitaireClass instance data
		es 	= segment of SolitaireClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	6/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireGainedSysTargetExcl	method dynamic SolitaireClass, 
					MSG_META_GAINED_SYS_TARGET_EXCL
	.enter

	mov	di, offset SolitaireClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	cmp	ds:[di].KI_timeStatus, TIME_NOT_ACTIVE
	jne	done
	
	;
	;	Start the timer
	;
	mov	ds:[di].KI_timeStatus, TIME_ON
	mov	bx, ds:[LMBH_handle]
	mov	al, TIMER_EVENT_CONTINUAL	;Timer Type
	clr	cx				;no delay before starting
	mov	dx, MSG_SOLITAIRE_ONE_SECOND_ELAPSED	;what method to send?
	mov	di, ONE_SECOND			;how often?
	call	TimerStart

	;
	;	Keep the timer handle around so we can stop it later
	;
	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	mov	ds:[di].KI_timerHandle, bx

done:

	.leave
	ret
SolitaireGainedSysTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireLostSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to pause the timer.

CALLED BY:	MSG_META_LOST_SYS_FOCUS_EXCL
PASS:		*ds:si	= SolitaireClass object
		ds:di	= SolitaireClass instance data
		es 	= segment of SolitaireClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	9/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireLostSysFocusExcl	method dynamic SolitaireClass, 
					MSG_META_LOST_SYS_FOCUS_EXCL
	;
	; See if the timer is ticking.
	;
	cmp	ds:[di].KI_timeStatus, TIME_ON
	jne	callSuper

	;
	; If the timer is going, set the time status to TIME_NOT_ACTIVE
	; and nuke the timer.  (The timer will be restarted in 
	; SolitaireGainedSysFocusExcl.)
	;
	mov	ds:[di].KI_timeStatus, TIME_NOT_ACTIVE
	clr	bx
	xchg	bx, ds:[di].KI_timerHandle
	tst	bx
	jz	callSuper
	clr	ax			; 0 => continual timer
	call	TimerStop

callSuper:
	mov	di, offset SolitaireClass
	mov	ax, MSG_META_LOST_SYS_FOCUS_EXCL
	call	ObjCallSuperNoLock
	
	ret

SolitaireLostSysFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireGainedSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to unpausee the timer if needed.

CALLED BY:	MSG_META_GAINED_SYS_FOCUS_EXCL
PASS:		*ds:si	= SolitaireClass object
		es 	= segment of SolitaireClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	9/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireGainedSysFocusExcl	method dynamic SolitaireClass, 
					MSG_META_GAINED_SYS_FOCUS_EXCL
	;
	; Call superclass first.
	;
	mov	di, offset SolitaireClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	cmp	ds:[di].KI_timeStatus, TIME_NOT_ACTIVE
	jne	done
	;	
	; Start the timer.
	;	
	mov	ds:[di].KI_timeStatus, TIME_ON
	mov	bx, ds:[LMBH_handle]
	mov	al, TIMER_EVENT_CONTINUAL	; TimerType
	clr	cx				; no delay before starting
	mov	dx, MSG_SOLITAIRE_ONE_SECOND_ELAPSED	; method to send
	mov	di, ONE_SECOND			; how often?
	call	TimerStart
	
	;
	; Save the timer handle so we can stop it later.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	mov	ds:[di].KI_timerHandle, bx
done:	
	ret
SolitaireGainedSysFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_CLOSE handler for SolitaireClass
		Makes sure that the timer is no longer running before
		the game closes visually.

CALLED BY:	

PASS:		nothing
		
CHANGES:	stops the game timer, if any

RETURN:		nothing

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
		if timer is on, then stop it
		call superclass

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireVisClose	method	SolitaireClass, MSG_VIS_CLOSE
	;
	;	See if time is on...
	;
	cmp	ds:[di].KI_timeStatus, TIME_ON
	jne	callSuper

	;
	;	If the timer is going, set the time status to TIME_PAUSED
	;	and nuke the timer (it will be restarted in SolitaireVisOpen).
	;

	call	SolitairePauseTimer

callSuper:
	mov	di, segment SolitaireClass
	mov	es, di
	mov	di, offset SolitaireClass
	mov	ax, MSG_VIS_CLOSE
	call	ObjCallSuperNoLock
	ret
SolitaireVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireStopTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the timer. 

CALLED BY:	SolitaireCheckForWinner

PASS:		*ds:si - SolitaireClass

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireStopTimer	proc	near
	class	SolitaireClass
	uses	ax,bx,di
	.enter
	
	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	mov	ds:[di].KI_timeStatus, TIME_STOPPED
	clr	bx
	xchg	bx, ds:[di].KI_timerHandle
	tst	bx
	jz	done
	clr	ax		; 0 => continual timer
	call	TimerStop
done:
	.leave
	ret
SolitaireStopTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitairePauseTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Halts the timer

Pass:		*ds:si - SolitaireClass

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 16, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitairePauseTimer	proc	near
	class	SolitaireClass
	uses	ax, bx, di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	cmp	ds:[di].KI_timeStatus, TIME_EXPIRED
	je	pauseNotNeeded
	mov	ds:[di].KI_timeStatus, TIME_PAUSED
pauseNotNeeded:
	clr	bx
	xchg	bx, ds:[di].KI_timerHandle
	tst	bx
	jz	done
	clr	ax		; 0 => continual
	call	TimerStop

done:
	.leave
	ret
SolitairePauseTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireUnpauseTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Unpauses the timer

Pass:		*ds:si - SolitaireClass

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 16, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireUnpauseTimer	proc	near
	class	SolitaireClass
	uses	ax, bx, cx, dx, di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	cmp	ds:[di].KI_timeStatus, TIME_PAUSED
	jne	done
	
	;
	;	Start the timer
	;
	mov	ds:[di].KI_timeStatus, TIME_ON
	mov	bx, ds:[LMBH_handle]
	mov	al, TIMER_EVENT_CONTINUAL	;Timer Type
	clr	cx				;no delay before starting
	mov	dx, MSG_SOLITAIRE_ONE_SECOND_ELAPSED	;what method to send?
	mov	di, ONE_SECOND			;how often?
	call	TimerStart

	;
	;	Keep the timer handle around so we can stop it later
	;
	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	mov	ds:[di].KI_timerHandle, bx

done:
	.leave
	ret
SolitaireUnpauseTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_OPEN handler for SolitaireClass
		Checks to see if we need to restart the game timer if
		it had been previously stopped (in SolitaireVisClose)
		before opening visually.

CALLED BY:	

PASS:		nothing
		
CHANGES:	If the time status is initially TIME_PAUSED, then it
		is changed to TIME_ON and a timer is started.

RETURN:		nothing

DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireVisOpen	method	SolitaireClass, MSG_VIS_OPEN
	mov	di, offset SolitaireClass
	call	ObjCallSuperNoLock

	call	SolitaireUnpauseTimer

	ret
SolitaireVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SolitaireDeckSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_DECK_SELECTED handler for SolitaireClass
		Makes sure the game hasn't been won before letting the
		superclass do its thing. If the game HAS been won, no
		more card dragging should be allowed.

CALLED BY:	

PASS:		^lcx:dx = OD of selected deck
		bp = # of child in composite that was selected
		
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
SolitaireDeckSelected	method	SolitaireClass, MSG_GAME_DECK_SELECTED
	test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
	jnz	done

	mov	di, offset SolitaireClass
	call	ObjCallSuperNoLock
done:
	ret
SolitaireDeckSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireResetScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the score based on the scoring type.

CALLED BY:	MSG_SOLITAIRE_RESET_SCORE

PASS:		*ds:si	= SolitaireClass object
		ds:di	= SolitaireClass instance data

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireResetScore	method dynamic SolitaireClass, 
					MSG_SOLITAIRE_RESET_SCORE
	.enter

	test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
	jz	checkNewGame

	mov	ax, MSG_SOLITAIRE_SET_SCORING_TYPE_AND_REDEAL
	call	ObjCallInstanceNoLock
	jmp	done

checkNewGame:
	cmp	ds:[di].GI_lastDonor.handle, USER_HASNT_STARTED_PLAYING_YET
	jne	gameInProgress

	mov	ax, MSG_SOLITAIRE_SET_SCORING_TYPE
	call	ObjCallInstanceNoLock
done:
	.leave
	ret

gameInProgress:
	cmp	ds:[di].KI_scoringType, ST_NONE
	je	done

	call	SolitairePauseTimer

	push	si
	mov	bx, handle ResetGameConfirmBox
	mov	si, offset ResetGameConfirmBox
	call	UserDoDialog
	pop	si

	call	SolitaireUnpauseTimer

	cmp	ax, IC_YES
	jne	done
	mov	ax, MSG_SOLITAIRE_SET_SCORING_TYPE_AND_REDEAL
	call	ObjCallInstanceNoLock
	jmp	done

SolitaireResetScore	endm


SolitaireNotifyCardFlipped	method	SolitaireClass, MSG_GAME_NOTIFY_CARD_FLIPPED
	dec	ds:[di].KI_nFaceDownCardsInTableau
	ja	done

	mov	ax, MSG_SOLITAIRE_CHECK_AUTO_FINISH_ENABLE
	call	ObjCallInstanceNoLock
done:
	ret
SolitaireNotifyCardFlipped	endm

SolitaireCheckAutoFinishEnable	method	SolitaireClass, MSG_SOLITAIRE_CHECK_AUTO_FINISH_ENABLE
	tst	ds:[di].KI_nFaceDownCardsInTableau
	jnz	done

	mov	bx, handle MyTalon
	mov	si, offset MyTalon
	mov	ax, MSG_DECK_GET_N_CARDS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	tst	cx
	jnz	done

	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	ax, MSG_DECK_GET_N_CARDS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	tst	cx
	jnz	done

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	bx, handle NewGameTrigger
	mov	si, offset NewGameTrigger
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, handle AutoFinishTrigger
	mov	si, offset AutoFinishTrigger
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret
SolitaireCheckAutoFinishEnable	endm

SolitaireAutoFinish	method	SolitaireClass, MSG_SOLITAIRE_AUTO_FINISH

finishLoop:
	mov	bx, handle TE1
	mov	si, offset TE1
	call	DoubleClickIfPossible
	clr	cx				;cx = # of decks with cards
	jnc	tryTE2
	inc	cx
tryTE2:
	push	cx
	mov	bx, handle TE2
	mov	si, offset TE2
	call	DoubleClickIfPossible
	pop	cx
	jnc	tryTE3
	inc	cx
tryTE3:
	push	cx
	mov	bx, handle TE3
	mov	si, offset TE3
	call	DoubleClickIfPossible
	pop	cx
	jnc	tryTE4
	inc	cx
tryTE4:
	push	cx
	mov	bx, handle TE4
	mov	si, offset TE4
	call	DoubleClickIfPossible
	pop	cx
	jnc	tryTE5
	inc	cx
tryTE5:
	push	cx
	mov	bx, handle TE5
	mov	si, offset TE5
	call	DoubleClickIfPossible
	pop	cx
	jnc	tryTE6
	inc	cx
tryTE6:
	push	cx
	mov	bx, handle TE6
	mov	si, offset TE6
	call	DoubleClickIfPossible
	pop	cx
	jnc	tryTE7
	inc	cx
tryTE7:
	push	cx
	mov	bx, handle TE7
	mov	si, offset TE7
	call	DoubleClickIfPossible
	pop	cx
	jc	finishLoop			;if TE7 had a card, loop
	jcxz	done				;if no cards, done
	jmp	finishLoop
done:
	ret
SolitaireAutoFinish	endm
	
DoubleClickIfPossible	proc	near
	mov	ax, MSG_DECK_GET_N_CARDS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	clc
	jcxz	done

	clr	bp
	mov	ax, MSG_DECK_CARD_DOUBLE_CLICKED
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	stc
done:
	ret
DoubleClickIfPossible	endp

SolitaireUserRequestsScoringTypeChange	method	SolitaireClass, MSG_SOLITAIRE_USER_REQUESTS_SCORING_TYPE_CHANGE
	;
	; Set scoring mode
	;
	push	si
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle ScoringList
	mov	si, offset ScoringList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	di, ds:[si]
	add	di, ds:[di].Game_offset
	test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
	jz	checkNewGame

	mov	ax, MSG_SOLITAIRE_SET_SCORING_TYPE_AND_REDEAL
	call	ObjCallInstanceNoLock
	jmp	done

checkNewGame:
	cmp	ds:[di].GI_lastDonor.handle, USER_HASNT_STARTED_PLAYING_YET
	jne	gameInProgress

setAndExit:
	mov	ax, MSG_SOLITAIRE_SET_SCORING_TYPE
	call	ObjCallInstanceNoLock
done:
	ret

gameInProgress:
	cmp	cl, ST_NONE
	je	setAndExit

	call	SolitairePauseTimer

	push	si
	mov	bx, handle ResetGameConfirmBox
	mov	si, offset ResetGameConfirmBox
	call	UserDoDialog
	pop	si

	call	SolitaireUnpauseTimer

	cmp	ax, IC_YES
	mov	ax, MSG_SOLITAIRE_FIXUP_SCORING_TYPE_LIST
	jne	sendMessage
	mov	ax, MSG_SOLITAIRE_SET_SCORING_TYPE_AND_REDEAL
sendMessage:
	call	ObjCallInstanceNoLock
	jmp	done
SolitaireUserRequestsScoringTypeChange	endm
	
SolitaireFixupScoringTypeList	method	SolitaireClass, MSG_SOLITAIRE_FIXUP_SCORING_TYPE_LIST
	mov	cl, ds:[di].KI_scoringType
	clr	ch
	mov	bx, handle ScoringList
	mov	si, offset ScoringList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage
	ret
SolitaireFixupScoringTypeList	endm
		
SolitaireUserRequestsDrawNumberChange	method	SolitaireClass, MSG_SOLITAIRE_USER_REQUESTS_DRAW_NUMBER_CHANGE
	test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
	jz	checkNewGame

	mov	ax, MSG_SOLITAIRE_SET_DRAW_NUMBER_AND_REDEAL
	call	ObjCallInstanceNoLock
	jmp	done

checkNewGame:
	cmp	ds:[di].GI_lastDonor.handle, USER_HASNT_STARTED_PLAYING_YET
	jne	gameInProgress

	mov	ax, MSG_SOLITAIRE_SET_DRAW_NUMBER
	call	ObjCallInstanceNoLock
	jmp	done
gameInProgress:

	call	SolitairePauseTimer

	push	si
	mov	bx, handle ResetGameConfirmBox
	mov	si, offset ResetGameConfirmBox
	call	UserDoDialog
	pop	si

	call	SolitaireUnpauseTimer

	cmp	ax, IC_YES
	mov	ax, MSG_SOLITAIRE_FIXUP_DRAW_LIST
	jne	sendMessage
	mov	ax, MSG_SOLITAIRE_SET_DRAW_NUMBER_AND_REDEAL
sendMessage:
	call	ObjCallInstanceNoLock
done:
	ret
SolitaireUserRequestsDrawNumberChange	endm
	
SolitaireFixupDrawNumberList	method	SolitaireClass, MSG_SOLITAIRE_FIXUP_DRAW_LIST
	mov	cl, ds:[di].KI_drawNumber
	clr	ch

	mov	bx, handle DrawList
	mov	si, offset DrawList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage
	ret
SolitaireFixupDrawNumberList	endm

SolitaireUserRequestsUserModeChange	method	SolitaireClass, MSG_SOLITAIRE_USER_REQUESTS_USER_MODE_CHANGE
	test	ds:[di].GI_gameAttrs, mask GA_JUST_WON_A_GAME
	jz	checkNewGame

	mov	ax, MSG_SOLITAIRE_SET_USER_MODE_AND_REDEAL
	call	ObjCallInstanceNoLock
	jmp	done

checkNewGame:
	cmp	ds:[di].GI_lastDonor.handle, USER_HASNT_STARTED_PLAYING_YET
	jne	gameInProgress

	mov	ax, MSG_GAME_SET_USER_MODE
	call	ObjCallInstanceNoLock
	jmp	done
gameInProgress:

	call	SolitairePauseTimer

	push	si
	mov	bx, handle ResetGameConfirmBox
	mov	si, offset ResetGameConfirmBox
	call	UserDoDialog
	pop	si

	call	SolitaireUnpauseTimer

	cmp	ax, IC_YES
	mov	ax, MSG_SOLITAIRE_FIXUP_USER_MODE_LIST
	jne	sendMessage
	mov	ax, MSG_SOLITAIRE_SET_USER_MODE_AND_REDEAL
sendMessage:
	call	ObjCallInstanceNoLock
done:
	ret
SolitaireUserRequestsUserModeChange	endm
	
SolitaireFixupUserModeList	method	SolitaireClass, MSG_SOLITAIRE_FIXUP_USER_MODE_LIST
	mov	cl, ds:[di].GI_userMode
	clr	ch

	mov	bx, handle UserModeList
	mov	si, offset UserModeList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

	ret
SolitaireFixupUserModeList	endm
		
SolitaireSetScoringTypeAndRedeal	method	SolitaireClass, MSG_SOLITAIRE_SET_SCORING_TYPE_AND_REDEAL
	mov	ax, MSG_SOLITAIRE_SET_SCORING_TYPE
	call	ObjCallInstanceNoLock

	;
	;  If it's vegas, then the new game will cost 52, so clear the
	;  score here
	;

	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	cmp	ds:[di].KI_scoringType, ST_VEGAS
	jne	redealNow

	clr	ds:[di].GI_score

redealNow:
	mov	ax, MSG_SOLITAIRE_NEW_GAME
	call	ObjCallInstanceNoLock
	ret
SolitaireSetScoringTypeAndRedeal	endm

		
SolitaireSetDrawNumberAndRedeal	method	SolitaireClass, MSG_SOLITAIRE_SET_DRAW_NUMBER_AND_REDEAL
	mov	ax, MSG_SOLITAIRE_SET_DRAW_NUMBER
	call	ObjCallInstanceNoLock

	mov	ax, MSG_SOLITAIRE_NEW_GAME
	call	ObjCallInstanceNoLock
	ret
SolitaireSetDrawNumberAndRedeal	endm

		
SolitaireSetUserModeAndRedeal	method	SolitaireClass, MSG_SOLITAIRE_SET_USER_MODE_AND_REDEAL
	mov	ax, MSG_GAME_SET_USER_MODE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_SOLITAIRE_NEW_GAME
	call	ObjCallInstanceNoLock
	ret
SolitaireSetUserModeAndRedeal	endm

SolitaireDroppingDragCards	method	SolitaireClass, MSG_GAME_DROPPING_DRAG_CARDS
	mov	di, offset SolitaireClass
	call	ObjCallSuperNoLock

	jnc	checkWait
done:
	ret

checkWait:
	mov	di, ds:[si]
	add	di, ds:[di].Solitaire_offset
	cmp	ds:[di].KI_timeStatus, TIME_WAITING_FOR_HOMEBOY_TO_STOP_DRAGGING
	clc
	jne	done

	mov	ax, MSG_SOLITAIRE_CHECK_FOR_WINNER
	call	ObjCallInstanceNoLock
	clc
	jmp	done
SolitaireDroppingDragCards	endm	

SolitaireCheckHilites	method	SolitaireClass, MSG_GAME_CHECK_HILITES
	push	cx
	mov	ax, MSG_GAME_GET_USER_MODE
	call	ObjCallInstanceNoLock

	cmp	cl, INTERMEDIATE_MODE
	pop	cx
	jne	done

	mov	di, segment SolitaireClass
	mov	es, di
	mov	di, offset SolitaireClass
	mov	ax, MSG_GAME_CHECK_HILITES
	call	ObjCallSuperNoLock
done:
	ret
SolitaireCheckHilites	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireGameTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Trap the various transfer events to generate sounds

CALLED BY:	

PASS:		*ds:si	= SolitaireClass object
		ds:di	= SolitaireClass instance data

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 2/5/2000        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireGameTransfer	method SolitaireClass, 
        MSG_GAME_TRANSFERRING_CARDS, MSG_GAME_TRANSFER_FAILED
        
        ; We can check the message number to determine whether the transfer
        ; succeeded or failed, and play a different sound for each.

        cmp     ax, MSG_GAME_TRANSFERRING_CARDS
        jne     failed
        PLAY_SOUND SS_CARD_MOVE_FLIP	; "correctly placing a card on another card" sound
        jmp     done
failed:
        PLAY_SOUND SS_DROP_BAD	; "incorrectly placing a card on another card" sound
done:
        ret
SolitaireGameTransfer   endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireDeckFlipCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Trap the TEx decks' flip card event to generate a sound

CALLED BY:	

PASS:		*ds:si	= SolitaireDeckClass object
		ds:di	= SolitaireDeckClass instance data

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 2/5/2000        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireDeckFlipCard   method SolitaireDeckClass, MSG_CARD_FLIP_CARD

        ; Play a sound.
        PLAY_SOUND SS_CARD_MOVE_FLIP	; "flip over a deck card" sound

        ; Then let the super do its work.
        mov     di, offset SolitaireDeckClass
        call    ObjCallSuperNoLock
        ret
SolitaireDeckFlipCard   endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitairePlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Plays a sound if the game sound is not muted.

CALLED BY:	

PASS:           cx = SolitaireSound

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 2/5/2000        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitairePlaySound      method SolitaireClass, MSG_SOLITAIRE_PLAY_SOUND
        uses   ax, bx, cx, dx, di, es

soundToken	local	GeodeToken
        .enter

        tst     ds:[di].KI_muteSound
        jnz     done

	segmov	es, udata, ax

	cmp	cx, SS_DEALING
	jne	cardMoveFlip

	mov	cx, es:[dealingSoundHandle]
	jmp	playFM

cardMoveFlip:
	cmp	cx, SS_CARD_MOVE_FLIP
	jne	dropBad

	mov	cx, es:[cardMoveFlipSoundHandle]
	jmp	playFM

dropBad:
	cmp	cx, SS_DROP_BAD
	jne	outOfTime

	mov	cx, es:[dropBadSoundHandle]
	jmp	playFM

outOfTime:
	cmp	cx, SS_OUT_OF_TIME
	jne	gameWon

	mov	bx, SWIS_OUT_OF_TIME
	jmp	playWav

gameWon:
	cmp	cx, SS_GAME_WON
	jne	default

	mov	bx, SWIS_GAME_WON
	jmp	playWav

playFM:
	;
	; Play an FM sound.
	;
	mov	ax, SST_CUSTOM_SOUND
	call	UserStandardSound
	jmp	done

playWav:
	;
	; Play a WAV sound.
	;

	; Retrieve our GeodeToken.
	segmov	es, ss, ax
	push	bx			; save sound number
	lea	di, soundToken
	mov	bx, handle 0		; bx <- app geode token
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo

	; Play the sound.
	pop	bx			; restore sound number
	mov	cx, es
	mov	dx, di
	call	WavPlayInitSound
	jmp	done

default:
	mov	ax, SST_WARNING
	call	UserStandardSound
done:
        .leave
        ret
SolitairePlaySound      endm

CommonCode	ends		;end of CommonCode resource
