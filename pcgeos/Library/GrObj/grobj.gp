##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GrObj
# FILE:		grobj.gp
#
# AUTHOR:	Steve Scholl 11/89
#
#
# Parameters file for: grobj.geo
#
#	$Id: grobj.gp,v 1.1 97/04/04 18:07:43 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name grobj.lib
#
# Long name
#
longname "Graphic Object Library"
tokenchars	"GOBJ"
tokenid		0
#
# Specify geode type
#
type	library, single
#
# Import kernel routine definitions
#
library	geos
library ui
library bitmap
library spline
library color
library text
library styles
library ruler
library impex noload

#
# Define resources other than standard discardable code
#
#
nosort
resource GrObjInitCode				read-only code shared
resource GrObjMiscUtilsCode			read-only code shared
resource GrObjAttributesCode			read-only code shared
resource GrObjRequiredCode			read-only code shared
resource GrObjAlmostRequiredCode		read-only code shared
resource GrObjDrawCode				read-only code shared
resource GrObjExtInteractiveCode		read-only code shared
resource GrObjUIControllerCode			read-only code shared
resource GrObjRequiredInteractiveCode		read-only code shared
resource GrObjRequiredExtInteractiveCode	read-only code shared
resource GrObjRequiredExtInteractive2Code	read-only code shared
resource GrObjExtNonInteractiveCode		read-only code shared
resource GrObjStyleSheetCode			read-only code shared
resource GrObjTransferCode			read-only code shared
resource GrObjImpexCode				read-only code shared
resource GrObjGroupCode				read-only code shared
resource GrObjVisGuardianCode			read-only code shared
resource GrObjSplineGuardianCode		read-only code shared
resource GrObjSpecialGraphicsCode		read-only code shared
resource GrObjObscureExtNonInteractiveCode	read-only code shared
resource C_Code					read-only code shared
resource GrObjBitmapGuardianCode		read-only code shared
resource GrObjTextGuardianCode			read-only code shared
resource RectPlusCode				read-only code shared
resource GrObjUIControllerActionCode		read-only code shared
resource PointerImages 				read-only shared lmem
resource GrObjAreaAttr				lmem
resource GrObjLineAttr				lmem
resource GrObjStyle				lmem
resource GrObjCharAttr				lmem
resource GrObjTVCharAttr			lmem
resource GrObjParaAttr				lmem
resource GrObjTypeElements			lmem
resource GrObjGraphicElements			lmem
resource GrObjNameElements			lmem
resource GrObjTextStyle				lmem
resource Strings 				shared lmem read-only
resource ErrorStrings 				shared lmem read-only
resource GrObjStyleStrings 			lmem read-only shared
resource GrObjTCMonikerResource 		ui-object read-only shared
resource GrObjTMMonikerResource 		ui-object read-only shared
resource GrObjTCGAMonikerResource 		ui-object read-only shared
resource GrObjHideShowControlUI 		ui-object read-only shared
resource GrObjControlUIStrings 			lmem data read-only shared
resource GrObjDraftModeControlUI 		ui-object read-only shared
resource GrObjCustomDuplicateControlUI 		ui-object read-only shared
resource GrObjCreateControlUI 			ui-object read-only shared
resource GrObjCreateToolControlUI 		ui-object read-only shared
resource GrObjCustomShapeControlUI 		ui-object read-only shared
resource GrObjOtherColorMonikerResource 	ui-object read-only shared
resource GrObjOtherMonoMonikerResource 		ui-object read-only shared
resource GrObjGradientFillControlUI 		ui-object read-only shared
resource GrObjInstructionControlUI 		ui-object read-only shared
resource GrObjObscureAttrControlUI 		ui-object read-only shared
resource GrObjArcControlUI 			ui-object read-only shared
resource GrObjNudgeControlUI 			ui-object read-only shared
resource GrObjGroupControlUI 			ui-object read-only shared
resource GrObjGroupToolControlUI 		ui-object read-only shared
resource GrObjDefaultAttributesControlUI 	ui-object read-only shared
resource GrObjDefaultAttributesToolControlUI 	ui-object read-only shared
resource GrObjDuplicateControlUI 		ui-object read-only shared
resource GrObjDuplicateToolControlUI 		ui-object read-only shared
resource GrObjPasteInsideControlUI 		ui-object read-only shared
resource GrObjPasteInsideToolControlUI 		ui-object read-only shared
resource GrObjConvertControlUI 			ui-object read-only shared
resource GrObjConvertToolControlUI 		ui-object read-only shared
resource GrObjLocksControlUI 			ui-object read-only shared
resource GrObjAlignColorMonikerResource 	ui-object read-only shared
resource GrObjAlignMonoMonikerResource 		ui-object read-only shared
resource GrObjAlignDistributeControlUI 		ui-object read-only shared
resource GrObjAlignToGridColorMonikerResource 	ui-object read-only shared
resource GrObjAlignToGridMonoMonikerResource 	ui-object read-only shared
resource GrObjAlignToGridControlUI 		ui-object read-only shared
resource GrObjRotateControlUI 			ui-object read-only shared
resource GrObjScaleControlUI 			ui-object read-only shared
resource GrObjTransformControlUI 		ui-object read-only shared
resource GrObjSkewControlUI 			ui-object read-only shared
resource GrObjToolControlToolboxUI 		ui-object read-only shared
resource GrObjHandleControlUI 			ui-object read-only shared
resource GrObjAreaAttrControlUI 		ui-object read-only shared
resource GrObjLineAttrControlUI 		ui-object read-only shared
resource GrObjLineAttrControlToolboxUI 		ui-object read-only shared
resource GrObjDepthControlUI 			ui-object read-only shared
resource GrObjDepthToolControlUI 		ui-object read-only shared
resource GrObjFlipControlUI 			ui-object read-only shared
resource GrObjFlipToolControlUI 		ui-object read-only shared
resource GrObjStyleSheetControlUI 		ui-object read-only shared
resource GlobalErrorCode			read-only code shared
resource GrObjErrorCode				read-only code shared
resource GrObjClassStructures			fixed read-only shared

#resource GrObjArrowheadControlUI ui-object read-only shared

ifdef GP_FULL_EXECUTE_IN_PLACE
resource GrObjControlInfoXIP			read-only shared
endif


# Export Table

export GrObjBodyClass
export GrObjHeadClass

export GrObjClass

export PointerClass
export RotatePointerClass
export ZoomPointerClass
export GrObjAttributeManagerClass
export RectClass
export RoundedRectClass
export EllipseClass
export LineClass
export ArcClass
export GStringClass
export GroupClass
export GrObjVisGuardianClass

export GrObjBitmapClass
export BitmapGuardianClass

export GrObjSplineClass
export SplineGuardianClass

export	GrObjTextClass
export  TextGuardianClass
export  MultTextGuardianClass
export  EditTextGuardianClass

#
# Controller classes
#
export GrObjStyleSheetControlClass

export GrObjToolControlClass
export GrObjBitmapToolControlClass
export GrObjToolItemClass
export GrObjArcControlClass
export GrObjNudgeControlClass
export GrObjMoveInsideControlClass
export GrObjGroupControlClass
export GrObjDefaultAttributesControlClass
export GrObjConvertControlClass
export GrObjLocksControlClass
export GrObjDepthControlClass
export GrObjFlipControlClass
export GrObjCreateControlClass
export GrObjAlignDistributeControlClass
export GrObjAlignToGridControlClass
export GrObjRotateControlClass
export GrObjScaleControlClass
export GrObjHideShowControlClass
export GrObjDraftModeControlClass
export GrObjCustomShapeControlClass
export GrObjCustomDuplicateControlClass
#export GrObjArrowheadControlClass
export GrObjGradientFillControlClass
export GrObjDuplicateControlClass
export GrObjPasteInsideControlClass
export GrObjObscureAttrControlClass
export GrObjInstructionControlClass
export GrObjTransformControlClass
export GrObjSkewControlClass
export GrObjHandleControlClass
export GrObjAreaAttrControlClass
export GrObjAreaColorSelectorClass
export GrObjBothColorSelectorClass
export GrObjBackgroundColorSelectorClass
export GrObjLineAttrControlClass
export GrObjLineColorSelectorClass
export GrObjStartingGradientColorSelectorClass
export GrObjEndingGradientColorSelectorClass


# 
# Routines to export
#
export GrObjBodyProcessAllGrObjsInDrawOrderCommon
export GrObjBodyProcessSelectedGrObjsCommon

# 
# C stubs to export
#
export GROBJBODYPROCESSALLGROBJSINDRAWORDERCOMMON
export GROBJBODYPROCESSSELECTEDGROBJSCOMMON

# 
export	GrObjGetCurrentHandleSize
export 	GrObjDrawOneHandle

export GrObjGetNormalOBJECTDimensions
export GrObjCalcCorners
export GrObjGetCurrentNudgeUnits

export GrObjGetSpriteOBJECTDimensions
export GrObjGetAbsSpriteOBJECTDimensions
export GrObjResizeSpriteRelativeToSprite

export GROBJGETSPRITEOBJECTDIMENSIONS
export GROBJGETNORMALOBJECTDIMENSIONS
export GROBJCALCCORNERS
export GROBJRESIZESPRITERELATIVETOSPRITE
export GROBJGETABSSPRITEOBJECTDIMENSIONS
export GROBJGETBODYOD
export GROBJMESSAGETOBODY

export GrObjDraw32BitRect
export GrObjGetGrObjFullLineAttrElement
export GrObjBodyParseGString
export GrObjMessageToBody
export SplineGuardianTransformSplinePoints
export GrObjApplyNormalTransform
export GrObjTestSupportedTransferFormats

incminor

publish GROBJGETCURRENTHANDLESIZE
publish GROBJDRAWONEHANDLE
publish GROBJGETCURRENTNUDGEUNITS
publish GROBJDRAW32BITRECT
publish GROBJBODYPARSEGSTRING
publish SPLINEGUARDIANTRANSFORMSPLINEPOINTS
publish GROBJAPPLYNORMALTRANSFORM
publish GROBJTESTSUPPORTEDTRANSFERFORMATS
#
# XIP-enabled
#

incminor

publish GROBJBODYPROCESSSELECTEDGROBJSCOMMONPASSFLAG


incminor GrObjNewFor2_1
