#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = pcx
EXPORTC         = dib2pcx.c pcxsave.c
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui
EXPORT          = exportManager.asm exportMain.asm
IMPORT          = importMain.asm importManager.asm
IMPORTC         = pcx2dib.c pcxload.c
COMMON          = packbit.c fixshort.c hsiport.c dib.c
UI_TO_RDFS      = libExport.ui
OBJS            = dib2pcx.obj pcxsave.obj pcx2dib.obj pcxload.obj\
                  packbit.obj fixshort.obj hsiport.obj dib.obj
COMMON          = pcxGeode.def pcx.def pcxGlobal.def
MODULES         = Lib Export Import
CMODULES        = ExportC ImportC Common
SRCS            = $(EXPORTC) $(LIB) $(EXPORT) $(IMPORT) $(IMPORTC)\
                  $(COMMON) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = pcx

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
