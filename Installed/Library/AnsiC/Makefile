#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = ansic
ASM_TO_OBJS     = memory_asm.asm ansic.asm bcc_rtl.asm string_asm.asm\
                  stdlib_asm.asm malloc_asm.asm stdio_asm.asm
UI_TO_RDFS      =
SRCS            = memory_asm.asm ansic.asm bcc_rtl.asm string_asm.asm\
                  stdlib_asm.asm malloc_asm.asm stdio_asm.asm ansic.def\
                  ansicErrors.def ansicGeode.def string.c stdio.c scanf.c
OBJS            = memory_asm.obj ansic.obj bcc_rtl.obj string_asm.obj\
                  stdlib_asm.obj malloc_asm.obj stdio_asm.obj string.obj\
                  stdio.obj scanf.obj
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = ansic

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
