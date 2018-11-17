COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Text/TextTransfer
FILE:		texttransferManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/17/91		Initial version

DESCRIPTION:

	$Id: texttransManager.asm,v 1.1 97/04/07 11:20:01 newdeal Exp $

------------------------------------------------------------------------------@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def
include texttext.def
include textattr.def
include texttrans.def
include textstorage.def
include textline.def
include textregion.def
include textselect.def
include textundo.def

include thread.def


;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include ttConstant.def

;-----------------------------------------------------------------------------
;	Include strings
;-----------------------------------------------------------------------------

include ttStrings.asm

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		ttHigh.asm
include		ttCreate.asm
include		ttReplace.asm
include		ttQuick.asm
include		ttC.asm
