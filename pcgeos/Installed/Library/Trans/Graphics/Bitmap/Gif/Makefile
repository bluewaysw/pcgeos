#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Gif
COMMON          = dib.c fixshort.c hsiport.c packbit.c
EXPORT          = exportMain.asm exportManager.asm
EXPORTC         = dib2gif.c gifsave.c
IMPORT          = importMain.asm importManager.asm
IMPORTC         = gif2dib.c gifload.c
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui
UI_TO_RDFS      = LIBEXPORT.UI
OBJS            = dib.obj fixshort.obj hsiport.obj packbit.obj dib2gif.obj\
                  gifsave.obj gif2dib.obj gifload.obj
COMMON          = gif.def gifGeode.def gifGlobal.def
MODULES         = Export Import Lib
CMODULES        = Common ExportC ImportC
SRCS            = $(COMMON) $(EXPORT) $(EXPORTC) $(IMPORT) $(IMPORTC)\
                  $(LIB) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = gif

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
