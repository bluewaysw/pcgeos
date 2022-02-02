#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = truetype
MAIN            = truetypeEscape.asm mainManager.asm truetypeWidths.asm\
                  truetypeMetrics.asm truetypeInit.asm truetypeEC.asm\
                  truetypeChars.asm truetypePath.asm truetypeMacros.def\
                  truetypeVariable.def truetypeConstant.def
FREETYPE        = ttcache.c ttraster.c ttmutex.c ttgload.c ttextend.c\
                  ttcalc.c ttapi.c ttdebug.c ftxkern.c ttinterp.c ttload.c\
                  ttfile.c ttcmap.c ttobjs.c ttmemory.c ttcache.h ttcmap.h\
                  ttconfig.h freetype.h ttgload.h ttfile.h ttdebug.h\
                  header.h ttinterp.h ttload.h tttables.h ttobjs.h\
                  fterrid.h ttraster.h ttengine.h tttypes.h ttmutex.h\
                  ft_conf.h ttextend.h ftnameid.h ttcalc.h ftxkern.h\
                  ttmemory.h tttags.h
UI_TO_RDFS      =
OBJS            = ttcache.obj ttraster.obj ttmutex.obj ttgload.obj\
                  ttextend.obj ttcalc.obj ttapi.obj ttdebug.obj ftxkern.obj\
                  ttinterp.obj ttload.obj ttfile.obj ttcmap.obj ttobjs.obj\
                  ttmemory.obj
COMMON          =
MODULES         = Main
CMODULES        = FreeType
SRCS            = $(MAIN) $(FREETYPE) $(COMMON)
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
