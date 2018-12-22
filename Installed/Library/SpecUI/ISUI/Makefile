##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Motif -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Gene Anderson, Mon Jan 26 22:50:05 PST 1998
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	motifec.geo		create an error-checking version
#	motif.geo		create a non error-checking version
#	full			create both of the above, plus tags
#	part			create only the error-checking version
#	tags			create a tags file from all the sources
#	depend			generate source file dependencies
#
# DESCRIPTION:
#	Makefile for a Specific User Interface geode.
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.ui
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id$
#
###############################################################################

GEODE           = isui

BUTTON          = cbuttonManager.asm copenButton.asm copenButtonBW.asm\
                  copenButtonBuild.asm copenButtonClass.asm\
                  copenButtonColor.asm copenButtonCommon.asm\
                  copenButtonData.asm copenData.asm copenMenuButton.asm\
                  cbuttonConstant.def cbuttonMacro.def cbuttonVariable.def
COMP            = ccompManager.asm copenContent.asm copenCtrl.asm\
                  copenCtrlClass.asm copenCtrlCommon.asm\
                  copenCtrlGeometry.asm copenGadgetArea.asm copenGroup.asm\
                  copenIsoContent.asm copenJustCtrl.asm copenMenuBar.asm\
                  copenMenuItemGroup.asm copenMenuSlots.asm copenPopout.asm\
                  copenReplyBar.asm copenTitleGroup.asm copenTriggerBar.asm\
                  ccompConstant.def ccompMacro.def ccompVariable.def
GADGET          = cgadgetManager.asm copenGadget.asm copenGadgetComp.asm\
                  copenGauge.asm copenGaugeData.asm copenGlyphDisplay.asm\
                  copenRange.asm copenRangeSection.asm copenSlider.asm\
                  copenSpinGadget.asm copenText.asm copenTextBuild.asm\
                  copenTextCommon.asm copenTextDisplay.asm\
                  copenTextEdit.asm copenValue.asm copenValueText.asm\
                  cgadgetConstant.def cgadgetMacro.def cgadgetVariable.def
ITEM            = citemBooleanGroup.asm citemCheckedItem.asm\
                  citemDynaList.asm citemItem.asm citemItemBW.asm\
                  citemItemClass.asm citemItemColor.asm citemItemCommon.asm\
                  citemItemGroup.asm citemItemGroupClass.asm\
                  citemItemGroupCommon.asm citemItemGroupVeryCommon.asm\
                  citemManager.asm citemScrollList.asm\
                  citemScrollableItem.asm citemConstant.def citemMacro.def\
                  citemVariable.def
MAIN            = cmainAdministrator.asm cmainAppDocumentControl.asm\
                  cmainCharTable.asm cmainCode.asm cmainDocDialog.asm\
                  cmainDocLowDisk.asm cmainDocObscure.asm\
                  cmainDocPhysical.asm cmainDocument.asm\
                  cmainDocumentCommon.asm cmainDocumentMisc.asm\
                  cmainDocumentNew.asm cmainDocumentRedwood.asm\
                  cmainHWRGrid.asm cmainKeyboard.asm cmainKeymap.asm\
                  cmainManager.asm cmainPenInputControl.asm\
                  cmainUIDocOperations.asm cmainUIDocumentControl.asm\
                  cmainUtils.asm cmainBigKeyKmp.def cmainConstant.def\
                  cmainHWRGridKmp.def cmainMacro.def cmainNumbersKmp.def\
                  cmainPenInputControl.def cmainPunctuationKmp.def\
                  cmainStandardKbd.def cmainStylusKbd.def cmainVariable.def\
                  cmainZoomerKbd.def cmainDocIcons.ui cmainLowDisk.ui\
                  cmainManager.ui cmainPenInputControl.ui\
                  cmainUIDocumentControl.ui
SPEC            = cspecAppDocumentControl.asm cspecApplication.asm\
                  cspecContent.asm cspecDisplay.asm cspecDisplayControl.asm\
                  cspecDocument.asm cspecField.asm cspecFileSelector.asm\
                  cspecGadget.asm cspecGlyphDisplay.asm\
                  cspecInteraction.asm cspecItem.asm cspecList.asm\
                  cspecListEntry.asm cspecManager.asm cspecPane.asm\
                  cspecPenInputControl.asm cspecPort.asm cspecPortGroup.asm\
                  cspecPrimary.asm cspecRange.asm cspecScreen.asm\
                  cspecSpinGadget.asm cspecSummons.asm cspecSystem.asm\
                  cspecText.asm cspecTextDisplay.asm cspecTextEdit.asm\
                  cspecTrigger.asm cspecUIDocumentControl.asm\
                  cspecValue.asm cspecConstant.def cspecMacro.def\
                  cspecVariable.def bmPin.ui cspecCUAS.ui cspecFile.ui\
                  cspecHelp.ui cspecLevels.ui cspecOpenLook.ui\
                  mkrDisplayWindowMenu.ui mkrExit.ui mkrExpressMenu.ui\
                  mkrHelp.ui mkrMaximize.ui mkrMinimize.ui mkrPin.ui\
                  mkrRestore.ui mkrWindowMenu.ui mkrWindowMenuButton.ui
UTILS           = copenAppAttDet.asm copenAppCommon.asm copenAppMisc.asm\
                  copenApplication.asm copenFileSelector.asm\
                  copenFileSelectorHigh.asm copenFileSelectorLow.asm\
                  copenFileSelectorMiddle.asm copenMoniker.asm\
                  copenSystem.asm copenTrace.asm copenUtils.asm\
                  cutilsManager.asm cutilsConstant.def cutilsMacro.def\
                  cutilsVariable.def
VIEW            = cviewManager.asm cviewPane.asm cviewPaneGeometry.asm\
                  cviewPaneScale.asm cviewPaneScroll.asm\
                  cviewPaneWindow.asm cviewPort.asm cviewPortGroup.asm\
                  cviewPortWindow.asm cviewScrollbar.asm\
                  cviewScrollbarData.asm cviewScrollbarSelect.asm\
                  cviewSimplePane.asm cviewSplitter.asm\
                  viewScrollbarDraw.asm cviewConstant.def cviewMacro.def\
                  cviewVariable.def
WIN             = cwinBase.asm cwinClass.asm cwinClassCUAS.asm\
                  cwinClassCommon.asm cwinClassCommonHigh.asm\
                  cwinClassCommonLow.asm cwinClassCommonMiddle.asm\
                  cwinClassMisc.asm cwinClassOther.asm cwinCommand.asm\
                  cwinData.asm cwinDialog.asm cwinDisplay.asm\
                  cwinDisplayControl.asm cwinDraw.asm cwinExcl.asm\
                  cwinField.asm cwinFieldCommon.asm cwinFieldData.asm\
                  cwinFieldInit.asm cwinFieldOther.asm\
                  cwinFieldUncommon.asm cwinGeometry.asm\
                  cwinGlyphDisplay.asm cwinManager.asm cwinMenu.asm\
                  cwinMenuedWin.asm cwinNotice.asm cwinPopup.asm\
                  cwinPtr.asm cwinScreen.asm cwinUtils.asm cwinWinIcon.asm\
                  winClassSpec.asm winDraw.asm cwinConstant.def\
                  cwinVariable.def
COMMON          = cConstant.def cGeode.def cGlobal.def cMacro.def
MODULES         = Button Comp Gadget Item Main Spec Utils View Win
LIBNAME         = spui
SRCS            = $(BUTTON) $(COMP) $(GADGET) $(ITEM) $(MAIN) $(SPEC)\
                  $(UTILS) $(VIEW) $(WIN) $(COMMON)

#include	<geos.mk>		# system directory definitions
#include	<gpath.mk>		# set search paths for files

MAKEFILE	= Makefile
SYSMAKEFILE	= geode.mk

#if exists(local.mk)
#	include	"local.mk"
#else
#	include	<$(SYSMAKEFILE)>
#endif

#
# Look in the common-ui module too.
#
-IFLAGS		+= -I../CommonUI -I$(INSTALL_DIR:H)/CommonUI \
		   -I../CommonUI/C$(.TARGET:R:T) \
		   -I$(INSTALL_DIR:H)/CommonUI/C$(.TARGET:R:T)

LINKFLAGS	+= -nll -f
		   
DEPFLAGS	+= -I../CommonUI -I$(INSTALL_DIR:H)/CommonUI \
		  -I../CommonUI/C$bi -I$(INSTALL_DIR:H)/CommonUI/C$bi

CSOURCE_PATHS	= $(MODULES:S|^|../CommonUI/C|g) \
		  $(MODULES:S|^|$(INSTALL_DIR:H)/CommonUI/C|g) \
		  ../CommonUI $(INSTALL_DIR:H)/CommonUI

.PATH.def	: $(CSOURCE_PATHS) 
.PATH.asm	: $(CSOURCE_PATHS)
.PATH.ui	: $(CSOURCE_PATHS)

#
# Include dependencies if they're around
#
#if 	exists($(DEPFILE))
#include	"$(DEPFILE)"
#endif

# Allow mkmf
