#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = GeoDex
DB              = dbDisplay.asm dbInk.asm dbManager.asm dbRecord.asm\
                  dbUpdate.asm dbUtils.asm dbVariable.def
DIAL            = dialManager.asm dialModem.asm dialPhone.asm\
                  dialQuickDial.asm dialUtils.asm dialVariable.def
FILE            = fileDocument.asm fileManager.asm fileVariable.def
IMPEX           = impexExport.asm impexImport.asm impexManager.asm\
                  impexVariable.def
MAIN            = mainClavin.asm mainEdit.asm mainExit.asm mainGeoDex.asm\
                  mainInit.asm mainManager.asm mainUtils.asm\
                  mainVariable.def
MISC            = miscBottomBWBitmap.asm miscBottomBWBitmapPizza.asm\
                  miscBottomColorBitmap.asm miscBottomColorBitmapPizza.asm\
                  miscLetters.asm miscLettersDraw.asm\
                  miscLetterTabInvert.asm miscManager.asm\
                  miscMiddleBWBitmap.asm miscMiddleBWBitmapPizza.asm\
                  miscMiddleCGABitmap.asm miscMiddleColorBitmap.asm\
                  miscMiddleColorBitmapPizza.asm miscPrint.asm\
                  miscSearch.asm miscTitle.asm miscTopBWBitmap.asm\
                  miscTopBWBitmapPizza.asm miscTopColorBitmap.asm\
                  miscTopColorBitmapPizza.asm miscUtils.asm\
                  miscViewMenu.asm miscConstant.def miscVariable.def
UI              = uiManager.asm uiClavin.ui uiDialog.ui uiMain.ui uiMenu.ui\
                  uiStrings.ui
UI_TO_RDFS      = UIMAIN.UI
OBJS            =
COMMON          = geodexConstant.def geodexGeode.def geodexGlobal.def\
                  geodexMacro.def
MODULES         = DB Dial File Impex Main Misc UI
CMODULES        =
SRCS            = $(DB) $(DIAL) $(FILE) $(IMPEX) $(MAIN) $(MISC) $(UI)\
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
