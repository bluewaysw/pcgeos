#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = FONTMGCK
ASMTOOLS        = asmToolsManager.asm
CHARSET         = CHARSET.GOC
DRAWFONT        = DRAWFONT.GOC
FONTDRVR        = fontDrvrManager.asm
FONTM           = FONTM.GOC FONT_UI.GOH
NONLIN          = NONLIN.GOC
UI_TO_RDFS      =
OBJS            = CHARSET.obj DRAWFONT.obj FONTM.obj NONLIN.obj
COMMON          = CHARSET.GOH FONTMAGI.H GSOL.H
MODULES         = ASMTOOLS FONTDRVR
CMODULES        = CHARSET DRAWFONT FONTM NONLIN
SRCS            = $(ASMTOOLS) $(CHARSET) $(DRAWFONT) $(FONTDRVR) $(FONTM)\
                  $(NONLIN) $(COMMON)
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
