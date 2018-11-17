COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		Main/mainManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/92		Initial version

DESCRIPTION:
	This file contains the process class for the GeoWrite application.

	$Id: mainManager.asm,v 1.1 97/04/04 15:57:05 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include writeGeode.def
include writeConstant.def
include writeProcess.def
include writeDocument.def
include writeApplication.def
include writeArticle.def
if _BATCH_RTF
include writeBatchExport.def
include writeSuperImpex.def
endif
include flowRegion.def

include initfile.def
include timedate.def	; TimerGetDateAndTime
include Objects/Text/tCtrlC.def

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include mainProcess.asm
include mainApp.asm
include mainAppUI.asm

if _ABBREVIATED_PHRASE
include	mainAbbrev.asm
endif











