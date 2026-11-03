#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = spell
ET              = thes.asm etManager.asm thesC.asm etConstant.def\
                  etVariable.def
UI              = uiSpell.asm uiEditUserDict.asm thesCtrl.asm uiManager.asm\
                  uiSuggestList.asm uiConstant.def uiManager.ui thesCtrl.ui\
                  uiEditUserDict.ui uiSpell.ui
ICS             = icsManager.asm geos_localmem.asm spellStrings.asm\
                  geos_asmcalls.asm spellC.asm icsThread.asm spell.asm\
                  geos_opts.asm icsVariable.def icsConstant.def
OPEN            = spellopen.c openlex.h geosbridge.h
IH              = ihManager.asm ihCalls.asm ihConstants.def ihVariables.def
UI_TO_RDFS      = uiManager.ui
OBJS            = spellopen.obj
COMMON          = spellFeatures.h spellFea.h spellConstant.def
MODULES         = ET UI ICS IH
CMODULES        = Open
SRCS            = $(ET) $(UI) $(ICS) $(OPEN) $(IH) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = spell

PRODUCTS        = DBCS 

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

#if exists(DBCS/$(DEPFILE))
#include "DBCS/$(DEPFILE)"
#endif
