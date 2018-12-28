#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = spell
UI              = uiSpell.asm thesCtrl.asm uiSuggestList.asm uiManager.asm\
                  uiEditUserDict.asm uiConstant.def uiSpell.ui thesCtrl.ui\
                  uiManager.ui uiEditUserDict.ui
IH              = ihCalls.asm ihManager.asm ihVariables.def ihConstants.def
ET              = thesC.asm thes.asm etManager.asm etVariable.def\
                  etConstant.def
ICS             = spellStrings.asm spell.asm icsManager.asm spellC.asm\
                  icsThread.asm icsConstant.def icsVariable.def
UI_TO_RDFS      = uiManager.ui
OBJS            =
COMMON          = spellFeatures.h spellConstant.def spellFea.h
MODULES         = UI IH ET ICS
CMODULES        =
SRCS            = $(UI) $(IH) $(ET) $(ICS) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = spell

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
