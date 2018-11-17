#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Bmp
COMMON          = dib.c fixshort.c hsiport.c packbit.c
EXPORT          = exportMain.asm exportManager.asm
EXPORTC         = dib2bmp.c dibsave.c
IMPORT          = importMain.asm importManager.asm
IMPORTC         = bmp2dib.c dibload.c
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui
UI_TO_RDFS      = LIBEXPORT.UI
OBJS            = dib.obj fixshort.obj hsiport.obj packbit.obj dib2bmp.obj\
                  dibsave.obj bmp2dib.obj dibload.obj
COMMON          = bmp.def bmpGeode.def bmpGlobal.def
MODULES         = Export Import Lib
CMODULES        = Common ExportC ImportC
SRCS            = $(COMMON) $(EXPORT) $(EXPORTC) $(IMPORT) $(IMPORTC)\
                  $(LIB) $(COMMON)
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
