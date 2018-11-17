#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = ConView
CTXTCONTROL     = ctxtcontrolControl.asm ctxtcontrolManager.asm\
                  ctxtcontrolControl.ui ctxtcontrolManager.ui
FINDCONTROL     = findcontrolControl.asm findcontrolManager.asm\
                  findcontrolControl.ui findcontrolManager.ui
MAIN            = mainBook.asm mainContentPointer.asm mainCopy.asm\
                  mainFile.asm mainHotspot.asm mainLink.asm mainManager.asm\
                  mainName.asm mainNotify.asm mainSearch.asm\
                  mainSpecialLink.asm mainStartEnd.asm mainText.asm\
                  mainUtils.asm mainConstant.def mainContent.ui\
                  mainManager.ui mainStrings.ui
NAVCONTROL      = navcontrolControl.asm navcontrolHistory.asm\
                  navcontrolManager.asm navcontrolUtils.asm\
                  navcontrolControl.ui navcontrolManager.ui
SENDCONTROL     = sendcontrolControl.asm sendcontrolManager.asm\
                  sendcontrolControl.ui sendcontrolManager.ui
UI_TO_RDFS      = CTXTCONTROLMANAGER.UI FINDCONTROLMANAGER.UI\
                  MAINMANAGER.UI NAVCONTROLMANAGER.UI SENDCONTROLMANAGER.UI
OBJS            =
COMMON          = contentConstant.def contentGeode.def contentGlobal.def
MODULES         = CtxtControl FindControl Main NavControl SendControl
CMODULES        =
SRCS            = $(CTXTCONTROL) $(FINDCONTROL) $(MAIN) $(NAVCONTROL)\
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
