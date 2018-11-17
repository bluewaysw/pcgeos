COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface
FILE:		UI/uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:

	$Id: uiManager.asm,v 1.1 97/04/07 11:46:46 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include uiGeode.def
include initfile.def

UseDriver Internal/videoDr.def

include Internal/kbdMap.def

include Internal/specUI.def		; for SPIR_GET_DOC_CONTROL_OPTIONS
					;	and DocControlOptions

ACCESS_KEYBOARD_DRIVER=1
UseDriver Internal/kbdDr.def

include	timer.def
include font.def
UseLib	Objects/vTextC.def
include	fileEnum.def

include	Internal/geodeStr.def

include driver.def			; to handle power On/Off
include Internal/powerDr.def

;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------


include uiEMCInteraction.def
include uiManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include uiEdit.asm
include uiView.asm
include uiTool.asm
include uiPage.asm
include uiDispCtrl.asm
include	uiExpress.asm
include uiEMOM.asm
include uiEMTrigger.asm
