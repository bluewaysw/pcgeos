#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = geofile
UI              = uiLayout.goc uiMarked.goc uiTmplat.goc uiModify.goc\
                  uiMain.goc
DOCUMENT        = docGroup.goc document.goc
MAIN            = mFldOrdr.goc mProcess.goc mFldOrgz.goc mModes.goc\
                  mLayouts.goc mAppl.goc mSorting.goc mSubsets.goc
DOCASM          = docButtn.asm docasmManager.asm
LOCALIZE        = strings.goc
UI_TO_RDFS      = uiButton.ui
OBJS            = uiLayout.obj uiMarked.obj uiTmplat.obj uiModify.obj\
                  uiMain.obj docGroup.obj document.obj mFldOrdr.obj\
                  mProcess.obj mFldOrgz.obj mModes.obj mLayouts.obj\
                  mAppl.obj mSorting.obj mSubsets.obj strings.obj
COMMON          = gfButton.goh geofile.goh gfButton.def
MODULES         = DocAsm
CMODULES        = UI Document Main Localize
SRCS            = $(UI) $(DOCUMENT) $(MAIN) $(DOCASM) $(LOCALIZE) $(COMMON)
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
