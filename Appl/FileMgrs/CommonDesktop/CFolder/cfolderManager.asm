COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CFolder
FILE:		cfolderManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version
	brianc	8/16/89		changed to subclass of DeskVis

DESCRIPTION:
	This file assembles the CFolder/ module of the desktop.

	$Id: cfolderManager.asm,v 1.3 98/06/03 13:34:27 joon Exp $

------------------------------------------------------------------------------@

_CFolder = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

ND < include Internal/spoolInt.def	>	; for NDPrinterClass
ND < include Internal/fsd.def		>	; for NDDesktopClass and
						;   NDDriveClass

if _BMGR
UseDriver	Internal/powerDr.def		; for WarnIfNoKeyboard
endif

;-----------------------------------------------------------------------------
;	Include cdefinitions for this module
;-----------------------------------------------------------------------------

include thread.def				; for GeodeLoad priority
include system.def				; for DosExec
include gstring.def				; for GrPlayString flags
include fileEnum.def				; for FileEnum stuff
include vm.def					; for transfer stuff
include disk.def
include driver.def
include	initfile.def
UseLib	iacp.def
include	library.def
include Internal/heapInt.def
if GPC_MAIN_SCREEN_LINK
include startup.def
endif

include cfolderConstant.def
include cfolderVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include cfolderCode.asm
include cfolderActionObscure.asm
include cfolderMisc.asm

if _PRINT_CAPABILITY
include cfolderPrint.asm
endif

include cfolderDisplay.asm
include cfolderButton.asm
include cfolderRecord.asm
include cfolderSelect.asm
include cfolderOperations.asm
include cfolderUtils.asm
include	cfolderPlacement.asm
include cfolderIcon.asm
include cfolderFileChange.asm
include cfolderKeyboard.asm
include cfolderCursor.asm

if ERROR_CHECK
include cfolderEC.asm
endif

if _NEWDESK
;include cfolderNotify.asm            ;need to RCS this file from Geoworks...
include cfolderScan.asm
if not GPC_NO_PRINT
include cfolderPrinter.asm
endif
include cndfolderClass.asm
include cndfolderDriveClass.asm
include	cndfolderIcon.asm
include cndfolderWastebasket.asm
include cndfolderPopupMenu.asm
include cnddesktopfolderClass.asm

if _NEWDESKBA
include folderBA.asm
include folderTeacherClasses.asm
include folderStudentClasses.asm
include folderRoster.asm
include folderTeacherCourse.asm
include folderStudentHomeTView.asm
include folderTeacherHome.asm
;include folderStudentHome.asm
;include folderStudentCourse.asm
;include folderStudentHomeByTeacher.asm
;include folderOfficeHome.asm
include folderCourseware.asm
include	folderListFolder.asm
include folderUtil.asm
include folderPrinter.asm
endif	; if _NEWDESKBA

endif	; if _NEWDESK
