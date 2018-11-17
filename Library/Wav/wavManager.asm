COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		wavManager.asm

AUTHOR:		Steve Scholl

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/13/93		Initial revision

DESCRIPTION:
	

	$Id: wavManager.asm,v 1.1 97/04/07 11:51:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Library =1

;------------------------------------------------------------------------------
;			common include files
;------------------------------------------------------------------------------

include geos.def
include ec.def
include library.def
include lmem.def
include vm.def
include system.def
include resource.def
include	geode.def
include heap.def
include initfile.def
UseDriver Internal/strDrInt.def

;------------------------------------------------------------------------------
;			stuff we need
;------------------------------------------------------------------------------

include file.def
include timer.def
include thread.def

;
; BestSound NewWave
;

ifndef GPC_ONLY
UseLib	bsnwav.def
endif

;------------------------------------------------------------------------------
;			library stuff
;------------------------------------------------------------------------------

UseLib	geos.def
UseLib	sound.def

DefLib	wav.def

;------------------------------------------------------------------------------
;			Classes
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

include	wavConstants.def
include wavMacros.def

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include	wav.asm
include adpcm.asm
