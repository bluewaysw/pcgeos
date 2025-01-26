#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = icon
SOURCE          = sourceSource.asm sourceUtils.asm sourceLarge.asm\
                  sourcePointer.asm sourceManager.asm sourceConstant.def\
                  sourceStrings.ui
VIEWER          = viewerMain.asm viewerKbd.asm viewerUI.asm\
                  viewerVisIcon.asm viewerManager.asm viewerConstant.def
FORMAT          = formatUI.asm formatManager.asm formatFormat.asm\
                  formatFlip.asm formatVMFile.asm formatTransform.asm\
                  formatConstant.def
PREVIEW         = previewManager.asm previewPreview.asm
DOCUMENT        = documentDocument.asm documentVisBitmap.asm\
                  documentManager.asm documentUI.asm documentImpex.asm\
                  documentOptions.asm documentSaveIcon.asm documentIcon.asm\
                  documentApplication.asm documentToken.asm\
                  documentUtils.asm documentDatabase.asm\
                  documentAddIcon.asm documentTransfer.asm\
                  documentConstant.def
UI              = uiManager.asm uiNewClasses.asm uiColor.asm uiConstant.def\
                  uiDocument.ui uiMain.ui uiStrings.ui uiTokenDB.ui\
                  uiTransform.ui uiFormatMenu.ui uiWriteSource.ui\
                  uiManager.ui uiAddIcon.ui uiOptions.ui uiIconMenu.ui\
                  uiPreview.ui uiGraphics.ui
UI_TO_RDFS      = sourceStrings.ui uiManager.ui
OBJS            =
COMMON          = iconGeode.def iconFile.def iconDocument.def\
                  iconFormat.def iconViewer.def iconGlobal.def\
                  iconConstant.def
MODULES         = Source Viewer Format Preview Document UI
CMODULES        =
SRCS            = $(SOURCE) $(VIEWER) $(FORMAT) $(PREVIEW) $(DOCUMENT)\
                  $(UI) $(COMMON)
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
