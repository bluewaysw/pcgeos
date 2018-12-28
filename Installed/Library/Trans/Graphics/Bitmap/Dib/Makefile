#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = dib
EXPORT          = exportDIB.asm exportManager.asm exportMain.asm
IMPORT          = importDIB.asm importMain.asm importManager.asm\
                  dibStrings.ui
UI_TO_RDFS      = dibStrings.ui
OBJS            =
COMMON          = dibGeode.def dibConstant.def dibMacro.def dibGlobal.def
MODULES         = Export Import
CMODULES        =
SRCS            = $(EXPORT) $(IMPORT) $(COMMON)
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
