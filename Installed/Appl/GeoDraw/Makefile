#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = GeoDraw
DOCUMENT        = BackupdocumentDocument.asm documentBody.asm\
                  documentConvert.asm documentDisplay.asm\
                  documentDocument.asm documentErrorCheck.asm\
                  documentManager.asm documentPrint.asm documentUtils.asm\
                  document12XConversionConstant.def documentConstant.def\
                  documentData.ui documentManager.ui
MAIN            = mainInit.asm mainManager.asm
UI              = uiDrawApplication.asm uiGifImage.asm uiMain.asm\
                  uiManager.asm uiTemplate.asm uiConstant.def\
                  uiGifImage.def uiDocument.ui uiLevel.ui uiMain.ui\
                  uiManager.ui uiTemplate.ui
UI_TO_RDFS      = DOCUMENTMANAGER.UI UIMANAGER.UI
OBJS            =
COMMON          = drawApplication.def drawConstant.def drawDisplay.def\
                  drawDocument.def drawGeode.def drawGlobal.def\
                  drawGrObjBody.def drawLevel.def
MODULES         = Document Main UI
CMODULES        =
SRCS            = $(DOCUMENT) $(MAIN) $(UI) $(COMMON)
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
