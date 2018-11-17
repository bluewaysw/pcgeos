COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Object
FILE:		objectManager.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file assembles the Object code.

	See the spec for more information.

	$Id: objectManager.asm,v 1.1 97/04/05 01:14:37 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include lmem.def
include gcnlist.def
include vm.def
include	win.def
include sem.def
include char.def
include Objects/metaC.def		;includes object.def
include Objects/processC.def
include Objects/winC.def

include Internal/geodeStr.def
include Internal/objInt.def
include Internal/interrup.def
include Internal/timerInt.def		;for counting durations of operations
include gcnlist.def
include geoworks.def
include profile.def
;--------------------------------------

include objectMacro.def			;OBJECT macros
include objectConstant.def		;OBJECT constants

;-------------------------------------

include objectVariable.def

;-------------------------------------

kcode	segment
include objectErrorCheck.asm
include objectClass.asm
include objectUtils.asm
include objectDup.asm
include objectFile.asm
include objectReloc.asm
include objectState.asm
include objectMeta.asm
include objectShutdown.asm
include objectProcess.asm
include objectLinkable.asm
include objectComposite.asm
include objectVarData.asm
kcode	ends

include objectC.asm

;-------------------------------------

kinit	segment
include objectInit.asm
kinit	ends

end
