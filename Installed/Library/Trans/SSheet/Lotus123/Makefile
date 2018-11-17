#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Lotus123
EXPORT          = export.asm exportExport.asm exportHeader.asm\
                  exportInfixToPostfix.asm exportManager.asm\
                  exportUtils.asm
IMPORT          = import.asm importCell.asm importManager.asm\
                  importPostfixToInfix.asm importTraverseTree.asm\
                  importUtils.asm
INIT            = init.asm initManager.asm
SHARED          = sharedCache.asm sharedDataChain.asm sharedFile.asm\
                  sharedManager.asm sharedCacheConstant.def
UI              = uiMain.asm uiManager.asm uiExport.ui uiImport.ui\
                  uiMain.ui
UI_TO_RDFS      = UIMAIN.UI
OBJS            =
COMMON          = lotus123Constant.def lotus123Geode.def lotus123Macro.def
MODULES         = Export Import Init Shared UI
CMODULES        =
SRCS            = $(EXPORT) $(IMPORT) $(INIT) $(SHARED) $(UI) $(COMMON)
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
