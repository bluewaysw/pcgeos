COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CDeskVis
FILE:		cshobjManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	11/92		Initial version

DESCRIPTION:

	$Id: cshobjManager.asm,v 1.1 97/04/04 15:03:19 newdeal Exp $

------------------------------------------------------------------------------@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include cshobjConstant.def
include cshobjVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

ShellObjectCode	segment	resource

include cshobjMoveCopy.asm
include cshobjDelete.asm
include cshobjUtils.asm
include cshobjReceive.asm

ShellObjectCode	ends
