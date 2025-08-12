#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = png
API             = apiManager.asm png.def
XLAT            = exppng.goc imppng.goc
UI_TO_RDFS      = manager.ui
OBJS            = exppng.obj imppng.obj
COMMON          =
MODULES         = API
CMODULES        = Xlat
SRCS            = $(API) $(XLAT) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = png

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
