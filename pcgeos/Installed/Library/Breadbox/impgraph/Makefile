#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = impgraph
ASMIMP          = asmimpManager.asm IMPGIF.ASM IIMPGIF.DEF
IMPBMP          = IBCOMMON.H IMPGIF.H IMPJPEG.H IMPFJPEG.GOC IMPGIFC.GOC\
                  IMPJPEG.GOC
MAIN            = AWATCHER.GOC IMPGRAPH.GOC
UI_TO_RDFS      =
OBJS            = IMPFJPEG.obj IMPGIFC.obj IMPJPEG.obj AWATCHER.obj\
                  IMPGRAPH.obj
COMMON          =
MODULES         = ASMIMP
CMODULES        = IMPBMP MAIN
SRCS            = $(ASMIMP) $(IMPBMP) $(MAIN) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = impgraph

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
