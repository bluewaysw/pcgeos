#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = serial
LIBNAME         = serial
PROTOCONST      = SERIAL
ASM_TO_OBJS     = serialHighSpeed.asm serialInit.asm serialInt.asm\
                  serialMain.asm
UI_TO_RDFS      =
SRCS            = serialHighSpeed.asm serialInit.asm serialInt.asm\
                  serialMain.asm serial.def
OBJS            = serialHighSpeed.obj serialInit.obj serialInt.obj\
                  serialMain.obj
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf

PRODUCTS        = WIN32 DBCS

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

#if exists(WIN32/$(DEPFILE))
#include "WIN32/$(DEPFILE)"
#endif
