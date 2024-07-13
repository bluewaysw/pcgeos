#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = datastore
DELLIST         = dellist.asm dellistManager.asm
FILE            = fileAccess.asm fileAPI.asm fileEC.asm fileFieldName.asm\
                  fileManager.asm fileMisc.asm fileOpen.asm
MAIN            = mainC.asm mainData.asm mainEC.asm mainManager.asm\
                  mainStructure.asm
MANAGER         = managerAccess.asm managerDataStore.asm managerInit.asm\
                  managerMain.asm managerManager.asm managerRecord.asm\
                  managerSynch.asm
PIPEPORT        = pipeportAppl.asm pipeportBehaviors.asm\
                  pipeportManager.asm pipeport.def
UI_TO_RDFS      =
OBJS            =
COMMON          = dsConstant.def dsGeode.def dsGlobal.def dsMacro.def
MODULES         = Dellist File Main Manager Pipeport
CMODULES        =
SRCS            = $(DELLIST) $(FILE) $(MAIN) $(MANAGER) $(PIPEPORT)\
                  $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = datastor

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
