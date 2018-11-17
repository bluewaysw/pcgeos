COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonStartup/CMain
FILE:		cmainManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/92		Initial version

DESCRIPTION:
	This file assembles the CMain/ module of startup.

	$Id: cmainManager.asm,v 1.1 97/04/04 16:52:20 newdeal Exp $

------------------------------------------------------------------------------@

_CMain = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cstartupGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------
ifdef ISTARTUP
include	sysstats.def
include thread.def
include Internal/parallDr.def
include Internal/heapInt.def
endif

include cmainConstant.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include cmainProcess.asm
include cmainStartupApplication.asm
include cmainStartupPrimary.asm

ifdef ISTARTUP
include cmainStartupRoomTrigger.asm
include mainIStartupField.asm
include mainTextMessages.asm
include mainQuiz.asm
endif

end
