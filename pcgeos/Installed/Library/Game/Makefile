#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = game
CONTENT         = contentGame.asm contentManager.asm
MAIN            = mainManager.asm
UI              = uiControl.asm uiHighScore.asm uiManager.asm uiStatus.asm\
                  uiHighScore.def uiHighScore.ui uiMain.ui uiStatus.ui\
                  uiStrings.ui
UTILS           = utilsManager.asm utilsRandom.asm
UI_TO_RDFS      = uiMain.ui
OBJS            =
COMMON          = gameConstant.def gameConstants.def gameGeode.def\
                  gameGlobal.def gameMacros.def random.def
MODULES         = Content Main UI Utils
CMODULES        =
SRCS            = $(CONTENT) $(MAIN) $(UI) $(UTILS) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = game

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
