COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Win
FILE:		cwinManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

DESCRIPTION:
	This file assembles the Win/ module of the Open Look library,
	which contains the OLWinClass & objects subclassed from it.

	$Id: cwinManager.asm,v 1.3 98/03/11 06:24:27 joon Exp $

------------------------------------------------------------------------------@

_Win		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		cMacro.def
include		cGeode.def
include		cGlobal.def

include		sem.def		; for cwinPopup.asm (for UserDoDialog handler)
include		vm.def		; for cwinFieldOther.asm (for BG files)
include		chunkarr.def

include		timer.def
include		fileEnum.def
include		initfile.def
include		backgrnd.def

UseDriver	Internal/videoDr.def
UseDriver	Internal/powerDr.def
include		Internal/grWinInt.def	; for cwinFieldxxx.asm
include		Internal/window.def	; for cwinFieldxxx.asm

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		cwinConstant.def
include		cwinVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		cwinUtils.asm
	;
	; the almightly OLWinClass:
	;
include		cwinClassMisc.asm		; All sorts of resources
include		cwinClassCommonHigh.asm		; WinCommon
include		cwinClassCommonMiddle.asm	; more WinCommon
include		cwinClassCommonLow.asm		; more WinCommon
include		cwinClassOther.asm		; WinOther

include		cwinPtr.asm		;code related to PTR/BTN events
include		cwinGeometry.asm	;method handlers for geometry
include		cwinExcl.asm		;code related to FOCUS, etc. exclusives

if _CUA_STYLE	;--------------------------------------------------------------
include		cwinClassCUAS.asm	;CUA-STYLE OLWinClass code.
endif		;--------------------------------------------------------------

include		winClassSpec.asm	;specific code for each specific UI
					;(See Motif/Win, PM/Win, OpenLook/Win)

include		winDraw.asm		;drawing code for each specific UI
					;(See Motif/Win, PM/Win, OpenLook/Win)

;and the remainder of our Windowed-object classes:

include		cwinPopup.asm
include		cwinMenu.asm	
include		cwinMenuedWin.asm
include		cwinDialog.asm
include		cwinDisplay.asm
include		cwinBase.asm

include		cwinFieldOther.asm
include		cwinFieldInit.asm
include		cwinFieldCommon.asm
include		cwinFieldUncommon.asm
include		cwinFieldData.asm

include		cwinScreen.asm
include		cwinDisplayControl.asm

if not _NO_WIN_ICONS	;------------------------------------------------------
include		cwinWinIcon.asm
include		cwinGlyphDisplay.asm
endif			;------------------------------------------------------

include		cwinData.asm

end
