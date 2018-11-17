#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = JPEG
GRAPH           = QUANT.C QUANT.H
MAIN            = mainManager.asm JPEG.DEF
PALETTE         = PALETTE.GOC PALETTE.GOH
XLAT            = EXPJPEG.GOC IMPJPEG.GOC
UI_TO_RDFS      = MANAGER.UI
OBJS            = QUANT.obj PALETTE.obj EXPJPEG.obj IMPJPEG.obj
COMMON          =
MODULES         = Main
CMODULES        = Graph Palette Xlat
SRCS            = $(GRAPH) $(MAIN) $(PALETTE) $(XLAT) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = jpeg

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
