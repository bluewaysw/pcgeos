COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Text
FILE:		textManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12-Jun-89	Initial version

DESCRIPTION:

	$Id: textManager.asm,v 1.2 98/03/24 23:00:58 gene Exp $

------------------------------------------------------------------------------@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def
include texttext.def
include textattr.def
include textgr.def
include texttrans.def
include textpen.def
include textssp.def
include textline.def
include textstorage.def
include textregion.def
include textselect.def
include textundo.def
include hwr.def

include Internal/im.def
include Internal/heapInt.def
include Internal/semInt.def
ifdef	USE_FEP
include Internal/fepDr.def
include driver.def
endif
include system.def
UseLib	spell.def


;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	tConstant.def
include	tVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------


; Resources:
;	Text - core calculation and display
;	TextInstance - initilization, relocation, setting instance data,
;			open/close stuff, obscure methods
;	TextAttributes - charAttr and paraAttr related
;	TextGraphic - graphics hanndling
;	TextBorder - border, background color, tab line related
;	TextSearchSpell - search & replace and spell check code

;-----------------------------------------------------------------------------


; Entry Point routines

include 	textEntry.asm

ifdef	USE_FEP
include		textFep.asm
endif	; USE_FEP

;==============

; Utility routines

include		textUtils.asm

; Core calculation and display code; resource(s): Text, TextInstance
;	(init code in TextInstance)

include		textCalc.asm
include		textCalcObject.asm
include		textReplace.asm

;-----------------------------------------------------------------------------
;			    Selection Code
;-----------------------------------------------------------------------------

include		textGState.asm

include		textOutput.asm
include		textScroll.asm
include		textScrollOneLine.asm


include		textStuff.asm

include		textMethodDraw.asm

;
; Hopefully everything in textMethodManip.asm will migrate to other files and
; we can remove it entirely.
;
include		textMethodManip.asm
include		textCompatibility.asm
include		textMethodSet.asm
include		textMethodGet.asm
include		textMethodClipboard.asm
include		textOptimizedUpdate.asm


include		textMethodInput.asm
include		textFilter.asm

;==============

; Instance data related code; resource(s): TextInstance

include		textInstance.asm
include		textMethodGeometry.asm
include		textMethodInstance.asm		;except ~20 bytes in Text

;==============

; Border, background color, tab line related code; resource(s): TextBorder

include		textBGBorder.asm

;==============

; Suspend/unsuspend; resource(s): TextAttributes

include		textSuspend.asm

include 	textC.asm
