COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWorks Poker
FILE:		gwpoker.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	12/90		Initial Version
	bchow	2 /93		2.0 update

DESCRIPTION:


RCS STAMP:
	$Id: gwpoker.asm,v 1.1 97/04/04 15:19:57 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Application		= 1

;Standard include files

include	geos.def
include geode.def
include ec.def

include myMacros.def

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

UseLib	ui.def
UseLib	sound.def
UseLib	game.def
UseLib	cards.def
UseLib	dbase.def
UseLib	wav.def

;    Don't enable both of these at once

WAV_SOUND  equ 0
STANDARD_SOUND equ 1

;   This enables/disables code to allow setting of card fading. The ui
;   must be uncommented/commented in bjack.ui also.

FADING = 0


include pokerGame.asm
include payoffDisplay.asm
include pokerSound.asm

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------
	SCORE_DISPLAY_BUFFER_SIZE	equ	12	;11 chars for score +
							; null terminator


if 	STANDARD_SOUND

	; Notes

;	WHOLE		equ	48
;	HALF		equ	WHOLE/2
	HALF_D		equ	HALF * 3/2
;	QUARTER		equ	WHOLE/4
	QUARTER_D	equ	QUARTER * 3/2
;	EIGHTH		equ	QUARTER/2

endif

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

PokerProcessClass	class	GenProcessClass

MSG_ADD			message

MSG_POKER_SAVE_OPTIONS	message

PokerProcessClass	endc	;end of class definition

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		sizes.def

include		gwpoker.rdef


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

;Class definition is stored in the application's idata resource here.

	PokerProcessClass	mask CLASSF_NEVER_SAVED

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment
	
udata	ends

;------------------------------------------------------------------------------
;		Code for PokerProcessClass
;------------------------------------------------------------------------------
CommonCode	segment	resource	;start of code resource

PokerStartUp	method	PokerProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION

	call	PokerSetViewBackgroundColor

	;    If the game is already open then we started to exit
	;    but were started backup. All the ui objects should still
	;    be in place. So just call the super class. Note -
	;    the AAF_RESTORING_FROM_STATE bit will be set in this 
	;    case even though we aren't coming back from state, so 
	;    checking for being open must come before checking the
	;    bit.
	;

	call	PokerCheckIfGameIsOpen
	jc	callSuper

	test	cx, mask AAF_RESTORING_FROM_STATE
	jz	startingUp

	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_GAME_RESTORE_BITMAPS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

callSuper:
	mov	di, offset PokerProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock

setupSounds:
	
if	STANDARD_SOUND

	;   Under any circumstances that we receive 
	;   MSG_GEN_PROCESS_OPEN_APPLICATION the sound buffers will
	;   need to be created.
	;

	CallMod	SoundSetupSounds
endif

	;    Mark the game as open so that we can detect the lazarus
	;    situation.
	;

	call	PokerMarkGameOpen

	ret

startingUp:
	call	PokerMakeSureTokenIsInstalled

	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_GAME_SETUP_STUFF
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	di, offset PokerProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock

	;
	;	We're not restoring from state, so we need to create a full
	;	deck and start a new game here
	;
	;	Instantiate a full deck of cards,including 2 jokers
	;
	CallObject MyHand, MSG_HAND_MAKE_FULL_HAND, MF_FIXUP_DS
	CallObject MyPlayingTable, MSG_ADD_JOKER, MF_FIXUP_DS
	CallObject MyPlayingTable, MSG_ADD_JOKER, MF_FIXUP_DS

	;
	;	Get which card back we're using
	;
	mov	cx, cs
	mov	ds, cx			;DS:SI <- ptr to category string
	mov	si, offset pokerCategoryString
	mov	dx, offset pokerWhichBackString
	call	InitFileReadInteger
	jc	wild
	mov_trash	cx, ax				;cx <- which back
	mov	ax, MSG_GAME_SET_WHICH_BACK
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	call	ObjMessage

wild:
	;
	;	Get the wild choice
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset pokerCategoryString
	mov	dx, offset pokerWildString
	call	InitFileReadInteger
	jc	getPlayTune
	mov_trash	cx, ax				;cx <- wild
	clr	dx					;indeterminate ones
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle WildList
	mov	si, offset WildList
	clr	di
	call	ObjMessage

getPlayTune:
	;
	; Set sound setting
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset pokerCategoryString		;category
	mov	dx, offset pokerPlayTuneString		;key
	call	InitFileReadInteger			;look into the .ini file
	jc	getFading
	mov_trash	cx, ax				;cx <- which back
	mov	dx, 0					;not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle SoundList
	mov	si, offset SoundList
	clr	di
	call	ObjMessage


getFading:
if	FADING

	;
	; Set fading mode.
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset pokerCategoryString		;category
	mov	dx, offset pokerFadingString		;key
	call	InitFileReadBoolean			;look into the .ini file
	jc	initScore
	mov_trash	cx, ax				;dx = boolean Fade
	clr	dx					;indeterminate ones
	mov	bx, handle FadeList
	mov	si, offset FadeList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage

initScore:
endif
	;
	;	Initialize the score and wager fields if not restoring from
	;	state.
	;
	mov	cx, INITIAL_CASH
	CallObject	MyPlayingTable, MSG_GAME_UPDATE_SCORE, MF_FORCE_QUEUE

	mov	cx, INITIAL_WAGER
	clr	dx
	CallObject	MyPlayingTable, MSG_ADJUST_WAGER_AND_CASH, MF_FORCE_QUEUE

	clr	cx
	clr	dx
	CallObject	MyPlayingTable, MSG_SHOW_WINNINGS, MF_FORCE_QUEUE

	;
	;	Read the UI to see whether or not we want wild cards to
	;	show up while playing
	;
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	mov	ax, MSG_SET_WILD
	call	ObjMessage

	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	mov	ax, MSG_SOLITAIRE_SET_FADE_STATUS
	call	ObjMessage

	jmp	setupSounds

PokerStartUp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerCheckIfGameIsOpen
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
PokerCheckIfGameIsOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size GetVarDataParams
	mov	bp, sp
	mov	ss:[bp].GVDP_dataType, \
		ATTR_POKER_GAME_OPEN
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
PokerCheckIfGameIsOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerMarkGameOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will add the varData ATTR_SOLITAIRE_GAME_OPEN to
		MyPlayingTable

CALLED BY:	PokerOpenApplication

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
PokerMarkGameOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size AddVarDataParams
	mov	bp, sp
	mov	ss:[bp].AVDP_dataType, \
		ATTR_POKER_GAME_OPEN
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
PokerMarkGameOpen	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerMakeSureTokenIsInstalled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The zoomer doesn't force applications to install their tokens. 
		So we must do it ourselves

CALLED BY:	INTERNAL
		GWPokerStartUp

PASS:		*ds:si - GWPokerProcessClass

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
	srs	8/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PokerMakeSureTokenIsInstalled		proc	near
	uses	ax,bx,cx,dx,bp,si,di
	.enter

	mov	bx,handle PokerApp
	mov	si,offset PokerApp
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_APPLICATION_INSTALL_TOKEN
	call	ObjMessage

	.leave
	ret
PokerMakeSureTokenIsInstalled		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokerSetViewBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the background color of the view to green if on	
		a color display and white if on a black and white
		display

CALLED BY:	PokerOpenApplication

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
PokerSetViewBackgroundColor		proc	near
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
        mov     bx, handle PokerApp
        mov     si, offset PokerApp
        mov     ax, MSG_GEN_CALL_PARENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
        call    ObjMessage	          ; ah = display type, bp = ptsize

	mov	cl, C_GREEN			;assume color display
	and 	ah, mask DT_DISP_CLASS
	cmp	ah, DC_GRAY_1 shl offset DT_DISP_CLASS
	jne	setColor
	mov	cl,C_WHITE
setColor:
	mov	ch, CF_INDEX or (CMT_DITHER shl offset  CMM_MAP_TYPE)
	mov	bx,handle PokerView
	mov	si,offset PokerView
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_VIEW_SET_COLOR
	call	ObjMessage

	mov	ch, CF_INDEX
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle InstructionDisplay
	mov	si,offset InstructionDisplay
	mov	ax,MSG_VIS_TEXT_SET_WASH_COLOR
	call	ObjMessage

	mov	di,mask MF_FIXUP_DS
	mov	bx,handle Instruction2Display
	mov	si,offset Instruction2Display
	call	ObjMessage

	mov	di,mask MF_FIXUP_DS
	mov	bx,handle FiveOfAKindDisplay
	mov	si,offset FiveOfAKindDisplay
	call	ObjMessage
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle StraightFlushDisplay
	mov	si,offset StraightFlushDisplay
	call	ObjMessage
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle FourOfAKindDisplay
	mov	si,offset FourOfAKindDisplay
	call	ObjMessage
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle FullHouseDisplay
	mov	si,offset FullHouseDisplay
	call	ObjMessage
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle FlushDisplay
	mov	si,offset FlushDisplay
	call	ObjMessage
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle StraightDisplay
	mov	si,offset StraightDisplay
	call	ObjMessage
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle ThreeOfAKindDisplay
	mov	si,offset ThreeOfAKindDisplay
	call	ObjMessage
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle TwoPairDisplay
	mov	si,offset TwoPairDisplay
	call	ObjMessage
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle PairDisplay
	mov	si,offset PairDisplay
	call	ObjMessage
	mov	di,mask MF_FIXUP_DS
	mov	bx,handle LostDisplay
	mov	si,offset LostDisplay
	call	ObjMessage

	.leave
	ret
PokerSetViewBackgroundColor		endp

;
;	These strings are in the .ini file so do not have to be localizable
;

pokerCategoryString		char	"poker",0
pokerWhichBackString		char	"whichBack",0
pokerPlayTuneString		char	"playTunes",0
pokerWildString			char	"wild",0

if	FADING
pokerFadingString		char	"fadeCards",0
endif


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
PokerSaveOptions	method	PokerProcessClass, MSG_POKER_SAVE_OPTIONS
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
	mov	si, offset pokerCategoryString
	mov	dx, offset pokerWhichBackString
	call	InitFileWriteInteger

	;
	; Save wild mode
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle WildList
	mov	si, offset WildList
	mov	di, mask MF_CALL
	call	ObjMessage		;AX <- wild boolean
EC <	ERROR_C	-1							>

	mov	bp, ax			;BP <- value
	mov	cx, ds
	mov	si, offset pokerCategoryString
	mov	dx, offset pokerWildString
	call	InitFileWriteInteger

if	FADING

	;
	;	Save fade mode
	;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	bx, handle FadeList
	mov	si, offset FadeList
	mov	di, mask MF_CALL
	call	ObjMessage
	call	ObjMessage		;LES_ACTUAL_EXCL set if on...
	and	ax, 1			;filter through fade bit
	mov	cx, ds
	mov	si, offset pokerCategoryString
	mov	dx, offset pokerFadingString
	call	InitFileWriteBoolean

endif
	;
	;	Save sound setting
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle SoundList
	mov	si, offset SoundList
	mov	di, mask MF_CALL
	call	ObjMessage
EC <	ERROR_C	-1							>

	mov	bp, ax
	mov	cx, ds
	mov	si, offset pokerCategoryString
	mov	dx, offset pokerPlayTuneString
	call	InitFileWriteInteger
	call	InitFileCommit

	ret
PokerSaveOptions	endm

PokerShutDown	method	PokerProcessClass,
			MSG_GEN_PROCESS_CLOSE_APPLICATION
	.enter
if 0
	mov	ax, MSG_GAME_SAVE_STATE
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	push	cx			;save block
endif
	CallObject	MyPlayingTable, MSG_GAME_SHUTDOWN, MF_FIXUP_DS
	mov	di, segment PokerProcessClass
	mov	es, di
	mov	di, offset PokerProcessClass
	mov	ax, MSG_GEN_PROCESS_CLOSE_APPLICATION
	call	ObjCallSuperNoLock
if 0
	pop	cx
endif
	.leave
	ret
PokerShutDown	endm


CommonCode	ends		;end of CommonCode resource
