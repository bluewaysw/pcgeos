#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = arabicwp
MAIN            = mainAppUI.asm mainAbbrev.asm mainApp.asm mainManager.asm\
                  mainProcess.asm
ARTICLE         = articleArticle.asm articleManager.asm
DOCUMENT        = documentPageSetup.asm documentOpenClose.asm\
                  documentAttrMgr.asm documentDocument.asm\
                  documentMerge.asm documentSearchSp.asm\
                  documentManager.asm documentPage.asm documentSection.asm\
                  documentData.asm documentNotify.asm documentMisc.asm\
                  documentUserSection.asm documentConvert.asm\
                  documentImpex.asm documentFrame.asm documentDraw.asm\
                  documentDisplay.asm documentVariable.asm\
                  documentArticle.asm documentPrint.asm documentManip.asm\
                  documentMergeScrap.asm documentFlow.asm\
                  documentMasterPage.asm documentHead.asm documentHelp.asm\
                  documentBody.asm documentRegion.asm documentUtils.asm\
                  documentScroll.asm documentHdrFtr.asm documentContent.asm\
                  documentData.ui documentManager.ui
UI              = uiGifImage.asm uiSuperIC.asm uiRowColumn.asm\
                  uiManager.asm uiPrint.asm uiTemplate.asm uiFixed.asm\
                  uiWriteDC.asm uiGifImage.def uiDocument.ui uiMain.ui\
                  uiEdit.ui uiTemplate.ui uiText.ui uiFixed.ui\
                  uiHelpEdit.ui uiAppMoniker.ui uiView.ui uiDisplay.ui\
                  uiLayout.ui uiManager.ui uiPrint.ui uiOptions.ui\
                  uiRowColumn.ui uiAbbrev.ui uiDocMoniker.ui uiGraphics.ui\
                  uiPageSetup.ui
UI_TO_RDFS      = documentManager.ui uiManager.ui
OBJS            =
COMMON          = writeHdrFtr.def writeArticle.def writeDocument.def\
                  writeGeode.def writeConstant.def writeProcess.def\
                  flowRegion.def writeSuperImpex.def writeDisplay.def\
                  writeGrObjBody.def writeApplication.def writeControls.def\
                  writeGrObjHead.def writeBatchExport.def
MODULES         = Main Article Document UI
CMODULES        =
SRCS            = $(MAIN) $(ARTICLE) $(DOCUMENT) $(UI) $(COMMON)
LOBJS           =

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
