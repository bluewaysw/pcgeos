#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = gdi
LIBNAME         = kbd
PROTOCONST      = KEYBOARD
ASM_TO_OBJS     = gdiKeyboardManager.asm
UI_TO_RDFS      =
SRCS            = gdiKeyboardInit.asm gdiKeyboardManager.asm\
                  gdiKeyboardProcess.asm gdiKeyboardStrategy.asm\
                  gdiKeyboardConstant.def gdiKeyboardVariable.def
OBJS            = gdiKeyboardManager.obj
LOBJS           =

PRODUCTS        = DBCS

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

#if exists(DBCS/$(DEPFILE))
#include "DBCS/$(DEPFILE)"
#endif
