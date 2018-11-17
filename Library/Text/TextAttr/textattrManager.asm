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

	$Id: textattrManager.asm,v 1.1 97/04/07 11:18:40 newdeal Exp $

------------------------------------------------------------------------------@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def
include texttext.def
include textstorage.def
include textattr.def
include textgr.def
include textui.def
include textregion.def
include textselect.def
include textundo.def
include textline.def

include Internal/harrint.def

include Objects/Text/tCtrlC.def
UseLib	spell.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include taConstant.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

; Common run related code; resources: Text, TextAttributes, TextGraphic

include		taStorage.asm
include		taRunQuery.asm
include		taRunLow.asm
include		taRunManip.asm
include		taRunTrans.asm

include		taElement.asm

include		taNotify.asm
include		taRange.asm

; CharAttr/paraAttr/type related code; resource(s): TextAttributes

include		taAttr.asm
include		taCharAttr.asm
include		taParaAttr.asm
include		taType.asm
include		taName.asm

; Style sheet code: TextStyle

include		taStyle.asm
include		taStyleDesc.asm
include		taStyleMerge.asm
include		taStyleStrings.asm

; C stubs

include 	taC.asm

