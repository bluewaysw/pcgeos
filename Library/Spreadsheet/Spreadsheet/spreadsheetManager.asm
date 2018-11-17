COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetManager.asm

AUTHOR:		Gene Anderson, Feb 27, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/27/91		Initial revision

DESCRIPTION:
	

	$Id: spreadsheetManager.asm,v 1.1 97/04/07 11:13:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	spreadsheetGeode.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

SpreadsheetClassStructures	segment	resource

	SpreadsheetClass		;declare the class record

SpreadsheetClassStructures	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include	spreadsheetStyleToken.def
include spreadsheetRowArray.def
include	spreadsheetFileConstant.def
include spreadsheetMacro.def

include spreadsheetConstant.def
include spreadsheetVariable.asm

include graphicsText.asm

include spreadsheetInit.asm
include spreadsheetDraw.asm
include spreadsheetDrawUtils.asm
include spreadsheetUtils.asm
include spreadsheetEditBar.asm
include spreadsheetKeyboard.asm
include spreadsheetStyleToken.asm
include spreadsheetRowArray.asm
include spreadsheetCell.asm
include spreadsheetRange.asm
include spreadsheetMethodStyle.asm
include spreadsheetNotify.asm
include spreadsheetMethodMove.asm
include spreadsheetMethodSelect.asm
include	spreadsheetMethodMouse.asm
include spreadsheetGeometry.asm
include spreadsheetScroll.asm
include spreadsheetErrorCheck.asm

include	spreadsheetNameUtils.asm
include	spreadsheetNameList.asm
include	spreadsheetNameMethods.asm
include	spreadsheetNameCtrlInterface.asm
include	spreadsheetParse.asm
include	spreadsheetRecalc.asm
include spreadsheetFormulaCell.asm
include spreadsheetExprMethods.asm
include spreadsheetCellEdit.asm
include spreadsheetNotes.asm
include spreadsheetSpace.asm
include spreadsheetPrint.asm
include spreadsheetFormatInit.asm
include spreadsheetFormat.asm
include spreadsheetHeaderFooter.asm
include spreadsheetExtent.asm

include spreadsheetCutCopyConstant.def
include spreadsheetCutCopy.asm
;include spreadsheetCutCopyDataChain.asm
include spreadsheetCutCopyUtils.asm
include spreadsheetPaste.asm
include spreadsheetPasteTransTbl.asm
include spreadsheetPasteName.asm
include spreadsheetQuickMoveCopy.asm
include spreadsheetTextScrap.asm

include spreadsheetSearch.asm
include spreadsheetSort.asm

include spreadsheetFunctions.asm

include spreadsheetMethodFocus.asm
include spreadsheetPointer.asm

include spreadsheetChart.asm
include spreadsheetFill.asm
include spreadsheetRowColumn.asm

include spreadsheetOverlap.asm

include spreadsheetC.asm

global	SpreadsheetEntry:far

InitCode	segment	resource

SpreadsheetEntry	proc	far
	clc
	ret
SpreadsheetEntry	endp

InitCode	ends
