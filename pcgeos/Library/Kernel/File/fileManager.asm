COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File
FILE:		fileManager.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

DESCRIPTION:
	This file assembles the file code.

	See the spec for more information.

	$Id: fileManager.asm,v 1.1 97/04/05 01:11:40 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include fileEnum.def
include vm.def
include sem.def
include timer.def
include disk.def
include localize.def
include lmem.def	; for FileGetCurrentPathIDs
include object.def	; for FileGetCurrentPathIDs
include gcnlist.def	; for FILEFLUSHCHANGENOTIFICATIONS
include localize.def
include char.def

include Internal/geodeStr.def
include Internal/interrup.def
include Internal/fileStr.def

include	kernelFS.def

;--------------------------------------

include fileMacro.def		;FILE macros
include fileConstant.def	;FILE constants

;-------------------------------------

include fileVariable.def

;-------------------------------------

FSResident	segment
include fileEC.asm
include fileEnum.asm
include fileFile.asm
include fileIO.asm
include fileList.asm
include fileOpenClose.asm
include filePath.asm
include fileSync.asm
include fileUtils.asm
FSResident	ends

include	fileLink.asm

include fileC.asm

;-------------------------------------

kinit	segment
include fileInit.asm
kinit	ends

end
