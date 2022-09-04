COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/Cbutton (common code for all specific UIs)
FILE:		cbuttonManager.asm (main file for all gadget code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file assembles the Utils/ module of the Open Look library

	$Id: cbuttonManager.asm,v 1.12 96/07/19 01:15:34 joon Exp $

------------------------------------------------------------------------------@

_Button		= 1

;------------------------------------------------------------------------------
;	Include common definitions
;------------------------------------------------------------------------------

include		cMacro.def
include		cGeode.def
include		cGlobal.def
include		timer.def		; for timed release of buttons in 
					;  pen mode 
if _JEDIMOTIF
include		Internal/Jedi/jCntlC.def	; for JotterIsDragActive
endif

;------------------------------------------------------------------------------
;	Include definitions for this module
;------------------------------------------------------------------------------

include		cbuttonMacro.def
include		cbuttonConstant.def
include		cbuttonVariable.def

;------------------------------------------------------------------------------
;	Include code
;------------------------------------------------------------------------------


;
; OLButtonClass code
;
include		copenButtonClass.asm
include		copenButtonCommon.asm
include		copenButtonBuild.asm

if _ODIE
include		odieButtonData.asm
else
include		copenButtonData.asm	;bitmap and region data for OLButton
endif

include		copenButtonBW.asm	;B&W draw code for OLButtonClass
include         copenMenuButton.asm

if (not NO_MENU_MARKS)
include		copenData.asm
endif

if _OL_STYLE or _MOTIF or _PM	;----------------------------------------------
include		copenButtonColor.asm	;Color draw code for OLButtonClass
endif		;OL_STYLE or MOTIF or PM --------------------------------------

end
