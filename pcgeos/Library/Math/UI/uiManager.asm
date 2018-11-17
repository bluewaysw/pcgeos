
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 10/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial revision

DESCRIPTION:
		
	$Id: uiManager.asm,v 1.1 97/04/05 01:23:26 newdeal Exp $

-------------------------------------------------------------------------------@

include mathGeode.def
include mathConstants.def
include Internal/threadIn.def	; so we can call ThreadBorrow/ReturnStackSpace
include geoworks.def		; controller notification enums
include Objects/vTextC.def

;-------------------------------------------------------------------------------
;	Resources
;-------------------------------------------------------------------------------

include uiMain.rdef

;-------------------------------------------------------------------------------
;	Code
;-------------------------------------------------------------------------------

include	uiFormatGlobal.asm
include	uiFormatMethods.asm
include	uiFormatInternal.asm
include	uiFormatInternalLow.asm
include	uiFormatUtils.asm
include	uiFormatC.asm
