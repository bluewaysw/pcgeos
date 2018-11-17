COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CLauncher
FILE:		clauncherManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/6/92		copied from utilManager.asm	

DESCRIPTION:
	This file assembles the Launcher/ module of the desktop.

	$Id: clauncherManager.asm,v 1.1 97/04/04 15:02:25 newdeal Exp $

------------------------------------------------------------------------------@

_CLauncher = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include fileEnum.def

if _DOS_LAUNCHERS
;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include cwFileSelectorClass.asm

endif

end





