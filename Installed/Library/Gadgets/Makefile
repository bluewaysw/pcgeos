#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Gadgets
MAIN            = mainManager.asm mainVisMonikerUtil.asm
UI              = uiBatteryIndicator.asm uiCommon.asm uiDateInput.asm\
                  uiDateSelector.asm uiManager.asm uiRepeatTrigger.asm\
                  uiStopwatch.asm uiTimeInput.asm uiTimeInputParse.asm\
                  uiTimeInputText.asm uiTimer.asm uiDateInput.ui\
                  uiDateSelector.ui uiManager.ui uiStopwatch.ui\
                  uiStrings.ui uiTimeInput.ui uiTimer.ui
UI_TO_RDFS      = UIMANAGER.UI
OBJS            =
COMMON          = gadgetsConstant.def gadgetsGeode.def\
                  gadgetsVisMonikerUtil.def
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
