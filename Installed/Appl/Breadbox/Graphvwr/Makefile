#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = graphvwr
GRAPH           = quant.c quant.h
ASMMOD          = asmmodManager.asm
MAIN            = bmpview.goc strings.goh
IMPBMP          = imppcx.h impbmp.h impgif.h ibcommon.h imp_bmp.h\
                  impgif.goc impbmp.goc imp_bmp.goc imppcx.goc
UI_TO_RDFS      =
OBJS            = quant.obj bmpview.obj impgif.obj impbmp.obj imp_bmp.obj\
                  imppcx.obj
COMMON          = token.goh bvdirmon.goh bvdirup.goh config.goh
MODULES         = ASMMOD
CMODULES        = GRAPH MAIN IMPBMP
SRCS            = $(GRAPH) $(ASMMOD) $(MAIN) $(IMPBMP) $(COMMON)
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
