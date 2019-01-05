#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = geodex
DIAL            = dialManager.asm dialUtils.asm dialModem.asm dialPhone.asm\
                  dialQuickDial.asm dialVariable.def
FILE            = fileManager.asm fileDocument.asm fileVariable.def
UI              = uiManager.asm uiStrings.ui uiDialog.ui uiMenu.ui\
                  uiClavin.ui uiMain.ui
MAIN            = mainManager.asm mainGeoDex.asm mainUtils.asm mainEdit.asm\
                  mainExit.asm mainInit.asm mainClavin.asm mainVariable.def
IMPEX           = impexManager.asm impexImport.asm impexExport.asm\
                  impexVariable.def
MISC            = miscMiddleColorBitmapPizza.asm miscMiddleCGABitmap.asm\
                  miscPrint.asm miscSearch.asm miscBottomBWBitmapPizza.asm\
                  miscViewMenu.asm miscLetters.asm\
                  miscBottomColorBitmapPizza.asm miscTopBWBitmap.asm\
                  miscTopColorBitmapPizza.asm miscUtils.asm\
                  miscMiddleBWBitmap.asm miscTitle.asm\
                  miscTopBWBitmapPizza.asm miscLettersDraw.asm\
                  miscMiddleBWBitmapPizza.asm miscLetterTabInvert.asm\
                  miscBottomColorBitmap.asm miscTopColorBitmap.asm\
                  miscManager.asm miscBottomBWBitmap.asm\
                  miscMiddleColorBitmap.asm miscConstant.def\
                  miscVariable.def
DB              = dbInk.asm dbManager.asm dbRecord.asm dbUpdate.asm\
                  dbDisplay.asm dbUtils.asm dbVariable.def
UI_TO_RDFS      = uiMain.ui
OBJS            =
COMMON          = geodexConstant.def geodexGlobal.def geodexMacro.def\
                  geodexGeode.def
MODULES         = Dial File UI Main Impex Misc DB
CMODULES        =
SRCS            = $(DIAL) $(FILE) $(UI) $(MAIN) $(IMPEX) $(MISC) $(DB)\
                  $(COMMON)
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
