COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- DirInfo
FILE:		dirinfoManager.asm

AUTHOR:		Martin Turon, November 9, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/9/92		Initial version

DESCRIPTION:
	Manager for this module.

	$Id: dirinfoManager.asm,v 1.1 97/04/07 10:45:49 newdeal Exp $

=============================================================================@

_DirInfo = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	shellGeode.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	dirinfoConstant.def
include	dirinfoVariable.def
include	dirinfoMacro.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
DirInfo	segment	resource

include	dirinfoMain.asm		; Main code file for this module.
include	dirinfoEC.asm

DirInfo	ends



