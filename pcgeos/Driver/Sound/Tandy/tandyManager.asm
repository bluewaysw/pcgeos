COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS Sound Library
MODULE:		Tandy 1000 Sound Driver
FILE:		tandyManager.asm

AUTHOR:		Todd Stumpf, Nov. 19th, 1992

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/19/92	Initial revision


DESCRIPTION:

	Manager file for the Tandy 1000 sound driver

	$Id: tandyManager.asm,v 1.1 97/04/18 11:57:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Include Files
;-----------------------------------------------------------------------------

include	geos.def
include	geode.def
include heap.def
include	resource.def
include	ec.def
include	driver.def
include	timer.def
include	sem.def

include	Internal/interrup.def


include tandyConstant.def

UseLib	sound.def

DefDriver Internal/soundDrv.def

;-----------------------------------------------------------------------------
;		Source files for driver
;-----------------------------------------------------------------------------

	.ioenable
include tandyErrors.def

include	tandyStrategy.asm
include tandyCodeFM.asm
include tandyCodeDAC.asm
