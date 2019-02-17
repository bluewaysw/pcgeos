#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = localize
MAIN            = mainList.asm mainBatch.asm mainManager.asm\
                  mainProcess.asm
TEXT            = textDraw.asm textManager.asm
DOCUMENT        = documentOpenClose.asm documentResource.asm\
                  documentImpExp.asm documentTransView.asm documentDB.asm\
                  documentSourceView.asm documentMnemonic.asm\
                  documentInitfile.asm documentManager.asm\
                  documentPatch.asm documentMisc.asm documentList.asm\
                  documentPath.asm documentDraw.asm documentClipboard.asm\
                  documentCount.asm documentBuild.asm documentPrint.asm\
                  documentUtilities.asm documentUpdate.asm\
                  documentParse.asm documentSearch.asm documentKeyboard.asm
UI              = uiManager.asm uiDocument.ui uiMain.ui uiEdit.ui uiFile.ui\
                  uiStrings.ui uiImpExp.ui uiAppMoniker.ui uiDisplay.ui\
                  uiManager.ui uiPrint.ui uiProject.ui
UI_TO_RDFS      = uiManager.ui
OBJS            =
COMMON          = localizeGeode.def localizeConstant.def localizeErrors.def\
                  localizeGlobal.def localizeMacro.def localizeLoc.def\
                  localizeText.def localizeProcess.def localizeContent.def\
                  localizeConstant.uih localizeDocument.def
MODULES         = Main Text Document UI
CMODULES        =
SRCS            = $(MAIN) $(TEXT) $(DOCUMENT) $(UI) $(COMMON)
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
