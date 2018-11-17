COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- Dialog
FILE:		dialogManager.asm

AUTHOR:		Martin Turon, December 5, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/05/92        Initial version

DESCRIPTION:
	Manager for this module.

	$Id: dialogManager.asm,v 1.1 97/04/07 10:45:03 newdeal Exp $

=============================================================================@

_Dialog = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	shellGeode.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	dialogConstant.def		; local constants
include	dialog.rdef			; error strings


;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
ShellErrorDialog	segment	resource
	include	dialogMain.asm		; Main code file for this module.
ShellErrorDialog	ends

ShellCStubs	segment	resource
	include	dialogC.asm		; C stubs for this module.
ShellCStubs	ends
