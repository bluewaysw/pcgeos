COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CSV/Export
FILE:		exportManger.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	4/7/92		Initial version

DESCRIPTION:
        This is the main include file for the Export module of the
	CSV translation library.

	$Id: exportManager.asm,v 1.1 97/04/07 11:42:31 newdeal Exp $

------------------------------------------------------------------------------@

_Export = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	dbCommonGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this database library
;-----------------------------------------------------------------------------

include	csvGlobal.def
include	csvConstant.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include exportFile.asm


end
