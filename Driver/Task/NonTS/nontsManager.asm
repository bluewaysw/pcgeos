COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nontsManager.asm

AUTHOR:		Adam de Boor, May  5, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 5/92		Initial revision


DESCRIPTION:
	The file what gets compiled.
		

	$Id: nontsManager.asm,v 1.1 97/04/18 11:58:17 newdeal Exp $

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
include initfile.def
include char.def
include Internal/heapInt.def	;For ThreadPrivateData 
if DBCS_PCGEOS
UseLib Internal/fsDriver.def
include sysstats.def
endif

DefDriver	Internal/taskDr.def

include Internal/fileInt.def
include Internal/dos.def
include Internal/fsd.def
include Internal/semInt.def

include nontsConstant.def
include nontsVariable.def
include nontsStrings.asm

include nontsEntry.asm
include nontsExec.asm
include nontsShutdown.asm
include nontsStart.asm
