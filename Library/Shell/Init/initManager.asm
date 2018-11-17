COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Shell -- Init
FILE:		initManager.asm

AUTHOR:		Martin Turon, Oct  2, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/ 2/92	Initial version

DESCRIPTION:
	Manager for this module.

RCS STAMP:
	$Id: initManager.asm,v 1.1 97/04/07 10:44:48 newdeal Exp $


=============================================================================@


_Init = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	shellGeode.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	initVariable.def
include initConstant.def
include initMacro.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
Init	segment	resource

include	initMain.asm		; Main code file for this module.

Init	ends



