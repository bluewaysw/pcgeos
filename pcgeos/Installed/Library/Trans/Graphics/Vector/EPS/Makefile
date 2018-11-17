#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = eps
EXPORT          = exportArc.asm exportBitmap.asm exportComments.asm\
                  exportEmbeddedGraphic.asm exportFontMap.asm\
                  exportFontTables.asm exportGString.asm exportHeader.asm\
                  exportMain.asm exportManager.asm exportMoreFonts.asm\
                  exportPath.asm exportProlog.asm exportPSCode.asm\
                  exportTables.asm exportText.asm exportType3Fonts.asm\
                  exportUtils.asm exportConstant.def exportMacro.def
IMPORT          = importMain.asm importManager.asm
LIB             = libFormat.asm libMain.asm libManager.asm
UI_TO_RDFS      =
OBJS            =
COMMON          = epsConstant.def epsGeode.def epsGlobal.def\
                  epsVariable.def
MODULES         = Export Import Lib
CMODULES        =
SRCS            = $(EXPORT) $(IMPORT) $(LIB) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = eps

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
