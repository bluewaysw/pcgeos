#
# Handcrafted, don't call mkmf!
#
GEODE           = idlepwr
LIBNAME		= power
PROTOCONST	= POWER
ASM_TO_OBJS     = IdlePower.asm
UI_TO_RDFS      =
SRCS            = IdlePower.asm
OBJS            = IdlePower.obj
LOBJS           =

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
