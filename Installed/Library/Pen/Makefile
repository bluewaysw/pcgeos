#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = pen
INK             = inkCursors.asm inkBackspace.asm inkSelection.asm\
                  inkMP.asm inkControlClass.asm inkClassEdit.asm\
                  inkManager.asm inkClassCommon.asm inkMouse.asm\
                  inkMacro.def inkConstant.def inkControl.ui
FILE            = fileManager.asm fileC.asm fileAccess.asm fileConstant.def\
                  fileMacro.def fileStrings.ui
UI_TO_RDFS      = inkControl.ui fileStrings.ui
OBJS            =
COMMON          = penGeode.def penConstant.def
MODULES         = Ink File
CMODULES        =
SRCS            = $(INK) $(FILE) $(COMMON)
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
