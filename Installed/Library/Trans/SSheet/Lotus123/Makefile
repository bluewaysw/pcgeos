#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = lotus123
IMPORT          = importUtils.asm importPostfixToInfix.asm\
                  importManager.asm import.asm importTraverseTree.asm\
                  importCell.asm
INIT            = init.asm initManager.asm
SHARED          = sharedFile.asm sharedCache.asm sharedManager.asm\
                  sharedDataChain.asm sharedCacheConstant.def
EXPORT          = exportExport.asm exportUtils.asm exportInfixToPostfix.asm\
                  exportHeader.asm exportManager.asm export.asm
UI              = uiMain.asm uiManager.asm uiImport.ui uiMain.ui\
                  uiExport.ui
UI_TO_RDFS      = uiMain.ui
OBJS            =
COMMON          = lotus123Constant.def lotus123Macro.def lotus123Geode.def
MODULES         = Import Init Shared Export UI
CMODULES        =
SRCS            = $(IMPORT) $(INIT) $(SHARED) $(EXPORT) $(UI) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = lot123ss

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
