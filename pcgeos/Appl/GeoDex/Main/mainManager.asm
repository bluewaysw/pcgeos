COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoDex/Main
FILE:		mainManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/3/92		Initial version

DESCRIPTION:
	This file assembles the Main module of Geodex.

	$Id: mainManager.asm,v 1.2 98/02/15 19:08:56 gene Exp $

------------------------------------------------------------------------------@

_Main = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include geodexGeode.def

ifdef GPC
include iapp.def
global MAILPARSEADDRESSSTRING:far
endif

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include mainVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include mainExit.asm
include mainInit.asm
include mainGeoDex.asm
include mainUtils.asm
include mainEdit.asm

if FAX_SUPPORT
include mainClavin.asm
endif ; FAX_SUPPORT

end
