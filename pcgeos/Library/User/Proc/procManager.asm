COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Proc
FILE:		procManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file assembles the Process/ module of the UserInterface.

	$Id: procManager.asm,v 1.1 97/04/07 11:44:03 newdeal Exp $

------------------------------------------------------------------------------@

_Proc		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		uiGeode.def

include		dbase.def
include		Objects/gEditCC.def
include		sem.def

include		Internal/objInt.def
include		Internal/geodeStr.def

	DecodeProtocol

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		procMacro.def
include		procConstant.def
include		procVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		procClass.asm
include		procUtils.asm
include		procUndo.asm
end
