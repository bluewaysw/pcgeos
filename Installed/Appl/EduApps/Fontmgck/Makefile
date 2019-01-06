#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = fontmgck
FONTM           = fontm.goc font_ui.goh
NONLIN          = nonlin.goc
ASMTOOLS        = asmtoolsManager.asm
FONTDRVR        = fontdrvrManager.asm
CHARSET         = charset.goc
DRAWFONT        = drawfont.goc
UI_TO_RDFS      =
OBJS            = fontm.obj nonlin.obj charset.obj drawfont.obj
COMMON          = gsol.h charset.goh fontmagi.h
MODULES         = ASMTOOLS FONTDRVR
CMODULES        = FONTM NONLIN CHARSET DRAWFONT
SRCS            = $(FONTM) $(NONLIN) $(ASMTOOLS) $(FONTDRVR) $(CHARSET)\
                  $(DRAWFONT) $(COMMON)
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
