COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dosappl
FILE:		dosapplManager.asm

AUTHOR:		Cheng

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

DESCRIPTION:
	This file assembles the DosAppl management code.

	$Id: dosapplManager.asm,v 1.1 97/04/05 01:11:20 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include sem.def
include object.def
include input.def
include localize.def

include disk.def
include lmem.def
include char.def
include initfile.def
include gcnlist.def

include Internal/geodeStr.def
include Internal/dos.def
include Internal/interrup.def
include Internal/fileInt.def
include Internal/debug.def

UseDriver	Internal/taskDr.def
UseDriver	Internal/fsDriver.def

;--------------------------------------

include dosapplVariable.def
include dosapplConstant.def

;-------------------------------------

include dosapplLocate.asm
include dosapplMain.asm
include dosapplC.asm

kinit	segment
kinit	ends

end
