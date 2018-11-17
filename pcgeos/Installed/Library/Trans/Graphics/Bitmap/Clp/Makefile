#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Clp
COMMON          = dib.c fixshort.c hsiport.c packbit.c
EXPORT          = exportMain.asm exportManager.asm
EXPORTC         = clpsave.c dib2clp.c
IMPORT          = importMain.asm importManager.asm
IMPORTC         = clp2dib.c clpload.c
LIB             = libFormat.asm libMain.asm libManager.asm libExport.ui
UI_TO_RDFS      = LIBEXPORT.UI
OBJS            = dib.obj fixshort.obj hsiport.obj packbit.obj clpsave.obj\
                  dib2clp.obj clp2dib.obj clpload.obj
COMMON          = clp.def clpGeode.def clpGlobal.def
MODULES         = Export Import Lib
CMODULES        = Common ExportC ImportC
SRCS            = $(COMMON) $(EXPORT) $(EXPORTC) $(IMPORT) $(IMPORTC)\
                  $(LIB) $(COMMON)
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
