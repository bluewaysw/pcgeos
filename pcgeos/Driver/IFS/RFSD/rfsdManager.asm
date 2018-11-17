COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		RFSD (Remot File System Driver)
FILE:		rfsdManager.asm

AUTHOR:		In Sik Rhee, Apr 14, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/14/92		Initial revision


DESCRIPTION:
	
	This is the glue for all the modules		

	$Id: rfsdManager.asm,v 1.1 97/04/18 11:46:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			    Include Files
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include	geode.def
include	resource.def
include	ec.def
include thread.def
include sem.def
include timer.def
include driver.def
include system.def
include drive.def
include disk.def
include initfile.def
include file.def
include Objects/processC.def
include gcnlist.def
include assert.def

UseDriver Internal/serialDr.def
DefDriver Internal/fsDriver.def
UseLib	net.def
UseLib	ui.def

include Internal/semInt.def
include Internal/dos.def
include Internal/fileInt.def
include Internal/diskInt.def
include Internal/driveInt.def
include Internal/fsd.def
include Internal/log.def
include Internal/fileStr.def
include	Internal/dosFSDr.def
include Internal/heapInt.def
include Internal/rfsd.def
include rfsdConstant.def
include rfsdVariable.def

;------------------------------------------------------------------------------
;			    Code
;------------------------------------------------------------------------------

include rfsd.asm
include rfsdDispatchProcess.asm
include	rfsdServer.asm
include rfsdStrings.asm
include	rfsdOpenClose.asm
include rfsdUtil.asm
include rfsdNotify.asm





