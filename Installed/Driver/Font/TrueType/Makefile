#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = truetype
FREETYPE        = ftxkern.c ttapi.c ttcache.c ttcalc.c ttcmap.c ttdebug.c\
                  ttextend.c ttfile.c ttgload.c ttinterp.c ttload.c\
                  ttmemory.c ttmutex.c ttobjs.c ttraster.c freetype.h\
                  ft_conf.h fterrid.h ftnameid.h ftxkern.h header.h\
                  ttcache.h ttcalc.h ttcmap.h ttconfig.h ttdebug.h\
                  ttengine.h ttextend.h ttfile.h ttgload.h ttinterp.h\
                  ttload.h ttmemory.h ttmutex.h ttobjs.h ttraster.h\
                  tttables.h tttags.h tttypes.h
MAIN            = mainManager.asm truetypeChars.asm truetypeEC.asm\
                  truetypeEscape.asm truetypeInit.asm truetypeMetrics.asm\
                  truetypePath.asm truetypeWidths.asm truetypeConstant.def\
                  truetypeMacros.def truetypeVariable.def
UI_TO_RDFS      =
OBJS            = ftxkern.obj ttapi.obj ttcache.obj ttcalc.obj ttcmap.obj\
                  ttdebug.obj ttextend.obj ttfile.obj ttgload.obj\
                  ttinterp.obj ttload.obj ttmemory.obj ttmutex.obj\
                  ttobjs.obj ttraster.obj
COMMON          =
MODULES         = Main
CMODULES        = FreeType
SRCS            = $(FREETYPE) $(MAIN) $(COMMON)
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
