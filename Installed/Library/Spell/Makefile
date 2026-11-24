#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = spell
ET              = etManager.asm thes.asm thesC.asm etConstant.def\
                  etVariable.def
ICS             = geos_asmcalls.asm geos_localmem.asm icsManager.asm\
                  icsThread.asm spell.asm spellC.asm spellStrings.asm\
                  icsConstant.def icsVariable.def
IH              = ihCalls.asm ihManager.asm ihConstants.def ihVariables.def
OPEN            = spellopen.c geosbridge.h openlex.h
UI              = thesCtrl.asm uiEditUserDict.asm uiManager.asm uiSpell.asm\
                  uiSuggestList.asm uiConstant.def thesCtrl.ui\
                  uiEditUserDict.ui uiManager.ui uiSpell.ui
UI_TO_RDFS      = uiManager.ui
OBJS            = spellopen.obj
COMMON          = spellConstant.def spellFea.h spellFeatures.h
MODULES         = ET ICS IH UI
CMODULES        = Open
SRCS            = $(ET) $(ICS) $(IH) $(OPEN) $(UI) $(COMMON)
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
