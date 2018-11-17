COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		Main/mainManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/92		Initial version

DESCRIPTION:
	This file contains the process class for the Studio application.

	$Id: mainManager.asm,v 1.1 97/04/04 14:39:41 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include studioGeode.def
include studioConstant.def
include studioProcess.def
include studioDocument.def
include studioApplication.def
include flowRegion.def

include initfile.def
include timedate.def	; TimerGetDateAndTime
include Objects/Text/tCtrlC.def

include studioControl.def

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include mainProcess.asm
include mainApp.asm
include mainAppUI.asm
