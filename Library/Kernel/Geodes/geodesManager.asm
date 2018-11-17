COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodesManager.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------
   GLB	GeodeLoad		Load in and execute a GEODE


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file assembles the geode code.

	See the spec for more information.

	$Id: geodesManager.asm,v 1.1 97/04/05 01:12:14 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include lmem.def
include graphics.def
include win.def
include sem.def
include timer.def
include timedate.def
include vm.def
include Objects/metaC.def		;includes: object.def
include Objects/processC.def
include localize.def
include gcnlist.def
include alb.def				;AppLaunchBlock
					;(for GeodeLoad app cache algorithm)
include profile.def

include fileEnum.def
include Internal/interrup.def
include Internal/geodeStr.def		;includes: geode.def
include Internal/debug.def
include Internal/fileInt.def
include Internal/fileStr.def		;GeosFileHeader for XIP LoadGeodeLow


include Internal/patch.def


UseDriver Internal/videoDr.def
UseDriver Internal/fontDr.def

if SUPPORT_32BIT_DATA_REGS
.386					; enable 386 instructions
endif

;--------------------------------------

include geodesMacro.def		;GEODE macros
include geodesConstant.def	;GEODE constants

;-------------------------------------

include geodesVariable.def

;-------------------------------------

kcode	segment
include geodesErrorCheck.asm
include geodesSystem.asm
include geodesLoad.asm
include geodesHandle.asm
include geodesResource.asm
include geodesUtils.asm
include geodesDriver.asm
include geodesLibrary.asm
include geodesProcess.asm
include geodesEvent.asm
include geodesAccess.asm
include geodesPriv.asm
include geodesAnalysis.asm
include geodesPatch.asm
if USE_PATCHES
include geodesPatchXIP.asm
endif
kcode	ends

include geodesC.asm

;-------------------------------------

kinit	segment
include geodesInit.asm
kinit	ends

end
