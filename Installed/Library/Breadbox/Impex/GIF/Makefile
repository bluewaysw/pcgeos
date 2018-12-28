#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = gif
XLAT            = impgif.h IMPGIF.goc EXPGIF.goc
API             = apiManager.asm gif.def
UI_TO_RDFS      = manager.ui
OBJS            = IMPGIF.obj EXPGIF.obj
COMMON          =
MODULES         = API
CMODULES        = XLAT
SRCS            = $(XLAT) $(API) $(COMMON)
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
