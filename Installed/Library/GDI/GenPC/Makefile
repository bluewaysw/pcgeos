#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = genpc
ASM_TO_OBJS     = genpcMain.asm
UI_TO_RDFS      =
SRCS            = genpcMain.asm genpcMouse.asm genpcKbd.asm genpcPwr.asm\
                  ../Common/gdiPointer.asm ../Common/gdiKeyboard.asm\
                  ../Common/gdiPower.asm ../Common/gdiExt.asm\
                  ../Common/gdiUtils.asm genpcVariable.def genpcConfig.def\
                  genpcMacro.def genpcConfigDBCS.def genpcConstant.def
OBJS            = genpcMain.obj
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = gdi

PRODUCTS        = win32 

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

#if exists(win32/$(DEPFILE))
#include "win32/$(DEPFILE)"
#endif
