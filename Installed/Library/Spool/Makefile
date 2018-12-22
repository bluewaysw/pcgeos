#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = spool
UI              = uiPageSizeCtrl.asm uiPrintControlUtils.asm\
                  uiPrintControl.asm uiSpoolSummons.asm\
                  uiSpoolSummonsPrint.asm uiC.asm uiManager.asm\
                  uiSpoolSummonsExternal.asm uiSpoolSummonsUtils.asm\
                  uiConstant.def uiGlobal.def uiSpoolError.ui uiStrings.ui\
                  uiPrintControl.ui uiPrinterControlPanel.ui uiSpoolApp.ui\
                  uiPageSizeCtrl.ui uiMain.ui
Process         = processManager.asm processPort.asm processText.asm\
                  processParallel.asm processFile.asm processSerial.asm\
                  processLabel.asm processDualThread.asm\
                  processControlPanel.asm processNothing.asm\
                  processQueue.asm processThread.asm processLockQueue.asm\
                  processCustom.asm processLoop.asm processPDL.asm\
                  processTables.asm processGraphics.asm processC.asm\
                  processUtils.asm processApp.asm processRestart.asm\
                  processError.asm processConstant.def
Lib             = libDriver.asm libIBM865Tab.asm libIBM850Tab.asm\
                  libWindows8bitTab.asm libPrintControl.asm\
                  libVentura8bitTab.asm libTables.asm libManager.asm\
                  libIBM8bitTab.asm libPrinter.asm libPaper.asm\
                  libIBM860Tab.asm libRoman8bitTab.asm libC.asm libMisc.asm\
                  libInit.asm libLatin8bitTab.asm libIBM863Tab.asm\
                  libMacro.def libConstant.def libStrings.ui
UI_TO_RDFS      = uiMain.ui libStrings.ui
OBJS            =
COMMON          = spoolConstant.def spoolGlobal.def spoolVariable.def\
                  spoolGeode.def
MODULES         = UI Process Lib
CMODULES        =
SRCS            = $(UI) $(Process) $(Lib) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = spool

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
