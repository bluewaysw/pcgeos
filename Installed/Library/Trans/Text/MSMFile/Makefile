#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = MSMFile
CACHE           = cacheCache.asm cacheManager.asm cacheConstant.def
EXPORT          = exportExport.asm exportManager.asm exportConstant.def
IMPORT          = importICF.asm importImport.asm importManager.asm\
                  importUtils.asm importConstant.def
UI_TO_RDFS      =
OBJS            =
COMMON          = msmfileGeode.def msmfileGlobal.def
MODULES         = Cache Export Import
CMODULES        =
SRCS            = $(CACHE) $(EXPORT) $(IMPORT) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = msmfile

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
