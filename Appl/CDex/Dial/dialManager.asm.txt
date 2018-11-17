COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Dial
FILE:		dialManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/3/92		Initial version

DESCRIPTION:
	This file assembles the Dial module GeoDex.

	$Id: dialManager.asm,v 1.1 97/04/04 15:49:49 newdeal Exp $

------------------------------------------------------------------------------@

_Dial = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include geodexGeode.def
include	initfile.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	dialVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include dialModem.asm
include dialPhone.asm

if _QUICK_DIAL
include dialQuickDial.asm
endif

include dialUtils.asm

end
