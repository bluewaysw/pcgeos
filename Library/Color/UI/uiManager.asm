COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Color Library
FILE:		UI/uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:

	$Id: uiManager.asm,v 1.2 98/05/08 20:22:16 gene Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include colorGeode.def

;---

DefLib Objects/colorC.def

include Internal/prodFeatures.def

;----------------------------------------------------------------------
; This part is to set some particular flags for the Jedi project.
;----------------------------------------------------------------------
	_JEDI		=	FALSE



;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

if not NO_CONTROLLERS
;
; if NO_CONTROLLERS, there is no resource left in ui files.
; -- kho, July 19. 1995
;
include uiManager.rdef
endif		; if (not NO_CONTROLLERS) and (not _JEDI)

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include uiColor.asm
include uiOtherColor.asm
