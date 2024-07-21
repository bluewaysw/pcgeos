#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = comp
FILE            = fileC.asm fileBuffer.goc fileComponent.goc\
                  fileLibrary.goc fileSelector.goc fileInternal.goh
PRINT           = printManager.asm printInternal.def printControl.goc\
                  printLibrary.goc printInternal.goh
SONG            = songLibrary.goc synthComponent.goc waveComponent.goc\
                  songInternal.goh
UI_TO_RDFS      =
OBJS            = fileBuffer.obj fileComponent.obj fileLibrary.obj\
                  fileSelector.obj printControl.obj printLibrary.obj\
                  songLibrary.obj synthComponent.obj waveComponent.obj
COMMON          =
MODULES         = File Print
CMODULES        = File Print Song
SRCS            = $(FILE) $(PRINT) $(SONG) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf

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
