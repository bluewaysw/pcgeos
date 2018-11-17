#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = styles
MANIP           = manipChange.asm manipCopy.asm manipDefine.asm\
                  manipDelete.asm manipDescribe.asm manipGet.asm\
                  manipManager.asm manipModify.asm manipSaveRecall.asm\
                  manipTrans.asm manipUtils.asm
UI              = uiManager.asm uiStyleSheet.asm uiManager.ui\
                  uiStyleSheet.ui
UI_TO_RDFS      = uiManager.ui
OBJS            =
COMMON          = stylesConstant.def stylesGeode.def stylesGlobal.def
MODULES         = Manip UI
CMODULES        =
SRCS            = $(MANIP) $(UI) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = styles

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
