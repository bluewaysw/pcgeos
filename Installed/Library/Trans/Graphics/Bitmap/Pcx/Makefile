#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = pcx
COMMON          = dib.c fixshort.c hsiport.c packbit.c
EXPORT          = exportMain.asm exportManager.asm
EXPORTC         = dib2pcx.c pcxsave.c
IMPORT          = importMain.asm importManager.asm
IMPORTC         = pcx2dib.c pcxload.c
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui
UI_TO_RDFS      = libExport.ui
OBJS            = dib.obj fixshort.obj hsiport.obj packbit.obj dib2pcx.obj\
                  pcxsave.obj pcx2dib.obj pcxload.obj
COMMON          = pcx.def pcxGeode.def pcxGlobal.def
MODULES         = Export Import Lib
CMODULES        = Common ExportC ImportC
SRCS            = $(COMMON) $(EXPORT) $(EXPORTC) $(IMPORT) $(IMPORTC)\
                  $(LIB) $(COMMON)
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
