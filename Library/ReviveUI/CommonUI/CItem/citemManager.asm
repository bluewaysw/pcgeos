COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CExcl (common code for all specific UIs)
FILE:		citemManager.asm (main file for all gadget code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

DESCRIPTION:
	This file assembles the Item/ module of the specific UI library

	$Id: citemManager.asm,v 1.8 96/05/28 21:05:29 jmagasin Exp $

------------------------------------------------------------------------------@

_Item		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		cMacro.def
include		cGeode.def
include		cGlobal.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		citemMacro.def
include		citemConstant.def
include		citemVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

	;
	; OLItemGroupClass
	;
include		citemItemGroupClass.asm
include		citemItemGroupCommon.asm
include		citemItemGroupVeryCommon.asm

include		citemBooleanGroup.asm		;Not an object.
include		citemScrollList.asm

	;
	; OLItemClass
	;
include		citemItemClass.asm
include		citemItemCommon.asm
include		citemItemColor.asm
include		citemItemBW.asm

include		citemCheckedItem.asm
include		citemScrollableItem.asm

if _PCV
include		../../PCV/Item/itemItemBW.asm
endif

end
