#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = TERM
FILE            = fileLocal.asm fileMain.asm fileManager.asm\
                  fileConstant.def fileImport.def fileInclude.def\
                  fileMacro.def fileVariable.def file.ui
FSM             = fsmMain.asm fsmMakeTables.asm fsmManager.asm\
                  fsmConstant.def fsmImport.def fsmInclude.def fsmMacro.def\
                  fsmVariable.def
MAIN            = dove.asm doveDs.asm mainConnection.asm mainEci.asm\
                  mainLocal.asm mainMain.asm mainManager.asm\
                  mainProtocol.asm mainTimedDialog.asm scriptEdit.asm\
                  termKeyMacro.asm mainConstant.def mainImport.def\
                  mainInclude.def mainMacro.def mainVariable.def main.ui
SCREEN          = screenLocal.asm screenMain.asm screenManager.asm\
                  screenConstant.def screenImport.def screenInclude.def\
                  screenMacro.def screenVariable.def
SCRIPT          = scriptLocal.asm scriptMain.asm scriptManager.asm\
                  scriptConstant.def scriptImport.def scriptInclude.def\
                  scriptMacro.def scriptVariable.def
SERIAL          = serialIn.asm serialMain.asm serialManager.asm\
                  serialScript.asm serialConstant.def serialImport.def\
                  serialInclude.def serialMacro.def serialScriptVar.def\
                  serialVariable.def
UTILS           = utilsLocal.asm utilsMain.asm utilsManager.asm\
                  utilsConstant.def utilsImport.def utilsInclude.def\
                  utilsMacro.def utilsVariable.def utils.ui
UI_TO_RDFS      = TERMUI.UI
OBJS            =
COMMON          = dove.def termConstant.def termInclude.def\
                  termKeyMacro.def termMacro.def termResource.def
MODULES         = File FSM Main Screen Script Serial Utils
CMODULES        =
SRCS            = $(FILE) $(FSM) $(MAIN) $(SCREEN) $(SCRIPT) $(SERIAL)\
                  $(UTILS) $(COMMON)
LOBJS           =

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
