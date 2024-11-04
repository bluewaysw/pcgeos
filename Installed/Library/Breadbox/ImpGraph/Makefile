#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = impgraph
ASMIMP          = asmimpManager.asm impgif.asm iimpgif.def
IMPBMP          = impgif.h impjpeg.h ibcommon.h impfjpeg.goc impgifc.goc\
                  impjpeg.goc
MAIN            = awatcher.goc impgraph.goc
UI_TO_RDFS      =
OBJS            = impfjpeg.obj impgifc.obj impjpeg.obj awatcher.obj\
                  impgraph.obj
COMMON          =
MODULES         = ASMIMP
CMODULES        = IMPBMP MAIN
SRCS            = $(ASMIMP) $(IMPBMP) $(MAIN) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = impgraph

PRODUCTS        = DBCS 

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

#if exists(DBCS/$(DEPFILE))
#include "DBCS/$(DEPFILE)"
#endif
