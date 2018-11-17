#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = GIF
API             = APIManager.asm GIF.DEF
XLAT            = IMPGIF.H EXPGIF.GOC IMPGIF.GOC IMPGIF2.GOC
UI_TO_RDFS      = MANAGER.UI
OBJS            = EXPGIF.obj IMPGIF.obj IMPGIF2.obj
COMMON          =
MODULES         = API
CMODULES        = XLAT
SRCS            = $(API) $(XLAT) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = gif

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
