#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = clp
EXPORTC         = dib2clp.c clpsave.c
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui
EXPORT          = exportManager.asm exportMain.asm
IMPORT          = importMain.asm importManager.asm
IMPORTC         = clpload.c clp2dib.c
COMMON          = packbit.c fixshort.c hsiport.c dib.c
UI_TO_RDFS      = libExport.ui
OBJS            = dib2clp.obj clpsave.obj clpload.obj clp2dib.obj\
                  packbit.obj fixshort.obj hsiport.obj dib.obj
COMMON          = clpGlobal.def clpGeode.def clp.def
MODULES         = Lib Export Import
CMODULES        = ExportC ImportC Common
SRCS            = $(EXPORTC) $(LIB) $(EXPORT) $(IMPORT) $(IMPORTC)\
                  $(COMMON) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = clp

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
