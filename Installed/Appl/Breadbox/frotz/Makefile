#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = frotz
GEOS            = gmem.c gpic.c gscreen.c ginput.goc gsample.goc gtext.goc\
                  ui.goc ctextlim.goh frotz.goh itextlim.goh
HIGHLEV         = input.c math.c object.c random.c redirect.c sound.c\
                  stream.c table.c text.c variable.c
LOWLEV          = buffer.c fastmem.c files.c hotkey.c main.c process.c\
                  screen.c
UI_TO_RDFS      =
OBJS            = gmem.obj gpic.obj gscreen.obj ginput.obj gsample.obj\
                  gtext.obj ui.obj input.obj math.obj object.obj random.obj\
                  redirect.obj sound.obj stream.obj table.obj text.obj\
                  variable.obj buffer.obj fastmem.obj files.obj hotkey.obj\
                  main.obj process.obj screen.obj
COMMON          = frotz.h gfzicons.goh
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
