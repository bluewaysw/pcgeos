#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = spool
Lib             = libC.asm libDriver.asm libIBM850Tab.asm libIBM860Tab.asm\
                  libIBM863Tab.asm libIBM865Tab.asm libIBM8bitTab.asm\
                  libInit.asm libLatin8bitTab.asm libManager.asm\
                  libMisc.asm libPaper.asm libPrintControl.asm\
                  libPrinter.asm libRoman8bitTab.asm libTables.asm\
                  libVentura8bitTab.asm libWindows8bitTab.asm\
                  libConstant.def libMacro.def libStrings.ui
Process         = processApp.asm processC.asm processControlPanel.asm\
                  processCustom.asm processDualThread.asm processError.asm\
                  processFile.asm processGraphics.asm processLabel.asm\
                  processLockQueue.asm processLoop.asm processManager.asm\
                  processNothing.asm processParallel.asm processPDL.asm\
                  processPort.asm processQueue.asm processRestart.asm\
                  processSerial.asm processTables.asm processText.asm\
                  processThread.asm processUtils.asm processConstant.def
UI              = uiC.asm uiManager.asm uiPageSizeCtrl.asm\
                  uiPrintControl.asm uiPrintControlUtils.asm\
                  uiSpoolSummons.asm uiSpoolSummonsExternal.asm\
                  uiSpoolSummonsPrint.asm uiSpoolSummonsUtils.asm\
                  uiConstant.def uiGlobal.def uiMain.ui uiPageSizeCtrl.ui\
                  uiPrintControl.ui uiPrinterControlPanel.ui uiSpoolApp.ui\
                  uiSpoolError.ui uiStrings.ui
UI_TO_RDFS      = libStrings.ui uiMain.ui
OBJS            =
COMMON          = spoolConstant.def spoolGeode.def spoolGlobal.def\
                  spoolVariable.def
MODULES         = Lib Process UI
CMODULES        =
SRCS            = $(Lib) $(Process) $(UI) $(COMMON)
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
