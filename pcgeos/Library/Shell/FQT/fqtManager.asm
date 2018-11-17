COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- FQT
FILE:		fqtManager.asm

AUTHOR:		David Litwin, January 19, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/19/93	Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: fqtManager.asm,v 1.1 97/04/07 10:45:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_FQT = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	shellGeode.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	fqtVariable.def
include	fqtConstant.def
include	fqtMacro.def


;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
FQT	segment	resource

include	fqtMain.asm		; Main code file for this module.

FQT	ends
