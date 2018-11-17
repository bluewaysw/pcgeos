COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VObj (Sample PC GEOS application)
FILE:		vobjManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MKH	7/7/93		Initial version

DESCRIPTION:

IMPORTANT:

RCS STAMP:
	$Id: freecellManager.asm,v 1.1 97/04/04 15:02:52 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def

include object.def
include graphics.def

include freecellMacros.def

include Objects/winC.def
include Objects/inputC.def			; Required for mouse input


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib cards.def
UseLib	sound.def

;
; Include our definitions here so that we can use the classes in ui.def as
; our superclasses.
;
include freecell.def

;-----------------------------------------------------------------------------
;			idata declarations
;-----------------------------------------------------------------------------

;
; There must be an instance of every class in idata.

idata	segment

	FreeCellProcessClass ;	mask CLASSF_NEVER_SAVED
	
idata	ends



;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
include		freecell.rdef		;include compiled UI definitions

	

;-----------------------------------------------------------------------------
;			Include Class Implementations
;-----------------------------------------------------------------------------

include		freecell.asm
include		freecellGame.asm
include		freecellSound.asm















