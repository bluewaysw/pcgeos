COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- File
FILE:		fileManager.asm

AUTHOR:		Martin Turon, October 21, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/21/92	Initial version

DESCRIPTION:
	Manager for this module.

	$Id: fileManager.asm,v 1.1 97/04/07 10:45:35 newdeal Exp $

=============================================================================@

_File = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	shellGeode.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	fileVariable.def
include	fileConstant.def
include	fileMacro.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
File	segment	resource

include	fileMain.asm		; Main code file for this module.
include fileEC.asm

File	ends



