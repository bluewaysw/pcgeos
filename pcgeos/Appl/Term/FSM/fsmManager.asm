COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		FSM
FILE:		fsmManager.asm

AUTHOR:		Dennis Chow, September 8, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc       9/ 8/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: fsmManager.asm,v 1.1 97/04/04 16:56:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_FSM = 1

;set to include extra EC code
EXTRA_EC	equ	0

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	fsmInclude.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
idata segment
include	fsmVariable.def
idata ends

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
FSM segment resource
include	fsmMain.asm		; External functions for this module
include	fsmMakeTables.asm	; Internal functions for this module
FSM ends

	end
