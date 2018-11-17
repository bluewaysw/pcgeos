COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec (common code for all specific UIs)
FILE:		cspecManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file assembles the Spec/ module of the Open Look library

	$Id: cspecManager.asm,v 1.1 97/04/07 10:51:09 newdeal Exp $

------------------------------------------------------------------------------@

_Spec		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		cMacro.def
include		cGeode.def
include		cGlobal.def

include		localize.def	; for Resources file

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		cspecMacro.def
include		cspecConstant.def
include		cspecVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		cspecGlyphDisplay.asm
include		cspecTrigger.asm
include		cspecInteraction.asm
include		cspecText.asm
include		cspecPane.asm
include		cspecDisplay.asm
include		cspecApplication.asm
include		cspecField.asm
include		cspecScreen.asm
include		cspecSystem.asm
include		cspecDisplayControl.asm
include		cspecPrimary.asm
include		cspecGadget.asm
include		cspecContent.asm
include		cspecUIDocumentControl.asm
include		cspecAppDocumentControl.asm
include		cspecDocument.asm
include		cspecFileSelector.asm
include		cspecItem.asm
include		cspecValue.asm
include		cspecPenInputControl.asm

;include interface definition files for each specific UI:

OLS < include	cspecOpenLook.rdef	;for all _OL_STYLE UIs.		>
CUAS < include	cspecCUAS.rdef		;for all _CUA_STYLE UIs.	>
end
