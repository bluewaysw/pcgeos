COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CUtil
FILE:		cutilManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version
	brianc	9/21/89		removed inclusion of geodeStruct.def
					for protected mode changes

DESCRIPTION:
	This file assembles the CUtil/ module of the desktop.

	$Id: cutilManager.asm,v 1.2 98/06/03 13:51:12 joon Exp $

------------------------------------------------------------------------------@

_CUtil = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include disk.def
include fileEnum.def				; for FileEnum stuff
include vm.def					; for transfer stuff
include char.def				; for C_NONBRKSPACE
include sysstats.def
include initfile.def				; ini stuff for file chaching

include Internal/fileInt.def

include cutilVariable.def
include CFolder/cfolderConstant.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include cutilUtil.asm
include cutilCommon.asm

ifdef _VS150
include cutilFileOpRedwood.asm
else
include cutilFileOpHigh.asm
include cutilFileOpMiddle.asm
include cutilFileOpLow.asm
endif

include cutilDummyObj.asm
include cutilError.asm

if ERROR_CHECK
include cutilEC.asm
endif


if _NEWDESK

include cutilSpecialObj.asm

if _NEWDESKBA

include	utilEntryLevel.asm

endif	; _NEWDESKBA

endif	; _NEWDESK

end
