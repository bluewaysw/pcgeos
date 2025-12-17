#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = localize
DOCUMENT        = documentBuild.asm documentClipboard.asm documentCount.asm\
                  documentDB.asm documentDraw.asm documentImpExp.asm\
                  documentInitfile.asm documentKeyboard.asm\
                  documentList.asm documentManager.asm documentMisc.asm\
                  documentMnemonic.asm documentOpenClose.asm\
                  documentParse.asm documentPatch.asm documentPath.asm\
                  documentPrint.asm documentResource.asm documentSearch.asm\
                  documentSourceView.asm documentTransView.asm\
                  documentUtilities.asm documentUpdate.asm
MAIN            = mainBatch.asm mainList.asm mainManager.asm\
                  mainProcess.asm
TEXT            = textDraw.asm textManager.asm
UI              = uiManager.asm uiAppMoniker.ui uiDisplay.ui uiDocument.ui\
                  uiEdit.ui uiImpExp.ui uiMain.ui uiManager.ui uiPrint.ui\
                  uiProject.ui uiStrings.ui uiFile.ui
UI_TO_RDFS      = uiManager.ui
OBJS            =
COMMON          = localizeConstant.def localizeConstant.uih\
                  localizeContent.def localizeDocument.def\
                  localizeErrors.def localizeGeode.def localizeGlobal.def\
                  localizeLoc.def localizeMacro.def localizeProcess.def\
                  localizeText.def
MODULES         = Document Main Text UI
CMODULES        =
SRCS            = $(DOCUMENT) $(MAIN) $(TEXT) $(UI) $(COMMON)
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
