COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		UI/uiManager.asm

AUTHOR:		Gene Anderson, Feb  7, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/ 7/91		Initial revision

DESCRIPTION:
	

	$Id: uiManager.asm,v 1.1 97/04/04 15:48:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include geocalcGeode.def

include gstring.def
include system.def
include initfile.def

include Internal/videoDr.def
include Internal/heapInt.def

include graphics.def
include char.def
include input.def
include Objects/inputC.def
include Objects/styles.def
include Objects/Text/tCtrlC.def
include Objects/SSheet/sCtrlC.def

include geocalcApplication.def
include geocalcDocument.def
include geocalcDocCtrl.def
include geocalcDisplay.def
include geocalcSpreadsheet.def
include geocalcView.def
include	geocalcGrObjHead.def
include geocalcEditBar.def
include geocalcDisplayGroup.def
include geocalcDocNote.def
include geocalcChartBody.def

;---


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiMain.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include uiTarget.asm

include uiDisplay.asm
include uiGeoCalcEditBar.asm
include uiGeoCalcSpreadsheet.asm
include uiGeoCalcContent.asm
include uiGeoCalcView.asm
include uiGeoCalcApplication.asm
include uiGeoCalcDisplayGroup.asm
include uiGeoCalcChartBody.asm

;
; Force references for some error messages which are never referred to
; explicitly, but are instead referred to as an offset from another message.
;
ForceRef noNameGivenMessage
ForceRef noDefinitionGivenMessage
ForceRef nameAlreadyDefinedMessage
ForceRef badNameDefinitionMessage
ForceRef reallocFailedMessage

ForceRef nothingToPrintMessage
