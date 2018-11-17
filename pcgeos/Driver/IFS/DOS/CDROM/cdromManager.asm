COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cdromManager.asm

AUTHOR:		Adam de Boor, Oct 30, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/30/91	Initial revision


DESCRIPTION:
	The thing what gets assembled.
		

	$Id: cdromManager.asm,v 1.1 97/04/10 11:55:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Common include files
;
include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include lmem.def
include system.def
include drive.def
include disk.def
include driver.def
include timedate.def
include localize.def
include sem.def
include timer.def
include initfile.def

include	Internal/semInt.def
include	Internal/interrup.def
include	Internal/dos.def
include Internal/fileInt.def
include	Internal/diskInt.def
include Internal/driveInt.def
include Internal/fsd.def
include Internal/log.def
include Internal/heapInt.def	; for ThreadPrivateData
include Internal/geodeStr.def	; for GeodeFileHeader
include Internal/fileStr.def	; for GeosFileHeader et al

DefDriver Internal/fsDriver.def
include Internal/dosFSDr.def

.ioenable

include cdromConstant.def

;------------------------------------------------------------------------------
;				Variables
;------------------------------------------------------------------------------

include cdromStrings.asm
include	cdromVariable.def

;------------------------------------------------------------------------------
;				Code
;------------------------------------------------------------------------------

include	cdromEntry.asm	; strategy & administrative gradoo
include	cdromDisk.asm		; DR_FS_DISK* implementation
include cdromInitExit.asm	; Initialization/exit routines.
include cdromSecondary.asm	; Support routines for primary to call
include cdromUtils.asm	; Random utility things.
include cdromHooks.asm
