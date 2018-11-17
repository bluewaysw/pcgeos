COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		Crossword
FILE:		cwordManager.asm

AUTHOR:		Peter Trinh, May  4, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 4/94   	Initial revision


DESCRIPTION:
	This file includes all the .def and .asm files of all the
	other 'modules'.
		

	$Id: cwordManager.asm,v 1.1 97/04/04 15:14:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;		Include all the system .def files
;------------------------------------------------------------------------------
include geos.def
include heap.def
include geode.def
include resource.def
include system.def
include ec.def
include assert.def
include vm.def
include gstring.def
include object.def
include graphics.def
include fileEnum.def
include product.def

include Objects/winC.def
include Objects/inputC.def
include localize.def
include timer.def
UseDriver Internal/videoDr.def
include compress.def
include Internal/specUI.def

;------------------------------------------------------------------------------
;		Include all the Libraries used
;------------------------------------------------------------------------------
UseLib ui.def
UseLib Objects/vTextC.def
UseLib wav.def

; We'll load up the HWR library when needed.

;------------------------------------------------------------------------------
;		Include all the local .def files
;------------------------------------------------------------------------------
include	cword.def
include cwordEC.def

include cwordEngine.def
include cwordFile.def

include cwordBoard.def
include cwordHWR.def
include cwordClueList.def
include cwordVisContent.def
include cwordGenView.def
include cwordOther.def

;------------------------------------------------------------------------------
;		Include .rdef file
;------------------------------------------------------------------------------
include cword.rdef

;------------------------------------------------------------------------------
;		Non-Module Class Definitions
;------------------------------------------------------------------------------
; Even though we are not define any new message or intercepting any
; existing message, we still need to subclass GenProcessClass to make
; a new process class, such that GEOS can bind this class to the geode's
; thread.
CwordProcessClass	class	GenProcessClass
MSG_CWORD_PROCESS_LAUNCH_WORD_MATCHER	message
MSG_CWORD_PROCESS_LAUNCH_WEB_BROWSER	message
CwordProcessClass	endc

idata	segment
	CwordProcessClass
idata	ends

;------------------------------------------------------------------------------
;		Include all the local .asm files
;------------------------------------------------------------------------------

include	cwordObscure.asm

include cwordEC.asm

include cwordEngine.asm
include cwordEngineFile.asm
include cwordFile.asm

include cwordBoard.asm
include cwordHWR.asm
include cwordClueList.asm
include cwordVisContent.asm
include cwordGenView.asm
include cwordBoardHWR.asm
include	cwordBoardKbd.asm
include cwordBoardClueList.asm
include	cwordBoardOpenClose.asm
include cwordBoardBounds.asm
include	cwordVictory.asm
include cwordFileSel.asm
