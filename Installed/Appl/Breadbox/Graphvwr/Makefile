#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = graphvwr
ASMMOD          = asmmodManager.asm
GRAPH           = quant.c quant.h
IMPBMP          = ibcommon.h imp_bmp.h impbmp.h impgif.h imppcx.h\
                  impbmp.goc impgif.goc imppcx.goc imp_bmp.goc
MAIN            = bmpview.goc strings.goh
UI_TO_RDFS      =
OBJS            = quant.obj impbmp.obj impgif.obj imppcx.obj imp_bmp.obj\
                  bmpview.obj
COMMON          = bvdirmon.goh bvdirup.goh config.goh token.goh
MODULES         = ASMMOD
CMODULES        = GRAPH IMPBMP MAIN
SRCS            = $(ASMMOD) $(GRAPH) $(IMPBMP) $(MAIN) $(COMMON)
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
