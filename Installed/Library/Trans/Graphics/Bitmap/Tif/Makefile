#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = tif
COMMONC         = ccitt.c
EXPORTC         = cpt4.c tiffsave.c lzwc.c dib2tif.c tif.h
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui
EXPORT          = cpt.asm exportManager.asm exportMain.asm
IMPORT          = importMain.asm importManager.asm
IMPORTC         = tif2dib.c tiffload.c dcpt4.c lzw.c t4.c lzw1.c
COMMON          = packbit.c fixshort.c hsiport.c dib.c
UI_TO_RDFS      = libExport.ui
OBJS            = ccitt.obj cpt4.obj tiffsave.obj lzwc.obj dib2tif.obj\
                  tif2dib.obj tiffload.obj dcpt4.obj lzw.obj t4.obj\
                  lzw1.obj packbit.obj fixshort.obj hsiport.obj dib.obj
COMMON          = tif.def tifGeode.def tifGlobal.def
MODULES         = Lib Export Import
CMODULES        = CommonC ExportC ImportC Common
SRCS            = $(COMMONC) $(EXPORTC) $(LIB) $(EXPORT) $(IMPORT)\
                  $(IMPORTC) $(COMMON) $(COMMON)
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
