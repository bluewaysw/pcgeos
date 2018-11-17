COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Drive
FILE:		driveManager.asm

AUTHOR:		Cheng

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

DESCRIPTION:
	This file assembles the drive management code.

	$Id: driveManager.asm,v 1.1 97/04/05 01:11:31 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include sem.def
include drive.def
include disk.def
include	localize.def

include Internal/interrup.def

include	kernelFS.def

;--------------------------------------

include driveConstant.def

;--------------------------------------

include	driveVariable.def

;-------------------------------------

FSResident	segment	resource
include driveHigh.asm
include driveEC.asm
FSResident	ends

include driveC.asm

kinit	segment
include driveInit.asm
kinit	ends

end
