COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Token
FILE:		tokenManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/89		Initial version

DESCRIPTION:
	This file assembles the Token/ module of the UserInterface.

	$Id: tokenManager.asm,v 1.1 97/04/07 11:46:38 newdeal Exp $

------------------------------------------------------------------------------@

_TokenDB = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		uiGeode.def

UseLib		dbase.def
UseLib		initfile.def
UseLib		vm.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		tokenMacro.def
include		tokenConstant.def
include		tokenVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		token.asm
include		tokenC.asm

end
