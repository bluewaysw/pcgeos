
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
		
	$Id: sharedManager.asm,v 1.1 97/04/07 11:42:14 newdeal Exp $

-------------------------------------------------------------------------------@

_Shared = 1

include lotus123Geode.def
include lotus123Constant.def

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Constants/Variables
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; REENTRANT_CODE must be set either TRUE or FALSE before transLibEntry.asm
; is included.
;
REENTRANT_CODE		equ	TRUE

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	transLibEntry.asm		; library entry point

CommonCode	segment	resource
	global	InputCacheAttach:far
	global	InputCacheGetChar:far
	global	InputCacheDestroy:far
	global	OutputCacheAttach:far
	global	OutputCacheWrite:far
	global	OutputCacheFlush:far
	global	OutputCacheDestroy:far

	include	sharedCacheConstant.def
	include	sharedCache.asm
CommonCode	ends

end
