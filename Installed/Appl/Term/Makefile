#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = term
Script          = scriptMain.asm scriptManager.asm scriptLocal.asm\
                  scriptConstant.def scriptMacro.def scriptImport.def\
                  scriptVariable.def scriptInclude.def
FSM             = fsmManager.asm fsmMakeTables.asm fsmMain.asm\
                  fsmImport.def fsmMacro.def fsmConstant.def\
                  fsmVariable.def fsmInclude.def
File            = fileManager.asm fileLocal.asm fileMain.asm\
                  fileInclude.def fileConstant.def fileImport.def\
                  fileMacro.def fileVariable.def file.ui
Screen          = screenManager.asm screenLocal.asm screenMain.asm\
                  screenMacro.def screenVariable.def screenConstant.def\
                  screenImport.def screenInclude.def
Utils           = utilsLocal.asm utilsMain.asm utilsManager.asm\
                  utilsImport.def utilsVariable.def utilsMacro.def\
                  utilsInclude.def utilsConstant.def utils.ui
Main            = mainMain.asm mainTimedDialog.asm mainManager.asm\
                  scriptEdit.asm dove.asm mainEci.asm mainProtocol.asm\
                  mainLocal.asm mainConnection.asm termKeyMacro.asm\
                  doveDs.asm mainConstant.def mainVariable.def\
                  mainInclude.def mainImport.def mainMacro.def main.ui
Serial          = serialIn.asm serialScript.asm serialManager.asm\
                  serialMain.asm serialVariable.def serialScriptVar.def\
                  serialConstant.def serialInclude.def serialImport.def\
                  serialMacro.def
UI_TO_RDFS      = termui.ui
OBJS            =
COMMON          = termMacro.def termKeyMacro.def termInclude.def\
                  termConstant.def termResource.def dove.def
MODULES         = Script FSM File Screen Utils Main Serial
CMODULES        =
SRCS            = $(Script) $(FSM) $(File) $(Screen) $(Utils) $(Main)\
                  $(Serial) $(COMMON)
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
