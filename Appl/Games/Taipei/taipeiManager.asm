COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Taipei (Trivia project: PC GEOS application)
FILE:		taipeiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/23/95		Initial version

DESCRIPTION:

IMPORTANT:

RCS STAMP:
	$Id: taipeiManager.asm,v 1.1 97/04/04 15:14:40 newdeal Exp $

------------------------------------------------------------------------------@

include stdapp.def

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

	_JEDI		=	FALSE
	_BW_ONLY	=	FALSE
	_GIVE_HINT	=	TRUE	

ifidn	PRODUCT, <JediXIP>
	_JEDI		=	TRUE
	_BW_ONLY	=	TRUE
	_GIVE_HINT	=	TRUE
endif


include timer.def
include timedate.def
include Objects/winC.def
include Objects/inputC.def			; Required for mouse input
include Objects/vTextC.def			; Text (of timer) stuffs
include assert.def
include localize.def				; for time text constants
;;; jfh include	Internal/Jedi/jCntlC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def


UseLib game.def					; for GameRandom()


;
; Include our definitions here so that we can use the classes in ui.def as
; our superclasses.
;
include taipei.def

;
; There must be an instance of every class in idata.
;
idata	segment
	TaipeiProcessClass	mask CLASSF_NEVER_SAVED
idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
include		taipei.rdef		;include compiled UI definitions

;
; Include the class implementations
;
include	taipeiContent.asm
include	taipei.asm
include taipeiInit.asm
include util.asm

; include	/staff/pcgeos/Library/User/uiConstant.def
					; for an error VOBJ
					; UI_REQUIRES_VISUAL_COMPOSITE
