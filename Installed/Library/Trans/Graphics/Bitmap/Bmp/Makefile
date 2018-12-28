#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = bmp
EXPORTC         = dib2bmp.c dibsave.c
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui
EXPORT          = exportManager.asm exportMain.asm
IMPORT          = importMain.asm importManager.asm
IMPORTC         = bmp2dib.c dibload.c
COMMON          = packbit.c fixshort.c hsiport.c dib.c
UI_TO_RDFS      = libExport.ui
OBJS            = dib2bmp.obj dibsave.obj bmp2dib.obj dibload.obj\
                  packbit.obj fixshort.obj hsiport.obj dib.obj
COMMON          = bmpGeode.def bmp.def bmpGlobal.def
MODULES         = Lib Export Import
CMODULES        = ExportC ImportC Common
SRCS            = $(EXPORTC) $(LIB) $(EXPORT) $(IMPORT) $(IMPORTC)\
                  $(COMMON) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = bmp

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
