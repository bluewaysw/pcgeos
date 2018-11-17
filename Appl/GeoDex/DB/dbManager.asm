COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Database
FILE:		dbManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/3/92		Initial version

DESCRIPTION:
	This file assembles the Database module of GeoDex.

	$Id: dbManager.asm,v 1.1 97/04/04 15:49:41 newdeal Exp $

------------------------------------------------------------------------------@

_Database = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include geodexGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	dbVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include dbDisplay.asm
include dbRecord.asm
include dbUpdate.asm
include dbUtils.asm

end
