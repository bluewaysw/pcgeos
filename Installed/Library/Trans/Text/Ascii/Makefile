#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = ascii
EXPORT          = exportMain.asm exportManager.asm
IMPORT          = importMain.asm importManager.asm importConstant.def
LIB             = libFormat.asm libManager.asm
UI_TO_RDFS      =
OBJS            =
COMMON          = asciiConstant.def asciiGeode.def
MODULES         = Export Import Lib
CMODULES        =
SRCS            = $(EXPORT) $(IMPORT) $(LIB) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = ascii

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
