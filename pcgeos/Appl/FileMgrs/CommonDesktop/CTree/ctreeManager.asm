COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CTree
FILE:		ctreeManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version

DESCRIPTION:
	This file assembles the CTree/ module of the desktop.

	$Id: ctreeManager.asm,v 1.1 97/04/04 15:00:58 newdeal Exp $

------------------------------------------------------------------------------@

_CTree = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

;-----------------------------------------------------------------------------
;	Include cdefinitions for this module
;-----------------------------------------------------------------------------

if _TREE_MENU
include drive.def				; for DriveGetStatus, etc.
include fileEnum.def				; for FileEnum stuff
include vm.def					; for transfer stuff
include disk.def
include driver.def

include ctreeConstant.def
include ctreeVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include ctreeClass.asm
include ctreeScan.asm
include ctreeOutline.asm
include ctreeUtils.asm

endif		; if _TREE_MENU

end





