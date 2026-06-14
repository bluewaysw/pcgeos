COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CMain
FILE:		cmainManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version

DESCRIPTION:
	This file assembles the CMain/ module of the desktop.

	$Id: cmainManager.asm,v 1.1 97/04/04 15:00:39 newdeal Exp $

------------------------------------------------------------------------------@

_CMain = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include drive.def				; for DS_TYPEs
include fileEnum.def				; for FileEnum stuff
include disk.def				; for Disk functions
include initfile.def
include font.def
include lmem.def
include gstring.def
include system.def				; for GetInfo time/date
						;	localization
include gcnlist.def				; for gcn stuff
include sysstats.def				; for SysGetInfo
include token.def				; for TokenRangeFlags struct
						;   used by TokenListTokens
UseLib	iacp.def

include Internal/geodeStr.def

include Internal/fileInt.def
include	Internal/fsd.def
include Internal/parallDr.def
include Internal/heapInt.def

include cmainConstant.def
include cmainVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include cmainChangeDir.asm

if _DOS_LAUNCHERS
include cmainCreateLauncher.asm
include cmainLauncher.asm
endif		; _DOS_LAUNCHERS

if _DISK_OPS
include cmainDiskOps.asm
endif

include cmainFileOps.asm

include cmainFolder.asm
include cmainInit.asm
include cmainMonikers.asm
include cmainLoadApp.asm
include cmainOpenClose.asm
include cmainProcess.asm

if _CONNECT_TO_REMOTE
include cmainZoomer.asm
endif

if _BMGR
include	mainInit.asm
endif

end


