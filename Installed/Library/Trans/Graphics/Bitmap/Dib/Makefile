#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = dib
IMPORT          = importDIB.asm importManager.asm importMain.asm\
                  dibStrings.ui
EXPORT          = exportMain.asm exportDIB.asm exportManager.asm
UI_TO_RDFS      = dibStrings.ui
OBJS            =
COMMON          = dibConstant.def dibMacro.def dibGeode.def dibGlobal.def
MODULES         = Import Export
CMODULES        =
SRCS            = $(IMPORT) $(EXPORT) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = dib

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
