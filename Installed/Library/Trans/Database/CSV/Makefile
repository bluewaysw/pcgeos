#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = CSV
EXPORT          = exportFile.asm exportManager.asm
IMPORT          = importFile.asm importManager.asm
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui\
                  libImport.ui libMain.ui
UI_TO_RDFS      = LIBMAIN.UI
OBJS            =
COMMON          = csvConstant.def csvGlobal.def
MODULES         = Export Import Lib
CMODULES        =
SRCS            = $(EXPORT) $(IMPORT) $(LIB) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = csv

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
