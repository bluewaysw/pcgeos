#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = gadgets
MAIN            = mainManager.asm mainVisMonikerUtil.asm
UI              = uiBatteryIndicator.asm uiTimeInputParse.asm\
                  uiTimeInput.asm uiDateInput.asm uiManager.asm\
                  uiCommon.asm uiDateSelector.asm uiTimer.asm\
                  uiStopwatch.asm uiTimeInputText.asm uiRepeatTrigger.asm\
                  uiDateSelector.ui uiDateInput.ui uiTimer.ui uiStrings.ui\
                  uiManager.ui uiTimeInput.ui uiStopwatch.ui
UI_TO_RDFS      = uiManager.ui
OBJS            =
COMMON          = gadgetsGeode.def gadgetsVisMonikerUtil.def\
                  gadgetsConstant.def
MODULES         = Main UI
CMODULES        =
SRCS            = $(MAIN) $(UI) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = gadgets

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
