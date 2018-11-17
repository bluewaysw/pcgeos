COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		DMA Driver
FILE:		dosrealManager.asm

AUTHOR:		Todd Stumpf, Nov. 15, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/15/92	Initial revision


DESCRIPTION:
	This is the manager file for the DMA driver.

	$Id: dosrealManager.asm,v 1.1 97/04/18 11:44:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Include Files
;-----------------------------------------------------------------------------

;
include	geos.def
include	resource.def
include	ec.def
include	driver.def
include	system.def

include	Internal/interrup.def

include DMAError.def

DefDriver Internal/DMADrv.def

;-----------------------------------------------------------------------------
;		Source files for driver
;-----------------------------------------------------------------------------
	.ioenable
include		dosrealDMA.asm
include		dosrealStrategy.asm
