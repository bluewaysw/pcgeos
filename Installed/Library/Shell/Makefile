#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = shell
BUFFER          = bufferC.asm bufferMain.asm bufferManager.asm\
                  bufferConstant.def
DIALOG          = dialogC.asm dialogMain.asm dialogManager.asm\
                  dialogConstant.def dialogGlobal.def dialogMacro.def\
                  dialogVariable.def dialog.ui
DIRINFO         = dirinfoEC.asm dirinfoMain.asm dirinfoManager.asm\
                  dirinfoConstant.def dirinfoMacro.def dirinfoVariable.def\
                  dirinfo.ui
FILE            = fileEC.asm fileMain.asm fileManager.asm fileConstant.def\
                  fileMacro.def fileVariable.def file.ui
FQT             = fqtMain.asm fqtManager.asm fqtConstant.def fqtMacro.def\
                  fqtVariable.def fqt.ui
ICON            = icondisplayMain.asm iconlistMain.asm iconlistUtil.asm\
                  iconMain.asm iconManager.asm iconConstant.def\
                  iconMacro.def iconVariable.def icon.ui
INIT            = initMain.asm initManager.asm initConstant.def\
                  initMacro.def initVariable.def init.ui
UTIL            = utilMain.asm utilManager.asm utilConstant.def\
                  utilMacro.def utilVariable.def util.ui
UI_TO_RDFS      = dialog.ui
OBJS            =
COMMON          = shellConstant.def shellGeode.def shellGlobal.def\
                  shellMacro.def shellVariable.def
MODULES         = Buffer Dialog DirInfo File FQT Icon Init Util
CMODULES        =
SRCS            = $(BUFFER) $(DIALOG) $(DIRINFO) $(FILE) $(FQT) $(ICON)\
                  $(INIT) $(UTIL) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = shell

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
