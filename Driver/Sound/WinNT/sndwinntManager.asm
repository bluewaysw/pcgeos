COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS Sound Library
MODULE:		Standard Sound Driver
FILE:		standardManager.asm

AUTHOR:		Todd Stumpf, Aug 18, 1992

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/18/92		Initial revision


DESCRIPTION:
	The Standard Sound Driver contains all the routines necessary
	to use the sound systems that come standard with the base PC.
	This includes IBM's standard 1 voice PC speaker, the sound chip
	on the TANDY IBM clones and the CASIO chip for the palmtop zoomer.

        Also included is a version of the driver for the standard PC speaker
	to run under faster computers.  It interupts the PC speaker repeatedly
	changing sounds quick enough so that the user hears multiple sounds
	over the lowly PC speaker.  This is a seperate driver as it would
	unduly drag down a system which does not have enough CPU power to
	handle such frequent interupts.
		

	$Id: sndwinntManager.asm,v 1.1 97/04/18 11:57:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Include Files
;-----------------------------------------------------------------------------

include	geos.def
include	geode.def
include	resource.def
include	ec.def
include	driver.def
include	timer.def
include	heap.def
include localize.def
include assert.def
include initfile.def

include	Internal/interrup.def
include Internal/winnt.def

include	sndwinntPCChips.def
include sndwinntConstant.def

UseLib	sound.def

DefDriver Internal/soundDrv.def

;-----------------------------------------------------------------------------
;		Source files for driver
;-----------------------------------------------------------------------------

;	.ioenable

include	sndwinntStrategy.asm
include	pcCode.asm













