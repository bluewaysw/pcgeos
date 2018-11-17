COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hearts (Trivia Project)
FILE:		hearts.asm

AUTHOR:		Peter Weck, Jan 19, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/19/93   	Initial revision


DESCRIPTION:
	
		

	$Id: hearts.asm,v 1.1 97/04/04 15:19:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

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
include text.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	sound.def
UseLib	cards.def
UseLib	Objects/vTextC.def
UseLib	wav.def

;    Don't enable both of these at once

WAV_SOUND  equ 0
STANDARD_SOUND equ 1

include heartsGame.def
include heartsDeck.def
include	heartsHand.def

include	heartsSound.asm
include heartsGame.asm
include heartsDeck.asm
include heartsHand.asm

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

EGYPTIAN_BACK = 1


;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

HeartsGenProcessClass	class	GenProcessClass

;define messages for this class here.

HeartsGenProcessClass	endc	;end of class definition

;---------------------------------
; 	HeartsAppClass
;---------------------------------
HeartsApplicationClass	class	GenApplicationClass

HeartsApplicationClass	endc

idata	segment
	HeartsApplicationClass
idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include 	hearts.rdef





;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment
	HeartsGenProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because GenProcessClass
				;objects are hybrid objects.
idata	ends


CommonCode	segment resource	;start of code resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGenOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GEN_PROCESS_OPEN_APPLICATION handler for 
		HeartsProcessClass.
		Sends the game object a MSG_GAME_SETUP_STUFF which readies
		everthing for the hearts game.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		ds	= dgroup

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	1/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGenOpenApplication	method dynamic HeartsGenProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
	uses	ax, cx, dx, bp
	.enter

	;    If the game is already open then we started to exit
	;    but were started backup. All the ui objects should still
	;    be in place. So just call the super class. Note -
	;    the AAF_RESTORING_FROM_STATE bit will be set in this 
	;    case even though we aren't coming back from state, so 
	;    checking for being open must come before checking the
	;    bit.
	;

	call	HeartsCheckIfGameIsOpen
	jc	callSuper

	test	cx, mask AAF_RESTORING_FROM_STATE
	jz	startingUp

	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	ax, MSG_GAME_RESTORE_BITMAPS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GAME_RESTORE_STATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

callSuper:
	mov	di, offset HeartsGenProcessClass
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

	call	HeartsMarkGameOpen

	.leave
	ret

startingUp:
	call	HeartsMakeSureTokenIsInstalled

	;
	;  We're not restoring from state, so we need to create a full
	;  deck and start a new game here
	;
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GAME_SETUP_STUFF
	call	ObjMessage

	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_HEARTS_GAME_SETUP_NEIGHBORS
	call	ObjMessage

	mov	di, offset HeartsGenProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock

	;
	;	instantiate a full deck of cards,including 
	;
	push	si
	mov	bx, handle MyHand
	mov	si, offset MyHand
	mov	ax, MSG_HAND_MAKE_FULL_HAND
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	;
	;	start a new game.
	;
	mov	ax, MSG_HEARTS_GAME_NEW_GAME
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	setupSounds


HeartsGenOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsCheckIfGameIsOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check if the varData ATTR_HEARTS_GAME_OPEN 
		exists for HeartsPlayingTable

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
HeartsCheckIfGameIsOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size GetVarDataParams
	mov	bp, sp
	mov	ss:[bp].GVDP_dataType, \
		ATTR_HEARTS_GAME_OPEN
	mov	{word} ss:[bp].GVDP_bufferSize, 0
;	clrdw	ss:[bp].GVDP_buffer
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
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
HeartsCheckIfGameIsOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsMarkGameOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will add the varData ATTR_SOLITAIRE_GAME_OPEN to
		MyPlayingTable

CALLED BY:	HeartsOpenApplication

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
HeartsMarkGameOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size AddVarDataParams
	mov	bp, sp
	mov	ss:[bp].AVDP_dataType, \
		ATTR_HEARTS_GAME_OPEN
	mov	{word} ss:[bp].AVDP_dataSize, size byte
	clrdw	ss:[bp].AVDP_data
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams

	.leave
	ret
HeartsMarkGameOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsMakeSureTokenIsInstalled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The zoomer doesn't force applications to install their tokens. 
		So we must do it ourselves

CALLED BY:	INTERNAL
		HeartsStartUp

PASS:		*ds:si - HeartsProcessClass

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
HeartsMakeSureTokenIsInstalled		proc	near
	uses	ax,bx,cx,dx,bp,si,di
	.enter

	mov	bx,handle HeartsApp
	mov	si,offset HeartsApp
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_APPLICATION_INSTALL_TOKEN
	call	ObjMessage

	.leave
	ret
HeartsMakeSureTokenIsInstalled		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsGenCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will save the state and then call the superclass to close
		the application.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		ds	= dgroup

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsGenCloseApplication	method dynamic HeartsGenProcessClass,
					MSG_GEN_PROCESS_CLOSE_APPLICATION
	.enter

	mov	ax, MSG_GAME_SAVE_STATE
	mov	bx, handle HeartsPlayingTable
	mov	si, offset HeartsPlayingTable
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

;	mov	bx, handle HeartsPlayingTable
;	mov	si, offset HeartsPlayingTable
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GAME_SHUTDOWN
	call	ObjMessage

	mov	di, segment HeartsGenProcessClass
	mov	es, di
	mov	di, offset HeartsGenProcessClass
	mov	ax, MSG_GEN_PROCESS_CLOSE_APPLICATION
	call	ObjCallSuperNoLock

	.leave
	ret
HeartsGenCloseApplication	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass message on to objects that need to save their options.



CALLED BY:	MSG_META_SAVE_OPTIONS
PASS:		*ds:si	= Application object
		es 	= segment of ConcenApplicationClass

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jfh	4/15/00  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsSaveOptions	method dynamic HeartsApplicationClass,
					MSG_META_SAVE_OPTIONS
	uses	ax, bx, cx, dx, di, bp
	.enter

	push	si				; save si
	
	;
	; Broadcast message to all objects that need their options saved.
	;
	CallObjectNS	HeartsToggleOptions, MSG_META_SAVE_OPTIONS, MF_FORCE_QUEUE
	CallObjectNS	SoundInteraction, MSG_META_SAVE_OPTIONS, MF_FORCE_QUEUE
	CallObjectNS	HeartsMaxPoints, MSG_META_SAVE_OPTIONS, MF_FORCE_QUEUE

	;
	; Save the card back in use. Card back will be returned in cx.
	;
	CallObjectNS 	HeartsPlayingTable, MSG_GAME_GET_WHICH_BACK, MF_CALL

	push	ds				; save ds
	mov	bp, cx				; bp <- the card back
	mov	cx, cs
	mov	ds, cx
	mov	si, offset categoryString	; ds:si=category ASCIIZ string
	mov	dx, offset keyString		; cx:dx=key ASCIIZ string
	call	InitFileWriteInteger
	pop	ds				; restore ds
  
	pop	si				; restore si

	;
	; Pass message to superclass.
	;
	mov	ax, MSG_META_SAVE_OPTIONS
	mov	di, offset HeartsApplicationClass
	call	ObjCallSuperNoLock

	.leave
	ret
HeartsSaveOptions	endm

categoryString	char	"Hearts",0      ; needs to be the same as in .ui file
keyString	char	"CardBackInUse",0

CommonCode	ends		;end of CommonCode resource
