#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = PEN
FILE            = fileAccess.asm fileC.asm fileManager.asm fileConstant.def\
                  fileMacro.def fileStrings.ui
INK             = inkBackspace.asm inkClassCommon.asm inkClassEdit.asm\
                  inkControlClass.asm inkCursors.asm inkManager.asm\
                  inkMouse.asm inkMP.asm inkSelection.asm inkConstant.def\
                  inkMacro.def inkControl.ui
UI_TO_RDFS      = FILESTRINGS.UI INKCONTROL.UI
OBJS            =
COMMON          = penConstant.def penGeode.def
MODULES         = File Ink
CMODULES        =
SRCS            = $(FILE) $(INK) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = pen

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
