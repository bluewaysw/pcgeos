COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		UI/uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:

	$Id: uiManager.asm,v 1.1 97/04/07 11:16:54 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include textGeode.def

include textui.def
include textssp.def

;---

include system.def

UseLib Objects/colorC.def

DefLib Objects/Text/tCtrlC.def

;------------------------------------------------------------------------------
;		Our very own class
;------------------------------------------------------------------------------

TextSuspendOnApplyInteractionClass	class	GenInteractionClass
TextSuspendOnApplyInteractionClass	endc
NoGraphicsTextClass	class	GenTextClass
;
;	A class we use to disallow the pasting of graphics
;
NoGraphicsTextClass	endc

ifdef GPC_SEARCH
OverrideCenterOnMonikersClass	class	GenInteractionClass
OverrideCenterOnMonikersClass	endc
endif

;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include uiUtils.asm
include uiTextStyle.asm
include uiFont.asm
include uiPointSize.asm
include uiCharFGColor.asm
include uiCharBGColor.asm
include uiFontAttr.asm

include uiJustification.asm
include uiParaSpacing.asm
include uiLineSpacing.asm
include uiDefaultTabs.asm
include uiParaBGColor.asm
include uiDropCap.asm
include uiParaAttr.asm
include uiBorder.asm
include uiBorderColor.asm
include uiHyphenation.asm
include uiMargin.asm
include uiTab.asm

include uiTextCount.asm
;include uiTextPosition.asm

include uiTextStyleSheet.asm
include uiSearchReplace.asm
include uiNoGraphicsText.asm
include uiC.asm
include uiTextRuler.asm

include uiHelp.asm
