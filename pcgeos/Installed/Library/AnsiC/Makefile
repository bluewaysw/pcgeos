#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = AnsiC
ASM_TO_OBJS     = ansic.asm bcc_rtl.asm malloc_asm.asm memory_asm.asm\
                  stdio_asm.asm stdlib_asm.asm string_asm.asm
UI_TO_RDFS      =
SRCS            = ansic.asm bcc_rtl.asm malloc_asm.asm memory_asm.asm\
                  stdio_asm.asm stdlib_asm.asm string_asm.asm ansic.def\
                  ansicErrors.def ansicGeode.def scanf.c stdio.c string.c
OBJS            = ansic.obj bcc_rtl.obj malloc_asm.obj memory_asm.obj\
                  stdio_asm.obj stdlib_asm.obj string_asm.obj scanf.obj\
                  stdio.obj string.obj
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBOBJ_PRODS    = $(DEVEL_DIR)/Include/DBCS/$(GEODE).ldf
LIBNAME         = ansic

SYSMAKEFILE     = geode.mk

PRODUCTS	= DBCS
PRODUCT_LDFS    = DBCS

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
