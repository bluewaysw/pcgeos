#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = frotz
GEOS            = gmem.c gscreen.c gpic.c ui.goc ginput.goc gsample.goc\
                  gtext.goc itextlim.goh ctextlim.goh frotz.goh
HIGHLEV         = stream.c sound.c redirect.c variable.c table.c text.c\
                  input.c object.c random.c math.c
LOWLEV          = hotkey.c screen.c main.c process.c buffer.c files.c\
                  fastmem.c
UI_TO_RDFS      =
OBJS            = gmem.obj gscreen.obj gpic.obj ui.obj ginput.obj\
                  gsample.obj gtext.obj stream.obj sound.obj redirect.obj\
                  variable.obj table.obj text.obj input.obj object.obj\
                  random.obj math.obj hotkey.obj screen.obj main.obj\
                  process.obj buffer.obj files.obj fastmem.obj
COMMON          = frotz.h bboxreg.goh gfzicons.goh
MODULES         =
CMODULES        = Geos Highlev Lowlev
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
