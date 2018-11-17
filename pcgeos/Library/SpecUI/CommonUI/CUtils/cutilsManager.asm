COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CUtils (common code for all specific UIs)
FILE:		cutilsManager.asm (main file for all gadget code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file assembles the Utils/ module of the Open Look library

	$Id: cutilsManager.asm,v 1.1 97/04/07 10:54:39 newdeal Exp $

------------------------------------------------------------------------------@

_Utils		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		cMacro.def
include		cGeode.def
include		cGlobal.def

include		timer.def		; for cutilsSpinGadget.asm
include		fileEnum.def		; for cutilsFileSelector.asm
include		drive.def		; for cutilsFileSelector.asm
include		system.def		; for cutilsFileSelector.asm
include		chunkarr.def		; for cutilsApplication.asm
include		initfile.def		; for cutilsApplication.asm
include		disk.def		; for cutilsFileSelector.asm
include		font.def
include		sysstats.def		; for SysGetInfo (FS)
include		system.def		; for SysDisableAPO


include		Internal/geodeStr.def	; for cutilsApplication.asm
include		Internal/grWinInt.def	; for copenSystem.asm
include		Internal/window.def	; for copenSystem.asm,
					;	copenAppXXX.asm
UseDriver	Internal/videoDr.def	; for cutilsApplication.asm

include		Internal/heapInt.def	; darn, for TPD_stackBot used in
					;	OLCountStayUpModeMenus
include		assert.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		cutilsMacro.def
include		cutilsConstant.def
include		cutilsVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		copenUtils.asm
include		copenMoniker.asm

if _NIKE_EUROPE
include		kbdAcceleratorData.asm
endif

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------
include		copenTrace.asm
endif		;END of OPEN LOOK specific code -------------------------------

include		copenAppAttDet.asm
include		copenAppCommon.asm
include		copenAppMisc.asm

include		copenSystem.asm

include		copenFileSelectorHigh.asm
include		copenFileSelectorMiddle.asm
include		copenFileSelectorLow.asm

end
