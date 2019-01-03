#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = geodraw
UI              = uiTemplate.asm uiMain.asm uiDrawApplication.asm\
                  uiGifImage.asm uiManager.asm uiGifImage.def\
                  uiConstant.def uiTemplate.ui uiLevel.ui uiDocument.ui\
                  uiManager.ui uiMain.ui
DOCUMENT        = documentUtils.asm documentPrint.asm documentManager.asm\
                  BackupdocumentDocument.asm documentBody.asm\
                  documentDisplay.asm documentDocument.asm\
                  documentConvert.asm documentErrorCheck.asm\
                  document12XConversionConstant.def documentConstant.def\
                  documentData.ui documentManager.ui
MAIN            = mainManager.asm mainInit.asm
UI_TO_RDFS      = uiManager.ui documentManager.ui
OBJS            =
COMMON          = drawDocument.def drawGrObjBody.def drawGlobal.def\
                  drawApplication.def drawLevel.def drawDisplay.def\
                  drawConstant.def drawGeode.def
MODULES         = UI Document Main
CMODULES        =
SRCS            = $(UI) $(DOCUMENT) $(MAIN) $(COMMON)
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
