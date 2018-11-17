#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = GEOFILE
DOCASM          = docasmManager.asm docButtn.asm
DOCUMENT        = docGroup.goc document.goc
LOCALIZE        = strings.goc
MAIN            = mAppl.goc mFldOrdr.goc mFldOrgz.goc mLayouts.goc\
                  mModes.goc mProcess.goc mSorting.goc mSubsets.goc
UI              = uiLayout.goc uiMain.goc uiMarked.goc uiModify.goc\
                  uiTmplat.goc
UI_TO_RDFS      = UIBUTTON.UI
OBJS            = docGroup.obj document.obj strings.obj mAppl.obj\
                  mFldOrdr.obj mFldOrgz.obj mLayouts.obj mModes.obj\
                  mProcess.obj mSorting.obj mSubsets.obj uiLayout.obj\
                  uiMain.obj uiMarked.obj uiModify.obj uiTmplat.obj
COMMON          = geofile.goh gfButton.def gfButton.goh
MODULES         = DocAsm
CMODULES        = Document Localize Main UI
SRCS            = $(DOCASM) $(DOCUMENT) $(LOCALIZE) $(MAIN) $(UI) $(COMMON)
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
