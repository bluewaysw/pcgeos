#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = dbase3
LIB             = libFormat.asm libMain.asm libManager.asm libMain.ui\
                  libImport.ui libExport.ui
EXPORT          = exportFile.asm exportManager.asm
IMPORT          = importFile.asm importManager.asm
UI_TO_RDFS      = libMain.ui
OBJS            =
COMMON          = dbase3Global.def dbase3Constant.def
MODULES         = Lib Export Import
CMODULES        =
SRCS            = $(LIB) $(EXPORT) $(IMPORT) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = dbase3

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
