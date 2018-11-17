COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		documentManager.asm

AUTHOR:		Gene Anderson, Feb 12, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/12/91		Initial revision

DESCRIPTION:
	This file contains GeoCalcDocument, a subclass of GenDocument

	$Id: documentManager.asm,v 1.1 97/04/04 15:48:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include geocalcGeode.def

include initfile.def
include system.def

include Objects/SSheet/sCtrlC.def



include geocalcDocument.def
include geocalcDocCtrl.def
include geocalcView.def
include geocalcDisplay.def
include geocalcSpreadsheet.def

include geocalcGrObjHead.def
include geocalcApplication.def
include geocalcDisplayGroup.def
include geocalcDocNote.def
include geocalcChartBody.def

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include documentClass.asm
include documentNew.asm
include documentManip.asm
include documentMessages.asm
include documentGraphic.asm
include documentChart.asm
include documentHead.asm
include documentSetup.asm
include documentImpex.asm
include documentMouse.asm
include documentCtrl.asm

if _SPLIT_VIEWS
include documentSplit.asm
endif
