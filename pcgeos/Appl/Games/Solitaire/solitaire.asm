COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Solitaire
FILE:		cards.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	6/90		Initial Version

DESCRIPTION:


RCS STAMP:
$Id: solitaire.asm,v 1.1 97/04/04 15:46:56 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Application		= 1

;Standard include files

include	geos.def
include geode.def
include ec.def
include product.def

;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the solitaire app. is going to
;       be used in a system where all geodes (or most, at any rate)
;       are to be executed out of ROM.  
;------------------------------------------------------------------------------
ifndef FULL_EXECUTE_IN_PLACE
        FULL_EXECUTE_IN_PLACE           equ     FALSE
endif

;------------------------------------------------------------------------------
;  The .GP file only understands defined/not defined;
;  it can not deal with expression evaluation.
;  Thus, for the TRUE/FALSE conditionals, we define
;  GP symbols that _only_ get defined when the
;  condition is true.
;-----------------------------------------------------------------------------
if      FULL_EXECUTE_IN_PLACE
        GP_FULL_EXECUTE_IN_PLACE        equ     TRUE
endif

if FULL_EXECUTE_IN_PLACE
include Internal/xip.def
endif

include solitaireMacros.def

include	library.def
include resource.def
include object.def
include	graphics.def
include gstring.def
include	Objects/winC.def
include heap.def
include lmem.def
include timer.def
include timedate.def
include	system.def
include	file.def
include	fileEnum.def
include	vm.def
include hugearr.def
include Objects/inputC.def
include initfile.def
include	dbase.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------
Strings segment lmem
Strings	ends

UseLib	ui.def
UseLib  cards.def
UseLib	dbase.def
UseLib 		Objects/vTextC.def
UseLib	sound.def
UseLib	wav.def

include solitaireGame.asm
include solitaireHand.asm
include solitaireTalon.asm
;include solitaireHiScore.asm
include	Internal/im.def

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------
SCORE_DISPLAY_BUFFER_SIZE	equ	12	;11 chars for score +
						; null terminator
SHOW_ON_STARTUP			equ	1

;
;	This enum is used to identify which sound to play.
;
SolitaireSound	etype word
SS_DEALING		enum SolitaireSound
SS_OUT_OF_TIME		enum SolitaireSound
SS_GAME_WON		enum SolitaireSound
SS_CARD_MOVE_FLIP	enum SolitaireSound
SS_DROP_BAD		enum SolitaireSound

;
;	This enum matches the values encoded in [sound]/wavDescriptions.
;
SolitaireWavInitSound	etype word
SWIS_OUT_OF_TIME	enum SolitaireWavInitSound
SWIS_GAME_WON		enum SolitaireWavInitSound

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Object Class include files
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;This is the class for this application's process.

SolitaireProcessClass	class	GenProcessClass

SolitaireProcessClass	endc	;end of class definition

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		solitaireSizes.def
include		solitaire.rdef


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

if FULL_EXECUTE_IN_PLACE
SolitaireClassStructures	segment	resource
else
idata	segment
endif

;Class definition is stored in the application's idata resource here.

	SolitaireProcessClass	mask CLASSF_NEVER_SAVED

if FULL_EXECUTE_IN_PLACE
SolitaireClassStructures	ends
else
idata	ends
endif

CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireStartup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_UI_OPEN_APPLICATION handler for SolitaireProcessClass
		Sends the game object a MSG_GAME_SETUP_STUFF which readies
		everything for an exciting session of solitaire!

CALLED BY:	

PASS:		same as superclass
		
CHANGES:	

RETURN:		same as superclass

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireOpenApplication method dynamic	SolitaireProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION
	.enter

	call	SolitaireSetUpSounds

	call	SolitaireSetViewBackgroundColor

	call	SolitaireCheckIfGameIsOpen	; check for the Laserus Case
	jnc	gameNotOpen			; the game isn't open
;gameAlreadyOpen:
	mov	di, segment SolitaireProcessClass
	mov	es, di
	mov	di, offset SolitaireProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock
	jmp	done

gameNotOpen:
	test	cx, mask AAF_RESTORING_FROM_STATE
	jz	startingUp

	push	cx, dx, bp			; save passed values
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_GAME_RESTORE_BITMAPS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp			; restore passed values

	mov	di, segment SolitaireProcessClass
	mov	es, di
	mov	di, offset SolitaireProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock

	jmp	markGameOpen

startingUp:
	push	cx, dx, bp			; save passed values
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_GAME_SETUP_STUFF
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp			; restore passed values

	mov	di, segment SolitaireProcessClass
	mov	es, di
	mov	di, offset SolitaireProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock

	;
	; Check first to see if the user really wants to see a quick tip.
	;
	push	ds
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString	;category
	mov	dx, offset klondikeTipsString		;key
	clr	ax				; assume false
	call	InitFileReadBoolean		; look into the .ini file
	pop	ds
	mov	cx, SHOW_ON_STARTUP		; assume we'll show tips
	tst	ax
	jz	setQuickTipsState		; correct assumtion!
	clr	cx				; nope - no tips
setQuickTipsState:
	push	cx
	mov	bx, handle ShowOnStartupGroup
	mov	si, offset ShowOnStartupGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx
	jcxz	letsPlay			; cx is zero to not show tips

	;
	; show the tips
	;
	mov	bx, handle TipsInteraction
	mov	si, offset TipsInteraction
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;  We're not restoring from state, so we need to create a full
	;  deck and start a new game here
	;
letsPlay:
	CallObject MyHand, MSG_HAND_MAKE_FULL_HAND, MF_FIXUP_DS
	CallObject MyPlayingTable, MSG_SOLITAIRE_INIT_DATA_FROM_UI, MF_FORCE_QUEUE
	CallObject MyPlayingTable, MSG_SOLITAIRE_NEW_GAME, MF_FORCE_QUEUE

	;
	;	Get which card back we're using
	;
	mov	cx, cs
	mov	ds, cx			;DS:SI <- ptr to category string
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeWhichBackString
	call	InitFileReadInteger
	jc	setDefaultBack
	mov_trash	cx, ax				;cx <- which back
	jmp	setBack
setDefaultBack:
	mov	cx, 2					; set default back
setBack:
	mov	ax, MSG_GAME_SET_WHICH_BACK
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	call	ObjMessage


	;
	;	Get the number of cards to flip each time
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeCountdownTimeString
	call	InitFileReadInteger
	jc	nFlipCards
	mov_trash	cx, ax				;cx <- time
	mov	ax, MSG_SOLITAIRE_SET_UI_COUNTDOWN_SECONDS
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	call	ObjMessage

	;
	;	Get the number of cards to flip each time
	;
nFlipCards:
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeDrawHowManyString
	call	InitFileReadInteger
	jc	scoringMode
	mov_trash	cx, ax				;cx <- which back
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle DrawList
	mov	si, offset DrawList
	clr	di
	call	ObjMessage

scoringMode:
	;
	;	Get the scoring mode
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeScoringModeString
	call	InitFileReadInteger
	jc	playLevel
	mov_trash	cx, ax				;cx <- which back
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle ScoringList
	mov	si, offset ScoringList
	clr	di
	call	ObjMessage

playLevel:
	;
	;	Get the play level
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikePlayLevelString
	call	InitFileReadInteger
	jc	dragMode
	mov_trash	cx, ax				;cx <- which back
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle UserModeList
	mov	si, offset UserModeList
	clr	di
	call	ObjMessage

dragMode:
if _NDO2000
	;
	;	See if we should be outline dragging
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeDragModeString
	call	InitFileReadInteger
	jc	getFading
	mov_trash	cx, ax				;cx <- which back
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle DragList
	mov	si, offset DragList
	clr	di
	call	ObjMessage

getFading:
endif
	;
	; Set fading mode.
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString	;category
	mov	dx, offset klondikeFadingString		;key
	call	InitFileReadBoolean		;look into the .ini file
	jc	scoreReset			;value not found, branch

	mov_tr	cx, ax
	clr	dx
	mov	bx, handle FadeList
	mov	si, offset FadeList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE	
	clr	di
	call	ObjMessage

scoreReset:
	;
	; Enable scoring reset trigger?
	;
	segmov	ds, cs, cx
	mov	si, offset klondikeCategoryString	;category
	mov	dx, offset klondikeResetScoreString	;key
	clr	ax				;assume false
	call	InitFileReadBoolean		;look into the .ini file
	tst	ax
	jz	muteSet

	mov	bx, handle ResetScoreTrigger
	mov	si, offset ResetScoreTrigger
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	di
	call	ObjMessage

muteSet:
        ;
        ; Mute the sound?
        ;
        segmov  ds, cs, cx
        mov     si, offset klondikeCategoryString       ;category
        mov     dx, offset klondikeMuteSoundString      ;key
        clr     ax
        call    InitFileReadBoolean
	and	ax, 1			;filter through mute bit
        jz      markGameOpen

	mov_tr	cx, ax
	clr	dx
	mov	bx, handle SoundList
	mov	si, offset SoundList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE	
	clr	di
	call	ObjMessage

markGameOpen:
	call	SolitaireMarkGameOpen

done:
	.leave
	ret
SolitaireOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireCheckIfGameIsOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check if the varData ATTR_SOLITAIRE_GAME_OPEN 
		exists for MyPlayingTable

CALLED BY:	SolitiareOpenApplication

PASS:		nothing

RETURN:		carry set if vardata found
		carry clear if not found

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	7/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireCheckIfGameIsOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size GetVarDataParams
	mov	bp, sp
	mov	ss:[bp].GVDP_dataType, \
		ATTR_SOLITAIRE_GAME_OPEN
	mov	{word} ss:[bp].GVDP_bufferSize, 0
;	clrdw	ss:[bp].GVDP_buffer
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_META_GET_VAR_DATA
	mov	dx, size GetVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size GetVarDataParams
	cmp	ax, -1				; check if not found
	stc
	jne	varDataFound
;varDataNotFound:
	clc
varDataFound:

	.leave
	ret
SolitaireCheckIfGameIsOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireMarkGameOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will add the varData ATTR_SOLITAIRE_GAME_OPEN to
		MyPlayingTable

CALLED BY:	SolitaireOpenApplication

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	7/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireMarkGameOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size AddVarDataParams
	mov	bp, sp
	mov	ss:[bp].AVDP_dataType, \
		ATTR_SOLITAIRE_GAME_OPEN
	mov	{word} ss:[bp].AVDP_dataSize, size byte
	clrdw	ss:[bp].AVDP_data
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams

	.leave
	ret
SolitaireMarkGameOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireSetViewBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the background color of the view to green if on	
		a color display, white if on a black and white
		display, and gray if on a TV

CALLED BY:	SolitaireOpenApplication

PASS:		

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
	srs	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSetViewBackgroundColor		proc	near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	;    Use VUP_QUERY to field to avoid building GenApp object.
	;

        mov     bx, segment GenFieldClass
        mov     si, offset GenFieldClass
        mov     ax, MSG_VIS_VUP_QUERY
        mov     cx, VUQ_DISPLAY_SCHEME          ; get display scheme
        mov     di, mask MF_RECORD
        call    ObjMessage                      ; di = event handle
        mov     cx, di                          ; cx = event handle
        mov     bx, handle SolitaireApp
        mov     si, offset SolitaireApp
        mov     ax, MSG_GEN_CALL_PARENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
        call    ObjMessage	          ; ah = display type, bp = ptsize

	mov	cl, C_GREEN			;assume color display
	mov	al, ah				; save for second test
	and 	ah, mask DT_DISP_CLASS
	cmp	ah, DC_GRAY_1 shl offset DT_DISP_CLASS
	jne	testTV
	mov	cl,C_WHITE
	jmp	short setColor

testTV:
	and	al, mask DT_DISP_ASPECT_RATIO
	cmp	al, DAR_TV shl offset DT_DISP_ASPECT_RATIO
	jne	setColor
	mov	cl, C_LIGHT_GRAY
	
setColor:
	mov	ch, CF_INDEX or (CMT_DITHER shl offset  CMM_MAP_TYPE)
	mov	bx,handle SolitaireView
	mov	si,offset SolitaireView
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_VIEW_SET_COLOR
	call	ObjMessage

	.leave
	ret
SolitaireSetViewBackgroundColor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireRestoreFromState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a message to the game object telling it that we are
		restoring from state.

CALLED BY:	GLOBAL
PASS:		es - dgroup
RETURN:		nada
DESTROYED:	Whatever our superclass destroys
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireRestoreFromState	method	SolitaireProcessClass,
				MSG_GEN_PROCESS_RESTORE_FROM_STATE

	push	cx, dx, bp			; save passed values
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	cx, bp
	mov	ax, MSG_GAME_RESTORE_STATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp			; restore passed values

	mov	di, segment SolitaireProcessClass
	mov	es, di
	mov	di,  offset SolitaireProcessClass
	mov	ax, MSG_GEN_PROCESS_RESTORE_FROM_STATE
	GOTO	ObjCallSuperNoLock
SolitaireRestoreFromState	endm


SolitaireShutDown	method	SolitaireProcessClass,
			MSG_GEN_PROCESS_CLOSE_APPLICATION
	.enter

	;
	;	Save quick tips setting
	;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	bx, handle ShowOnStartupGroup
	mov	si, offset ShowOnStartupGroup
	mov	di, mask MF_CALL
	call	ObjMessage
	and	ax, SHOW_ON_STARTUP	; filter out other garbage
	xor	ax, SHOW_ON_STARTUP	; setting TRUE if checkbox CLEARED

	push	ds
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeTipsString
	call	InitFileWriteBoolean
	call	InitFileCommit
	pop	ds

	mov	ax, MSG_GAME_SAVE_STATE
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	push	cx			;save block
	
;	mov	bx, handle MyPlayingTable
;	mov	si, offset MyPlayingTable
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_GAME_SHUTDOWN
	call	ObjMessage

	mov	di, segment SolitaireProcessClass
	mov	es, di
	mov	di, offset SolitaireProcessClass
	mov	ax, MSG_GEN_PROCESS_CLOSE_APPLICATION
	call	ObjCallSuperNoLock

	pop	cx

	.leave
	ret
SolitaireShutDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KlondikeSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine saves the current settings of the options menu
		to the .ini file.

CALLED BY:	GLOBAL
PASS:		es - idata
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SolitaireSaveOptions	method	SolitaireProcessClass, MSG_META_SAVE_OPTIONS

	;
	; Save countdown seconds
	;
	mov	ax, MSG_SOLITAIRE_GET_COUNTDOWN_SECONDS_FROM_UI
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage		;CX <- starting level

	mov	bp, cx			;BP <- value
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeCountdownTimeString
	call	InitFileWriteInteger

	;
	; Save which back
	;
	mov	ax, MSG_GAME_GET_WHICH_BACK
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage		;CX <- starting level

	mov	bp, cx			;BP <- value
	mov	cx, cs
	mov	ds, cx
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeWhichBackString
	call	InitFileWriteInteger

	;
	; Save the number of cards to flip each time
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle DrawList
	mov	si, offset DrawList
	mov	di, mask MF_CALL
	call	ObjMessage		;aX <- starting level

	mov_tr	bp, ax			;BP <- value
	mov	cx, ds
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeDrawHowManyString
	call	InitFileWriteInteger

	;
	; Save scoring mode
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle ScoringList
	mov	si, offset ScoringList
	mov	di, mask MF_CALL
	call	ObjMessage		;aX <- starting level

	mov_tr	bp, ax			;BP <- value
	mov	cx, ds
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeScoringModeString
	call	InitFileWriteInteger

	;
	; Save the play level
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle UserModeList
	mov	si, offset UserModeList
	mov	di, mask MF_CALL
	call	ObjMessage
   
	mov_tr	bp, ax
	mov	cx, ds
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikePlayLevelString
	call	InitFileWriteInteger

if _NDO2000
	;
	; Save the drag mode
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle DragList
	mov	si, offset DragList
	mov	di, mask MF_CALL
	call	ObjMessage
   
	mov_tr	bp, ax
	mov	cx, ds
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeDragModeString
	call	InitFileWriteInteger
endif

	;
	;	Save fade mode
	;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	bx, handle FadeList
	mov	si, offset FadeList
	mov	di, mask MF_CALL
	call	ObjMessage		;LES_ACTUAL_EXCL set if on...
	and	ax, 1			;filter through fade bit
	mov	cx, ds
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeFadingString
	call	InitFileWriteBoolean

        ;
        ; Save mute sound
        ;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	bx, handle SoundList
	mov	si, offset SoundList
	mov	di, mask MF_CALL
	call	ObjMessage		;LES_ACTUAL_EXCL set if on...
	and	ax, 1			;filter through mute bit
	mov	cx, ds
	mov	si, offset klondikeCategoryString
	mov	dx, offset klondikeMuteSoundString
	call	InitFileWriteBoolean

	call	InitFileCommit
	ret
SolitaireSaveOptions	endm

klondikeCategoryString		char	"klondike",0
klondikeWhichBackString		char	"whichBack",0
klondikeDrawHowManyString	char	"drawHowManyCards",0
klondikeScoringModeString	char	"scoringMode",0
klondikePlayLevelString		char	"playLevel",0
if _NDO2000
klondikeDragModeString		char	"dragMode",0
endif
klondikeFadingString		char	"fadeCards",0
klondikeCountdownTimeString	char	"countdown",0
klondikeResetScoreString	char	"resetScore",0
klondikeMuteSoundString         char    "muteSound",0
klondikeTipsString         char    "noShowTips",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolitaireSetUpSounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create Sound Handles for sounds

CALLED BY:	OpenApplication
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Initializes handles in udata.

PSEUDO CODE/STRATEGY:
		Call SoundAllocNote for all the sounds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	DH	2/29/2000	Stolen from Tetris

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
udata		segment
	dealingSoundHandle		word
if 0
	outOfTimeSoundHandle		word
	gameWonSoundHandle		word
endif
	cardMoveFlipSoundHandle		word
	dropBadSoundHandle		word
udata		ends

ONE_VOICE = 1
THREE_VOICES = 3

DealingSoundBuffer	segment	resource
	SimpleSoundHeader	ONE_VOICE

		ChangeEnvelope	0, IP_BASS_DRUM_1
		General		GE_SET_PRIORITY
		word		SP_GAME
		VoiceOn		0, FR_BASS_DRUM_1, DYNAMIC_F
		DeltaTick	5
		VoiceOff	0
		General		GE_END_OF_SONG

DealingSoundBuffer		ends

if 0
OutOfTimeSoundBuffer		segment	resource
	SimpleSoundHeader	ONE_VOICE

		ChangeEnvelope	0, IP_ACOUSTIC_GRAND_PIANO
		General		GE_SET_PRIORITY
		word		SP_GAME
		VoiceOn		0, MIDDLE_C_SH, DYNAMIC_F
		DeltaTick	3
		VoiceOff	0
		VoiceOn		0, MIDDLE_C_SH, DYNAMIC_F
		DeltaTick	3
		VoiceOff	0

		General		GE_END_OF_SONG

OutOfTimeSoundBuffer		ends

GameWonSoundBuffer		segment	resource
	SimpleSoundHeader	ONE_VOICE

		ChangeEnvelope	0, IP_ACOUSTIC_GRAND_PIANO
		General		GE_SET_PRIORITY
		word		SP_GAME
		DeltaTick	1
		VoiceOn		0, MIDDLE_C, DYNAMIC_F
		DeltaTick	1
		VoiceOff	0
		General		GE_END_OF_SONG

GameWonSoundBuffer		ends
endif

CardMoveFlipSoundBuffer		segment	resource
	SimpleSoundHeader	ONE_VOICE

		ChangeEnvelope	0, IP_SHAKUHACHI
		General		GE_SET_PRIORITY
		word		SP_GAME
		VoiceOn		0, HIGH_B, DYNAMIC_F
		DeltaTick	3
		VoiceOff	0
		General		GE_END_OF_SONG

CardMoveFlipSoundBuffer		ends

DropBadSoundBuffer	segment	resource
	SimpleSoundHeader	THREE_VOICES

		ChangeEnvelope	0, IP_ORCHESTRA_HIT
		ChangeEnvelope	1, IP_ORCHESTRA_HIT
		ChangeEnvelope	2, IP_ORCHESTRA_HIT
		General		GE_SET_PRIORITY
		word		SP_GAME
		VoiceOn		0, MIDDLE_F_SH, DYNAMIC_MF
		VoiceOn		1, MIDDLE_A_SH, DYNAMIC_MF
		VoiceOn		2, HIGH_C, DYNAMIC_MF
		DeltaTick	10
		VoiceOff	0
		VoiceOff	1
		VoiceOff	2
		General		GE_END_OF_SONG

DropBadSoundBuffer		ends

SolitaireSetUpSounds	proc	near
	uses	ax, bx, cx, dx, si, di, ds
	.enter
	segmov	ds, udata, ax

	;
	;  Allocate a sound handle so we can tick when each card is dealt in
	;  the startup dealing sequence
	mov	cx, 1
	mov	bx, handle DealingSoundBuffer
	call	SoundInitMusic

	mov	ds:[dealingSoundHandle], bx

	;
	;  Set us up as the owner
	mov_tr	ax, bx
	call	GeodeGetProcessHandle
	xchg	ax, bx			;AX <- process handle
					;BX <- sound handle
	call	SoundChangeOwner

if 0
	;
	;  Allocate a sound handle so we can make a noise
	;  when the game is over because time ran out
	mov	cx, 1
	mov	bx, handle OutOfTimeSoundBuffer
	call	SoundInitMusic

	mov	ds:[outOfTimeSoundHandle], bx

	;
	;  Set us up as the owner
	mov_tr	ax, bx
	call	GeodeGetProcessHandle
	xchg	ax, bx
	call	SoundChangeOwner

	;
	;  Allocate a sound handle so we can make a noise
	;  when the game is won
	mov	cx, 1
	mov	bx, handle GameWonSoundBuffer
	call	SoundInitMusic

	mov	ds:[gameWonSoundHandle], bx

	;
	;  Set us up as the owner

	mov_tr	ax, bx
	call	GeodeGetProcessHandle
	xchg	ax, bx
	call	SoundChangeOwner
endif

	;
	;  Allocate a sound handle so we can make a noise
	;  when one or move cards are moved or flipped
	mov	cx, 1
	mov	bx, handle CardMoveFlipSoundBuffer
	call	SoundInitMusic

	mov	ds:[cardMoveFlipSoundHandle], bx

	;
	;  Set us up as the owner

	mov_tr	ax, bx
	call	GeodeGetProcessHandle
	xchg	ax, bx
	call	SoundChangeOwner

	;
	;  Allocate a sound handle so we can make a noise
	;  when one or more cards are dropped in an illegal place
	mov	cx, THREE_VOICES
	mov	bx, handle DropBadSoundBuffer
	call	SoundInitMusic

	mov	ds:[dropBadSoundHandle], bx

	;
	;  Set us up as the owner

	mov_tr	ax, bx
	call	GeodeGetProcessHandle
	xchg	ax, bx
	call	SoundChangeOwner


	.leave
	ret
SolitaireSetUpSounds	endp


CommonCode	ends		;end of CommonCode resource
