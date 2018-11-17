COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- Util
FILE:		utilManager.asm

AUTHOR:		Martin Turon, October 30, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/30/92        Initial version

DESCRIPTION:
	Manager for this module.

	$Id: utilManager.asm,v 1.1 97/04/07 10:45:43 newdeal Exp $

=============================================================================@

_Util = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	shellGeode.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	utilVariable.def
include	utilConstant.def
include	utilMacro.def


;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
Util	segment	resource

include	utilMain.asm		; Main code file for this module.

Util	ends

