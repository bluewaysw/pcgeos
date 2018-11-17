COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Sound Library
FILE:		nsoundManager.asm

AUTHOR:		Todd Stumpf, Aug 3, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/03/92		Initial revision


DESCRIPTION:
		This is the manager file for the new sound library.
	This library is designed to provided a device-independent
	abstraction for any and all sound devices.  This includes
	both FM generation device (like the Sound Blaster) and DAC
	devices (like the Sound Source, as well as the Sound Blaster).

	$Id: soundManager.asm,v 1.1 97/04/07 10:46:24 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;			Include Files
;----------------------------------------------------------------------------

include	geos.def
include	file.def
include	geode.def
include	heap.def

ifdef	FULL_EXECUTE_IN_PLACE
include	Internal/xip.def		; must be included *before* resource.def
endif

include	resource.def
include	ec.def
include	object.def
include	initfile.def
include library.def
include thread.def
include	sem.def
include assert.def
include system.def
include	driver.def

include	Internal/interrup.def
include Internal/semInt.def
include	Internal/heapInt.def

include timer.def

;-----------------------------------------------------------------------------
;			Library's and Drivers
;-----------------------------------------------------------------------------
UseLib	  ui.def
UseDriver Internal/soundDrv.def
UseDriver Internal/strDrInt.def

DefLib	sound.def


include soundConstant.def
include soundError.def

;----------------------------------------------------------------------------
;			Code for Sound Library
;----------------------------------------------------------------------------

include		soundCommon.asm
include		soundResident.asm

include		soundVoiceAllocation.asm

include		soundC.asm

include		soundDriver.asm

include		soundMixer.asm













