#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Tif
COMMON          = dib.c fixshort.c hsiport.c packbit.c
COMMONC         = ccitt.c
EXPORT          = cpt.asm exportMain.asm exportManager.asm
EXPORTC         = cpt4.c dib2tif.c lzwc.c tiffsave.c tif.h
IMPORT          = importMain.asm importManager.asm
IMPORTC         = dcpt4.c lzw.c lzw1.c t4.c tif2dib.c tiffload.c
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui
UI_TO_RDFS      = LIBEXPORT.UI
OBJS            = dib.obj fixshort.obj hsiport.obj packbit.obj ccitt.obj\
                  cpt4.obj dib2tif.obj lzwc.obj tiffsave.obj dcpt4.obj\
                  lzw.obj lzw1.obj t4.obj tif2dib.obj tiffload.obj
COMMON          = tif.def tifGeode.def tifGlobal.def
MODULES         = Export Import Lib
CMODULES        = Common CommonC ExportC ImportC
SRCS            = $(COMMON) $(COMMONC) $(EXPORT) $(EXPORTC) $(IMPORT)\
                  $(IMPORTC) $(LIB) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = tif

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
