COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Source
FILE:		sourceManager.asm

AUTHOR:		Steve Yegge

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	stevey		8/18/92		initial revision

DESCRIPTION:

	$Id: sourceManager.asm,v 1.1 97/04/04 16:06:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include	iconGeode.def
include	system.def		; for hex->ascii conversion
include Internal/harrint.def

include	sourceConstant.def
include	sourceStrings.rdef

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

idata	segment

idata	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include sourceSource.asm
include	sourceUtils.asm
include sourcePointer.asm
include	sourceLarge.asm
