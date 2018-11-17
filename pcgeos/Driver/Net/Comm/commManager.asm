COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Communication Driver
FILE:		CommManager.asm

AUTHOR:		In Sik Rhee, July 29, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/29/92		Initial revision


DESCRIPTION:
	
	This is the glue for all the modules		

	$Id: commManager.asm,v 1.1 97/04/18 11:48:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			    Include Files
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include	geode.def

ifidn	PRODUCT, <XIP>
include Internal/xip.def		; must be included *before* resource.def
endif

include	resource.def
include	ec.def
include thread.def
include sem.def
include timer.def
include driver.def
include system.def
include disk.def
include Objects/winC.def
include Objects/processC.def
UseDriver Internal/serialDr.def

UseLib  net.def

include Internal/semInt.def
include Internal/log.def
include commConstant.def
include commVariable.def
include commMacro.def

;------------------------------------------------------------------------------
;			    Code
;------------------------------------------------------------------------------

include comm.asm
include slip.asm
include commUtil.asm
include commStrings.asm
include commEC.asm
include commInit.asm
include commOpenClose.asm






