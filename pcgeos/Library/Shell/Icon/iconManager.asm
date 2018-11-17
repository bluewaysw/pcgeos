COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- Icon
FILE:		iconManager.asm

AUTHOR:		Martin Turon, October 19, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/19/92	Initial version

DESCRIPTION:
	Manager for this module.

	$Id: iconManager.asm,v 1.1 97/04/07 10:45:26 newdeal Exp $

=============================================================================@

_Icon = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	shellGeode.def
include token.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	iconVariable.def
include	iconConstant.def
include	iconMacro.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
Icon	segment	resource

include	iconMain.asm		; Main code file for this module.

Icon	ends


IconGadgets	segment	resource

include	iconlistMain.asm	; Main code file for IconListClass objects
include	iconlistUtil.asm
include	icondisplayMain.asm

IconGadgets	ends

