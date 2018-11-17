COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CGadget (common code for all specific UIs)
FILE:		cgadgetManager.asm (main file for all gadget code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file assembles the Utils/ module of the Open Look library

	$Id: cgadgetManager.asm,v 1.1 97/04/07 10:54:18 newdeal Exp $

------------------------------------------------------------------------------@

_Gadget		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		cMacro.def
include		cGeode.def
include		cGlobal.def

include		timer.def	; for spin gadget repeat
include		font.def
UseLib		hwr.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		cgadgetMacro.def
include		cgadgetConstant.def
include		cgadgetVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include	        copenGadget.asm
include	        copenGadgetComp.asm
include	        copenGlyphDisplay.asm

include	        copenSpinGadget.asm

include	        copenTextCommon.asm
include	        copenTextBuild.asm

if GEN_VALUES_ARE_TEXT_ONLY

include		copenValue.asm
include		copenValueText.asm
include		copenSlider.asm

else

include		copenValue.asm
include		copenSlider.asm

endif

end
