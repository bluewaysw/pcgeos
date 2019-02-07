#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = conview
CTXTCONTROL     = ctxtcontrolControl.asm ctxtcontrolManager.asm\
                  ctxtcontrolManager.ui ctxtcontrolControl.ui
MAIN            = mainFile.asm mainManager.asm mainText.asm mainLink.asm\
                  mainUtils.asm mainContentPointer.asm mainCopy.asm\
                  mainNotify.asm mainStartEnd.asm mainBook.asm\
                  mainSearch.asm mainName.asm mainSpecialLink.asm\
                  mainHotspot.asm mainConstant.def mainContent.ui\
                  mainManager.ui mainStrings.ui
FINDCONTROL     = findcontrolManager.asm findcontrolControl.asm\
                  findcontrolControl.ui findcontrolManager.ui
NAVCONTROL      = navcontrolControl.asm navcontrolHistory.asm\
                  navcontrolManager.asm navcontrolUtils.asm\
                  navcontrolControl.ui navcontrolManager.ui
SENDCONTROL     = sendcontrolControl.asm sendcontrolManager.asm\
                  sendcontrolControl.ui sendcontrolManager.ui
UI_TO_RDFS      = ctxtcontrolManager.ui mainManager.ui\
                  findcontrolManager.ui navcontrolManager.ui\
                  sendcontrolManager.ui
OBJS            =
COMMON          = contentConstant.def contentGeode.def contentGlobal.def
MODULES         = CtxtControl Main FindControl NavControl SendControl
CMODULES        =
SRCS            = $(CTXTCONTROL) $(MAIN) $(FINDCONTROL) $(NAVCONTROL)\
                  $(SENDCONTROL) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = conview

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
