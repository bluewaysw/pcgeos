#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = geowrite
UI              = uiTemplate.asm uiWriteDC.asm uiGifImage.asm uiPrint.asm\
                  uiManager.asm uiSuperIC.asm uiRowColumn.asm uiFixed.asm\
                  uiGifImage.def uiAppMoniker.ui uiRowColumn.ui\
                  uiHelpEdit.ui uiGraphics.ui uiTemplate.ui uiView.ui\
                  uiLayout.ui uiFixed.ui uiPageSetup.ui uiDocMoniker.ui\
                  uiEdit.ui uiDocument.ui uiPrint.ui uiManager.ui\
                  uiDisplay.ui uiAbbrev.ui uiText.ui uiMain.ui uiOptions.ui
DOCUMENT        = documentUserSection.asm documentHdrFtr.asm\
                  documentFlow.asm documentUtils.asm documentOpenClose.asm\
                  documentMisc.asm documentContent.asm\
                  documentMergeScrap.asm documentPrint.asm\
                  documentManager.asm documentBody.asm documentDisplay.asm\
                  documentManip.asm documentMasterPage.asm\
                  documentDocument.asm documentMerge.asm documentFrame.asm\
                  documentRegion.asm documentPageSetup.asm\
                  documentAttrMgr.asm documentVariable.asm\
                  documentSection.asm documentHead.asm documentArticle.asm\
                  documentPage.asm documentConvert.asm documentImpex.asm\
                  documentDraw.asm documentData.asm documentNotify.asm\
                  documentScroll.asm documentSearchSp.asm documentHelp.asm\
                  documentData.ui documentManager.ui
MAIN            = mainManager.asm mainAbbrev.asm mainApp.asm mainAppUI.asm\
                  mainProcess.asm
ARTICLE         = articleArticle.asm articleManager.asm
UI_TO_RDFS      = uiManager.ui documentManager.ui
OBJS            =
COMMON          = writeGrObjBody.def writeArticle.def writeProcess.def\
                  writeControls.def writeGeode.def writeSuperImpex.def\
                  writeConstant.def writeGrObjHead.def writeHdrFtr.def\
                  writeDisplay.def flowRegion.def writeBatchExport.def\
                  writeApplication.def writeDocument.def
MODULES         = UI Document Main Article
CMODULES        =
SRCS            = $(UI) $(DOCUMENT) $(MAIN) $(ARTICLE) $(COMMON)
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
