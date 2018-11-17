#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = FROTZ
GEOS            = GMEM.C GPIC.C GSCREEN.C ginput.goc GSAMPLE.GOC GTEXT.GOC\
                  ui.goc CTEXTLIM.GOH FROTZ.GOH ITEXTLIM.GOH
HIGHLEV         = INPUT.C MATH.C OBJECT.C RANDOM.C REDIRECT.C SOUND.C\
                  STREAM.C TABLE.C TEXT.C VARIABLE.C
LOWLEV          = BUFFER.C FASTMEM.C FILES.C HOTKEY.C MAIN.C PROCESS.C\
                  SCREEN.C
UI_TO_RDFS      =
OBJS            = GMEM.obj GPIC.obj GSCREEN.obj ginput.obj GSAMPLE.obj\
                  GTEXT.obj ui.obj INPUT.obj MATH.obj OBJECT.obj RANDOM.obj\
                  REDIRECT.obj SOUND.obj STREAM.obj TABLE.obj TEXT.obj\
                  VARIABLE.obj BUFFER.obj FASTMEM.obj FILES.obj HOTKEY.obj\
                  MAIN.obj PROCESS.obj SCREEN.obj
COMMON          = FROTZ.H BBOXREG.GOH
MODULES         =
CMODULES        = GEOS HIGHLEV LOWLEV
SRCS            = $(GEOS) $(HIGHLEV) $(LOWLEV) $(COMMON)
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
