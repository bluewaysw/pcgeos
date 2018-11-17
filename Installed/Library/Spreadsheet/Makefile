#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Spreadsheet
RULER           = rulerCommon.asm rulerHoriz.asm rulerManager.asm\
                  rulerMouse.asm rulerVert.asm rulerConstant.def
SPREADSHEET     = graphicsText.asm spreadsheetC.asm spreadsheetCell.asm\
                  spreadsheetCellEdit.asm spreadsheetChart.asm\
                  spreadsheetCutCopy.asm spreadsheetCutCopyDataChain.asm\
                  spreadsheetCutCopyUtils.asm spreadsheetDraw.asm\
                  spreadsheetDrawUtils.asm spreadsheetEditBar.asm\
                  spreadsheetErrorCheck.asm spreadsheetExprMethods.asm\
                  spreadsheetExtent.asm spreadsheetFill.asm\
                  spreadsheetFormat.asm spreadsheetFormatDisplay.asm\
                  spreadsheetFormatInit.asm spreadsheetFormatMethods.asm\
                  spreadsheetFormulaCell.asm spreadsheetFunctions.asm\
                  spreadsheetGeometry.asm spreadsheetHeaderFooter.asm\
                  spreadsheetInit.asm spreadsheetKeyboard.asm\
                  spreadsheetManager.asm spreadsheetMethodFocus.asm\
                  spreadsheetMethodMouse.asm spreadsheetMethodMove.asm\
                  spreadsheetMethodSelect.asm spreadsheetMethodStyle.asm\
                  spreadsheetNameCtrlInterface.asm spreadsheetNameList.asm\
                  spreadsheetNameMethods.asm spreadsheetNameUtils.asm\
                  spreadsheetNotes.asm spreadsheetNotify.asm\
                  spreadsheetOverlap.asm spreadsheetParse.asm\
                  spreadsheetPaste.asm spreadsheetPasteName.asm\
                  spreadsheetPasteTransTbl.asm spreadsheetPointer.asm\
                  spreadsheetPrint.asm spreadsheetQuickMoveCopy.asm\
                  spreadsheetRange.asm spreadsheetRecalc.asm\
                  spreadsheetRowArray.asm spreadsheetRowColumn.asm\
                  spreadsheetScroll.asm spreadsheetSearch.asm\
                  spreadsheetSort.asm spreadsheetSpace.asm\
                  spreadsheetStyleToken.asm spreadsheetTextScrap.asm\
                  spreadsheetUtils.asm spreadsheetVariable.asm\
                  graphicsText.def spreadsheetConstant.def\
                  spreadsheetCutCopyConstant.def\
                  spreadsheetFileConstant.def spreadsheetMacro.def\
                  spreadsheetRowArray.def spreadsheetStyleToken.def
UI              = uiBorder.asm uiBorderColor.asm uiChart.asm\
                  uiChooseFunction.asm uiChooseName.asm uiDefineName.asm\
                  uiEdit.asm uiEditBar.asm uiFill.asm uiHeader.asm\
                  uiHeight.asm uiManager.asm uiNotes.asm uiOptions.asm\
                  uiRecalc.asm uiSort.asm uiUtils.asm uiWidth.asm\
                  uiConstant.def uiBorder.ui uiBorderColor.ui uiChart.ui\
                  uiChooseFunction.ui uiChooseName.ui uiDefineName.ui\
                  uiEdit.ui uiEditBar.ui uiFill.ui uiHeader.ui uiHeight.ui\
                  uiManager.ui uiNotes.ui uiOptions.ui uiRecalc.ui\
                  uiSort.ui uiWidth.ui
UI_TO_RDFS      = UIMANAGER.UI
OBJS            =
COMMON          = spreadsheetErrors.def spreadsheetGeode.def\
                  spreadsheetMacros.def
MODULES         = Ruler Spreadsheet UI
CMODULES        =
SRCS            = $(RULER) $(SPREADSHEET) $(UI) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = ssheet

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
