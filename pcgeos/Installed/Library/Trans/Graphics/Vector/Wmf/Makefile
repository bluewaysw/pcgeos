#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Wmf
EXPORT          = exportMain.asm exportManager.asm exportWMF.asm
IMPORT          = importMain.asm importManager.asm importWMF.asm
UI_TO_RDFS      =
OBJS            =
COMMON          = wmf.def wmfConstant.def wmfGeode.def wmfGlobal.def\
                  wmfMacro.def
MODULES         = Export Import
CMODULES        =
SRCS            = $(EXPORT) $(IMPORT) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = wmf

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
