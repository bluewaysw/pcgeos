#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = impgraph
ASMIMP          = asmimpManager.asm impgif.asm iimpgif.def
IMPBMP          = impgif.h impjpeg.h ibcommon.h imppng.h impgifc.goc\
                  impjpeg.goc impfjpeg.goc imppng.goc
MAIN            = awatcher.goc impgraph.goc
UI_TO_RDFS      =
OBJS            = impgifc.obj impjpeg.obj impfjpeg.obj imppng.obj\
                  awatcher.obj impgraph.obj
COMMON          =
MODULES         = ASMIMP
CMODULES        = IMPBMP MAIN
SRCS            = $(ASMIMP) $(IMPBMP) $(MAIN) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = impgraph

PRODUCTS        = DBCS FJPEG 

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

#if exists(FJPEG/$(DEPFILE))
#include "FJPEG/$(DEPFILE)"
#endif
