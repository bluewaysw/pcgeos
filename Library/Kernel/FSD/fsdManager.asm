COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Kernel -- FSD
FILE:		fsdManager.asm

AUTHOR:		Adam de Boor, July 18, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb   07/18/91        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: fsdManager.asm,v 1.1 97/04/05 01:17:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_FSD = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	kernelGeode.def

include sem.def
include localize.def
include gcnlist.def
include object.def

include Internal/interrup.def
include Internal/geodeStr.def
include Internal/fileStr.def
include Internal/timerInt.def	; For counting durations of operations

include kernelFS.def
;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include fsdConstant.def
include	fsdVariable.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------

include fsdDisk.asm		; Disk-related FSD support code
include fsdDrive.asm		; Drive-related FSD support code
include fsdFile.asm		; File-related FSD support code
include fsdSkeleton.asm		; Skeleton filesystem driver.
include fsdUtils.asm		; Various utility routines
include fsdEC.asm		; Error-checking routines

include	fsdInit.asm

end
