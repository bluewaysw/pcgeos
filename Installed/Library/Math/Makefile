#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = math
MAIN            = mainThread.asm mainMain.asm mainManager.asm
FLOAT           = floatFixed.asm floatTrans.asm floatHigh.asm\
                  floatFormat.asm floatConstants.asm floatConvert.asm\
                  floatGlobal.asm floatFloatToAscii.asm floatStack.asm\
                  floatC.asm floatDateTime.asm floatManager.asm\
                  floatMain.asm floatLow.asm floatComp.asm floatEC.asm\
                  floatConstant.def floatVariable.def floatMacro.def
UI              = uiFormatUtils.asm uiFormatInternalLow.asm uiManager.asm\
                  uiFormatC.asm uiFormatInternal.asm uiFormatGlobal.asm\
                  uiFormatMethods.asm uiMain.ui uiFormat.ui
UI_TO_RDFS      = uiMain.ui
OBJS            =
COMMON          = mathGeode.def mathConstants.def mathGlobals.def
MODULES         = Main Float UI
CMODULES        =
SRCS            = $(MAIN) $(FLOAT) $(UI) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = math

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
