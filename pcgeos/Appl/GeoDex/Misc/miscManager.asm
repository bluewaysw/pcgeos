COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc
FILE:		miscManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/3/92		Initial version

DESCRIPTION:
	This file assembles the Misc module of GeoDex.

	$Id: miscManager.asm,v 1.1 97/04/04 15:50:16 newdeal Exp $

------------------------------------------------------------------------------@

_Misc = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include geodexGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	miscVariable.def
include miscConstant.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

if PZ_PCGEOS

include miscTopColorBitmapPizza.asm
include miscTopBWBitmapPizza.asm

include miscMiddleColorBitmapPizza.asm
include miscMiddleBWBitmapPizza.asm

include miscBottomColorBitmapPizza.asm
include miscBottomBWBitmapPizza.asm

else

include miscTopColorBitmap.asm
include	miscTopBWBitmap.asm

include	miscMiddleColorBitmap.asm
include	miscMiddleBWBitmap.asm
include miscMiddleCGABitmap.asm

include miscBottomColorBitmap.asm
include	miscBottomBWBitmap.asm

endif

include miscSearch.asm
include miscLetters.asm
include miscLetterTabInvert.asm
include miscLettersDraw.asm
include miscTitle.asm
include miscPrint.asm
include miscViewMenu.asm
include miscUtils.asm

end
