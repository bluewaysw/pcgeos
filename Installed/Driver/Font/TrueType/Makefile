#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = truetype
ADAPTER         = ttadapter.c ttcharmapper.c ttchars.c ttinit.c ttmetrics.c\
                  ttpath.c ttwidths.c ttadapter.h ttcharmapper.h ttchars.h\
                  ttinit.h ttmetrics.h ttwidths.h
FREETYPE        = ftxkern.c ttapi.c ttcache.c ttcalc.c ttcmap.c ttextend.c\
                  ttfile.c ttgload.c ttinterp.c ttload.c ttmemory.c\
                  ttmutex.c ttobjs.c ttraster.c freetype.h fterrid.h\
                  ftnameid.h ftxkern.h ft_conf.h ttcache.h ttcalc.h\
                  ttcmap.h ttconfig.h ttengine.h ttextend.h ttfile.h\
                  ttgload.h ttinterp.h ttload.h ttmemory.h ttmutex.h\
                  ttobjs.h ttraster.h tttables.h tttags.h tttypes.h
MAIN            = ansic_memory.asm ansic_runtime.asm mainManager.asm\
                  ttmemory_asm.asm\
                  truetypeChars.asm truetypeEC.asm truetypeEscape.asm\
                  truetypeInit.asm truetypeMetrics.asm truetypePath.asm\
                  truetypeWidths.asm truetypeConstant.def\
                  truetypeMacros.def truetypeVariable.def
UI_TO_RDFS      =
OBJS            = ttadapter.obj ttcharmapper.obj ttchars.obj ttinit.obj\
                  ttmetrics.obj ttpath.obj ttwidths.obj ftxkern.obj\
                  ttapi.obj ttcache.obj ttcalc.obj ttcmap.obj ttextend.obj\
                  ttfile.obj ttgload.obj ttinterp.obj ttload.obj\
                  ttmemory.obj ttmutex.obj ttobjs.obj ttraster.obj
COMMON          =
MODULES         = Main
CMODULES        = Adapter FreeType
SRCS            = $(ADAPTER) $(FREETYPE) $(MAIN) $(COMMON)
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
