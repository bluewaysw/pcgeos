COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CSV/Import
FILE:		importManger.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	4/7/92		Initial version

DESCRIPTION:

        This is the main include file for the Import module of the
	CSV translation library.

	$Id: importManager.asm,v 1.1 97/04/07 11:42:37 newdeal Exp $

------------------------------------------------------------------------------@

_Import = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	dbCommonGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this library
;-----------------------------------------------------------------------------

include	csvGlobal.def
include csvConstant.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include importFile.asm

end
