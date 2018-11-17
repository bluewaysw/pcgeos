#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = graphvwr
ASMMOD          = asmmodManager.asm
GRAPH           = QUANT.C QUANT.H
IMPBMP          = IBCOMMON.H IMPBMP.H IMPGIF.H IMPPCX.H IMP_BMP.H\
                  IMPPCX.GOC IMPBMP.GOC IMPGIF.GOC IMP_BMP.GOC
MAIN            = BMPVIEW.GOC STRINGS.GOH
UI_TO_RDFS      =
OBJS            = QUANT.obj IMPPCX.obj IMPBMP.obj IMPGIF.obj IMP_BMP.obj\
                  BMPVIEW.obj
COMMON          = BVDIRMON.GOH BVDIRUP.GOH CONFIG.GOH TOKEN.GOH
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
