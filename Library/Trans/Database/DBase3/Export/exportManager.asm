COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	dBase III
MODULE:		Export
FILE:		exportManger.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/14/92		Initial version

DESCRIPTION:
        This is the main include file for the Export module of the
	dBase III translation library.

	$Id: exportManager.asm,v 1.1 97/04/07 11:42:58 newdeal Exp $

------------------------------------------------------------------------------@

_Export = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	dbCommonGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this library
;-----------------------------------------------------------------------------

include	dbase3Global.def
include	dbase3Constant.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include exportFile.asm

end
