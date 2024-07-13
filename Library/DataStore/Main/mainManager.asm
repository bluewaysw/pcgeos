COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	DataStore
MODULE:		Main
FILE:		mainManager.asm

AUTHOR:		Cassie Hartzog, Oct  5, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	10/ 5/95		Initial revision


DESCRIPTION:
	

	$Id: mainManager.asm,v 1.1 97/04/04 17:53:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;--------------------------------------------------------------------------
;			Def files
;--------------------------------------------------------------------------

include	dsGeode.def



;--------------------------------------------------------------------------
;			Module-specific definitions
;--------------------------------------------------------------------------

DS_NON_FIXED_FIELD	   equ	0	; variable-length field
NUM_INDEX_HANDLE           equ  1 


;--------------------------------------------------------------------------
;			Code files
;--------------------------------------------------------------------------

include	mainC.asm
include mainStructure.asm
include mainData.asm
include mainEC.asm

















