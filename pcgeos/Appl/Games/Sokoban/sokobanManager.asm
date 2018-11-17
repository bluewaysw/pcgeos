COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990-1995.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Sokoban
FILE:		sokoban.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/10/92	Initial version

DESCRIPTION:  
	      
	GEOS port of the much-beloved Sokoban game.	      

RCS STAMP:

	$Id: sokobanManager.asm,v 1.1 97/04/04 15:12:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Product shme
;------------------------------------------------------------------------------

include stdapp.def

	_JEDI			=	FALSE

	LEVEL_EDITOR			equ	TRUE
	SET_BACKGROUND_COLOR		equ	TRUE
	EXTERNAL_LEVELS			equ	TRUE
	HIGH_SCORES			equ	TRUE
	PLAY_SOUNDS			equ	TRUE
	DOCUMENT_CONTROL		equ	TRUE

;
;  .gp files only handle constants being defined, and don't
;  care what they're defined to.  So we only define them
;  where they're needed.
;
	GP_LEVEL_EDITOR			equ	TRUE
	GP_HIGH_SCORES			equ	TRUE
	GP_PLAY_SOUNDS			equ	TRUE
	GP_DOCUMENT_CONTROL		equ	TRUE

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include file.def
include	hugearr.def
include vm.def
include char.def
include input.def
include initfile.def				; loading/saving options
include	system.def
include	gstring.def
include Internal/threadIn.def			; ThreadBorrowStackSpace
include	assert.def

include Objects/winC.def
include Objects/inputC.def			; Required for mouse input

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

if HIGH_SCORES
UseLib game.def
endif

if PLAY_SOUNDS
UseLib sound.def
endif

UseLib Objects/vTextC.def
UseLib Objects/colorC.def

;
; Local include files.
;
include sokoban.def
include	sokoban.rdef		; include compiled UI definitions

;
; There must be an instance of every class in idata.
;
idata	segment
	SokobanProcessClass	mask	CLASSF_NEVER_SAVED
	SokobanApplicationClass
	MapContentClass
if HIGH_SCORES
	SokobanHighScoreClass
endif
	MapViewClass
idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

;
; Include all the source assembly files (small model).
;

include	sokobanBitmaps.asm

include	sokoban.asm
include sokobanUI.asm
include sokobanDocument.asm
include sokobanApplication.asm
include sokobanSolve.asm
include	sokobanMove.asm

if PLAY_SOUNDS
include sokobanSounds.asm
endif

if HIGH_SCORES
include sokobanScores.asm
endif

if LEVEL_EDITOR
include sokobanLevels.asm
include sokobanEditor.asm
endif
