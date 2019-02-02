#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = ansic
ASM_TO_OBJS     = stdlib_asm.asm stdio_asm.asm string_asm.asm ansic.asm\
                  malloc_asm.asm memory_asm.asm wcc_rtl.asm
UI_TO_RDFS      =
SRCS            = stdlib_asm.asm stdio_asm.asm string_asm.asm ansic.asm\
                  malloc_asm.asm memory_asm.asm wcc_rtl.asm ansicErrors.def\
                  ansicGeode.def ansic.def scanf.c stdio.c string.c
OBJS            = stdlib_asm.obj stdio_asm.obj string_asm.obj ansic.obj\
                  malloc_asm.obj memory_asm.obj wcc_rtl.obj scanf.obj\
                  stdio.obj string.obj
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBOBJ_PRODS    = $(DEVEL_DIR)/Include/DBCS/$(GEODE).ldf
LIBNAME         = ansic

PRODUCTS        = DBCS 
PRODUCT_LDFS    = DBCS

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
