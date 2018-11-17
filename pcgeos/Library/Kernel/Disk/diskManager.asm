COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Disk
FILE:		diskManager.asm

AUTHOR:		Cheng

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

DESCRIPTION:
	This file assembles the disk management code.

	$Id: diskManager.asm,v 1.1 97/04/05 01:11:11 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include sem.def
include object.def

include disk.def
include localize.def

include Internal/geodeStr.def
include Internal/interrup.def

include	kernelFS.def

;--------------------------------------

include	diskVariable.def

;-------------------------------------

FSResident	segment
include diskConstant.def
include diskHigh.asm
include diskKernelHigh.asm
include diskEC.asm
FSResident	ends

include diskC.asm

kinit	segment
include	diskInit.asm
kinit	ends

end
