COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CDeskVis
FILE:		cdeskvisManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version

DESCRIPTION:
	This file assembles the CDeskVis/ module of the desktop.

	$Id: cdeskvisManager.asm,v 1.1 97/04/04 15:01:17 newdeal Exp $

------------------------------------------------------------------------------@

_CDeskVis = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include cdeskvisConstant.def
include cdeskvisVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include cdeskvisClass.asm

end
