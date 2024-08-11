#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = ntaker
DOCUMENT        = documentApplication.asm documentCode.asm\
                  documentDisplay.asm documentInk.asm documentManager.asm\
                  documentMisc.asm documentPrint.asm documentText.asm\
                  documentTitledButton.asm documentConstant.def\
                  documentVariable.def
UI              = uiManager.asm uiDocument.ui uiMain.ui
UI_TO_RDFS      = uiMain.ui
OBJS            =
COMMON          = ntakerApplication.def ntakerDisplay.def\
                  ntakerDocument.def ntakerErrors.def ntakerGeode.def\
                  ntakerGlobal.def ntakerInk.def ntakerProcess.def\
                  ntakerText.def ntakerTitledButton.def
MODULES         = Document UI
CMODULES        =
SRCS            = $(DOCUMENT) $(UI) $(COMMON)
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
