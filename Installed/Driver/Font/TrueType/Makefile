#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = truetype
MAIN            = truetypeEscape.asm ansic_runtime.asm mainManager.asm\
                  ttmemory_asm.asm truetypeWidths.asm ansic_stdlib.asm\
                  ansic_memory.asm truetypeMetrics.asm truetypeInit.asm\
                  truetypeEC.asm truetypeChars.asm truetypePath.asm\
                  truetypeMacros.def ansicGeode.def truetypeVariable.def\
                  truetypeConstant.def
ADAPTER         = ttchars.c ttinit.c ttmetrics.c ttcharmapper.c ttadapter.c\
                  ttwidths.c ttpath.c ttcharmapper.h ttpath.h ttchars.h\
                  ttwidths.h ttinit.h ttmetrics.h ttadapter.h
FREETYPE        = ttcache.c ttraster.c ttgload.c ttextend.c ttcalc.c\
                  ttapi.c ftxkern.c ttinterp.c ttload.c ttfile.c ttcmap.c\
                  ttobjs.c ttmemory.c ttcache.h ttcmap.h ttconfig.h\
                  freetype.h ttgload.h ttfile.h ttinterp.h ttload.h\
                  tttables.h ttobjs.h fterrid.h ttraster.h ttengine.h\
                  tttypes.h ft_conf.h ttextend.h ftnameid.h ttcalc.h\
                  ftxkern.h ttmemory.h tttags.h
UI_TO_RDFS      =
OBJS            = ttchars.obj ttinit.obj ttmetrics.obj ttcharmapper.obj\
                  ttadapter.obj ttwidths.obj ttpath.obj ttcache.obj\
                  ttraster.obj ttgload.obj ttextend.obj ttcalc.obj\
                  ttapi.obj ftxkern.obj ttinterp.obj ttload.obj ttfile.obj\
                  ttcmap.obj ttobjs.obj ttmemory.obj
COMMON          =
MODULES         = Main
CMODULES        = Adapter FreeType
SRCS            = $(MAIN) $(ADAPTER) $(FREETYPE) $(COMMON)
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
