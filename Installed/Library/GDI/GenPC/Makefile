#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = genpc
ASM_TO_OBJS     = genpcMain.asm
UI_TO_RDFS      =
SRCS            = genpcKbd.asm genpcMain.asm genpcMouse.asm genpcPwr.asm\
                  ../Common/GDIPOINTER.ASM ../Common/GDIKEYBOARD.ASM\
                  ../Common/GDIPOWER.ASM ../Common/GDIEXT.ASM\
                  ../Common/GDIUTILS.ASM genpcConfig.def\
                  genpcConfigDBCS.def genpcConstant.def genpcMacro.def\
                  genpcVariable.def
OBJS            = genpcMain.obj
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = gdi

PRODUCTS        = win32 win32dbcs 

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

#if exists(WIN32DBCS/$(DEPFILE))
#include "WIN32DBCS/$(DEPFILE)"
#endif
