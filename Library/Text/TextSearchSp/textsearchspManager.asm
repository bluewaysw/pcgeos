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
 Fine docshere.

	$Id: textsearchspManager.asm,v 1.1 97/04/07 11:19:32 newdeal Exp $

------------------------------------------------------------------------------@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def
include texttext.def
include textstorage.def
include textselect.def
include textssp.def
include textundo.def

include Objects/Text/tCtrlC.def
UseLib	Internal/spelllib.def
UseLib	spell.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		tssMisc.asm

; Search/Replace and Spell check related code; resource: SearchSpell

include		tssMethodSpell.asm
include		tssMethodSearch.asm
include		tssSearchInString.asm
include		tssC.asm
