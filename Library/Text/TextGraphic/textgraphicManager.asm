COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Text/TextAttr
FILE:		textManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/17/91		Initial version

DESCRIPTION:

	$Id: textgraphicManager.asm,v 1.1 97/04/07 11:19:37 newdeal Exp $

------------------------------------------------------------------------------@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def

include texttext.def
include textattr.def
include textgr.def
include textstorage.def
include textselect.def
include textline.def
include textregion.def
include textundo.def
include texttrans.def

include system.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	Internal/gstate.def	; needed by VisTextGraphicCompressGraphic()
UseLib	bitmap.def		; needed by VisTextGraphicCompressGraphic()

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

; Graphic related code; resource(s): TextGraphic

include		tgGraphic.asm
include		tgReplace.asm
include		tgHigh.asm
include		tgNumber.asm
include		tgOptimize.asm

