COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Iclas -- HugeFile
FILE:		hugefileManager.asm

AUTHOR:		Martin Turon, September 23, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/23/92		Initial version

DESCRIPTION:
	Manager for this module.

	$Id: hugefileManager.asm,v 1.1 97/04/04 19:42:20 newdeal Exp $

=============================================================================@

_ShellBuffer = 1

;------------------------------------------------------------------------------
;	Include global library definitions.
;------------------------------------------------------------------------------
include	shellGeode.def

;------------------------------------------------------------------------------
;	Include local module definitions.
;------------------------------------------------------------------------------
include	bufferConstant.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
ShellFileBuffer	segment	resource
	include	bufferMain.asm		; Main code file for this module.
ShellFileBuffer	ends

ShellCStubs	segment	resource
	include	bufferC.asm		; C stubs for this module.
ShellCStubs	ends




