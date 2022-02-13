#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = compress
ASM_TO_OBJS     = compressManager.asm memory.asm
UI_TO_RDFS      =
SRCS            = compressIO.asm compressMain.asm compressManager.asm\
                  memory.asm memory_asm.asm compressConstant.def\
                  compressMacro.def compressVariable.def explode.c\
                  implode.c pklib.h
OBJS            = compressManager.obj memory.obj explode.obj implode.obj
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = compress

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
