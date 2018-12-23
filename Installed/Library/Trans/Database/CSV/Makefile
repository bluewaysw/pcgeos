#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = csv
LIB             = libManager.asm libFormat.asm libMain.asm libMain.ui\
                  libImport.ui libExport.ui
IMPORT          = importFile.asm importManager.asm
EXPORT          = exportFile.asm exportManager.asm
UI_TO_RDFS      = libMain.ui
OBJS            =
COMMON          = csvGlobal.def csvConstant.def
MODULES         = Lib Import Export
CMODULES        =
SRCS            = $(LIB) $(IMPORT) $(EXPORT) $(COMMON)
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
