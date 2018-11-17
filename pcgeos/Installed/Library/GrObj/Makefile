##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GrObj -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 16:45:33 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	grobjec.geo		create an error-checking version
#	grobj.geo		create a non error-checking version
#	full			create both of the above, plus tags
#	part			create only the error-checking version
#	tags			create a tags file from all the sources
#	depend			generate source file dependencies
#
# DESCRIPTION:
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.geode
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: Makefile.geode,v 1.4 92/01/03 20:17:45 johnm Exp $
#
###############################################################################

GEODE           = grobj

ATTR            = attr.asm attrArrays.asm attrManager.asm attrMgr.asm\
                  attrStyle.asm attrStyleDesc.asm attrStyleMerge.asm\
                  attrStyleStrings.asm attrUtils.asm attrConstant.def\
                  attrVariable.def
BODY            = body.asm bodyAlign.asm bodyAttr.asm bodyC.asm\
                  bodyClass.asm bodyCutCopyPaste.asm bodyGroup.asm\
                  bodyImpex.asm bodyKeyboard.asm bodyManager.asm\
                  bodyMouse.asm bodyObjArray.asm bodyPriorityList.asm\
                  bodyProcessChildren.asm bodySelectionList.asm\
                  bodySortableArray.asm bodyTest.asm bodyTransfer.asm\
                  bodyUI.asm bodyUtils.asm bodyConstant.def
GROBJ           = grobj.asm grobjAccessBody.asm grobjBounds.asm grobjC.asm\
                  grobjClass.asm grobjDraw.asm grobjErrorUtils.asm\
                  grobjGeometry.asm grobjHandleUtils.asm grobjHandles.asm\
                  grobjInteractive.asm grobjManager.asm grobjMathUtils.asm\
                  grobjOther.asm grobjSelectionList.asm grobjTransfer.asm\
                  grobjTransformUtils.asm grobjUI.asm grobjUndo.asm\
                  grobjUtils.asm grobjVariable.def
GROBJVIS        = grobjBitmap.asm grobjSpline.asm grobjText.asm\
                  grobjVis.asm grobjvisManager.asm grobjVisConstant.def
GUARDIAN        = bitmapGuardian.asm editTextGuardian.asm\
                  grobjVisGuardian.asm grobjVisGuardianTransfer.asm\
                  guardianManager.asm multTextGuardian.asm\
                  splineGuardian.asm textGuardian.asm guardianConstant.def
HEAD            = head.asm headManager.asm headConstant.def
MAIN            = globalErrorUtils.asm globalUtils.asm largeRect.asm\
                  mainManager.asm strings.asm mainConstant.def\
                  mainMacro.def mainVariable.def
POINTER         = pointer.asm pointerManager.asm pointerRotate.asm\
                  pointerUtils.asm pointerZoom.asm
SHAPE           = arc.asm ellipse.asm group.asm groupTransfer.asm\
                  gstring.asm line.asm oldgroup.asm rect.asm\
                  roundedRect.asm shapeManager.asm shapeConstant.def\
                  shapeVariable.def
UI              = uiAlignControl.asm uiAlignToGridControl.asm\
                  uiArcControl.asm uiAreaAttrControl.asm\
                  uiAreaColorSelector.asm uiArrowheadControl.asm\
                  uiBackgroundColorSelector.asm uiBitmapToolControl.asm\
                  uiBothColorSelector.asm uiControlCommon.asm\
                  uiConvertControl.asm uiCreateControl.asm\
                  uiCustomDuplicateControl.asm uiCustomShapeControl.asm\
                  uiDefaultAttributesControl.asm uiDepthControl.asm\
                  uiDraftModeControl.asm uiDuplicateControl.asm\
                  uiEditSpecialControl.asm\
                  uiEndingGradientColorSelector.asm uiFlipControl.asm\
                  uiGrObjStyleSheetControl.asm uiGradientFillControl.asm\
                  uiGroupControl.asm uiHandleControl.asm\
                  uiHideShowControl.asm uiInstructionControl.asm\
                  uiLineAttrControl.asm uiLineColorSelector.asm\
                  uiLocksControl.asm uiManager.asm uiMoveInsideControl.asm\
                  uiNudgeControl.asm uiObscureAttrControl.asm\
                  uiPasteInsideControl.asm uiRotateControl.asm\
                  uiScaleControl.asm uiSkewControl.asm\
                  uiStartingGradientColorSelector.asm uiToolControl.asm\
                  uiTransformControl.asm uiGrObjConstant.def\
                  uiAlignControl.ui uiAlignToGridControl.ui uiArcControl.ui\
                  uiAreaAttrControl.ui uiAreaColorSelector.ui\
                  uiArrowheadControl.ui uiBackgroundColorSelector.ui\
                  uiBothColorSelector.ui uiConvertControl.ui\
                  uiCreateControl.ui uiCustomDuplicateControl.ui\
                  uiCustomShapeControl.ui uiDefaultAttributesControl.ui\
                  uiDepthControl.ui uiDraftModeControl.ui\
                  uiDuplicateControl.ui uiEditSpecialControl.ui\
                  uiEndingGradientColorSelector.ui uiFlipControl.ui\
                  uiGrObjStyleSheetControl.ui uiGradientFillControl.ui\
                  uiGroupControl.ui uiHandleControl.ui uiHideShowControl.ui\
                  uiInstructionControl.ui uiLineAttrControl.ui\
                  uiLineColorSelector.ui uiLocksControl.ui uiManager.ui\
                  uiMoveInsideControl.ui uiNudgeControl.ui\
                  uiObscureAttrControl.ui uiPasteInsideControl.ui\
                  uiRotateControl.ui uiScaleControl.ui uiSkewControl.ui\
                  uiStartingGradientColorSelector.ui uiToolControl.ui\
                  uiTransformControl.ui
OBJS            =

COMMON          = bodyKeeper.def grobjConstant.def grobjGeode.def\
                  grobjGlobal.def grobjMacro.def
LOBJS           =
MODULES         = Attr Body GrObj GrObjVis Guardian Head Main Pointer Shape\
                  UI
CMODULES        =
SRCS            = $(ATTR) $(BODY) $(GROBJ) $(GROBJVIS) $(GUARDIAN) $(HEAD)\
                  $(MAIN) $(POINTER) $(SHAPE) $(UI) $(COMMON)
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = grobj
SUBDIRS         = Art Attr Body DBCS GrObj GrObjVis Guardian Head Main\
                  PIZZA Pointer Shape UI XIP

#PRODUCTS	= DBCS

#include	<geos.mk>		# system directory definitions
#include	<gpath.mk>		# set search paths for files

MAKEFILE	= Makefile
SYSMAKEFILE	= geode.mk

#if exists(local.mk)
#	include	"local.mk"
#else
#	include	<$(SYSMAKEFILE)>
#endif

#if 	exists($(DEPFILE))
#include	"$(DEPFILE)"
#endif

#if 	exists(DBCS/$(DEPFILE))
#include	"DBCS/$(DEPFILE)"
#endif

# Allow mkmf
