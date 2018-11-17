COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UI
FILE:		uiManager.asm

AUTHOR:		Steve Scholl, Jan 30, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/30/92		Initial revision


DESCRIPTION:
	
	$Id: uiManager.asm,v 1.1 97/04/04 18:05:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include	grobjGeode.def


GrObjClassStructures	segment resource

	GrObjStyleSheetControlClass
	GrObjNudgeControlClass
	GrObjMoveInsideControlClass
	GrObjGroupControlClass
	GrObjDefaultAttributesControlClass
	GrObjDuplicateControlClass
	GrObjPasteInsideControlClass
	GrObjConvertControlClass
	GrObjLocksControlClass
	GrObjAlignDistributeControlClass
	GrObjAlignToGridControlClass
	GrObjRotateControlClass
	GrObjScaleControlClass

	GrObjCustomShapeControlClass
	GrObjHideShowControlClass
	GrObjDraftModeControlClass
	GrObjCustomDuplicateControlClass
;	GrObjArrowheadControlClass

	GrObjGradientFillControlClass
	GrObjObscureAttrControlClass
	GrObjInstructionControlClass
	GrObjTransformControlClass
	GrObjSkewControlClass
	GrObjToolControlClass
	GrObjBitmapToolControlClass
	GrObjToolItemClass
	GrObjHandleControlClass
	GrObjAreaAttrControlClass
	GrObjAreaColorSelectorClass
	GrObjBothColorSelectorClass
	GrObjBackgroundColorSelectorClass
	GrObjLineAttrControlClass
	GrObjLineColorSelectorClass
	GrObjDepthControlClass
	GrObjFlipControlClass
	GrObjCreateControlClass
	GrObjArcControlClass

	GrObjStartingGradientColorSelectorClass
	GrObjEndingGradientColorSelectorClass

GrObjClassStructures	ends


include uiGrObjConstant.def
include uiManager.rdef
include uiControlCommon.asm
include uiCreateControl.asm
include uiHideShowControl.asm
include uiDraftModeControl.asm
include uiCustomShapeControl.asm
;include uiArrowheadControl.asm
include uiCustomDuplicateControl.asm
include uiAreaColorSelector.asm
include uiBothColorSelector.asm
include uiStartingGradientColorSelector.asm
include uiEndingGradientColorSelector.asm
include uiGradientFillControl.asm
include uiBackgroundColorSelector.asm
include uiInstructionControl.asm
include uiObscureAttrControl.asm
include uiArcControl.asm
include uiNudgeControl.asm
include uiMoveInsideControl.asm
include uiGroupControl.asm
include uiDefaultAttributesControl.asm
include uiDuplicateControl.asm
include uiPasteInsideControl.asm
include uiConvertControl.asm
include uiLocksControl.asm
include uiAlignControl.asm
include uiAlignToGridControl.asm
include uiRotateControl.asm
include uiScaleControl.asm
include uiTransformControl.asm
include uiSkewControl.asm
include uiToolControl.asm
include uiBitmapToolControl.asm
include uiHandleControl.asm
include uiAreaAttrControl.asm
include uiLineAttrControl.asm
include uiLineColorSelector.asm
include uiDepthControl.asm
include uiFlipControl.asm
include uiGrObjStyleSheetControl.asm


