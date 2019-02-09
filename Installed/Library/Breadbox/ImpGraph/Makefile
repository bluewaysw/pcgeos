#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = impgraph
ASMIMP          = impgif.asm asmimpManager.asm iimpgif.def
MAIN            = impgraph.goc awatcher.goc
IMPBMP          = impjpeg.h impgif.h ibcommon.h impfjpeg.goc impgifc.goc\
                  impjpeg.goc
UI_TO_RDFS      =
OBJS            = impgraph.obj awatcher.obj impfjpeg.obj impgifc.obj\
                  impjpeg.obj
COMMON          =
MODULES         = ASMIMP
CMODULES        = MAIN IMPBMP
SRCS            = $(ASMIMP) $(MAIN) $(IMPBMP) $(COMMON)
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
