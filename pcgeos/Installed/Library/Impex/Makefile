#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = impex
MAIN            = mainC.asm mainEntry.asm mainExport.asm mainImport.asm\
                  mainManager.asm mainMetafile.asm mainThread.asm\
                  mainUtils.asm mainConstant.def mainVariable.def\
                  mainStrings.ui
MAP             = mapCtrl.asm mapManager.asm mapCtrl.ui
UI              = uiC.asm uiExportCtrl.asm uiExportCtrlRed.asm\
                  uiFormatList.asm uiFormatListLow.asm uiImportCtrl.asm\
                  uiImportCtrlRed.asm uiImportExport.asm uiManager.asm\
                  uiUtils.asm uiUtilsRed.asm uiConstant.def uiExportCtrl.ui\
                  uiExportCtrlRed.ui uiImpex.ui uiImportCtrl.ui\
                  uiImportCtrlRed.ui uiMain.ui
UI_TO_RDFS      = mainStrings.ui mapCtrl.ui uiMain.ui
OBJS            =
COMMON          = impexConstant.def impexGeode.def impexGlobal.def\
                  impexThreadProcess.def
MODULES         = Main Map UI
CMODULES        =
SRCS            = $(MAIN) $(MAP) $(UI) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = impex

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
