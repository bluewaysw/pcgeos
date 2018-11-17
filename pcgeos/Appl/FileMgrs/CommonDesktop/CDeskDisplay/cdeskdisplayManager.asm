COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CDeskDisplay
FILE:		cdeskdisplayManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version

DESCRIPTION:
	This file assembles the DeskDisplay/ module of the desktop.

	$Id: cdeskdisplayManager.asm,v 1.2 98/06/03 13:23:32 joon Exp $

------------------------------------------------------------------------------@

_CDeskDisplay = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include initfile.def
include vm.def					; for transfer stuff
include gstring.def				; for setting drive name
include disk.def				; for DiskGetDrive
include system.def				; for SysShutdown

include Internal/window.def		; for DesktApplicationEnsureActiveFT
include Internal/grWinInt.def		; for DesktApplicationEnsureActiveFT

include cdeskdisplayConstant.def
include cdeskdisplayVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------


include cdeskdisplayApplication.asm
include cdeskdisplayFileOp.asm
include cdeskdisplayDriveLetter.asm
include cdeskdisplayPathname.asm

if _GMGR
include cdeskdisplayClass.asm

if _ICON_AREA
include cdeskdisplayDirTool.asm
include cdeskdisplayDriveTool.asm
include cdeskdisplayToolArea.asm
include cdeskdisplayTool.asm
endif

if _FCAB       ; titled trigger code for GeoLauncher
include cdeskdisplayTitledTrigger.asm
endif		; if _FCAB
endif		; if _GMGR


if _NEWDESK
include cNDPrimaryClass.asm
include cNDDesktopPrimaryClass.asm
ifndef GPC_ONLY
if GPC_FOLDER_DIR_TOOLS
include cdeskdisplayDirTool.asm
include cdeskdisplayTool.asm
endif
endif

if _NEWDESKBA
include deskdisplayBAPrimary.asm
include deskdisplayBAInteraction.asm
endif		; if _NEWDESKBA
endif		; if _NEWDESK


end


