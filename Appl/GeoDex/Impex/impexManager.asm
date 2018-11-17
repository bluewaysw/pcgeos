COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Impex
FILE:		impexManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/3/92		Initial version

DESCRIPTION:
	This file assembles the Impex module of GeoDex.

	$Id: impexManager.asm,v 1.1 97/04/04 15:49:59 newdeal Exp $

------------------------------------------------------------------------------@

_Impex = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include geodexGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include impexVariable.def
include math.def
include	cell.def
include	parse.def
include	ssheet.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include impexImport.asm
include impexExport.asm

end
