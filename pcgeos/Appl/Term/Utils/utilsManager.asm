COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Utils
FILE:		utilsManager.asm

AUTHOR:		Dennis Chow, December 13, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      12/13/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: utilsManager.asm,v 1.1 97/04/04 16:56:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Utils = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	utilsInclude.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
idata	segment
include	utilsVariable.def
idata	ends

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
Utils	segment	resource

include	utilsMain.asm		; Externally callable routines for this module.
include	utilsLocal.asm		; Internally callable routines for this module.

Utils	ends

	end
