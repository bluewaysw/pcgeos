#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = user
GEN             = genActive.asm genAppAttDet.asm genAppCommonIACP.asm\
                  genAppDocumentControl.asm genAppMisc.asm genBoolean.asm\
                  genBooleanGroup.asm genC.asm genClassBuild.asm\
                  genClassCommon.asm genClassMisc.asm genContent.asm\
                  genControl.asm genDataTrigger.asm genDisplay.asm\
                  genDisplayControl.asm genDocument.asm genDynamicList.asm\
                  genField.asm genFileSelector.asm genGadget.asm\
                  genGlyphDisplay.asm genInteraction.asm genItem.asm\
                  genItemGroup.asm genList.asm genListEntry.asm\
                  genManager.asm genPathUtils.asm genPenInputControl.asm\
                  genPrimary.asm genRange.asm genScreen.asm\
                  genSpinGadget.asm genSummons.asm genSystem.asm\
                  genTextDisplay.asm genTextEdit.asm genToolGroup.asm\
                  genTrigger.asm genUIDocumentControl.asm genUtils.asm\
                  genValue.asm genView.asm genConstant.def genMacro.def\
                  genVariable.def
HELP            = helpC.asm helpEC.asm helpFile.asm helpFirstAid.asm\
                  helpHelp.asm helpHistory.asm helpManager.asm helpName.asm\
                  helpPointerImage.asm helpRoutines.asm helpTextClass.asm\
                  helpTextUtils.asm helpUtils.asm helpControl.asm\
                  helpHint.asm helpLink.asm helpConstant.def helpText.def\
                  helpControl.ui
IACP            = iacpC.asm iacpConnect.asm iacpEC.asm iacpMain.asm\
                  iacpManager.asm iacpUtils.asm iacpConstant.def\
                  iacpVariable.def
PROC            = procClass.asm procManager.asm procUndo.asm procUtils.asm\
                  procConstant.def procMacro.def procVariable.def
TOKEN           = token.asm tokenC.asm tokenManager.asm tokenConstant.def\
                  tokenMacro.def tokenVariable.def
UI              = uiDispCtrl.asm uiEMOM.asm uiEMTrigger.asm uiEdit.asm\
                  uiManager.asm uiPage.asm uiTool.asm uiView.asm\
                  uiExpress.asm uiEMCInteraction.def toyMain.ui\
                  uiDispCtrl.ui uiEdit.ui uiExpress.ui uiManager.ui\
                  uiPage.ui uiTool.ui uiView.ui uiMain.ui
USER            = userDialog.asm userDocumentSave.asm userFlow.asm\
                  userFlowGrab.asm userFlowGrabLow.asm userFlowInput.asm\
                  userFlowMisc.asm userFlowUtils.asm userLibrary.asm\
                  userListUtils.asm userLog.asm userQuick.asm\
                  userScreen.asm userStrings.asm userTitleScreen.asm\
                  userTransfer.asm userUtils.asm userMain.asm\
                  userManager.asm userC.asm userConstant.def userMacro.def\
                  userVariable.def userManager.ui userPassword.ui
VIS             = visClass.asm visComp.asm visCompGeometry.asm\
                  visContentClass.asm visContentCommon.asm visEmpty.asm\
                  visGeometry.asm visIsoContent.asm visManager.asm\
                  visSpec.asm visSpecUtils.asm visUtilsClass.asm\
                  visUtilsResident.asm visConstant.def visMacro.def\
                  visVariable.def
UI_TO_RDFS      = helpControl.ui uiManager.ui userManager.ui
OBJS            =
COMMON          = uiGeode.def uiGlobal.def uiMacro.def uiConstant.def
MODULES         = Gen Help IACP Proc Token UI User Vis
CMODULES        =
SRCS            = $(GEN) $(HELP) $(IACP) $(PROC) $(TOKEN) $(UI) $(USER)\
                  $(VIS) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = ui

SYSMAKEFILE     = geode.mk

#include <geos.mk>
#include <gpath.mk>

#if exists(local.mk)
#include "local.mk"
#else
#include <$(SYSMAKEFILE)>
#endif

#if exists($(DEPFILE))
#include "$(DEPFILE)"
#endif
