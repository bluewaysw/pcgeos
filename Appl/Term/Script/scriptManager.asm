COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Script
FILE:		scriptManager.asm

AUTHOR:		Dennis Chow, January 31, 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      01/31/90        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: scriptManager.asm,v 1.1 97/04/04 16:56:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Script = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	scriptInclude.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
idata	segment
include	scriptVariable.def
idata	ends

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
Script	segment	resource

include	scriptMain.asm		; Main code file for this module.
include	scriptLocal.asm		; Local code file for this module.

Script	ends

	end
