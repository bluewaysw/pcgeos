COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Black Jack
FILE:		bjack.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	bchow	2 /93		Initial Version

DESCRIPTION:


RCS STAMP:
	$Id: bjack.asm,v 1.1 97/04/04 15:46:16 newdeal Exp $

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
UseLib	game.def
UseLib	cards.def
UseLib	sound.def
UseLib	dbase.def
UseLib	Objects/vTextC.def
UseLib	wav.def



;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

BJACK_BOTH_DOUBLE_DOWN_AND_SPLIT	enum	FatalErrors

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------
	SCORE_DISPLAY_BUFFER_SIZE	equ	12	;11 chars for score +
							; null terminator
;    Don't enable both of these at once

WAV_SOUND  equ 0
STANDARD_SOUND equ 1

;   This enables/disables code to allow setting of card fading. The ui
;   must be uncommented/commented in bjack.ui also.

FADING = 0

if	STANDARD_SOUND
	; Notes

;	WHOLE		equ	48
;	HALF		equ	WHOLE/2
	HALF_D		equ	HALF * 3/2
;	QUARTER		equ	WHOLE/4
	QUARTER_D	equ	QUARTER * 3/2
;	EIGHTH		equ	QUARTER/2

endif

include bjackGame.asm
include bjackSound.asm
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

BJackProcessClass	class	GenProcessClass

MSG_BJACK_SAVE_OPTIONS	message

BJackProcessClass	endc	;end of class definition

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		sizes.def

include		bjack.rdef



;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

;Class definition is stored in the application's idata resource here.

	BJackProcessClass	mask CLASSF_NEVER_SAVED

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends

;------------------------------------------------------------------------------
;		Code for BJackProcessClass
;------------------------------------------------------------------------------
CommonCode	segment	resource	;start of code resource

BJackStartUp	method	BJackProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION

	;    If the game is already open then we started to exit
	;    but were started backup. All the ui objects should still
	;    be in place. So just call the super class. Note -
	;    the AAF_RESTORING_FROM_STATE bit will be set in this 
	;    case even though we aren't coming back from state, so 
	;    checking for being open must come before checking the
	;    bit.
	;

	call	BJackCheckIfGameIsOpen
	jc	callSuper

	test	cx, mask AAF_RESTORING_FROM_STATE
	jz	startingUp

	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_GAME_RESTORE_BITMAPS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

callSuper:
	mov	di, offset BJackProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock

setupSounds:

if STANDARD_SOUND
	;   Under any circumstances that we receive 
	;   MSG_GEN_PROCESS_OPEN_APPLICATION the sound buffers will
	;   need to be created.
	;

	call	SoundSetupSounds
endif

	;    Mark the game as open so that we can detect the lazarus
	;    situation.
	;

	call	BJackMarkGameOpen

	ret

startingUp:
	call	BJackMakeSureTokenIsInstalled

	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_GAME_SETUP_STUFF
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	di, offset BJackProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock

	;
	;  We're not restoring from state, so we need to create a full
	;  deck and start a new game here
	;
	CallObject MyHand, MSG_HAND_MAKE_FULL_HAND, MF_FIXUP_DS

	;
	;	Get which card back we're using
	;
	mov	cx, cs
	mov	ds, cx			;DS:SI <- ptr to category string
	mov	si, offset bJackCategoryString
	mov	dx, offset bJackWhichBackString
	call	InitFileReadInteger
	jc	getPlayTune
	mov_trash	cx, ax				;cx <- which back
	mov	ax, MSG_GAME_SET_WHICH_BACK
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	call	ObjMessage

getPlayTune:
	;
	; Set sound setting
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset bJackCategoryString		;category
	mov	dx, offset bJackPlayTuneString		;key
	call	InitFileReadInteger			;look into the .ini file
	jc	getDealerStays
	mov_trash	cx, ax				;cx <- which back
	mov	dx, 0					;not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle SoundList
	mov	si, offset SoundList
	clr	di
	call	ObjMessage

getDealerStays:
	;
	; Set dealer stays setting
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset bJackCategoryString		;category
	mov	dx, offset bJackDealerStaysString		;key
	call	InitFileReadInteger			;look into the .ini file
	jc	getSpiltRule
	mov_trash	cx, ax				;cx <- which setting
	mov	dx, 0					;not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle DealerStayRule
	mov	si, offset DealerStayRule
	clr	di
	call	ObjMessage

getSpiltRule:
	;
	; Set splits setting
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset bJackCategoryString		;category
	mov	dx, offset bJackSplitAllowedString		;key
	call	InitFileReadInteger			;look into the .ini file
	jc	getDoubleDownRule
	mov_trash	cx, ax				;cx <- which setting
	mov	dx, 0					;not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle AcesSplitRule
	mov	si, offset AcesSplitRule
	clr	di
	call	ObjMessage

getDoubleDownRule:
	;
	; Set double down setting
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset bJackCategoryString		;category
	mov	dx, offset bJackDoubleDownString		;key
	call	InitFileReadInteger			;look into the .ini file
	jc	getFading
	mov_trash	cx, ax				;cx <- which setting
	mov	dx, 0					;not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle DoubleDownRule
	mov	si, offset DoubleDownRule
	clr	di
	call	ObjMessage

getFading:

if	FADING
	;
	; Set fading mode.
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset bJackCategoryString		;category
	mov	dx, offset bJackFadingString		;key
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


if	FADING
	;
	;	Read the UI to see whether or not we want cards to fade.
	;
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	mov	ax, MSG_SET_FADE_STATUS
	call	ObjMessage
endif

	CallObject	MyPlayingTable, MSG_DISPLAY_WELCOME_TEXT, MF_FORCE_QUEUE

	jmp	setupSounds

BJackStartUp	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackCheckIfGameIsOpen
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
BJackCheckIfGameIsOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size GetVarDataParams
	mov	bp, sp
	mov	ss:[bp].GVDP_dataType, \
		ATTR_BJACK_GAME_OPEN
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
BJackCheckIfGameIsOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackMarkGameOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will add the varData ATTR_SOLITAIRE_GAME_OPEN to
		MyPlayingTable

CALLED BY:	BJackOpenApplication

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
BJackMarkGameOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size AddVarDataParams
	mov	bp, sp
	mov	ss:[bp].AVDP_dataType, \
		ATTR_BJACK_GAME_OPEN
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
BJackMarkGameOpen	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BJackMakeSureTokenIsInstalled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The zoomer doesn't force applications to install their tokens. 
		So we must do it ourselves

CALLED BY:	INTERNAL
		BJackStartUp

PASS:		*ds:si - BJackProcessClass

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
BJackMakeSureTokenIsInstalled		proc	near
	uses	ax,bx,cx,dx,bp,si,di
	.enter

	mov	bx,handle BJackApp
	mov	si,offset BJackApp
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_APPLICATION_INSTALL_TOKEN
	call	ObjMessage

	.leave
	ret
BJackMakeSureTokenIsInstalled		endp


;
;	These strings are in the .ini file so do not have to be localizable
;

bJackCategoryString		char	"bjack",0
bJackWhichBackString		char	"whichBack",0
bJackPlayTuneString		char	"playTunes",0
bJackDealerStaysString		char	"dealerStay",0
bJackSplitAllowedString		char	"split",0
bJackDoubleDownString		char	"doubleDown",0
if	FADING
bJackFadingString		char	"fadeCards",0
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
	jfh  4/4/00	added the house rules to save
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BJackSaveOptions	method	BJackProcessClass, MSG_BJACK_SAVE_OPTIONS
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
	mov	si, offset bJackCategoryString
	mov	dx, offset bJackWhichBackString
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
	mov	si, offset bJackCategoryString
	mov	dx, offset bJackFadingString
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

	mov	bp, ax
	mov	cx, ds
	mov	si, offset bJackCategoryString
	mov	dx, offset bJackPlayTuneString
	call	InitFileWriteInteger

	;
	;	Dealer stays on... setting
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle DealerStayRule
	mov	si, offset DealerStayRule
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bp, ax
	mov	cx, ds
	mov	si, offset bJackCategoryString
	mov	dx, offset bJackDealerStaysString
	call	InitFileWriteInteger

	;
	;	Split allowed on... setting
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle AcesSplitRule
	mov	si, offset AcesSplitRule
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bp, ax
	mov	cx, ds
	mov	si, offset bJackCategoryString
	mov	dx, offset bJackSplitAllowedString
	call	InitFileWriteInteger

	;
	;	Double down allowed on... setting
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle DoubleDownRule
	mov	si, offset DoubleDownRule
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bp, ax
	mov	cx, ds
	mov	si, offset bJackCategoryString
	mov	dx, offset bJackDoubleDownString
	call	InitFileWriteInteger
	call	InitFileCommit

	ret
BJackSaveOptions	endm

BJackShutDown	method	BJackProcessClass, MSG_GEN_PROCESS_CLOSE_APPLICATION

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
	mov	di, segment BJackProcessClass
	mov	es, di
	mov	di, offset BJackProcessClass
	mov	ax, MSG_GEN_PROCESS_CLOSE_APPLICATION
	call	ObjCallSuperNoLock
if 0
	pop	cx
endif
	.leave
	ret
BJackShutDown	endm

CommonCode	ends		;end of CommonCode resource
