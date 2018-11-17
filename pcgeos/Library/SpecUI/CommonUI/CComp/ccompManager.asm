COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988-1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CComp (common code for all specific UIs)
FILE:		ccompManager.asm (main file for all gadget code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file assembles the Comp/ module of the Open Look library

	$Id: ccompManager.asm,v 1.1 97/04/07 10:54:01 newdeal Exp $

------------------------------------------------------------------------------@

_Comp		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		cMacro.def
include		cGeode.def
include		cGlobal.def

include		font.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		ccompMacro.def
include		ccompConstant.def
include		ccompVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

	;
	; OLCtrlClass
	;
include	        copenCtrlClass.asm
include	        copenCtrlCommon.asm
include	        copenCtrlGeometry.asm

include	        copenMenuBar.asm
include	        copenTriggerBar.asm
include	        copenGadgetArea.asm
include	        copenMenuItemGroup.asm
include	        copenContent.asm
include		copenReplyBar.asm
include		copenPopout.asm
include		copenTitleGroup.asm


end
